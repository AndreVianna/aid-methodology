# task-007: Close feature-005's acceptance criteria over the two extraction passes

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-007/STATE.md.
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

**Source:** feature-005-two-pass-extraction -> delivery-001 (Wave 1)

**Depends on:** task-001, task-004

**Scope:**
- **PROVISIONAL — the first step is the AC-to-assertion map** over
  `tests/canonical/test-graph-extraction.sh` (196 assertions, committed and passing), against the
  delivered `canonical/aid/scripts/graph/harvest-declared.sh`,
  `canonical/aid/scripts/graph/derive-edges.sh` and
  `canonical/aid/scripts/graph/build-relationships.sh`.
- Coverage to close: D1's eleven-field / ten-column row record; D2's Pass 1a and the four node kinds
  it emits (FR-30); D3's vocabulary and edge-relation map; D4's carriers and where each is
  harvested; D5's provenance rule; D6's Pass 2 and FR-31a's four-part bound made mechanical; D7's
  coverage-note content and the `fact` carrier decision; D8's W3 producer-satisfiability map.
- **This is the suite most likely to have real gaps.** The coverage-notes hand-off defect that
  task-008 fixes proves the extraction spine was never asserted end to end — a renderer that
  references the hand-off path zero times passed 196 assertions. Treat the map as a hunt, not a
  formality.
- **Depends on task-001 because this is BLUEPRINT edge 1** (feature-001 before feature-005), and on
  task-004 because Pass 2 emits rows in the schema feature-003 owns.

**Acceptance Criteria:**
- [ ] The AC-to-assertion map exists and names a live assertion id per criterion; gaps filled or
      raised against feature-005 with a reason
- [ ] FR-31a's four-part bound asserted part by part, with a case that would fail if any one part
      were dropped
- [ ] D5's provenance rule asserted for every provenance value the enum admits
- [ ] Fixtures are self-built; no assertion depends on this repository's own Knowledge Base (FR-8a)
- [ ] S1 and S2 honoured — **and this is the 783s suite, so any added cost must come from
      de-spawning, never from S4's forbidden trade of coverage for time**
- [ ] S3 mutation cases behind `--self-mutate`; S5 proves the tree untouched
- [ ] `# COVERS:` manifest updated if the covered set changed
- [ ] Suite passes; total read from the script's own summary line, not from grep over stdout
- [ ] All section-6 quality gates pass
