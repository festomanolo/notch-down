//
//  DynamicIslandView.swift
//  NotchDown
//
//  Modern Dynamic Island interface with macOS/iOS 26 style design
//  Features glassmorphism, outlined buttons with glowing effects, and minimalist layout
//

import SwiftUI
import AppKit
import Combine

/// Main Dynamic Island interface component with modern design.
///
/// This view owns *all* of the island's motion — morphing between states, the
/// slide-in from the notch, and the urgency nudge. The window it lives in is a
/// fixed-size transparent box that never animates, which is what keeps AppKit's
/// layout engine out of the loop.
struct DynamicIslandView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject private var motion = AnimationFallbackManager.shared

    /// Horizontal offset for the urgency attention nudge.
    @State private var nudgeOffset: CGFloat = 0
    @State private var isHoveringPill = false

    var body: some View {
        let size = currentFrameSize
        let shape = RoundedRectangle(
            cornerRadius: MorphingGeometry.cornerRadius(for: viewModel.islandState),
            style: .continuous
        )

        ZStack(alignment: .top) {
            ModernIslandBackground(
                state: viewModel.islandState,
                urgency: viewModel.urgencyLevel,
                theme: viewModel.currentTheme
            )

            // Each state's content blur-fades in once the shape is under way
            // and is clipped to the island, so nothing spills past the edge
            // mid-morph. (A stuck half-faded swap used to happen here; the
            // cause was the repeatForever urgency curve, since removed.)
            contentLayer
                .id(contentKind)
                .transition(.islandContent)
                .frame(width: size.width, height: size.height, alignment: .top)
                .clipShape(shape)
        }
        // An explicit, continuous size is what the morph spring interpolates.
        .frame(width: size.width, height: size.height)
        .animation(morphAnimation, value: size)
        .animation(morphAnimation, value: viewModel.islandState)
        // The resting pill leans in under the pointer, like a control would.
        .scaleEffect(viewModel.islandState == .collapsed && isHoveringPill ? 1.04 : 1, anchor: .top)
        .animation(SpringAnimator.hover(), value: isHoveringPill)
        .onHover { isHoveringPill = $0 }
        // Entrance: drops out of the notch, sharpening as it settles.
        .scaleEffect(viewModel.isIslandVisible ? 1.0 : 0.82, anchor: .top)
        .blur(radius: viewModel.isIslandVisible || motion.reduceMotion ? 0 : 6)
        .offset(x: nudgeOffset, y: viewModel.isIslandVisible ? 0 : -22)
        .opacity(viewModel.isIslandVisible ? 1 : 0)
        .onChange(of: viewModel.attentionNudge) {
            playAttentionNudge()
        }
        // Published last so the reported rect matches what is actually drawn.
        .reportsIslandHitRegion()
    }

    /// Bouncy on the way out of the notch, no overshoot on the way back in.
    private var morphAnimation: Animation {
        if motion.reduceMotion { return .easeInOut(duration: 0.15) }
        return viewModel.islandState == .collapsed
            ? SpringAnimator.morphToCollapsed()
            : SpringAnimator.morphToExpanded()
    }

    /// Quick sideways flick, then settle. Replaces the old window-frame shake.
    private func playAttentionNudge() {
        guard !motion.reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.08)) { nudgeOffset = 6 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(duration: 0.5, bounce: 0.55)) { nudgeOffset = 0 }
        }
    }

    // MARK: - Content Layer

    /// Identity for the content cross-fade. Expanded and critical share one,
    /// so the urgency pop-out grows in place rather than re-fading.
    private enum ContentKind: Hashable {
        case pill, panel, about
    }

    private var contentKind: ContentKind {
        switch viewModel.islandState {
        case .collapsed:            return .pill
        case .expanded, .critical:  return .panel
        case .about:                return .about
        }
    }

    @ViewBuilder
    private var contentLayer: some View {
        switch viewModel.islandState {
        case .collapsed:
            collapsedContent

        case .expanded, .critical:
            expandedContent

        case .about:
            AboutView(viewModel: viewModel)
        }
    }

    // MARK: - Collapsed State Content

    private var collapsedContent: some View {
        HStack(spacing: 8) {
            if viewModel.isActive {
                CompactCountdownDisplay(viewModel: viewModel)
            } else {
                TappableCountdownStarter(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        // Swipe/long-press shortcuts only make sense while a timer is running,
        // and they must never be attached when the pill hosts a button — a
        // DragGesture over the whole pill swallowed the button's tap, which is
        // why the collapsed island appeared unresponsive.
        .modifier(PillGestures(viewModel: viewModel, enabled: viewModel.isActive))
        .onTapGesture {
            // The running pill is a label, not a button; without this a click
            // on the countdown does nothing at all.
            if viewModel.isActive { viewModel.expandIsland() }
        }
    }

    // MARK: - Expanded State Content

    private var expandedContent: some View {
        VStack(spacing: 14) {
            if viewModel.showPermissionWarning {
                PermissionWarningBanner(viewModel: viewModel)
            }

            // Header row: action picker, live clock, appearance + window controls
            HStack(spacing: 10) {
                PowerDropdown(viewModel: viewModel)

                Spacer(minLength: 8)

                if !viewModel.isActive {
                    CurrentTimeDisplay(theme: viewModel.currentTheme)
                    Spacer(minLength: 8)
                }

                ThemeToggle(viewModel: viewModel)

                AboutCircleButton(theme: viewModel.currentTheme) {
                    viewModel.showAboutPage()
                }

                MinimizeButton(theme: viewModel.currentTheme) {
                    viewModel.collapseIsland()
                }
            }

            // Main content area
            if viewModel.isShowingSuggestion {
                suggestionView
            } else if viewModel.isActive {
                CountdownDisplay(viewModel: viewModel)
            } else {
                TimerSelectionView(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private var suggestionView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "battery.25")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                    .symbolEffect(.pulse, options: .repeating)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Low Battery Detected")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.textColor)
                    Text(viewModel.suggestionMessage)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                }

                Spacer()
            }
            .padding(12)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(12)

            HStack(spacing: 8) {
                ModernButton(title: "Dismiss", color: .gray, isSelected: false) {
                    viewModel.dismissSuggestion()
                }

                ModernButton(title: "Shutdown in 5m", color: .green, isSelected: true) {
                    viewModel.dismissSuggestion()
                    viewModel.startTimer(minutes: 5, action: .shutdown)
                }
            }
        }
    }

    // MARK: - Helper Properties

    /// Per-state geometry, sized for what the island is currently showing.
    private var currentFrameSize: CGSize {
        MorphingGeometry.calculateFrame(
            for: viewModel.islandState,
            content: MorphingGeometry.ContentContext(
                isTimerActive: viewModel.isActive,
                isShowingSuggestion: viewModel.isShowingSuggestion,
                isShowingCustomInput: viewModel.showingCustomInput,
                showsPermissionWarning: viewModel.showPermissionWarning
            )
        )
    }
}

// MARK: - Content Transition

/// Blur + fade + slight scale from the top: incoming content resolves out of
/// the morph as the shape arrives; outgoing content gets out of the way fast.
private struct IslandContentFade: ViewModifier {
    let isHidden: Bool

    func body(content: Content) -> some View {
        content
            .blur(radius: isHidden ? 8 : 0)
            .opacity(isHidden ? 0 : 1)
            .scaleEffect(isHidden ? 0.94 : 1, anchor: .top)
    }
}

private extension AnyTransition {
    static var islandContent: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: IslandContentFade(isHidden: true), identity: IslandContentFade(isHidden: false))
                .animation(SpringAnimator.contentSwap().delay(0.07)),
            removal: .modifier(active: IslandContentFade(isHidden: true), identity: IslandContentFade(isHidden: false))
                .animation(.easeOut(duration: 0.14))
        )
    }
}

// MARK: - Pill Gestures

/// Swipe right to snooze, swipe left to cancel, long-press to switch action.
///
/// The pill tracks the pointer with rubber-banding and reveals what letting go
/// will do; crossing the threshold gives a trackpad detent. A quick flick
/// counts even if it ends short of the threshold.
///
/// Applied conditionally: when no timer is running the pill hosts a button, and
/// a competing DragGesture would eat its taps.
private struct PillGestures: ViewModifier {
    @ObservedObject var viewModel: TimerViewModel
    let enabled: Bool

    @State private var dragX: CGFloat = 0
    @State private var isArmed = false

    private let threshold: CGFloat = 46

    func body(content: Content) -> some View {
        if enabled {
            content
                .offset(x: rubberBanded(dragX))
                .overlay(alignment: .leading) {
                    hint(systemImage: "goforward.plus", color: .blue, reveal: dragX)
                        .padding(.leading, 10)
                }
                .overlay(alignment: .trailing) {
                    hint(systemImage: "xmark", color: .red, reveal: -dragX)
                        .padding(.trailing, 10)
                }
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            dragX = value.translation.width
                            let armed = abs(dragX) > threshold
                            if armed != isArmed {
                                isArmed = armed
                                if armed { Haptics.detent() }
                            }
                        }
                        .onEnded { value in
                            let x = value.translation.width
                            let flick = value.predictedEndTranslation.width

                            if x > threshold || flick > threshold * 3 {
                                Haptics.confirm()
                                viewModel.snoozeTimer()
                            } else if x < -threshold || flick < -threshold * 3 {
                                Haptics.confirm()
                                viewModel.cancelTimer()
                            }

                            isArmed = false
                            withAnimation(.spring(duration: 0.45, bounce: 0.35)) { dragX = 0 }
                        }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.6)
                        .onEnded { _ in
                            Haptics.confirm()
                            viewModel.togglePrimaryAction()
                        }
                )
        } else {
            content
        }
    }

    /// Follows the pointer 1:1 at first, then resists — the same feel as
    /// overscrolling a list.
    private func rubberBanded(_ x: CGFloat) -> CGFloat {
        let limit: CGFloat = 64
        let magnitude = limit * (1 - exp(-abs(x) / limit))
        return x < 0 ? -magnitude : magnitude
    }

    private func hint(systemImage: String, color: Color, reveal: CGFloat) -> some View {
        let progress = min(1, max(0, reveal / threshold))
        return Image(systemName: systemImage)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 22, height: 22)
            .background(Circle().fill(color))
            .scaleEffect(0.5 + 0.5 * progress * (isArmed ? 1.12 : 1))
            .opacity(progress)
            .allowsHitTesting(false)
            .animation(SpringAnimator.hover(), value: isArmed)
    }
}

// MARK: - Modern Background Component

struct ModernIslandBackground: View {
    let state: IslandState
    let urgency: UrgencyLevel
    let theme: AppTheme

    var body: some View {
        ZStack {
            // Drop shadow layer
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.1))
                .shadow(color: .black.opacity(theme == .dark ? 0.4 : 0.22), radius: 30, x: 0, y: 15)
                .shadow(color: .black.opacity(theme == .dark ? 0.2 : 0.12), radius: 10, x: 0, y: 5)

            // Frosted base. The material sits *under* the theme tint so light
            // mode stays genuinely light — previously the material was layered
            // on top of the white fill and greyed the whole panel out, which is
            // what made light-mode text so hard to read.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.backgroundColor,
                            theme.backgroundColor.opacity(0.97),
                            theme.backgroundColor.opacity(0.93)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle specular sheen
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: theme == .dark
                            ? [.white.opacity(0.10), .clear, .black.opacity(0.05)]
                            : [.white.opacity(0.55), .clear, .black.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Border stroke
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.borderColor.opacity(0.7),
                            theme.borderColor.opacity(0.3),
                            theme.borderColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            // Urgency glow: breathes in the last minute, pulses in the last ten
            // seconds. The loop lives in its own phase animator so it can never
            // leak into the rest of the island the way a repeatForever did.
            if urgency != .normal {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(urgencyGlowColor, lineWidth: 2)
                    .blur(radius: 6)
                    .phaseAnimator([0.35, 1.0]) { glow, phase in
                        glow.opacity(urgencyGlowOpacity * phase)
                    } animation: { _ in
                        .easeInOut(duration: urgency == .critical ? 0.45 : 1.3)
                    }
                    .allowsHitTesting(false)
            }
        }
    }

    private var cornerRadius: Double {
        MorphingGeometry.cornerRadius(for: state)
    }

    private var urgencyGlowColor: Color {
        switch urgency {
        case .normal:   return .clear
        case .warning:  return .orange
        case .critical: return .red
        }
    }

    private var urgencyGlowOpacity: Double {
        switch urgency {
        case .normal:   return 0
        case .warning:  return 0.55
        case .critical: return 0.9
        }
    }
}

// MARK: - Power Dropdown Component

struct PowerDropdown: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        Group {
            // While a countdown is running the action is fixed, so show a plain
            // chip rather than a menu dimmed to 50% — which just looked broken.
            if viewModel.isActive {
                label(for: viewModel.scheduledAction ?? viewModel.currentPowerAction,
                      showsChevron: false)
            } else {
                Menu {
                    ForEach(PowerAction.allCases) { action in
                        Button {
                            viewModel.currentPowerAction = action
                        } label: {
                            Label(action.displayName, systemImage: action.iconName)
                        }
                    }
                } label: {
                    label(for: viewModel.currentPowerAction, showsChevron: true)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .menuIndicator(.hidden)
                .fixedSize()
            }
        }
        // The chip is applied *outside* the Menu. macOS strips background and
        // padding from a Menu's label, so styling it inline left this control
        // looking unstyled next to the theme toggle beside it.
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(viewModel.currentTheme.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(viewModel.currentTheme.borderColor, lineWidth: 1)
                )
        )
        .fixedSize()
    }

    @ViewBuilder
    private func label(for action: PowerAction, showsChevron: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: action.iconName)
                .font(.system(size: 11, weight: .medium))

            Text(action.displayName)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .fixedSize()

            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
        }
        .foregroundColor(viewModel.currentTheme.textColor)
    }
}

// MARK: - Theme Toggle Component

struct ThemeToggle: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        Button {
            viewModel.toggleTheme()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.currentTheme == .dark ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 11, weight: .medium))
                Text(viewModel.currentTheme == .dark ? "Dark" : "Light")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .fixedSize()
            }
            .foregroundColor(viewModel.currentTheme.textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(viewModel.currentTheme.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(viewModel.currentTheme.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .help("Switch between light and dark appearance")
    }
}

// MARK: - Timer Selection View

struct TimerSelectionView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.showingCustomInput {
                CustomTimeInputView(viewModel: viewModel)
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        presetButton(title: "5m", minutes: 5, color: .green)
                        presetButton(title: "10m", minutes: 10, color: .yellow)
                        presetButton(title: "30m", minutes: 30, color: .orange)
                        presetButton(title: "1h", minutes: 60, color: .purple)

                        ModernButton(
                            title: "Custom",
                            color: .blue,
                            isSelected: viewModel.showingCustomInput
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.showingCustomInput = true
                            }
                        }
                    }

                    Button {
                        guard let mins = viewModel.selectedPresetMinutes else { return }
                        viewModel.startTimer(minutes: mins, action: viewModel.currentPowerAction)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.currentPowerAction.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(startButtonTitle)
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.green, .green.opacity(0.82)],
                                                     startPoint: .top, endPoint: .bottom))
                                .shadow(color: .green.opacity(0.35), radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(viewModel.selectedPresetMinutes == nil)
                    .opacity(viewModel.selectedPresetMinutes == nil ? 0.5 : 1)
                }
            }
        }
    }

    private var startButtonTitle: String {
        guard let mins = viewModel.selectedPresetMinutes else { return "Start Timer" }
        let label = mins >= 60 ? "\(Int(mins / 60))h" : "\(Int(mins))m"
        return "\(viewModel.currentPowerAction.displayName) in \(label)"
    }

    @ViewBuilder
    private func presetButton(title: String, minutes: Double, color: Color) -> some View {
        ModernButton(
            title: title,
            color: color,
            isSelected: viewModel.selectedPresetMinutes == minutes && !viewModel.showingCustomInput
        ) {
            withAnimation(SpringAnimator.buttonSelection()) {
                viewModel.selectedPresetMinutes = minutes
                viewModel.showingCustomInput = false
            }
        }
    }
}

// MARK: - Current Time Display Component

struct CurrentTimeDisplay: View {
    let theme: AppTheme

    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 12, weight: .medium))

            Text(Self.formatter.string(from: currentTime))
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                .fixedSize()
        }
        .foregroundColor(theme.accentBlue)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.blue.opacity(theme == .dark ? 0.14 : 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .onReceive(timer) { currentTime = $0 }
    }
}

// MARK: - Tappable Countdown Starter

/// The idle pill. Tapping opens the full interface.
///
/// It used to start a five-minute shutdown on a single click with no
/// confirmation and no way to see what it was about to do — one stray click on
/// the notch and the Mac was on its way down.
struct TappableCountdownStarter: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var isHovered = false

    var body: some View {
        Button {
            viewModel.expandIsland()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.currentPowerAction.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.accentBlue)

                Text("Schedule \(viewModel.currentPowerAction.displayName)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(viewModel.currentTheme.textColor)
                    .fixedSize()

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.secondaryTextColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(viewModel.currentTheme.secondaryBackground.opacity(isHovered ? 1.8 : 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(viewModel.currentTheme.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(SpringAnimator.hover(), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Custom Time Input View

struct CustomTimeInputView: View {
    @ObservedObject var viewModel: TimerViewModel

    @State private var hours: Int = 0
    @State private var minutes: Int = 5
    @State private var seconds: Int = 0

    private var totalMinutes: Double {
        Double(hours * 60 + minutes) + Double(seconds) / 60.0
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                picker(title: "Hours", selection: $hours, range: 0..<24)
                picker(title: "Minutes", selection: $minutes, range: 0..<60)
                picker(title: "Seconds", selection: $seconds, range: 0..<60)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(viewModel.currentTheme.secondaryBackground.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(viewModel.currentTheme.borderColor.opacity(0.5), lineWidth: 1)
                    )
            )

            HStack(spacing: 8) {
                // Drives the shared action rather than a private @State copy —
                // the old local picker silently ignored (and disagreed with)
                // the action chosen in the header dropdown.
                Picker("Action", selection: $viewModel.currentPowerAction) {
                    ForEach(PowerAction.allCases) { action in
                        Text(action.displayName).tag(action)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 130)

                Spacer(minLength: 4)

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.showingCustomInput = false
                    }
                } label: {
                    Text("Back")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(viewModel.currentTheme.borderColor, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())

                Button {
                    viewModel.startTimer(minutes: totalMinutes, action: viewModel.currentPowerAction)
                } label: {
                    Text("Start Timer")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.green)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                // A zero-length timer would fire instantly; block it rather
                // than silently doing nothing on click.
                .disabled(totalMinutes <= 0)
                .opacity(totalMinutes <= 0 ? 0.5 : 1)
            }
        }
    }

    @ViewBuilder
    private func picker(title: String, selection: Binding<Int>, range: Range<Int>) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.currentTheme.secondaryTextColor)

            Picker("", selection: selection) {
                ForEach(range, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 68)
        }
    }
}

// MARK: - About View Component

struct AboutView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var haloRotation: Double = 0

    private var theme: AppTheme { viewModel.currentTheme }

    var body: some View {
        VStack(spacing: 14) {
            header

            profileCard

            VStack(spacing: 6) {
                Toggle("Show Countdown in Menu Bar", isOn: $viewModel.showCountdownInMenuBar)
                Toggle("Alert Sounds", isOn: $viewModel.soundAlertsEnabled)
                Toggle("Start at Login", isOn: $viewModel.startAtLogin)
                Toggle("Show Dock Icon", isOn: $viewModel.showInDock)
            }
            .toggleStyle(LiquidGlassToggleStyle(theme: theme))

            if !viewModel.updateStatusMessage.isEmpty {
                Text(viewModel.updateStatusMessage)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(theme.secondaryTextColor)
                    .transition(.opacity)
            }

            actionButtons
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private var header: some View {
        ZStack {
            Text("About")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(theme.textColor)

            HStack {
                Button {
                    viewModel.returnFromAboutPage()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                        Text("Back")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(theme.accentBlue)
                    .padding(.vertical, 6)
                    .padding(.trailing, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
            }
        }
    }

    private var profileCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(colors: [.blue, .purple, .cyan, .blue], center: .center),
                        lineWidth: 3
                    )
                    .frame(width: 82, height: 82)
                    .rotationEffect(.degrees(haloRotation))
                    .blur(radius: 2)

                if let profileImage = Self.profileImage {
                    Image(nsImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 76, height: 76)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(theme.borderColor, lineWidth: 1))
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 76, height: 76)
                        .foregroundColor(theme.accentBlue)
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                }
            }
            .onAppear {
                // Guarded so re-entering the About page does not stack another
                // repeatForever animation on top of the running one.
                guard haloRotation == 0 else { return }
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    haloRotation = 360
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("festomanolo")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textColor)

                Text("Lead Designer & Engineer")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(theme.secondaryTextColor)

                Text("NotchDown \(UpdateChecker.currentVersion)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accentBlue.opacity(0.15))
                    .foregroundColor(theme.accentBlue)
                    .cornerRadius(8)
            }

            Spacer(minLength: 0)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            if let url = viewModel.availableUpdateURL {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    capsuleLabel(
                        text: "Download Update",
                        systemImage: "arrow.down.circle",
                        showsProgress: false,
                        tint: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button {
                    viewModel.handleCheckForUpdates()
                } label: {
                    capsuleLabel(
                        text: viewModel.isCheckingForUpdates ? "Checking…" : "Check Updates",
                        systemImage: "arrow.clockwise.circle",
                        showsProgress: viewModel.isCheckingForUpdates,
                        tint: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isCheckingForUpdates)
            }

            Button {
                viewModel.runDiagnostics()
            } label: {
                capsuleLabel(
                    text: "Diagnostics",
                    systemImage: "stethoscope",
                    showsProgress: false,
                    tint: .green
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    @ViewBuilder
    private func capsuleLabel(text: String, systemImage: String, showsProgress: Bool, tint: Color) -> some View {
        HStack(spacing: 7) {
            if showsProgress {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(LinearGradient(colors: [tint, tint.opacity(0.72)], startPoint: .top, endPoint: .bottom))
                .shadow(color: tint.opacity(0.3), radius: 5, x: 0, y: 3)
        )
    }

    /// Resolved once — `NSImage(named:)` plus a bundle probe on every render is
    /// wasteful for an asset that cannot change at runtime.
    private static let profileImage: NSImage? = {
        if let image = NSImage(named: "festomanolo") { return image }
        if let path = Bundle.main.path(forResource: "festomanolo", ofType: "jpeg") {
            return NSImage(contentsOfFile: path)
        }
        return nil
    }()
}

// MARK: - About Circle Button

struct AboutCircleButton: View {
    let theme: AppTheme
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "info")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(theme.accentBlue)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(isHovered ? 0.28 : 0.16))
                        .overlay(Circle().stroke(Color.blue.opacity(0.45), lineWidth: 1))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .help("About NotchDown")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) { isHovered = hovering }
        }
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// MARK: - Liquid Glass Toggle Style

/// Theme-aware toggle.
///
/// Every colour here used to be a hardcoded white — label, knob, track and row
/// background — so on the light theme the text and the switch both disappeared
/// into the panel.
struct LiquidGlassToggleStyle: ToggleStyle {
    let theme: AppTheme

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textColor)

            Spacer(minLength: 8)

            ZStack {
                Capsule()
                    .fill(configuration.isOn
                          ? AnyShapeStyle(theme.accentBlue.opacity(0.9))
                          : AnyShapeStyle(theme.secondaryBackground))
                    .frame(width: 42, height: 22)
                    .overlay(
                        Capsule()
                            .stroke(configuration.isOn ? Color.clear : theme.borderColor, lineWidth: 1)
                    )

                Circle()
                    .fill(Color.white)
                    .frame(width: 17, height: 17)
                    .shadow(color: .black.opacity(0.28), radius: 2, y: 1)
                    .offset(x: configuration.isOn ? 9.5 : -9.5)
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: configuration.isOn)
            .contentShape(Capsule())
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.secondaryBackground.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(theme.borderColor.opacity(0.5), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Permission Warning Banner

struct PermissionWarningBanner: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 1) {
                Text("Permissions Required")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(viewModel.currentTheme.textColor)
                Text("Grant automation access in System Settings")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(viewModel.currentTheme.secondaryTextColor)
            }

            Spacer(minLength: 4)

            Button {
                PowerManager.shared.openAutomationSettings()
            } label: {
                Text("Open Settings")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.orange))
            }
            .buttonStyle(PlainButtonStyle())

            Button {
                withAnimation { viewModel.showPermissionWarning = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(viewModel.currentTheme.secondaryTextColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
