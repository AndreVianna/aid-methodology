"""check_fix.py <project> -- hidden check for the fix scenario: `list` shows each note once, pinned notes first.

Run by measure.py after the session, outside the agent's view. Exit 0 when the check passes, 1 when it fails.
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def main() -> int:
    project = Path(sys.argv[1]).resolve()
    env = dict(os.environ, PYTHONPATH=str(project / "src"))
    with tempfile.TemporaryDirectory() as folder:
        notes = [{"id": i, "text": t, "created": f"2026-01-0{i}T00:00:00+00:00"} for i, t in ((1, "a"), (2, "b"), (3, "c"))]
        notes[1]["pinned"] = True
        Path(folder, "notes.json").write_text(json.dumps(notes), encoding="utf-8")
        out = subprocess.run([sys.executable, "-m", "notes", "list"], cwd=folder, env=env, capture_output=True, text=True)
    ids = [line.split("\t")[0] for line in out.stdout.splitlines() if line.strip()]
    if ids != ["2", "1", "3"]:
        print(f"expected ids 2, 1, 3 (each once, pinned first); got {ids} {out.stderr.strip()[-200:]}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
