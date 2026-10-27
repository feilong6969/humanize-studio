#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="dist/HumanizeStudio.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -parse-as-library -O -framework SwiftUI -framework AppKit -framework Security \
  macos/HumanizeStudio.swift -o "$APP/Contents/MacOS/HumanizeStudio"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>HumanizeStudio</string>
<key>CFBundleIdentifier</key><string>dev.feilong.humanizestudio</string>
<key>CFBundleName</key><string>Humanize Studio</string>
<key>CFBundleDisplayName</key><string>Humanize Studio</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
echo "Built $APP"
