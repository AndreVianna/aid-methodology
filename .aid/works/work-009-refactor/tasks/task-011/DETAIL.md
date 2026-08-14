- Compared fields, at minimum: lifecycle, phase, active skill, updated, delivery state, gate
  tier/grade/timestamp, per-task state/review/elapsed/notes/display-name, lifecycle-history rows,
  Q&A entries, and the derived counts and percentages.
- Fixtures and the golden baseline are self-contained test assets -- no work folder's contents are
  an input (a work folder is transient, `C-6`), and no live work tree is read.
- OUT of this task: the subset/reject-list corpus (task-005); edits to existing suites (task-016);
  `test-migrate-hierarchy.sh` and `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/`
  (both triaged OUT and left untouched).

**Acceptance Criteria:**
- [ ] The golden baseline exists as a committed fixture payload, produced by the **pre-refactor**
      Python and Node readers over the legacy-markdown fixture tree, with those two payloads
      recorded as equal on every field enumerated in Scope and neither raising a `parse_warning`
      (SP-8 leg a).
- [ ] For the flat fixture, both **post-refactor** twins' reads of the converted tree equal the
      committed golden baseline on every field enumerated in Scope, with no `parse_warning` from
      either (SP-8 leg b).
- [ ] For the full-layout fixture, the same baseline equality holds, including the per-delivery and
      per-task file levels (SP-8 leg b).
- [ ] Reading the **unconverted** legacy tree with both post-refactor twins returns the
      minimal-model degradation and the same `parse_warning` naming the file and the migration
      command in both runtimes -- asserted as the required outcome, not tolerated as a shortfall
      (SP-8 leg c, SP-9, AC-5).
- [ ] The committed suite resolves no repo git history at run time; the pre-refactor capture is a
      recorded one-time authoring step of this task (CI clones shallowly).
- [ ] Derived counts and percentages in both post-refactor converted-tree payloads match the
      golden baseline's, proving no rollup was persisted by the conversion (SP-3, C-8).
- [ ] The suite builds its own fixtures, reads no live work tree, is deterministic, needs no
      network, and cleans up its temp state (`task-type-rules.md § TEST`).
- [ ] The suite runs under `python -m pytest dashboard/reader/tests dashboard/server/tests` with no