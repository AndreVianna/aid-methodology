# task-043: Shared-validator reuse and degradation verification

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

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-029, task-040

**Scope:**

- Verify **AC-17's data half**: that `/aid-graph`'s validation layer *reuses* the existing
  summary-skill tooling rather than reimplementing it, and that its documented degradation paths
  behave as specified. Feature-011's own framing is that "the expected flow is that this feature
  performs no edit at all" -- so this task is a **verification** task over existing code plus the
  new `grade-graph.sh`, not the authoring of a new validator suite.
- **Scope boundary, stated so the gate is not over-read: AC-17 does *not* fully close in
  delivery-002.** The two validator carve-outs are **contingent** (C1 `--profile graph` for S2,
  fired only if FR-18 selects external delivery; C2 the `validate-visuals.mjs` T2 exclusion,
  fired only for an SVG live surface) and neither can be exercised until `graph.html` exists in
  **delivery-004**. The trigger determination is task-075; the two contingent suites are tasks
  077 and 085. **This task closes the structural half only** -- the half that is decidable with
  the table alone.
- The four things verified, each recorded as evidence in the delivery gate:
  1. **No shared check body with `grade-summary.sh`.** Diff `grade-graph.sh` against
     `canonical/aid/scripts/summarize/grade-summary.sh` and confirm no check body is shared,
     because `grade-graph.sh` contains none -- it invokes the same leaf validators. Confirm
     `COV`, `AUTO_POOL`, `WEIGHTS`, the 70-point pool, the hardcoded `KB_DIR=".aid/knowledge"`,
     and `MANUAL_CHECKLIST_FILE=".aid/.temp/summarize/manual-checklist.json"` appear **nowhere**
     in `grade-graph.sh`. Confirm the deliberate non-reuse is the recorded one: importing `COV`
     would grade the Knowledge Base's completeness, which FR-28 forbids.
  2. **`tests/canonical/test-guardrails-d012.sh` is green and *unmodified*.** It is D4 proof 2 --
     the standing pin on `kb.html`'s `S2` / `NM` behaviour and on the presence of those sections
     in the shared script. Confirm the file is byte-unchanged relative to the merge base of this
     work branch (not merely relative to `HEAD`, which is already this branch), and that its 35
     assertions pass. Confirm no file under `canonical/aid/scripts/summarize/` was modified by
     delivery-002, and that neither existing call site was edited --
     `grade-summary.sh`'s `bash "$SCRIPT_DIR/validate-html-output.sh" "$HTML"` and the CI
     `visual-fidelity` job's `validate-visuals.mjs <html>` (D4 proof 1).
  3. **The Playwright-absent path degrades to a `SKIP` with exit 0.** With Playwright not
     installed, `validate-visuals.mjs` prints
     `SKIP -- Playwright is not installed in this environment.` plus the
     `npx playwright install chromium` remediation and exits `0`. Confirm the run continues, that
     `V-T` therefore emits no ledger rows and cannot lower the Machine Grade, and that the
     closing summary records the escalation -- `G1` becomes the sole carrier of visual assurance
     for that run, so the grade is not read as stronger evidence than it is. Confirm the adjacent
     documented behaviours: an absent HTML file also SKIPs to exit 0, while a genuine visual
     failure exits 1 and is a generation defect rather than graceful degradation.
  4. **The Node floor is reported.** Confirm and record the floor now enforced on both sides
     after the on-branch fix: `summarize-preflight.sh` Check 5 guards `-lt 20`,
     `canonical/skills/aid-summarize/references/state-preflight.md` item 5 matches,
     `canonical/aid/scripts/summarize/package.json` declares `"engines": { "node": ">=20" }`, and
     feature-010's `graph-preflight.sh` P5 asserts the **same** floor rather than a higher one.
     Report the floor in the verification evidence; introduce no new floor and edit no preflight.
- **Evidence, not narrative.** Record the outcome as reviewer-ledger rows in
  `.aid/.temp/review-pending/` per the seven-column schema, and cite real command output for each
  of the four. Where a check cannot be exercised in this delivery, record it as such and name the
  delivery-004 task that closes it.
- Out of scope: **creating** `tests/canonical/test-validate-html-profiles.sh` (`VP01`-`VP06`) or
  `tests/canonical/test-validate-visuals-profiles.sh` (`VV01`-`VV04`) -- both are contingent and
  belong to tasks 077 and 085; any edit to `canonical/aid/scripts/summarize/*` -- feature-011
  owns every such edit and expects none; the `graph.html` trigger determination (task-075); and
  `grade-graph.sh` itself (task-029).
- Any script the verification adds must be discovered by the `tests/canonical/test-*.sh` glob
  with **no edit to `tests/run-all.sh`**, source `tests/lib/assert.sh`, use the
  `ID + description` label convention, and build its fixtures under `mktemp -d` (A-6).

**Acceptance Criteria:**

- [ ] Scope note recorded in the evidence: AC-17 does **not** fully close in delivery-002; the
      validator carve-outs are contingent and cannot be exercised until `graph.html` exists in
      delivery-004, so this task closes the **structural half only**, with tasks 075, 077 and 085
      named as the closers.
- [ ] A diff of `grade-graph.sh` against `grade-summary.sh` is recorded showing **no shared check
      body**; `COV`, `AUTO_POOL`, `WEIGHTS`, the 70-point pool, `KB_DIR=".aid/knowledge"` and
      `MANUAL_CHECKLIST_FILE` are each confirmed absent from `grade-graph.sh`.
- [ ] Every check `grade-graph.sh` performs is confirmed to be an invocation of an existing leaf
      validator (`validate-html-output.sh`, `contrast-check.mjs`, `validate-visuals.mjs`,
      `lint-frontmatter.sh`, `validate-relationships.sh`, `grade.sh`), with no reimplementation.
- [ ] `tests/canonical/test-guardrails-d012.sh` is confirmed **byte-unchanged** relative to this
      work branch's merge base, and its 35 assertions are confirmed passing.
- [ ] No file under `canonical/aid/scripts/summarize/` is modified by delivery-002, and both
      existing call sites (`grade-summary.sh`'s `validate-html-output.sh` invocation and the CI
      `visual-fidelity` job's `validate-visuals.mjs` invocation) are confirmed untouched.
- [ ] With Playwright absent, `validate-visuals.mjs` is confirmed to print its `SKIP` message
      with the `npx playwright install chromium` remediation and **exit 0**, and the graph run is
      confirmed to continue.
- [ ] `V-T` is confirmed to emit **no** ledger row on the SKIP path, so the Machine Grade is not
      lowered by an unrun check.
- [ ] The closing-summary escalation is confirmed present: with Playwright absent, `G1` is the
      sole carrier of visual assurance for that run.
- [ ] The absent-HTML SKIP-to-0 case and the genuine-visual-failure exit-1 case are both
      confirmed, and the difference between them is recorded.
- [ ] The Node floor of **>= 20** is reported, with all four sources confirmed in agreement
      (`summarize-preflight.sh` Check 5, `state-preflight.md` item 5, `package.json` `engines`,
      and `graph-preflight.sh` P5), and no new floor is introduced and no preflight edited.
- [ ] Findings are recorded as seven-column reviewer-ledger rows under
      `.aid/.temp/review-pending/`, each citing real command output; no narrative or summary
      section is added to the ledger.
- [ ] Neither `tests/canonical/test-validate-html-profiles.sh` nor
      `tests/canonical/test-validate-visuals-profiles.sh` is created by this task.
- [ ] **Tests are deterministic** -- the Playwright-absent case is driven by a controlled
      environment (an isolated `HOME` / `NODE_PATH` with no `playwright` resolvable) rather than
      by whatever the host happens to have installed; no network; repeated runs agree.
- [ ] **Clean setup/teardown** -- any fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-011 that is decidable in this delivery is
      covered**: **AC-17**'s structural half (reuse, not reimplementation) and the
      graceful-degradation criterion (C-5). The parameterisation criterion is recorded as
      contingent and not-yet-exercisable.
- [ ] `HOME="$(mktemp -d)" bash tests/run-all.sh` is green, and no existing suite regresses.
