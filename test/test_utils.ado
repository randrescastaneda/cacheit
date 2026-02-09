/*==================================================
Test Utilities for cacheit Package
Author:        Testing Framework
E-mail:        testing@cacheit.org
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Provides assertion and test utilities
==================================================*/

/*
USAGE:
    source test_utils.ado before running tests
    
FUNCTIONS:
    - assert_equal(value1, value2, "message")
    - assert_scalar(value, "message")
    - assert_file_exists(path, "message")
    - assert_variable_exists(varname, "message")
    - assert_no_error()
    - test_pass(testname)
    - test_fail(testname, message)
*/
discard

program define assert_equal
    args value1 value2 message
    
    if "`value1'" != "`value2'" {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Expected: `value2'}"
        disp "{err:Got:      `value1'}"
        error 1
    }
end

program define assert_scalar
    args value message
    
    if mi(`value') {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Value is missing: `value'}"
        error 1
    }
end

program define assert_file_exists
    args filepath message
    
    mata: if (!fileexists("`filepath'")) {
        st_local("exists", "0")
    }
    else {
        st_local("exists", "1")
    }
    
    if "`exists'" == "0" {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:File not found: `filepath'}"
        error 1
    }
end

program define assert_variable_exists
    args varname message
    
    cap describe `varname'
    if _rc != 0 {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Variable not found: `varname'}"
        error 1
    }
end

program define assert_variable_missing
    args varname message
    
    cap describe `varname'
    if _rc == 0 {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Variable should not exist: `varname'}"
        error 1
    }
end

program define assert_frame_exists
    args framename message
    
    cap frame describe `framename'
    if _rc != 0 {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Frame not found: `framename'}"
        error 1
    }
end

program define assert_frame_missing
    args framename message
    
    cap frame describe `framename'
    if _rc == 0 {
        disp "{err:ASSERTION FAILED: `message'}"
        disp "{err:Frame should not exist: `framename'}"
        error 1
    }
end

program define test_pass
    args testname
    disp "{result:✓ PASS}: `testname'"
end

program define test_fail
    args testname message
    disp "{err:✗ FAIL}: `testname'"
    disp "{err:`message'}"
    error 1
end

program define test_skip
    args testname reason
    disp "{text:⊘ SKIP}: `testname' ({inp:`reason'})"
end

program define cleanup_cache
    args cache_dir
    
    // Check if directory exists
    mata: if (direxists("`cache_dir'")) {
        stata("cap cacheit clean, dir(\"" + "`cache_dir'" + "\")")
    }
end

/* End of test_utils.ado */
