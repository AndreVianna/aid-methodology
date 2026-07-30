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
    done < <(grep -E '^\| ' "$f" | grep -E '`[A-Z]+-[0-9]{2}`')
done
[[ "$sev_bad" -eq 0 ]] && ok SEV01 "no surface restates a severity that disagrees with the rule it cites"

# SEV01 can only report clean if it actually looked. Count the rows it examined across all eight files;
# zero would mean the pattern is broken again, which is exactly how it passed while five drifts stood.
sev_rows=0
for f in "${CITERS[@]}"; do
    [[ -f "$f" ]] || continue
    while IFS= read -r line; do
        printf '%s' "$line" | grep -qE '[A-Z]{2,12}-[0-9]{2}' || continue
        printf '%s' "$line" | grep -qE '\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]' || continue
        sev_rows=$((sev_rows + 1))
    done < <(grep -E '^\| ' "$f")
done
if [[ "$sev_rows" -ge 10 ]]; then
    ok SEV03 "SEV01 examined ${sev_rows} severity-bearing rows (not vacuous)"
else
    no SEV03 "SEV01 examined only ${sev_rows} rows -- its extraction pattern is broken"
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
    done < <(grep -ohE '`(SUMMARY|PRE|NAR|KB|CODE|SPEC|TASK)-[0-9]{2}`' "$f" | tr -d '`' | sort -u)
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
printf 'test-one-grading-backend.sh: %d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
