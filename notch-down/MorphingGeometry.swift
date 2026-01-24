//
//  MorphingGeometry.swift
//  NotchDown
//
//  Enhanced geometry calculations for Dynamic Island morphing animations
//  Provides smooth transitions, interpolation, and advanced visual calculations
//

import SwiftUI

/// Enhanced geometry utility for Dynamic Island morphing animations
/// Provides sophisticated calculations for size transitions, corner radius morphing, and glow effects
struct MorphingGeometry {
    
    // MARK: - Core Geometry Constants
    
    /// Base geometry definitions for Dynamic Island states
    private struct BaseGeometry {
        static let collapsedSize = CGSize(width: 220, height: 36) // Wider for text labels
        static let expandedSize = CGSize(width: 480, height: 120) // Much wider, shorter
        static let criticalSize = CGSize(width: 500, height: 130) // Slightly larger for critical state
        static let aboutSize = CGSize(width: 360, height: 220) // Taller for profile and about info
        
        static let collapsedRadius: Double = 16.0
        static let expandedRadius: Double = 20.0
        static let criticalRadius: Double = 22.0
        static let aboutRadius: Double = 24.0
    }
    
    // MARK: - Frame Size Calculations
    
    /// Calculate frame size for given island state with smooth interpolation
    /// Enhanced version that supports more nuanced state transitions
    static func calculateFrame(for state: IslandState) -> CGSize {
        switch state {
        case .collapsed:
            return BaseGeometry.collapsedSize
            
        case .expanding:
            // Use easing curve for smooth expansion
            let progress = 0.3 // Early expansion phase
            return interpolateSize(
                from: BaseGeometry.collapsedSize,
                to: BaseGeometry.expandedSize,
                progress: easeInOutProgress(progress)
            )
            
        case .expanded:
            return BaseGeometry.expandedSize
            
        case .collapsing:
            // Use easing curve for smooth collapse
            let progress = 0.7 // Late collapse phase
            return interpolateSize(
                from: BaseGeometry.expandedSize,
                to: BaseGeometry.collapsedSize,
                progress: easeInOutProgress(progress)
            )
            
        case .critical:
            return BaseGeometry.criticalSize
            
        case .about:
            return BaseGeometry.aboutSize
        }
    }
    
    /// Calculate frame size with custom progress for smooth morphing animations
    /// - Parameters:
    ///   - fromState: Starting island state
    ///   - toState: Target island state
    ///   - progress: Animation progress from 0.0 to 1.0
    /// - Returns: Interpolated frame size
    static func calculateFrame(from fromState: IslandState, to toState: IslandState, progress: Double) -> CGSize {
        let fromSize = calculateFrame(for: fromState)
        let toSize = calculateFrame(for: toState)
        let easedProgress = easeInOutProgress(progress)
        
        return interpolateSize(from: fromSize, to: toSize, progress: easedProgress)
    }
    
    // MARK: - Corner Radius Calculations
    
    /// Interpolate corner radius for smooth squircle morphing with enhanced easing
    /// - Parameter progress: Morphing progress from 0.0 (collapsed) to 1.0 (expanded)
    /// - Returns: Interpolated corner radius value
    static func interpolateCornerRadius(progress: Double) -> Double {
        let clampedProgress = max(0.0, min(1.0, progress))
        let easedProgress = easeInOutProgress(clampedProgress)
        
        return BaseGeometry.collapsedRadius + 
               (BaseGeometry.expandedRadius - BaseGeometry.collapsedRadius) * easedProgress
    }
    
    /// Calculate corner radius for specific island state
    /// - Parameter state: Current island state
    /// - Returns: Appropriate corner radius for the state
    static func cornerRadius(for state: IslandState) -> Double {
        switch state {
        case .collapsed, .collapsing:
            return BaseGeometry.collapsedRadius
        case .expanded:
            return BaseGeometry.expandedRadius
        case .expanding:
            return interpolateCornerRadius(progress: 0.5)
        case .critical:
            return BaseGeometry.criticalRadius
        case .about:
            return BaseGeometry.aboutRadius
        }
    }
    
    /// Calculate corner radius with custom transition progress
    /// - Parameters:
    ///   - fromState: Starting island state
    ///   - toState: Target island state
    ///   - progress: Animation progress from 0.0 to 1.0
    /// - Returns: Interpolated corner radius
    static func cornerRadius(from fromState: IslandState, to toState: IslandState, progress: Double) -> Double {
        let fromRadius = cornerRadius(for: fromState)
        let toRadius = cornerRadius(for: toState)
        let easedProgress = easeInOutProgress(progress)
        
        return fromRadius + (toRadius - fromRadius) * easedProgress
    }
    
    // MARK: - Glow Effect Calculations
    
    /// Calculate glow radius based on urgency level with enhanced scaling
    /// - Parameter urgency: Current urgency level
    /// - Returns: Appropriate glow radius in points
    static func calculateGlowRadius(urgency: UrgencyLevel) -> Double {
        switch urgency {
        case .normal:
            return 4.0
        case .warning:
            return 8.0
        case .critical:
            return 12.0
        }
    }
    
    /// Calculate glow intensity based on urgency level and animation phase
    /// - Parameters:
    ///   - urgency: Current urgency level
    ///   - animationPhase: Current animation phase
    /// - Returns: Glow intensity from 0.0 to 1.0
    static func calculateGlowIntensity(urgency: UrgencyLevel, animationPhase: AnimationPhase) -> Double {
        let baseIntensity: Double
        
        switch urgency {
        case .normal:
            baseIntensity = 0.3
        case .warning:
            baseIntensity = 0.6
        case .critical:
            baseIntensity = 0.8
        }
        
        // Modify intensity based on animation phase
        switch animationPhase {
        case .idle:
            return baseIntensity
        case .morphing:
            return baseIntensity * 0.7 // Reduced during morphing
        case .pulsing:
            return baseIntensity * 1.2 // Enhanced during pulsing
        case .rolling:
            return baseIntensity
        case .glowing:
            return baseIntensity * 1.5 // Maximum during glow phase
        }
    }
    
    /// Calculate glow offset for dynamic glow positioning
    /// - Parameters:
    ///   - urgency: Current urgency level
    ///   - time: Current time for animation cycling
    /// - Returns: Glow offset as CGPoint
    static func calculateGlowOffset(urgency: UrgencyLevel, time: Double) -> CGPoint {
        guard urgency != .normal else { return .zero }
        
        let amplitude: Double = urgency == .critical ? 2.0 : 1.0
        let frequency: Double = urgency == .critical ? 3.0 : 2.0
        
        let x = sin(time * frequency) * amplitude
        let y = cos(time * frequency * 0.7) * amplitude * 0.5
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Advanced Morphing Calculations
    
    /// Calculate morphing progress with spring physics simulation
    /// - Parameters:
    ///   - linearProgress: Linear progress from 0.0 to 1.0
    ///   - springConfig: Spring configuration parameters
    /// - Returns: Spring-eased progress value
    static func springMorphProgress(_ linearProgress: Double, springConfig: SpringConfig = .default) -> Double {
        let clampedProgress = max(0.0, min(1.0, linearProgress))
        
        // Simulate spring physics
        let dampingFactor = exp(-springConfig.damping * clampedProgress)
        let oscillation = sin(clampedProgress * .pi * springConfig.frequency) * dampingFactor
        let baseProgress = 1.0 - cos(clampedProgress * .pi * 0.5)
        
        return baseProgress + oscillation * springConfig.amplitude
    }
    
    /// Calculate bezier curve morphing for smooth path transitions
    /// - Parameters:
    ///   - progress: Animation progress from 0.0 to 1.0
    ///   - controlPoint1: First bezier control point
    ///   - controlPoint2: Second bezier control point
    /// - Returns: Bezier-eased progress value
    static func bezierMorphProgress(_ progress: Double, 
                                   controlPoint1: CGPoint = CGPoint(x: 0.25, y: 0.1),
                                   controlPoint2: CGPoint = CGPoint(x: 0.25, y: 1.0)) -> Double {
        let clampedProgress = max(0.0, min(1.0, progress))
        
        // Cubic bezier calculation
        let t = clampedProgress
        let oneMinusT = 1.0 - t
        
        return 3.0 * oneMinusT * oneMinusT * t * controlPoint1.y +
               3.0 * oneMinusT * t * t * controlPoint2.y +
               t * t * t
    }
    
    // MARK: - Utility Functions
    
    /// Interpolate between two CGSize values
    /// - Parameters:
    ///   - from: Starting size
    ///   - to: Target size
    ///   - progress: Interpolation progress from 0.0 to 1.0
    /// - Returns: Interpolated size
    private static func interpolateSize(from: CGSize, to: CGSize, progress: Double) -> CGSize {
        let clampedProgress = max(0.0, min(1.0, progress))
        
        return CGSize(
            width: from.width + (to.width - from.width) * clampedProgress,
            height: from.height + (to.height - from.height) * clampedProgress
        )
    }
    
    /// Apply ease-in-out curve to linear progress
    /// - Parameter progress: Linear progress from 0.0 to 1.0
    /// - Returns: Eased progress value
    private static func easeInOutProgress(_ progress: Double) -> Double {
        let clampedProgress = max(0.0, min(1.0, progress))
        
        if clampedProgress < 0.5 {
            return 2.0 * clampedProgress * clampedProgress
        } else {
            let adjustedProgress = clampedProgress - 0.5
            return 0.5 + 2.0 * adjustedProgress * (1.0 - adjustedProgress)
        }
    }
    
    // MARK: - Spring Configuration
    
    /// Configuration for spring physics calculations
    struct SpringConfig {
        let damping: Double
        let frequency: Double
        let amplitude: Double
        
        static let `default` = SpringConfig(damping: 2.0, frequency: 1.5, amplitude: 0.1)
        static let bouncy = SpringConfig(damping: 1.0, frequency: 2.0, amplitude: 0.2)
        static let smooth = SpringConfig(damping: 3.0, frequency: 1.0, amplitude: 0.05)
    }
}

// MARK: - Backward Compatibility

extension MorphingGeometry {
    /// Provides backward compatibility with existing IslandGeometry usage
    static func frameSize(for state: IslandState) -> CGSize {
        return calculateFrame(for: state)
    }
}

// MARK: - SwiftUI Integration

extension View {
    /// Apply morphing geometry calculations to view frame
    /// - Parameter state: Current island state
    /// - Returns: View with calculated frame size
    func morphingFrame(for state: IslandState) -> some View {
        let size = MorphingGeometry.calculateFrame(for: state)
        return self.frame(width: size.width, height: size.height)
    }
    
    /// Apply morphing corner radius to view
    /// - Parameter state: Current island state
    /// - Returns: View with calculated corner radius
    func morphingCornerRadius(for state: IslandState) -> some View {
        let radius = MorphingGeometry.cornerRadius(for: state)
        return self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}