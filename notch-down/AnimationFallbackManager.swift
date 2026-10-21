//
//  AnimationFallbackManager.swift
//  NotchDown
//
//  Picks the right animation for the user's motion preference.
//

import SwiftUI
import AppKit
import Combine

/// Honours System Settings › Accessibility › Display › Reduce Motion.
///
/// This used to poll CPU, frame rate and memory once a second and degrade
/// animations on the result — but CPU and frame rate were never actually
/// measured, so the timer only ever burned energy. The system preference is the
/// one signal that reflects what the user wants.
@MainActor
final class AnimationFallbackManager: ObservableObject {
    static let shared = AnimationFallbackManager()

    @Published private(set) var reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    enum AnimationType {
        case morphing
        case glowing
        case buttonSelection
    }

    private var observer: NSObjectProtocol?

    private init() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            }
        }
    }

    /// The animation for `type`, softened to a short fade under Reduce Motion.
    func getAnimation(for type: AnimationType) -> Animation {
        guard !reduceMotion else { return .easeInOut(duration: 0.15) }

        switch type {
        case .morphing:        return SpringAnimator.morphToExpanded()
        case .glowing:         return SpringAnimator.urgencyChange()
        case .buttonSelection: return SpringAnimator.buttonSelection()
        }
    }
}
