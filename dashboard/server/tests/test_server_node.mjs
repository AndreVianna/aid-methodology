/**
 * dashboard/server/tests/test_server_node.mjs
 * Self-check test for server.mjs + reader.mjs (feature-003 task-017 AC).
 *
 * Run: node dashboard/server/tests/test_server_node.mjs
 *
 * Asserts:
 *   (a) server.mjs source contains no 0.0.0.0/wildcard bind token.
 *   (b) server.mjs and reader.mjs contain no fs.writeFile/appendFile/unlink
 *       and no agent/LLM import.
 *   (c) GET /api/model returns DM-1 envelope (schema_version:1, generated_by:"node",
 *       works sorted by work_id).
 *   (d) Unknown path -> 404, POST -> 405.
 *
 * Uses a temp fixture .aid dir. Deterministic, fully cleaned up.
 * ASCII-only source. Node built-in modules only.
 */

import { readFileSync, mkdirSync, writeFileSync, rmSync, statSync } from "fs";
import { join, dirname, basename } from "path";
import { fileURLToPath } from "url";
import { createServer } from "http";
import http from "http";
import net from "net";
import { spawn } from "child_process";
import { tmpdir } from "os";
import { createRequire } from "module";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const SERVER_MJS = join(__dirname, "..", "server.mjs");
const READER_MJS = join(__dirname, "..", "reader.mjs");

let passed = 0;
let failed = 0;

function assert(cond, msg) {
  if (cond) {
    process.stdout.write("  PASS: " + msg + "\n");
    passed++;
  } else {
    process.stderr.write("  FAIL: " + msg + "\n");
    failed++;
  }
}

// ---------------------------------------------------------------------------
// (a) server.mjs bind-address invariant
// ---------------------------------------------------------------------------

process.stdout.write("\n[a] server.mjs bind-address invariant\n");

const serverSrc = readFileSync(SERVER_MJS, "utf-8");
const readerSrc = readFileSync(READER_MJS, "utf-8");

// The server.listen call must use "127.0.0.1", not 0.0.0.0 or ::
const listenM = serverSrc.match(/server\.listen\([^)]*\)/);
const listenStr = listenM ? listenM[0] : "";
assert(
  listenStr.includes('"127.0.0.1"') || listenStr.includes("'127.0.0.1'"),
  "server.listen() uses literal 127.0.0.1"
);
assert(
  !listenStr.includes('"0.0.0.0"') && !listenStr.includes("'0.0.0.0'"),
  "server.listen() does not contain 0.0.0.0"
);
assert(
  !serverSrc.match(/server\.listen\(PORT,\s*"::"\s*\)/) &&
  !serverSrc.match(/server\.listen\(PORT,\s*'::'\s*\)/),
  "server.mjs has no :: wildcard as listen arg"
);

// ---------------------------------------------------------------------------
// (b) No-write + no-LLM invariants
// ---------------------------------------------------------------------------

process.stdout.write("\n[b] No-write + no-LLM invariants\n");

// Strip single-line (//) and block (/**/) comments before checking for forbidden patterns
// so that doc-comment mentions like "No fs.writeFile..." don't trigger false positives.
function stripComments(src) {
  // Remove block comments (non-greedy)
  let s = src.replace(/\/\*[\s\S]*?\*\//g, " ");
  // Remove line comments
  s = s.replace(/\/\/.*/g, " ");
  return s;
}

const serverSrcCode = stripComments(serverSrc);
const readerSrcCode = stripComments(readerSrc);

assert(
  !serverSrcCode.includes("writeFile") &&
  !serverSrcCode.includes("appendFile") &&
  !/fs\s*\.\s*unlink\b/.test(serverSrcCode),
  "server.mjs: no fs.writeFile/appendFile/unlink (code, not comments)"
);
assert(
  !readerSrcCode.includes("writeFile") &&
  !readerSrcCode.includes("appendFile") &&
  !/fs\s*\.\s*unlink\b/.test(readerSrcCode),
  "reader.mjs: no fs.writeFile/appendFile/unlink (code, not comments)"
);

const LLM_IMPORTS = ["anthropic", "openai", "langchain", "litellm", "@anthropic-ai"];
for (const lib of LLM_IMPORTS) {
  assert(
    !serverSrc.includes('"' + lib) && !serverSrc.includes("'" + lib),
    "server.mjs: no import of " + lib
  );
  assert(
    !readerSrc.includes('"' + lib) && !readerSrc.includes("'" + lib),
    "reader.mjs: no import of " + lib
  );
}

// ---------------------------------------------------------------------------
// Build a minimal fixture .aid tree for live server tests
// ---------------------------------------------------------------------------

const tmpRoot = join(tmpdir(), "aid-test-" + Date.now());
const aidDir = join(tmpRoot, ".aid");
const workDir1 = join(aidDir, "work-001-alpha");
const workDir2 = join(aidDir, "work-002-beta");

mkdirSync(workDir1, { recursive: true });
mkdirSync(workDir2, { recursive: true });

// work-001-alpha: normalized, Running, 2 tasks
writeFileSync(join(workDir1, "STATE.md"), [
  "## Pipeline Status",
  "- **Lifecycle:** Running",
  "- **Phase:** Execute",
  "- **Active Skill:** aid-execute",
  "- **Updated:** 2026-06-10T12:00:00+00:00",
  "",
  "## Tasks Status",
  "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |",
  "| --- | --- | --- | --- | --- | --- | --- | --- |",
  "| 1 | task-001 | IMPLEMENT | 1 | In Progress | - | 2h | - |",
  "| 2 | task-002 | REVIEW | 1 | Pending | - | - | - |",
].join("\n"), "utf-8");

// work-002-beta: normalized, Completed, 1 task
writeFileSync(join(workDir2, "STATE.md"), [
  "## Pipeline Status",
  "- **Lifecycle:** Completed",
  "- **Phase:** Deploy",
  "- **Active Skill:** -",
  "- **Updated:** 2026-06-09T10:00:00+00:00",
  "",
  "## Tasks Status",
  "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |",
  "| --- | --- | --- | --- | --- | --- | --- | --- |",
  "| 1 | task-001 | IMPLEMENT | 1 | Done | A | 5h | - |",
].join("\n"), "utf-8");

// Minimal manifest
writeFileSync(join(aidDir, ".aid-manifest.json"), JSON.stringify({
  manifest_version: 1,
  aid_version: "1.0.0-test",
  installed_at: "2026-06-10T00:00:00Z",
  tools: {},
}), "utf-8");

// ---------------------------------------------------------------------------
// Helper: get a free port
// ---------------------------------------------------------------------------

function getFreePort() {
  return new Promise((resolve, reject) => {
    const srv = createServer();
    srv.listen(0, "127.0.0.1", () => {
      const port = srv.address().port;
      srv.close(() => resolve(port));
    });
    srv.on("error", reject);
  });
}

// ---------------------------------------------------------------------------
// Helper: poll until port accepts connections
// ---------------------------------------------------------------------------

function waitForPort(port, maxMs) {
  return new Promise((resolve) => {
    const deadline = Date.now() + (maxMs || 3000);
    function attempt() {
      if (Date.now() > deadline) { resolve(false); return; }
      const sock = new net.Socket();
      sock.setTimeout(200);
      sock.on("connect", () => { sock.destroy(); resolve(true); });
      sock.on("error", () => { setTimeout(attempt, 100); });
      sock.on("timeout", () => { sock.destroy(); setTimeout(attempt, 100); });
      sock.connect(port, "127.0.0.1");
    }
    setTimeout(attempt, 100);
  });
}

// ---------------------------------------------------------------------------
// Helper: HTTP request
// ---------------------------------------------------------------------------

function makeRequest(port, path, method) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: "127.0.0.1",
      port: port,
      path: path,
      method: method || "GET",
    };
    const req = http.request(options, (res) => {
      let body = "";
      res.setEncoding("utf-8");
      res.on("data", (chunk) => { body += chunk; });
      res.on("end", () => resolve({ status: res.statusCode, body: body, headers: res.headers }));
    });
    req.on("error", reject);
    req.end();
  });
}

// ---------------------------------------------------------------------------
// (c) + (d) live server route tests
// ---------------------------------------------------------------------------

process.stdout.write("\n[c+d] Live server route tests\n");

async function runLiveTests() {
  const port = await getFreePort();

  const proc = spawn(
    process.execPath,
    [SERVER_MJS, "--root", tmpRoot, "--host", "127.0.0.1", "--port", String(port)],
    { stdio: ["ignore", "ignore", "pipe"] }
  );

  let spawnError = null;
  proc.on("error", (err) => { spawnError = err; });

  const ready = await waitForPort(port, 5000);
  if (!ready || spawnError) {
    assert(false, "server spawned and accepted connections: " + (spawnError || "timeout"));
    proc.kill("SIGTERM");
    return;
  }
  assert(true, "server spawned and accepted connections on port " + port);

  try {
    // (c) GET /api/model -> DM-1 envelope
    const r1 = await makeRequest(port, "/api/model", "GET");
    assert(r1.status === 200, "GET /api/model -> 200 (got " + r1.status + ")");
    assert(
      !!(r1.headers["content-type"] && r1.headers["content-type"].includes("application/json")),
      "GET /api/model Content-Type includes application/json"
    );

    let envelope = null;
    try {
      envelope = JSON.parse(r1.body);
    } catch (_) {
      envelope = null;
    }
    assert(envelope !== null, "GET /api/model body is valid JSON");
    assert(!!(envelope && envelope.schema_version === 1), "envelope.schema_version === 1");
    assert(!!(envelope && envelope.generated_by === "node"), 'envelope.generated_by === "node"');
    assert(!!(envelope && typeof envelope.model === "object"), "envelope.model is an object");

    const model = (envelope && envelope.model) || {};
    assert(Array.isArray(model.works), "model.works is an array");

    // works sorted by work_id ascending
    const works = model.works || [];
    if (works.length >= 2) {
      assert(
        works[0].work_id <= works[1].work_id,
        "works[0].work_id <= works[1].work_id (sorted ascending)"
      );
    }

    const workIds = works.map((w) => w.work_id);
    assert(
      workIds.includes("work-001-alpha") && workIds.includes("work-002-beta"),
      "model.works contains both fixture works"
    );

    const w1 = works.find((w) => w.work_id === "work-001-alpha");
    assert(!!(w1 && w1.lifecycle === "Running"), "work-001-alpha lifecycle=Running");
    assert(
      !!(w1 && Array.isArray(w1.tasks) && w1.tasks.length === 2),
      "work-001-alpha has 2 tasks"
    );

    const w2 = works.find((w) => w.work_id === "work-002-beta");
    assert(!!(w2 && w2.lifecycle === "Completed"), "work-002-beta lifecycle=Completed");

    assert(
      !!(model.read && typeof model.read.read_at === "string"),
      "model.read.read_at is a string"
    );
    assert(
      !!(model.read && model.read.work_count === 2),
      "model.read.work_count === 2"
    );

    // (d) Unknown path -> 404
    const r2 = await makeRequest(port, "/unknown/path", "GET");
    assert(r2.status === 404, "GET /unknown/path -> 404 (got " + r2.status + ")");

    // (d) POST -> 405
    const r3 = await makeRequest(port, "/api/model", "POST");
    assert(r3.status === 405, "POST /api/model -> 405 (got " + r3.status + ")");

    // Route for / must exist (may 404 if no index.html, but must not crash or return 500)
    const r4 = await makeRequest(port, "/", "GET");
    assert(
      r4.status === 200 || r4.status === 404,
      "GET / -> 200 or 404 (route exists, got " + r4.status + ")"
    );

  } finally {
    proc.kill("SIGTERM");
    await new Promise((resolve) => setTimeout(resolve, 300));
    try {
      rmSync(tmpRoot, { recursive: true, force: true });
    } catch (_) {
      // ignore cleanup error
    }
  }
}

runLiveTests().then(() => {
  process.stdout.write("\n--- Result: " + passed + " passed, " + failed + " failed ---\n");
  if (failed > 0) process.exit(1);
}).catch((err) => {
  process.stderr.write("Test runner error: " + String(err) + "\n");
  if (err.stack) process.stderr.write(err.stack + "\n");
  process.exit(1);
});
