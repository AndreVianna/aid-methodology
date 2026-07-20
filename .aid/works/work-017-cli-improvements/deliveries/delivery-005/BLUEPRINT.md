# Delivery BLUEPRINT -- delivery-005: Execution Control

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-005
> **Work:** work-017-cli-improvements
> **Created:** 2026-07-18

---

## Objective

Let a user control running work from the dashboard: Finish a pipeline and Stop/Resume the
currently-executing task. Finish posts `pipeline.finish`, persisting `lifecycle = Completed`
through `writeback-state.sh`; the running `aid-execute` session, which already polls state, then
stops dispatching and does not advance. Stop/Resume posts `task.stop` / `task.resume` to the new
`write-control-signal.sh`, which creates/removes a per-task signal file under a gitignored
`.aid/.control/` directory; the executor stats it on the same poll cadence and winds the task
down cooperatively -- because the LLM-free server cannot kill a separate agent session directly.
A "stopped" task stays `In Progress` (no new `Paused` enum); its paused condition is an additive
derived `stop_requested` flag computed from the control-file presence. The Stop/Resume control is
offered only while a task is actively executing (AC6). This is the highest-uncertainty item in
the work and is isolated as the last deliverable: the dashboard side satisfies its acceptance
criteria on its own, but the raised signal only *bites* once the executor poll edit is rendered
across the canonical skill, the five profiles, and the dogfood tree -- the single largest render
surface in the work.

## Scope

In scope:
- **feature-008-execution-control** -- consumes the seeded `pipeline.finish` row; adds `task.stop` / `task.resume` `OP_TABLE` rows + the new co-vendored `write-control-signal.sh`; adds the additive derived `stop_requested` model field (both twins, filesystem `stat`, no `STATE.md` parser change); `home.html` Finish control (on Running pipelines) + Stop/Resume toggle on the currently-running task chip/drill view; `.aid/.control/` gitignore; the `aid-execute` poll contract (baseline orchestrator poll required; sub-agent `STOP_FILE` mid-task poll recommended).

**Out of scope:** any pipeline-lifecycle edit beyond `Running -> Completed` (no free lifecycle editing; the op value is fixed to `Completed`); rerun/start of a completed or pending task (AC6); `In Review` stop; every other delivery's surface.

## Gate Criteria

- [ ] AC-EC1 -- Finish, Stop, and Resume are performed from the dashboard and persist to disk (`lifecycle = Completed` in `STATE.md`; the `.aid/.control/<work_id>/task-<NNN>.stop` file created/removed).
- [ ] AC2 -- after each action the view re-renders from a post-op `/r/<id>/api/model` read; Finish shows `Completed`, Stop/Resume shows the re-derived `stop_requested`, with no drift.
- [ ] AC3 -- the only `STATE.md` write (`lifecycle = Completed`) goes through `writeback-state.sh`; no DERIVED view is hand-written; the `.stop` signal is a non-STATE control artifact written by a dispatched child (SEC-3).
- [ ] AC6 -- the Stop/Resume control renders iff `task.status === 'In Progress'` (and `write_enabled`); completed/pending/`In Review` tasks offer no rerun/start affordance.
- [ ] Executor poll (baseline, required) -- `state-execute.md` re-reads `lifecycle` and stats each in-flight task's `.stop` file at the existing dispatch boundary / heartbeat-read point, rendered canonical -> 5 profiles -> dogfood in lockstep, so the raised signal actually halts work.
- [ ] WT-1 -- the control file and the `stop_requested` stat both derive from `resolve_work_dir` / the walked worktree copy, landing in the same tree the executor polls (never a reconstructed served-tree path).
- [ ] AC4 / AC8 (inherited) -- the derived `stop_requested` is computed by an identical `stat` in both twins (fixtures regenerated in lockstep); all three ops honour `write_enabled`.
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-028 | IMPLEMENT | write-control-signal.sh stop-signal writer + gitignore |
| task-029 | IMPLEMENT | Derived stop_requested reader twin + task.stop/resume ops |
| task-030 | IMPLEMENT | Finish + Stop/Resume UI |
| task-031 | IMPLEMENT | Executor-poll baseline in state-execute.md across all profiles |
| task-032 | IMPLEMENT | Sub-agent STOP_FILE mid-task poll enhancement (separable) |
| task-033 | TEST | Execution-control op round-trips + parity |

## Dependencies

- **Depends on:** delivery-001 (write foundation: `OP_TABLE`, seeded `pipeline.finish`, write gate, `resolve_work_dir` / WT-1, co-vendor mechanism)
- **Blocks:** -- (none)

## Notes

The executor edit's render-lockstep blast radius (canonical skill + 5 profiles + dogfood +
parity) is the reason this is the last, isolated deliverable. The baseline orchestrator poll is
separable from the recommended sub-agent `STOP_FILE` mid-task enhancement (an opt-in dispatch
parameter analogous to `HEARTBEAT_FILE`). KI-007 (Low, latent): under a duplicated `work_id`
across worktrees the reader could read back `stop_requested` from a non-winner copy -- not present
in work-017's live topology; any fix belongs in feature-001's reconcile/resolve alignment.
