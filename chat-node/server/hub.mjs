// chat-node/server/hub.mjs -- the hub process: an HTTP server over loopback and its lifecycle.
//
// The hub has one responsibility, message exchange, and ships no operator surface of its own
// (FR-7.5): `start`, `stop` and `status` are `aid` subcommands that talk to this process, and
// this file implements the process, not the commands.
//
// Loopback only at this stage. Opening it to a LAN interface belongs to federation, and
// arrives with the trust model that justifies it -- binding wider before that exists would
// make the network reachable before anything decided it should be.
//
// The transport is the built-in HTTP server: no framework, no third-party dependency (FR-7.6).

import { createServer } from 'node:http';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';

import { nowMs, openStore, stateHome } from './store.mjs';
import * as core from './core.mjs';

export const DEFAULT_PORT = 8812;   // 8787 is the dashboard's; 8799 and 8811 are also taken
export const LOOPBACK = '127.0.0.1';

export function runtimeDir() {
    return process.env.AID_CHAT_RUNTIME || join(stateHome(), 'chat');
}
export function pidFilePath() { return join(runtimeDir(), 'hub.pid'); }
export function portFilePath() { return join(runtimeDir(), 'hub.port'); }

// ---------------------------------------------------------------------------
// Liveness of a recorded pid, without the POSIX `kill(pid, 0)` idiom.
//
// On Windows `kill(pid, 0)` TERMINATES the process rather than probing it. That is not a
// hypothetical: it silently corrupted a measurement during this product's own feasibility
// spike, and the wrong answer looked plausible. `process.kill(pid, 0)` in Node is safe on
// both platforms because Node maps signal 0 to a permission probe, but the reason it must
// not become a bare `kill` in a shell wrapper is recorded here rather than rediscovered.
export function pidAlive(pid) {
    if (!Number.isInteger(pid) || pid <= 0) return false;
    try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
}

export function readPid() {
    try {
        const pid = Number(readFileSync(pidFilePath(), 'utf8').trim());
        return Number.isInteger(pid) && pid > 0 ? pid : null;
    } catch { return null; }
}

export function readPort() {
    try {
        const p = Number(readFileSync(portFilePath(), 'utf8').trim());
        return Number.isInteger(p) && p > 0 ? p : null;
    } catch { return null; }
}

export function hubStatus() {
    const pid = readPid();
    if (pid === null) return { running: false, reason: 'no pid file' };
    if (!pidAlive(pid)) return { running: false, pid, reason: 'stale pid file' };
    return { running: true, pid, port: readPort() };
}

function writeRuntimeFiles(pid, port) {
    const dir = runtimeDir();
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true, mode: 0o700 });
    writeFileSync(pidFilePath(), `${pid}\n`, { mode: 0o600 });
    writeFileSync(portFilePath(), `${port}\n`, { mode: 0o600 });
}

export function clearRuntimeFiles() {
    for (const f of [pidFilePath(), portFilePath()]) {
        try { rmSync(f, { force: true }); } catch { /* nothing to remove */ }
    }
}

// ---------------------------------------------------------------------------
// Routes. Later tasks add the message plane and the hub plane; this file owns only the
// server, its lifecycle and the one route the operator needs to see it is alive.

function json(res, status, body) {
    const text = JSON.stringify(body);
    res.writeHead(status, {
        'content-type': 'application/json; charset=utf-8',
        'content-length': Buffer.byteLength(text),
    });
    res.end(text);
}

// A refused request is answered with 409 and its stable token, not 400 and not 500. 400 would
// say the caller sent something malformed, which it did not; 500 would say the hub broke, which
// it did not. The CLI maps this status to exit 14 -- one shape, one meaning, all the way out.
function answer(res, result) {
    if (result && result.ok) return json(res, 200, result);
    const status = result && result.reason === 'bad_request' ? 400 : 409;
    return json(res, status, result);
}

async function readJsonBody(req) {
    const chunks = [];
    for await (const c of req) chunks.push(c);
    if (!chunks.length) return {};
    // Decode with utf-8 BOM tolerance. RFC 8259 does not permit a BOM in JSON, so a strict
    // parser rejects an otherwise valid document at its FIRST character -- an error that reads
    // as malformed JSON rather than as an encoding problem. The spike lost two runs to exactly
    // that, and any client of this hub could hit it, so the tolerance lives here rather than in
    // each caller.
    const text = Buffer.concat(chunks).toString('utf8').replace(/^\uFEFF/, '');
    try { return JSON.parse(text); }
    catch (err) { const e = new Error(`malformed JSON body: ${err.message}`); e.badRequest = true; throw e; }
}

export function makeRouter({ db, startedAt }) {
    const routes = new Map();

    routes.set('GET /status', (_req, res) => json(res, 200, {
        running: true,
        pid: process.pid,
        started_at: startedAt,
        uptime_ms: nowMs() - startedAt,
        store: db ? 'open' : 'closed',
    }));

    // Session plane.
    routes.set('POST /session', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.register(db, {
            name: b.name, tool: b.tool, cwd: b.cwd,
            capabilities: b.capabilities, hostConversationId: b.host_conversation_id || null,
        }));
    });
    routes.set('POST /session/heartbeat', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.heartbeat(db, b.name));
    });
    routes.set('GET /sessions', (_req, res) => json(res, 200, { ok: true, sessions: core.listSessions(db) }));

    // Channel plane.
    routes.set('POST /channel', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.openChannel(db, { name: b.name, channelName: b.channel }));
    });
    routes.set('POST /channel/join', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.joinChannel(db, { name: b.name, channelName: b.channel }));
    });
    routes.set('POST /channel/leave', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.leaveChannel(db, { name: b.name }));
    });
    routes.set('GET /channels', (req, res, url) =>
        json(res, 200, { ok: true, channels: core.listChannels(db, { name: url.searchParams.get('name') }) }));

    // Message plane.
    routes.set('POST /messages', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.send(db, {
            name: b.name, body: b.body, kind: b.kind,
            idempotencyKey: b.idempotency_key || null,
            mention: b.mention || null, whisperTo: b.whisper_to || null,
            correlationId: b.correlation_id || null, replyTo: b.reply_to || null,
        }));
    });
    routes.set('GET /messages', (req, res, url) => {
        const cursor = url.searchParams.get('cursor');
        answer(res, core.inbox(db, {
            name: url.searchParams.get('name'),
            cursor: cursor === null ? null : Number(cursor),
        }));
    });
    routes.set('POST /messages/ack', async (req, res) => {
        const b = await readJsonBody(req);
        answer(res, core.ack(db, { name: b.name, cursor: b.cursor }));
    });

    return async function route(req, res) {
        const url = new URL(req.url, `http://${LOOPBACK}`);
        const key = `${req.method} ${url.pathname}`;
        const handler = routes.get(key);
        if (!handler) return json(res, 404, { error: 'no_such_route', route: key });
        try {
            await handler(req, res, url);
        } catch (err) {
            if (err && err.badRequest) {
                return json(res, 400, { ok: false, reason: 'bad_request', detail: String(err.message) });
            }
            // A handler fault is the hub's fault, not the caller's: report it as one rather
            // than leaking a stack trace over the wire.
            json(res, 500, { ok: false, reason: 'internal', detail: String(err && err.message || err) });
        }
    };
}

// ---------------------------------------------------------------------------
// Serving.

export async function serve({ port = DEFAULT_PORT, storeFile = null } = {}) {
    const db = await openStore(storeFile ? { path: storeFile } : {});
    const startedAt = nowMs();
    const server = createServer(makeRouter({ db, startedAt }));

    await new Promise((resolve, reject) => {
        server.once('error', reject);
        // Bind loopback explicitly. Omitting the host binds every interface, which would put
        // the hub on the network a whole stage before the trust model that permits it.
        server.listen(port, LOOPBACK, resolve);
    });

    const actualPort = server.address().port;
    writeRuntimeFiles(process.pid, actualPort);

    const shutdown = () => {
        try { server.close(); } catch { /* already closing */ }
        try { db.close(); } catch { /* already closed */ }
        clearRuntimeFiles();
        process.exit(0);
    };
    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);

    return { server, db, port: actualPort };
}

// ---------------------------------------------------------------------------
// Entry point, used by the CLI's `start`. Not a supported direct invocation.

if (process.argv[1] && process.argv[1].endsWith('hub.mjs')) {
    const portArg = process.argv.indexOf('--port');
    const port = portArg > -1 ? Number(process.argv[portArg + 1]) : DEFAULT_PORT;
    serve({ port }).then(({ port: p }) => {
        process.stdout.write(`chat-node: listening on ${LOOPBACK}:${p}\n`);
    }).catch((err) => {
        process.stderr.write(`chat-node: ${err && err.message || err}\n`);
        process.exit(1);
    });
}
