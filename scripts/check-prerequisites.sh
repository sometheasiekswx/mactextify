#!/bin/bash
# Read-only prerequisites for building the Apple-framework executables.
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
[ "$(uname -s)" = Darwin ] || fail 'Requires macOS 14 or later.'
major=$(sw_vers -productVersion | cut -d. -f1)
[ "$major" -ge 14 ] || fail 'Requires macOS 14 or later.'
developer=${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null || true)}
[ -d "$developer/Platforms/MacOSX.platform" ] || fail 'Select a full Xcode installation: set DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer and retry. Command Line Tools alone are not the supported build setup.'
export DEVELOPER_DIR="$developer"
xcrun --sdk macosx --show-sdk-path >/dev/null 2>&1 || fail 'Selected Xcode has no usable macOS SDK. Complete Xcode first-launch setup and retry.'
version=$(xcrun swift --version 2>/dev/null) || fail 'Swift is unavailable in selected Xcode. Complete Xcode first-launch setup and retry.'
number=$(printf '%s\n' "$version" | sed -nE 's/.*Swift version ([0-9]+)\.([0-9]+).*/\1 \2/p' | head -1)
read -r swift_major swift_minor <<< "$number"
[[ "$swift_major" =~ ^[0-9]+$ && "$swift_minor" =~ ^[0-9]+$ ]] || fail 'Cannot determine Swift version.'
if [ "$swift_major" -lt 5 ] || { [ "$swift_major" -eq 5 ] && [ "$swift_minor" -lt 9 ]; }; then fail 'Requires Swift 5.9 or later from full Xcode.'; fi
printf 'Prerequisites OK: macOS %s, Swift %s.%s, full Xcode.\n' "$major" "$swift_major" "$swift_minor"
