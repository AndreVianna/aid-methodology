# State: REVIEW

PLAN.md exists and was previously completed; re-review deliverables against the current feature sections and KB.

## REVIEW (re-run on existing PLAN.md)

Enter **the same loop at step 4** — review each deliverable
against current reality. Any concern the user gave at CONFIRM is context for this review.

### Load Current State

Re-read REQUIREMENTS.md (its § 11 feature sections included) and the KB docs (same as first run).

### Review Each Deliverable

For each deliverable in PLAN.md, run step 4:

1. **New features** not assigned to any deliverable?
2. **Removed features** still referenced in PLAN.md?
3. **Changed feature sections** since PLAN.md was written?
4. **Priority shifts** in REQUIREMENTS.md?
5. **Dependency changes** from SPEC updates?
6. **Cross-cutting risks** emerged or resolved?

### Dispatch the Reviewer

Render `references/reviewer-brief.md` with:
- `{{SCOPE}}` = `whole-plan`
- `{{ARTIFACTS}}` = full `PLAN.md` + the `### Feature NNN` sections of
  `.aid/works/{work}/REQUIREMENTS.md § 11`
- `{{CONTEXT}}` = `PLAN.md for work-NNN with N deliveries; re-review against the current feature sections.`

Include in the brief file (not in the dispatch prompt — `reviewer-dispatch.md` § Dispatch by path):
- **Ledger lifecycle:** "Read `{{LEDGER}}` if it exists.
  For each existing row: verify on disk, update Status (Pending→Fixed if resolved;
  Fixed→Recurred if regressed). Append new findings with Status: Pending.
  Output per `.aid/runtime/templates/reviewer-ledger-schema.md` — ONE table, no narrative."

Dispatch the `aid-reviewer` subagent **at Large tier** (the executor is the Large
`aid-architect`; reviewer tier >= executor tier per
`.aid/runtime/templates/agent-dispatch-tiering.md`) with a pointer to the rendered brief file
(`reviewer-dispatch.md` § Dispatch by path).

### Grade Overall

After aid-reviewer returns, run grade.sh:

```bash
bash .aid/runtime/scripts/grade.sh --explain {{LEDGER}}
```

Compare to minimum grade from `bash .aid/runtime/scripts/config/read-setting.sh --skill plan --key minimum_grade --default A`.

| Condition | Action |
|-----------|--------|
| Grade >= minimum | Ensure `deliveries/delivery-NNN/STATE.yml` exists for each delivery in PLAN.md; create any missing ones, seeding the top-level `delivery_state` scalar as `Pending-Spec` -- task-001/004. Delete ledger: `rm -f {{LEDGER}}`. Print summary, done. |
| Grade < minimum, deliverables fixable | List findings, re-enter loop for affected deliverables. |
| Grade < minimum, sequence invalidated | Recommend `--reset`. |

For grades below minimum: re-enter the loop for affected deliverables.

> NOTE: Do NOT write delivery rows into the work STATE.yml's Plan/Deliveries view. That view
> is a DERIVED read-only view assembled at read time from `deliveries/delivery-NNN/STATE.yml` files.

**Cycle 1 also runs the cross-document contradiction pass (Guard 2).** This review receives
every artifact of the phase at once, which is the only vantage point from which a
contradiction between two of them is visible. Run it on cycle 1 only -- that makes it
once per phase by construction. Definition:
`reviewer-dispatch.md` section "The cross-document contradiction pass (Guard 2)".

When the sequence is invalidated, the run ends here with the work paused: set the lifecycle to
`Paused-Awaiting-Input` and the pause reason to "Plan sequence invalidated; run `/aid-plan --reset`" through the
writer (`--pipeline --field Lifecycle`, then `--pipeline --field "Pause Reason"`) before it ends.

**Advance:** **CHAIN** → [State: DONE] when the grade meets minimum and all delivery folders are created; **CHAIN** → [State: FIRST-RUN] when the grade is below minimum and the deliverables are fixable; **HALT** when the sequence is invalidated (recommend `--reset`).
