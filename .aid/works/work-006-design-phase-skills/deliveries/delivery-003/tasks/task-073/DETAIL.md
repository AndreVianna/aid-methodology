# task-073: The pipeline proved untouched -- three scoped diffs and the `phase:` grep

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-073/STATE.md.
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

**Depends on:** task-072

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §8b and its §10 *Pipeline untouched*
  row; REQUIREMENTS **C-1**, **NFR-3**, **FR-3** and **AC-9**. It closes BLUEPRINT criterion **12** --
  *"The pipeline is provably untouched: the `phase:` enum, the work/delivery/task hierarchy and the
  numbered sequence are unchanged in their defining files, **and** no new skill declares a `phase:`"*.
- **Three properties, each with its own oracle and its own scope**, run over the finished tree after
  every authoring task has landed. This task writes nothing.
- **The `phase:` enum (C-1).** `git diff master -- canonical/aid/templates/work-state-template.md` shows
  no change to the `phase:` line. C-1 names that file as the enum's definition, so it is the right
  target and the diff is scoped there rather than repo-wide.
- **The work/delivery/task hierarchy (NFR-3).**
  `git diff master -- .aid/knowledge/artifact-schemas.md` shows no change to the hierarchy definition.
- **The numbered sequence (NFR-3), which is the row most easily over-read.**
  `git diff master -- .aid/knowledge/pipeline-contracts.md CLAUDE.md AGENTS.md` is a **scoped** diff,
  never `git diff --exit-code`: task-066 edits `pipeline-contracts.md` on purpose, adding per-skill
  contracts for the thirty-six, so an exit-code oracle there would be unsatisfiable by construction.
  What is asserted is that the numbered Discover / Describe / Define / Specify / Plan / Detail /
  Execute sequence is unchanged inside each of the three files. **Read that sequence out of each
  file; do not retype it** -- and note that the three files do **not** agree on how they write it, so
  one hand-typed pattern cannot match all three and would pass vacuously wherever it missed.
  `CLAUDE.md:74` and `AGENTS.md:74` separate the phases with **U+2192** (`→`) and name seven phases;
  `.aid/knowledge/pipeline-contracts.md:450-451` uses **ASCII `->`** and states *"six numbered
  phases"*, collapsing Describe/Define into a single `Describe/Define (Phase 2a/2b)` step. Both
  renderings are correct for their own file -- the phase set is the same, the presentation is not --
  so the oracle is a per-file extraction, never one shared pattern.
  **Both** `CLAUDE.md` and `AGENTS.md` are named because the
  numbered sequence is stated in both agent-context files, and checking one and not the other has been a
  live drift source.
- **The half that matters most, and the one a diff cannot cover: no new skill *joined* the spine.** The
  diffs prove nobody edited it; the grep proves nobody joined it, which is the actual risk. The positive
  control is that the grep returns nothing today, because no shipped shortcut skill declares a `phase:`
  either.
- **The grep's scope is the thirty-six, derived from disk rather than typed as a brace expansion.** A
  hand-written pattern like `aid-{design,create,update}-*` is easy to get wrong by one name and silently
  passes when it misses a directory. Derive the thirty-six names by `comm`-ing the live catalog row names
  against `git show master:canonical/aid/templates/shortcut-catalog.yml`'s, then grep each one's
  `SKILL.md`. The derivation is the oracle for the scope; the grep is the oracle for the property.
- **This sweep exists because the work adds thirty-six skills to a methodology whose seven-step spine is
  a closed enum.** The risk it guards is a skill quietly presenting itself as a phase -- which is exactly
  what FR-3 forbids and what the on-demand shape (`work-NNN` folder, `STATE.md`, review gate) exists to
  satisfy instead.
- Out of scope: fixing anything -- a finding here is reported; the description sweep (task-072); the
  grade floor (task-074); and any write at all.

**Acceptance Criteria:**
- [ ] Every row named in Scope is run and its outcome recorded **with the command that produced it** --
      no row is reported as covered without its oracle and result (TEST default: all acceptance criteria
      from the source feature covered)
- [ ] **BLUEPRINT criterion 12, property 1 -- the `phase:` enum.**
      `git diff master -- canonical/aid/templates/work-state-template.md` shows **no change to the
      `phase:` line**, and the line's current text is quoted in the record so the reader can see what was
      compared. `git diff master`, not `--exit-code`, which compares the working tree to `HEAD` and
      passes trivially once an edit is committed
- [ ] **Property 2 -- the work/delivery/task hierarchy.**
      `git diff master -- .aid/knowledge/artifact-schemas.md` shows no change to the hierarchy
      definition, with the compared region named
- [ ] **Property 3 -- the numbered sequence, in all three files.** For each of
      `.aid/knowledge/pipeline-contracts.md`, `CLAUDE.md` and `AGENTS.md`, the numbered sequence
      Discover / Describe / Define / Specify / Plan / Detail / Execute is present and unchanged.
      **Extract the sequence from each file separately; never reuse one pattern across the three**
      -- `CLAUDE.md` and `AGENTS.md` use U+2192 (`→`) and seven phases, `pipeline-contracts.md` uses
      ASCII `->` and writes it as six with `Describe/Define (Phase 2a/2b)` merged. Record the literal
      text compared for each file, so the reader can see that a per-file difference in rendering was
      not mistaken for a change in the phase set. Present and unchanged
      against `git show master:<file>`. Recorded per file, all three, because checking one and not the
      other has been a live drift source. The diff is **scoped to the sequence**, and the record states
      that `pipeline-contracts.md` was legitimately edited by task-066 -- so a whole-file exit-code
      oracle would be unsatisfiable and is not used
- [ ] **The clause a diff cannot cover -- no new skill declares a `phase:`.** The thirty-six names are
      derived by `comm -3` over the live catalog row names and
      `git show master:canonical/aid/templates/shortcut-catalog.yml`'s, the derived list is recorded and
      its length captured to a variable -> `36`, and `grep -l 'phase:'` over those thirty-six
      `canonical/skills/<name>/SKILL.md` files returns **nothing**
- [ ] **The positive control is run and recorded.** The same grep over a sample of shipped
      pre-existing shortcut skills also returns nothing, which is what makes the empty result above
      evidence rather than a vacuous pass
- [ ] **No new `phase:` value appears anywhere the enum is consumed**, which is the coordinated change
      C-1 exists to prevent: `git diff master --` is scoped-clean on
      `canonical/aid/templates/work-state-template.md` and `.aid/knowledge/artifact-schemas.md`, and no
      dashboard reader twin was edited by this work at all -- recorded by naming both twins and showing
      their diff is empty
- [ ] This task writes nothing: `git status --porcelain` over `canonical/`, `tests/`, `site/`, `docs/`,
      `.aid/`, `profiles/`, `.claude/` and `.cursor/` is **identical before and after**, and
      `git diff --cached --name-only` is empty
- [ ] Tests are deterministic and setup/teardown is clean -- every row is a scoped `git diff`, a `comm`
      or a `grep` over committed content, so two executions produce identical outcomes and there is
      nothing to tear down
- [ ] All section-6 quality gates pass
