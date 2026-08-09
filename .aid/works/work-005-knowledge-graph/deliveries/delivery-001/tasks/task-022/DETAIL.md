# task-022: Run the full FR-28 rubric over both artifacts

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-022/STATE.md.
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

**Type:** TEST

> **TYPE OVERRIDE, recorded rather than left to look like a mis-type.** `task-type-rules.md`'s TEST
> rule is "write integration/E2E/UI/load tests as specified in the task scope", and this task writes
> none: it *runs* the FR-28 rubric via `grade-graph.sh`, evidences each criterion and produces a graded
> ledger. No type in the closed set (IMPLEMENT, TEST, RESEARCH, DESIGN, DOCUMENT, MIGRATE, REFACTOR,
> CONFIGURE) names "run an acceptance rubric and evidence its verdicts", and TEST is the nearest --
> the work is verification, and its output is a pass/fail judgement over acceptance criteria. Recorded
> as an explicit override per `task-decomposition.md`:174 ("unless the task explicitly overrides")
> rather than silently carrying a type whose rule text does not describe the work.

**Source:** feature-010-aid-graph-skill-runtime -> delivery-001 (Wave 4)

**Depends on:** task-014, task-016, task-018, task-020, task-021, task-023

**Scope:**
- The gate this delivery exists to close. Run `canonical/aid/scripts/graph/grade-graph.sh` over
  **both** artifacts — `relationships.md` and `graph.html` — with the `R*` data checks and the `V*`
  view checks closing **together, once, here**. Under the retired six-delivery sequence the halves
  closed in different deliveries; the single boundary dissolves that hazard but not the obligation.
- Evidence AC-9 and AC-15 on **both** halves. Neither owner may consider either criterion met alone,
  and the gate may not pass on one half plus an assumption:
  - **AC-15** halves: task-012 (ledger), task-014 (shell), task-018 (canvas)
  - **AC-9** halves: task-016 (table, and the criterion's overall ownership) and task-018 (the
    reduced-motion clause and the canvas ARIA scoping)
  - **AC-7** halves: task-014, task-016, task-018

**Acceptance Criteria:**
- [ ] Every rubric row reports a real verdict; **no skip stands in for a pass**, and any legitimate
      skip names why it is legitimate
- [ ] The `R*` and `V*` halves both run in the same invocation, over both artifacts
- [ ] AC-9, AC-15 and AC-7 each cite the task that evidenced each half, by task id — a criterion with
      one half cited is not closed
- [ ] The run meets the `minimum_grade: B-` floor recorded in the work `STATE.md` frontmatter
- [ ] FR-26 is reported as **not fully satisfiable** until the external
      `reviewer-ledger-schema.md` retention amendment lands (Cross-Cutting Risk 1), rather than
      silently marked met
- [ ] Any finding the run produces is written to the ledger at `.aid/.temp/review-pending/` in the
      7-column schema, with plain-text status values
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass
