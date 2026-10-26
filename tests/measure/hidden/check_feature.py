"""check_feature.py <project> -- hidden check for the feature scenario: `list` has an option that lists the notes
newest first, and without it the order stays oldest first.

The option's name is the agent's choice: it is found in `list --help` by a word such as newest, recent, latest,
reverse or desc. Run by measure.py after the session, outside the agent's view. Exit 0 on pass, 1 on fail.
"""

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def main() -> int:
    project = Path(sys.argv[1]).resolve()
    env = dict(os.environ, PYTHONPATH=str(project / "src"))
    with tempfile.TemporaryDirectory() as folder:
        run = lambda *args: subprocess.run([sys.executable, "-m", "notes", *args], cwd=folder, env=env,
                                           capture_output=True, text=True)
        notes = [{"id": i, "text": t, "created": f"2026-01-0{i}T00:00:00+00:00"} for i, t in ((1, "a"), (2, "b"), (3, "c"))]
        Path(folder, "notes.json").write_text(json.dumps(notes), encoding="utf-8")
        flags = re.findall(r"(--?[\w-]*(?:newest|recent|latest|reverse|desc)[\w-]*)", run("list", "--help").stdout, re.I)
        if not flags:
            print("no newest-first option found in `list --help`")
            return 1
        order = lambda out: [line.split("\t")[0] for line in out.stdout.splitlines() if line.strip()]
        newest, default = order(run("list", flags[0])), order(run("list"))
    if newest != ["3", "2", "1"] or default != ["1", "2", "3"]:
        print(f"with {flags[0]} expected 3, 2, 1, got {newest}; without it expected 1, 2, 3, got {default}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
