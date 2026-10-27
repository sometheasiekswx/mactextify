#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"
architecture="${1:-native}"
case "$architecture" in
  native) arch_args=() ;;
  arm64|x86_64) arch_args=(--arch "$architecture") ;;
  universal) arch_args=(--arch arm64 --arch x86_64) ;;
  *) printf 'Unsupported architecture: %s\n' "$architecture" >&2; exit 2 ;;
esac
version="$(tr -d '\n' < VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid VERSION' >&2; exit 2; }
swift build -c release --product MacTextifyApp "${arch_args[@]}"
bin_path="$(swift build -c release --show-bin-path "${arch_args[@]}")"
app="$repo/.build/MacTextify.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$repo/assets/"*.icns "$app/Contents/Resources/"
cp "$bin_path/MacTextifyApp" "$app/Contents/MacOS/MacTextifyApp"
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>MacTextify</string>
<key>CFBundleDisplayName</key><string>MacTextify</string>
<key>CFBundleIdentifier</key><string>com.mactextify.desktop</string>
<key>CFBundleExecutable</key><string>MacTextifyApp</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$version</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
printf '%s\n' "$app"
