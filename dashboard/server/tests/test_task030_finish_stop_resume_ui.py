"""
test_task030_finish_stop_resume_ui.py -- Static/DOM assertions for the Pipeline
Finish (FR-PL2) and Task Stop/Resume (FR-T3, AC6) controls (task-030,
feature-008-execution-control, delivery-005, work-017-cli-improvements) in
dashboard/home.html.

Mirrors test_task026_delete_pipeline_ui.py's / test_task022_connectors_
external_sources_ui.py's / test_task009_rename_ui.py's established convention
for this codebase: no browser/jsdom required. Tests inspect the HTML/JS source
text and verify presence/placement/order of the new markup and functions --
never execute the client-side JS. (The server-side task.stop/task.resume
OP_TABLE rows, argv-builders, and write-control-signal.sh dispatch are
task-029's own scope, already covered by test_task029_task_stop_resume_ops.py;
this file covers ONLY the UI half task-030 adds on top of that, plus a
functional-verification check on the pre-existing pipeline.finish OP_TABLE row
both twins already carry.)

  OP0 -- Pre-flight: `pipeline.finish` is a FUNCTIONAL OP_TABLE row (writer +
          build_argv, not a placeholder) in BOTH server twins -- the
          precondition task-030's Finish button is wired against.

  F-S1 -- Finish structural: #overview-finish-zone is a child of
          #work-overview-body, placed BEFORE #overview-danger-zone; renderWorkHeader
          calls _renderFinishControl BEFORE _renderDangerZone.
  F-S2 -- Finish structural: _renderFinishControl/_submitPipelineFinish are
          defined with the documented signature and are NEVER referenced from
          _renderWorkCard (the main-grid card) or dashboard/index.html.
  F-G1 -- Finish gate: renders ONLY when writeEnabled AND work.lifecycle ===
          'Running' -- both checks are early-returns AFTER container.innerHTML
          is cleared, so a gated-out call still empties any prior content.
  F-C1 -- Finish confirm: window.confirm() with the exact §UI Specs copy; a
          declined confirm never calls _submitPipelineFinish.
  F-OP1 -- Finish op dispatch: postOp('pipeline.finish', { work_id: work.work_id
          }, {}, ...) -- the documented target shape (no args).
  F-RR -- Finish re-render: success calls _refetchModelForHeader() (AC2, the
          card then shows LIFECYCLE_MAP['Completed']); failure sets an inline
          errorMessage and re-renders from the SAME cached work (no
          optimistic flip, no navigation).
  F-GB -- Finish regression coverage (delivery-001 dogfood fix, commit
          41ea5d28): the explicit-render one-shot bypass flag is present and
          consumed BEFORE the guard's `saving` check, and is set before every
          render call made while entering the `saving` state or the
          post-failure re-render.

  T-S1 -- Stop/Resume structural: a SHARED builder (_buildTaskStopResumeControl)
          is called from BOTH makeTaskChip and renderTaskView -- so the two
          render sites stay in lockstep (mirrors _taskDisplayLabel's identical
          shared-helper role).
  T-G1 -- Stop/Resume AC6 gate: the shared builder returns null unless
          task.status === 'In Progress' AND writeEnabled -- explicitly
          verified for EVERY other status value, INCLUDING 'In Review' (the
          gate's deliberate narrowing below the chip's "active" CSS class).
  T-L1 -- Label/action flip: stop_requested === false -> "Stop"/task.stop;
          stop_requested === true -> "Resume"/task.resume.
  T-P1 -- Paused pill: makeStopRequestedPill() is a decorative badge distinct
          from makeTaskStatusBadge/STATUS_MAP; shown in makeTaskChip/
          renderTaskView ALONGSIDE (never instead of) the status badge, and
          independent of write_enabled (a read-only viewer still sees it).
  T-OP1 -- Stop/Resume op dispatch: postOp(op, { work_id, task_id[,
          delivery_id] }, {}, ...) with the SAME shape task.rename/
          task.set-notes already use (delivery_id forwarded only when
          task.delivery is set).
  T-RR -- Stop/Resume re-render: success calls _refetchModelForHeader() (AC2,
          re-derives stop_requested from disk, never optimistically flipped);
          failure surfaces an inline error and re-renders via
          _rerenderCurrentRoute().
  T-NAV -- The toggle's click handler calls e.stopPropagation() so clicking it
          on the chip never ALSO triggers the chip's own SEAM-2 drill-nav
          onclick.
  T-GB -- Stop/Resume regression coverage (delivery-001 dogfood fix): the
          SAME one-shot bypass-flag pattern, consumed BEFORE the `saving`
          check in BOTH renderTasks (chip grid) and renderTaskView (drill).

  WG -- Defense-in-depth: write_enabled === false hides the Finish button, the
        Stop/Resume toggle -- but NOT the decorative paused pill (informational
        only).

NOTE (test-infrastructure gap, same as test_task026_delete_pipeline_ui.py's
TestExplicitRenderGuardBypass): every test in this file is a static
source-text parse. It asserts the guard/bypass wiring, the copy strings, and
the op-dispatch call sites are present and correctly ordered, but it does NOT
execute a click handler or the render functions in a real DOM, so it CANNOT
itself observe that clicking "Finish"/"Stop"/"Resume" in a real browser
actually confirms, disables the button, or that a poll tick genuinely leaves
the disabled state alone. This codebase has no jsdom/DOM-executing harness for
home.html (only source-text parses) -- runtime behavior (does the confirm()
dialog actually appear, does the button really flip label/disable, does a
concurrent poll tick leave it untouched) is the browser-dogfood's job at the
delivery-005 gate.

Python 3.11+ stdlib only. Deterministic.
"""

import re
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # AID/
_HOME_HTML = _REPO_ROOT / "dashboard" / "home.html"
_INDEX_HTML = _REPO_ROOT / "dashboard" / "index.html"
_SERVER_PY = _REPO_ROOT / "dashboard" / "server" / "server.py"
_SERVER_MJS = _REPO_ROOT / "dashboard" / "server" / "server.mjs"


def _slice_fn(src, fn_signature, window=6000):
    idx = src.find(fn_signature)
    if idx == -1:
        return None
    return src[idx:idx + window]


class TestPipelineFinishOpTableFunctional(unittest.TestCase):
    """OP0: pipeline.finish is a FUNCTIONAL OP_TABLE row (writer + build_argv),
    not a placeholder -- the precondition task-030's Finish button depends on.
    Verified in BOTH server twins (task-025's review referenced it as an
    existing pipeline-scoped op alongside pipeline.rename)."""

    @classmethod
    def setUpClass(cls):
        assert _SERVER_PY.is_file()
        assert _SERVER_MJS.is_file()
        cls.py_src = _SERVER_PY.read_text(encoding="utf-8")
        cls.mjs_src = _SERVER_MJS.read_text(encoding="utf-8")

    def test_op0_python_twin_row_is_functional(self):
        snippet = _slice_fn(self.py_src, '"pipeline.finish": {', window=250)
        self.assertIsNotNone(snippet, "pipeline.finish OP_TABLE row missing in server.py")
        self.assertIn('"writer": "writeback-state.sh"', snippet)
        self.assertIn('"build_argv": _op_pipeline_finish_argv', snippet)
        self.assertIn('def _op_pipeline_finish_argv(', self.py_src)
        # The argv-builder actually forwards a Lifecycle write (not a stub).
        argv_snippet = _slice_fn(self.py_src, 'def _op_pipeline_finish_argv(', window=600)
        self.assertIn("--field", argv_snippet)
        self.assertIn("Lifecycle", argv_snippet)
        self.assertIn("Completed", argv_snippet)

    def test_op0_node_twin_row_is_functional(self):
        snippet = _slice_fn(self.mjs_src, '"pipeline.finish": {', window=250)
        self.assertIsNotNone(snippet, "pipeline.finish OP_TABLE row missing in server.mjs")
        self.assertIn('writer: "writeback-state.sh"', snippet)
        self.assertIn("buildArgv: opPipelineFinishArgv", snippet)
        self.assertIn("function opPipelineFinishArgv(", self.mjs_src)


class TestFinishStructuralPlacement(unittest.TestCase):
    """F-S1/F-S2: container placement + call-site ordering inside
    renderWorkHeader; never wired into the main-grid card or index.html."""

    @classmethod
    def setUpClass(cls):
        assert _HOME_HTML.is_file(), f"dashboard/home.html not found at {_HOME_HTML}"
        cls.src = _HOME_HTML.read_text(encoding="utf-8")
        assert _INDEX_HTML.is_file()
        cls.index_src = _INDEX_HTML.read_text(encoding="utf-8")

    def test_finish_zone_container_present(self):
        self.assertIn('id="overview-finish-zone"', self.src)

    def test_finish_zone_precedes_danger_zone_inside_work_overview_body(self):
        idx_body_open = self.src.find('id="work-overview-body"')
        idx_finish = self.src.find('id="overview-finish-zone"')
        idx_danger = self.src.find('id="overview-danger-zone"')
        idx_body_close = self.src.find('/#work-overview-body', idx_danger)
        for name, idx in [("body-open", idx_body_open), ("finish-zone", idx_finish),
                           ("danger-zone", idx_danger), ("body-close", idx_body_close)]:
            self.assertNotEqual(idx, -1, f"{name} not found")
        self.assertLess(idx_body_open, idx_finish)
        self.assertLess(idx_finish, idx_danger)
        self.assertLess(idx_danger, idx_body_close)

    def test_render_work_header_calls_finish_before_danger_zone(self):
        idx = self.src.find('function renderWorkHeader(work, model)')
        self.assertNotEqual(idx, -1)
        idx_end = self.src.find('\n  }', idx)
        snippet = self.src[idx:idx_end]
        idx_finish_call = snippet.find('_renderFinishControl(work, model && model.write_enabled === true);')
        idx_danger_call = snippet.find('_renderDangerZone(work, model && model.write_enabled === true);')
        self.assertNotEqual(idx_finish_call, -1)
        self.assertNotEqual(idx_danger_call, -1)
        self.assertLess(idx_finish_call, idx_danger_call)

    def test_render_functions_defined_with_documented_signature(self):
        self.assertIn('function _renderFinishControl(work, writeEnabled)', self.src)
        self.assertIn('function _submitPipelineFinish(work)', self.src)

    def test_render_work_card_never_calls_finish_control(self):
        idx = self.src.find('function _renderWorkCard(work)')
        self.assertNotEqual(idx, -1)
        idx_end = self.src.find('\n  function ', idx + 10)
        snippet = self.src[idx:idx_end]
        self.assertNotIn('_renderFinishControl', snippet)
        self.assertNotIn('pipeline.finish', snippet)

    def test_index_html_has_no_finish_affordance(self):
        self.assertNotIn('pipeline.finish', self.index_src)
        self.assertNotIn('_renderFinishControl', self.index_src)
        self.assertNotIn('overview-finish-zone', self.index_src)


class TestFinishGate(unittest.TestCase):
    """F-G1: renders ONLY when writeEnabled AND work.lifecycle === 'Running'."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_write_gate_and_lifecycle_gate_both_present_after_clear(self):
        snippet = _slice_fn(self.src, 'function _renderFinishControl(work, writeEnabled) {', window=2200)
        self.assertIsNotNone(snippet)
        clear_idx = snippet.find("container.innerHTML = '';")
        write_gate_idx = snippet.find('if (!writeEnabled) return;')
        lifecycle_gate_idx = snippet.find("if (work.lifecycle !== 'Running') return;")
        btn_idx = snippet.find('overview-finish-btn')
        self.assertNotEqual(clear_idx, -1)
        self.assertNotEqual(write_gate_idx, -1)
        self.assertNotEqual(lifecycle_gate_idx, -1)
        self.assertNotEqual(btn_idx, -1)
        self.assertLess(clear_idx, write_gate_idx, "container must be cleared BEFORE the write gate")
        self.assertLess(write_gate_idx, lifecycle_gate_idx)
        self.assertLess(lifecycle_gate_idx, btn_idx, "the button must be built AFTER (inside) both gates")

    def test_render_work_header_passes_model_write_enabled(self):
        idx = self.src.find('function renderWorkHeader(work, model)')
        snippet = self.src[idx:idx + 6000]
        self.assertIn('_renderFinishControl(work, model && model.write_enabled === true);', snippet)


class TestFinishConfirmAndOpDispatch(unittest.TestCase):
    """F-C1/F-OP1: plain window.confirm() with the exact copy; postOp shape."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_plain_confirm_used_with_exact_copy(self):
        snippet = _slice_fn(self.src, 'function _renderFinishControl(work, writeEnabled) {', window=2200)
        self.assertIn(
            "if (!window.confirm('Finish this pipeline? This marks it Completed and stops any running work.')) return;",
            snippet,
        )

    def test_confirm_is_a_plain_confirm_not_a_modal(self):
        # No <dialog>/modal machinery anywhere in the Finish section (distinct
        # from FR-PL3 Delete's type-to-confirm dialog).
        idx_start = self.src.find('// Pipeline Finish (feature-008-execution-control, task-030): a write-gated,')
        idx_end = self.src.find('// Danger zone (feature-009-pipeline-delete, task-026):', idx_start)
        self.assertNotEqual(idx_start, -1)
        self.assertNotEqual(idx_end, -1)
        section = self.src[idx_start:idx_end]
        self.assertNotIn("document.createElement('dialog')", section)
        self.assertNotIn('showModal', section)

    def test_op1_post_op_call_shape(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineFinish(work) {', window=1200)
        self.assertIsNotNone(snippet)
        self.assertIn(
            "postOp('pipeline.finish', { work_id: work.work_id }, {}, function (result) {",
            snippet,
        )

    def test_op1_no_args_payload_beyond_empty_object(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineFinish(work) {', window=1200)
        self.assertRegex(snippet, r"postOp\('pipeline\.finish', \{ work_id: work\.work_id \}, \{\},")


class TestFinishSuccessAndFailurePaths(unittest.TestCase):
    """F-RR: success -> _refetchModelForHeader(); failure -> inline error,
    NO navigation, NO optimistic flip."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_success_path_refetches_and_clears_state(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineFinish(work) {', window=1200)
        self.assertIn('finishPipelineState.workId = null;', snippet)
        self.assertIn('finishPipelineState.errorMessage = null;', snippet)
        self.assertIn('_refetchModelForHeader();', snippet)

    def test_failure_path_sets_error_and_forces_rerender_without_refetch(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineFinish(work) {', window=2000)
        else_idx = snippet.find('} else {')
        self.assertNotEqual(else_idx, -1)
        else_branch = snippet[else_idx:snippet.find('\n    });', else_idx)]
        self.assertIn('finishPipelineState.errorMessage =', else_branch)
        self.assertIn('_renderFinishControl(', else_branch)
        self.assertNotIn('_refetchModelForHeader', else_branch)
        self.assertNotIn("location.hash", else_branch)

    def test_error_message_rendered_inline_when_present(self):
        snippet = _slice_fn(self.src, 'function _renderFinishControl(work, writeEnabled) {', window=2500)
        self.assertIn('if (finishPipelineState.errorMessage && finishPipelineState.workId === work.work_id) {', snippet)
        self.assertIn("err.className = 'callout err';", snippet)


class TestFinishExplicitRenderGuardBypass(unittest.TestCase):
    """F-GB: regression coverage for the delivery-001 dogfood bug (commit
    41ea5d28) -- consumed BEFORE the guard's saving check; set before every
    render call made while entering saving / the post-failure re-render."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_consume_helper_defined_and_reads_then_clears(self):
        idx = self.src.find('function _consumeFinishExplicitRender()')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('_finishExplicitRender = false;', snippet)
        self.assertIn('return v;', snippet)

    def test_guard_consumes_flag_before_checking_saving(self):
        snippet = _slice_fn(self.src, 'function _renderFinishControl(work, writeEnabled) {', window=1200)
        self.assertIn(
            'if (!_consumeFinishExplicitRender() && finishPipelineState.saving &&',
            snippet,
        )

    def test_submit_finish_sets_flag_before_saving_render(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineFinish(work) {', window=800)
        idx_saving = snippet.find('finishPipelineState.saving = true;')
        idx_flag = snippet.find('_finishExplicitRender = true;', idx_saving)
        idx_render = snippet.find('_renderFinishControl(', idx_saving)
        self.assertNotEqual(idx_saving, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_saving, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_submit_finish_failure_path_also_forces_render(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineFinish(work) {', window=2000)
        idx_err = snippet.find('finishPipelineState.errorMessage = (result.body')
        idx_flag = snippet.find('_finishExplicitRender = true;', idx_err)
        idx_render = snippet.find('_renderFinishControl(', idx_err)
        self.assertNotEqual(idx_err, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_err, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_poll_loop_call_site_is_unconditional(self):
        idx_fn = self.src.find('function renderWorkHeader(work, model)')
        snippet = self.src[idx_fn:idx_fn + 6000]
        call_idx = snippet.find('_renderFinishControl(work, model && model.write_enabled === true);')
        self.assertNotEqual(call_idx, -1)
        preceding = snippet[max(0, call_idx - 200):call_idx]
        self.assertNotIn('_finishExplicitRender = true', preceding)


class TestStopResumeSharedBuilder(unittest.TestCase):
    """T-S1: the SAME shared builder is used by both the chip AND the drill
    view, so both stay in lockstep."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_builder_defined_with_documented_signature(self):
        self.assertIn('function _buildTaskStopResumeControl(workId, task, writeEnabled)', self.src)

    def test_make_task_chip_calls_shared_builder(self):
        snippet = _slice_fn(self.src, 'function makeTaskChip(task, workId, writeEnabled) {', window=3000)
        self.assertIsNotNone(snippet)
        self.assertIn('_buildTaskStopResumeControl(workId, task, writeEnabled === true)', snippet)

    def test_render_task_view_calls_shared_builder(self):
        snippet = _slice_fn(self.src, 'function renderTaskView(model, route) {', window=5000)
        self.assertIsNotNone(snippet)
        self.assertIn('_buildTaskStopResumeControl(workId, task, taskWriteEnabled)', snippet)

    def test_make_task_chip_signature_threads_write_enabled(self):
        self.assertIn('function makeTaskChip(task, workId, writeEnabled) {', self.src)
        # No leftover 2-arg call sites anywhere (renderLanes' two call sites
        # must both forward writeEnabled as a third argument).
        self.assertNotIn('makeTaskChip(lTasks[uti], workId));', self.src)
        self.assertNotIn('makeTaskChip(lTasks[ti], workId));', self.src)

    def test_render_tasks_chain_threads_write_enabled(self):
        self.assertIn('function renderTasks(work, writeEnabled) {', self.src)
        self.assertIn('function renderTasksFull(container, tasks, workId, writeEnabled) {', self.src)
        self.assertIn('function renderLanes(container, tasks, deliveryNum, workId, writeEnabled) {', self.src)
        snippet = _slice_fn(self.src, 'function renderWorkView(work, model) {', window=400)
        self.assertIn('renderTasks(work, model.write_enabled === true);', snippet)


class TestStopResumeAC6Gate(unittest.TestCase):
    """T-G1: the control renders IFF task.status === 'In Progress' &&
    writeEnabled -- verified explicitly for every OTHER status, INCLUDING
    'In Review' (the deliberate narrowing below the chip's own "active" set)."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_gate_returns_null_unless_in_progress_and_write_enabled(self):
        snippet = _slice_fn(self.src, 'function _buildTaskStopResumeControl(workId, task, writeEnabled) {', window=400)
        self.assertIn("if (task.status !== 'In Progress' || !writeEnabled) return null;", snippet)

    def test_gate_excludes_every_non_in_progress_status_explicitly(self):
        # The single condition above is a closed IFF gate; assert each excluded
        # status individually so the exclusion set (including In Review) is
        # spelled out in the test, not just implied by the one-line condition.
        excluded_statuses = ['Pending', 'Blocked', 'Done', 'Failed', 'Canceled', 'In Review']
        gate_line = "if (task.status !== 'In Progress' || !writeEnabled) return null;"
        self.assertIn(gate_line, self.src)
        for status in excluded_statuses:
            with self.subTest(status=status):
                # None of these literal status strings appear as a positive
                # match condition anywhere in the gate (only the single
                # 'In Progress' comparison governs visibility).
                self.assertNotIn(f"task.status === '{status}'", self.src[
                    self.src.find('function _buildTaskStopResumeControl('):
                    self.src.find('function _submitTaskStopResume(')
                ])

    def test_in_review_deliberately_excluded_documented(self):
        # The rationale comment precedes the function signature (documenting
        # WHY the gate is written the way it is), so anchor on the comment
        # itself rather than the function body.
        snippet = _slice_fn(self.src, '// Build the Stop/Resume toggle for a task.', window=1200)
        self.assertIsNotNone(snippet)
        self.assertIn('In Review is DELIBERATELY', snippet)
        self.assertIn("its executor has already", snippet)
        self.assertIn('function _buildTaskStopResumeControl(workId, task, writeEnabled) {', snippet)

    def test_write_disabled_hides_control_even_when_in_progress(self):
        # Static equivalent of "writeEnabled=false -> null": the gate's OR
        # condition short-circuits on !writeEnabled regardless of status.
        snippet = _slice_fn(self.src, 'function _buildTaskStopResumeControl(workId, task, writeEnabled) {', window=250)
        self.assertIn('|| !writeEnabled) return null;', snippet)


class TestStopResumeLabelActionFlip(unittest.TestCase):
    """T-L1: false -> "Stop"/task.stop; true -> "Resume"/task.resume."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_is_paused_derived_from_stop_requested(self):
        snippet = _slice_fn(self.src, 'function _buildTaskStopResumeControl(workId, task, writeEnabled) {', window=600)
        self.assertIn('var isPaused = task.stop_requested === true;', snippet)

    def test_label_flip_present(self):
        snippet = _slice_fn(self.src, 'function _buildTaskStopResumeControl(workId, task, writeEnabled) {', window=1200)
        self.assertIn(
            "btn.textContent = thisSaving ? (isPaused ? 'Resuming…' : 'Stopping…') : (isPaused ? 'Resume' : 'Stop');",
            snippet,
        )

    def test_op_flip_present(self):
        snippet = _slice_fn(self.src, 'function _buildTaskStopResumeControl(workId, task, writeEnabled) {', window=2000)
        self.assertIn(
            "_submitTaskStopResume(workId, task, detailKey, isPaused ? 'task.resume' : 'task.stop');",
            snippet,
        )


class TestPausedPill(unittest.TestCase):
    """T-P1: a decorative badge distinct from the status badge, shown
    ALONGSIDE it (never instead), and independent of write_enabled."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_pill_factory_defined(self):
        snippet = _slice_fn(self.src, 'function makeStopRequestedPill() {', window=300)
        self.assertIsNotNone(snippet)
        self.assertIn("pill.className = 'badge badge-warn';", snippet)
        self.assertIn("Paused", snippet)

    def test_pill_factory_distinct_from_status_badge_factory(self):
        self.assertNotEqual(
            self.src.find('function makeStopRequestedPill()'),
            self.src.find('function makeTaskStatusBadge('),
        )

    def test_chip_shows_pill_independent_of_write_enabled(self):
        snippet = _slice_fn(self.src, 'function makeTaskChip(task, workId, writeEnabled) {', window=3200)
        self.assertIn(
            "var isPaused = task.status === 'In Progress' && task.stop_requested === true;",
            snippet,
        )
        # isPaused governs the pill append UNCONDITIONALLY on writeEnabled --
        # the write-gate only governs stopResumeBtn (via the shared builder).
        self.assertIn('if (isPaused) actionsRow.appendChild(makeStopRequestedPill());', snippet)

    def test_drill_view_shows_pill_alongside_status_badge_not_instead(self):
        snippet = _slice_fn(self.src, 'function renderTaskView(model, route) {', window=5000)
        idx_status_badge = snippet.find('headerDiv.appendChild(makeTaskStatusBadge(task.status));')
        idx_pill = snippet.find('headerDiv.appendChild(makeStopRequestedPill());')
        self.assertNotEqual(idx_status_badge, -1)
        self.assertNotEqual(idx_pill, -1)
        self.assertLess(idx_status_badge, idx_pill, "status badge must still render; pill is additive, not a replacement")


class TestStopResumeOpDispatch(unittest.TestCase):
    """T-OP1: postOp(op, {work_id, task_id[, delivery_id]}, {}, ...) --
    delivery_id forwarded only when task.delivery is set (task.rename's
    identical convention)."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_target_shape_built_before_post(self):
        snippet = _slice_fn(self.src, 'function _submitTaskStopResume(workId, task, detailKey, op) {', window=1200)
        self.assertIsNotNone(snippet)
        self.assertIn("var target = { work_id: workId, task_id: task.task_id };", snippet)
        self.assertIn('if (task.delivery != null) target.delivery_id = task.delivery;', snippet)

    def test_post_op_call_shape(self):
        snippet = _slice_fn(self.src, 'function _submitTaskStopResume(workId, task, detailKey, op) {', window=1200)
        self.assertIn('postOp(op, target, {}, function (result) {', snippet)

    def test_click_handler_computes_op_name_and_delegates(self):
        snippet = _slice_fn(self.src, 'function _buildTaskStopResumeControl(workId, task, writeEnabled) {', window=1600)
        self.assertIn('btn.addEventListener(\'click\', function (e) {', snippet)
        self.assertIn('_submitTaskStopResume(workId, task, detailKey,', snippet)


class TestStopResumeReRender(unittest.TestCase):
    """T-RR: success -> _refetchModelForHeader() (re-derives stop_requested
    from disk); failure -> inline error + _rerenderCurrentRoute(), no
    optimistic client-side flip anywhere."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_success_path_refetches(self):
        snippet = _slice_fn(self.src, 'function _submitTaskStopResume(workId, task, detailKey, op) {', window=1200)
        self.assertIn('_refetchModelForHeader();', snippet)

    def test_failure_path_sets_error_and_rerenders_without_refetch(self):
        snippet = _slice_fn(self.src, 'function _submitTaskStopResume(workId, task, detailKey, op) {', window=1200)
        else_idx = snippet.find('} else {')
        self.assertNotEqual(else_idx, -1)
        else_branch = snippet[else_idx:snippet.find('\n    });', else_idx)]
        self.assertIn('taskControlState.errorMessage =', else_branch)
        self.assertIn('_rerenderCurrentRoute();', else_branch)
        self.assertNotIn('_refetchModelForHeader', else_branch)

    def test_no_optimistic_stop_requested_mutation_anywhere(self):
        # The client never writes task.stop_requested = ... itself -- the flag
        # is exclusively reader-derived (task-029) and only ever READ (===)
        # here. Excludes the READ comparisons (=== / !==) via a negative
        # lookahead so this doesn't false-positive on `task.stop_requested === true`.
        idx_start = self.src.find('function _buildTaskStopResumeControl(')
        idx_end = self.src.find('function makeTaskChip(')
        section = self.src[idx_start:idx_end]
        self.assertIsNone(
            re.search(r'\.stop_requested\s*=(?!=)', section),
            "found an apparent ASSIGNMENT (not comparison) to .stop_requested",
        )
        self.assertNotIn('stop_requested:', section)


class TestStopResumeNavigationGuard(unittest.TestCase):
    """T-NAV: the toggle's click handler stops propagation so it never ALSO
    triggers the chip's own SEAM-2 drill-nav onclick."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_stop_propagation_called_in_click_handler(self):
        snippet = _slice_fn(self.src, 'function _buildTaskStopResumeControl(workId, task, writeEnabled) {', window=1600)
        self.assertIn('if (e) e.stopPropagation();', snippet)

    def test_chip_still_has_its_own_drill_nav_onclick(self):
        snippet = _slice_fn(self.src, 'function makeTaskChip(task, workId, writeEnabled) {', window=800)
        self.assertIn("location.hash = '#/work/' + encodeURIComponent(wid) + '/task/' + encodeURIComponent(tid);", snippet)


class TestStopResumeExplicitRenderGuardBypass(unittest.TestCase):
    """T-GB: regression coverage for the delivery-001 dogfood bug (commit
    41ea5d28), applied to BOTH render sites (chip grid + drill view) sharing
    ONE flag."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_consume_helper_defined_and_reads_then_clears(self):
        idx = self.src.find('function _consumeTaskControlExplicitRender()')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('_taskControlExplicitRender = false;', snippet)
        self.assertIn('return v;', snippet)

    def test_render_tasks_guard_consumes_flag_before_checking_saving(self):
        snippet = _slice_fn(self.src, 'function renderTasks(work, writeEnabled) {', window=800)
        self.assertIn(
            'if (!_consumeTaskControlExplicitRender() && taskControlState.saving &&',
            snippet,
        )

    def test_render_task_view_guard_consumes_flag_before_checking_saving(self):
        snippet = _slice_fn(self.src, 'function renderTaskView(model, route) {', window=1600)
        self.assertIn('if (!_consumeTaskControlExplicitRender()) {', snippet)
        self.assertIn('if (taskControlState.saving && taskControlState.key === detailKey) {', snippet)

    def test_submit_sets_flag_before_forced_rerender(self):
        snippet = _slice_fn(self.src, 'function _submitTaskStopResume(workId, task, detailKey, op) {', window=800)
        idx_saving = snippet.find('taskControlState.saving = true;')
        idx_flag = snippet.find('_taskControlExplicitRender = true;', idx_saving)
        idx_render = snippet.find('_rerenderCurrentRoute();', idx_saving)
        self.assertNotEqual(idx_saving, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_saving, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_submit_failure_path_also_forces_rerender(self):
        snippet = _slice_fn(self.src, 'function _submitTaskStopResume(workId, task, detailKey, op) {', window=1200)
        idx_err = snippet.find('taskControlState.errorMessage = (result.body')
        idx_flag = snippet.find('_taskControlExplicitRender = true;', idx_err)
        idx_render = snippet.find('_rerenderCurrentRoute();', idx_err)
        self.assertNotEqual(idx_err, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_err, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_render_tasks_poll_call_site_is_unconditional(self):
        idx_fn = self.src.find('function renderWorkView(work, model) {')
        snippet = self.src[idx_fn:idx_fn + 400]
        call_idx = snippet.find('renderTasks(work, model.write_enabled === true);')
        self.assertNotEqual(call_idx, -1)
        preceding = snippet[max(0, call_idx - 150):call_idx]
        self.assertNotIn('_taskControlExplicitRender = true', preceding)


class TestWriteEnabledHidesAllNewControls(unittest.TestCase):
    """WG: defense-in-depth -- write_enabled === false hides the Finish
    button AND the Stop/Resume toggle (but not the informational paused
    pill)."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_finish_control_early_returns_on_write_disabled(self):
        snippet = _slice_fn(self.src, 'function _renderFinishControl(work, writeEnabled) {', window=1500)
        self.assertIn('if (!writeEnabled) return;', snippet)

    def test_stop_resume_builder_returns_null_on_write_disabled(self):
        snippet = _slice_fn(self.src, 'function _buildTaskStopResumeControl(workId, task, writeEnabled) {', window=250)
        self.assertIn('!writeEnabled) return null;', snippet)

    def test_pill_visibility_does_not_read_write_enabled(self):
        # The isPaused computation (which gates the pill) has no writeEnabled
        # term -- it is derived purely from task.status/task.stop_requested.
        snippet = _slice_fn(self.src, 'function makeTaskChip(task, workId, writeEnabled) {', window=3200)
        is_paused_line = "var isPaused = task.status === 'In Progress' && task.stop_requested === true;"
        self.assertIn(is_paused_line, snippet)
        self.assertNotIn('writeEnabled', is_paused_line)


if __name__ == "__main__":
    unittest.main()
