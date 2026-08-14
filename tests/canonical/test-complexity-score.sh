#!/usr/bin/env bash
# test-complexity-score.sh — Unit tests for complexity-score.sh (work-002 bug fixes).
#
# Covers the four correctness fixes (work-002 task-001):
#   A1  Type matching — only **Type:** (bold task-template form) scores risk; the
#       flat "- Type:" recipe form was retired with the recipe catalog
#       (work-001-lite-aid-skills feature-002) and no longer scores
#   A2  Portable awk — extraction works under mawk (no gawk 3-arg match); leading-zero
#       delivery-id matching is numeric (003 == 3)
#   A3  Lite/recipe specs — top-level "## Execution Graph" (no delivery wrapper) parses,
#       --delivery-id not required, "## Tasks" table not swallowed; multi-delivery PLAN
#       still scopes per delivery and requires --delivery-id
#   A4  Cycle guard — a cyclic / self-looping Depends On table terminates with exit 0
#   (also) "— (none)" / "(none)" treated as no-deps (lite-spec template form)
#
# Plus the directory-form task-definition lookup:
#   A5  Risk lookup finds `<tasks-dir>/task-NNN/DETAIL.md` — the shape BOTH
#       current layouts use (full: deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md;
#       flat feature-001: tasks/task-NNN/DETAIL.md). A depth-1-only scan found no
#       task file under either, so risk read 0 for every current work and the gate
#       reviewer could be under-tiered. The legacy depth-1 task-NNN.md /
#       task-NNN-{slug}.md shapes keep working and take precedence.
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
# A1 — Type matching: only the bold form scores; flat form is retired (+0)
# ---------------------------------------------------------------------------
out=$(bash "$SCRIPT" --plan-file "$TMP/lite.md" --tasks-dir "$TMP/tasks"); code=$?
assert_exit_eq "$code" 0 "A1/A3 lite spec exits 0"
assert_eq "$(field "$out" tasks)" 2 "A1 tasks=2"
# REFACTOR(+0, flat — retired) + IMPLEMENT(+1, bold) = 1
assert_eq "$(field "$out" risk)" 1 "A1 risk=1 (only bold **Type:** scores; flat - Type: is retired)"

# Isolate the flat form alone (regression guard: must NOT score — it was retired).
cat > "$TMP/flat.md" <<'EOF'
## Execution Graph
| Task | Depends On |
|------|------------|
| task-001 | — |
EOF
out=$(bash "$SCRIPT" --plan-file "$TMP/flat.md" --tasks-dir "$TMP/tasks")
assert_eq "$(field "$out" risk)" 0 "A1 flat '- Type: REFACTOR' alone scores +0 (retired form, not counted)"

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

# ---------------------------------------------------------------------------
# A5 — directory-form task definitions: <tasks-dir>/task-NNN/DETAIL.md
#
# This is where BOTH current layouts put the task definition (full:
# deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md; flat feature-001:
# tasks/task-NNN/DETAIL.md). Before the fix the scan was depth-1 + basename
# task-NNN.md only, so NO task file was ever found for a current work and risk
# was always 0 regardless of task types.
# ---------------------------------------------------------------------------
mkdir -p "$TMP/nested/task-001" "$TMP/nested/task-002"
printf '# task-001\n\n**Type:** REFACTOR\n'  > "$TMP/nested/task-001/DETAIL.md"   # +2
printf '# task-002\n\n**Type:** TEST\n'      > "$TMP/nested/task-002/DETAIL.md"   # +1

# lite.md graph: task-001 (root) -> task-002 → tasks=2, depth=1.
# risk = REFACTOR(+2) + TEST(+1) = 3 → score = 2 + 1 + 3 + 0 = 6.
out=$(bash "$SCRIPT" --plan-file "$TMP/lite.md" --tasks-dir "$TMP/nested"); code=$?
assert_exit_eq "$code" 0 "A5a directory-form tasks-dir exits 0"
assert_eq "$(field "$out" risk)"  3 "A5a risk=3 from task-NNN/DETAIL.md (REFACTOR +2, TEST +1)"
assert_eq "$(field "$out" score)" 6 "A5a score=6 (tasks 2 + depth 1 + risk 3 + consults 0)"

# A5b — a task whose DETAIL.md is absent contributes +0 (no phantom risk, no error).
mkdir -p "$TMP/nested-partial/task-001"
printf '# task-001\n\n**Type:** MIGRATE\n' > "$TMP/nested-partial/task-001/DETAIL.md"   # +2
out=$(bash "$SCRIPT" --plan-file "$TMP/lite.md" --tasks-dir "$TMP/nested-partial"); code=$?
assert_exit_eq "$code" 0 "A5b tasks-dir with a missing task DETAIL.md exits 0"
assert_eq "$(field "$out" risk)" 2 "A5b risk=2 (MIGRATE +2; the task with no DETAIL.md scores +0)"

# A5c — the slugged directory form <tasks-dir>/task-NNN-{slug}/DETAIL.md also resolves.
mkdir -p "$TMP/nested-slug/task-001-rename-thing" "$TMP/nested-slug/task-002-add-tests"
printf '# task-001\n\n**Type:** REFACTOR\n' > "$TMP/nested-slug/task-001-rename-thing/DETAIL.md"
printf '# task-002\n\n**Type:** TEST\n'     > "$TMP/nested-slug/task-002-add-tests/DETAIL.md"
out=$(bash "$SCRIPT" --plan-file "$TMP/lite.md" --tasks-dir "$TMP/nested-slug")
assert_eq "$(field "$out" risk)" 3 "A5c risk=3 from task-NNN-{slug}/DETAIL.md directories"

# A5d — the flat "- Type:" recipe form stays retired in the directory shape too
# (A1's rule is about the Type LINE, not about where the file lives).
mkdir -p "$TMP/nested-flatform/task-001"
printf '# task-001\n\n- Type: REFACTOR\n' > "$TMP/nested-flatform/task-001/DETAIL.md"
out=$(bash "$SCRIPT" --plan-file "$TMP/flat.md" --tasks-dir "$TMP/nested-flatform")
assert_eq "$(field "$out" risk)" 0 "A5d flat '- Type:' inside DETAIL.md still scores +0 (retired form)"

# A5e — LEGACY precedence: when BOTH <tasks-dir>/task-NNN.md and
# <tasks-dir>/task-NNN/DETAIL.md exist, the legacy depth-1 file wins, so a tree
# carrying the old shape resolves byte-identically to before the directory form
# was added. task-001.md is the retired flat form (+0); task-001/DETAIL.md is a
# bold REFACTOR (+2) that must NOT be consulted.
mkdir -p "$TMP/legacy-both/task-001"
printf '# task-001\n- Type: REFACTOR\n'      > "$TMP/legacy-both/task-001.md"          # legacy, +0
printf '# task-001\n\n**Type:** REFACTOR\n'  > "$TMP/legacy-both/task-001/DETAIL.md"   # would be +2
out=$(bash "$SCRIPT" --plan-file "$TMP/flat.md" --tasks-dir "$TMP/legacy-both")
assert_eq "$(field "$out" risk)" 0 "A5e legacy task-NNN.md takes precedence over task-NNN/DETAIL.md"

# A5f — legacy-only tree is unchanged by the depth-2 scan (regression guard for
# the A1 fixture, re-asserted here against the deeper enumeration).
out=$(bash "$SCRIPT" --plan-file "$TMP/lite.md" --tasks-dir "$TMP/tasks")
assert_eq "$(field "$out" risk)" 1 "A5f legacy-only tasks-dir still risk=1 under the depth-2 scan"

test_summary
