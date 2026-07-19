"""
test_task019_connector_ops.py -- "ConnectorRef reader/model + connector.set/remove
ops" (task-019, feature-007-connectors-list, delivery-003,
work-017-cli-improvements) -- Python twin.

Covers, all in-process (no socket bind -- see LOCAL TEST NOTE below):

  1. OP_TABLE shape: connector.set / connector.remove rows carry the expected
     scope ("project" -- no work_id), writer ("write-connector.sh"), arg_schema
     keys, and semantic_validate hooks; no per-op status_map override (relies
     on feature-001's generic DEFAULT_MAP, which already covers the writer's
     0/4/5/3 exit alphabet).
  2. Pure semantic validation (_validate_connector_set_args /
     _validate_connector_remove_args): name length/charset, type enum,
     conditional endpoint/auth requiredness per type, secret_ref pattern +
     forbidden-for-mcp/auth-none, stem charset.
  3. Argv builders (_op_connector_set_argv / _op_connector_remove_argv): argv
     is an array (never a shell string), starts with the write-connector.sh
     subcommand, --root is server-built from served_root (never the request
     body), optional flags omitted when absent.
  4. Full _dispatch_op round-trips through the REAL co-vendored
     write-connector.sh writer (bash) -- 200 happy paths (descriptor authored,
     INDEX.md regenerated) for connector.set/connector.remove, and 422
     'invalid-value' short-circuits BEFORE any child spawn for a semantically
     invalid request (proven via a served_root with no .aid/connectors/ at
     all -- if the writer had been invoked, a missing root would still exit 0
     since write-connector.sh mkdir -p's it, so a 422 here is FIRM proof the
     pre-validation fired before spawn).
  5. target: {} (present-but-empty) request shape -- no target.work_id is ever
     consumed by either op (project-scoped, feature-002 settings.set envelope
     precedent).

LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): every class in this file
calls `srv._dispatch_op(...)` directly -- no `_ServerThread` socket bind
anywhere -- so the whole file is safe to run locally per the project's
port-binding-server-test constraint. All classes were exercised directly as
part of this task's own verification pass.

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unittest
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


class _TmpRepo:
    """Context manager: a scratch repo root, cleaned up on exit."""

    def __enter__(self) -> Path:
        self.path = Path(tempfile.mkdtemp())
        return self.path

    def __exit__(self, *_exc) -> None:
        shutil.rmtree(str(self.path), ignore_errors=True)


# ===========================================================================
# (1) OP_TABLE shape
# ===========================================================================

class TestOpTableConnectorRows(unittest.TestCase):
    def test_connector_set_row_shape(self):
        row = srv.OP_TABLE["connector.set"]
        self.assertEqual(row["scope"], "project")
        self.assertEqual(row["writer"], "write-connector.sh")
        self.assertIn("name", row["arg_schema"])
        self.assertTrue(row["arg_schema"]["name"]["required"])
        self.assertIn("type", row["arg_schema"])
        self.assertTrue(row["arg_schema"]["type"]["required"])
        for optional_key in ("endpoint", "auth", "secret_ref"):
            self.assertIn(optional_key, row["arg_schema"])
            self.assertNotIn("required", row["arg_schema"][optional_key])
        self.assertTrue(callable(row["build_argv"]))
        self.assertTrue(callable(row["semantic_validate"]))
        self.assertIsNone(row.get("status_map"))

    def test_connector_remove_row_shape(self):
        row = srv.OP_TABLE["connector.remove"]
        self.assertEqual(row["scope"], "project")
        self.assertEqual(row["writer"], "write-connector.sh")
        self.assertIn("stem", row["arg_schema"])
        self.assertTrue(row["arg_schema"]["stem"]["required"])
        self.assertTrue(callable(row["build_argv"]))
        self.assertTrue(callable(row["semantic_validate"]))
        self.assertIsNone(row.get("status_map"))


# ===========================================================================
# (2) Pure semantic validation
# ===========================================================================

class TestValidateConnectorSetArgsName(unittest.TestCase):
    def test_valid_name_passes_for_mcp(self):
        self.assertIsNone(srv._validate_connector_set_args({"name": "GitHub", "type": "mcp"}))

    def test_empty_name_rejected(self):
        err = srv._validate_connector_set_args({"name": "", "type": "mcp"})
        self.assertIsNotNone(err)

    def test_overlong_name_rejected(self):
        err = srv._validate_connector_set_args({"name": "x" * 81, "type": "mcp"})
        self.assertIsNotNone(err)

    def test_name_at_max_length_passes(self):
        self.assertIsNone(srv._validate_connector_set_args({"name": "x" * 80, "type": "mcp"}))

    def test_name_with_newline_rejected(self):
        err = srv._validate_connector_set_args({"name": "a\nb", "type": "mcp"})
        self.assertIsNotNone(err)

    def test_name_with_pipe_rejected(self):
        err = srv._validate_connector_set_args({"name": "a|b", "type": "mcp"})
        self.assertIsNotNone(err)

    def test_name_with_control_char_rejected(self):
        err = srv._validate_connector_set_args({"name": "a\x01b", "type": "mcp"})
        self.assertIsNotNone(err)


class TestValidateConnectorSetArgsType(unittest.TestCase):
    def test_valid_types_pass_with_required_fields(self):
        cases = [
            {"name": "n", "type": "mcp"},
            {"name": "n", "type": "api", "endpoint": "https://x", "auth": "token"},
            {"name": "n", "type": "ssh", "endpoint": "host:22"},
            {"name": "n", "type": "url", "endpoint": "https://x", "auth": "none"},
            {"name": "n", "type": "cli", "endpoint": "cmd", "auth": "pat"},
        ]
        for args in cases:
            with self.subTest(args=args):
                self.assertIsNone(srv._validate_connector_set_args(args))

    def test_invalid_type_rejected(self):
        err = srv._validate_connector_set_args({"name": "n", "type": "ftp"})
        self.assertIsNotNone(err)
        self.assertIn("type", err)


class TestValidateConnectorSetArgsEndpointAuth(unittest.TestCase):
    def test_endpoint_required_for_aid_managed_types(self):
        for ctype in ("api", "ssh", "url", "cli"):
            with self.subTest(ctype=ctype):
                args = {"name": "n", "type": ctype}
                if ctype in ("api", "url", "cli"):
                    args["auth"] = "token"
                err = srv._validate_connector_set_args(args)
                self.assertIsNotNone(err, f"endpoint should be required for {ctype}")

    def test_endpoint_optional_for_mcp(self):
        self.assertIsNone(srv._validate_connector_set_args({"name": "n", "type": "mcp"}))
        self.assertIsNone(
            srv._validate_connector_set_args({"name": "n", "type": "mcp", "endpoint": "info"})
        )

    def test_auth_required_for_api_url_cli(self):
        for ctype in ("api", "url", "cli"):
            with self.subTest(ctype=ctype):
                err = srv._validate_connector_set_args(
                    {"name": "n", "type": ctype, "endpoint": "https://x"}
                )
                self.assertIsNotNone(err)

    def test_auth_optional_for_ssh_and_mcp(self):
        self.assertIsNone(
            srv._validate_connector_set_args({"name": "n", "type": "ssh", "endpoint": "host"})
        )
        self.assertIsNone(srv._validate_connector_set_args({"name": "n", "type": "mcp"}))

    def test_invalid_auth_enum_rejected(self):
        err = srv._validate_connector_set_args(
            {"name": "n", "type": "api", "endpoint": "https://x", "auth": "bearer"}
        )
        self.assertIsNotNone(err)

    def test_endpoint_over_length_rejected(self):
        err = srv._validate_connector_set_args(
            {"name": "n", "type": "api", "endpoint": "x" * 201, "auth": "token"}
        )
        self.assertIsNotNone(err)

    def test_endpoint_with_pipe_rejected(self):
        err = srv._validate_connector_set_args(
            {"name": "n", "type": "api", "endpoint": "https://x|evil", "auth": "token"}
        )
        self.assertIsNotNone(err)


class TestValidateConnectorSetArgsSecretRef(unittest.TestCase):
    def test_omitted_secret_ref_never_rejected(self):
        self.assertIsNone(
            srv._validate_connector_set_args(
                {"name": "n", "type": "api", "endpoint": "https://x", "auth": "token"}
            )
        )

    def test_env_form_accepted(self):
        self.assertIsNone(
            srv._validate_connector_set_args({
                "name": "n", "type": "api", "endpoint": "https://x", "auth": "token",
                "secret_ref": "env:MY_TOKEN",
            })
        )

    def test_file_form_accepted(self):
        self.assertIsNone(
            srv._validate_connector_set_args({
                "name": "n", "type": "ssh", "endpoint": "host",
                "secret_ref": "file:.aid/connectors/.secrets/n",
            })
        )

    def test_keychain_form_accepted(self):
        self.assertIsNone(
            srv._validate_connector_set_args({
                "name": "n", "type": "cli", "endpoint": "cmd", "auth": "pat",
                "secret_ref": "keychain:my-key",
            })
        )

    def test_malformed_secret_ref_rejected(self):
        err = srv._validate_connector_set_args({
            "name": "n", "type": "api", "endpoint": "https://x", "auth": "token",
            "secret_ref": "not-a-valid-ref",
        })
        self.assertIsNotNone(err)

    def test_env_form_bad_var_name_rejected(self):
        err = srv._validate_connector_set_args({
            "name": "n", "type": "api", "endpoint": "https://x", "auth": "token",
            "secret_ref": "env:123bad",
        })
        self.assertIsNotNone(err)

    def test_secret_ref_forbidden_for_mcp(self):
        err = srv._validate_connector_set_args({
            "name": "n", "type": "mcp", "secret_ref": "env:MY_TOKEN",
        })
        self.assertIsNotNone(err)

    def test_secret_ref_forbidden_for_auth_none(self):
        err = srv._validate_connector_set_args({
            "name": "n", "type": "url", "endpoint": "https://x", "auth": "none",
            "secret_ref": "env:MY_TOKEN",
        })
        self.assertIsNotNone(err)

    def test_secret_ref_over_length_rejected(self):
        err = srv._validate_connector_set_args({
            "name": "n", "type": "api", "endpoint": "https://x", "auth": "token",
            "secret_ref": "file:" + ("x" * 200),
        })
        self.assertIsNotNone(err)


class TestValidateConnectorRemoveArgs(unittest.TestCase):
    def test_valid_stem_passes(self):
        self.assertIsNone(srv._validate_connector_remove_args({"stem": "github"}))
        self.assertIsNone(srv._validate_connector_remove_args({"stem": "my-connector-2"}))

    def test_uppercase_stem_rejected(self):
        self.assertIsNotNone(srv._validate_connector_remove_args({"stem": "GitHub"}))

    def test_stem_starting_with_dash_rejected(self):
        self.assertIsNotNone(srv._validate_connector_remove_args({"stem": "-github"}))

    def test_stem_with_slash_rejected(self):
        self.assertIsNotNone(srv._validate_connector_remove_args({"stem": "a/b"}))

    def test_stem_with_dotdot_rejected(self):
        self.assertIsNotNone(srv._validate_connector_remove_args({"stem": "../etc"}))


# ===========================================================================
# (3) Argv builders
# ===========================================================================

class TestConnectorSetArgvBuilder(unittest.TestCase):
    def test_argv_is_list_and_starts_with_set_subcommand(self):
        argv, env = srv._op_connector_set_argv(
            None, "/repo/root", {}, {"name": "Jira", "type": "api", "endpoint": "https://x", "auth": "token"},
        )
        self.assertIsInstance(argv, list)
        self.assertEqual(argv[0], "set")
        self.assertIn("--root", argv)
        root_idx = argv.index("--root")
        self.assertTrue(argv[root_idx + 1].endswith(".aid/connectors"))

    def test_optional_flags_omitted_when_absent(self):
        argv, _ = srv._op_connector_set_argv(None, "/repo/root", {}, {"name": "GitHub", "type": "mcp"})
        self.assertNotIn("--endpoint", argv)
        self.assertNotIn("--auth", argv)
        self.assertNotIn("--secret-ref", argv)

    def test_optional_flags_included_when_present(self):
        argv, _ = srv._op_connector_set_argv(
            None, "/repo/root", {},
            {"name": "Jira", "type": "api", "endpoint": "https://x", "auth": "token", "secret_ref": "env:X"},
        )
        self.assertIn("--endpoint", argv)
        self.assertIn("--auth", argv)
        self.assertIn("--secret-ref", argv)

    def test_root_never_taken_from_args_body(self):
        """--root is ALWAYS server-built from served_root, never echoed from a
        client-supplied field (SEC-2)."""
        argv, _ = srv._op_connector_set_argv(
            None, "/repo/root", {}, {"name": "n", "type": "mcp", "root": "/evil/path"},
        )
        root_idx = argv.index("--root")
        self.assertNotIn("/evil/path", argv[root_idx + 1])


class TestConnectorRemoveArgvBuilder(unittest.TestCase):
    def test_argv_is_list_and_starts_with_remove_subcommand(self):
        argv, env = srv._op_connector_remove_argv(None, "/repo/root", {}, {"stem": "github"})
        self.assertIsInstance(argv, list)
        self.assertEqual(argv[0], "remove")
        self.assertIn("--root", argv)
        self.assertIn("--stem", argv)
        self.assertEqual(argv[argv.index("--stem") + 1], "github")


# ===========================================================================
# (4) Full _dispatch_op round-trips through the REAL write-connector.sh writer
# ===========================================================================

class TestConnectorOpsRealWriterRoundTrips(unittest.TestCase):
    def test_connector_set_mcp_success(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "target": {}, "args": {"name": "GitHub", "type": "mcp"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "connector.set"})
            descriptor = root / ".aid" / "connectors" / "github.md"
            self.assertTrue(descriptor.is_file())
            text = descriptor.read_text(encoding="utf-8")
            self.assertIn("connection_type: mcp", text)
            self.assertIn("auth_method: none", text)
            self.assertNotIn("secret_reference:", text)
            index_md = root / ".aid" / "connectors" / "INDEX.md"
            self.assertTrue(index_md.is_file())

    def test_connector_set_api_with_default_secret_ref(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "connector.set", "target": {},
                    "args": {"name": "Jira", "type": "api",
                             "endpoint": "https://acme.atlassian.net/rest/api/3", "auth": "token"},
                },
                str(root),
            )
            self.assertEqual(status, 200)
            descriptor = root / ".aid" / "connectors" / "jira.md"
            text = descriptor.read_text(encoding="utf-8")
            self.assertIn("auth_method: token", text)
            self.assertIn('secret_reference: "file:.aid/connectors/.secrets/jira"', text)

    def test_connector_set_semantic_failure_maps_to_422_before_spawn(self):
        """An invalid --type never reaches the writer (422 'invalid-value')."""
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "target": {}, "args": {"name": "n", "type": "ftp"}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")
            # Proof no spawn happened: write-connector.sh would have mkdir -p'd
            # the connectors/ dir even on failure paths that reach it.
            self.assertFalse((root / ".aid" / "connectors").exists())

    def test_connector_remove_success(self):
        with _TmpRepo() as root:
            # Seed a connector first.
            status, _ = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "target": {}, "args": {"name": "GitHub", "type": "mcp"}},
                str(root),
            )
            self.assertEqual(status, 200)
            descriptor = root / ".aid" / "connectors" / "github.md"
            self.assertTrue(descriptor.is_file())

            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.remove", "target": {}, "args": {"stem": "github"}},
                str(root),
            )
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"ok": True, "op": "connector.remove"})
            self.assertFalse(descriptor.exists())

    def test_connector_remove_idempotent_for_absent_stem(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.remove", "target": {}, "args": {"stem": "never-existed"}},
                str(root),
            )
            self.assertEqual(status, 200)

    def test_connector_remove_bad_stem_422_before_spawn(self):
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.remove", "target": {}, "args": {"stem": "../etc"}},
                str(root),
            )
            self.assertEqual(status, 422)
            self.assertEqual(json.loads(body)["error"], "invalid-value")


# ===========================================================================
# (5) target: {} envelope shape -- no work_id consumed
# ===========================================================================

class TestConnectorOpsProjectScoped(unittest.TestCase):
    def test_missing_target_key_defaults_to_empty_and_still_dispatches(self):
        """The op does not require 'target' in the body at all (defaults to {})."""
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {"op": "connector.set", "args": {"name": "GitHub", "type": "mcp"}},
                str(root),
            )
            self.assertEqual(status, 200)

    def test_target_with_work_id_is_ignored_not_consumed(self):
        """scope='project' never triggers work_id resolution (unlike 'task'/'pipeline')."""
        with _TmpRepo() as root:
            status, body = srv._dispatch_op(
                srv.OP_TABLE,
                {
                    "op": "connector.set",
                    "target": {"work_id": "work-999-does-not-exist"},
                    "args": {"name": "GitHub", "type": "mcp"},
                },
                str(root),
            )
            # Must NOT 404 (which would mean work_id resolution was attempted).
            self.assertEqual(status, 200)


if __name__ == "__main__":
    unittest.main()
