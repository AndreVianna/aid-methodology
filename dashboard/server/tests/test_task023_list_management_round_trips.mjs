/**
 * dashboard/server/tests/test_task023_list_management_round_trips.mjs
 * "List-management op round-trips + parser parity" (task-023,
 * feature-007-connectors-list / feature-010-external-sources-list,
 * delivery-003, work-017-cli-improvements) -- Node twin.
 *
 * This is a TEST-type task: no production code (that is tasks 018-021). The
 * PRIMARY parity work for this task (exit->HTTP matrix cross-runtime byte
 * parity via a fake writer pair, real-writer round-trip gap-filling, DM-1
 * serializer parity) lives in the Python file
 * test_task023_list_management_round_trips.py, which drives BOTH runtimes
 * from one process (Python's own `_dispatch_op` directly, Node's `dispatchOp`
 * via a sliced-and-redirected server.mjs copy run as a bounded subprocess --
 * the same slice-and-export technique test_task017_registry_tooling_round_
 * trips.py's own fixture established, applied here to WRITER_DIR instead of
 * AID_CLI_PATH). This file adds ONLY the ONE case that needs a REAL live
 * server.mjs process on the Node side: the HTTP-layer (_serve_op /
 * serveOp) write_enabled 403 gate for connector.set / external-source.add
 * (task-023 DETAIL: "the write_enabled gate returns 403 under read-only") --
 * that gate fires in serveOp BEFORE any body parse / OP_TABLE dispatch (see
 * server.py's _serve_op docstring: "Order: write gate (403) -> repo id
 * resolution -> body parse -> OP_TABLE dispatch"), so it cannot be exercised
 * through the sliced dispatchOp export (which is only reachable AFTER the
 * gate has already passed) -- mirrors test_task013_project_registry_ops.mjs's
 * / test_task017_registry_tooling_round_trips.mjs's own live-server group
 * convention. Expected body is asserted against the EXACT literal envelope
 * the Python twin (TestWriteEnabledGateLive) asserts against, which is how
 * parity is proven for this HTTP-layer case without a live cross-process
 * comparison at runtime.
 *
 * Run: node dashboard/server/tests/test_task023_list_management_round_trips.mjs
 *
 * LOCAL TEST NOTE (Windows/Git-Bash host, no setsid): this file spawns the
 * REAL server.mjs as a child process and binds a loopback port -- per the
 * project's port-binding-server-test constraint it is NOT executed locally as
 * part of this task's own verification pass; syntax-checked via `node --check`
 * and verified by inspection instead (mirrors test_task017_registry_tooling_
 * round_trips.mjs's own LOCAL TEST NOTE), deferred to CI for an actual run.
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
// test_server_node.mjs's/test_task017's own spawnServer/killServer/
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
// write_enabled 403 gate -- live server, spawned WITHOUT --allow-writes; the
// gate must fire for connector.set / external-source.add exactly as it does
// for every other op (task-013's/task-017's own project.add/tools.update
// live-gate coverage), never reaching OP_TABLE dispatch.
// ---------------------------------------------------------------------------

async function runLiveTest() {
  process.stdout.write("\n[H] connector.set / external-source.add write_enabled 403 gate (live serveOp, read-only)\n");

  const base = join(tmpdir(), "aid-t023-live-" + Date.now() + "-" + Math.random().toString(36).slice(2));
  const aidHome = join(base, "aid_home");
  const repoRoot = join(base, "repo-A");
  mkdirSync(aidHome, { recursive: true });
  mkdirSync(join(aidHome, "dashboard"), { recursive: true });
  mkdirSync(join(repoRoot, ".aid"), { recursive: true });

  const repoId = "deadbeefcafe";
  writeFileSync(
    join(aidHome, "registry.yml"),
    "schema: 1\nprojects:\n  - " + repoRoot.replace(/\\/g, "/") + "\n",
    "utf8",
  );

  // Spawned WITHOUT --allow-writes -- write_enabled stays false (fail-safe default).
  const s = await spawnServer(aidHome, []);
  if (!s.ready) {
    assert(false, "server spawned read-only for group [H]");
  } else {
    assert(true, "server spawned read-only for group [H]");

    // Resolve the real repo id the server computed (mirrors test_task017's
    // own approach of asking the server itself via /api/home rather than
    // re-implementing the id-hash algorithm here).
    const homeResp = await makeRequest(s.port, "/api/home", "GET");
    let resolvedId = repoId;
    try {
      const homeData = JSON.parse(homeResp.body);
      if (homeData && Array.isArray(homeData.repos) && homeData.repos.length > 0) {
        resolvedId = homeData.repos[0].id;
      }
    } catch (e) {
      // fall through with the placeholder id -- the 403 gate fires BEFORE id
      // resolution anyway, so an unresolved/wrong id does not affect this case.
    }

    const expectedBody = JSON.stringify({
      ok: false, op: null, error: "read-only",
      detail: "write endpoints disabled (server not spawned with --allow-writes)",
    });

    const r1 = await postJson(s.port, "/r/" + resolvedId + "/api/op",
      { op: "connector.set", args: { name: "GitHub", type: "mcp" } });
    assert(r1.status === 403, "H.1: connector.set -> 403 under read-only (got " + r1.status + ")");
    assert(r1.body === expectedBody,
      "H.2: connector.set response body is the EXACT literal envelope the Python twin asserts "
      + "(got " + r1.body + ", expected " + expectedBody + ")");

    const r2 = await postJson(s.port, "/r/" + resolvedId + "/api/op",
      { op: "external-source.add", args: { value: "https://example.com/doc" } });
    assert(r2.status === 403, "H.3: external-source.add -> 403 under read-only (got " + r2.status + ")");
    assert(r2.body === expectedBody,
      "H.4: external-source.add response body is the EXACT literal envelope the Python twin asserts "
      + "(got " + r2.body + ", expected " + expectedBody + ")");
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
