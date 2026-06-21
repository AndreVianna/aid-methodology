#!/usr/bin/env bash
# test-complexity-score.sh — Unit tests for complexity-score.sh (work-002 bug fixes).
#
# Covers the four correctness fixes (work-002 task-001):
#   A1  Type matching — both **Type:** (bold) and - Type: (flat recipe form) score risk
#   A2  Portable awk — extraction works under mawk (no gawk 3-arg match); leading-zero
#       delivery-id matching is numeric (003 == 3)
#   A3  Lite/recipe specs — top-level "## Execution Graph" (no delivery wrapper) parses,
#       --delivery-id not required, "## Tasks" table not swallowed; multi-delivery PLAN
#       still scopes per delivery and requires --delivery-id
#   A4  Cycle guard — a cyclic / self-looping Depends On table terminates with exit 0
#   (also) "— (none)" / "(none)" treated as no-deps (lite-spec template form)
#
# Usage:
#   bash test-complexity-score.sh [-v|--verbose]
# Exit: 0 all passed; 1 any failed.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/../../canonical/aid/scripts/execute/complexity-score.sh"
[[ -f "$SCRIPT" ]] || { echo "ERROR: complexity-score.sh not found at $SCRIPT" >&2; exit 1; }
[[ -x "$SCRIPT" ]] || chmod +x "$SCRIPT"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Pull one "key=value" line out of the script's stdout.
field() { grep -m1 "^$2=" <<< "$1" | cut -d= -f2; }

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------
mkdir -p "$TMP/tasks"
printf '# task-001\n- Type: REFACTOR\n'      > "$TMP/tasks/task-001.md"   # flat recipe form
printf '# task-002\n**Type:** IMPLEMENT\n'   > "$TMP/tasks/task-002.md"   # bold task-template form
printf '# task-003\n- Type: RESEARCH\n'      > "$TMP/tasks/task-003.md"   # +0

# Lite spec: top-level ## Tasks + ## Execution Graph, "— (none)" no-dep form.
cat > "$TMP/lite.md" <<'EOF'
# Lite work

## Tasks
| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | a |
| task-002 | IMPLEMENT | b |

## Execution Graph
### Task Dependencies
| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
### Can Be Done In Parallel
| Wave | Tasks |
|------|-------|
| 1 | task-001 |

## Revision History
| 2026-06-02 | x | y |
EOF

# Full multi-delivery PLAN with colliding per-delivery task IDs.
cat > "$TMP/plan.md" <<'EOF'
### delivery-001
#### Execution Graph
| Task | Depends On |
|------|------------|
| task-001 | — |
| task-002 | task-001 |
### delivery-002
#### Execution Graph
| Task | Depends On |
|------|------------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
EOF

# ---------------------------------------------------------------------------
# A1 — Type matching: flat and bold forms both score
# ---------------------------------------------------------------------------
out=$(bash "$SCRIPT" --plan-file "$TMP/lite.md" --tasks-dir "$TMP/tasks"); code=$?
assert_exit_eq "$code" 0 "A1/A3 lite spec exits 0"
assert_eq "$(field "$out" tasks)" 2 "A1 tasks=2"
# REFACTOR(+2, flat) + IMPLEMENT(+1, bold) = 3
assert_eq "$(field "$out" risk)" 3 "A1 risk=3 (flat - Type: scores, was 0 before fix)"

# Isolate the flat form alone (regression: used to score 0).
cat > "$TMP/flat.md" <<'EOF'
## Execution Graph
| Task | Depends On |
|------|------------|
| task-001 | — |
EOF
out=$(bash "$SCRIPT" --plan-file "$TMP/flat.md" --tasks-dir "$TMP/tasks")
assert_eq "$(field "$out" risk)" 2 "A1 flat '- Type: REFACTOR' alone scores +2"

# ---------------------------------------------------------------------------
# A3 — lite spec: no --delivery-id required; depth correct; ## Tasks not swallowed
# ---------------------------------------------------------------------------
out=$(bash "$SCRIPT" --plan-file "$TMP/lite.md")
assert_eq "$(field "$out" tasks)" 2 "A3 lite parses without --delivery-id"
# task-001 root (depth 0), task-002 depth 1 → MAX_DEPTH=1 (— (none) is NOT a phantom dep)
assert_eq "$(field "$out" depth)" 1 "A3 depth=1 ('— (none)' treated as no-deps)"

# ---------------------------------------------------------------------------
# A2 — delivery scoping + numeric (leading-zero) delivery-id; multi-delivery guard
# ---------------------------------------------------------------------------
out=$(bash "$SCRIPT" --plan-file "$TMP/plan.md" --delivery-id 001)
assert_eq "$(field "$out" tasks)" 2 "A2 delivery-001 scoped to 2 tasks"
out=$(bash "$SCRIPT" --plan-file "$TMP/plan.md" --delivery-id 2)   # unpadded matches delivery-002
assert_eq "$(field "$out" tasks)" 3 "A2 unpadded --delivery-id 2 matches delivery-002 (3 tasks)"
bash "$SCRIPT" --plan-file "$TMP/plan.md" >/dev/null 2>&1; code=$?
assert_exit_eq "$code" 4 "A2 multi-delivery PLAN without --delivery-id errors (exit 4)"

# ---------------------------------------------------------------------------
# A2 — portability: run the whole script with awk resolving to mawk
# ---------------------------------------------------------------------------
MAWK=$(command -v mawk || true)
if [[ -n "$MAWK" ]]; then
    AWKDIR=$(mktemp -d); ln -s "$MAWK" "$AWKDIR/awk"
    out=$(PATH="$AWKDIR:$PATH" bash "$SCRIPT" --plan-file "$TMP/plan.md" --delivery-id 001); code=$?
    rm -rf "$AWKDIR"
    assert_exit_eq "$code" 0 "A2 runs under mawk (exit 0)"
    assert_eq "$(field "$out" tasks)" 2 "A2 mawk extraction yields tasks=2 (not empty graph)"
else
    log "mawk not installed — skipping explicit mawk portability case"
fi

# ---------------------------------------------------------------------------
# A4 — cycle guard: 2-node cycle and self-loop terminate (exit 0), finite depth
# ---------------------------------------------------------------------------
cat > "$TMP/cycle.md" <<'EOF'
## Execution Graph
| Task | Depends On |
|------|------------|
| task-001 | task-002 |
| task-002 | task-001 |
EOF
out=$(timeout 15 bash "$SCRIPT" --plan-file "$TMP/cycle.md" 2>/dev/null); code=$?
assert_exit_eq "$code" 0 "A4 2-node cycle terminates with exit 0"
assert_eq "$(field "$out" tasks)" 2 "A4 cycle still reports tasks=2"

cat > "$TMP/self.md" <<'EOF'
## Execution Graph
| Task | Depends On |
|------|------------|
| task-001 | task-001 |
EOF
timeout 15 bash "$SCRIPT" --plan-file "$TMP/self.md" >/dev/null 2>&1; code=$?
assert_exit_eq "$code" 0 "A4 self-loop terminates with exit 0"

# Acyclic regression: linear chain depth is unchanged (deterministic).
cat > "$TMP/chain.md" <<'EOF'
## Execution Graph
| Task | Depends On |
|------|------------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
EOF
out=$(bash "$SCRIPT" --plan-file "$TMP/chain.md")
assert_eq "$(field "$out" depth)" 2 "A4 acyclic linear chain depth=2 (unchanged)"

test_summary
