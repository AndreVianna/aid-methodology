"""
test_cli_home_html.py -- Static/DOM assertions for dashboard/index.html (LC-HOME, task-053).

This file is the CLI-home page served at / by the multi-repo server (DR-2).  It polls
/api/home (DM-2) and renders the machine panel + repo-card grid.

No browser required.  Tests inspect the HTML source and verify:

  S1  -- Structural: page shell (top-bar, brand, freshness-badge, interval-input,
          theme-toggle, schema-mismatch-banner, machine-panel, repo-section,
          repo-grid, empty-registry, footer, noscript).
  S2  -- Structural: reads envelope.generated_by (not model.generated_by).
  S3  -- Structural: fetch targets are '/api/home' and, since feature-003/task-014
          (project.add/project.remove), '/api/op' (both same-origin absolute paths,
          never /api/model).
  S4  -- Structural: no CDN script tags or external stylesheets / web-fonts.
  S5  -- Structural: meta robots noindex present.
  S6  -- Structural: CSS design tokens present; dark theme block; badge classes.
  S7  -- Structural: EXPECTED_HOME_SCHEMA = 1; schema-mismatch check present.
  S8  -- Structural: localStorage key 'aid-dashboard-poll-ms' used.
  S9  -- Structural: brand is 'AID ... this machine' (static, no id="brand-name").
  B1  -- Behavioral: clampInterval bounds (1000 / 600000).
  B2  -- Behavioral: schema-mismatch banner hidden by default; showSchemaMismatch present.
  R1  -- Render: machine panel fields (version / install location / tool catalog).
  R2  -- Render: repo card display-name logic (name fallback / path/id never as title).
  R3  -- Render: available card -> /r/<id>/home.html href; card-link CSS.
  R4  -- Render: has_home=false -> non-clickable note.
  R5  -- Render: unavailable card -> badge-dim + prune guidance.
  R6  -- Render: empty repos -> empty-registry state.
  R7  -- Render: has_kb affordance chip.
  R8  -- Render: cli_runtime NOT rendered.
  INV -- Invariants: no .aid/ write; no agent/LLM import; no write button.

Python 3.11+ stdlib only. Deterministic.
"""

import re
import sys
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # AID/
_CLI_HOME_HTML = _REPO_ROOT / "dashboard" / "index.html"


class TestStructural(unittest.TestCase):
    """S1-S9: Structural checks on dashboard/index.html."""

    @classmethod
    def setUpClass(cls):
        assert _CLI_HOME_HTML.is_file(), f"dashboard/index.html not found at {_CLI_HOME_HTML}"
        cls.src = _CLI_HOME_HTML.read_text(encoding="utf-8")

    # S1 -- component anchors
    def test_s1_has_top_bar(self):
        self.assertIn('class="top-bar"', self.src)

    def test_s1_has_brand(self):
        self.assertIn('class="brand"', self.src)

    def test_s1_has_freshness_badge(self):
        self.assertIn('id="freshness-badge"', self.src)

    def test_s1_has_refresh_button(self):
        # The CLI home does NOT auto-poll; it offers a manual Refresh button instead
        # of a poll-interval input.
        self.assertIn('id="refresh-btn"', self.src)
        self.assertNotIn('id="interval-input"', self.src)

    def test_s1_has_theme_toggle(self):
        self.assertIn('id="theme-toggle"', self.src)

    def test_s1_has_machine_panel_container(self):
        self.assertIn('id="machine-panel"', self.src)

    def test_s1_has_repo_section(self):
        self.assertIn('id="repo-section"', self.src)

    def test_s1_has_repo_grid(self):
        self.assertIn('id="repo-grid"', self.src)

    def test_s1_projects_heading_and_fixed_grid(self):
        # The repo group is titled "Projects" and uses the fixed-width 4-per-row grid.
        self.assertIn('>Projects</h2>', self.src)
        self.assertNotIn('>Repos</h2>', self.src)
        self.assertIn('class="grid projects"', self.src)
        self.assertIn('.grid.projects { grid-template-columns: repeat(auto-fill, 270px)', self.src)

    def test_s1_has_empty_registry(self):
        self.assertIn('id="empty-registry"', self.src)

    def test_s1_has_schema_mismatch_banner(self):
        self.assertIn('id="schema-mismatch-banner"', self.src)

    def test_s1_has_footer(self):
        self.assertIn('<footer', self.src)

    def test_s1_has_noscript_fallback(self):
        self.assertIn('<noscript>', self.src)

    def test_s1_has_skip_link(self):
        self.assertIn('class="skip-link"', self.src)

    def test_s1_footer_says_refresh_to_update(self):
        # No auto-poll: the footer no longer advertises a poll interval.
        self.assertIn('refresh to update', self.src)
        self.assertNotIn('id="footer-interval"', self.src)

    def test_s1_has_footer_generated_by_span(self):
        self.assertIn('id="footer-generated-by"', self.src)

    def test_s1_has_loading_state(self):
        self.assertIn('id="loading-state"', self.src)

    # S2 -- reads envelope.generated_by
    def test_s2_reads_envelope_generated_by(self):
        self.assertIn('envelope.generated_by', self.src)

    def test_s2_does_not_read_model_dot_generated_by(self):
        self.assertNotIn('model.generated_by', self.src)

    # S3 -- fetch targets are /api/home (read poll), /api/op (feature-003
    # task-014 write-dispatch: project.add/project.remove; feature-004 task-016:
    # tools.update-self), both same-origin, plus the per-repo '/r/<id>/api/op'
    # route (feature-004 task-016: tools.update) built via string concatenation
    # ('/r/' + repo.id + '/api/op') -- the regex below only captures the literal
    # quoted prefix immediately after fetch(, i.e. '/r/' for that call.
    def test_s3_fetches_api_home(self):
        fetch_calls = re.findall(r"fetch\s*\(\s*['\"]([^'\"]+)['\"]", self.src)
        self.assertTrue(len(fetch_calls) > 0, "No fetch() call found")
        allowed = ('/api/home', '/api/op', '/r/')
        for url in fetch_calls:
            self.assertIn(url, allowed,
                         f"Unexpected fetch target: {url!r} -- only {allowed} allowed")

    def test_s3_fetches_api_op_present(self):
        # feature-003 (task-014): project.add / project.remove both dispatch via
        # POST /api/op -- confirm at least one such call exists (not just /api/home).
        self.assertIn("fetch('/api/op'", self.src)

    def test_s3_fetches_per_repo_api_op_present(self):
        # feature-004 (task-016): tools.update dispatches to the per-repo route,
        # with repo.id interpolated (never hard-coded, never derived from path).
        self.assertIn("fetch('/r/' + repo.id + '/api/op'", self.src)

    def test_s3_no_http_fetch(self):
        self.assertNotRegex(self.src, r"fetch\s*\(\s*['\"]https?://")

    def test_s3_does_not_fetch_api_model(self):
        self.assertNotIn("fetch('/api/model')", self.src)
        self.assertNotIn('fetch("./api/model")', self.src)
        self.assertNotIn("fetch('./api/model')", self.src)

    # S4 -- no CDN / external assets
    def test_s4_no_external_script_src(self):
        matches = re.findall(r'<script[^>]+src\s*=\s*["\']([^"\']+)["\']', self.src, re.IGNORECASE)
        for src in matches:
            self.assertFalse(src.startswith('http') or src.startswith('//'),
                             f"External script src: {src!r}")

    def test_s4_no_external_link_href(self):
        matches = re.findall(r'<link[^>]+href\s*=\s*["\']([^"\']+)["\']', self.src, re.IGNORECASE)
        for href in matches:
            self.assertFalse(href.startswith('http') or href.startswith('//'),
                             f"External link href: {href!r}")

    def test_s4_no_web_font_import(self):
        self.assertNotRegex(self.src, r'@import\s+url\s*\(\s*["\']?https?://')

    def test_s4_no_googleapis(self):
        self.assertNotIn('fonts.googleapis.com', self.src)

    def test_s4_no_cdn_unpkg(self):
        self.assertNotIn('unpkg.com', self.src)

    def test_s4_no_cdn_jsdelivr(self):
        self.assertNotIn('jsdelivr.net', self.src)

    # S5 -- meta robots noindex
    def test_s5_meta_robots_noindex(self):
        self.assertIn('content="noindex"', self.src)

    # S6 -- CSS design tokens
    def test_s6_has_bg_token(self):
        self.assertIn('--bg:', self.src)

    def test_s6_has_accent_token(self):
        self.assertIn('--accent:', self.src)

    def test_s6_has_ok_token(self):
        self.assertIn('--ok:', self.src)

    def test_s6_has_warn_token(self):
        self.assertIn('--warn:', self.src)

    def test_s6_has_err_token(self):
        self.assertIn('--err:', self.src)

    def test_s6_has_dark_theme_block(self):
        self.assertIn('html[data-theme="dark"]', self.src)

    def test_s6_badge_classes_present(self):
        for cls in ['.badge-accent', '.badge-ok', '.badge-warn', '.badge-err',
                    '.badge-dim', '.badge-primary', '.badge-info', '.badge-purple']:
            self.assertIn(cls, self.src, f"CSS class {cls} missing from index.html")

    def test_s6_callout_warn_class(self):
        self.assertIn('.callout.warn', self.src)

    def test_s6_card_plugin_css(self):
        self.assertIn('.card.plugin', self.src)

    def test_s6_card_link_css(self):
        self.assertIn('.card-link', self.src)

    def test_s6_card_link_display_block(self):
        idx = self.src.find('.card-link')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 100]
        self.assertIn('display:block', snippet.replace(' ', ''))

    def test_s6_grid_g2_class(self):
        self.assertIn('.grid.g2', self.src)

    def test_s6_main_section_head_class(self):
        self.assertIn('.main-section-head', self.src)

    def test_s6_responsive_768(self):
        self.assertIn('@media (max-width: 768px)', self.src)

    def test_s6_responsive_tablet(self):
        self.assertIn('@media (min-width: 769px) and (max-width: 1024px)', self.src)

    def test_s6_max_width_1200(self):
        self.assertIn('max-width: 1200px', self.src)

    def test_s6_grid_collapse_768(self):
        idx = self.src.find('@media (max-width: 768px)')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 500]
        self.assertIn('.grid', snippet)
        self.assertIn('1fr', snippet)

    # S7 -- schema constant
    def test_s7_expected_home_schema_1(self):
        self.assertIn('EXPECTED_HOME_SCHEMA = 1', self.src)

    def test_s7_schema_mismatch_check(self):
        self.assertIn('!== EXPECTED_HOME_SCHEMA', self.src)

    def test_s7_does_not_use_expected_schema_version_3(self):
        self.assertNotIn('EXPECTED_SCHEMA_VERSION = 3', self.src)

    # S8 -- no auto-poll: the CLI home loads once (no recurring setTimeout, no poll-ms key)
    def test_s8_no_auto_poll(self):
        self.assertNotIn("'aid-dashboard-poll-ms'", self.src)
        self.assertNotIn('scheduleNextPoll', self.src)
        # the single-shot fetch uses no recurring timer to re-call doFetch
        self.assertNotIn('setTimeout(function', self.src)

    # S9 -- brand is static "AID . this machine" (no id="brand-name")
    def test_s9_brand_contains_aid_this_machine(self):
        self.assertIn('this machine', self.src)
        # Check AID text is in the brand div
        idx = self.src.find('class="brand"')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('AID', snippet)
        self.assertIn('this machine', snippet)

    def test_s9_no_brand_name_id(self):
        # The CLI home brand is static -- no dynamic id="brand-name" injection needed
        self.assertNotIn('id="brand-name"', self.src)


class TestLoadOnce(unittest.TestCase):
    """B1: the CLI home loads once and updates only on Refresh / browser reload."""

    @classmethod
    def setUpClass(cls):
        cls.src = _CLI_HOME_HTML.read_text(encoding="utf-8")

    def test_single_shot_fetch_in_flight_guard(self):
        # doFetch keeps a single-in-flight guard but does NOT reschedule itself.
        self.assertIn('if (fetchPending) return;', self.src)

    def test_no_poll_interval_machinery(self):
        self.assertNotIn('clampInterval', self.src)
        self.assertNotIn('onIntervalChange', self.src)
        self.assertNotIn('pollTimer', self.src)

    def test_refresh_button_triggers_fetch(self):
        # The Refresh button re-runs doFetch (in-page reload of /api/home).
        idx = self.src.find("getElementById('refresh-btn')")
        self.assertNotEqual(idx, -1)
        self.assertIn('doFetch()', self.src[idx:idx + 200])


class TestSchemaMismatch(unittest.TestCase):
    """B2: schema-mismatch banner."""

    @classmethod
    def setUpClass(cls):
        cls.src = _CLI_HOME_HTML.read_text(encoding="utf-8")

    def test_schema_mismatch_banner_exists(self):
        self.assertIn('id="schema-mismatch-banner"', self.src)

    def test_schema_mismatch_hidden_by_default(self):
        banner_idx = self.src.find('id="schema-mismatch-banner"')
        self.assertNotEqual(banner_idx, -1)
        snippet = self.src[max(0, banner_idx - 50):banner_idx + 200]
        self.assertIn('display:none', snippet)

    def test_show_schema_mismatch_function(self):
        self.assertIn('showSchemaMismatch', self.src)
        self.assertIn('hideSchemaMismatch', self.src)

    def test_schema_mismatch_keep_last_good(self):
        # On mismatch, must return early (keep last good)
        idx = self.src.find('showSchemaMismatch')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 100]
        self.assertIn('return', snippet)


class TestRenderMachinePanel(unittest.TestCase):
    """R1: Machine panel renders the three parity-stable fields; cli_runtime not shown."""

    @classmethod
    def setUpClass(cls):
        cls.src = _CLI_HOME_HTML.read_text(encoding="utf-8")

    def test_r1_render_machine_panel_function(self):
        self.assertIn('function renderMachinePanel(', self.src)

    def test_r1_kicker_aid_cli_no_this_machine(self):
        # First line is just "AID CLI" + the version pill; no "(this machine)".
        idx = self.src.find('function renderMachinePanel(')
        snippet = self.src[idx:idx + 2000]
        self.assertIn("createTextNode('AID CLI')", snippet)
        self.assertNotIn('AID CLI (this machine)', self.src)
        # version pill: "v" + machine.aid_version
        self.assertIn("'v' + machine.aid_version", snippet)

    def test_r1_field_aid_version(self):
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('machine.aid_version', snippet)

    def test_r1_null_version_text(self):
        self.assertIn('(version unavailable)', self.src)

    def test_r1_field_aid_home(self):
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('machine.aid_home', snippet)

    def test_r1_field_tools_catalog(self):
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('machine.tools_catalog', snippet)

    def test_r1_dl_dt_dd_pattern(self):
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn("createElement('dl')", snippet)
        self.assertIn("createElement('dt')", snippet)
        self.assertIn("createElement('dd')", snippet)

    def test_r1_version_pill_in_kicker(self):
        # The version moved out of a dt/dd row into the kicker as a "v<ver>" pill.
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn("'v' + machine.aid_version", snippet)
        self.assertNotIn("dt1.textContent = 'version'", snippet)

    def test_r1_install_location_label(self):
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn("'install location'", snippet)

    def test_r1_available_tools_label(self):
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn("'available tools'", snippet)
        self.assertNotIn("'tool catalog'", snippet)

    def test_r1_no_registry_advisory_line(self):
        # The registry path advisory line was removed from the machine panel.
        idx = self.src.find('function renderMachinePanel(')
        snippet = self.src[idx:idx + 2000]
        self.assertNotIn('registry: ', snippet)
        self.assertNotIn('machine.registry_path', snippet)

    def test_r1_cli_runtime_not_rendered(self):
        # cli_runtime is explicitly excluded from the panel
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertNotIn('cli_runtime', snippet,
                         "cli_runtime must NOT be rendered in the machine panel (parity-excluded)")

    def test_r1_version_badge_info(self):
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('badge-info', snippet)

    def test_r1_catalog_badge_dim_chips(self):
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('badge-dim', snippet)

    def test_r1_empty_catalog_em_dash(self):
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('—', snippet)


class TestRenderRepoCard(unittest.TestCase):
    """R2-R7: Repo card rendering."""

    @classmethod
    def setUpClass(cls):
        cls.src = _CLI_HOME_HTML.read_text(encoding="utf-8")

    def test_r2_display_name_function(self):
        self.assertIn('function _displayName(', self.src)

    def test_r2_name_field_used(self):
        idx = self.src.find('function _displayName(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn('repo.name', snippet)

    def test_r2_basename_fallback(self):
        idx = self.src.find('function _displayName(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        # Must split path to get basename (never use raw path as title)
        self.assertIn("repo.path", snippet)
        self.assertIn("split('/')", snippet)

    def test_r2_em_dash_ultimate_fallback(self):
        idx = self.src.find('function _displayName(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn('—', snippet)

    def test_r3_available_card_href_pattern(self):
        # Available + has_home card: href = '/r/' + repo.id + '/home.html'
        self.assertIn("'/r/' + repo.id + '/home.html'", self.src)

    def test_r3_uses_repo_id_opaque(self):
        # Must use repo.id verbatim (no re-hash); must NOT construct from repo.path
        idx = self.src.find("'/r/' + repo.id")
        self.assertNotEqual(idx, -1)
        # region around the href construction must NOT reference repo.path
        snippet = self.src[max(0, idx - 50):idx + 80]
        self.assertNotIn('repo.path', snippet)

    def test_r3_card_link_class_used(self):
        self.assertIn('card card-link', self.src)

    def test_r4_has_home_false_note(self):
        self.assertIn('dashboard not generated yet', self.src)

    def test_r4_has_home_false_no_href(self):
        # The has_home=false branch must create a div, not an <a>
        idx = self.src.find('dashboard not generated yet')
        self.assertNotEqual(idx, -1)
        # Look backward from the note text to find the enclosing card creation
        region = self.src[max(0, idx - 3000):idx + 100]
        # The non-clickable branch uses createElement('div'), not card-link
        # Confirm there's a div path and the note is not inside an a.card-link context
        self.assertIn("createElement('div')", region)

    def test_r5_unavailable_card_function(self):
        self.assertIn('function _renderUnavailableCard(', self.src)

    def test_r5_unavailable_badge_dim(self):
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('badge-dim', snippet)

    def test_r5_unavailable_shows_path(self):
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('repo.path', snippet)

    def test_r5_unavailable_prune_guidance(self):
        # OQ-P2 (feature-003/task-014): the guidance's cmdCode.textContent (the
        # actual rendered command, not a doc comment) must read the untrack-only
        # 'aid projects remove <path>' -- the stale tool-uninstall form is gone
        # from that assignment.
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('aid projects remove', snippet)
        self.assertNotIn("cmdCode.textContent = 'aid remove --target", snippet)

    def test_r5_unavailable_no_write_button(self):
        # UI-P2 (feature-003/task-014): the Remove control is built by the shared
        # _buildCardActions/_renderRemoveIdle helpers into a SIBLING .card-actions
        # row (KI-004 scaffold) -- never a <button> literally inside
        # _renderUnavailableCard's own card body. This snippet window covers only
        # the card body (status glyph / path / read-only prune guidance).
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertNotIn("createElement('button')", snippet)

    def test_r5_unavailable_verify_step(self):
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('Verify', snippet)

    def test_r5_unavailable_uses_ol(self):
        # Step-by-step guidance uses an ordered list
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn("createElement('ol')", snippet)

    def test_r6_empty_repos_empty_registry_state(self):
        # When repos is empty, empty-registry div is shown
        idx = self.src.find('function renderRepoGrid(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 600]
        self.assertIn('empty-registry', snippet)

    def test_r6_empty_repos_never_blank(self):
        # Must show the empty-registry state (friendly message) -- the div exists in HTML
        self.assertIn('id="empty-registry"', self.src)
        self.assertIn('aid add', self.src)

    def test_r7_has_kb_affordance(self):
        idx = self.src.find('function _renderRepoCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 4000]
        self.assertIn('has_kb', snippet)
        self.assertIn('badge-purple', snippet)
        self.assertIn("'KB'", snippet)

    def test_r7_has_kb_no_nested_anchor(self):
        # KB chip must NOT be a nested <a> inside the card <a> (invalid HTML)
        idx = self.src.find('has_kb')
        self.assertNotEqual(idx, -1)
        # In the has_kb block, we should see a span/chip, not createElement('a')
        region = self.src[idx:idx + 200]
        self.assertNotIn("createElement('a')", region)

    def test_r8_tools_installed_chips(self):
        idx = self.src.find('function _renderRepoCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('tools_installed', snippet)

    def test_r8_tools_omit_when_empty(self):
        # When tools_installed is empty, the chip row is not added
        idx = self.src.find('function _renderRepoCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 4000]
        # The chip row is only appended if it has children
        self.assertIn('hasChildNodes', snippet)

    def test_desc_em_dash_null(self):
        # null description -> em-dash
        idx = self.src.find('function _renderRepoCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('description', snippet)
        self.assertIn('—', snippet)

    def test_tool_chip_includes_version_after_name(self):
        # Each installed-tool chip shows the AID version after the tool name.
        idx = self.src.find('function _renderRepoCard(')
        snippet = self.src[idx:idx + 4000]
        self.assertIn("' v' + repo.aid_version", snippet)
        self.assertIn('tools[t] + verSuffix', snippet)

    def test_pipeline_summary_line(self):
        # The card shows a line: "<n> pipeline(s) - <m> in progress".
        idx = self.src.find('function _renderRepoCard(')
        snippet = self.src[idx:idx + 4000]
        self.assertIn('repo.pipeline_count', snippet)
        self.assertIn('repo.pipelines_in_progress', snippet)
        self.assertIn('in progress', snippet)


class TestInvariants(unittest.TestCase):
    """INV: Static invariant checks (LC-HOME, NFR2/NFR7)."""

    @classmethod
    def setUpClass(cls):
        cls.src = _CLI_HOME_HTML.read_text(encoding="utf-8")

    def test_inv_no_aid_dir_write(self):
        # Must not write to .aid/
        self.assertNotIn("'.aid/'", self.src)
        self.assertNotIn('".aid/"', self.src)
        self.assertNotIn('writeFile', self.src)
        self.assertNotIn('fs.write', self.src)

    def test_inv_no_llm_import(self):
        # No agent/LLM imports
        for term in ['anthropic', 'openai', 'langchain', 'llm', 'gpt']:
            self.assertNotIn(term, self.src.lower()[:100])  # only check early import area

    def test_inv_same_origin_fetch_only(self):
        # All fetch() calls must be same-origin (no http:// or //)
        self.assertNotRegex(self.src, r"fetch\s*\(\s*['\"]https?://")
        self.assertNotRegex(self.src, r'fetch\s*\(\s*["\']//[^"\']')

    def test_inv_no_write_button(self):
        # The page has no native <form> submit path (NFR2/CSP form-action 'none'):
        # every JS-created <button> is type="button" (feature-001 AC8's write
        # controls -- Add/Remove Project since feature-003/task-014 -- are all
        # fetch-driven, never a literal <button type="submit"> in static markup).
        self.assertNotRegex(self.src, r'<button[^>]+type=["\']submit["\']')

    def test_inv_footer_read_only_text(self):
        self.assertIn('read-only', self.src)

    def test_inv_noscript_present(self):
        self.assertIn('<noscript>', self.src)

    def test_inv_render_repo_grid_function(self):
        self.assertIn('function renderRepoGrid(', self.src)

    def test_inv_poll_loop_single_inflight(self):
        self.assertIn('fetchPending', self.src)

    def test_inv_keep_last_good_on_error(self):
        idx = self.src.find('function onError(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn('lastGoodEnvelope', snippet)


class TestFeature003RegistryUi(unittest.TestCase):
    """
    UI-P1/UI-P2/KI-004 (feature-003-project-registry, task-014): Add/Remove
    Project controls + the shared card-actions sibling-row scaffold.

    AP -- Add Project control (UI-P1).
    RP -- Remove Project control (UI-P2).
    CA -- Shared card-actions sibling-row scaffold (KI-004).
    WE -- write_enabled gating (read once in onSuccess, threaded into render).
    SAFE -- textContent/escHtml-only dynamic text; aria-live; button type.
    """

    @classmethod
    def setUpClass(cls):
        cls.src = _CLI_HOME_HTML.read_text(encoding="utf-8")

    # ---- WE: write_enabled read + threading ----

    def test_we_read_once_in_onsuccess(self):
        idx = self.src.find('function onSuccess(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn('envelope.machine && envelope.machine.write_enabled === true', snippet)
        self.assertIn('currentWriteEnabled = ', snippet)

    def test_we_threaded_into_render_calls(self):
        idx = self.src.find('function onSuccess(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn('renderRepoGrid(envelope.repos, currentWriteEnabled)', snippet)
        self.assertIn('_renderAddProjectControls(currentWriteEnabled)', snippet)

    def test_we_render_repo_grid_accepts_write_enabled_param(self):
        self.assertIn('function renderRepoGrid(repos, writeEnabled)', self.src)

    def test_we_render_repo_card_accepts_write_enabled_param(self):
        self.assertIn('function _renderRepoCard(repo, writeEnabled)', self.src)

    def test_we_render_unavailable_card_accepts_write_enabled_param(self):
        self.assertIn('function _renderUnavailableCard(repo, writeEnabled)', self.src)

    # ---- AP: Add Project control (UI-P1) ----

    def test_ap_slot_anchors_present_in_markup(self):
        self.assertIn('id="add-project-slot"', self.src)
        self.assertIn('id="add-project-slot-empty"', self.src)

    def test_ap_render_function_present(self):
        self.assertIn('function _renderAddProjectControls(writeEnabled)', self.src)

    def test_ap_render_gated_on_write_enabled(self):
        idx = self.src.find('function _renderAddProjectControls(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 600]
        self.assertIn('if (writeEnabled)', snippet)

    def test_ap_no_native_form_element(self):
        # CSP form-action 'none': no literal <form> anywhere in the page.
        self.assertNotRegex(self.src, r'<form[\s>]')

    def test_ap_submit_posts_project_add(self):
        idx = self.src.find('function _submitAddProject(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn("op: 'project.add'", snippet)
        self.assertIn("args: { path: trimmed }", snippet)
        self.assertIn("fetch('/api/op'", snippet)

    def test_ap_empty_input_no_request(self):
        # Empty (trimmed) input must short-circuit BEFORE the fetch() call.
        idx = self.src.find('function _submitAddProject(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn('if (!trimmed)', snippet)
        self.assertIn('return;', snippet)
        fetch_idx = self.src.find('fetch(', idx)
        return_idx = self.src.find('return;', idx)
        self.assertLess(return_idx, fetch_idx,
                        "the empty-input early return must precede the fetch() call")

    def test_ap_error_detail_rendered_via_textcontent(self):
        idx = self.src.find('function _submitAddProject(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1600]
        self.assertIn('body.detail || body.error', snippet)
        # Rendered by re-invoking the builder (which sets err.textContent), never innerHTML.
        self.assertNotIn('.innerHTML = addProjectState', snippet)

    def test_ap_input_stays_populated_on_error(self):
        idx = self.src.find('function _submitAddProject(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1600]
        # addProjectState.path is set before dispatch and NOT cleared in the
        # else (error) branch -- only the success branch resets it to ''.
        else_idx = snippet.find('} else {')
        self.assertNotEqual(else_idx, -1)
        else_branch = snippet[else_idx:else_idx + 250]
        self.assertNotIn("addProjectState.path = ''", else_branch)

    def test_ap_error_live_region_polite(self):
        idx = self.src.find('function _buildAddProjectControl(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3000]
        self.assertIn("err.setAttribute('aria-live', 'polite')", snippet)

    def test_ap_hint_text_present(self):
        self.assertIn('Add only registers it, it installs nothing', self.src)

    def test_ap_placeholder_absolute_path(self):
        self.assertIn("input.placeholder = '/absolute/path/to/aid/project'", self.src)

    def test_ap_buttons_are_type_button(self):
        idx = self.src.find('function _buildAddProjectControl(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3000]
        # Every button created in this function is explicitly type='button'
        btn_count = snippet.count("createElement('button')")
        type_button_count = snippet.count("type = 'button'")
        self.assertGreaterEqual(type_button_count, btn_count)

    def test_ap_empty_registry_mirrors_add_control(self):
        # Both slots share the SAME builder (not a second independently-invented one).
        idx = self.src.find('function _renderAddProjectControls(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 700]
        self.assertEqual(snippet.count('_buildAddProjectControl()'), 2)

    # ---- CA: shared card-actions sibling-row scaffold (KI-004) ----

    def test_ca_repo_tile_css_present(self):
        self.assertIn('.repo-tile', self.src)

    def test_ca_card_actions_css_present(self):
        self.assertIn('.card-actions', self.src)

    def test_ca_build_card_actions_function_present(self):
        self.assertIn('function _buildCardActions(repo, writeEnabled)', self.src)

    def test_ca_card_actions_gated_on_write_enabled(self):
        idx = self.src.find('function _buildCardActions(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('if (!writeEnabled) return null;', snippet)

    def test_ca_available_card_tile_wraps_card_plus_actions(self):
        # The available-card tile appends the card THEN the actions row as a
        # SIBLING (never nested inside the <a class="card card-link"> itself).
        idx = self.src.find('function _renderRepoCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 5000]
        tile_idx = snippet.find("tile.className = 'repo-tile'")
        self.assertNotEqual(tile_idx, -1)
        region = snippet[tile_idx:tile_idx + 300]
        self.assertIn('tile.appendChild(card)', region)
        self.assertIn('_buildCardActions(repo, writeEnabled)', region)

    def test_ca_unavailable_card_tile_wraps_card_plus_actions(self):
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3000]
        tile_idx = snippet.find("tile.className = 'repo-tile'")
        self.assertNotEqual(tile_idx, -1)
        region = snippet[tile_idx:tile_idx + 300]
        self.assertIn('tile.appendChild(card)', region)
        self.assertIn('_buildCardActions(repo, writeEnabled)', region)

    def test_ca_grid_appends_renderrepocard_result_directly(self):
        # renderRepoGrid appends whatever _renderRepoCard returns (the tile, not
        # the bare card) -- no separate re-wrapping at the call site.
        idx = self.src.find('function renderRepoGrid(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1500]
        self.assertIn('grid.appendChild(_renderRepoCard(sorted[i], writeEnabled))', snippet)

    # ---- RP: Remove Project control (UI-P2) ----

    def test_rp_idle_confirm_functions_present(self):
        self.assertIn('function _renderRemoveIdle(item, repo)', self.src)
        self.assertIn('function _renderRemoveConfirm(item, repo)', self.src)
        self.assertIn('function _submitRemoveProject(', self.src)

    def test_rp_idle_button_labelled_remove(self):
        idx = self.src.find('function _renderRemoveIdle(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn("removeBtn.textContent = 'Remove'", snippet)

    def test_rp_confirm_is_inline_flip_not_window_confirm(self):
        # Decided design (feature-003 SPEC UI-P2): inline button-flip, NEVER
        # window.confirm.
        self.assertNotIn('window.confirm', self.src)
        idx = self.src.find('function _renderRemoveConfirm(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 900]
        self.assertIn("confirmBtn.textContent = 'Confirm untrack'", snippet)
        self.assertIn("cancelBtn.textContent = 'Cancel'", snippet)

    def test_rp_confirm_copy_text(self):
        self.assertIn('Untracks this project from the dashboard. No files are removed.', self.src)

    def test_rp_confirm_flip_is_dom_mutation_not_refetch(self):
        # Clicking "Remove" calls _renderRemoveConfirm(item, repo) directly --
        # it must NOT trigger doFetch() (that would be a whole-grid re-render,
        # not an in-place flip).
        idx = self.src.find('function _renderRemoveIdle(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn('_renderRemoveConfirm(item, repo)', snippet)
        self.assertNotIn('doFetch()', snippet)

    def test_rp_submit_posts_project_remove_with_target_id(self):
        idx = self.src.find('function _submitRemoveProject(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 700]
        self.assertIn("op: 'project.remove'", snippet)
        self.assertIn('target: { id: repo.id }', snippet)
        self.assertIn("fetch('/api/op'", snippet)

    def test_rp_success_triggers_dofetch(self):
        idx = self.src.find('function _submitRemoveProject(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 900]
        self.assertIn('doFetch();', snippet)

    def test_rp_error_detail_via_textcontent_aria_live(self):
        idx = self.src.find('function _renderRemoveConfirm(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn("err.setAttribute('aria-live', 'polite')", snippet)
        idx2 = self.src.find('function _submitRemoveProject(')
        snippet2 = self.src[idx2:idx2 + 700]
        self.assertIn('errEl.textContent', snippet2)

    def test_rp_replaces_unavailable_prune_guidance_when_write_enabled(self):
        # UI-P2: the prune-guidance <ol> is built ONLY inside the !writeEnabled
        # branch -- it is REPLACED (not supplemented) by the card-actions Remove
        # control when write_enabled is true.
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        guard_idx = snippet.find('if (!writeEnabled) {')
        self.assertNotEqual(guard_idx, -1)
        ol_idx = snippet.find("createElement('ol')")
        self.assertNotEqual(ol_idx, -1)
        self.assertGreater(ol_idx, guard_idx,
                           "the prune-guidance <ol> must be built inside the !writeEnabled guard")

    # ---- SAFE: no innerHTML with dynamic/untrusted text ----

    def test_safe_no_innerhtml_with_addprojectstate_value(self):
        self.assertNotIn('.innerHTML = addProjectState', self.src)

    def test_safe_no_innerhtml_with_repo_path_or_detail(self):
        self.assertNotRegex(self.src, r"\.innerHTML\s*=\s*[^;]*\brepo\.(path|id)")
        self.assertNotRegex(self.src, r"\.innerHTML\s*=\s*[^;]*\bdetail\b")


class TestFeature004UpdateToolsUi(unittest.TestCase):
    """
    UI (feature-004-update-tools, task-016): the global "Update CLI"
    (tools.update-self) and per-repo "Update Tools" (tools.update) controls,
    the restart-advisory banner (KI-002/KI-006), and the busy-state (KI-003).

    UC -- global "Update CLI" (machine panel).
    UT -- per-repo "Update Tools" (shared card-actions scaffold, KI-004 reuse).
    RA -- restart-advisory banner.
    BS -- busy-state (disable + "Updating..." until the op resolves).
    """

    @classmethod
    def setUpClass(cls):
        cls.src = _CLI_HOME_HTML.read_text(encoding="utf-8")

    # ---- UC: global "Update CLI" control (machine panel) ----

    def test_uc_idle_function_present(self):
        self.assertIn('function _renderUpdateSelfIdle(item)', self.src)

    def test_uc_submit_function_present(self):
        self.assertIn('function _submitUpdateSelf(btn, errEl)', self.src)

    def test_uc_button_labelled_update_cli(self):
        idx = self.src.find('function _renderUpdateSelfIdle(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 500]
        self.assertIn("btn.textContent = 'Update CLI'", snippet)

    def test_uc_gated_on_machine_write_enabled(self):
        # renderMachinePanel appends the action row only when
        # machine.write_enabled === true (missing => false, fail-safe).
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3000]
        self.assertIn('machine.write_enabled === true', snippet)
        self.assertIn('_renderUpdateSelfIdle(updateItem)', snippet)

    def test_uc_reuses_card_actions_class(self):
        # The machine-panel action row reuses the SAME .card-actions /
        # .card-action-item classes as the repo-card scaffold (KI-004) --
        # not an independently-invented class.
        idx = self.src.find('function renderMachinePanel(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 3000]
        self.assertIn("updateActions.className = 'card-actions'", snippet)
        self.assertIn("updateItem.className = 'card-action-item'", snippet)

    def test_uc_submit_posts_tools_update_self(self):
        idx = self.src.find('function _submitUpdateSelf(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn("op: 'tools.update-self'", snippet)
        self.assertIn("fetch('/api/op'", snippet)

    def test_uc_busy_state_disable_and_label(self):
        idx = self.src.find('function _submitUpdateSelf(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn('btn.disabled = true', snippet)
        self.assertIn("btn.textContent = 'Updating...'", snippet)

    def test_uc_ok_refetches_and_shows_restart_advisory(self):
        idx = self.src.find('function _submitUpdateSelf(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn('doFetch(function () { showRestartAdvisory(); });', snippet)

    def test_uc_failure_reenables_button_and_shows_error(self):
        idx = self.src.find('function _submitUpdateSelf(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        else_idx = snippet.find('} else {')
        self.assertNotEqual(else_idx, -1)
        else_branch = snippet[else_idx:else_idx + 300]
        self.assertIn('btn.disabled = false', else_branch)
        self.assertIn("btn.textContent = 'Update CLI'", else_branch)
        self.assertIn('errEl.textContent', else_branch)

    def test_uc_error_live_region_polite(self):
        idx = self.src.find('function _renderUpdateSelfIdle(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 600]
        self.assertIn("err.setAttribute('aria-live', 'polite')", snippet)

    # ---- UT: per-repo "Update Tools" control (shared card-actions scaffold) ----

    def test_ut_idle_function_present(self):
        self.assertIn('function _renderUpdateToolsIdle(item, repo)', self.src)

    def test_ut_submit_function_present(self):
        self.assertIn('function _submitUpdateTools(repo, btn, errEl)', self.src)

    def test_ut_button_labelled_update_tools(self):
        idx = self.src.find('function _renderUpdateToolsIdle(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 500]
        self.assertIn("btn.textContent = 'Update Tools'", snippet)

    def test_ut_gated_on_repo_available_inside_shared_scaffold(self):
        # _buildCardActions (the SAME shared scaffold task-014 introduced,
        # KI-004) gates the Update Tools item on repo.available === true, in
        # addition to the write_enabled gate already applied by its caller.
        idx = self.src.find('function _buildCardActions(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        self.assertIn('if (!writeEnabled) return null;', snippet)
        self.assertIn('repo.available === true', snippet)
        self.assertIn('_renderUpdateToolsIdle(updateItem, repo)', snippet)
        self.assertIn('_renderRemoveIdle(item, repo)', snippet)

    def test_ut_submit_posts_tools_update_to_per_repo_route(self):
        idx = self.src.find('function _submitUpdateTools(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1600]
        self.assertIn("op: 'tools.update'", snippet)
        self.assertIn("fetch('/r/' + repo.id + '/api/op'", snippet)

    def test_ut_busy_state_disable_and_label(self):
        idx = self.src.find('function _submitUpdateTools(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn('btn.disabled = true', snippet)
        self.assertIn("btn.textContent = 'Updating...'", snippet)

    def test_ut_captures_pre_op_version_before_fetch(self):
        # The pre-op machine.aid_version must be captured BEFORE the fetch()
        # call fires (so it reflects the value prior to this op's side effect).
        idx = self.src.find('function _submitUpdateTools(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1600]
        pre_idx = snippet.find('var preVersion =')
        fetch_idx = snippet.find("fetch('/r/'")
        self.assertNotEqual(pre_idx, -1)
        self.assertNotEqual(fetch_idx, -1)
        self.assertLess(pre_idx, fetch_idx,
                        "preVersion must be captured before the fetch() call")

    def test_ut_ok_refetches_and_conditionally_shows_restart_advisory(self):
        # On ok, re-fetch /api/home; show the restart advisory ONLY when the
        # re-fetched machine.aid_version differs from the captured pre-op
        # value (KI-002/KI-006 -- aid update's stale-CLI self-update preamble).
        idx = self.src.find('function _submitUpdateTools(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1800]
        self.assertIn('doFetch(function (envelope) {', snippet)
        self.assertIn('postVersion !== preVersion', snippet)
        self.assertIn('showRestartAdvisory();', snippet)

    def test_ut_failure_reenables_button_and_shows_error(self):
        idx = self.src.find('function _submitUpdateTools(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1800]
        else_idx = snippet.find('} else {')
        self.assertNotEqual(else_idx, -1)
        else_branch = snippet[else_idx:else_idx + 300]
        self.assertIn('btn.disabled = false', else_branch)
        self.assertIn("btn.textContent = 'Update Tools'", else_branch)
        self.assertIn('errEl.textContent', else_branch)

    def test_ut_error_live_region_polite(self):
        idx = self.src.find('function _renderUpdateToolsIdle(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 600]
        self.assertIn("err.setAttribute('aria-live', 'polite')", snippet)

    def test_ut_unavailable_card_gets_no_update_tools_button(self):
        # _buildCardActions is called from BOTH _renderRepoCard (available)
        # and _renderUnavailableCard (stale); the Update Tools item must only
        # render when repo.available === true, so an unavailable card never
        # gets the button (it has no .aid/manifest to update).
        idx = self.src.find('function _buildCardActions(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1200]
        avail_guard_idx = snippet.find('if (repo.available === true) {')
        update_idx = snippet.find('_renderUpdateToolsIdle(')
        self.assertNotEqual(avail_guard_idx, -1)
        self.assertNotEqual(update_idx, -1)
        self.assertLess(avail_guard_idx, update_idx,
                        "_renderUpdateToolsIdle must be called inside the repo.available guard")

    # ---- RA: restart-advisory banner (KI-002/KI-006) ----

    def test_ra_banner_markup_present(self):
        self.assertIn('id="restart-advisory-banner"', self.src)
        self.assertIn('id="restart-advisory-dismiss"', self.src)

    def test_ra_banner_hidden_by_default(self):
        idx = self.src.find('id="restart-advisory-banner"')
        self.assertNotEqual(idx, -1)
        snippet = self.src[max(0, idx - 50):idx + 200]
        self.assertIn('display:none', snippet)

    def test_ra_banner_copy_text(self):
        self.assertIn(
            'AID CLI updated &#8212; restart <code>aid dashboard</code> to load the new dashboard code.',
            self.src,
        )

    def test_ra_show_hide_functions_present(self):
        self.assertIn('function showRestartAdvisory()', self.src)
        self.assertIn('function hideRestartAdvisory()', self.src)

    def test_ra_dismiss_button_wired_to_hide(self):
        idx = self.src.find("getElementById('restart-advisory-dismiss')")
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 200]
        self.assertIn('hideRestartAdvisory', snippet)

    def test_ra_not_a_native_alert_or_confirm(self):
        # Dismissible in-page banner, never a blocking browser dialog.
        self.assertNotIn('window.alert', self.src)
        self.assertNotIn('window.confirm', self.src)

    # ---- doFetch onLoaded callback plumbing ----

    def test_dofetch_accepts_optional_onloaded_callback(self):
        idx = self.src.find('function doFetch(onLoaded)')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 700]
        self.assertIn("if (typeof onLoaded === 'function') onLoaded(envelope);", snippet)


if __name__ == "__main__":
    unittest.main()
