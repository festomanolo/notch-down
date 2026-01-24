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
            return Color.white.opacity(0.85)
        }
    }
    
    /// Secondary background for cards and buttons
    var secondaryBackground: Color {
        switch self {
        case .dark:
            return Color.white.opacity(0.08)
        case .light:
            return Color.black.opacity(0.05)
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

// MARK: - Visual Calculation Structs

/// Geometry calculations for Dynamic Island morphing animations
struct IslandGeometry {
    /// Size when collapsed to pill shape
    static let collapsedSize = CGSize(width: 120, height: 32)
    
    /// Size when fully expanded
    static let expandedSize = CGSize(width: 320, height: 180)
    
    /// Corner radius values for squircle geometry
    static let cornerRadius = (collapsed: 16.0, expanded: 24.0)
    
    /// Calculate frame size for given island state
    static func frameSize(for state: IslandState) -> CGSize {
        switch state {
        case .collapsed, .collapsing:
            return collapsedSize
        case .expanded, .critical, .about:
            return expandedSize
        case .expanding:
            // Return intermediate size during morphing
            return CGSize(
                width: collapsedSize.width + (expandedSize.width - collapsedSize.width) * 0.5,
                height: collapsedSize.height + (expandedSize.height - collapsedSize.height) * 0.5
            )
        }
    }
    
    /// Calculate corner radius for morphing progress (0.0 = collapsed, 1.0 = expanded)
    static func interpolateCornerRadius(progress: Double) -> Double {
        let clampedProgress = max(0.0, min(1.0, progress))
        return cornerRadius.collapsed + (cornerRadius.expanded - cornerRadius.collapsed) * clampedProgress
    }
}

/// Glow effect state for urgency visualization
struct GlowState {
    let intensity: Double       // Glow intensity (0.0 to 1.0)
    let color: Color           // Glow color
    let radius: Double         // Glow blur radius
    let pulseRate: Double      // Pulses per second
    
    /// Create glow state for urgency level
    static func forUrgency(_ urgency: UrgencyLevel) -> GlowState {
        switch urgency {
        case .normal:
            return GlowState(
                intensity: 0.3,
                color: Color.white,
                radius: 4.0,
                pulseRate: 0.0
            )
        case .warning:
            return GlowState(
                intensity: 0.6,
                color: Color.orange,
                radius: 8.0,
                pulseRate: 0.5
            )
        case .critical:
            return GlowState(
                intensity: 0.8,
                color: Color.red,
                radius: 12.0,
                pulseRate: 2.0
            )
        }
    }
    
    /// Calculate glow radius based on urgency level
    static func calculateGlowRadius(urgency: UrgencyLevel) -> Double {
        return forUrgency(urgency).radius
    }
}