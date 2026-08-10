# task-002: `design-seed.md` -- the anchorable seed-shape template

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-002/STATE.md.
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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-001

**Scope:**
- Source spec: `features/feature-002-design-lifecycle-machinery/SPEC.md` §1a, §4 (AC-8).
  Ordered per feature-002 §8's internal order -- §2 (the folder) then §4 (the seed shape)
  then §3 (the contract) -- and kept inside feature-002's contiguous commit block.
- Author `canonical/aid/templates/design-seed.md` at the **root** of
  `canonical/aid/templates/`, not under its `knowledge-base/` subtree. The placement is
  count-neutral: every templates enumeration on disk binds the `knowledge-base/`
  subdirectory, and the one out-of-subdirectory assertion (`AS08`) is bound to
  `feature-inventory.md` by name, not by glob (§1a).
- The six level-2 headings, literal text and order fixed by §4's table: `## Problem`,
  `## Options considered`, `## Current direction`, `## Constraints`, `## Open questions`,
  `## Destination`. Fixed rather than indicative for two stated reasons -- the readiness
  detection rule is a machine check anchored on the literal string `## Open questions`,
  and three independent consumers read this one file shape (the 22 `design`-stage writers,
  feature-005's engine read at CAPTURE Step 2, and feature-005's two hand-authored
  `document` bodies).
- `## Destination` is marked **optional**, omitted by an artifact-less writer whose
  destination is undecided.
- Unfilled content is written as brace-delimited placeholders per §4's placeholder
  convention -- the convention already used across `canonical/aid/templates/`.
- **No `changelog:` field and no `## Change Log` section** (§4): `## Current direction` is
  rewritten each iteration, so a changelog would be a lower-fidelity duplicate of git, and
  no Knowledge-Base-adjacent artifact in the repo carries the apparatus.
- Out of scope: the seed **naming** rule, the readiness gate, its detection rule and the
  `## Destination`-optional *binding* -- those are contract rules and land in
  `design-lifecycle.md` (task-003). This task ships only the file shape they anchor on.
  The file is **frozen once feature-005 starts** (§6), so any later change is a
  delivery-002 amendment, not a delivery-001 edit.

**Acceptance Criteria:**
- [ ] §7 D3: `grep -c '^## '` on the template captured to a variable -> `6`, and the six
      headings match §4's table byte for byte and in the table's order
- [ ] `grep -cE '\{(project_context_file|reviewer_output_file|open_questions_file)\}'` over
      the template -> `0`. `{open_questions_file}` is a real collision hazard given the
      `## Open questions` heading: `substitute_filenames` would ship a resolved filename
      where a placeholder belongs and the detection rule's unfilled-placeholder clause
      would misfire (§4)
- [ ] `grep -cE '^## Change Log|^changelog:'` over the template -> `0`
- [ ] Every placeholder in the shipped template is a line consisting wholly of a single
      brace-delimited span, so §4's detection rule classifies the shipped template's
      `## Open questions` as unfilled rather than non-empty
- [ ] The file lands at the templates-tree **root**, not under `knowledge-base/`:
      `test -f canonical/aid/templates/design-seed.md` succeeds and
      `test -f canonical/aid/templates/knowledge-base/design-seed.md` fails
- [ ] `ls canonical/aid/templates/knowledge-base/ | wc -l` still returns `14` -- unchanged
      by this task and by the delivery (§1a; feature-001 AC-3's seed-immobility premise).
      **No assertion is made here on the root directory's own entry count**: the baseline is
      41 today and two sibling tasks in the same commit block (task-001 and task-003) add to
      the same directory, so a "rises by one" form is ambiguous depending on when it is
      evaluated. The three-file total is asserted once, at the range level, by task-005's
      §7 G3 (exactly three `A` entries)
- [ ] No test script under `tests/canonical/` or `site/scripts/__tests__/` is edited:
      `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
