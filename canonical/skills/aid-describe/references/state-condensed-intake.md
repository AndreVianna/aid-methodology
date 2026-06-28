# State: CONDENSED-INTAKE (L1)

Runs after TRIAGE when `**Path:** lite`. Reads the `**Sub-path:**` field from
`STATE.md ## Triage` and runs the sub-path-specific condensed interview, then
writes the work-root `SPEC.md` (§ Goal, § Context, § Acceptance Criteria).

No `REQUIREMENTS.md` is created. No `features/` folder is created.

---

## Idempotency check

Read `STATE.md ## Triage`. If `**Path:**` is not `lite`, stop — wrong state.

Read the work-root `SPEC.md` (`.aid/{work}/SPEC.md`). If it already exists and
contains `## Acceptance Criteria` with at least one entry, CONDENSED-INTAKE is
already complete — skip to TASK-BREAKDOWN.

Print: `[State: CONDENSED-INTAKE] Sub-path: {Sub-path}`

---

## Step 1: Read KB context

Check for `.aid/knowledge/INDEX.md`. If it exists, read it and note any
documentation relevant to this work — KB references are used to populate the
`## Context` section without re-asking questions already answered.

---

## Step 1.5: Pre-fill from Recipe Slots (recipe→standard-lite escalation)

**This step only applies when a recipe was escalated (not declined or aborted).**

Read `STATE.md`. Check for a `## Recipe Slots` section. If it exists AND contains
`Status: abandoned — escalated to standard interview`, this is a recipe-escalation
session:

1. Parse the slot table from `## Recipe Slots` into a mapping:
   `{ "slot-name": "value", ... }` — skip rows with value `—` or placeholder text
   `(none filled before escalation)`.

2. For the current `Sub-path`, identify which slot names correspond to the sub-path's
   questions (the slot names are the same names used as variable names in
   state-condensed-intake.md — e.g., `bug-title`, `bug-description`, `reproduction-steps`,
   `intended-behavior` for LITE-BUG-FIX).

3. **Display pre-filled summary (one turn, before any interactive prompt):**

   ```
   Pre-filled from recipe '{recipe-name}':
     {slot-name-1}: {value-1}
     {slot-name-2}: {value-2}
     ...

   These answers will be used as-is. You will only be asked for the remaining questions.
   (To change a pre-filled answer, type the slot name and new value when prompted for
   the next question, or re-run with --reset to start over.)
   ```

   If zero matching slots were found (the recipe had no slots that overlap with this
   sub-path's questions), print:

   ```
   Note: Recipe '{recipe-name}' was abandoned before any matching answers were captured.
   Running full standard {Sub-path} interview.
   ```

4. Mark the pre-filled slots as answered internally. Skip the interactive prompt for
   each pre-filled slot — do not ask the user again. Proceed directly to the first
   **unanswered** sub-path question.

5. After all sub-path questions are resolved (pre-filled + newly asked), continue
   with Step 3 (Write work-root SPEC.md) using the combined slot values.

**Slot name cross-reference (recipe slot name → sub-path question slot name):**

The slot names in `## Recipe Slots` are recipe-defined names. They match sub-path
question slot names when they are **identical** (exact string match). No fuzzy matching.

| Sub-path | Known question slot names |
|----------|--------------------------|
| LITE-BUG-FIX | `bug-title`, `bug-description`, `reproduction-steps`, `intended-behavior` |
| LITE-REFACTOR | `scope`, `before-sketch`, `after-sketch`, `ac` |
| LITE-FEATURE | `feature-title`, `goal`, `scope`, `ac-1`, `ac-additional` |

Any recipe slot name that does NOT appear in the table above is ignored (it was a
recipe-specific slot that has no corresponding standard sub-path question).

---

## Escalation

At any point during CONDENSED-INTAKE, the user may type `/aid-describe escalate`
or respond with "escalate to full path". When that happens:

- Invoke `references/lite-to-full-escalation.md` immediately.
- Pass the current sub-path name and all slot values captured so far (even if only
  partially answered).
- Do NOT write the work-root `SPEC.md` before escalating.
- Exit CONDENSED-INTAKE after the escalation procedure completes.

---

## Step 2: Run sub-path-specific intake

Read `**Sub-path:**` from `STATE.md ## Triage`. Dispatch to the matching
sub-path below. Each sub-path asks its specific questions (one per turn),
records answers internally, then writes the work-root `SPEC.md`.

---

### Sub-path: LITE-BUG-FIX

**Purpose:** A bug fix is already its own spec — the reproduction IS the spec.
No "what are we building" Specify content is needed. The fix is bounded by
the reproduction + intended-behavior pair.

**Questions (ask one per turn; wait for answer before asking next):**

1. **bug-title** — What is the short title of this bug?
   ```
   What is a short, descriptive title for this bug?
   (e.g., "Login fails when username contains special characters")
   ```

2. **bug-description** — What is the full description of the bug?
   ```
   Describe the bug in detail. What behavior are you observing that is wrong?
   ```

3. **reproduction-steps** — How can someone reliably reproduce this?
   ```
   What are the exact steps to reproduce this bug?
   List them as numbered steps if possible.
   ```

4. **intended-behavior** — What should happen instead?
   ```
   What is the correct, intended behavior after the fix?
   ```

**SPEC.md shape for LITE-BUG-FIX:**

> **Identity block composition (MUST):** When writing the SPEC.md, the agent MUST compose:
> - **Name** — a concise Title-Case title from the work subject (no trailing period; NOT the `work_id` slug; derived from `bug-title`).
> - **Description** — exactly one sentence distilled from the captured problem/objective (derived from `bug-description`); no trailing period.
> These MUST be real values (not `*(pending)*`) at the moment of writing.

```markdown
# {bug-title}

- **Name:** {Name — Title Case title derived from bug-title, no trailing period}
- **Description:** {Description — one sentence from bug-description, no trailing period}
- **Work:** {work-NNN-name}
- **Created:** {today}
- **Source:** /aid-describe lite path — LITE-BUG-FIX
- **Status:** Draft

## Goal

{bug-description — one paragraph stating what is broken and its impact.}

## Context

**Bug report:** {bug-description}

**Reproduction steps:**
{reproduction-steps as numbered list}

**Intended behavior:** {intended-behavior}

{KB references if relevant — cite by INDEX.md doc name}

## Acceptance Criteria

- [ ] Given {reproduction-steps precondition}, when {the action that triggers the bug}, then {intended-behavior} is observed.
- [ ] Regression test added that would have caught this bug.
- [ ] All §6 quality gates pass.

## Tasks

> Tasks live under `delivery-001/tasks/task-NNN/SPEC.md`; each task folder also contains
> `STATE.md` for mutable task state. The table below is the navigational index.

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Apply fix + add regression test |

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
| {today} | Initial lite-path SPEC created | /aid-describe LITE-BUG-FIX |
```

> Note: The `## Tasks` and `## Execution Graph` sections are placeholders at
> L1 completion; they are filled in full by State L2 (TASK-BREAKDOWN). L1 only
> writes: `## Goal`, `## Context`, `## Acceptance Criteria`. The scaffold rows
> above are pre-populated so the file is valid Markdown — L2 overwrites them.
> The `delivery-001/` hierarchy (SPEC.md + STATE.md + task folders) is created by L2.

---

### Sub-path: LITE-REFACTOR

**Purpose:** A small, bounded refactor. The before/after sketch + scope + AC
describes both the intent and the definition of done.

> **Documentation/report work** that edits an existing doc or report routes here
> (e.g., `change-docs`, `change-report` recipes). When the work is a doc/report
> revision, interpret `scope` as the document being updated, `before-sketch` as its
> current state/gaps, and `after-sketch` as the desired post-edit state. Audience and
> outline changes are captured via the `scope` + `after-sketch` prompts.

**Questions (ask one per turn; wait for answer before asking next):**

1. **scope** — What code will be changed?
   ```
   What is the scope of this refactor? Which files, modules, classes, or methods
   will be changed?
   ```

2. **before-sketch** — What does the current code look like (the problem)?
   ```
   Briefly describe the current structure or behavior you want to change.
   What is wrong or suboptimal about it?
   ```

3. **after-sketch** — What should it look like after the refactor?
   ```
   Describe the desired structure or behavior after the refactor.
   What will be better?
   ```

4. **ac** — What are the acceptance criteria?
   ```
   How will you know the refactor is done and correct?
   List the key acceptance criteria (e.g., "all existing tests pass",
   "no public API changes", "cyclomatic complexity reduced").
   ```

**SPEC.md shape for LITE-REFACTOR:**

> **Identity block composition (MUST):** When writing the SPEC.md, the agent MUST compose:
> - **Name** — a concise Title-Case title from the work subject (no trailing period; NOT the `work_id` slug; derived from `scope`).
> - **Description** — exactly one sentence distilled from the captured problem/objective (derived from `before-sketch` → `after-sketch`); no trailing period.
> These MUST be real values (not `*(pending)*`) at the moment of writing.

```markdown
# {scope} — Refactor

- **Name:** {Name — Title Case title derived from scope, no trailing period}
- **Description:** {Description — one sentence from before/after sketch, no trailing period}
- **Work:** {work-NNN-name}
- **Created:** {today}
- **Source:** /aid-describe lite path — LITE-REFACTOR
- **Status:** Draft

## Goal

{before-sketch → after-sketch — one paragraph: what is changing and why.}

## Context

**Scope:** {scope}

**Before:** {before-sketch}

**After:** {after-sketch}

{KB references if relevant — cite by INDEX.md doc name}

## Acceptance Criteria

{ac — acceptance criteria from the ac question, formatted as checklist}
- [ ] All existing tests pass (no behavior regression).
- [ ] All §6 quality gates pass.

## Tasks

> Tasks live under `delivery-001/tasks/task-NNN/SPEC.md`; each task folder also contains
> `STATE.md` for mutable task state. The table below is the navigational index.

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | {scope} refactor |

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
| {today} | Initial lite-path SPEC created | /aid-describe LITE-REFACTOR |
```

> Note: L1 writes `## Goal`, `## Context`, `## Acceptance Criteria`.
> `## Tasks` / `## Execution Graph` scaffold rows are placeholders — L2 overwrites them.
> The `delivery-001/` hierarchy (SPEC.md + STATE.md + task folders) is created by L2.

---

### Sub-path: LITE-FEATURE

**Purpose:** A small new feature. Unlike LITE-REFACTOR, there is no existing
behavior to serve as the spec — explicit AC elicitation is required. Extends
LITE-REFACTOR with additional AC prompts.

> **Documentation/report work** that creates a new doc or report routes here
> (e.g., `add-docs`, `add-report` recipes). When the work is a new doc/report,
> interpret `feature-title` as the document title, `goal` as audience + purpose
> (who will read it and what they will be able to do), and `scope` as the sections
> or topics the document must cover (the outline). Audience and outline intent
> is captured via the `goal` + `scope` prompts — documentation work has no separate sub-path.

**Questions (ask one per turn; wait for answer before asking next):**

1. **feature-title** — What is the short name of this feature?
   ```
   What is a short, descriptive name for this feature?
   (e.g., "Password reset via email", "Dark mode toggle")
   ```

2. **goal** — What is the goal of this feature?
   ```
   What does this feature do? What problem does it solve for users?
   ```

3. **scope** — What will be built?
   ```
   What will be built? Which components, endpoints, UI elements, or modules
   will be added or changed?
   ```

4. **ac-1** — Primary acceptance criterion: what must the feature do?
   ```
   What is the primary thing this feature must do?
   Complete the sentence: "Given {precondition}, when {action}, then {result}."
   ```

5. **ac-additional** — Are there more acceptance criteria?
   ```
   Are there additional acceptance criteria? List each as:
   "Given {precondition}, when {action}, then {result}."
   (Type "done" when finished.)
   ```

**SPEC.md shape for LITE-FEATURE:**

> **Identity block composition (MUST):** When writing the SPEC.md, the agent MUST compose:
> - **Name** — a concise Title-Case title from the work subject (no trailing period; NOT the `work_id` slug; derived from `feature-title`).
> - **Description** — exactly one sentence distilled from the captured problem/objective (derived from `goal`); no trailing period.
> These MUST be real values (not `*(pending)*`) at the moment of writing.

```markdown
# {feature-title}

- **Name:** {Name — Title Case title derived from feature-title, no trailing period}
- **Description:** {Description — one sentence from goal, no trailing period}
- **Work:** {work-NNN-name}
- **Created:** {today}
- **Source:** /aid-describe lite path — LITE-FEATURE
- **Status:** Draft

## Goal

{goal — one paragraph: what the feature does and the user problem it solves.}

## Context

**Scope:** {scope}

{KB references if relevant — cite by INDEX.md doc name}

## Acceptance Criteria

- [ ] {ac-1 in Given/when/then form}
{ac-additional entries, each as a checklist item}
- [ ] All §6 quality gates pass.

## Tasks

> Tasks live under `delivery-001/tasks/task-NNN/SPEC.md`; each task folder also contains
> `STATE.md` for mutable task state. The table below is the navigational index.

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | {feature-title} implementation |

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
| {today} | Initial lite-path SPEC created | /aid-describe LITE-FEATURE |
```

> Note: L1 writes `## Goal`, `## Context`, `## Acceptance Criteria`.
> `## Tasks` / `## Execution Graph` scaffold rows are placeholders — L2 overwrites them.
> The `delivery-001/` hierarchy (SPEC.md + STATE.md + task folders) is created by L2.

---

## Step 3: Write work-root SPEC.md

After all sub-path questions are answered, write `.aid/{work}/SPEC.md` using the
sub-path's shape above. Fill in all fields from the answers collected.

**Write immediately after the last question is answered. Do not batch.**

---

## Step 4: Update STATE.md

After writing SPEC.md, update `STATE.md ## Lifecycle History`:

```
| {today} | CONDENSED-INTAKE complete — SPEC.md written | /aid-describe CONDENSED-INTAKE |
```

---

## Advance

**CHAIN** → [State: TASK-BREAKDOWN] (continue inline).

The TASK-BREAKDOWN state (L2) reads the work-root `SPEC.md` and produces the
`delivery-001/` hierarchy (SPEC.md + STATE.md + tasks/task-NNN/{SPEC,STATE}.md) plus
the filled `## Tasks` and `## Execution Graph` sections of the work-root `SPEC.md`.

---

## Unit-testable cases

| Input (Sub-path + answers) | Expected SPEC.md output |
|---------------------------|------------------------|
| LITE-BUG-FIX + all 4 answers | `## Goal` + `## Context` (reproduction + intended-behavior) + `## Acceptance Criteria` — no Specify block |
| LITE-REFACTOR + all 4 answers | `## Goal` + `## Context` (before/after/scope) + `## Acceptance Criteria` |
| LITE-FEATURE + all 5 answers | `## Goal` + `## Context` + `## Acceptance Criteria` (explicit Given/when/then per AC slot) |
| Sub-path = LITE-BUG-FIX, SPEC.md already has `## Acceptance Criteria` | Skip intake; advance to TASK-BREAKDOWN |
| User types `/aid-describe escalate` before any question answered | `lite-to-full-escalation.md` invoked with no slots; `Path: escalated`; REQUIREMENTS.md scaffold created; next state = CONTINUE |
| User types `/aid-describe escalate` after answering 2 of 4 LITE-BUG-FIX questions | `lite-to-full-escalation.md` invoked with `bug-title` + `bug-description`; §1 Objective + §2 Problem Statement pre-seeded as Partial; next state = CONTINUE |

### Recipe-escalation pre-fill cases (task-029 scope)

| Input | Expected behavior |
|-------|------------------|
| `## Recipe Slots` absent (no recipe or recipe declined/aborted) | Step 1.5 is skipped entirely; full standard interview runs |
| `## Recipe Slots` present, `Status: abandoned`, 0 matching slots | Pre-fill notice printed ("no matching answers"); all sub-path questions asked normally |
| `## Recipe Slots` present, `Status: abandoned`, LITE-BUG-FIX, `bug-title` + `bug-description` present | Pre-fill summary shown; `bug-title` + `bug-description` skipped; `reproduction-steps` + `intended-behavior` asked |
| `## Recipe Slots` present, `Status: abandoned`, LITE-BUG-FIX, all 4 slots present | Pre-fill summary shows all 4 values; no interactive prompts; SPEC.md written from pre-filled values |
| `## Recipe Slots` present, `Status: abandoned`, LITE-FEATURE, `feature-title` + `goal` present; `scope` absent | `feature-title` + `goal` pre-filled; `scope`, `ac-1`, `ac-additional` asked |
| `## Recipe Slots` present, `Status: abandoned`, recipe slot name does NOT match any known sub-path slot | Unknown slot ignored; corresponding sub-path question asked normally |
| Pre-filled via recipe, user then types `/aid-describe escalate` | `lite-to-full-escalation.md` invoked; carried slots include both pre-filled recipe values AND any newly-answered values; `## Escalation Carry` block written; `Path: escalated`; next state = CONTINUE |
