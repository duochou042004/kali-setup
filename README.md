# kali-setup

Setup developer chuẩn sau khi cài mới Kali Linux (Java/SDKMAN, .NET 10, Node 24/nvm, gh, glab, WARP, Podman, fcitx5...).

## Cài đặt một dòng

Chạy bằng **user thường** (không `sudo`), trong một terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/duochou042004/kali-setup/main/install.sh | bash
```

`install.sh` tải trọn vẹn `kali-setup.sh` về thư mục tạm, kiểm tra cú pháp rồi chạy nó với stdin nối vào terminal
(để nhập mật khẩu sudo và đếm ngược 15s trước khi reboot hoạt động đúng). Log: `~/kali-setup.log`.

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
| `KALI_SETUP_FORCE`  | `0`                          | `1` = cho chạy trên hệ không phải Kali    |

## Chạy cục bộ

```bash
git clone https://github.com/duochou042004/kali-setup && cd kali-setup && ./kali-setup.sh
```

> Đừng pipe trực tiếp `kali-setup.sh` vào bash — hãy dùng `install.sh`.
