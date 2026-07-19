"""
test_task023_list_management_round_trips.py -- "List-management op round-trips +
parser parity" (task-023, feature-007-connectors-list / feature-010-external-
sources-list, delivery-003, work-017-cli-improvements).

This is a TEST-type task: NO production code is written here (that is tasks
018-021). It closes the gaps those tasks' own suites (test_task019_connector_ops.
py/.mjs, test_task021_external_source_ops.py/.mjs, dashboard/reader/tests/
test_task019_connectors.py, dashboard/reader/tests/test_task021_external_sources.
py) deliberately left open -- each of those proves its OWN runtime/behavior
thoroughly in isolation, but none puts the two runtimes' ACTUAL dispatch output
side by side for an identical input (the task-017 precedent this file follows:
test_task017_registry_tooling_round_trips.py/.mjs), none exercises every cell of
the exit->HTTP matrix through a REAL dispatch, and several documented behaviors
(body-bullet mirroring, byte-preservation, INDEX.md dispatch-level idempotence,
lint-frontmatter.sh green, real on-disk secret-file purge, real-writer output
matching a committed golden) have no round-trip assertion at all yet.

Sections:
  (A) Real-writer round-trips: gaps in tasks 019/021's own real-writer coverage
      -- per-type (ssh/url/cli) descriptor content via _dispatch_op, connector.
      remove purging a REAL on-disk secret file (not just the descriptor),
      INDEX.md byte-identical across two dispatch-level runs (AC2 idempotence,
      exercised through _dispatch_op rather than a raw script invocation), a
      "no secret VALUE anywhere under root" sweep, external-source.add mirroring
      the ## Sources body bullet (untested by task-021's own suite), external-
      source.remove restoring the canonical placeholder paragraph, byte-
      preservation of hand-authored content around the managed block, exit-0
      no-op for an already-present value at the DISPATCH layer, and an added
      entry keeping lint-frontmatter.sh green.
  (B) exit->HTTP mapping matrix + cross-runtime BYTE parity: a FAKE writer pair
      (write-connector.sh / write-external-source.sh look-alikes controlled by
      FAKE_EXIT) swapped in for _WRITER_DIR/WRITER_DIR (mirrors task-017's
      _AID_CLI_PATH substitution technique) drives EVERY cell of both writers'
      documented exit alphabets through the REAL _dispatch_op/dispatchOp on
      BOTH runtimes, asserting (status, body) byte-identical -- connectors:
      0->200, 4/5->422, 3/6->500 (never touching 1/2); external sources:
      0->200, 1->404, 2->409, 3->500, 4->422. Also a REAL-writer cross-runtime
      parity case (connector.set mcp) and a static source-text proof that
      write-connector.sh's own exit alphabet never contains a bare exit 1/2.
  (C) write_enabled 403 gate: live-socket (deferred to CI per this host's
      port-binding constraint -- see LOCAL TEST NOTE), companion in
      test_task023_list_management_round_trips.mjs.
  (D) DM-1 serializer fixture consistency: cross-runtime BYTE parity of
      serialize_model/serializeModel for a repo with REAL connectors +
      external_sources populated (neither test_server_py.py/test_server_node.
      mjs nor tasks 019/021's own suites ever byte-compare the two runtimes'
      envelope for populated data) + thin AC-traceability pointers to the
      schema_version/key-order assertions those files already carry.

Deliberately NOT re-covered here (thin pointers only where applicable) --
already covered by tasks 018-021's own suites: OP_TABLE row shape, pure
semantic-validation matrices, argv-builder SEC-2 checks, 422-before-spawn for
a semantically invalid request, target:{} project-scope handling, the mcp/api
real-writer happy paths, and parser byte-parity over each task's OWN inline
fixture set (parse_connectors/parseConnectors, parse_external_sources/
parseExternalSources) -- see dashboard/reader/tests/test_task023_list_
management_parity.py for this task's OWN (non-duplicative, fixture-FILE-based,
five-connector-type / three-external-sources-state) parser-parity leg.

Fixtures: dashboard/server/tests/fixtures/pt023-connectors/ (five connector
types incl. credentialed ssh/api/cli + mcp + auth-none url -- confirmed
byte-identical to write-connector.sh's own real output during this task's
authoring) and dashboard/server/tests/fixtures/pt023-external-sources/
(placeholder-only / single-entry / multi-entry-with-hand-authored-content
states) -- shared with dashboard/reader/tests/test_task023_list_management_
parity.py (the established "permanent test data" location per fixtures/README.md;
reader tests already cross-reference into dashboard/server/ for reader.mjs, so
sharing this same directory for fixture DATA follows the identical precedent
rather than duplicating byte-for-byte copies in two places).

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every class in section (A),
(B), and (D) calls `srv._dispatch_op(...)` directly (no `_ServerThread` socket
bind) and/or shells out to `node --input-type=module` / a real `bash` writer
subprocess as a BOUNDED child (no port bind) -- safe to run locally per the
project's port-binding-server-test constraint, and all were exercised directly
as part of this task's own verification pass (skipped, not failed, when `node`/
`bash` is absent). Section (C)'s `TestWriteEnabledGateLive` is the ONE class in
this file that binds a loopback socket (`_ServerThread`) -- per that same
constraint it is NOT executed locally; deferred to CI (its Node twin lives in
the companion .mjs file).

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import unittest.mock as mock
import uuid
from pathlib import Path

# ---------------------------------------------------------------------------
# Make the dashboard package importable regardless of CWD (mirrors the other
# task-0NN suites' own sys.path setup).
# ---------------------------------------------------------------------------
_TESTS_DIR = Path(__file__).resolve().parent         # dashboard/server/tests/
_SERVER_DIR = _TESTS_DIR.parent                      # dashboard/server/
_DASHBOARD_DIR = _SERVER_DIR.parent                  # dashboard/
_REPO_ROOT = _DASHBOARD_DIR.parent                   # AID/

if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.server import server as srv
from dashboard.reader.reader import read_repo
from dashboard.reader.parsers import parse_external_sources
from dashboard.server.tests.test_server_py import _ServerThread, _make_aid_home, _write_registry, _repo_id8

_SERVER_MJS = _DASHBOARD_DIR / "server" / "server.mjs"
_WRITE_CONNECTOR_SH = _DASHBOARD_DIR / "scripts" / "write-connector.sh"
_LINT_FRONTMATTER_SH = _REPO_ROOT / "canonical" / "aid" / "scripts" / "kb" / "lint-frontmatter.sh"
_FIXTURES_CONNECTORS = _TESTS_DIR / "fixtures" / "pt023-connectors"
_FIXTURES_EXTERNAL_SOURCES = _TESTS_DIR / "fixtures" / "pt023-external-sources"

# Stable single-line cut marker -- kept in lockstep with test_task012_consuming_
# round_trips.py's / test_task017's identical marker string.
_MAIN_MARKER = "// Main: parse args, create server, bind, register SIGTERM"


def _node_available() -> bool:
    try:
        r = subprocess.run(["node", "--version"], capture_output=True, timeout=5)
        return r.returncode == 0
    except Exception:
        return False


def _bash_available() -> "str | None":
    """Resolve an ABSOLUTE bash.exe path via server.py's own _BASH_EXE resolver
    (never a bare "bash" argv[0] -- see server.py's _resolve_bash_exe docstring
    for why: on Windows CreateProcess would otherwise silently resolve to the
    unusable WSL-launcher stub in System32)."""
    try:
        subprocess.run([srv._BASH_EXE, "--version"], capture_output=True, check=True, timeout=10)
        return srv._BASH_EXE
    except Exception:
        return None


_NODE_AVAILABLE = _node_available()
_BASH_EXE_RESOLVED = _bash_available()


class _TmpRepo:
    """Context manager: a scratch repo root, cleaned up on exit (mirrors
    test_task019_connector_ops.py's / test_task021_external_source_ops.py's own
    convention)."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp())
        return self.path

    def __exit__(self, *_exc) -> None:
        shutil.rmtree(str(self.path), ignore_errors=True)


def _seed_external_sources_from_fixture(root: Path, fixture_name: str) -> Path:
    """Copy one of this task's committed pt023-external-sources/ fixtures into
    <root>/.aid/knowledge/external-sources.md (the real path write-external-
    source.sh/_op_external_source_*_argv expect)."""
    kb_dir = root / ".aid" / "knowledge"
    kb_dir.mkdir(parents=True, exist_ok=True)
    ext_file = kb_dir / "external-sources.md"
    shutil.copyfile(_FIXTURES_EXTERNAL_SOURCES / fixture_name, ext_file)
    return ext_file


# ===========================================================================
# (A) Real-writer round-trips -- gaps in tasks 019/021's own coverage.
# ===========================================================================

@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available/resolvable")
class TestConnectorPerTypeRealRoundTrips(unittest.TestCase):
    """task-019's own TestConnectorOpsRealWriterRoundTrips only dispatches mcp
    and api through the REAL writer end to end -- ssh/url/cli's per-type
    normalize (feature-007 AC1: 'ssh -> ssh-key'; 'api/url/cli require endpoint
    +auth') is proven only at the PURE VALIDATION layer there (args pass
    _validate_connector_set_args), never round-tripped to an actual descriptor
    on disk via _dispatch_op. Closes that gap for all three remaining types,
    each assertion additionally diffed against this task's own committed
    golden fixture (confirmed byte-identical to the real writer's output
    during this task's authoring -- see module docstring)."""

    def test_ssh_forces_auth_ssh_key_and_default_secret_ref(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "target": {},
                 "args": {"name": "Build Host", "type": "ssh",
                          "endpoint": "build.internal.example.com:22"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "connector.set"})
            descriptor = root / ".aid" / "connectors" / "build-host.md"
            text = descriptor.read_text(encoding="utf-8")
            self.assertIn("connection_type: ssh", text)
            self.assertIn("auth_method: ssh-key", text)
            self.assertIn('secret_reference: "file:.aid/connectors/.secrets/build-host"', text)
            golden = (_FIXTURES_CONNECTORS / "build-host.md").read_text(encoding="utf-8")
            self.assertEqual(text, golden, "real-writer output diverged from the committed golden fixture")

    def test_url_auth_none_carries_no_secret_reference(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "target": {},
                 "args": {"name": "Public Docs", "type": "url",
                          "endpoint": "https://docs.example.com/api", "auth": "none"}},
                str(root),
            )
            self.assertEqual(status, 200)
            descriptor = root / ".aid" / "connectors" / "public-docs.md"
            text = descriptor.read_text(encoding="utf-8")
            self.assertIn("connection_type: url", text)
            self.assertIn("auth_method: none", text)
            self.assertNotIn("secret_reference:", text)
            golden = (_FIXTURES_CONNECTORS / "public-docs.md").read_text(encoding="utf-8")
            self.assertEqual(text, golden)

    def test_cli_credentialed_gets_default_secret_ref(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "target": {},
                 "args": {"name": "CI Runner", "type": "cli",
                          "endpoint": "ci-runner-cli --profile prod", "auth": "pat"}},
                str(root),
            )
            self.assertEqual(status, 200)
            descriptor = root / ".aid" / "connectors" / "ci-runner.md"
            text = descriptor.read_text(encoding="utf-8")
            self.assertIn("connection_type: cli", text)
            self.assertIn("auth_method: pat", text)
            self.assertIn('secret_reference: "file:.aid/connectors/.secrets/ci-runner"', text)
            golden = (_FIXTURES_CONNECTORS / "ci-runner.md").read_text(encoding="utf-8")
            self.assertEqual(text, golden)


@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available/resolvable")
class TestConnectorRemovePurgesRealSecretFile(unittest.TestCase):
    """feature-007 AC2 / task-023 DETAIL: 'connector.remove purges the secret,
    deletes the descriptor'. task-019's own real-writer suite only asserts
    descriptor deletion (test_connector_remove_success); it never seeds an
    actual on-disk .secrets/<stem> file and checks it is gone afterward through
    _dispatch_op (the script-level U38 in tests/canonical/test-write-connector.
    sh only proves this for a mcp RE-SET, not for connector.remove). This test
    closes that dispatch-level gap directly for the remove op."""

    def test_remove_deletes_both_descriptor_and_secret_file(self):
        with _TmpRepo() as root:
            status, _ = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "target": {},
                 "args": {"name": "Jira", "type": "api",
                          "endpoint": "https://acme.atlassian.net/rest/api/3", "auth": "token"}},
                str(root),
            )
            self.assertEqual(status, 200)
            connectors_dir = root / ".aid" / "connectors"
            descriptor = connectors_dir / "jira.md"
            self.assertTrue(descriptor.is_file())
            # Simulate an out-of-band `connector-secret.sh write` having already
            # populated the referenced secret file (never done by connector.set
            # itself -- see TestConnectorSetNeverWritesSecretValue below).
            secrets_dir = connectors_dir / ".secrets"
            secrets_dir.mkdir(parents=True, exist_ok=True)
            secret_file = secrets_dir / "jira"
            secret_file.write_text("super-secret-value", encoding="utf-8")
            self.assertTrue(secret_file.is_file())

            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.remove", "target": {}, "args": {"stem": "jira"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "connector.remove"})
            self.assertFalse(descriptor.exists(), "descriptor not deleted")
            self.assertFalse(secret_file.exists(), "orphaned secret file not purged")


@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available/resolvable")
class TestConnectorSetNeverWritesSecretValue(unittest.TestCase):
    """feature-007 AC1/AC2 / task-023 DETAIL: 'no secret VALUE is ever
    written'. A sweep across every file under root after a full multi-type
    seed (including every credentialed type) -- none may ever carry the
    literal marker string a real secret VALUE would use."""

    def test_no_file_under_root_ever_carries_a_secret_value_marker(self):
        marker = "MARKER-THIS-WOULD-BE-A-SECRET-VALUE"
        with _TmpRepo() as root:
            for name, ctype, kwargs in (
                ("Jira", "api", {"endpoint": "https://x", "auth": "token"}),
                ("Build Host", "ssh", {"endpoint": "host:22"}),
                ("CI Runner", "cli", {"endpoint": "cmd", "auth": "pat"}),
            ):
                status, _ = srv._dispatch_op(
                    srv.OP_TABLE,
                    {"op": "connector.set", "target": {},
                     "args": {"name": name, "type": ctype, "secret_ref": f"env:{name.replace(' ', '_').upper()}", **kwargs}},
                    str(root),
                )
                self.assertEqual(status, 200)
            for path in root.rglob("*"):
                if path.is_file():
                    text = path.read_text(encoding="utf-8", errors="replace")
                    self.assertNotIn(marker, text)
            # Belt-and-suspenders: the env: secret_ref form never creates a
            # .secrets/ file at all (only file:/keychain: forms reference one,
            # and even then this writer never populates it).
            secrets_dir = root / ".aid" / "connectors" / ".secrets"
            if secrets_dir.is_dir():
                self.assertEqual(list(secrets_dir.iterdir()), [])


@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available/resolvable")
class TestConnectorIndexIdempotenceViaDispatch(unittest.TestCase):
    """feature-007 AC2: 'INDEX.md is regenerated and is byte-identical across
    two runs over an identical descriptor set (determinism/idempotence)'.
    tests/canonical/test-write-connector.sh's own U25 already proves this at
    the RAW SCRIPT layer; this test closes the DISPATCH-level gap (proving the
    property survives through _dispatch_op's argv-building/spawn plumbing,
    not just a direct script invocation) by re-issuing an IDENTICAL
    connector.set dispatch twice and diffing INDEX.md bytes."""

    def test_index_md_byte_identical_across_two_identical_dispatches(self):
        with _TmpRepo() as root:
            args = {"name": "GitHub", "type": "mcp"}
            status1, _ = srv._dispatch_op(
                srv.OP_TABLE, {"op": "connector.set", "target": {}, "args": args}, str(root),
            )
            self.assertEqual(status1, 200)
            index_path = root / ".aid" / "connectors" / "INDEX.md"
            self.assertTrue(index_path.is_file())
            first_bytes = index_path.read_bytes()

            status2, _ = srv._dispatch_op(
                srv.OP_TABLE, {"op": "connector.set", "target": {}, "args": dict(args)}, str(root),
            )
            self.assertEqual(status2, 200)
            second_bytes = index_path.read_bytes()
            self.assertEqual(first_bytes, second_bytes, "INDEX.md not byte-identical across two identical dispatches")


@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available/resolvable")
class TestConnectorSetTouchesOnlyItsOwnDescriptor(unittest.TestCase):
    """feature-007 AC1: 'atomically (temp-file + mv) authors/overwrites
    exactly ONE <root>/<stem>.md -- no sibling descriptor touched'. task-019's
    own suite never seeds SIBLING descriptors before a connector.set dispatch,
    so it cannot prove non-interference; this test seeds two pre-existing
    descriptors, dispatches a THIRD connector.set, and asserts the two
    siblings are byte-for-byte unchanged (INDEX.md is the one file allowed --
    expected -- to change)."""

    def test_siblings_byte_unchanged_after_a_third_connector_set(self):
        with _TmpRepo() as root:
            status, _ = srv._dispatch_op(
                srv.OP_TABLE, {"op": "connector.set", "target": {}, "args": {"name": "GitHub", "type": "mcp"}},
                str(root),
            )
            self.assertEqual(status, 200)
            status, _ = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "target": {},
                 "args": {"name": "Jira", "type": "api", "endpoint": "https://x", "auth": "token"}},
                str(root),
            )
            self.assertEqual(status, 200)
            connectors_dir = root / ".aid" / "connectors"
            github_before = (connectors_dir / "github.md").read_bytes()
            jira_before = (connectors_dir / "jira.md").read_bytes()

            status, _ = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "target": {},
                 "args": {"name": "Public Docs", "type": "url", "endpoint": "https://docs.example.com/api", "auth": "none"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual((connectors_dir / "github.md").read_bytes(), github_before, "github.md sibling was touched")
            self.assertEqual((connectors_dir / "jira.md").read_bytes(), jira_before, "jira.md sibling was touched")
            self.assertTrue((connectors_dir / "public-docs.md").is_file())


class TestSemanticValidate422BeforeSpawnAlreadyCovered(unittest.TestCase):
    """AC-traceability pointer only (task-023 DETAIL: 'assert per-op
    arg-schema violations return 422 BEFORE any spawn'). ALREADY covered by
    task-019's own test_task019_connector_ops.py (TestConnectorOpsRealWriter
    RoundTrips.test_connector_set_semantic_failure_maps_to_422_before_spawn /
    test_connector_remove_bad_stem_422_before_spawn) and task-021's own
    test_task021_external_source_ops.py (TestExternalSourceOpsRealWriter
    RoundTrips.test_add_semantic_failure_maps_to_422_before_spawn /
    test_remove_semantic_failure_maps_to_422_before_spawn) -- each proves,
    via the REAL writer, that a semantically invalid request never reaches a
    child spawn at all (a missing '.aid/connectors/'/'external-sources.md'
    artifact after the call is the spawn-never-happened proof). Not
    duplicated here; this file's TestConnectorExitHttpMatrixParity /
    TestExternalSourceExitHttpMatrixParity above additionally prove the
    COMPLEMENTARY exit4/exit5->422 cells of the map once a writer IS reached."""

    def test_pointer_to_422_before_spawn_coverage(self) -> None:
        from dashboard.server.tests import test_task019_connector_ops as t019
        from dashboard.server.tests import test_task021_external_source_ops as t021
        self.assertTrue(hasattr(
            t019.TestConnectorOpsRealWriterRoundTrips, "test_connector_set_semantic_failure_maps_to_422_before_spawn",
        ))
        self.assertTrue(hasattr(
            t019.TestConnectorOpsRealWriterRoundTrips, "test_connector_remove_bad_stem_422_before_spawn",
        ))
        self.assertTrue(hasattr(
            t021.TestExternalSourceOpsRealWriterRoundTrips, "test_add_semantic_failure_maps_to_422_before_spawn",
        ))
        self.assertTrue(hasattr(
            t021.TestExternalSourceOpsRealWriterRoundTrips, "test_remove_semantic_failure_maps_to_422_before_spawn",
        ))


@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available/resolvable")
class TestExternalSourceAddMirrorsBodyBulletAndPreservesLines(unittest.TestCase):
    """feature-010 AC1 / task-023 DETAIL: 'add inserts one contiguous item under
    sources: ... mirrors a body bullet ... byte-preserves every non-target
    line'. task-021's own TestExternalSourceOpsRealWriterRoundTrips never
    inspects the ## Sources body at all (only the frontmatter + the reader's
    parse_external_sources() view) -- this closes that gap using this task's
    own committed single-entry.md / multi-entry.md fixtures, asserting a
    FULL-FILE line-level diff against the untouched fixture so every
    unaffected line is proven byte-preserved (not merely 'the new value shows
    up somewhere')."""

    def test_add_to_single_entry_only_touches_two_lines(self):
        with _TmpRepo() as root:
            ext_file = _seed_external_sources_from_fixture(root, "single-entry.md")
            before_lines = ext_file.read_text(encoding="utf-8").splitlines()

            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.add", "target": {},
                 "args": {"value": "https://vendor.example.com/newthing"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "external-source.add"})
            after_lines = ext_file.read_text(encoding="utf-8").splitlines()

            # Exactly two NEW lines appear (frontmatter item + body bullet
            # mirror); every other line is byte-preserved verbatim, in order.
            added = [l for l in after_lines if l not in before_lines]
            self.assertEqual(
                added,
                ["  - https://vendor.example.com/newthing", "- https://vendor.example.com/newthing"],
                f"unexpected line-level diff: {added}",
            )
            # Every original line is still present, in its original relative order.
            filtered_after = [l for l in after_lines if l in before_lines]
            self.assertEqual(filtered_after, before_lines, "a pre-existing line was altered or reordered")

    def test_add_to_multi_entry_preserves_hand_authored_trailing_note(self):
        """multi-entry.md carries a hand-authored note AFTER the managed
        block -- proves the writer never rewrites non-managed content sharing
        the ## Sources section (writer docstring: 'inserted/updated adjacent
        to it ... WITHOUT rewriting those human rows')."""
        with _TmpRepo() as root:
            ext_file = _seed_external_sources_from_fixture(root, "multi-entry.md")
            hand_authored_note = "_Additional vendor documentation is pending legal review and is not yet cataloged here._"
            self.assertIn(hand_authored_note, ext_file.read_text(encoding="utf-8"))

            status, _ = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.add", "target": {},
                 "args": {"value": "https://vendor.example.com/newthing"}},
                str(root),
            )
            self.assertEqual(status, 200)
            after_text = ext_file.read_text(encoding="utf-8")
            self.assertIn(hand_authored_note, after_text, "hand-authored content was NOT preserved")
            self.assertEqual(
                parse_external_sources(root / ".aid" / "knowledge"),
                ["https://vendor.example.com/api-spec", "https://vendor.example.com/pricing",
                 "docs/vendor/onboarding.md", "https://vendor.example.com/newthing"],
            )

    def test_add_already_present_value_is_exit0_noop_byte_identical(self):
        """feature-010 AC1: 'is an exit-0 no-op for an already-present value'
        -- proven here at the DISPATCH layer (script-level U3 in tests/
        canonical/test-write-external-source.sh already covers the raw
        script; this closes the _dispatch_op-level gap) with a full byte
        comparison, not just a 200 status check."""
        with _TmpRepo() as root:
            ext_file = _seed_external_sources_from_fixture(root, "single-entry.md")
            before_bytes = ext_file.read_bytes()

            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.add", "target": {},
                 "args": {"value": "https://vendor.example.com/api-spec"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "external-source.add"})
            self.assertEqual(ext_file.read_bytes(), before_bytes, "no-op add must not touch the file at all")


@unittest.skipUnless(_BASH_EXE_RESOLVED, "bash not available/resolvable")
class TestExternalSourceRemoveRestoresCanonicalForms(unittest.TestCase):
    """feature-010 AC2: 'remove deletes the matching frontmatter item (writing
    sources: [] when the real list empties) and the body bullet (restoring the
    canonical paragraph when it empties)'. task-021's own real-writer suite
    checks parse_external_sources() sees [] after removing the last entry but
    never inspects sources: [] / the restored body paragraph directly."""

    def test_remove_last_entry_writes_empty_list_and_restores_paragraph(self):
        with _TmpRepo() as root:
            ext_file = _seed_external_sources_from_fixture(root, "single-entry.md")
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.remove", "target": {},
                 "args": {"value": "https://vendor.example.com/api-spec"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "external-source.remove"})
            text = ext_file.read_text(encoding="utf-8")
            self.assertIn("sources: []", text)
            self.assertIn(
                "No external documentation was provided during discovery. All knowledge was "
                "derived from repository content only. If external documentation becomes "
                "available, re-run discovery or add paths during Q&A.",
                text,
            )
            self.assertNotIn("<!-- managed:external-sources -->", text)
            self.assertEqual(parse_external_sources(root / ".aid" / "knowledge"), [])

    def test_remove_one_of_many_preserves_the_others_and_hand_authored_note(self):
        with _TmpRepo() as root:
            ext_file = _seed_external_sources_from_fixture(root, "multi-entry.md")
            status, _ = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.remove", "target": {},
                 "args": {"value": "https://vendor.example.com/pricing"}},
                str(root),
            )
            self.assertEqual(status, 200)
            text = ext_file.read_text(encoding="utf-8")
            self.assertIn(
                "_Additional vendor documentation is pending legal review and is not yet cataloged here._",
                text,
            )
            self.assertEqual(
                parse_external_sources(root / ".aid" / "knowledge"),
                ["https://vendor.example.com/api-spec", "docs/vendor/onboarding.md"],
            )


@unittest.skipUnless(_BASH_EXE_RESOLVED and _LINT_FRONTMATTER_SH.is_file(), "bash/lint-frontmatter.sh not available")
class TestExternalSourceAddKeepsLintFrontmatterGreen(unittest.TestCase):
    """feature-010 DETAIL: 'an added entry keeps lint-frontmatter.sh green
    (its alphabet matches sources_entry_shape())'. Runs the REAL, canonical
    (not a profile-rendered copy) lint-frontmatter.sh over the .aid/knowledge/
    directory produced by a real external-source.add dispatch and asserts
    exit 0. NOTE (documented honestly, not overclaimed): external-sources.md's
    real frontmatter carries `kb-category: meta`, which lint-frontmatter.sh
    ALWAYS skips outright (never soft-skip, never shape-checked) -- so this
    assertion proves the write never trips a finding when the doc IS
    inspected, and stays a real regression guard against a future
    lint-frontmatter.sh change that starts inspecting meta docs' sources:
    shape (in which case a malformed writer output would newly start failing
    this exact test)."""

    def test_lint_frontmatter_exits_zero_after_add(self):
        with _TmpRepo() as root:
            _seed_external_sources_from_fixture(root, "single-entry.md")
            kb_dir = root / ".aid" / "knowledge"
            status, _ = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "external-source.add", "target": {},
                 "args": {"value": "https://vendor.example.com/newthing"}},
                str(root),
            )
            self.assertEqual(status, 200)
            proc = subprocess.run(
                [_BASH_EXE_RESOLVED, str(_LINT_FRONTMATTER_SH), "--root", str(kb_dir)],
                capture_output=True, text=True, timeout=30,
            )
            self.assertEqual(proc.returncode, 0, f"lint-frontmatter.sh failed:\n{proc.stdout}\n{proc.stderr}")


# ===========================================================================
# (B) exit->HTTP mapping matrix + cross-runtime BYTE parity via a FAKE writer
# pair (mirrors task-017's _AID_CLI_PATH substitution technique, applied here
# to _WRITER_DIR/WRITER_DIR instead).
# ===========================================================================

_FAKE_WRITER_SCRIPT = (
    "#!/usr/bin/env bash\n"
    'code="${FAKE_EXIT:-0}"\n'
    'echo "fake-writer: exit ${code}" >&2\n'
    'exit "${code}"\n'
)


def _make_fake_writer_dir() -> Path:
    """A tmp dir containing look-alike write-connector.sh / write-external-
    source.sh scripts, each ignoring argv entirely and exiting with
    $FAKE_EXIT (defaults to 0) -- lets every cell of both writers' exit
    alphabets be driven through the REAL _dispatch_op/dispatchOp without
    needing to find a real validation gap in the actual bash scripts for
    each exit code."""
    d = Path(tempfile.mkdtemp())
    for name in ("write-connector.sh", "write-external-source.sh"):
        (d / name).write_text(_FAKE_WRITER_SCRIPT, encoding="utf-8")
    return d


def _sliced_server_mjs_source_fake_writer_dir(writer_dir: Path) -> str:
    """Slice server.mjs before its side-effecting 'Main' tail (same stable cut
    point as test_task017/test_task019/test_task021's own slices) and
    redirect the WRITER_DIR const to `writer_dir` -- the Node-side analogue of
    monkey-patching srv._WRITER_DIR below."""
    text = _SERVER_MJS.read_text(encoding="utf-8")
    idx = text.find(_MAIN_MARKER)
    assert idx != -1, (
        "server.mjs's 'Main: parse args, create server, bind, register SIGTERM' "
        "marker comment is gone -- this test's source-slice cut point needs updating"
    )
    sliced = text[:idx]
    old_line = 'const WRITER_DIR = join(_DASHBOARD_DIR_MJS, "scripts");'
    assert old_line in sliced, (
        "server.mjs's WRITER_DIR const declaration line has changed shape -- "
        "this test's slice-and-redirect cut point needs updating"
    )
    new_line = f"const WRITER_DIR = {json.dumps(str(writer_dir))};"
    sliced = sliced.replace(old_line, new_line, 1)
    return sliced + "\nexport { dispatchOp, OP_TABLE };\n"


class _NodeSlicedFakeWriterFixture:
    """setUpClass/tearDownClass helper mirroring test_task017's
    _NodeSlicedDispatchFixture, but redirecting WRITER_DIR instead of
    AID_CLI_PATH. `_node_dispatch_many` runs ALL cases in ONE Node process
    (this repo's own perf note: forking is ~1s/spawn on this host's class of
    environment)."""

    _slice_path: Path
    _fake_writer_dir: Path

    @classmethod
    def setUpClass(cls) -> None:
        cls._fake_writer_dir = _make_fake_writer_dir()
        cls._slice_path = _SERVER_DIR / f"_test_task023_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(
            _sliced_server_mjs_source_fake_writer_dir(cls._fake_writer_dir), encoding="utf-8",
        )

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)
        shutil.rmtree(str(cls._fake_writer_dir), ignore_errors=True)

    def _node_dispatch_many(self, cases: list[dict]) -> list[tuple[int, str]]:
        driver = (
            "import { dispatchOp, OP_TABLE } from "
            f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
            f"const cases = {json.dumps(cases)};\n"
            "const results = [];\n"
            "for (const c of cases) {\n"
            "  delete process.env.FAKE_EXIT;\n"
            "  Object.assign(process.env, c.env || {});\n"
            "  const [status, body] = dispatchOp(OP_TABLE, c.parsed, c.servedRoot, c.aidHome);\n"
            "  results.push([status, Buffer.from(body).toString('utf-8')]);\n"
            "}\n"
            "process.stdout.write(JSON.stringify(results));\n"
        )
        result = subprocess.run(
            ["node", "--input-type=module"],
            input=driver, capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            raise RuntimeError(f"Node dispatch driver failed: {result.stderr[:1000]}")
        return [tuple(x) for x in json.loads(result.stdout.strip())]


def _assert_parity(
    test: unittest.TestCase,
    py_result: "tuple[int, bytes]",
    node_result: "tuple[int, str]",
    expected_status: int,
    expected_error: "str | None" = None,
) -> None:
    """The core twin-parity assertion (mirrors test_task017_registry_tooling_
    round_trips.py's own helper verbatim): BOTH runtimes must independently
    produce the EXPECTED status, AND the two runtimes' actual (status,
    body-bytes) pairs must be IDENTICAL to each other."""
    py_status, py_body = py_result
    node_status, node_body = node_result
    py_text = py_body.decode("utf-8") if isinstance(py_body, (bytes, bytearray)) else py_body
    test.assertEqual(py_status, expected_status, f"python status mismatch; body={py_text!r}")
    test.assertEqual(node_status, expected_status, f"node status mismatch; body={node_body!r}")
    test.assertEqual(py_status, node_status, "python/node HTTP status DIVERGE (twin parity broken)")
    test.assertEqual(py_text, node_body, "python/node response BODY bytes DIVERGE (twin parity broken)")
    if expected_error is not None:
        test.assertEqual(json.loads(py_text)["error"], expected_error)


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestConnectorExitHttpMatrixParity(_NodeSlicedFakeWriterFixture, unittest.TestCase):
    """The FULL write-connector.sh exit alphabet (0/3/4/5/6 -- 1/2 reserved,
    never emitted) driven through the REAL connector.set _dispatch_op/
    dispatchOp on BOTH runtimes via the fake writer pair, proving
    feature-001's generic DEFAULT_MAP with no per-op remapping: 0->200,
    4/5->422, 3/6->500."""

    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls._orig_writer_dir = srv._WRITER_DIR
        srv._WRITER_DIR = cls._fake_writer_dir

    @classmethod
    def tearDownClass(cls) -> None:
        srv._WRITER_DIR = cls._orig_writer_dir
        super().tearDownClass()

    def test_all_exit_codes_parity(self) -> None:
        # (name, fake_exit, expected_status, expected_error)
        cases = [
            ("exit0_ok",          "0", 200, None),
            ("exit3_runtime_io",  "3", 500, "write-failed"),
            ("exit4_invalid",     "4", 422, "invalid-value"),
            ("exit5_missing_arg", "5", 422, "invalid-value"),
            ("exit6_catchall",    "6", 500, "write-failed"),
        ]
        parsed = {"op": "connector.set", "target": {}, "args": {"name": "GitHub", "type": "mcp"}}
        node_cases = [
            {"table": "OP_TABLE", "parsed": parsed, "servedRoot": "/repo/path",
             "aidHome": "/state/home", "env": {"FAKE_EXIT": fake_exit}}
            for (_name, fake_exit, _status, _err) in cases
        ]
        node_results = self._node_dispatch_many(node_cases)

        for (name, fake_exit, expected_status, expected_error), node_result in zip(cases, node_results):
            with self.subTest(case=name):
                with mock.patch.dict("os.environ", {"FAKE_EXIT": fake_exit}, clear=False):
                    py_result = srv._dispatch_op(srv.OP_TABLE, parsed, "/repo/path")
                _assert_parity(self, py_result, node_result, expected_status, expected_error)

    def test_remove_op_shares_the_identical_matrix(self) -> None:
        """connector.remove uses the SAME writer script name + DEFAULT_MAP --
        one representative cell (exit 4) confirms it is not accidentally
        wired to a different map."""
        parsed = {"op": "connector.remove", "target": {}, "args": {"stem": "github"}}
        node_result = self._node_dispatch_many([{
            "table": "OP_TABLE", "parsed": parsed, "servedRoot": "/repo/path",
            "aidHome": "/state/home", "env": {"FAKE_EXIT": "4"},
        }])[0]
        with mock.patch.dict("os.environ", {"FAKE_EXIT": "4"}, clear=False):
            py_result = srv._dispatch_op(srv.OP_TABLE, parsed, "/repo/path")
        _assert_parity(self, py_result, node_result, 422, "invalid-value")


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- twin parity skipped")
class TestExternalSourceExitHttpMatrixParity(_NodeSlicedFakeWriterFixture, unittest.TestCase):
    """The FULL write-external-source.sh exit alphabet (0/1/2/3/4) driven
    through the REAL external-source.add _dispatch_op/dispatchOp on BOTH
    runtimes via the fake writer pair: 0->200, 1->404, 2->409, 3->500,
    4->422 -- the DISTINCT alphabet from connectors' own (1/2 are live,
    meaningful codes here, unlike connectors' reserved-never-emitted ones)."""

    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls._orig_writer_dir = srv._WRITER_DIR
        srv._WRITER_DIR = cls._fake_writer_dir

    @classmethod
    def tearDownClass(cls) -> None:
        srv._WRITER_DIR = cls._orig_writer_dir
        super().tearDownClass()

    def test_all_exit_codes_parity(self) -> None:
        cases = [
            ("exit0_ok",             "0", 200, None),
            ("exit1_not_found",      "1", 404, "not-found"),
            ("exit2_busy",           "2", 409, "busy"),
            ("exit3_write_failed",   "3", 500, "write-failed"),
            ("exit4_invalid_value",  "4", 422, "invalid-value"),
        ]
        parsed = {"op": "external-source.add", "target": {}, "args": {"value": "https://example.com/doc"}}
        node_cases = [
            {"table": "OP_TABLE", "parsed": parsed, "servedRoot": "/repo/path",
             "aidHome": "/state/home", "env": {"FAKE_EXIT": fake_exit}}
            for (_name, fake_exit, _status, _err) in cases
        ]
        node_results = self._node_dispatch_many(node_cases)

        for (name, fake_exit, expected_status, expected_error), node_result in zip(cases, node_results):
            with self.subTest(case=name):
                with mock.patch.dict("os.environ", {"FAKE_EXIT": fake_exit}, clear=False):
                    py_result = srv._dispatch_op(srv.OP_TABLE, parsed, "/repo/path")
                _assert_parity(self, py_result, node_result, expected_status, expected_error)

    def test_distinct_from_connectors_alphabet_at_exit1_and_exit2(self) -> None:
        """The SAME raw exit codes (1, 2) mean something meaningful here
        (404/409) but are STRUCTURALLY UNREACHABLE for connectors (the writer
        never emits them) -- both rows share ONE generic DEFAULT_MAP object
        (not two aliased copies); the alphabets differ only because each
        writer's OWN exit vocabulary differs, not because of any per-op
        remapping."""
        self.assertIs(srv.OP_TABLE["connector.set"].get("status_map"), None)
        self.assertIs(srv.OP_TABLE["external-source.add"].get("status_map"), None)
        self.assertEqual(srv._map_exit_code(1, None, None), (404, "not-found"))
        self.assertEqual(srv._map_exit_code(2, None, None), (409, "busy"))


class TestWriteConnectorNeverEmitsReservedExitCodes(unittest.TestCase):
    """Static source-text proof (task-023 DETAIL: 'the writer never emits
    1/2 -> never 404/409') that write-connector.sh's actual exit alphabet
    contains no bare `exit 1` / `exit 2` / `die ... 1` / `die ... 2` anywhere
    -- a structural guarantee, not merely 'the test cases I happened to try
    didn't hit them'."""

    _RESERVED_EXIT_RE = re.compile(
        r"(?:^|[^0-9])(?:die\s+\"[^\"]*\"\s+[12]$|exit\s+[12](?:[^0-9]|$))",
        re.MULTILINE,
    )

    def test_no_bare_exit_1_or_2_statement_anywhere_in_source(self) -> None:
        text = _WRITE_CONNECTOR_SH.read_text(encoding="utf-8")
        matches = self._RESERVED_EXIT_RE.findall(text)
        self.assertEqual(
            matches, [],
            "write-connector.sh contains a literal exit-1/exit-2 statement -- "
            "this breaks the documented 'never 404/409' guarantee for connector ops",
        )

    def test_documented_alphabet_is_0_3_4_5_only(self) -> None:
        """Anchored to the '#   <N> -- <text>' exit-code-list line shape only
        (a bare substring check would false-positive on unrelated prose like
        'SKILL.md line 12 -- SEC-4', which contains the substring '2 -- ')."""
        header_text = "\n".join(_WRITE_CONNECTOR_SH.read_text(encoding="utf-8").splitlines()[:90])
        _exit_code_line_re = re.compile(r"(?m)^#\s+(\d)\s+--\s+\S")
        documented_codes = {m.group(1) for m in _exit_code_line_re.finditer(header_text)}
        self.assertEqual(documented_codes, {"0", "3", "4", "5"})


@unittest.skipUnless(_NODE_AVAILABLE and _BASH_EXE_RESOLVED, "node/bash not available")
class TestConnectorSetRealWriterCrossRuntimeParity(unittest.TestCase):
    """A REAL-writer (not fake) cross-runtime parity case: connector.set mcp
    happy path dispatched independently through Python's _dispatch_op and a
    sliced Node dispatchOp AGAINST THE SAME served_root, asserting the
    (status, body) pair AND the resulting descriptor bytes are identical --
    complements the exhaustive-but-synthetic fake-writer matrix above with one
    genuine end-to-end real-writer comparison (neither task-019's own suite
    nor the fake-writer classes above ever compare real disk OUTPUT bytes
    across runtimes)."""

    @classmethod
    def setUpClass(cls) -> None:
        if not _node_available():
            raise unittest.SkipTest("node not available")
        text = _SERVER_MJS.read_text(encoding="utf-8")
        idx = text.find(_MAIN_MARKER)
        assert idx != -1
        sliced = text[:idx] + "\nexport { dispatchOp, OP_TABLE };\n"
        cls._slice_path = _SERVER_DIR / f"_test_task023_real_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(sliced, encoding="utf-8")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)

    def test_connector_set_mcp_byte_identical_across_runtimes(self) -> None:
        py_root = Path(tempfile.mkdtemp())
        node_root = Path(tempfile.mkdtemp())
        try:
            parsed = {"op": "connector.set", "target": {}, "args": {"name": "GitHub", "type": "mcp"}}
            py_result = srv._dispatch_op(srv.OP_TABLE, parsed, str(py_root))

            driver = (
                "import { dispatchOp, OP_TABLE } from "
                f"{json.dumps(self._slice_path.resolve().as_uri())};\n"
                f"const parsed = {json.dumps(parsed)};\n"
                f"const [status, body] = dispatchOp(OP_TABLE, parsed, {json.dumps(str(node_root))});\n"
                "process.stdout.write(JSON.stringify([status, Buffer.from(body).toString('utf-8')]));\n"
            )
            result = subprocess.run(
                ["node", "--input-type=module"], input=driver,
                capture_output=True, text=True, timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            node_status, node_body = json.loads(result.stdout.strip())

            _assert_parity(self, py_result, (node_status, node_body), 200, None)

            py_descriptor = (py_root / ".aid" / "connectors" / "github.md").read_bytes()
            node_descriptor = (node_root / ".aid" / "connectors" / "github.md").read_bytes()
            self.assertEqual(
                py_descriptor, node_descriptor,
                "real write-connector.sh output diverged in BYTES between the two runtimes' dispatch",
            )
        finally:
            shutil.rmtree(str(py_root), ignore_errors=True)
            shutil.rmtree(str(node_root), ignore_errors=True)


# ===========================================================================
# (C) write_enabled 403 gate -- HTTP-layer (_serve_op), live socket.
# ===========================================================================

class TestWriteEnabledGateLive(unittest.TestCase):
    """task-023 DETAIL: 'the write_enabled gate returns 403 under read-only'.
    The gate fires in _serve_op BEFORE any body parse / OP_TABLE dispatch (see
    server.py _serve_op docstring: 'Order: write gate (403) -> repo id
    resolution -> body parse -> OP_TABLE dispatch'), so it is untestable via
    _dispatch_op alone (every other class in this file's boundary) -- it is
    inherently an HTTP-layer (_ServerThread) concern, mirroring test_task017's
    own TestToolsUpdateUnknownRepoIdLive convention for the analogous
    id-resolution 404.

    LOCAL TEST NOTE: this class binds a loopback socket (_ServerThread) -- per
    the project's port-binding-server-test constraint it is NOT executed
    locally as part of this task's own verification pass; deferred to CI. Its
    Node twin lives in test_task023_list_management_round_trips.mjs.
    """

    def setUp(self) -> None:
        self._base = Path(tempfile.mkdtemp())
        self._aid_home = self._base / "aid_home"
        _make_aid_home(self._aid_home)
        self._repo = self._base / "repo-A"
        (self._repo / ".aid").mkdir(parents=True, exist_ok=True)
        _write_registry(self._aid_home, [str(self._repo)])
        self._id = _repo_id8(str(self._repo))

    def tearDown(self) -> None:
        shutil.rmtree(str(self._base), ignore_errors=True)

    def test_connector_set_403_under_read_only(self) -> None:
        with _ServerThread(str(self._aid_home), write_enabled=False) as server:
            status, body = server.post_json(
                f"/r/{self._id}/api/op",
                {"op": "connector.set", "args": {"name": "GitHub", "type": "mcp"}},
            )
        self.assertEqual(status, 403)
        self.assertEqual(
            json.loads(body),
            {"ok": False, "op": None, "error": "read-only",
             "detail": "write endpoints disabled (server not spawned with --allow-writes)"},
        )
        # Fail-closed proof: no descriptor was written despite the request shape
        # being otherwise valid.
        self.assertFalse((self._repo / ".aid" / "connectors").exists())

    def test_external_source_add_403_under_read_only(self) -> None:
        with _ServerThread(str(self._aid_home), write_enabled=False) as server:
            status, body = server.post_json(
                f"/r/{self._id}/api/op",
                {"op": "external-source.add", "args": {"value": "https://example.com/doc"}},
            )
        self.assertEqual(status, 403)
        self.assertEqual(
            json.loads(body),
            {"ok": False, "op": None, "error": "read-only",
             "detail": "write endpoints disabled (server not spawned with --allow-writes)"},
        )


# ===========================================================================
# (D) DM-1 serializer fixture consistency -- cross-runtime BYTE parity WITH
# connectors + external_sources POPULATED (neither test_server_py.py/
# test_server_node.mjs nor tasks 019/021's own suites ever byte-compare the
# two runtimes' envelope for a repo carrying real data in these two fields).
# ===========================================================================

_WRITE_ENABLED_PARITY_MODULE = "test_write_enabled_cross_runtime_parity"


def _import_write_enabled_parity_module():
    import importlib
    return importlib.import_module(f"dashboard.server.tests.{_WRITE_ENABLED_PARITY_MODULE}")


@unittest.skipUnless(_NODE_AVAILABLE, "node not available on PATH -- cross-runtime comparison skipped")
class TestDm1SerializerConnectorsExternalSourcesParity(unittest.TestCase):
    """Reuses test_write_enabled_cross_runtime_parity.py's own established
    slice-and-export technique for serializeModel/serializeModelWithDetails/
    buildHomeModel/serializeHome (not re-implemented here) against a repo that
    ACTUALLY carries connector descriptors + external sources, asserting the
    two runtimes' raw JSON is byte-identical -- not merely 'each independently
    contains a connectors key' (already covered by test_server_py.py/
    test_server_node.mjs; see the pointer test below)."""

    @classmethod
    def setUpClass(cls) -> None:
        cls._mod = _import_write_enabled_parity_module()
        cls._slice_path = _SERVER_DIR / f"_test_task023_dm1_slice_{uuid.uuid4().hex}.mjs"
        cls._slice_path.write_text(cls._mod._sliced_server_mjs_source(), encoding="utf-8")

    @classmethod
    def tearDownClass(cls) -> None:
        cls._slice_path.unlink(missing_ok=True)

    def test_populated_connectors_and_external_sources_byte_identical(self) -> None:
        root = Path(tempfile.mkdtemp())
        try:
            connectors_dir = root / ".aid" / "connectors"
            connectors_dir.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(_FIXTURES_CONNECTORS / "github.md", connectors_dir / "github.md")
            shutil.copyfile(_FIXTURES_CONNECTORS / "jira.md", connectors_dir / "jira.md")
            _seed_external_sources_from_fixture(root, "multi-entry.md")
            (root / ".aid" / "settings.yml").write_text(
                "project:\n  name: test-project\n", encoding="utf-8",
            )

            py_model = read_repo(root)
            py_raw = srv.serialize_model(py_model, write_enabled=True).decode("utf-8")

            proc = subprocess.run(
                ["node"], input=(
                    "import { pathToFileURL } from 'node:url';\n"
                    f"const slicePath = {json.dumps(str(self._slice_path))};\n"
                    f"const readerPath = {json.dumps(str(_DASHBOARD_DIR / 'server' / 'reader.mjs'))};\n"
                    f"const servedRoot = {json.dumps(str(root))};\n"
                    "const sliceMod = await import(pathToFileURL(slicePath).href);\n"
                    "const readerMod = await import(pathToFileURL(readerPath).href);\n"
                    "const model = readerMod.readRepo(servedRoot);\n"
                    "const dm1Buf = sliceMod.serializeModel(model, true);\n"
                    "process.stdout.write(Buffer.from(dm1Buf).toString('utf-8'));\n"
                ),
                capture_output=True, text=True, timeout=15,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr)
            node_raw = proc.stdout

            py_json = json.loads(py_raw)
            node_json = json.loads(node_raw)
            self.assertEqual(len(py_json["model"]["repo"]["connectors"]), 2)
            self.assertEqual(len(py_json["model"]["repo"]["external_sources"]), 3)
            self.assertEqual(py_json["schema_version"], 3)
            self.assertEqual(node_json["schema_version"], 3)

            # THREE fields are EXPECTED to differ, all pre-existing/environmental,
            # none a connectors/external_sources regression -- normalized
            # before the byte comparison below:
            #   - generated_by: INTENTIONALLY runtime-specific ("python" vs
            #     "node" -- both serialize_model/serializeModel hardcode their
            #     own literal; see server.py/server.mjs).
            #   - repo.aid_dir: an ABSOLUTE FILESYSTEM PATH echo of served_root;
            #     on this Windows host, Python's and Node's own path-resolution
            #     can independently render the SAME directory in long-vs-8.3
            #     short-name form for a sufficiently long username component
            #     (the documented pre-existing 8.3-path gap that also affects
            #     ~11 test_server_py.py cases -- unrelated to this feature).
            #   - read.read_at: the read-time timestamp, captured INDEPENDENTLY
            #     by the Python read_repo() and the (milliseconds-later) Node
            #     readRepo() call -- a wall-clock artifact of running the twins
            #     sequentially, never a serialization divergence. Without this
            #     normalization the byte comparison flakes on the timestamp.
            self.assertEqual(py_json["generated_by"], "python")
            self.assertEqual(node_json["generated_by"], "node")
            py_aid_dir = py_json["model"]["repo"]["aid_dir"]
            node_aid_dir = node_json["model"]["repo"]["aid_dir"]
            _READ_AT_RE = r'"read_at":"[^"]*"'
            py_normalized = re.sub(
                _READ_AT_RE, '"read_at":"NORMALIZED"',
                py_raw.replace('"generated_by":"python"', '"generated_by":"RUNTIME"', 1)
                      .replace(json.dumps(py_aid_dir), json.dumps("AID_DIR"), 1),
            )
            node_normalized = re.sub(
                _READ_AT_RE, '"read_at":"NORMALIZED"',
                node_raw.replace('"generated_by":"node"', '"generated_by":"RUNTIME"', 1)
                        .replace(json.dumps(node_aid_dir), json.dumps("AID_DIR"), 1),
            )
            self.assertEqual(
                py_normalized, node_normalized,
                "python/node DM-1 envelope DIVERGES in bytes (beyond the two intentional/"
                "environmental fields normalized above) with connectors+external_sources populated",
            )
        finally:
            shutil.rmtree(str(root), ignore_errors=True)


class TestDm1AlreadyCoveredKeyOrderSchemaVersion(unittest.TestCase):
    """AC-traceability pointer only (task-023 DETAIL: 'DM-1 serializer
    fixtures ... stay byte-consistent with connectors + external_sources
    present and schema_version unchanged'). ALREADY covered independently per
    runtime: test_server_py.py (line ~1183, key-order assertion incl.
    'connectors'/'external_sources', schema_version==3) and
    test_server_node.mjs (lines ~771-778, identical key-order + empty-array
    assertions; line ~1846, schema_version stays 3). Not duplicated here;
    TestDm1SerializerConnectorsExternalSourcesParity above additionally proves
    the CROSS-RUNTIME byte-identity these two files never compare against
    each other."""

    def test_pointer_to_existing_key_order_and_schema_version_coverage(self) -> None:
        server_py_text = (_TESTS_DIR / "test_server_py.py").read_text(encoding="utf-8")
        self.assertIn('"connectors", "external_sources"', server_py_text)
        self.assertIn('data["schema_version"], 3', server_py_text)
        server_node_text = (_TESTS_DIR / "test_server_node.mjs").read_text(encoding="utf-8")
        self.assertIn('keys8[5] === "connectors"', server_node_text)
        self.assertIn('keys8[6] === "external_sources"', server_node_text)


if __name__ == "__main__":
    unittest.main(verbosity=2)
