# Specification State

**Status:** Ready
**Started:** 2026-05-22

## Activated Sections

| Section | Status | Activation |
|---------|--------|------------|
| Data Model | Written | core — the on-disk shape of a refactored skill: thin-router SKILL.md anatomy, `references/state-*.md` schema, dispatch-table contract |
| Feature Flow | Written | core — one-step-per-invocation router flow (M1); user-driven `/aid-{name}` re-invocation between states; halt-semantics for terminal/human-gated states |
| Layers & Components | Written | core — router and state-detail layers (no advance layer — M3 dropped); canonical-source-only authoring; soft interlock with `work-002`'s `feature-001-profile-driven-generator` (canonical structure); feature-003 deleted in the reshape (M2 hooks dropped) |
| Migration Plan | Written | auto — brownfield: incremental per-skill thin-router cutover across all 10 skills on `canonical/`, with NFR2 in-flight-workspace safety |

## Pending Q&A

(none)

## Loopbacks

(none)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Specification started — 4 sections activated (3 core + Migration Plan); all written in one batched /aid-specify pass | /aid-specify |
| 2026-05-22 | Technical Specification revised against locked decisions E1, E2, A, F (Wave-2): M3 mechanism re-specified — `auto-advance` = host Stop-hook programmatic auto-continue, `confirm-advance` = a prompt in the skill body (no hook), `manual` = re-invocation; the 3-mode ladder kept (no host hook can solicit a keystroke). E2/F — `references/` progressive disclosure confirmed on all three tools: "Claude-Code-first footprint" caveat and OQ-2.1 dropped, footprint win is universal, every profile uses `references` decomposition. A — NFR2 note updated for the `task-NNN-STATE.md` → `task-NNN.md` merge. New capability flag `stop_hook_autocontinue` introduced in the M3 capability inputs. | /aid-specify |
| 2026-05-22 | Reviewer fixes applied to SPEC.md (2 LOW + 1 MINOR): `aid-summarize` state count corrected 9 → 10 (verified 10 `## Mode:` blocks on disk) with a note on how the composite `DONE-IDEMPOTENT` collapses into the `DONE` dispatch row; router (~80–120) and inline-body (~370) line counts relabelled as estimates; `aid-discover` inline-Mode span corrected from 82–398 to 82–453 (last `## Mode:` at line 381, file is 453 lines). No architecture change. | /aid-specify |
| 2026-05-22 | Cross-cutting fixes (CR6, CR7) + LOW finding fixes applied to SPEC.md: (CR6) feature-002 now explicitly owns the canonical `SCREAMING_CASE`-with-underscores state-id format (`RENDER`, `REVIEW`, `LOAD_TASKS`, `EXECUTE_WAVE`, …) — Data Model dispatch-table block carries the canonical-format paragraph; feature-006 and feature-007 inherit. (CR7) feature-002 now explicitly delivers the extended two-zone `templates/delivery-plans/task-template.md` (Definition zone + empty Execution Record scaffold), updates `aid-detail` to write both zones, and deletes the retired `templates/implementation-state.md` — covered in Layers & Components and in a new Migration Plan "Template surgery" subsection. Resolved the Advance-enum naming inconsistency (LOW) with an explicit vocabulary-bridge note (`auto`↔`auto-advance`, `confirm`↔`confirm-advance`, **`halt`↔`manual`** — equivalent, two names) plus a clarifying parenthetical in the dispatch-table row. Referenced feature-003 by its full folder title ("feature-003 — Hooks and Sub-Agent Mechanical Offload") in the spec preamble. Reworded the inline-Mode line-count narrative: ~370 lines = 453 − 82 (full inline-Mode span); the 381→453 framing is the *last* Mode block only (~72 lines). No architecture change. | reviewer |
| 2026-05-22 | *Fresh-eyes scope reshape — M3 stripped; M1-only design; M4 folded in as a per-skill authoring discipline; references to dropped features 003 and 006 removed; feature-001 reference repointed to work-002.* SPEC.md preamble retargeted to "FR3 M1 with M4 as a per-skill authoring discipline"; Description / Acceptance Criteria reduced to the M1 scope (no auto-advance user story or criterion); all M3 content removed (3-mode degradation ladder, Stop-hook integration, capability-input table including `stop_hook_autocontinue`, vocabulary bridge, advance-signal consumption, Cursor-beta caveat, escalation-via-M3 paragraph); dispatch table `Advance` column simplified to `→ {NEXT-STATE-NAME}` or `→ halt` (no mode tokens, no mode-selection logic); Migration Plan sequencing constraint reduced — the "after feature-003" gate is gone, only the "after work-002's feature-001-profile-driven-generator" gate remains; Out-of-scope expanded to explicitly call out the dropped M3 and the dropped standalone-M4 feature. **Preserved unchanged:** M1 thin-router design (5-part router + `references/state-{name}.md` + dispatch-table contract); CR6 (canonical state-id format = UPPERCASE-with-hyphens, aligned with on-disk corpus); CR7 (feature-002 owns the two-zone `task-template.md` + `aid-detail` update + `implementation-state.md` deletion); the 453/82/370 line-count narrative. CR6 inheritance updated: feature-006 reference removed (dropped from work-001); feature-007 still inherits. | /aid-specify |
| 2026-05-22 | Reviewer fixes (1 LOW + 1 MINOR own findings) + feature-007 cross-feature resolution. **LOW** — STATE.md Activated Sections "Feature Flow" row tense corrected: removed the dropped-M3 "hook-driven auto-advance ladder (auto / confirm / manual)" description and replaced with the current M1 reality (one-step-per-invocation router flow, user-driven `/aid-{name}` re-invocation, halt-semantics for terminal/human-gated states). **MINOR** — SPEC.md AC2 run-on sentence split. **Cross-feature (feature-007 OQ-A and OQ-C, both deferred to feature-002):** new Data Model subsection "State descriptors and single source of truth" added — OQ-A resolved (dispatch-table `State` column = canonical state-id source; per-state human-readable descriptor lives in `references/state-{name}.md`, first-line opening sentence is the descriptor; feature-002 owns, feature-007 reads); OQ-C resolved (the `## Dispatch` table is the single source of truth for each skill's state set; feature-007's state-map descriptor derives from it, never duplicates). | reviewer |
