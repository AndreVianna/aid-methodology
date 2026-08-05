"""
test_shortcut_kind_map_cross_runtime_parity.py -- work-004-optimize-skill-library,
delivery-003 task-011 (feature-006, AC-11 / Decision 1): the CROSS-RUNTIME parity
guard for SHORTCUT_KIND_MAP.

dashboard/reader/state_schema.py and dashboard/server/reader.mjs each carry a
hand-maintained static mirror of canonical/aid/templates/shortcut-catalog.yml
(`SHORTCUT_KIND_MAP`), plus a resolver over it (`resolve_kind` / `resolveKind`).
Both files' own comments state the lockstep contract in prose -- "Any change to
shortcut-catalog.yml MUST be mirrored here AND in the Node twin" -- and until this
module landed nothing enforced it. The drift that motivated the guard reached 80
keys against 94 catalogue rows with no test noticing.

FOUR LEGS, and each exists because the other three cannot catch its failure:

  Leg 1  MAP EQUALITY. dict(python_map) == dict(node_map) over KEYS AND VALUES, in
         both directions. Catches a key or a {verb, artifact} pair changed on one
         side only.
  Leg 2  RESOLVER AGREEMENT. resolve_kind(n) == resolveKind(n) over the UNION of
         both key sets (plus two fixed probes). Leg 1 compares the DATA; leg 2
         compares the CODE that reads it -- a divergent label-formatting rule
         (capitalisation, the hyphen->space rewrite, the empty-artifact case)
         leaves both maps identical and still renders differently.
  Leg 3  CATALOGUE COVERAGE. Every `^  - name:` row in shortcut-catalog.yml has a
         key in both maps. ONE-DIRECTIONAL DELIBERATELY: the maps are a documented
         strict SUPERSET of the catalogue -- state_schema.py's own header says they
         include "every catalogue row plus every historical name ever written into
         durable pipeline.initiator frontmatter" -- so a key with no catalogue row
         is a compatibility surface, not drift, and must never be swept. A
         catalogue row with no key is the drift. LEG 3 IS THE ONLY LEG THAT CATCHES
         SYMMETRIC ERROR: if both twins are equally wrong, legs 1 and 2 pass.
  Leg 4  THE aid-describe SPECIAL CASE. Both readers resolve `aid-describe` OUTSIDE
         the map -- `_FULL_PATH_INITIATOR` in state_schema.py, `FULL_PATH_INITIATOR`
         in reader.mjs. It is therefore in neither map (outside leg 2's key-set
         union proper), and it is not a catalogue row (outside leg 3's scan). It is
         the one name whose behaviour is hard-coded in both twins, which is exactly
         the kind of thing that diverges silently, so it gets its own named leg and
         is asserted non-None as well as equal (two Nones would agree vacuously).

PERMANENT NEGATIVE CONTROLS, not a one-off manual proof. A guard that has only ever
been seen green is a guard nobody has seen work. Both controls below are ordinary
tests that run on EVERY CI invocation, and both mutate COPIES under mktemp -- never
the repository's own files:

  P1   ONE-SIDED: delete one key from the copied reader.mjs. Legs 1 and 2 MUST fail.
  P1b  TWO-SIDED: delete the same key from BOTH copied twins. Leg 1 MUST pass (the
       twins still agree) and LEG 3 MUST FAIL. If leg 3 passed here, leg 3 would be
       worthless, and that is the whole point of this control.
  P1c  ONE-SIDED VALUE: keep the key, rewrite only its {verb, artifact} pair in the
       copied reader.mjs. Legs 1 and 2 MUST fail and LEG 3 MUST PASS. P1/P1b only
       ever delete a KEY, so without P1c leg 1's VALUE comparison would never have
       been exercised, and a leg 1 rewritten to compare key sets alone would still
       pass everything else here. It is also the proof that leg 3 cannot substitute
       for leg 1: the catalogue row is still covered while the twins disagree.

The mutation key is DERIVED, not hard-coded -- the lexicographically first catalogue
row that is also a map key -- so retiring any single skill cannot silently disable
the controls. It must be a catalogue row, because leg 3 can only be shown red by
removing a key the catalogue still needs.

Each control also asserts that its mutation actually removed the key from the
LOADED map, so a mutation that silently failed to apply cannot masquerade as a
demonstrated red.

HOW THE NODE TWIN IS READ, and two divergences recorded so a reviewer does not read
either as a defect:

  (a) Decision 1 says the Node map is read through "a short-lived `node -e`
      subprocess" and claims to follow test_resolve_work_dir_cross_runtime_parity.py
      exactly. Measured: that precedent does NOT use `node -e` -- it writes a
      temporary driver.mjs into a tempdir and runs `node <driver>`. This module
      follows the PRECEDENT, not the prose: a driver file is quoting-safe across
      shells and is the form already proven in this repository.
  (b) `SHORTCUT_KIND_MAP` is `export`ed from reader.mjs (delivery-001 task-008), so
      the map is imported directly -- re-implementing a JavaScript object parser to
      read it is explicitly rejected (feature-005 Decision 3, feature-006 risk 7)
      and is not done here. `resolveKind`, however, is NOT exported, and leg 2 and
      leg 4 need it. Rather than edit a product file (feature-006 writes none), this
      module builds a PROBE MODULE: the reader's own source bytes, verbatim, with a
      single `export { resolveKind };` line appended, written to a scratch file and
      imported there. That is the in-repo precedent set by
      dashboard/server/tests/test_write_enabled_cross_runtime_parity.py, which does
      the same thing to reach server.mjs's unexported functions. It EXECUTES the
      real bytes -- it does not parse or re-implement them -- so an edit to
      resolveKind is exactly what this module proves parity against. If a future
      revision exports resolveKind, the append is skipped automatically.

Copying a single file is safe here, and that is asserted rather than assumed:
TestSingleFileCopySafety fails loudly if either twin ever grows a relative import,
because the mutation legs would then need to copy the whole directory.

Requires `node` on PATH for every cross-runtime leg; the parity and control classes
SKIP with a recorded reason when it is absent. A parity test that quietly passes
because one runtime was missing is worse than no test at all.

Python 3.11+ stdlib only. No third-party deps. No network, no wall-clock, no $HOME
dependence; every comparison is by set/mapping equality or over a sorted list, so
no result depends on iteration order.
"""

from __future__ import annotations

import importlib.util
import json
import re
import shutil
import subprocess
import tempfile
import unittest
import uuid
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # dashboard/reader/tests/ -> AID/

_PY_TWIN = _REPO_ROOT / "dashboard" / "reader" / "state_schema.py"
_JS_TWIN = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"
_CATALOG = _REPO_ROOT / "canonical" / "aid" / "templates" / "shortcut-catalog.yml"

# The FULL-pipeline starting skill: in neither map, hard-coded in both twins (leg 4).
_FULL_PATH_NAME = "aid-describe"
# A name that is in neither map and is not a catalogue row -- both runtimes must
# return null/None. Keeps leg 2 from being satisfiable by a resolver that returns a
# constant.
_UNKNOWN_NAME = "aid-not-a-real-skill-zzz"

_NODE_TIMEOUT = 60

# Appended to a verbatim copy of reader.mjs to reach the unexported resolveKind.
# See the module docstring, divergence (b).
_RESOLVE_KIND_EXPORT = "\nexport { resolveKind };\n"

_NODE_DRIVER = """
import { pathToFileURL } from "node:url";
import { readFileSync } from "node:fs";

const [, , readerPath, extraNamesPath] = process.argv;
const mod = await import(pathToFileURL(readerPath).href);

if (typeof mod.SHORTCUT_KIND_MAP !== "object" || mod.SHORTCUT_KIND_MAP === null) {
  throw new Error("SHORTCUT_KIND_MAP is not exported from " + readerPath);
}
if (typeof mod.resolveKind !== "function") {
  throw new Error("resolveKind is not reachable from " + readerPath);
}

const extra = JSON.parse(readFileSync(extraNamesPath, "utf8"));
const names = Array.from(
  new Set([...Object.keys(mod.SHORTCUT_KIND_MAP), ...extra])
).sort();

const kinds = {};
for (const n of names) kinds[n] = mod.resolveKind(n);

process.stdout.write(JSON.stringify({ map: mod.SHORTCUT_KIND_MAP, kinds }));
"""


# ---------------------------------------------------------------------------
# Availability
# ---------------------------------------------------------------------------

def _node_available() -> bool:
    try:
        r = subprocess.run(["node", "--version"], capture_output=True, timeout=10)
        return r.returncode == 0
    except Exception:
        return False


_NODE_AVAILABLE = _node_available()
_NODE_SKIP_REASON = (
    "node not available on PATH -- the SHORTCUT_KIND_MAP cross-runtime parity legs "
    "cannot run; SKIPPED rather than passed, because a parity test that passes "
    "vacuously is the failure this guard exists to prevent"
)


# ---------------------------------------------------------------------------
# Byte-faithful file IO (no newline translation in either direction: the copies
# these helpers make must be the twins' own bytes, not a Windows re-encode)
# ---------------------------------------------------------------------------

def _read_exact(path: Path) -> str:
    with open(path, "r", encoding="utf-8", newline="") as fh:
        return fh.read()


def _write_exact(path: Path, text: str) -> None:
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(text)


# ---------------------------------------------------------------------------
# The two twins, each loadable from an ARBITRARY path. Parameterised deliberately:
# a comparison hard-wired to the repository's own two files could not be pointed at
# a mutated copy, and the negative controls would then be unimplementable.
# ---------------------------------------------------------------------------

def _load_python_twin(py_path: Path):
    """Load a state_schema.py (real or copied) and return (map, resolve_kind)."""
    # Unique module name: never a stdlib name, and never reused, so a second load
    # of a MUTATED copy cannot be served from an earlier load's cache.
    mod_name = "aid_state_schema_probe_" + uuid.uuid4().hex
    spec = importlib.util.spec_from_file_location(mod_name, str(py_path))
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load Python twin from {py_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return dict(module.SHORTCUT_KIND_MAP), module.resolve_kind


def _node_probe_module(js_path: Path, dest_dir: Path) -> Path:
    """Write the reader's own source bytes, verbatim, plus a single
    `export { resolveKind };` line, into dest_dir. See docstring divergence (b)."""
    src = _read_exact(js_path)
    if "function resolveKind" not in src:
        raise RuntimeError(
            f"resolveKind is not declared in {js_path} -- the probe cannot be built. "
            "If the function was renamed, this module must be updated in lockstep."
        )
    already_exported = bool(
        re.search(r"^export\s+function\s+resolveKind\b", src, re.M)
        or re.search(r"^export\s*\{[^}]*\bresolveKind\b[^}]*\}", src, re.M)
    )
    if not already_exported:
        src += _RESOLVE_KIND_EXPORT
    probe = dest_dir / "reader_probe.mjs"
    _write_exact(probe, src)
    return probe


def _node_side(js_path: Path, scratch: Path, extra_names: list) -> dict:
    """Run the Node twin in a short-lived subprocess (no server spawn, no port
    binding) and return {'map': {...}, 'kinds': {...}}."""
    probe = _node_probe_module(js_path, scratch)
    driver = scratch / "driver.mjs"
    _write_exact(driver, _NODE_DRIVER)
    names_file = scratch / "extra-names.json"
    _write_exact(names_file, json.dumps(sorted(extra_names)))

    proc = subprocess.run(
        ["node", str(driver), str(probe), str(names_file)],
        capture_output=True, text=True, timeout=_NODE_TIMEOUT,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"node driver failed (exit {proc.returncode}) for {js_path}: {proc.stderr}"
        )
    payload = json.loads(proc.stdout)
    # JSON arrays -> tuples, so the comparison against Python's tuple values is a
    # value comparison and not a type mismatch dressed up as drift.
    payload["map"] = {k: tuple(v) for k, v in payload["map"].items()}
    return payload


def _catalog_row_names(catalog_path: Path) -> list:
    """Every `  - name: <x>` row in shortcut-catalog.yml, sorted."""
    names = []
    with open(catalog_path, "r", encoding="utf-8", newline="") as fh:
        for line in fh:
            m = re.match(r"^  - name:\s*(\S+)\s*$", line)
            if m:
                names.append(m.group(1))
    return sorted(names)


# ---------------------------------------------------------------------------
# The four legs, as pure data. Returning verdicts instead of raising is what lets
# the negative controls assert that a leg FAILED.
# ---------------------------------------------------------------------------

def run_legs(py_path: Path, js_path: Path, catalog_path: Path, scratch: Path) -> dict:
    py_map, py_resolve = _load_python_twin(py_path)
    probe_names = sorted(set(py_map) | {_FULL_PATH_NAME, _UNKNOWN_NAME})
    node = _node_side(js_path, scratch, probe_names)
    node_map, node_kinds = node["map"], node["kinds"]

    report = {"py_key_count": len(py_map), "node_key_count": len(node_map)}

    # -- Leg 1: map equality over keys AND values, both directions.
    only_py = sorted(set(py_map) - set(node_map))
    only_node = sorted(set(node_map) - set(py_map))
    mismatched = sorted(
        f"{k}: python={py_map[k]!r} node={node_map[k]!r}"
        for k in (set(py_map) & set(node_map))
        if py_map[k] != node_map[k]
    )
    report["leg1_ok"] = not (only_py or only_node or mismatched)
    report["leg1_detail"] = (
        f"keys only in state_schema.py: {only_py}; "
        f"keys only in reader.mjs: {only_node}; "
        f"values that differ: {mismatched}"
    )

    # -- Leg 2: resolver agreement over the union of both key sets + the two probes.
    union = sorted(set(py_map) | set(node_map) | {_FULL_PATH_NAME, _UNKNOWN_NAME})
    disagreements = []
    for name in union:
        py_kind = py_resolve(name)
        node_kind = node_kinds.get(name, "<not resolved by the node driver>")
        if py_kind != node_kind:
            disagreements.append(f"{name}: python={py_kind!r} node={node_kind!r}")
    report["leg2_ok"] = not disagreements
    report["leg2_compared"] = len(union)
    report["leg2_detail"] = f"{len(disagreements)} disagreement(s): {disagreements}"
    # The two fixed probes must sit OUTSIDE both maps, or they add nothing: an
    # aid-describe that had become an ordinary map key would make leg 4 a duplicate
    # of leg 2, and an _UNKNOWN_NAME that resolved would stop proving that a miss
    # returns None/null in both runtimes.
    report["probes_outside_maps"] = not any(
        p in m for p in (_FULL_PATH_NAME, _UNKNOWN_NAME) for m in (py_map, node_map)
    )

    # -- Leg 3: one-directional catalogue coverage.
    rows = _catalog_row_names(catalog_path)
    missing_py = sorted(r for r in rows if r not in py_map)
    missing_node = sorted(r for r in rows if r not in node_map)
    report["leg3_ok"] = not (missing_py or missing_node)
    report["leg3_rows"] = len(rows)
    report["leg3_detail"] = (
        f"catalogue rows absent from state_schema.py: {missing_py}; "
        f"catalogue rows absent from reader.mjs: {missing_node}"
    )

    # -- Leg 4: the aid-describe special case.
    py_full = py_resolve(_FULL_PATH_NAME)
    node_full = node_kinds.get(_FULL_PATH_NAME, "<not resolved by the node driver>")
    report["leg4_ok"] = (py_full == node_full) and (py_full is not None)
    report["leg4_python"] = py_full
    report["leg4_node"] = node_full
    report["leg4_detail"] = (
        f"{_FULL_PATH_NAME}: python={py_full!r} node={node_full!r} "
        "(must agree AND must not be None -- two Nones would agree vacuously)"
    )

    return report


# ---------------------------------------------------------------------------
# Source mutation, applied to COPIES only.
# ---------------------------------------------------------------------------

def _delete_js_key(text: str, key: str) -> "tuple[str, int]":
    """Delete the `"<key>": [...],` entry from a COPY of reader.mjs.
    Returns (mutated_text, number_of_entries_removed)."""
    pattern = re.compile(
        r'^[ \t]*"' + re.escape(key) + r'"[ \t]*:[ \t]*\[[^\]]*\],?[ \t]*\r?\n', re.M
    )
    return pattern.subn("", text)


def _delete_py_key(text: str, key: str) -> "tuple[str, int]":
    """Delete the `"<key>": (...),` entry from a COPY of state_schema.py.
    Returns (mutated_text, number_of_entries_removed)."""
    pattern = re.compile(
        r'^[ \t]*"' + re.escape(key) + r'"[ \t]*:[ \t]*\([^)]*\),?[ \t]*\r?\n', re.M
    )
    return pattern.subn("", text)


_VALUE_CONTROL_PAIR = '["mutated-verb", "mutated-artifact"]'


def _change_js_value(text: str, key: str) -> "tuple[str, int]":
    """Rewrite the {verb, artifact} PAIR of `"<key>"` in a COPY of reader.mjs,
    leaving the key itself in place. Returns (mutated_text, entries_rewritten)."""
    pattern = re.compile(
        r'(^[ \t]*"' + re.escape(key) + r'"[ \t]*:[ \t]*)\[[^\]]*\]', re.M
    )
    return pattern.subn(r"\1" + _VALUE_CONTROL_PAIR, text)


class _ScratchMixin(unittest.TestCase):
    """mktemp scratch space, removed on cleanup and CONFIRMED gone afterwards."""

    def scratch(self) -> Path:
        d = Path(tempfile.mkdtemp(prefix="aid-kindmap-parity-"))
        # unittest runs cleanups LIFO, so registering the assertion FIRST makes it
        # run LAST -- after the removal it is checking.
        self.addCleanup(self._assert_removed, d)
        self.addCleanup(shutil.rmtree, str(d), True)
        return d

    def _assert_removed(self, d: Path) -> None:
        self.assertFalse(d.exists(), f"scratch directory was not removed: {d}")


# ---------------------------------------------------------------------------

class TestSingleFileCopySafety(unittest.TestCase):
    """The mutation legs copy ONE file per twin to a tempdir. That is only valid
    while neither twin has a relative import to drag along. Measured, not assumed --
    if this fails, the mutation legs must copy the DIRECTORY instead."""

    # Each check below is a claimed ZERO, and a silently-broken pattern reads exactly
    # like a clean result -- so each is positive-controlled against a synthetic line
    # that MUST match before the real zero is trusted.
    _JS_RELATIVE_IMPORT = r'(?:from|import)\s*\(?\s*["\']\.\.?/'
    _PY_RELATIVE_IMPORT = r"^\s*(?:from\s+\.|import\s+\.)"

    def test_node_twin_has_no_relative_import(self):
        self.assertTrue(
            re.findall(self._JS_RELATIVE_IMPORT,
                       'import x from "./sibling.mjs";\nawait import("../up.mjs");'),
            "positive control: the relative-import pattern must match a real one",
        )
        src = _read_exact(_JS_TWIN)
        hits = re.findall(self._JS_RELATIVE_IMPORT, src)
        self.assertEqual(
            hits, [],
            f"{_JS_TWIN} grew a relative import {hits} -- single-file copying is no "
            "longer safe; the mutation legs must copy the directory instead",
        )

    def test_python_twin_has_no_relative_import(self):
        self.assertTrue(
            re.findall(self._PY_RELATIVE_IMPORT,
                       "from .sibling import thing\nimport .other", re.M),
            "positive control: the relative-import pattern must match a real one",
        )
        src = _read_exact(_PY_TWIN)
        hits = re.findall(self._PY_RELATIVE_IMPORT, src, re.M)
        self.assertEqual(
            hits, [],
            f"{_PY_TWIN} grew a relative import -- single-file copying is no longer "
            "safe; the mutation legs must copy the directory instead",
        )

    def test_node_twin_exports_the_map(self):
        """task-001's precondition 6, re-asserted here so a revision that removes
        the `export` fails THIS test with a clear message rather than failing the
        parity legs with an opaque one. The correct response to a red here is to
        restore the export -- never to parse the object literal out of the source."""
        src = _read_exact(_JS_TWIN)
        # assertTrue over an explicit re.M search rather than assertRegex: assertRegex
        # is unanchored-by-line (no re.M) AND echoes the entire 5 000-line source into
        # the failure message, which buries the finding.
        self.assertIsNotNone(
            re.search(r"^export const SHORTCUT_KIND_MAP\s*=", src, re.M),
            f"{_JS_TWIN} must export SHORTCUT_KIND_MAP (feature-005 Decision 3)",
        )


@unittest.skipUnless(_NODE_AVAILABLE, _NODE_SKIP_REASON)
class TestShortcutKindMapCrossRuntimeParity(_ScratchMixin):
    """The four legs, against the repository's own two twins."""

    @classmethod
    def setUpClass(cls):
        cls._tmp = Path(tempfile.mkdtemp(prefix="aid-kindmap-parity-real-"))
        try:
            cls.report = run_legs(_PY_TWIN, _JS_TWIN, _CATALOG, cls._tmp)
        finally:
            shutil.rmtree(str(cls._tmp), ignore_errors=True)

    @classmethod
    def tearDownClass(cls):
        # `raise`, not `assert`: an assert statement is compiled out under python -O.
        if cls._tmp.exists():
            raise AssertionError(f"scratch directory was not removed: {cls._tmp}")

    def test_leg1_map_equality_keys_and_values_both_directions(self):
        self.assertTrue(
            self.report["leg1_ok"],
            "LEG 1 (map equality) -- state_schema.py and reader.mjs disagree. "
            + self.report["leg1_detail"],
        )
        # Non-vacuity: an empty map on both sides would compare equal.
        self.assertGreater(self.report["py_key_count"], 0, "python map is empty")
        self.assertEqual(self.report["py_key_count"], self.report["node_key_count"])

    def test_leg2_resolver_agreement_over_the_key_set_union(self):
        self.assertTrue(
            self.report["leg2_ok"],
            "LEG 2 (resolver agreement) -- resolve_kind and resolveKind disagree. "
            + self.report["leg2_detail"],
        )
        self.assertGreater(
            self.report["leg2_compared"], self.report["py_key_count"],
            "leg 2 must compare the key-set UNION plus the two fixed probes",
        )
        self.assertTrue(
            self.report["probes_outside_maps"],
            f"fixture sanity: {_FULL_PATH_NAME!r} and {_UNKNOWN_NAME!r} must be in "
            "NEITHER map -- see leg 4's rationale",
        )

    def test_leg3_every_catalogue_row_has_a_key_one_directional(self):
        self.assertTrue(
            self.report["leg3_ok"],
            "LEG 3 (catalogue coverage) -- a shortcut-catalog.yml row has no "
            "SHORTCUT_KIND_MAP key. " + self.report["leg3_detail"],
        )
        self.assertGreater(self.report["leg3_rows"], 0, "catalogue scan found no rows")
        # One-directional deliberately: the maps are a documented strict SUPERSET of
        # the catalogue (historical pipeline.initiator names). Asserting the reverse
        # containment would demand deleting a live compatibility surface.
        self.assertGreaterEqual(
            self.report["py_key_count"], self.report["leg3_rows"],
            "the map is documented as a superset of the catalogue",
        )

    def test_leg4_aid_describe_resolves_identically_in_both_runtimes(self):
        self.assertTrue(
            self.report["leg4_ok"],
            "LEG 4 (aid-describe) -- " + self.report["leg4_detail"],
        )


@unittest.skipUnless(_NODE_AVAILABLE, _NODE_SKIP_REASON)
class TestShortcutKindMapNegativeControls(_ScratchMixin):
    """The demonstrated red, as PERMANENT tests: re-proved on every CI run rather
    than recorded once in a work folder that is transient by standing rule.

    FOUR controls, not two: three mutating (one-sided deletion, two-sided deletion,
    one-sided value change) plus a proof that the repository twins are untouched by
    the other three. The three mutating controls act only on COPIES under mktemp;
    none of the four writes to the repository -- which is what the fourth exists to
    demonstrate rather than assert.

    Do not re-describe this set by counting from prose. Derive it:
    `grep -cE '^    def test_' <this file>` gives the module total, and the class
    boundaries give the split (4 legs + 4 negative controls + 3 copy-safety = 11).
    An earlier "Both controls" reading here propagated a 4+3+3 miscount into three
    separate work-folder records before anyone counted the methods."""

    def _mutation_key(self) -> str:
        """A catalogue row that is also a map key, chosen deterministically (the
        lexicographically first) rather than hard-coded, so retiring any single
        skill cannot silently disable these controls. It MUST be a catalogue row:
        leg 3 can only be shown red by deleting a key the catalogue still needs."""
        rows = set(_catalog_row_names(_CATALOG))
        py_map, _ = _load_python_twin(_PY_TWIN)
        both = sorted(rows & set(py_map))
        self.assertTrue(both, "no catalogue row is present in the map -- cannot mutate")
        return both[0]

    def _copy_twins(self, dest: Path) -> "tuple[Path, Path]":
        py_copy = dest / "state_schema_copy.py"
        js_copy = dest / "reader_copy.mjs"
        _write_exact(py_copy, _read_exact(_PY_TWIN))
        _write_exact(js_copy, _read_exact(_JS_TWIN))
        return py_copy, js_copy

    def test_p1_one_sided_deletion_makes_legs_1_and_2_fail(self):
        """Delete one key from the COPIED reader.mjs only. The twins now disagree,
        so leg 1 (map equality) and leg 2 (resolver agreement) must both fail."""
        tmp = self.scratch()
        key = self._mutation_key()
        py_copy, js_copy = self._copy_twins(tmp)

        mutated, n = _delete_js_key(_read_exact(js_copy), key)
        self.assertEqual(n, 1, f"expected to delete exactly one {key!r} entry, deleted {n}")
        _write_exact(js_copy, mutated)

        report = run_legs(py_copy, js_copy, _CATALOG, tmp)

        # The mutation reached the LOADED map -- not merely the source text.
        self.assertEqual(
            report["node_key_count"], report["py_key_count"] - 1,
            f"P1 mutation did not reach the loaded node map (key {key!r})",
        )
        self.assertFalse(
            report["leg1_ok"],
            f"P1: leg 1 passed against a one-sided deletion of {key!r} -- leg 1 is "
            "not detecting map drift. " + report["leg1_detail"],
        )
        self.assertIn(key, report["leg1_detail"])
        self.assertFalse(
            report["leg2_ok"],
            f"P1: leg 2 passed against a one-sided deletion of {key!r} -- leg 2 is "
            "not detecting resolver drift. " + report["leg2_detail"],
        )
        self.assertIn(key, report["leg2_detail"])
        # Leg 3 also fails here (the row lost its node key); that is expected and is
        # NOT what this control proves. P1b isolates leg 3.

    def test_p1b_two_sided_deletion_keeps_leg_1_green_and_makes_leg_3_fail(self):
        """Delete the SAME key from BOTH copied twins. The twins still agree, so
        leg 1 must PASS -- and leg 3 must FAIL, because the catalogue row it served
        no longer resolves. If leg 3 passed here, leg 3 would be worthless: it is
        the only leg that catches an error made identically on both sides."""
        tmp = self.scratch()
        key = self._mutation_key()
        py_copy, js_copy = self._copy_twins(tmp)

        mutated_js, n_js = _delete_js_key(_read_exact(js_copy), key)
        self.assertEqual(n_js, 1, f"expected one {key!r} entry in the .mjs copy, found {n_js}")
        _write_exact(js_copy, mutated_js)

        mutated_py, n_py = _delete_py_key(_read_exact(py_copy), key)
        self.assertEqual(n_py, 1, f"expected one {key!r} entry in the .py copy, found {n_py}")
        _write_exact(py_copy, mutated_py)

        report = run_legs(py_copy, js_copy, _CATALOG, tmp)

        # Both mutations reached their LOADED maps.
        self.assertEqual(
            report["py_key_count"], report["node_key_count"],
            "P1b: the two-sided mutation left the maps different sizes",
        )
        self.assertTrue(
            report["leg1_ok"],
            "P1b: leg 1 failed on a SYMMETRIC deletion -- the twins still agree, so "
            "leg 1 is reporting drift that does not exist. " + report["leg1_detail"],
        )
        self.assertTrue(
            report["leg2_ok"],
            "P1b: leg 2 failed on a SYMMETRIC deletion -- both resolvers return None "
            "for the removed key, so they still agree. " + report["leg2_detail"],
        )
        self.assertFalse(
            report["leg3_ok"],
            f"P1b: leg 3 passed while catalogue row {key!r} had no key in EITHER map. "
            "Leg 3 is the only leg that catches symmetric error and it is not "
            "catching it. " + report["leg3_detail"],
        )
        self.assertIn(key, report["leg3_detail"])

    def test_p1c_one_sided_value_change_makes_legs_1_and_2_fail(self):
        """Leg 1 compares KEYS AND VALUES. P1 and P1b only ever delete a key, so
        without this third control leg 1's value comparison would never have been
        seen working, and a leg-1 rewritten to compare key SETS alone would still
        pass every other test in this file. Here the key stays and only its
        {verb, artifact} pair is rewritten on ONE side: leg 1 must fail on the value,
        leg 2 must fail on the label derived from it, and LEG 3 MUST STILL PASS --
        the catalogue row is still covered, which is exactly why leg 3 cannot
        substitute for leg 1."""
        tmp = self.scratch()
        key = self._mutation_key()
        py_copy, js_copy = self._copy_twins(tmp)

        mutated, n = _change_js_value(_read_exact(js_copy), key)
        self.assertEqual(n, 1, f"expected to rewrite exactly one {key!r} value, rewrote {n}")
        _write_exact(js_copy, mutated)

        report = run_legs(py_copy, js_copy, _CATALOG, tmp)

        # The mutation reached the LOADED map: same key count, different value.
        self.assertEqual(report["py_key_count"], report["node_key_count"])
        self.assertIn("mutated-verb", report["leg1_detail"])
        self.assertFalse(
            report["leg1_ok"],
            f"P1c: leg 1 passed while {key!r} carried a different value on each side "
            "-- leg 1 is comparing keys only, not values. " + report["leg1_detail"],
        )
        self.assertFalse(
            report["leg2_ok"],
            f"P1c: leg 2 passed while {key!r} resolved to a different label on each "
            "side. " + report["leg2_detail"],
        )
        self.assertTrue(
            report["leg3_ok"],
            "P1c: leg 3 failed on a value-only change -- it must not, and this is the "
            "proof that leg 3 cannot substitute for leg 1. " + report["leg3_detail"],
        )

    def test_repository_twins_are_untouched_by_the_controls(self):
        """The mechanical proof that no mutation escaped onto a product file: the
        two twins still hold the key the controls delete from their copies."""
        key = self._mutation_key()
        self.assertIn(f'"{key}"', _read_exact(_PY_TWIN))
        self.assertIn(f'"{key}"', _read_exact(_JS_TWIN))


if __name__ == "__main__":
    unittest.main(verbosity=2)
