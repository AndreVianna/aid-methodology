#!/usr/bin/env bash
# test-connector-consumption-linkage.sh -- AC9 linkage/consumption smoke suite
# for a work's tracker links, as one sources: list
# (canonical/aid/templates/connectors/consumption-protocol.md, "Work sources").
#
# SCOPE NOTE -- there is no dedicated script that picks a work's ticket (it is a
# selection RULE an agent applies at a wired seam, documented as markdown prose
# in consumption-protocol.md's "Finding the work's ticket" rule). This suite
# SCRIPTS that rule directly (mirroring how test-reconcile-scenarios.sh scripts
# ELICIT's R0-R5 prose) and pairs it with a STUBBED host-MCP action -- a local
# mock function that only appends to a log file -- so "acts via the linked
# connector's host MCP" is exercised WITHOUT any live external call. Structural
# assertions separately confirm the contract text is documented in canonical/,
# and that the retired per-unit `ticket_ref` is gone from the state and feature
# templates (CL08c-CL08f).
#
# Traces:
#   CL01-CL08f  Structural -- consumption-protocol.md documents the work's
#               sources: list (the entry fields, the write_backs: entry
#               fields, the kind enum), the ticket-selection rule, the
#               terminal case, the Wired seams table; CL08c-CL08f: the 4
#               templates that once carried `ticket_ref` (work/delivery/task
#               STATE + the feature section) carry it no more -- a work's
#               tracker items are entries of its one `sources:` list
#   CL34-CL39   Consumption smoke check -- the worked example (the work's
#               sources: list holds jira:PROJ-45 as kind ticket; a `jira` MCP
#               connector is catalogued) drives 3 State-Write Protocol
#               transitions (In Progress / In Review / Done) through the
#               stubbed host-MCP mock; asserts each transition posted to the
#               correct external id, in order, with no live call
#   CL40-CL42   Consumption smoke check (contrast) -- the SAME ticket, but the
#               connector is `api`-typed (not `mcp`): the seam recipe's Step 2
#               confirmation fails, so NO host-MCP action fires (aid-managed
#               consumption is out of scope)
#   CL43-CL50   Ticket selection -- the seam picks the first sources: entry
#               whose kind is ticket and whose ref is <connector-stem>:<id>;
#               every other kind, a URL, an issue, or an empty list resolves
#               to no ticket (the terminal case, a silent skip)
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
WORK_TPL="${REPO_ROOT}/canonical/aid/templates/work-state-template.yml"
DELIVERY_TPL="${REPO_ROOT}/canonical/aid/templates/delivery-state-template.yml"
TASK_TPL="${REPO_ROOT}/canonical/aid/templates/task-state-template.yml"
FEATURE_TPL="${REPO_ROOT}/canonical/aid/templates/requirements/requirements-template.md"

for f in "$PROTOCOL" "$WORK_TPL" "$DELIVERY_TPL" "$TASK_TPL" "$FEATURE_TPL"; do
    if [[ ! -f "$f" ]]; then
        fail "CL00 setup -- required file not found: $f"
        test_summary
        exit 1
    fi
done

echo "== connector consumption / work sources linkage tests (AC9) =="

# ===========================================================================
# CL01-CL08  Structural -- the contract is actually documented where the SPEC
# says it must be.
# ===========================================================================
assert_file_contains "$PROTOCOL" '## Work sources (`sources:`)' \
    "CL01 consumption-protocol.md documents the work's sources: list (its one work-level link list)"

assert_file_contains "$PROTOCOL" "  - ref: 'jira:PROJ-123'" \
    "CL02 consumption-protocol.md documents the sources: entry, ref first"

missing=""
for pat in '^    kind: ticket ' '^    added: ' '^    phase: ' '^    effect: '; do
    grep -qE "$pat" "$PROTOCOL" || missing+=" [$pat]"
done
if [[ -z "$missing" ]]; then
    pass "CL03 sources: entry carries the kind, added, phase and effect fields"
else
    fail "CL03 sources: entry is missing field(s):$missing"
fi

assert_file_contains "$PROTOCOL" "kind: ticket  " \
    "CL03b the entry names the kind enum with ticket first"
assert_file_contains "$PROTOCOL" "ticket | issue | document | link | file" \
    "CL03c the kind values are the closed enum ticket | issue | document | link | file"

missing=""
for pat in '^write_backs:' '^  - at: ' '^    source: ' '^    part: ' '^    files: '; do
    grep -qE "$pat" "$PROTOCOL" || missing+=" [$pat]"
done
if [[ -z "$missing" ]]; then
    pass "CL04 write_backs: entry (top-level) carries at, source, part and files"
else
    fail "CL04 write_backs: entry is missing field(s):$missing"
fi

assert_wrapped_contains "$PROTOCOL" 'first `sources:` entry whose `kind` is `ticket`' \
    "CL05 the seam picks the first sources: entry whose kind is ticket"

assert_wrapped_contains "$PROTOCOL" "A work with no such entry resolves to **no" \
    "CL06 a work with no ticket entry resolves to no ticket"

assert_file_contains "$PROTOCOL" "**Terminal case.**" \
    "CL07 the terminal case (no ticket in the list) is documented as a silent skip"

assert_file_contains "$PROTOCOL" "## Wired seams" \
    "CL08 consumption-protocol.md documents the Wired seams table"

# The aid-execute status-mirror write seam has been retired -- consumption-protocol no longer
# carries an aid-execute row; the aid-fix / shortcut-engine INTAKE ingest seam is the 7th wired
# seam. Every seam below is a READ/ingest seam that delegates to /aid-read-ticket.
for seam in "aid-describe" "aid-specify" "aid-plan" "aid-fix" "aid-ask" "aid-researcher" "aid-developer"; do
    assert_file_contains "$PROTOCOL" "$seam" \
        "CL08b Wired seams table references $seam"
done

# CL08c-CL08f INVERTED: the per-unit `ticket_ref` is retired. A work's tracker
# items are entries of the one work-level `sources:` list (CL08c2 asserts the
# key; test-work-state-template.sh WS24 asserts its shape), so none of the four
# templates that once carried `ticket_ref` -- the key, its
# `{connector-stem}:{external-id}` format note, or the feature `**Ticket:**`
# line -- may carry it again.
assert_file_not_contains "$WORK_TPL" "ticket_ref" \
    "CL08c work-state-template.yml carries no ticket_ref (retired)"
assert_file_contains "$WORK_TPL" "sources: []" \
    "CL08c2 work-state-template.yml carries the work-level sources: list that replaces it"
assert_file_not_contains "$DELIVERY_TPL" "ticket_ref" \
    "CL08d delivery-state-template.yml carries no ticket_ref (retired)"
assert_file_not_contains "$DELIVERY_TPL" "{connector-stem}:{external-id}" \
    "CL08d2 delivery-state-template.yml carries no ticket_ref value-format note"
assert_file_not_contains "$TASK_TPL" "ticket_ref" \
    "CL08e task-state-template.yml carries no ticket_ref (retired)"
assert_file_not_contains "$TASK_TPL" "{connector-stem}:{external-id}" \
    "CL08e2 task-state-template.yml carries no ticket_ref value-format note"
assert_file_not_contains "$FEATURE_TPL" '**Ticket:**' \
    "CL08f the feature section carries no Ticket line (retired)"

# ===========================================================================
# pick_ticket ENTRIES -- scripts consumption-protocol.md's "Finding the work's
# ticket" rule. ENTRIES is a newline-separated list of "kind|ref" lines, one
# per sources: entry. Prints the first ticket ref (kind ticket, ref shaped
# <connector-stem>:<id>); prints nothing and returns 1 when there is none.
# ===========================================================================
pick_ticket() {
    local entries="$1" line kind ref
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        kind="${line%%|*}"
        ref="${line#*|}"
        if [[ "$kind" == "ticket" && "$ref" =~ ^[a-z][a-z0-9_-]*:[^/]+$ ]]; then
            printf '%s' "$ref"
            return 0
        fi
    done <<< "$entries"
    return 1
}

# ===========================================================================
# CL43-CL50  Ticket selection over a work's sources: list.
# ===========================================================================
r=$(pick_ticket "file|REQUIREMENTS.md"); ec=$?
assert_eq "$r" "" "CL43 a list with only a file entry yields no ticket (terminal case)"
assert_exit_ne "$ec" 0 "CL43b the selection reports no ticket for a file-only list"

r=$(pick_ticket "ticket|jira:PROJ-1")
assert_eq "$r" "jira:PROJ-1" "CL44 a single ticket entry is the work's ticket"

r=$(pick_ticket "file|REQUIREMENTS.md
ticket|jira:PROJ-2")
assert_eq "$r" "jira:PROJ-2" "CL45 non-ticket entries are skipped; the ticket entry after them is picked"

r=$(pick_ticket "ticket|jira:PROJ-3
ticket|jira:PROJ-4")
assert_eq "$r" "jira:PROJ-3" "CL46 with two ticket entries, the first in the list is the work's ticket"

r=$(pick_ticket "link|https://example.com/spec")
assert_eq "$r" "" "CL47 a link entry is never read as a ticket"

r=$(pick_ticket "ticket|https://jira.example.com/PROJ-9")
assert_eq "$r" "" "CL48 a URL is not a <connector-stem>:<id> ref, so it is not a connector ticket"

r=$(pick_ticket "issue|github:4")
assert_eq "$r" "" "CL49 an issue entry is not read as a ticket"

r=$(pick_ticket "")
assert_eq "$r" "" "CL50 an empty sources: list yields no ticket (terminal case)"

# ===========================================================================
# CL34-CL39  Consumption smoke check -- the worked example
# (consumption-protocol.md "Worked example (work sources)"): the work's
# sources: list holds jira:PROJ-45 as kind ticket; a `jira` connector is
# catalogued with connection_type: mcp. Drives 3 State-Write Protocol
# transitions through a STUBBED host-MCP mock (a local function appending to a
# log file -- no live external call of any kind is made anywhere in this suite).
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
WORK_SOURCES="file|REQUIREMENTS.md
ticket|jira:PROJ-45
document|docs/notes.md"

resolved=$(pick_ticket "$WORK_SOURCES")

assert_eq "$resolved" "jira:PROJ-45" "CL34 worked example -- the work's ticket is its sources: entry jira:PROJ-45"

stem="${resolved%%:*}"
external_id="${resolved#*:}"
assert_eq "$stem" "jira" "CL35 worked example -- resolved connector stem is 'jira'"
assert_eq "$external_id" "PROJ-45" "CL36 worked example -- resolved external id is 'PROJ-45'"

for transition in "In Progress" "In Review" "Done"; do
    mock_host_mcp_post "$JIRA_CONNECTOR_TYPE" "$stem" "$external_id" "$transition"
done

assert_eq "$(wc -l < "$MCP_LOG" | tr -d ' ')" "3" "CL37 worked example -- exactly 3 host-MCP posts recorded (one per State-Write Protocol transition)"
assert_file_contains "$MCP_LOG" "POST jira:PROJ-45 state=In Progress" "CL38a worked example -- In Progress transition mirrored to PROJ-45"
assert_file_contains "$MCP_LOG" "POST jira:PROJ-45 state=In Review" "CL38b worked example -- In Review transition mirrored to PROJ-45"
assert_file_contains "$MCP_LOG" "POST jira:PROJ-45 state=Done" "CL38c worked example -- Done transition mirrored to PROJ-45"

# Order matters (mirrors the pipeline's own transition order).
first_line=$(sed -n '1p' "$MCP_LOG")
last_line=$(sed -n '3p' "$MCP_LOG")
assert_output_contains "$first_line" "state=In Progress" "CL39a worked example -- transitions mirrored IN ORDER (first = In Progress)"
assert_output_contains "$last_line" "state=Done" "CL39b worked example -- transitions mirrored IN ORDER (last = Done)"

# ===========================================================================
# CL40-CL42  Contrast -- the SAME ticket, but the connector is `api`-typed,
# not `mcp`: aid-managed consumption is out of scope (SPEC.md "Out of Scope /
# Deferred"), so the seam recipe's Step 2 confirmation fails and NO host-MCP
# action fires.
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
