# Skill Topology

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-26, FR-27, FR-28) | /aid-interview |

## Source

- REQUIREMENTS.md §5.G (FR-26, FR-27, FR-28) — author/behavior side
- REQUIREMENTS.md §1.8 (skill topology, the freshness loop's signal-capture hole), §2.8 (P8)
- §4 S7, §10 (Should)

## Description

This feature fills the skill-topology gaps in the KB lifecycle. It **renames
`aid-ask` → `aid-query-kb`** (the read/query side; behavior preserved, clearer
name). It adds a new **`aid-update-kb`** skill for **targeted / punctual** KB
updates — the "second pass" for the precise deltas a finished work introduced —
applied through the same review/calibration gate as `aid-discover` (so quality is
not bypassed for small updates), because `aid-housekeep`'s KB-DELTA is too broad
for an end-of-work diff. Finally, `aid-query-kb` is made to **capture gaps** ("KB
can't answer" / "KB contradicts code") into a KB-gap queue consumed by
`aid-update-kb` / `aid-housekeep` — turning the single best free drift signal,
which `aid-ask` discards today, into a captured input.

This feature is the **author/behavior side** of the topology: the SKILL.md
definitions, state machines, and behavior. The cross-tree render, orphan-prune, and
install-manifest lockstep for the rename/add are handled by f009.

## User Stories

- As an **AID maintainer**, I want a targeted `aid-update-kb` skill so that a
  finished work's known deltas can be applied through the review gate without a
  heavy full housekeep sweep or hand-editing.
- As an **AID adopter**, I want `aid-ask` renamed to `aid-query-kb` with behavior
  preserved so that the read side has a clear name and keeps working.
- As a **doc owner**, I want a failed `aid-query-kb` query to enqueue a gap so that
  the cheapest, most accurate freshness signal is captured instead of discarded.

## Priority

Should

## Acceptance Criteria

- [ ] Given the read-side skill, when it is invoked, then `aid-ask` has been renamed
  to `aid-query-kb` with behavior preserved. *(FR-26, AC8)*
- [ ] Given a prompt-driven targeted update, when `aid-update-kb` runs, then it
  applies the update through the same review/calibration gate as `aid-discover`.
  *(FR-27, AC8)*
- [ ] Given a query the KB cannot answer (or that contradicts code), when
  `aid-query-kb` runs, then it enqueues a gap into the KB-gap queue consumed by
  `aid-update-kb` / `aid-housekeep`. *(FR-28, AC8)*

> Cross-cutting note: the rename/add must follow the content-isolation cornerstone
> (aid- prefix, manifests) and the thin-router SKILL.md + references/ state-machine
> convention (C6, C8). The ship-side propagation (render, orphan-prune, manifest
> lockstep) is f009.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
