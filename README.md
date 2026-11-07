# kali-setup

[![CI](https://github.com/duochou042004/kali-setup/actions/workflows/ci.yml/badge.svg)](https://github.com/duochou042004/kali-setup/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/duochou042004/kali-setup)](https://github.com/duochou042004/kali-setup/releases/latest)

Setup developer chuẩn sau khi cài mới Kali Linux (Java/SDKMAN, .NET 10, Node 24/nvm, gh, glab, WARP, Podman, fcitx5...).

Hỗ trợ **Kali** (chuẩn gốc), **Ubuntu** và **Debian** — script tự nhận diện distro qua `/etc/os-release`.

## Cài đặt một dòng

Chạy bằng **user thường** có quyền sudo (không chạy bằng `sudo`), trong một terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/duochou042004/kali-setup/main/install.sh | bash
```

Debian/Ubuntu bản tối giản chưa có `curl`:

```bash
wget -qO- https://raw.githubusercontent.com/duochou042004/kali-setup/main/install.sh | bash
```

> Máy sẽ **tự reboot** ở cuối (Ctrl+C trong 15s để hủy). Log: `~/kali-setup.log`.

`| bash` chỉ là chương trình đọc script (script viết bằng cú pháp bash) — không đổi terminal của bạn,
nên trên Kali đang dùng zsh vẫn chạy y như vậy.

### Cố định phiên bản

Thay `main` bằng tag (xem [Releases](https://github.com/duochou042004/kali-setup/releases)) — từ **v1.2.0**,
`install.sh` của tag nào tự lấy `kali-setup.sh` + `dotfiles/` của đúng tag đó:

```bash
curl -fsSL https://raw.githubusercontent.com/duochou042004/kali-setup/v1.2.1/install.sh | bash
```

Mỗi GitHub Release có sẵn lệnh cài kèm checksum (`KALI_SETUP_SHA256`) và file `SHA256SUMS`.

> Tag cũ (v1.0.0 – v1.1.1) chưa tự ghim, cần thêm `KALI_SETUP_REF=<tag>` trước `bash`.

### Khi chạy trông như thế nào

```text
┌──(kali-setup v1.2.1)──────────────────────────────────────────
│ Distro  : Ubuntu 24.04.3 LTS (ubuntu 24.04 noble)
│ User    : duong@laptop
│ Số bước : 16 (gồm bước chuẩn bị môi trường giống Kali)
│ Log     : /home/duong/kali-setup.log
└───────────────────────────────────────────────────────────────

==> [1/16] Chuẩn bị môi trường giống Kali (gói nền + zsh)
...
✓ Chuẩn bị môi trường giống Kali (gói nền + zsh) (1m01s)

==> Tổng kết (log: /home/duong/kali-setup.log)
Thời gian từng bước:
  ✓  1m01s  Chuẩn bị môi trường giống Kali (gói nền + zsh)
  ✓  0m08s  Gỡ Java cũ (apt)
  ...
  ⊘  0m00s  Chrome + fcitx5 (bỏ qua)
  ✓  0m09s  apt update/upgrade/clean
  Tổng: 4m36s  ·  15/16 bước OK, 1 bỏ qua
Các bước bỏ qua (không phải lỗi):
  ⊘ Chrome + fcitx5: chưa cài Google Chrome - cài Chrome rồi chạy lại script để bật gõ tiếng Việt cho Chrome
Không có bước nào lỗi.
```

- `✓` thành công · `✗` lỗi (liệt kê ở "Các bước lỗi", xem log) · `⊘` **bỏ qua**: bước không áp dụng được
  trên máy này, có ghi lý do, **không phải lỗi**.
- Hiện chỉ có **"Chrome + fcitx5"** có thể bị bỏ qua: bước này chỉ chỉnh shortcut của Google Chrome
  (gói `google-chrome-stable`), mà Kali/Ubuntu/Debian cài mới đều chưa có Chrome. Cài Chrome rồi chạy lại script.

Xong sẽ có tiếng bíp + thông báo desktop (`notify-send`, nếu có). Tắt màu: `NO_COLOR=1`.

## Khác biệt theo distro

| | Kali | Debian | Ubuntu |
|---|---|---|---|
| Chuẩn bị môi trường | — (đã có sẵn) | cài gói nền + zsh kiểu Kali | cài gói nền + zsh kiểu Kali |
| .NET 10 | repo Microsoft `debian/13` | repo Microsoft `debian/<VERSION_ID>` | gói Ubuntu / `ppa:dotnet/backports` |
| Repo WARP | `trixie` | codename (fallback `trixie`) | codename (fallback `noble`) |
| `im-config` | `-w` | `-w` nếu có, không thì `-n` | `-w` nếu có, không thì `-n` |

Trên Ubuntu/Debian, bước **"Chuẩn bị môi trường giống Kali"** chạy đầu tiên:

1. Cài gói mà Kali có sẵn: `git curl wget gnupg zip unzip zsh zsh-autosuggestions zsh-syntax-highlighting command-not-found im-config` (+ `software-properties-common` trên Ubuntu).
2. Cài `~/.zshrc`, `~/.zprofile` mặc định của Kali ([dotfiles/](dotfiles/), lấy từ `/etc/skel` của gói `kali-defaults`) — prompt `┌──(user㉿host)-[~]`, gợi ý lệnh, tô màu cú pháp, Tab completion dạng menu. `~/.zshrc` cũ được backup thành `~/.zshrc.bak.<thời gian>`.
3. Giống Kali: `/etc/zsh/zprofile` nạp thêm `/etc/profile` (+ `/etc/profile.d/*`, ví dụ PATH snap/flatpak). Làm bằng `dpkg-divert --local` (bản gốc giữ ở `/etc/zsh/zprofile.original`) nên nâng cấp `zsh-common` không ghi đè.
4. Đổi shell đăng nhập sang zsh (`chsh`), có hiệu lực sau reboot cuối script.
5. Các bước sau chạy với `SHELL=zsh` để nvm/SDKMAN ghi cấu hình vào `~/.zshrc` giống trên Kali.

Nếu bước này lỗi, script dừng luôn (các bước sau phụ thuộc vào nó).

> Ký tự `㉿` trong prompt cần font có hỗ trợ (Ubuntu Desktop thường có sẵn; nếu hiện ô vuông: `sudo apt install fonts-noto-cjk`).
> Màu/font của ứng dụng terminal (qterminal trên Kali, GNOME Terminal trên Ubuntu) là cài đặt riêng của ứng dụng, script không đổi.

## Biến môi trường

Đặt trước `bash`, ví dụ `curl -fsSL .../install.sh | NO_COLOR=1 bash`.

| Biến                | Mặc định                     | Ý nghĩa                                   |
|---------------------|------------------------------|-------------------------------------------|
| `KALI_SETUP_REPO`   | `duochou042004/kali-setup`   | Repo GitHub chứa `kali-setup.sh`          |
| `KALI_SETUP_REF`    | phiên bản của `install.sh`   | Branch / tag / commit                     |
| `KALI_SETUP_URL`    | (tính từ REPO/REF)           | URL đầy đủ tới `kali-setup.sh`            |
| `KALI_SETUP_SHA256` | (trống)                      | Bắt buộc khớp SHA-256 trước khi chạy      |
| `KALI_SETUP_FORCE`  | `0`                          | `1` = thử distro khác theo `ID_LIKE` (Mint, Pop!_OS...) |
| `NO_COLOR`          | (trống)                      | Đặt bất kỳ giá trị nào để tắt màu         |

> `KALI_SETUP_SHA256` chỉ kiểm tra `kali-setup.sh`; `dotfiles/` được tải từ cùng ref (ghim tag để cố định).

## Chạy cục bộ

```bash
git clone https://github.com/duochou042004/kali-setup && cd kali-setup && ./kali-setup.sh
```

> Đừng pipe trực tiếp `kali-setup.sh` vào bash — hãy dùng `install.sh`.

## Phát triển

| File | Vai trò |
|---|---|
| [kali-setup.sh](kali-setup.sh) | Script chính; danh sách bước nằm trong mảng `STEPS` |
| [install.sh](install.sh) | Bootstrapper cho `curl \| bash` |
| [dotfiles/](dotfiles/) | `.zshrc`/`.zprofile` của Kali cho Ubuntu/Debian |
| [tests/smoke.sh](tests/smoke.sh) | Chạy toàn bộ script trong container rồi kiểm tra kết quả |
| [tests/run-local.sh](tests/run-local.sh) | Chạy smoke test song song trên 5 distro bằng podman/docker |
| [scripts/release.sh](scripts/release.sh) | Phát hành tag tự ghim phiên bản |
| [CHANGELOG.md](CHANGELOG.md) | Lịch sử thay đổi (ghi chú cho GitHub Release lấy từ đây) |

**Test:** `tests/run-local.sh` (hoặc `tests/run-local.sh ubuntu:24.04` cho 1 distro). CI chạy shellcheck
+ smoke test trên Ubuntu 24.04/26.04, Debian 12/13, Kali rolling mỗi lần push lên `main`.
Smoke test **không chấp nhận bước lỗi nào**; Kali giả lập máy đã cài Chrome (test nhánh cấu hình),
Ubuntu/Debian là máy chưa có Chrome (test nhánh bỏ qua).

Bước mới không áp dụng được trên mọi máy thì gọi `skip "lý do"` trong hàm bước (đừng để nó báo lỗi).

**Phát hành phiên bản mới:**

1. Thêm mục `## [vX.Y.Z] - YYYY-MM-DD` vào [CHANGELOG.md](CHANGELOG.md), commit, push `main`, chờ CI xanh.
2. `scripts/release.sh vX.Y.Z --dry-run` để xem trước, rồi `scripts/release.sh vX.Y.Z`.

`release.sh` tạo một commit phát hành (con của `main`, không nằm trên `main`) đổi dòng
`"main"  # @release-ref` trong `install.sh` và `kali-setup.sh` thành tag, gắn tag vào commit đó và push tag.
GitHub Actions kiểm tra tag đã ghim đúng rồi tạo GitHub Release kèm `SHA256SUMS`.
Vì vậy trên GitHub, commit của tag hiện "does not belong to any branch" — đó là chủ ý.

## Ghi công

`dotfiles/zshrc` và `dotfiles/zprofile` sao chép nguyên vẹn từ `/etc/skel` của gói
[kali-defaults](https://gitlab.com/kalilinux/packages/kali-defaults) (Kali Linux).
