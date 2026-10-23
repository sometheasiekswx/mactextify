#!/bin/bash
# Build a local checkout and install into a user-owned prefix. No downloads.
set -euo pipefail
umask 077
repo=$(cd -- "$(dirname -- "$0")/.." && pwd)
"$repo/scripts/check-prerequisites.sh"
# Build with the selected Xcode rather than an unrelated Swift on PATH.
export PATH="$(dirname "$(xcrun --find swift)"):$PATH"
prefix=${1:-"$HOME/.local"}
if [ "$#" -gt 1 ] || [[ "$prefix" != /* ]]; then
  echo 'Usage: scripts/install.sh [/absolute/user-owned/prefix]' >&2; exit 2
fi
if [ -L "$prefix" ]; then echo 'Refusing a symlink installation prefix.' >&2; exit 2; fi
mkdir -p -- "$prefix"
prefix=$(cd -- "$prefix" && pwd -P)
for directory in "$prefix/bin" "$prefix/share" "$prefix/share/mactextify"; do
  [ ! -L "$directory" ] || { echo 'Refusing symlinked install directories.' >&2; exit 2; }
done
base="$prefix/share/mactextify"
if [ -e "$base" ] && [ ! -f "$base/.installation-owner" ]; then
  echo 'Installation directory exists without an ownership marker; refusing to overwrite.' >&2; exit 2
fi
mkdir -p -- "$prefix/bin" "$base"
if ! mkdir "$base/.install-lock" 2>/dev/null; then
  echo 'Installation is locked. If a previous installer was interrupted, remove .install-lock only after confirming it has stopped.' >&2; exit 2
fi
trap 'rmdir "$base/.install-lock" 2>/dev/null || true' EXIT
if [ -e "$base/.installation-owner" ]; then
  [ ! -L "$base/.installation-owner" ] && [ "$(cat "$base/.installation-owner")" = 'mactextify-install-v1' ] || exit 2
else
  printf '%s\n' 'mactextify-install-v1' > "$base/.installation-owner"
fi
for name in mactextify 'MacTextify.command' mactextify-uninstall; do
  target="../share/mactextify/current/$name"
  path="$prefix/bin/$name"
  if [ -e "$path" ] || [ -L "$path" ]; then
    [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ] || {
      echo "Refusing unrelated executable: $name" >&2; exit 2;
    }
  fi
done
[ ! -L "$base/versions" ] || exit 2
mkdir -p "$base/versions"
cd "$repo"
swift build -c release
binary_dir=$(swift build -c release --show-bin-path)
version=$("$binary_dir/mactextify" --version)
slot=$(cat "$binary_dir/mactextify" "$repo/scripts/MacTextify.command" "$repo/scripts/uninstall.sh" | shasum -a 256 | awk '{print $1}')
release="$base/versions/$slot"
[ ! -L "$release" ] || exit 2
if [ ! -e "$release" ]; then
  stage=$(mktemp -d "$base/versions/.stage.XXXXXX")
  cp "$binary_dir/mactextify" "$stage/mactextify"
  cp "$repo/scripts/MacTextify.command" "$stage/MacTextify.command"
  cp "$repo/scripts/uninstall.sh" "$stage/mactextify-uninstall"
  chmod 755 "$stage/mactextify" "$stage/MacTextify.command" "$stage/mactextify-uninstall"
  printf '%s\n' "$version" > "$stage/VERSION"
  (cd "$stage" && shasum -a 256 mactextify 'MacTextify.command' mactextify-uninstall VERSION > SHA256SUMS)
  mv "$stage" "$release"
fi
(cd "$release" && shasum -a 256 -c SHA256SUMS >/dev/null)
if [ -e "$base/current" ] || [ -L "$base/current" ]; then
  [ -L "$base/current" ] || { echo 'current is not a managed symlink.' >&2; exit 2; }
  old=$(readlink "$base/current")
  [[ "$old" =~ ^versions/[a-f0-9]{64}$ ]] || exit 2
fi
switch="$base/.switch-$$"
ln -s "versions/$slot" "$switch"
mv -fh "$switch" "$base/current"
for name in mactextify 'MacTextify.command' mactextify-uninstall; do
  path="$prefix/bin/$name"
  if [ ! -L "$path" ]; then ln -s "../share/mactextify/current/$name" "$path"; fi
done
printf 'Installed mactextify %s into %s/bin\n' "$version" "$prefix"
printf 'Add that bin directory to PATH, or use the full executable path.\n'
printf 'Finder launcher: %s/bin/MacTextify.command\n' "$prefix"
