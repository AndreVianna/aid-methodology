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
# A raw control byte anywhere in the file means it is not JSON, whatever the field looks like.
if LC_ALL=C grep -qP '[\x00-\x08\x0a-\x1f]' <(tr -d '\n' < "$MCT/ml.json"); then
    no MC09 "the written JSON contains a raw control character"
else
    ok MC09 "no raw control character survives into the JSON"
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

echo
echo "== the two-grade model appears on no surface =="
# The pattern IS the assertion. A narrower one (Machine Grade|Human Grade|Overall Grade|AUTO_POOL|
# MANUAL_POOL) reported zero while aid-summarize's own frontmatter description still read "Two-grade
# quality gate (Machine + Human) ... APPROVAL requires BOTH grades >= minimum" -- the surface the skill
# catalogue renders. Every phrasing that ever carried the model is listed here. Extend it; never trim it.
TG_PAT='Machine Grade|Human Grade|Overall Grade|Machine total|Human total|AUTO_POOL|MANUAL_POOL'
TG_PAT="$TG_PAT"'|MACHINE_GRADE|HUMAN_GRADE|OVERALL_GRADE|Pending Human Review|machine-pool|human-pool'
TG_PAT="$TG_PAT"'|both Machine and Human|BOTH grades|Machine [+] Human|min[(]Machine|Machine_letter'
TG_PAT="$TG_PAT"'|Human_letter|[Tt]wo-[Gg]rade|two grades|percentage ladder'

# Passages that EXPLAIN the retirement are legitimate and must survive -- deleting them would leave the
# next reader no account of why the model went. They are excluded BY FILE, and the list is deliberately
# short: a growing exclusion list is how an assertion quietly stops asserting.
TG_EXPLAINERS='knowledge-summary/grading-rubric.md|aid-summarize/README.md|aid-summarize/SKILL.md'
TG_EXPLAINERS="$TG_EXPLAINERS"'|summarize/emit-summary-findings.sh|review-rubrics/summary.md'

mapfile -t tg_hits < <(grep -rlE "$TG_PAT" "$ROOT/canonical/" 2>/dev/null \
                       | grep -vE "$TG_EXPLAINERS" | sort -u)
chk "${#tg_hits[@]}" 0 TG01 "no canonical surface carries the two-grade vocabulary"
[[ "${#tg_hits[@]}" -eq 0 ]] || printf '       %s\n' "${tg_hits[@]}"

# In an explainer file the vocabulary may appear ONLY in retirement prose, never as a live instruction.
# The frontmatter description is the sharpest case: it is metadata, so it cannot be explaining anything.
fm=$(awk '/^---$/{n++; next} n==1' "$ROOT/canonical/skills/aid-summarize/SKILL.md" \
     | grep -cE "$TG_PAT" || true)
chk "${fm:-1}" 0 TG02 "aid-summarize's frontmatter description carries no two-grade vocabulary"

# Control: TG01 must be able to see a planted surface, or zero hits means nothing.
TGCTL="$(mktemp -d)"; mkdir -p "$TGCTL/skills/planted"
printf 'APPROVAL requires BOTH grades >= minimum.\n' > "$TGCTL/skills/planted/SKILL.md"
n_tgctl=$(grep -rlE "$TG_PAT" "$TGCTL" 2>/dev/null | grep -vE "$TG_EXPLAINERS" | wc -l)
rm -rf "$TGCTL"
chk "$n_tgctl" 1 TG03 "TG01 DOES find a planted two-grade surface (control)"

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
catalog_sev() {
    local rule="$1"
    grep -rhE "^\| \`${rule}\` " "$RUBRIC_DIR" 2>/dev/null | head -1 \
        | awk -F'|' '{print $(NF-1)}' | grep -oE '\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]' | head -1
}

# SEV01 sweeps the SAME eight files RID01 does, and every rule CLASS, not just SUMMARY/PRE in one file.
# Scoped to one file and two classes it reported clean while five live drifts sat in the sibling
# reviewer prompts -- an assertion narrower than the defect it is named for.
sev_bad=0
for f in "${CITERS[@]}"; do
    [[ -f "$f" ]] || continue
    while IFS= read -r line; do
        # Backticked OR bare. Requiring backticks meant this loop examined ZERO rows in all four
        # reviewer-prompt files -- their rule IDs sit in ledger EXAMPLE rows, which are bare by
        # construction -- and five live drifts sat inside the declared scope while it reported clean.
        rule=$(printf '%s' "$line" | grep -oE '[A-Z]{2,12}-[0-9]{2}' | head -1 | tr -d '`')
        [[ -n "$rule" ]] || continue
        stated=$(printf '%s' "$line" | grep -oE '\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]' | head -1)
        [[ -n "$stated" ]] || continue
        declared=$(catalog_sev "$rule")
        [[ -n "$declared" ]] || continue      # `Step 2` rules: nothing fixed to compare against
        if [[ "$stated" != "$declared" ]]; then
            no "SEV-$(basename "$f"):${rule}" "says ${stated}, catalog declares ${declared}"
            sev_bad=1
        fi
    done < <(sev_rows "$f")
done
[[ "$sev_bad" -eq 0 ]] && ok SEV01 "no surface restates a severity that disagrees with the rule it cites"

# SEV01 can only report clean if it actually looked. Count the rows it examined across all eight files;
# zero would mean the pattern is broken again, which is exactly how it passed while five drifts stood.
n_sev_rows=0
for f in "${CITERS[@]}"; do
    [[ -f "$f" ]] || continue
    n_sev_rows=$((n_sev_rows + $(sev_rows "$f" | wc -l)))
done
if [[ "$n_sev_rows" -ge 10 ]]; then
    ok SEV03 "SEV01 examined ${n_sev_rows} severity-bearing rows via the shared feed (not vacuous)"
else
    no SEV03 "SEV01 examined only ${n_sev_rows} rows -- its feed is broken"
fi

# Control: catalog_sev must actually read the catalog, else SEV01 passes on an empty comparison.
[[ "$(catalog_sev SUMMARY-08)" == "[LOW]" ]] \
    && ok SEV02 "the catalog reader resolves a known severity (control: SUMMARY-08 = [LOW])" \
    || no SEV02 "the catalog reader returned '$(catalog_sev SUMMARY-08)' for SUMMARY-08, expected [LOW]"

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
cb2_bad=()
for f in "${CB_FILES[@]}"; do
    [[ -f "$f" ]] || continue
    # A backslash-n inside a shell word, outside a quoted string, is never intentional in these files.
    if grep -nE '(^|[^"'"'"'\\])\\n[[:space:]]' "$f" 2>/dev/null | grep -qv 'printf'; then
        cb2_bad+=("$(basename "$f"): $(grep -nE '(^|[^"'"'"'\\])\\n[[:space:]]' "$f" | grep -v printf | head -1 | cut -c1-60)")
    fi
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
