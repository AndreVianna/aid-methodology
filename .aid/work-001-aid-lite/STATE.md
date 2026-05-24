# Work State — work-001-aid-lite

> **Status:** Specifying (scope re-expanded 2026-05-24; feature-005 needs re-spec, feature-011 needs creation)
> **Phase:** Specify
> **Minimum Grade:** A+ *(was A; updated 2026-05-24 to track project STATE.md minimum)*
> **Started:** 2026-05-22
> **User Approved:** yes (Interview)

This is the single state file for `work-001-aid-lite` — speed-focused AID-Lite reform (lite path + two-tier review + thin-router + parallel-by-default). Consolidates what used to be `INTERVIEW-STATE.md` + per-feature `STATE.md` × 4.

## Interview Status

**Status:** Approved · **Grade:** A

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

## Features Status

| # | Feature | Spec Status | Spec Grade | Q&A Count | Notes |
|---|---------|-------------|------------|-----------|-------|
| 002 | `feature-002-skill-footprint-refactor` | Ready (per-area STATE sweep pending) | A | 0 open | FR3 thin-router (M1 only, M4 folded in as authoring discipline). Owns CR6 (state-id format: UPPERCASE-with-hyphens). CR7 (two-zone task-template) **retired** by the 2026-05-24 REQUIREMENTS refresh — per-task state lives in work `STATE.md ## Tasks Status` per work-003 FR2 area-STATE rule. Sweep flagged. Soft dep from `work-003/feature-001` AC4. |
| 004 | `feature-004-two-tier-review` | Ready (per-area STATE sweep pending) | A | 0 open | FR2 review pattern: per-task quick check (major/critical only) + per-delivery A-grade gate. Quick-check + delivery-gate records write through work `STATE.md ## Tasks Status` per the 2026-05-24 REQUIREMENTS refresh (not Execution Record zone). Sweep flagged. |
| 005 | `feature-005-lite-path` | **In Discussion** (FR1 type-aware ext + per-area STATE sweep pending) | A (pre-extension) | 0 open | FR1 lite path: triage fork in /aid-interview; consolidated work-root SPEC.md for small work; no feature folders / no PLAN.md when lite. **NEW scope (2026-05-24):** type-aware lite sub-paths (bug-fix / single-doc / small-refactor / small-new-feature). Also: INTERVIEW-STATE.md refs need sweep to per-area work `STATE.md`. Needs re-spec + re-review. |
| 009 | `feature-009-parallel-task-execution` | Ready (per-area STATE sweep pending) | A+ | 1 open (IQ6 — Task-tool wait-for-any semantic; deferred to /aid-plan, not a SPEC blocker) | FR6 parallel-by-default in /aid-execute. **Pool model** (continuous, bounded by `MaxConcurrent`, default 5 via new aid-init Max Parallel Tasks question). Pass-1 D+ → fix-pass-1 → pass-2 D+ → fix-pass-2 → **pass-3 A+** (clean pass, 2026-05-23). Per-task state references (Execution Record zone phrasing) need sweep to per-area work `STATE.md ## Tasks Status` per the 2026-05-24 REQUIREMENTS refresh. Failure stops only descendant subtree (AND-only deps). Soft-coupling target for `work-003/feature-001` AC4 sub-unit drill-down. |
| 011 | `feature-011-recipes` | **Pending Creation** | — | — | NEW FR8 from 2026-05-24 scope addition. Recipes catalog of pre-filled lite-path templates for common small-work patterns (bug-fix, method-refactor, add-crud-endpoint, write-release-note, add-unit-test seed catalog); instantiation collapses lite path to slot-filling. Soft dep on feature-005's type-aware triage extension landing first. Needs full /aid-specify cycle. |

## Plan / Deliveries

| Delivery | Status | Tasks | Notes |
|----------|--------|-------|-------|
| _none yet_ | — | — | `/aid-plan` not yet run for this work |

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| _none yet_ | — | — | — | — | — | — | `/aid-detail` not yet run for this work |

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | — | — | — | — | — |

## Cross-phase Q&A (Pending)

### IQ6: [Host Capability — feature-009 pool model: Medium]

**Question:** Does the host's **Task-tool** sub-agent dispatch surface support a
**wait-for-any-of-N completion** semantic (i.e., dispatch N concurrent Task-tool
calls and block until any one returns, leaving the others running)? FR6's pool
algorithm needs this primitive to admit a new task on every completion event
without joining across the in-flight set.

**Context:** Today `aid-execute` dispatches **one** Task-tool call per
invocation, and `aid-discover` runs multiple sub-agents in parallel via the
**Agent** tool (a different surface) with `background: true` plus an
orchestrator-side wait loop. The new feature-009 pool model is the first
caller to combine Task-tool dispatch with bounded parallel-pool admission and
wait-for-any semantics. If the Task tool does not natively expose
wait-for-any, FR6 has three options: (a) realise the wait via the Agent tool
instead (different agent registry, different output discipline); (b) emulate
wait-for-any by polling or via a host-specific capability flag owned by
`work-002`'s `feature-001-profile-driven-generator`; (c) escalate to a new
host capability requirement under FR5/work-002.

**Source:** /aid-specify reviewer pass on feature-009 SPEC (2026-05-23, Finding
#6) — clean-context reviewer flagged the precedent claim as overstated and
recommended escalating to an Open Question rather than asserting that
precedent exists.

**Impact:** Medium. Affects implementation strategy and may pull in a small
change in `work-002`'s capability registry. Does **not** affect the pool
algorithm itself, the `MaxConcurrent` parameter, or the failure-block-radius
semantics. Resolution is best handled before `/aid-detail` decomposes
feature-009 into tasks, since the chosen primitive shapes the
dispatch-related tasks.

**Suggested:** Investigate during `/aid-plan` (or earlier if the user wants
to resolve now). Likely outcome is (b) — capability flag owned by work-002
with NFR4 graceful degradation to sequential when the flag is absent —
since that matches the existing `background_execution` pattern. But this is
a guess; the host-tool surface needs to be checked.

**Status:** Pending

---

*All 5 historical IQs (IQ1–IQ5) were resolved during /aid-interview cross-reference cycles; see Resolved Q&A below for audit trail.*

### Resolved Q&A (historical audit trail)

| # | Topic | Resolution |
|---|-------|------------|
| IQ1 | FR3-M3 native skill chaining unsupported by host tools | **Answered** — Redefined as hook-driven/user-confirmed auto-advance; ultimately dropped in fresh-eyes reshape (M3 fights the platform). |
| IQ2 | KB stale across ~14 docs (pre-cleanup artifact model) | **Answered** — KB re-synced in place; 12 docs corrected; DISCOVERY-STATE Q181 resolved. |
| IQ3 | FR5 must subsume/fix Codex installer bug (H6) | **Answered** — Acknowledged; H6 retired by work-002. |
| IQ4 | §2 benchmark evidence trail clarity | **Answered** — §2 rewritten with the 3-group comparison. |
| IQ5 | feature-008 "bonus/stretch" wording | **Answered** — feature-008 confirmed Should; later dropped entirely in the reshape. |

## Lifecycle History

| # | Date | Phase Transition / Gate | Grade | Notes |
|---|------|------------------------|-------|-------|
| 1 | 2026-05-22 | /aid-interview complete — all 10 sections approved | — | Initial interview, 10 sections, user-approved scope |
| 2 | 2026-05-22 | Feature Decomposition — 10 features created | — | feature-001 through feature-010 (per original FR-decomposition) |
| 3 | 2026-05-22 | Cross-Reference (first pass) | C (resolved) | 8 findings (2 MEDIUM, 3 LOW, 2 MINOR, 1 no-defect); all resolved via IQ1–IQ5 + 3 direct fixes. KB re-synced. |
| 4 | 2026-05-22 | Cross-Reference (re-run) | A | Three independent reviewer passes C → B → A; cleared for /aid-specify. |
| 5 | 2026-05-22 | Fresh-eyes reshape (option B) | — | Independent critique flagged scope creep (4 pain points → 10 features + 8 CRs). Reshape: 5 features survive (002 / 004 / 005 / 007 / 009); feature-001 (FR5) moved to **`work-002-canonical-generator`** (sequenced first); features 003 / 006 / 008 / 010 deleted. CR1–CR6 and CR8 retired; CR7 retained (later superseded by FR2). |
| 6 | 2026-05-23 | Split — `work-003-traceability` extracted | A (carried) | FR4 (progress traceability), pain-point #4, and `feature-007` moved to dedicated `work-003-traceability`. work-001 reduced to 4 features (FR1 + FR2 + FR3 + FR6) on grade A. |
| 7 | 2026-05-23 | CW4: state files migrated to area-STATE shape | — | INTERVIEW-STATE.md + 4 feature STATE.md absorbed into this STATE.md per the new FR2 rule from work-003. Spec contents (SPEC.md, REQUIREMENTS.md) unchanged. |
| 8 | 2026-05-23 | feature-009 SPEC.md revised — wave model → pool model | needs re-grade | User clarification before /aid-plan: pool of bounded agents (default `MaxConcurrent=5`, configurable via new aid-init question stored in `STATE.md`); ready-set advances continuously on every completion (not after wave joins); failure blocks only transitive descendants (AND-only deps); wave barriers — when wanted — are expressed as graph dependencies, not a first-class execution concept. Spec sections touched: Change Log, Description, ACs, Data Model, Feature Flow, Layers & Components, Constraints & Boundaries. Other 3 features unchanged. |
| 9 | 2026-05-23 | feature-009 SPEC.md — first re-review after revision | **D+** (vs A+ minimum) | Clean-context reviewer dispatched via /aid-specify State 5 (5m08s, within 5-12m band). 10 findings: 2 HIGH (per-task state contract drift across features 002/004/005/009 + SKILL.md line-citation drift from subagent-visibility-patch), 4 MEDIUM (ready-queue/ready-set vocab; Q-number brittleness; NFR4 user-set-value silent; Task-tool precedent overstated), 3 LOW, 1 MINOR. Algorithm itself sound — issues are hygiene + alignment with shipped FR2. |
| 10 | 2026-05-23 | feature-009 SPEC.md — fix-pass after re-review | pending re-grade | Applied 8 mechanical fixes (citations re-anchored to section names; "ready queue" → "ready set + FIFO admission"; AC6 brittleness fix; pull-quote schema reconciled; NFR4 degraded-host log; pool observability extends EXECUTE-WAVE drill-down; trust-boundary widening explicit; "CW8" tag dropped). Per-task state contract deferred to /aid-plan (cross-feature, finding #1 user choice "c"). Task-tool precedent raised as IQ6 in this STATE.md (finding #6 user choice "escalate"). |
| 11 | 2026-05-23 | feature-009 SPEC.md — second re-review after fix-pass-1 | **D+** (vs A+ minimum) | Clean-context reviewer pass-2 dispatched via /aid-specify State 5 (5m34s, within 5-12m band). Significant improvement (7 of 10 prior findings cleanly resolved; IQ6 escalation handled by the book), but worst-issue-dominates rule still pulls grade to D+: 1 HIGH (Finding #1 partial regression — deferment applied to 3 summary places but missed 4 in-line places where the algorithm reads/writes per-task state) + 1 MEDIUM (NFR4 cite broken — NFR4 was relocated to work-003 when the traceability concerns split) + 2 LOW (EXECUTE-WAVE icon vocab mismatch; 3 hardcoded Q7 body refs not swept) + 1 MINOR (cosmetic at Layers Data row). Algorithm still sound — issues are sweep-width and post-split staleness. |
| 12 | 2026-05-23 | feature-009 SPEC.md — fix-pass-2 after second re-review | pending re-grade | Applied all 5 fixes mechanically (no design decisions required; prior user directives covered the approach). Per-task contract deferment swept through the 4 in-line locations. NFR4 cite fixed by inlining the principle and noting the work-003 relocation. EXECUTE-WAVE icon vocabulary now reuses existing `(queued)` and explicitly supplements with `⊘ blocked`. 3 descriptive "Q7" body refs replaced with position-based phrasing; prescriptive Layers row retains "Q7". Minor cosmetic acknowledged FR2-shipped shape. Re-dispatch reviewer for pass-3 grade. |
| 13 | 2026-05-23 | feature-009 SPEC.md — third re-review after fix-pass-2 | **A+** ✅ | Clean-context reviewer pass-3 (3m53s, beat 5-12m band). **No findings.** Spec is ready for /aid-plan. Two micro-observations recorded as out-of-scope: (a) the "FR1 /" prefix in the observability paragraph is technically redundant with the `work-003-traceability feature-001-you-are-here-heartbeat AC4` cite that follows — below MINOR; (b) work-003 SPEC's own queued-glyph (`(blank) queued`) drifts from canonical `(queued)` — orthogonal to feature-009. Reviewer also surfaced unrelated work-level staleness: `work-001-aid-lite/STATE.md` L5 says Minimum Grade **A** while project STATE.md says **A+** — not a feature-009 issue; we used the project minimum per the canonical aid-specify skill. Feature-009 is **READY**. |
| 14 | 2026-05-24 | REQUIREMENTS refresh — FR6 pool model + per-area STATE | — | Canonical REQUIREMENTS aligned with feature-009's revised pool model (FR6 + §9 ACs expanded from 1 to 6) and with work-003's deployed FR2 area-STATE rule (§5 scope-addition rewritten — `task-NNN.md` stays 6-section flat, per-task state in work `STATE.md ## Tasks Status`; two-zone proposal retired). Cascade flagged for feature SPECs 002/004/005/009. |
| 15 | 2026-05-24 | Adaptiveness scope additions (sufficiency analysis) | — | Sufficiency analysis identified two adaptiveness gaps the 4 features didn't address: (1) **type-aware lite-path routing** (FR1 extension — bug fix / single doc / small refactor / small new feature each get a sub-path tuned to their ceremony floor) — realised by extending feature-005; (2) **NEW FR8 recipes catalog** — instantiable lite-path templates for repetitive small-work patterns (bug-fix, method-refactor, add-crud-endpoint, write-release-note, add-unit-test seed) — realised by **new feature-011-recipes**. REQUIREMENTS §4 In Scope, §5 FR1, §5 FR8, §9 FR1 ext, §9 FR8, §10 Priority + pain-point coverage all updated. Feature-005 moves to In Discussion (needs re-spec); feature-011 added as Pending Creation. |
