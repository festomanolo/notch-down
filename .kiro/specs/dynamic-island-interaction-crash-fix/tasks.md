# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Fault Condition** - Button Interactions Cause Termination
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: Scope the property to concrete failing cases - button clicks in Dynamic Island interface
  - Test that clicking any button (Start Timer, theme toggle, power dropdown, About navigation, Cancel Timer, custom time picker) causes app termination on UNFIXED code
  - Verify system logs show "makeKeyWindow called on window which returned NO from canBecomeKeyWindow" and "Attempting sudden termination" messages
  - Verify window configuration conflict: `.nonactivatingPanel` style mask with `canBecomeKey` returning `true`
  - The test assertions should match: button action executes without termination, responder chain established, no "makeKeyWindow" warnings
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found: which buttons cause termination, what logs appear, window configuration details
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Non-Interactive Behavior Unchanged
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-interactive features:
    - Window display with glassmorphism effects, shadows, visual styling
    - Morph animations between collapsed/expanded states with spring physics
    - Hover effects on buttons (work without key window status)
    - Menu bar icon and menu functionality
    - Global keyboard shortcut (Shift + Ctrl + U) toggle
    - Click-outside-to-collapse behavior
    - Timer countdown logic and urgency level transitions
    - Auto-expansion for critical states (T-minus 1 minute, 10 seconds)
    - Window positioning on active screen with safe area insets
    - Floating panel behavior (canJoinAllSpaces, fullScreenAuxiliary)
  - Write property-based tests capturing observed behavior patterns for all non-button-click interactions
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

- [x] 3. Fix window configuration conflict in NotchPanel

  - [x] 3.1 Implement the fix in NotchWindow.swift
    - Remove `.nonactivatingPanel` from style mask (line 237)
    - Replace with `.titled` to allow proper window activation
    - Keep `canBecomeKey` returning `true` (line 252-254) - now consistent with style mask
    - Verify `canBecomeMain` still returns `false` (line 256-258) to prevent main window behavior
    - This aligns the window's key window capability with its panel style, allowing button interactions to establish responder chain
    - _Bug_Condition: isBugCondition(input) where input.type IN ['button_click', 'toggle_click', 'dropdown_select', 'picker_interact'] AND input.target IS_WITHIN DynamicIslandView AND window.styleMask CONTAINS .nonactivatingPanel AND window.canBecomeKey == true_
    - _Expected_Behavior: Button action handler executes, UI state updates, no app termination, responder chain established, no "makeKeyWindow" warnings_
    - _Preservation: Window display, animations, hover effects, menu bar, keyboard shortcuts, click-outside, timer logic, positioning, and all non-interactive behaviors remain unchanged_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

  - [x] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Button Interactions Execute Without Termination
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - Verify all button clicks (Start Timer, theme toggle, power dropdown, About navigation, Cancel Timer, custom time picker) execute without termination
    - Verify no "makeKeyWindow" warnings appear in logs
    - Verify responder chain is established correctly
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [x] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Non-Interactive Behavior Unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - Verify window display, animations, hover effects, menu bar, keyboard shortcuts, click-outside, timer logic, positioning, and floating panel behavior all work identically to unfixed code
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

- [x] 4. Checkpoint - Ensure all tests pass
  - Verify bug condition exploration test passes (button interactions work without termination)
  - Verify preservation tests pass (non-interactive behaviors unchanged)
  - Run full integration test suite: timer flows, theme switching, About page navigation, critical expansion, multi-screen support
  - Ensure all tests pass, ask the user if questions arise
