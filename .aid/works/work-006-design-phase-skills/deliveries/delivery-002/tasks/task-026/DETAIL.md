# task-026: FR-10's single additive seed read in the shortcut engine

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-026/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-020

**Scope:**
- Source spec: `features/feature-005-design-grid-and-brainstorm/SPEC.md` §4a (where the read
  goes and why CAPTURE rather than INTAKE), §4b (the reach, stated rather than left implicit),
  §3c (the `query`-paragraph extension), and §1's table rows `c`. It consumes feature-002 §4's
  seed shape, which that spec **freezes** once this feature starts.
- **This is the first task of the delivery, and the ordering reason is read/write, not risk.**
  Every one of the twenty-seven bodies this delivery authors is modelled on
  `canonical/skills/aid-design/SKILL.md` (feature-002 §3e), whose frontmatter task-028
  rewrites, and task-028's routing text must match the clause task-027 writes into
  `canonical/skills/aid-create-document/SKILL.md`. So feature-005's three *edit-what-exists*
  tasks run ahead of the new doorways rather than beside them. The cross-delivery edge is to
  **task-020**, delivery-001's leaf: its audit reads `canonical/aid/templates/` whole, so a
  write into that tree before it runs would corrupt what it audits.
- Add **one** bullet to `canonical/aid/templates/shortcut-engine.md`, inside
  **State: CAPTURE -> Step 2: Read context** (`:379` is that heading; the two existing
  optional-context bullets follow it and already carry the "if it does not exist, fall back
  unmodified" idiom). Its content is fixed verbatim by feature-005 §4a: `.aid/design/{artifact}.md`,
  read **if it exists and `{artifact}` is non-empty**, as PRIOR CONTEXT for the slot set of
  Step 3; an input to the write-up, **never a substitute** for it; **never edited, moved or
  deleted** by the run; and if the file is absent or `{artifact}` is `""`, CAPTURE proceeds
  exactly as before.
- Extend the `query` paragraph (`:191-194`) to name `design` alongside `query` as a family
  deliberately absent from the **Current verb -> family-file groupings** table (header `:183`,
  rows `:185-189`). This is a **comment-only** edit and nothing behavioral rests on it: the
  engine already states the fallback at `:175-176` with its mechanism at `:206`, and ten of the
  catalog's eighteen verbs are absent from that table today. Its purpose is to stop a later
  reader from reading the gap as an oversight and "fixing" it once the `design` family grows
  from one row to CC-7's figure.
- Three properties bound the change, and they are what the criteria measure rather than
  restate: **conditional** (absent seed ⇒ byte-identical behavior), **non-mutating** (no write
  path is added), **additive** (no existing bullet, rule or state transition is altered).
- Out of scope: any `design` or `brainstorm` entry in the verb->family table, and any
  `canonical/aid/templates/shortcut-scaffolding/design.md` (feature-002 §1e owns that scope
  decision); the two hand-authored `document` doorway reads (task-027); and the behavioral
  additivity comparison (task-047), which cannot run before the render.

**Acceptance Criteria:**
- [ ] feature-005 V12, this task's share:
      `grep -c '\.aid/design/{artifact}\.md' canonical/aid/templates/shortcut-engine.md` captured
      to a variable -> `1`. The two `document` files are task-027's share of the same row
- [ ] feature-005 V13: `git diff --numstat master -- canonical/aid/templates/shortcut-engine.md`
      shows **0 deletions**, and the added lines fall in exactly **two** hunks -- the CAPTURE
      Step 2 bullet and the `query`-paragraph extension. Non-zero deletions mean an existing
      rule was altered. `master` is named as the base ref because this task edits the file, so a
      whole-file `git diff --exit-code` is unsatisfiable by construction
- [ ] The bullet lands inside CAPTURE Step 2 and nowhere else. Capture three line numbers:
      `S = grep -n '^### Step 2: Read context'` (today `:379`),
      `B = grep -n '\.aid/design/{artifact}\.md'`, and
      `T = grep -n '^### Step 3: Determine the minimal slot set'` (today `:388`); assert
      `S < B < T`. A bare `grep -q` would pass on a bullet added to INTAKE, which feature-005
      §4a rejects by name
- [ ] **Conditional, with both halves present.** The bullet's own text carries the absent-file
      fallback **and** the empty-`{artifact}` fallback: within the bullet,
      `grep -c 'is non-empty'` and `grep -cF 'proceeds exactly as before'` each return `1`. A
      bullet guarded only on existence fires on the eight bare generated doorways whose
      `artifact` is `""`
- [ ] **Non-mutating, asserted over the file rather than over the bullet's intent:** the bullet
      states the seed is not edited, moved or deleted, and the diff adds no `Write`, `Edit`,
      `rm` or deletion instruction anywhere in the file
- [ ] No family-file entry is minted and no scaffolding file is written: the verb->family table
      carries the same rows after this task as before (`git diff master --` shows no hunk between
      `:183` and `:189`), and `test ! -f canonical/aid/templates/shortcut-scaffolding/design.md`
      holds
- [ ] The `query`-paragraph edit is an **extension, not a replacement**: after it, the paragraph
      that today opens at `:191` with `` `query` (the `aid-ask` `repurpose: true` row) `` still
      contains the literal `aid-ask` **and** the literal `query`, and now also contains `design`.
      Asserted over that paragraph's own text -- a bare `grep -q 'design'` over the whole file
      passes trivially, since the file already names the verb elsewhere
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean (feature-001 AC-3's
      standing guard) and `git status --porcelain profiles/ .claude/ .cursor/` is clean -- the
      render is delivery-003's, and no profile copy of the engine is edited here
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
