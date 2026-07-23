#!/usr/bin/env bash
# test-ticket-skills-structural.sh -- structural / parse-level guard suite for
# work-023-ticket-integration's three dedicated ticket-tracker skills
# (aid-read-ticket, aid-create-ticket, aid-update-ticket) and the shared
# ticket-resolution.md reference they all point to
# (features/feature-001-dedicated-ticket-skills/SPEC.md).
#
# The host MCP + a live tracker are unavailable in CI, so this suite is
# structural/parse-level only -- it greps the canonical/ markdown for the
# documented contract (frontmatter, Feature-Flow states, grammar rules,
# ladder branches, confirm-gate conventions), never makes a live MCP call,
# and never depends on any .aid/works/work-023* path (work-folder-
# transience rule -- these are canonical/ artifacts, not work-folder ones).
#
# Byte/path-parity of the *rendered* .claude/ copies is delivery-003's gate,
# not this suite's (feature-001 SPEC.md § Testing).
#
# Traces (feature-001 AC-1..AC-6):
#   T01-T18   Anatomy -- frontmatter (name, one-pass description,
#             allowed-tools incl. AskUserQuestion / excl. Write+Edit,
#             argument-hint = the bare grammar line) for all 3 skills
#   T19-T35   Anatomy -- Feature-Flow durable state headers present:
#             read PARSE-ARGS/RESOLVE-CONNECTOR/FETCH/DISPLAY; create
#             PARSE-ARGS/RESOLVE-CONNECTOR/COMPOSE/LEVEL-RESOLVE/CONFIRM/
#             FILE/RETURN-REF; update PARSE-ARGS/RESOLVE-CONNECTOR/
#             LOAD-CONTEXT/COMPOSE/CONFIRM/WRITE
#   T36-T44   DRY -- all 3 skills point to ticket-resolution.md and do NOT
#             re-list the ladder's numbered steps or the level-resolution
#             synonym set inline
#   T45-T52   Confirm gate -- present (AskUserQuestion + button row) in
#             create/update; absent in read; the button-row copy is
#             byte-identical across create/update/the shared ref (AC-1,
#             AC-2, AC-3)
#   T53-T63   Grammar matrix -- read stem:id split; update part closed
#             enum + reject + verbatim content; create --connector (no
#             leading-token heuristic), --level accept/reject/quoted-
#             literal, --parent, flags-any-order, missing-description usage
#             line (AC-2, AC-3)
#   T64-T73   Resolution-ladder branch coverage -- explicit override,
#             single-silent, 2+-ask, host-MCP fallback, the verbatim notify
#             string, api/ssh/cli fall-through, and each skill's own
#             per-state routing of those outcomes (AC-4, AC-5, AC-6)
#   T74-T81   Create level & parent behavior -- no silent level default,
#             description-inferred level surfaced (not silently applied),
#             ordered synonym set + quoted-literal override, graceful
#             degradation to a plain issue + optional type:<tier> label,
#             best-effort parent linking, cross-tracker parent stop (AC-2)
#   T82-T85   Update status validation + part semantics -- invalid
#             transition lists valid targets and stops before confirm,
#             capability-gap graceful fallback, description REPLACES,
#             comment APPENDS (AC-3)
#   T86-T88   Each skill carries the verbatim "no issue-tracker connector
#             found." notify string (AC-6)
#   T89       This suite makes no reference to any .aid/works/work-023*
#             path (work-folder-transience rule, self-check)
#
# Usage:
#   bash tests/canonical/test-ticket-skills-structural.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
READ_SKILL="${REPO_ROOT}/canonical/skills/aid-read-ticket/SKILL.md"
CREATE_SKILL="${REPO_ROOT}/canonical/skills/aid-create-ticket/SKILL.md"
UPDATE_SKILL="${REPO_ROOT}/canonical/skills/aid-update-ticket/SKILL.md"
SHARED_REF="${REPO_ROOT}/canonical/aid/templates/connectors/ticket-resolution.md"

for f in "$READ_SKILL" "$CREATE_SKILL" "$UPDATE_SKILL" "$SHARED_REF"; do
    if [[ ! -f "$f" ]]; then
        fail "T00 setup -- required file not found: $f"
        test_summary
        exit 1
    fi
done

echo "== ticket-skills structural guard tests =="

# assert_wrapped_contains FILE PATTERN LABEL -- like assert_file_contains,
# but tolerant of markdown's own line-wrapping: newlines and runs of
# whitespace are squashed to single spaces before the fixed-string search,
# so a phrase that happens to wrap across two source lines is still found.
# (Same helper/convention as test-connector-skills-structural.sh.)
assert_wrapped_contains() {
    local file="$1" pattern="$2" label="$3" squashed
    squashed="$(sed -E 's/^>[[:space:]]*//' "$file" | tr '\n' ' ' | tr -s ' ')"
    if grep -qF -- "$pattern" <<< "$squashed"; then
        pass "$label"
    else
        fail "$label — pattern not found (line-wrap-tolerant): '$pattern' in $file"
    fi
}

# assert_header FILE TOKEN LABEL -- true when TOKEN (an ALL-CAPS state name,
# e.g. PARSE-ARGS) appears as a whole word inside a markdown header line
# (## through #####). Case-sensitive by design: state tokens are always
# spelled ALL-CAPS in these SKILL.md files, so this never false-matches an
# unrelated mixed-case header (e.g. "### WRITE (host MCP)" matches the WRITE
# state; "## Write-zone" does not, because "Write" is not all-caps).
assert_header() {
    local file="$1" token="$2" label="$3"
    if grep -qE "^#{2,5}[^#].*\\b${token}\\b" "$file"; then
        pass "$label"
    else
        fail "$label — no markdown header containing '$token' found in $file"
    fi
}

# ===========================================================================
# T01-T18  Anatomy -- frontmatter, per skill.
# ===========================================================================
assert_file_contains "$READ_SKILL" "name: aid-read-ticket" "T01 aid-read-ticket frontmatter name"
assert_wrapped_contains "$READ_SKILL" "description: >" "T02 aid-read-ticket has a one-pass (folded-scalar) description field"
assert_file_contains "$READ_SKILL" "allowed-tools: Read, Glob, Grep, AskUserQuestion" "T03 aid-read-ticket allowed-tools includes AskUserQuestion"
grep -qE '^allowed-tools:.*\bWrite\b' "$READ_SKILL" && fail "T04 aid-read-ticket allowed-tools must NOT include Write" || pass "T04 aid-read-ticket allowed-tools excludes Write"
grep -qE '^allowed-tools:.*\bEdit\b' "$READ_SKILL" && fail "T05 aid-read-ticket allowed-tools must NOT include Edit" || pass "T05 aid-read-ticket allowed-tools excludes Edit"
assert_file_contains "$READ_SKILL" 'argument-hint: "[<connector>:]<ticket-id>"' "T06 aid-read-ticket argument-hint = the bare grammar line"

assert_file_contains "$CREATE_SKILL" "name: aid-create-ticket" "T07 aid-create-ticket frontmatter name"
assert_wrapped_contains "$CREATE_SKILL" "description: >" "T08 aid-create-ticket has a one-pass (folded-scalar) description field"
assert_file_contains "$CREATE_SKILL" "allowed-tools: Read, Glob, Grep, AskUserQuestion" "T09 aid-create-ticket allowed-tools includes AskUserQuestion"
grep -qE '^allowed-tools:.*\bWrite\b' "$CREATE_SKILL" && fail "T10 aid-create-ticket allowed-tools must NOT include Write" || pass "T10 aid-create-ticket allowed-tools excludes Write"
grep -qE '^allowed-tools:.*\bEdit\b' "$CREATE_SKILL" && fail "T11 aid-create-ticket allowed-tools must NOT include Edit" || pass "T11 aid-create-ticket allowed-tools excludes Edit"
assert_file_contains "$CREATE_SKILL" 'argument-hint: "[--connector <stem>] [--level epic|story|task] [--parent <ref>] <description>"' "T12 aid-create-ticket argument-hint = the bare grammar line"

assert_file_contains "$UPDATE_SKILL" "name: aid-update-ticket" "T13 aid-update-ticket frontmatter name"
assert_wrapped_contains "$UPDATE_SKILL" "description: >" "T14 aid-update-ticket has a one-pass (folded-scalar) description field"
assert_file_contains "$UPDATE_SKILL" "allowed-tools: Read, Glob, Grep, AskUserQuestion" "T15 aid-update-ticket allowed-tools includes AskUserQuestion"
grep -qE '^allowed-tools:.*\bWrite\b' "$UPDATE_SKILL" && fail "T16 aid-update-ticket allowed-tools must NOT include Write" || pass "T16 aid-update-ticket allowed-tools excludes Write"
grep -qE '^allowed-tools:.*\bEdit\b' "$UPDATE_SKILL" && fail "T17 aid-update-ticket allowed-tools must NOT include Edit" || pass "T17 aid-update-ticket allowed-tools excludes Edit"
assert_file_contains "$UPDATE_SKILL" 'argument-hint: "<part> [<connector>:]<ticket-id> <content>"' "T18 aid-update-ticket argument-hint = the bare grammar line"

# ===========================================================================
# T19-T35  Anatomy -- Feature-Flow durable state headers present.
# ===========================================================================
assert_header "$READ_SKILL" "PARSE-ARGS" "T19 aid-read-ticket has a PARSE-ARGS state header"
assert_header "$READ_SKILL" "RESOLVE-CONNECTOR" "T20 aid-read-ticket has a RESOLVE-CONNECTOR state header"
assert_header "$READ_SKILL" "FETCH" "T21 aid-read-ticket has a FETCH state header"
assert_header "$READ_SKILL" "DISPLAY" "T22 aid-read-ticket has a DISPLAY state header"

assert_header "$CREATE_SKILL" "PARSE-ARGS" "T23 aid-create-ticket has a PARSE-ARGS state header"
assert_header "$CREATE_SKILL" "RESOLVE-CONNECTOR" "T24 aid-create-ticket has a RESOLVE-CONNECTOR state header"
assert_header "$CREATE_SKILL" "COMPOSE" "T25 aid-create-ticket has a COMPOSE state header"
assert_header "$CREATE_SKILL" "LEVEL-RESOLVE" "T26 aid-create-ticket has a LEVEL-RESOLVE state header"
assert_header "$CREATE_SKILL" "CONFIRM" "T27 aid-create-ticket has a CONFIRM state header"
assert_header "$CREATE_SKILL" "FILE" "T28 aid-create-ticket has a FILE state header"
assert_header "$CREATE_SKILL" "RETURN-REF" "T29 aid-create-ticket has a RETURN-REF state header"

assert_header "$UPDATE_SKILL" "PARSE-ARGS" "T30 aid-update-ticket has a PARSE-ARGS state header"
assert_header "$UPDATE_SKILL" "RESOLVE-CONNECTOR" "T31 aid-update-ticket has a RESOLVE-CONNECTOR state header"
assert_header "$UPDATE_SKILL" "LOAD-CONTEXT" "T32 aid-update-ticket has a LOAD-CONTEXT state header"
assert_header "$UPDATE_SKILL" "COMPOSE" "T33 aid-update-ticket has a COMPOSE state header"
assert_header "$UPDATE_SKILL" "CONFIRM" "T34 aid-update-ticket has a CONFIRM state header"
assert_header "$UPDATE_SKILL" "WRITE" "T35 aid-update-ticket has a WRITE state header"

# ===========================================================================
# T36-T44  DRY -- pointer to ticket-resolution.md present; ladder's own
# numbered steps and the level-resolution synonym set are NEVER re-listed
# inline in any of the 3 skills (SPEC.md § Layers & Components, decision 1).
# ===========================================================================
assert_file_contains "$READ_SKILL" "ticket-resolution.md" "T36 aid-read-ticket points to ticket-resolution.md"
assert_file_contains "$CREATE_SKILL" "ticket-resolution.md" "T37 aid-create-ticket points to ticket-resolution.md"
assert_file_contains "$UPDATE_SKILL" "ticket-resolution.md" "T38 aid-update-ticket points to ticket-resolution.md"

for pair in "READ_SKILL:$READ_SKILL" "CREATE_SKILL:$CREATE_SKILL" "UPDATE_SKILL:$UPDATE_SKILL"; do
    name="${pair%%:*}"; file="${pair#*:}"
    if grep -qE '^[0-9]\. \*\*(Explicit|Scan|None catalogued|Neither available)' "$file"; then
        fail "T39/T40/T41 $name re-lists the ladder's own numbered steps inline (must point to ticket-resolution.md instead)"
    else
        pass "T39/T40/T41 $name does not re-list the ladder's numbered steps inline"
    fi
done

for pair in "READ_SKILL:$READ_SKILL" "CREATE_SKILL:$CREATE_SKILL" "UPDATE_SKILL:$UPDATE_SKILL"; do
    name="${pair%%:*}"; file="${pair#*:}"
    if grep -qF "Epic / Initiative" "$file"; then
        fail "T42/T43/T44 $name re-lists the level-resolution ordered synonym set inline (must point to ticket-resolution.md instead)"
    else
        pass "T42/T43/T44 $name does not re-list the level-resolution ordered synonym set inline"
    fi
done

# ===========================================================================
# T45-T52  Confirm gate -- present (AskUserQuestion + button row) in
# create/update; absent in read; button-row copy byte-identical across
# create/update/the shared reference.
# ===========================================================================
assert_wrapped_contains "$CREATE_SKILL" "single in-run \`AskUserQuestion\` exchange" "T45 aid-create-ticket's CONFIRM state is a single in-run AskUserQuestion exchange"
assert_file_contains "$CREATE_SKILL" "[1] File it · [2] Edit · [3] Cancel" "T46 aid-create-ticket shows the [1]/[2]/[3] confirm button row"
assert_wrapped_contains "$UPDATE_SKILL" "single in-invocation confirm" "T47 aid-update-ticket's CONFIRM state is a single in-invocation confirm"
assert_file_contains "$UPDATE_SKILL" "[1] File it · [2] Edit · [3] Cancel" "T48 aid-update-ticket shows the [1]/[2]/[3] confirm button row"
assert_file_not_contains "$READ_SKILL" "[1] File it · [2] Edit · [3] Cancel" "T49 aid-read-ticket never shows the confirm button row (non-destructive, no write)"
assert_wrapped_contains "$READ_SKILL" "No confirmation prompt, ever" "T50 aid-read-ticket documents it never shows a confirmation prompt"

# T51/T52 -- extract the exact button-row line (trimmed) from each file and
# assert byte-identity across create/update/shared-ref (not just "contains").
BTN_RE='^[[:space:]]*\[1\] File it · \[2\] Edit · \[3\] Cancel[[:space:]]*$'
create_btn="$(grep -E "$BTN_RE" "$CREATE_SKILL" | head -1 | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"
update_btn="$(grep -E "$BTN_RE" "$UPDATE_SKILL" | head -1 | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"
sharedref_btn="$(grep -E "$BTN_RE" "$SHARED_REF" | head -1 | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')"
assert_eq "$create_btn" "$update_btn" "T51 create's confirm button row is byte-identical to update's"
assert_eq "$create_btn" "$sharedref_btn" "T52 create's confirm button row is byte-identical to the shared reference's"

# ===========================================================================
# T53-T63  Grammar matrix.
# ===========================================================================
assert_wrapped_contains "$READ_SKILL" "the token contains a \`:\` → split on the **first** \`:\`" "T53 aid-read-ticket PARSE-ARGS splits stem:id on the first colon"
assert_wrapped_contains "$UPDATE_SKILL" "closed enum \`description | comment | status\`" "T54 aid-update-ticket <part> is the closed enum {description,comment,status}"
assert_wrapped_contains "$UPDATE_SKILL" "rejected with the same usage line above" "T55 aid-update-ticket rejects an out-of-enum <part> with the usage line"
assert_wrapped_contains "$UPDATE_SKILL" "re-parsed** for flags or further structure" "T56 aid-update-ticket <content> is taken verbatim, never re-parsed"
assert_file_contains "$CREATE_SKILL" "bare-leading-token connector heuristic" "T57 aid-create-ticket documents it has no bare-leading-token connector heuristic"
assert_wrapped_contains "$CREATE_SKILL" "closed canonical enum \`epic|story|task\` (case-insensitive)" "T58 aid-create-ticket --level accepts the closed epic|story|task enum, case-insensitive"
assert_wrapped_contains "$CREATE_SKILL" "quoted is rejected — print the usage line" "T59 aid-create-ticket rejects a bare non-tier --level value"
assert_file_contains "$CREATE_SKILL" "Quoted literal passthrough" "T60 aid-create-ticket --level supports the quoted-literal passthrough"
assert_wrapped_contains "$CREATE_SKILL" "capture one ticket ref (\`[<stem>:]<external-id>\`) verbatim" "T61 aid-create-ticket --parent takes one ticket ref"
assert_wrapped_contains "$CREATE_SKILL" "may appear in **any order** before the trailing free-text \`<description>\`" "T62 aid-create-ticket flags parse in any order before the description"
assert_wrapped_contains "$CREATE_SKILL" "after the flags are consumed (nothing left, or only whitespace)" "T63 aid-create-ticket prints the usage line when <description> is missing"

# ===========================================================================
# T64-T73  Resolution-ladder branch coverage (shared reference + each
# skill's own per-state routing of the ladder's outcomes).
# ===========================================================================
assert_wrapped_contains "$SHARED_REF" "Either form **always overrides** the scan below" "T64 shared ref: explicit connector always overrides the scan"
assert_wrapped_contains "$SHARED_REF" "Exactly one** \`mcp\` + \`issue-tracker\` match → **use it silently**" "T65 shared ref: exactly one catalogued match is used silently"
assert_wrapped_contains "$SHARED_REF" "Two or more** → ask the user which via \`AskUserQuestion\`" "T66 shared ref: two-or-more catalogued matches ask via AskUserQuestion"
assert_wrapped_contains "$SHARED_REF" "None catalogued** → request the **host tool's own** issue-tracker MCP" "T67 shared ref: zero catalogued matches fall through to the host tool's own MCP"
assert_file_contains "$SHARED_REF" "no issue-tracker connector found." "T68 shared ref: the verbatim notify string is present"
assert_file_contains "$SHARED_REF" '`api` / `ssh` / `cli` fall-through' "T69 shared ref: an api/ssh/cli fall-through section exists"
assert_wrapped_contains "$SHARED_REF" "so resolution falls through to Step 3/4" "T70 shared ref: a non-mcp connector falls through to Step 3/4"
assert_wrapped_contains "$READ_SKILL" "one \`mcp\` + \`issue-tracker\` connector → use it silently" "T71 aid-read-ticket routes the ladder's single-match outcome to its own State 2"
assert_wrapped_contains "$CREATE_SKILL" "match (silent) or an" "T72 aid-create-ticket's RESOLVE-CONNECTOR routes all four ladder outcomes (silent/ask/host-MCP/notify)"
assert_file_contains "$UPDATE_SKILL" "exactly-one-silent → two-or-more-ask" "T73 aid-update-ticket's RESOLVE-CONNECTOR routes all four ladder outcomes (silent/ask/host-MCP/notify)"

# ===========================================================================
# T74-T81  Create level & parent behavior (AC-2).
# ===========================================================================
assert_file_contains "$CREATE_SKILL" "No silent level default" "T74 aid-create-ticket: no silent level default -- the pick is mandatory at CONFIRM when unset"
assert_file_contains "$CREATE_SKILL" "never silently applied" "T75 aid-create-ticket: a description-inferred level is surfaced for confirmation, never silently applied"
assert_file_contains "$CREATE_SKILL" "ordered synonym set, first available wins" "T76 aid-create-ticket: tier-to-tracker-type resolution uses the ordered synonym set, first available wins"
assert_wrapped_contains "$CREATE_SKILL" "skips synonym-matching entirely" "T77 aid-create-ticket: the quoted-literal passthrough skips synonym-matching entirely"
assert_file_contains "$CREATE_SKILL" "plain issue" "T78 aid-create-ticket: graceful degradation files a plain issue when no tier matches"
assert_file_contains "$CREATE_SKILL" 'type:<tier>' "T79 aid-create-ticket: graceful degradation optionally applies a type:<tier> label"
assert_wrapped_contains "$CREATE_SKILL" "is **reported, not fatal** — the create still succeeds" "T80 aid-create-ticket: a missing/rejected parent link is reported, not fatal -- the create still succeeds"
assert_wrapped_contains "$CREATE_SKILL" "parent must be on the same tracker as the" "T81 aid-create-ticket: a cross-tracker --parent stops the run before CONFIRM"

# ===========================================================================
# T82-T85  Update status validation + per-part semantics (AC-3).
# ===========================================================================
assert_wrapped_contains "$UPDATE_SKILL" "list the valid targets and stop" "T82 aid-update-ticket: an invalid status transition lists the valid targets and stops before CONFIRM"
assert_wrapped_contains "$UPDATE_SKILL" "a capability gap, not an error" "T83 aid-update-ticket: a tracker that cannot enumerate transitions is a capability gap, not an error"
assert_wrapped_contains "$UPDATE_SKILL" "\`description\` → REPLACES" "T84 aid-update-ticket: description REPLACES the field"
assert_wrapped_contains "$UPDATE_SKILL" "\`comment\` → APPENDS" "T85 aid-update-ticket: comment APPENDS a new comment"

# ===========================================================================
# T86-T88  Every skill carries the verbatim notify string (AC-6).
# ===========================================================================
assert_file_contains "$READ_SKILL" '"no issue-tracker connector found."' "T86 aid-read-ticket carries the verbatim notify string"
assert_file_contains "$CREATE_SKILL" "no issue-tracker connector found." "T87 aid-create-ticket carries the verbatim notify string"
assert_file_contains "$UPDATE_SKILL" '"no issue-tracker connector found."' "T88 aid-update-ticket carries the verbatim notify string"

# ===========================================================================
# T89  Work-folder-transience self-check: this suite depends on no
# .aid/works/work-023* path (feature-001 SPEC.md § Testing; task-005 scope).
# Only non-comment (code) lines are checked -- this header/trace prose
# itself legitimately NAMES the rule it satisfies, in comment lines, without
# violating it; what must never happen is a live PATH DEPENDENCY in an
# executable line (a variable, a test -f, a source/cat/grep target, etc.).
# ===========================================================================
THIS_FILE="${BASH_SOURCE[0]}"
# Built from two fragments so THIS line never itself contains the
# contiguous forbidden substring (which would trivially self-match).
_wf_frag_a=".aid/works/work"
_wf_frag_b="-023"
_wf_needle="${_wf_frag_a}${_wf_frag_b}"
if grep -vE '^[[:space:]]*#' "$THIS_FILE" | grep -qF -- "$_wf_needle"; then
    fail "T89 this suite must not DEPEND on any work-023 work-folder path in a code line"
else
    pass "T89 this suite depends on no work-023 work-folder path (code lines only; header prose is exempt)"
fi

# ===========================================================================
test_summary
