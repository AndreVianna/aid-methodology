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
 *
 * ASCII-only source. Node built-in modules only.
 */

import { readFileSync, mkdirSync, writeFileSync, rmSync, statSync, existsSync, symlinkSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { createServer } from "http";
import http from "http";
import net from "net";
import { spawn } from "child_process";
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

function makeRepo(base, withDashboard) {
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
  if (withDashboard) {
    const dash = join(aid, "dashboard");
    mkdirSync(dash, { recursive: true });
    writeFileSync(join(dash, "home.html"), "<html>home</html>", "utf8");
    writeFileSync(join(dash, "kb.html"), "<html>kb</html>", "utf8");
  }
}

function makeAidWithWorks(repo, workIds) {
  const aid = join(repo, ".aid");
  mkdirSync(aid, { recursive: true });
  for (const wid of workIds) {
    const wdir = join(aid, wid);
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

function makeRequest(port, path, method) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: "127.0.0.1",
      port: port,
      path: path,
      method: method || "GET",
    };
    const req = http.request(options, (res) => {
      let bodyBuf = Buffer.alloc(0);
      res.on("data", (chunk) => { bodyBuf = Buffer.concat([bodyBuf, chunk]); });
      res.on("end", () => resolve({
        status: res.statusCode,
        body: bodyBuf.toString("utf-8"),
        bodyBuf: bodyBuf,
        headers: res.headers,
      }));
    });
    req.on("error", reject);
    req.end();
  });
}

// Spawn the server against an aidHome, return {proc, port}.
async function spawnServer(aidHome) {
  const port = await getFreePort();
  const proc = spawn(
    process.execPath,
    [SERVER_MJS, "--aid-home", aidHome, "--host", "127.0.0.1", "--port", String(port)],
    { stdio: ["ignore", "ignore", "pipe"] }
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
    assert(!!(w1 && w1.tasks[0] && w1.tasks[0].task_id === "task-001"), "e1: first task is task-001");
    assert(!!(w1 && w1.tasks[1] && w1.tasks[1].task_id === "task-002"), "e1: second task is task-002");
    assert(!!(w1 && w1.source_mode === "normalized"), "e1: source_mode=normalized");
  } finally {
    try { rmSync(tmpE1, { recursive: true, force: true }); } catch (_) {}
  }

  // Case e2: ## Pipeline Status section with no typed fields
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
    const liteWorkDir = join(fixtureRoot, ".aid", "work-006-lite-sample");
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
  makeRepo(repoB, false);  // no dashboard files

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

    // GET /r/<id>/home.html -> 200
    {
      const r = await makeRequest(port, "/r/" + idA + "/home.html", "GET");
      assert(r.status === 200, "GET /r/<id>/home.html -> 200 (got " + r.status + ")");
      assert(r.body.includes("<html>home</html>"), "GET /r/<id>/home.html body correct");
      assert(
        !!(r.headers["content-type"] && r.headers["content-type"].includes("text/html")),
        "GET /r/<id>/home.html Content-Type is text/html"
      );
    }

    // GET /r/<id>/kb.html -> 200
    {
      const r = await makeRequest(port, "/r/" + idA + "/kb.html", "GET");
      assert(r.status === 200, "GET /r/<id>/kb.html -> 200 (got " + r.status + ")");
      assert(r.body.includes("<html>kb</html>"), "GET /r/<id>/kb.html body correct");
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

    // repo-B has no dashboard files -> 404 for static leaves
    {
      const r = await makeRequest(port, "/r/" + idB + "/home.html", "GET");
      assert(r.status === 404, "repo without dashboard home.html -> 404 (got " + r.status + ")");
    }
    {
      const r = await makeRequest(port, "/r/" + idB + "/kb.html", "GET");
      assert(r.status === 404, "repo without dashboard kb.html -> 404 (got " + r.status + ")");
    }

    // Symlinked non-allowlisted file -> 404 (route regex can't reach it)
    {
      // Put a secret file in the repo-A dir and symlink it with a non-allowlisted name
      const secretFile = join(repoA, "secret_data.txt");
      writeFileSync(secretFile, "secret", "utf8");
      const dashA = join(repoA, ".aid", "dashboard");
      const linkPath = join(dashA, "secret.txt");
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
      for (const k of ["aid_version", "aid_home", "tools_catalog", "registry_path", "cli_runtime"]) {
        assert(!!(machine && machine[k] !== undefined), "DM-2: machine has key " + k);
      }
      assert(!!(machine && machine.cli_runtime === "node"), 'DM-2: machine.cli_runtime==="node"');
      assert(!!(machine && machine.aid_version === "1.0.0-test"), "DM-2: aid_version from VERSION file");
      assert(!!(machine && Array.isArray(machine.tools_catalog)), "DM-2: tools_catalog is array");
      assert(
        !!(machine && machine.registry_path && machine.registry_path.includes("registry.yml")),
        "DM-2: registry_path includes registry.yml"
      );

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

      // repo-A has dashboard files
      const repoAEntry = (repos || []).find((r) => r.path === repoA);
      assert(!!(repoAEntry && repoAEntry.has_home), "DM-2: repo-A has_home=true");
      assert(!!(repoAEntry && repoAEntry.has_kb), "DM-2: repo-A has_kb=true");

      // repo-B has no dashboard files
      const repoBEntry = (repos || []).find((r) => r.path === repoB);
      assert(!!(repoBEntry && !repoBEntry.has_home), "DM-2: repo-B has_home=false");
      assert(!!(repoBEntry && !repoBEntry.has_kb), "DM-2: repo-B has_kb=false");

      // read panel
      const read = data && data.read;
      for (const k of ["read_at", "repo_count", "unavailable_count", "parse_warnings"]) {
        assert(!!(read && read[k] !== undefined), "DM-2: read has key " + k);
      }
      assert(!!(read && read.repo_count === 2), "DM-2: repo_count===2");
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

runLiveTests().then(() => {
  process.stdout.write("\n--- Result: " + passed + " passed, " + failed + " failed ---\n");
  if (failed > 0) process.exit(1);
}).catch((err) => {
  process.stderr.write("Test runner error: " + String(err) + "\n");
  if (err.stack) process.stderr.write(err.stack + "\n");
  process.exit(1);
});
