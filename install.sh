#!/usr/bin/env bash
# install.sh - Bootstrapper cài đặt một dòng cho kali-setup.sh
#
#   curl -fsSL https://raw.githubusercontent.com/duochou042004/kali-setup/main/install.sh | bash
#
# Script này KHÔNG thay đổi kali-setup.sh. Nó chỉ:
#   1. Kiểm tra môi trường (bash, user thường, Kali, có terminal, công cụ cần thiết)
#   2. Tải TRỌN VẸN kali-setup.sh về thư mục tạm, kiểm tra cú pháp (+ checksum nếu có)
#   3. Chạy kali-setup.sh như khi chạy ./kali-setup.sh, với stdin nối vào terminal
#
# Tuỳ chọn (biến môi trường, đặt trước "bash"):
#   curl -fsSL .../install.sh | KALI_SETUP_REF=v1.0.0 bash
#   KALI_SETUP_REPO=user/repo   repo GitHub chứa kali-setup.sh   (mặc định: duochou042004/kali-setup)
#   KALI_SETUP_REF=main         branch / tag / commit SHA        (mặc định: main)
#   KALI_SETUP_URL=https://...  URL đầy đủ tới kali-setup.sh (ghi đè REPO/REF)
#   KALI_SETUP_SHA256=<hash>    bắt buộc khớp SHA-256 trước khi chạy
#   KALI_SETUP_FORCE=1          cho phép chạy trên hệ không phải Kali

# Bị pipe vào sh/dash thay vì bash: không thể tự exec lại (không có file), nên báo và thoát
if [ -z "${BASH_VERSION:-}" ]; then
  echo "install.sh cần bash. Chạy: curl -fsSL <URL>/install.sh | bash" >&2
  exit 1
fi

# Toàn bộ logic nằm trong main() và chỉ được gọi ở dòng cuối:
# nếu kết nối bị đứt giữa chừng, bash không thực thi một script bị cắt cụt.
main() {
  set -euo pipefail

  local repo="${KALI_SETUP_REPO:-duochou042004/kali-setup}"
  local ref="${KALI_SETUP_REF:-main}"
  local url="${KALI_SETUP_URL:-https://raw.githubusercontent.com/${repo}/${ref}/kali-setup.sh}"
  local one_liner="curl -fsSL https://raw.githubusercontent.com/${repo}/${ref}/install.sh | bash"

  info() { printf '\e[1;34m[install]\e[0m %s\n' "$*"; }
  warn() { printf '\e[1;33m[install]\e[0m %s\n' "$*" >&2; }
  die()  { printf '\e[1;31m[install] %s\e[0m\n' "$*" >&2; exit 1; }

  # --- 1. Kiểm tra môi trường ---------------------------------------------

  # kali-setup.sh dùng ~/, git config --global, SDKMAN, systemctl --user => user thường.
  # Bắt sớm lỗi hay gặp "curl ... | sudo bash".
  if [[ $EUID -eq 0 ]]; then
    die "Không chạy bằng sudo/root. Chạy lại bằng user thường: $one_liner"
  fi

  # Hỗ trợ Kali, Ubuntu, Debian (kali-setup.sh tự xử lý khác biệt giữa các distro)
  local os_id=""
  [[ -r /etc/os-release ]] && os_id="$(. /etc/os-release && echo "${ID:-}")"
  case "$os_id" in
    kali|ubuntu|debian) info "Distro: $os_id" ;;
    *)
      [[ "${KALI_SETUP_FORCE:-0}" == "1" ]] \
        || die "Distro '${os_id:-unknown}' chưa hỗ trợ (chỉ Kali, Ubuntu, Debian). Đặt KALI_SETUP_FORCE=1 để thử."
      warn "Distro '${os_id:-unknown}' chưa hỗ trợ - vẫn thử vì KALI_SETUP_FORCE=1"
      ;;
  esac

  # Khi chạy qua pipe, stdin là nội dung script chứ không phải bàn phím.
  # Cần terminal thật cho: mật khẩu sudo, prompt của apt/sdkman, "read -t 15" trước khi reboot.
  if ! { : </dev/tty; } 2>/dev/null; then
    die "Không tìm thấy terminal tương tác (/dev/tty). Hãy chạy lệnh trong một terminal."
  fi

  command -v sudo >/dev/null 2>&1 \
    || die "Thiếu 'sudo'. Debian: su - -c 'apt install sudo && usermod -aG sudo $USER' rồi đăng nhập lại."

  # Gói nền (git, curl, zsh, zip...) do kali-setup.sh tự cài; ở đây chỉ cần curl/wget khi phải tải

  # --- 2. Lấy kali-setup.sh -----------------------------------------------

  local workdir
  workdir="$(mktemp -d "${TMPDIR:-/tmp}/kali-setup.XXXXXX")"
  # shellcheck disable=SC2064  # mở rộng $workdir ngay lúc đặt trap là cố ý
  trap "rm -rf -- '$workdir'" EXIT
  local script="$workdir/kali-setup.sh"   # giữ đúng tên file để \$0 / basename như bản gốc

  # Chạy ./install.sh ngay trong repo: dùng bản kali-setup.sh cục bộ (tiện test/offline)
  local self="${BASH_SOURCE[0]:-}" local_copy=""
  if [[ -z "${KALI_SETUP_URL:-}" && "$(basename -- "$self")" == "install.sh" && -f "$self" ]]; then
    local_copy="$(cd -- "$(dirname -- "$self")" && pwd)/kali-setup.sh"
    [[ -f "$local_copy" ]] || local_copy=""
  fi

  # Cho kali-setup.sh biết lấy tài nguyên đi kèm (dotfiles/) ở đâu, cùng nguồn/phiên bản với nó
  if [[ -n "$local_copy" ]]; then
    info "Dùng bản cục bộ: $local_copy"
    cp -- "$local_copy" "$script"
    export KALI_SETUP_SRC_DIR="${local_copy%/*}"
  else
    export KALI_SETUP_BASE_URL="${url%/*}"
    case "$url" in
      https://*|file://*) ;;
      *) die "URL không an toàn (chỉ chấp nhận https://): $url" ;;
    esac
    command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 \
      || die "Cần curl hoặc wget để tải kali-setup.sh."
    info "Tải $url"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL --retry 3 --retry-delay 2 -o "$script" "$url" \
        || die "Tải thất bại: $url"
    else
      wget -q --tries=3 -O "$script" "$url" || die "Tải thất bại: $url"
    fi
  fi

  # --- 3. Kiểm tra file trước khi chạy -------------------------------------

  [[ -s "$script" ]] || die "File tải về rỗng."
  head -n1 "$script" | grep -q '^#!.*bash' \
    || die "File tải về không phải bash script (sai URL/branch?)."
  bash -n "$script" || die "kali-setup.sh lỗi cú pháp - dừng lại, không chạy."

  if [[ -n "${KALI_SETUP_SHA256:-}" ]]; then
    local got
    got="$(sha256sum "$script" | cut -d' ' -f1)"
    [[ "$got" == "${KALI_SETUP_SHA256,,}" ]] \
      || die "SHA-256 không khớp. Mong đợi ${KALI_SETUP_SHA256}, nhận được ${got}."
    info "SHA-256 OK"
  fi
  chmod +x "$script"

  # --- 4. Chạy -------------------------------------------------------------

  # Thư mục làm việc ghi được, tự dọn (kali-setup.sh tải .deb vào thư mục hiện tại)
  cd -- "$workdir"
  info "Bắt đầu kali-setup.sh (log: \$HOME/kali-setup.log)"
  set +e
  bash "$script" "$@" </dev/tty
  local rc=$?
  set -e
  (( rc == 0 )) || warn "kali-setup.sh kết thúc với mã $rc"
  return "$rc"
}

main "$@"
