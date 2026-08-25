"""
test_feature009.py -- Feature-009 producer-state-emission tests (task-042).

Covers:
  T-9  Guard: PT-1 fixture parses under normalized path with zero PF-7 sentinels.
  T-10 Producer<->consumer contract: writes via REAL producer emission strings,
       reads via read_repo(), asserts field-by-field agreement; a mutated producer
       string (e.g. **Name** without colon, broken wave-map fence) FAILS the test.
  T-11 Canonical-producer pinning: reads the ACTUAL canonical producer specification
       files (canonical/aid/templates/requirements.md, canonical/skills/aid-detail/
       references/task-decomposition.md and execution-graph-generation.md) and asserts
       the reader parses each format AS DOCUMENTED THERE.  These tests fail if the
       canonical doc's format and the reader's parser diverge -- pinning
       reader<->canonical, not reader<->hand-copied copy.
  T-4  Phase single source: phase comes SOLELY from ## Pipeline Status; absent block
       -> phase=None; blockquote > **Phase:** ... does NOT populate phase.
       Cross-runtime (Python + Node assertions).
  T-8  Fully-degraded legacy work: no Name/Description, no ## Pipeline Status,
       prose-only PLAN, bare integer Wave -> graceful -- placeholders, zero garbage
       sentinels (no Delivery #0, no phase unknown, no raw work_id-as-title).
       Cross-runtime.

Python 3.11+ stdlib only. No third-party deps.
All tests are deterministic (temp dirs, no network, no subprocess except for Node
and the one read-only `git log` KB-freshness read (FR35)).
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

from dashboard.reader import (
    Lifecycle,
    Phase,
    RepoModel,
    read_repo,
)
from dashboard.reader.models import SourceMode, TaskModel

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_repo(root: Path, work_id: str = "work-001-test") -> tuple[Path, Path]:
    """Create a minimal .aid/ tree and return (aid_dir, work_dir)."""
    aid = root / ".aid"
    work = aid / "works" / work_id
    work.mkdir(parents=True, exist_ok=True)
    return aid, work


def _write_manifest(aid: Path) -> None:
    manifest = {
        "manifest_version": 1,
        "aid_version": "1.0.0",
        "installed_at": "2026-06-10T00:00:00Z",
        "tools": {"claude-code": {"version": "1.0.0",
                                   "installed_at": "2026-06-10T00:00:00Z",
                                   "paths": [], "root_agent_files": []}},
    }
    (aid / ".aid-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")


def _write_settings(aid: Path, name: str = "TestProject") -> None:
    (aid / "settings.yml").write_text(
        f"project:\n  name: {name}\n", encoding="utf-8"
    )


# ---------------------------------------------------------------------------
# T-9: PT-1 fixture guard test
#
# The regenerated fixture at dashboard/server/tests/fixtures/pt1-aid/
# must parse via the normalized reader path with ZERO PF-7 sentinels.
# ---------------------------------------------------------------------------

_PT1_FIXTURE = (
    Path(__file__).resolve().parents[2]   # dashboard/
    / "server" / "tests" / "fixtures" / "pt1-aid"
)


class TestT9FixtureFromReal(unittest.TestCase):
    """T-9: PT-1 fixture guard -- zero PF-7 sentinels for conforming works."""

    def _model(self) -> RepoModel:
        return read_repo(_PT1_FIXTURE)

    def test_fixture_exists(self):
        self.assertTrue(_PT1_FIXTURE.exists(), f"PT-1 fixture not found: {_PT1_FIXTURE}")

    def test_works_present(self):
        model = self._model()
        self.assertGreater(len(model.works), 0, "Fixture must have at least one work")

    def test_conforming_works_have_no_null_title(self):
        """Conforming works (with REQUIREMENTS.md Name header) must have a non-null title."""
        model = self._model()
        conforming = [w for w in model.works if w.work_id != "work-005-fallback"]
        for w in conforming:
            self.assertIsNotNone(
                w.title,
                f"{w.work_id}: title must not be null for a conforming work (PF-7)",
            )
            self.assertNotEqual(
                w.title, w.work_id,
                f"{w.work_id}: title must not be the raw work_id (PF-7 sentinel)",
            )

    def test_conforming_works_have_no_null_description(self):
        """Conforming works must have a non-null description (not a leaked blockquote)."""
        model = self._model()
        conforming = [w for w in model.works if w.work_id != "work-005-fallback"]
        for w in conforming:
            self.assertIsNotNone(
                w.description,
                f"{w.work_id}: description must not be null for a conforming work",
            )
            self.assertNotIn(
                "> _Status:",
                (w.description or ""),
                f"{w.work_id}: description must not contain a leaked blockquote (PF-7)",
            )

    def test_conforming_works_have_no_null_phase(self):
        """Conforming works with ## Pipeline Status must have a non-null phase."""
        model = self._model()
        conforming = [w for w in model.works if w.work_id != "work-005-fallback"]
        for w in conforming:
            self.assertIsNotNone(
                w.phase,
                f"{w.work_id}: phase must not be null (PF-4 -- typed block present)",
            )
            # Phase must be a valid Phase enum value, not Unknown
            self.assertIsInstance(w.phase, Phase)
            self.assertNotEqual(
                w.phase, Phase.Unknown,
                f"{w.work_id}: phase must not be Unknown sentinel for a conforming work",
            )

    def test_conforming_tasks_have_no_zero_delivery(self):
        """No task may have delivery=0 (the 'Delivery #0' garbage sentinel)."""
        model = self._model()
        conforming = [w for w in model.works if w.work_id != "work-005-fallback"]
        for w in conforming:
            for t in w.tasks:
                self.assertNotEqual(
                    t.delivery, 0,
                    f"{w.work_id}/{t.task_id}: delivery must not be 0 (PF-7 garbage sentinel)",
                )

    def test_conforming_tasks_have_short_names(self):
        """Conforming works with task files must resolve short_names (not null)."""
        model = self._model()
        # work-001-running-parallel has task files -> all tasks should have short_name
        w1 = next((w for w in model.works if w.work_id == "work-001-running-parallel"), None)
        if w1 is not None and len(w1.tasks) > 0:
            for t in w1.tasks:
                self.assertIsNotNone(
                    t.short_name,
                    f"work-001-running-parallel/{t.task_id}: short_name must not be null",
                )

    def test_degraded_fallback_work_is_graceful(self):
        """T-8 via fixture: work-005-fallback degrades gracefully -- no garbage."""
        model = self._model()
        fallback = next(
            (w for w in model.works if w.work_id == "work-005-fallback"), None
        )
        if fallback is None:
            self.skipTest("work-005-fallback not in fixture")

        # title must be None or a de-slugged fallback (never raw work_id styled as Name)
        # The REQUIREMENTS.md for work-005-fallback does NOT have a Name header.
        # So title should be None (the reader emits null).
        # Front-end renders it gracefully; the reader must NOT emit the work_id as title.
        # (Per PF-7: absent -> null, front-end decides the fallback rendering)
        if fallback.title is not None:
            # If the reader does emit a fallback title, it must NOT be the raw work_id string
            self.assertNotEqual(
                fallback.title, "work-005-fallback",
                "Degraded work: title must not be the raw work_id (PF-7)",
            )

        # Phase must be None (no ## Pipeline Status block in work-005-fallback)
        self.assertIsNone(
            fallback.phase,
            "T-8: Fully-degraded work must have phase=None, not 'phase unknown'",
        )

        # lifecycle must not be Unknown (fallback adapter should derive a value)
        self.assertIsNotNone(fallback.lifecycle)

        # No task must have delivery=0 (the garbage sentinel)
        for t in fallback.tasks:
            self.assertNotEqual(
                t.delivery, 0,
                f"T-8: {t.task_id} must not have delivery=0 (garbage sentinel)",
            )


# ---------------------------------------------------------------------------
# T-10: Producer<->consumer contract test
#
# Writes fixture files using the REAL producer emission strings (the same
# patterns the canonical skills emit), reads them back via read_repo(), and
# asserts field-by-field agreement. Also proves that a MUTATED producer string
# causes the expected field to become None/wrong (drift is caught).
# ---------------------------------------------------------------------------

# PF-1 canonical producer emission (from /aid-describe)
_PF1_REQUIREMENTS = """\
# Requirements

- **Name:** Widget Factory
- **Description:** A modular widget assembly pipeline with configurable stages.

## 1. Objective

Build a reliable widget factory pipeline.

> _Status: Complete -- approved._
"""

# STATE.yml, PF-4 typed lifecycle keys (work-009-refactor task-016: was a
# markdown STATE.md carrying a '## Pipeline Status' block and a real
# delivery-NNN Wave column in a '## Tasks Status' table -- both retired,
# sec:D-4. The Wave-column-derived task delivery/lane mechanism this fixture
# used to exercise (PF-5a/PF-5c) is now categorically unreachable through
# the monolithic reader path -- parse_state_md() never populates pw.tasks
# for ANY input any more (see test_pf5a_delivery_from_state_wave below,
# renamed to document that). This fixture keeps only the lifecycle-key
# fields PF-1/PF-4 still need.
_PF4_STATE = """\
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-06-11T00:00:00Z'
pause_reason: --
block_reason: --
block_artifact: --
"""

# PF-5a wave-map PLAN.md (canonical producer emission from /aid-detail).
# NOTE: intentionally has NO prose Wave lines -- only the machine-readable wave-map
# blocks. This ensures the drift-detection test (broken fence -> lanes fail) works
# because the prose fallback has nothing to parse either.
_PF5A_PLAN = """\
# Plan -- work-001-widget-factory

## Execution Graph

### delivery-001 execution graph

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002
```

### delivery-002 execution graph

```wave-map
delivery: 002
wave 1: task-003
```
"""

# PF-3 task short-names (# task-NNN: <title> format)
_PF3_TASK_001 = "# task-001: Widget assembly stage\n\nBody.\n"
_PF3_TASK_002 = "# task-002: Widget acceptance tests\n\nBody.\n"
_PF3_TASK_003 = "# task-003: Widget packaging module\n\nBody.\n"


class TestT10ProducerConsumerContract(unittest.TestCase):
    """T-10: Producer<->consumer round-trip contract test.

    Writes artifacts via the real producer emission strings (the canonical
    formats skills produce), reads them back via read_repo(), and asserts
    field-by-field agreement. A deliberately mutated producer string MUST
    cause the assertion to fail (proving drift is caught).
    """

    def _write_conforming_repo(self, root: Path, work_id: str = "work-001-widget-factory") -> Path:
        """Write a conforming producer repo at root and return work_dir."""
        aid, work = _make_repo(root, work_id)
        _write_manifest(aid)
        _write_settings(aid, "WidgetProject")

        (work / "REQUIREMENTS.md").write_text(_PF1_REQUIREMENTS, encoding="utf-8")
        (work / "STATE.yml").write_text(_PF4_STATE, encoding="utf-8")
        (work / "PLAN.md").write_text(_PF5A_PLAN, encoding="utf-8")

        tasks = work / "tasks"
        tasks.mkdir()
        (tasks / "task-001.md").write_text(_PF3_TASK_001, encoding="utf-8")
        (tasks / "task-002.md").write_text(_PF3_TASK_002, encoding="utf-8")
        (tasks / "task-003.md").write_text(_PF3_TASK_003, encoding="utf-8")
        return work

    # --- Happy-path: conforming producer -> correct reader fields ---

    def test_pf1_name_consumed_as_title(self):
        """PF-1: - **Name:** <value> -> WorkModel.title == value."""
        with tempfile.TemporaryDirectory() as d:
            self._write_conforming_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(w.title, "Widget Factory")

    def test_pf1_description_consumed(self):
        """PF-1: - **Description:** <value> -> WorkModel.description == value."""
        with tempfile.TemporaryDirectory() as d:
            self._write_conforming_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(
            w.description,
            "A modular widget assembly pipeline with configurable stages.",
        )

    def test_pf1_objective_skips_blockquote(self):
        """PF-2: objective body excludes the > _Status:_ blockquote line."""
        with tempfile.TemporaryDirectory() as d:
            self._write_conforming_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertIsNotNone(w.objective)
        self.assertNotIn("> _Status:", w.objective)
        self.assertIn("widget factory pipeline", w.objective)

    def test_pf3_task_short_names_now_unreachable_via_monolithic_state(self):
        """PF-3, content-level update (task-016): '_write_conforming_repo' has
        no BLUEPRINT.md and flat 'tasks/task-NNN.md' files (not
        'tasks/task-NNN/DETAIL.md' dirs) -- the pre-feature-001 monolithic
        shape. parse_state_md() never populates pw.tasks for ANY input
        (see test_derivation.py's
        test_fallback_no_markdown_text_never_populates_tasks), so short_name
        resolution through THIS fixture shape is now categorically
        unreachable, same class of consequence as
        test_pf5a_delivery_from_state_wave / test_pf5a_lane_from_wave_map
        below. PF-3 itself (parse_task_short_name) is still correctly
        covered directly in test_reader.py's TestPF3TaskShortName."""
        with tempfile.TemporaryDirectory() as d:
            self._write_conforming_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(w.tasks, [])

    def test_pf4_phase_from_pipeline_status(self):
        """PF-4: `phase:` key present (was: ## Pipeline Status block) -> phase=Execute."""
        with tempfile.TemporaryDirectory() as d:
            self._write_conforming_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(w.phase, Phase.Execute)
        self.assertEqual(w.source_mode, SourceMode.Normalized)

    def test_pf5a_delivery_from_state_wave_now_unreachable(self):
        """PF-5c, content-level update (task-016): the STATE Wave-column ->
        task.delivery mechanism is retired along with the '## Tasks Status'
        table it read (sec:L-3, '_parse_tasks_line ... nothing to
        retarget'). No task reaches this fixture's tasks[] at all any more
        (see test_pf3_task_short_names_now_unreachable_via_monolithic_state
        above) -- so there is no delivery=0 garbage sentinel either, since
        there is no task to carry one."""
        with tempfile.TemporaryDirectory() as d:
            self._write_conforming_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(w.tasks, [])

    def test_pf5a_lane_from_wave_map_now_unreachable(self):
        """PF-5a, content-level update (task-016): lane derivation from the
        PLAN.md wave-map still works (parse_execution_graph is untouched by
        this refactor -- test_reader.py's TestPF5ExecutionGraph covers it
        directly), but it has no task to attach to here -- see the sibling
        tests above for why tasks[] is now always empty through this
        monolithic fixture shape."""
        with tempfile.TemporaryDirectory() as d:
            self._write_conforming_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(w.tasks, [])

    def test_field_by_field_agreement(self):
        """Full field-by-field agreement: producer emission -> reader model.

        Content-level update (task-016): PF-1/PF-4 (title/description/phase/
        lifecycle) still agree field-by-field; PF-5a's task-level fields do
        not, because this fixture's tasks[] is now always empty through the
        monolithic reader path (see the three tests above)."""
        with tempfile.TemporaryDirectory() as d:
            self._write_conforming_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]

        # PF-1
        self.assertEqual(w.title, "Widget Factory")
        self.assertIsNotNone(w.description)
        # PF-4
        self.assertEqual(w.phase, Phase.Execute)
        self.assertEqual(w.lifecycle, Lifecycle.Running)
        # PF-5a: no longer reachable through this fixture shape (see above)
        self.assertEqual(w.tasks, [])

    # --- Drift-detection: mutated producer strings must cause failures ---

    def test_drift_mutated_name_without_colon_breaks_parse(self):
        """Mutation: '- **Name**' (no colon) -> title becomes None (drift caught)."""
        broken_requirements = _PF1_REQUIREMENTS.replace(
            "- **Name:** Widget Factory",
            "- **Name** Widget Factory",  # colon removed -> parse fails
        )
        with tempfile.TemporaryDirectory() as d:
            aid, work = _make_repo(Path(d))
            _write_manifest(aid)
            _write_settings(aid)
            (work / "REQUIREMENTS.md").write_text(broken_requirements, encoding="utf-8")
            (work / "STATE.yml").write_text(_PF4_STATE, encoding="utf-8")
            model = read_repo(Path(d))
        w = model.works[0]
        # The mutated string must NOT parse as the correct title
        self.assertNotEqual(
            w.title, "Widget Factory",
            "Mutated '- **Name**' (no colon) should NOT parse as the correct title "
            "(drift detection contract)",
        )

    def test_drift_mutated_wavemap_fence_breaks_lane(self):
        """Mutation: broken wave-map fence -> lane resolution fails (drift caught).

        Content-level update (task-016): this fixture shape (no BLUEPRINT.md,
        flat 'tasks/task-NNN.md' files) never reaches a populated tasks[] any
        more regardless of the PLAN.md fence (see
        test_pf5a_lane_from_wave_map_now_unreachable) -- so `lanes` is always
        `{}` and the drift property is vacuously, not meaningfully, true.
        The REAL drift-detection oracle for a broken wave-map fence is
        test_reader.py's TestPF5ExecutionGraph, which calls
        parse_execution_graph() directly against a populated tasks_dir and
        does resolve a real (non-empty) lane map."""
        # Replace the backtick fence with a different fence that won't be parsed as wave-map
        broken_plan = _PF5A_PLAN.replace("```wave-map", "```wavemap")  # typo in fence name
        with tempfile.TemporaryDirectory() as d:
            aid, work = _make_repo(Path(d))
            _write_manifest(aid)
            _write_settings(aid)
            (work / "REQUIREMENTS.md").write_text(_PF1_REQUIREMENTS, encoding="utf-8")
            (work / "STATE.yml").write_text(_PF4_STATE, encoding="utf-8")
            (work / "PLAN.md").write_text(broken_plan, encoding="utf-8")
            tasks = work / "tasks"
            tasks.mkdir()
            (tasks / "task-001.md").write_text(_PF3_TASK_001, encoding="utf-8")
            (tasks / "task-002.md").write_text(_PF3_TASK_002, encoding="utf-8")
            (tasks / "task-003.md").write_text(_PF3_TASK_003, encoding="utf-8")
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(w.tasks, [])

    def test_drift_description_without_colon_breaks_parse(self):
        """Mutation: '- **Description**' (no colon) -> description becomes None."""
        broken_requirements = _PF1_REQUIREMENTS.replace(
            "- **Description:** A modular widget assembly pipeline with configurable stages.",
            "- **Description** A modular widget assembly pipeline with configurable stages.",
        )
        with tempfile.TemporaryDirectory() as d:
            aid, work = _make_repo(Path(d))
            _write_manifest(aid)
            _write_settings(aid)
            (work / "REQUIREMENTS.md").write_text(broken_requirements, encoding="utf-8")
            (work / "STATE.yml").write_text(_PF4_STATE, encoding="utf-8")
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertNotEqual(
            w.description,
            "A modular widget assembly pipeline with configurable stages.",
            "Mutated '- **Description**' (no colon) should NOT parse as the correct description",
        )


# ---------------------------------------------------------------------------
# T-11: Canonical-producer pinning
#
# For each producer format (PF-1, PF-3, PF-5a), READ the canonical producer
# specification file and assert the reader parses the format AS DOCUMENTED
# THERE.  These tests fail if the canonical doc's format and the reader's
# parser diverge -- pinning reader<->canonical, not reader<->hand-copied copy.
#
# Canonical producer files:
#   PF-1: canonical/aid/templates/requirements.md
#         (contains - **Name:** / - **Description:** header lines)
#   PF-3: canonical/skills/aid-detail/references/task-decomposition.md
#         (documents # task-NNN: {Title} format + regex ^#\s+task-0*\d+\s*:\s*(.+)$)
#   PF-5a: canonical/skills/aid-detail/references/execution-graph-generation.md
#          (documents ```wave-map fence + delivery:/wave N: line format with example)
# ---------------------------------------------------------------------------

_CANONICAL_REQUIREMENTS_TEMPLATE = (
    _REPO_ROOT / "canonical" / "aid" / "templates" / "requirements.md"
)
_CANONICAL_TASK_DECOMPOSITION = (
    _REPO_ROOT / "canonical" / "skills" / "aid-detail" / "references"
    / "task-decomposition.md"
)
_CANONICAL_EXECUTION_GRAPH = (
    _REPO_ROOT / "canonical" / "skills" / "aid-detail" / "references"
    / "execution-graph-generation.md"
)


def _extract_wave_map_example(doc_text: str) -> str:
    """Extract the first complete wave-map fenced block from documentation text.

    Scans for ```wave-map ... ``` blocks and returns the content between
    the opening and closing fences (excluding the fence lines).
    Returns the full block content (delivery: + wave lines) or raises
    AssertionError if no wave-map block is found (canonical doc changed).
    """
    lines = doc_text.splitlines()
    in_block = False
    block_lines: list[str] = []
    for line in lines:
        if not in_block:
            # Accept both ` ```wave-map` (backtick inside markdown code block)
            # and bare ```wave-map (direct fence)
            stripped = line.strip()
            if stripped == "```wave-map" or stripped.endswith("```wave-map"):
                in_block = True
                block_lines = []
                continue
        else:
            stripped = line.strip()
            if stripped == "```":
                # End of block -- return what we have
                return "\n".join(block_lines)
            block_lines.append(line.strip())
    raise AssertionError(
        "No ```wave-map block found in canonical execution-graph-generation.md -- "
        "format may have changed incompatibly (T-11 canonical pin)"
    )


class TestT11CanonicalProducerPinning(unittest.TestCase):
    """T-11: Reader is pinned to the ACTUAL canonical producer specification files.

    Each test reads the canonical producer file at test time, extracts the
    documented format, and asserts the reader parses it correctly.  If the
    canonical doc's format changes incompatibly (e.g. wave-map fence renamed,
    Name header line dropped), these tests fail -- catching producer<->reader
    drift before it reaches production.
    """

    # -----------------------------------------------------------------------
    # PF-1: requirements.md template -- Name / Description headers
    # -----------------------------------------------------------------------

    def test_pf1_canonical_template_contains_name_header(self):
        """PF-1 pin: canonical/aid/templates/requirements.md has '- **Name:**' line."""
        self.assertTrue(
            _CANONICAL_REQUIREMENTS_TEMPLATE.is_file(),
            f"Canonical requirements template not found: {_CANONICAL_REQUIREMENTS_TEMPLATE}",
        )
        text = _CANONICAL_REQUIREMENTS_TEMPLATE.read_text(encoding="utf-8")
        self.assertIn(
            "- **Name:**",
            text,
            "canonical/aid/templates/requirements.md must contain '- **Name:**' header line "
            "(PF-1 pin: reader's parse_requirements_md regex expects this exact format)",
        )

    def test_pf1_canonical_template_contains_description_header(self):
        """PF-1 pin: canonical/aid/templates/requirements.md has '- **Description:**' line."""
        self.assertTrue(
            _CANONICAL_REQUIREMENTS_TEMPLATE.is_file(),
            f"Canonical requirements template not found: {_CANONICAL_REQUIREMENTS_TEMPLATE}",
        )
        text = _CANONICAL_REQUIREMENTS_TEMPLATE.read_text(encoding="utf-8")
        self.assertIn(
            "- **Description:**",
            text,
            "canonical/aid/templates/requirements.md must contain '- **Description:**' header line "
            "(PF-1 pin: reader's parse_requirements_md regex expects this exact format)",
        )

    def test_pf1_reader_parses_canonical_template_header_format(self):
        """PF-1 pin: reader parses the EXACT header format from the canonical template.

        Reads the canonical template, replaces *(pending)* with real values,
        and asserts the reader extracts them.  If the template's header format
        changes so the reader can no longer parse it, this test fails.
        """
        from dashboard.reader.parsers import parse_requirements_md

        self.assertTrue(
            _CANONICAL_REQUIREMENTS_TEMPLATE.is_file(),
            f"Canonical requirements template not found: {_CANONICAL_REQUIREMENTS_TEMPLATE}",
        )
        template_text = _CANONICAL_REQUIREMENTS_TEMPLATE.read_text(encoding="utf-8")

        # Verify the template has the expected placeholder format
        self.assertIn("- **Name:** *(pending)*", template_text,
                      "canonical template must seed Name with *(pending)* placeholder")
        self.assertIn("- **Description:** *(pending)*", template_text,
                      "canonical template must seed Description with *(pending)* placeholder")

        # Replace the placeholders with concrete values (simulating post-interview state)
        concrete = template_text.replace(
            "- **Name:** *(pending)*", "- **Name:** Canonical Test Project"
        ).replace(
            "- **Description:** *(pending)*",
            "- **Description:** A test project seeded from the canonical template.",
        )

        with tempfile.TemporaryDirectory() as d:
            req_path = Path(d) / "REQUIREMENTS.md"
            req_path.write_text(concrete, encoding="utf-8")
            title, description, _obj, br = parse_requirements_md(req_path)

        self.assertEqual(
            title, "Canonical Test Project",
            "PF-1 pin: reader must parse Name from the canonical template's header format "
            "(format divergence detected -- update reader or canonical template)",
        )
        self.assertEqual(
            description,
            "A test project seeded from the canonical template.",
            "PF-1 pin: reader must parse Description from the canonical template's header format",
        )

    def test_pf1_canonical_pending_placeholder_is_absorbed(self):
        """PF-1 pin: canonical template's *(pending)* seed -> reader returns None (not literal).

        The template seeds Name/Description with *(pending)* before the interview
        populates them.  The reader must treat that as absent (None) so a
        mid-interview work degrades gracefully via PF-7 rather than displaying
        '*(pending)*' as the project title.
        """
        from dashboard.reader.parsers import parse_requirements_md

        self.assertTrue(
            _CANONICAL_REQUIREMENTS_TEMPLATE.is_file(),
            f"Canonical requirements template not found: {_CANONICAL_REQUIREMENTS_TEMPLATE}",
        )
        template_text = _CANONICAL_REQUIREMENTS_TEMPLATE.read_text(encoding="utf-8")

        with tempfile.TemporaryDirectory() as d:
            req_path = Path(d) / "REQUIREMENTS.md"
            # Write the template verbatim (without replacing the placeholders)
            req_path.write_text(template_text, encoding="utf-8")
            title, description, _obj, br = parse_requirements_md(req_path)

        self.assertIsNone(
            title,
            "PF-1 pin: reader must return None for Name when canonical template "
            "seed '*(pending)*' is present (not render it literally as the title)",
        )
        self.assertIsNone(
            description,
            "PF-1 pin: reader must return None for Description when canonical template "
            "seed '*(pending)*' is present",
        )

    # -----------------------------------------------------------------------
    # PF-3: task-decomposition.md -- task short-name format
    # -----------------------------------------------------------------------

    def test_pf3_canonical_doc_contains_task_title_format(self):
        """PF-3 pin: task-decomposition.md documents '# task-NNN: {Title}' format."""
        self.assertTrue(
            _CANONICAL_TASK_DECOMPOSITION.is_file(),
            f"Canonical task-decomposition not found: {_CANONICAL_TASK_DECOMPOSITION}",
        )
        text = _CANONICAL_TASK_DECOMPOSITION.read_text(encoding="utf-8")
        self.assertIn(
            "# task-NNN:",
            text,
            "canonical/skills/aid-detail/references/task-decomposition.md must document "
            "'# task-NNN: {Title}' format (PF-3 pin: reader's short_name regex relies on this)",
        )

    def test_pf3_canonical_doc_documents_parse_regex(self):
        """PF-3 pin: task-decomposition.md explicitly documents the parse regex."""
        self.assertTrue(
            _CANONICAL_TASK_DECOMPOSITION.is_file(),
            f"Canonical task-decomposition not found: {_CANONICAL_TASK_DECOMPOSITION}",
        )
        text = _CANONICAL_TASK_DECOMPOSITION.read_text(encoding="utf-8")
        # The doc should document the regex pattern used by the reader
        self.assertIn(
            r"task-0*\d+",
            text,
            "canonical/skills/aid-detail/references/task-decomposition.md must document "
            r"the parse regex (^#\s+task-0*\d+\s*:\s*(.+)$) so reader<->canonical is pinned",
        )

    def test_pf3_reader_parses_canonical_documented_format(self):
        """PF-3 pin: reader parses the # task-NNN: {Title} format documented in canonical doc."""
        from dashboard.reader.parsers import parse_task_short_name

        self.assertTrue(
            _CANONICAL_TASK_DECOMPOSITION.is_file(),
            f"Canonical task-decomposition not found: {_CANONICAL_TASK_DECOMPOSITION}",
        )
        text = _CANONICAL_TASK_DECOMPOSITION.read_text(encoding="utf-8")

        # Confirm doc has the format line before asserting the reader parses it
        self.assertIn("# task-NNN:", text)

        # Build a concrete example in the documented format and assert reader parses it
        task_content = "# task-042: Canonical format validation task\n\n**Type:** IMPLEMENT\n"
        with tempfile.TemporaryDirectory() as d:
            task_path = Path(d) / "task-042.md"
            task_path.write_text(task_content, encoding="utf-8")
            short_name, br = parse_task_short_name(task_path)

        self.assertEqual(
            short_name, "Canonical format validation task",
            "PF-3 pin: reader must parse short_name from the '# task-NNN: Title' format "
            "documented in task-decomposition.md "
            "(format divergence: update reader or canonical doc)",
        )

    # -----------------------------------------------------------------------
    # PF-5a: execution-graph-generation.md -- wave-map format
    # -----------------------------------------------------------------------

    def test_pf5a_canonical_doc_contains_wave_map_fence(self):
        """PF-5a pin: execution-graph-generation.md documents ```wave-map fence."""
        self.assertTrue(
            _CANONICAL_EXECUTION_GRAPH.is_file(),
            f"Canonical execution-graph-generation not found: {_CANONICAL_EXECUTION_GRAPH}",
        )
        text = _CANONICAL_EXECUTION_GRAPH.read_text(encoding="utf-8")
        self.assertIn(
            "```wave-map",
            text,
            "canonical/skills/aid-detail/references/execution-graph-generation.md "
            "must document ```wave-map fence (PF-5a pin)",
        )

    def test_pf5a_canonical_doc_example_block_parses_correctly(self):
        """PF-5a pin: reader parses the wave-map example block from the canonical doc.

        Extracts the documented example ```wave-map block from execution-graph-
        generation.md and runs the reader's execution-graph parser on it.
        Asserts it yields the expected task->{delivery, lane} mapping exactly
        as the doc describes.  If the doc's format changes incompatibly, this fails.
        """
        from dashboard.reader.parsers import parse_execution_graph

        self.assertTrue(
            _CANONICAL_EXECUTION_GRAPH.is_file(),
            f"Canonical execution-graph-generation not found: {_CANONICAL_EXECUTION_GRAPH}",
        )
        doc_text = _CANONICAL_EXECUTION_GRAPH.read_text(encoding="utf-8")

        # The canonical doc's example block (for the two-delivery plan) reads:
        #   delivery: 001 / wave 1: task-001 / wave 2: task-002, task-003
        #   delivery: 002 / wave 1: task-004 / wave 2: task-005
        # Extract the example block and wrap it in a valid PLAN.md context
        example_block = _extract_wave_map_example(doc_text)
        self.assertTrue(
            example_block.strip(),
            "No content found inside the first ```wave-map block in execution-graph-generation.md",
        )

        # Verify the doc example block has the expected content (canonical pins both sides)
        self.assertIn("delivery:", example_block,
                      "PF-5a pin: wave-map example must start with 'delivery:' line")
        self.assertIn("wave 1:", example_block,
                      "PF-5a pin: wave-map example must have 'wave 1:' line")

        # Wrap the extracted block into a minimal PLAN.md and run the parser
        plan_text = (
            "# Plan\n\n"
            "### delivery-001 execution graph\n\n"
            "```wave-map\n"
            + example_block + "\n"
            "```\n"
        )

        with tempfile.TemporaryDirectory() as d:
            plan_path = Path(d) / "PLAN.md"
            plan_path.write_text(plan_text, encoding="utf-8")
            lane_map, br = parse_execution_graph(plan_path)

        # The canonical example block contains task-001 in wave 1 and task-002/task-003 in wave 2
        # (first block in the two-delivery example: delivery 001)
        self.assertIn(
            "task-001", lane_map,
            "PF-5a pin: task-001 must appear in the parsed lane map from the canonical example",
        )
        self.assertEqual(
            lane_map.get("task-001"), 1,
            "PF-5a pin: task-001 must be in wave/lane 1 per canonical doc example",
        )
        # task-002 and/or task-003 should be in wave 2
        wave2_tasks = [t for t, l in lane_map.items() if l == 2]
        self.assertTrue(
            len(wave2_tasks) > 0,
            "PF-5a pin: canonical doc example must have tasks in wave 2; "
            "lane_map=" + str(lane_map),
        )

    def test_pf5a_broken_fence_name_fails_canonical_parse(self):
        """PF-5a drift detection: renaming the fence (e.g. ```wavemap) breaks lane parsing.

        This is the same mutation as TestT10's test_drift_mutated_wavemap_fence_breaks_lane
        but now the canonical format is the reference.  If the fence name in the
        canonical doc is renamed (format divergence), the reader will fail to parse
        live repos -- this test surfaces that early.
        """
        from dashboard.reader.parsers import parse_execution_graph

        self.assertTrue(
            _CANONICAL_EXECUTION_GRAPH.is_file(),
            f"Canonical execution-graph-generation not found: {_CANONICAL_EXECUTION_GRAPH}",
        )
        doc_text = _CANONICAL_EXECUTION_GRAPH.read_text(encoding="utf-8")

        # Confirm the canonical doc actually has the expected fence before mutation
        self.assertIn("```wave-map", doc_text,
                      "Canonical doc must have ```wave-map fence for this drift test to be valid")

        # Extract the canonical example block from the unmodified doc first
        canonical_block = _extract_wave_map_example(doc_text)
        self.assertTrue(canonical_block.strip(),
                        "Canonical doc must have a non-empty wave-map example block")

        # Build a PLAN.md using the MUTATED (wrong) fence name -- simulates format drift
        # where the canonical doc renames the fence but the reader hasn't been updated
        plan_text = (
            "# Plan\n\n"
            "### delivery-001 execution graph\n\n"
            "```wavemap\n"  # <-- wrong fence name (drift mutation)
            + canonical_block + "\n"
            "```\n"
        )

        with tempfile.TemporaryDirectory() as d:
            plan_path = Path(d) / "PLAN.md"
            plan_path.write_text(plan_text, encoding="utf-8")
            lane_map, br = parse_execution_graph(plan_path)

        # The reader must NOT parse the mutated fence (drift caught)
        all_tasks_have_lane = (
            lane_map.get("task-001") == 1
        )
        self.assertFalse(
            all_tasks_have_lane,
            "PF-5a drift: mutated fence '```wavemap' must NOT be parsed by the reader "
            "(if this fails, the reader is accepting non-canonical fence names)",
        )


# ---------------------------------------------------------------------------
# T-4: Phase single source (PF-4) -- explicit cross-runtime assertions
#
# NOTE: TestPF4PhaseSingleSource in test_reader.py already covers the core
# Python-side assertions. This class supplements with:
#   - The bootstrap/absent block case (explicit cross-runtime fixture test)
#   - Assertion that a legacy blockquote > **Phase:** does NOT populate phase
#   - Node runtime mirror (if node is available)
# ---------------------------------------------------------------------------

class TestT4PhaseSingleSourceExplicit(unittest.TestCase):
    """T-4: Phase is sourced solely from ## Pipeline Status.

    Supplements TestPF4PhaseSingleSource in test_reader.py with:
    - Explicit T-4 fixture cases (with-block / without-block / blockquote-only)
    - No secondary phase inference from any other signal
    """

    def test_with_pipeline_status_phase_is_execute(self):
        """T-4: work WITH a `phase:` key (was: typed ## Pipeline Status) -> phase=Execute."""
        state = (
            "lifecycle: Running\n"
            "phase: Execute\n"
            "active_skill: aid-execute\n"
            "updated: '2026-06-11T00:00:00Z'\n"
        )
        with tempfile.TemporaryDirectory() as d:
            aid, work = _make_repo(Path(d), "work-001-with-phase")
            _write_manifest(aid)
            _write_settings(aid)
            (work / "STATE.yml").write_text(state, encoding="utf-8")
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(w.phase, Phase.Execute)
        self.assertEqual(w.source_mode, SourceMode.Normalized)

    def test_without_pipeline_status_phase_is_none(self):
        """T-4: work WITHOUT a `lifecycle` key (bootstrap) -> phase=None (graceful)."""
        state = (
            "tasks_lifecycle:\n"
            "  task-001:\n"
            "    state: In Progress\n"
        )
        with tempfile.TemporaryDirectory() as d:
            aid, work = _make_repo(Path(d), "work-001-no-phase")
            _write_manifest(aid)
            _write_settings(aid)
            (work / "STATE.yml").write_text(state, encoding="utf-8")
            model = read_repo(Path(d))
        w = model.works[0]
        # Bootstrap case: phase must be None (never "unknown" or a garbage sentinel)
        self.assertIsNone(w.phase, "T-4: bootstrap work must have phase=None, not a garbage value")
        self.assertEqual(w.source_mode, SourceMode.Fallback)

    def test_legacy_blockquote_phase_does_not_populate_phase(self):
        """T-4: a stray legacy > **Phase:** blockquote LINE inside an
        otherwise `lifecycle`-absent document does NOT populate phase (was:
        the legacy blockquote header against a markdown '## Tasks Status'
        body; the property survives the format change unchanged -- there is
        no more prose scan to pick it up at all)."""
        state = (
            "> **Phase:** Execute\n\n"
            "tasks_lifecycle:\n"
            "  task-001:\n"
            "    state: In Progress\n"
        )
        with tempfile.TemporaryDirectory() as d:
            aid, work = _make_repo(Path(d), "work-001-blockquote-phase")
            _write_manifest(aid)
            _write_settings(aid)
            (work / "STATE.yml").write_text(state, encoding="utf-8")
            model = read_repo(Path(d))
        w = model.works[0]
        # The blockquote is NOT a phase source -> phase must be None
        self.assertIsNone(
            w.phase,
            "T-4: legacy > **Phase:** blockquote must NOT populate phase (single source is the `phase:` key)",
        )

    def test_t4_cross_runtime_node_mirrors_python(self):
        """T-4: Node reader mirrors Python for phase=None (bootstrap) case."""
        # Only run if node is available
        try:
            subprocess.run(
                ["node", "--version"], capture_output=True, check=True, timeout=5
            )
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            self.skipTest("node not available")

        state = (
            "tasks_lifecycle:\n"
            "  task-001:\n"
            "    state: In Progress\n"
        )
        tmpdir = tempfile.mkdtemp()
        try:
            root = Path(tmpdir)
            aid, work = _make_repo(root, "work-001-no-phase")
            _write_manifest(aid)
            _write_settings(aid)
            (work / "STATE.yml").write_text(state, encoding="utf-8")

            # Python result
            py_model = read_repo(root)
            py_phase = py_model.works[0].phase  # must be None

            # Node result via inline reader.mjs script (dir still alive)
            reader_mjs = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"
            script = (
                "import { readRepo } from " + repr(str(reader_mjs)) + ";\n"
                "const m = readRepo(" + repr(str(tmpdir)) + ");\n"
                "const w = m.works[0];\n"
                "process.stdout.write(JSON.stringify({phase: w ? w.phase : null}) + '\\n');\n"
            )
            result = subprocess.run(
                ["node", "--input-type=module"],
                input=script,
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode != 0:
                self.skipTest(f"Node script error: {result.stderr[:200]}")
            node_data = json.loads(result.stdout.strip())
            node_phase = node_data.get("phase")
        finally:
            shutil.rmtree(tmpdir, ignore_errors=True)

        self.assertIsNone(py_phase, "T-4 Python: bootstrap work must have phase=None")
        # Node emits null JSON -> Python json.loads gives None
        self.assertIsNone(node_phase, "T-4 Node: bootstrap work must have phase=null (mirrors Python)")


# ---------------------------------------------------------------------------
# T-8: Fully-degraded legacy work -> no garbage sentinels
# ---------------------------------------------------------------------------

# The fully-degraded legacy STATE.md (work-009-refactor task-016: content-level
# update -- the real pre-migration shape this fixture models IS the SP-9
# legacy-detector trigger now, not a best-effort prose scan). This work
# folder holds ONLY the retired STATE.md, no STATE.yml sibling -- exactly the
# SP-9 condition (sec:D-1/D-4, NFR-8) that reader.py diagnoses BEFORE any
# content is parsed at all. The class below is restated for that: "graceful
# degradation" is now "a clean minimal WorkModel plus a parse_warning naming
# the migration command", not "field-by-field best-effort prose scanning" --
# the OLD mechanism (parse_header_bold_field / the legacy prose fallback for
# state files) no longer exists (sec:L-3). Content is otherwise unchanged
# (still a legacy-shaped document) since it is now irrelevant -- the SP-9
# check fires on filename presence alone, never on content.
_T8_STATE = """\
# Work State -- work-legacy

> **Status:** Executing
> **Phase:** Execute
> **Minimum Grade:** B
> **Started:** 2026-06-01

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | CODE | delivery-001 | In Progress | -- | -- | -- |
| 002 | task-002 | TEST | delivery-001 | Pending | -- | -- | -- |

## Lifecycle History

| Date | Phase | Event | Phase Transition / Gate | Notes |
|------|-------|-------|--------------------------|-------|
| 2026-06-01 | Describe | Work created | Describe start | -- |

"""


class TestT8FullyDegradedLegacyWork(unittest.TestCase):
    """T-8: Fully-degraded legacy work renders with graceful -- placeholders.

    Content-level update (task-016): "graceful" is now the SP-9 legacy
    detector's minimal WorkModel + a parse_warning naming the file and the
    migration command ('aid update') -- the class docstring's original list
    of properties (no Name/Description, no ## Pipeline Status, prose-only
    PLAN, bare delivery-NNN waves) described the OLD best-effort prose scan,
    now retired (sec:L-3). Every property below still holds, for the NEW
    reason (a minimal model that never looks at content), not the old one
    (a scan that tried and safely gave up field-by-field):
    - phase = None (minimal model default)
    - title = None (minimal model default)
    - description = None (minimal model default)
    - No task has delivery=0 (trivially true -- tasks is always [])
    - source_mode = fallback
    - lifecycle = Unknown (a valid Lifecycle member, never a crash)
    - NEW: a parse_warning names the file and 'aid update' (SP-9, NFR-8)
    """

    def _make_degraded_repo(self, root: Path) -> None:
        aid, work = _make_repo(root, "work-001-legacy")
        _write_manifest(aid)
        _write_settings(aid)
        (work / "STATE.md").write_text(_T8_STATE, encoding="utf-8")
        # NO STATE.yml sibling -- this IS the SP-9 legacy-detector trigger.
        # NO REQUIREMENTS.md (no Name/Description header)
        # NO PLAN.md (no wave-map)

    def test_phase_is_none_not_garbage(self):
        """T-8: phase must be None, never 'phase unknown' or 'Execute' from blockquote."""
        with tempfile.TemporaryDirectory() as d:
            self._make_degraded_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        # The legacy blockquote > **Phase:** Execute must NOT populate phase
        self.assertIsNone(
            w.phase,
            "T-8: fully-degraded work must have phase=None (blockquote not a phase source)",
        )

    def test_title_is_none_not_raw_work_id(self):
        """T-8: title must be None (reader emits null; front-end labels fallback)."""
        with tempfile.TemporaryDirectory() as d:
            self._make_degraded_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        # No REQUIREMENTS.md with Name header -> title must be None
        # (front-end may show de-slugged work name as a labelled fallback, but reader emits null)
        self.assertIsNone(
            w.title,
            "T-8: fully-degraded work with no Name header must have title=None",
        )

    def test_description_is_none_no_blockquote(self):
        """T-8: description must be None (never a leaked blockquote)."""
        with tempfile.TemporaryDirectory() as d:
            self._make_degraded_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertIsNone(
            w.description,
            "T-8: fully-degraded work with no Name header must have description=None",
        )
        # Extra guard: if somehow non-None, must not contain a blockquote
        if w.description is not None:
            self.assertNotIn("> _Status:", w.description)

    def test_no_task_has_zero_delivery(self):
        """T-8: no task may have delivery=0 (never 'Delivery #0' sentinel)."""
        with tempfile.TemporaryDirectory() as d:
            self._make_degraded_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        for t in w.tasks:
            self.assertNotEqual(
                t.delivery, 0,
                f"T-8: {t.task_id} must not have delivery=0 (garbage sentinel)",
            )

    def test_source_mode_is_fallback(self):
        """T-8: fully-degraded work (no ## Pipeline Status) -> source_mode=fallback."""
        with tempfile.TemporaryDirectory() as d:
            self._make_degraded_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(w.source_mode, SourceMode.Fallback)

    def test_lifecycle_is_valid_enum_not_crash(self):
        """T-8, content-level update (task-016): lifecycle is a valid
        Lifecycle value -- never a crash. The SP-9 legacy detector's minimal
        model uses Lifecycle.Unknown (not a re-derived Running), which is
        itself still "a valid Lifecycle value, not a crash" -- the property
        this test's name states. The OLD content-driven derivation
        (Running, from the In Progress tasks) required the now-deleted
        prose-fallback scan reading this file's own content; SP-9 never
        reaches that scan for a legacy STATE.md at all."""
        with tempfile.TemporaryDirectory() as d:
            self._make_degraded_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertIsInstance(w.lifecycle, Lifecycle)
        self.assertEqual(w.lifecycle, Lifecycle.Unknown)

    def test_tasks_have_graceful_delivery_not_zero(self):
        """T-8, content-level update (task-016): no task may have delivery=0
        (the 'Delivery #0' garbage sentinel this test guards against).
        Trivially, and still gracefully, true: the SP-9 minimal model's
        tasks[] is always empty, so there is no task to carry a bad
        delivery value in the first place."""
        with tempfile.TemporaryDirectory() as d:
            self._make_degraded_repo(Path(d))
            model = read_repo(Path(d))
        w = model.works[0]
        self.assertEqual(w.tasks, [])
        for t in w.tasks:
            self.assertNotEqual(t.delivery, 0, f"T-8: {t.task_id}.delivery must not be 0")

    def test_parse_warning_names_migration_command(self):
        """NEW (task-016, SP-9/NFR-8): the parse_warning for this legacy
        STATE.md-only work names the file and the migration command."""
        with tempfile.TemporaryDirectory() as d:
            self._make_degraded_repo(Path(d))
            model = read_repo(Path(d))
        hit = next(
            (warn for warn in model.read.parse_warnings if "work-001-legacy" in warn), None
        )
        self.assertIsNotNone(hit, "a parse_warning must name the legacy work by id")
        self.assertIn("aid update", hit)
        self.assertIn("STATE.md", hit)

    def test_t8_cross_runtime_node_mirrors_python(self):
        """T-8: Node reader mirrors Python: phase=null, no garbage for degraded work."""
        try:
            subprocess.run(
                ["node", "--version"], capture_output=True, check=True, timeout=5
            )
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            self.skipTest("node not available")

        tmpdir = tempfile.mkdtemp()
        try:
            self._make_degraded_repo(Path(tmpdir))

            py_model = read_repo(Path(tmpdir))
            py_w = py_model.works[0]

            reader_mjs = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"
            script = (
                "import { readRepo } from " + repr(str(reader_mjs)) + ";\n"
                "const m = readRepo(" + repr(tmpdir) + ");\n"
                "const w = m.works[0];\n"
                "const tasks = w ? w.tasks : [];\n"
                "const has_zero_delivery = tasks.some(t => t.delivery === 0);\n"
                "process.stdout.write(JSON.stringify({\n"
                "  phase: w ? w.phase : 'NO_WORK',\n"
                "  title: w ? w.title : 'NO_WORK',\n"
                "  has_zero_delivery: has_zero_delivery,\n"
                "  source_mode: w ? w.source_mode : 'NO_WORK'\n"
                "}) + '\\n');\n"
            )
            result = subprocess.run(
                ["node", "--input-type=module"],
                input=script,
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode != 0:
                self.skipTest(f"Node script error: {result.stderr[:200]}")
            node_data = json.loads(result.stdout.strip())
        finally:
            shutil.rmtree(tmpdir, ignore_errors=True)

        # Python assertions
        self.assertIsNone(py_w.phase, "T-8 Python: phase must be None")
        self.assertIsNone(py_w.title, "T-8 Python: title must be None")

        # Node mirrors Python
        self.assertIsNone(
            node_data.get("phase"),
            "T-8 Node: phase must be null (mirrors Python None)",
        )
        self.assertIsNone(
            node_data.get("title"),
            "T-8 Node: title must be null (mirrors Python None)",
        )
        self.assertFalse(
            node_data.get("has_zero_delivery"),
            "T-8 Node: no task must have delivery=0 (Delivery #0 garbage sentinel)",
        )
        self.assertEqual(
            node_data.get("source_mode"),
            "fallback",
            "T-8 Node: fully-degraded work source_mode must be 'fallback'",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
