#!/usr/bin/env bash
# test-question-form-hook.sh -- Unit tests for the AID question-form Stop hook
# (canonical/aid/scripts/hooks/aid-question-form.sh and aid-question-form.py).
#
# COVERS: canonical/aid/scripts/hooks/
#
# Builds its own stdin events, transcripts and project folders in a temp dir; it reads no
# work folder and never touches the real project's .aid state (CLAUDE_PROJECT_DIR is pinned
# to the temp project for every run).
#
# Cases:
#   QF-25 a go-ahead (Shall I / May I / Do you approve ...) with the skip closing line blocks
#   QF-01 formed and recorded passes        QF-02..05 each of F1..F4 missing blocks, naming it
#   QF-06 no --ask blocks, names the record QF-07 --ask --design and --project --ask pass
#   QF-08 --ask in an earlier turn blocks   QF-09 a report with no question passes
#   QF-10 stop_hook_active passes           QF-11 break offer passes
#   QF-12 Recovery / Cancel work waived     QF-13 re-offer of an open entry (same text)
#   QF-14 KB state edit passes              QF-15 ticket skill most recent passes
#   QF-16 '?' only inside a fence passes    QF-17 bad stdin / no transcript / no Python
#   QF-18 kill switch                       QF-19 transcript fallback for the message
#   QF-20 log line on a block only          QF-21 block output is one JSON object, exit 0
#   QF-22 waits without a '?' (offers, "tell me", lead-in + list) blocks; a done-list report passes
#   QF-23 R3 needs the same question: the category alone never satisfies the record
#   QF-22n..r "I need one of these:" + a list waits; "I needed to ..." / "I need to <step>:" does not
#   QF-24 a break offer anywhere in the last three paragraphs passes; with a form question it is checked
#   QF-26 R1 needs the --ask --context to be the question shown (double, single, $'..' quotes; unreadable passes)
#   QF-27 a question shown in the form inside a code fence is still checked (the protocol's own example is fenced)
#   QF-28 the block reason keeps the repeat line and never invites dropping a required question or a break offer
#   QF-29 a question naming an internal identifier blocks when every user message is in plain words
#         (not for waived confirmations, ticket skills or a link target; no close without a record)
#   QF-30 an --ask this turn that duplicates an older open entry of the same question blocks
#
# Usage:
#   HOME="$(mktemp -d)" bash test-question-form-hook.sh [-v|--verbose]
# Exit: 0 all passed; 1 any failed.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DIR="${SCRIPT_DIR}/../../canonical/aid/scripts/hooks"
LAUNCHER="${HOOK_DIR}/aid-question-form.sh"
CHECKER="${HOOK_DIR}/aid-question-form.py"
[[ -f "$LAUNCHER" && -f "$CHECKER" ]] || { echo "ERROR: hook scripts not found in $HOOK_DIR" >&2; exit 1; }
PY="$(command -v python3 || command -v python)"
[[ -n "$PY" ]] || { echo "ERROR: python3 not found" >&2; exit 1; }
BASH_BIN="$(command -v bash)"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
PROJ="$TMP/proj"
mkdir -p "$PROJ/.aid"

# --- fixture builder: transcripts and stop events -----------------------------------------
cat > "$TMP/mk.py" <<'PYEOF'
import json, sys

def entry(role, blocks, **extra):
    e = {"type": role, "message": {"role": role, "content": blocks}}
    e.update(extra)
    return e

def transcript(path, pairs):
    out = []
    n = 0
    for kind, arg in pairs:
        n += 1
        if kind == "user":
            out.append(entry("user", [{"type": "text", "text": arg}]))
        elif kind == "meta":
            out.append(entry("user", [{"type": "text", "text": arg}], isMeta=True))
        elif kind == "text":
            out.append(entry("assistant", [{"type": "text", "text": arg}]))
        elif kind == "side":
            out.append(entry("assistant", [{"type": "tool_use", "id": "t%d" % n, "name": "Bash",
                                            "input": {"command": arg}}], isSidechain=True))
        else:
            name, inp = {
                "bash": ("Bash", {"command": arg}),
                "edit": ("Edit", {"file_path": arg}),
                "skill": ("Skill", {"skill": arg}),
            }[kind]
            out.append(entry("assistant", [{"type": "tool_use", "id": "t%d" % n, "name": name, "input": inp}]))
            out.append(entry("user", [{"type": "tool_result", "tool_use_id": "t%d" % n, "content": "ok"}]))
    with open(path, "w") as fh:
        for e in out:
            fh.write(json.dumps(e) + "\n")

def event(path, tpath, message, active, cwd, session):
    ev = {"session_id": session, "transcript_path": tpath, "cwd": cwd,
          "hook_event_name": "Stop", "stop_hook_active": active == "1"}
    if message != "-":
        ev["last_assistant_message"] = message
    with open(path, "w") as fh:
        json.dump(ev, fh)

def jget(text, key):
    obj = json.loads(text)
    if not isinstance(obj, dict):
        raise SystemExit(1)
    print(obj.get(key, ""))

cmd = sys.argv[1]
if cmd == "transcript":
    a = sys.argv[3:]
    transcript(sys.argv[2], list(zip(a[0::2], a[1::2])))
elif cmd == "event":
    event(*sys.argv[2:8])
elif cmd == "jget":
    jget(sys.argv[2], sys.argv[3])
PYEOF

# mk_t FILE kind arg [kind arg ...]   (kinds: user meta text side bash edit skill)
mk_t() { "$PY" "$TMP/mk.py" transcript "$@"; }

# --- messages -------------------------------------------------------------------------------
CLOSE_Q='Or answer in your own words, ask me to explain, or skip this question.'
CLOSE_A='Or answer in your own words, or ask me to explain.'
FIRST='Connections -- question 1 of 3 -- importance: high'
GOOD="$FIRST
Should AID reach your Jira through the connection your tool already has?
Why I ask: AID stores no passwords, so it needs your tool's own connection.
My recommendation: yes -- your tool is already signed in to Jira.
  1. Yes, use my tool's connection (recommended)
  2. Not now, skip Jira
$CLOSE_Q"
ASK='bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Connections --impact High --context "x"'

N=0
OUT=""; CODE=0
# run_case NAME MESSAGE [-- env assignments]  with the transcript already built at $TMP/t.jsonl
# Sets OUT and CODE. Environment: CLAUDE_PROJECT_DIR pinned, kill switch and log cleared.
run_event() {   # run_event <stdin-file> [VAR=val ...]
    local stdin="$1"; shift
    OUT=$(env -u AID_QUESTION_HOOK -u AID_QUESTION_HOOK_LOG CLAUDE_PROJECT_DIR="$PROJ" "$@" \
        "$BASH_BIN" "$LAUNCHER" < "$stdin" 2>/dev/null)
    CODE=$?
}
# hook MESSAGE [active] [VAR=val ...]   transcript is $TMP/t.jsonl
hook() {
    local msg="$1" active="${2:-0}"; shift; [[ $# -gt 0 ]] && shift
    N=$((N + 1))
    "$PY" "$TMP/mk.py" event "$TMP/ev$N.json" "$TMP/t.jsonl" "$msg" "$active" "$PROJ" "sess-$N"
    run_event "$TMP/ev$N.json" "$@"
}
expect_pass() {  # label
    if [[ "$OUT" == "{}" && $CODE -eq 0 ]]; then pass "$1"; else fail "$1 -- expected {} exit 0, got '$OUT' exit $CODE"; fi
}
expect_block() { # label [needle ...]  (needles must appear in the reason)
    local label="$1"; shift
    local dec reason
    dec=$("$PY" "$TMP/mk.py" jget "$OUT" decision 2>/dev/null)
    reason=$("$PY" "$TMP/mk.py" jget "$OUT" reason 2>/dev/null)
    if [[ "$dec" != "block" || $CODE -ne 0 ]]; then fail "$label -- expected block, got '$OUT' exit $CODE"; return; fi
    local needle
    for needle in "$@"; do
        if ! grep -qF -- "$needle" <<< "$reason"; then fail "$label -- reason lacks '$needle': $reason"; return; fi
    done
    pass "$label"
}
not_in_reason() { # label needle
    local reason
    reason=$("$PY" "$TMP/mk.py" jget "$OUT" reason 2>/dev/null)
    if grep -qF -- "$2" <<< "$reason"; then fail "$1 -- reason holds '$2': $reason"; else pass "$1"; fi
}

M_FIRST='the first line'
M_WHY='"Why I ask:"'
M_REC='"My recommendation:"'
M_CLOSE='the closing line'
M_RECORD='the record'

# --- QF-01 formed and recorded passes -----------------------------------------------------------
mk_t "$TMP/t.jsonl" user "set up jira" bash "$ASK" text "$GOOD"
hook "$GOOD"; expect_pass "QF-01a formed and recorded passes"
APPROVAL="Build plan -- question 2 of 2 -- importance: medium
May I start the build now?
Why I ask: the build changes files.
My recommendation: yes.
$CLOSE_A"
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$APPROVAL"
hook "$APPROVAL"; expect_pass "QF-01b approval closing line passes"
BOLD="**Connections -- question 1 of 3 -- importance: high**
Should AID reach your Jira?
**Why I ask:** it needs a connection.
**My recommendation**: yes.
$CLOSE_Q"
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$BOLD"
hook "$BOLD"; expect_pass "QF-01c bold markers tolerated"
# --- QF-25 a go-ahead is an approval: its closing line offers no skip --------------------------
GOSKIP="Fix -- question 1 of 1 -- importance: high
Shall I start a fix for the duplicate notes?
Why I ask: starting creates a tracked piece of work, and nothing changes until you agree.
My recommendation: yes.
$CLOSE_Q"
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$GOSKIP"
hook "$GOSKIP"; expect_block "QF-25a a go-ahead with the skip closing line blocks" "the approval closing line"
GOOK="Fix -- question 1 of 1 -- importance: high
Shall I start a fix for the duplicate notes?
Why I ask: starting creates a tracked piece of work, and nothing changes until you agree.
My recommendation: yes.
$CLOSE_A"
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$GOOK"
hook "$GOOK"; expect_pass "QF-25b a go-ahead with the approval closing line passes"
mk_t "$TMP/t.jsonl" user "set up jira" bash "$ASK" text "$GOOD"
hook "$GOOD"; expect_pass "QF-25c a plain question keeps the skip closing line"
EMDASH="Connections $(printf '\xe2\x80\x94') question 1 of 3 $(printf '\xe2\x80\x93') importance: low
Should AID reach your Jira?
Why I ask: it needs a connection.
My recommendation: yes.
$CLOSE_Q"
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$EMDASH"
hook "$EMDASH"; expect_pass "QF-01d en and em dash separators accepted"

# --- QF-02..05 each of F1..F4 missing -----------------------------------------------------------
NO_FIRST=$(grep -vF -- "$FIRST" <<< "$GOOD")
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$NO_FIRST"
hook "$NO_FIRST"; expect_block "QF-02a F1 missing blocks, names the first line" "$M_FIRST"
not_in_reason "QF-02a only F1 named (no Why I ask complaint)" "$M_WHY"
BAD_LABEL="${GOOD/importance: high/importance: High}"
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$BAD_LABEL"
hook "$BAD_LABEL"; expect_block "QF-02b upper-case importance blocks" "$M_FIRST"
NO_WHY=$(grep -v '^Why I ask' <<< "$GOOD")
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$NO_WHY"
hook "$NO_WHY"; expect_block "QF-03 F2 missing blocks, names Why I ask" "$M_WHY"
NO_REC=$(grep -v '^My recommendation' <<< "$GOOD")
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$NO_REC"
hook "$NO_REC"; expect_block "QF-04 F3 missing blocks, names My recommendation" "$M_REC"
NO_CLOSE=$(grep -vF -- "$CLOSE_Q" <<< "$GOOD")
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$NO_CLOSE"
hook "$NO_CLOSE"; expect_block "QF-05 F4 missing blocks, names the closing line" "$M_CLOSE"
BARE="Do you want me to go on with the Jira setup?"
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$BARE"
hook "$BARE"; expect_block "QF-05b a bare question blocks, names all four form items" \
    "$M_FIRST" "$M_WHY" "$M_REC" "$M_CLOSE"

# --- QF-06 no --ask blocks, names the record ----------------------------------------------------
mk_t "$TMP/t.jsonl" user "set up jira" bash "bash .aid/runtime/scripts/execute/writeback-state.sh --check" text "$GOOD"
hook "$GOOD"; expect_block "QF-06a formed but no --ask blocks, names the record" "$M_RECORD" "--ask --design" "--project --ask" "do not record it twice"
not_in_reason "QF-06a only the record named" "$M_WHY"
mk_t "$TMP/t.jsonl" user "set up jira" text "$GOOD"
hook "$GOOD"; expect_block "QF-06b no tool call at all blocks" "$M_RECORD"
mk_t "$TMP/t.jsonl" user "go" bash "echo --ask only, no writer" text "$GOOD"
hook "$GOOD"; expect_block "QF-06c --ask without writeback-state.sh blocks" "$M_RECORD"
mk_t "$TMP/t.jsonl" user "go" side "$ASK" text "$GOOD"
hook "$GOOD"; expect_block "QF-06d an --ask in a sidechain does not count" "$M_RECORD"
mk_t "$TMP/t.jsonl" user "go" text "$NO_WHY"
hook "$NO_WHY"; expect_block "QF-06e both form and record missing names both" "$M_WHY" "$M_RECORD"

# --- QF-07 --ask --design and --project --ask pass ------------------------------------------------
mk_t "$TMP/t.jsonl" user "go" bash 'bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/x.md --category C --impact Low --context q' text "$GOOD"
hook "$GOOD"; expect_pass "QF-07a --ask --design passes"
mk_t "$TMP/t.jsonl" user "go" bash 'bash .aid/runtime/scripts/execute/writeback-state.sh --project --ask --category C --impact Low --context q' text "$GOOD"
hook "$GOOD"; expect_pass "QF-07b --project --ask passes"

# --- QF-08 --ask only in an earlier turn blocks -------------------------------------------------
mk_t "$TMP/t.jsonl" user "first" bash "$ASK" text "first answer" user "second prompt" text "$GOOD"
hook "$GOOD"; expect_block "QF-08a --ask before the last user prompt blocks" "$M_RECORD"
mk_t "$TMP/t.jsonl" user "first" bash "$ASK" text "first answer" meta "skill body" text "$GOOD"
hook "$GOOD"; expect_pass "QF-08b an isMeta entry does not start a new turn"

# --- QF-09 a report with no question passes -----------------------------------------------------
REPORT="Done. The connector file is written and the index was rebuilt.
Nothing else changed."
mk_t "$TMP/t.jsonl" user "go" text "$REPORT"
hook "$REPORT"; expect_pass "QF-09a a report with no question passes"
STMT="I found three files. See https://example.com/a?b=c for the page.
The /aid-fix skill can repair these."
mk_t "$TMP/t.jsonl" user "go" text "$STMT"
hook "$STMT"; expect_pass "QF-09b a '?' inside a URL or inline code does not count"
INL='The pattern is `a?b` and nothing else.'
mk_t "$TMP/t.jsonl" user "go" text "$INL"
hook "$INL"; expect_pass "QF-09c a '?' inside inline code does not count"

# --- QF-10 stop_hook_active passes ---------------------------------------------------------------
mk_t "$TMP/t.jsonl" user "go" text "$BARE"
hook "$BARE" 1; expect_pass "QF-10 stop_hook_active passes a bad message"

# --- QF-11 break offer passes --------------------------------------------------------------------
BREAK="That's all on Connections. Take a break, or go on to Settings?"
mk_t "$TMP/t.jsonl" user "go" text "$BREAK"
hook "$BREAK"; expect_pass "QF-11 break offer passes"

# --- QF-12 fixed subjects waive the record -------------------------------------------------------
REC_MSG="Recovery -- question 1 of 1 -- importance: high
The work record is missing its state file. Shall I rebuild it?
Why I ask: nothing is written before your yes.
My recommendation: yes.
$CLOSE_A"
mk_t "$TMP/t.jsonl" user "resume" bash "bash .aid/runtime/scripts/execute/writeback-state.sh --check" text "$REC_MSG"
hook "$REC_MSG"; expect_pass "QF-12a Recovery subject passes with no record"
CAN_MSG="${REC_MSG/Recovery/Cancel work}"
mk_t "$TMP/t.jsonl" user "cancel" text "$CAN_MSG"
hook "$CAN_MSG"; expect_pass "QF-12b Cancel work subject passes with no record"
OTHER_MSG="${REC_MSG/Recovery/Resume}"
mk_t "$TMP/t.jsonl" user "resume" bash "bash .aid/runtime/scripts/execute/writeback-state.sh --check" text "$OTHER_MSG"
hook "$OTHER_MSG"; expect_block "QF-12c another subject after a --check, no record, blocks" "$M_RECORD"
NOFORM="${CAN_MSG/Why I ask/Because}"
mk_t "$TMP/t.jsonl" user "cancel" text "$NOFORM"
hook "$NOFORM"; expect_block "QF-12d a waived record still needs F1 to F4" "$M_WHY"

# --- QF-13 re-offer of an open entry -------------------------------------------------------------
cat > "$PROJ/.aid/STATE.yml" <<'EOF'
qa:
  - id: Q1
    category: Connections
    impact: High
    state: Skipped
    asked_by: aid-set-connector
    step: --
    context: 'Should AID reach your Jira through the connection your tool already has? AID stores no passwords'
    suggested: 'Yes'
  - id: Q2
    category: Settings
    impact: Low
    state: Answered
    asked_by: aid-config
    step: --
    context: 'Which output style do you want for the project reports?'
    suggested: 'Short'
EOF
REWORD="Connections -- question 1 of 2 -- importance: high
Would you like to link Jira now?
Why I ask: nothing is linked yet.
My recommendation: yes.
$CLOSE_Q"
SAMETEXT="${REWORD/Would you like to link Jira now?/Should AID reach your Jira through the connection your tool already has?}"
mk_t "$TMP/t.jsonl" user "carry on" text "$SAMETEXT"
hook "$SAMETEXT"; expect_pass "QF-13a a skipped question offered again with the same text passes"
OTHERCAT="${SAMETEXT/Connections/Tickets}"
mk_t "$TMP/t.jsonl" user "carry on" text "$OTHERCAT"
hook "$OTHERCAT"; expect_pass "QF-13b same question text under a new subject matches the entry's context"
ANSWERED="${SAMETEXT/Connections/Settings}"
ANSWERED="${ANSWERED/Should AID reach your Jira through the connection your tool already has?/Which output style do you want for the project reports?}"
mk_t "$TMP/t.jsonl" user "carry on" text "$ANSWERED"
hook "$ANSWERED"; expect_block "QF-13c an Answered entry is not open; blocks" "$M_RECORD" "do not record it twice"
rm -f "$PROJ/.aid/STATE.yml"
mk_t "$TMP/t.jsonl" user "carry on" text "$REWORD"
hook "$REWORD"; expect_block "QF-13d no open entry; blocks, says not to record twice" "$M_RECORD" "do not record it twice"
mkdir -p "$PROJ/.aid/design"
cat > "$PROJ/.aid/design/idea.md" <<'EOF'
---
status: draft
---
# Idea

## Questions

| id | question | answer | state | answered_by | category |
|----|----------|--------|-------|-------------|----------|
| D1 | What should the report answer? | | Pending | -- | Report scope |
EOF
DESIGN_MSG="${REWORD/Connections/Report scope}"
DESIGN_MSG="${DESIGN_MSG/Would you like to link Jira now?/What should the report answer?}"
mk_t "$TMP/t.jsonl" user "carry on" text "$DESIGN_MSG"
hook "$DESIGN_MSG"; expect_pass "QF-13e a Pending design-table entry offered again with its text passes"
rm -rf "$PROJ/.aid/design"
mkdir -p "$PROJ/.aid/works/work-900-x"
cat > "$PROJ/.aid/works/work-900-x/STATE.yml" <<'EOF'
qa:
  - id: Q1
    category: Scope
    state: Pending
    context: 'Which environment should the check run against?'
EOF
WORK_MSG="${REWORD/Connections/Scope}"
WORK_MSG="${WORK_MSG/Would you like to link Jira now?/Which environment should the check run against?}"
mk_t "$TMP/t.jsonl" user "carry on" text "$WORK_MSG"
hook "$WORK_MSG"; expect_pass "QF-13f a Pending work qa entry offered again with its text passes"
rm -rf "$PROJ/.aid/works"

# --- QF-14 KB question with an Edit on .aid/knowledge/STATE.md ----------------------------------
mk_t "$TMP/t.jsonl" user "discover" edit "$PROJ/.aid/knowledge/STATE.md" text "$GOOD"
hook "$GOOD"; expect_pass "QF-14a Edit of .aid/knowledge/STATE.md passes"
mk_t "$TMP/t.jsonl" user "discover" edit "$PROJ/.aid/knowledge/other.md" text "$GOOD"
hook "$GOOD"; expect_block "QF-14b Edit of another KB file does not count" "$M_RECORD"

# --- QF-15 ticket skill most recent --------------------------------------------------------------
mk_t "$TMP/t.jsonl" user "read PROJ-1" skill "aid-read-ticket" text "$GOOD"
hook "$GOOD"; expect_pass "QF-15a ticket skill most recent passes with no record"
mk_t "$TMP/t.jsonl" user "read PROJ-1" skill "aid-read-ticket" skill "aid-config" text "$GOOD"
hook "$GOOD"; expect_block "QF-15b a later non-ticket skill ends the waiver" "$M_RECORD"

# --- QF-16 '?' only inside a code fence ----------------------------------------------------------
FENCED='Here is the regex I used:

```
^(a|b)?c?
Is this fine?
```

That is all.'
mk_t "$TMP/t.jsonl" user "go" text "$FENCED"
hook "$FENCED"; expect_pass "QF-16 a '?' only inside a code fence passes"

# --- QF-17 fail-open -----------------------------------------------------------------------------
mk_t "$TMP/t.jsonl" user "go" text "$BARE"
printf 'this is not json' > "$TMP/bad.json"
run_event "$TMP/bad.json"; expect_pass "QF-17a bad stdin prints {} exit 0"
: > "$TMP/empty.json"
run_event "$TMP/empty.json"; expect_pass "QF-17b empty stdin prints {} exit 0"
printf '[1,2]' > "$TMP/arr.json"
run_event "$TMP/arr.json"; expect_pass "QF-17c non-object stdin prints {} exit 0"
N=$((N + 1))
"$PY" "$TMP/mk.py" event "$TMP/ev$N.json" "$TMP/no-such-file.jsonl" "$BARE" 0 "$PROJ" s
run_event "$TMP/ev$N.json"; expect_pass "QF-17d missing transcript prints {} exit 0"
printf '{broken\n[1]\nnot json\n' > "$TMP/garbage.jsonl"
N=$((N + 1))
"$PY" "$TMP/mk.py" event "$TMP/ev$N.json" "$TMP/garbage.jsonl" "$BARE" 0 "$PROJ" s
run_event "$TMP/ev$N.json"; expect_pass "QF-17e unreadable transcript lines never crash"
# Positive control for the no-Python cases: the same event blocks with a normal PATH.
N=$((N + 1))
"$PY" "$TMP/mk.py" event "$TMP/ev$N.json" "$TMP/t.jsonl" "$BARE" 0 "$PROJ" s
run_event "$TMP/ev$N.json"; expect_block "QF-17f control: the event blocks with a normal PATH"
mkdir -p "$TMP/emptybin"
run_event "$TMP/ev$N.json" PATH="$TMP/emptybin"; expect_pass "QF-17g no Python on PATH prints {} exit 0"
mkdir -p "$TMP/badbin"
printf '#!/bin/sh\nexit 1\n' > "$TMP/badbin/python3"; chmod +x "$TMP/badbin/python3"
cp "$TMP/badbin/python3" "$TMP/badbin/python"
run_event "$TMP/ev$N.json" PATH="$TMP/badbin"; expect_pass "QF-17h a Python below 3.8 (or broken) prints {} exit 0"

# --- QF-18 kill switch ---------------------------------------------------------------------------
run_event "$TMP/ev$N.json" AID_QUESTION_HOOK=off; expect_pass "QF-18a AID_QUESTION_HOOK=off passes"
run_event "$TMP/ev$N.json" AID_QUESTION_HOOK=OFF; expect_pass "QF-18b the switch is case-insensitive"
run_event "$TMP/ev$N.json" AID_QUESTION_HOOK=on; expect_block "QF-18c another value does not turn the hook off"

# --- QF-19 no last_assistant_message: the transcript fallback ------------------------------------
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "working" text "$GOOD"
hook "-"; expect_pass "QF-19a fallback reads the last assistant text (formed, recorded)"
mk_t "$TMP/t.jsonl" user "go" text "$BARE"
hook "-"; expect_block "QF-19b fallback blocks a bare question" "$M_FIRST" "$M_RECORD"
mk_t "$TMP/t.jsonl" user "go" text "$REPORT"
hook "-"; expect_pass "QF-19c fallback passes a report"
mk_t "$TMP/t.jsonl" user "go"
hook "-"; expect_pass "QF-19d fallback with no assistant text passes"

# --- QF-20 the log line is written on a block only -----------------------------------------------
LOG="$TMP/hook.jsonl"; rm -f "$LOG"
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$GOOD"
hook "$GOOD" 0 AID_QUESTION_HOOK_LOG="$LOG"
if [[ "$OUT" == "{}" && ! -s "$LOG" ]]; then pass "QF-20a no log line on a pass"; else fail "QF-20a log written on a pass: $(cat "$LOG" 2>/dev/null)"; fi
mk_t "$TMP/t.jsonl" user "go" text "$NO_WHY"
hook "$NO_WHY" 0 AID_QUESTION_HOOK_LOG="$LOG"
expect_block "QF-20b block with the log set"
if [[ -f "$LOG" && $(wc -l < "$LOG") -eq 1 ]]; then
    chk=$("$PY" - "$LOG" "$NO_WHY" <<'PYEOF'
import json, sys
row = json.loads(open(sys.argv[1]).read().splitlines()[0])
ok = (set(row) == {"time", "session_id", "missing", "message"}
      and row["message"] == sys.argv[2]
      and isinstance(row["missing"], list) and len(row["missing"]) == 2
      and row["session_id"].startswith("sess-")
      and row["time"].endswith("Z"))
print("ok" if ok else "bad: %r" % (row,))
PYEOF
)
    assert_eq "$chk" "ok" "QF-20c log line holds time, session_id, missing (list) and message"
else
    fail "QF-20c expected exactly one log line, got: $(cat "$LOG" 2>/dev/null)"
fi
rm -f "$LOG"
hook "$NO_WHY" 1 AID_QUESTION_HOOK_LOG="$LOG"
if [[ ! -s "$LOG" ]]; then pass "QF-20d no log line when stop_hook_active passes it"; else fail "QF-20d log written for an active stop"; fi

# --- QF-21 the block output is one JSON object, exit 0 -------------------------------------------
mk_t "$TMP/t.jsonl" user "go" text "$BARE"
hook "$BARE"
shape=$("$PY" - "$OUT" <<'PYEOF'
import json, sys
text = sys.argv[1]
obj = json.loads(text)
ok = (isinstance(obj, dict) and set(obj) == {"decision", "reason"}
      and obj["decision"] == "block" and obj["reason"].startswith("AID question check:")
      and "\n" not in text.strip())
print("ok" if ok else "bad")
PYEOF
)
assert_eq "$shape" "ok" "QF-21a block output is one single-line JSON object {decision, reason}"
assert_eq "$CODE" "0" "QF-21b a block exits 0"
assert_eq "$(wc -l <<< "$OUT" | tr -d ' ')" "1" "QF-21c exactly one output line"

# --- QF-22 waits on the user without a '?' -------------------------------------------------------
WAYS='I could not find the data in this checkout.

Here are the ways forward:

- tell me where the production data lives
- point me at the other checkout
- say if you would rather have `/aid-monitor` start a new work'
mk_t "$TMP/t.jsonl" user "go" text "$WAYS"
hook "$WAYS"; expect_block "QF-22a a lead-in ending with ':' and a list of ways forward blocks" "$M_FIRST" "$M_RECORD"
WAYS_BARE="Here are the ways forward:
- one path
- another path"
mk_t "$TMP/t.jsonl" user "go" text "$WAYS_BARE"
hook "$WAYS_BARE"; expect_block "QF-22b a 'ways forward' lead-in with a list blocks even with no request verb" "$M_FIRST"
RUNNING="The work is still marked as running. Tell me if you want it cancelled."
mk_t "$TMP/t.jsonl" user "go" text "$RUNNING"
hook "$RUNNING"; expect_block "QF-22c 'Tell me if you want it cancelled.' blocks" "$M_FIRST" "$M_RECORD"
LETKNOW="The index is rebuilt. Let me know if you want X."
mk_t "$TMP/t.jsonl" user "go" text "$LETKNOW"
hook "$LETKNOW"; expect_block "QF-22d 'Let me know if you want X.' blocks" "$M_FIRST"
WOULD="Two layouts fit. Would you like the flat one or the nested one."
mk_t "$TMP/t.jsonl" user "go" text "$WOULD"
hook "$WOULD"; expect_block "QF-22e 'would you like' without a '?' blocks" "$M_FIRST"
PICK="Both fit. Pick one and I will go on."
mk_t "$TMP/t.jsonl" user "go" text "$PICK"
hook "$PICK"; expect_block "QF-22f an imperative 'pick' blocks" "$M_FIRST"
DONELIST="Done. What changed:

- the connector file was written
- the index was rebuilt
- the tests passed"
mk_t "$TMP/t.jsonl" user "go" text "$DONELIST"
hook "$DONELIST"; expect_pass "QF-22g a final report ending with a done-list passes"
DONELIST2="All set. The options considered were the flat layout and the nested one; I picked the flat one and chose the name."
mk_t "$TMP/t.jsonl" user "go" text "$DONELIST2"
hook "$DONELIST2"; expect_pass "QF-22h a report that only tells what was chosen passes"
FENCED2='The command to run is:

```
Tell me if you want it cancelled.
```

That is all.'
mk_t "$TMP/t.jsonl" user "go" text "$FENCED2"
hook "$FENCED2"; expect_pass "QF-22i a request phrase only inside a code fence passes"
INLINE2='The flag `let me know if` is not used here.'
mk_t "$TMP/t.jsonl" user "go" text "$INLINE2"
hook "$INLINE2"; expect_pass "QF-22j a request phrase only inside inline code passes"
EARLIER="Tell me if you want it cancelled.

Earlier I listed the three steps.

Each step ran in order.

Done. The work was left as it was."
mk_t "$TMP/t.jsonl" user "go" text "$EARLIER"
hook "$EARLIER"; expect_pass "QF-22k a request phrase more than three paragraphs before the end passes"
CLOSER="Tell me if you want it cancelled.

Done. The work was left as it was."
mk_t "$TMP/t.jsonl" user "go" text "$CLOSER"
hook "$CLOSER"; expect_block "QF-22l a request followed by a closing remark still waits on the user"
MIDDLE="I have not changed anything yet.

To narrow it down, I need two things from you:
1. What the duplicated lines look like.
2. The exact commands you ran.

Once we know the cause, I can fix it."
mk_t "$TMP/t.jsonl" user "go" text "$MIDDLE"
hook "$MIDDLE"; expect_block "QF-22m a numbered request in the middle, then a closing remark, waits on the user"
NEEDLIST="To get a real answer, I need one of these:

- the path of the other checkout
- the name of the branch
- a copy of the log

I haven't started that, so no project files were changed."
mk_t "$TMP/t.jsonl" user "go" text "$NEEDLIST"
hook "$NEEDLIST"; expect_block "QF-22n 'I need one of these:' + a list + a closing remark waits on the user" "$M_FIRST" "$M_RECORD"
NEEDLIST2="I'd need the following:
- the path of the other checkout
- the name of the branch"
mk_t "$TMP/t.jsonl" user "go" text "$NEEDLIST2"
hook "$NEEDLIST2"; expect_block "QF-22o \"I'd need the following:\" + a list waits on the user" "$M_FIRST"
NEEDLIST3="I would need two things before I can go on:
1. the path of the other checkout
2. the name of the branch"
mk_t "$TMP/t.jsonl" user "go" text "$NEEDLIST3"
hook "$NEEDLIST3"; expect_block "QF-22p 'I would need two things' + a list waits on the user" "$M_FIRST"
NEEDPAST="Done. I needed to check the following:

- the connector file
- the index
- the tests

All three were fine, so nothing was changed."
mk_t "$TMP/t.jsonl" user "go" text "$NEEDPAST"
hook "$NEEDPAST"; expect_pass "QF-22q a report that says 'I needed to ...' about the past passes"
NEEDTO="Here is what happens next. I need to restart the index, and I need to rerun the tests:

- restart the index
- rerun the tests"
mk_t "$TMP/t.jsonl" user "go" text "$NEEDTO"
hook "$NEEDTO"; expect_pass "QF-22r 'I need to <do something>:' + a list (the agent's own steps) passes"

# --- QF-24 the break offer anywhere in the tail window ---------------------------------------------
BRK1="That is all on Connections. Take a break, or go on to the pipeline settings?

Nothing else is pending."
mk_t "$TMP/t.jsonl" user "go" text "$BRK1"
hook "$BRK1"; expect_pass "QF-24a a break offer followed by a short closing line passes"
BRK2="Everything about Connections is set.

Take a break, or go on to the pipeline settings?

Your connectors are listed in the index.

The index is up to date."
mk_t "$TMP/t.jsonl" user "go" text "$BRK2"
hook "$BRK2"; expect_pass "QF-24b a break offer two paragraphs before the end passes"
BRK3="Take a break, or go on to the pipeline settings?

Settings -- question 1 of 2 -- importance: medium
Should AID use the default pipeline settings?
Why I ask: they decide how the pipeline runs.
My recommendation: yes.
$CLOSE_Q"
mk_t "$TMP/t.jsonl" user "go" text "$BRK3"
hook "$BRK3"; expect_block "QF-24c a break offer plus a separate form question is still checked as a question" "$M_RECORD"
BRK4="Take a break, or go on to the pipeline settings?

Settings -- question 1 of 2 -- importance: medium
Should AID use the default pipeline settings?
$CLOSE_Q"
mk_t "$TMP/t.jsonl" user "go" bash "$ASK" text "$BRK4"
hook "$BRK4"; expect_block "QF-24d a break offer plus a form question missing its lines still blocks" "$M_WHY" "$M_REC"

# --- QF-23 R3 needs the same question; the category alone never matches ----------------------------
cat > "$PROJ/.aid/STATE.yml" <<'EOF'
qa:
  - id: Q1
    category: Approval
    impact: High
    state: Pending
    asked_by: aid-orchestrate
    step: --
    context: 'May I publish the review to the pull request now?'
    suggested: 'Yes'
  - id: Q2
    category: Connections
    impact: High
    state: Skipped
    asked_by: aid-set-connector
    step: --
    context: 'Should AID reach your Jira through the connection your tool already has? AID stores no passwords'
    suggested: 'Yes'
EOF
DIFFQ="Approval -- question 2 of 2 -- importance: medium
May I start the build now?
Why I ask: the build changes files.
My recommendation: yes.
$CLOSE_A"
mk_t "$TMP/t.jsonl" user "go" text "$DIFFQ"
hook "$DIFFQ"; expect_block "QF-23a an open entry with the same category but another question does not satisfy the record" "$M_RECORD"
not_in_reason "QF-23a only the record named" "$M_WHY"
SAMEQ="${DIFFQ/May I start the build now?/May I publish the review to the pull request now?}"
mk_t "$TMP/t.jsonl" user "go" text "$SAMEQ"
hook "$SAMEQ"; expect_pass "QF-23b the same question text under the same category passes"
SAMEQ2="${DIFFQ/May I start the build now?/Shall I publish the review to the pull request now?}"
mk_t "$TMP/t.jsonl" user "go" text "$SAMEQ2"
hook "$SAMEQ2"; expect_pass "QF-23c a near-identical wording (token overlap of 0.6 or more) passes"
SKIPPED="Connections -- question 1 of 1 -- importance: high
Should AID reach your Jira through the connection your tool already has?
Why I ask: AID stores no passwords, so it needs your tool's own connection.
My recommendation: yes.
$CLOSE_Q"
mk_t "$TMP/t.jsonl" user "carry on" text "$SKIPPED"
hook "$SKIPPED"; expect_pass "QF-23d a re-offered skipped question with the same text still passes"
CATONLY="Connections -- question 1 of 1 -- importance: high
Do you also want a Slack connector?
Why I ask: none is set up.
My recommendation: no.
$CLOSE_Q"
mk_t "$TMP/t.jsonl" user "carry on" text "$CATONLY"
hook "$CATONLY"; expect_block "QF-23e a new question under a category that holds a Skipped entry blocks" "$M_RECORD"
rm -f "$PROJ/.aid/STATE.yml"

# --- QF-26 R1: the --ask context must be the question shown ---------------------------------------
Q26='Should AID reach your Jira through the connection your tool already has?'
ASK26='bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/x.md --category Connections --impact High --context '
OTHERCTX='Where do you see the same note twice: in the list output, or is the note saved twice in notes.json?'
M_OTHER='another question than the one shown'
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"${Q26}\" --suggested yes" text "$GOOD"
hook "$GOOD"; expect_pass "QF-26a a double-quoted --context that is the shown question passes"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}'${Q26}' --suggested yes" text "$GOOD"
hook "$GOOD"; expect_pass "QF-26b a single-quoted --context that is the shown question passes"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"${OTHERCTX}\" --suggested yes" text "$GOOD"
hook "$GOOD"; expect_block "QF-26c a different --context blocks, naming the record" "$M_RECORD" "$M_OTHER" "--ask --design"
not_in_reason "QF-26c the missing-record wording is not used" "no writeback-state.sh --ask ran"
QOWN="Should AID reach your Jira through your tool's own connection?"
QAPOS="${GOOD/Should AID reach your Jira through the connection your tool already has?/$QOWN}"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\$'Should AID reach your Jira through your tool\\'s own connection?'" text "$QAPOS"
hook "$QAPOS"; expect_pass "QF-26d a \$'...' --context with an escaped quote passes"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}'Should AID reach your Jira through your tool'\\''s own connection?'" text "$QAPOS"
hook "$QAPOS"; expect_pass "QF-26e a single-quoted --context with a '\\'' quote passes"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"\$(cat /tmp/ctx.txt)\"" text "$GOOD"
hook "$GOOD"; expect_pass "QF-26f a --context that cannot be read (command substitution) keeps today's behaviour"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}'unterminated" text "$GOOD"
hook "$GOOD"; expect_pass "QF-26g an unterminated quote keeps today's behaviour"
mk_t "$TMP/t.jsonl" user "go" bash 'bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category C --impact Low' text "$GOOD"
hook "$GOOD"; expect_pass "QF-26h an --ask with no --context keeps today's behaviour"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"${OTHERCTX}\"" bash "${ASK26}\"${Q26}\"" text "$GOOD"
hook "$GOOD"; expect_pass "QF-26i one matching --ask among several passes"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"${OTHERCTX}\"" text "$GOOD"
hook "$GOOD"; expect_block "QF-26j a non-matching --ask alone blocks" "$M_OTHER"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"${OTHERCTX}\" && echo done" text "$GOOD"
hook "$GOOD"; expect_block "QF-26k a chained command is read to the end of the value" "$M_OTHER"
# the shape of a real miss: the recorded question and the shown one differ in wording and meaning
SHOWN14="Notes -- question 1 of 2 -- importance: high
Is it the same words added two separate times, or did one add produce two entries?
Why I ask: it points to a different cause.
My recommendation: the second.
$CLOSE_Q"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"${OTHERCTX}\"" text "$SHOWN14"
hook "$SHOWN14"; expect_block "QF-26l a recorded question that differs from the one shown blocks" "$M_OTHER"
# a matching open entry still satisfies the record (R3), whatever the --ask said
cat > "$PROJ/.aid/STATE.yml" <<EOF
qa:
  - id: Q1
    category: Connections
    state: Pending
    context: '${Q26}'
EOF
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"${OTHERCTX}\"" text "$GOOD"
hook "$GOOD"; expect_pass "QF-26m an open entry with the shown question satisfies the record"
rm -f "$PROJ/.aid/STATE.yml"

# --- QF-27 a question in the form inside a code fence is still checked ---------------------------
FENCEDQ="Jira is not connected yet.

\`\`\`text
$GOOD
\`\`\`

I could not record it."
mk_t "$TMP/t.jsonl" user "go" text "$FENCEDQ"
hook "$FENCEDQ"; expect_block "QF-27a a fenced question with no record blocks, naming the record" "$M_RECORD"
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"${Q26}\"" text "$FENCEDQ"
hook "$FENCEDQ"; expect_pass "QF-27b a fenced question that was recorded passes"
FENCEDQ2=$(grep -v '^Why I ask' <<< "$FENCEDQ")
mk_t "$TMP/t.jsonl" user "go" bash "${ASK26}\"${Q26}\"" text "$FENCEDQ2"
hook "$FENCEDQ2"; expect_block "QF-27c a fenced question missing a form line blocks, naming it" "$M_WHY"
FENCEDX="The form looks like this:

\`\`\`text
$FIRST
Some question?
\`\`\`

Nothing else changed."
mk_t "$TMP/t.jsonl" user "go" text "$FENCEDX"
hook "$FENCEDX"; expect_pass "QF-27d a fence without the closing line is code, not a question"

# --- QF-28 the block reason ------------------------------------------------------------------------
mk_t "$TMP/t.jsonl" user "go" text "$GOOD"
hook "$GOOD"; expect_block "QF-28a the reason keeps the repeat line and forbids dropping a question or a break offer" \
    "repeat everything this message told them" "Never drop a question your skill requires, or a break offer" "truly asks nothing"
not_in_reason "QF-28b the old 'not waiting' escape is gone" "If you are not waiting on the user"

# --- QF-29 plain words: no internal identifier in the question for a plain-words user -------------
Q29='Approve the flattened work so /aid-execute can start?'
JARGON="Build plan -- question 1 of 1 -- importance: high
$Q29
Why I ask: the build changes files.
My recommendation: yes.
$CLOSE_A"
ASK29="${ASK26}'${Q29}' --suggested yes"
mk_t "$TMP/t.jsonl" user "add two notes one right after the other" bash "$ASK29" text "$JARGON"
hook "$JARGON"; expect_block "QF-29a a skill name in the question of a plain-words user blocks, naming it" \
    "plain words in the question" "aid-execute" "--answer --id Q<n> or D<n>" "--state Assumed"
not_in_reason "QF-29a the record is not named when it matches" "the record ("
for tech in 'the bug is in `notes.py`' 'run it with --force' '/aid-config' 'check notes.json' 'the save_note call' \
    'try aid-execute' 'see src/notes' 'getUser() fails' 'open INDEX.MD'; do
    mk_t "$TMP/t.jsonl" user "$tech" bash "$ASK29" text "$JARGON"
    hook "$JARGON"; expect_pass "QF-29b a technical user message ($tech) passes"
done
mk_t "$TMP/t.jsonl" user "<command-name>/aid-execute</command-name>" bash "$ASK29" text "$JARGON"
hook "$JARGON"; expect_pass "QF-29c a typed slash command makes the user technical"
PROSE="I'll use aid-orchestrate and writeback-state.sh for this.

$GOOD"
mk_t "$TMP/t.jsonl" user "set up jira" bash "${ASK26}\"${Q26}\"" text "$PROSE"
hook "$PROSE"; expect_pass "QF-29d an identifier outside the question is not checked"
SCRIPTQ="${GOOD/Should AID reach your Jira through the connection your tool already has?/Shall I run writeback-state.sh in .aid/ now?}"
mk_t "$TMP/t.jsonl" user "set up jira" bash "${ASK26}'Shall I run writeback-state.sh in .aid/ now?'" text "$SCRIPTQ"
hook "$SCRIPTQ"; expect_block "QF-29e a script name and an .aid/ path are internal" "writeback-state.sh" ".aid/"
mk_t "$TMP/t.jsonl" user "add notes" meta "AID question check: x \`y\`" bash "$ASK29" text "$JARGON"
hook "$JARGON"; expect_block "QF-29f a meta entry does not make the user technical" "plain words in the question"

mk_t "$TMP/t.jsonl" user "add notes" user "Stop hook feedback: AID question check: x \`y\`" bash "$ASK29" text "$JARGON"
hook "$JARGON"; expect_block "QF-29g hook feedback in a user entry does not make the user technical" "plain words in the question"
RECOV="${JARGON/Build plan -- question 1 of 1/Recovery -- question 1 of 1}"
mk_t "$TMP/t.jsonl" user "add notes" text "$RECOV"
hook "$RECOV"; expect_pass "QF-29h a waived Recovery confirmation is not checked for plain words"
mk_t "$TMP/t.jsonl" user "add notes" skill "aid-read-ticket" text "$JARGON"
hook "$JARGON"; expect_pass "QF-29i a ticket skill's question is not checked for plain words"
QLINK='May I follow [the asking rule](.aid/runtime/rules.md) for this?'
LINKQ="${JARGON/$Q29/$QLINK}"
mk_t "$TMP/t.jsonl" user "add notes" bash "${ASK26}'${QLINK}'" text "$LINKQ"
hook "$LINKQ"; expect_pass "QF-29j a path in a link target is not an internal name in the question"
mk_t "$TMP/t.jsonl" user "add notes" text "$JARGON"
hook "$JARGON"; expect_block "QF-29k jargon with no record names both and gives no close instruction" "plain words in the question" "$M_RECORD"
not_in_reason "QF-29k no close of an entry that does not exist" "Close the entry"
QKIT='Should the first-aid-kit note stay in the list?'
KITQ="${JARGON/$Q29/$QKIT}"
mk_t "$TMP/t.jsonl" user "add notes" bash "${ASK26}'${QKIT}'" text "$KITQ"
hook "$KITQ"; expect_pass "QF-29l an ordinary hyphenated word holding 'aid-' passes"

# --- QF-30 a re-offer reuses the open entry's id; a new --ask for it is a duplicate -----------------
qa30() {   # qa30 FILE ID|STATE|CONTEXT ...
    local f="$1" row id st ctx; shift
    { echo "qa:"; for row in "$@"; do
        IFS='|' read -r id st ctx <<< "$row"
        printf "  - id: %s\n    category: Connections\n    impact: High\n    state: %s\n    context: '%s'\n" "$id" "$st" "$ctx"
      done; } > "$f"
}
ASK30="${ASK26}\"${Q26}\""
qa30 "$PROJ/.aid/STATE.yml" "Q1|Skipped|$Q26" "Q2|Pending|$Q26"
mk_t "$TMP/t.jsonl" user "carry on" bash "$ASK30" text "$GOOD"
hook "$GOOD"; expect_block "QF-30a a new --ask of a skipped question blocks, naming the open id" "already open as Q1" "duplicate of the open entry"
qa30 "$PROJ/.aid/STATE.yml" "Q1|Answered|$Q26" "Q2|Pending|$Q26"
hook "$GOOD"; expect_pass "QF-30b an Answered earlier entry is not open, so a new --ask is not a duplicate"
rm -f "$PROJ/.aid/STATE.yml"
mkdir -p "$PROJ/.aid/works/work-001-x"
W30="$PROJ/.aid/works/work-001-x/STATE.yml"
qa30 "$W30" "Q1|Pending|Which output style do you want for the project reports?" "Q2|Pending|$Q26"
printf 'tasks:\n  - id: task-001\n    state: Pending\n' >> "$W30"
hook "$GOOD"; expect_pass "QF-30c the newest question is found by number, not by its place in the file"
qa30 "$W30" "Q1|Pending|$Q26"
mk_t "$TMP/t.jsonl" user "carry on" text "$GOOD"
hook "$GOOD"; expect_pass "QF-30d a re-offer with no new --ask passes"
rm -f "$W30"; rmdir "$PROJ/.aid/works/work-001-x" "$PROJ/.aid/works"

# --- launcher/checker hygiene ---------------------------------------------------------------------
if LC_ALL=C grep -qP '[^\x00-\x7F]' "$LAUNCHER" "$CHECKER"; then fail "HY-01 hook scripts must be ASCII-only"; else pass "HY-01 hook scripts are ASCII-only"; fi
[[ -x "$LAUNCHER" ]] && pass "HY-02 launcher is executable" || fail "HY-02 launcher is not executable"
for f in "$LAUNCHER" "$CHECKER"; do
    if [[ "$(grep -c -E '^(#|\s*Purpose:)' "$f")" -gt 0 ]] && grep -q 'Exit codes' "$f" && grep -q 'Usage' "$f" && grep -q 'Purpose' "$f"; then
        pass "HY-03 $(basename "$f") header has Purpose, Usage and Exit codes"
    else
        fail "HY-03 $(basename "$f") header lacks Purpose, Usage or Exit codes"
    fi
done

test_summary
