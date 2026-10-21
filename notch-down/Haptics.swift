//
//  Haptics.swift
//  NotchDown
//
//  Force Touch trackpad feedback for gestures, matching the system's own
//  detents (snapping guides, Mission Control thresholds).
//

import AppKit

enum Haptics {
    /// A light detent — a gesture crossing its commit threshold.
    static func detent() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    /// A firmer bump — a gesture's action actually happening.
    static func confirm() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
}
