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

// Setup paths
local test_root = c(sysdir_ado) + "/../../../ado/myados/cacheit/test"
capture cd "`test_root'"

if _rc != 0 {
    disp "{err:ERROR: Could not navigate to test directory}"
    disp "{err:`test_root'}"
    exit 1
}

//========================================================
// RUN BUG-SPECIFIC TESTS
//========================================================
if strpos("`test_suites'", "bugs") > 0 {
    cap {
        do unit/test_units_bugs.do
    }
}

//========================================================
// RUN CORE FUNCTIONALITY TESTS
//========================================================
if strpos("`test_suites'", "core") > 0 {
    cap {
        do unit/test_units_core.do
    }
}

//========================================================
// RUN ADVANCED FEATURE TESTS
//========================================================
if strpos("`test_suites'", "advanced") > 0 {
    cap {
        do unit/test_units_advanced.do
    }
}

disp _newline "{result:Tests completed." _newline

exit
/* End of test runner */
