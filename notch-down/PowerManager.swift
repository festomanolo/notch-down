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

enum PowerAction: CaseIterable {
    case shutdown, restart, logout, sleep
    
    var iconName: String {
        switch self {
        case .shutdown: return "power"
        case .restart: return "arrow.clockwise"
        case .sleep: return "moon.zzz.fill"
        case .logout: return "person.and.arrow.left.and.arrow.right"
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
}

enum PowerManagerError: Error {
    case scriptExecutionFailed(String)
    case permissionDenied
    case fallbackFailed
    case verificationFailed
    
    var localizedDescription: String {
        switch self {
        case .scriptExecutionFailed(let details):
            return "Failed to execute power command: \(details)"
        case .permissionDenied:
            return "Permission denied. Please grant automation permissions in System Settings."
        case .fallbackFailed:
            return "Primary and fallback methods failed."
        case .verificationFailed:
            return "Could not verify permissions."
        }
    }
}

class PowerManager: ObservableObject {
    static let shared = PowerManager()
    
    @Published var lastError: PowerManagerError?
    @Published var isExecuting: Bool = false
    
    private var executionInProgress: Bool = false
    
    /// Execute a power action with comprehensive error handling and fallback mechanisms
    func execute(_ action: PowerAction, completion: ((Result<Void, PowerManagerError>) -> Void)? = nil) {
        // Prevent concurrent executions
        guard !executionInProgress else {
            let error = PowerManagerError.scriptExecutionFailed("Another power operation is in progress")
            DispatchQueue.main.async {
                self.lastError = error
                completion?(.failure(error))
            }
            return
        }
        
        executionInProgress = true
        DispatchQueue.main.async {
            self.isExecuting = true
        }
        
        // Show confirmation dialog for destructive actions
        if shouldConfirm(action) {
            DispatchQueue.main.async {
                self.showConfirmationDialog(for: action) { confirmed in
                    if confirmed {
                        self.performExecution(action, completion: completion)
                    } else {
                        self.executionInProgress = false
                        self.isExecuting = false
                        completion?(.failure(.scriptExecutionFailed("User cancelled")))
                    }
                }
            }
        } else {
            performExecution(action, completion: completion)
        }
    }
    
    /// Verify if the app has necessary permissions
    func verifyPermissions(completion: @escaping (Bool) -> Void) {
        // Test with a harmless AppleScript command
        let testScript = "tell application \"System Events\" to get name"
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let script = NSAppleScript(source: testScript) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                
                DispatchQueue.main.async {
                    completion(error == nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Check if action requires user confirmation
    private func shouldConfirm(_ action: PowerAction) -> Bool {
        // Only sleep doesn't require confirmation for quick access
        return action != .sleep
    }
    
    /// Show confirmation dialog
    private func showConfirmationDialog(for action: PowerAction, completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Confirm \(action.displayName)"
        alert.informativeText = "Are you sure you want to \(action.displayName.lowercased()) your Mac?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: action.displayName)
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        completion(response == .alertFirstButtonReturn)
    }
    
    /// Perform the actual execution with fallback
    private func performExecution(_ action: PowerAction, completion: ((Result<Void, PowerManagerError>) -> Void)?) {
        DispatchQueue.global(qos: .userInteractive).async {
            // Try primary method (AppleScript)
            let primaryResult = self.executePrimaryMethod(action)
            
            if case .failure = primaryResult {
                // Try fallback method
                let fallbackResult = self.executeFallbackMethod(action)
                
                if case .failure(let error) = fallbackResult {
                    // Both methods failed
                    DispatchQueue.main.async {
                        self.lastError = error
                        self.executionInProgress = false
                        self.isExecuting = false
                        self.showErrorDialog(error)
                        completion?(.failure(error))
                    }
                    return
                }
            }
            
            // Success
            DispatchQueue.main.async {
                self.executionInProgress = false
                self.isExecuting = false
                completion?(.success(()))
            }
        }
    }
    
    /// Primary execution method using AppleScript
    private func executePrimaryMethod(_ action: PowerAction) -> Result<Void, PowerManagerError> {
        let scriptSource: String
        
        switch action {
        case .shutdown:
            scriptSource = "tell application \"System Events\" to shut down"
        case .restart:
            scriptSource = "tell application \"System Events\" to restart"
        case .logout:
            // Fixed: Send Apple Event directly to loginwindow for robust logout
            // «event aevtrlgo» is the Apple Event code for 'really log out'
            scriptSource = "tell application \"loginwindow\" to «event aevtrlgo»"
        case .sleep:
            // Use IOKit directly as primary method for sleep
            let result = executeSleepViaIOKit()
            return result
        }
        
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            
            if let error = error {
                let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                return .failure(.scriptExecutionFailed(errorMessage))
            }
            return .success(())
        }
        
        return .failure(.scriptExecutionFailed("Failed to create AppleScript"))
    }
    
    /// Fallback execution method using IOKit and system commands
    private func executeFallbackMethod(_ action: PowerAction) -> Result<Void, PowerManagerError> {
        switch action {
        case .sleep:
            // Use IOKit for sleep
            return executeSleepViaIOKit()
        case .logout, .shutdown, .restart:
            // For other actions, try shell command as last resort
            return executeViaShellCommand(action)
        }
    }
    
    /// Execute sleep using IOKit (most reliable for sleep)
    private func executeSleepViaIOKit() -> Result<Void, PowerManagerError> {
        let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
        if port != MACH_PORT_NULL {
            IOPMSleepSystem(port)
            return .success(())
        }
        return .failure(.fallbackFailed)
    }
    
    /// Execute via shell command (last resort)
    private func executeViaShellCommand(_ action: PowerAction) -> Result<Void, PowerManagerError> {
        let command: String
        
        switch action {
        case .shutdown:
            command = "osascript -e 'tell app \"System Events\" to shut down'"
        case .restart:
            command = "osascript -e 'tell app \"System Events\" to restart'"
        case .logout:
            // Force logout via launchctl
            command = "/bin/launchctl bootout user/$(id -u)"
        case .sleep:
            // pmset sleepnow is a good fallback
            command = "/usr/bin/pmset sleepnow"
        }
        
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                return .success(())
            } else {
                return .failure(.fallbackFailed)
            }
        } catch {
            return .failure(.fallbackFailed)
        }
    }
    
    /// Show error dialog to user
    private func showErrorDialog(_ error: PowerManagerError) {
        let alert = NSAlert()
        alert.messageText = "Power Action Failed"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        
        if case .permissionDenied = error {
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "OK")
            
            if alert.runModal() == .alertFirstButtonReturn {
                openSystemSettings()
            }
        } else {
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    /// Open System Settings to Automation preferences
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Test a power action without executing (for debugging)
    func testAction(_ action: PowerAction, completion: @escaping (Bool) -> Void) {
        verifyPermissions { hasPermission in
            completion(hasPermission)
        }
    }
}
