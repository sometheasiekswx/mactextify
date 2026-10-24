#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"
swift build -c release --product MacTextifyApp
app="$repo/.build/MacTextify.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$repo/assets/"*.icns "$app/Contents/Resources/"
cp "$repo/.build/release/MacTextifyApp" "$app/Contents/MacOS/MacTextifyApp"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>MacTextify</string>
<key>CFBundleDisplayName</key><string>MacTextify</string>
<key>CFBundleIdentifier</key><string>com.mactextify.desktop</string>
<key>CFBundleExecutable</key><string>MacTextifyApp</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.3.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
printf '%s\n' "$app"
