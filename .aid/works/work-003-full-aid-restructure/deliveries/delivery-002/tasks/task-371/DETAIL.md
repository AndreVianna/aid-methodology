# task-371 (task-037a): The flow-chart builder reads the one-line continuation form

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 371 --field State.

**Type:** FIX

**Source:** feature-002-step-by-step-decisions -> delivery-002 -> AC-37 (Q157: fix the builder now
rather than backlog it)

**Depends on:** --. task-037 depends on this task.

**Why:** task-037 replaces the shortcut engine's continuation paragraph with the one-line form
"On **continuation**, follow the gate's § 3b: ...". The site flow-chart builder draws the
Continuation branch (rule B1) only when the "On **continuation**" arm also says `HALTS` or
`does not run` (`B1_TRIGGERS_RE` in `site/scripts/lib/flow-graph/engine-core.mjs`). With the new
form it finds no trigger, so the 34 skill flow pages built on the shortcut engine lose their
Continuation branch and 42 site tests fail.

**Scope:**
- `site/scripts/lib/flow-graph/engine-core.mjs`: rule B1 for INTAKE also fires on the one-line form,
  an "On **continuation**" arm that says `follow the gate's § 3b` (match the gate reference, not one
  exact sentence, so a re-wrap does not break it). The B1 node's name, its branch edge, the re-kinded
  advance edge and their provenance stay as the old form gives them. The old form keeps working, so the
  builder is correct before and after task-037 lands. The GATE circuit-breaker arm is unchanged.
- Update the comments that describe the B1 trigger (the header list near the rule and the
  `_applyB1` / `_findIntakeB1Arm` doc comments) to name both forms.
- `site/scripts/__tests__/`: cases in the style of the existing B1 tests: the one-line form gives the
  same B1 node and edges as the old form; an "On **continuation**" arm with neither trigger still gives
  no B1 node; each case fails against a copy of the builder with the new trigger removed.
- Do not change any skill or template file: task-037 owns the wording.
- **Test step:** `(cd site && npm test)` on this task's tree. Then, in task-037's worktree with this
  change applied, regenerate (`npm run gen:skills && npm run gen:reference`) and run `npm test`: the 42
  tests that failed on task-037's change pass, and the 34 flow pages keep their Continuation branch.

**Acceptance Criteria:**
- [ ] On the one-line form, every shortcut-engine skill's flow chart has the Continuation branch, with
      the same node name and edges as on the old form.
- [ ] The old form still gives the same chart as before (the committed flow JSON is byte-identical
      after regeneration on this task's own tree).
- [ ] An arm with no trigger and no gate reference still gives no B1 node.
- [ ] The new test cases pass, and each fails against the builder with its new trigger removed.
- [ ] `(cd site && npm test)` passes on this task's tree, and again on task-037's change with this
      task applied.
