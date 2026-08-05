# task-020: feature-011's PV suite and the kb.html default-path proof

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-020/STATE.md.
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

**Source:** feature-011-validator-parameterisation -> delivery-001 (Wave 3)

> **RECORDED DEVIATION — this task and `task-019` are ONE COMMIT.** feature-011's SPEC `:453–:455`
> requires the suite to land in the same change as the amendment ("a plan that schedules them apart
> should be rejected"), because an amended validator without its assertions is the unproven carve-out
> D5 exists to prevent. The split into two tasks exists only because a task carries exactly one Type
> and an amendment cannot share one with its suite. The SPEC's intent is preserved by committing them
> together: this task depends on `task-019`, both sit in gate wave 3, and **neither may be committed
> without the other.** The task boundary is a review boundary, not a commit boundary. The same note
> is recorded on `task-019` so whichever is picked up first sees it.

**Depends on:** task-019

**Scope:**
- The `PV*` series for the parameterisation contract: `PV03`'s stale-copy detectability (a copy
  predating the flag would silently ignore it and validate the wrong pair set — the printed profile
  line is what makes the mismatch observable), `PV11`'s re-taken contrast baseline asserted by
  substance, `PV19`'s recorded degradation, the exit-2 usage path, and D1's six properties.
- D5's proof that `kb.html` is unchanged: byte-identity on the default path except the one named
  contrast exception.

**Acceptance Criteria:**
- [ ] Byte-identity of default-path output proven for all three scripts, with the single named
      contrast exception isolated and its substance asserted instead of its bytes
- [ ] `grade-summary.sh`'s grepped tokens — `S2`, `NM`, `L1`, `L2`, `C1`, `C2` — verified stable, since
      a wording change moves a grade without moving a verdict
- [ ] `tests/canonical/test-contrast-check.sh` and `tests/canonical/test-guardrails-d012.sh` still
      pass; any change to either is deliberate, argued, and named
- [ ] The zero-sized-input-set case is asserted for every reused check whose input set can be empty —
      a pass over nothing is the failure mode this criterion exists for
- [ ] `PV03` fails against a pre-parameterisation copy of each script; an assertion that passes both
      before and after is asserting nothing
- [ ] A `# COVERS:` manifest naming all three summarize scripts, so `select-suites.sh` selects this
      suite when any of them changes
- [ ] S1, S2, S4 honoured; S3 mutation cases behind `--self-mutate`; S5 proves the tree untouched
- [ ] Suite passes; total read from the script's own summary line
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass
