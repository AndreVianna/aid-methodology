"""state_yaml_conformance_corpus.py -- shared row loader for the task-005
cross-runtime YAML-subset conformance corpus.

NOT a test module itself (no `test_` prefix, so pytest does not collect it as
a test file) -- it is the ONE piece of loading logic shared by the two actual
runners (`test_state_yaml_conformance.py`, the Python twin, and
`test_state_yaml_conformance_node.py`, the Node twin) so that both read the
SAME on-disk corpus through the SAME code path. Building the load logic twice
would not duplicate the corpus itself (the corpus directory is still the one
and only fixture tree), but it would still invite the two loaders to drift in
how they interpret a row -- this module is the guard against that.

The corpus lives at `tests/canonical/fixtures/state-yaml-conformance/`
(SPEC.md work-009-refactor, task-005): one `<stem>.yml` input paired with one
`<stem>.expected.json` (`{"file_label": str, "values": <tree>, "warnings":
[str, ...]}`) per row.

Python 3.11+ stdlib only. No third-party deps. No network. No file I/O
side-effects beyond reading the corpus (read-only).
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import NamedTuple

CORPUS_DIR = (
    Path(__file__).resolve().parents[3]
    / "tests" / "canonical" / "fixtures" / "state-yaml-conformance"
)


class ConformanceRow(NamedTuple):
    stem: str
    yaml_text: str
    file_label: str
    expected_values: dict
    expected_warnings: list


def load_rows(corpus_dir: Path = CORPUS_DIR) -> "list[ConformanceRow]":
    """Load every `<stem>.yml` + `<stem>.expected.json` pair, sorted by stem
    for a deterministic, reproducible row order. Raises AssertionError (not a
    silent skip) if a `.yml` has no matching `.expected.json` -- a fixture
    with no expectation is a corpus defect, not an empty-warnings row."""
    rows: list[ConformanceRow] = []
    yml_paths = sorted(corpus_dir.glob("*.yml"))
    for yml_path in yml_paths:
        stem = yml_path.stem
        json_path = corpus_dir / f"{stem}.expected.json"
        if not json_path.exists():
            raise AssertionError(
                f"corpus row {stem!r} has {yml_path.name} but no "
                f"{json_path.name} -- every row needs both files"
            )
        # newline="" -- read the EXACT bytes-as-text the row was written with
        # (no universal-newline translation), so a cross-runtime comparison
        # is never confused by a platform line-ending rewrite.
        with open(yml_path, "r", encoding="utf-8", newline="") as fh:
            yaml_text = fh.read()
        with open(json_path, "r", encoding="utf-8", newline="") as fh:
            expected = json.load(fh)
        rows.append(ConformanceRow(
            stem=stem,
            yaml_text=yaml_text,
            file_label=expected["file_label"],
            expected_values=expected["values"],
            expected_warnings=expected["warnings"],
        ))
    return rows
