//
//  MorphingGeometry.swift
//  NotchDown
//
//  Per-state sizes and corner radii the island morphs between.
//

import SwiftUI

enum MorphingGeometry {

    // MARK: - Base geometry

    // Sizes are the *content* box; NotchWindowController adds padding for
    // shadows and glow.
    private static let collapsedSize = CGSize(width: 240, height: 38)  // Pill, fits "Shutdown 1:00:00"
    private static let expandedSize = CGSize(width: 460, height: 250)
    private static let criticalSize = CGSize(width: 490, height: 290)  // Room for the full roller + urgency row
    private static let aboutSize = CGSize(width: 470, height: 386)

    // MARK: - Content-aware sizing

    /// What the island is currently showing.
    ///
    /// The expanded state's height varies a lot with its content — a preset
    /// picker is roughly 140pt while a running countdown with the digit roller
    /// is over 220 — so a single per-state height either clipped the roller or
    /// left a slab of dead space under the buttons.
    struct ContentContext: Equatable {
        var isTimerActive = false
        var isShowingSuggestion = false
        var isShowingCustomInput = false
        var showsPermissionWarning = false
        /// The "less than a minute" banner under a running countdown.
        var showsUrgencyNotice = false

        static let empty = ContentContext()
    }

    /// Frame for a state, sized to what it is actually displaying.
    ///
    /// These are explicit numbers rather than a measurement of the live view on
    /// purpose. The height has to be a continuous, animatable value for the
    /// morph spring to interpolate; feeding it back from a GeometryReader
    /// through a preference lags a layout pass and reads the *outgoing* state's
    /// height mid-transition, which pinned the island at pill height.
    ///
    /// If a state's layout changes, update its figure here.
    static func calculateFrame(for state: IslandState, content: ContentContext = .empty) -> CGSize {
        switch state {
        case .collapsed:
            return collapsedSize

        case .about:
            return aboutSize

        case .expanded, .critical:
            var size = state == .critical ? criticalSize : expandedSize
            if content.isShowingSuggestion {
                size.height = 178
            } else if content.isTimerActive {
                size.height = 234
                size.height = state == .critical ? 246 : 234
            } else if content.isShowingCustomInput {
                size.height = 178
            } else {
                size.height = 150
            }
            if content.showsPermissionWarning {
                size.height += 64
            }
            return size
        }
    }

    /// The largest frame any state can occupy, across every content variation.
    ///
    /// The window is sized to this once and never resized, so the island can
    /// morph freely inside it without dragging AppKit's layout engine along.
    static var largestStateSize: CGSize {
        let worstCase = ContentContext(isTimerActive: true, showsPermissionWarning: true)

        return IslandState.allCases.reduce(CGSize.zero) { partial, state in
            let plain = calculateFrame(for: state)
            let loaded = calculateFrame(for: state, content: worstCase)
            return CGSize(
                width: max(partial.width, plain.width, loaded.width),
                height: max(partial.height, plain.height, loaded.height)
            )
        }
    }

    // MARK: - Corner radius

    /// Continuous-curve radius per state. The pill's is half its height so its
    /// ends are perfectly round.
    static func cornerRadius(for state: IslandState) -> Double {
        switch state {
        case .collapsed: return collapsedSize.height / 2
        case .expanded:  return 26
        case .critical:  return 28
        case .about:     return 30
        }
    }
}
