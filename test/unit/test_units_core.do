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

disp _newline "{title:Running Core Functionality Tests...}" _newline
local tests_passed = 0
local tests_failed = 0

//========================================================
// TEST 001: Basic Caching - First Run
//========================================================
cap noisily {
    
    sysuse auto, clear
    
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length"'
    cap `cmd_line'
    
    if _rc == 0 {
        test_pass "TEST 001"
        local ++tests_passed
    }
    else {
        test_fail "TEST 001" "Command execution failed" "Error code: `_rc'" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 002: Cache File Creation
//========================================================
cap noisily {
    
    sysuse auto, clear
    
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length"'
    cap `cmd_line'
    local hash = r(call_hash)
    
    // Look for cache files
    local cache_files: dir "`test_dir'" files "`hash'*", respectcase
    
    if length(`"`cache_files'"') > 0 {
        test_pass "TEST 002"
        local ++tests_passed
    }
    else {
        test_fail "TEST 002" "Cache file creation" "No cache files found for hash: `hash'" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 003: Cached Retrieval
//========================================================
cap noisily {
    
    sysuse auto, clear
    
    // First run
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
    cap `cmd_line'
    local r2_first = e(r2)
    local N_first = e(N)
    
    // Clear ereturn
    ereturn clear
    
    // Second run - should load from cache
    cap `cmd_line'
    local r2_second = e(r2)
    local N_second = e(N)
    
    if `r2_first' == `r2_second' & `N_first' == `N_second' {
        test_pass "TEST 003"
        local ++tests_passed
    }
    else {
        test_fail "TEST 003" "Cached results differ from original" "r2: `r2_first' vs `r2_second', N: `N_first' vs `N_second'" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 004: Return List Preservation
//========================================================
cap noisily {
    
    sysuse auto, clear
    
    local cmd_line `"cacheit, dir("`test_dir'"): summ price"'
    cap `cmd_line'
    local mean_first = r(mean)
    local sd_first = r(sd)
    local N_first = r(N)
    
    return clear
    
    cap `cmd_line'
    local mean_second = r(mean)
    local sd_second = r(sd)
    local N_second = r(N)
    
    if `mean_first' == `mean_second' & `sd_first' == `sd_second' & `N_first' == `N_second' {
        test_pass "TEST 004"
        local ++tests_passed
    }
    else {
        test_fail "TEST 004" "Return list preservation" "mean/sd/N mismatch" `"`cmd_line'"'
        test_fail "TEST 004: Return lists not preserved" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 005: ereturn Matrices
//========================================================
cap noisily {
    
    sysuse auto, clear
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length displacement"'
    cap `cmd_line'
    local b_dims_1 = rowsof(e(b))
    local V_dims_1 = rowsof(e(V))
    
    ereturn clear
    
    cap `cmd_line'
    local b_dims_2 = rowsof(e(b))
    local V_dims_2 = rowsof(e(V))
    
    if `b_dims_1' == `b_dims_2' & `V_dims_1' == `V_dims_2' {
        test_pass "TEST 005"
        local ++tests_passed
    }
    else {
        test_fail "TEST 005" "ereturn matrices preservation" "Matrix dimensions mismatch" `"`cmd_line'"'
        test_fail "TEST 005: ereturn matrices not preserved" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 006: nodata Option
//========================================================
cap noisily {

    
    sysuse auto, clear
    local orig_obs = _N
    local cmd_line `"cacheit, dir("`test_dir'") nodata: generate test_var = price * 2"'
    cap `cmd_line'
    
    // Check that variable wasn't created on reload
    cap describe test_var
    if _rc == 111 {
        test_pass "TEST 006"
        local ++tests_passed
    }
    else {
        test_fail "TEST 006" "nodata option" "Variable should not exist after reload" `"`cmd_line'"'
    else {
        test_fail "TEST 006: nodata option not working" "Variable should not exist"
        local ++tests_failed
    }
}

//========================================================
// TEST 007: replace Option
//========================================================
cap noisily {
    
    sysuse auto, clear
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
    cap `cmd_line'
    local N_first = e(N)
    
    // Modify data
    drop if _n > 50
    
    // Second run WITH replace should use new data
    local cmd_line_replace `"cacheit, dir("`test_dir'") replace: regress price weight"'
    cap `cmd_line_replace'
    local N_second = e(N)
    
    if `N_second' < `N_first' {
        test_pass "TEST 007"
        local ++tests_passed
    }
    else {
        test_fail "TEST 007" "replace option" "replace not forcing recomputation" `"`cmd_line_replace'"'
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
    
    sysuse auto, clear
    
    // First command
    cacheit, dir("`test_dir'"): summ price
    local mean = r(mean)
    
    local cmd_line `"cacheit, dir("`test_dir'") keepall: summ length"'
    cap `cmd_line'
    
    if _rc == 0 {
        test_pass "TEST 008"
        local ++tests_passed
    }
    else {
        test_fail "TEST 008" "keepall option" "keepall option failed" `"`cmd_line'"'
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
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
    cap `cmd_line'
    local hash_1 = r(call_hash)
    
    return clear
    
    cap `cmd_line'
    local hash_2 = r(call_hash)
    
    if "`hash_1'" == "`hash_2'" {
        test_pass "TEST 009"
        local ++tests_passed
    }
    else {
        test_fail "TEST 009" "Hash consistency" "Hash 1: `hash_1', Hash 2: `hash_2'" `"`cmd_line'"'
        local ++tests_passed
    }
    else {
        test_fail "TEST 009: Hash inconsistency" "Hash 1: `hash_1', Hash 2: `hash_2'"
        local ++tests_failed
    }
}

//========================================================
// TEST 010: Different Commands Different Hash
//==local cmd_line_1 `"cacheit, dir("`test_dir'"): regress price weight"'
    cap `cmd_line_1'
    local hash_1 = r(call_hash)
    
    return clear
    
    local cmd_line_2 `"cacheit, dir("`test_dir'"): regress price weight length"'
    cap `cmd_line_2'
    local hash_2 = r(call_hash)
    
    if "`hash_1'" != "`hash_2'" {
        test_pass "TEST 010"
        local ++tests_passed
    }
    else {
        test_fail "TEST 010" "Hash collision" "Both commands produced same hash: `hash_1'" `"`cmd_line_1'"'
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
cleanup_cache "`test_dir'"
global cache_dir ""

local total = `tests_passed' + `tests_failed'
disp _newline "{result:Core Tests: `tests_passed' passed, `tests_failed' failed (out of `total'))}" _newline

if `tests_failed' > 0 {
    exit 1
}

exit
/* End of test file */
