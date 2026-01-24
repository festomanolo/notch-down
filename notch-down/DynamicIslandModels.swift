//
//  DynamicIslandModels.swift
//  NotchDown
//
//  Data models for Dynamic Island interface state management and visual calculations
//

import SwiftUI

// MARK: - Island State Management

/// Represents the current state of the Dynamic Island interface
enum IslandState: CaseIterable {
    case collapsed      // Pill shape in menu bar
    case expanding      // Morphing animation in progress
    case expanded       // Full interface visible
    case collapsing     // Returning to pill shape
    case critical       // Auto-expanded for urgency (< 1 minute or < 10 seconds)
    case about          // Dedicated About page for festomanolo profile
}

/// Represents the current animation phase for visual effects
enum AnimationPhase: CaseIterable {
    case idle           // No animation active
    case morphing       // Shape transformation in progress
    case pulsing        // Urgency pulsing effect
    case rolling        // Slot machine effect for countdown numbers
    case glowing        // Border glow animation for urgency
}

/// Represents urgency levels for visual feedback during countdown
enum UrgencyLevel: CaseIterable {
    case normal         // White glow (> 1 minute remaining)
    case warning        // Amber glow (< 1 minute remaining)
    case critical       // Red glow (< 10 seconds remaining)
    
    /// The glow color associated with this urgency level
    var glowColor: Color {
        switch self {
        case .normal:
            return Color.white.opacity(0.3)
        case .warning:
            return Color.orange.opacity(0.6)
        case .critical:
            return Color.red.opacity(0.8)
        }
    }
    
    /// The pulse rate for urgency animations (pulses per second)
    var pulseRate: Double {
        switch self {
        case .normal:
            return 0.0      // No pulsing
        case .warning:
            return 0.5      // Slow pulse
        case .critical:
            return 2.0      // Fast pulse
        }
    }
}

// MARK: - Time Selection Models

/// Available time options for timer selection
enum TimeOption: CaseIterable {
    case custom
    case fiveMinutes
    case tenMinutes
    case thirtyMinutes
    case fortyFiveMinutes
    case oneHour
    
    /// Display text for the timer option button
    var displayText: String {
        switch self {
        case .custom:
            return "Custom"
        case .fiveMinutes:
            return "5m"
        case .tenMinutes:
            return "10m"
        case .thirtyMinutes:
            return "30m"
        case .fortyFiveMinutes:
            return "45m"
        case .oneHour:
            return "1h"
        }
    }
    
    /// Duration in minutes (nil for custom option)
    var minutes: Double? {
        switch self {
        case .custom:
            return nil
        case .fiveMinutes:
            return 5.0
        case .tenMinutes:
            return 10.0
        case .thirtyMinutes:
            return 30.0
        case .fortyFiveMinutes:
            return 45.0
        case .oneHour:
            return 60.0
        }
    }
}

// MARK: - Theme Management

/// Available visual themes for the Dynamic Island interface
enum AppTheme: CaseIterable {
    case dark
    case light
    
    /// Background color for the Dynamic Island with glassmorphism
    var backgroundColor: Color {
        switch self {
        case .dark:
            return Color.black.opacity(0.85)  // Glassmorphism effect
        case .light:
            return Color.white.opacity(0.92) // Higher contrast glass for Godmode
        }
    }
    
    /// Secondary background for cards and buttons
    var secondaryBackground: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.08)
        case .light:
            return Color.black.opacity(0.08) // More visible secondary background
        }
    }
    
    /// Border color for glassmorphism effect and outlined buttons
    var borderColor: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.2)
        case .light:
            return Color.black.opacity(0.15)
        }
    }
    
    /// Primary text color
    var textColor: Color {
        switch self {
        case .dark:
            return Color.white
        case .light:
            return Color.black
        }
    }
    
    /// Secondary text color (60% opacity for hierarchy)
    var secondaryTextColor: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.7)
        case .light:
            return Color.black.opacity(0.6)
        }
    }
    
    /// Modern accent colors
    var accentBlue: Color { Color.blue }
    var accentGreen: Color { Color.green }
    var accentOrange: Color { Color.orange }
    var accentYellow: Color { Color.yellow }
    
    /// Glow color for urgency effects
    var glowColor: Color {
        switch self {
        case .dark:
            return Color.white
        case .light:
            return Color.black
        }
    }
}

// MARK: - Legacy Geometry Removal
// Consolidated into MorphingGeometry.swift