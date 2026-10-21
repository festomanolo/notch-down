//
//  DebugCommands.swift
//  NotchDown
//
//  Debug builds only: drive the island from the command line so UI states can
//  be exercised and captured without touching the keyboard or mouse.
//
//  Post the distributed notification "manolo.notch-down.debug" with a
//  "command" string in userInfo, e.g. "expand", "about", "start:65:shutdown".
//

#if DEBUG
import Foundation

extension TimerViewModel {
    func installDebugCommands() -> NSObjectProtocol {
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("manolo.notch-down.debug"),
            object: nil,
            queue: .main
        ) { [weak self] note in
            let command = note.userInfo?["command"] as? String ?? ""
            MainActor.assumeIsolated { self?.runDebugCommand(command) }
        }
    }

    private func runDebugCommand(_ command: String) {
        let parts = command.split(separator: ":").map(String.init)
        switch parts.first {
        case "expand":   expandIsland()
        case "collapse": collapseIsland()
        case "about":    showAboutPage()
        case "back":     returnFromAboutPage()
        case "snooze":   snoozeTimer()
        case "cancel":   cancelTimer()
        case "toggle":   togglePrimaryAction()
        case "custom":   openCustomTimerInput(for: currentPowerAction)
        case "light":    setTheme(.light)
        case "dark":     setTheme(.dark)
        case "toast":    ToastManager.shared.info(parts.dropFirst().joined(separator: ":"))
        case "start":
            // Refuse to arm a real power action from the debug channel.
            guard UserDefaults.standard.bool(forKey: "NotchDownDryRun") else {
                ToastManager.shared.error("Debug start needs -NotchDownDryRun YES")
                return
            }
            let seconds = Double(parts.count > 1 ? parts[1] : "") ?? 65
            let action = PowerAction.allCases.first { "\($0)" == (parts.count > 2 ? parts[2] : "") } ?? .shutdown
            startTimer(minutes: seconds / 60, action: action)
        default:
            ToastManager.shared.warning("Unknown debug command: \(command)")
        }
    }
}
#endif
