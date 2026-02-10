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
discard // very important for changes in the cacheit package
set more off

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

cd "`test_root'"

if _rc != 0 {
    disp "{err:ERROR: Could not navigate to test directory}"
    disp "{err:`test_root'}"
    exit 1
}

//========================================================
// RUN BUG-SPECIFIC TESTS
//========================================================
local overall_rc = 0

//========================================================
// RUN BUG-SPECIFIC TESTS
//========================================================
if strpos("`test_suites'", "bugs") > 0 {
    cap noisily do unit/test_units_bugs.do
    if _rc != 0 {
        local overall_rc = 1
        disp "{err:BUG TESTS FAILED}"
    }
    else {
        disp "{result:BUG TESTS PASSED}"
    }
}

//========================================================
// RUN CORE FUNCTIONALITY TESTS
//========================================================
if strpos("`test_suites'", "core") > 0 {
    cap noisily do unit/test_units_core.do
    if _rc != 0 {
        local overall_rc = 1
        disp "{err:CORE TESTS FAILED}"
    }
    else {
        disp "{result:CORE TESTS PASSED}"
    }
}

//========================================================
// RUN ADVANCED FEATURE TESTS
//========================================================
if strpos("`test_suites'", "advanced") > 0 {
    cap noisily do unit/test_units_advanced.do
    if _rc != 0 {
        local overall_rc = 1
        disp "{err:ADVANCED TESTS FAILED}"
    }
    else {
        disp "{result:ADVANCED TESTS PASSED}"
    }
}

if `overall_rc' == 0 {
    disp _newline "{result:All test suites completed successfully.}" _newline
    exit 0
}
else {
    disp _newline "{err:Some test suites had failures.}" _newline
    exit 1
}
/* End of test runner */
