/**
 * dashboard/server/server.mjs
 * Node thin server for the AID pipeline dashboard (feature-003, LC-S).
 *
 * Entry-point: node dashboard/server/server.mjs --root <repo-root> --host 127.0.0.1 --port <n>
 *
 * Routes (closed allowlist):
 *   GET /            -> serve static index.html (sibling assets dir)
 *   GET /api/model   -> readRepo(root) -> DM-1 envelope -> 200 JSON
 *   other path       -> 404
 *   non-GET verb     -> 405
 *
 * Invariants (structurally enforced):
 *   - Binds LITERAL "127.0.0.1" only; never 0.0.0.0 / :: / wildcard.
 *   - No fs.write* / appendFile / unlink / open-for-write in this file.
 *   - No agent/LLM import in this file.
 *   - http.createServer; binds before slow work; SIGTERM -> server.close + exit 0.
 *
 * Serialization (DM-3):
 *   - Object literals built in declared field order (reader.mjs guarantees this).
 *   - works sorted by work_id ascending.
 *   - JSON.stringify(obj) -- compact, no trailing newline, no BOM, UTF-8.
 *   - U+2028 / U+2029: Node JSON.stringify does NOT escape them by default (emits
 *     raw bytes). This server post-processes to the escaped canonical form to match
 *     the Python server (PT-1 / R7). The escaped form IS canonical (DM-3).
 *   - Content-Type: application/json; charset=utf-8
 *
 * Source must be ASCII-only (shipped script posture; coding-standards.md).
 * UTF-8 content emitted at runtime, not in source.
 */

import { createServer } from "http";
import { readFileSync, existsSync } from "fs";
import { resolve, dirname, join } from "path";
import { fileURLToPath } from "url";

import { readRepo } from "./reader.mjs";

// ---------------------------------------------------------------------------
// Arg parsing
// ---------------------------------------------------------------------------

const LOOPBACK_ADDRS = new Set(["127.0.0.1", "::1"]);

function parseArgs(argv) {
  const args = argv.slice(2); // strip node + script
  let root = null;
  let host = null;
  let port = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--root" && i + 1 < args.length) {
      root = args[++i];
    } else if (args[i] === "--host" && i + 1 < args.length) {
      host = args[++i];
    } else if (args[i] === "--port" && i + 1 < args.length) {
      port = parseInt(args[++i], 10);
    }
  }

  const errs = [];
  if (!root) errs.push("--root is required");
  if (!host) errs.push("--host is required");
  if (port === null || isNaN(port)) errs.push("--port is required and must be an integer");

  if (errs.length > 0) {
    process.stderr.write("server.mjs: " + errs.join("; ") + "\n");
    process.exit(1);
  }

  // Reject any host that is not a loopback address (C1/C2 hard invariant)
  if (!LOOPBACK_ADDRS.has(host)) {
    process.stderr.write(
      "server.mjs: --host must be a loopback address (127.0.0.1 or ::1); " +
      "widened bind addresses are not permitted (C1/C2).\n"
    );
    process.exit(1);
  }

  return { root, host, port };
}

// ---------------------------------------------------------------------------
// Static assets resolution
// ---------------------------------------------------------------------------

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// index.html lives at the dashboard root (dashboard/index.html), one level up
// from server/. Resolve relative to server.mjs so the server finds it regardless
// of cwd. Matches Python's _INDEX_HTML = dashboard/index.html (PT-1 parity).
const INDEX_HTML_PATH = join(__dirname, "..", "index.html");  // dashboard/index.html (sibling of server/, alongside reader/)

// ---------------------------------------------------------------------------
// Request handler
// ---------------------------------------------------------------------------

function handler(req, res) {
  const method = req.method || "GET";
  const url = (req.url || "/").split("?")[0]; // strip query string

  // Non-GET -> 405
  if (method !== "GET") {
    res.writeHead(405, { "Content-Type": "text/plain; charset=utf-8", "Allow": "GET" });
    res.end("405 Method Not Allowed\n");
    return;
  }

  if (url === "/") {
    serveIndexHtml(res);
    return;
  }

  if (url === "/api/model") {
    serveApiModel(res);
    return;
  }

  // All other paths -> 404
  res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
  res.end("404 Not Found\n");
}

function serveIndexHtml(res) {
  if (!existsSync(INDEX_HTML_PATH)) {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("404 index.html not yet available\n");
    return;
  }
  let content;
  try {
    content = readFileSync(INDEX_HTML_PATH);
  } catch (err) {
    res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("500 Internal Server Error\n");
    return;
  }
  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(content);
}

function serveApiModel(res) {
  let model;
  try {
    // readRepo sorts works by work_id (already sorted by locator, but enforce here per DM-3)
    model = readRepo(ROOT);
  } catch (err) {
    process.stderr.write("server.mjs: readRepo error: " + String(err) + "\n");
    res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("500 Internal Server Error\n");
    return;
  }

  // Sort works by work_id ascending (DM-3 determinism)
  if (model.works) {
    model.works.sort((a, b) => a.work_id < b.work_id ? -1 : a.work_id > b.work_id ? 1 : 0);
  }

  // DM-1 envelope: schema_version + generated_by at top level, then model
  const envelope = {
    schema_version: 1,
    generated_by: "node",
    model: model,
  };

  // DM-3 parity: neither Node JSON.stringify nor Python json.dumps(ensure_ascii=False)
  // escapes U+2028/U+2029 by default (both emit raw bytes). The canonical /api/model form
  // is the ESCAPED form, so post-process to match the Python server (PT-1 / R7).
  const body = JSON.stringify(envelope)
    .replace(/\u2028/gu, "\\u2028")
    .replace(/\u2029/gu, "\\u2029");
  const bodyBuf = Buffer.from(body, "utf-8");

  res.writeHead(200, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": bodyBuf.length,
  });
  res.end(bodyBuf);
}

// ---------------------------------------------------------------------------
// Main: parse args, create server, bind, register SIGTERM
// ---------------------------------------------------------------------------

const { root: ROOT, host: HOST, port: PORT } = parseArgs(process.argv);

const server = createServer(handler);

// Bind BEFORE any slow work (LC-1 readiness contract)
server.listen(PORT, "127.0.0.1", () => {
  // Nothing required on stdout (LC-1 spawn seam D1).
  // The CLI confirms readiness via TCP-connect poll, not stdout.
  // Diagnostics may go to stderr.
  process.stderr.write(
    "server.mjs: listening on http://127.0.0.1:" + PORT + " (root=" + ROOT + ")\n"
  );
});

server.on("error", (err) => {
  process.stderr.write("server.mjs: bind error: " + String(err) + "\n");
  process.exit(1);
});

// Clean exit on SIGTERM (LC-1 exit semantics)
process.on("SIGTERM", () => {
  server.close(() => {
    process.exit(0);
  });
});
