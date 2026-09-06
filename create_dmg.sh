#!/bin/bash

# Configuration
APP_NAME="notch-down"
APP_BUNDLE="DerivedData/Build/Products/Release/${APP_NAME}.app"

DMG_TMP="temp_notchdown.dmg"
LICENSE_FILE="License.txt"

# Build a fresh universal (Apple Silicon + Intel) Release binary.
#
# The generic destination matters: with a scheme and no -destination, xcodebuild
# resolves the concrete "My Mac" destination and pins the build to that Mac's
# own architecture, silently producing a single-arch app no matter what ARCHS
# says. A single-arch x86_64 build needs Rosetta on every Apple Silicon Mac.
echo "Building universal Release binary..."
xcodebuild -project notch-down.xcodeproj \
    -scheme "${APP_NAME}" \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath ./DerivedData \
    build || { echo "Error: build failed"; exit 1; }

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Error: App bundle not found at ${APP_BUNDLE}"
    exit 1
fi

# Version comes from the built app, so the installer can never claim a
# different version than the bundle it contains.
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
    "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || echo "1.0")
DMG_NAME="NotchDown_v${VERSION}_Installer.dmg"
VOL_NAME="NotchDown ${VERSION}"

ARCHS_BUILT=$(lipo -archs "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}")
echo "  Architectures: ${ARCHS_BUILT}"
case "${ARCHS_BUILT}" in
    *arm64*) ;;
    *) echo "Error: arm64 slice missing - refusing to ship an Intel-only build"; exit 1 ;;
esac

# Cleanup
echo "Cleaning up old build artifacts..."
hdiutil detach /Volumes/"${VOL_NAME}" 2>/dev/null || true
rm -f "${DMG_NAME}" "${DMG_TMP}"
rm -rf build/dmg_content

# Preparation
mkdir -p build/dmg_content
echo "Preparing contents (App, License, Documentation, Symlinks)..."
cp -R "${APP_BUNDLE}" build/dmg_content/
cp "${LICENSE_FILE}" build/dmg_content/ 2>/dev/null || echo "License file not found, skipping..."
cp "README.md" build/dmg_content/ 2>/dev/null || echo "README not found, skipping..."
cp "QUICK_START.md" build/dmg_content/ 2>/dev/null || echo "Quick Start not found, skipping..."
ln -s /Applications build/dmg_content/Applications

# Create temp DMG
echo "Creating temporary writable disk image..."
hdiutil create -size 100m -fs HFS+ -volname "${VOL_NAME}" "${DMG_TMP}"

# Mount DMG with explicit readwrite and noautoopen
echo "Mounting temporary image (Read-Write)..."
ATTACH_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TMP}")
DEVICE=$(echo "$ATTACH_OUTPUT" | egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 3

# Copy contents to mounted DMG
echo "Copying files to volume..."
cp -R build/dmg_content/* "/Volumes/${VOL_NAME}/"
sync

# Setup window via AppleScript
echo "Setting up Finder window layout..."
osascript <<EOF || echo "  (Finder layout skipped - grant Automation access to set it)"
tell application "Finder"
    tell disk "${VOL_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 740, 540}
        
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 110
        
        -- Position items
        set position of item "${APP_NAME}.app" to {180, 180}
        set position of item "Applications" to {460, 180}
        
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Finalize DMG
echo "Compressing and finalizing DMG..."
chmod -Rf go-w "/Volumes/${VOL_NAME}"
sync
sleep 2
hdiutil detach "${DEVICE}"
hdiutil convert "${DMG_TMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_NAME}"

# Final cleanup
rm "${DMG_TMP}"
rm -rf build/dmg_content

echo "=================================================="
echo "✅ DMG CREATED: ${DMG_NAME}"
echo "=================================================="
echo ""
echo "Installation Instructions:"
echo "1. Double-click ${DMG_NAME} to mount"
echo "2. Drag notch-down.app to Applications folder"
echo "3. Launch from Applications or Spotlight"
echo "4. Grant automation permissions when prompted"
echo ""
echo "For help, see README.md or QUICK_START.md"
echo "=================================================="
