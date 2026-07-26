# State: DONE

DONE confirms discovery is complete and user-approved; it is selected when the KB meets minimum grade and `**User Approved:** yes` is present in STATE.md.

Print: _"Discovery is complete and approved (Grade: {grade}). Do you want to reopen it for review?"_

- User confirms → set state to REVIEW
- User has specific concern → record as context for reviewer
- User says no → `✅ Discovery complete. Grade: {grade}. Minimum: {minimum}. KB approved and ready for the Interview phase.`

### Ledger cleanup

Delete the review ledger:
```bash
rm -f .aid/.temp/review-pending/discovery.md
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

Print: `[State: DONE] complete.`

**Advance:** **HALT**.
