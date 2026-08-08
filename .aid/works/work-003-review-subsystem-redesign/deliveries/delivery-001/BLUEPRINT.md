# Delivery BLUEPRINT -- delivery-001: Baseline and fix-first

> **Delivery:** delivery-001
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Capture the measurement baselines that become unrecoverable the moment editing starts, and clear
three prerequisite defects. Scoped as a distinct unit because AC-13 is a SHOULD about cost whose
instrument does not yet exist -- once any later delivery edits the review path, the pre-migration
numbers can no longer be observed.

## Scope

- AC-11's two baselines: `B` (the shared review-asset line budget) and the nine-row `C` table
  (per-caller review-mechanics lines), captured by the fixed pattern the feature-006 SPEC declares.
- AC-13's baseline: one fixture artifact taken through a full gate passage, recording total
  dispatch count and FIX-cycle count. ~~per-dispatch agent and tier~~ **Amended at execution** -- the per-dispatch tier is dropped: the `## Dispatch Log` telemetry AC-13 was written against is never actually written (49 dispatches, zero rows), so tier was unrecoverable and its weighting was never defined. Populating that log is now a prerequisite of AC-13, not an input to it. See REQUIREMENTS.md AC-13 and BASELINE-ac13.md.
- Reconcile `canonical/agents/aid-reviewer/AGENT.md` to its committed base (`git checkout --`); the
  main tree carries an uncommitted markdown-formatter run that introduced a stray word.
- ~~Correct the five rendered emission manifests~~ **CUT at execution.** The claim was a
  misreading: `render.py` deliberately normalizes `canonical/aid/<sub>/` to `canonical/<sub>/`
  in the manifest `src` field "for manifest src stability". The field is a stable logical
  identifier, not a filesystem path, and is correct as generated.

**Out of scope:** any change to review behaviour, and the WSL worktree gitdir defect (leaves this
work per concern N4).

## Gate Criteria

- [ ] `B` and the nine-row `C` table are recorded in the delivery, each with the command that
      produced it
- [ ] The AC-13 fixture gate passage is recorded: dispatch count and FIX cycles
      (~~per-dispatch tier~~ -- dropped; see Scope)
- [ ] `git diff canonical/agents/aid-reviewer/AGENT.md` is empty in the main tree
- [ ] _(cut -- see Scope. The manifest `src` normalization is intentional generator behaviour.)_
- [ ] All section-6 quality gates pass

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** delivery-003, delivery-010

## Notes

**Enabling, not standalone-functional** -- it ships no user-visible capability. It is first and is a
hard gate: nothing else begins until the baselines are recorded, because they cannot be recovered
retrospectively.
## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | CONFIGURE | 1 | Base reconciliation and emission manifests |
| task-002 | RESEARCH | 1 | AC-11 baseline |
| task-003 | RESEARCH | 2 | AC-13 cost baseline |
