# task-001: Close feature-001's acceptance criteria against the shipped vocabulary

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-001/STATE.md.
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

**Source:** feature-001-relation-vocabulary-research -> delivery-001 (Wave 1)

**Depends on:** -- (none)

**Scope:**
- **PROVISIONAL — the first step of this task is to establish its own size.** Build the
  AC-to-assertion map for feature-001's `AC-S1`..`AC-S6` over the already-shipped
  `canonical/aid/templates/graph/relation-vocabulary.yml` (57 entries across 14 categories,
  committed) and the assertions already live in
  `tests/canonical/test-graph-relationship-validator.sh` (121) and
  `tests/canonical/test-graph-schema-loader.sh` (211). Per-AC coverage was NOT established during
  Detail — reading six suites against six SPECs was outside that budget — so the map is genuine
  work, not a formality, and this task's true size is unknown until it exists.
- Then add ONLY the assertions the map shows missing, in the suite that already covers the
  subject: D2's eight-field vocabulary record, D3's `endpoint_kinds` re-keyed from prefixes to
  kinds, D4's five-plus-one inverse-pair properties, D5's fourteen-category set, D7's
  core-plus-project-extension merge, D8's stated coverage limit, D9's ten-column worked examples.
- Nothing is implemented here. The vocabulary file, the loader and the validator all exist and
  pass; this task closes the criteria over them and records where each is carried.

**Acceptance Criteria:**
- [ ] The AC-to-assertion map exists and names a live assertion id for every `AC-S` row; any row
      with no assertion is either filled here or raised against feature-001 with a reason, never
      left blank
- [ ] Every added assertion derives its expectation from `relation-vocabulary.yml` itself — no
      entry count, category count or pair count is written into the suite as a literal
- [ ] S1 honoured: one subject invocation per distinct input, declared in the suite header
- [ ] S2 honoured: output loaded once, then asserted with bash builtins — no per-assertion command
      substitution
- [ ] S3: a mutation case behind `--self-mutate` for every added assertion that could pass vacuously
- [ ] S5: mutation operates on a copy and the suite proves the working tree is untouched
- [ ] The suite's `# COVERS:` manifest is updated if the covered set changed, so
      `tests/canonical/select-suites.sh` still selects it for a vocabulary edit
- [ ] The suite passes, and its assertion total is read from the script's own summary line, not
      from grep over stdout
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass
