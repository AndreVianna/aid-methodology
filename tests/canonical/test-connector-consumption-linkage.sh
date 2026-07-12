#!/usr/bin/env bash
# test-connector-consumption-linkage.sh -- AC9 linkage/consumption smoke suite
# for work-004-connector-consumption's multi-level `ticket_ref` contract
# (canonical/aid/templates/connectors/consumption-protocol.md).
#
# SCOPE NOTE -- there is no dedicated script for `ticket_ref` resolution (it is
# a resolution RULE an agent applies at a wired seam, documented as markdown
# prose in consumption-protocol.md's "Nearest-ancestor resolution" section).
# This suite SCRIPTS that resolution rule directly (mirroring how
# test-reconcile-scenarios.sh scripts ELICIT's R0-R5 prose) and pairs it with a
# STUBBED host-MCP action -- a local mock function that only appends to a log
# file -- so "acts via the linked connector's host MCP" is exercised WITHOUT
# any live external call (per task-007's mandate). Structural assertions
# separately confirm the contract text + the optional `ticket_ref`
# STATE/SPEC scalar are actually documented/present in canonical/.
#
# Traces:
#   CL01-CL08   Structural -- consumption-protocol.md documents the
#               `ticket_ref` scalar form, the nearest-ancestor resolution
#               chains (delivery/feature/task), the "feature outranks delivery"
#               rationale, and the wired-seams table; the optional `ticket_ref`
#               scalar/line is present in all 4 lifecycle-unit carriers
#               (work/delivery/task STATE frontmatter + feature SPEC body)
#   CL09-CL16   Resolution -- own ticket_ref wins at every level (work/
#               delivery/feature/task), ignoring any ancestor value
#   CL17-CL20   Resolution -- delivery inherits from work when it has none of
#               its own; feature inherits from work when it has none of its own
#   CL21-CL24   Resolution -- task inherits from its owning feature BEFORE its
#               delivery (feature outranks delivery -- AC9's specific rule)
#   CL25-CL27   Resolution -- task with no own/feature ref falls to delivery,
#               then to work
#   CL28-CL30   Resolution -- a task tracing to NO single owning feature skips
#               the feature level entirely (task -> delivery -> work)
#   CL31-CL33   Resolution -- terminal case: nothing anywhere in the chain ->
#               resolves to no ticket; the seam skips silently (no error)
#   CL34-CL39   Consumption smoke check -- the AC9 worked example (task
#               inherits `jira:PROJ-45` from its feature; a `jira` MCP
#               connector is catalogued) drives 3 State-Write Protocol
#               transitions (In Progress / In Review / Done) through the
#               stubbed host-MCP mock; asserts each transition posted to the
#               correct external id, in order, with no live call
#   CL40-CL42   Consumption smoke check (contrast) -- the SAME resolved
#               ticket_ref, but the connector is `api`-typed (not `mcp`):
#               the seam recipe's Step 2 confirmation fails, so NO host-MCP
#               action fires (aid-managed consumption is out of scope)
#
# Usage:
#   bash tests/canonical/test-connector-consumption-linkage.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROTOCOL="${REPO_ROOT}/canonical/aid/templates/connectors/consumption-protocol.md"
WORK_TPL="${REPO_ROOT}/canonical/aid/templates/work-state-template.md"
DELIVERY_TPL="${REPO_ROOT}/canonical/aid/templates/delivery-state-template.md"
TASK_TPL="${REPO_ROOT}/canonical/aid/templates/task-state-template.md"
SPEC_TPL="${REPO_ROOT}/canonical/aid/templates/specs/spec-template.md"

for f in "$PROTOCOL" "$WORK_TPL" "$DELIVERY_TPL" "$TASK_TPL" "$SPEC_TPL"; do
    if [[ ! -f "$f" ]]; then
        fail "CL00 setup -- required file not found: $f"
        test_summary
        exit 1
    fi
done

echo "== connector consumption / ticket_ref linkage tests (AC9) =="

# ===========================================================================
# CL01-CL08  Structural -- the contract is actually documented where the SPEC
# says it must be.
# ===========================================================================
assert_file_contains "$PROTOCOL" 'ticket_ref: "<connector-stem>:<external-id>"' \
    "CL01 consumption-protocol.md documents the ticket_ref scalar form"
assert_file_contains "$PROTOCOL" "## Nearest-ancestor resolution" \
    "CL02 consumption-protocol.md has a Nearest-ancestor resolution section"
assert_file_contains "$PROTOCOL" "delivery → work" \
    "CL03 resolution chain documented: delivery -> work"
assert_file_contains "$PROTOCOL" "feature → work" \
    "CL04 resolution chain documented: feature -> work"
assert_file_contains "$PROTOCOL" "task → its owning (SPEC-traced) feature → its delivery → work" \
    "CL05 resolution chain documented: task -> feature -> delivery -> work"
assert_file_contains "$PROTOCOL" "Why feature outranks delivery for a task" \
    "CL06 rationale documented: feature outranks delivery"
assert_file_contains "$PROTOCOL" "task → its delivery → work" \
    "CL07 documented fallback: a task with no single owning feature skips the feature level"
assert_file_contains "$PROTOCOL" "## Wired seams" \
    "CL08 consumption-protocol.md documents the Wired seams table"

for seam in "aid-describe" "aid-specify" "aid-plan" "aid-execute" "aid-query-kb" "aid-researcher" "aid-developer"; do
    assert_file_contains "$PROTOCOL" "$seam" \
        "CL08b Wired seams table references $seam"
done

assert_file_contains "$WORK_TPL" 'ticket_ref: "{connector-stem}:{external-id}' \
    "CL08c work-state-template.md carries the optional ticket_ref frontmatter scalar"
assert_file_contains "$DELIVERY_TPL" 'ticket_ref: "{connector-stem}:{external-id}' \
    "CL08d delivery-state-template.md carries the optional ticket_ref frontmatter scalar"
assert_file_contains "$TASK_TPL" 'ticket_ref: "{connector-stem}:{external-id}' \
    "CL08e task-state-template.md carries the optional ticket_ref frontmatter scalar"
assert_file_contains "$SPEC_TPL" '**Ticket:** {connector-stem}:{external-id}' \
    "CL08f spec-template.md carries the optional Ticket line (SPEC.md has no frontmatter block)"

# ===========================================================================
# resolve_ticket_ref UNIT_TYPE OWN FEATURE DELIVERY WORK HAS_OWNING_FEATURE
# -- scripts consumption-protocol.md's "Nearest-ancestor resolution" table
# directly. Each positional value is the ticket_ref string at that level, or
# "" if absent. HAS_OWNING_FEATURE is 1/0 (only meaningful for UNIT_TYPE=task):
# a task tracing to no single feature skips the feature level entirely.
# ===========================================================================
resolve_ticket_ref() {
    local unit_type="$1" own="$2" feature="$3" delivery="$4" work="$5" has_feature="${6:-1}"

    if [[ -n "$own" ]]; then
        echo "$own"; return 0
    fi

    case "$unit_type" in
        delivery|feature)
            [[ -n "$work" ]] && { echo "$work"; return 0; }
            ;;
        task)
            if [[ "$has_feature" == "1" && -n "$feature" ]]; then
                echo "$feature"; return 0
            fi
            [[ -n "$delivery" ]] && { echo "$delivery"; return 0; }
            [[ -n "$work" ]] && { echo "$work"; return 0; }
            ;;
    esac
    echo ""
    return 1
}

# ===========================================================================
# CL09-CL16  Own ticket_ref always wins, at every level, ignoring ancestors.
# ===========================================================================
r=$(resolve_ticket_ref work "jira:WORK-1" "" "" "" 1)
assert_eq "$r" "jira:WORK-1" "CL09 own ticket_ref wins -- work level"

r=$(resolve_ticket_ref delivery "jira:DEL-1" "" "" "jira:WORK-2" 1)
assert_eq "$r" "jira:DEL-1" "CL10 own ticket_ref wins -- delivery (ignores work ancestor)"

r=$(resolve_ticket_ref feature "jira:FEAT-1" "" "" "jira:WORK-3" 1)
assert_eq "$r" "jira:FEAT-1" "CL11 own ticket_ref wins -- feature (ignores work ancestor)"

r=$(resolve_ticket_ref task "jira:TASK-1" "jira:FEAT-9" "jira:DEL-9" "jira:WORK-9" 1)
assert_eq "$r" "jira:TASK-1" "CL12 own ticket_ref wins -- task (ignores feature/delivery/work ancestors)"

# Re-run each with the ancestor values varied -- own still wins regardless.
r=$(resolve_ticket_ref delivery "jira:DEL-1" "" "" "" 1)
assert_eq "$r" "jira:DEL-1" "CL13 own ticket_ref wins -- delivery, even with no ancestor at all"
r=$(resolve_ticket_ref feature "jira:FEAT-1" "" "" "" 1)
assert_eq "$r" "jira:FEAT-1" "CL14 own ticket_ref wins -- feature, even with no ancestor at all"
r=$(resolve_ticket_ref task "jira:TASK-1" "" "" "" 1)
assert_eq "$r" "jira:TASK-1" "CL15 own ticket_ref wins -- task, even with no ancestor at all"
r=$(resolve_ticket_ref work "jira:WORK-1" "irrelevant" "irrelevant" "irrelevant" 1)
assert_eq "$r" "jira:WORK-1" "CL16 own ticket_ref wins -- work (work has no ancestor to fall back to anyway)"

# ===========================================================================
# CL17-CL20  Delivery/feature inherit from work when they carry none of their own.
# ===========================================================================
r=$(resolve_ticket_ref delivery "" "" "" "jira:WORK-10" 1)
assert_eq "$r" "jira:WORK-10" "CL17 delivery with no own ticket_ref inherits from work"

r=$(resolve_ticket_ref feature "" "" "" "jira:WORK-11" 1)
assert_eq "$r" "jira:WORK-11" "CL18 feature with no own ticket_ref inherits from work"

r=$(resolve_ticket_ref delivery "" "" "" "" 1)
assert_eq "$r" "" "CL19 delivery with no own ref and no work ref resolves to nothing"

r=$(resolve_ticket_ref feature "" "" "" "" 1)
assert_eq "$r" "" "CL20 feature with no own ref and no work ref resolves to nothing"

# ===========================================================================
# CL21-CL24  AC9's specific rule -- for a task, feature outranks delivery.
# ===========================================================================
r=$(resolve_ticket_ref task "" "jira:FEAT-20" "jira:DEL-20" "jira:WORK-20" 1)
assert_eq "$r" "jira:FEAT-20" "CL21 task inherits from its owning FEATURE before its delivery"

r=$(resolve_ticket_ref task "" "jira:FEAT-21" "" "jira:WORK-21" 1)
assert_eq "$r" "jira:FEAT-21" "CL22 task inherits from its feature even when the delivery carries none"

r=$(resolve_ticket_ref task "" "jira:FEAT-22" "jira:DEL-22" "" 1)
assert_eq "$r" "jira:FEAT-22" "CL23 task inherits from its feature even when the work carries none"

# Falsifiability contrast: swap which ancestor carries a value -- the RESULT
# tracks the rule, not a hardcoded return.
r=$(resolve_ticket_ref task "" "jira:FEAT-23-alt" "jira:DEL-23-alt" "jira:WORK-23-alt" 1)
assert_eq "$r" "jira:FEAT-23-alt" "CL24 contrast -- changing which value is present, feature still wins"

# ===========================================================================
# CL25-CL27  Task with no own/feature ref falls to delivery, then to work.
# ===========================================================================
r=$(resolve_ticket_ref task "" "" "jira:DEL-24" "jira:WORK-24" 1)
assert_eq "$r" "jira:DEL-24" "CL25 task with no own/feature ref falls to delivery"

r=$(resolve_ticket_ref task "" "" "" "jira:WORK-25" 1)
assert_eq "$r" "jira:WORK-25" "CL26 task with no own/feature/delivery ref falls to work"

r=$(resolve_ticket_ref task "" "" "" "jira:WORK-25" 0)
assert_eq "$r" "jira:WORK-25" "CL27 same, task also has no single owning feature (has_feature=0) -- still falls to work"

# ===========================================================================
# CL28-CL30  A task tracing to no single owning feature skips the feature
# level entirely (task -> delivery -> work) -- even when a feature-shaped
# value happens to be passed in, it must be ignored.
# ===========================================================================
r=$(resolve_ticket_ref task "" "jira:FEAT-30-MUST-BE-IGNORED" "jira:DEL-30" "jira:WORK-30" 0)
assert_eq "$r" "jira:DEL-30" "CL28 task with no single owning feature -- feature level skipped, resolves to delivery"

r=$(resolve_ticket_ref task "" "jira:FEAT-31-MUST-BE-IGNORED" "" "jira:WORK-31" 0)
assert_eq "$r" "jira:WORK-31" "CL29 task with no single owning feature and no delivery ref -- resolves to work"

# Contrast: the SAME inputs, but has_feature=1 -- now the feature DOES win.
r=$(resolve_ticket_ref task "" "jira:FEAT-30-MUST-BE-IGNORED" "jira:DEL-30" "jira:WORK-30" 1)
assert_eq "$r" "jira:FEAT-30-MUST-BE-IGNORED" \
    "CL30 contrast -- same inputs with has_feature=1 -- feature now wins (proves CL28 depended on the flag, not on the value being empty)"

# ===========================================================================
# CL31-CL33  Terminal case -- nothing anywhere in the chain.
# ===========================================================================
r=$(resolve_ticket_ref task "" "" "" "" 1); ec=$?
assert_eq "$r" "" "CL31 terminal case -- task, empty chain, resolves to nothing"
assert_exit_eq "$ec" 1 "CL32 terminal case -- resolver reports non-zero (no ticket found)"

r=$(resolve_ticket_ref delivery "" "" "" "" 1); ec=$?
assert_eq "$r" "" "CL33 terminal case -- delivery, empty chain, resolves to nothing (seam skips silently, no error)"

# ===========================================================================
# CL34-CL39  Consumption smoke check -- the AC9 worked example
# (consumption-protocol.md "Worked example"): task inherits jira:PROJ-45 from
# its feature; a `jira` connector is catalogued with connection_type: mcp.
# Drives 3 State-Write Protocol transitions through a STUBBED host-MCP mock
# (a local function appending to a log file -- no live external call of any
# kind is made anywhere in this suite).
# ===========================================================================
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT
MCP_LOG="${TMPDIR_BASE}/mcp-calls.log"
: > "$MCP_LOG"

# mock_host_mcp_post CONNECTOR_TYPE STEM EXTERNAL_ID TRANSITION -- the seam
# recipe's Step 3/4 ("request the connection from the host tool", "act, then
# stop"), stubbed: only mcp-typed connectors act; anything else is a silent
# skip (Step 2's confirmation failing). NEVER performs any network I/O.
mock_host_mcp_post() {
    local connector_type="$1" stem="$2" external_id="$3" transition="$4"
    if [[ "$connector_type" != "mcp" ]]; then
        return 1   # Step 2 confirmation fails -- aid-managed consumption out of scope
    fi
    echo "POST ${stem}:${external_id} state=${transition}" >> "$MCP_LOG"
    return 0
}

JIRA_CONNECTOR_TYPE="mcp"
TASK_OWN=""; TASK_FEATURE="jira:PROJ-45"; TASK_DELIVERY="jira:DEL-99"; TASK_WORK="jira:WORK-99"

resolved=$(resolve_ticket_ref task "$TASK_OWN" "$TASK_FEATURE" "$TASK_DELIVERY" "$TASK_WORK" 1)
assert_eq "$resolved" "jira:PROJ-45" "CL34 AC9 worked example -- task resolves to its feature's jira:PROJ-45"

stem="${resolved%%:*}"
external_id="${resolved#*:}"
assert_eq "$stem" "jira" "CL35 AC9 worked example -- resolved connector stem is 'jira'"
assert_eq "$external_id" "PROJ-45" "CL36 AC9 worked example -- resolved external id is 'PROJ-45'"

for transition in "In Progress" "In Review" "Done"; do
    mock_host_mcp_post "$JIRA_CONNECTOR_TYPE" "$stem" "$external_id" "$transition"
done

assert_eq "$(wc -l < "$MCP_LOG" | tr -d ' ')" "3" "CL37 AC9 worked example -- exactly 3 host-MCP posts recorded (one per State-Write Protocol transition)"
assert_file_contains "$MCP_LOG" "POST jira:PROJ-45 state=In Progress" "CL38a AC9 worked example -- In Progress transition mirrored to PROJ-45"
assert_file_contains "$MCP_LOG" "POST jira:PROJ-45 state=In Review" "CL38b AC9 worked example -- In Review transition mirrored to PROJ-45"
assert_file_contains "$MCP_LOG" "POST jira:PROJ-45 state=Done" "CL38c AC9 worked example -- Done transition mirrored to PROJ-45"

# Order matters (mirrors the pipeline's own transition order).
first_line=$(sed -n '1p' "$MCP_LOG")
last_line=$(sed -n '3p' "$MCP_LOG")
assert_output_contains "$first_line" "state=In Progress" "CL39a AC9 worked example -- transitions mirrored IN ORDER (first = In Progress)"
assert_output_contains "$last_line" "state=Done" "CL39b AC9 worked example -- transitions mirrored IN ORDER (last = Done)"

# ===========================================================================
# CL40-CL42  Contrast -- the SAME resolved ticket_ref, but the connector is
# `api`-typed, not `mcp`: aid-managed consumption is out of scope (SPEC.md
# "Out of Scope / Deferred"), so the seam recipe's Step 2 confirmation fails
# and NO host-MCP action fires.
# ===========================================================================
: > "$MCP_LOG"
API_CONNECTOR_TYPE="api"
mock_host_mcp_post "$API_CONNECTOR_TYPE" "$stem" "$external_id" "In Progress"
ec_api_attempt=$?

assert_exit_ne "$ec_api_attempt" 0 "CL40 contrast -- an api-typed connector's Step-2 confirmation fails (aid-managed consumption out of scope)"
assert_eq "$(wc -l < "$MCP_LOG" | tr -d ' ')" "0" "CL41 contrast -- no host-MCP post recorded for an api-typed connector"
if [[ ! -s "$MCP_LOG" ]]; then
    pass "CL42 contrast -- log file confirms zero posts (empty file)"
else
    fail "CL42 contrast -- log file unexpectedly non-empty"
fi

# ===========================================================================
test_summary
