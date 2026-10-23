#!/bin/bash
set -eu
bin_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ ! -x "$bin_dir/screenshot-ocr" ]; then
  echo 'screenshot-ocr is missing. Reinstall the tool before processing images.' >&2
  exit 2
fi
# No file paths are interpolated into AppleScript source.
if ! folder=$(/usr/bin/osascript <<'APPLESCRIPT'
try
  return POSIX path of (choose folder with prompt "Choose a folder of screenshots to extract locally")
on error number -128
  return ""
end try
APPLESCRIPT
); then exit 2; fi
[ -n "$folder" ] || exit 0
if ! choice=$(/usr/bin/osascript <<'APPLESCRIPT'
try
  return button returned of (display dialog "Keep originals in place, or move successful originals into Processed? Existing duplicate copies stay in place." buttons {"Cancel", "Keep originals", "Archive originals"} default button "Keep originals" cancel button "Cancel")
on error number -128
  return "Cancel"
end try
APPLESCRIPT
); then exit 2; fi
case "$choice" in
  'Keep originals') "$bin_dir/screenshot-ocr" process --folder "$folder" ;;
  'Archive originals') "$bin_dir/screenshot-ocr" process --folder "$folder" --archive ;;
  *) exit 0 ;;
esac
