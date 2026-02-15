# NotchDown v1.1.0 - Installation Guide

## What's Fixed in v1.1.0

✅ **Sleep command now works** - Fixed incorrect AppleScript  
✅ **Logout command now works** - Replaced malformed Apple Event  
✅ **No more crashes** - Fixed layout constraint issues  
✅ **Proper rendering** - Dynamic Island displays correctly  
✅ **Comprehensive error handling** - User feedback for all operations  
✅ **Fallback mechanisms** - Multiple execution strategies  
✅ **Permission management** - Automatic verification and guidance  
✅ **Toast notifications** - Real-time operation feedback  
✅ **Diagnostics system** - Built-in testing and verification  

---

## Installation from DMG

### Step 1: Download and Mount
1. Locate `NotchDown_v1.1.0_Installer.dmg`
2. Double-click to mount the disk image
3. A Finder window will open showing the installer

### Step 2: Install
1. Drag `notch-down.app` to the `Applications` folder shortcut
2. Wait for the copy to complete
3. Eject the DMG by clicking the eject button in Finder

### Step 3: First Launch
1. Open Applications folder
2. Find and double-click `notch-down`
3. If you see "cannot be opened because it is from an unidentified developer":
   - Right-click (or Control-click) on `notch-down.app`
   - Select "Open" from the menu
   - Click "Open" in the dialog
   - This only needs to be done once

### Step 4: Grant Permissions
1. macOS will request automation permissions
2. Click "Open System Settings" (or "OK")
3. In System Settings → Privacy & Security → Automation:
   - Find "notch-down" in the list
   - Enable the checkbox for "System Events"
4. Restart NotchDown after granting permissions

### Step 5: Verify Installation
1. Look for the NotchDown icon in your menu bar (top-right)
2. Click the icon and select "Run Diagnostics"
3. All tests should pass ✓
4. If any fail, see TROUBLESHOOTING.md

---

## Quick Start

### Open Dynamic Island
Press `Shift + Control + U` or click the menu bar icon

### Start a Timer
1. Open Dynamic Island
2. Click a preset (5m, 10m, 30m, 1h) or "Custom"
3. Click "Start Timer"
4. Confirm the action

### Manage Timer
- **Snooze**: Swipe right on collapsed island (+5 min)
- **Cancel**: Swipe left on collapsed island
- **Expand**: Click on collapsed island

---

## System Requirements

- macOS 14.0 or newer
- Apple Silicon or Intel Mac
- ~50MB disk space
- Automation permissions for System Events

---

## Uninstallation

To remove NotchDown:

1. Quit the app (Menu Bar → Quit NotchDown)
2. Delete from Applications:
   ```bash
   rm -rf /Applications/notch-down.app
   ```
3. Remove preferences (optional):
   ```bash
   rm ~/Library/Preferences/manolo.notch-down.plist
   ```
4. Remove automation permissions (optional):
   - System Settings → Privacy & Security → Automation
   - Remove NotchDown from the list

---

## Troubleshooting

### App Won't Open
- Right-click → Open (for first launch)
- Check macOS version (requires 14.0+)
- See TROUBLESHOOTING.md for details

### Sleep/Logout Not Working
1. Run diagnostics from menu bar
2. Check automation permissions
3. Verify "System Events" is enabled
4. Restart the app

### Timer Won't Start
- Check for permission warning banner
- Grant automation permissions
- Restart NotchDown

### Dynamic Island Not Showing
- Press `Shift + Control + U`
- Or click menu bar icon → "Open Dynamic Island"
- Check that app is running (icon in menu bar)

---

## Getting Help

### Documentation
- **README.md**: Full feature documentation
- **QUICK_START.md**: 5-minute getting started guide
- **TROUBLESHOOTING.md**: Detailed problem solving
- **DEVELOPER_GUIDE.md**: Technical documentation

### Built-in Tools
- Run Diagnostics (menu bar)
- Verify Permissions (menu bar)
- Check About page for version info

### Common Issues
See TROUBLESHOOTING.md for solutions to:
- Permission problems
- Sleep/logout failures
- Timer issues
- Window rendering problems
- Crash recovery

---

## What's New in v1.1.0

### Critical Fixes
- Fixed sleep command (now uses System Events)
- Fixed logout command (proper AppleScript)
- Fixed layout crashes (removed constraint loops)
- Fixed window sizing (proper rendering)

### New Features
- Comprehensive error handling
- Toast notification system
- Diagnostics and testing tools
- Permission management
- Fallback execution mechanisms
- User confirmation dialogs
- Enhanced documentation

### Improvements
- Better permission descriptions
- Improved user feedback
- More reliable power operations
- Enhanced window layout
- Proper asset loading

---

## Support

For issues not covered in the documentation:

1. Run diagnostics and note results
2. Check Console.app for error messages
3. Review TROUBLESHOOTING.md
4. Check system requirements

---

## Version Information

- **Version**: 1.1.0
- **Release Date**: February 13, 2026
- **Build**: Release
- **Minimum macOS**: 14.0
- **Architecture**: Universal (Apple Silicon + Intel)

---

## License

See License.txt for details.

---

**Enjoy NotchDown!** 🚀

For the best experience:
1. Enable "Start at Login" in About page
2. Learn the gestures (swipe, long press)
3. Use keyboard shortcut for quick access
4. Run diagnostics after macOS updates
