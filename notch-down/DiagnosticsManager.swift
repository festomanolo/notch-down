//
//  DiagnosticsManager.swift
//  NotchDown
//
//  Comprehensive diagnostics and testing for power management functionality
//

import Foundation
import AppKit
import IOKit.pwr_mgt
import Combine
import UniformTypeIdentifiers

/// Diagnostics manager for testing and verifying system capabilities
class DiagnosticsManager: ObservableObject {
    static let shared = DiagnosticsManager()
    
    @Published var diagnosticResults: [DiagnosticResult] = []
    @Published var isRunningDiagnostics = false
    
    struct DiagnosticResult: Identifiable {
        let id = UUID()
        let category: String
        let test: String
        let status: Status
        let message: String
        let timestamp: Date
        
        enum Status {
            case passed
            case warning
            case failed
            case info
            
            var color: NSColor {
                switch self {
                case .passed: return .systemGreen
                case .warning: return .systemOrange
                case .failed: return .systemRed
                case .info: return .systemBlue
                }
            }
            
            var icon: String {
                switch self {
                case .passed: return "checkmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .failed: return "xmark.circle.fill"
                case .info: return "info.circle.fill"
                }
            }
        }
    }
    
    private init() {}
    
    /// Run comprehensive diagnostics
    func runDiagnostics(completion: @escaping () -> Void) {
        isRunningDiagnostics = true
        diagnosticResults.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Test 1: System Information
            self.testSystemInformation()
            
            // Test 2: Permissions
            self.testPermissions()
            
            // Test 3: Power Management Capabilities
            self.testPowerCapabilities()
            
            // Test 4: AppleScript Execution
            self.testAppleScriptExecution()
            
            // Test 5: IOKit Access
            self.testIOKitAccess()
            
            // Test 6: Battery Status
            self.testBatteryStatus()
            
            DispatchQueue.main.async {
                self.isRunningDiagnostics = false
                completion()
            }
        }
    }
    
    // MARK: - Individual Tests
    
    private func testSystemInformation() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        
        addResult(
            category: "System",
            test: "macOS Version",
            status: .info,
            message: "Running macOS \(versionString)"
        )
        
        let hasNotch = NSScreen.main?.safeAreaInsets.top ?? 0 > 0
        addResult(
            category: "System",
            test: "Display Type",
            status: hasNotch ? .passed : .warning,
            message: hasNotch ? "MacBook with notch detected" : "No notch detected (app will still work)"
        )
    }
    
    private func testPermissions() {
        let semaphore = DispatchSemaphore(value: 0)
        var hasPermission = false
        
        PowerManager.shared.verifyPermissions { result in
            hasPermission = result
            semaphore.signal()
        }
        
        semaphore.wait()
        
        addResult(
            category: "Permissions",
            test: "Automation Access",
            status: hasPermission ? .passed : .failed,
            message: hasPermission ? "Automation permissions granted" : "Automation permissions required"
        )
    }
    
    private func testPowerCapabilities() {
        // Test if we can access power management
        let canAccessPower = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL)) != MACH_PORT_NULL
        
        addResult(
            category: "Power Management",
            test: "IOKit Power Access",
            status: canAccessPower ? .passed : .warning,
            message: canAccessPower ? "IOKit power management accessible" : "Limited power management access"
        )
    }
    
    private func testAppleScriptExecution() {
        // Test with a harmless command
        let testScript = "tell application \"System Events\" to get name"
        
        if let script = NSAppleScript(source: testScript) {
            var error: NSDictionary?
            let result = script.executeAndReturnError(&error)
            
            if error == nil && result.stringValue != nil {
                addResult(
                    category: "AppleScript",
                    test: "Script Execution",
                    status: .passed,
                    message: "AppleScript execution working"
                )
            } else {
                let errorMsg = error?["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                addResult(
                    category: "AppleScript",
                    test: "Script Execution",
                    status: .failed,
                    message: "AppleScript failed: \(errorMsg)"
                )
            }
        } else {
            addResult(
                category: "AppleScript",
                test: "Script Execution",
                status: .failed,
                message: "Cannot create AppleScript"
            )
        }
    }
    
    private func testIOKitAccess() {
        let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
        
        if port != MACH_PORT_NULL {
            addResult(
                category: "IOKit",
                test: "Power Management Port",
                status: .passed,
                message: "IOKit power management port accessible"
            )
        } else {
            addResult(
                category: "IOKit",
                test: "Power Management Port",
                status: .warning,
                message: "Cannot access IOKit power port (sleep may use fallback)"
            )
        }
    }
    
    private func testBatteryStatus() {
        let batteryLevel = BatteryManager.shared.batteryLevel
        let isPluggedIn = BatteryManager.shared.isPluggedIn
        
        let statusMessage = isPluggedIn ? 
            "Plugged in, battery at \(Int(batteryLevel))%" : 
            "On battery, \(Int(batteryLevel))% remaining"
        
        addResult(
            category: "Battery",
            test: "Battery Monitoring",
            status: .info,
            message: statusMessage
        )
    }
    
    // MARK: - Helper Methods
    
    private func addResult(category: String, test: String, status: DiagnosticResult.Status, message: String) {
        DispatchQueue.main.async {
            let result = DiagnosticResult(
                category: category,
                test: test,
                status: status,
                message: message,
                timestamp: Date()
            )
            self.diagnosticResults.append(result)
        }
    }
    
    /// Generate a diagnostic report as text
    func generateReport() -> String {
        var report = "NotchDown Diagnostic Report\n"
        report += "Generated: \(Date())\n"
        report += String(repeating: "=", count: 50) + "\n\n"
        
        let groupedResults = Dictionary(grouping: diagnosticResults) { $0.category }
        
        for (category, results) in groupedResults.sorted(by: { $0.key < $1.key }) {
            report += "\(category):\n"
            for result in results {
                let statusSymbol: String
                switch result.status {
                case .passed: statusSymbol = "✓"
                case .warning: statusSymbol = "⚠"
                case .failed: statusSymbol = "✗"
                case .info: statusSymbol = "ℹ"
                }
                report += "  \(statusSymbol) \(result.test): \(result.message)\n"
            }
            report += "\n"
        }
        
        return report
    }
    
    /// Export diagnostic report to file
    func exportReport(completion: @escaping (URL?) -> Void) {
        let report = generateReport()
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "NotchDown_Diagnostics_\(Date().timeIntervalSince1970).txt"
        savePanel.title = "Export Diagnostic Report"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try report.write(to: url, atomically: true, encoding: .utf8)
                    completion(url)
                } catch {
                    print("Failed to export report: \(error)")
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}
