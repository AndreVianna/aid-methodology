# Specification State

**Status:** Ready
**Started:** 2026-05-22

## Activated Sections

| Section | Status | Activation |
|---------|--------|------------|
| Data Model | Written | core — STATE-file shape changes + new delivery-issue-log artifact + delivery-complexity signal |
| Feature Flow | Written | core — per-task quick-check flow + per-delivery gate flow; resolves the FR2 trigger/location and lite-path deferrals |
| Layers & Components | Written | core — review-component changes: dual-mode reviewer dispatch, proportional tier selection |
| State Machines | Written | auto — FR2 is fundamentally a rewrite of `aid-execute`'s review state machine; an explicit before/after is load-bearing |

## Pending Q&A

(none)

## Loopbacks

(none)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Specification started — 4 sections activated (3 core + State Machines); Technical Specification written; FR2 deferrals resolved (gate = closing step of aid-execute; complexity signal = deterministic score from Execution Graph + task types; lite delivery = one gated delivery); 3 open questions surfaced for the methodology owner | /aid-specify |
| 2026-05-22 | Technical Specification revised against two locked decisions — (A) `task-NNN-STATE.md` / `implementation-state.md` merged into `task-NNN.md` (Definition + Execution Record zones); quick check and delivery gate now record into the `task-NNN.md` Execution Record (new `## Quick Check` and `## Delivery Gate` blocks), no separate STATE file. (B) lite path emits one consolidated work-root `SPEC.md` (no `PLAN.md`, no feature folder); per-delivery gate and complexity score read delivery/Execution-Graph inputs from `PLAN.md` (full path) or work-root `SPEC.md` (lite path); SPEC-loopback target path-qualified. Gate-location, deterministic complexity score, NFR6, reviewer≠executor all unchanged. | /aid-specify |
| 2026-05-22 | Reviewer fixes applied (2 LOW + 3 MINOR) — (1) enumerated the ~12 `aid-execute/SKILL.md` `task-NNN-STATE.md` references + the `implementation-state.md` dispatch (line 194) as FR2's edit surface; (2) AC block now states "major (= rubric `[HIGH]`)" / "critical (= `[CRITICAL]`)" with a forward-reference to the Severity vocabulary note; (3) pinned the delivery issue log to the exact path `.aid/{work}/delivery-NNN-issues.md` (sibling of `tasks/`) and reconciled the `templates/delivery-issues.md` template name; (4) replaced the non-deterministic "last task of the delivery" with the deterministic Execution-Graph terminal node (highest-numbered if several) for the `## Delivery Gate` block location, gate trigger, and `aid-deploy` read; (5) added the `## Open Questions` section enumerating OQ1–3. Architecture unchanged — completeness/factual corrections only. | reviewer |
| 2026-05-22 | Cross-cutting + precision fixes (CR7) applied to SPEC.md — (1) corrected the `task-NNN-STATE.md` count from ~12 to **16** and enumerated all 16 `aid-execute/SKILL.md` line cites (67, 83, 119, 155, 159, 172, 194, 203, 208, 218, 234, 281, 291, 297, 360, 386 — the 8 literal `task-NNN-STATE.md` mentions plus the 8 bare `STATE file` / `STATE.md` in-context references, all redirecting to the `task-NNN.md` Execution Record zone); (2) added an explicit "Template authorship — feature-002 owns the two-zone `task-NNN.md` (CR7)" subsection in Layers & Components — closes the "no feature owns the template" gap (feature-002 owns the template + `aid-detail` update + `implementation-state.md` deletion; feature-004 writes into the Execution Record scaffold it inherits); (3) reconciled the Data Model wording on `task-NNN.md` zone creation with the CR7 model — `aid-detail` creates the file with Definition filled and Execution Record as empty scaffold, `aid-execute` populates the scaffold; no contradiction with Layers & Components; (4) replaced the stray `[MAJOR…]` token in the Data Model `### Findings` table with `[HIGH]` for severity-vocabulary consistency; (5) added an explicit FR6-aware determinism rule for the `## Delivery Gate` block location (terminal node of the Execution Graph, highest-numbered tiebreak, identical for `aid-execute` writer and `aid-deploy` reader); (6) added a "Naming reconciliation (both forms intentional)" note — instance `.aid/{work}/delivery-NNN-issues.md`, template `templates/delivery-issues.md`, mirroring the `task-template.md` → `task-NNN.md` convention; (7) added a "Parallel-write coordination (FR6)" note — quick checks write deferred `[HIGH]` rows into their own per-task `## Quick Check` block (single-writer), and the gate's new step 0 `AGGREGATE` writes `delivery-NNN-issues.md` once, serially, after the all-`Done` trigger — no append race possible; updated Flow A TRIAGE and Flow B gate flow to reflect this; (8) corrected the IMPEDIMENT line cite from `aid-execute/SKILL.md:308-330` to `:305-330`. `## Open Questions` (OQ1–3) verified already present and consistent with inline `see Open Question N` references — no change. Architecture unchanged — completeness, factual corrections, and CR7 wiring only. | reviewer |
