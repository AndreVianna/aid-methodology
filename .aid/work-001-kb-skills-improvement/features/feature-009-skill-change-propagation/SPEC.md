# Skill-Change Propagation

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (ship side of FR-26/FR-27) | /aid-interview |

## Source

- REQUIREMENTS.md §5.G (FR-26, FR-27 — ship/propagation side)
- REQUIREMENTS.md §1.6/§1.9 (canonical→render ethos), C3 (canonical→render single source), C6 (content-isolation), C7 (KB-hygiene CI), NFR-4 (conventions-fit)
- §4 S7, §10 (Should)

## Description

Renaming `aid-ask → aid-query-kb` and adding `aid-update-kb` (f008) is not a
single-file edit — in AID a skill change ripples across the whole canonical→render
machinery, and this feature owns that propagation so nothing is left stale. It
covers: rendering the changed/new skill from `canonical/` into the **five host
trees** (claude-code, codex, copilot-cli, cursor, antigravity) with render-drift CI
green; **orphan-pruning** the retired `aid-ask` content by prefix from all trees;
keeping the **five install manifests in lockstep** on the new skill file set;
reconciling the **~10 KB-doc "N user-facing skills" count references** that a
skill rename/add leaves stale; and updating the **docs site** to match.

This is the ship-side counterpart to f008's author-side definitions. It exists as a
separate feature because the cross-tree/manifest/count-drift propagation is a
distinct, CI-guarded class of work (the known "adding a skill → KB count drift" and
"render-drift full generator" hazards) that must be done in lockstep or CI fails.

## User Stories

- As an **AID maintainer**, I want the skill rename/add rendered into all five host
  trees with the retired skill orphan-pruned so that render-drift CI stays green and
  no stale `aid-ask` content lingers.
- As an **AID adopter**, I want the five install manifests in lockstep on the new
  skill file set so that every install channel ships the correct skills.
- As an **AID maintainer**, I want the ~10 KB-doc skill-count references and the docs
  site reconciled so that the documented skill inventory matches reality.

## Priority

Should

## Acceptance Criteria

- [ ] Given the f008 skill rename/add, when the full generator runs, then the
  changed/new skill is rendered into all five host trees and render-drift CI is
  green. *(ship side of FR-26/FR-27, C3, NFR-4)*
- [ ] Given the retired `aid-ask`, when propagation runs, then its content is
  orphan-pruned by prefix from all trees and the five install manifests are updated
  in lockstep. *(C6, AC12 conventions)*
- [ ] Given the skill rename/add, when reconciliation runs, then the ~10 KB-doc
  "N user-facing skills" count references and the docs site are updated, and
  KB-hygiene CI passes. *(C7, AC12)*

> Cross-cutting note: this is the propagation half of AC12 (conventions &
> canonical→render with render-drift + KB-hygiene CI green). Pairs with f008.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
