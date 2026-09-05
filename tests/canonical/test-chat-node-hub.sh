#!/usr/bin/env bash
# test-chat-node-hub.sh — the hub plane: roster, and the connect request answered from state.
#
# The hub plane is SIGNALLING, not messaging, and it exists to break one specific deadlock: two
# idle agents each waiting to be told to talk, neither able to tell the other, because telling
# needs a channel and a channel needs somebody to have been told. These cases are all about
# whether that deadlock is actually broken.
#
# Roster (AC-27)
#   HP01  an agent in no channel is available to every other agent
#   HP02  an agent in a channel is unavailable
#   HP03  an agent quiet past the stale threshold is unavailable, AND its channel stays open
#   HP04  no `available` column exists; the roster computes it
#   HP05  the roster carries name, tool, capabilities and liveness, not just availability
#
# Connect (AC-28)
#   HP06  a request at an available agent joins it to the asker's channel
#   HP07  the target learns on its NEXT CALL OF ANY KIND, not only on a wake
#   HP08  the target joins at the channel HEAD, with no backfill
#   HP09  a request at an agent already in a channel fails at once, exit 14
#   HP10  a request at an unknown agent fails the same way, with the same token
#   HP11  a request at a stale agent fails the same way
#   HP12  a request from a session in no channel is refused with its own reason
#   HP13  a request naming itself is refused with its own reason
#   HP14  no pending-invitation state exists anywhere after either outcome
#   HP15  no approval prompt is raised: the whole exchange is two calls and no third party
#
# Reciprocal (FR-9.6)
#   HP16  two agents that each open a channel and then request the other BOTH fail as busy,
#         ordered around an explicit barrier rather than raced
#   HP17  neither ends up in the other's channel
#   HP18  the refusal carries a JITTERED retry hint, so two agents cannot fail in lockstep
#
# Surface boundary (FR-7.3)
#   HP19  the verbs added are exactly the roster and the connect request
#   HP20  no administrative verb entered the agent-facing set
#
# HP16 is ordered, not raced: a race would pass or fail depending on scheduling, and a test
# whose result depends on scheduling cannot tell a correct implementation from a lucky one.
#
# Usage: bash test-chat-node-hub.sh [--verbose]

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "SKIP: node not available" >&2; exit 0; }
command -v curl >/dev/null 2>&1 || { echo "SKIP: curl not available" >&2; exit 0; }

_TMPD="$(mktemp -d)"
# Count only THIS suite's own hub processes, by matching the private runtime dir in each
# process's environment. A machine-wide count is NOT usable here: tests/run-all.sh dispatches
# suites concurrently under `xargs -P`, so a sibling suite's healthy node would read as this
# suite's leak. Scoping to `_TMPD` -- unique per run via mktemp -- makes the check both precise
# and parallel-safe, and it asks the question that actually matters: did *this* suite clean up?
_own_hubs() {
    local n=0 p
    for p in $(pgrep -f 'server/hub.mjs' 2>/dev/null); do
        if tr '\0' '\n' < "/proc/${p}/environ" 2>/dev/null | grep -q "^AID_CHAT_RUNTIME=${_TMPD}"; then
            n=$((n + 1))
        fi
    done
    printf '%s\n' "$n"
}

export AID_CODE_HOME="$REPO_ROOT"
export AID_CHAT_RUNTIME="${_TMPD}/rt"
export AID_CHAT_STORE="${_TMPD}/rt/chat.db"
AID="bash ${REPO_ROOT}/bin/aid"
_cleanup() { $AID chat node stop >/dev/null 2>&1 || true; rm -rf "${_TMPD}"; }
trap _cleanup EXIT

_field() { python3 -c "import json,sys; d=json.load(sys.stdin); print(eval('d'+sys.argv[1]))" "$1"; }
_agent() {  # _agent <roster-json-on-stdin> <name> <field>
    python3 -c "
import json,sys
a=[x for x in json.load(sys.stdin)['agents'] if x['name']==sys.argv[1]]
print(a[0][sys.argv[2]] if a else 'ABSENT')" "$1" "$2"
}

$AID chat node start --port 0 >/dev/null 2>&1
for n in alice bob carol quiet; do
    curl -sS -X POST "http://127.0.0.1:$(cat "${AID_CHAT_RUNTIME}/hub.port")/session" \
        --data-binary "{\"name\":\"${n}\",\"tool\":\"cursor\",\"cwd\":\"/w\",\"capabilities\":{\"wake\":true}}" >/dev/null
done

# --- roster -----------------------------------------------------------------
r=$($AID chat roster --name alice 2>/dev/null)
assert_eq "$(printf '%s' "$r" | _agent bob available)" "True" "HP01 an agent in no channel is available to every other agent"
assert_eq "$(printf '%s' "$r" | _agent alice is_self)" "True" "HP01 the roster marks which entry is the caller"

$AID chat open --name carol --channel busywork >/dev/null 2>&1
r=$($AID chat roster --name alice 2>/dev/null)
assert_eq "$(printf '%s' "$r" | _agent carol available)" "False" "HP02 an agent in a channel is unavailable"
assert_eq "$(printf '%s' "$r" | _agent carol in_channel)" "True" "HP02 the roster says WHY it is unavailable"

# Make `quiet` stale by rewriting its heartbeat directly -- the alternative is sleeping past the
# threshold, and a test that sleeps for a real 30 minutes is a test nobody runs.
python3 - "$AID_CHAT_STORE" <<'PY'
import sqlite3, sys, time
c = sqlite3.connect(sys.argv[1])
c.execute('UPDATE session SET last_heartbeat_at = ? WHERE name = ?', (int(time.time()*1000) - 3600_000, 'quiet'))
c.commit(); c.close()
PY
$AID chat open --name quiet --channel abandoned >/dev/null 2>&1
python3 - "$AID_CHAT_STORE" <<'PY'
import sqlite3, sys, time
c = sqlite3.connect(sys.argv[1])
c.execute('UPDATE session SET last_heartbeat_at = ? WHERE name = ?', (int(time.time()*1000) - 3600_000, 'quiet'))
c.commit(); c.close()
PY
r=$($AID chat roster --name alice 2>/dev/null)
assert_eq "$(printf '%s' "$r" | _agent quiet stale)" "True" "HP03 an agent quiet past the stale threshold is stale"
assert_eq "$(printf '%s' "$r" | _agent quiet available)" "False" "HP03 and therefore unavailable"
chan_open=$($AID chat list --name alice 2>/dev/null | python3 -c "import json,sys; print(any(c['name']=='abandoned' for c in json.load(sys.stdin)['channels']))")
assert_eq "$chan_open" "True" "HP03 a stale agent's channel stays OPEN: stale is not gone"

cols=$(python3 -c "
import sqlite3,sys
c=sqlite3.connect('${AID_CHAT_STORE}')
print(','.join(r[1] for r in c.execute(\"PRAGMA table_info('session')\")))")
if [[ ",${cols}," == *",available,"* ]]; then
    fail "HP04 an 'available' column exists; it must be computed, not stored"
else
    pass "HP04 no 'available' column exists: availability is computed at read time"
fi

r=$($AID chat roster --name alice 2>/dev/null)
shape=$(printf '%s' "$r" | python3 -c "
import json,sys
a=[x for x in json.load(sys.stdin)['agents'] if x['name']=='bob'][0]
need=('name','tool','capabilities','quiet_for_ms','stale','in_channel','available')
print(','.join(k for k in need if k not in a) or 'complete')")
assert_eq "$shape" "complete" "HP05 the roster carries name, tool, capabilities and liveness, not only availability"
caps=$(printf '%s' "$r" | python3 -c "
import json,sys
print([x for x in json.load(sys.stdin)['agents'] if x['name']=='bob'][0]['capabilities'].get('wake'))")
assert_eq "$caps" "True" "HP05 declared capabilities survive the round trip"

# --- connect ----------------------------------------------------------------
err=$($AID chat connect --name alice --target bob 2>&1 >/dev/null); rc=$?
assert_eq "$rc" "14" "HP12 a request from a session in no channel is refused, exit 14"
assert_output_contains "$err" "no_channel" "HP12 the refusal has its own reason, distinct from the target's"

$AID chat open --name alice --channel standup >/dev/null 2>&1
err=$($AID chat connect --name alice --target alice 2>&1 >/dev/null); rc=$?
assert_eq "$rc" "14" "HP13 a request naming itself is refused, exit 14"
assert_output_contains "$err" "target_is_self" "HP13 with its own reason"

$AID chat send --name alice --body 'said before bob arrived' >/dev/null 2>&1
out=$($AID chat connect --name alice --target bob 2>/dev/null); rc=$?
assert_eq "$rc" "0" "HP06 a request at an available agent succeeds"
assert_eq "$(printf '%s' "$out" | _field "['connected']")" "bob" "HP06 the answer names who was connected"
assert_eq "$(printf '%s' "$out" | _field "['channel']")" "standup" "HP06 into the asker's own channel, which it never had to name"

# The target learns on its next call of ANY kind. `heartbeat` is the weakest possible call --
# it asks nothing about channels -- so if the outcome is durable state rather than an event,
# even a re-register or a list reveals it.
learned=$($AID chat register --name bob --tool cursor 2>/dev/null | _field "['channel']")
assert_eq "$learned" "standup" "HP07 the target learns on its next call of any kind, not only on a wake"
# And specifically on the WEAKEST call there is. `heartbeat` asks nothing about channels, and an
# idle agent doing nothing but keeping itself alive is exactly the caller most likely to be
# relying on this -- so if `heartbeat` did not report it, "any kind" would be false where it
# matters most. It returned a bare ok() until the gate caught it.
hb=$($AID chat heartbeat --name bob 2>/dev/null | _field "['channel']")
assert_eq "$hb" "standup" "HP07 even a bare heartbeat -- the weakest call -- reveals the connect outcome"
mine=$($AID chat list --name bob 2>/dev/null | python3 -c "
import json,sys
print([c['name'] for c in json.load(sys.stdin)['channels'] if c['is_mine']])")
assert_eq "$mine" "['standup']" "HP07 and the channel is reported as its own"

depth=$($AID chat inbox --name bob 2>/dev/null | _field "['messages'].__len__()")
assert_eq "$depth" "0" "HP08 the target joins at the channel HEAD: no backfill of what was said before it arrived"

err=$($AID chat connect --name alice --target bob 2>&1 >/dev/null); rc=$?
assert_eq "$rc" "14" "HP09 a request at an agent already in a channel fails at once, exit 14"
assert_output_contains "$err" "target_unavailable" "HP09 with the target-unavailable token"

err=$($AID chat connect --name alice --target nobody-here 2>&1 >/dev/null); rc=$?
assert_eq "$rc" "14" "HP10 a request at an unknown agent fails, exit 14"
assert_output_contains "$err" "target_unavailable" "HP10 with the SAME token as a busy target: an asker learns it cannot connect, not who exists"

err=$($AID chat connect --name alice --target quiet 2>&1 >/dev/null); rc=$?
assert_eq "$rc" "14" "HP11 a request at a stale agent fails, exit 14"
assert_output_contains "$err" "target_unavailable" "HP11 with the same token again"

tables=$(python3 -c "
import sqlite3
c=sqlite3.connect('${AID_CHAT_STORE}')
print(','.join(sorted(r[0] for r in c.execute(\"SELECT name FROM sqlite_master WHERE type='table'\"))))")
if [[ "$tables" == *invit* || "$tables" == *pending* || "$tables" == *request* ]]; then
    fail "HP14 a pending-invitation table exists: ${tables}"
else
    pass "HP14 no pending-invitation state exists anywhere: the store has only ${tables}"
fi

# HP15 -- "no approval prompt at either end" is a claim about what the product DOES NOT DO, so
# it is asserted structurally: the successful exchange above was two CLI calls, and neither the
# node nor the CLI has any code path that waits for a third party to answer. A prompt would have
# to be a read of stdin or a blocking wait; there is neither.
# Comments are STRIPPED before searching. An earlier version grepped the whole file and matched the
# word "confirm" inside a comment explaining why something is NOT confirmed -- so the guard failed on
# prose that agreed with it. A check that can be tripped by its own explanation is a check that will
# be quietly reworded around rather than trusted.
prompts=$(python3 - "${REPO_ROOT}/chat-node/server" <<'PY'
import os, re, sys
pat = re.compile(r'read -[rp]|AskUser|confirm|prompt', re.I)
hits = 0
for fn in ('core.mjs', 'hub.mjs'):
    src = open(os.path.join(sys.argv[1], fn), encoding='utf-8').read()
    src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)        # block comments
    src = re.sub(r'^\s*//.*$', '', src, flags=re.M)         # whole-line comments
    src = re.sub(r'\s//.*$', '', src, flags=re.M)           # trailing comments
    hits += len(pat.findall(src))
print(hits)
PY
)
assert_eq "$prompts" "0" "HP15 no approval prompt exists in the connect path: nothing reads stdin or waits for a third party"

# --- reciprocal -------------------------------------------------------------
# Ordered around an explicit barrier: BOTH agents open their own channel first (the barrier),
# and only then does each request the other. That is the exact interleaving FR-9.6 describes,
# and ordering it means the result cannot depend on scheduling.
for n in recip1 recip2; do $AID chat register --name $n --tool cursor >/dev/null 2>&1; done
$AID chat open --name recip1 --channel r1 >/dev/null 2>&1
$AID chat open --name recip2 --channel r2 >/dev/null 2>&1      # <-- barrier: both are now busy
e1=$($AID chat connect --name recip1 --target recip2 2>&1 >/dev/null); rc1=$?
e2=$($AID chat connect --name recip2 --target recip1 2>&1 >/dev/null); rc2=$?
assert_eq "${rc1},${rc2}" "14,14" "HP16 two reciprocal requests BOTH fail as busy"
assert_output_contains "$e1" "target_unavailable" "HP16 the first fails with target_unavailable"
assert_output_contains "$e2" "target_unavailable" "HP16 and so does the second"

where=$($AID chat list --name recip1 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)['channels']
print(sorted((c['name'], sorted(c['members'])) for c in d if c['name'] in ('r1','r2')))")
assert_eq "$where" "[('r1', ['recip1']), ('r2', ['recip2'])]" "HP17 neither ended up in the other's channel: each is still alone in its own"

# HP18 -- the retry hint must be jittered. Sampled rather than assumed: identical hints across
# several refusals would mean two agents could retry in step and fail each other indefinitely.
hints=$(for _ in 1 2 3 4 5 6; do
    curl -sS -X POST "http://127.0.0.1:$(cat "${AID_CHAT_RUNTIME}/hub.port")/connect" \
        --data-binary '{"name":"recip1","target":"recip2"}' 2>/dev/null \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('retry_after_ms'))"
done | sort -u | wc -l | tr -d ' ')
if [[ "$hints" -gt 1 ]]; then
    pass "HP18 the retry hint is jittered (${hints} distinct values in 6 refusals), so two agents cannot fail in lockstep"
else
    fail "HP18 the retry hint is constant across refusals; two agents can retry in step forever"
fi

# HP22 -- the retry hint must REACH a caller. It existed in the node and was dropped by the CLI,
# which means the livelock it prevents was still there for every agent using that surface. Both
# channels are checked: prose on stderr for a human, and JSON on stdout for a program.
e=$($AID chat connect --name recip1 --target recip2 2>&1 >/dev/null)
assert_output_contains "$e" "retry after" "HP22 the refusal tells a human when to retry"
hint=$($AID chat connect --name recip1 --target recip2 2>/dev/null | _field "['retry_after_ms']")
if [[ "$hint" =~ ^[0-9]+$ ]] && [[ "$hint" -ge 250 && "$hint" -le 1000 ]]; then
    pass "HP22 and gives a program a machine-readable hint in range (${hint}ms)"
else
    fail "HP22 the retry hint did not reach stdout as a number in range: '${hint}'"
fi

# HP23 -- a refusal keeps stdout machine-readable, exactly as a success does. A caller should not
# need two parsing strategies depending on the outcome.
# `set -o pipefail` is on, so putting the CLI in a pipeline makes the pipeline's status the
# CLI's 14 and not the parser's verdict -- which is what two earlier versions of this assertion
# actually measured. Take the output first, then parse it as a separate command.
_refusal_out="$($AID chat connect --name recip1 --target recip2 2>/dev/null || true)"
_json_ok=0
printf '%s' "$_refusal_out" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null || _json_ok=1
assert_eq "${_json_ok}" "0" "HP23 stdout parses as JSON on refusal as well as on success"

# HP24 -- THE TWO CLI TWINS CARRY THE SAME VERB SET. This is a text-level comparison and needs no
# PowerShell, which is the point: the real parity suite skips in every environment without an
# interpreter, and that skip is what let a whole verb -- `subscribe` -- ship in bin/aid and be
# entirely absent from bin/aid.ps1 through a full delivery and its gate.
#
# It does not prove the two behave alike. It proves neither has a verb the other lacks, which is the
# single most likely way for them to diverge and the one that costs a user a missing feature rather
# than a subtle difference.
twin_sync="$(python3 - "${REPO_ROOT}" <<'PY'
import re, sys
root = sys.argv[1]
bash = open(f'{root}/bin/aid', encoding='utf-8').read()
ps1  = open(f'{root}/bin/aid.ps1', encoding='utf-8').read()
# Both the SHARED dispatch list and every SEPARATELY dispatched verb.
#
# Reading only the shared list is how this guard missed `hook`: it was added to bin/aid with its own
# case arm and to bin/aid.ps1 with its own branch, so deleting the PowerShell branch entirely still
# reported 'in-sync'. A guard against a missing verb that cannot see half the dispatch shapes is a
# guard that passes at exactly the wrong moment.
# Anchored on the DISPATCH ITSELF rather than on two verb names happening to sit next to each other.
# The previous anchor was the literal `register|heartbeat`, which broke the moment a verb was added
# between them: the regex missed, the comparison reported DISPATCH-NOT-FOUND, and a guard that cannot
# find what it compares is a guard that has stopped guarding.
bm = re.search(r'^\s{8}([a-z|-]+)\)\n\s+shift\n\s+_cmd_chat_plane', bash, re.M)
pm = re.search(r"\$action -in @\(([^)]*)\)", ps1)
if not bm or not pm:
    print('DISPATCH-NOT-FOUND'); raise SystemExit
bv = set(bm.group(1).split('|'))
pv = set(pm.group(1).replace("'", '').replace(' ', '').split(','))

# Separately dispatched: a bare `        <verb>)` arm inside the chat dispatcher, and its
# `$action -eq '<verb>'` counterpart. Sliced to the chat command so unrelated dispatchers stay out.
# Each side sliced to ITS OWN dispatcher, or the scan picks up local `$action` comparisons inside
# unrelated helpers -- the hook generator's own `--check` parsing was caught that way.
bm2 = re.search(r'^_cmd_chat_ctl\(\) \{.*?^\}', bash, re.M | re.S)
pm2 = re.search(r'^function script:Invoke-AidChatCtl \{.*?^\}', ps1, re.M | re.S)
if not bm2 or not pm2:
    print('CHAT-DISPATCHER-NOT-FOUND'); raise SystemExit
bv |= set(re.findall(r'^        ([a-z][a-z-]*)\)$', bm2.group(0), re.M))
pv |= set(re.findall(r"\$action -eq '([a-z][a-z-]*)'", pm2.group(0)))
# The `aid chat node <x>` lifecycle sub-verbs are a separate surface with its own shape in each twin,
# asserted by the lifecycle suite rather than here. `node`/`help` are shapes, not plane verbs.
for shape in ('node', 'help', 'start', 'stop', 'status', ''):
    bv.discard(shape); pv.discard(shape)
if bv == pv:
    print(f'in-sync:{len(bv)}')
else:
    only_bash = sorted(bv - pv)
    only_ps1 = sorted(pv - bv)
    print(f'DIVERGED bash-only={only_bash} ps1-only={only_ps1}')
PY
)"
case "$twin_sync" in
    in-sync:*) pass "HP24 both CLI twins carry the same chat verb set (${twin_sync#in-sync:} verbs)" ;;
    *)         fail "HP24 the CLI twins have diverged: ${twin_sync}" ;;
esac

# HP25 -- EVERY CHAT VERB IS COVERED BY A MANUAL PROCEDURE. Not because a procedure is as good as a
# test, but because the PowerShell twins cannot be executed here at all, and the only honest handling
# of a check this environment cannot perform is to make the SET of them countable. Nine verbs had no
# procedure and so were neither executed nor recorded as needing execution -- including `subscribe`,
# which is the one that had already shipped missing from a twin.
#
# This fails when a verb is ADDED without being recorded, which is exactly when it would otherwise be
# forgotten.
uncovered="$(python3 - "${REPO_ROOT}" <<'PY'
import re, sys
root = sys.argv[1]
src = open(f'{root}/bin/aid', encoding='utf-8').read()
# Anchored on the dispatch structure, not on two verb names being adjacent: the literal anchor broke
# the moment a verb was inserted between them, and reported DISPATCH-NOT-FOUND rather than a miss.
m = re.search(r'^\s{8}([a-z|-]+)\)\n\s+shift\n\s+_cmd_chat_plane', src, re.M)
if not m:
    print('DISPATCH-NOT-FOUND'); raise SystemExit
verbs = sorted(set(m.group(1).split('|'))) + ['node start', 'node stop', 'node status']
mp = open(f'{root}/chat-node/tests/MANUAL-PROCEDURES.md', encoding='utf-8').read()
missing = [v for v in verbs if f'chat {v}' not in mp]
print(' '.join(missing) if missing else 'all-covered')
PY
)"
assert_eq "$uncovered" "all-covered" \
    "HP25 every chat verb appears in a manual procedure, so the set of unexecuted checks is countable"

# --- surface boundary -------------------------------------------------------
# The agent-facing surface is a SKILL that omits things, and that skill is a later delivery's
# artifact. What is checkable here is the CLI's own plane-verb set: this delivery must have added
# exactly the roster and the connect request, and no administrative verb.
#
# Compared as a SET against an explicit expected list, rather than as one contiguous literal string.
# The literal form asserted that the verbs sat in a fixed ORDER as well as a fixed set, so inserting a
# verb anywhere but the end failed the check for the wrong reason -- and the failure said the set had
# changed shape when only its spelling had. The ratchet is unchanged in strength: an unexpected verb
# still fails, because the expected set is written out here in full.
verbs="$(python3 - "${REPO_ROOT}" <<'PY'
import re, sys
src = open(f'{sys.argv[1]}/bin/aid', encoding='utf-8').read()
m = re.search(r'^\s{8}([a-z|-]+)\)\n\s+shift\n\s+_cmd_chat_plane', src, re.M)
print('|'.join(sorted(m.group(1).split('|'))) if m else 'DISPATCH-NOT-FOUND')
PY
)"
expected="$(printf '%s\n' ack audit connect evict heartbeat inbox join leave list open peers register \
    rename reap retention roster send show subscribe | sort -u | paste -sd'|' -)"
assert_eq "$verbs" "$expected" \
    "HP19 the plane-verb set is exactly the expected one -- a new verb must be added here deliberately"
# HP20 -- THE BOUNDARY IS THE SKILL, NOT THE CLI, and this assertion used to have that backwards.
#
# It listed `evict` and `retention` as sentinels for "administrative" and failed if either appeared in
# the CLI at all -- which was a usable proxy while the agent-facing skill did not exist, and became
# wrong the moment the operator legitimately needed those verbs. FR-7.3 is explicit that the boundary
# is a skill that OMITS things and that it prevents nothing: any session whose host lets it run shell
# commands can invoke the whole CLI.
#
# So the real property is two-sided, and both sides are checked: the operator verbs must EXIST on the
# CLI, because an operator with no way to evict or set retention has no remedy at all; and they must be
# ABSENT from the skill, which is what the agent is told about. The skill half is asserted in detail by
# WK21-WK23 against all five rendered copies.
for admin in evict retention show audit; do
    if ! grep -qE "^        ${admin}\)" "${REPO_ROOT}/bin/aid"; then
        fail "HP20 the operator verb '${admin}' is missing from the CLI, leaving an operator without it"
    fi
    if grep -qE "^aid chat ${admin}\b" "${REPO_ROOT}/canonical/skills/aid-chat/SKILL.md"; then
        fail "HP20 the administrative verb '${admin}' is documented in the agent-facing skill"
    fi
done
pass "HP20 the operator verbs exist on the CLI and none of them is documented in the agent-facing skill"

# HP21 — this suite leaves no hub process behind. Enforced rather than assumed, because the
# lifecycle suite was found leaking one process per run while its own comment claimed otherwise.
# Tear down FIRST, then measure. The EXIT trap runs after this line, so measuring before
# stopping would count this suite's own still-running node and report a leak that is not one.
_cleanup
trap - EXIT
sleep 0.3
_leaked="$(_own_hubs)"
if [[ "$_leaked" -eq 0 ]]; then
    pass "HP21 the suite leaves none of its own hub processes behind"
else
    fail "HP21 the suite leaked ${_leaked} of its own hub process(es)"
fi

test_summary
