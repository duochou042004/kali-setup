#!/usr/bin/env bash
# scripts/release.sh - Phát hành phiên bản mới (tag tự ghim phiên bản)
#
#   scripts/release.sh v1.2.0            # tạo tag + push => GitHub Actions tạo GitHub Release
#   scripts/release.sh v1.2.0 --dry-run  # chỉ xem khác biệt, không tạo tag
#
# Trên nhánh main, install.sh và kali-setup.sh ghi phiên bản là "main" (dòng có "# @release-ref").
# Script này tạo một commit phát hành (con của main, KHÔNG nằm trên main) đổi "main" thành tag,
# rồi gắn tag vào commit đó. Nhờ vậy:
#   curl -fsSL https://raw.githubusercontent.com/<repo>/v1.2.0/install.sh | bash
# tự lấy kali-setup.sh + dotfiles/ của đúng v1.2.0, không cần KALI_SETUP_REF.
# Working tree và nhánh main không bị thay đổi.
set -euo pipefail

die()  { printf '\e[1;31m[release] %s\e[0m\n' "$*" >&2; exit 1; }
info() { printf '\e[1;34m[release]\e[0m %s\n' "$*"; }

tag="${1:-}"; dry_run=0
[[ "${2:-}" == "--dry-run" ]] && dry_run=1
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Dùng: scripts/release.sh vX.Y.Z [--dry-run]"

cd "$(git rev-parse --show-toplevel)"
PINNED_FILES=(install.sh kali-setup.sh)

# --- Kiểm tra trước khi phát hành -------------------------------------------
[[ "$(git branch --show-current)" == main ]] || die "Phải đứng ở nhánh main."
[[ -z "$(git status --porcelain)" ]] || die "Working tree chưa sạch - commit hoặc stash trước."
git fetch -q origin main --tags
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] \
  || die "main local khác origin/main - push/pull trước (CI phải chạy trên đúng commit này)."
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then die "Tag $tag đã tồn tại."; fi
grep -q "^## \[$tag\]" CHANGELOG.md || die "CHANGELOG.md chưa có mục '## [$tag]'."
for f in "${PINNED_FILES[@]}"; do
  bash -n "$f" || die "$f lỗi cú pháp."
  n="$(grep -c '"main"[[:space:]]*# @release-ref' "$f" || true)"
  [[ "$n" == 1 ]] || die "$f phải có đúng 1 dòng \"main\"  # @release-ref (đang có $n)."
done

# --- Tạo commit phát hành trên index tạm (không đụng working tree) -----------
tmp="$(mktemp -d)"; trap 'rm -rf -- "$tmp"' EXIT
export GIT_INDEX_FILE="$tmp/index"
git read-tree HEAD
for f in "${PINNED_FILES[@]}"; do
  git show "HEAD:$f" | sed -E "s/\"main\"([[:space:]]*# @release-ref)/\"$tag\"\1/" > "$tmp/file"
  mode="$(git ls-files -s -- "$f" | cut -d' ' -f1)"
  git update-index --cacheinfo "$mode,$(git hash-object -w "$tmp/file"),$f"
done
tree="$(git write-tree)"
unset GIT_INDEX_FILE
commit="$(git commit-tree "$tree" -p HEAD -m "Release $tag" \
  -m "Ghim phiên bản: \"main\" -> \"$tag\" trong ${PINNED_FILES[*]} (dòng # @release-ref).")"

info "Commit phát hành $commit (cha: $(git rev-parse --short HEAD) trên main):"
git --no-pager diff --stat HEAD "$commit"
git --no-pager diff -U0 HEAD "$commit" | grep -E '^[-+][^-+]' || true

if (( dry_run )); then
  info "--dry-run: không tạo tag."
  exit 0
fi

git tag -a "$tag" "$commit" -m "kali-setup $tag"
git push origin "refs/tags/$tag"
info "Đã push tag $tag. GitHub Actions sẽ tạo GitHub Release:"
info "  https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo '<repo>')/releases/tag/$tag"
