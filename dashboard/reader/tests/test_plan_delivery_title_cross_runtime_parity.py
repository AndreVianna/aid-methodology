"""
test_plan_delivery_title_cross_runtime_parity.py -- CROSS-RUNTIME parity for the
delivery-title source after BLUEPRINT.md was retired.

The delivery definition -- objective, scope, gate criteria, and its title -- moved
into the delivery's own stanza in PLAN.md. Both reader twins therefore grew a stanza
parser, and both must agree on every input: reader.py's `_parse_plan_delivery_titles`
and reader.mjs's `_parsePlanDeliveryTitles`.

Why this file exists rather than a Python-only test. Three scalar-form divergences
were already found in this project between a hand-rolled bash YAML reader and these
same two twins -- CRLF, single quotes, and an inline comment -- each of which
silently misclassified a work while every branch returned a value. Two regex
implementations of the same grammar in two languages is the identical hazard: Python's
`re` and JavaScript's RegExp differ on enough details (character classes, lazy
quantifiers, unicode) that agreement has to be asserted, not assumed.

The fixtures deliberately include the cases where the two engines could plausibly
part company:
  - both stanza spellings (nested `### delivery-NNN: Title`, flattened
    `- **Delivery:** delivery-NNN -- Title`), since the flattened PLAN.md emits no
    `### delivery-NNN` heading by design
  - all three dash forms in the bullet spelling, including the EN/EM dash a writer
    or an editor's smart-punctuation may produce
  - an unfilled `{Name}` placeholder, which must yield no title rather than showing
    the braces
  - a duplicate heading, where first-wins must hold identically
  - a title containing its own colon, which a greedy pattern would truncate
  - `# delivery-001: x` at H1, which must NOT match (the stanza is H2 or deeper)

Bounded compute only: the Node side is a short-lived `node` subprocess, no server
spawn and no port binding, matching test_resolve_work_dir_cross_runtime_parity.py.
"""

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[3]   # dashboard/reader/tests/ -> AID/
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader.reader import _parse_plan_delivery_titles

_READER_MJS = _REPO_ROOT / "dashboard" / "server" / "reader.mjs"

_NODE_DRIVER = """
import { pathToFileURL } from "node:url";
const [, , readerPath, fixturesPath] = process.argv;
const fs = await import("node:fs");
const mod = await import(pathToFileURL(readerPath).href);
const fixtures = JSON.parse(fs.readFileSync(fixturesPath, "utf8"));
const out = {};
for (const [name, text] of Object.entries(fixtures)) {
  out[name] = mod._parsePlanDeliveryTitles(text);
}
process.stdout.write(JSON.stringify(out));
"""

# name -> PLAN.md excerpt
FIXTURES = {
    "nested_heading": "### delivery-001: User Authentication\n",
    "nested_multi": (
        "## Deliverables\n\n"
        "### delivery-001: First Thing\n- **Priority:** Must\n\n"
        "### delivery-002: Second Thing\n"
    ),
    "deeper_heading": "#### delivery-003: Deeper Heading\n",
    "h1_must_not_match": "# delivery-001: Top Level\n",
    "flat_bullet_double_hyphen": "- **Delivery:** delivery-001 -- Flattened Title\n",
    "flat_bullet_em_dash": "- **Delivery:** delivery-001 \u2014 Em Dash Title\n",
    "flat_bullet_single_hyphen": "- **Delivery:** delivery-001 - Single Hyphen\n",
    "star_bullet": "* **Delivery:** delivery-002 -- Star Bullet\n",
    "placeholder_heading": "### delivery-001: {Name}\n",
    "placeholder_bullet": "- **Delivery:** delivery-001 -- {Name}\n",
    "no_title_after_colon": "### delivery-001:\n",
    "duplicate_heading_first_wins": (
        "### delivery-001: First Wins\n### delivery-001: Second Loses\n"
    ),
    "uppercase_id": "### DELIVERY-001: Upper Case Id\n",
    "trailing_whitespace": "### delivery-001: Padded Title   \n",
    "colon_inside_title": "### delivery-001: Thing: With Colon\n",
    "empty": "",
    "no_stanza_at_all": "# Plan\n\n## Execution Graph\n\n| Task | Depends On |\n",
}


def _node_available() -> bool:
    try:
        proc = subprocess.run(["node", "--version"], capture_output=True, timeout=5)
        return proc.returncode == 0
    except Exception:  # noqa: BLE001
        return False


_NODE_AVAILABLE = _node_available()


def _node_titles(fixtures: dict) -> dict:
    """Run reader.mjs's _parsePlanDeliveryTitles over every fixture in one subprocess."""
    tmp = Path(tempfile.mkdtemp())
    try:
        driver = tmp / "driver.mjs"
        driver.write_text(_NODE_DRIVER, encoding="utf-8")
        payload = tmp / "fixtures.json"
        payload.write_text(json.dumps(fixtures), encoding="utf-8")
        proc = subprocess.run(
            ["node", str(driver), str(_READER_MJS), str(payload)],
            capture_output=True, text=True, timeout=30,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"node driver failed (exit {proc.returncode}): {proc.stderr}")
        return json.loads(proc.stdout)
    finally:
        shutil.rmtree(str(tmp), ignore_errors=True)


class TestPlanDeliveryTitleParity(unittest.TestCase):

    def test_python_side_expected_values(self):
        """Pin the Python twin's answers, so parity cannot be satisfied by BOTH
        runtimes being wrong in the same way."""
        self.assertEqual(
            _parse_plan_delivery_titles(FIXTURES["nested_heading"]),
            {"delivery-001": "User Authentication"},
        )
        self.assertEqual(
            _parse_plan_delivery_titles(FIXTURES["nested_multi"]),
            {"delivery-001": "First Thing", "delivery-002": "Second Thing"},
        )
        self.assertEqual(
            _parse_plan_delivery_titles(FIXTURES["flat_bullet_double_hyphen"]),
            {"delivery-001": "Flattened Title"},
        )
        self.assertEqual(
            _parse_plan_delivery_titles(FIXTURES["colon_inside_title"]),
            {"delivery-001": "Thing: With Colon"},
        )
        self.assertEqual(
            _parse_plan_delivery_titles(FIXTURES["duplicate_heading_first_wins"]),
            {"delivery-001": "First Wins"},
        )
        # An unfilled scaffold has no title; the braces must never reach the UI.
        self.assertEqual(_parse_plan_delivery_titles(FIXTURES["placeholder_heading"]), {})
        self.assertEqual(_parse_plan_delivery_titles(FIXTURES["placeholder_bullet"]), {})
        # H1 is the document title, not a delivery stanza.
        self.assertEqual(_parse_plan_delivery_titles(FIXTURES["h1_must_not_match"]), {})
        self.assertEqual(_parse_plan_delivery_titles(FIXTURES["no_title_after_colon"]), {})
        self.assertEqual(_parse_plan_delivery_titles(FIXTURES["empty"]), {})
        self.assertEqual(_parse_plan_delivery_titles(FIXTURES["no_stanza_at_all"]), {})

    @unittest.skipUnless(_NODE_AVAILABLE, "node not available")
    def test_both_runtimes_agree_on_every_fixture(self):
        node_out = _node_titles(FIXTURES)
        mismatches = []
        for name, text in FIXTURES.items():
            py = _parse_plan_delivery_titles(text)
            nd = node_out.get(name)
            if py != nd:
                mismatches.append(f"{name}: python={py!r} node={nd!r}")
        self.assertEqual(
            mismatches, [],
            "reader.py and reader.mjs disagree on the PLAN.md delivery stanza:\n  "
            + "\n  ".join(mismatches),
        )


if __name__ == "__main__":
    unittest.main()
