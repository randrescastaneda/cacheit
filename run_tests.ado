/*==================================================
Test Runner for cacheit Package
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Master test runner with pause debugging support
==================================================*/

cap program drop run_tests
program define run_tests, rclass
    syntax [anything(name=subcmd id="subcommand")], ///
        [                                             ///
            pause                                     ///
            *                                         ///
        ]
    
    version 16.1
    
    // ============================================================
    // SETUP
    // ============================================================
    
    // Save current directory
    local pwd = c(pwd)
    
    // Handle cache_dir_dev global
    if ("${cache_dir_dev}" != "") {
        cd "${cache_dir_dev}"
    }
    
    // Configure pause state for test files
    if ("`pause'" == "pause") {
        global ct_test_pause "pause"
        pause on
    } 
    else {
        global ct_test_pause ""
        pause off
    }
    
    // Determine which test suites to run
    if ("`subcmd'" == "") {
        // No argument: run all tests
        local suites "bugs core advanced"
    } 
    else if inlist("`subcmd'", "bugs", "core", "advanced") {
        // Valid suite specified
        local suites "`subcmd'"
    } 
    else {
        disp "{err:ERROR: Invalid test suite: `subcmd'}"
        disp "{text:Valid options: bugs, core, advanced, or leave blank for all}"
        cd "`pwd'"
        exit 198
    }
    
    // ============================================================
    // INITIALIZE TEST RESULTS FRAME (once for all suites)
    // ============================================================
    
    clear all
    set more off
    
    // Source test utilities
    do test/test_utils.ado
    cls // clean console

    // Initialize single frame for all tests
    init_test_results "cacheit Test Suite"
    
    // ============================================================
    // DISPLAY HEADER
    // ============================================================
    
    disp _newline "{title:CACHEIT TEST SUITE RUNNER}" _newline
    
    // ============================================================
    // RUN BUG-SPECIFIC TESTS
    // ============================================================
    
    if strpos("`suites'", "bugs") > 0 {
        disp _newline "{title:Running BUG tests...}" _newline
        cap do test/unit/test_units_bugs.do
    }
    
    // ============================================================
    // RUN CORE FUNCTIONALITY TESTS
    // ============================================================
    
    if strpos("`suites'", "core") > 0 {
        disp _newline "{title:Running CORE tests...}" _newline
        cap do test/unit/test_units_core.do
    }
    
    // ============================================================
    // RUN ADVANCED FEATURE TESTS
    // ============================================================
    
    if strpos("`suites'", "advanced") > 0 {
        disp _newline "{title:Running ADVANCED tests...}" _newline
        cap do test/unit/test_units_advanced.do
    }
    
    // ============================================================
    // CONSOLIDATED TEST SUMMARY
    // ============================================================
    
    local n_pass = 0
    local n_fail = 0
    local n_skip = 0
    
    // Count results from frame
    frame $ct_test_results_frame {
        qui count if status == "pass"
        local n_pass = r(N)
        qui count if status == "fail"
        local n_fail = r(N)
        qui count if status == "skip"
        local n_skip = r(N)
    }
    
    local total = `n_pass' + `n_fail' + `n_skip'
    
    // ============================================================
    // DISPLAY SIMPLE SUMMARY
    // ============================================================
    
    disp _newline "{hline 70}"
    disp "{bf:TEST RESULTS SUMMARY}"
    disp "{hline 70}"
    disp _newline "Passed:  {result:`n_pass'}/{result:`total'}"
    if `n_fail' > 0 {
        disp "Failed:  {err:`n_fail'}/{result:`total'}"
    } 
    else {
        disp "Failed:  {result:`n_fail'}/{result:`total'}"
    }
    if `n_skip' > 0 {
        disp "Skipped: {text:`n_skip'}/{result:`total'}"
    } 
    else {
        disp "Skipped: {result:`n_skip'}/{result:`total'}"
    }
    disp _newline "{hline 70}"
    
    // ============================================================
    // FRAME AVAILABILITY MESSAGE
    // ============================================================
    
    disp _newline "{bf:Test Results Frame}"
    disp "{text:Frame name: {result:__cacheit_test_results}}"
    disp "{text:  Load frame:  {input:cwf __cacheit_test_results}}"
    disp "{text:  View data:   {input:list}}"
    disp "{text:  Return info: {input:frame dir}}" _newline
    
    // ============================================================
    // CLEANUP AND EXIT
    // ============================================================
    
    // NOTE: Frame is kept available for data inspection
    // Do NOT drop the frame here
    
    // Reset pause state
    pause off
    
    // Restore working directory
    cd "`pwd'"
    
    // Determine exit code
    local overall_rc = 0
    if `n_fail' > 0 {
        local overall_rc = 1
    }
    
    // Display final message
    if `overall_rc' == 0 {
        disp "{result:✓ SUCCESS: All tests passed}" _newline
    } 
    else {
        disp "{err:✗ FAILURE: Some tests failed}" _newline
        disp "{text:Use the frame to inspect detailed failure information.}" _newline
    }
    
    // Return results
    return scalar n_fail = `n_fail'
    return scalar n_pass = `n_pass'
    return scalar n_skip = `n_skip'
    return scalar n_total = `total'
    return scalar rc = `overall_rc'
    
    // Only exit in batch mode (allows frame inspection in interactive mode)

    noi disp "type {cmd:  cwf __cacheit_test_results}"
    if c(mode) == "batch" {
        exit `overall_rc'
    }
    
end

/* End of run_tests.ado */

*! version 0.0.2