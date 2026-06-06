# Concepts & Reference Sections

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR8, FR9), §10 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR8 Concepts, FR9 Reference)
- REQUIREMENTS.md §3 (Users — returning users, maintainers), §10 (Priority — Should/Could)

## Description

Build the understanding-oriented and information-oriented areas of the site. Concepts presents the
methodology in full — pipeline & phases, philosophy, the Knowledge Base, the agent model, feedback
loops, lite vs full, and AID vs spec-driven development (from `docs/aid-methodology.md`) — plus the
FAQ (from `docs/faq.md`). Reference presents the facts: CLI & subcommands (from `docs/install.md`),
a generated Skills / Agents / KB reference (from `canonical/`), settings keys (net-new,
generated from `.aid/settings.yml`), artifacts,
repository structure (from `docs/repository-structure.md`), and the glossary (from
`docs/glossary.md`). Concepts and Reference consume content produced by the migration feature and
add the net-new generated catalog pages. Per §10, Concepts and the core Reference pages are
Should; the generated Skills/Agents/KB reference is Could and may start as stubs and deepen later.

## User Stories

- As an evaluator, I want a full explanation of the methodology and philosophy so that I can
  understand how AID works and why before committing.
- As a returning user, I want a CLI & subcommand reference, settings keys, and artifacts so that
  I can look up exact facts quickly.
- As a returning user, I want a glossary and repository-structure reference so that I can decode
  AID's terms and layout.
- As a maintainer, I want a generated Skills / Agents / KB reference from `canonical/` so that the
  roster stays accurate to the source of truth (acceptable as stubs initially).
- As a returning user, I want an FAQ so that common questions are answered without searching the
  long methodology page.

## Priority

Should

## Acceptance Criteria

- [ ] Given the Concepts section, when navigated, then the full methodology (pipeline & phases,
  philosophy, KB, agent model, feedback loops, lite vs full, AID vs SDD) and the FAQ are present
  (FR8, AC3).
- [ ] Given the Reference section, when navigated, then CLI & subcommands, settings keys
  (generated from `.aid/settings.yml`), artifacts, repository structure, and glossary pages
  are present (FR9, AC3).
- [ ] Given `canonical/`, when the Reference is built, then a Skills / Agents / KB reference
  exists (may begin as stubs and deepen later) (FR9, AC6).
- [ ] Given the migrated methodology, FAQ, repo-structure, and glossary source, when published in
  these sections, then content appears with no loss and internal links resolve (AC5).

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
