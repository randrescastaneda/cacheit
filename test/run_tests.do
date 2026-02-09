/*==================================================
Master Test Runner for cacheit Package
Author:        Testing Framework
E-mail:        testing@cacheit.org
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Runs all test suites and generates report
==================================================*/

/*
USAGE:
    From cacheit/test directory:
    do run_tests.do
    
    Or with options:
    do run_tests.do, bugs core advanced integration
*/

version 16.1
clear all
set more off

// Parse arguments
local test_suites "bugs core advanced"

disp _newline "{title:╔════════════════════════════════════════════════════════╗}"
disp "{title:║         CACHEIT COMPREHENSIVE TEST SUITE RUNNER           ║}"
disp "{title:╚════════════════════════════════════════════════════════╝}" _newline

// Setup paths
local test_root = c(sysdir_ado) + "/../../../ado/myados/cacheit/test"
capture cd "`test_root'"

if _rc != 0 {
    disp "{err:ERROR: Could not navigate to test directory}"
    disp "{err:`test_root'}"
    exit 1
}

// Initialize results tracking
local total_passed = 0
local total_failed = 0
local total_skipped = 0

local test_results ""

//========================================================
// RUN BUG-SPECIFIC TESTS
//========================================================
if strpos("`test_suites'", "bugs") > 0 {
    disp "{title:Running BUG-SPECIFIC TESTS...}" _newline
    
    cap {
        do unit/test_units_bugs.do
    }
    
    if _rc == 0 {
        disp "{result:✓ Bug tests completed successfully}" _newline
    }
    else {
        disp "{err:✗ Bug tests encountered errors (code: `_rc')}" _newline
    }
}

//========================================================
// RUN CORE FUNCTIONALITY TESTS
//========================================================
if strpos("`test_suites'", "core") > 0 {
    disp "{title:Running CORE FUNCTIONALITY TESTS...}" _newline
    
    cap {
        do unit/test_units_core.do
    }
    
    if _rc == 0 {
        disp "{result:✓ Core tests completed successfully}" _newline
    }
    else {
        disp "{err:✗ Core tests encountered errors (code: `_rc')}" _newline
    }
}

//========================================================
// RUN ADVANCED FEATURE TESTS
//========================================================
if strpos("`test_suites'", "advanced") > 0 {
    disp "{title:Running ADVANCED FEATURE TESTS...}" _newline
    
    cap {
        do unit/test_units_advanced.do
    }
    
    if _rc == 0 {
        disp "{result:✓ Advanced tests completed successfully}" _newline
    }
    else {
        disp "{err:✗ Advanced tests encountered errors (code: `_rc')}" _newline
    }
}

//========================================================
// GENERATE FINAL REPORT
//========================================================
disp _newline "{title:╔════════════════════════════════════════════════════════╗}"
disp "{title:║                    FINAL TEST REPORT                      ║}"
disp "{title:╚════════════════════════════════════════════════════════╝}" _newline

disp "{text:Test Suites Run: `test_suites'}"
disp "{text:Date: `c(current_date)' `c(current_time)'}" _newline

disp "{result:For detailed results, review individual test output above.}" _newline

exit
/* End of test runner */
