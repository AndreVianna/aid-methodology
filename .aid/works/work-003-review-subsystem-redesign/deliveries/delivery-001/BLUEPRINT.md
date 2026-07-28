# Delivery BLUEPRINT -- delivery-001: Baseline and fix-first

> **Delivery:** delivery-001
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-07-28

---

## Objective

Capture the measurement baselines that become unrecoverable the moment editing starts, and clear
three prerequisite defects. Scoped as a distinct unit because AC-13 is a MUST about cost whose
instrument does not yet exist -- once any later delivery edits the review path, the pre-migration
numbers can no longer be observed.

## Scope

- AC-11's two baselines: `B` (the shared review-asset line budget) and the nine-row `C` table
  (per-caller review-mechanics lines), captured by the fixed pattern the feature-006 SPEC declares.
- AC-13's baseline: one fixture artifact taken through a full gate passage, recording total dispatch
  count, per-dispatch agent and tier, and FIX-cycle count from the `## Dispatch Log` telemetry.
- Reconcile `canonical/agents/aid-reviewer/AGENT.md` to its committed base (`git checkout --`); the
  main tree carries an uncommitted markdown-formatter run that introduced a stray word.
- Correct the five rendered emission manifests, which reference `canonical/scripts/grade.sh` -- a
  path that does not exist.

**Out of scope:** any change to review behaviour, and the WSL worktree gitdir defect (leaves this
work per concern N4).

## Gate Criteria

- [ ] `B` and the nine-row `C` table are recorded in the delivery, each with the command that
      produced it
- [ ] The AC-13 fixture gate passage is recorded: dispatch count, per-dispatch tier, FIX cycles
- [ ] `git diff canonical/agents/aid-reviewer/AGENT.md` is empty in the main tree
- [ ] No emission manifest references a path that does not exist on disk
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
