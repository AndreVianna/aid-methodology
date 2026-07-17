"""
test_work016_container_discovery.py -- Regression guard for work-016 task-004
(Concern A: container discovery under .aid/works/).

WHAT THIS LOCKS IN
------------------
The reported defect: work discovery was coupled to a `^work-[0-9]+-` folder-name
convention, so a naming slip hid the work from the dashboard. work-016 relocates
works into a `.aid/works/` container and enumerates EVERY direct subfolder of it
as a work -- visibility no longer depends on the folder name.

This suite asserts, per task-004's acceptance criteria:
  * AC-1  a subfolder of `.aid/works/` with NO numeric prefix IS discovered/shown
          (the reported symptom cannot recur);
  * AC-3  the readers read ONLY `.aid/works/*` -- a legacy top-level
          `.aid/work-NNN-*` folder (directly under `.aid/`, not under works/) is
          NOT enumerated (no dual-read);
  * AC-4  Python (`locator.py`/`reader.py`) <-> Node (`reader.mjs`) parity holds
          for the same `.aid/works/` tree; and the presentation layer
          (`home.html`'s client path-fallback + empty-state/help text and
          `models.py`'s captions) references `.aid/works/`.

FAIL-PRE / PASS-POST CONTRACT
-----------------------------
Every assertion is written against the POST-FIX container contract and RED-FAILS
BY CONSTRUCTION on the pre-fix readers -- no need to stash/revert task-001/002 to
observe red:

  * Pre-fix the twins enumerated `.aid/*` filtered by `^work-[0-9]+-` and
    re-derived per-work paths as `.aid/{work_id}/...`. Against that code a work
    placed under `.aid/works/` is not found at all (wrong container) and a
    numberless name additionally fails the name filter -> the discovery asserts
    below see `works == []` and red-fail.
  * Pre-fix `home.html`'s browser fallback / empty-state text and `models.py`'s
    captions still named `.aid/` (not `.aid/works/`) -> the presentation asserts
    below red-fail.
  * Post-fix the twins enumerate every direct subfolder of `.aid/works/`
    (name-independent) and re-derive paths as `.aid/works/{work_id}/...`, so all
    assertions pass.

Wired into the repo's existing pytest reader suite (run by
`python -m pytest dashboard/reader/tests`) -- no new harness. Python 3.11+ stdlib
only; deterministic. The Node-parity case is gated on node availability (skips
cleanly when node is absent).
"""

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

# Robust paths (works from either the main checkout or a git worktree):
_TESTS_DIR = Path(__file__).resolve().parent          # dashboard/reader/tests/
_READER_DIR = _TESTS_DIR.parent                       # dashboard/reader/
_DASHBOARD_DIR = _READER_DIR.parent                   # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                    # repo root (contains dashboard/)

import sys
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import Lifecycle, read_repo
from dashboard.reader.locator import locate_aid_root

_HOME_HTML = _DASHBOARD_DIR / "home.html"
_MODELS_PY = _READER_DIR / "models.py"
_READER_MJS = _DASHBOARD_DIR / "server" / "reader.mjs"


# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

_STATE_MD = """\
# Work State

## Pipeline Status

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** aid-execute
- **Updated:** 2026-07-17T00:00:00Z
- **Pause Reason:** --
- **Block Reason:** --
- **Block Artifact:** --

## Tasks Status

| # | Task | Type | Wave | Status | Review | Elapsed | Notes |
|---|------|------|------|--------|--------|---------|-------|
| 001 | task-001 | IMPLEMENT | delivery-001 | In Progress | -- | -- | -- |
"""


def _make_aid(root: Path) -> Path:
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    (aid / "settings.yml").write_text("project:\n  name: work016\n", encoding="utf-8")
    (aid / ".aid-manifest.json").write_text(
        json.dumps({
            "manifest_version": 1,
            "aid_version": "1.0.0",
            "installed_at": "2026-07-17T00:00:00Z",
            "tools": {"claude-code": {}},
        }),
        encoding="utf-8",
    )
    return aid


def _make_work(aid: Path, work_id: str, *, state: bool = True) -> Path:
    """Create a work as a direct subfolder of the .aid/works/ container."""
    wd = aid / "works" / work_id
    wd.mkdir(parents=True, exist_ok=True)
    if state:
        (wd / "STATE.md").write_text(_STATE_MD, encoding="utf-8")
    return wd


def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return False


def _run_node_work_ids(root: Path, pinned_home: Path) -> list[tuple[str, str]]:
    """Run reader.mjs readRepo() in a bounded, in-process (no server/port)
    subprocess and return [(work_id, lifecycle), ...] sorted by work_id.

    Uses a file:// URL module specifier (Path.as_uri()) so this actually runs on
    Windows instead of hitting ERR_UNSUPPORTED_ESM_URL_SCHEME (same pattern as
    test_work003_state_schema.py::_run_node_work)."""
    script = (
        f"import {{ readRepo }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const m = readRepo({json.dumps(str(root))});\n"
        "const out = (m.works || []).map((w) => [w.work_id, w.lifecycle]);\n"
        "out.sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0));\n"
        "process.stdout.write(JSON.stringify(out) + '\\n');\n"
    )
    result = subprocess.run(
        ["node", "--input-type=module"],
        input=script,
        capture_output=True,
        text=True,
        timeout=20,
        env={**os.environ, "HOME": str(pinned_home)},
    )
    if result.returncode != 0:
        raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:500]}")
    return [(wid, lc) for wid, lc in json.loads(result.stdout.strip())]


# ---------------------------------------------------------------------------
# AC-1: name-independent discovery (the reported symptom cannot recur)
# ---------------------------------------------------------------------------

class TestNameIndependentDiscovery(unittest.TestCase):
    """AC-1: a numberless / arbitrarily-named subfolder of .aid/works/ IS
    discovered and shown. RED-FAILS pre-fix (the ^work-[0-9]+- filter drops the
    numberless name, and the pre-fix reader never looked in .aid/works/ at all)."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        self.aid = _make_aid(self.root)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_numberless_subfolder_enumerated_by_locator(self):
        _make_work(self.aid, "just-a-name", state=False)
        loc = locate_aid_root(self.root)
        names = [p.name for p in loc.work_dirs]
        self.assertIn("just-a-name", names,
                      "a numberless .aid/works/ subfolder must be enumerated (AC-1)")

    def test_numberless_subfolder_shown_by_read_repo(self):
        _make_work(self.aid, "just-a-name")
        model = read_repo(self.root)
        work_ids = [w.work_id for w in model.works]
        self.assertIn("just-a-name", work_ids,
                      "a numberless .aid/works/ work must appear in the model (AC-1)")
        self.assertEqual(model.read.work_count, 1)

    def test_arbitrary_names_all_discovered(self):
        for name in ("numberless-work", "work-007-numbered", "UPPER_and.dots", "42-leading-digits"):
            _make_work(self.aid, name)
        model = read_repo(self.root)
        got = {w.work_id for w in model.works}
        self.assertEqual(
            got, {"numberless-work", "work-007-numbered", "UPPER_and.dots", "42-leading-digits"},
            "EVERY direct subfolder of .aid/works/ is a work regardless of its name (AC-1)")

    def test_numberless_work_state_parsed(self):
        _make_work(self.aid, "no-number-here")
        model = read_repo(self.root)
        w = next(w for w in model.works if w.work_id == "no-number-here")
        self.assertEqual(w.lifecycle, Lifecycle.Running,
                         "the numberless work's STATE.md must parse like any other work")


# ---------------------------------------------------------------------------
# AC-3: readers read ONLY .aid/works/* (no dual-read)
# ---------------------------------------------------------------------------

class TestOnlyWorksContainerRead(unittest.TestCase):
    """AC-3: a legacy top-level `.aid/work-NNN-*` folder (directly under .aid/,
    NOT under works/) is NOT read. Only `.aid/works/*` subfolders are read."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        self.aid = _make_aid(self.root)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _make_legacy_toplevel_work(self, work_id: str) -> None:
        """Create a legacy work directly under .aid/ (the PRE-container location)."""
        legacy = self.aid / work_id
        legacy.mkdir(parents=True, exist_ok=True)
        (legacy / "STATE.md").write_text(_STATE_MD, encoding="utf-8")

    def test_legacy_toplevel_work_not_enumerated(self):
        # A perfectly-named legacy work at the OLD location...
        self._make_legacy_toplevel_work("work-999-legacy")
        # ...and one real work in the container.
        _make_work(self.aid, "work-001-real")

        loc = locate_aid_root(self.root)
        names = [p.name for p in loc.work_dirs]
        self.assertIn("work-001-real", names)
        self.assertNotIn("work-999-legacy", names,
                         "a top-level .aid/work-NNN-* must NOT be read -- only .aid/works/* (AC-3)")

    def test_read_repo_ignores_legacy_toplevel_work(self):
        self._make_legacy_toplevel_work("work-999-legacy")
        _make_work(self.aid, "work-001-real")

        model = read_repo(self.root)
        work_ids = {w.work_id for w in model.works}
        self.assertEqual(work_ids, {"work-001-real"},
                         "no dual-read: the legacy top-level work must be absent from the model (AC-3)")
        self.assertEqual(model.read.work_count, 1)

    def test_non_work_siblings_of_works_excluded(self):
        # knowledge/, .temp/, .heartbeat/ live BESIDE works/ under .aid/ -- they
        # are excluded structurally by the "all subfolders of .aid/works/" selector.
        _make_work(self.aid, "work-001-real")
        (self.aid / "knowledge").mkdir()
        (self.aid / ".temp").mkdir()
        (self.aid / ".heartbeat").mkdir()

        model = read_repo(self.root)
        work_ids = {w.work_id for w in model.works}
        self.assertEqual(work_ids, {"work-001-real"})
        for sib in ("knowledge", ".temp", ".heartbeat"):
            self.assertNotIn(sib, work_ids)


# ---------------------------------------------------------------------------
# AC-4: Python <-> Node parity for the same .aid/works/ tree
# ---------------------------------------------------------------------------

@unittest.skipUnless(_node_available(), "node not available on PATH")
class TestPythonNodeContainerParity(unittest.TestCase):
    """AC-4: for the same `.aid/works/` tree, the Python and Node readers produce
    parity-consistent enumeration -- including a numberless work. RED-FAILS pre-fix
    (both twins returned [] because they read the wrong container)."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)
        self.aid = _make_aid(self.root)
        # Pin HOME so reader.mjs's HOME-rooted worktree scan cannot escape the fixture.
        self.pinned_home = Path(self.tmp) / "_home"
        self.pinned_home.mkdir(parents=True, exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_python_node_agree_on_container_tree(self):
        _make_work(self.aid, "work-001-alpha")
        _make_work(self.aid, "work-002-beta")
        _make_work(self.aid, "numberless-work")  # the symptom-guard name

        model = read_repo(self.root)
        py = sorted((w.work_id, w.lifecycle.value) for w in model.works)
        node = sorted(_run_node_work_ids(self.root, self.pinned_home))

        self.assertEqual(
            py, node,
            "Python and Node readers must agree on the .aid/works/ enumeration "
            "(ids + lifecycle), numberless work included (AC-4)")
        self.assertEqual(
            {wid for wid, _ in py},
            {"work-001-alpha", "work-002-beta", "numberless-work"})


# ---------------------------------------------------------------------------
# AC-4: presentation layer references .aid/works/
# ---------------------------------------------------------------------------

class TestPresentationReferencesWorksContainer(unittest.TestCase):
    """AC-4: home.html's client path-fallback + empty-state/help text and
    models.py's captions reference `.aid/works/`. RED-FAILS pre-fix (all these
    sites still named `.aid/`, not `.aid/works/`)."""

    @classmethod
    def setUpClass(cls):
        assert _HOME_HTML.is_file(), f"home.html not found at {_HOME_HTML}"
        assert _MODELS_PY.is_file(), f"models.py not found at {_MODELS_PY}"
        cls.home = _HOME_HTML.read_text(encoding="utf-8")
        cls.models = _MODELS_PY.read_text(encoding="utf-8")

    # -- home.html client-side per-work path fallback (browser twin of the reader
    #    per-work path re-derivation) --
    def test_home_html_client_fallback_path_uses_works(self):
        self.assertIn("'.aid/works/' + workId + '/STATE.md'", self.home,
                      "home.html fallback path must resolve to .aid/works/{workId}/STATE.md (AC-4)")

    def test_home_html_client_fallback_old_path_gone(self):
        # The pre-fix browser fallback was ('.aid/' + workId + '/STATE.md').
        self.assertNotIn("'.aid/' + workId + '/STATE.md'", self.home,
                         "the old .aid/{workId}/STATE.md browser fallback must be gone (no dual path)")

    # -- home.html empty-state / help text (live feature-006 empty-state + steps) --
    def test_home_html_empty_state_references_works(self):
        self.assertIn("no AID works in .aid/works/", self.home,
                      "live empty-state text must reference .aid/works/ (AC-4)")

    def test_home_html_help_step_references_works(self):
        self.assertIn(".aid/works/work-NNN-", self.home,
                      "empty-state help steps must reference .aid/works/work-NNN- (AC-4)")

    def test_home_html_legacy_empty_state_markup_references_works(self):
        # The legacy/dead #empty-state markup (hidden by feature-006) is updated
        # for consistency: "No works found in .aid/works/".
        self.assertIn("No works found in <code>.aid/works/</code>", self.home,
                      "legacy #empty-state markup must reference .aid/works/ (AC-4)")

    # -- models.py caption / docstrings --
    def test_models_captions_reference_works(self):
        self.assertIn("One per .aid/works/work-NNN-*/ directory", self.models)
        self.assertIn(".aid/works/{work}/STATE.md", self.models)
        self.assertIn("one per .aid/works/work-NNN-*/ folder", self.models)

    def test_models_captions_old_form_gone(self):
        # Pre-fix captions named ".aid/work-NNN-*/" and ".aid/{work}/STATE.md".
        self.assertNotIn("One per .aid/work-NNN-*/ directory", self.models)
        self.assertNotIn("'.aid/{work}/STATE.md'", self.models)


if __name__ == "__main__":
    unittest.main(verbosity=2)
