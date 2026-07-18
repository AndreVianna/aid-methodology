/**
 * dashboard/server/tests/test_task017_registry_tooling_round_trips.mjs
 * "Registry + tooling op round-trips" (task-017, feature-003-project-registry /
 * feature-004-update-tools, delivery-002, work-017-cli-improvements) -- Node twin.
 *
 * This is a TEST-type task: no production code (that is tasks 013-016). The
 * PRIMARY twin-parity work for this task (server.py vs server.mjs returning
 * IDENTICAL HTTP status + response bytes for the SAME fake-CLI-driven
 * scenario, across project.add / project.remove / tools.update /
 * tools.update-self) lives in the Python file
 * test_task017_registry_tooling_round_trips.py, which drives BOTH runtimes
 * from one process (Python's own `_dispatch_op` directly, Node's `dispatchOp`
 * via a sliced-and-redirected server.mjs copy run as a bounded subprocess --
 * the same slice-and-export technique test_task012_consuming_round_trips.py's
 * `_NodeSlicedServerFixture` established) and asserts (status, body) equality
 * there. This file adds ONLY the ONE case that needs a REAL live server.mjs
 * process on the Node side: the HTTP-layer (serveOp) unknown-<id> 404 for
 * tools.update (task-017 Scope: "unknown repo <id> ... via POST
 * /r/<id>/api/op") -- that 404 fires in serveOp BEFORE any OP_TABLE dispatch,
 * so it cannot be exercised through the sliced dispatchOp export (which takes
 * an already-resolved servedRoot, bypassing id-map resolution entirely) --
 * mirrors test_task013_project_registry_ops.mjs's own live-server group [C]
 * convention. Expected body is asserted against the EXACT literal envelope
 * the Python twin (TestToolsUpdateUnknownRepoIdLive) asserts against
 * (`{"ok":false,"op":null,"error":"not-found","detail":"unknown repo id"}`),
 * which is how parity is proven for this HTTP-layer case without a live
 * cross-process comparison at runtime.
 *
 * Run: node dashboard/server/tests/test_task017_registry_tooling_round_trips.mjs
 *
 * LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): this file spawns the
 * REAL server.mjs as a child process and binds a loopback port -- per the
 * project's port-binding-server-test constraint it is NOT executed locally
 * as part of this task's own verification pass; syntax-checked via
 * `node --check` and verified by inspection instead (mirrors
 * test_task013_project_registry_ops.mjs's own group [C] LOCAL TEST NOTE),
 * deferred to CI for an actual run.
 *
 * ASCII-only source. Node built-in modules only.
 */

import { mkdirSync, rmSync, writeFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { createServer } from "http";
import http from "http";
import net from "net";
import { spawn } from "child_process";
import { tmpdir } from "os";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const SERVER_MJS = join(__dirname, "..", "server.mjs");

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
// Helpers: network + process (slim, self-contained duplicates of
// test_server_node.mjs's/test_task013's own spawnServer/killServer/
// makeRequest/postJson -- duplicated rather than imported, same rationale
// those files' own docstrings give: never touch an already-passing canonical
// file).
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

function waitForPort(port, maxMs) {
  return new Promise((resolve) => {
    const deadline = Date.now() + (maxMs || 5000);
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

function makeRequest(port, path, method, headers, requestBody) {
  return new Promise((resolve, reject) => {
    const bodyBuf = requestBody === undefined ? null : Buffer.from(requestBody);
    const options = { hostname: "127.0.0.1", port, path, method: method || "GET" };
    options.headers = Object.assign({}, headers || {});
    if (bodyBuf !== null && options.headers["Content-Length"] === undefined) {
      options.headers["Content-Length"] = bodyBuf.length;
    }
    const req = http.request(options, (res) => {
      let respBuf = Buffer.alloc(0);
      res.on("data", (chunk) => { respBuf = Buffer.concat([respBuf, chunk]); });
      res.on("end", () => resolve({ status: res.statusCode, body: respBuf.toString("utf-8") }));
    });
    req.on("error", reject);
    req.end(bodyBuf === null ? undefined : bodyBuf);
  });
}

function postJson(port, path, payload) {
  return makeRequest(port, path, "POST", { "Content-Type": "application/json" }, JSON.stringify(payload));
}

async function spawnServer(aidHome, extraArgs) {
  const port = await getFreePort();
  const proc = spawn(
    process.execPath,
    [SERVER_MJS, "--host", "127.0.0.1", "--port", String(port), ...(extraArgs || [])],
    { stdio: ["ignore", "ignore", "pipe"], env: Object.assign({}, process.env, { AID_HOME: aidHome }) }
  );
  const ready = await waitForPort(port, 5000);
  return { proc, port, ready };
}

function killServer(proc) {
  return new Promise((resolve) => {
    if (proc.exitCode !== null) { resolve(); return; }
    proc.kill("SIGTERM");
    setTimeout(resolve, 300);
  });
}

// ---------------------------------------------------------------------------
// tools.update unknown-<id> 404 -- live server, real serveOp id-resolution
// path (never reaches any CLI, fake or real).
// ---------------------------------------------------------------------------

async function runLiveTest() {
  process.stdout.write("\n[G] tools.update unknown repo <id> -> 404 (live serveOp id-resolution path)\n");

  const base = join(tmpdir(), "aid-t017-live-" + Date.now() + "-" + Math.random().toString(36).slice(2));
  const aidHome = join(base, "aid_home");
  mkdirSync(aidHome, { recursive: true });
  mkdirSync(join(aidHome, "dashboard"), { recursive: true });
  writeFileSync(join(aidHome, "registry.yml"), "schema: 1\nprojects:\n", "utf8");   // empty union

  const s = await spawnServer(aidHome, ["--allow-writes"]);
  if (!s.ready) {
    assert(false, "server spawned with --allow-writes for group [G]");
  } else {
    assert(true, "server spawned with --allow-writes for group [G]");

    const r = await postJson(s.port, "/r/deadbeefcafe/api/op", { op: "tools.update" });
    assert(r.status === 404, "G.1: unknown repo <id> -> 404 (got " + r.status + ")");

    const expectedBody = JSON.stringify({ ok: false, op: null, error: "not-found", detail: "unknown repo id" });
    assert(r.body === expectedBody,
      "G.2: response body is the EXACT literal envelope the Python twin asserts "
      + "(got " + r.body + ", expected " + expectedBody + ")");
  }
  await killServer(s.proc);
  rmSync(base, { recursive: true, force: true });
}

await runLiveTest();

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

process.stdout.write("\n--- Result: " + passed + " passed, " + failed + " failed ---\n");

if (failed > 0) {
  process.exit(1);
}
