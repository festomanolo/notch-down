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
    case collapsed      // Pill tucked under the notch
    case expanded       // Full interface visible
    case critical       // Auto-expanded for urgency (< 1 minute or < 10 seconds)
    case about          // About & settings page
}

/// Represents urgency levels for visual feedback during countdown
enum UrgencyLevel: CaseIterable {
    case normal         // > 1 minute remaining
    case warning        // < 1 minute remaining
    case critical       // < 10 seconds remaining
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
    var accentOrange: Color { Color.orange }
}
