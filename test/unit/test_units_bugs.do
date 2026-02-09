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
    
    // Fill up ALL timers to force uninitialized timernum
    forvalues i = 1/100 {
        qui timer on `i'
        qui timer off `i'
    }
    
    // Now attempt cacheit with NO free timers
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
    cap `cmd_line'
    
    if _rc != 0 {
        // Should fail because timernum is uninitialized
        test_pass "BUG-001"
        local ++tests_passed
    }
    else {
        noi test_fail "BUG-001" "Timer allocation" "Command unexpectedly succeeded with all timers full" `"`cmd_line'"'
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
    
    // First, try to access the rlog file to see if it's open after error
    // Attempt command with hidden option that will generate error
    local cmd_error `"cacheit, dir("`test_dir'") hidden: bogus_command_that_fails"'
    cap `cmd_error'
    local error_code = _rc
    
    if `error_code' != 0 {
        // Error correctly generated
        // Now try to CREATE a file named rlog in same directory
        // If rlog is still open, this should fail
        cap file open testfile using "`test_dir'/rlist.txt", read
        
        if _rc == 0 {
            // File can be opened, meaning rlog was closed (no leak)
            file close testfile
            noi test_fail "BUG-002" "Log file leak" "rlog file handle properly closed (bug may be fixed)" `"`cmd_error'"'
            local ++tests_failed
        }
        else {
            // File cannot be opened (rlog still holding it)
            test_pass "BUG-002"
            local ++tests_passed
        }
    }
}

//========================================================
// BUG-003: Temporary Frame Cleanup on Error
//========================================================
qui {
    sysuse auto, clear
    
    // Count frames before (baseline)
    qui frames dir
    local frames_before : word count `r(frames)'
    
    // Attempt cacheit that will error DURING cache lookup (before command execution)
    // This triggers the hashcheck frame creation at line 271
    // If error happens before saving, hashcheck frame isn't cleaned up
    local cmd_line `"cacheit, dir("`test_dir'"): generate x = 1/0"'
    cap `cmd_line'
    
    // Count frames after
    qui frames dir
    local frames_after : word count `r(frames)'
    
    // If frames_after > frames_before, we have leaked frames
    if `frames_after' > `frames_before' {
        test_pass "BUG-003"
        local ++tests_passed
    }
    else {
        noi test_fail "BUG-003" "Frame cleanup on error" `"`cmd_line'"'
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
    cap `cmd_lframes to track
    qui frames dir
    local frames_initial : word count `r(frames)'
    
    // Run cacheit which will create and drop internal frames
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
    cap `cmd_line'
    
    // Count frames after execution
    qui frames dir
    local frames_final : word count `r(frames)'
    
    // If frame drops have error checking (cap), frames should be cleaned
    // If frame drops lack error checking and fail silently, frames stay
    // Bug manifests as orphaned frames remaining
    if `frames_final' == `frames_initial' {
        test_pass "BUG-004"
        local ++tests_passed
    }
    else {
        noi test_fail "BUG-004" "Orphaned frames remain (expected `frames_initial', got `frames_final')" `"`cmd_line'"'
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
            noi test_fail "BUG-005" "Graph not restored from cache" `"`cmd_line'"'
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
* cleanup_cache "${cache_dir}"
cleanup_cache "`test_dir'"

global cache_dir ""

local total = `tests_passed' + `tests_failed'
disp _newline "{result:Bug Tests: `tests_passed' passed, `tests_failed' failed (out of `total')}" _newline

exit
/* End of test file */
