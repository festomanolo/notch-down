# NotchDown: The Dynamic Island for macOS

**NotchDown** is a premium, high-fidelity macOS power management utility that breathes life into your MacBook's notch. It transforms the screen's static area into an intelligent, interactive "Dynamic Island" that helps you manage system intent—Shutdown, Sleep, and Restart—with fluid animations and proactive intelligence.

---

## Features

### Core Functionality
- **Liquid UI Performance**: Physics-based morphing animations using custom spring solver for a tactile, "living" interface feel.
- **Power Management**: Schedule shutdown, restart, sleep, and logout operations with visual countdown timers.
- **Micro-Action Gestures**: 
  - **Swipe Right**: Snooze your timer by +5 minutes.
  - **Swipe Left**: Instantly cancel the active process.
  - **Long Press**: Toggle between Power and Sleep modes without expanding.
- **Battery-Aware Intelligence**: Proactively suggests power-saving actions when your system is on battery and below 20%.
- **Intelligent Visibility**: Features "Smart Peeks"—the island auto-hides to reduce clutter and peeks back at strategic intervals to keep you informed.
- **Global Hotkey**: Instant access from any app via `Shift + Control + U`.
- **Glassmorphism Aesthetic**: Ultra-thin material design with dynamic urgency glows (Normal/Warning/Critical).

### New Enhanced Features (v1.1)

#### Robust Power Management
- **Fixed Sleep & Logout**: Corrected AppleScript commands for reliable sleep and logout operations
- **Dual Execution Methods**: Primary AppleScript with IOKit fallback for maximum reliability
- **Confirmation Dialogs**: User confirmation for destructive actions (shutdown, restart, logout)
- **Error Handling**: Comprehensive error detection with user-friendly feedback
- **Permission Verification**: Automatic permission checking with guided setup

#### User Feedback System
- **Toast Notifications**: Real-time visual feedback for all operations
  - Success notifications for completed actions
  - Error alerts with detailed messages
  - Info messages for timer events
- **Permission Warnings**: In-app banner alerts when permissions are needed
- **Status Indicators**: Visual feedback in menu bar and Dynamic Island

#### Diagnostics & Testing
- **Comprehensive Diagnostics**: Built-in system testing tool
  - System information verification
  - Permission status checking
  - Power management capability testing
  - AppleScript execution validation
  - IOKit access verification
  - Battery monitoring status
- **Diagnostic Reports**: Export detailed diagnostic reports for troubleshooting
- **Quick Access**: Run diagnostics from menu bar or About page

#### Enhanced Reliability
- **Fallback Mechanisms**: Multiple execution paths ensure operations complete
  - AppleScript (primary)
  - IOKit for sleep operations
  - Shell commands as last resort
- **State Preservation**: Timer state maintained through system sleep/wake cycles
- **Concurrent Operation Prevention**: Blocks multiple simultaneous power operations
- **Asset Loading**: Proper resource loading with fallback icons

---

## Technical Innovation

NotchDown isn't just a timer; it's an engineering exploration of how to bridge the gap between utility and delight on macOS.

- **Carbon Hotkey Engine**: Zero-latency system-wide shortcut handling without requiring accessibility permissions.
- **IOKit Power Monitoring**: Direct system-level integration for energy state awareness.
- **Modular SwiftUI Architecture**: Clean, production-ready codebase separated into ViewModels, Managers, and Custom Animators.
- **Multi-Layer Error Handling**: Graceful degradation with user feedback at every step.
- **Toast Notification System**: Non-intrusive feedback overlay for all user actions.

---

## 🛠️ Installation & Setup

### Requirements
- macOS 14.0 or newer
- Optimized for Apple Silicon MacBooks with a notch
- Automation permissions for System Events

### Build Instructions
1. Open `notch-down.xcodeproj` in Xcode
2. Select the `notch-down` scheme
3. Build & Run (⌘R)

### First Launch Setup
1. **Grant Permissions**: On first launch, macOS will request automation permissions
   - Click "Open System Settings" when prompted
   - Enable NotchDown in Privacy & Security → Automation
   - Allow access to "System Events"

2. **Verify Setup**: 
   - Open NotchDown menu from menu bar
   - Click "Run Diagnostics" to verify all systems are working
   - Check for any permission warnings

3. **Configure Preferences**:
   - Access About page via Dynamic Island or menu bar
   - Enable "Start at Login" for automatic startup
   - Toggle "Show Countdown in Menu Bar" for persistent timer display
   - Choose your preferred theme (Dark/Light)

### Keyboard Shortcut
Use `Shift + Control + U` to toggle the Dynamic Island at any time.

---

## Usage Guide

### Starting a Timer
1. **Quick Start**: Click menu bar icon → Select preset time (5m, 10m, 30m, 1h)
2. **Custom Timer**: Open Dynamic Island → Click "Custom" → Set hours, minutes, seconds
3. **Choose Action**: Select Shutdown, Restart, Sleep, or Log Out
4. **Confirm**: Click "Start Timer"

### Managing Active Timers
- **Snooze**: Swipe right on collapsed island (+5 minutes)
- **Cancel**: Swipe left on collapsed island or click "Cancel Timer"
- **Monitor**: Timer displays in collapsed pill shape with countdown
- **Urgency Alerts**: 
  - Warning glow at T-minus 1 minute
  - Critical expansion at T-minus 10 seconds
  - Audio alerts at key intervals

### Troubleshooting
1. **Sleep/Logout Not Working**:
   - Run diagnostics from menu bar
   - Check automation permissions in System Settings
   - Verify "System Events" has automation access

2. **Timer Not Starting**:
   - Ensure no other timer is active
   - Check for permission warnings in Dynamic Island
   - Review diagnostic report for issues

3. **Permissions Issues**:
   - Open System Settings → Privacy & Security → Automation
   - Enable NotchDown for System Events
   - Restart the app after granting permissions

---

## Architecture

### Core Components
- **NotchDownApp.swift**: Main app entry point and TimerViewModel
- **PowerManager.swift**: Power operation execution with fallback mechanisms
- **DynamicIslandView.swift**: Main UI with glassmorphism design
- **DiagnosticsManager.swift**: System testing and verification
- **ToastManager.swift**: User feedback notification system
- **ErrorHandler.swift**: Comprehensive error management
- **BatteryManager.swift**: Battery monitoring and intelligence
- **ThemeManager.swift**: Theme switching and persistence

### Key Managers
- **ShortcutManager**: Global hotkey registration (Carbon API)
- **SpringAnimator**: Custom physics-based animations
- **MorphingGeometry**: Dynamic Island size calculations
- **AnimationFallbackManager**: Performance-adaptive animations

---

## Aesthetics: Nolo UI

Every interaction in NotchDown is designed to feel premium. We use:
- **Custom Spring Physics**: To ensure every expansion and collapse feels organic.
- **OLED-Black Foundation**: Optimized for MacBook displays.
- **Haptic-Visual Feedback**: Symbolic bounces and glows that respond to your intent.
- **Toast Notifications**: Subtle, non-intrusive feedback for all operations.
- **Permission Awareness**: Proactive guidance when system access is needed.

---

## Version History

### v1.1 (Current)
- Fixed sleep and logout commands
- Added comprehensive error handling
- Implemented toast notification system
- Added diagnostics and testing tools
- Enhanced permission management
- Added fallback execution methods
- Improved user feedback throughout
- Fixed asset loading issues

### v1.0
- Initial release
- Dynamic Island interface
- Basic power management
- Timer functionality
- Battery awareness
- Theme support

---

## Known Limitations

- Requires macOS 14.0+ for full feature support
- Automation permissions must be granted manually
- Some power operations may require admin privileges
- Sleep via IOKit may not work on all Mac models

---

## Contributing

NotchDown is a showcase project demonstrating modern macOS development practices. Feel free to explore the codebase and learn from the implementation patterns.

---

## License

See License.txt for details.

---

## Credits

**Created by festomanolo**  
Lead Designer & Engineer

NotchDown v1.1.0 - The Dynamic Island for macOS
