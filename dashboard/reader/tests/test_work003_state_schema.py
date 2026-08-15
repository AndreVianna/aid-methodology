"""
test_work003_state_schema.py -- work-003-state-schema task-002.

Covers the dual-format (frontmatter-first, legacy-prose-fallback) STATE.md read
added by task-002:
  - state_schema.py primitives: parse_frontmatter_scalars (flat + one-level
    nested + rollout-safety placeholder filtering), parse_bool_yesno (yes/no/
    true/false normalization, closing the PyYAML-vs-js-yaml twin-parity
    landmine), parse_header_bold_field (legacy header-blockquote fallback),
    resolve_kind (pipeline.initiator -> display verb via the shortcut-catalog
    mirror table).
  - parse_state_md: frontmatter-only / legacy-prose-only / mixed input shapes
    for lifecycle/phase/active_skill/updated/pause_reason/block_reason/
    block_artifact, work_path (pipeline.path), kind (pipeline.initiator),
    started (+ created backfill), minimum_grade, user_approved.
  - parse_kb_state / _parse_kb_summary_approval: frontmatter-first summary
    approval + the newly-captured kb_status/kb_grade/last_kb_review, and the
    KbStateRef.source_mode extension (gate criteria #3).
  - parse_task_state_md / parse_delivery_state_md: frontmatter-first read for
    the per-task and per-delivery scalar cells.
  - read_repo() integration: work_path resolution from pipeline.path across
    all three layouts (legacy monolithic / flat / hierarchical), including the
    hierarchical "full" fallback default fix.
  - Cross-twin parity (Python read_repo() vs Node readRepo()) computed
    in-process via a bounded subprocess -- no server, no port, no *parity*.sh
    script (per work-003-state-schema task-002 verification posture: the
    canonical test-dashboard-parity*.sh scripts hang on this box and are
    intentionally not invoked here).

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo
from dashboard.reader.models import KbStatus, Lifecycle, Phase, SourceMode
from dashboard.reader.parsers import (
    _parse_kb_summary_approval,
    parse_delivery_state_md,
    parse_kb_state,
    parse_state_md,
    parse_task_state_md,
)
from dashboard.reader.state_schema import (
    SHORTCUT_KIND_MAP,
    parse_bool_yesno,
    parse_header_bold_field,
    parse_state_document,
    resolve_kind,
)

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"
_MANIFEST = _REPO_ROOT / "dashboard" / "MANIFEST"


# ---------------------------------------------------------------------------
# state_schema.py primitives
# ---------------------------------------------------------------------------

class TestParseFrontmatterScalars(unittest.TestCase):
    """parse_state_document: whole-document (was: fenced-frontmatter-only)
    scalar/nested-mapping read + rollout safety (work-009-refactor task-016:
    parse_frontmatter_scalars was EXTENDED into this whole-document parser
    and renamed, per SPEC.md sec:L-3 -- 'generalises from a fenced block to a
    whole document'. Class kept at its original name/subject; every test
    below drops the '---' fence (no longer needed -- the WHOLE input is now
    the document, sec:D-1) and reads the returned NESTED dict tree instead of
    the retired flat dot-joined shape."""

    def test_flat_scalar(self):
        data, _warnings = parse_state_document("started: 2026-07-10\n")
        self.assertEqual(data.get("started"), "2026-07-10")

    def test_nested_mapping(self):
        text = "pipeline:\n  path: lite\n  initiator: aid-refactor\n"
        data, _warnings = parse_state_document(text)
        self.assertEqual(data.get("pipeline", {}).get("path"), "lite")
        self.assertEqual(data.get("pipeline", {}).get("initiator"), "aid-refactor")

    def test_quoted_scalar_unquoted(self):
        data, _warnings = parse_state_document('started: "2026-07-10"\n')
        self.assertEqual(data.get("started"), "2026-07-10")

    def test_prose_only_returns_empty_data_with_warnings(self):
        """A '#'-led heading is a full-line comment (skipped, no warning); a
        bare prose line matches no 'key:' shape and is reported as a
        malformed line (D-3) -- either way, no key is ever fabricated."""
        data, warnings = parse_state_document("# Just a heading\nbody text\n")
        self.assertEqual(data, {})
        self.assertEqual(len(warnings), 1, "the bare prose line is one malformed-line warning")

    def test_trailing_second_document_marker_does_not_lose_prior_data(self):
        """A bare '---'/'...' anywhere (including trailing, e.g. what used to
        be an 'unclosed frontmatter fence') is rejected as a second document
        (D-3) and emits a warning, but does not discard data already parsed
        before it -- the engine keeps parsing, never raises."""
        data, warnings = parse_state_document("started: 2026-07-10\n---\n")
        self.assertEqual(data.get("started"), "2026-07-10")
        self.assertEqual(len(warnings), 1)
        self.assertIn("second document", warnings[0])

    def test_placeholder_alternatives_filtered(self):
        """Rollout safety: an un-instantiated template enum-alternatives value
        (' | '-separated) must be treated as absent, not as literal data."""
        text = "lifecycle: Running | Paused-Awaiting-Input | Blocked | Completed | Canceled\n"
        data, _warnings = parse_state_document(text)
        self.assertNotIn("lifecycle", data,
                         "un-instantiated ' | ' placeholder must not be captured")

    def test_placeholder_brace_filtered(self):
        """Rollout safety: an un-instantiated '{...}' template placeholder must
        be treated as absent."""
        data, _warnings = parse_state_document('started: "{YYYY-MM-DD}"\n')
        self.assertNotIn("started", data)

    def test_placeholder_nested_filtered(self):
        text = "pipeline:\n  path: lite | full\n"
        data, _warnings = parse_state_document(text)
        self.assertNotIn("path", data.get("pipeline", {}))

    def test_real_single_token_not_filtered(self):
        """A real closed-enum single token (no spaces/braces) is never
        mistaken for a placeholder."""
        data, _warnings = parse_state_document("lifecycle: Running\n")
        self.assertEqual(data.get("lifecycle"), "Running")

    def test_freetext_field_with_pipe_is_kept(self):
        """Row-1 fix (task-002 review): a REAL free-text value that merely
        contains ' | ' must NOT be mistaken for an enum-alternatives placeholder
        and silently discarded. The ' | ' rule is suppressed for the free-text
        keys (pause_reason/block_reason/block_artifact/notes)."""
        for key in ("pause_reason", "block_reason", "block_artifact", "notes"):
            with self.subTest(key=key):
                data, _warnings = parse_state_document(f"{key}: waiting on A | else B\n")
                self.assertEqual(data.get(key), "waiting on A | else B",
                                 f"free-text {key} containing ' | ' must be kept, not dropped")

    def test_freetext_field_placeholder_still_filtered(self):
        """The free-text exemption applies ONLY to the ' | ' rule -- a free-text
        field still carrying its '{...}' template token is still skipped, so an
        un-migrated scaffold does not clobber the prose value."""
        data, _warnings = parse_state_document('block_reason: "{short text} | --"\n')
        self.assertNotIn("block_reason", data)

    def test_enum_field_with_pipe_still_filtered(self):
        """The ' | ' enum-list rule stays ACTIVE for closed-enum (non-free-text)
        keys: 'yes | no' on user_approved is the un-instantiated template line."""
        data, _warnings = parse_state_document("user_approved: yes | no\n")
        self.assertNotIn("user_approved", data)

    def test_single_quoted_scalar_unescapes_doubled_quote(self):
        """A single-quoted scalar collapses YAML's ''-escaping ('' -> ') -- the
        exact inverse of the writer, which single-quotes a free-text value and
        doubles an embedded '. So `'user''s reason'` reads back as the literal
        `user's reason` (writer<->reader round-trip parity, sec:D-5)."""
        data, _warnings = parse_state_document("notes: 'user''s reason'\n")
        self.assertEqual(data.get("notes"), "user's reason")

    def test_double_quoted_scalar_stripped_verbatim(self):
        """A double-quoted scalar with no backslash escape decodes verbatim
        (sec:D-5 mode 3's five-escape subset is a no-op when none is present)."""
        data, _warnings = parse_state_document('notes: "plain: value"\n')
        self.assertEqual(data.get("notes"), "plain: value")

    def test_crlf_line_endings(self):
        """CRLF-authored files (e.g. edited on Windows) parse identically to
        LF-only files. This is the Python side of a cross-twin landmine caught
        during the original task-002 development: the Node twin's $-anchored
        nested/top-level regexes silently failed on a dangling '\\r' left by
        text.split('\\n') (JS '.' excludes '\\r' as a line terminator, unlike
        Python's splitlines(), which already strips it) -- see reader.mjs's
        parseStateDocument for the fix."""
        text = "pipeline:\r\n  path: lite\r\n  initiator: aid-refactor\r\n"
        data, _warnings = parse_state_document(text)
        self.assertEqual(data.get("pipeline", {}).get("path"), "lite")
        self.assertEqual(data.get("pipeline", {}).get("initiator"), "aid-refactor")


class TestParseBoolYesno(unittest.TestCase):
    """parse_bool_yesno: yes/no/true/false, case-insensitive; twin-parity fix."""

    def test_yes_variants(self):
        for tok in ("yes", "Yes", "YES", "true", "True", "TRUE"):
            self.assertTrue(parse_bool_yesno(tok), f"{tok!r} must normalize to True")

    def test_no_variants(self):
        for tok in ("no", "No", "NO", "false", "False", "FALSE"):
            self.assertFalse(parse_bool_yesno(tok), f"{tok!r} must normalize to False")
            self.assertIs(parse_bool_yesno(tok), False)

    def test_none_input(self):
        self.assertIsNone(parse_bool_yesno(None))

    def test_unparseable_returns_none(self):
        self.assertIsNone(parse_bool_yesno("maybe"))
        self.assertIsNone(parse_bool_yesno(""))


class TestParseHeaderBoldField(unittest.TestCase):
    """parse_header_bold_field: legacy header-blockquote fallback scan."""

    def test_finds_blockquote_line(self):
        text = "> **User Approved:** yes\n\n## Pipeline State\n"
        self.assertEqual(parse_header_bold_field(text, "User Approved"), "yes")

    def test_finds_plain_bold_line(self):
        text = "**Minimum Grade:** B\n\n## Pipeline State\n"
        self.assertEqual(parse_header_bold_field(text, "Minimum Grade"), "B")

    def test_stops_at_first_section_header(self):
        text = "## Some Section\n\n**Status:** Approved\n"
        self.assertIsNone(parse_header_bold_field(text, "Status"))

    def test_absent_returns_none(self):
        self.assertIsNone(parse_header_bold_field("no such field here\n", "Status"))


class TestResolveKind(unittest.TestCase):
    """resolve_kind: pipeline.initiator -> display verb (shortcut-catalog mirror)."""

    def test_bare_verb(self):
        self.assertEqual(resolve_kind("aid-refactor"), "Refactor")

    def test_verb_plus_artifact(self):
        self.assertEqual(resolve_kind("aid-create-api"), "Create api")

    def test_hyphenated_artifact_spaced(self):
        self.assertEqual(resolve_kind("aid-create-data-model"), "Create data model")

    def test_alias_resolves_to_canonical_verb(self):
        # aid-add is an alias of aid-create -- same {verb, artifact} binding.
        self.assertEqual(resolve_kind("aid-add"), "Create")
        self.assertEqual(resolve_kind("aid-audit"), "Review")  # alias of aid-review

    def test_full_path_initiator(self):
        self.assertEqual(resolve_kind("aid-describe"), "full path")

    def test_unknown_initiator_returns_none(self):
        self.assertIsNone(resolve_kind("aid-not-a-real-skill"))

    def test_absent_initiator_returns_none(self):
        self.assertIsNone(resolve_kind(None))
        self.assertIsNone(resolve_kind(""))

    def test_every_catalog_row_resolves_to_a_label(self):
        """Every {name: (verb, artifact)} row must resolve to a non-empty label
        (catches a malformed/empty verb entry in the mirror table)."""
        for name in SHORTCUT_KIND_MAP:
            label = resolve_kind(name)
            self.assertTrue(label, f"{name!r} must resolve to a non-empty label")
            self.assertEqual(label[0], label[0].upper(),
                              f"{name!r} label {label!r} must start with an uppercase letter")


# ---------------------------------------------------------------------------
# parse_state_md: frontmatter-only / legacy-prose-only / mixed
# ---------------------------------------------------------------------------

_STRUCTURED_STATE = """\
pipeline:
  path: lite
  initiator: aid-refactor
started: "2026-07-10"
minimum_grade: A
user_approved: yes
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: "2026-07-10T12:00:00Z"
"""

# NOTE (work-009-refactor task-016, deleted-symbol change-set entry): the
# former _LEGACY_PROSE_ONLY_STATE / _MIXED_STATE / _UNMIGRATED_TEMPLATE_SEED_STATE
# fixtures and their three test methods (test_legacy_prose_only,
# test_mixed_frontmatter_wins_per_field, test_unmigrated_template_seed_does_not_
# clobber_prose) are REMOVED, not retargeted: SPEC.md sec:L-3 deletes
# parse_state_md's legacy-prose-fallback / per-field frontmatter-vs-prose
# resolution outright ("Section state machine deleted ... Becomes: parse
# document -> map keys onto ParsedWork"). parse_state_md no longer has a
# prose-bullet scan to fall back to at all -- a legacy STATE.md (no sibling
# STATE.yml) is now diagnosed BEFORE parse_state_md is ever reached
# (reader.py's SP-9 legacy detector, see TestManifestRegistration's sibling
# suite test_reader.py for that coverage), and a lifecycle-absent STATE.yml
# degrades to the LC-3 safe no-op covered by test_derivation.py's
# TestFallbackIntegration -- there is no third, "prose wins per missing
# frontmatter field" mode left to test here.


class TestParseStateMdStructured(unittest.TestCase):
    """parse_state_md: parse-document-then-map-keys (work-009-refactor
    task-003; was TestParseStateMdDualFormat, frontmatter-first +
    legacy-prose-fallback -- the fallback half is deleted, see the NOTE
    above). No '---' fence is needed any more (sec:D-1: the whole file IS
    the document)."""

    def test_structured_document(self):
        pw = parse_state_md(_STRUCTURED_STATE, work_id="work-900-demo")
        self.assertEqual(pw.lifecycle, Lifecycle.Running)
        self.assertEqual(pw.phase, Phase.Execute)
        self.assertEqual(pw.active_skill, "aid-execute")
        self.assertEqual(pw.updated, "2026-07-10T12:00:00Z")
        self.assertEqual(pw.source_mode, SourceMode.Normalized)
        self.assertEqual(pw.work_path, "lite")
        self.assertEqual(pw.kind, "Refactor")
        self.assertEqual(pw.started, "2026-07-10")
        self.assertEqual(pw.created, "2026-07-10",
                          "created is backfilled from the top-level `started` key")
        self.assertEqual(pw.minimum_grade, "A")
        self.assertTrue(pw.user_approved)


# ---------------------------------------------------------------------------
# Phase enum: members read via frontmatter (faithful numbered pipeline).
# ---------------------------------------------------------------------------

_PHASE_DESCRIBE_STATE = """\
pipeline:
  path: full
  initiator: aid-describe
lifecycle: Running
phase: Describe
active_skill: aid-describe
"""

_PHASE_DEFINE_STATE = """\
pipeline:
  path: full
  initiator: aid-describe
lifecycle: Running
phase: Define
active_skill: aid-define
"""


class TestPhaseTask010Migration(unittest.TestCase):
    """parse_state_md reads the faithful numbered-pipeline phase enum
    (work-003-state-schema task-010, BLUEPRINT gate criteria #16)."""

    def test_frontmatter_phase_describe(self):
        pw = parse_state_md(_PHASE_DESCRIBE_STATE, work_id="work-910-demo")
        self.assertEqual(pw.phase, Phase.Describe)

    def test_frontmatter_phase_define(self):
        pw = parse_state_md(_PHASE_DEFINE_STATE, work_id="work-911-demo")
        self.assertEqual(pw.phase, Phase.Define)


# ---------------------------------------------------------------------------
# parse_kb_state / _parse_kb_summary_approval: dual-format + source_mode
# ---------------------------------------------------------------------------

class TestParseKbStateDualFormat(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _kb_dir(self) -> Path:
        kb = self.tmp / ".aid" / "knowledge"
        kb.mkdir(parents=True, exist_ok=True)
        return kb

    def test_frontmatter_only(self):
        kb = self._kb_dir()
        (kb / "STATE.md").write_text(
            "---\n"
            "kb_status: Approved\n"
            "kb_grade: A\n"
            'last_kb_review: "2026-07-01"\n'
            "summary_approved: yes\n"
            'last_summary: "2026-07-02"\n'
            "---\n\n# Discovery State\n",
            encoding="utf-8",
        )
        ref, _br = parse_kb_state(kb)
        self.assertTrue(ref.summary_approved)
        self.assertEqual(ref.last_summary_date, "2026-07-02")
        self.assertEqual(ref.source_mode, SourceMode.Normalized)
        self.assertEqual(ref.kb_status, "Approved")
        self.assertEqual(ref.kb_grade, "A")
        self.assertEqual(ref.last_kb_review, "2026-07-01")

    def test_legacy_prose_only(self):
        kb = self._kb_dir()
        (kb / "STATE.md").write_text(
            "> **Status:** Approved\n"
            "> **Current Grade:** A\n"
            "> **Last KB Review:** 2026-07-01\n\n"
            "## Knowledge Summary Status\n\n"
            "**User Approved:** yes (2026-07-02)\n",
            encoding="utf-8",
        )
        ref, _br = parse_kb_state(kb)
        self.assertTrue(ref.summary_approved)
        self.assertEqual(ref.last_summary_date, "2026-07-02")
        self.assertEqual(ref.source_mode, SourceMode.Fallback)
        self.assertEqual(ref.kb_status, "Approved")
        self.assertEqual(ref.kb_grade, "A")
        self.assertEqual(ref.last_kb_review, "2026-07-01")

    def test_frontmatter_wins_over_legacy_prose(self):
        kb = self._kb_dir()
        (kb / "STATE.md").write_text(
            "---\n"
            "summary_approved: yes\n"
            'last_summary: "2026-07-05"\n'
            "---\n\n"
            "## Knowledge Summary Status\n\n"
            "**User Approved:** no\n",  # legacy prose disagrees -- frontmatter must win
            encoding="utf-8",
        )
        ref, _br = parse_kb_state(kb)
        self.assertTrue(ref.summary_approved)
        self.assertEqual(ref.last_summary_date, "2026-07-05")
        self.assertEqual(ref.source_mode, SourceMode.Normalized)

    def test_no_state_md_defaults_to_fallback_unapproved(self):
        kb = self._kb_dir()
        ref, _br = parse_kb_state(kb)
        self.assertFalse(ref.summary_approved)
        self.assertEqual(ref.source_mode, SourceMode.Fallback)
        self.assertIsNone(ref.kb_status)


# ---------------------------------------------------------------------------
# parse_task_state_md / parse_delivery_state_md: structured (no prose fallback)
#
# NOTE (task-016 deleted-symbol change-set entry): each class's former
# test_legacy_prose_only / test_mixed_frontmatter_wins_per_field methods are
# REMOVED, not retargeted -- SPEC.md sec:L-3 states plainly "Frontmatter-first
# already; drop their prose fallbacks". parse_task_state_md / parse_delivery_
# state_md (parsers.py) now contain NO bullet/heading scan whatsoever; every
# field is a direct structured-key read with no fallback branch left to test.
# ---------------------------------------------------------------------------

class TestParseTaskStateStructured(unittest.TestCase):
    """was TestParseTaskStateDualFormat -- see the module-level NOTE above."""

    def test_structured_document(self):
        text = "state: Done\nreview: A+ (Large)\nelapsed: '02:30'\nnotes: shipped\n"
        pts = parse_task_state_md(text, task_id="task-001")
        self.assertEqual(pts.state.value, "Done")
        self.assertEqual(pts.review, "A+ (Large)")
        self.assertEqual(pts.elapsed, "02:30")
        self.assertEqual(pts.notes, "shipped")


class TestParseDeliveryStateStructured(unittest.TestCase):
    """was TestParseDeliveryStateDualFormat -- see the module-level NOTE above."""

    def test_structured_document(self):
        text = (
            "delivery_state: Executing\n"
            "gate_tier: Large\n"
            "gate_grade: A+\n"
            'gate_timestamp: "2026-07-10T00:00:00Z"\n'
        )
        pds = parse_delivery_state_md(text, delivery_id="delivery-001")
        self.assertEqual(pds.delivery_state, "Executing")
        self.assertEqual(pds.gate_reviewer_tier, "Large")
        self.assertEqual(pds.gate_grade, "A+")
        self.assertEqual(pds.gate_timestamp, "2026-07-10T00:00:00Z")


# ---------------------------------------------------------------------------
# read_repo() integration: work_path from pipeline.path across all 3 layouts
# ---------------------------------------------------------------------------

def _make_repo(tmp: Path) -> "tuple[Path, Path]":
    aid = tmp / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    manifest = {
        "manifest_version": 1,
        "aid_version": "1.0.0",
        "installed_at": "2026-01-01T00:00:00Z",
        "tools": {"claude-code": {}},
    }
    (aid / ".aid-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    (aid / "settings.yml").write_text("project:\n  name: TestRepo\n", encoding="utf-8")
    return tmp, aid


class TestWorkPathFromPipeline(unittest.TestCase):
    """work_path is read from pipeline.path (frontmatter-first), falling back
    to layout detection (_detect_flat -> "lite", _detect_hierarchy -> "full")
    only when the frontmatter key is absent (un-migrated works)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _read_one_work(self):
        import unittest.mock as mock
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            return read_repo(self.root)

    def test_flat_layout_frontmatter_override(self):
        """A flat-layout work whose frontmatter explicitly says pipeline.path:
        full (an unusual but legal override) must be honored, not silently
        replaced by the "lite" layout-detection default."""
        work_dir = self.aid / "works" / "work-950-demo"
        work_dir.mkdir(parents=True)
        (work_dir / "BLUEPRINT.md").write_text(
            "# Delivery BLUEPRINT -- delivery-001: Demo\n\n"
            "## Objective\n\nDemo.\n\n## Gate Criteria\n\n- [ ] pass\n",
            encoding="utf-8",
        )
        (work_dir / "STATE.yml").write_text(
            "pipeline:\n  path: full\n  initiator: aid-refactor\n"
            "lifecycle: Running\n",
            encoding="utf-8",
        )
        tasks_dir = work_dir / "tasks" / "task-001"
        tasks_dir.mkdir(parents=True)
        (tasks_dir / "DETAIL.md").write_text("# task-001: Demo task\n\n**Type:** REFACTOR\n",
                                              encoding="utf-8")
        model = self._read_one_work()
        w = model.works[0]
        self.assertEqual(w.work_path, "full", "frontmatter override wins over flat-detect default")
        self.assertEqual(w.kind, "Refactor")

    def test_flat_layout_default_fallback(self):
        """No pipeline.path frontmatter -> falls back to the flat-detect
        default ('lite')."""
        work_dir = self.aid / "works" / "work-951-demo"
        work_dir.mkdir(parents=True)
        (work_dir / "BLUEPRINT.md").write_text(
            "# Delivery BLUEPRINT -- delivery-001: Demo\n\n"
            "## Objective\n\nDemo.\n\n## Gate Criteria\n\n- [ ] pass\n",
            encoding="utf-8",
        )
        (work_dir / "STATE.yml").write_text(
            "lifecycle: Running\n", encoding="utf-8"
        )
        tasks_dir = work_dir / "tasks" / "task-001"
        tasks_dir.mkdir(parents=True)
        (tasks_dir / "DETAIL.md").write_text("# task-001: Demo task\n\n**Type:** REFACTOR\n",
                                              encoding="utf-8")
        model = self._read_one_work()
        w = model.works[0]
        self.assertEqual(w.work_path, "lite")
        self.assertIsNone(w.kind)

    def test_hierarchical_layout_default_fallback(self):
        """No pipeline.path frontmatter on a hierarchical (deliveries/) work
        -> falls back to "full" (task-002 fix; previously left None)."""
        work_dir = self.aid / "works" / "work-952-demo"
        work_dir.mkdir(parents=True)
        (work_dir / "STATE.yml").write_text(
            "lifecycle: Running\n", encoding="utf-8"
        )
        task_dir = work_dir / "deliveries" / "delivery-001" / "tasks" / "task-001"
        task_dir.mkdir(parents=True)
        (task_dir / "STATE.yml").write_text(
            "state: Done\n", encoding="utf-8"
        )
        model = self._read_one_work()
        w = model.works[0]
        self.assertEqual(w.work_path, "full",
                          "hierarchical layout with no pipeline.path frontmatter "
                          "must default to 'full' (symmetric with the flat->'lite' default)")

    def test_hierarchical_layout_frontmatter_override(self):
        work_dir = self.aid / "works" / "work-953-demo"
        work_dir.mkdir(parents=True)
        (work_dir / "STATE.yml").write_text(
            "pipeline:\n  path: lite\n  initiator: aid-create-api\n"
            "lifecycle: Running\n",
            encoding="utf-8",
        )
        task_dir = work_dir / "deliveries" / "delivery-001" / "tasks" / "task-001"
        task_dir.mkdir(parents=True)
        (task_dir / "STATE.yml").write_text(
            "state: Done\n", encoding="utf-8"
        )
        model = self._read_one_work()
        w = model.works[0]
        self.assertEqual(w.work_path, "lite", "frontmatter override wins even though unusual")
        self.assertEqual(w.kind, "Create api")


# ---------------------------------------------------------------------------
# Cross-twin parity: Python read_repo() vs Node readRepo() (in-process, bounded)
# ---------------------------------------------------------------------------

def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _run_node_work(root: Path, pinned_home: Path) -> dict:
    """Run reader.mjs's readRepo() in a bounded, in-process (no server, no
    port) subprocess and return works[0] as a plain dict. Uses a file:// URL
    module specifier (Path.as_uri()) so this actually runs on Windows instead
    of hitting ERR_UNSUPPORTED_ESM_URL_SCHEME (see test_work001_delivery_layouts.py
    _run_node_normalized_work for the same pattern)."""
    script = (
        f"import {{ readRepo }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const m = readRepo({json.dumps(str(root))});\n"
        "const w = (m.works && m.works[0]) || null;\n"
        "process.stdout.write(JSON.stringify(w) + '\\n');\n"
    )
    result = subprocess.run(
        ["node", "--input-type=module"],
        input=script,
        capture_output=True,
        text=True,
        timeout=15,
        env={**os.environ, "HOME": str(pinned_home)},
    )
    if result.returncode != 0:
        raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:500]}")
    return json.loads(result.stdout.strip())


@unittest.skipUnless(_node_available(), "node not available on PATH")
class TestCrossTwinParity(unittest.TestCase):
    """Python read_repo() and Node readRepo() must agree byte-for-byte (as JSON)
    on the new task-002 fields, for both the frontmatter and legacy-prose
    input shapes -- computed in-process (no server/port/parity.sh)."""

    def setUp(self):
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)
        self.pinned_home = self.tmp / "pinned-home"
        self.pinned_home.mkdir(parents=True, exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _read_python_work(self):
        import unittest.mock as mock
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            model = read_repo(self.root)
        # Use the REAL server.py serializer (not raw dataclasses.asdict()) so
        # this compares exactly what ships over the wire -- asdict() would
        # also include internal-only fields server.py deliberately omits for
        # parity (e.g. DeliverableRef.delivery_state; branch_label).
        from dashboard.server.server import _ser_work
        return _ser_work(model.works[0])

    def _write_frontmatter_work(self, work_id: str) -> None:
        work_dir = self.aid / "works" / work_id
        work_dir.mkdir(parents=True)
        (work_dir / "BLUEPRINT.md").write_text(
            "# Delivery BLUEPRINT -- delivery-001: Demo\n\n"
            "## Objective\n\nDemo.\n\n## Gate Criteria\n\n- [ ] pass\n",
            encoding="utf-8",
        )
        (work_dir / "STATE.yml").write_text(
            "pipeline:\n"
            "  path: lite\n"
            "  initiator: aid-refactor\n"
            'started: "2026-07-10"\n'
            "minimum_grade: A\n"
            "user_approved: yes\n"
            "lifecycle: Running\n"
            "phase: Execute\n"
            "active_skill: aid-execute\n"
            'updated: "2026-07-10T12:00:00Z"\n',
            encoding="utf-8",
        )
        tasks_dir = work_dir / "tasks" / "task-001"
        tasks_dir.mkdir(parents=True)
        (tasks_dir / "DETAIL.md").write_text(
            "# task-001: Demo task\n\n**Type:** REFACTOR\n", encoding="utf-8"
        )

    def test_frontmatter_work_parity(self):
        self._write_frontmatter_work("work-960-demo")
        py_w = self._read_python_work()
        node_w = _run_node_work(self.root, self.pinned_home)
        self.assertEqual(
            py_w, node_w,
            "Python and Node must agree on every field (including the new "
            "kind/started/minimum_grade/user_approved) for a STATE.yml work"
        )

    def test_frontmatter_work_parity_crlf(self):
        """Deterministic (OS-independent) CRLF regression test: writes the
        STATE.yml document with explicit '\\r\\n' bytes (not relying on
        a platform's text-mode newline translation) and asserts parity. This
        is the exact input shape that caught a real Node-twin bug during the
        original task-002 development (see reader.mjs parseStateDocument's
        CRLF tolerance comment) -- Python's splitlines() already tolerated
        it, so only the Node side needed the fix; this test pins both
        directions."""
        work_id = "work-962-demo"
        work_dir = self.aid / "works" / work_id
        work_dir.mkdir(parents=True)
        (work_dir / "BLUEPRINT.md").write_bytes(
            b"# Delivery BLUEPRINT -- delivery-001: Demo\r\n\r\n"
            b"## Objective\r\n\r\nDemo.\r\n\r\n## Gate Criteria\r\n\r\n- [ ] pass\r\n"
        )
        (work_dir / "STATE.yml").write_bytes(
            b"pipeline:\r\n"
            b"  path: lite\r\n"
            b"  initiator: aid-refactor\r\n"
            b'started: "2026-07-10"\r\n'
            b"minimum_grade: A\r\n"
            b"user_approved: yes\r\n"
            b"lifecycle: Running\r\n"
            b"phase: Execute\r\n"
            b"active_skill: aid-execute\r\n"
            b'updated: "2026-07-10T12:00:00Z"\r\n'
        )
        tasks_dir = work_dir / "tasks" / "task-001"
        tasks_dir.mkdir(parents=True)
        (tasks_dir / "DETAIL.md").write_bytes(
            b"# task-001: Demo task\r\n\r\n**Type:** REFACTOR\r\n"
        )
        py_w = self._read_python_work()
        node_w = _run_node_work(self.root, self.pinned_home)
        self.assertEqual(py_w, node_w, "CRLF-authored STATE.yml must parity-match too")
        self.assertEqual(py_w["lifecycle"], "Running",
                          "CRLF must not silently degrade the document parse to Unknown")

    def _write_legacy_state_md_only_work(self, work_id: str) -> None:
        """A work holding ONLY the retired `STATE.md`, no `STATE.yml` sibling
        -- the SP-9 legacy-detector trigger (work-009-refactor task-016: was
        `_write_legacy_prose_work` / test_legacy_prose_work_parity, which
        tested the now-deleted legacy-prose-fallback dual-format read; see
        the module-level NOTE above TestParseStateMdStructured). Repurposed
        as the cross-twin proof that BOTH runtimes' legacy detector fire
        identically -- SP-9, NFR-8."""
        work_dir = self.aid / "works" / work_id
        work_dir.mkdir(parents=True)
        (work_dir / "BLUEPRINT.md").write_text(
            "# Delivery BLUEPRINT -- delivery-001: Demo\n\n"
            "## Objective\n\nDemo.\n\n## Gate Criteria\n\n- [ ] pass\n",
            encoding="utf-8",
        )
        (work_dir / "STATE.md").write_text(
            "> **Minimum Grade:** B\n"
            "> **User Approved:** no\n\n"
            "## Pipeline State\n\n"
            "- **Lifecycle:** Blocked\n"
            "- **Phase:** Execute\n"
            "- **Active Skill:** aid-execute\n"
            "- **Updated:** 2026-05-02T00:00:00Z\n"
            "- **Block Reason:** stuff broke\n"
            "- **Block Artifact:** IMPEDIMENT-task-001.md\n",
            encoding="utf-8",
        )
        tasks_dir = work_dir / "tasks" / "task-001"
        tasks_dir.mkdir(parents=True)
        (tasks_dir / "DETAIL.md").write_text(
            "# task-001: Demo task\n\n**Type:** REFACTOR\n", encoding="utf-8"
        )

    def test_legacy_state_md_only_work_degrades_identically_both_runtimes(self):
        """SP-9 / NFR-8, new read-path assertion (work-009-refactor task-016):
        a work holding only the legacy `STATE.md` (no `STATE.yml` sibling)
        is diagnosed identically by BOTH reader twins -- same minimal
        WorkModel fields, and each runtime's OWN `read.parse_warnings` names
        the file and the migration command ('aid update')."""
        work_id = "work-961-demo"
        self._write_legacy_state_md_only_work(work_id)
        py_w = self._read_python_work()
        node_w = _run_node_work(self.root, self.pinned_home)
        self.assertEqual(py_w, node_w,
                          "Python and Node must agree on the minimal WorkModel "
                          "for a legacy STATE.md-only work")
        self.assertEqual(py_w["lifecycle"], "Unknown")

        import unittest.mock as mock
        with mock.patch(
            "dashboard.reader.reader.enumerate_worktree_roots",
            return_value=[("main", self.aid)],
        ):
            py_model = read_repo(self.root)
        py_warning = next(
            (w for w in py_model.read.parse_warnings if work_id in w), None
        )
        self.assertIsNotNone(py_warning, "Python must warn by work_id")
        self.assertIn("aid update", py_warning)

        node_warning = self._run_node_legacy_warning(work_id)
        self.assertIsNotNone(node_warning, "Node must warn by work_id too")
        self.assertIn("aid update", node_warning)

    def _run_node_legacy_warning(self, work_id: str) -> "str | None":
        script = (
            f"import {{ readRepo }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
            f"const model = readRepo({json.dumps(str(self.root))});\n"
            f"const hit = model.read.parse_warnings.find(w => w.includes({json.dumps(work_id)}));\n"
            "process.stdout.write(JSON.stringify(hit || null) + '\\n');\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"],
            input=script,
            capture_output=True,
            text=True,
            timeout=15,
            env={**os.environ, "HOME": str(self.pinned_home)},
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:500]}")
        return json.loads(result.stdout.strip())

    def _write_frontmatter_work_with_phase(self, work_id: str, phase_value: str) -> None:
        """Same shape as _write_frontmatter_work, with a parameterized `phase:`
        value (work-003-state-schema task-010 phase-enum parity coverage)."""
        work_dir = self.aid / "works" / work_id
        work_dir.mkdir(parents=True)
        (work_dir / "BLUEPRINT.md").write_text(
            "# Delivery BLUEPRINT -- delivery-001: Demo\n\n"
            "## Objective\n\nDemo.\n\n## Gate Criteria\n\n- [ ] pass\n",
            encoding="utf-8",
        )
        (work_dir / "STATE.yml").write_text(
            "pipeline:\n"
            "  path: full\n"
            "  initiator: aid-describe\n"
            'started: "2026-07-10"\n'
            "minimum_grade: A\n"
            "user_approved: no\n"
            "lifecycle: Running\n"
            f"phase: {phase_value}\n"
            "active_skill: aid-describe\n"
            'updated: "2026-07-10T12:00:00Z"\n',
            encoding="utf-8",
        )
        tasks_dir = work_dir / "tasks" / "task-001"
        tasks_dir.mkdir(parents=True)
        (tasks_dir / "DETAIL.md").write_text(
            "# task-001: Demo task\n\n**Type:** REFACTOR\n", encoding="utf-8"
        )

    def test_new_phase_enum_parity(self):
        """work-003-state-schema task-010: both twins agree on the new
        Describe/Define phase members (BLUEPRINT gate criteria #16)."""
        for phase_value in ("Describe", "Define"):
            with self.subTest(phase=phase_value):
                work_id = f"work-970-{phase_value.lower()}"
                self._write_frontmatter_work_with_phase(work_id, phase_value)
                py_w = self._read_python_work()
                node_w = _run_node_work(self.root, self.pinned_home)
                self.assertEqual(py_w, node_w,
                                  f"Python and Node must agree on phase={phase_value!r}")
                self.assertEqual(py_w["phase"], phase_value)

    def _run_node_kb_summary_approved(self, root: Path, pinned_home: Path) -> "bool | None":
        script = (
            f"import {{ readRepo }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
            f"const m = readRepo({json.dumps(str(root))});\n"
            "const kb = m.repo.kb_state;\n"
            "process.stdout.write(JSON.stringify(kb ? kb.summary_approved : null) + '\\n');\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"],
            input=script,
            capture_output=True,
            text=True,
            timeout=15,
            env={**os.environ, "HOME": str(pinned_home)},
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:500]}")
        return json.loads(result.stdout.strip())

    def test_yesno_normalization_parity(self):
        """work-003-state-schema task-002 twin-parity landmine test: yes/no/
        true/false (case-insensitive) must normalize to the SAME logical
        boolean in BOTH runtimes -- PyYAML (1.1) coerces bare yes/no to bool
        at load time while js-yaml (1.2) keeps them as strings; since neither
        reader twin here uses a real YAML library (both hand-parse via
        parse_frontmatter_scalars/parseFrontmatterScalars), this test pins the
        two independent hand-rolled normalizers (parse_bool_yesno /
        parseBoolYesno) to agree for every accepted token."""
        for token, expected in (
            ("yes", True), ("YES", True), ("Yes", True), ("true", True), ("TRUE", True),
            ("no", False), ("NO", False), ("No", False), ("false", False), ("FALSE", False),
        ):
            with self.subTest(token=token):
                kb_dir = self.aid / "knowledge"
                if kb_dir.is_dir():
                    shutil.rmtree(kb_dir)
                kb_dir.mkdir(parents=True)
                (kb_dir / "STATE.md").write_text(
                    f"---\nsummary_approved: {token}\n---\n", encoding="utf-8"
                )
                import unittest.mock as mock
                with mock.patch(
                    "dashboard.reader.reader.enumerate_worktree_roots",
                    return_value=[("main", self.aid)],
                ):
                    py_model = read_repo(self.root)
                py_approved = py_model.repo.kb_state.summary_approved
                node_approved = self._run_node_kb_summary_approved(self.root, self.pinned_home)
                self.assertEqual(py_approved, expected,
                                  f"Python: token {token!r} must normalize to {expected}")
                self.assertEqual(node_approved, expected,
                                  f"Node: token {token!r} must normalize to {expected}")
                self.assertEqual(py_approved, node_approved,
                                  f"Python/Node must agree for token {token!r}")


# ---------------------------------------------------------------------------
# MANIFEST registration (light check; the canonical shell test does the full
# byte-for-byte curated-tree assertion -- not re-invoked here per this task's
# verification posture, see module docstring)
# ---------------------------------------------------------------------------

class TestManifestRegistration(unittest.TestCase):
    def test_state_schema_registered(self):
        lines = _MANIFEST.read_text(encoding="utf-8").splitlines()
        paths = {ln.split("#", 1)[0].strip() for ln in lines if ln.strip() and not ln.strip().startswith("#")}
        self.assertIn("reader/state_schema.py", paths,
                      "reader/state_schema.py must be listed in dashboard/MANIFEST "
                      "or it silently won't vendor (test-dashboard-manifest.sh)")


if __name__ == "__main__":
    unittest.main(verbosity=2)
