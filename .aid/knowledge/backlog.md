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
| **W5-21** | `[NEW]` | Knowledge relationship graph | **Knowledge relationship graph** — a new on-demand skill `/aid-graph` builds `.aid/knowledge/relationships.md` (the machine-readable relationship table over the approved Knowledge Base plus the project's own source) and `.aid/knowledge/graph.html` (the interactive view over it, with a table fallback). It is a sibling of `/aid-summarize` in the same post-Knowledge-Base slot — on demand, never fired by discovery, and refused by pre-flight unless the Knowledge Base is finished and approved. The Knowledge Base is read-only for the whole run, enforced by a write fence rather than promised; the run is idempotent and content-addressed, so a re-run on an unchanged project is a true no-op and a regeneration names the input that changed. It grades its own two artifacts only: Knowledge Base gaps are reported in a separate ledger and routed to the skills that own KB repair, never gated on and never fixed here. Ships the `canonical/aid/scripts/graph/` helper set, the `canonical/aid/templates/graph/` schema + relation-vocabulary contracts, and the `canonical/aid/templates/knowledge-graph/` view templates, rendered into all five profiles. **Done when** the next tag ships it — **shipped, pending tag** | `canonical/skills/aid-graph/SKILL.md`; `canonical/aid/scripts/graph/`; `canonical/aid/templates/graph/`; `canonical/aid/templates/knowledge-graph/`; outputs `.aid/knowledge/relationships.md` and `.aid/knowledge/graph.html` | Ships untagged / absent from the next release notes | P1 |

## Prioritized

Accepted items not yet committed to the current tag, ordered by priority.

| ID | Tag | Title | Definition & done-condition | Location | Risk if not done | Priority |
|----|-----|-------|-----------------------------|----------|-----------------|----------|
| **W5-20** | `[CHANGE]` | A refused or routed design-lifecycle run still leaves an allocated work folder and git worktree behind | The design-lifecycle skills allocate through the Work Initiation Gate at their `INTAKE` state — before the `GUARD` that refuses a seed whose `## Open questions` is non-empty, and before the `REALIZE` that routes to a prerequisite skill when the destination is absent. An invocation that writes nothing therefore still creates a `work-NNN` folder **and**, because allocation runs `worktree-lifecycle.sh create`, a git worktree the user must remove by hand. Decide whether that is the intended shape. Two coherent resolutions: move allocation to after both exits, or have each exit tear down what it allocated. **Done when** the allocation contract states the chosen rule explicitly and every skill body matches it, with the refusal and routing-exit paths asserted either way. Note the counter-argument on record: allocation is currently unconditional *by design*, so that a graded, reviewable work folder exists for every invocation — changing it is a contract change, not a bug fix | `canonical/aid/templates/design-lifecycle.md` § *Skill shape — Allocation*, and its binding-table row `Allocation via the Work Initiation Gate`; the `INTAKE` state of each `canonical/skills/aid-{design,create,update}-*/SKILL.md` body; `canonical/aid/scripts/works/worktree-lifecycle.sh` | Refused and routed runs accumulate empty work folders and stray git worktrees in every adopter's project, with no skill that cleans them up; and verification keeps re-deriving the same surprise, having already produced one unsatisfiable acceptance criterion from the assumption that a non-realizing run allocates nothing | P3 |

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
