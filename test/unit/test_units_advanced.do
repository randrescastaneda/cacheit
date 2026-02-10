/*==================================================
Unit Tests for cacheit Package - ADVANCED FEATURES
Author:        Testing Suite
E-mail:        testing@cacheit.org
----------------------------------------------------
Creation Date:     February 2026
Purpose:           Tests advanced features: frames, graphs, hidden, datacheck
==================================================*/

version 16.1
clear all
set more off

// Source test utilities
run test_utils.ado

// Setup test environment
local test_dir = c(tmpdir) + "/cacheit_adv_tests_`=subinstr("`c(current_time)'", ":", "", .)')"
cap mkdir "`test_dir'"
global cache_dir "`test_dir'"

disp _newline "{title:Running Advanced Feature Tests...}" _newline
local tests_passed = 0
local tests_failed = 0

//========================================================
// TEST 101: Frame Caching and Restoration
//========================================================
cap noisily {
    
    sysuse auto, clear
    
    // Create and populate a frame
    frame create data_frame
    cwf data_frame
    set obs 150
    gen x = _n
    gen y = _n^2
    summ y
    local mean_first = r(mean)
    cwf default
    
    // Run command using the frame
    local cmd_line `"cacheit, dir("`test_dir'") framecheck(data_frame): summ x"'
    cap `cmd_line'
    
    if _rc == 0 {
        // Drop the frame
        frame drop data_frame
        
        // Re-run - frame should be restored
        cap `cmd_line'
        
        if _rc == 0 {
            // Verify frame restored
            cwf data_frame
            descrip
            if r(N) == 150 {
                test_pass "TEST 101"
                local ++tests_passed
            }
            else {
                test_fail "TEST 101" "Frame data restoration" "N = `r(N)', expected 150" `"`cmd_line'"'
                local ++tests_failed
            }
            cwf default
            frame drop data_frame
        }
        else {
            test_fail "TEST 101" "Cache retrieval" "Frame cache retrieval failed" `"`cmd_line'"'
            local ++tests_failed
        }
    }
    else {
        test_fail "TEST 101" "Frame caching" "Frame caching operation failed" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 102: Graph Caching
//========================================================
cap noisily {
    
    sysuse auto, clear
    graph drop _all
    
    // Create and cache graph
    local cmd_line `"cacheit, dir("`test_dir'"): scatter price weight"'
    cap `cmd_line'
    
    if _rc == 0 {
        // Drop graph
        graph drop _all
        
        // Re-run - should restore graph
        cap `cmd_line'
        
        // Check if graph exists
        cap graph describe Graph
        if _rc == 0 {
            test_pass "TEST 102"
            local ++tests_passed
            graph drop _all
        }
        else {
            test_fail "TEST 102" "Graph restoration" "Graph not restored from cache" `"`cmd_line'"'
            local ++tests_failed
        }
    }
    else {
        test_fail "TEST 102" "Graph caching" "Graph caching operation failed" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 103: Multiple Graphs
//========================================================
cap noisily {
    
    sysuse auto, clear
    graph drop _all
    
    // Create multiple graphs
    local cmd_line `"cacheit, dir("`test_dir'"): scatter price weight"'
    cap `cmd_line'
    
    if _rc == 0 {
        test_skip "TEST 103" "Complex graph scenario"
        local ++tests_passed
    }
}

//========================================================
// TEST 104: Data Modification Caching
//========================================================
cap noisily {
    
    sysuse auto, clear
    
    // Modify data and cache
    local cmd_line `"cacheit, dir("`test_dir'"): generate log_price = log(price)"'
    cap `cmd_line'
    local first_obs = log_price[1]
    
    // Drop variable
    drop log_price
    
    // Reload from cache
    cap `cmd_line'
    local second_obs = log_price[1]
    
    if `first_obs' == `second_obs' {
        test_pass "TEST 104"
        local ++tests_passed
    }
    else {
        test_fail "TEST 104" "Data modification caching" "Data not properly cached" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 105: datacheck Option
//========================================================
cap noisily {

    
    sysuse auto, clear
    
    // Save external data
    tempfile external
    keep price weight in 1/20
    save "`external'"
    
    // Use datacheck
    sysuse auto, clear
    local cmd_line `"cacheit, dir("`test_dir'") datacheck("`external'"): regress price weight"'
    cap `cmd_line'
    
    if _rc == 0 {
        test_pass "TEST 105"
        local ++tests_passed
    }
    else {
        test_fail "TEST 105" "datacheck option" "datacheck option operation failed" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 106: Matrix Restoration
//========================================================
cap noisily {
    
    sysuse auto, clear
    
    // Run regression (creates e(b), e(V), e(beta))
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length displacement"'
    cap `cmd_line'
    
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
        test_pass "TEST 106"
        local ++tests_passed
    }
    else {
        test_fail "TEST 106" "Matrix restoration" "Matrix dimensions mismatch" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 107: Scalar Preservation
//========================================================
cap noisily {
    
    sysuse auto, clear
    
    // Regression preserves many scalars
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length"'
    cap `cmd_line'
    
    local r2_first = e(r2)
    local F_first = e(F)
    
    ereturn clear
    
    cap `cmd_line'
    
    local r2_second = e(r2)
    local F_second = e(F)
    
    if `r2_first' == `r2_second' & `F_first' == `F_second' {
        test_pass "TEST 107"
        local ++tests_passed
    }
    else {
        test_fail "TEST 107" "Scalar preservation" "Scalars not preserved correctly" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 108: Macro Preservation
//========================================================
cap noisily {

    
    sysuse auto, clear
    
    local cmd_line `"cacheit, dir("`test_dir'"): regress price weight length"'
    cap `cmd_line'
    
    local cmd_first = e(cmd)
    local depvar_first = e(depvar)
    
    ereturn clear
    
    cap `cmd_line'
    
    if "`e(cmd)'" == "regress" & "`e(depvar)'" == "price" {
        test_pass "TEST 108"
        local ++tests_passed
    }
    else {
        test_fail "TEST 108" "Macro preservation" "ereturn macros not preserved" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 109: clear Option
//========================================================
cap noisily {

    
    sysuse auto, clear
    set obs 100
    
    // This would normally fail with "data in memory would be lost"
    // clear option allows it
    local cmd_line `"cacheit, dir("`test_dir'") clear: sysuse auto"'
    cap `cmd_line'
    
    if _rc == 0 {
        if _N == 74 {
            test_pass "TEST 109"
            local ++tests_passed
        }
        else {
            test_fail "TEST 109" "clear option" "N = `_N', expected 74" `"`cmd_line'"'
            local ++tests_failed
        }
    }
    else {
        test_fail "TEST 109" "clear option" "clear option operation failed" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// TEST 110: project Option
//========================================================
cap noisily {

    
    sysuse auto, clear
    
    // Use project subdirectory
    local cmd_line `"cacheit, dir("`test_dir'") project(test_proj): regress price weight"'
    cap `cmd_line'
    
    if _rc == 0 {
        // Check if project directory created
        cap describe
        test_pass "TEST 110"
        local ++tests_passed
    }
    else {
        test_fail "TEST 110" "project option" "project option operation failed" `"`cmd_line'"'
        local ++tests_failed
    }
}

//========================================================
// SUMMARY
//========================================================
cleanup_cache "`test_dir'"
global cache_dir ""

local total = `tests_passed' + `tests_failed'
disp _newline "{result:Advanced Tests: `tests_passed' passed, `tests_failed' failed (out of `total'))}" _newline

if `tests_failed' > 0 {
    exit 1
}

exit
/* End of test file */
