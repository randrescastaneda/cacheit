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
    cap noisily `command'
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
