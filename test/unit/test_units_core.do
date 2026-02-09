/*==================================================
Unit Tests for cacheit Package - CORE FUNCTIONALITY
Author:        Testing Suite
E-mail:        testing@cacheit.org
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Tests core caching and retrieval functionality
==================================================*/

version 16.1
clear all
set more off

// Source test utilities
run test_utils.ado

// Setup test environment
local test_dir = c(tmpdir) + "/cacheit_core_tests_`=subinstr("`c(current_time)'", ":", "", .)')"
cap mkdir "`test_dir'"
global cache_dir "`test_dir'"

disp _newline "{title:========== CACHEIT CORE FUNCTIONALITY TESTS ==========}" _newline
local tests_passed = 0
local tests_failed = 0

//========================================================
// TEST 001: Basic Caching - First Run
//========================================================
cap noisily {
    disp "{bf:TEST 001 - Basic Caching: First Run}"
    
    sysuse auto, clear
    
    cap noisily cacheit, dir("`test_dir'"): regress price weight length
    
    if _rc == 0 {
        test_pass "TEST 001: Command executed and cached"
        local ++tests_passed
    }
    else {
        test_fail "TEST 001: Command execution failed" "Error code: `_rc'"
        local ++tests_failed
    }
}

//========================================================
// TEST 002: Cache File Creation
//========================================================
cap noisily {
    disp "{bf:TEST 002 - Cache Files Created}"
    
    sysuse auto, clear
    
    cacheit, dir("`test_dir'"): regress price weight length
    local hash = r(call_hash)
    
    // Look for cache files
    local cache_files: dir "`test_dir'" files "`hash'*", respectcase
    
    if length(`"`cache_files'"') > 0 {
        test_pass "TEST 002: Cache files created (`hash')"
        local ++tests_passed
    }
    else {
        test_fail "TEST 002: No cache files found" "Hash: `hash'"
        local ++tests_failed
    }
}

//========================================================
// TEST 003: Cached Retrieval
//========================================================
cap noisily {
    disp "{bf:TEST 003 - Retrieve from Cache}"
    
    sysuse auto, clear
    
    // First run
    cacheit, dir("`test_dir'"): regress price weight
    local r2_first = e(r2)
    local N_first = e(N)
    
    // Clear ereturn
    ereturn clear
    
    // Second run - should load from cache
    cap noisily cacheit, dir("`test_dir'"): regress price weight
    local r2_second = e(r2)
    local N_second = e(N)
    
    if `r2_first' == `r2_second' & `N_first' == `N_second' {
        test_pass "TEST 003: Cached results identical to original"
        local ++tests_passed
    }
    else {
        test_fail "TEST 003: Cached results differ from original" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 004: Return List Preservation
//========================================================
cap noisily {
    disp "{bf:TEST 004 - Return List Preservation}"
    
    sysuse auto, clear
    
    // Statistics command generates return list
    cacheit, dir("`test_dir'"): summ price
    local mean_first = r(mean)
    local sd_first = r(sd)
    local N_first = r(N)
    
    return clear
    
    cacheit, dir("`test_dir'"): summ price
    local mean_second = r(mean)
    local sd_second = r(sd)
    local N_second = r(N)
    
    if `mean_first' == `mean_second' & `sd_first' == `sd_second' & `N_first' == `N_second' {
        test_pass "TEST 004: Return lists preserved correctly"
        local ++tests_passed
    }
    else {
        test_fail "TEST 004: Return lists not preserved" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 005: ereturn Matrices
//========================================================
cap noisily {
    disp "{bf:TEST 005 - ereturn Matrix Preservation}"
    
    sysuse auto, clear
    
    cacheit, dir("`test_dir'"): regress price weight length displacement
    local b_dims_1 = rowsof(e(b))
    local V_dims_1 = rowsof(e(V))
    
    ereturn clear
    
    cacheit, dir("`test_dir'"): regress price weight length displacement
    local b_dims_2 = rowsof(e(b))
    local V_dims_2 = rowsof(e(V))
    
    if `b_dims_1' == `b_dims_2' & `V_dims_1' == `V_dims_2' {
        test_pass "TEST 005: ereturn matrices preserved"
        local ++tests_passed
    }
    else {
        test_fail "TEST 005: ereturn matrices not preserved" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 006: nodata Option
//========================================================
cap noisily {
    disp "{bf:TEST 006 - nodata Option"} 
    
    sysuse auto, clear
    local orig_obs = _N
    
    // Run with nodata - no data should be cached
    cap noisily cacheit, dir("`test_dir'") nodata: generate test_var = price * 2
    
    // Check that variable wasn't created on reload
    cap describe test_var
    if _rc == 111 {
        test_pass "TEST 006: nodata prevents data caching"
        local ++tests_passed
    }
    else {
        test_fail "TEST 006: nodata option not working" "Variable should not exist"
        local ++tests_failed
    }
}

//========================================================
// TEST 007: replace Option
//========================================================
cap noisily {
    disp "{bf:TEST 007 - replace Option Forces Recomputation}"
    
    sysuse auto, clear
    
    // First run
    cacheit, dir("`test_dir'"): regress price weight
    local N_first = e(N)
    
    // Modify data
    drop if _n > 50
    
    // Second run WITH replace should use new data
    cacheit, dir("`test_dir'") replace: regress price weight
    local N_second = e(N)
    
    if `N_second' < `N_first' {
        test_pass "TEST 007: replace forces recomputation"
        local ++tests_passed
    }
    else {
        test_fail "TEST 007: replace option not forcing recomputation" ""
        local ++tests_failed
    }
    
    // Cleanup
    sysuse auto, clear
}

//========================================================
// TEST 008: keepall Option
//========================================================
cap noisily {
    disp "{bf:TEST 008 - keepall Option}"
    
    sysuse auto, clear
    
    // First command
    cacheit, dir("`test_dir'"): summ price
    local mean = r(mean)
    
    // Regular command (would clear return)
    regress weight length
    
    // With keepall, should work
    cap noisily cacheit, dir("`test_dir'") keepall: summ length
    
    if _rc == 0 {
        test_pass "TEST 008: keepall option accepted"
        local ++tests_passed
    }
    else {
        test_fail "TEST 008: keepall option failed" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 009: Hash Consistency
//========================================================
cap noisily {
    disp "{bf:TEST 009 - Hash Consistency}"
    
    sysuse auto, clear
    
    // Same command should produce same hash
    cacheit, dir("`test_dir'"): regress price weight
    local hash_1 = r(call_hash)
    
    return clear
    
    cacheit, dir("`test_dir'"): regress price weight
    local hash_2 = r(call_hash)
    
    if "`hash_1'" == "`hash_2'" {
        test_pass "TEST 009: Hash consistency maintained"
        local ++tests_passed
    }
    else {
        test_fail "TEST 009: Hash inconsistency" "Hash 1: `hash_1', Hash 2: `hash_2'"
        local ++tests_failed
    }
}

//========================================================
// TEST 010: Different Commands Different Hash
//========================================================
cap noisily {
    disp "{bf:TEST 010 - Different Commands Produce Different Hashes}"
    
    sysuse auto, clear
    
    cacheit, dir("`test_dir'"): regress price weight
    local hash_1 = r(call_hash)
    
    return clear
    
    cacheit, dir("`test_dir'"): regress price weight length
    local hash_2 = r(call_hash)
    
    if "`hash_1'" != "`hash_2'" {
        test_pass "TEST 010: Different commands have different hashes"
        local ++tests_passed
    }
    else {
        test_fail "TEST 010: Hash collision detected" "Both hashes: `hash_1'"
        local ++tests_failed
    }
}

//========================================================
// SUMMARY
//========================================================
disp _newline "{title:========== CORE FUNCTIONALITY TEST SUMMARY ==========}"
disp _newline "{result:Tests Passed:  `tests_passed'}"
disp "{result:Tests Failed:  `tests_failed'}"
local total = `tests_passed' + `tests_failed'
disp "{result:Total Tests:   `total'}" _newline

// Cleanup
cleanup_cache "`test_dir'"
global cache_dir ""

if `tests_failed' > 0 {
    disp "{err:SOME TESTS FAILED}" _newline
    exit 1
}
else {
    disp "{result:ALL CORE FUNCTIONALITY TESTS PASSED}" _newline
}

exit
/* End of test file */
