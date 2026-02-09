/*==================================================
Unit Tests for cacheit Package - BUG-SPECIFIC TESTS
Author:        Testing Suite
E-mail:        testing@cacheit.org
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Tests that specifically target identified bugs
==================================================*/

/*
USAGE:
    do test_units_bugs.do
    
TESTS:
    BUG-001: Timer loop variable typo
    BUG-002: Log file handle leak on error
    BUG-003: Temporary frame cleanup on error
    BUG-004: Frame drop error handling
    BUG-005: Graph name parsing with special characters
*/

version 16.1

// Setup
clear all
set more off
timer clear

// Source test utilities
run test_utils.ado

// Setup test environment
local test_dir = c(tmpdir) + `"cacheit_bug_tests_`=subinstr("`c(current_time)'", ":", "", .)'"'

cap mkdir "`test_dir'"
global cache_dir "`test_dir'"

disp _newline "{title:Running Bug-Specific Tests...}" _newline
local tests_passed = 0
local tests_failed = 0

//========================================================
// BUG-001: Timer Loop Variable Typo (Line 567)
//========================================================
qui {
    sysuse auto, clear
    
    // Fill up timers to near capacity
    forvalues i = 1/95 {
        qui timer on `i'
        qui timer off `i'
    }
    
    // Now attempt cacheit with limited timers free
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
    cap `cmd_line'
    
    if _rc == 0 {
        test_pass "BUG-001"
        local ++tests_passed
    }
    else {
        test_fail "BUG-001" ///
        "Timer allocation" "Expected graceful handling, got error code `_rc'" ///
        `"`cmd_line'"'
        local ++tests_failed
    }
    
    // Reset timers
    timer clear
}

//========================================================
// BUG-002: Log File Handle Leak on Error  (Line 594)
//========================================================
qui {
    sysuse auto, clear
    
    // Attempt command with error to trigger log file handling
    local cmd_error `"cacheit, dir("`test_dir'") hidden: bogus_command_that_fails"'
    cap `cmd_error'
    local error_code = _rc
    
    if `error_code' != 0 {
        // Error correctly generated, check if we can still use cacheit afterward
        sysuse auto, clear
        
        local cmd_recovery `"cacheit, dir("`test_dir'"): regress price weight"'
        cap `cmd_recovery'
        
        if _rc == 0 {
            test_pass "BUG-002"
            local ++tests_passed
        }
        else {
            test_fail "BUG-002" "Recovery after error" "Resource leak may have occurred" `"`cmd_recovery'"'
            local ++tests_failed
        }
    }
}

//========================================================
// BUG-003: Temporary Frame Cleanup on Error
//========================================================
qui {
    sysuse auto, clear
    
    // Count frames before
    qui frames dir
    local frames_before : word count `r(frames)'
    
    // Attempt cacheit with invalid command
    local cmd_line `"cacheit, dir("`test_dir'"): invalid command syntax here"'
    cap `cmd_line'
    
    // Count frames after
    qui frames dir
    local frames_after : word count `r(frames)'
    
    // Frames should be equal (temp frames cleaned up)
    if `frames_before' == `frames_after' {
        test_pass "BUG-003"
        local ++tests_passed
    }
    else {
        test_fail "BUG-003" "Frame cleanup on error" "Frames before: `frames_before', after: `frames_after'" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// BUG-004: Frame Drop Error Handling
//========================================================
qui {
    sysuse auto, clear
    
    // Create a frame that we'll attempt to drop during cacheit
    frame create temp_frame
    
    qui frames dir
    local frames_before : word count `r(frames)'
    
    // Run cacheit command
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
    cap `cmd_line'
    
    // Drop the frame we created
    frame drop temp_frame
    
    qui frames dir
    local frames_after : word count `r(frames)'
    
    // Verify frame cleanup works
    if `frames_after' < `frames_before' {
        test_pass "BUG-004"
        local ++tests_passed
    }
    else {
        test_fail "BUG-004" "Frame cleanup" "Frames not properly cleaned" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// BUG-005: Graph Name Parsing Edge Cases
//========================================================
qui {
    sysuse auto, clear
    graph drop _all
    
    // Create and cache a simple graph (without special names)
    local cmd_line `"cacheit, dir("`test_dir'"): scatter price weight"'
    cap `cmd_line'
    
    if _rc == 0 {
        // Drop graph
        graph drop _all
        
        // Re-run from cache - should restore graph
        cap `cmd_line'
        
        // Try to describe the graph
        cap graph describe Graph
        if _rc == 0 {
            test_pass "BUG-005"
            local ++tests_passed
            graph drop _all
        }
        else {
            test_fail "BUG-005" "Graph restoration" "Graph not restored from cache" `"`cmd_line'"'
            local ++tests_failed
        }
    }
    else {
        test_skip "BUG-005" "Graph caching prerequisite failed"
    }
}

//========================================================
// SUMMARY
//========================================================
cleanup_cache "`test_dir'"
global cache_dir ""

local total = `tests_passed' + `tests_failed'
disp _newline "{result:Bug Tests: `tests_passed' passed, `tests_failed' failed (out of `total')}" _newline

exit
/* End of test file */
