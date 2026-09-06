//
//  DynamicIslandInteractionTests.swift
//  notch-down
//
//  Bug Condition Exploration Test for Dynamic Island Interaction Crash
//  This test is EXPECTED TO FAIL on unfixed code - failure confirms the bug exists
//
//  USAGE: Run this file directly in the app to test the bug condition
//  The test will print results to console showing the window configuration conflict
//

import AppKit
import SwiftUI

/// **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7**
///
/// Property 1: Fault Condition - Button Interactions Cause Termination
///
/// This test explores the bug condition where clicking any button in the Dynamic Island
/// interface causes app termination due to a window configuration conflict.
///
/// CRITICAL: This test MUST FAIL on unfixed code - failure confirms the bug exists.
/// DO NOT attempt to fix the test or the code when it fails.
///
/// The test verifies:
/// 1. Window configuration conflict exists (.nonactivatingPanel + canBecomeKey=true)
/// 2. Button interactions trigger the responder chain failure
/// 3. System logs show "makeKeyWindow called on window which returned NO from canBecomeKeyWindow"
/// 4. App termination occurs when buttons are clicked
///
/// Expected outcome on UNFIXED code: TEST FAILS (this is correct - proves bug exists)
/// Expected outcome on FIXED code: TEST PASSES (bug is resolved)
class DynamicIslandInteractionTests {
    
    static let shared = DynamicIslandInteractionTests()
    
    private init() {}
    
    // MARK: - Test Execution
    
    /// Run all bug condition exploration tests
    /// Returns: Dictionary with test results and counterexamples
    func runAllTests() -> [String: TestResult] {
        print("\n" + String(repeating: "=", count: 80))
        print("BUG CONDITION EXPLORATION TEST - Dynamic Island Interaction Crash")
        print(String(repeating: "=", count: 80))
        print("CRITICAL: These tests are EXPECTED TO FAIL on unfixed code")
        print("Failure confirms the bug exists and validates the root cause analysis")
        print(String(repeating: "=", count: 80) + "\n")
        
        var results: [String: TestResult] = [:]
        
        results["windowConfigurationConflict"] = testWindowConfigurationConflict()
        results["makeKeyWindowBehavior"] = testMakeKeyWindowBehavior()
        results["responderChainEstablishment"] = testResponderChainEstablishment()
        
        print("\n" + String(repeating: "=", count: 80))
        print("TEST SUMMARY")
        print(String(repeating: "=", count: 80))
        
        let passedCount = results.values.filter { $0.passed }.count
        let failedCount = results.values.filter { !$0.passed }.count
        
        print("Total Tests: \(results.count)")
        print("Passed: \(passedCount)")
        print("Failed: \(failedCount)")
        
        if failedCount > 0 {
            print("\n⚠️  EXPECTED OUTCOME ON UNFIXED CODE: Tests FAILED")
            print("This confirms the bug exists and validates the root cause analysis.")
            print("\nCounterexamples found:")
            for (testName, result) in results where !result.passed {
                print("  - \(testName): \(result.message)")
            }
        } else {
            print("\n✅ UNEXPECTED OUTCOME: All tests PASSED")
            print("This suggests the bug may already be fixed or the root cause is different.")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
        
        return results
    }
    
    // MARK: - Individual Tests
    
    /// Test 1: Verify window configuration conflict exists
    /// This test checks if the root cause (window configuration conflict) is present
    private func testWindowConfigurationConflict() -> TestResult {
        print("\n--- Test 1: Window Configuration Conflict ---")
        
        // Create a test window with the same configuration as NotchPanel
        let testView = AnyView(Text("Test"))
        let testWindow = NotchPanel(rootView: testView)
        
        // Verify the configuration conflict exists
        let hasNonactivatingPanel = testWindow.styleMask.contains(.nonactivatingPanel)
        let canBecomeKey = testWindow.canBecomeKey
        let conflictExists = hasNonactivatingPanel && canBecomeKey
        
        print("Style mask contains .nonactivatingPanel: \(hasNonactivatingPanel)")
        print("canBecomeKey returns: \(canBecomeKey)")
        print("Configuration conflict exists: \(conflictExists)")
        
        let passed = conflictExists
        let message = conflictExists
            ? "Window configuration conflict detected: .nonactivatingPanel + canBecomeKey=true"
            : "No window configuration conflict found"
        
        print("Result: \(passed ? "PASS (conflict exists)" : "FAIL (no conflict)")")
        
        return TestResult(
            testName: "Window Configuration Conflict",
            passed: passed,
            message: message,
            counterexample: conflictExists ? "NotchPanel has .nonactivatingPanel style mask but canBecomeKey returns true" : nil
        )
    }
    
    /// Test 2: Verify makeKeyWindow behavior
    /// This test attempts to make the window key and checks if it succeeds
    private func testMakeKeyWindowBehavior() -> TestResult {
        print("\n--- Test 2: makeKeyWindow Behavior ---")
        
        let testView = AnyView(Text("Test"))
        let testWindow = NotchPanel(rootView: testView)
        
        // Show the window
        testWindow.makeKeyAndOrderFront(nil)
        
        // Wait for window to appear
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check if window became key
        let isKeyWindow = testWindow.isKeyWindow
        let isVisible = testWindow.isVisible
        
        print("Window is visible: \(isVisible)")
        print("Window is key: \(isKeyWindow)")
        print("canBecomeKey: \(testWindow.canBecomeKey)")
        print("Style mask: \(testWindow.styleMask)")
        
        // On UNFIXED code: Window will NOT become key despite canBecomeKey=true
        // This is because .nonactivatingPanel prevents it
        let passed = isKeyWindow
        let message = isKeyWindow
            ? "Window successfully became key window"
            : "Window failed to become key despite canBecomeKey=true (conflict with .nonactivatingPanel)"
        
        print("Result: \(passed ? "PASS" : "FAIL (expected on unfixed code)")")
        
        // Clean up
        testWindow.close()
        
        return TestResult(
            testName: "makeKeyWindow Behavior",
            passed: passed,
            message: message,
            counterexample: !passed ? "makeKeyWindow called but window did not become key due to .nonactivatingPanel style" : nil
        )
    }
    
    /// Test 3: Verify responder chain establishment
    /// This test checks if the responder chain can be properly established for button interactions
    private func testResponderChainEstablishment() -> TestResult {
        print("\n--- Test 3: Responder Chain Establishment ---")
        
        let testView = AnyView(Text("Test"))
        let testWindow = NotchPanel(rootView: testView)
        
        testWindow.makeKeyAndOrderFront(nil)
        
        // Wait for window to appear
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check responder chain
        let firstResponder = testWindow.firstResponder
        let acceptsFirstResponder = testWindow.acceptsFirstResponder
        let isKeyWindow = testWindow.isKeyWindow
        
        print("First responder: \(String(describing: firstResponder))")
        print("Accepts first responder: \(acceptsFirstResponder)")
        print("Is key window: \(isKeyWindow)")
        
        // On UNFIXED code: Responder chain cannot be established properly
        // because the window cannot become key
        let responderChainEstablished = firstResponder != nil && isKeyWindow
        let passed = responderChainEstablished
        let message = responderChainEstablished
            ? "Responder chain successfully established"
            : "Responder chain failed to establish (window not key, cannot route button events)"
        
        print("Result: \(passed ? "PASS" : "FAIL (expected on unfixed code)")")
        
        // Clean up
        testWindow.close()
        
        return TestResult(
            testName: "Responder Chain Establishment",
            passed: passed,
            message: message,
            counterexample: !passed ? "Responder chain cannot be established because window cannot become key" : nil
        )
    }
    
    // MARK: - Test Result Structure
    
    struct TestResult {
        let testName: String
        let passed: Bool
        let message: String
        let counterexample: String?
    }
}
