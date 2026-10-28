#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo"
architecture="${1:-native}"
case "$architecture" in
  native) architecture="$(uname -m)"; arch_args=(--arch "$architecture") ;;
  arm64|x86_64) arch_args=(--arch "$architecture") ;;
  universal) arch_args=(--arch arm64 --arch x86_64) ;;
  *) printf 'Unsupported architecture: %s\n' "$architecture" >&2; exit 2 ;;
esac
version="$(tr -d '\n' < VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid VERSION' >&2; exit 2; }
public_key="$(tr -d '\n' < config/update-public-key.txt)"
[[ "$public_key" =~ ^[A-Za-z0-9+/]{43}=$ ]] || { echo 'Invalid update public key' >&2; exit 2; }
swift build -c release --product MacTextifyApp "${arch_args[@]}"
bin_path="$(swift build -c release --show-bin-path "${arch_args[@]}")"
app="$repo/.build/MacTextify.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$repo/assets/"*.icns "$app/Contents/Resources/"
cp "$repo/LICENSE" "$app/Contents/Resources/LICENSE"
cp "$bin_path/MacTextifyApp" "$app/Contents/MacOS/MacTextifyApp"
mkdir -p "$app/Contents/Frameworks"
ditto "$repo/.build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework" "$app/Contents/Frameworks/Sparkle.framework"
cp "$repo/.build/artifacts/sparkle/Sparkle/LICENSE" "$app/Contents/Resources/Sparkle-LICENSE"
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
<key>CFBundleVersion</key><string>$version</string>
<key>SUFeedURL</key><string>https://mactextify.vercel.app/updates/$architecture.xml</string>
<key>SUPublicEDKey</key><string>$public_key</string>
<key>SUEnableAutomaticChecks</key><false/>
<key>SUAllowsAutomaticUpdates</key><false/>
<key>SUAutomaticallyUpdate</key><false/>
<key>SUSendProfileInfo</key><false/>
<key>SUVerifyUpdateBeforeExtraction</key><true/>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
printf '%s\n' "$app"
