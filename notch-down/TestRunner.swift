//
//  TestRunner.swift
//  notch-down
//
//  Test runner for bug condition exploration tests
//  This allows running tests directly from the app without needing a test target
//

import Foundation

class TestRunner {
    static let shared = TestRunner()
    
    private init() {}
    
    /// Run bug condition exploration tests
    /// Call this method to execute the tests and print results to console
    func runBugExplorationTests() {
        let results = DynamicIslandInteractionTests.shared.runAllTests()
        
        // Store results for later analysis
        saveTestResults(results)
    }
    
    private func saveTestResults(_ results: [String: DynamicIslandInteractionTests.TestResult]) {
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var output = """
        Bug Condition Exploration Test Results
        Timestamp: \(formatter.string(from: timestamp))
        
        """
        
        for (_, result) in results {
            output += """
            
            Test: \(result.testName)
            Status: \(result.passed ? "PASS" : "FAIL")
            Message: \(result.message)
            """
            
            if let counterexample = result.counterexample {
                output += "\nCounterexample: \(counterexample)"
            }
            
            output += "\n"
        }
        
        print(output)
    }
}
