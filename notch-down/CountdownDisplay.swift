//
//  CountdownDisplay.swift
//  NotchDown
//
//  Countdown display component with slot machine animations and urgency indicators
//  Features rolling number transitions and pulsing effects for critical states
//

import SwiftUI

/// Countdown display with a slot-machine digit roller, urgency colouring and a
/// cancel affordance. Rendered by the expanded and critical island states.
struct CountdownDisplay: View {
    @ObservedObject var viewModel: TimerViewModel

    private var theme: AppTheme { viewModel.currentTheme }
    private var isCritical: Bool { viewModel.islandState == .critical }

    var body: some View {
        VStack(spacing: 10) {
            timerDisplay

            actionDescription

            if viewModel.urgencyLevel != .normal {
                urgencyIndicator
            }

            HStack(spacing: 8) {
                ModernButton(title: "+5 min", color: .blue, isSelected: false) {
                    viewModel.snoozeTimer()
                }

                ModernButton(title: "Cancel Timer", color: .red, isSelected: false) {
                    viewModel.cancelTimer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        HStack(spacing: 8) {
            if hours > 0 {
                digitSlot(text: hoursText, label: "HRS", value: hours)
                separator
            }

            digitSlot(text: minutesText, label: "MIN", value: minutes)
            separator
            digitSlot(text: secondsText, label: "SEC", value: seconds)
        }
        // Last ten seconds: the digits give a small heartbeat on every tick.
        .phaseAnimator(heartbeatPhases, trigger: viewModel.secondsRemaining) { digits, scale in
            digits.scaleEffect(scale)
        } animation: { scale in
            scale > 1 ? .easeOut(duration: 0.09) : .spring(duration: 0.35, bounce: 0.4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.secondaryBackground.opacity(0.6))

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(urgencyTint.opacity(0.28), lineWidth: 1)
            }
        )
        // Time left, draining continuously along the bottom of the well.
        .overlay(alignment: .bottom) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(urgencyTint.opacity(0.15))
                    Capsule()
                        .fill(urgencyTint)
                        .frame(width: proxy.size.width * viewModel.progress)
                        .shadow(color: urgencyTint.opacity(0.6), radius: 3)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 22)
            .padding(.bottom, 4)
            .animation(.linear(duration: 1), value: viewModel.progress)
        }
    }

    private var heartbeatPhases: [CGFloat] {
        viewModel.urgencyLevel == .critical ? [1, 1.07, 1] : [1]
    }

    private var separator: some View {
        Text(":")
            .font(.system(size: timerFontSize * 0.7, weight: .bold, design: .monospaced))
            .foregroundColor(theme.textColor.opacity(0.4))
            .padding(.bottom, 14)
    }

    @ViewBuilder
    private func digitSlot(text: String, label: String, value: Int) -> some View {
        VStack(spacing: 3) {
            ZStack {
                // Slot well: tinted from the theme rather than a fixed black,
                // which rendered black-on-black digits in light mode.
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(theme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.06))
                    .frame(width: slotSize.width, height: slotSize.height)

                Text(text)
                    .font(.system(size: timerFontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.textColor)
                    // The roller itself: numericText transitions each digit
                    // vertically as the value counts down.
                    .contentTransition(.numericText(countsDown: true))
                    .animation(SpringAnimator.slotMachineRoll(), value: value)
            }

            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(theme.secondaryTextColor)
                .tracking(1)
        }
    }

    // MARK: - Action Description

    private var actionDescription: some View {
        Text("System will \(viewModel.scheduledAction?.presentVerb ?? "shut down")")
            .font(.system(size: 12.5, weight: .medium, design: .rounded))
            .foregroundColor(theme.secondaryTextColor)
            .multilineTextAlignment(.center)
    }

    // MARK: - Urgency Indicator

    private var urgencyIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(urgencyTint)
                .frame(width: 8, height: 8)
                .shadow(color: urgencyTint, radius: 4)

            Text(urgencyText)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundColor(urgencyTint)

            if viewModel.urgencyLevel == .critical {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(urgencyTint)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(urgencyTint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(urgencyTint.opacity(0.3), lineWidth: 1)
                )
        )
        // Swap the label outright instead of cross-fading it. Inheriting the
        // island's morph animation blended the warning and critical strings
        // into each other and left them stacked, unreadable, indefinitely.
        //
        // Note there is deliberately no `.id(urgencyLevel)` here. Adding one
        // makes it worse, not better: a changed id tells SwiftUI to remove the
        // old view and insert a new one, which is precisely the insert/remove
        // transition that renders both labels at once. Without it, the string
        // change is an ordinary redraw.
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }

    // MARK: - Computed Properties

    private var totalSeconds: Int { viewModel.secondsRemaining }
    private var hours: Int { totalSeconds / 3600 }
    private var minutes: Int { hours > 0 ? (totalSeconds % 3600) / 60 : totalSeconds / 60 }
    private var seconds: Int { totalSeconds % 60 }

    private var hoursText: String { String(format: "%02d", hours) }
    private var minutesText: String { String(format: "%02d", minutes) }
    private var secondsText: String { String(format: "%02d", seconds) }

    /// Slot geometry shrinks when a third (hours) slot is on screen so the row
    /// still fits inside the island.
    private var slotSize: CGSize {
        if hours > 0 {
            return CGSize(width: 54, height: isCritical ? 50 : 46)
        }
        return CGSize(width: 66, height: isCritical ? 58 : 52)
    }

    private var timerFontSize: CGFloat {
        if hours > 0 { return isCritical ? 32 : 29 }
        return isCritical ? 42 : 37
    }

    /// Colour used for urgency glow, chrome and text.
    ///
    /// Note this replaces `UrgencyLevel.glowColor`, whose `.normal` case is a
    /// translucent white — invisible against the light theme.
    private var urgencyTint: Color {
        switch viewModel.urgencyLevel {
        case .normal:   return theme.accentBlue
        case .warning:  return theme.accentOrange
        case .critical: return .red
        }
    }

    private var urgencyText: String {
        switch viewModel.urgencyLevel {
        case .normal:   return ""
        case .warning:  return "Less than 1 minute remaining"
        case .critical: return "CRITICAL — Less than 10 seconds!"
        }
    }
}

// MARK: - Compact Countdown Display

/// Compact countdown shown in the collapsed pill
struct CompactCountdownDisplay: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        HStack(spacing: 6) {
            ProgressRing(progress: viewModel.progress, color: urgencyColor, lineWidth: 2.2) {
                Image(systemName: actionIconName)
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundColor(urgencyColor)
            }
            .frame(width: 17, height: 17)

            Text(actionDisplayName)
                .font(.system(size: fontSize * 0.92, weight: .bold, design: .rounded))
                .foregroundColor(urgencyColor.opacity(0.85))
                .fixedSize()

            Text(viewModel.timeString)
                .font(.system(size: fontSize, weight: .semibold, design: .monospaced))
                .foregroundColor(urgencyColor)
                .contentTransition(.numericText(countsDown: true))
                .animation(SpringAnimator.slotMachineRoll(), value: viewModel.timeRemaining)
                .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(urgencyColor.opacity(0.12))

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(urgencyColor.opacity(0.3), lineWidth: 1)
            }
        )
    }

    private var actionIconName: String {
        (viewModel.scheduledAction ?? viewModel.currentPowerAction).iconName
    }

    private var actionDisplayName: String {
        (viewModel.scheduledAction ?? viewModel.currentPowerAction).displayName
    }

    private var urgencyColor: Color {
        switch viewModel.urgencyLevel {
        case .normal:   return viewModel.currentTheme.accentBlue
        case .warning:  return viewModel.currentTheme.accentOrange
        case .critical: return .red
        }
    }

    private var fontSize: CGFloat {
        switch viewModel.islandState {
        case .collapsed:
            return 12
        case .expanded, .critical, .about:
            return 14
        }
    }
}

// MARK: - Progress Ring

/// Circular time-remaining indicator, like the system timer's Live Activity.
///
/// Animated linearly over each one-second tick, so consecutive ticks chain into
/// one continuous drain rather than a series of hops.
struct ProgressRing<Center: View>: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 2.5
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.22), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)

            center()
        }
    }
}
