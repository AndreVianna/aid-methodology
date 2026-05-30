# assert.sh — shared assertion helpers for the canonical bash test suites.
#
# Source it from a suite (after setting VERBOSE):
#   VERBOSE=0
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
#
# Provides:
#   counters : PASS, FAIL, ERRORS[]   (initialized here)
#   logging  : log "<msg>"            (only printed when VERBOSE=1)
#   outcomes : pass "<name>"          (counts; printed only when VERBOSE=1)
#              fail "<name> — why"    (counts; ALWAYS printed; recorded in ERRORS)
#   asserts  : assert_eq, assert_output_contains, assert_output_not_contains,
#              assert_file_contains, assert_file_not_contains, assert_file_exists,
#              assert_dir_exists, assert_exit_zero, assert_exit_nonzero, assert_exit_eq,
#              assert_line_exact, assert_line_count
#   summary  : test_summary           (prints totals + failures; returns 1 if any failed)
#
# Convention for a consistent failure line: pass the assertion name PLUS the reason in a
# single label, e.g.  fail "T07 build output — expected exit 0, got $code"  →  the helpers
# below already format their reasons this way, so output reads:  "  FAIL: <name> — <why>".

: "${VERBOSE:=0}"
PASS=0
FAIL=0
ERRORS=()

log()  { [[ "$VERBOSE" -eq 1 ]] && echo "[LOG] $*" || true; }
pass() { PASS=$((PASS + 1)); [[ "$VERBOSE" -eq 1 ]] && echo "  PASS: $*" || true; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$*"); echo "  FAIL: $*"; }

assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label — expected '$expected' got '$actual'"
    fi
}

assert_output_contains() {
    local output="$1" pattern="$2" label="$3"
    if echo "$output" | grep -qF "$pattern"; then
        pass "$label"
    else
        fail "$label — pattern not found: '$pattern'"
        [[ "$VERBOSE" -eq 1 ]] && echo "---OUTPUT---" && echo "$output" && echo "---END---"
    fi
}

assert_output_not_contains() {
    local output="$1" pattern="$2" label="$3"
    if ! echo "$output" | grep -qF "$pattern"; then
        pass "$label"
    else
        fail "$label — unexpected pattern found: '$pattern'"
    fi
}

assert_file_contains() {
    local file="$1" pattern="$2" label="$3"
    if grep -qF "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label — pattern not found: '$pattern' in $file"
        [[ "$VERBOSE" -eq 1 ]] && echo "---FILE---" && cat "$file" && echo "---END---"
    fi
}

assert_file_not_contains() {
    local file="$1" pattern="$2" label="$3"
    if ! grep -qF "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label — unexpected pattern found: '$pattern' in $file"
    fi
}

assert_file_exists() {
    local file="$1" label="$2"
    if [[ -f "$file" ]]; then
        pass "$label"
    else
        fail "$label — file does not exist: $file"
    fi
}

assert_exit_zero() {
    local code="$1" label="$2"
    if [[ "$code" -eq 0 ]]; then
        pass "$label (exit 0)"
    else
        fail "$label — expected exit 0, got $code"
    fi
}

assert_exit_nonzero() {
    local code="$1" label="$2"
    if [[ "$code" -ne 0 ]]; then
        pass "$label (exit $code)"
    else
        fail "$label — expected non-zero exit, got 0"
    fi
}

assert_exit_eq() {
    local code="$1" expected="$2" label="$3"
    if [[ "$code" -eq "$expected" ]]; then
        pass "$label (exit $expected)"
    else
        fail "$label — expected exit $expected, got $code"
    fi
}

assert_dir_exists() {
    local dir="$1" label="$2"
    if [[ -d "$dir" ]]; then
        pass "$label"
    else
        fail "$label — directory does not exist: $dir"
    fi
}

assert_line_exact() {
    local output="$1" lineno="$2" expected="$3" label="$4"
    local actual
    actual=$(echo "$output" | sed -n "${lineno}p")
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label — line $lineno: expected '$expected' got '$actual'"
    fi
}

assert_line_count() {
    local file="$1" expected="$2" label="$3"
    local actual
    actual=$(wc -l < "$file" | tr -d ' ')
    if [[ "$actual" -eq "$expected" ]]; then
        pass "$label"
    else
        fail "$label — expected $expected lines, got $actual in $file"
    fi
}

# Print the run summary; return 1 if any assertion failed, 0 otherwise.
test_summary() {
    echo "=== Summary ==="
    echo "  Tests passed: $PASS"
    echo "  Tests failed: $FAIL"
    if [[ $FAIL -gt 0 ]]; then
        echo ""
        echo "Failed tests:"
        local e
        for e in "${ERRORS[@]}"; do
            echo "  - $e"
        done
        return 1
    fi
    echo ""
    echo "All tests passed."
    return 0
}
