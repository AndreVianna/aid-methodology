# State: DONE

DONE confirms discovery is complete and user-approved; it is selected when the KB meets minimum grade and `**User Approved:** yes` is present in STATE.md.

Tell the user, in one plain line, that discovery is complete and approved (Grade: {grade}). Then ask one
question, in the protocol's form, recorded first as the SKILL's recording paragraph says:

```text
Knowledge base -- question 1 of 1 -- importance: low
Do you want to reopen the discovery for another review?
Why I ask: the knowledge base is already approved, so nothing more runs unless you ask for it.
My recommendation: leave it as it is -- it is approved and meets the minimum grade.
  1. Leave it as it is (recommended)
  2. Reopen it for review
Or answer in your own words (for example, a concern for the reviewer), ask me to explain, or skip this question.
```

The question is blocking: this step pauses on it until the user answers.

- User reopens it → end this step at once with the first case of the advance line below (REVIEW); nothing below this list runs
- User has specific concern → record as context for reviewer
- User leaves it as it is (or skips) → carry on with the rest of this step, which ends with the second case of the advance line below. Print `✅ Discovery complete. Grade: {grade}. Minimum: {minimum}. KB approved and ready for the Definition phase.`

### Ledger cleanup

Delete the review ledger:
```bash
rm -f {{LEDGER}}
rmdir --ignore-fail-on-non-empty .aid/.temp/review-pending/ 2>/dev/null || true
```

### Record KB baseline (FR35 - NEW, before HALT)

Resolve the default branch using the DD-A2 detection order:
1. Prefer the branch already stored in `.aid/settings.yml` `kb_baseline.branch` (if present and non-empty).
2. Else resolve `origin/HEAD`: run `git symbolic-ref --short refs/remotes/origin/HEAD` and take the basename (e.g. `origin/master` -> `master`).
3. Else use the first of `{main, master}` that exists as a local branch (`git branch --list <name>`).

Once the branch name is known, read its tip commit date:
```bash
git log -1 --format=%cI <branch>
```

Write `.aid/settings.yml` `kb_baseline: {branch, tip_date}` using the **append-a-new-block** idiom
(`/aid-config` SKILL.md:126-132 -- the not-yet-present-section path). This is the **first** write of
the multi-line `kb_baseline` block; use a same-directory temp file + `mv -f` crash-safe rename (NOT
the single-line "Save in place" replace, which only replaces one line):
```bash
# Append the kb_baseline block to a temp copy, then rename atomically
cp .aid/settings.yml .aid/settings.yml.tmp
cat >> .aid/settings.yml.tmp << 'EOF'

kb_baseline:
  branch: <resolved-branch>
  tip_date: <ISO-8601-tip-date>
EOF
mv -f .aid/settings.yml.tmp .aid/settings.yml
```
If `kb_baseline` is already present (re-run after an earlier DONE), skip the append and instead
replace only the `tip_date:` line in the existing block (the single-line "Save in place" idiom,
`/aid-config` SKILL.md:124).

If git is absent, the repo has no commits, or the branch cannot be resolved, skip the baseline
write silently (the reader degrades gracefully when `kb_baseline` is absent -- FF-A2).

### Auto-trigger aid-summarize (FR34 - NEW deliberate closing behavior, not C4-preserving)

This replaces the former "Optional: run /aid-summarize" suggestion. Invoke `/aid-summarize` now,
running its **full state machine** (PREFLIGHT -> STALE-CHECK -> ... -> APPROVAL(V1) -> WRITEBACK ->
DONE), which runs its own human visual-approval gate (V1) and produces `kb.html`.

**This auto-trigger is async by design.** Discovery is DONE at KB approval (above) and does NOT
block on the summary. If the user defers or fails summarize's V1 gate, the KB card sits at
`preparing` (never `generating` -- discovery is complete). The derivation self-corrects on the next
poll when V1 lands (FF-A3).

**Both approval gates still fire** (R11):
1. Discovery's own KB approval gate (already passed -- this state is only reached after it).
2. aid-summarize's V1 visual-approval gate (fires now, inside the invoked summarize run).

Neither gate is replaced by this auto-trigger; the trigger composes them.

**Advance:** **CHAIN** → [State: REVIEW] when the user confirms the reopen; **HALT** when the user keeps the discovery as it is.
