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

Invoke `/aid-deep-review`. It owns the dispatch, the clean context, the ledger, the gap gate, the grade
and the fix loop.

```yaml
scope:         plan
artifacts:     PLAN.md and every delivery BLUEPRINT.md
rule_set:      definition
depth:         deep
tier:          large            # the executor is the Large aid-architect
fix_agent:     aid-architect
```

`minimum_grade` resolves from `read-setting.sh --skill plan`; the two brief sections come from
`references/reviewer-brief.md`. It returns the grade.


| Condition | Action |
|-----------|--------|
| Grade >= minimum | Ensure all delivery folders exist (deliveries/delivery-NNN/BLUEPRINT.md + STATE.md for each delivery in PLAN.md; create any missing ones, seeding the frontmatter's `delivery_state` scalar as `Pending-Spec` -- task-001/004). Delete ledger: `rm -f .aid/.temp/review-pending/plan.md`. Print summary, done. |
| Grade < minimum, deliverables fixable | List findings, re-enter loop for affected deliverables. |
| Grade < minimum, sequence invalidated | Recommend `--reset`. |

For grades below minimum: re-enter the loop for affected deliverables.

> NOTE: Do NOT write delivery rows into the work STATE.md `## Plan / Deliveries`. That section
> is a DERIVED read-only view assembled at read time from `deliveries/delivery-NNN/STATE.md` files.

**Advance:** **CHAIN** -> [State: DONE] when the grade meets minimum and all delivery folders are created (continue inline).
