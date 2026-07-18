# task-005: DM-1 reader exposure of project_description + global minimum_grade

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

**Type:** IMPLEMENT

**Source:** feature-002-project-header-edit -> delivery-001

**Depends on:** task-001

**Scope:**
- Additively expose the two settings scalars the redesigned header must display -- `project.description` and the global `review.minimum_grade` -- on the DM-1 `./api/model` channel `home.html` consumes, with identical parser + serializer changes across both reader twins and a KI-001-safe round-trip. This is read-side only; the header UI is task-006.
- Parsers: factor the body of `parse_project_name` (`parsers.py:173`) into a combined `parse_project_settings(settings_path) -> (name, description, bytes_read)` that shares one `project:`-section scan for name + description, keeping a thin `parse_project_name` wrapper for existing callers/tests; add a SEPARATE `parse_minimum_grade(settings_path) -> (grade, bytes_read)` that does its own `review:`-section scan (in a real `settings.yml` the `tools:` section sits between `project:` and `review:`, so the `project:` scan's break-on-next-top-level-key logic (`parsers.py:207-208`) cannot reach `review:`). Mirror both in the Node twin (`parseProjectName`, `reader.mjs:594`). Same `_strip_yaml_inline_comment` handling, quote-stripping, and bounded read (`read_bytes_bounded`). `review.minimum_grade` is read literally as a display scalar (no resolution -- `read-setting.sh` remains the resolution contract).
- Models: `RepoInfo` (`models.py:220`) gains `project_description: Optional[str] = None` and `minimum_grade: Optional[str] = None` (the GLOBAL settings default, deliberately distinct from `WorkModel.minimum_grade`, the per-work value).
- `reader.py` populates both new fields at the LEVEL-1 build site (`reader.py:423`; the parser calls sit near `reader.py:392`); the empty-model early-return `RepoInfo(...)` (`reader.py:371`, no-`.aid` path) leaves both at their `None` default. The Node twin populates `repoInfo` (`reader.mjs:2640`) / `_buildRepoInfo` (`reader.mjs:4327`). Absent/unreadable -> `None`; the folder-basename fallback for `project_name` is unchanged.
- Serializers: emit the two new keys in declared field order `project_name, project_description, minimum_grade, aid_dir, kb_state` (inserted after `project_name`) in `_ser_repo_info` (`server.py:595`) and `_buildRepoInfo` (`reader.mjs:4327`), identically in both twins, to preserve DM-3 byte-parity. No `schema_version` bump (stays 3; DM-A3 / RC-2 precedent). Regenerate golden fixtures in lockstep.
- KI-001 read-side: the new DM-1 parser MUST strip/round-trip identically to `_read_settings` (`server.py:347`) / `readSettings` (`server.mjs:380`) -- same `_strip_yaml_inline_comment` + bare/quoted-scalar handling -- so both channels display the same value after a write.

**Acceptance Criteria:**
- [ ] `parse_project_settings` returns `(name, description, bytes_read)` from one `project:`-section scan; `parse_project_name` remains a thin wrapper (existing callers/tests unchanged); both are mirrored in `reader.mjs`.
- [ ] `parse_minimum_grade` reads the global `review.minimum_grade` via its own `review:`-section scan (correct across a real `settings.yml` where `tools:` sits between `project:` and `review:`), read literally with no resolution; mirrored in `reader.mjs`.
- [ ] `RepoInfo` carries `project_description` + `minimum_grade` (both Optional, default `None`, distinct from `WorkModel.minimum_grade`); populated at the LEVEL-1 build site and left `None` on the no-`.aid` early-return and when the scalar is absent/unreadable.
- [ ] Serializers emit `project_name, project_description, minimum_grade, aid_dir, kb_state` in that order, identically in `_ser_repo_info` and `_buildRepoInfo`; `schema_version` stays 3; golden fixtures regenerated in lockstep and the parity suites stay green (AC4).
- [ ] The new DM-1 parser round-trips a `settings.yml` value identically to `_read_settings`/`readSettings` (same strip/quote handling); the named KI-001 read-side round-trip regression fixture that pins this is authored by the TEST task (task-012), not this IMPLEMENT task.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
