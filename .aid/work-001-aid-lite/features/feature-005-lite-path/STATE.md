# Specification State

**Status:** Ready
**Started:** 2026-05-22

## Activated Sections

| Section | Status | Activation |
|---------|--------|------------|
| Data Model | Written | core — reduced lite-path artifact set; ONE consolidated work-root `SPEC.md` (no `DELIVERY.md`, no per-feature SPEC, no `PLAN.md`); resolves the FR1 output/`aid-execute`-input deferral |
| Feature Flow | Written | core — State 1.5 TRIAGE fork inside aid-interview, lite-path States L1–L4, deterministic routing rule, lite→full escalation, `aid-execute` hand-off contract |
| Layers & Components | Written | core — no new skill/agent; new states + two `references/` files inside aid-interview; reused interviewer/architect/reviewer roster; cross-tree propagation |
| State Machines | Written | auto — the fork extends a real 7-state state machine; the routing/escalation/resume transitions are load-bearing and warrant their own section |
| Migration Plan | Written | auto — brownfield change to a shipped skill; additive-only; absent `**Path:**` reads as `full`; `aid-execute` back-compat is a behavioural superset |

## Pending Q&A

(none)

## Loopbacks

(none)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Specification written — 5 sections (3 core: Data Model, Feature Flow, Layers & Components; 2 auto: State Machines, Migration Plan); FR1 deferral resolved with the `DELIVERY.md` minimal delivery descriptor; consistent with feature-001's architecture style; 5 open questions surfaced for the methodology owner | /aid-specify |
| 2026-05-22 | Specification revised against locked decisions — (B) `DELIVERY.md` removed entirely, replaced by ONE consolidated work-root `SPEC.md` (`.aid/work-NNN/SPEC.md`) merging the condensed spec + PLAN-level content (single delivery, Execution Graph, delivery-level acceptance criteria, task list); lite work has no feature folder, no per-feature `SPEC.md`, no `PLAN.md`; (A) `task-NNN-STATE.md` merged into `task-NNN.md` (two-zone shape — Definition + Execution Record); `aid-execute` delivery-descriptor resolution rule restated (full → `PLAN.md`, lite → work-root `SPEC.md`); Data Model, Feature Flow, Layers & Components, State Machines, Migration Plan, and the Acceptance Criteria all updated; no new open questions | /aid-specify |
| 2026-05-22 | Reviewer-identified fixes applied (architecture graded B+, sound — no redesign): 1 LOW — Resume detection now special-cases the 1b–1.5 interrupt window (INTERVIEW-STATE.md present, no `**Path:**`, no `## Triage`, empty REQUIREMENTS scaffold → re-enter State 1.5, not State 3); 3 MINOR — `## Source` now lists §8 (triage-misclassification safety net); State L4 hand-off prints `/aid-execute task-001 {work-NNN}` (work id required when multiple works exist); the two new `references/` files marked conditional on FR3/feature-002 having landed (pre-FR3 the lite path is plain `SKILL.md` prose) | /aid-specify |
| 2026-05-22 | Second independent-review fixes applied (2 LOW + 3 MINOR; locked cross-cutting — none touch feature-005). **LOW (template path).** Migration Plan §5 and the `INTERVIEW-STATE.md template` Layers row corrected: `templates/interview-state.md` does **not** exist in the repo (pre-existing defect — live `aid-interview/SKILL.md:174` already references the non-existent path); this feature now **creates** the template (Section Status / Pending Q&A / Review History schema + `**Path:**` + optional `## Triage` block), which is also the co-dependency that resolves the dangling `SKILL.md:174` reference. The `task-NNN.md` template path corrected to the real `templates/delivery-plans/task-template.md`. **LOW (escalation/resume window gap).** Escalation steps re-ordered into a strict 4-step sequence with work-root `SPEC.md` **deletion as the explicit last step**, so the signature "`**Path:** escalated` + work-root `SPEC.md` present" unambiguously means "re-seed not yet confirmed" and is recoverable. Resume detection now has an explicit `**Path:** escalated` clause: routes to full-path State Detection (States 2–7 / Section Status); and a mid-escalation interrupt clause that idempotently replays steps 1 → 4. **MINOR x 3.** `## Source` already lists §8, L4 hand-off already prints `{work-NNN}`, the two `references/` files already marked conditional on FR3 — all applied in prior round, verified intact, no further change. | /aid-specify |
| 2026-05-22 | Third reviewer-fix round applied (1 MEDIUM + 1 LOW + 3 MINOR). **MEDIUM (cross-reference).** All bare `FR5` references qualified as `work-002's feature-001-profile-driven-generator` per the post-reshape `REQUIREMENTS.md §10` where FR5 is `(Moved)` to work-002 (Cross-tree propagation paragraph, Layers row for `references/triage.md`, Sequencing note, Migration Plan §5). Grep verified — zero bare `FR5` remain in the SPEC. No bare `feature-001` references existed; nothing to qualify there. **LOW (dead text).** Cross-tree propagation paragraph's pre-FR5 manual-quadruplicate fallback removed — §10 sequences work-002 **first**, so by the time feature-005 lands the generator is in place; the fallback is never exercised. **MINOR (CR6 state ids).** Lite-path state ids hyphenated per feature-002's locked CR6: `CONDENSED INTAKE → CONDENSED-INTAKE`, `TASK BREAKDOWN → TASK-BREAKDOWN`, `LITE REVIEW → LITE-REVIEW`, `LITE DONE → LITE-DONE` (L1–L4 dispatch table, transition table, ASCII state diagram, in-prose State references). **MINOR (state-id).** `State 1.5 TRIAGE` pinned as canonical `State TRIAGE` (drops the numeric-fractional `1.5` framing from the id); positional context preserved as in-prose phrasing ("positioned between State 1 and State 2"). **MINOR (data-model registration).** Migration Plan §5's data-model.md write-action now names concrete targets: extend `§2.4 SPEC.md (per-feature)` with a lite-path sub-note (work-root placement, merged spec + PLAN-level content) and update `§3.2 Cardinality` for the one-per-lite-work cardinality; the implementer may rename §2.4 to cover both placements at their discretion. Diagram alignment preserved (hyphen replaces space in-place, same character count; `State 1.5 / TRIAGE` split into `State / TRIAGE` two-line label preserves box width). Change Log entries from prior rounds left intact (historical record). | /aid-specify |
