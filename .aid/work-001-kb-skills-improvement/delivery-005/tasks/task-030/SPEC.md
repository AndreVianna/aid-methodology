# task-030: test-actback-task.sh canonical suite + ascii-only allow-list

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-005

**Depends on:** task-028

**Scope:**
- Author the NEW canonical suite `tests/canonical/test-actback-task.sh` (auto-discovered by
  `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob) asserting `kb-actback-task.sh` (task-028) over
  a small, in-suite, ASCII fixture:
  - **Representative-task selection** is emitted **deterministically + byte-reproducibly** over the
    machine-readable substrate (a fixed `discovery.doc_set` filename+presence shape + the operational
    sections present): same input -> byte-identical task spec on re-run.
  - **Operational-structure presence check** reports `present` for the named operational sections
    (`## Conventions`/`## Invariants`/`## Gotchas`/`## Contracts`) when present and `absent` when
    omitted/prose-buried, **scoped to the classes each doc is expected to own** (a doc owning no class
    X is NOT reported `X absent`).
  - The suite copies the fixture into a `mktemp -d` scratch before any script runs (the committed
    fixture is a static read-only input; nothing is written/harvested at run time).
- Confirm `kb-actback-task.sh` is on `test-ascii-only.sh`'s `SHIPPED_SCRIPTS` allow-list (the allow-list
  entry is added in task-028; this suite asserts the script passes the ascii-only gate).

**Boundary (this suite EXERCISES, does not RE-SPEC):** it does NOT author/edit `kb-actback-task.sh`
(task-028), the doc-model owning-table (task-027), or the M6 panel wiring (task-029) -- it runs the
shipped helper over an in-suite fixture and asserts its two mechanical functions. The **end-to-end
act-back fixture** (the `actback-pass-kb`/`actback-fail-kb` pair + the representative-task spec fixture)
and its **judgment-anchored V-E assertions** are **delivery-006 / f012**'s ([SPIKE-A5]); this task
ships only the helper's small in-suite unit fixture and must not duplicate/diverge from f012's corpus.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-actback-task.sh` exists, is auto-discovered by `tests/run-all.sh`, and is
  deterministic with clean setup/teardown (fixture copied into `mktemp -d`; no committed fixture
  mutated).
- [ ] Asserts `kb-actback-task.sh`'s representative-task selection is byte-reproducible over the
  in-suite fixture (re-run yields identical bytes).
- [ ] Asserts the operational-structure presence check reports `present`/`absent` correctly per the
  named sections, scoped to expected classes (no over-report of legitimately-absent classes).
- [ ] Asserts `kb-actback-task.sh` is on `test-ascii-only.sh`'s allow-list and passes the ascii-only
  gate.
- [ ] No reference to the delivery-006/f012 end-to-end pass/fail-KB corpus or the V-E family (those are
  f012's; this is the helper's unit suite only).
- [ ] All section-6 quality gates pass (TEST defaults: deterministic, clean setup/teardown, all task-028
  acceptance criteria covered).
