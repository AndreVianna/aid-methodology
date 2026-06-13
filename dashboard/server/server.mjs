/**
 * dashboard/server/server.mjs
 * Node multi-repo server for the AID dashboard (feature-010, delivery-008).
 * Byte-parity sibling of server.py (task-051).
 *
 * Entry-point:
 *   node dashboard/server/server.mjs --host 127.0.0.1 --port <n>
 *
 * AID_HOME resolution (env-or-self-locate):
 *   1. AID_HOME environment variable if set and non-empty.
 *   2. Self-locate: server.mjs -> server/ -> dashboard/ -> $AID_HOME (join(__dirname, "..", "..")).
 *
 * Routes (NEW closed allowlist -- replaces feature-003 two-route server):
 *   GET /                    -> CLI-home index.html from $AID_HOME/dashboard/index.html
 *   GET /api/home            -> build DM-2 model -> 200 JSON
 *   GET /r/<id>/home.html    -> <repo(id)>/.aid/dashboard/home.html (SEC-2 by construction)
 *   GET /r/<id>/kb.html      -> <repo(id)>/.aid/dashboard/kb.html  (SEC-2 by construction)
 *   GET /r/<id>/api/model    -> readRepo(repo(id)) -> DM-1 envelope
 *   other path               -> 404
 *   non-GET verb             -> 405
 *
 * Invariants (SEC-1..4):
 *   - Binds literal 127.0.0.1 only (SEC-1); never 0.0.0.0/wildcard.
 *   - No fs write/appendFile/unlink primitives in this file (SEC-3).
 *   - No agent/LLM import (SEC-4).
 *   - CAN-1 site 4: stored path used verbatim -- no realpathSync/path.resolve on it (DD-5).
 *
 * Serialization (DM-3):
 *   - Declared key order, compact, no trailing newline, no BOM, UTF-8.
 *   - U+2028/U+2029 post-processed to escaped canonical form (same as Python server, PT-1/R7).
 *   - ensure_ascii=false equivalent: JSON.stringify (emits raw UTF-8).
 *
 * Source must be ASCII-only (shipped script posture; coding-standards.md).
 * UTF-8 content emitted at runtime, not in source.
 */

import { createServer } from "http";
import { readFileSync, statSync, existsSync } from "fs";
import { join, dirname, basename } from "path";
import { fileURLToPath } from "url";
import { createHash } from "crypto";

import { readRepo, readRepoDetail } from "./reader.mjs";

// ---------------------------------------------------------------------------
// Arg parsing
// ---------------------------------------------------------------------------

const LOOPBACK_ADDRS = new Set(["127.0.0.1", "::1"]);

// __dirname equivalent for ESM modules.
const __filename_srv = fileURLToPath(import.meta.url);
const __dirname_srv = dirname(__filename_srv);

function parseArgs(argv) {
  const args = argv.slice(2); // strip node + script
  let host = null;
  let port = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--host" && i + 1 < args.length) {
      host = args[++i];
    } else if (args[i] === "--port" && i + 1 < args.length) {
      port = parseInt(args[++i], 10);
    }
  }

  const errs = [];
  if (!host) errs.push("--host is required");
  if (port === null || isNaN(port)) errs.push("--port is required and must be an integer");

  if (errs.length > 0) {
    process.stderr.write("server.mjs: " + errs.join("; ") + "\n");
    process.exit(1);
  }

  // SEC-1: reject any host that is not a loopback address
  if (!LOOPBACK_ADDRS.has(host)) {
    process.stderr.write(
      "server.mjs: --host must be a loopback address (127.0.0.1 or ::1); " +
      "widened bind addresses are not permitted (SEC-1/C1/C2).\n"
    );
    process.exit(1);
  }

  // Resolve AID_HOME: (1) AID_HOME env var if set and non-empty, else
  // (2) self-locate: server.mjs -> server/ -> dashboard/ -> $AID_HOME.
  const aidHome = process.env.AID_HOME || join(__dirname_srv, "..", "..");

  return { aidHome, host, port };
}

// ---------------------------------------------------------------------------
// DD-1 id derivation (sha256(CAN-1(path))[:8], collision-lengthen) -- SS 3.1/3.5
// ---------------------------------------------------------------------------

// CAN-1 site 4: compute the sha256 of the stored path verbatim (no realpathSync).
// DO NOT call fs.realpathSync(p) or path.resolve against cwd -- realpath follows
// symlinks (-P semantics) and would diverge from the writer + Python map (DD-5).
function repoIdFull(canonPath) {
  // UTF-8 encoding, no trailing newline -- identical byte input to Python (DD-5).
  return createHash("sha256").update(canonPath, "utf8").digest("hex");
}

function buildIdMap(repos) {
  // Build {id -> canonPath} map with collision-lengthen (DD-1 SS 3.5).
  // Each id starts as the first 8 hex chars of sha256(CAN-1(path)).
  // Collision -> lengthen all colliders to shortest L > 8 at which all are unique.

  // Compute full digests for all paths.
  const fullDigests = new Map(); // canonPath -> full sha256 hex
  for (const path of repos) {
    fullDigests.set(path, repoIdFull(path));
  }

  // Group paths by their 8-char prefix.
  const prefix8Groups = new Map(); // prefix8 -> [canonPath, ...]
  for (const [path, digest] of fullDigests) {
    const p8 = digest.slice(0, 8);
    if (!prefix8Groups.has(p8)) prefix8Groups.set(p8, []);
    prefix8Groups.get(p8).push(path);
  }

  // Build result map.
  const result = new Map(); // id -> canonPath
  for (const [p8, paths] of prefix8Groups) {
    if (paths.length === 1) {
      result.set(p8, paths[0]);
    } else {
      // Collision: lengthen to shortest unique prefix L > 8.
      let resolved = false;
      for (let L = 9; L <= 64; L++) {
        const prefixes = paths.map((p) => fullDigests.get(p).slice(0, L));
        if (new Set(prefixes).size === paths.length) {
          for (const p of paths) {
            result.set(fullDigests.get(p).slice(0, L), p);
          }
          resolved = true;
          break;
        }
      }
      if (!resolved) {
        // Fallback: full digest (should never happen for distinct paths)
        for (const p of paths) {
          result.set(fullDigests.get(p), p);
        }
      }
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// mtime+size-keyed registry cache (NFR4 / DD-1 SS 3.4)
// ---------------------------------------------------------------------------

let _cacheKey = null;         // "${mtimeMs}:${size}" or null (absent)
let _cacheIdMap = new Map();  // id -> canonPath
let _cacheWarnings = [];

function getIdMap(regPath) {
  // One stat per request (O(1)).
  let key = null;
  try {
    const st = statSync(regPath);
    key = st.mtimeMs + ":" + st.size;
  } catch (e) {
    if (!e || e.code !== "ENOENT") {
      // Unreadable: return empty (NFR10)
      return { idMap: new Map(), warnings: ["registry unreadable (" + e + "); empty best-effort"] };
    }
    // ENOENT: absent == empty
    key = null;
  }

  if (key === _cacheKey) {
    return { idMap: _cacheIdMap, warnings: _cacheWarnings };
  }

  // Rebuild.
  if (key === null) {
    _cacheIdMap = new Map();
    _cacheWarnings = [];
  } else {
    const { repos, warnings } = loadRegistry(regPath);
    _cacheIdMap = buildIdMap(repos);
    _cacheWarnings = warnings;
  }
  _cacheKey = key;
  return { idMap: _cacheIdMap, warnings: _cacheWarnings };
}

// ---------------------------------------------------------------------------
// Registry line-scan (DD-REG-FMT / SS 5.3) -- no YAML lib
// ---------------------------------------------------------------------------

function loadRegistry(regPath) {
  // Returns { repos: string[], warnings: string[] }; absent -> {repos:[],warnings:[]}; never throws.
  // CAN-1 site 4: paths returned verbatim as stored -- NO realpathSync (DD-5).
  let text;
  try {
    text = readFileSync(regPath, "utf8");
  } catch (e) {
    if (e && e.code === "ENOENT") return { repos: [], warnings: [] }; // absent == empty (NFR10)
    return { repos: [], warnings: ["registry unreadable (" + e + "); empty best-effort"] };
  }
  const repos = [];
  const warnings = [];
  const ITEM = /^\s*-\s+(.*\S)\s*$/; // anchored sequence item; capture trimmed path
  for (const line of text.split(/\r?\n/)) {
    const s = line.trim();
    if (s.startsWith("schema:")) {
      const v = s.slice("schema:".length).trim();
      if (/^\d+$/.test(v) && Number(v) > 1)
        warnings.push("registry schema " + v + " newer than reader (expected 1); read best-effort");
      continue;
    }
    if (s === "repos:" || s.startsWith("repos:")) continue;
    const m = ITEM.exec(line);
    if (m) repos.push(m[1]); // trimmed verbatim CAN-1 path
  }
  return { repos, warnings };
}

// ---------------------------------------------------------------------------
// Route parse (DD-1 SS 3.3)
// ---------------------------------------------------------------------------

// Anchored regex: hex id (8+ chars) followed by fixed leaf.
// Node JS $ is strict (no trailing-newline accept divergence from Python \Z).
const R_ROUTE = /^\/r\/([0-9a-f]{8,})\/(home\.html|kb\.html|api\/model)$/;

const LEAF_ALLOWLIST = new Set(["home.html", "kb.html"]);

// ---------------------------------------------------------------------------
// /api/home builder (DM-2) -- best-effort, never throws (NFR10)
// ---------------------------------------------------------------------------

// Strip an inline YAML comment from a scalar value (PF-6 -- port of the reader's
// _strip_yaml_inline_comment; keeps the server /api/home name/description byte-identical
// to the Python server AND consistent with the reader's project-name extraction).
function stripYamlInlineComment(scalar) {
  let s = scalar;
  if (s && (s[0] === '"' || s[0] === "'")) {
    const quote = s[0];
    const end = s.indexOf(quote, 1);
    if (end !== -1) {
      const after = s.slice(end + 1).replace(/^\s+/, "");
      if (after.startsWith("#")) s = s.slice(0, end + 1);
    }
    return s;
  }
  const idx = s.indexOf("#");
  if (idx !== -1) s = s.slice(0, idx);
  return s;
}

function readSettings(repoPath) {
  // Returns { name, description } or { name: null, description: null }.
  try {
    const text = readFileSync(join(repoPath, ".aid", "settings.yml"), "utf8");
    let name = null;
    let description = null;
    let inProject = false;
    for (const line of text.split(/\r?\n/)) {
      const s = line.trim();
      if (s === "project:" || s.startsWith("project:")) { inProject = true; continue; }
      if (inProject) {
        if (s.startsWith("name:")) {
          let v = stripYamlInlineComment(s.slice("name:".length)).trim().replace(/^["']|["']$/g, "");
          name = v || null;
        } else if (s.startsWith("description:")) {
          let v = stripYamlInlineComment(s.slice("description:".length)).trim().replace(/^["']|["']$/g, "");
          description = v || null;
        } else if (s && !s.startsWith("#") && !/^\s/.test(line)) {
          inProject = false;
        }
      }
    }
    return { name, description };
  } catch (_) {
    return { name: null, description: null };
  }
}

function readManifest(repoPath) {
  // Returns { aidVersion, toolsInstalled }.
  try {
    const raw = readFileSync(join(repoPath, ".aid", ".aid-manifest.json"), "utf8");
    const data = JSON.parse(raw);
    let aidVersion = typeof data.aid_version === "string" ? data.aid_version.trim() || null : null;
    const toolsRaw = data.tools || {};
    const toolsInstalled = typeof toolsRaw === "object" ? Object.keys(toolsRaw).sort() : [];
    return { aidVersion, toolsInstalled };
  } catch (_) {
    return { aidVersion: null, toolsInstalled: [] };
  }
}

function readAidVersion(aidHome) {
  try {
    return readFileSync(join(aidHome, "VERSION"), "utf8").trim() || null;
  } catch (_) {
    return null;
  }
}

function toolsCatalog(aidHome) {
  const catalogPath = join(aidHome, "lib", "tools-catalog.txt");
  try {
    const lines = readFileSync(catalogPath, "utf8").split(/\r?\n/);
    return lines.map((l) => l.trim()).filter((l) => l && !l.startsWith("#"));
  } catch (_) {
    // Static fallback: the known aid-manageable tools (byte-identical to the Python twin).
    return ["antigravity", "claude-code", "codex", "copilot-cli", "cursor"];
  }
}

function fileExists(path) {
  try { statSync(path); return true; } catch (_) { return false; }
}

function buildHomeModel(aidHome, regPath, idMap, warnings, runtime) {
  // Build DM-2 /api/home model. Never throws (NFR10).
  const now = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");

  const repoEntries = [];
  let unavailableCount = 0;

  for (const [rid, canonPath] of idMap) {
    let available = false;
    try {
      available = fileExists(join(canonPath, ".aid"));
    } catch (_) {}

    const entry = {
      path:           canonPath,
      id:             rid,
      available:      available,
      name:           null,
      description:    null,
      aid_version:    null,
      tools_installed: [],
      has_home:       false,
      has_kb:         false,
      pipeline_count:        null,
      pipelines_in_progress: null,
    };

    if (available) {
      try {
        const { name, description } = readSettings(canonPath);
        entry.name = name;
        entry.description = description;
      } catch (_) {}
      try {
        const { aidVersion, toolsInstalled } = readManifest(canonPath);
        entry.aid_version = aidVersion;
        entry.tools_installed = toolsInstalled;
      } catch (_) {}
      try {
        entry.has_home = fileExists(join(canonPath, ".aid", "dashboard", "home.html"));
      } catch (_) {}
      try {
        entry.has_kb = fileExists(join(canonPath, ".aid", "dashboard", "kb.html"));
      } catch (_) {}
      // Pipeline counts (FR27 home summary): total works + how many are Running.
      // CLI home is load-once, so this per-project readRepo is paid once per page
      // load, not per poll. Best-effort: never throws (NFR10). Byte-parity twin of
      // the Python server's read_repo-based counts.
      try {
        const rm = readRepo(canonPath);
        const works = (rm && Array.isArray(rm.works)) ? rm.works : [];
        entry.pipeline_count = works.length;
        entry.pipelines_in_progress = works.filter((w) => w && w.lifecycle === "Running").length;
      } catch (_) {}
      // Folder-basename fallback for name.
      if (!entry.name) {
        try { entry.name = basename(canonPath) || null; } catch (_) {}
      }
    } else {
      unavailableCount++;
    }

    repoEntries.push(entry);
  }

  // Sort by path ascending (PT-1 determinism).
  repoEntries.sort((a, b) => a.path < b.path ? -1 : a.path > b.path ? 1 : 0);

  return {
    schema_version: 1,
    generated_by:   runtime,
    machine: {
      aid_version:    readAidVersion(aidHome),
      aid_home:       aidHome,
      tools_catalog:  toolsCatalog(aidHome),
      registry_path:  regPath,
      cli_runtime:    runtime,
    },
    repos: repoEntries,
    read: {
      read_at:          now,
      repo_count:       repoEntries.length,
      unavailable_count: unavailableCount,
      parse_warnings:   warnings,
    },
  };
}

// ---------------------------------------------------------------------------
// Serialization (DM-3)
// ---------------------------------------------------------------------------

// DM-3 parity: neither Node JSON.stringify nor Python json.dumps(ensure_ascii=False)
// escapes U+2028/U+2029 by default (both emit raw bytes). The canonical form is the
// ESCAPED form (PT-1/R7). Post-process to match the Python server exactly.
// NOTE: The regex flag /gu ensures global replacement and correct Unicode handling.
function dm3PostProcess(raw) {
  // Use code-point literals via fromCharCode so the source stays ASCII-only.
  const LS = String.fromCharCode(0x2028);
  const PS = String.fromCharCode(0x2029);
  return raw.replace(new RegExp(LS, "gu"), "\\u2028")
            .replace(new RegExp(PS, "gu"), "\\u2029");
}

function serializeModel(model) {
  // Sort works by work_id ascending (DM-3 determinism).
  if (model.works) {
    model.works = model.works.slice().sort((a, b) =>
      a.work_id < b.work_id ? -1 : a.work_id > b.work_id ? 1 : 0
    );
  }

  // DM-1 envelope: schema_version + generated_by at top level, then model.
  const envelope = {
    schema_version: 3,
    generated_by:   "node",
    model:          model,
  };

  const body = dm3PostProcess(JSON.stringify(envelope));
  return Buffer.from(body, "utf-8");
}

function serializeHome(homeModel) {
  const body = dm3PostProcess(JSON.stringify(homeModel));
  return Buffer.from(body, "utf-8");
}

// ---------------------------------------------------------------------------
// LC-SD ?detail= helpers (task-070)
// ---------------------------------------------------------------------------

// parseDetailParam: parse ?detail=<work_id>/<task_id>[,...] from a raw query string.
// Returns [] for missing or empty ?detail= value.
// Value is URL-decoded (% encoding), comma-split, trimmed, empties dropped.
function parseDetailParam(queryString) {
  if (!queryString) return [];
  // Parse query string manually (no third-party deps, no querystring module).
  // Find the "detail" param value.
  const pairs = queryString.split("&");
  let raw = null;
  for (const pair of pairs) {
    const eq = pair.indexOf("=");
    if (eq === -1) continue;
    const key = decodeURIComponent(pair.slice(0, eq).replace(/\+/g, " "));
    if (key === "detail") {
      raw = decodeURIComponent(pair.slice(eq + 1).replace(/\+/g, " "));
      break;
    }
  }
  if (raw === null || raw === "") return [];
  return raw.split(",").map((k) => k.trim()).filter((k) => k.length > 0);
}

// serializeModelWithDetails: serialize a RepoModel + details map (LC-SD).
// 'details' values are ALREADY plain objects from readRepoDetail (_buildTaskDetail).
// Keys are sorted ascending (DM-2 key-order parity); re-sorting here is defensive.
// schema_version stays at 3 (RC-2 no-bump decision).
function serializeModelWithDetails(model, details) {
  // Sort model.works ascending by work_id (DM-3 determinism).
  if (model.works) {
    model.works = model.works.slice().sort((a, b) =>
      a.work_id < b.work_id ? -1 : a.work_id > b.work_id ? 1 : 0
    );
  }

  // Sort details keys ascending (DM-2 key-order parity).
  const sortedDetails = {};
  for (const k of Object.keys(details).sort()) {
    sortedDetails[k] = details[k];
  }

  // DM-1 envelope: schema_version + generated_by + model + details (details is LAST).
  const envelope = {
    schema_version: 3,
    generated_by:   "node",
    model:          model,
    details:        sortedDetails,
  };

  const body = dm3PostProcess(JSON.stringify(envelope));
  return Buffer.from(body, "utf-8");
}

// ---------------------------------------------------------------------------
// Request handler
// ---------------------------------------------------------------------------

function handler(req, res) {
  const method = req.method || "GET";
  // Split path and query string; route on path only (closed allowlist).
  // The raw query string is threaded to serveRepoModel for ?detail= parsing (task-070).
  const rawUrl = req.url || "/";
  const qMark = rawUrl.indexOf("?");
  const url = qMark === -1 ? rawUrl : rawUrl.slice(0, qMark);
  const queryString = qMark === -1 ? "" : rawUrl.slice(qMark + 1);

  // Non-GET -> 405
  if (method !== "GET") {
    res.writeHead(405, { "Content-Type": "text/plain; charset=utf-8", "Allow": "GET" });
    res.end("405 Method Not Allowed\n");
    return;
  }

  if (url === "/") {
    serveCliHome(res);
    return;
  }

  if (url === "/api/home") {
    serveApiHome(res);
    return;
  }

  const m = R_ROUTE.exec(url);
  if (m) {
    const rid = m[1];
    const leaf = m[2];
    serveRepoRoute(res, rid, leaf, queryString);
    return;
  }

  // Closed allowlist: everything else -> 404
  res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
  res.end("404 Not Found\n");
}

function serveCliHome(res) {
  // GET / -> $AID_HOME/dashboard/index.html (task-053 lands the real file).
  const indexPath = join(AID_HOME, "dashboard", "index.html");
  if (!existsSync(indexPath)) {
    const body = Buffer.from("503 CLI home not yet available (task-053 will provide index.html)", "utf-8");
    res.writeHead(503, {
      "Content-Type": "text/plain; charset=utf-8",
      "Content-Length": body.length,
    });
    res.end(body);
    return;
  }
  let content;
  try {
    content = readFileSync(indexPath);
  } catch (err) {
    process.stderr.write("server.mjs: index.html read error: " + String(err) + "\n");
    res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("500 Internal Server Error\n");
    return;
  }
  res.writeHead(200, {
    "Content-Type": "text/html; charset=utf-8",
    "Content-Length": content.length,
  });
  res.end(content);
}

function serveApiHome(res) {
  let bodyBuf;
  try {
    const regPath = join(AID_HOME, "registry.yml");
    const { idMap, warnings } = getIdMap(regPath);
    const model = buildHomeModel(AID_HOME, regPath, idMap, warnings, "node");
    bodyBuf = serializeHome(model);
  } catch (err) {
    process.stderr.write("server.mjs: /api/home error: " + String(err) + "\n");
    res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("500 Internal Server Error\n");
    return;
  }
  res.writeHead(200, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": bodyBuf.length,
  });
  res.end(bodyBuf);
}

function serveRepoRoute(res, rid, leaf, queryString) {
  const regPath = join(AID_HOME, "registry.yml");
  const { idMap } = getIdMap(regPath);

  const canonPath = idMap.get(rid);
  if (!canonPath) {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("404 Not Found\n");
    return;
  }

  if (LEAF_ALLOWLIST.has(leaf)) {
    serveStaticLeaf(res, canonPath, leaf);
  } else {
    // leaf === "api/model"
    serveRepoModel(res, canonPath, queryString || "");
  }
}

function serveStaticLeaf(res, canonPath, leaf) {
  // SEC-2: served path constructed as registry[id]/.aid/dashboard/<leaf>.
  // The leaf is from the fixed allowlist -- not from the request.
  const filePath = join(canonPath, ".aid", "dashboard", leaf);
  if (!existsSync(filePath)) {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("404 Not Found\n");
    return;
  }
  let data;
  try {
    data = readFileSync(filePath);
  } catch (err) {
    process.stderr.write("server.mjs: static leaf read error: " + String(err) + "\n");
    res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("500 Internal Server Error\n");
    return;
  }
  res.writeHead(200, {
    "Content-Type": "text/html; charset=utf-8",
    "Content-Length": data.length,
  });
  res.end(data);
}

function serveRepoModel(res, canonPath, queryString) {
  // GET /r/<id>/api/model -> readRepo(canonPath) -> DM-1 envelope.
  // If .aid/ is gone: empty RepoModel (NFR10), NOT 404/500.
  //
  // LC-SD (task-070): when ?detail=<work_id>/<task_id>[,...] is present, calls
  // readRepoDetail and appends a 'details' map to the envelope. The 'details'
  // key is OMITTED entirely when ?detail= is not supplied (NFR4 byte-identical
  // bare-poll path). schema_version stays at 3 (RC-2 no-bump decision).
  const detailKeys = parseDetailParam(queryString || "");
  let bodyBuf;
  try {
    if (detailKeys.length > 0) {
      const { model, details } = readRepoDetail(canonPath, detailKeys);
      bodyBuf = serializeModelWithDetails(model, details);
    } else {
      const model = readRepo(canonPath);
      bodyBuf = serializeModel(model);
    }
  } catch (err) {
    process.stderr.write("server.mjs: readRepo error: " + String(err) + "\n");
    res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("500 Internal Server Error\n");
    return;
  }

  res.writeHead(200, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": bodyBuf.length,
  });
  res.end(bodyBuf);
}

// ---------------------------------------------------------------------------
// Main: parse args, create server, bind, register SIGTERM
// ---------------------------------------------------------------------------

const { aidHome: AID_HOME, host: HOST, port: PORT } = parseArgs(process.argv);

const server = createServer(handler);

// Bind BEFORE any slow work (LC-1 readiness contract).
// HOST is validated against LOOPBACK_ADDRS (127.0.0.1 or ::1) at parse time (SEC-1).
server.listen(PORT, HOST, () => {
  process.stderr.write(
    "server.mjs: listening on http://" + HOST + ":" + PORT + " (aid_home=" + AID_HOME + ")\n"
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
