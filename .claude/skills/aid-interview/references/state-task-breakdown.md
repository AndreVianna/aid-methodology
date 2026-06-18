# State: TASK-BREAKDOWN (L2)

Runs after CONDENSED-INTAKE (L1). Reads the work-root `SPEC.md` and proposes a
typed task breakdown, then scaffolds the `delivery-001/` hierarchy
(delivery-001/{SPEC,STATE}.md + delivery-001/tasks/task-NNN/{SPEC,STATE}.md) and fills the
`## Tasks` + `## Execution Graph` sections of the work-root `SPEC.md`.

**Agent:** Dispatch `aid-architect` (override `subagent_type`). This is design work,
not interview work.

---

## Idempotency check

Read the work-root `SPEC.md`. If `## Tasks` already has task rows (i.e., at
least one `task-NNN` entry beyond the placeholder) AND
`delivery-001/tasks/` contains at least one `task-NNN/` subdirectory,
TASK-BREAKDOWN is already complete — skip to LITE-REVIEW.

Print: `[State: TASK-BREAKDOWN] Sub-path: {Sub-path}`
Print before dispatch: `[State: TASK-BREAKDOWN] Dispatching aid-architect for task breakdown.`

---

## Dispatch

```
▶ aid-architect starting
Read `references/state-task-breakdown.md` for the full task-breakdown process.
✓ aid-architect done — or ✗ aid-architect failed: {reason}
```

---

## Task-breakdown process (aid-architect)

### Step 1: Load context

Read:
- `STATE.md ## Triage` — for `Sub-path` and `Work Type`
- Work-root `SPEC.md` — for `## Goal`, `## Context`, `## Acceptance Criteria`
- `.aid/knowledge/INDEX.md` — for KB context

### Step 2: Propose task breakdown

Propose a small typed task breakdown directly from the work-root `SPEC.md`.

**Rules (same as `aid-detail`):**

- One type per task — never mix IMPLEMENT + TEST in a single task.
- Every task is one reviewable unit (one coherent change, clearly bounded).
- Dependencies drive ordering — no task starts before its dependencies are done.
- Natural ordering: RESEARCH → DESIGN → IMPLEMENT → TEST → DOCUMENT.
- Each task must be traceable to at least one `## Acceptance Criteria` entry.
- Task count: 1–2 for LITE-BUG-FIX, 1–3 for LITE-REFACTOR,
  1–5 for LITE-FEATURE. Propose the minimum number needed; escalate if genuinely more.

**Sub-path-specific guidance:**

| Sub-path | Typical task count | Typical task types |
|----------|-------------------|--------------------|
| LITE-BUG-FIX | 1 (apply fix + add regression test as one task) | IMPLEMENT |
| LITE-REFACTOR | 1–3 | REFACTOR, TEST (if tests need separate update); when the work is a doc/report revision (`change-docs`/`change-report` recipe), the single task is typed DOCUMENT |
| LITE-FEATURE | 1–5 | IMPLEMENT, TEST, DOCUMENT; when the work is a new doc/report (`add-docs`/`add-report` recipe), exactly 1 DOCUMENT task is typical |

### Step 3: Present proposed breakdown for approval

Present the proposed task list to the user:

```
Proposed task breakdown for {work-NNN-name} ({Sub-path}):

  task-001 [{Type}]: {title}
    Scope: {scope}
    Depends on: — (none)

  task-002 [{Type}]: {title}        ← only if needed
    Scope: {scope}
    Depends on: task-001

[1] Approve this breakdown
[2] Modify: ___
[3] Escalate to full path (too many tasks or features discovered)
```

Wait for user response:
- **[1] Approve:** proceed to Step 4.
- **[2] Modify:** incorporate the change and re-present for approval (loop until [1]).
- **[3] Escalate:** invoke `references/lite-to-full-escalation.md` (lite→full
  escalation procedure). Pass current state name (`TASK-BREAKDOWN`) and all
  captured info: the approved task list (if any), the work-root `SPEC.md` (already
  written by CONDENSED-INTAKE), and all slot values from CONDENSED-INTAKE (read
  `STATE.md ## Escalation Carry` if escalation was partially triggered earlier, or
  read the `SPEC.md` sections to reconstruct slot values). Exit TASK-BREAKDOWN after
  escalation completes.

### Step 4: Scaffold delivery-001 hierarchy and write task files

#### 4a: Create delivery-001 folder and SPEC.md

Create `.aid/{work}/delivery-001/` if it does not exist.

Write `.aid/{work}/delivery-001/SPEC.md` using the delivery spec shape
from `../../templates/delivery-spec-template.md`:

```markdown
# Delivery SPEC -- delivery-001: {work-NNN-name} lite execution

> **Delivery:** delivery-001
> **Work:** {work-NNN-name}
> **Created:** {today}

---

## Objective

Single delivery for lite-path work {work-NNN-name}. All tasks execute on the
`aid/work-NNN-delivery-001` branch and are gated together at delivery-001 close.

## Scope

All tasks defined in the work-root SPEC.md `## Tasks` section.

**Out of scope:** Future deliveries (this is the sole lite-path delivery).

## Gate Criteria

- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] Delivery grade meets or exceeds the minimum grade for this work.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | {Type} | {title} |
| task-002 | {Type} | {title} |   ← only if present

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Lite-path work: single delivery, no features/ folder, no REQUIREMENTS.md, no PLAN.md.
Source: /aid-interview lite path, sub-path {Sub-path}.
```

**Write immediately after task list is approved. Do not batch.**

#### 4b: Create delivery-001/STATE.md

Write `.aid/{work}/delivery-001/STATE.md` seeded from
`../../templates/delivery-state-template.md` with the initial delivery lifecycle:

```markdown
# Delivery State -- delivery-001

> **Delivery:** delivery-001
> **Work:** {work-NNN-name}
> **Branch:** aid/{work-NNN-name}-delivery-001

---

## Delivery Lifecycle

- **State:** Executing
- **Updated:** {YYYY-MM-DDTHH:MM:SSZ}
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

- **Reviewer Tier:** Small
- **Grade:** Pending
- **Issue List:** none
- **Timestamp:** --

---

## Cross-phase Q&A

_None yet._

---

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
```

Note: the delivery State is seeded as `Executing` (not `Pending-Spec` or `Specified`)
because the lite path runs CONDENSED-INTAKE + TASK-BREAKDOWN before scaffolding the
delivery folder -- by the time delivery-001 is created, the tasks are already approved
and execution is the next step. The delivery-001 lifecycle goes directly to `Executing`
at creation; the `Gated` and `Done` transitions happen in aid-execute.

**Write immediately. Do not batch.**

#### 4c: Create task folders and write task SPEC.md + STATE.md files

Create `.aid/{work}/delivery-001/tasks/` if it does not exist.

For each approved task, create `.aid/{work}/delivery-001/tasks/task-NNN/` and write
two files:

**`delivery-001/tasks/task-NNN/SPEC.md`** -- the task definition (immutable):

```markdown
# task-NNN: {title}

**Type:** {Type}

**Source:** {work-NNN-name} → delivery-001

**Depends on:** task-NNN [, task-NNN] | — (none)

**Scope:**
- {What this task produces or modifies — specific and bounded.}

**Acceptance Criteria:**
- [ ] {Criterion 1 — concrete and testable, traceable to work-root SPEC.md AC}
- [ ] {Criterion 2 — concrete and testable}
- [ ] All §6 quality gates pass.
```

**`delivery-001/tasks/task-NNN/STATE.md`** -- the task mutable state, seeded from
`../../templates/task-state-template.md`:

```markdown
# Task State -- task-NNN

> **Task:** task-NNN
> **Delivery:** delivery-001
> **Work:** {work-NNN-name}

---

## Task State

- **State:** Pending
- **Review:** Pending
- **Elapsed:** --
- **Notes:** --

---

## Quick Check Findings

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:** none

---

## Dispatch Log

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
```

**Source field convention (lite path):** always `{work-NNN-name} → delivery-001`.
There is no `features/` folder; `delivery-001` is the constant lite-work delivery id.

**Write each task folder and its two files immediately after approval. Do not batch.**

### Step 5: Fill SPEC.md §§ Tasks + Execution Graph

Update the work-root `SPEC.md` to replace the placeholder rows with the actual task list:

**`## Tasks` section:**

```markdown
## Tasks

> Tasks live under `delivery-001/tasks/task-NNN/SPEC.md`; each task folder also contains
> `STATE.md` for mutable task state. The table below is the navigational index.

| Task | Type | Title |
|------|------|-------|
| task-001 | {Type} | {title} |
| task-002 | {Type} | {title} |   ← only if present
```

**`## Execution Graph` section:**

```markdown
## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |   ← only if present

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |   ← only if present and depends on wave-1
```

Parallel tasks (tasks with no dependency between them) go in the same wave.

Also update the delivery-001/SPEC.md `## Tasks` table to match the approved task list
(same rows as the work-root SPEC.md table above).

### Step 6: Update STATE.md lifecycle

(The `## Tasks State` section of the work-level STATE.md is DERIVED at read time from
per-task STATE.md files; do NOT write task rows directly into the work STATE.md.)

Add entry to `STATE.md ## Lifecycle History`:

```
| {today} | TASK-BREAKDOWN complete — {N} tasks written | /aid-interview TASK-BREAKDOWN |
```

---

## Advance

**CHAIN** → [State: LITE-REVIEW] (continue inline).

---

## Unit-testable cases

| Input | Expected output |
|-------|----------------|
| LITE-BUG-FIX SPEC.md, no delivery-001/ | delivery-001/{SPEC,STATE}.md created; delivery-001/tasks/task-001/{SPEC,STATE}.md written (IMPLEMENT); `## Tasks` + `## Execution Graph` filled; wave-1 = task-001 |
| LITE-REFACTOR SPEC.md, 2-task breakdown approved | delivery-001/ + tasks/task-001/ (REFACTOR) + tasks/task-002/ (TEST) written; delivery-001/SPEC.md tasks table has both rows; dependency graph: task-002 depends on task-001 |
| LITE-FEATURE SPEC.md, 3-task breakdown approved | 3 task folders written under delivery-001/tasks/; parallel waves calculated correctly |
| delivery-001/tasks/ already has task-NNN/ dirs AND SPEC.md ## Tasks has rows | Skip; advance to LITE-REVIEW (idempotent) |
| User selects [3] Escalate | `lite-to-full-escalation.md` invoked; SPEC.md + captured slots carried; `Path: escalated` written; REQUIREMENTS.md seeded; exit TASK-BREAKDOWN; next state = CONTINUE |
