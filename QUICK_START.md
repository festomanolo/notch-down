# NotchDown Quick Start Guide

Get up and running with NotchDown in 5 minutes!

---

## Installation

1. **Build the App**:
   - Open `notch-down.xcodeproj` in Xcode
   - Press ⌘R to build and run
   - The app will appear in your menu bar

2. **Grant Permissions** (First Launch):
   - macOS will ask for automation permissions
   - Click "OK" or "Open System Settings"
   - In System Settings → Privacy & Security → Automation
   - Enable NotchDown for "System Events"
   - Restart NotchDown

3. **Verify Setup**:
   - Click NotchDown menu bar icon
   - Select "Run Diagnostics"
   - All tests should pass ✓

---

## Basic Usage

### Start a Quick Timer

**Method 1: Menu Bar**
1. Click NotchDown icon in menu bar
2. Select a preset: "Shutdown in 5 min", "Sleep in 5 min", etc.
3. Timer starts immediately

**Method 2: Dynamic Island**
1. Press `Shift + Control + U` (or click menu bar icon → "Open Dynamic Island")
2. Click a preset button: 5m, 10m, 30m, or 1h
3. Click "Start Timer"
4. Confirm the action when prompted

**Method 3: Custom Time**
1. Open Dynamic Island (`Shift + Control + U`)
2. Click "Custom" button
3. Set hours, minutes, and seconds
4. Choose action (Shutdown, Restart, Sleep, Log Out)
5. Click "Start Timer"

### Manage Active Timer

**View Timer**:
- Collapsed pill shape shows countdown
- Hover to see details
- Click to expand for full view

**Snooze Timer** (+5 minutes):
- Swipe RIGHT on collapsed island
- Or expand and adjust time

**Cancel Timer**:
- Swipe LEFT on collapsed island
- Or expand and click "Cancel Timer"

**Toggle Action** (Shutdown ↔ Sleep):
- Long press on collapsed island

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Shift + Control + U` | Toggle Dynamic Island |

---

## Power Actions Explained

### Sleep
- **What it does**: Puts your Mac to sleep immediately
- **Confirmation**: No (for quick access)
- **Use when**: Taking a break, saving battery
- **Wakes with**: Keyboard, mouse, or lid open

### Shutdown
- **What it does**: Completely powers off your Mac
- **Confirmation**: Yes
- **Use when**: Done for the day, traveling
- **Requires**: Power button to restart

### Restart
- **What it does**: Shuts down and automatically restarts
- **Confirmation**: Yes
- **Use when**: Installing updates, troubleshooting
- **Automatic**: Mac restarts on its own

### Log Out
- **What it does**: Logs out current user, returns to login screen
- **Confirmation**: Yes
- **Use when**: Switching users, securing your session
- **Preserves**: System stays on, other users unaffected

---

## Tips & Tricks

### Smart Features

**Battery Intelligence**:
- When battery drops below 20% (and unplugged)
- NotchDown suggests scheduling a shutdown
- Accept or dismiss the suggestion

**Smart Peeks**:
- Timer auto-hides to reduce clutter
- Peeks back at strategic intervals
- More frequent as deadline approaches

**Urgency Levels**:
- **Normal** (blue): More than 1 minute remaining
- **Warning** (orange): Less than 1 minute remaining
- **Critical** (red): Less than 10 seconds remaining

### Gestures

**On Collapsed Island**:
- **Swipe Right**: Add 5 minutes
- **Swipe Left**: Cancel timer
- **Long Press**: Toggle Shutdown ↔ Sleep
- **Click**: Expand to full view

**On Expanded Island**:
- **Click Outside**: Collapse to pill shape
- **Click Minimize**: Collapse to pill shape

### Menu Bar

**Icon Indicators**:
- **Power icon**: No timer active
- **Timer icon**: Timer running (normal)
- **Warning icon**: Timer in warning state
- **Critical icon**: Timer in critical state
- **Colored dot**: Urgency indicator

**Optional Countdown**:
- Enable "Show Countdown in Menu Bar" in About page
- Shows time remaining next to icon

---

## Settings & Preferences

### Access Settings
1. Open Dynamic Island (`Shift + Control + U`)
2. Click the "!" button (About)
3. Configure preferences

### Available Settings

**Show Countdown in Menu Bar**:
- Display timer countdown next to menu bar icon
- Useful for always seeing time remaining

**Start at Login**:
- Launch NotchDown automatically when you log in
- Recommended for regular use

**Show Dock Icon**:
- Display NotchDown in the Dock
- Default: Off (menu bar only)

**Theme**:
- Dark or Light mode
- Matches your preference

---

## Troubleshooting

### Timer Won't Start
1. Check for permission warning banner
2. Click "Open Settings" if shown
3. Grant automation permissions
4. Restart NotchDown

### Sleep/Logout Not Working
1. Run diagnostics: Menu Bar → "Run Diagnostics"
2. Check "Automation Access" test
3. If failed, grant permissions in System Settings
4. Verify "System Events" is enabled

### Permission Issues
1. System Settings → Privacy & Security → Automation
2. Find NotchDown in the list
3. Enable "System Events"
4. Restart the app

### Still Having Issues?
- See TROUBLESHOOTING.md for detailed solutions
- Run diagnostics for automatic problem detection
- Check Console.app for error messages

---

## Advanced Features

### Diagnostics
**Run Tests**:
- Menu Bar → "Run Diagnostics"
- Or About page → "Diagnostics" button

**What It Tests**:
- System information
- Permissions
- Power management
- AppleScript execution
- IOKit access
- Battery monitoring

**Export Report**:
- Results shown in alert
- Full report in Console.app
- Copy for troubleshooting

### Verify Permissions
- Menu Bar → "Verify Permissions"
- Tests automation access
- Updates permission status
- Shows result in alert

---

## Best Practices

### Before Scheduling Shutdown/Restart/Logout
1. ✅ Save all your work
2. ✅ Close important applications
3. ✅ Verify the timer duration
4. ✅ Confirm the action type

### For Reliable Operation
1. ✅ Keep automation permissions granted
2. ✅ Run diagnostics after updates
3. ✅ Test with Sleep first (least destructive)
4. ✅ Don't force quit the app

### For Best Experience
1. ✅ Enable "Start at Login"
2. ✅ Learn the gestures (swipe, long press)
3. ✅ Use keyboard shortcut for quick access
4. ✅ Enable menu bar countdown if desired

---

## Common Workflows

### "I'm leaving in 10 minutes"
1. Press `Shift + Control + U`
2. Click "10m" preset
3. Click "Start Timer"
4. Confirm shutdown
5. Save your work and leave

### "Put Mac to sleep when this downloads"
1. Start your download
2. Open NotchDown
3. Estimate time needed
4. Set custom timer
5. Select "Sleep" action
6. Start timer

### "Restart after this render"
1. Start your render
2. Set timer for estimated completion
3. Select "Restart" action
4. Mac will restart when done

### "Low battery, need to shutdown soon"
1. NotchDown detects low battery
2. Shows suggestion automatically
3. Click "Shutdown in 5m"
4. Or dismiss and set custom time

---

## Keyboard Shortcuts Reference

| Action | Shortcut |
|--------|----------|
| Toggle Dynamic Island | `Shift + Control + U` |
| Quit NotchDown | Menu Bar → Quit |

*More shortcuts coming in future versions!*

---

## Getting Help

### Documentation
- **README.md**: Full feature documentation
- **TROUBLESHOOTING.md**: Detailed problem solving
- **DEVELOPER_GUIDE.md**: Technical documentation

### Self-Help Tools
- Run Diagnostics (built-in)
- Verify Permissions (menu bar)
- Check Console.app logs

### Before Asking for Help
1. Run diagnostics
2. Check troubleshooting guide
3. Verify permissions granted
4. Try restarting the app
5. Check macOS version (14.0+ required)

---

## What's Next?

Now that you're set up:
1. ✅ Try each power action (start with Sleep)
2. ✅ Learn the gestures
3. ✅ Customize your preferences
4. ✅ Set up "Start at Login"
5. ✅ Explore the Dynamic Island interface

**Enjoy NotchDown!** 🚀

---

**Version**: 1.1.0  
**Last Updated**: February 13, 2026  
**Need Help?** See TROUBLESHOOTING.md
