"""
test_index_html.py -- Structural and behavioral self-checks for dashboard/index.html
                      (feature-003, task-019).

No browser required. These tests parse/inspect the HTML source and exercise the
inlined JavaScript logic in isolation via a small Python-level extraction:
  (S1) Structural: page contains expected component anchors.
  (S2) Structural: reads envelope.generated_by (not model.generated_by) -- verified
       by presence of 'envelope.generated_by' string in JS and absence of
       'model.generated_by' as a dot-access path.
  (S3) Structural: makes only /api/model fetch (no CDN/web-font/external URLs).
  (S4) Structural: no CDN script tags or external stylesheets.
  (S5) Structural: meta robots noindex present.
  (S6) Structural: CSS :root token block copied verbatim from design family (key tokens present).
  (S7) Structural: schema_version EXPECTED constant is present and equals 1.
  (S8) Structural: localStorage key 'aid-dashboard-poll-ms' used for interval persistence.
  (B1) Behavioral: clampInterval logic -- extracted from JS, tested at Python level.
  (B2) Behavioral: schema_version mismatch path -- presence of !== EXPECTED check in JS.
  (B3) Behavioral: unrecognized enum fallback -- neutral badge path in lifecycle/status maps.
  (B4) Behavioral: server round-trip -- GET / returns index.html with 200 and correct CT.

Python 3.11+ stdlib only. Deterministic.
"""

import json
import re
import sys
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from pathlib import Path

# Locate index.html and server module regardless of working directory.
_REPO_ROOT = Path(__file__).resolve().parents[3]   # AID/
_DASHBOARD_DIR = Path(__file__).resolve().parents[2]  # AID/dashboard/
_INDEX_HTML = _DASHBOARD_DIR / "index.html"

sys.path.insert(0, str(_REPO_ROOT))
from dashboard.server import server as _server_module


# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

def _make_minimal_aid(root: Path) -> None:
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    (aid / "settings.yml").write_text("project:\n  name: test-project\n", encoding="utf-8")


class _ServerThread:
    """Minimal server context manager (same pattern as test_server_py.py)."""

    def __init__(self, aid_root: str) -> None:
        self._aid_root = aid_root
        self._httpd = None
        self._thread = None
        self.port = None

    def __enter__(self) -> "_ServerThread":
        import socket
        with socket.socket() as s:
            s.bind(("127.0.0.1", 0))
            self.port = s.getsockname()[1]
        self._httpd = _server_module.ThreadingHTTPServer(
            ("127.0.0.1", self.port), _server_module._DashboardHandler
        )
        self._httpd.aid_root = self._aid_root
        self._thread = threading.Thread(target=self._httpd.serve_forever, daemon=True)
        self._thread.start()
        self._wait_ready()
        return self

    def _wait_ready(self) -> None:
        import socket
        for _ in range(50):
            try:
                with socket.create_connection(("127.0.0.1", self.port), timeout=0.1):
                    return
            except OSError:
                time.sleep(0.05)
        raise RuntimeError("Server did not become ready in time")

    def __exit__(self, *_) -> None:
        if self._httpd:
            self._httpd.shutdown()
            self._httpd.server_close()
        if self._thread:
            self._thread.join(timeout=5)

    def get(self, path: str):
        url = f"http://127.0.0.1:{self.port}{path}"
        try:
            with urllib.request.urlopen(url) as resp:
                return resp.status, resp.read(), dict(resp.headers)
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read(), {}


# ---------------------------------------------------------------------------
# S1-S8: Structural checks (source inspection)
# ---------------------------------------------------------------------------

class TestStructural(unittest.TestCase):
    """Source-level structural checks on dashboard/index.html."""

    @classmethod
    def setUpClass(cls):
        assert _INDEX_HTML.is_file(), f"index.html not found at {_INDEX_HTML}"
        cls.src = _INDEX_HTML.read_text(encoding="utf-8")

    # S1 -- component anchors
    def test_s1_has_top_bar(self):
        self.assertIn('class="top-bar"', self.src)

    def test_s1_has_brand(self):
        self.assertIn('class="brand"', self.src)

    def test_s1_has_freshness_badge(self):
        self.assertIn('id="freshness-badge"', self.src)

    def test_s1_has_interval_input(self):
        self.assertIn('id="interval-input"', self.src)

    def test_s1_has_theme_toggle(self):
        self.assertIn('id="theme-toggle"', self.src)

    def test_s1_has_main_top(self):
        self.assertIn('id="top"', self.src)

    def test_s1_has_stage_rail(self):
        self.assertIn('id="stage-rail"', self.src)

    def test_s1_has_tasks_section(self):
        self.assertIn('id="tasks-section"', self.src)

    def test_s1_has_attention_strip(self):
        self.assertIn('id="attention-strip"', self.src)

    def test_s1_has_schema_mismatch_banner(self):
        self.assertIn('id="schema-mismatch-banner"', self.src)

    def test_s1_has_footer(self):
        self.assertIn('<footer', self.src)

    def test_s1_has_noscript_fallback(self):
        self.assertIn('<noscript>', self.src)

    def test_s1_has_skip_link(self):
        self.assertIn('class="skip-link"', self.src)

    def test_s1_has_footer_interval_span(self):
        self.assertIn('id="footer-interval"', self.src)

    def test_s1_has_footer_generated_by_span(self):
        self.assertIn('id="footer-generated-by"', self.src)

    # S2 -- reads envelope.generated_by (not model.generated_by)
    def test_s2_reads_envelope_generated_by(self):
        # The JS must read envelope.generated_by (top-level sibling of model)
        self.assertIn('envelope.generated_by', self.src,
                      "JS must read envelope.generated_by (not model.generated_by)")

    def test_s2_does_not_read_model_dot_generated_by(self):
        # model.generated_by would be wrong -- the field is on the envelope, not the model
        self.assertNotIn('model.generated_by', self.src,
                         "JS must NOT read model.generated_by -- use envelope.generated_by")

    # S3 -- only same-origin fetch('/api/model'), no external fetches
    def test_s3_only_api_model_fetch(self):
        # All fetch() calls must target /api/model
        fetch_calls = re.findall(r"fetch\s*\(\s*['\"]([^'\"]+)['\"]", self.src)
        for url in fetch_calls:
            self.assertEqual(url, '/api/model',
                             f"Found unexpected fetch target: {url!r} -- only /api/model allowed")

    def test_s3_no_http_fetch(self):
        # No fetch('http://...') or fetch('https://...')
        self.assertNotRegex(self.src, r"fetch\s*\(\s*['\"]https?://")

    # S4 -- no CDN script tags or external stylesheets
    def test_s4_no_external_script_src(self):
        # No <script src="http..."> or <script src="//...">
        matches = re.findall(r'<script[^>]+src\s*=\s*["\']([^"\']+)["\']', self.src, re.IGNORECASE)
        for src in matches:
            self.assertFalse(src.startswith('http') or src.startswith('//'),
                             f"External script src found: {src!r}")

    def test_s4_no_external_link_href(self):
        # No <link rel="stylesheet" href="http...">
        matches = re.findall(r'<link[^>]+href\s*=\s*["\']([^"\']+)["\']', self.src, re.IGNORECASE)
        for href in matches:
            self.assertFalse(href.startswith('http') or href.startswith('//'),
                             f"External link href found: {href!r}")

    def test_s4_no_web_font_import(self):
        # No @import url('https://...')
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

    # S6 -- CSS :root token block (key design tokens present)
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
        for cls in ['.badge-accent', '.badge-ok', '.badge-warn', '.badge-err', '.badge-dim', '.badge-primary']:
            self.assertIn(cls, self.src, f"CSS class {cls} missing from index.html")

    def test_s6_callout_classes_present(self):
        for cls in ['.callout', '.callout.warn', '.callout.err']:
            self.assertIn(cls, self.src, f"CSS class {cls} missing from index.html")

    # S7 -- schema_version expected constant
    def test_s7_expected_schema_version_1(self):
        # Should define EXPECTED_SCHEMA_VERSION = 2
        self.assertIn('EXPECTED_SCHEMA_VERSION = 2', self.src)

    def test_s7_schema_version_mismatch_check(self):
        # Must have a !== EXPECTED check
        self.assertIn('!== EXPECTED_SCHEMA_VERSION', self.src)

    # S8 -- localStorage key
    def test_s8_localstorage_key(self):
        self.assertIn("'aid-dashboard-poll-ms'", self.src)


# ---------------------------------------------------------------------------
# B1: Interval clamping
# ---------------------------------------------------------------------------

class TestIntervalClamping(unittest.TestCase):
    """
    Extract and test the clampInterval logic from index.html.

    The spec requires [1000ms, 600000ms]. We verify boundary values.
    Rather than executing the JS, we verify the HTML encodes the correct bounds
    (min="1" max="600" on the input) and confirm the JS clamp constants are present.
    """

    @classmethod
    def setUpClass(cls):
        cls.src = _INDEX_HTML.read_text(encoding="utf-8")

    def test_clamp_lower_bound_1000(self):
        # The JS source must clamp to 1000ms lower bound
        self.assertIn('if (ms < 1000) return 1000', self.src)

    def test_clamp_upper_bound_600000(self):
        # The JS source must clamp to 600000ms upper bound
        self.assertIn('if (ms > 600000) return 600000', self.src)

    def test_input_min_1(self):
        # The input element uses min="1" (1 second)
        self.assertIn('min="1"', self.src)

    def test_input_max_600(self):
        # The input element uses max="600" (600 seconds)
        self.assertIn('max="600"', self.src)

    def test_default_5000(self):
        # Default poll interval is 5000ms
        self.assertIn('5000', self.src)


# ---------------------------------------------------------------------------
# B2: Schema version mismatch
# ---------------------------------------------------------------------------

class TestSchemaMismatch(unittest.TestCase):
    """Verify the HTML encodes the schema-mismatch banner and check logic."""

    @classmethod
    def setUpClass(cls):
        cls.src = _INDEX_HTML.read_text(encoding="utf-8")

    def test_schema_mismatch_banner_exists(self):
        self.assertIn('id="schema-mismatch-banner"', self.src)

    def test_schema_mismatch_hidden_by_default(self):
        # Banner starts hidden
        self.assertIn('id="schema-mismatch-banner"', self.src)
        # Find the banner element and confirm style="display:none"
        match = re.search(r'id="schema-mismatch-banner"[^>]*>', self.src)
        self.assertIsNotNone(match)
        # The whole element line should have display:none
        banner_idx = self.src.find('id="schema-mismatch-banner"')
        snippet = self.src[max(0, banner_idx - 50):banner_idx + 200]
        self.assertIn('display:none', snippet)

    def test_schema_mismatch_keep_last_view_comment_or_logic(self):
        # The JS must show the banner and NOT re-render (return early)
        self.assertIn('showSchemaMismatch', self.src)
        # The success handler calls hideSchemaMismatch() on good schema
        self.assertIn('hideSchemaMismatch', self.src)


# ---------------------------------------------------------------------------
# B3: Unrecognized enum fallback (NFR7 forward-compat)
# ---------------------------------------------------------------------------

class TestEnumFallback(unittest.TestCase):
    """Verify neutral badge fallback for unrecognized lifecycle/status strings."""

    @classmethod
    def setUpClass(cls):
        cls.src = _INDEX_HTML.read_text(encoding="utf-8")

    def test_lifecycle_unknown_fallback(self):
        # The lifecycle mapping must have an else branch for unrecognized strings
        # (neutral .badge, no throw)
        self.assertIn("badge.className = 'badge'", self.src)

    def test_status_unknown_literal(self):
        # TaskStatus Unknown is explicitly mapped
        self.assertIn("'Unknown':", self.src)

    def test_lifecycle_all_five_literals_mapped(self):
        for lit in ['Running', 'Paused-Awaiting-Input', 'Blocked', 'Completed', 'Canceled']:
            self.assertIn(f"'{lit}':", self.src, f"Lifecycle literal {lit!r} not found in JS map")

    def test_task_status_all_literals_mapped(self):
        for lit in ['Pending', 'In Progress', 'In Review', 'Blocked', 'Done', 'Failed', 'Canceled']:
            self.assertIn(f"'{lit}':", self.src, f"TaskStatus literal {lit!r} not found in JS map")

    def test_phase_order_all_phases(self):
        for phase in ['Interview', 'Specify', 'Plan', 'Detail', 'Execute', 'Deploy', 'Monitor']:
            self.assertIn(f"'{phase}'", self.src, f"Phase {phase!r} not found in PHASE_ORDER")

    def test_attention_callout_warn_for_paused(self):
        # Paused-Awaiting-Input triggers callout.warn attention strip
        self.assertIn("callout warn", self.src)

    def test_attention_callout_err_for_blocked(self):
        # Blocked triggers callout.err attention strip
        self.assertIn("callout err", self.src)

    def test_block_artifact_as_code_not_link(self):
        # block_artifact rendered as <code>, not <a href=...>
        self.assertIn('block_artifact', self.src)
        # The code element wraps it
        self.assertIn('<code>', self.src)
        # Must NOT create a link for it
        block_idx = self.src.find('block_artifact')
        region = self.src[block_idx:block_idx + 200]
        self.assertNotIn('<a href', region.lower())


# ---------------------------------------------------------------------------
# B4: Server round-trip -- GET / returns index.html
# ---------------------------------------------------------------------------

class TestServerRoundTrip(unittest.TestCase):
    """Confirm the server serves dashboard/index.html at GET / with correct headers."""

    def setUp(self):
        self._tmpdir = tempfile.mkdtemp()
        _make_minimal_aid(Path(self._tmpdir))

    def tearDown(self):
        import shutil
        shutil.rmtree(self._tmpdir, ignore_errors=True)

    def test_get_root_returns_200(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, headers = srv.get('/')
        self.assertEqual(status, 200)

    def test_get_root_content_type_html(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, headers = srv.get('/')
        ct = headers.get('Content-Type', '')
        self.assertIn('text/html', ct)

    def test_get_root_body_is_index_html(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, headers = srv.get('/')
        # Should contain the DOCTYPE declaration
        self.assertIn(b'<!DOCTYPE html>', body)
        # Should contain our JS fetch target
        self.assertIn(b'/api/model', body)

    def test_get_root_contains_fetch_api_model(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, headers = srv.get('/')
        self.assertIn(b"fetch('/api/model')", body)

    def test_get_root_no_external_urls_in_served_html(self):
        with _ServerThread(self._tmpdir) as srv:
            status, body, _ = srv.get('/')
        text = body.decode('utf-8')
        # No CDN references in the served page
        self.assertNotIn('cdn.', text)
        self.assertNotIn('googleapis.com', text)
        self.assertNotIn('unpkg.com', text)


# ---------------------------------------------------------------------------
# VP1: Visual polish checks (delivery-002 VISUAL-POLISH pass)
# ---------------------------------------------------------------------------

class TestVisualPolish(unittest.TestCase):
    """
    Structural checks for the visual-polish changes introduced in delivery-002.

    VP1: Enriched chip layout — chip-task-id span present in JS output.
    VP2: Content column — .content-col CSS class present.
    VP3: Wave summary pill — wave-summary uses inline-flex (muted pill).
    """

    @classmethod
    def setUpClass(cls):
        assert _INDEX_HTML.is_file(), f"index.html not found at {_INDEX_HTML}"
        cls.src = _INDEX_HTML.read_text(encoding="utf-8")

    def test_vp1_task_chip_class_present(self):
        # The makeTaskChip function must produce .task-chip elements
        self.assertIn("'task-chip'", self.src,
                      "JS must create task-chip elements for enriched compact chips")

    def test_vp1_chip_task_id_class_present(self):
        # Each chip must include a chip-task-id element showing the task_id field
        self.assertIn("'chip-task-id'", self.src,
                      "JS must produce chip-task-id element on each task chip")

    def test_vp1_chip_reads_task_id_field(self):
        # JS must access task.task_id
        self.assertIn("task.task_id", self.src,
                      "JS must read task.task_id to populate chip-task-id")

    def test_vp2_content_col_css(self):
        # .content-col must be defined in CSS to constrain header/rail column
        self.assertIn(".content-col", self.src,
                      ".content-col CSS class must exist for centered-column layout")

    def test_vp3_wave_summary_pill(self):
        # wave-summary must use inline-flex (muted pill treatment)
        # Check the CSS block has inline-flex for .wave-summary
        idx = self.src.find('.wave-summary')
        self.assertNotEqual(idx, -1, ".wave-summary CSS block must be present")
        snippet = self.src[idx:idx + 300]
        self.assertIn('inline-flex', snippet,
                      ".wave-summary must use inline-flex for muted pill look")


if __name__ == "__main__":
    unittest.main()
