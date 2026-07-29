#!/usr/bin/env bash
# test-agent-boilerplate-split.sh -- the boilerplate split, and the screener that motivated it.
#
# THE SPLIT'S SUCCESS CRITERION IS AN EMPTY DIFF: nine agents inherit this boilerplate, so if the
# split changed any RENDERED agent body it changed nine agents at once. That is asserted by
# reconstructing the original from the two halves and requiring byte equality -- the same round trip
# the renderer performs, so it tests the actual mechanism rather than a description of it.
#
# THE SCREENER'S REASON TO EXIST IS A DIFFERENCE THAT MUST HOLD: it must NOT carry the exhaustiveness
# mandate while aid-reviewer must. If both carried it the screener would be a slow reviewer; if
# neither did, the reviewer would have lost its discipline. So the difference is asserted in every
# rendered tree, in both directions.
#
# Usage: bash tests/canonical/test-agent-boilerplate-split.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"
cd "$REPO" || exit 2

TPL="canonical/aid/templates"
A="${TPL}/agent-boilerplate.md"
B="${TPL}/agent-discipline-boilerplate.md"

echo "== test-agent-boilerplate-split.sh =="

# ---------------------------------------------------------------------------
# BS01-BS04 -- the split exists and each half holds exactly its own concern.
# ---------------------------------------------------------------------------
assert_eq "$([[ -f "$A" ]] && echo yes)" "yes" "BS01 agent-boilerplate.md exists"
assert_eq "$([[ -f "$B" ]] && echo yes)" "yes" "BS02 agent-discipline-boilerplate.md exists"

a_txt="$(cat "$A")"; b_txt="$(cat "$B")"
assert_output_contains "$a_txt" "## Heartbeat protocol" "BS03 the heartbeat half carries the heartbeat"
assert_output_contains "$b_txt" "## Self-review discipline" "BS04 the discipline half carries the discipline"

# Neither may carry the other's section, or the split achieved nothing.
h_in_b=$(grep -c '^## Heartbeat protocol' "$B" 2>/dev/null || true)
d_in_a=$(grep -c '^## Self-review discipline' "$A" 2>/dev/null || true)
assert_eq "$h_in_b" "0" "BS05 the discipline half does NOT re-carry the heartbeat"
assert_eq "$d_in_a" "0" "BS06 the heartbeat half does NOT re-carry the discipline"

# ---------------------------------------------------------------------------
# BS07 -- THE ROUND TRIP. A + newline + B must equal what the single file held.
#
# This is the mechanism the renderer uses: {{include:}} substitutes a whole file
# verbatim and the token line contributes its own newline. So the blank line that
# separated the two sections must live in NEITHER file -- if it were kept, every
# rendered agent body would gain a stray blank line.
# ---------------------------------------------------------------------------
recon="$(mktemp)"
{ cat "$A"; printf '\n'; cat "$B"; } > "$recon"

# The pre-split original is recoverable from git, whichever ref still holds it.
found_ref=""
for ref in aid/work-003-delivery-009 aid/work-003-delivery-008 master; do
  if git show "${ref}:${A}" >/dev/null 2>&1; then
    if git show "${ref}:${A}" | grep -q '^## Self-review discipline'; then
      found_ref="$ref"; break
    fi
  fi
done

if [[ -n "$found_ref" ]]; then
  orig="$(mktemp)"
  git show "${found_ref}:${A}" > "$orig"
  # Compare with line endings normalised: git emits the stored blob while the working tree carries the
  # repo's filters, and that difference is not a content change (an earlier delivery raised a false
  # NFR-1 alarm on exactly this).
  if diff -q <(tr -d '\r' < "$orig") <(tr -d '\r' < "$recon") >/dev/null 2>&1; then
    pass "BS07 A + newline + B reproduces the pre-split original byte-for-byte (vs $found_ref)"
  else
    fail "BS07 the round trip does NOT reproduce the original -- rendered agent bodies would change"
    diff <(tr -d '\r' < "$orig") <(tr -d '\r' < "$recon") | head -10 | sed 's/^/    /'
  fi
  rm -f "$orig"
else
  echo "  SKIP BS07 (no ref still holds the pre-split boilerplate)"
fi
rm -f "$recon"

# ---------------------------------------------------------------------------
# BS08-BS09 -- every agent that took the old include now takes both, in order.
# Order matters: the rendered body must read heartbeat-then-discipline.
# ---------------------------------------------------------------------------
missing=0; misordered=0; n_agents=0
for f in canonical/agents/*/AGENT.md; do
  grep -q '{{include:agent-boilerplate}}' "$f" || continue
  n_agents=$((n_agents + 1))
  if ! grep -q '{{include:agent-discipline-boilerplate}}' "$f"; then
    # The screener deliberately omits it -- that is its whole point, asserted below.
    [[ "$f" == *aid-screener* ]] && continue
    missing=$((missing + 1)); echo "    (no discipline include: $f)"
    continue
  fi
  la=$(grep -n '{{include:agent-boilerplate}}' "$f" | head -1 | cut -d: -f1)
  lb=$(grep -n '{{include:agent-discipline-boilerplate}}' "$f" | head -1 | cut -d: -f1)
  [[ "$la" -lt "$lb" ]] || { misordered=$((misordered+1)); echo "    (discipline before heartbeat: $f)"; }
done
assert_eq "$missing"    "0" "BS08 every agent but the screener carries both includes"
assert_eq "$misordered" "0" "BS09 the heartbeat include precedes the discipline include"

if [[ "$n_agents" -ge 9 ]]; then
  pass "BS10 the include sweep inspected $n_agents agents (not vacuous)"
else
  fail "BS10 the include sweep inspected only $n_agents agents"
fi

# ---------------------------------------------------------------------------
# BS11-BS15 -- aid-screener: tier, tools, and the ABSENCE that defines it.
# ---------------------------------------------------------------------------
S=canonical/agents/aid-screener/AGENT.md
assert_eq "$([[ -f "$S" ]] && echo yes)" "yes" "BS11 aid-screener exists"
s_txt="$(cat "$S" 2>/dev/null || true)"
assert_output_contains "$s_txt" "tier: small" "BS12 the screener is small tier"

tools_line="$(grep -m1 '^tools:' "$S" 2>/dev/null || true)"
assert_output_contains "$tools_line" "Read" "BS13 the screener has Read"
assert_output_contains "$tools_line" "Glob" "BS13b the screener has Glob"
assert_output_contains "$tools_line" "Grep" "BS13c the screener has Grep"
if [[ "$tools_line" == *Bash* ]]; then
  fail "BS14 the screener must NOT have Bash -- with it, it could write graded ledger rows"
else
  pass "BS14 the screener has no Bash (so it cannot write a graded ledger row)"
fi

# The defining absence: no exhaustiveness mandate.
if grep -q '{{include:agent-discipline-boilerplate}}' "$S"; then
  fail "BS15 the screener must NOT include the discipline boilerplate -- that is its reason to exist"
else
  pass "BS15 the screener omits the discipline boilerplate"
fi
# ...but it must still get the heartbeat, or it cannot be stopped or monitored.
assert_output_contains "$s_txt" "{{include:agent-boilerplate}}" "BS16 the screener still gets the heartbeat protocol"

# It must say plainly that a clean screen is not a pass -- the failure mode of a cheap pass is being
# mistaken for a thorough one.
assert_output_contains "$s_txt" "deliberately NOT exhaustive" "BS17 the screener states it is deliberately not exhaustive"
assert_output_contains "$s_txt" "NOT a pass" "BS18 the screener states a clean screen is not a pass"

# ---------------------------------------------------------------------------
# BS19-BS22 -- the difference must hold IN EVERY RENDERED TREE, both directions.
# ---------------------------------------------------------------------------
bad_screener=0; bad_reviewer=0; bad_tools=0; trees=0; tools_checked=0
for p in antigravity claude-code codex copilot-cli cursor; do
  sf="$(find "profiles/$p" -path '*agents/aid-screener*' -type f 2>/dev/null | head -1)"
  rf="$(find "profiles/$p" -path '*agents/aid-reviewer*'  -type f 2>/dev/null | head -1)"
  [[ -n "$sf" && -n "$rf" ]] || { echo "    ($p: screener='$sf' reviewer='$rf')"; continue; }
  trees=$((trees + 1))

  # The screener must NOT carry the mandate...
  grep -q 'Find nothing more to find' "$sf" && { bad_screener=$((bad_screener+1)); echo "    ($p screener HAS the mandate)"; }
  # ...and the reviewer must.
  grep -q 'Find nothing more to find' "$rf" || { bad_reviewer=$((bad_reviewer+1)); echo "    ($p reviewer LOST the mandate)"; }
  # GRANTING Bash is the `tools:` frontmatter line, NOT any mention of the word. The screener's body
  # deliberately DISCUSSES Bash at length to explain why it has none ("Why you have no Bash"), so a
  # whole-body grep conflates the explanation with the grant and fails on a correct artifact -- which
  # is exactly what the first version of this assertion did.
  # The Codex tree renders TOML with no `tools` field at all, so there is nothing to check there.
  tl="$(grep -m1 '^tools:' "$sf" 2>/dev/null || true)"
  if [[ -n "$tl" ]]; then
    tools_checked=$((tools_checked + 1))
    [[ "$tl" == *Bash* ]] && { bad_tools=$((bad_tools+1)); echo "    ($p screener GRANTS Bash: $tl)"; }
  fi
done
assert_eq "$trees" "5" "BS19 both agents are present in all five rendered trees"
assert_eq "$bad_screener" "0" "BS20 no rendered screener carries the exhaustiveness mandate"
assert_eq "$bad_reviewer" "0" "BS21 every rendered reviewer still carries it"
assert_eq "$bad_tools" "0" "BS22 no rendered screener GRANTS Bash in its tools line"
if [[ "$tools_checked" -ge 4 ]]; then
  pass "BS22b the tools check inspected $tools_checked trees (Codex renders TOML with no tools field)"
else
  fail "BS22b the tools check inspected only $tools_checked trees -- it is not proving much"
fi

# ---------------------------------------------------------------------------
# BS23 -- the roster count is now ten, derived not asserted.
# ---------------------------------------------------------------------------
n=$(find canonical/agents -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
assert_eq "$n" "10" "BS23 the canonical roster holds ten agents"

# ...and the tiering table lists the new one, or dispatch has no default for it.
assert_output_contains "$(cat "$TPL/agent-dispatch-tiering.md")" "aid-screener" \
  "BS24 the tiering table carries a row for aid-screener"

echo
test_summary
exit $?
