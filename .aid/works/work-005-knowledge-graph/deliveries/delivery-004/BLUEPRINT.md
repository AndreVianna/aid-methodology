# Delivery BLUEPRINT -- delivery-004: Accessible View

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-004
> **Work:** work-005-knowledge-graph
> **Created:** 2026-07-28

---

## Objective

This delivery produces `.aid/knowledge/graph.html` as a working artifact: the page shell, the
lens and control layer both renderings consume, and the accessible peer table view. It is a
functional deliverable on its own, and deliberately so — NFR-2 makes the table a **peer** view
rather than a fallback, and for the verification work this artifact exists to support ("which
rows are unbacked") a filterable, sortable, keyboard-navigable list is often the better tool than
a picture. A reader can open the file, apply any of the four preset lenses, and work the data
before the canvas exists.

It is scoped as a distinct unit because neither feature is blocked by the rendering research:
feature-007's Dependency position states the shell, the data loader and the lens layer are
independent of the rendering-approach decision, and feature-009's states the table rendering
needs no rendering decision at all. That decoupling is the reason the table view is a separate
feature from the canvas, and it is what lets the WCAG AA bar have a named owner rather than being
a footnote on a drawing feature.

## Scope

**In scope:**

- **feature-007-graph-view-shell** — `graph.html` as the documented entry point (a local
  `file://` open, per STATE.md Q5), the `relationships.md` loader, the lens view-model as a
  first-class contract with defined inputs and outputs, the four preset lenses (Coverage,
  Overview, Impact, Provenance), the always-live manual controls (grouping, density, filter,
  zoom), the `kb_gaps` verification at load time with a loud failure on mismatch, and zero-row
  node materialisation as complete `Node` records.
- **feature-009-accessible-table-view** — the peer table rendering: sortable, filterable,
  keyboard-navigable, screen-reader usable at WCAG AA, with the zero-row region for enumerated
  `int:` nodes that have no edge (the main table is one row per edge, so those nodes would
  otherwise have no representation at all — an NFR-2 break at exactly the FR-19/FR-20 case that
  matters most), and meaning never carried by colour alone.
- **The GV-series assertions in `tests/canonical/test-graph-view-shell.sh`**, including the three
  that assert against delivery-003's `coverage-predicate.mjs` (see below).

**Out of scope:** nothing is deferred from this work. Specifically excluded from *this delivery*:
the interactive graph canvas and its layout, reduced-motion settling, and keyboard zoom/pan
(feature-008, delivery-005); the rendering-approach decision itself (feature-002, delivery-001);
creating `coverage-predicate.mjs` (feature-006's delivery-003 does that, per the owner decision
below); adding a dashboard route for `graph.html` (STATE.md Q5 — the dashboard's leaf allowlist
admits only `home.html` and `kb.html` and its CSP is `default-src 'self'`, so a route is a
separate change to the dashboard).

## Owner decision recorded here: `coverage-predicate.mjs` was created in delivery-003

`feature-007` owns the **file** `canonical/aid/scripts/graph/coverage-predicate.mjs` — its
boundary rules, its exports, and how each runtime reaches it — while `feature-006` owns the gap
predicate's **semantics**. Because the file is a Node script rather than view code, sitting beside
`scan-source.sh` and `detect-kb-gaps.mjs` under `canonical/aid/scripts/graph/`, **the ledger
deliverable (delivery-003) creates it, authored to this feature's contract**. feature-006's own
Migration step 1 already assumes it exists, and its detector imports it directly. feature-006's
Dependency position names only features 004 and 005 and does not mention this, so the plan is
where it becomes visible; the mirror note is recorded in delivery-003's BLUEPRINT.

**This delivery is where the byte-identity assertions run**, because the view is what inlines the
module:

- **GV02** — the module's inlined region in a generated `graph.html` is byte-identical to the
  `coverage-predicate.mjs` **of the tree that generated it** (`<install-root>/aid/scripts/graph/…`,
  never a hard-coded `canonical/…` path). `graph.html` is a run-time artifact written by the
  installed tree's own scripts, so same-tree is the only basis under which the comparison means
  "the browser runs what the generator ran".
- **GV04** — `COVERAGE_BEARING` in the module equals feature-006's recorded subset beside the
  vocabulary artifact.
- **GV08** — every rendered copy of the module under `profiles/` is byte-identical to the
  canonical file, which is the fixed-point property boundary rule 5 buys.

GV02 and feature-006's GL09 are complementary, not duplicates: GL09 asserts the ledger, the
frontmatter and a from-rows recomputation are the same set on the Node side; GV02 asserts the
browser is running the same bytes that produced it.

## Gate Criteria

- [ ] **AC-6** — opened by its documented entry point, the artifact renders the graph
      successfully, and its runtime prerequisites (network access, companion asset files, or a
      build output) are documented explicitly. The prerequisite statement is the one
      delivery-001's rendering decision record wrote as prose; this is where it is checked.
- [ ] **AC-7 closes in this delivery** — all four preset lenses are present, each visibly changes
      the view, and each applies to **both** renderings. **Shared: feature-007 owns the
      criterion, feature-009 owns the table side** (both features are in this delivery, so the
      mutual obligation is discharged here). feature-008's graph half is exercised in
      delivery-005 against the same lens view-model and must not reinterpret it.
- [ ] **AC-8** — grouping, density, filter and zoom controls remain usable after arriving via a
      preset; a preset is an entry point, not a mode that locks the view.
- [ ] **AC-9 is satisfied on the table and structural side and does NOT close in this delivery.**
      feature-009 owns the criterion overall — the view passes the existing structural and
      accessibility checks at WCAG AA, and the table view is keyboard-navigable and
      screen-reader usable. **Its reduced-motion clause is owned by feature-008 in delivery-005**,
      and neither owner may consider the criterion met alone, so **AC-9 closes overall in
      delivery-005**.
- [ ] **AC-10** — the view renders from `relationships.md` alone, with no second extraction path.
      This holds including the zero-row case, because `kb_gaps` lives in `relationships.md`'s own
      frontmatter, so the view still reads exactly one artifact.
- [ ] **AC-15 is satisfied on the view side and does NOT close in this delivery.** The Coverage
      lens surfaces exactly the gaps the ledger records. **feature-006 owns the criterion
      (delivery-003) and feature-008 owns the graph side (delivery-005)**; all three SPECs state
      that neither owner may consider it met alone, so **AC-15 closes overall in delivery-005**.
      The equality binds the `int:` class only — unbacked `kb:` nodes are a lens-only signal with
      no corresponding ledger row, and their presence does not breach the criterion.
- [ ] No one of the four purposes is privileged as the default layout (FR-15), and relation
      category from delivery-001's vocabulary is available as a grouping dimension (FR-6).
- [ ] The lens view-model is explicit enough that features 008 and 009 interpret each lens
      identically — the contract, not the first rendering built, is what defines a lens.
- [ ] **`tests/canonical/test-graph-view-shell.sh` passes GV01–GV08**, and in particular:
      **GV02** (same-tree byte identity of the inlined region), **GV04** (`COVERAGE_BEARING`
      equals feature-006's recorded subset), **GV08** (every `profiles/` copy byte-identical to
      canonical) — the three assertions on delivery-003's file, now runnable because the view
      exists to inline it; **GV03** (bare-Node import returns the expected set over a fixture);
      **GV05** (`COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)`); **GV06** (a deliberately wrong
      `kb_gaps` reports the exact `viewOnly`/`ledgerOnly` ids while both renderings still mount);
      **GV07** (a zero-row `kb_gaps` entry yields a complete `Node` carrying the entry's `name`,
      `degree === 0`, `coverageOrigin === 'ledger-only'`, no mismatch alarm, presence at
      `density: 1`, membership of the `no relationships` group, and a row in feature-009's
      zero-row region).
- [ ] The reused validators behave as feature-011 parameterised them in delivery-002: `kb.html`
      keeps every check unchanged, and any graph exemption is per-artifact and parameterised
      rather than achieved by weakening the shared script.
- [ ] All section-6 quality gates pass: the delivery gate's `grade.sh` run over
      `.aid/.temp/review-pending/` reaches this repository's resolved `minimum_grade` of **A+**
      (`review.minimum_grade` in `.aid/settings.yml`; this work's `minimum_grade: "A+"`), i.e.
      zero findings with Status `Pending` or `Recurred`.

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-002 (feature-003's schema, which feature-007 renders from, and
  feature-005's real data); delivery-003 in practice, for `coverage-predicate.mjs` and the
  `kb_gaps` record the GV-series asserts against
- **Blocks:** delivery-005 (feature-008 mounts in this shell and consumes this lens view-model),
  delivery-006

## Notes

- **The lens view-model is a first-class contract, not a by-product.** Both feature-007 and
  feature-009 say so: a loose interface here is the direct route to violating NFR-3 and AC-7 at
  integration time, because the two renderings will drift into interpreting the same lens
  differently. It must be specified as a named contract with defined inputs and outputs before
  either rendering is built.
- **The prior art agrees with the architecture already chosen.** The research feature-002
  gathered recommends maintaining an accessibility model alongside the visual model — a plain
  data structure decoupled from drawing, read by both the renderer and the accessibility layer,
  so it survives a renderer swap. Here that model *is* feature-007's lens view-model over
  `relationships.md`, which is why NFR-2's peer table adds no second data path.
- **The standing risk the prior art names is keeping the table and the chart in sync.** The
  single view-model plus the GV-series parity assertions are the mitigation.
- **Coverage is not on the consumer surface.** `coverageGaps` and `coverageOrigin` reach features
  008 and 009 as `ViewModel` fields; the functions that produce them live in
  `coverage-predicate.mjs`, which the renderings never call directly.
