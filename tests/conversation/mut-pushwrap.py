#!/usr/bin/env python3
"""Conversation test suite runner (NFR-T; REQUIREMENTS.md section 11 Feature 001, section 6 Testing).

Purpose: drive the agent under test through scripted sample conversations, capture every
run, evaluate each sample's checks, and have an independent judge rule on the transcript.
Standard library only. Runs on demand; never part of run-all.sh or CI.

Usage:
  python3 tests/conversation/run.py --feature NNN [--sample ID] [--hosts claude-code,...]
      [--runs 3] [--samples-dir DIR] [--fixtures-dir DIR] [--briefs-dir DIR]
  python3 tests/conversation/run.py --feature NNN [--sample ID] --validate

Exit codes:
  0  every run passes (--validate: every selected sample parses)
  1  any failure (a run failed, or --validate or a malformed sample found an error)
  2  invocation error (bad arguments, unknown sample or host, missing briefs, no claude)

Run folder: .aid/.temp/conversation-tests/<run-id>/<sample>/run-<n>/ holding transcript.jsonl,
transcript.md, files.diff, checks.txt, ledger.md (the judge's ledger) and model.txt (the model the
agent under test ran with). The judge's ledger is also saved in the fixture's .aid/.temp/review-pending/.

Agent model: Claude Code uses claude-sonnet-5-5 (DEFAULT_MODEL), passed as --model on every agent turn;
Codex uses its CLI default unless AID_CODEX_MODEL names another model. AID_CONV_MODEL names another
Claude Code model. The agent's environment drops the parent session's identity
and wiring (ENV_DROP_NAMES, ENV_DROP_PREFIXES); auth, provider, proxy and CA variables are kept.

Sample file (samples/feature-NNN/<id>.md):
  frontmatter        id, covers, fixture (required); branch (optional: the fixture gets a work branch of
                     that name with one commit of its own, and the default branch stays checked out);
                     any other key is kept and ignored (Feature 002's samples add skills:)
  ## User            the first paragraph is the opening message; the whole section is the persona
  ## Answer sheet    all the simulated user knows
  ## Expected outcome  items the judge rules on one by one
  ## Must not          items the judge rules on one by one
  ## Checks            one check per line, evaluated before judging

Checks grammar (one per line; a leading "- " and surrounding backticks are ignored):
  exists PATH                  PATH exists in the fixture after the run
  absent PATH                  nothing exists at PATH in the fixture after the run
  contains PATH TEXT           the file PATH contains TEXT (TEXT is the rest of the line; one
                               pair of matching quotes around it is removed)
  no-new-dir PATH              no directory is created at PATH or directly inside it
  no-push                      no Bash call runs git push
  tool-called NAME [GLOB]      the transcript has a call to tool NAME whose target matches GLOB
  tool-not-called NAME [GLOB]  the transcript has no such call
  ref-unchanged NAME           the branch NAME points at the same commit after the run as before it
                               (NAME is a branch, or "default" for the branch checked out before the run)
  Targets: Skill -> the skill name; Task -> the subagent type; Bash -> the command;
  Read/Edit/Write -> the file path (relative to the fixture when inside it); Glob/Grep -> the pattern.

Driver (Claude Code): each agent turn is one `claude -p --output-format stream-json` call in the
fixture, with --permission-mode acceptEdits, --tools and --allowedTools
"Read,Glob,Grep,Edit,Write,Bash,Skill,Task", --strict-mcp-config, --setting-sources project, and
--resume <session-id> from turn 2 on. The prompt goes on stdin, because --tools is variadic.
Tool names checked against the installed CLI (2.1.302; the spec names 2.1.296): `claude --help` does not
list built-in tool names, so the check used the CLI's own text. Its model-invoked skill calls are
`"name":"Skill"` with the skill name as the target, so Skill is confirmed. It refers to "the Task
tool" with a `subagent_type` input, so Task is confirmed, but the same text also says "Agent/Task
tool": a newer alias may exist, and a live run should confirm the name in use.
Simulated user and judge: `claude -p --tools "" --safe-mode --strict-mcp-config --system-prompt
<brief>` from an empty temporary folder, the prompt on stdin.
Driver (Codex): the first turn is `codex exec --json --model <model, when set> --sandbox workspace-write
--approve-for-me --output-last-message <file> -` in the fixture, the prompt on stdin; the thread id comes
from the thread.started event, and each later turn is `codex exec resume <thread-id>` with --json,
--model and --output-last-message only (the resume help lists no sandbox or approval option). Codex
output is not normalized to tool calls, so the tool-call checks read NOT RUN on that host.
Limits: 12 user turns (the run fails when no <<END>> comes within them); 600 s per claude or codex call.
Other hosts: a start/send/read adapter per host (ADAPTERS). Claude Code and Codex have adapters;
hosts without an adapter are skipped with a NOTICE.
"""

from __future__ import annotations

import argparse
import difflib
import fnmatch
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SAMPLES_DIR = ROOT / "tests/conversation/samples"
DEFAULT_FIXTURES_DIR = ROOT / "tests/conversation/fixtures"
DEFAULT_BRIEFS_DIR = ROOT / "tests/conversation"
RUN_ROOT = ROOT / ".aid/.temp/conversation-tests"

TURN_CAP = 12
TURN_TIMEOUT = 600
END_MARK = "<<END>>"
AGENT_TOOLS = "Read,Glob,Grep,Edit,Write,Bash,Skill,Task"
DEFAULT_MODEL = "claude-sonnet-5-5"
MODEL_ENV = "AID_CONV_MODEL"
REQUIRED_KEYS = ("id", "covers", "fixture")
REQUIRED_SECTIONS = ("User", "Answer sheet", "Expected outcome", "Must not", "Checks")
CHECK_VERBS = ("exists", "absent", "contains", "no-new-dir", "no-push", "tool-called", "tool-not-called", "ref-unchanged")
# the credential files under HOME, never recorded in files.diff: the known credential file names, and private
# key or certificate files by extension (a note whose name merely says token or secret is kept)
CREDENTIAL_RE = re.compile(r"(?i)^(\.credentials\.json|\.netrc|\.npmrc|\.pypirc|\.git-credentials|\.env|id_(rsa|dsa|ecdsa|ed25519)|.+\.(pem|key|p12|pfx))$")
# the agent's environment: the parent session's identity and wiring are dropped (the deny-list below);
# every auth and provider variable, proxy and CA variable is kept, so the agent can still authenticate
ENV_DROP_NAMES = (
    # the parent session's identity: its session, account, organization, user and ingress
    "CLAUDECODE", "CLAUDE_CODE_SESSION_ID", "CLAUDE_CODE_ENTRYPOINT", "CLAUDE_CODE_CHILD_SESSION",
    "CLAUDE_CODE_USER_EMAIL", "CLAUDE_CODE_ACCOUNT_UUID", "CLAUDE_CODE_ORGANIZATION_UUID",
    "CLAUDE_CODE_CONTAINER_ID", "CLAUDE_EFFORT", "CLAUDE_AFTER_LAST_COMPACT", "CLAUDE_CONFIG_DIR",
    "CLAUDE_PID", "CLAUDE_ADDITIONAL_DIRECTORIES", "CCR_SESSION_PROFILE", "CCR_SPAWN_TIMESTAMP_MS",
    # the parent session's ingress, messaging and sync wiring (URLs, tokens and sockets of that session)
    "SESSION_INGRESS_URL", "CLAUDE_SESSION_INGRESS_TOKEN_FILE", "CLAUDE_CODE_POST_FOR_SESSION_INGRESS_V2",
    "CLAUDE_CODE_MESSAGING_SOCKET", "CLAUDE_CODE_MESSAGING_TOKEN", "CLAUDE_CODE_SESSION_ATTENDED",
    "CLAUDE_CODE_SYNC_SESSION_REFS", "CLAUDE_CODE_SYNC_PLUGINS", "CLAUDE_CODE_SYNC_SKILLS",
    "CLAUDE_CODE_WORKER_EPOCH", "CLAUDE_CODE_USE_CCR_V2", "CLAUDE_CODE_ENVIRONMENT_RUNNER_VERSION",
    "CLAUDE_CODE_DIAGNOSTICS_FILE", "CLAUDE_CODE_TEE_SDK_STDOUT", "CLAUDE_CODE_EXECPATH",
)
# every CLAUDE_CODE_REMOTE* variable (the remote-session wiring); no auth or provider name starts with it
ENV_DROP_PREFIXES = ("CLAUDE_CODE_REMOTE",)
# the sandbox's own set-up files, and the Codex CLI's folder (its sign-in file), under HOME: never recorded
# in files.diff, in a transcript or in the judge's prompt
HOME_SETUP_DIRS = (".ccr", ".pki", ".local/share/pki", ".aws", ".codex")
HOME_SETUP_FILES = (".boto",)
# a worktree the agent creates under the fixture: its files are diffed against the fixture's own files
WORKTREES_PREFIX = "fixture/.claude/worktrees/"
# the judge's prompt only (files.diff on disk is never cut): per-file line cap and total byte cap
JUDGE_FILE_LINES = 300
JUDGE_TOTAL_BYTES = 200_000
JUDGE_MAX_MARKERS = 20  # per-file truncation markers; the files past them are counted in one final line
JUDGE_SUMMARY_BYTES = 100  # room kept inside the total for that final line
# the first rule of every simulated-user turn: the answer sheet's end conditions override the rest
END_FIRST_RULE = (
    "Before anything else, check the answer sheet's end conditions: if the assistant's last message "
    f"meets one, reply {END_MARK} alone. This overrides every other rule."
)
LEDGER_COLUMNS = ("#", "Severity", "Status", "Doc", "Line", "Description", "Evidence")
DEFAULT_HOSTS = ("claude-code",)
KNOWN_HOSTS = ("claude-code", "codex", "cursor", "copilot-cli", "antigravity")


class UsageError(Exception):
    """An invocation or setup error: exit 2."""


class RunError(Exception):
    """A run-level failure: that run fails, and the harness goes on to capture and judge it."""


# ---------------------------------------------------------------- sample parsing


def split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("no frontmatter (the file must open with ---)")
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        raise ValueError("frontmatter is not closed by ---")
    meta: dict[str, str] = {}
    for raw in lines[1:end]:
        if not raw.strip() or raw[0] in " \t-":
            continue  # a continuation line of a list value
        m = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", raw)
        if not m:
            raise ValueError(f"malformed frontmatter line: {raw!r}")
        meta[m.group(1)] = m.group(2).strip()
    return meta, "\n".join(lines[end + 1 :])


def split_sections(body: str) -> dict[str, str]:
    sections: dict[str, list[str]] = {}
    current = None
    for line in body.splitlines():
        m = re.match(r"^## (.+?)\s*$", line)
        if m:
            current = m.group(1)
            sections.setdefault(current, [])
        elif current is not None:
            sections[current].append(line)
    return {name: "\n".join(lines).strip("\n") for name, lines in sections.items()}


def parse_check(line: str) -> dict:
    text = line.strip()
    if text.startswith("- "):
        text = text[2:].strip()
    if len(text) >= 2 and text[0] == text[-1] == "`":
        text = text[1:-1].strip()
    parts = text.split(None, 1)
    verb = parts[0] if parts else ""
    rest = parts[1].strip() if len(parts) > 1 else ""
    args = rest.split()
    if verb not in CHECK_VERBS:
        raise ValueError(f"unknown check {line.strip()!r}")
    if verb in ("exists", "absent", "no-new-dir"):
        if len(args) != 1:
            raise ValueError(f"{verb} takes one PATH: {line.strip()!r}")
        return {"verb": verb, "args": args, "label": f"{verb} {args[0]}"}
    if verb == "contains":
        pieces = rest.split(None, 1)
        if len(pieces) != 2 or not pieces[1].strip():
            raise ValueError(f"contains takes PATH and TEXT: {line.strip()!r}")
        found = pieces[1].strip()
        if len(found) >= 2 and found[0] == found[-1] and found[0] in "\"'`":
            found = found[1:-1]
        return {"verb": verb, "args": [pieces[0], found], "label": f"contains {pieces[0]} {found}"}
    if verb == "ref-unchanged":
        if len(args) != 1:
            raise ValueError(f"ref-unchanged takes one NAME: {line.strip()!r}")
        return {"verb": verb, "args": args, "label": f"ref-unchanged {args[0]}"}
    if verb == "no-push":
        if args:
            raise ValueError(f"no-push takes no arguments: {line.strip()!r}")
        return {"verb": verb, "args": [], "label": "no-push"}
    if len(args) not in (1, 2):
        raise ValueError(f"{verb} takes NAME [GLOB]: {line.strip()!r}")
    return {"verb": verb, "args": args, "label": " ".join([verb, *args])}


@dataclass
class Sample:
    path: Path
    id: str
    meta: dict[str, str]
    sections: dict[str, str]
    checks: list[dict]


def load_sample(path: Path) -> Sample:
    meta, body = split_frontmatter(path.read_text(encoding="utf-8"))
    missing = [key for key in REQUIRED_KEYS if not meta.get(key)]
    if missing:
        raise ValueError(f"frontmatter lacks {', '.join(missing)}")
    sections = split_sections(body)
    missing = [name for name in REQUIRED_SECTIONS if name not in sections]
    if missing:
        raise ValueError("missing section(s): " + ", ".join(f"## {name}" for name in missing))
    checks = [parse_check(line) for line in sections["Checks"].splitlines() if line.strip()]
    return Sample(path=path, id=meta["id"], meta=meta, sections=sections, checks=checks)


def sample_ids_match(path: Path, wanted: str) -> bool:
    if path.stem == wanted:
        return True
    try:
        meta, _ = split_frontmatter(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return False
    return meta.get("id") == wanted


def select_samples(samples_dir: Path, feature: str, sample_id: str | None) -> list[Path]:
    feature_dir = samples_dir / f"feature-{feature}"
    if not feature_dir.is_dir():
        raise UsageError(f"no samples folder: {feature_dir}")
    files = sorted(feature_dir.glob("*.md"))
    if not files:
        raise UsageError(f"no samples in {feature_dir}")
    if sample_id is None:
        return files
    selected = [f for f in files if sample_ids_match(f, sample_id)]
    if not selected:
        raise UsageError(f"no sample {sample_id!r} in {feature_dir}")
    return selected


# ---------------------------------------------------------------- driver: claude


def target_of(name: str, inp: dict, base: str) -> str:
    if name == "Skill":
        target = inp.get("skill", "")
    elif name == "Task":
        target = inp.get("subagent_type") or inp.get("description", "")
    elif name == "Bash":
        target = inp.get("command", "")
    elif name in ("Read", "Edit", "Write", "MultiEdit", "NotebookEdit"):
        target = inp.get("file_path") or inp.get("notebook_path") or inp.get("path", "")
    elif name in ("Glob", "Grep"):
        target = inp.get("pattern") or inp.get("path", "")
    else:
        target = next((v for v in inp.values() if isinstance(v, str)), "")
    target = str(target)
    if base and target.startswith(base + "/"):
        target = target[len(base) + 1 :]
    return target


def read_stream(stdout: str, base: str = "") -> tuple[str | None, str, list[dict]]:
    """Return (session_id, reply text, tool calls) from stream-json output, or the plain text."""
    session: str | None = None
    texts: list[str] = []
    tools: list[dict] = []
    saw_json = False
    for line in stdout.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            obj = json.loads(line)
        except ValueError:
            continue
        if not isinstance(obj, dict):
            continue
        saw_json = True
        session = session or obj.get("session_id")
        kind = obj.get("type")
        if kind == "assistant":
            for block in (obj.get("message") or {}).get("content") or []:
                if block.get("type") == "text":
                    texts.append(block.get("text", ""))
                elif block.get("type") == "tool_use":
                    name = block.get("name", "")
                    tools.append({"name": name, "target": target_of(name, block.get("input") or {}, base)})
        elif kind == "tool_use":
            name = obj.get("name", "")
            tools.append({"name": name, "target": target_of(name, obj.get("input") or {}, base)})
        elif kind == "result" and not texts and isinstance(obj.get("result"), str):
            texts.append(obj["result"])
    if not saw_json:
        return None, stdout.strip(), []
    return session, "\n\n".join(t for t in texts if t).strip(), tools


def run_cli(cli: str, args: list[str], *, cwd: Path, env: dict, stdin: str) -> str:
    """One call of an agent CLI (claude or codex) with the prompt on stdin; returns its stdout.
    A timeout, a start failure or a non-zero exit raises RunError, naming the CLI."""
    try:
        proc = subprocess.run(
            [cli, *args],
            cwd=cwd,
            env=env,
            input=stdin,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=TURN_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        raise RunError(f"{cli} call timed out after {TURN_TIMEOUT} s")
    except OSError as exc:
        raise RunError(f"{cli} could not start: {exc}")
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout or "").strip()[-400:]
        raise RunError(f"{cli} exited {proc.returncode}: {tail}")
    return proc.stdout


def run_claude(args: list[str], *, cwd: Path, env: dict, stdin: str) -> str:
    """One `claude` call (the agent's turns and the simulated user and judge): see run_cli."""
    return run_cli("claude", args, cwd=cwd, env=env, stdin=stdin)


def run_codex(args: list[str], *, cwd: Path, env: dict, stdin: str) -> str:
    """One `codex` call (the Codex agent's turns): see run_cli."""
    return run_cli("codex", args, cwd=cwd, env=env, stdin=stdin)


class ClaudeCodeAgent:
    """start/send/read adapter for the agent under test: one `claude -p` call per turn."""

    def __init__(self, fixture: Path, env: dict, model: str):
        self.fixture = fixture
        self.env = env
        self.model = model
        self.session_id: str | None = None

    def start(self) -> None:
        self.session_id = None

    def send(self, message: str) -> tuple[str, list[dict]]:
        args = [
            "-p",
            "--output-format", "stream-json",
            "--verbose",
            "--permission-mode", "acceptEdits",
            "--tools", AGENT_TOOLS,
            "--allowedTools", AGENT_TOOLS,
            "--strict-mcp-config",
            "--setting-sources", "project",
            "--model", self.model,
        ]
        if self.session_id:
            args += ["--resume", self.session_id]
        out = run_claude(args, cwd=self.fixture, env=self.env, stdin=message)
        session, text, tools = read_stream(out, str(self.fixture))
        if session and not self.session_id:
            self.session_id = session
        if not self.session_id:
            raise RunError("the agent turn returned no session id, so the next turn cannot resume")
        return text, tools


class CodexAgent:
    """start/send/read adapter for the Codex host: one non-interactive `codex exec` call per turn.

    The first turn starts a thread (`codex exec --json`, its thread id read from the `thread.started`
    event); each later turn resumes that thread with `codex exec resume <thread-id>`. The prompt goes
    on stdin ("-") and the reply is read from the --output-last-message file. An empty model leaves
    the CLI's default model in place. CODEX_HOME points at the throwaway HOME's .codex folder.
    """

    def __init__(self, fixture: Path, env: dict, model: str):
        self.fixture = fixture
        self.env = env
        self.model = model
        self.session_id: str | None = None
        self.env["CODEX_HOME"] = str(Path(self.env["HOME"]) / ".codex")

    def start(self) -> None:
        self.session_id = None

    def send(self, message: str) -> tuple[str, list[dict]]:
        # Options as `codex exec --help` lists them: --json, --model, --sandbox, --approve-for-me and
        # --output-last-message; the prompt is read from stdin ("-").
        with tempfile.TemporaryDirectory(prefix="aid-codex-turn-") as turn_dir:
            last_message = Path(turn_dir) / "last-message.txt"
            args = ["exec"]
            if self.session_id:
                args += ["resume", self.session_id]
            args += ["--json"]
            if self.model:
                args += ["--model", self.model]
            if not self.session_id:
                # The resume subcommand's help (`codex exec resume --help`) lists only --json, --model
                # and --output-last-message: the usage is "codex exec resume [OPTIONS] [SESSION_ID]
                # [PROMPT]", and it shows no --sandbox and no --approve-for-me. So the resumed turn is
                # not given them, and runs under the CLI's own sandbox and approval defaults, which may
                # differ from the start turn's; a live run has not confirmed which. The start help
                # describes --sandbox as the policy for model-generated shell commands and does not say
                # it confines reads, so the fixture is not a read boundary.
                args += ["--sandbox", "workspace-write", "--approve-for-me"]
            args += ["--output-last-message", str(last_message), "-"]
            out = run_codex(args, cwd=self.fixture, env=self.env, stdin=message)
            thread_id = None
            for line in out.splitlines():
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                if isinstance(event, dict) and event.get("type") == "thread.started":
                    thread_id = event.get("thread_id")
            if thread_id and not self.session_id:
                self.session_id = str(thread_id)
            if not self.session_id:
                raise RunError("the codex turn returned no thread id, so the next turn cannot resume")
            try:
                text = last_message.read_text(encoding="utf-8").strip()
            except OSError:
                text = ""
            return text, []  # Codex JSON output is not normalized to the runner's tool-call schema.

    @staticmethod
    def available() -> tuple[bool, str]:
        """Whether the Codex host can run: the CLI is on PATH and `codex login status` reports a sign-in.
        Returns (True, "") or (False, reason); main prints the reason in its NOTICE and skips the host."""
        if shutil.which("codex") is None:
            return False, "codex CLI is not on PATH"
        try:
            proc = subprocess.run(["codex", "login", "status"], capture_output=True, text=True,
                                  encoding="utf-8", errors="replace", timeout=15)
        except (OSError, subprocess.TimeoutExpired):
            return False, "codex login status could not be checked"
        status = (proc.stdout + proc.stderr).lower()
        if proc.returncode != 0 or not re.search(r"(?m)^\s*logged in(?:\s|$)", status):
            return False, "codex is not signed in"
        return True, ""


# Other hosts: each registered host has a start/send/read adapter; unavailable CLIs are skipped.
ADAPTERS: dict[str, type] = {"claude-code": ClaudeCodeAgent, "codex": CodexAgent}


def helper_call(prompt: str, system: str, *, cwd: Path, env: dict) -> str:
    """One text-only claude call: the simulated user and the judge (no tools, no MCP, safe mode)."""
    args = [
        "-p",
        "--output-format", "text",
        "--tools", "",
        "--safe-mode",
        "--strict-mcp-config",
        "--system-prompt", system,
    ]
    out = run_claude(args, cwd=cwd, env=env, stdin=prompt)
    return read_stream(out)[1]


# ---------------------------------------------------------------- fixture and state


def base_env(home: Path) -> dict:
    env = {
        k: v
        for k, v in os.environ.items()
        if k not in ENV_DROP_NAMES and not k.startswith(ENV_DROP_PREFIXES)
    }
    env["HOME"] = str(home)
    env["AID_NO_UPDATE_CHECK"] = "1"
    return env


def git_in(fixture: Path, *args: str) -> None:
    cmd = ["git", "-C", str(fixture), "-c", "user.name=conversation", "-c", "user.email=conversation@local", *args]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RunError(f"git {' '.join(args)} failed: {proc.stderr.strip()[-300:]}")


def stage_bundle(dest: Path) -> None:
    lib = ROOT / "tests/lib/bundle.sh"
    proc = subprocess.run(
        ["bash", "-c", 'source "$1" && aid_test_stage_bundle "$2"', "stage", str(lib), str(dest)],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        raise UsageError(f"staging the AID bundle failed: {(proc.stderr or proc.stdout).strip()[-400:]}")


def build_fixture(sample: Sample, fixtures_dir: Path, bundle: Path, real_home: Path, work: Path) -> tuple[Path, Path]:
    source = fixtures_dir / sample.meta["fixture"]
    if not source.is_dir():
        raise RunError(f"fixture folder not found: {source}")
    fixture = work / "project"
    home = work / "home"
    state = work / "aid-state"
    shutil.copytree(source, fixture, symlinks=True)
    (home / ".claude").mkdir(parents=True)
    state.mkdir()
    creds = real_home / ".claude" / ".credentials.json"
    if creds.is_file():
        shutil.copy2(creds, home / ".claude" / ".credentials.json")
    codex_home = Path(os.environ.get("CODEX_HOME") or (real_home / ".codex"))
    codex_auth = codex_home / "auth.json"
    if codex_auth.is_file():
        (home / ".codex").mkdir(parents=True, exist_ok=True)
        shutil.copy2(codex_auth, home / ".codex" / "auth.json")
    env = base_env(home)
    env["AID_HOME"] = str(state)
    proc = subprocess.run(
        ["bash", str(ROOT / "bin/aid"), "add", "claude-code", "--target", str(fixture), "--from-bundle", str(bundle)],
        cwd=fixture,
        env=env,
        capture_output=True,
        text=True,
        timeout=TURN_TIMEOUT,
    )
    if proc.returncode != 0:
        raise RunError("AID install into the fixture failed: " + (proc.stdout + proc.stderr).strip()[-400:])
    git_in(fixture, "init", "-q")
    git_in(fixture, "add", "-A")
    git_in(fixture, "commit", "-q", "--allow-empty", "-m", "fixture baseline")
    branch = sample.meta.get("branch", "")
    if branch:  # a work branch with one commit of its own, checked out back on the default branch
        git_in(fixture, "checkout", "-q", "-b", branch)
        git_in(fixture, "commit", "-q", "--allow-empty", "-m", f"{branch} work commit")
        git_in(fixture, "checkout", "-q", "-")
    return fixture, home


# ---------------------------------------------------------------- capture


def fixture_skip(rel: str, is_dir: bool) -> bool:
    return rel == ".git" or rel.startswith(".git/")


def home_skip(rel: str, is_dir: bool) -> bool:
    if rel == ".claude" or rel.startswith(".claude/") or rel == ".claude.json":
        return True
    if rel in HOME_SETUP_FILES or any(rel == d or rel.startswith(d + "/") for d in HOME_SETUP_DIRS):
        return True
    return bool(CREDENTIAL_RE.search(os.path.basename(rel)))


LINK_PREFIX = b"\0symlink -> "  # a link's snapshot entry starts with NUL
REGULAR_TAG = b"\1"  # a regular file's snapshot entry starts with this byte, so no regular file's entry equals a link's


def snapshot(root: Path, skip) -> tuple[dict[str, bytes], set[str]]:
    """The files and the directories under root that skip does not drop. A symbolic link is recorded as a
    file whose content is its target text (LINK_PREFIX + target), so a link created, removed or retargeted
    shows as a change; a link is never followed, so no file it points at is read. A regular file's entry is
    REGULAR_TAG + its bytes, so a regular file whose bytes equal a link's entry is still a different entry."""
    files: dict[str, bytes] = {}
    dirs: set[str] = set()
    for dirpath, dirnames, filenames in os.walk(root):
        here = Path(dirpath)
        rel_here = here.relative_to(root)
        kept = []
        for name in dirnames:
            rel = (rel_here / name).as_posix()
            if skip(rel, True):
                continue
            if (here / name).is_symlink():
                files[rel] = LINK_PREFIX + os.fsencode(os.readlink(here / name))  # a linked directory: never descended
                continue
            kept.append(name)
            dirs.add(rel)
        dirnames[:] = kept
        for name in filenames:
            rel = (rel_here / name).as_posix()
            path = here / name
            if skip(rel, False):
                continue
            if path.is_symlink():
                files[rel] = LINK_PREFIX + os.fsencode(os.readlink(path))  # a linked file: its target text, never read through
                continue
            if not path.is_file():
                continue
            files[rel] = REGULAR_TAG + path.read_bytes()
    return files, dirs


def capture(fixture: Path, home: Path) -> tuple[dict[str, bytes], set[str]]:
    fixture_files, fixture_dirs = snapshot(fixture, fixture_skip)
    home_files, _ = snapshot(home, home_skip)
    state = {f"fixture/{k}": v for k, v in fixture_files.items()}
    state.update({f"home/{k}": v for k, v in home_files.items()})
    return state, fixture_dirs


def is_binary(data: bytes) -> bool:
    if b"\0" in data:
        return True
    try:
        data.decode("utf-8")
    except UnicodeDecodeError:
        return True
    return False


def worktree_baseline(rel: str) -> str | None:
    """The fixture file a file under the fixture's .claude/worktrees/<wt>/ is compared with: the same
    relative path in the fixture itself. None for any other path."""
    if not rel.startswith(WORKTREES_PREFIX):
        return None
    parts = rel[len(WORKTREES_PREFIX):].split("/", 1)
    if len(parts) != 2 or not parts[1]:
        return None
    return "fixture/" + parts[1]


def untagged(entry: bytes | None) -> bytes | None:
    """The content of a snapshot entry: a regular file's bytes without REGULAR_TAG; a link's entry as it is."""
    if entry is not None and entry.startswith(REGULAR_TAG):
        return entry[len(REGULAR_TAG):]
    return entry


def diff_chunks(before: dict[str, bytes], after: dict[str, bytes]) -> list[tuple[str, str]]:
    """One (path, text) pair per changed file, in path order; byte-identical entries are omitted, and a
    regular file never equals a link, whatever their bytes. An empty file added or removed has no lines, so
    its text is git's header alone (no hunk) and it is still named."""
    chunks: list[tuple[str, str]] = []
    for rel in sorted(set(before) | set(after)):
        old_key = rel
        baseline = worktree_baseline(rel)
        if baseline is not None and rel not in before:
            old_key = baseline  # a worktree file the run created is compared with the fixture's file
        old, new = before.get(old_key), after.get(rel)
        if old == new:
            continue
        old, new = untagged(old), untagged(new)
        if (old is not None and is_binary(old)) or (new is not None and is_binary(new)):
            if old is None:
                text = f"Binary file {rel} added ({len(new)} bytes)\n"
            elif new is None:
                text = f"Binary file {rel} removed ({len(old)} bytes)\n"
            else:
                text = f"Binary file {rel} changed ({len(old)} -> {len(new)} bytes)\n"
            chunks.append((rel, text))
            continue
        old_lines = (old or b"").decode("utf-8").splitlines(keepends=True)
        new_lines = (new or b"").decode("utf-8").splitlines(keepends=True)
        text = "".join(
            difflib.unified_diff(
                old_lines,
                new_lines,
                fromfile="/dev/null" if old is None else f"a/{old_key}",
                tofile="/dev/null" if new is None else f"b/{rel}",
            )
        )
        if text and not text.endswith("\n"):
            text += "\n"
        if not text and (old is None or new is None):  # an empty file added or removed: no hunk to show
            text = f"diff --git a/{old_key} b/{rel}\n" + ("new file mode 100644\n" if old is None else "deleted file mode 100644\n")
        chunks.append((rel, text))
    return chunks


def build_diff(before: dict[str, bytes], after: dict[str, bytes]) -> str:
    """files.diff: every change, in full."""
    return "".join(text for _, text in diff_chunks(before, after))


def judge_view(chunks: list[tuple[str, str]]) -> str:
    """The diff the judge reads, at most JUDGE_TOTAL_BYTES in all: each file cut at JUDGE_FILE_LINES, and
    every cut marked "[... N lines of <path> truncated ...]". The markers count inside the cap. At most
    JUDGE_MAX_MARKERS files get a marker; the rest are counted in one final "[... N more files truncated ...]"
    line, which sits in the bytes reserved for it. files.diff on disk is not cut."""
    ceiling = JUDGE_TOTAL_BYTES - JUDGE_SUMMARY_BYTES  # the room kept for the final summary line
    out: list[str] = []
    used = 0
    markers = 0
    unlisted = 0
    for rel, text in chunks:
        lines = text.splitlines(keepends=True)
        # room for this file's own marker if it is cut: its hidden count is at most len(lines)
        room = ceiling - len(f"[... {len(lines)} lines of {rel} truncated ...]\n".encode("utf-8"))
        shown: list[str] = []
        for line in lines[:JUDGE_FILE_LINES]:
            size = len(line.encode("utf-8"))
            if used + size > room:
                break
            shown.append(line)
            used += size
        out.append("".join(shown))
        hidden = len(lines) - len(shown)
        if not hidden:
            continue
        marker = f"[... {hidden} lines of {rel} truncated ...]\n"
        size = len(marker.encode("utf-8"))
        if markers < JUDGE_MAX_MARKERS and used + size <= ceiling:
            out.append(marker)
            used += size
            markers += 1
        else:
            unlisted += 1
    if unlisted:
        out.append(f"[... {unlisted} more files truncated ...]\n")
    return "".join(out)


# ---------------------------------------------------------------- checks

HEREDOC_START = re.compile(r"<<(-?)\s*(['\"]?)(\w+)\2")
GIT_VALUE_OPTIONS = ("-C", "-c", "--git-dir", "--work-tree", "--namespace")  # git's global options that take a value
SHELLS = ("sh", "bash", "zsh", "dash")
SHELL_C_FLAG = re.compile(r"^-[A-Za-z]*c[A-Za-z]*$")  # -c, or a combined flag that holds c: -lc, -ec
WRAPPERS = ("env", "command", "exec", "nohup", "sudo")  # commands that run the command given after them
WRAPPER_VALUE_OPTIONS = {  # the wrappers' options that take the next word as their value (short and long forms)
    "env": ("-u", "--unset", "-C", "--chdir"),
    "exec": ("-a",),
    "sudo": ("-u", "-g", "-C", "-h", "-p", "-D", "-r", "-t", "-U", "-T",
             "--user", "--group", "--host", "--prompt", "--chdir", "--close-from", "--role", "--type", "--other-user"),
}
ENV_SPLIT_OPTIONS = ("-S", "--split-string")  # env's option whose value is a command line, checked as a command
SHELL_PUNCTUATION = "();<>|&`"  # shlex returns these as tokens; a token made only of them ends a command


def strip_heredocs(command: str) -> str:
    """The command with each heredoc body removed: the lines from <<WORD to the line that is WORD."""
    kept, end, dash = [], None, False
    for line in command.split("\n"):
        if end is not None:
            if (line.lstrip("\t") if dash else line) == end:
                end = None
            continue
        kept.append(line)
        match = HEREDOC_START.search(line)
        if match:
            dash, end = match.group(1) == "-", match.group(3)
    return "\n".join(kept)


def is_git_push(command: str) -> bool:
    """True when a shell command runs git push. Each command segment (split on ; && || | and newlines) is
    checked: its command is git, after any VAR=value prefix and git's global options, and its subcommand
    is push. Heredoc bodies and quoted text are not commands, so prose that names git push does not count;
    a shell's -c string (also behind combined flags such as -lc) is checked as a command of its own, and
    so is the command that a wrapper (env, command, exec, nohup, sudo) runs. command -v and -V only look a
    name up and run nothing, so they are not a push; env -S (--split-string) holds a command line that is checked."""
    text = strip_heredocs(command).replace("\\\n", " ").replace("\n", " ; ")
    try:
        lex = shlex.shlex(text, posix=True, punctuation_chars=SHELL_PUNCTUATION)
        lex.whitespace_split = True
        tokens = list(lex)
    except ValueError:  # unbalanced quotes: no reliable split, so read the text as plain text
        return bool(re.search(r"\bgit\b.*\bpush\b", text))
    segments, words = [], []
    for token in tokens:
        if token and all(char in SHELL_PUNCTUATION for char in token):
            segments.append(words)
            words = []
        else:
            words.append(token)
    segments.append(words)
    return any(segment_is_git_push(words) for words in segments)


def command_line(parts: list[str]) -> list[str]:
    """The words of a command line that is held in one word (env -S): split as a shell splits words."""
    if not parts:
        return []
    try:
        return shlex.split(parts[0])
    except ValueError:  # unbalanced quotes: no words to check
        return []


def command_looks_up(words: list[str]) -> bool:
    """True when command's own options (-v, -V, also combined as -pv) ask for a lookup: it names a command."""
    for word in words[1:]:
        if not word.startswith("-") or word == "-":
            return False
        if set(word[1:]) & set("vV"):
            return True
    return False


def wrapped_words(words: list[str]) -> list[str]:
    """The words a wrapper runs: those after its own options, their values and VAR=value operands. A value
    is skipped with its option, as --opt value or --opt=value; flag-only options are skipped alone. env's
    -S (--split-string) value is a command line of its own, so its words stand in its place."""
    name = os.path.basename(words[0])
    values = WRAPPER_VALUE_OPTIONS.get(name, ())
    index = 1
    while index < len(words):
        word = words[index]
        if name == "env" and word in ENV_SPLIT_OPTIONS:
            return command_line(words[index + 1 : index + 2]) + words[index + 2 :]
        if name == "env" and word.startswith(("-S", "--split-string=")):
            value = word.split("=", 1)[1] if word.startswith("--") else word[2:]
            return command_line([value]) + words[index + 1 :]
        if word in values:
            index += 2
        elif word.startswith("-") or re.match(r"^\w+=", word):
            index += 1
        else:
            break
    return words[index:]


def segment_is_git_push(words: list[str]) -> bool:
    while words and re.match(r"^\w+=", words[0]):  # leading VAR=value assignments
        words = words[1:]
    if not words:
        return False
    program = os.path.basename(words[0])
    if program == "command" and command_looks_up(words):
        return False  # command -v / -V names a command and runs none
    if False:
        return segment_is_git_push(wrapped_words(words))
    if program in SHELLS:
        for index in range(1, len(words)):
            if words[index] == "-c":
                return index + 1 < len(words) and is_git_push(words[index + 1])
        return False
    if program != "git":
        return False
    index = 1
    while index < len(words) and words[index].startswith("-"):
        index += 2 if words[index] in GIT_VALUE_OPTIONS else 1
    return index < len(words) and words[index] == "push"


def inside(fixture: Path, rel: str) -> Path:
    target = (fixture / rel).resolve()
    if fixture.resolve() not in (target, *target.parents):
        raise ValueError(f"path leaves the fixture: {rel}")
    return target


def ref_shas(fixture: Path) -> dict[str, str]:
    """The commit of each local branch, and under "HEAD" the branch checked out (empty when detached)."""
    refs: dict[str, str] = {}
    listing = subprocess.run(
        ["git", "-C", str(fixture), "for-each-ref", "--format=%(refname:short) %(objectname)", "refs/heads"],
        capture_output=True, text=True,
    )
    for line in listing.stdout.splitlines():
        name, _, sha = line.partition(" ")
        if name and sha:
            refs[name] = sha
    head = subprocess.run(
        ["git", "-C", str(fixture), "symbolic-ref", "--short", "-q", "HEAD"], capture_output=True, text=True
    )
    refs["HEAD"] = head.stdout.strip()
    return refs


def run_checks(checks: list[dict], fixture: Path, dirs_before: set[str], dirs_after: set[str], tools: list[dict], host: str = "claude-code", refs_before: dict[str, str] | None = None, refs_after: dict[str, str] | None = None):
    results: list[tuple[str, bool | None, str]] = []
    refs_before = refs_before or {}
    refs_after = refs_after or {}
    for check in checks:
        verb, args = check["verb"], check["args"]
        if host == "codex" and verb in ("no-push", "tool-called", "tool-not-called"):
            results.append((check["label"], None, "Codex output does not expose normalized tool calls"))
            continue
        try:
            if verb in ("exists", "absent", "contains"):
                path = inside(fixture, args[0])
            if verb == "exists":
                ok, detail = path.exists(), "" if path.exists() else "missing"
            elif verb == "absent":
                ok, detail = not path.exists(), "" if not path.exists() else "present"
            elif verb == "contains":
                text = path.read_text(encoding="utf-8", errors="replace") if path.is_file() else None
                ok = text is not None and args[1] in text
                detail = "" if ok else ("no such file" if text is None else "text not found")
            elif verb == "no-new-dir":
                target = args[0].rstrip("/")
                bad = [d for d in sorted(dirs_after - dirs_before) if d == target or os.path.dirname(d) == target]
                ok, detail = not bad, "" if not bad else "created: " + ", ".join(bad)
            elif verb == "ref-unchanged":
                name = refs_before.get("HEAD", "") if args[0] == "default" else args[0]
                before_sha = refs_before.get(name) if name else None
                ok = before_sha is not None and refs_after.get(name) == before_sha
                detail = "" if ok else (f"no branch {name!r} before the run" if before_sha is None else f"{name} moved or was removed")
            elif verb == "no-push":
                bad = [t["target"] for t in tools if t["name"] == "Bash" and is_git_push(t["target"])]
                ok, detail = not bad, "" if not bad else "push call: " + bad[0]
            else:
                name = args[0]
                glob = args[1] if len(args) == 2 else None
                hits = [t for t in tools if t["name"] == name and (glob is None or fnmatch.fnmatchcase(t["target"], glob))]
                called = bool(hits)
                ok = called if verb == "tool-called" else not called
                detail = "" if ok else ("no matching call" if verb == "tool-called" else f"{len(hits)} matching call(s)")
        except (OSError, ValueError) as exc:
            ok, detail = False, str(exc)
        results.append((check["label"], ok, detail))
    return results


def render_checks(results: list[tuple[str, bool | None, str]]) -> str:
    if not results:
        return "(no checks)\n"
    lines = []
    for label, ok, detail in results:
        mark = "PASS" if ok is True else "FAIL" if ok is False else "NOT RUN"
        lines.append(f"{mark} {label}" + (f" -- {detail}" if detail and ok is not True else ""))
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------- conversation and judge


def opening_message(sample: Sample) -> str:
    return re.split(r"\n\s*\n", sample.sections["User"].strip())[0].strip()


def render_transcript_md(transcript: list[dict]) -> str:
    out = ["# Transcript", ""]
    for entry in transcript:
        who = "User" if entry["role"] == "user" else "Agent"
        out += [f"## Turn {entry['turn']} -- {who}", "", entry["text"] or "(empty)", ""]
        if entry["tools"]:
            calls = ", ".join(f"{t['name']}({t['target']})" for t in entry["tools"])
            out += [f"Tool calls: {calls}", ""]
    return "\n".join(out) + "\n"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def ask_user(brief: str, sample: Sample, transcript: list[dict], scratch: Path, env: dict) -> str:
    prompt = (
        f"{END_FIRST_RULE}\n\n"
        f"## Persona (from the sample)\n\n{sample.sections['User']}\n\n"
        f"## Answer sheet\n\n{sample.sections['Answer sheet']}\n\n"
        f"## Transcript so far\n\n{render_transcript_md(transcript)}\n"
        f"Write the simulated user's next message, or {END_MARK} if the sheet has nothing left to say "
        "or the agent has finished.\n"
    )
    reply = helper_call(prompt, brief, cwd=scratch, env=env)
    return reply or "I don't know."


def run_conversation(agent, brief: str, sample: Sample, transcript: list[dict], scratch: Path, env: dict) -> None:
    message = opening_message(sample)
    agent.start()
    for turn in range(1, TURN_CAP + 1):
        transcript.append({"turn": turn, "role": "user", "text": message, "tools": [], "ts": now()})
        reply, tools = agent.send(message)
        transcript.append({"turn": turn, "role": "agent", "text": reply, "tools": tools, "ts": now()})
        nxt = ask_user(brief, sample, transcript, scratch, env)
        if END_MARK in nxt:
            return
        message = nxt
    raise RunError(f"no {END_MARK} within {TURN_CAP} user turns (turn cap)")


def installed_reviewer_body(fixture: Path) -> str:
    agent_file = fixture / ".claude/agents/aid-reviewer.md"
    if not agent_file.is_file():
        raise RunError("the installed aid-reviewer agent is missing from the fixture")
    text = agent_file.read_text(encoding="utf-8")
    try:
        _, body = split_frontmatter(text)
    except ValueError:
        return text
    return body


def judge(fixture: Path, sample: Sample, judge_brief: str, transcript_md: str, diff: str,
          checks_txt: str, helper_dir: Path, env: dict) -> str:
    system = installed_reviewer_body(fixture) + "\n\n" + judge_brief
    prompt = (
        f"## transcript.md\n\n{transcript_md}\n"
        f"## files.diff\n\n```diff\n{diff or '(no changes)'}\n```\n\n"
        f"## checks.txt\n\n{checks_txt}\n"
        f"## Expected outcome\n\n{sample.sections['Expected outcome']}\n\n"
        f"## Must not\n\n{sample.sections['Must not']}\n"
    )
    return helper_call(prompt, system, cwd=helper_dir, env=env)


def ledger_status(text: str) -> tuple[bool, int]:
    """Return (has a ledger table, number of Pending rows in the LAST ledger table).

    A ledger table has the seven columns of LEDGER_COLUMNS. A judge that drops the Evidence column
    writes a six-column table (the first six columns, in order); it is accepted too, so its Pending
    rows still count. A judge that corrects itself writes a table, then a correction, then a second
    table; the last table is the verdict. Rows are grouped under the header that opens them, so rows
    of an earlier table never count against a later one. A row is split on its unescaped pipes only:
    an escaped \\| (the schema's form for a literal pipe inside a cell) stays in its cell.
    """
    tables: list[list[list[str]]] = []
    width = 0  # cells per row of the table that is open
    for line in text.splitlines():
        s = line.strip()
        if not (s.startswith("|") and s.endswith("|")):
            continue
        cells = [c.strip() for c in re.split(r"(?<!\\)\|", s[1:-1])]
        if cells == list(LEDGER_COLUMNS):
            tables.append([])
            width = len(LEDGER_COLUMNS)
        elif cells == list(LEDGER_COLUMNS[:6]):  # the header without its Evidence column
            tables.append([])
            width = 6
        elif tables and len(cells) == width:
            tables[-1].append(cells)
    if not tables:
        return False, 0
    pending = sum(1 for cells in tables[-1] if cells[0].isdigit() and cells[2].lower() == "pending")
    return True, pending


# ---------------------------------------------------------------- one run


def run_once(sample: Sample, n: int, run_dir: Path, ctx: dict, host: str = "claude-code") -> list[str]:
    run_dir.mkdir(parents=True, exist_ok=True)
    reasons: list[str] = []
    model = ctx["codex_model"] if host == "codex" else ctx["model"]  # the model this host's agent runs with
    work = Path(tempfile.mkdtemp(prefix="aid-conv-run-"))
    transcript: list[dict] = []
    checks_txt = ""
    diff = ""
    ledger = ""
    try:
        fixture, home = build_fixture(sample, ctx["fixtures_dir"], ctx["bundle"], ctx["real_home"], work)
        env = base_env(home)
        fixture_bin = fixture / "bin"
        agent_env = dict(env)
        if fixture_bin.is_dir():
            agent_env["PATH"] = str(fixture_bin) + os.pathsep + env.get("PATH", "")
        before, dirs_before = capture(fixture, home)
        refs_before = ref_shas(fixture)
        helper_dir = work / "helper"  # empty, outside the fixture: the simulated user and the judge run here
        helper_dir.mkdir()
        agent = ADAPTERS[host](fixture, agent_env, model)
        try:
            run_conversation(agent, ctx["user_brief"], sample, transcript, helper_dir, env)
        except RunError as exc:
            reasons.append(f"conversation: {exc}")
        after, dirs_after = capture(fixture, home)
        refs_after = ref_shas(fixture)
        chunks = diff_chunks(before, after)
        diff = "".join(text for _, text in chunks)
        tools = [t for e in transcript if e["role"] == "agent" for t in e["tools"]]
        results = run_checks(sample.checks, fixture, dirs_before, dirs_after, tools, host, refs_before, refs_after)
        checks_txt = render_checks(results)
        reasons += [f"check: {label} -- {detail}" for label, ok, detail in results if ok is False]
        transcript_md = render_transcript_md(transcript)
        try:
            ledger = judge(fixture, sample, ctx["judge_brief"], transcript_md, judge_view(chunks),
                           checks_txt, helper_dir, env)
            has_table, pending = ledger_status(ledger)
            if not has_table:
                reasons.append("judge: no 7-column ledger table in the output")
            elif pending:
                reasons.append(f"judge: {pending} Pending row(s) in the ledger")
            saved = fixture / ".aid/.temp/review-pending"
            saved.mkdir(parents=True, exist_ok=True)
            (saved / f"conversation-{sample.id}-run-{n}.md").write_text(ledger, encoding="utf-8")
        except RunError as exc:
            reasons.append(f"judge: {exc}")
    except (RunError, OSError) as exc:
        reasons.append(f"setup: {exc}")
    finally:
        (run_dir / "transcript.jsonl").write_text(
            "".join(json.dumps(e, ensure_ascii=False) + "\n" for e in transcript), encoding="utf-8"
        )
        (run_dir / "transcript.md").write_text(render_transcript_md(transcript), encoding="utf-8")
        (run_dir / "files.diff").write_text(diff, encoding="utf-8")
        (run_dir / "checks.txt").write_text(checks_txt, encoding="utf-8")
        (run_dir / "ledger.md").write_text(ledger.rstrip("\n") + "\n" if ledger else "", encoding="utf-8")
        (run_dir / "model.txt").write_text((model or "Codex CLI default") + "\n", encoding="utf-8")
        shutil.rmtree(work, ignore_errors=True)
    return reasons


# ---------------------------------------------------------------- main


def parse_hosts(raw: str) -> list[str]:
    hosts = [h.strip() for h in raw.split(",") if h.strip()]
    if not hosts:
        raise UsageError("at least one host is required")
    unknown = [h for h in hosts if h not in KNOWN_HOSTS]
    if unknown:
        raise UsageError("unknown host(s): " + ", ".join(unknown))
    return hosts


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Conversation test suite (NFR-T).")
    parser.add_argument("--feature", required=True, help="three-digit feature number, for example 001")
    parser.add_argument("--sample", help="one sample id; default every sample of the feature")
    parser.add_argument("--hosts", default=",".join(DEFAULT_HOSTS), help="comma-separated hosts")
    parser.add_argument("--runs", type=int, default=3, help="runs per sample (default 3)")
    parser.add_argument("--samples-dir", type=Path, default=DEFAULT_SAMPLES_DIR)
    parser.add_argument("--fixtures-dir", type=Path, default=DEFAULT_FIXTURES_DIR)
    parser.add_argument("--briefs-dir", type=Path, default=DEFAULT_BRIEFS_DIR,
                        help="folder holding simulated-user.md and judge.md")
    parser.add_argument("--validate", action="store_true", help="parse the samples and run nothing")
    args = parser.parse_args(argv)

    try:
        if not re.fullmatch(r"\d{3}", args.feature):
            raise UsageError("--feature takes three digits, for example 001")
        if args.runs < 1:
            raise UsageError("--runs must be at least 1")
        hosts = parse_hosts(args.hosts)
        files = select_samples(args.samples_dir, args.feature, args.sample)
    except UsageError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    samples: list[Sample] = []
    errors: list[str] = []
    for path in files:
        try:
            samples.append(load_sample(path))
        except ValueError as exc:
            errors.append(f"{path}: {exc}")

    if args.validate:
        for error in errors:
            print(f"INVALID {error}")
        for sample in samples:
            print(f"OK {sample.id} ({len(sample.checks)} checks)")
        return 1 if errors else 0

    if errors:
        for error in errors:
            print(f"FAIL malformed sample: {error}")
        return 1

    if "claude-code" not in hosts:
        print("NOTICE: claude-code is required for the simulated user and judge; it runs too")
        hosts.insert(0, "claude-code")
    if shutil.which("claude") is None:
        print("error: the claude CLI is not on PATH", file=sys.stderr)
        return 2
    try:
        user_brief = (args.briefs_dir / "simulated-user.md").read_text(encoding="utf-8")
        judge_brief = (args.briefs_dir / "judge.md").read_text(encoding="utf-8")
    except OSError as exc:
        print(f"error: cannot read a brief: {exc}", file=sys.stderr)
        return 2

    work_root = Path(tempfile.mkdtemp(prefix="aid-conv-bundle-"))
    try:
        bundle = work_root / "bundle"
        try:
            stage_bundle(bundle)
        except UsageError as exc:
            print(f"error: {exc}", file=sys.stderr)
            return 2
        ctx = {
            "fixtures_dir": args.fixtures_dir,
            "bundle": bundle,
            "real_home": Path(os.environ.get("HOME", str(Path.home()))),
            "user_brief": user_brief,
            "judge_brief": judge_brief,
            "model": os.environ.get(MODEL_ENV) or DEFAULT_MODEL,
            "codex_model": os.environ.get("AID_CODEX_MODEL") or "",  # empty: the Codex CLI's default model
        }
        any_failed = False
        for host in hosts:
            if host not in ADAPTERS:
                print(f"NOTICE: no non-interactive adapter for host {host}; skipped")
                continue
            if host == "codex":
                available, reason = CodexAgent.available()
                if not available:
                    print(f"NOTICE: {reason}; codex host skipped")
                    continue
            run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + f"-{host}-{os.getpid()}"
            for sample in samples:
                failed_runs = 0
                for n in range(1, args.runs + 1):
                    run_dir = RUN_ROOT / run_id / sample.id / f"run-{n}"
                    reasons = run_once(sample, n, run_dir, ctx, host)
                    if reasons:
                        failed_runs += 1
                        print(f"FAIL {host} {sample.id} run {n}/{args.runs} -> {run_dir}")
                        for reason in reasons:
                            print(f"    {reason}")
                    else:
                        print(f"PASS {host} {sample.id} run {n}/{args.runs} -> {run_dir}")
                verdict = "PASS" if failed_runs == 0 else "FAIL"
                print(f"{verdict} {host} {sample.id}: {args.runs - failed_runs}/{args.runs} runs passed")
                any_failed = any_failed or failed_runs > 0
        return 1 if any_failed else 0
    finally:
        shutil.rmtree(work_root, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
