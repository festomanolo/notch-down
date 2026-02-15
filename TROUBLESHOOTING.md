# NotchDown Troubleshooting Guide

## Quick Diagnostics

Before troubleshooting specific issues, run the built-in diagnostics:

1. Click the NotchDown menu bar icon
2. Select "Run Diagnostics"
3. Review the results in the alert or console

This will identify most common issues automatically.

---

## Common Issues

### Sleep Command Not Working

**Symptoms**: Timer completes but Mac doesn't sleep

**Causes**:
- Missing automation permissions
- System Events not accessible
- IOKit fallback failed

**Solutions**:
1. **Check Permissions**:
   - Open System Settings → Privacy & Security → Automation
   - Ensure NotchDown has permission for "System Events"
   - If not listed, click the "+" button and add NotchDown

2. **Verify with Diagnostics**:
   ```
   Menu Bar → Run Diagnostics
   Look for "Automation Access" test result
   ```

3. **Test Manually**:
   - Open Script Editor
   - Run: `tell application "System Events" to sleep`
   - If this fails, it's a system-wide permission issue

4. **Try IOKit Fallback**:
   - The app automatically tries IOKit if AppleScript fails
   - Check Console.app for error messages
   - Look for "IOKit power management port accessible" in diagnostics

**Still Not Working?**
- Restart your Mac
- Reinstall NotchDown
- Check for macOS updates

---

### Logout Command Not Working

**Symptoms**: Timer completes but logout doesn't occur

**Causes**:
- Missing automation permissions
- Unsaved work blocking logout
- System Events not accessible

**Solutions**:
1. **Check Permissions** (same as Sleep above)

2. **Save All Work**:
   - Logout requires all apps to quit
   - Save work in all applications first
   - Close apps that might block logout

3. **Test Manually**:
   ```applescript
   tell application "System Events" to log out
   ```

4. **Check for Blocking Apps**:
   - Some apps prevent logout (e.g., apps with unsaved changes)
   - Close all apps before testing

---

### Timer Not Starting

**Symptoms**: Click "Start Timer" but nothing happens

**Causes**:
- Another timer already active
- Permission warning blocking start
- Invalid time selection

**Solutions**:
1. **Cancel Existing Timer**:
   - Check if a timer is already running
   - Swipe left on collapsed island to cancel
   - Or click "Cancel Timer" in expanded view

2. **Check Permission Warning**:
   - Look for orange warning banner in Dynamic Island
   - Click "Open Settings" to grant permissions
   - Restart app after granting permissions

3. **Verify Time Selection**:
   - Ensure you've selected a time (preset or custom)
   - Custom time must be greater than 0
   - Check that hours, minutes, or seconds are set

4. **Check Console**:
   - Open Console.app
   - Filter for "NotchDown"
   - Look for error messages

---

### Permission Warnings Keep Appearing

**Symptoms**: Orange permission banner shows even after granting permissions

**Causes**:
- Permissions not properly granted
- App needs restart
- System Settings cache issue

**Solutions**:
1. **Verify Permissions**:
   - System Settings → Privacy & Security → Automation
   - NotchDown should be listed
   - "System Events" should be checked

2. **Restart App**:
   - Quit NotchDown completely (Menu Bar → Quit)
   - Relaunch the app
   - Permissions should be detected

3. **Reset Permissions**:
   - Remove NotchDown from Automation list
   - Restart NotchDown
   - Grant permissions when prompted

4. **Dismiss Warning**:
   - Click the X button on the warning banner
   - Run "Verify Permissions" from menu bar
   - If test passes, warning won't return

---

### Dynamic Island Not Appearing

**Symptoms**: Press Shift+Ctrl+U but nothing shows

**Causes**:
- Hotkey conflict with another app
- Window hidden off-screen
- App not running

**Solutions**:
1. **Check App Status**:
   - Look for NotchDown icon in menu bar
   - If not present, app isn't running
   - Launch NotchDown

2. **Try Menu Bar**:
   - Click NotchDown menu bar icon
   - Select "Open Dynamic Island"
   - If this works, hotkey has a conflict

3. **Check for Conflicts**:
   - Other apps may use Shift+Ctrl+U
   - Disable other apps temporarily to test
   - Future version may allow custom hotkeys

4. **Reset Window Position**:
   - Quit NotchDown
   - Delete preferences: `~/Library/Preferences/manolo.notch-down.plist`
   - Relaunch app

---

### Toast Notifications Not Showing

**Symptoms**: Actions complete but no feedback messages appear

**Causes**:
- Window not visible
- Toast overlay issue
- Notification dismissed too quickly

**Solutions**:
1. **Expand Dynamic Island**:
   - Toasts show in the window overlay
   - Expand island to see toasts
   - Press Shift+Ctrl+U

2. **Check Duration**:
   - Success toasts: 3 seconds
   - Error toasts: 5 seconds
   - May have missed them

3. **Test Toast System**:
   - Start a timer (should show "Timer started")
   - Cancel timer (should show "Timer cancelled")
   - If neither shows, toast system has an issue

---

### Diagnostics Fail

**Symptoms**: Diagnostic tests show failures

**Solutions by Test**:

**"Automation Access" Failed**:
- Grant permissions in System Settings
- See "Permission Warnings" section above

**"AppleScript Execution" Failed**:
- System Events may be disabled
- Check System Settings → Privacy & Security
- Restart Mac if needed

**"IOKit Power Access" Warning**:
- Not critical, fallback will work
- Some Macs don't expose IOKit power port
- Sleep will use AppleScript instead

**"Power Management Port" Warning**:
- Normal on some Mac models
- Fallback mechanisms will handle this
- No action needed

---

### Battery Intelligence Not Working

**Symptoms**: No low battery suggestions appear

**Causes**:
- Battery monitoring disabled
- Not on battery power
- Battery above 20%

**Solutions**:
1. **Check Battery Status**:
   - Run diagnostics
   - Look for "Battery Monitoring" test
   - Should show current battery level

2. **Test Conditions**:
   - Unplug Mac from power
   - Wait for battery to drop below 20%
   - Suggestion should appear automatically

3. **Dismiss Old Suggestions**:
   - If suggestion is stuck, click "Dismiss"
   - New suggestions will appear when conditions met

---

### App Crashes or Freezes

**Symptoms**: App becomes unresponsive or crashes

**Solutions**:
1. **Check Console Logs**:
   - Open Console.app
   - Filter for "NotchDown"
   - Look for crash reports or errors

2. **Reset Preferences**:
   ```bash
   rm ~/Library/Preferences/manolo.notch-down.plist
   ```

3. **Clean Reinstall**:
   - Quit NotchDown
   - Delete app from Applications
   - Delete preferences (above)
   - Rebuild from Xcode

4. **Check macOS Version**:
   - Requires macOS 14.0+
   - Update macOS if needed

---

### Timer State Lost After Sleep

**Symptoms**: Mac sleeps and timer resets

**Causes**:
- System sleep interrupted timer
- State restoration failed

**Solutions**:
1. **Normal Behavior**:
   - App attempts to restore timer state
   - If Mac slept longer than timer, it's cancelled
   - This is expected behavior

2. **Check Error Handler**:
   - ErrorHandler backs up state before sleep
   - Restores on wake if time remaining
   - Check console for restoration messages

3. **Avoid System Sleep**:
   - Don't manually sleep Mac while timer active
   - Let timer complete its action
   - Or cancel timer before sleeping

---

## Advanced Troubleshooting

### Enable Debug Logging

Add to NotchDownApp.swift init():
```swift
UserDefaults.standard.set(true, forKey: "DebugLogging")
```

### Export Diagnostic Report

1. Open About page in Dynamic Island
2. Click "Diagnostics" button
3. Wait for tests to complete
4. Check console for full report
5. Copy report for support

### Check System Logs

```bash
# View NotchDown logs
log show --predicate 'process == "notch-down"' --last 1h

# View System Events logs
log show --predicate 'process == "System Events"' --last 1h
```

### Test AppleScript Manually

Open Script Editor and test commands:

```applescript
-- Test System Events access
tell application "System Events" to get name

-- Test sleep
tell application "System Events" to sleep

-- Test logout
tell application "System Events" to log out

-- Test shutdown
tell application "System Events" to shut down

-- Test restart
tell application "System Events" to restart
```

### Reset All Permissions

```bash
# Reset TCC database (requires restart)
tccutil reset AppleEvents
```

Then relaunch NotchDown and grant permissions again.

---

## Getting Help

If none of these solutions work:

1. **Export Diagnostics**:
   - Run full diagnostics
   - Export report from About page
   - Include in support request

2. **Check Console**:
   - Open Console.app
   - Filter for "NotchDown"
   - Copy relevant error messages

3. **System Information**:
   - macOS version
   - Mac model
   - Notch present or not
   - Other power management apps installed

4. **Steps to Reproduce**:
   - What you were trying to do
   - What happened instead
   - Any error messages shown

---

## Prevention Tips

1. **Keep Permissions Granted**: Don't revoke automation permissions
2. **Save Work Before Timers**: Always save before scheduling shutdown/logout
3. **Test with Sleep First**: Sleep is least destructive for testing
4. **Run Diagnostics Regularly**: Catch issues early
5. **Keep macOS Updated**: Ensures compatibility
6. **Don't Force Quit**: Use proper quit from menu bar

---

**Last Updated**: v1.1.0  
**Need More Help?** Check DEVELOPER_GUIDE.md for technical details
