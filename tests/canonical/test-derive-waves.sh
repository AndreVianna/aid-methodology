#!/usr/bin/env bash
# test-derive-waves.sh — guards canonical/aid/scripts/execute/derive-waves.sh.
#
# What the script replaces: `aid-detail/references/execution-graph-generation.md`
# used to instruct the agent to compute the wave-map by hand from the
# `Depends On` table and then run a "Mandatory SELF-CHECK (MUST, not optional)"
# for totality. A wave-map is a topological sort of a table sitting directly
# above it — it carries no information that table does not — so deriving it costs
# nothing and cannot drift. This suite pins the properties that make the
# derivation trustworthy enough to replace the instruction:
#
#   - correctness   waves respect dependency order
#   - format        byte-exact to the reader contract (parsers.py PF-5a)
#   - totality      every task in the table lands in exactly one wave
#   - tolerance     column count varies between real plans (2 and 4 both occur);
#                   "no dependencies" is written as an em dash, en dash, --, -,
#                   `none`, or empty
#   - detection     --check FAILS on a table/wave-map disagreement (this is what
#                   caught task-030 missing from work-005's delivery-001 table)
#   - read-only     never writes to the plan it reads
#
# Usage:
#   bash test-derive-waves.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/canonical/aid/scripts/execute/derive-waves.sh"

echo "=== derive-waves guard ==="

assert_file_exists "$SCRIPT" "DW01 derive-waves.sh exists"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- fixture 1: two columns, em dash for "no deps", a diamond ---------------
cat > "${TMP}/plan-2col.md" <<'EOF'
# Plan

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-001 |
| task-004 | task-002, task-003 |

| Can Be Done In Parallel |
|------------------------|
| task-002, task-003 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-003
wave 3: task-004
```
EOF

out="$(bash "$SCRIPT" "${TMP}/plan-2col.md" 2>&1)"
rc=$?
assert_exit_zero "$rc" "DW02 emits successfully on a 2-column table"
assert_output_contains "$out" 'wave 1: task-001' "DW03 wave 1 holds the dependency-free task"
assert_output_contains "$out" 'wave 2: task-002, task-003' "DW04 wave 2 holds both parallel tasks"
assert_output_contains "$out" 'wave 3: task-004' "DW05 the join task lands after both its deps"
assert_output_contains "$out" 'delivery: 001' "DW06 emits the delivery line the reader parses"
assert_output_contains "$out" '```wave-map' "DW07 emits the exact fence the reader matches"

# The "Can Be Done In Parallel" table must never be read as dependency rows.
assert_output_not_contains "$out" 'wave 4' "DW08 single-cell parallel table is not parsed as tasks"

bash "$SCRIPT" "${TMP}/plan-2col.md" --check >/dev/null 2>&1
assert_exit_zero "$?" "DW09 --check passes when the authored map already agrees"

# --- fixture 2: four columns (work-005 shape) + varied no-dep spellings -----
cat > "${TMP}/plan-4col.md" <<'EOF'
### delivery-002 execution graph

| Task | Depends On | Gate wave | Lane |
|------|-----------|-----------|------|
| task-005 | — | 1 | 1 |
| task-006 | -- | 1 | 1 |
| task-007 | none | 1 | 1 |
| task-008 |  | 1 | 1 |
| task-009 | task-005, task-008 | 2 | 2 |
EOF

out="$(bash "$SCRIPT" "${TMP}/plan-4col.md" 2>&1)"
assert_output_contains "$out" 'delivery: 002' "DW10 handles a 4-column dependency table"
assert_output_contains "$out" 'wave 1: task-005, task-006, task-007, task-008' \
    "DW11 em dash, --, none and empty all read as no dependencies"
assert_output_contains "$out" 'wave 2: task-009' "DW12 dependent task placed in wave 2"

# --- DW13 totality: every task in the table appears exactly once ------------
ids="$(bash "$SCRIPT" "${TMP}/plan-4col.md" 2>/dev/null | grep -oE 'task-[0-9]+' | sort)"
dupes="$(echo "$ids" | uniq -d)"
count="$(echo "$ids" | wc -l | tr -d ' ')"
if [[ "$count" -eq 5 && -z "$dupes" ]]; then
    pass "DW13 all 5 tasks appear exactly once (totality)"
else
    fail "DW13 totality — expected 5 unique ids, got ${count} with dupes '${dupes}'"
fi

# --- DW14/DW15 --check detects a disagreement ------------------------------
# This is the case that matters: work-005 delivery-001 carries task-030 in its
# authored wave-map while its dependency table never defines it. The mandatory
# manual self-check did not catch that; --check must.
cat > "${TMP}/plan-drift.md" <<'EOF'
### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-030
```
EOF

bash "$SCRIPT" "${TMP}/plan-drift.md" --check >"${TMP}/drift.txt" 2>&1
rc=$?
assert_exit_eq "$rc" 1 "DW14 --check exits 1 on a table/wave-map disagreement"
assert_file_contains "${TMP}/drift.txt" "MISMATCH" "DW15 --check names the mismatch"

# --- DW16 a dependency cycle is reported, not silently mis-sorted -----------
cat > "${TMP}/plan-cycle.md" <<'EOF'
### delivery-003 execution graph

| Task | Depends On |
|------|-----------|
| task-010 | task-011 |
| task-011 | task-010 |
EOF

bash "$SCRIPT" "${TMP}/plan-cycle.md" >"${TMP}/cycle.txt" 2>&1
rc=$?
assert_exit_eq "$rc" 2 "DW16 a dependency cycle exits 2"
assert_file_contains "${TMP}/cycle.txt" "cycle" "DW17 the cycle is named in the error"

# --- DW18 a dep on an earlier delivery is treated as satisfied -------------
# Deliveries run in series, so a dependency naming a task outside this table
# belongs to an earlier delivery and must not block wave 1.
cat > "${TMP}/plan-foreign.md" <<'EOF'
### delivery-004 execution graph

| Task | Depends On |
|------|-----------|
| task-020 | task-019 |
| task-021 | task-020 |
EOF
out="$(bash "$SCRIPT" "${TMP}/plan-foreign.md" 2>&1)"
assert_output_contains "$out" 'wave 1: task-020' \
    "DW18 a dependency outside this delivery does not block wave 1"

# --- DW24..DW30 --write ------------------------------------------------------
# The first draft of this script had no --write; the reference doc told the agent
# to redirect with `>> PLAN.md`. On any plan that already carries wave-maps that
# DUPLICATES every block and breaks --check. These assertions pin the properties
# that make in-place writing safe.
cp "${TMP}/plan-2col.md" "${TMP}/w.md"
orig_sha="$(sha256sum "${TMP}/w.md" | cut -d' ' -f1)"

bash "$SCRIPT" "${TMP}/w.md" --write >/dev/null 2>&1
assert_exit_zero "$?" "DW24 --write succeeds on a plan that already has blocks"
n="$(grep -c '^```wave-map' "${TMP}/w.md")"
assert_eq "$n" "1" "DW25 --write REPLACES rather than appends (still 1 block, not 2)"

# Byte-identical no-op on an already-correct plan is the strongest statement of
# idempotency available, and it also proves the splice preserves position and
# surrounding blank lines.
new_sha="$(sha256sum "${TMP}/w.md" | cut -d' ' -f1)"
assert_eq "$new_sha" "$orig_sha" "DW26 --write on a correct plan is a byte-identical no-op"

bash "$SCRIPT" "${TMP}/w.md" --write >/dev/null 2>&1
bash "$SCRIPT" "${TMP}/w.md" --write >/dev/null 2>&1
assert_eq "$(sha256sum "${TMP}/w.md" | cut -d' ' -f1)" "$orig_sha" \
    "DW27 three consecutive --writes leave the file unchanged"

# First authoring: a plan with no blocks at all must gain them.
awk '/^```wave-map/{s=1} s&&/^```$/{s=0;next} !s' "${TMP}/plan-2col.md" > "${TMP}/none.md"
bash "$SCRIPT" "${TMP}/none.md" --write >/dev/null 2>&1
bash "$SCRIPT" "${TMP}/none.md" --check >/dev/null 2>&1
assert_exit_zero "$?" "DW28 --write then --check passes on a plan that had no blocks"

# A drifted plan must be corrected by --write.
bash "$SCRIPT" "${TMP}/plan-drift.md" --write >/dev/null 2>&1
bash "$SCRIPT" "${TMP}/plan-drift.md" --check >/dev/null 2>&1
assert_exit_zero "$?" "DW29 --write repairs a drifted wave-map"

# A malformed graph must abort BEFORE touching the file: a plan is safer left
# alone than half-rewritten.
cyc_sha="$(sha256sum "${TMP}/plan-cycle.md" | cut -d' ' -f1)"
bash "$SCRIPT" "${TMP}/plan-cycle.md" --write >/dev/null 2>&1
assert_exit_eq "$?" 2 "DW30 --write on a cyclic graph exits 2"
assert_eq "$(sha256sum "${TMP}/plan-cycle.md" | cut -d' ' -f1)" "$cyc_sha" \
    "DW31 a refused --write leaves the file byte-identical"

# --- DW32 an empty delivery section emits no bare block ---------------------
printf '### delivery-009 execution graph\n\nNo tasks yet.\n' > "${TMP}/plan-empty.md"
out="$(bash "$SCRIPT" "${TMP}/plan-empty.md" 2>&1)"
assert_output_not_contains "$out" 'delivery: 009' \
    "DW32 a delivery with no dependency rows emits no bare wave-map block"

# --- DW19 read-only --------------------------------------------------------
before="$(cd "$TMP" && sha256sum ./*.md | LC_ALL=C sort | sha256sum)"
bash "$SCRIPT" "${TMP}/plan-2col.md" >/dev/null 2>&1
bash "$SCRIPT" "${TMP}/plan-drift.md" --check >/dev/null 2>&1
after="$(cd "$TMP" && sha256sum ./*.md | LC_ALL=C sort | sha256sum)"
assert_eq "$after" "$before" "DW19 never writes to the plan it reads"

# --- DW20 determinism ------------------------------------------------------
a="$(bash "$SCRIPT" "${TMP}/plan-2col.md" 2>/dev/null)"
b="$(bash "$SCRIPT" "${TMP}/plan-2col.md" 2>/dev/null)"
assert_eq "$b" "$a" "DW20 two runs produce identical output"

# --- DW21 usage errors -----------------------------------------------------
bash "$SCRIPT" >/dev/null 2>&1
assert_exit_eq "$?" 2 "DW21 missing argument exits 2"
bash "$SCRIPT" "${TMP}/does-not-exist.md" >/dev/null 2>&1
assert_exit_eq "$?" 2 "DW22 nonexistent plan exits 2"

# --- DW23 a multi-delivery plan with a 4-column table and shared ids --------
# Was previously a read of a live .aid/works/ PLAN.md. Removed: a permanent
# artifact must not depend on a transient work folder (CLAUDE.md
# transient-work-folder invariant), even softly. The fixture below reproduces the
# shape that mattered — several deliveries in one file, a 4-column table, and a
# delivery whose tasks are not numbered from 001.
cat > "${TMP}/plan-multi.md" <<'EOF'
## Execution Graph

### delivery-001 execution graph

| Task | Depends On | Gate wave | Lane |
|------|-----------|-----------|------|
| task-001 | — | 1 | 1 |
| task-002 | task-001 | 1 | 2 |

### delivery-002 execution graph

| Task | Depends On | Gate wave | Lane |
|------|-----------|-----------|------|
| task-030 | — | 1 | 1 |
| task-031 | task-030 | 1 | 2 |
| task-032 | task-030 | 1 | 2 |

### delivery-003 execution graph

| Task | Depends On |
|------|-----------|
| task-040 | task-032 |
EOF

out="$(bash "$SCRIPT" "${TMP}/plan-multi.md" 2>&1)"
rc=$?
assert_exit_zero "$rc" "DW23 derives across three deliveries in one plan"
assert_output_contains "$out" 'delivery: 002' "DW24a each delivery gets its own block"
assert_output_contains "$out" 'wave 2: task-031, task-032' \
    "DW24b tasks not numbered from 001 sort correctly"
assert_output_contains "$out" 'wave 1: task-040' \
    "DW24c a dependency on an earlier delivery does not delay wave 1"

# ---------------------------------------------------------------------------
# DW33+: --from-tasks -- deriving the graph from the task DETAIL.md files.
#
# The Lite path has one feature and one delivery, so there is no sequencing decision
# to record and a PLAN.md would hold nothing but a view of data already on disk: each
# task's `**Depends on:**` field IS the graph. This mode renders those DETAILs into
# the same `| Task | Depends On |` shape the table source produces and feeds it
# through the SAME awk pass -- so these cases also prove the reuse, not a second
# topological sort with its own bugs.
# ---------------------------------------------------------------------------

# make_task <work-dir> <task-num> <delivery-or-empty> <depends-value>
make_task() {
    local work="$1" num="$2" delivery="$3" deps="$4"
    local dir="${work}/tasks/task-${num}"
    mkdir -p "$dir"
    {
        printf '# task-%s: Fixture\n\n**Type:** IMPLEMENT\n\n' "$num"
        if [[ -n "$delivery" ]]; then
            printf '**Source:** work-900-fixture -> delivery-%s -> AC-1\n\n' "$delivery"
        fi
        printf '**Depends on:** %s\n' "$deps"
    } > "${dir}/DETAIL.md"
}

FT="${TMP}/ft-flat"
make_task "$FT" 001 001 "-- (none)"
make_task "$FT" 002 001 "task-001"
make_task "$FT" 003 001 "task-001"

out="$(bash "$SCRIPT" --from-tasks "$FT" 2>&1)"
rc=$?
assert_exit_zero "$rc" "DW33 --from-tasks derives from DETAIL.md files with no PLAN.md present"
assert_output_contains "$out" 'wave 1: task-001' "DW34a the root task lands in wave 1"
assert_output_contains "$out" 'wave 2: task-002, task-003' \
    "DW34b two tasks sharing one dependency share a wave"
# The table is printed as well as the waves: with no authored table on disk, it is the
# only way to see what the sort was computed FROM.
assert_output_contains "$out" '| task-002 | task-001 |' \
    "DW34c the derived dependency table is printed alongside the wave-map"

# A cycle must fail the same way it does from a table source -- same sort, same
# semantics, same exit code.
FT_CYC="${TMP}/ft-cycle"
make_task "$FT_CYC" 001 001 "task-002"
make_task "$FT_CYC" 002 001 "task-001"
bash "$SCRIPT" --from-tasks "$FT_CYC" >/dev/null 2>&1
assert_exit_eq "$?" 2 "DW35 --from-tasks exits 2 on a dependency cycle"

# The nested layout: DETAILs live under deliveries/delivery-NNN/tasks/, and each
# delivery must get its own section and its own wave-map.
FT_NEST="${TMP}/ft-nested"
for spec in "001 001 -- (none)" "002 002 -- (none)" "003 002 task-002"; do
    set -- $spec
    num="$1" del="$2"; shift 2; deps="$*"
    dir="${FT_NEST}/deliveries/delivery-${del}/tasks/task-${num}"
    mkdir -p "$dir"
    printf '# task-%s\n\n**Source:** w -> delivery-%s\n\n**Depends on:** %s\n' \
        "$num" "$del" "$deps" > "${dir}/DETAIL.md"
done
out="$(bash "$SCRIPT" --from-tasks "$FT_NEST" 2>&1)"
rc=$?
assert_exit_zero "$rc" "DW36 --from-tasks handles the nested deliveries/ layout"
assert_output_contains "$out" 'delivery: 001' "DW37a nested: delivery-001 gets a wave-map"
assert_output_contains "$out" 'delivery: 002' "DW37b nested: delivery-002 gets its own wave-map"
assert_output_contains "$out" 'wave 2: task-003' \
    "DW37c nested: dependencies within a delivery still sort"

# A DETAIL with no **Source:** line falls to delivery-001 -- the Lite path's
# synthesized single delivery, and the only case where Source can be terse.
FT_NOSRC="${TMP}/ft-nosource"
make_task "$FT_NOSRC" 001 "" "-- (none)"
out="$(bash "$SCRIPT" --from-tasks "$FT_NOSRC" 2>&1)"
assert_exit_zero "$?" "DW38 --from-tasks tolerates a DETAIL with no Source line"
assert_output_contains "$out" 'delivery: 001' \
    "DW39 a task with no resolvable delivery falls to delivery-001"

# An empty work is an error, not an empty success: silently emitting nothing would
# look identical to a work whose tasks all sorted into no waves.
bash "$SCRIPT" --from-tasks "${TMP}/ft-empty-work" >/dev/null 2>&1
assert_exit_eq "$?" 2 "DW40 --from-tasks exits 2 when the work directory does not exist"
mkdir -p "${TMP}/ft-empty-work"
bash "$SCRIPT" --from-tasks "${TMP}/ft-empty-work" >/dev/null 2>&1
assert_exit_eq "$?" 2 "DW41 --from-tasks exits 2 when the work has no task DETAIL.md files"

# "No dependencies" is spelled many ways. Every spelling must yield no dependency,
# which is the same extraction-not-cleaning argument the table source relies on.
FT_DASH="${TMP}/ft-dashes"
make_task "$FT_DASH" 001 001 "--"
make_task "$FT_DASH" 002 001 "None"
make_task "$FT_DASH" 003 001 ""
out="$(bash "$SCRIPT" --from-tasks "$FT_DASH" 2>&1)"
assert_exit_zero "$?" "DW42 --from-tasks accepts every 'no dependencies' spelling"
assert_output_contains "$out" 'wave 1: task-001, task-002, task-003' \
    "DW43 '--', 'None' and an empty value all mean no dependency, so all three are wave 1"

test_summary
