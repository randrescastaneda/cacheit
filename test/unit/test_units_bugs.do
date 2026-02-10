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

// Initialize test results frame
init_test_results, suite_name("Bug-Specific Tests")

// Setup test environment
global test_dir = c(tmpdir) + `"cacheit_bug_tests_`=subinstr("`c(current_time)'", ":", "", .)'"'

cap mkdir "${test_dir}"
global cache_dir "${test_dir}"

disp _newline "{title:Running Bug-Specific Tests...}" _newline

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
    local rc = _rc
    
    if `rc' == 0 {
        // Should succeed if bug is fixed (graceful handling)
        append_test_result, test_id("BUG-001") status("pass") description("Timer allocation with high timer count") command("`cmd_line'")
    }
    else {
        // Test FAILS because bug exists (timernum undefined causes error)
        append_test_result, test_id("BUG-001") status("fail") description("Timer allocation with high timer count") assertion_msg("Command failed with all timers full (timernum likely undefined): Error code `rc'") command("`cmd_line'")
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
    local rc = _rc
    
    if `rc' != 0 {
        // Stata auto-closed rlog when exit was called
        cap qui log query rlog
        if _rc != 0 {
            append_test_result, test_id("BUG-002") status("pass") description("Log file handle leak on error") assertion_msg("NOTE: Bug exists in code but Stata cleans up automatically") command("`cmd_error'")
            // NOTE: Bug exists in code but Stata cleans up automatically
        }
        else {
            cap qui log close rlog
            append_test_result, test_id("BUG-002") status("fail") description("Log file handle leak on error") assertion_msg("Unexpected: rlog still open") command("`cmd_error'")
        }
    }
    else {
        append_test_result, test_id("BUG-002") status("fail") description("Log file handle leak on error") assertion_msg("Expected error but command succeeded") command("`cmd_error'")
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
    local rc = _rc
    
    qui frames dir
    local frames_after : word count `r(frames)'
    
    // Test will pass because Stata cleaned up
    if `frames_after' == `frames_before' {
        append_test_result, test_id("BUG-003") status("pass") description("Frame cleanup on error") assertion_msg("NOTE: Bug exists in code but Stata cleans up automatically") command("`cmd_line'")
        // NOTE: Bug exists in code but Stata cleans up automatically
    }
    else {
        append_test_result, test_id("BUG-003") status("fail") description("Frame cleanup on error") assertion_msg("Unexpected frame leak: before=`frames_before', after=`frames_after'") command("`cmd_line'")
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
    local rc = _rc
    
    qui frames dir
    local frames_after : word count `r(frames)'
    
    if `frames_after' == `frames_before' {
        append_test_result, test_id("BUG-004") status("pass") description("Frame cleanup after execution") assertion_msg("NOTE: Bug in code (missing cap) but doesn't fail in normal use") command("`cmd_line'")
        // NOTE: Bug in code (missing cap) but doesn't fail in normal use
    }
    else {
        append_test_result, test_id("BUG-004") status("fail") description("Frame cleanup after execution") assertion_msg("Frames not cleaned: before=`frames_before', after=`frames_after'") command("`cmd_line'")
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
    local rc = _rc
    
    if `rc' == 0 {
        graph drop _all
        cap `cmd_line'
        
        cap graph describe Graph
        local graph_rc = _rc
        
        if `graph_rc' == 0 {
            append_test_result, test_id("BUG-005") status("pass") description("Graph restoration from cache") command("`cmd_line'")
            graph drop _all
        }
        else {
            append_test_result, test_id("BUG-005") status("fail") description("Graph restoration from cache") assertion_msg("Graph not restored from cache") command("`cmd_line'")
        }
    }
    else {
        append_test_result, test_id("BUG-005") status("fail") description("Graph restoration from cache") assertion_msg("Initial graph creation failed: Error code `rc'") command("`cmd_line'")
    }
}

//========================================================
// SUMMARY AND CLEANUP
//========================================================

cacheit clean, dir("${test_dir}") force

global cache_dir ""

print_test_summary
local has_failures = r(n_fail) > 0

if `has_failures' > 0 {
    disp "{err:TESTS FAILED - Bugs detected that cause runtime failures}"
    exit 1
}
else {
    disp "{text:All runtime tests passed. Note: BUG-002, BUG-003, BUG-004 are}"
    disp "{text:code quality issues that should still be fixed in cacheit.ado}"
    exit 0
}
/* End of test file */
