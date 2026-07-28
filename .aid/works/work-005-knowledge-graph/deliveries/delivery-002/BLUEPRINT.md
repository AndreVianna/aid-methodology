# Delivery BLUEPRINT -- delivery-002: Relationship Table

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-002
> **Work:** work-005-knowledge-graph
> **Created:** 2026-07-28

---

## Objective

This delivery produces an installed, rendered `/aid-graph` that emits a validated
`relationships.md`. It is the functional MVP REQUIREMENTS.md §10 identifies as deliverable 2:
"a functional MVP on its own — it delivers verification, impact analysis, and agent-routable
structure with no view at all, because the table is readable as markdown. Nearly all the value
and nearly all the risk live here — the extraction, the identity scheme, and the significance
rule." A user can invoke the skill, get a table, and route over it before any view exists.

Six features combine here. feature-012 puts the skill and its script area into the canonical
tree and out to all five host profiles; feature-011 wires the reused `/aid-summarize` HTML
toolchain and parameterises the shared validator rather than forking it; feature-004 enumerates
the project source by structural significance in a single scanner walk; feature-005 consumes that
walk's streams to produce rows in two passes; feature-003 fixes the eight-column shape and the
validators that decide conformance; and feature-010 is the skill itself — preflight, staleness,
the read-only fence, and the FR-28 gate rubric.

## Scope

**In scope:**

- **feature-012-canonical-registration** — canonical authoring of `/aid-graph` and its
  `canonical/aid/scripts/graph/` area, the full profile render, the emission manifests, and the
  count/roster reconciliation that a 112th skill forces.
- **feature-011-validator-parameterisation** — invoking `/aid-summarize`'s existing assembler,
  contrast checker, HTML-output validator and Playwright visual validator rather than forked
  copies; the two contingent carve-outs (`S2` only under CDN packaging, `validate-visuals.mjs`
  T2 only for an SVG live surface), expressed by parameterisation; graceful degradation when the
  browser is not provisioned.
- **feature-003-relationship-table-schema** — the eight-column contract, the `kb:`/`int:`/`ext:`
  id grammars, the KB frontmatter, the `rel_load_vocabulary` loader over delivery-001's
  vocabulary file, and the `V1`–`V12` validators in `validate-relationships.sh`.
- **feature-004-source-enumeration** — `canonical/aid/scripts/graph/scan-source.sh`, the single
  traversal that decides structural significance, applies the FR-22 exclusions (generated and
  derived trees, vendored code, `graph.ignore`), holds whole-artifact granularity, and enforces
  the `no-inferred-node` invariant.
- **feature-005-two-pass-extraction** — the deterministic pass over the scanner's streams
  (`declared` / `derived`) and the bounded agent pass over the residue (`inferred`), with the
  byte-reproducibility that makes the staleness check meaningful.
- **feature-010-aid-graph-skill-runtime** — the skill, its preflight, its wider staleness input
  set with `--reset`, the read-only fence over the Knowledge Base, and the FR-28 rubric and gate
  orchestration.

**Out of scope:** nothing is deferred from this work. Specifically excluded from *this delivery*:
gap detection and the gap ledger (feature-006, delivery-003), `graph.html` and the lens layer
(feature-007, delivery-004), the accessible table view (feature-009, delivery-004), the
interactive canvas (feature-008, delivery-005), and the documentation surfaces, registration
suite and ship-time Knowledge Base updates (feature-013, delivery-006). Fixing any Knowledge Base
gap the enumeration implies is out of scope for the whole work (FR-27).

## Gate Criteria

- [ ] **AC-1** — every `Source Id` and `Target Id` resolves: `kb:` to a document in the KB scan
      set and, where an anchor is present, to a recomputed heading slug in that document; `int:`
      to an existing repo-relative path; `ext:` to a registered key. Verified by feature-003's
      `V2 [REL-UNRESOLVED]`, with `V8 [REL-NAME]` in support. **The `ext:` branch is proven
      against the Q4 self-built synthetic `external-sources.md`** carrying both resolvable and
      deliberately unresolvable keys (A-6), because this project's own file has zero registered
      entries and would satisfy the criterion vacuously.
- [ ] **AC-2** — both relation labels on every row are vocabulary members and form a valid
      inverse pair, with a symmetric relation's `S2T == T2S` row accepted as valid rather than as
      a disagreement. Verified by `V3 [REL-VOCAB]` and `V4 [REL-PAIR]` against delivery-001's
      vocabulary file.
- [ ] **AC-3** — no relationship is recorded twice, neither as a repeated row nor as a forward
      row plus a separate inverse row for the same endpoint pair, with the unordered endpoint
      pair collapsed for symmetric relations.
- [ ] **AC-4** — every row carries exactly one of `declared` / `derived` / `inferred`, non-empty
      and lowercase. Verified by `V6 [REL-PROVENANCE]`.
- [ ] **AC-5** — re-running on an unchanged repository leaves the `declared` + `derived` rows
      byte-identical to the previous run, with `V10 [REL-ORDER]` and `V11 [REL-OBSERVATION]` in
      support.
- [ ] **AC-16** — no node originates from a generated or derived tree, from vendored
      third-party code, or from an ignore-listed path, and no node is finer-grained than a whole
      artifact. Owned by feature-004's exclusion filter; the table side is feature-003's
      `V7 [REL-GRANULARITY]`. Both features are in this delivery.
- [ ] **AC-18** — `relationships.md` carries frontmatter valid for the KB index generator
      (`kb-category`, `source`, `generator`, `objective`, `summary`, `tags`, all present and
      non-empty), and regenerating the KB index leaves the index and `relationships.md`
      consistent. Verified by `V9 [REL-FRONTMATTER]` and `lint-frontmatter.sh`.
- [ ] **AC-11** — preflight refuses to run without an approved Knowledge Base and reports an
      actionable message naming what the user must do. Each of feature-010's preflight checks
      P1–P6 refuses individually; a fixture whose KB is unapproved but whose
      `## Knowledge Summary Status` records `**User Approved:** yes` must still be refused.
      Verified by `tests/canonical/test-graph-preflight.sh`.
- [ ] **AC-12** — an unchanged Knowledge Base, project source and external-sources file makes the
      run a no-op; `--reset` forces regeneration; and mutating only a source file with the
      Knowledge Base untouched still yields `STALE`, proving the input set is wider than
      `/aid-summarize`'s. Verified by `tests/canonical/test-graph-stale-check.sh`.
- [ ] **AC-13** — no Knowledge Base file is modified by any run; the write allowlist and the
      before/after fence detect a mutated KB document and exit non-zero naming it. Verified by
      `tests/canonical/test-graph-read-only.sh`.
- [ ] **AC-17** — the HTML pipeline invokes `/aid-summarize`'s existing scripts rather than
      forked copies, with no duplicated assembler or validator logic, and the no-runtime-engine
      assertion still holds for `kb.html` while the graph is a documented exception **expressed
      by parameterisation, not by a forked validator**. Browser-backed validation degrades
      gracefully with a clear message when no browser is provisioned, and the runtime version
      floor (Node ≥ 20) is reported when unmet.
- [ ] **Registration is complete and derived, not hand-asserted** (feature-012): the full
      generator has run, the render-drift check passes with no stale emission manifest, the skill
      appears in every host profile install tree with no hand-maintained profile copy,
      `tests/canonical/test-doc-counts.sh` passes with every `${SKILLS}` surface stating the
      current derived count — the eleven that move from 111 to 112, including the five
      `profiles/<tool>/README.md` files that live inside generated trees but are not emitted by
      the generator — and `site/scripts/gen-reference.mjs`'s `SKILL_GROUPS` entry and
      `site/scripts/__tests__/gen-reference.test.mjs`'s `CURATED_SKILL_NAMES` roster have moved
      together. No new hardcoded total is introduced; every count assertion compares a derived
      artifact to the source of truth rather than to a sibling literal.
- [ ] **FR-28 does not fully close in this delivery, and the gate records that.** feature-010
      owns the rubric and gate orchestration, but only the `R*` data checks (`R1`–`R5`, mapping
      to AC-1–AC-4 and AC-18) have an artifact to run against here. The `V-*` view checks
      (`V-A` accessibility baseline, `V-C` contrast, and the visual validation) require
      `graph.html`, which does not exist until delivery-004. The full rubric closes over both
      artifacts for the first time in delivery-006.
- [ ] **Q6 is decided in this delivery, before feature-004's implementation task.** FR-22's
      ignore list requires a `graph:` section in `.aid/settings.yml`, which declares
      `format_version: 3` and has no such section. Whether adding it requires a `format_version`
      bump, and what reconcile rule applies to installs that predate it, is answered here —
      feature-004 Open Item 1 routes the decision to the skill-wiring feature rather than
      answering it. `graph.ignore` must resolve through `read-setting.sh --path graph.ignore
      --default ''`, so an absent section is not an error.
- [ ] **Q7 is accepted as an upstream gap, not closed.** `.aid/knowledge/external-sources.md` has
      no machine-readable entry format and `/aid-graph` may not author one under FR-10 — its
      writer is `/aid-discover`'s ELICIT state. feature-003 D2c specifies the table form the
      resolver reads; against today's prose-only file it registers zero keys. AC-1's `ext:`
      branch is therefore satisfied by the Q4 fixture alone, and emitting the table form from
      ELICIT is recorded as a candidate follow-on outside this work.
- [ ] All section-6 quality gates pass: the delivery gate's `grade.sh` run over
      `.aid/.temp/review-pending/` reaches this repository's resolved `minimum_grade` of **A+**
      (`review.minimum_grade` in `.aid/settings.yml`; this work's `minimum_grade: "A+"`), i.e.
      zero findings with Status `Pending` or `Recurred`.

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001 (the relation vocabulary blocks feature-003 and feature-005; the
  rendering recommendation conditions feature-011's carve-outs and feature-012's
  dependency-packaging criterion)
- **Blocks:** delivery-003, delivery-004, delivery-006

## Notes

- **One scanner walk, not two.** feature-004 and feature-005 are two specifications over one
  mechanism: `canonical/aid/scripts/graph/scan-source.sh`. Both SPECs bind `/aid-detail` not to
  produce two competing scanners — a second independent walk would drift and the two would
  disagree about what exists. feature-004 owns which nodes exist; feature-005 owns which rows
  exist and consumes the streams without re-walking.
- **The order within the delivery matters.** feature-012's registration gives the other features
  a place to put code (its Dependency position calls it "the earliest non-research feature"), and
  feature-010 "should be specified early and closed last" — it invokes features 004 and 005,
  writes what feature-003 defines, and owns the gate over all of them.
- **feature-011's carve-outs are contingent, and one cannot be exercised here.** `S2` fires only
  if the selected packaging fetches from a CDN; `validate-visuals.mjs` T2 fires only for an SVG
  live drawing surface (feature-007 Open Item 4, which closes once feature-002 names the
  renderer). delivery-001 supplies the answer, but `graph.html` does not exist until delivery-004,
  so the carve-out is specified here and proven there.
- **The lockstep hazard is the real residue.** `README` matches zero records in all five
  `emission-manifest.jsonl` files and `render.py`'s `skills` branch emits only `SKILL.md` plus
  `references/*.md`, so the five `profiles/<tool>/README.md` files survive the render and must be
  hand-edited. The Knowledge Base records the failure mode as tech-debt **L4** — the
  test-effectiveness gap whose proof case is the `io_bounds.py` incident, where "five install
  manifests plus two installer-test lists all asserted each other and 'passed' while every one of
  them was missing a shipped, security-relevant file. The tests ran; they did not bite." L4's own
  invariant-anchoring remedy is what feature-012's derived-count acceptance criterion encodes.
- **After any canonical edit, run the FULL generator**, never a partial render, or the
  render-drift gate fails on stale emission manifests (`infrastructure.md` § "The Build:
  Multi-Profile Render").
