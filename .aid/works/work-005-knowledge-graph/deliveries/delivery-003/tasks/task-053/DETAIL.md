# task-053: `test-graph-gap-ledger.sh` agreement and lifecycle assertions

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

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** task-052

**Scope:**
- Add **`GL08`-`GL11`** to the existing `tests/canonical/test-graph-gap-ledger.sh`, created by
  task-052.
- **This task writes to the same suite file as task-052**, which is why it depends on it and why it
  **must not disturb task-052's assertions**. `GL01`-`GL07`, `GL12` and `GL13` must still be present
  and still pass after this change; the fixture builder is extended, never rewritten, and no
  existing assertion is moved or renumbered.
- **`GL08` and `GL11` are why this task exists.** feature-006's SPEC names them as **the two
  assertions that would fail if a future change filtered by row instead of by file**, or wrote a
  `Status` value outside the schema's enum. That regression is precisely what would re-conflate the
  graded ledger (`graph.md`) with the delivered one (`graph-kb-gaps.md`) and undo FR-25's structural
  separation. Record that reason as a comment beside the two assertions, so a later editor cannot
  weaken them without reading why they are there.
- `GL09` closes **AC-15's ledger side only**. AC-15 is a mutual obligation shared with feature-007
  (delivery-004) and feature-008 (delivery-005), and closes overall in delivery-005 at task-089.
  `GL10` is what proves the `Status` transitions survive across runs; without it a retained findings
  ledger silently rots.
- Out of scope: `GL01`-`GL07`, `GL12` and `GL13` (task-052); `GV01` (task-054); the view side of
  AC-15 (task-071, delivery-004) and its graph side (task-089, delivery-005).

**Acceptance Criteria:**
- [ ] **`GL08`** -- `grade.sh` over `.aid/.temp/review-pending/graph.md` returns `A+` while
      `graph-kb-gaps.md` holds `[HIGH]` rows, proving the gap rows are invisible to the gate because
      `grade.sh` is never given that path.
- [ ] **`GL09`** -- three sets are asserted equal over the fixture: the `kb_gaps` id list in
      `relationships.md` frontmatter, the ledger's `Doc` column, and an in-test call to
      `detectKbGaps` over the fixture's **full node inventory** plus its table; and `kbUnbacked` ids
      from that same fixture appear in **neither** `kb_gaps` nor the ledger, confirming the
      lens-only scope.
- [ ] **`GL10`** -- re-running against a previous ledger moves a now-covered row to `Fixed` and a
      re-broken row to `Recurred`, renumbers nothing, and leaves every existing `#`, `Severity` and
      `Description` cell byte-unchanged.
- [ ] **`GL11`** -- `grade.sh` over a ledger whose rows are all `Fixed` returns `A+`, confirming the
      `Status` enum is written in the form `grade.sh` actually counts.
- [ ] A comment beside `GL08` and `GL11` records that these two are feature-006's named tripwire for
      a future change that filters by row instead of by file, or that writes a `Status` value outside
      the enum.
- [ ] **`GL01`-`GL07`, `GL12` and `GL13` are undisturbed:** the whole suite is run after this change
      and every task-052 assertion is still present, still identified by the same `GL` id, and still
      reporting the same result.
- [ ] Each new assertion is separately identified by its `GL` id in the suite's output.
- [ ] Tests are deterministic (TEST default): no timing dependency, no external state leak, and no
      dependence on the host repository's own Knowledge Base or ledger directory -- the fixture is
      still self-built under `mktemp -d` and depends on no work folder (A-6).
- [ ] Clean setup and teardown (TEST default), including on failure.
- [ ] Source-feature acceptance criteria covered (TEST default): between tasks 052 and 053 the suite
      now covers AC-14, FR-25's structural separation, and **AC-15's ledger side**. The suite records
      explicitly that **AC-15 does not close here** -- its view side is feature-007 in delivery-004
      and its graph side feature-008 in delivery-005, and neither owner may consider it met alone.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
