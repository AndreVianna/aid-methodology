# INDEX Routing Table

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-1, FR-3) | /aid-interview |

## Source

- REQUIREMENTS.md §5.A (FR-1, FR-3)
- REQUIREMENTS.md §1.7 (INDEX routing table design; vector-router rejection), §2.6 (P6)
- Constraints C3 (canonical→render), C7 (INDEX-fresh / KB-hygiene CI)

## Description

This feature replaces today's prose-`intent:` `INDEX.md` list with a generated,
deterministic **routing table** so agents and humans find the right doc fast and
reliably. Each row carries *Document (link = path) · Objective · Summary · Tags ·
See-instead · Audience*, where Audience lets a human filter to the docs relevant
to their role and See-instead provides negative routing ("use this doc, not that
one") to avoid the siloed-logic trap.

The table is composed mechanically by `build-kb-index.sh` from the frontmatter
fields (no LLM), so it stays deterministic, git-diffable, and dependency-free —
consistent with AID's bare-box, AI-skeptic-friendly ethos. The INDEX-fresh and
KB-hygiene CI checks are updated to assert the new table format rather than the
old prose list. The explicitly rejected alternative (a vector/MCP router) is out
of scope.

## User Stories

- As an **AI agent**, I want `INDEX.md` to be a structured routing table with tags
  and see-instead pointers so that I route to the right doc in one pass without
  burning context budget or missing a conflicting rule in another doc.
- As a **non-technical PM** (or any human role), I want an Audience column so that
  I can filter the KB to the docs written at my level.
- As an **AID maintainer**, I want the table generated deterministically by
  `build-kb-index.sh` from frontmatter so that it is CI-verifiable and never
  hand-edited.

## Priority

Must

## Acceptance Criteria

- [ ] Given a KB with frontmatter, when `build-kb-index.sh` runs, then `INDEX.md`
  is the generated routing table with columns Document · Objective · Summary ·
  Tags · See-instead · Audience. *(FR-1, AC4)*
- [ ] Given the generator, when it composes the table, then it does so
  deterministically from frontmatter with no LLM, and the INDEX-fresh / KB-hygiene
  CI checks pass under the new format. *(FR-3, AC4)*
- [ ] Given two docs with a conflicting rule, when an agent consults the INDEX,
  then See-instead negative routing points it to the authoritative/related doc.
  *(FR-1, addresses P6 siloed-logic trap)*

> Cross-cutting note: builds on the frontmatter primitive (f001). Deterministic,
> dependency-free composition satisfies the FR-23 / NFR-3 determinism budget and
> NFR-8 (no new dependency).

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
