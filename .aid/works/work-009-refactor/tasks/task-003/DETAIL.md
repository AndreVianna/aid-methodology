# task-003: Rebuild the Python reader twin onto one structured state parse

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-003/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
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

**Type:** REFACTOR

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-002

**Scope:**
- `dashboard/reader/state_schema.py`: extend `parse_frontmatter_scalars` (`:116`) into the single
  whole-document state parser of the `SPEC.md § D-3` subset -- shapes S1-S5, the D-5 single-quote
  and five-escape double-quote modes, inline-comment stripping applied on this path via the
  existing `_strip_yaml_inline_comment` idiom (`parsers.py:304`), and the reject list emitting a
  `parse_warning` per rejected construct. Rename it to reflect that it parses a document, not a
  frontmatter block. Keep `_strip_scalar_quotes` (`:63`), `_looks_like_unfilled_placeholder`
  (`:82`) and `parse_bool_yesno`'s four-literal tolerance (`:226`) unchanged in behavior. Refresh
  the lockstep comment (`:29-32`) and the implicit-typing note (`:229-239`) to describe the new
  path.
- `dashboard/reader/parsers.py`: delete the `parse_state_md` (`:1282`) section state machine and
  its seven section regexes (`:1246-1252`) -- `in_pipeline_status`, `in_tasks`, `in_crossphase`,
  `in_triage`, `in_features`, `in_deliveries`, `in_lifecycle_history`; `parse_state_md` becomes
  parse-document then map keys onto `ParsedWork`, with `_apply_pipeline_frontmatter` (`:2166`) and
  `_apply_identity_frontmatter` (`:2211`) becoming the whole of it. Delete
  `_parse_tasks_line` (`:2267`), `_parse_features_line` (`:2342`), `_parse_deliveries_line`
  (`:2386`), `_parse_lifecycle_history_line` (`:2441`), `_parse_pipeline_status_line` (`:2108`),
  `_parse_triage_line` (`:2325`). Convert `parse_tasks_lifecycle_md` (`:2003`) to a
  `tasks_lifecycle` mapping read whose `ParsedTaskState` return shape is unchanged (so
  `reader.py:1132` needs no change). Convert `parse_task_state_md` (`:1637`) and
  `parse_delivery_state_md` (`:1740`) to structured reads, dropping their prose fallbacks and
  adding `quick_check` / `dispatch_log` / `delivery_lifecycle` / `delivery_gate` / `qa`. Retarget
  `parse_quick_check_findings` (`:2664`) and `parse_delivery_gate` (`:2747`) to their keys --
  they still return empty for a current-shape work, and that pre-existing staleness is preserved,
  not repaired (`SPEC.md § L-12`).
- `state_schema.parse_header_bold_field` (`:201`): remove the STATE call sites. Check for
  non-state callers before deleting the symbol -- delete it only if it has none, and name the
  surviving caller in the commit message otherwise.
- Legacy detection, replacing the prose fallbacks: a work directory holding a `STATE.md` with no
  sibling `STATE.yml` yields `_minimal_work_model` plus a `parse_warning` that names the file AND
  the migration command (`aid update`).
- `dashboard/reader/reader.py`: the filename constants (`:403`, `:833-834`, `:992`, `:1069-1070`,
  plus `_read_work_hierarchical`'s work-level (`:1273`), delivery-level (`:1360`) and task-level
  (`:1403`) resolutions) and the `state_path_label` strings (`:699`) move to one `STATE.yml`
  constant per module, with the `.aid/works/{work}/STATE.yml` labels following. `_detect_flat`
  (`:1002`) and `_detect_hierarchy` (`:971`) change filename only -- the three-part rule is
  untouched (SP-7).
- `models.py`, `derivation.py`, `io_bounds.py` stay behaviorally unchanged (the model is
  unchanged, derivation is unchanged, bounded reads apply to the new name unchanged).
- OUT of this task: the Node twin (task-004), the conformance corpus and the cross-format suite
  (task-005, task-011), and updating the existing reader suites (task-016).

**Acceptance Criteria:**
- [ ] A `STATE.yml` using only shapes S1-S5 with the declared quoting rules parses into the same
      `ParsedWork` / `ParsedTaskState` / delivery model the pre-refactor reader produced from the
      equivalent markdown file -- no model field added, renamed or removed (SP-1, SP-2).
- [ ] Every rejected construct in `SPEC.md § D-3`'s table (tab indentation, a flow collection
      other than literal `[]`/`{}`, a block scalar, an anchor/alias/tag/directive, a second
      document, indentation not a multiple of two, nesting deeper than S5, a line with no `key:`
      separator, a duplicate key -- last wins AND warn, a byte-order mark -- stripped and warned)
      emits a `parse_warning` naming file, line and construct, skips exactly that key, keeps
      parsing, and raises no exception (SP-1).
- [ ] A trailing inline `#` comment on a scalar is stripped, including the quoted-value case, and
      a full-line `#` comment at any indentation is skipped (D-3).
- [ ] Both D-5 quoting modes round-trip on read, including a value containing `|`, a newline, a
      colon, a `#` or a quote; any other backslash escape (`\uXXXX`, `\x41`) is rejected with a
      warning and literal passthrough (SP-5 read side).
- [ ] An absent, empty, truncated, unknown-key-carrying or legacy-`STATE.md` state file yields a
      best-effort model with a `parse_warning` naming the file and no exception; the legacy warning
      names the migration command; the dashboard still lists the work (SP-9).
- [ ] Exactly one file read occurs per work, reused by `read_repo_detail` for `raw_state`
      (`reader.py:696-713`) with no re-read; no stat or glob is added; `io_bounds.py`'s
      `MAX_READ_BYTES` protection applies to `STATE.yml` (SP-10).
- [ ] `_detect_flat` / `_detect_hierarchy` still apply the identical three-part rule, retargeted
      only by filename (SP-7).
- [ ] Every deleted symbol is enumerated in the commit message and `grep` over `dashboard/`
      shows no residual caller; `parse_header_bold_field` is deleted, or kept with its surviving
      non-state caller named (SP-3).
- [ ] `models.py` and `derivation.py` carry no behavioral change, and no rollup is persisted into
      a parent file (C-8, SP-3).
- [ ] `packages/pypi/pyproject.toml` still declares `dependencies = []` and no module under
      `dashboard/reader/` imports a YAML library (SP-17, C-3).
- [ ] All section-6 quality gates pass.
