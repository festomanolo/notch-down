//
//  SpringAnimator.swift
//  NotchDown
//
//  Spring physics utility class for Dynamic Island morphing animations
//  Provides easing curves and animation calculations for premium visual effects
//

import SwiftUI

/// Utility class providing spring physics calculations and easing curves for Dynamic Island animations
struct SpringAnimator {
    
    // MARK: - Spring Physics Parameters
    
    /// Spring configuration for morphing animations using modern response/damping
    private struct SpringParams {
        let response: Double
        let damping: Double
        
        static let premium = SpringParams(response: 0.5, damping: 0.7) // iOS style snappiness
        static let bouncy = SpringParams(response: 0.6, damping: 0.5)  // More bounce for pop effects
        static let smooth = SpringParams(response: 0.4, damping: 0.8)  // Smooth transitions
    }
    
    // MARK: - Primary Animation Methods
    
    /// Creates spring animation for expanding Dynamic Island with a premium "pop" effect
    static func morphToExpanded() -> Animation {
        let params = SpringParams.bouncy
        return .spring(
            response: params.response,
            dampingFraction: params.damping,
            blendDuration: 0.1
        )
    }
    
    /// Creates spring animation for collapsing Dynamic Island
    static func morphToCollapsed() -> Animation {
        let params = SpringParams.smooth
        return .spring(
            response: params.response,
            dampingFraction: params.damping,
            blendDuration: 0.1
        )
    }
    
    /// Creates pulsing animation for urgency indicators (warning and critical states)
    /// Provides continuous pulsing effect with varying intensity based on urgency level
    static func urgencyPulse(for urgencyLevel: UrgencyLevel) -> Animation {
        let params = SpringParams.smooth
        let baseAnimation = Animation.spring(
            response: params.response,
            dampingFraction: params.damping
        )
        
        // Adjust animation speed based on urgency level
        switch urgencyLevel {
        case .normal:
            return baseAnimation.speed(0.0) // No pulsing for normal state
        case .warning:
            return baseAnimation.repeatForever(autoreverses: true).speed(0.5)
        case .critical:
            return baseAnimation.repeatForever(autoreverses: true).speed(2.0)
        }
    }
    
    /// Creates slot machine rolling animation for countdown number transitions
    /// Provides vertical rolling effect when countdown numbers change
    static func slotMachineRoll() -> Animation {
        let params = SpringParams.premium
        return .spring(
            response: params.response * 0.8, // Snappier for numbers
            dampingFraction: params.damping,
            blendDuration: 0.1
        )
    }
    
    // MARK: - Specialized Animation Variants
    
    /// Creates smooth glow animation for border effects during urgency states
    static func glowAnimation(for urgencyLevel: UrgencyLevel) -> Animation {
        switch urgencyLevel {
        case .normal:
            return .easeInOut(duration: 0.3)
        case .warning:
            return .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        case .critical:
            return .easeInOut(duration: 0.25).repeatForever(autoreverses: true)
        }
    }
    
    /// Creates theme transition animation for smooth dark/light mode switching
    static func themeTransition() -> Animation {
        return .easeInOut(duration: 0.4)
    }
    
    /// Creates button selection animation for timer option buttons
    static func buttonSelection() -> Animation {
        return .interpolatingSpring(
            mass: 0.8,
            stiffness: 0.9,
            damping: 0.7,
            initialVelocity: 0.0
        )
        .speed(1.5)
    }
    
    // MARK: - Animation Timing Utilities
    
    /// Standard duration for morphing animations - faster for premium feel
    static let morphDuration: Double = 0.35 // Reduced from 0.6
    
    /// Duration for urgency pulse cycle
    static let pulseDuration: Double = 0.8 // Slightly faster
    
    /// Duration for slot machine roll effect
    static let rollDuration: Double = 0.25 // Much faster
    
    /// Duration for glow fade transitions
    static let glowDuration: Double = 0.2 // Faster
    
    // MARK: - Easing Curve Calculations
    
    /// Calculates easing progress for morphing animations
    /// - Parameter progress: Linear progress from 0.0 to 1.0
    /// - Returns: Eased progress value using spring physics
    static func easeMorphProgress(_ progress: Double) -> Double {
        let clampedProgress = max(0.0, min(1.0, progress))
        
        // Apply spring easing curve
        // This approximates the spring physics curve for non-animated calculations
        let springFactor = 1.0 - pow(1.0 - clampedProgress, 2.5)
        let dampingFactor = 1.0 - (0.1 * sin(clampedProgress * .pi * 2))
        
        return springFactor * dampingFactor
    }
    
    /// Calculates bounce effect for button interactions
    /// - Parameter progress: Linear progress from 0.0 to 1.0
    /// - Returns: Bounce-eased progress value
    static func easeBounceProgress(_ progress: Double) -> Double {
        let clampedProgress = max(0.0, min(1.0, progress))
        
        if clampedProgress < 0.5 {
            // First half: compress
            return 2.0 * clampedProgress * clampedProgress
        } else {
            // Second half: expand with slight overshoot
            let adjustedProgress = (clampedProgress - 0.5) * 2.0
            return 0.5 + 0.5 * (2.0 * adjustedProgress - adjustedProgress * adjustedProgress)
        }
    }
    
    // MARK: - Animation State Helpers
    
    /// Determines if an animation should use hardware acceleration
    /// - Parameter animationType: The type of animation being performed
    /// - Returns: True if hardware acceleration should be used
    static func shouldUseHardwareAcceleration(for animationType: AnimationType) -> Bool {
        switch animationType {
        case .morphing, .glowing:
            return true // Complex animations benefit from hardware acceleration
        case .pulsing, .rolling:
            return false // Simple animations can use software rendering
        }
    }
    
    /// Animation types for hardware acceleration decisions
    enum AnimationType {
        case morphing   // Shape transformation animations
        case pulsing    // Urgency pulse animations
        case rolling    // Slot machine number rolling
        case glowing    // Border glow effects
    }
}

// MARK: - Animation Extensions

extension Animation {
    /// Creates a spring animation with Dynamic Island-optimized parameters
    static var dynamicIslandSpring: Animation {
        return SpringAnimator.morphToExpanded()
    }
    
    /// Creates an urgency pulse animation
    static func urgencyPulse(level: UrgencyLevel) -> Animation {
        return SpringAnimator.urgencyPulse(for: level)
    }
    
    /// Creates a slot machine roll animation
    static var slotMachineRoll: Animation {
        return SpringAnimator.slotMachineRoll()
    }
}

// MARK: - SwiftUI View Modifiers

extension View {
    /// Applies spring animation for Dynamic Island morphing
    func dynamicIslandMorph() -> some View {
        self.animation(.dynamicIslandSpring, value: UUID())
    }
    
    /// Applies urgency pulse animation based on urgency level
    func urgencyPulse(_ level: UrgencyLevel) -> some View {
        self.animation(.urgencyPulse(level: level), value: level)
    }
    
    /// Applies slot machine roll animation for number changes
    func slotMachineRoll() -> some View {
        self.animation(.slotMachineRoll, value: UUID())
    }
}