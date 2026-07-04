#!/usr/bin/env bash
# test-harvest-batching.sh -- guards for the batched harvest refactor (work-007 #7).
#
# The harvest was rewritten to eliminate the per-file / per-token subprocess-spawn
# storm that made /aid-discover unusable on Windows Git Bash / MSYS. Two properties
# MUST hold for that refactor to be safe:
#
#   T01  ENGINE EQUIVALENCE (determinism across OS): the rg-accelerated path and the
#        coreutils-grep fallback produce BYTE-IDENTICAL candidate-concepts.md over the
#        same tree (modulo the Generated date). This is what guarantees a repo
#        discovered on Windows-with-rg yields the same KB as Linux-without-rg.
#        Forced via AID_HARVEST_NO_RG=1. Skipped-as-note if rg is not installed (then
#        both runs already use the same grep engine, so there is nothing to compare).
#
#   T02  NO HANG on pathological single-long-line input: a docs file that is one very
#        long line of capitalized words (the shape that stalled the old per-match
#        shell loop / could pathologically backtrack a naive engine) must complete
#        quickly and emit a well-formed table. Run under an internal `timeout` so a
#        regression to O(spawns) or catastrophic backtracking turns the test RED.
#
#   T03  Long-line extraction still WORKS: the planted cross-source concept surfaces.
#
# Auto-discovered by tests/run-all.sh (tests/canonical/test-*.sh glob).
# Pattern mirrors test-harvest-coined-terms.sh / test-essence-capture.sh.
#
# Usage:
#   bash tests/canonical/test-harvest-batching.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT="${REPO}/canonical/aid/scripts/kb/harvest-coined-terms.sh"
DENYLIST="${REPO}/canonical/aid/scripts/kb/coined-term-denylist.txt"
FX_LONGLINE="${SCRIPT_DIR}/fixtures/harvest-coined-terms/pathological-longline"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-harvest-batching.sh =="

if [[ ! -f "$SUT" ]]; then
  echo "FATAL: harvest-coined-terms.sh not found at $SUT" >&2
  exit 2
fi
if [[ ! -f "$DENYLIST" ]]; then
  echo "FATAL: coined-term-denylist.txt not found at $DENYLIST" >&2
  exit 2
fi
if [[ ! -d "$FX_LONGLINE" ]]; then
  echo "FATAL: pathological-longline fixture not found at $FX_LONGLINE" >&2
  exit 2
fi

TMP="$(mktemp -d)"
FAKE_HOME="${TMP}/fakehome"
mkdir -p "$FAKE_HOME"
trap 'rm -rf "$TMP"' EXIT

# run_harvest <root> <output> [extra env assignment ...]
# Pinned SOURCE_DATE_EPOCH + throwaway HOME so runs are byte-comparable and isolated.
run_harvest() {
  local root="$1" out="$2"; shift 2
  env "$@" \
    SOURCE_DATE_EPOCH=1750000000 \
    HOME="$FAKE_HOME" \
    bash "$SUT" --root "$root" --output "$out" --denylist "$DENYLIST" 2>/dev/null
}

# ---------------------------------------------------------------------------
# T01 -- engine equivalence: rg path == grep fallback, byte-identical.
#
# Build a rich fixture exercising EVERY channel/class: code (ident/camel/snake/
# quoted/comment), docs (camel/phrase/quoted), config (snake/camel), and git
# history. Then harvest twice -- once with rg allowed, once with it forced off --
# and diff (excluding only the Generated date line).
# ---------------------------------------------------------------------------
FX_EQ="${TMP}/equiv"
mkdir -p "$FX_EQ/src" "$FX_EQ/docs" "$FX_EQ/config"

cat > "$FX_EQ/src/service.ts" << 'EOF'
// RelativeBus powers the QuorumPulse scheduler across worker nodes.
class RelativeBus {
  scheduleRelativeBus(retry_budget) { return "quorum pulse"; }
  applyQuorumPulse() {}
}
const worker_node_count = 4;
EOF
cat > "$FX_EQ/docs/design.md" << 'EOF'
# Design

The Relative Bus connects the QuorumPulse scheduler to every Worker Node.
QuorumPulse timing is Adaptive And Deterministic across the fleet.
It exposes a "relative bus mode" toggle.
EOF
cat > "$FX_EQ/config/settings.yml" << 'EOF'
# QuorumPulse configuration
quorum_pulse_mode: enabled
worker_node_count: 4
retry_budget: 3
EOF

git -C "$FX_EQ" init -q 2>/dev/null
git -C "$FX_EQ" config user.email "test@aid.local"
git -C "$FX_EQ" config user.name "AID Test"
git -C "$FX_EQ" add -A 2>/dev/null
git -C "$FX_EQ" commit -q -m "Add RelativeBus QuorumPulse scheduler with Adaptive Quorum Pulse" 2>/dev/null

OUT_RG="${TMP}/eq_rg.md"
OUT_NORG="${TMP}/eq_norg.md"
run_harvest "$FX_EQ" "$OUT_RG"
run_harvest "$FX_EQ" "$OUT_NORG" AID_HARVEST_NO_RG=1

if command -v rg >/dev/null 2>&1; then
  eq_label="T01 rg path == grep fallback (byte-identical; cross-OS determinism)"
else
  eq_label="T01 fallback self-consistent (rg absent -- both runs use grep)"
fi

if diff <(grep -v '^| Generated' "$OUT_RG") <(grep -v '^| Generated' "$OUT_NORG") > /dev/null 2>&1; then
  pass "$eq_label"
else
  fail "$eq_label -- outputs diverge"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- rg vs no-rg diff ---"
    diff <(grep -v '^| Generated' "$OUT_RG") <(grep -v '^| Generated' "$OUT_NORG") || true
  fi
fi

# Sanity: the fixture actually produced candidates (guards a silently-empty pass).
if grep -qE '^\| [0-9]+ \| harvest \|' "$OUT_RG"; then
  pass "T01b equivalence fixture produced harvest rows (comparison is non-vacuous)"
else
  fail "T01b equivalence fixture produced NO harvest rows -- comparison would be vacuous"
fi

# ---------------------------------------------------------------------------
# T02 -- no hang on a pathological single-long-line docs file.
# Run under an internal timeout: a regression to per-match spawns or catastrophic
# backtracking would exceed it and fail here rather than hang the whole suite.
# ---------------------------------------------------------------------------
OUT_LL="${TMP}/longline.md"
LL_EXIT=0
timeout 60 env SOURCE_DATE_EPOCH=1750000000 HOME="$FAKE_HOME" \
  bash "$SUT" --root "$FX_LONGLINE" --output "$OUT_LL" --denylist "$DENYLIST" >/dev/null 2>&1 || LL_EXIT=$?

if [[ "$LL_EXIT" -eq 124 ]]; then
  fail "T02 harvest HUNG on pathological long-line input (>60s -- spawn storm / backtracking regression)"
else
  assert_exit_zero "$LL_EXIT" "T02 harvest completes on pathological long-line input (no hang)"
fi

assert_file_contains "$OUT_LL" "| # | Source | Term | Class | Freq | Spread | Channels | Salience | Example source |" \
  "T02b pathological run still emits the documented table header"

# ---------------------------------------------------------------------------
# T03 -- long-line extraction still surfaces the planted cross-source concept.
# ---------------------------------------------------------------------------
assert_file_contains "$OUT_LL" "Relative Bus" \
  "T03 planted 'Relative Bus' concept surfaces from the long-line fixture"

# ---------------------------------------------------------------------------
test_summary
exit $?
