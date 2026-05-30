#!/usr/bin/env bash
# run-all.sh — run every canonical test suite, aggregate PASS/FAIL, exit non-zero on any failure.
#
# The single "run all tests" entrypoint shared by CI (.github/workflows/test.yml) and local
# development — so a contributor runs the exact same gate locally before pushing.
#
# Discovers suites by glob (tests/canonical/test-*.sh), so adding a suite needs no edit here.
# Each suite is run under `timeout 300` in its own bash process (isolated state).
#
# Usage:
#   bash tests/run-all.sh            # run all suites
#   bash tests/run-all.sh -v         # verbose (pass through to each suite)
#
# Exit code: 0 if every suite passed; 1 if any suite failed (or no suites found).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

suite_args=()
case "${1:-}" in
  -v | --verbose) suite_args+=(--verbose) ;;
esac

# Several suites invoke their SUT directly (e.g. "$WRITEBACK"); the repo is authored on
# Windows (committed 100644), so ensure the exec bit on Linux. Idempotent.
find canonical/scripts tests/canonical -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

# GitHub Actions log folding + error annotations when running under CI; plain output locally.
in_ci="${GITHUB_ACTIONS:-}"

shopt -s nullglob
suites=( tests/canonical/test-*.sh )
shopt -u nullglob

total=${#suites[@]}
if [[ $total -eq 0 ]]; then
  echo "ERROR: no test suites found under tests/canonical/test-*.sh" >&2
  exit 1
fi

failed=0
failed_suites=()

for f in "${suites[@]}"; do
  [[ -n "$in_ci" ]] && echo "::group::$f" || echo "=== $f ==="
  if ! timeout 300 bash "$f" "${suite_args[@]}"; then
    failed=$((failed + 1))
    failed_suites+=("$f")
    [[ -n "$in_ci" ]] && echo "::error::suite failed: $f"
  fi
  [[ -n "$in_ci" ]] && echo "::endgroup::"
done

echo
echo "=================================================="
if [[ $failed -eq 0 ]]; then
  echo "ALL ${total} CANONICAL SUITES PASSED"
  exit 0
fi
echo "${failed} of ${total} CANONICAL SUITES FAILED:"
printf '  - %s\n' "${failed_suites[@]}"
exit 1
