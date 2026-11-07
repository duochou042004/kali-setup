#!/usr/bin/env bash
# Lỡ chạy bằng "zsh kali-setup.sh" / "sh kali-setup.sh" thì tự chạy lại bằng bash
[ -z "$BASH_VERSION" ] && exec bash "$0" "$@"
# kali-setup.sh - Setup developer chuẩn sau khi cài mới Kali Linux
# Cách chạy (user thường, KHÔNG dùng sudo):  chmod +x kali-setup.sh && ./kali-setup.sh

# Phải chạy bằng user thường vì có ~/, git config --global, SDKMAN, systemctl --user
if [[ $EUID -eq 0 ]]; then
  echo "Không chạy bằng sudo/root. Chạy lại: ./$(basename "$0")"
  exit 1
fi

# Ghi log để xem lại khi có lỗi
LOG="$HOME/kali-setup.log"
exec > >(tee -a "$LOG") 2>&1

# Hỏi mật khẩu sudo 1 lần, giữ phiên sudo sống tới khi script kết thúc
sudo -v || exit 1
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

# ---------- Setup developer chuẩn ----------

remove_java() ( set -e
sudo apt remove --purge -y \
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
sudo apt remove --purge -y \
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
wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-10.0

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
# Add cloudflare gpg key
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

# Add this repo to your apt repositories
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ trixie main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
# Install
sudo apt-get update && sudo apt-get install -y cloudflare-warp
)

# ---------- Setup fcitx5 (giữ nguyên) ----------

setup_fcitx5() ( set -eE
trap 'echo "  -> lệnh lỗi: $BASH_COMMAND (mã $?)" >&2' ERR
sudo apt install -y fcitx5 fcitx5-unikey fcitx5-config-qt

# im-config 1.1: dùng -w để ghi cấu hình
im-config -w fcitx5
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
