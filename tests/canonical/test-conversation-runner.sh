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
#   EXIT VALIDATE CAPTURE FLAGS DIFF CHECKS CLEAN LEDGER SAMPLES CAP
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
ALL_GROUPS="EXIT VALIDATE CAPTURE FLAGS DIFF CHECKS CLEAN LEDGER SAMPLES CAP"
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

cleanup() {
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
export PATH="$BIN:$PATH"

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
          "prompt": prompt, "reviewer": reviewer}
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
                          ("stub-token.txt", "secret\n"), ("notes.txt", "a note\n"),
                          ("deploy.pem", "-----stub-----\n"), ("server.key", "stub key\n")):
            with open(os.path.join(home, rel), "w", encoding="utf-8") as fh:
                fh.write(text)
        os.makedirs("scratch", exist_ok=True)  # a new directory, for the no-new-dir checks
        with open(os.path.join("scratch", "notes.txt"), "w", encoding="utf-8") as fh:
            fh.write("scratch\n")
        with open("logo.bin", "wb") as fh:  # a binary file: NUL bytes, four of them
            fh.write(b"\x00\x01\x02\x03")
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


with open(judge_prompt_out, "w", encoding="utf-8") as fh:
    fh.write(judges[0]["prompt"] if judges else "")


print(f"agent_calls={len(agents)}")
print(f"user_calls={len(users)}")
print(f"judge_calls={len(judges)}")
print("agent_flags_ok=" + flag(bool(agents) and all(
    c["argv"] == AGENT + (["--resume", "stub-session-1"] if i else []) for i, c in enumerate(agents))))
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

# --- runs: one run.py call each, memoised by key so groups share them ----------
invoke() {  # KEY USER-MODE JUDGE-MODE run.py-args...   (STUB_PUSH=1 in the caller makes the agent push)
    local key="$1" user="$2" judge="$3"
    shift 3
    env STUB_USER="$user" STUB_JUDGE="$judge" STUB_PUSH="${STUB_PUSH:-0}" CONV_STUB_LOG="$T/log/$key.jsonl" \
        CONV_STUB_REVIEW_DIR="$T/review-copy/$key" \
        "$PY" "$RUNNER" --feature 900 --samples-dir "$T/samples" --fixtures-dir "$T/fixtures" \
        --briefs-dir "$T/briefs" "$@" > "$T/log/$key.out" 2>&1 < /dev/null &
    local pid=$!
    echo "$pid" >> "$T/log/run-pids"
    wait "$pid"
    echo $? > "$T/log/$key.rc"
    "$PY" "$T/facts.py" "$T/log/$key.jsonl" "$T/briefs/simulated-user.md" "$T/briefs/judge.md" \
        "$T/log/$key.judge-prompt" > "$T/log/$key.facts" 2>&1
}
need_pass()    { [ -f "$T/log/pass.rc" ]    || invoke pass    two-turns clean   --sample s-pass --runs 1; }
need_checks()  { [ -f "$T/log/checks.rc" ]  || invoke checks  two-turns clean   --sample s-checks-fail --runs 1; }
need_grammar() { [ -f "$T/log/grammar.rc" ] || STUB_PUSH=1 invoke grammar two-turns clean --sample s-grammar-fail --runs 1; }
need_pending() { [ -f "$T/log/pending.rc" ] || invoke pending end-after-one pending --sample s-pass --runs 1; }
need_notable() { [ -f "$T/log/notable.rc" ] || invoke notable end-after-one no-table --sample s-pass --runs 1; }
need_flaky()   { [ -f "$T/log/flaky.rc" ]   || invoke flaky   end-after-one flaky   --sample s-pass --runs 3; }
need_clean3()  { [ -f "$T/log/clean3.rc" ]  || invoke clean3  end-after-one clean   --sample s-pass --runs 3; }
need_cap()     { [ -f "$T/log/cap.rc" ]     || invoke cap     never         clean   --sample s-pass --runs 1; }

fact() { grep -m1 "^$2=" "$1" | cut -d= -f2-; }
run_dir_of() { sed -n "s/^$2 claude-code $3 run $4\/[0-9]* -> //p" "$1" | head -1; }

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
}

# ---------------------------------------------------------------- FLAGS
group_flags() {
    echo "--- FLAGS"
    need_pass
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
    local diff
    diff="$(run_dir_of "$T/log/pass.out" PASS s-pass 1)/files.diff"
    assert_file_contains "$diff" "b/fixture/changed.txt" "DF01 a change inside the fixture is recorded"
    assert_file_contains "$diff" "+hello from the stub" "DF02 the recorded change carries its content"
    assert_file_contains "$diff" "b/home/notes.txt" "DF03 a change inside the throwaway HOME is recorded"
    assert_file_not_contains "$diff" ".git/stub-marker" "DF04 the fixture's .git/ is excluded"
    assert_file_not_contains "$diff" "home/.claude/state.json" "DF05 the host tool's .claude/ in HOME is excluded"
    assert_file_not_contains "$diff" "home/.claude.json" "DF06 .claude.json in HOME is excluded"
    assert_file_not_contains "$diff" "stub-token.txt" "DF07 a credential-named file in HOME is excluded"
    assert_file_contains "$diff" "Binary file fixture/logo.bin added (4 bytes)" \
        "DF08 a binary file is recorded by path and size only"
    assert_file_not_contains "$diff" "b/fixture/logo.bin" "DF09 a binary file carries no content diff"
    assert_file_not_contains "$diff" "deploy.pem" "DF10 a .pem credential in HOME is excluded"
    assert_file_not_contains "$diff" "server.key" "DF11 a .key credential in HOME is excluded"
}

# ---------------------------------------------------------------- CHECKS
group_checks() {
    echo "--- CHECKS"
    need_pass
    need_checks
    need_grammar
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
}

# ---------------------------------------------------------------- CLEAN
group_clean() {
    echo "--- CLEAN"
    need_pass
    need_checks
    local left
    left="$(ls -A "$T/tmp" 2>/dev/null | grep -c '^aid-conv-' || true)"
    assert_eq "$left" 0 "CL01 no aid-conv-* work folder is left in TMPDIR after the runs"
}

# ---------------------------------------------------------------- LEDGER
group_ledger() {
    echo "--- LEDGER"
    need_pass
    need_pending
    need_notable
    assert_file_contains "$(run_dir_of "$T/log/pass.out" PASS s-pass 1)/ledger.md" "| # | Severity | Status" \
        "LG01 a clean ledger (no Pending row) passes the run"
    assert_exit_eq "$(cat "$T/log/pending.rc")" 1 "LG02 a Pending ledger row fails the run"
    assert_output_contains "$(cat "$T/log/pending.out")" "judge: 1 Pending row(s) in the ledger" \
        "LG03 the Pending row is named as the reason"
    assert_exit_eq "$(cat "$T/log/notable.rc")" 1 "LG04 a judge reply with no ledger table fails the run"
    assert_output_contains "$(cat "$T/log/notable.out")" "judge: no 7-column ledger table in the output" \
        "LG05 the missing table is named as the reason"
}

# ---------------------------------------------------------------- SAMPLES
group_samples() {
    echo "--- SAMPLES"
    need_clean3
    need_flaky
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

# ---------------------------------------------------------------- CAP
group_cap() {
    echo "--- CAP"
    need_cap
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
want CHECKS && group_checks
want CLEAN && group_clean
want LEDGER && group_ledger
want SAMPLES && group_samples
want CAP && group_cap

test_summary
exit $?
