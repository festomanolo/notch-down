#!/bin/bash

# Configuration
APP_NAME="notch-down"
APP_BUNDLE="build/Release/${APP_NAME}.app"
# Final name including professional branding
DMG_NAME="NotchDown_Professional_Installer.dmg"
DMG_TMP="temp_pro.dmg"
VOL_NAME="NotchDown Installer"
BG_IMAGE="/Users/festomanolo/.gemini/antigravity/brain/4f86be94-eb81-4f23-9799-f481480aa5ef/dmg_background_resized.png"
LICENSE_FILE="License.txt"

# Cleanup
echo "Cleaning up old build artifacts..."
hdiutil detach /Volumes/"${VOL_NAME}" 2>/dev/null || true
rm -f "${DMG_NAME}" "${DMG_TMP}"
rm -rf build/dmg_content

# Preparation
mkdir -p build/dmg_content
echo "Preparing contents (App, License, Symlinks)..."
cp -R "${APP_BUNDLE}" build/dmg_content/
cp "${LICENSE_FILE}" build/dmg_content/
ln -s /Applications build/dmg_content/Applications

# Create temp DMG (Make it slightly larger for padding)
echo "Creating temporary writable disk image..."
hdiutil create -size 200m -fs HFS+ -volname "${VOL_NAME}" "${DMG_TMP}"

# Mount DMG with explicit readwrite and noautoopen
echo "Mounting temporary image (Read-Write)..."
ATTACH_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TMP}")
DEVICE=$(echo "$ATTACH_OUTPUT" | egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 5

# Copy contents to mounted DMG
echo "Copying files to volume..."
cp -R build/dmg_content/* "/Volumes/${VOL_NAME}/"
sync

# Add background image
echo "Applying Retina decoration..."
mkdir "/Volumes/${VOL_NAME}/.background"
cp "${BG_IMAGE}" "/Volumes/${VOL_NAME}/.background/background.png"

# Setup window via AppleScript
echo "Automating Finder layout (Godmode coordinates)..."
osascript <<EOF
tell application "Finder"
    tell disk "${VOL_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        -- Premium Retina scale adjustment
        set the bounds of container window to {100, 100, 740, 540} -- 640x440
        
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 110
        set background picture of theViewOptions to file ".background:background.png"
        
        -- Center the icons on the "Smooth Drift" path (Godmode coordinates)
        set position of item "${APP_NAME}.app" to {180, 220}
        set position of item "Applications" to {460, 220}
        set position of item "License.txt" to {320, 360}
        
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Finalize DMG
echo "Compressing and finalizing as high-fidelity UDZO..."
chmod -Rf go-w "/Volumes/${VOL_NAME}"
sync
hdiutil detach "${DEVICE}"
hdiutil convert "${DMG_TMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_NAME}"

# Final cleanup
rm "${DMG_TMP}"
rm -rf build/dmg_content

echo "=================================================="
echo "GODMODE DMG COMPLETED: ${DMG_NAME}"
echo "=================================================="
