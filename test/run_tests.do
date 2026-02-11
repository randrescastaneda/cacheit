/*==================================================
Master Test Runner for cacheit Package
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Runs all test suites and generates report
==================================================*/

version 16.1
clear all
cls
discard
set more off

disp _newline "{title:CACHEIT TEST SUITE RUNNER}" _newline

// Initialize tracking
local overall_rc = 0
local suite_count = 0

//========================================================
// RUN BUG-SPECIFIC TESTS
//========================================================
disp _newline "{title:Running BUG tests...}" _newline
cap noisily do test/unit/test_units_bugs.do
local rc_bugs = _rc

if `rc_bugs' == 0 {
    disp _newline "{result:✓ BUG TESTS PASSED}" _newline
    local ++suite_count
}
else {
    local overall_rc = 1
    disp _newline "{err:✗ BUG TESTS FAILED}" _newline
    local ++suite_count
}

//========================================================
// RUN CORE FUNCTIONALITY TESTS
//========================================================
disp _newline "{title:Running CORE tests...}" _newline
cap noisily do test/unit/test_units_core.do
local rc_core = _rc

if `rc_core' == 0 {
    disp _newline "{result:✓ CORE TESTS PASSED}" _newline
    local ++suite_count
}
else {
    local overall_rc = 1
    disp _newline "{err:✗ CORE TESTS FAILED}" _newline
    local ++suite_count
}

//========================================================
// RUN ADVANCED FEATURE TESTS
//========================================================
disp _newline "{title:Running ADVANCED tests...}" _newline
cap noisily do test/unit/test_units_advanced.do
local rc_advanced = _rc

if `rc_advanced' == 0 {
    disp _newline "{result:✓ ADVANCED TESTS PASSED}" _newline
    local ++suite_count
}
else {
    local overall_rc = 1
    disp _newline "{err:✗ ADVANCED TESTS FAILED}" _newline
    local ++suite_count
}

//========================================================
// FINAL SUMMARY
//========================================================
disp _newline "{hline 70}"
disp "{bf:MASTER TEST SUMMARY}"
disp "{hline 70}"
disp "Test suites run: `suite_count'"

if `overall_rc' == 0 {
    disp _newline "{result:✓ SUCCESS: All test suites completed successfully.}" _newline
    exit 0
}
else {
    disp _newline "{err:✗ FAILURE: Some test suites had failures.}" _newline
    noi print_test_summary
}

/* End of test runner */
