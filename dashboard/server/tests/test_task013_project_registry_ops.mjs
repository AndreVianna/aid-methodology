/**
 * dashboard/server/tests/test_task013_project_registry_ops.mjs
 * "project.add / project.remove handlers + shared aid-CLI resolver" (task-013,
 * feature-003-project-registry, delivery-002, work-017-cli-improvements) --
 * Node twin.
 *
 * Mirrors test_task013_project_registry_ops.py's scope, adapted to this
 * codebase's established Node-testing constraint: server.mjs self-executes on
 * import (parses argv, binds a socket immediately -- no main-guard), so its
 * internal functions (dispatchOp, validateProjectAddArgs, runAidCli, ...) are
 * NOT importable in-process the way server.py's are. Per the SAME convention
 * test_task011_dispatch_round_trip.mjs's own "OP-SM hook" group already
 * established (mirror the logic verbatim, kept in lockstep by inspection) --
 * this file:
 *   [A] SEC-3/SEC-4 static guard, scoped to the runAidCli(...) function body
 *       (not a whole-file substring scan -- this file's own doc comments
 *       mention "shell"/"argv" in prose describing what is NOT done).
 *   [B] A mirrored proof of the fail-open guard's regex (RE_AID_FAIL_OPEN),
 *       in-process, no spawn -- kept in lockstep with server.mjs by inspection.
 *   [C] Live-server integration groups: spawn the REAL server.mjs (--allow-
 *       writes) against a temp AID_HOME, dispatching through the REAL bin/aid
 *       CLI (never a stub) -- project.add / project.remove happy paths (real
 *       registry.yml mutation observed), the CLI's own 422 paths (nonexistent
 *       path, not-an-AID-project), a 400 pre-validate rejection (relative
 *       path, never reaching the CLI), and a 404 for an unknown target.id.
 *
 * Run: node dashboard/server/tests/test_task013_project_registry_ops.mjs
 *
 * LOCAL TEST NOTE: group [C] spawns server.mjs as a child process and binds a
 * loopback port (mirrors test_task011_dispatch_round_trip.mjs's own
 * convention) -- per the project's port-binding-server-test constraint it is
 * NOT executed locally as part of this task's own verification pass;
 * syntax-checked via `node --check` and verified by inspection instead,
 * deferred to CI for an actual run. Groups [A]/[B] do not spawn anything and
 * were reasoned through by inspection too, for the same reason this file, as
 * a whole script, exits 1 on any local failure (no separate harness for
 * partial-group execution of a .mjs suite -- same rationale
 * test_task011_dispatch_round_trip.mjs's own LOCAL TEST NOTE documents).
 *
 * ASCII-only source. Node built-in modules only.
 */

import { readFileSync, mkdirSync, writeFileSync, rmSync, existsSync } from "fs";
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
const REPO_ROOT = join(__dirname, "..", "..", "..");   // AID/
const BIN_AID = join(REPO_ROOT, "bin", "aid");          // the REAL bin/aid (never a stub)

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
// Helpers: id derivation + fixture builders (mirror test_task011's own
// makeAidHome / writeRegistry / repoId8)
// ---------------------------------------------------------------------------

function repoId8(canonPath) {
  return createHash("sha256").update(canonPath, "utf8").digest("hex").slice(0, 8);
}

function makeAidHome(base) {
  mkdirSync(base, { recursive: true });
  writeFileSync(join(base, "VERSION"), "1.0.0-test\n", "utf8");
  writeRegistry(base, []);
  mkdirSync(join(base, "dashboard"), { recursive: true });
}

function writeRegistry(aidHome, paths) {
  let content = "schema: 1\nprojects:\n";
  for (const p of paths) content += "  - " + p + "\n";
  writeFileSync(join(aidHome, "registry.yml"), content, "utf8");
}

function readRegistryRepos(aidHome) {
  let text;
  try {
    text = readFileSync(join(aidHome, "registry.yml"), "utf8");
  } catch (e) {
    return [];
  }
  const repos = [];
  for (const line of text.split("\n")) {
    const m = /^\s*-\s+(.*\S)\s*$/.exec(line);
    if (m) repos.push(m[1]);
  }
  return repos;
}

// ---------------------------------------------------------------------------
// Helpers: network + process (slim, self-contained duplicates of
// test_server_node.mjs's own spawnServer/killServer/makeRequest/postJson --
// duplicated rather than imported, same rationale test_task011's own file
// documents: this file never touches that already-passing canonical parity
// file)
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
// [A] SEC-3/SEC-4 static guard, scoped to runAidCli(...)'s function body.
// ---------------------------------------------------------------------------

process.stdout.write("\n[A] SEC-3/SEC-4 static guard (scoped to runAidCli(...))\n");

{
  const serverSrc = readFileSync(SERVER_MJS, "utf-8");

  const m = serverSrc.match(/function runAidCli\([^)]*\)\s*\{[\s\S]*?\n\}/);
  assert(!!m, "A.1: runAidCli(...) function found in server.mjs");
  const runAidCliBody = m ? m[0] : "";
  const runAidCliCode = runAidCliBody.replace(/\/\/.*/g, " ").replace(/\/\*[\s\S]*?\*\//g, " ");

  assert(/spawnSync\(\s*BASH_EXE\s*,\s*\[/.test(runAidCliCode),
    "A.2: runAidCli spawns via spawnSync(BASH_EXE, [argv array]) -- an argv array, not a shell string");
  assert(!/shell\s*:\s*true/i.test(runAidCliCode),
    "A.3: runAidCli's spawnSync options object never sets shell:true (SEC-3)");
  assert(!/exec\s*\(/.test(runAidCliCode),
    "A.4: runAidCli never uses child_process.exec() (shell-interpreted command string)");
  assert(runAidCliCode.includes("AID_CLI_PATH"),
    "A.5: runAidCli resolves the shared AID_CLI_PATH anchor (KI-004), not an ad-hoc path");

  // KI-009 Part A: the Windows dispatch branch is ALSO an argv array (never a
  // shell string), spawning the resolved PowerShell exe against the
  // co-vendored aid.ps1 twin -- never an ad-hoc path.
  assert(/spawnSync\(\s*PWSH_EXE\s*,\s*\[/.test(runAidCliCode),
    "A.6: runAidCli's Windows branch spawns via spawnSync(PWSH_EXE, [argv array]) -- also an argv array, never a shell string");
  assert(runAidCliCode.includes("AID_CLI_PATH_PS1"),
    "A.7: runAidCli resolves the Windows-branch anchor AID_CLI_PATH_PS1 (KI-009), not an ad-hoc path");
  assert(runAidCliCode.includes("-NoProfile") && runAidCliCode.includes("-NonInteractive"),
    "A.8: runAidCli's PowerShell spawn passes -NoProfile -NonInteractive (headless-safe, no profile/prompt)");
  assert(/process\.platform\s*===\s*"win32"/.test(runAidCliCode),
    "A.9: runAidCli's OS branch is keyed off process.platform (the SERVER's own OS), not any client/request signal");
}

// ---------------------------------------------------------------------------
// [B] Mirrored proof of the fail-open guard's regex (RE_AID_FAIL_OPEN),
// in-process, no spawn -- kept in lockstep with server.mjs by inspection (same
// convention as the OP-SM DEFAULT_MAP mirror in test_task011_dispatch_round_trip.mjs).
// ---------------------------------------------------------------------------

process.stdout.write("\n[B] Fail-open guard regex (mirrored, kept in lockstep with server.mjs)\n");

// Mirrors server.mjs's RE_AID_FAIL_OPEN verbatim (see server.mjs, feature-003
// section, near HOME_OP_TABLE).
const MIRRORED_RE_AID_FAIL_OPEN = /^(?:WARN|ERROR): aid:/m;

{
  assert(MIRRORED_RE_AID_FAIL_OPEN.test("WARN: aid: could not update the shared project registry\n"),
    "B.1: a 'WARN: aid:' line is detected as a fail-open signal");
  assert(MIRRORED_RE_AID_FAIL_OPEN.test("ERROR: aid: /var/lib/aid is not writable and sudo is unavailable.\n"),
    "B.2: the _aid_priv_run real-probe 'ERROR: aid:' line is ALSO detected");
  assert(!MIRRORED_RE_AID_FAIL_OPEN.test("aid projects: '/x' registered in user tier.\n"),
    "B.3: the normal success line (no WARN/ERROR prefix) is NOT flagged");
  assert(!MIRRORED_RE_AID_FAIL_OPEN.test(""),
    "B.4: empty stderr is NOT flagged (clean exit)");
  assert(MIRRORED_RE_AID_FAIL_OPEN.test("some other output\nWARN: aid: degraded\nmore output\n"),
    "B.5: the regex is multiline -- a WARN line anywhere in stderr is caught");
}

// ---------------------------------------------------------------------------
// [C] Live-server integration groups: spawn the REAL server.mjs against a temp
// AID_HOME, dispatching through the REAL bin/aid CLI (never a stub).
// ---------------------------------------------------------------------------

async function runLiveTests() {
  const base = join(tmpdir(), "aid-t013-live-" + Date.now() + "-" + Math.random().toString(36).slice(2));
  const aidHome = join(base, "aid_home");
  makeAidHome(aidHome);
  const project = join(base, "real-project");
  mkdirSync(join(project, ".aid"), { recursive: true });

  // Isolate from the REAL developer $HOME/.aid registry fallback tier (same
  // rationale as the Python twin's TestProjectRegistryRealCliRoundTrip.setUp):
  // loadUnionRepos unions aidHome with $HOME/.aid unless the two coincide, so
  // without this override, the live server's /api/home union (and hence
  // getIdMap's project.remove target resolution) would be polluted by
  // whatever is ACTUALLY registered on the machine running this suite.
  const fakeHome = join(base, "fake_home");
  mkdirSync(fakeHome, { recursive: true });
  const isolatedEnv = { HOME: fakeHome };

  process.stdout.write("\n[C] project.add / project.remove via the REAL bin/aid CLI (live, write-enabled)\n");
  assert(existsSync(BIN_AID), "C.0: real bin/aid exists at " + BIN_AID + " (never a stub for this suite)");

  const s = await spawnServer(aidHome, ["--allow-writes"], isolatedEnv);
  if (!s.ready) {
    assert(false, "server spawned with --allow-writes for group [C]");
  } else {
    assert(true, "server spawned with --allow-writes for group [C]");

    // C.1: relative path -> 400 bad-request, BEFORE any CLI spawn (registry
    // untouched).
    {
      const r = await postJson(s.port, "/api/op", { op: "project.add", args: { path: "relative/path" } });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 400, "C.1: relative path -> 400 (got " + r.status + ")");
      assert(!!(data && data.error === "bad-request"), "C.1b: error class 'bad-request'");
      assertEquals(readRegistryRepos(aidHome).length, 0, "C.1c: registry untouched by the rejected request");
    }

    // C.2: nonexistent path -> 422 invalid-value (real bin/aid's own exit 2).
    {
      const nonexistent = join(base, "does-not-exist-at-all");
      const r = await postJson(s.port, "/api/op", { op: "project.add", args: { path: nonexistent } });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 422, "C.2: nonexistent path -> 422 (got " + r.status + ")");
      assert(!!(data && data.error === "invalid-value"), "C.2b: error class 'invalid-value'");
    }

    // C.3: not-an-AID-project -> 422 invalid-value.
    {
      const notAProject = join(base, "not-an-aid-project");
      mkdirSync(notAProject, { recursive: true });
      const r = await postJson(s.port, "/api/op", { op: "project.add", args: { path: notAProject } });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 422, "C.3: not-an-AID-project -> 422 (got " + r.status + ")");
      assert(!!(data && data.detail && data.detail.includes("not an AID project")),
        "C.3b: detail cites the CLI's own 'not an AID project' message");
    }

    // C.4: happy path add -> 200, registry.yml actually gains an entry.
    let storedPath = null;
    {
      const r = await postJson(s.port, "/api/op", { op: "project.add", args: { path: project } });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 200, "C.4: add happy path -> 200 (got " + r.status + ", body=" + r.body + ")");
      assert(!!(data && data.ok === true && data.op === "project.add"), "C.4b: envelope {ok:true, op:'project.add'}");
      const repos = readRegistryRepos(aidHome);
      assertEquals(repos.length, 1, "C.4c: registry.yml gained exactly one entry");
      storedPath = repos[0] || null;
    }

    // C.5: unknown target.id -> 404 not-found, before any CLI spawn.
    {
      const r = await postJson(s.port, "/api/op", { op: "project.remove", target: { id: "deadbeef" } });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 404, "C.5: unknown target.id -> 404 (got " + r.status + ")");
      assert(!!(data && data.error === "not-found"), "C.5b: error class 'not-found'");
    }

    // C.6: happy path remove -> 200, registry.yml entry actually gone.
    if (storedPath !== null) {
      const id = repoId8(storedPath);
      const r = await postJson(s.port, "/api/op", { op: "project.remove", target: { id } });
      let data = null; try { data = JSON.parse(r.body); } catch (_) {}
      assert(r.status === 200, "C.6: remove happy path -> 200 (got " + r.status + ", body=" + r.body + ")");
      assert(!!(data && data.ok === true && data.op === "project.remove"), "C.6b: envelope {ok:true, op:'project.remove'}");
      assertEquals(readRegistryRepos(aidHome).length, 0, "C.6c: registry.yml entry actually removed");
    } else {
      assert(false, "C.6: skipped -- C.4 did not yield a stored path to remove");
    }
  }
  await killServer(s.proc);

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
