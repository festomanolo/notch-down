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
final class BatteryManager: ObservableObject {
    static let shared = BatteryManager()

    @Published private(set) var batteryLevel: Double = 100
    @Published private(set) var isPluggedIn: Bool = true

    private var runLoopSource: CFRunLoopSource?

    private init() {
        updateBatteryState()
        startMonitoring()
    }

    /// Subscribes to IOKit power-source changes.
    ///
    /// Event-driven instead of the old 60-second poll: updates land the moment
    /// the charger is pulled or the level ticks, with no timer waking the Mac.
    private func startMonitoring() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            Unmanaged<BatteryManager>.fromOpaque(context).takeUnretainedValue().updateBatteryState()
        }, context)?.takeRetainedValue() else { return }

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        runLoopSource = source
    }

    /// Updates battery level and power source state using IOKit
    func updateBatteryState() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any] else { continue }

            let capacity = description[kIOPSCurrentCapacityKey] as? Int ?? 100
            let maxCapacity = max(1, description[kIOPSMaxCapacityKey] as? Int ?? 100)
            let powerSource = description[kIOPSPowerSourceStateKey] as? String ?? kIOPSACPowerValue

            let level = Double(capacity) / Double(maxCapacity) * 100
            let pluggedIn = powerSource == kIOPSACPowerValue

            // Publish only real changes so subscribers are not re-run for nothing.
            if level != batteryLevel { batteryLevel = level }
            if pluggedIn != isPluggedIn { isPluggedIn = pluggedIn }
            break
        }
    }
}
