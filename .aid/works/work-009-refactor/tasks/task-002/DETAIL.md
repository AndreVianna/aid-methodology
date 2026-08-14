# task-002: Convert the three work-tree state templates to the YAML subset

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-002/STATE.md` -- this task's mutable cells live
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

**Depends on:** task-001

**Scope:**
- The three in-scope templates, converted in `canonical/` only (C-1):
  `canonical/aid/templates/work-state-template.md` -> `work-state-template.yml`,
  `delivery-state-template.md` -> `delivery-state-template.yml`,
  `task-state-template.md` -> `task-state-template.yml`. The `.md` files are deleted.
- Each carries the corresponding skeleton from `SPEC.md § D-4` verbatim in shape: the work-level
  flattened set (including the four flattened-only gate/delivery scalars, `delivery_lifecycle`,
  `tasks_lifecycle`, `delivery_gate`, `qa`), the work-level full-layout omission rule, the
  per-delivery set, and the per-task set (including `quick_check` and `dispatch_log`, which exist
  at that level only).
- The current zone documentation, enum hints, single-writer `[W]`/`[A]` annotations and the STATE
  ADVANCEMENT ORDERING block (today `work-state-template.md:62-86`, and the single encoding of
  that ordering) survive as full-line `#` YAML comments -- this is the reason YAML beat JSON.
- Two mechanical shape rules from `SPEC.md § D-3`/`§ L-1`: no trailing inline comment on any
  writer-owned key (`WB_SET_FRONTMATTER_AWK` replaces the whole line, so a trailing comment is
  destroyed on first write -- every hint goes on its own full-line comment ABOVE the key); and no
  un-instantiated `{...}` placeholder on a key whose real value must be readable before the first
  write.
- `display_name` is declared in the task-level template as the one documented exception of SP-2 --
  a **documentation fix** (the writer already writes it, `writeback-state.sh:829`), recorded as
  such, not a schema change.
- DERIVED views (Features State, Plan/Deliveries, Tasks State, Delivery Gates, Calibration Log,
  Dispatches) get NO key at all; `qa` is the one former-DERIVED name that keeps a key, and only in
  the flattened work-level template where it is AUTHORED.
- Quoting per `SPEC.md § D-5`: every implicit-typing deny-list value quoted (notably
  `user_approved: 'no'`), bare values kept byte-identical to today wherever the bare class allows.
- OUT of this task: `canonical/aid/templates/discovery-state-template.md` (out of scope, serves
  the KB ledger); the writer (task-007); the readers (task-003/004); every consumer that names a
  template by filename -- `shortcut-engine.md § INTAKE Step 4`'s `cp`, `aid-review/SKILL.md`
  (task-014); `tests/canonical/test-work-state-template.sh` (task-015); the `profiles/` renders
  and dogfood trees (task-017 -- hand-editing one is a defect).

**Acceptance Criteria:**
- [ ] The three `.yml` templates exist at their canonical paths and the three `.md` templates no
      longer exist; no other file under `canonical/aid/templates/` is modified.
- [ ] The key set and every closed-enum string are identical to the pre-refactor set at all three
      levels -- no key added, renamed or removed, no enum string changed -- with `display_name` the
      single documented exception, recorded in the commit message as a documentation fix (SP-2).
- [ ] No key exists for Features State, Plan/Deliveries, Tasks State, Delivery Gates, Calibration
      Log or Dispatches in any of the three templates; `qa` appears only in the flattened
      work-level template (SP-3).
- [ ] Every enum hint, `[W]`/`[A]` single-writer annotation and the STATE ADVANCEMENT ORDERING
      block survive as full-line `#` comments; no `[W]` key carries a trailing inline comment
      (D-3, SP-20a). Verified by grep, not by reading: today's `work-state-template.md` breaks this
      on `pause_reason`, `block_reason`, `block_artifact`, `ticket_ref` and
      `pipeline.path`/`pipeline.initiator`, so it is a recurrence risk carried in the source, and
      `§D-4`'s skeletons are the corrected form to copy.
- [ ] No key whose real value must be readable before the first write carries an un-instantiated
      `{...}` placeholder; the readers' `_looks_like_unfilled_placeholder` skip
      (`state_schema.py:82`) is left untouched as the safety net rather than relied on as the
      mechanism (SP-20b).
- [ ] Each template uses only shapes S1-S5, two-space indentation, no tabs, no flow collection
      other than a literal `[]`/`{}`, no block scalar, no anchor/alias/tag/directive and no `---`
      document fence (D-1, D-3).
- [ ] Every value on the implicit-typing deny list is quoted; `user_approved` is written `'no'`
      with the enum string `no` intact (D-5, C-5, NFR-2).
- [ ] The work-level template documents the full-layout omission rule (which keys a full work
      omits) as a comment, and the per-task template keeps `quick_check` / `dispatch_log` at that
      level only (D-4).
- [ ] `canonical/aid/templates/discovery-state-template.md` is byte-unchanged.
- [ ] No file under `profiles/`, `.claude/` or `.cursor/` is edited by this task (C-1).
- [ ] All section-6 quality gates pass.
