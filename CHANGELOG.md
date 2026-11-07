# Changelog

Định dạng theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/), phiên bản theo [SemVer](https://semver.org/).
Mục của mỗi tag được dùng làm ghi chú GitHub Release.

## [v1.2.1] - 2026-11-08

### Sửa
- Bước "Chrome + fcitx5" báo **lỗi** trên mọi máy chưa cài Google Chrome (Kali/Ubuntu/Debian cài mới đều chưa có). Giờ báo **bỏ qua** (⊘) kèm lý do và cách xử lý, không tính là lỗi.

### Thêm
- Trạng thái "bỏ qua" cho bước: hàm bước gọi `skip "lý do"`; tổng kết hiện `n/N bước OK, k bỏ qua` và danh sách "Các bước bỏ qua (không phải lỗi)".
- Smoke test không còn chấp nhận bước lỗi nào; Kali test nhánh đã cài Chrome, Ubuntu/Debian test nhánh bỏ qua.

## [v1.2.0] - 2026-11-08

### Thêm
- Tag tự ghim phiên bản: `curl -fsSL .../v1.2.0/install.sh | bash` tự lấy `kali-setup.sh` + `dotfiles/` của đúng tag, không cần `KALI_SETUP_REF`. Phát hành bằng `scripts/release.sh`.
- Giao diện: banner kiểu prompt Kali (phiên bản, distro, số bước, log), tiến độ `[n/N]`, ✓/✗ kèm thời gian sau mỗi bước, tổng kết `n/N bước OK`.
- Khi xong: tiếng bíp + thông báo desktop (`notify-send`) nếu đang trong phiên đồ họa.
- Tắt màu bằng `NO_COLOR=1`; tự tắt màu khi output không phải terminal.
- CI (GitHub Actions): `bash -n`, shellcheck, smoke test chạy toàn bộ script trên Ubuntu 24.04/26.04, Debian 12/13, Kali rolling.
- Release tự động khi push tag: kiểm tra tag đã ghim, tạo GitHub Release với ghi chú từ CHANGELOG, `SHA256SUMS` và lệnh cài kèm checksum.
- `tests/run-local.sh` chạy smoke test song song bằng podman/docker.

### Thay đổi
- Danh sách bước gom vào mảng `STEPS` (thứ tự và nội dung các bước không đổi).

## [v1.1.1] - 2026-11-07

### Thêm
- Ubuntu/Debian: `/etc/zsh/zprofile` nạp `/etc/profile` giống Kali (`dpkg-divert --local`), để zsh đăng nhập có `/etc/profile.d/*`.

## [v1.1.0] - 2026-11-07

### Thêm
- Hỗ trợ Ubuntu và Debian: tự nhận diện distro; bước đầu cài gói nền, zsh + `.zshrc`/`.zprofile` của Kali, đổi shell đăng nhập sang zsh.
- .NET 10 theo distro (Ubuntu: archive/`ppa:dotnet/backports`; Debian: repo Microsoft theo phiên bản); repo WARP theo codename có fallback; `im-config -w`/`-n` theo khả năng.

### Thay đổi
- Chỉ gỡ gói mà apt/dpkg biết tới (trên Kali kết quả không đổi).

## [v1.0.0] - 2026-11-07

### Thêm
- Cài đặt một dòng `curl -fsSL .../install.sh | bash` cho `kali-setup.sh` (setup chuẩn Kali, giữ nguyên).

[v1.2.1]: https://github.com/duochou042004/kali-setup/compare/v1.2.0...v1.2.1
[v1.2.0]: https://github.com/duochou042004/kali-setup/compare/v1.1.1...v1.2.0
[v1.1.1]: https://github.com/duochou042004/kali-setup/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/duochou042004/kali-setup/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/duochou042004/kali-setup/tree/v1.0.0
