//
//  DynamicIslandView.swift
//  NotchDown
//
//  Modern Dynamic Island interface with macOS/iOS 26 style design
//  Features glassmorphism, outlined buttons with glowing effects, and minimalist layout
//

import SwiftUI
import Combine

/// Main Dynamic Island interface component with modern design
struct DynamicIslandView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                ZStack {
                    // Modern glassmorphism background
                    ModernIslandBackground(
                        state: viewModel.islandState,
                        urgency: viewModel.urgencyLevel,
                        theme: viewModel.currentTheme
                    )
                    
                    // Content layer with modern layout
                    contentLayer
                        .opacity(contentOpacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.islandState)
                }
                .frame(
                    width: currentFrameSize.width,
                    height: currentFrameSize.height
                )
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .animation(SpringAnimator.morphToExpanded(), value: viewModel.islandState)
        }
        .frame(maxWidth: .infinity)
        .frame(height: currentFrameSize.height)
    }
    
    // MARK: - Content Layer
    
    @ViewBuilder
    private var contentLayer: some View {
        switch viewModel.islandState {
        case .collapsed, .collapsing:
            collapsedContent
            
        case .expanding:
            expandingContent
            
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
                    .layoutPriority(1)
            } else {
                // Show tappable countdown starter
                TappableCountdownStarter(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .frame(width: 450, height: 40) // Fixed size for absolute stability
        .contentShape(Rectangle()) // Make entire area gesture-sensitive
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe Right -> Snooze
                        viewModel.snoozeTimer()
                    } else if value.translation.width < -50 {
                        // Swipe Left -> Cancel
                        viewModel.cancelTimer()
                    }
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.8)
                .onEnded { _ in
                    // Long Press -> Toggle Mode
                    viewModel.togglePrimaryAction()
                }
        )
    }
    
    // MARK: - Expanding State Content
    
    private var expandingContent: some View {
        HStack {
            Text("Power Timer")
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundColor(viewModel.currentTheme.textColor)
            
            Spacer()
            
            if viewModel.isActive {
                CompactCountdownDisplay(viewModel: viewModel)
            } else {
                CurrentTimeDisplay()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
    
    // MARK: - Expanded State Content
    
    private var expandedContent: some View {
        VStack(spacing: 16) {
            // Top row: Controls, time display, and minimize button
            HStack {
                // Power dropdown
                PowerDropdown(viewModel: viewModel)
                
                Spacer()
                
                // Current time or timer display
                if viewModel.isActive {
                    // Show timer countdown
                    CompactCountdownDisplay(viewModel: viewModel)
                } else {
                    // Show current time
                    CurrentTimeDisplay()
                }
                
                Spacer()
                
                // Theme toggle
                ThemeToggle(viewModel: viewModel)
                
                HStack(spacing: 8) {
                    // About button (Exclamation mark)
                    AboutCircleButton {
                        viewModel.showAboutPage()
                    }
                    
                    // Minimize button
                    MinimizeButton {
                        viewModel.collapseIsland()
                    }
                }
            }
            
            // Main content area
            if viewModel.isShowingSuggestion {
                suggestionView
            } else if viewModel.isActive {
                ActiveTimerView(viewModel: viewModel)
            } else {
                TimerSelectionView(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
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
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            HStack(spacing: 8) {
                ModernButton(title: "Dismiss", color: .gray, isSelected: false) {
                    viewModel.dismissSuggestion()
                }
                
                ModernButton(title: "Shutdown in 5m", color: .green, isSelected: true) {
                    viewModel.isShowingSuggestion = false
                    viewModel.startTimer(minutes: 5, action: .shutdown)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var currentFrameSize: CGSize {
        MorphingGeometry.calculateFrame(for: viewModel.islandState)
    }
    
    private var contentOpacity: Double {
        switch viewModel.islandState {
        case .collapsed:
            return 1.0
        case .expanding:
            return 0.7
        case .expanded, .critical, .about:
            return 1.0
        case .collapsing:
            return 0.5
        }
    }
}

// MARK: - Modern Background Component

struct ModernIslandBackground: View {
    let state: IslandState
    let urgency: UrgencyLevel
    let theme: AppTheme
    
    var body: some View {
        ZStack {
            // Base shadow layer (multi-layered for depth)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.1))
                .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // Main background with gradient
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.backgroundColor,
                            theme.backgroundColor.opacity(0.95),
                            theme.backgroundColor.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Material layer for glass effect
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    // Subtle light reflection
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear, .black.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                )
            
            // Border stroke
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            theme.borderColor.opacity(0.5),
                            theme.borderColor.opacity(0.2),
                            theme.borderColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            // Urgency glow effect
            if urgency != .normal {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(urgencyGlowColor, lineWidth: 2)
                    .blur(radius: 6)
                    .opacity(urgencyGlowOpacity)
            }
        }
    }
    
    private var cornerRadius: Double {
        switch state {
        case .collapsed, .collapsing:
            return 16
        case .expanding:
            return 18
        case .expanded, .critical:
            return 20
        case .about:
            return 24
        }
    }
    
    private var urgencyGlowColor: Color {
        switch urgency {
        case .normal:
            return .clear
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
    
    private var urgencyGlowOpacity: Double {
        switch urgency {
        case .normal:
            return 0
        case .warning:
            return 0.4
        case .critical:
            return 0.7
        }
    }
}

// MARK: - Power Dropdown Component

struct PowerDropdown: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var isExpanded = false
    
    var body: some View {
        Menu {
            Button(action: {
                viewModel.startTimer(minutes: 5, action: .shutdown)
            }) {
                Label("Shutdown", systemImage: "power")
            }
            
            Button(action: {
                viewModel.startTimer(minutes: 5, action: .restart)
            }) {
                Label("Restart", systemImage: "arrow.clockwise")
            }
            
            Button(action: {
                viewModel.startTimer(minutes: 5, action: .sleep)
            }) {
                Label("Sleep", systemImage: "moon.fill")
            }
            
            Button(action: {
                viewModel.startTimer(minutes: 5, action: .logout)
            }) {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .medium))
                Text("Power")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
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
        .menuStyle(BorderlessButtonMenuStyle())
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
            }
            .foregroundColor(viewModel.currentTheme.textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.currentTheme.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.currentTheme.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Timer Selection View

struct TimerSelectionView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    private let timerOptions: [(TimeOption, String, Color)] = [
        (.custom, "Custom", .blue),
        (.fiveMinutes, "5m", .green),
        (.tenMinutes, "10m", .yellow),
        (.thirtyMinutes, "30m", .orange),
        (.custom, "1h", .purple) // Using .custom as a placeholder for 60m if needed, or I'll just use the minutes below
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            if viewModel.showingCustomInput {
                // Custom time input UI
                CustomTimeInputView(viewModel: viewModel)
            } else {
                HStack(spacing: 8) {
                    // Presets group on the left
                    HStack(spacing: 6) {
                        presetButton(title: "5m", minutes: 5, color: .green)
                        presetButton(title: "10m", minutes: 10, color: .yellow)
                        presetButton(title: "30m", minutes: 30, color: .orange)
                        presetButton(title: "1h", minutes: 60, color: .purple)
                        
                        // Custom toggle
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
                    
                    Spacer()
                    
                    // Main Start Button for presets on the right
                    Button(action: {
                        if let mins = viewModel.selectedPresetMinutes {
                            viewModel.startTimer(minutes: mins, action: viewModel.currentPowerAction)
                        }
                    }) {
                        Text("Start Timer")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    private func presetButton(title: String, minutes: Double, color: Color) -> some View {
        ModernButton(
            title: title,
            color: color,
            isSelected: viewModel.selectedPresetMinutes == minutes && !viewModel.showingCustomInput
        ) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                viewModel.selectedPresetMinutes = minutes
                viewModel.showingCustomInput = false
            }
        }
    }
}

// MARK: - Active Timer View

struct ActiveTimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Large countdown display
            VStack(spacing: 4) {
                Text("Time Remaining")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                
                Text(viewModel.timeString)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(urgencyColor)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.timeRemaining)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(urgencyColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(urgencyColor.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Cancel button
            ModernButton(
                title: "Cancel Timer",
                color: .red,
                isSelected: false
            ) {
                viewModel.cancelTimer()
            }
        }
    }
    
    private var urgencyColor: Color {
        switch viewModel.urgencyLevel {
        case .normal:
            return viewModel.currentTheme.accentBlue
        case .warning:
            return viewModel.currentTheme.accentOrange
        case .critical:
            return .red
        }
    }
}

// MARK: - Current Time Display Component

struct CurrentTimeDisplay: View {
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
            
            Text(timeString)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .onReceive(timer) { input in
            currentTime = input
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
}

// MARK: - Tappable Countdown Starter

struct TappableCountdownStarter: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var displayTime: TimeInterval = 300 // Default 5 minutes
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            // Start countdown immediately when tapped
            viewModel.startTimer(minutes: displayTime / 60, action: viewModel.currentPowerAction)
        }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.currentPowerAction.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.currentPowerAction == .shutdown ? viewModel.currentTheme.accentBlue : .purple)
                
                Text(formatTime(displayTime))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(viewModel.currentTheme.textColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(viewModel.currentTheme.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(viewModel.currentTheme.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Custom Time Input View

struct CustomTimeInputView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var hours: Int = 0
    @State private var minutes: Int = 5
    @State private var seconds: Int = 0
    @State private var selectedAction: PowerAction = .shutdown
    
    var body: some View {
        VStack(spacing: 12) {
            // Time input row
            HStack(spacing: 16) {
                // Hours picker
                VStack(spacing: 4) {
                    Text("Hours")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                    
                    Picker("", selection: $hours) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 65)
                }
                
                // Minutes picker
                VStack(spacing: 4) {
                    Text("Minutes")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                    
                    Picker("", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 65)
                }
                
                // Seconds picker
                VStack(spacing: 4) {
                    Text("Seconds")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                    
                    Picker("", selection: $seconds) {
                        ForEach(0..<60, id: \.self) { second in
                            Text("\(second)").tag(second)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 65)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(viewModel.currentTheme.secondaryBackground.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(viewModel.currentTheme.borderColor.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Action selection row
            HStack(spacing: 8) {
                // Action picker
                Picker("Action", selection: $selectedAction) {
                    Text("Shutdown").tag(PowerAction.shutdown)
                    Text("Restart").tag(PowerAction.restart)
                    Text("Sleep").tag(PowerAction.sleep)
                    Text("Log Out").tag(PowerAction.logout)
                }
                .pickerStyle(.menu)
                .frame(width: 145) // Slightly more width just in case
                
                Spacer()
                
                // Back button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.showingCustomInput = false
                    }
                }) {
                    Text("Back")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(viewModel.currentTheme.borderColor, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Start button
                Button(action: {
                    let totalMinutes = Double(hours * 60 + minutes) + Double(seconds) / 60.0
                    if totalMinutes > 0 {
                        viewModel.startTimer(minutes: totalMinutes, action: selectedAction)
                    }
                }) {
                    Text("Start Timer")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.green)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - About View Component

struct AboutView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var haloRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with Back Button
            HStack {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        viewModel.islandState = .expanded
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Back")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(viewModel.currentTheme.accentBlue)
                    .contentShape(Rectangle()) // Explicit hit testing area
                    .padding(.vertical, 8)
                    .padding(.trailing, 16)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("About")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(viewModel.currentTheme.textColor)
                
                Spacer()
                
                // Spacer to balance the back button
                Text("Back").opacity(0)
            }
            
            HStack(spacing: 20) {
                // Profile Photo with Godmode Halo
                ZStack {
                    // Glowing Halo
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [.blue, .purple, .cyan, .blue],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(haloRotation))
                        .blur(radius: 2)
                        .onAppear {
                            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                                haloRotation = 360
                            }
                        }
                    
                    // Profile Image
                    Image(nsImage: NSImage(contentsOfFile: "/Users/festomanolo/Desktop/projects/notch-down/notch-down/Assets.xcassets/festomanolo.jpeg") ?? NSImage())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("festomanolo")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.textColor)
                    
                    Text("Lead Designer & Engineer")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                    
                    Text("NotchDown v1.0.0")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(viewModel.currentTheme.accentBlue.opacity(0.15))
                        .foregroundColor(viewModel.currentTheme.accentBlue)
                        .cornerRadius(8)
                }
            }
            
            VStack(spacing: 8) {
                // System Settings Toggles
                VStack(spacing: 8) {
                    Toggle("Show Countdown in Menu Bar", isOn: $viewModel.showCountdownInMenuBar)
                        .toggleStyle(LiquidGlassToggleStyle())
                        
                    Toggle("Start at Login", isOn: $viewModel.startAtLogin)
                        .toggleStyle(LiquidGlassToggleStyle())
                    
                    Toggle("Show Dock Icon", isOn: $viewModel.showInDock)
                        .toggleStyle(LiquidGlassToggleStyle())
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                
                if !viewModel.updateStatusMessage.isEmpty {
                    Text(viewModel.updateStatusMessage)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(viewModel.currentTheme.secondaryTextColor)
                        .transition(.opacity)
                }
                
                Button {
                    viewModel.handleCheckForUpdates()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isCheckingForUpdates {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise.circle")
                        }
                        Text(viewModel.isCheckingForUpdates ? "Checking..." : "Check for Updates")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isCheckingForUpdates)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - About Circle Button

struct AboutCircleButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "exclamationmark")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(isHovered ? 0.3 : 0.2))
                        .overlay(
                            Circle()
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
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

// MARK: - iOS 26 Liquid Glass Toggle Style

struct LiquidGlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            ZStack {
                // Outer Track
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 24)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Active Glow
                if configuration.isOn {
                    Capsule()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: 44, height: 24)
                        .blur(radius: 6)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                
                // The Liquid Knob
                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: configuration.isOn ? .blue.opacity(0.6) : .black.opacity(0.3), 
                            radius: configuration.isOn ? 8 : 3)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0), 
                               value: configuration.isOn)
            }
            .onTapGesture {
                withAnimation {
                    configuration.isOn.toggle()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                )
        )
    }
}

struct LiquidToggle: View {
    @Binding var isOn: Bool
    let label: String
    
    var body: some View {
        Toggle(label, isOn: $isOn)
            .toggleStyle(LiquidGlassToggleStyle())
    }
}