//
//  PowerManager.swift
//  notch-down
//
//  Created by festomanolo on 22/01/2026.
//


import Foundation
import IOKit.pwr_mgt

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
}

class PowerManager {
    static let shared = PowerManager()
    
    /// Checks if video is playing or system is rendering (prevents accidental shutdown)
    func isSystemBusy() -> Bool {
        var assertions: Unmanaged<CFDictionary>?
        let result = IOPMCopyAssertionsByProcess(&assertions)
        
        guard result == kIOReturnSuccess, let assertionsDict = assertions?.takeRetainedValue() as? [String: Any] else {
            return false
        }
        
        for (_, value) in assertionsDict {
            if let assertionInfo = value as? [String: Any],
               let type = assertionInfo[kIOPMAssertionTypeKey] as? String {
                if type == kIOPMAssertionTypeNoDisplaySleep || type == kIOPMAssertionTypeNoIdleSleep {
                    return true
                }
            }
        }
        return false
    }
    
    func execute(_ action: PowerAction) {
        // Godmode: Always execute if triggered by user/timer, bypass busy check for now to ensure reliability
        let scriptSource: String
        switch action {
        case .shutdown:
            scriptSource = "tell application \"System Events\" to shut down"
        case .restart:
            scriptSource = "tell application \"System Events\" to restart"
        case .logout:
            scriptSource = "tell application \"loginwindow\" to «event aevtrlgo»" // Direct logout event
        case .sleep:
            scriptSource = "tell application \"Finder\" to sleep"
        }
        
        // Execute AppleScript
        if let script = NSAppleScript(source: scriptSource) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Error: \(error)")
            }
        }
    }
}
