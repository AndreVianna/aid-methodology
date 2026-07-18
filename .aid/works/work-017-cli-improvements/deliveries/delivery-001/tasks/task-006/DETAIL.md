# task-006: home.html project-header edit panel + settings.set client

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

**Depends on:** task-004, task-005

**Scope:**
- Redesign the `home.html` project-header from a KB-link card into an editable identity panel (name / description / global grade + KB button), wire the `settings.set` client call + targeted re-fetch, and introduce the shared `envelope.write_enabled -> model.write_enabled` graft that features 005/006 reuse. Every edit affordance is gated on `write_enabled`.
- New `#project-header` panel at the TOP of `#main-page` (before the KB heading + `#knowledge-tool-section`, `home.html` line 874-877), rendered by a new `_renderProjectHeader(model)` called first inside `renderMainPage` (line 1318). Reuse the `.work-overview*` panel pattern (lines 353-417) and existing styles `.btn-ghost` (155), `.interval-input` (719), `.badge` (178), `.callout.err` (244); no new CSS framework.
- Panel contents: (1) name as `.work-overview-title` from `model.repo.project_name`, pencil/`Edit` `.btn-ghost` swaps to a text input + Save/Cancel -> `settings.set {path:"project.name"}` (empty name rejected client-side); (2) description as `.work-overview-desc` from `model.repo.project_description` (muted placeholder when empty), `<textarea>` edit -> `settings.set {path:"project.description"}` (empty clears); (3) global minimum grade as a labelled `<select>` (`A+ A A- B+ ... F`, `^[A-F][+-]?$`) seeded from `model.repo.minimum_grade` -> `settings.set {path:"review.minimum_grade"}` (read-only shows the value as a `.badge`); (4) an "Open Knowledge Base" `.btn-ghost` -> `./kb.html`, preserving `_renderKbCard`'s target and clickability rule (line 1618: clickable only when `kb_state.status` is `approved`/`outdated`, else a disabled button carrying the 5-state status label).
- Finalize the `settings.set` arg-schema (client + server): closed `args.path` allowlist `{project.name, project.description, review.minimum_grade}`; grade value `^[A-F][+-]?$`; `project.name`/`project.description` reject `\n`/`"`/`\` (KI-001), empty allowed for description (clears), rejected for name (required).
- Add the shared `write_enabled` graft in `onSuccess` (line 1067/1081): `lastGoodModel.write_enabled = (envelope.write_enabled === true)` (missing -> false), mirroring the existing `envelope.details` graft; this is shared infrastructure features 005/006 reuse. Every edit affordance renders only when `model.write_enabled === true`.
- On a successful `settings.set`: re-fetch `./api/model`, swap `lastGoodModel`, call `renderMainPage` (header re-renders from disk, no drift); on failure show an inline `.callout.err` and revert the field to its last on-disk value (no optimistic mutation). Accessibility grounded in existing patterns: each field labelled (`<label>`/`aria-label`), keyboard-operable, Save/error announced via an `aria-live="polite"` region, disabled KB button uses `aria-disabled`, edit toggles use `aria-expanded`.

**Acceptance Criteria:**
- [ ] The `#project-header` panel renders name / description / global-grade + a KB button at the top of `#main-page` via `_renderProjectHeader` (first call in `renderMainPage`), reusing existing `.work-overview*` / `.btn-ghost` / `.badge` / `.callout.err` styles.
- [ ] Editing name/description/grade dispatches `settings.set {path,value}` and, on ok, re-fetches `./api/model` and re-renders the header from disk with no drift (AC1/AC2); no optimistic mutation.
- [ ] The `settings.set` arg-schema is enforced client + server: grade `^[A-F][+-]?$` (via the `<select>`); name/description reject `\n`/`"`/`\`; empty description clears, empty name rejected.
- [ ] The KB button preserves `_renderKbCard`'s target (`./kb.html`) and 5-state clickability rule (clickable only when `approved`/`outdated`; else disabled with the status label).
- [ ] The shared `envelope.write_enabled -> model.write_enabled` graft is added in `onSuccess` (missing -> false); all edit affordances render only when `write_enabled === true` (read-only display otherwise) -- the AC8 UI half.
- [ ] Accessibility: each field is labelled, keyboard-operable, Save/error announced via `aria-live`, and the disabled KB button uses `aria-disabled` (not removal).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
