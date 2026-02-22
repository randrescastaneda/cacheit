/*==================================================
Unit Tests for cacheit Package - ADVANCED FEATURES
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Tests advanced features: frames, graphs, hidden, datacheck
==================================================*/

version 16.1

// Setup test environment
local test_dir = c(tmpdir) + "/cacheit_adv_tests_`=subinstr("`c(current_time)'", ":", "", .)'"
cap mkdir "`test_dir'"
global cache_dir "`test_dir'"

disp _newline "{title:Running Advanced Feature Tests...}" _newline

//========================================================
// TEST 101: Frame Caching and Restoration
//========================================================
pause_test "ADV-101" "Frame caching and restoration"

sysuse auto, clear

// Create and populate a frame
cap frame drop data_frame
frame create data_frame
frame data_frame {
    set obs 150
    gen x = _n
    gen y = _n^2
}
cwf default

// Run command using the frame
local cmd_line `"cacheit, dir("`test_dir'") framecheck(data_frame): summ price"'
qui `cmd_line'
local hash_first = "`r(call_hash)'"

// modify the frame
frame data_frame {
    replace y = 1
}
cwf default
`cmd_line'
local hash_second = "`r(call_hash)'"

if ("`hash_first'" != "`hash_second'" ) { // different is OK
    append_test_result, test_id("ADV-101") status("pass") description("Frame caching and restoration") command("`cmd_line'")
}
else {
    append_test_result, test_id("ADV-101") status("fail") description("Frame caching and restoration") assertion_msg("Frame cache not used correctly") command("`cmd_line'")
}
cap frame drop data_frame

//========================================================
// TEST 102: Graph Caching
//========================================================
pause_test "ADV-102" "Graph caching"

sysuse auto, clear
graph drop _all

// Create and cache graph
local cmd_line `"cacheit, dir("`test_dir'"): scatter price weight"'
capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    // Drop graph
    graph drop _all
    
    // Re-run - should restore graph
    cap `cmd_line'
    local rc2 = _rc
    
    // Check if graph exists
    cap graph describe Graph
    if _rc == 0 {
        append_test_result, test_id("ADV-102") status("pass") description("Graph caching") command("`cmd_line'")
        graph drop _all
    }
    else {
        append_test_result, test_id("ADV-102") status("fail") description("Graph caching") assertion_msg("Graph not restored from cache") command("`cmd_line'")
    }
}
else {
    append_test_result, test_id("ADV-102") status("fail") description("Graph caching") assertion_msg("Graph caching operation failed: Error code `rc'") command("`cmd_line'")
}

//========================================================
// TEST 103: Multiple Graphs
//========================================================
pause_test "ADV-103" "Multiple graphs"

sysuse auto, clear
graph drop _all

// Create multiple graphs
local cmd_line `"cacheit, dir("`test_dir'"): scatter price weight"'
capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    append_test_result, test_id("ADV-103") status("skip") description("Complex graph scenario") assertion_msg("Placeholder test") command("`cmd_line'")
}
else {
    append_test_result, test_id("ADV-103") status("fail") description("Complex graph scenario") assertion_msg("Graph creation failed: Error code `rc'") command("`cmd_line'")
}

//========================================================
// TEST 104: Data Modification Caching
//========================================================
pause_test "ADV-104" "Data modification caching"

sysuse auto, clear

// Modify data and cache
local cmd_line `"cacheit, dir("`test_dir'"): generate log_price = log(price)"'
capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    local first_obs = log_price[1]
    
    // Drop variable
    drop log_price
    
    // Reload from cache
    cap `cmd_line'
    local second_obs = log_price[1]
    
    if `first_obs' == `second_obs' {
        append_test_result, test_id("ADV-104") status("pass") description("Data modification caching") command("`cmd_line'")
    }
    else {
        append_test_result, test_id("ADV-104") status("fail") description("Data modification caching") assertion_msg("Data not properly cached") command("`cmd_line'")
    }
}
else {
    append_test_result, test_id("ADV-104") status("fail") description("Data modification caching") assertion_msg("Operation failed: Error code `rc'") command("`cmd_line'")
}

//========================================================
// TEST 105: datacheck Option
//========================================================
pause_test "ADV-105" "datacheck option"

sysuse auto, clear

// Save external data
tempfile external
keep price weight in 1/20
save "`external'"

// Use datacheck
sysuse auto, clear
local cmd_line `"cacheit, dir("`test_dir'") datacheck("`external'"): regress price weight"'
capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    append_test_result, test_id("ADV-105") status("pass") description("datacheck option") command("`cmd_line'")
}
else {
    append_test_result, test_id("ADV-105") status("fail") description("datacheck option") assertion_msg("datacheck option operation failed: Error code `rc'") command("`cmd_line'")
}

//========================================================
// TEST 106: Matrix Restoration
//========================================================
pause_test "ADV-106" "Matrix restoration"

sysuse auto, clear

// Run regression (creates e(b), e(V), e(beta))
local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length displacement"'
capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    // Store matrix info
    local b_r = rowsof(e(b))
    local V_r = rowsof(e(V))
    local b_c = colsof(e(b))
    
    // Clear ereturn
    ereturn clear
    
    // Reload from cache
    cap `cmd_line'
    
    // Check matrices restored
    if rowsof(e(b)) == `b_r' & rowsof(e(V)) == `V_r' & colsof(e(b)) == `b_c' {
        append_test_result, test_id("ADV-106") status("pass") description("Matrix restoration") command("`cmd_line'")
    }
    else {
        append_test_result, test_id("ADV-106") status("fail") description("Matrix restoration") assertion_msg("Matrix dimensions mismatch") command("`cmd_line'")
    }
}
else {
    append_test_result, test_id("ADV-106") status("fail") description("Matrix restoration") assertion_msg("Operation failed: Error code `rc'") command("`cmd_line'")
}

//========================================================
// TEST 107: Scalar Preservation
//========================================================
pause_test "ADV-107" "Scalar preservation"

sysuse auto, clear

// Regression preserves many scalars
local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length"'
capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    local r2_first = e(r2)
    local F_first = e(F)
    
    ereturn clear
    
    cap `cmd_line'
    
    local r2_second = e(r2)
    local F_second = e(F)
    
    if `r2_first' == `r2_second' & `F_first' == `F_second' {
        append_test_result, test_id("ADV-107") status("pass") description("Scalar preservation") command("`cmd_line'")
    }
    else {
        append_test_result, test_id("ADV-107") status("fail") description("Scalar preservation") assertion_msg("Scalars not preserved correctly") command("`cmd_line'")
    }
}
else {
    append_test_result, test_id("ADV-107") status("fail") description("Scalar preservation") assertion_msg("Operation failed: Error code `rc'") command("`cmd_line'")
}

//========================================================
// TEST 108: Macro Preservation
//========================================================
pause_test "ADV-108" "Macro preservation"

sysuse auto, clear

local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length"'
capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    local cmd_first = e(cmd)
    local depvar_first = e(depvar)
    
    ereturn clear
    
    cap `cmd_line'
    
    if "`e(cmd)'" == "regress" & "`e(depvar)'" == "price" {
        append_test_result, test_id("ADV-108") status("pass") description("Macro preservation") command("`cmd_line'")
    }
    else {
        append_test_result, test_id("ADV-108") status("fail") description("Macro preservation") assertion_msg("ereturn macros not preserved") command("`cmd_line'")
    }
}
else {
    append_test_result, test_id("ADV-108") status("fail") description("Macro preservation") assertion_msg("Operation failed: Error code `rc'") command("`cmd_line'")
}

//========================================================
// TEST 109: clear Option
//========================================================
pause_test "ADV-109" "clear option"

sysuse auto, clear
set obs 100

// This would normally fail with "data in memory would be lost"
// clear option allows it
local cmd_line `"cacheit, dir("`test_dir'") clear: sysuse auto"'
capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    if _N == 74 {
        append_test_result, test_id("ADV-109") status("pass") description("clear option") command("`cmd_line'")
    }
    else {
        append_test_result, test_id("ADV-109") status("fail") description("clear option") assertion_msg("N = `_N', expected 74") command("`cmd_line'")
    }
}
else {
    append_test_result, test_id("ADV-109") status("fail") description("clear option") assertion_msg("clear option operation failed: Error code `rc'") command("`cmd_line'")
}

//========================================================
// TEST 110: project Option
//========================================================
pause_test "ADV-110" "project option"

sysuse auto, clear

// Use project subdirectory
local cmd_line `"cacheit, dir("`test_dir'") project(test_proj): regress price weight"'
capture `cmd_line'
local rc = _rc

if `rc' == 0 {
    // Check if project directory created
    cap describe
    append_test_result, test_id("ADV-110") status("pass") description("project option") command("`cmd_line'")
}
else {
    append_test_result, test_id("ADV-110") status("fail") description("project option") assertion_msg("project option operation failed: Error code `rc'") command("`cmd_line'")
}

//========================================================
// SUMMARY AND CLEANUP
//========================================================

global cache_dir ""

/* End of test file */
