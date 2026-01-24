# NotchDown: The Dynamic Island for macOS 🏝️

**NotchDown** is a premium, high-fidelity macOS power management utility that breathes life into your MacBook's notch. It transforms the screen's static area into an intelligent, interactive "Dynamic Island" that helps you manage system intent—Shutdown, Sleep, and Restart—with fluid animations and proactive intelligence.

---

## ✨ Features

- **Liquid UI Performance**: Physics-based morphing animations using custom spring solver for a tactile, "living" interface feel.
- **Micro-Action Gestures**: 
  - **Swipe Right**: Snooze your timer by +5 minutes.
  - **Swipe Left**: Instantly cancel the active process.
  - **Long Press**: Toggle between Power and Sleep modes without expanding.
- **Battery-Aware Intelligence**: Proactively suggests power-saving actions when your system is on battery and below 20%.
- **Intelligent Visibility**: Features "Smart Peeks"—the island auto-hides to reduce clutter and peeks back at strategic intervals to keep you informed.
- **Global Hotkey**: Instant access from any app via `Shift + Control + U`.
- **Glassmorphism Aesthetic**: Ultra-thin material design with dynamic urgency glows (Normal/Warning/Critical).

---

## 🚀 Technical Innovation

NotchDown isn't just a timer; it's an engineering exploration of how to bridge the gap between utility and delight on macOS.

- **Carbon Hotkey Engine**: Zero-latency system-wide shortcut handling without requiring accessibility permissions.
- **IOKit Power Monitoring**: Direct system-level integration for energy state awareness.
- **Modular SwiftUI Architecture**: Clean, production-ready codebase separated into ViewModels, Managers, and Custom Animators.

---

## 🛠️ Installation & Setup

1. **Requirements**: macOS 14.0 or newer. Optimized for Apple Silicon MacBooks with a notch.
2. **Build**: 
   - Open `notch-down.xcodeproj` in Xcode.
   - Select the `notch-down` scheme and Build & Run (⌘R).
3. **Shortcut**: Use `Shift + Control + U` to toggle the island at any time.

---

## 🎨 Aesthetics: "Godmode" UI

Every interaction in NotchDown is designed to feel premium. We use:
- **Custom Spring Physics**: To ensure every expansion and collapse feels organic.
- **OLED-Black Foundation**: Optimized for MacBook displays.
- **Haptic-Visual Feedback**: Symbolic bounces and glows that respond to your intent.

---

## 📄 License & Attribution

Designed and engineered for the ultimate macOS "Godmode" experience. 

*NotchDown is ready for the App Store. Let's make power management beautiful.*
