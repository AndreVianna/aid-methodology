/**
 * dashboard/server/tests/test_task011_dispatch_round_trip.mjs
 * "Foundation parity + dispatch round-trip suite" (task-011,
 * feature-001-write-infrastructure, delivery-001) -- Node twin.
 *
 * Mirrors test_task011_dispatch_round_trip.py's scope. Closes the coverage
 * test_server_node.mjs's own (2c)/(5c-op) groups explicitly defer to task-011:
 *   1. The full DEFAULT_MAP writer-exit -> HTTP-status matrix (1->404, 2->409,
 *      3->500, 4->422, 5->422, 6->500), each driven end-to-end through a REAL
 *      writer script (writeback-state.sh / write-setting.sh) via a crafted
 *      fixture that naturally exits with that code -- never a synthetic stub
 *      -- over a real spawned server.mjs process + loopback socket.
 *   2. WT-1: a pipeline-scoped op (task.set-notes) whose target.work_id no
 *      worktree holds -> 404 'not-found' (complementary op to
 *      test_server_node.mjs's existing pipeline.rename live-server case).
 *   3. Oversize (>64 KiB) request body -> 400 'bad-request'.
 *   4. Gate-closed -> 403 / unknown op -> 400 (quick confirmations, redundant
 *      with test_server_node.mjs's (2c) group -- kept here so this file is
 *      self-contained).
 *   5. The OP-SM hook (`statusMap || DEFAULT_MAP`): server.mjs self-executes
 *      on import (parses argv, binds a socket immediately -- no main-guard),
 *      so its internal mapExitCode/DEFAULT_MAP are not importable here. No
 *      SEEDED OP_TABLE row uses statusMap yet (features 003/004 add the
 *      first ones), so there is no live op to drive an override through
 *      anyway. Mirrored verbatim instead (SAME convention this file's own
 *      isAllowedHost mirror in test_server_node.mjs already uses, kept in
 *      lockstep with server.mjs's real mapExitCode/DEFAULT_MAP) and unit-
 *      tested directly, in-process -- no spawn, no socket.
 *   6. SEC-3/SEC-4 static guard, precisely scoped to the runWriter(...)
 *      function body (not a whole-file substring scan, which would
 *      false-positive on this file's own doc comments describing what is
 *      NOT done).
 *
 * Run: node dashboard/server/tests/test_task011_dispatch_round_trip.mjs
 *
 * LOCAL TEST NOTE: this file spawns server.mjs as a child process and binds
 * loopback ports (mirrors test_server_node.mjs's own convention) -- per the
 * project's port-binding-server-test constraint it is NOT executed locally as
 * part of this task's own verification pass; syntax-checked via `node --check`
 * and verified by inspection instead, deferred to CI for an actual run. The
 * mirrored mapExitCode/DEFAULT_MAP unit-test group and the SEC-3/SEC-4 source
 * guard do not spawn anything and were reasoned through by inspection too,
 * for the same reason (this file, as a whole script, exits 1 on any local
 * failure -- partial-group execution would need a separate harness this repo
 * does not have for .mjs suites).
 *
 * ASCII-only source. Node built-in modules only.
 */

import { mkdirSync, writeFileSync, rmSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { createServer } from "http";
import http from "http";
import net from "net";
import { spawn } from "child_process";
import { tmpdir } from "os";
import { createHash } from "crypto";

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

function assertEquals(a, b, msg) {
  assert(a === b, msg + " -- got " + JSON.stringify(a) + " expected " + JSON.stringify(b));
}

// ---------------------------------------------------------------------------
// Helpers: id derivation (mirrors test_server_node.mjs's repoId8)
// ---------------------------------------------------------------------------

function repoId8(canonPath) {
  return createHash("sha256").update(canonPath, "utf8").digest("hex").slice(0, 8);
}

// ---------------------------------------------------------------------------
// Helpers: fixture builders (mirror test_server_node.mjs's own makeAidHome /
// writeRegistry / makeRepo, plus the 3 flat-work shapes this suite needs --
// see test_task011_dispatch_round_trip.py's Python-twin equivalents)
// ---------------------------------------------------------------------------

function makeAidHome(base) {
  mkdirSync(base, { recursive: true });
  writeFileSync(join(base, "VERSION"), "1.0.0-test\n", "utf8");
  writeRegistry(base, []);
  mkdirSync(join(base, "dashboard"), { recursive: true });
}

function writeRegistry(aidHome, paths) {
  let content = "schema: 1\nrepos:\n";
  for (const p of paths) content += "  - " + p + "\n";
  writeFileSync(join(aidHome, "registry.yml"), content, "utf8");
}

function makeRepoWithSettings(base) {
  const aid = join(base, ".aid");
  mkdirSync(aid, { recursive: true });
  writeFileSync(join(aid, "settings.yml"), "project:\n  name: test-repo\n", "utf8");
}

function makeRepoNoSettings(base) {
  // .aid/ present, but NO settings.yml -- drives write-setting.sh's own exit 3.
  mkdirSync(join(base, ".aid"), { recursive: true });
}

function makeFlatMarkers(workDir) {
  mkdirSync(join(workDir, "tasks", "task-001"), { recursive: true });
  writeFileSync(join(workDir, "BLUEPRINT.md"), "# Blueprint\n", "utf8");
  writeFileSync(join(workDir, "tasks", "task-001", "DETAIL.md"), "# task-001\n", "utf8");
}

function makeFlatWork(repoRoot, workId) {
  const workDir = join(repoRoot, ".aid", "works", workId);
  makeFlatMarkers(workDir);
  writeFileSync(join(workDir, "STATE.md"), [
    "---",
    "lifecycle: Running",
    "updated: '2026-01-01T00:00:00Z'",
    "---",
    "",
    "# Work State",
    "",
    "### Tasks lifecycle",
    "",
    "| Task | State | Review | Elapsed | Notes |",
    "| --- | --- | --- | --- | --- |",
    "| task-001 | Pending | -- | -- | -- |",
    "",
  ].join("\n"), "utf8");
  return workDir;
}

function makeFlatWorkNoState(repoRoot, workId) {
  const workDir = join(repoRoot, ".aid", "works", workId);
  makeFlatMarkers(workDir);
  return workDir;
}

function makeFlatWorkMalformedState(repoRoot, workId) {
  const workDir = join(repoRoot, ".aid", "works", workId);
  makeFlatMarkers(workDir);
  writeFileSync(join(workDir, "STATE.md"),
    "---\nlifecycle: Running\n---\n\n# Work State\n\nNo tasks section here.\n", "utf8");
  return workDir;
}

// A NESTED-layout work (deliveries/ wrapper, no BLUEPRINT.md -- isFlatLayout()
// is false) whose task-001 DETAIL.md carries NO '**Source:**' bullet --
// writeback-state.sh's resolve_delivery_from_task_spec() can't recover a
// delivery number, so resolve_delivery_for_task_mode() dies exit 5 ('cannot
// resolve delivery for task ...') when --delivery-id is omitted (mirrors the
// Python twin's _make_nested_work_unresolvable_delivery). Used to drive the
// DEFAULT_MAP exit-5 -> 422 row via a DIFFERENT path than an empty --value now
// that task-010's argv-builder substitutes the '--' null sentinel before spawn
// (so an empty task.set-notes value no longer reaches writeback-state.sh's own
// '--value is required' exit-5 guard).
function makeNestedWorkUnresolvableDelivery(repoRoot, workId) {
  const workDir = join(repoRoot, ".aid", "works", workId);
  const delDir = join(workDir, "deliveries", "delivery-001");
  const taskDir = join(delDir, "tasks", "task-001");
  mkdirSync(taskDir, { recursive: true });
  writeFileSync(join(workDir, "STATE.md"), "## Pipeline State\n\n- **Lifecycle:** Running\n", "utf8");
  writeFileSync(join(delDir, "STATE.md"), "## Delivery Lifecycle\n\n- **State:** Executing\n", "utf8");
  writeFileSync(join(taskDir, "DETAIL.md"), "# task-001: Nested task (no Source line)\n\n**Type:** IMPLEMENT\n", "utf8");
  writeFileSync(join(taskDir, "STATE.md"), "---\nstate: Pending\n---\n\n## Task State\n", "utf8");
  return workDir;
}

// ---------------------------------------------------------------------------
// Helpers: network + process (slim, self-contained duplicates of
// test_server_node.mjs's own spawnServer/killServer/makeRequest/postJson --
// duplicated rather than imported so this file never touches that already-
// passing 2000+ line canonical parity file)
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
    const deadline = Date.now() + (maxMs || 4000);
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

async function spawnServer(aidHome, extraArgs, extraEnv) {
  const port = await getFreePort();
  const proc = spawn(
    process.execPath,
    [SERVER_MJS, "--host", "127.0.0.1", "--port", String(port), ...(extraArgs || [])],
    {
      stdio: ["ignore", "ignore", "pipe"],
      env: Object.assign({}, process.env, { AID_HOME: aidHome }, extraEnv || {}),
    }
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
// (D) OP-SM hook: mirrored mapExitCode/DEFAULT_MAP (server.mjs self-executes
// on import -- see module docstring), in-process, no spawn.
// ---------------------------------------------------------------------------

process.stdout.write("\n[D] OP-SM hook: mapExitCode(exitCode, statusMap) (mirrored, kept in lockstep with server.mjs)\n");

// Mirrors server.mjs's DEFAULT_MAP / mapExitCode verbatim (see server.mjs
// ~line 706-771). Kept in lockstep by inspection -- same convention as this
// suite family's isAllowedHost mirror in test_server_node.mjs.
const MIRRORED_DEFAULT_MAP = {
  1: [404, "not-found"],
  2: [409, "busy"],
  4: [422, "invalid-value"],
  5: [422, "invalid-value"],
  3: [500, "write-failed"],
  6: [500, "write-failed"],
};
const MIRRORED_DEFAULT_FALLBACK = [500, "write-failed"];

function mirroredMapExitCode(exitCode, statusMap) {
  const effective = statusMap || MIRRORED_DEFAULT_MAP;
  return effective[exitCode] || MIRRORED_DEFAULT_FALLBACK;
}

{
  const [status1, err1] = mirroredMapExitCode(4, null);
  assertEquals(status1, 422, "D.1: row without statusMap -- exit 4 -> DEFAULT_MAP (422)");
  assertEquals(err1, "invalid-value", "D.1b: error class 'invalid-value'");

  const override = { 4: [409, "custom-conflict"] };
  const [status2, err2] = mirroredMapExitCode(4, override);
  assertEquals(status2, 409, "D.2: row WITH statusMap overrides DEFAULT_MAP (exit 4 -> 409)");
  assertEquals(err2, "custom-conflict", "D.2b: error class 'custom-conflict'");

  // Sibling rows resolve independently in the same table.
  const [statusDefault] = mirroredMapExitCode(4, null);
  const [statusOverride] = mirroredMapExitCode(4, { 4: [409, "custom-conflict"] });
  assertEquals(statusDefault, 422, "D.3: sibling row without override still uses DEFAULT_MAP");
  assertEquals(statusOverride, 409, "D.3b: sibling row with override uses its own map");

  // An exit code absent from the OVERRIDE map falls back to the fixed
  // (500, write-failed) sentinel, NOT to DEFAULT_MAP's own row for that code.
  const partialOverride = { 1: [401, "custom-unauthorized"] };   // no entry for exit 4
  const [status3, err3] = mirroredMapExitCode(4, partialOverride);
  assertEquals(status3, 500, "D.4: exit absent from the override map falls back to 500 (not DEFAULT_MAP's row)");
  assertEquals(err3, "write-failed", "D.4b: fallback error class 'write-failed'");
}

// ---------------------------------------------------------------------------
// (E) SEC-3/SEC-4 static guard, scoped to the runWriter(...) function body
// (not a whole-file substring scan -- this file's OWN doc comments above
// mention "shell" in prose explaining what is NOT done; a naive scan of
// server.mjs's comments would carry the same false-positive risk).
// ---------------------------------------------------------------------------

process.stdout.write("\n[E] SEC-3/SEC-4 static guard (scoped to runWriter(...))\n");

{
  const fs = await import("fs");
  const serverSrc = fs.readFileSync(SERVER_MJS, "utf-8");

  const m = serverSrc.match(/function runWriter\([^)]*\)\s*\{[\s\S]*?\n\}/);
  assert(!!m, "E.1: runWriter(...) function found in server.mjs");
  const runWriterBody = m ? m[0] : "";
  // Strip comments from the extracted body ONLY (not the whole file) before
  // the negative assertions, so this scoped check cannot false-positive on
  // runWriter's own doc comment ("never a shell string").
  const runWriterCode = runWriterBody.replace(/\/\/.*/g, " ").replace(/\/\*[\s\S]*?\*\//g, " ");

  assert(/spawnSync\(\s*BASH_EXE\s*,\s*\[/.test(runWriterCode),
    "E.2: runWriter spawns via spawnSync(BASH_EXE, [argv array]) -- an argv array, not a shell string");
  assert(!/shell\s*:\s*true/i.test(runWriterCode),
    "E.3: runWriter's spawnSync options object never sets shell:true (SEC-3)");
  assert(!/exec\s*\(/.test(runWriterCode),
    "E.4: runWriter never uses child_process.exec() (shell-interpreted command string)");

  const serverCode = serverSrc.replace(/\/\/.*/g, " ").replace(/\/\*[\s\S]*?\*\//g, " ");
  assert(!serverCode.includes("writeFileSync") && !serverCode.includes("appendFileSync") &&
    !/fs\s*\.\s*unlink/.test(serverCode),
    "E.5: server.mjs has no in-process fs write/append/unlink primitive (SEC-3)");
  for (const lib of ["anthropic", "openai", "langchain", "@anthropic-ai"]) {
    assert(!serverSrc.includes('"' + lib) && !serverSrc.includes("'" + lib),
      "E.6: server.mjs does not import " + lib + " (SEC-4)");
  }
}

// ---------------------------------------------------------------------------
// Live-server groups (spawn server.mjs as a child process; each group
// restarts the server fresh to keep write_enabled / fixtures isolated)
// ---------------------------------------------------------------------------

async function runLiveTests() {
  const base = join(tmpdir(), "aid-t011-live-" + Date.now() + "-" + Math.random().toString(36).slice(2));
  const aidHome = join(base, "aid_home");
  makeAidHome(aidHome);

  const repoA = join(base, "repo-A");
  makeRepoWithSettings(repoA);
  const repoB = join(base, "repo-B");
  makeRepoNoSettings(repoB);
  writeRegistry(aidHome, [repoA, repoB]);
  const idA = repoId8(repoA);
  const idB = repoId8(repoB);

  // -------------------------------------------------------------------------
  // (A) DEFAULT_MAP writer-exit -> HTTP-status matrix, over a real spawned
  // server, each driven by a REAL writer script.
  // -------------------------------------------------------------------------

  process.stdout.write("\n[A] DEFAULT_MAP writer-exit -> HTTP-status matrix (live, write-enabled)\n");

  let s = await spawnServer(aidHome, ["--allow-writes"]);
  if (!s.ready) {
    assert(false, "server spawned with --allow-writes for group [A]");
  } else {
    assert(true, "server spawned with --allow-writes for group [A]");

    // exit 1 -> 404 not-found: flat markers present, NO STATE.md.
    {
      makeFlatWorkNoState(repoA, "work-711-nostate");
      const r = await postJson(s.port, "/r/" + idA + "/api/op", {
        op: "task.set-notes",
        target: { work_id: "work-711-nostate", task_id: "001" },
        args: { value: "hi" },
      });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 404, "A.1: exit 1 (missing STATE.md) -> 404 (got " + r.status + ")");
      assert(!!(data && data.error === "not-found"), "A.1b: error class 'not-found'");
    }

    // exit 4 -> 422 invalid-value: pipe in value.
    {
      makeFlatWork(repoA, "work-714-pipe");
      const r = await postJson(s.port, "/r/" + idA + "/api/op", {
        op: "task.set-notes",
        target: { work_id: "work-714-pipe", task_id: "001" },
        args: { value: "a|b" },
      });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 422, "A.2: exit 4 (pipe in value) -> 422 (got " + r.status + ")");
      assert(!!(data && data.error === "invalid-value"), "A.2b: error class 'invalid-value'");
    }

    // exit 5 -> 422 invalid-value: unresolvable delivery (nested layout, no
    // --delivery-id, task DETAIL.md has no '**Source:**' bullet). NOTE: this
    // replaces the file's original exit-5 case (an empty args.value) -- task-010
    // (feature-006-task-notes) added an argv-builder substitution that maps an
    // empty value to the '--' null sentinel BEFORE spawn, so an empty
    // task.set-notes value now round-trips to a SUCCESSFUL 200 write, never
    // reaching writeback-state.sh's own '--value is required' exit-5 guard.
    {
      makeNestedWorkUnresolvableDelivery(repoA, "work-715-nodelivery");
      const r = await postJson(s.port, "/r/" + idA + "/api/op", {
        op: "task.set-notes",
        target: { work_id: "work-715-nodelivery", task_id: "001" },
        args: { value: "hi" },
      });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 422, "A.3: exit 5 (unresolvable delivery) -> 422 (got " + r.status + ")");
      assert(!!(data && data.error === "invalid-value"), "A.3b: error class 'invalid-value'");
    }

    // exit 6 -> 500 write-failed: STATE.md missing '### Tasks lifecycle'.
    {
      makeFlatWorkMalformedState(repoA, "work-716-malformed");
      const r = await postJson(s.port, "/r/" + idA + "/api/op", {
        op: "task.set-notes",
        target: { work_id: "work-716-malformed", task_id: "001" },
        args: { value: "hi" },
      });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 500, "A.4: exit 6 (malformed STATE.md) -> 500 (got " + r.status + ")");
      assert(!!(data && data.error === "write-failed"), "A.4b: error class 'write-failed'");
    }

    // exit 3 -> 500 write-failed: settings.set against a repo with NO settings.yml.
    {
      const r = await postJson(s.port, "/r/" + idB + "/api/op", {
        op: "settings.set", args: { path: "project.name", value: "x" },
      });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 500, "A.5: exit 3 (settings.yml missing) -> 500 (got " + r.status + ")");
      assert(!!(data && data.error === "write-failed"), "A.5b: error class 'write-failed'");
    }

    // WT-1: task.set-notes against an unresolvable work_id -> 404.
    {
      const r = await postJson(s.port, "/r/" + idA + "/api/op", {
        op: "task.set-notes",
        target: { work_id: "work-999-nowhere", task_id: "001" },
        args: { value: "hi" },
      });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 404, "A.6 (WT-1): task.set-notes unresolvable work_id -> 404 (got " + r.status + ")");
      assert(!!(data && data.error === "not-found"), "A.6b: error class 'not-found'");
    }

    // Oversize (>64 KiB) body -> 400 bad-request.
    {
      const oversizeValue = "x".repeat(70 * 1024);
      const r = await postJson(s.port, "/r/" + idA + "/api/op", {
        op: "settings.set", args: { path: "project.name", value: oversizeValue },
      });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 400, "A.7: oversize (>64 KiB) body -> 400 (got " + r.status + ")");
      assert(!!(data && data.error === "bad-request"), "A.7b: error class 'bad-request'");
    }

    // Unknown op -> 400 bad-request (quick confirmation).
    {
      const r = await postJson(s.port, "/r/" + idA + "/api/op", { op: "not-a-real-op" });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 400, "A.8: unknown op -> 400 (got " + r.status + ")");
      assert(!!(data && data.error === "bad-request"), "A.8b: error class 'bad-request'");
    }
  }
  await killServer(s.proc);

  // exit 2 -> 409 busy: pre-created .writeback-state.lock sentinel,
  // AID_LOCK_TIMEOUT=1 for a fast (~0.5s), deterministic retry loop -- a
  // FRESH server spawn so the lock env var is read at writer-subprocess
  // start (inherited from the server process's own env).
  process.stdout.write("\n[A.9] DEFAULT_MAP exit 2 (lock contention) -> 409 busy\n");
  {
    const workDir = makeFlatWork(repoA, "work-712-locked");
    writeFileSync(join(workDir, ".writeback-state.lock"), "999999\n", "utf8");
    const s2 = await spawnServer(aidHome, ["--allow-writes"], { AID_LOCK_TIMEOUT: "1" });
    if (!s2.ready) {
      assert(false, "server spawned with --allow-writes + AID_LOCK_TIMEOUT=1 for [A.9]");
    } else {
      const r = await postJson(s2.port, "/r/" + idA + "/api/op", {
        op: "task.set-notes",
        target: { work_id: "work-712-locked", task_id: "001" },
        args: { value: "hi" },
      });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 409, "A.9: exit 2 (lock contention) -> 409 (got " + r.status + ")");
      assert(!!(data && data.error === "busy"), "A.9b: error class 'busy'");
    }
    await killServer(s2.proc);
  }

  // Gate-closed -> 403 read-only (quick confirmation, no --allow-writes).
  process.stdout.write("\n[A.10] Gate-closed (no --allow-writes) -> 403 read-only\n");
  {
    const s3 = await spawnServer(aidHome);
    if (!s3.ready) {
      assert(false, "server spawned without --allow-writes for [A.10]");
    } else {
      const r = await postJson(s3.port, "/r/" + idA + "/api/op", {
        op: "task.set-notes",
        target: { work_id: "work-714-pipe", task_id: "001" },
        args: { value: "hi" },
      });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 403, "A.10: gate closed -> 403 (got " + r.status + ")");
      assert(!!(data && data.error === "read-only"), "A.10b: error class 'read-only'");
    }
    await killServer(s3.proc);
  }

  rmSync(base, { recursive: true, force: true });
}

await runLiveTests();

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

process.stdout.write("\n--- Result: " + passed + " passed, " + failed + " failed ---\n");

if (failed > 0) {
  process.exit(1);
}
