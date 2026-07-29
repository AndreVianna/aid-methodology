# task-051: SKILL.md GAP-REPORT dispatch row and state-map node

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

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** task-007, task-008, task-050

**Scope:**
- `canonical/skills/aid-graph/SKILL.md` -- add **exactly one** Dispatch-table row for `GAP-REPORT`
  pointing at `references/state-gap-report.md`, plus the corresponding `GAP-REPORT` node in the
  "you are here" state map, positioned after EMIT as feature-010's state machine declares.
- **Re-point the Advance lines so the machine is valid *at this delivery boundary*** *(owner
  correction 2026-07-28).* The state machine must be runnable at the end of every delivery, not only
  at the end of the work, and RENDER does not exist until delivery-004:
  - `GAP-REPORT`'s Advance is **`CHAIN → VALIDATE`** here, **not** `→ RENDER`.
  - EMIT's Advance, which task-031 wrote as `CHAIN → VALIDATE` for delivery-002's nine-state machine
    (feature-010's table says `→ GAP-REPORT`, which did not yet exist), is **re-pointed to
    `CHAIN → GAP-REPORT`** by this task.
  Task-067 then re-points `GAP-REPORT → RENDER` and gives RENDER `→ VALIDATE`, closing the sequence
  feature-010's table describes. Each delivery therefore ships a machine with no dangling state.
- **Also append this delivery's new files to `## References`** *(owner addition 2026-07-28).*
  Task-008 authors that section in delivery-002 covering delivery-002's files only, and **no other
  task adds the later deliveries' modules** — so without this, the shipped skill's `## References`
  silently omits `detect-kb-gaps.mjs` and `coverage-predicate.mjs`. Add the entries for the files
  delivery-003 creates (tasks 045, 046, 047). This is a deliberate, narrow exception to the
  feature-010 ÷ feature-012 named-section seam: feature-012 owns the section's *initial authoring*,
  and each later delivery appends its own entries in the task that already edits this file, rather
  than adding a second `SKILL.md`-editing task per delivery.
- **No edit to this file beyond those two things.**
- This is the one row feature-006 L1 requires as its own task, stated there explicitly so
  `/aid-detail` produces one task that edits `SKILL.md` and a separate task that creates
  `state-gap-report.md`, rather than two tasks editing the same lines.
- **`SKILL.md` is serialised across three deliveries** and this task is the third writer:
  task-007 -> task-008 -> **task-051** -> task-067. delivery-002 ships a deliberately **nine-state**
  machine (no GAP-REPORT, no RENDER). This task takes it to **ten** states; task-067 in delivery-004
  adds RENDER and takes it to eleven.
- **Why the successor is VALIDATE here and not RENDER** *(owner correction 2026-07-28; supersedes an
  earlier note in this task that said to leave `→ RENDER` as tabled).* feature-010's state machine
  declares `GAP-REPORT → RENDER` as the **final** shape, but `RENDER`'s body
  (`references/state-render.md`, task-066) and its state-map node (task-067) do not exist until
  delivery-004. Pointing at a state that does not exist would ship a machine with a dangling
  successor, and `SKILL.md` must be **runnable at the end of every delivery**, not only at the end of
  the work. So `GAP-REPORT` advances to `VALIDATE` here, and task-067 re-points it to `RENDER` when
  RENDER lands. This is an interim target by necessity, and it is recorded rather than hidden.
- **Canonical-first.** Only the canonical copy is edited; the `profiles/`, `.claude/` and `.cursor/`
  copies are rendered build output. The render is task-055.
- Out of scope: the state body itself (task-050); the frontmatter and the Pre-flight / Arguments /
  State Detection / Quality Gate / Failure-modes sections (task-007, feature-010); the
  `## References` entries belonging to delivery-002 (task-008) and delivery-004 (task-067); the
  RENDER row and node (task-067, delivery-004).

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-graph/SKILL.md` gains exactly one Dispatch-table row for GAP-REPORT,
      pointing at `references/state-gap-report.md`, positioned after the EMIT row.
- [ ] The "you are here" state map gains exactly one `GAP-REPORT` node, in the same position.
- [ ] **`GAP-REPORT`'s Advance is `CHAIN → VALIDATE`, not `→ RENDER`** — RENDER does not exist until
      delivery-004, and a machine shipped with a dangling successor is not runnable. Task-067
      re-points it to RENDER.
- [ ] **EMIT's Advance is re-pointed from `CHAIN → VALIDATE` to `CHAIN → GAP-REPORT`.** Task-031 wrote
      it as VALIDATE for delivery-002's nine-state machine because GAP-REPORT did not yet exist.
- [ ] **`## References` gains delivery-003's entries** — the files tasks 045, 046 and 047 create.
      Task-008 authored that section for delivery-002's files only, and no other task adds the later
      deliveries', so without this the shipped skill's reference list omits them.
- [ ] The row's Advance target matches `state-gap-report.md`'s single `**Advance:**` line exactly --
      the two are read together and cannot disagree.
- [ ] The state machine reads as **ten** states after this task (the nine delivery-002 shipped, plus
      GAP-REPORT), and every place in `SKILL.md` that states a state count says ten. Task-067 takes it
      to eleven.
- [ ] `git diff -- canonical/skills/aid-graph/SKILL.md` touches only: the GAP-REPORT dispatch row, the
      diagram node, the two Advance re-points, this delivery's `## References` entries, and the count
      reconciliation. The frontmatter and the `## Pre-flight Checks`, `## Arguments`,
      `## State Detection`, `## Quality Gate` and `## Failure modes and recovery` sections are
      byte-unchanged, because they belong to task-007.
- [ ] Only the canonical copy is edited: `git status --porcelain` shows no change under `profiles/`,
      `.claude/` or `.cursor/` from this task.
- [ ] All existing canonical suites still pass -- `bash tests/run-all.sh` reports no newly red suite.
- [ ] **The named suite is task-091's `tests/canonical/test-graph-skill-registration.sh`**
      (`GR01`-`GR06`, delivery-006), which compares every rendered tree to the canonical source
      rather than to a sibling. *This replaces IMPLEMENT's "unit tests for all new public methods"
      default, which has no vehicle for a `SKILL.md` edit: the `tests/canonical/test-*.sh` suites are
      the only vehicle, and the one-type-per-task rule forces them into separate TEST tasks.*
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
