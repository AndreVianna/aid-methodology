# Parallel Task Execution by Default

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Feature identified from REQUIREMENTS.md §5 (FR6) | /aid-interview |
| 2026-05-22 | Description corrected — aid-execute permits concurrent runs today but not automatically; FR6 makes it the automatic default (cross-reference) | /aid-interview |
| 2026-05-22 | Technical Specification written — 3 core sections (Data Model: no new artifacts, consumes the PLAN.md Execution Graph; Feature Flow: wave-based execution loop; Layers & Components: one-skill change to aid-execute) + Constraints & Boundaries note | /aid-specify |
| 2026-05-22 | Technical Specification revised for locked decisions D/A/B — aggressive graph-bounded parallelism (no concurrency cap), trusted graph-independence on the shared delivery branch (no serialized-commit step), in-flight siblings finish on failure (not cancelled); `task-NNN-STATE.md` references replaced with the merged `task-NNN.md` Execution Record zone; Execution Graph now read from `PLAN.md` (full path) or work-root `SPEC.md` (lite path) | /aid-specify |
| 2026-05-23 | **Pool-model revision.** Wave-based barrier loop replaced with a **continuous agent pool** (topological-order, work-stealing): the next ready task is dispatched the moment any in-flight task finishes, not after a wave joins. **`MaxConcurrent` parameter** introduced (default 5, project-configurable via a new `aid-init` question asked between Heartbeat Interval and Commit AID Workspace, stored in `.aid/knowledge/STATE.md` as `**Max Parallel Tasks:**`). **Failure handling narrowed** to transitive descendants only — unrelated chains continue executing until natural completion. Explicit "must complete before" barriers are now expressed by planning *as dependencies* in the Execution Graph (no first-class wave concept in execution). | /aid-specify |
| 2026-05-23 | **Fix-pass after re-review.** Citations re-anchored from absolute SKILL.md line numbers to section names (patch-resilient; cycle-14 KB pattern); "ready queue" → "ready set" everywhere except where FIFO admission ordering is being asserted; AC6 rephrased to test the persistence property, not the absolute Q-number; pull-quote schema-change claim reconciled with §Data Model; NFR4 user-set-value handling on degraded hosts made explicit (informational log); pool observability cross-references FR1's EXECUTE-WAVE drill-down; trust-boundary widening under pool admission made explicit; "CW8" tag dropped; §Constraints adds a "per-task state contract — deferred to /aid-plan" note (cross-feature concern with features 002/004/005); IQ raised in work STATE.md asking whether host Task-tool surface supports wait-for-any-completion semantic the pool needs. | /aid-specify |
| 2026-05-23 | **Fix-pass-2 after second re-review** (graded D+, 1 HIGH + 1 MED + 2 LOW + 1 MIN). Per-task state contract deferment swept through the 4 in-line locations missed in fix-pass-1 (Data Model Depends-On bullet, Feature Flow step 3, both Failure-semantics bullets) — body now uses "canonical per-task state contract" phrasing consistently with §Data Model "Per-task state" paragraph and §Constraints deferred-contract bullet. Broken NFR4 cite (REQUIREMENTS.md §6 — NFR4 was relocated to work-003) fixed by inlining the graceful-degradation principle and noting the relocation. EXECUTE-WAVE drill-down icon vocabulary now reuses the existing `(queued)` token verbatim and is explicit that FR6 *supplements* the set with `⊘ blocked` rather than replacing existing glyphs. Three descriptive "Q7" body references (L93, L209, L433) replaced with position-based phrasing ("the new aid-init Max Parallel Tasks question, asked between Heartbeat Interval and Commit AID Workspace"); the prescriptive Layers row at L352 retains "Q7" since it defines the renumber. Minor cosmetic at the Layers Data row (L356) acknowledges the FR2-shipped shape exists today. | /aid-specify |
| 2026-05-24 | **Alignment Update** added (between Acceptance Criteria and Technical Specification). The per-task state contract previously "deferred to /aid-plan" is **now resolved** by the 2026-05-24 REQUIREMENTS refresh: the canonical contract is work-003's FR2 per-area STATE rule — task-NNN.md stays 6-section flat; per-task Status / dispatch history / Blocked state live in the per-work `STATE.md ## Tasks Status` row. The pool algorithm, all 6 ACs, the `MaxConcurrent` parameter, and the IQ6 deferment are unchanged; only the per-task state target is now pinned. Body sections that say "the canonical per-task state contract — see §Constraints" still parse correctly under the resolution — they now point at the work `STATE.md ## Tasks Status` row. | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR6, §9, §10

## Description

Today `aid-execute` *permits* running independent tasks concurrently — separate
invocations can run in parallel — but it does not do so automatically: the user must
manually launch the parallel invocations. This feature makes parallel execution the
**automatic default** via a **continuous agent pool**: `aid-execute` maintains up to
`MaxConcurrent` tasks in flight, and the *moment* any in-flight task finishes (and
its completion newly satisfies a downstream task's dependencies), the pool admits
the next ready task — without waiting for a synchronized "wave" to join. The pool
size defaults to **5** and is configurable per project via `aid-init`. Each task
still gets its per-task quick check, and the single per-delivery quality gate still
runs once at the end. While the wall-time gain from parallelism alone is modest
compared to the review and footprint changes, continuous pool execution is the
correct execution behavior and complements the other speed improvements.

## User Stories

- As an AID end user, I want `aid-execute` to run independent tasks concurrently by
  default so that a delivery with parallelizable work completes faster without me
  having to invoke each task separately.

## Priority

Should

## Acceptance Criteria

- [ ] Given an Execution Graph with parallelizable tasks, when `aid-execute` runs
  the delivery, then ready tasks (`Depends On` all `Done`) are dispatched
  concurrently up to `MaxConcurrent` in flight at a time by default.
- [ ] Given the pool has fewer than `MaxConcurrent` tasks in flight, when any
  in-flight task completes and a previously-blocked task becomes ready, then the
  pool dispatches that newly-ready task immediately — without waiting for the
  other in-flight tasks to finish.
- [ ] Given `MaxConcurrent` is N, when more than N tasks are ready simultaneously,
  then no more than N tasks are in flight concurrently; the surplus stays in the
  **ready set** and is admitted in FIFO-by-task-number order as slots free.
- [ ] Given each task is run via the pool, when it completes, then it still
  receives its per-task quick check, and the per-delivery quality gate still runs
  exactly once per delivery.
- [ ] Given a task **Fails** (Impediment), when its transitive descendants are
  still pending, then those descendants are marked **Blocked** and never
  dispatched; tasks in **unrelated** chains continue executing in the pool until
  they reach natural completion or are themselves Blocked.
- [ ] Given `aid-init` is run, when the user is asked the Max Parallel Tasks
  question (the question asked between Heartbeat Interval and Commit AID
  Workspace), then a default of **5** is offered, the chosen value is persisted
  to `.aid/knowledge/STATE.md` as the `**Max Parallel Tasks:**` metadata line,
  and `aid-execute` reads from that field at delivery start.

---

## Alignment Update — 2026-05-24

> **REQUIREMENTS.md was refreshed on 2026-05-24** to align with work-003's
> deployed FR2 per-area STATE rule. This SPEC's body (post-pool-revision +
> two fix-passes) describes the per-task state contract as
> **"deferred to /aid-plan"**. That deferment is now **resolved**: the
> canonical contract is work-003's FR2 per-area STATE rule:
>
> - **`task-NNN.md` stays 6-section flat** (Definition only).
> - **Per-task Status / dispatch history / Blocked state live in the per-work
>   `.aid/work-NNN/STATE.md ## Tasks Status` row.**
>
> **What changes for this feature's body:**
>
> - The §Data Model "Per-task state" paragraph and the §Constraints "Per-task
>   state contract — deferred to /aid-plan" bullet are superseded — the
>   contract is no longer deferred; it points at the work `STATE.md ## Tasks
>   Status` row.
> - The §Layers Data row's "Whether `Blocked` is written to the canonical
>   `task-NNN.md` shape (post-/aid-plan reconciliation) or to the work
>   `STATE.md ## Tasks Status` row" hedge is superseded — the answer is the
>   work `STATE.md ## Tasks Status` row.
> - Feature Flow step 3, the failure-semantics bullets ("The failing task is
>   removed from in-flight" / "Its transitive descendants are marked Blocked")
>   read against the work `STATE.md ## Tasks Status` row as the per-task state
>   target.
>
> **What stays the same:**
>
> - The pool algorithm (continuous admission, `MaxConcurrent` ceiling,
>   transitive-descendant failure block, wave barriers as graph dependencies,
>   graceful degradation).
> - All 6 ACs — the algorithm + the configuration contract are independent of
>   where per-task state lives.
> - The `MaxConcurrent` parameter (default 5, configured via new aid-init
>   question between Heartbeat Interval and Commit AID Workspace, stored in
>   `.aid/knowledge/STATE.md` as `**Max Parallel Tasks:**`).
> - IQ6 (Task-tool wait-for-any semantic) remains open in work `STATE.md
>   ## Cross-phase Q&A` for /aid-plan to resolve.
>
> Body sections below treat the per-task state contract as deferred; the
> alignment update above is the operative contract for /aid-plan and
> implementation. A focused body-text rewrite is a candidate /aid-detail task
> and is not scoped into this feature.

---

## Technical Specification

> This is a small, behavior-level change centered on **one skill — `aid-execute`** —
> with a single supporting touch in `aid-init` (one new configuration question) and
> **one additive metadata line** in `.aid/knowledge/STATE.md` for the resulting
> setting. No new artifacts, no new agents, no new templates, and no other schema
> changes. The spec is therefore proportionately small: it activates only the
> three core sections plus a short Constraints & Boundaries note. The change is
> *which path through `aid-execute`'s existing Delivery Lifecycle is the default*
> — pool-driven dispatch up to `MaxConcurrent` of any ready, graph-independent
> tasks, advancing on every completion event — not a new capability bolted on.

### Data Model

**One new STATE.md field; no new artifacts and no schema changes elsewhere.** FR6
consumes data structures that already exist; the only addition is one metadata
line in `.aid/knowledge/STATE.md`.

**Two inputs FR6 relies on:**

1. The **Execution Graph** (existing — see below).
2. **`MaxConcurrent`** — read from `.aid/knowledge/STATE.md` top-of-file metadata
   as `**Max Parallel Tasks:** N` (default `5` if the field is absent). Set
   interactively during `aid-init` by the new Max Parallel Tasks question
   (asked between Heartbeat Interval and Commit AID Workspace). The value
   applies to every delivery in the project unless overridden at the command
   line (out of scope for this feature). Same metadata pattern as
   `**Heartbeat Interval:**` introduced by the subagent-visibility-patch.

The Execution Graph is the
*verified* dependency structure of a delivery: it is defined during `aid-plan`
(full path) or `aid-interview`'s lite path, and confirmed during `aid-detail`. By
the time `aid-execute` runs, the graph has been reviewed twice — FR6 therefore
**trusts it as authoritative** and parallelizes strictly along it.

**The graph lives in different files on the two paths, but its content is
identical:**

| Path | File holding the Execution Graph |
|------|----------------------------------|
| Full | `PLAN.md` (per delivery) |
| Lite | the consolidated work-root `SPEC.md` (the lite path's single delivery descriptor — there is no `PLAN.md` or `DELIVERY.md` on the lite path) |

`aid-execute` resolves which file to read from the work's shape (a `PLAN.md`
present ⇒ full path; otherwise the work-root `SPEC.md`). The graph format is the
same two markdown tables under the delivery in either file (per the **Execution
Graph block** of `aid-detail/SKILL.md`):

```markdown
#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-002 |
| task-005 | task-003, task-004 |

| Can Be Done In Parallel |
|------------------------|
| task-003, task-004 |
```

> **Coordination note.** The cited example (the **Execution Graph block** of
> `aid-detail/SKILL.md`) is the *full-path* producer of this two-table format. On the lite path, producing that
> identical two-table Execution Graph in the work-root `SPEC.md` is **feature-005's
> responsibility** — FR6 only consumes it. This is a coordination dependency:
> feature-005 must emit the same format `aid-detail` produces for FR6's reader to
> work unchanged across both paths.

- The **`Depends On`** table is the precedence relation **and the sole driver of
  pool dispatch**: a task is *ready* the moment every task in its `Depends On`
  list has Status `Done` (read through the canonical per-task state contract —
  see the "Per-task state" paragraph below and §Constraints; the readiness rule
  `aid-execute` Pre-flight Check 2b already enforces this, generalized from
  per-task to per-delivery). The pool admits any ready task whenever a slot is
  free. Independence between tasks is therefore a *derived* property of the
  Depends-On graph (two tasks are independent iff neither transitively depends on
  the other), not a separately-tracked enumeration.
- The **`Can Be Done In Parallel`** table is **retained as a planning artifact and
  reviewer aid** — it records the parallelization opportunities `aid-plan` and
  `aid-detail` explicitly identified, which makes the graph easier to read and
  review. It is **not consulted by the pool executor**: any two tasks that the
  Depends-On relation leaves mutually independent are eligible to run together up
  to `MaxConcurrent`. **The trust boundary (decision D) still stands:**
  graph-certified independence is trusted to mean file-disjointness on the shared
  delivery branch, so concurrently-running siblings do not contend on content.
  The disjoint-files property remains an assumption FR6 leans on, not a structural
  guarantee the graph format mechanically provides.
  - **Trust-boundary widening under pool admission (note for planners and
    reviewers).** Under the prior wave model, the in-flight set was restricted to
    a single graph-certified parallel group that `aid-plan` had explicitly
    enumerated. Under the pool model, the in-flight set can mix tasks that the
    planner did *not* explicitly group together — any pair of graph-independent
    tasks may be co-resident if their dependencies happen to clear at the same
    moment. The trust boundary therefore relies on file-disjointness being a
    property of *graph independence in general* (which `aid-plan` and `aid-detail`
    are expected to enforce when laying down dependencies), not of explicit
    parallel-group enumeration. Planners should not encode file-disjointness
    only for the pairs they happen to list in `Can Be Done In Parallel`.
- **Wave barriers, when planning needs them, are expressed as dependencies — not
  as a separate execution concept.** If `aid-plan` or `aid-detail` decides that
  a set of tasks `{D, E, F}` *must* wait until `{A, B, C}` are all complete (e.g.,
  to checkpoint a schema migration before downstream work), this is encoded by
  making `D`, `E`, and `F` each depend on `A`, `B`, and `C` (or via a synthetic
  checkpoint task that depends on `A`/`B`/`C` and is depended on by `D`/`E`/`F`).
  The pool then *automatically* honors the barrier through its normal readiness
  rule — no special "wave-aware" logic in the executor.

FR6 changes **no part of this data**. It changes how `aid-execute` *acts on* it:
the pool issues a new dispatch on every completion event, instead of waiting for a
synchronized wave to join.

**Per-task state — read/written through the canonical per-task state contract.**
There is no separate `task-NNN-STATE.md` (retired). The canonical contract for
per-task state — whether it's a two-zone `task-NNN.md` (Definition +
Execution Record) co-resident with this SPEC, or the work `STATE.md ## Tasks
Status` row already shipped by FR2 (work-003) — is a cross-feature concern
across work-001 (features 002, 004, 005, 009) and is **deferred to `/aid-plan`**
(see §Constraints & Boundaries). FR6's pool reads task Status from, and writes
status transitions (Done / Failed / Blocked) to, whichever contract is canonical
at implementation time. Each pool-dispatched task writes its own status and
`## Dispatches`-equivalent record exactly as a sequential task does. The pool
algorithm itself is independent of the shape decision.

### Feature Flow

Today's `aid-execute` runs **one task per invocation** (`task-NNN` is a required
argument; the skill's **Delivery Lifecycle** section documents the user manually
issuing `/aid-execute task-003`, `/aid-execute task-004`, … in sequence). FR6 makes the skill able to **advance a delivery as a
continuous pool**: at most `MaxConcurrent` tasks are in flight at any moment, and
the pool admits the next ready task the instant any in-flight task completes —
without waiting for a synchronized wave to finish.

**Parallelism is bounded by two things and only two things:**

1. **The Execution Graph (correctness bound)** — a task may run only when all its
   `Depends On` tasks have Status `Done`. This bound is non-negotiable.
2. **`MaxConcurrent` (resource bound)** — a project-configured ceiling on the
   number of *simultaneously in-flight* tasks. Default `5`, set per project via
   the new `aid-init` Max Parallel Tasks question (asked between Heartbeat
   Interval and Commit AID Workspace), stored in `.aid/knowledge/STATE.md`.
   This bound is tunable: it exists so the user can cap host-resource usage,
   debugging blast-radius, and review-load surges, **not** to second-guess the
   graph.

The graph is trustworthy by virtue of upstream review (defined in `aid-plan` /
lite-path planning, re-confirmed in `aid-detail`), so FR6 leans on it fully for
correctness. `MaxConcurrent` exists separately, as a *throttle*, not as a
correctness mechanism.

**Pool-based execution loop** (the FR6 default for a delivery):

1. **Resolve the delivery.** From the task/delivery argument, locate the delivery
   and read its Execution Graph — from `PLAN.md` on the full path, or from the
   consolidated work-root `SPEC.md` on the lite path (same graph content, see Data
   Model). Read `MaxConcurrent` from `.aid/knowledge/STATE.md`
   (`**Max Parallel Tasks:** N`, default `5`).
2. **Initialize state.** Compute the initial **ready set** — every task whose
   `Depends On` list is empty (or whose dependencies were already `Done` from a
   previous run). Mark every other task **Pending**. The **in-flight set** starts
   empty.
3. **Fill the pool.** While `|in-flight| < MaxConcurrent` and the ready set is
   non-empty: pick one task from the ready set (FIFO by task number is sufficient
   — the graph already guarantees correctness regardless of within-ready ordering),
   move it to the in-flight set, and dispatch it. Each dispatch runs the
   **existing per-task pipeline unchanged**: EXECUTE (type-specific executor) →
   per-task quick check (the FR2 two-tier model's first tier — coordinated with
   feature-004, not redefined here). Each task writes its own status and
   dispatch history through the canonical per-task state contract (see §Data
   Model "Per-task state" paragraph and §Constraints), exactly as a sequential
   run does.
4. **Wait for one completion.** Block until *any* in-flight task reaches a
   terminal state (`TASK-DONE`, or **Failed** via an IMPEDIMENT that survives its
   one fix-on-spot — feature-004 Flow A). Crucially, this is a **one-event wait**,
   not a join across all in-flight tasks — the pool reacts to each completion
   independently.
5. **On completion, update the ready set.**
   - If the task **completed successfully**: remove it from in-flight; for every
     Pending task whose `Depends On` set is now entirely `Done`, add that task to
     the ready set. Go to step 3.
   - If the task **Failed**: remove it from in-flight; compute its **transitive
     descendant set** in the Depends-On graph and mark every descendant
     **Blocked**. Blocked tasks are never moved to ready, never dispatched. The
     pool continues to operate on remaining ready / in-flight tasks from
     **unrelated chains** — those are unaffected by the failure (per decision D's
     trust boundary, an unrelated chain shares no graph dependency on the failed
     work). Surface the failure via the existing Impediment mechanism. Go to
     step 3.
6. **Terminate.** When the in-flight set is empty and the ready set is empty,
   the pool has reached fixed point. The delivery's task phase is complete if no
   tasks are Blocked or Failed; if any are, the delivery is **partially
   complete** — the user resolves the failure(s) and re-invokes `aid-execute` to
   resume from the unfinished tail.

   **Observability.** Pool admission and per-completion updates render through
   the **existing EXECUTE-WAVE sub-unit drill-down** in `aid-execute`'s state
   map (introduced by FR1 / work-003-traceability `feature-001-you-are-here-heartbeat`
   AC4) — FR6 does not add a new visibility surface. The drill-down's existing
   icon vocabulary (`✓ done`, `● running`, `✗ failed`, `(queued)`) is **reused
   verbatim**: under the pool model, `(queued)` is rendered for every task in
   the ready set that is waiting for a `MaxConcurrent` slot to free, and FR6
   **supplements** the existing set with one additional glyph — `⊘ blocked`
   for tasks downstream of a Failed ancestor — to distinguish the
   failure-radius from the merely-not-yet-ready. The drill-down also gains a
   single counts summary line (`done / in-flight / queued / blocked / failed`).
   FR1's `▶/✓` bracket pairs continue to mark each per-task dispatch and
   completion as today.
7. **Per-delivery quality gate — once.** After the pool reaches a fully successful
   fixed point, the FR2 per-delivery quality gate (the rigorous review → fix →
   review loop to grade ≥ minimum) runs **exactly once for the delivery**,
   unchanged by FR6. The pool model multiplies task dispatch; it does not
   multiply the gate. The gate does **not** run if any task is Failed/Blocked.

**Pool model vs. wave model — why it matters.** Consider a delivery with two
independent chains: `A → B → C` and `D → E → F`. Suppose `D`, `E`, `F` each take
30 s and `A` takes 5 min.

| Time | Wave model (prior spec) | Pool model (this spec), MaxConcurrent=2 |
|---|---|---|
| t=0 | Wave 1 dispatches {A, D} | Pool starts A, D |
| t=30 s | D done; B not ready (A still running). **Pool idle, waiting for A.** | D done → E starts immediately (slot freed) |
| t=60 s | (still waiting) | E done → F starts |
| t=90 s | (still waiting) | F done; A still in flight |
| t=5 min | A done; wave 1 joins; **wave 2 = {B, E} dispatches** | A done → B starts; D-chain already finished |
| t=10 min | B, E join; wave 3 = {C, F} | B done → C starts |
| t=15 min | C, F join; delivery done | C done; delivery done |

Same dispatch count, same correctness — but the pool finishes ~10 minutes earlier
because it never sits idle while ready work exists.

**Pre-FR6 vs. post-FR6** for the sample delivery in `aid-execute/SKILL.md`'s
**Delivery Lifecycle** section (task-003 and task-004 both depend on task-002 —
two siblings; a wider graph fans out further, capped at `MaxConcurrent`):

| | Today | With FR6 |
|--|-------|----------|
| task-003 / task-004 (siblings under task-002) | User runs `/aid-execute task-003`, then `/aid-execute task-004` (or two terminals, by hand) | Both ready at the same instant when task-002 finishes; pool dispatches both immediately (capacity permitting) |
| New task ready while siblings still running | User has to notice and launch manually | Pool dispatches it the moment a slot frees, without waiting for siblings |
| Per-task quick check | Once per task | Once per task — unchanged |
| Per-delivery gate | Once | Once — unchanged |

**Single-task invocation still works.** `/aid-execute task-NNN` for one specific
task is preserved (resume, re-run, targeted fix — see `aid-execute/SKILL.md`'s
**Re-run** path; with state read through the canonical per-task state contract,
see §Data Model). FR6 adds the pool-driven default for advancing a delivery; it
does not remove the ability to run a single task.

**Failure semantics (transitive-descendant block).** When an in-flight task
**Fails** (raises an Impediment that survives its one fix-on-spot):

- **The failing task is removed from in-flight.** Its failure is recorded
  through the canonical per-task state contract (see §Data Model "Per-task
  state" and §Constraints); the Impediment file and circuit breaker
  (`aid-execute/SKILL.md`'s **Impediments** section) surface it to the user
  exactly as for a sequential run. FR6 adds no new failure-handling machinery.
- **Its transitive descendants are marked Blocked.** Every task that depends on
  the failed task — directly or transitively — is taken out of consideration. They
  are never dispatched, never enter the ready set. Their status changes from
  Pending to Blocked (recorded through the canonical per-task state contract)
  so the user can see the damage radius at a glance.
- **All `Depends On` edges are AND.** There is no "alternative path" through the
  graph — every dependency must be `Done` for a task to be ready. So a single
  failure deterministically blocks its entire downstream subtree, no partial
  recovery paths to evaluate. This is a deliberate simplification: planning is
  responsible for any redundancy/retry strategy *upstream* in the graph, not
  *during* execution.
- **In-flight siblings and unrelated chains continue.** Tasks already in flight at
  the moment of failure are **not cancelled** — they are independent of the failed
  task per the verified Execution Graph (decision D's trust boundary), so their
  work is valid and cancelling would only waste completed effort. Pending tasks in
  unrelated chains (no transitive dependency on the failed task) **continue to
  enter the pool normally** as their own dependencies clear. The pool reaches a
  fixed point when no further progress is possible.
- **The delivery does not silently end.** After the pool reaches its
  failure-affected fixed point, `aid-execute` reports: tasks Done, tasks Failed
  (with Impediment refs), tasks Blocked (with their failed ancestor named). The
  per-delivery quality gate does **not** run while any task is Failed/Blocked.
  The user resolves the failure(s) — typically by fixing the failed task and
  re-running it — and re-invokes `aid-execute` to resume; the pool then admits
  newly-unblocked downstream tasks.

### Layers & Components

FR6 touches **two skills — `aid-execute` (substantive) and `aid-init` (one new
question)** — plus one new metadata line in `.aid/knowledge/STATE.md`. No new
agent, no new template, no new script.

| Layer | Component | Change |
|-------|-----------|--------|
| Orchestration | `aid-execute` SKILL.md — its Delivery Lifecycle / execution-graph handling | **Substantive.** A continuous-pool loop (compute initial ready set → fill pool up to `MaxConcurrent` → wait for any one completion → update ready set / mark Blocked descendants on failure → loop until fixed point) becomes the default for advancing a delivery. The graph is read from `PLAN.md` (full path) or the work-root `SPEC.md` (lite path). `MaxConcurrent` is read from `.aid/knowledge/STATE.md` (`**Max Parallel Tasks:**`, default 5). The existing single-task path is retained. |
| Configuration | `aid-init` SKILL.md | **New Q7 (Max Parallel Tasks).** Inserted after Q6 (Heartbeat Interval); the existing Q7 (Commit AID Workspace) renumbers to Q8. The question offers a default of `5` and accepts any positive integer. The chosen value is written to `.aid/knowledge/STATE.md` top-of-file as `**Max Parallel Tasks:** N`. |
| State | `.aid/knowledge/STATE.md` top-of-file metadata block | **One new field.** `**Max Parallel Tasks:** N`, placed next to `**Heartbeat Interval:**`. Same convention as the existing metadata lines (one `**Key:**` line per file-level setting). The Discovery `state-template.md` gains a corresponding placeholder so newly-initialized projects ship with the line populated. |
| Execution | type-specific executor agents (`developer`, `researcher`, …) + the per-task quick-check reviewer | **Unchanged.** Each pool-dispatched task runs the same agents through the same per-task pipeline. FR6 changes only *when* a dispatch is issued (pool admission), not what a dispatch does. |
| Quality gate | the FR2 per-delivery reviewer | **Unchanged.** Runs once per delivery, after the pool reaches a fully successful fixed point. Defined by feature-004 (FR2); FR6 only guarantees it still fires exactly once and does not fire while tasks are Failed/Blocked. |
| Data | Execution Graph (`PLAN.md` / work-root `SPEC.md`); per-task state contract (deferred to `/aid-plan` — see §Data Model and §Constraints) | **Unchanged structurally** — but per-task state now also records the `Blocked` status when a transitive ancestor has Failed, so the user can see the damage radius at a glance without recomputing it. Whether `Blocked` is written to the canonical `task-NNN.md` shape (post-`/aid-plan` reconciliation) or to the work `STATE.md ## Tasks Status` row (the shape FR2 already ships) is the contract decision deferred to planning. |

**Concurrency mechanism.** Concurrent dispatch is realized through the host
agentic platform's existing sub-agent dispatch facility — the same mechanism
`aid-execute` already uses to dispatch one executor per task, and the same one
`aid-discover` uses to run its discovery sub-agents in parallel (see
`architecture.md` pattern 2, "sub-agent dispatch (orchestrator-worker)", and
`aid-discover/SKILL.md`'s GENERATE-mode "Steps 2-5: Dispatch 4 Subagents in
Parallel"). Note
that the two are distinct dispatch surfaces: the directly relevant precedent is
`aid-execute`'s per-task **Task-tool** dispatch of one executor per task, whereas
`aid-discover` uses the **Agent** tool for its discovery sub-agents — so when
`INDEX.md`'s integration-map summary states `aid-discover` is the only skill
using the **Agent** tool for sub-agent dispatch, that is consistent with this
spec, which leans on the Task-tool path FR6 already exercises. FR6
issues up to `MaxConcurrent` such sub-agent dispatches simultaneously, admitting a
new one on every completion event rather than after a wave joins. **Precedent
exists in this codebase** — `aid-execute` already dispatches per-task executors
via the Task tool, and `aid-discover` already runs sub-agents in parallel; FR6
combines the two with a bounded pool driven by completion events.
The exact platform call shape is an implementation detail and is **profile-aware**:
hosts that expose `background_execution` (an FR5 capability flag — owned by
`work-002`'s `feature-001-profile-driven-generator`) can run the pool truly
concurrently; where that capability is weaker, FR6 applies the same
graceful-degradation principle work-003 introduced — `aid-execute` falls back to
sequential dispatch (effective `MaxConcurrent` = 1), preserving correctness and
the methodology, losing only the wall-time overlap. (The "NFR4 graceful
degradation" requirement that originally lived in this work's REQUIREMENTS.md §6
was relocated to `work-003-traceability` when the traceability concerns were
split off; the principle applies here verbatim, sourced locally rather than
cross-cited to avoid drift.)

**Degraded-host visibility for `MaxConcurrent`.** On hosts without
`background_execution`, the user's configured `MaxConcurrent` from
`.aid/knowledge/STATE.md` becomes informational only — `aid-execute` runs the
pool sequentially (effective `MaxConcurrent` = 1) regardless of the configured
value. To prevent the user being surprised by their `5` (or whatever they set)
silently becoming `1`, `aid-execute` logs a single line at delivery start:
`[degradation] MaxConcurrent={N} requested, host capability=sequential — running
effective=1`. No Impediment is raised — degradation is not an error.

**State-machine integrity.** Each task's `EXECUTE → REVIEW(quick) → … → DONE`
sub-machine is per-task and self-contained; running several of them at once does
not couple them because the graph guarantees pool-coresident tasks are mutually
independent (neither transitively depends on the other, so no shared output and —
per decision D's trust boundary — no shared files on the delivery branch).

**Shared delivery branch — no serialized-commit step.** The delivery branch
(`aid/delivery-NNN`, one branch per delivery — see `aid-execute/SKILL.md`'s
**Branch Isolation** check) is shared by all tasks in the delivery today and
remains shared. **Graph-independence
is *trusted* here to mean disjoint files (decision D's trust boundary):** any two
tasks that the Depends-On graph leaves mutually independent (neither transitively
depends on the other) were vetted as such by `aid-plan` and re-confirmed by
`aid-detail`; FR6 then *assumes* that dependency-independence implies those tasks
operate on disjoint files — and on that assumption, there is no file contention
between concurrently in-flight pool members, so concurrent commits to the shared
branch do not collide on content. FR6 therefore introduces **no serialized-commit
step, no per-task sub-branch, and no merge/rebase choreography** — each task
commits to the delivery branch as it does today. The trust boundary is explicit:
the graph format does not mechanically guarantee file-disjointness; FR6 trusts the
upstream review process (twice-verified graph) to make that assumption hold.

### Constraints & Boundaries

- **Methodology preserved (§7).** FR6 changes *how* `aid-execute` advances a
  delivery, not *what* the pipeline does. Phases, artifacts, the per-task quick
  check, the per-delivery gate, deterministic grading, and the branch-per-delivery
  rule are all intact.
- **Coordinates with feature-004 (FR2), does not redefine it.** Every pool-
  dispatched task receives its FR2 per-task quick check; the FR2 per-delivery
  quality gate runs once after a fully successful pool fixed point. The definition
  of those two tiers belongs to feature-004; FR6 only asserts they remain wired in.
- **Modest standalone gain — by design.** Per REQUIREMENTS.md FR6, the wall-time
  win from parallelism alone was modest in benchmarking; the headline speed gains
  are FR2 and FR3. FR6 is included because pool-driven parallel-by-default is the
  *correct* execution behavior and complements them — not for its own speed number.
  The pool model does, however, reclaim the wall-time that the prior wave model
  would have left on the table when chains finish at different speeds.
- **Two bounds, both real.** The Execution Graph (correctness) and `MaxConcurrent`
  (resource cap) are the *only* two bounds on the pool. The graph is non-
  negotiable; `MaxConcurrent` is tunable per project (via the new `aid-init`
  Max Parallel Tasks question, asked between Heartbeat Interval and Commit AID
  Workspace) with a default of `5`. Graph-certified independence is trusted to
  mean disjoint files on the shared delivery branch (see Layers & Components) —
  no serialized-commit step is added.
- **Wave barriers, when wanted, are dependencies.** If planning needs `{D, E, F}`
  to wait until `{A, B, C}` are all done (a "checkpoint" intent), the planner
  encodes that as graph dependencies in `aid-plan` / `aid-detail`. The pool then
  honors the barrier automatically through its normal readiness rule. There is
  **no first-class "wave" concept in the executor**; this avoids a second
  scheduling layer with its own edge cases.
- **Failure stops only the descendant subtree.** A failed task blocks only its
  transitive descendants in the Depends-On graph (all `Depends On` edges are AND;
  no alternative paths). Unrelated chains continue to completion. This is a
  deliberate scope choice — recovery (retry, alternative implementations, etc.)
  is a *planning* concern handled upstream in the graph, not an *execution-time*
  concern.
- **Per-task state contract — deferred to `/aid-plan` (cross-feature concern).**
  This SPEC reads and writes per-task state (Status, the failure → Blocked
  transition, `## Dispatches` records, etc.) under the assumption of a
  **two-zone `task-NNN.md` shape** (Definition + Execution Record). Features
  002, 004, 005, and 009 all carry the same assumption today, but disk truth
  right now is the **6-section flat `task-NNN.md` template** + per-task status
  rows in the work `STATE.md ## Tasks Status` table (the shipped FR2 contract
  from work-003). Reconciling the two shapes is **not** in FR6's scope — it is
  a planning concern across the work-001 feature family. `/aid-plan` is
  expected to sequence the four features and resolve which shape becomes
  canonical; FR6's executor reads and writes per-task state in whatever shape
  is canonical at implementation time. The pool algorithm itself is independent
  of the shape decision.
- **Temporary per-run `MaxConcurrent` overrides — deferred.** The STATE.md
  value is the only knob FR6 ships. A future enhancement may add a
  `--max-concurrent=N` CLI override (e.g., to set `=1` for debugging a single
  task in isolation) but that is out of scope here and would belong to a
  follow-up feature.
- **Scope boundary.** FR6 does **not** change how the Execution Graph is produced
  (that is `aid-plan` / `aid-detail`'s job), does not add new parallelism beyond
  what the graph certifies, does not introduce task-priority or fair-share
  scheduling beyond simple FIFO admission from the ready set, and does not touch
  deploy/monitor. It is a behavior change in `aid-execute` plus a single
  configuration question in `aid-init`.
