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
from measure import REPLY, ROOT, asks, bash_executable, bash_path, child_env, codex_env, format_cost, next_phase, record_usage, require_supported_codex_version, run, turn, turn_codex, validate_codex_home, validate_private_config, verify_trusted_hook  # noqa: E402

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


def setup(out: Path, task: str, aid: bool, commit: str, lean_bundle: Path | None = None, host: str = 'claude', codex_home: Path | None = None) -> tuple[Path, dict]:
    project, home = out / "project", out / "home"
    branch = f"{task}-{'aid' if aid else 'plain'}"
    preparation_env = os.environ
    if host == 'codex':
        preparation_env = codex_env(run_env(out), home, validate_codex_home(codex_home))
    if run(["git", "clone", "--quiet", "--shared", str(ROOT), str(project)], out, preparation_env).returncode:
        sys.exit("git clone failed")
    if run(["git", "checkout", "--quiet", "-b", branch, commit], project, preparation_env).returncode:
        sys.exit("git checkout failed")
    if (ROOT / "site/node_modules").is_dir():
        shutil.copytree(ROOT / "site/node_modules", project / "site/node_modules", symlinks=True)
    if not aid:
        if host == 'codex':
            hooks = project / '.codex/hooks.json'
            if hooks.exists() and 'codex_safeguard.py' in hooks.read_text(encoding='utf-8'):
                sys.exit('plain Codex baseline contains an AID hook; cannot compare safely')
            agents = project / '.codex/agents'
            if agents.is_dir():
                for agent in agents.glob('aid-*.toml'):
                    agent.unlink()
        for rel in AID_PATHS:
            p = project / rel
            shutil.rmtree(p) if p.is_dir() else p.unlink(missing_ok=True)
        for name in ("CLAUDE.md", "AGENTS.md"):
            strip_region(project / name)
        git = ["git", "-c", "user.name=m", "-c", "user.email=m@local"]
        run([*git, "add", "-A"], project, preparation_env)
        run([*git, "commit", "--quiet", "-m", "benchmark: remove AID for the plain run"], project, preparation_env)
    if host == 'claude':
        (home / ".claude").mkdir(parents=True)
    else:
        home.mkdir(parents=True, exist_ok=True)
    env = run_env(out)
    if host == 'codex':
        env = codex_env(env, home, validate_codex_home(codex_home))
    if lean_bundle is not None:
        install = (["add", "codex", "--target", bash_path(project), "--from-bundle", bash_path(lean_bundle)] if host == 'codex'
                   else ["update", "--from-bundle", bash_path(lean_bundle), "--target", bash_path(project)] if (project / ".aid").is_dir()
                   else ["add", "claude-code", "--target", bash_path(project), "--from-bundle", bash_path(lean_bundle)])
        result = run([bash_executable(), bash_path(ROOT / "bin/aid"), *install], project, env)
        markers = (project / (".agents/skills/aid-change/SKILL.md" if host == 'codex' else ".claude/skills/aid-change/SKILL.md"), project / ".aid/runtime/scripts/change/checks.py")
        if result.returncode or not all(path.is_file() for path in markers):
            sys.exit("lean bundle installation failed or missing expected files: " + (result.stdout + result.stderr)[-400:])
        if run(["git", "diff", "--quiet", commit, "--", "site"], project, env).returncode:
            sys.exit("lean installation changed the site baseline")
        if host == 'codex':
            helper = project / '.aid/runtime/scripts/change/codex_hook_config.py'
            activation = run([sys.executable, str(helper), 'install', '--project', str(project)], project, env)
            if activation.returncode:
                sys.exit('Codex hook activation failed: ' + (activation.stderr or activation.stdout)[-400:])
    if host == 'claude':
        creds = Path.home() / ".claude/.credentials.json"
        if creds.is_file() and not os.environ.get("CLAUDE_CODE_OAUTH_TOKEN"):
            shutil.copy2(creds, home / ".claude/.credentials.json")
    return project, env


def run_env(out: Path) -> dict:
    return child_env(dict(os.environ, HOME=str(out / "home"), AID_HOME=str(out / "aid-state"), AID_NO_UPDATE_CHECK="1",
                          PYTHONDONTWRITEBYTECODE="1"))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--task", choices=sorted(TASKS), default="site")
    ap.add_argument("--out", required=True, help="an empty folder that keeps the copy for grading")
    ap.add_argument("--no-aid", action="store_true")
    ap.add_argument("--host", choices=('claude', 'codex'), default='claude')
    ap.add_argument('--codex-home', type=Path, help='existing private Codex home under .aid/.temp')
    ap.add_argument("--lean", action="store_true", help="start the lean change skill")
    ap.add_argument("--lean-bundle", type=Path, help="staged current AID bundle to install over the historical checkout")
    ap.add_argument("--commit", default="HEAD")
    ap.add_argument("--turns", type=int, default=80)
    ap.add_argument("--max-cost", type=float, default=None, help="stop after the turn that passes this (USD; Claude only)")
    ap.add_argument("--model", default=None)
    ap.add_argument("--resume", metavar="SESSION", help="continue this session of an earlier run in --out")
    ap.add_argument("--cwd", help="with --resume: the folder the session last ran in (default: the copy)")
    a = ap.parse_args()
    if a.lean and a.no_aid:
        ap.error("--lean requires AID; it cannot be combined with --no-aid")
    if a.host == 'codex' and a.max_cost is not None:
        ap.error('Codex does not report per-run USD cost; --max-cost cannot be enforced')
    if a.host == 'codex':
        if not a.model:
            ap.error('Codex benchmarks require an explicit --model')
        try:
            a.codex_home = validate_codex_home(a.codex_home)
            validate_private_config(a.codex_home)
        except (OSError, ValueError, RuntimeError) as exc:
            ap.error(str(exc))
    if a.host == 'claude':
        a.max_cost = 150.0 if a.max_cost is None else a.max_cost
        a.model = a.model or os.environ.get('AID_MEASURE_MODEL', 'claude-sonnet-5-5')
    if a.lean and not a.resume and (not a.lean_bundle or not a.lean_bundle.is_dir()):
        ap.error("--lean requires --lean-bundle pointing to a staged current bundle")
    out = Path(a.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    aid = not a.no_aid
    mode = 'lean' if a.lean else ('aid' if aid else 'plain')
    git_env = run_env(out)
    if a.host == 'codex':
        git_env = codex_env(git_env, out / 'home', a.codex_home)
    resolved = run(["git", "rev-parse", "--verify", a.commit + '^{commit}'], ROOT, git_env)
    commit = resolved.stdout.strip()
    if resolved.returncode or not commit:
        sys.exit('could not resolve benchmark baseline')
    if a.resume:
        project, env = Path(a.cwd or out / "project").resolve(), run_env(out)
        if a.host == 'codex':
            env = codex_env(env, out / 'home', a.codex_home)
            metadata_path = out / 'benchmark-metadata.json'
            try:
                metadata = json.loads(metadata_path.read_text(encoding='utf-8'))
            except (OSError, ValueError) as exc:
                raise RuntimeError('resume requires original benchmark metadata') from exc
            expected = {'commit': commit, 'project': str((out / 'project').resolve()),
                        'host': 'codex', 'model': a.model, 'task': a.task, 'mode': mode}
            if (not isinstance(metadata, dict) or
                    any(metadata.get(key) != value for key, value in expected.items()) or
                    not isinstance(metadata.get('prepared_head'), str) or
                    project != (out / 'project').resolve()):
                raise RuntimeError('resume does not match original benchmark metadata')
            head = run(['git', 'rev-parse', 'HEAD'], project, env)
            if (head.returncode or not head.stdout.strip() or
                    any(run(['git', 'merge-base', '--is-ancestor', ancestor, 'HEAD'], project, env).returncode
                        for ancestor in (commit, metadata['prepared_head']))):
                raise RuntimeError('resume checkout does not match original baseline')
    else:
        project, env = setup(out, a.task, aid, commit, lean_bundle=a.lean_bundle if a.lean else None, host=a.host, codex_home=a.codex_home)
        if a.host == 'codex':
            prepared = run(['git', 'rev-parse', 'HEAD'], project, env)
            if prepared.returncode or not prepared.stdout.strip():
                raise RuntimeError('cannot establish prepared benchmark revision')
            metadata = {'commit': commit, 'prepared_head': prepared.stdout.strip(), 'project': str(project.resolve()),
                        'host': 'codex', 'model': a.model, 'task': a.task, 'mode': mode}
            with (out / 'benchmark-metadata.json').open('x', encoding='utf-8') as file:
                json.dump(metadata, file)

    cli_version = require_supported_codex_version(project, env, runner=run) if a.host == 'codex' else None
    probe_usage = None
    guard_identity = None
    if a.host == 'codex' and a.lean:
        guard_identity = verify_trusted_hook(project, a.codex_home, a.model, env)
        if isinstance(guard_identity, dict):
            probe_usage = guard_identity.get('usage')

    rec = {"task": a.task, "aid": aid, "host": a.host, "model": a.model, "commit": commit, "user_turns": 0, "agent_turns": None if a.host == 'codex' else 0,
           "cost_usd": None if a.host == 'codex' else 0.0, "input_tokens": 0, "output_tokens": 0, "cache_read_tokens": 0, "cache_write_tokens": None if a.host == 'codex' else 0, "tools": {},
           "dispatches": None if a.host == 'codex' else 0, "writer_calls": None if a.host == 'codex' else 0, "stopped": "turn limit"}
    rec["mode"] = mode
    rec['safeguard_probe_usage'] = probe_usage
    if a.host == 'codex':
        rec['usage_scope'] = ('session_cumulative_including_previous_turns' if a.resume
                              else 'session_cumulative')
        rec['codex_cli_version'] = cli_version
    session, message, text, repeats = None, ("/aid-change " if a.lean else "/aid-describe " if aid else "") + TASKS[a.task], "", 0
    if a.resume:
        session, message = a.resume, "Continue the work from where you stopped. " + GO_ON
    start = time.time()
    usage_watermarks = {}
    while rec["user_turns"] < a.turns:
        if a.host == 'codex' and guard_identity is not None:
            t = turn_codex(project, env, a.model, message, session, guard_identity=guard_identity)
        else:
            t = (turn_codex if a.host == 'codex' else turn)(project, env, a.model, message, session)
        session, r = t["session"], t["result"]
        u = r.get("usage", {})
        rec["user_turns"] += 1
        if rec["agent_turns"] is not None:
            rec["agent_turns"] += r.get("num_turns") or 0
        rec["cost_usd"] = r.get("total_cost_usd", rec["cost_usd"])  # the session's running total, not the turn's
        record_usage(rec, u, a.host, usage_watermarks)
        for k, v in t["tools"].items():
            rec["tools"][k] = rec["tools"].get(k, 0) + v
        if rec["dispatches"] is not None:
            rec["dispatches"] += t["dispatches"]
        if rec["writer_calls"] is not None:
            rec["writer_calls"] += t["writer_calls"]
        last, text = text, r.get("result", "") or ""
        repeats = repeats + 1 if text.strip() and text.strip() == last.strip() else 0
        acted = sum(t["tools"].values())  # any tool call; work can happen inside a resumed helper agent
        print(f"  turn {rec['user_turns']}: {format_cost(rec['cost_usd'])}, {round(time.time() - start)}s, "
              f"{rec['dispatches']} dispatches; last line: {text.strip().splitlines()[-1][:100] if text.strip() else '-'}",
              file=sys.stderr, flush=True)
        if r.get("is_error"):
            rec["stopped"] = "error: " + str(r.get("result", ""))[:200]
            break
        if a.max_cost is not None and rec["cost_usd"] is not None and rec["cost_usd"] > a.max_cost:
            rec["stopped"] = f"cost limit ${a.max_cost:.0f}"
            break
        if repeats >= 2:
            rec["stopped"] = "finished"  # the same closing message three times: it waits on a user step (merge, PR)
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
