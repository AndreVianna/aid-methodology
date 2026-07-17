# REVIEW — Re-review Existing Tasks

Existing task files found; re-review against current PLAN.md and SPECs.

Load `references/task-decomposition.md` for task type rules, file format, and quality criteria.

---

## REVIEW (re-run on existing tasks)

`tasks/` has files and were previously completed.

**Ask first:** _"Tasks for this work are already complete. Do you want to reopen for review?
Is there something specific you want to re-examine?"_

If user confirms → continue below.
If user has a specific concern → record it as context for the review.

Enter **the same loop at step 4** — review tasks against
current PLAN.md and SPECs.

### Load Current State

Re-read PLAN.md, all feature SPECs, all existing task files.

### Review Each Deliverable's Tasks

For each deliverable, check its corresponding tasks:

1. **PLAN.md changed** — deliverables added, removed, resequenced?
2. **SPECs changed** — feature content updated since tasks were written?
3. **Orphan tasks** — tasks referencing deliverables/features that no longer exist?
4. **Missing tasks** — new deliverables/features with no corresponding tasks?
5. **Sequence broken** — task order invalid given changes?

### Dispatch the Reviewer

Render `references/reviewer-brief.md` with:
- `{{SCOPE}}` = `whole-list`
- `{{ARTIFACTS}}` = every `.aid/works/{work}/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` (all deliveries) + the full `PLAN.md` (incl. Execution Graphs)
- `{{CONTEXT}}` = `Re-review of all tasks for work-NNN after PLAN/SPEC changes.`

Include in the prompt:
- **Ledger lifecycle:** "Read `.aid/.temp/review-pending/detail.md` if it exists.
  For each existing row: verify on disk, update Status (Pending→Fixed if resolved;
  Fixed→Recurred if regressed). Append new findings with Status: Pending.
  Output per `.codex/aid/templates/reviewer-ledger-schema.md` — ONE table, no narrative."

Dispatch the `aid-reviewer` subagent **at Large tier** (the executor is the Large
`aid-architect`; reviewer tier >= executor tier per
`.codex/aid/templates/agent-dispatch-tiering.md`) with the rendered brief.

### Grade Overall

After aid-reviewer returns, run grade.sh:

```bash
bash .codex/aid/scripts/grade.sh --explain .aid/.temp/review-pending/detail.md
```

Compare to minimum grade from `bash .codex/aid/scripts/config/read-setting.sh --skill detail --key minimum_grade --default A`.

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Print summary, done. Delete ledger: `rm -f .aid/.temp/review-pending/detail.md` |
| Grade < minimum, tasks fixable | List findings, re-enter loop for affected deliverables. |
| Grade < minimum, most tasks orphaned | Recommend `--reset`. |

For grades below minimum: re-enter the loop for affected deliverables.
Update task files, create new ones, delete orphans, renumber if needed.

[State: REVIEW] complete.

**Advance:** **CHAIN** → [State: DONE] (continue inline).
