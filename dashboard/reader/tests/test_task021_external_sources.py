"""
test_task021_external_sources.py -- work-017-cli-improvements,
feature-010-external-sources-list, delivery-003 task-021.

Covers the reader-twin half of task-021 (parse_external_sources wrapper +
RepoInfo.external_sources):
  - parse_external_sources: a THIN WRAPPER over the existing parity-tested
    parse_doc_frontmatter() -- no new frontmatter parser. Drops the discovery
    placeholder `(none)`, dedupes preserving first-seen order, and returns
    `[]` for an absent/frontmatter-less file (inherits parse_doc_frontmatter's
    own absent-file contract; no separate branch in the wrapper).
  - Reader-parity constraint (feature-010 SPEC): parse_doc_frontmatter's
    block-list continuation only matches CONTIGUOUS item lines -- a comment or
    blank line between `sources:` and its items ends the block. The wrapper
    inherits this boundary verbatim (it is NOT worked around here); a
    write-external-source.sh (task-020) round trip is asserted to produce
    exactly the normalized, reader-visible form.
  - RepoInfo.external_sources wiring via read_repo() (project-level).
  - Serialization: _ser_repo_info emits `external_sources` AFTER `connectors`;
    the DM-2 build_home_model() entry never carries an `external_sources` key
    (feature-010 scope: DM-1 only).
  - Cross-twin (Python parse_external_sources() vs Node parseExternalSources())
    byte parity over a shared fixture set, computed in-process via a bounded
    subprocess (no server, no port, no *parity*.sh script) -- mirrors
    test_task019_connectors.py's own "no server spawn" convention.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import read_repo
from dashboard.reader.parsers import parse_external_sources

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"
_WRITER_SH = _REPO_ROOT / "dashboard" / "scripts" / "write-external-source.sh"


def _bash_available() -> "str | None":
    """Resolve an ABSOLUTE bash.exe path via server.py's own _BASH_EXE resolver
    (never a bare "bash" argv[0] -- on Windows, CreateProcess consults
    System32 BEFORE the PATH env var and silently resolves a bare "bash" to
    the unusable WSL-launcher stub there, which hangs rather than erroring;
    see server.py _resolve_bash_exe's docstring). Returns the absolute path
    string on success, or None if bash is genuinely unavailable/broken.
    """
    try:
        from dashboard.server.server import _BASH_EXE
        subprocess.run([_BASH_EXE, "--version"], capture_output=True, check=True, timeout=10)
        return _BASH_EXE
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return None


_BASH_EXE_RESOLVED = _bash_available()


# ---------------------------------------------------------------------------
# Unit tests: parse_external_sources (thin wrapper over parse_doc_frontmatter)
# ---------------------------------------------------------------------------

class TestParseExternalSourcesWrapper(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.kb_dir = Path(self._tmp) / "knowledge"
        self.kb_dir.mkdir(parents=True, exist_ok=True)

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _write(self, content: str) -> None:
        (self.kb_dir / "external-sources.md").write_text(content, encoding="utf-8")

    def test_absent_file_yields_empty_list(self):
        self.assertEqual(parse_external_sources(self.kb_dir), [])

    def test_no_frontmatter_yields_empty_list(self):
        self._write("# External Sources\n\nNo frontmatter here.\n")
        self.assertEqual(parse_external_sources(self.kb_dir), [])

    def test_none_placeholder_dropped(self):
        self._write("---\nsources:\n  - (none)\n---\n")
        self.assertEqual(parse_external_sources(self.kb_dir), [])

    def test_block_list_entries_returned_in_order(self):
        self._write(
            "---\nsources:\n  - https://example.com/a\n  - path/to/b\n---\n"
        )
        self.assertEqual(
            parse_external_sources(self.kb_dir),
            ["https://example.com/a", "path/to/b"],
        )

    def test_dedupes_preserving_first_seen_order(self):
        self._write(
            "---\nsources:\n"
            "  - https://example.com/a\n"
            "  - path/to/b\n"
            "  - https://example.com/a\n"
            "---\n"
        )
        self.assertEqual(
            parse_external_sources(self.kb_dir),
            ["https://example.com/a", "path/to/b"],
        )

    def test_inline_list_form_supported(self):
        self._write("---\nsources: [https://example.com/a, path/to/b]\n---\n")
        self.assertEqual(
            parse_external_sources(self.kb_dir),
            ["https://example.com/a", "path/to/b"],
        )

    def test_empty_inline_list_yields_empty(self):
        self._write("---\nsources: []\n---\n")
        self.assertEqual(parse_external_sources(self.kb_dir), [])

    def test_comment_between_key_and_items_ends_block_known_boundary(self):
        """Reader-parity constraint (feature-010 SPEC): parse_doc_frontmatter's
        block-list continuation only matches CONTIGUOUS item lines -- a
        comment line between `sources:` and its items ends the block, so the
        real item is NOT surfaced. This is the documented parser boundary
        (not a bug this wrapper works around); write-external-source.sh
        (task-020) avoids it by normalizing to a contiguous block."""
        self._write(
            "---\nsources:\n"
            "# EXTERNAL DOCUMENTATION -- discovered during Q&A\n"
            "  - (none)\n"
            "---\n"
        )
        self.assertEqual(parse_external_sources(self.kb_dir), [])

    def test_never_raises_on_malformed_yaml(self):
        self._write("---\nsources: {not a list\n---\n")
        # Must not raise; parse_doc_frontmatter degrades gracefully.
        result = parse_external_sources(self.kb_dir)
        self.assertIsInstance(result, list)


# ---------------------------------------------------------------------------
# Reader-visibility round trip through the REAL write-external-source.sh
# writer (task-020) -- feature-010 AC2 / task-021 acceptance criterion.
# ---------------------------------------------------------------------------

@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available/resolvable")
class TestReaderVisibilityRoundTripWithRealWriter(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.kb_dir = Path(self._tmp) / "knowledge"
        self.kb_dir.mkdir(parents=True, exist_ok=True)
        self.ext_file = self.kb_dir / "external-sources.md"
        # Seed a realistic external-sources.md with the discovery placeholder,
        # including the interstitial "# EXTERNAL..." comment line the live
        # template carries (feature-010 SPEC: today parses to [] -- benign).
        self.ext_file.write_text(
            "---\nsources:\n"
            "# EXTERNAL DOCUMENTATION -- discovered during Q&A\n"
            "  - (none)\n"
            "---\n\n"
            "## Sources\n\n"
            "No external documentation was provided during discovery. All knowledge was "
            "derived from repository content only. If external documentation becomes "
            "available, re-run discovery or add paths during Q&A.\n"
        )

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _run_writer(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [_BASH_EXE_RESOLVED, str(_WRITER_SH), *args],
            capture_output=True, text=True, timeout=15,
        )

    def test_add_normalizes_block_and_is_reader_visible(self):
        proc = self._run_writer(
            "--op", "add", "--value", "https://example.com/doc",
            "--file", str(self.ext_file),
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        # Reader wrapper sees exactly the normalized entry -- the writer
        # dropped the placeholder AND the interstitial comment that would
        # otherwise have ended the block per the reader-parity constraint.
        self.assertEqual(
            parse_external_sources(self.kb_dir),
            ["https://example.com/doc"],
        )

    def test_multiple_adds_all_reader_visible_in_order(self):
        self._run_writer("--op", "add", "--value", "https://example.com/a", "--file", str(self.ext_file))
        self._run_writer("--op", "add", "--value", "path/to/b.md", "--file", str(self.ext_file))
        self.assertEqual(
            parse_external_sources(self.kb_dir),
            ["https://example.com/a", "path/to/b.md"],
        )

    def test_remove_then_reader_no_longer_sees_it(self):
        self._run_writer("--op", "add", "--value", "https://example.com/a", "--file", str(self.ext_file))
        self.assertEqual(parse_external_sources(self.kb_dir), ["https://example.com/a"])
        proc = self._run_writer("--op", "remove", "--value", "https://example.com/a", "--file", str(self.ext_file))
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(parse_external_sources(self.kb_dir), [])


# ---------------------------------------------------------------------------
# Unit tests: RepoInfo.external_sources wiring via read_repo()
# ---------------------------------------------------------------------------

def _make_repo(tmp: Path) -> "tuple[Path, Path]":
    root = tmp / "repo"
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    (aid / "settings.yml").write_text("project:\n  name: test-project\n", encoding="utf-8")
    return root, aid


class TestReadRepoExternalSourcesWiring(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_no_external_sources_file_yields_empty_list(self):
        model = read_repo(self.root)
        self.assertEqual(model.repo.external_sources, [])

    def test_external_sources_populated_and_deduped(self):
        kb_dir = self.aid / "knowledge"
        kb_dir.mkdir(parents=True, exist_ok=True)
        (kb_dir / "external-sources.md").write_text(
            "---\nsources:\n  - https://example.com/a\n  - https://example.com/a\n  - path/b\n---\n",
            encoding="utf-8",
        )
        model = read_repo(self.root)
        self.assertEqual(model.repo.external_sources, ["https://example.com/a", "path/b"])


# ---------------------------------------------------------------------------
# Unit tests: serialization (declared field order + DM-1-only exposure)
# ---------------------------------------------------------------------------

class TestExternalSourcesSerialization(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_ser_repo_info_carries_external_sources_after_connectors(self):
        from dashboard.server.server import _ser_repo_info
        model = read_repo(self.root)
        serialized = _ser_repo_info(model.repo)
        keys = list(serialized.keys())
        self.assertIn("connectors", keys)
        self.assertIn("external_sources", keys)
        self.assertLess(keys.index("connectors"), keys.index("external_sources"))

    def test_ser_repo_info_external_sources_is_plain_list(self):
        from dashboard.server.server import _ser_repo_info
        kb_dir = self.aid / "knowledge"
        kb_dir.mkdir(parents=True, exist_ok=True)
        (kb_dir / "external-sources.md").write_text(
            "---\nsources:\n  - https://example.com/a\n---\n", encoding="utf-8",
        )
        model = read_repo(self.root)
        serialized = _ser_repo_info(model.repo)
        self.assertEqual(serialized["external_sources"], ["https://example.com/a"])

    def test_home_model_entry_never_carries_external_sources_key(self):
        """DM-2 (/api/home) is explicitly out of scope for feature-010 --
        build_home_model's per-repo entry must never surface an
        'external_sources' key."""
        import uuid
        from dashboard.server.server import build_home_model
        aid_home = self.tmp / "aid_home"
        aid_home.mkdir(parents=True, exist_ok=True)
        reg_path = aid_home / "registry.yml"
        rid = uuid.uuid4().hex[:8]
        home_model = build_home_model(
            str(aid_home), reg_path, {rid: str(self.root)}, [], "test-runtime",
        )
        for entry in home_model["repos"]:
            self.assertNotIn("external_sources", entry)


# ---------------------------------------------------------------------------
# Cross-twin parity: Python parse_external_sources() vs Node
# parseExternalSources()
# ---------------------------------------------------------------------------

def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _run_node_parse_external_sources(kb_dir: Path) -> list:
    """Run reader.mjs's parseExternalSources() in a bounded, in-process (no
    server, no port) subprocess and return the resulting array."""
    script = (
        f"import {{ parseExternalSources }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const refs = parseExternalSources({json.dumps(str(kb_dir))});\n"
        "process.stdout.write(JSON.stringify(refs) + '\\n');\n"
    )
    result = subprocess.run(
        ["node", "--input-type=module"],
        input=script,
        capture_output=True,
        text=True,
        timeout=15,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:500]}")
    return json.loads(result.stdout.strip())


@unittest.skipUnless(_node_available(), "node not available on PATH")
class TestCrossTwinParityParseExternalSources(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.kb_dir = Path(self._tmp) / "knowledge"
        self.kb_dir.mkdir(parents=True, exist_ok=True)

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def _write(self, content: str) -> None:
        (self.kb_dir / "external-sources.md").write_text(content, encoding="utf-8")

    def test_shared_fixture_set_byte_identical(self):
        self._write(
            "---\nsources:\n"
            "  - https://example.com/a\n"
            "  - path/to/b\n"
            "  - https://example.com/a\n"
            "  - (none)\n"
            "---\n\n"
            "## Sources\n\nSome body text.\n"
        )
        py_result = parse_external_sources(self.kb_dir)
        node_result = _run_node_parse_external_sources(self.kb_dir)

        py_json = json.dumps(py_result, separators=(",", ":"))
        node_json = json.dumps(node_result, separators=(",", ":"))
        self.assertEqual(
            py_json, node_json,
            f"parse_external_sources/parseExternalSources NOT byte-identical:\n"
            f"  Python: {py_json}\n  Node:   {node_json}",
        )

    def test_missing_file_parity(self):
        py_result = parse_external_sources(self.kb_dir)
        node_result = _run_node_parse_external_sources(self.kb_dir)
        self.assertEqual(py_result, [])
        self.assertEqual(node_result, [])

    def test_only_placeholder_parity(self):
        self._write("---\nsources:\n  - (none)\n---\n")
        py_result = parse_external_sources(self.kb_dir)
        node_result = _run_node_parse_external_sources(self.kb_dir)
        self.assertEqual(py_result, [])
        self.assertEqual(node_result, [])


if __name__ == "__main__":
    unittest.main()
