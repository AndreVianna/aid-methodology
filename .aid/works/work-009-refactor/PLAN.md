# Plan -- Convert Work-Tree STATE Files to YAML and Exclude Them From Review

> **Work:** work-009-refactor
> **Created:** 2026-08-12

---

## Deliverables

- **Delivery:** delivery-001 -- Convert Work-Tree STATE Files to YAML and Exclude Them From Review
- **What it delivers:** Every work-tree state tracker under `.aid/works/` -- the work-level file
  and, on the full path, each `deliveries/delivery-NNN/STATE.md` and
  `deliveries/delivery-NNN/tasks/task-NNN/STATE.md` -- becomes a `STATE.yml` holding the same
  keys, the same closed-enum values and the same semantics as YAML instead of a YAML frontmatter
  block wrapped in markdown prose. The machine writer collapses four hand-rolled awk grammars
  onto one write path, both dashboard reader twins collapse their per-section line handlers onto
  one structured read, and the three shell state readers keep their cheap hand-rolled lookups with
  no YAML dependency -- including the `delete-pipeline.sh` guard whose read gates a destructive
  operation. Because the file stops looking like prose, it stops being handed to reviewers as
  prose: state files are named out of the reviewable-artifact surface at the single upstream point
  every reviewer brief derives from, so state churn in a reviewed diff is no longer gradeable
  content (the reviewer still *writes* its outcome into state). Works already on disk are
  converted by the CLI's existing per-repo format migration, so no in-flight work is stranded and
  an older CLI run against a converted repo gets a named diagnostic rather than an empty
  dashboard.
- **Features:** feature-001-state-yaml-and-review-exclusion   (the single feature; no `features/` folder)
- **Depends on:** -- (none -- single delivery)
- **Priority:** Must

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-003 |
| task-005 | task-003, task-004 |
| task-006 | task-002 |
| task-007 | task-004, task-006 |
| task-008 | task-007 |
| task-009 | task-008 |
| task-010 | task-009, task-017, task-020 |
| task-011 | task-008 |
| task-012 | task-001 |
| task-013 | task-012 |
| task-014 | task-002, task-007, task-012 |
| task-015 | task-006, task-009 |
| task-016 | task-004, task-020 |
| task-017 | task-014 |
| task-018 | task-017 |
| task-019 | task-005, task-010, task-011, task-013, task-015, task-016, task-018 |
| task-020 | task-007 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002, task-012 |
| 3 | task-003, task-006, task-013 |
| 4 | task-004 |
| 5 | task-005, task-007 |
| 6 | task-008, task-014, task-020 |
| 7 | task-009, task-011, task-016, task-017 |
| 8 | task-010, task-015, task-018 |
| 9 | task-019 |

---

## Sequencing Notes

**`task-010` depends on `task-017`, and the edge is now encoded.** `task-010` converts every live
work tree in this repository. The live pipeline writes state through the **dogfood render** of
`writeback-state.sh`, and `task-017` (render fan-out + dogfood resync) is the only task that
updates that render. Converting live works before `task-017` lands would leave the repo's own
tracking being written by a markdown-era writer against `STATE.yml` files -- exactly the
"reader/CLI support before any conversion" invariant of `SPEC.md § SP-18` and `C-6`. That
invariant previously rested on an *unstated* ordering: the wave computation happened to place
`task-017` in wave 7 and `task-010` in wave 8, so the ordering held by arithmetic rather than by
constraint, and any edge-driven consumer (`compute-block-radius.sh`, or any scheduler that reads
the dependency table rather than the wave table) saw no ordering at all.

**The wave table is unchanged by this edit, and that is the expected result.** Every wave above is
the topological minimum of the dependency table (wave = 1 + max(wave of dependencies)). Adding
`task-017` (wave 7) to `task-010`'s dependencies leaves `task-010` at wave 8, where it already
was. The edit makes the constraint *explicit* without changing the schedule -- which is precisely
why it was easy to miss.

**`task-020` is the dashboard server layer (`SPEC.md § L-11`), split out of `task-007` rather than
folded into it.** `task-007` already collapses four hand-rolled awk grammars in
`writeback-state.sh` onto one write path and hand-carries the same change into the
`dashboard/scripts/` fork; the six `AID_STATE_FILE` constructions in `dashboard/server/server.mjs`
and `server.py` plus `dashboard/home.html`'s source labels are a different language, a different
runtime pair, a different failure mode (an explicit env override beating the writer's layout
auto-detection -> `exit 1` on a nonexistent path) and a different gate (SP-19b, not SP-4/5/6). They
are also strictly *downstream* of the writer they call, so folding them in would put a dependency
inside one task. Both runtimes stay in `task-020` together -- `server.mjs` and `server.py` are a
lockstep twin pair under C-4 and may never be split across tasks or commits. `task-016` gains
`task-020` as a dependency because
`dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` is that layer's only oracle.

**`task-010` depends on `task-020` too, for the same reason it depends on `task-017`.** The
dashboard server layer is a state-file *consumer* whose every write-enabled edit surface breaks the
moment a live work is converted underneath an unretargeted `AID_STATE_FILE` -- so "the readers, the
shell readers and the CLI accept `STATE.yml` **before** any live work tree is converted" (SP-18,
C-6) covers it. Without the edge the ordering would again hold only by arithmetic (`task-020` in
wave 6, `task-010` in wave 8), which is precisely the flaw the paragraph above records. Adding it
leaves `task-010` at wave 8, where it already was.

**The wave table recomputation, over all twenty tasks.** Every wave is still the topological
minimum of the dependency table (wave = 1 + max(wave of dependencies)). Two rows move, both as a
consequence of the `task-020` split: `task-020` lands in wave 6 (after `task-007` in wave 5), and
`task-016` moves from wave 5 to wave 7 (after `task-020`). Nothing else shifts -- `task-010` stays
at wave 8 (`max(task-009 = 7, task-017 = 7, task-020 = 6) + 1`) and `task-019` stays at wave 9,
because its longest path still runs through `task-010`, `task-015` and `task-018` in wave 8.

**Not covered by any edge either: which works `task-010` converts.** That set is **enumerated from
disk at execution time**, as `task-010`'s first step -- `.claude/aid/scripts/works/enumerate-works.sh`
per worktree root, or the equivalent `git worktree list` + `ls <root>/.aid/works/` sweep -- and the
recorded enumeration is the authority for the run. No roster in `PLAN.md`, `BLUEPRINT.md` or
`tasks/task-010/DETAIL.md` is that authority; each carries at most an illustrative snapshot,
explicitly labelled as one. The reason is empirical rather than stylistic: two additional worktrees
appeared while this delivery was being defined, so any list authored here is stale before it is
read, and a work omitted from a hardcoded roster is a work left in markdown after the cutover --
exactly what SP-18 and `BLUEPRINT.md § Notes` ("No two-format end state") forbid.

**Not covered by any edge: reinstalling the CLI.** `BLUEPRINT.md § Notes` records the hazard that
"a repo-local fix does not reach an already-installed `aid` until it is reinstalled". `task-010`
runs the conversion through `aid update`, i.e. through the *installed* CLI, not through
`bin/aid` in this tree -- so the format-4 carriers `task-009` bumps only take effect after a
reinstall. That reinstall step belongs inside `task-010` (or as an explicit final step of
`task-009`); it is not expressible as a task edge and is recorded here so a later executor cannot
lose it.
