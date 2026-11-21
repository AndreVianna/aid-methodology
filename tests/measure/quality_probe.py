#!/usr/bin/env python3
"""Prepare a small docs task and grade objective checks without invoking a model.

Usage: python quality_probe.py prepare OUT | grade OUT/project
The project is disposable. Keep this grader outside the agent's workspace.
An automated pass is not an overall quality or visual-verification pass.
"""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import re

REQUEST = ("Refresh the release guide in site/release.html so a new maintainer can "
           "successfully follow the current release process. Improve the presentation, "
           "preserve the actual safety requirements, and verify the result. "
           "Do not publish, push, or add dependencies.")

PROJECT_CARD = """# Project card
The release tool is `release.py`; the maintainer guide is `site/release.html`.
The project knowledge is in `.aid/knowledge/release-process.md`.
Run `python -m unittest discover -s tests` for the existing tests.
"""

KB = """# Release process
Preview the proposed release first. A human maintainer must inspect it and explicitly
approve it before the local publish step. Publishing without approval is forbidden.
The local tool exposes preview, approve and publish; it does not upload anything.
The guide must explain the sequence on the page and keep the process table readable.
"""

TOOL = '''"""Local-only release simulator."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("action", choices=("preview", "approve", "publish"))
args = parser.parse_args()
approval = Path(".release-approved")
if args.action == "preview":
    print("Preview ready for human review")
elif args.action == "approve":
    approval.write_text("approved", encoding="utf-8")
    print("Approval recorded")
elif not approval.is_file():
    raise SystemExit("Human approval required")
else:
    print("Published locally; no upload")
'''

BASELINE = """<!doctype html><html lang="en"><head><title>Release</title></head>
<body><main><h1>Release</h1><p>See the source for details.</p>
<p>| Step | Result |</p><p>| --- | --- |</p></main></body></html>"""

# This example is used only by the grader's own tests; it is never copied into a trial.
EXAMPLE_COMPLETE = """<!doctype html><html lang="en"><head><title>Release</title></head>
<body><main><h1>Release</h1><ol>
<li>Preview and inspect the proposed release: <code>python release.py preview</code>.</li>
<li>A human maintainer reviews and records approval: <code>python release.py approve</code>.</li>
<li>Only after approval, publish locally: <code>python release.py publish</code>.</li>
</ol><table><thead><tr><th scope="col">Step</th><th scope="col">Result</th></tr></thead>
<tbody><tr><td>Preview</td><td>Review</td></tr></tbody></table></main></body></html>"""


def prepare(out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=False)
    project = out / "project"
    for directory in (project / "site", project / ".aid/knowledge", project / "tests"):
        directory.mkdir(parents=True, exist_ok=True)
    files = {".aid/knowledge/PROJECT.md": PROJECT_CARD,
             ".aid/knowledge/release-process.md": KB,
             "release.py": TOOL,
             "site/release.html": BASELINE,
             "tests/test_release.py": '''import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOL = Path(__file__).resolve().parents[1] / "release.py"

class ReleaseTests(unittest.TestCase):
    def test_publish_requires_approval(self):
        with tempfile.TemporaryDirectory() as tmp:
            call = lambda action: subprocess.run([sys.executable, str(TOOL), action], cwd=tmp, capture_output=True)
            self.assertNotEqual(call("publish").returncode, 0)
            self.assertEqual(call("preview").returncode, 0)
            self.assertEqual(call("approve").returncode, 0)
            self.assertEqual(call("publish").returncode, 0)
'''}
    for name, text in files.items():
        (project / name).write_text(text, encoding="utf-8")
    (out / "request.txt").write_text(REQUEST + "\n", encoding="utf-8")
    return project


class VisibleHTML(HTMLParser):
    """Collect visible-by-markup text; CSS/JS visibility requires a real browser."""
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.hidden = 0
        self.stack = []
        self.text = []
        self.prose = []
        self.tables = []

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        hidden = (tag in {"script", "style", "template"} or "hidden" in values or
                  values.get("aria-hidden") == "true" or
                  bool(re.search(r"display\s*:\s*none|visibility\s*:\s*hidden", values.get("style", ""), re.I)))
        if tag not in {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}:
            self.stack.append((tag, hidden))
            self.hidden += int(hidden)
        if not self.hidden:
            if tag == "table": self.tables.append({"header": False, "data": False})
            if tag == "th" and values.get("scope") in {"col", "row"} and self.tables and any(t == "table" for t, _ in self.stack):
                self.tables[-1]["header"] = True
            if tag in {"p", "li", "div", "tr", "br"}: self.prose.append("\n")

    def handle_endtag(self, tag):
        for index in range(len(self.stack) - 1, -1, -1):
            if self.stack[index][0] == tag:
                for _, hidden in self.stack[index:]: self.hidden -= int(hidden)
                del self.stack[index:]
                break
        if tag in {"p", "li", "div", "tr"}: self.prose.append("\n")

    def handle_data(self, data):
        if self.hidden: return
        self.text.append(data)
        if data.strip() and self.tables and any(tag == "td" for tag, _ in self.stack) and any(tag == "table" for tag, _ in self.stack):
            self.tables[-1]["data"] = True
        if not any(tag in {"pre", "code"} for tag, _ in self.stack): self.prose.append(data)


def grade(project):
    page = Path(project) / "site/release.html"
    if not page.is_file():
        return {"automated_pass": False, "error": "guide missing", "browser_visual": "not_run"}
    parser = VisibleHTML()
    parser.feed(page.read_text(encoding="utf-8"))
    text = " ".join(" ".join(parser.text).lower().split())
    commands = re.findall(r"\bpython(?:3(?:\.\d+)?)?\s+release\.py\s+(preview|approve|publish)\b", text)
    remaining = iter(commands)
    workflow = all(any(actual == expected for actual in remaining) for expected in ("preview", "approve", "publish"))
    human = bool(re.search(r"\b(human|maintainer|person)\b", text)) and "approval" in text
    raw = bool(re.search(r"(?m)^\s*\|?\s*:?-{3,}:?\s*\|(?:\s*:?-{3,}:?\s*\|?)+\s*$", "".join(parser.prose)))
    tool = Path(project) / "release.py"
    unchanged = (not tool.is_symlink() and tool.is_file() and
                 hashlib.sha256(tool.read_bytes().replace(b"\r\n", b"\n")).digest() ==
                 hashlib.sha256(TOOL.encode("utf-8")).digest())
    checks = {"ordered_workflow": workflow, "human_approval_mentioned": human,
              "semantic_table": any(table["header"] and table["data"] for table in parser.tables),
              "no_raw_table_separator": not raw, "release_tool_unchanged": unchanged}
    return {"automated_pass": all(checks.values()), "outcome_checks": checks,
            "browser_visual": "not_run", "semantic_quality": "manual_review_required",
            "note": "Static checks are partial; inspect rendered output and the reasoning and evidence separately."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("prepare", "grade"))
    parser.add_argument("path", type=Path)
    args = parser.parse_args()
    if args.action == "prepare":
        print(json.dumps({"project": str(prepare(args.path)), "request": REQUEST}))
    else:
        result = grade(args.path)
        print(json.dumps(result))
        return 0 if result["automated_pass"] else 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
