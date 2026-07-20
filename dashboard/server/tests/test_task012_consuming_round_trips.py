"""
test_task012_consuming_round_trips.py -- "Consuming-op round-trips + model-field
parity" (task-012, feature-002-project-header-edit / feature-005-display-rename /
feature-006-task-notes, delivery-001, work-017-cli-improvements).

This is a TEST-type task: no production code. It closes the specific gaps left
open by the individual op-implementation tasks (005/006/008/009/010), which each
proved their OWN op's writer-dispatch logic (argv-builders, semantic validation,
raw-file-content assertions) but did not, in one place, drive the FULL
write -> re-fetch round trip through the actual reader (the thing a dashboard
client sees on its post-write `./api/model` GET):

  - settings.set (task-006/feature-002): dispatch tests exist
    (test_task004_op_dispatch.py, test_task006_settings_set_validation.py) but
    only assert raw `.aid/settings.yml` substrings for `project.name` -- never
    re-read the write through `read_repo()`/`serialize_model()` for ANY of the
    three paths, and never touch `project_description`/`minimum_grade` at all.
  - pipeline.rename (task-008/feature-005): dispatch tests
    (test_task008_display_rename.py) assert the raw `REQUIREMENTS.md` bullet
    text, never `read_repo()`'s `WorkModel.title`.
  - task.rename (task-008/feature-005): ALREADY has a full write->read_repo()
    round trip, both layouts, both non-empty and empty-clears-to-None
    (test_task008_display_rename.py's TestTaskRenameWriteReadRoundTrip) -- this
    file does NOT duplicate that; see TestTaskRenameRoundTripAlreadyCovered
    below for a thin, explicit pointer instead.
  - task.set-notes (task-010/feature-006): dispatch tests
    (test_task010_task_notes.py) assert the raw STATE.md substring, never
    `read_repo()`'s `TaskModel.notes`.
  - Model-field twin parity (AC4): `project_description`/`minimum_grade`
    (RepoInfo, task-005) are each individually pinned to a hardcoded expected
    key-order list in test_server_py.py / test_server_node.mjs, but the two
    runtimes' ACTUAL outputs are never diffed against each other for identical
    input (as `TestCrossTwinParityDisplayName` in
    dashboard/reader/tests/test_task008_display_rename.py already does for
    `display_name`). TestCrossRuntimeRepoInfoParity below closes that gap the
    same way, extending "the reader ... parity suite" (this task's own AC
    wording) with a genuine A/B equality check rather than two independent
    hardcoded-list assertions.
  - KI-001 read-side hazard (feature-002 SPEC.md, Open Questions): the DM-1
    reader (`parse_project_settings`, `parsers.py`) is documented as "the
    fourth ad-hoc settings.yml reader of project.description" and MUST
    round-trip identically to the pre-existing `_read_settings` (server.py,
    the reader behind the all-projects grid) / `readSettings` (server.mjs).
    No test previously compared these two readers' OUTPUT for identical
    input in either runtime -- TestSettingsKi001ReadSideParity (Python) and
    TestSettingsKi001NodeSideParity (Node, via server.mjs's own established
    module-slice technique) close that.
  - Legacy 5-column `### Tasks lifecycle` row -> `display_name None`
    (fallback): ALREADY fully covered (parser unit test, reader integration
    test, AND cross-twin parity) by
    dashboard/reader/tests/test_task008_display_rename.py
    (TestParseTasksLifecycleMdName.test_legacy_five_column_row_yields_none,
    TestReadRepoFlatLayoutDisplayName.test_legacy_five_column_table_yields_none,
    TestCrossTwinParityDisplayName.test_flat_legacy_five_column_parity). This
    file adds ONE thin, self-contained pointer test
    (TestLegacyFiveColumnDisplayNameFallbackPointer) so the AC is also directly
    traceable from THIS task's own suite, without duplicating that fixture.

Every dispatch below goes through the REAL co-vendored writer (writeback-state.sh /
write-setting.sh / write-requirement.sh) via `srv._dispatch_op` -- a bounded,
non-interactive child-process spawn, exactly like test_task004/008/010's own
convention. No server is spawned, no port is bound anywhere in this file; every
test here is safe to run locally per this repo's port-binding-test constraint.

Python 3.11+ stdlib only. No third-party deps. Node comparisons (skipped, not
failed, when `node` is absent from PATH) reuse the two established Node
cross-runtime techniques already in this codebase:
  - `readRepo()` is directly importable from reader.mjs (no side effects on
    import) -- dashboard/reader/tests/test_task008_display_rename.py's
    `_run_node_task0` pattern.
  - `readSettings` lives in server.mjs, which self-executes (parses argv, BINDS
    A SOCKET) on import -- dashboard/server/tests/
    test_task010_task_notes_cross_runtime_parity.py's marker-based
    slice-and-export workaround is reused verbatim (same cut marker).
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
import unittest.mock as mock
import uuid
from pathlib import Path

# ---------------------------------------------------------------------------
# Make the dashboard package importable regardless of CWD (mirrors
# test_task004_op_dispatch.py / test_task008_display_rename.py's own setup).
# ---------------------------------------------------------------------------
_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo
from dashboard.reader.parsers import parse_project_settings, parse_minimum_grade
from dashboard.server import server as srv

_READER_MJS = _DASHBOARD_DIR / "server" / "reader.mjs"
_SERVER_MJS = _DASHBOARD_DIR / "server" / "server.mjs"


# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

class _TmpRepo:
    """Context manager: a scratch repo root, cleaned up on exit."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp())
        return self.path

    def __exit__(self, *_exc) -> None:
        shutil.rmtree(self.path, ignore_errors=True)


def _make_settings_repo(root: Path, *, name: "str | None" = "Old Name",
                         description: "str | None" = "Old description",
                         grade: "str | None" = None) -> Path:
    """A repo root with `.aid/settings.yml` shaped like a REAL settings.yml --
    project: / tools: / review: sections in that order (feature-002 SPEC.md's
    own grounding: 'tools: sits between project: and review: in a real
    settings.yml', which is exactly why parse_minimum_grade needs its own
    review:-section scan rather than reusing parse_project_settings's)."""
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    lines = ["project:\n"]
    if name is not None:
        lines.append(f"  name: {name}\n")
    if description is not None:
        lines.append(f"  description: {description}\n")
    lines.append("tools:\n  installed:\n    - claude-code\n")
    lines.append("review:\n")
    if grade is not None:
        lines.append(f"  minimum_grade: {grade}\n")
    (aid / "settings.yml").write_text("".join(lines), encoding="utf-8")
    (aid / ".aid-manifest.json").write_text(
        json.dumps({
            "manifest_version": 1,
            "aid_version": "1.0.0-test",
            "installed_at": "2026-01-01T00:00:00Z",
            "tools": {"claude-code": {}},
        }),
        encoding="utf-8",
    )
    return root


def _read_model(root: Path):
    """read_repo() with git-worktree enumeration mocked to the single main root
    (mirrors test_task008_display_rename.py's `_read_repo_single_work` -- skips
    the (harmless but slow, per this repo's fork-cost note) per-call `git
    worktree list` subprocess against a non-git tmp dir; SD-3 would degrade to
    the exact same [("main", aid)] result unmocked)."""
    aid = root / ".aid"
    with mock.patch(
        "dashboard.reader.reader.enumerate_worktree_roots",
        return_value=[("main", aid)],
    ):
        return read_repo(root)


def _make_flat_work(root: Path, work_id: str, *, notes: str = "--",
                     req_name: str = "Old Title") -> Path:
    """A flat/Lite-layout work: BLUEPRINT.md + tasks/task-001/DETAIL.md markers,
    a REQUIREMENTS.md with a Name bullet (pipeline.rename target), and a
    STATE.md with a legacy 5-column '### Tasks lifecycle' row (task.set-notes
    target) -- mirrors test_task008_display_rename.py's / test_task010's own
    flat-work fixture shape."""
    work_dir = root / ".aid" / "works" / work_id
    (work_dir / "tasks" / "task-001").mkdir(parents=True, exist_ok=True)
    (work_dir / "BLUEPRINT.md").write_text("# Blueprint\n", encoding="utf-8")
    (work_dir / "tasks" / "task-001" / "DETAIL.md").write_text(
        "# task-001: Flat task\n\n**Type:** IMPLEMENT\n", encoding="utf-8",
    )
    (work_dir / "REQUIREMENTS.md").write_text(
        f"# Requirements\n\n- **Name:** {req_name}\n", encoding="utf-8",
    )
    (work_dir / "STATE.md").write_text(
        "---\n"
        "lifecycle: Running\n"
        "updated: '2026-01-01T00:00:00Z'\n"
        "---\n\n"
        "# Work State\n\n"
        "### Tasks lifecycle\n\n"
        "| Task | State | Review | Elapsed | Notes |\n"
        "| --- | --- | --- | --- | --- |\n"
        f"| task-001 | Pending | -- | -- | {notes} |\n",
        encoding="utf-8",
    )
    return work_dir


def _make_hierarchical_work(root: Path, work_id: str, *, notes: "str | None" = None) -> Path:
    """A full-nested-layout work: deliveries/delivery-001/tasks/task-001, with
    a per-task STATE.md frontmatter carrying (optionally) a `notes` scalar."""
    del_dir = root / ".aid" / "works" / work_id / "deliveries" / "delivery-001"
    task_dir = del_dir / "tasks" / "task-001"
    task_dir.mkdir(parents=True, exist_ok=True)
    (root / ".aid" / "works" / work_id / "STATE.md").write_text(
        "## Pipeline State\n\n- **Lifecycle:** Running\n", encoding="utf-8",
    )
    (del_dir / "STATE.md").write_text(
        "## Delivery Lifecycle\n\n- **State:** Executing\n", encoding="utf-8",
    )
    (task_dir / "DETAIL.md").write_text(
        "# task-001: Nested task\n\n**Type:** IMPLEMENT\n\n"
        "**Source:** feature-006-task-notes -> delivery-001\n",
        encoding="utf-8",
    )
    fm = "---\nstate: Pending\n"
    if notes is not None:
        fm += f"notes: {notes}\n"
    fm += "---\n\n## Task State\n"
    (task_dir / "STATE.md").write_text(fm, encoding="utf-8")
    return root / ".aid" / "works" / work_id


def _node_available() -> bool:
    try:
        r = subprocess.run(["node", "--version"], capture_output=True, timeout=5)
        return r.returncode == 0
    except Exception:
        return False


_NODE_AVAILABLE = _node_available()


def _run_node_read_repo(root: Path) -> dict:
    """Run reader.mjs's exported readRepo() in a bounded subprocess (no server,
    no port) and return the full model as a plain dict (mirrors
    test_task008_display_rename.py's `_run_node_task0`, generalized to the
    whole model rather than just tasks[0])."""
    script = (
        f"import {{ readRepo }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const m = readRepo({json.dumps(str(root))});\n"
        "process.stdout.write(JSON.stringify(m) + '\\n');\n"
    )
    result = subprocess.run(
        ["node", "--input-type=module"],
        input=script,
        capture_output=True,
        text=True,
        timeout=15,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:800]}")
    return json.loads(result.stdout.strip())


# Stable single-line cut marker -- kept in lockstep with
# test_task010_task_notes_cross_runtime_parity.py's identical marker string.
_MAIN_MARKER = "// Main: parse args, create server, bind, register SIGTERM"


def _sliced_server_mjs_source() -> str:
    """server.mjs's own source, truncated right before its side-effecting
    'Main' tail, with readSettings re-exported. Raises loudly (not silently)
    if the stable marker is gone."""
    text = _SERVER_MJS.read_text(encoding="utf-8")
    idx = text.find(_MAIN_MARKER)
    assert idx != -1, (
        "server.mjs's 'Main: parse args, create server, bind, register SIGTERM' "
        "marker comment is gone -- this test's source-slice cut point needs updating"
    )
    return text[:idx] + "\nexport { readSettings };\n"


class _NodeSlicedServerFixture:
    """setUpClass/tearDownClass helper: writes the sliced server.mjs export
    once per test class, deletes it afterward regardless of outcome."""

    _slice_path: Path

    @classmethod
    def setUpClass(cls) -> None:
        cls._slice_path = _SERVER_DIR / f"_test_task012_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(_sliced_server_mjs_source(), encoding="utf-8")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)

    def _node_read_settings(self, repo_path: Path) -> dict:
        driver = (
            f"import {{ readSettings }} from {json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const r = readSettings({json.dumps(str(repo_path))});\n"
            "process.stdout.write(JSON.stringify(r) + '\\n');\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"],
            input=driver, capture_output=True, text=True, timeout=15,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node readSettings driver failed: {result.stderr[:800]}")
        return json.loads(result.stdout.strip())


# ===========================================================================
# (A) settings.set: write-setting.sh -> re-fetched model (RepoInfo) round trip.
# ===========================================================================

class TestSettingsSetWriteReReadRoundTrip(unittest.TestCase):
    """dispatch settings.set through the REAL write-setting.sh, then re-fetch
    via the ACTUAL reader (read_repo -> serialize_model, the same pair the
    server's own GET /r/<id>/api/model handler calls) and assert the new value
    is present -- never a stale/optimistic one (AC1/AC2)."""

    def test_name_round_trips_through_model(self):
        with _TmpRepo() as root:
            _make_settings_repo(root, name="Old Name")
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "project.name", "value": "New Name"}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            model = _read_model(root)
            envelope = json.loads(srv.serialize_model(model, write_enabled=True))
            self.assertEqual(envelope["model"]["repo"]["project_name"], "New Name")

    def test_description_round_trips_through_model(self):
        with _TmpRepo() as root:
            _make_settings_repo(root, description="Old description")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "settings.set", "args": {"path": "project.description", "value": "New description"}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            model = _read_model(root)
            envelope = json.loads(srv.serialize_model(model, write_enabled=True))
            self.assertEqual(envelope["model"]["repo"]["project_description"], "New description")

    def test_description_empty_clears_to_none(self):
        with _TmpRepo() as root:
            _make_settings_repo(root, description="Has a description")
            status, _body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "project.description", "value": ""}},
                str(root),
            )
            self.assertEqual(status, 200)
            model = _read_model(root)
            self.assertIsNone(model.repo.project_description)

    def test_grade_round_trips_through_model(self):
        with _TmpRepo() as root:
            _make_settings_repo(root, grade=None)
            status, body = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "review.minimum_grade", "value": "B+"}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            model = _read_model(root)
            envelope = json.loads(srv.serialize_model(model, write_enabled=True))
            self.assertEqual(envelope["model"]["repo"]["minimum_grade"], "B+")

    def test_sequential_edits_show_latest_value_not_stale(self):
        """Two edits in a row: the SECOND re-fetch must show the SECOND value,
        proving each re-fetch reads fresh off disk rather than an earlier
        cached/optimistic value (AC2's 'no drift')."""
        with _TmpRepo() as root:
            _make_settings_repo(root, name="Original")
            status1, _ = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "project.name", "value": "First Edit"}},
                str(root),
            )
            self.assertEqual(status1, 200)
            self.assertEqual(_read_model(root).repo.project_name, "First Edit")

            status2, _ = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "project.name", "value": "Second Edit"}},
                str(root),
            )
            self.assertEqual(status2, 200)
            self.assertEqual(_read_model(root).repo.project_name, "Second Edit")


# ===========================================================================
# (B) KI-001 read-side parity: DM-1's parse_project_settings vs server.py's
# _read_settings (the pre-existing all-projects-grid reader) -- SAME runtime,
# two independently-coded 'project:'-section scans that must agree.
# ===========================================================================

class TestSettingsKi001ReadSideParity(unittest.TestCase):
    """Pins parse_project_settings() (DM-1, parsers.py) to _read_settings()
    (server.py, the pre-existing 'third reader' feature-002 SPEC.md's KI-001
    caveat names) for identical settings.yml content -- the read-side half of
    the KI-001 divergent-parser hazard (the write-side half, write-setting.sh's
    own charset guard, is covered by test-write-setting.sh /
    test_task006_settings_set_validation.py)."""

    def _both_readers(self, root: Path) -> "tuple[tuple, tuple]":
        dm1_name, dm1_desc, _br = parse_project_settings(root / ".aid" / "settings.yml")
        grid_name, grid_desc = srv._read_settings(str(root))
        return (dm1_name, dm1_desc), (grid_name, grid_desc)

    def test_plain_values_agree(self):
        with _TmpRepo() as root:
            _make_settings_repo(root, name="MyProject", description="A test project")
            dm1, grid = self._both_readers(root)
            self.assertEqual(dm1, grid)
            self.assertEqual(dm1, ("MyProject", "A test project"))

    def test_inline_comment_stripped_identically(self):
        with _TmpRepo() as root:
            aid = root / ".aid"
            aid.mkdir(parents=True, exist_ok=True)
            (aid / "settings.yml").write_text(
                "project:\n"
                "  name: AID                          # set during /aid-config INIT\n"
                "  description: AI Integrated Development\n",
                encoding="utf-8",
            )
            dm1, grid = self._both_readers(root)
            self.assertEqual(dm1, grid)
            self.assertEqual(dm1, ("AID", "AI Integrated Development"))

    def test_quoted_value_with_trailing_comment_agrees(self):
        with _TmpRepo() as root:
            aid = root / ".aid"
            aid.mkdir(parents=True, exist_ok=True)
            (aid / "settings.yml").write_text(
                'project:\n  name: MyProject\n  description: "Foo Bar" # comment\n',
                encoding="utf-8",
            )
            dm1, grid = self._both_readers(root)
            self.assertEqual(dm1, grid)
            self.assertEqual(dm1, ("MyProject", "Foo Bar"))

    def test_apostrophe_value_agrees(self):
        with _TmpRepo() as root:
            _make_settings_repo(root, name="Andre's Project", description="It's a test")
            dm1, grid = self._both_readers(root)
            self.assertEqual(dm1, grid)
            self.assertEqual(dm1, ("Andre's Project", "It's a test"))

    def test_real_write_setting_round_trip_agrees(self):
        """After a REAL write-setting.sh dispatch (not a hand-authored
        fixture), both readers still agree on the resulting file."""
        with _TmpRepo() as root:
            _make_settings_repo(root, name="Old Name", description="Old description")
            status, _ = srv._dispatch_op(
                srv.OP_TABLE, {"op": "settings.set", "args": {"path": "project.description", "value": "Freshly written"}},
                str(root),
            )
            self.assertEqual(status, 200)
            dm1, grid = self._both_readers(root)
            self.assertEqual(dm1, grid)
            self.assertEqual(dm1, ("Old Name", "Freshly written"))


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- Node-side KI-001 parity skipped")
class TestSettingsKi001NodeSideParity(_NodeSlicedServerFixture, unittest.TestCase):
    """Node-side twin of TestSettingsKi001ReadSideParity: server.mjs's own
    readSettings() (independently re-implemented, NOT imported from
    reader.mjs -- confirmed by inspection: server.mjs declares its own
    stripYamlInlineComment rather than importing reader.mjs's) vs readRepo()'s
    project_name/project_description (built by parseProjectSettings in
    reader.mjs)."""

    def test_plain_values_agree_node(self):
        with _TmpRepo() as root:
            _make_settings_repo(root, name="MyProject", description="A test project")
            model = _run_node_read_repo(root)
            settings = self._node_read_settings(root)
            self.assertEqual(settings["name"], model["repo"]["project_name"])
            self.assertEqual(settings["description"], model["repo"]["project_description"])
            self.assertEqual(settings["name"], "MyProject")
            self.assertEqual(settings["description"], "A test project")

    def test_inline_comment_stripped_identically_node(self):
        with _TmpRepo() as root:
            aid = root / ".aid"
            aid.mkdir(parents=True, exist_ok=True)
            (aid / "settings.yml").write_text(
                "project:\n"
                "  name: AID                          # set during /aid-config INIT\n"
                "  description: AI Integrated Development\n",
                encoding="utf-8",
            )
            model = _run_node_read_repo(root)
            settings = self._node_read_settings(root)
            self.assertEqual(settings["name"], model["repo"]["project_name"])
            self.assertEqual(settings["description"], model["repo"]["project_description"])
            self.assertEqual(settings["name"], "AID")


# ===========================================================================
# (C) pipeline.rename: write-requirement.sh -> re-fetched WorkModel.title.
# ===========================================================================

class TestPipelineRenameRoundTrip(unittest.TestCase):
    def test_rename_round_trips_to_title(self):
        with _TmpRepo() as root:
            _make_flat_work(root, "work-720-pipeline", req_name="Old Title")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "pipeline.rename", "target": {"work_id": "work-720-pipeline"}, "args": {"value": "New Title"}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            model = _read_model(root)
            self.assertEqual(model.works[0].title, "New Title")

    def test_empty_value_clears_title_to_none_slug_fallback(self):
        """Empty rename -> *(pending)* null sentinel -> WorkModel.title None --
        home.html's existing de-slug fallback then renders WorkModel.name (the
        folder-slug label), which this model already carries unconditionally."""
        with _TmpRepo() as root:
            _make_flat_work(root, "work-721-pipeline-clear", req_name="Has A Title")
            status, _body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "pipeline.rename", "target": {"work_id": "work-721-pipeline-clear"}, "args": {"value": ""}},
                str(root),
            )
            self.assertEqual(status, 200)
            model = _read_model(root)
            self.assertIsNone(model.works[0].title)
            self.assertTrue(model.works[0].name)  # the slug-fallback source is still populated


# ===========================================================================
# (D) task.set-notes: writeback-state.sh -> re-fetched TaskModel.notes.
# ===========================================================================

class TestTaskSetNotesRoundTrip(unittest.TestCase):
    def test_flat_layout_round_trips_to_notes(self):
        with _TmpRepo() as root:
            _make_flat_work(root, "work-730-flat-notes")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes", "target": {"work_id": "work-730-flat-notes", "task_id": "001"},
                 "args": {"value": "blocked on upstream fix"}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            model = _read_model(root)
            self.assertEqual(model.works[0].tasks[0].notes, "blocked on upstream fix")

    def test_nested_layout_round_trips_to_notes(self):
        with _TmpRepo() as root:
            _make_hierarchical_work(root, "work-731-nested-notes")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes",
                 "target": {"work_id": "work-731-nested-notes", "delivery_id": "1", "task_id": "001"},
                 "args": {"value": "context for reviewer"}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            model = _read_model(root)
            self.assertEqual(model.works[0].tasks[0].notes, "context for reviewer")

    def test_empty_value_clears_notes_to_none(self):
        with _TmpRepo() as root:
            _make_flat_work(root, "work-732-flat-clear", notes="had some notes")
            status, _body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes", "target": {"work_id": "work-732-flat-clear", "task_id": "001"},
                 "args": {"value": ""}},
                str(root),
            )
            self.assertEqual(status, 200)
            model = _read_model(root)
            self.assertIsNone(model.works[0].tasks[0].notes)

    def test_sequential_edits_show_latest_notes_not_stale(self):
        with _TmpRepo() as root:
            _make_flat_work(root, "work-733-flat-sequential")
            srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes", "target": {"work_id": "work-733-flat-sequential", "task_id": "001"},
                 "args": {"value": "first note"}},
                str(root),
            )
            self.assertEqual(_read_model(root).works[0].tasks[0].notes, "first note")
            srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.set-notes", "target": {"work_id": "work-733-flat-sequential", "task_id": "001"},
                 "args": {"value": "second note"}},
                str(root),
            )
            self.assertEqual(_read_model(root).works[0].tasks[0].notes, "second note")


# ===========================================================================
# (E) task.rename round trip -- ALREADY fully covered; thin pointer only.
# ===========================================================================

class TestTaskRenameRoundTripAlreadyCovered(unittest.TestCase):
    """task.rename's write -> read_repo() round trip (both layouts, both
    non-empty and empty-clears-to-None) is ALREADY exhaustively covered by
    dashboard/server/tests/test_task008_display_rename.py's
    TestTaskRenameWriteReadRoundTrip class (test_flat_round_trip,
    test_flat_empty_clears_to_none, test_nested_round_trip,
    test_nested_empty_clears_to_none) -- this test intentionally does NOT
    duplicate that fixture; it re-asserts the SAME contract with an
    independent minimal fixture purely for direct AC-traceability from this
    task's own suite (task-012 Scope: 'task.rename -> ... -> display_name cell
    ... -> precedence render')."""

    def test_task_rename_round_trips_to_display_name(self):
        with _TmpRepo() as root:
            _make_flat_work(root, "work-740-rename-pointer")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "task.rename", "target": {"work_id": "work-740-rename-pointer", "task_id": "001"},
                 "args": {"value": "Renamed via task-012 pointer test"}},
                str(root),
            )
            self.assertEqual(status, 200, body)
            model = _read_model(root)
            self.assertEqual(model.works[0].tasks[0].display_name, "Renamed via task-012 pointer test")


# ===========================================================================
# (F) Regression fixture: legacy 5-column '### Tasks lifecycle' row ->
# display_name None (fallback) -- ALREADY fully covered; thin pointer only.
# ===========================================================================

class TestLegacyFiveColumnDisplayNameFallbackPointer(unittest.TestCase):
    """ALREADY exhaustively covered (parser unit test, reader integration test,
    AND Python<->Node cross-twin parity) by
    dashboard/reader/tests/test_task008_display_rename.py:
      TestParseTasksLifecycleMdName.test_legacy_five_column_row_yields_none
      TestReadRepoFlatLayoutDisplayName.test_legacy_five_column_table_yields_none
      TestCrossTwinParityDisplayName.test_flat_legacy_five_column_parity
    This is a thin, self-contained pointer re-assertion (via read_repo(), not
    the bare parser) for direct traceability from THIS task's own suite --
    task-012 Scope explicitly names this fixture."""

    def test_legacy_five_column_table_yields_display_name_none(self):
        with _TmpRepo() as root:
            _make_flat_work(root, "work-741-legacy-table")  # 5-column table, no Name column
            model = _read_model(root)
            self.assertIsNone(model.works[0].tasks[0].display_name)
            self.assertIsNotNone(model.works[0].tasks[0].short_name)  # unaffected sibling field


# ===========================================================================
# (G) Model-field twin parity (AC4): RepoInfo project_description/minimum_grade,
# a genuine cross-runtime A/B equality check (Python read_repo() vs Node
# readRepo() for IDENTICAL input) -- extends the existing hardcoded-key-order
# assertions in test_server_py.py/test_server_node.mjs (task-005) with the same
# technique TestCrossTwinParityDisplayName (test_task008_display_rename.py)
# already applies to display_name.
# ===========================================================================

# Fields compared across runtimes: excludes 'aid_dir'. On Windows, Python's
# Path.resolve() and Node's path resolution can disagree on 8.3-short-form
# vs long-form directory-name segments for the SAME real path (e.g. a
# tempfile.mkdtemp() root under a long username -- 'ANDRE~1.VIA' vs
# 'andre.vianna') -- a pre-existing, environment-specific artifact unrelated
# to this feature's parity concern (project_name/project_description/
# minimum_grade/kb_state), which this test scopes to instead.
_REPO_INFO_PARITY_FIELDS = ("project_name", "project_description", "minimum_grade", "kb_state")


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- cross-runtime parity skipped")
class TestCrossRuntimeRepoInfoParity(unittest.TestCase):
    def _py_repo_dict(self, root: Path) -> dict:
        model = _read_model(root)
        return srv._ser_repo_info(model.repo)

    @staticmethod
    def _scoped(repo: dict) -> dict:
        return {k: repo[k] for k in _REPO_INFO_PARITY_FIELDS}

    def test_project_description_and_minimum_grade_parity(self):
        with _TmpRepo() as root:
            _make_settings_repo(root, name="Parity Project", description="Parity description", grade="A-")
            py_repo = self._py_repo_dict(root)
            node_model = _run_node_read_repo(root)
            self.assertEqual(self._scoped(py_repo), self._scoped(node_model["repo"]))
            self.assertEqual(py_repo["project_description"], "Parity description")
            self.assertEqual(py_repo["minimum_grade"], "A-")

    def test_absent_settings_yml_parity(self):
        with _TmpRepo() as root:
            (root / ".aid").mkdir(parents=True, exist_ok=True)   # no settings.yml at all
            py_repo = self._py_repo_dict(root)
            node_model = _run_node_read_repo(root)
            self.assertEqual(self._scoped(py_repo), self._scoped(node_model["repo"]))
            self.assertIsNone(py_repo["project_description"])
            self.assertIsNone(py_repo["minimum_grade"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
