#!/usr/bin/env bash
# tests/run-local.sh - Chạy tests/smoke.sh trên nhiều distro song song bằng podman (hoặc docker)
#
#   tests/run-local.sh                          # mặc định: tất cả distro như CI
#   tests/run-local.sh ubuntu:24.04 debian:13   # chỉ một số image
set -uo pipefail

cd "$(dirname -- "$0")/.." || exit 1
engine="$(command -v podman || command -v docker)" || { echo "Cần podman hoặc docker." >&2; exit 1; }
images=("$@")
(( ${#images[@]} )) || images=(ubuntu:24.04 ubuntu:26.04 debian:12 debian:13 kalilinux/kali-rolling)

logdir="$(mktemp -d "${TMPDIR:-/tmp}/kali-setup-smoke.XXXXXX")"
echo "Log: $logdir"
for img in "${images[@]}"; do
  name="${img//[\/:]/_}"
  ref="$img"; [[ "$ref" == */* ]] || ref="library/$ref"   # tên đầy đủ, tránh podman hỏi registry
  "$engine" run --rm -v "$PWD:/src:ro" "docker.io/$ref" bash /src/tests/smoke.sh \
    > "$logdir/$name.log" 2>&1 &
  echo "  chạy $img (pid $!)"
done
wait

rc=0
for img in "${images[@]}"; do
  name="${img//[\/:]/_}"
  if grep -q 'SMOKE TEST: PASS' "$logdir/$name.log"; then r=PASS; else r=FAIL; rc=1; fi
  printf '%-28s %s\n' "$img" "$r"
  sed -n '/^Kết quả/,$p' "$logdir/$name.log" | sed 's/^/    /'
done
exit "$rc"
