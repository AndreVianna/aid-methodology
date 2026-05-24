# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Initial interview started | /aid-interview |
| 2026-05-22 | Captured objective, problem statement, stakeholders, and initial scope from opening answer | /aid-interview |
| 2026-05-22 | FR1 refined — lite capability is a fork inside aid-interview, not a new skill; lite path ends at execution-ready output (planning only) | /aid-interview |
| 2026-05-22 | FR1 — fork decided by 2–3 deterministic triage questions; lite path escalates to full if work proves large | /aid-interview |
| 2026-05-22 | FR2 — two-tier review: quick per-task check (major/critical only) + full A-grade gate per delivery with proportional reviewer | /aid-interview |
| 2026-05-22 | FR2 — per-task quick check fixes critical errors immediately (one fix), defers major and below to the delivery gate | /aid-interview |
| 2026-05-22 | FR3 — commit to all four footprint mechanisms (priority M1+M3, then M2+M4); full rollout across all 10 skills and 3 trees | /aid-interview |
| 2026-05-22 | Constraint added — the refactor must preserve the AID pipeline intent, phases, artifacts, gates, and the lite path | /aid-interview |
| 2026-05-22 | FR4 — progress traceability: P1 (you-are-here + heartbeat) + P3 (hook-emitted JSON/log event stream) as core; optional live HTML viewer as bonus; P4 dropped | /aid-interview |
| 2026-05-22 | FR5 added (O1) — profile-driven generation: one canonical source + per-host-tool profiles; new tools (Copilot CLI, Antigravity) onboarded by authoring a profile | /aid-interview |
| 2026-05-22 | FR6 added (O2) — parallel execution of independent tasks as default aid-execute behavior | /aid-interview |
| 2026-05-22 | FR7 added (O3) — self-telemetry: per-phase/skill/task timing built on the FR4 P3 event stream | /aid-interview |
| 2026-05-22 | Wrap-up — drafted §4 Out of Scope, §6 NFRs, §8 Assumptions & Dependencies, §9 Acceptance Criteria; recorded §10 Priority (Must FR5→FR3→FR2→FR1; Should FR4; Could FR6, FR7) | /aid-interview |
| 2026-05-22 | FR7 expanded to include token consumption and cost; FR5 profile gains per-tool capability flags; §8 — provider capability tracking + Codex/Cursor hook research delegated to aid-specify | /aid-interview |
| 2026-05-22 | Priority reconfirmed as Option A — measure-first (Option B) considered and declined | /aid-interview |
| 2026-05-22 | Quality check — §4 In Scope completed to cover all 7 FRs (was missing FR5–FR7) | /aid-interview |
| 2026-05-22 | Interview complete — approved | /aid-interview |
| 2026-05-22 | Feature decomposition — 10 features created; user elevated feature-006 (FR4-P3) and feature-009 (FR6) to Must, feature-008 (FR4-P2) to Should; §10 reconciled | /aid-interview |
| 2026-05-22 | Cross-reference IQ1 — FR3-M3 redefined as hook-driven/user-confirmed auto-advance (no host tool has native skill chaining); §8 hook support confirmed for all 3 host tools | /aid-interview |
| 2026-05-22 | Cross-reference IQ2 — KB found stale across ~14 docs (pre-cleanup artifact model); logged DISCOVERY-STATE Q181; §8 notes KB re-discovery required before /aid-specify | /aid-interview |
| 2026-05-22 | Cross-reference IQ2 resolved — KB re-synced in place: 12 docs corrected to the current artifact model, project-index.md regenerated, verified; DISCOVERY-STATE Q181 resolved; §8 updated | /aid-interview |
| 2026-05-22 | Cross-reference IQ3 — §8 + NFR2 note that FR5 must subsume/fix the Codex installer bug (tech-debt H6); pre-existing broken Codex installs are the backward-compat baseline | /aid-interview |
| 2026-05-22 | FR1 — lite-path eligibility criteria defined (size/complexity: a single small delivery of a few simple tasks; small or no feature) | /aid-interview |
| 2026-05-22 | Cross-reference IQ4 — §2 rewritten with the concrete benchmark (3-group comparison; AID ~3h vs ~1h vs minutes; AID nets a gain only on large/complex work) as the evidence trail | /aid-interview |
| 2026-05-22 | Cross-reference IQ5 — feature-008 confirmed a committed Should; "bonus/stretch"/"optional" wording removed from FR4, §9, §10, and the feature SPEC | /aid-interview |
| 2026-05-22 | Cross-reference direct fixes — FR6 body marked Must per decomposition; FR3 "resolves H1" over-claim corrected (H3/H4 are FR5's scope); feature-005 "does not execute" made an explicit non-goal | /aid-interview |
| 2026-05-22 | Cross-reference (State 6) complete — all 8 findings resolved (IQ1–IQ5 + 3 direct fixes); validation grade C, re-run /aid-interview to re-grade | /aid-interview |
| 2026-05-22 | Cross-reference re-validation (State 6, grade C) — all 8 new findings fixed directly: §1/§2/FR6/feature-009 Discover-scope + "permits, not automatic" clarified, FR5→H4 terminology, FR3 sequencing note, FR7 retroactive-baseline note, §8 Antigravity caveat, Q181 doc-count reconciled to 12 | /aid-interview |
| 2026-05-22 | Cross-reference verification (State 6, grade B) — 2 LOW + 2 MINOR fixed: FR1 lite-path output contract (aid-execute input deferred to aid-specify); FR2 lite-delivery gate unit; FR3 "constraint" wording; §8 knowledge-summary residual trimmed | /aid-interview |
| 2026-05-22 | Cross-reference verification (State 6) — final independent grade A (C → B → A across passes), meets the A minimum; 3 cosmetic MINORs cleaned up. Cleared for /aid-specify | /aid-interview |
| 2026-05-22 | /aid-specify scope updates — FR1 lite-path output resolved (one consolidated work-root SPEC.md); task-NNN-STATE.md → task-NNN.md merge recorded as a scope addition; §8 refreshed with round-2 Codex/Cursor capability research | /aid-specify |
| 2026-05-23 | **Split: traceability moved to `work-003-traceability`.** FR4 (progress traceability), pain-point #4 ("no progress visibility"), and `feature-007-you-are-here-heartbeat` (renumbered to `feature-001` there) extracted to a dedicated work. Rationale: the traceability concern is orthogonal to the AID-Lite speed concern; separating them keeps each work's scope tight. NFR4 also moved; §1 success criterion about staying "informed and engaged" moved; §9 FR4 ACs moved; §10 Should bucket reduced to FR6 only. | split |
| 2026-05-24 | **REQUIREMENTS refresh after feature-009 pool revision + work-003 per-area STATE deployment.** (1) **FR6 expanded** in §5 and §9 to reflect the pool execution model that replaced the original wave-barrier framing: continuous admission, `MaxConcurrent` ceiling (default 5, configurable via a new `aid-init` question), transitive-descendant failure block, wave barriers expressed as graph dependencies. (2) **§5 scope-addition rewritten** to align with work-003's deployed FR2 area-STATE rule: per-task status lives in the per-work `.aid/work-NNN/STATE.md ## Tasks Status` row; `task-NNN.md` stays 6-section flat (Definition only). The original intent — retire `task-NNN-STATE.md` and consolidate per-task state — is achieved by work-003's per-area STATE consolidation rather than by a two-zone `task-NNN.md`. Feature SPECs (002, 004, 005, 009) currently carry the older two-zone assumption; a coordinated sweep to align them with this updated REQUIREMENTS is flagged for resolution at /aid-plan. | /aid-specify |
| 2026-05-22 | **Fresh-eyes scope reshape.** Independent critique flagged the work as over-engineered (4 user pain points → 10 features + 8 CRs). Reshaped to 5 features in this work + 1 feature split to work-002. FR5 moved to `work-002-canonical-generator` (sequenced first; the canonical-source consolidation unblocks single-source editing). Dropped: FR3-M3 auto-advance (fighting the platform), FR3-M2 hooks (no surviving consumer), FR4-P3 event stream + FR4-P2 HTML viewer (observability product nested in a methodology refactor), FR7 telemetry (speculative meta-work). FR3 simplified to M1 only with M4 folded in as an authoring discipline. FR4 simplified to P1 only as pure skill-body text (state-entry print + bracket-pair floor + ASCII state-map). Deleted features 003, 006, 008, 010. CR1–CR6 retired; CR7 (two-zone task-NNN.md) retained; CR8 retired. | reshape |

## 1. Objective

Deliver **AID Lite** — a faster, leaner way to apply the AID methodology to small
work. AID's **per-work pipeline** — Interview → Specify → Plan → Detail → Execute —
earns its overhead on large efforts, but is too slow and bureaucratic for small
tasks (debugging, small refactors, single documents). (Discover is a
once-per-project phase that builds the Knowledge Base; it runs before any work item
and is upstream of — and unaffected by — this effort.) The objective is to make AID
*competitive on speed* for small work while keeping the full rigor available for
large work.

**Success looks like:**

- A small task is **faster to complete through AID than through ad-hoc prompting**
  of the AI.
- The full pipeline remains intact and unaffected for large work.

## 2. Problem Statement

AID was run in a controlled benchmark against alternative approaches. The benchmark
showed that AID's overhead is not justified for small or medium work.

### The benchmark

**Task:** refactor one method in each of three Java classes to be adherent to DDD
and hexagonal architecture, with the associated unit tests — a small, well-scoped
change (3 classes, 1 method each, plus tests).

| Group | Approach | Outcome |
|-------|----------|---------|
| 1 | AID (full per-work pipeline) | **~3 hours total.** After 1 hour it had not yet finished `aid-detail`; the remaining ~2 hours executed the 8 tasks it had generated. |
| 2 | Claude Code, prompting the CLI directly to dispatch agents | **~1 hour.** Finished first — with 3–4 follow-up prompts to fix errors and failing tests, plus a couple more for style and linting. |
| 3 (control) | A developer editing the code directly | Finished a few minutes after Group 2. |

Repeating the benchmark across problem sizes gave a consistent result: **AID
delivered a net gain only on large, complex work** — efforts that would take weeks
were delivered in 3–4 days. For small and medium work, AID was the slowest of the
three approaches.

These figures come from observed benchmark runs, not instrumented telemetry (AID
has none today; FR7 self-telemetry was considered and *dropped* during the
fresh-eyes reshape — measure when there is a specific question, not speculatively).
They cover the per-work pipeline (Interview through Execute); Discover — a
once-per-project phase — is not part of this per-work comparison.

### Weaknesses the benchmark exposed

1. **Heavy pipeline for small work.** The Interview → Specify → Plan → Detail
   sequence before execution is too bureaucratic — over an hour on planning alone
   for a 3-class refactor, and `aid-detail` over-decomposed it into 8 tasks. For
   small, short work it takes longer than directly prompting the AI to do the work.
2. **Slow per-task execution.** Even small, atomic tasks take a long time in
   `aid-execute` (~15 minutes per task in the benchmark). Suspected causes: the
   per-task review → grade → fix loop, and/or non-optimal model selection.
3. **Heavy skills.** Each skill carries a full state machine; the large footprint
   may itself contribute to slowness. There is no mechanism for a skill to call
   another skill or otherwise offload work (hooks, chaining).
These are the main items raised; the interview remains open to additional
improvement opportunities.

## 3. Users & Stakeholders

| Stakeholder | Role | Interest |
|-------------|------|----------|
| AID end users | Developers running the methodology via Claude Code / Codex / Cursor | Primary — they feel the slowness and disengagement directly |
| AID methodology maintainer | Project owner | Defines, designs, and ships the improvements |

## 4. Scope

### In Scope

- A lite path inside `aid-interview` (an early fork) for small work — problem to
  execution-ready, no new skill (FR1).
- A two-tier review model for faster `aid-execute` (FR2).
- A **thin-router refactor** to reduce per-skill footprint (FR3 — **M1 only**;
  M4 folded in as a per-skill authoring discipline).
- **Parallel execution** of independent tasks by default (FR6).

> *Reshape note (2026-05-22):* originally also in scope: the four-mechanism FR3
> refactor (M3 hook-driven auto-advance + M2 mechanical-offload hooks — both
> **dropped**); FR4's hook-emitted event stream and HTML viewer (P2/P3 —
> **dropped**); profile-driven generation of install trees (FR5 — **moved to
> `work-002-canonical-generator`**, sequenced first); self-telemetry (FR7 —
> **dropped**). See §5 for the per-FR details and §10 for the reshaped
> priority/build order.

### Out of Scope

- Changing the AID methodology itself — its phases, artifacts, feedback loops, and
  quality gates are preserved (see §7).
- Execution of work by the lite path — the lite path stops at execution-ready
  output; `aid-execute` performs execution (FR1).
- Onboarding any specific new host tool — `work-002`'s generator makes future
  tools (Copilot CLI, Antigravity) cheap to add, but actually building a given new
  tree is separate work (and lives in its own work item).
- A fixed numeric speed SLA — NFR1 keeps the speed goal qualitative; with FR7
  dropped in the reshape, the comparison baseline is the documented benchmark in
  §2 rather than instrumented telemetry.

## 5. Functional Requirements

> Design for several of these is still under discussion; entries are
> capability-level and will be refined.

- **FR1 — Lite path via a fork in `aid-interview`.** `aid-interview` gains an early
  fork that routes a work item to either the **full path** (today's Interview →
  Specify → Plan → Detail pipeline) or a **lite path** for small work. This is *not*
  a new skill — the entry point stays `/aid-interview`, because the user often
  cannot tell upfront whether the work needs the full pipeline. The lite path
  collapses pre-execution planning into a fast, condensed flow and ends at
  **execution-ready output**; `aid-execute` remains the next step (the lite path
  does not execute). Applies to small work — one or no feature, a single small
  delivery, a few tasks (debug a bug, small refactor, write one document).

  The fork is decided by **2–3 quick deterministic triage questions** asked at the
  start of `aid-interview`, probing: (a) breadth — one/no feature vs. multiple
  features; (b) size — a few tasks vs. many; (c) type of work — bug fix / small
  refactor / single document vs. new feature or system. A deterministic rule maps
  the answers to a path.

  **Lite-path eligibility** is judged on size and complexity: a work qualifies for
  the lite path when it is a **single small delivery of a few simple tasks** — a
  small single feature, or no feature at all (a bug fix, a small refactor, or a
  simple artifact such as a short report). Typical scale: adding one small class,
  or changing an existing method together with its unit tests. The criterion is
  acknowledged as somewhat subjective and will be tuned with experience.

  If the lite path later discovers the work is actually large, it escalates to the
  full path rather than forcing a poor fit.

  **Lite-path output.** The lite path produces, per work, **one consolidated
  `SPEC.md` at the work root** plus `tasks/task-NNN.md` files — no feature folder, no
  per-feature `SPEC.md`, no `PLAN.md`. The work-root `SPEC.md` merges the condensed
  spec with the planning content (the single delivery, the dependency graph, the
  delivery-level acceptance criteria, the task list); a lite work is one-or-no
  feature, so per-work and per-feature scope coincide. `aid-execute` resolves the
  delivery descriptor by one rule — `PLAN.md` on the full path, the work-root
  `SPEC.md` on the lite path. FR2's per-delivery gate treats the lite work's single
  delivery (defined in that `SPEC.md`) as one delivery. *(Resolved during
  `/aid-specify` — feature-005.)*
- **FR2 — Two-tier review in `aid-execute`.** Replace today's per-task full quality
  gate (a review → fix → review loop to grade A on *every* task) with a two-tier
  model:
  - **Per-task quick check** — during execution, each task gets a single quick
    review pass, run once, with no grade loop, surfacing only **major and critical**
    errors. Purpose: catch showstoppers early so later tasks do not build on a
    broken one. Uses a lightweight (cheap-tier) reviewer. **Critical** errors
    (break the build, or break something a dependent task needs) get one immediate
    fix on the spot — no loop; **major** errors and below are logged and rolled
    into the per-delivery gate.
  - **Per-delivery quality gate** — at the end of the delivery (the full set of
    tasks that compose it), the rigorous gate runs the review → fix → review loop
    until grade ≥ minimum (A). The A-grade standard is enforced once per delivery
    instead of once per task.
  - **Proportional reviewer** — the delivery gate's reviewer model/effort scales
    with the complexity of the whole delivery.

  Net effect: the expensive review loop moves from N-times-per-delivery to once,
  and the Large-tier reviewer is right-sized to the delivery instead of running on
  every task. *Deferred to `aid-specify`:* exact trigger/location of the delivery
  gate (closing step of `aid-execute` vs. opening step of `aid-deploy`) and the
  delivery-complexity signal that drives the proportional reviewer. For lite-path work, the lite path's
  single small delivery is the gate's delivery unit (see FR1).
- **FR3 — Lighter skill footprint via thin-router refactor.** Reduce the weight of
  every skill so each invocation loads only what the running state needs. Refactor
  every skill into a **thin state router (M1)**: `SKILL.md` shrinks to frontmatter +
  pre-flight + state detection + a dispatch table; each state's detail moves to
  `references/state-{name}.md`, loaded only when that state runs. State-to-state
  progression remains user-driven (`/aid-{name}` re-invocation between states) —
  there is no hook-driven auto-advance.

  **M4 (sub-agent offload) survives as a per-skill authoring discipline inside
  M1:** the dispatch table's `Worker` column may point at a sub-agent for a state
  whose heavy work warrants offload (the way `aid-discover` already does), or at
  `inline` for trivial states. M4 is not a separate mechanism in this work.

  **Full rollout** — applied to all 10 skills (single-source via `canonical/` once
  `work-002` ships). Doing it uniformly addresses the skill-body triplication
  drift (tech-debt H1) on top of the canonical-source consolidation `work-002`
  delivers.

  *Reshape note (2026-05-22):* the original FR3 specified all four mechanisms
  (M1+M2+M3+M4) across two features. The fresh-eyes scope reshape dropped **M3**
  (hook-driven auto-advance — no host hook can solicit a keystroke; the resulting
  3-mode degradation ladder fought the platform) and **M2** (hook-based mechanical
  offload — its consumers, FR4-P3 and M3, are gone). Realized by `feature-002`
  (`feature-003` was deleted).
- **FR4 — Progress traceability.** *Moved to `work-003-traceability` on 2026-05-23;
  see that work's REQUIREMENTS.md and `feature-001-you-are-here-heartbeat` SPEC.*

- **FR5 — Profile-driven generation of install trees.** *Moved to
  `work-002-canonical-generator` during the fresh-eyes scope reshape (2026-05-22).*
  The 4-way asset duplication is real (tech-debt H1, H4, H6) but unrelated to the
  four user pain points this work addresses. Splitting FR5 into its own work,
  sequenced first, turns every subsequent edit to AID's skills / agents / templates
  (including this work's 5 surviving features) into single-source changes. See
  `.aid/work-002-canonical-generator/REQUIREMENTS.md` for the full requirements and
  `.aid/work-002-canonical-generator/features/feature-001-profile-driven-generator/SPEC.md`
  for the spec (already graded **A** in the prior cycle).
- **FR6 — Parallel task execution by default (continuous pool model).** Today
  `aid-execute` *permits* concurrent execution of independent tasks — those the
  execution graph leaves mutually independent — but does not do it automatically:
  the user must manually launch the parallel invocations. FR6 makes parallel
  execution the **automatic default** through a **continuous agent pool**:
  `aid-execute` maintains up to `MaxConcurrent` tasks in flight, and the *moment*
  any in-flight task completes (and its completion newly satisfies a downstream
  task's dependencies), the pool admits the next ready task — without waiting for
  a synchronized wave to join.

  - **Two bounds.** The pool is bounded by exactly two things: (a) the Execution
    Graph (correctness — a task may run only when all its `Depends On` tasks are
    `Done`), and (b) `MaxConcurrent` (resource cap — a ceiling on simultaneously
    in-flight tasks). The graph is non-negotiable; `MaxConcurrent` is tunable.
  - **`MaxConcurrent` configuration.** Default value is **5**. The value is set
    interactively during `aid-init` by a new question (Max Parallel Tasks)
    inserted in the existing question sequence, and persisted to
    `.aid/knowledge/STATE.md` top-of-file metadata as `**Max Parallel Tasks:** N`
    (same metadata pattern as `**Heartbeat Interval:**`).
  - **Failure semantics (transitive-descendant block).** When a task **Fails**
    (raises an Impediment that survives its one fix-on-spot), every task that
    depends on it — directly or transitively — is marked **Blocked** and never
    dispatched. Tasks in **unrelated chains** (no transitive dependency on the
    failed task) continue executing in the pool until natural completion. All
    `Depends On` edges are AND (no alternative paths); a single failure
    deterministically blocks its entire downstream subtree.
  - **Wave barriers expressed as dependencies, not a separate concept.** If
    planning needs `{D, E, F}` to wait until all of `{A, B, C}` are complete
    (e.g., a checkpoint), this is encoded in the Execution Graph as `D`, `E`,
    `F` each depending on `A`, `B`, `C` (or via a synthetic checkpoint task).
    The pool then honors the barrier through its normal readiness rule — no
    first-class "wave" concept in the executor.
  - **Graceful degradation.** On hosts whose sub-agent dispatch surface lacks
    a wait-for-any-completion primitive (capability flag owned by `work-002`'s
    `feature-001-profile-driven-generator`), `aid-execute` falls back to
    sequential dispatch (effective `MaxConcurrent` = 1), preserving correctness
    and the methodology, losing only the wall-time overlap. The user's
    configured `MaxConcurrent` becomes informational on such hosts;
    `aid-execute` emits a single info line at delivery start so the user is
    not surprised.

  *Note:* in real-world use the wall-time gain from parallelism alone was modest
  (the larger speed wins are FR2 and FR3); FR6 is included because pool-driven
  parallel-by-default is the correct execution behavior and complements them —
  each task still gets its FR2 per-task quick check, and the per-delivery gate
  still runs once. Per the post-reshape §10 priority table, FR6 is in the
  **Should** bucket (`feature-009`).
- **FR7 — Self-telemetry.** *Dropped during the fresh-eyes scope reshape
  (2026-05-22).* The independent critique noted: per-task token / cost is
  best-effort (host-tool session logs are not keyed to AID task IDs), the
  heuristic correlation needed a 5-rung confidence ladder to label its own
  uncertainty, and the whole purpose was *retroactive* measurement of whether
  FR1–FR6 worked. If FR2's two-tier review doesn't *visibly* speed execution on a
  known benchmark, no JSONL summary will rescue it. Measure when there is a
  specific question; do not build measurement infrastructure speculatively.

> **Scope addition (2026-05-22, during `/aid-specify`; updated 2026-05-24 to
> reflect work-003's deployed per-area STATE rule).** `task-NNN-STATE.md` is
> **retired** and the `implementation-state.md` template is **removed**. Per-task
> state is consolidated under **work-003's FR2 per-area STATE rule** (deployed):
>
> - **`task-NNN.md` stays 6-section flat** (Title, Type, Source, Depends on,
>   Scope, Acceptance Criteria) — the Definition only, written by `aid-detail`.
> - **Per-task status, review history, and dispatch records live in the per-work
>   `.aid/work-NNN/STATE.md ## Tasks Status` row** — written/updated by
>   `aid-execute` as the task progresses.
>
> The original intent of this scope addition — retire `task-NNN-STATE.md` and
> consolidate per-task state — is achieved by work-003's per-area STATE
> consolidation rather than by the originally-proposed two-zone `task-NNN.md`
> shape. A decision beyond the original FR1–FR7, surfaced and confirmed during
> feature specification; realized across feature-002 (`task-template.md` stays
> 6-section, no Execution Record scaffold; `implementation-state.md` deletion),
> feature-004 (per-task quick-check record + per-delivery gate record write
> through the work `STATE.md ## Tasks Status` row), feature-009 (pool admission
> reads task Status from the same row), and the core artifact model.
>
> **Cascade.** Feature SPECs 002, 004, 005, and 009 still describe the older
> two-zone `task-NNN.md` shape in their bodies — a coordinated sweep aligning
> them with this updated scope-addition is flagged for resolution at /aid-plan
> (or as a coordinated fix-pass before planning, if the user prefers). The pool
> algorithm, the two-tier review structure, and the lite-path artifact set are
> all *independent of the shape decision* — only the wording shifts.

## 6. Non-Functional Requirements

- **NFR1 — Speed (the core goal).** A small task taken through the lite path must
  be measurably faster end-to-end than the same task through the full pipeline,
  and must not feel slower than ad-hoc prompting of the AI. A precise numeric
  target is not yet fixed; with FR7 telemetry dropped in the reshape, the speed
  gain is evaluated against the documented benchmark in §2 — qualitative until a
  specific measurement need surfaces.
- **NFR2 — Backward compatibility.** Existing AID installations and in-flight
  `.aid/` workspaces must keep working across the FR3 refactor — either unchanged
  or via a defined, documented migration path. No silent breakage. (Baseline note:
  Codex installs via the bundled installer are already broken pre-refactor —
  tech-debt H6, see §8 — so backward compatibility is measured against a *working*
  install, not the broken status quo. **`work-002` owns the H6 fix and the
  cross-tree edit surface**; this NFR scopes only this work's FR3 refactor.)
- **NFR3 — Cross-tool parity (inherited from `work-002`).** `work-002`'s
  generator must produce functionally equivalent install trees; this work's
  surviving features (FR1, FR2, FR3, FR6) must respect that parity (no
  per-tool bifurcation in canonical content).
- **NFR4 — Graceful degradation.** *Moved to `work-003-traceability` (it was an
  FR4 companion).*
- **NFR5 — Minimal end-user runtime footprint.** New machinery must not impose
  heavy mandatory runtime dependencies on end users. This work's surviving
  features add only skill-body text and shell scripts (no new runtime deps); the
  generator that renders the install trees is **inherited from `work-002`** as a
  maintainer-side build tool, never reaching end-user runtime.
- **NFR6 — Deterministic grading preserved.** The FR2 two-tier review keeps the
  deterministic grade computation (`grade.sh` from a severity-tagged issue list) at
  the per-delivery gate. Speed changes must not make grading subjective.

## 7. Constraints

- **The AID methodology must be preserved.** This work — especially the FR3
  refactor — is a large structural / packaging change, but it must not alter the
  methodology itself. The pipeline intent stays intact: the 10 skills / phases, the
  artifacts, the feedback loops, the quality gates, and the three-tier agent model
  — **including the lite path (FR1)**. This is a change to *how skills are
  packaged, loaded, and chained*, not a redesign of *what the pipeline does*.

## 8. Assumptions & Dependencies

**Assumptions:**

- The AID methodology's phase model, artifacts, and feedback loops are sound and
  stay as-is; this work changes packaging, routing, and review *granularity*, not
  the methodology (see §7).
- A small work item can be reliably distinguished from a large one by 2–3 triage
  questions (FR1). If triage proves unreliable, lite-path escalation to the full
  path is the safety net.
- The per-task quick check (FR2) catching only critical/major issues is sufficient
  to stop broken tasks from cascading, with the per-delivery gate as the true
  quality bar.

**Dependencies / open unknowns:**

- **Host-tool capability research — preserved for context (most findings now
  vestigial after reshape).** Two rounds of 2026-05-22 vendor research established:
  (a) all three host tools support hooks (Claude Code / Codex stable, Cursor beta);
  (b) no host tool offers native skill chaining; (c) no host-tool hook can prompt
  for a keystroke; (d) on-demand `references/` loading works on all three tools (the
  FR3 footprint win is universal — load-bearing for this work's surviving FR3-M1);
  (e) token/cost is not exposed to hooks. With the fresh-eyes reshape dropping
  FR3-M2, FR3-M3, FR4-P3, FR4-P2, and FR7, findings (a)/(b)/(c)/(e) no longer
  affect this work's surviving features. Finding (d) — universal `references/`
  loading — remains the load-bearing fact that makes FR3-M1 worth doing on every
  tree. The full hook / capability-tracking story now lives in `work-002` (its FR5
  profile is the per-tool capability registry).
- **Knowledge Base re-synced (2026-05-22).** The KB was generated before the
  methodology-correctness cleanup and had gone stale across 12 docs (references to
  abolished artifacts — `DETAIL.md`, `GAP.md`, `REVIEW.md`, etc.). It was corrected
  in place by a targeted surgical re-sync (cross-reference IQ2; `DISCOVERY-STATE.md`
  Q181, which also tracks the follow-up `/aid-summarize` refresh of the generated
  `knowledge-summary.html`).
- **Codex installer bug (tech-debt H6) handled by work-002.** `setup.sh` and
  `setup.ps1` never copy `codex/.agents/` (skills + templates), so every Codex
  install via the bundled installer is already broken. `work-002`'s generator and
  installer rewrite touch exactly this surface — they must fix H6, not inherit or
  mask it. `work-001-aid-lite` consumes the fix transitively (any edit it makes is
  single-source once `work-002` lands).
- **Provider capability tracking + future host tools.** *Repointed to `work-002`.*
  Host-tool capabilities and onboarding new tools (Copilot CLI, Antigravity) are
  work-002's profile-registry concern; this work does not redefine that surface.

## 9. Acceptance Criteria

**FR1 — Lite path:**

- `/aid-interview` asks 2–3 triage questions and deterministically routes to the
  lite or full path.
- For a small work item, the lite path produces execution-ready `task-NNN.md` files
  for one small delivery, without creating REQUIREMENTS.md, per-feature SPEC.md, or
  feature folders.
- `/aid-execute` can run the lite path's output (the exact input contract — see
  FR1 — is finalized in `aid-specify`).
- A lite work item that proves large escalates to the full path without losing
  captured information.

**FR2 — Two-tier review:**

- During execution, each task gets exactly one quick review pass (no grade loop)
  reporting only major/critical issues.
- A critical issue triggers one immediate fix; major-and-below are logged for the
  delivery gate.
- At delivery end, the full review → fix → review loop runs to grade ≥ minimum.
- The delivery-gate reviewer's model tier varies with delivery complexity.
- The deterministic grade (`grade.sh`) is computed at the delivery gate.

**FR3 — Footprint refactor (M1 only):**

- Every skill's SKILL.md is a thin router; per-state detail lives in
  `references/state-*.md` loaded on demand.
- A completed state prints a next-step hint; the user re-invokes `/aid-{name}` to
  advance (no hook-driven auto-advance).
- The refactor is applied uniformly to all 10 skills (single-source via
  `canonical/` once `work-002` lands).
- The methodology pipeline behaves identically before and after (§7).

**FR4 — Progress traceability.** *Moved to `work-003-traceability`; see that
work's REQUIREMENTS.md §9.*

**FR5 — Profile-driven generator.** *Moved to `work-002-canonical-generator`; see
that work's REQUIREMENTS.md and feature-001 SPEC for acceptance criteria.*

**FR6 — Parallel execution (continuous pool model):**

- Given an Execution Graph with parallelizable tasks, when `aid-execute` runs the
  delivery, then ready tasks (`Depends On` all `Done`) are dispatched concurrently
  up to `MaxConcurrent` in flight at a time by default.
- Given the pool has fewer than `MaxConcurrent` tasks in flight, when any
  in-flight task completes and a previously-blocked task becomes ready, then the
  pool dispatches that newly-ready task immediately — without waiting for the
  other in-flight tasks to finish.
- Given `MaxConcurrent` is N, when more than N tasks are ready simultaneously,
  then no more than N tasks are in flight concurrently; the surplus stays in the
  ready set and is admitted in FIFO-by-task-number order as slots free.
- Given each task is run via the pool, when it completes, then it still receives
  its per-task quick check (FR2), and the per-delivery quality gate (FR2) still
  runs exactly once per delivery.
- Given a task **Fails** (Impediment), when its transitive descendants are still
  pending, then those descendants are marked **Blocked** and never dispatched;
  tasks in **unrelated** chains continue executing in the pool until they reach
  natural completion or are themselves Blocked.
- Given `aid-init` is run, when the user is asked the Max Parallel Tasks question
  (asked between Heartbeat Interval and Commit AID Workspace), then a default of
  **5** is offered, the chosen value is persisted to `.aid/knowledge/STATE.md`
  as the `**Max Parallel Tasks:**` metadata line, and `aid-execute` reads from
  that field at delivery start.

**FR7 — Self-telemetry.** *Dropped — see FR7 in §5.*

## 10. Priority

Priority below is the requirement-level scope *after* the fresh-eyes reshape
(2026-05-22).

| Bucket | Items | Rationale |
|--------|-------|-----------|
| **Must** | FR1 (`feature-005`) · FR2 (`feature-004`) · FR3 (`feature-002`) | The three speed-core changes — lite path, two-tier review, thin-router refactor — that directly address pain points 1, 2, and 3. |
| **Should** | FR6 (`feature-009`) | Parallel-by-default execution. (FR4 / pain-point #4 / `feature-007` moved to `work-003-traceability` on 2026-05-23.) |
| **(Moved)** | FR5 → `work-002-canonical-generator` | Sequenced **first** — the canonical-source consolidation it delivers makes every subsequent edit to AID's skills single-source instead of triplicated. |
| **(Dropped)** | FR3-M3 (auto-advance) · FR3-M2 (mechanical-offload hooks) · FR4-P2 (HTML viewer) · FR4-P3 (event stream) · FR7 (telemetry) | Over-engineered per the independent critique. The bracket-pair text floor (FR4) replaces the observability stack; M3 fought the platform; M2 lost its consumers; telemetry was speculative meta-work. |

**Recommended build order:**

1. **`work-002` first** (canonical generator) — unblocks single-source editing for
   everything below.
2. **`work-001-aid-lite`:** FR3 (`feature-002`) before FR1 / FR2 — it refactors
   the skills the others modify. FR6 (`feature-009`) ships anytime.

Detailed sequencing is `aid-plan`'s job; see the 4 surviving feature folders
(`feature-002`, `feature-004`, `feature-005`, `feature-009`).

### Pain-point → surviving feature coverage

| Pain point (§2) | Owning feature | Mechanism |
|---|---|---|
| **1.** Heavy pipeline for small work | `feature-005-lite-path` | Triage fork in `aid-interview`; single consolidated work-root `SPEC.md`; no per-feature folders for lite work |
| **2.** Slow per-task execution | `feature-004-two-tier-review` + `feature-009-parallel-task-execution` | Cheap per-task quick check + one full A-grade gate per delivery; concurrent dispatch of graph-independent tasks |
| **3.** Heavy skills | `feature-002-skill-footprint-refactor` | Thin-router `SKILL.md` + per-state `references/state-*.md` loaded on demand |

All three pain points have a surviving owner here; pain-point #4 was split to `work-003-traceability` on 2026-05-23. **Cross-cutting:** `work-002` lands
first so every subsequent edit is single-source rather than triplicated.
