# task-010: Three `design` planning-artifact skills and their catalog rows

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-010/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-005

**Scope:**
- Source spec: `features/feature-003-planning-artifact-skills/SPEC.md` §1, §6a, §6d (its
  three `design` rows); it binds feature-002 §3a's `design` stage row, §3e's skill shape,
  §3f's catalog row shape, §3g and §4. **No feature-001 dependency**: these three skills
  write only `.aid/design/` and never touch `.aid/knowledge/`, so doctrine and membership do
  not gate them -- that dependency binds the `create` skills (task-011, task-012).
- Author three hand-authored bodies -- `canonical/skills/aid-design-roadmap/SKILL.md`,
  `aid-design-mvp/SKILL.md`, `aid-design-backlog/SKILL.md` -- on feature-002 §3e's shape:
  frontmatter (`name` == directory name, `description`, `allowed-tools`, `argument-hint`);
  states INTAKE -> DESIGN -> VERIFY -> PRESENT -> DONE; allocation through the Work
  Initiation Gate (`enumerate-works.sh`, then `worktree-lifecycle.sh create` on new work,
  stopping on a non-zero exit or empty path) with `pipeline.path: lite`,
  `initiator: aid-design-<artifact>`, `lifecycle: Running`, and **`phase` not driven**;
  `aid-architect` dispatch tiered by complexity with verifier tier >= producer tier; full
  verify as `design-lifecycle.md` defines it.
- Each body binds the `design` stage row: reads its seed if present plus `.aid/knowledge/`
  and the project source; writes **only** `.aid/design/<artifact>.md` in `design-seed.md`'s
  shape; **never writes `.aid/knowledge/` and never writes production code**; re-invocation
  iterates the same seed (`## Current direction` rewritten, `## Options considered`
  accumulating); terminates by presenting, with the user iterating by re-invoking.
- Each body carries feature-002 §2d's first-use acquisition of `.aid/design/` and its
  `README.md`.
- What each draws out, per feature-003 §6a's table: direction and its *why* / committed vs
  merely wanted / sequencing rationale and rejected alternatives; the MVP line -- what is in
  the first shippable slice, what defers, and the reason for each cut; item definitions,
  done-conditions and priorities plus which `tech-debt.md` rows the user is accepting.
- Append three rows to `canonical/aid/templates/shortcut-catalog.yml` -- the canonical
  source; a row added under a profile copy is discarded by the next render -- carrying all
  eight fields of feature-003 §1's table: `name` == directory, `verb: design`,
  `artifact: roadmap|mvp|backlog`, `alias_of: null`, `group: G3`, `default_type: DESIGN`,
  the `intent` string verbatim, `repurpose: true`.
- Out of scope: **the three stale count comments inside `shortcut-catalog.yml`** (the G4 and
  G5 family headers and the `repurpose` schema note) -- handed to delivery-003 so that
  features 003, 004 and 005 do not collide on one file (BLUEPRINT § Notes; feature-003 V28);
  and the full `run_generator.py` render, which is delivery-003's single run (C-5).

**Acceptance Criteria:**
- [ ] V1, this task's share: `ls -d canonical/skills/aid-design-{roadmap,mvp,backlog}` -> 3,
      and `grep -cE '^  - name: aid-design-(roadmap|mvp|backlog)$' canonical/aid/templates/shortcut-catalog.yml`
      -> `3`
- [ ] V3: each of the three rows carries all eight fields, with `default_type: DESIGN` from
      the closed 8-enum and `group: G3` (Prototype + Design) -- not `G8`, whose own header
      forbids writing `.aid/knowledge/`
- [ ] V2: running `build-shortcut-skills.py` leaves
      `git diff --exit-code canonical/skills/aid-design-{roadmap,mvp,backlog}/` clean -- a row
      that lost `repurpose: true` makes the helper emit a doorway and the diff non-empty.
      Separately, `grep -rL 'shortcut-engine' canonical/skills/aid-design-{roadmap,mvp,backlog}/SKILL.md`
      lists all three: engine participation is a property of the body, not of the key
- [ ] V25, this task's share: each `description` contains the literal name of every
      neighbour feature-003 §6d assigns it -- `aid-design-roadmap` -> `/aid-design-mvp` and
      `/aid-create-roadmap`; `aid-design-mvp` -> `/aid-design-roadmap` and `/aid-create-mvp`;
      `aid-design-backlog` -> `/aid-design-roadmap` and `/aid-create-backlog` -- and names no
      neighbour §6d does not assign
- [ ] No `intent` value contains a backtick or any other markdown, and its em-dashes are
      ASCII `--`, matching how all 58 live rows write theirs
- [ ] Each body states the `design` invariant explicitly (never writes `.aid/knowledge/`,
      never writes production code) and drives no `phase:` value
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean, and no count comment
      inside `shortcut-catalog.yml` is edited
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
