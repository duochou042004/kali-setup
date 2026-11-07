#!/usr/bin/env bash
# tests/smoke.sh - Smoke test chạy TOÀN BỘ kali-setup.sh trong container (root), dùng cho CI và local.
#
#   podman run --rm -v "$PWD:/src:ro" ubuntu:24.04 bash /src/tests/smoke.sh
#   (hoặc: tests/run-local.sh)
#
# Tạo user thường có sudo, chạy install.sh bản cục bộ trong pty (giống người dùng thật gõ lệnh),
# rồi kiểm tra kết quả. Container không phải máy thật nên giả lập vài thứ máy thật luôn có.
set -uo pipefail

SRC="${1:-/src}"
export DEBIAN_FRONTEND=noninteractive TZ=UTC
. /etc/os-release

fail=0
check() {  # check "mô tả" lệnh...
  if "${@:2}" >/dev/null 2>&1; then echo "  ✓ $1"; else echo "  ✗ $1"; fail=1; fi
}

echo "::group::Chuẩn bị container ($PRETTY_NAME)"
ln -fs /usr/share/zoneinfo/UTC /etc/localtime
pkgs=(sudo tzdata)
# Kali bản cài đầy đủ luôn có sẵn những gói này (image kali-rolling thì tối giản)
[[ "$ID" == kali ]] && pkgs+=(zsh zsh-autosuggestions zsh-syntax-highlighting command-not-found
                               curl wget git gnupg zip unzip im-config ca-certificates)
apt-get update -qq && apt-get install -y -qq "${pkgs[@]}" >/dev/null || exit 1

# Máy thật: udev tạo group kvm; journald có sẵn (im-config ghi log qua systemd-cat).
groupadd -f -r kvm   # system group như udev tạo (group thường làm postinst của udev lỗi)
dpkg-divert --local --rename --add /usr/bin/systemd-cat >/dev/null
printf '#!/bin/sh\n# stub cho container: bỏ các option của systemd-cat, chạy lệnh\nwhile [ "${1#-}" != "$1" ]; do case "$1" in -p|-t) shift;; esac; shift; done\n"$@" >&2\n' \
  > /usr/bin/systemd-cat && chmod +x /usr/bin/systemd-cat

# Bước "Chrome + fcitx5": Kali = máy đã cài Chrome (giả lập shortcut của gói google-chrome-stable)
# để test nhánh cấu hình; Ubuntu/Debian = máy cài mới chưa có Chrome để test nhánh "bỏ qua".
if [[ "$ID" == kali ]]; then
  mkdir -p /usr/share/applications
  printf '%s\n' '[Desktop Entry]' 'Exec=/usr/bin/google-chrome-stable %U' \
    '[Desktop Action new-window]' 'Exec=/usr/bin/google-chrome-stable' \
    '[Desktop Action new-private-window]' 'Exec=/usr/bin/google-chrome-stable --incognito' \
    > /usr/share/applications/google-chrome.desktop
fi

useradd -m -s /bin/bash tester
[[ "$ID" == kali ]] && chsh -s /usr/bin/zsh tester
printf 'tester ALL=(ALL) NOPASSWD:ALL\nDefaults env_keep += "DEBIAN_FRONTEND TZ"\n' > /etc/sudoers.d/tester
cp -r "$SRC" /home/tester/kali-setup && chown -R tester: /home/tester/kali-setup
echo "::endgroup::"

echo "::group::Chạy install.sh (pty)"
# script(1) tạo pty để install.sh có /dev/tty như khi người dùng chạy trong terminal
script -qec "sudo -u tester -i ./kali-setup/install.sh" /dev/null </dev/null
rc=$?
echo "::endgroup::"
echo "install.sh exit code: $rc (là mã của 'sudo reboot' cuối script - luôn lỗi trong container)"

log="$(sed 's/\x1b\[[0-9;]*m//g' /home/tester/kali-setup.log)"
mapfile -t failed < <(awk '/^Các bước lỗi:/{f=1; next} f && /^  - /{sub(/^  - /,""); print; next} f && !/^  - /{f=0}' <<<"$log")

echo "Kết quả ($PRETTY_NAME):"
check "đã chạy tới phần Tổng kết" grep -q '^==> Tổng kết' <<<"$log"
# Không chấp nhận bước lỗi nào: bước không áp dụng được phải báo "bỏ qua" (⊘), không phải lỗi
for s in "${failed[@]}"; do echo "  ✗ bước lỗi: $s"; fail=1; done
(( ${#failed[@]} )) || echo "  ✓ không có bước nào lỗi"
awk '/^Các bước bỏ qua/{f=1; next} f && /^  ⊘ /{sub(/^  ⊘ /,"  ~ bỏ qua: "); print; next} {f=0}' <<<"$log"

if [[ "$ID" == kali ]]; then
  check "Chrome đã cài: shortcut được cấu hình fcitx5" \
    grep -q 'Exec=env GTK_IM_MODULE=fcitx /usr/bin/google-chrome-stable --ozone-platform=x11 --incognito' \
    /home/tester/.local/share/applications/google-chrome.desktop
else
  check "Chrome chưa cài: bước Chrome được bỏ qua có lý do" \
    grep -q '^  ⊘ Chrome + fcitx5: chưa cài Google Chrome' <<<"$log"
fi

check "shell đăng nhập là zsh" bash -c '[[ "$(getent passwd tester | cut -d: -f7)" == */zsh ]]'
check "file ~/.zshrc kiểu Kali" grep -q PROMPT_ALTERNATIVE /home/tester/.zshrc
check "nvm được nạp trong ~/.zshrc" grep -q NVM_DIR /home/tester/.zshrc
check "SDKMAN được nạp trong ~/.zshrc" grep -q sdkman-init /home/tester/.zshrc
[[ "$ID" != kali ]] && check "/etc/zsh/zprofile nạp /etc/profile" \
  grep -qxF "emulate sh -c '. /etc/profile'" /etc/zsh/zprofile

# Chạy trong zsh đăng nhập + tương tác, như mở terminal mới sau khi reboot
cat > /tmp/tools.zsh <<'EOF'
for c in java node npm dotnet gh glab podman; do
  command -v $c >/dev/null || { echo "thiếu $c"; exit 1; }
done
echo "  java   : $(java -version 2>&1 | head -1)"
echo "  node   : $(node -v)   dotnet: $(dotnet --version)"
echo "  gh     : $(gh --version | head -1)"
echo "  prompt : $PROMPT_ALTERNATIVE"
EOF
chmod 644 /tmp/tools.zsh
if sudo -u tester -H zsh -lic 'source /tmp/tools.zsh' </dev/null 2>/dev/null; then
  echo "  ✓ java/node/npm/dotnet/gh/glab/podman chạy được từ zsh"
else
  echo "  ✗ thiếu công cụ trong zsh"; fail=1
fi

(( fail )) && echo "SMOKE TEST: FAIL" || echo "SMOKE TEST: PASS"
exit "$fail"
