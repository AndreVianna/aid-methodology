# task-089: AC-15 closure: Coverage-lens graph highlighting equals the ledger

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

**Source:** work-005-knowledge-graph -> delivery-005

**Depends on:** task-053, task-071, task-086

**Scope:**
- **This task closes AC-15 overall, and it has three contributing owners.** feature-006 owns the
  criterion, and its ledger side landed in delivery-003 **task-053** (`GL09`'s three-set
  agreement: the `kb_gaps` id list, the ledger `Doc` column, and an in-test `detectKbGaps` call
  over the fixture's full node inventory). feature-007 owns the view side, verified in
  delivery-004 **task-071** (`GV06`'s wrong-`kb_gaps` reporting with both renderings still
  mounting, and `GV07`'s full zero-row contract). feature-008 owns the graph side, verified here.
  All three SPECs state that **no owner may consider the criterion met alone**, so this task
  verifies **all three** contributions together and records AC-15 as closed only when all three
  hold.
- **The graph side.** With the Coverage lens applied to the rendered `.aid/knowledge/graph.html`,
  the graph highlights **exactly** the gaps the ledger records: the set of nodes drawn with the
  `int-undocumented` emphasis equals the ledger's `int:` gap rows, and equals
  `viewModel.coverageGaps.intUndocumented`.
- **The equality binds the `int:` class only.** `kb-unbacked` nodes -- `kind: 'kb'` with no edge
  to an `int:` node -- are a **lens-only** signal: computed in the browser, never written to
  `kb_gaps`, never a ledger row, and never compared against one. The Coverage lens still surfaces
  them because FR-13 says so, and the two classes are labelled distinctly on both surfaces
  (`no source` versus `no KB doc`) so a reader can tell which has a ledger counterpart. Their
  absence from the ledger is correct, not a mismatch.
- **Zero-row nodes are an expected asymmetry, never a mismatch.** `orphans = G \ T` reach the page
  through `kb_gaps` and are highlighted by the same code path as every other gap; `ledgerOnly` is
  defined as `(G ∩ T) \ R` precisely so a node the view could never have found is not counted
  against it. No integrity alarm may fire on one.
- **The density exemption under the lens.** At density level 5 with the Coverage lens applied,
  every `viewModel.coverageGaps` member is still drawn (task-082's explicit exemption), so
  thinning cannot hide a gap. This is the concrete mechanism behind feature-008's half of AC-15.
- **Out of scope:** authoring or amending the ledger and its detector (feature-006, delivery-003);
  the view's load-time verification and its loud-failure callout (feature-007, delivery-004) --
  both are read back here, not rebuilt; and any fix to `graph-canvas.js`, which belongs to
  tasks 079-082.

**Acceptance Criteria:**
- [ ] Tests are deterministic: the same ledger and the same rendered artifact yield the same
      result on every run.
- [ ] Clean setup and teardown: any working directory is created under `mktemp -d` and removed,
      and the run modifies neither the ledger nor `graph.html`.
- [ ] With the Coverage lens applied, the set of graph-highlighted `int-undocumented` node ids
      equals the ledger's `int:` gap rows exactly -- no member is missing on either side, and a
      difference is reported with the offending ids named.
- [ ] That same set equals `viewModel.coverageGaps.intUndocumented`, so the graph and the peer
      table highlight the same nodes.
- [ ] `kb-unbacked` ids appear in the graph's Coverage lens but in **neither** `kb_gaps` nor the
      ledger, and their absence is **not** treated as a mismatch.
- [ ] The two classes are distinguishable on the graph by their non-colour carriers -- `no source`
      for `kb-unbacked`, `no KB doc` for `int-undocumented`.
- [ ] A zero-row node recorded in `kb_gaps` is highlighted by the lens and triggers no mismatch
      alarm.
- [ ] At density level 5 under the Coverage lens, every `coverageGaps` member is still drawn.
- [ ] **All three co-owner contributions are verified in this run:** task-053's `GL09` ledger-side
      agreement, task-071's `GV06` / `GV07` view-side contract, and the graph-side equality above.
      AC-15 is recorded as closed **only** if all three hold; a pass on the graph side alone is
      recorded as not-closed.
- [ ] All acceptance criteria from feature-008's AC-15 graph side are covered by this suite.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
