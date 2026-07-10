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

Include in the prompt:
- **Ledger lifecycle:** "Read `.aid/.temp/review-pending/plan.md` if it exists.
  For each existing row: verify on disk, update Status (Pending→Fixed if resolved;
  Fixed→Recurred if regressed). Append new findings with Status: Pending.
  Output per `.claude/aid/templates/reviewer-ledger-schema.md` — ONE table, no narrative."

Dispatch the `aid-reviewer` subagent with the rendered brief.

### Grade Overall

After aid-reviewer returns, run grade.sh:

```bash
bash .claude/aid/scripts/grade.sh --explain .aid/.temp/review-pending/plan.md
```

Compare to minimum grade from `bash .claude/aid/scripts/config/read-setting.sh --skill plan --key minimum_grade --default A`.

| Condition | Action |
|-----------|--------|
| Grade >= minimum | Ensure all delivery folders exist (deliveries/delivery-NNN/BLUEPRINT.md + STATE.md for each delivery in PLAN.md; create any missing ones with State: Pending-Spec). Delete ledger: `rm -f .aid/.temp/review-pending/plan.md`. Print summary, done. |
| Grade < minimum, deliverables fixable | List findings, re-enter loop for affected deliverables. |
| Grade < minimum, sequence invalidated | Recommend `--reset`. |

For grades below minimum: re-enter the loop for affected deliverables.

> NOTE: Do NOT write delivery rows into the work STATE.md `## Plan / Deliveries`. That section
> is a DERIVED read-only view assembled at read time from `deliveries/delivery-NNN/STATE.md` files.

**Advance:** **CHAIN** -> [State: DONE] when the grade meets minimum and all delivery folders are created (continue inline).
