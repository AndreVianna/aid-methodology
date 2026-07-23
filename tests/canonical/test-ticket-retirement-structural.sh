#!/usr/bin/env bash
# test-ticket-retirement-structural.sh -- structural / grep-level guard suite for the
# retirement of the PM-TOOL automated writes, the consolidation of the CONNECTORS seams
# onto the dedicated ticket skills, and the revision of the shared consumption-protocol.md.
# Covers AC-7 (PM-TOOL retirement), AC-8 / AC-9 (seam consolidation + read reroutes),
# and AC-10 / AC-11 / NFR-3 (consumption-protocol revision + no-connector silent-skip).
#
# The host MCP + a live tracker are unavailable in CI, so this suite is
# structural/grep-level only -- it greps canonical/ markdown (never .claude/, which
# is render output) for the documented per-site dispositions, the zero-signature
# sweeps, and the reads-delegate/writes-route contracts, and reads only canonical/
# artifacts (no work-folder or live-tracker dependency).
#
# Byte/path-parity of the *rendered* .claude/ + profiles/* copies is verified by the
# dogfood byte-identity suite, not this one.
#
# Traces:
#   T001-T034  AC-7  -- six FR-7 PM-TOOL sites: per-site old-signature absence +
#                        new disposition (suggestion present + conditional-on-
#                        connector wording, or removed outright with no suggestion)
#   T035-T036  AC-7  -- cross-site zero-signature sweep (write + guard signatures)
#   T037-T042  AC-8  -- state-execute.md mirror section gone; State-Write Protocol
#                        intact; first-run-loop.md Step 4c has no outward
#                        create/register signature, carries the printed
#                        /aid-create-ticket suggestion instead
#   T043-T058  AC-9  -- each of the 8 read-seam anchors (6 file seams + 2 agent
#                        bullets, incl. aid-plan Step 4c's record half and the
#                        aid-review REVIEW read) names /aid-read-ticket and
#                        carries no inline direct-fetch recipe of its own
#   T059-T060  AC-9  -- bounded old-recipe-phrase sweep across every canonical
#                        file this change edited -- zero, since none of them are
#                        one of the three ticket skills or consumption-protocol.md
#   T061-T068  AC-8/AC-9 write-seam reroutes -- aid-review PUBLISH + INTAKE
#                        label, aid-research HANDOFF, aid-report HANDOFF route
#                        through /aid-update-ticket (comment)
#   T069-T086  AC-11 -- consumption-protocol.md: no mirror signature, no
#                        aid-execute Target row, linkage + nearest-ancestor
#                        sections retained, reads-delegate / writes-route
#                        documented inline, Worked example rewritten
#   T087-T098  AC-10/NFR-3 -- the four ticket_ref-carrying templates still
#                        carry their documented carrier; ticket_ref is
#                        documented as user-supplied-only; silent-skip wording
#                        present at five ingest/enrich seams (T092, T097-T098)
#                        and at the connector-gated suggestion sites, incl.
#                        aid-plan Step 4c's create half (T093-T096)
#
# Usage:
#   bash tests/canonical/test-ticket-retirement-structural.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# -- AC-7: six PM-TOOL sites --
DESCRIBE_COMPLETION="${REPO_ROOT}/canonical/skills/aid-describe/references/state-completion.md"
DETAIL_TASKDECOMP="${REPO_ROOT}/canonical/skills/aid-detail/references/task-decomposition.md"
PLAN_SKILL="${REPO_ROOT}/canonical/skills/aid-plan/SKILL.md"
EXECUTE_SKILL="${REPO_ROOT}/canonical/skills/aid-execute/SKILL.md"
DEPLOY_PACKAGING="${REPO_ROOT}/canonical/skills/aid-deploy/references/state-packaging.md"
MONITOR_ROUTE="${REPO_ROOT}/canonical/skills/aid-monitor/references/state-route.md"

# -- AC-8: write-seam sites --
STATE_EXECUTE="${REPO_ROOT}/canonical/skills/aid-execute/references/state-execute.md"
FIRST_RUN_LOOP="${REPO_ROOT}/canonical/skills/aid-plan/references/first-run-loop.md"

# -- AC-9: read-seam sites (4 pure-read + 2 dual-anchor read halves) --
DESCRIBE_FIRSTRUN="${REPO_ROOT}/canonical/skills/aid-describe/references/state-first-run.md"
SPECIFY_INIT="${REPO_ROOT}/canonical/skills/aid-specify/references/state-initialize.md"
SHORTCUT_ENGINE="${REPO_ROOT}/canonical/aid/templates/shortcut-engine.md"
QUERY_KB="${REPO_ROOT}/canonical/skills/aid-query-kb/SKILL.md"
REVIEW_SKILL="${REPO_ROOT}/canonical/skills/aid-review/SKILL.md"
DEVELOPER_AGENT="${REPO_ROOT}/canonical/agents/aid-developer/AGENT.md"
RESEARCHER_AGENT="${REPO_ROOT}/canonical/agents/aid-researcher/AGENT.md"

# -- AC-8/AC-9 (d): comment-write reroutes --
RESEARCH_SKILL="${REPO_ROOT}/canonical/skills/aid-research/SKILL.md"
REPORT_SKILL="${REPO_ROOT}/canonical/skills/aid-report/SKILL.md"

# -- AC-11: shared reference --
CONSUMPTION_PROTOCOL="${REPO_ROOT}/canonical/aid/templates/connectors/consumption-protocol.md"

# -- AC-10/NFR-3: the four ticket_ref-carrying templates (FR-11, untouched) --
WORK_STATE_TPL="${REPO_ROOT}/canonical/aid/templates/work-state-template.md"
DELIVERY_STATE_TPL="${REPO_ROOT}/canonical/aid/templates/delivery-state-template.md"
TASK_STATE_TPL="${REPO_ROOT}/canonical/aid/templates/task-state-template.md"
SPEC_TPL="${REPO_ROOT}/canonical/aid/templates/specs/spec-template.md"

ALL_FILES=(
    "$DESCRIBE_COMPLETION" "$DETAIL_TASKDECOMP" "$PLAN_SKILL" "$EXECUTE_SKILL"
    "$DEPLOY_PACKAGING" "$MONITOR_ROUTE" "$STATE_EXECUTE" "$FIRST_RUN_LOOP"
    "$DESCRIBE_FIRSTRUN" "$SPECIFY_INIT" "$SHORTCUT_ENGINE" "$QUERY_KB"
    "$REVIEW_SKILL" "$DEVELOPER_AGENT" "$RESEARCHER_AGENT" "$RESEARCH_SKILL"
    "$REPORT_SKILL" "$CONSUMPTION_PROTOCOL" "$WORK_STATE_TPL" "$DELIVERY_STATE_TPL"
    "$TASK_STATE_TPL" "$SPEC_TPL"
)
for f in "${ALL_FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        fail "T000 setup -- required file not found: $f"
        test_summary
        exit 1
    fi
done

echo "== ticket-retirement structural guard tests =="

# assert_wrapped_contains FILE PATTERN LABEL -- tolerant of markdown's own line
# wrapping: newlines + runs of whitespace squashed to single spaces before a
# fixed-string search (same helper/convention as test-ticket-skills-structural.sh
# and test-connector-skills-structural.sh).
assert_wrapped_contains() {
    local file="$1" pattern="$2" label="$3" squashed
    squashed="$(sed -E 's/^>[[:space:]]*//' "$file" | tr '\n' ' ' | tr -s ' ')"
    if grep -qF -- "$pattern" <<< "$squashed"; then
        pass "$label"
    else
        fail "$label — pattern not found (line-wrap-tolerant): '$pattern' in $file"
    fi
}

# assert_wrapped_not_contains FILE PATTERN LABEL -- the negative counterpart.
assert_wrapped_not_contains() {
    local file="$1" pattern="$2" label="$3" squashed
    squashed="$(sed -E 's/^>[[:space:]]*//' "$file" | tr '\n' ' ' | tr -s ' ')"
    if grep -qF -- "$pattern" <<< "$squashed"; then
        fail "$label — unexpected pattern found (line-wrap-tolerant): '$pattern' in $file"
    else
        pass "$label"
    fi
}

# ===========================================================================
# T001-T034  AC-7 -- per-site retirement of the six FR-7 PM-TOOL sites
# (per the PM-TOOL retirement disposition table).
# ===========================================================================

# --- Site 1: aid-describe/state-completion.md -- SUGGEST /aid-create-ticket ---
assert_file_not_contains "$DESCRIBE_COMPLETION" 'defines a tool → create an Epic for this work' "T001 site1 aid-describe: old create-Epic write + guard is gone"
assert_file_not_contains "$DESCRIBE_COMPLETION" 'If `infrastructure.md § Project Management`' "T002 site1 aid-describe: old PM-guard clause is gone"
assert_wrapped_contains "$DESCRIBE_COMPLETION" 'If a catalogued `issue-tracker` connector exists in `.aid/connectors/`' "T003 site1 aid-describe: new suggestion is gated on a catalogued issue-tracker connector"
assert_wrapped_contains "$DESCRIBE_COMPLETION" 'run `/aid-create-ticket --level epic' "T004 site1 aid-describe: suggestion names /aid-create-ticket (epic-type)"
assert_wrapped_contains "$DESCRIBE_COMPLETION" 'Optional, user-initiated, never auto-invoked' "T005 site1 aid-describe: suggestion is optional/user-initiated/never-auto-invoked"
assert_wrapped_contains "$DESCRIBE_COMPLETION" 'silent (no output) if no' "T006 site1 aid-describe: silent when no issue-tracker connector is catalogued"

# --- Site 2: aid-detail/task-decomposition.md -- MIXED (suggest create; remove link) ---
assert_file_not_contains "$DETAIL_TASKDECOMP" 'create Tickets/Work Items in the PM tool' "T007 site2 aid-detail: old create-Tickets write is gone"
assert_file_not_contains "$DETAIL_TASKDECOMP" 'Link each ticket to the corresponding Sprint' "T008 site2 aid-detail: link-to-Sprint/Epic bullet is removed outright (no-analog action)"
assert_file_not_contains "$DETAIL_TASKDECOMP" '## Project Management Sync' "T009 site2 aid-detail: old section header is gone"
assert_file_contains "$DETAIL_TASKDECOMP" '## Ticket Suggestion (conditional)' "T010 site2 aid-detail: new Ticket Suggestion header present"
assert_wrapped_contains "$DETAIL_TASKDECOMP" 'If a catalogued `issue-tracker` connector exists in `.aid/connectors/`' "T011 site2 aid-detail: suggestion gated on a catalogued issue-tracker connector"
assert_wrapped_contains "$DETAIL_TASKDECOMP" 'filing a ticket per task via `/aid-create-ticket`' "T012 site2 aid-detail: suggestion names /aid-create-ticket"
assert_wrapped_contains "$DETAIL_TASKDECOMP" 'silent (no output) if no issue-tracker connector is' "T013 site2 aid-detail: silent when no issue-tracker connector is catalogued"

# --- Site 3: aid-plan/SKILL.md -- REMOVE OUTRIGHT, no ticket analog (Sprint/Iteration) ---
assert_file_not_contains "$PLAN_SKILL" 'create Sprint/Iteration entries' "T014 site3 aid-plan: old create-Sprint write is gone"
assert_file_not_contains "$PLAN_SKILL" 'Map deliveries to Sprints' "T015 site3 aid-plan: old map-to-Sprints bullet is gone"
assert_file_not_contains "$PLAN_SKILL" '## Project Management Sync' "T016 site3 aid-plan: old section header is gone"
assert_file_not_contains "$PLAN_SKILL" '## Ticket Suggestion' "T017 site3 aid-plan: no suggestion added -- a Sprint/Iteration has no ticket-scoped analog"
assert_file_not_contains "$PLAN_SKILL" 'aid-create-ticket' "T018 site3 aid-plan/SKILL.md: no dedicated-skill suggestion at all (no-analog action removed outright)"

# --- Site 4: aid-execute/SKILL.md -- SUGGEST /aid-update-ticket status + comment ---
assert_file_not_contains "$EXECUTE_SKILL" 'update corresponding ticket to In Progress' "T019 site4 aid-execute: old status-update write is gone"
assert_file_not_contains "$EXECUTE_SKILL" 'update ticket to Done' "T020 site4 aid-execute: old mark-Done write is gone"
assert_file_not_contains "$EXECUTE_SKILL" 'add comment to ticket with context' "T021 site4 aid-execute: old add-comment write is gone"
assert_file_contains "$EXECUTE_SKILL" '## Ticket Suggestion (conditional)' "T022 site4 aid-execute: new Ticket Suggestion header present"
assert_wrapped_contains "$EXECUTE_SKILL" 'If a catalogued `issue-tracker` connector exists in `.aid/connectors/`' "T023 site4 aid-execute: suggestion gated on a catalogued issue-tracker connector"
assert_wrapped_contains "$EXECUTE_SKILL" 'via `/aid-update-ticket status`' "T024 site4 aid-execute: suggestion names /aid-update-ticket status"
assert_wrapped_contains "$EXECUTE_SKILL" 'via `/aid-update-ticket' "T025 site4 aid-execute: suggestion names /aid-update-ticket comment (loopback)"

# --- Site 5: aid-deploy/state-packaging.md -- MIXED (suggest mark-Done; remove Release+link) ---
assert_file_not_contains "$DEPLOY_PACKAGING" 'Create a Release in the PM tool' "T026 site5 aid-deploy: old create-Release write is removed outright (no analog)"
assert_file_not_contains "$DEPLOY_PACKAGING" 'Link the release to the corresponding Epic' "T027 site5 aid-deploy: old link-release-to-Epic bullet is removed outright (no analog)"
assert_file_contains "$DEPLOY_PACKAGING" '### Step 8: Ticket Suggestion (conditional)' "T028 site5 aid-deploy: new Ticket Suggestion header present"
assert_wrapped_contains "$DEPLOY_PACKAGING" 'via `/aid-update-ticket status`' "T029 site5 aid-deploy: suggestion names /aid-update-ticket status for mark-Done/Closed"

# --- Site 6: aid-monitor/state-route.md -- MIXED (suggest create BUG ticket; remove link) ---
assert_file_not_contains "$MONITOR_ROUTE" 'Create tickets for BUG tasks' "T030 site6 aid-monitor: old create-BUG-tickets write is gone"
assert_file_not_contains "$MONITOR_ROUTE" 'Link to existing Sprint/Epic' "T031 site6 aid-monitor: link-to-Sprint/Epic bullet removed outright (no analog)"
assert_file_not_contains "$MONITOR_ROUTE" 'PM tool ticket creation' "T032 site6 aid-monitor: the old PM-tool timing scaffolding (▶/✓) is gone"
assert_file_not_contains "$MONITOR_ROUTE" 'If PM tool configured' "T033 site6 aid-monitor: old PM-tool-configured guard is gone"
assert_wrapped_contains "$MONITOR_ROUTE" 'filing a ticket for each BUG finding via `/aid-create-ticket`' "T034 site6 aid-monitor: suggestion names /aid-create-ticket for the BUG-ticket create half"

# ===========================================================================
# T035-T036  Cross-site zero-signature sweep (AC-7 -- mechanical spot-check
# across all six skill dirs, write signatures + guard signatures together).
# ===========================================================================
PM_SIG_HITS="$(grep -rniE \
    'create an Epic|create Tickets/Work Items|create Sprint/Iteration|Map deliveries to Sprints|update .* ticket to In Progress|update ticket to Done|add comment to ticket|mark as Done/Closed|Create a Release in the PM tool|create tickets for BUG|Link .*Epic' \
    "${REPO_ROOT}/canonical/skills/aid-describe" "${REPO_ROOT}/canonical/skills/aid-detail" \
    "${REPO_ROOT}/canonical/skills/aid-plan" "${REPO_ROOT}/canonical/skills/aid-execute" \
    "${REPO_ROOT}/canonical/skills/aid-deploy" "${REPO_ROOT}/canonical/skills/aid-monitor" \
    2>/dev/null)"
if [[ -z "$PM_SIG_HITS" ]]; then
    pass "T035 zero-signature sweep: no automated-write signature remains across the six skill dirs"
else
    fail "T035 zero-signature sweep: unexpected write-signature hit(s):"$'\n'"$PM_SIG_HITS"
fi

PM_GUARD_HITS="$(grep -rniE \
    'infrastructure\.md . Project Management. defines a tool|If PM tool configured|If no PM tool' \
    "${REPO_ROOT}/canonical/skills/aid-describe" "${REPO_ROOT}/canonical/skills/aid-detail" \
    "${REPO_ROOT}/canonical/skills/aid-plan" "${REPO_ROOT}/canonical/skills/aid-execute" \
    "${REPO_ROOT}/canonical/skills/aid-deploy" "${REPO_ROOT}/canonical/skills/aid-monitor" \
    2>/dev/null)"
if [[ -z "$PM_GUARD_HITS" ]]; then
    pass "T036 zero-signature sweep: no PM-tool guard signature remains across the six skill dirs"
else
    fail "T036 zero-signature sweep: unexpected guard-signature hit(s):"$'\n'"$PM_GUARD_HITS"
fi

# ===========================================================================
# T037-T042  AC-8 -- aid-execute's status-mirror removed; aid-plan Step 4c's
# outward create/register branch retired (AC-8).
# ===========================================================================
assert_file_not_contains "$STATE_EXECUTE" '## Connector Mirroring' "T037 aid-execute state-execute.md: the Connector Mirroring section header is gone"
assert_file_not_contains "$STATE_EXECUTE" 'mirror the same transition to that ticket via the host tool' "T038 aid-execute state-execute.md: no outward-mirror signature remains"
assert_file_not_contains "$STATE_EXECUTE" "mirrors this task's" "T039 aid-execute state-execute.md: no lifecycle-mirror signature remains"
assert_file_contains "$STATE_EXECUTE" '## MANDATORY: State-Write Protocol' "T040 aid-execute state-execute.md: the mandatory local State-Write Protocol is intact"

assert_wrapped_not_contains "$FIRST_RUN_LOOP" 'create/register it via a catalogued issue-tracker connector' "T041 aid-plan first-run-loop.md Step 4c: the outward create/register signature is gone"
assert_wrapped_contains "$FIRST_RUN_LOOP" 'run `/aid-create-ticket`, then re-record its ref' "T042 aid-plan first-run-loop.md Step 4c: a printed /aid-create-ticket suggestion replaces the retired create/register branch"

# ===========================================================================
# T043-T058  AC-9 -- every rerouted read seam (6 file seams + 2 agent bullets,
# incl. aid-plan Step 4c's record half and the aid-review REVIEW read) names
# /aid-read-ticket and carries no inline direct-fetch recipe of its own
# (AC-9 -- the read-seam contract).
# ===========================================================================
declare -A READ_SEAMS=(
    ["aid-describe state-first-run.md"]="$DESCRIBE_FIRSTRUN"
    ["aid-specify state-initialize.md"]="$SPECIFY_INIT"
    ["aid-plan first-run-loop.md (Step 4c record half)"]="$FIRST_RUN_LOOP"
    ["shortcut-engine.md (Step 4b)"]="$SHORTCUT_ENGINE"
    ["aid-query-kb SKILL.md (Step 2c)"]="$QUERY_KB"
    ["aid-review SKILL.md (REVIEW Gather evidence)"]="$REVIEW_SKILL"
    ["aid-developer AGENT.md"]="$DEVELOPER_AGENT"
    ["aid-researcher AGENT.md"]="$RESEARCHER_AGENT"
)
# Each seam's OWN pre-change inline-recipe wording (verified against `git show
# HEAD:<file>` -- each of these 8 needles is CONFIRMED PRESENT in the
# pre-change file and CONFIRMED ABSENT post-edit, so this is a real
# regression guard per file, not one generic phrase that happens to be vacuous
# for the 3 seams that never worded it that way (aid-review, aid-developer,
# aid-researcher used their own distinct pre-change wording).
declare -A OLD_NEEDLES=(
    ["aid-describe state-first-run.md"]="request the connection from the host tool's own MCP"
    ["aid-specify state-initialize.md"]="request the connection from the host tool's own MCP"
    ["aid-plan first-run-loop.md (Step 4c record half)"]="request the connection from the host tool's own MCP"
    ["shortcut-engine.md (Step 4b)"]="request the connection from the host tool's own MCP"
    ["aid-query-kb SKILL.md (Step 2c)"]="request the connection from the host tool's own MCP"
    ["aid-review SKILL.md (REVIEW Gather evidence)"]="an issue-tracker MCP to fetch a ticket"
    ["aid-developer AGENT.md"]="canonical/aid/templates/connectors/consumption-protocol.md"
    ["aid-researcher AGENT.md"]="canonical/aid/templates/connectors/consumption-protocol.md"
)
i=43
for name in "aid-describe state-first-run.md" "aid-specify state-initialize.md" \
            "aid-plan first-run-loop.md (Step 4c record half)" "shortcut-engine.md (Step 4b)" \
            "aid-query-kb SKILL.md (Step 2c)" "aid-review SKILL.md (REVIEW Gather evidence)" \
            "aid-developer AGENT.md" "aid-researcher AGENT.md"; do
    file="${READ_SEAMS[$name]}"
    needle="${OLD_NEEDLES[$name]}"
    if grep -qF -- "/aid-read-ticket" "$file"; then
        pass "T0${i} ${name}: names /aid-read-ticket as the fetch surface"
    else
        fail "T0${i} ${name}: does not name /aid-read-ticket — pattern not found in $file"
    fi
    i=$((i + 1))
    if grep -qF -- "$needle" "$file"; then
        fail "T0${i} ${name}: still carries its own old inline direct-fetch recipe ('$needle')"
    else
        pass "T0${i} ${name}: carries no inline direct-fetch recipe of its own"
    fi
    i=$((i + 1))
done

# ===========================================================================
# T059-T060  Bounded old-recipe-phrase sweep -- across every canonical/ file
# this change edited. None of them is one of the three ticket skills
# (aid-read-ticket/aid-create-ticket/aid-update-ticket, added as whole new
# files) or consumption-protocol.md's own header note, so a zero-hit result
# here is the "outside the three ticket skills + consumption-protocol/
# ticket-resolution shared refs" carve-out from the AC-9 spot-check, scoped to
# this change's own edit set (not the unrelated, untouched connector-
# registration subsystem -- reconcile.md, aid-set-connector, aid-discover --
# which this change never touches; AC-9 Boundaries).
# ===========================================================================
DELIVERY_002_FILES=(
    "$DESCRIBE_COMPLETION" "$DETAIL_TASKDECOMP" "$PLAN_SKILL" "$EXECUTE_SKILL"
    "$DEPLOY_PACKAGING" "$MONITOR_ROUTE" "$STATE_EXECUTE" "$FIRST_RUN_LOOP"
    "$DESCRIBE_FIRSTRUN" "$SPECIFY_INIT" "$SHORTCUT_ENGINE" "$QUERY_KB"
    "$REVIEW_SKILL" "$DEVELOPER_AGENT" "$RESEARCHER_AGENT" "$RESEARCH_SKILL"
    "$REPORT_SKILL" "$CONSUMPTION_PROTOCOL"
)
OLD_RECIPE_HITS=""
for f in "${DELIVERY_002_FILES[@]}"; do
    if grep -qF -- "request the connection from the host tool's own MCP" "$f"; then
        OLD_RECIPE_HITS+="$f"$'\n'
    fi
done
if [[ -z "$OLD_RECIPE_HITS" ]]; then
    pass "T059 old direct-fetch recipe phrase appears in none of the 18 canonical files edited by this change"
else
    fail "T059 old direct-fetch recipe phrase unexpectedly found in:"$'\n'"$OLD_RECIPE_HITS"
fi
# Sanity companion: the phrase must still exist SOMEWHERE (it's a real recipe
# step owned by the three ticket skills) -- a suite that could never fail
# T059 (e.g. a typo'd needle) would be a false-negative test, not a real guard.
if grep -qF -- "request the connection from the host tool's own MCP" \
    "${REPO_ROOT}/canonical/skills/aid-update-ticket/SKILL.md" 2>/dev/null; then
    pass "T060 self-check: the needle string is real (found in aid-update-ticket/SKILL.md, one of the three ticket skills)"
else
    fail "T060 self-check: the needle string was not found anywhere -- T059 would be a false-negative guard"
fi

# ===========================================================================
# T061-T068  Write-seam reroutes -- the three human-gated comment writes route
# through /aid-update-ticket, stay user-authorized, never auto-invoked
# (AC-8/AC-9 (d)).
# ===========================================================================
assert_file_contains "$REVIEW_SKILL" 'ticket comment via `/aid-update-ticket`' "T061 aid-review INTAKE fast-path label names /aid-update-ticket"
assert_file_not_contains "$REVIEW_SKILL" 'ticket comment via an MCP connector' "T062 aid-review INTAKE fast-path label: old MCP-connector wording is gone"
assert_wrapped_contains "$REVIEW_SKILL" 'a ticket comment via `/aid-update-ticket comment [<connector>:]<ticket-id> <text>`' "T063 aid-review PUBLISH: ticket comment delivery routes through /aid-update-ticket comment"
assert_file_not_contains "$REVIEW_SKILL" 'a ticket comment via the MCP connector' "T064 aid-review PUBLISH: old MCP-connector delivery wording is gone"

assert_wrapped_contains "$RESEARCH_SKILL" 'a source ticket (`/aid-update-ticket comment [<connector>:]<ticket-id> <text>`)' "T065 aid-research HANDOFF: comment suggestion routes through /aid-update-ticket comment"
assert_file_not_contains "$RESEARCH_SKILL" 'MCP connector' "T066 aid-research HANDOFF: old MCP-connector clause is gone"

assert_wrapped_contains "$REPORT_SKILL" 'or comment on a source ticket (`/aid-update-ticket comment [<connector>:]<ticket-id> <text>`)' "T067 aid-report HANDOFF: comment suggestion routes through /aid-update-ticket comment"
assert_wrapped_contains "$RESEARCH_SKILL" 'Never auto-invoked; never a resolution' "T068 aid-research HANDOFF: still never-auto-invoked / never-a-resolution"

# ===========================================================================
# T069-T086  AC-11 -- consumption-protocol.md revision (E1-E7).
# ===========================================================================
MIRROR_HITS="$(grep -in 'mirror' "$CONSUMPTION_PROTOCOL" || true)"
if [[ -z "$MIRROR_HITS" ]]; then
    pass "T069 consumption-protocol.md: grep -i mirror -> 0 hits"
else
    fail "T069 consumption-protocol.md: unexpected 'mirror' hit(s):"$'\n'"$MIRROR_HITS"
fi

if grep -qE '\| .aid-execute. \|' "$CONSUMPTION_PROTOCOL"; then
    fail "T070 consumption-protocol.md: the aid-execute Target row is still present"
else
    pass "T070 consumption-protocol.md: the aid-execute Target row is absent"
fi
assert_file_not_contains "$CONSUMPTION_PROTOCOL" '| Target |' "T071 consumption-protocol.md: no seam carries the Target role any more"
assert_wrapped_not_contains "$CONSUMPTION_PROTOCOL" 'Read or write through the host MCP' "T072 consumption-protocol.md: the old read-or-write Step-4 lead is gone"
assert_file_contains "$CONSUMPTION_PROTOCOL" '## Multi-level `ticket_ref` linkage' "T073 consumption-protocol.md: the ticket_ref linkage section is retained"
assert_file_contains "$CONSUMPTION_PROTOCOL" '## Nearest-ancestor resolution' "T074 consumption-protocol.md: the nearest-ancestor resolution section is retained"
assert_file_contains "$CONSUMPTION_PROTOCOL" 'task → its owning (SPEC-traced) feature → its delivery → work' "T075 consumption-protocol.md: the containment chains table is byte-identical (task row)"
assert_wrapped_contains "$CONSUMPTION_PROTOCOL" 'Why feature outranks delivery for a task' "T076 consumption-protocol.md: the 'why feature outranks delivery' rationale is retained"
assert_file_contains "$CONSUMPTION_PROTOCOL" 'Terminal case' "T077 consumption-protocol.md: the terminal silent-skip case is retained"
assert_wrapped_contains "$CONSUMPTION_PROTOCOL" '**Read, then stop.**' "T078 consumption-protocol.md: seam-recipe Step 4 is renamed 'Read, then stop.'"
assert_wrapped_not_contains "$CONSUMPTION_PROTOCOL" '**Act, then stop.**' "T079 consumption-protocol.md: the old 'Act, then stop.' lead is gone"
assert_wrapped_contains "$CONSUMPTION_PROTOCOL" 'when the seam is reading a ticket' "T080 consumption-protocol.md: seam-recipe Step 1 purpose example is read-only (filing dropped)"
assert_file_not_contains "$CONSUMPTION_PROTOCOL" '## Worked example (AC9)' "T081 consumption-protocol.md: the old worked-example header is gone"
assert_file_contains "$CONSUMPTION_PROTOCOL" '## Worked example (nearest-ancestor resolution)' "T082 consumption-protocol.md: the worked example is retitled to nearest-ancestor resolution"
assert_wrapped_contains "$CONSUMPTION_PROTOCOL" 'No automated caller acts on this resolution' "T083 consumption-protocol.md: worked example states no automated caller acts on the resolution"
READS_DELEGATE_COUNT="$(grep -oF -- '/aid-read-ticket' "$CONSUMPTION_PROTOCOL" | wc -l | tr -d ' ')"
if [[ "$READS_DELEGATE_COUNT" -ge 5 ]]; then
    pass "T084 consumption-protocol.md: reads-delegate-to-/aid-read-ticket is documented at multiple seam rows ($READS_DELEGATE_COUNT mentions)"
else
    fail "T084 consumption-protocol.md: expected >=5 /aid-read-ticket mentions documenting the delegated-read model, found $READS_DELEGATE_COUNT"
fi
assert_file_contains "$CONSUMPTION_PROTOCOL" '/aid-create-ticket' "T085 consumption-protocol.md: writes-route documents /aid-create-ticket"
assert_file_contains "$CONSUMPTION_PROTOCOL" '/aid-update-ticket' "T086 consumption-protocol.md: writes-route documents /aid-update-ticket"

# ===========================================================================
# T087-T097  AC-10 / NFR-3 -- the four ticket_ref-carrying templates are
# unchanged (still carry their documented carrier); ticket_ref is documented
# as user-supplied-only; silent-skip wording present at representative seams
# (T092, T096-T097) and at the three remaining PM-TOOL suggestion sites
# (T093-T095).
# ===========================================================================
assert_file_contains "$WORK_STATE_TPL" 'ticket_ref' "T087 work-state-template.md still carries the ticket_ref frontmatter key (FR-11 untouched)"
assert_file_contains "$DELIVERY_STATE_TPL" 'ticket_ref' "T088 delivery-state-template.md still carries the ticket_ref frontmatter key (FR-11 untouched)"
assert_file_contains "$TASK_STATE_TPL" 'ticket_ref' "T089 task-state-template.md still carries the ticket_ref frontmatter key (FR-11 untouched)"
assert_file_contains "$SPEC_TPL" 'Ticket:' "T090 specs/spec-template.md still carries the '> **Ticket:**' line (FR-11 untouched)"
assert_wrapped_contains "$CONSUMPTION_PROTOCOL" 'sourced from a **user-supplied ref**' "T091 consumption-protocol.md: ticket_ref is documented as populated only from a user-supplied ref"
assert_wrapped_contains "$DESCRIBE_FIRSTRUN" 'Skip silently when no such ticket is named or no matching connector is catalogued' "T092 aid-describe state-first-run.md: silent-skip on no-connector/no-ticket_ref is documented"

# --- T093-T096: the "silent (no output)" gating clause, spot-checked across
# the create-suggestion site + the remaining PM-TOOL suggestion sites (site1/
# site2 already covered by T006/T013) -- enumerating the class of connector-
# gated suggestion sites, not just one instance (self-review: "Fix everywhere"
# applies equally to "verify everywhere"). Includes aid-plan first-run-loop.md
# Step 4c's create half, whose missing gate was a gate-caught HIGH
# regression -- this asserts the fix and guards the class against recurrence.
declare -A SILENT_GATE_SITES=(
    ["site3c aid-plan first-run-loop (create half)"]="$FIRST_RUN_LOOP"
    ["site4 aid-execute"]="$EXECUTE_SKILL"
    ["site5 aid-deploy"]="$DEPLOY_PACKAGING"
    ["site6 aid-monitor"]="$MONITOR_ROUTE"
)
j=93
for sitename in "site3c aid-plan first-run-loop (create half)" "site4 aid-execute" "site5 aid-deploy" "site6 aid-monitor"; do
    sfile="${SILENT_GATE_SITES[$sitename]}"
    if grep -qF -- "silent (no output) if no" "$sfile"; then
        pass "T0${j} ${sitename}: suggestion is silent (no output) when no issue-tracker connector is catalogued"
    else
        fail "T0${j} ${sitename}: missing the silent (no output) gating clause in $sfile"
    fi
    j=$((j + 1))
done

# --- T097-T098: silent-skip wording at two further rerouted read seams
# (aid-specify, shortcut-engine), rounding out the AC-10/NFR-3 "every edited
# seam" spot-check beyond the single aid-describe example (T092). ---
assert_wrapped_contains "$SPECIFY_INIT" 'Skip silently when no such ticket applies or no matching connector is catalogued' "T097 aid-specify state-initialize.md: silent-skip on no-connector/no-ticket_ref is documented"
assert_wrapped_contains "$SHORTCUT_ENGINE" 'Skip silently when no such ticket applies or no matching connector is catalogued' "T098 shortcut-engine.md Step 4b: silent-skip on no-connector/no-ticket_ref is documented"

# ===========================================================================
test_summary
