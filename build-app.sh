#!/usr/bin/env bash
# Build a Cheetos.app bundle (menu-bar app, no dock icon).
set -euo pipefail

cd "$(dirname "$0")"

CONFIG="${CONFIG:-release}"
swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
APP="Cheetos.app"
CONTENTS="$APP/Contents"

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

cp "$BIN_DIR/Cheetos" "$CONTENTS/MacOS/Cheetos"
if [ -d "$BIN_DIR/Cheetos_Cheetos.bundle" ]; then
  cp -R "$BIN_DIR/Cheetos_Cheetos.bundle" "$CONTENTS/Resources/"
fi

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Cheetos</string>
  <key>CFBundleDisplayName</key><string>Cheetos</string>
  <key>CFBundleIdentifier</key><string>com.local.cheetos</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleExecutable</key><string>Cheetos</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  echo "Codesigning with: $CODESIGN_IDENTITY"
  codesign --force --options runtime --timestamp \
    --sign "$CODESIGN_IDENTITY" "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"
else
  echo "Ad-hoc signing (set CODESIGN_IDENTITY to use Developer ID)"
  codesign --force --sign - "$APP"
fi

echo "Built $APP"
echo "Run it with:  open ./$APP"
