#!/usr/bin/env python3
"""measure.py -- measure what one task costs with AID and without it.

Purpose:
    Runs a real `claude -p` session on a fresh copy of a small notes project, with AID installed or not,
    answers every question with one fixed reply, and records what the session used: cost, tokens, turns,
    time, tool calls, sub-agent dispatches and state-writer calls. These are the baseline numbers every
    later change is measured against.

Usage:
    python3 tests/measure/measure.py [--scenario fix|feature] [--no-aid] [--runs N] [--turns N] [--model M]
    Needs the claude CLI logged in (its ~/.claude/.credentials.json is copied into each run's private home).

Output:
    stdout: one JSON object per run.  stderr: progress and a summary line per run.

Exit codes:
    0 -- every run finished.  1 -- setup or CLI error.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/measure/fixture"
SCENARIOS = {
    "fix": "Some notes in the list come out twice. Can you fix it?",
    "feature": "Add an option to list the notes newest first.",
}
REPLY = "Yes, go ahead. Take your recommendation for anything else."
TOOLS = "Read,Glob,Grep,Edit,Write,Bash,Skill,Task"
TIMEOUT = 1800


def run(cmd, cwd, env, stdin=None):
    return subprocess.run(cmd, cwd=cwd, env=env, input=stdin, capture_output=True, text=True, timeout=TIMEOUT)


def setup(work: Path, aid: bool, bundle: Path) -> tuple[Path, dict]:
    project, home = work / "project", work / "home"
    shutil.copytree(FIXTURE, project)
    if not aid:
        shutil.rmtree(project / ".aid", ignore_errors=True)
    (home / ".claude").mkdir(parents=True)
    creds = Path.home() / ".claude/.credentials.json"
    if creds.is_file():
        shutil.copy2(creds, home / ".claude/.credentials.json")
    env = dict(os.environ, HOME=str(home), AID_HOME=str(work / "aid-state"), AID_NO_UPDATE_CHECK="1",
               PYTHONDONTWRITEBYTECODE="1")
    if aid:
        out = run(["bash", str(ROOT / "bin/aid"), "add", "claude-code", "--target", str(project),
                   "--from-bundle", str(bundle)], project, env)
        if out.returncode:
            sys.exit("AID install failed: " + (out.stdout + out.stderr)[-400:])
    for args in (["init", "-q"], ["add", "-A"], ["commit", "-qm", "baseline", "--allow-empty"]):
        run(["git", "-c", "user.name=m", "-c", "user.email=m@local", *args], project, env)
    return project, env


def turn(project: Path, env: dict, model: str, message: str, session: str | None) -> dict:
    cmd = ["claude", "-p", "--output-format", "stream-json", "--verbose", "--permission-mode", "acceptEdits",
           "--allowedTools", TOOLS, "--setting-sources", "project", "--model", model]
    if session:
        cmd += ["--resume", session]
    out = run(cmd, project, env, stdin=message)
    t = {"session": session, "tools": {}, "dispatches": 0, "writer_calls": 0, "result": None}
    for line in out.stdout.splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "system" and ev.get("subtype") == "init":
            t["session"] = t["session"] or ev.get("session_id")
        elif ev.get("type") == "assistant":
            for b in ev.get("message", {}).get("content", []):
                if b.get("type") != "tool_use":
                    continue
                name = b.get("name", "")
                t["tools"][name] = t["tools"].get(name, 0) + 1
                t["dispatches"] += name in ("Task", "Agent")
                t["writer_calls"] += "writeback-state" in json.dumps(b.get("input", {}))
        elif ev.get("type") == "result":
            t["result"] = ev
    if t["result"] is None:
        sys.exit(f"claude returned no result (exit {out.returncode}): {(out.stderr or out.stdout)[-400:]}")
    return t


def asks(text: str) -> bool:
    tail = "\n".join(text.strip().splitlines()[-6:])
    return "?" in tail or "ask me to explain" in tail


def measure(scenario: str, aid: bool, turns: int, model: str, bundle: Path) -> dict:
    work = Path(tempfile.mkdtemp(prefix="aid-measure-"))
    project, env = setup(work, aid, bundle)
    rec = {"scenario": scenario, "aid": aid, "model": model, "user_turns": 0, "agent_turns": 0, "cost_usd": 0.0,
           "input_tokens": 0, "output_tokens": 0, "cache_read_tokens": 0, "cache_write_tokens": 0,
           "seconds": 0.0, "tools": {}, "dispatches": 0, "writer_calls": 0}
    session, message, text = None, SCENARIOS[scenario], ""
    start = time.time()
    while rec["user_turns"] < turns:
        t = turn(project, env, model, message, session)
        session, r = t["session"], t["result"]
        u = r.get("usage", {})
        rec["user_turns"] += 1
        rec["agent_turns"] += r.get("num_turns", 0)
        rec["cost_usd"] += r.get("total_cost_usd", 0.0)
        rec["input_tokens"] += u.get("input_tokens", 0)
        rec["output_tokens"] += u.get("output_tokens", 0)
        rec["cache_read_tokens"] += u.get("cache_read_input_tokens", 0)
        rec["cache_write_tokens"] += u.get("cache_creation_input_tokens", 0)
        for k, v in t["tools"].items():
            rec["tools"][k] = rec["tools"].get(k, 0) + v
        rec["dispatches"] += t["dispatches"]
        rec["writer_calls"] += t["writer_calls"]
        text = r.get("result", "") or ""
        if r.get("is_error") or not asks(text):
            break
        message = REPLY
    rec["seconds"] = round(time.time() - start, 1)
    changed = run(["git", "status", "--porcelain", "--", "src", "tests"], project, env).stdout.splitlines()
    rec["code_files_changed"] = len(changed)
    tests = run([sys.executable, "-m", "unittest", "discover", "-s", "tests", "-q"], project,
                dict(env, PYTHONPATH=str(project / "src")))
    rec["tests_pass"] = tests.returncode == 0
    rec["finished_asking"] = not asks(text)
    rec["last_message"] = text[-300:]
    rec["run_folder"] = str(work)
    return rec


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--scenario", choices=sorted(SCENARIOS), default="fix")
    ap.add_argument("--no-aid", action="store_true", help="measure the same request with no AID installed")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--turns", type=int, default=6, help="user turns before giving up (default 6)")
    ap.add_argument("--model", default=os.environ.get("AID_MEASURE_MODEL", "claude-sonnet-5-5"))
    a = ap.parse_args()
    bundle = Path(tempfile.mkdtemp(prefix="aid-bundle-"))
    if not a.no_aid:
        out = subprocess.run(["bash", "-c", 'source tests/lib/bundle.sh && aid_test_stage_bundle "$1"', "_",
                              str(bundle)], cwd=ROOT, capture_output=True, text=True)
        if out.returncode:
            sys.exit("staging the AID bundle failed: " + (out.stderr or out.stdout)[-400:])
    for i in range(1, a.runs + 1):
        rec = measure(a.scenario, not a.no_aid, a.turns, a.model, bundle)
        rec["run"] = i
        print(json.dumps(rec), flush=True)
        print(f"{a.scenario} aid={not a.no_aid} run {i}: ${rec['cost_usd']:.2f}, {rec['user_turns']} user turns, "
              f"{rec['agent_turns']} agent turns, {rec['dispatches']} dispatches, {rec['writer_calls']} writer "
              f"calls, {rec['seconds']:.0f}s, tests {'pass' if rec['tests_pass'] else 'FAIL'}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
