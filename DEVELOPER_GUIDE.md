# NotchDown Developer Guide

## Quick Reference for Understanding the Codebase

### Architecture Overview

NotchDown follows a clean MVVM architecture with specialized managers for different concerns.

```
┌─────────────────────────────────────────────────────────┐
│                    NotchDownApp.swift                    │
│              (Main App + TimerViewModel)                 │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ PowerManager │   │ ThemeManager │   │BatteryManager│
└──────────────┘   └──────────────┘   └──────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────────────────────────────────────────────┐
│              DynamicIslandView.swift                  │
│           (Main UI with all components)               │
└──────────────────────────────────────────────────────┘
```

### Key Files and Their Responsibilities

#### Core Application
- **NotchDownApp.swift**: Main app entry, TimerViewModel, business logic
- **ContentView.swift**: Unused placeholder (app uses MenuBarExtra)

#### Power Management
- **PowerManager.swift**: 
  - Executes power actions (shutdown, restart, sleep, logout)
  - Implements fallback mechanisms (AppleScript → IOKit → Shell)
  - Handles permissions and errors
  - Provides user confirmation dialogs

#### UI Components
- **DynamicIslandView.swift**: Main Dynamic Island interface
  - Collapsed/Expanded states
  - Timer selection UI
  - Active timer display
  - About page
  - Permission warnings

#### Window Management
- **NotchWindow.swift**: Custom NSPanel for floating window
  - Handles window positioning near notch
  - Morphing animations
  - Click-outside detection
  - Toast overlay integration

#### State Management
- **DynamicIslandModels.swift**: Enums and data models
  - IslandState (collapsed, expanded, critical, etc.)
  - AnimationPhase (idle, morphing, rolling, etc.)
  - UrgencyLevel (normal, warning, critical)
  - TimeOption (preset time selections)
  - AppTheme (dark, light)

#### Managers
- **BatteryManager.swift**: IOKit-based battery monitoring
- **ThemeManager.swift**: Theme persistence and switching
- **ShortcutManager.swift**: Global hotkey registration (Carbon API)
- **ErrorHandler.swift**: System sleep/wake handling, error management
- **DiagnosticsManager.swift**: System testing and verification
- **ToastManager.swift**: User feedback notifications

#### Animation System
- **SpringAnimator.swift**: Custom spring physics calculations
- **MorphingGeometry.swift**: Dynamic Island size calculations
- **AnimationFallbackManager.swift**: Performance-adaptive animations

#### UI Components
- **ModernButton.swift**: Reusable button component
- **CountdownDisplay.swift**: Timer display component
- **IslandBackground.swift**: Glassmorphism background

### Power Action Execution Flow

```
User triggers action
        │
        ▼
TimerViewModel.startTimer()
        │
        ▼
Timer counts down (tick())
        │
        ▼
Timer reaches 0
        │
        ▼
PowerManager.execute(action)
        │
        ├─→ Show confirmation dialog (if needed)
        │
        ├─→ Try AppleScript (primary)
        │   └─→ Success? ✓ Done
        │
        ├─→ Try IOKit (for sleep)
        │   └─→ Success? ✓ Done
        │
        └─→ Try Shell command (fallback)
            └─→ Success? ✓ Done
                └─→ Failure? Show error dialog
```

### Permission System

NotchDown requires automation permissions to control System Events:

1. **Info.plist Keys**:
   - `NSAppleEventsUsageDescription`: Explains why automation is needed
   - `NSSystemAdministrationUsageDescription`: For system-level operations

2. **Permission Verification**:
   - `PowerManager.verifyPermissions()`: Tests with harmless command
   - `TimerViewModel.verifyPermissions()`: Updates UI state
   - Permission warnings shown in Dynamic Island when needed

3. **User Flow**:
   - App detects missing permissions
   - Shows warning banner in UI
   - Provides "Open Settings" button
   - Links directly to Privacy & Security → Automation

### Toast Notification System

```swift
// Show success message
ToastManager.shared.success("Timer started")

// Show error message
ToastManager.shared.error("Permission denied")

// Show warning
ToastManager.shared.warning("Low battery")

// Show info
ToastManager.shared.info("Timer cancelled")
```

Toasts are automatically displayed in the NotchWindow overlay and auto-dismiss after their duration.

### Diagnostics System

The diagnostics system tests:
1. System information (macOS version, notch detection)
2. Automation permissions
3. Power management capabilities
4. AppleScript execution
5. IOKit access
6. Battery monitoring

Run diagnostics:
```swift
DiagnosticsManager.shared.runDiagnostics {
    let report = DiagnosticsManager.shared.generateReport()
    print(report)
}
```

### Common Development Tasks

#### Adding a New Power Action

1. Add case to `PowerAction` enum in PowerManager.swift:
```swift
enum PowerAction: CaseIterable {
    case shutdown, restart, logout, sleep, newAction
    
    var iconName: String {
        case .newAction: return "icon.name"
    }
}
```

2. Add AppleScript command in `executePrimaryMethod()`:
```swift
case .newAction:
    scriptSource = "tell application \"System Events\" to ..."
```

3. Add to UI in DynamicIslandView.swift PowerDropdown

#### Modifying Animation Timing

Edit SpringAnimator.swift:
```swift
static let morphDuration: TimeInterval = 0.5  // Morph animation
static let rollDuration: TimeInterval = 0.3   // Number roll
```

#### Changing Island Sizes

Edit MorphingGeometry.swift:
```swift
case .collapsed:
    return CGSize(width: 600, height: 40)  // Pill size
case .expanded:
    return CGSize(width: 600, height: 200) // Full size
```

#### Adding New Diagnostic Tests

Add to DiagnosticsManager.swift:
```swift
private func testNewFeature() {
    // Perform test
    let success = // test result
    
    addResult(
        category: "Category",
        test: "Test Name",
        status: success ? .passed : .failed,
        message: "Test result message"
    )
}
```

Then call in `runDiagnostics()`.

### Testing Power Actions

**IMPORTANT**: Test power actions carefully as they can shut down your Mac!

1. Use the diagnostics system first:
```swift
DiagnosticsManager.shared.runDiagnostics { }
```

2. Test permissions without executing:
```swift
PowerManager.shared.verifyPermissions { hasPermission in
    print("Has permission: \(hasPermission)")
}
```

3. For actual testing:
   - Save all work first
   - Test sleep first (least destructive)
   - Test logout second
   - Test restart/shutdown last

### Debugging Tips

1. **Timer not starting**: Check `TimerViewModel.startTimer()` and verify no other timer is active

2. **Power action fails**: 
   - Run diagnostics
   - Check Console.app for AppleScript errors
   - Verify permissions in System Settings

3. **UI not updating**:
   - Check `@Published` properties in ViewModels
   - Verify `@ObservedObject` in Views
   - Look for main thread issues

4. **Window positioning issues**:
   - Check `NotchWindow.swift` screen calculations
   - Verify safe area insets
   - Test on different displays

### Performance Considerations

1. **Animation Performance**: AnimationFallbackManager automatically reduces animation complexity on slower systems

2. **Timer Precision**: Uses 1-second intervals, acceptable for power management use case

3. **Battery Monitoring**: Polls battery status, not real-time (acceptable for this use case)

4. **Memory Management**: All managers use weak references to prevent retain cycles

### Security Considerations

1. **Confirmation Dialogs**: Destructive actions require user confirmation
2. **Permission Checks**: Verify permissions before attempting operations
3. **Error Handling**: Never silently fail on power operations
4. **Fallback Safety**: Each fallback method is tested before use

### Building for Distribution

1. Update version in Info.plist
2. Update version string in AboutView
3. Run diagnostics to verify all systems
4. Test on clean macOS installation
5. Notarize for distribution outside App Store

### Common Issues and Solutions

**Issue**: Sleep command doesn't work
**Solution**: Ensure using `System Events` not `Finder`, fallback to IOKit

**Issue**: Logout shows permission error
**Solution**: Check automation permissions for System Events

**Issue**: Timer state lost after sleep
**Solution**: ErrorHandler backs up and restores state automatically

**Issue**: Toast notifications not showing
**Solution**: Verify ToastContainerView is in NotchPanel overlay

**Issue**: Hardcoded paths in code
**Solution**: Use Bundle.main for resources, never absolute paths

### Code Style Guidelines

1. Use descriptive variable names
2. Add MARK comments for organization
3. Document complex logic with comments
4. Use SwiftUI best practices (prefer composition)
5. Handle errors gracefully with user feedback
6. Always provide fallback mechanisms
7. Test on multiple macOS versions

### Resources

- Apple Documentation: [NSAppleScript](https://developer.apple.com/documentation/foundation/nsapplescript)
- IOKit Power Management: [IOPMLib](https://developer.apple.com/documentation/iokit/iopowerlib)
- Carbon Event Manager: [Event Manager](https://developer.apple.com/documentation/carbon/event_manager)

---

**Last Updated**: v1.1.0  
**Maintainer**: festomanolo
