# task-012: Close feature-006's acceptance criteria over the Knowledge-Base gap ledger

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-012/STATE.md.
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

**Source:** feature-006-kb-gap-ledger -> delivery-001 (Wave 1)

**Depends on:** task-005, task-007

**Scope:**
- **PROVISIONAL — the first step is the AC-to-assertion map** over
  `tests/canonical/test-graph-gap-ledger.sh` (303 assertions, committed and passing), against the
  delivered `canonical/aid/scripts/graph/detect-kb-gaps.mjs`,
  `canonical/aid/scripts/graph/coverage-predicate.mjs` and
  `canonical/aid/templates/graph/coverage-bearing.yml`.
- Coverage to close: D1/D1a's inputs and the `nodes.tsv` field map; D2's single-implementation
  coverage predicate and D2a's `COVERAGE_BEARING` selection; D3's false-gap classes; D4's severity
  derived from the significance qualifier; D5's ledger row; D6's AC-15 carrier in two runtimes and
  D6a's lens/ledger asymmetry; D7's two ledger scopes and the D-6 shortfall.
- Records the **AC-15 ledger half explicitly as one half**. The delivery gate requires both halves
  evidenced, and the other halves are task-014's (shell) and task-018's (canvas).
- **Depends on task-005 and task-007 because this is BLUEPRINT edge 3** — features 004 and 005
  before feature-006: the ledger runs over the enumerated node set.

**Acceptance Criteria:**
- [ ] The AC-to-assertion map exists and names a live assertion id per criterion; gaps filled or
      raised
- [ ] D2's predicate proven to be ONE implementation: the `.mjs` module the ledger uses is the same
      file the page inlines, asserted by content identity rather than by comment
- [ ] D3's false-gap classes each exercised, with a case per class that would be misreported if the
      class were dropped
- [ ] D4's severity mapping asserted for every significance qualifier the enum admits
- [ ] The FR-26 retention split asserted **as the SPECs actually state it today**: `graph-kb-gaps.md`
      is **never graded** AND is **NOT retained past skill DONE** -- it follows the standard schema
      lifecycle and is deleted at DONE until D-6 lands (feature-006 `:777`, and `GL18` at `:1130`
      requires the routing block to say so).
      **CORRECTED 2026-08-05 during execution; the earlier wording was false and this note stays so it
      is not "fixed" back.** It read "is retained and never graded (feature-006 D7)". The *never
      graded* half was right; *retained* was a claim from feature-010's **superseded 2026-07-28
      pre-decision draft**, which feature-010 itself withdrew when it was re-authored fresh on
      2026-07-30 (its `:606`-`:607` records the correction, and `:632` states the replacement
      explicitly as "a weaker guarantee than retained, and calling it that is the point"). So the
      criterion asserted a withdrawn claim *while citing the SPEC that refutes it*. Found by this
      task's executor, which declined to encode a false assertion -- the right call.
      **Related, and already discharged rather than owed:** feature-006's Open Item 3 (`:1209`-`:1212`)
      still flags feature-010 as making that retention claim at "its SPEC.md:497-498". Those lines are
      the grading rubric today; the citation points into the superseded draft. Both SPECs now agree, so
      the Open Item needs closing, not answering. Routed to `task-026`'s KB/SPEC pass, not fixed here
- [ ] The external `reviewer-ledger-schema.md` retention carve-out is recorded as **unsatisfied and
      out of this work's scope** (Cross-Cutting Risk 1), not assumed present
- [ ] The AC-15 ledger half is labelled a half, naming feature-007 and feature-008 as co-owners
- [ ] S1, S2, S4 honoured; S3 mutation cases behind `--self-mutate`; S5 proves the tree untouched
- [ ] `# COVERS:` manifest updated if the covered set changed; suite passes; total read from the
      script's own summary line
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass
