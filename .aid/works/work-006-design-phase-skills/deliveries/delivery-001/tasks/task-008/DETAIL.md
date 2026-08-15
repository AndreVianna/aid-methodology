# task-008: Filename-to-spine-dimension arms for the three documents in both KB script twins

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-008/STATE.md.
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

**Type:** IMPLEMENT

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-007

**Scope:**
- Source spec: `features/feature-001-kb-doc-set-restructure/SPEC.md` §1b surface 4, AC-10;
  REQUIREMENTS CC-4. The fourth and last registration surface this task owns.
- Add three arms to `_dim_of_filename` -- `roadmap.md` -> `D`, `backlog.md` -> `C7`,
  `release-tracking.md` -> `C8` -- in **both** twins:
  `canonical/aid/scripts/kb/kb-actback-task.sh` (which sets `_DIM`) and
  `canonical/aid/scripts/kb/kb-dual-intent-probes.sh` (which sets `_DIM_OUT`). Both carry a
  *"Do not edit independently of domain-doc-matrix.md"* banner; the twins must not diverge,
  and the arms must match the spine dimensions task-007 wrote into the matrix.
- Without these arms all three documents fall through the catch-all (`_DIM=""` /
  `_DIM_OUT=""`) and contribute no owning-table rows to the presence check.
- **Record the downstream effect this deliberately turns on**: once the C7 arm resolves,
  `_dim_owns_class(C7, Gotchas)` returns true and the operational-structure presence check
  emits `| backlog.md | Gotchas | absent |` on every run until the section exists -- the
  check reports for *expected* classes whether or not the doc is on disk. That is why
  `backlog.md`'s shape carries a required `## Gotchas` section (feature-003 §3b, task-012),
  and why this task precedes it.
- Out of scope: any test script (feature-001 AC-3 -- the seed does not move);
  `synth_default_seed`'s ownership map (AC-4 -- none of the three enters it); and
  `.aid/settings.yml`'s `doc_set` presence values, which are runtime writes by the `create`
  skills (CC-1, CC-2) and, for `release-tracking.md`, already correct.

**Acceptance Criteria:**
- [ ] AC-10 oracle: the extract-and-eval loop the SPEC prints -- extract `_dim_of_filename`
      from each twin with `awk` and evaluate it, since the function is not exported, neither
      twin echoes, and both invoke `_main` at load -- prints six lines,
      `roadmap.md -> D`, `backlog.md -> C7`, `release-tracking.md -> C8`, **identical across
      the two twins**. All three return an empty dimension today, so the oracle fails now and
      is satisfiable only by this edit
- [ ] The two extracted functions remain equivalent: a diff of them shows only the
      pre-existing output-global difference (`_DIM` vs `_DIM_OUT`), with no divergence in the
      arm set
- [ ] AC-4 oracle: the anchor-scoped `awk` + `grep -c` over the two ownership-map regions of
      `doc-set-resolve.md` still returns `0` for all three filenames (the same extractor
      returns `2` for `tech-debt.md`, which is what proves it selects both regions)
- [ ] **No unit test is added for the new arms, and that is deliberate, not an omission.**
      The ground is feature-001 **AC-3** alone, which makes *"no test script is edited"* the
      criterion -- and adding an assertion means editing one. It is **not** the
      `coverage-parity` re-bootstrap: this delivery already mints roughly 36 new assertion ids
      without touching a script, because `test-catalog-dirs-parity.sh:126-141` mints four ids
      per catalog row and tasks 010-014 add nine rows, so the CI re-bootstrap is already
      scheduled in delivery-003 either way (PLAN § Cross-Cutting Risks, risk 1) and declining
      a test buys nothing. The AC-10 extract-and-eval loop is the oracle that stands in place
      of a unit test (feature-001 §5 row 6), and this task -- the delivery's only IMPLEMENT
      task -- ships its two edited scripts behind that oracle rather than behind a new
      assertion id
- [ ] All existing tests still pass and the build passes:
      `test-doc-set-read.sh`, `test-doc-set-mapping.sh` and `test-spine-depth-coverage.sh`
      green **unmodified**, and `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/`
      clean
- [ ] Counts read from each script's own summary line, never from grep over stdout
- [ ] All section-6 quality gates pass
