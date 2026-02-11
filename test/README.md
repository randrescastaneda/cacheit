# Running cacheit Tests

## Quick Start

If your current directory is the root of the cacheit project, simply run:

```stata
run_tests
```

## Test Suites

The test suite includes three categories:

| Suite | Tests | Purpose |
|-------|-------|---------|
| **BUG** | 5 tests (BUG-001 to BUG-005) | Regression tests for known issues (timers, logs, frames, graphs) |
| **CORE** | 10 tests (CORE-001 to CORE-010) | Core caching functionality (file creation, retrieval, options) |
| **ADVANCED** | 10 tests (ADV-101 to ADV-110) | Advanced features (frames, graphs, data modification, preservation) |

## Usage

```stata
run_tests                    // Run all 25 tests
run_tests bugs               // Run 5 BUG tests only
run_tests core               // Run 10 CORE tests only
run_tests advanced           // Run 10 ADVANCED tests only
```

## Results

After tests complete:

1. **Console Summary** - Shows pass/fail/skip counts
2. **Test Frame** - Remains available for detailed inspection

### Inspect Results

```stata
cwf __cacheit_test_results    // Switch to test results frame
list                          // View all test results
list if status == "fail"      // View only failed tests
cwf default                   // Switch back to main frame
```

## Options

```stata
run_tests bugs, pause         // Run with debugging pauses
```

---

*Test framework built with Stata's frame technology for efficient result tracking.*
