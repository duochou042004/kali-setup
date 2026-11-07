#!/usr/bin/env bash
# Lỡ chạy bằng "zsh kali-setup.sh" / "sh kali-setup.sh" thì tự chạy lại bằng bash
[ -z "$BASH_VERSION" ] && exec bash "$0" "$@"
# kali-setup.sh - Setup developer chuẩn sau khi cài mới Kali Linux
# Hỗ trợ: Kali (chuẩn gốc), Ubuntu, Debian. Với Ubuntu/Debian script cài gói nền
# và zsh + cấu hình shell giống Kali TRƯỚC, rồi mới chạy các bước như trên Kali.
# Cách chạy (user thường, KHÔNG dùng sudo):  chmod +x kali-setup.sh && ./kali-setup.sh

# Phải chạy bằng user thường vì có ~/, git config --global, SDKMAN, systemctl --user
if [[ $EUID -eq 0 ]]; then
  echo "Không chạy bằng sudo/root. Chạy lại: ./$(basename "$0")"
  exit 1
fi

# Ghi log để xem lại khi có lỗi
LOG="$HOME/kali-setup.log"
exec > >(tee -a "$LOG") 2>&1

# ---------- Nhận diện distro ----------
# DISTRO_ID: kali | ubuntu | debian. Distro khác: dừng (KALI_SETUP_FORCE=1 để thử theo ID_LIKE)
os_field() { ( . /etc/os-release 2>/dev/null && eval "echo \"\${$1:-}\"" ); }
DISTRO_ID="$(os_field ID)"
DISTRO_VERSION="$(os_field VERSION_ID)"
DISTRO_CODENAME="$(os_field VERSION_CODENAME)"
DISTRO_NAME="$(os_field PRETTY_NAME)"
case "$DISTRO_ID" in
  kali|ubuntu|debian) ;;
  *)
    like=" $(os_field ID_LIKE) "
    if [[ "${KALI_SETUP_FORCE:-0}" == "1" && "$like" == *" ubuntu "* ]]; then
      DISTRO_ID=ubuntu; DISTRO_CODENAME="$(os_field UBUNTU_CODENAME)"
    elif [[ "${KALI_SETUP_FORCE:-0}" == "1" && "$like" == *" debian "* ]]; then
      DISTRO_ID=debian
    else
      echo "Distro '${DISTRO_NAME:-unknown}' chưa hỗ trợ (chỉ Kali, Ubuntu, Debian)."
      exit 1
    fi
    echo "Chạy thử '${DISTRO_NAME}' như $DISTRO_ID (KALI_SETUP_FORCE=1)"
    ;;
esac
is_kali() { [[ "$DISTRO_ID" == kali ]]; }
echo "Distro: ${DISTRO_NAME:-$DISTRO_ID} ($DISTRO_ID ${DISTRO_VERSION:-?} ${DISTRO_CODENAME:-?})"

# Nơi lấy tài nguyên đi kèm (dotfiles/): thư mục repo cục bộ, hoặc tải từ GitHub
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
BASE_URL="${KALI_SETUP_BASE_URL:-https://raw.githubusercontent.com/duochou042004/kali-setup/${KALI_SETUP_REF:-main}}"
fetch_resource() {  # fetch_resource dotfiles/zshrc /đường/dẫn/đích
  local d
  for d in "${KALI_SETUP_SRC_DIR:-}" "$SCRIPT_DIR"; do
    [[ -n "$d" && -f "$d/$1" ]] && { cp -- "$d/$1" "$2"; return; }
  done
  curl -fsSL --retry 3 -o "$2" "$BASE_URL/$1"
}

# Hỏi mật khẩu sudo 1 lần, giữ phiên sudo sống tới khi script kết thúc
if ! sudo -v; then
  [[ "$DISTRO_ID" == debian ]] && echo "Debian: user chưa có quyền sudo? Chạy: su - -c 'usermod -aG sudo $USER' rồi đăng nhập lại."
  exit 1
fi
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

FAILED=()
TIMES=()
step() {  # step "Tên bước" ten_ham
  echo -e "\n\e[1;34m==> $1\e[0m"
  local start=$SECONDS
  # Gọi trần (không kèm ||) để set -e bên trong hàm còn hiệu lực
  "$2"
  if (( $? != 0 )); then echo -e "\e[1;31m[LỖI] $1\e[0m"; FAILED+=("$1"); fi
  local d=$((SECONDS - start))
  TIMES+=("$(printf '%3dm%02ds  %s' $((d/60)) $((d%60)) "$1")")
}

# ---------- Chuẩn bị môi trường giống Kali (chỉ Ubuntu/Debian) ----------

# Kali có sẵn các gói này; Ubuntu/Debian (nhất là bản minimal/server) có thể thiếu
prepare_env() ( set -eE
trap 'echo "  -> lệnh lỗi: $BASH_COMMAND (mã $?)" >&2' ERR
local pkgs=(git curl wget ca-certificates gnupg zip unzip
            zsh zsh-autosuggestions zsh-syntax-highlighting command-not-found
            im-config)
[[ "$DISTRO_ID" == ubuntu ]] && pkgs+=(software-properties-common)  # add-apt-repository cho .NET
sudo apt-get update
sudo apt-get install -y "${pkgs[@]}"

# Cấu hình zsh mặc định của Kali (dotfiles/ = /etc/skel/.zshrc, .zprofile của kali-defaults).
# Đã có ~/.zshrc kiểu Kali (chạy lại script) thì giữ nguyên để không mất dòng SDKMAN/nvm.
if [[ -f ~/.zshrc ]] && grep -q 'PROMPT_ALTERNATIVE' ~/.zshrc; then
  echo "~/.zshrc kiểu Kali đã có, giữ nguyên"
else
  fetch_resource dotfiles/zshrc ~/.zshrc.kali-setup
  [[ -e ~/.zshrc ]] && cp -a ~/.zshrc ~/.zshrc.bak."$(date +%Y%m%d%H%M%S)"
  mv ~/.zshrc.kali-setup ~/.zshrc
fi
if [[ ! -e ~/.zprofile ]]; then
  fetch_resource dotfiles/zprofile ~/.zprofile
fi

# Đổi shell đăng nhập sang zsh (có hiệu lực sau khi đăng nhập lại / reboot cuối script)
local zsh_path cur
zsh_path="$(command -v zsh)"
grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
cur="$(getent passwd "$USER" | cut -d: -f7)"
[[ "$(basename -- "$cur")" == zsh ]] || sudo chsh -s "$zsh_path" "$USER"
getent passwd "$USER" | cut -d: -f7
zsh --version
)

# ---------- Setup developer chuẩn ----------

# Chỉ gỡ gói mà apt/dpkg biết tới: Ubuntu/Debian có thể không có openjdk-25, dotnet 6...
# (apt báo "Unable to locate package" và hủy cả lệnh). Trên Kali mọi gói đều có => lệnh y như cũ.
apt_purge_known() {
  local p known=()
  for p in "$@"; do
    if apt-cache show "$p" >/dev/null 2>&1 || dpkg-query -W "$p" >/dev/null 2>&1; then
      known+=("$p")
    else
      echo "  (bỏ qua $p: không có trên ${DISTRO_ID})"
    fi
  done
  (( ${#known[@]} )) || return 0
  sudo apt remove --purge -y "${known[@]}"
}

remove_java() ( set -e
apt_purge_known \
  openjdk-25-jre \
  openjdk-25-jre-headless \
  default-jre \
  default-jre-headless \
  ca-certificates-java \
  java-common \
  java-wrappers \
  libatk-wrapper-java \
  libatk-wrapper-java-jni \
  libcommons-logging-java \
  libcommons-parent-java \
  libapache-pom-java \
  libfontbox-java \
  libpdfbox-java
)

remove_dotnet6() ( set -e
apt_purge_known \
  dotnet-sdk-6.0 \
  dotnet-runtime-6.0 \
  dotnet-runtime-deps-6.0 \
  dotnet-host \
  dotnet-hostfxr-6.0 \
  dotnet-apphost-pack-6.0 \
  dotnet-targeting-pack-6.0
)

cleanup() ( set -e
# Dọn dependencies thừa
sudo apt autoremove --purge -y
sudo apt clean

# Xóa thư mục còn sót
sudo rm -rf /usr/share/dotnet
sudo rm -rf /usr/lib/jvm/java-25-openjdk-amd64
sudo rm -rf /usr/lib/jvm/java-1.25.0-openjdk-amd64
rm -rf ~/.dotnet ~/.nuget

# Xóa alternatives
sudo update-alternatives --remove-all java 2>/dev/null || true
sudo update-alternatives --remove-all javac 2>/dev/null || true
)

# Không dùng set -e ở đây: sdkman-init.sh có lệnh trả mã khác 0 vô hại
install_java() (
curl -s "https://get.sdkman.io" | zsh
source "$HOME/.sdkman/bin/sdkman-init.sh"
# Xem các bản Java LTS có sẵn
sdk list java | grep -E "17|21|25"
# Cài bản mặc định LTS mới nhất
sdk install java
java --version
javac --version
)

install_dotnet10() ( set -e
if [[ "$DISTRO_ID" == ubuntu ]]; then
  # Ubuntu: Microsoft khuyến nghị dùng gói của Ubuntu (archive, hoặc PPA dotnet/backports
  # nếu archive chưa có .NET 10) thay vì feed packages.microsoft.com để tránh xung đột gói
  sudo apt-get update
  if ! apt-cache policy dotnet-sdk-10.0 | grep -q 'Candidate: [0-9]'; then
    sudo add-apt-repository -y ppa:dotnet/backports
    sudo apt-get update
  fi
  sudo apt-get install -y dotnet-sdk-10.0
else
# Kali: repo Microsoft cho Debian 13 (như bản gốc). Debian: theo đúng phiên bản (12, 13...)
local deb_ver=13
[[ "$DISTRO_ID" == debian && -n "$DISTRO_VERSION" ]] && deb_ver="$DISTRO_VERSION"
wget "https://packages.microsoft.com/config/debian/${deb_ver}/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-10.0
fi

dotnet --version
)

# Không dùng set -e: nvm.sh có lệnh trả mã khác 0 vô hại (giống SDKMAN)
install_node() (
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 24

# Verify the Node.js version:
node -v # Should print "v24.21.0".

# Verify npm version:
npm -v # Should print "11.19.0".
)

setup_kvm() ( set -e
sudo usermod -aG kvm $USER
)

install_podman() ( set -e
sudo apt install -y podman podman-compose
podman --version
podman-compose --version
)

git_config() ( set -e
# Cấu hình Tên (hiển thị trên các commit)
git config --global user.name "duochou042004"

# Cấu hình Email (nên dùng email đăng ký tài khoản GitHub)
git config --global user.email "duongchausky@gmail.com"
)

install_gh() ( set -e
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y
)

install_glab() ( set -e
# Add WakeMeOps repository
curl -sSL "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | sudo bash
# Install glab
sudo apt install -y glab
)

install_warp() ( set -e
# Kali dùng repo trixie (như bản gốc). Ubuntu/Debian: theo codename; Cloudflare chưa có repo
# cho bản Ubuntu interim / Debian testing thì lùi về bản LTS/stable gần nhất (tránh apt update lỗi 404)
local codename=trixie
if ! is_kali; then
  codename="$DISTRO_CODENAME"
  if ! curl -fsI "https://pkg.cloudflareclient.com/dists/${codename}/Release" >/dev/null 2>&1; then
    local fallback=trixie
    [[ "$DISTRO_ID" == ubuntu ]] && fallback=noble
    echo "  -> WARP chưa có repo cho '${codename:-?}', dùng '$fallback'"
    codename="$fallback"
  fi
fi

# Add cloudflare gpg key
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

# Add this repo to your apt repositories
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ ${codename} main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
# Install
sudo apt-get update && sudo apt-get install -y cloudflare-warp
)

# ---------- Setup fcitx5 (giữ nguyên) ----------

setup_fcitx5() ( set -eE
trap 'echo "  -> lệnh lỗi: $BASH_COMMAND (mã $?)" >&2' ERR
sudo apt install -y fcitx5 fcitx5-unikey fcitx5-config-qt

# im-config 1.1: dùng -w để ghi cấu hình; bản cũ (Ubuntu/Debian cũ) chỉ có -n
if im-config -h 2>&1 | grep -q -- '-w <name>'; then
  im-config -w fcitx5
else
  im-config -n fcitx5
fi
grep -qx 'run_im fcitx5' "$HOME/.xinputrc"

systemctl --user mask ibus-daemon.service 2>/dev/null || true
systemctl --user mask ibus-x11.service 2>/dev/null || true

mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/fcitx5.conf << 'EOF'
XMODIFIERS=@im=fcitx
EOF

mkdir -p ~/.config/autostart
cp /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart/
)

setup_chrome_fcitx() ( set -eE
trap 'echo "  -> lệnh lỗi: $BASH_COMMAND (mã $?)" >&2' ERR
mkdir -p ~/.local/share/applications
cp /usr/share/applications/google-chrome.desktop \
   ~/.local/share/applications/google-chrome.desktop

sed -i \
  -e 's|Exec=/usr/bin/google-chrome-stable %U|Exec=env GTK_IM_MODULE=fcitx /usr/bin/google-chrome-stable --ozone-platform=x11 %U|' \
  -e 's|Exec=/usr/bin/google-chrome-stable$|Exec=env GTK_IM_MODULE=fcitx /usr/bin/google-chrome-stable --ozone-platform=x11|' \
  -e 's|Exec=/usr/bin/google-chrome-stable --incognito|Exec=env GTK_IM_MODULE=fcitx /usr/bin/google-chrome-stable --ozone-platform=x11 --incognito|' \
  ~/.local/share/applications/google-chrome.desktop
)

# ---------- Cập nhật hệ thống (chạy cuối) ----------

system_upgrade() ( set -e
sudo apt update && sudo apt upgrade -y && sudo apt clean && sudo apt autoremove -y
)

# ---------- Chạy ----------

# Ubuntu/Debian: dựng môi trường giống Kali TRƯỚC. Lỗi ở đây thì các bước sau chắc chắn hỏng
# (thiếu zsh/curl/git...) nên dừng luôn thay vì chạy tiếp.
if ! is_kali; then
  step "Chuẩn bị môi trường giống Kali (gói nền + zsh)" prepare_env
  if (( ${#FAILED[@]} )); then
    echo -e "\e[1;31mChuẩn bị môi trường lỗi - dừng lại. Xem log: $LOG\e[0m"
    exit 1
  fi
  # Shell hiện tại vẫn là bash: báo cho installer (nvm, SDKMAN) rằng shell là zsh như trên Kali,
  # để chúng ghi cấu hình vào ~/.zshrc thay vì ~/.bashrc
  export SHELL="$(command -v zsh)"
fi

step "Gỡ Java cũ (apt)"            remove_java
step "Gỡ .NET 6"                   remove_dotnet6
step "Dọn dẹp + xóa alternatives"  cleanup
step "Cài Java qua SDKMAN"         install_java
step "Cài .NET SDK 10"             install_dotnet10
step "Cài Node.js 24 qua nvm"      install_node
step "Cấu hình Git"                git_config
step "Cài GitHub CLI (gh)"         install_gh
step "Cài GitLab CLI (glab)"       install_glab
step "Cài Cloudflare WARP"         install_warp
step "Thêm user vào nhóm kvm"      setup_kvm
step "Cài Podman + podman-compose" install_podman
step "Setup fcitx5"                setup_fcitx5
step "Chrome + fcitx5"             setup_chrome_fcitx
step "apt update/upgrade/clean"    system_upgrade

echo -e "\n\e[1;34m==> Tổng kết\e[0m (log: $LOG)"
echo "Thời gian từng bước:"
printf '  %s\n' "${TIMES[@]}"
printf '  Tổng: %dm%02ds\n' $((SECONDS/60)) $((SECONDS%60))
if (( ${#FAILED[@]} )); then
  echo -e "\e[1;31mCác bước lỗi:\e[0m"
  printf '  - %s\n' "${FAILED[@]}"
else
  echo -e "\e[1;32mTất cả các bước OK.\e[0m"
fi

read -t 15 -p "Reboot sau 15s (Enter để reboot ngay, Ctrl+C để hủy)... " || true
sudo reboot
