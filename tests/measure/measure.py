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
import hashlib
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
try:
    import tomllib
except ImportError:
    tomllib = None

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


def bash_executable() -> str:
    """Use Git Bash on Windows, not the unrelated WSL bash launcher."""
    if os.name == "nt":
        git = shutil.which("git")
        if git:
            candidate = Path(git).resolve().parent.parent / "bin" / "bash.exe"
            if candidate.is_file():
                return str(candidate)
        raise RuntimeError("Git Bash is required for the Windows benchmark")
    return "bash"


def bash_path(value) -> str:
    """Convert a Windows drive path to the POSIX path used by Git Bash."""
    path = str(value).replace('\\', '/')
    return re.sub(r'^([A-Za-z]):(?:/|$)', lambda match: '/' + match.group(1).lower() + '/', path)


def run(cmd, cwd, env, stdin=None):
    return subprocess.run(cmd, cwd=cwd, env=env, input=stdin, capture_output=True, text=True, timeout=TIMEOUT)


def child_env(env: dict) -> dict:
    """Drop the calling session's own identity, so a nested claude run starts a session of its own."""
    return {k: v for k, v in env.items()
            if not (k.startswith(("CLAUDE_CODE_SESSION", "CLAUDE_CODE_REMOTE", "CLAUDE_CODE_CHILD", "CCR_",
                                  "SESSION_INGRESS", "CLAUDE_SESSION_INGRESS", "CLAUDE_CODE_SYNC",
                                  "CLAUDE_CODE_POST_FOR_SESSION")))}


def codex_env(env: dict, home: Path, codex_home: Path) -> dict:
    """Keep only process essentials; authentication comes from the selected home."""
    allowed = {'PATH', 'SYSTEMROOT', 'WINDIR', 'COMSPEC', 'PATHEXT',
               'LANG', 'LANGUAGE', 'LC_ALL', 'LC_CTYPE', 'TERM', 'SYSTEMDRIVE'}
    clean = {key: value for key, value in env.items() if key.upper() in allowed}
    temp = home / 'tmp'
    temp.mkdir(parents=True, exist_ok=True)
    clean.update(HOME=str(home), USERPROFILE=str(home), CODEX_HOME=str(codex_home),
                 AID_HOME=env['AID_HOME'], AID_NO_UPDATE_CHECK='1', PYTHONDONTWRITEBYTECODE='1',
                 TMP=str(temp), TEMP=str(temp), TMPDIR=str(temp))
    return clean


def validate_codex_home(value):
    """Require an existing private home under the project's temporary directory."""
    if not value:
        raise ValueError('Codex requires --codex-home under .aid/.temp')
    path = Path(os.path.abspath(value))
    base = (ROOT / '.aid/.temp').resolve()
    try:
        path.relative_to(base)
    except ValueError as exc:
        raise ValueError('Codex home must be under .aid/.temp') from exc
    for part in (path, *path.parents):
        if part.is_symlink() or (hasattr(os.path, 'isjunction') and os.path.isjunction(part)):
            raise ValueError('Codex home must not traverse links or junctions')
        if part == base:
            break
    if not path.is_dir() or path == base:
        raise ValueError('Codex home must be an existing private directory')
    return path


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixture_tree_sha256(project: Path, excluded_probe: Path | None = None) -> str:
    """Hash all fixture files, excluding Git internals and only the named probe."""
    project = project.resolve()
    excluded = excluded_probe.resolve() if excluded_probe is not None else None
    digest = hashlib.sha256()
    for directory, dirs, files in os.walk(project, followlinks=False):
        here = Path(directory)
        rel_dir = here.relative_to(project).as_posix().encode('utf-8')
        digest.update(b'D' + len(rel_dir).to_bytes(4, 'big') + rel_dir)
        kept = []
        for name in sorted(dirs):
            child = here / name
            if child.is_symlink():
                raise ValueError('fixture contains a directory symlink')
            if child == project / '.git' or child == excluded:
                continue
            kept.append(name)
        dirs[:] = kept
        for name in sorted(files):
            path = here / name
            if path.is_symlink():
                raise ValueError('fixture contains a file symlink')
            rel = path.relative_to(project).as_posix().encode('utf-8')
            digest.update(len(rel).to_bytes(4, 'big'))
            digest.update(rel)
            digest.update((path.stat().st_mode & 0o777).to_bytes(4, 'big'))
            digest.update(hashlib.sha256(path.read_bytes()).digest())
    return digest.hexdigest()


def validate_private_config(codex_home: Path) -> Path:
    """Accept only isolated UI, project-trust, and hook-trust settings."""
    if tomllib is None:
        raise RuntimeError('Codex trust verification requires Python 3.11 or newer')
    config = codex_home / 'config.toml'
    try:
        data = tomllib.loads(config.read_text(encoding='utf-8'))
    except (OSError, ValueError) as exc:
        raise RuntimeError('isolated Codex configuration is unavailable or invalid') from exc
    if not isinstance(data, dict) or set(data) - {'tui', 'projects', 'hooks'}:
        raise ValueError('isolated Codex configuration has unsupported settings')
    tui = data.get('tui', {})
    if not isinstance(tui, dict) or set(tui) - {'screen_reader_detection_done', 'model_availability_nux'}:
        raise ValueError('isolated Codex UI configuration has unsupported settings')
    nux = tui.get('model_availability_nux', {})
    if not isinstance(nux, dict) or not all(isinstance(k, str) and isinstance(v, int) for k, v in nux.items()):
        raise ValueError('invalid Codex UI state')
    projects = data.get('projects', {})
    if not isinstance(projects, dict) or any(not isinstance(v, dict) or set(v) != {'trust_level'} or
                                              v['trust_level'] != 'trusted' for v in projects.values()):
        raise ValueError('invalid isolated project trust state')
    hooks = data.get('hooks', {})
    if not isinstance(hooks, dict) or set(hooks) - {'state'} or not isinstance(hooks.get('state', {}), dict):
        raise ValueError('invalid isolated hook trust state')
    for value in hooks.get('state', {}).values():
        if (not isinstance(value, dict) or set(value) != {'trusted_hash'} or
                not re.fullmatch(r'sha256:[0-9a-f]{64}', str(value['trusted_hash']))):
            raise ValueError('invalid isolated hook trust entry')
    return config, data


def validate_project_config(project: Path) -> None:
    codex_dir = project / '.codex'
    if codex_dir.is_symlink() or (hasattr(os.path, 'isjunction') and os.path.isjunction(codex_dir)):
        raise RuntimeError('project Codex configuration directory is linked')
    if (codex_dir / 'config.toml').exists():
        raise RuntimeError('project Codex config is not permitted in the benchmark')


def require_supported_codex_version(project: Path, env: dict, runner=None) -> str:
    """Only 0.164.0 session-cumulative usage has been verified for this driver."""
    result = (runner or run)(['codex', '--version'], project, env)
    if result.returncode or result.stdout.strip() != 'codex-cli 0.164.0':
        raise RuntimeError('Codex benchmark usage accounting requires verified codex-cli 0.164.0')
    return '0.164.0'


def verify_trusted_hook(project: Path, codex_home: Path, model: str, env: dict) -> dict:
    """Prove native enforcement in this fixture; config or markers alone are not proof."""
    if not model or Path(env.get('CODEX_HOME', '')).resolve() != codex_home.resolve():
        raise ValueError('explicit model and matching isolated Codex home required')
    validate_project_config(project)
    config, config_data = validate_private_config(codex_home)
    hook = project / '.codex/hooks.json'
    handler = project / '.aid/runtime/scripts/change/codex_safeguard.py'
    for path in (config, hook, handler):
        if path.is_symlink() or not path.is_file():
            raise ValueError(f'required verification file is missing or linked: {path}')
    project_key = str(project.resolve()).replace('\\', '/')
    hook_key = str(hook.resolve()).replace('\\', '/') + ':pre_tool_use:0:0'
    if (config_data.get('projects', {}).get(project_key, {}).get('trust_level') != 'trusted' or
            hook_key not in config_data.get('hooks', {}).get('state', {})):
        raise RuntimeError(f'fixture must be reviewed and trusted in Codex /hooks: {project}')
    binary = shutil.which('codex', path=env.get('PATH'))
    if not binary:
        raise RuntimeError('Codex executable not found in isolated PATH')
    git_dir = project / '.git'
    git_config = git_dir / 'config'
    git_index = git_dir / 'index'
    if (git_dir.is_symlink() or not git_dir.is_dir() or (git_dir / 'commondir').exists() or
            git_config.is_symlink() or not git_config.is_file() or git_index.is_symlink()):
        raise RuntimeError('native hook probe requires an owned Git directory and configuration')
    git_root = run(['git', 'rev-parse', '--show-toplevel'], project, env)
    if git_root.returncode or Path(git_root.stdout.strip()).resolve() != project.resolve():
        raise RuntimeError('native hook probe project must be its own Git root')
    before = {str(p): _sha256(p) for p in (config, hook, handler, Path(binary))}
    remotes = run(['git', 'remote'], project, env)
    if remotes.returncode or remotes.stdout.strip():
        raise RuntimeError('native hook probe requires a fixture without Git remotes')
    head = run(['git', 'rev-parse', 'HEAD'], project, env)
    if head.returncode or not head.stdout.strip():
        raise RuntimeError('native hook probe requires a valid Git revision')
    git_config_hash = _sha256(git_config)
    git_index_hash = _sha256(git_index) if git_index.is_file() else None
    temp_root = project / '.aid/.temp'
    temp_root.mkdir(parents=True, exist_ok=True)
    baseline = fixture_tree_sha256(project)
    probe = Path(tempfile.mkdtemp(prefix='codex-hook-probe-', dir=temp_root))
    executable = probe / 'fake-bin/git'
    executable.parent.mkdir()
    executable.write_text('#!/bin/sh\nprintf "%s\\n" "$1" > ' + shlex.quote(str(probe)) + '/"$1"\n', encoding='utf-8')
    executable.chmod(0o700)
    executable_hash = _sha256(executable)
    command = executable.relative_to(project).as_posix()
    prompt = ('Use your shell tool for three separate calls in order: ' + '; '.join(
        command + ' ' + verb for verb in ('status', 'push', 'merge')) +
        '. This executable is inert; never run real Git. Report each result.')
    evidence = project.parent / 'codex-hook-evidence' / probe.name
    evidence.mkdir(parents=True, exist_ok=False)
    try:
        version = run(['codex', '--version'], project, env)
        if version.returncode or not version.stdout.strip():
            raise RuntimeError('cannot identify Codex CLI version')
        cmd = ['codex', 'exec', '--sandbox', 'workspace-write', '--enable', 'hooks',
               '--disable', 'apps', '--disable', 'browser_use', '-c', 'sandbox_workspace_write.network_access=false',
               '-c', 'approval_policy=never', '--json', '--model', model, '-']
        try:
            out = run(cmd, project, env, stdin=prompt)
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError('native Codex hook verification timed out') from exc
        (evidence / 'stdout.jsonl').write_text(out.stdout, encoding='utf-8')
        (evidence / 'stderr.txt').write_text(out.stderr, encoding='utf-8')
        try:
            events = [json.loads(line) for line in out.stdout.splitlines() if line.strip()]
        except ValueError as exc:
            raise RuntimeError('invalid native Codex probe output') from exc
        probe_usage = next((e.get('usage') for e in reversed(events) if e.get('type') == 'turn.completed'), None)
        identity = {'project': str(project.resolve()),
            'codex_home': str(codex_home.resolve()), 'cli': str(Path(binary).resolve()),
            'version': version.stdout.strip(), 'model': model, 'hashes': before,
            'fixture_tree_sha256': baseline, 'command': command, 'usage': probe_usage,
            'probe_path': str(probe)}
        (evidence / 'identity.json').write_text(json.dumps(identity, indent=2), encoding='utf-8')
        def is_exact_status(text):
            try:
                words = shlex.split(text)
            except ValueError:
                return False
            expected = command + ' status'
            return text == expected or (len(words) == 3 and Path(words[0]).name in ('bash', 'sh') and
                                        words[1] in ('-c', '-lc') and words[2] == expected)
        status = any(e.get('type') == 'item.completed' and
                     e.get('item', {}).get('type') == 'command_execution' and
                     is_exact_status(e['item'].get('command', '')) and
                     e['item'].get('exit_code') == 0 for e in events)
        denial_lines = [line for line in out.stderr.splitlines() if 'Command blocked by PreToolUse hook:' in line]
        denials = len(denial_lines) == 2 and all(denial_lines[i].endswith(
            'Command blocked by PreToolUse hook: Push and merge require the maintainer.. Command: '
            + command + ' ' + verb) for i, verb in enumerate(('push', 'merge')))
        if (out.returncode or not any(e.get('type') == 'turn.completed' for e in events) or not status or not denials or
                not (probe / 'status').is_file() or (probe / 'status').read_text(encoding='utf-8').strip() != 'status' or
                (probe / 'push').exists() or (probe / 'merge').exists()):
            raise RuntimeError(f'Codex hook enforcement not proven; review fixture {project} and evidence {evidence}')
        if before != {str(p): _sha256(p) for p in (config, hook, handler, Path(binary))}:
            raise RuntimeError('hook, handler, Codex configuration or launcher changed during verification')
        if executable.is_symlink() or not executable.is_file() or _sha256(executable) != executable_hash:
            raise RuntimeError('inert probe executable changed during verification')
        after_remote = run(['git', 'remote'], project, env)
        after_head = run(['git', 'rev-parse', 'HEAD'], project, env)
        after_config = _sha256(git_config) if git_config.is_file() else None
        after_index = _sha256(git_index) if git_index.is_file() and not git_index.is_symlink() else None
        if (after_remote.returncode or after_remote.stdout.strip() or after_head.returncode or
                after_head.stdout.strip() != head.stdout.strip() or after_config != git_config_hash or
                git_index.is_symlink() or after_index != git_index_hash):
            raise RuntimeError('benchmark fixture Git state changed during hook verification')
        if fixture_tree_sha256(project, excluded_probe=probe) != baseline:
            raise RuntimeError('benchmark fixture changed during hook verification')
    finally:
        if probe.is_symlink() or not probe.is_dir() or probe.parent.resolve() != temp_root.resolve():
            raise RuntimeError('probe directory was changed; preserving fixture for inspection')
        fixture_tree_sha256(probe)
        probe.rename(evidence / 'probe')
    if fixture_tree_sha256(project) != baseline:
        raise RuntimeError('benchmark fixture changed after hook verification')
    return identity


def validate_guard_identity(project: Path, env: dict, model: str, identity: dict) -> None:
    """Recheck the actual verified hook and private trust before every model turn."""
    if not isinstance(identity, dict) or identity.get('project') != str(project.resolve()) or identity.get('model') != model:
        raise RuntimeError('verified safeguard does not match this project and model')
    home = Path(env.get('CODEX_HOME', '')).resolve()
    if str(home) != identity.get('codex_home'):
        raise RuntimeError('verified safeguard does not match this Codex home')
    config, data = validate_private_config(home)
    hook = project / '.codex/hooks.json'
    handler = project / '.aid/runtime/scripts/change/codex_safeguard.py'
    binary = shutil.which('codex', path=env.get('PATH'))
    if not binary or str(Path(binary).resolve()) != identity.get('cli'):
        raise RuntimeError('Codex launcher changed since safeguard verification')
    key = str(hook.resolve()).replace('\\', '/') + ':pre_tool_use:0:0'
    project_key = str(project.resolve()).replace('\\', '/')
    if (data.get('projects', {}).get(project_key, {}).get('trust_level') != 'trusted' or
            key not in data.get('hooks', {}).get('state', {})):
        raise RuntimeError('fixture hook is no longer trusted')
    paths = (config, hook, handler, Path(binary))
    if any(p.is_symlink() and p != Path(binary) for p in paths):
        raise RuntimeError('verified safeguard file became a symlink')
    if identity.get('hashes') != {str(p): _sha256(p) for p in paths}:
        raise RuntimeError('verified safeguard identity changed')


def setup(work: Path, aid: bool, bundle: Path, host: str = 'claude', codex_home: Path | None = None, lean: bool = False) -> tuple[Path, dict]:
    project, home = work / "project", work / "home"
    shutil.copytree(FIXTURE, project)
    if not aid:
        shutil.rmtree(project / ".aid", ignore_errors=True)
    if host == 'claude':
        (home / ".claude").mkdir(parents=True)
        creds = Path.home() / ".claude/.credentials.json"
        if creds.is_file() and not os.environ.get("CLAUDE_CODE_OAUTH_TOKEN"):
            shutil.copy2(creds, home / ".claude/.credentials.json")
    else:
        home.mkdir(parents=True)
    env = child_env(dict(os.environ, HOME=str(home), AID_HOME=str(work / "aid-state"), AID_NO_UPDATE_CHECK="1",
                         PYTHONDONTWRITEBYTECODE="1"))
    if host == 'codex':
        env = codex_env(env, home, validate_codex_home(codex_home))
    if aid:
        out = run([bash_executable(), bash_path(ROOT / "bin/aid"), "add", "codex" if host == 'codex' else "claude-code", "--target", bash_path(project),
                   "--from-bundle", bash_path(bundle)], project, env)
        if out.returncode:
            sys.exit("AID install failed: " + (out.stdout + out.stderr)[-400:])
    for args in (["init", "-q"], ["add", "-A"], ["commit", "-qm", "baseline", "--allow-empty"]):
        if run(["git", "-c", "user.name=m", "-c", "user.email=m@local", *args], project, env).returncode:
            sys.exit('benchmark fixture Git setup failed')
    if host == 'codex' and lean and aid:
        helper = project / '.aid/runtime/scripts/change/codex_hook_config.py'
        result = run([sys.executable, str(helper), 'install', '--project', str(project)], project, env)
        if result.returncode:
            sys.exit('Codex hook activation failed: ' + (result.stderr or result.stdout)[-400:])
    return project, env


def prepared_work_path(value: Path, codex_home: Path) -> Path:
    """Bound prepared fixtures to the project scratch directory without links."""
    path = Path(os.path.abspath(value))
    base = (ROOT / '.aid/.temp').resolve()
    try:
        path.relative_to(base)
    except ValueError as exc:
        raise ValueError('prepared work must be under .aid/.temp') from exc
    if path == base or path == codex_home or codex_home in path.parents or path in codex_home.parents:
        raise ValueError('prepared work must be separate from the Codex home')
    for part in (path, *path.parents):
        if part.is_symlink() or (hasattr(os.path, 'isjunction') and os.path.isjunction(part)):
            raise ValueError('prepared work must not traverse links or junctions')
        if part == base:
            break
    return path


def preparation_metadata(project: Path, env: dict, scenario: str, model: str, codex_home: Path) -> dict:
    head = run(['git', 'rev-parse', 'HEAD'], project, env)
    if head.returncode or not re.fullmatch(r'[0-9a-f]{40,64}', head.stdout.strip()):
        raise RuntimeError('cannot establish prepared fixture Git revision')
    hook = project / '.codex/hooks.json'
    handler = project / '.aid/runtime/scripts/change/codex_safeguard.py'
    return {'project': str(project.resolve()), 'scenario': scenario, 'model': model, 'host': 'codex',
            'mode': 'lean', 'codex_home': str(codex_home.resolve()), 'fixture_head': head.stdout.strip(),
            'hook_sha256': _sha256(hook), 'handler_sha256': _sha256(handler),
            'fixture_tree_sha256': fixture_tree_sha256(project)}


def prepare_fixture(work: Path, scenario: str, model: str, bundle: Path, codex_home: Path) -> dict:
    work = prepared_work_path(work, codex_home)
    work.mkdir(parents=True, exist_ok=False)
    project, env = setup(work, True, bundle, host='codex', codex_home=codex_home, lean=True)
    (project / '.aid/.temp').mkdir(parents=True, exist_ok=True)
    metadata = preparation_metadata(project, env, scenario, model, codex_home)
    with (work / 'benchmark-metadata.json').open('x', encoding='utf-8') as out:
        json.dump(metadata, out, indent=2)
    return metadata


def load_prepared_fixture(work: Path, scenario: str, model: str, codex_home: Path) -> tuple[Path, dict, dict]:
    work = prepared_work_path(work, codex_home)
    if not work.is_dir():
        raise ValueError('prepared work directory does not exist')
    metadata = json.loads((work / 'benchmark-metadata.json').read_text(encoding='utf-8'))
    project = work / 'project'
    env = codex_env(dict(os.environ, AID_HOME=str(work / 'aid-state')), work / 'home', codex_home)
    expected = preparation_metadata(project, env, scenario, model, codex_home)
    if metadata != expected:
        raise ValueError('prepared fixture or benchmark identity has changed')
    return project, env, metadata


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


def turn_codex(project: Path, env: dict, model: str | None, message: str, session: str | None, *, guard_identity: dict | None = None) -> dict:
    """Read a completed Codex JSONL turn; keep raw evidence and never invent a price."""
    if not env.get('CODEX_HOME'):
        raise RuntimeError('Codex requires an isolated home')
    validate_private_config(Path(env['CODEX_HOME']))
    validate_project_config(project)
    if guard_identity is not None:
        validate_guard_identity(project, env, model, guard_identity)
    cmd = ['codex', 'exec', '--sandbox', 'workspace-write', '--enable', 'hooks',
           '--disable', 'apps', '--disable', 'browser_use', '-c', 'sandbox_workspace_write.network_access=false',
           '-c', 'approval_policy=never'] + (['resume'] if session else [])
    cmd += ['--json']
    if model:
        cmd += ['--model', model]
    if session:
        cmd.append(session)
    cmd.append('-')
    try:
        out = run(cmd, project, env, stdin=message)
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f'Codex timed out after {TIMEOUT}s') from exc
    raw_dir = project.parent / 'codex-raw'
    raw_dir.mkdir(exist_ok=True)
    number = len(list(raw_dir.glob('turn-*.jsonl'))) + 1
    (raw_dir / f'turn-{number:03d}.jsonl').write_text(out.stdout, encoding='utf-8')
    if out.returncode:
        raise RuntimeError(f'Codex exited {out.returncode}: {out.stderr[-400:]}')
    messages, final, tools, usage, completed, thread = [], None, {}, None, False, session
    for line in out.stdout.splitlines():
        event = json.loads(line)
        kind = event.get('type')
        if kind == 'thread.started':
            returned_thread = event.get('thread_id')
            if thread and returned_thread and thread != returned_thread:
                raise RuntimeError('Codex returned a different thread ID')
            thread = thread or returned_thread
        elif kind == 'turn.failed' or kind == 'error':
            raise RuntimeError('Codex turn failed: ' + str(event.get('error', event)))
        elif kind == 'turn.completed':
            completed, usage = True, event.get('usage')
        elif kind == 'item.completed':
            item = event.get('item', {})
            item_type = item.get('type')
            if item_type == 'agent_message':
                text = item.get('text', '')
                messages.append(text)
                if item.get('phase') != 'commentary':
                    final = text
            elif item_type in ('command_execution', 'file_change', 'mcp_tool_call'):
                tools[item_type] = tools.get(item_type, 0) + 1
    if not completed or not thread or not final or not isinstance(usage, dict):
        raise RuntimeError('Codex output lacks completed turn, session, final message or usage')
    normalized = {'input_tokens': usage.get('input_tokens'), 'output_tokens': usage.get('output_tokens'),
                  'cache_read_input_tokens': usage.get('cached_input_tokens'), 'cache_creation_input_tokens': None}
    return {'session': thread, 'messages': messages, 'tools': tools, 'dispatches': None, 'writer_calls': None,
            'start_context': None, 'result': {'result': final, 'usage': normalized, 'num_turns': None,
                                               'total_cost_usd': None, 'is_error': False}}


def record_usage(record: dict, usage: dict, host: str, watermarks: dict) -> None:
    """Codex 0.164 reports session-cumulative usage; Claude reports per-turn usage."""
    for target, source in (('input_tokens', 'input_tokens'), ('output_tokens', 'output_tokens'),
                           ('cache_read_tokens', 'cache_read_input_tokens')):
        value = usage.get(source)
        if host == 'codex':
            previous = watermarks.get(target)
            if value is not None and (not isinstance(value, int) or isinstance(value, bool) or value < 0):
                raise ValueError('invalid cumulative Codex usage')
            if value is not None and previous is not None and value < previous:
                raise ValueError('cumulative Codex usage decreased')
            if value is not None:
                watermarks[target] = value
            record[target] = value
        elif record[target] is not None:
            record[target] = record[target] + value if value is not None else None
    if record['cache_write_tokens'] is not None:
        record['cache_write_tokens'] += usage.get('cache_creation_input_tokens') or 0


def tail(text: str) -> str:
    return "\n".join(text.strip().splitlines()[-6:])


def next_phase(text: str) -> str | None:
    found = PHASES.findall(tail(text))
    return found[-1] if found else None


# AID asks in several forms; a question mark is only one of them.
ASKS = re.compile(r"\?|ask me to explain|reply with|your own (words|answer)|\[1\]|^\s*1[.)] ", re.I | re.M)


def requests_hook_trust(text: str) -> bool:
    text = text.replace('`', '')
    return bool(re.search(r'(?:^|(?<=[.!?])\s+|\n)\s*please\s+review\s+and\s+trust\s+'
                          r'(?:it\s+in\s+codex|the\s+aid\s+hook\s+in)\s+/hooks\b', text, re.I))


def safe_trust_followup(text: str) -> bool:
    """Recognize only reviewed, trust-only messages; unfamiliar wording needs a person."""
    text = text.replace('`', '').replace('’', "'")
    text = re.sub(r'\s+', ' ', text).strip()
    status = r"(?:The (?:required AID )?hook is installed(?:, but its trust status isn't established)?\.\s*)?"
    request = r'Please review and trust it in Codex /hooks(?: so I can continue)?\.'
    explanation = (r'(?:\s+The \[aid-change skill\]\([^)]*\) requires: '
                   r'[“"]If activation, the required Git/Python tools, or trust cannot be established, '
                   r'stop and explain the missing step\.[”"])?')
    # The optional final sentence is a factual status, not another instruction.
    ending = r'(?:\s+No application code has changed; the [\w -]+ remain(?:s)? unresolved\.)?'
    return bool(re.fullmatch(status + request + explanation + ending, text, re.I))


def asks(text: str) -> bool:
    return bool(ASKS.search(tail(text))) or requests_hook_trust(text) or next_phase(text) is not None


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


def measure(scenario: str, aid: bool, turns: int, model: str | None, bundle: Path, lean: bool = False, host: str = 'claude', codex_home: Path | None = None, prepared_work: Path | None = None) -> dict:
    scratch = ROOT / '.aid/.temp'
    scratch.mkdir(parents=True, exist_ok=True)
    metadata = None
    probe_usage = None
    guard_identity = None
    if prepared_work is not None:
        work = prepared_work_path(prepared_work, codex_home)
        project, env, metadata = load_prepared_fixture(work, scenario, model, codex_home)
    else:
        work = Path(tempfile.mkdtemp(prefix="aid-measure-", dir=scratch))
        project, env = setup(work, aid, bundle, host=host, codex_home=codex_home, lean=lean)
    cli_version = require_supported_codex_version(project, env) if host == 'codex' else None
    if host == 'codex' and lean:
        guard_identity = verify_trusted_hook(project, codex_home, model, env)
        if isinstance(guard_identity, dict):
            probe_usage = guard_identity.get('usage')
        if metadata is not None and fixture_tree_sha256(project) != metadata['fixture_tree_sha256']:
            raise RuntimeError('prepared fixture changed during hook verification')
    rec = {"scenario": scenario, "aid": aid, "host": host, "model": model, "user_turns": 0, "agent_turns": None if host == 'codex' else 0, "cost_usd": None if host == 'codex' else 0.0,
           "input_tokens": 0, "output_tokens": 0, "cache_read_tokens": 0, "cache_write_tokens": None if host == 'codex' else 0,
           "seconds": 0.0, "tools": {}, "dispatches": None if host == 'codex' else 0, "writer_calls": None if host == 'codex' else 0, "start_context_tokens": None}
    rec['safeguard_probe_usage'] = probe_usage
    if host == 'codex':
        rec['usage_scope'] = 'session_cumulative'
        rec['codex_cli_version'] = cli_version
    rec['trust_evidence_followup'] = None
    rec['trust_preflight_context'] = None
    request = SCENARIOS[scenario]
    if lean:
        request = "/aid-change " + re.sub(r"^/aid-\S+\s+", "", request)
    if host == 'codex' and lean and isinstance(guard_identity, dict):
        context = ('For this exact fixture, Codex recorded the hook as trusted. '
                   'A native preflight allowed fake status and blocked fake push and merge.')
        rec['trust_preflight_context'] = context
        request += '\n\n' + context
    rec["mode"] = "lean" if lean else ("aid" if aid else "plain")
    session, message, text = None, request, ""
    trust_followup_queued = False
    usage_watermarks = {}
    start = time.time()
    while rec["user_turns"] < turns:
        if host == 'codex' and guard_identity is not None:
            t = turn_codex(project, env, model, message, session, guard_identity=guard_identity)
        else:
            t = (turn_codex if host == 'codex' else turn)(project, env, model, message, session)
        if trust_followup_queued:
            rec['trust_evidence_followup'] = message
            trust_followup_queued = False
        session, r = t["session"], t["result"]
        if rec["start_context_tokens"] is None:
            rec["start_context_tokens"] = t["start_context"]
        u = r.get("usage", {})
        rec["user_turns"] += 1
        if rec["agent_turns"] is not None:
            rec["agent_turns"] += r.get("num_turns") or 0
        rec["cost_usd"] = r.get("total_cost_usd", rec["cost_usd"])  # the session's running total, not the turn's
        record_usage(rec, u, host, usage_watermarks)
        for k, v in t["tools"].items():
            rec["tools"][k] = rec["tools"].get(k, 0) + v
        if rec["dispatches"] is not None:
            rec["dispatches"] += t["dispatches"]
        if rec["writer_calls"] is not None:
            rec["writer_calls"] += t["writer_calls"]
        text = r.get("result", "") or ""
        print(f"  turn {rec['user_turns']}: {format_cost(rec['cost_usd'])} so far, {round(time.time() - start)}s, "
              f"{rec['dispatches']} dispatches; last line: {text.strip().splitlines()[-1][:100] if text.strip() else '-'}",
              file=sys.stderr, flush=True)
        # A complex run goes on until the hidden check passes: AID often ends a phase without a question.
        done = (any(grade(loc, scenario, work, env)["hidden_pass"] for loc in locations(project))
                if scenario.startswith("complex") else not asks(text))
        if r.get("is_error") or done:
            break
        if requests_hook_trust(text):
            # Only the exact, separately verified hook request is answerable here.
            # A mixed request, repeated request, or absent native proof must stop.
            if (host != 'codex' or not lean or not isinstance(guard_identity, dict) or
                    rec['trust_evidence_followup'] is not None or not safe_trust_followup(text)):
                break
            message = ('For this exact fixture, Codex recorded the hook as trusted. '
                       'A native preflight allowed fake status and blocked fake push and merge; please continue.')
            trust_followup_queued = True
            continue
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


def format_cost(value):
    return 'n/a' if value is None else f'${value:.2f}'


def report(files: list[str]) -> int:
    rows = [json.loads(line) for f in files for line in Path(f).read_text().splitlines() if line.strip()]
    groups: dict[tuple, list] = {}
    for index, r in enumerate(rows):
        mode = r.get("mode", "aid" if r["aid"] else "plain")
        model = r.get('model') or f'unreported-{index}'
        groups.setdefault((r["scenario"], mode, r.get("host", "claude"), model), []).append(r)
    print("scenario       mode   runs  host    model             start context  cache write  cost    seconds  hidden check")
    for (scenario, mode, host, model), g in sorted(groups.items()):
        cost = median([r['cost_usd'] for r in g]) if any(r['cost_usd'] is not None for r in g) else None
        contexts = [r.get('start_context_tokens') for r in g]
        writes = [r.get('cache_write_tokens') for r in g]
        context = f'{median(contexts):,.0f}' if any(x is not None for x in contexts) else 'n/a'
        write = f'{median(writes):,.0f}' if any(x is not None for x in writes) else 'n/a'
        print(f"{scenario:<14} {mode:<6} {len(g):<5} {host:<7} {model:<17} {context:>13}"
              f"  {write:>11}  {format_cost(cost):<7}"
              f" {median([r['seconds'] for r in g]):>7.0f}  {sum(bool(r.get('hidden_pass')) for r in g)}/{len(g)} pass")
    for scenario, host, model in sorted({(s, h, model) for s, _, h, model in groups}):
        plain = groups.get((scenario, "plain", host, model))
        for mode in ("aid", "lean"):
            group = groups.get((scenario, mode, host, model))
            if group and plain:
                a, p = (median([r.get("start_context_tokens") for r in x]) for x in (group, plain))
                if p:
                    print(f"Comparison {scenario} {host}: {mode} adds {a - p:,.0f} tokens to the start context ({(a - p) / p:+.0%})")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--scenario", choices=sorted(SCENARIOS), default="fix")
    ap.add_argument("--no-aid", action="store_true", help="measure the same request with no AID installed")
    ap.add_argument("--lean", action="store_true", help="start the installed lean change skill")
    ap.add_argument("--host", choices=('claude', 'codex'), default='claude')
    ap.add_argument('--codex-home', type=Path, help='existing private Codex home under .aid/.temp')
    ap.add_argument('--prepared-work', type=Path, help='project-local fixture to prepare or reuse')
    ap.add_argument('--prepare-only', action='store_true', help='prepare one lean Codex fixture without a model call')
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--turns", type=int, default=None,
                    help="user turns before giving up (default 10; 60 for the complex scenarios)")
    ap.add_argument("--model", default=None)
    ap.add_argument("--report", nargs="+", metavar="FILE", help="print medians from earlier runs' JSON lines")
    a = ap.parse_args()
    if a.lean and a.no_aid:
        ap.error("--lean requires AID; it cannot be combined with --no-aid")
    if a.model is None and a.host == 'claude':
        a.model = os.environ.get('AID_MEASURE_MODEL', 'claude-sonnet-5-5')
    if a.report:
        return report(a.report)
    if a.host == 'codex':
        if not a.model:
            ap.error('Codex benchmarks require an explicit --model')
        try:
            a.codex_home = validate_codex_home(a.codex_home)
            validate_private_config(a.codex_home)
        except (OSError, ValueError, RuntimeError) as exc:
            ap.error(str(exc))
    if a.prepare_only and not a.prepared_work:
        ap.error('--prepare-only requires --prepared-work')
    if a.prepared_work and (a.host != 'codex' or not a.lean or a.runs != 1):
        ap.error('--prepared-work requires one lean Codex run')
    if a.turns is None:
        a.turns = 60 if a.scenario.startswith("complex") else 10
    scratch = ROOT / '.aid/.temp'
    scratch.mkdir(parents=True, exist_ok=True)
    bundle = None
    if not a.prepared_work or a.prepare_only:
        bundle = Path(tempfile.mkdtemp(prefix="aid-bundle-", dir=scratch))
    if not a.no_aid and bundle is not None:
        stage_env = None
        if a.host == 'codex':
            stage_home = Path(tempfile.mkdtemp(prefix='aid-stage-home-', dir=scratch))
            stage_env = codex_env(dict(os.environ, AID_HOME=str(stage_home / 'aid-state')), stage_home, a.codex_home)
        out = subprocess.run([bash_executable(), "-c", 'source tests/lib/bundle.sh && aid_test_stage_bundle "$1"', "_",
                              bash_path(bundle)], cwd=ROOT, env=stage_env, capture_output=True, text=True)
        if out.returncode:
            sys.exit("staging the AID bundle failed: " + (out.stderr or out.stdout)[-400:])
    if a.prepare_only:
        metadata = prepare_fixture(a.prepared_work, a.scenario, a.model, bundle, a.codex_home)
        print(json.dumps(metadata), flush=True)
        return 0
    for i in range(1, a.runs + 1):
        rec = measure(a.scenario, not a.no_aid, a.turns, a.model, bundle, lean=a.lean, host=a.host,
                      codex_home=a.codex_home, prepared_work=a.prepared_work)
        rec["run"] = i
        print(json.dumps(rec), flush=True)
        print(f"{a.scenario} aid={not a.no_aid} run {i}: {format_cost(rec['cost_usd'])}, {rec['user_turns']} user turns, "
              f"{rec['agent_turns']} agent turns, {rec['dispatches']} dispatches, {rec['writer_calls']} writer "
              f"calls, {rec['seconds']:.0f}s, tests {'pass' if rec['tests_pass'] else 'FAIL'}, hidden check "
              f"{'pass' if rec['hidden_pass'] else 'FAIL'}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
