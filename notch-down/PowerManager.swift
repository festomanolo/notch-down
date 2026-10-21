//
//  PowerManager.swift
//  notch-down
//
//  Created by festomanolo on 22/01/2026.
//

import Foundation
import IOKit.pwr_mgt
import AppKit
import Combine

enum PowerAction: CaseIterable, Identifiable {
    case shutdown, restart, logout, sleep

    var id: Self { self }

    var iconName: String {
        switch self {
        case .shutdown: return "power"
        case .restart: return "arrow.clockwise"
        case .sleep: return "moon.zzz.fill"
        case .logout: return "rectangle.portrait.and.arrow.right"
        }
    }

    var displayName: String {
        switch self {
        case .shutdown: return "Shutdown"
        case .restart: return "Restart"
        case .sleep: return "Sleep"
        case .logout: return "Log Out"
        }
    }

    /// Bare verb for sentences like "System will shut down".
    ///
    /// `displayName.lowercased()` gave "System will shutdown", which reads as a
    /// noun where a verb belongs.
    var presentVerb: String {
        switch self {
        case .shutdown: return "shut down"
        case .restart:  return "restart"
        case .sleep:    return "sleep"
        case .logout:   return "log out"
        }
    }

    /// Verb used in confirmation copy, e.g. "shut down your Mac".
    var verbPhrase: String {
        switch self {
        case .shutdown: return "shut down your Mac"
        case .restart: return "restart your Mac"
        case .sleep: return "put your Mac to sleep"
        case .logout: return "log out of your account"
        }
    }
}

enum PowerManagerError: Error {
    case scriptExecutionFailed(String)
    case permissionDenied
    case fallbackFailed
    case verificationFailed
    case cancelled
    case busy

    var localizedDescription: String {
        switch self {
        case .scriptExecutionFailed(let details):
            return "Failed to execute power command: \(details)"
        case .permissionDenied:
            return "Permission denied. Grant NotchDown automation access in System Settings › Privacy & Security › Automation."
        case .fallbackFailed:
            return "Primary and fallback methods failed."
        case .verificationFailed:
            return "Could not verify permissions."
        case .cancelled:
            return "Cancelled."
        case .busy:
            return "Another power operation is already in progress."
        }
    }
}

/// Executes power actions.
///
/// Everything here is main-actor bound on purpose: `NSAppleScript` is not
/// thread-safe and must not be executed from a background queue (the previous
/// implementation ran it on `.userInteractive`, which intermittently corrupted
/// the AppleEvent machinery), and `NSAlert.runModal` must run on the main thread.
@MainActor
class PowerManager: ObservableObject {
    static let shared = PowerManager()

    @Published var lastError: PowerManagerError?
    @Published var isExecuting: Bool = false

    /// AppleScript error codes that mean "the user has not granted (or has
    /// revoked) automation access", as opposed to a genuine scripting failure.
    private static let permissionErrorCodes: Set<Int> = [-1743, -1744, -10004]

    /// Execute a power action.
    ///
    /// - Parameters:
    ///   - action: what to do.
    ///   - confirm: show a confirmation sheet first. Countdown expiry passes
    ///     `false` — starting the timer *was* the confirmation, and a modal that
    ///     nobody is present to answer would silently cancel the action.
    func execute(_ action: PowerAction,
                 confirm: Bool = true,
                 completion: ((Result<Void, PowerManagerError>) -> Void)? = nil) {
        guard !isExecuting else {
            lastError = .busy
            completion?(.failure(.busy))
            return
        }

        if confirm && !confirmWithUser(for: action) {
            completion?(.failure(.cancelled))
            return
        }

        #if DEBUG
        // `-NotchDownDryRun YES` on the command line: exercise every countdown
        // and UI path without ever touching the machine's power state.
        if UserDefaults.standard.bool(forKey: "NotchDownDryRun") {
            ToastManager.shared.warning("Dry run — would \(action.presentVerb) now")
            completion?(.success(()))
            return
        }
        #endif

        isExecuting = true

        let result = performExecution(action)

        isExecuting = false

        switch result {
        case .success:
            lastError = nil
        case .failure(let error):
            lastError = error
        }

        completion?(result)
    }

    /// Verify that the app can drive System Events.
    func verifyPermissions(completion: @escaping (Bool) -> Void) {
        // A no-op query: succeeds only if automation access has been granted.
        let testScript = "tell application \"System Events\" to get name"

        guard let script = NSAppleScript(source: testScript) else {
            completion(false)
            return
        }

        var error: NSDictionary?
        script.executeAndReturnError(&error)
        completion(error == nil)
    }

    // MARK: - Confirmation

    private func confirmWithUser(for action: PowerAction) -> Bool {
        // NotchDown is an LSUIElement accessory app, so it is usually not the
        // active application. Without this the alert opens *behind* whatever the
        // user is looking at and the action appears to do nothing.
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Confirm \(action.displayName)"
        alert.informativeText = "Are you sure you want to \(action.verbPhrase)?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: action.displayName)
        alert.addButton(withTitle: "Cancel")
        alert.window.level = .modalPanel

        return alert.runModal() == .alertFirstButtonReturn
    }

    // MARK: - Execution

    private func performExecution(_ action: PowerAction) -> Result<Void, PowerManagerError> {
        let primary = executePrimaryMethod(action)
        if case .success = primary { return .success(()) }

        let fallback = executeFallbackMethod(action)
        if case .success = fallback { return .success(()) }

        // Prefer reporting the primary failure — it carries the real diagnostic.
        if case .failure(let primaryError) = primary {
            return .failure(primaryError)
        }
        return fallback
    }

    /// Primary execution method using AppleScript.
    private func executePrimaryMethod(_ action: PowerAction) -> Result<Void, PowerManagerError> {
        let scriptSource: String

        switch action {
        case .shutdown:
            scriptSource = "tell application \"System Events\" to shut down"
        case .restart:
            scriptSource = "tell application \"System Events\" to restart"
        case .logout:
            scriptSource = "tell application \"System Events\" to log out"
        case .sleep:
            // IOKit is both faster and more reliable than scripting for sleep.
            return executeSleepViaIOKit()
        }

        guard let script = NSAppleScript(source: scriptSource) else {
            return .failure(.scriptExecutionFailed("Failed to compile AppleScript"))
        }

        var error: NSDictionary?
        script.executeAndReturnError(&error)

        guard let error = error else { return .success(()) }

        let code = error[NSAppleScript.errorNumber] as? Int ?? 0
        if Self.permissionErrorCodes.contains(code) {
            return .failure(.permissionDenied)
        }

        let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error (\(code))"
        return .failure(.scriptExecutionFailed(message))
    }

    /// Fallback execution method using IOKit and system commands.
    private func executeFallbackMethod(_ action: PowerAction) -> Result<Void, PowerManagerError> {
        switch action {
        case .sleep:
            return executeSleepViaIOKit()
        case .logout, .shutdown, .restart:
            return executeViaAppleEvent(action)
        }
    }

    /// Execute sleep using IOKit (most reliable for sleep).
    private func executeSleepViaIOKit() -> Result<Void, PowerManagerError> {
        let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
        guard port != MACH_PORT_NULL else { return .failure(.fallbackFailed) }

        let status = IOPMSleepSystem(port)
        IOServiceClose(port)

        return status == kIOReturnSuccess ? .success(()) : .failure(.fallbackFailed)
    }

    /// Fallback: send the raw Apple Event straight to loginwindow.
    ///
    /// Deliberately does *not* shell out to `launchctl bootout user/$(id -u)`
    /// like the previous implementation — that force-kills the entire user
    /// session with no chance for apps to save, and fails without root anyway.
    private func executeViaAppleEvent(_ action: PowerAction) -> Result<Void, PowerManagerError> {
        let eventCode: String
        switch action {
        case .shutdown: eventCode = "rsdn"
        case .restart:  eventCode = "rrst"
        case .logout:   eventCode = "rlgo"
        case .sleep:    eventCode = "slep"
        }

        let source = "tell application \"loginwindow\" to «event aevt\(eventCode)»"

        guard let script = NSAppleScript(source: source) else {
            return .failure(.fallbackFailed)
        }

        var error: NSDictionary?
        script.executeAndReturnError(&error)

        guard let error = error else { return .success(()) }

        let code = error[NSAppleScript.errorNumber] as? Int ?? 0
        if Self.permissionErrorCodes.contains(code) {
            return .failure(.permissionDenied)
        }
        return .failure(.fallbackFailed)
    }

    // MARK: - Settings

    /// Open System Settings to the Automation privacy pane.
    func openAutomationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }
}
