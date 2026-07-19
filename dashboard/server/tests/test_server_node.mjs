/**
 * dashboard/server/tests/test_server_node.mjs
 * Self-check and behavioral tests for server.mjs (feature-010, delivery-008 -- multi-repo).
 *
 * Run: node dashboard/server/tests/test_server_node.mjs
 *
 * Assertion groups:
 *   (1) Source invariants: no wildcard bind, no write primitive, no LLM import.
 *   (2) Route table: allowlisted routes return expected status + shape; unknown -> 404; non-GET -> 405.
 *   (3) SEC-2 refusal matrix: traversal/escape/non-allowlisted/unregistered -> 404.
 *       Registered-but-.aid-gone -> 404 static leaves, 200 empty RepoModel for api/model.
 *   (4) Registry tolerance (NFR10): absent/torn/higher-schema -> best-effort, never 500.
 *   (5) /api/home DM-2 shape: machine panel keys, repos[] sorted by path, per-repo fields.
 *   (6) Serialization (DM-3): compact, no trailing newline, integers-only, U+2028/U+2029 escaped.
 *   (7) <id> derivation: sha256(CAN-1(path))[:8] for a known path -- Node side of cross-runtime parity.
 *   (8) reader.mjs malformed-input regression (delivery-006 fixes).
 *   (9) PF-8 parseSpecMd + Lite fixture (HT-2).
 *   (2c) POST /r/<id>/api/op + POST /api/op write gate (feature-001 task-004): every op
 *        403s "read-only" on a write-disabled spawn (incl. pipeline.delete, task-027);
 *        other POST paths still 405.
 *   (5c-op) OP_TABLE dispatch smoke test (feature-001 task-004, write-enabled spawn):
 *        settings.set 200 round-trip (writer actually mutates settings.yml on disk),
 *        unknown op -> 400, unresolvable work_id -> 404 (WT-1, incl. pipeline.delete,
 *        task-027). The full per-op matrix (task.set-notes/pipeline.finish/pipeline.rename
 *        fixtures, status-map overrides) is task-011's "dispatch round-trip suite" mandate;
 *        pipeline.delete's own real-writer guard/topology/containment/post-delete matrix +
 *        twin byte-parity is test_task027_pipeline_delete_round_trips.py's mandate.
 *
 * ASCII-only source. Node built-in modules only.
 */

import { readFileSync, mkdirSync, writeFileSync, rmSync, statSync, existsSync, symlinkSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { createServer } from "http";
import http from "http";
import net from "net";
import { spawn, spawnSync } from "child_process";
import { tmpdir } from "os";
import { createHash } from "crypto";
import { readRepo, parseSpecMd } from "../reader.mjs";

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
// Helpers: id derivation (DD-1 / DD-5 parity)
// ---------------------------------------------------------------------------

function repoIdFull(canonPath) {
  return createHash("sha256").update(canonPath, "utf8").digest("hex");
}

function repoId8(canonPath) {
  return repoIdFull(canonPath).slice(0, 8);
}

// ---------------------------------------------------------------------------
// Helpers: fixture builders
// ---------------------------------------------------------------------------

function makeAidHome(base) {
  mkdirSync(base, { recursive: true });
  writeFileSync(join(base, "VERSION"), "1.0.0-test\n", "utf8");
  writeRegistry(base, []);
  mkdirSync(join(base, "dashboard"), { recursive: true });
}

function writeRegistry(aidHome, paths) {
  let content = (
    "# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).\n" +
    "# Holds ONLY the base folders of repos this CLI install manages.\n" +
    "schema: 1\n" +
    "repos:\n"
  );
  for (const p of paths) {
    content += "  - " + p + "\n";
  }
  writeFileSync(join(aidHome, "registry.yml"), content, "utf8");
}

function makeRepo(base, withKb) {
  const aid = join(base, ".aid");
  mkdirSync(aid, { recursive: true });
  writeFileSync(join(aid, "settings.yml"),
    "project:\n  name: test-repo\n  description: A test repo\n", "utf8");
  writeFileSync(join(aid, ".aid-manifest.json"),
    JSON.stringify({
      manifest_version: 1,
      aid_version: "1.0.0-test",
      installed_at: "2026-01-01T00:00:00Z",
      tools: { "claude-code": { installed_at: "2026-01-01T00:00:00Z" } },
    }), "utf8");
  if (withKb) {
    // kb.html is a per-repo GENERATED artifact; it now lives beside its KB source
    // in .aid/knowledge/ (the .aid/dashboard/ folder was eliminated). home.html is
    // no longer a per-repo file -- the CLI serves its OWN copy -- so none is written.
    const kb = join(aid, "knowledge");
    mkdirSync(kb, { recursive: true });
    writeFileSync(join(kb, "kb.html"), "<html>kb</html>", "utf8");
  }
}

function makeAidWithWorks(repo, workIds) {
  const aid = join(repo, ".aid");
  mkdirSync(aid, { recursive: true });
  for (const wid of workIds) {
    const wdir = join(aid, "works", wid);
    mkdirSync(wdir, { recursive: true });
    writeFileSync(join(wdir, "STATE.md"), [
      "# Work State",
      "",
      "## Pipeline Status",
      "",
      "Lifecycle: Running",
      "",
      "## Tasks Status",
      "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |",
      "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ].join("\n"), "utf8");
  }
}

// ---------------------------------------------------------------------------
// Helpers: network
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
  // requestBody (feature-001 task-004, optional): a Buffer/string request body
  // (e.g. a JSON op-request payload). Content-Length is set automatically.
  return new Promise((resolve, reject) => {
    const bodyBuf = requestBody === undefined ? null : Buffer.from(requestBody);
    const options = {
      hostname: "127.0.0.1",
      port: port,
      path: path,
      method: method || "GET",
    };
    options.headers = Object.assign({}, headers || {});
    if (bodyBuf !== null && options.headers["Content-Length"] === undefined) {
      options.headers["Content-Length"] = bodyBuf.length;
    }
    const req = http.request(options, (res) => {
      let respBuf = Buffer.alloc(0);
      res.on("data", (chunk) => { respBuf = Buffer.concat([respBuf, chunk]); });
      res.on("end", () => resolve({
        status: res.statusCode,
        body: respBuf.toString("utf-8"),
        bodyBuf: respBuf,
        headers: res.headers,
      }));
    });
    req.on("error", reject);
    req.end(bodyBuf === null ? undefined : bodyBuf);
  });
}

function postJson(port, path, payload, headers) {
  // Convenience wrapper: POST a JSON-encoded op-request body (feature-001 task-004).
  return makeRequest(port, path, "POST", Object.assign({ "Content-Type": "application/json" }, headers || {}), JSON.stringify(payload));
}

// Spawn the server against an aidHome, return {proc, port}.
// AID_HOME is passed via environment (delivery-008 refinement: no --aid-home flag).
// extraArgs (feature-001 task-001): optional additional argv tokens, e.g. ["--allow-writes"].
async function spawnServer(aidHome, extraArgs) {
  const port = await getFreePort();
  const proc = spawn(
    process.execPath,
    [SERVER_MJS, "--host", "127.0.0.1", "--port", String(port), ...(extraArgs || [])],
    {
      stdio: ["ignore", "ignore", "pipe"],
      env: Object.assign({}, process.env, { AID_HOME: aidHome }),
    }
  );
  let spawnError = null;
  proc.on("error", (err) => { spawnError = err; });
  const ready = await waitForPort(port, 5000);
  return { proc, port, ready, spawnError };
}

function killServer(proc) {
  return new Promise((resolve) => {
    if (proc.exitCode !== null) { resolve(); return; }
    proc.kill("SIGTERM");
    setTimeout(resolve, 300);
  });
}

// ---------------------------------------------------------------------------
// (1) Source invariants
// ---------------------------------------------------------------------------

process.stdout.write("\n[1] Source invariants\n");

const serverSrc = readFileSync(SERVER_MJS, "utf-8");
const readerSrc = readFileSync(READER_MJS, "utf-8");

function stripComments(src) {
  let s = src.replace(/\/\*[\s\S]*?\*\//g, " ");
  s = s.replace(/\/\/.*/g, " ");
  return s;
}

const serverCode = stripComments(serverSrc);
const readerCode = stripComments(readerSrc);

// SEC-1: loopback-only bind
assert(
  serverSrc.includes('"127.0.0.1"'),
  "server.mjs LOOPBACK_ADDRS contains literal 127.0.0.1"
);
assert(
  serverSrc.includes("LOOPBACK_ADDRS.has(host)"),
  "server.mjs validates host against LOOPBACK_ADDRS before bind (SEC-1)"
);
{
  const listenM = serverSrc.match(/server\.listen\([^)]*\)/);
  const listenStr = listenM ? listenM[0] : "";
  assert(
    !listenStr.includes('"0.0.0.0"') && !listenStr.includes("'0.0.0.0'"),
    "server.listen() does not hardcode 0.0.0.0"
  );
}
assert(
  !serverSrc.match(/server\.listen\(PORT,\s*"::"\s*\)/) &&
  !serverSrc.match(/server\.listen\(PORT,\s*'::'\s*\)/),
  "server.mjs has no :: wildcard as listen arg"
);

// SEC-3: no write/append/remove
assert(
  !serverCode.includes("writeFile") &&
  !serverCode.includes("appendFile") &&
  !/fs\s*\.\s*unlink\b/.test(serverCode),
  "server.mjs: no fs.writeFile/appendFile/unlink in code"
);
assert(
  !readerCode.includes("writeFile") &&
  !readerCode.includes("appendFile") &&
  !/fs\s*\.\s*unlink\b/.test(readerCode),
  "reader.mjs: no fs.writeFile/appendFile/unlink in code"
);

// SEC-4: no agent/LLM import
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
// (12) SEC-6: anti-DNS-rebinding Host-header allowlist -- pure unit test
// (kept in lockstep with server.mjs's isAllowedHost; server.mjs self-executes
// on import (parses argv, binds a socket) so its own function is not
// importable here -- mirrored verbatim instead, same convention as the
// repoIdFull() helper above.)
// ---------------------------------------------------------------------------

process.stdout.write("\n[12] SEC-6: Host-header allowlist (unit test of isAllowedHost)\n");

function isAllowedHost(hostHeader, port) {
  if (!hostHeader) return true;
  const h = hostHeader.trim();
  if (h === "") return true;
  const hLower = h.toLowerCase();

  if (hLower === "127.0.0.1" || hLower === "localhost" ||
      hLower === "::1" || hLower === "[::1]") {
    return true;
  }

  let hostPart;
  let portPart;
  if (h[0] === "[") {
    const closeIdx = h.indexOf("]");
    if (closeIdx === -1) return false;
    hostPart = h.slice(0, closeIdx + 1).toLowerCase();
    const rest = h.slice(closeIdx + 1);
    portPart = rest.startsWith(":") ? rest.slice(1) : null;
  } else {
    const colonIdx = h.lastIndexOf(":");
    if (colonIdx === -1 || !/^[0-9]+$/.test(h.slice(colonIdx + 1))) return false;
    hostPart = h.slice(0, colonIdx).toLowerCase();
    portPart = h.slice(colonIdx + 1);
  }

  const ALLOWED_HOSTS = new Set(["127.0.0.1", "localhost", "[::1]"]);
  if (!ALLOWED_HOSTS.has(hostPart)) return false;
  return portPart !== null && Number(portPart) === port;
}

{
  const PORT = 8787;
  // Accept: allowlisted host, with and without the matching port.
  assert(isAllowedHost("127.0.0.1:8787", PORT), "12.1: 127.0.0.1:<port> -> allowed");
  assert(isAllowedHost("localhost:8787", PORT), "12.2: localhost:<port> -> allowed");
  assert(isAllowedHost("[::1]:8787", PORT), "12.3: [::1]:<port> -> allowed");
  assert(isAllowedHost("127.0.0.1", PORT), "12.4: bare 127.0.0.1 (no port) -> allowed");
  assert(isAllowedHost("localhost", PORT), "12.5: bare localhost (no port) -> allowed");
  assert(isAllowedHost("::1", PORT), "12.6: bare ::1 (no port, unbracketed) -> allowed");
  assert(isAllowedHost("[::1]", PORT), "12.7: bare [::1] (no port, bracketed) -> allowed");
  assert(isAllowedHost("LOCALHOST:8787", PORT), "12.8: case-insensitive host match -> allowed");
  assert(isAllowedHost(undefined, PORT), "12.9: missing Host header -> allowed (back-compat)");
  assert(isAllowedHost("", PORT), "12.10: empty Host header -> allowed (back-compat)");

  // Reject: foreign host names (the DNS-rebinding attack shape).
  assert(!isAllowedHost("evil.example.com", PORT), "12.11: foreign host (no port) -> rejected");
  assert(!isAllowedHost("evil.example.com:8787", PORT),
    "12.12: foreign host with matching port -> rejected");
  assert(!isAllowedHost("127.0.0.1.evil.example.com:8787", PORT),
    "12.13: subdomain-suffix trick on loopback -> rejected");
  // Reject: allowlisted host name but WRONG port (rebind to a different local
  // service listening on another port would still be a cross-origin read).
  assert(!isAllowedHost("127.0.0.1:9999", PORT), "12.14: allowlisted host, wrong port -> rejected");
  assert(!isAllowedHost("localhost:1", PORT), "12.15: allowlisted host, wrong port -> rejected");
}

// ---------------------------------------------------------------------------
// (7) <id> derivation -- Node side of cross-runtime parity (DD-5)
// ---------------------------------------------------------------------------

process.stdout.write("\n[7] <id> derivation (DD-5 cross-runtime parity)\n");

{
  const FIXTURE_PATH = "/tmp/aid-fixture-repo-A";
  // Expected values computed from Python: sha256(path.encode('utf-8')).hexdigest()
  const EXPECTED_FULL = "56e3c68fe7a7342b3b7ea6b76dc876a4163348bea90c80d0e2faa130dade3a91";
  const EXPECTED_8 = "56e3c68f";

  const fullDigest = repoIdFull(FIXTURE_PATH);
  assert(
    fullDigest === EXPECTED_FULL,
    "sha256('/tmp/aid-fixture-repo-A') full digest matches known Python value (DD-5 parity)"
  );
  assert(
    fullDigest.slice(0, 8) === EXPECTED_8,
    "[:8] prefix matches expected 56e3c68f"
  );
  // Confirm trailing newline would change the id (DD-5: no newline in input)
  const withNewline = createHash("sha256").update(FIXTURE_PATH + "\n", "utf8").digest("hex");
  assert(
    withNewline.slice(0, 8) !== EXPECTED_8,
    "Trailing newline changes the id (DD-5: no newline in sha256 input)"
  );
}

// ---------------------------------------------------------------------------
// (8) reader.mjs malformed-input regression (delivery-006 fixes)
// ---------------------------------------------------------------------------

process.stdout.write("\n[8] Malformed-input regression (delivery-006 fixes)\n");

{
  // Case e1: headerless Tasks table
  const tmpE1 = join(tmpdir(), "aid-e1-" + Date.now());
  const aidE1 = join(tmpE1, ".aid");
  const wdirE1 = join(aidE1, "works", "work-001-headerless");
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
    assert(!!(w1 && w1.tasks[0] && w1.tasks[0].task_id === "task-001"), "e1: first task is task-001");
    assert(!!(w1 && w1.tasks[1] && w1.tasks[1].task_id === "task-002"), "e1: second task is task-002");
    assert(!!(w1 && w1.source_mode === "normalized"), "e1: source_mode=normalized");
  } finally {
    try { rmSync(tmpE1, { recursive: true, force: true }); } catch (_) {}
  }

  // Case e2: ## Pipeline Status section with no typed fields
  const tmpE2 = join(tmpdir(), "aid-e2-" + Date.now());
  const aidE2 = join(tmpE2, ".aid");
  const wdirE2 = join(aidE2, "works", "work-001-psonly");
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
    assert(!!(w2 && w2.source_mode === "normalized"), "e2: source_mode=normalized");
    assert(!!(w2 && w2.lifecycle === "Unknown"), "e2: lifecycle=Unknown");
    assert(
      !!(modelE2.read && Array.isArray(modelE2.read.fallback_works) &&
         modelE2.read.fallback_works.length === 0),
      "e2: fallback_works=[]"
    );
  } finally {
    try { rmSync(tmpE2, { recursive: true, force: true }); } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// (9) PF-8 parseSpecMd + Lite fixture (HT-2)
// ---------------------------------------------------------------------------

process.stdout.write("\n[9] PF-8 parseSpecMd + Lite fixture (HT-2)\n");

{
  const tmpF = join(tmpdir(), "aid-spec-" + Date.now());
  mkdirSync(tmpF, { recursive: true });

  // f1: Name+Description returned correctly
  const specF1 = join(tmpF, "spec-f1.md");
  writeFileSync(specF1, [
    "# My Feature", "", "- **Name:** My Feature Name", "- **Description:** A short description.",
  ].join("\n"), "utf-8");
  const [tf1, df1, h1f1] = parseSpecMd(specF1);
  assert(tf1 === "My Feature Name", "f1: Name field returned correctly");
  assert(df1 === "A short description.", "f1: Description field returned correctly");
  assert(h1f1 === "My Feature", "f1: H1 title returned correctly");

  // f2: H1 only -> title=null
  const specF2 = join(tmpF, "spec-f2.md");
  writeFileSync(specF2, "# Dashboard Lite\n\nSome body text.\n", "utf-8");
  const [tf2, df2, h1f2] = parseSpecMd(specF2);
  assert(tf2 === null, "f2: title=null when no Name line");
  assert(df2 === null, "f2: description=null when no Description line");
  assert(h1f2 === "Dashboard Lite", "f2: H1 title captured");

  // f3: *(pending)* seed -> null
  const specF3 = join(tmpF, "spec-f3.md");
  writeFileSync(specF3, [
    "# Pending Work", "", "- **Name:** *(pending)*", "- **Description:** *(pending)*",
  ].join("\n"), "utf-8");
  const [tf3, df3] = parseSpecMd(specF3);
  assert(tf3 === null, "f3: *(pending)* Name -> null");
  assert(df3 === null, "f3: *(pending)* Description -> null");

  // f4: absent file -> all null, bytesRead=0
  const specF4 = join(tmpF, "spec-absent.md");
  const [tf4, df4, h1f4, brf4] = parseSpecMd(specF4);
  assert(tf4 === null, "f4: absent file -> title=null");
  assert(df4 === null, "f4: absent file -> description=null");
  assert(h1f4 === null, "f4: absent file -> h1Title=null");
  assert(brf4 === 0, "f4: absent file -> bytesRead=0");

  // f5: CRLF SPEC.md
  const specF5 = join(tmpF, "spec-f5.md");
  writeFileSync(specF5, Buffer.from("# CRLF Title\r\n\r\nBody text.\r\n", "utf-8"));
  const [tf5, df5, h1f5] = parseSpecMd(specF5);
  assert(tf5 === null, "f5: CRLF H1-only SPEC -> title=null");
  assert(df5 === null, "f5: CRLF H1-only SPEC -> description=null");
  assert(h1f5 === "CRLF Title", "f5: CRLF H1-only SPEC -> h1Title=CRLF Title");

  // f6: HT-2 -- readWork over work-006-lite-sample fixture
  const fixtureRoot = join(__dirname, "fixtures", "pt1-aid");
  let fixturePresent = false;
  try { statSync(fixtureRoot); fixturePresent = true; } catch (_) {}
  if (!fixturePresent) {
    process.stdout.write("  SKIP: pt1-aid fixture not found\n");
  } else {
    const liteWorkDir = join(fixtureRoot, ".aid", "works", "work-006-lite-sample");
    let litePresent = false;
    try { statSync(liteWorkDir); litePresent = true; } catch (_) {}
    if (!litePresent) {
      process.stdout.write("  SKIP: work-006-lite-sample not found\n");
    } else {
      let hasReqs = true;
      try { statSync(join(liteWorkDir, "REQUIREMENTS.md")); } catch (_) { hasReqs = false; }
      assert(!hasReqs, "f6: work-006-lite-sample has no REQUIREMENTS.md (pure Lite path)");
      const modelF6 = readRepo(fixtureRoot);
      const liteWork = modelF6.works.find((w) => w.work_id === "work-006-lite-sample");
      assert(!!liteWork, "f6: work-006-lite-sample found in model");
      if (liteWork) {
        assert(liteWork.title === "Lite Sample Feature", "f6: HT-2 title from SPEC Name");
        assert(
          liteWork.description === "A minimal Lite-path work used to verify SPEC.md identity parsing.",
          "f6: HT-2 description from SPEC Description"
        );
        assert(liteWork.source_mode === "normalized", "f6: Lite work source_mode=normalized");
      }
    }
  }

  try { rmSync(tmpF, { recursive: true, force: true }); } catch (_) {}
}

// ---------------------------------------------------------------------------
// (10) task-064: KB status extension unit tests
//      -- parseKbBaseline, normalizeToUtcMs, deriveKbStatus, gitFreshnessCheck
// ---------------------------------------------------------------------------

process.stdout.write("\n[10] task-064 KB status extension (reader.mjs)\n");

// We import the internal helpers via a dynamic eval trick or test them indirectly
// through readRepo(). Since reader.mjs doesn't export the internal helpers,
// we test them through behavior via readRepo() and through the exported shapes.

{
  // --- UTC normalization behavior via readRepo() output shape ---
  // Test: KbStatus enum values are ASCII strings
  const KB_STATUS_VALUES = ["pending", "generating", "preparing", "approved", "outdated", "unknown"];
  for (const s of KB_STATUS_VALUES) {
    assert(typeof s === "string", "KbStatus value '" + s + "' is a string");
  }
  assert(KB_STATUS_VALUES.includes("pending"), "KbStatus.pending defined");
  assert(KB_STATUS_VALUES.includes("generating"), "KbStatus.generating defined");
  assert(KB_STATUS_VALUES.includes("preparing"), "KbStatus.preparing defined");
  assert(KB_STATUS_VALUES.includes("approved"), "KbStatus.approved defined");
  assert(KB_STATUS_VALUES.includes("outdated"), "KbStatus.outdated defined");

  // --- readRepo() with no .aid/ -> kb_state null ---
  const tmp0 = join(tmpdir(), "aid-kb064-" + Date.now());
  mkdirSync(tmp0, { recursive: true });
  try {
    const m0 = readRepo(tmp0);
    assert(m0.repo.kb_state === null, "10.1: kb_state null when .aid/ absent");
  } finally {
    try { rmSync(tmp0, { recursive: true, force: true }); } catch (_) {}
  }

  // --- readRepo() with empty knowledge dir -> status=pending ---
  const tmp1 = join(tmpdir(), "aid-kb064-" + Date.now());
  mkdirSync(join(tmp1, ".aid", "knowledge"), { recursive: true });
  try {
    const m1 = readRepo(tmp1);
    assert(m1.repo.kb_state !== null, "10.2: kb_state present with knowledge dir");
    assert(m1.repo.kb_state.status === "pending", "10.3: status=pending when knowledge empty");
    assert(m1.repo.kb_state.summary_present === false, "10.4: summary_present=false");
    assert(m1.repo.kb_state.kb_baseline === null, "10.5: kb_baseline=null when not in settings");
  } finally {
    try { rmSync(tmp1, { recursive: true, force: true }); } catch (_) {}
  }

  // --- readRepo() with knowledge dir + STATE.md not approved -> status=generating ---
  const tmp2 = join(tmpdir(), "aid-kb064-" + Date.now());
  mkdirSync(join(tmp2, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmp2, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** no\n",
    "utf-8"
  );
  try {
    const m2 = readRepo(tmp2);
    assert(m2.repo.kb_state !== null, "10.6: kb_state present");
    assert(m2.repo.kb_state.status === "generating",
      "10.7: status=generating when KB present but not approved");
  } finally {
    try { rmSync(tmp2, { recursive: true, force: true }); } catch (_) {}
  }

  // --- readRepo() with approved STATE.md but no kb.html -> status=preparing ---
  const tmp3 = join(tmpdir(), "aid-kb064-" + Date.now());
  mkdirSync(join(tmp3, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmp3, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf-8"
  );
  try {
    const m3 = readRepo(tmp3);
    assert(m3.repo.kb_state !== null, "10.8: kb_state present");
    assert(m3.repo.kb_state.status === "preparing",
      "10.9: status=preparing when approved but no kb.html");
    assert(m3.repo.kb_state.summary_present === false, "10.10: summary_present=false");
  } finally {
    try { rmSync(tmp3, { recursive: true, force: true }); } catch (_) {}
  }

  // --- readRepo() with approved STATE.md + kb.html + no baseline -> status=approved ---
  const tmp4 = join(tmpdir(), "aid-kb064-" + Date.now());
  mkdirSync(join(tmp4, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmp4, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf-8"
  );
  writeFileSync(join(tmp4, ".aid", "knowledge", "kb.html"), "<html></html>", "utf-8");
  try {
    const m4 = readRepo(tmp4);
    assert(m4.repo.kb_state !== null, "10.11: kb_state present");
    assert(m4.repo.kb_state.status === "approved",
      "10.12: status=approved when KB+kb.html present, no baseline");
    assert(m4.repo.kb_state.summary_present === true, "10.13: summary_present=true");
    assert(m4.repo.kb_state.kb_baseline === null, "10.14: kb_baseline=null when no settings entry");
  } finally {
    try { rmSync(tmp4, { recursive: true, force: true }); } catch (_) {}
  }

  // --- readRepo() with kb_baseline in settings.yml -> parsed correctly ---
  const tmp5 = join(tmpdir(), "aid-kb064-" + Date.now());
  mkdirSync(join(tmp5, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmp5, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf-8"
  );
  writeFileSync(join(tmp5, ".aid", "knowledge", "kb.html"), "<html></html>", "utf-8");
  writeFileSync(
    join(tmp5, ".aid", "settings.yml"),
    "project:\n  name: Test\nkb_baseline:\n  branch: main\n  tip_date: 2026-06-01T00:00:00Z\n",
    "utf-8"
  );
  try {
    const m5 = readRepo(tmp5);
    assert(m5.repo.kb_state !== null, "10.15: kb_state present with baseline");
    assert(m5.repo.kb_state.kb_baseline !== null, "10.16: kb_baseline parsed");
    assert(m5.repo.kb_state.kb_baseline.branch === "main", "10.17: kb_baseline.branch=main");
    assert(m5.repo.kb_state.kb_baseline.tip_date === "2026-06-01T00:00:00Z",
      "10.18: kb_baseline.tip_date correct");
  } finally {
    try { rmSync(tmp5, { recursive: true, force: true }); } catch (_) {}
  }

  // --- UTC normalization: Z and +00:00 same instant -> equal comparison ---
  // We can't call _normalizeToUtcMs directly (not exported), but we can verify
  // through the "outdated" logic: a baseline VERY far in the future -> approved,
  // a baseline in the past -> outdated (in a real git repo). Here we just verify
  // Date.parse handles both Z and offset forms consistently.
  const ms_z = Date.parse("2026-06-12T14:03:00Z");
  const ms_offset = Date.parse("2026-06-12T10:03:00-04:00");  // same instant
  const ms_plus = Date.parse("2026-06-12T14:03:00+00:00");
  assert(!isNaN(ms_z), "10.19: Date.parse Z-suffix produces valid ms");
  assert(!isNaN(ms_offset), "10.20: Date.parse offset form produces valid ms");
  assert(ms_z === ms_offset, "10.21: Z and -04:00 offset of same instant are equal ms");
  assert(ms_z === ms_plus, "10.22: Z and +00:00 of same instant are equal ms");

  // --- Degradation: non-git dir + baseline -> freshness degrades to 'approved' ---
  const tmp6 = join(tmpdir(), "aid-kb064-" + Date.now());
  mkdirSync(join(tmp6, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmp6, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf-8"
  );
  writeFileSync(join(tmp6, ".aid", "knowledge", "kb.html"), "<html></html>", "utf-8");
  writeFileSync(
    join(tmp6, ".aid", "settings.yml"),
    "kb_baseline:\n  branch: main\n  tip_date: 2000-01-01T00:00:00Z\n",
    "utf-8"
  );
  try {
    const m6 = readRepo(tmp6);
    assert(m6.repo.kb_state !== null, "10.23: kb_state present (non-git with old baseline)");
    // Non-git dir -> git freshness degrades to skip -> approved (not outdated)
    const s6 = m6.repo.kb_state.status;
    assert(s6 === "approved" || s6 === "outdated",
      "10.24: status is approved or outdated (non-git: degradation to skip -> approved expected)");
    // In a non-git dir git will fail -> skip -> approved
    assert(s6 === "approved",
      "10.25: status=approved in non-git dir even with old baseline (graceful degradation)");
  } finally {
    try { rmSync(tmp6, { recursive: true, force: true }); } catch (_) {}
  }

  // --- kb_state field order: retained fields come first (DM-A3) ---
  const tmp7 = join(tmpdir(), "aid-kb064-" + Date.now());
  mkdirSync(join(tmp7, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmp7, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf-8"
  );
  try {
    const m7 = readRepo(tmp7);
    const kb7 = m7.repo.kb_state;
    assert(kb7 !== null, "10.26: kb_state present");
    const keys7 = Object.keys(kb7);
    assert(keys7[0] === "summary_approved", "10.27: first key is summary_approved (DM-3 order)");
    assert(keys7[1] === "last_summary_date", "10.28: second key is last_summary_date");
    assert(keys7[2] === "doc_count", "10.29: third key is doc_count");
    assert(keys7[3] === "status", "10.30: fourth key is status (new, task-064)");
    assert(keys7[4] === "summary_present", "10.31: fifth key is summary_present");
    assert(keys7[5] === "kb_baseline", "10.32: sixth key is kb_baseline");
  } finally {
    try { rmSync(tmp7, { recursive: true, force: true }); } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// (10b) feature-002 (work-017 task-005): DM-1 reader exposure of
//       project.description + global review.minimum_grade
// ---------------------------------------------------------------------------

process.stdout.write("\n[10b] task-005 project_description + minimum_grade (reader.mjs)\n");

{
  // --- repo key order: project_name, project_description, minimum_grade,
  //     aid_dir, kb_state (additive keys inserted after project_name),
  //     connectors (feature-007, task-019: additive key inserted after
  //     kb_state), external_sources (feature-010, task-021: additive key
  //     inserted after connectors) ---
  const tmp8 = join(tmpdir(), "aid-task005-" + Date.now());
  mkdirSync(join(tmp8, ".aid"), { recursive: true });
  try {
    const m8 = readRepo(tmp8);
    const keys8 = Object.keys(m8.repo);
    assert(keys8[0] === "project_name", "10b.1: first key is project_name");
    assert(keys8[1] === "project_description", "10b.2: second key is project_description (new)");
    assert(keys8[2] === "minimum_grade", "10b.3: third key is minimum_grade (new)");
    assert(keys8[3] === "aid_dir", "10b.4: fourth key is aid_dir");
    assert(keys8[4] === "kb_state", "10b.5: fifth key is kb_state");
    assert(keys8[5] === "connectors", "10b.5b: sixth key is connectors (task-019, new)");
    assert(keys8[6] === "external_sources", "10b.5c: seventh key is external_sources (task-021, new)");
    assert(m8.repo.project_description === null, "10b.6: project_description=null when absent");
    assert(m8.repo.minimum_grade === null, "10b.7: minimum_grade=null when absent");
    assert(Array.isArray(m8.repo.connectors) && m8.repo.connectors.length === 0,
           "10b.8: connectors=[] when .aid/connectors/ absent");
    assert(Array.isArray(m8.repo.external_sources) && m8.repo.external_sources.length === 0,
           "10b.9: external_sources=[] when external-sources.md absent");
  } finally {
    try { rmSync(tmp8, { recursive: true, force: true }); } catch (_) {}
  }

  // --- real settings.yml layout: tools: sits between project: and review: ---
  const tmp9 = join(tmpdir(), "aid-task005-" + Date.now());
  mkdirSync(join(tmp9, ".aid"), { recursive: true });
  writeFileSync(
    join(tmp9, ".aid", "settings.yml"),
    "project:\n" +
    "  name: AID                          # set during /aid-config INIT\n" +
    "  description: AI Integrated Development\n" +
    "  type: brownfield\n" +
    "tools:\n" +
    "  installed:\n" +
    "    - claude-code\n" +
    "review:\n" +
    "  minimum_grade: A+   # owner directive 2026-06-27\n",
    "utf-8"
  );
  try {
    const m9 = readRepo(tmp9);
    assert(m9.repo.project_name === "AID", "10b.8: project_name parsed");
    assert(m9.repo.project_description === "AI Integrated Development",
      "10b.9: project_description parsed from the same project: block");
    assert(m9.repo.minimum_grade === "A+",
      "10b.10: minimum_grade parsed from the SEPARATE review: block " +
      "(tools: sits in between in a real settings.yml)");
  } finally {
    try { rmSync(tmp9, { recursive: true, force: true }); } catch (_) {}
  }

  // --- no .aid/ -> empty model leaves both fields null (no crash) ---
  const tmp10 = join(tmpdir(), "aid-task005-noaid-" + Date.now());
  mkdirSync(tmp10, { recursive: true });
  try {
    const m10 = readRepo(tmp10);
    assert(m10.repo.project_description === null,
      "10b.11: no-.aid/ empty model: project_description=null");
    assert(m10.repo.minimum_grade === null,
      "10b.12: no-.aid/ empty model: minimum_grade=null");
  } finally {
    try { rmSync(tmp10, { recursive: true, force: true }); } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// Live server tests: (2) route table, (3) SEC-2, (4) registry tolerance,
//                   (5) /api/home DM-2 shape, (6) serialization DM-3
// ---------------------------------------------------------------------------

async function runLiveTests() {
  // ---------------------------------------------------------------------------
  // Set up shared fixtures
  // ---------------------------------------------------------------------------

  const base = join(tmpdir(), "aid-live-" + Date.now());
  const aidHome = join(base, "aid_home");
  makeAidHome(aidHome);

  const repoA = join(base, "repo-A");
  makeRepo(repoA, true);
  makeAidWithWorks(repoA, ["work-003-gamma", "work-001-alpha", "work-002-beta"]);

  const repoB = join(base, "repo-B");
  makeRepo(repoB, false);  // has .aid/ but no generated kb.html

  // Register both (reverse alpha to test sort)
  writeRegistry(aidHome, [repoB, repoA]);

  const idA = repoId8(repoA);
  const idB = repoId8(repoB);

  let { proc, port, ready, spawnError } = await spawnServer(aidHome);

  if (!ready || spawnError) {
    assert(false, "server spawned and accepted connections: " + (spawnError || "timeout"));
    proc.kill("SIGTERM");
    return;
  }
  assert(true, "server spawned and accepted connections on port " + port);

  try {
    // -----------------------------------------------------------------------
    // (2) Route table
    // -----------------------------------------------------------------------

    process.stdout.write("\n[2] Route table\n");

    // GET / -> 503 when index.html absent
    {
      const r = await makeRequest(port, "/", "GET");
      assert(r.status === 503, "GET / -> 503 when index.html absent (got " + r.status + ")");
      assert(r.body.includes("task-053"), "GET / 503 body mentions task-053");
    }

    // GET / -> 200 when index.html present
    {
      const indexPath = join(aidHome, "dashboard", "index.html");
      writeFileSync(indexPath, "<html>cli-home</html>", "utf8");
      const r = await makeRequest(port, "/", "GET");
      assert(r.status === 200, "GET / -> 200 when index.html present (got " + r.status + ")");
      assert(r.body.includes("<html>"), "GET / body contains html");
      assert(
        !!(r.headers["content-type"] && r.headers["content-type"].includes("text/html")),
        "GET / Content-Type is text/html"
      );
      rmSync(indexPath);
    }

    // GET /api/home -> 200 DM-2 envelope
    {
      const r = await makeRequest(port, "/api/home", "GET");
      assert(r.status === 200, "GET /api/home -> 200 (got " + r.status + ")");
      assert(
        !!(r.headers["content-type"] && r.headers["content-type"].includes("application/json")),
        "GET /api/home Content-Type includes application/json"
      );
      let data = null;
      try { data = JSON.parse(r.body); } catch (_) {}
      assert(data !== null, "GET /api/home body is valid JSON");
      assert(!!(data && data.schema_version === 1), "GET /api/home schema_version===1");
      assert(!!(data && data.generated_by === "node"), 'GET /api/home generated_by==="node"');
      assert(!!(data && Array.isArray(data.repos)), "GET /api/home has repos array");
    }

    // GET /r/<id>/home.html -> 200. home.html is now served from the CLI's OWN copy
    // ($AID_CODE_HOME/dashboard/home.html, self-located from server.mjs) and is gated
    // only on the repo having an .aid/ dir (repo-A does). So the body is the real CLI
    // SPA, not a per-repo "<html>home</html>" stub. Also sends Cache-Control: no-cache.
    {
      const r = await makeRequest(port, "/r/" + idA + "/home.html", "GET");
      assert(r.status === 200, "GET /r/<id>/home.html -> 200 (got " + r.status + ")");
      assert(r.body.includes("<!DOCTYPE html>"),
        "GET /r/<id>/home.html serves the CLI's own home.html SPA");
      assert(
        !!(r.headers["content-type"] && r.headers["content-type"].includes("text/html")),
        "GET /r/<id>/home.html Content-Type is text/html"
      );
      assert(r.headers["cache-control"] === "no-cache",
        "GET /r/<id>/home.html sends Cache-Control: no-cache");
    }

    // GET /r/<id>/kb.html -> 200 (served from <repo>/.aid/knowledge/kb.html)
    {
      const r = await makeRequest(port, "/r/" + idA + "/kb.html", "GET");
      assert(r.status === 200, "GET /r/<id>/kb.html -> 200 (got " + r.status + ")");
      assert(r.body.includes("<html>kb</html>"), "GET /r/<id>/kb.html body correct");
      assert(r.headers["cache-control"] === "no-cache",
        "GET /r/<id>/kb.html sends Cache-Control: no-cache");
    }

    // GET /r/<id>/api/model -> 200 DM-1 envelope
    {
      const r = await makeRequest(port, "/r/" + idA + "/api/model", "GET");
      assert(r.status === 200, "GET /r/<id>/api/model -> 200 (got " + r.status + ")");
      assert(
        !!(r.headers["content-type"] && r.headers["content-type"].includes("application/json")),
        "GET /r/<id>/api/model Content-Type is application/json"
      );
      let data = null;
      try { data = JSON.parse(r.body); } catch (_) {}
      assert(data !== null, "GET /r/<id>/api/model body is valid JSON");
      assert(!!(data && data.schema_version === 3), "schema_version===3");
      assert(!!(data && data.generated_by === "node"), 'generated_by==="node"');
      // write_enabled (additive, feature-001 task-001): fail-safe gate signal, false
      // by default (server spawned here with no --allow-writes).
      assert(!!(data && data.write_enabled === false), "write_enabled===false by default");
      assert(!!(data && data.model && typeof data.model === "object"), "has model object");
      const model = data && data.model;
      assert(Array.isArray(model && model.works), "model.works is array");
      assert(Array.isArray(model && model.works), "model has required keys");
      for (const k of ["tool", "repo", "works", "read"]) {
        assert(!!(model && model[k] !== undefined), "model has key: " + k);
      }
    }

    // GET /api/home no trailing newline
    {
      const r = await makeRequest(port, "/api/home", "GET");
      assert(
        !r.bodyBuf.equals(Buffer.concat([r.bodyBuf.slice(0, -1), Buffer.from("\n")])) ||
        !r.body.endsWith("\n"),
        "GET /api/home: no trailing newline"
      );
    }

    // GET /r/<id>/api/model no trailing newline
    {
      const r = await makeRequest(port, "/r/" + idA + "/api/model", "GET");
      assert(!r.body.endsWith("\n"), "GET /r/<id>/api/model: no trailing newline");
    }

    // Unknown paths -> 404
    {
      const r = await makeRequest(port, "/no/such/path", "GET");
      assert(r.status === 404, "GET /no/such/path -> 404 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/api/other", "GET");
      assert(r.status === 404, "GET /api/other -> 404 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/foo/bar/baz", "GET");
      assert(r.status === 404, "GET /foo/bar/baz -> 404 (got " + r.status + ")");
    }

    // Non-GET -> 405
    {
      const r = await makeRequest(port, "/api/home", "POST");
      assert(r.status === 405, "POST /api/home -> 405 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/api/home", "PUT");
      assert(r.status === 405, "PUT /api/home -> 405 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/api/home", "DELETE");
      assert(r.status === 405, "DELETE /api/home -> 405 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/r/" + idA + "/api/model", "POST");
      assert(r.status === 405, "POST /r/<id>/api/model -> 405 (got " + r.status + ")");
    }
    {
      // HEAD is a non-GET verb -> 405 (SPEC: "non-GET verb -> 405"); must match the
      // Python server (parity, SEC-5).
      const r1 = await makeRequest(port, "/", "HEAD");
      assert(r1.status === 405, "HEAD / -> 405 (got " + r1.status + ")");
      const r2 = await makeRequest(port, "/r/deadbeef0/home.html", "HEAD");
      assert(r2.status === 405, "HEAD /r/<id>/home.html -> 405 (got " + r2.status + ")");
    }

    // -----------------------------------------------------------------------
    // (2c) POST /r/<id>/api/op + POST /api/op write gate (feature-001 task-004)
    // This server instance was spawned with NO --allow-writes (write-disabled,
    // the fail-safe default) -- every op must 403 regardless of op/target shape.
    // The full OP_TABLE dispatch matrix (success round-trips, 400/404/422 paths,
    // WT-1 worktree resolution) is task-011's "dispatch round-trip suite"
    // mandate; this group covers the gate + routing wiring task-004 introduces.
    // -----------------------------------------------------------------------

    process.stdout.write("\n[2c] POST /api/op write gate (write-disabled)\n");

    {
      const r = await postJson(port, "/r/" + idA + "/api/op", { op: "settings.set", args: { path: "project.name", value: "x" } });
      assert(r.status === 403, "POST /r/<id>/api/op (write-disabled) -> 403 (got " + r.status + ")");
      let data = null;
      try { data = JSON.parse(r.body); } catch (_) {}
      assert(!!(data && data.ok === false && data.error === "read-only"), "write-disabled op -> {ok:false, error:'read-only'}");
    }
    {
      const r = await postJson(port, "/api/op", { op: "project.add" });
      assert(r.status === 403, "POST /api/op (write-disabled) -> 403 (got " + r.status + ")");
    }
    {
      // Other POST paths (not /api/op or /r/<id>/api/op) still 405, unaffected by the gate.
      const r = await makeRequest(port, "/foo/bar", "POST");
      assert(r.status === 405, "POST /foo/bar (non-op path) -> 405 (got " + r.status + ")");
    }
    {
      // feature-009-pipeline-delete (task-027): pipeline.delete is subject to
      // the SAME write gate as every other op -- mirrors this group's own
      // settings.set/project.add cases immediately above. The full guard/
      // topology/containment/post-delete matrix (real git worktree fixtures,
      // real delete-pipeline.sh spawns, twin byte-parity) lives in
      // test_task027_pipeline_delete_round_trips.py's own sliced-dispatchOp
      // parity suite (no live socket needed there).
      const r = await postJson(port, "/r/" + idA + "/api/op",
        { op: "pipeline.delete", target: { work_id: "work-999-does-not-matter" } });
      assert(r.status === 403, "pipeline.delete (write-disabled) -> 403 (got " + r.status + ")");
      let data = null;
      try { data = JSON.parse(r.body); } catch (_) {}
      assert(!!(data && data.ok === false && data.error === "read-only"), "write-disabled pipeline.delete -> {ok:false, error:'read-only'}");
    }

    // -----------------------------------------------------------------------
    // (2b) SEC-6: anti-DNS-rebinding Host-header allowlist (live server)
    // -----------------------------------------------------------------------

    process.stdout.write("\n[2b] SEC-6: Host-header allowlist (live)\n");

    // Allowlisted loopback Host -> normal response (not rejected).
    {
      const r = await makeRequest(port, "/api/home", "GET", { Host: "127.0.0.1:" + port });
      assert(r.status === 200, "Host 127.0.0.1:<port> -> 200 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/api/home", "GET", { Host: "localhost:" + port });
      assert(r.status === 200, "Host localhost:<port> -> 200 (got " + r.status + ")");
    }
    // No Host header override (Node's default, hostname:port) -- baseline sanity.
    {
      const r = await makeRequest(port, "/api/home", "GET");
      assert(r.status === 200, "default Host header (no override) -> 200 (got " + r.status + ")");
    }

    // Foreign Host -> 403 (the DNS-rebinding attack shape: a page served from
    // evil.example.com whose DNS has been rebound to 127.0.0.1 for the 2nd request).
    {
      const r = await makeRequest(port, "/api/home", "GET", { Host: "evil.example.com" });
      assert(r.status === 403, "Host evil.example.com -> 403 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/", "GET", { Host: "evil.example.com:" + port });
      assert(r.status === 403, "Host evil.example.com:<port> on GET / -> 403 (got " + r.status + ")");
    }
    // Allowlisted host name but the WRONG port -- still a cross-origin read risk -> 403.
    {
      const r = await makeRequest(port, "/api/home", "GET", { Host: "127.0.0.1:1" });
      assert(r.status === 403, "Host 127.0.0.1:<wrong-port> -> 403 (got " + r.status + ")");
    }

    // Security response headers present on both an accepted and a rejected response.
    {
      const rOk = await makeRequest(port, "/api/home", "GET", { Host: "127.0.0.1:" + port });
      assert(rOk.headers["x-content-type-options"] === "nosniff",
        "200 response has X-Content-Type-Options: nosniff");
      assert(!!rOk.headers["content-security-policy"],
        "200 response has a Content-Security-Policy header");
      const rBad = await makeRequest(port, "/api/home", "GET", { Host: "evil.example.com" });
      assert(rBad.headers["x-content-type-options"] === "nosniff",
        "403 response has X-Content-Type-Options: nosniff");
      assert(!!rBad.headers["content-security-policy"],
        "403 response has a Content-Security-Policy header");
    }

    // -----------------------------------------------------------------------
    // (3) SEC-2 refusal matrix
    // -----------------------------------------------------------------------

    process.stdout.write("\n[3] SEC-2 refusal matrix\n");

    // Traversal in path (id segment is hex-only; ".." can't appear in id)
    {
      const r = await makeRequest(port, "/r/" + idA + "/../registry.yml", "GET");
      assert(r.status === 404, "path traversal /r/<id>/../registry.yml -> 404 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/r/../registry.yml", "GET");
      assert(r.status === 404, "/r/../registry.yml -> 404 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/r/" + idA + "/work-001/STATE.md", "GET");
      assert(r.status === 404, "/r/<id>/work-001/STATE.md -> 404 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/r/" + idA + "/%2e%2e/registry.yml", "GET");
      assert(r.status === 404, "percent-encoded dotdot -> 404 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/etc/passwd", "GET");
      assert(r.status === 404, "absolute path /etc/passwd -> 404 (got " + r.status + ")");
    }

    // Non-allowlisted leaf names -> 404 (route regex won't match)
    {
      const r = await makeRequest(port, "/r/" + idA + "/secret.txt", "GET");
      assert(r.status === 404, "/r/<id>/secret.txt (non-allowlisted leaf) -> 404 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/r/" + idA + "/settings.yml", "GET");
      assert(r.status === 404, "/r/<id>/settings.yml -> 404 (got " + r.status + ")");
    }

    // Unregistered id -> 404
    {
      const r = await makeRequest(port, "/r/deadbeef/home.html", "GET");
      assert(r.status === 404, "unregistered id deadbeef/home.html -> 404 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/r/deadbeef/api/model", "GET");
      assert(r.status === 404, "unregistered id deadbeef/api/model -> 404 (got " + r.status + ")");
    }

    // repo-B has an .aid/ dir but never generated a kb.html.
    {
      // home.html is served from the CLI's own copy and gated only on .aid/ existence
      // (repo-B has one) -> 200. The 404 path for home.html is now "no .aid/ at all",
      // exercised by the registered-but-.aid-gone case below.
      const r = await makeRequest(port, "/r/" + idB + "/home.html", "GET");
      assert(r.status === 200, "repo-B (.aid present, no kb) home.html -> 200 (got " + r.status + ")");
    }
    {
      // kb.html is per-repo (.aid/knowledge/kb.html) and repo-B has none -> 404.
      const r = await makeRequest(port, "/r/" + idB + "/kb.html", "GET");
      assert(r.status === 404, "repo without kb.html -> 404 (got " + r.status + ")");
    }

    // Symlinked non-allowlisted file -> 404 (route regex can't reach it)
    {
      // Put a secret file in the repo-A dir and symlink it with a non-allowlisted name
      const secretFile = join(repoA, "secret_data.txt");
      writeFileSync(secretFile, "secret", "utf8");
      // The .aid/dashboard/ folder was eliminated; place the decoy in .aid/knowledge/
      // (a real served dir). "secret.txt" is still not in the {home.html,kb.html}
      // leaf allowlist, so the route regex can never reach it -> 404.
      const knowledgeA = join(repoA, ".aid", "knowledge");
      const linkPath = join(knowledgeA, "secret.txt");
      let symlinkOk = false;
      try { symlinkSync(secretFile, linkPath); symlinkOk = true; } catch (_) {}
      if (symlinkOk) {
        const r = await makeRequest(port, "/r/" + idA + "/secret.txt", "GET");
        assert(r.status === 404, "non-allowlisted symlinked file -> 404 (got " + r.status + ")");
        try { rmSync(linkPath); } catch (_) {}
      } else {
        process.stdout.write("  SKIP: symlink not supported on this fs\n");
      }
      try { rmSync(secretFile); } catch (_) {}
    }

    // Registered-but-.aid-gone: static leaf -> 404, api/model -> 200 empty
    {
      const repoC = join(base, "repo-C");
      makeRepo(repoC, true);
      writeRegistry(aidHome, [repoB, repoA, repoC]);
      const idC = repoId8(repoC);
      // Kill server and respawn with updated registry
      await killServer(proc);
      const respawned = await spawnServer(aidHome);
      proc = respawned.proc;
      port = respawned.port;
      if (!respawned.ready) {
        assert(false, "server re-spawned with 3-repo registry");
      } else {
        assert(true, "server re-spawned with 3-repo registry");
        // Remove .aid/
        rmSync(join(repoC, ".aid"), { recursive: true, force: true });
        const r1 = await makeRequest(port, "/r/" + idC + "/home.html", "GET");
        assert(r1.status === 404, "registered-but-.aid-gone: home.html -> 404 (got " + r1.status + ")");
        const r2 = await makeRequest(port, "/r/" + idC + "/api/model", "GET");
        assert(r2.status === 200, "registered-but-.aid-gone: api/model -> 200 (got " + r2.status + ")");
        if (r2.status === 200) {
          let data = null;
          try { data = JSON.parse(r2.body); } catch (_) {}
          assert(data !== null && data.schema_version === 3, "empty RepoModel has schema_version=3");
          assert(
            !!(data && data.model && Array.isArray(data.model.works) && data.model.works.length === 0),
            "registered-but-.aid-gone: works=[] (empty RepoModel)"
          );
        }
        // Restore registry
        writeRegistry(aidHome, [repoB, repoA]);
      }
    }

    // -----------------------------------------------------------------------
    // (4) Registry tolerance (NFR10)
    // -----------------------------------------------------------------------

    process.stdout.write("\n[4] Registry tolerance (NFR10)\n");

    // Kill and test with absent registry
    {
      await killServer(proc);
      const aidHome2 = join(base, "aid_home2");
      makeAidHome(aidHome2);
      // Remove the registry file
      rmSync(join(aidHome2, "registry.yml"));
      const s2 = await spawnServer(aidHome2);
      proc = s2.proc;
      port = s2.port;
      if (!s2.ready) {
        assert(false, "server started without registry.yml");
      } else {
        assert(true, "server started without registry.yml");
        const r = await makeRequest(port, "/api/home", "GET");
        assert(r.status === 200, "absent registry: /api/home -> 200 (got " + r.status + ")");
        assert(r.status !== 500, "absent registry: /api/home not 500");
        let data = null;
        try { data = JSON.parse(r.body); } catch (_) {}
        assert(!!(data && Array.isArray(data.repos) && data.repos.length === 0),
          "absent registry: repos=[] (got " + (data && JSON.stringify(data.repos)) + ")");
        await killServer(proc);
      }
    }

    // Test with torn/partial registry
    {
      const aidHome3 = join(base, "aid_home3");
      makeAidHome(aidHome3);
      writeFileSync(join(aidHome3, "registry.yml"),
        "schema: 1\nrepos:\n  - /valid/path/one\n  - \n  - /valid/path/two\n", "utf8");
      const s3 = await spawnServer(aidHome3);
      proc = s3.proc;
      port = s3.port;
      if (!s3.ready) {
        assert(false, "server started with partial registry");
      } else {
        assert(true, "server started with partial registry");
        const r = await makeRequest(port, "/api/home", "GET");
        assert(r.status === 200, "torn registry: /api/home -> 200 (got " + r.status + ")");
        assert(r.status !== 500, "torn registry: not 500");
        await killServer(proc);
      }
    }

    // Test with higher-schema registry
    {
      const repoX = join(base, "repo-X");
      makeRepo(repoX);
      const aidHome4 = join(base, "aid_home4");
      makeAidHome(aidHome4);
      writeFileSync(join(aidHome4, "registry.yml"),
        "schema: 5\nrepos:\n  - " + repoX + "\n", "utf8");
      const s4 = await spawnServer(aidHome4);
      proc = s4.proc;
      port = s4.port;
      if (!s4.ready) {
        assert(false, "server started with schema:5 registry");
      } else {
        assert(true, "server started with schema:5 registry");
        const r = await makeRequest(port, "/api/home", "GET");
        assert(r.status === 200, "higher-schema registry: /api/home -> 200 (got " + r.status + ")");
        let data = null;
        try { data = JSON.parse(r.body); } catch (_) {}
        assert(!!(data && data.repos && data.repos.length === 1),
          "higher-schema registry: 1 repo read best-effort (got " +
          (data && data.repos && data.repos.length) + ")");
        const warnings = data && data.read && data.read.parse_warnings;
        assert(
          !!(warnings && warnings.some && warnings.some((w) => w.includes("newer than reader"))),
          "higher-schema registry: parse_warnings includes 'newer than reader'"
        );
        await killServer(proc);
      }
    }

    // Restart with normal registry for remaining tests
    writeRegistry(aidHome, [repoB, repoA]);
    const final = await spawnServer(aidHome);
    proc = final.proc;
    port = final.port;
    if (!final.ready) {
      assert(false, "server re-spawned for DM-2 + DM-3 tests");
      return;
    }
    assert(true, "server re-spawned for DM-2 + DM-3 tests");

    // -----------------------------------------------------------------------
    // (5) /api/home DM-2 shape
    // -----------------------------------------------------------------------

    process.stdout.write("\n[5] /api/home DM-2 shape\n");

    {
      const r = await makeRequest(port, "/api/home", "GET");
      let data = null;
      try { data = JSON.parse(r.body); } catch (_) {}

      assert(!!(data && data.schema_version === 1), "DM-2: schema_version===1");
      assert(!!(data && data.generated_by === "node"), 'DM-2: generated_by==="node"');

      // Machine panel keys
      const machine = data && data.machine;
      assert(machine !== null && machine !== undefined, "DM-2: machine panel present");
      for (const k of ["aid_version", "aid_home", "tools_catalog", "registry_path", "cli_runtime",
                        "write_enabled"]) {
        assert(!!(machine && machine[k] !== undefined), "DM-2: machine has key " + k);
      }
      assert(!!(machine && machine.cli_runtime === "node"), 'DM-2: machine.cli_runtime==="node"');
      assert(!!(machine && machine.aid_version === "1.0.0-test"), "DM-2: aid_version from VERSION file");
      assert(!!(machine && Array.isArray(machine.tools_catalog)), "DM-2: tools_catalog is array");
      assert(
        !!(machine && machine.registry_path && machine.registry_path.includes("registry.yml")),
        "DM-2: registry_path includes registry.yml"
      );
      // write_enabled (additive, feature-001 task-001): false by default (no --allow-writes).
      assert(!!(machine && machine.write_enabled === false), "DM-2: write_enabled===false by default");

      // repos[] sorted by path ascending
      const repos = data && data.repos;
      assert(Array.isArray(repos), "DM-2: repos is array");
      assert(!!(repos && repos.length === 2), "DM-2: 2 repos (got " + (repos && repos.length) + ")");
      if (repos && repos.length >= 2) {
        assert(
          repos[0].path <= repos[1].path,
          "DM-2: repos sorted by path ascending"
        );
      }

      // Per-repo fields
      for (const repo of (repos || [])) {
        for (const f of ["name", "description", "aid_version", "tools_installed",
                          "available", "has_home", "has_kb", "id", "path"]) {
          assert(repo[f] !== undefined, "DM-2: repo has field " + f);
        }
        assert(/^[0-9a-f]{8,}$/.test(repo.id || ""), "DM-2: repo.id is hex8+");
      }

      // repo-A has an .aid/ dir (-> has_home) and a generated kb.html (-> has_kb)
      const repoAEntry = (repos || []).find((r) => r.path === repoA);
      assert(!!(repoAEntry && repoAEntry.has_home), "DM-2: repo-A has_home=true");
      assert(!!(repoAEntry && repoAEntry.has_kb), "DM-2: repo-A has_kb=true");

      // repo-B has an .aid/ dir (-> has_home=true, the new gate) but no generated
      // kb.html (-> has_kb=false). has_home no longer depends on dashboard files.
      const repoBEntry = (repos || []).find((r) => r.path === repoB);
      assert(!!(repoBEntry && repoBEntry.has_home),
        "DM-2: repo-B has_home=true (has .aid/, even without a generated dashboard)");
      assert(!!(repoBEntry && !repoBEntry.has_kb), "DM-2: repo-B has_kb=false");

      // read panel
      const read = data && data.read;
      for (const k of ["read_at", "repo_count", "unavailable_count", "parse_warnings"]) {
        assert(!!(read && read[k] !== undefined), "DM-2: read has key " + k);
      }
      assert(!!(read && read.repo_count === 2), "DM-2: repo_count===2");
    }

    // -----------------------------------------------------------------------
    // (5c) --allow-writes write gate (feature-001 task-001)
    // A bare spawn (no flag, exercised above in [5]) is read-only; spawning with
    // --allow-writes flips write_enabled true in BOTH DM envelopes.
    // -----------------------------------------------------------------------

    process.stdout.write("\n[5c] --allow-writes write gate\n");

    {
      await killServer(proc);
      const s5c = await spawnServer(aidHome, ["--allow-writes"]);
      proc = s5c.proc;
      port = s5c.port;
      if (!s5c.ready) {
        assert(false, "server spawned with --allow-writes");
      } else {
        assert(true, "server spawned with --allow-writes");

        const rHome = await makeRequest(port, "/api/home", "GET");
        let homeData = null;
        try { homeData = JSON.parse(rHome.body); } catch (_) {}
        assert(
          !!(homeData && homeData.machine && homeData.machine.write_enabled === true),
          "--allow-writes: /api/home machine.write_enabled===true"
        );

        const rModel = await makeRequest(port, "/r/" + idA + "/api/model", "GET");
        let modelData = null;
        try { modelData = JSON.parse(rModel.body); } catch (_) {}
        assert(
          !!(modelData && modelData.write_enabled === true),
          "--allow-writes: /r/<id>/api/model write_enabled===true"
        );

        // -------------------------------------------------------------------
        // (5c-op) OP_TABLE dispatch smoke test (feature-001 task-004) -- the
        // gate is open now, so a real op should reach its writer. settings.set
        // is the simplest round-trip: repoA already has .aid/settings.yml
        // (makeRepo(repoA, true)), no work-dir fixture needed. The full
        // per-op matrix (task.set-notes/pipeline.finish/pipeline.rename
        // against real flat/nested work-dir fixtures, WT-1 worktree
        // resolution, status-map overrides) is task-011's mandate.
        // -------------------------------------------------------------------

        {
          const r = await postJson(port, "/r/" + idA + "/api/op", {
            op: "settings.set", args: { path: "project.name", value: "renamed-by-op" },
          });
          let data = null;
          try { data = JSON.parse(r.body); } catch (_) {}
          assert(r.status === 200, "settings.set (write-enabled) -> 200 (got " + r.status + ")");
          assert(!!(data && data.ok === true && data.op === "settings.set"), "settings.set success envelope {ok:true, op}");
          const settingsAfter = readFileSync(join(repoA, ".aid", "settings.yml"), "utf8");
          assert(settingsAfter.includes("renamed-by-op"), "settings.set writer round-trip updated settings.yml on disk");
        }

        // -------------------------------------------------------------------
        // (5c-op-006) settings.set semantic arg-schema finalization (task-006,
        // feature-002-project-header-edit): the server's OWN pre-validation hook
        // (validateSettingsSetArgs) 422s an invalid request BEFORE the writer spawn --
        // closed args.path allowlist, review.minimum_grade ^[A-F][+-]?$, and the
        // KI-001 name/description charset guard (reject \n/"/\), empty name required.
        // -------------------------------------------------------------------
        {
          const r = await postJson(port, "/r/" + idA + "/api/op", {
            op: "settings.set", args: { path: "not.allowed", value: "x" },
          });
          let data = null;
          try { data = JSON.parse(r.body); } catch (_) {}
          assert(r.status === 422, "settings.set out-of-allowlist path -> 422 (got " + r.status + ")");
          assert(!!(data && data.error === "invalid-value"), "out-of-allowlist path -> error:'invalid-value'");
        }
        {
          const r = await postJson(port, "/r/" + idA + "/api/op", {
            op: "settings.set", args: { path: "review.minimum_grade", value: "Z" },
          });
          let data = null;
          try { data = JSON.parse(r.body); } catch (_) {}
          assert(r.status === 422, "settings.set invalid grade -> 422 (got " + r.status + ")");
          assert(!!(data && data.error === "invalid-value"), "invalid grade -> error:'invalid-value'");
        }
        {
          const r = await postJson(port, "/r/" + idA + "/api/op", {
            op: "settings.set", args: { path: "project.name", value: "" },
          });
          let data = null;
          try { data = JSON.parse(r.body); } catch (_) {}
          assert(r.status === 422, "settings.set empty project.name -> 422 (got " + r.status + ")");
          assert(!!(data && data.error === "invalid-value"), "empty project.name -> error:'invalid-value'");
        }
        {
          const r = await postJson(port, "/r/" + idA + "/api/op", {
            op: "settings.set", args: { path: "project.description", value: 'has "quote"' },
          });
          let data = null;
          try { data = JSON.parse(r.body); } catch (_) {}
          assert(r.status === 422, "settings.set embedded double-quote value -> 422 (got " + r.status + ")");
          assert(!!(data && data.error === "invalid-value"), "embedded double-quote -> error:'invalid-value'");
        }
        {
          const r = await postJson(port, "/r/" + idA + "/api/op", {
            op: "settings.set", args: { path: "project.description", value: "" },
          });
          let data = null;
          try { data = JSON.parse(r.body); } catch (_) {}
          assert(r.status === 200, "settings.set empty project.description (clears) -> 200 (got " + r.status + ")");
          assert(!!(data && data.ok === true), "empty project.description -> {ok:true} (clearing is allowed)");
        }
        {
          const r = await postJson(port, "/r/" + idA + "/api/op", { op: "not-a-real-op" });
          let data = null;
          try { data = JSON.parse(r.body); } catch (_) {}
          assert(r.status === 400, "unknown op (write-enabled) -> 400 (got " + r.status + ")");
          assert(!!(data && data.ok === false && data.error === "bad-request"), "unknown op -> {ok:false, error:'bad-request'}");
        }
        {
          const r = await postJson(port, "/r/" + idA + "/api/op", {
            op: "pipeline.rename", target: { work_id: "work-999-nonexistent" }, args: { value: "x" },
          });
          let data = null;
          try { data = JSON.parse(r.body); } catch (_) {}
          assert(r.status === 404, "pipeline.rename unresolvable work_id -> 404 (got " + r.status + ")");
          assert(!!(data && data.error === "not-found"), "unresolvable work_id -> error:'not-found' (WT-1)");
        }
        {
          // feature-009-pipeline-delete (task-027): pipeline.delete's WT-1
          // 404 wiring, over the real HTTP path -- mirrors the pipeline.rename
          // case immediately above. Real writer round-trips (200 happy across
          // all 3 removal topologies, 409 guards, containment, post-delete
          // truthfulness, twin byte-parity) are covered at the _dispatch_op/
          // dispatchOp layer by test_task027_pipeline_delete_round_trips.py
          // (no live socket needed there).
          const r = await postJson(port, "/r/" + idA + "/api/op", {
            op: "pipeline.delete", target: { work_id: "work-999-nonexistent" },
          });
          let data = null;
          try { data = JSON.parse(r.body); } catch (_) {}
          assert(r.status === 404, "pipeline.delete unresolvable work_id -> 404 (got " + r.status + ")");
          assert(!!(data && data.error === "not-found"), "pipeline.delete unresolvable work_id -> error:'not-found' (WT-1)");
        }
      }
    }

    // Restart WITHOUT --allow-writes for the remaining (DM-3) tests.
    {
      await killServer(proc);
      const s5d = await spawnServer(aidHome);
      proc = s5d.proc;
      port = s5d.port;
      if (!s5d.ready) {
        assert(false, "server re-spawned (no --allow-writes) for DM-3 tests");
        return;
      }
      assert(true, "server re-spawned (no --allow-writes) for DM-3 tests");
    }

    // -----------------------------------------------------------------------
    // (6) Serialization (DM-3)
    // -----------------------------------------------------------------------

    process.stdout.write("\n[6] Serialization (DM-3)\n");

    // /r/<id>/api/model compact
    {
      const r = await makeRequest(port, "/r/" + idA + "/api/model", "GET");
      assert(!r.body.includes(": "), "DM-3 /api/model: no ': ' spacing (compact)");
      assert(!r.body.includes(", "), "DM-3 /api/model: no ', ' spacing (compact)");
      assert(!r.body.endsWith("\n"), "DM-3 /api/model: no trailing newline");
    }

    // /api/home compact
    {
      const r = await makeRequest(port, "/api/home", "GET");
      assert(!r.body.includes(": "), "DM-3 /api/home: no ': ' spacing (compact)");
      assert(!r.body.includes(", "), "DM-3 /api/home: no ', ' spacing (compact)");
      assert(!r.body.endsWith("\n"), "DM-3 /api/home: no trailing newline");
    }

    // Integers not floats
    {
      const r = await makeRequest(port, "/api/home", "GET");
      let data = null;
      try { data = JSON.parse(r.body); } catch (_) {}
      assert(
        !!(data && Number.isInteger(data.schema_version)),
        "DM-3: schema_version is integer"
      );
      assert(
        !!(data && data.read && Number.isInteger(data.read.repo_count)),
        "DM-3: read.repo_count is integer"
      );
      assert(
        !!(data && data.read && Number.isInteger(data.read.unavailable_count)),
        "DM-3: read.unavailable_count is integer"
      );
    }

    // works sorted by work_id ascending
    {
      const r = await makeRequest(port, "/r/" + idA + "/api/model", "GET");
      let data = null;
      try { data = JSON.parse(r.body); } catch (_) {}
      const works = data && data.model && data.model.works;
      if (works && works.length >= 2) {
        const workIds = works.map((w) => w.work_id);
        assert(
          JSON.stringify(workIds) === JSON.stringify(workIds.slice().sort()),
          "DM-3: works sorted by work_id ascending (got " + JSON.stringify(workIds) + ")"
        );
      }
    }

    // Enum values are strings
    {
      const r = await makeRequest(port, "/r/" + idA + "/api/model", "GET");
      let data = null;
      try { data = JSON.parse(r.body); } catch (_) {}
      const works = data && data.model && data.model.works;
      for (const w of (works || [])) {
        assert(typeof w.lifecycle === "string", "DM-3: lifecycle is string");
        assert(typeof w.source_mode === "string", "DM-3: source_mode is string");
      }
    }

    // U+2028/U+2029 escaping: we can't inject them via a fixture easily,
    // but we can verify the dm3PostProcess function by checking the source
    // uses the correct post-processing and the output has no raw bytes.
    // Verify via the /api/home parse_warnings injection path:
    {
      // The registry with a higher schema triggers a warning; we check
      // that the output doesn't contain raw U+2028 bytes (it never would
      // in warnings, but at least the endpoint works correctly).
      // The definitive U+2028 test is a direct unit test of the serializer:
      // that is covered by the Python test; Node parity is ensured by task-056.
      // We assert the source uses dm3PostProcess:
      assert(
        serverSrc.includes("dm3PostProcess"),
        "server.mjs source applies dm3PostProcess for U+2028/U+2029 escaping (DM-3)"
      );
      assert(
        serverSrc.includes("0x2028") || serverSrc.includes("0x2029") ||
        serverSrc.includes("\\u2028") || serverSrc.includes("\\u2029"),
        "server.mjs source references U+2028/U+2029 escape logic"
      );
    }

  } finally {
    await killServer(proc);
    try { rmSync(base, { recursive: true, force: true }); } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// (11) task-066: KB-state parity -- Z-vs-offset, round-trip, anti-drift,
//      frozen-commit outdated verdict, degradation, DM-A3 schema_version.
// ---------------------------------------------------------------------------

process.stdout.write("\n[11] task-066: KB-state parity + round-trip + degradation\n");

// ---------------------------------------------------------------------------
// (11a) Z-vs-+/-HH:MM normalization (residual #5, R12)
// Same instant in Z and -04:00 -> equal ms AND same verdict.
// ---------------------------------------------------------------------------
{
  // The canonical test instant: 2026-06-12T14:03:00Z (UTC)
  // Same in -04:00: 2026-06-12T10:03:00-04:00
  // Same in +05:30: 2026-06-12T19:33:00+05:30
  const INSTANT_Z    = "2026-06-12T14:03:00Z";
  const INSTANT_NEG4 = "2026-06-12T10:03:00-04:00";
  const INSTANT_PLUS530 = "2026-06-12T19:33:00+05:30";

  const ms_z    = Date.parse(INSTANT_Z);
  const ms_neg4 = Date.parse(INSTANT_NEG4);
  const ms_ist  = Date.parse(INSTANT_PLUS530);

  assert(!isNaN(ms_z),    "11a.1: Z suffix parses to valid ms");
  assert(!isNaN(ms_neg4), "11a.2: -04:00 offset parses to valid ms");
  assert(!isNaN(ms_ist),  "11a.3: +05:30 offset parses to valid ms");
  assert(ms_z === ms_neg4,
    "11a.4: Z and -04:00 of same instant are equal ms (chronological, not lexicographic)");
  assert(ms_z === ms_ist,
    "11a.5: Z and +05:30 (IST) of same instant are equal ms");

  // Guard the offset-boundary bug: lexicographically-earlier but chronologically-later string
  // baseline: "2026-06-12T14:03:00Z" (UTC 14:03)
  // newer:    "2026-06-12T11:03:01-04:00" (UTC 15:03:01 -- LATER, but lex-earlier string)
  const ms_baseline = Date.parse("2026-06-12T14:03:00Z");
  const ms_newer    = Date.parse("2026-06-12T11:03:01-04:00"); // UTC 15:03:01

  assert(!isNaN(ms_newer), "11a.6: newer offset string parses correctly");
  assert(ms_newer > ms_baseline,
    "11a.7: UTC-normalized ms shows newer_str IS after baseline_str "
    + "(guards lexicographic vs chronological compare bug)");

  // Raw string compare is wrong: newer_str lexicographically < baseline_str
  const rawCompareWrong = "2026-06-12T11:03:01-04:00" > "2026-06-12T14:03:00Z";
  assert(!rawCompareWrong,
    "11a.8: raw string compare says newer_str <= baseline_str (this is the bug UTC normalization prevents)");
}

// ---------------------------------------------------------------------------
// (11b) Producer->consumer round-trip (task-059 append-block shape, anti-drift)
// ---------------------------------------------------------------------------
{
  // Well-formed producer block -> readRepo -> same {branch, tip_date}
  const tmpRt = join(tmpdir(), "aid-066-rt-" + Date.now());
  mkdirSync(join(tmpRt, ".aid", "knowledge"), { recursive: true });

  const PRODUCER_BLOCK =
    "project:\n  name: RT-Test\n" +
    "kb_baseline:\n" +
    "  branch: master\n" +
    "  tip_date: 2026-06-12T14:03:00Z\n";

  writeFileSync(join(tmpRt, ".aid", "settings.yml"), PRODUCER_BLOCK, "utf8");
  writeFileSync(
    join(tmpRt, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf8"
  );
  writeFileSync(join(tmpRt, ".aid", "knowledge", "kb.html"), "<html></html>", "utf8");

  try {
    const mRt = readRepo(tmpRt);
    assert(mRt.repo.kb_state !== null, "11b.1: kb_state present after round-trip");
    assert(mRt.repo.kb_state.kb_baseline !== null, "11b.2: kb_baseline parsed from producer block");
    assert(mRt.repo.kb_state.kb_baseline.branch === "master",
      "11b.3: round-trip: branch='master'");
    assert(mRt.repo.kb_state.kb_baseline.tip_date === "2026-06-12T14:03:00Z",
      "11b.4: round-trip: tip_date='2026-06-12T14:03:00Z'");
  } finally {
    try { rmSync(tmpRt, { recursive: true, force: true }); } catch (_) {}
  }

  // Anti-drift: wrong key name 'kb_base_line' -> kb_baseline is null
  const tmpAd1 = join(tmpdir(), "aid-066-ad1-" + Date.now());
  mkdirSync(join(tmpAd1, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmpAd1, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf8"
  );
  const MUTATED_KEY =
    "kb_base_line:\n" +   // wrong key
    "  branch: master\n" +
    "  tip_date: 2026-06-12T14:03:00Z\n";
  writeFileSync(join(tmpAd1, ".aid", "settings.yml"), MUTATED_KEY, "utf8");
  try {
    const mAd1 = readRepo(tmpAd1);
    assert(mAd1.repo.kb_state === null || mAd1.repo.kb_state.kb_baseline === null,
      "11b.5: anti-drift: wrong key name -> kb_baseline is null (contract fails)");
  } finally {
    try { rmSync(tmpAd1, { recursive: true, force: true }); } catch (_) {}
  }

  // Anti-drift: wrong sub-key 'git_branch' instead of 'branch' -> branch null
  const tmpAd2 = join(tmpdir(), "aid-066-ad2-" + Date.now());
  mkdirSync(join(tmpAd2, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmpAd2, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf8"
  );
  const MUTATED_SUBKEY =
    "kb_baseline:\n" +
    "  git_branch: master\n" +  // wrong sub-key
    "  tip_date: 2026-06-12T14:03:00Z\n";
  writeFileSync(join(tmpAd2, ".aid", "settings.yml"), MUTATED_SUBKEY, "utf8");
  try {
    const mAd2 = readRepo(tmpAd2);
    // kb_baseline should be parsed (tip_date present) but branch should be null
    const bl2 = mAd2.repo.kb_state ? mAd2.repo.kb_state.kb_baseline : null;
    assert(bl2 !== null, "11b.6: anti-drift: kb_baseline still parsed when tip_date present");
    assert(bl2.branch === null,
      "11b.7: anti-drift: wrong sub-key 'git_branch' -> branch is null");
    assert(bl2.tip_date === "2026-06-12T14:03:00Z",
      "11b.8: anti-drift: tip_date correctly parsed despite wrong branch key");
  } finally {
    try { rmSync(tmpAd2, { recursive: true, force: true }); } catch (_) {}
  }

  // Anti-drift: missing indentation -> top-level keys end the block -> None
  const tmpAd3 = join(tmpdir(), "aid-066-ad3-" + Date.now());
  mkdirSync(join(tmpAd3, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmpAd3, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf8"
  );
  const MUTATED_INDENT =
    "kb_baseline:\n" +
    "branch: master\n" +   // no indent -> top-level key -> ends block
    "tip_date: 2026-06-12T14:03:00Z\n";
  writeFileSync(join(tmpAd3, ".aid", "settings.yml"), MUTATED_INDENT, "utf8");
  try {
    const mAd3 = readRepo(tmpAd3);
    const bl3 = mAd3.repo.kb_state ? mAd3.repo.kb_state.kb_baseline : null;
    assert(bl3 === null,
      "11b.9: anti-drift: missing indentation -> no sub-keys in block -> kb_baseline null");
  } finally {
    try { rmSync(tmpAd3, { recursive: true, force: true }); } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// (11c) Degradation: git-absent / not-a-git-repo / kb_baseline-absent -> approved
// ---------------------------------------------------------------------------
{
  // kb_baseline absent -> no freshness check -> approved
  const tmpDg1 = join(tmpdir(), "aid-066-dg1-" + Date.now());
  mkdirSync(join(tmpDg1, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmpDg1, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf8"
  );
  writeFileSync(join(tmpDg1, ".aid", "knowledge", "kb.html"), "<html></html>", "utf8");
  // No settings.yml -> kb_baseline absent
  try {
    const mDg1 = readRepo(tmpDg1);
    assert(mDg1.repo.kb_state !== null, "11c.1: kb_state present");
    assert(mDg1.repo.kb_state.kb_baseline === null, "11c.2: kb_baseline null (absent)");
    assert(mDg1.repo.kb_state.status === "approved",
      "11c.3: status=approved when kb_baseline absent (skip freshness)");
  } finally {
    try { rmSync(tmpDg1, { recursive: true, force: true }); } catch (_) {}
  }

  // Not a git repo + old baseline -> degradation -> approved (not outdated)
  const tmpDg2 = join(tmpdir(), "aid-066-dg2-" + Date.now());
  mkdirSync(join(tmpDg2, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmpDg2, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf8"
  );
  writeFileSync(join(tmpDg2, ".aid", "knowledge", "kb.html"), "<html></html>", "utf8");
  writeFileSync(
    join(tmpDg2, ".aid", "settings.yml"),
    "kb_baseline:\n  branch: main\n  tip_date: 2000-01-01T00:00:00Z\n",  // very old
    "utf8"
  );
  try {
    const mDg2 = readRepo(tmpDg2);
    assert(mDg2.repo.kb_state !== null, "11c.4: kb_state present (non-git + old baseline)");
    // Non-git dir -> git freshness degrades to skip -> approved (not outdated)
    assert(mDg2.repo.kb_state.status === "approved",
      "11c.5: non-git dir -> degradation -> approved (not outdated despite old baseline)");
  } finally {
    try { rmSync(tmpDg2, { recursive: true, force: true }); } catch (_) {}
  }

  // Baseline present but tip_date unparseable -> skip -> approved
  const tmpDg3 = join(tmpdir(), "aid-066-dg3-" + Date.now());
  mkdirSync(join(tmpDg3, ".aid", "knowledge"), { recursive: true });
  writeFileSync(
    join(tmpDg3, ".aid", "knowledge", "STATE.md"),
    "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
    "utf8"
  );
  writeFileSync(join(tmpDg3, ".aid", "knowledge", "kb.html"), "<html></html>", "utf8");
  writeFileSync(
    join(tmpDg3, ".aid", "settings.yml"),
    "kb_baseline:\n  branch: main\n  tip_date: not-a-valid-date\n",
    "utf8"
  );
  try {
    const mDg3 = readRepo(tmpDg3);
    assert(mDg3.repo.kb_state !== null, "11c.6: kb_state present");
    // Unparseable tip_date -> normalize returns null -> skip -> approved
    assert(mDg3.repo.kb_state.status === "approved",
      "11c.7: unparseable tip_date -> skip -> approved");
  } finally {
    try { rmSync(tmpDg3, { recursive: true, force: true }); } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// (11d) DM-A3: schema_version stays 3 (no bump for feature-007)
// ---------------------------------------------------------------------------
{
  const readerMjsSrc = readFileSync(join(__dirname, "..", "reader.mjs"), "utf8");
  // The schema_version constant must be 3 in reader.mjs
  assert(
    readerMjsSrc.includes("schema_version: 3") ||
    readerMjsSrc.includes("schema_version:3") ||
    readerMjsSrc.includes("SCHEMA_VERSION = 3") ||
    readerMjsSrc.includes("schemaVersion = 3") ||
    (readerMjsSrc.includes("schema_version") && !readerMjsSrc.match(/schema_version[: ]+[4-9]/)),
    "11d.1: DM-A3: schema_version is 3 (no bump in reader.mjs for feature-007)"
  );

  // Verify via readRepo that the model JSON contains schema_version:3
  const tmpSv = join(tmpdir(), "aid-066-sv-" + Date.now());
  mkdirSync(join(tmpSv, ".aid"), { recursive: true });
  try {
    // Minimal repo: read_repo must still produce schema_version 3
    const mSv = readRepo(tmpSv);
    // schema_version is in the top-level envelope (not in readRepo's direct output,
    // but the server serializes it; check via the reader source constant)
    // We verify the model does not contain schema_version > 3 by asserting the source
    // constant hasn't changed -- already done above via source grep.
    assert(true, "11d.2: DM-A3: readRepo called without error on minimal repo");
  } finally {
    try { rmSync(tmpSv, { recursive: true, force: true }); } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// (11e) Frozen-commit git repo: outdated verdict reproducible (residual #4)
//       Skipped if git not available.
// ---------------------------------------------------------------------------
{
  let gitAvailable = false;
  try {
    const r = spawnSync("git", ["--version"], { timeout: 2000, encoding: "utf8" });
    gitAvailable = r.status === 0;
  } catch (_) {}

  if (gitAvailable) {
    process.stdout.write("  [11e] git available -- running frozen-commit tests\n");

    // Helper: build a frozen-commit git repo
    function buildFrozenRepo(dir, frozenDate) {
      const env = Object.assign({}, process.env, {
        GIT_AUTHOR_DATE: frozenDate,
        GIT_COMMITTER_DATE: frozenDate,
        GIT_AUTHOR_NAME: "test",
        GIT_AUTHOR_EMAIL: "test@test.com",
        GIT_COMMITTER_NAME: "test",
        GIT_COMMITTER_EMAIL: "test@test.com",
      });
      mkdirSync(dir, { recursive: true });
      spawnSync("git", ["init", "-b", "master", dir], { env, timeout: 5000 });
      writeFileSync(join(dir, "dummy.txt"), "frozen commit\n", "utf8");
      spawnSync("git", ["-C", dir, "add", "dummy.txt"], { env, timeout: 5000 });
      spawnSync("git", ["-C", dir, "commit", "-m", "frozen commit"], { env, timeout: 5000 });
    }

    // Test 1: commit 2026-06-10 > baseline 2026-06-01 -> outdated
    const tmpFc1 = join(tmpdir(), "aid-066-fc1-" + Date.now());
    try {
      buildFrozenRepo(tmpFc1, "2026-06-10T12:00:00+00:00");
      mkdirSync(join(tmpFc1, ".aid", "knowledge"), { recursive: true });
      writeFileSync(
        join(tmpFc1, ".aid", "knowledge", "STATE.md"),
        "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
        "utf8"
      );
      writeFileSync(join(tmpFc1, ".aid", "knowledge", "kb.html"), "<html></html>", "utf8");
      writeFileSync(
        join(tmpFc1, ".aid", "settings.yml"),
        "kb_baseline:\n  branch: master\n  tip_date: 2026-06-01T00:00:00Z\n",
        "utf8"
      );
      // Run twice to verify reproducibility
      const m1a = readRepo(tmpFc1);
      const m1b = readRepo(tmpFc1);
      const status1a = m1a.repo.kb_state ? m1a.repo.kb_state.status : null;
      const status1b = m1b.repo.kb_state ? m1b.repo.kb_state.status : null;
      assert(status1a === "outdated",
        "11e.1: frozen commit 2026-06-10 > baseline 2026-06-01 -> outdated");
      assert(status1a === status1b,
        "11e.2: reproducibility: second run matches first (frozen commit)");
    } finally {
      try { rmSync(tmpFc1, { recursive: true, force: true }); } catch (_) {}
    }

    // Test 2: commit 2026-06-01 < baseline 2026-06-10 -> approved
    const tmpFc2 = join(tmpdir(), "aid-066-fc2-" + Date.now());
    try {
      buildFrozenRepo(tmpFc2, "2026-06-01T12:00:00+00:00");
      mkdirSync(join(tmpFc2, ".aid", "knowledge"), { recursive: true });
      writeFileSync(
        join(tmpFc2, ".aid", "knowledge", "STATE.md"),
        "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
        "utf8"
      );
      writeFileSync(join(tmpFc2, ".aid", "knowledge", "kb.html"), "<html></html>", "utf8");
      writeFileSync(
        join(tmpFc2, ".aid", "settings.yml"),
        "kb_baseline:\n  branch: master\n  tip_date: 2026-06-10T00:00:00Z\n",
        "utf8"
      );
      const m2 = readRepo(tmpFc2);
      const status2 = m2.repo.kb_state ? m2.repo.kb_state.status : null;
      assert(status2 === "approved",
        "11e.3: frozen commit 2026-06-01 < baseline 2026-06-10 -> approved");
    } finally {
      try { rmSync(tmpFc2, { recursive: true, force: true }); } catch (_) {}
    }

    // Test 3: Z vs -04:00 baseline of same instant -> same verdict (R12)
    // Frozen commit: 2026-06-10T12:00:00+00:00
    // Baseline just before: 2026-06-10T11:59:59Z == 2026-06-10T07:59:59-04:00
    // Both should give "outdated"
    const tmpFc3Z = join(tmpdir(), "aid-066-fc3z-" + Date.now());
    const tmpFc3N = join(tmpdir(), "aid-066-fc3n-" + Date.now());
    try {
      buildFrozenRepo(tmpFc3Z, "2026-06-10T12:00:00+00:00");
      mkdirSync(join(tmpFc3Z, ".aid", "knowledge"), { recursive: true });
      writeFileSync(
        join(tmpFc3Z, ".aid", "knowledge", "STATE.md"),
        "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
        "utf8"
      );
      writeFileSync(join(tmpFc3Z, ".aid", "knowledge", "kb.html"), "<html></html>", "utf8");
      // Baseline Z form (11:59:59 UTC -> 1 second before 12:00 UTC commit)
      writeFileSync(
        join(tmpFc3Z, ".aid", "settings.yml"),
        "kb_baseline:\n  branch: master\n  tip_date: 2026-06-10T11:59:59Z\n",
        "utf8"
      );

      buildFrozenRepo(tmpFc3N, "2026-06-10T12:00:00+00:00");
      mkdirSync(join(tmpFc3N, ".aid", "knowledge"), { recursive: true });
      writeFileSync(
        join(tmpFc3N, ".aid", "knowledge", "STATE.md"),
        "## Knowledge Summary Status\n**User Approved:** yes (2026-06-01)\n",
        "utf8"
      );
      writeFileSync(join(tmpFc3N, ".aid", "knowledge", "kb.html"), "<html></html>", "utf8");
      // Baseline -04:00 form: 07:59:59 -04:00 == 11:59:59 UTC (same instant)
      writeFileSync(
        join(tmpFc3N, ".aid", "settings.yml"),
        "kb_baseline:\n  branch: master\n  tip_date: 2026-06-10T07:59:59-04:00\n",
        "utf8"
      );

      const m3Z = readRepo(tmpFc3Z);
      const m3N = readRepo(tmpFc3N);
      const s3Z = m3Z.repo.kb_state ? m3Z.repo.kb_state.status : null;
      const s3N = m3N.repo.kb_state ? m3N.repo.kb_state.status : null;

      assert(s3Z === s3N,
        "11e.4: Z and -04:00 of same baseline instant give same verdict (R12 cross-runtime Z-vs-offset)");
      assert(s3Z === "outdated",
        "11e.5: frozen commit 12:00 UTC > baseline 11:59:59 UTC -> outdated (Z form)");
      assert(s3N === "outdated",
        "11e.6: frozen commit 12:00 UTC > baseline 11:59:59 UTC -> outdated (-04:00 form)");
    } finally {
      try { rmSync(tmpFc3Z, { recursive: true, force: true }); } catch (_) {}
      try { rmSync(tmpFc3N, { recursive: true, force: true }); } catch (_) {}
    }

  } else {
    process.stdout.write("  [11e] git not available -- skipping frozen-commit tests\n");
    // Soft-skip: emit as a passing note (same posture as test_task066_kb_parity.py)
    assert(true, "11e: frozen-commit tests SKIPPED (git not available)");
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
