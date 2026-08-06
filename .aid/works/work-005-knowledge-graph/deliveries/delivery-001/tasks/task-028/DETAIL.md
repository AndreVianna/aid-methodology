# task-028: The test census

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-028/STATE.md.
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

**Source:** feature-013-tests-and-docs -> delivery-001 (Wave 5)

**Depends on:** task-022, task-025, task-027

**Scope:**
- feature-013 `AC-T9` and D2's census. **Report the set** of suites this work ships and what each
  proves; name any behaviour that has no suite which fails when it breaks; and raise each such gap
  **against the owning feature** rather than patching it here.
- The census exists because of tech-debt L4 — the test-effectiveness gap whose proof case is the
  `io_bounds.py` incident, where five install manifests and two installer test lists all asserted
  each other and "passed" while every one of them was missing a shipped, security-relevant file. The
  tests ran; they did not bite. That is why feature-013 is a feature and not a checklist.

**Acceptance Criteria:**
- [ ] The census **reports a set**, not a count — a numeric total is not the deliverable
- [ ] Each suite is paired with what it proves, stated as a behaviour rather than as a file name
- [ ] Every behaviour with no biting suite is named and routed to its owning feature; none is patched
      inside this task
- [ ] The L4 failure mode is explicitly checked for: **no assertion that compares one manifest to a
      sibling manifest is counted as coverage**
- [ ] Two commands, no new CI lane — the ship gate adds no aggregate lane wiring
- [ ] Suite totals cited in the census are read from each script's own summary line
- [ ] The census output lives where a permanent artifact may reference it, or is explicitly declared
      transient — it may not become a permanent dependency on this work folder
- [ ] **The FR-28 verdict is re-validated against the delivery's FINAL state.** `task-022` runs the
      full rubric in gate wave 4, but wave-5 tasks **inside this task's dependency closure** move
      content the rubric reads afterwards -- `task-024` re-renders across five profile roots and both
      dogfood trees, and `task-027` restructures suites. The BLUEPRINT claims the rubric "closes over
      both artifacts in this delivery's gate", and a wave-4 run cannot support that claim on its own.
      So: re-run `grade-graph.sh` over `relationships.md` and `graph.html` here and confirm every
      verdict `task-022` recorded still holds. A changed verdict is a finding, not a refresh.
      **Two wave-5 tasks are deliberately NOT required to precede this one, and the omission is the
      point.** An earlier version of this criterion also demanded that `task-026` and `task-029` "have
      landed" first, which no executor could satisfy: `task-026` stands in no dependency relation to
      this task, and `task-029` **depends on** this task, so it can never precede it. Neither touches a
      rubric input -- `task-026` writes Knowledge Base documents, `task-029` disposes ledger rows, and
      FR-28 reads only `relationships.md` and `graph.html`. Their absence from the closure is therefore
      correct, not an ordering this task must enforce
- [ ] **Accuracy verified against the current codebase** (DOCUMENT type-default,
      `task-decomposition.md`:182), sharpened for a census, whose whole value is that it not flatter the
      suite set: every "covered" claim is verified by reading the assertion that would fail, never
      inferred from the presence of a suite whose name matches the behaviour -- that inference is
      precisely the `io_bounds.py` failure this census exists to answer
- [ ] **The census counts SKIPPED assertions as UNCOVERED, and names them.** A suite that passes
      while a third of its named acceptance ids skip is exactly the "tests ran but did not bite" case
      this census exists for -- the `io_bounds.py` shape in a new form. **Known instance, do not
      rediscover it:** 11 of feature-009's DOM-grounded `TV` verdicts (TV04, TV05b, TV06c, TV08b,
      TV09b, TV10, TV12, TV13b, TV15, TV17, TV18) SKIP on every machine AND in CI, because
      `graph-view-dom.mjs` resolves jsdom by bare specifier while jsdom is declared only in
      `site/package.json` and CI runs `tests/run-all.sh` with no install (tech-debt **W5-9**). The
      census must report those as uncovered rather than counting `test-graph-table-view.sh`'s 116
      passes as feature-009's coverage
- [ ] All section-6 quality gates pass
