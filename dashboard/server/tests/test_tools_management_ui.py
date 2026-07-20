"""
test_tools_management_ui.py -- Static/DOM assertions for the project page's
Tools section (work-017 post-dogfood) in dashboard/home.html.

Production context (not a numbered TASK -- a post-dogfood fix on top of the
already-completed work-017 pipeline): per-project host-tool management
(install/update/uninstall a tool against a specific project) moved OFF the
CLI-home repo card (which used to offer a per-repo "Update Tools" button
posting tools.update to '/r/<id>/api/op' -- see test_cli_home_html.py's
TestFeature004UpdateSelfUi docstring for that removal) onto the project
page's own new Tools section, which now ALSO offers Add (tools.add) and
Remove (tools.remove) -- two brand-new project-scoped OP_TABLE rows
(server.py/server.mjs) alongside the pre-existing tools.update row. See
test_task015_tools_update_ops.{py,mjs}'s TestOpTablesToolsAddRemove* groups
for the server-side row/dispatch coverage this file does NOT duplicate; this
file covers ONLY the client-side home.html half.

Mirrors test_task022_connectors_external_sources_ui.py's established
convention for this codebase: no browser/jsdom required. Tests inspect the
HTML/JS source text and verify presence/placement/order of the new markup
and functions -- never execute the client-side JS.

  S1  -- Structural: Tools section (<h2>Tools</h2> + #tools-section) is a
          sibling of the project-header, positioned BETWEEN it and the
          Knowledge Base section; renderMainPage calls
          _renderToolsCard(model, model.write_enabled === true) immediately
          after _renderProjectHeader(model).
  R1  -- Render: installed-tools list ("No tools installed yet." empty state;
          each row reads tool.tools_installed / aid_version).
  G1  -- Gate: Add / Update / Remove are ALL write-gated; the installed list
          itself renders unconditionally (read view).
  OP1 -- Ops: tools.add / tools.update / tools.remove dispatch via postOp()
          with the documented target/args shape; Remove uses a confirm()
          guard; both success AND failure re-fetch the model
          (_refetchModelForHeader).
  GB  -- Regression-shaped coverage (mirrors delivery-001's dogfood-fix
          pattern, commit 41ea5d28 / TestEditEntryGuardBypass in the sibling
          connectors/external-sources suite): the explicit-render one-shot
          bypass flag is present and consumed BEFORE the guard's saving
          check, and is set before every forced render while entering the
          `saving` state.
  GR  -- Graft: onSuccess grafts the envelope-level `tools_catalog` onto the
          model (fail-safe [] when missing/non-array) so _renderToolsCard can
          read model.tools_catalog.
  RA  -- Restart advisory (reviewer follow-up on top of the initial Tools
          section): a successful tools.update captures the pre-update
          aid_version (toolsUiState.restartFromVersion) and _renderToolsCard
          shows a dismiss-free 'callout warn' notice when the re-fetched
          version differs -- `aid update`'s self-update-if-stale preamble can
          rewrite the RUNNING server's own code (KI-002/KI-006), so a
          restart is needed to pick it up. tools.add/tools.remove do NOT run
          that preamble and never touch restartFromVersion.
  N1  -- dashboard/index.html (CLI-home) carries none of these per-project
          ops (tools.add/tools.remove) -- Tools management is project-page
          (home.html) only.

NOTE (test-infrastructure gap, same as the connectors/external-sources
suite): every test here is a static source-text parse; it does not execute a
click handler or the render functions, so it cannot itself observe runtime
DOM behavior in a real browser -- that is the browser-dogfood's job.

Python 3.11+ stdlib only. Deterministic.
"""

import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # AID/
_HOME_HTML = _REPO_ROOT / "dashboard" / "home.html"
_INDEX_HTML = _REPO_ROOT / "dashboard" / "index.html"


class TestStructuralPlacement(unittest.TestCase):
    """S1: section placement + render-call wiring."""

    @classmethod
    def setUpClass(cls):
        assert _HOME_HTML.is_file(), f"dashboard/home.html not found at {_HOME_HTML}"
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_s1_tools_section_container_present(self):
        self.assertIn('id="tools-section"', self.src)

    def test_s1_heading_present(self):
        self.assertIn('>Tools</h2>', self.src)

    def test_s1_order_project_header_then_tools_then_kb(self):
        idx_header = self.src.find('id="project-header"')
        idx_tools = self.src.find('id="tools-section"')
        idx_kb = self.src.find('id="knowledge-tool-section"')
        for name, idx in [("project-header", idx_header), ("tools-section", idx_tools),
                           ("knowledge-tool-section", idx_kb)]:
            self.assertNotEqual(idx, -1, f"{name} container not found")
        self.assertLess(idx_header, idx_tools)
        self.assertLess(idx_tools, idx_kb)

    def test_s1_render_main_page_calls_tools_card_right_after_project_header(self):
        idx = self.src.find('function renderMainPage(model)')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        header_idx = snippet.find('_renderProjectHeader(model);')
        tools_idx = snippet.find('_renderToolsCard(model, model.write_enabled === true);')
        self.assertNotEqual(header_idx, -1)
        self.assertNotEqual(tools_idx, -1)
        self.assertLess(header_idx, tools_idx,
                        "_renderToolsCard must be called immediately after _renderProjectHeader")

    def test_s1_render_function_defined_with_documented_signature(self):
        self.assertIn('function _renderToolsCard(model, writeEnabled)', self.src)

    def test_s1_helper_functions_defined(self):
        for fn in ['function _buildToolRow(', 'function _buildToolAddRow(',
                   'function _forceToolsRender(', 'function _submitToolsAdd(',
                   'function _submitToolsUpdate(', 'function _submitToolsRemove(']:
            self.assertIn(fn, self.src, f"{fn} not found in home.html")


class TestToolsList(unittest.TestCase):
    """R1: the installed-tools list + empty state."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r1_empty_state_line(self):
        self.assertIn('No tools installed yet.', self.src)

    def test_r1_empty_state_gated_on_installed_length(self):
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn('installed.length === 0', snippet)
        self.assertIn('No tools installed yet.', snippet)

    def test_r1_reads_tool_tools_installed_and_aid_version(self):
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn('tool.tools_installed', snippet)
        self.assertIn('tool.aid_version', snippet)

    def test_r1_row_shows_tool_and_version(self):
        idx = self.src.find('function _buildToolRow(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn("toolName + ' v' + version", snippet)

    def test_r1_catalog_read_from_model_tools_catalog(self):
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn('model.tools_catalog', snippet)

    def test_r1_available_excludes_already_installed(self):
        # Window widened 2700 -> 3900 (reviewer follow-up: the restart-advisory
        # block inserted between the error block and the write-gate pushed this
        # string further into the function; 3900 comfortably covers the whole
        # function body, ~3785 chars).
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3900]
        self.assertIn(
            'catalog.filter(function (t) { return installed.indexOf(t) === -1; });',
            snippet,
        )

    def test_r1_all_installed_note(self):
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3900]
        self.assertIn('All available tools are installed.', snippet)


class TestWriteEnabledGate(unittest.TestCase):
    """G1: Add/Update/Remove are write-gated; the installed list is not."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_g1_installed_list_read_before_any_write_gate(self):
        # Window widened 2200 -> 2600 (reviewer follow-up: the restart-advisory
        # block sits between the error block and this write-mode gate).
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2600]
        len_idx = snippet.find('installed.length === 0')
        we_idx = snippet.find('if (writeEnabled) {')
        self.assertNotEqual(len_idx, -1)
        self.assertNotEqual(we_idx, -1)
        self.assertLess(len_idx, we_idx,
                        "the installed-tools read view must render before the write-mode gate")

    def test_g1_update_and_add_inside_write_gate(self):
        # Window widened 3000 -> 3900 (reviewer follow-up: the restart-advisory
        # block pushed the write-gate's own contents further into the function).
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3900]
        we_idx = snippet.find('if (writeEnabled) {')
        update_idx = snippet.find("_submitToolsUpdate()")
        add_idx = snippet.find('_buildToolAddRow(available)')
        self.assertNotEqual(we_idx, -1)
        self.assertNotEqual(update_idx, -1)
        self.assertNotEqual(add_idx, -1)
        self.assertLess(we_idx, update_idx)
        self.assertLess(we_idx, add_idx)

    def test_g1_update_only_offered_when_at_least_one_tool_installed(self):
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3900]
        self.assertIn('installed.length > 0', snippet)

    def test_g1_remove_button_gated_inside_build_tool_row(self):
        idx = self.src.find('function _buildToolRow(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 600]
        guard_idx = snippet.find('if (writeEnabled) {')
        remove_idx = snippet.find("removeBtn.textContent = 'Remove';")
        self.assertNotEqual(guard_idx, -1)
        self.assertNotEqual(remove_idx, -1)
        self.assertLess(guard_idx, remove_idx,
                        "the Remove button must be built INSIDE the writeEnabled guard")

    def test_g1_add_update_remove_disabled_while_saving(self):
        idx_row = self.src.find('function _buildToolRow(')
        snippet_row = self.src[idx_row:idx_row + 800]
        self.assertIn('removeBtn.disabled = toolsUiState.saving;', snippet_row)

        idx_add = self.src.find('function _buildToolAddRow(')
        snippet_add = self.src[idx_add:idx_add + 1200]
        self.assertIn('select.disabled = toolsUiState.saving;', snippet_add)
        self.assertIn('addBtn.disabled = toolsUiState.saving;', snippet_add)

        idx_card = self.src.find('function _renderToolsCard(')
        # Window widened 2500 -> 3900 (reviewer follow-up: the restart-advisory
        # block pushed the Update button's own build code further into the
        # function).
        snippet_card = self.src[idx_card:idx_card + 3900]
        self.assertIn('updateBtn.disabled = toolsUiState.saving;', snippet_card)


class TestToolsOps(unittest.TestCase):
    """OP1: tools.add / tools.update / tools.remove dispatch shape."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_op1_add_uses_post_op_helper_with_tool_arg(self):
        idx = self.src.find('function _submitToolsAdd(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 700]
        self.assertIn("postOp('tools.add', {}, { tool: toolName }, function (result) {", snippet)

    def test_op1_add_short_circuits_on_empty_tool_name(self):
        idx = self.src.find('function _submitToolsAdd(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('if (!toolName) return;', snippet)

    def test_op1_update_uses_post_op_helper_with_empty_args(self):
        # Window widened 500 -> 700 (reviewer follow-up: _submitToolsUpdate now
        # captures preVersion and resets restartFromVersion before dispatch,
        # pushing the postOp() call further into the function).
        idx = self.src.find('function _submitToolsUpdate(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 700]
        self.assertIn("postOp('tools.update', {}, {}, function (result) {", snippet)

    def test_op1_remove_uses_post_op_helper_with_tool_arg(self):
        idx = self.src.find('function _submitToolsRemove(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 500]
        self.assertIn("postOp('tools.remove', {}, { tool: toolName }, function (result) {", snippet)

    def test_op1_remove_uses_window_confirm_guard(self):
        idx = self.src.find('function _buildToolRow(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1100]
        self.assertIn('window.confirm(', snippet)
        confirm_idx = snippet.find('window.confirm(')
        remove_call_idx = snippet.find('_submitToolsRemove(toolName);')
        self.assertNotEqual(confirm_idx, -1)
        self.assertNotEqual(remove_call_idx, -1)
        self.assertLess(confirm_idx, remove_call_idx,
                        "confirm() must gate the call to _submitToolsRemove")

    def test_op1_confirm_early_return_on_cancel(self):
        idx = self.src.find('function _buildToolRow(')
        snippet = self.src[idx:idx + 1100]
        self.assertRegex(snippet, r"if \(!window\.confirm\(.*\)\) return;")

    def test_op1_all_three_ops_refetch_on_either_outcome(self):
        for fn_name, window in [
            ('_submitToolsAdd', 700),
            # _submitToolsUpdate widened 600 -> 1100 (reviewer follow-up: the
            # preVersion capture + restartFromVersion arming push
            # _refetchModelForHeader() further into the function).
            ('_submitToolsUpdate', 1100),
            ('_submitToolsRemove', 600),
        ]:
            with self.subTest(fn=fn_name):
                idx = self.src.find(f'function {fn_name}(')
                self.assertNotEqual(idx, -1, fn_name)
                snippet = self.src[idx:idx + window]
                refetch_count = snippet.count('_refetchModelForHeader();')
                self.assertEqual(refetch_count, 1,
                                 f"{fn_name} must call _refetchModelForHeader() exactly once")
                refetch_idx = snippet.find('_refetchModelForHeader();')
                else_close_idx = snippet.rfind('}', 0, refetch_idx)
                self.assertNotEqual(else_close_idx, -1)

    def test_op1_error_message_read_from_body_detail_or_error(self):
        for fn_name, window in [
            ('_submitToolsAdd', 700),
            # _submitToolsUpdate widened 700 -> 1100 (reviewer follow-up: the
            # preVersion capture + restartFromVersion arming push the
            # failure-branch errorMessage assignment further into the function).
            ('_submitToolsUpdate', 1100),
            ('_submitToolsRemove', 700),
        ]:
            with self.subTest(fn=fn_name):
                idx = self.src.find(f'function {fn_name}(')
                self.assertNotEqual(idx, -1, fn_name)
                snippet = self.src[idx:idx + window]
                self.assertIn('result.body.detail || result.body.error', snippet)


class TestExplicitRenderGuardBypass(unittest.TestCase):
    """GB: the saving-guard bypass flag (mirrors connectors/external-sources'
    delivery-001 dogfood-fix pattern -- TestEditEntryGuardBypass in
    test_task022_connectors_external_sources_ui.py)."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_gb_consume_helper_defined_and_reads_then_clears(self):
        idx = self.src.find('function _consumeToolsExplicitRender()')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('_toolsExplicitRender = false;', snippet)
        self.assertIn('return v;', snippet)

    def test_gb_guard_consumes_flag_before_checking_saving(self):
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn(
            'if (!_consumeToolsExplicitRender() && toolsUiState.saving) return;',
            snippet,
        )

    def test_gb_force_render_sets_flag_before_rendering(self):
        idx = self.src.find('function _forceToolsRender()')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 250]
        flag_idx = snippet.find('_toolsExplicitRender = true;')
        render_idx = snippet.find('_renderToolsCard(')
        self.assertNotEqual(flag_idx, -1)
        self.assertNotEqual(render_idx, -1)
        self.assertLess(flag_idx, render_idx,
                        "the flag must be set BEFORE the render call it needs to bypass")

    def test_gb_all_three_ops_call_force_render_before_postop(self):
        for fn_name, window in [
            ('_submitToolsAdd', 700),
            # _submitToolsUpdate widened 500 -> 700 (reviewer follow-up: the
            # preVersion capture + restartFromVersion reset push the postOp()
            # call slightly further into the function).
            ('_submitToolsUpdate', 700),
            ('_submitToolsRemove', 500),
        ]:
            with self.subTest(fn=fn_name):
                idx = self.src.find(f'function {fn_name}(')
                self.assertNotEqual(idx, -1, fn_name)
                snippet = self.src[idx:idx + window]
                saving_idx = snippet.find('toolsUiState.saving = true;')
                force_idx = snippet.find('_forceToolsRender();')
                postop_idx = snippet.find("postOp('tools.")
                self.assertNotEqual(saving_idx, -1)
                self.assertNotEqual(force_idx, -1)
                self.assertNotEqual(postop_idx, -1)
                self.assertLess(saving_idx, force_idx)
                self.assertLess(force_idx, postop_idx,
                                "_forceToolsRender must run BEFORE the postOp dispatch (busy-state paint)")

    def test_gb_poll_loop_render_call_is_unconditional(self):
        # renderMainPage's own call site must NOT set the flag beforehand.
        idx_fn = self.src.find('function renderMainPage(model)')
        self.assertNotEqual(idx_fn, -1)
        snippet = self.src[idx_fn:idx_fn + 400]
        tools_call_idx = snippet.find('_renderToolsCard(model, model.write_enabled === true);')
        self.assertNotEqual(tools_call_idx, -1)
        preceding = snippet[max(0, tools_call_idx - 120):tools_call_idx]
        self.assertNotIn('_toolsExplicitRender = true', preceding)


class TestToolsCatalogGraft(unittest.TestCase):
    """GR: onSuccess grafts envelope.tools_catalog onto the model, fail-safe []."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_gr_graft_present_in_onsuccess(self):
        idx = self.src.find('function onSuccess(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1600]
        self.assertIn(
            "lastGoodModel.tools_catalog = Array.isArray(envelope.tools_catalog) ? envelope.tools_catalog : [];",
            snippet,
        )

    def test_gr_graft_happens_after_lastgoodmodel_assignment(self):
        idx = self.src.find('function onSuccess(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1600]
        assign_idx = snippet.find('lastGoodModel = envelope.model;')
        graft_idx = snippet.find('lastGoodModel.tools_catalog =')
        self.assertNotEqual(assign_idx, -1)
        self.assertNotEqual(graft_idx, -1)
        self.assertLess(assign_idx, graft_idx)


class TestRestartAdvisory(unittest.TestCase):
    """RA (reviewer follow-up on top of the initial Tools section): the
    tools.update restart advisory.

    `aid update`'s self-update-if-stale preamble (FF-3) can rewrite the
    RUNNING server's own code (KI-002/KI-006); a successful tools.update
    captures the pre-update aid_version (toolsUiState.restartFromVersion) so
    _renderToolsCard can compare it to the freshly re-fetched version and
    surface a 'callout warn' notice when they differ. tools.add/tools.remove
    do NOT run that preamble and never touch restartFromVersion.
    """

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_ra_tools_ui_state_has_restart_from_version_field(self):
        self.assertIn(
            "var toolsUiState = { saving: false, errorMessage: null, selected: '', "
            "restartFromVersion: null };",
            self.src,
        )

    def test_ra_advisory_gated_on_restart_from_version_differs_from_current(self):
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3900]
        self.assertIn(
            'toolsUiState.restartFromVersion !== null && toolsUiState.restartFromVersion !== version',
            snippet,
        )

    def test_ra_advisory_uses_callout_warn_and_aria_live_polite(self):
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3900]
        advisory_idx = snippet.find('toolsUiState.restartFromVersion !== null')
        self.assertNotEqual(advisory_idx, -1)
        region = snippet[advisory_idx:advisory_idx + 400]
        self.assertIn("advisory.className = 'callout warn';", region)
        self.assertIn("advisory.setAttribute('aria-live', 'polite');", region)

    def test_ra_advisory_copy_mentions_restart_and_both_versions(self):
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3900]
        advisory_idx = snippet.find('toolsUiState.restartFromVersion !== null')
        self.assertNotEqual(advisory_idx, -1)
        region = snippet[advisory_idx:advisory_idx + 400]
        self.assertIn('restart `aid dashboard`', region)
        self.assertIn("toolsUiState.restartFromVersion +", region)
        self.assertIn("' → v' + version", region)

    def test_ra_advisory_positioned_after_error_block_before_write_gate(self):
        # The advisory is a READ-VIEW notice (visible in read-only mode too,
        # since a prior write elsewhere could have updated the CLI) -- it must
        # render AFTER the inline error block and BEFORE the write-mode gate,
        # never nested inside either.
        idx = self.src.find('function _renderToolsCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3900]
        error_idx = snippet.find('if (toolsUiState.errorMessage) {')
        advisory_idx = snippet.find('toolsUiState.restartFromVersion !== null')
        write_gate_idx = snippet.find('if (writeEnabled) {')
        self.assertNotEqual(error_idx, -1)
        self.assertNotEqual(advisory_idx, -1)
        self.assertNotEqual(write_gate_idx, -1)
        self.assertLess(error_idx, advisory_idx,
                        "the advisory must be built AFTER the inline error block")
        self.assertLess(advisory_idx, write_gate_idx,
                        "the advisory must be built BEFORE the write-mode gate (a read-view notice)")

    def test_ra_submit_update_captures_pre_version_before_dispatch(self):
        idx = self.src.find('function _submitToolsUpdate(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1100]
        pre_idx = snippet.find(
            'var preVersion = (lastGoodModel && lastGoodModel.tool) ? lastGoodModel.tool.aid_version : null;'
        )
        postop_idx = snippet.find("postOp('tools.update'")
        self.assertNotEqual(pre_idx, -1)
        self.assertNotEqual(postop_idx, -1)
        self.assertLess(pre_idx, postop_idx,
                        "preVersion must be captured BEFORE the postOp dispatch")

    def test_ra_submit_update_resets_restart_from_version_before_dispatch(self):
        # Each fresh attempt clears any prior advisory before the request fires.
        idx = self.src.find('function _submitToolsUpdate(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1100]
        reset_idx = snippet.find('toolsUiState.restartFromVersion = null;')
        postop_idx = snippet.find("postOp('tools.update'")
        self.assertNotEqual(reset_idx, -1)
        self.assertNotEqual(postop_idx, -1)
        self.assertLess(reset_idx, postop_idx)

    def test_ra_submit_update_arms_restart_from_version_only_on_success(self):
        idx = self.src.find('function _submitToolsUpdate(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1100]
        ok_idx = snippet.find('if (result.ok && result.body && result.body.ok) {')
        arm_idx = snippet.find(
            'toolsUiState.restartFromVersion = (preVersion === undefined ? null : preVersion);'
        )
        else_idx = snippet.find('} else {', ok_idx if ok_idx != -1 else 0)
        self.assertNotEqual(ok_idx, -1)
        self.assertNotEqual(arm_idx, -1)
        self.assertNotEqual(else_idx, -1)
        self.assertLess(ok_idx, arm_idx,
                        "restartFromVersion must be armed INSIDE the success branch")
        self.assertLess(arm_idx, else_idx,
                        "the arming statement must precede the else (failure) branch")

    def test_ra_submit_update_does_not_arm_on_failure(self):
        idx = self.src.find('function _submitToolsUpdate(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1100]
        else_idx = snippet.find('} else {')
        self.assertNotEqual(else_idx, -1)
        else_branch = snippet[else_idx:else_idx + 250]
        self.assertNotIn('restartFromVersion', else_branch)

    def test_ra_add_never_touches_restart_from_version(self):
        idx = self.src.find('function _submitToolsAdd(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 700]
        self.assertNotIn('restartFromVersion', snippet)

    def test_ra_remove_never_touches_restart_from_version(self):
        idx = self.src.find('function _submitToolsRemove(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 700]
        self.assertNotIn('restartFromVersion', snippet)


class TestNoNewPageOrRoute(unittest.TestCase):
    """N1: dashboard/index.html (the CLI-home / all-projects page) carries none
    of these per-project tool-management ops -- Add/Update/Remove tool are
    project-page (home.html) only."""

    @classmethod
    def setUpClass(cls):
        assert _INDEX_HTML.is_file()
        cls.index_src = _INDEX_HTML.read_text(encoding="utf-8")

    def test_n1_no_tools_add_or_remove_op_strings_in_index_html(self):
        self.assertNotIn("'tools.add'", self.index_src)
        self.assertNotIn("'tools.remove'", self.index_src)

    def test_n1_no_tools_section_markup_in_index_html(self):
        self.assertNotIn('tools-section', self.index_src)
        self.assertNotIn('_renderToolsCard', self.index_src)


if __name__ == "__main__":
    unittest.main()
