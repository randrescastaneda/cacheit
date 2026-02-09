# cacheit Test Suite

## Overview

This directory contains comprehensive unit and integration tests for the `cacheit` Stata package. The test suite is organized to:

1. **Identify existing bugs** through specific bug-targeting tests
2. **Verify core functionality** through functional tests
3. **Test advanced features** through feature-specific tests
4. **Provide comprehensive coverage** to catch regressions after fixes

## Directory Structure

```
test/
├── run_tests.do                 # Master test runner
├── test_utils.ado               # Test utilities and assertions
├── unit/
│   ├── test_units_bugs.do       # Bug-specific tests
│   ├── test_units_core.do       # Core functionality tests
│   └── test_units_advanced.do   # Advanced feature tests
└── integration/
    └── (planned for future)
```

## Test Categories

### 1. Bug-Specific Tests (`test_units_bugs.do`)

These tests specifically target the bugs identified in the codebase:

- **BUG-001**: Timer loop variable typo (line 567)
  - Tests: High timer count handling
  - Expected: Graceful failure or success even with limited timers

- **BUG-002**: Log file handle leak on error (line 594)
  - Tests: Recovery after command error
  - Expected: No resource leak after error recovery

- **BUG-003**: Temporary frame cleanup on error
  - Tests: Frame count after error condition
  - Expected: Same number of frames before and after error

- **BUG-004**: Frame drop error handling
  - Tests: Frame cleanup without errors
  - Expected: Proper cleanup of temporary frames

- **BUG-005**: Graph name parsing with special characters
  - Tests: Standard graph caching and restoration
  - Expected: Graphs properly cached and restored

### 2. Core Functionality Tests (`test_units_core.do`)

Tests basic caching and retrieval operations:

- **TEST 001**: Basic caching - first run
- **TEST 002**: Cache file creation verification
- **TEST 003**: Cached retrieval (identical results)
- **TEST 004**: Return list preservation (r-class results)
- **TEST 005**: ereturn matrix preservation
- **TEST 006**: nodata option functionality
- **TEST 007**: replace option forces recomputation
- **TEST 008**: keepall option behavior
- **TEST 009**: Hash consistency (same command = same hash)
- **TEST 010**: Different commands create different hashes

### 3. Advanced Feature Tests (`test_units_advanced.do`)

Tests complex features and edge cases:

- **TEST 101**: Frame caching and restoration
- **TEST 102**: Graph caching and restoration
- **TEST 103**: Multiple graph caching
- **TEST 104**: Data modification caching
- **TEST 105**: datacheck option
- **TEST 106**: Multiple matrix restoration
- **TEST 107**: Scalar preservation
- **TEST 108**: Macro preservation
- **TEST 109**: clear option
- **TEST 110**: project option subdirectories

## Running the Tests

### Run All Tests

From the `test/` directory:

```stata
do run_tests.do
```

### Run Specific Test Suite

```stata
// Bug tests only
do unit/test_units_bugs.do

// Core functionality tests only  
do unit/test_units_core.do

// Advanced features tests only
do unit/test_units_advanced.do
```

### Run from Stata Command Line

```stata
cd "path/to/cacheit/test"
do run_tests.do
```

## Test Output Format

Each test produces output in the following format:

```
✓ PASS: Test Name
✗ FAIL: Test Name
    Assertion failed: Expected X, got Y
⊘ SKIP: Test Name (reason for skip)
```

**Summary example:**
```
========== CORE FUNCTIONALITY TEST SUMMARY ==========
Tests Passed:  9
Tests Failed:  1
Total Tests:   10

SOME TESTS FAILED
```

## Test Utilities (`test_utils.ado`)

The test suite provides assertion functions:

### Assertions

```stata
assert_equal(value1, value2, "message")
assert_scalar(value, "message")
assert_file_exists(filepath, "message")
assert_variable_exists(varname, "message")
assert_variable_missing(varname, "message")
assert_frame_exists(framename, "message")
assert_frame_missing(framename, "message")
```

### Test Control

```stata
test_pass "Test Name"
test_fail "Test Name" "Failure message"
test_skip "Test Name" "Skip reason"
```

### Cleanup

```stata
cleanup_cache "`cache_directory'"
```

## Interpreting Test Results

### All Tests Pass ✓
- Core functionality is working correctly
- Advanced features are operational
- No obvious bugs detected

### Some Tests Fail ✗
- Review the specific test output
- Cross-reference with bug list
- Investigate failure message for details

### Tests Skip
- Skipped tests indicate prerequisites not met
- Often due to command errors in setup
- Not counted as failures

## Adding New Tests

To add a new test:

1. **Choose the appropriate file**:
   - Bug fix tests → `test_units_bugs.do`
   - Feature tests → `test_units_core.do` or `test_units_advanced.do`

2. **Follow the pattern**:
   ```stata
   cap noisily {
       disp "{bf:TEST XXX - Test Name}"
       
       // Setup
       sysuse auto, clear
       
       // Test execution
       cacheit, dir("`test_dir'"): command here
       
       // Assertions
       if condition {
           test_pass "TEST XXX: Description"
           local ++tests_passed
       }
       else {
           test_fail "TEST XXX: Description" "Failure reason"
           local ++tests_failed
       }
   }
   ```

3. **Update counter**: Ensure `tests_passed` and `tests_failed` are incremented

4. **Document**: Add test description at the top of relevant section

## Troubleshooting

### Test Hangs or Freezes
- Check for infinite loops in cached commands
- Verify cache directory is accessible
- Review system resources

### Memory Issues
- Clear temporary data between tests
- Use `cleanup_cache` function between tests
- Check for orphaned frames: `frame dir`

### Path Issues
- Ensure proper navigation to test directory
- Use absolute paths in test execution
- Verify temporary directory permissions

### Missing Data
- Some tests require `sysuse auto`
- Verify this dataset is available
- Check Stata installation

## Test Coverage Status

| Category | Tests | Status |
|----------|-------|--------|
| Bug Detection | 5 | ✓ Implemented |
| Core Features | 10 | ✓ Implemented |
| Advanced Features | 10 | ✓ Implemented |
| Integration | 0 | Planned |
| Performance | 0 | Planned |

**Total: 25 unit tests implemented**

## Known Limitations

1. **Bug-001, Bug-002, Bug-003**: Tests verify recovery after errors, but cannot directly verify absence of memory leaks
2. **Mata/Memory tests**: Limited ability to verify Mata-level issues
3. **Special character handling**: Limited testing for extreme edge cases
4. **Performance testing**: Currently no performance benchmarks

## Future Enhancements

- [ ] Integration tests for multi-command workflows
- [ ] Performance benchmarking tests
- [ ] Stress tests with large datasets
- [ ] Internationalization tests
- [ ] Continuous integration setup (GitHub Actions, etc.)

## Contact & Support

For test-related issues or contributions:
- Review test output carefully
- Check this documentation
- Open issue with test output attached

---

**Last Updated**: February 2026  
**Version**: 0.0.1  
**Status**: Active Development

