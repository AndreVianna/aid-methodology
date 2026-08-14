"""test_state_yaml_conformance.py -- work-009-refactor task-005, Python twin.

The parity surface reduced to DATA (SPEC.md § L-4, enforcement leg 2): one
committed corpus of small `.yml` inputs under
`tests/canonical/fixtures/state-yaml-conformance/`, each paired with its
expected parsed value tree AND its expected `parse_warning` set. This module
is the PYTHON runner over that corpus -- it calls
`dashboard.reader.state_schema.parse_state_document` DIRECTLY (no subprocess,
no Node) and asserts BOTH the value tree and the warning list for every row,
so a divergence from the golden corpus is a failing row, not a silent field
difference.

Coverage, one input per row (see the corpus's own generator history / the
task-005 DETAIL.md Scope for the full enumeration): every permitted shape
S1-S5; the three § D-5 quoting modes (bare / single-quoted / double-quoted-
with-escapes), including a value carrying `|`, a newline, a colon, a `#` and
a quote; every implicit-typing deny-list literal (§ D-5 NFR-2) -- the parsed
value must be the string ON DISK, never coerced to bool/None by either
runtime; every § D-3 rejected construct (tab indentation, a non-literal flow
collection, a block scalar with each chomping suffix, an anchor, an alias, a
tag, a directive, a second document, odd indentation, over-deep nesting, a
line with no `key:` separator, a duplicate key, a BOM); and an absent key
versus an empty `[]` / `{}` collection.

The SIBLING runner, `test_state_yaml_conformance_node.py`, reads the SAME
corpus and drives `dashboard/server/reader.mjs`'s `parseStateDocument` via a
subprocess, so both runtimes are checked against the one shared ground truth
rather than against each other (a corpus-vs-runtime comparison here, in
BOTH runners independently, catches a bug shipped identically to both twins --
a mutual A-vs-B diff test could not).

Python 3.11+ stdlib only. No third-party deps. No network. Deterministic --
every row is a pure text -> value computation, no wall-clock, no filesystem
writes (the corpus is read-only from this runner's point of view).
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader.state_schema import parse_state_document  # noqa: E402
from dashboard.reader.tests.state_yaml_conformance_corpus import (  # noqa: E402
    CORPUS_DIR,
    load_rows,
)


class TestStateYamlConformanceCorpus(unittest.TestCase):
    """Corpus-health checks that are NOT row-specific -- run once, not once
    per row, so a corpus-wide problem (e.g. an empty directory) is reported
    as ONE clear failure rather than N confusing ones."""

    def test_corpus_directory_exists(self):
        self.assertTrue(
            CORPUS_DIR.is_dir(),
            f"corpus directory missing: {CORPUS_DIR}",
        )

    def test_corpus_is_non_empty_and_every_yml_has_an_expectation(self):
        rows = load_rows()
        self.assertGreater(len(rows), 0, "corpus loaded zero rows")
        # Every .yml must be paired with exactly one .expected.json -- and
        # nothing else should be sitting in the fixture directory unpaired.
        yml_stems = {p.stem for p in CORPUS_DIR.glob("*.yml")}
        json_stems = {p.stem for p in CORPUS_DIR.glob("*.expected.json")}
        # .expected.json files have stem "<row>.expected" via Path.stem
        # (only the LAST suffix is stripped), so re-derive the row stem.
        json_row_stems = {s[: -len(".expected")] for s in json_stems if s.endswith(".expected")}
        self.assertEqual(
            yml_stems, json_row_stems,
            "every corpus .yml must have exactly one matching .expected.json, "
            f"and vice versa. yml-only: {yml_stems - json_row_stems}, "
            f"json-only: {json_row_stems - yml_stems}",
        )


class TestStateYamlConformancePython(unittest.TestCase):
    """Row-by-row: dashboard.reader.state_schema.parse_state_document against
    every corpus row's golden (values, warnings) pair."""

    @classmethod
    def setUpClass(cls):
        cls.rows = load_rows()
        assert cls.rows, "corpus must not be empty"

    def test_every_row_matches_python_engine(self):
        for row in self.rows:
            with self.subTest(row=row.stem):
                actual_values, actual_warnings = parse_state_document(
                    row.yaml_text, file_label=row.file_label
                )
                self.assertEqual(
                    actual_values, row.expected_values,
                    f"[{row.stem}] value tree mismatch\n"
                    f"input:\n{row.yaml_text}\n"
                    f"expected: {row.expected_values}\n"
                    f"actual:   {actual_values}",
                )
                self.assertEqual(
                    actual_warnings, row.expected_warnings,
                    f"[{row.stem}] parse_warning mismatch\n"
                    f"input:\n{row.yaml_text}\n"
                    f"expected: {row.expected_warnings}\n"
                    f"actual:   {actual_warnings}",
                )

    def test_never_raises_on_any_row(self):
        """NFR7 -- parse_state_document must never raise, for any corpus row,
        REJECT-list or not."""
        for row in self.rows:
            with self.subTest(row=row.stem):
                try:
                    parse_state_document(row.yaml_text, file_label=row.file_label)
                except Exception as exc:  # noqa: BLE001
                    self.fail(f"[{row.stem}] parse_state_document raised: {exc!r}")

    def test_permitted_shape_rows_have_no_warnings(self):
        """AC-3: shape-/quoting-/typed- rows (every PERMITTED construct) must
        produce an empty warning set."""
        permitted_prefixes = ("shape-", "quoting-", "typed-")
        checked = 0
        for row in self.rows:
            if row.stem.startswith(permitted_prefixes):
                checked += 1
                with self.subTest(row=row.stem):
                    actual_values, actual_warnings = parse_state_document(
                        row.yaml_text, file_label=row.file_label
                    )
                    self.assertEqual(
                        actual_warnings, [],
                        f"[{row.stem}] permitted-construct row must warn nothing, "
                        f"got: {actual_warnings}",
                    )
        self.assertGreater(checked, 0, "no permitted-shape rows were found to check")

    def test_implicit_typing_rows_keep_the_string_on_disk(self):
        """NFR-2: every implicit-typing deny-list literal round-trips as the
        exact string on disk in the Python twin -- never coerced to a Python
        bool/None. This is the row set that makes the PyYAML-1.1 / js-yaml-1.2
        yes/no divergence (dashboard/reader/state_schema.py:229-239)
        structurally impossible: this parser never interprets a scalar's
        type at all, so there is nothing FOR a resolver version to diverge on."""
        typed_rows = [r for r in self.rows if r.stem.startswith("typed-")]
        self.assertEqual(len(typed_rows), 30, "expected exactly 30 implicit-typing rows")
        for row in typed_rows:
            with self.subTest(row=row.stem):
                actual_values, _ = parse_state_document(row.yaml_text, file_label=row.file_label)
                value = actual_values.get("typed_value")
                self.assertIsInstance(
                    value, str,
                    f"[{row.stem}] implicit-typing value must be a str, got {type(value)!r}",
                )
                self.assertEqual(value, row.expected_values["typed_value"])

    def test_rejected_construct_rows_skip_only_that_key(self):
        """AC-4: for every reject- row, the construct's own key is ABSENT
        from the result and the surrounding control_before/control_after (or
        equivalent) keys still parsed -- "skip exactly that key, keep parsing
        the rest" -- and exactly the expected warning(s) were emitted."""
        reject_rows = [r for r in self.rows if r.stem.startswith("reject-")]
        self.assertEqual(len(reject_rows), 19, "expected exactly 19 rejected-construct rows")
        for row in reject_rows:
            with self.subTest(row=row.stem):
                actual_values, actual_warnings = parse_state_document(
                    row.yaml_text, file_label=row.file_label
                )
                self.assertGreater(
                    len(actual_warnings), 0,
                    f"[{row.stem}] a rejected construct must emit at least one warning",
                )
                self.assertEqual(actual_values, row.expected_values)
                self.assertEqual(actual_warnings, row.expected_warnings)

    def test_absent_key_and_empty_collections_are_distinct_rows_parsed_consistently(self):
        """AC-6: an absent key, an empty `[]`, and an empty `{}` are each
        their own row; this asserts the raw-tree shape for each (None-via-
        `.get`, `[]`, `{}`) so the two twins can be checked identically
        against the SAME three golden shapes."""
        by_stem = {r.stem: r for r in self.rows}
        for stem in ("absent-key", "empty-collection-list", "empty-collection-map"):
            self.assertIn(stem, by_stem, f"missing corpus row {stem!r}")

        absent = by_stem["absent-key"]
        av, _ = parse_state_document(absent.yaml_text, file_label=absent.file_label)
        self.assertNotIn("target_key", av)
        self.assertIsNone(av.get("target_key"))

        empty_list = by_stem["empty-collection-list"]
        elv, _ = parse_state_document(empty_list.yaml_text, file_label=empty_list.file_label)
        self.assertEqual(elv.get("target_key"), [])

        empty_map = by_stem["empty-collection-map"]
        emv, _ = parse_state_document(empty_map.yaml_text, file_label=empty_map.file_label)
        self.assertEqual(emv.get("target_key"), {})

        # The AC-6 property itself: a caller that defaults an absent key to
        # an empty collection cannot distinguish "absent" from "empty" --
        # exactly the treat-them-the-same rule D-3 states.
        self.assertEqual(av.get("target_key", []), [])
        self.assertEqual(av.get("target_key", {}), {})


if __name__ == "__main__":
    unittest.main(verbosity=2)
