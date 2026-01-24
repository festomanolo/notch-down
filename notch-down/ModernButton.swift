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
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11.5, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : color)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        // Base glass layer
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(isSelected ? 0 : 1)
                        
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
                // Start rotating glow
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    glowRotation = 360
                }
            } else {
                // Stop rotating glow
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

/// Minimize button with modern design
struct MinimizeButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "minus")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.white.opacity(isHovered ? 0.15 : 0.08))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

/// Power action button with color coding
struct PowerActionButton: View {
    let title: String
    let color: Color
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(isHovered ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}