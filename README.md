# kali-setup

Setup developer chuẩn sau khi cài mới Kali Linux (Java/SDKMAN, .NET 10, Node 24/nvm, gh, glab, WARP, Podman, fcitx5...).

Hỗ trợ **Kali** (chuẩn gốc), **Ubuntu** và **Debian** — script tự nhận diện distro qua `/etc/os-release`.

## Khác biệt theo distro

| | Kali | Debian | Ubuntu |
|---|---|---|---|
| Chuẩn bị môi trường | — (đã có sẵn) | cài gói nền + zsh kiểu Kali | cài gói nền + zsh kiểu Kali |
| .NET 10 | repo Microsoft `debian/13` | repo Microsoft `debian/<VERSION_ID>` | gói Ubuntu / `ppa:dotnet/backports` |
| Repo WARP | `trixie` | codename (fallback `trixie`) | codename (fallback `noble`) |

Trên Ubuntu/Debian, bước **"Chuẩn bị môi trường giống Kali"** chạy đầu tiên:

1. Cài gói mà Kali có sẵn: `git curl wget gnupg zip unzip zsh zsh-autosuggestions zsh-syntax-highlighting command-not-found im-config` (+ `software-properties-common` trên Ubuntu).
2. Cài `~/.zshrc`, `~/.zprofile` mặc định của Kali ([dotfiles/](dotfiles/), lấy từ `/etc/skel` của gói `kali-defaults`) — prompt `┌──(user㉿host)-[~]`, gợi ý lệnh, tô màu cú pháp. `~/.zshrc` cũ được backup thành `~/.zshrc.bak.<thời gian>`.
3. Đổi shell đăng nhập sang zsh (`chsh`), có hiệu lực sau reboot cuối script.
4. Các bước sau chạy với `SHELL=zsh` để nvm/SDKMAN ghi cấu hình vào `~/.zshrc` giống trên Kali.

Nếu bước này lỗi, script dừng luôn (các bước sau phụ thuộc vào nó).

## Cài đặt một dòng

Chạy bằng **user thường** có quyền sudo (không chạy bằng `sudo`), trong một terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/duochou042004/kali-setup/main/install.sh | bash
```

`install.sh` tải trọn vẹn `kali-setup.sh` về thư mục tạm, kiểm tra cú pháp rồi chạy nó với stdin nối vào terminal
(để nhập mật khẩu sudo và đếm ngược 15s trước khi reboot hoạt động đúng). Log: `~/kali-setup.log`.

Debian/Ubuntu bản tối giản chưa có `curl`:

```bash
wget -qO- https://raw.githubusercontent.com/duochou042004/kali-setup/main/install.sh | bash
```

> Máy sẽ **tự reboot** ở cuối (Ctrl+C trong 15s để hủy).

### Ghim phiên bản (khuyến nghị)

```bash
curl -fsSL https://raw.githubusercontent.com/duochou042004/kali-setup/v1.0.0/install.sh | KALI_SETUP_REF=v1.0.0 bash
```

### Kiểm tra checksum

```bash
curl -fsSL https://raw.githubusercontent.com/duochou042004/kali-setup/main/install.sh | KALI_SETUP_SHA256=<sha256 của kali-setup.sh> bash
```

| Biến                | Mặc định                     | Ý nghĩa                                   |
|---------------------|------------------------------|-------------------------------------------|
| `KALI_SETUP_REPO`   | `duochou042004/kali-setup`   | Repo GitHub chứa `kali-setup.sh`          |
| `KALI_SETUP_REF`    | `main`                       | Branch / tag / commit                     |
| `KALI_SETUP_URL`    | (tính từ REPO/REF)           | URL đầy đủ tới `kali-setup.sh`            |
| `KALI_SETUP_SHA256` | (trống)                      | Bắt buộc khớp SHA-256 trước khi chạy      |
| `KALI_SETUP_FORCE`  | `0`                          | `1` = thử distro khác theo `ID_LIKE` (Mint, Pop!_OS...) |

## Chạy cục bộ

```bash
git clone https://github.com/duochou042004/kali-setup && cd kali-setup && ./kali-setup.sh
```

> Đừng pipe trực tiếp `kali-setup.sh` vào bash — hãy dùng `install.sh`.
>
> `KALI_SETUP_SHA256` chỉ kiểm tra `kali-setup.sh`; `dotfiles/` được tải từ cùng ref (ghim tag để cố định).

