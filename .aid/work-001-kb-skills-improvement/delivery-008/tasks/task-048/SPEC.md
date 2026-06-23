# task-048: housekeep <-> update-kb boundary contract record

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-008

**Depends on:** task-043 (delivery-007)

**Scope:**
- f010 Part 1 (FR-33, AC10) + Part 4 (durable artifact) -- record the non-overlapping
  `aid-housekeep` (KB-DELTA, source-driven/global) <-> `aid-update-kb` (prompt-driven/targeted)
  boundary as a durable, routable KB artifact. This task records the contract ONLY; the
  `state-kb-delta.md` scoping/closure rewrite is task-049 and the behavioral guards are task-050.
- **SPIKE-K1 resolved (record during /aid-detail):** the canonical KB doc that owns skill topology
  and the per-skill slash-command contracts in this repo is
  `.aid/knowledge/pipeline-contracts.md` (it already carries the `/aid-housekeep` contract entry
  and the 12-skill topology; the SPEC's "adopter-facing vs this-repo KB" distinction is moot here
  because f010 edits this repo's own `.aid/knowledge/`). Append the boundary contract there.
- **Cross-delivery dependency (cite explicitly):** the contract documents the boundary AROUND the
  already-shipped `aid-update-kb` skill authored in **task-043 (delivery-007, f008)** -- this task
  draws the boundary, it does NOT author or re-spec `aid-update-kb` (f008 owns the skill body and
  its own DONE closure re-verify).
- **Boundary record (in `pipeline-contracts.md`):** append the 7-dimension contract table verbatim
  to the SPEC's Part 1 shape (rows: Driver / Scope / Trigger / Question-it-answers /
  Shared-signal-the-divider / Gate / Closure), the "shared signal -- per-doc staleness (f007)"
  note (both skills read `kb-freshness-check.sh`'s `{current,suspect,unknown}` verdict but for
  opposite purposes -- housekeep = scope-defining input, update-kb = confirmation filter), and the
  four no-overlap guarantee rules (no prompt -> not update-kb; whole-KB reconcile -> not update-kb;
  targeted named delta -> not housekeep; the divider is recorded not just asserted). The Closure
  row records BOTH halves: housekeep re-verifies `closure-check.sh` before committing
  (new in f010, wired by task-049) and update-kb re-verifies before committing in DONE (f008,
  task-043, existing -- referenced not duplicated).
- **Skill description cross-refs (Part 4 item 2):** add a one-line boundary cross-reference to
  `canonical/skills/aid-housekeep/SKILL.md` `description:` ("source-driven global reconcile; for a
  targeted prompt-named delta use `/aid-update-kb`"). The reciprocal line in
  `aid-update-kb`'s description is f008's edit (task-043) -- NOT made here.
- **Edits canonical source + this repo's KB only.** Editing `canonical/skills/aid-housekeep/SKILL.md`
  leaves render-drift RED on the f010 branch by construction; f009 runs the generator (out of scope).
- ASCII-only (C2): no non-ASCII glyphs introduced into the KB doc or the SKILL.md description.

**Acceptance Criteria:**
- [ ] `.aid/knowledge/pipeline-contracts.md` contains the boundary contract table with all 7
  dimensions (Driver, Scope, Trigger, Question-it-answers, Shared-signal, Gate, Closure) and both
  columns (`aid-housekeep` (KB-DELTA), `aid-update-kb`), matching the SPEC Part 1 table.
- [ ] The contract record states the shared signal is f007's `kb-freshness-check.sh` per-doc
  `suspect` verdict, read by housekeep as a scope-defining input and by update-kb as a
  confirmation filter (the non-overlap rationale).
- [ ] The contract record states all four no-overlap guarantee rules (no prompt -> not update-kb;
  whole-KB reconcile -> not update-kb; targeted named delta -> not housekeep; divider recorded).
- [ ] The Closure dimension records both halves: housekeep re-verifies `closure-check.sh` before
  committing (f010) and update-kb before committing in DONE (f008/task-043, referenced).
- [ ] `canonical/skills/aid-housekeep/SKILL.md` `description:` carries the one-line cross-reference
  pointing a targeted prompt-named delta to `/aid-update-kb`.
- [ ] The cross-delivery dependency on task-043 (delivery-007, the shipped `aid-update-kb` whose
  boundary this draws) is cited in the contract record; `aid-update-kb` is not re-spec'd here.
- [ ] After the KB edit, `.aid/knowledge/INDEX.md` is regenerated if the summary/anchors changed
  (canonical regen path, not the `.claude/` copy).
- [ ] Edited KB doc and SKILL.md description are ASCII-only.
- [ ] All section-6 quality gates pass.
