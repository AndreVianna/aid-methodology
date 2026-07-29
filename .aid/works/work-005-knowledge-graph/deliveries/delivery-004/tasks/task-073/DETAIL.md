# task-073: WCAG AA structural, contrast and keyboard/screen-reader verification

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
- Verify AC-9's table and structural half against the real generated
  `.aid/knowledge/graph.html`, using the reused validators unmodified:
  ```bash
  bash canonical/aid/scripts/summarize/validate-html-output.sh .aid/knowledge/graph.html --kb-dir .aid/knowledge
  node canonical/aid/scripts/summarize/contrast-check.mjs .aid/knowledge/graph.html
  ```
  covering **H1**, **A1**-**A5**, **L1** and **L2**, and **C1**/**C2** in both themes.
- Verify keyboard reach and screen-reader semantics against feature-009 § "Keyboard reach" and
  § "Screen-reader behaviour", and record the manual `accessibility-checklist.md` items
  feature-009 owns.
- Record every result as findings in `.aid/.temp/review-pending/` using the 7-column reviewer
  ledger schema.
- **Out of scope:** `S2` and `NM`, whose verdicts are the contingency determination of task-075;
  the reduced-motion clause of AC-9, owned by feature-008 in delivery-005 -- **AC-9 does not close
  in this delivery**; fixing any defect found (that is the owning IMPLEMENT task's work); editing
  any shared validator (feature-011 owns those edits, and only under a fired contingency).

**Acceptance Criteria:**
- [ ] `validate-html-output.sh` over the real `graph.html` reports **H1**, **A1**-**A5**, **L1**
      and **L2** as PASS, with the command and full output recorded as evidence.
- [ ] `contrast-check.mjs` over the same file passes **C1**/**C2** for both `light` and `dark`
      themes, and the script's pair list is **unchanged** -- no pair was added to make the graph
      pass.
- [ ] Keyboard reach verified in a real browser: the documented tab order is reachable in visual
      order (skip link, preset buttons, control panel, skip-past-table link, header sort buttons,
      filter inputs, row focus actions); `Enter` and `Space` operate every button; no table cell is
      a tab stop.
- [ ] 2.4.11 verified: after scroll-into-view, a focused element inside `<tbody>` is obscured by
      neither the sticky top bar nor the sticky column headers.
- [ ] Screen-reader semantics verified: the `<caption>` is read on table entry, `<th scope="col">`
      and `<th scope="row">` associations announce correctly, `aria-sort` is announced on exactly
      the sorted column, and a sort or filter produces **one** polite announcement -- with no
      row-level announcement flooding.
- [ ] The zero-row region announces as its own table with its own caption, and the
      "no recorded relationships" marker is read as part of the node's name.
- [ ] Each manual item feature-009 owns is recorded pass or fail: `<label for>` on every form
      control, no skipped heading levels, 44 × 44 px hit areas, and usability at 200 % zoom with
      horizontal scrolling confined to `.tbl-wrap`.
- [ ] Results are written to `.aid/.temp/review-pending/` in the 7-column schema
      (`# | Severity | Status | Doc | Line | Description | Evidence`), with no narrative sections.
- [ ] The gate record states explicitly that **AC-9 is satisfied on the table and structural side
      and does not close here** -- its reduced-motion clause is feature-008's, and AC-9 closes
      overall in delivery-005.
- [ ] **Tests are deterministic** (TEST default): the two validator invocations are re-runnable and
      produce the same verdicts on an unchanged artifact; the manual items are recorded with the
      browser and version used.
- [ ] **Clean setup/teardown** (TEST default): the verification writes nothing into
      `.aid/knowledge/` and leaves no temporary file behind.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
