# State: REVIEW

PLAN.md exists and was previously completed; re-review deliverables against current SPECs and KB.

## REVIEW (re-run on existing PLAN.md)

PLAN.md exists and was previously completed.

**Ask first:** _"This plan is already complete. Do you want to reopen it for review?
Is there something specific you want to re-examine?"_

If user confirms → continue below.
If user has a specific concern → record it as context for the review.

Enter **the same loop at step 4** — review each deliverable
against current reality.

### Load Current State

Re-read all feature SPECs, REQUIREMENTS.md, KB docs (same as first run).

### Review Each Deliverable

For each deliverable in PLAN.md, run step 4:

1. **New features** not assigned to any deliverable?
2. **Removed features** still referenced in PLAN.md?
3. **Changed SPECs** since PLAN.md was written?
4. **Priority shifts** in REQUIREMENTS.md?
5. **Dependency changes** from SPEC updates?
6. **Cross-cutting risks** emerged or resolved?

### Dispatch the Reviewer

Render `references/reviewer-brief.md` with:
- `{{SCOPE}}` = `whole-plan`
- `{{ARTIFACTS}}` = full `PLAN.md` + every `.aid/{work}/features/feature-*/SPEC.md`
- `{{CONTEXT}}` = `PLAN.md for work-NNN with N deliveries; re-review against current SPECs.`

Dispatch the `reviewer` subagent with the rendered brief.

### Grade Overall

Use the universal rubric (`canonical/templates/grading-rubric.md`). Classify each issue
by severity. The grade is calculated — worst issue dominates.

Compare to minimum grade from `bash canonical/scripts/config/read-setting.sh --skill plan --key minimum_grade --default A`.

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Print summary, done. Update work STATE.md `## Plan / Deliveries`. |
| Grade < minimum, deliverables fixable | List findings, re-enter loop for affected deliverables. |
| Grade < minimum, sequence invalidated | Recommend `--reset`. |

For grades below minimum: re-enter the loop for affected deliverables.

**Advance:** Next state is `DONE` — when the grade meets minimum and work STATE.md is updated, router prints `Next: [State: DONE] — run /aid-plan again` and exits.
