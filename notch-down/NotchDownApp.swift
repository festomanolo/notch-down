//
//  NotchDownApp.swift
//  NotchDown
//
//  Created for the Godmode UI experience.
//

import SwiftUI
import Combine
import AppKit

@main
struct NotchDownApp: App {
    // We attach the ViewModel here so it persists as long as the app runs
    @StateObject var timerVM = TimerViewModel()
    
    init() {
        // Register Global Shortcut (Shift + Ctrl + U) using simplified manager
        ShortcutManager.shared.registerGlobalShortcut()
    }
    
    var body: some Scene {
        // "MenuBarExtra" creates the icon in the top right status bar
        // Enhanced with visual state indicators
        MenuBarExtra {
            // Menu content with state-aware display
            MenuBarContent(viewModel: timerVM)
        } label: {
            // Dynamic menu bar icon with state indicators
            MenuBarIcon(viewModel: timerVM)
        }
    }
}

// MARK: - Menu Bar Content

struct MenuBarContent: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        // Quick timer actions
        Button("Shutdown in 5 min") { 
            viewModel.startTimer(minutes: 5, action: .shutdown) 
        }
        Button("Shutdown in 15 min") { 
            viewModel.startTimer(minutes: 15, action: .shutdown) 
        }
        Button("Restart in 5 min") { 
            viewModel.startTimer(minutes: 5, action: .restart) 
        }
        
        Divider()
        
        // Timer status display
        if viewModel.isActive {
            HStack {
                Text("Timer Active")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(viewModel.timeString)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(urgencyColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            
            Button("Cancel Timer") {
                viewModel.cancelTimer()
            }
        } else {
            Button("Open Dynamic Island") {
                viewModel.expandIsland()
            }
        }
        
        Divider()
        
        // Theme toggle
        Button(viewModel.currentTheme == .dark ? "Switch to Light Theme" : "Switch to Dark Theme") {
            viewModel.toggleTheme()
        }
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private var urgencyColor: Color {
        switch viewModel.urgencyLevel {
        case .normal:
            return .primary
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

// MARK: - Menu Bar Icon

struct MenuBarIcon: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        HStack(spacing: 4) {
            // Main icon with state indicator
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 16, weight: .medium))
            
            // Urgency indicator dot (when timer is active)
            if viewModel.isActive {
                Circle()
                    .fill(urgencyColor)
                    .frame(width: 6, height: 6)
                    .opacity(viewModel.urgencyLevel == .critical ? 1.0 : 0.7)
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    private var iconName: String {
        if viewModel.isActive {
            switch viewModel.urgencyLevel {
            case .normal:
                return "timer"
            case .warning:
                return "timer.square"
            case .critical:
                return "exclamationmark.triangle.fill"
            }
        }
        return "power.circle"
    }
    
    private var iconColor: Color {
        if viewModel.isActive {
            switch viewModel.urgencyLevel {
            case .normal:
                return .blue
            case .warning:
                return .orange
            case .critical:
                return .red
            }
        }
        return .primary
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
    
    private var accessibilityLabel: String {
        if viewModel.isActive {
            return "Timer active, \(viewModel.timeString) remaining"
        }
        return "NotchDown - Power management timer"
    }
    
    private var accessibilityHint: String {
        if viewModel.isActive {
            return "Click to open Dynamic Island interface"
        }
        return "Click to open menu"
    }
}

// -- The Brain (ViewModel) --
class TimerViewModel: ObservableObject {
    // MARK: - Existing Timer Properties
    @Published var timeRemaining: TimeInterval = 0
    @Published var isActive = false
    
    // MARK: - Dynamic Island State Properties
    @Published var islandState: IslandState = .collapsed
    @Published var animationPhase: AnimationPhase = .idle
    @Published var urgencyLevel: UrgencyLevel = .normal
    
    // MARK: - Theme and UI State Properties
    @Published var currentTheme: AppTheme = .dark {
        didSet {
            // Sync with ThemeManager
            if ThemeManager.shared.currentTheme != currentTheme {
                ThemeManager.shared.setTheme(currentTheme)
            }
        }
    }
    @Published var selectedTimeOption: TimeOption = .custom
    @Published var showingCustomInput: Bool = false
    @Published var selectedPresetMinutes: Double? = 5 // Track selected preset before start
    
    // MARK: - Peeking (Intelligent Visibility) Properties
    private var lastPeekTime: Date = Date()
    private var isPeeking: Bool = false
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var scheduledAction: PowerAction?
    private var windowController: NotchWindowController?
    private var themeManagerObserver: AnyCancellable?
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var batteryObserver: AnyCancellable?
    
    // Audio alerts
    private let warningSound = NSSound(named: "Glass")
    private let criticalSound = NSSound(named: "Hero")
    private let heartbeatSound = NSSound(named: "Morse")
    private var lastAudioTriggerTime: Int = 0
    
    // New: Proactive Suggestion state
    @Published var isShowingSuggestion = false
    @Published var suggestionMessage = ""
    @Published var currentPowerAction: PowerAction = .shutdown
    
    // MARK: - Initialization
    
    init() {
        // Initialize theme from ThemeManager
        currentTheme = ThemeManager.shared.currentTheme
        
        // Observe ThemeManager changes
        themeManagerObserver = ThemeManager.shared.$currentTheme
            .sink { [weak self] newTheme in
                if self?.currentTheme != newTheme {
                    self?.currentTheme = newTheme
                }
            }
        
        // Observe collapse notifications (for click-outside)
        NotificationCenter.default.addObserver(
            forName: Notification.Name("CollapseDynamicIsland"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.collapseIsland()
        }
        
        // Setup system sleep/wake observers for timer state preservation
        setupSystemObservers()
        
        // Observe Battery changes
        batteryObserver = BatteryManager.shared.$batteryLevel
            .combineLatest(BatteryManager.shared.$isPluggedIn)
            .sink { [weak self] level, isPluggedIn in
                self?.handleBatteryChange(level: level, isPluggedIn: isPluggedIn)
            }
            
        // Observe Global Shortcut Notification
        NotificationCenter.default.addObserver(
            forName: .expandDynamicIsland,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.islandState == .collapsed {
                self?.expandIsland()
            } else {
                self?.collapseIsland()
            }
        }
    }
    
    deinit {
        themeManagerObserver?.cancel()
        batteryObserver?.cancel()
        removeSystemObservers()
    }
    
    // MARK: - System Observers
    
    private func setupSystemObservers() {
        // Observe system sleep
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Backup timer state before sleep
            if let self = self, self.isActive {
                ErrorHandler.shared.backupTimerState(viewModel: self)
            }
        }
        
        // Observe system wake
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Restore timer state after wake
            if let self = self {
                ErrorHandler.shared.restoreTimerState(viewModel: self)
            }
        }
    }
    
    private func removeSystemObservers() {
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startTimer(minutes: Double, action: PowerAction) {
        cancelTimer() // Reset if currently running
        
        self.timeRemaining = minutes * 60
        self.scheduledAction = action
        self.isActive = true
        
        // Initialize Dynamic Island state
        updateUrgencyLevel()
        animationPhase = .rolling // Start with rolling animation for countdown
        
        // Auto-minimize to pill shape when timer starts
        if islandState == .expanded {
            collapseIsland()
        }
        
        // Start the countdown logic
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
            self?.handleIntelligentVisibility()
        }
        
        // Trigger the UI
        showWindow()
    }
    
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
        
        // Reset Dynamic Island state
        urgencyLevel = .normal
        animationPhase = .idle
        if islandState == .critical {
            collapseIsland()
        }
        
        // Stop all sounds
        warningSound?.stop()
        criticalSound?.stop()
        heartbeatSound?.stop()
        
        hideWindow()
    }
    
    private func tick() {
        if timeRemaining > 0 {
            // Use animation fallback manager for appropriate animation level
            let animation = AnimationFallbackManager.shared.getAnimation(for: .rolling)
            withAnimation(animation) {
                timeRemaining -= 1
            }
            
            // Set rolling animation phase for visual feedback
            animationPhase = .rolling
            
            // Reset animation phase after roll duration
            DispatchQueue.main.asyncAfter(deadline: .now() + SpringAnimator.rollDuration) {
                if self.animationPhase == .rolling {
                    self.animationPhase = .idle
                }
            }
            
            updateUrgencyLevel() // Update urgency based on remaining time
            handleAudioAlerts()
        } else {
            // TIMER FINISHED
            cancelTimer()
            if let action = scheduledAction {
                // Check for system busy state before executing
                if PowerManager.shared.isSystemBusy() {
                    ErrorHandler.shared.handleSystemBusy()
                } else {
                    PowerManager.shared.execute(action)
                }
            }
        }
    }
    
    // MARK: - Audio Intelligence
    
    private func handleAudioAlerts() {
        let remaining = Int(timeRemaining)
        
        // Only trigger once per second mark
        guard remaining != lastAudioTriggerTime else { return }
        lastAudioTriggerTime = remaining
        
        if remaining == 60 {
            warningSound?.play()
        } else if remaining == 10 {
            criticalSound?.play()
        } else if remaining < 10 && remaining > 0 {
            // Heartbeat effect for final 10 seconds
            heartbeatSound?.play()
        }
    }
    
    // MARK: - Battery Intelligence
    
    private func handleBatteryChange(level: Double, isPluggedIn: Bool) {
        // Suggest eco-mode if battery is low and not charging
        if level <= 20 && !isPluggedIn && !isActive && !isShowingSuggestion {
            withAnimation(.spring()) {
                suggestionMessage = "Low Battery: Shutdown soon?"
                isShowingSuggestion = true
                currentPowerAction = .shutdown
            }
            
            // Expand to show suggestion
            if islandState == .collapsed {
                expandIsland()
            }
            
            // Auto-hide suggestion if not acted upon
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if self?.isShowingSuggestion == true {
                    self?.dismissSuggestion()
                }
            }
        }
    }
    
    func dismissSuggestion() {
        withAnimation {
            isShowingSuggestion = false
            if islandState == .expanded && !isActive {
                collapseIsland()
            }
        }
    }
    
    // MARK: - Pill Gesture Actions
    
    /// Adds 5 minutes to the active timer (Swipe Right)
    func snoozeTimer() {
        guard isActive else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            timeRemaining += 300 // 5 minutes
            animationPhase = .rolling
        }
        
        // Brief visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.animationPhase = .idle
        }
    }
    
    /// Toggles between shutdown and sleep (Long Press)
    func togglePrimaryAction() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentPowerAction = (currentPowerAction == .shutdown) ? .sleep : .shutdown
        }
    }
    
    // MARK: - Intelligent Visibility Logic
    
    private func handleIntelligentVisibility() {
        guard isActive && !isPeeking && islandState == .collapsed else { return }
        
        let now = Date()
        let timeSinceLastPeek = now.timeIntervalSince(lastPeekTime)
        let peekInterval: TimeInterval
        
        // Dynamic peek interval based on time remaining
        if timeRemaining > 600 { // > 10 min
            peekInterval = 120 // Every 2 min
        } else if timeRemaining > 300 { // 5-10 min
            peekInterval = 60 // Every 1 min
        } else if timeRemaining > 60 { // 1-5 min
            peekInterval = 30 // Every 30s
        } else {
            return // Under 1 min stays visible via urgency level
        }
        
        if timeSinceLastPeek >= peekInterval {
            triggerPeek()
        }
    }
    
    private func triggerPeek() {
        isPeeking = true
        lastPeekTime = Date()
        
        // Briefly show the window in collapsed state
        showWindow()
        
        // Hide it again after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            if self.isActive && self.islandState == .collapsed {
                self.hideWindow()
            }
            self.isPeeking = false
        }
    }
    
    
    // MARK: - Dynamic Island State Management
    
    /// Expands the Dynamic Island to show full interface using spring physics
    func expandIsland() {
        guard islandState == .collapsed else { return }
        
        animationPhase = .morphing
        islandState = .expanding
        
        // Show the window first
        showWindow()
        
        // Use animation fallback manager for appropriate animation level
        let animation = AnimationFallbackManager.shared.getAnimation(for: .morphing)
        withAnimation(animation) {
            islandState = .expanded
        }
        
        // Update window controller frame with spring animation
        windowController?.updateWindowFrame(for: .expanded, animated: true)
        
        // Reset animation phase after morph duration
        DispatchQueue.main.asyncAfter(deadline: .now() + SpringAnimator.morphDuration) {
            if self.animationPhase == .morphing {
                self.animationPhase = .idle
            }
        }
    }
    
    /// Collapses the Dynamic Island to pill shape using spring physics
    func collapseIsland() {
        guard islandState == .expanded || islandState == .critical else { return }
        
        animationPhase = .morphing
        islandState = .collapsing
        
        // Use animation fallback manager for appropriate animation level
        let animation = AnimationFallbackManager.shared.getAnimation(for: .morphing)
        withAnimation(animation) {
            islandState = .collapsed
        }
        
        // Update window controller frame with spring animation
        windowController?.updateWindowFrame(for: .collapsed, animated: true)
        
        // Reset animation phase after collapse animation
        DispatchQueue.main.asyncAfter(deadline: .now() + (SpringAnimator.morphDuration * 0.8)) {
            if self.animationPhase == .morphing {
                self.animationPhase = .idle
            }
        }
        
        // Hide the window after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + SpringAnimator.morphDuration) {
            self.hideWindow()
        }
    }
    
    /// Updates urgency level based on remaining time with spring animations
    /// Implements auto-expansion for critical states (Requirements 3.5, 5.4)
    func updateUrgencyLevel() {
        let newUrgencyLevel: UrgencyLevel
        
        // Determine urgency level based on time thresholds
        if timeRemaining <= 10 {
            newUrgencyLevel = .critical      // T-minus 10 seconds
        } else if timeRemaining <= 60 {
            newUrgencyLevel = .warning       // T-minus 1 minute
        } else {
            newUrgencyLevel = .normal        // > 1 minute remaining
        }
        
        // Only update if urgency level changed to prevent redundant animations
        if urgencyLevel != newUrgencyLevel {
            // Use animation fallback manager for appropriate animation level
            let animation = AnimationFallbackManager.shared.getAnimation(for: .glowing)
            withAnimation(animation) {
                urgencyLevel = newUrgencyLevel
            }
            
            // Auto-expand for critical states (T-minus 1 minute or 10 seconds)
            // Requirements 3.5: "WHEN timer reaches T-minus 1 minute or 10 seconds, 
            // THE Dynamic_Island SHALL auto-expand with critical pop-up"
            if (newUrgencyLevel == .warning || newUrgencyLevel == .critical) && 
               (islandState == .collapsed || islandState == .collapsing) {
                
                // Ensure window controller is available for critical expansion
                if windowController == nil {
                    // Create window controller if not already available
                    let view = DynamicIslandView(viewModel: self)
                    windowController = NotchWindowController(rootView: AnyView(view))
                }
                
                // Use animation fallback manager for appropriate animation level
                let animation = AnimationFallbackManager.shared.getAnimation(for: .morphing)
                withAnimation(animation) {
                    islandState = .critical
                    animationPhase = .glowing // Set glowing phase for critical urgency
                }
                
                // Ensure window is visible before triggering expansion
                if let windowController = windowController, windowController.window?.isVisible == false {
                    windowController.show()
                }
                
                // Trigger critical expansion animation on window controller
                windowController?.handleCriticalExpansion()
                
                // Update window frame to critical size
                windowController?.updateWindowFrame(for: .critical, animated: true)
            }
        }
    }
    
    /// Toggles between dark and light themes with smooth animation
    func toggleTheme() {
        // Use ThemeManager for theme switching
        ThemeManager.shared.toggleTheme()
        // ThemeManager will update currentTheme through observer
    }
    
    /// Selects a time option and updates UI state with button animation
    func selectTimeOption(_ option: TimeOption) {
        // Use animation fallback manager for appropriate animation level
        let animation = AnimationFallbackManager.shared.getAnimation(for: .buttonSelection)
        withAnimation(animation) {
            selectedTimeOption = option
            showingCustomInput = (option == .custom)
        }
    }
    
    // -- Window Logic Helper --
    private func showWindow() {
        // Create the window controller only once if possible
        if windowController == nil {
            let view = DynamicIslandView(viewModel: self)
            windowController = NotchWindowController(rootView: AnyView(view))
        }
        windowController?.show()
    }
    
    private func hideWindow() {
        windowController?.hide()
    }
}
