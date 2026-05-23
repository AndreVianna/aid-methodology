# Specification State

**Status:** Ready
**Started:** 2026-05-22

## Activated Sections

| Section | Status | Activation |
|---------|--------|------------|
| Data Model | Complete | core — profile schema + canonical-source layout (grade A) |
| Feature Flow | Complete | core — the generation pipeline (source + profile → tree) (grade A) |
| Layers & Components | Complete | core — the generator skill body, its helper scripts, and the profiles (grade A) |
| Migration Plan | Complete | auto — brownfield: cut over from 4 hand-maintained copies to 1 source + generated trees (grade A) |

## Pending Q&A

(none)

## Loopbacks

(none)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Specification started — 4 sections activated (3 core + Migration Plan) | /aid-specify |
| 2026-05-22 | Reframed — the generator is a maintainer-facing skill running inside the agentic platform, not a standalone build program (no CLI, no language choice) | /aid-specify |
| 2026-05-22 | Confirmed — generator is a new maintainer-facing skill; rendering is deterministic (helper scripts, byte-identical re-runs) | /aid-specify |
| 2026-05-22 | Technical Specification complete — all 4 sections (Data Model, Feature Flow, Layers & Components, Migration Plan) written and graded A; Status → Ready | /aid-specify |
| 2026-05-22 | Amended (decision F) — Data Model / Feature Flow / Migration Plan updated so all three profiles use `references` decomposition | /aid-specify |
| 2026-05-22 | Reviewer fixes applied — Data Model: noted `canonical/` is extensible and feature-003 adds `canonical/hooks/`; Data Model: added `stop_hook_autocontinue` to profile `capabilities` (4 flags total, consumed by feature-002 FR3-M3 and feature-003); Feature Flow RENDER: defined generator-owned paths via per-run emission manifest (deletion restricted to previously-emitted paths); Feature Flow VERIFY-4b: degrades to skipped-with-warning when a vendor doc is unreachable / still `⚠️ Pending fetch` (advisory, never blocking); Migration Plan opening: aligned with Description's "four parallel locations" framing (human READMEs + three install trees) | Reviewer |
| 2026-05-22 | Post-reshape stale-reference fixes applied (2 LOW + 4 MINOR) — (1) Data Model `canonical/` extensibility paragraph: removed feature-003 reference (deleted by reshape), reframed to generic forward-looking extensibility; (2) Data Model `capabilities` row: dropped FR3-M3 + feature-003 attribution for `stop_hook_autocontinue` (no surviving consumer), retained flag as forward-looking registry entry; (3) Source line: replaced work-001's "§5 FR5, §8, §9, §10" with work-002's §1–§7 plus origin note; (4) Change-log row: annotated "originally REQUIREMENTS.md §5 FR5 of work-001-aid-lite"; (5) Preamble FR5 label: neutralized to "(originally FR5 of work-001-aid-lite)"; (6) Description "the reason §10 sequences FR5 before FR3": reframed to "work-001-aid-lite's §10 sequences this work first, before FR3" | Reviewer |
