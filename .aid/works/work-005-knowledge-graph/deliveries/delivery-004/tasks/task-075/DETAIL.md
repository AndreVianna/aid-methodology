# task-075: Validator contingency-trigger determination against the real `graph.html`

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-069

**Scope:**
- Execute feature-011 § Feature Flow step 1 -- the **trigger check** -- by running the three leaf
  validators against the real generated `.aid/knowledge/graph.html` exactly as D5 records their
  invocations:
  ```bash
  bash canonical/aid/scripts/summarize/validate-html-output.sh .aid/knowledge/graph.html --kb-dir .aid/knowledge
  node canonical/aid/scripts/summarize/contrast-check.mjs .aid/knowledge/graph.html
  node canonical/aid/scripts/summarize/validate-visuals.mjs .aid/knowledge/graph.html
  ```
- Record every check's verdict and **determine which contingency, if any, fires**: an `S2` failure
  is C1's trigger (FR-18 selected external delivery); a `T2` failure on the live drawing surface is
  C2's trigger (feature-002 selected SVG). Anything else that fails is a **view defect**, owned by
  feature-007/008/009, and is never a reason to widen a profile.
- Confirm the D7 degradation path: with Playwright absent, `validate-visuals.mjs` SKIPs with its
  remediation message and exits 0.
- Write the determination into the delivery's review-pending ledger so tasks 076/077 (and
  delivery-005's 084/085) fire, or are recorded no-ops, on evidence rather than assumption.
- **This task authors no test suite.** Its product is the determination.
- **Out of scope:** editing any validator (task-076 if C1 fires; task-084 in delivery-005 if C2
  fires); the golden-output suites (task-077, task-085); fixing any view defect it finds.

**Acceptance Criteria:**
- [ ] All three commands are run exactly as feature-011 D5 records them, and each individual
      check's verdict -- including all three `NM` sub-checks, `S2`, and `T1`-`T4` -- is recorded
      with its output.
- [ ] The determination states one of: **C1 fires** (an `S2` failure was observed), **C2 fires**
      (a `T2` failure on the live drawing surface was observed), **both fire**, or **neither
      fires**; and it names the observed evidence for the verdict it reaches.
- [ ] Any failure that is **not** `S2` and **not** `T2` on the live surface is recorded as a view
      defect with the owning feature and task named -- explicitly not as a carve-out trigger. In
      particular a `T1` (font-size), `T3` or `T4` failure is a legibility or layout defect to fix,
      and an `NM` failure is a D-012 violation, never a waiver candidate.
- [ ] If neither trigger is observed, the record states "no contingency fires; no shared validator
      is edited" -- the outcome feature-011 expects under the reference local-vendored layout --
      and tasks 076/077 become recorded no-ops citing this determination.
- [ ] The Playwright-absent path is exercised and recorded: `validate-visuals.mjs` prints
      `SKIP -- Playwright is not installed in this environment.` with the
      `npx playwright install chromium` remediation and exits **0**, and the run continues (D7).
- [ ] `bash tests/canonical/test-guardrails-d012.sh` passes **unmodified** both before and after
      this determination -- nothing was changed, and the standing `kb.html` pin proves it.
- [ ] The determination is written to `.aid/.temp/review-pending/` in the 7-column reviewer-ledger
      schema, so the firing condition tasks 076/077 quote is evidenced and citable.
- [ ] **Deterministic** (TEST default, adapted -- this task runs existing validators rather than
      authoring a suite): the three invocations are re-runnable against an unchanged artifact and
      produce the same verdicts.
- [ ] **Clean setup/teardown** (TEST default): nothing is written into `.aid/knowledge/`, no
      validator or call site is modified, and no temporary file is left behind.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
