# Frontmatter & `sources:` Primitive

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-2, FR-4, FR-10) + §1.7 render plumbing (GAP-B) | /aid-interview |

## Source

- REQUIREMENTS.md §5.A (FR-2), §5.B (FR-4), §5.C (FR-10)
- REQUIREMENTS.md §1.3 (the `sources:` primitive rationale), §1.7 (frontmatter feeding the INDEX)
- Cross-cutting NFR-4 (canonical→render, CI-guarded), C3, C7

## Description

This feature establishes the shared frontmatter vocabulary that the rest of the
KB overhaul depends on. It adds new frontmatter fields to every KB document so
the document can describe itself to both the routing layer and the freshness
layer: `objective:` (one-line purpose), `summary:` (one-sentence scope),
`tags:` (concrete project terms), `see_also:` (negative-routing pointers),
`owner:` (the role accountable for the doc), `audience:` (who the doc is for),
and `sources:` (the files, directories, and external docs the doc summarizes).

The `sources:` field is the keystone primitive — it is required by three threads
at once (the INDEX go-deeper pointer, per-doc source-keyed freshness, and the
calibration/coverage grading), which is why it is built once, here, as a
foundation. Beyond the field definitions, this feature delivers the render
plumbing (GAP-B): the canonical frontmatter-schema and the generator must parse,
validate, and carry these fields end-to-end so downstream features (INDEX
routing, freshness, calibration) can consume them without re-plumbing.

## User Stories

- As an **AI agent**, I want every KB doc to declare its objective, summary, and
  tags in structured frontmatter so that I can be routed to the right doc cheaply
  and deterministically.
- As a **doc owner / maintainer**, I want each doc to declare its `sources:` and
  `owner:` so that I know which doc my change made suspect and who is accountable
  for keeping it current.
- As an **AID maintainer**, I want the frontmatter schema and the canonical→render
  generator to validate the new fields so that the new primitive is CI-guarded and
  cannot drift.

## Priority

Must

## Acceptance Criteria

- [ ] Given the KB frontmatter schema, when a KB doc is authored, then it can
  declare `objective:`, `summary:`, `tags:`, `see_also:`, `owner:`, `audience:`,
  and `sources:` and the schema validates them. *(FR-2, FR-10, FR-4)*
- [ ] Given a KB doc with the new fields, when the canonical→render generator runs,
  then the fields are parsed, validated, and carried through with render-drift and
  KB-hygiene CI green (GAP-B render plumbing). *(NFR-4, C3, C7; supports AC12)*
- [ ] Given any KB doc, when it is checked, then it declares `sources:` — the
  files/dirs/external docs it summarizes. *(FR-4; foundation for AC5)*

> Cross-cutting note: this feature carries the FR-23 / NFR-1–3 deterministic
> substrate at the frontmatter layer (schema validation is mechanical, CI-able,
> no LLM). It is the foundation consumed by AC4 (f002), AC5 (f007), and the
> calibration coverage-vs-source check (f005).

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
