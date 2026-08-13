# task-001: KB criteria system — imports log + the two authoring-conventions tables

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Create `.aid/works/work-004-frontmatter-review-criteria/imports-from-work-003.md` with §8's three
  collision figures as its first entries (each: fact, requirement served, where re-derived).
- In `.aid/knowledge/authoring-conventions.md`, add two new sections after `## KB Document Layout`:
  - a **type registry** table (`| Type | Selector | Notes |`) whose selectors are mutually exclusive
    and exhaustive over the in-scope corpus, including the splits `skill-generated` (58) /
    `skill-authored` (18) and `template-payload` / `template-own`, plus `kb-doc`, `skill-reference`,
    `agent`, and `state` (excluded, cites `G-04`);
  - a **criteria** table (`| ID | Applies to | Kind | Criterion | Severity | Why |`), one row per
    criterion, `*` = global; seed the global level (drift-prone counts, durable citations, resolved
    items) re-authored at project scope, and each type's level-2 criteria. No cell contains a pipe.
    The global level MUST include:
    - the two global **exclusions**: `agent-context` (root `CLAUDE.md`/`AGENTS.md` never reviewed) and
      `rendered` (keyed on **provenance, two limbs** — (a) a `dst` in an emission manifest, or (b) under
      `profiles/<tool>/` **with** a `canonical/` source; never a bare path glob, so the repo-local
      dogfood carve-outs and the 5 hand-authored profile context files stay reviewable), each with its
      `why`;
    - the **FR-10 backstop** criterion on `authoring-conventions.md` itself: *every in-scope file
      resolves to exactly one registry row.*
- Do not touch the frontmatter schema, the rubric, or any reader/writer surface (later tasks).

**Acceptance Criteria:**
- [ ] `imports-from-work-003.md` exists with the three §8 entries, each naming the requirement it serves.
- [ ] The type registry resolves **every** in-scope file to exactly one type (exhaustive + mutually
      exclusive), verifiable by walking the selectors against the trees.
- [ ] The criteria table has one row per criterion, carries a severity on every `validate` row and none
      on any `exclude` row, and no row restates another at a more specific level.
- [ ] The two global exclusions (`agent-context`, two-limb `rendered`) and the FR-10 backstop criterion
      are present as rows, each `exclude`/backstop carrying its `why`.
- [ ] No markdown table cell contains a pipe; every criterion is derivable from the repo alone (NFR-5).
- [ ] Edit is additive/localized to `authoring-conventions.md` (NFR-3); no new script or gate (C-1).
- [ ] All §6 quality gates pass.
