# task-014: Retarget every skill recipe, template and agent-context reference

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-014/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-002, task-007, task-012

**Scope:**
- Mechanical but wide (`SPEC.md § L-7`, FR-8): every canonical recipe that names a work-tree state
  file by path, copies a state template, or describes a retired markdown section.
- `canonical/aid/templates/shortcut-engine.md`: `§ INTAKE Step 4`'s `cp work-state-template` (now
  the `.yml` template), every `writeback-state.sh --pipeline` block, `§ PLAN Step 3`'s direct
  frontmatter edit, `§ DETAIL Step 3`'s `### Tasks lifecycle` row promotion (now a
  `tasks_lifecycle` entry), `§ DETAIL Step 4`'s `delivery_state` edit, and each "append to
  `## Lifecycle History`" instruction (now "append an entry to the `lifecycle_history` sequence").
  Task-012 edits this same file's `§ GATE` `OUT OF SCOPE` bullets -- do not revert them.
- `canonical/skills/aid-execute/` (SKILL.md + `references/state-execute.md`, `state-review.md`,
  `state-delivery-gate.md`, `state-fix.md`), and `canonical/skills/` for `aid-plan`, `aid-specify`,
  `aid-describe`, `aid-define`, `aid-detail`, `aid-deploy`, `aid-triage`, `aid-housekeep`,
  `aid-review` (including its own template `cp`), `aid-ask`, `aid-monitor`.
- Other canonical templates that name a state file or a retired section by name -- including the
  task/delivery plan templates and `task-detail-template.md`'s own note, whose "State lives in
  task-NNN/STATE.md" line must name the new filename.
- **Templates that RESOLVE AND READ a work state file, which the skill list above does not cover**
  (`SPEC.md § L-7`; these are routing logic written as prose, so a missed one silently mis-routes
  the pipeline rather than merely reading stale): `work-initiation-gate.md` -- it reads the chosen
  work's `STATE.md` frontmatter (`:131`), routes on its `phase` (`:141`), and scaffolds the file on
  the NEW-work branch (`:123`); `downstream-worktree-entry.md:119`; and
  `subagent-heartbeat-protocol.md:151` (the cooperative stop-poll's `lifecycle` re-read).
- **Templates that WRITE to a work state file or name a retired section**, same scope:
  `dispatch-protocol-checklist.md:34` and `long-wait-protocol.md:80` (`## Calibration Log` row
  appends), `delivery-issues.md:11`/`:34`/`:42` (`## Quick Check Findings`, `## Delivery Gates`),
  and `connectors/consumption-protocol.md:84-87`/`:135` (the `ticket_ref` resolution table naming
  the work/delivery/task `STATE.md` frontmatter at each level).
- The denominator for this task's sweep of the template tree:
  `grep -rl STATE.md canonical/aid/templates` returns **30** files. Every one is classified
  converted / not-converted with a one-line reason, so a skipped file is a recorded decision rather
  than an oversight. `rough-time-hints.md:55` is an example of a legitimate skip (a historical
  mention, not a resolution).
- The agent-context files `CLAUDE.md` and `AGENTS.md`, wherever a work-tree state file is named by
  path. The mandatory state-write protocol text is preserved verbatim in meaning -- only the target
  notation changes.
- The retired heading names (`## Lifecycle History`, `### Tasks lifecycle`, `## Tasks State`,
  `## Delivery Gate`, `## Quick Check Findings`) are replaced by their key names wherever a recipe
  instructs an agent to write or read them.
- **Must not change:** any reference to the out-of-scope `.aid/knowledge/STATE.md` discovery ledger
  (`aid-discover`, `aid-summarize`, `graph-preflight.sh`, `discover-preflight.sh`,
  `kb-write-fence.sh`, `kb-freshness-check.sh`, `stale-check.sh`, `complexity-score.sh` and
  `canonical/aid/scripts/summarize/writeback-state.sh`), and
  `canonical/aid/templates/discovery-state-template.md`. A blind find-and-replace hits these.
- **SP-15's search surface is no longer docs-and-renders-only, and this task's grep must reflect
  that.** SP-15 is now explicit that the surface includes every operational consumer under
  `dashboard/` -- `dashboard/scripts/` (the `delete-pipeline.sh` guard and the `writeback-state.sh`
  fork), `dashboard/server/` (`server.mjs`, `server.py`, `reader.mjs`) and `dashboard/home.html` --
  because a docs-and-renders-only search is exactly what let `SPEC.md § L-10` and `§ L-11` go
  unnoticed in the first draft: none of those files is a doc, a skill, a template or a render. The
  *edits* to that half stay with their owners -- task-006 (`delete-pipeline.sh`), task-007 (the
  `writeback-state.sh` fork), task-004 (`reader.mjs`) and task-020 (`server.mjs` / `server.py` /
  `home.html`). What this task owns is not treating a `canonical/`-only grep as a complete SP-15
  search: its residual-hit enumeration names the `dashboard/` half and the task covering each hit,
  so no consumer layer is left with no owner named. The final residual sweep that produces SP-15's
  evidence runs in task-019, over the widened surface.
- Canonical only (C-1); the five profile renders and the dogfood trees are regenerated in task-017.
- OUT of this task: KB docs (task-018); the review-exclusion rule itself (task-012); tests
  (task-015/016); every `dashboard/` edit (task-004/006/007/020, as above).

**Acceptance Criteria:**
- [ ] Every canonical skill, reference doc and template that named a work-tree state file now names
      `STATE.yml`, and every instruction that named a retired markdown section now names the
      corresponding YAML key (FR-8, SP-15).
- [ ] `grep -rn 'STATE\.md' canonical/` returns only out-of-scope discovery-ledger references and
      explicitly labelled legacy/migration references; each remaining hit is enumerated in the
      commit message with its reason (SP-15).
- [ ] The `dashboard/` half of SP-15's surface is accounted for rather than assumed absent: this
      task also runs `grep -rn 'STATE\.md' dashboard/scripts/ dashboard/server/ dashboard/home.html`
      and, for every hit, names either the owning task (task-004/006/007/020) or the reason it is
      out of scope (the `.aid/knowledge/STATE.md` discovery ledger via `join(kbDir, ...)` /
      `SKIP_NAMES`, or an explicitly labelled legacy reference). It edits none of them (SP-15,
      FR-4e, FR-7a).
- [ ] Every `cp`-a-template step names the `.yml` template that task-002 produced, and no recipe
      copies a filename that no longer exists.
- [ ] The mandatory state-write protocol text is unchanged in meaning everywhere it appears -- the
      per-transition mandate (`In Progress` / `In Review` / terminal) still binds whoever executes a
      task, main agent or sub-agent (`CLAUDE.md § Tracking discipline`).
- [ ] `CLAUDE.md` and `AGENTS.md` name the new filename wherever a work-tree state file is named by
      path, and neither names this work or its folder anywhere.
- [ ] The discovery-ledger surface is byte-unchanged: `canonical/aid/templates/discovery-state-template.md`,
      `canonical/aid/scripts/summarize/writeback-state.sh` and the six KB-state reader scripts show
      no diff.
- [ ] Task-012's `§ GATE` `OUT OF SCOPE` bullets in `shortcut-engine.md` are intact.
- [ ] Documentation accuracy is verified against the shipped code, not from memory: each changed
      recipe's target key exists in the task-002 templates and is writable by the task-007 writer
      (`task-type-rules.md § DOCUMENT`).
- [ ] No file under `profiles/`, `.claude/` or `.cursor/` is edited by this task (C-1).
- [ ] All section-6 quality gates pass.
