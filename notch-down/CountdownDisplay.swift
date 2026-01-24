//
//  CountdownDisplay.swift
//  NotchDown
//
//  Countdown display component with slot machine animations and urgency indicators
//  Features rolling number transitions and pulsing effects for critical states
//

import SwiftUI

/// Countdown display component providing timer visualization with slot machine animations
/// Features urgency indicators, pulsing effects, and smooth number transitions
struct CountdownDisplay: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Main countdown timer with slot machine animation
            timerDisplay
            
            // Action description
            actionDescription
            
            // Urgency indicator (shown for warning and critical states)
            if viewModel.urgencyLevel != .normal {
                urgencyIndicator
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        HStack(spacing: 8) {
            // Minutes slot
            digitSlot(text: minutesText, label: "MIN", value: minutes)
            
            // Separator
            Text(":")
                .font(.system(size: timerFontSize * 0.8, weight: .bold, design: .monospaced))
                .foregroundColor(viewModel.currentTheme.textColor.opacity(0.5))
                .padding(.top, -10)
            
            // Seconds slot
            digitSlot(text: secondsText, label: "SEC", value: seconds)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        
        .background(
            ZStack {
                // Glassmorphism background for the whole timer
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(viewModel.currentTheme.backgroundColor.opacity(0.4))
                    .background(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(viewModel.currentTheme.borderColor.opacity(0.2), lineWidth: 1)
            }
        )
    }
    
    @ViewBuilder
    private func digitSlot(text: String, label: String, value: Int) -> some View {
        VStack(spacing: 4) {
            ZStack {
                // Background slot shape
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 70, height: 60)
                
                Text(text)
                    .font(.system(size: timerFontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(viewModel.currentTheme.textColor)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
            }
            .urgencyPulse(viewModel.urgencyLevel)
            
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                .tracking(1)
        }
    }
    
    // MARK: - Action Description
    
    private var actionDescription: some View {
        Text("System will shut down")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(viewModel.currentTheme.secondaryTextColor)
            .multilineTextAlignment(.center)
    }
    
    // MARK: - Urgency Indicator
    
    private var urgencyIndicator: some View {
        HStack(spacing: 8) {
            // Pulsing indicator dot
            Circle()
                .fill(viewModel.urgencyLevel.glowColor)
                .frame(width: 10, height: 10)
                .animation(SpringAnimator.urgencyPulse(for: viewModel.urgencyLevel), value: viewModel.urgencyLevel)
                .shadow(color: viewModel.urgencyLevel.glowColor, radius: 4)
            
            // Urgency text
            Text(urgencyText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(viewModel.urgencyLevel.glowColor)
            
            // Warning icon for critical state
            if viewModel.urgencyLevel == .critical {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(viewModel.urgencyLevel.glowColor)
                    .animation(SpringAnimator.urgencyPulse(for: viewModel.urgencyLevel), value: viewModel.urgencyLevel)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(urgencyBackground)
    }
    
    // MARK: - Computed Properties
    
    /// Current minutes value
    private var minutes: Int {
        Int(viewModel.timeRemaining) / 60
    }
    
    /// Current seconds value
    private var seconds: Int {
        Int(viewModel.timeRemaining) % 60
    }
    
    /// Formatted minutes text with leading zero
    private var minutesText: String {
        String(format: "%02d", minutes)
    }
    
    /// Formatted seconds text with leading zero
    private var secondsText: String {
        String(format: "%02d", seconds)
    }
    
    /// Dynamic timer font size based on urgency and state
    private var timerFontSize: CGFloat {
        switch viewModel.urgencyLevel {
        case .normal:
            return viewModel.islandState == .critical ? 52 : 48
        case .warning:
            return viewModel.islandState == .critical ? 54 : 50
        case .critical:
            return viewModel.islandState == .critical ? 56 : 52
        }
    }
    
    /// Urgency text description
    private var urgencyText: String {
        switch viewModel.urgencyLevel {
        case .normal:
            return ""
        case .warning:
            return "Less than 1 minute remaining"
        case .critical:
            return "CRITICAL - Less than 10 seconds!"
        }
    }
    
    /// Timer background with glassmorphism effect
    private var timerBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        timerBorderColor,
                        lineWidth: timerBorderWidth
                    )
            )
            .shadow(color: timerShadowColor, radius: timerShadowRadius)
    }
    
    /// Urgency indicator background
    private var urgencyBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(viewModel.urgencyLevel.glowColor.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        viewModel.urgencyLevel.glowColor.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(color: viewModel.urgencyLevel.glowColor.opacity(0.3), radius: 4)
    }
    
    /// Dynamic timer border color based on urgency
    private var timerBorderColor: Color {
        switch viewModel.urgencyLevel {
        case .normal:
            return viewModel.currentTheme.borderColor.opacity(0.3)
        case .warning:
            return Color.orange.opacity(0.5)
        case .critical:
            return Color.red.opacity(0.7)
        }
    }
    
    /// Dynamic timer border width based on urgency
    private var timerBorderWidth: CGFloat {
        switch viewModel.urgencyLevel {
        case .normal:
            return 0.5
        case .warning:
            return 1.0
        case .critical:
            return 1.5
        }
    }
    
    /// Dynamic timer shadow color based on urgency
    private var timerShadowColor: Color {
        switch viewModel.urgencyLevel {
        case .normal:
            return Color.clear
        case .warning:
            return Color.orange.opacity(0.3)
        case .critical:
            return Color.red.opacity(0.5)
        }
    }
    
    /// Dynamic timer shadow radius based on urgency
    private var timerShadowRadius: CGFloat {
        switch viewModel.urgencyLevel {
        case .normal:
            return 0
        case .warning:
            return 6
        case .critical:
            return 10
        }
    }
}

// MARK: - Compact Countdown Display

/// Compact version of countdown display for collapsed and expanding states
struct CompactCountdownDisplay: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        HStack(spacing: 6) {
            // Dynamic Power Action Icon
            Image(systemName: actionIconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(urgencyColor)
                .symbolEffect(.bounce, value: viewModel.timeRemaining)
            
            // Action Label + Time remaining
            HStack(spacing: 4) {
                Text(actionDisplayName)
                    .font(.system(size: fontSize * 0.9, weight: .bold, design: .rounded))
                    .foregroundColor(urgencyColor.opacity(0.8))
                    .fixedSize(horizontal: true, vertical: false)
                
                Text(viewModel.timeString)
                    .font(.system(size: fontSize, weight: .semibold, design: .monospaced))
                    .foregroundColor(urgencyColor)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(SpringAnimator.slotMachineRoll(), value: viewModel.timeRemaining)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(urgencyColor.opacity(0.12))
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(urgencyColor.opacity(0.3), lineWidth: 1)
            }
        )
    }
    
    private var actionIconName: String {
        viewModel.currentPowerAction.iconName
    }
    
    private var actionDisplayName: String {
        switch viewModel.currentPowerAction {
        case .shutdown: return "Shutdown"
        case .restart: return "Restart"
        case .sleep: return "Sleep"
        case .logout: return "Log Out"
        }
    }
    
    private var iconName: String {
        switch viewModel.urgencyLevel {
        case .normal:
            return "timer"
        case .warning:
            return "timer.square"
        case .critical:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var urgencyColor: Color {
        switch viewModel.urgencyLevel {
        case .normal:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
    
    /// Dynamic font size based on island state
    private var fontSize: CGFloat {
        switch viewModel.islandState {
        case .collapsed, .collapsing:
            return 12
        case .expanding:
            return 14
        case .expanded, .critical, .about:
            return 16
        }
    }
}

// MARK: - Preview

#Preview("Normal State") {
    CountdownDisplay(viewModel: {
        let vm = TimerViewModel()
        vm.isActive = true
        vm.timeRemaining = 300 // 5 minutes
        vm.urgencyLevel = .normal
        vm.currentTheme = .dark
        return vm
    }())
    .frame(width: 320, height: 200)
    .background(Color.black)
}

#Preview("Warning State") {
    CountdownDisplay(viewModel: {
        let vm = TimerViewModel()
        vm.isActive = true
        vm.timeRemaining = 45 // 45 seconds
        vm.urgencyLevel = .warning
        vm.currentTheme = .dark
        return vm
    }())
    .frame(width: 320, height: 200)
    .background(Color.black)
}

#Preview("Critical State") {
    CountdownDisplay(viewModel: {
        let vm = TimerViewModel()
        vm.isActive = true
        vm.timeRemaining = 5 // 5 seconds
        vm.urgencyLevel = .critical
        vm.currentTheme = .dark
        vm.islandState = .critical
        return vm
    }())
    .frame(width: 340, height: 220)
    .background(Color.black)
}

#Preview("Compact Display") {
    CompactCountdownDisplay(viewModel: {
        let vm = TimerViewModel()
        vm.isActive = true
        vm.timeRemaining = 120 // 2 minutes
        vm.urgencyLevel = .warning
        vm.currentTheme = .dark
        vm.islandState = .collapsed
        return vm
    }())
    .frame(width: 120, height: 32)
    .background(Color.black)
}