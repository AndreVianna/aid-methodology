# Delivery BLUEPRINT -- delivery-001: Mechanism -- declarations exist and are read

> **Delivery:** delivery-001
> **Work:** work-004-frontmatter-review-criteria
> **Created:** 2026-08-13

---

## Objective

Make review criteria declared data that agents actually read. This delivery builds the
`review-criteria:` schema, authors the global and per-document-type criteria lists in the KB, and
edits every surface that reads or writes a file so it resolves those criteria first. It is scoped as
its own delivery because nothing in the next two streams has any effect until the declarations exist
and something reads them -- populating files (delivery-002) or retiring guards (delivery-003) against
a mechanism that no agent consults would repeat the exact failure this work fixes.

## Scope

Feature-001, all 8 technical-spec sections:

- The `review-criteria:` field schema and the two KB tables (type registry + criteria, levels 1-2) in
  `.aid/knowledge/authoring-conventions.md`.
- Generalize `kb-authoring/review-rubric.md` item 3 beyond `.aid/knowledge/`; define the field in
  `frontmatter-schema.md` for all four trees and split it out of the "stay fully exempt" legacy list.
- The readers: `aid-reviewer/AGENT.md`, `reviewer-dispatch.md`, `reviewer-ledger-schema.md`, the **6**
  per-skill `reviewer-brief.md`, and the FIX contract in `aid-execute/references/state-fix.md` (FR-3).
- The writer-side instruction (FR-9/FR-10) in `agent-boilerplate.md` **and** the 5 hand-authored
  `profiles/<tool>/{CLAUDE,AGENTS}.md`.
- `render.py` carry-through of `review-criteria:`.
- The severity reconciliation to one authority (`grading-rubric.md`).
- The rename's code half: the 5 emitters (+ the `.ps1` twin), the migration parser, the 4 definition
  docs, and the 2 script test-suites.
- Create `.aid/works/work-004-frontmatter-review-criteria/imports-from-work-003.md`.

**Out of scope:** populating the 290 files, deleting the READMEs, the on-disk data rename of the KB
docs/fixtures (all delivery-002); any render or dogfood resync (delivery-003).

## Gate Criteria

- [ ] `authoring-conventions.md` carries the type registry (mutually exclusive + exhaustive, incl. the
      `skill-generated`/`skill-authored` and `template-payload`/`template-own` splits) and the criteria
      table, each criterion carrying its own severity.
- [ ] `review-rubric.md` item 3 resolves all three levels and is no longer KB-only; the field is
      defined for all four trees and is no longer in the "fully exempt" list (with `intent:`/`changelog:`
      retained).
- [ ] All 6 `reviewer-brief.md`, the reviewer AGENT, dispatch template, and ledger schema route to the
      declaration; a finding cites the criterion `id` as a `Description` prefix with the ledger still 7
      columns and `grade.sh` unmodified.
- [ ] `agent-boilerplate.md` and the 5 profile context files carry the resolve-before-writing (FR-9) and
      new-document-type (FR-10) instructions.
- [ ] The rename's code half holds: emitters (incl. `.ps1` twin) emit the new key, the migration parser
      accepts both names, the 2 script test-suites pass.
- [ ] **AC-2 proof (writer + reviewer)** passes in a disposable worktree per NFR-1.
- [ ] No new linter/validator/CI check added (C-1); stream-1 edits additive and localized (NFR-3).
- [ ] All section-6 quality gates pass.

## Tasks

*Defined by `/aid-detail`.*

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** delivery-002

## Notes

No render happens here -- the field-carry-through in `render.py` is authored but not run; the derived
trees stay stale until delivery-003 (C-2 / NFR-4). Keep every edit additive to limit the `work-003`
collision surface (26 shared files).
