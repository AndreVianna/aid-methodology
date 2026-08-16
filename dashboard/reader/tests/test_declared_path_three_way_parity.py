"""
test_declared_path_three_way_parity.py -- THREE-way parity for the declared layout read.

`pipeline.path` in a work's STATE.yml decides whether the work uses the flat/Lite layout
or the nested one. Three implementations read it and all three must agree on every file:

    canonical/aid/scripts/execute/writeback-state.sh   wb_get_pipeline_path   (awk)
    dashboard/reader/reader.py                         _declared_work_path    (D-3 engine)
    dashboard/server/reader.mjs                        _declaredWorkPath      (D-3 engine)

THIS IS THE TEST THAT WAS MISSING. Three scalar forms once made the bash reader disagree
with both twins on the same file -- a CRLF file, a single-quoted 'lite', and a trailing
`# comment` -- and each silently classified a work declared `lite` as `full`. They were
found by a reviewer reading the code, not by any suite: the existing 278-assertion
writeback suite passed throughout, because every one of its flat fixtures also carried
the old BLUEPRINT.md sentinel and so satisfied the presence rule whether the declared
read worked or not.

A behavioural regression test now covers the bash side (Unit 26 in
test-writeback-state.sh). What that cannot do is prove the three agree WITH EACH OTHER,
which is the actual invariant: any one of them being individually reasonable is not
enough. Hence one shared corpus, run through all three.

The corpus deliberately includes the three historical failures plus the forms most
likely to separate a hand-rolled parser from a real one: quoting, comments, whitespace,
line endings, key scoping, and the empty/absent cases.

Bounded compute only -- a `bash` subprocess and a `node` subprocess, no server spawn.
"""

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader.reader import _declared_work_path

_WRITEBACK = _REPO_ROOT / "canonical" / "aid" / "scripts" / "execute" / "writeback-state.sh"
_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"

# name -> exact STATE.yml bytes. Written as bytes so line endings are explicit rather
# than whatever the editor decides.
FIXTURES = {
    "plain":                 b"pipeline:\n  path: lite\n",
    "full":                  b"pipeline:\n  path: full\n",
    # The three that actually diverged.
    "crlf":                  b"pipeline:\r\n  path: lite\r\n",
    "single_quoted":         b"pipeline:\n  path: 'lite'\n",
    "trailing_comment":      b"pipeline:\n  path: lite # single-delivery\n",
    # Neighbouring forms a parser tends to get wrong once it handles the above.
    "double_quoted":         b'pipeline:\n  path: "lite"\n',
    "uppercase_value":       b"pipeline:\n  path: LITE\n",
    "trailing_whitespace":   b"pipeline:\n  path: lite   \n",
    "hash_inside_quotes":    b"pipeline:\n  path: 'a # b'\n",
    "tab_indent":            b"pipeline:\n\tpath: lite\n",
    "empty_value":           b"pipeline:\n  path:\n",
    "no_path_key":           b"pipeline:\n  initiator: aid-fix\n",
    "no_pipeline_key":       b"lifecycle: Running\n",
    "empty_file":            b"",
    # Scoping: a `path:` under a DIFFERENT parent must not be mistaken for this one.
    "foreign_parent_first":  b"other:\n  path: full\npipeline:\n  path: lite\n",
    "pipeline_first":        b"pipeline:\n  path: lite\nother:\n  path: full\n",
    "sibling_before_path":   b"pipeline:\n  initiator: aid-fix\n  path: lite\n",
    # A commented-out key must not win over the real one below it.
    "commented_decoy":       b"# path: full\npipeline:\n  path: lite\n",
    "dedent_ends_mapping":   b"pipeline:\n  initiator: x\nlifecycle: Running\n  path: full\n",

    # ---- found by probing forms the corpus had never tried ----------------------
    # The five below are not hypotheticals: each made the bash reader disagree with
    # both twins on the same file, and each was found by generating scalar forms
    # rather than by waiting for a reviewer. The corpus above had grown by recording
    # failures already known, which is precisely the coverage a corpus cannot claim
    # credit for.
    "bom": b"\xef\xbb\xbfpipeline:\n  path: lite\n",
    "nested_deeper": b"pipeline:\n  opts:\n    path: lite\n",
    "block_literal": b"pipeline:\n  path: |\n    lite\n",
    "block_folded": b"pipeline:\n  path: >\n    lite\n",
    "anchor": b"pipeline:\n  path: &p lite\n",
    "escaped_quote": b'pipeline:\n  path: "li\\"te"\n',
    "multi_doc": b"pipeline:\n  path: lite\n---\npipeline:\n  path: full\n",

    # Four-space indentation is VALID YAML that all three read as "not declared",
    # because the engine models nesting as `level = indent // 2` and so sees a
    # grandchild of `pipeline:`. Pinned deliberately: the three agreeing is the
    # invariant, and a file all three misread identically is at least classified
    # consistently. A future engine that learns relative indentation must change
    # this fixture knowingly rather than discover it.
    "four_space_indent": b"pipeline:\n    path: lite\n",
    "flow_mapping": b"pipeline: {path: lite}\n",
    "list_not_mapping": b"pipeline:\n  - path: lite\n"
}

_NODE_DRIVER = """
import { pathToFileURL } from "node:url";
const [, , readerPath, dirsJson] = process.argv;
const fs = await import("node:fs");
const mod = await import(pathToFileURL(readerPath).href);
const dirs = JSON.parse(fs.readFileSync(dirsJson, "utf8"));
const out = {};
for (const [name, dir] of Object.entries(dirs)) {
  out[name] = mod._declaredWorkPath(dir);
}
process.stdout.write(JSON.stringify(out));
"""


def _tool(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, timeout=10).returncode == 0
    except Exception:  # noqa: BLE001
        return False


_NODE = _tool(["node", "--version"])
_BASH = _tool(["bash", "--version"])


class TestDeclaredPathThreeWayParity(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.tmp = Path(tempfile.mkdtemp())
        cls.dirs = {}
        for name, body in FIXTURES.items():
            d = cls.tmp / name
            d.mkdir()
            (d / "STATE.yml").write_bytes(body)
            cls.dirs[name] = str(d)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(str(cls.tmp), ignore_errors=True)

    # ---- the three readers -------------------------------------------------------
    def _python(self, name):
        return _declared_work_path(Path(self.dirs[name]))

    def _bash(self, name):
        """Invoke wb_get_pipeline_path exactly as writeback-state.sh defines it.

        The script self-executes on load, so the function is extracted rather than
        sourced -- slicing it out keeps this honest about which code is under test
        instead of reimplementing it here.
        """
        src = _WRITEBACK.read_text(encoding="utf-8")
        start = src.index("wb_get_pipeline_path() {")
        depth, i = 0, start
        while True:
            if src[i] == "{":
                depth += 1
            elif src[i] == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        fn = src[start:i + 1]
        # resolve_work_dir is the script's own path plumbing; stub it to the fixture.
        harness = (
            "set -uo pipefail\n"
            f'WORK_DIR="{self.dirs[name]}"\n'
            "resolve_work_dir() { :; }\n"
            f"{fn}\n"
            "wb_get_pipeline_path\n"
        )
        proc = subprocess.run(["bash", "-c", harness], capture_output=True, text=True, timeout=15)
        return proc.stdout.strip() or None

    def _node_all(self):
        payload = self.tmp / "dirs.json"
        payload.write_text(json.dumps(self.dirs), encoding="utf-8")
        driver = self.tmp / "driver.mjs"
        driver.write_text(_NODE_DRIVER, encoding="utf-8")
        proc = subprocess.run(
            ["node", str(driver), str(_READER_MJS), str(payload)],
            capture_output=True, text=True, timeout=30,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"node driver failed: {proc.stderr}")
        return json.loads(proc.stdout)

    # ---- assertions ----------------------------------------------------------------
    def test_python_side_expected_values(self):
        """Pin the Python answers, so three-way agreement cannot be satisfied by all
        three being wrong together."""
        self.assertEqual(self._python("plain"), "lite")
        self.assertEqual(self._python("full"), "full")
        self.assertEqual(self._python("crlf"), "lite")
        self.assertEqual(self._python("single_quoted"), "lite")
        self.assertEqual(self._python("trailing_comment"), "lite")
        self.assertEqual(self._python("double_quoted"), "lite")
        self.assertEqual(self._python("uppercase_value"), "lite")
        self.assertEqual(self._python("trailing_whitespace"), "lite")
        self.assertEqual(self._python("hash_inside_quotes"), "a # b")
        # Absent / empty all mean "not declared", and the caller falls back to inference.
        for name in ("empty_value", "no_path_key", "no_pipeline_key", "empty_file"):
            self.assertIsNone(self._python(name), f"{name} should be undeclared")
        # Scoping
        self.assertEqual(self._python("foreign_parent_first"), "lite")
        self.assertEqual(self._python("pipeline_first"), "lite")
        self.assertEqual(self._python("sibling_before_path"), "lite")
        self.assertEqual(self._python("commented_decoy"), "lite")

    @unittest.skipUnless(_BASH, "bash not available")
    def test_bash_agrees_with_python_on_every_fixture(self):
        mismatches = []
        for name in FIXTURES:
            py = self._python(name)
            sh = self._bash(name)
            # bash prints nothing for "undeclared"; Python returns None.
            if (py or None) != (sh or None):
                mismatches.append(f"{name}: python={py!r} bash={sh!r}")
        self.assertEqual(
            mismatches, [],
            "writeback-state.sh disagrees with reader.py on the declared layout:\n  "
            + "\n  ".join(mismatches),
        )

    @unittest.skipUnless(_NODE, "node not available")
    def test_node_agrees_with_python_on_every_fixture(self):
        node = self._node_all()
        mismatches = []
        for name in FIXTURES:
            py = self._python(name)
            nd = node.get(name)
            if (py or None) != (nd or None):
                mismatches.append(f"{name}: python={py!r} node={nd!r}")
        self.assertEqual(
            mismatches, [],
            "reader.mjs disagrees with reader.py on the declared layout:\n  "
            + "\n  ".join(mismatches),
        )


if __name__ == "__main__":
    unittest.main()
