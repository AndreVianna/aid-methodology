"""
test_task023_list_management_parity.py -- "List-management op round-trips +
parser parity" (task-023, feature-007-connectors-list / feature-010-external-
sources-list, delivery-003, work-017-cli-improvements) -- reader-twin leg.

This is a TEST-type task: NO production code is written here (that is tasks
018-021). dashboard/reader/tests/test_task019_connectors.py and
dashboard/reader/tests/test_task021_external_sources.py already prove
parse_connectors()/parseConnectors() and parse_external_sources()/
parseExternalSources() byte-identical across the Python and Node twins over
their OWN inline-string-literal fixture sets (three connector descriptors:
github/jira/minimal; one external-sources.md body per case) -- this file does
NOT duplicate that; it consumes this task's own COMMITTED FIXTURE FILES
(dashboard/server/tests/fixtures/pt023-connectors/ -- all FIVE connector types
incl. credentialed ssh/api/cli + mcp + auth-none url; dashboard/server/tests/
fixtures/pt023-external-sources/ -- placeholder-only/single-entry/multi-entry
states) that task-023's DETAIL explicitly calls for ("connector descriptors
across all five types incl. credentialed + mcp"; "an external-sources.md with
placeholder-only, single-entry, and multi-entry states"), which the FULL
five-type / three-state combination task-019/021's own inline literals never
exercised in one shared, reusable, on-disk set.

Fixture location note: the fixture DATA lives under dashboard/server/tests/
fixtures/ (the established "permanent test data" location per that
directory's own README.md) rather than a byte-for-byte duplicate copy under
dashboard/reader/tests/ -- this file cross-references into dashboard/server/
for shared assets, the identical precedent test_task019_connectors.py/
test_task021_external_sources.py already set for reader.mjs itself
(`_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"`).

Python 3.11+ stdlib only. No third-party deps. Requires `node` on PATH for the
cross-twin comparison (module SKIPS, not fails, if absent).
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

from dashboard.reader.parsers import parse_connectors, parse_external_sources
from dashboard.reader.models import ConnectorRef

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"
_FIXTURES_CONNECTORS = _REPO_ROOT / "dashboard" / "server" / "tests" / "fixtures" / "pt023-connectors"
_FIXTURES_EXTERNAL_SOURCES = _REPO_ROOT / "dashboard" / "server" / "tests" / "fixtures" / "pt023-external-sources"

_ALL_CONNECTOR_STEMS = ["build-host", "ci-runner", "github", "jira", "public-docs"]  # sort-by-stem order
_ALL_EXTERNAL_SOURCES_FIXTURES = ["placeholder-only.md", "single-entry.md", "multi-entry.md"]


def _node_available() -> bool:
    try:
        subprocess.run(["node", "--version"], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _run_node_parse_connectors(connectors_dir: Path) -> list:
    script = (
        f"import {{ parseConnectors }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const [refs] = parseConnectors({json.dumps(str(connectors_dir))});\n"
        "process.stdout.write(JSON.stringify(refs) + '\\n');\n"
    )
    result = subprocess.run(
        ["node", "--input-type=module"], input=script, capture_output=True, text=True, timeout=15,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Node reader.mjs script failed: {result.stderr[:500]}")
    return json.loads(result.stdout.strip())


def _run_node_parse_external_sources(kb_dir: Path) -> list:
    script = (
        f"import {{ parseExternalSources }} from {json.dumps(_READER_MJS.resolve().as_uri())};\n"
        f"const refs = parseExternalSources({json.dumps(str(kb_dir))});\n"
        "process.stdout.write(JSON.stringify(refs) + '\\n');\n"
    )
    result = subprocess.run(
        ["node", "--input-type=module"], input=script, capture_output=True, text=True, timeout=15,
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


# ===========================================================================
# Content-correctness anchors over the committed five-type golden fixture set
# (cheap, direct -- guards against the fixture files themselves drifting out
# of sync with what write-connector.sh actually produces; this task's own
# authoring confirmed byte-identity against a live write-connector.sh run for
# all five, see test_task023_list_management_round_trips.py's module docstring).
# ===========================================================================

class TestFiveConnectorTypesFixtureSetContent(unittest.TestCase):
    def test_enumeration_is_exactly_the_five_types_sorted_by_stem(self):
        refs, bytes_read = parse_connectors(_FIXTURES_CONNECTORS)
        self.assertEqual([r.stem for r in refs], _ALL_CONNECTOR_STEMS)
        self.assertGreater(bytes_read, 0)

    def test_mcp_type_auth_none_no_secret_reference(self):
        refs, _ = parse_connectors(_FIXTURES_CONNECTORS)
        ref = next(r for r in refs if r.stem == "github")
        self.assertEqual(ref.connection_type, "mcp")
        self.assertEqual(ref.auth_method, "none")
        self.assertIsNone(ref.secret_reference)

    def test_ssh_type_auth_forced_ssh_key_credentialed(self):
        refs, _ = parse_connectors(_FIXTURES_CONNECTORS)
        ref = next(r for r in refs if r.stem == "build-host")
        self.assertEqual(ref.connection_type, "ssh")
        self.assertEqual(ref.auth_method, "ssh-key")
        self.assertEqual(ref.secret_reference, "file:.aid/connectors/.secrets/build-host")

    def test_api_type_credentialed_with_default_secret_reference(self):
        refs, _ = parse_connectors(_FIXTURES_CONNECTORS)
        ref = next(r for r in refs if r.stem == "jira")
        self.assertEqual(ref.connection_type, "api")
        self.assertEqual(ref.auth_method, "token")
        self.assertEqual(ref.secret_reference, "file:.aid/connectors/.secrets/jira")

    def test_url_type_auth_none_no_secret_reference(self):
        refs, _ = parse_connectors(_FIXTURES_CONNECTORS)
        ref = next(r for r in refs if r.stem == "public-docs")
        self.assertEqual(ref.connection_type, "url")
        self.assertEqual(ref.auth_method, "none")
        self.assertIsNone(ref.secret_reference)

    def test_cli_type_credentialed_with_default_secret_reference(self):
        refs, _ = parse_connectors(_FIXTURES_CONNECTORS)
        ref = next(r for r in refs if r.stem == "ci-runner")
        self.assertEqual(ref.connection_type, "cli")
        self.assertEqual(ref.auth_method, "pat")
        self.assertEqual(ref.secret_reference, "file:.aid/connectors/.secrets/ci-runner")

    def test_no_secret_value_anywhere_in_parsed_output(self):
        refs, _ = parse_connectors(_FIXTURES_CONNECTORS)
        dumped = json.dumps([_connector_ref_to_dict(r) for r in refs])
        for marker in ("super-secret", "BEGIN PRIVATE KEY", "-----BEGIN"):
            self.assertNotIn(marker, dumped)


class TestExternalSourcesThreeStateFixtureSetContent(unittest.TestCase):
    def _kb_dir_for(self, fixture_name: str, tmp: Path) -> Path:
        kb_dir = tmp / "knowledge"
        kb_dir.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(_FIXTURES_EXTERNAL_SOURCES / fixture_name, kb_dir / "external-sources.md")
        return kb_dir

    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())

    def tearDown(self) -> None:
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    def test_placeholder_only_state_yields_empty_list(self):
        kb_dir = self._kb_dir_for("placeholder-only.md", self._tmp)
        self.assertEqual(parse_external_sources(kb_dir), [])

    def test_single_entry_state_yields_one_item(self):
        kb_dir = self._kb_dir_for("single-entry.md", self._tmp)
        self.assertEqual(parse_external_sources(kb_dir), ["https://vendor.example.com/api-spec"])

    def test_multi_entry_state_yields_three_items_in_order(self):
        kb_dir = self._kb_dir_for("multi-entry.md", self._tmp)
        self.assertEqual(
            parse_external_sources(kb_dir),
            ["https://vendor.example.com/api-spec", "https://vendor.example.com/pricing",
             "docs/vendor/onboarding.md"],
        )


# ===========================================================================
# Cross-twin parity over the shared golden fixture FILE sets (task-023's own
# fixture-file-based leg -- complements, does not duplicate, task-019's/
# task-021's own inline-literal parity tests).
# ===========================================================================

@unittest.skipUnless(_node_available(), "node not available on PATH")
class TestCrossTwinParityFiveConnectorTypesFixtureSet(unittest.TestCase):
    def test_five_connector_types_byte_identical(self):
        py_refs = [_connector_ref_to_dict(r) for r in parse_connectors(_FIXTURES_CONNECTORS)[0]]
        node_refs = _run_node_parse_connectors(_FIXTURES_CONNECTORS)

        py_json = json.dumps(py_refs, separators=(",", ":"), sort_keys=False)
        node_json = json.dumps(node_refs, separators=(",", ":"), sort_keys=False)
        self.assertEqual(
            py_json, node_json,
            f"parse_connectors/parseConnectors NOT byte-identical over the five-type fixture set:\n"
            f"  Python: {py_json}\n  Node:   {node_json}",
        )
        # Anchor: exactly five refs, sorted by stem -- a parity pass over an
        # accidentally-empty enumeration would be vacuous.
        self.assertEqual([r["stem"] for r in py_refs], _ALL_CONNECTOR_STEMS)


@unittest.skipUnless(_node_available(), "node not available on PATH")
class TestCrossTwinParityExternalSourcesThreeStateFixtureSet(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = Path(tempfile.mkdtemp())

    def tearDown(self) -> None:
        shutil.rmtree(str(self._tmp), ignore_errors=True)

    def _kb_dir_for(self, fixture_name: str) -> Path:
        kb_dir = self._tmp / fixture_name / "knowledge"
        kb_dir.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(_FIXTURES_EXTERNAL_SOURCES / fixture_name, kb_dir / "external-sources.md")
        return kb_dir

    def test_all_three_states_byte_identical(self):
        for fixture_name in _ALL_EXTERNAL_SOURCES_FIXTURES:
            with self.subTest(fixture=fixture_name):
                kb_dir = self._kb_dir_for(fixture_name)
                py_result = parse_external_sources(kb_dir)
                node_result = _run_node_parse_external_sources(kb_dir)
                py_json = json.dumps(py_result, separators=(",", ":"))
                node_json = json.dumps(node_result, separators=(",", ":"))
                self.assertEqual(
                    py_json, node_json,
                    f"parse_external_sources/parseExternalSources NOT byte-identical for "
                    f"{fixture_name}:\n  Python: {py_json}\n  Node:   {node_json}",
                )


if __name__ == "__main__":
    unittest.main(verbosity=2)
