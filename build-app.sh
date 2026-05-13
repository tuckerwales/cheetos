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
# Copy resources into Contents/Resources (Apple-standard location). The Swift
# code looks up `cheatsheets/` via Bundle.main first, falling back to
# Bundle.module for `swift run` development.
if [ -d "$BIN_DIR/Cheetos_Cheetos.bundle/cheatsheets" ]; then
  cp -R "$BIN_DIR/Cheetos_Cheetos.bundle/cheatsheets" "$CONTENTS/Resources/"
fi
if [ -f "$BIN_DIR/Cheetos_Cheetos.bundle/Logo.png" ]; then
  cp "$BIN_DIR/Cheetos_Cheetos.bundle/Logo.png" "$CONTENTS/Resources/"
fi

# Build AppIcon.icns from assets/AppIcon/icon-{256,512,1024}.png using sips +
# iconutil. Smaller sizes are downscaled from the 256px master.
ICON_SRC="assets/AppIcon"
if [ -f "$ICON_SRC/icon-1024.png" ]; then
  ICONSET="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "$ICONSET"
  sips -z 16   16   "$ICON_SRC/icon-256.png"  --out "$ICONSET/icon_16x16.png"      > /dev/null
  sips -z 32   32   "$ICON_SRC/icon-256.png"  --out "$ICONSET/icon_16x16@2x.png"   > /dev/null
  sips -z 32   32   "$ICON_SRC/icon-256.png"  --out "$ICONSET/icon_32x32.png"      > /dev/null
  sips -z 64   64   "$ICON_SRC/icon-256.png"  --out "$ICONSET/icon_32x32@2x.png"   > /dev/null
  sips -z 128  128  "$ICON_SRC/icon-256.png"  --out "$ICONSET/icon_128x128.png"    > /dev/null
  cp "$ICON_SRC/icon-256.png"  "$ICONSET/icon_128x128@2x.png"
  cp "$ICON_SRC/icon-256.png"  "$ICONSET/icon_256x256.png"
  cp "$ICON_SRC/icon-512.png"  "$ICONSET/icon_256x256@2x.png"
  cp "$ICON_SRC/icon-512.png"  "$ICONSET/icon_512x512.png"
  cp "$ICON_SRC/icon-1024.png" "$ICONSET/icon_512x512@2x.png"
  iconutil -c icns "$ICONSET" -o "$CONTENTS/Resources/AppIcon.icns"
  rm -rf "$ICONSET"
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
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Strip resource forks / Finder info / quarantine xattrs that would otherwise
# cause `codesign` to reject the bundle with "resource fork ... not allowed".
xattr -rc "$APP"

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
