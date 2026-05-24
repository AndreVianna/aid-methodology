# Work State — work-001-aid-lite

> **Status:** Specifying complete — all 5 features at A+; ready for /aid-plan (2 IQs open for resolution at planning)
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
| 002 | `feature-002-skill-footprint-refactor` | **Ready ✅** | **A+** (B → fix-pass → A+ in batch-2) | 0 open | FR3 thin-router. CR7 (two-zone task-template) **retired** by the 2026-05-24 REQUIREMENTS refresh. **Alignment Update section added** at top of Technical Specification; body retained as historical reference. Per-task state lives in work `STATE.md ## Tasks Status` (work-003 FR2). |
| 004 | `feature-004-two-tier-review` | **Ready ✅** | **A+** (B → fix-pass → A → final-fix → A+) | 1 open (IQ7 — row-level write coordination under FR6×per-area STATE; deferred to /aid-plan) | FR2 two-tier. Quick-check + delivery-gate records write through work `STATE.md` (per-task row + `## Delivery Gates` section) per 2026-05-24 REQUIREMENTS refresh. **Alignment Update section added** at top of Technical Specification; body retained as historical reference. |
| 005 | `feature-005-lite-path` | **Ready ✅** | **A+** (C → fix-pass → A+ in batch-2) | 0 open | FR1 lite path + **NEW type-aware sub-paths** (LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR / LITE-FEATURE) landed 2026-05-24. New "Type-Aware Lite Sub-paths" section + 4 new ACs added. Alignment Update for per-area STATE (INTERVIEW-STATE.md retired, two-zone retired). Body retained as historical reference. |
| 009 | `feature-009-parallel-task-execution` | **Ready ✅** | **A+** (Alignment Update resolved the previously-deferred per-task state contract; algorithm unchanged from the original A+ pass) | 1 open (IQ6 — Task-tool wait-for-any semantic; deferred to /aid-plan) | FR6 pool model (continuous, `MaxConcurrent` default 5). **Alignment Update section added** at top of Technical Specification — the previously-deferred per-task state contract is now resolved (work-003 FR2 area-STATE canonical). Algorithm unchanged. |
| 011 | `feature-011-recipes` | **Ready ✅** | **A+** (first-draft C → fix-pass → B → final-fix → A+) | 0 open | **NEW FR8 created 2026-05-24.** Full SPEC.md written (Description, User Stories, Priority Should, 6 ACs, Technical Specification with Data Model / Feature Flow / Layers & Components / Migration Plan / Constraints). Recipes catalog of pre-filled lite-path templates (5 seed recipes). YAML front-matter + body with `{{slot}}` placeholders. Soft dep on feature-005's type-aware triage (landed). |

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

## Cross-phase Q&A (Pending — 3 open)

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

### IQ7: [Implementation Coordination — FR2 × FR6 row-level write coordination: Medium]

**Question:** Under FR6 pool execution (feature-009) + FR2 two-tier review
(feature-004) + per-area STATE rule (work-003 FR2), N parallel tasks write
per-task rows + Quick Check sub-blocks concurrently to the SAME work
`STATE.md` file. The original spec's "single-writer per `task-NNN.md`"
coordination relied on file-level isolation. Under per-area STATE, we need
row-level (or block-level) coordination. What is the writeback contract?

**Context:** Each quick-check writes its task's row + a per-task block
(single-writer per task by construction); the gate's `AGGREGATE` step is
single-writer for the `## Delivery Gates` block. But concurrent row writes
to the shared file need a coordination mechanism — either work-003's
`writeback-state.sh` adapted to row scope, or a new row-level append
helper, or a global file lock.

**Source:** feature-004 fix-pass reviewer pass-2 finding #2 (Medium).

**Impact:** Medium. Affects implementation of feature-004 (quick-check
writes) and feature-009 (pool task status updates). Resolution is best
handled before /aid-detail decomposes either feature into tasks.

**Suggested:** Most likely a row-level append helper backed by file
locking (mirroring writeback-state.sh's per-section pattern). Decision
deferred to /aid-plan or early /aid-detail.

**Status:** Pending

---

### IQ8: [Cross-work Coordination — work-002 backport for FR8 recipes: Low]

**Question:** Adding `canonical/recipes/` (feature-011) requires a back-port
against work-002's shipped `feature-001-profile-driven-generator`: a new
`recipe` renderer (passthrough acceptable), a `recipes` kind entry in each
profile's `layout` field, and emission-manifest support for paths under
`recipes/`. What is the back-port path against the already-shipped work-002?

**Context:** work-002's generator has an asset-kind registry with per-kind
renderers (agents / skills / templates / rules); recipes is a new kind. The
SPEC for work-002 feature-001 doesn't define an "any new directory is
rendered" rule, so the registry needs the new entry.

**Source:** feature-011 first-draft review finding #3 (Medium).

**Impact:** Low. The back-port itself is small (≤ ~30 lines of changes
across 3-4 files). Affects work-002 ownership question: does this back-port
land as a new mini-feature in work-002, as a coordinated change-set
attributed to FR8 implementation, or under a maintainer-task rubric?

**Suggested:** Coordinated change-set attributed to FR8 implementation;
recorded in work-002's STATE.md Lifecycle History but executed as part of
the FR8 build. Decision deferred to /aid-plan.

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
| 18 | 2026-05-24 | **All 5 features at A+ ✅ — ready for /aid-plan.** | A+ × 5 | Final tally after iterative fix-pass cycles: feature-002 (B → fix-pass → A+), feature-004 (B → fix-pass → A → final-fix-pass → A+), feature-005 (C → fix-pass → A+), feature-009 (A+ throughout — Alignment Update resolved deferred per-task state contract without algorithm change), feature-011 (first-draft C → fix-pass → B → final-fix-pass → A+). Total reviewer dispatches across all cycles: 12 (3 for feature-009 originally, 5 in batch-1, 4 in batch-2, 2 in final-fix). Two IQs carry forward to /aid-plan: **IQ6** (Task-tool wait-for-any semantic for FR6 pool model) and **IQ7** (row-level write coordination under FR6 pool + per-area STATE). **IQ8** (work-002 backport for FR8 recipes generator support) is also Pending — total 3 IQs open. **work-001 is cleared for /aid-plan.** |
| 17 | 2026-05-24 | Batch fix-pass after 5-feature parallel reviewer batch | — | 5 parallel reviewers dispatched (feature-009 PASS A+; features 002/004 graded B; feature-005 graded C; feature-011 first-draft graded C). User directed full fix-pass across the 4 below-minimum features. 33 mechanical fix-pass edits applied via Python script (Edit tool blocked by bg-isolation guard mismatch; workaround used CLAUDE_JOB_DIR Python scripts run via Bash from the worktree): **feature-002** = 10 edits (5 LOWs + 5 MINs; NFR2 misleading parenthetical, 3 stale line counts, divergence-narrative rewrite, Layers row inline supersede marker, Owns bullet strike, Template surgery italic header, pull-quote pointer, soften work-002 claim); **feature-004** = 1 large edit adding 6 new bullets to the Alignment Update (SKILL.md line-cite drift surface, row-level write coordination → IQ7, Delivery Gate determinism rule retraction, delivery-NNN-issues.md vs ## Delivery Gates distinction, State Machines re-read note, cross-feature CR7 retraction); **feature-005** = 7 edits (T3 prose → workType kebab mapping table, Migration Plan addition for work-state-template.md ## Triage + data-model.md §2.3, cross-feature field-name fix, Triage block schema extension with Override/Sub-path-auto/Recipe + templated rationale, LITE-BUG-FIX circular-ref removal, State L1 sub-path branching flag, Alignment Update INTERVIEW-STATE.md template-create supersession note); **feature-011** = 15 edits (slot syntax escape `{!{`, slot-name lexical rule into Data Model, work-002 generator dependency back-port reality → IQ8, recipe-offer placement vs feature-005 user-override sequencing, ## Triage Recipe pick line, escalation INTERVIEW-STATE.md removal, seed-catalog 5-recipe shapes table, applies-to:* + chore-example reconciliation, multi-line input delimiter, grep -oE portability, task-count validation parallel rule, work-002 backport wording, scripts/ dir creation note, ## spec lowercase note, recipe-template.md own bullet). Plus 2 new IQs (IQ7 row-level write coordination, IQ8 work-002 backport) added to ## Cross-phase Q&A. Re-dispatching 4 parallel reviewers to verify A+ across the board. |
| 16 | 2026-05-24 | Batch /aid-specify — alignment + new feature creation | — | Per user directive ("review all the features and execute the pending specify process for the new one"), batched 5-feature operation in a single worktree session: **(a)** added "Alignment Update" sections to features 002, 004, 005, 009 at the top of their Technical Specification blocks — each section explicitly reconciles the SPEC body's two-zone task-NNN.md / Execution Record / INTERVIEW-STATE.md references to the work-003 FR2 per-area STATE rule (now canonical per the same-day REQUIREMENTS refresh); body sections kept as historical reference rather than rewritten in-line. **(b)** Added a substantial new "Type-Aware Lite Sub-paths (FR1 extension)" section + 4 new ACs to feature-005, documenting the LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR / LITE-FEATURE sub-paths, the triage emission shape, the user override flow, and the integration point with feature-011. **(c)** Created feature-011-recipes/SPEC.md from scratch — full first-draft SPEC with Description, User Stories, Priority (Should), 6 ACs from REQUIREMENTS, and Technical Specification covering Data Model (`canonical/recipes/` directory + recipe file shape + YAML front-matter + `{{slot}}` syntax), Feature Flow (recipe-offer step in lite-path triage + slot-fill loop + emission), Layers & Components, Migration Plan (additive), and Constraints. 5 features now staged for parallel reviewer dispatch. |
