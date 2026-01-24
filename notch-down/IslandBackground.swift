//
//  IslandBackground.swift
//  NotchDown
//
//  Dynamic Island background component with glassmorphism effects and dynamic glow system
//

import SwiftUI

/// The visual foundation component for the Dynamic Island interface
/// Provides glassmorphism effects, dynamic glow system, and squircle geometry
struct IslandBackground: View {
    let state: IslandState
    let urgency: UrgencyLevel
    let theme: AppTheme
    
    @State private var glowAnimation: Bool = false
    @State private var morphProgress: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base background with pure #000000 OLED black
                backgroundShape
                    .fill(theme.backgroundColor)
                
                // Glassmorphism blur overlay
                backgroundShape
                    .fill(.ultraThinMaterial.opacity(0.1))
                
                // Translucent frosted glass border with 1px stroke
                backgroundShape
                    .stroke(
                        borderGradient,
                        lineWidth: 1.0
                    )
                
                // Dynamic glow system
                if urgency != .normal {
                    // Intense Strobe Pulse Overlay
                    backgroundShape
                        .fill(Color.white)
                        .opacity(strobeOpacity)
                        .blur(radius: 2)
                    
                    backgroundShape
                        .stroke(
                            glowColor,
                            lineWidth: glowLineWidth
                        )
                        .blur(radius: glowRadius)
                        .opacity(glowOpacity)
                        .scaleEffect(glowAnimation ? strobeScale : 1.0)
                        .animation(
                            glowAnimationType,
                            value: glowAnimation
                        )
                }
            }
        }
        .onAppear {
            startGlowAnimation()
            updateMorphProgress()
        }
        .onChange(of: state) { _ in
            updateMorphProgress()
        }
        .onChange(of: urgency) { _ in
            startGlowAnimation()
        }
    }
    
    // MARK: - Background Shape with Squircle Geometry
    
    private var backgroundShape: some Shape {
        RoundedRectangle(
            cornerRadius: currentCornerRadius,
            style: .continuous
        )
    }
    
    /// Calculates current corner radius based on island state with continuous morphing
    private var currentCornerRadius: Double {
        MorphingGeometry.cornerRadius(for: state)
    }
    
    // MARK: - Border Styling
    
    /// Translucent frosted glass border gradient
    private var borderGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                theme.borderColor.opacity(0.8),
                theme.borderColor.opacity(0.3),
                theme.borderColor.opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Dynamic Glow System
    
    /// Glow color with white/amber/red progression
    private var glowColor: Color {
        switch urgency {
        case .normal:
            return Color.clear
        case .warning:
            return Color.orange.opacity(0.8)
        case .critical:
            return Color.red.opacity(0.9)
        }
    }
    
    /// Dynamic glow line width based on urgency
    private var glowLineWidth: Double {
        switch urgency {
        case .normal:
            return 0.0
        case .warning:
            return 2.0
        case .critical:
            return 3.0
        }
    }
    
    /// Dynamic glow blur radius
    private var glowRadius: Double {
        MorphingGeometry.calculateGlowRadius(urgency: urgency)
    }
    
    /// Glow opacity with pulsing effect
    private var glowOpacity: Double {
        let baseOpacity = MorphingGeometry.calculateGlowIntensity(urgency: urgency, animationPhase: .idle)
        
        if urgency.pulseRate > 0 {
            // More aggressive pulse for strobe effect
            return glowAnimation ? baseOpacity : baseOpacity * 0.3
        } else {
            return baseOpacity
        }
    }
    
    /// High-intensity strobe opacity calculation
    private var strobeOpacity: Double {
        guard urgency != .normal && glowAnimation else { return 0 }
        // Strobes briefly at the peak of the pulse
        return urgency == .critical ? 0.25 : 0.12
    }
    
    /// Increased scale for critical strobe effect
    private var strobeScale: CGFloat {
        switch urgency {
        case .normal: return 1.0
        case .warning: return 1.04
        case .critical: return 1.08
        }
    }
    
    /// Animation type for glow effects
    private var glowAnimationType: Animation {
        if urgency.pulseRate > 0 {
            return .easeInOut(duration: 1.0 / urgency.pulseRate)
                .repeatForever(autoreverses: true)
        } else {
            return .easeInOut(duration: 0.3)
        }
    }
    
    // MARK: - Animation Control
    
    /// Starts the glow animation based on urgency level
    private func startGlowAnimation() {
        if urgency.pulseRate > 0 {
            glowAnimation = true
        } else {
            glowAnimation = false
        }
    }
    
    /// Updates morphing progress for smooth transitions
    private func updateMorphProgress() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            switch state {
            case .collapsed, .collapsing:
                morphProgress = 0.0
            case .expanding:
                morphProgress = 0.5
            case .expanded, .critical, .about:
                morphProgress = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview("Normal State") {
    IslandBackground(
        state: .expanded,
        urgency: .normal,
        theme: .dark
    )
    .frame(width: 320, height: 180)
    .background(Color.gray.opacity(0.1))
}

#Preview("Warning State") {
    IslandBackground(
        state: .expanded,
        urgency: .warning,
        theme: .dark
    )
    .frame(width: 320, height: 180)
    .background(Color.gray.opacity(0.1))
}

#Preview("Critical State") {
    IslandBackground(
        state: .critical,
        urgency: .critical,
        theme: .dark
    )
    .frame(width: 320, height: 180)
    .background(Color.gray.opacity(0.1))
}

#Preview("Collapsed State") {
    IslandBackground(
        state: .collapsed,
        urgency: .normal,
        theme: .dark
    )
    .frame(width: 120, height: 32)
    .background(Color.gray.opacity(0.1))
}