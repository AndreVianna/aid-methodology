#!/usr/bin/env bash
# test-conversation-runner.sh -- guards tests/conversation/run.py, the conversation test runner (NFR-T).
#
# run.py drives the agent under test through scripted sample conversations, captures each run and
# has a judge rule on it. Nothing here calls a real model. A stub `claude` is put first on PATH; it
# logs every call and answers in the shape run.py reads (stream-json for an agent turn, plain text
# for the simulated user and the judge). The suite builds its own tree (samples/feature-900,
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
#   EXIT VALIDATE CAPTURE FLAGS DIFF JUDGE ENV END BRIEFS CHECKS CLEAN LEDGER SAMPLES VSAMPLES CAP
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
ALL_GROUPS="EXIT VALIDATE CAPTURE FLAGS DIFF JUDGE ENV END BRIEFS CHECKS CLEAN LEDGER SAMPLES VSAMPLES CAP"
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

# --- the stub claude ----------------------------------------------------------
cat > "$BIN/claude" <<'PYSTUB'
#!/usr/bin/env python3
# Stub claude for test-conversation-runner.sh. Logs each call to $CONV_STUB_LOG, then answers:
# an agent turn (stream-json) with a session, tool calls and writes on turn 1; the simulated user
# (plain text) per $STUB_USER; the judge (plain text) per $STUB_JUDGE.
import json
import os
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
                  if k.startswith(("CLAUDE", "CCR_", "SESSION_INGRESS", "HTTPS_PROXY", "NODE_EXTRA_CA_CERTS"))}}
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
        if os.environ.get("STUB_PUSH") == "1":  # the agent pushes, so no-push must fail
            content.append({"type": "tool_use", "id": "t4", "name": "Bash",
                            "input": {"command": "git push origin main"}})
        review_dir = os.environ.get("CONV_STUB_REVIEW_DIR", "")
        if review_dir:  # the fixture's review-pending folder points at a folder the suite can read
            os.makedirs(review_dir, exist_ok=True)
            os.makedirs(os.path.join(".aid", ".temp"), exist_ok=True)
            os.symlink(review_dir, os.path.join(".aid", ".temp", "review-pending"))
    lines = [
        {"type": "system", "subtype": "init", "session_id": session},
        {"type": "assistant", "session_id": session, "message": {"content": content}},
        {"type": "result", "subtype": "success", "session_id": session, "result": "Reply."},
    ]
    print("\n".join(json.dumps(item) for item in lines))
elif role == "user":
    mode = os.environ.get("STUB_USER", "end-after-one")
    if mode == "never":
        out = "Keep going."
    elif mode == "two-turns":
        out = "Second message from the persona." if count == 1 else "<<END>>"
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
printf '# Stub fixture\n' > "$T/fixtures/stub/README.md"
printf 'print("stub")\n' > "$T/fixtures/stub/src/app.py"
printf 'USER-BRIEF-MARK\nStand-in simulated-user brief for the suite.\n' > "$T/briefs/simulated-user.md"
printf 'JUDGE-BRIEF-MARK\nStand-in judge brief for the suite.\n' > "$T/briefs/judge.md"

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
    env STUB_USER="$user" STUB_JUDGE="$judge" STUB_PUSH="${STUB_PUSH:-0}" STUB_WORKTREE="${STUB_WORKTREE:-0}" \
        STUB_BIG="${STUB_BIG:-0}" CONV_STUB_LOG="$T/log/$key.jsonl" \
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
need_grammar() { STUB_PUSH=1 need grammar invoke grammar two-turns clean --sample s-grammar-fail --runs 1; }
need_flaky()   { need flaky invoke flaky end-after-one flaky --sample s-pass --runs 3; }
need_clean3()  { need clean3 invoke clean3 end-after-one clean --sample s-pass --runs 3; }
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
        'HOME_SETUP_DIRS = (".ccr", ".pki", ".local/share/pki", ".aws")' 'HOME_SETUP_DIRS = ()' \
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

test_summary
exit $?
