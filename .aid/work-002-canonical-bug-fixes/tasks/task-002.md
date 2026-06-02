# task-002: compute-block-radius.sh — four correctness fixes (B1–B4)

**Type:** IMPLEMENT

**Source:** work-002-canonical-bug-fixes → delivery-001

**Depends on:** — (none)

**Scope:**
All four fixes are in `canonical/scripts/execute/compute-block-radius.sh`. One cohesive pass; the
exit-contract (B2) and existence/leaf-node (B3) changes touch the same region, so do them together.

- **B1 — any-level Execution Graph (~line 138).** Relax the header matcher in
  `build_reverse_graph_from_plan()` from `/^####[[:space:]]+Execution Graph/` to
  `/^#+[[:space:]]+Execution Graph/`, so lite/recipe specs with a top-level `## Execution Graph`
  parse correctly. Keep the row parsing, the "Can Be Done In Parallel" stop condition, and the
  blank-line terminator unchanged.

- **B2 — exit-2 contract vs behavior (header :31; code ~:281).** The header documents exit 2 as
  "warn but succeed with empty set," but the code does `exit 2` (failure under `set -e`). Make a
  genuinely-absent failed task **warn to stderr, print nothing, and exit 0** under BOTH `--plan-file`
  and `--graph-file`, and update the header exit-code table to match (retire code 2 as a "success"
  signal).

- **B3 — declared leaf tasks resolve to empty radius (~lines 277–282).** `build_reverse_graph...`
  emits only edges, so a task declared in the graph but with no deps and no dependents appears in no
  TSV row and is falsely "not found." Add declared-node enumeration (e.g.
  `list_graph_nodes_from_plan()` capturing the left-column `task-NNN` of every Depends On row) and
  define existence as declared-node OR appears-in-an-edge; a declared leaf yields an empty radius and
  exit 0. **Folds in B5:** replace the unanchored `grep -q "^${FAILED_TASK_NORM}"` (which prefix-
  matches `task-001` against `task-0010`) with a tab/line-anchored check; do not rely on
  `grep -E '\t'` interpreting the tab (prefer `awk -F'\t'` or a `$'\t'` literal).

- **B4 — `--delivery-id` graph scoping (~lines 124–194, 277).** A multi-delivery `PLAN.md` currently
  merges every delivery's graph, so colliding per-delivery `task-NNN` IDs contaminate the radius.
  Add an optional `--delivery-id NNN`; when the PLAN has `### delivery-` sections, restrict parsing to
  the matching block. Without `--delivery-id` on a multi-delivery PLAN → distinct non-zero error
  (e.g. 5) rather than silent merge. Lite/recipe specs (no `### delivery-`) need no scoping. Leave
  the `--graph-file` TSV branch unscoped. Use portable awk (no gawk 3-arg `match`); update usage/help
  and the header exit-code table.

**Acceptance Criteria:**
- [ ] B1: a `##`-level Execution Graph (lite/recipe) yields the correct reverse graph (was empty);
      a `####`-level full PLAN still parses.
- [ ] B2: an absent failed task warns to stderr, prints nothing, exits 0 under both input modes; the
      header exit-code table matches behavior.
- [ ] B3: a declared leaf (`| task-003 | — |`, nothing depends on it) returns an empty radius and
      exit 0; `task-001` is not satisfied by a graph containing only `task-0010`; tab matching works
      under the project's grep/awk.
- [ ] B4: a 2-delivery PLAN where both declare `task-001` returns the correct radius for the given
      `--delivery-id` with no bleed; without `--delivery-id` it errors; lite specs and `--graph-file`
      are unaffected.
- [ ] `tests/canonical/test-compute-block-radius.sh` passes; add cases for the `##` heading, the
      absent-task exit-0 contract, the declared-leaf, the prefix collision, and multi-delivery
      scoping.
- [ ] All §6 quality gates pass.
