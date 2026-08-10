# task-004: Rule-binding table that class-scopes the lifecycle contract

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-004/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-003

**Scope:**
- Source spec: `features/feature-002-design-lifecycle-machinery/SPEC.md` §3g (AC-3).
  Written **last**, from the finished §3 and §4 (§8 § Internal order) -- which is why it is
  a task after task-003 rather than a section inside it.
- Append the rule-binding table to `canonical/aid/templates/design-lifecycle.md`: one row
  per rule the contract states, with three population columns -- class 1 (the 7 design
  artifacts), class 2 (the 14), and `/aid-brainstorm` -- each cell reading `Binds`, `No`
  with its reason, `N/A`, or the rule's per-population value.
- **Derive the row set by re-running §3g's stated derivation** over §2d, §3a-§3f and §4 in
  file order, rather than recalling the number: §2d 1 (acquisition, with its
  never-overwrite and warn-do-not-fail clauses); §3a 3 (`design` stage semantics, the
  `design` invariant, `create`/`update` stage semantics); §3b 1; §3c 2 (region ownership +
  write discipline, the first-write rule); §3d 1; §3e 5 (skill shape incl. the `description`
  contract, allocation, dispatch tiering, verify depth on `design`, verify depth on
  `create`/`update`); §3f 1; §4 5 (seed shape/headings, `## Destination`, naming, readiness
  gate + detection rule + placeholder convention, no `changelog:`). **19** at this revision.
  If the authored contract states a rule the tally does not carry, add the row and record
  the corrected tally -- the derivation is the authority, not the number.
- Every `No` and `N/A` cell carries its reason inline, so no row is a bare verdict: class 2
  is not authored by this work for `create`/`update`; class-2 seeds persist; class 2's
  destination is a built artifact rather than a document region; neither class-2 sub-case
  has a refusal state; `/aid-brainstorm` has no `create` counterpart.
- The `create`/`update` verify-depth row resolves class 2's two sub-cases separately --
  2a delegates to the engine's own GATE state, 2b to the collapse body, which has no GATE
  state to delegate to.
- Out of scope: adding, amending or removing any **rule**. This task binds the rules
  task-003 wrote; a rule that turns out to be missing is a task-003 defect and is fixed
  there, not invented here.

**Acceptance Criteria:**
- [ ] §7 C1 (review): the table holds exactly one data row per rule stated in §2d, §3a-§3f
      and §4 -- no duplicates, no orphans. The derivation is re-run and its result recorded
      alongside the table's row count, and the two agree
- [ ] §7 C2 (review): for every `Binds` cell, the contract names where the rule is
      implemented -- no rule binds a population that has no implementation site
- [ ] The dispatch-tiering row is present (it is the row an earlier spec revision stated in
      §3e and left unbound), and the verify-depth-on-`create`/`update` row resolves 2a and
      2b separately rather than delegating both to a mechanism that does not run for `2b`
- [ ] §7 J1 (review): a reader can state both stage tables (including `update`'s CC-3 seed
      read), both classes and class 2's two sub-cases, the region mechanics and the
      first-write rule, the readiness detection rule, "full verify", and the `description`
      contract from this file alone, without a second source
- [ ] The two sibling templates are unchanged by this task:
      `diff canonical/aid/templates/design-folder-readme.md .aid/design/README.md` is still
      empty and `grep -c '^## ' canonical/aid/templates/design-seed.md` still returns `6`
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
