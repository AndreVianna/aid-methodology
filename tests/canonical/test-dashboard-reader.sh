#!/usr/bin/env bash
# test-dashboard-reader.sh -- Unit tests for the AID state reader (feature-002, task-010).
#
# Invokes the Python test modules via unittest discovery and maps the result to the
# canonical pass/fail harness style (matching tests/run-all.sh expectations).
#
# Per-test PASS:/FAIL: emission (work-004 delivery-003, gate findings 8 + 14)
#   The suite used to print ONLY a two-line verdict ("dashboard reader Python tests
#   PASSED/FAILED") plus a Summary block. tests/coverage-parity.sh harvests coverage
#   identities from leading `PASS:`/`FAIL:` lines ONLY (coverage-parity.sh:221-224), so
#   every Python test in dashboard/reader/tests/ contributed ZERO coverage-parity keys
#   and this suite had ZERO rows in tests/coverage-baseline.tsv. The consequence was
#   that a whole guard module could be DELETED and both run-all.sh and the coverage
#   oracle would stay green. It now emits exactly one assert.sh-shaped line per test.
#
#   Why a driver instead of parsing `unittest -v` output: with descriptions enabled,
#   unittest prints a docstring'd test's identity and its `... ok` verdict on TWO
#   separate lines (438 of the 794 test methods here carry a docstring), and a test
#   whose only failure arrives via `self.subTest` reports through addSubTest and never
#   through addFailure. Text-scraping would silently drop both classes -- the exact
#   invisibility being repaired. The driver below emits from `stopTest`, which fires
#   exactly once per test whichever outcome hook ran, and self-checks that the number
#   of emitted lines equals unittest's own testsRun.
#
#   Coverage-key stability: every emitted label leads with `DRPY1-<unittest test id>`.
#   normalize_key (coverage-parity.sh:136) treats a leading multi-letter token followed
#   IMMEDIATELY by a digit as the WHOLE key and discards the remainder of the label, so
#   the key is the test's dotted identity verbatim -- no path, timing, count or line
#   number can leak into it, and a PASS/FAIL/skip flip on the same test keeps ONE key
#   (the oracle counts EXECUTION, not correctness -- coverage-parity.sh:48-52). The
#   trailing `1` in `DRPY1` is a label-SCHEMA version, not an index: it is fixed, so
#   adding or removing a test or module never moves any other test's key. A hyphen
#   before the first digit (`DRPY-1`) would defeat that rule and fall back to
#   whole-label masking.
#
#   unittest's own report is buffered and replayed under an inert `[unittest] ` prefix
#   so that its `FAIL: <test id>` failure-summary headers -- which would otherwise be
#   harvested as spurious coverage keys that exist only on red runs -- can never match
#   the harvester's `^[[:space:]]*(PASS|FAIL):[[:space:]]` pattern.
#
# Runtime note: this suite drives 794 Python tests, several of which shell out to node
# and pwsh. It takes ~3 minutes on a Windows host (process-spawn bound), which can
# exceed run-all.sh's `timeout 300` when 20+ suites run concurrently. Emission is
# STREAMED and flushed per test rather than buffered to the end, so a run truncated by
# that timeout still reports every test that completed before the kill instead of
# emitting nothing at all.
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed (or zero tests were collected)
#
# Usage:
#   bash tests/canonical/test-dashboard-reader.sh [-v | --verbose]
#     Without --verbose only FAIL lines print (assert.sh convention: `pass` is quiet,
#     `fail` always prints). coverage-parity.sh always runs suites with --verbose.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

# Verify python3 is available (required by technology-stack.md)
if ! command -v python3 >/dev/null 2>&1; then
    echo "  FAIL: DRPY0-python3-runtime -- python3 not found; cannot run the dashboard reader tests"
    echo "=== Summary ==="
    echo "  Tests passed: 0"
    echo "  Tests failed: 1"
    exit 1
fi

python3 -u - "$REPO_ROOT" "$VERBOSE" <<'PY'
import io
import sys
import unittest

REPO_ROOT = sys.argv[1]
VERBOSE = sys.argv[2] == "1"

# Fixed step-2 anchor for normalize_key -- see the shell header above. Never derive any
# part of this from a count, an index, or a path.
PREFIX = "DRPY1-"

OUT = sys.stdout


def flat(value):
    """Collapse any note to a single ASCII line, so one emission is always one line."""
    text = str(value).replace("\r", " ").replace("\n", " ").replace("\t", " ")
    text = text.encode("ascii", "replace").decode("ascii")
    return " ".join(text.split())[:120]


class LabelEmittingResult(unittest.TextTestResult):
    """Emit exactly one `  PASS:`/`  FAIL:` line per test, at stopTest.

    Emitting from stopTest (not from the individual add* hooks) is what makes the
    emission exhaustive: addSuccess is NOT called for a test whose subtest failed, and
    a module that fails to import surfaces as a synthetic _FailedTest. stopTest runs
    once for every one of those, so emitted == testsRun by construction.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.aid_passed = []
        self.aid_failed = []
        self.aid_status = None
        self.aid_note = ""

    def startTest(self, test):
        self.aid_status = None      # first recorded outcome wins
        self.aid_note = ""
        super().startTest(test)

    def _mark(self, status, note=""):
        if self.aid_status is None:
            self.aid_status = status
            self.aid_note = note

    def addError(self, test, err):
        super().addError(test, err)
        self._mark("FAIL", "ERROR")

    def addFailure(self, test, err):
        super().addFailure(test, err)
        self._mark("FAIL", "FAILURE")

    def addSubTest(self, test, subtest, err):
        super().addSubTest(test, subtest, err)
        if err is not None:
            self._mark("FAIL", "SUBTEST FAILURE")

    def addSkip(self, test, reason):
        super().addSkip(test, reason)
        # Keeps the key alive across a runtime-guarded skip, matching the
        # " [SKIPPED: ...]" shim normalize_key strips in step 1.
        self._mark("PASS", "[SKIPPED: %s]" % flat(reason))

    def addExpectedFailure(self, test, err):
        super().addExpectedFailure(test, err)
        self._mark("PASS", "expected failure")

    def addUnexpectedSuccess(self, test):
        super().addUnexpectedSuccess(test)
        self._mark("FAIL", "UNEXPECTED SUCCESS")

    def stopTest(self, test):
        super().stopTest(test)
        status = self.aid_status or "PASS"
        label = PREFIX + test.id()
        if self.aid_note:
            label = "%s %s" % (label, self.aid_note)
        if status == "PASS":
            self.aid_passed.append(label)
            if VERBOSE:
                OUT.write("  PASS: %s\n" % label)
                OUT.flush()
        else:
            self.aid_failed.append(label)
            OUT.write("  FAIL: %s\n" % label)
            OUT.flush()


# unittest's own output goes to a buffer, NOT to stdout: its "FAIL: <test id>" summary
# headers would otherwise be harvested as coverage keys that appear only on red runs.
report = io.StringIO()
runner = unittest.TextTestRunner(
    stream=report, descriptions=True, verbosity=2, resultclass=LabelEmittingResult
)
suite = unittest.TestLoader().discover(
    start_dir="%s/dashboard/reader/tests" % REPO_ROOT,
    pattern="test_*.py",
    top_level_dir=REPO_ROOT,
)
result = runner.run(suite)

n_pass = len(result.aid_passed)
n_fail = len(result.aid_failed)
n_skip = len(result.skipped)

# Two oracle self-guards, emitted on EVERY run so they are permanent coverage keys.
# They make "collected nothing and passed" -- a suite that silently stops testing --
# impossible to mistake for green.
if result.testsRun > 0:
    if VERBOSE:
        OUT.write("  PASS: DRPY0-collection-nonzero -- unittest collected %d test(s)\n" % result.testsRun)
else:
    OUT.write("  FAIL: DRPY0-collection-nonzero -- unittest collected ZERO tests; nothing was verified\n")

if n_pass + n_fail == result.testsRun:
    if VERBOSE:
        OUT.write("  PASS: DRPY0-emission-parity -- %d emitted line(s) == %d test(s) run\n"
                  % (n_pass + n_fail, result.testsRun))
else:
    OUT.write("  FAIL: DRPY0-emission-parity -- %d emitted line(s) != %d test(s) run; some tests are invisible to the coverage oracle\n"
              % (n_pass + n_fail, result.testsRun))

ok = result.wasSuccessful() and result.testsRun > 0 and (n_pass + n_fail == result.testsRun)

# Replay unittest's buffered report (tracebacks and all) on failure, or always under
# --verbose -- preserving the pre-existing diagnostics. The inert prefix keeps its own
# "FAIL:"/"ERROR:" headers out of the harvester's reach.
if VERBOSE or not ok:
    for line in report.getvalue().splitlines():
        OUT.write("[unittest] %s\n" % line)

OUT.write("=== Summary ===\n")
OUT.write("  Tests passed: %d\n" % n_pass)
OUT.write("  Tests failed: %d\n" % n_fail)
OUT.write("  Tests skipped: %d (counted as passed; the key survives the skip)\n" % n_skip)
if ok:
    OUT.write("  dashboard reader Python tests PASSED\n")
    OUT.write("\nAll tests passed.\n")
else:
    OUT.write("  dashboard reader Python tests FAILED\n")
    if result.aid_failed:
        OUT.write("\nFailed tests:\n")
        for label in result.aid_failed:
            OUT.write("  - %s\n" % label)
OUT.flush()
sys.exit(0 if ok else 1)
PY
exit $?
