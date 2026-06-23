#!/usr/bin/env bash
# test-harvest-coined-terms.sh -- Canonical tests for harvest-coined-terms.sh.
#
# Tests (T01-T10) cover all acceptance criteria from feature-004 / task-007:
#   T01-T03  Denylist filter: UserService dropped; RelativeBus survives; Relative Bus
#            (all-common-word phrase) recurring cross-source survives (phrase-survival rule).
#   T04-T06  Ranking: cross-source outranks same-freq single-channel; spread>=3 candidates
#            never truncated by --top; re-run is byte-identical (NFR-3 determinism).
#   T07-T08  Channels: a commit-only term (history channel) is captured; a non-git fixture
#            yields empty history without error.
#   T09      Planted 'Relative bus' cross-source fixture (code+docs+comments) surfaces in
#            the top rows -- the AC2 mechanical half.
#   T10      Output shape: the emitted markdown has the documented columns and parses.
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# Pattern mirrors test-doc-set-mapping.sh: numbered T01.. assertions, set -u, sourced assert.sh.
#
# Usage:
#   bash tests/canonical/test-harvest-coined-terms.sh [--verbose]
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
FIXTURES_BASE="${SCRIPT_DIR}/fixtures/harvest-coined-terms"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-harvest-coined-terms.sh =="

# ---------------------------------------------------------------------------
# Guard: SUT must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
  echo "FATAL: harvest-coined-terms.sh not found at $SUT" >&2
  exit 2
fi
if [[ ! -f "$DENYLIST" ]]; then
  echo "FATAL: coined-term-denylist.txt not found at $DENYLIST" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Run the harvest script on a fixture root, writing output to a temp file.
# Returns the output file path via stdout.
# Usage: run_harvest ROOT [extra args...]
run_harvest() {
  local root="$1"; shift
  local out
  out=$(mktemp)
  # Pin HOME to a throwaway dir so no local .coined-term-denylist.local.txt leaks in
  HOME=$(mktemp -d) bash "$SUT" \
    --root "$root" \
    --output "$out" \
    --denylist "$DENYLIST" \
    "$@" 2>/dev/null
  echo "$out"
}

# ---------------------------------------------------------------------------
# Fixture teardown
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
# T01-T03: Denylist filter
#
# Fixture: three terms in a shared code+docs tree:
#   - UserService  (both words in denylist, spread=1) -> DROPPED
#   - RelativeBus  (all-common camel, but multi-word split; spread>=2) -> SURVIVES
#   - Relative Bus (all-common phrase; spread>=2) -> SURVIVES (phrase-survival rule)
#
# Key: UserService appears ONLY in non-comment code lines (no comment channel),
# so spread=1, failing the phrase-escape spread>=2 floor -> dropped.
# RelativeBus and Relative Bus appear in both code and docs -> spread>=2 -> survive.
# ---------------------------------------------------------------------------

FIXTURE_T01=$(mktemp -d -p "$TMPDIR_BASE")
mkdir -p "$FIXTURE_T01/src" "$FIXTURE_T01/docs" "$FIXTURE_T01/.aid/generated"

# UserService: code-channel ONLY (no comments mentioning it, no docs)
# spread=1 -> phrase-escape floor not met -> DROPPED
cat > "$FIXTURE_T01/src/service.ts" << 'EOF'
class UserService {
  getUser() {}
  listUsers() {}
}
EOF

# RelativeBus: code + docs -> spread=2 -> SURVIVES (phrase-escape applies, spread>=2)
# Relative Bus split form also appears -> phrase, spread=2 -> SURVIVES
cat > "$FIXTURE_T01/src/bus.ts" << 'EOF'
class RelativeBus {
  scheduleRelativeBus() {}
}
EOF
cat > "$FIXTURE_T01/docs/architecture.md" << 'EOF'
# Architecture
RelativeBus is the core concept.
The Relative Bus connects all services.
EOF

OUT_T01=$(run_harvest "$FIXTURE_T01")

# T01: UserService must NOT appear in the output
assert_output_not_contains "$(cat "$OUT_T01")" "UserService" \
  "T01 UserService (all-common-word, spread=1) dropped by denylist filter"

# T02: RelativeBus (CamelCase, all-common-word split, spread>=2) survives
assert_output_contains "$(cat "$OUT_T01")" "RelativeBus" \
  "T02 RelativeBus (all-common split, spread>=2) survives via phrase-escape rule"

# T03: Relative Bus (phrase, all-common words, spread>=2) survives
assert_output_contains "$(cat "$OUT_T01")" "Relative Bus" \
  "T03 Relative Bus (all-common phrase, spread>=2) survives via phrase-survival rule"

rm -f "$OUT_T01"

# ---------------------------------------------------------------------------
# T04-T06: Ranking and determinism
#
# Fixture A (T04): two coined terms with equal freq but different spread:
#   - CrunchFactor: code+docs+comments (spread=3) -> salience = freq*(1+2*(3-1)) = freq*5
#   - FluxMatrix:   code-only (spread=1)          -> salience = freq*(1+0) = freq
#   -> CrunchFactor ranks above FluxMatrix despite equal freq.
#
# Fixture B (T05): a spread>=3 term that ranks outside the top-N cut
#   should still appear in the output (the spread>=3-never-truncated guarantee).
#
# Fixture C (T06): two runs on the same fixture produce byte-identical output
#   (excluding only the Generated date, which is always the same day in CI).
# ---------------------------------------------------------------------------

# --- T04: cross-source outranks same-freq single-channel ---

FIXTURE_T04=$(mktemp -d -p "$TMPDIR_BASE")
mkdir -p "$FIXTURE_T04/src" "$FIXTURE_T04/docs" "$FIXTURE_T04/.aid/generated"

# CrunchFactor: appears in code (non-comment) + docs -> spread=2 naturally.
# Add a comment in code to push spread to code+comments+docs=3.
cat > "$FIXTURE_T04/src/core.ts" << 'EOF'
// CrunchFactor is the scheduling algorithm
class CrunchFactor {
  computeCrunchFactor() {}
  applyCrunchFactor() {}
}
EOF
cat > "$FIXTURE_T04/docs/design.md" << 'EOF'
# Design
CrunchFactor drives all priority decisions.
CrunchFactor is updated each cycle.
EOF

# FluxMatrix: appears only in code (non-comment lines, no docs mention)
# Give it the same raw count as CrunchFactor code occurrences to make the test fair
cat > "$FIXTURE_T04/src/flux.ts" << 'EOF'
class FluxMatrix {
  computeFluxMatrix() {}
  applyFluxMatrix() {}
}
EOF

OUT_T04=$(run_harvest "$FIXTURE_T04")
output_T04=$(cat "$OUT_T04")

# CrunchFactor should appear before FluxMatrix in the output
line_crunch=$(echo "$output_T04" | grep -n "CrunchFactor" | head -1 | cut -d: -f1)
line_flux=$(echo "$output_T04" | grep -n "FluxMatrix" | head -1 | cut -d: -f1)

if [[ -n "$line_crunch" && -n "$line_flux" && "$line_crunch" -lt "$line_flux" ]]; then
  pass "T04 CrunchFactor (cross-source) outranks FluxMatrix (single-channel) in output"
else
  fail "T04 CrunchFactor (cross-source) should outrank FluxMatrix (single-channel) -- crunch at line ${line_crunch:-MISSING}, flux at line ${line_flux:-MISSING}"
fi
rm -f "$OUT_T04"

# --- T05: spread>=3 never truncated by --top ---

FIXTURE_T05=$(mktemp -d -p "$TMPDIR_BASE")
mkdir -p "$FIXTURE_T05/src" "$FIXTURE_T05/docs" "$FIXTURE_T05/.aid/generated"

# TripleSpread: spread=3 (code+docs+config) but low freq -> would be cut by --top 1
cat > "$FIXTURE_T05/src/triple.ts" << 'EOF'
class TripleSpread { run() {} }
EOF
cat > "$FIXTURE_T05/docs/overview.md" << 'EOF'
# TripleSpread Overview
EOF
cat > "$FIXTURE_T05/settings.yml" << 'EOF'
# TripleSpread configuration
mode: enabled
EOF

# FluxMatrix: high-freq code-only (spread=1) -> outranks TripleSpread by salience
{
  echo "class FluxMatrix {"
  for j in $(seq 1 50); do echo "  doFluxMatrixWork${j}() { return FluxMatrix; }"; done
  echo "}"
} > "$FIXTURE_T05/src/flux.ts"

# Use --top 1: FluxMatrix ranks first; TripleSpread must still appear (spread>=3 guarantee)
OUT_T05=$(run_harvest "$FIXTURE_T05" --top 1)
assert_output_contains "$(cat "$OUT_T05")" "TripleSpread" \
  "T05 spread>=3 candidate (TripleSpread) not truncated by --top 1"
rm -f "$OUT_T05"

# --- T06: byte-identical re-run (NFR-3 determinism) ---

FIXTURE_T06=$(mktemp -d -p "$TMPDIR_BASE")
mkdir -p "$FIXTURE_T06/src" "$FIXTURE_T06/docs" "$FIXTURE_T06/.aid/generated"

cat > "$FIXTURE_T06/src/engine.ts" << 'EOF'
// VortexAlgo powers the core scheduling engine
class VortexAlgo {
  computeVortexAlgo() {}
  applyVortexAlgo() {}
}
EOF
cat > "$FIXTURE_T06/docs/design.md" << 'EOF'
# VortexAlgo Design
VortexAlgo is described here in detail.
EOF

# First run
OUT_T06A=$(run_harvest "$FIXTURE_T06")
# Second run (separate output path to avoid the file being re-scanned)
OUT_T06B=$(run_harvest "$FIXTURE_T06")

# Compare excluding the Generated date line (same-day run is identical there too,
# but omitting it makes the test robust for cross-midnight CI runs)
if diff <(grep -v "^| Generated" "$OUT_T06A") <(grep -v "^| Generated" "$OUT_T06B") > /dev/null 2>&1; then
  pass "T06 harvest output is byte-identical on re-run (NFR-3 determinism)"
else
  fail "T06 harvest output differs between runs (NFR-3 determinism violated)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    diff <(grep -v "^| Generated" "$OUT_T06A") <(grep -v "^| Generated" "$OUT_T06B") || true
  fi
fi
rm -f "$OUT_T06A" "$OUT_T06B"

# ---------------------------------------------------------------------------
# T07-T08: Channels
#
# T07: A term appearing ONLY in git commit messages (history channel) is captured.
# T08: A non-git source tree yields empty history channel without error (exit 0).
# ---------------------------------------------------------------------------

# --- T07: history channel captures commit-only terms ---

FIXTURE_T07=$(mktemp -d -p "$TMPDIR_BASE")
mkdir -p "$FIXTURE_T07/.aid/generated"

# Init a git repo with a commit mentioning a coined term
git -C "$FIXTURE_T07" init -q 2>/dev/null
git -C "$FIXTURE_T07" config user.email "test@aid.local"
git -C "$FIXTURE_T07" config user.name "AID Test"
cat > "$FIXTURE_T07/README.md" << 'EOF'
# Project
Hello world.
EOF
git -C "$FIXTURE_T07" add README.md 2>/dev/null
git -C "$FIXTURE_T07" commit -q -m "Add QuorumPulse architecture decision" 2>/dev/null

# QuorumPulse appears ONLY in the commit message, NOT in any file
OUT_T07=$(run_harvest "$FIXTURE_T07")
assert_output_contains "$(cat "$OUT_T07")" "QuorumPulse" \
  "T07 QuorumPulse (commit-only term) captured via history channel"
rm -f "$OUT_T07"

# --- T08: non-git tree yields no history channel, no error ---

FIXTURE_T08=$(mktemp -d -p "$TMPDIR_BASE")
mkdir -p "$FIXTURE_T08/src" "$FIXTURE_T08/.aid/generated"
cat > "$FIXTURE_T08/src/core.ts" << 'EOF'
class QuantumLeap { execute() {} }
EOF

# Run on a non-git directory -> must exit 0 and not emit history rows
EXIT_T08=0
OUT_T08=$(mktemp)
HOME=$(mktemp -d) bash "$SUT" \
  --root "$FIXTURE_T08" \
  --output "$OUT_T08" \
  --denylist "$DENYLIST" \
  2>/dev/null || EXIT_T08=$?

assert_exit_zero "$EXIT_T08" "T08a non-git tree: harvest exits 0 (no error)"
assert_output_not_contains "$(cat "$OUT_T08")" "history" \
  "T08b non-git tree: no history-channel rows in output"
rm -f "$OUT_T08"

# ---------------------------------------------------------------------------
# T09: Planted 'Relative bus' cross-source fixture
#
# A fixture with Relative Bus / RelativeBus planted across code+docs+comments
# must surface in the top rows of the harvest output (AC2 mechanical half).
# "Top rows" = top 5 by row number (well within any reasonable --top value).
# ---------------------------------------------------------------------------

FIXTURE_T09="${FIXTURES_BASE}/relative-bus"

if [[ ! -d "$FIXTURE_T09" ]]; then
  echo "FATAL: T09 fixture not found at $FIXTURE_T09" >&2
  exit 2
fi

OUT_T09=$(run_harvest "$FIXTURE_T09" --top 60)
output_T09=$(cat "$OUT_T09")

# Relative Bus or RelativeBus must appear in the output
assert_output_contains "$output_T09" "Relative Bus" \
  "T09a 'Relative Bus' phrase surfaces in harvest output"

# Must be in the top 5 rows (the planted cross-source concept outranks noise)
top5=$(echo "$output_T09" | grep "^| [0-9]" | head -5)
if echo "$top5" | grep -qF "Relative Bus"; then
  pass "T09b 'Relative Bus' appears in top 5 rows (cross-source salience)"
else
  fail "T09b 'Relative Bus' not in top 5 rows -- top-5: $(echo "$top5" | head -5)"
fi

rm -f "$OUT_T09"

# ---------------------------------------------------------------------------
# T10: Output shape
#
# The emitted markdown must have the documented columns:
#   # | Source | Term | Class | Freq | Spread | Channels | Salience | Example source
# and the summary table must include the required metrics.
# ---------------------------------------------------------------------------

FIXTURE_T10=$(mktemp -d -p "$TMPDIR_BASE")
mkdir -p "$FIXTURE_T10/src" "$FIXTURE_T10/docs" "$FIXTURE_T10/.aid/generated"

cat > "$FIXTURE_T10/src/core.ts" << 'EOF'
class QuantumLeap { execute() {} }
EOF
cat > "$FIXTURE_T10/docs/overview.md" << 'EOF'
# QuantumLeap Overview
QuantumLeap is the execution engine.
EOF

OUT_T10=$(run_harvest "$FIXTURE_T10")
output_T10=$(cat "$OUT_T10")

# Must start with the documented title
assert_output_contains "$output_T10" "# Candidate Concepts" \
  "T10a output title: '# Candidate Concepts'"

# Must have the Summary table header
assert_output_contains "$output_T10" "## Summary" \
  "T10b output has '## Summary' section"

# Must have the Ranked Candidates section
assert_output_contains "$output_T10" "## Ranked Candidates" \
  "T10c output has '## Ranked Candidates' section"

# Must have the column header row with all documented columns
assert_output_contains "$output_T10" "| # | Source | Term | Class | Freq | Spread | Channels | Salience | Example source |" \
  "T10d output has documented column header row"

# Must have data rows (at least one candidate in this fixture)
if echo "$output_T10" | grep -qE '^\| [0-9]+ \| harvest \|'; then
  pass "T10e output has at least one harvest data row"
else
  fail "T10e output has no harvest data rows"
fi

# Each data row must have exactly 9 pipe-delimited columns
malformed_rows=0
while IFS= read -r row; do
  col_count=$(echo "$row" | tr -cd '|' | wc -c)
  # 9 columns -> 10 pipe characters (one leading, eight internal, one trailing)
  if [[ "$col_count" -ne 10 ]]; then
    malformed_rows=$((malformed_rows + 1))
    log "T10f malformed row (pipe count=$col_count): $row"
  fi
done < <(echo "$output_T10" | grep -E '^\| [0-9]+ \| harvest \|')

if [[ "$malformed_rows" -eq 0 ]]; then
  pass "T10f all harvest data rows have exactly 9 columns"
else
  fail "T10f $malformed_rows harvest data row(s) have wrong column count (expected 9)"
fi

# Source column must be 'harvest' for all data rows
non_harvest_rows=$(echo "$output_T10" | grep -E '^\| [0-9]+' | grep -v "| harvest |" | wc -l | tr -d ' ')
if [[ "$non_harvest_rows" -eq 0 ]]; then
  pass "T10g all data rows have Source='harvest'"
else
  fail "T10g $non_harvest_rows data row(s) have Source != 'harvest' (synthesis not expected in mechanical harvest output)"
fi

rm -f "$OUT_T10"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
