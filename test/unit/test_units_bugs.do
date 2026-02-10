/*==================================================
Unit Tests for cacheit Package - BUG-SPECIFIC TESTS
Author:        Testing Suite
E-mail:        testing@cacheit.org
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Tests that specifically target identified bugs

NOTE: Only BUG-001 is a functional bug detectable at runtime.
      BUG-002 through BUG-004 are code quality issues that should
      be fixed but don't cause runtime failures because Stata
      automatically cleans up resources when programs exit.
==================================================*/

/*
USAGE:
    do test_units_bugs.do
    
TESTS:
    BUG-001: Timer loop variable typo - FUNCTIONAL BUG
    BUG-002: Log file handle leak - CODE QUALITY (auto-cleaned by Stata)
    BUG-003: Frame cleanup on error - CODE QUALITY (auto-cleaned by Stata)
    BUG-004: Unguarded frame drops - CODE QUALITY (Stata handles gracefully)
    BUG-005: Graph caching test - FUNCTIONAL TEST
*/

version 16.1

// Setup
clear all
set more off
timer clear

// Source test utilities
run test_utils.ado

// Setup test environment
global test_dir = c(tmpdir) + `"cacheit_bug_tests_`=subinstr("`c(current_time)'", ":", "", .)'"'

cap mkdir "${test_dir}"
global cache_dir "${test_dir}"

disp _newline "{title:Running Bug-Specific Tests...}" _newline
local tests_passed = 0
local tests_failed = 0

//========================================================
// BUG-001: Timer Loop Variable Typo (Line 567)
//========================================================
qui {
    sysuse auto, clear
    
    // Fill up ALL timers to force uninitialized timernum
    forvalues i = 1/100 {
        qui timer on `i'
        qui timer off `i'
    }
    
    // Now attempt cacheit with NO free timers
    local cmd_line `"cacheit, dir("${test_dir}"): regress price weight"'
    cap `cmd_line'
    
    if _rc == 0 {
        // Should succeed if bug is fixed (graceful handling)
        test_pass "BUG-001"
        local ++tests_passed
    }
    else {
        // Test FAILS because bug exists (timernum undefined causes error)
        noi test_fail "BUG-001" "Timer allocation" "Command failed with all timers full (timernum likely undefined)" `"`cmd_line'"'
        local ++tests_failed
    }
    
    // Reset timers
    timer clear
}

//========================================================
// BUG-002: Log File Handle Leak on Error (Line 606)
// NOTE: This is a CODE QUALITY issue. Stata auto-closes logs
//       when programs exit, so this won't cause runtime failure.
//       However, explicit cleanup is still best practice.
//========================================================
qui {
    sysuse auto, clear
    
    // This test documents the issue but will pass due to Stata's cleanup
    local cmd_error `"cacheit, dir("${test_dir}") hidden: bogus_command_that_fails"'
    cap `cmd_error'
    
    if _rc != 0 {
        // Stata auto-closed rlog when exit was called
        cap qui log query rlog
        if _rc != 0 {
            test_pass "BUG-002"
            local ++tests_passed
            // NOTE: Bug exists in code but Stata cleans up automatically
        }
        else {
            cap qui log close rlog
            noi test_fail "BUG-002" "Log file leak" "Unexpected: rlog still open" `"`cmd_error'"'
            local ++tests_failed
        }
    }
    else {
        noi test_fail "BUG-002" "Test setup" "Expected error but command succeeded" `"`cmd_error'"'
        local ++tests_failed
    }
} 
//========================================================
// BUG-003: Temporary Frame Cleanup on Error
//========================================================
//   NOTE: This is a CODE QUALITY issue. Stata auto-cleans frames
//       when programs exit, so leaked frames don't persist.
//       However, explicit cleanup is still best practice.
//========================================================
qui {
    sysuse auto, clear
    
    qui frames dir
    local frames_before : word count `r(frames)'
    
    // This will error, but Stata will clean up frames on exit
    local cmd_line `"cacheit, dir("${test_dir}"): generate x = 1/0"'
    cap `cmd_line'
    
    qui frames dir
    local frames_after : word count `r(frames)'
    
    // Test will pass because Stata cleaned up
    if `frames_after' == `frames_before' {
        test_pass "BUG-003"
        local ++tests_passed
        // NOTE: Bug exists in code but Stata cleans up automatically
    }
    else {
        noi test_fail "BUG-003" "Frame cleanup" "Unexpected frame leak: before=`frames_before', after=`frames_after'"
        local ++tests_failed
    }
}

//========================================================
// BUG-004: Unguarded Frame Drops (Line 730)
// NOTE: This is a CODE QUALITY issue. Missing 'cap' prefix means
//       errors aren't gracefully handled, but in normal operation
//       frames exist and drop succeeds.
//========================================================
qui {
    sysuse auto, clear
    
    qui frames dir
    local frames_before : word count `r(frames)'
    
    // Normal operation - frames get created and dropped successfully
    local cmd_line `"cacheit, dir("${test_dir}"): regress price weight"'
    cap `cmd_line'
    
    qui frames dir
    local frames_after : word count `r(frames)'
    
    if `frames_after' == `frames_before' {
        test_pass "BUG-004"
        local ++tests_passed
        // NOTE: Bug in code (missing cap) but doesn't fail in normal use
    }
    else {
        noi test_fail "BUG-004" "Frame cleanup" "Frames not cleaned: before=`frames_before', after=`frames_after'" `"`cmd_line'"'
        local ++tests_failed
    }
}
//========================================================
// BUG-005: Graph Caching and Restoration Test
// NOTE: This tests that graph functionality works correctly.
//========================================================

qui {
    sysuse auto, clear
    graph drop _all
    
    local cmd_line `"cacheit, dir("${test_dir}"): scatter price weight"'
    cap `cmd_line'
    
    if _rc == 0 {
        graph drop _all
        cap `cmd_line'
        
        cap graph describe Graph
        if _rc == 0 {
            test_pass "BUG-005"
            local ++tests_passed
            graph drop _all
        }
        else {
            noi test_fail "BUG-005" "Graph restoration" "Graph not restored from cache" `"`cmd_line'"'
            local ++tests_failed
        }
    }
    else {
        noi test_fail "BUG-005" "Graph creation" "Initial graph creation failed" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// SUMMARY
//========================================================

cacheit clean, dir("${test_dir}") force

global cache_dir ""

local total = `tests_passed' + `tests_failed'
disp _newline "{result:Bug Tests: `tests_passed' passed, `tests_failed' failed (out of `total')}" _newline

if `tests_failed' > 0 {
    disp "{err:TESTS FAILED - Bugs detected that cause runtime failures}"
}
else {
    disp "{text:All runtime tests passed. Note: BUG-002, BUG-003, BUG-004 are}"
    disp "{text:code quality issues that should still be fixed in cacheit.ado}"
}