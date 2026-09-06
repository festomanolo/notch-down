//
//  ErrorHandler.swift
//  NotchDown
//
//  Comprehensive error handling for system integration, permissions, and timer state preservation
//

import SwiftUI
import AppKit
import Combine

/// Error handler for Dynamic Island interface
/// Handles permission errors, system sleep/wake cycles, and power operation conflicts
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    // MARK: - Published Properties
    
    @Published var lastError: ErrorInfo?
    @Published var isSystemBusy: Bool = false
    
    // MARK: - Error Types
    
    struct ErrorInfo: Identifiable {
        let id = UUID()
        let type: ErrorType
        let message: String
        let timestamp: Date
        
        enum ErrorType {
            case permissionDenied
            case systemBusy
            case timerStateLost
            case powerOperationConflict
            case systemSleep
            case unknown
        }
    }
    
    // MARK: - Private Properties
    
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var timerStateBackup: TimerStateBackup?
    
    // MARK: - Initialization
    
    private init() {
        setupSystemObservers()
    }
    
    deinit {
        let center = NSWorkspace.shared.notificationCenter
        [sleepObserver, wakeObserver].compactMap { $0 }.forEach(center.removeObserver)
    }
    
    // MARK: - Error Handling
    
    /// Handles permission errors with clear dialog display
    func handlePermissionError(_ error: Error, context: String) {
        let errorInfo = ErrorInfo(
            type: .permissionDenied,
            message: "Permission denied: \(context). \(error.localizedDescription)",
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.lastError = errorInfo
            self.showPermissionDialog(context: context)
        }
    }
    
    /// Handles system busy state
    func handleSystemBusy() {
        isSystemBusy = true
        let errorInfo = ErrorInfo(
            type: .systemBusy,
            message: "System is busy. Power operation cannot be executed.",
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.lastError = errorInfo
        }
        
        // Auto-clear after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isSystemBusy = false
        }
    }
    
    /// Handles power operation conflicts
    func handlePowerOperationConflict() {
        let errorInfo = ErrorInfo(
            type: .powerOperationConflict,
            message: "Another power operation is in progress. Please wait.",
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.lastError = errorInfo
        }
    }
    
    /// Handles timer state loss during system sleep
    func handleTimerStateLoss() {
        let errorInfo = ErrorInfo(
            type: .timerStateLost,
            message: "Timer state was lost during system sleep. Timer has been reset.",
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.lastError = errorInfo
        }
    }
    
    // MARK: - Timer State Preservation
    
    /// Records a snapshot of the countdown for diagnostics.
    ///
    /// Recovery itself is no longer done here: `TimerViewModel` stores an
    /// absolute deadline and recomputes from it on wake. The old restore path
    /// wrote `timeRemaining` back without restarting the run-loop timer, which
    /// left the countdown frozen on screen after every sleep.
    @MainActor
    func backupTimerState(viewModel: TimerViewModel) {
        timerStateBackup = TimerStateBackup(
            timeRemaining: viewModel.timeRemaining,
            isActive: viewModel.isActive,
            scheduledAction: viewModel.scheduledAction,
            timestamp: Date()
        )
    }

    /// The last recorded countdown snapshot, if any.
    func lastTimerSnapshot() -> (timeRemaining: TimeInterval, isActive: Bool, timestamp: Date)? {
        guard let backup = timerStateBackup else { return nil }
        return (backup.timeRemaining, backup.isActive, backup.timestamp)
    }
    
    // MARK: - System Observers
    
    /// Sets up observers for system sleep/wake events.
    ///
    /// Both handles are retained. The wake observer used to be stored in a
    /// local, so it was never removed and leaked for the life of the process.
    private func setupSystemObservers() {
        let center = NSWorkspace.shared.notificationCenter

        sleepObserver = center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isSystemBusy = true
        }

        wakeObserver = center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isSystemBusy = false
        }
    }
    
    // MARK: - Dialog Display
    
    /// Shows permission dialog
    private func showPermissionDialog(context: String) {
        let alert = NSAlert()
        alert.messageText = "Permission Required"
        alert.informativeText = "NotchDown requires \(context) permission to function properly. Please grant permission in System Preferences."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Open System Preferences
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    // MARK: - Timer State Backup
    
    private struct TimerStateBackup {
        let timeRemaining: TimeInterval
        let isActive: Bool
        let scheduledAction: PowerAction?
        let timestamp: Date
    }
}
