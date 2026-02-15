# Changelog

All notable changes to NotchDown will be documented in this file.

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
