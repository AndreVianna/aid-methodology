# task-074: Every artifact this work produced graded against the configured floor

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-074/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-073

**Scope:**
- Source: REQUIREMENTS **NFR-5** and `features/feature-006-integration-and-close-out/SPEC.md` §10 row
  *Grade floor*. It closes BLUEPRINT criterion **13** -- *"Every artifact this work produced meets the
  configured minimum grade (`A`)"* -- which is the last substantive criterion and the only one that
  spans all three deliveries rather than one.
- **It is the combined graph's leaf and it writes nothing.** Every artifact this work produced is
  final at this point: the thirty-six skills and their rows, the three canonical templates, the
  doctrine amendments, the two new Knowledge Base documents, the eight refreshed ones, the methodology
  narrative and its mirrors, the rendered profiles, the two dogfood trees, the site's generated skill
  surface, and the two regenerated summaries.
- **The oracle is `canonical/aid/scripts/grade.sh`**, run per artifact, and the configured minimum is
  read from the work's own configuration at run time rather than typed here -- REQUIREMENTS NFR-5 says
  *"the configured minimum grade (currently `A`)"*, and reading it means the criterion stays true if the
  floor moves.
- **The artifact set is derived, not listed.** Take it from the union of the three deliveries' committed
  paths -- `git diff --name-only master...HEAD` -- and partition it by artifact class, so a file no task
  claimed is visible as a residue rather than absent from a hand list. A list maintained here would
  drift from what the branch actually contains, which is the failure this derivation exists to prevent.
- **Two grades that are recorded rather than re-derived.** `kb.html`'s human V1 verdict is
  **orchestrator-run** and was recorded by task-071 in `.aid/knowledge/STATE.md` § Summarization History;
  this task cites that record and does not claim to have re-run a gate that cannot run automatically
  (Playwright is absent from the summarize package). And each delivery's own gate grade is written by
  `aid-execute`, not here -- this task feeds it, and must not write `gate_tier` or `gate_grade` into any
  `STATE.md`.
- **A grade below the floor is a finding, not a fix.** This task reports; the remedy is the delivery
  gate's, and a task that quietly re-authored an artifact to lift its grade would be doing the reviewer's
  job at the point where independence matters most.
- Out of scope: writing any `gate_tier`, `gate_grade` or `gate_timestamp` value; re-running the
  description sweep (task-072) or the pipeline sweep (task-073); regenerating any artifact; and grading
  the pipeline artifacts of this work's own folder (`REQUIREMENTS.md`, `PLAN.md`, the feature `SPEC.md`
  files, the task `DETAIL.md` files), which the phase gates already graded when they were written.

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 13 -- every artifact this work produced meets the configured minimum.**
      `canonical/aid/scripts/grade.sh` is run per artifact and every result is recorded as a triple:
      the artifact path, its grade, and the floor it was compared against. The floor is read from the
      work's configuration at run time and the read is recorded
- [ ] **The artifact set is derived from the branch, not from a list.**
      `git diff --name-only master...HEAD` is captured, partitioned by artifact class in the record, and
      every path is either graded, or explained as not a gradable artifact (a generated file, a lock or
      manifest, a baseline inventory), with the reason. A path in neither bucket is a residue and is
      reported as one
- [ ] **No grade is below the floor**, or every one that is, is reported as a finding with its artifact
      and its grade -- and the record states explicitly that the remedy belongs to the delivery gate,
      not to this task
- [ ] **`kb.html`'s human verdict is cited, not re-claimed.** The record quotes the
      `## Summarization History` row task-071 wrote, names the verdict as **orchestrator-run**, and
      states that `validate-visuals.mjs` was SKIPPED because Playwright is absent from the summarize
      package. A record that reports an automated visual pass fails this criterion
- [ ] **This task writes no gate value.** `git diff --exit-code --
      .aid/works/work-006-design-phase-skills/deliveries/*/STATE.md` is clean, and no
      `gate_tier`, `gate_grade` or `gate_timestamp` field anywhere was written by this task -- those
      belong to `aid-execute`'s delivery-gate step
- [ ] This task writes nothing at all: `git status --porcelain` over `canonical/`, `tests/`, `site/`,
      `docs/`, `.aid/`, `profiles/`, `.claude/` and `.cursor/` is **identical before and after**, and
      `git diff --cached --name-only` is empty
- [ ] Tests are deterministic and setup/teardown is clean -- `grade.sh` over committed content and a
      scoped `git diff`, so two executions produce identical outcomes and there is nothing to tear down
- [ ] All acceptance criteria from the source feature that this task covers are covered: feature-006's
      grade-floor criterion and its §10 *Grade floor* row, each recorded with the command that produced
      its result
- [ ] All section-6 quality gates pass
