"""
test_task019_connectors.py -- work-017-cli-improvements, feature-007-connectors-list,
delivery-003 task-019.

Covers the reader-twin half of task-019 (ConnectorRef + parse_connectors):
  - _parse_connector_frontmatter_scalars: single-line scalar extraction, ONE
    pair of surrounding quotes stripped, first-occurrence-wins, and a
    body-level thematic-break '---' is never re-entered as frontmatter (a
    decoy 'field: value' line after the closing fence is never read).
  - parse_connectors: the EXACT connector-registry.sh `list` filter (*.md,
    excluding INDEX.md + dotfiles, sorted by stem); missing dir -> [] (non-
    error); `name` defaults to stem when absent; connection_type is a raw,
    possibly-empty scalar; endpoint/auth_method/secret_reference/summary are
    None when absent.
  - RepoInfo.connectors wiring via read_repo() (project-level, sorted by stem).
  - Serialization: _ser_repo_info emits `connectors` AFTER `kb_state`, each
    ConnectorRef in declared field order; the DM-2 build_home_model() entry
    never carries a `connectors` key (feature-007 scope: DM-1 only).
  - Cross-twin (Python parse_connectors() vs Node parseConnectors()) byte
    parity over a shared fixture set, computed in-process via a bounded
    subprocess (no server, no port, no *parity*.sh script) -- mirrors
    test_task008_display_rename.py's / test_task044_freshness_parity.py's own
    "no server spawn" convention.

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
from dashboard.reader.models import ConnectorRef
from dashboard.reader.parsers import (
    _parse_connector_frontmatter_scalars,
    parse_connectors,
)

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"


# ---------------------------------------------------------------------------
# Unit tests: _parse_connector_frontmatter_scalars
# ---------------------------------------------------------------------------

class TestParseConnectorFrontmatterScalars(unittest.TestCase):
    def test_double_quoted_values_stripped(self):
        text = '---\nname: "Jira"\nconnection_type: api\n---\n\n# Jira\n'
        fm = _parse_connector_frontmatter_scalars(text)
        self.assertEqual(fm["name"], "Jira")
        self.assertEqual(fm["connection_type"], "api")

    def test_single_quoted_values_stripped(self):
        text = "---\nsummary: 'A single-quoted summary'\n---\n"
        fm = _parse_connector_frontmatter_scalars(text)
        self.assertEqual(fm["summary"], "A single-quoted summary")

    def test_unquoted_value_passes_through(self):
        text = "---\nconnection_type: mcp\nauth_method: none\n---\n"
        fm = _parse_connector_frontmatter_scalars(text)
        self.assertEqual(fm["connection_type"], "mcp")
        self.assertEqual(fm["auth_method"], "none")

    def test_absent_field_is_absent_from_dict(self):
        text = "---\nconnection_type: mcp\n---\n"
        fm = _parse_connector_frontmatter_scalars(text)
        self.assertNotIn("endpoint", fm)
        self.assertNotIn("secret_reference", fm)

    def test_no_frontmatter_yields_empty_dict(self):
        text = "# Just a heading\n\nno frontmatter here.\n"
        fm = _parse_connector_frontmatter_scalars(text)
        self.assertEqual(fm, {})

    def test_body_level_thematic_break_never_reenters_frontmatter(self):
        """A '---' inside the body (e.g. a second decoy frontmatter-looking
        block) must NEVER be read -- the scan stops at the closing fence."""
        text = (
            "---\n"
            "name: \"Real Name\"\n"
            "connection_type: cli\n"
            "---\n\n"
            "# Real Name\n\n"
            "---\n"
            "name: \"DECOY -- must not be read\"\n"
            "connection_type: decoy-type\n"
            "---\n"
        )
        fm = _parse_connector_frontmatter_scalars(text)
        self.assertEqual(fm["name"], "Real Name")
        self.assertEqual(fm["connection_type"], "cli")

    def test_first_occurrence_wins_for_duplicate_key(self):
        text = "---\nname: \"First\"\nname: \"Second\"\n---\n"
        fm = _parse_connector_frontmatter_scalars(text)
        self.assertEqual(fm["name"], "First")

    def test_never_raises_on_empty_text(self):
        self.assertEqual(_parse_connector_frontmatter_scalars(""), {})


# ---------------------------------------------------------------------------
# Unit tests: parse_connectors (enumeration filter + field extraction)
# ---------------------------------------------------------------------------

def _write_connector(connectors_dir: Path, filename: str, content: str) -> None:
    connectors_dir.mkdir(parents=True, exist_ok=True)
    (connectors_dir / filename).write_text(content, encoding="utf-8")


_GITHUB_MD = (
    "---\n"
    'name: "GitHub"\n'
    "connection_type: mcp\n"
    'endpoint: ""\n'
    "auth_method: none\n"
    "preset: custom\n"
    'objective: "Connect to GitHub via its host tool\'s own MCP/plugin."\n'
    'summary: "GitHub (mcp) -- request via the host tool\'s MCP/plugin."\n'
    "tags: [connector, mcp]\n"
    "audience: [developer, architect]\n"
    "---\n\n"
    "# GitHub\n"
)

_JIRA_MD = (
    "---\n"
    'name: "Jira"\n'
    "connection_type: api\n"
    'endpoint: "https://acme.atlassian.net/rest/api/3"\n'
    "auth_method: token\n"
    'secret_reference: "file:.aid/connectors/.secrets/jira"\n'
    "preset: custom\n"
    'objective: "Connect to Jira via api."\n'
    'summary: "Jira (api) -- auth: token."\n'
    "tags: [connector, api]\n"
    "audience: [developer, architect]\n"
    "---\n\n"
    "# Jira\n"
)

_MINIMAL_MD = (
    "---\n"
    "connection_type: mcp\n"
    "---\n"
)


class TestParseConnectorsEnumerationFilter(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.root = Path(self._tmp)
        self.connectors_dir = self.root / "connectors"

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_missing_dir_yields_empty_list_no_error(self):
        refs, bytes_read = parse_connectors(self.connectors_dir)
        self.assertEqual(refs, [])
        self.assertEqual(bytes_read, 0)

    def test_index_md_and_dotfiles_and_non_md_excluded(self):
        _write_connector(self.connectors_dir, "github.md", _GITHUB_MD)
        _write_connector(self.connectors_dir, "INDEX.md", "# Connectors Index\n")
        _write_connector(self.connectors_dir, ".gitignore", ".secrets/\n")
        _write_connector(self.connectors_dir, ".hidden.md", "---\nname: hidden\n---\n")
        _write_connector(self.connectors_dir, "notes.txt", "not a descriptor\n")
        refs, _ = parse_connectors(self.connectors_dir)
        stems = [r.stem for r in refs]
        self.assertEqual(stems, ["github"])

    def test_sorted_by_stem(self):
        _write_connector(self.connectors_dir, "zeta.md", _MINIMAL_MD)
        _write_connector(self.connectors_dir, "alpha.md", _MINIMAL_MD)
        _write_connector(self.connectors_dir, "mid.md", _MINIMAL_MD)
        refs, _ = parse_connectors(self.connectors_dir)
        self.assertEqual([r.stem for r in refs], ["alpha", "mid", "zeta"])

    def test_bytes_read_accumulates(self):
        _write_connector(self.connectors_dir, "github.md", _GITHUB_MD)
        _write_connector(self.connectors_dir, "jira.md", _JIRA_MD)
        refs, bytes_read = parse_connectors(self.connectors_dir)
        self.assertEqual(len(refs), 2)
        self.assertGreater(bytes_read, 0)


class TestParseConnectorsFieldExtraction(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.root = Path(self._tmp)
        self.connectors_dir = self.root / "connectors"

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_full_mcp_descriptor(self):
        _write_connector(self.connectors_dir, "github.md", _GITHUB_MD)
        refs, _ = parse_connectors(self.connectors_dir)
        self.assertEqual(len(refs), 1)
        ref = refs[0]
        self.assertIsInstance(ref, ConnectorRef)
        self.assertEqual(ref.stem, "github")
        self.assertEqual(ref.name, "GitHub")
        self.assertEqual(ref.connection_type, "mcp")
        # endpoint: "" -> falls back to None (empty scalar treated as absent)
        self.assertIsNone(ref.endpoint)
        self.assertEqual(ref.auth_method, "none")
        self.assertIsNone(ref.secret_reference)
        self.assertEqual(ref.summary, "GitHub (mcp) -- request via the host tool's MCP/plugin.")

    def test_full_api_descriptor_with_secret_reference(self):
        _write_connector(self.connectors_dir, "jira.md", _JIRA_MD)
        refs, _ = parse_connectors(self.connectors_dir)
        ref = refs[0]
        self.assertEqual(ref.name, "Jira")
        self.assertEqual(ref.connection_type, "api")
        self.assertEqual(ref.endpoint, "https://acme.atlassian.net/rest/api/3")
        self.assertEqual(ref.auth_method, "token")
        self.assertEqual(ref.secret_reference, "file:.aid/connectors/.secrets/jira")
        self.assertEqual(ref.summary, "Jira (api) -- auth: token.")

    def test_minimal_descriptor_name_defaults_to_stem(self):
        _write_connector(self.connectors_dir, "minimal.md", _MINIMAL_MD)
        refs, _ = parse_connectors(self.connectors_dir)
        ref = refs[0]
        self.assertEqual(ref.name, "minimal")
        self.assertEqual(ref.connection_type, "mcp")
        self.assertIsNone(ref.endpoint)
        self.assertIsNone(ref.auth_method)
        self.assertIsNone(ref.secret_reference)
        self.assertIsNone(ref.summary)

    def test_never_reads_secrets_directory(self):
        """Sanity: a .secrets/ sibling directory is never enumerated as a
        descriptor (it is not a *.md file at connectors_dir's top level)."""
        _write_connector(self.connectors_dir, "jira.md", _JIRA_MD)
        secrets_dir = self.connectors_dir / ".secrets"
        secrets_dir.mkdir(parents=True, exist_ok=True)
        (secrets_dir / "jira").write_text("super-secret-value", encoding="utf-8")
        refs, _ = parse_connectors(self.connectors_dir)
        self.assertEqual([r.stem for r in refs], ["jira"])
        # No field anywhere carries the raw secret text.
        self.assertNotIn("super-secret-value", json.dumps([r.__dict__ for r in refs]))


# ---------------------------------------------------------------------------
# Unit tests: RepoInfo.connectors wiring via read_repo()
# ---------------------------------------------------------------------------

def _make_repo(tmp: Path) -> "tuple[Path, Path]":
    root = tmp / "repo"
    aid = root / ".aid"
    aid.mkdir(parents=True, exist_ok=True)
    (aid / "settings.yml").write_text("project:\n  name: test-project\n", encoding="utf-8")
    return root, aid


class TestReadRepoConnectorsWiring(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_no_connectors_dir_yields_empty_list(self):
        model = read_repo(self.root)
        self.assertEqual(model.repo.connectors, [])

    def test_connectors_populated_and_sorted(self):
        connectors_dir = self.aid / "connectors"
        _write_connector(connectors_dir, "zeta.md", _MINIMAL_MD)
        _write_connector(connectors_dir, "github.md", _GITHUB_MD)
        model = read_repo(self.root)
        self.assertEqual([r.stem for r in model.repo.connectors], ["github", "zeta"])


# ---------------------------------------------------------------------------
# Unit tests: serialization (declared field order + DM-1-only exposure)
# ---------------------------------------------------------------------------

class TestConnectorSerialization(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.tmp = Path(self._tmp)
        self.root, self.aid = _make_repo(self.tmp)

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_ser_repo_info_carries_connectors_after_kb_state(self):
        from dashboard.server.server import _ser_repo_info
        model = read_repo(self.root)
        serialized = _ser_repo_info(model.repo)
        keys = list(serialized.keys())
        self.assertIn("kb_state", keys)
        self.assertIn("connectors", keys)
        self.assertLess(keys.index("kb_state"), keys.index("connectors"))

    def test_ser_connector_ref_declared_field_order(self):
        from dashboard.server.server import _ser_connector_ref
        _write_connector(self.aid / "connectors", "jira.md", _JIRA_MD)
        model = read_repo(self.root)
        ref = model.repo.connectors[0]
        serialized = _ser_connector_ref(ref)
        self.assertEqual(
            list(serialized.keys()),
            ["stem", "name", "connection_type", "endpoint", "auth_method",
             "secret_reference", "summary"],
        )

    def test_home_model_entry_never_carries_connectors_key(self):
        """DM-2 (/api/home) is explicitly out of scope for feature-007 --
        build_home_model's per-repo entry must never surface a 'connectors' key."""
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
            self.assertNotIn("connectors", entry)


# ---------------------------------------------------------------------------
# Cross-twin parity: Python parse_connectors() vs Node parseConnectors()
# ---------------------------------------------------------------------------

def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _run_node_parse_connectors(connectors_dir: Path) -> list:
    """Run reader.mjs's parseConnectors() in a bounded, in-process (no server,
    no port) subprocess and return the resulting array as plain dicts."""
    script = (
        f"import {{ parseConnectors }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const [refs] = parseConnectors({json.dumps(str(connectors_dir))});\n"
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


def _connector_ref_to_dict(ref: ConnectorRef) -> dict:
    return {
        "stem": ref.stem,
        "name": ref.name,
        "connection_type": ref.connection_type,
        "endpoint": ref.endpoint,
        "auth_method": ref.auth_method,
        "secret_reference": ref.secret_reference,
        "summary": ref.summary,
    }


@unittest.skipUnless(_node_available(), "node not available on PATH")
class TestCrossTwinParityParseConnectors(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.mkdtemp()
        self.connectors_dir = Path(self._tmp) / "connectors"

    def tearDown(self) -> None:
        shutil.rmtree(self._tmp, ignore_errors=True)

    def test_shared_fixture_set_byte_identical(self):
        _write_connector(self.connectors_dir, "github.md", _GITHUB_MD)
        _write_connector(self.connectors_dir, "jira.md", _JIRA_MD)
        _write_connector(self.connectors_dir, "minimal.md", _MINIMAL_MD)
        _write_connector(self.connectors_dir, "INDEX.md", "# Connectors Index\n")
        _write_connector(self.connectors_dir, ".hidden.md", "---\nname: hidden\n---\n")
        # Decoy body-level '---' block -- must never be re-entered as frontmatter.
        _write_connector(
            self.connectors_dir, "decoy.md",
            "---\nname: \"Decoy\"\nconnection_type: cli\n---\n\n"
            "# Decoy\n\n---\nname: \"SHOULD NOT BE READ\"\n---\n",
        )

        py_refs = [
            _connector_ref_to_dict(r) for r in parse_connectors(self.connectors_dir)[0]
        ]
        node_refs = _run_node_parse_connectors(self.connectors_dir)

        py_json = json.dumps(py_refs, separators=(",", ":"), sort_keys=False)
        node_json = json.dumps(node_refs, separators=(",", ":"), sort_keys=False)
        self.assertEqual(
            py_json, node_json,
            f"parse_connectors/parseConnectors NOT byte-identical:\n"
            f"  Python: {py_json}\n  Node:   {node_json}",
        )

    def test_missing_dir_parity(self):
        py_refs = parse_connectors(self.connectors_dir)[0]
        node_refs = _run_node_parse_connectors(self.connectors_dir)
        self.assertEqual(py_refs, [])
        self.assertEqual(node_refs, [])


if __name__ == "__main__":
    unittest.main()
