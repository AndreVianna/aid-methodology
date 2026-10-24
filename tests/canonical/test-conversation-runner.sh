#!/usr/bin/env bash
# test-conversation-runner.sh -- guards tests/conversation/run.py, the conversation test runner (NFR-T).
#
# run.py drives the agent under test through scripted sample conversations, captures each run and
# has a judge rule on it. Nothing here calls a real model. Stub `claude` and `codex` CLIs are put
# first on PATH; they log calls and answer in the shapes run.py reads. The suite builds its own tree (samples/feature-900,
# fixtures/stub, briefs) and passes it with --samples-dir, --fixtures-dir and --briefs-dir, so it
# reads no committed sample, fixture or brief. HOME and TMPDIR are pinned to temporary folders, and
# no network call is made.
#
# run.py installs AID through tests/lib/bundle.sh, which stages a release through release.sh and
# takes its artifacts from profiles/. The suite is therefore a copy-reading suite: it runs where the
# resync has written profiles/.
#
# COVERS: tests/conversation/
#
# Groups (a filter, so a failing group can be re-run alone):
#   EXIT VALIDATE CAPTURE FLAGS DIFF JUDGE ENV END BRIEFS CHECKS CLEAN LEDGER SAMPLES VSAMPLES CAP CODEX HELPERS EVIDENCE RAW MCP PROTO HOOK
#
# Each behaviour of the harness that a group guards has a mutation: a throwaway copy of run.py (or of
# a brief) with that one behaviour broken. The group asserts that its check fails on the mutant, so a
# check that would pass on a broken harness is itself a failure. The copies sit under tests/conversation/
# for the length of the suite and are removed on exit.
#
# Usage:
#   bash test-conversation-runner.sh [--group NAME] [--verbose]
#   AID_CONV_RUNNER=<path>  runs that run.py copy instead of tests/conversation/run.py (used to check
#                           that each group fails when its behaviour is broken). The copy must sit
#                           inside the repository tree at a path whose third parent is the repository
#                           root, e.g. tests/conversation/<name>.py: run.py derives ROOT from its own
#                           path, which sets its install bundle and its run folders. This suite cleans
#                           up only under the repository's own .aid/.temp/conversation-tests.
# Exit codes: 0 all pass (or SKIP without python3) / 1 any fail / 2 bad usage.

set -uo pipefail

VERBOSE=0
GROUP=""
while [ $# -gt 0 ]; do
    case "$1" in
        -v|--verbose) VERBOSE=1; shift ;;
        --group) GROUP="${2:-}"; shift 2 ;;
        -h|--help) sed -n '2,/^$/p' "$0"; exit 0 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done
ALL_GROUPS="EXIT VALIDATE CAPTURE FLAGS DIFF JUDGE ENV END BRIEFS CHECKS CLEAN LEDGER SAMPLES VSAMPLES CAP CODEX HELPERS EVIDENCE RAW MCP PROTO HOOK"
if [ -n "$GROUP" ] && ! [[ " $ALL_GROUPS " == *" $GROUP "* ]]; then
    echo "unknown group: $GROUP (groups: $ALL_GROUPS)" >&2
    exit 2
fi
want() { [ -z "$GROUP" ] || [ "$GROUP" = "$1" ]; }

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

echo "=== conversation runner (tests/conversation/run.py) ==="

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="${AID_CONV_RUNNER:-$REPO_ROOT/tests/conversation/run.py}"
PY="$(command -v python3 || true)"
if [ -z "$PY" ]; then
    echo "SKIP: python3 unavailable -- conversation runner suite cannot run"
    test_summary
    exit $?
fi

# --- temporary tree, pinned HOME and TMPDIR ----------------------------------
T="$(mktemp -d)"
T="$(cd "$T" && pwd -P)"
RUN_ROOT="$REPO_ROOT/.aid/.temp/conversation-tests"
RUN_SNAP="$T/run-root-before"
RUN_ROOT_EXISTED=0
[ -d "$RUN_ROOT" ] && RUN_ROOT_EXISTED=1
TEMP_EXISTED=0
[ -d "$REPO_ROOT/.aid/.temp" ] && TEMP_EXISTED=1
if [ -d "$RUN_ROOT" ]; then ls -A "$RUN_ROOT" > "$RUN_SNAP"; else : > "$RUN_SNAP"; fi

MUT_FILES=()
PYCACHE="$REPO_ROOT/tests/conversation/__pycache__"
PYCACHE_EXISTED=0
[ -d "$PYCACHE" ] && PYCACHE_EXISTED=1
cleanup() {
    rm -f -- "${MUT_FILES[@]}"
    # the mutant copies are loaded by the suite (spec_from_file_location); the bytecode they leave is removed,
    # and a __pycache__ the suite itself created is removed with them
    rm -f -- "$PYCACHE"/mut-*.pyc
    [ "$PYCACHE_EXISTED" -eq 1 ] || rmdir "$PYCACHE" 2>/dev/null
    # run.py names each run folder <timestamp>-<host>-<pid> with the pid of its own process. The suite
    # records the pid of every run.py it starts (log/run-pids) and removes only the folders carrying one
    # of those pids that were not there before the suite began. A concurrent run.py in the same tree
    # keeps its folders.
    if [ -d "$RUN_ROOT" ]; then
        while IFS= read -r entry; do
            [ -n "$entry" ] || continue
            grep -qxF -- "$entry" "$RUN_SNAP" && continue
            pid="${entry##*-}"
            grep -qxF -- "$pid" "$T/log/run-pids" 2>/dev/null && rm -rf -- "$RUN_ROOT/$entry"
        done < <(ls -A "$RUN_ROOT")
        [ "$RUN_ROOT_EXISTED" -eq 1 ] || rmdir "$RUN_ROOT" 2>/dev/null
    fi
    [ "$TEMP_EXISTED" -eq 1 ] || rmdir "$REPO_ROOT/.aid/.temp" 2>/dev/null
    rm -rf -- "$T"
}
trap cleanup EXIT

BIN="$T/bin"
mkdir -p "$BIN" "$T/empty" "$T/tmp" "$T/home" "$T/log"
export HOME="$T/home" TMPDIR="$T/tmp" AID_NO_UPDATE_CHECK=1
export PYTHONDONTWRITEBYTECODE=1  # no __pycache__ of the runner or of its mutant copies inside the tree
export PATH="$BIN:$PATH"
unset AID_CONV_MODEL  # the default model is asserted; a maintainer's override must not leak in
unset AID_CODEX_MODEL CODEX_HOME  # likewise the Codex model and folder: run.py copies the sign-in from CODEX_HOME when set

# --- the stub claude ----------------------------------------------------------
cat > "$BIN/claude" <<'PYSTUB'
#!/usr/bin/env python3
# Stub claude for test-conversation-runner.sh. Logs each call to $CONV_STUB_LOG, then answers:
# an agent turn (stream-json) with a session, tool calls and writes on turn 1 (with STUB_HOOK=1, also a
# message the question-form hook withdrew, and its line in $AID_QUESTION_HOOK_LOG); the simulated user
# (plain text) per $STUB_USER; the judge (plain text) per $STUB_JUDGE.
import json
import os
import subprocess
import sys

argv = sys.argv[1:]
prompt = sys.stdin.read()
log = os.environ["CONV_STUB_LOG"]
fmt = argv[argv.index("--output-format") + 1] if "--output-format" in argv else ""
system = argv[argv.index("--system-prompt") + 1] if "--system-prompt" in argv else ""
if fmt == "stream-json":
    role = "agent"
elif "USER-BRIEF-MARK" in system:
    role = "user"
elif "JUDGE-BRIEF-MARK" in system:
    role = "judge"
else:
    role = "unknown"
prior = []
if os.path.exists(log):
    with open(log, encoding="utf-8") as fh:
        prior = [json.loads(line) for line in fh if line.strip()]
count = sum(1 for c in prior if c["role"] == role) + 1
# run.py runs the judge from <run>/helper, and the fixture is <run>/project: the installed reviewer
# body the judge is given is read from there.
reviewer = None
if role == "judge":
    try:
        with open(os.path.join("..", "project", ".claude", "agents", "aid-reviewer.md"), encoding="utf-8") as fh:
            reviewer = fh.read()
    except OSError:
        reviewer = None
record = {"role": role, "argv": argv, "cwd": os.getcwd(), "home": os.environ.get("HOME", ""),
          "prompt": prompt, "reviewer": reviewer,
          "env": {k: v for k, v in os.environ.items()
                  if k.startswith(("CLAUDE", "CCR_", "SESSION_INGRESS", "HTTPS_PROXY", "NODE_EXTRA_CA_CERTS", "AID_QUESTION_HOOK"))}}
with open(log, "a", encoding="utf-8") as fh:
    fh.write(json.dumps(record) + "\n")

LEDGER_HEAD = "| # | Severity | Status | Doc | Line | Description | Evidence |\n"
LEDGER_RULE = "| --- | --- | --- | --- | --- | --- | --- |\n"
if role == "agent":
    session = "stub-session-1"
    content = [{"type": "text", "text": "Reply " + str(count) + "."}]
    if "--resume" not in argv:  # the first turn of a run; the count spans every run of an invocation
        with open("changed.txt", "w", encoding="utf-8") as fh:
            fh.write("hello from the stub\n")
        os.makedirs(".git", exist_ok=True)
        with open(os.path.join(".git", "stub-marker"), "w", encoding="utf-8") as fh:
            fh.write("x\n")
        home = os.environ["HOME"]
        os.makedirs(os.path.join(home, ".claude"), exist_ok=True)
        for rel, text in ((".claude/state.json", "{}\n"), (".claude.json", "{}\n"),
                          (".credentials.json", "{}\n"), ("id_ed25519", "stub key\n"),
                          ("tokens.md", "notes on tokens\n"), ("notes.txt", "a note\n"),
                          ("deploy.pem", "-----stub-----\n"), ("server.key", "stub key\n")):
            with open(os.path.join(home, rel), "w", encoding="utf-8") as fh:
                fh.write(text)
        os.makedirs("scratch", exist_ok=True)  # a new directory, for the no-new-dir checks
        with open(os.path.join("scratch", "notes.txt"), "w", encoding="utf-8") as fh:
            fh.write("scratch\n")
        with open("logo.bin", "wb") as fh:  # a binary file: NUL bytes, four of them
            fh.write(b"\x00\x01\x02\x03")
        for rel, text in ((".ccr/ca-bundle.crt", "stub ca\n"), (".pki/stub-nss.txt", "stub\n"),
                          (".local/share/pki/stub-db.txt", "stub\n"), (".aws/config", "stub\n"),
                          (".boto", "stub\n")):  # the sandbox's own set-up files under HOME
            path = os.path.join(home, rel)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(text)
        if os.environ.get("STUB_WORKTREE") == "1":  # a worktree the agent creates under the fixture
            wt = os.path.join(os.getcwd(), ".claude", "worktrees", "wt1")
            os.makedirs(os.path.join(wt, "src"), exist_ok=True)
            os.makedirs(os.path.join(wt, ".aid"), exist_ok=True)
            with open(os.path.join(wt, "README.md"), "w", encoding="utf-8") as fh:  # as the fixture's: omitted
                fh.write("# Stub fixture\n")
            with open(os.path.join(wt, "src", "app.py"), "w", encoding="utf-8") as fh:  # changed
                fh.write('print("stub changed")\n')
            with open(os.path.join(wt, ".aid", "state.txt"), "w", encoding="utf-8") as fh:  # new, under .aid/
                fh.write("new in the worktree\n")
        if os.environ.get("STUB_BIG") == "1":  # two large files: one over the per-file cap, one over the total
            with open("big.txt", "w", encoding="utf-8") as fh:
                fh.write("".join(f"line {i}\n" for i in range(1, 401)))
            with open("huge.txt", "w", encoding="utf-8") as fh:  # 250 lines: under the per-file cap, over the total
                fh.write("".join(f"line {i} " + "x" * 990 + "\n" for i in range(1, 251)))
            os.makedirs("many", exist_ok=True)  # 100 more large files: the total cap holds for all of them
            for j in range(1, 101):
                with open(os.path.join("many", f"f{j:03}.txt"), "w", encoding="utf-8") as fh:
                    fh.write("".join(f"file {j} line {i} " + "y" * 20 + "\n" for i in range(1, 401)))
        here = os.getcwd()
        content += [
            {"type": "tool_use", "id": "t1", "name": "Skill", "input": {"skill": "aid-plan"}},
            {"type": "tool_use", "id": "t2", "name": "Bash", "input": {"command": "git status"}},
            {"type": "tool_use", "id": "t3", "name": "Read",
             "input": {"file_path": os.path.join(here, ".aid", "knowledge", "INDEX.md")}},
        ]
        if os.environ.get("STUB_MOVE_REF") == "1":  # the agent commits on the branch that was checked out
            subprocess.run(["git", "-c", "user.name=stub", "-c", "user.email=stub@example.test", "commit",
                            "-q", "--allow-empty", "-m", "stub move"], check=False)
        if os.environ.get("STUB_PUSH") == "1":  # the agent pushes, so no-push must fail
            content.append({"type": "tool_use", "id": "t4", "name": "Bash",
                            "input": {"command": "git push origin main"}})
        review_dir = os.environ.get("CONV_STUB_REVIEW_DIR", "")
        if review_dir:  # the fixture's review-pending folder points at a folder the suite can read
            os.makedirs(review_dir, exist_ok=True)
            os.makedirs(os.path.join(".aid", ".temp"), exist_ok=True)
            os.symlink(review_dir, os.path.join(".aid", ".temp", "review-pending"))
    withdrawn_events = []
    if os.environ.get("STUB_HOOK") == "1":  # the hook sent the first message back: it stays in the stream
        withdrawn_events.append({"type": "assistant", "session_id": session, "message": {
            "id": "msg-w" + str(count), "content": [{"type": "text", "text": "Withdrawn question " + str(count) + ": shall I go on?"}]}})
        hook_log = os.environ.get("AID_QUESTION_HOOK_LOG")
        if hook_log:
            with open(hook_log, "a", encoding="utf-8") as fh:
                if count == 1:
                    fh.write("not json\n")  # an unreadable line the runner must skip
                fh.write(json.dumps({"time": "2026-01-01T00:00:00Z", "session_id": session,
                                     "missing": ["the record", "the \"Why I ask:\" line"],
                                     "message": "Withdrawn question " + str(count) + ": shall I go on?"}) + "\n")
    lines = [
        {"type": "system", "subtype": "init", "session_id": session},
        *withdrawn_events,
        {"type": "assistant", "session_id": session, "message": {"id": "msg-r" + str(count), "content": content}},
        {"type": "result", "subtype": "success", "session_id": session, "result": "Reply."},
    ]
    print("\n".join(json.dumps(item) for item in lines))
elif role == "user":
    mode = os.environ.get("STUB_USER", "end-after-one")
    if mode == "never":
        out = "Keep going."
    elif mode == "two-turns":
        out = "Second message from the persona." if count % 2 == 1 else "<<END>>"
    else:
        out = "<<END>>"
    print(out)
elif role == "judge":
    mode = os.environ.get("STUB_JUDGE", "clean")
    if mode == "no-table":
        print("The run looks fine.")
    else:
        pending = mode == "pending" or (mode == "flaky" and count == 2)
        if pending:
            print(LEDGER_HEAD + LEDGER_RULE + "| 1 | [HIGH] | Pending | transcript.md | 1 | Stub unmet item | Stub evidence |")
        else:
            print(LEDGER_HEAD + LEDGER_RULE + "| 1 | [LOW] | Fixed | transcript.md | 1 | Stub note | Stub evidence |")
PYSTUB
chmod +x "$BIN/claude"

# Stub Codex CLI: record session/resume arguments, write its last-message file, and emit a JSONL
# thread.started event. Login status is separately checked by the adapter.
cat > "$BIN/codex" <<'CODEXSTUB'
#!/usr/bin/env python3
import json, os, sys
argv = sys.argv[1:]
if argv[:2] == ["login", "status"]:
    print("Logged in using ChatGPT" if os.environ.get("STUB_CODEX_SIGNED_IN", "1") == "1" else "Not logged in")
    raise SystemExit(0)
if not argv or argv[0] != "exec":
    raise SystemExit("expected codex exec")
if "--sandbox" in argv and "--approve-for-me" in argv:
    raise SystemExit("--sandbox cannot be combined with --approve-for-me")
last = argv[argv.index("--output-last-message") + 1]
prompt = sys.stdin.read()
system = next((argv[i + 1].split("=", 1)[1] for i, value in enumerate(argv[:-1])
               if value == "-c" and argv[i + 1].startswith("developer_instructions=")), "")
role = ("user" if "USER-BRIEF-MARK" in system else "judge") if "--ephemeral" in argv else "agent"
log = os.environ["CODEX_STUB_LOG"]
prior = []
if os.path.exists(log):
    with open(log, encoding="utf-8") as f:
        prior = [json.loads(line) for line in f if line.strip()]
count = sum(c.get("role") == role for c in prior) + 1
with open(os.environ["CODEX_STUB_LOG"], "a", encoding="utf-8") as f:
    f.write(json.dumps({"argv": argv, "cwd": os.getcwd(), "home": os.environ.get("HOME"),
                        "role": role, "prompt": prompt, "system": system,
                        "codex_home": os.environ.get("CODEX_HOME"),
                        "aid_context": os.path.isfile("AGENTS.md"),
                        "auth_copied": os.path.isfile(os.path.join(os.environ.get("HOME", ""), ".codex", "auth.json"))}) + "\n")
if role != "agent":
    if os.environ.get("STUB_CODEX_HELPER_FAIL") == "1":
        raise SystemExit("stub helper unavailable")
    if role == "user":
        mode = os.environ.get("STUB_USER", "end-after-one")
        reply = "Keep going." if mode == "never" else (
            "Second message from the persona." if mode == "two-turns" and count % 2 == 1 else "<<END>>")
    else:
        mode = os.environ.get("STUB_JUDGE", "clean")
        status = "Pending" if mode == "pending" else "Fixed"
        reply = ("The run looks fine." if mode == "no-table" else
                 "| # | Severity | Status | Doc | Line | Description | Evidence |\n"
                 "| --- | --- | --- | --- | --- | --- | --- |\n"
                 f"| 1 | [HIGH] | {status} | transcript.md | 1 | Stub item | Stub evidence |")
    with open(last, "w", encoding="utf-8") as f:
        f.write("" if os.environ.get("STUB_CODEX_HELPER_EMPTY") == "1" else reply)
    if os.environ.get("STUB_CODEX_HELPER_TURN_FAILED") == "1":
        print(json.dumps({"type": "turn.failed", "error": {"message": "stub failed turn"}}))
    if os.environ.get("STUB_CODEX_HELPER_TOOL") == "1":
        print(json.dumps({"type": "item.completed", "item": {"type": "command_execution"}}))
    print(json.dumps({"type": "item.completed", "item": {"type": "agent_message", "text": reply}}))
    raise SystemExit(0)
if "resume" not in argv:
    with open("changed.txt", "w", encoding="utf-8") as f:
        f.write("hello from the stub\n")
    # the Codex CLI refreshes its sign-in file during a start turn, as a token refresh does: the file
    # then changes under HOME during the run (CX26 reads that the change is not captured)
    auth = os.path.join(os.environ.get("HOME", ""), ".codex", "auth.json")
    os.makedirs(os.path.dirname(auth), exist_ok=True)
    with open(auth, "w", encoding="utf-8") as f:
        f.write('{"tokens": {"access_token": "AUTH-MARK-7731-refreshed"}}\n')
with open(last, "w", encoding="utf-8") as f:
    f.write("Codex reply " + ("2" if "resume" in argv else "1"))
if "resume" not in argv:
    print(json.dumps({"type": "thread.started", "thread_id": "stub-codex-thread"}))
print(json.dumps({"type": "item.completed", "item": {"id": "command-" + str(count),
                  "type": "command_execution", "command": "git status --short", "aggregated_output": "", "exit_code": 0}}))
print(json.dumps({"type": "item.completed", "item": {"type": "agent_message",
                  "text": "Codex reply " + ("2" if "resume" in argv else "1")}}))
CODEXSTUB
chmod +x "$BIN/codex"

# --- the facts reader: one key=value line per fact of a stub log --------------
cat > "$T/facts.py" <<'PYFACTS'
import json
import os
import re
import sys

log, user_brief_path, judge_brief_path, judge_prompt_out = sys.argv[1:5]
calls = []
if os.path.exists(log):
    with open(log, encoding="utf-8") as fh:
        calls = [json.loads(line) for line in fh if line.strip()]
agents = [c for c in calls if c["role"] == "agent"]
users = [c for c in calls if c["role"] == "user"]
judges = [c for c in calls if c["role"] == "judge"]
helpers = users + judges
with open(user_brief_path, encoding="utf-8") as fh:
    user_brief = fh.read()
with open(judge_brief_path, encoding="utf-8") as fh:
    judge_brief = fh.read()
TOOLS = "Read,Glob,Grep,Edit,Write,Bash,Skill,Task"
AGENT = ["-p", "--output-format", "stream-json", "--verbose", "--permission-mode", "acceptEdits",
         "--tools", TOOLS, "--allowedTools", TOOLS, "--strict-mcp-config", "--setting-sources", "project"]
HELPER = ["-p", "--output-format", "text", "--tools", "", "--safe-mode", "--strict-mcp-config",
          "--system-prompt"]


def system_of(call):
    return call["argv"][8] if len(call["argv"]) > 8 else ""


def body_of(text):
    # the same rule as run.py's split_frontmatter: the text after the closing --- of a frontmatter
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return text
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        return text
    return "\n".join(lines[end + 1:])


def flag(value):
    return "1" if value else "0"


def model_of(argv):
    """The value after --model, or "" when the argv names no model."""
    if "--model" not in argv or argv.index("--model") + 1 >= len(argv):
        return ""
    return argv[argv.index("--model") + 1]


def without_model(argv):
    if "--model" not in argv:
        return argv
    i = argv.index("--model")
    return argv[:i] + argv[i + 2:]


def end_first_ok(prompt):
    head, sep, _ = prompt.partition("## Persona")
    return bool(sep) and head.lstrip().startswith("Before anything else") \
        and "end conditions" in head and "overrides every other rule" in head


# the parent session's identity and wiring that parent_session exports: none may reach the agent
SESSION_VARS = (
    "CLAUDECODE", "CLAUDE_CODE_SESSION_ID", "CLAUDE_CODE_ENTRYPOINT", "CLAUDE_CODE_USER_EMAIL",
    "CLAUDE_CODE_CHILD_SESSION", "CLAUDE_CODE_REMOTE", "CLAUDE_CODE_REMOTE_SESSION_ID",
    "CLAUDE_CODE_CONTAINER_ID", "CLAUDE_CODE_MESSAGING_TOKEN", "CLAUDE_EFFORT", "CLAUDE_AFTER_LAST_COMPACT",
    "CLAUDE_CONFIG_DIR", "CLAUDE_PID", "CLAUDE_ADDITIONAL_DIRECTORIES", "CCR_SESSION_PROFILE",
    "SESSION_INGRESS_URL", "CLAUDE_SESSION_INGRESS_TOKEN_FILE",
)


def env_leak(call):
    return sorted(k for k in call["env"] if k in SESSION_VARS)


with open(judge_prompt_out, "w", encoding="utf-8") as fh:
    fh.write(judges[0]["prompt"] if judges else "")


print(f"agent_calls={len(agents)}")
print(f"user_calls={len(users)}")
print(f"judge_calls={len(judges)}")
print("agent_flags_ok=" + flag(bool(agents) and all(
    without_model(c["argv"]) == AGENT + (["--resume", "stub-session-1"] if i else []) for i, c in enumerate(agents))))
print("agent_models=" + "|".join(sorted({model_of(c["argv"]) for c in agents})))
print("agent_env_leak=" + ",".join(sorted({k for c in agents for k in env_leak(c)})))
print("agent_env_auth=" + (agents[0]["env"].get("CLAUDE_CODE_OAUTH_TOKEN", "<unset>") if agents else "<no agent>"))
print("agent_env_proxy=" + (agents[0]["env"].get("HTTPS_PROXY", "<unset>") if agents else "<no agent>"))
print("agent_env_ca=" + (agents[0]["env"].get("NODE_EXTRA_CA_CERTS", "<unset>") if agents else "<no agent>"))
print("user_end_first_ok=" + flag(bool(users) and all(end_first_ok(c["prompt"]) for c in users)))
judge_prompt = judges[0]["prompt"] if judges else ""
print("judge_prompt_len=" + str(len(judge_prompt)))
print("judge_marker_big=" + flag(re.search(r"\[\.\.\. \d+ lines of fixture/big\.txt truncated \.\.\.\]", judge_prompt)))
print("judge_marker_huge=" + flag(re.search(r"\[\.\.\. \d+ lines of fixture/huge\.txt truncated \.\.\.\]", judge_prompt)))
print("judge_has_last_big_line=" + flag("+line 400\n" in judge_prompt))
judge_diff = re.search(r"```diff\n(.*?)\n```\n\n## checks.txt", judge_prompt, re.S)
judge_diff_bytes = len(judge_diff.group(1).encode("utf-8")) if judge_diff else -1
print("judge_diff_cap_ok=" + flag(0 < judge_diff_bytes <= 200000))
print("judge_summary_big=" + flag(re.search(r"\[\.\.\. \d+ more files truncated \.\.\.\]", judge_prompt)))
print("judge_markers_bounded=" + flag(
    0 < len(re.findall(r"^\[\.\.\. .* truncated \.\.\.\]$", judge_prompt, re.M)) <= 21))
print("judge_cap_ok=" + flag(
    re.search(r"\[\.\.\. \d+ lines of fixture/big\.txt truncated \.\.\.\]", judge_prompt)
    and re.search(r"\[\.\.\. \d+ lines of fixture/huge\.txt truncated \.\.\.\]", judge_prompt)
    and "+line 400\n" not in judge_prompt and len(judge_prompt) < 250000))
print("agent_prompts=" + "|".join(c["prompt"] for c in agents))
print("helper_flags_ok=" + flag(bool(helpers) and all(
    c["argv"][:8] == HELPER and len(c["argv"]) == 9 for c in helpers)))
print("user_brief_ok=" + flag(bool(users) and all(system_of(c) == user_brief for c in users)))
print("judge_system_ok=" + flag(bool(judges) and all(
    c["reviewer"] is not None and body_of(c["reviewer"]).strip() != ""
    and system_of(c) == body_of(c["reviewer"]) + "\n\n" + judge_brief for c in judges)))
print("helper_cwd_ok=" + flag(bool(helpers) and all(os.path.basename(c["cwd"]) == "helper" for c in helpers)))
print("agent_cwd_ok=" + flag(bool(agents) and all(os.path.basename(c["cwd"]) == "project" for c in agents)))
print("throwaway_home_ok=" + flag(bool(calls) and all("/aid-conv-run-" in c["home"] for c in calls)))
PYFACTS

# --- the samples, the fixture and the stand-in briefs ---------------------------
mkdir -p "$T/samples/feature-900" "$T/samples-bad/feature-900" "$T/fixtures/stub/src" "$T/briefs"
cat > "$T/samples/feature-900/s-pass.md" <<'EOF'
---
id: s-pass
covers: a passing run with every check met
fixture: stub
---

## User

I need help with the feature.

The persona asks for help with the stub feature.

## Answer sheet

- The feature is the stub feature.

## Expected outcome

1. The assistant replies.

## Must not

1. Push anything.

## Checks

- exists changed.txt
- contains changed.txt hello from the stub
- tool-called Skill aid-plan
- tool-not-called Skill aid-execute
- tool-called Bash git*
- tool-called Read .aid/knowledge/INDEX.md
- tool-not-called Bash *push*
- no-push
- absent missing.txt
- no-new-dir .aid/works
EOF
cat > "$T/samples/feature-900/s-checks-fail.md" <<'EOF'
---
id: s-checks-fail
covers: a run whose checks do not hold
fixture: stub
---

## User

I need help with the feature.

## Answer sheet

- The feature is the stub feature.

## Expected outcome

1. The assistant replies.

## Must not

1. Push anything.

## Checks

- tool-called Skill aid-execute
- tool-not-called Bash git*
- absent changed.txt
- contains changed.txt not in the file
EOF
cat > "$T/samples/feature-900/s-grammar-fail.md" <<'EOF'
---
id: s-grammar-fail
covers: a run whose exists, no-new-dir and no-push checks do not hold
fixture: stub
---

## User

I need help with the feature.

## Answer sheet

- The feature is the stub feature.

## Expected outcome

1. The assistant replies.

## Must not

1. Push anything.

## Checks

- exists missing.txt
- no-new-dir scratch
- no-push
EOF
cat > "$T/samples/feature-900/s-branch.md" <<'EOF'
---
id: s-branch
covers: a fixture with a work branch, and the ref-unchanged check on it
fixture: stub
branch: work-x
---

## User

I need help with the feature.

## Answer sheet

- The feature is the stub feature.

## Expected outcome

1. The assistant replies.

## Must not

1. Push anything.

## Checks

- ref-unchanged default
- ref-unchanged work-x
- ref-unchanged no-such-branch
EOF
cat > "$T/samples/feature-900/s-onbranch.md" <<'EOF'
---
id: s-onbranch
covers: a fixture whose run starts on a work branch
fixture: stub
on-branch: work-y
---

## User

I need help with the feature.

## Answer sheet

- The feature is the stub feature.

## Expected outcome

1. The assistant replies.

## Must not

1. Push anything.

## Checks

- ref-unchanged work-y
EOF
cat > "$T/samples-bad/feature-900/s-bad.md" <<'EOF'
---
id: s-bad
covers: a sample with an unknown check verb
fixture: stub
---

## User

Hello.

## Answer sheet

- Nothing.

## Expected outcome

1. Nothing.

## Must not

1. Nothing.

## Checks

- frobnicate changed.txt
EOF
cat > "$T/samples/feature-900/s-protocol.md" <<'EOF'
---
id: s-protocol
covers: AC-8, AC-28 -- a sample whose judge also gets the protocol checklist
fixture: stub
---

## User

I need help with the feature.

## Answer sheet

- The feature is the stub feature.

## Expected outcome

1. The assistant replies.

## Must not

1. Push anything.

## Checks

- exists changed.txt
EOF
cat > "$T/samples/feature-900/s-ac11.md" <<'EOF'
---
id: s-ac11
covers: AC-11 -- a sample whose judge does not get the protocol checklist
fixture: stub
---

## User

I need help with the feature.

## Answer sheet

- The feature is the stub feature.

## Expected outcome

1. The assistant replies.

## Must not

1. Push anything.

## Checks

- exists changed.txt
EOF
printf '# Stub fixture\n' > "$T/fixtures/stub/README.md"
printf 'print("stub")\n' > "$T/fixtures/stub/src/app.py"
printf 'USER-BRIEF-MARK\nStand-in simulated-user brief for the suite.\n' > "$T/briefs/simulated-user.md"
printf 'JUDGE-BRIEF-MARK\nStand-in judge brief for the suite.\n' > "$T/briefs/judge.md"
printf 'PROTOCOL-CHECKS-MARK\nStand-in protocol checklist for the suite.\n' > "$T/briefs/protocol-checks.md"
# the same briefs without the checklist: a run of an AC-8 or AC-28 sample reads it and must exit 2
mkdir -p "$T/briefs-nocheck"
cp "$T/briefs/simulated-user.md" "$T/briefs/judge.md" "$T/briefs-nocheck/"

# --- mutations: a copy of run.py (or of a brief) with one behaviour broken ----
# mutate.py SRC DST OLD NEW [OLD NEW...]: writes DST from SRC with each OLD replaced by NEW; every OLD
# must occur exactly once, so a mutation that did not apply fails loudly instead of passing as a no-op.
cat > "$T/mutate.py" <<'PYMUT'
import sys

src, dst, pairs = sys.argv[1], sys.argv[2], sys.argv[3:]
if len(pairs) % 2:
    sys.exit("mutate.py: OLD and NEW come in pairs")
with open(src, encoding="utf-8") as fh:
    text = fh.read()
for old, new in zip(pairs[::2], pairs[1::2]):
    found = text.count(old)
    if found != 1:
        sys.exit(f"mutate.py: {old!r} occurs {found} times in {src}")
    text = text.replace(old, new)
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)
PYMUT

MUT_PATH=""
make_mutant() {  # NAME OLD NEW [OLD NEW...]: sets MUT_PATH to a copy of run.py inside the tree
    MUT_PATH="$REPO_ROOT/tests/conversation/mut-$1.py"
    MUT_FILES+=("$MUT_PATH")
    shift
    "$PY" "$T/mutate.py" "$REPO_ROOT/tests/conversation/run.py" "$MUT_PATH" "$@"
}

# --- runs: one run.py call each, memoised by key so groups share them ----------
# Every run.py call stages a release bundle and installs AID into each run's fixture, which is most of
# the suite's cost. So each call serves every assertion that can read it: the cap run also carries the
# worktree and large-file stubs and the parent session's environment (CP, EN, DF12, JD); the two mutant
# runs each carry several independent mutations, and each mutation's check reads only its own fact or
# folder. A mutation whose check needs a clean environment (the default model) is kept out of the run
# with the model override.
invoke() {  # KEY USER-MODE JUDGE-MODE run.py-args...   (STUB_PUSH=1 in the caller makes the agent push)
    local key="$1" user="$2" judge="$3"
    shift 3
    env STUB_USER="$user" STUB_JUDGE="$judge" STUB_CODEX_SIGNED_IN="${STUB_CODEX_SIGNED_IN:-1}" STUB_PUSH="${STUB_PUSH:-0}" STUB_WORKTREE="${STUB_WORKTREE:-0}" \
        STUB_BIG="${STUB_BIG:-0}" CONV_STUB_LOG="$T/log/$key.jsonl" CODEX_STUB_LOG="$T/log/$key.codex.jsonl" \
        CONV_STUB_REVIEW_DIR="$T/review-copy/$key" \
        "$PY" "${INVOKE_RUNNER:-$RUNNER}" --feature 900 --samples-dir "$T/samples" --fixtures-dir "$T/fixtures" \
        --briefs-dir "$T/briefs" "$@" > "$T/log/$key.out" 2>&1 < /dev/null &
    local pid=$!
    echo "$pid" >> "$T/log/run-pids"
    wait "$pid"
    echo $? > "$T/log/$key.rc"
    "$PY" "$T/facts.py" "$T/log/$key.jsonl" "$T/briefs/simulated-user.md" "$T/briefs/judge.md" \
        "$T/log/$key.judge-prompt" > "$T/log/$key.facts" 2>&1
}
invoke_no_codex() {  # KEY USER-MODE JUDGE-MODE run.py-args...
    local key="$1" user="$2" judge="$3"
    shift 3
    mkdir -p "$T/no-codex-bin"
    ln -sf "$BIN/claude" "$T/no-codex-bin/claude"
    env PATH="$T/no-codex-bin:/usr/bin:/bin" STUB_USER="$user" STUB_JUDGE="$judge" \
        CONV_STUB_LOG="$T/log/$key.jsonl" CODEX_STUB_LOG="$T/log/$key.codex.jsonl" \
        "$PY" "${INVOKE_RUNNER:-$RUNNER}" --feature 900 --samples-dir "$T/samples" \
        --fixtures-dir "$T/fixtures" --briefs-dir "$T/briefs" "$@" > "$T/log/$key.out" 2>&1 < /dev/null &
    local pid=$!
    echo "$pid" >> "$T/log/run-pids"
    wait "$pid"
    echo $? > "$T/log/$key.rc"
}
# need KEY COMMAND...: starts the run in the background, once per KEY; await_runs waits for every run started.
# A group calls need for each run it reads, then await_runs, so its runs overlap and it reads only finished runs.
STARTED_KEYS=" "
RUNS_STARTED=()
started() { case "$STARTED_KEYS" in *" $1 "*) return 0 ;; esac; return 1; }
need() {
    local key="$1"
    shift
    started "$key" && return 0
    STARTED_KEYS="$STARTED_KEYS$key "
    "$@" &
    RUNS_STARTED+=("$!")
}
await_runs() {
    local pid
    for pid in ${RUNS_STARTED[@]+"${RUNS_STARTED[@]}"}; do wait "$pid"; done
    RUNS_STARTED=()
}
need_pass()    { need pass invoke pass two-turns clean --sample s-pass --runs 1; }
need_checks()  { need checks invoke checks two-turns clean --sample s-checks-fail --runs 1; }
need_branch()  { need branch invoke branch end-after-one clean --sample s-branch --runs 1; }
need_branch_move() { STUB_MOVE_REF=1 need branchmove invoke branchmove end-after-one clean --sample s-branch --runs 1; }
need_onbranch_move() { STUB_MOVE_REF=1 need onbranchmove invoke onbranchmove end-after-one clean --sample s-onbranch --runs 1; }
need_grammar() { STUB_PUSH=1 need grammar invoke grammar two-turns clean --sample s-grammar-fail --runs 1; }
need_flaky()   { need flaky invoke flaky end-after-one flaky --sample s-pass --runs 3; }
need_clean3()  { need clean3 invoke clean3 end-after-one clean --sample s-pass --runs 3; }
need_proto()   { need proto invoke proto end-after-one clean --sample s-protocol --runs 1; }
need_ac11()    { need ac11 invoke ac11 end-after-one clean --sample s-ac11 --runs 1; }
# the mutant run: the judge is never given the checklist, though the sample covers AC-28 (PQ04)
need_protom() {
    started protom && return 0
    make_mutant protom 'protocol = ctx["protocol_checks"] if needs_protocol_checks(sample) else None' \
        'protocol = None' || fail "PQ04 the protocol mutation did not apply"
    INVOKE_RUNNER="$MUT_PATH" need protom invoke protom end-after-one clean --sample s-protocol --runs 1
}
# the no-checklist run: an AC-8 or AC-28 sample whose briefs folder has no protocol-checks.md (PQ03)
run_nocheck() {  # KEY RUNNER: run.py runs in the background, and its pid is recorded for the cleanup
    local key="$1" runner="$2"
    env CONV_STUB_LOG="$T/log/$key.jsonl" STUB_USER=end-after-one STUB_JUDGE=clean \
        "$PY" "$runner" --feature 900 --sample s-protocol --runs 1 --samples-dir "$T/samples" \
        --fixtures-dir "$T/fixtures" --briefs-dir "$T/briefs-nocheck" > "$T/log/$key.out" 2>&1 < /dev/null &
    local pid=$!
    echo "$pid" >> "$T/log/run-pids"
    wait "$pid"
    echo $? > "$T/log/$key.rc"
}
# the cap run: 12 turns with no <<END>> (CP); the agent's environment under a parent session and a model
# override (EN); the worktree and the large-file stubs (DF12, JD); its judge reply is clean
need_cap() {
    AID_CONV_MODEL=claude-override-test STUB_WORKTREE=1 STUB_BIG=1 \
        need cap parent_session invoke cap never clean --sample s-pass --runs 1
}
# the first mutant run: the judge reply is Pending (LG02, LG03); the end-first (ED02), default-model (EN07),
# HOME set-up (DF15) and auth-variable (EN10) mutations; no model override, so EN07 sees the default model
need_m1() {
    started m1 && return 0
    make_mutant m1 \
        'HOME_SETUP_DIRS = (".ccr", ".pki", ".local/share/pki", ".aws", ".codex")' 'HOME_SETUP_DIRS = ()' \
        'HOME_SETUP_FILES = (".boto",)' 'HOME_SETUP_FILES = ()' \
        'f"{END_FIRST_RULE}\n\n"' '""' \
        '"--model", self.model,' '' \
        'if k not in ENV_DROP_NAMES and not k.startswith(ENV_DROP_PREFIXES)' \
        'if k not in ENV_DROP_NAMES and not k.startswith(ENV_DROP_PREFIXES) and k != "CLAUDE_CODE_OAUTH_TOKEN"' \
        || { fail "DF15 the HOME mutation did not apply"; fail "ED02 the end-first mutation did not apply"
             fail "EN07 the --model mutation did not apply"; fail "EN10 the auth-drop mutation did not apply"; }
    INVOKE_RUNNER="$MUT_PATH" need m1 parent_session invoke m1 end-after-one pending --sample s-pass --runs 1
}
# the second mutant run: the judge reply has no ledger table (LG04, LG05); the worktree, judge-cap, env-filter
# and model-override mutations (DF14, JD06a, JD06b, EN06, EN08), with the model override and the worktree
# and large-file stubs
need_m2() {
    started m2 && return 0
    make_mutant m2 'if baseline is not None and rel not in before:' 'if False:' \
        'JUDGE_FILE_LINES = 300' 'JUDGE_FILE_LINES = 10**9' \
        'JUDGE_TOTAL_BYTES = 200_000' 'JUDGE_TOTAL_BYTES = 10**12' \
        'if k not in ENV_DROP_NAMES and not k.startswith(ENV_DROP_PREFIXES)' 'if k != "CLAUDE_CONFIG_DIR"' \
        '"model": os.environ.get(MODEL_ENV) or DEFAULT_MODEL,' '"model": DEFAULT_MODEL,' \
        || { fail "DF14 the worktree mutation did not apply"; fail "JD06a the per-file cap mutation did not apply"
             fail "JD06b the total cap mutation did not apply"; fail "EN06 the environment mutation did not apply"
             fail "EN08 the model-override mutation did not apply"; }
    AID_CONV_MODEL=claude-override-test STUB_WORKTREE=1 STUB_BIG=1 INVOKE_RUNNER="$MUT_PATH" \
        need m2 parent_session invoke m2 end-after-one no-table --sample s-pass --runs 1
}
# the agent's environment is checked under a parent session's variables (the model override is set by the caller)
parent_session() {
    (
        export CLAUDECODE=1 CLAUDE_CODE_SESSION_ID=parent-session CLAUDE_CODE_ENTRYPOINT=cli \
            CLAUDE_CODE_USER_EMAIL=user@example.test CLAUDE_CODE_CHILD_SESSION=1 CLAUDE_CODE_REMOTE=1 \
            CLAUDE_CODE_REMOTE_SESSION_ID=parent-remote CLAUDE_CODE_CONTAINER_ID=parent-container \
            CLAUDE_CODE_MESSAGING_TOKEN=parent-messaging CLAUDE_EFFORT=high CLAUDE_AFTER_LAST_COMPACT=1 \
            CLAUDE_CONFIG_DIR=/stub/config CLAUDE_PID=4242 CLAUDE_ADDITIONAL_DIRECTORIES=/stub/extra \
            CCR_SESSION_PROFILE=parent-profile SESSION_INGRESS_URL=http://ingress.test/parent \
            CLAUDE_SESSION_INGRESS_TOKEN_FILE=/stub/ingress-token \
            CLAUDE_CODE_OAUTH_TOKEN=dummy-oauth-token-for-test \
            HTTPS_PROXY=http://proxy.test:3128 NODE_EXTRA_CA_CERTS=/stub/ca.pem
        "$@"
    )
}

fact() { grep -m1 "^$2=" "$1" | cut -d= -f2-; }
run_dir_of() { sed -n "s/^$2 claude-code $3 run $4\/[0-9]* -> //p" "$1" | head -1; }
# the run folder of the one run in an output file, whatever its verdict
any_run_dir() { sed -n 's/^[A-Z]* claude-code [^ ]* run [0-9]*\/[0-9]* -> //p' "$1" | head -1; }

# predicates over a run folder: each returns 0 when the behaviour holds in that folder
wt_diff_ok() {  # the worktree's changed file is diffed against the fixture's file; the identical one is omitted
    local d="$1/files.diff"
    grep -q -F -- "--- a/fixture/src/app.py" "$d" \
        && grep -q -F -- "+++ b/fixture/.claude/worktrees/wt1/src/app.py" "$d" \
        && grep -q -F -- '-print("stub")' "$d" && grep -q -F -- '+print("stub changed")' "$d" \
        && grep -q -F -- "+new in the worktree" "$d" \
        && ! grep -q -F -- "wt1/README.md" "$d"
}
home_setup_ok() {  # the sandbox's own set-up and credential files under HOME are not recorded
    local d="$1/files.diff"
    grep -q -F -- "b/home/notes.txt" "$d" \
        && ! grep -q -F -- "home/.ccr/" "$d" && ! grep -q -F -- "home/.pki/" "$d" \
        && ! grep -q -F -- "home/.local/share/pki/" "$d" && ! grep -q -F -- "home/.aws/" "$d" \
        && ! grep -q -F -- "home/.boto" "$d"
}
user_brief_ok() {  # the end conditions come first in the simulated-user brief, and override every rule
    local f="$1" end rules
    end="$(grep -n -F -- "overrides every other rule" "$f" | head -1 | cut -d: -f1)"
    rules="$(grep -n -F -- "## Rules" "$f" | head -1 | cut -d: -f1)"
    [ -n "$end" ] && [ -n "$rules" ] && [ "$end" -lt "$rules" ]
}
judge_brief_ok() {  # truncated diff content is not absent; no row outside the EO-n and MN-n lists
    local f="$1"
    grep -q -F -- "Truncated content is not absent" "$f" && grep -q -F -- "Never add a row that is not an EO-n or MN-n item" "$f"
}
judge_unmet_only_ok() {  # the output part says a row is only for an UNMET item, so a met item gets no row
    grep -q -F -- "A row is only for an UNMET item" "$1"
}

# ---------------------------------------------------------------- EXIT
group_exit() {
    echo "--- EXIT"
    local base=(--samples-dir "$T/samples" --fixtures-dir "$T/fixtures" --briefs-dir "$T/briefs")
    expect_code() {  # LABEL WANT command...
        local label="$1" want_code="$2"
        shift 2
        "$@" > "$T/log/exit-probe.out" 2>&1 < /dev/null
        assert_exit_eq "$?" "$want_code" "$label"
    }
    expect_code "EX01 no arguments exits 2" 2 "$PY" "$RUNNER"
    expect_code "EX02 a feature that is not three digits exits 2" 2 "$PY" "$RUNNER" --feature 1 "${base[@]}"
    expect_code "EX03 --runs 0 exits 2" 2 "$PY" "$RUNNER" --feature 900 --runs 0 "${base[@]}"
    expect_code "EX04 an unknown host exits 2" 2 "$PY" "$RUNNER" --feature 900 --hosts bogus "${base[@]}"
    expect_code "EX05 a feature with no samples folder exits 2" 2 "$PY" "$RUNNER" --feature 777 "${base[@]}"
    expect_code "EX06 an unknown sample id exits 2" 2 "$PY" "$RUNNER" --feature 900 --sample nope "${base[@]}"
    expect_code "EX07 a missing brief folder exits 2" 2 "$PY" "$RUNNER" --feature 900 \
        --samples-dir "$T/samples" --fixtures-dir "$T/fixtures" --briefs-dir "$T/nobriefs"
    expect_code "EX08 no claude on PATH exits 2" 2 env PATH="$T/empty" "$PY" "$RUNNER" --feature 900 "${base[@]}"
    "$PY" "$RUNNER" --feature 900 --hosts , "${base[@]}" > "$T/log/empty-hosts.out" 2>&1
    assert_exit_eq "$?" 2 "EX09 an empty --hosts value exits 2"
    assert_output_contains "$(cat "$T/log/empty-hosts.out")" "error: at least one host is required" \
        "EX10 an empty --hosts value reports usage"
    assert_output_not_contains "$(cat "$T/log/empty-hosts.out")" "Traceback" \
        "EX11 an empty --hosts value does not print a traceback"
}

# ---------------------------------------------------------------- VALIDATE
group_validate() {
    echo "--- VALIDATE"
    local out code
    out="$(env CONV_STUB_LOG="$T/log/validate.jsonl" "$PY" "$RUNNER" --feature 900 --validate \
        --samples-dir "$T/samples" 2>&1 < /dev/null)"
    code=$?
    assert_exit_eq "$code" 0 "VA01 --validate on well-formed samples"
    assert_output_contains "$out" "OK s-pass (10 checks)" "VA02 --validate parses s-pass and counts its checks"
    assert_output_contains "$out" "OK s-checks-fail (4 checks)" "VA03 --validate parses s-checks-fail"
    out="$(env CONV_STUB_LOG="$T/log/validate.jsonl" "$PY" "$RUNNER" --feature 900 --validate \
        --samples-dir "$T/samples-bad" 2>&1 < /dev/null)"
    code=$?
    assert_exit_eq "$code" 1 "VA04 --validate on a malformed sample"
    assert_output_contains "$out" "unknown check" "VA05 --validate names the malformed check"
    if [ -e "$T/log/validate.jsonl" ]; then
        fail "VA06 --validate runs no agent -- the stub was called"
    else
        pass "VA06 --validate runs no agent"
    fi
}

# ---------------------------------------------------------------- CAPTURE
group_capture() {
    echo "--- CAPTURE"
    need_pass
    await_runs
    local dir
    dir="$(run_dir_of "$T/log/pass.out" PASS s-pass 1)"
    assert_exit_eq "$(cat "$T/log/pass.rc")" 0 "CA01 a passing run exits 0"
    assert_dir_exists "$dir" "CA02 run.py prints the run folder of a passing run"
    assert_file_exists "$dir/transcript.jsonl" "CA03 capture file transcript.jsonl"
    assert_file_exists "$dir/transcript.md" "CA04 capture file transcript.md"
    assert_file_exists "$dir/files.diff" "CA05 capture file files.diff"
    assert_file_exists "$dir/checks.txt" "CA06 capture file checks.txt"
    assert_file_exists "$dir/ledger.md" "CA07 capture file ledger.md (the judge's ledger)"
    assert_eq "$(grep -c '"role": "agent"' "$dir/transcript.jsonl")" 2 "CA08 transcript.jsonl has one entry per agent turn"
    assert_eq "$(grep -c '"role": "user"' "$dir/transcript.jsonl")" 2 "CA09 transcript.jsonl has one entry per user message"
    assert_eq "$(grep -c '"tools": ' "$dir/transcript.jsonl")" 4 "CA10 every transcript entry carries its tools"
    assert_eq "$(grep -c '"ts": ' "$dir/transcript.jsonl")" 4 "CA11 every transcript entry carries its timestamp"
    assert_file_contains "$dir/transcript.md" "## Turn 2 -- Agent" "CA12 transcript.md is the readable form"
    assert_file_contains "$dir/ledger.md" "| # | Severity | Status" "CA13 ledger.md holds the judge's table"
    assert_eq "$(cat "$dir/model.txt" 2>/dev/null)" "claude-sonnet-5-5" "CA14 model.txt holds the model the run used"
}

# ---------------------------------------------------------------- FLAGS
group_flags() {
    echo "--- FLAGS"
    need_pass
    await_runs
    local f="$T/log/pass.facts"
    assert_eq "$(fact "$f" agent_calls)" 2 "FL01 two agent turns for two user messages"
    assert_eq "$(fact "$f" agent_flags_ok)" 1 "FL02 agent flags on every turn, --resume from turn 2 only"
    assert_eq "$(fact "$f" agent_prompts)" "I need help with the feature.|Second message from the persona." \
        "FL03 agent prompts go on stdin, opening message first"
    assert_eq "$(fact "$f" user_calls)" 2 "FL04 the simulated user is asked after each agent turn"
    assert_eq "$(fact "$f" user_brief_ok)" 1 "FL05 simulated-user calls use the user brief and no tools"
    assert_eq "$(fact "$f" judge_calls)" 1 "FL06 one judge call per run"
    assert_eq "$(fact "$f" judge_system_ok)" 1 "FL07 judge system prompt is exactly the installed reviewer body plus the judge brief"
    assert_eq "$(fact "$f" helper_flags_ok)" 1 "FL08 simulated-user and judge flags (text, no tools, safe mode)"
    assert_eq "$(fact "$f" helper_cwd_ok)" 1 "FL09 helper calls run from an empty folder, not the fixture"
    assert_eq "$(fact "$f" agent_cwd_ok)" 1 "FL10 agent turns run in the fixture folder"
    assert_eq "$(fact "$f" throwaway_home_ok)" 1 "FL11 every call runs with the throwaway HOME"
    assert_eq "$(fact "$f" agent_models)" "claude-sonnet-5-5" \
        "FL17 every agent turn runs with the default model claude-sonnet-5-5 (AID_CONV_MODEL unset)"
    # the judge input (one prompt on stdin): every part the spec names, with its content
    local jp="$T/log/pass.judge-prompt"
    local all_in
    all_in() {  # FILE TEXT... : 1 when every TEXT is in FILE
        local file="$1" text
        shift
        for text in "$@"; do grep -qF -- "$text" "$file" || return 1; done
        return 0
    }
    assert_eq "$(all_in "$jp" "## transcript.md" "## Turn 1 -- User" "## Turn 2 -- Agent" "Reply 2." && echo 1 || echo 0)" 1 \
        "FL12 the judge input carries transcript.md (both turns of the conversation)"
    assert_eq "$(all_in "$jp" "## files.diff" "b/fixture/changed.txt" "+hello from the stub" && echo 1 || echo 0)" 1 \
        "FL13 the judge input carries files.diff (the recorded change and its content)"
    assert_eq "$(all_in "$jp" "## checks.txt" "PASS exists changed.txt" && echo 1 || echo 0)" 1 \
        "FL14 the judge input carries checks.txt (the evaluated checks)"
    assert_eq "$(all_in "$jp" "## Expected outcome" "1. The assistant replies." "## Must not" "1. Push anything." && echo 1 || echo 0)" 1 \
        "FL15 the judge input carries the sample's Expected outcome and Must not"
    # the judge's ledger is also saved in the fixture's .aid/.temp/review-pending/ (the fixture holds a
    # symlink to review-copy/pass, placed by the agent turn, so run.py's write lands in that folder)
    local saved="$T/review-copy/pass/conversation-s-pass-run-1.md" led
    led="$(run_dir_of "$T/log/pass.out" PASS s-pass 1)/ledger.md"
    assert_eq "$([ -f "$saved" ] && [ "$(cat "$saved")" = "$(cat "$led")" ] && echo same || echo differ)" same \
        "FL16 the judge's ledger is saved as .aid/.temp/review-pending/conversation-s-pass-run-1.md in the fixture (same text as ledger.md)"
}

# ---------------------------------------------------------------- DIFF
group_diff() {
    echo "--- DIFF"
    need_pass
    need_cap
    need_m1
    need_m2
    await_runs
    local diff
    diff="$(run_dir_of "$T/log/pass.out" PASS s-pass 1)/files.diff"
    assert_file_contains "$diff" "b/fixture/changed.txt" "DF01 a change inside the fixture is recorded"
    assert_file_contains "$diff" "+hello from the stub" "DF02 the recorded change carries its content"
    assert_file_contains "$diff" "b/home/notes.txt" "DF03 a change inside the throwaway HOME is recorded"
    assert_file_not_contains "$diff" ".git/stub-marker" "DF04 the fixture's .git/ is excluded"
    assert_file_not_contains "$diff" "home/.claude/state.json" "DF05 the host tool's .claude/ in HOME is excluded"
    assert_file_not_contains "$diff" "home/.claude.json" "DF06 .claude.json in HOME is excluded"
    assert_file_not_contains "$diff" "home/.credentials.json" "DF07 the credential file .credentials.json under HOME is excluded"
    assert_file_contains "$diff" "b/home/tokens.md" "DF07b a note whose name says token (tokens.md) under HOME is kept"
    assert_file_not_contains "$diff" "home/id_ed25519" "DF07c a private key file (id_ed25519) under HOME is excluded"
    assert_file_contains "$diff" "Binary file fixture/logo.bin added (4 bytes)" \
        "DF08 a binary file is recorded by path and size only"
    assert_file_not_contains "$diff" "b/fixture/logo.bin" "DF09 a binary file carries no content diff"
    assert_file_not_contains "$diff" "deploy.pem" "DF10 a .pem credential in HOME is excluded"
    assert_file_not_contains "$diff" "server.key" "DF11 a .key credential in HOME is excluded"
    # a worktree under the fixture's .claude/worktrees/: changed files against the fixture's own file,
    # identical files omitted, .aid/ not excluded (DF12); the sandbox's own set-up files excluded (DF13)
    local dir_w
    dir_w="$(any_run_dir "$T/log/cap.out")"
    assert_eq "$(wt_diff_ok "$dir_w" && echo ok)" ok \
        "DF12 a worktree file is diffed against the fixture's file of the same path, and an identical one is omitted"
    assert_eq "$(home_setup_ok "$(run_dir_of "$T/log/pass.out" PASS s-pass 1)" && echo ok)" ok \
        "DF13 the sandbox's set-up files under HOME (.ccr/, .pki/, .local/share/pki/, .aws/, .boto) are excluded"
    # mutations: each broken behaviour fails its own check
    expect_fail "DF14 a worktree that is not diffed against the fixture's file fails DF12" \
        wt_diff_ok "$(any_run_dir "$T/log/m2.out")"
    expect_fail "DF15 a HOME without the set-up exclusions fails DF13" \
        home_setup_ok "$(any_run_dir "$T/log/m1.out")"
    # the credential rule itself, on the names alone: the module is loaded and no run is made. A note named
    # for a token or a secret is kept; the known credential names and the private key or certificate files are dropped.
    cat > "$T/credrule.py" <<'PYCR'
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)
KEPT = ["tokens.md", "secrets-notes.md", "token-plan.txt", "notes.txt"]
DROPPED = [".credentials.json", ".netrc", ".npmrc", "id_ed25519", "id_rsa", "deploy.pem", "server.key", "cert.p12"]
bad = [n for n in KEPT if mod.CREDENTIAL_RE.search(n)] + [n for n in DROPPED if not mod.CREDENTIAL_RE.search(n)]
for name in bad:
    print("credential rule misjudged: " + name, file=sys.stderr)
sys.exit(1 if bad else 0)
PYCR
    assert_eq "$("$PY" "$T/credrule.py" "$RUNNER" && echo ok)" ok \
        "CR01 the credential rule keeps tokens.md, secrets-notes.md and token-plan.txt, and drops .credentials.json, .netrc, .npmrc, id_ed25519, id_rsa, *.pem, *.key and *.p12"
    make_mutant cred 'CREDENTIAL_RE = re.compile(r"(?i)^(\.credentials\.json|\.netrc|\.npmrc|\.pypirc|\.git-credentials|\.env|id_(rsa|dsa|ecdsa|ed25519)|.+\.(pem|key|p12|pfx))$")' \
        'CREDENTIAL_RE = re.compile(r"(?i)(credential|secret|token)|\.(pem|key)$")'
    expect_fail "CR02 a credential rule that matches any name with token or secret fails CR01" \
        "$PY" "$T/credrule.py" "$MUT_PATH"
    # symbolic links, through snapshot and build_diff itself on a tree of the test's own: a link created,
    # removed or retargeted shows in the diff (DF16), and a link is never followed, so no file it points at is
    # read and a linked directory is not descended into (DF17). An empty file added or removed is named (DF18).
    cat > "$T/linkdiff.py" <<'PYLD'
import importlib.util
import os
import shutil
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)
MODE = sys.argv[2]
ROOT = Path(sys.argv[3])
shutil.rmtree(ROOT, ignore_errors=True)
TREE = ROOT / "tree"
OUTSIDE = ROOT / "outside"  # what a link may point at: none of it may reach the snapshot
TREE.mkdir(parents=True)
OUTSIDE.mkdir()
(OUTSIDE / "secret.txt").write_text("SECRET\n")
(TREE / "target.md").write_text("one\n")
(TREE / "a.md").write_text("A\n")
(TREE / "b.md").write_text("B\n")


def diff_of(edit):
    before, _ = mod.snapshot(TREE, mod.fixture_skip)
    edit()
    after, _ = mod.snapshot(TREE, mod.fixture_skip)
    return mod.build_diff({"fixture/" + k: v for k, v in before.items()}, {"fixture/" + k: v for k, v in after.items()})


if MODE == "appear":
    ok = "fixture/alias.md" in diff_of(lambda: os.symlink("target.md", TREE / "alias.md"))  # created
    ok = ok and "fixture/alias.md" in diff_of(lambda: os.unlink(TREE / "alias.md"))  # removed
    os.symlink("a.md", TREE / "link.md")
    ok = ok and "fixture/link.md" in diff_of(lambda: (os.unlink(TREE / "link.md"), os.symlink("b.md", TREE / "link.md")))
else:  # follow: a link to a file outside the tree, and a link to a directory outside it
    os.symlink(str(OUTSIDE / "secret.txt"), TREE / "secret-link.md")
    os.symlink(str(OUTSIDE), TREE / "outdir")
    snap, _ = mod.snapshot(TREE, mod.fixture_skip)
    ok = snap.get("secret-link.md") == mod.LINK_PREFIX + os.fsencode(str(OUTSIDE / "secret.txt"))
    ok = ok and snap.get("outdir") == mod.LINK_PREFIX + os.fsencode(str(OUTSIDE))
    ok = ok and not any(b"SECRET" in data for data in snap.values())
    ok = ok and not any(name.startswith("outdir/") for name in snap)
sys.exit(0 if ok else 1)
PYLD
    assert_eq "$("$PY" "$T/linkdiff.py" "$RUNNER" appear "$T/linkdiff" && echo ok)" ok \
        "DF16 a symbolic link created, removed or retargeted inside the fixture appears in the diff"
    assert_eq "$("$PY" "$T/linkdiff.py" "$RUNNER" follow "$T/linkdiff" && echo ok)" ok \
        "DF17 a symbolic link is recorded by its target and never followed: no file it points at is read, and a linked directory is not descended into"
    make_mutant linkskip 'if skip(rel, True):' 'if skip(rel, True) or (here / name).is_symlink():' \
        'if skip(rel, False):' 'if skip(rel, False) or path.is_symlink():'
    expect_fail "DF19 a snapshot that skips symbolic links fails DF16" \
        "$PY" "$T/linkdiff.py" "$MUT_PATH" appear "$T/linkdiff-m"
    make_mutant linkfollow 'files[rel] = LINK_PREFIX + os.fsencode(os.readlink(path))  # a linked file: its target text, never read through' \
        'files[rel] = path.read_bytes()  # a linked file, followed'
    expect_fail "DF20 a snapshot that reads through a symbolic link fails DF17" \
        "$PY" "$T/linkdiff.py" "$MUT_PATH" follow "$T/linkdiff-m"
    # an empty file added or removed: the diff holds git's header for it, so files.diff names it (DF18)
    cat > "$T/emptydiff.py" <<'PYED'
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)
added = mod.build_diff({}, {"fixture/empty.md": b""})
removed = mod.build_diff({"fixture/empty.md": b""}, {})
sys.exit(0 if added and removed and "empty.md" in added and "empty.md" in removed else 1)
PYED
    assert_eq "$("$PY" "$T/emptydiff.py" "$RUNNER" && echo ok)" ok \
        "DF18 an empty text file added or removed is named in the diff, not an empty diff"
    make_mutant emptydiff 'if not text and (old is None or new is None):' 'if False:'
    expect_fail "DF21 a diff that drops an empty file's header fails DF18" "$PY" "$T/emptydiff.py" "$MUT_PATH"
    # a regular file whose bytes equal a link's snapshot entry is a different entry: replacing it with the link
    # (or back) shows in the diff, in both directions (DF22); a snapshot that tags no regular file fails it (DF23)
    cat > "$T/collide.py" <<'PYCL'
import importlib.util
import shutil
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)
ROOT = Path(sys.argv[2])
shutil.rmtree(ROOT, ignore_errors=True)
TREE = ROOT / "tree"
TREE.mkdir(parents=True)
(TREE / "target.md").write_text("one\n")


def snap():
    return {"fixture/" + k: v for k, v in mod.snapshot(TREE, mod.fixture_skip)[0].items()}


(TREE / "alias").write_bytes(mod.LINK_PREFIX + b"target.md")  # a regular file, bytes equal to a link's entry
regular = snap()
(TREE / "alias").unlink()
(TREE / "alias").symlink_to("target.md")
linked = snap()
forward = mod.build_diff(regular, linked)
backward = mod.build_diff(linked, regular)
ok = "fixture/alias" in forward and "fixture/alias" in backward
sys.exit(0 if ok else 1)
PYCL
    assert_eq "$("$PY" "$T/collide.py" "$RUNNER" "$T/collide" && echo ok)" ok \
        "DF22 a regular file whose bytes equal a symbolic link's entry is replaced by the link (and back) and the change shows in the diff"
    make_mutant untagged 'files[rel] = REGULAR_TAG + path.read_bytes()' 'files[rel] = path.read_bytes()'
    expect_fail "DF23 a snapshot that tags no regular file fails DF22" "$PY" "$T/collide.py" "$MUT_PATH" "$T/collide-m"
}

# ---------------------------------------------------------------- JUDGE
group_judge() {
    echo "--- JUDGE"
    need_cap
    need_m2
    await_runs
    local f="$T/log/cap.facts" dir
    dir="$(any_run_dir "$T/log/cap.out")"
    assert_file_contains "$dir/files.diff" "+line 400" \
        "JD01 files.diff on disk holds every line of a large file (the cap is for the judge only)"
    assert_eq "$(fact "$f" judge_marker_big)" 1 \
        "JD02 the judge prompt marks the cut of a file over the per-file cap: [... N lines of <path> truncated ...]"
    assert_eq "$(fact "$f" judge_has_last_big_line)" 0 "JD03 the judge prompt omits the lines past the per-file cap"
    assert_eq "$(fact "$f" judge_marker_huge)" 1 \
        "JD04 the judge prompt marks the cut of a diff over the total cap, for the file that crosses it"
    assert_eq "$(fact "$f" judge_cap_ok)" 1 "JD05 the judge prompt stays under the total cap"
    assert_file_contains "$dir/files.diff" "b/fixture/many/f100.txt" \
        "JD07 files.diff on disk records all 100 large files"
    assert_eq "$(fact "$f" judge_diff_cap_ok)" 1 \
        "JD08 the diff the judge reads stays within the total cap (200,000 bytes) with 100 large files"
    assert_eq "$(fact "$f" judge_summary_big)" 1 \
        "JD09 the files past the marker limit are counted in one final [... N more files truncated ...] line"
    assert_eq "$(fact "$f" judge_markers_bounded)" 1 "JD10 the truncation markers are bounded (at most 21 lines)"
    # mutations: each cap's marker comes from that cap alone, so a judge prompt without a cap fails the
    # assertion for that cap's marker (the two caps are removed in one mutant run, m2)
    expect_fail "JD06a a judge prompt with no per-file cap fails JD02" \
        test "$(fact "$T/log/m2.facts" judge_marker_big)" = 1
    expect_fail "JD06b a judge prompt with no total cap fails JD04" \
        test "$(fact "$T/log/m2.facts" judge_marker_huge)" = 1
}

# ---------------------------------------------------------------- ENV
group_env() {
    echo "--- ENV"
    need_cap
    need_m1
    need_m2
    await_runs
    local f="$T/log/cap.facts" dir
    dir="$(any_run_dir "$T/log/cap.out")"
    assert_eq "$(fact "$f" agent_env_leak)" "" \
        "EN01 the agent's environment drops each identity and session variable of the parent session"
    assert_eq "$(fact "$f" agent_env_auth)" "dummy-oauth-token-for-test" \
        "EN09 the auth variable CLAUDE_CODE_OAUTH_TOKEN is kept for the agent"
    assert_eq "$(fact "$f" agent_env_proxy)" "http://proxy.test:3128" "EN02 the proxy variable is kept for the agent"
    assert_eq "$(fact "$f" agent_env_ca)" "/stub/ca.pem" "EN03 the CA variable is kept for the agent"
    assert_eq "$(fact "$f" agent_models)" "claude-override-test" \
        "EN04 AID_CONV_MODEL sets the --model of every agent turn"
    assert_file_contains "$dir/model.txt" "claude-override-test" "EN05 the model the run used is written to the run folder"
    expect_fail "EN07 an agent turn with no --model fails FL17" \
        test "$(fact "$T/log/m1.facts" agent_models)" = "claude-sonnet-5-5"
    expect_fail "EN10 an agent that drops CLAUDE_CODE_OAUTH_TOKEN fails EN09" \
        test "$(fact "$T/log/m1.facts" agent_env_auth)" = "dummy-oauth-token-for-test"
    expect_fail "EN06 an agent that inherits the parent session's variables fails EN01" \
        test "$(fact "$T/log/m2.facts" agent_env_leak)" = ""
    expect_fail "EN08 a run that ignores AID_CONV_MODEL fails EN04" \
        test "$(fact "$T/log/m2.facts" agent_models)" = "claude-override-test"
}

# ---------------------------------------------------------------- END
group_end() {
    echo "--- END"
    need_pass
    need_m1
    await_runs
    assert_eq "$(fact "$T/log/pass.facts" user_end_first_ok)" 1 \
        "ED01 every simulated-user turn puts the answer sheet's end conditions first, and they override every other rule"
    expect_fail "ED02 a per-turn prompt without the end-first rule fails ED01" \
        test "$(fact "$T/log/m1.facts" user_end_first_ok)" = 1
}

# ---------------------------------------------------------------- BRIEFS
# The briefs are committed text, read here (not run): the same predicates run on a throwaway copy of
# each brief with its behaviour's wording broken, and must fail there.
group_briefs() {
    echo "--- BRIEFS"
    local sim="$REPO_ROOT/tests/conversation/simulated-user.md" jud="$REPO_ROOT/tests/conversation/judge.md"
    mkdir -p "$T/briefs-mut"
    assert_eq "$(user_brief_ok "$sim" && echo ok)" ok \
        "BR01 simulated-user.md puts the end conditions first, and they override every other rule"
    assert_eq "$(judge_brief_ok "$jud" && echo ok)" ok \
        "BR02 judge.md says truncated content is not absent, and forbids a row that is not an EO-n or MN-n item"
    sed 's/overrides every other rule/yields to the rest/' "$sim" > "$T/briefs-mut/simulated-user.md"
    expect_fail "BR03 a simulated-user brief whose end conditions do not override fails BR01" \
        user_brief_ok "$T/briefs-mut/simulated-user.md"
    sed 's/Truncated content is not absent/Truncated content is cut/' "$jud" > "$T/briefs-mut/judge.md"
    expect_fail "BR04 a judge brief that reads truncated content as absent fails BR02" judge_brief_ok "$T/briefs-mut/judge.md"
    sed 's/Never add a row that is not an EO-n or MN-n item/Add any row you find/' "$jud" > "$T/briefs-mut/judge.md"
    expect_fail "BR05 a judge brief that allows any row fails BR02" judge_brief_ok "$T/briefs-mut/judge.md"
    assert_eq "$(judge_unmet_only_ok "$jud" && echo ok)" ok \
        "BR06 judge.md's output part says a row is only for an UNMET item"
    sed 's/A row is only for an UNMET item/A row may be written for any item/' "$jud" > "$T/briefs-mut/judge.md"
    expect_fail "BR07 a judge brief without the UNMET-only output rule fails BR06" judge_unmet_only_ok "$T/briefs-mut/judge.md"
}

# expect_fail LABEL command...: the command must fail; a mutant that still passes is a gap in the check
expect_fail() {
    local label="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        fail "$label"
    else
        pass "$label"
    fi
}

# ---------------------------------------------------------------- CHECKS
group_checks() {
    echo "--- CHECKS"
    need_pass
    need_checks
    need_grammar
    await_runs
    local dir_p dir_c dir_g
    dir_p="$(run_dir_of "$T/log/pass.out" PASS s-pass 1)"
    dir_c="$(run_dir_of "$T/log/checks.out" FAIL s-checks-fail 1)"
    dir_g="$(run_dir_of "$T/log/grammar.out" FAIL s-grammar-fail 1)"
    assert_eq "$(grep -c '^PASS ' "$dir_p/checks.txt")" 10 "CK01 every check of s-pass passes (tool-called, tool-not-called, exists, contains, no-push, absent, no-new-dir)"
    assert_eq "$(grep -c '^FAIL ' "$dir_p/checks.txt")" 0 "CK02 s-pass records no failing check"
    assert_file_contains "$dir_p/checks.txt" "PASS absent missing.txt" "CK13 absent on a missing path passes"
    assert_file_contains "$dir_p/checks.txt" "PASS no-new-dir .aid/works" "CK14 no-new-dir on a path with no new folder passes"
    assert_file_contains "$dir_g/checks.txt" "FAIL exists missing.txt -- missing" "CK15 exists on a missing path fails"
    assert_file_contains "$dir_g/checks.txt" "FAIL no-new-dir scratch -- created: scratch" \
        "CK16 no-new-dir on a folder the run created fails"
    assert_file_contains "$dir_g/checks.txt" "FAIL no-push -- push call: git push origin main" \
        "CK17 no-push with a push call fails"
    assert_exit_eq "$(cat "$T/log/grammar.rc")" 1 "CK18 a run whose grammar checks fail exits 1"
    assert_file_contains "$dir_c/checks.txt" "FAIL tool-called Skill aid-execute -- no matching call" \
        "CK03 tool-called with no matching call fails"
    assert_file_contains "$dir_c/checks.txt" "FAIL tool-not-called Bash git* -- 1 matching call(s)" \
        "CK04 tool-not-called with a matching call fails"
    assert_file_contains "$dir_c/checks.txt" "FAIL absent changed.txt -- present" "CK05 absent on an existing path fails"
    assert_file_contains "$dir_c/checks.txt" "FAIL contains changed.txt not in the file -- text not found" \
        "CK06 contains with missing text fails"
    assert_output_contains "$(cat "$T/log/checks.out")" "check: tool-called Skill aid-execute -- no matching call" \
        "CK07 a failed check is named in the run's reasons"
    assert_exit_eq "$(cat "$T/log/checks.rc")" 1 "CK08 a run with a failed check exits 1"
    # no-push on Bash targets, through run_checks itself: the module is loaded, no run is made. A prose
    # mention of git push in a heredoc passes; a real push, however it is written, fails.
    cat > "$T/nopush.py" <<'PYNP'
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)
CHECK = [{"verb": "no-push", "args": [], "label": "no-push"}]
CASES = [  # (Bash command, whether no-push should pass)
    ("cat > notes.md <<'EOF'\nThe run ran no `git push`.\nEOF", True),
    ("cat > notes.md <<EOF\nno git push here\nEOF\ngit status", True),
    ("git commit -m 'do not git push yet'", True),
    ("git log --oneline | grep push", True),
    ("git push origin main", False),
    ("git -C x push origin main", False),
    ("cd x && git push", False),
    ("bash -c 'git push origin main'", False),
]
bad = []
for command, passes in CASES:
    got = mod.run_checks(CHECK, Path("."), set(), set(), [{"name": "Bash", "target": command}])[0][1]
    if got != passes:
        bad.append(command)
for command in bad:
    print("no-push misjudged: " + repr(command), file=sys.stderr)
sys.exit(1 if bad else 0)
PYNP
    make_mutant nopush 'and is_git_push(t["target"])]' 'and re.search(r"\bgit\b.*\bpush\b", t["target"])]'
    assert_eq "$("$PY" "$T/nopush.py" "$RUNNER" && echo ok)" ok \
        "NP01 no-push passes a heredoc prose mention and a quoted or piped git, and fails each real push form"
    expect_fail "NP02 a no-push that reads heredoc prose as a push fails NP01" "$PY" "$T/nopush.py" "$MUT_PATH"
    # no-push behind a shell's combined flags (bash -lc) and the env, command, exec, nohup and sudo wrappers,
    # through run_checks itself: a real push fails, and the same words in an echo or a status do not
    cat > "$T/pushwrap.py" <<'PYPW'
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)
CHECK = [{"verb": "no-push", "args": [], "label": "no-push"}]
CASES = [  # (Bash command, whether no-push should pass)
    ('bash -lc "git push origin main"', False),
    ("env GIT_TERMINAL_PROMPT=0 git push origin main", False),
    ("command git push origin main", False),
    ("sudo git push origin main", False),
    ("sh -ec 'git push'", False),
    ("env -i FOO=1 -u BAR git push", False),
    ("nohup git push origin main", False),
    ("sudo -u root env X=1 git push", False),
    ('bash -lc "echo git push"', True),
    ("env FOO=1 git status", True),
    ("command -v git", True),
]
bad = []
for command, passes in CASES:
    got = mod.run_checks(CHECK, Path("."), set(), set(), [{"name": "Bash", "target": command}])[0][1]
    if got != passes:
        bad.append(command)
for command in bad:
    print("no-push misjudged: " + repr(command), file=sys.stderr)
sys.exit(1 if bad else 0)
PYPW
    assert_eq "$("$PY" "$T/pushwrap.py" "$RUNNER" && echo ok)" ok \
        "NP03 no-push fails a git push behind bash -lc, sh -ec, env (with VAR=value, -i and -u), command, sudo and nohup, and passes the same words in an echo or a status"
    make_mutant pushwrap 'if program in WRAPPERS:' 'if False:' \
        'if SHELL_C_FLAG.match(words[index]):' 'if words[index] == "-c":'
    expect_fail "NP04 a no-push that sees neither wrappers nor combined shell flags fails NP03" "$PY" "$T/pushwrap.py" "$MUT_PATH"
    # no-push behind a wrapper's value-taking long options (--user root, --user=root, --chdir, env -S) and
    # flag-only long options, through run_checks itself; command -v and -V only look a name up, so no push
    cat > "$T/pushlong.py" <<'PYPL'
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)
CHECK = [{"verb": "no-push", "args": [], "label": "no-push"}]
CASES = [  # (Bash command, whether no-push should pass)
    ("sudo --user root git push origin main", False),
    ("sudo --user=root git push", False),
    ("env --chdir . git push origin main", False),
    ("env --chdir=. git push", False),
    ("env -S 'git push origin main'", False),
    ("env --split-string 'FOO=1 git push'", False),
    ("sudo --login git push", False),
    ("env --ignore-environment git push", False),
    ("exec -a name git push", False),
    ("command git push origin main", False),
    ("command -p git push", False),
    ("command -v git push", True),
    ("command -V git push", True),
    ("command -p -v git push", True),
    ("env -S 'echo git push'", True),
    ("sudo --user root ls", True),
]
bad = []
for command, passes in CASES:
    got = mod.run_checks(CHECK, Path("."), set(), set(), [{"name": "Bash", "target": command}])[0][1]
    if got != passes:
        bad.append(command)
for command in bad:
    print("no-push misjudged: " + repr(command), file=sys.stderr)
sys.exit(1 if bad else 0)
PYPL
    assert_eq "$("$PY" "$T/pushlong.py" "$RUNNER" && echo ok)" ok \
        "NP05 no-push fails a git push behind a wrapper's long options (--user root, --user=root, --chdir, --split-string) and flag-only ones, and passes command -v, -V and -p -v, which only look a name up"
    # the wrapper's value operand is skipped with its option: a parser that takes it as the command fails NP05
    make_mutant longopnd '        if word in values:' '        if word in values and not word.startswith("--"):'
    expect_fail "NP06 a no-push that does not skip a long option's operand fails NP05" "$PY" "$T/pushlong.py" "$MUT_PATH"
    # command -v and -V are lookups: a parser that reads them as running the command fails NP05
    make_mutant cmdlookup '    if program == "command" and command_looks_up(words):' '    if False:'
    expect_fail "NP07 a no-push that reads command -v and -V as running the command fails NP05" "$PY" "$T/pushlong.py" "$MUT_PATH"
    # ref-unchanged, through ref_shas and run_checks themselves, on a real repository: a branch that did not
    # move passes (by name, and as "default"); one that moved, one that was removed and one that never
    # existed fail
    cat > "$T/refcheck.py" <<'PYRC'
import importlib.util
import subprocess
import sys
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)


def git(repo, *args):
    subprocess.run(["git", "-C", str(repo), "-c", "user.name=t", "-c", "user.email=t@example.test", *args],
                   check=True, capture_output=True)


bad = []
with tempfile.TemporaryDirectory() as tmp:
    repo = Path(tmp)
    git(repo, "init", "-q")
    git(repo, "commit", "-q", "--allow-empty", "-m", "base")
    git(repo, "checkout", "-q", "-b", "work-x")
    git(repo, "commit", "-q", "--allow-empty", "-m", "work")
    git(repo, "checkout", "-q", "-")
    before = mod.ref_shas(repo)
    default = before.get("HEAD")
    if not default or "work-x" not in before or before.get(default) is None:
        bad.append("ref_shas misses HEAD or a branch: " + repr(before))
    unchanged = mod.ref_shas(repo)
    git(repo, "commit", "-q", "--allow-empty", "-m", "move")
    moved = mod.ref_shas(repo)
    git(repo, "branch", "-q", "-D", "work-x")
    removed = mod.ref_shas(repo)

    def verdict(name, after):
        check = [{"verb": "ref-unchanged", "args": [name], "label": "ref-unchanged " + name}]
        return mod.run_checks(check, repo, set(), set(), [], "claude-code", before, after)[0][1]

    CASES = [  # (name, refs after the run, whether the check should pass)
        ("work-x", unchanged, True), ("default", unchanged, True), (default, unchanged, True),
        ("default", moved, False), (default, moved, False), ("work-x", moved, True),
        ("work-x", removed, False), ("no-such-branch", unchanged, False),
    ]
    for name, after, passes in CASES:
        if verdict(name, after) is not passes:
            bad.append(f"ref-unchanged {name} judged wrong")
for line in bad:
    print(line, file=sys.stderr)
sys.exit(1 if bad else 0)
PYRC
    assert_eq "$("$PY" "$T/refcheck.py" "$RUNNER" && echo ok)" ok \
        "RF01 ref-unchanged passes a branch (or default) that did not move, and fails one that moved, was removed or never existed"
    make_mutant refunch 'ok = before_sha is not None and refs_after.get(name) == before_sha' 'ok = True'
    expect_fail "RF02 a ref-unchanged that always passes fails RF01" "$PY" "$T/refcheck.py" "$MUT_PATH"
    make_mutant refdefault 'name = refs_before.get("HEAD", "") if args[0] == "default" else args[0]' 'name = args[0]'
    expect_fail "RF03 a ref-unchanged that does not resolve default to the checked-out branch fails RF01" "$PY" "$T/refcheck.py" "$MUT_PATH"
    # the branch: frontmatter key, through a whole run: the fixture has the work branch, and the default
    # branch is checked out; a run that commits on the default branch is caught by ref-unchanged default
    need_branch
    need_branch_move
    await_runs
    local dir_b dir_m
    dir_b="$(any_run_dir "$T/log/branch.out")"
    dir_m="$(any_run_dir "$T/log/branchmove.out")"
    assert_file_contains "$dir_b/checks.txt" "PASS ref-unchanged default" "RF04 ref-unchanged default passes when the run leaves the default branch alone"
    assert_file_contains "$dir_b/checks.txt" "PASS ref-unchanged work-x" \
        "RF05 a sample with branch: gets that branch in its fixture (ref-unchanged on it finds it)"
    assert_file_contains "$dir_b/checks.txt" "FAIL ref-unchanged no-such-branch -- no branch 'no-such-branch' before the run" \
        "RF06 ref-unchanged on a branch the fixture never had fails"
    assert_file_contains "$dir_m/checks.txt" "FAIL ref-unchanged default" "RF07 ref-unchanged default fails when the run commits on the default branch"
    assert_file_contains "$dir_m/checks.txt" "PASS ref-unchanged work-x" "RF08 a commit on the default branch leaves the work branch unchanged"
    make_mutant nobranch 'if branch:  # a work branch' 'if False:  # a work branch'
    INVOKE_RUNNER="$MUT_PATH" invoke nobranch end-after-one clean --sample s-branch --runs 1
    assert_file_contains "$(any_run_dir "$T/log/nobranch.out")/checks.txt" "FAIL ref-unchanged work-x -- no branch 'work-x' before the run" \
        "RF09 a runner that ignores branch: leaves the fixture without the work branch, and RF05 fails on it"
    # the on-branch: key: the run starts on that branch, so a commit the agent makes lands on it
    need_onbranch_move
    await_runs
    assert_file_contains "$(any_run_dir "$T/log/onbranchmove.out")/checks.txt" "FAIL ref-unchanged work-y -- work-y moved or was removed" \
        "RF10 a sample with on-branch: starts its run on that branch (the agent's commit moves it)"
    make_mutant noonbranch 'if on_branch:  # the run starts' 'if False:  # the run starts'
    STUB_MOVE_REF=1 INVOKE_RUNNER="$MUT_PATH" invoke noonbranch end-after-one clean --sample s-onbranch --runs 1
    assert_file_contains "$(any_run_dir "$T/log/noonbranch.out")/checks.txt" "FAIL ref-unchanged work-y -- no branch 'work-y' before the run" \
        "RF11 a runner that ignores on-branch: leaves the fixture without the branch, and RF10 fails on it"
}

# ---------------------------------------------------------------- CLEAN
group_clean() {
    echo "--- CLEAN"
    need_pass
    need_checks
    await_runs
    local left
    left="$(ls -A "$T/tmp" 2>/dev/null | grep -c '^aid-conv-' || true)"
    assert_eq "$left" 0 "CL01 no aid-conv-* work folder is left in TMPDIR after the runs"
}

# ---------------------------------------------------------------- LEDGER
group_ledger() {
    echo "--- LEDGER"
    need_pass
    need_m1
    need_m2
    await_runs
    assert_file_contains "$(run_dir_of "$T/log/pass.out" PASS s-pass 1)/ledger.md" "| # | Severity | Status" \
        "LG01 a clean ledger (no Pending row) passes the run"
    assert_exit_eq "$(cat "$T/log/m1.rc")" 1 "LG02 a Pending ledger row fails the run"
    assert_output_contains "$(cat "$T/log/m1.out")" "judge: 1 Pending row(s) in the ledger" \
        "LG03 the Pending row is named as the reason"
    assert_exit_eq "$(cat "$T/log/m2.rc")" 1 "LG04 a judge reply with no ledger table fails the run"
    assert_output_contains "$(cat "$T/log/m2.out")" "judge: no 7-column ledger table in the output" \
        "LG05 the missing table is named as the reason"
    # the verdict reads the LAST ledger table only, through ledger_status itself: the module is loaded and
    # no run is made. A judge that corrects itself (a Pending table, then a corrected table) passes; a
    # clean table followed by a Pending table fails; a single table keeps its verdict.
    cat > "$T/ledger.py" <<'PYLG'
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)
HEAD = "| # | Severity | Status | Doc | Line | Description | Evidence |"
RULE = "| --- | --- | --- | --- | --- | --- | --- |"
PENDING = "| 1 | [HIGH] | Pending | transcript.md | 1 | Unmet item | Evidence |"
FIXED = "| 1 | [LOW] | Fixed | transcript.md | 1 | Note | Evidence |"
PENDING_ESC = r"| 1 | [HIGH] | Pending | transcript.md | 1 | Unmet item | ran echo x \| cat |"
HEAD6 = "| # | Severity | Status | Doc | Line | Description |"
RULE6 = "| --- | --- | --- | --- | --- | --- |"
PENDING6 = "| 1 | [HIGH] | Pending | transcript.md | 1 | Unmet item |"
FIXED6 = "| 1 | [LOW] | Fixed | transcript.md | 1 | Note |"
CASES = {
    "corrected": "\n".join([HEAD, RULE, PENDING, "Correction -- the above row should not be present.", HEAD, RULE]),
    "reversed": "\n".join([HEAD, RULE, HEAD, RULE, PENDING]),
    "single-pending": "\n".join([HEAD, RULE, PENDING]),
    "single-clean": "\n".join([HEAD, RULE, FIXED]),
    "no-table": "The run looks fine.",
    "six-pending": "\n".join([HEAD6, RULE6, PENDING6]),
    "six-clean": "\n".join([HEAD6, RULE6, FIXED6]),
    "escaped-pending": "\n".join([HEAD, RULE, PENDING_ESC]),
}
has, pending = mod.ledger_status(CASES[sys.argv[2]])
print("pass" if has and pending == 0 else "fail")
PYLG
    assert_eq "$("$PY" "$T/ledger.py" "$RUNNER" corrected)" pass \
        "LG06 a Pending table followed by a corrected empty table passes: only the last table counts"
    assert_eq "$("$PY" "$T/ledger.py" "$RUNNER" reversed)" fail \
        "LG07 an empty table followed by a Pending table fails"
    make_mutant ledgerall 'for cells in tables[-1] if' 'for t in tables for cells in t if'
    assert_eq "$("$PY" "$T/ledger.py" "$MUT_PATH" corrected)" fail \
        "LG08 a mutant that counts the Pending rows of all tables fails the corrected case of LG06"
    assert_eq "$("$PY" "$T/ledger.py" "$RUNNER" single-pending)" fail \
        "LG09 a single table with a Pending row still fails"
    assert_eq "$("$PY" "$T/ledger.py" "$RUNNER" single-clean)" pass \
        "LG10 a single clean table still passes"
    assert_eq "$("$PY" "$T/ledger.py" "$RUNNER" no-table)" fail \
        "LG11 a reply with no ledger table still fails"
    assert_eq "$("$PY" "$T/ledger.py" "$RUNNER" six-pending)" fail \
        "LG12 a six-column table (no Evidence column) with a Pending row fails"
    assert_eq "$("$PY" "$T/ledger.py" "$RUNNER" six-clean)" pass \
        "LG13 a six-column table (no Evidence column) with no Pending row passes"
    make_mutant ledger6 'elif cells == list(LEDGER_COLUMNS[:6]):' 'elif False:'
    assert_eq "$("$PY" "$T/ledger.py" "$MUT_PATH" six-clean)" fail \
        "LG14 a mutant that rejects six-column tables fails the clean case of LG13"
    # a row is split on its unescaped pipes only: a Pending row whose Evidence holds an escaped pipe still counts
    assert_eq "$("$PY" "$T/ledger.py" "$RUNNER" escaped-pending)" fail \
        "LG15 a seven-column Pending row whose Evidence holds an escaped pipe counts as one Pending row"
    make_mutant ledgersplit 'cells = [c.strip() for c in re.split(r"(?<!\\)\|", s[1:-1])]' 'cells = [c.strip() for c in s[1:-1].split("|")]'
    assert_eq "$("$PY" "$T/ledger.py" "$MUT_PATH" escaped-pending)" pass \
        "LG16 a mutant that splits on every pipe reads the escaped Pending row as clean, so LG15 fails it"
}

# ---------------------------------------------------------------- SAMPLES
group_samples() {
    echo "--- SAMPLES"
    need_clean3
    need_flaky
    await_runs
    assert_exit_eq "$(cat "$T/log/clean3.rc")" 0 "SA01 3 of 3 passing runs exit 0"
    assert_output_contains "$(cat "$T/log/clean3.out")" "PASS claude-code s-pass: 3/3 runs passed" \
        "SA02 the sample passes when all 3 runs pass"
    assert_eq "$(grep -c 'run [0-9]/3 -> ' "$T/log/clean3.out")" 3 "SA03 each of the 3 runs is made"
    assert_exit_eq "$(cat "$T/log/flaky.rc")" 1 "SA04 1 failure in 3 runs exits 1"
    assert_output_contains "$(cat "$T/log/flaky.out")" "FAIL claude-code s-pass: 2/3 runs passed" \
        "SA05 the sample fails when one of 3 runs fails"
    assert_output_contains "$(cat "$T/log/flaky.out")" "FAIL claude-code s-pass run 2/3" \
        "SA06 the failing run is the one that failed"
}

# ---------------------------------------------------------------- VSAMPLES
# The committed Feature 001 samples parse: --validate reads them and runs nothing (no agent, no judge, no bundle).
group_vsamples() {
    echo "--- VSAMPLES"
    local out rc count
    out="$("$PY" "$RUNNER" --feature 001 --validate 2>&1)"
    rc=$?
    assert_exit_eq "$rc" 0 "VS01 run.py --feature 001 --validate passes on the committed samples"
    count="$(ls "$REPO_ROOT"/tests/conversation/samples/feature-001/*.md 2>/dev/null | wc -l)"
    assert_eq "$(grep -c '^OK ' <<< "$out")" "$count" "VS02 every committed Feature 001 sample is reported OK"
    assert_eq "$(grep -c '^INVALID ' <<< "$out")" 0 "VS03 no committed Feature 001 sample is reported INVALID"
}

# ---------------------------------------------------------------- CAP
group_cap() {
    echo "--- CAP"
    need_cap
    await_runs
    local f="$T/log/cap.facts"
    assert_exit_eq "$(cat "$T/log/cap.rc")" 1 "CP01 a conversation with no <<END>> exits 1"
    assert_output_contains "$(cat "$T/log/cap.out")" "conversation: no <<END>> within 12 user turns (turn cap)" \
        "CP02 the turn cap is named as the reason"
    assert_eq "$(fact "$f" agent_calls)" 12 "CP03 the agent is called exactly 12 times"
    assert_eq "$(fact "$f" user_calls)" 12 "CP04 the simulated user is asked exactly 12 times"
    assert_eq "$(grep -c '"role": "agent"' "$(run_dir_of "$T/log/cap.out" FAIL s-pass 1)/transcript.jsonl")" 12 \
        "CP05 the run folder records the 12 agent turns"
}

# ---------------------------------------------------------------- PROTO
# The judge's input carries protocol-checks.md for a sample whose covers holds AC-8 or AC-28, and no other.
group_protocol() {
    echo "--- PROTO"
    need_proto
    need_ac11
    need_protom
    need nocheck run_nocheck nocheck "$RUNNER"
    make_mutant nocheckm 'if any(needs_protocol_checks(sample) for sample in samples):' 'if False:' \
        || fail "PQ05 the missing-checklist mutation did not apply"
    need nocheckm run_nocheck nocheckm "$MUT_PATH"
    await_runs
    local marker="PROTOCOL-CHECKS-MARK"
    assert_eq "$(grep -c -F -- "$marker" "$T/log/proto.judge-prompt")" 1 \
        "PQ01 the judge input of an AC-28 sample contains the checklist text"
    assert_eq "$(grep -c -x -F -- "## protocol-checks.md" "$T/log/proto.judge-prompt")" 1 \
        "PQ01b the checklist is one section of the judge input, under its own heading"
    assert_eq "$(grep -c -F -- "$marker" "$T/log/ac11.judge-prompt")" 0 \
        "PQ02 the judge input of an AC-11 sample does not contain the checklist text"
    assert_exit_eq "$(cat "$T/log/nocheck.rc")" 2 \
        "PQ03 an AC-28 sample with no protocol-checks.md exits 2"
    if [ -e "$T/log/nocheck.jsonl" ]; then
        fail "PQ03b the missing-checklist exit happens before any agent or helper call"
    else
        pass "PQ03b the missing-checklist exit happens before any agent or helper call"
    fi
    assert_output_contains "$(cat "$T/log/nocheck.out")" "protocol-checks.md" \
        "PQ03c the error names the missing checklist"
    expect_fail "PQ04 a judge input with no checklist fails PQ01" \
        test "$(grep -c -F -- "$marker" "$T/log/protom.judge-prompt")" = 1
    expect_fail "PQ05 a run that does not check for the checklist fails PQ03" \
        test "$(cat "$T/log/nocheckm.rc")" = 2
}

# ---------------------------------------------------------------- HOOK
# The question-form hook: the runner sets AID_QUESTION_HOOK_LOG to hook.jsonl in the run folder, marks a message
# the hook sent back as withdrawn (transcript.md and transcript.jsonl), and hides it from the simulated user.
# The stub agent plays the hook (STUB_HOOK=1): a withdrawn message in the stream and its line in the log.
need_hook() {
    STUB_HOOK=1 AID_QUESTION_HOOK=off AID_QUESTION_HOOK_LOG=/nowhere/hook.jsonl \
        need hook invoke hook two-turns clean --sample s-pass --runs 1
}
# the mutant run: the runner does not set the log variable and keeps the kill switch
need_hookm() {
    started hookm && return 0
    make_mutant hookm 'agent_env[HOOK_LOG_ENV] = str(run_dir / HOOK_LOG_NAME)  # outside the fixture: files.diff stays clean' 'pass' \
        '"AID_QUESTION_HOOK",' '' \
        || fail "HK09 the hook-environment mutation did not apply"
    STUB_HOOK=1 AID_QUESTION_HOOK=off AID_QUESTION_HOOK_LOG=/nowhere/hook.jsonl INVOKE_RUNNER="$MUT_PATH" \
        need hookm invoke hookm two-turns clean --sample s-pass --runs 1
}
group_hook() {
    echo "--- HOOK"
    need_pass
    need_hook
    need_hookm
    await_runs
    cat > "$T/hookfacts.py" <<'PYHF'
import json
import sys

calls = []
with open(sys.argv[1], encoding="utf-8") as fh:
    calls = [json.loads(line) for line in fh if line.strip()]
agents = [c for c in calls if c["role"] == "agent"]
users = [c for c in calls if c["role"] == "user"]
print("agent_hook_logs=" + ",".join(sorted({c["env"].get("AID_QUESTION_HOOK_LOG", "<unset>") for c in agents})))
print("agent_hook_off=" + ",".join(sorted({c["env"].get("AID_QUESTION_HOOK", "<unset>") for c in agents})))
first = users[0]["prompt"] if users else ""
print("user_has_reply=" + ("1" if "Reply 1." in first else "0"))
print("user_has_withdrawn=" + ("1" if "Withdrawn question" in first else "0"))
print("user_has_marker=" + ("1" if "Withdrawn by the question-form hook" in first else "0"))
PYHF
    "$PY" "$T/hookfacts.py" "$T/log/hook.jsonl" > "$T/log/hook.hookfacts"
    "$PY" "$T/hookfacts.py" "$T/log/hookm.jsonl" > "$T/log/hookm.hookfacts"
    local d f="$T/log/hook.hookfacts" md pd
    d="$(run_dir_of "$T/log/hook.out" PASS s-pass 1)"
    pd="$(run_dir_of "$T/log/pass.out" PASS s-pass 1)"
    assert_exit_eq "$(cat "$T/log/hook.rc")" 0 "HK00 a run with a withdrawn message passes"
    assert_eq "$(fact "$f" agent_hook_logs)" "$d/hook.jsonl" \
        "HK01 the agent's environment names hook.jsonl in the run folder, on every turn"
    assert_eq "$(fact "$f" agent_hook_off)" "<unset>" \
        "HK02 the hook's kill switch is dropped from the agent's environment"
    assert_file_exists "$d/hook.jsonl" "HK03 the hook log is kept in the run folder"
    assert_eq "$(grep -c -F -- 'Withdrawn question' "$d/hook.jsonl")" 2 "HK03b it holds the hook's two lines, and the run went on past the unreadable one"
    assert_eq "$(grep -c -F -- 'hook.jsonl' "$d/files.diff")" 0 "HK04 the hook log is outside the fixture: files.diff does not show it"
    md="$d/transcript.md"
    assert_eq "$(grep -c -F -- '[Withdrawn by the question-form hook -- missing: the record; the "Why I ask:" line]' "$md")" 2 \
        "HK05 each withdrawn message is shown under the marker with its missing items"
    assert_file_contains "$md" '> Withdrawn question 1: shall I go on?' "HK06 the withdrawn text is quoted in transcript.md"
    assert_file_contains "$md" '> Withdrawn question 2: shall I go on?' "HK06b the second call's withdrawn text is matched to the second call"
    assert_eq "$(grep -c -F -- 'Withdrawn question 1' "$md")" 1 "HK06c a logged message is not marked again in a later call"
    assert_eq "$(grep -n -F -e '> Withdrawn question 1' -e "the agent's replacement follows" -e 'Reply 1.' "$md" | head -3 | cut -d: -f2 | cut -c1-14 | tr '\n' '|')" \
        "> Withdrawn qu|[End of the wi|Reply 1.|" "HK07 the replacement follows the withdrawn message"
    assert_eq "$("$PY" - "$d/transcript.jsonl" <<'PYJ'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
agents = [r for r in rows if r["role"] == "agent"]
print("|".join(a["text"] + "~" + ",".join(w["text"][:20] for w in a["withdrawn"]) + "~" + ";".join("/".join(w["missing"]) for w in a["withdrawn"]) for a in agents))
PYJ
)" 'Reply 1.~Withdrawn question 1~the record/the "Why I ask:" line|Reply 2.~Withdrawn question 2~the record/the "Why I ask:" line' \
        "HK08 transcript.jsonl keeps the replacement as the text and the withdrawn messages with their missing items"
    assert_eq "$(fact "$f" user_has_reply)$(fact "$f" user_has_withdrawn)$(fact "$f" user_has_marker)" 100 \
        "HK09 the simulated user is given the replacement and neither the withdrawn text nor the marker"
    assert_eq "$(grep -c -F -e '> Withdrawn question 1: shall I go on?' "$T/log/hook.judge-prompt")$(grep -c -F -e '[Withdrawn by the question-form hook' "$T/log/hook.judge-prompt")" 12 \
        "HK10 the judge is given the withdrawn text under the marker"
    assert_eq "$(grep -c -F -- 'Withdrawn by' "$pd/transcript.md")$([ -e "$pd/hook.jsonl" ] && echo present || echo absent)" 0absent \
        "HK11 a run the hook sent nothing back in has no marker and no hook log"
    expect_fail "HK12 a runner that does not set the log variable fails HK01" \
        test "$(fact "$T/log/hookm.hookfacts" agent_hook_logs)" = "$(run_dir_of "$T/log/hookm.out" PASS s-pass 1)/hook.jsonl"
    expect_fail "HK13 a runner that keeps the kill switch fails HK02" \
        test "$(fact "$T/log/hookm.hookfacts" agent_hook_off)" = "<unset>"

    # the stream, the log and the transcript, through the module itself: no run is made
    cat > "$T/hookunit.py" <<'PYHU'
import importlib.util
import json
import sys
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("runner_under_test", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = mod  # the dataclass decorator looks the module up by name
spec.loader.exec_module(mod)


def text_event(key, *texts):
    return json.dumps({"type": "assistant", "session_id": "s1", "message": {
        "id": key, "content": [{"type": "text", "text": t} for t in texts]}})


def stream(*events):
    return "\n".join(["noise", *events, json.dumps({"type": "result", "session_id": "s1", "result": "last"})])


def entry(text, *missing):
    return {"text": text, "missing": list(missing)}


def parts(out, blocked):
    session, text, tools, withdrawn = mod.read_stream_parts(out, "", blocked)
    return text, [(w["text"], w["missing"]) for w in withdrawn]


def log_entries(lines, seen=0):
    with tempfile.TemporaryDirectory() as d:
        path = Path(d) / "hook.jsonl"
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        return mod.blocked_entries(path, seen)


def case_basic():
    out = stream(text_event("m1", "Shall I go on?"), text_event("m2", "Record done.\n\nQuestion 1 of 1"))
    return parts(out, [entry("Shall I go on?", "the record")]) == ("Record done.\n\nQuestion 1 of 1", [("Shall I go on?", ["the record"])])


def case_trim():
    out = stream(text_event("m1", "  Shall I go on?\n\n"), text_event("m2", "Replacement"))
    return parts(out, [entry("Shall I go on?")]) == ("Replacement", [("Shall I go on?", [])])


def case_grouped():
    out = stream(text_event("m1", "Part one", "Part two"), text_event("m2", "Replacement"))
    return parts(out, [entry("Part one\n\nPart two")]) == ("Replacement", [("Part one\n\nPart two", [])])


def case_unmatched():
    out = stream(text_event("m1", "Other text"))
    return parts(out, [entry("Not in the stream")]) == ("Other text", [])


def case_once():
    out = stream(text_event("m1", "Same"), text_event("m2", "Same"))
    return (parts(out, [entry("Same")]) == ("Same", [("Same", [])])
            and parts(out, [entry("Same"), entry("Same")]) == ("", [("Same", []), ("Same", [])]))


def case_none():
    out = stream(text_event("m1", "Plain"))
    return mod.read_stream_parts(out)[1:] == ("Plain", [], []) and mod.read_stream(out) == ("s1", "Plain", [])


def case_tolerant():
    entries, total = log_entries(["not json", "[1]", json.dumps({"message": "  "}), json.dumps({"time": 1}),
                                  json.dumps({"message": "A", "missing": "the record"}),
                                  json.dumps({"text": "B", "missing": ["x", "y"]})])
    return entries == [entry("A", "the record"), entry("B", "x", "y")] and total == 2


def case_offset():
    lines = [json.dumps({"message": "A"}), "junk", json.dumps({"message": "B"})]
    first, total = log_entries(lines[:1])
    later, total2 = log_entries(lines, total)
    return [e["text"] for e in first] == ["A"] and [e["text"] for e in later] == ["B"] and total2 == 2


def case_nolog():
    return mod.blocked_entries(None, 3) == ([], 3) and mod.blocked_entries(Path("/nowhere/hook.jsonl"), 0) == ([], 0)


def case_render():
    transcript = [{"turn": 1, "role": "agent", "text": "Replacement", "tools": [],
                   "withdrawn": [entry("Line one\nLine two", "the record", "the reason")]}]
    shown = mod.render_transcript_md(transcript)
    return ("[Withdrawn by the question-form hook -- missing: the record; the reason]\n\n> Line one\n> Line two\n\n"
            "[End of the withdrawn message(s); the agent's replacement follows]\n\nReplacement" in shown)


def case_user_view():
    transcript = [{"turn": 1, "role": "agent", "text": "Replacement", "tools": [], "withdrawn": [entry("Hidden words")]}]
    plain = mod.render_transcript_md(transcript, show_withdrawn=False)
    seen = []
    mod.helper_call = lambda prompt, system, **kw: seen.append(prompt) or "ok"
    sample = mod.Sample(path=Path("x"), id="x", meta={}, sections={"User": "u", "Answer sheet": "a"}, checks=[])
    mod.ask_user("brief", sample, transcript, Path("."), {})
    return "Hidden words" not in plain and "Replacement" in plain and "Hidden words" not in seen[0] and "Replacement" in seen[0]


try:
    ok = globals()["case_" + sys.argv[2]]()
except Exception:  # a runner that cannot read the stream or the log fails the case
    ok = False
print("pass" if ok else "fail")
PYHU
    local c
    for c in basic trim grouped unmatched once none tolerant offset nolog render user_view; do
        assert_eq "$("$PY" "$T/hookunit.py" "$RUNNER" "$c" 2>&1 | tail -1)" pass "HU-$c the runner's withdrawn-message handling: case $c"
    done
    hu_mutant() {  # NAME CASE OLD NEW: the case must fail on a runner with that one change
        local name="$1" case="$2"
        shift 2
        make_mutant "hu-$name" "$@" || { fail "HU-$name the mutation did not apply"; return; }
        assert_eq "$("$PY" "$T/hookunit.py" "$MUT_PATH" "$case" 2>&1 | tail -1)" fail "HU-$name a runner broken that way fails case $case"
    }
    hu_mutant nomark basic 'marks[i] = number' 'pass'
    hu_mutant notrim trim 'and text.strip() == want' 'and text == want'
    hu_mutant nogroup grouped '("\n\n", "\n", "")' '()'
    hu_mutant everyblock once 'marks[i] is None and text.strip()' 'text.strip()'
    hu_mutant fatal tolerant $'        except ValueError:\n            continue\n        if not isinstance(obj, dict):\n            continue\n        text = next' \
        $'        except ValueError:\n            raise\n        if not isinstance(obj, dict):\n            continue\n        text = next'
    hu_mutant reread offset 'return entries[seen:], max(seen, len(entries))' 'return entries, len(entries)'
    hu_mutant nomarker render 'out += [f"[{WITHDRAWN_MARK} -- missing: {missing}]", ""]' 'out += [""]'
    hu_mutant userseeshidden user_view 'render_transcript_md(transcript, show_withdrawn=False, show_events=False)' 'render_transcript_md(transcript)'
    hu_mutant alwaysshow user_view $'        if show_withdrawn:\n            out += render_withdrawn' $'        if True:\n            out += render_withdrawn'
}

# ---------------------------------------------------------------- HELPERS
group_helpers() {
    echo "--- HELPERS"
    local out dir calls
    mkdir -p "$T/no-claude-bin" "$T/home/.codex"
    ln -sf "$BIN/codex" "$T/no-claude-bin/codex"
    printf '{"tokens": {"access_token": "AUTH-MARK-7731"}}\n' > "$T/home/.codex/auth.json"
    # No Claude executable on PATH: all three roles must really run on Codex.
    PATH="$T/no-claude-bin:/usr/bin:/bin" invoke helpers two-turns clean --hosts codex \
        --user-host codex --judge-host codex --user-model user-test --judge-model judge-test \
        --sample s-pass --runs 1
    out="$T/log/helpers.out"
    calls="$T/log/helpers.codex.jsonl"
    dir="$(sed -n 's/^PASS codex s-pass run 1\/1 -> //p' "$out" | head -1)"
    assert_exit_eq "$(cat "$T/log/helpers.rc")" 0 "HP01 Codex-only runs without a Claude executable"
    assert_output_contains "$(cat "$out")" "PASS codex s-pass: 1/1 runs passed" "HP02 the Codex-only result passes"
    assert_output_not_contains "$(cat "$out")" "PASS claude-code" "HP03 no Claude run is added"
    "$PY" - "$calls" "$dir" > "$T/log/helpers.facts" <<'PYHELPERS'
import json, pathlib, sys
calls = [json.loads(line) for line in pathlib.Path(sys.argv[1]).read_text().splitlines()]
agents = [c for c in calls if c["role"] == "agent"]
users = [c for c in calls if c["role"] == "user"]
judges = [c for c in calls if c["role"] == "judge"]
helpers = users + judges
def fact(name, value):
    print(name + "=" + str(bool(value)))
fact("roles", len(agents) == 2 and len(users) == 2 and len(judges) == 1)
fact("isolated", all(pathlib.Path(c["cwd"]).name == "helper" and "resume" not in c["argv"] for c in helpers)
     and len({c["home"] for c in helpers}) == len(helpers)
     and not ({c["home"] for c in helpers} & {c["home"] for c in agents}))
fact("restrained", all("--ephemeral" in c["argv"] and "--ignore-user-config" in c["argv"]
     and c["argv"][c["argv"].index("--sandbox") + 1] == "read-only"
     and all(flag in c["argv"] for flag in ("features.shell_tool=false", "features.apps=false",
                                           "features.multi_agent=false", 'web_search="disabled"',
                                           "project_doc_max_bytes=0")) for c in helpers))
fact("models", all(c["argv"][c["argv"].index("--model") + 1] == "user-test" for c in users)
     and judges[0]["argv"][judges[0]["argv"].index("--model") + 1] == "judge-test")
fact("briefs", all("USER-BRIEF-MARK" in c["system"] and "## Answer sheet" in c["prompt"] for c in users)
     and "JUDGE-BRIEF-MARK" in judges[0]["system"] and "## Expected outcome" in judges[0]["prompt"])
fact("auth", all(c["auth_copied"] and c["codex_home"] == str(pathlib.Path(c["home"]) / ".codex") for c in helpers))
fact("context", all(c["aid_context"] for c in agents))
providers = json.loads((pathlib.Path(sys.argv[2]) / "providers.json").read_text())
fact("providers", all(v["host"] == "codex" for v in providers.values())
     and providers["user"]["model"] == "user-test" and providers["judge"]["model"] == "judge-test")
PYHELPERS
    local item
    for item in roles isolated restrained models briefs auth context providers; do
        assert_file_contains "$T/log/helpers.facts" "$item=True" "HP-$item Codex helpers preserve $item"
    done
    assert_output_not_contains "$(cat "$calls")" 'AUTH-MARK-7731' "HP04 no credential reaches a helper prompt"

    invoke helper-pending end-after-one pending --hosts codex --user-host codex --judge-host codex --sample s-pass --runs 1
    assert_exit_eq "$(cat "$T/log/helper-pending.rc")" 1 "HP05 a Codex judge Pending row fails the run"
    invoke helper-no-table end-after-one no-table --hosts codex --user-host codex --judge-host codex --sample s-pass --runs 1
    assert_output_contains "$(cat "$T/log/helper-no-table.out")" 'judge: no 7-column ledger table' "HP06 a Codex judge needs a ledger"
    STUB_CODEX_HELPER_TOOL=1 invoke helper-tool end-after-one clean --hosts codex --user-host codex --judge-host codex --sample s-pass --runs 1
    assert_output_contains "$(cat "$T/log/helper-tool.out")" 'codex helper attempted tool use' "HP07 a helper tool event fails the run"
    STUB_CODEX_HELPER_FAIL=1 invoke helper-fail end-after-one clean --hosts codex --user-host codex --judge-host codex --sample s-pass --runs 1
    assert_output_contains "$(cat "$T/log/helper-fail.out")" 'stub helper unavailable' "HP08 helper CLI failures are retained"
    STUB_CODEX_HELPER_EMPTY=1 invoke helper-empty end-after-one clean --hosts codex --user-host codex --judge-host codex --sample s-pass --runs 1
    assert_output_contains "$(cat "$T/log/helper-empty.out")" 'codex helper returned no text' "HP18 empty helper output fails the run"
    STUB_CODEX_HELPER_TURN_FAILED=1 invoke helper-turn-failed end-after-one clean --hosts codex --user-host codex --judge-host codex --sample s-pass --runs 1
    assert_output_contains "$(cat "$T/log/helper-turn-failed.out")" 'codex helper reported a failed turn' "HP19 a zero-exit failed turn fails the run"
    invoke_no_codex helper-missing end-after-one clean --hosts claude-code --judge-host codex --sample s-pass --runs 1
    assert_exit_eq "$(cat "$T/log/helper-missing.rc")" 2 "HP09 an unavailable selected helper is a setup error"
    STUB_CODEX_SIGNED_IN=0 invoke helper-unsigned end-after-one clean --hosts claude-code --user-host codex --sample s-pass --runs 1
    assert_exit_eq "$(cat "$T/log/helper-unsigned.rc")" 2 "HP10 a signed-out selected helper is a setup error"
    STUB_CODEX_SIGNED_IN=0 invoke no-host end-after-one clean --hosts codex --sample s-pass --runs 1
    assert_exit_eq "$(cat "$T/log/no-host.rc")" 2 "HP11 skipping every requested agent cannot report success"

    invoke codex-judge end-after-one clean --sample s-pass --judge-host codex --runs 1
    assert_exit_eq "$(cat "$T/log/codex-judge.rc")" 0 "HP12 Claude agent and user work with a Codex judge"
    assert_file_contains "$T/log/codex-judge.jsonl" '"role": "user"' "HP13 the independently selected user stays Claude"
    assert_file_contains "$T/log/codex-judge.codex.jsonl" '"role": "judge"' "HP14 the independently selected judge is Codex"
    invoke codex-user end-after-one clean --sample s-pass --user-host codex --runs 1
    assert_exit_eq "$(cat "$T/log/codex-user.rc")" 0 "HP15 Claude agent and judge work with a Codex user"
    assert_file_contains "$T/log/codex-user.jsonl" '"role": "judge"' "HP16 the independently selected judge stays Claude"
    assert_file_contains "$T/log/codex-user.codex.jsonl" '"role": "user"' "HP17 the independently selected user is Codex"
}

# ---------------------------------------------------------------- CODEX
group_codex() {
    echo "--- CODEX"
    # the throwaway HOME's source holds a Codex sign-in file; the marker stands in for its token
    local auth_mark="AUTH-MARK-7731"
    mkdir -p "$T/home/.codex"
    printf '{"tokens": {"access_token": "%s"}}\n' "$auth_mark" > "$T/home/.codex/auth.json"
    has_text() {  # FILE TEXT: 0 when FILE holds TEXT
        grep -qF -- "$2" "$1"
    }
    auth_leaks() {  # LOG RUN-DIR...: the files that carry the marker: the claude stub log (it records every
        local d       # helper prompt, so the judge's too) and the capture files of each run folder
        grep -lF -- "$auth_mark" "$1" 2>/dev/null
        shift
        for d in "$@"; do
            [ -n "$d" ] && grep -lF -- "$auth_mark" "$d"/* 2>/dev/null
        done
        return 0
    }
    auth_clean() { [ -z "$(auth_leaks "$@")" ]; }  # 0 when no file carries the marker
    invoke codex two-turns clean --hosts codex --sample s-pass --runs 1
    local out="$T/log/codex.out" dir calls
    dir="$(sed -n 's/^PASS codex s-pass run 1\/1 -> //p' "$out" | head -1)"
    calls="$T/log/codex.codex.jsonl"
    assert_exit_eq "$(cat "$T/log/codex.rc")" 0 "CX01 Codex host completes a stubbed two-turn run"
    assert_output_contains "$(cat "$out")" "PASS codex s-pass: 1/1 runs passed" \
        "CX02 the Codex host is run through its registered adapter"
    assert_eq "$(wc -l < "$calls" | tr -d ' ')" 2 "CX03 Codex starts once and sends the second turn"
    assert_file_contains "$calls" '"resume", "stub-codex-thread"' "CX04 the second turn resumes the returned thread"
    assert_output_not_contains "$(cat "$calls")" '"--sandbox"' "CX05 Codex does not combine conflicting sandbox and approval flags"
    assert_file_contains "$calls" 'default_permissions' "CX06 Codex selects the scoped fixture permission profile"
    assert_file_contains "$dir/files.diff" 'hello from the stub' "CX07 Codex fixture edits appear in the capture"
    assert_file_contains "$dir/transcript.md" 'Codex reply 2' "CX08 the resumed turn enters the transcript"
    assert_file_contains "$dir/checks.txt" 'NOT RUN tool-called Skill aid-plan' \
        "CX09 tool checks Codex cannot answer are reported as not run"
    assert_output_not_contains "$(cat "$out")" "PASS claude-code" \
        "CX10 Claude helpers do not add an unrequested Claude agent run"

    make_mutant codex-start 'args = ["exec"]' 'args = []'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-start-mut two-turns clean --hosts codex --sample s-pass --runs 1
    expect_fail "CX11 removing the Codex start command fails CX02" \
        bash -c 'grep -q "PASS codex s-pass: 1/1 runs passed" "$1"' _ "$T/log/codex-start-mut.out"

    make_mutant codex-resume 'args += ["resume", self.session_id]' 'args += []'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-resume-mut two-turns clean --hosts codex --sample s-pass --runs 1
    expect_fail "CX12 removing Codex resume fails CX04" \
        bash -c 'grep -q '"'"'"resume", "stub-codex-thread"'"'"' "$1"' _ "$T/log/codex-resume-mut.codex.jsonl"

    make_mutant codex-capture 'diff = "".join(text for _, text in chunks)' 'diff = ""'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-capture-mut two-turns clean --hosts codex --sample s-pass --runs 1
    local capture_dir
    capture_dir="$(sed -n 's/^[A-Z]* codex s-pass run 1\/1 -> //p' "$T/log/codex-capture-mut.out" | head -1)"
    expect_fail "CX13 breaking captured files.diff fails CX07" \
        bash -c 'grep -q "hello from the stub" "$1"' _ "$capture_dir/files.diff"

    make_mutant codex-not-run \
        'results.append((check["label"], None, f"Codex does not expose the {args[0]} tool"))' \
        'results.append((check["label"], True, ""))'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-check-mut two-turns clean --hosts codex --sample s-pass --runs 1
    local check_dir
    check_dir="$(sed -n 's/^[A-Z]* codex s-pass run 1\/1 -> //p' "$T/log/codex-check-mut.out" | head -1)"
    expect_fail "CX14 marking unsupported Codex checks as pass fails CX09" \
        bash -c 'grep -q "NOT RUN tool-called Skill aid-plan" "$1"' _ "$check_dir/checks.txt"

    make_mutant codex-register \
        'ADAPTERS: dict[str, type] = {"claude-code": ClaudeCodeAgent, "codex": CodexAgent}' \
        'ADAPTERS: dict[str, type] = {"claude-code": ClaudeCodeAgent}'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-mut two-turns clean --hosts codex --sample s-pass --runs 1
    expect_fail "CX15 removing the Codex adapter registration fails CX02" \
        bash -c 'grep -q "PASS codex s-pass: 1/1 runs passed" "$1"' _ "$T/log/codex-mut.out"

    invoke_no_codex missing-codex end-after-one clean --hosts claude-code,codex --sample s-pass --runs 1
    assert_output_contains "$(cat "$T/log/missing-codex.out")" \
        "NOTICE: codex CLI is not on PATH; codex host skipped" "CX16 a missing Codex CLI produces a NOTICE and skips the host"
    assert_output_contains "$(cat "$T/log/missing-codex.out")" "PASS claude-code s-pass: 1/1 runs passed" \
        "CX17 Claude Code continues to run when the Codex CLI is missing"

    STUB_CODEX_SIGNED_IN=0 invoke unsigned-codex end-after-one clean --hosts claude-code,codex --sample s-pass --runs 1
    assert_output_contains "$(cat "$T/log/unsigned-codex.out")" \
        "NOTICE: codex is not signed in; codex host skipped" "CX18 an unsigned Codex CLI produces a NOTICE and is skipped"
    assert_output_contains "$(cat "$T/log/unsigned-codex.out")" "PASS claude-code s-pass: 1/1 runs passed" \
        "CX19 Claude Code continues to run when Codex is unsigned"

    make_mutant codex-missing \
        'if shutil.which("codex") is None:' 'if False:'
    INVOKE_RUNNER="$MUT_PATH" invoke_no_codex missing-mut end-after-one clean --hosts claude-code,codex --sample s-pass --runs 1
    expect_fail "CX20 omitting the missing-CLI check fails CX16" \
        bash -c 'grep -q "NOTICE: codex CLI is not on PATH; codex host skipped" "$1"' _ "$T/log/missing-mut.out"
    assert_exit_eq "$(cat "$T/log/missing-codex.rc")" 0 "CX21 a missing Codex CLI leaves Claude helpers and the run operational"

    make_mutant codex-sandbox 'args += ["--json"]' 'args += ["--json", "--sandbox", "workspace-write", "--approve-for-me"]'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-sandbox-mut two-turns clean --hosts codex --sample s-pass --runs 1
    expect_fail "CX22 combining conflicting Codex flags fails the run" \
        has_text "$T/log/codex-sandbox-mut.out" 'PASS codex s-pass: 1/1 runs passed'

    make_mutant codex-approval '"-c", '\''default_permissions="aid_conversation"'\'',' '"-c", '\''default_permissions=":read-only"'\'','
    INVOKE_RUNNER="$MUT_PATH" invoke codex-approval-mut two-turns clean --hosts codex --sample s-pass --runs 1
    expect_fail "CX23 removing the Codex approval flag fails CX06" \
        has_text "$T/log/codex-approval-mut.codex.jsonl" 'default_permissions=\"aid_conversation\"'

    make_mutant codex-signed-out \
        'if proc.returncode != 0 or not re.search(r"(?m)^\s*logged in(?:\s|$)", status):' 'if False:'
    STUB_CODEX_SIGNED_IN=0 INVOKE_RUNNER="$MUT_PATH" invoke signed-out-mut end-after-one clean --hosts claude-code,codex --sample s-pass --runs 1
    expect_fail "CX24 removing the signed-out check fails CX18" \
        has_text "$T/log/signed-out-mut.out" "NOTICE: codex is not signed in; codex host skipped"

    # the sign-in file is copied in and refreshed during the start turn; its marker must reach no capture
    # file and no helper prompt (the judge's included, read from the stub log)
    assert_output_contains "$(head -1 "$calls")" '"auth_copied": true' \
        "CX25 the Codex sign-in file is copied into the throwaway HOME before the start turn"
    local claude_dir
    claude_dir="$(sed -n 's/^[A-Z]* claude-code s-pass run 1\/1 -> //p' "$out" | head -1)"
    assert_eq "$(auth_leaks "$T/log/codex.jsonl" "$dir" "$claude_dir")" "" \
        "CX26 the Codex sign-in file's bytes are in no capture file and no judge prompt"

    make_mutant codex-auth-home 'HOME_SETUP_DIRS = (".ccr", ".pki", ".local/share/pki", ".aws", ".codex")' \
        'HOME_SETUP_DIRS = (".ccr", ".pki", ".local/share/pki", ".aws")'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-auth-mut two-turns clean --hosts codex --sample s-pass --runs 1
    local mut_codex_dir mut_claude_dir
    mut_codex_dir="$(sed -n 's/^[A-Z]* codex s-pass run 1\/1 -> //p' "$T/log/codex-auth-mut.out" | head -1)"
    mut_claude_dir="$(sed -n 's/^[A-Z]* claude-code s-pass run 1\/1 -> //p' "$T/log/codex-auth-mut.out" | head -1)"
    expect_fail "CX27 dropping .codex from the HOME set-up folders fails CX26" \
        auth_clean "$T/log/codex-auth-mut.jsonl" "$mut_codex_dir" "$mut_claude_dir"

    # the model named by AID_CODEX_MODEL reaches the Codex CLI through the model the runner passes it
    AID_CODEX_MODEL=gpt-test-model invoke codex-model two-turns clean --hosts codex --sample s-pass --runs 1
    assert_file_contains "$T/log/codex-model.codex.jsonl" '"--model", "gpt-test-model"' \
        "CX28 the Codex host runs with the model AID_CODEX_MODEL names"

    make_mutant codex-model-arg 'model = ctx["codex_model"] if host == "codex" else ctx["model"]' 'model = ctx["model"]'
    AID_CODEX_MODEL=gpt-test-model INVOKE_RUNNER="$MUT_PATH" invoke codex-model-mut two-turns clean --hosts codex --sample s-pass --runs 1
    expect_fail "CX29 handing Codex the Claude model instead of its own fails CX28" \
        has_text "$T/log/codex-model-mut.codex.jsonl" '"--model", "gpt-test-model"'

    # the 12-user-turn cap, for the Codex host: a stub simulated user that never ends the conversation
    invoke codex-cap never clean --hosts codex --sample s-pass --runs 1
    assert_output_contains "$(sed -n '/^FAIL codex s-pass run/,$p' "$T/log/codex-cap.out")" \
        "conversation: no <<END>> within 12 user turns (turn cap)" "CX30 the Codex host fails at the 12-user-turn cap"
    assert_eq "$(wc -l < "$T/log/codex-cap.codex.jsonl" | tr -d ' ')" 12 "CX31 Codex is called once per turn, 12 times, to the cap"

    make_mutant codex-no-copy 'shutil.copy2(codex_auth, home / ".codex" / "auth.json")' 'pass'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-copy-mut two-turns clean --hosts codex --sample s-pass --runs 1
    expect_fail "CX32 not copying the Codex sign-in file fails CX25" \
        bash -c 'head -1 "$1" | grep -qF -- "\"auth_copied\": true"' _ "$T/log/codex-copy-mut.codex.jsonl"

    make_mutant codex-cap-short 'for turn in range(1, TURN_CAP + 1):' 'for turn in range(1, TURN_CAP):'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-cap-mut never clean --hosts codex --sample s-pass --runs 1
    expect_fail "CX33 ending the turns one short of the cap fails CX31" \
        bash -c '[ "$(wc -l < "$1" | tr -d " ")" = 12 ]' _ "$T/log/codex-cap-mut.codex.jsonl"

    make_mutant codex-cap-msg 'raise RunError(f"no {END_MARK} within {TURN_CAP} user turns (turn cap)")' \
        'raise RunError(f"no {END_MARK} within {TURN_CAP} user turns")'
    INVOKE_RUNNER="$MUT_PATH" invoke codex-cap-msg-mut never clean --hosts codex --sample s-pass --runs 1
    cap_named_in() {  # OUT-FILE: the Codex host's failure reason names the turn cap
        sed -n '/^FAIL codex s-pass run/,$p' "$1" | grep -qF -- "(turn cap)"
    }
    expect_fail "CX34 dropping the turn cap's name from the reason fails CX30" \
        cap_named_in "$T/log/codex-cap-msg-mut.out"

    codex_resume_policy() {
        "$PY" - "$1" <<'PYRESUME'
import importlib.util, json, pathlib, sys, tempfile
spec = importlib.util.spec_from_file_location("resume_runner", sys.argv[1])
runner = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = runner
spec.loader.exec_module(runner)
calls = []
def fake_codex(args, **kwargs):
    calls.append(args)
    pathlib.Path(args[args.index("--output-last-message") + 1]).write_text("reply")
    return json.dumps({"type": "thread.started", "thread_id": "test-thread"})
runner.run_codex = fake_codex
with tempfile.TemporaryDirectory() as folder:
    agent = runner.CodexAgent(pathlib.Path(folder), {"HOME": folder}, "")
    agent.start()
    agent.send("first")
    agent.send("second")
required = ('default_permissions="aid_conversation"', 'approval_policy="on-request"', 'approvals_reviewer="auto_review"',
            'features.apps=false', 'web_search="disabled"', '--ignore-user-config')
print("pass" if calls[1][:3] == ["exec", "resume", "test-thread"]
      and all(all(value in call for value in required) for call in calls)
      and all(any('".git"="write"' in value for value in call) for call in calls)
      and all('--sandbox' not in call and '--approve-for-me' not in call for call in calls) else "fail")
PYRESUME
    }
    assert_eq "$(codex_resume_policy "$RUNNER")" pass "CX35 resumed turns retain the workspace sandbox and automatic review"
    make_mutant codex-resume-policy 'default_permissions="aid_conversation"' 'default_permissions=":read-only"'
    assert_eq "$(codex_resume_policy "$MUT_PATH")" fail "CX36 changing the resumed policy fails CX35"
}

group_evidence() {
    echo "--- EVIDENCE"
    "$PY" - "$RUNNER" <<'PYEVIDENCE'
import json, pathlib, runpy, subprocess, sys, tempfile
r = runpy.run_path(__import__('sys').argv[1])
send_globals = r['CodexAgent'].send.__globals__
with tempfile.TemporaryDirectory() as folder:
    base = pathlib.Path(folder)
    (base/'reviewed_module.py').write_text('value = 1\n')
    subprocess.run([sys.executable,'-c','import reviewed_module'],cwd=base,env=r['base_env'](base),check=True)
    assert not (base/'__pycache__').exists(), 'read-only Python verification created source artifacts'
    def fake(args, **kwargs):
        assert all(value in args for value in ['features.apps=false','web_search="disabled"','--ignore-user-config'])
        pathlib.Path(args[args.index('--output-last-message') + 1]).write_text('Question?')
        return '\n'.join(json.dumps(e) for e in [
            {'type':'thread.started','thread_id':'evidence-thread'},
            {'type':'item.completed','item':{'type':'agent_message','text':'I will record this first.'}},
            {'type':'item.started','item':{'type':'command_execution','id':'c1','command':'git push origin master'}},
            {'type':'item.completed','item':{'type':'command_execution','id':'c1','command':'git push origin master','aggregated_output':'recorded Q1 Pending','exit_code':0}},
            {'type':'item.completed','item':{'type':'agent_message','text':'Question?'}},
        ])
    send_globals['run_codex'] = fake
    a = r['CodexAgent'](base, {'HOME': folder}, '')
    text, tools, _ = a.send('first')
    assert tools == [{'name':'Bash','target':'git push origin master'}], tools
    assert [e['type'] for e in a.events] == ['message','command','command_result','message']
    transcript = [{'turn':1,'role':'agent','text':text,'tools':tools,'events':a.events}]
    rendered = r['render_transcript_md'](transcript)
    assert rendered.index('I will record this first.') < rendered.index('git push') < rendered.index('recorded Q1 Pending') < rendered.index('Final reply:')
    assert rendered.count('Question?') == 1
    early_question = [dict(transcript[0], events=[{'type':'message','text':'Question?'}, *a.events])]
    assert r['render_transcript_md'](early_question).count('Question?') == 2
    hidden = r['render_transcript_md'](transcript, show_events=False)
    assert 'recorded Q1 Pending' not in hidden
    checks = r['run_checks']([{'verb':'no-push','args':[],'label':'no-push'}],base,set(),set(),tools,'codex')
    assert checks[0][1] is False, checks
    temporal = [r['parse_check']('no-new-dir-before-answer .aid/works')]
    # Later work creation is allowed; a nested worktree created before the answer is not.
    later={'.aid/works/work-001'}
    assert r['run_checks'](temporal,base,set(),later,[],'codex',before_answer_dirs=(set(),set()))[0][1] is True
    nested={'.claude/worktrees/work-001-test/.aid/works/work-001'}
    assert r['run_checks'](temporal,base,set(),nested,[],'codex',before_answer_dirs=(set(),nested))[0][1] is False
    assert r['run_checks'](temporal,base,set(),later,[],'codex')[0][1] is False
    a.send('resume with the same isolation')
    def failed(args, **kwargs):
        return json.dumps({'type':'turn.failed','error':{'message':'test failure'}})
    send_globals['run_codex'] = failed
    try: a.send('second')
    except r['RunError']: pass
    else: raise AssertionError('failed agent turn accepted')
    # A clean judge must not erase a conversation failure from the saved verdict.
    g = r['run_once'].__globals__
    project = base/'project';project.mkdir()
    home=base/'home';home.mkdir()
    g['build_fixture'] = lambda *args: (project,home)
    g['capture'] = lambda *args: ({},set())
    g['ref_shas'] = lambda *args: {}
    def capped(*args): raise r['RunError']('turn cap')
    g['run_conversation'] = capped
    g['run_checks'] = lambda *args: []
    g['judge'] = lambda *args: '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|'
    sample=r['Sample'](base/'sample.md','900-evidence',{'fixture':'stub'},{},[])
    ctx={'codex_model':'','model':'','fixtures_dir':base,'bundle':base,'real_home':base,'user_brief':'','judge_brief':'','protocol_checks':'','user_host':'codex','user_model':'','judge_host':'codex','judge_model':''}
    reasons=r['run_once'](sample,1,base/'result',ctx,'codex')
    saved=json.loads((base/'result/result.json').read_text())
    assert reasons == ['conversation: turn cap'], reasons
    assert saved['passed'] is False and saved['reasons'] == reasons
    def interrupted(*args): raise KeyboardInterrupt()
    g['run_conversation'] = interrupted
    try: r['run_once'](sample,2,base/'interrupted',ctx,'codex')
    except KeyboardInterrupt: pass
    else: raise AssertionError('interrupt swallowed')
    interrupted_result=json.loads((base/'interrupted/result.json').read_text())
    assert interrupted_result['passed'] is False
    assert 'KeyboardInterrupt' in interrupted_result['reasons'][0]
    # Gate diagnostics may stop early, but cannot present an incomplete batch as passing.
    g['stage_bundle'] = lambda *args: None
    g['select_samples'] = lambda *args: [base/'sample.md']
    g['load_sample'] = lambda *args: sample
    g['shutil'].which = lambda *args: 'stub'
    g['RUN_ROOT'] = base/'batches'
    (base/'simulated-user.md').write_text('user')
    (base/'judge.md').write_text('judge')
    invoked=[]
    def fail_once(sample,n,run_dir,ctx,host):
        invoked.append(n);run_dir.mkdir(parents=True);return ['known failure']
    g['run_once'] = fail_once
    rc=r['main'](['--feature','900','--hosts','claude-code','--briefs-dir',str(base),'--runs','3','--fail-fast'])
    assert rc == 1 and invoked == [1]
    batch=json.loads(next((base/'batches').glob('*/summary.json')).read_text())
    assert batch['completed'] is False and batch['passed'] is False and batch['stopped_early'] is True
    assert batch['runs_per_sample'] == 3 and len(batch['results']) == 1
print('Ordered messages, deduplicated commands, no-push detection, failed-turn handling and exact saved verdict verified.')
PYEVIDENCE
    assert_exit_eq "$?" 0 "EV01 ordered Codex evidence and failed conversation verdicts are preserved"
}

group_raw() {
    echo "--- RAW (offline main-agent evidence and artifact parity; no release staging)"
    "$PY" - "$RUNNER" <<'PYRAW'
import importlib.util, json, pathlib, sys, tempfile

spec=importlib.util.spec_from_file_location('raw_runner',sys.argv[1])
r=importlib.util.module_from_spec(spec);sys.modules[spec.name]=r;spec.loader.exec_module(r)
real_agent=r.CodexAgent
real_conversation=r.run_conversation
ledger='| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|'
streams=[]
for turn in (1,2):
    events=[{'type':'thread.started','thread_id':'raw-thread'},
            {'type':'future.outer.event','marker':'RAW-ONLY caf\u00e9 \u03a9','turn':turn},
            {'type':'item.completed','item':{'type':'future_tool_call','id':'unknown','marker':'UNKNOWN-ITEM','arguments':{'text':'preserve me'}}},
            {'type':'item.started','item':{'type':'command_execution','id':'c1','command':'echo observed'}},
            {'type':'item.completed','item':{'type':'command_execution','id':'c1','command':'echo observed','aggregated_output':'normal-prefix\n'+'L'*18000+'\nLONG-TAIL','exit_code':0}},
            {'type':'item.completed','item':{'type':'agent_message','text':f'Reply {turn}.'}}]
    streams.append('\r\n'.join(json.dumps(event,ensure_ascii=False) for event in events)+'\r\n\n')

class WithoutRaw(real_agent):
    def __init__(self,fixture,env,model,fixture_name='',raw_dir=None):
        super().__init__(fixture,env,model,fixture_name)

with tempfile.TemporaryDirectory() as folder:
    base=pathlib.Path(folder)
    r.now=lambda: 'fixed-time'
    def build(sample,fixtures,bundle,real_home,work,host):
        fixture=work/'project';home=work/'home'
        fixture.mkdir();home.mkdir()
        return fixture,home
    r.build_fixture=build
    sample=r.Sample(base/'sample.md','900-raw',{'fixture':'stub'},
                    {'User':'Read the fixture.','Answer sheet':'Continue once.','Expected outcome':'Reply.','Must not':'Push.'},
                    [r.parse_check('no-push')])
    ctx={'codex_model':'','model':'','fixtures_dir':base,'bundle':base,'real_home':base,
         'user_brief':'user','judge_brief':'judge','protocol_checks':'','user_host':'codex','user_model':'','judge_host':'codex','judge_model':''}
    def exercise(name,agent_class=real_agent,scenario='normal'):
        calls=[];helpers=[];judge_inputs=[];returned=[]
        r.CodexAgent=agent_class
        def fake(args,**kwargs):
            calls.append((list(args),kwargs['cwd']))
            if scenario=='cli-error':raise r.RunError('CLI nonzero: no stdout returned')
            index=len(calls)-1
            pathlib.Path(args[args.index('--output-last-message')+1]).write_text(f'Reply {index+1}.',encoding='utf-8')
            (kwargs['cwd']/'changed.txt').write_text('agent wrote this\n',encoding='utf-8')
            out=streams[index]
            if scenario=='turn-failed':out+=json.dumps({'type':'turn.failed','error':{'message':'failed turn'}})+'\n'
            returned.append(out)
            return out
        def helper(prompt,*args,**kwargs):
            helpers.append(prompt)
            assert 'RAW-ONLY' not in prompt and 'UNKNOWN-ITEM' not in prompt and 'LONG-TAIL' not in prompt
            return 'Continue.' if len(helpers)==1 else r.END_MARK
        def judge(*args):
            judge_inputs.append(args[3:6])
            assert all('RAW-ONLY' not in value and 'UNKNOWN-ITEM' not in value and 'LONG-TAIL' not in value for value in args[3:6])
            return ledger
        r.run_codex=fake;r.helper_call=helper;r.judge=judge
        r.run_conversation=real_conversation
        if scenario=='interrupt':
            def interrupted(agent,*args):
                agent.start();agent.send('first');raise KeyboardInterrupt()
            r.run_conversation=interrupted
        dest=base/name
        if scenario=='persist-error':
            dest.mkdir();(dest/'codex-raw').write_text('blocked by a file',encoding='utf-8')
        try:
            reasons=r.run_once(sample,1,dest,ctx,'codex')
        except KeyboardInterrupt:
            assert scenario=='interrupt'
            reasons=json.loads((dest/'result.json').read_text())['reasons']
        else:
            assert scenario!='interrupt','interrupt was swallowed'
        assert all(not fixture.exists() for _,fixture in calls),'disposable fixture retained'
        return dest,calls,helpers,judge_inputs,returned,reasons

    control=exercise('control',WithoutRaw)
    observed=exercise('observed')
    dest,calls,helpers,judges,returned,reasons=observed
    assert reasons==[] and control[-1]==[],(reasons,control[-1])
    raw_files=sorted((dest/'codex-raw').glob('*'))
    assert [p.name for p in raw_files]==['turn-001.jsonl','turn-002.jsonl']
    assert [p.read_bytes() for p in raw_files]==[text.encode('utf-8') for text in streams]
    assert all(not p.is_relative_to(fixture) for p in raw_files for _,fixture in calls)
    assert len(calls)==2 and calls[1][0][:3]==['exec','resume','raw-thread']
    for name in ('transcript.jsonl','transcript.md','files.diff','checks.txt','ledger.md'):
        assert (control[0]/name).read_bytes()==(dest/name).read_bytes(),name+' changed when raw capture was enabled'
    assert control[2:4]==observed[2:4],'judge or simulated-user input changed'
    def comparable(args):
        result=list(args);result[result.index('--output-last-message')+1]='<temporary-message-file>'
        return result
    assert [comparable(args) for args,_ in control[1]]==[comparable(args) for args,_ in calls],'CLI configuration changed'
    assert not (control[0]/'codex-raw').exists()
    assert 'characters omitted' in (dest/'transcript.jsonl').read_text()
    assert b'LONG-TAIL' in raw_files[0].read_bytes() and b'UNKNOWN-ITEM' in raw_files[0].read_bytes()

    failed=exercise('failed',scenario='turn-failed')
    assert (failed[0]/'codex-raw/turn-001.jsonl').read_bytes()==failed[4][0].encode('utf-8')
    assert 'turn.failed' in failed[4][0] and any('failed turn' in reason for reason in failed[-1])
    assert json.loads((failed[0]/'result.json').read_text())['passed'] is False
    assert not (failed[0]/'codex-raw/turn-002.jsonl').exists()
    interrupted=exercise('interrupted',scenario='interrupt')
    assert (interrupted[0]/'codex-raw/turn-001.jsonl').read_bytes()==streams[0].encode('utf-8')
    assert 'KeyboardInterrupt' in interrupted[-1][0]
    assert json.loads((interrupted[0]/'result.json').read_text())['passed'] is False
    blocked=exercise('blocked',scenario='persist-error')
    assert any('codex raw stdout could not be saved at' in reason and 'turn-001.jsonl' in reason for reason in blocked[-1])
    assert json.loads((blocked[0]/'result.json').read_text())['passed'] is False
    assert len(blocked[1])==1 and blocked[2]==[],'raw persistence failure continued the conversation'
    no_stdout=exercise('no-stdout',scenario='cli-error')
    assert any('no stdout returned' in reason for reason in no_stdout[-1])
    assert not (no_stdout[0]/'codex-raw').exists(),'raw output fabricated for a CLI call that returned none'
    assert json.loads((no_stdout[0]/'result.json').read_text())['passed'] is False
print('Verbatim raw start/resume streams, unknown events, pre-parse failure retention, artifact/input parity, interruptions and persistence errors verified.')
PYRAW
    assert_exit_eq "$?" 0 "RW01 passive raw Codex evidence preserves existing behavior and honest failures"
}

group_mcp() {
    echo "--- MCP (one stdio subprocess per protocol input; no model or release staging)"
    "$PY" - "$RUNNER" <<'PYMCP'
import ast, importlib.util, json, pathlib, subprocess, sys, tempfile, tomllib

runner_path = pathlib.Path(sys.argv[1])
def load_runner(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module

r = load_runner(runner_path, 'mcp_runner')
server_path = r.ROOT / 'tests/conversation/support/tracker_mcp.py'
imports = {node.module for node in ast.walk(ast.parse(server_path.read_text())) if isinstance(node, ast.ImportFrom)}
imports |= {alias.name for node in ast.walk(ast.parse(server_path.read_text())) if isinstance(node, ast.Import) for alias in node.names}
assert imports == {'__future__', 'json', 're', 'sys'}, imports

def request(n, method, params=None):
    result = {'jsonrpc':'2.0', 'id':n, 'method':method}
    if params is not None: result['params'] = params
    return result

with tempfile.TemporaryDirectory() as folder:
    base = pathlib.Path(folder)
    for version in ('2025-11-25', '2024-11-05', 'future-version'):
        inputs = [request(1,'tools/list'),
                  request(2,'initialize',{'protocolVersion':version,'capabilities':{},'clientInfo':{'name':'offline-test','version':'1'}}),
                  {'jsonrpc':'2.0','method':'notifications/initialized'}, request(3,'ping'), request(4,'tools/list'),
                  request(5,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42'}}),
                  request(6,'tools/call',{'name':'linear_read_ticket','arguments':{'ticket_id':'LIN-7'}}),
                  request(7,'tools/call',{'name':'write_ticket','arguments':{'ticket_id':'PROJ-42'}}),
                  request(8,'tools/call',{'name':'jira_read_ticket','arguments':{}}),
                  request(9,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42','path':'/tmp'}}),
                  request(10,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'../../secret'}}),
                  request(11,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':42}}),
                  request(12,'tools/call',{'name':[],'arguments':{}}),
                  request(13,'tools/call',[]), request(14,'resources/read',{'uri':'file:///tmp'}),
                  request(15,'tools/list',{'cursor':'unexpected'}),
                  request(16,'tools/list',{'_meta':{}}),
                  request(17,'tools/list',{'_meta':{'progressToken':'list-17','test/client':{'trace':'opaque'}}}),
                  request(18,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42'},'_meta':{'progressToken':'read-18'}}),
                  request(19,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42'},'_meta':{'progressToken':0}}),
                  request(20,'tools/list',{'_meta':[]}),
                  request(21,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42'},'_meta':None}),
                  request(22,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42'},'_meta':{'progressToken':True}}),
                  request(23,'tools/list',{'_meta':{'progressToken':{}}}),
                  request(24,'tools/list',{'_meta':{'progressToken':None}}),
                  request(25,'tools/list',{'_meta':{'progressToken':1.5}}),
                  request(26,'tools/list',{'_meta':'not-an-object'}),
                  request(27,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42'},'_meta':{},'path':'/tmp'}),
                  request(28,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42','_meta':{}},'_meta':{}}),
                  request(29,'tools/list',{'_meta':{},'cursor':'unexpected'}),
                  request(30,'tools/call',{'name':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42'},'_meta':{'progressToken':1.0}}),
                  '{"jsonrpc":"2.0","id":31,"method":"tools/call","params":{"name":"jira_read_ticket","arguments":{"ticket_id":"PROJ-42"},"_meta":{"progressToken":2e3}}}',
                  '{"jsonrpc":"2.0","id":32,"method":"tools/list","params":{"_meta":{"progressToken":1e309}}}',
                  {'jsonrpc':'2.0','method':'unknown-notification'}, [], request([], 'tools/list')]
        payload = '\n'.join(row if isinstance(row,str) else json.dumps(row) for row in inputs) + '\n{broken-json\n'
        proc = subprocess.run([sys.executable,str(server_path)],input=payload,cwd=base,
                              capture_output=True,text=True,timeout=10)
        assert proc.returncode == 0 and proc.stderr == '', (proc.returncode,proc.stderr)
        responses = [json.loads(line) for line in proc.stdout.splitlines()]
        assert all(row['jsonrpc'] == '2.0' for row in responses)
        numbered = {row['id']:row for row in responses if row['id'] is not None}
        assert len(responses) == 35 and len(numbered) == 32, responses
        assert numbered[1]['error']['code'] == -32600
        assert numbered[2]['result']['protocolVersion'] == ('2025-11-25' if version == 'future-version' else version)
        assert numbered[2]['result']['capabilities'] == {'tools':{}}
        assert numbered[3]['result'] == {}
        tools = numbered[4]['result']['tools']
        assert {tool['name'] for tool in tools} == {'jira_read_ticket','linear_read_ticket'}
        for tool in tools:
            assert tool['description'].endswith('(isolated test tracker).')
            assert 'unavailable' not in json.dumps(tool).lower()
            assert tool['annotations'] == {'readOnlyHint':True,'destructiveHint':False,'idempotentHint':True,'openWorldHint':False}
            assert tool['inputSchema']['required'] == ['ticket_id']
            assert set(tool['inputSchema']['properties']) == {'ticket_id'}
            assert tool['inputSchema']['additionalProperties'] is False
        jira_error = numbered[5]['result']
        assert jira_error == {'content':[{'type':'text','text':'Jira is unavailable. Ticket PROJ-42 could not be read.'}],'isError':True}
        assert numbered[6]['result']['isError'] is True
        assert numbered[6]['result']['content'][0]['text'] == 'Linear is unavailable. Ticket LIN-7 could not be read.'
        assert all(numbered[n]['error']['code'] == -32602 for n in (*range(7,14),15))
        assert numbered[14]['error']['code'] == -32601
        assert numbered[16]['result']['tools'] == tools and numbered[17]['result']['tools'] == tools
        assert numbered[18]['result'] == jira_error and numbered[19]['result'] == jira_error
        assert numbered[30]['result'] == jira_error and numbered[31]['result'] == jira_error
        assert numbered[32]['error']['code'] == -32602
        assert all(numbered[n]['error']['code'] == -32602 for n in range(20,30))
        assert [row['error']['code'] for row in responses[-3:]] == [-32600,-32600,-32700]
        assert list(base.iterdir()) == [], 'fixture provider wrote state'

    def exercise_scope(module):
        calls = []
        def fake(args, **kwargs):
            calls.append(args)
            if '--output-last-message' not in args:
                return json.dumps({'type':'assistant','session_id':'claude-thread','message':{'content':[{'type':'text','text':'final-only'}]}})
            pathlib.Path(args[args.index('--output-last-message')+1]).write_text('final-only')
            return json.dumps({'type':'thread.started','thread_id':'mcp-thread'})
        module.run_codex = fake
        module.run_claude = fake
        def fixture(sample, fixtures, bundle, real_home, work, host):
            project=work/'project'; home=work/'home'
            project.mkdir(); home.mkdir()
            return project,home
        module.build_fixture = fixture
        module.capture = lambda *args: ({},set())
        module.ref_shas = lambda *args: {}
        def conversation(agent, *args):
            agent.start(); agent.send('first'); agent.send('resume')
        module.run_conversation = conversation
        module.judge = lambda *args: '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|'
        ctx={'codex_model':'','model':'','fixtures_dir':base,'bundle':base,'real_home':base,'user_brief':'','judge_brief':'','protocol_checks':'','user_host':'codex','user_model':'','judge_host':'codex','judge_model':''}
        for host, fixture_name in [('codex','two-trackers'),('codex','stub'),('claude-code','two-trackers')]:
            sample=module.Sample(base/'sample.md','900-mcp',{'fixture':fixture_name},{},[])
            before=len(calls)
            assert module.run_once(sample,1,base/(module.__name__+host+fixture_name),ctx,host) == []
            turns=calls[before:]
            assert len(turns)==2
            if host=='codex': assert turns[1][:3] == ['exec','resume','mcp-thread']
            for args in turns:
                overrides=[value for value in args if value.startswith('mcp_servers=')]
                if host=='codex' and fixture_name=='two-trackers':
                    assert len(overrides)==1, args
                    config=tomllib.loads(overrides[0])['mcp_servers']
                    assert config == {'aid_test_trackers':{'command':sys.executable,'args':[str(server_path)]}},config
                else: assert not overrides,args
        for host in ('codex','claude-code'):
            module.helper_call('prompt','brief',cwd=base,env={'HOME':str(base)},host=host)
            assert not any(value.startswith('mcp_servers=') for value in calls[-1])
            if host=='codex': assert '--ignore-user-config' in calls[-1] and 'features.apps=false' in calls[-1]
    exercise_scope(r)
    # An absence check must fail if the scope guard is broadened to every fixture.
    mutant_source = runner_path.read_text().replace('if fixture_name == "two-trackers" else {}','if True else {}')
    assert mutant_source != runner_path.read_text()
    mutant_path=base/'scope-mutant.py'; mutant_path.write_text(mutant_source)
    mutant=load_runner(mutant_path,'mcp_scope_mutant'); mutant.ROOT=r.ROOT
    try: exercise_scope(mutant)
    except AssertionError: pass
    else: raise AssertionError('fixture-scope negative control accepted an always-on provider')

    def fake_events(args, **kwargs):
        pathlib.Path(args[args.index('--output-last-message')+1]).write_text('Final reply text')
        item={'type':'mcp_tool_call','id':'m1','server':'aid_test_trackers','tool':'jira_read_ticket','arguments':{'ticket_id':'PROJ-42'}}
        completed=dict(item,status='completed',result=jira_error,error=None)
        return '\n'.join(json.dumps(event) for event in [
            {'type':'thread.started','thread_id':'ordered'},
            {'type':'item.completed','item':{'type':'agent_message','text':'Before read'}},
            {'type':'item.started','item':item}, {'type':'item.started','item':item},
            {'type':'item.completed','item':{'type':'command_execution','id':'c1','command':'echo observed','aggregated_output':'command output','exit_code':0}},
            {'type':'item.completed','item':completed}, {'type':'item.completed','item':completed},
            {'type':'item.completed','item':{'type':'mcp_tool_call','id':'m2','server':'aid_test_trackers','tool':'linear_read_ticket','arguments':{'ticket_id':'LIN-7'},'status':'failed','result':None,'error':{'message':'transport unavailable'}}},
            {'type':'item.completed','item':{'type':'agent_message','text':'Final reply text'}}])
    r.run_codex=fake_events
    agent=r.CodexAgent(base,{'HOME':str(base)},'','two-trackers')
    text,tools,withdrawn=agent.send('read')
    assert [e['type'] for e in agent.events] == ['message','mcp_call','command','command_result','mcp_result','mcp_call','mcp_result','message']
    assert [tool['name'] for tool in tools] == ['mcp__aid_test_trackers__jira_read_ticket','Bash','mcp__aid_test_trackers__linear_read_ticket']
    assert json.loads(tools[0]['target']) == {'ticket_id':'PROJ-42'}
    assert agent.events[4]['result'] == jira_error and agent.events[6]['error'] == {'message':'transport unavailable'}
    transcript=[{'role':'agent','turn':1,'text':text,'tools':tools,'events':agent.events}]
    rendered=r.render_transcript_md(transcript)
    markers=['Before read','MCP call: mcp__aid_test_trackers__jira_read_ticket','Command:', 'command output','MCP result: mcp__aid_test_trackers__jira_read_ticket','Jira is unavailable.','MCP call: mcp__aid_test_trackers__linear_read_ticket','transport unavailable','Final reply:']
    assert [rendered.index(m) for m in markers] == sorted(rendered.index(m) for m in markers)
    assert rendered.count('MCP call: mcp__aid_test_trackers__jira_read_ticket') == 1
    assert rendered.count('MCP result: mcp__aid_test_trackers__jira_read_ticket') == 1
    assert r.render_transcript_md(transcript,show_events=False).strip().endswith('Final reply text')
    assert 'PROJ-42' not in r.render_transcript_md(transcript,show_events=False)
    checks=[r.parse_check('tool-called Skill aid-read-ticket'),r.parse_check('tool-called Edit *'),r.parse_check('tool-called Write *')]
    assert all(result[1] is None for result in r.run_checks(checks,base,set(),set(),tools,'codex'))
    # A helper remains tool-free even if its CLI unexpectedly emits an MCP call.
    try: r.helper_call('prompt','brief',cwd=base,env={'HOME':str(base)},host='codex')
    except r.RunError as exc: assert 'attempted tool use: mcp_tool_call' in str(exc)
    else: raise AssertionError('helper accepted an MCP tool event')
    # A missing provider yields no observed read: a text-only reply cannot manufacture evidence.
    def no_provider(args, **kwargs):
        pathlib.Path(args[args.index('--output-last-message')+1]).write_text('No tracker is available')
        return json.dumps({'type':'thread.started','thread_id':'no-provider'})
    r.run_codex=no_provider
    unconnected=r.CodexAgent(base,{'HOME':str(base)},'')
    missing_text,missing_tools,_=unconnected.send('read')
    assert not unconnected.fixture_mcp and missing_tools == [] and unconnected.events == []
    missing_view=r.render_transcript_md([{'role':'agent','turn':1,'text':missing_text,'tools':missing_tools,'events':unconnected.events}])
    assert 'MCP call:' not in missing_view and 'MCP result:' not in missing_view
print('Real stdio negotiation/read errors, closed tool set, main-agent fixture scope, helper absence and ordered MCP lifecycle verified.')
PYMCP
    assert_exit_eq "$?" 0 "MC01 closed fixture MCP scope and ordered evidence are preserved"
}

want EVIDENCE && group_evidence
want RAW && group_raw
want MCP && group_mcp
want EXIT && group_exit
want VALIDATE && group_validate
want CAPTURE && group_capture
want FLAGS && group_flags
want DIFF && group_diff
want JUDGE && group_judge
want ENV && group_env
want END && group_end
want BRIEFS && group_briefs
want CHECKS && group_checks
want CLEAN && group_clean
want LEDGER && group_ledger
want SAMPLES && group_samples
want VSAMPLES && group_vsamples
want CAP && group_cap
want CODEX && group_codex
want HELPERS && group_helpers
want PROTO && group_protocol
want HOOK && group_hook

test_summary
exit $?
