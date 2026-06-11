#!/usr/bin/env bash
# test-dashboard-reader.sh -- Unit tests for the AID state reader (feature-002, task-010).
#
# Invokes the Python test module via python3 -m unittest and maps the result
# to the canonical pass/fail harness style (matching tests/run-all.sh expectations).
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed
#
# Usage:
#   bash tests/canonical/test-dashboard-reader.sh [-v | --verbose]

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

# Verify python3 is available (required by technology-stack.md)
if ! command -v python3 >/dev/null 2>&1; then
    echo "  FAIL: python3 not found; cannot run dashboard reader tests"
    echo "=== Summary ==="
    echo "  Tests passed: 0"
    echo "  Tests failed: 1"
    exit 1
fi

# Run the Python unittest suite.
# -v for verbose (unittest output), otherwise just top-level pass/fail.
if [[ "$VERBOSE" -eq 1 ]]; then
    python3 -m unittest discover \
        --start-directory "${REPO_ROOT}/dashboard/reader/tests" \
        --pattern "test_*.py" \
        --top-level-directory "${REPO_ROOT}" \
        -v
    exit_code=$?
else
    # Capture output; only print on failure.
    output=$(
        python3 -m unittest discover \
            --start-directory "${REPO_ROOT}/dashboard/reader/tests" \
            --pattern "test_*.py" \
            --top-level-directory "${REPO_ROOT}" \
            -v 2>&1
    )
    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "$output"
    fi
fi

echo "=== Summary ==="
if [[ $exit_code -eq 0 ]]; then
    echo "  dashboard reader Python tests PASSED"
    echo ""
    echo "All tests passed."
else
    echo "  dashboard reader Python tests FAILED (exit $exit_code)"
fi
exit $exit_code
