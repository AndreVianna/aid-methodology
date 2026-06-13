"""
test_cli_home_html.py -- Static/DOM assertions for dashboard/index.html (LC-HOME, task-053).

This file is the CLI-home page served at / by the multi-repo server (DR-2).  It polls
/api/home (DM-2) and renders the machine panel + repo-card grid.

No browser required.  Tests inspect the HTML source and verify:

  S1  -- Structural: page shell (top-bar, brand, freshness-badge, interval-input,
          theme-toggle, schema-mismatch-banner, machine-panel, repo-section,
          repo-grid, empty-registry, footer, noscript).
  S2  -- Structural: reads envelope.generated_by (not model.generated_by).
  S3  -- Structural: fetch target is '/api/home' (same-origin absolute path, not /api/model).
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

    # S3 -- fetch target is /api/home (same-origin)
    def test_s3_fetches_api_home(self):
        fetch_calls = re.findall(r"fetch\s*\(\s*['\"]([^'\"]+)['\"]", self.src)
        self.assertTrue(len(fetch_calls) > 0, "No fetch() call found")
        for url in fetch_calls:
            self.assertEqual(url, '/api/home',
                             f"Unexpected fetch target: {url!r} -- only /api/home allowed")

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
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn('aid remove --target', snippet)

    def test_r5_unavailable_no_write_button(self):
        idx = self.src.find('function _renderUnavailableCard(')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        # Must NOT create a button that mutates anything
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
        # The page is read-only (NFR2): no submit/write buttons
        # (unavailable card has no button; the prune guidance is text-only)
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


if __name__ == "__main__":
    unittest.main()
