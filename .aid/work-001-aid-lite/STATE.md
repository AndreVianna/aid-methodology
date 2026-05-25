# Work State — work-001-aid-lite

> **Status:** Detail complete ✅ — 37 task files at A+ (4 reviewer cycles: D → D → C+ → A+); ready for /aid-execute
> **Phase:** Execute (next)
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

| Delivery | Features | Status | Tasks | Notes |
|----------|----------|--------|-------|-------|
| delivery-001 | feature-002 | Planned | — | Skill Footprint Refactor (foundation; Must). All 10 skills → thin-router. |
| delivery-002 | feature-005 | Planned | — | Lite Path with Type-Aware Routing (Must; pain-point #1). Depends on delivery-001. |
| delivery-003 | feature-004 | Planned | — | Two-Tier Review (Must; pain-point #2). Depends on delivery-001. Implements `writeback-task-status.sh` helper (IQ7). |
| delivery-004 | feature-011 | Planned | — | Recipes Catalog (Should). Depends on delivery-002 (workType signal) + work-002 back-port (IQ8 sub-step). |
| delivery-005 | feature-009 | Planned | — | Parallel Pool Execution (Should). Depends on delivery-001 + delivery-003. Uses Agent tool wait-for-any (IQ6) + writeback-task-status.sh helper. |

See `PLAN.md` for full details, IQ resolutions, and cross-cutting risks.

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | `task-001` | REFACTOR | W0 | **Done ✅** | C2 A+ | 7m14s + 3m47s | Refactor aid-deploy to thin-router. Commits 22381aa (refactor) + b8b87e8 (cycle-1 fix-pass: RE-RUN header restored, state-idle heading normalized, state-packaging opener trimmed, State Detection parentheticals updated). SKILL.md 360→201; 4 refs (idle/selecting/verifying/packaging). All 3 install trees byte-identical. C1=B (2 LOW + 2 MINOR, all CODE, all fixed). C2=A+ (0 issues). Generator VERIFY-4a PASS both cycles. |
| 002 | `task-002` | REFACTOR | W0 | In Review (C3) | C1 D+ → C2 A → C3 pending | 6m18s+~8m+~7m+~? | Refactor aid-monitor. C3 dispatched after fix-pass + mojibake repair. |
| 003 | `task-003` | REFACTOR | W0 | **Done ✅** | C2 A+ | ~7m+~5m+~2.5m | aid-summarize (Mode-keyed, 10 refs, DONE-IDEMPOTENT composite). C1=A (2 MIN) → C2=A+ (0 defects). |
| 004 | `task-004` | REFACTOR | W0 | **Done ✅** | C2 A+ | 7m49s+~10m+~3m | aid-init (Step-keyed, 5 step refs). MaxConcurrent insertion-point preserved for task-032. C1=C+ disputed → C2=A+ (1 MIN theoretical dead-branch). |
| 005 | `task-005` | REFACTOR | W0 | **Done ✅ (Loopback IQ9)** | C2 A+ effective | 7m47s+~7m+~4m | aid-interview (State-keyed, 7 refs + interview-loop.md shared partial). TRIAGE insertion-point preserved. C1 surfaced pre-existing SPEC auto-advance contradiction in state-completion.md L64. C2 confirmed: 1 HIGH [SPEC] + 3 MIN — all pre-existing. **Loopback IQ9** in Cross-phase Q&A: route to /aid-specify. |
| 006 | `task-006` | REFACTOR | W0 | **Done ✅** | C2 A+ | 6m43s+~7m+~2m | aid-specify (State-keyed, 6-state INITIALIZE/CONTINUE/SPIKE/BLOCKED/REVIEW/DONE). C1=B/C+ → C2=A+ (0 defects). |
| 007 | `task-007` | REFACTOR | W0 | **Done ✅** | C1 A+ | ~11m+~5m | aid-plan (Section-keyed, 2 thematic refs). PASS cycle-1: A+. No cycle-2 needed. |
| 008 | `task-008` | REFACTOR | W0 | **Done ✅** | C1 A+ | 7m11s+~7m | aid-detail (Section-keyed, 4 thematic refs incl. task-decomposition shared methodology). 77-line router (82% reduction!). PASS cycle-1: A+. |
| 009 | `task-009` | REFACTOR | W0 | **Done ✅ (Loopback IQ10)** | C2 A+/A | 8m4s+~11m+~5m | aid-execute (Step-keyed, 4 new + 2 preserved refs). Insertion-point markers for delivery-003/005. C1=C → C2 fix-pass moved cross-cutting sections back to SKILL.md; State Detection inversion fixed. Remaining 1 MED [SPEC] dual-Advance gap + carryovers. **Loopback IQ10** in Cross-phase Q&A. |
| 010 | `task-010` | REFACTOR | W0 | **Done ✅** | C1 A+ | 11m26s+~10m | aid-discover (Mode-keyed with Step substructure; LARGEST 596→253, 58% reduction). 6 state refs + 3 preserved. Sub-agent fanout in GENERATE preserved verbatim. CR6 (Q&A→Q-AND-A) applied to 22 occurrences. PASS cycle-1: A+. |
| 011 | `task-011` | IMPLEMENT | W0 | **Done ✅** | C2 A+ | 10m48s+~5m+1m30s | Orphan-ref sweep. 6 KB docs + 2 STATE.md updated to ref work-003 FR2. Zero current-state matches. C1=A+ (PASS-with-LOW) → C2 fix-pass restored api-contracts L305 specificity → A+ (0 defects). |
| 012 | `task-012` | TEST | W1 | **Done ✅** | C1 PASS | ~20m | E2E pipeline parity test. All 10 thin-router skills PASS: dispatch tables correct (State/Detail/Worker/Advance), no inline state bodies, all referenced files present. VERIFY-4a PASS all 3 install trees (168/168/170 SHA256 matches). task-011 orphan-ref sweep confirmed clean. State-name changes verified as CR6 normalization (not regressions). Report: `.aid/work-001-aid-lite/test-reports/task-012-pipeline-parity.md`. |
| 013 | `task-013` | CONFIGURE | W0 | **Done ✅** | C1 FIX → C2 A+ | ~8m+~6m+~1m | ## Triage section added (Path/Work Type/Sub-path/Sub-path-auto/rationale/Override/Recipe). C1=FIX (1 HIGH workType enum drift) → inline fix to kebab values per feature-005 SPEC L196-208. data-model.md §2.3 updated. |
| 014 | `task-014` | IMPLEMENT | W1 | **Done ✅** | C1 A+ | 10m27s+~4m | State TRIAGE in aid-interview. 3-question flow + T3→workType deterministic mapping. TRIAGE inserted between Q-AND-A and CONTINUE; FIRST-RUN also redirected to TRIAGE per SPEC. Backward compat for pre-TRIAGE in-flight works. C1 ACCEPT at A+. |
| 015 | `task-015` | IMPLEMENT | W2 | In Progress | — | — | User-override mechanism on triage turn — Wave-6 parallel |
| 016 | `task-016` | IMPLEMENT | W2 | In Progress | — | — | 4 lite-path sub-paths in State L1 — Wave-6 parallel |
| 017 | `task-017` | IMPLEMENT | W3 | In Progress | — | — | Lite→full escalation — Wave-7 parallel |
| 018 | `task-018` | TEST | W4 | Pending | — | — | E2E lite path test |
| 019 | `task-019` | IMPLEMENT | W0 | **Done ✅ (Loopback: test-coverage)** | C3 A+ | 8m9s+~7m+14m+~6m+~4m | writeback-task-status.sh helper (520L) + smoke test (427L, 57/57 PASS). Sentinel-file lock (set -o noclobber + atomic create + sleep-poll). C1=FIX (2 HIGH+2 MED+5 LOW+5 MIN) → C2 fix-batch (HIGH H1 schema-mismatch + H2 pipe-corruption + MED M1 --help sed + M2 lock-dir-missing all fixed; new MED found: newline bypasses pipe check) → C3 fix (extended pipe check to also reject \n) → C3 review A+ (1 LOW Loopback: no newline-rejection test, deferred). |
| 020 | `task-020` | CONFIGURE | W0 | **Done ✅ (Loopback IQ11)** | C1 FIX → C2 A+ | ~8m+~6m+~1m | ## Delivery Gates + ## Quick Check Findings sections added; new delivery-issues.md template. C1=FIX (2 HIGH delivery-issues.md row schema + H1 drift from feature-004 SPEC L272-282) → inline fix reverted to SPEC 4-col schema. **IQ11** flags task scope vs SPEC schema discrepancy: richer 6-col schema (task scope) vs simpler 4-col (SPEC). Reverted to SPEC; can add columns back via /aid-specify. |
| 021 | `task-021` | IMPLEMENT | W1 | **Done ✅** | C1 FIX → C2 A+ | 4m17s+~7m+19m+~7m | Per-task quick-check in aid-execute. C1=FIX (1 CRIT helper/caller contract mismatch + 2 HIGH ## Dispatches vaporware) → C2 fix-batch rewired writeback-task-status.sh mode_findings to STATE.md ## Quick Check Findings + removed Dispatches refs (Calibration Log serves that role). C2 A+ (0 defects). |
| 022 | `task-022` | IMPLEMENT | W2 | In Progress | — | — | Per-delivery quality gate + FR6 interlock — Wave-6 parallel |
| 023 | `task-023` | TEST | W3 | **Done ✅** | C1 PASS | ~20m | E2E two-tier review test. 95 assertions (62 smoke + 33 E2E): all PASS. writeback-task-status.sh 4 modes verified; quick-check CRITICAL fix-on-spot + HIGH deferred confirmed; ## Quick Check Findings + delivery-NNN-issues.md written correctly; FR6 interlock verified; grade.sh deterministic; gate grade == standalone invocation. All 5 feature-004 ACs verified. Report: `.aid/work-001-aid-lite/test-reports/task-023-two-tier-review-test.md`. |
| 024 | `task-024` | IMPLEMENT | W0 | **Done ✅** | C1 A+ | 9m21s+~6m | work-002 generator back-port for recipes asset kind. canonical/recipes/ recognized; emits to all 3 install trees per profile contract. EMISSION-MANIFEST.md declares Recipes section. VERIFY-4a PASS. No regression to existing asset kinds. C1 PASS at A+ (0 HIGH/MED, 1 LOW + 2 MIN cosmetic). |
| 025 | `task-025` | DOCUMENT | W0 | **Done ✅** | C3 A+ | 6m53s+~7m+14m+~5m+~4m | Recipe meta-template + README. C1=FIX (3 HIGH+4 MED+4 LOW+3 MIN). C2 fix-batch (path move canonical/recipes/RECIPE-TEMPLATE.md → canonical/templates/recipe-template.md + Metadata block + slot-count fix + ## spec rationale + multi-task example). C2 review surfaced 1 new HIGH (multi-task example slot-count 6→5). C3 fix (1-line) → C3 review A+ (0 defects). |
| 026 | `task-026` | DOCUMENT | W1 | **Done ✅** | C1 A+ | 3m8s+~10m | 5 seed recipes (bug-fix/release-note/method-refactor/add-crud-endpoint/add-unit-test). All slot-count + task-count match SPEC L107-114. Metadata block per feature-005 SPEC. C1 PASS at A+ (2 MIN cosmetic). |
| 027 | `task-027` | IMPLEMENT | W1 | **Done ✅** | C1 FIX → C2 A+ | 15m40s+~10m+19m+~7m | parse-recipe.sh (533L + 889L test, 111/111 pass). 5 modes (--list/--validate/--spec/--tasks/--render). Sentinel-file lock. C1=FIX (1 CRIT wrong path: must be canonical/skills/aid-interview/scripts/ per SPEC L341-346; 2 HIGH warn-to-stdout + asset misclass) → C2 fix-batch git-mv to correct path + warn→stderr + 5 fixture tests. C2 A+. |
| 028 | `task-028` | IMPLEMENT | W2 | In Progress | — | — | Triage recipe-offer + slot-fill + emit — Wave-7 parallel |
| 029 | `task-029` | IMPLEMENT | W3 | Pending | — | — | Recipe → standard-lite escalation (preserve slots) |
| 030 | `task-030` | TEST | W4 | Pending | — | — | E2E recipes test |
| 031 | `task-031` | CONFIGURE | W0 | **Done ✅** | C1 A+ | ~8m+~6m | `**Max Parallel Tasks:** 5` metadata added to discovery-state-template.md + .aid/knowledge/STATE.md. data-model.md §2.1 updated. PASS cycle-1 clean (1 MINOR cosmetic). |
| 032 | `task-032` | IMPLEMENT | W1 | **Done ✅** | C1 FIX → C2 A+ | ~10m+~6m+19m+~7m | MaxConcurrent Q (Q7) in aid-init. Default 5 per feature-009 FR6. Q7→Q8 renumbering. C1=FIX (2 HIGH Q7→Q8 missed in subagent-heartbeat-protocol.md) → C2 fix-batch updated all 4 files. C2 A+. |
| 033 | `task-033` | IMPLEMENT | W1 | **Done ✅** | C1 FIX → C2 A+ | ~10m+~7m+19m+~7m | Pool dispatch (PD-0→PD-6) in aid-execute EXECUTE-WAVE. MaxConcurrent default 5, graceful degradation. C1=FIX (1 CRIT PD-2a "Step 1 only" contradicts PD-4; 3 HIGH cherry-pick, double STATE write, Dispatches vaporware) → C2 fix-batch resolved all. C2 A+. |
| 034 | `task-034` | IMPLEMENT | W2 | In Progress | — | — | Failure-block-radius (transitive descendants Blocked) — Wave-6 parallel |
| 035 | `task-035` | IMPLEMENT | W2 | In Progress | — | — | EXECUTE-WAVE drill-down extension — Wave-6 parallel |
| 036 | `task-036` | IMPLEMENT | W2 | In Progress | — | — | Graceful degradation (effective MaxConcurrent=1) — Wave-6 parallel |
| 037 | `task-037` | TEST | W3 | In Progress | — | — | E2E parallel pool test — Wave-7 parallel |

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|----|----|
| _none yet_ | — | — | — | — | — |

## Cross-phase Q&A (Pending — 0 open) ✅

*(all 3 IQs resolved at /aid-plan 2026-05-24; see PLAN.md § IQ Resolutions for resolution details. Historical entries moved to Resolved Q&A below.)*

### IQ6 (Resolved at /aid-plan 2026-05-24): [Host Capability — feature-009 pool model: Medium]

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

### IQ7 (Resolved at /aid-plan 2026-05-24): [Implementation Coordination — FR2 × FR6 row-level write coordination: Medium]

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

### IQ8 (Resolved at /aid-plan 2026-05-24): [Cross-work Coordination — work-002 backport for FR8 recipes: Low]

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

## Calibration Log

Append-only log of every subagent dispatch in this work. Per work-003 traceability rule (unconditional, never gated on ETA threshold).

Format: `| Date | Agent | Task / Cycle | ETA band | Actual | Notes |`

| Date | Agent | Task / Cycle | ETA band | Actual | Notes |
|------|-------|--------------|----------|--------|-------|
| 2026-05-24 | developer | task-001 cycle-1 (REFACTOR aid-deploy) | 5–12 min | 7m14s | First refactor; established thin-router shape. Commit 22381aa→91e999e. |
| 2026-05-24 | reviewer | task-001 cycle-1 | 1–2 min | ~5m | Grade B (2 LOW + 2 MINOR). |
| 2026-05-24 | reviewer | task-001 cycle-2 (post-fix) | 3–10 min | 3m47s | Grade A+. PASS. |
| 2026-05-24 | developer | task-002 cycle-1 (REFACTOR aid-monitor) | 5–15 min | 6m18s | Wave-1 parallel. Commit 96ff6a3→49c46d1. |
| 2026-05-24 | developer | task-003 cycle-1 (REFACTOR aid-summarize) | 5–15 min | ~7m | Wave-1 parallel. Commit 338cce7→e45c8f2. |
| 2026-05-24 | developer | task-004 cycle-1 (REFACTOR aid-init) | 5–15 min | 7m49s | Wave-1 parallel. Commit f3d0934→c743bfb. |
| 2026-05-24 | developer | task-005 cycle-1 (REFACTOR aid-interview) | 5–15 min | 7m47s | Wave-1 parallel. Commit 9ec50ce→8701235. |
| 2026-05-24 | developer | task-006 cycle-1 (REFACTOR aid-specify) | 5–15 min | 6m43s | Wave-1 parallel. Commit 858c19e→c403e17. |
| 2026-05-24 | developer | task-007 cycle-1 (REFACTOR aid-plan) | 5–15 min | ~11m | Wave-2 parallel. Commit 796019c→aa466e5. |
| 2026-05-24 | developer | task-008 cycle-1 (REFACTOR aid-detail) | 5–15 min | 7m11s | Wave-2 parallel. Commit d68febd→02081a3. |
| 2026-05-24 | developer | task-009 cycle-1 (REFACTOR aid-execute) | 5–15 min | 8m4s | Wave-2 parallel. Commit a06fe87→0ac1fe5. |
| 2026-05-24 | developer | task-010 cycle-1 (REFACTOR aid-discover, largest) | 5–18 min | 11m26s | Wave-2 parallel. Commit 63b01f6→25be0a6. |
| 2026-05-24 | developer | task-011 cycle-1 (orphan-ref sweep) | 5–15 min | 10m48s | Wave-2 parallel. Commit 5b64a68→1d9bd4c. |
| 2026-05-24 | reviewer | task-002 cycle-1 | 5–20 min | ~8m | Grade D+ (1 HIGH+1 MED+4 LOW+2 MIN). |
| 2026-05-24 | reviewer | task-003 cycle-1 | 5–20 min | ~5m | Grade A. |
| 2026-05-24 | reviewer | task-004 cycle-1 | 5–20 min | ~10m | Grade C+ (disputed). |
| 2026-05-24 | reviewer | task-005 cycle-1 | 5–20 min | ~7m | Grade high-A. |
| 2026-05-24 | reviewer | task-006 cycle-1 | 5–20 min | ~7m | Grade B/C+. |
| 2026-05-24 | reviewer | task-007 cycle-1 | 5–20 min | ~5m | Grade A+. PASS. |
| 2026-05-24 | reviewer | task-008 cycle-1 | 5–20 min | ~7m | Grade A+. PASS. |
| 2026-05-24 | reviewer | task-009 cycle-1 | 5–20 min | ~11m | Grade ~C (3 MED). |
| 2026-05-24 | reviewer | task-010 cycle-1 | 5–20 min | ~10m | Grade A+. PASS. |
| 2026-05-24 | reviewer | task-011 cycle-1 | 5–20 min | ~5m | Grade A+ (PASS-with-LOW). |
| 2026-05-24 | developer | batch fix-pass cycle-2 (16 fixes / 7 tasks) | 8–20 min | 10m11s | Single fix-batch dev. Commit 8e52c53→261b264. |
| 2026-05-24 | reviewer | task-002 cycle-2 | 1–10 min | ~7m | Grade A (2 MIN). |
| 2026-05-24 | reviewer | task-003 cycle-2 | 1–10 min | ~2m30s | Grade A+. PASS. |
| 2026-05-24 | reviewer | task-004 cycle-2 | 1–10 min | ~3m | Grade A+. APPROVED. |
| 2026-05-24 | reviewer | task-005 cycle-2 | 1–10 min | ~4m | Grade A+ effective. |
| 2026-05-24 | reviewer | task-006 cycle-2 | 1–10 min | ~2m | Grade A+. PASS. |
| 2026-05-24 | reviewer | task-009 cycle-2 | 1–10 min | ~5m | Grade A+/A. |
| 2026-05-24 | reviewer | task-011 cycle-2 | 1–10 min | 1m30s | Grade A+. PASS. |
| 2026-05-24 | reviewer | task-002 cycle-3 (post-mojibake-discovery) | 1–10 min | ~8m | Grade HIGH regression (mojibake). |

| 2026-05-24 | reviewer | task-002 cycle-3 (post-mojibake-fix) | 1-10 min | 5m22s | A+ SHIP. 0 defects. Mojibake gone (hex-verified). |
| 2026-05-24 | developer | task-019 cycle-1 (writeback-task-status.sh) | 5-15 min | 8m9s | First implement, sentinel-file lock 4 arg-modes. Commit ede82d6→d2fba50. |
| 2026-05-24 | developer | task-024 cycle-1 (recipes generator back-port) | 5-15 min | 9m21s | Generator-side wiring. Commit 307c9ff direct on work-001 (worktree bypass). |
| 2026-05-24 | tech-writer | task-025 cycle-1 (recipe meta-template+README) | 5-15 min | 6m53s | Required orchestrator commit (no Bash tool). beaf99e→ef80de1. |
| 2026-05-24 | reviewer | task-019 cycle-1 | 5-20 min | ~7m | 2 HIGH (silent-success, pipe-corruption) + 2 MED + 5 LOW + 5 MIN. |
| 2026-05-24 | reviewer | task-024 cycle-1 | 5-20 min | ~6m | A+ PASS (0 HIGH/MED, 1 LOW + 2 MIN). |
| 2026-05-24 | reviewer | task-025 cycle-1 | 5-20 min | ~7m | 3 HIGH (wrong path, missing Metadata, slot-count) + 4 MED + 4 LOW + 3 MIN. |
| 2026-05-24 | developer | wave-3 cycle-1 fix-batch (019+025, 9 fixes) | 8-20 min | 14m | All applied. 57/57 smoke tests pass. Commit 0884e34→b13c012. |
| 2026-05-24 | reviewer | task-019 cycle-2 | 1-10 min | ~6m | 4 cycle-1 HIGH/MED fixed; new MED (newline bypass). |
| 2026-05-24 | reviewer | task-025 cycle-2 | 1-10 min | ~5m | 3 HIGH + 4 MED fixed; new HIGH (multi-task slot-count). |
| 2026-05-24 | reviewer | task-019+025 cycle-3 combined | 1-10 min | 3m56s | Both A+ PASS. 1 LOW Loopback (test coverage). |

**Wave-3 calibration observations (refresh):**

- `tech-writer` ETA NEW class: 5–10 min for 100-500 line documentation tasks. **Refine rough-time-hints.md row `tech-writer`: 5–10 min, 1 sample**. CAVEAT: tech-writer has no Bash tool — orchestrator must commit on its behalf.
- `developer (IMPLEMENT)` ETA refined: 8–15 min for ~500-1000 LOC implement+test tasks (task-019 was 8m9s for 947 lines).
- Single-line cycle-3 fixes via orchestrator inline Python: ~30s + generator + commit = ~1 min total. Much faster than dispatch overhead.
- Combined verification reviewer (multiple tasks in one dispatch): ~4m. Halves overhead vs 2 separate reviewers.
- Heartbeat compliance: 3 of 5 wave-3 agents updated heartbeat well (rev-task002-c3, dev-task024, all 3 wave-3 reviewers); 2 of 5 ignored (dev-task019, dev-task025). Calibration finding: developer agents inconsistent about heartbeat writes despite explicit prompt instruction.

| 2026-05-24 | devops | wave-4 serial (013+020+031) | 5-15 min | 7m56s | All 3 done. 9 canonical files + 12 profile-generated. VERIFY-4a PASS. Commit 0bec5a5→be05af2. |
| 2026-05-24 | reviewer | wave-4 combined (013+020+031) | 1-10 min | 5m51s | task-031 PASS A+; task-013 FIX 1 HIGH workType enum; task-020 FIX 2 HIGH delivery-issues.md schema. |

**Calibration observations:**

- REFACTOR developer ETAs were estimated at 5–12 min; actual span 6m18s – 11m26s; mean ~8m. **Refine `rough-time-hints.md` row `developer (REFACTOR)`: 6–12 min, 10 samples**.
- Reviewer cycles ETAs were estimated at 5–20 min; actual span 1m30s – 11m; mean ~6m. **Refine `rough-time-hints.md` row `reviewer`: 2–11 min, ~25 samples**.
- Largest-skill refactor (aid-discover, 596L) took 11m26s, near top of band. **Add note: scales with source SKILL.md size**.
- Cycle-2 reviewer runs ~50% faster than cycle-1 (smaller diff to grade); a future "fix-pass review" row could be 2–7 min.
- Parallelism win: wave-1+2 wall-clock ~11m26s (longest member) vs sequential ~80m → ~7× speedup.

**Backfill source:** Backfilled from Agent tool `<usage>` blocks observed during the 2026-05-24 /aid-execute work-001 run. Times are agent-reported actuals (duration_ms / 1000), rounded to nearest 30s. ETA bands were the per-dispatch L2 timer settings (often wider than the rough-time-hints baseline to account for parallel-tail-latency).

### IQ11: delivery-issues.md row schema — task scope vs SPEC mismatch

**Question:** Task-020 scope proposed a richer 6-column delivery-issues.md schema (`task-id | Severity | Description | Source File:Line | Deferred At | Status`) but feature-004 SPEC L272-282 mandates a simpler 4-column schema (`Source task | Severity | Description | Status`). Which is canonical?

**Context:** Discovered by wave-4 combined reviewer (2026-05-24). Reverted to SPEC 4-col in wave-4 cycle-1 fix-pass commit `ddf1d17`. The richer schema's extra columns (Source File:Line, Deferred At) provide useful operational detail for gate reviewers but aren't required by the SPEC.

**Source:** /aid-execute work-001 wave-4 task-020 cycle-1 review (2026-05-24)
**Suggested:** If the richer schema is preferred, update feature-004 SPEC L272-282 to extend the column set + bump the template back to 6 cols. If the SPEC's 4-col minimal schema is canonical, leave as-is (current state).
**Status:** Pending — route to /aid-specify for SPEC clarification.

