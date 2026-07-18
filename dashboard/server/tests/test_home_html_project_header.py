"""
test_home_html_project_header.py -- Static/DOM assertions for the project-header panel
(task-006, feature-002-project-header-edit, delivery-001) in dashboard/home.html.

Mirrors test_cli_home_html.py's established convention for this codebase: no browser
required. Tests inspect the HTML/JS source text and verify presence/placement/order of
the new markup and functions -- never execute the client-side JS.

  S1  -- Structural: #project-header container + a persistent aria-live status region,
          both ABOVE the existing Knowledge Base heading/section.
  S2  -- Structural: _renderProjectHeader is the FIRST statement inside renderMainPage.
  S3  -- Structural: reuses .work-overview / .btn-ghost / .badge / .callout verbatim
          (no new CSS framework); reuses .interval-input as the text/select input model.
  R1  -- Render: settings.set op string + POST target ./api/op present in the client op
          call; the write_enabled envelope graft is present in onSuccess.
  R2  -- Render: grade <select> validated against ^[A-F][+-]?$ (client mirror).
  R3  -- Render: name/description KI-001 charset guard (newline / double-quote /
          backslash) + the empty-name-required / empty-description-allowed rules.
  R4  -- Render: KB button preserves ./kb.html + the approved/outdated clickability
          rule, and uses aria-disabled (not native disabled / removal) when not
          clickable.
  A1  -- Accessibility: aria-live="polite" status region; aria-expanded on the edit
          toggle buttons; aria-label on every edit input/toggle.

Python 3.11+ stdlib only. Deterministic.
"""

import re
import sys
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # AID/
_HOME_HTML = _REPO_ROOT / "dashboard" / "home.html"


class TestStructuralPlacement(unittest.TestCase):
    """S1-S3: container placement, render-order, style reuse."""

    @classmethod
    def setUpClass(cls):
        assert _HOME_HTML.is_file(), f"dashboard/home.html not found at {_HOME_HTML}"
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_s1_project_header_container_present(self):
        self.assertIn('id="project-header"', self.src)

    def test_s1_project_header_status_live_region_present(self):
        self.assertIn('id="project-header-status"', self.src)
        # It's declared once, statically in the markup -- never rebuilt by JS
        # (innerHTML='' on #project-header never touches this sibling id).
        self.assertIn('aria-live="polite"', self.src)

    def test_s1_project_header_precedes_knowledge_base_heading(self):
        idx_header = self.src.find('id="project-header"')
        idx_kb_heading = self.src.find('Knowledge Base</h2>')
        self.assertNotEqual(idx_header, -1)
        self.assertNotEqual(idx_kb_heading, -1)
        self.assertLess(idx_header, idx_kb_heading,
                         "#project-header must render above the existing Knowledge Base band")

    def test_s2_render_project_header_function_defined(self):
        self.assertIn('function _renderProjectHeader(model)', self.src)

    def test_s2_render_project_header_called_first_in_render_main_page(self):
        idx_fn = self.src.find('function renderMainPage(model) {')
        self.assertNotEqual(idx_fn, -1)
        snippet = self.src[idx_fn:idx_fn + 300]
        # First statement in the function body (right after the opening brace).
        self.assertRegex(snippet, r"function renderMainPage\(model\) \{\s*\n\s*_renderProjectHeader\(model\);")

    def test_s3_panel_reuses_work_overview_class(self):
        idx = self.src.find('function _renderProjectHeader(model)')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 1500]
        self.assertIn("panel.className = 'work-overview'", snippet)

    def test_s3_reuses_btn_ghost_badge_callout_interval_input(self):
        idx = self.src.find('function _renderProjectHeaderNameRow(')
        idxEnd = self.src.find('function _renderProjectHeaderGradeRow(')
        self.assertNotEqual(idx, -1)
        self.assertNotEqual(idxEnd, -1)
        snippet = self.src[idx:idxEnd]
        self.assertIn("'btn-ghost'", snippet)
        self.assertIn("interval-input", snippet)
        grade_snippet = self.src[idxEnd:idxEnd + 2000]
        self.assertIn("'badge'", grade_snippet)

    def test_s3_error_callout_reuses_callout_err(self):
        idx = self.src.find('function _renderProjectHeader(model)')
        snippet = self.src[idx:idx + 1500]
        self.assertIn("'callout err'", snippet)


class TestSettingsSetClientCall(unittest.TestCase):
    """R1: the settings.set op call + the write_enabled envelope graft."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r1_post_settings_set_function_defined(self):
        self.assertIn('function _postSettingsSet(path, value, onDone)', self.src)

    def test_r1_posts_to_relative_api_op(self):
        idx = self.src.find('function _postSettingsSet(')
        snippet = self.src[idx:idx + 600]
        self.assertIn("fetch('./api/op'", snippet)
        self.assertIn("method: 'POST'", snippet)
        self.assertIn("op: 'settings.set'", snippet)

    def test_r1_no_work_id_target_project_scoped(self):
        idx = self.src.find('function _postSettingsSet(')
        snippet = self.src[idx:idx + 600]
        self.assertIn("target: {}", snippet)

    def test_r1_write_enabled_graft_present_in_on_success(self):
        idx = self.src.find('function onSuccess(envelope)')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 2000]
        self.assertIn("lastGoodModel.write_enabled = (envelope.write_enabled === true)", snippet)

    def test_r1_write_enabled_graft_follows_details_graft(self):
        idx = self.src.find('function onSuccess(envelope)')
        snippet = self.src[idx:idx + 2000]
        idx_details = snippet.find("lastGoodModel.details = envelope.details")
        idx_write_enabled = snippet.find("lastGoodModel.write_enabled")
        self.assertNotEqual(idx_details, -1)
        self.assertNotEqual(idx_write_enabled, -1)
        self.assertLess(idx_details, idx_write_enabled)

    def test_r1_targeted_refetch_calls_on_success(self):
        idx = self.src.find('function _refetchModelForHeader()')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 400]
        self.assertIn("fetch('./api/model')", snippet)
        self.assertIn("onSuccess(envelope)", snippet)


class TestClientSideValidation(unittest.TestCase):
    """R2-R3: client-side mirror of the settings.set arg-schema."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r2_grade_regex_present(self):
        idx = self.src.find('function _validateSettingValue(path, value)')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 800]
        self.assertIn(r"/^[A-F][+-]?$/", snippet)

    def test_r3_newline_double_quote_backslash_rejected(self):
        idx = self.src.find('function _validateSettingValue(path, value)')
        snippet = self.src[idx:idx + 800]
        self.assertIn("indexOf('\\n')", snippet)
        self.assertIn('indexOf(\'"\')', snippet)
        self.assertIn("indexOf('\\\\')", snippet)

    def test_r3_empty_name_required_empty_description_allowed(self):
        idx = self.src.find('function _validateSettingValue(path, value)')
        snippet = self.src[idx:idx + 800]
        self.assertIn("project.name' && value === ''", snippet)
        # No project.description-specific empty rejection anywhere in the validator --
        # an empty string simply falls through to `return null;` (allowed / clears it).
        self.assertNotIn("project.description' && value === ''", snippet)

    def test_r3_grade_alphabet_matches_server_and_writer(self):
        # Same alphabet as server.py's _RE_GRADE / server.mjs's RE_GRADE / write-setting.sh.
        server_py = (_REPO_ROOT / "dashboard" / "server" / "server.py").read_text(encoding="utf-8")
        server_mjs = (_REPO_ROOT / "dashboard" / "server" / "server.mjs").read_text(encoding="utf-8")
        self.assertIn(r're.compile(r"^[A-F][+-]?$")', server_py)
        self.assertIn(r"/^[A-F][+-]?$/", server_mjs)


class TestKbButton(unittest.TestCase):
    """R4: the "Open Knowledge Base" button preserves target + clickability rule."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_r4_kb_button_function_defined(self):
        self.assertIn('function _renderProjectHeaderKbButton(kbState)', self.src)

    def test_r4_href_is_relative_kb_html(self):
        idx = self.src.find('function _renderProjectHeaderKbButton(')
        snippet = self.src[idx:idx + 1500]
        self.assertIn("link.href = './kb.html';", snippet)

    def test_r4_clickable_only_when_approved_or_outdated(self):
        idx = self.src.find('function _renderProjectHeaderKbButton(')
        snippet = self.src[idx:idx + 1500]
        self.assertIn("status === 'approved' || status === 'outdated'", snippet)

    def test_r4_disabled_variant_uses_aria_disabled_not_native_disabled(self):
        idx = self.src.find('function _renderProjectHeaderKbButton(')
        snippet = self.src[idx:idx + 1500]
        self.assertIn("setAttribute('aria-disabled', 'true')", snippet)
        self.assertNotIn("btn.disabled = true", snippet)

    def test_r4_five_state_label_map_present(self):
        idx = self.src.find('var PROJECT_HEADER_KB_LABEL')
        self.assertNotEqual(idx, -1)
        snippet = self.src[idx:idx + 300]
        for state in ("pending", "generating", "preparing", "outdated"):
            self.assertIn(state, snippet)


class TestAccessibility(unittest.TestCase):
    """A1: aria-live status region, aria-expanded toggles, labelled inputs."""

    @classmethod
    def setUpClass(cls):
        cls.src = _HOME_HTML.read_text(encoding="utf-8")

    def test_a1_edit_toggle_buttons_carry_aria_expanded(self):
        idx_name = self.src.find('function _renderProjectHeaderNameRow(')
        idx_desc_end = self.src.find('function _renderProjectHeaderGradeRow(')
        snippet = self.src[idx_name:idx_desc_end]
        self.assertEqual(snippet.count("aria-expanded', 'false'"), 2,
                          "both the name and description Edit buttons carry aria-expanded=false")

    def test_a1_inputs_are_labelled(self):
        idx_name = self.src.find('function _renderProjectHeaderNameRow(')
        idx_desc_end = self.src.find('function _renderProjectHeaderGradeRow(')
        snippet = self.src[idx_name:idx_desc_end]
        self.assertIn("aria-label', 'Project name'", snippet)
        self.assertIn("aria-label', 'Project description'", snippet)

    def test_a1_grade_select_labelled_via_for_id_pairing(self):
        idx = self.src.find('function _renderProjectHeaderGradeRow(')
        snippet = self.src[idx:idx + 1200]
        self.assertIn("setAttribute('for', 'project-header-grade-select')", snippet)
        self.assertIn("select.id = 'project-header-grade-select'", snippet)


if __name__ == "__main__":
    unittest.main()
