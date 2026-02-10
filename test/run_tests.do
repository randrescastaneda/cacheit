/*==================================================
Master Test Runner for cacheit Package
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
discard // very important for changes in the cacheit package
set more off

// Source test utilities for master tracking
run test_utils.ado

disp _newline "{title:CACHEIT TEST SUITE RUNNER}" _newline

// Parse arguments
local test_suites "bugs core advanced"

// User-specific overrides (add your path if needed)
if ("`c(username)'" == "wb384996") {
    local test_root "C:\Users\wb384996\OneDrive - WBG\ado\myados\cacheit\test"
}
else {
    // Default: use current working directory
    local test_root "`c(pwd)'"
}

cap cd "`test_root'"

if _rc != 0 {
    disp "{err:ERROR: Could not navigate to test directory}"
    disp "{err:`test_root'}"
    exit 1
}

//========================================================
// RUN BUG-SPECIFIC TESTS
//========================================================
local overall_rc = 0
local suite_count = 0

if strpos("`test_suites'", "bugs") > 0 {
    disp _newline "{title:Running BUG tests...}" _newline
    cap noisily do unit/test_units_bugs.do
    local rc_bugs = _rc
    
    if `rc_bugs' != 0 {
        local overall_rc = 1
        disp _newline "{err:✗ BUG TESTS FAILED}" _newline
    }
    else {
        disp _newline "{result:✓ BUG TESTS PASSED}" _newline
    }
    local ++suite_count
}

//========================================================
// RUN CORE FUNCTIONALITY TESTS
//========================================================
if strpos("`test_suites'", "core") > 0 {
    disp _newline "{title:Running CORE tests...}" _newline
    cap noisily do unit/test_units_core.do
    local rc_core = _rc
    
    if `rc_core' != 0 {
        local overall_rc = 1
        disp _newline "{err:✗ CORE TESTS FAILED}" _newline
    }
    else {
        disp _newline "{result:✓ CORE TESTS PASSED}" _newline
    }
    local ++suite_count
}

//========================================================
// RUN ADVANCED FEATURE TESTS
//========================================================
if strpos("`test_suites'", "advanced") > 0 {
    disp _newline "{title:Running ADVANCED tests...}" _newline
    cap noisily do unit/test_units_advanced.do
    local rc_advanced = _rc
    
    if `rc_advanced' != 0 {
        local overall_rc = 1
        disp _newline "{err:✗ ADVANCED TESTS FAILED}" _newline
    }
    else {
        disp _newline "{result:✓ ADVANCED TESTS PASSED}" _newline
    }
    local ++suite_count
}

if `overall_rc' == 0 {
    disp _newline "{hline 70}"
    disp "{bf:MASTER TEST SUMMARY}"
    disp "{hline 70}"
    disp "Test suites run: `suite_count'"
    disp _newline "{result:✓ SUCCESS: All test suites completed successfully.}" _newline
    disp "{text:For detailed test results, see individual test output above.}"
    exit 0
}
else {
    disp _newline "{hline 70}"
    disp "{bf:MASTER TEST SUMMARY}"
    disp "{hline 70}"
    disp "Test suites run: `suite_count'"
    disp _newline "{err:✗ FAILURE: Some test suites had failures.}" _newline
    disp "{text:Review error messages above for details.}"
    exit 1
}
/* End of test runner */
