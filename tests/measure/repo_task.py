#!/usr/bin/env python3
"""repo_task.py -- run one large task on a copy of this repository, with AID or without, and record what it cost.

Purpose:
    The brownfield benchmark. Clones this repository at a commit onto a new branch, removes AID from the copy for a
    plain run (its rules, skills, agents and runtime; the Knowledge Base stays as project documents), then drives a
    `claude -p` session through the task exactly as measure.py does: every question gets one fixed reply, every
    next-phase command AID names is sent, and a turn that ends with neither gets "go on" until the work is done.
    Grading is separate (tests/measure/hidden/check_<task>.py), so the copy is kept.

Usage:
    python3 tests/measure/repo_task.py --task site --out DIR [--no-aid] [--model M] [--turns N] [--max-cost USD]
    python3 tests/measure/repo_task.py --task site --out DIR --resume SESSION --cwd DIR   (continue a stopped run)

Output:
    stdout: one JSON object.  stderr: progress per turn.  The copy stays at DIR/project on branch <task>-<aid|plain>.

Exit codes:
    0 -- the run finished, hit its turn limit or its cost limit (see `stopped`).  1 -- setup error.
"""

import argparse
import json
import os
import shutil
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from measure import REPLY, ROOT, asks, child_env, next_phase, run, turn  # noqa: E402

TASKS = {
    "site": ("Rework the product site in `site/` (published at aid.casuloailabs.com) completely. Check every page "
             "against the current skills and processes in this repository and fix what is wrong or stale. Give the "
             "diagrams and the whole layout a modern, professional look that stays accessible to developers of every "
             "level, and to screen-reader and keyboard users. Simplify the site's machinery (generators, scripts and "
             "tests) to what a static documentation site needs: keep only what earns its place. Do not deploy or "
             "publish anything."),
}
GO_ON = ("Go on with the next step until the work is finished. Wait for any helper agent you start to finish before you "
         "end your turn: a helper still running when the turn ends is stopped.")
AID_PATHS = [".claude/skills", ".claude/agents", ".agents", ".aid/runtime", ".aid/.aid-manifest.json"]


def strip_region(path: Path) -> None:
    """Remove the AID:BEGIN..AID:END region from a root instructions file, keeping the project's own lines."""
    if not path.is_file():
        return
    lines, out, inside = path.read_text(encoding="utf-8").splitlines(keepends=True), [], False
    for line in lines:
        if line.startswith("<!-- AID:BEGIN"):
            inside = True
        elif line.startswith("<!-- AID:END"):
            inside = False
        elif not inside:
            out.append(line)
    path.write_text("".join(out), encoding="utf-8")


def setup(out: Path, task: str, aid: bool, commit: str) -> tuple[Path, dict]:
    project, home = out / "project", out / "home"
    branch = f"{task}-{'aid' if aid else 'plain'}"
    if run(["git", "clone", "--quiet", "--shared", str(ROOT), str(project)], out, os.environ).returncode:
        sys.exit("git clone failed")
    run(["git", "checkout", "--quiet", "-b", branch, commit], project, os.environ)
    if (ROOT / "site/node_modules").is_dir():
        shutil.copytree(ROOT / "site/node_modules", project / "site/node_modules", symlinks=True)
    if not aid:
        for rel in AID_PATHS:
            p = project / rel
            shutil.rmtree(p) if p.is_dir() else p.unlink(missing_ok=True)
        for name in ("CLAUDE.md", "AGENTS.md"):
            strip_region(project / name)
        git = ["git", "-c", "user.name=m", "-c", "user.email=m@local"]
        run([*git, "add", "-A"], project, os.environ)
        run([*git, "commit", "--quiet", "-m", "benchmark: remove AID for the plain run"], project, os.environ)
    (home / ".claude").mkdir(parents=True)
    creds = Path.home() / ".claude/.credentials.json"
    if creds.is_file() and not os.environ.get("CLAUDE_CODE_OAUTH_TOKEN"):
        shutil.copy2(creds, home / ".claude/.credentials.json")
    return project, run_env(out)


def run_env(out: Path) -> dict:
    return child_env(dict(os.environ, HOME=str(out / "home"), AID_HOME=str(out / "aid-state"), AID_NO_UPDATE_CHECK="1",
                          PYTHONDONTWRITEBYTECODE="1"))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--task", choices=sorted(TASKS), default="site")
    ap.add_argument("--out", required=True, help="an empty folder that keeps the copy for grading")
    ap.add_argument("--no-aid", action="store_true")
    ap.add_argument("--commit", default="HEAD")
    ap.add_argument("--turns", type=int, default=80)
    ap.add_argument("--max-cost", type=float, default=150.0, help="stop after the turn that passes this (USD)")
    ap.add_argument("--model", default=os.environ.get("AID_MEASURE_MODEL", "claude-sonnet-5-5"))
    ap.add_argument("--resume", metavar="SESSION", help="continue this session of an earlier run in --out")
    ap.add_argument("--cwd", help="with --resume: the folder the session last ran in (default: the copy)")
    a = ap.parse_args()
    out = Path(a.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    aid = not a.no_aid
    commit = run(["git", "rev-parse", a.commit], ROOT, os.environ).stdout.strip()
    if a.resume:
        project, env = Path(a.cwd or out / "project").resolve(), run_env(out)
    else:
        project, env = setup(out, a.task, aid, commit)

    rec = {"task": a.task, "aid": aid, "model": a.model, "commit": commit, "user_turns": 0, "agent_turns": 0,
           "cost_usd": 0.0, "output_tokens": 0, "cache_read_tokens": 0, "cache_write_tokens": 0, "tools": {},
           "dispatches": 0, "writer_calls": 0, "stopped": "turn limit"}
    session, message, text = None, ("/aid-describe " if aid else "") + TASKS[a.task], ""
    if a.resume:
        session, message = a.resume, "Continue the work from where you stopped. " + GO_ON
    start = time.time()
    while rec["user_turns"] < a.turns:
        t = turn(project, env, a.model, message, session)
        session, r = t["session"], t["result"]
        u = r.get("usage", {})
        rec["user_turns"] += 1
        rec["agent_turns"] += r.get("num_turns", 0)
        rec["cost_usd"] = r.get("total_cost_usd", rec["cost_usd"])  # the session's running total, not the turn's
        rec["output_tokens"] += u.get("output_tokens", 0)
        rec["cache_read_tokens"] += u.get("cache_read_input_tokens", 0)
        rec["cache_write_tokens"] += u.get("cache_creation_input_tokens", 0)
        for k, v in t["tools"].items():
            rec["tools"][k] = rec["tools"].get(k, 0) + v
        rec["dispatches"] += t["dispatches"]
        rec["writer_calls"] += t["writer_calls"]
        text = r.get("result", "") or ""
        acted = sum(t["tools"].values())  # any tool call; work can happen inside a resumed helper agent
        print(f"  turn {rec['user_turns']}: ${rec['cost_usd']:.2f}, {round(time.time() - start)}s, "
              f"{rec['dispatches']} dispatches; last line: {text.strip().splitlines()[-1][:100] if text.strip() else '-'}",
              file=sys.stderr, flush=True)
        if r.get("is_error"):
            rec["stopped"] = "error: " + str(r.get("result", ""))[:200]
            break
        if rec["cost_usd"] > a.max_cost:
            rec["stopped"] = f"cost limit ${a.max_cost:.0f}"
            break
        phase = next_phase(text)
        if phase and phase != message:
            message = phase
        elif asks(text):
            message = REPLY
        elif message == GO_ON and acted == 0:
            rec["stopped"] = "finished"  # no question, asked to go on, and did nothing: the work is done
            break
        else:
            message = GO_ON
    rec["seconds"] = round(time.time() - start, 1)
    rec["last_message"] = text[-400:]
    rec["project"] = str(project)
    print(json.dumps(rec), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
