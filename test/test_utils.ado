/*==================================================
Test Utilities for cacheit Package
Author:        Testing Framework
E-mail:        testing@cacheit.org
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Provides assertion and test utilities with frame-based result tracking
==================================================*/

/*
USAGE:
    source test_utils.ado before running tests
    
CORE FUNCTIONS:
    - init_test_results: Initialize the test results frame
    - append_test_result: Add a test result to the frame
    - run_test: Execute a test command with result tracking
    - check_test_frame_exists: Verify frame is initialized
    - print_test_summary: Display test results summary
    - save_test_report: Save results to disk
    
ASSERTION FUNCTIONS:
    - assert_equal(value1, value2, "message")
    - assert_scalar(value, "message")
    - assert_file_exists(path, "message")
    - assert_variable_exists(varname, "message")
    - assert_frame_exists(framename, "message")
    - assert_frame_missing(framename, "message")
*/

discard

// ============================================================
// TEST RESULTS FRAME INFRASTRUCTURE
// ============================================================

cap program drop init_test_results
program define init_test_results
    syntax, [framename(string) suite_name(string)]
    
    // Set defaults
    if "`framename'" == "" local framename "__cacheit_test_results"
    if "`suite_name'" == "" local suite_name "default"
    
    // Check if frame already exists
    cap frame describe `framename'
    if _rc == 0 {
        disp "{err:ERROR: Test results frame '`framename'' already exists.}"
        disp "{text:To start fresh, run: frame drop `framename'}"
        error 601
    }
    
    // Create the frame with proper structure for frame post
    frame create `framename' ///
        str20(test_id) ///
        str10(status) ///
        str60(description) ///
        str200(assertion_msg) ///
        str500(command)
    
    // Store frame name and initialization status in globals
    global __test_results_frame = "`framename'"
    global __test_results_init = 1
    global __test_suite_name = "`suite_name'"
    global __test_pass_count = 0
    global __test_fail_count = 0
    global __test_skip_count = 0
    
    disp "{text:Test results frame initialized: `framename'}"
end

cap program drop check_test_frame_exists
program define check_test_frame_exists
    
    if "${__test_results_init}" != "1" {
        disp "{err:ERROR: Test results frame not initialized.}"
        disp "{text:Run init_test_results at the start of your test file.}"
        error 601
    }
end

cap program drop append_test_result
program define append_test_result
    syntax, test_id(string) status(string) description(string) ///
        [assertion_msg(string) command(string)]
    
    check_test_frame_exists
    
    // Use frame post for efficient appending
    frame post ${__test_results_frame} ///
        ("`test_id'") ///
        ("`status'") ///
        ("`description'") ///
        ("`assertion_msg'") ///
        ("`command'")
    
    // Update global counters
    if "`status'" == "pass" {
        global __test_pass_count = ${__test_pass_count} + 1
    }
    else if "`status'" == "fail" {
        global __test_fail_count = ${__test_fail_count} + 1
    }
    else if "`status'" == "skip" {
        global __test_skip_count = ${__test_skip_count} + 1
    }
end

cap program drop print_test_summary
program define print_test_summary, rclass
    
    check_test_frame_exists
    
    local n_pass = ${__test_pass_count}
    local n_fail = ${__test_fail_count}
    local n_skip = ${__test_skip_count}
    local total = `n_pass' + `n_fail' + `n_skip'
    
    // Print summary
    disp _newline "{hline 70}"
    disp "{bf:TEST SUMMARY - ${__test_suite_name}}"
    disp "{hline 70}"
    disp "Passed:  {result:`n_pass'}/{result:`total'}"
    if `n_fail' > 0 disp "Failed:  {err:`n_fail'}/{result:`total'}"
    else disp "Failed:  {result:`n_fail'}/{result:`total'}"
    if `n_skip' > 0 disp "Skipped: {text:`n_skip'}/{result:`total'}"
    else disp "Skipped: {result:`n_skip'}/{result:`total'}"
    disp "{hline 70}" _newline
    
    // Show failed tests if any
    if `n_fail' > 0 {
        disp "{bf:{err:FAILED TESTS:}}"
        frame ${__test_results_frame} {
            list test_id description assertion_msg command if status == "fail", clean noobs
        }
        disp ""
    }
    
    return scalar n_pass = `n_pass'
    return scalar n_fail = `n_fail'
    return scalar n_skip = `n_skip'
    return scalar n_total = `total'
end

cap program drop save_test_report
program define save_test_report
    syntax, [filename(string) filepath(string)]
    
    check_test_frame_exists
    
    // Set defaults
    if "`filename'" == "" local filename = "test_results_${__test_suite_name}.dta"
    if "`filepath'" == "" local filepath = c(pwd)
    
    // Save frame data
    frame ${__test_results_frame} {
        qui save "`filepath'/`filename'", replace
    }
    
    disp "{text:Test results saved to: `filepath'/`filename'}"
end

// ============================================================
// TEST EXECUTION WRAPPER
// ============================================================

cap program drop run_test
program define run_test, rclass
    syntax, ///
        id(string) ///
        description(string) ///
        command(string) ///
        [noisily]
    
    check_test_frame_exists
    
    local test_status "pass"
    local error_msg ""
    local rc = 0
    
    // Display command if noisily requested
    if "`noisily'" != "" {
        disp "{text:Running: `command'}"
    }
    
    // Execute command with capture (suppress output by default)
    capture `command'
    local rc = _rc
    
    if `rc' != 0 {
        local test_status "fail"
        local error_msg "Error code: `rc'"
    }
    
    // Log result to frame
    append_test_result, ///
        test_id("`id'") ///
        status("`test_status'") ///
        description("`description'") ///
        assertion_msg("`error_msg'") ///
        command("`command'")
    
    return scalar rc = `rc'
    return local status = "`test_status'"
end

// ============================================================
// ASSERTION FUNCTIONS
// ============================================================
cap program drop assert_equal
program define assert_equal
    args value1 value2 message
    
    if "`value1'" != "`value2'" {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Expected: `value2'}"
        disp "{err:Got:      `value1'}"
        error 1
    }
end

cap program drop assert_scalar
program define assert_scalar
    args value message
    
    if mi(`value') {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Value is missing: `value'}"
        error 1
    }
end

cap program drop assert_file_exists
program define assert_file_exists
    args filepath message
    
    mata {
        if (!fileexists(st_local("filepath"))) {
            st_local("exists", "0")
        }
        else {
            st_local("exists", "1")
        }
    }
    
    if "`exists'" == "0" {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:File not found: `filepath'}"
        error 1
    }
end

cap program drop assert_variable_exists
program define assert_variable_exists
    args varname message
    
    cap describe `varname'
    if _rc != 0 {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Variable not found: `varname'}"
        error 1
    }
end

cap program drop assert_variable_missing
program define assert_variable_missing
    args varname message
    
    cap describe `varname'
    if _rc == 0 {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Variable should not exist: `varname'}"
        error 1
    }
end

cap program drop assert_frame_exists
program define assert_frame_exists
    args framename message
    
    cap frame describe `framename'
    if _rc != 0 {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Frame not found: `framename'}"
        error 1
    }
end

cap program drop assert_frame_missing
program define assert_frame_missing
    args framename message
    
    cap frame describe `framename'
    if _rc == 0 {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Frame should not exist: `framename'}"
        error 1
    }
end

// ============================================================
// LEGACY TEST FUNCTIONS (for backward compatibility)
// Note: These are deprecated. Use run_test() and append_test_result() instead
// ============================================================

cap program drop test_pass
program define test_pass
    args testname
    // Legacy function - now tracked via frame
end

cap program drop test_fail
program define test_fail
    args testname description message cmd
    noi disp "{err:✗ FAIL}: `testname'"
    if (`"`description'"' != `""') noi disp `"{err:  `description'}: `message'}"'
    if (`"`cmd'"' != `""') noi disp `"{text:  `cmd'}"'
end

cap program drop test_skip
program define test_skip
    args testname reason
    noi disp "{text:⊘ SKIP}: `testname'" 
    noi disp "{text:  Reason: `reason'}"
end

// ============================================================
// UTILITY FUNCTIONS
// ============================================================

cap program drop cleanup_cache
program define cleanup_cache
    args cache_dir
    
    // Check if directory exists
    mata: st_local("direxists", strofreal(direxists("`cache_dir'")))

    if ("`direxists'" == "1") {
        noi cacheit clean, dir("`cache_dir'") force
    }

end

/* End of test_utils.ado */
