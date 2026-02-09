# Quick Start: Running cacheit Tests

## TL;DR - Get Testing in 30 Seconds

### Step 1: Navigate to Test Directory

```stata
cd "path/to/cacheit/test"
```

### Step 2: Run All Tests

```stata
do run_tests.do
```

### Step 3: Review Output

Look for:
- ✓ **PASS** = Test successful
- ✗ **FAIL** = Test failed (review message)
- ⊘ **SKIP** = Test skipped (usually OK)

---

## Test Suites at a Glance

| Suite | Purpose | Duration | Critical? |
|-------|---------|----------|-----------|
| **Bugs** | Detect known bugs | ~2 min | YES |
| **Core** | Basic functionality | ~3 min | YES |  
| **Advanced** | Complex features | ~4 min | NO |

## Common Workflows

### Verify No Regressions After Code Changes

```stata
do run_tests.do
// Ensure all tests still pass
```

### Test Single Feature

```stata
// Test only core functionality
do unit/test_units_core.do
```

### Test Bug Fixes

```stata
// Run bug-specific tests FIRST to confirm bugs exist
do unit/test_units_bugs.do

// Make your code changes...

// Re-run to verify fix
do unit/test_units_bugs.do
```

## Expected Output

```
========== CACHEIT BUG-SPECIFIC TESTS ==========

[BUG-001] Timer Loop Variable Typo
Issue: local timeroff set instead of timernum
Impact: Command execution fails if all 100 timers in use
✓ PASS: BUG-001: Timer allocation works with high timer count

[BUG-002] Log File Handle Leak on Error
...
========== BUG TEST SUMMARY ==========
Tests Passed:  5
Tests Failed:  0
Total Tests:   5

ALL CRITICAL BUGS APPEAR TO BE HANDLED
```

## Understanding Failures

### Example Failure

```
✗ FAIL: TEST 003: Cached results differ from original
    Expected r(r2) = 0.347563, Got 0.347500
```

**What to do:**
1. Note the test name (TEST 003)
2. Check the detailed description in test file
3. Review the assertion message
4. Debug the issue or report it

## Quick Test Reference

### Fastest Way to Verify Installation

```stata
. do unit/test_units_core.do
...
TEST 001 - Basic Caching: First Run
✓ PASS: TEST 001: Command executed and cached
...
ALL CORE FUNCTIONALITY TESTS PASSED
```

### Comprehensive Testing (Recommended Before Commits)

```stata
. do run_tests.do
// Takes 10-15 minutes
// Tests all 25+ unit tests
// Provides complete coverage report
```

---

## Troubleshooting

**Q: "File not found" error**
```
A: Make sure you're in the test/ directory
   cd "/path/to/cacheit/test"
```

**Q: "Command not recognized"**
```
A: Verify test_utils.ado is in the directory
   do unit/test_units_core.do  (handles sourcing automatically)
```

**Q: Test hangs**
```
A: Press Ctrl+C, then check:
   - Temp directory has write permissions
   - Sufficient disk space
   - No other Stata instances using same cache
```

---

## Next Steps

- **All tests pass?** → Ready for deployment
- **Some tests fail?** → Review detailed failure messages
- **Need more tests?** → See test/README.md for adding new tests

---

**Ready to test?** Run this now:

```stata
cd "path/to/cacheit/test"
do run_tests.do
```

