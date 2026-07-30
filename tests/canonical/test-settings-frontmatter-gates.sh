#!/usr/bin/env bash
# test-settings-frontmatter-gates.sh -- delivery-014.
#
# Two artifacts had no runtime gate: .aid/settings.yml (which sets every gate's quality bar and was
# validated by nothing) and KB frontmatter (whose linter existed and was invoked by no skill state).
#
# Every acceptance assertion is paired with a NEGATIVE CONTROL. The specific risk here is a validator
# that accepts everything: `lint-settings.sh` would then report the settings valid forever, which is
# indistinguishable from having no gate while looking like having one.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LS="$ROOT/canonical/aid/scripts/config/lint-settings.sh"
FM="$ROOT/canonical/aid/scripts/kb/lint-frontmatter.sh"
TMPL="$ROOT/canonical/aid/templates/settings.yml"
RUBRIC="$ROOT/canonical/aid/templates/grading-rubric.md"
LIVE="$ROOT/.aid/settings.yml"
DEEP="$ROOT/canonical/skills/aid-deep-review/SKILL.md"
CFG="$ROOT/canonical/skills/aid-config/SKILL.md"
GEN="$ROOT/canonical/skills/aid-discover/references/state-generate.md"

pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ok   %s -- %s\n' "$1" "$2"; }
no()  { fail=$((fail+1)); printf '  FAIL %s -- %s\n' "$1" "$2"; }
chk() { if [[ "$1" == "$2" ]]; then ok "$3" "$4"; else no "$3" "$4 (expected '$2', got '$1')"; fi; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mk() { cp "$LIVE" "$W/s.yml"; }   # start from the real file so fixtures stay realistic

echo "== the settings gate exists and follows the linter exit alphabet =="
[[ -f "$LS" ]] && ok SG01 "lint-settings.sh exists" || { no SG01 "missing"; echo FAIL; exit 1; }
bash "$LS" --bogus >/dev/null 2>&1;                   chk "$?" 2 SG02 "unknown flag is a usage error"
bash "$LS" --file "$W/nope.yml" >/dev/null 2>&1;      chk "$?" 2 SG03 "absent settings file is a usage error, not a pass"
bash "$LS" --file "$LIVE" --rubric "$W/nope.md" >/dev/null 2>&1
chk "$?" 2 SG04 "an unreadable rubric is exit 2 -- never a silent built-in fallback"

echo
echo "== the live settings file is valid =="
bash "$LS" --file "$LIVE" --quiet >/dev/null 2>&1;    chk "$?" 0 SG05 "the live .aid/settings.yml passes"

echo
echo "== the grade enum is DERIVED from the rubric, not restated (no sixth alphabet) =="

# The whole point: the validator must not carry its own copy of the grade list. If it did, its idea of a
# valid grade could drift from the grader's, and it would reject settings the grader would honour.
derived="$(bash "$LS" --file "$LIVE" 2>/dev/null | sed -n 's/^derived grade alphabet ([0-9]*): //p')"
rubric_line="$(awk '/^## Grade Ordering/{w=1;next} w&&/>/{print;exit}' "$RUBRIC" | tr -d ' ' | tr '>' ' ')"
if [[ -n "$derived" && "$(tr -s ' ' <<<"$derived" | xargs)" == "$(tr -s ' ' <<<"$rubric_line" | xargs)" ]]; then
    ok SG06 "derived alphabet equals the rubric's ordering line ($(wc -w <<<"$derived") grades)"
else
    no SG06 "derived alphabet '$derived' != rubric '$rubric_line'"
fi

# NEGATIVE CONTROL for derivation: change the rubric, and the validator's notion of valid must change
# with it. If it does not, the enum is hardcoded somewhere despite appearances.
# Keep at least 4 grades in the fixture: fewer trips the lint's own "implausible derivation" guard
# (SG09), so a 3-grade fixture would exit 2 and prove nothing about derivation.
awk '{ if ($0 ~ /^A\+ > A > A-/) print "A+ > A > A- > ZZZ"; else print }' "$RUBRIC" > "$W/r2.md"
mk; sed -i 's/^minimum_grade:.*/minimum_grade: ZZZ/' "$W/s.yml"
bash "$LS" --file "$W/s.yml" --rubric "$W/r2.md" --quiet >/dev/null 2>&1
chk "$?" 0 SG07 "a grade valid ONLY in a modified rubric is accepted -- proving derivation is live"
bash "$LS" --file "$W/s.yml" --rubric "$RUBRIC" --quiet >/dev/null 2>&1
chk "$?" 1 SG08 "the same grade is REJECTED against the real rubric"

# Guard against a parse that silently collapses to one token: then only that token would be valid.
printf '## Grade Ordering\n\nA+\n' > "$W/r3.md"
bash "$LS" --file "$LIVE" --rubric "$W/r3.md" >/dev/null 2>&1
chk "$?" 2 SG09 "an implausible 1-grade derivation is refused rather than enforced"

echo
echo "== NEGATIVE CONTROLS: each way settings can be wrong must be rejected =="

mk; sed -i 's/^minimum_grade:.*/minimum_grade: A1/'        "$W/s.yml"; bash "$LS" --file "$W/s.yml" --quiet >/dev/null 2>&1
chk "$?" 1 SG10 "REJECTS an out-of-enum minimum grade (A1)"
mk; sed -i '/^minimum_grade:/d'                            "$W/s.yml"; bash "$LS" --file "$W/s.yml" --quiet >/dev/null 2>&1
chk "$?" 1 SG11 "REJECTS an absent minimum_grade"
mk; sed -i 's/^type:.*/type: bluefield/'                   "$W/s.yml"; bash "$LS" --file "$W/s.yml" --quiet >/dev/null 2>&1
chk "$?" 1 SG12 "REJECTS an out-of-enum type"
mk; sed -i 's/^source_control:.*/source_control: perforce/' "$W/s.yml"; bash "$LS" --file "$W/s.yml" --quiet >/dev/null 2>&1
chk "$?" 1 SG13 "REJECTS an out-of-enum source_control"
mk; sed -i 's/^heartbeat_interval:.*/heartbeat_interval: 0/' "$W/s.yml"; bash "$LS" --file "$W/s.yml" --quiet >/dev/null 2>&1
chk "$?" 1 SG14 "REJECTS a non-positive heartbeat_interval"
mk; sed -i 's/^minimum_grade:/minimum_grades:/'            "$W/s.yml"; bash "$LS" --file "$W/s.yml" --quiet >/dev/null 2>&1
chk "$?" 1 SG15 "REJECTS a typo'd key -- otherwise read-setting.sh silently uses its default"
# Two distinct corruptions, because they fail differently. A row with the wrong field count is visibly
# malformed; a row that lost its leading "- " stops being a list item at all and would be dropped from
# the doc set with nothing complaining -- the quieter and worse failure.
mk; sed -i 's|^\( *\)- project-structure.md.*|\1- project-structure.md\|required|' "$W/s.yml"
bash "$LS" --file "$W/s.yml" --quiet >/dev/null 2>&1
chk "$?" 1 SG16 "REJECTS a doc_set row with the wrong field count"
mk; sed -i 's|^\( *\)- project-structure.md|\1project-structure.md|' "$W/s.yml"
bash "$LS" --file "$W/s.yml" --quiet >/dev/null 2>&1
chk "$?" 1 SG16b "REJECTS a doc_set line that is no longer a list item (silently-dropped row)"

# The type/source_control enums are read from the TEMPLATE's comments, so removing the comment must be
# reported rather than silently skipping the check.
cp "$TMPL" "$W/t.yml"; sed -i 's/^type: brownfield.*/type: brownfield/' "$W/t.yml"
bash "$LS" --file "$LIVE" --template "$W/t.yml" --quiet >/dev/null 2>&1
chk "$?" 1 SG17 "an undeclared enum in the template is a violation, not a skipped check"

echo
echo "== the settings gate is wired where the bar is consumed and written =="
grep -q 'lint-settings.sh' "$DEEP"; chk "$?" 0 SG18 "aid-deep-review INTAKE validates settings"
grep -q 'lint-settings.sh' "$CFG";  chk "$?" 0 SG19 "aid-config verifies the file it just wrote"
# The loosening criterion is met by printing the bar, not by a settings-history mechanism.
grep -qi 'print the resolved bar\|bar = ' "$DEEP"
chk "$?" 0 SG20 "the gate prints the bar it is enforcing (auditability without a history file)"
# Validation must precede use, or a bad value is consumed before it is checked.
lsl=$(grep -n 'lint-settings.sh' "$DEEP" | head -1 | cut -d: -f1)
rsl=$(grep -n 'read-setting.sh --skill <caller> --key minimum_grade' "$DEEP" | head -1 | cut -d: -f1)
if [[ -n "$lsl" && -n "$rsl" && "$lsl" -lt "$rsl" ]]; then ok SG21 "validation precedes the read (line $lsl < $rsl)"
else no SG21 "validation does not precede the read (lint=$lsl read=$rsl)"; fi

echo
echo "== the frontmatter lint is a runtime gate, and --fail-on-skip is satisfiable =="
grep -q -- '--fail-on-skip' "$FM";  chk "$?" 0 FG01 "lint-frontmatter.sh accepts --fail-on-skip"
grep -qE 'bash [^ ]*lint-frontmatter\.sh' "$GEN"
chk "$?" 0 FG02 "a skill state now INVOKES the lint (not merely mentions it)"
grep -q -- 'lint-frontmatter.sh --root .aid/knowledge --fail-on-skip' "$GEN"
chk "$?" 0 FG03 "the skill state passes --fail-on-skip"

# The flag must distinguish permanent from pre-migration skips. Conflating them makes it permanently
# red on any KB with meta docs -- and a gate that can never pass gets switched off.
grep -q 'skipped_premigration' "$FM"; chk "$?" 0 FG04 "pre-migration skips are counted separately"
out="$(bash "$FM" --root "$ROOT/.aid/knowledge" --fail-on-skip 2>&1)"; rc=$?
chk "$rc" 0 FG05 "--fail-on-skip PASSES on this KB (all skips are out of scope, so the gate is usable)"
grep -q 'out of scope' <<<"$out"; chk "$?" 0 FG06 "output distinguishes out-of-scope from pre-migration"

# NEGATIVE CONTROL: a genuinely pre-migration doc must fail the flag.
mkdir -p "$W/kb"
printf -- '---\nkb-category: primary\nsource: hand-authored\n---\n\n# Old Doc\n' > "$W/kb/old.md"
bash "$FM" --root "$W/kb" --fail-on-skip >/dev/null 2>&1
chk "$?" 1 FG07 "REJECTS a pre-migration doc under --fail-on-skip"
bash "$FM" --root "$W/kb" >/dev/null 2>&1
chk "$?" 0 FG08 "the same doc is tolerated WITHOUT the flag (day-one CI compatibility preserved)"

# And an out-of-scope doc must NOT fail it.
printf -- '---\nkb-category: meta\nsource: hand-authored\n---\n\n# Meta\n' > "$W/kb2meta.md"
mkdir -p "$W/kb2"; mv "$W/kb2meta.md" "$W/kb2/INDEX.md"
bash "$FM" --root "$W/kb2" --fail-on-skip >/dev/null 2>&1
chk "$?" 0 FG09 "a meta doc does NOT fail --fail-on-skip"

echo
echo "== no canonical body hardcodes a profile install path =="

# state-generate.md itself states the convention: scripts are written in canonical/aid/scripts form and
# the renderer rewrites them per profile. Two invocations broke that rule in the same skill.
hits="$(grep -rn 'bash \.claude/aid/scripts' "$ROOT/canonical/" 2>/dev/null | wc -l)"
chk "${hits:-1}" 0 HP01 "no 'bash .claude/aid/scripts' invocation remains in canonical/"
grep -q 'renderer rewrites them' "$GEN"; chk "$?" 0 HP02 "the convention is still stated in the skill"
# The two known offenders, by content anchor rather than line number.
grep -q 'bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge' "$GEN"
chk "$?" 0 HP03 "state-generate.md's citation-lint call uses canonical form"
grep -q 'bash canonical/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge' \
    "$ROOT/canonical/skills/aid-discover/references/agent-prompts.md"
chk "$?" 0 HP04 "agent-prompts.md's citation-lint call uses canonical form"

echo
printf 'test-settings-frontmatter-gates.sh: %d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
