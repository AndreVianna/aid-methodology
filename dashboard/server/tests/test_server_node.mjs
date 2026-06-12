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
 *   (c) GET /api/model returns DM-1 envelope (schema_version:3, generated_by:"node",
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
import { readRepo } from "../reader.mjs";

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

// The server binds only validated loopback addresses (127.0.0.1 or ::1).
// HOST is validated against LOOPBACK_ADDRS at parse time (SEC-1 contract).
// We check: LOOPBACK_ADDRS contains "127.0.0.1", listen call uses HOST variable
// (not 0.0.0.0 / wildcard), and the source enforces loopback via the set check.
assert(
  serverSrc.includes('"127.0.0.1"'),
  "server.mjs LOOPBACK_ADDRS contains literal 127.0.0.1"
);
const listenM = serverSrc.match(/server\.listen\([^)]*\)/);
const listenStr = listenM ? listenM[0] : "";
assert(
  !listenStr.includes('"0.0.0.0"') && !listenStr.includes("'0.0.0.0'"),
  "server.listen() does not contain 0.0.0.0"
);
assert(
  !serverSrc.match(/server\.listen\(PORT,\s*"::"\s*\)/) &&
  !serverSrc.match(/server\.listen\(PORT,\s*'::'\s*\)/),
  "server.mjs has no :: wildcard as listen arg"
);
// HOST must be validated against LOOPBACK_ADDRS before bind (loopback guarantee)
assert(
  serverSrc.includes("LOOPBACK_ADDRS.has(host)"),
  "server.mjs validates host against LOOPBACK_ADDRS before bind"
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

// work-001-alpha: add REQUIREMENTS.md with identity fields
writeFileSync(join(workDir1, "REQUIREMENTS.md"), [
  "# Requirements -- Alpha Work",
  "",
  "- **Name:** Alpha Work",
  "- **Description:** A test work item for the alpha fixture.",
  "",
  "## 1. Objective",
  "",
  "This is the objective block for the alpha work.",
  "",
].join("\n"), "utf-8");

// work-001-alpha: add STATE.md with Triage + Features + Deliveries sections
writeFileSync(join(workDir1, "STATE.md"), [
  "## Triage",
  "- **Path:** full",
  "",
  "## Features Status",
  "| # | Feature | Notes |",
  "| --- | --- | --- |",
  "| 1 | feature-001-core | core feature |",
  "",
  "## Plan / Deliveries",
  "| Delivery | Status | Tasks | Notes |",
  "| --- | --- | --- | --- |",
  "| delivery-001 | Done | 2 (task-001-002) | Initial delivery |",
  "",
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
    assert(!!(envelope && envelope.schema_version === 3), "envelope.schema_version === 3");
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
    // New work-identity fields (PART 2)
    assert(!!(w1 && w1.number === 1), "work-001-alpha number=1");
    assert(!!(w1 && w1.title === "Alpha Work"), "work-001-alpha title=Alpha Work");
    assert(!!(w1 && typeof w1.description === "string" && w1.description.length > 0),
      "work-001-alpha description is non-empty string");
    assert(!!(w1 && typeof w1.objective === "string" && w1.objective.length > 0),
      "work-001-alpha objective is non-empty string");
    assert(!!(w1 && w1.work_path === "full"), "work-001-alpha work_path=full");
    assert(!!(w1 && Array.isArray(w1.features) && w1.features.length === 1),
      "work-001-alpha has 1 feature");
    assert(!!(w1 && w1.features[0] && w1.features[0].number === 1 && w1.features[0].name === "core"),
      "work-001-alpha feature[0]: number=1, name=core");
    assert(!!(w1 && Array.isArray(w1.deliverables) && w1.deliverables.length === 1),
      "work-001-alpha has 1 deliverable");
    assert(
      !!(w1 && w1.deliverables[0] && w1.deliverables[0].number === 1 &&
         w1.deliverables[0].task_count === 2),
      "work-001-alpha deliverable[0]: number=1, task_count=2"
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

// ---------------------------------------------------------------------------
// (e) Malformed-input regression: delivery-006 bug class (PT-1 divergences)
//     These tests guard the two parsing fixes against future regression.
// ---------------------------------------------------------------------------

process.stdout.write("\n[e] Malformed-input regression (delivery-006 fixes)\n");

function runMalformedTests() {
  // Case e1: Headerless ## Tasks Status table.
  // A table whose first pipe row is a data row (col[0] != "#" and != "").
  // Before the fix, Node dropped the first data row; Python kept it.
  // After the fix, Node must parse BOTH rows.
  const tmpE1 = join(tmpdir(), "aid-e1-" + Date.now());
  const aidE1 = join(tmpE1, ".aid");
  const wdirE1 = join(aidE1, "work-001-headerless");
  mkdirSync(wdirE1, { recursive: true });
  writeFileSync(join(wdirE1, "STATE.md"), [
    "## Pipeline Status",
    "- **Lifecycle:** Running",
    "- **Phase:** Execute",
    "- **Active Skill:** -",
    "- **Updated:** 2026-06-01T00:00:00+00:00",
    "",
    "## Tasks Status",
    "| 1 | task-001 | IMPLEMENT | wave-1 | Done | A | 2h | first task |",
    "| 2 | task-002 | REVIEW | wave-1 | Pending | - | - | second task |",
  ].join("\n"), "utf-8");
  writeFileSync(join(aidE1, ".aid-manifest.json"), JSON.stringify({
    manifest_version: 1, aid_version: "1.0.0",
    installed_at: "2026-01-01T00:00:00Z", tools: {},
  }));

  try {
    const modelE1 = readRepo(tmpE1);
    const w1 = modelE1.works.find((w) => w.work_id === "work-001-headerless");
    assert(
      !!(w1 && w1.tasks.length === 2),
      "e1: headerless Tasks table: both data rows parsed (task_count=2, got " +
        (w1 ? w1.tasks.length : "no work") + ")"
    );
    assert(
      !!(w1 && w1.tasks[0] && w1.tasks[0].task_id === "task-001"),
      "e1: headerless Tasks table: first task is task-001"
    );
    assert(
      !!(w1 && w1.tasks[1] && w1.tasks[1].task_id === "task-002"),
      "e1: headerless Tasks table: second task is task-002"
    );
    assert(
      !!(w1 && w1.source_mode === "normalized"),
      "e1: headerless Tasks table: source_mode=normalized (got " +
        (w1 ? w1.source_mode : "no work") + ")"
    );
  } finally {
    try { rmSync(tmpE1, { recursive: true, force: true }); } catch (_) {}
  }

  // Case e2: ## Pipeline Status section present but containing NO typed "- **Field:**" lines.
  // Before the fix, Node fell through to fallback (source_mode=fallback, lifecycle=Running,
  // work added to fallback_works). Python set source_mode=normalized / lifecycle=Unknown.
  // After the fix, Node must match Python: source_mode=normalized, lifecycle=Unknown,
  // fallback_works=[].
  const tmpE2 = join(tmpdir(), "aid-e2-" + Date.now());
  const aidE2 = join(tmpE2, ".aid");
  const wdirE2 = join(aidE2, "work-001-psonly");
  mkdirSync(wdirE2, { recursive: true });
  writeFileSync(join(wdirE2, "STATE.md"), [
    "## Pipeline Status",
    "",
    "This section has prose but no typed fields.",
    "",
    "## Tasks Status",
    "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |",
    "| --- | --- | --- | --- | --- | --- | --- | --- |",
    "| 1 | task-001 | IMPLEMENT | wave-1 | Done | A | 2h | - |",
  ].join("\n"), "utf-8");
  writeFileSync(join(aidE2, ".aid-manifest.json"), JSON.stringify({
    manifest_version: 1, aid_version: "1.0.0",
    installed_at: "2026-01-01T00:00:00Z", tools: {},
  }));

  try {
    const modelE2 = readRepo(tmpE2);
    const w2 = modelE2.works.find((w) => w.work_id === "work-001-psonly");
    assert(
      !!(w2 && w2.source_mode === "normalized"),
      "e2: PS heading + no typed fields: source_mode=normalized (got " +
        (w2 ? w2.source_mode : "no work") + ")"
    );
    assert(
      !!(w2 && w2.lifecycle === "Unknown"),
      "e2: PS heading + no typed fields: lifecycle=Unknown (got " +
        (w2 ? w2.lifecycle : "no work") + ")"
    );
    assert(
      !!(modelE2.read && Array.isArray(modelE2.read.fallback_works) &&
         modelE2.read.fallback_works.length === 0),
      "e2: PS heading + no typed fields: fallback_works=[] (got " +
        (modelE2.read ? JSON.stringify(modelE2.read.fallback_works) : "no read") + ")"
    );
  } finally {
    try { rmSync(tmpE2, { recursive: true, force: true }); } catch (_) {}
  }
}

runMalformedTests();

runLiveTests().then(() => {
  process.stdout.write("\n--- Result: " + passed + " passed, " + failed + " failed ---\n");
  if (failed > 0) process.exit(1);
}).catch((err) => {
  process.stderr.write("Test runner error: " + String(err) + "\n");
  if (err.stack) process.stderr.write(err.stack + "\n");
  process.exit(1);
});
