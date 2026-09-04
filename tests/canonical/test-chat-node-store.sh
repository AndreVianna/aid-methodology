#!/usr/bin/env bash
# test-chat-node-store.sh — the chat node's store: schema shape, id safety, warning discipline.
#
# The store is where four requirements are either honoured or quietly lost, so each is
# asserted directly against a real database rather than inferred from the schema text:
#
#   ST01  the store opens and creates its schema from nothing
#   ST02  AUTOINCREMENT on every surrogate key: a deleted id is never reused
#   ST03  sequences start at 1 and positions at 0 — the pairing that keeps the first
#         message of a channel reachable, and makes a trim before any ack delete nothing
#   ST04  the SQLite ExperimentalWarning is suppressed on the runtimes that emit it
#   ST05  an UNRELATED experimental warning still reaches the operator (the suppression is
#         one message, not a class)
#   ST06  the three uniqueness constraints on message hold, including the sender-scoped
#         idempotency key — two senders numbering from 1 must not swallow each other
#   ST07  opening twice is idempotent (CREATE TABLE IF NOT EXISTS, no error, no data loss)
#   ST08  foreign keys are ON, so closing a channel cascades its messages away
#
# ST02 and ST06 are the two that would fail silently in production: a reused id hands one
# session another's mail, and a channel-scoped idempotency key drops a message with no error.
#
# Fast + hermetic: every case runs against an in-memory or temp-file database, binds no port.
#
# Usage: bash test-chat-node-store.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STORE="${REPO_ROOT}/chat-node/server/store.mjs"

if ! command -v node >/dev/null 2>&1; then
    echo "SKIP: node not available" >&2
    exit 0
fi
assert_file_exists "$STORE" "ST00 chat-node/server/store.mjs exists"

# Run a node snippet against the store. The snippet is fed via a temp .mjs file rather than
# `node -e`, because inline snippets have to be escaped twice -- once for the shell and once
# for JS -- and that double-escaping silently produced empty output on the first attempt here.
_TMPD="$(mktemp -d)"
trap 'rm -rf "${_TMPD}"' EXIT
_node() {  # stdin = module body; `S` is the imported store module
    { printf 'import * as S from %s;\n' "'${STORE}'"; cat; } > "${_TMPD}/snip.mjs"
    node "${_TMPD}/snip.mjs"
}

# ST01 -- opens from nothing and creates the schema.
out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
const t = db.prepare("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
    .all().map(r => r.name).filter(n => !n.startsWith('sqlite_'));
process.stdout.write(t.join(','));
JS
)
assert_eq "$out" "channel,message,session" "ST01 store opens and creates all three tables"

# ST02 -- a deleted id is never reused, on every table with a surrogate key.
out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
const ins = db.prepare('INSERT INTO channel(name,opened_at) VALUES (?,1)');
ins.run('a'); ins.run('b');
db.exec("DELETE FROM channel WHERE name='b'");
ins.run('c');
process.stdout.write(String(db.prepare('SELECT MAX(id) AS m FROM channel').get().m));
JS
)
assert_eq "$out" "3" "ST02 channel: id 2 is not reused after delete (AUTOINCREMENT)"

out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
const ins = db.prepare('INSERT INTO session(name,conversation_id,tool,cwd,registered_at,last_heartbeat_at) VALUES (?,?,?,?,1,1)');
ins.run('a', 'ca', 'claude', '/x'); ins.run('b', 'cb', 'cursor', '/x');
db.exec("DELETE FROM session WHERE name='b'");
ins.run('c', 'cc', 'cursor', '/x');
process.stdout.write(String(db.prepare('SELECT MAX(id) AS m FROM session').get().m));
JS
)
assert_eq "$out" "3" "ST02 session: id 2 is not reused after delete (AUTOINCREMENT)"

out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
db.prepare('INSERT INTO channel(name,opened_at) VALUES (?,1)').run('c');
const ins = db.prepare('INSERT INTO message(channel_id,arrival_seq,sender_name,sender_machine,sender_seq,idempotency_key,body,sent_at,received_at) VALUES (1,?,?,?,?,?,?,1,1)');
ins.run(1, 's', 'm', 1, 'k1', 'b'); ins.run(2, 's', 'm', 2, 'k2', 'b');
db.exec('DELETE FROM message WHERE arrival_seq=2');
ins.run(3, 's', 'm', 3, 'k3', 'b');
process.stdout.write(String(db.prepare('SELECT MAX(id) AS m FROM message').get().m));
JS
)
assert_eq "$out" "3" "ST02 message: id 2 is not reused after delete (AUTOINCREMENT)"

# ST03 -- the 1/0 pairing: the first message is visible to a member at position 0.
out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
db.prepare('INSERT INTO channel(name,opened_at) VALUES (?,1)').run('c');
const nx = db.prepare('SELECT next_seq FROM channel WHERE id=1').get().next_seq;
db.prepare('INSERT INTO message(channel_id,arrival_seq,sender_name,sender_machine,sender_seq,idempotency_key,body,sent_at,received_at) VALUES (1,?,?,?,1,?,?,1,1)')
    .run(nx, 's', 'm', 'k', 'b');
const visible = db.prepare('SELECT COUNT(*) AS n FROM message WHERE channel_id=1 AND arrival_seq > 0').get().n;
const trimmed = db.prepare('SELECT COUNT(*) AS n FROM message WHERE channel_id=1 AND arrival_seq <= 0').get().n;
process.stdout.write(nx + ':' + visible + ':' + trimmed);
JS
)
assert_eq "$out" "1:1:0" "ST03 next_seq starts at 1; first message visible above position 0; nothing selected for trim at 0"

# ST04 -- the SQLite warning is suppressed. stderr must be empty on a plain open.
err_bytes=$(_node <<'JS' 2>&1 >/dev/null | wc -c | tr -d ' '
const db = await S.openStore({ path: ':memory:' });
db.close();
JS
)
if [[ "$err_bytes" == "0" ]]; then
    pass "ST04 opening the store writes nothing to stderr (SQLite ExperimentalWarning suppressed)"
else
    fail "ST04 opening the store wrote ${err_bytes} bytes to stderr; expected none"
fi

# ST05 -- but an unrelated experimental warning still gets through.
n=$(_node <<'JS' 2>&1 >/dev/null | grep -c 'a different experimental thing'
const db = await S.openStore({ path: ':memory:' });
db.close();
process.emitWarning('a different experimental thing', 'ExperimentalWarning');
JS
)
if [[ "$n" == "1" ]]; then
    pass "ST05 an unrelated ExperimentalWarning still reaches stderr (one message suppressed, not a class)"
else
    fail "ST05 an unrelated ExperimentalWarning was swallowed (suppression is too broad)"
fi

# ST06 -- the sender-scoped idempotency key. Same key, two senders: both must be stored.
out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
db.prepare('INSERT INTO channel(name,opened_at) VALUES (?,1)').run('c');
const ins = db.prepare('INSERT INTO message(channel_id,arrival_seq,sender_name,sender_machine,sender_seq,idempotency_key,body,sent_at,received_at) VALUES (1,?,?,?,?,?,?,1,1)');
ins.run(1, 'alice', 'm', 1, 'key-1', 'b');
ins.run(2, 'bob', 'm', 1, 'key-1', 'b');
let dup = 'no';
try { ins.run(3, 'alice', 'm', 2, 'key-1', 'b'); } catch (e) { dup = 'rejected'; }
process.stdout.write(db.prepare('SELECT COUNT(*) AS n FROM message').get().n + ':' + dup);
JS
)
assert_eq "$out" "2:rejected" "ST06 idempotency key is sender-scoped: two senders may share a key, one sender may not reuse it"

# ST07 -- opening twice loses nothing.
_TMPDB="${_TMPD}/persist.db"
out=$(_node <<JS 2>/dev/null
const a = await S.openStore({ path: '${_TMPDB}' });
a.prepare('INSERT INTO channel(name,opened_at) VALUES (?,1)').run('kept');
a.close();
const b = await S.openStore({ path: '${_TMPDB}' });
process.stdout.write(b.prepare('SELECT name FROM channel').get().name);
JS
)
assert_eq "$out" "kept" "ST07 re-opening an existing store preserves its data and raises no error"

# ST08 -- foreign keys on: deleting a channel cascades its messages away.
out=$(_node <<'JS' 2>/dev/null
const db = await S.openStore({ path: ':memory:' });
db.prepare('INSERT INTO channel(name,opened_at) VALUES (?,1)').run('c');
db.prepare('INSERT INTO message(channel_id,arrival_seq,sender_name,sender_machine,sender_seq,idempotency_key,body,sent_at,received_at) VALUES (1,1,?,?,1,?,?,1,1)')
    .run('s', 'm', 'k', 'b');
db.exec('DELETE FROM channel WHERE id=1');
process.stdout.write(String(db.prepare('SELECT COUNT(*) AS n FROM message').get().n));
JS
)
assert_eq "$out" "0" "ST08 closing a channel cascades its messages away (foreign keys enforced)"

test_summary
