#!/bin/bash
set -euo pipefail

APP_NAME="StatusDot"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy resource bundle
if [ -d "$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle" ]; then
    cp -R "$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle" "$APP_BUNDLE/Contents/Resources/"
fi

# Copy app icon for Finder
if [ -f "$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle/Resources/AppIcon.png" ]; then
    cp "$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle/Resources/AppIcon.png" "$APP_BUNDLE/Contents/Resources/"
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>StatusDot</string>
    <key>CFBundleIdentifier</key>
    <string>com.statusdot.app</string>
    <key>CFBundleName</key>
    <string>StatusDot</string>
    <key>CFBundleDisplayName</key>
    <string>StatusDot</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "Done: $APP_BUNDLE"
echo ""
echo "Install with:"
echo "  cp -R \"$APP_BUNDLE\" /Applications/"
