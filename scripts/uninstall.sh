#!/bin/bash
set -euo pipefail
# Invoke via the installed prefix/bin/screenshot-ocr-uninstall link.
[ "$#" -eq 0 ] || { echo 'This uninstaller takes no arguments.' >&2; exit 2; }
bin_dir=$(cd -- "$(dirname -- "$0")" && pwd -P)
prefix=$(dirname -- "$bin_dir")
base="$prefix/share/screenshot-ocr"
[ ! -L "$base" ] && [ ! -L "$base/.installation-owner" ] && [ "$(cat "$base/.installation-owner")" = 'screenshot-ocr-install-v1' ] || {
  echo 'Not an owned installation. Run the installed bin/screenshot-ocr-uninstall link.' >&2; exit 2;
}
if ! mkdir "$base/.install-lock" 2>/dev/null; then echo 'Installation is locked.' >&2; exit 2; fi
trap 'rmdir "$base/.install-lock" 2>/dev/null || true' EXIT
for name in screenshot-ocr 'Process Screenshots.command' screenshot-ocr-uninstall; do
  path="$bin_dir/$name"
  [ -L "$path" ] && [ "$(readlink "$path")" = "../share/screenshot-ocr/current/$name" ] || {
    echo "Unrelated or modified install entry: $name; nothing removed." >&2; exit 2;
  }
done
[ ! -L "$base/versions" ] && [ -d "$base/versions" ] || exit 2
# Verify all owned files before removing any. Extra files/directories are retained.
for release in "$base"/versions/*; do
  [ -e "$release" ] || continue
  slot=$(basename "$release")
  [[ "$slot" =~ ^[a-f0-9]{64}$ ]] || continue
  [ -d "$release" ] && [ ! -L "$release" ] || exit 2
  for name in screenshot-ocr 'Process Screenshots.command' screenshot-ocr-uninstall VERSION SHA256SUMS; do
    [ -f "$release/$name" ] && [ ! -L "$release/$name" ] || exit 2
  done
  (cd "$release" && shasum -a 256 -c SHA256SUMS >/dev/null) || {
    echo 'Installed files were modified; refusing removal.' >&2; exit 2;
  }
done
for name in screenshot-ocr 'Process Screenshots.command' screenshot-ocr-uninstall; do rm -- "$bin_dir/$name"; done
[ ! -L "$base/current" ] || rm -- "$base/current"
for release in "$base"/versions/*; do
  [ -e "$release" ] || continue
  slot=$(basename "$release")
  [[ "$slot" =~ ^[a-f0-9]{64}$ ]] || continue
  rm -- "$release/screenshot-ocr" "$release/Process Screenshots.command" "$release/screenshot-ocr-uninstall" "$release/VERSION" "$release/SHA256SUMS"
  rmdir "$release" 2>/dev/null || true
done
rm -- "$base/.installation-owner"
rmdir "$base/.install-lock"
trap - EXIT
rmdir "$base/versions" "$base" 2>/dev/null || true
printf 'Uninstalled. All project images, exports and receipts were preserved.\n'
