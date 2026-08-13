# task-004: Reader surfaces — reviewer, dispatch, ledger schema, briefs, FIX contract

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-001

**Depends on:** task-002, task-003

*(Depends on task-003 not only for the schema but because task-003 also edits
`aid-reviewer/AGENT.md` and `reviewer-ledger-schema.md` — the same two files this task edits, in
different sections. The edge serializes them so a parallel wave cannot clobber the shared files.)*

**Scope:**
- `canonical/agents/aid-reviewer/AGENT.md`: instruct it to (a) verify a file against its **resolved**
  criteria (global → type → file), (b) cite the criterion `id` in the finding's `Description`, (c) when
  a finding is written against an **overridden** criterion, record the **resolved severity and the
  overriding file's `why` in the finding's `Evidence` cell** (FR-6 override surfacing — the owner-decided
  behavior; no `grade.sh` change, the `Evidence` cell is already inert to grading), and (d) treat a
  finding that cites **no id, or an id that resolves nowhere, as itself a defect** (the reviewer invented
  a criterion).
- `canonical/aid/templates/reviewer-dispatch.md`: route the dispatched reviewer to read the artifact's
  own frontmatter.
- `canonical/aid/templates/reviewer-ledger-schema.md`: document the `id`-as-`Description`-prefix
  convention **and** the override-in-`Evidence` recording; keep the 7-column shape.
- All **6** `canonical/skills/*/references/reviewer-brief.md` (`define`, `detail`, `execute`, `plan`,
  `specify`, `discover`): name the declaration the reviewer must read. (Distinct from the 5-of-6 that
  cite `grading-rubric.md` for severity — do not conflate.)
- `canonical/skills/aid-execute/references/state-fix.md` (FR-3): F1–F6 gain post-edit re-verification of
  the edited file's own `review-criteria:`.

**Acceptance Criteria:**
- [ ] The reviewer AGENT resolves all three levels and cites the `id`; the ledger stays 7 columns.
- [ ] The reviewer records an override's resolved severity + `why` in the `Evidence` cell (FR-6); no
      `grade.sh` change.
- [ ] A finding citing no id, or an id that resolves nowhere, is defined as itself a defect.
- [ ] The dispatch template and ledger schema route to the declaration rather than restating it (FR-4).
- [ ] All 6 briefs name the declaration; `discover` is included.
- [ ] `state-fix.md` requires re-verifying the edited file's own declaration after the edit.
- [ ] Additive/localized (NFR-3); no new mechanism (C-1). All §6 quality gates pass.
