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
    
    func execute(_ action: PowerAction) {
        let scriptSource: String
        switch action {
        case .shutdown:
            scriptSource = "tell application \"System Events\" to shut down"
        case .restart:
            scriptSource = "tell application \"System Events\" to restart"
        case .logout:
            // High-fidelity forced logout event
            scriptSource = "tell application \"loginwindow\" to «event aevtrlgo»" 
        case .sleep:
            // Native fluid sleep transition
            scriptSource = "tell application \"Finder\" to sleep"
        }
        
        // Execute AppleScript with Godmode priority
        DispatchQueue.global(qos: .userInteractive).async {
            if let script = NSAppleScript(source: scriptSource) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                if let error = error {
                    print("Godmode execution error: \(error)")
                }
            }
        }
    }
}
