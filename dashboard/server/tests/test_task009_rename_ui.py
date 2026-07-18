"""
test_task009_rename_ui.py -- Static/DOM assertions for the feature-005 (display-rename)
UI half: the pipeline-rename pencil (FR-PL1) and task-rename pencil (FR-T1) controls in
dashboard/home.html, plus the display_name -> short_name -> task_id label precedence at
both render sites (task-009, work-017-cli-improvements, delivery-001).

Mirrors test_home_html_project_header.py's established convention for this codebase: no
browser/jsdom required. Tests inspect the HTML/JS source text and verify presence/
placement/order of the new markup and functions -- never execute the client-side JS.
(The server-side op argv-builders/arg-schemas -- OP_TABLE rows, semantic_validate, the
task.rename/pipeline.rename null-sentinel substitution -- are task-008's own scope and
are already covered by test_task008_display_rename.py; this file covers ONLY the UI half
task-009 adds on top of that.)

  S1  -- Structural: the pipeline-rename pencil slot + inline editor + error/status
          regions are siblings of (never nested inside) the collapsible toggle button.
  S2  -- Structural: _renderPipelineTitleControl is invoked from renderWorkHeader, after
          the title/de-slug-fallback block, gated on model.write_enabled.
  S3  -- Structural: the pipeline editor reuses .btn-ghost / .interval-input /
          .project-header-name-input / .callout err (no new CSS framework).
  S4  -- Structural: the task-rename pencil is appended in renderTaskView's at-a-glance
          header, gated on model.write_enabled.
  R1  -- Render: pipeline.rename POST body {op, target:{work_id}, args:{value}} via the
          location-relative './api/op'; prefilled from work.title; Save triggers a
          re-fetch (_refetchModelForHeader) on ok.
  R2  -- Render: task.rename POST body {op, target:{work_id,[delivery_id],task_id},
          args:{value}}; delivery_id forwarded only when task.delivery is set.
  R3  -- Render: label precedence display_name -> short_name -> task_id, shared by a
          single _taskDisplayLabel helper consumed at BOTH render sites (task card +
          drill view) -- AC3/AC4 lockstep.
  G1  -- Gate: both pencils render only when write_enabled === true; not rendered (not
          just disabled) when false -- AC8 UI half.
  V1  -- Validation: the shared client-side args.value mirror rejects newline / '|'.
  N1  -- No new page/route: dashboard/index.html carries neither op string.

Python 3.11+ stdlib only. Deterministic.
"""

import re
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # AID/
_HOME_HTML = _REPO_ROOT / "dashboard" / "home.html"
_INDEX_HTML = _REPO_ROOT / "dashboard" / "index.html"


class TestPipelineRenameStructural(unittest.TestCase):
    """S1-S3: pipeline-rename markup placement + style reuse."""

    @classmethod
    def setUpClass(cls):
        assert _HOME_HTML.is_file(), f"dashboard/home.html not found at {_HOME_HTML}"
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_s1_pencil_slot_and_editor_present(self):
        self.assertIn('id="overview-title-edit-btn"', self.src)
        self.assertIn('id="overview-title-editor"', self.src)
        self.assertIn('id="overview-title-error"', self.src)
        self.assertIn('id="overview-title-status"', self.src)

    def test_s1_pencil_slot_is_sibling_not_nested_in_toggle_button(self):
        # The toggle button (#work-overview-header-btn) must CLOSE before the pencil
        # slot opens -- a <button> cannot validly contain another interactive control,
        # and the whole toggle row is itself clickable (collapse/expand).
        idx_btn_close = self.src.find("</button>", self.src.find('id="work-overview-header-btn"'))
        idx_pencil = self.src.find('id="overview-title-edit-btn"')
        self.assertNotEqual(idx_btn_close, -1)
        self.assertNotEqual(idx_pencil, -1)
        self.assertLess(idx_btn_close, idx_pencil,
                         "the pencil slot must be a sibling AFTER the toggle button closes")

    def test_s1_editor_error_status_precede_collapsible_body(self):
        idx_editor = self.src.find('id="overview-title-editor"')
        idx_body = self.src.find('id="work-overview-body"')
        self.assertNotEqual(idx_editor, -1)
        self.assertNotEqual(idx_body, -1)
        self.assertLess(idx_editor, idx_body)

    def test_s2_render_pipeline_title_control_defined(self):
        self.assertIn("function _renderPipelineTitleControl(work, writeEnabled)", self.src)

    def test_s2_called_from_render_work_header_after_title_fallback(self):
        idx_fn = self.src.find("function renderWorkHeader(work, model)")
        self.assertNotEqual(idx_fn, -1)
        idx_fallback = self.src.find("Name not yet recorded", idx_fn)
        idx_call = self.src.find("_renderPipelineTitleControl(work,", idx_fn)
        self.assertNotEqual(idx_fallback, -1)
        self.assertNotEqual(idx_call, -1)
        self.assertLess(idx_fallback, idx_call)

    def test_s2_gated_on_model_write_enabled(self):
        idx_fn = self.src.find("function renderWorkHeader(work, model)")
        snippet = self.src[idx_fn:idx_fn + 2500]
        self.assertIn("_renderPipelineTitleControl(work, model && model.write_enabled === true)", snippet)

    def test_s3_reuses_btn_ghost_and_interval_input(self):
        idx = self.src.find("function _buildPipelineTitleEditor(work)")
        idx_end = self.src.find("function _savePipelineRename(")
        self.assertNotEqual(idx, -1)
        self.assertNotEqual(idx_end, -1)
        snippet = self.src[idx:idx_end]
        self.assertIn("'btn-ghost'", snippet)
        self.assertIn("interval-input project-header-name-input", snippet)

    def test_s3_error_region_reuses_callout_err(self):
        self.assertIn('id="overview-title-error" class="callout err"', self.src)


class TestPipelineRenameClientCall(unittest.TestCase):
    """R1: pipeline.rename op call shape + prefill + re-fetch on success."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r1_post_function_defined(self):
        self.assertIn("function _postPipelineRename(workId, value, onDone)", self.src)

    def test_r1_posts_to_relative_api_op(self):
        idx = self.src.find("function _postPipelineRename(")
        snippet = self.src[idx:idx + 500]
        self.assertIn("fetch('./api/op'", snippet)
        self.assertIn("method: 'POST'", snippet)
        self.assertIn("op: 'pipeline.rename'", snippet)
        self.assertIn("target: { work_id: workId }", snippet)
        self.assertIn("args: { value: value }", snippet)

    def test_r1_editor_prefilled_from_work_title(self):
        idx = self.src.find("function _buildPipelineTitleEditor(work)")
        snippet = self.src[idx:idx + 700]
        self.assertIn("input.value = work.title || ''", snippet)

    def test_r1_save_calls_post_with_work_id_and_input_value(self):
        idx = self.src.find("function _buildPipelineTitleEditor(work)")
        snippet = self.src[idx:idx + 1400]
        self.assertIn("_savePipelineRename(work, input.value)", snippet)

    def test_r1_success_path_refetches_model(self):
        idx = self.src.find("function _savePipelineRename(work, value)")
        snippet = self.src[idx:idx + 1200]
        self.assertIn("_refetchModelForHeader()", snippet)
        self.assertIn("pipelineRenameState.editing = false", snippet)

    def test_r1_failure_path_keeps_error_and_exits_edit_mode(self):
        idx = self.src.find("function _savePipelineRename(work, value)")
        snippet = self.src[idx:idx + 1200]
        # else-branch of the result.ok check: sets errorMessage without mutating the model
        self.assertIn("pipelineRenameState.errorMessage = detail;", snippet)

    def test_r1_cancel_does_not_post(self):
        idx = self.src.find("function _buildPipelineTitleEditor(work)")
        idx_end = self.src.find("function _savePipelineRename(")
        snippet = self.src[idx:idx_end]
        cancel_idx = snippet.find("cancelBtn.addEventListener")
        cancel_snippet = snippet[cancel_idx:cancel_idx + 300]
        self.assertNotIn("_postPipelineRename", cancel_snippet)
        self.assertNotIn("fetch(", cancel_snippet)


class TestTaskRenameStructural(unittest.TestCase):
    """S4: task-rename pencil placement in renderTaskView, gated on write_enabled."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_s4_render_control_defined(self):
        self.assertIn(
            "function _renderTaskRenameControl(workId, task, detailKey, writeEnabled)",
            self.src,
        )

    def test_s4_appended_in_render_task_view_header(self):
        idx_fn = self.src.find("function renderTaskView(model, route)")
        self.assertNotEqual(idx_fn, -1)
        idx_call = self.src.find("_renderTaskRenameControl(workId, task, detailKey,", idx_fn)
        self.assertNotEqual(idx_call, -1)

    def test_s4_gated_on_model_write_enabled(self):
        idx_fn = self.src.find("function renderTaskView(model, route)")
        idx_call = self.src.find("_renderTaskRenameControl(", idx_fn)
        snippet = self.src[idx_fn:idx_call + 50]
        self.assertIn("var taskWriteEnabled = model.write_enabled === true;", snippet)

    def test_s4_pencil_not_rendered_when_write_disabled(self):
        idx = self.src.find("function _renderTaskRenameControl(")
        snippet = self.src[idx:idx + 2600]
        # Display-mode pencil only appears inside an `else if (writeEnabled)` arm --
        # never rendered (not just disabled) when write_enabled is false.
        self.assertIn("} else if (writeEnabled) {", snippet)


class TestTaskRenameClientCall(unittest.TestCase):
    """R2: task.rename op call shape, incl. conditional delivery_id."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r2_post_function_defined(self):
        self.assertIn(
            "function _postTaskRename(workId, deliveryId, taskId, value, onDone)",
            self.src,
        )

    def test_r2_posts_to_relative_api_op(self):
        idx = self.src.find("function _postTaskRename(")
        snippet = self.src[idx:idx + 700]
        self.assertIn("fetch('./api/op'", snippet)
        self.assertIn("op: 'task.rename'", snippet)

    def test_r2_delivery_id_forwarded_only_when_present(self):
        idx = self.src.find("function _postTaskRename(")
        snippet = self.src[idx:idx + 400]
        self.assertIn("if (deliveryId != null) target.delivery_id = deliveryId;", snippet)

    def test_r2_save_forwards_task_delivery(self):
        idx = self.src.find("function _saveTaskRename(")
        snippet = self.src[idx:idx + 900]
        self.assertIn("_postTaskRename(workId, task.delivery, task.task_id, value,", snippet)

    def test_r2_success_path_refetches_model(self):
        idx = self.src.find("function _saveTaskRename(")
        snippet = self.src[idx:idx + 1200]
        self.assertIn("_refetchModelForHeader()", snippet)

    def test_r2_editor_prefilled_from_display_label(self):
        idx = self.src.find("function _renderTaskRenameControl(")
        snippet = self.src[idx:idx + 900]
        self.assertIn("input.value = _taskDisplayLabel(task) || '';", snippet)


class TestLabelPrecedenceBothSites(unittest.TestCase):
    """R3: display_name -> short_name -> task_id, shared helper, both render sites."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r3_shared_helper_defined_with_precedence(self):
        idx = self.src.find("function _taskDisplayLabel(task)")
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 350]
        idx_display = snippet.find("task.display_name")
        idx_short = snippet.find("task.short_name")
        idx_id = snippet.find("return task.task_id")
        self.assertNotEqual(idx_display, -1)
        self.assertNotEqual(idx_short, -1)
        self.assertNotEqual(idx_id, -1)
        self.assertLess(idx_display, idx_short)
        self.assertLess(idx_short, idx_id)

    def test_r3_task_card_uses_shared_helper(self):
        idx = self.src.find("function makeTaskChip(task, workId)")
        idx_end = idx + 2000
        snippet = self.src[idx:idx_end]
        self.assertIn("_taskDisplayLabel(task)", snippet)
        # No re-implementation of the precedence chain inline in the chip anymore.
        self.assertNotIn("task.short_name != null && String(task.short_name).trim()", snippet)

    def test_r3_drill_view_uses_shared_helper(self):
        idx = self.src.find("function renderTaskView(model, route)")
        snippet = self.src[idx:idx + 3000]
        self.assertIn("_taskDisplayLabel(task)", snippet)


class TestRenameValueValidationClient(unittest.TestCase):
    """V1: shared client-side args.value mirror (newline / '|' rejected)."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_v1_function_defined(self):
        self.assertIn("function _validateRenameValueClient(value)", self.src)

    def test_v1_rejects_newline_and_pipe(self):
        idx = self.src.find("function _validateRenameValueClient(value)")
        snippet = self.src[idx:idx + 400]
        self.assertIn("indexOf('\\n')", snippet)
        self.assertIn("indexOf('|')", snippet)

    def test_v1_used_by_both_save_paths(self):
        idx_pipeline = self.src.find("function _savePipelineRename(work, value)")
        pipeline_snippet = self.src[idx_pipeline:idx_pipeline + 300]
        self.assertIn("_validateRenameValueClient(value)", pipeline_snippet)

        idx_task = self.src.find("function _saveTaskRename(")
        task_snippet = self.src[idx_task:idx_task + 300]
        self.assertIn("_validateRenameValueClient(value)", task_snippet)


class TestNoNewPageOrRoute(unittest.TestCase):
    """N1: rename lives on the existing per-repo page; index.html is untouched."""

    def test_n1_index_html_carries_no_rename_ops(self):
        assert _INDEX_HTML.is_file(), f"dashboard/index.html not found at {_INDEX_HTML}"
        src = _INDEX_HTML.read_text(encoding="utf-8")
        self.assertNotIn("pipeline.rename", src)
        self.assertNotIn("task.rename", src)


if __name__ == "__main__":
    unittest.main()
