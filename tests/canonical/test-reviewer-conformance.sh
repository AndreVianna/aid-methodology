#!/usr/bin/env bash
# test-reviewer-conformance.sh -- the spine's terminus.
#
# Seven deliveries edited canonical/agents/aid-reviewer/AGENT.md, each owning declared regions of it.
# This suite is the proof that the region-ownership arithmetic held: it asserts the file's END STATE,
# so a later delivery that quietly undid an earlier one's edit fails here.
#
# EVERY ASSERTION IS A CONTENT ANCHOR, NEVER A LINE NUMBER. Line numbers in the specs that planned this
# work all drifted, because each of the seven deliveries changed the file's length. An assertion keyed
# to a line number would have started failing for the wrong reason around delivery-005.
#
# VERIFY, DO NOT REDO: a failure here is reported against the upstream delivery that owns the region.
# This delivery does not fix another's work; it proves it landed.
#
# Usage: bash tests/canonical/test-reviewer-conformance.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"
cd "$REPO" || exit 2

A="canonical/agents/aid-reviewer/AGENT.md"
RM="canonical/agents/aid-reviewer/README.md"

echo "== test-reviewer-conformance.sh =="
[[ -f "$A" ]]  || { echo "FATAL: $A missing" >&2; exit 2; }
[[ -f "$RM" ]] || { echo "FATAL: $RM missing" >&2; exit 2; }

body="$(cat "$A")"
readme="$(cat "$RM")"

# ---------------------------------------------------------------------------
# THE NINE VERIFY-DO-NOT-REDO ASSERTIONS, each naming the delivery that owns it.
# ---------------------------------------------------------------------------

# 1. delivery-003 -- no local severity table. Severity is defined once, elsewhere.
sev_table=$(grep -cE '^\| *`?\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]`? *\|' "$A" 2>/dev/null || true)
assert_eq "$sev_table" "0" "RC01 no local severity definition table (owned by delivery-003)"
assert_output_contains "$body" "grading-rubric.md#severity-scale" \
  "RC02 severity points at the single canonical scale (delivery-003)"

# 2. delivery-003 -- the invented-criteria licence is gone.
for phrase in "established best practice" "general best practice" "industry standard"; do
  n=$(grep -ci "$phrase" "$A" 2>/dev/null || true)
  [[ "$n" == "0" ]] || fail "RC03 '$phrase' survives in the body (delivery-003 owns its removal)"
done
pass "RC03 no invented-criteria licence phrase survives (delivery-003)"

# 3. delivery-004 -- the source tags are retired and rule IDs replace them.
assert_output_contains "$body" "review-rubrics/INDEX.md" \
  "RC04 the body routes to the rule catalog (delivery-004)"
if grep -qE 'Tag every issue by source' "$A"; then
  fail "RC05 the five-source-tag mandate survives (delivery-004 owns its removal)"
else
  pass "RC05 the five-source-tag mandate is gone (delivery-004)"
fi
if grep -q '^## Standing KB-Convention Checks' "$A"; then
  fail "RC06 the Standing KB-Convention Checks section survives (delivery-004 relocated it)"
else
  pass "RC06 the Standing KB-Convention Checks section is gone (delivery-004)"
fi

# 4. delivery-004 -- the phantom citation is gone, tree-wide.
phantom=$(grep -rc 'content-isolation\.md' "$A" 2>/dev/null || true)
assert_eq "$phantom" "0" "RC07 no phantom content-isolation.md citation (delivery-004)"

# 5. delivery-005 -- eight columns, with Rule after Status.
assert_output_contains "$body" 'Rule | Doc | Line | Description | Evidence' \
  "RC08 the column list is the 8-column shape (delivery-005)"
if grep -q 'Status | Doc | Line | Description | Evidence' "$A"; then
  fail "RC09 a 7-column list survives (delivery-005 owns the migration)"
else
  pass "RC09 no 7-column list survives (delivery-005)"
fi

# 6. delivery-006 -- the heredoc write is gone; the helper is named.
if grep -q 'LEDGEREOF' "$A"; then
  fail "RC10 a heredoc ledger write survives (delivery-006 retired it)"
else
  pass "RC10 no heredoc ledger write survives (delivery-006)"
fi
assert_output_contains "$body" "review/writeback-ledger.sh" \
  "RC11 the body names the surgical row writer (delivery-006)"
assert_output_contains "$body" "three row kinds" \
  "RC12 the body explains the three row kinds (delivery-006)"

# 7. delivery-007 -- the gap outcome, and no OOS escape.
assert_output_contains "$body" "criteria-gap-protocol.md" \
  "RC13 the body routes to the gap protocol (delivery-007)"
assert_output_contains "$body" "[GAP:CRITERIA]" \
  "RC14 the body names the blocking discriminator (delivery-007)"
if grep -q 'only a Status=OOS row may carry' "$A"; then
  fail "RC15 the OOS rule-citation exemption survives (delivery-007 retired it)"
else
  pass "RC15 no OOS rule-citation exemption survives (delivery-007)"
fi

# 8. delivery-009 -- reconciliation is off the reviewer; the scratch is the only ledger it sees.
assert_output_contains "$body" "orchestrator reconciles" \
  "RC16 the body says the orchestrator reconciles (delivery-009)"
assert_output_contains "$body" "scratch" \
  "RC17 the body names the scratch ledger (delivery-009)"
# The examples must NOT spell the durable path, or they teach the forbidden behaviour.
dur=$(grep -c -- '--ledger .aid/.temp/review-pending/' "$A" 2>/dev/null || true)
assert_eq "$dur" "0" "RC18 no example passes the durable ledger path (delivery-009)"

# 9. delivery-010 -- the discipline include is present (the reviewer KEEPS the mandate).
assert_output_contains "$body" "{{include:agent-discipline-boilerplate}}" \
  "RC19 the reviewer still takes the discipline boilerplate (delivery-010)"
assert_output_contains "$body" "{{include:agent-boilerplate}}" \
  "RC20 the reviewer still takes the heartbeat boilerplate (delivery-010)"

# ---------------------------------------------------------------------------
# THIS delivery's own additions.
# ---------------------------------------------------------------------------
assert_output_contains "$body" "Depth and division of labour" \
  "RC21 the body carries the depth / division-of-labour section"
assert_output_contains "$body" "never substitutes for a graded pass" \
  "RC22 the body states a screening result never substitutes for a graded pass"
assert_output_contains "$body" "aid-screener" \
  "RC23 the body names the screener it divides labour with"

# The Tasks Status write-target defect: the section does not exist and its real name is read-only.
ts=$(grep -c 'Tasks Status' "$A" 2>/dev/null || true)
assert_eq "$ts" "0" "RC24 the body no longer names a nonexistent '## Tasks Status' write target"
ts_rm=$(grep -c 'Tasks Status' "$RM" 2>/dev/null || true)
assert_eq "$ts_rm" "0" "RC25 the README no longer names it either"

# ...and the claim is true: no state template defines that section.
tmpl=$(grep -rc '^## Tasks Status' canonical/aid/templates/*state*.md 2>/dev/null | grep -v ':0' | wc -l)
assert_eq "$tmpl" "0" "RC26 no state template defines a '## Tasks Status' section (the defect was real)"

# Severity must be described as looked up, not assigned.
if grep -q '^- Assign severity by' "$A"; then
  fail "RC27 the body still says the reviewer ASSIGNS severity"
else
  pass "RC27 the body describes severity as looked up, not assigned"
fi

# ---------------------------------------------------------------------------
# README: the tier claim must match the canonical frontmatter.
# ---------------------------------------------------------------------------
fm_tier="$(grep -m1 '^tier:' "$A" | awk '{print $2}')"
assert_eq "$fm_tier" "medium" "RC28 the canonical frontmatter tier is medium"
if grep -qE '^\*\*Large tier\*\* — required' "$RM"; then
  fail "RC29 the README still states Large as the DEFAULT tier, contradicting the frontmatter"
else
  pass "RC29 the README no longer states Large as the default tier"
fi
assert_output_contains "$readme" "Medium by default" "RC30 the README states the medium default"
assert_output_contains "$readme" "escalat" "RC31 the README explains the per-dispatch escalation"

# ---------------------------------------------------------------------------
# The end state must survive rendering, in every tree.
# ---------------------------------------------------------------------------
bad=0; trees=0
for p in antigravity claude-code codex copilot-cli cursor; do
  f="$(find "profiles/$p" -path '*agents/aid-reviewer*' -type f 2>/dev/null | head -1)"
  [[ -n "$f" ]] || continue
  trees=$((trees + 1))
  grep -q 'Depth and division of labour' "$f" || { bad=$((bad+1)); echo "    ($p: no depth section)"; }
  grep -q 'Tasks Status' "$f" && { bad=$((bad+1)); echo "    ($p: stale Tasks Status survives)"; }
  grep -q 'Standing KB-Convention Checks' "$f" && { bad=$((bad+1)); echo "    ($p: relocated section survives)"; }
done
assert_eq "$trees" "5" "RC32 the reviewer renders to all five trees"
assert_eq "$bad" "0" "RC33 the end state survives rendering in every tree"

echo
test_summary
exit $?
