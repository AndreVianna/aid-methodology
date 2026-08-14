"""test_state_yaml_conformance_node.py -- work-009-refactor task-005, Node twin.

The SIBLING runner to `test_state_yaml_conformance.py`: reads the SAME
committed corpus (`tests/canonical/fixtures/state-yaml-conformance/`) and
drives `dashboard/server/reader.mjs`'s `parseStateDocument` through a
`subprocess` -- the shape `dashboard/reader/tests/test_flattened_layout_parity.py`
already uses for `readRepo`/`reader.mjs` (a `node --input-type=module` /
driver-file subprocess, never a spawned server, never a bound port).

`parseStateDocument` is NOT exported from reader.mjs (only `SHORTCUT_KIND_MAP`,
`parseConnectors`, `parseExternalSources`, `parseSpecMd`, `readRepo`,
`resolveWorkDir`, `readRepoDetail` are). Rather than edit a product file (this
task edits none), this module builds a PROBE MODULE exactly the way
`test_shortcut_kind_map_cross_runtime_parity.py` already does for the
unexported `resolveKind`: the reader's own source bytes, verbatim, with one
`export { parseStateDocument };` line appended, written to a scratch file and
imported from there. That executes the real bytes -- it does not parse or
re-implement them -- so an edit to `parseStateDocument` is exactly what this
module checks against the corpus.

ONE Node subprocess call per test run (not one per row): the driver script
reads every `<stem>.yml` in the corpus directory itself, calls
`parseStateDocument` on each, and emits one JSON object keyed by stem. This
keeps the corpus the single on-disk source for BOTH runners (this module's
own Python-side row list, used only for the per-row assertions and the
`.expected.json` comparison, is loaded via the same shared
`state_yaml_conformance_corpus.load_rows()` the Python-twin runner uses) while
paying Node's process-startup cost once instead of once per row.

Requires `node` on PATH; SKIPS (with a recorded reason) rather than passing
vacuously when it is absent -- a parity test that quietly passes because one
runtime was missing proves nothing.

Python 3.11+ stdlib only. No third-party deps. No network. Deterministic.
Cleans up its own scratch directory and CONFIRMS the removal (matches the
`_ScratchMixin` precedent in test_shortcut_kind_map_cross_runtime_parity.py).
"""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader.tests.state_yaml_conformance_corpus import (  # noqa: E402
    CORPUS_DIR,
    load_rows,
)

_JS_TWIN = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"
_NODE_TIMEOUT = 60

# Appended to a verbatim copy of reader.mjs to reach the unexported
# parseStateDocument -- same technique as
# test_shortcut_kind_map_cross_runtime_parity.py's `_RESOLVE_KIND_EXPORT`.
_PARSE_STATE_DOCUMENT_EXPORT = "\nexport { parseStateDocument };\n"

_NODE_DRIVER = """
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const [, , readerPath, corpusDir] = process.argv;
const mod = await import(pathToFileURL(readerPath).href);

if (typeof mod.parseStateDocument !== "function") {
  throw new Error("parseStateDocument is not reachable from " + readerPath);
}

const files = readdirSync(corpusDir).filter((f) => f.endsWith(".yml"));
const results = {};
for (const fname of files) {
  const stem = fname.slice(0, -4);
  const text = readFileSync(join(corpusDir, fname), "utf8");
  const expected = JSON.parse(
    readFileSync(join(corpusDir, stem + ".expected.json"), "utf8")
  );
  // Per-row try/catch (NFR7 -- parseStateDocument must never raise, for any
  // row, REJECT-list or not): isolates one row's exception into its own
  // result entry instead of crashing the whole batch, so a single bad row
  // is a reported finding rather than an opaque process-exit-1 with no row
  // attribution.
  try {
    const [data, warnings] = mod.parseStateDocument(text, { fileLabel: expected.file_label });
    results[stem] = { data, warnings };
  } catch (err) {
    results[stem] = { error: String(err && err.message ? err.message : err) };
  }
}
process.stdout.write(JSON.stringify(results));
"""


def _node_available() -> bool:
    try:
        r = subprocess.run(["node", "--version"], capture_output=True, timeout=10)
        return r.returncode == 0
    except Exception:
        return False


_NODE_AVAILABLE = _node_available()
_NODE_SKIP_REASON = (
    "node not available on PATH -- the state-yaml-conformance Node-twin runner "
    "cannot run; SKIPPED rather than passed, because a parity test that passes "
    "vacuously is the failure this corpus exists to prevent"
)


def _read_exact(path: Path) -> str:
    with open(path, "r", encoding="utf-8", newline="") as fh:
        return fh.read()


def _write_exact(path: Path, text: str) -> None:
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(text)


def _node_probe_module(js_path: Path, dest_dir: Path) -> Path:
    """Write the reader's own source bytes, verbatim, plus a single
    `export { parseStateDocument };` line, into dest_dir."""
    src = _read_exact(js_path)
    if "function parseStateDocument" not in src:
        raise RuntimeError(
            f"parseStateDocument is not declared in {js_path} -- the probe cannot "
            "be built. If the function was renamed, this module must be updated."
        )
    already_exported = bool(
        re.search(r"^export\s+function\s+parseStateDocument\b", src, re.M)
        or re.search(r"^export\s*\{[^}]*\bparseStateDocument\b[^}]*\}", src, re.M)
    )
    if not already_exported:
        src += _PARSE_STATE_DOCUMENT_EXPORT
    probe = dest_dir / "reader_probe.mjs"
    _write_exact(probe, src)
    return probe


class _ScratchMixin(unittest.TestCase):
    """mktemp scratch space, removed on cleanup and CONFIRMED gone afterwards."""

    def scratch(self) -> Path:
        d = Path(tempfile.mkdtemp(prefix="aid-state-yaml-conformance-"))
        self.addCleanup(self._assert_removed, d)
        self.addCleanup(shutil.rmtree, str(d), True)
        return d

    def _assert_removed(self, d: Path) -> None:
        self.assertFalse(d.exists(), f"scratch directory was not removed: {d}")


class TestNodeTwinExportPrecondition(unittest.TestCase):
    """Non-Node-dependent sanity: the probe technique itself is well-formed."""

    def test_reader_mjs_declares_parse_state_document(self):
        src = _read_exact(_JS_TWIN)
        self.assertIn(
            "function parseStateDocument", src,
            f"{_JS_TWIN} must declare parseStateDocument for the probe to reach it",
        )


@unittest.skipUnless(_NODE_AVAILABLE, _NODE_SKIP_REASON)
class TestStateYamlConformanceNode(_ScratchMixin):
    """Row-by-row: reader.mjs's parseStateDocument (via the probe module)
    against every corpus row's golden (values, warnings) pair -- the SAME
    corpus and the SAME expectations `test_state_yaml_conformance.py` checks
    the Python engine against."""

    @classmethod
    def setUpClass(cls):
        cls.rows = load_rows()
        assert cls.rows, "corpus must not be empty"
        cls._tmp = Path(tempfile.mkdtemp(prefix="aid-state-yaml-conformance-real-"))
        try:
            probe = _node_probe_module(_JS_TWIN, cls._tmp)
            driver = cls._tmp / "driver.mjs"
            _write_exact(driver, _NODE_DRIVER)
            proc = subprocess.run(
                ["node", str(driver), str(probe), str(CORPUS_DIR)],
                capture_output=True, text=True, timeout=_NODE_TIMEOUT,
            )
            if proc.returncode != 0:
                raise RuntimeError(
                    f"node driver failed (exit {proc.returncode}): {proc.stderr[:4000]}"
                )
            cls.node_results = json.loads(proc.stdout)
        finally:
            shutil.rmtree(str(cls._tmp), ignore_errors=True)

    @classmethod
    def tearDownClass(cls):
        if cls._tmp.exists():
            raise AssertionError(f"scratch directory was not removed: {cls._tmp}")

    def test_every_row_present_in_node_output(self):
        missing = [row.stem for row in self.rows if row.stem not in self.node_results]
        self.assertEqual(missing, [], f"node driver produced no result for: {missing}")

    def test_never_raises_on_any_row(self):
        """NFR7 -- parseStateDocument must never raise (Node), for any corpus
        row, REJECT-list or not. The driver isolates each row's call in its
        own try/catch, so a raise surfaces as an "error" key here rather than
        an opaque non-zero exit for the whole batch."""
        errored = [
            (row.stem, self.node_results[row.stem].get("error"))
            for row in self.rows
            if "error" in self.node_results.get(row.stem, {})
        ]
        self.assertEqual(errored, [], f"parseStateDocument raised (Node) on: {errored}")

    def test_every_row_matches_node_engine(self):
        """AC-3 / AC-4 / AC-5 / AC-6 -- values + warnings, row by row, against
        the SAME golden corpus test_state_yaml_conformance.py checks the
        Python engine against."""
        for row in self.rows:
            with self.subTest(row=row.stem):
                self.assertIn(row.stem, self.node_results)
                actual = self.node_results[row.stem]
                self.assertEqual(
                    actual["data"], row.expected_values,
                    f"[{row.stem}] value tree mismatch (Node)\n"
                    f"input:\n{row.yaml_text}\n"
                    f"expected: {row.expected_values}\n"
                    f"actual:   {actual['data']}",
                )
                self.assertEqual(
                    actual["warnings"], row.expected_warnings,
                    f"[{row.stem}] parse_warning mismatch (Node)\n"
                    f"input:\n{row.yaml_text}\n"
                    f"expected: {row.expected_warnings}\n"
                    f"actual:   {actual['warnings']}",
                )

    def test_permitted_shape_rows_have_no_warnings(self):
        """AC-3: every permitted-shape/quoting-mode/typed-literal row -- an
        empty warning set (Node)."""
        permitted_prefixes = ("shape-", "quoting-", "typed-")
        checked = 0
        for row in self.rows:
            if row.stem.startswith(permitted_prefixes):
                checked += 1
                with self.subTest(row=row.stem):
                    actual = self.node_results[row.stem]
                    self.assertEqual(
                        actual["warnings"], [],
                        f"[{row.stem}] permitted-construct row must warn nothing "
                        f"(Node), got: {actual['warnings']}",
                    )
        self.assertGreater(checked, 0, "no permitted-shape rows were found to check")

    def test_implicit_typing_rows_keep_the_string_on_disk(self):
        """AC-5 / NFR-2, Node side: every deny-list literal comes back as a JS
        string, never a boolean/null -- js-yaml's 1.2-core-schema resolver
        (which WOULD leave 'yes'/'no' as strings but coerce 'true'/'false' to
        boolean) is never in this code path at all, so there is nothing to
        diverge from PyYAML's 1.1 resolver on."""
        typed_rows = [r for r in self.rows if r.stem.startswith("typed-")]
        self.assertEqual(len(typed_rows), 30, "expected exactly 30 implicit-typing rows")
        for row in typed_rows:
            with self.subTest(row=row.stem):
                value = self.node_results[row.stem]["data"].get("typed_value")
                self.assertIsInstance(
                    value, str,
                    f"[{row.stem}] implicit-typing value must be a string (Node), "
                    f"got {type(value).__name__}: {value!r}",
                )
                self.assertEqual(value, row.expected_values["typed_value"])

    def test_rejected_construct_rows_skip_only_that_key(self):
        """AC-4, Node side: the construct's own key is absent, the
        surrounding control keys still parsed, and exactly the expected
        warning(s) were emitted -- "skip exactly that key, keep parsing
        the rest"."""
        reject_rows = [r for r in self.rows if r.stem.startswith("reject-")]
        self.assertEqual(len(reject_rows), 19, "expected exactly 19 rejected-construct rows")
        for row in reject_rows:
            with self.subTest(row=row.stem):
                actual = self.node_results[row.stem]
                self.assertGreater(
                    len(actual["warnings"]), 0,
                    f"[{row.stem}] a rejected construct must emit at least one "
                    "warning (Node)",
                )
                self.assertEqual(actual["data"], row.expected_values)
                self.assertEqual(actual["warnings"], row.expected_warnings)

    def test_absent_key_and_empty_collections_are_distinct_rows_parsed_consistently(self):
        """AC-6, Node side: absent-key / empty-[] / empty-{} are each their
        own row, checked against the same three golden shapes as the
        Python-twin runner."""
        av = self.node_results["absent-key"]["data"]
        self.assertNotIn("target_key", av)

        elv = self.node_results["empty-collection-list"]["data"]
        self.assertEqual(elv.get("target_key"), [])

        emv = self.node_results["empty-collection-map"]["data"]
        self.assertEqual(emv.get("target_key"), {})


if __name__ == "__main__":
    unittest.main(verbosity=2)
