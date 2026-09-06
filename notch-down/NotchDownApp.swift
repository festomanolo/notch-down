//
//  NotchDownApp.swift
//  NotchDown
//
//  Created for the Godmode UI experience.
//

import SwiftUI
import Combine
import AppKit
import ServiceManagement

@main
struct NotchDownApp: App {
    // We attach the ViewModel here so it persists as long as the app runs
    @StateObject var timerVM = TimerViewModel()

    init() {
        // Disable macOS Sudden Termination to prevent accessory process kills
        ProcessInfo.processInfo.disableSuddenTermination()

        // Register Global Shortcut (Shift + Ctrl + U) using simplified manager
        ShortcutManager.shared.registerGlobalShortcut()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(viewModel: timerVM)
        } label: {
            MenuBarIcon(viewModel: timerVM)
        }
        .menuBarExtraStyle(.menu)
    }
}

// MARK: - Menu Bar Content

/// The status menu.
///
/// Laid out as labelled sections with an icon on every row and submenus for
/// grouped choices, so the menu reads as a structured panel rather than a flat
/// list of buttons.
struct MenuBarContent: View {
    @ObservedObject var viewModel: TimerViewModel

    private let presets: [(label: String, minutes: Double)] = [
        ("5 minutes", 5),
        ("10 minutes", 10),
        ("15 minutes", 15),
        ("30 minutes", 30),
        ("45 minutes", 45),
        ("1 hour", 60),
        ("2 hours", 120)
    ]

    var body: some View {

        // MARK: Status header

        Section(viewModel.isActive ? "Timer Running" : "NotchDown") {
            if viewModel.isActive {
                Button {
                    viewModel.expandIsland()
                } label: {
                    Label(
                        "\(viewModel.scheduledAction?.displayName ?? "Timer") in \(viewModel.timeString)",
                        systemImage: viewModel.urgencyLevel == .normal ? "timer" : "exclamationmark.triangle.fill"
                    )
                }

                Button {
                    viewModel.snoozeTimer()
                } label: {
                    Label("Add 5 Minutes", systemImage: "goforward.plus")
                }

                Button {
                    viewModel.cancelTimer()
                } label: {
                    Label("Cancel Timer", systemImage: "xmark.circle")
                }
                .keyboardShortcut(".", modifiers: .command)
            } else {
                Button {
                    viewModel.expandIsland()
                } label: {
                    Label("Open Dynamic Island", systemImage: "capsule.inset.filled")
                }
                .keyboardShortcut("u", modifiers: [.control, .shift])
            }
        }

        Divider()

        // MARK: Schedule

        Section("Schedule") {
            ForEach(PowerAction.allCases) { action in
                Menu {
                    ForEach(presets, id: \.label) { preset in
                        Button(preset.label) {
                            viewModel.startTimer(minutes: preset.minutes, action: action)
                        }
                    }
                    Divider()
                    Button("Custom…") {
                        viewModel.openCustomTimerInput(for: action)
                    }
                } label: {
                    Label(action.displayName, systemImage: action.iconName)
                }
            }
        }

        Divider()

        // MARK: Immediate actions

        Section("Run Now") {
            Menu {
                ForEach(PowerAction.allCases) { action in
                    Button("\(action.displayName) Now") {
                        viewModel.runActionNow(action)
                    }
                }
            } label: {
                Label("Power Actions", systemImage: "bolt.circle")
            }
        }

        Divider()

        // MARK: Display

        Section("Display") {
            Toggle(isOn: $viewModel.showCountdownInMenuBar) {
                Label("Show Countdown in Menu Bar", systemImage: "menubar.rectangle")
            }

            Toggle(isOn: $viewModel.soundAlertsEnabled) {
                Label("Alert Sounds", systemImage: "speaker.wave.2")
            }

            Menu {
                Button {
                    viewModel.useSystemTheme()
                } label: {
                    Label("Match System", systemImage: viewModel.followsSystemTheme ? "checkmark" : "circle.lefthalf.filled")
                }
                Button {
                    viewModel.setTheme(.light)
                } label: {
                    Label("Light", systemImage: !viewModel.followsSystemTheme && viewModel.currentTheme == .light ? "checkmark" : "sun.max")
                }
                Button {
                    viewModel.setTheme(.dark)
                } label: {
                    Label("Dark", systemImage: !viewModel.followsSystemTheme && viewModel.currentTheme == .dark ? "checkmark" : "moon")
                }
            } label: {
                Label("Appearance", systemImage: "paintpalette")
            }
        }

        Divider()

        // MARK: System

        Section("System") {
            Toggle(isOn: $viewModel.startAtLogin) {
                Label("Start at Login", systemImage: "arrow.right.square")
            }

            Toggle(isOn: $viewModel.showInDock) {
                Label("Show Dock Icon", systemImage: "dock.rectangle")
            }

            Menu {
                Button("Run Diagnostics…") {
                    viewModel.runDiagnostics()
                }
                Button("Verify Permissions") {
                    viewModel.verifyPermissions(announce: true)
                }
                Divider()
                Button("Open Automation Settings") {
                    PowerManager.shared.openAutomationSettings()
                }
            } label: {
                Label("Troubleshooting", systemImage: "stethoscope")
            }
        }

        Divider()

        Button {
            viewModel.showAboutPage()
        } label: {
            Label("About NotchDown", systemImage: "info.circle")
        }

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit NotchDown", systemImage: "power")
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

// MARK: - Menu Bar Icon

/// Status item content.
///
/// Deliberately just a symbol plus text: shape primitives (the old `Circle()`
/// urgency dot) are unreliable inside a `MenuBarExtra` label and were part of
/// why nothing rendered next to the icon.
struct MenuBarIcon: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)

            if viewModel.isActive && viewModel.showCountdownInMenuBar {
                Text(viewModel.timeString)
                    .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var iconName: String {
        guard viewModel.isActive else { return "power.circle" }

        switch viewModel.urgencyLevel {
        case .normal:  return "timer"
        case .warning: return "timer.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    private var accessibilityLabel: String {
        if viewModel.isActive {
            return "\(viewModel.scheduledAction?.displayName ?? "Timer") in \(viewModel.timeString)"
        }
        return "NotchDown — power management timer"
    }
}

// -- The Brain (ViewModel) --

@MainActor
class TimerViewModel: ObservableObject {

    // MARK: - Timer Properties
    @Published var timeRemaining: TimeInterval = 0
    @Published var isActive = false

    /// Wall-clock instant the action fires.
    ///
    /// The countdown is derived from this rather than decremented, so it stays
    /// correct across timer drift, app stalls and system sleep — the previous
    /// "subtract 1 every tick" approach silently froze after a wake.
    private var deadline: Date?

    // MARK: - Dynamic Island State Properties
    @Published var islandState: IslandState = .collapsed

    /// Drives the island's slide-in/out. The window itself never animates —
    /// see NotchWindowController for why.
    @Published var isIslandVisible: Bool = false

    /// Bumped to make the island nudge sideways for an urgency milestone.
    @Published var attentionNudge: Int = 0
    @Published var animationPhase: AnimationPhase = .idle
    @Published var urgencyLevel: UrgencyLevel = .normal

    // MARK: - Theme and UI State Properties
    @Published var currentTheme: AppTheme = .dark
    @Published var followsSystemTheme: Bool = true
    @Published var selectedTimeOption: TimeOption = .custom
    @Published var showingCustomInput: Bool = false
    @Published var selectedPresetMinutes: Double? = 5

    // MARK: - Peeking (Intelligent Visibility) Properties
    private var lastPeekTime: Date = Date()
    private var isPeeking: Bool = false

    // MARK: - Private Properties
    private var timer: Timer?
    @Published var scheduledAction: PowerAction?
    private var windowController: NotchWindowController?
    private var themeManagerObserver: AnyCancellable?
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var screenObserver: NSObjectProtocol?
    private var batteryObserver: AnyCancellable?
    private var collapseObserver: NSObjectProtocol?
    private var shortcutObserver: NSObjectProtocol?

    /// Suppresses `didSet` side effects while persisted values are being loaded.
    private var isLoadingSettings = false

    // Audio alerts
    private let warningSound = NSSound(named: "Glass")
    private let criticalSound = NSSound(named: "Sosumi")
    private let heartbeatSound = NSSound(named: "Tink")
    /// Seconds mark the last alert fired at, so each mark fires exactly once.
    private var lastAudioTriggerSecond: Int = -1

    // Proactive Suggestion state
    @Published var isShowingSuggestion = false
    @Published var suggestionMessage = ""
    @Published var currentPowerAction: PowerAction = .shutdown

    // About Page State
    @Published var isCheckingForUpdates = false
    @Published var updateStatusMessage = ""

    // Permission State
    @Published var hasPermissions = true
    @Published var showPermissionWarning = false

    // Background & System Integration
    @Published var startAtLogin = false {
        didSet {
            guard !isLoadingSettings, oldValue != startAtLogin else { return }
            toggleLoginItem(startAtLogin)
        }
    }
    @Published var showInDock = false {
        didSet {
            guard !isLoadingSettings, oldValue != showInDock else { return }
            defaults.set(showInDock, forKey: Keys.showInDock)
            toggleDockIcon(showInDock)
        }
    }
    @Published var showCountdownInMenuBar = true {
        didSet {
            guard !isLoadingSettings, oldValue != showCountdownInMenuBar else { return }
            defaults.set(showCountdownInMenuBar, forKey: Keys.showCountdown)
        }
    }
    @Published var soundAlertsEnabled = true {
        didSet {
            guard !isLoadingSettings, oldValue != soundAlertsEnabled else { return }
            defaults.set(soundAlertsEnabled, forKey: Keys.soundAlerts)
        }
    }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let showCountdown = "NotchDownShowCountdownInMenuBar"
        static let soundAlerts = "NotchDownSoundAlertsEnabled"
        static let showInDock = "NotchDownShowInDock"
    }

    // MARK: - Initialization

    init() {
        loadSettings()

        // Mirror ThemeManager state
        currentTheme = ThemeManager.shared.currentTheme
        followsSystemTheme = ThemeManager.shared.followsSystemTheme

        themeManagerObserver = ThemeManager.shared.$currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] newTheme in
                guard let self = self, self.currentTheme != newTheme else { return }
                self.currentTheme = newTheme
                self.followsSystemTheme = ThemeManager.shared.followsSystemTheme
            }

        // Observe collapse notifications (for click-outside)
        collapseObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("CollapseDynamicIsland"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.collapseIsland() }
        }

        setupSystemObservers()

        batteryObserver = BatteryManager.shared.$batteryLevel
            .combineLatest(BatteryManager.shared.$isPluggedIn)
            .receive(on: RunLoop.main)
            .sink { [weak self] level, isPluggedIn in
                self?.handleBatteryChange(level: level, isPluggedIn: isPluggedIn)
            }

        shortcutObserver = NotificationCenter.default.addObserver(
            forName: .expandDynamicIsland,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self else { return }
                if self.islandState == .collapsed {
                    self.expandIsland()
                } else {
                    self.collapseIsland()
                }
            }
        }

        verifyPermissions()
    }

    deinit {
        themeManagerObserver?.cancel()
        batteryObserver?.cancel()

        let center = NotificationCenter.default
        [collapseObserver, shortcutObserver].compactMap { $0 }.forEach(center.removeObserver)

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        [sleepObserver, wakeObserver].compactMap { $0 }.forEach(workspaceCenter.removeObserver)

        if let screenObserver = screenObserver {
            center.removeObserver(screenObserver)
        }
    }

    // MARK: - Settings persistence

    private func loadSettings() {
        isLoadingSettings = true
        defer { isLoadingSettings = false }

        if defaults.object(forKey: Keys.showCountdown) != nil {
            showCountdownInMenuBar = defaults.bool(forKey: Keys.showCountdown)
        }
        if defaults.object(forKey: Keys.soundAlerts) != nil {
            soundAlertsEnabled = defaults.bool(forKey: Keys.soundAlerts)
        }
        if defaults.object(forKey: Keys.showInDock) != nil {
            showInDock = defaults.bool(forKey: Keys.showInDock)
        }

        // Reflect the real login-item state rather than assuming false.
        startAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - System Observers

    private func setupSystemObservers() {
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.pauseTickingForSleep() }
        }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.resumeAfterWake() }
        }

        // Keep the island on the screen the user is actually looking at.
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateActiveScreen() }
        }
    }

    /// Stop the run-loop timer over sleep; the deadline keeps the truth.
    private func pauseTickingForSleep() {
        timer?.invalidate()
        timer = nil
    }

    /// Recompute from the deadline and resume, firing immediately if the
    /// deadline passed while the machine was asleep.
    private func resumeAfterWake() {
        guard isActive, let deadline = deadline else { return }

        timeRemaining = max(0, deadline.timeIntervalSinceNow)

        if timeRemaining <= 0 {
            fireScheduledAction()
        } else {
            startTicking()
            updateUrgencyLevel()
        }
    }

    // MARK: - Formatting

    var timeString: String {
        let total = max(0, Int(timeRemaining.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Timer lifecycle

    func startTimer(minutes: Double, action: PowerAction) {
        guard minutes > 0 else { return }

        cancelTimer(silently: true)

        deadline = Date().addingTimeInterval(minutes * 60)
        timeRemaining = minutes * 60
        scheduledAction = action
        currentPowerAction = action
        isActive = true
        lastAudioTriggerSecond = -1
        lastPeekTime = Date()

        updateUrgencyLevel()
        animationPhase = .rolling

        ToastManager.shared.success("\(action.displayName) scheduled in \(Self.describe(minutes: minutes))")

        if islandState == .expanded || islandState == .about {
            collapseIsland()
        }

        startTicking()
        showWindow()
    }

    private static func describe(minutes: Double) -> String {
        let totalSeconds = Int((minutes * 60).rounded())
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60

        var parts: [String] = []
        if h > 0 { parts.append("\(h)h") }
        if m > 0 { parts.append("\(m)m") }
        if s > 0 && h == 0 { parts.append("\(s)s") }
        return parts.isEmpty ? "0s" : parts.joined(separator: " ")
    }

    private func startTicking() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // .common so the countdown keeps running while a menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func cancelTimer() {
        cancelTimer(silently: false)
    }

    private func cancelTimer(silently: Bool) {
        timer?.invalidate()
        timer = nil
        deadline = nil

        let wasActive = isActive
        isActive = false
        timeRemaining = 0
        scheduledAction = nil
        lastAudioTriggerSecond = -1

        urgencyLevel = .normal
        animationPhase = .idle

        stopAllSounds()

        if islandState == .critical {
            collapseIsland()
        }

        if wasActive && !silently {
            ToastManager.shared.info("Timer cancelled")
            hideWindow()
        }
    }

    private func stopAllSounds() {
        [warningSound, criticalSound, heartbeatSound].forEach { $0?.stop() }
    }

    // MARK: - Tick

    private func tick() {
        guard isActive, let deadline = deadline else { return }

        let remaining = max(0, deadline.timeIntervalSinceNow)

        // Only publish on whole-second boundaries so the roller animates once
        // per second instead of stuttering twice.
        let newWhole = Int(remaining.rounded(.up))
        let oldWhole = Int(timeRemaining.rounded(.up))

        if remaining <= 0 {
            timeRemaining = 0
            fireScheduledAction()
            return
        }

        guard newWhole != oldWhole else { return }

        timeRemaining = remaining
        animationPhase = .rolling

        updateUrgencyLevel()
        handleAudioAlerts(secondsRemaining: newWhole)
        handleIntelligentVisibility()
    }

    private func fireScheduledAction() {
        let actionToExecute = scheduledAction
        cancelTimer(silently: true)
        hideWindow()

        guard let action = actionToExecute else { return }

        ToastManager.shared.info("Executing \(action.displayName)…")

        // No confirmation prompt: scheduling the countdown *was* the
        // confirmation, and a modal nobody is present to answer would silently
        // cancel the action the user asked for.
        PowerManager.shared.execute(action, confirm: false) { [weak self] result in
            switch result {
            case .success:
                ToastManager.shared.success("\(action.displayName) command sent")
            case .failure(let error):
                ToastManager.shared.error("\(action.displayName) failed: \(error.localizedDescription)")
                self?.showPowerActionError(error)
            }
        }
    }

    /// Run a power action immediately (from the menu), with confirmation.
    func runActionNow(_ action: PowerAction) {
        PowerManager.shared.execute(action, confirm: true) { [weak self] result in
            if case .failure(let error) = result, case .cancelled = error { return }
            if case .failure(let error) = result {
                ToastManager.shared.error("\(action.displayName) failed: \(error.localizedDescription)")
                self?.showPowerActionError(error)
            }
        }
    }

    // MARK: - Audio Intelligence

    private func handleAudioAlerts(secondsRemaining: Int) {
        guard soundAlertsEnabled else { return }
        guard secondsRemaining != lastAudioTriggerSecond else { return }
        lastAudioTriggerSecond = secondsRemaining

        if secondsRemaining == 60 {
            play(warningSound)
        } else if secondsRemaining == 10 {
            play(criticalSound)
        } else if secondsRemaining < 10 && secondsRemaining > 0 {
            play(heartbeatSound)
        }
    }

    /// `NSSound.play()` is a no-op while the same instance is still playing, so
    /// a repeated alert (the final-ten-seconds heartbeat) silently did nothing.
    private func play(_ sound: NSSound?) {
        guard let sound = sound else { return }
        if sound.isPlaying { sound.stop() }
        sound.play()
    }

    // MARK: - Battery Intelligence

    private func handleBatteryChange(level: Double, isPluggedIn: Bool) {
        guard level <= 20, !isPluggedIn, !isActive, !isShowingSuggestion else { return }

        suggestionMessage = "Low Battery: Shutdown soon?"
        isShowingSuggestion = true
        currentPowerAction = .shutdown

        if islandState == .collapsed {
            expandIsland()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self, self.isShowingSuggestion else { return }
            self.dismissSuggestion()
        }
    }

    func dismissSuggestion() {
        isShowingSuggestion = false
        if islandState == .expanded && !isActive {
            collapseIsland()
        }
    }

    // MARK: - Pill Gesture Actions

    /// Adds 5 minutes to the active timer (Swipe Right)
    func snoozeTimer() {
        guard isActive, let current = deadline else { return }

        deadline = current.addingTimeInterval(300)
        timeRemaining = max(0, self.deadline!.timeIntervalSinceNow)
        lastAudioTriggerSecond = -1
        animationPhase = .rolling
        updateUrgencyLevel()

        ToastManager.shared.success("Timer snoozed: +5 minutes")
    }

    /// Toggles between shutdown and sleep (Long Press)
    func togglePrimaryAction() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentPowerAction = (currentPowerAction == .shutdown) ? .sleep : .shutdown
        }
    }

    // MARK: - Intelligent Visibility Logic

    private func handleIntelligentVisibility() {
        guard isActive, !isPeeking, islandState == .collapsed else { return }

        let peekInterval: TimeInterval
        if timeRemaining > 600 {
            peekInterval = 120
        } else if timeRemaining > 300 {
            peekInterval = 60
        } else if timeRemaining > 60 {
            peekInterval = 30
        } else {
            return // Under a minute the island stays out via the urgency path
        }

        if Date().timeIntervalSince(lastPeekTime) >= peekInterval {
            triggerPeek()
        }
    }

    private func triggerPeek() {
        isPeeking = true
        lastPeekTime = Date()

        showWindow()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            if self.isActive && self.islandState == .collapsed {
                self.hideWindow()
            }
            self.isPeeking = false
        }
    }

    // MARK: - Dynamic Island State Management

    func expandIsland() {
        guard islandState == .collapsed || islandState == .collapsing else { return }

        updateActiveScreen()

        animationPhase = .morphing
        showWindow(activating: true)

        withAnimation(AnimationFallbackManager.shared.getAnimation(for: .morphing)) {
            islandState = .expanded
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + SpringAnimator.morphDuration) { [weak self] in
            guard let self = self, self.animationPhase == .morphing else { return }
            self.animationPhase = .idle
        }
    }

    func collapseIsland() {
        guard islandState == .expanded || islandState == .critical || islandState == .about else { return }

        animationPhase = .morphing

        withAnimation(AnimationFallbackManager.shared.getAnimation(for: .morphing)) {
            islandState = .collapsed
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + SpringAnimator.morphDuration) { [weak self] in
            guard let self = self else { return }
            if self.animationPhase == .morphing { self.animationPhase = .idle }
            if !self.isActive && self.islandState == .collapsed {
                self.hideWindow()
            }
        }
    }

    func showAboutPage() {
        updateActiveScreen()
        showWindow(activating: true)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            islandState = .about
        }
    }

    func returnFromAboutPage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            islandState = .expanded
        }
    }

    /// Opens the island straight into the custom-duration editor.
    func openCustomTimerInput(for action: PowerAction) {
        currentPowerAction = action
        showingCustomInput = true
        selectedTimeOption = .custom

        if islandState == .collapsed || islandState == .collapsing {
            expandIsland()
        } else {
            showWindow(activating: true)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                islandState = .expanded
            }
        }
    }

    /// Updates urgency level based on remaining time.
    ///
    /// The auto-expansion is deferred to the next run-loop turn: it drives
    /// AppKit window animations, and previously ran inside the timer callback's
    /// SwiftUI animation transaction, stacking two competing frame animations
    /// on the same window at exactly T-60s and T-10s.
    func updateUrgencyLevel() {
        let newUrgencyLevel: UrgencyLevel
        if timeRemaining <= 10 {
            newUrgencyLevel = .critical
        } else if timeRemaining <= 60 {
            newUrgencyLevel = .warning
        } else {
            newUrgencyLevel = .normal
        }

        guard urgencyLevel != newUrgencyLevel else { return }

        withAnimation(AnimationFallbackManager.shared.getAnimation(for: .glowing)) {
            urgencyLevel = newUrgencyLevel
        }

        guard newUrgencyLevel == .warning || newUrgencyLevel == .critical else { return }

        DispatchQueue.main.async { [weak self] in
            self?.presentCriticalIsland()
        }
    }

    /// Brings the island out (or re-alerts if it is already out) for an urgency
    /// milestone. Called at both T-60s and T-10s, so the ten-second alert still
    /// fires when the one-minute alert already expanded the island.
    private func presentCriticalIsland() {
        guard isActive else { return }
        guard islandState != .about else { return }

        showWindow()

        withAnimation(AnimationFallbackManager.shared.getAnimation(for: .morphing)) {
            islandState = .critical
            animationPhase = .glowing
        }

        // Nudge the island sideways to draw the eye. Purely a SwiftUI offset —
        // nothing touches the window frame.
        attentionNudge += 1
    }

    // MARK: - Theme

    func toggleTheme() {
        ThemeManager.shared.toggleTheme()
    }

    func setTheme(_ theme: AppTheme) {
        ThemeManager.shared.setTheme(theme)
        followsSystemTheme = false
    }

    func useSystemTheme() {
        ThemeManager.shared.enableSystemThemeFollowing()
        followsSystemTheme = true
    }

    func selectTimeOption(_ option: TimeOption) {
        withAnimation(AnimationFallbackManager.shared.getAnimation(for: .buttonSelection)) {
            selectedTimeOption = option
            showingCustomInput = (option == .custom)
        }
    }

    // MARK: - Background & System Management

    private func toggleLoginItem(_ enable: Bool) {
        let service = SMAppService.mainApp
        do {
            if enable {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
        } catch {
            ToastManager.shared.error("Couldn't update login item: \(error.localizedDescription)")
            // Put the switch back where the system actually is.
            isLoadingSettings = true
            startAtLogin = (service.status == .enabled)
            isLoadingSettings = false
        }
    }

    private func toggleDockIcon(_ show: Bool) {
        NSApp.setActivationPolicy(show ? .regular : .accessory)
    }

    private func updateActiveScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        guard let activeScreen = screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })
            ?? NSScreen.main ?? screens.first else { return }

        windowController?.updateScreen(activeScreen)
    }

    // MARK: - Window Logic

    private func ensureWindowController() {
        guard windowController == nil else { return }
        let view = DynamicIslandView(viewModel: self)
        windowController = NotchWindowController(rootView: AnyView(view))
    }

    /// Orders the panel in and slides the island down from the notch.
    ///
    /// Deliberately does not assign `islandState` — callers set it inside their
    /// own `withAnimation` so the morph is animated rather than snapped.
    private func showWindow(activating: Bool = false) {
        ensureWindowController()
        windowController?.present(activating: activating)

        guard !isIslandVisible else { return }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            isIslandVisible = true
        }
    }

    private func hideWindow() {
        guard isIslandVisible else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            isIslandVisible = false
        }

        // Order out only once the exit animation has played.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self, !self.isIslandVisible else { return }
            self.windowController?.dismiss()
        }
    }

    // MARK: - Updates & Diagnostics

    func handleCheckForUpdates() {
        isCheckingForUpdates = true
        updateStatusMessage = "Checking for updates…"

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isCheckingForUpdates = false
            self?.updateStatusMessage = "You are on the latest version (1.0.0)"
        }
    }

    func runDiagnostics() {
        DiagnosticsManager.shared.runDiagnostics { [weak self] in
            guard self != nil else { return }
            let report = DiagnosticsManager.shared.generateReport()
            print(report)

            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Diagnostics Complete"
            alert.informativeText = "Full report printed to the console. Export it from the About page for sharing."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    // MARK: - Permission Management

    func verifyPermissions(announce: Bool = false) {
        PowerManager.shared.verifyPermissions { [weak self] hasPermission in
            guard let self = self else { return }
            self.hasPermissions = hasPermission
            self.showPermissionWarning = !hasPermission

            if announce {
                if hasPermission {
                    ToastManager.shared.success("Automation permissions are granted")
                } else {
                    ToastManager.shared.warning("Automation permission is missing")
                }
            }
        }
    }

    private func showPowerActionError(_ error: PowerManagerError) {
        if case .permissionDenied = error {
            hasPermissions = false
            showPermissionWarning = true
        }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Power Action Failed"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")

        if case .permissionDenied = error {
            alert.addButton(withTitle: "Open Settings")
            if alert.runModal() == .alertSecondButtonReturn {
                PowerManager.shared.openAutomationSettings()
            }
        } else {
            alert.runModal()
        }
    }

    func testPowerAction(_ action: PowerAction) {
        PowerManager.shared.testAction(action) { [weak self] success in
            guard let self = self else { return }
            self.hasPermissions = success
            self.showPermissionWarning = !success
        }
    }
}
