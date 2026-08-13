# task-010: KB docs — correct the empty declarations and disposition the field-less two

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-002

**Depends on:** task-008, task-009

*(Depends on task-009 so the canonical-tree slice is done first: this task owns the delivery-wide 290
reconciliation, which needs task-009's per-bucket counts; the edge also removes the
`reviewer-ledger-schema.md` ownership ambiguity — task-009 excludes it, this task owns its content.)*

**Scope:**
- The 8 in-scope KB docs at `contracts: []` (9 on disk; `external-sources.md` carved out): each declares
  real criteria or states why it legitimately has none.
- The 8 already-declaring artifacts — **7 KB docs + `reviewer-ledger-schema.md`** (the latter a
  `canonical/aid/templates/` file, not a KB doc; its **content** is verified here, its key **rename** is
  task-011): **verify against disk**, do not assume — a stale existing declaration is the worst case.
- The two field-less in-scope KB docs: `capability-inventory.md` (`source: generated`) → build-verify,
  no file-level block; `release-tracking.md` (extension log) → a file-level `exclude` (rows are
  historical, not validated against current state) with its `why`.

**Acceptance Criteria:**
- [ ] No in-scope KB doc is left at bare `contracts: []`; each declares or states why none.
- [ ] Each of the 8 already-declaring docs is verified true against disk (or corrected).
- [ ] `capability-inventory.md` has no drift-block; `release-tracking.md` carries the historical-log
      exclusion.
- [ ] KB buckets reconcile: 7 declare + 10 declare-nothing = 17 in-scope KB + 5 carved = 22.
- [ ] **Delivery-wide bucket invariant (BLUEPRINT Gate 2 / SPEC AC-1):** combining task-009's
      canonical-tree counts with this task's KB counts, the full 290-file population reconciles to
      **159 no-block + 123 declares-nothing + 8 declares = 290**, carve-outs netted out of the buckets
      (not only the total). This task owns the aggregate check.
- [ ] All §6 quality gates pass.
