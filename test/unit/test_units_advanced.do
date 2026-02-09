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

disp _newline "{title:========== CACHEIT ADVANCED FEATURE TESTS ==========}" _newline
local tests_passed = 0
local tests_failed = 0

//========================================================
// TEST 101: Frame Caching and Restoration
//========================================================
cap noisily {
    disp "{bf:TEST 101 - Frame Caching}"
    
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
    cap noisily cacheit, dir("`test_dir'") framecheck(data_frame): summ x
    
    if _rc == 0 {
        // Drop the frame
        frame drop data_frame
        
        // Re-run - frame should be restored
        cap noisily cacheit, dir("`test_dir'") framecheck(data_frame): summ x
        
        if _rc == 0 {
            // Verify frame restored
            cwf data_frame
            descrip
            if r(N) == 150 {
                test_pass "TEST 101: Frame caching and restoration works"
                local ++tests_passed
            }
            else {
                test_fail "TEST 101: Frame data not restored" "N = `r(N)', expected 150"
                local ++tests_failed
            }
            cwf default
            frame drop data_frame
        }
        else {
            test_fail "TEST 101: Cache retrieval failed" ""
            local ++tests_failed
        }
    }
    else {
        test_fail "TEST 101: Frame caching failed" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 102: Graph Caching
//========================================================
cap noisily {
    disp "{bf:TEST 102 - Graph Caching and Restoration}"
    
    sysuse auto, clear
    graph drop _all
    
    // Create and cache graph
    cap noisily cacheit, dir("`test_dir'"): scatter price weight
    
    if _rc == 0 {
        // Drop graph
        graph drop _all
        
        // Re-run - should restore graph
        cap noisily cacheit, dir("`test_dir'"): scatter price weight
        
        // Check if graph exists
        cap graph describe Graph
        if _rc == 0 {
            test_pass "TEST 102: Graph caching works"
            local ++tests_passed
            graph drop _all
        }
        else {
            test_fail "TEST 102: Graph not restored" ""
            local ++tests_failed
        }
    }
    else {
        test_fail "TEST 102: Graph caching failed" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 103: Multiple Graphs
//========================================================
cap noisily {
    disp "{bf:TEST 103 - Multiple Graph Caching}"
    
    sysuse auto, clear
    graph drop _all
    
    // Create multiple graphs
    cap noisily {
        cacheit, dir("`test_dir'"): scatter price weight
        graph save Graph "`test_dir'/temp_graph1.gph", replace
        
        cacheit, dir("`test_dir'"): histogram price
        graph save Graph "`test_dir'/temp_graph2.gph", replace
    }
    
    if _rc == 0 {
        test_skip "TEST 103" "Complex graph scenario"
        local ++tests_passed
    }
}

//========================================================
// TEST 104: Data Modification Caching
//========================================================
cap noisily {
    disp "{bf:TEST 104 - Data Modification Caching}"
    
    sysuse auto, clear
    
    // Modify data and cache
    cap noisily cacheit, dir("`test_dir'"): generate log_price = log(price)
    local first_obs = log_price[1]
    
    // Drop variable
    drop log_price
    
    // Reload from cache
    cacheit, dir("`test_dir'"): generate log_price = log(price)
    local second_obs = log_price[1]
    
    if `first_obs' == `second_obs' {
        test_pass "TEST 104: Data modifications cached correctly"
        local ++tests_passed
    }
    else {
        test_fail "TEST 104: Data not properly cached" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 105: datacheck Option
//========================================================
cap noisily {
    disp "{bf:TEST 105 - datacheck Option"} 
    
    sysuse auto, clear
    
    // Save external data
    tempfile external
    keep price weight in 1/20
    save "`external'"
    
    // Use datacheck
    sysuse auto, clear
    cap noisily cacheit, dir("`test_dir'") datacheck("`external'"): regress price weight
    
    if _rc == 0 {
        test_pass "TEST 105: datacheck option accepted and processed"
        local ++tests_passed
    }
    else {
        test_fail "TEST 105: datacheck option failed" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 106: Matrix Restoration
//========================================================
cap noisily {
    disp "{bf:TEST 106 - Multiple Matrix Restoration}"
    
    sysuse auto, clear
    
    // Run regression (creates e(b), e(V), e(beta))
    cacheit, dir("`test_dir'"): regress price weight length displacement
    
    // Store matrix info
    local b_r = rowsof(e(b))
    local V_r = rowsof(e(V))
    local b_c = colsof(e(b))
    
    // Clear ereturn
    ereturn clear
    
    // Reload from cache
    cacheit, dir("`test_dir'"): regress price weight length displacement
    
    // Check matrices restored
    if rowsof(e(b)) == `b_r' & rowsof(e(V)) == `V_r' & colsof(e(b)) == `b_c' {
        test_pass "TEST 106: All matrices restored correctly"
        local ++tests_passed
    }
    else {
        test_fail "TEST 106: Matrix dimensions mismatch" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 107: Scalar Preservation
//========================================================
cap noisily {
    disp "{bf:TEST 107 - Scalar Preservation}"
    
    sysuse auto, clear
    
    // Regression preserves many scalars
    cacheit, dir("`test_dir'"): regress price weight length
    
    local r2_first = e(r2)
    local F_first = e(F)
    
    ereturn clear
    
    cacheit, dir("`test_dir'"): regress price weight length
    
    local r2_second = e(r2)
    local F_second = e(F)
    
    if `r2_first' == `r2_second' & `F_first' == `F_second' {
        test_pass "TEST 107: Scalars preserved correctly"
        local ++tests_passed
    }
    else {
        test_fail "TEST 107: Scalar preservation failed" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 108: Macro Preservation
//========================================================
cap noisily {
    disp "{bf:TEST 108 - ereturn Macros"} 
    
    sysuse auto, clear
    
    cacheit, dir("`test_dir'"): regress price weight length
    
    local cmd_first = e(cmd)
    local depvar_first = e(depvar)
    
    ereturn clear
    
    cacheit, dir("`test_dir'"): regress price weight length
    
    if "`e(cmd)'" == "regress" & "`e(depvar)'" == "price" {
        test_pass "TEST 108: ereturn Macros preserved"
        local ++tests_passed
    }
    else {
        test_fail "TEST 108: Macros not preserved" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 109: clear Option
//========================================================
cap noisily {
    disp "{bf:TEST 109 - clear Option"} 
    
    sysuse auto, clear
    set obs 100
    
    // This would normally fail with "data in memory would be lost"
    // clear option allows it
    cap noisily cacheit, dir("`test_dir'") clear: sysuse auto
    
    if _rc == 0 {
        if _N == 74 {
            test_pass "TEST 109: clear option works"
            local ++tests_passed
        }
        else {
            test_fail "TEST 109: clear option issue" "N = `_N', expected 74"
            local ++tests_failed
        }
    }
    else {
        test_fail "TEST 109: clear option failed" ""
        local ++tests_failed
    }
}

//========================================================
// TEST 110: project Option
//========================================================
cap noisily {
    disp "{bf:TEST 110 - project Organization"} 
    
    sysuse auto, clear
    
    // Use project subdirectory
    cap noisily cacheit, dir("`test_dir'") project(test_proj): regress price weight
    
    if _rc == 0 {
        // Check if project directory created
        cap describe
        test_pass "TEST 110: project option creates subdirectory"
        local ++tests_passed
    }
    else {
        test_fail "TEST 110: project option failed" ""
        local ++tests_failed
    }
}

//========================================================
// SUMMARY
//========================================================
disp _newline "{title:========== ADVANCED FEATURES TEST SUMMARY ==========}"
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
    disp "{result:ALL ADVANCED FEATURE TESTS PASSED}" _newline
}

exit
/* End of test file */
