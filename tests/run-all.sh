#!/usr/bin/env bash
# run-all.sh — run every canonical test suite, aggregate PASS/FAIL, exit non-zero on any failure.
#
# The single "run all tests" entrypoint shared by CI (.github/workflows/test.yml) and local
# development — so a contributor runs the exact same gate locally before pushing.
#
# Discovers suites by glob (tests/canonical/test-*.sh), so adding a suite needs no edit here.
# Each suite is run under `timeout 300` in its own bash process (isolated state).
#
# Suites run CONCURRENTLY under bounded parallelism (`xargs -P`), then their captured output is
# replayed sequentially in glob order for a stable, non-interleaved log. Concurrency writes only
# to per-suite files (<base>.log / <base>.rc under a private mktemp -d results dir); the shared
# stdout / CI log is written ONLY by the single-threaded replay, so `::group::`/`::error::`
# folding stays contiguous and correctly attributed. The aggregate PASS/FAIL result is derived
# from the `.rc` files, wholly independent of xargs's own exit status.
#
# Usage:
#   bash tests/run-all.sh            # run all suites (parallel; -P $(nproc))
#   bash tests/run-all.sh -v         # verbose (pass through to each suite)
#
# Environment:
#   AID_TEST_JOBS   parallelism budget (default: nproc, or 4 if nproc is absent).
#                   AID_TEST_JOBS=1 degrades to a strict one-at-a-time run (legacy ordering) —
#                   a determinism escape hatch and debugging aid.
#
# Exit code: 0 if every suite passed; 1 if any suite failed (or no suites found).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Internal dispatch mode: run exactly ONE suite and record its result to files.
#
#   run-all.sh --__run-one <results-dir> [suite_args...] -- <suite>
#
# Invoked by the parallel dispatch below (one process per suite). It writes the suite's merged
# stdout+stderr to <results>/<base>.log and its real exit status to <results>/<base>.rc, then
# ALWAYS exits 0. The always-0 exit is load-bearing: GNU xargs stops reading further input the
# moment a child exits 255, and its own exit status (123/124/125) is a coarse roll-up — by
# capturing the suite's true status in .rc and never propagating it as the wrapper's exit, a
# suite that exits 1, 124 (timeout), or 255 neither truncates the run nor is lost. Discovery and
# chmod are skipped here (the parent already did them once).
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--__run-one" ]]; then
  shift
  __results="$1"; shift
  __run_one_args=()
  while [[ $# -gt 0 && "$1" != "--" ]]; do
    __run_one_args+=("$1")
    shift
  done
  shift || true                       # drop the "--" separator
  __suite="${1:-}"
  [[ -z "$__suite" ]] && exit 0
  __base="$(basename "$__suite")"
  timeout 300 bash "$__suite" "${__run_one_args[@]}" >"${__results}/${__base}.log" 2>&1
  echo "$?" >"${__results}/${__base}.rc"
  exit 0                              # ALWAYS 0 — the real status lives in the .rc file.
fi

suite_args=()
case "${1:-}" in
  -v | --verbose) suite_args+=(--verbose) ;;
esac

# Several suites invoke their SUT directly (e.g. "$WRITEBACK"); the repo is authored on
# Windows (committed 100644), so ensure the exec bit on Linux. Idempotent. Runs ONCE in the
# parent (never in the concurrent --__run-one children, avoiding concurrent-chmod races).
find canonical/aid/scripts tests/canonical -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

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

# Parallelism budget — bounded by the runner (ubuntu-24.04 ~= 4 vCPU); nproc has a fallback.
jobs="${AID_TEST_JOBS:-$(nproc 2>/dev/null || echo 4)}"

# Per-run results dir: lives OUTSIDE tests/canonical/, so it is never matched by the
# tests/canonical/test-*.sh glob (count-neutral). Removed on EXIT.
results="$(mktemp -d)"
trap 'rm -rf "$results"' EXIT

# --- Dispatch (bounded-parallel, order-independent) ---
# NUL-delimited so any suite path is safe; each item becomes the single trailing <suite>
# argument of a `--__run-one` invocation. "${suite_args[@]}" is forwarded verbatim (matching the
# legacy per-suite call); an empty array expands to nothing under bash >= 4.4 (ubuntu-24.04 +
# git-bash), whereas a ":-" default would inject a spurious empty positional arg.
printf '%s\0' "${suites[@]}" \
  | xargs -0 -P "$jobs" -n1 bash "$0" --__run-one "$results" "${suite_args[@]}" --

# --- Aggregate + fold (parent, single-threaded, glob order) ---
# Iterate suites in the SAME deterministic glob order, replaying each suite's captured output
# under its own ::group:: fence. Because only this single-threaded loop writes the shared log,
# the fences stay contiguous and correctly attributed (no interleave). The failure tally is
# derived from the .rc files (a missing/killed result is treated as a failure).
failed=0
failed_suites=()

for f in "${suites[@]}"; do
  base="$(basename "$f")"
  [[ -n "$in_ci" ]] && echo "::group::$f" || echo "=== $f ==="
  [[ -f "${results}/${base}.log" ]] && cat "${results}/${base}.log"
  rc=1
  [[ -f "${results}/${base}.rc" ]] && rc="$(cat "${results}/${base}.rc")"
  if [[ "$rc" != "0" ]]; then
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
