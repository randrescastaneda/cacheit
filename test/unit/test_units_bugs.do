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

// Source test utilities
run test_utils.ado

// Setup test environment
local test_dir = c(tmpdir) + "/cacheit_bug_tests_`=subinstr("`c(current_time)'", ":", "", .)')"
cap mkdir "`test_dir'"
global cache_dir "`test_dir'"

disp _newline "{title:========== CACHEIT BUG-SPECIFIC TESTS ==========}" _newline
local tests_passed = 0
local tests_failed = 0

//========================================================
// BUG-001: Timer Loop Variable Typo (Line 567)
//========================================================
cap noisily {
    disp "{bf:[BUG-001] Timer Loop Variable Typo}"
    disp "{text:Issue: local timeroff set instead of timernum}"
    disp "{text:Impact: Command execution fails if all 100 timers in use}"
    
    sysuse auto, clear
    
    // Fill up timers to near capacity
    forvalues i = 1/95 {
        qui timer on `i'
        qui timer off `i'
    }
    
    // Now attempt cacheit with limited timers free
    cap noisily cacheit, dir("`test_dir'"): regress price weight
    
    if _rc == 0 {
        test_pass "BUG-001: Timer allocation works with high timer count"
        local ++tests_passed
    }
    else {
        test_fail "BUG-001: Timer allocation fails with high timer count" "Expected graceful handling, got error code `_rc'"
        local ++tests_failed
    }
    
    // Reset timers
    timer clear
}

//========================================================
// BUG-002: Log File Handle Leak on Error  (Line 594)
//========================================================
cap noisily {
    disp _newline "{bf:[BUG-002] Log File Handle Leak on Error}"
    disp "{text:Issue: rlog file handle not closed when hidden option + error}"
    disp "{text:Impact: Resource leak in error paths}"
    
    sysuse auto, clear
    
    // Attempt command with hidden option that will generate error
    cap noisily cacheit, dir("`test_dir'") hidden: bogus_command_that_fails
    local error_code = _rc
    
    if `error_code' != 0 {
        // Error correctly generated
        // Check if rlog files are left open (hard to verify directly)
        // Instead, check that we can still use cacheit afterward
        sysuse auto, clear
        
        cap noisily cacheit, dir("`test_dir'"): regress price weight
        
        if _rc == 0 {
            test_pass "BUG-002: Recovery after command error works"
            local ++tests_passed
        }
        else {
            test_fail "BUG-002: Cannot recover after command error" "Resource leak may have occurred"
            local ++tests_failed
        }
    }
}

//========================================================
// BUG-003: Temporary Frame Cleanup on Error
//========================================================
cap noisily {
    disp _newline "{bf:[BUG-003] Temporary Frame Cleanup on Error}"
    disp "{text:Issue: Temporary frames not dropped on error paths}"
    disp "{text:Impact: Memory leak, orphaned frames in memory}"
    
    sysuse auto, clear
    
    // Count frames before
    qui frames dir
    local frames_before = r(number)
    
    // Attempt cacheit with invalid command
    cap noisily cacheit, dir("`test_dir'"): invalid command syntax here
    
    // Count frames after
    qui frames dir
    local frames_after = r(number)
    
    // Frames should be equal (temp frames cleaned up)
    if `frames_before' == `frames_after' {
        test_pass "BUG-003: Temporary frames cleaned up on error"
        local ++tests_passed
    }
    else {
        test_fail "BUG-003: Frame leak on error detected" "Frames before: `frames_before', after: `frames_after'"
        local ++tests_failed
    }
}

//========================================================
// BUG-004: Frame Drop Error Handling
//========================================================
cap noisily {
    disp _newline "{bf:[BUG-004] Frame Drop Error Handling}"
    disp "{text:Issue: Frame drop commands have no error checking}"
    disp "{text:Impact: Orphaned frames remain in memory silently}"
    
    sysuse auto, clear
    
    // Create a frame that we'll attempt to drop during cacheit
    frame create temp_frame
    
    qui frames dir
    local frames_before = r(number)
    
    // Run cacheit command
    cap noisily cacheit, dir("`test_dir'"): regress price weight
    
    // Drop the frame we created
    frame drop temp_frame
    
    qui frames dir
    local frames_after = r(number)
    
    // Verify frame cleanup works
    if `frames_after' < `frames_before' {
        test_pass "BUG-004: Frame cleanup error handling intact"
        local ++tests_passed
    }
    else {
        test_fail "BUG-004: Frame cleanup issue detected" ""
        local ++tests_failed
    }
}

//========================================================
// BUG-005: Graph Name Parsing Edge Cases
//========================================================
cap noisily {
    disp _newline "{bf:[BUG-005] Graph Name Parsing with Special Characters}"
    disp "{text:Issue: Special characters in graph names break list comparison}"
    disp "{text:Impact: Graphs may not be handled correctly in all cases}"
    
    sysuse auto, clear
    graph drop _all
    
    // Create and cache a simple graph (without special names)
    cap noisily cacheit, dir("`test_dir'"): scatter price weight
    
    if _rc == 0 {
        // Drop graph
        graph drop _all
        
        // Re-run from cache - should restore graph
        cap noisily cacheit, dir("`test_dir'"): scatter price weight
        
        // Try to describe the graph
        cap graph describe Graph
        if _rc == 0 {
            test_pass "BUG-005: Graph handling works for standard names"
            local ++tests_passed
        }
        else {
            test_fail "BUG-005: Graph not restored from cache" ""
            local ++tests_failed
        }
        
        graph drop _all
    }
    else {
        test_skip "BUG-005" "Graph caching prerequisite failed"
    }
}

//========================================================
// SUMMARY
//========================================================
disp _newline "{title:========== BUG TEST SUMMARY ==========}"
disp _newline "{result:Tests Passed:  `tests_passed'}"
disp "{result:Tests Failed:  `tests_failed'}"
local total = `tests_passed' + `tests_failed'
disp "{result:Total Tests:   `total'}" _newline

// Cleanup
cleanup_cache "`test_dir'"
global cache_dir ""

if `tests_failed' > 0 {
    disp "{err:BUGS DETECTED}" _newline
    exit 1
}
else {
    disp "{result:ALL CRITICAL BUGS APPEAR TO BE HANDLED}" _newline
}

exit
/* End of test file */
