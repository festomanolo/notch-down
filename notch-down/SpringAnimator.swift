//
//  SpringAnimator.swift
//  NotchDown
//
//  The island's motion vocabulary. Every curve here is finite and
//  interruptible: a new target retargets the spring mid-flight instead of
//  queueing behind it, which is what makes the morph feel physical.
//

import SwiftUI

enum SpringAnimator {

    /// Growing out of the notch: quick with a small, confident overshoot —
    /// the iPhone Dynamic Island's "pop".
    static func morphToExpanded() -> Animation {
        .spring(duration: 0.46, bounce: 0.24)
    }

    /// Tucking back in: same speed, no overshoot, so the pill never appears to
    /// bounce *past* the notch.
    static func morphToCollapsed() -> Animation {
        .spring(duration: 0.38, bounce: 0.06)
    }

    /// Slide/fade of the whole island in and out of the notch.
    static func presence(_ visible: Bool) -> Animation {
        visible ? .spring(duration: 0.42, bounce: 0.18) : .spring(duration: 0.3, bounce: 0)
    }

    /// Content cross-fade between island states. Slightly slower than the
    /// shape so the new content settles after the shape has mostly arrived.
    static func contentSwap() -> Animation {
        .smooth(duration: 0.32)
    }

    /// Countdown digits rolling to their next value.
    static func slotMachineRoll() -> Animation {
        .snappy(duration: 0.36)
    }

    /// Urgency colour changes. Finite on purpose — a repeating curve here
    /// leaves every urgency-tinted view oscillating forever.
    static func urgencyChange() -> Animation {
        .easeInOut(duration: 0.45)
    }

    /// Dark/light switch.
    static func themeTransition() -> Animation {
        .easeInOut(duration: 0.35)
    }

    /// Preset chip selection.
    static func buttonSelection() -> Animation {
        .snappy(duration: 0.26, extraBounce: 0.08)
    }

    /// Hover lift on controls.
    static func hover() -> Animation {
        .spring(duration: 0.25, bounce: 0.3)
    }

    /// How long the morph takes to settle, for work that must wait for it.
    static let morphDuration: Double = 0.46
}
