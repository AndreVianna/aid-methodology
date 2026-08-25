#!/usr/bin/env bash
# test-install.sh — integration tests for install.sh's own usage/mode-detection
# surface (usage errors, help, piped invocation of install.sh itself).
#
# NOTE (legacy excision, tech-debt L3): install.sh's flag-style direct project-install
# path (--tool/--update/--uninstall/--target) has been removed.  Functional coverage
# of the shared install/uninstall/manifest/prune/root-agent-merge core logic
# (lib/aid-install-core.sh) that used to be driven through that legacy path now lives
# in tests/canonical/test-aid-cli.sh, which drives the same core logic through the
# persistent `aid` CLI's `add`/`remove`/`update` subcommands instead.
#
# Usage:
#   bash test-install.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/install.sh"

[[ -f "$SUT" ]] || { echo "ERROR: install.sh not found at $SUT" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Helper: run install.sh and capture output + exit code.
# Usage: run_install [args...]
run_install() {
    OUT=$(bash "$SUT" "$@" 2>&1); RC=$?
}

# ---------------------------------------------------------------------------
# IN01 – Unknown flag → usage error, exit 2.
# ---------------------------------------------------------------------------
run_install --unknown-flag
assert_exit_eq "$RC" 2 "IN01 unknown flag → exit 2"
assert_output_contains "$OUT" "unrecognized option or argument" \
    "IN01b error message mentions 'unrecognized option or argument'"
assert_output_contains "$OUT" "Usage" "IN01c usage printed on unrecognized flag"

# ---------------------------------------------------------------------------
# IN02–IN05 – Removed legacy flags now fall through to the unknown-flag /
#         unknown-positional case → usage error, exit 2 (locks in the L3
#         excision: --tool / --update / --uninstall / --target are no longer
#         recognized by install.sh).
# ---------------------------------------------------------------------------
run_install --tool codex
assert_exit_eq "$RC" 2 "IN02 --tool codex (removed legacy flag) → exit 2"
assert_output_contains "$OUT" "Usage" "IN02b --tool codex prints usage"

run_install --update
assert_exit_eq "$RC" 2 "IN03 --update (removed legacy flag) → exit 2"
assert_output_contains "$OUT" "Usage" "IN03b --update prints usage"

run_install --uninstall
assert_exit_eq "$RC" 2 "IN04 --uninstall (removed legacy flag) → exit 2"
assert_output_contains "$OUT" "Usage" "IN04b --uninstall prints usage"

T=$(mktemp -d "${TMP}/tgt.XXXXXX")
run_install --target "$T"
assert_exit_eq "$RC" 2 "IN05 --target <dir> (removed legacy flag) → exit 2"
assert_output_contains "$OUT" "Usage" "IN05b --target <dir> prints usage"

# ---------------------------------------------------------------------------
# IN06 – Help flag exits 0.
# ---------------------------------------------------------------------------
run_install --help
assert_exit_eq "$RC" 0 "IN06 --help → exit 0"
assert_output_contains "$OUT" "Usage" "IN06b --help prints Usage"

run_install -h
assert_exit_eq "$RC" 0 "IN06c -h → exit 0"

# ---------------------------------------------------------------------------
# IN07 – Piped --help: AID_LIB_PATH set to avoid network; $0 is 'bash' (not a
#         readable file), so usage() must print the stub (fix #11).
#         Guards finding #11.
# ---------------------------------------------------------------------------
LIB_PATH="${REPO_ROOT}/lib/aid-install-core.sh"

OUT=$(AID_LIB_PATH="$LIB_PATH" bash -s -- --help < "$SUT" 2>&1); RC=$?
assert_exit_eq "$RC" 0 "IN07 piped --help exits 0"
assert_output_contains "$OUT" "install.sh" "IN07b piped --help output contains 'install.sh'"
assert_output_contains "$OUT" "Usage" "IN07c piped --help output contains 'Usage'"
# Must NOT contain 'sed: can't read bash'
assert_output_not_contains "$OUT" "can't read" "IN07d piped --help has no sed error"

# IN07e – Piped bad flag: prints stub + error, exits 2.
OUT=$(AID_LIB_PATH="$LIB_PATH" bash -s -- --badflag-xyz < "$SUT" 2>&1); RC=$?
assert_exit_eq "$RC" 2 "IN07e piped bad flag exits 2"
assert_output_not_contains "$OUT" "can't read" "IN07f piped bad flag: no sed error"

test_summary
