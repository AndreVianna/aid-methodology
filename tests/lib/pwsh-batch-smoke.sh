#!/usr/bin/env bash
# pwsh-batch-smoke.sh -- minimal round-trip smoke for the pwsh session driver
# (work-024 delivery-003, task-016). NOT a glob-discovered test-*.sh suite;
# run it directly (or from review) as a reproducible mechanism check:
#   bash tests/lib/pwsh-batch-smoke.sh [-v]
#
# Proves the task-016 acceptance criteria in isolation (no aid.ps1 dependency):
#   - start/call/stop returns combined stdout+stderr + the exit code;
#   - args with spaces survive the wire protocol (@args splat);
#   - the per-call env override reaches the child runspace;
#   - Write-Host (stdout) + [Console]::Error (stderr) interleave in one buffer;
#   - the transparent cold-start fallback engages when the responder is forced
#     off (AID_PWSH_NO_SESSION=1) and returns byte-identical output + rc.
#
# Portability: correctness asserts are MODE-AGNOSTIC -- the fallback guarantees
# the same output+rc whether the round-trip ran warm (a real FIFO, as on Linux
# CI) or degraded to cold (e.g. MSYS/cygwin, where FIFO RDWR-reopen is "busy").
# The observed default mode is ECHOed, not hard-asserted, so the smoke is green
# on both. Env is a fixed token (no path) to avoid MSYS<->Windows path noise.
#
# Exit codes: 0 all pass / 1 any fail / 0 SKIP when pwsh is absent.
# ASCII-only + LF.
set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/assert.sh"
source "$DIR/pwsh.sh"
source "$DIR/pwsh-batch.sh"

PWSH="$(detect_pwsh || true)"
if [[ -z "$PWSH" ]]; then
    echo "SKIP: pwsh not found on PATH -- skipping pwsh-batch smoke."
    exit 0
fi

TMP="$(mktemp -d)"
trap 'pwsh_session_stop; rm -rf "$TMP"' EXIT

# A tiny aid.ps1 stand-in: Write-Host (stdout) + [Console]::Error (stderr),
# echoes its args + a per-call env token, then exits with a known non-zero code.
cat > "$TMP/echo.ps1" <<'PS'
Write-Host "hello-stdout args=[$($args -join '|')]"
[Console]::Error.WriteLine("err-stderr token=$($env:SMOKE_ENV_TOKEN)")
Write-Host "trailing-stdout"
exit 7
PS

check_call_output() {
    local phase="$1"
    assert_exit_eq "$PWSH_CALL_RC" 7 "smoke($phase): round-trip exit code == 7"
    assert_output_contains "$PWSH_CALL_OUT" "hello-stdout args=[a b|c]" \
        "smoke($phase): stdout + args-with-spaces survive"
    assert_output_contains "$PWSH_CALL_OUT" "err-stderr token=marker-4242" \
        "smoke($phase): stderr captured + per-call env reached the child"
    assert_output_contains "$PWSH_CALL_OUT" "trailing-stdout" \
        "smoke($phase): trailing stdout after stderr present (interleave order)"
}

# --- default path (warm on a real FIFO; cold fallback elsewhere) ---
pwsh_session_start
echo "smoke: observed default session mode = ${PWSH_SESSION_MODE}"
pwsh_session_call "$TMP/echo.ps1" "$TMP" "SMOKE_ENV_TOKEN=marker-4242" -- "a b" "c"
check_call_output "default"
DEFAULT_OUT="$PWSH_CALL_OUT"
pwsh_session_stop

# --- forced cold fallback (byte-parity toggle task-018 drives) ---
AID_PWSH_NO_SESSION=1 pwsh_session_start
assert_eq "$PWSH_SESSION_MODE" "cold" "smoke: forced cold-fallback mode"
pwsh_session_call "$TMP/echo.ps1" "$TMP" "SMOKE_ENV_TOKEN=marker-4242" -- "a b" "c"
check_call_output "cold"
COLD_OUT="$PWSH_CALL_OUT"
pwsh_session_stop

# --- default-vs-cold parity (identical output + rc regardless of path) ---
assert_eq "$DEFAULT_OUT" "$COLD_OUT" "smoke: default and forced-cold produce identical output"

test_summary
