# task-008: Make build-relationships.sh consume the coverage-notes hand-off

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

**Source:** feature-005-two-pass-extraction -> delivery-001 (Wave 1)

**Depends on:** task-007

**Scope:**
- **A shipped implementation defect, not a specification gap.** feature-010's SPEC (`:649`-`:653`,
  Open Item 7) and feature-005's step 15 agree: the assembler writes
  `.aid/.temp/graph/coverage-notes.md` and `build-relationships.sh` renders THAT. The SPECs agree
  with each other; the code disagrees with both.
- **The producer half already exists.** `canonical/aid/scripts/graph/assemble-coverage-notes.sh`
  references the hand-off path 9 times, `canonical/skills/aid-graph/references/state-emit.md` 3
  times and `state-fix.md` once.
- **The consumer half is missing.** `canonical/aid/scripts/graph/build-relationships.sh` references
  the path **zero** times and re-renders the section itself via `br_render_coverage()` (~`:806`).
- Fix it by making the renderer consume the hand-off: `br_render_coverage()` stops composing section
  content and instead reads the assembled file, preserving byte-stability. This is the whole scope —
  no other extraction behaviour changes.

**Acceptance Criteria:**
- [ ] `br_render_coverage()` no longer composes any `## Coverage notes` content of its own; the
      section's bytes come from `.aid/.temp/graph/coverage-notes.md`
- [ ] The emitted `## Coverage notes` section is byte-identical to the assembler's output
- [ ] An absent, empty or truncated hand-off is a **loud failure**, not a silent fall-back to
      self-rendering — the fall-back is exactly the defect being removed
- [ ] feature-010 D7 and feature-005 step 15 are both satisfied by the same code path, with no
      second renderer left behind
- [ ] AC-19 and AC-20 byte-stability preserved: two runs over one input produce identical bytes
- [ ] `grep -c coverage-notes canonical/aid/scripts/graph/build-relationships.sh` returns non-zero —
      the defect's own signature, inverted
- [ ] The extraction suite still passes before task-009 adds the new assertions
- [ ] All section-6 quality gates pass
