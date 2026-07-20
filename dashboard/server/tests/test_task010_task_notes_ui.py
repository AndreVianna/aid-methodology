"""
test_task010_task_notes_ui.py -- Static/DOM assertions for the "TASK NOTES" card +
inline editor (task-010, feature-006-task-notes, delivery-001) in
dashboard/home.html.

Mirrors test_task009_rename_ui.py's / test_home_html_project_header.py's established
convention for this codebase: no browser/jsdom required. Tests inspect the HTML/JS
source text and verify presence/placement/order of the new markup and functions --
never execute the client-side JS. (The server-side task.set-notes argv-builder/
arg-schema -- the empty-value null-sentinel substitution, the target.task_id
superset normalization, the semantic_validate hook -- are task-010's server half
and are already covered by test_task010_task_notes.py /
test_task010_task_notes_cross_runtime_parity.py; this file covers ONLY the UI half.)

  S1  -- Structural: _renderTaskNotesPanel is appended in renderTaskView right
          after the header (container.appendChild(headerDiv)) and before the
          `if (!detail)` first-tick early-return.
  S2  -- Structural: the card reuses the existing .card / .kicker style (no new
          CSS framework); kicker text is "TASK NOTES".
  S3  -- Structural: the Edit affordance / Save / Cancel controls reuse
          .btn-ghost / .interval-input / .callout warn.
  R1  -- Render: a new thin postOp(op, target, args, onDone) helper POSTs
          {op, target, args} to the location-relative './api/op'.
  R2  -- Render: read state shows task.notes, or a dimmed "No notes." (using
          var(--text-dim)) when null.
  R3  -- Render: Save dispatches task.set-notes via postOp with
          {work_id, task_id[, delivery_id]} / {value}; on ok exits edit mode and
          calls doFetch() (NOT _refetchModelForHeader -- task-010 deliberately
          uses doFetch so the ?detail= query for the open drill view is
          preserved).
  R4  -- Render: on failure the input is NEVER reset/rebuilt (no full
          re-render on failure) -- only the inline error slot / button
          disabled-state are patched, so the user's typed value survives.
  G1  -- Gate: the Edit button/affordance renders only inside the
          `else if (writeEnabled)` non-editing arm -- never rendered (not just
          disabled) when write_enabled is false.
  G2  -- Gate: renderTaskView's poll-loop guard also covers taskNotesState
          (mirrors the existing taskRenameState guard).
  V1  -- Validation: the client-side args.value mirror rejects newline / '|' /
          over-length (<=1 KiB).
  N1  -- No new page/route: dashboard/index.html carries no task.set-notes op
          string.

Python 3.11+ stdlib only. Deterministic.
"""

import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # AID/
_HOME_HTML = _REPO_ROOT / "dashboard" / "home.html"
_INDEX_HTML = _REPO_ROOT / "dashboard" / "index.html"


class TestTaskNotesStructural(unittest.TestCase):
    """S1-S3: TASK NOTES card placement + style reuse."""

    @classmethod
    def setUpClass(cls):
        assert _HOME_HTML.is_file(), f"dashboard/home.html not found at {_HOME_HTML}"
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_s1_render_task_notes_panel_defined(self):
        self.assertIn(
            "function _renderTaskNotesPanel(workId, task, detailKey, writeEnabled)",
            self.src,
        )

    def test_s1_appended_after_header_before_detail_early_return(self):
        idx_fn = self.src.find("function renderTaskView(model, route)")
        self.assertNotEqual(idx_fn, -1)
        idx_header_append = self.src.find("container.appendChild(headerDiv);", idx_fn)
        idx_notes_append = self.src.find("_renderTaskNotesPanel(workId, task, detailKey,", idx_fn)
        idx_detail_guard = self.src.find("if (!detail) {", idx_fn)
        self.assertNotEqual(idx_header_append, -1)
        self.assertNotEqual(idx_notes_append, -1)
        self.assertNotEqual(idx_detail_guard, -1)
        self.assertLess(idx_header_append, idx_notes_append,
                         "the Notes card must be appended AFTER the header")
        self.assertLess(idx_notes_append, idx_detail_guard,
                         "the Notes card must be appended BEFORE the first-tick 'if (!detail)' return")

    def test_s2_card_reuses_card_and_kicker_classes(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 900]
        self.assertIn("card.className = 'card';", snippet)
        self.assertIn("kicker.className = 'kicker';", snippet)
        self.assertIn("kicker.textContent = 'TASK NOTES';", snippet)

    def test_s3_editor_reuses_btn_ghost_and_interval_input(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        self.assertNotEqual(idx, -1)
        self.assertNotEqual(idx_end, -1)
        snippet = self.src[idx:idx_end]
        self.assertIn("'btn-ghost'", snippet)
        self.assertIn("interval-input project-header-name-input", snippet)

    def test_s3_error_slot_reuses_callout_warn(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        self.assertIn("errSlot.className = 'callout warn';", snippet)

    def test_s2_empty_state_uses_text_dim(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        self.assertIn("var(--text-dim)", snippet)
        self.assertIn("'No notes.'", snippet)


class TestPostOpHelper(unittest.TestCase):
    """R1: the new generic postOp() helper."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r1_post_op_function_defined(self):
        self.assertIn("function postOp(op, target, args, onDone)", self.src)

    def test_r1_posts_to_relative_api_op(self):
        idx = self.src.find("function postOp(")
        snippet = self.src[idx:idx + 500]
        self.assertIn("fetch('./api/op'", snippet)
        self.assertIn("method: 'POST'", snippet)
        self.assertIn("body: JSON.stringify({ op: op, target: target, args: args })", snippet)

    def test_r1_only_one_postop_definition(self):
        self.assertEqual(self.src.count("function postOp(op, target, args, onDone)"), 1)


class TestTaskNotesReadState(unittest.TestCase):
    """R2: read state always renders -- task.notes value or dimmed empty state."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r2_shows_task_notes_when_present(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        self.assertIn("body.textContent = task.notes;", snippet)


class TestTaskNotesSaveClientCall(unittest.TestCase):
    """R3: task.set-notes dispatched via postOp; success exits edit mode + doFetch()."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r3_dispatches_task_set_notes_via_post_op(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        self.assertIn("postOp('task.set-notes', target, { value: value },", snippet)

    def test_r3_delivery_id_forwarded_only_when_present(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        self.assertIn("if (task.delivery != null) target.delivery_id = task.delivery;", snippet)

    def test_r3_success_path_calls_doFetch_not_refetch_model_for_header(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        idx_postop = snippet.find("postOp('task.set-notes'")
        self.assertNotEqual(idx_postop, -1)
        callback_snippet = snippet[idx_postop:idx_postop + 800]
        self.assertIn("taskNotesState.editing = false;", callback_snippet)
        self.assertIn("doFetch();", callback_snippet)
        self.assertNotIn("_refetchModelForHeader()", callback_snippet)


class TestTaskNotesFailurePreservesInput(unittest.TestCase):
    """R4: on failure, no full re-render is triggered -- the input keeps the
    user's text (the DOM node is never rebuilt while taskNotesState.editing
    stays true for this detailKey)."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r4_failure_branch_patches_err_slot_without_rerender(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        idx_postop = snippet.find("postOp('task.set-notes'")
        callback_snippet = snippet[idx_postop:idx_postop + 900]
        # else-branch (failure): re-enables the buttons and shows the error inline --
        # never calls _rerenderCurrentRoute()/render()/renderTaskView() (which would
        # rebuild the <input> and lose whatever the user typed).
        self.assertIn("errSlot.textContent = detail;", callback_snippet)
        idx_else = callback_snippet.find("} else {")
        failure_arm = callback_snippet[idx_else:]
        self.assertNotIn("_rerenderCurrentRoute()", failure_arm)
        self.assertNotIn("render(", failure_arm)


class TestTaskNotesWriteGate(unittest.TestCase):
    """G1: Edit affordance renders only when writeEnabled."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_g1_edit_button_only_when_write_enabled(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        idx_write_gate = snippet.find("if (writeEnabled) {")
        self.assertNotEqual(idx_write_gate, -1)
        gated_snippet = snippet[idx_write_gate:idx_write_gate + 500]
        self.assertIn("editBtn.textContent = 'Edit';", gated_snippet)

    def test_g1_called_with_task_write_enabled_variable(self):
        idx_fn = self.src.find("function renderTaskView(model, route)")
        idx_call = self.src.find("_renderTaskNotesPanel(workId, task, detailKey,", idx_fn)
        snippet = self.src[idx_fn:idx_call + 110]
        self.assertIn("var taskWriteEnabled = model.write_enabled === true;", snippet)
        self.assertIn("_renderTaskNotesPanel(workId, task, detailKey, taskWriteEnabled)", snippet)


class TestTaskNotesPollGuard(unittest.TestCase):
    """G2: renderTaskView's poll-loop guard also covers an in-progress Notes edit."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_g2_guard_present_and_mirrors_task_rename_guard(self):
        idx_fn = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx_fn:idx_fn + 1000]
        self.assertIn(
            "if ((taskRenameState.editing || taskRenameState.saving) && taskRenameState.key === detailKey) {",
            snippet,
        )
        self.assertIn(
            "if ((taskNotesState.editing || taskNotesState.saving) && taskNotesState.key === detailKey) {",
            snippet,
        )
        idx_rename_guard = snippet.find("taskRenameState.editing || taskRenameState.saving")
        idx_notes_guard = snippet.find("taskNotesState.editing || taskNotesState.saving")
        self.assertLess(idx_rename_guard, idx_notes_guard)

    def test_g2_task_notes_state_declared(self):
        self.assertIn(
            "var taskNotesState = { key: null, editing: false, saving: false };",
            self.src,
        )


class TestNotesValueValidationClient(unittest.TestCase):
    """V1: client-side args.value mirror (newline / '|' / over-length rejected)."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_v1_function_defined(self):
        self.assertIn("function _validateNotesValueClient(value)", self.src)

    def test_v1_rejects_newline_pipe_and_overlength(self):
        idx = self.src.find("function _validateNotesValueClient(value)")
        snippet = self.src[idx:idx + 500]
        self.assertIn("indexOf('\\n')", snippet)
        self.assertIn("indexOf('|')", snippet)
        self.assertIn("value.length > MAX_NOTES_VALUE_LEN", snippet)

    def test_v1_used_before_dispatching_save(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        self.assertIn("_validateNotesValueClient(value)", snippet)


class TestNoNewPageOrRoute(unittest.TestCase):
    """N1: Notes lives on the existing per-repo drill view; index.html is untouched."""

    def test_n1_index_html_carries_no_task_notes_op(self):
        assert _INDEX_HTML.is_file(), f"dashboard/index.html not found at {_INDEX_HTML}"
        src = _INDEX_HTML.read_text(encoding="utf-8")
        self.assertNotIn("task.set-notes", src)


class TestEditEntryGuardBypass(unittest.TestCase):
    """Regression coverage for a dogfood-found bug (work-017 delivery-001): the TASK
    NOTES card's Edit handler sets taskNotesState.editing=true and THEN calls
    _rerenderCurrentRoute() -> render() -> renderTaskView, whose own first action was
    the G2 poll-loop guard -- `if ((taskNotesState.editing || saving) && key ===
    detailKey) return;`. Because editing was already true by the time the guard ran,
    the guarded render early-returned and the inline editor never drew (task-notes
    Edit was a dead click). The fix: a one-shot `_taskNotesExplicitRender` flag the
    Edit-button handler sets to true immediately before _rerenderCurrentRoute();
    renderTaskView's guard consumes-and-clears it via
    _consumeTaskNotesExplicitRender(), so ONLY that one render bypasses the guard -- a
    later poll-loop re-render still sees the flag already cleared and so still
    preserves an in-progress edit/save exactly as before. Scoped independently from
    the sibling task-rename flag (test_task009_rename_ui.py's TestEditEntryGuardBypass)
    so opening one field's editor can never discard an unsaved, in-progress edit in
    the other field.

    NOTE (test-infrastructure gap): like every other test in this file, this is a
    static source-text parse -- it asserts the flag-set/flag-consume wiring is present
    and correctly ordered, but it does NOT execute the click handler or render
    function, so it cannot itself observe the DOM the way a real click would. This
    codebase has no jsdom/DOM-executing harness for home.html (only source-text
    parses); that is a genuine coverage gap this fix does not close.
    """

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_consume_helper_defined_and_reads_then_clears(self):
        idx = self.src.find("function _consumeTaskNotesExplicitRender()")
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn("_taskNotesExplicitRender = false;", snippet)
        self.assertIn("return v;", snippet)

    def test_guard_consumes_flag_before_checking_editing_state(self):
        idx_fn = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx_fn:idx_fn + 1000]
        idx_wrap = snippet.find("if (!_consumeTaskNotesExplicitRender()) {")
        self.assertNotEqual(idx_wrap, -1)
        idx_inner = snippet.find(
            "if ((taskNotesState.editing || taskNotesState.saving) && "
            "taskNotesState.key === detailKey) {",
            idx_wrap,
        )
        self.assertNotEqual(idx_inner, -1)
        self.assertLess(idx_wrap, idx_inner,
                         "the flag-consuming wrapper must be OUTSIDE the original guard")

    def test_edit_button_sets_flag_before_rerendering(self):
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        idx_click = snippet.find("taskNotesState.editing = true;")
        self.assertNotEqual(idx_click, -1)
        idx_flag = snippet.find("_taskNotesExplicitRender = true;", idx_click)
        idx_rerender = snippet.find("_rerenderCurrentRoute();", idx_click)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_rerender, -1)
        self.assertLess(idx_flag, idx_rerender,
                         "the flag must be set BEFORE the re-render call it needs to bypass")

    def test_cancel_does_not_need_and_does_not_set_the_flag(self):
        # Cancel already worked pre-fix (it sets editing=false before re-rendering, so
        # the original guard's own condition is already false) -- confirm the fix
        # didn't add an unnecessary flag-set here.
        idx = self.src.find("function _renderTaskNotesPanel(")
        idx_end = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx_end]
        idx_cancel = snippet.find("cancelBtn.addEventListener")
        cancel_snippet = snippet[idx_cancel:idx_cancel + 200]
        self.assertIn("taskNotesState.editing = false;", cancel_snippet)
        self.assertNotIn("_taskNotesExplicitRender", cancel_snippet)


if __name__ == "__main__":
    unittest.main()
