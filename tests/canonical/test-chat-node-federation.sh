#!/usr/bin/env bash
# test-chat-node-federation.sh — two hubs, replication, and the hub plane across machines.
#
# WHAT THIS SUITE IS AND IS NOT, first, because it decides what everything below is worth.
#
# It runs TWO REAL HUBS: separate processes, separate stores, separate link ports, and a real TCP
# connection between them. Everything that is a property of the PROTOCOL is therefore genuinely
# tested — the handshake, replication, the outbox, the relay, the partial roster.
#
# It does NOT test two machines. Both hubs are on loopback here, and two of this delivery's criteria
# are about a real network rather than the protocol running over one:
#
#   AC-2's full form  — the two sessions on different machines. The protocol half is covered here;
#                       the machine half is MP-09.
#   The idle link     — left idle long enough for a real network to close the connection. A loopback
#                       connection is never dropped by anything, so this cannot be simulated: the
#                       whole property is about middleboxes that this environment has none of. The
#                       plan says so itself, and calls for an overnight idle followed by a send.
#                       That is MP-10.
#
# Simulating either would be worse than deferring it. A test that closes a socket itself and then
# asserts recovery proves the reconnect path works, which is already covered — it proves nothing
# about whether the keepalive interval is short enough for the networks people actually have.
#
# Protocol and peers
#   FD01  the protocol version is its own number, not the artifact's
#   FD02  a hub dials a peer by address alone: the guaranteed path, no discovery involved
#   FD03  an inbound peer is learned, without an operator naming it on both sides
#   FD04  a major version mismatch is refused explicitly, by name, and does not enter the peer list
#   FD05  minor and patch differences interoperate
#   FD06  an unreachable peer fails and backs off rather than spinning
#
# Replication (AC-13's cross-machine clause, AC-5)
#   FD07  a join replicates, and each hub holds the other's members
#   FD08  a sender with a member only on another hub is NOT refused as solo
#   FD09  a message crosses, and arrives with the sender's machine attached
#   FD10  the receiving hub keeps the sender's sender_seq verbatim and assigns its own arrival_seq
#   FD11  replication is not a loop: each hub holds each message exactly once
#   FD12  fan-out reaches members on both machines
#   FD13  a message sent while a peer is down is queued, and delivered when it returns
#   FD14  a connect request is NEVER queued, which is the deliberate asymmetry with messages
#
# The hub plane across machines (AC-34)
#   FD15  the roster spans hubs, and every agent carries the machine it sits on
#   FD16  a roster answered while a peer is down is partial AND names the peer it could not reach
#   FD17  a connect request crosses and joins the target at the channel head
#   FD18  a relayed refusal carries the real reason, not the local hub's guess
#   FD19  a hub asked for a channel name it has never seen creates its replica and joins its agent
#   FD20  a refused relay leaves no orphan channel behind
#
# FD20 is a regression test for a defect this suite found: a failed relay created the channel before
# discovering the join would be refused, leaving a channel with no members that nothing would close.
#
# Usage: bash test-chat-node-federation.sh [--verbose]

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "SKIP: node not available" >&2; exit 0; }
command -v curl >/dev/null 2>&1 || { echo "SKIP: curl not available" >&2; exit 0; }
command -v python3 >/dev/null 2>&1 || { echo "SKIP: python3 not available" >&2; exit 0; }

_TMPD="$(mktemp -d)"
export AID_CODE_HOME="$REPO_ROOT"

# Link ports are picked from an ephemeral-ish band and derived from this run's own pid, so two
# concurrent runs of this suite -- which run-all makes possible -- cannot collide on a listener.
LINK_A=$(( 18000 + (BASHPID % 2000) * 2 ))
LINK_B=$(( LINK_A + 1 ))

A_RT="${_TMPD}/A"; B_RT="${_TMPD}/B"
mkdir -p "$A_RT" "$B_RT"
BA=""; BB=""

# Only THIS suite's processes, matched by its private runtime dir. A machine-wide count is unusable
# because run-all dispatches suites concurrently.
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

_start() {  # _start <A|B> <machine-id> <link-port>
    local which="$1" mid="$2" lp="$3"
    AID_CHAT_RUNTIME="${_TMPD}/${which}" AID_CHAT_STORE="${_TMPD}/${which}/chat.db" \
        AID_CHAT_MACHINE="$mid" AID_CHAT_LINK_PORT="$lp" \
        node "${REPO_ROOT}/chat-node/server/hub.mjs" --port 0 >"${_TMPD}/${which}.log" 2>&1 &
    local tries=0
    while [[ $tries -lt 40 && ! -s "${_TMPD}/${which}/hub.port" ]]; do sleep 0.15; tries=$((tries+1)); done
    [[ -s "${_TMPD}/${which}/hub.port" ]] || return 1
    printf 'http://127.0.0.1:%s\n' "$(cat "${_TMPD}/${which}/hub.port")"
}

_j() { python3 -c "import json,sys; d=json.load(sys.stdin); print(eval(sys.argv[1]))" "$1"; }
_sql() { python3 -c "
import sqlite3,sys
c=sqlite3.connect(sys.argv[1])
print(list(c.execute(sys.argv[2])))" "$1" "$2"; }

BA="$(_start A alpha "$LINK_A")" || { echo "SKIP: hub A would not start" >&2; exit 0; }
BB="$(_start B beta  "$LINK_B")" || { echo "SKIP: hub B would not start" >&2; exit 0; }

# --- protocol and peers -----------------------------------------------------
proto="$(curl -sS "${BA}/protocol" 2>/dev/null | _j "d['protocol']")"
artifact="$(head -1 "${REPO_ROOT}/VERSION" 2>/dev/null || echo unknown)"
if [[ "$proto" != "$artifact" ]]; then
    pass "FD01 the protocol version (${proto}) is its own number, not the artifact's (${artifact})"
else
    fail "FD01 the protocol version equals the artifact version, so one moves when the other does"
fi

dial="$(curl -sS -X POST "${BA}/peers/connect" -d "{\"machine\":\"127.0.0.1:${LINK_B}\"}" 2>/dev/null)"
assert_eq "$(printf '%s' "$dial" | _j "d['ok']")" "True" "FD02 a hub dials a peer by address alone, with no discovery involved"
sleep 0.5
assert_eq "$(curl -sS "${BA}/peers" 2>/dev/null | _j "[p['state'] for p in d['peers']]")" "['reachable']" \
    "FD02 and the peer is reachable once the handshake completes"

b_peers="$(curl -sS "${BB}/peers" 2>/dev/null | _j "[(p['source'], p['state']) for p in d['peers']]")"
assert_eq "$b_peers" "[('discovered', 'reachable')]" \
    "FD03 the dialled hub learned the dialler without an operator naming it on both sides"

refusal="$(python3 - "$LINK_A" <<'PY'
import socket, json, sys
try:
    s = socket.create_connection(('127.0.0.1', int(sys.argv[1])), timeout=3)
    s.sendall((json.dumps({'t':'hello','protocol':'2.0.0','machine':'impostor','port':9999})+'\n').encode())
    s.settimeout(3)
    line = s.recv(4096).decode().strip().split('\n')[0]
    s.close()
    f = json.loads(line)
    print(f"{f.get('t')}:{f.get('reason')}")
except Exception as e:
    print(f'ERROR:{e}')
PY
)"
assert_eq "$refusal" "refused:protocol_major_mismatch" \
    "FD04 a major version mismatch is refused explicitly, as a frame rather than a dropped socket"
assert_output_contains "$(curl -sS "${BA}/peers" 2>/dev/null)" "127.0.0.1:${LINK_B}" "FD04 the real peer is still listed"
if curl -sS "${BA}/peers" 2>/dev/null | grep -q impostor; then
    fail "FD04 the refused impostor entered the peer list"
else
    pass "FD04 and the refused impostor did not enter the peer list"
fi

compat="$(python3 - "$LINK_A" <<'PY'
import socket, json, sys
out = []
for v in ('1.0.0', '1.4.9', '1.0.99'):
    try:
        s = socket.create_connection(('127.0.0.1', int(sys.argv[1])), timeout=3)
        s.sendall((json.dumps({'t':'hello','protocol':v,'machine':'probe','port':9000})+'\n').encode())
        s.settimeout(3)
        f = json.loads(s.recv(4096).decode().strip().split('\n')[0])
        s.close()
        out.append(f.get('t'))
    except Exception:
        out.append('error')
print(','.join(out))
PY
)"
assert_eq "$compat" "hello-ack,hello-ack,hello-ack" "FD05 minor and patch differences interoperate"
# Those probes were fake hubs: they completed a handshake, announced a port nothing listens on, and
# vanished. The hub correctly LEARNED them as peers -- a real hub that handshakes is a real hub -- so
# the litter is this test's, and it is cleaned up here rather than asserted around later.
curl -sS -X POST "${BA}/peers/remove" -d '{"machine":"127.0.0.1:9000"}' >/dev/null 2>&1

curl -sS -X POST "${BA}/peers/connect" -d '{"machine":"127.0.0.1:9"}' >/dev/null 2>&1
sleep 0.4
dead="$(curl -sS "${BA}/links" 2>/dev/null | _j "[(l['state'], l['attempt']) for l in d['links'] if l['machine']=='127.0.0.1:9']")"
assert_eq "$dead" "[('idle', 1)]" "FD06 an unreachable peer fails and schedules one backed-off retry rather than spinning"
curl -sS -X POST "${BA}/peers/remove" -d '{"machine":"127.0.0.1:9"}' >/dev/null 2>&1

# --- replication ------------------------------------------------------------
curl -sS -X POST "${BA}/session" -d '{"name":"alice","tool":"cursor","cwd":"/a"}' >/dev/null 2>&1
curl -sS -X POST "${BB}/session" -d '{"name":"bob","tool":"claude","cwd":"/b"}' >/dev/null 2>&1
curl -sS -X POST "${BA}/channel" -d '{"name":"alice","channel":"cross"}' >/dev/null 2>&1
sleep 0.4
curl -sS -X POST "${BB}/channel/join" -d '{"name":"bob","channel":"cross"}' >/dev/null 2>&1
sleep 0.5

a_remote="$(_sql "${A_RT}/chat.db" "SELECT machine, name FROM channel_member")"
b_remote="$(_sql "${B_RT}/chat.db" "SELECT machine, name FROM channel_member")"
assert_eq "$a_remote" "[('beta', 'bob')]" "FD07 a join replicates: hub A holds hub B's member"
assert_eq "$b_remote" "[('alpha', 'alice')]" "FD07 and hub B holds hub A's member"

sent="$(curl -sS -X POST "${BA}/messages" -d '{"name":"alice","body":"hello across"}' 2>/dev/null)"
assert_eq "$(printf '%s' "$sent" | _j "d['ok']")" "True" \
    "FD08 a sender whose only company is on another hub is not refused as solo"
KEY="$(printf '%s' "$sent" | _j "d['idempotency_key']")"
sleep 0.7

got="$(curl -sS "${BB}/messages?name=bob" 2>/dev/null | _j "[(m['from'], m['machine'], m['body']) for m in d['messages']]")"
assert_eq "$got" "[('alice', 'alpha', 'hello across')]" "FD09 the message crosses, with the sender's machine attached"

pair="$(python3 - "${A_RT}/chat.db" "${B_RT}/chat.db" "$KEY" <<'PY'
import sqlite3, sys
key = sys.argv[3]
out = []
for p in (sys.argv[1], sys.argv[2]):
    c = sqlite3.connect(p)
    r = c.execute('SELECT arrival_seq, sender_seq, sender_machine FROM message WHERE idempotency_key=?', (key,)).fetchone()
    out.append(r)
print(out)
PY
)"
sender_seqs="$(printf '%s' "$pair" | python3 -c "import ast,sys; r=ast.literal_eval(sys.stdin.read()); print(r[0][1], r[1][1])")"
assert_eq "$sender_seqs" "1 1" "FD10 the receiving hub kept the sender's sender_seq verbatim"
machines="$(printf '%s' "$pair" | python3 -c "import ast,sys; r=ast.literal_eval(sys.stdin.read()); print(r[0][2], r[1][2])")"
assert_eq "$machines" "alpha alpha" "FD10 and the sender's machine, so provenance survives the hop"

counts="$(python3 - "${A_RT}/chat.db" "${B_RT}/chat.db" <<'PY'
import sqlite3, sys
print(','.join(str(sqlite3.connect(p).execute('SELECT COUNT(*) FROM message').fetchone()[0]) for p in sys.argv[1:3]))
PY
)"
assert_eq "$counts" "1,1" "FD11 replication is not a loop: each hub holds the message exactly once"

# FD12 -- fan-out across machines. A third member, local to A, must also receive.
curl -sS -X POST "${BA}/session" -d '{"name":"carol","tool":"cursor","cwd":"/c"}' >/dev/null 2>&1
curl -sS -X POST "${BA}/channel/join" -d '{"name":"carol","channel":"cross"}' >/dev/null 2>&1
sleep 0.4
curl -sS -X POST "${BA}/messages" -d '{"name":"alice","body":"to both machines"}' >/dev/null 2>&1
sleep 0.7
c_got="$(curl -sS "${BA}/messages?name=carol" 2>/dev/null | _j "any(m['body']=='to both machines' for m in d['messages'])")"
b_got="$(curl -sS "${BB}/messages?name=bob" 2>/dev/null | _j "any(m['body']=='to both machines' for m in d['messages'])")"
assert_eq "${c_got},${b_got}" "True,True" "FD12 fan-out reaches members on both machines"

# FD13 -- the outbox. B goes away, a message is sent, B returns and the queue drains.
_kill_own B
sleep 1.2
curl -sS -X POST "${BA}/messages" -d '{"name":"alice","body":"sent while beta was down"}' >/dev/null 2>&1
sleep 0.5
queued="$(curl -sS "${BA}/outbox" 2>/dev/null | _j "d['total']")"
if [[ "${queued:-0}" -ge 1 ]]; then
    pass "FD13 a message for an unreachable peer is queued (${queued} item(s)), not dropped"
else
    fail "FD13 nothing was queued for the unreachable peer, so the message was lost"
fi

BB="$(_start B beta "$LINK_B")" || fail "FD13 hub B would not restart"
curl -sS -X POST "${BA}/peers/connect" -d "{\"machine\":\"127.0.0.1:${LINK_B}\"}" >/dev/null 2>&1
# The drain is triggered by the link coming up, so give it a moment rather than a fixed guess.
for _ in 1 2 3 4 5 6 7 8 9 10; do
    [[ "$(curl -sS "${BA}/outbox" 2>/dev/null | _j "d['total']")" == "0" ]] && break
    sleep 0.4
done
assert_eq "$(curl -sS "${BA}/outbox" 2>/dev/null | _j "d['total']")" "0" "FD13 and the queue drains once the peer returns"
late="$(curl -sS "${BB}/messages?name=bob" 2>/dev/null | _j "any(m['body']=='sent while beta was down' for m in d['messages'])")"
assert_eq "$late" "True" "FD13 the message sent during the outage is delivered"

# --- the hub plane across machines -----------------------------------------
roster="$(curl -sS "${BA}/roster?name=alice" 2>/dev/null)"
assert_eq "$(printf '%s' "$roster" | _j "sorted({a['machine'] for a in d['agents']})")" "['alpha', 'beta']" \
    "FD15 the roster spans both hubs, and every agent carries the machine it sits on"
assert_eq "$(printf '%s' "$roster" | _j "d['partial']")" "False" "FD15 and is not partial while both peers answer"

_kill_own B
sleep 1.2
partial="$(curl -sS "${BA}/roster?name=alice" 2>/dev/null)"
assert_eq "$(printf '%s' "$partial" | _j "d['partial']")" "True" \
    "FD16 a roster answered while a peer is down reports itself partial"
assert_eq "$(printf '%s' "$partial" | _j "[p['machine'] for p in d['unreachable_peers']]")" "['127.0.0.1:${LINK_B}']" \
    "FD16 and NAMES the peer it could not reach, rather than silently omitting its agents"

# FD14 -- a connect request is never queued, even with the peer down.
curl -sS -X POST "${BA}/session" -d '{"name":"dave","tool":"cursor","cwd":"/d"}' >/dev/null 2>&1
curl -sS -X POST "${BA}/channel" -d '{"name":"dave","channel":"waiting"}' >/dev/null 2>&1
before_kinds="$(_sql "${A_RT}/chat.db" "SELECT DISTINCT kind FROM outbox")"
curl -sS -X POST "${BA}/connect" -d '{"name":"dave","target":"bob"}' >/dev/null 2>&1
sleep 0.4
after_kinds="$(_sql "${A_RT}/chat.db" "SELECT DISTINCT kind FROM outbox")"
if printf '%s' "$after_kinds" | grep -q connect; then
    fail "FD14 a connect request was queued: ${after_kinds}"
else
    pass "FD14 a connect request is never queued, unlike a message (outbox kinds: ${after_kinds:-none})"
fi

# FD17 to FD20 -- the relay, with B back up.
BB="$(_start B beta "$LINK_B")" || fail "FD17 hub B would not restart"
curl -sS -X POST "${BA}/peers/connect" -d "{\"machine\":\"127.0.0.1:${LINK_B}\"}" >/dev/null 2>&1
sleep 0.8
curl -sS -X POST "${BB}/session" -d '{"name":"bob","tool":"claude","cwd":"/b"}' >/dev/null 2>&1
curl -sS -X POST "${BB}/channel/leave" -d '{"name":"bob"}' >/dev/null 2>&1
sleep 0.4

relayed="$(curl -sS -X POST "${BA}/connect" -d '{"name":"dave","target":"bob"}' 2>/dev/null)"
assert_eq "$(printf '%s' "$relayed" | _j "(d['ok'], d.get('relayed'))")" "(True, True)" \
    "FD17 a connect request crosses machines and succeeds"
sleep 0.5
mine="$(curl -sS "${BB}/channels?name=bob" 2>/dev/null | _j "[c['name'] for c in d['channels'] if c['is_mine']]")"
assert_eq "$mine" "['waiting']" "FD17 and the target is in the asker's channel on its own hub"
depth="$(curl -sS "${BB}/messages?name=bob" 2>/dev/null | _j "len(d['messages'])")"
assert_eq "$depth" "0" "FD17 joined at the channel head: no backfill of what was said before it arrived"

# FD18 -- a relayed refusal carries the real reason.
curl -sS -X POST "${BA}/session" -d '{"name":"erin","tool":"cursor","cwd":"/e"}' >/dev/null 2>&1
curl -sS -X POST "${BA}/channel" -d '{"name":"erin","channel":"erins"}' >/dev/null 2>&1
busy="$(curl -sS -X POST "${BA}/connect" -d '{"name":"erin","target":"bob"}' 2>/dev/null)"
assert_eq "$(printf '%s' "$busy" | _j "d['detail']")" "already in a channel" \
    "FD18 a relayed refusal carries the target hub's real reason, not the local hub's guess"

# FD19 and FD20 -- a name the target hub has never seen, and no orphan from a refused relay.
before_ch="$(_sql "${B_RT}/chat.db" "SELECT name FROM channel")"
curl -sS -X POST "${BB}/channel/leave" -d '{"name":"bob"}' >/dev/null 2>&1
sleep 0.3
fresh="$(curl -sS -X POST "${BA}/connect" -d '{"name":"erin","target":"bob"}' 2>/dev/null)"
assert_eq "$(printf '%s' "$fresh" | _j "d['ok']")" "True" "FD19 a relay naming a channel the target hub has never seen succeeds"
sleep 0.5
after_ch="$(_sql "${B_RT}/chat.db" "SELECT name FROM channel")"
assert_output_contains "$after_ch" "erins" "FD19 and that hub created its local replica of the name"

orphans="$(python3 - "${B_RT}/chat.db" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1])
bad = []
for cid, name in c.execute('SELECT id, name FROM channel'):
    loc = c.execute('SELECT COUNT(*) FROM session WHERE channel_id=?', (cid,)).fetchone()[0]
    rem = c.execute('SELECT COUNT(*) FROM channel_member WHERE channel_id=?', (cid,)).fetchone()[0]
    if loc == 0 and rem == 0:
        bad.append(name)
print(','.join(bad) if bad else 'none')
PY
)"
assert_eq "$orphans" "none" "FD20 no channel is left with neither a local nor a remote member: a refused relay leaves no orphan"

# Non-automated checks are enumerated, not implied.
for mp in MP-09 MP-10; do
    assert_file_contains "${REPO_ROOT}/chat-node/tests/MANUAL-PROCEDURES.md" "$mp" \
        "the checks needing a real network are recorded as ${mp}, by name and with steps"
done

# Tear down FIRST, then measure, since the EXIT trap runs after this line.
_cleanup
trap - EXIT
sleep 0.3
assert_eq "$(_own_hubs)" "0" "the suite leaves none of its own hub processes behind"

test_summary
