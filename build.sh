#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="lil agents"
BUNDLE_ID="com.lilagents.app"
APP_BUNDLE="$PROJECT_DIR/build/${APP_NAME}.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "==> Building with Swift Package Manager..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

# Find the built executable
BUILD_DIR="$(swift build -c release --show-bin-path 2>/dev/null)"
EXECUTABLE="$BUILD_DIR/LilAgents"

if [ ! -f "$EXECUTABLE" ]; then
    echo "ERROR: Executable not found at $EXECUTABLE"
    exit 1
fi

echo "==> Assembling app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$EXECUTABLE" "$MACOS_DIR/lil agents"

# Copy SPM resource bundle (contains Sounds/ and .mov files)
RESOURCE_BUNDLE="$BUILD_DIR/LilAgents_LilAgents.bundle"
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$RESOURCES_DIR/"
    # Also copy resources to top-level Resources for Bundle.main access
    if [ -d "$RESOURCE_BUNDLE/Sounds" ]; then
        cp -R "$RESOURCE_BUNDLE/Sounds" "$RESOURCES_DIR/Sounds"
    fi
    for mov in "$RESOURCE_BUNDLE"/*.mov; do
        [ -f "$mov" ] && cp "$mov" "$RESOURCES_DIR/"
    done
fi

# Also copy resources directly (in case Bundle.main looks here)
cp -R "$PROJECT_DIR/LilAgents/Sounds" "$RESOURCES_DIR/Sounds" 2>/dev/null || true
cp "$PROJECT_DIR/LilAgents/walk-bruce-01.mov" "$RESOURCES_DIR/" 2>/dev/null || true
cp "$PROJECT_DIR/LilAgents/walk-jazz-01.mov" "$RESOURCES_DIR/" 2>/dev/null || true

# Compile asset catalog
echo "==> Compiling asset catalog..."
xcrun actool "$PROJECT_DIR/LilAgents/Assets.xcassets" \
    --compile "$RESOURCES_DIR" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$CONTENTS/assetcatalog_generated_info.plist" 2>&1 || echo "Warning: actool failed, copying icons manually"

# If actool didn't produce the icon, create icns manually
if [ ! -f "$RESOURCES_DIR/AppIcon.icns" ]; then
    echo "==> Creating app icon manually..."
    ICONSET_DIR="$RESOURCES_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png" "$ICONSET_DIR/icon_16x16@2x.png"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png" "$ICONSET_DIR/icon_32x32@2x.png"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" "$ICONSET_DIR/icon_128x128@2x.png"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png" "$ICONSET_DIR/icon_256x256@2x.png"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png"
    cp "$PROJECT_DIR/LilAgents/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" "$ICONSET_DIR/icon_512x512@2x.png"
    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null || true
    rm -rf "$ICONSET_DIR"
fi

# Copy menu bar icon images directly (NSImage(named:) finds them in Resources)
cp "$PROJECT_DIR/LilAgents/Assets.xcassets/MenuBarIcon.imageset/bubble-icon.png" "$RESOURCES_DIR/MenuBarIcon.png" 2>/dev/null || true
cp "$PROJECT_DIR/LilAgents/Assets.xcassets/MenuBarIcon.imageset/bubble-icon@2x.png" "$RESOURCES_DIR/MenuBarIcon@2x.png" 2>/dev/null || true

# Create Info.plist
echo "==> Creating Info.plist..."
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>lil agents</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.lilagents.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>lil agents</string>
    <key>CFBundleDisplayName</key>
    <string>lil agents</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>SUFeedURL</key>
    <string>https://lilagents.xyz/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>8QOCrY3j4crgz4iR5lmxyv+rA5vnqK6Qtd1XheMllP8=</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUAllowsAutomaticUpdates</key>
    <true/>
</dict>
</plist>
PLIST

# Copy entitlements
cp "$PROJECT_DIR/LilAgents/LilAgents.entitlements" "$CONTENTS/entitlements.plist"

# Copy Sparkle framework into app bundle
echo "==> Bundling Sparkle framework..."
SPARKLE_FRAMEWORK=$(find "$PROJECT_DIR/.build/artifacts" -name "Sparkle.framework" -type d 2>/dev/null | head -1)
if [ -z "$SPARKLE_FRAMEWORK" ]; then
    # Try to find it in the build directory
    SPARKLE_FRAMEWORK=$(find "$PROJECT_DIR/.build" -name "Sparkle.framework" -type d 2>/dev/null | head -1)
fi
if [ -n "$SPARKLE_FRAMEWORK" ]; then
    mkdir -p "$CONTENTS/Frameworks"
    cp -R "$SPARKLE_FRAMEWORK" "$CONTENTS/Frameworks/"
    echo "   Sparkle framework bundled."
else
    echo "   Warning: Sparkle.framework not found - auto-updates may not work"
fi

# Ad-hoc code sign
echo "==> Code signing..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>&1 || echo "Warning: Code signing failed (app may still work)"

echo ""
echo "==> Build complete: $APP_BUNDLE"
echo ""
