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
    
    private var sleepWakeObserver: NSObjectProtocol?
    private var timerStateBackup: TimerStateBackup?
    
    // MARK: - Initialization
    
    private init() {
        setupSystemObservers()
    }
    
    deinit {
        if let observer = sleepWakeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
    
    /// Backs up timer state before system sleep
    func backupTimerState(viewModel: TimerViewModel) {
        timerStateBackup = TimerStateBackup(
            timeRemaining: viewModel.timeRemaining,
            isActive: viewModel.isActive,
            scheduledAction: nil, // Would need to store this
            timestamp: Date()
        )
    }
    
    /// Restores timer state after system wake
    func restoreTimerState(viewModel: TimerViewModel) {
        guard let backup = timerStateBackup else { return }
        
        let timeElapsed = Date().timeIntervalSince(backup.timestamp)
        let newTimeRemaining = max(0, backup.timeRemaining - timeElapsed)
        
        if newTimeRemaining > 0 && backup.isActive {
            // Restore timer
            viewModel.timeRemaining = newTimeRemaining
            viewModel.isActive = backup.isActive
        } else if backup.isActive {
            // Timer expired during sleep
            handleTimerStateLoss()
            viewModel.cancelTimer()
        }
        
        timerStateBackup = nil
    }
    
    // MARK: - System Observers
    
    /// Sets up observers for system sleep/wake events
    private func setupSystemObservers() {
        // Observe system sleep
        sleepWakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // System is about to sleep
            // Timer state will be backed up by the view model
        }
        
        // Observe system wake
        let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // System has woken up
            // Timer state will be restored by the view model
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
