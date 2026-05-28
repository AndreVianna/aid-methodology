# State: TASK-BREAKDOWN (L2)

Runs after CONDENSED-INTAKE (L1). Reads the work-root `SPEC.md` and proposes a
typed task breakdown, then writes `tasks/task-NNN.md` files and fills the
`## Tasks` + `## Execution Graph` sections of `SPEC.md`.

**Agent:** Dispatch `architect` (override `subagent_type`). This is design work,
not interview work.

---

## Idempotency check

Read the work-root `SPEC.md`. If `## Tasks` already has task rows (i.e., at
least one `task-NNN` entry beyond the placeholder), TASK-BREAKDOWN is already
complete — skip to LITE-REVIEW.

Print: `[State: TASK-BREAKDOWN] Sub-path: {Sub-path}`
Print before dispatch: `[State: TASK-BREAKDOWN] Dispatching architect for task breakdown.`

---

## Dispatch

```
▶ architect starting
Read `references/state-task-breakdown.md` for the full task-breakdown process.
✓ architect done — or ✗ architect failed: {reason}
```

---

## Task-breakdown process (architect)

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
- Task count: 1–2 for LITE-BUG-FIX, exactly 1 for LITE-DOC, 1–3 for LITE-REFACTOR,
  1–5 for LITE-FEATURE. Propose the minimum number needed; escalate if genuinely more.

**Sub-path-specific guidance:**

| Sub-path | Typical task count | Typical task types |
|----------|-------------------|--------------------|
| LITE-BUG-FIX | 1 (apply fix + add regression test as one task) | IMPLEMENT |
| LITE-DOC | 1 | DOCUMENT |
| LITE-REFACTOR | 1–3 | REFACTOR, TEST (if tests need separate update) |
| LITE-FEATURE | 1–5 | IMPLEMENT, TEST, DOCUMENT |

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

### Step 4: Create tasks/ folder and write task files

Create `.aid/{work}/tasks/` if it does not exist.

For each approved task, write `.aid/{work}/tasks/task-NNN.md` using the
6-section flat shape from `../../templates/delivery-plans/task-template.md`:

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

**Source field convention (lite path):** always `{work-NNN-name} → delivery-001`.
There is no `features/` folder; `delivery-001` is the constant lite-work delivery id.

**Write each task file immediately after approval. Do not batch.**

### Step 5: Fill SPEC.md §§ Tasks + Execution Graph

Update the work-root `SPEC.md` to replace the placeholder rows with the actual task list:

**`## Tasks` section:**

```markdown
## Tasks

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

### Step 6: Update STATE.md Tasks Status

Add a row to `STATE.md ## Tasks Status` for each task created:

```
| task-NNN | {title} | {Type} | 1 | Pending | — | — | — |
```

### Step 7: Update STATE.md lifecycle

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
| LITE-BUG-FIX SPEC.md, no tasks/ | task-001 IMPLEMENT written; `## Tasks` + `## Execution Graph` filled; wave-1 = task-001 |
| LITE-DOC SPEC.md, no tasks/ | task-001 DOCUMENT written; single-wave graph |
| LITE-REFACTOR SPEC.md, 2-task breakdown approved | task-001 REFACTOR + task-002 TEST written; dependency graph: task-002 depends on task-001 |
| LITE-FEATURE SPEC.md, 3-task breakdown approved | 3 tasks written; parallel waves calculated correctly |
| tasks/ already has task-NNN rows in SPEC.md ## Tasks | Skip; advance to LITE-REVIEW (idempotent) |
| User selects [3] Escalate | `lite-to-full-escalation.md` invoked; SPEC.md + captured slots carried; `Path: escalated` written; REQUIREMENTS.md seeded; exit TASK-BREAKDOWN; next state = CONTINUE |
