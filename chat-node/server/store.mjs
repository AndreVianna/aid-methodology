// chat-node/server/store.mjs -- the hub's store: one SQLite database per machine.
//
// Opened through Node's built-in SQLite module, so the node carries no third-party
// dependency (FR-7.6). One file per machine under the per-user state home, because a hub
// serves every session on the machine regardless of which project each session works in.

import { existsSync, mkdirSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';

// ---------------------------------------------------------------------------
// The ExperimentalWarning, suppressed narrowly and for a stated reason.
//
// Below Node 24.15.0 the built-in SQLite module prints an ExperimentalWarning to stderr on
// every open. On the declared floor (>=22.13.0) that means every single node start carries a
// line the operator can do nothing about -- and the node's stderr is exactly where an
// actionable prerequisite error has to land. A line on every start is what teaches an
// operator to stop reading that channel.
//
// So exactly ONE message is suppressed, on exactly the runtime range that emits it. Any
// other experimental warning -- including a future one from this same module -- still
// reaches the operator. Suppressing warnings as a class would be the easy version of this
// and the wrong one.
const SQLITE_WARNING_RE = /SQLite is an experimental feature/i;

function nodeMajorMinorPatch() {
    const m = /^v?(\d+)\.(\d+)\.(\d+)/.exec(process.version);
    return m ? [Number(m[1]), Number(m[2]), Number(m[3])] : [0, 0, 0];
}

// The range that emits it: below 24.15.0. At or above, nothing is patched at all.
export function emitsSqliteExperimentalWarning() {
    const [maj, min, pat] = nodeMajorMinorPatch();
    if (maj > 24) return false;
    if (maj === 24 && (min > 15 || (min === 15 && pat >= 0))) return false;
    return true;
}

let _restoreEmitWarning = null;

function suppressSqliteWarning() {
    if (!emitsSqliteExperimentalWarning() || _restoreEmitWarning) return;
    const original = process.emitWarning;
    process.emitWarning = function (warning, ...rest) {
        const message = typeof warning === 'string' ? warning : (warning && warning.message) || '';
        // The type arrives either as the second positional argument or on an options object,
        // depending on which overload the caller used. Check both rather than assume one.
        let type = '';
        if (typeof rest[0] === 'string') type = rest[0];
        else if (rest[0] && typeof rest[0] === 'object' && rest[0].type) type = rest[0].type;
        else if (warning && warning.name) type = warning.name;
        if (type === 'ExperimentalWarning' && SQLITE_WARNING_RE.test(message)) return undefined;
        return original.call(process, warning, ...rest);
    };
    _restoreEmitWarning = () => { process.emitWarning = original; };
}

function restoreEmitWarning() {
    if (_restoreEmitWarning) { _restoreEmitWarning(); _restoreEmitWarning = null; }
}

// ---------------------------------------------------------------------------
// Where the store lives.

export function stateHome() {
    return process.env.AID_HOME || join(homedir(), '.aid');
}

export function storePath() {
    return process.env.AID_CHAT_STORE || join(stateHome(), 'chat', 'chat.db');
}

// ---------------------------------------------------------------------------
// The schema.
//
// AUTOINCREMENT is on every surrogate key, and it is not a style choice. `id INTEGER PRIMARY
// KEY` alone is a rowid alias, and SQLite reuses the id of a deleted row. This store deletes
// rows as routine business -- reaping removes sessions, closing a channel removes it and its
// messages -- so without AUTOINCREMENT a new session can inherit a reaped one's id and, with
// it, that predecessor's messages and positions. There is no error and no symptom until
// somebody reads the wrong mail.
//
// Sequences start at 1 and positions at 0, and the pairing is load-bearing. A position means
// "the last thing I have", so 0 has to mean "nothing". If arrival_seq also started at 0 the
// first message of every channel would sit at the position meaning "nothing", and the read
// predicate `arrival_seq > delivered_seq` would exclude it from every query for every member,
// forever. The same pairing makes the retention trim safe before anyone has acknowledged
// anything: min(acked_seq) is then 0, and `arrival_seq <= 0` selects no rows.
export const SCHEMA = `
CREATE TABLE IF NOT EXISTS session (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  name                  TEXT    NOT NULL UNIQUE,
  conversation_id       TEXT    NOT NULL UNIQUE,
  tool                  TEXT    NOT NULL,
  cwd                   TEXT    NOT NULL,
  capabilities          TEXT    NOT NULL DEFAULT '{}',
  host_conversation_id  TEXT,
  registered_at         INTEGER NOT NULL,
  last_heartbeat_at     INTEGER NOT NULL,
  channel_id            INTEGER REFERENCES channel(id) ON DELETE SET NULL,
  delivered_seq         INTEGER NOT NULL DEFAULT 0,
  acked_seq             INTEGER NOT NULL DEFAULT 0,
  next_sender_seq       INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS channel (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL UNIQUE,
  opened_at   INTEGER NOT NULL,
  next_seq    INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS message (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  channel_id       INTEGER NOT NULL REFERENCES channel(id) ON DELETE CASCADE,
  arrival_seq      INTEGER NOT NULL,
  sender_name      TEXT    NOT NULL,
  sender_machine   TEXT    NOT NULL,
  sender_seq       INTEGER NOT NULL,
  idempotency_key  TEXT    NOT NULL,
  kind             TEXT    NOT NULL DEFAULT 'message',
  body             TEXT    NOT NULL,
  correlation_id   TEXT,
  reply_to         TEXT,
  mention          TEXT,
  whisper_to       TEXT,
  sent_at          INTEGER NOT NULL,
  received_at      INTEGER NOT NULL,
  UNIQUE (channel_id, arrival_seq),
  UNIQUE (channel_id, sender_machine, sender_name, sender_seq),
  UNIQUE (channel_id, sender_machine, sender_name, idempotency_key)
);

CREATE INDEX IF NOT EXISTS message_read     ON message (channel_id, arrival_seq);
CREATE INDEX IF NOT EXISTS session_liveness ON session (last_heartbeat_at);

-- ---------------------------------------------------------------------------
-- Federation (delivery-004). Three additions and no changed rule: a session's
-- experience is identical whether its peer is on this machine or another.

-- The peers this hub knows. machine is the address a peer is reached at, and it is
-- UNIQUE because two rows for one address would mean two links, two outboxes, and two
-- answers to "is it reachable".
CREATE TABLE IF NOT EXISTS peer (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  machine        TEXT    NOT NULL UNIQUE,   -- the ADDRESS a peer is reached at
  machine_id     TEXT,                      -- the logical name it announced at handshake
  protocol_major INTEGER,
  source         TEXT    NOT NULL,
  last_seen_at   INTEGER,
  state          TEXT    NOT NULL DEFAULT 'unreachable'
);

-- What is owed to a peer that was not reachable when it was produced. Everything not yet
-- delivered lives HERE rather than in the link, which is what makes a reconnect lose
-- nothing: the link can be dropped and rebuilt without consulting anybody.
CREATE TABLE IF NOT EXISTS outbox (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  peer_id     INTEGER NOT NULL REFERENCES peer(id) ON DELETE CASCADE,
  kind        TEXT    NOT NULL,
  payload     TEXT    NOT NULL,
  queued_at   INTEGER NOT NULL,
  attempts    INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS outbox_drain ON outbox (peer_id, id);

-- The operator's audit log. Written by the hub, read only by the operator, and it records WHAT
-- HAPPENED rather than what was said: a whisper's parties are here and its body is not, because an
-- operator who could read whispers would make that guarantee a lie for everyone rather than just for
-- them. The same reasoning is why there is no body column at all -- not "we choose not to fill it
-- for whispers", which is a policy one edit away from being reversed, but nowhere to put it.
CREATE TABLE IF NOT EXISTS audit (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  at          INTEGER NOT NULL,
  event       TEXT    NOT NULL,   -- 'register' | 'open' | 'join' | 'leave' | 'send' | 'whisper' | 'connect' | 'reap' | 'evict' | 'trim'
  actor       TEXT,               -- the session that did it, where there was one
  subject     TEXT,               -- who or what it was done to
  channel     TEXT,
  detail      TEXT                -- a short, non-content note; never a message body
);

CREATE INDEX IF NOT EXISTS audit_recent ON audit (at DESC);

-- The one index retention adds. Its only reader is the trim job, which selects by channel and by
-- age; without it that job scans every message in the store on every run, which is precisely the
-- work it exists to make unnecessary.
CREATE INDEX IF NOT EXISTS message_trim ON message (channel_id, received_at);

-- The REMOTE half of a channel's roll, and only the remote half. Local membership stays in
-- session.channel_id, so there is no second copy of a fact to drift: mirroring local members
-- here would create two places for one truth, and they would disagree the first time a
-- transaction updated one and not the other.
--
-- This answers the question replication cannot work without -- which peers hold members of
-- this channel -- and, with the local count, whether a sender is alone.
CREATE TABLE IF NOT EXISTS channel_member (
  channel_id  INTEGER NOT NULL REFERENCES channel(id) ON DELETE CASCADE,
  machine     TEXT    NOT NULL,
  name        TEXT    NOT NULL,
  joined_at   INTEGER NOT NULL,
  PRIMARY KEY (channel_id, machine, name)
);
`;

// ---------------------------------------------------------------------------
// Opening.

let _DatabaseSync = null;

async function loadSqlite() {
    if (_DatabaseSync) return _DatabaseSync;
    // The warning fires on first load of the module, so the patch must be installed before
    // the import -- which is why this is a dynamic import rather than a top-level one: ESM
    // hoists static imports above every statement, including the patch.
    suppressSqliteWarning();
    try {
        const mod = await import('node:sqlite');
        _DatabaseSync = mod.DatabaseSync;
    } finally {
        restoreEmitWarning();
    }
    return _DatabaseSync;
}

export async function openStore({ path = null, create = true } = {}) {
    const file = path || storePath();
    if (file !== ':memory:' && create) {
        const dir = dirname(file);
        if (!existsSync(dir)) mkdirSync(dir, { recursive: true, mode: 0o700 });
    }
    const DatabaseSync = await loadSqlite();
    const db = new DatabaseSync(file);
    db.exec('PRAGMA foreign_keys = ON');
    db.exec('PRAGMA journal_mode = WAL');
    db.exec(SCHEMA);
    return db;
}

export function nowMs() {
    return Date.now();
}
