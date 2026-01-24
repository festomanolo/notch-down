//
//  BatteryManager.swift
//  NotchDown
//
//  Created for Intelligent Power Management.
//

import Foundation
import Combine
import IOKit.ps

/// Singleton manager for monitoring system battery levels and power source state
class BatteryManager: ObservableObject {
    static let shared = BatteryManager()
    
    @Published var batteryLevel: Double = 100
    @Published var isPluggedIn: Bool = true
    
    private var timer: Timer?
    
    private init() {
        updateBatteryState()
        startMonitoring()
    }
    
    /// Starts periodic monitoring of battery state
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateBatteryState()
        }
    }
    
    /// Updates battery level and power source state using IOKit
    func updateBatteryState() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                let capacity = description[kIOPSCurrentCapacityKey] as? Int ?? 100
                let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
                let powerSource = description[kIOPSPowerSourceStateKey] as? String ?? kIOPSACPowerValue
                
                self.batteryLevel = (Double(capacity) / Double(maxCapacity)) * 100
                self.isPluggedIn = (powerSource == kIOPSACPowerValue)
                
                // Post notification for significant changes if needed
                NotificationCenter.default.post(name: .batteryStateChanged, object: nil)
                break
            }
        }
    }
}

extension Notification.Name {
    static let batteryStateChanged = Notification.Name("batteryStateChanged")
}
