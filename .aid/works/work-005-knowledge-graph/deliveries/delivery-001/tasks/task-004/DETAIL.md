# task-004: Close feature-003's acceptance criteria over the ten-column schema and loaders

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-004/STATE.md.
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

**Source:** feature-003-relationship-table-schema -> delivery-001 (Wave 1)

**Depends on:** task-001

**Scope:**
- **PROVISIONAL — the first step is the AC-to-assertion map**, for the same reason as task-001:
  per-AC coverage of the two shipped suites was not established during Detail, so this task's size
  is unknown until the map exists.
- Map feature-003's acceptance criteria over `tests/canonical/test-graph-schema-loader.sh` (211)
  and `tests/canonical/test-graph-relationship-validator.sh` (121), against the delivered
  `canonical/aid/templates/graph/relationship-schema.yml`,
  `canonical/aid/scripts/graph/relationship-schema.sh` and
  `canonical/aid/scripts/graph/validate-relationships.sh` — all committed and passing.
- Coverage to close: D1's ten-column contract, D1a's `Kind` enum, D2's node-id grammars and
  resolution (one pair per `Kind`), D3's `Provenance` enum, D4's core-plus-extension vocabulary
  load, D5's display-name rule, D6's `Observation` cell, D7's row normalisation and ordering, D7a's
  `## Coverage notes` shape and byte-stability, D7b's class-0 row-block extraction, D8's emitted KB
  frontmatter, D9's loader library surface.
- **Depends on task-001 because this is BLUEPRINT edge 1** (feature-001 before feature-003): no row
  can be typed and no inverse pair validated without the vocabulary closed first.

**Acceptance Criteria:**
- [ ] The AC-to-assertion map exists and names a live assertion id per criterion; gaps are filled or
      raised, never left blank
- [ ] D7b's class-0 row-block extraction and D7's ordering are asserted against a self-built
      fixture, not against this repository's own Knowledge Base (FR-8a)
- [ ] The `ext:` branch of AC-1 is evidenced by the synthetic fixture Q4 already resolved to (A-6),
      with the production-completeness shortfall (`external-sources.md` carries no registered
      entries and no machine-readable entry shape) recorded rather than papered over
- [ ] S1, S2 and S4 honoured — S4 in particular: no coverage is traded for run time
- [ ] S3 mutation cases behind `--self-mutate` wherever an added assertion could be vacuous; S5
      proves the tree untouched
- [ ] `# COVERS:` manifests updated if the covered set changed
- [ ] Both suites pass; totals read from each script's own summary line
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass
