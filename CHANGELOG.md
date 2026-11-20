# Changelog

Định dạng theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/), phiên bản theo [SemVer](https://semver.org/).
Mục của mỗi tag được dùng làm ghi chú GitHub Release.

## [v1.4.0] - 2026-11-20

### Thay đổi
- Node.js **26 LTS** (thay 24) qua nvm **v0.41.0**, theo hướng dẫn chính thức trên nodejs.org; dùng **pnpm** thay npm: cài Corepack (`npm install -g corepack`, Node 25+ không còn kèm) rồi `corepack enable pnpm`. Không hỏi Y/n khi Corepack tải pnpm lần đầu.
- Ubuntu/Debian: bước "Gỡ Java cũ (apt)", "Gỡ .NET 6" chỉ gỡ gói **đang cài**; máy cài mới không có Java/.NET thì **bỏ qua** (⊘) kèm lý do. "Dọn dẹp + xóa alternatives" bỏ qua khi không có gì sót lại. Kali giữ nguyên như cũ.

### Thêm
- Ubuntu/Debian: bước **"Cài công cụ CLI (clipboard, Python, shellcheck, pipx)"** — kiểm tra và cài gói còn thiếu: `wl-clipboard xclip python3-jsonschema python-is-python3 shellcheck pipx`.
- Smoke test: kiểm tra Node 26, `corepack`, `pnpm`, các công cụ CLI và các bước gỡ Java/.NET được bỏ qua trên Ubuntu/Debian.

## [v1.3.0] - 2026-11-19

### Thêm
- Debian: bước **"GNOME giống Kali (extension + tweak)"** — cài và bật bộ extension như Kali (Apps Menu, Dash to Dock, DING, Places, Removable Drive Menu, System Monitor, Tiling Assistant, AppIndicators, User Themes, VPN IP), GNOME Tweaks, Extension Manager; ghi gsettings override theo `kali-themes` (nút minimize/maximize, dark mode, phím tắt, cấu hình dock, màu GNOME Terminal). VPN IP lấy từ GitLab Kali (ghim tag). Bỏ qua (⊘) khi máy không có GNOME.
- Smoke test: Debian 13 test nhánh có GNOME.

### Thay đổi
- CI/`tests/run-local.sh` chỉ test Ubuntu 26.04, Debian 13, Kali rolling (bỏ Ubuntu 24.04, Debian 12 cho nhanh). Script vẫn chạy trên bản cũ nhưng không còn được test.

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
