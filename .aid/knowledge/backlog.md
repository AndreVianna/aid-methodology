---
kb-category: primary
source: hand-authored
objective: Defined and prioritized work items for AID that have not shipped — the slice committed to the next release and the prioritized remainder.
summary: Read this to see what is accepted into the plan but not yet shipped; raw unscheduled observations live in tech-debt.md and shipped work in release-tracking.md.
sources: []
tags: [C7, backlog, prioritization, items, planning]
see_also: [tech-debt.md, release-tracking.md, roadmap.md]
owner: architect
audience: [developer, architect, pm]
---

# Backlog

This document holds the work items that have been explicitly accepted into the plan but not
yet shipped. An item moves here when a human makes a deliberate planning decision to commit
to it — the per-item confirm gate at `/aid-create-backlog` or `/aid-update-backlog`. Raw,
unscheduled debt observations stay in `tech-debt.md` until that decision is made; shipped
items move to `release-tracking.md`.

## Contents

- [Next Release](#next-release)
- [Prioritized](#prioritized)
- [Gotchas](#gotchas)

## Next Release

The committed slice for the current tag. Every item here is drained by `release-aid` at tag
time — it becomes a tagged release-note bullet in `release-tracking.md` and is deleted from
this document in the same run.

| ID | Tag | Title | Definition & done-condition | Location | Risk if not done | Priority |
|----|-----|-------|-----------------------------|----------|-----------------|----------|

## Prioritized

Accepted items not yet committed to the current tag, ordered by priority.

| ID | Tag | Title | Definition & done-condition | Location | Risk if not done | Priority |
|----|-----|-------|-----------------------------|----------|-----------------|----------|

## Gotchas

- **ID is inherited on promotion, never re-minted.** The `comm -12` duplicate-item oracle
  (V18) keys on the id; re-minting a promoted id makes the check compare unlike things and
  breaks the move audit entirely.
- **Parking an item in `## Next Release` is a commitment.** That section is drained at
  tag time by `release-aid`; every row there becomes a tagged release-note bullet in
  `release-tracking.md` and is deleted from `backlog.md` in the same run. Do not park
  an item there unless the current tag will include it.
- **An item is moved, never copied.** The promoted row is deleted from `tech-debt.md` in
  the same run that adds it to `backlog.md`. An item present in both documents is a
  checkable defect.
