"""
test_task026_delete_pipeline_ui.py -- Static/DOM assertions for the Danger-zone
Delete UI + type-to-confirm modal (task-026, feature-009-pipeline-delete,
delivery-004, work-017-cli-improvements) in dashboard/home.html.

Mirrors test_task022_connectors_external_sources_ui.py's / test_home_html_
project_header.py's established convention for this codebase: no browser/
jsdom required. Tests inspect the HTML/JS source text and verify presence/
placement/order of the new markup and functions -- never execute the
client-side JS. (The server-side pipeline.delete OP_TABLE row, status_map,
argv-builder, and dispatch-validation order are task-025's own scope, already
covered by test_task025_pipeline_delete_ops.py/.mjs; this file covers ONLY the
UI half task-026 adds on top of that.)

  S1  -- Structural: #overview-danger-zone container is the LAST child of
          #work-overview-body, and _renderDangerZone is called as the LAST
          statement of renderWorkHeader.
  S2  -- Structural: _renderDangerZone/_buildDeleteModal are defined ONLY once
          and are NEVER referenced from _renderWorkCard (the main-grid card)
          or dashboard/index.html (the all-projects page) -- the destructive
          control lives ONLY on the per-pipeline detail route.
  G1  -- Gate: the entire Danger zone (including the button) is built INSIDE
          an `if (!writeEnabled) return;` early-return, so a read-only model
          renders an empty container.
  M1  -- Modal: worktree-agnostic copy -- keyed only on work_id; no
          `branch_label` read anywhere in the new code; no hardcoded
          `.claude/worktrees` path literal anywhere in home.html.
  M2  -- Modal: the two verbatim copy strings (conditional-outcome sentence +
          irreversibility warning) are present byte-for-byte.
  M3  -- Modal: accessibility -- role="dialog", aria-modal, aria-label,
          aria-labelledby -> a real heading id, explicit destructive Confirm
          label built from work_id, a Tab-trap keydown handler, a native
          'cancel' (Esc) handler, and a backdrop-click (`e.target === dlg`)
          handler, all present.
  M4  -- Modal: type-to-confirm gate -- Confirm's `disabled` is computed from
          `typedValue !== workId` at BOTH build time and on every input event;
          Cancel/Esc/backdrop all route through the SAME no-side-effect close
          function, which resets state and returns focus to the Delete
          button.
  OP1 -- Ops: Confirm dispatches postOp('pipeline.delete', {work_id:
          work.work_id}, {}, ...) -- the documented target shape.
  OP2 -- Ops: on success, the modal closes, `location.hash` is cleared, and
          doFetch() runs (AC2); on failure the modal stays open (no hash
          change, no doFetch) and the inline copy is keyed off the server's
          `error` code for the two named cases (409 pipeline-active / 404
          not-found).
  GB  -- Regression coverage (delivery-001 dogfood fix, commit 41ea5d28, and
          task-022's identical fix applied to a MODAL instead of an inline
          editor): the explicit-render one-shot bypass flag is present and
          consumed BEFORE the guard's `deleteModalState.open` check, and is
          set before every render call made while opening/keeping the modal
          open (button click, Confirm's in-flight `saving` transition, and the
          post-failure re-render).
  RC  -- Route-change safety: a route change to a DIFFERENT work_id while the
          modal is open resets deleteModalState instead of preserving it.

NOTE (test-infrastructure gap, same as test_task022_connectors_external_
sources_ui.py's / test_home_html_project_header.py's TestEditEntryGuardBypass):
every test in this file is a static source-text parse. It asserts the guard/
bypass wiring, the copy strings, and the op-dispatch call sites are present
and correctly ordered, but it does NOT execute a click handler or the render
functions in a real DOM, so it CANNOT itself observe that clicking "Delete
pipeline" in a real browser actually opens the dialog, traps focus, or that
Tab/Shift+Tab correctly cycles between the input/Cancel/Confirm elements.
This codebase has no jsdom/DOM-executing harness for home.html (only
source-text parses) -- runtime behavior (does the modal actually OPEN and
STAY open across a poll tick, does focus really move in/trap/return) is the
browser-dogfood's job at the delivery-004 gate.

Python 3.11+ stdlib only. Deterministic.
"""

import re
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # AID/
_HOME_HTML = _REPO_ROOT / "dashboard" / "home.html"
_INDEX_HTML = _REPO_ROOT / "dashboard" / "index.html"


def _slice_fn(src, fn_signature, window=6000):
    idx = src.find(fn_signature)
    if idx == -1:
        return None
    return src[idx:idx + window]


class TestStructuralPlacement(unittest.TestCase):
    """S1: container placement + call-site ordering inside renderWorkHeader."""

    @classmethod
    def setUpClass(cls):
        assert _HOME_HTML.is_file(), f"dashboard/home.html not found at {_HOME_HTML}"
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_s1_danger_zone_container_present(self):
        self.assertIn('id="overview-danger-zone"', self.src)

    def test_s1_container_is_last_child_of_work_overview_body(self):
        idx_body_open = self.src.find('id="work-overview-body"')
        idx_container = self.src.find('id="overview-danger-zone"')
        idx_body_close = self.src.find('/#work-overview-body', idx_container)
        self.assertNotEqual(idx_body_open, -1)
        self.assertNotEqual(idx_container, -1)
        self.assertNotEqual(idx_body_close, -1)
        self.assertLess(idx_body_open, idx_container)
        self.assertLess(idx_container, idx_body_close)
        # No OTHER work-overview-body child markup between the danger-zone
        # container and the closing comment (confirms it is the LAST child).
        between = self.src[idx_container:idx_body_close]
        self.assertNotIn('id="overview-', between.replace('id="overview-danger-zone"', ''))

    def test_s1_render_work_header_calls_render_danger_zone_last(self):
        idx = self.src.find('function renderWorkHeader(work, model)')
        self.assertNotEqual(idx, -1)
        idx_end = self.src.find('\n  }', idx)
        snippet = self.src[idx:idx_end]
        self.assertIn('_renderDangerZone(work, model && model.write_enabled === true);', snippet)
        # It must be the LAST call in the function body (nothing after it but
        # the closing brace).
        call_idx = snippet.rfind('_renderDangerZone(')
        remainder = snippet[call_idx:]
        # Only the call's own statement + trailing whitespace/comments remain.
        self.assertNotIn('_render', remainder.split(';', 1)[1])

    def test_s1_render_functions_defined_with_documented_signature(self):
        self.assertIn('function _renderDangerZone(work, writeEnabled)', self.src)
        self.assertIn('function _buildDeleteModal(work)', self.src)
        self.assertIn('function _closeDeleteModal(work)', self.src)
        self.assertIn('function _submitPipelineDelete(work)', self.src)


class TestDetailRouteOnly(unittest.TestCase):
    """S2: the destructive control is NEVER wired into the main-grid card or
    dashboard/index.html -- pipeline-level ops live on the detail page only."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")
        assert _INDEX_HTML.is_file()
        cls.index_src = _INDEX_HTML.read_text(encoding="utf-8")

    def test_render_work_card_never_calls_danger_zone(self):
        idx = self.src.find('function _renderWorkCard(work)')
        self.assertNotEqual(idx, -1)
        idx_end = self.src.find('\n  function ', idx + 10)
        snippet = self.src[idx:idx_end]
        self.assertNotIn('_renderDangerZone', snippet)
        self.assertNotIn('btn-danger', snippet)
        self.assertNotIn('pipeline.delete', snippet)

    def test_index_html_has_no_delete_affordance(self):
        self.assertNotIn('pipeline.delete', self.index_src)
        self.assertNotIn('_renderDangerZone', self.index_src)
        self.assertNotIn('btn-danger', self.index_src)

    def test_danger_zone_css_class_defined_once(self):
        self.assertEqual(self.src.count('.btn-danger {'), 1)


class TestWriteEnabledGate(unittest.TestCase):
    """G1: the whole Danger zone (button included) renders ONLY when
    write_enabled === true; a read-only model gets an EMPTY container."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_g1_early_return_on_read_only(self):
        snippet = _slice_fn(self.src, 'function _renderDangerZone(work, writeEnabled) {', window=1500)
        self.assertIsNotNone(snippet)
        self.assertIn('container.innerHTML = \'\';', snippet)
        self.assertIn('if (!writeEnabled) return;', snippet)
        clear_idx = snippet.find("container.innerHTML = '';")
        gate_idx = snippet.find('if (!writeEnabled) return;')
        btn_idx = snippet.find("danger-zone-delete-btn")
        self.assertNotEqual(clear_idx, -1)
        self.assertNotEqual(gate_idx, -1)
        self.assertNotEqual(btn_idx, -1)
        self.assertLess(clear_idx, gate_idx, "container must be cleared BEFORE the write gate")
        self.assertLess(gate_idx, btn_idx, "the Delete button must be built AFTER (inside) the write gate")

    def test_g1_render_work_header_passes_model_write_enabled(self):
        idx = self.src.find('function renderWorkHeader(work, model)')
        snippet = self.src[idx:idx + 6000]
        self.assertIn('_renderDangerZone(work, model && model.write_enabled === true);', snippet)


class TestModalWorktreeAgnostic(unittest.TestCase):
    """M1/M2: worktree-agnostic copy, verbatim strings, no branch_label/path."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_m1_no_branch_label_read_anywhere_in_new_code(self):
        idx = self.src.find('function _renderDangerZone(')
        self.assertNotEqual(idx, -1)
        # From the Danger-zone section through the end of the delete-modal
        # machinery (bounded by the next unrelated section comment). The word
        # "branch_label" MAY appear in an explanatory COMMENT (documenting why
        # it is deliberately not read, mirroring the SPEC.md rationale) -- what
        # must never appear is an actual PROPERTY-ACCESS read of it off the
        # work/model object.
        idx_end = self.src.find('// Attention strip (UI-4', idx)
        self.assertNotEqual(idx_end, -1)
        snippet = self.src[idx:idx_end]
        self.assertNotIn('work.branch_label', snippet)
        self.assertNotIn('.branch_label]', snippet)
        self.assertNotIn("['branch_label']", snippet)
        self.assertNotIn('branchLabel', snippet)

    def test_m1_no_hardcoded_worktree_path_literal(self):
        idx = self.src.find('function _buildDeleteModal(work)')
        self.assertNotEqual(idx, -1)
        idx_end = self.src.find('function _submitPipelineDelete(', idx)
        snippet = self.src[idx:idx_end]
        self.assertNotIn('.claude/worktrees', snippet)

    def test_m2_conditional_outcome_copy_verbatim(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=3500)
        self.assertIsNotNone(snippet)
        self.assertIn("'This removes the work folder .aid/works/' + workId +", snippet)
        self.assertIn(
            "'. If this pipeline has its own worktree, that worktree is removed too; ' +",
            snippet,
        )
        self.assertIn(
            "'a worktree shared with other pipelines is kept. The git branch is not deleted.';",
            snippet,
        )

    def test_m2_irreversibility_warning_verbatim(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=3500)
        self.assertIn(
            "'This permanently deletes the pipeline. Any work not pushed ' +",
            snippet,
        )
        self.assertIn("'to git will be lost and cannot be recovered.';", snippet)

    def test_m2_modal_reads_only_work_id_field_off_work_object(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=200)
        self.assertIn('var workId = work.work_id;', snippet)


class TestModalAccessibility(unittest.TestCase):
    """M3: role/aria wiring, destructive Confirm label, Tab-trap, Esc, backdrop."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_m3_dialog_element_used(self):
        self.assertIn("var dlg = document.createElement('dialog');", self.src)
        self.assertIn("dlg.id = 'delete-pipeline-modal';", self.src)

    def test_m3_role_and_aria_attributes_set(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=1200)
        self.assertIn("dlg.setAttribute('role', 'dialog');", snippet)
        self.assertIn("dlg.setAttribute('aria-modal', 'true');", snippet)
        self.assertIn("dlg.setAttribute('aria-label', 'Delete pipeline ' + workId);", snippet)
        self.assertIn("dlg.setAttribute('aria-labelledby', 'delete-modal-heading');", snippet)
        self.assertIn("heading.id = 'delete-modal-heading';", snippet)

    def test_m3_confirm_button_carries_destructive_label(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=4000)
        self.assertIn("confirmBtn.textContent = deleteModalState.saving ? 'Deleting…' : 'Delete ' + workId;", snippet)

    def test_m3_tab_trap_present(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=6000)
        self.assertIn("if (e.key !== 'Tab') return;", snippet)
        self.assertIn('dlg.querySelectorAll(', snippet)
        self.assertIn('document.activeElement === first', snippet)
        self.assertIn('document.activeElement === last', snippet)

    def test_m3_native_cancel_event_wired_for_esc(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=6000)
        self.assertIn(
            "dlg.addEventListener('cancel', function (e) { e.preventDefault(); _closeDeleteModal(work); });",
            snippet,
        )

    def test_m3_backdrop_click_closes(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=6000)
        self.assertIn('if (e.target === dlg) _closeDeleteModal(work);', snippet)

    def test_m3_focus_moves_into_modal_on_open(self):
        snippet = _slice_fn(self.src, 'function _renderDangerZone(work, writeEnabled) {', window=3500)
        self.assertIn("var input = document.getElementById('delete-confirm-input');", snippet)
        self.assertIn('if (input) input.focus();', snippet)

    def test_m3_focus_returns_to_delete_button_on_close(self):
        snippet = _slice_fn(self.src, 'function _closeDeleteModal(work) {', window=800)
        self.assertIn("var delBtn = document.getElementById('danger-zone-delete-btn');", snippet)
        self.assertIn('if (delBtn) delBtn.focus();', snippet)


class TestTypeToConfirmGate(unittest.TestCase):
    """M4: Confirm stays disabled until typed === work_id; Cancel/Esc/backdrop
    all route through the SAME no-side-effect close."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_m4_confirm_disabled_at_build_time(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=4000)
        self.assertIn(
            "confirmBtn.disabled = (deleteModalState.typedValue !== workId) || deleteModalState.saving;",
            snippet,
        )

    def test_m4_confirm_disabled_recomputed_on_input(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=6000)
        self.assertIn(
            "confirmBtn.disabled = (input.value !== workId) || deleteModalState.saving;",
            snippet,
        )
        # The input listener must WRITE typedValue back into state too (so a
        # forced rebuild -- e.g. the post-failure error redraw -- restores it).
        self.assertIn('deleteModalState.typedValue = input.value;', snippet)

    def test_m4_confirm_click_is_a_no_op_while_disabled(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=6000)
        self.assertIn('if (confirmBtn.disabled) return;', snippet)
        self.assertIn('_submitPipelineDelete(work);', snippet)

    def test_m4_cancel_button_routes_through_close_delete_modal(self):
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=4000)
        self.assertIn(
            "cancelBtn.addEventListener('click', function () { _closeDeleteModal(work); });",
            snippet,
        )

    def test_m4_close_delete_modal_resets_state_with_no_side_effect(self):
        snippet = _slice_fn(self.src, 'function _closeDeleteModal(work) {', window=800)
        self.assertIsNotNone(snippet)
        self.assertIn('deleteModalState.open = false;', snippet)
        self.assertIn("deleteModalState.typedValue = '';", snippet)
        self.assertIn('deleteModalState.errorMessage = null;', snippet)
        # No fetch()/postOp() call anywhere in the close path -- confirms "no
        # side effect".
        self.assertNotIn('postOp(', snippet)
        self.assertNotIn('fetch(', snippet)


class TestOpDispatch(unittest.TestCase):
    """OP1: Confirm dispatches the documented pipeline.delete op shape."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_op1_post_op_call_shape(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineDelete(work) {', window=1500)
        self.assertIsNotNone(snippet)
        self.assertIn(
            "postOp('pipeline.delete', { work_id: work.work_id }, {}, function (result) {",
            snippet,
        )

    def test_op1_no_args_payload_beyond_empty_object(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineDelete(work) {', window=1500)
        # The postOp args parameter is the literal empty object -- delete takes
        # no parameters (SPEC.md API Contracts).
        self.assertRegex(snippet, r"postOp\('pipeline\.delete', \{ work_id: work\.work_id \}, \{\},")


class TestSuccessAndFailurePaths(unittest.TestCase):
    """OP2: 200 -> close + hash-clear + doFetch; 4xx/5xx -> stay open + inline copy."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_op2_success_path_closes_clears_hash_and_refetches(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineDelete(work) {', window=1500)
        self.assertIn('deleteModalState.open = false;', snippet)
        self.assertIn("location.hash = '';", snippet)
        self.assertIn('doFetch();', snippet)
        # Ordering: close-state BEFORE navigating BEFORE re-fetching.
        idx_close = snippet.find('deleteModalState.open = false;')
        idx_hash = snippet.find("location.hash = '';")
        idx_fetch = snippet.find('doFetch();')
        self.assertNotEqual(idx_close, -1)
        self.assertNotEqual(idx_hash, -1)
        self.assertNotEqual(idx_fetch, -1)
        self.assertLess(idx_close, idx_hash)
        self.assertLess(idx_hash, idx_fetch)

    def test_op2_failure_path_does_not_navigate_or_refetch(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineDelete(work) {', window=1500)
        else_idx = snippet.find('} else {')
        self.assertNotEqual(else_idx, -1)
        else_branch = snippet[else_idx:]
        # Bounded to the else branch only (up to its own closing brace pair).
        else_branch = else_branch[:else_branch.find('\n    });')]
        self.assertNotIn("location.hash = '';", else_branch)
        self.assertNotIn('doFetch();', else_branch)
        self.assertIn('deleteModalState.errorMessage = _friendlyDeleteError(result.body);', else_branch)

    def test_op2_error_mapping_function_defined(self):
        snippet = _slice_fn(self.src, 'function _friendlyDeleteError(body) {', window=400)
        self.assertIsNotNone(snippet)
        self.assertIn("if (code === 'pipeline-active') return 'This pipeline is Running — Finish it before deleting.';", snippet)
        self.assertIn("if (code === 'not-found') return 'Pipeline not found — it may already be gone.';", snippet)

    def test_op2_error_mapping_keyed_on_body_error_field(self):
        snippet = _slice_fn(self.src, 'function _friendlyDeleteError(body) {', window=200)
        self.assertIn('var code = body && body.error;', snippet)


class TestExplicitRenderGuardBypass(unittest.TestCase):
    """GB: regression coverage for the delivery-001 dogfood bug (commit
    41ea5d28) applied to a MODAL instead of an inline editor -- the guard
    consumes the one-shot flag BEFORE checking deleteModalState.open, and every
    transition that would otherwise be swallowed by that guard sets the flag
    first."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_consume_helper_defined_and_reads_then_clears(self):
        idx = self.src.find('function _consumeDeleteModalExplicitRender()')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('_deleteModalExplicitRender = false;', snippet)
        self.assertIn('return v;', snippet)

    def test_guard_consumes_flag_before_checking_open(self):
        idx = self.src.find('function _renderDangerZone(work, writeEnabled) {')
        snippet = self.src[idx:idx + 1500]
        self.assertIn(
            'if (!_consumeDeleteModalExplicitRender() && deleteModalState.open) return;',
            snippet,
        )

    def test_delete_button_click_sets_flag_before_forced_render(self):
        snippet = _slice_fn(self.src, 'function _renderDangerZone(work, writeEnabled) {', window=2500)
        idx_open = snippet.find('deleteModalState.open = true;')
        idx_flag = snippet.find('_deleteModalExplicitRender = true;', idx_open)
        idx_render = snippet.find('_renderDangerZone(work, writeEnabled);', idx_open)
        self.assertNotEqual(idx_open, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_open, idx_flag)
        self.assertLess(idx_flag, idx_render,
                        "the flag must be set BEFORE the render call it needs to bypass")

    def test_submit_delete_sets_flag_before_saving_render(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineDelete(work) {', window=800)
        idx_saving = snippet.find('deleteModalState.saving = true;')
        idx_flag = snippet.find('_deleteModalExplicitRender = true;', idx_saving)
        idx_render = snippet.find('_renderDangerZone(', idx_saving)
        self.assertNotEqual(idx_saving, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_saving, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_submit_delete_failure_path_also_forces_render(self):
        snippet = _slice_fn(self.src, 'function _submitPipelineDelete(work) {', window=1500)
        idx_err = snippet.find('deleteModalState.errorMessage = _friendlyDeleteError(result.body);')
        idx_flag = snippet.find('_deleteModalExplicitRender = true;', idx_err)
        idx_render = snippet.find('_renderDangerZone(', idx_err)
        self.assertNotEqual(idx_err, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_err, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_poll_loop_call_site_is_unconditional(self):
        # renderWorkHeader's own call site must NOT set the flag beforehand --
        # only the transitions above (button click / saving / failure) may.
        idx_fn = self.src.find('function renderWorkHeader(work, model)')
        snippet = self.src[idx_fn:idx_fn + 6000]
        call_idx = snippet.find('_renderDangerZone(work, model && model.write_enabled === true);')
        self.assertNotEqual(call_idx, -1)
        preceding = snippet[max(0, call_idx - 200):call_idx]
        self.assertNotIn('_deleteModalExplicitRender = true', preceding)

    def test_typed_value_state_is_mirrored_not_only_dom(self):
        # Confirms the typed-confirm input's value is tracked in JS state (the
        # backstop for the one explicit-rebuild-while-open case: a 4xx/5xx
        # inline-error redraw), not left to the DOM node alone.
        snippet = _slice_fn(self.src, 'function _buildDeleteModal(work) {', window=2200)
        self.assertIn('input.value = deleteModalState.typedValue;', snippet)


class TestRouteChangeSafety(unittest.TestCase):
    """RC: a route change to a DIFFERENT work_id while the modal is open resets
    deleteModalState instead of leaking a stale confirmation onto the new
    pipeline's page."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_workid_mismatch_resets_before_guard_check(self):
        idx = self.src.find('function _renderDangerZone(work, writeEnabled) {')
        snippet = self.src[idx:idx + 1500]
        mismatch_idx = snippet.find('deleteModalState.workId !== work.work_id')
        guard_idx = snippet.find('if (!_consumeDeleteModalExplicitRender()')
        self.assertNotEqual(mismatch_idx, -1)
        self.assertNotEqual(guard_idx, -1)
        self.assertLess(mismatch_idx, guard_idx,
                        "the route-mismatch reset must run BEFORE the open-modal guard")

    def test_workid_recorded_on_open(self):
        snippet = _slice_fn(self.src, 'function _renderDangerZone(work, writeEnabled) {', window=2500)
        self.assertIn('deleteModalState.workId = work.work_id;', snippet)


class TestDangerZoneStyling(unittest.TestCase):
    """Reuses .work-overview/.border-err verbatim; only .btn-danger/.confirm-
    modal are new CSS."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_section_reuses_work_overview_border_err(self):
        snippet = _slice_fn(self.src, 'function _renderDangerZone(work, writeEnabled) {', window=1500)
        self.assertIn("section.className = 'work-overview border-err danger-zone';", snippet)

    def test_new_css_classes_defined(self):
        for cls_name in ['.btn-danger', '.confirm-modal', '.confirm-modal::backdrop',
                          '.confirm-modal-actions', '.confirm-modal-warning', '.danger-zone']:
            self.assertIn(cls_name, self.src, f"CSS class {cls_name} missing from home.html")


if __name__ == "__main__":
    unittest.main()
