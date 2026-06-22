# KB Migration

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-30) | /aid-interview |

## Source

- REQUIREMENTS.md §5.I (FR-30)
- REQUIREMENTS.md §2.9 (net impact / every phase loads the KB), NFR-7 (backward-compat during migration), D4 (migration precedent)
- §10 (Must)

## Description

This feature ensures no existing KB is stranded on the old format when the new
frontmatter schema and INDEX routing table land. Existing KBs — including **AID's
own** and **adopters'** — must be **migratable** to the new frontmatter
(`objective`/`summary`/`tags`/`see_also`/`owner`/`audience`/`sources`) and the new
INDEX format. The generator and skills must handle the transition, either
upgrade-in-place or via a migration step, **following AID's existing migration
precedent** (`migrate-work-hierarchy`, the content-isolation migration).

Per NFR-7, the migration must not break existing pipelines: an **un-migrated
old-format KB must keep functioning (degrade gracefully)** until it is upgraded,
and the migration must be **safe / reversible** per AID precedent. This is a
**Must** because every downstream AID phase loads the KB; a hard format break would
strand every existing project.

## User Stories

- As an **AID adopter** with an existing KB, I want my KB migrated to the new
  schema/INDEX format so that I get the overhaul without re-running discovery from
  scratch.
- As an **AID adopter** mid-upgrade, I want my un-migrated old-format KB to keep
  working so that nothing breaks before I migrate.
- As an **AID maintainer**, I want migration to follow existing precedent and be
  safe/reversible so that AID's own KB and adopters' KBs migrate predictably.

## Priority

Must

## Acceptance Criteria

- [ ] Given an old-format KB (AID's own and a fixture old-format KB), when migration
  runs, then it is upgraded to the new frontmatter schema and INDEX format. *(FR-30,
  AC9)*
- [ ] Given an un-migrated old-format KB, when the pipeline loads it, then it
  degrades gracefully and keeps functioning until upgraded. *(NFR-7, AC9)*
- [ ] Given the migration, when it runs, then it follows AID's existing migration
  precedent and is safe/reversible. *(FR-30, NFR-7)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
