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

// Initialize test results frame
init_test_results, suite_name("Core Functionality")

// Setup test environment
local test_dir = c(tmpdir) + "cacheit_core_tests_`=subinstr("`c(current_time)'", ":", "", .)'"
cap mkdir "`test_dir'"
global cache_dir "`test_dir'"

disp _newline "{title:Running Core Functionality Tests...}" _newline

//========================================================
// TEST 001: Basic Caching - First Run
//========================================================
sysuse auto, clear
local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length"'
quietly capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    append_test_result, test_id("CORE-001") status("pass") description("Basic caching - first run") command("`cmd_line'")
}
else {
    append_test_result, test_id("CORE-001") status("fail") description("Basic caching - first run") assertion_msg("Error code: `rc'") command("`cmd_line'")
}

//========================================================
// TEST 002: Cache File Creation
//========================================================
sysuse auto, clear
local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length"'
quietly capture `cmd_line'
local hash = r(call_hash)

// Look for cache files
local cache_files: dir "`test_dir'" files "`hash'*", respectcase

if length(`"`cache_files'"') > 0 {
    append_test_result, test_id("CORE-002") status("pass") description("Cache file creation") command("`cmd_line'")
}
else {
    append_test_result, test_id("CORE-002") status("fail") description("Cache file creation") assertion_msg("No cache files found for hash: `hash'") command("`cmd_line'")
}

//========================================================
// TEST 003: Cached Retrieval
//========================================================
sysuse auto, clear

// First run
local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
quietly capture `cmd_line'
local r2_first = e(r2)
local N_first = e(N)

// Clear ereturn
ereturn clear

// Second run - should load from cache
quietly capture `cmd_line'
local r2_second = e(r2)
local N_second = e(N)

if `r2_first' == `r2_second' & `N_first' == `N_second' {
    append_test_result, test_id("CORE-003") status("pass") description("Cached retrieval") command("`cmd_line'")
}
else {
    append_test_result, test_id("CORE-003") status("fail") description("Cached retrieval") assertion_msg("r2: `r2_first' vs `r2_second', N: `N_first' vs `N_second'") command("`cmd_line'")
}

//========================================================
// TEST 004: Return List Preservation
//========================================================
sysuse auto, clear

local cmd_line `"cacheit, dir("`test_dir'"): summ price"'
quietly capture `cmd_line'
local mean_first = r(mean)
local sd_first = r(sd)
local N_first = r(N)

return clear

quietly capture `cmd_line'
local mean_second = r(mean)
local sd_second = r(sd)
local N_second = r(N)

if `mean_first' == `mean_second' & `sd_first' == `sd_second' & `N_first' == `N_second' {
    append_test_result, test_id("CORE-004") status("pass") description("Return list preservation") command("`cmd_line'")
}
else {
    append_test_result, test_id("CORE-004") status("fail") description("Return list preservation") assertion_msg("mean/sd/N mismatch") command("`cmd_line'")
}

//========================================================
// TEST 005: ereturn Matrices
//========================================================
sysuse auto, clear
local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length displacement"'
quietly capture `cmd_line'
local b_dims_1 = rowsof(e(b))
local V_dims_1 = rowsof(e(V))

ereturn clear

quietly capture `cmd_line'
local b_dims_2 = rowsof(e(b))
local V_dims_2 = rowsof(e(V))

if `b_dims_1' == `b_dims_2' & `V_dims_1' == `V_dims_2' {
    append_test_result, test_id("CORE-005") status("pass") description("ereturn matrices preservation") command("`cmd_line'")
}
else {
    append_test_result, test_id("CORE-005") status("fail") description("ereturn matrices preservation") assertion_msg("Matrix dimensions mismatch") command("`cmd_line'")
}

//========================================================
// TEST 006: nodata Option
//========================================================
sysuse auto, clear
local orig_obs = _N
local cmd_line `"cacheit, dir("`test_dir'") nodata: generate test_var = price * 2"'
quietly capture `cmd_line'

// Check that variable wasn't created on reload
cap describe test_var
if _rc == 111 {
    append_test_result, test_id("CORE-006") status("pass") description("nodata option") command("`cmd_line'")
}
else {
    append_test_result, test_id("CORE-006") status("fail") description("nodata option") assertion_msg("Variable should not exist after reload") command("`cmd_line'")
}
//========================================================
// TEST 007: replace Option
//========================================================
sysuse auto, clear
local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
quietly capture `cmd_line'
local N_first = e(N)

// Modify data
drop if _n > 50

// Second run WITH replace should use new data
local cmd_line_replace `"cacheit, dir("`test_dir'") replace: regress price weight"'
quietly capture `cmd_line_replace'
local N_second = e(N)

if `N_second' < `N_first' {
    append_test_result, test_id("CORE-007") status("pass") description("replace option") command("`cmd_line_replace'")
}
else {
    append_test_result, test_id("CORE-007") status("fail") description("replace option") assertion_msg("replace not forcing recomputation") command("`cmd_line_replace'")
}

// Cleanup
sysuse auto, clear

//========================================================
// TEST 008: keepall Option
//========================================================
sysuse auto, clear

// First command
cacheit, dir("`test_dir'"): summ price
local mean = r(mean)

local cmd_line `"cacheit, dir("`test_dir'") keepall: summ length"'
quietly capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    append_test_result, test_id("CORE-008") status("pass") description("keepall option") command("`cmd_line'")
}
else {
    append_test_result, test_id("CORE-008") status("fail") description("keepall option") assertion_msg("keepall option failed") command("`cmd_line'")
}

//========================================================
// TEST 009: Hash Consistency
//========================================================
local cmd_line `"cacheit, dir("`test_dir'"): regress price weight"'
quietly capture `cmd_line'
local hash_1 = r(call_hash)

return clear

quietly capture `cmd_line'
local hash_2 = r(call_hash)

if "`hash_1'" == "`hash_2'" {
    append_test_result, test_id("CORE-009") status("pass") description("Hash consistency") command("`cmd_line'")
}
else {
    append_test_result, test_id("CORE-009") status("fail") description("Hash consistency") assertion_msg("Hash 1: `hash_1', Hash 2: `hash_2'") command("`cmd_line'")
}

//========================================================
// TEST 010: Different Commands Different Hash
//========================================================
sysuse auto, clear
local cmd_line_1 `"cacheit, dir("`test_dir'"): regress price weight"'
quietly capture `cmd_line_1'
local hash_1 = r(call_hash)

return clear

local cmd_line_2 `"cacheit, dir("`test_dir'"): regress price weight length"'
quietly capture `cmd_line_2'
local hash_2 = r(call_hash)

if "`hash_1'" != "`hash_2'" {
    append_test_result, test_id("CORE-010") status("pass") description("Hash collision detection") command("`cmd_line_1'")
}
else {
    append_test_result, test_id("CORE-010") status("fail") description("Hash collision detection") assertion_msg("Both commands produced same hash: `hash_1'") command("`cmd_line_1'")
}

//========================================================
// SUMMARY AND CLEANUP
//========================================================
cleanup_cache "`test_dir'"

print_test_summary
local return_code = r(n_fail) > 0
if `return_code' > 0 {
    disp "{err:Some tests failed.}"
    exit 1
}
else {
    disp "{result:All core tests passed!}"
}

exit
/* End of test file */
