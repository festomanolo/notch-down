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
    private var systemThemeObserver: NSKeyValueObservation?
    
    // MARK: - Initialization
    
    private init() {
        loadThemePreference()
        setupSystemThemeObserver()
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
        let match = NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        return match == .darkAqua ? .dark : .light
    }
    
    // MARK: - System Theme Observer
    
    /// Sets up observer for system theme changes.
    ///
    /// Observes the app's effective appearance rather than the
    /// `AppleInterfaceThemeChangedNotification` distributed notification: that
    /// one is delivered before `effectiveAppearance` updates, so reading it
    /// there picked up the *old* theme.
    private func setupSystemThemeObserver() {
        systemThemeObserver = NSApplication.shared.observe(\.effectiveAppearance) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self = self, self.followsSystemTheme else { return }
                self.updateFromSystemTheme()
            }
        }
    }
    
    // MARK: - Persistence
    
    /// Saves theme preference to UserDefaults
    private func saveThemePreference() {
        userDefaults.set(currentTheme == .dark ? "dark" : "light", forKey: themeKey)
        userDefaults.set(followsSystemTheme, forKey: followsSystemKey)
    }
    
    /// Loads theme preference from UserDefaults.
    ///
    /// Both values are read *before* either is assigned: each property's
    /// `didSet` saves both, so assigning `followsSystemTheme` first overwrote
    /// the stored theme with the default and the chosen theme never survived
    /// a relaunch.
    private func loadThemePreference() {
        let storedFollows = userDefaults.object(forKey: followsSystemKey) as? Bool
        let storedTheme = userDefaults.string(forKey: themeKey)

        if let storedTheme = storedTheme {
            currentTheme = storedTheme == "dark" ? .dark : .light
        } else {
            currentTheme = detectSystemTheme()
        }

        // Assigning this also applies the system theme when following it.
        followsSystemTheme = storedFollows ?? true
    }
}
