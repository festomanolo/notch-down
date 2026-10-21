//
//  ModernButton.swift
//  NotchDown
//
//  Modern outlined button with glowing hover effects for macOS/iOS 26 style
//

import SwiftUI

/// Modern outlined button with glowing hover effects
struct ModernButton: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var glowRotation: Double = 0
    @Environment(\.colorScheme) private var colorScheme

    /// Tinted label colour. Yellow and orange text on a light panel was close
    /// to invisible, so on light backgrounds the tint is deepened.
    private var labelColor: Color {
        guard !isSelected else { return .white }
        return colorScheme == .light ? color.mix(with: .black, by: 0.35) : color
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11.5, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(labelColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        // Base glass layer
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(isSelected ? 0 : 0.6)
                        
                        // Selected state liquid fill
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
                        } else {
                            // Subtle background for non-selected
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(color.opacity(isHovered ? 0.15 : 0.05))
                        }
                        
                        // Glass border
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                color.opacity(isSelected ? 0.4 : 0.2),
                                lineWidth: 1
                            )
                        
                        // Glowing rotating border on hover (Premium UX)
                        if isHovered && !isSelected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    AngularGradient(
                                        colors: [
                                            color.opacity(0.8),
                                            color,
                                            color.opacity(0.3),
                                            color.opacity(0.1),
                                            color.opacity(0.8)
                                        ],
                                        center: .center,
                                        startAngle: .degrees(glowRotation),
                                        endAngle: .degrees(glowRotation + 360)
                                    ),
                                    lineWidth: 2
                                )
                                .blur(radius: 1)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }

            if hovering {
                // Only kick off the rotation if one is not already running —
                // re-entering the button used to stack a second (and third…)
                // repeatForever animation on the same property.
                if glowRotation == 0 {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        glowRotation = 360
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    glowRotation = 0
                }
            }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isHovered)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
    }
}

/// Minimize button with modern design.
///
/// Takes the theme: the glyph and its well were hardcoded white, so on the
/// light background this button was white-on-white and effectively invisible.
struct MinimizeButton: View {
    let theme: AppTheme
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.textColor.opacity(0.85))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(theme.secondaryBackground.opacity(isHovered ? 1.6 : 1.0))
                        .overlay(
                            Circle()
                                .stroke(theme.borderColor, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help("Minimize to the notch")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}
