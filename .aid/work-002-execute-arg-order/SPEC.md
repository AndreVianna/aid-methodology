# aid-execute argument order — Refactor

- **Work:** work-002-execute-arg-order
- **Created:** 2026-06-09
- **Source:** /aid-interview lite path — LITE-REFACTOR
- **Status:** Ready

## Goal

`aid-execute` is the only AID skill whose invocation puts the task before the work
(`/aid-execute task-001 [work-001]`); every sibling skill (aid-detail, aid-plan,
aid-specify, aid-interview) leads with the work. This refactor makes aid-execute
consistent — it leads with the work: `/aid-execute work-001 task-001` — updating the
argument-hint, the Check 1 locate logic, all example invocations, and every
cross-reference, then re-rendering the install trees. No runtime behavior changes
beyond argument parsing.

## Context

**Scope:**

- `canonical/skills/aid-execute/SKILL.md` — `argument-hint` (line 9), the
  "Check 1: Locate Work and Task" parsing steps, and the example invocations
  (lines ~183–188).
- `canonical/skills/aid-execute/README.md` (lines ~44–45) — the `/aid-execute task-003 work-001` examples.
- `canonical/skills/aid-execute/references/state-execute.md` (lines ~44, ~380) and
  `references/state-re-run.md` (line ~7) — these use the single-work **shorthand**
  `/aid-execute task-NNN`, which AC3 intentionally preserves; leave the shorthand
  form as-is (it demonstrates the kept shorthand), but ensure any two-arg example
  uses work-first order.
- `canonical/skills/aid-interview/references/state-lite-done.md` (lines ~61, ~95) —
  the LITE-DONE hand-off command (cross-skill reference); AND line ~85, the prose
  "The `{work-NNN-name}` work id is **appended** to the `/aid-execute` command…" —
  reword, since after the refactor the work id **leads** the command, it is no
  longer appended.
- `canonical/templates/reviewer-ledger-schema.md` (line ~49) — `/aid-execute task-NNN` reference.
- Re-render all 5 install trees via the FULL generator.

**Out of scope / no change:** the execute helper scripts
(`complexity-score.sh`, `compute-block-radius.sh`, `writeback-state.sh`) — their
`$2` usages parse named flags (`--task-id`, `--tasks-dir`), not positional skill
arguments, so they are unaffected.

**Before:** `/aid-execute task-001 [work-001]` — task-first, work optional second.
Inconsistent with every sibling skill, which leads with the work.

**After:** `/aid-execute work-001 task-001` — work-first, two positional args, mirroring
aid-detail / aid-plan. Backward-compatible single-work shorthand `/aid-execute task-001`
still resolves by `work-`/`task-` prefix detection when only one work exists.

**KB references:** `architecture.md` (phase-to-skill mapping, canonical→5-tree render
pipeline); the sibling argument-hints in `canonical/skills/aid-{detail,plan,specify,interview}/SKILL.md`
are the consistency target.

## Acceptance Criteria

- [ ] Given the aid-execute SKILL.md, the `argument-hint` leads with the work (`work-001` before `task-001`), consistent with aid-detail / aid-plan / aid-specify / aid-interview.
- [ ] Given "Check 1: Locate Work and Task", the parsing leads with the work argument and still auto-selects the work when only one exists.
- [ ] Given the single-work shorthand `/aid-execute task-001`, it still resolves correctly (backward-compatible; no breakage for single-work users).
- [ ] Given every canonical example invocation and cross-reference (aid-execute SKILL.md / README / state-execute / state-re-run, aid-interview state-lite-done, reviewer-ledger-schema), they all show the work-first order.
- [ ] Given the FULL generator runs, `/aid-execute` is byte-identical across all 5 install trees and the render-drift, canonical-tests, generator-selftests, and kb-hygiene CI gates pass.
- [ ] All existing tests pass (no behavior regression).

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | aid-execute arg-order refactor |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-06-09 | Initial lite-path SPEC created | /aid-interview LITE-REFACTOR |
