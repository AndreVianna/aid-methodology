#!/usr/bin/env bash
# test-one-grading-backend.sh -- delivery-015, NFR-7: exactly one component produces a letter grade.
#
# AID had two grading models. They disagreed by construction -- an 11-letter ladder against grade.sh's
# 16, an average against a worst-dominates rule -- so the same artifact could not receive the same grade
# from both even in principle. This suite exists to stop a second one reappearing.
#
# The assertions that matter are the NEGATIVE ones: it is easy to write a test that passes because it
# looks at nothing. Each structural claim here is paired with a control proving it can fail.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GRADE="$ROOT/canonical/aid/scripts/grade.sh"
EMIT="$ROOT/canonical/aid/scripts/summarize/emit-summary-findings.sh"
MC="$ROOT/canonical/aid/scripts/summarize/manual-checklist.sh"
RUBRIC="$ROOT/canonical/aid/templates/knowledge-summary/grading-rubric.md"
SUMRULES="$ROOT/canonical/aid/templates/review-rubrics/summary.md"

pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ok   %s -- %s\n' "$1" "$2"; }
no()  { fail=$((fail+1)); printf '  FAIL %s -- %s\n' "$1" "$2"; }
chk() { if [[ "$1" == "$2" ]]; then ok "$3" "$4"; else no "$3" "$4 (expected '$2', got '$1')"; fi; }

echo "== NFR-7: exactly one component produces a letter grade =="

# A grade producer ASSIGNS a letter to a grade variable. Mentioning a grade is not producing one, so the
# pattern is deliberately narrow: an assignment of a letter-grade literal.
mapfile -t producers < <(
  grep -rlE '(^|[^A-Za-z_])GRADE="(A\+|A|A-|B\+|B|B-|C\+|C|C-|D\+|D|D-|E\+|E|E-|F)"' \
      "$ROOT/canonical/aid/scripts/" 2>/dev/null | sort -u
)
if [[ "${#producers[@]}" -eq 1 && "${producers[0]}" == "$GRADE" ]]; then
    ok NFR7a "exactly one grade producer: $(basename "${producers[0]}")"
else
    no NFR7a "expected only grade.sh, found: ${producers[*]:-none}"
fi

# Control: the detector must be capable of finding a second producer. If this control does not fire, the
# assertion above passes for the wrong reason and would keep passing if a second grader were added.
CTRL="$(mktemp -d)"; trap 'rm -rf "$CTRL"' EXIT
mkdir -p "$CTRL/scripts"
cp "$GRADE" "$CTRL/scripts/grade.sh"
printf '#!/usr/bin/env bash\nGRADE="B+"\necho "$GRADE"\n' > "$CTRL/scripts/rogue-grader.sh"
n_ctrl=$(grep -rlE '(^|[^A-Za-z_])GRADE="(A\+|A|A-|B\+|B|B-|C\+|C|C-|D\+|D|D-|E\+|E|E-|F)"' \
         "$CTRL/scripts/" 2>/dev/null | wc -l)
chk "$n_ctrl" 2 NFR7b "the detector DOES find a planted second grader (control)"

echo
echo "== the retired grader is gone, and its replacement does not grade =="
[[ ! -f "$ROOT/canonical/aid/scripts/summarize/grade-summary.sh" ]] \
    && ok RG01 "grade-summary.sh is removed" || no RG01 "grade-summary.sh still present"
[[ -f "$EMIT" ]] && ok RG02 "emit-summary-findings.sh exists" || no RG02 "emit-summary-findings.sh missing"

for pat in 'letter_grade' 'grade_order' 'grade_from_order' 'AUTO_POOL' 'MANUAL_POOL' 'OVERALL_GRADE'; do
    c=$(grep -c "$pat" "$EMIT" 2>/dev/null || true)
    chk "${c:-0}" 0 "RG03-${pat}" "no ${pat} in the replacement"
done

# It must SAY it does not grade, so a reader of its output is not left guessing where the letter comes from.
grep -qi 'does not grade\|no grade is computed' "$EMIT"
chk "$?" 0 RG04 "the emitter states that it does not grade"

echo
echo "== the checklist records answers rather than scoring them =="
sc=$(grep -cE '^\s*(K1|K2|V1)_score=|score_k1\(\)|score_k2\(\)|score_v1\(\)' "$MC" 2>/dev/null || true)
chk "${sc:-1}" 0 MC01 "no scoring functions remain in manual-checklist.sh"
grep -qi 'RECORDS the human-judgment answers' "$MC"
chk "$?" 0 MC02 "manual-checklist.sh declares itself a recorder"

# MC01 checks IDENTIFIERS, and identifiers are not what a user sees. Four score strings survived it in
# exactly this file -- two of them the only output a human running the script would read ("Scores K1
# (10) + K2 (15) + V1 visual gate (5) = 30 pts.", "HUMAN VISUAL GATE (mandatory, 5 pts)") -- because the
# scorer FUNCTIONS were genuinely gone, and that is all MC01 looks at. So assert over what the script
# PRINTS, not only over its symbols.
mapfile -t echoed < <(grep -nE '^[[:space:]]*(echo|printf)' "$MC" \
    | grep -iE '[0-9]+ ?pts|/30|/68|scoring|score' \
    | grep -viE 'no scoring|not score|does not score')
chk "${#echoed[@]}" 0 MC03 "no score value or scoring claim survives in the script's own OUTPUT"
[[ "${#echoed[@]}" -eq 0 ]] || printf '       %s\n' "${echoed[@]}"

# Control: MC03 must be able to see a planted score string, or it passes for the wrong reason.
#
# This control must run MC03's detector VERBATIM -- including the `grep -v` exclusion stage. An earlier
# version dropped that stage, so it matched the legitimate `... No scoring.` line that is already in the
# file and reported success without the plant ever mattering. A control that passes on the unmodified
# file controls nothing, so it is measured before AND after: the delta is the assertion.
mc03_detect() {   # $1 = file -> count of offending output lines, using MC03's exact pipeline
    grep -nE '^[[:space:]]*(echo|printf)' "$1" \
        | grep -iE '[0-9]+ ?pts|/30|/68|scoring|score' \
        | grep -viE 'no scoring|not score|does not score' | wc -l
}
MCCTL="$(mktemp)"; cp "$MC" "$MCCTL"
n_before=$(mc03_detect "$MCCTL")
printf 'echo "  Scores K1 (10) + K2 (15) = 30 pts."\n' >> "$MCCTL"
n_after=$(mc03_detect "$MCCTL")
rm -f "$MCCTL"
if [[ "${n_before:-1}" -eq 0 && "${n_after:-0}" -eq 1 ]]; then
    ok MC04 "MC03's detector is silent on the real file and fires on the plant (control: 0 -> 1)"
else
    no MC04 "control did not isolate the plant: before=${n_before} after=${n_after}, expected 0 -> 1"
fi

# --input must reach its own rejection. Under `set -euo pipefail` the answer-extracting greps aborted
# the script before the check below them could run, so a malformed file exited 1 in silence where the
# documented contract is exit 2 with a reason.
MCT="$(mktemp -d)"
printf '{}\n' > "$MCT/empty.json"
bash "$MC" --input "$MCT/empty.json" >/dev/null 2>&1
chk "$?" 2 MC05 "--input rejects a JSON with no answers with exit 2, not a silent exit 1"

# Every value-taking flag given as the LAST argument. `shift 2` with one argument left fails under
# `set -euo pipefail`, and the script exited 1 with empty stdout AND stderr -- silence, at the code its
# header reserves for "user aborted". The contract is exit 2 with a reason, for all seven.
mc_flag_bad=()
for flag in --html --out --input --k1 --k2 --v1 --notes; do
    msg=$(bash "$MC" "$flag" 2>&1); rc=$?
    [[ "$rc" -eq 2 ]] || mc_flag_bad+=("${flag}:exit${rc}")
    printf '%s' "$msg" | grep -q . || mc_flag_bad+=("${flag}:silent")
done
if [[ "${#mc_flag_bad[@]}" -eq 0 ]]; then
    ok MC07 "all 7 value-taking flags exit 2 with a reason when given no value"
else
    no MC07 "flags that did not exit 2 with a message: ${mc_flag_bad[*]}"
fi

# And normalising must not be lossy. The rewrite once dropped `notes` -- the one field here that nothing
# else can reconstruct, and the one state-fix.md's expose-propose-ask loop reads.
bash "$MC" --k1 y --k2 p --v1 n --notes 'quoted "ok" and back\slash' --html h.html \
     --out "$MCT/rt.json" >/dev/null 2>&1
bash "$MC" --input "$MCT/rt.json" >/dev/null 2>&1
bash "$MC" --input "$MCT/rt.json" >/dev/null 2>&1      # twice: the round-trip must be idempotent
if grep -qF 'quoted \"ok\" and back\\slash' "$MCT/rt.json"; then
    ok MC06 "--input carries notes across the rewrite, escaping intact over two passes"
else
    no MC06 "--input lost or re-escaped the notes: $(grep '"notes"' "$MCT/rt.json" || echo absent)"
fi
# A MULTI-LINE note. The interactive prompt invites one, and JSON forbids a raw control character inside
# a string -- so escaping only backslash and quote produced a file that is not JSON, after which --input
# read the notes back as "" and destroyed the only field here nothing else can reconstruct. MC06's
# fixture is single-line, so it could not see this.
bash "$MC" --k1 y --k2 y --v1 y --html h.html \
     --notes "$(printf 'line1\nline2\twith "q" and back\\slash')" \
     --out "$MCT/ml.json" >/dev/null 2>&1
if grep -q '"notes": "line1\\nline2\\twith \\"q\\" and back\\\\slash"' "$MCT/ml.json"; then
    ok MC08 "a multi-line note is escaped to valid JSON (newline, tab, quote, backslash)"
else
    no MC08 "multi-line note mis-escaped: $(grep '"notes"' "$MCT/ml.json" | head -1)"
fi
# MC09 drives EVERY C0 control plus DEL through --notes and requires the result to be valid JSON whose
# value round-trips exactly. The previous version could not fail: its fixture held only tab, CR and
# newline -- the three the escaper already handled -- and its byte range omitted 0x09, so deleting the
# tab escape left it green while the file carried a raw 0x09. An assertion whose fixture only contains
# cases that already pass is not an assertion.
#
# The escaper must therefore be a CLASS fix: a short escape where JSON defines one (\b \t \n \f \r),
# \uXXXX for every other control. This drives all 32.
mc09_bad=()
for hex in 01 02 03 04 05 06 07 08 09 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 7f; do
    v=$(printf "a\\x${hex}b")
    bash "$MC" --k1 y --k2 y --v1 y --notes "$v" --out "$MCT/c_${hex}.json" >/dev/null 2>&1 \
        || { mc09_bad+=("${hex}:exit"); continue; }
    # Not JSON if a raw control byte survives anywhere in the file.
    if LC_ALL=C grep -qP '[\x00-\x09\x0b-\x1f\x7f]' "$MCT/c_${hex}.json"; then
        mc09_bad+=("${hex}:raw-byte")
    fi
done
if [[ "${#mc09_bad[@]}" -eq 0 ]]; then
    ok MC09 "all 31 C0 controls + DEL are escaped, never emitted raw (32 cases)"
else
    no MC09 "control characters emitted raw or rejected: ${mc09_bad[*]}"
fi
# And the escaped form must survive normalisation unchanged, or every pass doubles the backslashes.
cp "$MCT/ml.json" "$MCT/ml2.json"
bash "$MC" --input "$MCT/ml2.json" >/dev/null 2>&1
bash "$MC" --input "$MCT/ml2.json" >/dev/null 2>&1
if diff <(grep '"notes"' "$MCT/ml.json") <(grep '"notes"' "$MCT/ml2.json") >/dev/null 2>&1; then
    ok MC10 "the multi-line note is byte-identical after two --input passes"
else
    no MC10 "normalisation altered the note: $(grep '"notes"' "$MCT/ml2.json" | head -1)"
fi

# MC11 -- a COMPACT (single-line) --input file. Every fixture above is built BY the script, which only
# ever writes the pretty one-key-per-line form, so no assertion here had ever fed it a compact object --
# and the extraction was a greedy `\(.*\)` that ran to the LAST quote on the line. MEASURED before the
# fix: notes came back as `hi","html_file":"x.html","timestamp":"t`, the rewrite emitted duplicate
# html_file/timestamp keys, the file was no longer JSON, and the script printed "Validated" and exited 0.
# The four cases are the ones a regex cannot tell apart from a terminator: a plain value, an embedded
# escaped quote beside a literal backslash, escaped control characters, and a value that CONTAINS a
# quoted key of its own.
mc11_bad=()
# The comparison is between JSON-ESCAPED forms, which are pure ASCII. Comparing the decoded strings
# instead made this assertion fail on a value the script had round-tripped correctly: python's `print`
# is text-mode, so on Windows it turned the note's `\n` into `\r\n` inside the probe, and the CR was the
# probe's, not the script's. An expected value that can be re-encoded on its way to the comparison is
# not an expected value.
mc11_case() {   # mc11_case NAME COMPACT_JSON EXPECTED_JSON_PAIR
    local name="$1" json="$2" want="$3" got
    printf '%s\n' "$json" > "$MCT/${name}.json"
    bash "$MC" --input "$MCT/${name}.json" >/dev/null 2>&1 || { mc11_bad+=("${name}:rc"); return; }
    got=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1],encoding="utf-8")); print(json.dumps([d["notes"],d["html_file"]],separators=(",",":")))' \
          "$MCT/${name}.json" 2>/dev/null) || { mc11_bad+=("${name}:not-json-after-rewrite"); return; }
    [[ "$got" == "$want" ]] || mc11_bad+=("${name}:altered->${got}")
}
if command -v python3 >/dev/null 2>&1; then
    mc11_case flat  '{"K1_answer":"y","K2_answer":"y","V1_answer":"y","notes":"hi","html_file":"x.html","timestamp":"t"}' \
                    '["hi","x.html"]'
    mc11_case quote '{"K1_answer":"y","K2_answer":"p","V1_answer":"n","notes":"he said \"go\" then \\ left","html_file":"a.html","timestamp":"t"}' \
                    '["he said \"go\" then \\ left","a.html"]'
    mc11_case ctrl  '{"K1_answer":"n","K2_answer":"y","V1_answer":"y","notes":"line1\nline2\ttabbed","html_file":"b.html","timestamp":"t"}' \
                    '["line1\nline2\ttabbed","b.html"]'
    mc11_case brace '{"K1_answer":"y","K2_answer":"y","V1_answer":"y","notes":"{\"html_file\":\"evil.html\"}","html_file":"c.html","timestamp":"t"}' \
                    '["{\"html_file\":\"evil.html\"}","c.html"]'
    if [[ "${#mc11_bad[@]}" -eq 0 ]]; then
        ok MC11 "a compact single-line --input round-trips exactly (4 cases incl. embedded quote and brace)"
    else
        no MC11 "compact --input mishandled: ${mc11_bad[*]}"
    fi
else
    no MC11 "python3 unavailable -- cannot verify the compact --input round trip (not a pass)"
fi

# MC12 -- and a string that is never CLOSED is a malformed input, which the contract says exits 2 with a
# reason. The greedy form could not distinguish it: it simply captured to end-of-line and rewrote the
# file, so a truncated hand-edited checklist was silently "normalised" into a different document.
printf '%s\n' '{"K1_answer":"y","K2_answer":"y","V1_answer":"y","notes":"oops' > "$MCT/unclosed.json"
cp "$MCT/unclosed.json" "$MCT/unclosed.orig"
mc12_msg=$(bash "$MC" --input "$MCT/unclosed.json" 2>&1); mc12_rc=$?
if [[ "$mc12_rc" -eq 2 ]] && printf '%s' "$mc12_msg" | grep -qi 'never closed' \
   && cmp -s "$MCT/unclosed.json" "$MCT/unclosed.orig"; then
    ok MC12 "an unclosed string exits 2 with a reason and leaves the input untouched"
else
    no MC12 "expected exit 2 + reason + untouched file, got rc=${mc12_rc}, msg='$(printf '%s' "$mc12_msg" | head -1)', modified=$(cmp -s "$MCT/unclosed.json" "$MCT/unclosed.orig" && echo no || echo yes)"
fi
rm -rf "$MCT"

echo
echo "== the emitter is RUN, not just read =="
# Every assertion above greps the emitter's text. Text assertions cannot see a detection bug, and three
# were live: S2 and NM were parsed with a pattern that does not match the shape the validator prints
# them in, so SUMMARY-03 and SUMMARY-07 could never fire; contrast was parsed with a pattern matching
# neither of its line shapes, so PRE-11 could never fire either. All three greps "passed" throughout.
EMT="$(mktemp -d)"

# The two shapes validate-html-output.sh really uses, verbatim: marker-first for H1/A*/L*, marker-last
# for S2 and NM. Extract the emitter's own detector and drive it with both.
( eval "$(sed -n '/^check_failed() {/,/^}/p' "$EMIT")"
  printf '%s\n' \
    '  ❌ H1. HTML validity (tidy reported errors)' \
    '  S2. Offline render [FAIL] found CDN reference(s) in output HTML:' \
    '  ❌ NM.2 mermaid.initialize() call detected -- engine still wired in' \
    '  ✅ L2. 12/12 relative md links resolve' > "$EMT/fail.log"
  for k in H1 S2 NM; do check_failed "$k" "$EMT/fail.log" || { echo "MISS $k"; }; done
  check_failed L2 "$EMT/fail.log" && echo "FALSEPOS L2"
  printf '%s\n' \
    '  ✅ H1. HTML validity (tidy: 0 errors)' \
    '  S2. Offline render [PASS] no external CDN script or link (self-contained)' \
    '  NM. No-Mermaid-engine [PASS] no Mermaid runtime engine or init call in output' > "$EMT/pass.log"
  for k in H1 S2 NM; do check_failed "$k" "$EMT/pass.log" && echo "FALSEPOS $k"; done
  true ) > "$EMT/out" 2>&1
if [[ ! -s "$EMT/out" ]]; then
    ok EM01 "the failure detector reads BOTH validator line shapes, with no false positive on PASS"
else
    no EM01 "detector wrong on a real validator line shape: $(tr '\n' ' ' < "$EMT/out")"
fi

# NM must NOT be a bare grep for "mermaid" in the HTML. This project's own kb.html says the word five
# times -- CSS comments and sentences about the engine having been RETIRED -- so a bare grep reports the
# presence of the very thing whose absence it asserts, and one spurious [HIGH] caps the summary at D+.
printf '%s\n' '<!DOCTYPE html><html><head><title>t</title></head><body><main>' \
  '<!-- Decision D-012 retired the Mermaid diagram engine; visuals are inline SVG. -->' \
  '</main></body></html>' > "$EMT/prose.html"
out=$(cd "$EMT" && bash "$EMIT" prose.html --dry-run 2>&1 || true)
if printf '%s' "$out" | grep -q 'SUMMARY-07'; then
    no EM02 "a prose mention of the retired engine still emits SUMMARY-07 (false positive)"
else
    ok EM02 "a prose mention of the retired engine emits no SUMMARY-07"
fi

# An unrun check is not a passed check. With no settings.yml the coverage check cannot run, and the
# documented exit code for that is 2 -- because exit 0 with an empty ledger grades A+ for an artifact
# nothing examined, which is worse than any failing grade.
(cd "$EMT" && bash "$EMIT" prose.html --dry-run >/dev/null 2>&1)
chk "$?" 2 EM03 "a run with an unevaluated check group exits 2, not 0"

# EM04/EM05 -- the unmapped-check guard must attribute LINE BY LINE, not by aggregate count. It used to
# compare only the finding count before and after the loop, so it fired only when NOTHING matched: one
# mapped failure beside an unmapped one -- the ordinary case -- hid the unmapped one entirely and the run
# still exited 1, the code for a complete run. Driven with a stub validator so the case is reproducible.
mkdir -p "$EMT/summarize"
cp "$EMIT" "$EMT/summarize/"
printf '%s\n' '<!DOCTYPE html><html><head><title>t</title></head><body><main>x</main></body></html>' > "$EMT/kb.html"
{ printf '%s\n' '#!/usr/bin/env bash' \
    'echo "  ❌ A1.2 has <header role=banner>"' \
    'echo "  ❌ skip-link present"' \
    'echo "❌ HTML output validation failed: 19/21 checks passed"' \
    'exit 1' ; } > "$EMT/summarize/validate-html-output.sh"
n_unmapped=$(cd "$EMT" && bash summarize/emit-summary-findings.sh kb.html --dry-run 2>&1 \
             | grep -c 'no rule claims' || true)
chk "${n_unmapped:-0}" 1 EM04 "an unmapped failure is reported even when a mapped one also failed"

# ...and the validator's own aggregate roll-up must NOT be reported as unattributed, or the note fires on
# every genuinely-failing run and a reader learns to ignore it.
{ printf '%s\n' '#!/usr/bin/env bash' \
    'echo "  ❌ A1.2 has <header role=banner>"' \
    'echo "❌ HTML output validation failed: 20/21 checks passed"' \
    'exit 1' ; } > "$EMT/summarize/validate-html-output.sh"
n_agg=$(cd "$EMT" && bash summarize/emit-summary-findings.sh kb.html --dry-run 2>&1 \
        | grep -c 'no rule claims' || true)
chk "${n_agg:-1}" 0 EM05 "the validator's aggregate summary line is not mistaken for an unmapped check"

# EM06 -- ...nor must a check's PER-INSTANCE detail lines be. The validator marks the unit by indent
# depth: 0 = the run's aggregate, 2 = a check verdict, 4 = one instance inside a check. Feeding the
# 4-space lines to the guard made an ordinary broken anchor exit 2 (a check group could not be
# evaluated -> PAUSE-FOR-USER-ACTION) rather than 1, because no RULE_FOR key claims `#does-not-exist` --
# while L1 itself was mapped, emitted and correct. MEASURED on a real kb.html fixture with two dead
# anchors and one dead ./x.md: four spurious notes, rc=2. The stub reproduces the exact shapes from
# validate-html-output.sh:367 and :393.
{ printf '%s\n' '#!/usr/bin/env bash' \
    'echo "  ❌ L1. 2 anchor link(s) broken (of 2)"' \
    'echo "    ❌ #does-not-exist — no matching id=\"does-not-exist\""' \
    'echo "    ❌ #also-missing — no matching id=\"also-missing\""' \
    'echo "  ❌ L2. 1 md link(s) broken (of 1)"' \
    'echo "    ❌ ./missing-doc.md — file does not exist at ./missing-doc.md"' \
    'echo "❌ HTML output validation failed: 19/21 checks passed"' \
    'exit 1' ; } > "$EMT/summarize/validate-html-output.sh"
inst_out=$(cd "$EMT" && bash summarize/emit-summary-findings.sh kb.html --dry-run 2>&1 || true)
n_inst=$(printf '%s\n' "$inst_out" | grep -c 'no rule claims' || true)
# Both checks must still be REPORTED -- a guard fixed by looking at nothing would also score 0 notes.
n_rows=$(printf '%s\n' "$inst_out" | grep -cE 'SUMMARY-0(8|9)' || true)
if [[ "${n_inst:-1}" -eq 0 && "${n_rows:-0}" -eq 2 ]]; then
    ok EM06 "per-instance detail lines are attributed to their check, not reported as unmapped"
else
    no EM06 "expected 0 unmapped notes and 2 rule rows, got ${n_inst:-?} notes and ${n_rows:-?} rows"
fi
rm -rf "$EMT"

echo
echo "== an unanswered checklist pauses instead of grading F =="
# This is the behavioural change, and it is easy to lose: reporting F for an unperformed check asserts a
# result nobody observed, and hides a real failure behind an identical score.
grep -qi 'pause, not a grade\|pause, not a failing grade\|no grade at all' \
     "$ROOT/canonical/skills/aid-summarize/references/state-manual-checklist.md"
chk "$?" 0 UA01 "MANUAL-CHECKLIST states that unanswered means no grade"
# The advance TYPE is the assertion, not the word "halt". UA02 used to accept "HALT and ask", which
# pinned the router to the one type that is terminal -- so the test actively defended the bug: an
# unanswered checklist is waiting on a human who will come back, which is PAUSE-FOR-USER-ACTION.
grep -q 'PAUSE-FOR-USER-ACTION' "$ROOT/canonical/skills/aid-summarize/SKILL.md"
chk "$?" 0 UA02 "the router types an unanswered checklist as PAUSE-FOR-USER-ACTION"
grep -q 'PAUSE-FOR-USER-ACTION' "$ROOT/canonical/skills/aid-summarize/references/state-manual-checklist.md"
chk "$?" 0 UA02b "MANUAL-CHECKLIST's own Advance agrees with the router"
# And the old behaviour must be gone.
c=$(grep -rc 'forces Human Grade = F\|Human Grade is forced to F' \
    "$ROOT/canonical/skills/aid-summarize/" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
chk "${c:-1}" 0 UA03 "no surface still forces a failing grade for an unanswered check"

echo
echo "== the checklist gates approval by EXISTING, not by scoring =="
# This is task-003's second acceptance criterion, and it had no mechanical test -- the surface said
# "the checklist must have been completed" without naming anything testable, which is a judgement call
# dressed as a precondition.
APPROVAL="$ROOT/canonical/skills/aid-summarize/references/state-approval.md"
grep -q 'manual-checklist\.json' "$APPROVAL"
chk "$?" 0 CK01 "APPROVAL's precondition names the artifact whose existence gates it"
grep -qE 'test -f .*manual-checklist\.json' "$APPROVAL"
chk "$?" 0 CK02 "the precondition is a file test, not a judgement"
# It must NOT gate on a score or a second grade -- that is the thing being retired.
# Exclude the negations -- the file legitimately says the checklist is "not scored", and a pattern that
# cannot tell an assertion from its denial reports the fix as the defect.
if grep -iE 'checklist[^.]*scor' "$APPROVAL" \
   | grep -qviE 'not scored|never scored|not by a score|not on a score|rather than a score|no score'; then
    no CK03 "APPROVAL still gates on a checklist SCORE rather than its existence"
else
    ok CK03 "APPROVAL gates on existence, not on a score"
fi
# GENERATE and APPROVAL must agree on the Checklist field's two forms, or the dashboard reads a value
# no surface declares.
GEN="$ROOT/canonical/skills/aid-summarize/references/state-generate.md"
# The two forms are declared in prose that spans lines, so match the FILE, not a single line.
if grep -q '\*\*Checklist:\*\* Not run' "$GEN" && grep -qE 'Checklist: *Completed' "$APPROVAL" \
   && grep -qF 'Not run' "$APPROVAL" && grep -qF 'Completed YYYY-MM-DD' "$APPROVAL"; then
    ok CK04 "GENERATE and APPROVAL agree on the Checklist field's declared value set"
else
    no CK04 "the Checklist field's value set is not declared consistently across GENERATE and APPROVAL"
fi

# CK05 -- agreeing on the VALUE set is not agreeing on the FORM. CK04 compares values only, so it
# passed while the template declared `| Grade |` and `| Checklist |` as rows of the section's
# Field/Value table and GENERATE wrote them as `**Grade:**` / `**Checklist:**` body lines -- exactly
# the table-row-vs-bold-line split whose earlier instance the template's own header comment records as
# having caused a silent misparse. The writer's form wins: these are per-run values, and
# state-approval.md already calls Checklist "an agent-written body line".
DSTPL="$ROOT/canonical/aid/templates/discovery-state-template.md"
form_bad=()
for field in Grade "Grade Source" Checklist; do
    # In the template: a body line, and NOT a row of the Field/Value table.
    grep -qE "^\*\*${field}:\*\*" "$DSTPL" || form_bad+=("template:${field}:no-body-line")
    grep -qE "^\| *${field} *\|" "$DSTPL" && form_bad+=("template:${field}:still-a-table-row")
    # In the writer: the same body-line form.
    grep -qE "^\*\*${field}:\*\*" "$GEN"  || form_bad+=("state-generate:${field}:no-body-line")
done
if [[ "${#form_bad[@]}" -eq 0 ]]; then
    ok CK05 "the template and GENERATE declare Grade/Grade Source/Checklist in the SAME form (body line)"
else
    no CK05 "form disagreements: ${form_bad[*]}"
fi

# CK06 -- no row of that Field/Value table may carry an unescaped pipe, which silently turns a 2-column
# row into a 3-to-5-column one. Three rows did: `| Profile Source | {auto-detected | user-specified} |`,
# the Profile Confidence row, and `| Theme | default | brand-{name} |`.
# Bracket classes, not `\|`. A backslash-escaped `|` in an awk ERE is undefined behaviour: gawk 5.4
# treats it as a literal pipe, but an awk that instead reads it as the alternation operator sees
# `/|/` -- empty-or-empty -- which matches at every position, and every count this check makes would
# be garbage in a way that still yields a number. `[|]` cannot be read two ways.
# Counted on a COPY with "&" as the replacement, so neither gsub perturbs $0 or the other's count.
ragged=$(awk '
  /^## Knowledge Summary Status/ { in_s = 1; next }
  in_s && /^## / { in_s = 0 }
  in_s && /^[|] / && $0 !~ /^[|][-| ]+[|]$/ {
    line = $0
    tot = gsub(/[|]/,   "&", line)   # every pipe, escaped or not
    esc = gsub(/\\[|]/, "&", line)   # just the escaped ones
    if (tot - esc != 3) print FNR ": " $0
  }' "$DSTPL")
if [[ -z "$ragged" ]]; then
    ok CK06 "every row of the Knowledge Summary Status table has exactly two columns"
else
    no CK06 "ragged rows (unescaped pipe in a value): $(printf '%s' "$ragged" | tr '\n' ' ' | cut -c1-160)"
fi

# GR01 -- the generated settings reference must agree with the file it declares as its source.
# `site/src/content/docs/reference/settings.md` carries `generatedFrom: .aid/settings.yml` and
# "generated -- do not edit", and it published `minimum_grade | A+` for the whole span in which the
# source said `B-`: the delivery re-ran the generator for agents.md and skills.md but not after the
# settings change. Nothing anywhere covers it -- `grep -rl gen-reference tests/ .github/workflows/`
# matches nothing, and the repo registers no generated-files manifest for the page. Comparing the
# published value against the ACCESSOR (not against the YAML text) also means this passes only if the
# page, the file and the resolution path all agree.
SETTINGS_PAGE="$ROOT/site/src/content/docs/reference/settings.md"
if [[ -f "$SETTINGS_PAGE" ]]; then
    published=$(grep -E '^\| `minimum_grade` \|' "$SETTINGS_PAGE" | head -1 \
                | awk -F'|' '{print $3}' | tr -d ' `')
    resolved=$(bash "$ROOT/canonical/aid/scripts/config/read-setting.sh" \
                    --skill execute --key minimum_grade --default A 2>/dev/null)
    if [[ -z "$published" ]]; then
        no GR01 "the generated settings page has no minimum_grade row -- the check reads nothing"
    else
        chk "$published" "$resolved" GR01 "the generated settings reference publishes the resolved minimum_grade"
    fi
else
    no GR01 "the generated settings reference is missing: $SETTINGS_PAGE"
fi

echo
echo "== the two-grade model appears on no surface =="
# The pattern IS the assertion. A narrower one (Machine Grade|Human Grade|Overall Grade|AUTO_POOL|
# MANUAL_POOL) reported zero while aid-summarize's own frontmatter description still read "Two-grade
# quality gate (Machine + Human) ... APPROVAL requires BOTH grades >= minimum" -- the surface the skill
# catalogue renders. Every phrasing that ever carried the model is listed here. Extend it; never trim it.
# Two halves, because case matters differently for each.
#
# TG_PAT_CS -- FIELD NAMES, matched case-SENSITIVELY. These are literal field names as the artifacts
# spell them. Matching them case-insensitively makes them ordinary English: "Overall grade and minimum"
# in aid-discover's approval print block, and "there is no separate human grade to combine" in
# state-manual-checklist.md's retirement prose, are both legitimate and neither names a field.
TG_PAT_CS='Machine Grade|Human Grade|Overall Grade|Machine total|Human total|AUTO_POOL|MANUAL_POOL'
TG_PAT_CS="$TG_PAT_CS"'|MACHINE_GRADE|HUMAN_GRADE|OVERALL_GRADE|Pending Human Review|machine-pool'
TG_PAT_CS="$TG_PAT_CS"'|human-pool|Machine [+] Human|min[(]Machine|Machine_letter|Human_letter'
#
# TG_PAT_CI -- PHRASES, matched case-INSENSITIVELY. A phrase carries the model whatever its
# capitalisation, and the live instruction that survived nine cycles proved it: TG_PAT spelled
# `both Machine and Human` while the APPROVAL banner read `Both Machine and Human grades`.
TG_PAT_CI='both machine and human|both grades|two-grade|two grades|percentage ladder'
TG_PAT_CI="$TG_PAT_CI"'|weighted average.*grade|grade.*weighted average'

# Passages that EXPLAIN the retirement are legitimate and must survive -- deleting them would leave the
# next reader no account of why the model went.
#
# They are allowed PER LINE, by a distinctive snippet of the retirement statement itself -- NOT by file.
# The by-file form excluded five files WHOLE, and the surviving live instruction was inside one of them:
# aid-summarize/SKILL.md's APPROVAL banner read "Both Machine and Human grades meet minimum", a string
# the router prints. MEASURED: appending a fresh two-grade instruction to that file's body left the suite
# fully green, while the same line appended to state-approval.md failed TG01 -- so the guard's verdict
# depended on which file the defect landed in. Line-level allowlisting cannot hide a body.
#
# Every entry is `<path-fragment>|<snippet that must appear on the same line>`. Seven entries, one per
# known retirement statement. A new occurrence, or an edit that moves the vocabulary off these lines,
# fails -- which is the intended cost: these seven sentences are historical statements and should not
# churn.
TG_ALLOW=(
  'knowledge-summary/grading-rubric.md|two-grade minimum are gone'
  'knowledge-summary/grading-rubric.md|were the two pools of the retired'
  'knowledge-summary/grading-rubric.md|percentage ladder was retired'
  'knowledge-summary/grading-rubric.md|why there are no longer'
  'aid-summarize/README.md|One grading backend'
  'aid-summarize/SKILL.md|why the two-grade model was retired'
  'summarize/emit-summary-findings.sh|This script derived one from'
  'aid-discover/SKILL.md|This used to read'
)
# -i, not case-sensitive matching. TG_PAT spelled `both Machine and Human` lower-case while the live
# banner read `Both Machine and Human`, so the pattern missed it even outside an excluded file.
# tg_disallowed -- reads `path:lineno:text` hits on stdin, prints the ones no allowance covers. TG01 and
# its control TG03 both go through THIS, so the control cannot pass while the assertion is broken.
tg_disallowed() {
    local hit entry frag snip allowed
    while IFS= read -r hit; do
        [[ -n "$hit" ]] || continue
        allowed=0
        for entry in "${TG_ALLOW[@]}"; do
            frag="${entry%%|*}"; snip="${entry#*|}"
            [[ "$hit" == *"$frag"* && "$hit" == *"$snip"* ]] && { allowed=1; break; }
        done
        [[ "$allowed" -eq 1 ]] || printf '%s\n' "$hit"
    done
}
# tg_raw_hits -- the whole feed, both halves, path-relative. One function, so TG01, TG04 and TG02
# cannot drift apart in what they sweep.
tg_raw_hits() {
    { grep -rnE  "$TG_PAT_CS" "$ROOT/canonical/" 2>/dev/null
      grep -rniE "$TG_PAT_CI" "$ROOT/canonical/" 2>/dev/null; } \
        | sed "s|^${ROOT}/||" | sort -u
}
mapfile -t tg_hits < <(tg_raw_hits | tg_disallowed || true)
chk "${#tg_hits[@]}" 0 TG01 "no canonical LINE carries the two-grade vocabulary outside a retirement statement"
[[ "${#tg_hits[@]}" -eq 0 ]] || printf '       %s\n' "${tg_hits[@]:0:8}"

# TG01's allowlist must not be able to grow silently either: an entry that matches nothing is a stale
# exclusion, and a stale exclusion is how the list turns back into a whole-file pass.
tg_stale=()
for entry in "${TG_ALLOW[@]}"; do
    frag="${entry%%|*}"; snip="${entry#*|}"
    tg_raw_hits | grep -F "$frag" | grep -qF "$snip" || tg_stale+=("$entry")
done
chk "${#tg_stale[@]}" 0 TG04 "every retirement-prose allowance still matches a real line"
[[ "${#tg_stale[@]}" -eq 0 ]] || printf '       stale: %s\n' "${tg_stale[@]}"

# In an explainer file the vocabulary may appear ONLY in retirement prose, never as a live instruction.
# The frontmatter description is the sharpest case: it is metadata, so it cannot be explaining anything.
# Each half keeps its own case rule here too -- ORing them into one -E pattern would silently make the
# case-insensitive half case-sensitive, which is the exact defect the split exists to fix.
fm_block=$(awk '/^---$/{n++; next} n==1' "$ROOT/canonical/skills/aid-summarize/SKILL.md")
fm=$(( $(printf '%s\n' "$fm_block" | grep -cE  "$TG_PAT_CS" || true) \
     + $(printf '%s\n' "$fm_block" | grep -ciE "$TG_PAT_CI" || true) ))
chk "${fm:-1}" 0 TG02 "aid-summarize's frontmatter description carries no two-grade vocabulary"

# Control: TG01 must be able to see a planted live instruction, or zero hits means nothing. Two plants,
# both through tg_disallowed: one in a file no allowance names, and one in an ALLOWED file -- the second
# is the case the by-file form could not catch, and it is planted with the exact capitalisation that
# defeated the old pattern.
n_tgctl=$(printf '%s\n' \
    'canonical/skills/planted/SKILL.md:1:APPROVAL requires BOTH grades >= minimum.' \
    'canonical/skills/aid-summarize/SKILL.md:165:[State: APPROVAL] - Both Machine and Human grades meet minimum.' \
    'canonical/aid/templates/knowledge-summary/grading-rubric.md:9:Report the Machine Grade beside the Human Grade.' \
    | tg_disallowed | wc -l)
chk "$n_tgctl" 3 TG03 "TG01 DOES find a planted live instruction, including inside an allowed file (control)"

echo
echo "== coverage tightened rather than loosened =="
grep -q 'One row per unreferenced document' "$SUMRULES"
chk "$?" 0 CV01 "SUMMARY-01 emits one row per unreferenced document"
# The band that let 19-of-20 score full marks must be gone from the rubric.
c=$(grep -c 'coverage >= 95%\|80-94%\|60-79%' "$RUBRIC" 2>/dev/null || true)
chk "${c:-1}" 0 CV02 "the partial-credit coverage bands are gone"
grep -qi 'no 60% cliff\|no bands and no cliff\|no longer has a 60% cliff' "$RUBRIC"
chk "$?" 0 CV03 "the rubric records that the coverage cliff was removed"

echo
echo "== every retired check is accounted for =="
# Retiring a scoring model must not retire coverage. The mapping table is the evidence.
grep -q 'Where the retired per-check scores went' "$SUMRULES"
chk "$?" 0 MP01 "the mapping table exists"
# All 21, not 17. T1/T2/T3 and NM were missing while the table claimed every check was accounted for --
# and they are the four a points-based audit cannot catch, because they carried ZERO weight and blocked
# DONE in prose only. An audit that enumerates by points is exactly how they went missing.
RETIRED=(COV D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2 T1 T2 T3 NM K1 K2 V1)
missing=()
for c in "${RETIRED[@]}"; do
    grep -qE "^\| \`?${c}\`? " "$SUMRULES" || missing+=("$c")
done
if [[ "${#missing[@]}" -eq 0 ]]; then
    ok MP02 "all ${#RETIRED[@]} retired checks appear in the mapping table"
else
    no MP02 "not mapped: ${missing[*]}"
fi
# D1/D2 must be marked deleted, not silently carried.
grep -qE '^\| `?D1`? .*(deleted|\*\*deleted\*\*)' "$SUMRULES"
chk "$?" 0 MP03 "D1 is recorded as deleted, not quietly dropped"

echo
echo "== grade.sh was not touched to achieve any of the above =="
# The other assertions prove the SECOND backend is gone. This one proves the first was not quietly
# edited to make that true. NFR-1 is the whole reason the delivery could claim "no change of any kind".
BASE="${GRADE_BASELINE_REF:-7a9df485}"          # delivery-014's close = this delivery's pre-state
if git -C "$ROOT" rev-parse --verify --quiet "$BASE" >/dev/null 2>&1; then
    pre=$(git -C "$ROOT" show "${BASE}:canonical/aid/scripts/grade.sh" 2>/dev/null \
          | git -C "$ROOT" hash-object --stdin 2>/dev/null || echo unreadable)
    now=$(git -C "$ROOT" hash-object "$GRADE" 2>/dev/null || echo unreadable)
    chk "$now" "$pre" NF01 "grade.sh is byte-identical to its pre-delivery state (${BASE})"
else
    # A shallow clone (CI) may not carry the baseline commit. Skipping is honest; passing would not be.
    printf '  SKIP NF01 -- baseline commit %s not present (shallow clone?); set GRADE_BASELINE_REF\n' "$BASE"
fi

echo
echo "== no surface restates a rule's severity differently from the catalog =="
# A severity restated beside a rule ID is a second source of truth for the value that decides the grade.
# state-validate.md's check table carried the retired points model's [HIGH] for L1/L2/H1 while the
# catalog had re-derived them as [LOW]/[MEDIUM]/[MEDIUM].
# The surfaces that cite rule IDs. Shared by SEV01 (severity agrees with the rule) and RID01
# (the rule exists), so the two can never drift apart in scope -- SEV01 originally swept one of
# these eight and reported clean while five drifts sat in the others.
CITERS=(
  "$ROOT/canonical/skills/aid-summarize/references/state-validate.md"
  "$ROOT/canonical/skills/aid-summarize/references/state-manual-checklist.md"
  "$ROOT/canonical/skills/aid-summarize/references/state-fix.md"
  "$ROOT/canonical/skills/aid-discover/references/state-review.md"
  "$ROOT/canonical/skills/aid-discover/references/reviewer-prompt-teachback.md"
  "$ROOT/canonical/skills/aid-discover/references/reviewer-prompt-actback.md"
  "$ROOT/canonical/skills/aid-discover/references/reviewer-prompt-correctness.md"
  "$ROOT/canonical/skills/aid-discover/references/reviewer-prompt-anatomy.md"
)
RUBRIC_DIR="$ROOT/canonical/aid/templates/review-rubrics"

VALSTATE="$ROOT/canonical/skills/aid-summarize/references/state-validate.md"
PRERULES="$ROOT/canonical/aid/templates/review-rubrics/presentation.md"

# sev_rows FILE -- the table rows that carry BOTH a rule ID and a bracketed severity, i.e. the rows
# SEV01 must compare. Backticked or bare: the reviewer-prompt files' IDs live in ledger EXAMPLE rows and
# are bare by construction, so a backtick requirement silently emptied the feed for four of eight files.
# SEV01 and SEV03 both call THIS, so the assertion and its own reach-control cannot disagree.
sev_rows() {
    grep -E '^\| ' "$1" 2>/dev/null         | grep -E '[A-Z]{2,12}-[0-9]{2}'         | grep -E '\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]'
}

# catalog_sev RULE -> the bracketed token the rule row declares (first one wins; "Step 2" has none, and
# returns empty so the row is skipped -- an instance-derived anchor cannot be compared to a fixed token).
# Resolves across the WHOLE catalog rather than a per-class file map: a hardcoded map silently returns ""
# for any class it does not list, which skips the row and passes.
#
# Built ONCE into an array, then looked up with no forks. The per-call form was 4 forks (grep -r, awk,
# grep, head) x 42 calls across SEV01 and SEV04, and this suite runs on hosts where a fork costs ~1s.
declare -A CATALOG_SEV=()
while IFS='|' read -r rule token; do
    [[ -n "$rule" ]] || continue
    [[ -n "${CATALOG_SEV[$rule]:-}" ]] || CATALOG_SEV["$rule"]="$token"   # first one wins
done < <(awk -F'|' '
  $2 ~ /^ *`[A-Z]+-[0-9]+` *$/ {
    rule = $2; gsub(/^ +| +$|`/, "", rule)
    cell = $(NF-1)
    if (match(cell, /\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]/))
        print rule "|" substr(cell, RSTART, RLENGTH)
  }' "$RUBRIC_DIR"/*.md)
catalog_sev() { printf '%s' "${CATALOG_SEV[$1]:-}"; }

# SEV01 sweeps the SAME eight files RID01 does, and every rule CLASS, not just SUMMARY/PRE in one file.
# Scoped to one file and two classes it reported clean while five live drifts sat in the sibling
# reviewer prompts -- an assertion narrower than the defect it is named for.
# TAKE EVERY rule-shaped token on the line, not the first. `head -1` took the `#` cell of a ledger
# EXAMPLE row: all four `AB-00N` rows yielded `AB-00`, both `TB-00N` rows yielded `TB-00`, catalog_sev
# returned empty for those non-rules, and `continue` dropped the row -- six of eleven example rows sat
# in the feed and were never compared, while cycle 10's comment claimed the vacuity was fixed because
# the rows now ENTER the feed. Entering a feed is not being compared, and the counter below could not
# tell the difference: it counted rows seen.
sev_bad=0
sev_compared=0
for f in "${CITERS[@]}"; do
    [[ -f "$f" ]] || continue
    while IFS= read -r line; do
        stated=$(printf '%s' "$line" | grep -oE '\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]' | head -1)
        [[ -n "$stated" ]] || continue
        matched=0
        while IFS= read -r rule; do
            [[ -n "$rule" ]] || continue
            declared=$(catalog_sev "$rule")
            [[ -n "$declared" ]] || continue   # a `#`-cell token, or a `Step 2` rule: nothing to compare
            matched=1
            sev_compared=$((sev_compared + 1))
            if [[ "$stated" != "$declared" ]]; then
                no "SEV-$(basename "$f"):${rule}" "says ${stated}, catalog declares ${declared}"
                sev_bad=1
            fi
        done < <(printf '%s' "$line" | grep -oE '[A-Z]{2,12}-[0-9]{2}' | tr -d '`' | sort -u)
        # A severity-bearing row citing NO resolvable rule is not a pass -- it is a row this assertion
        # cannot judge, and staying silent about it is how six rows hid. `Step 2` rules are the one
        # legitimate case, so name them explicitly rather than letting every unresolvable token through.
        if [[ "$matched" -eq 0 ]] \
           && ! printf '%s' "$line" | grep -qE '(KB-2[0-6]|NAR-05|SUMMARY-0[45]|INT-01|Step 2)'; then
            no "SEV-$(basename "$f")" "severity-bearing row cites no resolvable rule: $(printf '%s' "$line" | cut -c1-90)"
            sev_bad=1
        fi
    done < <(sev_rows "$f")
done
[[ "$sev_bad" -eq 0 ]] && ok SEV01 "no surface restates a severity that disagrees with the rule it cites"

# SEV01 can only report clean if it actually COMPARED something. Count comparisons performed, not rows
# seen: the row-count form read 28 while six of those rows were being dropped unjudged.
n_sev_rows="$sev_compared"
if [[ "$n_sev_rows" -ge 10 ]]; then
    ok SEV03 "SEV01 performed ${n_sev_rows} catalog comparisons (not vacuous)"
else
    no SEV03 "SEV01 performed only ${n_sev_rows} comparisons -- its feed or its extraction is broken"
fi

# Control: catalog_sev must actually read the catalog, else SEV01 passes on an empty comparison. The
# expected value is hardcoded ON PURPOSE -- a control that reads its own expectation from the thing
# under test proves nothing. If the catalog legitimately re-derives SUMMARY-08, this fails loudly and
# whoever changed it re-reads the control; that is the intended cost.
[[ "$(catalog_sev SUMMARY-08)" == "[MEDIUM]" ]] \
    && ok SEV02 "the catalog reader resolves a known severity (control: SUMMARY-08 = [MEDIUM])" \
    || no SEV02 "the catalog reader returned '$(catalog_sev SUMMARY-08)' for SUMMARY-08, expected [MEDIUM]"

# SEV04 -- the EMITTER's severity tokens, which are the ones that actually reach grade.sh.
# SEV01's feed is CITERS: eight .md files that merely RESTATE a severity. The emitter was in none of
# them, so the authoritative copy was the one surface with no guard at all. MEASURED before this
# assertion existed: flipping SEV_FOR[L1] to [HIGH] and the direct SUMMARY-01 emit to [CRITICAL] left
# the suite fully green. Feed = the SEV_FOR/RULE_FOR pair joined on the check key, plus every `emit`
# call that passes a literal rule and severity.
emit_sev_bad=()
emit_sev_n=0
# 1) SEV_FOR x RULE_FOR, joined on the check key. Extracted by sourcing the two declare blocks in a
#    subshell rather than by regex, so a reformat of the arrays cannot silently empty the feed.
while IFS='|' read -r key rule stated; do
    [[ -n "$key" ]] || continue
    emit_sev_n=$((emit_sev_n + 1))
    declared=$(catalog_sev "$rule")
    [[ -n "$declared" ]] || { emit_sev_bad+=("${key}:${rule}:no-catalog-row"); continue; }
    [[ "$stated" == "$declared" ]] || emit_sev_bad+=("${key}(${rule}):emitter=${stated},catalog=${declared}")
done < <(
    eval "$(sed -n '/^declare -A RULE_FOR=(/,/^)/p;/^declare -A SEV_FOR=(/,/^)/p' "$EMIT")"
    for k in "${!SEV_FOR[@]}"; do printf '%s|%s|%s\n' "$k" "${RULE_FOR[$k]:-}" "${SEV_FOR[$k]}"; done
)
# 2) Literal `emit "RULE" "[SEV]"` calls -- the two rules with no check key (SUMMARY-01, PRE-11).
while IFS='|' read -r rule stated; do
    [[ -n "$rule" ]] || continue
    emit_sev_n=$((emit_sev_n + 1))
    declared=$(catalog_sev "$rule")
    [[ -n "$declared" ]] || { emit_sev_bad+=("${rule}:no-catalog-row"); continue; }
    [[ "$stated" == "$declared" ]] || emit_sev_bad+=("${rule}:emitter=${stated},catalog=${declared}")
done < <(grep -oE 'emit "[A-Z]+-[0-9]{2}" "\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]"' "$EMIT" \
         | sed -E 's/emit "([A-Z]+-[0-9]{2})" "(\[[A-Z]+\])"/\1|\2/')
if [[ "${#emit_sev_bad[@]}" -eq 0 && "$emit_sev_n" -ge 12 ]]; then
    ok SEV04 "all ${emit_sev_n} severity tokens the emitter writes match the catalog"
elif [[ "$emit_sev_n" -lt 12 ]]; then
    no SEV04 "the emitter severity feed collected only ${emit_sev_n} tokens (expected >= 12) -- extraction is broken"
else
    no SEV04 "emitter severities disagreeing with the catalog: ${emit_sev_bad[*]}"
fi

# SEV06 -- a severity stated for a lint TAG in PROSE must match the anchor of the rule that tag cites.
# SEV01 cannot reach these: its feed is table rows (`^| `), and a reviewer prompt states its severities
# in prose bullets. So while the delivery re-derived the [CAL-*] example ROWS to [LOW], five prose
# statements in the same file still read [HIGH]/[MEDIUM]/[MEDIUM] -- the retired flat-limb values -- and
# the lint-tag table in kb-authoring/review-rubric.md still declared them flatly too. A reviewer obeying
# the prose would write a Severity cell contradicting its own Rule cell.
#
# The TAG -> RULE map is READ from that table, not hardcoded: its cells now read
# `_the cited rule's anchor_ (`KB-08`)`. A tag whose cell is still a flat value has no rule to compare
# against and is skipped -- which is why TAG_MAPPED below is also asserted non-empty.
declare -A TAG_RULE=()
while IFS='|' read -r tag rule; do
    [[ -n "$tag" && -n "$rule" ]] && TAG_RULE["$tag"]="$rule"
done < <(awk -F'|' '
  $2 ~ /^ *`\[[A-Z-]+\]` *$/ && $3 ~ /cited rule/ {
    tag = $2; cell = $3
    gsub(/^ +| +$|`|\[|\]/, "", tag)
    if (match(cell, /`[A-Z]+-[0-9]+`/)) {
        rule = substr(cell, RSTART + 1, RLENGTH - 2)
        print tag "|" rule
    }
  }' "$ROOT/canonical/aid/templates/kb-authoring/review-rubric.md")
sev06_bad=()
sev06_n=0
for f in "${CITERS[@]}" "$ROOT/canonical/aid/templates/kb-authoring/review-rubric.md"; do
    [[ -f "$f" ]] || continue
    for tag in "${!TAG_RULE[@]}"; do
        declared=$(catalog_sev "${TAG_RULE[$tag]}")
        [[ -n "$declared" ]] || continue
        # Every line naming this tag AND a bracketed severity, table row or prose alike.
        while IFS= read -r line; do
            [[ -n "$line" ]] || continue
            sev06_n=$((sev06_n + 1))
            # The line is fine if the declared token appears on it at all -- the escape form legitimately
            # names two ([LOW] escaping to [MEDIUM]), and a rewrite may phrase it either way round.
            printf '%s' "$line" | grep -qF "$declared" \
                || sev06_bad+=("$(basename "$f"):${tag}(${TAG_RULE[$tag]}) states $(printf '%s' "$line" | grep -oE '\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]' | tr '\n' '/' ) want ${declared}")
        done < <(grep -nE "\[${tag}\]" "$f" 2>/dev/null \
                 | grep -E '\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]' \
                 | grep -viE 'used to read|formerly|retired|no longer|the values the retired')
    done
done
if [[ "${#TAG_RULE[@]}" -eq 0 ]]; then
    no SEV06 "the TAG->RULE map is empty -- the lint-tag table's shape changed and this guard reads nothing"
elif [[ "$sev06_n" -lt 3 ]]; then
    no SEV06 "only ${sev06_n} tag/severity lines examined across ${#TAG_RULE[@]} mapped tags -- feed is broken"
elif [[ "${#sev06_bad[@]}" -eq 0 ]]; then
    ok SEV06 "all ${sev06_n} prose/table severities for the ${#TAG_RULE[@]} rule-mapped lint tags match the catalog"
else
    no SEV06 "tag severities disagreeing with their cited rule: ${sev06_bad[*]}"
fi

# SEV05 -- every catalog row's Severity must sit in the band its own Modality selects. This is Step 1
# of grading-rubric.md's scale, and nothing enforced it: SUMMARY-08 shipped MUST/[LOW], which Step 1
# forbids (MUST -> Step 2 -> CRITICAL/HIGH/MEDIUM; [LOW] is reserved for a SHOULD), and four
# dependent surfaces had already copied the [LOW].
# The comparison is against the LEADING token, never the whole cell. Matching `Step 2` anywhere in the
# cell is how this assertion first failed to fail: with the rationale reading "-- Step 2: correction is
# local", MUST/[LOW] passed. The token is whatever the cell OPENS with; everything after it is prose,
# and prose must not be able to license a band. Three legal cell forms, per INDEX.md § The rule row:
#   `[MEDIUM]` -- rationale                        a fixed token
#   `[LOW]; escaped (>1 doc) -> [MEDIUM]`          a fixed token with the SHOULD escape
#   `Step 2` -- rationale                          instance-derived, nothing fixed to check
# Requiring the closing backtick right after the bracket rejected all 18 escape-form rows as
# <no-token>, which is why the leading match stops at the bracket.
band_bad=()
band_n=0
while IFS='|' read -r file id modality token rest; do
    [[ -n "$id" ]] || continue
    case "$modality" in
        # band_n counts rows COMPARED, incremented after this gate, not rows seen. The seen-form read 83
        # while one row was being dropped unjudged, so the non-vacuity guard could not tell the
        # difference -- the same defect as SEV03's row count.
        MUST|SHOULD|COULD) band_n=$((band_n + 1)) ;;
        # A modality this case cannot read is NOT a pass. The feed stripped only spaces, so kb.md's
        # emphasised `**SHOULD**` matched no branch and fell out of the case with no note -- and that is
        # the ONE such row in the catalog, KB-26, the row this delivery re-anchored and leaned on across
        # five surfaces. Setting its severity to [CRITICAL] left the whole suite green. The feed now
        # strips emphasis and backticks; this branch is the backstop for the next unreadable spelling.
        *) band_bad+=("${file}:${id} unreadable Modality cell '${modality}' -- not compared"); continue ;;
    esac
    case "$modality" in
        MUST)   [[ "$token" == "[CRITICAL]" || "$token" == "[HIGH]" || "$token" == "[MEDIUM]" \
                   || "$token" == "Step 2" ]] || band_bad+=("${file}:${id} MUST/${token:-<no-token>}")
                # An escape may not leave the band either: a MUST cannot decay to [LOW]/[MINOR].
                [[ "$rest" == *"[LOW]"* || "$rest" == *"[MINOR]"* ]] \
                    && band_bad+=("${file}:${id} MUST escapes below its band: ${rest}") ;;
        SHOULD) [[ "$token" == "[LOW]" || "$token" == "[MEDIUM]" || "$token" == "Step 2" ]] \
                    || band_bad+=("${file}:${id} SHOULD/${token:-<no-token>}")
                [[ "$rest" == *"[CRITICAL]"* || "$rest" == *"[HIGH]"* ]] \
                    && band_bad+=("${file}:${id} SHOULD escapes above its band: ${rest}") ;;
        COULD)  [[ "$token" == "[MINOR]" || "$token" == "Step 2" ]] \
                    || band_bad+=("${file}:${id} COULD/${token:-<no-token>}")
                [[ "$rest" == *"[CRITICAL]"* || "$rest" == *"[HIGH]"* || "$rest" == *"[MEDIUM]"* ]] \
                    && band_bad+=("${file}:${id} COULD escapes above its band: ${rest}") ;;
    esac
done < <(
    awk -F'|' '
      $2 ~ /^ *`[A-Z]+-[0-9]+` *$/ {
        id = $2; mod = $5; cell = $(NF-1)
        gsub(/^ +| +$|`/, "", id)
        # Normalise the Modality cell: emphasis and backticks are presentation, not value. Stripping
        # only spaces left the KB-26 row (**SHOULD**) unreadable, and the case fell through in silence.
        # No apostrophe in this comment: it sits inside a single-quoted awk program, and one closed it.
        gsub(/[*`]/, "", mod); gsub(/^ +| +$/, "", mod)
        gsub(/^ +| +$/, "", cell)
        token = ""; rest = cell
        if (match(cell, /^`\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]/)) {
            token = substr(cell, RSTART + 1, RLENGTH - 1)      # drop the opening backtick
            rest  = substr(cell, RSTART + RLENGTH)             # the escape clause / rationale
        } else if (cell ~ /^`Step 2`/) {
            token = "Step 2"; rest = ""                        # instance-derived: nothing fixed to check
        }
        n = split(FILENAME, parts, "/")
        print parts[n] "|" id "|" mod "|" token "|" rest
      }' "$RUBRIC_DIR"/*.md
)
if [[ "${#band_bad[@]}" -eq 0 && "$band_n" -ge 20 ]]; then
    ok SEV05 "all ${band_n} catalog rows carry a severity inside the band their modality selects"
elif [[ "$band_n" -lt 20 ]]; then
    no SEV05 "the catalog row feed collected only ${band_n} rows (expected >= 20) -- extraction is broken"
else
    no SEV05 "modality/severity band violations: ${band_bad[*]}"
fi

echo
echo "== every rule ID cited by the summarize and discover surfaces exists =="
# A gate that counts a rule ID which no catalog declares counts nothing, silently. Two of these were
# real: a [FIDELITY] example row cited KB-20, and the correctness prompt used KB-20 as a placeholder.
unknown=()
for f in "${CITERS[@]}"; do
    [[ -f "$f" ]] || continue
    while IFS= read -r id; do
        grep -rqE "^\| \`${id}\` " "$RUBRIC_DIR" 2>/dev/null || unknown+=("$(basename "$f"):${id}")
    done < <(grep -ohE '(SUMMARY|PRE|NAR|KB|CODE|SPEC|TASK)-[0-9]{2}' "$f" | sort -u)
done
if [[ "${#unknown[@]}" -eq 0 ]]; then
    ok RID01 "every cited rule ID resolves to a catalog rule row"
else
    no RID01 "unknown rule IDs: ${unknown[*]}"
fi

# Control: the resolver must reject an ID that does not exist.
grep -rqE '^\| `SUMMARY-99` ' "$RUBRIC_DIR" 2>/dev/null \
    && no RID02 "SUMMARY-99 unexpectedly exists; the control is void" \
    || ok RID02 "the resolver rejects a non-existent ID (control: SUMMARY-99)"

echo
echo "== every rule the emitter can emit is named on all three downstream surfaces =="
# This contract has broken THREE times in this delivery, each time the same way: a rule wired into the
# emitter and into some-but-not-all of the surfaces that consume it. A rule missing from the
# reconciliation list can never reach `Fixed`; one missing from the FIX repair list reaches the fixer
# with no instruction. Either stalls the VALIDATE -> FIX -> VALIDATE loop for that rule, silently.
# Prose review caught it three times and would have to keep catching it; this closes it mechanically.
VALSTATE_F="$ROOT/canonical/skills/aid-summarize/references/state-validate.md"
FIXSTATE_F="$ROOT/canonical/skills/aid-summarize/references/state-fix.md"

# The emitter's rule set = its RULE_FOR values + the rules it emits by direct call.
mapfile -t emit_rules < <(
  { grep -oE '="(SUMMARY|PRE)-[0-9]{2}"' "$EMIT" | tr -d '="' ;
    grep -oE 'emit "(SUMMARY|PRE)-[0-9]{2}"' "$EMIT" | grep -oE '(SUMMARY|PRE)-[0-9]{2}' ; } | sort -u
)
if [[ "${#emit_rules[@]}" -ge 10 ]]; then
    ok RS01 "the emitter's rule set resolves to ${#emit_rules[@]} rules (not vacuous)"
else
    no RS01 "only ${#emit_rules[@]} emitter rules found -- the extraction is broken, so RS02/RS03 mean nothing"
fi

# Both checks require the STRUCTURE that carries the obligation, not a mention of the rule anywhere in
# the file. A bare `grep -F` passes on the prose that explains the requirement -- verified: removing
# SUMMARY-03's repair bullet left the guard green, because the note above it names SUMMARY-03. A guard
# satisfied by a sentence about itself is the vacuity this suite exists to prevent.
rs_missing=()
for r in "${emit_rules[@]}"; do
    # A row of the check->rule table: a table line naming the rule.
    grep -E "^\| .*${r}" "$VALSTATE_F" >/dev/null 2>&1 || rs_missing+=("state-validate-table:$r")
done
if [[ "${#rs_missing[@]}" -eq 0 ]]; then
    ok RS02 "every emitter rule has a row in state-validate.md's check-to-rule table"
else
    no RS02 "emitter rules with no table row in state-validate.md: ${rs_missing[*]}"
fi

rs_missing2=()
for r in "${emit_rules[@]}"; do
    # Inside a repair BULLET (a line starting `- **`), not merely somewhere in the file. Several rules
    # legitimately share one bullet -- PRE-02/03/04/05 all take the same "add the missing landmark /
    # attribute / marker" action -- so the rule need not lead it. The explanatory note above the list
    # starts with `>` and is excluded, which is what stops a sentence about the requirement satisfying it.
    grep -E "^- \*\*.*${r}" "$FIXSTATE_F" >/dev/null 2>&1 || rs_missing2+=("state-fix:$r")
done
if [[ "${#rs_missing2[@]}" -eq 0 ]]; then
    ok RS03 "every emitter rule appears in a repair bullet in state-fix.md"
else
    no RS03 "emitter rules with no FIX repair bullet: ${rs_missing2[*]}"
fi

# RS05 -- the RECONCILIATION LIST, the third surface and the one whose omission matters most: a rule
# missing there is never swept, so its rows never reach `Fixed`. RS02/RS03 could not see it -- the list is
# prose, so neither a table-row nor a bullet pattern reaches it, and deleting a rule from it left the
# whole suite green. Extract the list region by its two anchors and require every emitter rule inside it.
mapfile -t recon_list < <(
  awk '/reconciliation applies ONLY to rows the emitter could have produced/{on=1}
       on{print}
       on && /Every other row is left exactly as it stands/{exit}' "$VALSTATE_F"
)
if [[ "${#recon_list[@]}" -eq 0 ]]; then
    no RS05 "could not locate the reconciliation list in state-validate.md -- its anchors moved"
else
    rs_missing3=()
    for r in "${emit_rules[@]}"; do
        printf '%s\n' "${recon_list[@]}" | grep -qF "$r" || rs_missing3+=("recon-list:$r")
    done
    if [[ "${#rs_missing3[@]}" -eq 0 ]]; then
        ok RS05 "every emitter rule is named in state-validate.md's reconciliation list"
    else
        no RS05 "emitter rules absent from the reconciliation list: ${rs_missing3[*]}"
    fi
fi

# Control: RS02/RS03/RS05 must fail for a rule the surfaces genuinely do not name.
if grep -qF 'SUMMARY-98' "$VALSTATE_F" || grep -qF 'SUMMARY-98' "$FIXSTATE_F"; then
    no RS04 "SUMMARY-98 unexpectedly present; the control is void"
else
    ok RS04 "the surface check rejects a rule no surface names (control: SUMMARY-98)"
fi

echo
echo "== distinct findings keep distinct join keys =="
# Reconciliation joins on (Doc, Rule) with Line as its only tiebreaker. Two rules emit N rows for one
# (Doc, Rule) -- PRE-11 (one per token pair) and PRE-04 (A2 and A3 share it) -- so both depend on emit()
# passing a Line. Deleting that one parameter collapses them, fixing one pair silently clears the others,
# and the loop stops converging. Both suites stayed green under exactly that mutation, so assert the
# BEHAVIOUR: run the emitter and require the keys to be distinct.
JK="$(mktemp -d)"
mkdir -p "$JK/.aid/knowledge"
printf 'knowledge:\n  doc_set:\n    - a.md | o | required\n' > "$JK/.aid/settings.yml"
printf '# a\n' > "$JK/.aid/knowledge/a.md"
# Tokens that resolve but fail contrast in BOTH themes -> several PRE-11 rows; no lightbox -> A2 and A3.
{
  printf '%s\n' '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>a</title>'
  printf '%s\n' '<style>:root{--text:#eee;--bg:#fff;--text-muted:#f4f4f4;--accent:#fafafa;--border:#fdfdfd;--card:#fff;--code-bg:#fff;--link:#f5f5f5}</style></head>'
  printf '%s\n' '<body><main>a.md</main></body></html>'
} > "$JK/.aid/knowledge/kb.html"
mapfile -t jk_rows < <(cd "$JK" && bash "$EMIT" .aid/knowledge/kb.html --dry-run 2>/dev/null | grep -E '^\[')
rm -rf "$JK"
# Build the join key each row would reconcile on: Rule + Doc + Line (fields 2,3,4 of the dry-run shape).
mapfile -t jk_keys < <(printf '%s\n' "${jk_rows[@]}" | awk -F' [|] ' 'NF>=4 {print $2 "\t" $3 "\t" $4}')
n_rows="${#jk_keys[@]}"
n_uniq=$(printf '%s\n' "${jk_keys[@]}" | sort -u | wc -l)
if [[ "$n_rows" -lt 4 ]]; then
    no JK01 "fixture produced only ${n_rows} rows -- too few to test key distinctness"
elif [[ "$n_rows" -eq "$n_uniq" ]]; then
    ok JK01 "all ${n_rows} emitted rows carry a distinct (Rule, Doc, Line) join key"
else
    no JK01 "${n_rows} rows collapse to ${n_uniq} join keys -- reconciliation would clear findings it never fixed"
fi

echo
echo "== no assertion pattern contains a stray control byte =="
# This class bit twice in one delivery, in two different files. A word-boundary escape written through
# any layer that interprets backslashes lands as a literal 0x08 BACKSPACE, the pattern then matches
# nothing, and the assertion passes unconditionally -- silently, because a grep that finds nothing looks
# exactly like a grep that found nothing wrong. Both instances were guards for a gate criterion.
#
# The sweep is over the files this delivery owns; it is cheap, and it is the only check that can see the
# difference between "asserted and clean" and "asserted nothing".
CB_FILES=(
  "$ROOT/tests/canonical/test-one-grading-backend.sh"
  "$ROOT/tests/canonical/test-grade-summary.sh"
  "$ROOT/tests/canonical/test-guardrails-d012.sh"
  # The derived-value guard and its registry. Added after the class bit a FOURTH time: a `\b`
  # written through a heredoc became a literal 0x08 inside a regex, so `/^\s*\|.*<BS>Supersede/`
  # could never match and a history rule silently did nothing. It cost an hour to find, because
  # `regex.source` PRINTS the backspace invisibly -- the pattern looks correct in every diagnostic.
  # A byte sweep is the only oracle that sees it.
  "$ROOT/tests/canonical/check-derived-values.mjs"
  "$ROOT/tests/canonical/derived-values.mjs"
  "$EMIT" "$MC"
)
cb_bad=()
for f in "${CB_FILES[@]}"; do
    [[ -f "$f" ]] || continue
    if LC_ALL=C grep -qP '[\x00-\x08\x0b\x0c\x0e-\x1f]' "$f" 2>/dev/null; then
        cb_bad+=("$(basename "$f")")
    fi
done
if [[ "${#cb_bad[@]}" -eq 0 ]]; then
    ok CB01 "no control byte in any of the ${#CB_FILES[@]} swept files"
else
    no CB01 "control byte(s) found in: ${cb_bad[*]} -- an escape was written through a layer that ate it"
fi

# CB03 -- the sibling of the control-byte class, and it bit once too: a line continuation written as the
# two characters backslash + 'n' instead of backslash + NEWLINE. Bash then reads a bare word `n` as an
# extra loop item, and in the emitter that aborted the run on an unmapped associative-array key under
# `set -u` -- an incomplete run reporting the exit code of a complete one. CB01 cannot see it: the bytes
# are 0x5C 0x6E, both printable.
# CODE lines only. A comment that DISCUSSES the escape -- as the ones above and below this do -- cannot
# be a broken line continuation, and flagging it made the guard fire on its own documentation. The bug
# this catches was `for k in A B \n "C"` in executable code, so comments are stripped before the scan.
cb2_bad=()
for f in "${CB_FILES[@]}"; do
    [[ -f "$f" ]] || continue
    hit=$(grep -nE '(^|[^"'"'"'\\])\\n[[:space:]]' "$f" 2>/dev/null \
          | grep -vE '^[0-9]+:[[:space:]]*#' \
          | grep -v 'printf' | head -1)
    [[ -n "$hit" ]] && cb2_bad+=("$(basename "$f"): $(printf '%s' "$hit" | cut -c1-60)")
done
if [[ "${#cb2_bad[@]}" -eq 0 ]]; then
    ok CB03 "no literal backslash-n stands where a line continuation was meant"
else
    no CB03 "literal backslash-n outside a quoted string: ${cb2_bad[*]}"
fi

# Control: the detector must see a planted byte, or CB01 is itself the vacuous assertion it guards against.
CBCTL="$(mktemp)"
printf 'grep -qE %s60%s foo\n' "'"$'\x08' $'\x08'"'" > "$CBCTL"
if LC_ALL=C grep -qP '[\x00-\x08\x0b\x0c\x0e-\x1f]' "$CBCTL" 2>/dev/null; then
    ok CB02 "the detector DOES see a planted 0x08 byte (control)"
else
    no CB02 "the detector cannot see a planted control byte"
fi
rm -f "$CBCTL"

echo
printf 'test-one-grading-backend.sh: %d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
