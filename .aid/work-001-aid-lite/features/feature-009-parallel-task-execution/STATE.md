# Specification State

**Status:** Ready
**Started:** 2026-05-22

## Activated Sections

| Section | Status | Activation |
|---------|--------|------------|
| Data Model | Written | core — no new artifacts; consumes the existing Execution Graph (`Depends On` + `Can Be Done In Parallel` tables) from `PLAN.md` (full path) or the consolidated work-root `SPEC.md` (lite path) |
| Feature Flow | Written | core — the wave-based execution loop: compute ready wave → partition by the parallel table → dispatch concurrently → join → repeat → per-delivery gate once |
| Layers & Components | Written | core — single-skill change to `aid-execute`; executors, quick check, and per-delivery gate unchanged |
| Constraints & Boundaries | Written | added — small feature; records §7 methodology-preservation, FR2/feature-004 coordination, and the scope boundary |

## Pending Q&A

(none)

## Loopbacks

(none)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Specification started — 3 core sections activated (Data Model, Feature Flow, Layers & Components) plus a Constraints & Boundaries note; proportionate to a small one-skill feature | /aid-specify |
| 2026-05-22 | Technical Specification written — wave-based execution loop for `aid-execute`, no new artifacts; 4 open questions surfaced for the methodology owner; Status → In Discussion | /aid-specify |
| 2026-05-22 | Technical Specification revised in place against locked decisions D/A/B. **D** — parallelism is aggressive and strictly graph-bounded: no artificial concurrency cap; graph-independence trusted on the shared delivery branch (disjoint files ⇒ no serialized-commit step); on failure, in-flight sibling tasks finish (not cancelled), the wave does not advance, failure surfaces via existing Impediment / circuit-breaker. **A** — all `task-NNN-STATE.md` references replaced with the merged `task-NNN.md` Execution Record zone. **B** — Execution Graph read from `PLAN.md` (full path) or the consolidated work-root `SPEC.md` (lite path), same content. Wave-loop, single-task invocation, and `aid-discover` parallel-dispatch grounding retained. No new open questions. | /aid-specify |
| 2026-05-22 | Reviewer-identified fixes applied (1 LOW + 2 MINOR; architecture graded B+, no redesign). **LOW** — Concurrency mechanism section reconciled with `INDEX.md`'s integration-map summary: clarified that the relevant precedent is `aid-execute`'s per-task **Task-tool** dispatch, distinct from `aid-discover`'s **Agent-tool** discovery dispatch — no contradiction with the KB. **MINOR** — corrected `aid-detail/SKILL.md` citation for the "share dependencies but don't depend on each other → parallel" quote from `:297-298` to `:296` (Dependency-rules block 293-298). **MINOR** — added a coordination note that producing the identical two-table Execution Graph format on the lite-path work-root `SPEC.md` is feature-005's responsibility (the cited example is the full-path producer). | /aid-specify |
| 2026-05-22 | Independent-review fixes applied (2 LOW + 2 MINOR). **LOW** — line citation for the "share dependencies but don't depend on each other → parallel" quote corrected from `:296` back to `:297` (the prior fix overshot by one line; line 296 is the preceding bullet's continuation; the precise rule is on line 297). **LOW** — Data Model and Layers & Components reworded to frame disjoint-files as decision D's *trust assumption* (graph-certified dependency-independence is *trusted* to mean file-disjointness on the shared delivery branch), not as a structural guarantee the graph format mechanically provides; consistent with the Constraints section's existing "*trusted* to mean disjoint files" phrasing. **MINOR** — added parenthetical cites to Layers & Components: `background_execution` (FR5 capability flag — feature-001) and NFR4 graceful degradation (REQUIREMENTS.md §6). **MINOR** — Feature Flow step 5 vocabulary aligned with feature-004's two-tier model: rewrote "reaches its terminal per-task state, or raises an Impediment, or fails" as "reaches `TASK-DONE`, or raises an IMPEDIMENT (a critical that survives its one fix-on-spot — feature-004 Flow A)". | /aid-specify |
