# task-012: Consuming-op round-trips + model-field parity

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
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

**Source:** feature-002-project-header-edit, feature-005-display-rename, feature-006-task-notes -> delivery-001

**Depends on:** task-005, task-006, task-008, task-009, task-010

**Scope:**
- End-to-end tests for the consuming interactions -- `settings.set` / `pipeline.rename` / `task.rename` / `task.set-notes` write -> re-render round-trips -- plus twin byte-parity for the new model fields (`display_name`, `project_description`, `minimum_grade`) with regenerated fixtures. Tests only -- no production code.
- Op round-trips (per op): `settings.set` (name/description/grade) -> `write-setting.sh` -> `.aid/settings.yml` mutated -> re-fetched `./api/model` shows the new value; `pipeline.rename` -> `write-requirement.sh` -> `REQUIREMENTS.md **Name:**` -> title renders (folder-slug fallback when cleared); `task.rename` -> `writeback-state.sh --field Name` -> `display_name` cell (nested frontmatter AND flat `### Tasks lifecycle` row) -> precedence render; `task.set-notes` -> `writeback-state.sh --field Notes` -> notes cell -> card re-render.
- Empty-value clear semantics: `task.rename` / `task.set-notes` empty -> `--` sentinel -> fallback render; `pipeline.rename` empty -> pending placeholder -> slug fallback.
- Model-field parity: assert `project_description` + `minimum_grade` (RepoInfo) and `display_name` (TaskModel) are present and byte-identical across the `server.py` / `server.mjs` serializers, with fixtures regenerated in lockstep; extend the reader + server parity suites.
- Regression fixtures (this TEST task authors them): a KI-001 read-side round-trip fixture for the settings scalars, pinning task-005's DM-1 parser to match `_read_settings`/`readSettings`; a legacy 5-column `### Tasks lifecycle` row yielding `display_name None` (fallback).

**Acceptance Criteria:**
- [ ] Each consuming op has a write -> re-render round-trip test: `settings.set` mutates `.aid/settings.yml` and the re-fetched `./api/model` shows the new name/description/grade; `pipeline.rename` mutates `REQUIREMENTS.md **Name:**` and renders the new title (slug fallback when cleared); `task.rename` mutates the `display_name` cell (both layouts) and renders per precedence; `task.set-notes` mutates the notes cell and re-renders the card.
- [ ] Empty-value clear semantics are tested: `task.rename` / `task.set-notes` empty -> `--` sentinel -> fallback render; `pipeline.rename` empty -> pending placeholder -> slug fallback.
- [ ] Twin byte-parity: `project_description`, `minimum_grade` (RepoInfo) and `display_name` (TaskModel) are present and identical across the `server.py` / `server.mjs` serializers with fixtures regenerated in lockstep; parity suites green (AC4).
- [ ] Regression fixtures: a KI-001 read-side round-trip for the settings scalars; a legacy 5-column `### Tasks lifecycle` row yields `display_name None` (fallback).
- [ ] Tests are deterministic
- [ ] Clean setup/teardown
- [ ] All acceptance criteria from source feature covered
- [ ] All section-6 quality gates pass
