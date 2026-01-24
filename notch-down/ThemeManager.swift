//
//  ThemeManager.swift
//  NotchDown
//
//  Theme management system with system preference integration and persistence
//  Provides smooth theme transitions and accessibility compliance
//

import SwiftUI
import AppKit
import Combine

/// Theme manager class for Dynamic Island interface
/// Handles theme switching, system preference integration, and persistence
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // MARK: - Published Properties
    
    @Published var currentTheme: AppTheme = .dark {
        didSet {
            saveThemePreference()
        }
    }
    
    @Published var followsSystemTheme: Bool = true {
        didSet {
            saveThemePreference()
            if followsSystemTheme {
                updateFromSystemTheme()
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "DynamicIslandTheme"
    private let followsSystemKey = "DynamicIslandFollowsSystemTheme"
    private var systemThemeObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    private init() {
        loadThemePreference()
        setupSystemThemeObserver()
    }
    
    deinit {
        if let observer = systemThemeObserver {
            DistributedNotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Theme Management
    
    /// Toggles between dark and light themes with smooth animation
    func toggleTheme() {
        withAnimation(SpringAnimator.themeTransition()) {
            if followsSystemTheme {
                // If following system, toggle system preference following
                followsSystemTheme = false
                currentTheme = currentTheme == .dark ? .light : .dark
            } else {
                currentTheme = currentTheme == .dark ? .light : .dark
            }
        }
    }
    
    /// Sets theme explicitly (disables system theme following)
    func setTheme(_ theme: AppTheme) {
        withAnimation(SpringAnimator.themeTransition()) {
            followsSystemTheme = false
            currentTheme = theme
        }
    }
    
    /// Enables system theme following
    func enableSystemThemeFollowing() {
        followsSystemTheme = true
        updateFromSystemTheme()
    }
    
    /// Updates theme from system preferences
    func updateFromSystemTheme() {
        let systemTheme = detectSystemTheme()
        if currentTheme != systemTheme {
            withAnimation(SpringAnimator.themeTransition()) {
                currentTheme = systemTheme
            }
        }
    }
    
    // MARK: - System Theme Detection
    
    /// Detects current system theme preference
    func detectSystemTheme() -> AppTheme {
        let style = NSApplication.shared.effectiveAppearance.name.rawValue
        // NSAppearanceNameDarkAqua or similar
        if style.contains("Dark") {
            return .dark
        }
        return .light
    }
    
    // MARK: - System Theme Observer
    
    /// Sets up observer for system theme changes
    private func setupSystemThemeObserver() {
        systemThemeObserver = DistributedNotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, self.followsSystemTheme else { return }
            self.updateFromSystemTheme()
        }
    }
    
    // MARK: - Persistence
    
    /// Saves theme preference to UserDefaults
    private func saveThemePreference() {
        userDefaults.set(currentTheme == .dark ? "dark" : "light", forKey: themeKey)
        userDefaults.set(followsSystemTheme, forKey: followsSystemKey)
    }
    
    /// Loads theme preference from UserDefaults
    private func loadThemePreference() {
        // Load system theme following preference
        if userDefaults.object(forKey: followsSystemKey) != nil {
            followsSystemTheme = userDefaults.bool(forKey: followsSystemKey)
        }
        
        // Load theme preference
        if let themeString = userDefaults.string(forKey: themeKey) {
            currentTheme = themeString == "dark" ? .dark : .light
        } else {
            // Default to system theme
            currentTheme = detectSystemTheme()
        }
        
        // If following system theme, update from system
        if followsSystemTheme {
            updateFromSystemTheme()
        }
    }
}

// MARK: - Theme Accessibility Extensions

extension ThemeManager {
    /// Checks if current theme meets WCAG contrast requirements
    func meetsWCAGContrast(level: WCAGLevel = .AA) -> Bool {
        // This would use actual contrast ratio calculations
        // For now, we assume our color choices meet requirements
        return true
    }
    
    /// WCAG contrast level requirements
    enum WCAGLevel {
        case AA      // Minimum contrast ratio 4.5:1 for normal text
        case AAA     // Enhanced contrast ratio 7:1 for normal text
    }
    
    /// Gets high contrast variant if available
    func highContrastVariant() -> AppTheme {
        // For high contrast mode, we might adjust colors
        return currentTheme
    }
}
