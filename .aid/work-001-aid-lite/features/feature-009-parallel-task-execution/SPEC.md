# Parallel Task Execution by Default

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Feature identified from REQUIREMENTS.md §5 (FR6) | /aid-interview |
| 2026-05-22 | Description corrected — aid-execute permits concurrent runs today but not automatically; FR6 makes it the automatic default (cross-reference) | /aid-interview |
| 2026-05-22 | Technical Specification written — 3 core sections (Data Model: no new artifacts, consumes the PLAN.md Execution Graph; Feature Flow: wave-based execution loop; Layers & Components: one-skill change to aid-execute) + Constraints & Boundaries note | /aid-specify |
| 2026-05-22 | Technical Specification revised for locked decisions D/A/B — aggressive graph-bounded parallelism (no concurrency cap), trusted graph-independence on the shared delivery branch (no serialized-commit step), in-flight siblings finish on failure (not cancelled); `task-NNN-STATE.md` references replaced with the merged `task-NNN.md` Execution Record zone; Execution Graph now read from `PLAN.md` (full path) or work-root `SPEC.md` (lite path) | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR6, §9, §10

## Description

Today `aid-execute` *permits* running independent tasks concurrently — separate
invocations can run in parallel — but it does not do so automatically: the user must
manually launch the parallel invocations. This feature makes parallel execution the
**automatic default**: tasks that the PLAN.md execution graph already marks as
parallelizable are dispatched concurrently rather than left for the user to launch
one at a time. Each task run in parallel still gets its two-tier quick check, and the
single per-delivery quality gate still runs once at the end. While the wall-time gain
from parallelism alone is modest compared to the review and footprint changes,
parallel-by-default is the correct execution behavior and complements the other
speed improvements.

## User Stories

- As an AID end user, I want `aid-execute` to run independent tasks concurrently by
  default so that a delivery with parallelizable work completes faster without me
  having to invoke each task separately.

## Priority

Should

## Acceptance Criteria

- [ ] Given a PLAN.md execution graph that marks certain tasks as parallelizable,
  when `aid-execute` runs the delivery, then it runs those tasks concurrently by
  default.
- [ ] Given tasks are run concurrently, when each task completes, then it still
  receives its per-task quick check, and the per-delivery quality gate still runs
  once.

---

## Technical Specification

> This is a small, behavior-level change to one skill — `aid-execute`. It introduces
> no new artifacts, no schema changes, and no new components. The spec is therefore
> proportionately small: it activates only the three core sections plus a short
> Constraints & Boundaries note. The change is *which path through `aid-execute`'s
> existing Delivery Lifecycle is the default* — concurrent dispatch of
> already-marked-parallelizable tasks — not a new capability bolted on.

### Data Model

**No new artifacts and no schema changes.** FR6 consumes data structures that
already exist; it produces nothing new.

The single input it relies on is the **Execution Graph**. The graph is the
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
same two markdown tables under the delivery in either file (per
`aid-detail/SKILL.md:278-291`):

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

> **Coordination note.** The cited example (`aid-detail/SKILL.md:278-291`) is the
> *full-path* producer of this two-table format. On the lite path, producing that
> identical two-table Execution Graph in the work-root `SPEC.md` is **feature-005's
> responsibility** — FR6 only consumes it. This is a coordination dependency:
> feature-005 must emit the same format `aid-detail` produces for FR6's reader to
> work unchanged across both paths.

- The **`Depends On`** table is the precedence relation: a task is *ready* only when
  every task in its `Depends On` list has Status `Done` in its **Execution Record**
  zone of `task-NNN.md` (the readiness rule `aid-execute` Pre-flight Check 2b
  already enforces).
- The **`Can Be Done In Parallel`** table enumerates the groups certified — by
  `aid-plan` and re-confirmed by `aid-detail` — as safe to run concurrently
  (`aid-detail/SKILL.md:297`, in the Dependency-rules block at lines 293-298 —
  "if two tasks share the same dependencies but don't depend on each other →
  parallel"). **Independence in this table is the trust boundary decision D
  establishes:** independent-by-graph tasks are *trusted* to touch disjoint files
  (decision D — graph-certified independence is taken to mean file-disjointness on
  the shared delivery branch), so they cannot contend with one another. The
  parallel-eligibility rule itself is dependency-based, not file-overlap-based;
  the disjoint-files property is the assumption FR6 leans on, not a structural
  guarantee the graph format mechanically provides.

FR6 changes **no part of this data**. It changes only how `aid-execute` *acts on*
the second table: today it is read as permission ("these tasks *may* run in
parallel — you, the user, launch them"); after FR6 it is read as an instruction
("these tasks are dispatched together automatically").

**Per-task state lives in `task-NNN.md`.** There is no separate `task-NNN-STATE.md`
— each task file has two zones: a **Definition** zone (Title, Type, Source, Depends
on, Scope, Acceptance Criteria) and an **Execution Record** zone (status, review
history, grade, `## Dispatches`). Each parallel task writes its own Execution
Record exactly as a sequential task does; the `## Dispatches` rows remain the
record of what was dispatched for that task.

### Feature Flow

Today's `aid-execute` runs **one task per invocation** (`task-NNN` is a required
argument; the skill's "Delivery Lifecycle", `aid-execute/SKILL.md:334-352`,
documents the user manually issuing `/aid-execute task-003`, `/aid-execute
task-004`, … in sequence). FR6 makes the skill able to **advance a delivery wave at
a time**, dispatching *all* the ready, mutually-independent tasks of that wave
concurrently.

**Parallelism is aggressive and graph-bounded.** The Execution Graph is the *only*
bound on concurrency. There is **no artificial concurrency cap**: every task the
graph certifies as ready and independent in a given wave is dispatched at once. The
graph is trustworthy by virtue of upstream review — defined in `aid-plan` /
lite-path planning and re-confirmed in `aid-detail` — so FR6 leans on it fully
rather than second-guessing it with a heuristic ceiling.

**Wave-based execution loop** (the FR6 default for a delivery):

1. **Resolve the delivery.** From the task/delivery argument, locate the delivery
   and read its Execution Graph — from `PLAN.md` on the full path, or from the
   consolidated work-root `SPEC.md` on the lite path (same graph content, see Data
   Model).
2. **Compute the ready wave.** A task is *ready* when it is not yet `Done` and every
   task in its `Depends On` list is `Done` (Pre-flight Check 2b's existing rule,
   applied across the whole delivery instead of one task). The ready set is the
   current wave.
3. **Partition the wave by the parallel table.** Tasks in the ready set that the
   `Can Be Done In Parallel` table groups together are dispatched **concurrently**;
   tasks not so grouped run on their own. Concurrency is whatever the graph
   certifies — all of it, with no cap. The parallel table is the safety contract.
4. **Dispatch concurrently.** Each task in the wave runs the **existing
   per-task pipeline unchanged**: EXECUTE (type-specific executor) → per-task quick
   check (the FR2 two-tier model's first tier — coordinated with feature-004, not
   redefined here). Each concurrent task writes its own **Execution Record** zone in
   its `task-NNN.md` and its own `## Dispatches` rows, exactly as a serial run does.
5. **Join.** Wait for every task in the wave to settle: each reaches `TASK-DONE`,
   or raises an IMPEDIMENT (a critical that survives its one fix-on-spot —
   feature-004 Flow A). The wave is a barrier: the next wave's readiness cannot be
   evaluated until this wave's tasks have updated the Execution Record in their
   task files.
6. **Recompute and repeat.** Return to step 2. When no unfinished tasks remain, the
   delivery's tasks are complete.
7. **Per-delivery quality gate — once.** After the final wave, the FR2 per-delivery
   quality gate (the rigorous review → fix → review loop to grade ≥ minimum) runs
   **exactly once for the delivery**, unchanged by FR6. Parallelism multiplies task
   dispatch; it does not multiply the gate.

**Pre-FR6 vs. post-FR6** for the sample delivery in `aid-execute/SKILL.md:339-348`
(task-003 and task-004 both depend on task-002 — a two-task parallel group; a wider
graph fans out further, with no cap):

| | Today | With FR6 |
|--|-------|----------|
| task-003 / task-004 | User runs `/aid-execute task-003`, then `/aid-execute task-004` (or two terminals, by hand) | Both dispatched concurrently in one wave automatically |
| Per-task quick check | Once per task | Once per task — unchanged |
| Per-delivery gate | Once | Once — unchanged |

**Single-task invocation still works.** `/aid-execute task-NNN` for one specific
task is preserved (resume, re-run, targeted fix — `aid-execute/SKILL.md` Re-run and
Check 6 paths; with state read from the task file's Execution Record zone). FR6
adds the wave-driven default for advancing a delivery; it does not remove the
ability to run a single task.

**Failure inside a wave.** If a task in a concurrently-dispatched wave fails or
raises an Impediment:

- **In-flight sibling tasks are allowed to complete — not cancelled.** They are
  independent of the failed task per the verified Execution Graph (the graph guarantees it), so
  their work is valid and cancelling it would only waste completed effort.
- **The wave does not advance.** Once the wave's tasks have all settled, the next
  wave is *not* computed, because the failed task may be a `Depends On` of a later
  task. The delivery stops at the wave boundary.
- **The failure surfaces through the existing mechanisms** — the Impediment file
  and the circuit breaker (`aid-execute/SKILL.md` Impediments / Step 4) — exactly
  as for a sequential run. FR6 adds no new failure-handling machinery. The user
  resolves the failure before the delivery resumes; no partial wave is silently
  skipped.

### Layers & Components

FR6 touches **one skill — `aid-execute` — and nothing else.** No new agent, no new
template, no new artifact, no new script is required by the feature itself.

| Layer | Component | Change |
|-------|-----------|--------|
| Orchestration | `aid-execute` SKILL.md — its Delivery Lifecycle / execution-graph handling | The substantive change: a wave-based loop (compute ready wave → partition by the parallel table → dispatch concurrently → join → repeat) becomes the default for advancing a delivery. The graph is read from `PLAN.md` (full path) or the work-root `SPEC.md` (lite path). The existing single-task path is retained. |
| Execution | type-specific executor agents (`developer`, `researcher`, …) + the per-task quick-check reviewer | **Unchanged.** Each parallel task dispatches the same agents through the same per-task pipeline. FR6 changes the *number of simultaneous dispatches*, not what a dispatch does. |
| Quality gate | the FR2 per-delivery reviewer | **Unchanged.** Runs once per delivery, after the final wave. Defined by feature-004 (FR2); FR6 only guarantees it still fires exactly once. |
| Data | Execution Graph (`PLAN.md` / work-root `SPEC.md`); `task-NNN.md` Execution Record zone | **Unchanged.** Read-only consumption of the graph; per-task state written into each task file's Execution Record zone as today. |

**Concurrency mechanism.** Concurrent dispatch is realized through the host
agentic platform's existing sub-agent dispatch facility — the same mechanism
`aid-execute` already uses to dispatch one executor per task, and the same one
`aid-discover` uses to run its discovery sub-agents in parallel
(`architecture.md` pattern 2, "sub-agent dispatch (orchestrator-worker)";
`aid-methodology.md:254` — Discover "dispatches … four more in parallel"). Note
that the two are distinct dispatch surfaces: the directly relevant precedent is
`aid-execute`'s per-task **Task-tool** dispatch of one executor per task, whereas
`aid-discover` uses the **Agent** tool for its discovery sub-agents — so when
`INDEX.md`'s integration-map summary states `aid-discover` is the only skill
using the **Agent** tool for sub-agent dispatch, that is consistent with this
spec, which leans on the Task-tool path FR6 already exercises. FR6
issues as many such sub-agent dispatches in one wave as the graph certifies ready,
instead of one at a time. **Precedent exists in this codebase** — `aid-execute`
already dispatches per-task executors via the Task tool, and `aid-discover`
already runs sub-agents in parallel; FR6 combines the two by issuing several
per-task Task-tool dispatches per wave.
The exact platform call shape is an implementation detail and is **profile-aware**:
hosts that expose `background_execution` (an FR5 capability flag — owned by
`work-002`'s `feature-001-profile-driven-generator`) can run waves truly
concurrently; where that capability is weaker, NFR4 graceful
degradation (REQUIREMENTS.md §6) applies — `aid-execute` falls back to sequential
dispatch of the wave's tasks, preserving correctness and the methodology, losing
only the wall-time overlap.

**State-machine integrity.** Each task's `EXECUTE → REVIEW(quick) → … → DONE`
sub-machine is per-task and self-contained; running several of them at once does
not couple them because the graph guarantees the wave's tasks are independent
(no shared `Depends On`, no shared output).

**Shared delivery branch — no serialized-commit step.** The delivery branch
(`aid/delivery-NNN`, one branch per delivery — `aid-execute/SKILL.md:134`) is
shared by all tasks in the delivery today and remains shared. **Graph-independence
is *trusted* here to mean disjoint files (decision D's trust boundary):** the
parallel table only groups tasks that `aid-plan` / `aid-detail` certified as
independent by dependency; FR6 then *assumes* that dependency-independence implies
those tasks operate on disjoint files — and on that assumption, there is no file
contention between concurrently-running siblings, so concurrent commits to the
shared branch do not collide on content. FR6 therefore introduces **no
serialized-commit step, no per-task sub-branch, and no merge/rebase choreography**
— each task commits to the delivery branch as it does today. The trust boundary
is explicit: the graph format does not mechanically guarantee file-disjointness;
FR6 trusts the upstream review process (twice-verified graph) to make that
assumption hold.

### Constraints & Boundaries

- **Methodology preserved (§7).** FR6 changes *how* `aid-execute` advances a
  delivery, not *what* the pipeline does. Phases, artifacts, the per-task quick
  check, the per-delivery gate, deterministic grading, and the branch-per-delivery
  rule are all intact.
- **Coordinates with feature-004 (FR2), does not redefine it.** Every task in a
  wave receives its FR2 per-task quick check; the FR2 per-delivery quality gate
  runs once. The definition of those two tiers belongs to feature-004; FR6 only
  asserts they remain wired in.
- **Modest standalone gain — by design.** Per REQUIREMENTS.md FR6, the wall-time
  win from parallelism alone was modest in benchmarking; the headline speed gains
  are FR2 and FR3. FR6 is included because parallel-by-default is the *correct*
  execution behavior and complements them — not for its own speed number.
- **Graph is the sole bound.** FR6 imposes no artificial concurrency cap and no
  serialized-commit step. The verified Execution Graph is the only constraint on
  how wide a wave fans out, and graph-certified independence is trusted to mean
  disjoint files on the shared delivery branch (see Layers & Components).
- **Scope boundary.** FR6 does **not** change how the Execution Graph is produced
  (that is `aid-plan` / `aid-detail`'s job), does not add new parallelism beyond
  what the graph certifies, and does not touch deploy/monitor. It is one skill's
  default-behavior change.
