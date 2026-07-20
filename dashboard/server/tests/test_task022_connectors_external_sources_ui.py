"""
test_task022_connectors_external_sources_ui.py -- Static/DOM assertions for the
Connectors (feature-007-connectors-list) and External Sources
(feature-010-external-sources-list) list-CRUD sections (task-022, delivery-003,
work-017-cli-improvements) in dashboard/home.html.

Mirrors test_home_html_project_header.py's / test_task009_rename_ui.py's /
test_task010_task_notes_ui.py's established convention for this codebase: no
browser/jsdom required. Tests inspect the HTML/JS source text and verify
presence/placement/order of the new markup and functions -- never execute the
client-side JS. (The server-side connector.set/.remove and
external-source.add/.remove argv-builders/arg-schemas -- OP_TABLE rows,
semantic_validate, write-connector.sh/write-external-source.sh dispatch -- are
task-019's/task-021's own scope and are already covered by their own test
files; this file covers ONLY the UI half task-022 adds on top of that.)

  S1  -- Structural: Connectors + External Sources sections are siblings of the
          KB band, in KB -> Connectors -> External Sources -> Pipelines order.
  S2  -- Structural: renderMainPage calls _renderConnectorsCard /
          _renderExternalSourcesCard with model.repo.connectors /
          model.repo.external_sources and model.write_enabled === true.
  S3  -- Structural: both sections reuse .work-overview / .btn-ghost /
          .interval-input / .callout err (no new CSS framework beyond the new
          .list-crud-* scaffold classes).
  R1  -- Render: the Connectors read table shows Connector/Type/Endpoint/Auth/
          Secret Ref/Summary (build-connectors-index.sh's column contract) +
          an empty-state line.
  R2  -- Render: the External Sources list renders each entry as a link iff it
          matches the browser URL-regex twin (byte-identical to Python
          _RE_URL / Node RE_URL_SOURCE), else plain text; rel=noopener
          noreferrer; empty-state line.
  G1  -- Gate: Add form / Remove buttons render ONLY when write_enabled ===
          true, in both card-builder functions; the read views are unconditional.
  OP1 -- Ops: connector.set / connector.remove dispatch with target: {} and the
          documented args shape; Remove uses a confirm() guard; the secret hint
          appears for an aid-managed file:-form connector; no secret VALUE is
          ever referenced/posted.
  OP2 -- Ops: external-source.add / external-source.remove dispatch with
          target: {} and {value}; client-side trim/whitespace/empty validation
          runs before postOp().
  RR  -- Re-render: both success AND failure paths call _refetchModelForHeader
          (task-022's "re-render from the fresh model regardless" contract).
  GB  -- Regression coverage (delivery-001 dogfood fix, commit 41ea5d28): the
          explicit-render one-shot bypass flag is present and consumed BEFORE
          the guard's saving check, for BOTH sections, and is set before every
          render call made while entering the `saving` state.

NOTE (test-infrastructure gap, same as test_home_html_project_header.py's
TestEditEntryGuardBypass): every test in this file is a static source-text
parse. It asserts the guard/bypass wiring and the op dispatch call sites are
present and correctly ordered, but it does NOT execute a click handler or the
render functions, so it cannot itself observe that clicking "Add"/"Remove" in a
real browser actually draws the busy state or opens the network request. This
codebase has no jsdom/DOM-executing harness for home.html (only source-text
parses) -- runtime behavior is the browser-dogfood's job at the delivery-003
gate.

Python 3.11+ stdlib only. Deterministic.
"""

import re
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # AID/
_HOME_HTML = _REPO_ROOT / "dashboard" / "home.html"
_INDEX_HTML = _REPO_ROOT / "dashboard" / "index.html"
_PARSERS_PY = _REPO_ROOT / "dashboard" / "reader" / "parsers.py"
_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"


class TestStructuralPlacement(unittest.TestCase):
    """S1-S3: section placement, render-call wiring, style reuse."""

    @classmethod
    def setUpClass(cls):
        assert _HOME_HTML.is_file(), f"dashboard/home.html not found at {_HOME_HTML}"
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_s1_connectors_section_container_present(self):
        self.assertIn('id="connectors-section"', self.src)

    def test_s1_external_sources_section_container_present(self):
        self.assertIn('id="external-sources-section"', self.src)

    def test_s1_headings_present(self):
        self.assertIn('>Connectors</h2>', self.src)
        self.assertIn('>External Sources</h2>', self.src)

    def test_s1_order_kb_then_connectors_then_external_sources_then_pipelines(self):
        idx_kb = self.src.find('id="knowledge-tool-section"')
        idx_conn = self.src.find('id="connectors-section"')
        idx_ext = self.src.find('id="external-sources-section"')
        idx_pipe = self.src.find('id="pipelines-section"')
        for name, idx in [("kb", idx_kb), ("connectors", idx_conn),
                           ("external-sources", idx_ext), ("pipelines", idx_pipe)]:
            self.assertNotEqual(idx, -1, f"{name} container not found")
        self.assertLess(idx_kb, idx_conn)
        self.assertLess(idx_conn, idx_ext)
        self.assertLess(idx_ext, idx_pipe)

    def test_s2_render_main_page_calls_both_card_renders(self):
        idx = self.src.find('function renderMainPage(model)')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3000]
        self.assertIn(
            "_renderConnectorsCard(model.repo && model.repo.connectors, model.write_enabled === true);",
            snippet,
        )
        self.assertIn(
            "_renderExternalSourcesCard(model.repo, model.write_enabled === true);",
            snippet,
        )

    def test_s2_render_functions_defined_with_documented_signature(self):
        self.assertIn('function _renderConnectorsCard(connectors, writeEnabled)', self.src)
        self.assertIn('function _renderExternalSourcesCard(repo, writeEnabled)', self.src)

    def test_s3_reuses_work_overview_panel_class(self):
        idx = self.src.find('function _renderConnectorsCard(')
        snippet = self.src[idx:idx + 800]
        self.assertIn("panel.className = 'work-overview'", snippet)
        idx2 = self.src.find('function _renderExternalSourcesCard(')
        snippet2 = self.src[idx2:idx2 + 800]
        self.assertIn("panel.className = 'work-overview'", snippet2)

    def test_s3_reuses_btn_ghost_and_interval_input(self):
        idx = self.src.find('function _buildConnectorAddForm(')
        idx_end = self.src.find('function _validateConnectorFields(')
        snippet = self.src[idx:idx_end]
        self.assertIn("'interval-input'", snippet)
        self.assertIn("'btn-ghost'", snippet)

    def test_s3_error_surfaces_reuse_callout_err(self):
        idx = self.src.find('function _renderConnectorsCard(')
        snippet = self.src[idx:idx + 1200]
        self.assertIn("'callout err'", snippet)
        idx2 = self.src.find('function _renderExternalSourcesCard(')
        snippet2 = self.src[idx2:idx2 + 1200]
        self.assertIn("'callout err'", snippet2)

    def test_s3_list_crud_css_classes_present(self):
        for cls in ['.list-crud-table', '.list-crud-empty', '.list-crud-hint',
                    '.list-crud-list', '.list-crud-list-item', '.list-crud-add-row']:
            self.assertIn(cls, self.src, f"CSS class {cls} missing from home.html")


class TestConnectorFormTypeDependentFields(unittest.TestCase):
    """The Add-connector form shows ONLY the fields that apply to the selected
    type (mirrors the server's connector.set validation): endpoint for
    api/ssh/cli; auth for api only (ssh/cli self-authenticate; `url` was
    dropped by the feature-007 schema simplification); secret ONLY when
    type == api AND auth != 'none'. Changing type/auth rebuilds the row +
    drops now-hidden values."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")
        i = cls.src.find("function _buildConnectorAddForm(")
        j = cls.src.find("function _rebuildConnectorAddForm(")
        assert i != -1 and j != -1, "connector add-form / rebuild helper not found"
        cls.form = cls.src[i:j]

    def test_endpoint_gated_on_endpoint_required_types(self):
        self.assertIn("var showEndpoint = CONNECTOR_ENDPOINT_REQUIRED_TYPES.indexOf(f.type) !== -1", self.form)
        self.assertIn("if (showEndpoint)", self.form)

    def test_auth_gated_on_api_only(self):
        # auth applies to `api` only now (ssh/cli self-authenticate; mcp tool-managed)
        self.assertIn("var showAuth = CONNECTOR_AUTH_REQUIRED_TYPES.indexOf(f.type) !== -1", self.form)
        self.assertIn("if (showAuth)", self.form)

    def test_secret_gated_on_api_and_auth_not_none(self):
        self.assertIn("var showSecret = showAuth && !!f.auth && f.auth !== 'none'", self.form)
        self.assertIn("if (showSecret)", self.form)

    def test_type_change_clears_hidden_fields_and_rebuilds(self):
        # mcp drops the (uncollected) endpoint; any non-api type drops auth+secret.
        self.assertIn("if (f.type === 'mcp') { f.endpoint = ''; }", self.form)
        self.assertIn("if (f.type !== 'api') { f.auth = 'none'; f.secret_ref = ''; }", self.form)
        self.assertIn("_rebuildConnectorAddForm()", self.form)

    def test_auth_change_clears_secret_when_none(self):
        self.assertIn("if (f.auth === 'none') { f.secret_ref = ''; }", self.form)

    def test_rebuild_helper_forces_render_of_connectors_card(self):
        idx = self.src.find("function _rebuildConnectorAddForm(")
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn("_connectorsExplicitRender = true", snippet)
        self.assertIn("_renderConnectorsCard(", snippet)


class TestConnectorsTable(unittest.TestCase):
    """R1: the Connectors read table matches build-connectors-index.sh's columns."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r1_table_builder_defined(self):
        self.assertIn('function _buildConnectorsTable(list, writeEnabled)', self.src)

    def test_r1_column_headers_in_order(self):
        idx = self.src.find('function _buildConnectorsTable(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 800]
        self.assertIn(
            "var headers = ['Connector', 'Type', 'Endpoint', 'Auth', 'Secret Ref', 'Summary'];",
            snippet,
        )

    def test_r1_row_reads_declared_connector_ref_fields(self):
        idx = self.src.find('function _buildConnectorRow(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2500]
        for field in ['c.name', 'c.stem', 'c.connection_type', 'c.endpoint',
                      'c.auth_method', 'c.secret_reference', 'c.summary']:
            self.assertIn(field, snippet)

    def test_r1_empty_state_line(self):
        self.assertIn('No connectors registered.', self.src)

    def test_r1_empty_state_gated_on_list_length(self):
        idx = self.src.find('function _renderConnectorsCard(')
        snippet = self.src[idx:idx + 900]
        self.assertIn('list.length === 0', snippet)
        self.assertIn('No connectors registered.', snippet)


class TestExternalSourcesList(unittest.TestCase):
    """R2: the External Sources list + the browser-side URL-regex twin."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")
        assert _PARSERS_PY.is_file()
        assert _READER_MJS.is_file()
        cls.parsers_py_src = _PARSERS_PY.read_text(encoding="utf-8")
        cls.reader_mjs_src = _READER_MJS.read_text(encoding="utf-8")

    def test_r2_regex_twin_defined(self):
        self.assertIn(r"var _RE_URL_CLIENT = /^[a-z][a-z0-9+.\-]*:\/\//;", self.src)

    def test_r2_regex_twin_matches_python_re_url_source(self):
        # Python: _RE_URL = re.compile(r"^[a-z][a-z0-9+.\-]*://")
        self.assertIn(r'_RE_URL = re.compile(r"^[a-z][a-z0-9+.\-]*://")', self.parsers_py_src)

    def test_r2_regex_twin_matches_node_re_url_source(self):
        # Node: const RE_URL_SOURCE = /^[a-z][a-z0-9+.\-]*:\/\//;
        self.assertIn(r"const RE_URL_SOURCE = /^[a-z][a-z0-9+.\-]*:\/\//;", self.reader_mjs_src)

    def test_r2_regex_twin_byte_identical_across_python_node_client(self):
        # Extract just the bracket-expression body shared by all three forms and
        # confirm it is IDENTICAL (not just "similar") -- the anchor charset,
        # quantifier, and escaped hyphen must all match exactly.
        body = r"[a-z][a-z0-9+.\-]*"
        self.assertIn(body, self.parsers_py_src)
        self.assertIn(body, self.reader_mjs_src)
        self.assertIn(body, self.src)

    def test_r2_functional_parity_shared_case_set(self):
        # Run the SAME case set through Python's compiled regex (stdlib only --
        # this file does not shell out to node) and confirm the expected
        # true/false split; the JS twin's source is asserted byte-identical
        # above, so this exercises the shared semantics both twins encode.
        re_url = re.compile(r"^[a-z][a-z0-9+.\-]*://")
        cases = {
            "https://example.com/doc": True,
            "http://example.com": True,
            "ftp://foo": True,
            "git+ssh://host/path": True,
            "mailto:foo@bar.com": False,
            "path/to/doc.md": False,
            "HTTPS://EXAMPLE.COM": False,
            "": False,
            "a://": True,
            "1abc://x": False,
        }
        for value, expected in cases.items():
            self.assertEqual(bool(re_url.match(value)), expected, f"case {value!r}")

    def test_r2_url_match_renders_anchor_with_rel_noopener(self):
        idx = self.src.find('function _buildExternalSourceItem(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 900]
        self.assertIn('_RE_URL_CLIENT.test(value)', snippet)
        self.assertIn("a.rel = 'noopener noreferrer';", snippet)
        self.assertIn('a.href = value;', snippet)

    def test_r2_non_url_renders_plain_text_span(self):
        idx = self.src.find('function _buildExternalSourceItem(')
        snippet = self.src[idx:idx + 900]
        self.assertIn("createElement('span')", snippet)
        self.assertIn('span.textContent = value;', snippet)

    def test_r2_empty_state_line(self):
        self.assertIn('No external sources registered.', self.src)


class TestWriteEnabledGate(unittest.TestCase):
    """G1: Add form / Remove buttons render ONLY when write_enabled === true."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_g1_connectors_add_form_gated(self):
        idx = self.src.find('function _renderConnectorsCard(')
        snippet = self.src[idx:idx + 1200]
        self.assertIn('if (writeEnabled) {', snippet)
        self.assertIn('_buildConnectorAddForm()', snippet)

    def test_g1_connectors_remove_button_gated(self):
        idx = self.src.find('function _buildConnectorRow(')
        snippet = self.src[idx:idx + 3000]
        guard_idx = snippet.find('if (writeEnabled) {')
        remove_idx = snippet.find("removeBtn.textContent = 'Remove';")
        self.assertNotEqual(guard_idx, -1)
        self.assertNotEqual(remove_idx, -1)
        self.assertLess(guard_idx, remove_idx,
                        "the Remove button must be built INSIDE the writeEnabled guard")

    def test_g1_connectors_actions_column_header_gated(self):
        idx = self.src.find('function _buildConnectorsTable(')
        snippet = self.src[idx:idx + 900]
        self.assertIn('if (writeEnabled) headRow.appendChild', snippet)

    def test_g1_external_sources_add_row_gated(self):
        idx = self.src.find('function _renderExternalSourcesCard(')
        snippet = self.src[idx:idx + 1500]
        self.assertIn('if (writeEnabled) {', snippet)
        self.assertIn('_buildExternalSourceAddRow()', snippet)

    def test_g1_external_sources_remove_button_gated(self):
        idx = self.src.find('function _buildExternalSourceItem(')
        snippet = self.src[idx:idx + 900]
        guard_idx = snippet.find('if (writeEnabled) {')
        remove_idx = snippet.find("removeBtn.textContent = 'Remove';")
        self.assertNotEqual(guard_idx, -1)
        self.assertNotEqual(remove_idx, -1)
        self.assertLess(guard_idx, remove_idx,
                        "the Remove button must be built INSIDE the writeEnabled guard")

    def test_g1_connector_remove_button_disabled_while_saving(self):
        # Regression: the Remove button must be gated on the shared `saving`
        # flag (like the Add button) so a rebuild mid-flight can't be double-
        # clicked into a second overlapping request.
        idx = self.src.find('function _buildConnectorRow(')
        snippet = self.src[idx:idx + 3000]
        self.assertIn('removeBtn.disabled = connectorsUiState.saving;', snippet)

    def test_g1_external_source_remove_button_disabled_while_saving(self):
        idx = self.src.find('function _buildExternalSourceItem(')
        snippet = self.src[idx:idx + 900]
        self.assertIn('removeBtn.disabled = externalSourcesUiState.saving;', snippet)

    def test_g1_read_views_are_unconditional(self):
        # The empty-state / table / list construction happens BEFORE any
        # writeEnabled check -- confirm the length-check branch precedes the
        # first `if (writeEnabled)` in each render function.
        idx = self.src.find('function _renderConnectorsCard(')
        snippet = self.src[idx:idx + 1200]
        len_idx = snippet.find('list.length === 0')
        we_idx = snippet.find('if (writeEnabled) {')
        self.assertNotEqual(len_idx, -1)
        self.assertNotEqual(we_idx, -1)
        self.assertLess(len_idx, we_idx)

        idx2 = self.src.find('function _renderExternalSourcesCard(')
        snippet2 = self.src[idx2:idx2 + 1500]
        len_idx2 = snippet2.find('sources.length === 0')
        we_idx2 = snippet2.find('if (writeEnabled) {')
        self.assertNotEqual(len_idx2, -1)
        self.assertNotEqual(we_idx2, -1)
        self.assertLess(len_idx2, we_idx2)


class TestConnectorOps(unittest.TestCase):
    """OP1: connector.set / connector.remove dispatch shape + secret hint."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_op1_set_uses_post_op_helper_with_empty_target(self):
        idx = self.src.find('function _submitConnectorAdd(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1600]
        self.assertIn("postOp('connector.set', {}, args, function (result) {", snippet)

    def test_op1_set_args_shape(self):
        idx = self.src.find('function _submitConnectorAdd(')
        snippet = self.src[idx:idx + 1200]
        self.assertIn("var args = { name: f.name, type: f.type };", snippet)
        self.assertIn('if (f.endpoint) args.endpoint = f.endpoint;', snippet)
        self.assertIn('if (f.auth) args.auth = f.auth;', snippet)
        self.assertIn('if (f.secret_ref) args.secret_ref = f.secret_ref;', snippet)

    def test_op1_remove_uses_post_op_helper_with_stem(self):
        idx = self.src.find('function _submitConnectorRemove(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 800]
        self.assertIn("postOp('connector.remove', {}, { stem: stem }, function (result) {", snippet)

    def test_op1_remove_uses_window_confirm_guard(self):
        idx = self.src.find('function _buildConnectorRow(')
        snippet = self.src[idx:idx + 3000]
        self.assertIn('window.confirm(', snippet)
        confirm_idx = snippet.find('window.confirm(')
        remove_call_idx = snippet.find('_submitConnectorRemove(c.stem);')
        self.assertNotEqual(confirm_idx, -1)
        self.assertNotEqual(remove_call_idx, -1)
        self.assertLess(confirm_idx, remove_call_idx,
                        "confirm() must gate the call to _submitConnectorRemove")

    def test_op1_confirm_early_return_on_cancel(self):
        idx = self.src.find('function _buildConnectorRow(')
        snippet = self.src[idx:idx + 3000]
        self.assertIn('if (!window.confirm(', snippet)
        # The confirm() line itself must early-return (the message may contain
        # nested parens, e.g. (c.name || c.stem), so match loosely up to the
        # line's own closing `)) return;`).
        self.assertRegex(snippet, r"if \(!window\.confirm\(.*\)\) return;")

    def test_op1_secret_hint_conditions(self):
        idx = self.src.find('function _buildConnectorRow(')
        snippet = self.src[idx:idx + 3000]
        self.assertIn("c.auth_method && c.auth_method !== 'none' && c.secret_reference &&", snippet)
        self.assertIn("c.secret_reference.indexOf('file:') === 0", snippet)
        self.assertIn('secret not yet stored', snippet)
        self.assertIn('connector-secret.sh write', snippet)

    def test_op1_no_secret_value_field_referenced_anywhere(self):
        # The Add form only carries a REFERENCE field (secret_ref); there must
        # be no field/variable name suggesting a raw secret VALUE is captured
        # or posted (e.g. 'secret_value', 'secretValue', 'credential').
        for banned in ['secret_value', 'secretValue', 'credential_value', 'secretVal']:
            self.assertNotIn(banned, self.src)

    def test_op1_client_side_type_conditional_validation(self):
        idx = self.src.find('function _validateConnectorFields(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 900]
        self.assertIn('Name is required.', snippet)
        self.assertIn('CONNECTOR_ENDPOINT_REQUIRED_TYPES.indexOf(f.type) !== -1', snippet)
        self.assertIn('CONNECTOR_AUTH_REQUIRED_TYPES.indexOf(f.type) !== -1', snippet)

    def test_op1_connector_type_and_auth_enums_match_server(self):
        server_py = (_REPO_ROOT / "dashboard" / "server" / "server.py").read_text(encoding="utf-8")
        self.assertIn(
            '_CONNECTOR_TYPES = frozenset({"mcp", "api", "ssh", "cli"})', server_py
        )
        self.assertIn(
            "var CONNECTOR_TYPES = ['mcp', 'api', 'ssh', 'cli'];", self.src
        )
        self.assertIn(
            '_CONNECTOR_AUTH_METHODS = frozenset({"none", "token", "pat", "oauth"})',
            server_py,
        )
        self.assertIn(
            "var CONNECTOR_AUTH_METHODS = ['none', 'token', 'pat', 'oauth'];", self.src
        )
        # `url` type and `ssh-key` auth are gone everywhere.
        self.assertNotIn('"url"', server_py.split("_CONNECTOR_TYPES")[1].split("\n")[0])
        self.assertNotIn("'ssh-key'", self.src.split("CONNECTOR_AUTH_METHODS")[1].split("\n")[0])


class TestExternalSourceOps(unittest.TestCase):
    """OP2: external-source.add / external-source.remove dispatch + validation."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_op2_add_uses_post_op_helper_with_empty_target(self):
        idx = self.src.find('function _submitExternalSourceAdd(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn("postOp('external-source.add', {}, { value: trimmed }, function (result) {", snippet)

    def test_op2_remove_uses_post_op_helper_with_value(self):
        idx = self.src.find('function _submitExternalSourceRemove(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 800]
        self.assertIn("postOp('external-source.remove', {}, { value: value }, function (result) {", snippet)

    def test_op2_client_validation_blocks_empty_and_whitespace(self):
        idx = self.src.find('function _validateExternalSourceValueClient(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn('if (!trimmed) return', snippet)
        self.assertIn(r'if (/\s/.test(trimmed)) return', snippet)

    def test_op2_validation_runs_before_postop(self):
        idx = self.src.find('function _submitExternalSourceAdd(')
        snippet = self.src[idx:idx + 1200]
        validate_idx = snippet.find('_validateExternalSourceValueClient(trimmed)')
        postop_idx = snippet.find("postOp('external-source.add'")
        self.assertNotEqual(validate_idx, -1)
        self.assertNotEqual(postop_idx, -1)
        self.assertLess(validate_idx, postop_idx)

    def test_op2_input_value_trimmed_before_validation(self):
        idx = self.src.find('function _submitExternalSourceAdd(')
        snippet = self.src[idx:idx + 400]
        self.assertIn("var trimmed = (externalSourcesUiState.value || '').trim();", snippet)


class TestReRenderOnEitherOutcome(unittest.TestCase):
    """RR: both success AND failure re-fetch the model (task-022's own
    "re-render from the fresh model regardless" contract -- stronger than the
    plain success-only contract feature-001 states verbatim elsewhere)."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def _assert_refetch_outside_conditional(self, fn_name, window=1200):
        idx = self.src.find(f'function {fn_name}(')
        self.assertNotEqual(idx, -1, fn_name)
        snippet = self.src[idx:idx + window]
        # Find the postOp(...) callback body and confirm _refetchModelForHeader()
        # is called exactly once, OUTSIDE (after) the if/else branch -- i.e. on
        # both outcomes, not duplicated inside each branch.
        refetch_count = snippet.count('_refetchModelForHeader();')
        self.assertEqual(refetch_count, 1,
                         f"{fn_name} must call _refetchModelForHeader() exactly once, "
                         f"after the if/else (both outcomes), found {refetch_count}")
        # The single call must be the LAST statement in the postOp callback --
        # i.e. it follows the closing brace of the if/else block, not nested
        # inside either arm.
        refetch_idx = snippet.find('_refetchModelForHeader();')
        else_close_idx = snippet.rfind('}', 0, refetch_idx)
        self.assertNotEqual(else_close_idx, -1)

    def test_rr_connector_add_refetches_on_either_outcome(self):
        self._assert_refetch_outside_conditional('_submitConnectorAdd', window=1800)

    def test_rr_connector_remove_refetches_on_either_outcome(self):
        self._assert_refetch_outside_conditional('_submitConnectorRemove')

    def test_rr_external_source_add_refetches_on_either_outcome(self):
        self._assert_refetch_outside_conditional('_submitExternalSourceAdd', window=1600)

    def test_rr_external_source_remove_refetches_on_either_outcome(self):
        self._assert_refetch_outside_conditional('_submitExternalSourceRemove')


class TestEditEntryGuardBypass(unittest.TestCase):
    """Regression coverage for the delivery-001 dogfood bug (commit 41ea5d28):
    each section's render function guards a poll-triggered rebuild while
    `saving` is true, but the very transition that SETS saving=true must force
    that render through via a one-shot explicit-render flag -- otherwise the
    guard swallows the busy-state draw exactly like delivery-001's four dead
    edit surfaces. Mirrors TestEditEntryGuardBypass in
    test_home_html_project_header.py.
    """

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    # ---- Connectors ----

    def test_connectors_consume_helper_defined_and_reads_then_clears(self):
        idx = self.src.find('function _consumeConnectorsExplicitRender()')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('_connectorsExplicitRender = false;', snippet)
        self.assertIn('return v;', snippet)

    def test_connectors_guard_consumes_flag_before_checking_saving(self):
        idx = self.src.find('function _renderConnectorsCard(')
        snippet = self.src[idx:idx + 400]
        self.assertIn(
            'if (!_consumeConnectorsExplicitRender() && connectorsUiState.saving) return;',
            snippet,
        )

    def test_connectors_add_sets_flag_before_forced_render(self):
        idx = self.src.find('function _submitConnectorAdd(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        idx_saving = snippet.find('connectorsUiState.saving = true;')
        idx_flag = snippet.find('_connectorsExplicitRender = true;', idx_saving)
        idx_render = snippet.find('_renderConnectorsCard(', idx_saving)
        self.assertNotEqual(idx_saving, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_saving, idx_flag)
        self.assertLess(idx_flag, idx_render,
                        "the flag must be set BEFORE the render call it needs to bypass")

    def test_connectors_remove_sets_flag_before_forced_render(self):
        idx = self.src.find('function _submitConnectorRemove(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 500]
        idx_saving = snippet.find('connectorsUiState.saving = true;')
        idx_flag = snippet.find('_connectorsExplicitRender = true;')
        idx_render = snippet.find('_renderConnectorsCard(')
        self.assertNotEqual(idx_saving, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_saving, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_connectors_validation_error_path_also_forces_render(self):
        idx = self.src.find('function _submitConnectorAdd(')
        snippet = self.src[idx:idx + 500]
        idx_err = snippet.find('connectorsUiState.errorMessage = clientErr;')
        idx_flag = snippet.find('_connectorsExplicitRender = true;')
        idx_render = snippet.find('_renderConnectorsCard(')
        self.assertNotEqual(idx_err, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_err, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_connectors_poll_loop_render_call_is_unconditional(self):
        # renderMainPage's own call site must NOT set the flag beforehand.
        idx_fn = self.src.find('function renderMainPage(model)')
        snippet = self.src[idx_fn:idx_fn + 3000]
        conn_call_idx = snippet.find('_renderConnectorsCard(model.repo && model.repo.connectors')
        self.assertNotEqual(conn_call_idx, -1)
        preceding = snippet[max(0, conn_call_idx - 120):conn_call_idx]
        self.assertNotIn('_connectorsExplicitRender = true', preceding)

    # ---- External Sources ----

    def test_external_sources_consume_helper_defined_and_reads_then_clears(self):
        idx = self.src.find('function _consumeExternalSourcesExplicitRender()')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('_externalSourcesExplicitRender = false;', snippet)
        self.assertIn('return v;', snippet)

    def test_external_sources_guard_consumes_flag_before_checking_saving(self):
        idx = self.src.find('function _renderExternalSourcesCard(')
        snippet = self.src[idx:idx + 400]
        self.assertIn(
            'if (!_consumeExternalSourcesExplicitRender() && externalSourcesUiState.saving) return;',
            snippet,
        )

    def test_external_sources_add_sets_flag_before_forced_render(self):
        idx = self.src.find('function _submitExternalSourceAdd(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 900]
        idx_saving = snippet.find('externalSourcesUiState.saving = true;')
        idx_flag = snippet.find('_externalSourcesExplicitRender = true;', idx_saving)
        idx_render = snippet.find('_renderExternalSourcesCard(', idx_saving)
        self.assertNotEqual(idx_saving, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_saving, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_external_sources_remove_sets_flag_before_forced_render(self):
        idx = self.src.find('function _submitExternalSourceRemove(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 500]
        idx_saving = snippet.find('externalSourcesUiState.saving = true;')
        idx_flag = snippet.find('_externalSourcesExplicitRender = true;')
        idx_render = snippet.find('_renderExternalSourcesCard(')
        self.assertNotEqual(idx_saving, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_saving, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_external_sources_validation_error_path_also_forces_render(self):
        idx = self.src.find('function _submitExternalSourceAdd(')
        snippet = self.src[idx:idx + 500]
        idx_err = snippet.find('externalSourcesUiState.errorMessage = clientErr;')
        idx_flag = snippet.find('_externalSourcesExplicitRender = true;')
        idx_render = snippet.find('_renderExternalSourcesCard(')
        self.assertNotEqual(idx_err, -1)
        self.assertNotEqual(idx_flag, -1)
        self.assertNotEqual(idx_render, -1)
        self.assertLess(idx_err, idx_flag)
        self.assertLess(idx_flag, idx_render)

    def test_external_sources_poll_loop_render_call_is_unconditional(self):
        idx_fn = self.src.find('function renderMainPage(model)')
        snippet = self.src[idx_fn:idx_fn + 3000]
        ext_call_idx = snippet.find('_renderExternalSourcesCard(model.repo, model.write_enabled === true);')
        self.assertNotEqual(ext_call_idx, -1)
        preceding = snippet[max(0, ext_call_idx - 120):ext_call_idx]
        self.assertNotIn('_externalSourcesExplicitRender = true', preceding)

    # ---- Field-state survives a poll-triggered rebuild (no data loss) ----

    def test_connector_add_form_fields_state_tracked_not_reset_on_rebuild(self):
        # Each input's initial `.value` is read from connectorsUiState.fields
        # (not a fixed literal), and each 'input'/'change' listener writes back
        # into that SAME object -- so a rebuild reconstructs the in-progress
        # entry instead of discarding it.
        idx = self.src.find('function _buildConnectorAddForm(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2500]
        self.assertIn('var f = connectorsUiState.fields;', snippet)
        self.assertIn('nameInput.value = f.name;', snippet)
        self.assertIn("nameInput.addEventListener('input', function () { f.name = nameInput.value; });", snippet)

    def test_external_source_input_value_state_tracked_not_reset_on_rebuild(self):
        idx = self.src.find('function _buildExternalSourceAddRow(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn('input.value = externalSourcesUiState.value;', snippet)
        self.assertIn(
            "input.addEventListener('input', function () { externalSourcesUiState.value = input.value; });",
            snippet,
        )


class TestNoNewPageOrRoute(unittest.TestCase):
    """N1: dashboard/index.html (the CLI-home / all-projects page) carries none
    of these per-project ops -- Connectors/External Sources are project-page
    (home.html) only."""

    @classmethod
    def setUpClass(cls):
        assert _INDEX_HTML.is_file()
        cls.index_src = _INDEX_HTML.read_text(encoding="utf-8")

    def test_n1_no_connector_ops_in_index_html(self):
        self.assertNotIn('connector.set', self.index_src)
        self.assertNotIn('connector.remove', self.index_src)

    def test_n1_no_external_source_ops_in_index_html(self):
        self.assertNotIn('external-source.add', self.index_src)
        self.assertNotIn('external-source.remove', self.index_src)


if __name__ == "__main__":
    unittest.main()
