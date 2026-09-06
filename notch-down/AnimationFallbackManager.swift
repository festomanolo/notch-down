//
//  AnimationFallbackManager.swift
//  NotchDown
//
//  Animation fallback hierarchy for graceful degradation based on performance and accessibility
//

import SwiftUI
import AppKit
import Combine
import QuartzCore

/// Animation fallback manager for performance and accessibility
/// Provides graceful degradation from full animations to static displays
class AnimationFallbackManager: ObservableObject {
    static let shared = AnimationFallbackManager()
    
    // MARK: - Published Properties
    
    @Published var animationLevel: AnimationLevel = .full
    @Published var currentFrameRate: Double = 60.0
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    
    // MARK: - Animation Levels
    
    enum AnimationLevel {
        case full        // All animations enabled
        case reduced     // Reduced animations (fewer effects)
        case minimal     // Minimal animations (essential only)
        case staticDisplay  // No animations (static display)
    }
    
    // MARK: - Performance Thresholds
    
    private let targetFrameRate: Double = 55.0   // Minimum acceptable frame rate
    private let maxCPUUsage: Double = 80.0       // Maximum CPU usage (% of one core)
    private let maxMemoryUsage: Double = 600.0   // Maximum resident memory (MB)
    
    // MARK: - Private Properties
    
    private var performanceMonitor: Timer?
    private var frameRateMonitor: CADisplayLink?
    
    // MARK: - Initialization
    
    private init() {
        updateAnimationLevel()
        startPerformanceMonitoring()
    }
    
    deinit {
        stopPerformanceMonitoring()
    }
    
    // MARK: - Animation Level Management
    
    /// Updates animation level based on performance and accessibility.
    func updateAnimationLevel() {
        // Honour the system setting first — it is the only signal here that
        // reflects an actual user preference.
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            setLevel(.minimal)
            return
        }

        let struggling = currentFrameRate < targetFrameRate
            || cpuUsage > maxCPUUsage
            || memoryUsage > maxMemoryUsage

        guard struggling else {
            // Recover a step at a time rather than snapping straight to full.
            switch animationLevel {
            case .staticDisplay: setLevel(.minimal)
            case .minimal:       setLevel(.reduced)
            case .reduced:       setLevel(.full)
            case .full:          break
            }
            return
        }

        // Degrade one step, but never below `.reduced` on a metrics signal:
        // the old code walked all the way to `.staticDisplay` after three bad
        // samples and never came back within a session, killing every animation
        // in the app.
        switch animationLevel {
        case .full:    setLevel(.reduced)
        case .reduced: setLevel(.minimal)
        default:       break
        }
    }

    /// Assigns only on an actual change, so the publisher does not fire every second.
    private func setLevel(_ level: AnimationLevel) {
        guard animationLevel != level else { return }
        animationLevel = level
    }
    
    /// Gets appropriate animation for current level
    func getAnimation(for type: AnimationType) -> Animation {
        switch animationLevel {
        case .full:
            return getFullAnimation(for: type)
        case .reduced:
            return getReducedAnimation(for: type)
        case .minimal:
            return getMinimalAnimation(for: type)
        case .staticDisplay:
            return .linear(duration: 0) // No animation
        }
    }
    
    /// Animation types
    enum AnimationType {
        case morphing
        case pulsing
        case rolling
        case glowing
        case themeTransition
        case buttonSelection
    }
    
    // MARK: - Animation Variants
    
    private func getFullAnimation(for type: AnimationType) -> Animation {
        switch type {
        case .morphing:
            return SpringAnimator.morphToExpanded()
        case .pulsing:
            return SpringAnimator.urgencyPulse(for: .warning)
        case .rolling:
            return SpringAnimator.slotMachineRoll()
        case .glowing:
            return SpringAnimator.glowAnimation(for: .warning)
        case .themeTransition:
            return SpringAnimator.themeTransition()
        case .buttonSelection:
            return SpringAnimator.buttonSelection()
        }
    }
    
    private func getReducedAnimation(for type: AnimationType) -> Animation {
        switch type {
        case .morphing:
            return .easeInOut(duration: 0.3) // Simpler easing
        case .pulsing:
            return .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        case .rolling:
            return .easeInOut(duration: 0.2) // Faster, simpler
        case .glowing:
            return .easeInOut(duration: 0.5)
        case .themeTransition:
            return .easeInOut(duration: 0.2) // Faster transition
        case .buttonSelection:
            return .easeInOut(duration: 0.15)
        }
    }
    
    private func getMinimalAnimation(for type: AnimationType) -> Animation {
        // Only essential animations
        switch type {
        case .morphing, .themeTransition:
            return .easeInOut(duration: 0.1) // Very fast
        default:
            return .linear(duration: 0) // No animation
        }
    }
    
    // MARK: - Performance Monitoring
    
    /// Starts performance monitoring
    private func startPerformanceMonitoring() {
        // Monitor CPU and memory usage
        performanceMonitor = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
        
        // Monitor frame rate (would need CADisplayLink for actual frame rate)
        // For now, we'll use a simplified approach
    }
    
    /// Stops performance monitoring
    private func stopPerformanceMonitoring() {
        performanceMonitor?.invalidate()
        performanceMonitor = nil
        frameRateMonitor?.invalidate()
        frameRateMonitor = nil
    }
    
    /// Updates performance metrics.
    ///
    /// Reads *this process's* resident footprint. The previous implementation
    /// used `ProcessInfo.physicalMemory` — the machine's total RAM — divided by
    /// an arbitrary constant, so on a 64 GB Mac it read as "64 MB over budget"
    /// forever and permanently disabled the app's animations.
    private func updatePerformanceMetrics() {
        let newMemory = Self.residentMemoryMB() ?? memoryUsage

        // Assign through the change check to avoid a publish every second.
        if abs(newMemory - memoryUsage) > 1.0 {
            memoryUsage = newMemory
        }

        updateAnimationLevel()
    }

    /// Resident memory of this process, in megabytes.
    private static func residentMemoryMB() -> Double? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }
        return Double(info.phys_footprint) / 1024.0 / 1024.0
    }
}
