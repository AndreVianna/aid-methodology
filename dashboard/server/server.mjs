/**
 * dashboard/server/server.mjs
 * Node multi-repo server for the AID dashboard (feature-010, delivery-008).
 * Byte-parity sibling of server.py (task-051).
 *
 * Entry-point:
 *   node dashboard/server/server.mjs --host 127.0.0.1 --port <n> [--allow-writes]
 *   --allow-writes: fail-safe write gate (feature-001 task-001) -- absent => read-only;
 *   a fixed token appended only by bin/aid's spawn policy, never read from request/config/env.
 *   When absent, POST /r/<id>/api/op and POST /api/op both 403 "read-only" (task-004).
 *
 * AID_HOME (state home) resolution for registry.yml:
 *   1. AID_HOME environment variable if set and non-empty (bin/aid always passes AID_HOME=$AID_STATE_HOME).
 *   2. Self-locate fallback (direct invocation without env): join(__dirname, "..", "..").
 *
 * Registry: two-tier union of AID_HOME/registry.yml (primary) and $HOME/.aid/registry.yml
 *   (user fallback) -- mirrors _registry_read_raw_union in bin/aid. Per-user collapse when
 *   both paths normalize to the same location.
 *
 * Code/static asset resolution (index.html, VERSION, lib/tools-catalog.txt):
 *   Always self-located from _DASHBOARD_DIR_MJS / _CODE_HOME (derived from __filename),
 *   independent of AID_HOME. These are shipped install-tree assets, NOT per-machine state.
 *
 * Routes (NEW closed allowlist -- replaces feature-003 two-route server):
 *   GET /                    -> CLI-home index.html from $AID_CODE_HOME/dashboard/index.html
 *   GET /api/home            -> build DM-2 model -> 200 JSON
 *   GET /r/<id>/home.html    -> $AID_CODE_HOME/dashboard/home.html (CLI template; gated on <repo>/.aid/)
 *   GET /r/<id>/kb.html      -> <repo(id)>/.aid/knowledge/kb.html  (SEC-2 by construction)
 *   GET /r/<id>/api/model    -> readRepo(repo(id)) -> DM-1 envelope
 *   POST /r/<id>/api/op      -> serveOp: closed OP_TABLE write/operation dispatch
 *                               (feature-001 task-004; 403 when not WRITE_ENABLED)
 *   POST /api/op             -> serveHomeOp: home-level op dispatch (HOME_OP_TABLE is
 *                               empty until feature-003/004 register rows -> 400 unknown op)
 *   other path               -> 404
 *   other POST / non-GET verb -> 405
 *
 * Invariants (SEC-1..4, SEC-6):
 *   - Binds literal 127.0.0.1 only (SEC-1); never 0.0.0.0/wildcard.
 *   - SEC-3 (refined, feature-001 task-004): no IN-PROCESS write/appendFile/unlink
 *     primitive anywhere in this file -- every mutation is delegated to a co-vendored
 *     writer script (writeback-state.sh / write-setting.sh / write-requirement.sh,
 *     dashboard/scripts/) spawned via spawnSync() with an argv ARRAY (never a shell
 *     string). See OP_TABLE below.
 *   - No agent/LLM import (SEC-4). Writer children are shell scripts, never an
 *     agent/LLM import (SEC-4 holds for the dispatched child too).
 *   - CAN-1 site 4: stored path used verbatim -- no realpathSync/path.resolve on it (DD-5).
 *   - Host-header allowlist (anti-DNS-rebinding) + X-Content-Type-Options/CSP response
 *     headers on every response, enforced before routing (SEC-6).
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
import { join, dirname, basename, normalize, delimiter, sep } from "path";
import { fileURLToPath } from "url";
import { createHash } from "crypto";
import { spawnSync } from "child_process";

import { readRepo, readRepoDetail, resolveWorkDir } from "./reader.mjs";

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
  // Fail-safe write gate (feature-001 task-001): absent => read-only. A fixed
  // store-true token appended only by bin/aid's spawn policy -- never read
  // from request/config/env (SEC-1 posture unaffected).
  let allowWrites = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--host" && i + 1 < args.length) {
      host = args[++i];
    } else if (args[i] === "--port" && i + 1 < args.length) {
      port = parseInt(args[++i], 10);
    } else if (args[i] === "--allow-writes") {
      allowWrites = true;
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

  return { aidHome, host, port, allowWrites };
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
// Two-tier registry union (mirrors _registry_read_raw_union in bin/aid)
// ---------------------------------------------------------------------------

function regStatKey(regPath) {
  // Returns "${mtimeMs}:${size}" or null if absent.
  try {
    const st = statSync(regPath);
    return st.mtimeMs + ":" + st.size;
  } catch (e) {
    if (e && e.code === "ENOENT") return null;
    // Unreadable: treat as absent for cache purposes.
    return null;
  }
}

function loadUnionRepos(aidHome) {
  // Returns { repos, warnings, primaryPath, fallbackPath }.
  // Mirrors _registry_read_raw_union from bin/aid (non-pruning raw union):
  //   primary  = aidHome/registry.yml  (= AID_STATE_HOME/registry.yml)
  //   fallback = $HOME/.aid/registry.yml
  //
  // Per-user collapse: when aidHome resolves to $HOME/.aid, read primary only
  // (single tier, no double-read / double-count).
  //
  // Otherwise: union primary + fallback, deduped by path (first-occurrence order).
  // The fallback file is gracefully absent (NFR10).

  const primaryPath = join(aidHome, "registry.yml");
  const userHome = process.env.HOME || "";
  const userAidPath = userHome ? join(userHome, ".aid") : "";

  // Per-user collapse: compare normalized strings (for comparison only -- not stored, CAN-1/DD-5).
  const isPerUser = !!(userAidPath && normalize(aidHome) === normalize(userAidPath));

  if (isPerUser || !userAidPath) {
    const { repos, warnings } = loadRegistry(primaryPath);
    return { repos, warnings, primaryPath, fallbackPath: null };
  }

  // Global / shared install: union primary + $HOME/.aid fallback.
  const fallbackPath = join(userAidPath, "registry.yml");
  const { repos: primaryRepos, warnings: primaryWarnings } = loadRegistry(primaryPath);
  const { repos: fallbackRepos, warnings: fallbackWarnings } = loadRegistry(fallbackPath);

  // Dedup by path, preserving first-occurrence order.
  const seen = new Map();
  for (const p of primaryRepos) seen.set(p, true);
  for (const p of fallbackRepos) { if (!seen.has(p)) seen.set(p, true); }
  const repos = Array.from(seen.keys());
  const warnings = primaryWarnings.concat(fallbackWarnings);

  return { repos, warnings, primaryPath, fallbackPath };
}

// ---------------------------------------------------------------------------
// mtime+size-keyed registry cache (NFR4 / DD-1 SS 3.4)
//
// Cache key: [primaryStat, fallbackStat].
// A change in either tier's mtime/size invalidates the cache.  The path-set is
// NOT stored or compared separately: any path-set change requires editing the
// registry.yml which changes mtime or size, so stat-keying is sufficient.
// ---------------------------------------------------------------------------

let _cacheKey = null;         // JSON string of [primaryStat, fallbackStat]
let _cacheIdMap = new Map();  // id -> canonPath
let _cacheWarnings = [];

function getIdMap(aidHome) {
  // Stat both tiers (O(1) each).
  const primaryPath = join(aidHome, "registry.yml");
  const userHome = process.env.HOME || "";
  const userAidPath = userHome ? join(userHome, ".aid") : "";
  const isPerUser = !!(userAidPath && normalize(aidHome) === normalize(userAidPath));

  const primaryStat = regStatKey(primaryPath);
  const fallbackStat = (isPerUser || !userAidPath) ? null : regStatKey(join(userAidPath, "registry.yml"));

  // Stat key (the complete cache key).
  const probeKey = JSON.stringify([primaryStat, fallbackStat]);

  // Fast path: stat key unchanged -> return cached result.
  if (_cacheKey !== null && _cacheKey === probeKey) {
    return { idMap: _cacheIdMap, warnings: _cacheWarnings };
  }

  // Rebuild.
  const { repos, warnings } = loadUnionRepos(aidHome);
  _cacheIdMap = buildIdMap(repos);
  _cacheWarnings = warnings;
  _cacheKey = probeKey;
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

// POST /r/<id>/api/op route (feature-001 task-004; separate from the GET-only R_ROUTE above).
const R_OP = /^\/r\/([0-9a-f]{8,})\/api\/op$/;

// ---------------------------------------------------------------------------
// SEC-6: anti-DNS-rebinding Host-header allowlist + security response headers
// ---------------------------------------------------------------------------

// Restrictive CSP for the fully self-contained dashboard: every page inlines
// its own CSS/JS and never fetches an external origin (same-origin /api/*
// polling only). 'unsafe-inline' is required because the shipped HTML has no
// nonce/hash infrastructure for its inline <script>/<style> blocks; data:
// is allowed for img-src/font-src for any future inlined asset -- there are
// none today, so this does not widen the current attack surface.
const CSP_HEADER =
  "default-src 'self'; script-src 'self' 'unsafe-inline'; " +
  "style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; " +
  "connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'";

// isAllowedHost: true iff the Host header names THIS server's own loopback
// bind (127.0.0.1, localhost, or ::1/[::1]), with or without an explicit
// port; when a port is present it must match the server's actual listen
// port. A MISSING/empty Host header is allowed -- conservative back-compat:
// the server only ever binds loopback (SEC-1), so an absent header cannot be
// forged by a remote page the way a forged Host VALUE can via DNS-rebinding
// (a rebind attack needs a Host value that resolves attacker DNS -> 127.0.0.1;
// it cannot make a browser omit Host entirely).
function isAllowedHost(hostHeader, port) {
  if (!hostHeader) return true;
  const h = hostHeader.trim();
  if (h === "") return true;
  const hLower = h.toLowerCase();

  // Bare literal forms (no port) -- checked first so the colon-based
  // host/port split below never has to special-case bracket-less IPv6.
  if (hLower === "127.0.0.1" || hLower === "localhost" ||
      hLower === "::1" || hLower === "[::1]") {
    return true;
  }

  let hostPart;
  let portPart;
  if (h[0] === "[") {
    // Bracketed IPv6 literal: [::1] or [::1]:<port>
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

// _CODE_HOME: $AID_CODE_HOME resolved via self-location.
// server.mjs lives at $AID_CODE_HOME/dashboard/server/server.mjs, so:
//   __dirname_srv             = $AID_CODE_HOME/dashboard/server/
//   join(__dirname_srv, "..")  = $AID_CODE_HOME/dashboard/
//   join(__dirname_srv, "..", "..") = $AID_CODE_HOME
// Used for CODE assets (VERSION, lib/tools-catalog.txt, dashboard/index.html)
// which are shipped with the install tree, NOT per-machine state artifacts.
const _DASHBOARD_DIR_MJS = join(__dirname_srv, "..");
const _CODE_HOME = join(__dirname_srv, "..", "..");

function readAidVersion() {
  // VERSION is a CODE asset at $AID_CODE_HOME/VERSION, NOT in the state home.
  try {
    return readFileSync(join(_CODE_HOME, "VERSION"), "utf8").trim() || null;
  } catch (_) {
    return null;
  }
}

function toolsCatalog() {
  // tools-catalog.txt is a CODE asset at $AID_CODE_HOME/lib/tools-catalog.txt, NOT in state home.
  const catalogPath = join(_CODE_HOME, "lib", "tools-catalog.txt");
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

function buildHomeModel(aidHome, regPath, idMap, warnings, runtime, writeEnabled) {
  // Build DM-2 /api/home model. Never throws (NFR10).
  // writeEnabled (additive, feature-001 task-001): echoes the server's fail-safe write
  // gate so the UI can hide controls the server would refuse (403). Defaults to false
  // (fail-safe) when the caller omits it.
  writeEnabled = !!writeEnabled;
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
        // home.html is a data-free CLI template served from $AID_CODE_HOME (not a
        // per-repo file); the opt-in signal is simply that the repo is AID-initialized
        // (.aid/ exists). fileExists() is really "path exists" (file or dir).
        entry.has_home = fileExists(join(canonPath, ".aid"));
      } catch (_) {}
      try {
        // kb.html is the generated KB summary, now beside its source in
        // .aid/knowledge/ (the .aid/dashboard/ folder was eliminated).
        entry.has_kb = fileExists(join(canonPath, ".aid", "knowledge", "kb.html"));
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
      aid_version:    readAidVersion(),
      aid_home:       aidHome,
      tools_catalog:  toolsCatalog(),
      registry_path:  regPath,
      cli_runtime:    runtime,
      write_enabled:  writeEnabled,
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

function serializeModel(model, writeEnabled) {
  // Sort works by work_id ascending (DM-3 determinism).
  if (model.works) {
    model.works = model.works.slice().sort((a, b) =>
      a.work_id < b.work_id ? -1 : a.work_id > b.work_id ? 1 : 0
    );
  }

  // DM-1 envelope: schema_version + generated_by + write_enabled at top level, then model.
  // write_enabled (additive, feature-001 task-001): defaults to false (fail-safe) when
  // the caller omits it -- same contract as serializeModelWithDetails().
  const envelope = {
    schema_version: 3,
    generated_by:   "node",
    write_enabled:  !!writeEnabled,
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
function serializeModelWithDetails(model, details, writeEnabled) {
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

  // DM-1 envelope: schema_version + generated_by + write_enabled + model + details
  // (details is LAST). write_enabled: see serializeModel() -- same additive top-level
  // key, same fail-safe default.
  const envelope = {
    schema_version: 3,
    generated_by:   "node",
    write_enabled:  !!writeEnabled,
    model:          model,
    details:        sortedDetails,
  };

  const body = dm3PostProcess(JSON.stringify(envelope));
  return Buffer.from(body, "utf-8");
}

// ---------------------------------------------------------------------------
// Write / operation dispatch (feature-001-write-infrastructure, task-004)
//
// POST /r/<id>/api/op -> serveOp (per-repo) / POST /api/op -> serveHomeOp (home).
// Order enforced by the handlers below: SEC-6 Host allowlist (handler(), unchanged) ->
// write gate (WRITE_ENABLED, 403 "read-only") -> body parse (400 "bad-request") ->
// closed OP_TABLE lookup (400 "bad-request" for unknown/missing op) -> target/arg
// shape validation (400) -> pipeline-scoped work_id resolution via resolveWorkDir
// (404 "not-found") -> writer spawn (argv ARRAY, never shell) -> exit-code -> HTTP
// status via the op's effective map (`op.status_map or DEFAULT_MAP`, OP-SM).
//
// The server never interprets a client-supplied path or command: OP_TABLE is a
// closed, static object; each row names a fixed writer script and an argv-builder
// that only ever fills placeholders from validated, server-resolved values (never
// echoes a raw client path). SEC-3/SEC-4 hold: no in-process fs mutation, no
// agent/LLM import; the child is always a co-vendored shell script.
// ---------------------------------------------------------------------------

const MAX_BODY_BYTES = 64 * 1024;   // 64 KiB request-body cap (API Contracts)
const MAX_DETAIL_BYTES = 1024;      // 1 KiB failure 'detail' cap (writer stderr)

// Writers are co-vendored with the dashboard unit and self-located from the
// server's own install-tree location (_DASHBOARD_DIR_MJS = $AID_CODE_HOME/dashboard/),
// never from AID_HOME (per-machine state) -- same rationale as home.html
// (bin/aid ~line 1196 `assets_dir="$AID_CODE_HOME/dashboard"`).
const WRITER_DIR = join(_DASHBOARD_DIR_MJS, "scripts");

// DEFAULT_MAP: writer exit code -> [http_status, error_class]. Derived from
// writeback-state.sh's exit alphabet (0 ok / 1 missing-artifact / 2 lock-contention /
// 3 empty-or-unverifiable-write / 4 invalid-value / 5 missing-arg / 6 malformed
// STATE.md); write-setting.sh / write-requirement.sh reuse the SAME alphabet and
// never emit 2 (reserved for lock contention). An OP_TABLE row's OPTIONAL
// `statusMap` field overrides this per-op (OP-SM foundation contract for features
// 003/004's `aid`-CLI-backed ops).
const DEFAULT_MAP = {
  1: [404, "not-found"],
  2: [409, "busy"],
  4: [422, "invalid-value"],
  5: [422, "invalid-value"],
  3: [500, "write-failed"],
  6: [500, "write-failed"],
};
const DEFAULT_FALLBACK = [500, "write-failed"];   // any other/unknown exit code

const RE_WORK_ID_SHAPE = /^work-[0-9]+/;
const RE_DELIVERY_TASK_ID = /^\d{1,3}$/;

// bash.exe resolution (feature-001 task-004; mirrors server.py's shutil.which() note):
// on Windows, spawning the bare string "bash" via child_process (no shell: true) goes
// through CreateProcess, whose OWN search order checks the System32 directory BEFORE
// consuming the PATH env var's entries -- and Windows 10+ ships a WSL-launcher stub at
// C:\Windows\System32\bash.exe. A bare "bash" would therefore silently resolve to that
// WSL stub (which cannot see a "C:/..." host path) instead of Git-Bash, even when
// Git-Bash appears earlier in PATH. Resolve bash's ABSOLUTE path ourselves via a plain
// PATH-order search (matching this script's own portability expectations) so the writer
// spawn below never depends on CreateProcess's fixed system-dir-first order.
function resolveBashExe() {
  const pathEnv = process.env.PATH || process.env.Path || "";
  const exeNames = process.platform === "win32" ? ["bash.exe", "bash.EXE"] : ["bash"];
  for (const dir of pathEnv.split(delimiter)) {
    if (!dir) continue;
    for (const exeName of exeNames) {
      const candidate = join(dir, exeName);
      if (existsSync(candidate)) return candidate;
    }
  }
  return "bash";   // fall back to bare name; spawnSync reports ENOENT if truly absent
}

const BASH_EXE = resolveBashExe();

// toPosixArg: forward-slash form of a path, for use as a bash ARGV element only
// (never for an env-var value -- those are unaffected, see the doc comment below).
// Empirically (feature-001 task-004), Node's spawnSync() on Windows mangles a
// backslash-separated ARGV element passed to an MSYS/Git-Bash bash.exe (distinct
// from the CreateProcess system-dir-first issue resolveBashExe() above works
// around): the backslashes are silently stripped, corrupting the path, even
// though the SAME absolute path passed via the `env` option (not argv) reaches
// the child unmodified. Every writer-script-path / --file argv element below is
// therefore posix-ified; AID_STATE_FILE/AID_WORK_DIR/AID_REQUIREMENTS_FILE (env
// overrides) are passed through unmodified in their native form.
function toPosixArg(p) {
  return p.split(sep).join("/");
}

function mapExitCode(exitCode, statusMap) {
  // Resolve the op's effective status map (`op.status_map or DEFAULT_MAP`, OP-SM)
  // and map exitCode -> [httpStatus, errorClass]. An exit code absent from the
  // effective map falls back to [500, 'write-failed'] -- DEFAULT_MAP's own '3/6/*'
  // catch-all row.
  const effective = statusMap || DEFAULT_MAP;
  return effective[exitCode] || DEFAULT_FALLBACK;
}

function opOkBody(op) {
  // Success envelope: {"ok": true, "op": "<op>"} (API Contracts).
  return Buffer.from(JSON.stringify({ ok: true, op: op }), "utf-8");
}

function truncateDetail(text) {
  // Bound a failure 'detail' string to <= 1 KiB (API Contracts).
  const buf = Buffer.from(text, "utf-8");
  if (buf.length <= MAX_DETAIL_BYTES) return text;
  return buf.slice(0, MAX_DETAIL_BYTES).toString("utf-8");
}

function opFailBody(op, error, detail) {
  // Failure envelope: {"ok": false, "op": <op|null>, "error": "<class>", "detail": "<=1KiB"}.
  const envelope = { ok: false, op: op, error: error, detail: truncateDetail(detail) };
  return Buffer.from(JSON.stringify(envelope), "utf-8");
}

function parseOpBody(raw) {
  // Parse a POST op-request body. Returns [parsedObj, null] on success, or
  // [null, errorDetail] on malformed JSON / a non-object top level (400 'bad-request').
  let parsed;
  try {
    parsed = JSON.parse(raw.toString("utf8"));
  } catch (e) {
    return [null, "malformed JSON body: " + String(e)];
  }
  if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
    return [null, "body must be a JSON object"];
  }
  return [parsed, null];
}

function runWriter(writerName, argv, envOverrides) {
  // Spawn a co-vendored writer script via `bash <writer> <argv...>` -- an argv
  // ARRAY, never a shell string (SEC-3/SEC-4 injection defense). Returns
  // [exitCode, stderrText]. Never throws: an exec failure (writer missing, bash
  // missing, timeout) is reported as exit 3 (the 'empty/unverifiable write' class
  // -> 500 write-failed) with the error text as detail, so a broken install
  // degrades to a clean HTTP error instead of an unhandled exception.
  const writerPath = toPosixArg(join(WRITER_DIR, writerName));
  const childEnv = Object.assign({}, process.env, envOverrides || {});
  try {
    const result = spawnSync(BASH_EXE, [writerPath, ...argv], {
      env: childEnv,
      encoding: "utf8",
      timeout: 30000,
    });
    if (result.error) {
      return [3, String(result.error)];
    }
    const code = (result.status === null || result.status === undefined) ? 3 : result.status;
    return [code, result.stderr || ""];
  } catch (e) {
    return [3, String(e)];
  }
}

function validateArgs(schema, args) {
  // Schema-level (shape-only) arg validation: required-key presence + string
  // type. Returns an error message on violation, else null. Deeper SEMANTIC
  // validation (enum membership, grade format, forbidden charset) is the writer's
  // own job -- it returns exit 4/5, mapped to 422 'invalid-value' by DEFAULT_MAP;
  // this function only prevents a malformed REQUEST from ever reaching a child
  // spawn (400 'bad-request').
  for (const key of Object.keys(schema)) {
    const spec = schema[key];
    if (spec.required && !(key in args)) {
      return "missing required arg '" + key + "'";
    }
    if (key in args && typeof args[key] !== "string") {
      return "arg '" + key + "' must be a string";
    }
  }
  return null;
}

// ---- OP_TABLE argv-builders (feature-001-owned rows; see SPEC.md API Contracts) ----
// Each builder has signature (workDir, servedRoot, target, args) -> [argv, envOverrides].
// workDir is the resolveWorkDir() result (null for scope="project" ops); servedRoot
// is the resolved repo canonPath (per-repo ops) or aidHome (home ops, unused today --
// HOME_OP_TABLE is empty). Builders never echo a raw client path -- workDir/servedRoot
// are already server-resolved.

function opTaskSetNotesArgv(workDir, servedRoot, target, args) {
  // task.set-notes -> writeback-state.sh [--delivery-id <d>] --task-id <t> --field Notes --value <v>.
  const argv = [];
  const deliveryId = target.delivery_id;
  if (deliveryId !== undefined && deliveryId !== null && deliveryId !== "") {
    argv.push("--delivery-id", String(deliveryId));
  }
  argv.push("--task-id", String(target.task_id), "--field", "Notes", "--value", args.value);
  const env = { AID_STATE_FILE: join(workDir, "STATE.md"), AID_WORK_DIR: workDir };
  return [argv, env];
}

function opPipelineFinishArgv(workDir, servedRoot, target, args) {
  // pipeline.finish -> writeback-state.sh --pipeline --field Lifecycle --value Completed.
  // Value is FIXED to 'Completed' -- the op takes no lifecycle argument and forwards
  // no other of writeback-state.sh's Lifecycle enum values (general pipeline-lifecycle
  // editing stays closed per REQUIREMENTS Sec 5.2). args is accepted but ignored.
  const argv = ["--pipeline", "--field", "Lifecycle", "--value", "Completed"];
  const env = { AID_STATE_FILE: join(workDir, "STATE.md"), AID_WORK_DIR: workDir };
  return [argv, env];
}

function opSettingsSetArgv(workDir, servedRoot, target, args) {
  // settings.set (project-scoped; no work_id) -> write-setting.sh --path <p> --value <v>
  // --file <served-root>/.aid/settings.yml. toPosixArg: this is an ARGV element
  // (not env) -- see runWriter's doc comment.
  const settingsFile = toPosixArg(join(servedRoot, ".aid", "settings.yml"));
  const argv = ["--path", args.path, "--value", args.value, "--file", settingsFile];
  return [argv, {}];
}

// settings.set semantic (per-path) arg validation (feature-002, task-006): the closed
// args.path allowlist + per-path value rules the finalized arg-schema pins (SPEC.md
// API Contracts). Same alphabet as write-setting.sh's own (redundant, belt-and-suspenders)
// checks -- the writer remains the ultimate authority on what reaches settings.yml, but
// pre-validating here lets an invalid request 422 cleanly (API Contracts: "the server
// pre-validates for a clean status") without ever spawning a child.
const RE_GRADE = /^[A-F][+-]?$/;
const SETTINGS_SET_PATH_ALLOWLIST = new Set(["project.name", "project.description", "review.minimum_grade"]);

function validateSettingsSetArgs(args) {
  // Semantic validation for the settings.set op (task-006). Returns an error message
  // on violation, else null. Called AFTER the generic shape check (validateArgs), so
  // args.path/args.value are guaranteed present strings by the time this runs.
  const path = args.path;
  const value = args.value;
  if (!SETTINGS_SET_PATH_ALLOWLIST.has(path)) {
    return "'path' must be one of: " + Array.from(SETTINGS_SET_PATH_ALLOWLIST).sort().join(", ");
  }
  if (path === "review.minimum_grade") {
    if (!RE_GRADE.test(value)) {
      return "'value' must match ^[A-F][+-]?$ (e.g. A, A-, B+, F)";
    }
    return null;
  }
  // project.name / project.description share the KI-001 output-charset guard.
  if (value.indexOf("\n") !== -1) {
    return "'value' cannot contain a newline";
  }
  if (value.indexOf('"') !== -1) {
    return "'value' cannot contain a double-quote (\")";
  }
  if (value.indexOf("\\") !== -1) {
    return "'value' cannot contain a backslash (\\)";
  }
  if (path === "project.name" && value === "") {
    return "'value' is required for project.name (cannot be empty)";
  }
  return null;
}

const PIPELINE_RENAME_NULL_SENTINEL = "*(pending)*";

function opPipelineRenameArgv(workDir, servedRoot, target, args) {
  // pipeline.rename -> write-requirement.sh --field Name --value <v>
  // (env AID_REQUIREMENTS_FILE=<resolved-work-dir>/REQUIREMENTS.md).
  //
  // Empty args.value means clear-to-fallback (AC2): write-requirement.sh needs a
  // non-empty bullet value, so an empty value is substituted with the
  // '*(pending)*' null sentinel before spawn -- the exact placeholder
  // parseRequirementsMd's RE_NAME/PENDING_PLACEHOLDER already maps back to
  // title=null (reader.mjs), which home.html's de-slug fallback then renders.
  let value = args.value;
  if (value === "") value = PIPELINE_RENAME_NULL_SENTINEL;
  const argv = ["--field", "Name", "--value", value];
  const env = { AID_REQUIREMENTS_FILE: join(workDir, "REQUIREMENTS.md") };
  return [argv, env];
}

const TASK_RENAME_NULL_SENTINEL = "--";

function opTaskRenameArgv(workDir, servedRoot, target, args) {
  // task.rename -> writeback-state.sh [--delivery-id <d>] --task-id <t> --field Name --value <v>
  // (env AID_STATE_FILE/AID_WORK_DIR=<resolved-work-dir>).
  //
  // Empty args.value means clear-to-fallback (AC2): writeback-state.sh dies exit 5
  // on a literally empty --value ('--value is required with --task-id --field',
  // fired before mode_field/layout detection ever runs), so an empty value is
  // substituted with the '--' null sentinel before spawn -- the same sentinel
  // mode_field/write_task_field_flat write for a cleared cell, and the value the
  // reader's isNull/NULL_SENTINELS set already maps back to null.
  let value = args.value;
  if (value === "") value = TASK_RENAME_NULL_SENTINEL;
  const argv = [];
  const deliveryId = target.delivery_id;
  if (deliveryId !== undefined && deliveryId !== null && deliveryId !== "") {
    argv.push("--delivery-id", String(deliveryId));
  }
  argv.push("--task-id", String(target.task_id), "--field", "Name", "--value", value);
  const env = { AID_STATE_FILE: join(workDir, "STATE.md"), AID_WORK_DIR: workDir };
  return [argv, env];
}

// feature-005 (work-017 task-008) shared args.value semantic validation for
// task.rename / pipeline.rename: a single-line, length-capped string. Mirrors
// (belt-and-suspenders) the same charset guard both writers already enforce
// (write-requirement.sh rejects \n/| -> exit 4; writeback-state.sh mode_field
// rejects \n/| -> exit 4) -- an empty string is explicitly ALLOWED here (it means
// clear-to-fallback, AC2); the argv-builders substitute each writer's null
// sentinel for an empty value before spawn, never forwarding "" literally.
const MAX_RENAME_VALUE_LEN = 200;

function validateRenameValue(value) {
  if (value.indexOf("\n") !== -1) {
    return "'value' cannot contain a newline";
  }
  if (value.indexOf("|") !== -1) {
    return "'value' cannot contain '|' (reserved column separator)";
  }
  if (value.length > MAX_RENAME_VALUE_LEN) {
    return "'value' exceeds max length (" + MAX_RENAME_VALUE_LEN + " chars)";
  }
  return null;
}

function validateTaskRenameArgs(args) {
  return validateRenameValue(args.value);
}

function validatePipelineRenameArgs(args) {
  return validateRenameValue(args.value);
}

// OP_TABLE: closed static object seeded by feature-001 (the 4 feature-001-owned rows).
// 'scope': "task" (work_id + task_id required) | "pipeline" (work_id required) |
// "project" (no work_id -- settings.set targets the served root directly).
// 'statusMap': null -> dispatcher uses DEFAULT_MAP (OP-SM); a later feature's row
// may set its own {exit -> [status, error]} map for the `aid`-CLI exit alphabet.
const OP_TABLE = {
  "task.set-notes": {
    scope: "task",
    writer: "writeback-state.sh",
    argSchema: { value: { required: true } },
    buildArgv: opTaskSetNotesArgv,
    statusMap: null,
  },
  "pipeline.finish": {
    scope: "pipeline",
    writer: "writeback-state.sh",
    argSchema: {},
    buildArgv: opPipelineFinishArgv,
    statusMap: null,
  },
  "settings.set": {
    scope: "project",
    writer: "write-setting.sh",
    argSchema: { path: { required: true }, value: { required: true } },
    buildArgv: opSettingsSetArgv,
    semanticValidate: validateSettingsSetArgs,
    statusMap: null,
  },
  "pipeline.rename": {
    scope: "pipeline",
    writer: "write-requirement.sh",
    argSchema: { value: { required: true } },
    buildArgv: opPipelineRenameArgv,
    semanticValidate: validatePipelineRenameArgs,
    statusMap: null,
  },
  "task.rename": {
    scope: "task",
    writer: "writeback-state.sh",
    argSchema: { value: { required: true } },
    buildArgv: opTaskRenameArgv,
    semanticValidate: validateTaskRenameArgs,
    statusMap: null,
  },
};

// HOME_OP_TABLE: empty until feature-003 (project.add/remove) / feature-004
// (tools.update/tools.update-self) register their home-scoped rows. Every op
// dispatched through serveHomeOp is therefore 'unknown' -> 400 today; the
// gate/body-parsing/dispatch plumbing is wired so those features only add rows.
const HOME_OP_TABLE = {};

function dispatchOp(opTable, parsed, servedRoot) {
  // Validate + dispatch a parsed op-request body against opTable.
  //
  // servedRoot is the resolved repo canonPath (per-repo ops) or aidHome (home
  // ops). Never spawns a writer child before every schema/shape check below has
  // passed (no client-controlled bytes reach subprocess argv unvalidated).
  const op = parsed.op;
  if (typeof op !== "string" || !Object.prototype.hasOwnProperty.call(opTable, op)) {
    return [400, opFailBody(typeof op === "string" ? op : null, "bad-request", "unknown or missing 'op'")];
  }

  const row = opTable[op];

  let target = parsed.target;
  if (target === undefined || target === null) target = {};
  if (typeof target !== "object" || Array.isArray(target)) {
    return [400, opFailBody(op, "bad-request", "'target' must be an object")];
  }

  let args = parsed.args;
  if (args === undefined || args === null) args = {};
  if (typeof args !== "object" || Array.isArray(args)) {
    return [400, opFailBody(op, "bad-request", "'args' must be an object")];
  }

  const deliveryId = target.delivery_id;
  if (deliveryId !== undefined && deliveryId !== null && !RE_DELIVERY_TASK_ID.test(String(deliveryId))) {
    return [400, opFailBody(op, "bad-request", "invalid target.delivery_id")];
  }
  const taskIdRaw = target.task_id;
  if (taskIdRaw !== undefined && taskIdRaw !== null && !RE_DELIVERY_TASK_ID.test(String(taskIdRaw))) {
    return [400, opFailBody(op, "bad-request", "invalid target.task_id")];
  }

  const scope = row.scope;
  let workDir = null;
  if (scope === "task" || scope === "pipeline") {
    const workId = target.work_id;
    if (typeof workId !== "string" || !RE_WORK_ID_SHAPE.test(workId)) {
      return [400, opFailBody(op, "bad-request", "missing or invalid target.work_id")];
    }
    if (scope === "task" && (taskIdRaw === undefined || taskIdRaw === null || taskIdRaw === "")) {
      return [400, opFailBody(op, "bad-request", "this op requires target.task_id")];
    }
    workDir = resolveWorkDir(servedRoot, workId);
    if (workDir === null) {
      return [404, opFailBody(op, "not-found", "no worktree holds work_id '" + workId + "'")];
    }
  }

  const argErr = validateArgs(row.argSchema, args);
  if (argErr !== null) {
    return [400, opFailBody(op, "bad-request", argErr)];
  }

  // Optional per-op semantic (value-level) validation hook (task-006's OP-SM-style
  // extension point): a row with one 422s a request the writer would reject anyway,
  // ahead of any child spawn; a row without one skips straight to buildArgv/spawn.
  const semanticValidateFn = row.semanticValidate;
  if (semanticValidateFn) {
    const semanticErr = semanticValidateFn(args);
    if (semanticErr !== null && semanticErr !== undefined) {
      return [422, opFailBody(op, "invalid-value", semanticErr)];
    }
  }

  const [argv, envOverrides] = row.buildArgv(workDir, servedRoot, target, args);
  const [exitCode, stderrText] = runWriter(row.writer, argv, envOverrides);
  if (exitCode === 0) {
    return [200, opOkBody(op)];
  }
  const [status, errorClass] = mapExitCode(exitCode, row.statusMap);
  return [status, opFailBody(op, errorClass, (stderrText || "").trim())];
}

function readBodyBounded(req, maxBytes) {
  // Read the request body, enforcing the 64 KiB cap (API Contracts). Resolves
  // null (caller sends 400) when the body exceeds maxBytes or the stream errors.
  return new Promise((resolve) => {
    const chunks = [];
    let total = 0;
    let settled = false;
    function finish(result) {
      if (settled) return;
      settled = true;
      resolve(result);
    }
    req.on("data", (chunk) => {
      total += chunk.length;
      if (total > maxBytes) {
        finish(null);
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on("end", () => {
      finish(Buffer.concat(chunks));
    });
    req.on("error", () => {
      finish(null);
    });
    req.on("aborted", () => {
      finish(null);
    });
  });
}

function sendJson(res, code, body) {
  // Send a JSON op-response envelope (used by serveOp / serveHomeOp).
  res.writeHead(code, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": body.length,
  });
  res.end(body);
}

async function serveOp(req, res, rid) {
  // POST /r/<id>/api/op -- per-repo write/operation dispatch (feature-001 task-004).
  //
  // Order: write gate (403 'read-only') -> repo id resolution (404 'not-found') ->
  // body parse (400 'bad-request') -> OP_TABLE dispatch (dispatchOp). SEC-6
  // (isAllowedHost) already ran in handler() before this is reached.
  if (!WRITE_ENABLED) {
    sendJson(res, 403, opFailBody(null, "read-only", "write endpoints disabled (server not spawned with --allow-writes)"));
    return;
  }

  const { idMap } = getIdMap(AID_HOME);
  const canonPath = idMap.get(rid);
  if (!canonPath) {
    sendJson(res, 404, opFailBody(null, "not-found", "unknown repo id"));
    return;
  }

  const raw = await readBodyBounded(req, MAX_BODY_BYTES);
  if (raw === null) {
    sendJson(res, 400, opFailBody(null, "bad-request", "body exceeds 64 KiB or is unreadable"));
    return;
  }
  const [parsed, err] = parseOpBody(raw);
  if (parsed === null) {
    sendJson(res, 400, opFailBody(null, "bad-request", err || "malformed body"));
    return;
  }

  const [status, body] = dispatchOp(OP_TABLE, parsed, canonPath);
  sendJson(res, status, body);
}

async function serveHomeOp(req, res) {
  // POST /api/op -- home-level write/operation dispatch (feature-001 task-004).
  //
  // feature-001 seeds no home-scoped rows (HOME_OP_TABLE is empty); features 003
  // (project.add/remove) and 004 (tools.update/tools.update-self) register into it.
  // Every op is therefore 'unknown' -> 400 today -- the gate/body-parsing/dispatch
  // plumbing is wired so those features only need to add OP_TABLE rows.
  if (!WRITE_ENABLED) {
    sendJson(res, 403, opFailBody(null, "read-only", "write endpoints disabled (server not spawned with --allow-writes)"));
    return;
  }

  const raw = await readBodyBounded(req, MAX_BODY_BYTES);
  if (raw === null) {
    sendJson(res, 400, opFailBody(null, "bad-request", "body exceeds 64 KiB or is unreadable"));
    return;
  }
  const [parsed, err] = parseOpBody(raw);
  if (parsed === null) {
    sendJson(res, 400, opFailBody(null, "bad-request", err || "malformed body"));
    return;
  }

  const [status, body] = dispatchOp(HOME_OP_TABLE, parsed, AID_HOME);
  sendJson(res, status, body);
}

// ---------------------------------------------------------------------------
// Request handler
// ---------------------------------------------------------------------------

function handler(req, res) {
  // SEC-6: security response headers on every response. Set via setHeader()
  // (not writeHead()) BEFORE any routing so Node merges them into whichever
  // writeHead() call the eventual route handler makes (headers passed to
  // writeHead() take precedence over setHeader() but never unset it).
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("Content-Security-Policy", CSP_HEADER);

  // SEC-6: anti-DNS-rebinding Host-header allowlist -- rejected BEFORE any
  // routing/method dispatch. The server binds 127.0.0.1 only (SEC-1), but
  // without a Host check a malicious web page (fixed default port) could
  // rebind DNS to 127.0.0.1 and read the whole API through the victim's
  // browser. Applies to every verb, not just GET.
  if (!isAllowedHost(req.headers.host, PORT)) {
    const body = "403 Forbidden (untrusted Host header)\n";
    res.writeHead(403, {
      "Content-Type": "text/plain; charset=utf-8",
      "Content-Length": Buffer.byteLength(body),
    });
    res.end(body);
    return;
  }

  const method = req.method || "GET";
  // Split path and query string; route on path only (closed allowlist).
  // The raw query string is threaded to serveRepoModel for ?detail= parsing (task-070).
  const rawUrl = req.url || "/";
  const qMark = rawUrl.indexOf("?");
  const url = qMark === -1 ? rawUrl : rawUrl.slice(0, qMark);
  const queryString = qMark === -1 ? "" : rawUrl.slice(qMark + 1);

  // POST: /api/op (home) and /r/<id>/api/op (per-repo) dispatch to the write/
  // operation layer (feature-001 task-004); any other POST path -> 405.
  if (method === "POST") {
    if (url === "/api/op") {
      serveHomeOp(req, res);
      return;
    }
    const opMatch = R_OP.exec(url);
    if (opMatch) {
      serveOp(req, res, opMatch[1]);
      return;
    }
    res.writeHead(405, { "Content-Type": "text/plain; charset=utf-8", "Allow": "GET" });
    res.end("405 Method Not Allowed\n");
    return;
  }

  // Non-GET (PUT/DELETE/PATCH/HEAD/other) -> 405
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
  // GET / -> $AID_CODE_HOME/dashboard/index.html (code asset, self-located).
  // index.html is a CODE asset shipped with the install tree -- it resolves from
  // _DASHBOARD_DIR_MJS (= server.mjs/../../ = $AID_CODE_HOME/dashboard/), NOT from
  // the per-machine AID_HOME (state home).
  const indexPath = join(_DASHBOARD_DIR_MJS, "index.html");
  if (!existsSync(indexPath)) {
    // Graceful 503: the file is genuinely missing from the install tree.
    // This should not happen in a healthy install; run 'aid update' to repair.
    const body = Buffer.from("503 dashboard index.html missing from install tree; run 'aid update' to repair", "utf-8");
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
    const { idMap, warnings } = getIdMap(AID_HOME);
    // registry_path in the machine block shows the primary (state-home) path.
    const regPath = join(AID_HOME, "registry.yml");
    const model = buildHomeModel(AID_HOME, regPath, idMap, warnings, "node", WRITE_ENABLED);
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
  const { idMap } = getIdMap(AID_HOME);

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
  // home.html is a DATA-FREE CLI TEMPLATE (byte-identical across repos: derives the
  // repo from the URL, pulls all state from ./api/model). Serve the installed CLI's
  // OWN copy (_DASHBOARD_DIR_MJS/home.html) so it is always current with the running
  // server, NOT a per-repo copy (which drifted across CLI versions -- the cause of
  // "updated the CLI but the dashboard is stale"). The repo just needs to be
  // AID-initialized (.aid/ exists) to gate access.
  //
  // kb.html is a per-repo GENERATED artifact (summarize bakes the KB docs) and lives
  // beside its source at .aid/knowledge/kb.html (the .aid/dashboard/ folder was
  // eliminated). Served from the repo copy (SEC-2: registry[id]/.aid/knowledge/kb.html;
  // a broken symlink there fails existsSync -> 404).
  let filePath;
  if (leaf === "home.html") {
    // Opt-in gate: only AID-initialized repos expose a dashboard.
    if (!existsSync(join(canonPath, ".aid"))) {
      res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("404 Not Found\n");
      return;
    }
    filePath = join(_DASHBOARD_DIR_MJS, "home.html");
    if (!existsSync(filePath)) {
      const body = Buffer.from(
        "503 dashboard home.html missing from install tree; run 'aid update' to repair",
        "utf-8",
      );
      res.writeHead(503, { "Content-Type": "text/plain; charset=utf-8", "Content-Length": body.length });
      res.end(body);
      return;
    }
  } else {
    // kb.html (per-repo generated leaf): served from .aid/knowledge/.
    filePath = join(canonPath, ".aid", "knowledge", leaf);
    if (!existsSync(filePath)) {
      res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("404 Not Found\n");
      return;
    }
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
  // home.html is CLI-served and changes across CLI versions; kb.html changes on
  // re-summarize. Force revalidation so an updated CLI/summary shows without a manual
  // hard-refresh (this simple server has no ETag, so revalidate == re-send).
  res.writeHead(200, {
    "Content-Type": "text/html; charset=utf-8",
    "Cache-Control": "no-cache",
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
      bodyBuf = serializeModelWithDetails(model, details, WRITE_ENABLED);
    } else {
      const model = readRepo(canonPath);
      bodyBuf = serializeModel(model, WRITE_ENABLED);
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

const { aidHome: AID_HOME, host: HOST, port: PORT, allowWrites: WRITE_ENABLED } = parseArgs(process.argv);

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
