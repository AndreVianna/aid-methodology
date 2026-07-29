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
REQ="$ROOT/.aid/works/work-003-review-subsystem-redesign/REQUIREMENTS.md"

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

# Separator rows must never be counted as requirements.
n=$(bash "$LINT" --file "$WORK/REQUIREMENTS.md" 2>/dev/null | grep -oE '[0-9]+ requirement' | grep -oE '[0-9]+')
chk "${n:-0}" 4 MG14 "counts exactly the 4 real rows, no separators or headers"

echo
echo "== VACUITY CONTROL: the count must be real =="

# The tree-wide sweep is the expensive check here, so run it ONCE and reuse both its output and its exit
# status below. Running it per assertion cost ~100s, uncomfortably close to run-all.sh's per-suite budget.
sweep_out="$(bash "$LINT" --root "$ROOT/.aid/works" 2>/dev/null)"; sweep_rc=$?

# If the checker inspected nothing it would report 0 and still exit 0. Assert the tree-wide count is
# non-trivial, so an accidentally-inert matcher cannot pass this suite.
tot=$(grep -oE '[0-9]+ requirement' <<<"$sweep_out" | grep -oE '[0-9]+')
if [[ "${tot:-0}" -ge 50 ]]; then ok MG15 "tree-wide sweep inspects ${tot} rows (>=50, so not inert)"
else no MG15 "tree-wide sweep inspected only ${tot:-0} rows -- matcher may be inert"; fi

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
echo "== the back-fill is complete and did not flatten the distinction (gate criterion 3) =="

chk "$sweep_rc" 0 MG20 "no untagged requirement or criterion remains under .aid/works"

# A blanket MUST would satisfy the lint while destroying the distinction the field exists to record.
# Requiring at least one non-MUST makes that failure mode visible.
nm=$(grep -cE '^\| AC-[0-9]+ \| (SHOULD|COULD) \|' "$REQ")
if [[ "${nm:-0}" -ge 1 ]]; then ok MG21 "back-fill preserved modality variation (${nm} non-MUST criteria)"
else no MG21 "every criterion is MUST -- back-fill flattened the distinction it exists to record"; fi

am=$(grep -cE '^\| AC-[0-9]+ \| (MUST|SHOULD|COULD) \|' "$REQ")
chk "${am:-0}" 14 MG22 "all 14 acceptance criteria carry a modality"

echo
printf 'test-modality-gate.sh: %d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
