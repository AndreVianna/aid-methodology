# State: REVIEW

All sections complete; re-review entire spec against current KB and codebase.

The spec was completed previously (feature status `Ready` in work STATE.md `## Features Status`).

**Ask first:** _"This feature spec is marked Ready. Do you want to reopen it for review?
Is there something specific you want to re-examine?"_

If user confirms → set feature status to `In Discussion`, continue below.
If user has a specific concern → record it as context for the review.

Re-run enters **the same loop at step 4** —
reviewing all sections against current reality.

### Load Current Context

Same as INITIALIZE Step 1: SPEC.md, REQUIREMENTS.md, KB docs, codebase.

### Review All Sections

For each section in SPEC.md, run step 4 of the loop against current state:

1. **KB drift** — SPEC references KB content that changed?
2. **Requirements drift** — Requirements changed since spec was written?
3. **Codebase drift** — Code changed (renamed, refactored by another feature)?
4. **Missing sections** — New conditional sections should now be activated?
5. **Stale content** — Section contradicts what now exists?

### Grade Overall

Use the universal rubric (`../../templates/grading-rubric.md`). Classify each issue
by severity. The grade is calculated — worst issue dominates.

Compare to minimum grade from `.aid/knowledge/STATE.md` `**Minimum Grade:**`.

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Print summary, done. Set feature status to `Ready` in work STATE.md. |
| Grade < minimum, fixable sections | List findings, re-enter loop for affected sections. |
| Grade < minimum, core assumptions wrong | Recommend `--reset`. |

```
Reviewing {work}/{feature} against current KB and codebase...

Issues found: 1 Low (stale DB column ref), 3 Minor (naming) → **Grade: B+**
Minimum: B+. ✅ Meets minimum.
```

For grades below minimum: re-enter the loop (Propose → Discuss → Write → Review)
for affected sections. When all resolved, set status back to Ready.

**Advance:** Next state is `DONE` — when spec is Ready and meets minimum grade, router prints `Next: [State: DONE] — run /aid-specify again` and exits.
