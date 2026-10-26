"""check_complex.py <project> -- hidden check for the complex scenario: note tags.

The request fixes the interface: `notes tag ID TAG`, `notes untag ID TAG`, `notes list --tag TAG` and `notes tags`
(one `TAG<tab>COUNT` line per tag, sorted by tag). Each part is checked on its own, and a notes file written before
the change (no tags) must still work. Run by measure.py after the session, outside the agent's view. Prints one
line per failed part; exit 0 when every part passes, 1 otherwise.
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
    failed = []
    with tempfile.TemporaryDirectory() as folder:
        def run(*args):
            return subprocess.run([sys.executable, "-m", "notes", *args], cwd=folder, env=env, capture_output=True,
                                  text=True)

        def ids(out):
            return [line.split("\t")[0] for line in out.stdout.splitlines() if line.strip()]

        def check(name, ok):
            if not ok:
                failed.append(name)

        old = [{"id": i, "text": t, "created": f"2026-01-0{i}T00:00:00+00:00"} for i, t in ((1, "a"), (2, "b"), (3, "c"))]
        Path(folder, "notes.json").write_text(json.dumps(old), encoding="utf-8")
        check("an old notes file still lists", ids(run("list")) == ["1", "2", "3"])
        tags0 = run("tags")
        check("an old notes file has no tags", tags0.returncode == 0 and tags0.stdout.strip() == "")
        tagged = run("tag", "1", "x").returncode == 0
        check("tag a note", tagged)
        run("tag", "2", "x")
        run("tag", "2", "y")
        run("tag", "1", "x")
        check("list --tag shows only tagged notes", ids(run("list", "--tag", "x")) == ["1", "2"])
        check("list without --tag is unchanged", ids(run("list")) == ["1", "2", "3"])
        check("tags counts each note once, sorted", run("tags").stdout.split() == ["x", "2", "y", "1"])
        check("untag a note", run("untag", "2", "x").returncode == 0)
        check("untag removes the tag", ids(run("list", "--tag", "x")) == ["1"])
        check("tags follows untag", run("tags").stdout.split() == ["x", "1", "y", "1"])
        check("tagging a missing note fails", tagged and run("tag", "9", "x").returncode != 0)
        nope = run("list", "--tag", "nope")
        check("an unknown tag lists nothing", nope.returncode == 0 and ids(nope) == [])
    for name in failed:
        print(f"failed: {name}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
