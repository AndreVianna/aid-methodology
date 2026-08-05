# task-010: feature-002 Stage 2b -- the derived bench, NFR-7's floor and NFR-8's ceiling

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-010/STATE.md.
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

**Type:** RESEARCH

**Source:** feature-002-graph-rendering-research -> delivery-001 (Wave 1)

**Depends on:** task-003, task-005, task-007

**Scope:**
- feature-002 Stage 2b: apply Stage 2a's response surface to a bench **derived by D2's procedure**
  over the enumerated node set, and produce the two verdicts AC-6a needs — a steady-simulation
  window and a node-drag window, each measured against D4b's frame-time predicate and NFR-7's floor.
- Produce NFR-8's ceiling: the node count at which the predicate stops clearing the floor, stated
  with its measurement conditions. This is the value `canonical/aid/templates/graph/scale-ceiling.yml`
  is waiting for — the file ships `node_ceiling` as a required key with **deliberately no value**,
  and its own header says the value arrives with this measurement. **Writing the value into the
  carrier is task-021's**, not this task's; this task produces the number and its conditions.
- Write the runtime-prerequisite statement as prose that AC-6 can be checked against — Cross-Cutting
  Risk 6 requires exactly that, and feature-007/feature-010 quote it rather than compose it.
- **Depends on task-003** (the surface), **task-005** (feature-004's enumerator) and **task-007**
  (feature-005's Pass 1a) — D2 states the derivation needs all three.

**Acceptance Criteria:**
- [ ] The bench is derived by D2's stated procedure and **not** by counting this repository's files;
      the procedure is portable to any project with an approved KB (FR-8a)
- [ ] Both AC-6a windows measured — steady simulation and node drag — each with its statistic and an
      explicit clears / does-not-clear verdict against NFR-7's floor
- [ ] `node_ceiling` reported as a positive integer with the conditions it was measured under, and
      with the comparand named: the total node count across every producer stream
- [ ] The runtime-prerequisite statement is written as checkable prose, quotable verbatim by
      feature-007's page footer and feature-010's console output
- [ ] No product code and no carrier edit — this task writes a document; the carrier write is
      task-021's
- [ ] Written to `deliveries/delivery-001/research/`; not cited by any permanent artifact
- [ ] **Sources cited** and an **actionable recommendation** stated (RESEARCH type-defaults,
      `task-decomposition.md`:180) -- the recommendation being NFR-8's ceiling and NFR-7's two verdicts,
      each stated with its measurement conditions, since `task-021` writes the ceiling into a shipped
      carrier and an unconditioned number there would be unfalsifiable
- [ ] **RECORDED OVERRIDE of the third RESEARCH default, "at least 2 alternatives compared."** This task
      applies `task-003`'s surface to a derived bench and reports two windows and a ceiling; it selects
      nothing. Substituted obligation: the bench is derived by D2's procedure over the enumerated node
      set rather than hand-picked, and the derivation is shown
- [ ] All section-6 quality gates pass
