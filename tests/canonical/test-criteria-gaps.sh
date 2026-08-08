#!/usr/bin/env bash
# test-criteria-gaps.sh -- the criteria-gap interrupt: the gate, the register, and the two rules that
# make "never re-ask" and loop detection work at the same time.
#
# The two properties worth the most here pull against each other, so they are tested together:
#   AC-5   a recorded "no" is never re-asked
#   AC-10  the same gap twice raises a loop flag, but a still-pending gap re-raised does not
# Getting one without the other is easy; a first implementation here reset a Declined gap to Pending
# on recurrence, which satisfied AC-10 and silently broke AC-5.
#
# Usage: bash tests/canonical/test-criteria-gaps.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"

CG="${REPO}/canonical/aid/scripts/review/check-gaps.sh"
GR="${REPO}/canonical/aid/scripts/review/gap-register.sh"
WB="${REPO}/canonical/aid/scripts/review/writeback-ledger.sh"

echo "== test-criteria-gaps.sh =="
for f in "$CG" "$GR" "$WB"; do
  [[ -f "$f" ]] || { echo "FATAL: missing $f" >&2; exit 2; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cg() { bash "$CG" "$@"; }
gr() { bash "$GR" "$@"; }
wb() { bash "$WB" "$@"; }

new_state() { printf '# STATE\n\n## Pipeline State\n\n- phase: Execute\n' > "$1"; }

gap_row() {   # $1=ledger $2=key $3=discriminator
  wb --ledger "$1" --append-gap --gap-key "$2" --doc b.sh \
     --description "$3 no standard declared for this class" \
     --resolution '/aid-update-kb coding-standards' >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# CG01-CG06 -- the gate blocks only [GAP:CRITERIA].
# ---------------------------------------------------------------------------
L="$TMP/a.md"
wb --ledger "$L" --append-finding --severity '[LOW]' --rule NAR-08 --doc a.md \
   --description 'a finding' --evidence 'e' >/dev/null
cg --ledger "$L" >/dev/null 2>&1
assert_eq "$?" "0" "CG01 a ledger with findings but no gap passes the gate"

gap_row "$L" 'code-sh/coding-standard' '[GAP:CRITERIA]'
cg --ledger "$L" >/dev/null 2>&1
assert_eq "$?" "1" "CG02 an open [GAP:CRITERIA] row blocks the gate"

L2="$TMP/b.md"; gap_row "$L2" 'x/y' '[GAP:CRITERIA:NB]'
cg --ledger "$L2" >/dev/null 2>&1
assert_eq "$?" "0" "CG03 [GAP:CRITERIA:NB] does not block (the anchored match distinguishes it)"

L3="$TMP/c.md"; gap_row "$L3" 'p/q' '[GAP:EVIDENCE]'
cg --ledger "$L3" >/dev/null 2>&1
assert_eq "$?" "0" "CG04 [GAP:EVIDENCE] does not block"

# A Resolved gap never blocks, whatever its discriminator.
L4="$TMP/d.md"; gap_row "$L4" 'r/s' '[GAP:CRITERIA]'
wb --ledger "$L4" --set-status --row-id G-001 --status Resolved >/dev/null 2>&1
cg --ledger "$L4" >/dev/null 2>&1
assert_eq "$?" "0" "CG05 a Resolved [GAP:CRITERIA] row no longer blocks"

# A missing ledger is not an error -- a clean first run must not be blocked by absence.
cg --ledger "$TMP/nonexistent.md" >/dev/null 2>&1
assert_eq "$?" "0" "CG06 an absent ledger passes rather than erroring"

# ---------------------------------------------------------------------------
# CG07-CG08 -- repeated --ledger, which is how the batch forms at all under
# parallel mandates (U-/G- rows are never merged into the panel ledger).
# ---------------------------------------------------------------------------
cg --ledger "$L2" --ledger "$L3" >/dev/null 2>&1
assert_eq "$?" "0" "CG07 several clean ledgers together still pass"
cg --ledger "$L2" --ledger "$L" --ledger "$L3" >/dev/null 2>&1
assert_eq "$?" "1" "CG08 one blocking gap among several ledgers blocks the batch"

cg >/dev/null 2>&1
assert_eq "$?" "2" "CG09 no --ledger is a usage error (exit 2, distinct from a finding)"

# ---------------------------------------------------------------------------
# CG10-CG13 -- the register: creation, promotion, idempotence.
# ---------------------------------------------------------------------------
S="$TMP/STATE.md"; new_state "$S"
gr --state "$S" --promote --gap-key code-sh/coding-standard --kind criteria \
   --scope b.sh --criterion 'no shell coding standard declared' \
   --resolution '/aid-update-kb coding-standards' >/dev/null 2>&1
assert_eq "$?" "0" "CG10 --promote succeeds on a STATE.md with no register section"
assert_output_contains "$(cat "$S")" "## Criteria Gaps" "CG11 the section is created on first use"
assert_output_contains "$(cat "$S")" "| code-sh/coding-standard | criteria | Pending | 0 | 0 |" \
  "CG12 the row is written with depth 0 and no recurrence"

before="$(grep -c '^| code-sh/coding-standard |' "$S")"
gr --state "$S" --promote --gap-key code-sh/coding-standard --kind criteria \
   --scope b.sh --criterion 'no shell coding standard declared' >/dev/null 2>&1
after="$(grep -c '^| code-sh/coding-standard |' "$S")"
assert_eq "$after" "$before" "CG13 --promote is idempotent on the key (no second row)"

# ---------------------------------------------------------------------------
# CG14-CG18 -- AC-5 and AC-10 TOGETHER. This is the pair a first implementation
# got half-right.
# ---------------------------------------------------------------------------
# Still Pending, re-raised: NO recurrence. A slow human is not a loop.
assert_output_contains "$(grep '^| code-sh/coding-standard |' "$S")" "| Pending | 0 | 0 |" \
  "CG14 re-raising a still-Pending gap does not increment Recurrences (AC-10)"

# Decline it -- a recorded "no".
gr --state "$S" --set-status --gap-key code-sh/coding-standard --status Declined \
   --resolution 'declined; instead: skip shell lint; canon' >/dev/null 2>&1
assert_output_contains "$(gr --state "$S" --resolved-keys)" "code-sh/coding-standard" \
  "CG15 a Declined key appears in --resolved-keys (AC-5 read side)"

# Now it comes BACK. Recurrence must increment AND the answer must stand.
gr --state "$S" --promote --gap-key code-sh/coding-standard --kind criteria \
   --scope b.sh --criterion 'no shell coding standard declared' >/dev/null 2>&1
row="$(grep '^| code-sh/coding-standard |' "$S")"
assert_output_contains "$row" "| Declined |" \
  "CG16 a recurrence does NOT reset the status to Pending -- the answer stands (AC-5)"
assert_output_contains "$row" "| 1 |" \
  "CG17 a recurrence after resolution increments Recurrences (AC-10)"
assert_output_contains "$(gr --state "$S" --resolved-keys)" "code-sh/coding-standard" \
  "CG18 the key is STILL subtracted after recurring, so it is never re-asked (AC-5)"

# ...and the resolution text survives the recurrence.
assert_output_contains "$row" "declined; instead: skip shell lint" \
  "CG19 the recorded resolution survives a recurrence"

# ---------------------------------------------------------------------------
# CG20-CG24 -- key hygiene. A bad key silently disables BOTH AC-5 and AC-10,
# so these are hard rejections rather than warnings.
# ---------------------------------------------------------------------------
gr --state "$S" --promote --gap-key 'Has-Caps' --kind criteria --scope s --criterion c >/dev/null 2>&1
assert_eq "$?" "4" "CG20 an uppercase key is rejected"
gr --state "$S" --promote --gap-key 'x/2026-07-29-thing' --kind criteria --scope s --criterion c >/dev/null 2>&1
assert_eq "$?" "4" "CG21 a key containing a date is rejected (it would never dedupe)"
gr --state "$S" --promote --gap-key 'ab' --kind criteria --scope s --criterion c >/dev/null 2>&1
assert_eq "$?" "4" "CG22 a too-short key is rejected"
gr --state "$S" --promote --gap-key 'ok/key' --kind bogus --scope s --criterion c >/dev/null 2>&1
assert_eq "$?" "4" "CG23 an invalid --kind is rejected"
gr --state "$S" --promote --gap-key 'ok/key' --kind criteria --scope s --criterion c --depth 3 >/dev/null 2>&1
assert_eq "$?" "4" "CG24 depth 3 is rejected -- the chain is capped at 2"

# ---------------------------------------------------------------------------
# CG25-CG27 -- depth, open keys, and the not-found path.
# ---------------------------------------------------------------------------
gr --state "$S" --promote --gap-key deep/gap --kind criteria --scope z.md \
   --criterion 'gap raised while resolving a gap' --depth 2 >/dev/null 2>&1
assert_eq "$(gr --state "$S" --depth-of deep/gap)" "2" "CG25 --depth-of reads the recorded depth"
assert_output_contains "$(gr --state "$S" --open-keys)" "deep/gap" "CG26 --open-keys lists a Pending gap"
gr --state "$S" --depth-of no/such >/dev/null 2>&1
assert_eq "$?" "7" "CG27 an unknown key exits 7"

# A depth-2 gap must still be RECORDED, not discarded -- the cap demotes only.
assert_output_contains "$(grep '^| deep/gap |' "$S")" "| Pending |" \
  "CG28 a depth-2 gap is still recorded Pending so a human sees it when the chain unwinds"

# ---------------------------------------------------------------------------
# CG29-CG31 -- the register survives, and the ungrounded finding is gone.
# ---------------------------------------------------------------------------
cd "$REPO" || exit 2
ign=0
# A SYNTHETIC work path, not a live one. `git check-ignore` evaluates the ignore RULES and needs no
# file on disk, so the general invariant -- "a work register is not ignored" -- is provable without
# binding a permanent test to one transient work folder (CLAUDE.md: work folders are transient; tests
# build their own fixtures). Naming work-003 here made this suite fail the day that folder is pruned.
for p in ".aid/works/work-999-fixture/STATE.md" ".aid/knowledge/STATE.md"; do
  git check-ignore -q "$p" 2>/dev/null && { ign=$((ign+1)); echo "    ($p IS gitignored -- the register would not survive)"; }
done
assert_eq "$ign" "0" "CG29 neither register file is gitignored (the record outlives the halt)"

# The interim OOS exemption must be gone from both the writer and the schema.
# NOTE: no `|| echo 0` here. `grep -c` already prints 0 when it finds nothing AND exits 1, so the
# fallback appended a second zero and the assertion compared against "0\n0".
oos=$(grep -c 'only a Status=OOS row may carry' canonical/aid/scripts/review/writeback-ledger.sh 2>/dev/null || true)
assert_eq "$oos" "0" "CG30 the writer no longer documents an OOS rule-citation exemption"
assert_output_contains "$(cat canonical/aid/templates/reviewer-ledger-schema.md)" "There is no exemption" \
  "CG31 the schema states that no exemption remains"

# ---------------------------------------------------------------------------
# CG32-CG34 -- the protocol document, and render reach.
# ---------------------------------------------------------------------------
PROTO=canonical/aid/templates/criteria-gap-protocol.md
assert_eq "$([[ -f "$PROTO" ]] && echo yes)" "yes" "CG32 the gap protocol document exists"
proto="$(cat "$PROTO" 2>/dev/null || true)"
assert_output_contains "$proto" "PAUSE-FOR-USER-ACTION" "CG33 the protocol cites the existing halt mechanism"
assert_output_contains "$proto" "Depth cap" "CG34 the protocol states the depth cap"

missing=0
for p in antigravity claude-code codex copilot-cli cursor; do
  n=$(find "profiles/$p" -path '*aid/scripts/review/check-gaps.sh' 2>/dev/null | wc -l)
  m=$(find "profiles/$p" -path '*aid/scripts/review/gap-register.sh' 2>/dev/null | wc -l)
  [[ "$n" -eq 1 && "$m" -eq 1 ]] || { missing=$((missing+1)); echo "    ($p: check-gaps=$n gap-register=$m)"; }
done
assert_eq "$missing" "0" "CG35 both gap scripts reached all five profiles"

echo
test_summary
exit $?
