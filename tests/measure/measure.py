#!/usr/bin/env python3
"""measure.py -- measure what one task costs with AID and without it.

Purpose:
    Runs a real `claude -p` session on a fresh copy of a small notes project, with AID installed or not,
    answers every question with one fixed reply, and records what the session used: cost, tokens, turns,
    time, tool calls, sub-agent dispatches and state-writer calls. It then grades the result with a hidden
    check the agent never sees (tests/measure/hidden/). `start_context_tokens` is the size of the first model
    request, before any work: the context that is always loaded, free of the session's own choices.

Usage:
    python3 tests/measure/measure.py [--scenario NAME] [--no-aid] [--runs N] [--turns N] [--model M]
    python3 tests/measure/measure.py --report FILE.jsonl...   (medians per scenario, with and without AID)
    Needs the claude CLI logged in. With CLAUDE_CODE_OAUTH_TOKEN set (from `claude setup-token`) every run uses
    it; otherwise ~/.claude/.credentials.json is copied into each run's private home, and a long run can let
    that login expire.

Output:
    stdout: one JSON object per run, or the report table.  stderr: progress and a summary line per run.

Exit codes:
    0 -- every run finished.  1 -- setup or CLI error.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/measure/fixture"
HIDDEN = ROOT / "tests/measure/hidden"
COMPLEX = ("Add tags to notes. `notes tag ID TAG` adds a tag to a note and `notes untag ID TAG` removes it; tagging "
           "a note that does not exist fails. `notes list --tag TAG` lists only the notes with that tag. `notes tags` "
           "prints one line per tag, the tag and the number of notes that have it separated by a tab, sorted by tag. "
           "Notes files written before this change must keep working.")
SCENARIOS = {
    "fix": "Some notes in the list come out twice. Can you fix it?",
    "feature": "Add an option to list the notes newest first.",
    "fix-skill": "/aid-fix Some notes in the list come out twice.",
    "feature-skill": "/aid-create Add an option to list the notes newest first.",
    "complex": COMPLEX,
    "complex-skill": "/aid-describe " + COMPLEX,
}
REPLY = "Yes, go ahead. Take your recommendation for anything else."
# When AID ends a turn naming the next phase command, that command is sent instead of REPLY.
PHASES = re.compile(r"/aid-(?:define|specify|plan|detail|execute)\b(?: [\w./-]+)?")
TOOLS = "Read,Glob,Grep,Edit,Write,Bash,Skill,Task"
TIMEOUT = int(os.environ.get("AID_MEASURE_TIMEOUT", "7200"))  # seconds per claude call


def run(cmd, cwd, env, stdin=None):
    return subprocess.run(cmd, cwd=cwd, env=env, input=stdin, capture_output=True, text=True, timeout=TIMEOUT)


def setup(work: Path, aid: bool, bundle: Path) -> tuple[Path, dict]:
    project, home = work / "project", work / "home"
    shutil.copytree(FIXTURE, project)
    if not aid:
        shutil.rmtree(project / ".aid", ignore_errors=True)
    (home / ".claude").mkdir(parents=True)
    creds = Path.home() / ".claude/.credentials.json"
    if creds.is_file() and not os.environ.get("CLAUDE_CODE_OAUTH_TOKEN"):
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
    try:
        out = run(cmd, project, env, stdin=message)
    except subprocess.TimeoutExpired:
        return {"session": session, "tools": {}, "dispatches": 0, "writer_calls": 0,
                "result": {"is_error": True, "result": f"timed out after {TIMEOUT}s"}}
    t = {"session": session, "tools": {}, "dispatches": 0, "writer_calls": 0, "result": None, "start_context": None}
    for line in out.stdout.splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "system" and ev.get("subtype") == "init":
            t["session"] = t["session"] or ev.get("session_id")
        elif ev.get("type") == "assistant":
            u = ev.get("message", {}).get("usage") or {}
            if t["start_context"] is None and u:
                t["start_context"] = (u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0)
                                      + u.get("cache_creation_input_tokens", 0))
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


def tail(text: str) -> str:
    return "\n".join(text.strip().splitlines()[-6:])


def next_phase(text: str) -> str | None:
    found = PHASES.findall(tail(text))
    return found[-1] if found else None


def asks(text: str) -> bool:
    return "?" in tail(text) or "ask me to explain" in tail(text) or next_phase(text) is not None


def locations(project: Path) -> list[Path]:
    return [project, *sorted((project / ".claude/worktrees").glob("*/"))]


def grade(loc: Path, scenario: str, work: Path, env: dict) -> dict:
    root = run(["git", "rev-list", "--max-parents=0", "HEAD"], loc, env).stdout.split()
    diff = run(["git", "diff", "--name-only", *root[:1], "--", "src", "tests"], loc, env).stdout.split()
    new = run(["git", "ls-files", "--others", "--exclude-standard", "--", "src", "tests"], loc, env).stdout.split()
    changed = sorted(set(diff + new))
    tests = run([sys.executable, "-m", "unittest", "discover", "-s", "tests", "-q"], loc,
                dict(env, PYTHONPATH=str(loc / "src")))
    check = run([sys.executable, str(HIDDEN / f"check_{scenario.split('-')[0]}.py"), str(loc)], work, env)
    return {"code_files_changed": len(changed), "test_files_changed": sum(f.startswith("tests/") for f in changed),
            "tests_pass": tests.returncode == 0, "hidden_pass": check.returncode == 0,
            "hidden_detail": (check.stdout + check.stderr).strip()[-200:]}


def measure(scenario: str, aid: bool, turns: int, model: str, bundle: Path) -> dict:
    work = Path(tempfile.mkdtemp(prefix="aid-measure-"))
    project, env = setup(work, aid, bundle)
    rec = {"scenario": scenario, "aid": aid, "model": model, "user_turns": 0, "agent_turns": 0, "cost_usd": 0.0,
           "input_tokens": 0, "output_tokens": 0, "cache_read_tokens": 0, "cache_write_tokens": 0,
           "seconds": 0.0, "tools": {}, "dispatches": 0, "writer_calls": 0, "start_context_tokens": None}
    session, message, text = None, SCENARIOS[scenario], ""
    start = time.time()
    while rec["user_turns"] < turns:
        t = turn(project, env, model, message, session)
        session, r = t["session"], t["result"]
        if rec["start_context_tokens"] is None:
            rec["start_context_tokens"] = t["start_context"]
        u = r.get("usage", {})
        rec["user_turns"] += 1
        rec["agent_turns"] += r.get("num_turns", 0)
        rec["cost_usd"] = r.get("total_cost_usd", rec["cost_usd"])  # the session's running total, not the turn's
        rec["input_tokens"] += u.get("input_tokens", 0)
        rec["output_tokens"] += u.get("output_tokens", 0)
        rec["cache_read_tokens"] += u.get("cache_read_input_tokens", 0)
        rec["cache_write_tokens"] += u.get("cache_creation_input_tokens", 0)
        for k, v in t["tools"].items():
            rec["tools"][k] = rec["tools"].get(k, 0) + v
        rec["dispatches"] += t["dispatches"]
        rec["writer_calls"] += t["writer_calls"]
        text = r.get("result", "") or ""
        print(f"  turn {rec['user_turns']}: ${rec['cost_usd']:.2f} so far, {round(time.time() - start)}s, "
              f"{rec['dispatches']} dispatches; last line: {text.strip().splitlines()[-1][:100] if text.strip() else '-'}",
              file=sys.stderr, flush=True)
        # A complex run goes on until the hidden check passes: AID often ends a phase without a question.
        done = (any(grade(loc, scenario, work, env)["hidden_pass"] for loc in locations(project))
                if scenario.startswith("complex") else not asks(text))
        if r.get("is_error") or done:
            break
        phase = next_phase(text)
        message = phase if phase and phase != message else REPLY
    rec["seconds"] = round(time.time() - start, 1)
    # AID may build in a git worktree of its own inside the project; grade every copy, keep the best.
    best = None
    for loc in locations(project):
        g = grade(loc, scenario, work, env)
        if best is None or (g["hidden_pass"], g["code_files_changed"]) > (best["hidden_pass"], best["code_files_changed"]):
            best = dict(g, graded_at=str(loc.relative_to(project)))
    rec.update(best)
    rec["finished_asking"] = not asks(text)
    rec["last_message"] = text[-300:]
    rec["run_folder"] = str(work)
    return rec


def median(values: list) -> float:
    v = sorted(x for x in values if x is not None)
    return 0 if not v else (v[len(v) // 2] if len(v) % 2 else (v[len(v) // 2 - 1] + v[len(v) // 2]) / 2)


def report(files: list[str]) -> int:
    rows = [json.loads(line) for f in files for line in Path(f).read_text().splitlines() if line.strip()]
    groups: dict[tuple, list] = {}
    for r in rows:
        groups.setdefault((r["scenario"], r["aid"]), []).append(r)
    print("scenario       AID    runs  start context  cache write  cost    seconds  hidden check")
    for (scenario, aid), g in sorted(groups.items()):
        print(f"{scenario:<14} {'yes' if aid else 'no':<6} {len(g):<5} {median([r.get('start_context_tokens') for r in g]):>13,.0f}"
              f"  {median([r['cache_write_tokens'] for r in g]):>11,.0f}  ${median([r['cost_usd'] for r in g]):<6.2f}"
              f" {median([r['seconds'] for r in g]):>7.0f}  {sum(bool(r.get('hidden_pass')) for r in g)}/{len(g)} pass")
    for scenario in sorted({s for s, _ in groups}):
        aid, plain = groups.get((scenario, True)), groups.get((scenario, False))
        if aid and plain:
            a, p = (median([r.get("start_context_tokens") for r in x]) for x in (aid, plain))
            if p:
                print(f"{scenario}: AID adds {a - p:,.0f} tokens to the start context ({(a - p) / p:+.0%})")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--scenario", choices=sorted(SCENARIOS), default="fix")
    ap.add_argument("--no-aid", action="store_true", help="measure the same request with no AID installed")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--turns", type=int, default=None,
                    help="user turns before giving up (default 10; 60 for the complex scenarios)")
    ap.add_argument("--model", default=os.environ.get("AID_MEASURE_MODEL", "claude-sonnet-5-5"))
    ap.add_argument("--report", nargs="+", metavar="FILE", help="print medians from earlier runs' JSON lines")
    a = ap.parse_args()
    if a.report:
        return report(a.report)
    if a.turns is None:
        a.turns = 60 if a.scenario.startswith("complex") else 10
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
              f"calls, {rec['seconds']:.0f}s, tests {'pass' if rec['tests_pass'] else 'FAIL'}, hidden check "
              f"{'pass' if rec['hidden_pass'] else 'FAIL'}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
