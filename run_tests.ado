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
    cls
    
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
    
    noi print_test_summary
    local n_fail = r(n_fail)
    
    // ============================================================
    // CLEANUP AND EXIT
    // ============================================================
    
    // Clean up frame
    cap frame drop ${ct_test_results_frame}
    
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
    disp _newline "{hline 70}"
    if `overall_rc' == 0 {
        disp "{result:✓ SUCCESS: All tests passed}" _newline
    } 
    else {
        disp "{err:✗ FAILURE: Some tests failed}" _newline
    }
    disp "{hline 70}" _newline
    
    // Return results
    return scalar n_fail = `n_fail'
    return scalar rc = `overall_rc'
    
    // Exit with appropriate code
    exit `overall_rc'
    
end

/* End of run_tests.ado */

*! version 0.0.1