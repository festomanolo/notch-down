# Changelog

All notable changes to NotchDown will be documented in this file.

## [1.2.0] - 2026-10-21

### ✨ Improved
- Direction-aware island morph: grows out of the notch with a small overshoot, tucks back without one
- Content blur-fades between states and is clipped to the island while it morphs
- Live progress ring in the pill and a draining progress bar under the digits
- Breathing glow in the final minute, fast pulse and digit heartbeat in the final ten seconds
- Swipe the running pill to snooze or cancel: it follows the pointer, shows a hint and gives trackpad haptics; quick flicks count
- Click outside the island or press Esc to close it; focus returns to the previous app
- Pill leans in on hover; entrance sharpens out of a blur
- Check Updates queries GitHub releases and offers a download; About shows the real version
- Diagnostics shows its report with Copy and Save buttons
- Reduce Motion is followed live
- Battery monitoring is event-driven instead of polling every minute

### 🔧 Fixed
- Countdown digits changed irregularly (sometimes half a second late)
- Cancelling a timer from the open island made "Open Dynamic Island" stop working
- Long-press on the pill did nothing to the action that would run
- Low-battery suggestion reappeared on every battery update after being dismissed
- Countdown buttons hung below the island during the final minute
- Island stayed in the oversized alert layout after snoozing out of the final minute
- Toasts showed one update late, lingered after dismissal, and were invisible when raised from the menu
- Chosen theme was lost on relaunch; Match System could apply the previous appearance
- Light theme was greyed out on a dark Mac, with low-contrast chip labels
- Saved "Show Dock Icon" setting was not applied at launch
- About page profile photo never loaded; app icon used the 1024px image for every size
- Diagnostics ran AppleScript off the main thread

### 🧹 Removed
- Unused code: in-app test harnesses, ErrorHandler, IslandBackground, ContentView, legacy geometry/animation helpers and stale verification scripts

## [1.1.0] - 2026-02-13

### 🔧 Fixed
- **Critical**: Fixed sleep command - changed from `Finder` to `System Events`
- **Critical**: Fixed logout command - replaced malformed Apple Event with proper `System Events` command
- **Bug**: Fixed hardcoded image path in AboutView - now uses proper asset loading with fallback
- **Bug**: Fixed missing error feedback when power actions fail

### ✨ Added

#### Power Management Enhancements
- **Dual Execution Methods**: Primary AppleScript with automatic fallback to IOKit and shell commands
- **Confirmation Dialogs**: User confirmation required for destructive actions (shutdown, restart, logout)
- **Permission Verification**: Automatic permission checking on startup with guided setup
- **Error Recovery**: Comprehensive error handling with multiple fallback mechanisms
- **IOKit Sleep Fallback**: Direct IOKit integration for sleep when AppleScript fails

#### User Feedback System
- **Toast Notifications**: Real-time visual feedback for all operations
  - Success notifications (green) for completed actions
  - Error alerts (red) with detailed messages
  - Warning messages (orange) for important notices
  - Info messages (blue) for general feedback
- **Permission Warning Banner**: In-app banner when automation permissions are needed
- **Status Indicators**: Enhanced visual feedback in menu bar and Dynamic Island
- **Operation Feedback**: Toast notifications for timer start, cancel, snooze, and completion

#### Diagnostics & Testing
- **Comprehensive Diagnostics Tool**: Built-in system testing
  - System information verification (macOS version, notch detection)
  - Permission status checking
  - Power management capability testing
  - AppleScript execution validation
  - IOKit access verification
  - Battery monitoring status
- **Diagnostic Reports**: Export detailed reports for troubleshooting
- **Menu Bar Access**: Quick diagnostics from menu bar
- **About Page Integration**: Diagnostics button in About page

#### Developer Features
- **DiagnosticsManager**: New manager for system testing and verification
- **ToastManager**: Centralized notification system with auto-dismiss
- **Enhanced PowerManager**: 
  - Result-based completion handlers
  - Multiple execution strategies
  - Permission verification methods
  - Test mode for debugging
- **Error Types**: Structured error handling with specific error cases

### 🎨 Improved
- **Info.plist**: Enhanced permission descriptions for better user understanding
- **Error Messages**: More descriptive and actionable error messages
- **User Guidance**: Direct links to System Settings for permission management
- **Asset Loading**: Proper resource loading with graceful fallbacks
- **Code Organization**: Better separation of concerns with new managers

### 📚 Documentation
- **README.md**: Comprehensive update with:
  - New features documentation
  - Detailed setup instructions
  - Troubleshooting guide
  - Usage examples
  - Version history
- **DEVELOPER_GUIDE.md**: New developer documentation with:
  - Architecture overview
  - Code flow diagrams
  - Common development tasks
  - Testing guidelines
  - Debugging tips
- **CHANGELOG.md**: This file for tracking changes

### 🔒 Security
- **Confirmation Dialogs**: Prevent accidental destructive actions
- **Permission Validation**: Verify permissions before attempting operations
- **Concurrent Operation Prevention**: Block multiple simultaneous power operations
- **Safe Fallbacks**: Each fallback method is validated before use

### 🏗️ Technical
- **New Files**:
  - `DiagnosticsManager.swift`: System diagnostics and testing
  - `ToastManager.swift`: User feedback notification system
  - `DEVELOPER_GUIDE.md`: Developer documentation
  - `CHANGELOG.md`: Version history
- **Modified Files**:
  - `PowerManager.swift`: Complete rewrite with fallback mechanisms
  - `NotchDownApp.swift`: Added permission management and toast integration
  - `DynamicIslandView.swift`: Added permission warning banner and diagnostics
  - `NotchWindow.swift`: Integrated toast overlay
  - `Info.plist`: Enhanced permission descriptions
  - `README.md`: Comprehensive documentation update

### 🐛 Known Issues
- None currently identified

### 🔄 Migration Notes
- No breaking changes for existing users
- Permissions may need to be re-granted after update
- Run diagnostics after first launch to verify setup

---

## [1.0.0] - 2026-01-22

### Initial Release
- Dynamic Island interface for macOS
- Timer-based power management (shutdown, restart, sleep, logout)
- Battery-aware intelligence
- Smart visibility with auto-hide/peek
- Global hotkey support (Shift + Control + U)
- Glassmorphism design with urgency levels
- Theme support (dark/light)
- Gesture controls (swipe, long press)
- Custom spring physics animations
- Menu bar integration
- About page with system settings

---

## Version Format

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality in a backwards compatible manner
- **PATCH**: Backwards compatible bug fixes

## Categories

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements
