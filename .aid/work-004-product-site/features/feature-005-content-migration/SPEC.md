# Content Migration: Reuse Existing docs/*.md as the Single Source

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR11), §7, §8, §10 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR11 Content reuse)
- REQUIREMENTS.md §7 (Constraints — content reuse), §8 (Assumptions — frontmatter migration),
  §10 (Priority — Must)

## Description

Establish the repeatable, low-drift migration of the repo's existing Markdown into Starlight
content. The existing `docs/*.md` files — `aid-methodology.md`, `install.md`,
`repository-structure.md`, `faq.md`, `glossary.md` — are brought into Starlight's content
directory with the required YAML frontmatter added, kept as the single source where feasible to
minimize duplication and drift, with internal relative links and anchors fixed for the new IA and
Mermaid diagrams rendering correctly. This feature owns the migration mechanism and the faithful
transfer of the source files; the content-bearing features (Get Started, Installation, Concepts,
Reference) consume the migrated pages and arrange them into the site map. Isolating the
migration/transform step lets it be built and validated (no content loss, links resolve, diagrams
render) independently of page-layout decisions.

## User Stories

- As a returning user, I want the existing docs (methodology, install, repo structure, FAQ,
  glossary) to appear on the site with no content loss so that nothing I relied on disappears.
- As a returning user, I want internal links to resolve under the new structure so that I never
  hit a broken cross-reference.
- As an evaluator, I want Mermaid diagrams from the methodology to render so that the
  architecture is communicated visually, not as raw code.
- As a maintainer, I want a single source for migrated docs (with frontmatter added by a
  one-time, scriptable migration) so that ongoing maintenance has minimal duplication and drift.

## Priority

Must

## Acceptance Criteria

- [ ] Given the existing `docs/*.md` (methodology, install, repository-structure, faq, glossary),
  when migrated, then each appears in Starlight content with no content loss (AC5).
- [ ] Given migrated pages, when built, then required YAML frontmatter (incl. `title`) is present
  and the pages live in Starlight's content directory (§8).
- [ ] Given migrated pages containing Mermaid, when built, then the diagrams render correctly
  (AC5).
- [ ] Given internal relative links and anchors in the source files, when re-grouped under the
  new IA, then they resolve with no broken internal links (AC5; §6 CI link-check where practical).
- [ ] Given the migration, when re-run, then it is scriptable/repeatable so the source `docs/`
  remains the single source where feasible (FR11, §8).

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
