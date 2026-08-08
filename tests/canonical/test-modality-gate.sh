#!/usr/bin/env bash
# test-modality-gate.sh -- delivery-013, modality enforcement.
#
# Guards the input to step 1 of the canonical severity scale. If a requirement or acceptance criterion
# carries no modality, step 1 has nothing to read and severity falls back to judgment -- so this suite
# has to prove the gate REJECTS, not merely that it accepts a clean tree.
#
# Every acceptance assertion here is paired with a NEGATIVE CONTROL that breaks the input and requires
# the gate to fail. Eight of the twelve deliveries before this one shipped a check that passed on
# deliberately broken input; a suite that only ever sees good input cannot tell "correct" from "inert".
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LINT="$ROOT/canonical/aid/scripts/kb/lint-modality.sh"
TMPL="$ROOT/canonical/aid/templates/requirements/requirements-template.md"

pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ok   %s -- %s\n' "$1" "$2"; }
no()  { fail=$((fail+1)); printf '  FAIL %s -- %s\n' "$1" "$2"; }
chk() { if [[ "$1" == "$2" ]]; then ok "$3" "$4"; else no "$3" "$4 (expected '$2', got '$1')"; fi; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

echo "== the gate exists and follows the linter exit alphabet =="

[[ -f "$LINT" ]] && ok MG01 "lint-modality.sh exists" || { no MG01 "lint-modality.sh missing"; echo; echo "FAIL"; exit 1; }

bash "$LINT" >/dev/null 2>&1; chk "$?" 2 MG02 "no arguments is a usage error (exit 2)"
bash "$LINT" --root /nonexistent-dir-xyz >/dev/null 2>&1; chk "$?" 2 MG03 "bad --root is a usage error (exit 2)"
bash "$LINT" --bogus-flag >/dev/null 2>&1; chk "$?" 2 MG04 "unknown flag is a usage error (exit 2)"

# A typo'd --file must NOT report a clean pass. A gate that inspects nothing and exits 0 produces a
# passing record for work it never checked, which is worse than having no gate at all.
bash "$LINT" --file "$ROOT/no-such-file-xyz.md" >/dev/null 2>&1
chk "$?" 2 MG04b "a named file that does not exist is a usage error, NOT a clean pass"

echo
echo "== accepts a conforming file =="

cat > "$WORK/REQUIREMENTS.md" <<'EOF'
# Requirements
| ID | Modality | Requirement |
|----|----------|-------------|
| FR-1 | MUST | The system does X. |
| FR-A2 | SHOULD | The system prefers Y. |
| NFR-1 | COULD | The system might do Z. |

| # | Modality | Criterion |
|---|----------|-----------|
| AC-1 | MUST | Given A, when B, then C. |
EOF
bash "$LINT" --file "$WORK/REQUIREMENTS.md" >/dev/null 2>&1
chk "$?" 0 MG05 "a fully-tagged file is clean (exit 0)"

echo
echo "== NEGATIVE CONTROLS: the gate must reject each way a modality can be absent =="

# (a) no modality column at all -- the shape this work's own ACs had before the back-fill
cat > "$WORK/no-column.md" <<'EOF'
| # | Criterion |
|---|-----------|
| AC-1 | Given A, when B, then C. |
EOF
bash "$LINT" --file "$WORK/no-column.md" >/dev/null 2>&1
chk "$?" 1 MG06 "REJECTS a criterion with no modality column"

# (b) the column exists but the cell is empty
printf '| ID | Modality | Requirement |\n|----|----|----|\n| FR-1 |  | Does X. |\n' > "$WORK/empty.md"
bash "$LINT" --file "$WORK/empty.md" >/dev/null 2>&1
chk "$?" 1 MG07 "REJECTS an empty modality cell"

# (c) a tag outside the closed set
printf '| ID | Modality | Requirement |\n|----|----|----|\n| FR-1 | SHALL | Does X. |\n' > "$WORK/wrong.md"
bash "$LINT" --file "$WORK/wrong.md" >/dev/null 2>&1
chk "$?" 1 MG08 "REJECTS a non-conforming tag (SHALL)"

# (d) right word, wrong spelling -- caught, and reported as a spelling problem not a missing column,
#     because the two have different fixes
printf '| ID | Modality | Requirement |\n|----|----|----|\n| FR-1 | must | Does X. |\n' > "$WORK/case.md"
bash "$LINT" --file "$WORK/case.md" >/dev/null 2>&1
chk "$?" 1 MG09 "REJECTS lowercase 'must'"
# Capture before matching: piping the lint into grep would report the LINT's exit status under
# `pipefail`, which is 1 whenever it finds a violation -- so the match result would be invisible.
out_case="$(bash "$LINT" --file "$WORK/case.md" 2>/dev/null)"
grep -q 'canonical spelling' <<<"$out_case"
chk "$?" 0 MG10 "reports a spelling problem distinctly from a missing column"
out_nocol="$(bash "$LINT" --file "$WORK/no-column.md" 2>/dev/null)"
grep -q 'no modality column' <<<"$out_nocol"
chk "$?" 0 MG11 "reports a missing column distinctly from a spelling problem"

echo
echo "== PRECISION: it must not fire on rows that only look like requirements =="

# A results table can hold a row whose first cell BEGINS with an ID. A prefix match reported five such
# rows in feature-008's SPEC as untagged requirements; anchoring the ID at both ends is what fixes it.
cat > "$WORK/results.md" <<'EOF'
| Check | Findings |
|-------|----------|
| FR-G2 resolution -- [UNRESOLVED] | 4 |
| FR-G3 quote presence, raw substring | 2 |
EOF
bash "$LINT" --file "$WORK/results.md" >/dev/null 2>&1
chk "$?" 0 MG12 "does NOT fire on a results row whose cell merely starts with an ID"

# A cut requirement keeps its historical shape on purpose.
printf '| ID | Modality | Requirement |\n|----|----|----|\n| ~~FR-A7~~ | ~~CUT~~ | ~~Does X.~~ |\n' > "$WORK/cut.md"
bash "$LINT" --file "$WORK/cut.md" >/dev/null 2>&1
chk "$?" 0 MG13 "does NOT fire on a struck-through (cut) requirement"

# THE COUNT ITSELF IS AN ASSERTION, and it must be able to be wrong.
#
# MG14 used to count $WORK/REQUIREMENTS.md, which holds only clean rows plus headers and separators --
# and every mechanism that could have miscounted it was subsumed by the ID anchor, so the assertion
# passed under every mutation. It could not fail, which the suite's own header promises no assertion
# does. The fixture below adds the two shapes that DO discriminate: a results row whose first cell
# merely begins with an ID (only the both-ends anchor excludes it) and a cut row (only the cut-skip
# excludes it). 4 is now reachable only with both intact.
cat > "$WORK/counting.md" <<'EOF'
| ID | Modality | Requirement |
|----|----------|-------------|
| FR-1 | MUST | The system does X. |
| FR-A2 | SHOULD | The system prefers Y. |
| NFR-1 | COULD | The system might do Z. |
| ~~FR-A7~~ | ~~CUT~~ | ~~Withdrawn.~~ |

| # | Modality | Criterion |
|---|----------|-----------|
| AC-1 | MUST | Given A, when B, then C. |
| FR-G2 resolution -- [UNRESOLVED] | 4 | not a requirement row |
EOF
n=$(bash "$LINT" --file "$WORK/counting.md" 2>/dev/null | grep -oE '[0-9]+ requirement' | grep -oE '[0-9]+')
chk "${n:-0}" 4 MG14 "counts exactly the 4 real rows -- separators, headers, the cut row and the results row all excluded"

echo
echo "== VACUITY CONTROL: the count must be real, over a tree this suite builds =="

# THE SWEEP RUNS OVER A FIXTURE TREE, NOT `.aid/works`.
#
# This suite used to sweep the live `.aid/works` and assert against
# `work-003-review-subsystem-redesign/REQUIREMENTS.md` by name. That made a permanent CI gate depend on
# one transient work folder outliving the work it belongs to -- the day work-003 is pruned, four
# assertions here break for a reason that has nothing to do with the gate they guard. CLAUDE.md states
# the rule directly: no permanent artifact may depend on a specific work folder; tests build their own
# fixtures. So this builds one.
#
# It is also a STRONGER test. The live tree happened to contain modality variation and happened to hold
# more than 50 rows; neither was guaranteed, and neither was under this suite's control. The fixture
# below pins both on purpose, and adds the shapes a real tree only sometimes has: separator rows, a
# header, a cut requirement, a results row whose first cell merely begins with an ID, and a split ID.
SWEEP="$WORK/tree"
mkdir -p "$SWEEP/work-fixture-a" "$SWEEP/work-fixture-b/features/feature-001"
{
  printf '# Fixture requirements\n\n## 5. Functional Requirements\n\n'
  printf '| ID | Modality | Requirement |\n|----|----------|-------------|\n'
  for i in $(seq 1 40); do printf '| FR-A%d | MUST | Requirement %d. |\n' "$i" "$i"; done
  printf '| FR-B5a | SHOULD | Split half a. |\n| FR-B5b | COULD | Split half b. |\n'
  printf '| ~~FR-A99~~ | ~~CUT~~ | ~~Withdrawn.~~ |\n'
  printf '\n## 9. Acceptance Criteria\n\n'
  printf '| ID | Modality | Criterion |\n|----|----------|-----------|\n'
  for i in $(seq 1 12); do printf '| AC-%d | MUST | Criterion %d. |\n' "$i" "$i"; done
  printf '| AC-13 | SHOULD | A non-MUST criterion. |\n| AC-14 | COULD | Another non-MUST criterion. |\n'
  printf '\n## Results\n\n| Check | Findings |\n|-------|----------|\n| FR-G2 resolution -- [UNRESOLVED] | 4 |\n'
} > "$SWEEP/work-fixture-a/REQUIREMENTS.md"
{
  printf '# Fixture spec\n\n| ID | Modality | Criterion |\n|----|----------|-----------|\n'
  for i in $(seq 1 6); do printf '| AC-%d | MUST | Spec criterion %d. |\n' "$i" "$i"; done
} > "$SWEEP/work-fixture-b/features/feature-001/SPEC.md"

# EXPECTED TOTAL, derived by hand from the fixture above so the number is a claim, not a readout:
#   fixture-a  40 FR-A* + 2 split (FR-B5a/b) + 14 AC = 56   (cut row skipped; results row not an ID)
#   fixture-b  6 AC                                   =  6
#                                                       ---
#                                                        62
SWEEP_EXPECT=62

# Run the sweep ONCE and reuse its output and exit status: per-assertion runs cost ~100s against the
# live tree, uncomfortably close to run-all.sh's per-suite budget.
sweep_out="$(bash "$LINT" --root "$SWEEP" 2>/dev/null)"; sweep_rc=$?

# An inert matcher would report 0 rows. Assert the EXACT count rather than a floor: the fixture is
# fully known, so anything other than 62 means the matcher's scope changed, and a `>=` bound would
# hide a matcher that started over-counting.
tot=$(grep -oE '[0-9]+ requirement' <<<"$sweep_out" | grep -oE '[0-9]+')
chk "${tot:-0}" "$SWEEP_EXPECT" MG15 "tree-wide sweep inspects exactly ${SWEEP_EXPECT} fixture rows (cut skipped, results row ignored, split IDs counted)"

echo
echo "== the template carries the field (gate criterion 2) =="

grep -q '^| ID | Modality | Requirement |' "$TMPL"
chk "$?" 0 MG16 "template's Functional Requirements table has a Modality column"
grep -q '^| ID | Modality | Criterion |' "$TMPL"
chk "$?" 0 MG17 "template's Acceptance Criteria table has a Modality column"
grep -q 'lint-modality.sh' "$TMPL"
chk "$?" 0 MG18 "template names the gate that enforces it"
grep -qi 'first thing the severity scale reads\|first step' "$TMPL"
chk "$?" 0 MG19 "template says WHY the field exists, not just that it is required"

echo
echo "== a fully-tagged tree passes, and the sweep can still fail =="

chk "$sweep_rc" 0 MG20 "a fully-tagged fixture tree sweeps clean (exit 0)"

# NEGATIVE CONTROL for MG20. Without it MG20 asserts only that the gate can say yes -- and this suite's
# own header promises every acceptance is paired with a control that breaks the input. Untag one row of
# the fixture and require the sweep to fail.
sed -i '0,/^| FR-A7 | MUST |/s//| FR-A7 |  |/' "$SWEEP/work-fixture-a/REQUIREMENTS.md"
bash "$LINT" --root "$SWEEP" >/dev/null 2>&1
chk "$?" 1 MG20b "one untagged row anywhere in the tree fails the sweep (control)"
sed -i '0,/^| FR-A7 |  |/s//| FR-A7 | MUST |/' "$SWEEP/work-fixture-a/REQUIREMENTS.md"

# A blanket MUST would satisfy the lint while destroying the distinction the field exists to record, so
# the gate must ACCEPT the non-MUST spellings rather than merely tolerate MUST everywhere. Asserted
# against the fixture's own SHOULD/COULD rows: if the lint only ever accepted MUST, these would fail.
printf '| ID | Modality | Requirement |\n|----|----|----|\n| FR-S1 | SHOULD | s |\n| FR-C1 | COULD | c |\n' > "$WORK/variation.md"
bash "$LINT" --file "$WORK/variation.md" >/dev/null 2>&1
chk "$?" 0 MG21 "SHOULD and COULD are accepted, not just MUST (the distinction survives)"

# The AC rows specifically are in scope -- not only FR/NFR. The fixture holds exactly 20 (14 + 6).
ac=$(cat "$SWEEP/work-fixture-a/REQUIREMENTS.md" "$SWEEP/work-fixture-b/features/feature-001/SPEC.md" \
     | grep -cE '^\| AC-[0-9]+ \| (MUST|SHOULD|COULD) \|')
chk "${ac:-0}" 20 MG22 "acceptance criteria are in scope in both REQUIREMENTS.md and SPEC.md (20 rows)"

echo
printf 'test-modality-gate.sh: %d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
