# task-013: `/aid-create-mvp` and the `## MVP` region split inside `roadmap.md`

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-013/STATE.md.
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

**Depends on:** task-012

**Scope:**
- Source spec: `features/feature-003-planning-artifact-skills/SPEC.md` §3c, §4, §6b (its
  `/aid-create-mvp` row), §6d; feature-002 §3c (*Mechanics* and the first-write rule's
  region-owning row); REQUIREMENTS CC-5.
- **Why the edge is to task-012 rather than to task-011.** The content dependency is on
  task-011 (this skill needs `roadmap.md`'s shape and its `## Contents` anchor). The edge
  goes one step further because task-012 and this task **both append rows to the single
  `canonical/aid/templates/shortcut-catalog.yml`** -- the canonical source, where a row
  added under a profile copy is discarded by the next render. Two concurrent appends to one
  file is shared mutable state, so the whole catalog-writing chain is serial by construction.
  It executes in the order 010, 011, 012, 013, 014 -- written as a comma-separated list in
  run order, never with arrows, per the convention PLAN § *Execution Graph* states once.
- Author `canonical/skills/aid-create-mvp/SKILL.md` plus its catalog row (`verb: create`,
  `artifact: mvp`, `default_type: DOCUMENT`, `group: G4`, `alias_of: null`,
  `repurpose: true`, §1's `intent` verbatim).
- **Region identity, extent and write discipline**, referred to feature-002 §3c rather than
  restated in a second form: the literal heading `## MVP`, matched exactly; extent from that
  heading to the next heading of level 2 or shallower, or EOF, with `###` entries belonging
  to the region; read the whole file, replace only the owned byte range, write back with
  every other region **byte-identical**, never regenerate.
- **Position when created** -- the concrete anchor feature-002 defers to this feature:
  immediately after the `## Contents` block and **before `## Now`**. Not "before the first
  other `##`", which would place the MVP above the document index and break KB layout order.
- **The MVP section's own shape**: it is a decision entry like any other --
  `**What:**` the first shippable slice, itemized; `**Why:**` why the line falls there;
  `**Rejected:**` what was cut, each with its reason; `**Status:** Not started | In progress
  | Shipped <version>` with the evidence anchor.
- **The three first-write situations for this skill** (feature-003 §4, §6b):
  `roadmap.md` absent -> **route to `/aid-create-roadmap`**, naming it, creating nothing, and
  leaving `.aid/design/mvp.md` in place for that run to consume (CC-5, CC-3) -- it neither
  stops silently nor scaffolds a document it does not own; document present and `## MVP`
  absent -> create the region at the anchor; region already populated -> route to
  `/aid-update-mvp`, seed survives.
- Class-1 seed handling: refuse while `## Open questions` is non-empty unless overridden,
  naming the unresolved content **and** the override; delete the seed on the realizing path
  only.
- **This skill writes no registration entry**, because it never creates a document (CC-5;
  feature-003 §1's destinations table).
- Out of scope: the `MVP` entry in `## Contents`, which `/aid-create-roadmap` writes at
  creation (task-011) precisely so REQUIREMENTS AC-6a's "writes only that section" is
  literally true; the `update` counterpart (task-014); and running the skill against this
  repository (task-015).

**Acceptance Criteria:**
- [ ] V1/V3 for this row: directory and row exist with all eight fields,
      `default_type: DOCUMENT`, `group: G4`; V2 -- `build-shortcut-skills.py` overwrites no
      body
- [ ] The body **never** creates `roadmap.md` and **never** edits `## Contents` -- the two
      writes CC-5 and AC-6a forbid it
- [ ] The routing exit on an absent `roadmap.md` names `/aid-create-roadmap` explicitly,
      writes nothing, and leaves `.aid/design/mvp.md` in place (V16 / feature-002 E1's
      assertions; the run itself is task-016)
- [ ] The body states the byte-range write discipline in full -- whole file read, only the
      `## MVP` range replaced, every other region byte-identical -- which is V7's and V8's
      precondition
- [ ] The anchor position is stated as "immediately after the `## Contents` block, before
      `## Now`", and the rejected phrasing is not reintroduced
- [ ] The body writes no `.aid/settings.yml` entry and no `.aid/knowledge/README.md`
      Completeness row
- [ ] V25 for this skill: the `description` names `/aid-create-roadmap` (which creates the
      document itself) and `/aid-update-mvp`
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean, and no count comment
      inside `shortcut-catalog.yml` is edited
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
