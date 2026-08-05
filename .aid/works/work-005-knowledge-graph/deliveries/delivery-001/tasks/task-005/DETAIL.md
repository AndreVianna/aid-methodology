# task-005: Close feature-004's acceptance criteria over source, media and external enumeration

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-005/STATE.md.
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

**Source:** feature-004-source-enumeration -> delivery-001 (Wave 1)

**Depends on:** -- (none)

**Scope:**
- **PROVISIONAL — the first step is the AC-to-assertion map** over
  `tests/canonical/test-graph-source-enumeration.sh` (189 assertions, committed and passing),
  against the delivered `canonical/aid/scripts/graph/scan-source.sh` and
  `canonical/aid/scripts/graph/significance-rules.sh`. Size is unknown until the map exists.
- Coverage to close: D1's `source-artifact` record and D1a's `image`/`web-page` records; D2's
  `artifact_class` enum and D2a's kind-classification-precedes-significance partition rule; D3's
  derivable-evidence rule (FR-24, the highest-risk requirement), D3b's byte-fixed evidence-string
  templates and D3a's total `qualifier` carrier map with its stated precedence; D4's exclusion
  filter; D4a's three ignore-list availability states and their single probe; D5's observation
  record; D6's candidate record; D7's coverage-note content.
- The reader half of `graph.ignore` is already built and needs asserting, not writing:
  `scan-source.sh:152` resolves it with `--default ''`, `scan-source.sh:171` prints the
  ignore-list-unavailable notice, and `significance-rules.sh:722` runs the `--probe`. Declaring the
  settings section is task-006's job, not this one's.

**Acceptance Criteria:**
- [ ] The AC-to-assertion map exists and names a live assertion id per criterion; gaps filled or
      raised
- [ ] D3b's evidence-string templates asserted **to the byte**, one case per carrier
- [ ] D3a's qualifier map asserted as **total** — every carrier value reaches a rule — and the
      stated precedence exercised where two rules could both apply
- [ ] D4a's three states each exercised: declared, absent (the `scan-source.sh:171` notice fires),
      and unreadable — with the absent case proving enumeration DEGRADES to "no ignore list" rather
      than failing, so the blast radius stays completeness and never correctness
- [ ] D2a asserted in the order the rule states: kind classification strictly before significance
- [ ] S1, S2 and S4 honoured; S3 mutation cases behind `--self-mutate`; S5 proves the tree untouched
- [ ] `# COVERS:` manifest updated if the covered set changed
- [ ] Suite passes; total read from the script's own summary line
- [ ] All section-6 quality gates pass
