#!/usr/bin/env bash
# test-chat-node-endtoend.sh — the whole product, in one scenario, across all five deliveries.
#
# WHY THIS EXISTS AND WHAT IT IS FOR. Every delivery was gated on its own criteria and every gate
# passed, but each suite exercises the layer its delivery built. This one runs a single scenario that
# crosses all five, because a product whose parts are each correct can still be wrong at the joins —
# and the joins are where nobody was looking.
#
# The scenario is the work's own TARGET CASE, from §3: a session in one tool on one machine exchanging
# messages with a session in another tool on another machine. Everything else is a subset of it.
#
#   delivery-001  the hub, a channel, send / inbox / ack, positions
#   delivery-002  the roster and a directed connect request
#   delivery-003  the wake — a real adapter, driven exactly as its host would drive it
#   delivery-004  two hubs, replication, the federated roster
#   delivery-005  whisper, mention, retention, the audit log, operator visibility
#
# WHAT IT STILL CANNOT DO: there is no live host session here, so the wake is exercised by feeding an
# adapter the stop payload its host would send and reading what it returns. That is the whole of the
# adapter contract and none of the host's half; the host's half is MP-05 to MP-07.
#
#   E2E01  the invariant the whole design rests on: a session's every call goes to loopback
#   E2E02  two hubs, two tools, two repositories — the target case's setting
#   E2E03  the roster spans machines and shows who is free
#   E2E04  a connect request crosses machines and puts the peer in the channel
#   E2E05  a message crosses, and the recipient's ADAPTER wakes with the text in hand
#   E2E06  the woken session acknowledges, and the position moves on its own hub
#   E2E07  a reply crosses back and wakes the other side
#   E2E08  a mention reaches everyone and the mentioned member can tell
#   E2E09  a whisper reaches only its target, across the machine boundary
#   E2E10  and its body is nowhere in the non-target hub's store
#   E2E11  the operator sees both sessions, the channel, unread depth and idle time
#   E2E12  the audit log shows what happened, including the whisper, and no bodies
#   E2E13  retention removes what everyone has acknowledged and keeps what they have not
#   E2E14  a message sent while the far hub is down is delivered when it returns
#   E2E15  nothing is left running, on either machine
#
# Usage: bash test-chat-node-endtoend.sh [--verbose]

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
for tool in node curl python3; do
    command -v "$tool" >/dev/null 2>&1 || { echo "SKIP: ${tool} not available" >&2; exit 0; }
done

_TMPD="$(mktemp -d)"
export AID_CODE_HOME="$REPO_ROOT"
LINK_A=$(( 21000 + (BASHPID % 1500) * 2 ))
LINK_B=$(( LINK_A + 1 ))
mkdir -p "${_TMPD}/A" "${_TMPD}/B" "${_TMPD}/repoA" "${_TMPD}/repoB"

_own_hubs() {
    local n=0 p
    for p in $(pgrep -f 'server/hub.mjs' 2>/dev/null); do
        if tr '\0' '\n' < "/proc/${p}/environ" 2>/dev/null | grep -q "^AID_CHAT_RUNTIME=${_TMPD}"; then
            n=$((n + 1))
        fi
    done
    printf '%s\n' "$n"
}
_kill_own() {
    local want="$1" p
    for p in $(pgrep -f 'server/hub.mjs' 2>/dev/null); do
        if tr '\0' '\n' < "/proc/${p}/environ" 2>/dev/null | grep -q "^AID_CHAT_RUNTIME=${_TMPD}/${want}\$"; then
            kill "$p" 2>/dev/null
        fi
    done
}
_cleanup() { _kill_own A; _kill_own B; sleep 0.3; rm -rf "${_TMPD}"; }
trap _cleanup EXIT

# Each machine gets its own runtime, store, identity and link port -- and the CLI is invoked with that
# machine's environment, exactly as it would be on two real hosts.
_A() { env AID_CHAT_RUNTIME="${_TMPD}/A" AID_CHAT_STORE="${_TMPD}/A/chat.db" AID_CHAT_MACHINE=alpha \
           AID_CHAT_LINK_PORT="$LINK_A" AID_CHAT_JOB_INTERVAL_MS=0 \
           bash "${REPO_ROOT}/bin/aid" "$@"; }
_B() { env AID_CHAT_RUNTIME="${_TMPD}/B" AID_CHAT_STORE="${_TMPD}/B/chat.db" AID_CHAT_MACHINE=beta \
           AID_CHAT_LINK_PORT="$LINK_B" AID_CHAT_JOB_INTERVAL_MS=0 \
           bash "${REPO_ROOT}/bin/aid" "$@"; }
_j() { python3 -c "import json,sys; d=json.load(sys.stdin); print(eval(sys.argv[1]))" "$1"; }
_sql() { python3 -c "
import sqlite3,sys
print(list(sqlite3.connect(sys.argv[1]).execute(sys.argv[2])))" "$1" "$2"; }

# --- E2E01: the invariant everything else rests on ---------------------------
#
# "A session speaks only to its own machine's hub, ever." Asserted structurally, because it is the
# premise that makes a scalar read position exact, makes the trust boundary a single loopback socket,
# and makes federation a hub-to-hub concern the session never sees. If a session could reach a remote
# hub, three separate designs would be wrong at once.
offenders="$(python3 - "${REPO_ROOT}" <<'PY'
import re, sys
root = sys.argv[1]

# Scoped to the CHAT code and nothing else. An earlier version scanned the whole of `bin/aid` and
# caught the installer's download host and the dashboard's Tailscale links -- other features of the
# same file, with nothing to do with a chat session. A check that fails on unrelated code gets
# widened until it passes, which is how an invariant stops being checked at all.
CHAT_FNS = ('_aid_chat_base_url', '_aid_chat_call', '_aid_chat_wait_once', '_aid_chat_merge_wake',
            '_aid_chat_respond', '_cmd_chat_plane', '_cmd_chat_ctl', '_aid_chat_runtime_dir',
            '_aid_chat_hub_entry', '_aid_chat_require_node', '_aid_json_escape')

def bash_fn_bodies(src, names):
    out = []
    lines = src.split('\n')
    for n, line in enumerate(lines):
        m = re.match(r'^(' + '|'.join(names) + r')\(\)\s*\{', line)
        if not m:
            continue
        for k in range(n + 1, len(lines)):
            if lines[k] == '}':
                out.append('\n'.join(lines[n:k]))
                break
    return out

regions = bash_fn_bodies(open(f'{root}/bin/aid', encoding='utf-8').read(), CHAT_FNS)
if not regions:
    print('SCAN-FOUND-NO-CHAT-FUNCTIONS')   # fails loudly rather than passing vacuously
    raise SystemExit
for path in ('chat-node/adapters/common.mjs', 'chat-node/adapters/cursor.mjs',
             'chat-node/adapters/claude-code.mjs'):
    regions.append(open(f'{root}/{path}', encoding='utf-8').read())

bad = []
for region in regions:
    for m in re.finditer(r'https?://([^"\'` )\n]+)', region):
        host = m.group(1)
        if not host.startswith('127.0.0.1') and not host.startswith('localhost'):
            bad.append(host[:50])
print('\n'.join(sorted(set(bad))) if bad else 'loopback-only')
PY
)"
assert_eq "$offenders" "loopback-only" \
    "E2E01 every address the session path can reach is loopback: a session speaks only to its own hub"

# --- E2E02: the target case's setting ---------------------------------------
_A chat node start --port 0 >/dev/null 2>&1
_B chat node start --port 0 >/dev/null 2>&1
for _ in 1 2 3 4 5 6 7 8 9 10; do
    [[ -s "${_TMPD}/A/hub.port" && -s "${_TMPD}/B/hub.port" ]] && break
    sleep 0.2
done
[[ -s "${_TMPD}/A/hub.port" && -s "${_TMPD}/B/hub.port" ]] || { echo "SKIP: hubs would not start" >&2; exit 0; }
BA="http://127.0.0.1:$(cat "${_TMPD}/A/hub.port")"
BB="http://127.0.0.1:$(cat "${_TMPD}/B/hub.port")"

# Two tools, two repositories -- which is the §3 target case and not decoration: the cwd is what makes
# them different repositories, and the tool is what makes the adapter contract the thing under test.
( cd "${_TMPD}/repoA" && env AID_CHAT_RUNTIME="${_TMPD}/A" AID_CHAT_STORE="${_TMPD}/A/chat.db" \
    bash "${REPO_ROOT}/bin/aid" chat register --name dev-cursor --tool cursor >/dev/null 2>&1 )
( cd "${_TMPD}/repoB" && env AID_CHAT_RUNTIME="${_TMPD}/B" AID_CHAT_STORE="${_TMPD}/B/chat.db" \
    bash "${REPO_ROOT}/bin/aid" chat register --name dev-claude --tool claude-code >/dev/null 2>&1 )

shape="$(_A chat show 2>/dev/null | python3 -c "
import json,sys
s=[x for x in json.load(sys.stdin)['sessions'] if x['name']=='dev-cursor'][0]
print(f\"{s['tool']}|{s['cwd'].split('/')[-1]}\")")"
assert_eq "$shape" "cursor|repoA" "E2E02 machine A's session declares its tool and its own repository"
shape="$(_B chat show 2>/dev/null | python3 -c "
import json,sys
s=[x for x in json.load(sys.stdin)['sessions'] if x['name']=='dev-claude'][0]
print(f\"{s['tool']}|{s['cwd'].split('/')[-1]}\")")"
assert_eq "$shape" "claude-code|repoB" "E2E02 machine B's session declares a DIFFERENT tool and a different repository"

# --- E2E03: the federated roster --------------------------------------------
_A chat peers --add --machine "127.0.0.1:${LINK_B}" >/dev/null 2>&1
curl -sS -X POST "${BA}/peers/connect" -d "{\"machine\":\"127.0.0.1:${LINK_B}\"}" >/dev/null 2>&1
sleep 0.7
roster="$(_A chat roster --name dev-cursor 2>/dev/null)"
assert_eq "$(printf '%s' "$roster" | _j "sorted({a['machine'] for a in d['agents']})")" "['alpha', 'beta']" \
    "E2E03 the roster spans both machines"
assert_eq "$(printf '%s' "$roster" | _j "[a['available'] for a in d['agents'] if a['name']=='dev-claude']")" "[True]" \
    "E2E03 and shows the peer on the other machine as available"

# --- E2E04: the connect request across machines -----------------------------
_A chat open --name dev-cursor --channel pairing >/dev/null 2>&1
sleep 0.3
conn="$(_A chat connect --name dev-cursor --target dev-claude 2>/dev/null)"
assert_eq "$(printf '%s' "$conn" | _j "(d['ok'], d.get('relayed'))")" "(True, True)" \
    "E2E04 a connect request crosses machines and succeeds"
sleep 0.5
assert_eq "$(_B chat list --name dev-claude 2>/dev/null | _j "[c['name'] for c in d['channels'] if c['is_mine']]")" "['pairing']" \
    "E2E04 and the peer is in the asker's channel on its OWN hub, having called nothing"

# --- E2E05/E2E06: the message, the wake, the acknowledgement -----------------
_A chat send --name dev-cursor --body 'what test framework does this repo use?' >/dev/null 2>&1
sleep 0.8

# The adapter, driven exactly as its host drives it: the stop payload on stdin, BOM and all. This is
# machine B, whose session runs in Claude Code, so it is that adapter.
woke="$(echo '{"session_id":"e2e-1","stop_hook_active":false}' \
    | env AID_CHAT_RUNTIME="${_TMPD}/B" AID_CHAT_STORE="${_TMPD}/B/chat.db" \
      node "${REPO_ROOT}/chat-node/adapters/claude-code.mjs" --name dev-claude --host-timeout 60 2>/dev/null)"
carried="$(printf '%s' "$woke" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print('yes' if 'what test framework' in d.get('reason','') else 'no')")"
assert_eq "$carried" "yes" "E2E05 the recipient's adapter wakes with the message text already in hand"
assert_eq "$(printf '%s' "$woke" | _j "sorted(d.keys())")" "['decision', 'reason']" \
    "E2E05 in the shape that host documents"

# The adapter advanced `delivered` and NOT `acked`; the session advances `acked` when it acts.
pos="$(_sql "${_TMPD}/B/chat.db" "SELECT delivered_seq, acked_seq FROM session WHERE name='dev-claude'")"
assert_eq "$pos" "[(1, 0)]" "E2E06 the wake advanced delivered and left acked alone, so a crash before the turn loses nothing"
_B chat ack --name dev-claude --cursor 1 >/dev/null 2>&1
assert_eq "$(_sql "${_TMPD}/B/chat.db" "SELECT acked_seq FROM session WHERE name='dev-claude'")" "[(1,)]" \
    "E2E06 and the session's own acknowledgement moves it"

# --- E2E07: the reply, the other way ----------------------------------------
_B chat send --name dev-claude --body 'vitest, see package.json' >/dev/null 2>&1
sleep 0.8
woke_back="$(printf '\xef\xbb\xbf{"loop_count":0,"conversation_id":"e2e-2"}' \
    | env AID_CHAT_RUNTIME="${_TMPD}/A" AID_CHAT_STORE="${_TMPD}/A/chat.db" \
      node "${REPO_ROOT}/chat-node/adapters/cursor.mjs" --name dev-cursor --host-timeout 60 2>/dev/null)"
back="$(printf '%s' "$woke_back" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print('yes' if 'vitest' in d.get('followup_message','') else 'no')")"
assert_eq "$back" "yes" "E2E07 the reply crosses back and wakes the other machine's session"
assert_eq "$(printf '%s' "$woke_back" | _j "sorted(d.keys())")" "['followup_message']" \
    "E2E07 in the shape THAT host documents -- a different shape, the same contract"

# --- E2E08/E2E09/E2E10: mention and whisper, across the boundary ------------
# A third member on machine A, so a whisper has somebody to hide from.
( cd "${_TMPD}/repoA" && env AID_CHAT_RUNTIME="${_TMPD}/A" AID_CHAT_STORE="${_TMPD}/A/chat.db" \
    bash "${REPO_ROOT}/bin/aid" chat register --name dev-third --tool cursor >/dev/null 2>&1 )
_A chat join --name dev-third --channel pairing >/dev/null 2>&1
sleep 0.5

_A chat send --name dev-cursor --body 'MENTION-BODY for claude' --mention dev-claude >/dev/null 2>&1
sleep 0.7
for who in dev-third; do
    got="$(_A chat inbox --name "$who" --cursor 0 2>/dev/null | _j "any('MENTION-BODY' in m['body'] for m in d['messages'])")"
    assert_eq "$got" "True" "E2E08 a mention is visible to everyone, including ${who} who was not mentioned"
done
aimed="$(_B chat inbox --name dev-claude --cursor 0 2>/dev/null | _j "[m['mention'] for m in d['messages'] if m['mention']]")"
assert_eq "$aimed" "[['dev-claude']]" "E2E08 and the mentioned member, on the other machine, can tell it was aimed at them"

_A chat send --name dev-cursor --body 'WHISPER-BODY only for claude' --whisper-to dev-claude >/dev/null 2>&1
sleep 0.9
tgt="$(_B chat inbox --name dev-claude --cursor 0 2>/dev/null | _j "any('WHISPER-BODY' in m['body'] for m in d['messages'])")"
assert_eq "$tgt" "True" "E2E09 a whisper reaches its target across the machine boundary"
third="$(_A chat inbox --name dev-third --cursor 0 2>/dev/null | _j "any('WHISPER-BODY' in m['body'] for m in d['messages'])")"
assert_eq "$third" "False" "E2E09 and is invisible to a third member, in history as well as delivery"

# E2E10 -- the storage boundary. The whisper originated on A, so A holds it and filters on read; the
# assertion that matters is which HUBS hold the body at all.
a_has="$(_sql "${_TMPD}/A/chat.db" "SELECT COUNT(*) FROM message WHERE body LIKE '%WHISPER-BODY%'")"
b_has="$(_sql "${_TMPD}/B/chat.db" "SELECT COUNT(*) FROM message WHERE body LIKE '%WHISPER-BODY%'")"
assert_eq "${a_has}|${b_has}" "[(1,)]|[(1,)]" \
    "E2E10 the whisper body is on the sender's hub and the target's hub, and those are the only two in this channel"

# --- E2E11/E2E12: the operator ----------------------------------------------
view="$(_A chat show 2>/dev/null)"
assert_eq "$(printf '%s' "$view" | _j "d['machine']")" "alpha" "E2E11 the operator view names the machine it is describing"
assert_eq "$(printf '%s' "$view" | _j "any(c['name']=='pairing' for c in d['channels'])")" "True" \
    "E2E11 and shows the channel"
mem="$(printf '%s' "$view" | python3 -c "
import json,sys
c=next(x for x in json.load(sys.stdin)['channels'] if x['name']=='pairing')
loc=sorted(m['name'] for m in c['members'] if m['unread'] is not None)
rem=sorted(m['name'] for m in c['members'] if m['unread'] is None)
print(f'{loc}|{rem}')")"
assert_eq "$mem" "['dev-cursor', 'dev-third']|['dev-claude']" \
    "E2E11 with local members' unread depth and a remote member's reported as unknown rather than guessed"
idle="$(printf '%s' "$view" | python3 -c "
import json,sys
print(all(isinstance(s['idle_ms'], int) for s in json.load(sys.stdin)['sessions']))")"
assert_eq "$idle" "True" "E2E11 and idle time for every session, the input to eviction"

log="$(_A chat audit --limit 50 2>/dev/null)"
assert_eq "$(printf '%s' "$log" | _j "any(e['event']=='whisper' and e['subject']=='dev-claude' for e in d['entries'])")" \
    "True" "E2E12 the audit log records the whisper and who it was between"
leaked=""
for body in 'WHISPER-BODY' 'MENTION-BODY' 'what test framework' 'vitest'; do
    if printf '%s' "$log" | grep -qF "$body"; then leaked="${leaked} ${body}"; fi
done
if [[ -n "$leaked" ]]; then
    fail "E2E12 a message body reached the audit log:${leaked}"
else
    pass "E2E12 and no message body is in it, whispered or not"
fi

# --- E2E13: retention -------------------------------------------------------
# Everyone on hub A acknowledges; the messages are aged past the TTL; trim runs.
for who in dev-cursor dev-third; do
    d="$(_A chat inbox --name "$who" 2>/dev/null | _j "d['delivered_seq']")"
    [[ "${d:-0}" -gt 0 ]] && _A chat ack --name "$who" --cursor "$d" >/dev/null 2>&1
done
before="$(_sql "${_TMPD}/A/chat.db" "SELECT COUNT(*) FROM message")"
python3 -c "
import sqlite3,sys
c=sqlite3.connect('${_TMPD}/A/chat.db')
c.execute('UPDATE message SET received_at = ?', (1,))   # ancient
c.commit()"
curl -sS -X POST "${BA}/jobs/run" >/dev/null 2>&1
after_all="$(_sql "${_TMPD}/A/chat.db" "SELECT COUNT(*) FROM message")"
assert_eq "$after_all" "[(0,)]" "E2E13 retention removes what every live local member has acknowledged and aged past its TTL"
if [[ "$before" == "[(0,)]" ]]; then
    fail "E2E13 there was nothing to remove, so the assertion proved nothing"
else
    pass "E2E13 and there was something to remove (${before} before), so that assertion means something"
fi

# A message nobody has acknowledged must survive the same job.
_A chat send --name dev-cursor --body 'unread and ancient' >/dev/null 2>&1
python3 -c "
import sqlite3
c=sqlite3.connect('${_TMPD}/A/chat.db')
c.execute('UPDATE message SET received_at = ?', (1,))
c.commit()"
curl -sS -X POST "${BA}/jobs/run" >/dev/null 2>&1
assert_eq "$(_sql "${_TMPD}/A/chat.db" "SELECT COUNT(*) FROM message")" "[(1,)]" \
    "E2E13 and keeps one that a live member has not acknowledged, however old"

# --- E2E14: the far hub goes away and comes back ----------------------------
_kill_own B
sleep 1.2
_A chat send --name dev-cursor --body 'sent while beta was down' >/dev/null 2>&1
sleep 0.5
queued="$(curl -sS "${BA}/outbox" 2>/dev/null | _j "d['total']")"
if [[ "${queued:-0}" -ge 1 ]]; then
    pass "E2E14 a message for the unreachable machine is queued (${queued}), not lost"
else
    fail "E2E14 nothing was queued for the unreachable machine"
fi
_B chat node start --port 0 >/dev/null 2>&1
for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -s "${_TMPD}/B/hub.port" ]] && break; sleep 0.2; done
BB="http://127.0.0.1:$(cat "${_TMPD}/B/hub.port")"
curl -sS -X POST "${BA}/peers/connect" -d "{\"machine\":\"127.0.0.1:${LINK_B}\"}" >/dev/null 2>&1
for _ in 1 2 3 4 5 6 7 8 9 10; do
    [[ "$(curl -sS "${BA}/outbox" 2>/dev/null | _j "d['total']")" == "0" ]] && break
    sleep 0.4
done
assert_eq "$(curl -sS "${BA}/outbox" 2>/dev/null | _j "d['total']")" "0" "E2E14 and the queue drains when it returns"
arrived="$(_B chat inbox --name dev-claude --cursor 0 2>/dev/null | _j "any('while beta was down' in m['body'] for m in d['messages'])")"
assert_eq "$arrived" "True" "E2E14 the message sent during the outage is delivered"

# --- E2E16: every chat call is bounded --------------------------------------
#
# Found by falsifying E2E01: pointing the chat base URL at an unreachable host did not make the CLI
# FAIL, it made it STOP -- and the test suite waiting on it stopped too, for nineteen minutes, with no
# output. A hung `aid chat` is worse than a failed one, because there is nothing to read and nothing to
# act on, and the same shape reaches a user through a stale port file.
#
# Measured before fixing: an unroutable address ran past 25s with no bound and ended at exactly 5s
# with one. Asserted statically here, because a behavioural version needs a blackhole address and not
# every environment has one -- the property is that no chat request is issued without a bound.
unbounded="$(python3 - "${REPO_ROOT}" <<'PY'
import re, sys
root = sys.argv[1]
src = open(f'{root}/bin/aid', encoding='utf-8').read()
bad = []
for m in re.finditer(r'^\s*(?:\w+="?\$\()?curl [^\n]*', src, re.M):
    line = m.group(0)
    # Only the chat calls: the installer and the dashboard have their own reasons and their own review.
    if 'hub.port' not in line and '${base}' not in line and '${BA}' not in line:
        continue
    if '--max-time' not in line and 'tmo[@]' not in line:
        bad.append(line.strip()[:70])
print('\n'.join(bad) if bad else 'all-bounded')
PY
)"
assert_eq "$unbounded" "all-bounded" \
    "E2E16 every chat HTTP call carries a timeout: an unreachable address makes the CLI fail, not hang"

# The PowerShell half, parsed rather than counted. Comparing two grep totals said the twin had six
# requests and five bounds -- because one "request" was a COMMENT mentioning Invoke-WebRequest and one
# bound belonged to the dashboard, which is a different feature entirely. Two wrong numbers that
# happened to differ by one, reported as a defect in code that was correct.
ps_unbounded="$(python3 - "${REPO_ROOT}/bin/aid.ps1" <<'PY'
import re, sys
src = open(sys.argv[1], encoding='utf-8').read()
bad = []
for n, raw in enumerate(src.split('\n'), 1):
    line = raw.strip()
    if line.startswith('#') or 'Invoke-WebRequest' not in line:
        continue
    # Only the chat calls, and only real invocations.
    if '$base' not in line and '@args' not in line:
        continue
    # `@args` is bounded by the splat that builds it, which sets TimeoutSec a few lines above.
    if '@args' in line:
        window = '\n'.join(src.split('\n')[max(0, n - 8):n])
        if 'TimeoutSec' in window:
            continue
    elif 'TimeoutSec' in line:
        continue
    bad.append(f'{n}: {line[:60]}')
print('\n'.join(bad) if bad else 'all-bounded')
PY
)"
assert_eq "$ps_unbounded" "all-bounded" "E2E16 and every chat request in the PowerShell twin is bounded too"

# --- E2E15 ------------------------------------------------------------------
_cleanup
trap - EXIT
sleep 0.3
assert_eq "$(_own_hubs)" "0" "E2E15 nothing is left running on either machine"

test_summary
