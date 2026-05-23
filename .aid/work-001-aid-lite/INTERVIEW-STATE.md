# INTERVIEW-STATE.md

**Status:** Approved
**Grade:** A
**Minimum Grade:** A

## Section Status

| # | Section | Status | Last Updated |
|---|---------|--------|--------------|
| 1 | Objective | Complete | 2026-05-22 |
| 2 | Problem Statement | Complete | 2026-05-22 |
| 3 | Users & Stakeholders | Complete | 2026-05-22 |
| 4 | Scope | Complete | 2026-05-22 |
| 5 | Functional Requirements | Complete | 2026-05-22 |
| 6 | Non-Functional Requirements | Complete | 2026-05-22 |
| 7 | Constraints | Complete | 2026-05-22 |
| 8 | Assumptions & Dependencies | Complete | 2026-05-22 |
| 9 | Acceptance Criteria | Complete | 2026-05-22 |
| 10 | Priority | Complete | 2026-05-22 |

## Pending Q&A

### IQ1: [Architecture: High]

**Question:** FR3-M3 (skill chaining — a completed state auto-advancing to the next step) is not natively supported by any of the three host tools. How should M3 be redefined?
**Context:** The Codex/Cursor documentation research found that hooks ARE supported (Codex CLI: stable, v0.131–0.133, May 2026; Cursor: beta since 1.7) — so FR3-M2 and FR4-P3 are safe — but NO host tool (Claude Code, Codex, Cursor) offers a skill autonomously invoking the next. Cursor is closest (command-orchestrated skill sequencing); Codex has only manual slash-command queuing (auto-invocation is an open feature request). FR3-M3, and the §10 dependency "FR3's chaining smooths FR1's lite auto-flow," assumed a native capability that does not exist.
**Source:** /aid-interview (cross-reference) + Codex/Cursor docs research
**Suggested:** Redefine M3 from "native skill chaining" to "hook-driven / user-confirmed auto-advance" built on the M2 hook infrastructure (available on all three tools): on state completion a hook emits the next-step prompt and triggers it where the host allows, otherwise presents a one-keystroke continue. Auto-advance becomes a behavior built on hooks, not an assumed native feature; NFR4 graceful degradation covers tools where even that is limited.
**Status:** Answered
**Answer:** Accepted — M3 is redefined as hook-driven / user-confirmed auto-advance built on the M2 hook infrastructure.

### IQ2: [Knowledge Base: Medium]

**Question:** The KB (`architecture.md`, `data-model.md`) is stale — it describes a `DETAIL.md` artifact and `detail-template.md` / `delivery-template.md` that no longer exist (the methodology spec confirms there is no separate DETAIL.md; the execution graph lives in PLAN.md). How should it be corrected before /aid-specify reads it?
**Context:** REQUIREMENTS.md FR1/FR6 are themselves correct, but a downstream phase reading the stale KB would design against a phantom artifact. The canonical AID mechanism for a KB deficiency is a Q&A entry in DISCOVERY-STATE.md that triggers a targeted /aid-discover — not a GAP.md (not an AID artifact).
**Source:** /aid-interview (cross-reference)
**Suggested:** Log a Q&A entry in `.aid/knowledge/DISCOVERY-STATE.md` flagging the stale `DETAIL.md` / `detail-template` references in `architecture.md` and `data-model.md`, and run a targeted /aid-discover to re-sync them before /aid-specify — folding in the Codex/Cursor hook findings from this research (integration-map.md / host-tools-matrix.md currently record hooks as "unused / unconfirmed").
**Status:** Answered
**Answer:** Executed the re-sync now, per the user's instruction. Scoped via grep — the staleness was schema-deep, not just artifact names (e.g. `api-contracts.md`'s TASK schema was the old 13-field format). A full `/aid-discover --reset` was rejected as disproportionate — it would destroy the A+ KB and its 181-entry Q&A / 24-cycle history to fix artifact references. Instead: a **targeted surgical re-sync** of 12 KB docs to the current artifact model, `project-index.md` regenerated via `build-project-index.sh`, verified by re-grep + spot-reads of the schema rewrites. `DISCOVERY-STATE.md` Q181 marked Resolved; Review History entry #25 records the change. One item remains: `knowledge-summary.html` is generated output and needs a `/aid-summarize` re-run to refresh — it cannot be hand-edited.

### IQ3: [Scope: Medium]

**Question:** Should FR5 (the profile-driven generator) explicitly own fixing the confirmed Codex installer bug — tech-debt H6 (`setup.sh` / `setup.ps1` never copy `codex/.agents/`, so every bundled-installer Codex install is already broken)?
**Context:** FR5's generator and FR3's refactor both touch the installer surface. §8 currently does not mention H6. Re-architecting on a known-broken installer risks silently inheriting or masking the bug; NFR2's "no silent breakage" baseline should account for installs already broken pre-refactor.
**Source:** /aid-interview (cross-reference)
**Suggested:** Yes — add an §8 dependency note that FR5's generator must subsume/fix tech-debt H6, and that NFR2's backward-compatibility baseline explicitly accounts for the pre-existing broken Codex installs.
**Status:** Answered
**Answer:** Accepted — §8 gains a dependency note that FR5's generator and the installer rewrite must subsume and fix tech-debt H6 (the bundled installer never copies `codex/.agents/`), not inherit or mask it; NFR2's backward-compatibility baseline is measured against a working install, not the already-broken Codex status quo.

### IQ4: [Accuracy: Low]

**Question:** §2 Problem Statement presents the competitive comparison and "small tasks take longer than ad-hoc prompting" as established fact. By the document's own admission (FR7 / NFR1: AID has no telemetry today) these are un-instrumented. Reframe?
**Context:** These empirical claims are the load-bearing justification for the whole effort but have no recorded evidence trail. Presenting them as qualitative observations (consistent with NFR1's honesty) is more accurate.
**Source:** /aid-interview (cross-reference)
**Suggested:** Reframe §2's four items as observed, qualitative findings from the comparison (un-instrumented; FR7 will quantify), keeping them as the effort's motivation without overclaiming.
**Status:** Answered
**Answer:** User supplied the concrete benchmark behind §2 — a controlled 3-group comparison on a small Java DDD/hexagonal refactor (3 classes, 1 method each + tests): AID full pipeline ~3h (had not finished aid-detail after 1h; ~2h for 8 generated tasks); Claude Code prompted directly ~1h; developer control finished minutes after — plus the cross-size finding that AID nets a gain only on large/complex work (weeks → 3-4 days). §2 was rewritten to present this benchmark as the evidence trail, honestly framed as observed runs (not instrumented telemetry — FR7 will measure going forward). Resolves the "empirical claims presented as fact" finding.

### IQ5: [Priority: Medium]

**Question:** feature-008 (the HTML progress viewer, FR4-P2) is bucketed "Should" in §10, but FR4's body and `feature-008/SPEC.md` still call P2 a "bonus / stretch." Which is binding — a committed Should-priority feature, or a non-committed stretch?
**Context:** feature-008 was elevated to Should during decomposition, but the earlier "bonus" framing in the FR4 body was never updated. A Should-priority feature with a full SPEC and binding acceptance criteria is a commitment, not a stretch — the two readings contradict.
**Source:** /aid-interview (cross-reference)
**Suggested:** Treat feature-008 as a committed Should (the decomposition decision is the latest word) and drop the "bonus / stretch" wording from the FR4 body and the SPEC.
**Status:** Answered
**Answer:** Accepted — feature-008 is a committed Should. The "bonus / stretch" and "optional" priority wording was removed from the FR4 body, §9, §10, and feature-008/SPEC.md; the SPEC now describes P2 accurately as an additive layer (the P1 + P3 core does not depend on it) without understating its committed status.

## Cross-Reference

**Status:** Complete
**Date:** 2026-05-22
**Grade:** A — final independent grade, meets the A minimum
**Summary:** Cross-reference ran in two rounds. **Round 1** (State 6): 8 findings → grade C; resolved via IQ1–IQ5 + 3 direct fixes — this round also did the Codex/Cursor hook research and the 12-doc KB re-sync (DISCOVERY-STATE Q181). **Round 2** (re-run from State 7): three independent reviewer passes graded C → B → A as findings were fixed each pass — pass 1: 8 findings (2 MEDIUM — FR6 mis-stating current behavior, §1 omitting Discover); pass 2: 4 findings (2 LOW — the FR1/FR2 lite-path artifact contract); pass 3: 4 cosmetic MINOR. Final independent grade **A**, meeting the work-item A minimum. The 3 work-product MINORs were then cleaned up; 1 cosmetic KB nit (`architecture.md` branch-name style) noted for the KB owner. Cleared for `/aid-specify`.

## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-05-22 | — | /aid-interview | Interview complete — all 10 sections approved by user |
| 2 | 2026-05-22 | — | Feature Decomposition | 10 features created |
| 3 | 2026-05-22 | C (resolved) | Cross-Reference | Validated REQUIREMENTS.md vs KB + methodology + code. 8 findings (2 MEDIUM, 3 LOW, 2 MINOR, 1 no-defect) → grade C; all resolved via IQ1–IQ5 + 3 direct fixes. KB re-synced (DISCOVERY-STATE Q181). Re-run /aid-interview to re-grade. |
| 4 | 2026-05-22 | A | Cross-Reference (re-run) | Re-validation from State 7. Three independent reviewer passes C → B → A; final grade A meets the A minimum. 12 findings fixed across passes; 3 cosmetic MINORs cleaned up, 1 KB-cosmetic nit noted. Cleared for /aid-specify. |
| 5 | 2026-05-22 | — | Fresh-eyes reshape (option B) | Post-`/aid-specify` independent over-engineering critique flagged scope creep (4 user pain points → 10 features + 8 cross-cutting resolutions). **Reshape:** 5 features survive in this work (`feature-002` M1-only, `feature-004`, `feature-005`, `feature-007` redesigned as pure skill-body text, `feature-009`); `feature-001` moved to **`work-002-canonical-generator`** (sequenced first — its canonical-source consolidation unblocks single-source editing for the rest); features 003, 006, 008, 010 deleted. CR1–CR6 and CR8 retired; **CR7** (two-zone `task-NNN.md`) retained. REQUIREMENTS.md reshaped: FR3 simplified to M1 only (M4 folded in as authoring discipline); FR4 simplified to P1 only (pure skill-body text — state-entry print + bracket-pair floor + ASCII state-map); FR5 moved to work-002; FR7 dropped; §10 build order: work-002 first, then FR3 → FR1 / FR2 / FR4 / FR6. |
