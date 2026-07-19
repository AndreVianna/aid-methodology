/**
 * dashboard/server/reader.mjs
 * Node runtime reader: port of dashboard/reader/ (Python) for the Node thin server.
 *
 * Exports readRepo(root) -> model object (same shape as Python RepoModel serialized).
 *
 * Read-only by construction: uses only fs.readFileSync / fs.readdirSync / fs.statSync,
 * plus fs.openSync/readSync/closeSync opened read-only ("r") for the bounded-read
 * helper (readFileBounded, v2.1.0 security hardening -- FIX-3).
 * No fs.write* / fs.appendFile / fs.unlink / fs.open for write anywhere in this file.
 * No agent/LLM import. No third-party deps. Node built-in modules only.
 *
 * Source MUST be ASCII-only (shipped script posture; coding-standards.md).
 * UTF-8 payload content is emitted at runtime, not in source.
 */

import { readFileSync, readdirSync, statSync, existsSync, openSync, readSync, closeSync } from "fs";
import { resolve, join, basename } from "path";
import { execFileSync } from "child_process";

// ---------------------------------------------------------------------------
// Security hardening (v2.1.0, FIX-3 MEDIUM): shared bounded-read helper.
// Twin of dashboard/reader/io_bounds.py read_bytes_bounded() (byte-parity minded).
//
// Problem: the reader read every STATE.md / DETAIL.md / BLUEPRINT.md / PLAN.md /
// delivery-NNN-issues.md / KB doc fully into memory with no size cap -- a very
// large (or maliciously large) file at any of these well-known paths could
// exhaust process memory (DoS) -- every reader read site called readFileSync()
// directly with no bound.
//
// Fix: every content-read site routes through readFileBounded() instead of
// readFileSync(). stat() first; size <= MAX_READ_BYTES -> full read (byte-
// identical to readFileSync(path) for every real-world file -- existing
// behavior and the Python<->Node parity contract are unchanged for the common
// case); size > MAX_READ_BYTES -> bounded read of only the first
// MAX_READ_BYTES bytes. The file is NEVER skipped -- the reader's line-
// scanners tolerate a truncated tail (degrade gracefully, never throw, never
// skip -- matches the reader's no-throw posture).
// ---------------------------------------------------------------------------

const MAX_READ_BYTES = 5 * 1024 * 1024; // 5 MB (matches Python io_bounds.MAX_READ_BYTES)

function readFileBounded(path, maxBytes = MAX_READ_BYTES) {
  // Byte-identical to readFileSync(path) when the file is <= maxBytes (the
  // common case for every real repo file). For an oversized file, returns
  // only the first maxBytes bytes (never skips the file).
  const size = statSync(path).size;
  if (size <= maxBytes) {
    return readFileSync(path);
  }
  const fd = openSync(path, "r");
  try {
    const buf = Buffer.alloc(maxBytes);
    const bytesRead = readSync(fd, buf, 0, maxBytes, 0);
    return buf.subarray(0, bytesRead);
  } finally {
    closeSync(fd);
  }
}

// ---------------------------------------------------------------------------
// Enum literals (DM-6 -- mirrors models.py verbatim)
// ---------------------------------------------------------------------------

const Lifecycle = {
  Running: "Running",
  PausedAwaitingInput: "Paused-Awaiting-Input",
  Blocked: "Blocked",
  Completed: "Completed",
  Canceled: "Canceled",
  Unknown: "Unknown",
};

// Faithful numbered pipeline; ends at Execute (mirrors models.py Phase).
// Discover is NOT a member -- aid-discover is KB-level (writes kb_status, never a
// work phase:); it is surfaced from KbStatus instead. Deploy is NOT a member --
// the numbered sequence ends at Execute; /aid-deploy is a separate path (no longer
// a work phase:).
const Phase = {
  Describe: "Describe",
  Define: "Define",
  Specify: "Specify",
  Plan: "Plan",
  Detail: "Detail",
  Execute: "Execute",
  Unknown: "Unknown",
};

const TaskStatus = {
  Pending: "Pending",
  InProgress: "In Progress",
  InReview: "In Review",
  Blocked: "Blocked",
  Done: "Done",
  Failed: "Failed",
  Canceled: "Canceled",
  Unknown: "Unknown",
};

const SourceMode = {
  Normalized: "normalized",
  Fallback: "fallback",
  Mixed: "mixed",
};

// FR32 5-state KB status enum (feature-007 DM-A2, task-064)
// Derived by the reader (FF-A3); never written to disk (NFR2).
const KbStatus = {
  pending:    "pending",    // .aid/knowledge/ absent or empty
  generating: "generating", // KB present but not yet User Approved: yes (SPEC residual-#1)
  preparing:  "preparing",  // KB approved but kb.html absent OR summary not V1-approved
  approved:   "approved",   // KB + kb.html ready, current, approved
  outdated:   "outdated",   // approved but default branch advanced past kb_baseline (FR35)
  unknown:    "unknown",    // reader-only sentinel; never written to disk
};

// ---------------------------------------------------------------------------
// Null-value sentinels (mirrors parsers.py _NULL_SENTINELS)
// ---------------------------------------------------------------------------

const NULL_SENTINELS = new Set(["-", "--", "\u2014", ""]);

function isNull(val) {
  return NULL_SENTINELS.has(val);
}

// ---------------------------------------------------------------------------
// STATE YAML-frontmatter dual-format read (work-003-state-schema task-002)
// Twin of dashboard/reader/state_schema.py -- keep the two in lockstep.
// ---------------------------------------------------------------------------

const RE_FM_FENCE_GENERIC = /^---\s*$/;
const RE_TOPLEVEL_KV = /^([A-Za-z0-9_\-]+):\s*(.*)$/;
const RE_NESTED_KV = /^[ \t]+([A-Za-z0-9_\-]+):\s*(.*)$/;
const RE_SECTION_HEADER_GENERIC = /^##\s+/;

function _stripScalarQuotes(raw) {
  // Strip one layer of matching surrounding quotes from a YAML scalar.
  // For a SINGLE-quoted scalar, also collapse YAML's ''-escaping ('' -> '),
  // the exact inverse of the frontmatter writer (task-004 emits a single-quoted
  // scalar with embedded ' doubled). Twin of Python _strip_scalar_quotes.
  const val = raw.trim();
  if (val.length >= 2 && val[0] === val[val.length - 1] &&
      (val[0] === "'" || val[0] === '"')) {
    const inner = val.slice(1, -1);
    return val[0] === "'" ? inner.split("''").join("'") : inner;
  }
  return val;
}

// A '{...}' template token anywhere in the value (matching braces, no nested
// '}'). Every un-instantiated placeholder in the 4 STATE templates carries one.
const RE_PLACEHOLDER_TOKEN = /\{[^}]*\}/;

// Frontmatter keys whose value is human/skill free-text, NOT a closed enum.
// Twin of Python _FREETEXT_FM_KEYS -- the ' | ' enum-list marker is suppressed
// for these so a real free-text value containing ' | ' is not discarded; their
// own placeholders still carry a '{...}' token. Keep in lockstep with Python.
const FREETEXT_FM_KEYS = new Set(["pause_reason", "block_reason", "block_artifact", "notes"]);

function _looksLikeUnfilledPlaceholder(val, isFreetext) {
  // True if val is un-instantiated TEMPLATE placeholder text, not real data.
  // Twin of Python _looks_like_unfilled_placeholder() -- see its docstring for
  // the rollout-safety rationale (BLUEPRINT gate criteria #6). Two markers:
  //   - a '{...}' token anywhere (always a placeholder), and
  //   - a ' | ' enum-alternatives list, but ONLY for closed-enum fields; it is
  //     suppressed when isFreetext (real free-text may contain ' | ').
  if (RE_PLACEHOLDER_TOKEN.test(val)) return true;
  if (!isFreetext && val.includes(" | ")) return true;
  return false;
}

function parseFrontmatterScalars(text) {
  // Tolerant flat + one-level-nested frontmatter scalar scan.
  // Twin of Python parse_frontmatter_scalars(). Returns a plain object:
  //   top-level scalar keys map directly:       {started: "2026-07-10"}
  //   one level of nested mapping is dot-joined: {"pipeline.path": "lite"}
  // Never throws (NFR7). No file I/O. Returns {} when no opening '---' fence.
  const result = {};
  let inFm = false;
  let fmEntered = false;
  let currentPrefix = null;

  // CRLF tolerance: text.split("\n") leaves a trailing "\r" on each line for
  // CRLF-authored files (e.g. edited on Windows); JS's "." and "$" both treat
  // "\r" as a line terminator (unlike Python's splitlines(), which already
  // strips it), so an un-stripped "\r" would silently fail every (.*)$-shaped
  // capture below. Stripping it here keeps this function's behavior identical
  // to the Python twin for both LF-only and CRLF-authored STATE.md files.
  for (const rawLine of text.split("\n")) {
    const line = rawLine.endsWith("\r") ? rawLine.slice(0, -1) : rawLine;
    if (RE_FM_FENCE_GENERIC.test(line)) {
      if (!fmEntered) {
        inFm = true;
        fmEntered = true;
        continue;
      } else {
        break; // closing fence
      }
    }
    if (!inFm) break; // no opening fence -- no frontmatter at all

    if (!line.trim()) continue;

    if (line[0] === " " || line[0] === "\t") {
      // Nested continuation line
      if (currentPrefix === null) continue; // orphan indented line; ignore
      const m = line.match(RE_NESTED_KV);
      if (m) {
        const key = m[1];
        const val = _stripScalarQuotes(m[2]);
        if (val !== "" && !_looksLikeUnfilledPlaceholder(val, FREETEXT_FM_KEYS.has(key))) {
          result[`${currentPrefix}.${key}`] = val;
        }
      }
      continue;
    }

    // Top-level line
    const m = line.match(RE_TOPLEVEL_KV);
    if (!m) {
      currentPrefix = null;
      continue;
    }
    const key = m[1];
    const rest = m[2].trim();
    if (rest === "") {
      // Bare 'key:' -- nested mapping follows
      currentPrefix = key;
      continue;
    }
    currentPrefix = null;
    const val = _stripScalarQuotes(rest);
    if (!_looksLikeUnfilledPlaceholder(val, FREETEXT_FM_KEYS.has(key))) {
      result[key] = val;
    }
  }

  return result;
}

function parseHeaderBoldField(text, label) {
  // Legacy-prose fallback: scan the pre-first-"##" header-blockquote zone for
  // a '**{label}:** value' line (optionally '>'-prefixed), case-insensitive.
  // Twin of Python parse_header_bold_field(). Returns trimmed value or null.
  const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp("\\*\\*" + escaped + ":\\*\\*\\s*(.+)", "i");
  for (const line of text.split("\n")) {
    if (RE_SECTION_HEADER_GENERIC.test(line)) break;
    const m = line.match(pattern);
    if (m) return m[1].trim();
  }
  return null;
}

function parseBoolYesno(raw) {
  // Normalize a yes/no/true/false (case-insensitive) scalar to bool.
  // Twin of Python parse_bool_yesno() -- see its docstring for the
  // twin-parity landmine rationale (PyYAML 1.1 vs js-yaml 1.2 yes/no coercion).
  // Returns null when raw is null/undefined or an unrecognized token.
  if (raw === null || raw === undefined) return null;
  const v = String(raw).trim().toLowerCase();
  if (v === "yes" || v === "true") return true;
  if (v === "no" || v === "false") return false;
  return null;
}

// pipeline.initiator -> display kind: static mirror of
// canonical/aid/templates/shortcut-catalog.yml's {name: [verb, artifact]} rows.
// NOT read from disk at runtime -- see state_schema.py's SHORTCUT_KIND_MAP
// docstring for the full rationale. Keep in lockstep with the Python twin.
const SHORTCUT_KIND_MAP = {
  "aid-fix": ["fix", ""],
  "aid-create": ["create", ""],
  "aid-create-api": ["create", "api"],
  "aid-create-ui": ["create", "ui"],
  "aid-create-theme": ["create", "theme"],
  "aid-create-cli": ["create", "cli"],
  "aid-create-data-model": ["create", "data-model"],
  "aid-create-data-pipeline": ["create", "data-pipeline"],
  "aid-create-messaging": ["create", "messaging"],
  "aid-create-integration": ["create", "integration"],
  "aid-create-job": ["create", "job"],
  "aid-create-config": ["create", "config"],
  "aid-create-infra": ["create", "infra"],
  "aid-add": ["create", ""],
  "aid-add-api": ["create", "api"],
  "aid-add-ui": ["create", "ui"],
  "aid-add-theme": ["create", "theme"],
  "aid-add-cli": ["create", "cli"],
  "aid-add-data-model": ["create", "data-model"],
  "aid-add-data-pipeline": ["create", "data-pipeline"],
  "aid-add-messaging": ["create", "messaging"],
  "aid-add-integration": ["create", "integration"],
  "aid-add-job": ["create", "job"],
  "aid-add-config": ["create", "config"],
  "aid-add-infra": ["create", "infra"],
  "aid-change": ["change", ""],
  "aid-change-api": ["change", "api"],
  "aid-change-ui": ["change", "ui"],
  "aid-change-theme": ["change", "theme"],
  "aid-change-cli": ["change", "cli"],
  "aid-change-data-model": ["change", "data-model"],
  "aid-change-data-pipeline": ["change", "data-pipeline"],
  "aid-change-messaging": ["change", "messaging"],
  "aid-change-integration": ["change", "integration"],
  "aid-change-job": ["change", "job"],
  "aid-change-config": ["change", "config"],
  "aid-change-infra": ["change", "infra"],
  "aid-refactor": ["refactor", ""],
  "aid-update": ["change", ""],
  "aid-update-api": ["change", "api"],
  "aid-update-ui": ["change", "ui"],
  "aid-update-theme": ["change", "theme"],
  "aid-update-cli": ["change", "cli"],
  "aid-update-data-model": ["change", "data-model"],
  "aid-update-data-pipeline": ["change", "data-pipeline"],
  "aid-update-messaging": ["change", "messaging"],
  "aid-update-integration": ["change", "integration"],
  "aid-update-job": ["change", "job"],
  "aid-update-config": ["change", "config"],
  "aid-update-infra": ["change", "infra"],
  "aid-remove": ["remove", ""],
  "aid-delete": ["remove", ""],
  "aid-deprecate": ["deprecate", ""],
  "aid-migrate": ["migrate", ""],
  "aid-test": ["test", ""],
  "aid-test-security": ["test", "security"],
  "aid-test-performance": ["test", "performance"],
  "aid-test-data-quality": ["test", "data-quality"],
  "aid-experiment": ["experiment", ""],
  "aid-prototype": ["prototype", ""],
  "aid-prototype-ui": ["prototype", "ui"],
  "aid-document": ["document", ""],
  "aid-document-decision": ["document", "decision"],
  "aid-document-architecture": ["document", "architecture"],
  "aid-document-guideline": ["document", "guideline"],
  "aid-document-standard": ["document", "standard"],
  "aid-document-runbook": ["document", "runbook"],
  "aid-document-tutorial": ["document", "tutorial"],
  "aid-document-changelog": ["document", "changelog"],
  "aid-report": ["report", ""],
  "aid-show-dashboard": ["show-dashboard", ""],
  "aid-review": ["review", ""],
  "aid-audit": ["review", ""],
  "aid-research": ["research", ""],
  "aid-investigate": ["research", ""],
  "aid-spike": ["research", ""],
  "aid-deploy": ["deploy", ""],
  "aid-monitor": ["monitor", ""],
  "aid-query-kb": ["query", ""],
  "aid-ask": ["query", ""],
};

// The FULL-pipeline starting skill -- never a shortcut-catalog.yml row.
const FULL_PATH_INITIATOR = "aid-describe";
const FULL_PATH_KIND = "full path";

function resolveKind(initiator) {
  // Resolve a pipeline.initiator skill name to a human display verb.
  // Twin of Python resolve_kind(). Unknown/absent -> null (caller drops the
  // redundant word instead of rendering a literal "Unknown"/"Lite").
  if (!initiator) return null;
  const trimmed = initiator.trim();
  if (!trimmed) return null;
  if (trimmed === FULL_PATH_INITIATOR) return FULL_PATH_KIND;

  const entry = SHORTCUT_KIND_MAP[trimmed];
  if (!entry) return null;

  const [verb, artifact] = entry;
  let label = verb.replace(/-/g, " ");
  if (label) label = label[0].toUpperCase() + label.slice(1);
  if (artifact) label = `${label} ${artifact.replace(/-/g, " ")}`;
  return label;
}

// ---------------------------------------------------------------------------
// Enum parse helpers (mirrors parsers.py _parse_* functions)
// ---------------------------------------------------------------------------

const LIFECYCLE_MAP = {
  "Running": Lifecycle.Running,
  "Paused-Awaiting-Input": Lifecycle.PausedAwaitingInput,
  "Blocked": Lifecycle.Blocked,
  "Completed": Lifecycle.Completed,
  "Canceled": Lifecycle.Canceled,
};

const PHASE_MAP = {
  "Describe": Phase.Describe,
  "Define": Phase.Define,
  "Specify": Phase.Specify,
  "Plan": Phase.Plan,
  "Detail": Phase.Detail,
  "Execute": Phase.Execute,
};

const TASK_STATUS_MAP = {
  "Pending": TaskStatus.Pending,
  "In Progress": TaskStatus.InProgress,
  "In Review": TaskStatus.InReview,
  "Blocked": TaskStatus.Blocked,
  "Done": TaskStatus.Done,
  "Failed": TaskStatus.Failed,
  "Canceled": TaskStatus.Canceled,
};

function parseLifecycle(raw) {
  return LIFECYCLE_MAP[raw] || Lifecycle.Unknown;
}

function parsePhase(raw) {
  return PHASE_MAP[raw] || Phase.Unknown;
}

function parseTaskStatus(raw) {
  return TASK_STATUS_MAP[raw] || TaskStatus.Unknown;
}

// ---------------------------------------------------------------------------
// Locator (mirrors locator.py locate_aid_root / _enumerate_work_dirs)
// ---------------------------------------------------------------------------

function locateAidRoot(repoRoot) {
  const root = resolve(repoRoot);
  const aidDir = join(root, ".aid");

  const manifestPath = join(aidDir, ".aid-manifest.json");
  const versionPath = join(aidDir, ".aid-version");
  const settingsPath = join(aidDir, "settings.yml");
  const kbDir = join(aidDir, "knowledge");
  const heartbeatDir = join(aidDir, ".heartbeat");

  let aidExists = false;
  try {
    const st = statSync(aidDir);
    aidExists = st.isDirectory();
  } catch (_) {
    aidExists = false;
  }

  let workDirs = [];
  if (aidExists) {
    workDirs = enumerateWorkDirs(aidDir);
  }

  return {
    aidDir,
    aidExists,
    manifestPath,
    versionPath,
    settingsPath,
    kbDir,
    workDirs,
    heartbeatDir,
  };
}

function enumerateWorkDirs(aidDir) {
  // Enumerate EVERY direct subfolder of the .aid/works/ container -- the
  // container is the discovery selector, so the folder name is no longer a
  // visibility filter (numberless works included). Mirrors locator.py
  // _enumerate_work_dirs.
  const worksDir = join(aidDir, "works");
  let entries;
  try {
    entries = readdirSync(worksDir);
  } catch (_) {
    return [];
  }

  const result = [];
  for (const name of entries) {
    const fullPath = join(worksDir, name);
    try {
      if (statSync(fullPath).isDirectory()) {
        result.push(fullPath);
      }
    } catch (_) {
      // skip unreadable
    }
  }

  result.sort((a, b) => basename(a).localeCompare(basename(b)));
  return result;
}

function statPath(p) {
  try {
    const st = statSync(p);
    if (st.isFile()) return st.size;
    return null;
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Level-0: ToolInfo from .aid-manifest.json (mirrors parsers.py parse_tool_info)
// ---------------------------------------------------------------------------

function parseToolInfo(manifestPath, versionPath) {
  let bytesRead = 0;

  if (existsSync(manifestPath)) {
    let raw;
    try {
      raw = readFileBounded(manifestPath);
      bytesRead += raw.length;
    } catch (_) {
      return [
        { manifest_present: false, aid_version: null, installed_at: null, tools_installed: [] },
        bytesRead,
      ];
    }
    let data;
    try {
      data = JSON.parse(raw.toString("utf-8"));
    } catch (_) {
      return [
        { manifest_present: false, aid_version: null, installed_at: null, tools_installed: [] },
        bytesRead,
      ];
    }

    const aidVersion = data.aid_version != null ? String(data.aid_version) : null;
    const installedAt = data.installed_at != null ? String(data.installed_at) : null;
    const toolsDict = typeof data.tools === "object" && data.tools !== null ? data.tools : {};
    const toolsInstalled = Object.keys(toolsDict);

    return [
      { manifest_present: true, aid_version: aidVersion, installed_at: installedAt, tools_installed: toolsInstalled },
      bytesRead,
    ];
  }

  // Fallback: .aid-version
  if (existsSync(versionPath)) {
    let raw;
    try {
      raw = readFileBounded(versionPath);
      bytesRead += raw.length;
    } catch (_) {
      return [
        { manifest_present: false, aid_version: null, installed_at: null, tools_installed: [] },
        bytesRead,
      ];
    }
    const versionStr = raw.toString("utf-8").trim() || null;
    return [
      { manifest_present: false, aid_version: versionStr, installed_at: null, tools_installed: [] },
      bytesRead,
    ];
  }

  return [
    { manifest_present: false, aid_version: null, installed_at: null, tools_installed: [] },
    bytesRead,
  ];
}

// ---------------------------------------------------------------------------
// Level-1: RepoInfo helpers (mirrors parsers.py parse_project_name / parse_kb_state)
// ---------------------------------------------------------------------------

// PF-6: strip inline YAML comment from a scalar value.
// Drops everything from the first '#' that is NOT inside a quoted string.
function stripYamlInlineComment(scalar) {
  const s = scalar;
  if (s && (s[0] === '"' || s[0] === "'")) {
    const quote = s[0];
    const end = s.indexOf(quote, 1);
    if (end !== -1) {
      const after = s.slice(end + 1).trimStart();
      if (after.startsWith("#")) {
        return s.slice(0, end + 1);
      }
    }
    return s;
  }
  // Unquoted: first '#' is the comment
  const idx = s.indexOf("#");
  if (idx !== -1) {
    return s.slice(0, idx);
  }
  return s;
}

// parseProjectSettings: extracts project.name + project.description from
// .aid/settings.yml. Both scalars live in the SAME 'project:' block, so this
// is one shared line-scan (feature-002, work-017 task-005). Returns
// [name, description, bytesRead]; on any failure ["", null, 0].
// Twin of parsers.py parse_project_settings().
function parseProjectSettings(settingsPath) {
  if (!existsSync(settingsPath)) return ["", null, 0];
  let raw;
  try {
    raw = readFileBounded(settingsPath);
  } catch (_) {
    return ["", null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  let inProject = false;
  let name = null;
  let description = null;
  for (const line of text.split("\n")) {
    const stripped = line.trim();
    if (stripped === "project:" || stripped.startsWith("project: ")) {
      inProject = true;
      continue;
    }
    if (inProject) {
      if (line.length > 0 && !/^\s/.test(line) && !line.startsWith("#") && line.includes(":")) {
        const key = line.split(":")[0].trim();
        if (key !== "name" && key !== "description") {
          if (!/^\s/.test(line)) break;
        }
      }
      let m = line.match(/^\s+name:\s+(.+)/);
      if (m && name === null) {
        // PF-6: strip inline YAML comment
        name = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        continue;
      }
      m = line.match(/^\s+description:\s+(.+)/);
      if (m && description === null) {
        description = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        continue;
      }
    }
  }
  return [name !== null ? name : "", description, bytesRead];
}

// parseProjectName: thin wrapper over parseProjectSettings (kept for existing
// callers that only need the name). Twin of parsers.py parse_project_name().
function parseProjectName(settingsPath) {
  const [name, , bytesRead] = parseProjectSettings(settingsPath);
  return [name, bytesRead];
}

// parseSettingsMinimumGrade: extracts the GLOBAL review.minimum_grade from
// .aid/settings.yml. Its own 'review:'-section line-scan -- structurally
// SEPARATE from the 'project:' block (a real settings.yml has 'tools:'
// between 'project:' and 'review:', so parseProjectSettings's
// break-on-next-top-level-key logic cannot reach 'review:'). Returns
// [grade, bytesRead]; absent/unreadable -> [null, bytesRead or 0]. Read
// literally as a display scalar -- no resolution. Twin of parsers.py
// parse_minimum_grade() -- named parseSettingsMinimumGrade (not
// parseMinimumGrade) in this flat file only to avoid colliding with the
// pre-existing per-work parseMinimumGrade(text) below (twin of
// derivation.py's _parse_minimum_grade, a STATE.md-text scan -- Python
// keeps the two apart via module namespacing + the underscore prefix;
// this single-file Node twin needs a distinct name instead).
function parseSettingsMinimumGrade(settingsPath) {
  if (!existsSync(settingsPath)) return [null, 0];
  let raw;
  try {
    raw = readFileBounded(settingsPath);
  } catch (_) {
    return [null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  let inReview = false;
  let grade = null;
  for (const line of text.split("\n")) {
    const stripped = line.trim();
    if (stripped === "review:" || stripped.startsWith("review: ")) {
      inReview = true;
      continue;
    }
    if (inReview) {
      if (line.length > 0 && !/^\s/.test(line) && !line.startsWith("#") && line.includes(":")) {
        const key = line.split(":")[0].trim();
        if (key !== "minimum_grade") {
          if (!/^\s/.test(line)) break;
        }
      }
      const m = line.match(/^\s+minimum_grade:\s+(.+)/);
      if (m && grade === null) {
        const val = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        if (val) grade = val;
        continue;
      }
    }
  }
  return [grade, bytesRead];
}

// ---------------------------------------------------------------------------
// task-064: parseKbBaseline -- tolerant line-scan of settings.yml kb_baseline block
// Twin of dashboard/reader/parsers.py parse_kb_baseline (byte-parity minded, DM-A4)
// ---------------------------------------------------------------------------

function parseKbBaseline(settingsPath) {
  // Returns [{branch, tip_date}|null, bytesRead]
  // Tolerant line-scan of the 'kb_baseline:' nested block in .aid/settings.yml.
  // Absent/unparseable -> null (skip freshness, stay approved; FF-A2).
  if (!existsSync(settingsPath)) return [null, 0];
  let raw;
  try {
    raw = readFileBounded(settingsPath);
  } catch (_) {
    return [null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  let inBaseline = false;
  let branch = null;
  let tipDate = null;

  for (const line of text.split("\n")) {
    const stripped = line.trim();
    if (stripped === "kb_baseline:" || stripped.startsWith("kb_baseline: ")) {
      inBaseline = true;
      continue;
    }
    if (inBaseline) {
      // Another top-level key (no leading whitespace) ends the block
      if (line.length > 0 && !/^\s/.test(line) && line.includes(":") && !stripped.startsWith("#")) {
        break;
      }
      // Extract branch:
      let m = line.match(/^\s+branch:\s+(.+)/);
      if (m && branch === null) {
        let val = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        if (val) branch = val;
        continue;
      }
      // Extract tip_date:
      m = line.match(/^\s+tip_date:\s+(.+)/);
      if (m && tipDate === null) {
        let val = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        if (val) tipDate = val;
        continue;
      }
    }
  }

  if (branch === null && tipDate === null) return [null, bytesRead];
  return [{ branch: branch, tip_date: tipDate }, bytesRead];
}

function parseKbSummaryApproval(text, fm) {
  // Frontmatter-first (task-002): summary_approved/last_summary scalars.
  // Twin of Python _parse_kb_summary_approval(). Returns
  // [approved, date, sourceMode].
  if (fm) {
    const fmApproved = fm.summary_approved;
    if (fmApproved !== undefined) {
      const approved = !!parseBoolYesno(fmApproved);
      const fmLast = fm.last_summary;
      let date = null;
      if (fmLast !== undefined && !isNull(fmLast)) {
        date = fmLast.trim();
      }
      return [approved, date, SourceMode.Normalized];
    }
  }

  // Legacy-prose fallback (UNCHANGED behavior): '## Knowledge Summary Status'
  // bold line (not a table row -- see parsers.py's _parse_kb_summary_approval
  // docstring for why this remains the real legacy-compat path).
  let inSummaryStatus = false;
  for (const line of text.split("\n")) {
    if (/^##\s+Knowledge Summary Status/.test(line)) {
      inSummaryStatus = true;
      continue;
    }
    if (inSummaryStatus) {
      if (/^##\s+/.test(line)) break;
      const m = line.trim().match(/^\*\*User Approved:\*\*\s+(.+)/);
      if (m) {
        const val = m[1].trim();
        const approved = val.toLowerCase().startsWith("yes");
        const dateM = val.match(/\((\d{4}-\d{2}-\d{2})/);
        const date = dateM ? dateM[1] : null;
        return [approved, date, SourceMode.Fallback];
      }
    }
  }
  return [false, null, SourceMode.Fallback];
}

function parseKbDocCount(text) {
  let inCompleteness = false;
  let count = 0;
  let headerSeen = false;

  for (const line of text.split("\n")) {
    if (/^##\s+Completeness/.test(line)) {
      inCompleteness = true;
      headerSeen = false;
      count = 0;
      continue;
    }
    if (inCompleteness) {
      if (/^##\s+/.test(line)) break;
      if (!line.trim().startsWith("|")) continue;
      if (line.includes("---")) {
        headerSeen = true;
        continue;
      }
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      const cols = line.trim().replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (cols.length >= 2 && cols[0]) {
        count++;
      }
    }
  }
  return inCompleteness ? count : null;
}

function parseKbState(kbDir) {
  // summary_present is stat'd from kbDir/kb.html: the generated KB summary now
  // lives beside its KB source in .aid/knowledge/ (the .aid/dashboard/ folder was
  // eliminated -- home.html is served by the CLI, kb.html moved here). (task-064)
  let isDir = false;
  try {
    isDir = statSync(kbDir).isDirectory();
  } catch (_) {
    isDir = false;
  }
  if (!isDir) return [null, 0];

  let bytesRead = 0;
  let summaryApproved = false;
  let lastSummaryDate = null;
  let docCount = null;
  let sourceMode = SourceMode.Fallback;
  let kbStatusVal = null;
  let kbGradeVal = null;
  let lastKbReviewVal = null;

  const statePath = join(kbDir, "STATE.md");
  if (existsSync(statePath)) {
    let raw;
    try {
      raw = readFileBounded(statePath);
      bytesRead += raw.length;
      const stateText = raw.toString("utf-8");
      const fm = parseFrontmatterScalars(stateText);
      [summaryApproved, lastSummaryDate, sourceMode] = parseKbSummaryApproval(stateText, fm);

      // Newly-captured discovery-status scalars (task-002): frontmatter-first,
      // legacy header-blockquote fallback.
      let v = fm["kb_status"];
      if (v !== undefined && !isNull(v)) {
        kbStatusVal = v.trim();
      } else {
        const legacy = parseHeaderBoldField(stateText, "Status");
        if (legacy !== null && !isNull(legacy)) kbStatusVal = legacy;
      }

      v = fm["kb_grade"];
      if (v !== undefined && !isNull(v)) {
        kbGradeVal = v.trim();
      } else {
        const legacy = parseHeaderBoldField(stateText, "Current Grade");
        if (legacy !== null && !isNull(legacy)) kbGradeVal = legacy;
      }

      v = fm["last_kb_review"];
      if (v !== undefined && !isNull(v)) {
        lastKbReviewVal = v.trim();
      } else {
        const legacy = parseHeaderBoldField(stateText, "Last KB Review");
        if (legacy !== null && !isNull(legacy)) lastKbReviewVal = legacy;
      }
    } catch (_) {
      // ignore
    }
  }

  const readmePath = join(kbDir, "README.md");
  if (existsSync(readmePath)) {
    let raw;
    try {
      raw = readFileBounded(readmePath);
      bytesRead += raw.length;
      const readmeText = raw.toString("utf-8");
      docCount = parseKbDocCount(readmeText);
    } catch (_) {
      // ignore
    }
  }

  // task-064: stat kbDir/kb.html for summary_present (kb.html now lives beside its
  // KB source in .aid/knowledge/, not in the eliminated .aid/dashboard/ folder).
  let summaryPresent = false;
  const kbHtmlPath = join(kbDir, "kb.html");
  try {
    summaryPresent = statSync(kbHtmlPath).isFile();
  } catch (_) {
    summaryPresent = false;
  }

  return [
    {
      summary_approved: summaryApproved,
      last_summary_date: lastSummaryDate,
      doc_count: docCount,
      summary_present: summaryPresent,
      // status and kb_baseline set by readRepo after derivation
      status: KbStatus.unknown,
      kb_baseline: null,
      source_mode: sourceMode,
      kb_status: kbStatusVal,
      kb_grade: kbGradeVal,
      last_kb_review: lastKbReviewVal,
    },
    bytesRead,
  ];
}

// ---------------------------------------------------------------------------
// task-064: UTC-instant normalization helper (R12, FF-A2 step 4)
// Twin of derivation.py _normalize_to_utc_ms (byte-parity minded)
// ---------------------------------------------------------------------------

function normalizeToUtcMs(isoStr) {
  // Parse ISO-8601 string and return UTC milliseconds since epoch.
  // Handles Z-suffix and +/-HH:MM offset forms. Returns null if unparseable.
  // Node: Date.parse() / getTime() -- same UTC epoch for same ISO-8601 input as Python.
  if (!isoStr) return null;
  const ms = Date.parse(isoStr);
  if (isNaN(ms)) return null;
  return ms;
}

// ---------------------------------------------------------------------------
// task-064: FF-A2 git freshness check (read-only bounded subprocess)
// Twin of derivation.py git_freshness_check / _resolve_git_branch / _run_git_log
// ---------------------------------------------------------------------------

const GIT_TIMEOUT_MS = 2000; // 2s timeout (matches Python _GIT_TIMEOUT_S = 2)

function runGitCommand(args, cwd) {
  // Run git with the given args (no shell). Returns stdout string or null on failure.
  // cwd: working directory for the process (null -> use process.cwd()).
  //      When args include -C <path>, cwd is not needed (git changes into <path>).
  // Degradation: ENOENT (git absent), nonzero, timeout, OSError -> null.
  const opts = {
    timeout: GIT_TIMEOUT_MS,
    stdio: ["ignore", "pipe", "pipe"],
    encoding: "utf-8",
  };
  if (cwd !== null && cwd !== undefined) {
    opts.cwd = cwd;
  }
  try {
    const stdout = execFileSync("git", args, opts);
    return (stdout || "").trim() || null;
  } catch (_) {
    return null;
  }
}

function resolveGitBranch(repoRoot, kbBaseline) {
  // DD-A2 branch resolution: prefer baseline.branch, else origin/HEAD, else main/master.
  // Twin of Python derivation.py _resolve_git_branch.
  // Uses -C <repoRoot> to match Python's argv exactly (no shell, no cwd).
  if (kbBaseline && kbBaseline.branch) {
    return kbBaseline.branch;
  }
  // Try: git -C <repoRoot> symbolic-ref --short refs/remotes/origin/HEAD
  const ref = runGitCommand(
    ["-C", repoRoot, "symbolic-ref", "--short", "refs/remotes/origin/HEAD"],
    null  // cwd not needed when using -C
  );
  if (ref) {
    // basename: "origin/main" -> "main"
    return ref.includes("/") ? ref.split("/").pop() : ref;
  }
  // Fallback: first of {main, master} that exists
  // Try: git -C <repoRoot> rev-parse --verify refs/heads/<candidate>
  for (const candidate of ["main", "master"]) {
    const out = runGitCommand(
      ["-C", repoRoot, "rev-parse", "--verify", "refs/heads/" + candidate],
      null
    );
    if (out !== null) return candidate;
  }
  return null;
}

function runGitLog(repoRoot, branch) {
  // Run: git -C <repoRoot> log -1 --format=%cI --end-of-options <branch>
  // argv identical to Python twin (no shell).
  // Returns ISO-8601 date string or null on every failure.
  //
  // SECURITY (HIGH, v2.1.0): branch is read verbatim from an untrusted repo's
  // .aid/settings.yml (kb_baseline.branch). Without --end-of-options, a value
  // like "--output=/path/to/file" is parsed as a git OPTION (not a revision),
  // letting an attacker create/truncate an arbitrary file. --end-of-options
  // (git 2.24+) forces every argument after it to be treated as a revision,
  // never an option, closing the injection.
  return runGitCommand(
    ["-C", repoRoot, "log", "-1", "--format=%cI", "--end-of-options", branch],
    null
  );
}

// ---------------------------------------------------------------------------
// Security/perf hardening (v2.1.0, FIX-4 LOW): per-process freshness cache.
// Twin of derivation.py's git_freshness_check in-process cache (same rationale
// and TTL). See the Python module comment for the full correctness rationale:
// a cache keyed on .aid/knowledge/ mtime ALONE would be unsound (the "outdated"
// verdict tracks the default branch advancing, unrelated to kb_dir mtime), so
// a short TTL bounds staleness while the mtime key gives early invalidation
// when the KB folder itself changes.
// ---------------------------------------------------------------------------
const FRESHNESS_CACHE = new Map();
const FRESHNESS_CACHE_TTL_MS = 5000; // 5s (matches Python _FRESHNESS_CACHE_TTL_S)

function _freshnessCacheKey(repoRoot, kbBaseline) {
  const kbDir = join(repoRoot, ".aid", "knowledge");
  let mtimeMs = null;
  try {
    mtimeMs = statSync(kbDir).mtimeMs;
  } catch (_) {
    mtimeMs = null;
  }
  return [
    resolve(repoRoot),
    kbBaseline.branch || null,
    kbBaseline.tip_date || null,
    mtimeMs,
  ].join("|");
}

function gitFreshnessCheck(repoRoot, kbBaseline) {
  // FF-A2: Check if the default branch has advanced past kb_baseline.
  // Returns "approved" | "outdated" | "skip".
  // Every failure mode (DD-A2 7-mode degradation matrix) -> "skip" -> stay approved.
  // Twin of Python derivation.py git_freshness_check.
  //
  // FIX-4 (LOW, v2.1.0): result is cached in-process for FRESHNESS_CACHE_TTL_MS,
  // keyed on (repoRoot, branch, baseline, kb_dir mtime).

  // Degradation mode 6: kb_baseline absent
  if (!kbBaseline) return "skip";

  const cacheKey = _freshnessCacheKey(repoRoot, kbBaseline);
  const now = Date.now();
  const cached = FRESHNESS_CACHE.get(cacheKey);
  if (cached && (now - cached.at) <= FRESHNESS_CACHE_TTL_MS) {
    return cached.result;
  }

  const branch = resolveGitBranch(repoRoot, kbBaseline);
  let result;
  if (branch === null) {
    result = "skip";
  } else {
    // Run: git -C <repoRoot> log -1 --format=%cI --end-of-options <branch> (via
    // runGitLog; twin of Python git_freshness_check -> _run_git_log). Any
    // failure -> null -> skip.
    const currentTipStr = runGitLog(repoRoot, branch);
    if (!currentTipStr) {
      result = "skip";
    } else {
      // UTC normalization before compare (R12, never raw string compare)
      const currentMs = normalizeToUtcMs(currentTipStr);
      const baselineMs = normalizeToUtcMs(kbBaseline.tip_date || "");
      if (currentMs === null || baselineMs === null) {
        result = "skip";
      } else {
        result = currentMs > baselineMs ? "outdated" : "approved";
      }
    }
  }

  FRESHNESS_CACHE.set(cacheKey, { result, at: now });
  return result;
}

// ---------------------------------------------------------------------------
// task-064: FF-A3 KB 5-state status waterfall (feature-007 DM-A2)
// Twin of derivation.py derive_kb_status (byte-parity minded)
// ---------------------------------------------------------------------------

function deriveKbStatus(kbDir, summaryApproved, summaryPresent, kbBaseline, repoRoot) {
  // Waterfall (outermost-first, DD-A3):
  //   1. .aid/knowledge/ absent or empty                           -> pending
  //   2. KB present but not yet User Approved: yes                 -> generating
  //      (SPEC residual-#1 safe default -- applied verbatim)
  //   3. KB approved but kb.html absent OR summary not V1-approved -> preparing
  //   4. freshness_check == "outdated"                             -> outdated
  //   5. else                                                      -> approved
  // Never throws (NFR7).
  try {
    // Step 1: .aid/knowledge/ absent or empty -> pending
    let isDir = false;
    try { isDir = statSync(kbDir).isDirectory(); } catch (_) { isDir = false; }
    if (!isDir) return KbStatus.pending;
    let entries = [];
    try { entries = readdirSync(kbDir); } catch (_) { entries = []; }
    if (entries.length === 0) return KbStatus.pending;

    // Step 2: KB present but not yet User Approved: yes -> generating
    if (!summaryApproved) return KbStatus.generating;

    // Step 3: KB approved but kb.html absent OR summary not V1-approved -> preparing
    if (!summaryPresent) return KbStatus.preparing;

    // Step 4+5: freshness check (last, only over approved)
    const freshness = gitFreshnessCheck(repoRoot, kbBaseline);
    if (freshness === "outdated") return KbStatus.outdated;

    return KbStatus.approved;
  } catch (_) {
    return KbStatus.unknown;
  }
}

// ---------------------------------------------------------------------------
// f007 / task-042: per-doc freshness (byte-parity twin of derivation.py)
// ---------------------------------------------------------------------------

const RE_FM_FENCE = /^---\s*$/;
const RE_URL_SOURCE = /^[a-z][a-z0-9+.\-]*:\/\//;

function isUrlSource(entry) {
  // Twin of Python parsers.is_url_source() and kb-freshness-check.sh is_url().
  return RE_URL_SOURCE.test(entry);
}

function parseDocFrontmatter(docPath) {
  // Tolerant sources:/approved_at_commit: frontmatter scan for one KB doc.
  // Twin of Python parsers.parse_doc_frontmatter().
  //
  // Returns [approvedAtCommit, sourcesList, sourcesFieldPresent].
  //   approvedAtCommit:      string or null
  //   sourcesList:           string[] (items from sources: list)
  //   sourcesFieldPresent:   boolean (true even if sources: [])
  //
  // Never throws. Handles inline list [a,b] + block list (- a\n  - b).

  let approvedAtCommit = null;
  const sourcesList = [];
  let sourcesFieldPresent = false;

  let raw;
  try {
    raw = readFileBounded(docPath).toString("utf-8");
  } catch (_) {
    return [null, [], false];
  }

  const lines = raw.split("\n");
  let inFm = false;
  let fmEntered = false;
  let inSourcesBlock = false;

  for (const line of lines) {
    const stripped = line.replace(/\r$/, "");
    if (RE_FM_FENCE.test(stripped)) {
      if (!fmEntered) {
        inFm = true;
        fmEntered = true;
        continue;
      } else {
        break;
      }
    }
    if (!inFm) {
      break;
    }

    if (inSourcesBlock) {
      // Block-list item: leading whitespace + '-'
      const mItem = /^[ \t]+-[ \t]*(.*)/.exec(stripped);
      if (mItem) {
        const item = mItem[1].trim().replace(/^['"]|['"]$/g, "");
        if (item) sourcesList.push(item);
        continue;
      } else {
        inSourcesBlock = false;
        // fall through to check this line for other fields
      }
    }

    // approved_at_commit: scalar
    const mAac = /^approved_at_commit:\s*(.*)/.exec(stripped);
    if (mAac) {
      const val = mAac[1].trim().replace(/^['"]|['"]$/g, "");
      approvedAtCommit = val || null;
      continue;
    }

    // sources: field
    const mSrc = /^sources:\s*(.*)/.exec(stripped);
    if (mSrc) {
      sourcesFieldPresent = true;
      const rest = mSrc[1].trim();
      if (rest === "[]") {
        // Explicit empty inline list: sources: []
        // sourcesFieldPresent already set; list stays empty
        continue;
      }
      if (!rest) {
        // Bare 'sources:' with nothing after -- block list follows
        inSourcesBlock = true;
        continue;
      }
      if (rest.startsWith("[")) {
        // Inline list: [a, b, c]
        const inner = rest.replace(/^\[/, "").replace(/\].*$/, "").trim();
        if (inner) {
          for (const item of inner.split(",")) {
            const s = item.trim().replace(/^['"]|['"]$/g, "");
            if (s) sourcesList.push(s);
          }
        }
        continue;
      }
      // Block list -- following indented lines are items
      inSourcesBlock = true;
      continue;
    }
  }

  return [approvedAtCommit, sourcesList, sourcesFieldPresent];
}

// ---------------------------------------------------------------------------
// feature-007-connectors-list (work-017 task-019): connectors registry parser
// (byte-parity twin of Python parsers.parse_connectors()).
// ---------------------------------------------------------------------------

// The six connector-descriptor frontmatter scalars (feature-001's frozen
// schema) -- the SAME fields build-connectors-index.sh's ef() and
// connector-registry.sh's read_field address.
const CONNECTOR_FM_FIELDS = [
  "name", "connection_type", "endpoint", "auth_method", "secret_reference", "summary",
];

function _parseConnectorFrontmatterScalars(text) {
  // Extract the six connector-descriptor frontmatter scalars from the FIRST
  // frontmatter block only. Twin of Python
  // parsers._parse_connector_frontmatter_scalars().
  //
  // Same semantics as connector-registry.sh's read_field() / build-connectors-
  // index.sh's ef(): a single-line 'field: value' scalar, with ONE pair of
  // surrounding quotes stripped, first occurrence wins. A body-level
  // thematic-break '---' is never re-entered as frontmatter -- the scan stops
  // the instant the frontmatter block closes.
  //
  // Returns a plain object keyed by field name; a field absent from the
  // frontmatter (or a wholly frontmatter-less file) is simply absent from the
  // returned object. Never throws.
  const result = {};
  let inFm = false;
  let fmEntered = false;

  const lines = text.split("\n");
  for (const rawLine of lines) {
    const line = rawLine.replace(/\r$/, "");
    if (RE_FM_FENCE.test(line)) {
      if (!fmEntered) {
        inFm = true;
        fmEntered = true;
        continue;
      } else {
        // Closing fence -- stop scanning entirely (never re-enter
        // frontmatter for a body-level thematic break).
        break;
      }
    }
    if (!inFm) {
      break;
    }

    for (const fld of CONNECTOR_FM_FIELDS) {
      if (Object.prototype.hasOwnProperty.call(result, fld)) continue; // first occurrence wins
      const prefix = fld + ":";
      if (line.startsWith(prefix)) {
        let val = line.slice(prefix.length).trim();
        if (val.length >= 1 && (val[0] === '"' || val[0] === "'")) {
          val = val.slice(1);
        }
        if (val.length >= 1 && (val[val.length - 1] === '"' || val[val.length - 1] === "'")) {
          val = val.slice(0, -1);
        }
        result[fld] = val;
      }
    }
  }

  return result;
}

export function parseConnectors(connectorsDir) {
  // Enumerate <aid_dir>/connectors/*.md into a stem-sorted array of
  // ConnectorRef-shaped plain objects. Twin of Python parsers.parse_connectors().
  //
  // Uses the EXACT filter connector-registry.sh's `list` op uses
  // (connector-registry.sh lines 151-154): `*.md` files directly under
  // connectorsDir, excluding `INDEX.md` and dotfiles, sorted by stem. A
  // missing connectorsDir -> [] (non-error; mirrors the script's own
  // missing-root behavior).
  //
  // Returns [refs, bytesRead]. Never throws.
  let isDir = false;
  try {
    isDir = statSync(connectorsDir).isDirectory();
  } catch (_) {
    isDir = false;
  }
  if (!isDir) return [[], 0];

  let entries = [];
  try {
    entries = readdirSync(connectorsDir);
  } catch (_) {
    return [[], 0];
  }

  const candidates = entries
    .filter((name) => name.endsWith(".md") && name !== "INDEX.md" && !name.startsWith("."))
    .filter((name) => {
      try {
        return statSync(join(connectorsDir, name)).isFile();
      } catch (_) {
        return false;
      }
    });

  const stemOf = (name) => name.slice(0, -3); // strip trailing ".md"
  candidates.sort((a, b) => {
    const sa = stemOf(a);
    const sb = stemOf(b);
    return sa < sb ? -1 : sa > sb ? 1 : 0;
  });

  let bytesRead = 0;
  const refs = [];
  for (const name of candidates) {
    const stem = stemOf(name);
    const path = join(connectorsDir, name);
    let text = "";
    try {
      const raw = readFileBounded(path);
      bytesRead += raw.length;
      text = raw.toString("utf-8");
    } catch (_) {
      text = "";
    }

    const fm = _parseConnectorFrontmatterScalars(text);
    const name_ = fm.name || stem;
    const connectionType = fm.connection_type !== undefined ? fm.connection_type : "";
    const endpoint = fm.endpoint || null;
    const authMethod = fm.auth_method || null;
    const secretReference = fm.secret_reference || null;
    const summary = fm.summary || null;

    refs.push({
      stem,
      name: name_,
      connection_type: connectionType,
      endpoint,
      auth_method: authMethod,
      secret_reference: secretReference,
      summary,
    });
  }

  return [refs, bytesRead];
}

// ---------------------------------------------------------------------------
// feature-010-external-sources-list (work-017 task-021): external-sources
// registry wrapper (byte-parity twin of Python parsers.parse_external_sources()).
// NO new frontmatter parser -- a thin wrapper over the existing
// parseDocFrontmatter().
// ---------------------------------------------------------------------------

export function parseExternalSources(kbDir) {
  // Twin of Python parsers.parse_external_sources(). Returns the deduped,
  // order-preserved sources: entries of <kbDir>/external-sources.md, with the
  // discovery placeholder "(none)" filtered out. Absent/frontmatter-less file
  // -> parseDocFrontmatter already returns [] for sourcesList -> [].
  //
  // Reader-parity note (feature-010 SPEC): parseDocFrontmatter's block-list
  // continuation only matches CONTIGUOUS leading-whitespace '-' item lines --
  // a comment or blank line between sources: and its items ends the block
  // (and it does not strip a trailing inline '# comment' from a block item).
  // The write-external-source.sh writer (task-020) normalizes the block to
  // contiguous '  - <item>' lines directly under sources:, with no inline
  // comment, so every dashboard-managed entry is reader-visible here (AC2).
  const [, sourcesList] = parseDocFrontmatter(join(kbDir, "external-sources.md"));
  const seen = new Set();
  const result = [];
  for (const item of sourcesList) {
    if (item === "(none)") continue;
    if (seen.has(item)) continue;
    seen.add(item);
    result.push(item);
  }
  return result;
}

function _readRoutingFields(docPath) {
  // Read kb-category and source frontmatter scalars for doc routing.
  // Returns [kbCategory, sourceField]. Absent fields return "".
  // Twin of Python derivation._read_routing_fields().
  // Never throws.

  let raw;
  try {
    raw = readFileBounded(docPath).toString("utf-8");
  } catch (_) {
    return ["", ""];
  }

  const lines = raw.split("\n");
  let inFm = false;
  let fmEntered = false;
  let kbCat = "";
  let srcField = "";

  for (const line of lines) {
    const stripped = line.replace(/\r$/, "");
    if (RE_FM_FENCE.test(stripped)) {
      if (!fmEntered) {
        inFm = true;
        fmEntered = true;
        continue;
      } else {
        break;
      }
    }
    if (!inFm) break;

    const mCat = /^kb-category:\s*(.*)/.exec(stripped);
    if (mCat) {
      kbCat = mCat[1].trim().replace(/^['"]|['"]$/g, "");
      continue;
    }
    const mSrc = /^source:\s*(.*)/.exec(stripped);
    if (mSrc) {
      srcField = mSrc[1].trim().replace(/^['"]|['"]$/g, "");
      continue;
    }
  }

  return [kbCat, srcField];
}

function _runMergeBaseIsAncestor(repoRoot, cSrc, baseline) {
  // Returns "current" | "suspect" | "unknown".
  // execFileSync throws on non-zero exit; status 1 = NOT ancestor = suspect.
  // Any other error (128 bad object, ENOENT, timeout) = unknown.
  //
  // SECURITY (LOW, v2.1.0): baseline is frontmatter-derived (approved_at_commit:)
  // and cSrc comes from a prior git-log lookup; neither is fully trusted input.
  // --end-of-options (git 2.24+) guards both trailing commit-ish arguments from
  // being parsed as options (same rationale as runGitLog's --end-of-options).
  try {
    execFileSync(
      "git",
      ["-C", repoRoot, "merge-base", "--is-ancestor", "--end-of-options", cSrc, baseline],
      {
        timeout: GIT_TIMEOUT_MS,
        stdio: ["ignore", "pipe", "pipe"],
        encoding: "utf-8",
      }
    );
    // exit 0 = ancestor/equal = current
    return "current";
  } catch (err) {
    // execFileSync throws with err.status for non-zero exit
    if (err && err.status === 1) {
      // exit 1 = NOT ancestor = source changed after baseline
      return "suspect";
    }
    // exit 128 (bad object), ENOENT (git absent), timeout, etc. -> unknown
    return "unknown";
  }
}

const SKIP_NAMES = new Set(["INDEX.md", "README.md", "STATE.md"]);

function deriveDocFreshness(kbDir, repoRoot) {
  // f007: Per-doc freshness read for all hand-authored primary/extension KB docs.
  // Twin of Python derivation.derive_doc_freshness().
  //
  // Same algorithm as kb-freshness-check.sh (task-040):
  //   - Same doc routing (skip INDEX.md, README.md, STATE.md, meta, generated)
  //   - Same absence gate (no approved_at_commit: -> unknown; no/empty sources: -> current)
  //   - Same git verbs: git log -1 --format=%H -- <src> + merge-base --is-ancestor
  //   - Same fold rule: suspect > current > unknown
  //   - Same degrade-to-unknown matrix (any git failure -> unknown, never false suspect)
  //
  // Returns array of {doc, verdict, suspect_sources} sorted by doc path.
  // Never throws. No writes.

  const results = [];

  let isDir = false;
  try { isDir = statSync(kbDir).isDirectory(); } catch (_) { isDir = false; }
  if (!isDir) return results;

  let entries = [];
  try { entries = readdirSync(kbDir); } catch (_) { return results; }

  // Sort deterministically (same as Python sorted() + bash sort)
  const mdFiles = entries
    .filter(n => n.endsWith(".md") && !n.startsWith("."))
    .sort();

  for (const name of mdFiles) {
    if (SKIP_NAMES.has(name)) continue;

    const docPath = join(kbDir, name);

    // Check routing fields: kb-category and source
    const [kbCat, srcField] = _readRoutingFields(docPath);
    if (kbCat === "meta") continue;
    if (srcField === "generated") continue;
    // Only primary and extension with hand-authored (or absent) source
    if (kbCat !== "primary" && kbCat !== "extension" && kbCat !== "") continue;

    const rel = name;

    // Parse frontmatter: approved_at_commit + sources
    const [approvedAtCommit, sourcesList, sourcesFieldPresent] =
      parseDocFrontmatter(docPath);

    // Absence gate: missing/empty approved_at_commit -> unknown (never suspect)
    if (!approvedAtCommit) {
      results.push({ doc: rel, verdict: "unknown", suspect_sources: [] });
      continue;
    }

    // sources: absent or empty -> current (nothing to drift against)
    if (!sourcesFieldPresent || sourcesList.length === 0) {
      results.push({ doc: rel, verdict: "current", suspect_sources: [] });
      continue;
    }

    // Per-source staleness checks
    let nCurrent = 0;
    let nSuspect = 0;
    let nUnknown = 0;
    const suspectSources = [];

    for (const entry of sourcesList) {
      const srcVerdict = _checkSourceNode(entry, approvedAtCommit, repoRoot);
      if (srcVerdict === "current") {
        nCurrent++;
      } else if (srcVerdict === "suspect") {
        nSuspect++;
        suspectSources.push(entry);
      } else {
        nUnknown++;
      }
    }

    // Fold rule (identical to script and Python twin)
    let verdict;
    if (nSuspect > 0) {
      verdict = "suspect";
    } else if (nCurrent > 0) {
      verdict = "current";
    } else {
      verdict = "unknown";
    }

    results.push({ doc: rel, verdict, suspect_sources: suspectSources });
  }

  return results;
}

function _checkSourceNode(entry, approvedAtCommit, repoRoot) {
  // Node implementation of check_source (twin of Python _check_source).
  // Returns "current" | "suspect" | "unknown".

  if (isUrlSource(entry)) return "unknown";

  // Get last-changed commit for this path/glob
  const cSrc = runGitCommand(
    ["-C", repoRoot, "log", "-1", "--format=%H", "--", entry],
    null
  );
  if (!cSrc) return "unknown";

  // merge-base --is-ancestor: exit 0 = current, exit 1 = suspect, other = unknown
  return _runMergeBaseIsAncestor(repoRoot, cSrc, approvedAtCommit);
}

// ---------------------------------------------------------------------------
// Derivation helpers (mirrors derivation.py)
// ---------------------------------------------------------------------------

const RE_HISTORY_SECTION = /^##\s+Lifecycle History\s*$/i;
const RE_TABLE_SEP = /^\|[\s\-|]+\|$/;
const CANCEL_RE = /cancel(?:ed)?/i;
const RE_DATE = /\b(\d{4}-\d{2}-\d{2})\b/;

function hasTableSep(stripped) {
  return RE_TABLE_SEP.test(stripped);
}

function hasCancellationInHistory(text, warnings, workId) {
  let inHistory = false;
  let headerSeen = false;

  for (const line of text.split("\n")) {
    if (RE_HISTORY_SECTION.test(line)) {
      inHistory = true;
      headerSeen = false;
      continue;
    }
    if (inHistory) {
      if (/^##\s+/.test(line)) break;
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (hasTableSep(stripped)) continue;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      // Phase Transition / Gate is column index 1
      const gateCol = cols.length > 1 ? cols[1].trim() : "";
      if (CANCEL_RE.test(gateCol)) {
        return true;
      }
      // Check all columns for ambiguous mentions
      if (cols.some(c => CANCEL_RE.test(c))) {
        const prefix = workId ? workId + ": " : "";
        warnings.push(
          prefix + "## Lifecycle History row mentions cancellation outside " +
          "Gate column (ambiguous); check manually: " + stripped
        );
      }
    }
  }
  return false;
}

function extractLatestHistoryDate(text) {
  let inHistory = false;
  let headerSeen = false;
  let latest = null;

  for (const line of text.split("\n")) {
    if (RE_HISTORY_SECTION.test(line)) {
      inHistory = true;
      headerSeen = false;
      continue;
    }
    if (inHistory) {
      if (/^##\s+/.test(line)) break;
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (hasTableSep(stripped)) continue;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      const dateCol = cols.length > 0 ? cols[0].trim() : "";
      const m = dateCol.match(RE_DATE);
      if (m) {
        const d = m[1];
        if (latest === null || d > latest) {
          latest = d;
        }
      }
    }
  }
  return latest;
}

const RE_DEPLOY_STATUS = /^##\s+Deploy Status\s*$/i;
const RE_PLAN_DELIVERIES = /^##\s+Plan\s*\/\s*Deliveries\s*$/i;
const SHIPPED_RE = /\b(shipped|deployed|done|complete[d]?)\b/i;
const DELIVERY_DONE_RE = /^done$/i;

function deployStatusShipped(text) {
  let inDeploy = false;
  let headerSeen = false;

  for (const line of text.split("\n")) {
    if (RE_DEPLOY_STATUS.test(line)) {
      inDeploy = true;
      headerSeen = false;
      continue;
    }
    if (inDeploy) {
      if (/^##\s+/.test(line)) break;
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (hasTableSep(stripped)) continue;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      const statusCol = cols.length > 1 ? cols[1].trim() : "";
      if (SHIPPED_RE.test(statusCol)) return true;
    }
  }
  return false;
}

function allDeliveriesDone(text) {
  let inPlan = false;
  let headerSeen = false;
  let rowCount = 0;
  let allDone = true;

  for (const line of text.split("\n")) {
    if (RE_PLAN_DELIVERIES.test(line)) {
      inPlan = true;
      headerSeen = false;
      rowCount = 0;
      allDone = true;
      continue;
    }
    if (inPlan) {
      if (/^##\s+/.test(line)) break;
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (hasTableSep(stripped)) continue;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      if (cols.some(c => c.includes("_none yet_"))) continue;
      const statusCol = cols.length > 1 ? cols[1].trim() : "";
      if (!statusCol) continue;
      rowCount++;
      if (!DELIVERY_DONE_RE.test(statusCol)) {
        allDone = false;
      }
    }
  }
  return inPlan && rowCount > 0 && allDone;
}

function hasOpenTask(tasks) {
  return tasks.some(t => t.status === TaskStatus.InProgress || t.status === TaskStatus.InReview);
}

function isCompleted(text, tasks) {
  if (deployStatusShipped(text)) return true;
  if (allDeliveriesDone(text) && !hasOpenTask(tasks)) return true;
  return false;
}

const IMPEDIMENT_RE = /^IMPEDIMENT-task-\w+\.md$/i;
const RE_DELIVERY_GATES = /^##\s+Delivery Gates\s*$/i;
const RE_GRADE_LINE = /\*\*Grade:\*\*\s*(\S+)/i;
const RE_MINIMUM_GRADE_LINE = /\*\*Minimum Grade:\*\*\s*(\S+)/i;
const GRADE_ORDER = ["F", "D", "C", "B", "A"];

function gradeBelow(grade, minimum) {
  if (!GRADE_ORDER.includes(grade) || !GRADE_ORDER.includes(minimum)) return false;
  return GRADE_ORDER.indexOf(grade) < GRADE_ORDER.indexOf(minimum);
}

function parseMinimumGrade(text) {
  for (const line of text.split("\n")) {
    if (/^##\s+/.test(line)) break;
    const m = line.match(RE_MINIMUM_GRADE_LINE);
    if (m) return m[1].trim().toUpperCase();
  }
  return null;
}

function findSubminimumGate(text) {
  const minimumGrade = parseMinimumGrade(text);
  let inGates = false;
  let currentDelivery = null;

  for (const line of text.split("\n")) {
    if (RE_DELIVERY_GATES.test(line)) {
      inGates = true;
      currentDelivery = null;
      continue;
    }
    if (inGates) {
      if (/^##\s+/.test(line) && !/^###\s+/.test(line)) break;
      const hm = line.match(/^###\s+(\S+)/);
      if (hm) {
        currentDelivery = hm[1];
        continue;
      }
      if (currentDelivery) {
        const gm = line.match(RE_GRADE_LINE);
        if (gm) {
          const grade = gm[1].trim().toUpperCase();
          if (minimumGrade && gradeBelow(grade, minimumGrade)) {
            return currentDelivery;
          }
        }
      }
    }
  }
  return null;
}

function findImpedimentFile(workDir) {
  let entries;
  try {
    entries = readdirSync(workDir);
  } catch (_) {
    return null;
  }
  for (const name of entries) {
    if (IMPEDIMENT_RE.test(name)) {
      const fullPath = join(workDir, name);
      try {
        if (statSync(fullPath).isFile()) return fullPath;
      } catch (_) {
        // skip
      }
    }
  }
  return null;
}

function findBlockSignal(workDir, tasks, stateText) {
  // (a) IMPEDIMENT file
  const impedimentPath = findImpedimentFile(workDir);
  if (impedimentPath !== null) {
    const artifact = basename(impedimentPath);
    return [`IMPEDIMENT file present: ${artifact}`, artifact];
  }

  // (b) Failed task
  const failedTasks = tasks.filter(t => t.status === TaskStatus.Failed);
  if (failedTasks.length > 0) {
    const ids = failedTasks.map(t => t.task_id).join(", ");
    return [`Task(s) failed: ${ids}`, null];
  }

  // (c) Sub-minimum delivery gate
  const gateFail = findSubminimumGate(stateText);
  if (gateFail) {
    return [`Delivery gate below minimum: ${gateFail}`, gateFail];
  }

  return [null, null];
}

function deriveLifecycle({ workDir, tasks, pendingInputs, stateText, workId }) {
  const warnings = [];

  // Prio 1: Canceled
  if (hasCancellationInHistory(stateText, warnings, workId)) {
    return [
      Lifecycle.Canceled, SourceMode.Fallback,
      null, null, null,
      extractLatestHistoryDate(stateText),
      warnings,
    ];
  }

  // Prio 2: Completed
  if (isCompleted(stateText, tasks)) {
    return [
      Lifecycle.Completed, SourceMode.Fallback,
      null, null, null,
      extractLatestHistoryDate(stateText),
      warnings,
    ];
  }

  // Prio 3: Blocked
  const [blockReason, blockArtifact] = findBlockSignal(workDir, tasks, stateText);
  if (blockReason !== null) {
    return [
      Lifecycle.Blocked, SourceMode.Fallback,
      null, blockReason, blockArtifact,
      extractLatestHistoryDate(stateText),
      warnings,
    ];
  }

  // Prio 4: Paused-Awaiting-Input
  if (pendingInputs.length > 0) {
    const qIds = pendingInputs.map(p => p.question_id).join(", ");
    const pauseReason = `Pending Q&A: ${qIds}`;
    return [
      Lifecycle.PausedAwaitingInput, SourceMode.Fallback,
      pauseReason, null, null,
      extractLatestHistoryDate(stateText),
      warnings,
    ];
  }

  // Prio 5: Running (default)
  return [
    Lifecycle.Running, SourceMode.Fallback,
    null, null, null,
    extractLatestHistoryDate(stateText),
    warnings,
  ];
}

// ---------------------------------------------------------------------------
// REQUIREMENTS.md parser (mirrors parsers.py parse_requirements_md)
// ---------------------------------------------------------------------------

function parseRequirementsMd(reqPath) {
  // Returns [title, description, objective, bytesRead]
  // PF-2: status blockquote lines (^> _..._) are skipped in the Objective body.
  let isFile = false;
  try { isFile = statSync(reqPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [null, null, null, 0];

  let raw;
  try {
    raw = readFileBounded(reqPath);
  } catch (_) {
    return [null, null, null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  const RE_NAME = /^\s*-\s*\*\*Name:\*\*\s*(.+)/i;
  const RE_DESC = /^\s*-\s*\*\*Description:\*\*\s*(.+)/i;
  const RE_OBJ_HDR = /^##\s+(?:\d+\.\s+)?Objective\s*$/i;
  const RE_SECTION_HDR = /^##\s+\S/;
  // PF-2: status blockquote footer: > _..._  (wholly italic blockquote)
  const RE_STATUS_BLOCKQUOTE = /^>\s*_.*_\s*$/;

  // Template seed placeholder: treat *(pending)* as absent (PF-7)
  const PENDING_PLACEHOLDER = "*(pending)*";

  let title = null;
  let description = null;
  const objLines = [];
  let inObjective = false;

  for (const line of text.split("\n")) {
    if (inObjective) {
      if (RE_SECTION_HDR.test(line)) {
        inObjective = false;
      } else {
        // PF-2: skip status blockquote lines
        if (!RE_STATUS_BLOCKQUOTE.test(line.trim())) {
          objLines.push(line);
        }
      }
      continue;
    }

    let m = line.match(RE_NAME);
    if (m && title === null) {
      const val = m[1].trim();
      title = val === PENDING_PLACEHOLDER ? null : val;
      continue;
    }
    m = line.match(RE_DESC);
    if (m && description === null) {
      const val = m[1].trim();
      description = val === PENDING_PLACEHOLDER ? null : val;
      continue;
    }
    if (RE_OBJ_HDR.test(line)) {
      inObjective = true;
      continue;
    }
  }

  let objective = null;
  if (objLines.length > 0) {
    const raw_obj = objLines.join("\n").trim();
    if (raw_obj) objective = raw_obj;
  }

  return [title, description, objective, bytesRead];
}

// ---------------------------------------------------------------------------
// PF-8: parse work-root SPEC.md for identity fields (Lite-path fallback)
// ---------------------------------------------------------------------------

export function parseSpecMd(specPath) {
  // Returns [title, description, h1Title, bytesRead]
  // Mirrors parse_spec_md in parsers.py (byte-parity).
  // - title: value from '- **Name:**' line (null if absent or *(pending)*)
  // - description: value from '- **Description:**' line (null if absent or *(pending)*)
  // - h1Title: text after the first '# ' line (null if absent)
  // Reuses RE_NAME/RE_DESC from parseRequirementsMd and PENDING_PLACEHOLDER.
  let isFile = false;
  try { isFile = statSync(specPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [null, null, null, 0];

  let raw;
  try {
    raw = readFileBounded(specPath);
  } catch (_) {
    return [null, null, null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  const RE_NAME = /^\s*-\s*\*\*Name:\*\*\s*(.+)/i;
  const RE_DESC = /^\s*-\s*\*\*Description:\*\*\s*(.+)/i;
  const RE_H1 = /^#\s+(.+)$/;

  // Template seed placeholder: treat *(pending)* as absent (PF-7)
  const PENDING_PLACEHOLDER = "*(pending)*";

  let title = null;
  let description = null;
  let h1Title = null;

  // Split on \r\n, \r, or \n (mirrors Python splitlines() \r handling) -- CRLF fix
  for (const line of text.split(/\r\n|\r|\n/)) {
    if (h1Title === null) {
      const mh = line.match(RE_H1);
      if (mh) {
        h1Title = mh[1].trim();
        continue;
      }
    }

    let m = line.match(RE_NAME);
    if (m && title === null) {
      const val = m[1].trim();
      title = val === PENDING_PLACEHOLDER ? null : val;
      continue;
    }
    m = line.match(RE_DESC);
    if (m && description === null) {
      const val = m[1].trim();
      description = val === PENDING_PLACEHOLDER ? null : val;
      continue;
    }

    // Stop scanning after all three fields are found
    if (title !== null && description !== null && h1Title !== null) break;
  }

  return [title, description, h1Title, bytesRead];
}

// ---------------------------------------------------------------------------
// PF-3: parse task short-name from tasks/task-NNN.md first line
// ---------------------------------------------------------------------------

function parseTaskShortName(taskPath) {
  // Returns [shortName, bytesRead]
  // Parse rule: ^#\s+task-0*\d+\s*:\s*(.+)$  (case-insensitive)
  // Strips trailing period from the title.
  let isFile = false;
  try { isFile = statSync(taskPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [null, 0];

  let raw;
  try {
    raw = readFileBounded(taskPath);
  } catch (_) {
    return [null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  const RE_TITLE = /^#\s+task-0*\d+\s*:\s*(.+)$/i;

  for (const line of text.split("\n")) {
    const stripped = line.trim();
    if (!stripped) continue;
    const m = stripped.match(RE_TITLE);
    if (m) {
      let title = m[1].trim().replace(/\.$/, "");
      return [title || null, bytesRead];
    }
    // First non-blank line didn't match -> no short_name
    break;
  }

  return [null, bytesRead];
}

// ---------------------------------------------------------------------------
// PF-5: parse execution graph from PLAN.md (wave-map + prose fallback)
// ---------------------------------------------------------------------------

function parseExecutionGraph(planPath) {
  // Returns [taskLaneMap, bytesRead]
  // taskLaneMap: { task_id -> lane (int) }
  // Delivery comes from STATE (PF-5c); this only derives the lane.
  let isFile = false;
  try { isFile = statSync(planPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [{}, 0];

  let raw;
  try {
    raw = readFileBounded(planPath);
  } catch (_) {
    return [{}, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  const taskLaneMap = {};
  const lines = text.split("\n");

  // --- PF-5a: scan for wave-map fenced blocks ---
  const RE_WAVEMAP_OPEN = /^```wave-map\s*$/;
  const RE_WAVEMAP_CLOSE = /^```\s*$/;
  const RE_DELIVERY_LINE = /^delivery:\s*(\d+)\s*$/;
  const RE_WAVE_LINE = /^wave\s+(\d+)\s*:\s*(.+)$/i;
  const RE_TASK_ID = /\btask-\d+\b/gi;

  const wavemapDeliveries = new Set();

  let i = 0;
  while (i < lines.length) {
    const line = lines[i].trim();
    if (RE_WAVEMAP_OPEN.test(line)) {
      i++;
      let blockDelivery = null;
      while (i < lines.length) {
        const bline = lines[i].trim();
        if (RE_WAVEMAP_CLOSE.test(bline)) { i++; break; }
        const dm = bline.match(RE_DELIVERY_LINE);
        if (dm) {
          blockDelivery = parseInt(dm[1], 10);
          if (!isNaN(blockDelivery)) wavemapDeliveries.add(blockDelivery);
          i++; continue;
        }
        const wm = bline.match(RE_WAVE_LINE);
        if (wm) {
          const lane = parseInt(wm[1], 10);
          const tasksStr = wm[2];
          let tm;
          const re = /\btask-\d+\b/gi;
          while ((tm = re.exec(tasksStr)) !== null) {
            taskLaneMap[tm[0].toLowerCase()] = lane;
          }
          i++; continue;
        }
        i++;
      }
    } else {
      i++;
    }
  }

  // --- PF-5b: prose fallback for delivery sections with no wave-map ---
  const RE_DELIVERY_SECTION = /^###\s+delivery-(\d+)\s+execution\s+graph/i;
  const RE_WAVE_PROSE = /^(\s*)-\s*Wave\s+(\d+)\b/i;

  const wavemapTaskIds = new Set(Object.keys(taskLaneMap));
  let currentDelivery = null;
  let currentWave = null;
  let waveIndent = null;

  for (const line of lines) {
    const dsm = line.match(RE_DELIVERY_SECTION);
    if (dsm) {
      currentDelivery = parseInt(dsm[1], 10);
      currentWave = null;
      waveIndent = null;
      continue;
    }

    // Only prose-fallback for deliveries without a wave-map
    if (currentDelivery === null || wavemapDeliveries.has(currentDelivery)) {
      currentWave = null;
      waveIndent = null;
      continue;
    }

    const wpm = line.match(RE_WAVE_PROSE);
    if (wpm) {
      currentWave = parseInt(wpm[2], 10);
      waveIndent = wpm[1].length;
      // Collect task ids from the heading line
      const re = /\btask-\d+\b/gi;
      let tm;
      while ((tm = re.exec(line)) !== null) {
        const tid = tm[0].toLowerCase();
        if (!wavemapTaskIds.has(tid)) taskLaneMap[tid] = currentWave;
      }
      continue;
    }

    if (currentWave !== null && waveIndent !== null) {
      const lineIndent = line.length - line.trimStart().length;
      if (line.trim() === "") {
        // blank line: keep wave context
      } else if (lineIndent > waveIndent) {
        // sub-bullet: collect task ids
        const re = /\btask-\d+\b/gi;
        let tm;
        while ((tm = re.exec(line)) !== null) {
          const tid = tm[0].toLowerCase();
          if (!wavemapTaskIds.has(tid)) taskLaneMap[tid] = currentWave;
        }
      } else {
        // dedented -> end of wave sub-bullets
        currentWave = null;
        waveIndent = null;
      }
    }
  }

  return [taskLaneMap, bytesRead];
}

// ---------------------------------------------------------------------------
// Slug extraction (mirrors reader.py _slug_from_work_id)
// ---------------------------------------------------------------------------

function numberFromWorkId(workId) {
  // mirrors reader.py _number_from_work_id
  const m = workId.match(/^work-(\d+)-/);
  if (m) {
    const n = parseInt(m[1], 10);
    if (!isNaN(n)) return n;
  }
  return null;
}

// ---------------------------------------------------------------------------
// STATE.md parser (mirrors parsers.py parse_state_md)
// ---------------------------------------------------------------------------

// Accept BOTH new "State" names (work-004 rename) and legacy "Status" names
// (Pillar 3 / Pillar 6 coexistence: new works use "State"; old works keep "Status").
const RE_PIPELINE_STATUS = /^##\s+Pipeline (?:State|Status)\s*$/i;
const RE_TASKS_STATUS = /^##\s+Tasks (?:State|Status)\s*$/i;
const RE_CROSSPHASE_QA = /^##\s+Cross-phase Q&A/i;
const RE_TRIAGE = /^##\s+Triage\s*$/i;
const RE_FEATURES_STATUS = /^##\s+Features (?:State|Status)\s*$/i;
// RE_PLAN_DELIVERIES already declared in derivation helpers above (reused here)
const RE_LIFECYCLE_HISTORY_SECTION = /^##\s+Lifecycle History\s*$/i;
const RE_SECTION = /^##\s+\S/;

const RE_TRIAGE_PATH   = /^\s*-\s*\*\*Path:\*\*\s*(.+)/i;
const RE_TRIAGE_RECIPE = /^\s*-\s*\*\*Recipe:\*\*\s*(.+)/i;

const RE_PS_LIFECYCLE    = /^\s*-\s*\*\*Lifecycle:\*\*\s*(.+)/i;
const RE_PS_PHASE        = /^\s*-\s*\*\*Phase:\*\*\s*(.+)/i;
const RE_PS_SKILL        = /^\s*-\s*\*\*Active Skill:\*\*\s*(.+)/i;
const RE_PS_UPDATED      = /^\s*-\s*\*\*Updated:\*\*\s*(.+)/i;
const RE_PS_PAUSE_REASON = /^\s*-\s*\*\*Pause Reason:\*\*\s*(.+)/i;
const RE_PS_BLOCK_REASON = /^\s*-\s*\*\*Block Reason:\*\*\s*(.+)/i;
const RE_PS_BLOCK_ART    = /^\s*-\s*\*\*Block Artifact:\*\*\s*(.+)/i;

const RE_QN_HEADER  = /^###\s+(Q\d+)\s*$/;
const RE_QN_STATUS  = /^\s*-\s*\*\*Status:\*\*\s*(.+)/i;
const RE_QN_CAT     = /^\s*-\s*\*\*Category:\*\*\s*(.+)/i;
const RE_QN_IMPACT  = /^\s*-\s*\*\*Impact:\*\*\s*(.+)/i;
const RE_QN_CONTEXT = /^\s*-\s*\*\*Context:\*\*\s*(.+)/i;
const RE_QN_SUGGEST = /^\s*-\s*\*\*Suggested:\*\*\s*(.+)/i;

const NONE_YET = "_none yet_";

function parseStateText(text, workId, workDir) {
  // Dual-format (task-002): parse the YAML frontmatter block ONCE; applied
  // AFTER the legacy prose line-scan below (frontmatter wins when present).
  const fm = parseFrontmatterScalars(text);

  // ParsedWork fields
  let lifecycle = Lifecycle.Unknown;
  let phase = null;
  let activeSkill = null;
  let updated = null;
  let pauseReason = null;
  let blockReason = null;
  let blockArtifact = null;
  const tasks = [];
  const pendingInputs = [];
  let sourceMode = SourceMode.Fallback;
  const parseWarnings = [];
  let bytesRead = 0; // bytes accounted by caller
  // prototype: work-overview header fields
  let workPath = null;
  let recipe = null;
  const features = [];
  const deliverables = [];
  // work-003-state-schema task-002: dual-format frontmatter read, new fields
  let kind = null;
  let started = null;
  let minimumGrade = null;
  let userApproved = null;

  let inPipelineStatus = false;
  let pipelineStatusFound = false;
  let inTasks = false;
  let inCrossphase = false;
  let inTriage = false;
  let inFeatures = false;
  let inDeliveries = false;
  let inLifecycleHistory = false;
  let tasksHeaderSeen = false;
  let featuresHeaderSeen = false;
  let deliveriesHeaderSeen = false;
  let lifecycleHistoryHeaderSeen = false;
  let created = null;

  let currentQId = null;
  let currentQ = {};

  function flushQ() {
    if (currentQId && (currentQ.status || "").toLowerCase() === "pending") {
      pendingInputs.push({
        question_id: currentQId,
        category: currentQ.category || null,
        impact: currentQ.impact || null,
        context: currentQ.context || null,
        suggested: currentQ.suggested || null,
      });
    }
    currentQId = null;
    currentQ = {};
  }

  function resetSections() {
    inPipelineStatus = false;
    inTasks = false;
    inCrossphase = false;
    inTriage = false;
    inFeatures = false;
    inDeliveries = false;
    inLifecycleHistory = false;
  }

  const lines = text.split("\n");
  for (const line of lines) {
    if (RE_PIPELINE_STATUS.test(line)) {
      flushQ(); resetSections();
      inPipelineStatus = true;
      // Mirror Python parsers.py:748: pipeline_status_found=True for ANY line in the section.
      // The heading itself counts -- presence of ## Pipeline Status means normalized source.
      pipelineStatusFound = true;
      continue;
    }
    if (RE_TASKS_STATUS.test(line)) {
      flushQ(); resetSections();
      inTasks = true;
      tasksHeaderSeen = false;
      continue;
    }
    if (RE_CROSSPHASE_QA.test(line)) {
      flushQ(); resetSections();
      inCrossphase = true;
      continue;
    }
    if (RE_TRIAGE.test(line)) {
      flushQ(); resetSections();
      inTriage = true;
      continue;
    }
    if (RE_FEATURES_STATUS.test(line)) {
      flushQ(); resetSections();
      inFeatures = true;
      featuresHeaderSeen = false;
      continue;
    }
    if (RE_PLAN_DELIVERIES.test(line)) {
      flushQ(); resetSections();
      inDeliveries = true;
      deliveriesHeaderSeen = false;
      continue;
    }
    if (RE_LIFECYCLE_HISTORY_SECTION.test(line)) {
      flushQ(); resetSections();
      inLifecycleHistory = true;
      lifecycleHistoryHeaderSeen = false;
      continue;
    }
    if (RE_SECTION.test(line)) {
      flushQ(); resetSections();
      continue;
    }

    if (inPipelineStatus) {
      let m;
      if ((m = line.match(RE_PS_LIFECYCLE))) {
        lifecycle = parseLifecycle(m[1].trim());
        pipelineStatusFound = true;
        continue;
      }
      if ((m = line.match(RE_PS_PHASE))) {
        phase = parsePhase(m[1].trim());
        pipelineStatusFound = true;
        continue;
      }
      if ((m = line.match(RE_PS_SKILL))) {
        const val = m[1].trim();
        activeSkill = (isNull(val) || val === "none") ? null : val;
        pipelineStatusFound = true;
        continue;
      }
      if ((m = line.match(RE_PS_UPDATED))) {
        const val = m[1].trim();
        updated = isNull(val) ? null : val;
        pipelineStatusFound = true;
        continue;
      }
      if ((m = line.match(RE_PS_PAUSE_REASON))) {
        const val = m[1].trim();
        pauseReason = isNull(val) ? null : val;
        pipelineStatusFound = true;
        continue;
      }
      if ((m = line.match(RE_PS_BLOCK_REASON))) {
        const val = m[1].trim();
        blockReason = isNull(val) ? null : val;
        pipelineStatusFound = true;
        continue;
      }
      if ((m = line.match(RE_PS_BLOCK_ART))) {
        const val = m[1].trim();
        blockArtifact = isNull(val) ? null : val;
        pipelineStatusFound = true;
        continue;
      }
      // Any recognized Pipeline Status line counts as found
      if (/^\s*-\s*\*\*/.test(line)) {
        pipelineStatusFound = true;
      }
      continue;
    }

    if (inTasks) {
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (hasTableSep(stripped)) continue;

      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (cols.length < 2) continue;

      // Skip header row: pattern-based only (col[0] is "#" or blank), mirrors Python
      // parsers.py:910 which only skips when cols[0] in ("#", "").
      // Do NOT unconditionally skip the first row -- a headerless table must keep it.
      if ((cols[0] === "#" || cols[0] === "") && !tasksHeaderSeen) {
        tasksHeaderSeen = true;
        continue;
      }
      // Mark first non-separator pipe row seen (matches Python header_seen tracking)
      tasksHeaderSeen = true;

      // Skip _none yet_ placeholder
      if (cols.some(c => c.includes(NONE_YET))) continue;

      function col(idx) {
        if (idx < cols.length) {
          const v = cols[idx].trim();
          return isNull(v) ? null : v;
        }
        return null;
      }

      const taskId = col(1) || col(0) || "";
      if (!taskId || taskId === "#") continue;

      const statusStr = col(4) || "";
      const status = parseTaskStatus(statusStr);

      tasks.push({
        task_id: taskId,
        type: col(2) || "",
        wave: col(3),
        status: status,
        review_grade: col(5),
        elapsed: col(6),
        notes: col(7),
      });
      continue;
    }

    if (inCrossphase) {
      let m;
      if ((m = line.match(RE_QN_HEADER))) {
        flushQ();
        currentQId = m[1];
        currentQ = {};
        continue;
      }
      if (currentQId) {
        // Accept both "Status:" (legacy) and "State:" (new, Pillar 3) for Q&A state
        if ((m = line.match(RE_QN_STATUS)) ||
            (m = line.match(/^\s*-\s*\*\*State:\*\*\s*(.+)/i))) {
          currentQ.status = m[1].trim();
          continue;
        }
        if ((m = line.match(RE_QN_CAT))) {
          currentQ.category = m[1].trim();
          continue;
        }
        if ((m = line.match(RE_QN_IMPACT))) {
          currentQ.impact = m[1].trim();
          continue;
        }
        if ((m = line.match(RE_QN_CONTEXT))) {
          currentQ.context = m[1].trim();
          continue;
        }
        if ((m = line.match(RE_QN_SUGGEST))) {
          currentQ.suggested = m[1].trim();
          continue;
        }
      }
    }

    if (inTriage) {
      let m;
      if ((m = line.match(RE_TRIAGE_PATH))) {
        const val = m[1].trim();
        if (!isNull(val)) workPath = val.toLowerCase();
      } else if ((m = line.match(RE_TRIAGE_RECIPE))) {
        const val = m[1].trim();
        if (!isNull(val)) recipe = val;
      }
      continue;
    }

    if (inFeatures) {
      // mirrors parsers.py _parse_features_line
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (hasTableSep(stripped)) continue;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (cols.length < 2) continue;
      // Skip header row: pattern-based (col[0] is "#" or empty) before first data row seen
      if ((cols[0] === "#" || cols[0] === "") && !featuresHeaderSeen) {
        featuresHeaderSeen = true;
        continue;
      }
      // Mark first non-separator pipe row seen (mirrors Python: header_seen set after any | row)
      featuresHeaderSeen = true;

      function fcol(idx) {
        if (idx < cols.length) { const v = cols[idx].trim(); return isNull(v) ? null : v; }
        return null;
      }
      const numStr = fcol(0) || "";
      const featureName = fcol(1) || "";
      if (!numStr || numStr === "#" || !featureName) continue;
      const number = parseInt(numStr, 10);
      if (isNaN(number)) continue;
      // Readable name: strip "feature-NNN-" prefix (mirrors Python)
      let readable = featureName.replace(/^feature-\d+-/i, "").replace(/-/g, " ").trim();
      if (!readable) readable = featureName;
      features.push({ number: number, name: readable });
      continue;
    }

    if (inDeliveries) {
      // mirrors parsers.py _parse_deliveries_line
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (hasTableSep(stripped)) continue;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (cols.length < 3) continue;
      // Skip header row: pattern-based (first col "Delivery" or blank) before first data row seen
      if ((cols[0].toLowerCase() === "delivery" || cols[0] === "") && !deliveriesHeaderSeen) {
        deliveriesHeaderSeen = true;
        continue;
      }
      // Mark first non-separator pipe row seen (mirrors Python: header_seen set after any | row)
      deliveriesHeaderSeen = true;

      function dcol(idx) {
        if (idx < cols.length) { const v = cols[idx].trim(); return isNull(v) ? null : v; }
        return null;
      }
      const deliveryId = dcol(0) || "";
      const tasksStr = dcol(2) || "";
      const notesStr = dcol(3) || "";
      if (!deliveryId || deliveryId.toLowerCase() === "delivery") continue;
      // Parse delivery number from "delivery-NNN"
      const dm = deliveryId.match(/^delivery-(\d+)/i);
      if (!dm) continue;
      const number = parseInt(dm[1], 10);
      // task_count: leading integer from tasks column
      let taskCount = 0;
      const tm = tasksStr.match(/^(\d+)/);
      if (tm) taskCount = parseInt(tm[1], 10);
      // name: first clause of notes (split on ";", " - ", " -- ")
      let name = deliveryId;
      if (notesStr) {
        const short = notesStr.split(";")[0].split(" - ")[0].split(" -- ")[0].trim();
        if (short) name = short;
      }
      deliverables.push({ number: number, name: name, task_count: taskCount });
      continue;
    }

    if (inLifecycleHistory) {
      // mirrors parsers.py _parse_lifecycle_history_line + its caller
      // The caller flips header_seen for ANY non-separator pipe row regardless
      // of column count; the <2-col guard only skips data extraction.
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (hasTableSep(stripped)) continue;
      // Flip header-seen for ALL non-separator pipe rows (mirrors Python caller)
      const wasHeaderSeen = lifecycleHistoryHeaderSeen;
      lifecycleHistoryHeaderSeen = true;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (cols.length < 2) continue;
      // Skip header row (first non-separator pipe row) before first data row
      if (!wasHeaderSeen) continue;
      // Only extract created once (first matching row)
      if (created === null) {
        const dateVal = cols[0].trim();
        const gateVal = cols[1].trim();
        if (gateVal.toLowerCase() === "work created" && dateVal) {
          created = dateVal;
        }
      }
      continue;
    }
  }

  flushQ();

  // Dual-format (task-002): frontmatter-first override for the ## Pipeline
  // State scalars, applied AFTER the legacy prose scan above so frontmatter
  // (the newer, authoritative source) wins whenever both are present. A
  // migrated STATE.md's ## Pipeline State section body is enum-reference
  // prose ONLY (no more "- **Lifecycle:** ..." bullets) -- without this
  // override, a migrated work would render Lifecycle.Unknown despite
  // pipelineStatusFound=true (the section header alone is still seen).
  let fmLifecyclePresent = false;
  {
    let v = fm["lifecycle"];
    if (v !== undefined && !isNull(v)) {
      lifecycle = parseLifecycle(v.trim());
      fmLifecyclePresent = true;
    }
    v = fm["phase"];
    if (v !== undefined && !isNull(v)) {
      phase = parsePhase(v.trim());
    }
    v = fm["active_skill"];
    if (v !== undefined) {
      const vv = v.trim();
      activeSkill = (isNull(vv) || vv.toLowerCase() === "none") ? null : vv;
    }
    v = fm["updated"];
    if (v !== undefined && !isNull(v)) {
      updated = v.trim();
    }
    v = fm["pause_reason"];
    if (v !== undefined) {
      const vv = v.trim();
      pauseReason = isNull(vv) ? null : vv;
    }
    v = fm["block_reason"];
    if (v !== undefined) {
      const vv = v.trim();
      blockReason = isNull(vv) ? null : vv;
    }
    v = fm["block_artifact"];
    if (v !== undefined) {
      const vv = v.trim();
      blockArtifact = isNull(vv) ? null : vv;
    }
  }

  // Normalized path: if ## Pipeline Status was found (legacy prose) OR the
  // frontmatter supplied a valid `lifecycle` scalar, set source_mode=normalized.
  if (pipelineStatusFound || fmLifecyclePresent) {
    sourceMode = SourceMode.Normalized;
  } else {
    // LC-3 FALLBACK ADAPTER
    const _wd = workDir || ".";
    const [
      derivedLifecycle, derivedSourceMode,
      derivedPauseReason, derivedBlockReason, derivedBlockArtifact,
      derivedUpdated, extraWarnings,
    ] = deriveLifecycle({
      workDir: _wd,
      tasks,
      pendingInputs,
      stateText: text,
      workId: workId || "",
    });
    lifecycle = derivedLifecycle;
    sourceMode = derivedSourceMode;
    pauseReason = derivedPauseReason;
    blockReason = derivedBlockReason;
    blockArtifact = derivedBlockArtifact;
    if (updated === null) {
      updated = derivedUpdated;
    }
    parseWarnings.push(...extraWarnings);
  }

  // Dual-format (task-002): pipeline-identity + newly-captured scalars.
  // Independent of the lifecycle/sourceMode decision above -- these fields
  // have their own frontmatter-first / legacy-prose-fallback resolution.
  {
    // pipeline.path -> workPath (stop inferring via _detectFlat/_detectHierarchy
    // when present; readWork/_readWorkFlat/_readWorkHierarchical keep those
    // layout-detection heuristics as the fallback default for un-migrated works).
    let v = fm["pipeline.path"];
    if (v !== undefined && !isNull(v)) {
      workPath = v.trim().toLowerCase();
    }

    // pipeline.initiator -> kind (display verb, shortcut-catalog.yml mapping).
    // No legacy prose equivalent exists (the old ## Triage **Recipe:** field --
    // still read into `recipe` above -- is a distinct, older, dead-prose concept).
    v = fm["pipeline.initiator"];
    if (v !== undefined && !isNull(v)) {
      kind = resolveKind(v.trim());
    }

    // started (frontmatter-only; no working legacy prose fallback ever existed
    // -- see state_schema.py's docstring). Retires the fragile 'Work created'
    // row-scrape for migrated works: `created` is ALSO backfilled here so
    // existing consumers (home.html work.created, the JSON 'created' key)
    // keep working unchanged.
    v = fm["started"];
    if (v !== undefined && !isNull(v)) {
      const startedVal = v.trim();
      started = startedVal;
      created = startedVal;
    }

    // minimum_grade: frontmatter-first; legacy fallback reuses the EXISTING
    // header-blockquote scan (parseMinimumGrade) -- its role in the
    // sub-minimum Blocked-gate derivation (findSubminimumGate) is UNCHANGED;
    // this is a separate exposure of the same value onto the model.
    v = fm["minimum_grade"];
    if (v !== undefined && !isNull(v)) {
      minimumGrade = v.trim().toUpperCase();
    } else {
      const legacyGrade = parseMinimumGrade(text);
      if (legacyGrade) minimumGrade = legacyGrade;
    }

    // user_approved: frontmatter yes/no/true/false (case-insensitive) -> bool;
    // legacy header-blockquote '**User Approved:**' line as fallback.
    // Work-level approval, distinct from the KB's summary_approved.
    v = fm["user_approved"];
    if (v !== undefined) {
      userApproved = parseBoolYesno(v);
    } else {
      const legacyVal = parseHeaderBoldField(text, "User Approved");
      if (legacyVal !== null && !isNull(legacyVal)) {
        userApproved = parseBoolYesno(legacyVal);
      }
    }
  }

  return {
    lifecycle,
    phase,
    activeSkill,
    updated,
    pauseReason,
    blockReason,
    blockArtifact,
    tasks,
    pendingInputs,
    sourceMode,
    parseWarnings,
    workPath,
    recipe,
    features,
    deliverables,
    created,
    kind,
    started,
    minimumGrade,
    userApproved,
  };
}

// ---------------------------------------------------------------------------
// Slug extraction (mirrors reader.py _slug_from_work_id)
// ---------------------------------------------------------------------------

function slugFromWorkId(workId) {
  const m = workId.match(/^work-\d+-(.+)$/);
  return m ? m[1] : workId;
}

// ---------------------------------------------------------------------------
// readRepo(root) -- main entry point (mirrors reader.py read_repo)
// ---------------------------------------------------------------------------

export function readRepo(root) {
  // Thin wrapper: run full pass, discard STATE.md cache, return model only.
  // Signature and return type are UNCHANGED (DR-1/DD-3/NFR4 satisfied by _readRepoFull).
  return _readRepoFull(root).model;
}

function _readRepoFull(root) {
  // Run the full always-on repo read pass.
  // Returns { model, stateCache } where stateCache maps workId -> [stateText, statePathLabel].
  // The cache is a by-product (zero extra I/O); readRepoDetail uses it to satisfy
  // DR-1/DD-3/NFR4 (raw_state reuses bytes already read; no re-read of STATE.md).

  // Normalize: accept repo root or .aid/ dir itself
  let resolvedRoot = resolve(root);
  if (basename(resolvedRoot) === ".aid") {
    resolvedRoot = resolve(resolvedRoot, "..");
  }

  const readAt = new Date().toISOString().replace(/\.\d{3}Z$/, "+00:00");
  const parseWarnings = [];
  let bytesRead = 0;

  // Step 1: RESOLVE
  const loc = locateAidRoot(resolvedRoot);

  if (!loc.aidExists) {
    parseWarnings.push(
      `No .aid/ directory found at ${resolvedRoot}; returning empty model.`
    );
    const emptyModel = _buildRepoModel({
      tool: { manifest_present: false, aid_version: null, installed_at: null, tools_installed: [] },
      repo: { project_name: basename(resolvedRoot), aid_dir: loc.aidDir, kb_state: null },
      works: [],
      read: {
        read_at: readAt,
        work_count: 0,
        fallback_works: [],
        parse_warnings: parseWarnings,
        bytes_read: 0,
      },
    });
    return { model: emptyModel, stateCache: {} };
  }

  // Step 2: LEVEL-0 ToolInfo
  const [toolInfo, br0] = parseToolInfo(loc.manifestPath, loc.versionPath);
  bytesRead += br0;

  // Step 3: LEVEL-1 RepoInfo
  let [projectName, projectDescription, br1] = parseProjectSettings(loc.settingsPath);
  bytesRead += br1;
  if (!projectName) {
    projectName = basename(resolvedRoot);
  }

  // feature-002 (work-017 task-005): GLOBAL review.minimum_grade -- its own
  // 'review:'-section scan (a real settings.yml has 'tools:' between 'project:'
  // and 'review:', so the project-section scan above cannot reach it).
  const [minimumGrade, brGrade] = parseSettingsMinimumGrade(loc.settingsPath);
  bytesRead += brGrade;

  // task-064: parse kb_baseline from settings.yml (DM-A4)
  const [kbBaseline, brBaseline] = parseKbBaseline(loc.settingsPath);
  bytesRead += brBaseline;

  // task-064: parse kb_state with summary_present (stat of .aid/knowledge/kb.html)
  const [kbState, br2] = parseKbState(loc.kbDir);
  bytesRead += br2;

  // task-064: derive 5-state KB status (FF-A3 waterfall) and attach fields
  if (kbState !== null) {
    const kbStatus = deriveKbStatus(
      loc.kbDir,
      kbState.summary_approved,
      kbState.summary_present,
      kbBaseline,
      resolvedRoot
    );
    kbState.status = kbStatus;
    kbState.kb_baseline = kbBaseline;

    // task-042: per-doc freshness (f007) -- additive; gitFreshnessCheck retained
    const docFreshness = deriveDocFreshness(loc.kbDir, resolvedRoot);
    kbState.doc_freshness = docFreshness;
    kbState.suspect_count = docFreshness.filter(d => d.verdict === "suspect").length;
  }

  // feature-007 (work-017 task-019): parse the project-level connectors registry
  // (.aid/connectors/*.md), sorted by stem. Missing dir -> [] (non-error).
  const [connectors, brConnectors] = parseConnectors(join(loc.aidDir, "connectors"));
  bytesRead += brConnectors;

  // feature-010 (work-017 task-021): parse the project-level external-sources
  // registry (.aid/knowledge/external-sources.md sources: list). A thin wrapper
  // over parseDocFrontmatter (no new parser); absent file -> [] (non-error).
  const externalSources = parseExternalSources(loc.kbDir);

  const repoInfo = {
    project_name: projectName,
    aid_dir: loc.aidDir,
    kb_state: kbState,
    project_description: projectDescription,
    minimum_grade: minimumGrade,
    connectors: connectors,
    external_sources: externalSources,
  };

  // Step 4: ENUMERATE worktrees + work folders (work-004 Pillar 4 / SD-3)
  // _enumerateWorktreeRoots returns [[branchLabel, aidDir], ...] with main root first.
  // Degrades to main-root-only on any git failure (never throws).
  // For each (branchLabel, aidDir) root, locate work-NNN-*/ dirs. Each resulting
  // WorkModel is tagged with branchLabel. Cross-root merge of same work_id is Step 6.
  const worktreeRoots = _enumerateWorktreeRoots(resolvedRoot);

  // Steps 5a-5g: PER WORK -- parse STATE.md; build WorkModel list (pre-reconcile).
  // Intermediate accumulator: maps work_id -> [[WorkModel, stateText, stateLabel], ...]
  const workCopies = {}; // work_id -> array of [WorkModel, stateText, stateLabel]

  for (const [branchLabel, wtAidDir] of worktreeRoots) {
    const wtRoot = join(wtAidDir, "..");
    const wtLoc = locateAidRoot(wtRoot);
    if (!wtLoc.aidExists) continue;

    for (const workDir of wtLoc.workDirs) {
      const workId = basename(workDir);
      const [workModel, workWarnings, workBytes, stateText, statePathLabel] = readWork(workDir, workId);
      // Tag the work model with the branch that owns this worktree
      workModel.branch_label = branchLabel;
      parseWarnings.push(...workWarnings);
      bytesRead += workBytes;
      if (!(workId in workCopies)) workCopies[workId] = [];
      workCopies[workId].push([workModel, stateText, statePathLabel]);
    }
  }

  // If worktree enumeration yielded NO results (all worktrees had no .aid/), fall back
  // to the main root so a bare repo without worktrees still renders correctly.
  if (Object.keys(workCopies).length === 0 && loc.aidExists) {
    for (const workDir of loc.workDirs) {
      const workId = basename(workDir);
      const [workModel, workWarnings, workBytes, stateText, statePathLabel] = readWork(workDir, workId);
      workModel.branch_label = null; // indeterminate; worktree list gave no data
      parseWarnings.push(...workWarnings);
      bytesRead += workBytes;
      workCopies[workId] = [[workModel, stateText, statePathLabel]];
    }
  }

  // Step 6: RECONCILE -- for each work_id, merge all copies (Pillar 5 / task-011).
  // Single-copy works pass through _reconcileSameWork unchanged (trivial case).
  const works = [];
  const fallbackWorks = [];
  // Build per-work STATE.md cache as a by-product of the always-on pass.
  const stateCache = {};

  for (const workId of Object.keys(workCopies)) {
    const copies = workCopies[workId];
    const [reconciledWm, winningText, winningLabel] = _reconcileSameWork(copies);
    works.push(reconciledWm);
    stateCache[workId] = [winningText, winningLabel];
    if (reconciledWm.source_mode !== SourceMode.Normalized) {
      fallbackWorks.push(workId);
    }
  }

  // Step 7: ASSEMBLE
  const model = _buildRepoModel({
    tool: toolInfo,
    repo: repoInfo,
    works,
    read: {
      read_at: readAt,
      work_count: works.length,
      fallback_works: fallbackWorks,
      parse_warnings: parseWarnings,
      bytes_read: bytesRead,
    },
  });
  return { model, stateCache };
}

function _taskStopRequested(workDir, workId, taskId) {
  // Derive TaskModel.stop_requested (feature-008-execution-control, work-017
  // task-029): a filesystem `stat` of the cooperative stop-signal file
  // `write-control-signal.sh` (task-028) creates on `task.stop` / removes on
  // `task.resume`.
  //
  // Computed RELATIVE to workDir -- the walked worktree copy of
  // `.aid/works/<work_id>` this read pass is currently processing (WT-1) --
  // NEVER a reconstructed `<served-root>/.aid/.control/<work_id>/` path.
  // `join(workDir, "..", "..", ".control", workId)` is the `.aid/.control/
  // <work_id>/` sibling of workDir's own `.aid/works/`, exactly mirroring
  // `write-control-signal.sh`'s own path derivation (`dashboard/scripts/
  // write-control-signal.sh`: `WORK_DIR/../../.control/WORK_ID`) so the reader
  // stats the identical tree the writer and the `aid-execute` poll act on --
  // the Python twin's `_task_stop_requested` (reader.py) performs the
  // byte-identical stat via `work_dir.parent.parent`.
  //
  // Never parsed from / written to STATE.md (the control file is a new
  // control-artifact class, outside STATE.md's C1 single-writer scope -- see
  // feature-008 SPEC.md "C1 scope note"). Fail-safe: a missing `.control/`
  // directory, a missing signal file, or any error all yield false -- never a
  // parse warning, never a thrown exception (mirrors the reader's
  // forward-compat posture for every other derived field).
  try {
    const controlFile = join(workDir, "..", "..", ".control", workId, taskId + ".stop");
    return statSync(controlFile).isFile();
  } catch (_) {
    return false;
  }
}

function readWork(workDir, workId) {
  // Pillar 6: hierarchy detection (per-work, presence-based)
  if (_detectHierarchy(workDir)) {
    return _readWorkHierarchical(workDir, workId);
  }

  // feature-001: flattened single-delivery layout (per-work, presence-based;
  // mutually exclusive with the deliveries/ wrapper checked above)
  if (_detectFlat(workDir)) {
    return _readWorkFlat(workDir, workId);
  }

  // --- Legacy monolithic path (preserved behavior) ---
  const statePath = join(workDir, "STATE.md");
  const statePathLabel = ".aid/works/" + workId + "/STATE.md";
  const parseWarnings = [];
  let bytesRead = 0;

  let isFile = false;
  try {
    isFile = statSync(statePath).isFile();
  } catch (_) {
    isFile = false;
  }

  if (!isFile) {
    parseWarnings.push(workId + ": STATE.md not found; returning minimal WorkModel.");
    return [_minimalWorkModel(workId), parseWarnings, 0, "", statePathLabel];
  }

  let text;
  let raw;
  try {
    raw = readFileBounded(statePath);
    bytesRead = raw.length;
    text = raw.toString("utf-8");
  } catch (exc) {
    parseWarnings.push(workId + ": STATE.md read error (" + exc + "); returning minimal WorkModel.");
    return [_minimalWorkModel(workId), parseWarnings, 0, "", statePathLabel];
  }

  const pw = parseStateText(text, workId, workDir);
  parseWarnings.push(...pw.parseWarnings);

  const name = slugFromWorkId(workId);

  // Prototype: parse work number from folder prefix (work-NNN-...)
  const workNumber = numberFromWorkId(workId);

  // Prototype: parse REQUIREMENTS.md for identity fields
  const reqPath = join(workDir, "REQUIREMENTS.md");
  let [reqTitle, reqDescription, reqObjective, reqBytes] = parseRequirementsMd(reqPath);
  bytesRead += reqBytes;

  // PF-8: SPEC.md fallback source for Lite-path works (no REQUIREMENTS.md)
  // Resolution order: REQUIREMENTS.md Name -> SPEC.md Name -> SPEC.md H1 -> de-slug
  // Resolution order: REQUIREMENTS.md Description -> SPEC.md Description -> null
  if (reqTitle === null || reqDescription === null) {
    const specPath = join(workDir, "SPEC.md");
    const [specTitle, specDescription, specH1, specBytes] = parseSpecMd(specPath);
    bytesRead += specBytes;
    if (reqTitle === null) {
      // Prefer SPEC.md Name over H1; de-slug is the final fallback (set by 'name')
      if (specTitle !== null) {
        reqTitle = specTitle;
      } else if (specH1 !== null) {
        reqTitle = specH1;
      }
    }
    if (reqDescription === null && specDescription !== null) {
      reqDescription = specDescription;
    }
  }

  // PF-5: parse PLAN.md execution graph to derive lane per task_id
  const planPath = join(workDir, "PLAN.md");
  const [taskLaneMap, planBytes] = parseExecutionGraph(planPath);
  bytesRead += planBytes;

  // PF-3 + PF-5c: enrich each task with short_name, delivery, lane
  const tasksDir = join(workDir, "tasks");
  const RE_DELIVERY = /^delivery-(\d+)$/i;
  const enrichedTasks = pw.tasks.map(task => {
    // PF-5c: delivery from STATE Wave column ("delivery-NNN")
    let delivery = null;
    if (task.wave) {
      const dm = task.wave.trim().match(RE_DELIVERY);
      if (dm) delivery = parseInt(dm[1], 10);
    }

    // PF-5a/5b: lane from PLAN.md wave-map / prose
    const lane = taskLaneMap[task.task_id.toLowerCase()];
    const laneVal = (lane !== undefined) ? lane : null;

    // PF-3: short_name from tasks/task-NNN.md first line
    let shortName = null;
    const taskFile = join(tasksDir, task.task_id + ".md");
    const [sn, snBytes] = parseTaskShortName(taskFile);
    bytesRead += snBytes;
    shortName = sn;

    return Object.assign({}, task, {
      short_name: shortName,
      delivery: delivery,
      lane: laneVal,
      stop_requested: _taskStopRequested(workDir, workId, task.task_id),
    });
  });

  const workModel = _buildWorkModel({
    work_id: workId,
    name,
    lifecycle: pw.lifecycle,
    phase: pw.phase,
    active_skill: pw.activeSkill,
    updated: pw.updated,
    created: pw.created,
    pause_reason: pw.pauseReason,
    block_reason: pw.blockReason,
    block_artifact: pw.blockArtifact,
    tasks: enrichedTasks,
    pending_inputs: pw.pendingInputs,
    source_mode: pw.sourceMode,
    number: workNumber,
    title: reqTitle,
    description: reqDescription,
    objective: reqObjective,
    work_path: pw.workPath,
    recipe: pw.recipe,
    features: pw.features,
    deliverables: pw.deliverables,
    kind: pw.kind,
    started: pw.started,
    minimum_grade: pw.minimumGrade,
    user_approved: pw.userApproved,
  });

  return [workModel, parseWarnings, bytesRead, text, statePathLabel];
}

function _minimalWorkModel(workId) {
  return _buildWorkModel({
    work_id: workId,
    name: slugFromWorkId(workId),
    lifecycle: Lifecycle.Unknown,
    phase: null,
    active_skill: null,
    updated: null,
    created: null,
    pause_reason: null,
    block_reason: null,
    block_artifact: null,
    tasks: [],
    pending_inputs: [],
    source_mode: SourceMode.Fallback,
    number: numberFromWorkId(workId),
    title: null,
    description: null,
    objective: null,
    work_path: null,
    recipe: null,
    features: [],
    deliverables: [],
  });
}

// ---------------------------------------------------------------------------
// work-004 Pillar 5 / SD-2: State advancement ordering (LOCKED)
//
// Authoritative ordered list (most-advanced first, index = rank int):
//   Done(0) > Canceled(1) > In Review(2) > In Progress(3) >
//   Blocked(4) > Failed(5) > Pending(6) > Unknown(7)
//
// Rationale (from SPEC.md SD-2):
//   Done/Canceled are terminal-resolved (highest rank).
//   In Review is past In Progress (review is a later pipeline stage).
//   Blocked outranks Failed: blocked = recoverable-in-place + needs attention;
//   Failed = completed-but-rejected attempt (parallel branch may have superseded it).
//   Both Blocked and Failed outrank Pending (work was attempted; more informative).
//   Unknown is the reader-only sentinel and is ranked last.
//
// The Python twin (reader.py) encodes this SAME ordering verbatim.
// ---------------------------------------------------------------------------
const SD2_RANK = {
  "Done":        0,
  "Canceled":    1,
  "In Review":   2,
  "In Progress": 3,
  "Blocked":     4,
  "Failed":      5,
  "Pending":     6,
  "Unknown":     7,
};
const _SD2_RANK_DEFAULT = 7; // sentinel for any state not in SD2_RANK

function _sd2Rank(taskStatus) {
  // Return the SD-2 rank for a task status string. Lower = more advanced.
  // Never throws.
  try {
    const r = SD2_RANK[taskStatus];
    return r !== undefined ? r : _SD2_RANK_DEFAULT;
  } catch (_) {
    return _SD2_RANK_DEFAULT;
  }
}

// ---------------------------------------------------------------------------
// work-004 Pillar 4 / SD-3: Worktree enumeration helpers
//
// Delegates via the EXISTING runGitCommand fixed-argv / execFileSync no-shell
// pattern (verb hard-coded in argv). No allow-list is enforced (none exists in
// reader.mjs today; safety rests on fixed-argv by construction).
// ---------------------------------------------------------------------------

// Branch name label for the main worktree (must match Python _detect_main_branch_label)
function _detectMainBranchLabel(repoRoot) {
  // Try: git -C <repoRoot> symbolic-ref --short HEAD
  const ref = runGitCommand(
    ["-C", repoRoot, "symbolic-ref", "--short", "HEAD"],
    null
  );
  if (ref) return ref;
  return "main"; // fallback default
}

function _isGitToplevel(repoRoot) {
  // Return true if repoRoot is the git worktree toplevel (not a subdirectory of one).
  // Mirrors Python derivation.py _is_git_toplevel (same guard).
  // Prevents a fixture or nested dir from inheriting the host repo's worktrees.
  // Never throws.
  try {
    const toplevel = runGitCommand(
      ["-C", repoRoot, "rev-parse", "--show-toplevel"],
      null
    );
    if (!toplevel) return false;
    // Resolve both paths for reliable comparison
    const resolvedToplevel = resolve(toplevel.trim());
    const resolvedRoot = resolve(repoRoot);
    return resolvedToplevel === resolvedRoot;
  } catch (_) {
    return false;
  }
}

function _runWorktreeList(repoRoot) {
  // Run: git -C <repoRoot> worktree list --porcelain
  // Verb hard-coded in argv (no shell). 2s timeout via runGitCommand.
  // Safety guard: verifies repoRoot IS the git toplevel before running worktree list.
  // If repoRoot is a subdirectory of a git repo (e.g. a fixture directory nested inside
  // a larger repo), git would walk up and report the enclosing repo's worktrees -- wrong.
  // The guard degrades to null (caller falls back to main-root-only).
  // Returns stdout string or null on any failure.
  if (!_isGitToplevel(repoRoot)) return null;
  return runGitCommand(
    ["-C", repoRoot, "worktree", "list", "--porcelain"],
    null
  );
}

function _parseWorktreePorcelain(output) {
  // Parse `git worktree list --porcelain` output.
  // Returns [ [absPath, branchLabel], ... ]
  // absPath is an absolute path string; branchLabel is branch name or "(detached)".
  // Returns [] on any parse failure. Never throws.
  const DETACHED_LABEL = "(detached)";
  try {
    const records = [];
    let currentPath = null;
    let currentBranch = null;

    for (const rawLine of output.split("\n")) {
      const line = rawLine.replace(/\r$/, "");

      if (!line) {
        // Blank line: flush current record
        if (currentPath !== null) {
          const label = currentBranch !== null ? currentBranch : DETACHED_LABEL;
          records.push([currentPath, label]);
        }
        currentPath = null;
        currentBranch = null;
        continue;
      }

      const wtM = line.match(/^worktree\s+(.+)$/);
      if (wtM) {
        // Flush pending record without trailing blank
        if (currentPath !== null) {
          const label = currentBranch !== null ? currentBranch : DETACHED_LABEL;
          records.push([currentPath, label]);
          currentBranch = null;
        }
        currentPath = wtM[1].trim();
        continue;
      }

      const brM = line.match(/^branch\s+refs\/heads\/(.+)$/);
      if (brM) {
        currentBranch = brM[1].trim();
      }
    }

    // Flush trailing record (output may not end with blank line)
    if (currentPath !== null) {
      const label = currentBranch !== null ? currentBranch : DETACHED_LABEL;
      records.push([currentPath, label]);
    }

    return records;
  } catch (_) {
    return [];
  }
}

function _enumerateWorktreeRoots(repoRoot) {
  // Mirror Python locator.enumerate_worktree_roots.
  // Returns [[branchLabel, aidDir], ...] with main root always first.
  // Degrades to main-root-only on any git failure (never throws).
  const mainAid = join(repoRoot, ".aid");
  const mainLabel = _detectMainBranchLabel(repoRoot);
  const mainFallback = [[mainLabel, mainAid]];

  const porcelain = _runWorktreeList(repoRoot);
  if (porcelain === null) return mainFallback;

  const parsed = _parseWorktreePorcelain(porcelain);
  if (!parsed || parsed.length === 0) return mainFallback;

  const results = [];
  for (const [wtPath, branchLabel] of parsed) {
    const wtAid = join(wtPath, ".aid");
    results.push([branchLabel, wtAid]);
  }

  return results.length > 0 ? results : mainFallback;
}

// ---------------------------------------------------------------------------
// work-004 Pillar 6: Hierarchy detection + hierarchical work read
// ---------------------------------------------------------------------------

const RE_DELIVERY_DIR = /^delivery-(\d+)$/i;
const RE_TASK_DIR_H = /^(task-\d+)$/i;

function _detectHierarchy(workDir) {
  // Return true if this work has the new per-unit STATE.md hierarchy.
  // Detection: if ANY deliveries/delivery-NNN/tasks/task-NNN/STATE.md exists under workDir.
  // Presence-based, per-work. Never throws.
  try {
    const deliveriesDir = join(workDir, "deliveries");
    let entries;
    try { entries = readdirSync(deliveriesDir); } catch (_) { return false; }
    for (const name of entries) {
      if (!RE_DELIVERY_DIR.test(name)) continue;
      const deliveryPath = join(deliveriesDir, name);
      let isDir = false;
      try { isDir = statSync(deliveryPath).isDirectory(); } catch (_) { isDir = false; }
      if (!isDir) continue;
      const tasksDir = join(deliveryPath, "tasks");
      let tasksDirExists = false;
      try { tasksDirExists = statSync(tasksDir).isDirectory(); } catch (_) { tasksDirExists = false; }
      if (!tasksDirExists) continue;
      let taskEntries;
      try { taskEntries = readdirSync(tasksDir); } catch (_) { continue; }
      for (const tname of taskEntries) {
        if (!RE_TASK_DIR_H.test(tname)) continue;
        const taskStatePath = join(tasksDir, tname, "STATE.md");
        let isFile = false;
        try { isFile = statSync(taskStatePath).isFile(); } catch (_) { isFile = false; }
        if (isFile) return true;
      }
    }
  } catch (_) {
    // pass
  }
  return false;
}

function _detectFlat(workDir) {
  // Return true if this work has the FLATTENED single-delivery layout (feature-001).
  // Mirror reader.py _detect_flat.
  //
  // Detection rule (3-part; identical across all consumers): a work-root
  // BLUEPRINT.md exists AND at least one tasks/task-NNN/DETAIL.md exists
  // directly under the work root AND no `deliveries/` wrapper exists under
  // the work root. This layout has no per-task STATE.md; this check does not
  // look for one.
  //
  // Mirrors the SAME 3-part detection rule as `is_flat_layout()` in
  // canonical/aid/scripts/execute/writeback-state.sh and reader.py's
  // `_detect_flat` (lockstep Python twin).
  //
  // Presence-based, per-work. Mutually exclusive with _detectHierarchy by
  // construction (this function explicitly asserts `deliveries/` absence,
  // not just call-site ordering). Never throws.
  try {
    let blueprintIsFile = false;
    try { blueprintIsFile = statSync(join(workDir, "BLUEPRINT.md")).isFile(); } catch (_) { blueprintIsFile = false; }
    if (!blueprintIsFile) return false;

    let deliveriesIsDir = false;
    try { deliveriesIsDir = statSync(join(workDir, "deliveries")).isDirectory(); } catch (_) { deliveriesIsDir = false; }
    if (deliveriesIsDir) return false;

    const tasksDir = join(workDir, "tasks");
    let tasksDirIsDir = false;
    try { tasksDirIsDir = statSync(tasksDir).isDirectory(); } catch (_) { tasksDirIsDir = false; }
    if (!tasksDirIsDir) return false;

    let entries;
    try { entries = readdirSync(tasksDir); } catch (_) { return false; }
    for (const name of entries) {
      if (!RE_TASK_DIR_H.test(name)) continue;
      const taskPath = join(tasksDir, name);
      let isDir = false;
      try { isDir = statSync(taskPath).isDirectory(); } catch (_) { isDir = false; }
      if (!isDir) continue;
      let detailIsFile = false;
      try { detailIsFile = statSync(join(taskPath, "DETAIL.md")).isFile(); } catch (_) { detailIsFile = false; }
      if (detailIsFile) return true;
    }
  } catch (_) {
    // pass
  }
  return false;
}

// Regexes for hierarchical parsers (mirror parsers.py)
const RE_TASK_STATE_SECTION = /^##\s+Task State\s*$/i;
const RE_TS_STATE   = /^\s*-\s*\*\*State:\*\*\s*(.+)/i;
const RE_TS_REVIEW  = /^\s*-\s*\*\*Review:\*\*\s*(.+)/i;
const RE_TS_ELAPSED = /^\s*-\s*\*\*Elapsed:\*\*\s*(.+)/i;
const RE_TS_NOTES   = /^\s*-\s*\*\*Notes:\*\*\s*(.+)/i;

const RE_DELIVERY_LIFECYCLE_SECTION = /^##\s+Delivery Lifecycle\s*$/i;
const RE_DELIVERY_GATE_SECTION      = /^##\s+Delivery Gate\s*$/i;
const RE_DELIVERY_CROSSPHASE_QA     = /^##\s+Cross-phase Q&A/i;
const RE_DELIVERY_TASKS_STATE_H     = /^##\s+Tasks State\s*$/i;

const RE_DL_STATE        = /^\s*-\s*\*\*State:\*\*\s*(.+)/i;
const RE_DL_UPDATED      = /^\s*-\s*\*\*Updated:\*\*\s*(.+)/i;
const RE_DL_BLOCK_REASON = /^\s*-\s*\*\*Block Reason:\*\*\s*(.+)/i;
const RE_DL_BLOCK_ART    = /^\s*-\s*\*\*Block Artifact:\*\*\s*(.+)/i;

const RE_DG_REVIEWER_TIER = /^\s*-\s*\*\*Reviewer Tier:\*\*\s*(.+)/i;
const RE_DG_GRADE         = /^\s*-\s*\*\*Grade:\*\*\s*(.+)/i;
const RE_DG_TIMESTAMP     = /^\s*-\s*\*\*Timestamp:\*\*\s*(.+)/i;

const DELIVERY_STATE_VALUES = new Set([
  "Pending-Spec", "Specified", "Executing", "Gated", "Done", "Blocked",
]);

function _parseTaskStateMd(text, taskId) {
  // Mirror parsers.py parse_task_state_md.
  // Returns { state, review, elapsed, notes, displayName, parseWarnings }
  const pts = {
    state: TaskStatus.Unknown,
    review: null,
    elapsed: null,
    notes: null,
    displayName: null,
    parseWarnings: [],
  };

  try {
    let inTaskState = false;
    for (const line of text.split("\n")) {
      if (RE_TASK_STATE_SECTION.test(line)) {
        inTaskState = true;
        continue;
      }
      if (RE_SECTION.test(line)) {
        inTaskState = false;
        continue;
      }
      if (!inTaskState) continue;

      let m;
      if ((m = line.match(RE_TS_STATE))) {
        pts.state = parseTaskStatus(m[1].trim());
        continue;
      }
      if ((m = line.match(RE_TS_REVIEW))) {
        const val = m[1].trim();
        pts.review = isNull(val) ? null : val;
        continue;
      }
      if ((m = line.match(RE_TS_ELAPSED))) {
        const val = m[1].trim();
        pts.elapsed = isNull(val) ? null : val;
        continue;
      }
      if ((m = line.match(RE_TS_NOTES))) {
        const val = m[1].trim();
        pts.notes = isNull(val) ? null : val;
        continue;
      }
    }

    // Frontmatter-first override (task-002): applied after the legacy prose
    // scan so frontmatter wins whenever both are present.
    const fm = parseFrontmatterScalars(text);
    let v = fm["state"];
    if (v !== undefined && !isNull(v)) {
      pts.state = parseTaskStatus(v.trim());
    }
    v = fm["review"];
    if (v !== undefined) {
      const vv = v.trim();
      pts.review = isNull(vv) ? null : vv;
    }
    v = fm["elapsed"];
    if (v !== undefined) {
      const vv = v.trim();
      pts.elapsed = isNull(vv) ? null : vv;
    }
    v = fm["notes"];
    if (v !== undefined) {
      const vv = v.trim();
      pts.notes = isNull(vv) ? null : vv;
    }

    // feature-005 (work-017 task-008): display_name is a NEW frontmatter-only
    // key -- no legacy prose bullet form exists, so it is read only here (no
    // body-scan counterpart above, unlike state/review/elapsed/notes).
    v = fm["display_name"];
    if (v !== undefined) {
      const vv = v.trim();
      pts.displayName = isNull(vv) ? null : vv;
    }
  } catch (exc) {
    pts.parseWarnings.push(
      taskId + ": error parsing task STATE.md (" + exc + "); returning best-effort task state"
    );
  }

  return pts;
}

function _parseDeliveryStateMd(text, deliveryId) {
  // Mirror parsers.py parse_delivery_state_md.
  // Returns { deliveryState, updated, blockReason, blockArtifact,
  //           gateGrade, gateReviewerTier, gateTimestamp, pendingInputs, tasks, parseWarnings }
  const pds = {
    deliveryState: null,
    updated: null,
    blockReason: null,
    blockArtifact: null,
    gateGrade: null,
    gateReviewerTier: null,
    gateTimestamp: null,
    pendingInputs: [],
    tasks: [],
    parseWarnings: [],
  };

  try {
    let inLifecycle = false;
    let inGate = false;
    let inCrossphase = false;
    let inTasks = false;
    let tasksHeaderSeen = false;
    let currentQId = null;
    let currentQ = {};

    function flushQ() {
      if (currentQId && (currentQ.state || "").toLowerCase() === "pending") {
        pds.pendingInputs.push({
          question_id: currentQId,
          category: currentQ.category || null,
          impact: currentQ.impact || null,
          context: currentQ.context || null,
          suggested: currentQ.suggested || null,
        });
      }
      currentQId = null;
      currentQ = {};
    }

    for (const line of text.split("\n")) {
      if (RE_DELIVERY_LIFECYCLE_SECTION.test(line)) {
        flushQ();
        inLifecycle = true; inGate = false; inCrossphase = false; inTasks = false;
        continue;
      }
      if (RE_DELIVERY_GATE_SECTION.test(line)) {
        flushQ();
        inLifecycle = false; inGate = true; inCrossphase = false; inTasks = false;
        continue;
      }
      if (RE_DELIVERY_CROSSPHASE_QA.test(line)) {
        flushQ();
        inLifecycle = false; inGate = false; inCrossphase = true; inTasks = false;
        continue;
      }
      if (RE_DELIVERY_TASKS_STATE_H.test(line)) {
        flushQ();
        inLifecycle = false; inGate = false; inCrossphase = false; inTasks = true;
        tasksHeaderSeen = false;
        continue;
      }
      if (RE_SECTION.test(line)) {
        flushQ();
        inLifecycle = false; inGate = false; inCrossphase = false; inTasks = false;
        continue;
      }

      if (inLifecycle) {
        let m;
        if ((m = line.match(RE_DL_STATE))) {
          const raw = m[1].trim();
          if (DELIVERY_STATE_VALUES.has(raw)) {
            pds.deliveryState = raw;
          } else if (!raw.includes("|") && raw) {
            pds.parseWarnings.push(
              deliveryId + ": unknown Delivery Lifecycle State '" + raw + "'"
            );
          }
          continue;
        }
        if ((m = line.match(RE_DL_UPDATED))) {
          const val = m[1].trim();
          pds.updated = isNull(val) ? null : val;
          continue;
        }
        if ((m = line.match(RE_DL_BLOCK_REASON))) {
          const val = m[1].trim();
          pds.blockReason = isNull(val) ? null : val;
          continue;
        }
        if ((m = line.match(RE_DL_BLOCK_ART))) {
          const val = m[1].trim();
          pds.blockArtifact = isNull(val) ? null : val;
          continue;
        }
        continue;
      }

      if (inGate) {
        let m;
        if ((m = line.match(RE_DG_REVIEWER_TIER)) && pds.gateReviewerTier === null) {
          const val = m[1].trim();
          const split = val ? val.split(/\s+/)[0] : null;
          pds.gateReviewerTier = split && !isNull(split) ? split : null;
          continue;
        }
        if ((m = line.match(RE_DG_GRADE)) && pds.gateGrade === null) {
          const val = m[1].trim();
          const split = val ? val.split(/\s+/)[0] : null;
          if (split && !isNull(split) && split.toLowerCase() !== "pending") {
            pds.gateGrade = split;
          }
          continue;
        }
        if ((m = line.match(RE_DG_TIMESTAMP)) && pds.gateTimestamp === null) {
          const val = m[1].trim();
          pds.gateTimestamp = isNull(val) ? null : val;
          continue;
        }
        continue;
      }

      if (inCrossphase) {
        let m;
        if ((m = line.match(RE_QN_HEADER))) {
          flushQ();
          currentQId = m[1];
          currentQ = {};
          continue;
        }
        if (currentQId) {
          // Accept both "State:" (new) and "Status:" (legacy) for Q&A state
          m = line.match(/^\s*-\s*\*\*(?:State|Status):\*\*\s*(.+)/i);
          if (m) { currentQ.state = m[1].trim(); continue; }
          if ((m = line.match(RE_QN_CAT)))     { currentQ.category  = m[1].trim(); continue; }
          if ((m = line.match(RE_QN_IMPACT)))   { currentQ.impact    = m[1].trim(); continue; }
          if ((m = line.match(RE_QN_CONTEXT)))  { currentQ.context   = m[1].trim(); continue; }
          if ((m = line.match(RE_QN_SUGGEST)))  { currentQ.suggested = m[1].trim(); continue; }
        }
        continue;
      }

      if (inTasks) {
        // Parse derived task rollup table (same column layout as work-level Tasks table)
        const stripped = line.trim();
        if (!stripped.startsWith("|")) continue;
        if (RE_TABLE_SEP.test(stripped)) continue;
        const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
        if (cols.length < 2) continue;
        if ((cols[0] === "#" || cols[0] === "") && !tasksHeaderSeen) {
          tasksHeaderSeen = true;
          continue;
        }
        tasksHeaderSeen = true;
        if (cols.some(c => c.includes(NONE_YET))) continue;
        function dcol(idx) {
          if (idx < cols.length) { const v = cols[idx].trim(); return isNull(v) ? null : v; }
          return null;
        }
        const taskId = dcol(1) || dcol(0) || "";
        if (!taskId || taskId === "#") continue;
        const statusStr = dcol(4) || "";
        pds.tasks.push({
          task_id: taskId,
          type: dcol(2) || "",
          wave: dcol(3),
          status: parseTaskStatus(statusStr),
          review_grade: dcol(5),
          elapsed: dcol(6),
          notes: dcol(7),
        });
        continue;
      }
    }

    flushQ();

    // Frontmatter-first override (task-002): applied after the legacy prose
    // scan so frontmatter wins whenever both are present.
    const fm = parseFrontmatterScalars(text);
    let v = fm["delivery_state"];
    if (v !== undefined && !isNull(v)) {
      const raw = v.trim();
      if (DELIVERY_STATE_VALUES.has(raw)) {
        pds.deliveryState = raw;
      } else {
        pds.parseWarnings.push(
          deliveryId + ": unknown frontmatter delivery_state '" + raw + "'"
        );
      }
    }

    v = fm["gate_tier"];
    if (v !== undefined && !isNull(v)) {
      const split = v.trim().split(/\s+/);
      if (split.length && split[0]) pds.gateReviewerTier = split[0];
    }

    v = fm["gate_grade"];
    if (v !== undefined && !isNull(v)) {
      const split = v.trim().split(/\s+/);
      if (split.length && split[0] && split[0].toLowerCase() !== "pending") {
        pds.gateGrade = split[0];
      }
    }

    v = fm["gate_timestamp"];
    if (v !== undefined && !isNull(v)) {
      pds.gateTimestamp = v.trim();
    }
  } catch (exc) {
    pds.parseWarnings.push(
      deliveryId + ": error parsing delivery STATE.md (" + exc + "); returning best-effort delivery state"
    );
  }

  return pds;
}

// ---------------------------------------------------------------------------
// feature-001 (flattened single-delivery layout): ### Tasks lifecycle parser
// Mirror parsers.py parse_tasks_lifecycle_md.
//
// The flat layout has no per-task STATE.md and no per-delivery STATE.md -- the
// promoted ## Delivery Lifecycle / ## Delivery Gate blocks (parsed above via
// _parseDeliveryStateMd, unchanged) plus a ### Tasks lifecycle SUBSECTION live
// directly in the work-root STATE.md. This table REPLACES the per-task
// STATE.md's ## Task State section, but uses a NARROWER column layout (no
// leading # / Type / Wave columns -- type comes from DETAIL.md, wave is the
// synthesized delivery-001 for every task in this layout):
//
//   | Task | State | Review | Elapsed | Notes | Name |
//
// Name (feature-005, work-017 task-008) is the trailing col 5 (0-indexed) --
// a legacy 5-column row (pre-feature-005) yields displayName null.
// ---------------------------------------------------------------------------

const RE_TASKS_LIFECYCLE_SECTION = /^###\s+Tasks lifecycle\s*$/i;
// Any ## or ### heading ends the ### Tasks lifecycle subsection (nested under
// ## Delivery Lifecycle, so a plain ## heading -- e.g. ## Delivery Gate --
// must also close it, not just another ###).
const RE_SECTION_2_OR_3 = /^#{2,3}\s+\S/;

function parseTasksLifecycleMd(text) {
  // Returns [taskIdLowerToState, parseWarnings] where taskIdLowerToState maps
  // task_id.toLowerCase() -> { state, review, elapsed, notes }.
  // Header/separator rows and the _none yet_ placeholder row are skipped.
  // Never throws (NFR7).
  const result = {};
  const warnings = [];

  try {
    let inSection = false;
    let headerSeen = false;

    for (const line of text.split("\n")) {
      if (RE_TASKS_LIFECYCLE_SECTION.test(line)) {
        inSection = true;
        headerSeen = false;
        continue;
      }
      if (inSection && RE_SECTION_2_OR_3.test(line)) {
        inSection = false;
        continue;
      }
      if (!inSection) continue;

      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (RE_TABLE_SEP.test(stripped)) continue;

      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (cols.length < 2) continue;

      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      if (cols.some(c => c.includes(NONE_YET))) continue;

      function fcol(idx) {
        if (idx < cols.length) { const v = cols[idx].trim(); return isNull(v) ? null : v; }
        return null;
      }

      const taskId = fcol(0) || "";
      if (!taskId || taskId.toLowerCase() === "task") continue;

      // feature-005 (work-017 task-008): trailing Name column (col 5); a
      // legacy 5-column row (no Name column authored yet) yields
      // fcol(5) === null -> displayName null -> shortName/taskId fallback.
      result[taskId.toLowerCase()] = {
        state: parseTaskStatus(fcol(1) || ""),
        review: fcol(2),
        elapsed: fcol(3),
        notes: fcol(4),
        displayName: fcol(5),
      };
    }
  } catch (exc) {
    warnings.push("error parsing ### Tasks lifecycle table (" + exc + "); returning best-effort");
  }

  return [result, warnings];
}

function _parseTaskSpecShortName(specText) {
  // Extract the short name from a task-level DETAIL.md.
  // Mirror parsers.py _parse_task_spec_short_name.
  // Reads: '# task-NNN: {Title}' -- returns the title portion, or null.
  try {
    const RE_TITLE = /^#\s+task-\d+\s*:\s*(.+)$/i;
    for (const line of specText.split("\n")) {
      const stripped = line.trim();
      if (!stripped) continue;
      const m = stripped.match(RE_TITLE);
      if (m) {
        const title = m[1].trim().replace(/\.$/, "");
        return title || null;
      }
      break; // first non-blank line didn't match
    }
  } catch (_) {
    // pass
  }
  return null;
}

function _parseTaskSpecType(specText) {
  // Extract the task type from a task-level DETAIL.md.
  // Mirror parsers.py _parse_task_spec_type.
  // Reads: '**Type:** VALUE' line -- returns the type string, or ''.
  try {
    const RE_TYPE = /^\*\*Type:\*\*\s*(.+)/i;
    for (const line of specText.split("\n")) {
      const m = line.trim().match(RE_TYPE);
      if (m) {
        const parts = m[1].trim().split(/\s+/);
        return parts[0] || "";
      }
    }
  } catch (_) {
    // pass
  }
  return "";
}

function _parseDeliverySpecTitle(specText) {
  // Extract the delivery title from a delivery-level BLUEPRINT.md.
  // Mirror parsers.py _parse_delivery_spec_title.
  // Returns the title portion after '# ... delivery-NNN: Title', or null.
  try {
    for (const line of specText.split("\n")) {
      const stripped = line.trim();
      if (!stripped.startsWith("#")) continue;
      const m = stripped.match(/^#+\s+.*delivery-\d+\s*:\s*(.+)$/i);
      if (m) {
        const title = m[1].trim();
        if (title && !title.startsWith("{")) return title;
      }
      break; // only check the first heading line
    }
  } catch (_) {
    // pass
  }
  return null;
}

function _readWorkFlat(workDir, workId) {
  // Mirror reader.py _read_work_flat.
  //
  // Assemble a WorkModel from the FLATTENED single-delivery layout (feature-001).
  //
  // Reads:
  //   - workDir/STATE.md                  -- work-level lifecycle/triage/history, PLUS the
  //                                           promoted ## Delivery Lifecycle (### Tasks
  //                                           lifecycle) / ## Delivery Gate AUTHORED blocks
  //                                           (single writer; no deliveries/ wrapper)
  //   - workDir/tasks/task-NNN/DETAIL.md  -- task type / short-name (no per-task STATE.md --
  //                                           mutable cells come from the work STATE.md
  //                                           ### Tasks lifecycle table)
  //   - workDir/BLUEPRINT.md              -- the single delivery's title (synthesized
  //                                           DeliverableRef name)
  //
  // Synthesizes exactly ONE DeliverableRef for delivery-001 (every task gets
  // wave="delivery-001", delivery=1) -- there is no deliveries/ wrapper to enumerate.
  //
  // pendingInputs is taken from pw.pendingInputs ONLY -- see reader.py docstring for
  // why _parseDeliveryStateMd's own Cross-phase Q&A scan is intentionally NOT unioned
  // here (would double-count the work's single shared ## Cross-phase Q&A section).
  //
  // Returns [workModel, parseWarnings, bytesRead, stateText, stateLabel]. Never raises.
  const stateLabel = ".aid/works/" + workId + "/STATE.md";
  const parseWarnings = [];
  let bytesRead = 0;

  const statePath = join(workDir, "STATE.md");
  let workText = "";
  let workIsFile = false;
  try { workIsFile = statSync(statePath).isFile(); } catch (_) { workIsFile = false; }

  if (!workIsFile) {
    parseWarnings.push(
      workId + ": STATE.md not found (flat mode); work-level lifecycle will be Unknown."
    );
  } else {
    try {
      const raw = readFileBounded(statePath);
      bytesRead += raw.length;
      workText = raw.toString("utf-8");
    } catch (exc) {
      parseWarnings.push(
        workId + ": STATE.md read error (" + exc + "); work-level lifecycle will be Unknown."
      );
    }
  }

  const pw = parseStateText(workText, workId, workDir);
  parseWarnings.push(...pw.parseWarnings);

  const name = slugFromWorkId(workId);
  const workNumber = numberFromWorkId(workId);

  // Identity fields: REQUIREMENTS.md -> SPEC.md fallback (PF-8, unchanged)
  const reqPath = join(workDir, "REQUIREMENTS.md");
  let [reqTitle, reqDescription, reqObjective, reqBytes] = parseRequirementsMd(reqPath);
  bytesRead += reqBytes;

  if (reqTitle === null || reqDescription === null) {
    const specPath = join(workDir, "SPEC.md");
    const [specTitle, specDescription, specH1, specBytes] = parseSpecMd(specPath);
    bytesRead += specBytes;
    if (reqTitle === null) {
      if (specTitle !== null) {
        reqTitle = specTitle;
      } else if (specH1 !== null) {
        reqTitle = specH1;
      }
    }
    if (reqDescription === null && specDescription !== null) {
      reqDescription = specDescription;
    }
  }

  // PF-5: parse PLAN.md execution graph for lane assignments. The flat PLAN.md's
  // top-level ## Execution Graph carries no wave-map fence / "### delivery-NNN
  // Execution Graph" prose header, so this yields an empty map -- lane stays null
  // for every task (harmless; no lane derivation is defined for the flat shape).
  const planPath = join(workDir, "PLAN.md");
  const [taskLaneMap, planBytes] = parseExecutionGraph(planPath);
  bytesRead += planBytes;

  // Parse the promoted ## Delivery Lifecycle / ## Delivery Gate blocks from the SAME
  // work-root STATE.md text via the existing _parseDeliveryStateMd -- it keys on the
  // exact headings regardless of which file they live in. Only pds.deliveryState is
  // used (see function comment for why pds.pendingInputs is not unioned).
  const pds = _parseDeliveryStateMd(workText, "delivery-001");
  parseWarnings.push(...pds.parseWarnings);

  // Parse the promoted ### Tasks lifecycle table (replaces per-task STATE.md)
  const [tasksLifecycle, tlWarnings] = parseTasksLifecycleMd(workText);
  parseWarnings.push(...tlWarnings);

  // -----------------------------------------------------------------------
  // Enumerate tasks/task-NNN/ directly under the work root (no deliveries/
  // wrapper -- the flat layout's single delivery is implicit/synthesized)
  // -----------------------------------------------------------------------
  const allTasks = [];
  const tasksDir = join(workDir, "tasks");
  let taskDirEntries = [];

  try {
    let tasksDirExists = false;
    try { tasksDirExists = statSync(tasksDir).isDirectory(); } catch (_) { tasksDirExists = false; }
    if (tasksDirExists) {
      const entries = readdirSync(tasksDir);
      for (const tname of entries) {
        if (!RE_TASK_DIR_H.test(tname)) continue;
        const tpath = join(tasksDir, tname);
        let isDir = false;
        try { isDir = statSync(tpath).isDirectory(); } catch (_) { isDir = false; }
        if (isDir) taskDirEntries.push([tname, tpath]);
      }
      taskDirEntries.sort((a, b) => a[0].localeCompare(b[0]));
    }
  } catch (exc) {
    parseWarnings.push(workId + ": could not enumerate flat task dirs (" + exc + "); tasks will be empty.");
    taskDirEntries = [];
  }

  for (const [taskIdStr, taskDir] of taskDirEntries) {
    // Read task DETAIL.md for short_name and type (no per-task STATE.md here)
    const taskDetailPath = join(taskDir, "DETAIL.md");
    let shortName = null;
    let taskType = "";
    let taskDetailIsFile = false;
    try { taskDetailIsFile = statSync(taskDetailPath).isFile(); } catch (_) { taskDetailIsFile = false; }

    if (taskDetailIsFile) {
      try {
        const raw = readFileBounded(taskDetailPath);
        bytesRead += raw.length;
        const detailText = raw.toString("utf-8");
        shortName = _parseTaskSpecShortName(detailText);
        taskType = _parseTaskSpecType(detailText);
      } catch (_) {
        // pass
      }
    }

    // Mutable cells from the work-root STATE.md ### Tasks lifecycle table
    const pts = tasksLifecycle[taskIdStr.toLowerCase()] || {
      state: TaskStatus.Unknown, review: null, elapsed: null, notes: null, displayName: null,
    };

    const laneVal = taskLaneMap[taskIdStr.toLowerCase()];
    const lane = laneVal !== undefined ? laneVal : null;

    allTasks.push({
      task_id: taskIdStr,
      type: taskType,
      wave: "delivery-001",
      status: pts.state,
      review_grade: pts.review,
      elapsed: pts.elapsed,
      notes: pts.notes,
      short_name: shortName,
      delivery: 1,
      lane: lane,
      display_name: pts.displayName,
      stop_requested: _taskStopRequested(workDir, workId, taskIdStr),
    });
  }

  // ---- Synthesize the single DeliverableRef for delivery-001 ----
  const blueprintPath = join(workDir, "BLUEPRINT.md");
  let deliveryName = "delivery-001";
  let blueprintIsFile = false;
  try { blueprintIsFile = statSync(blueprintPath).isFile(); } catch (_) { blueprintIsFile = false; }

  if (blueprintIsFile) {
    try {
      const raw = readFileBounded(blueprintPath);
      bytesRead += raw.length;
      const bpText = raw.toString("utf-8");
      const bpName = _parseDeliverySpecTitle(bpText);
      if (bpName) deliveryName = bpName;
    } catch (_) {
      // pass
    }
  }

  const deliverables = [{
    number: 1,
    name: deliveryName,
    task_count: allTasks.length,
    delivery_state: pds.deliveryState,
  }];

  const workModel = _buildWorkModel({
    work_id: workId,
    name,
    lifecycle: pw.lifecycle,
    phase: pw.phase,
    active_skill: pw.activeSkill,
    updated: pw.updated,
    created: pw.created,
    pause_reason: pw.pauseReason,
    block_reason: pw.blockReason,
    block_artifact: pw.blockArtifact,
    tasks: allTasks,
    pending_inputs: pw.pendingInputs,
    source_mode: pw.sourceMode,
    number: workNumber,
    title: reqTitle,
    description: reqDescription,
    objective: reqObjective,
    work_path: pw.workPath || "lite",
    recipe: pw.recipe,
    features: pw.features,
    deliverables: deliverables,
    kind: pw.kind,
    started: pw.started,
    minimum_grade: pw.minimumGrade,
    user_approved: pw.userApproved,
  });

  return [workModel, parseWarnings, bytesRead, workText, stateLabel];
}

function _readWorkHierarchical(workDir, workId) {
  // Mirror reader.py _read_work_hierarchical.
  // Assemble a WorkModel from the per-unit STATE.md hierarchy.
  // Returns [workModel, parseWarnings, bytesRead, stateText, stateLabel].
  const stateLabel = ".aid/works/" + workId + "/STATE.md";
  const parseWarnings = [];
  let bytesRead = 0;

  // Read work-level STATE.md (for Pipeline State / Lifecycle History / Triage)
  const statePath = join(workDir, "STATE.md");
  let workText = "";
  let workIsFile = false;
  try { workIsFile = statSync(statePath).isFile(); } catch (_) { workIsFile = false; }

  if (!workIsFile) {
    parseWarnings.push(
      workId + ": STATE.md not found (hierarchical mode); work-level lifecycle will be Unknown."
    );
  } else {
    try {
      const raw = readFileBounded(statePath);
      bytesRead += raw.length;
      workText = raw.toString("utf-8");
    } catch (exc) {
      parseWarnings.push(
        workId + ": STATE.md read error (" + exc + "); work-level lifecycle will be Unknown."
      );
    }
  }

  // Parse work-level STATE.md for pipeline/lifecycle/triage fields
  // (tasks[] from this parse are IGNORED in hierarchical mode; per-unit task STATE.md files
  // are authoritative)
  const pw = parseStateText(workText, workId, workDir);
  parseWarnings.push(...pw.parseWarnings);

  const name = slugFromWorkId(workId);
  const workNumber = numberFromWorkId(workId);

  // Parse REQUIREMENTS.md / SPEC.md for identity fields
  const reqPath = join(workDir, "REQUIREMENTS.md");
  let [reqTitle, reqDescription, reqObjective, reqBytes] = parseRequirementsMd(reqPath);
  bytesRead += reqBytes;

  if (reqTitle === null || reqDescription === null) {
    const specPath = join(workDir, "SPEC.md");
    const [specTitle, specDescription, specH1, specBytes] = parseSpecMd(specPath);
    bytesRead += specBytes;
    if (reqTitle === null) {
      if (specTitle !== null) {
        reqTitle = specTitle;
      } else if (specH1 !== null) {
        reqTitle = specH1;
      }
    }
    if (reqDescription === null && specDescription !== null) {
      reqDescription = specDescription;
    }
  }

  // Parse PLAN.md for lane assignments
  const planPath = join(workDir, "PLAN.md");
  const [taskLaneMap, planBytes] = parseExecutionGraph(planPath);
  bytesRead += planBytes;

  // Enumerate deliveries and their tasks from the hierarchy
  const allTasks = [];
  const allDeliverables = [];
  const allPendingInputs = [];

  let deliveryEntries = [];
  try {
    const deliveriesDir = join(workDir, "deliveries");
    const entries = readdirSync(deliveriesDir);
    for (const name of entries) {
      if (!RE_DELIVERY_DIR.test(name)) continue;
      const fullPath = join(deliveriesDir, name);
      let isDir = false;
      try { isDir = statSync(fullPath).isDirectory(); } catch (_) { isDir = false; }
      if (isDir) deliveryEntries.push([name, fullPath]);
    }
    deliveryEntries.sort((a, b) => a[0].localeCompare(b[0]));
  } catch (exc) {
    parseWarnings.push(workId + ": could not enumerate delivery dirs (" + exc + "); tasks will be empty.");
    deliveryEntries = [];
  }

  for (const [deliveryId, deliveryDir] of deliveryEntries) {
    const dm = deliveryId.match(RE_DELIVERY_DIR);
    const deliveryNumber = dm ? parseInt(dm[1], 10) : 0;

    // Read delivery-level STATE.md
    const deliveryStatePath = join(deliveryDir, "STATE.md");
    let deliveryStateText = "";
    let deliveryStateIsFile = false;
    try { deliveryStateIsFile = statSync(deliveryStatePath).isFile(); } catch (_) { deliveryStateIsFile = false; }

    if (deliveryStateIsFile) {
      try {
        const raw = readFileBounded(deliveryStatePath);
        bytesRead += raw.length;
        deliveryStateText = raw.toString("utf-8");
      } catch (exc) {
        parseWarnings.push(
          workId + "/" + deliveryId + ": STATE.md read error (" + exc + "); delivery lifecycle will be unknown."
        );
      }
    }

    const pds = _parseDeliveryStateMd(deliveryStateText, deliveryId);
    parseWarnings.push(...pds.parseWarnings);
    allPendingInputs.push(...pds.pendingInputs);

    // Enumerate tasks under this delivery
    const tasksDir = join(deliveryDir, "tasks");
    let taskDirEntries = [];
    let tasksDirExists = false;
    try { tasksDirExists = statSync(tasksDir).isDirectory(); } catch (_) { tasksDirExists = false; }

    if (tasksDirExists) {
      try {
        const entries = readdirSync(tasksDir);
        for (const tname of entries) {
          if (!RE_TASK_DIR_H.test(tname)) continue;
          const tpath = join(tasksDir, tname);
          let isDir = false;
          try { isDir = statSync(tpath).isDirectory(); } catch (_) { isDir = false; }
          if (isDir) taskDirEntries.push([tname, tpath]);
        }
        taskDirEntries.sort((a, b) => a[0].localeCompare(b[0]));
      } catch (exc) {
        parseWarnings.push(workId + "/" + deliveryId + ": could not enumerate task dirs (" + exc + ").");
        taskDirEntries = [];
      }
    }

    let deliveryTaskCount = 0;
    for (const [taskIdStr, taskDir] of taskDirEntries) {
      deliveryTaskCount++;

      // Read task-level STATE.md
      const taskStatePath = join(taskDir, "STATE.md");
      let taskStateText = "";
      let taskStateIsFile = false;
      try { taskStateIsFile = statSync(taskStatePath).isFile(); } catch (_) { taskStateIsFile = false; }

      if (taskStateIsFile) {
        try {
          const raw = readFileBounded(taskStatePath);
          bytesRead += raw.length;
          taskStateText = raw.toString("utf-8");
        } catch (exc) {
          parseWarnings.push(
            workId + "/" + deliveryId + "/" + taskIdStr + ": STATE.md read error (" + exc + "); task state will be Unknown."
          );
        }
      }

      const pts = _parseTaskStateMd(taskStateText, taskIdStr);
      parseWarnings.push(...pts.parseWarnings);

      // Read task DETAIL.md for short_name and type
      const taskSpecPath = join(taskDir, "DETAIL.md");
      let shortName = null;
      let taskType = "";
      let taskSpecIsFile = false;
      try { taskSpecIsFile = statSync(taskSpecPath).isFile(); } catch (_) { taskSpecIsFile = false; }

      if (taskSpecIsFile) {
        try {
          const raw = readFileBounded(taskSpecPath);
          bytesRead += raw.length;
          const specText = raw.toString("utf-8");
          shortName = _parseTaskSpecShortName(specText);
          taskType = _parseTaskSpecType(specText);
        } catch (_) {
          // pass
        }
      }

      // Lane from PLAN.md wave-map
      const laneVal = taskLaneMap[taskIdStr.toLowerCase()];
      const lane = laneVal !== undefined ? laneVal : null;

      allTasks.push({
        task_id: taskIdStr,
        type: taskType,
        wave: deliveryId,        // wave = delivery-NNN in hierarchical works
        status: pts.state,
        review_grade: pts.review,
        elapsed: pts.elapsed,
        notes: pts.notes,
        short_name: shortName,
        delivery: deliveryNumber,
        lane: lane,
        display_name: pts.displayName,
        stop_requested: _taskStopRequested(workDir, workId, taskIdStr),
      });
    }

    // Build DeliverableRef for this delivery
    const deliverySpecPath = join(deliveryDir, "BLUEPRINT.md");
    let deliveryName = deliveryId;
    let deliverySpecIsFile = false;
    try { deliverySpecIsFile = statSync(deliverySpecPath).isFile(); } catch (_) { deliverySpecIsFile = false; }

    if (deliverySpecIsFile) {
      try {
        const raw = readFileBounded(deliverySpecPath);
        bytesRead += raw.length;
        const specText = raw.toString("utf-8");
        const specName = _parseDeliverySpecTitle(specText);
        if (specName) deliveryName = specName;
      } catch (_) {
        // pass
      }
    }

    allDeliverables.push({
      number: deliveryNumber,
      name: deliveryName,
      task_count: deliveryTaskCount,
      delivery_state: pds.deliveryState,
    });
  }

  // Work-level pending_inputs: union of work-level Q&A + per-delivery Q&A
  const unionPendingInputs = [...pw.pendingInputs, ...allPendingInputs];

  const workModel = _buildWorkModel({
    work_id: workId,
    name,
    lifecycle: pw.lifecycle,
    phase: pw.phase,
    active_skill: pw.activeSkill,
    updated: pw.updated,
    created: pw.created,
    pause_reason: pw.pauseReason,
    block_reason: pw.blockReason,
    block_artifact: pw.blockArtifact,
    tasks: allTasks,
    pending_inputs: unionPendingInputs,
    source_mode: pw.sourceMode,
    number: workNumber,
    title: reqTitle,
    description: reqDescription,
    objective: reqObjective,
    // work_path: frontmatter `pipeline.path` first; else "full" -- the
    // hierarchical deliveries/ wrapper only exists for full multi-delivery
    // works, so layout detection is a sound fallback default here (symmetric
    // with _readWorkFlat's `pw.workPath || "lite"` fallback above).
    work_path: pw.workPath || "full",
    recipe: pw.recipe,
    features: pw.features,
    deliverables: allDeliverables,
    kind: pw.kind,
    started: pw.started,
    minimum_grade: pw.minimumGrade,
    user_approved: pw.userApproved,
  });

  return [workModel, parseWarnings, bytesRead, workText, stateLabel];
}

// ---------------------------------------------------------------------------
// work-004 Pillar 5: Same-work reconcile (no winner) -- mirror reader.py
// ---------------------------------------------------------------------------

function _pipelineWinnerSortKey(updated, branchLabel) {
  // Shared Pipeline-State winner-rule sort key (SD-2 / Pillar 5 step 2); mirror
  // reader.py _pipeline_winner_sort_key verbatim.
  //
  // Newest `updated` wins; tie -> branch_label lexical sort, "main" first. This
  // is the SINGLE encoding of the winner rule -- used by BOTH _reconcileSameWork
  // (ranking WorkModel copies) and resolveWorkDir (task-002, WT-1: ranking raw
  // worktree candidates) so the "same winner rule" invariant holds by
  // construction rather than by two independently-maintained copies.
  //
  // Key: [tier, invUpdated, secondary]
  //   tier=0 if updated present, tier=1 if absent.
  //   invUpdated: char-complement so larger (newer) timestamp sorts smaller (ascending).
  //   secondary: [0, ""] for "main", else [1, label].
  const upd = updated || "";
  const label = branchLabel || "";
  const secondary = label === "main" ? [0, ""] : [1, label];
  if (upd) {
    const invUpdated = upd.split("").map(c => {
      const cp = c.charCodeAt(0);
      return String.fromCharCode(0x7F - Math.min(cp, 0x7F));
    }).join("");
    return [0, invUpdated, secondary];
  }
  return [1, "", secondary];
}

function _pipelineWinnerKeyCmp(ka, kb) {
  // Compare two keys returned by _pipelineWinnerSortKey.
  if (ka[0] !== kb[0]) return ka[0] - kb[0];
  if (ka[1] < kb[1]) return -1;
  if (ka[1] > kb[1]) return 1;
  const [sat, sal] = ka[2];
  const [sbt, sbl] = kb[2];
  if (sat !== sbt) return sat - sbt;
  if (sal < sbl) return -1;
  if (sal > sbl) return 1;
  return 0;
}

function _reconcileSameWork(copies) {
  // Merge N WorkModel copies for the same work_id into one reconciled model.
  //
  // copies: array of [WorkModel, stateText, stateLabel] tuples.
  // Returns [reconciledWorkModel, winningStateText, winningStateLabel].
  //
  // Reconcile rules (Pillar 5 / SD-2):
  //   1. Per-task State: most-advanced by SD2_RANK (lower rank wins).
  //   2. Work-level Pipeline State: newest Updated; tie -> branch_label sort, "main" first.
  //   3. Derived views (tasks, pending_inputs, deliverables, features): UNION.
  //   4. Identity fields: from the Pipeline-State winner.
  //   5. source_mode: Normalized if any copy is Normalized.
  //
  // Deterministic and order-independent. Never throws.

  if (copies.length === 1) return copies[0];

  // Step 1: union tasks, picking the most-advanced state per task_id
  const bestTask = {}; // lower-cased task_id -> task model
  for (const [wm] of copies) {
    for (const task of wm.tasks) {
      const tid = task.task_id.toLowerCase();
      if (!(tid in bestTask)) {
        bestTask[tid] = task;
      } else {
        const currentRank = _sd2Rank(bestTask[tid].status);
        const candidateRank = _sd2Rank(task.status);
        if (candidateRank < currentRank) {
          bestTask[tid] = task;
        }
      }
    }
  }
  // Sort deterministically by task_id (input-order-independent)
  const mergedTasks = Object.values(bestTask).sort(
    (a, b) => a.task_id.toLowerCase().localeCompare(b.task_id.toLowerCase())
  );

  // Step 2: pick the Pipeline-State winner by newest Updated timestamp.
  // Tie-break: branch_label lexical sort, "main" sorting first.
  // The sort key itself is the shared _pipelineWinnerSortKey (see its comment
  // above) -- reused verbatim by resolveWorkDir (task-002).
  function _pipelineWinnerKey(entry) {
    const wm = entry[0];
    return _pipelineWinnerSortKey(wm.updated, wm.branch_label);
  }

  function _keyCmp(a, b) {
    return _pipelineWinnerKeyCmp(_pipelineWinnerKey(a), _pipelineWinnerKey(b));
  }

  const sortedCopies = copies.slice().sort(_keyCmp);
  const [winnerWm, winnerText, winnerLabel] = sortedCopies[0];

  // Step 3: union pending_inputs (all copies contribute)
  const seenQIds = new Set();
  const mergedPending = [];
  for (const [wm] of copies) {
    for (const pi of wm.pending_inputs) {
      if (!seenQIds.has(pi.question_id)) {
        seenQIds.add(pi.question_id);
        mergedPending.push(pi);
      }
    }
  }

  // Step 3b: union deliverables (by delivery number; winner's entry wins on duplicates)
  const seenDel = new Set();
  const mergedDeliverables = [];
  for (const dr of winnerWm.deliverables) {
    if (!seenDel.has(dr.number)) {
      seenDel.add(dr.number);
      mergedDeliverables.push(dr);
    }
  }
  for (const [wm] of copies) {
    if (wm === winnerWm) continue;
    for (const dr of wm.deliverables) {
      if (!seenDel.has(dr.number)) {
        seenDel.add(dr.number);
        mergedDeliverables.push(dr);
      }
    }
  }
  mergedDeliverables.sort((a, b) => a.number - b.number);

  // Step 3c: union features (by feature number; winner first)
  const seenFeat = new Set();
  const mergedFeatures = [];
  for (const fr of winnerWm.features) {
    if (!seenFeat.has(fr.number)) {
      seenFeat.add(fr.number);
      mergedFeatures.push(fr);
    }
  }
  for (const [wm] of copies) {
    if (wm === winnerWm) continue;
    for (const fr of wm.features) {
      if (!seenFeat.has(fr.number)) {
        seenFeat.add(fr.number);
        mergedFeatures.push(fr);
      }
    }
  }

  // Step 4 + 5: build reconciled WorkModel from winner's fields + merged views.
  // source_mode: Normalized if any copy is Normalized.
  let mergedSourceMode = winnerWm.source_mode;
  for (const [wm] of copies) {
    if (wm.source_mode === SourceMode.Normalized) {
      mergedSourceMode = SourceMode.Normalized;
      break;
    }
  }

  const reconciled = _buildWorkModel({
    work_id: winnerWm.work_id,
    name: winnerWm.name,
    lifecycle: winnerWm.lifecycle,
    phase: winnerWm.phase,
    active_skill: winnerWm.active_skill,
    updated: winnerWm.updated,
    created: winnerWm.created,
    pause_reason: winnerWm.pause_reason,
    block_reason: winnerWm.block_reason,
    block_artifact: winnerWm.block_artifact,
    tasks: mergedTasks,
    pending_inputs: mergedPending,
    source_mode: mergedSourceMode,
    number: winnerWm.number,
    title: winnerWm.title,
    description: winnerWm.description,
    objective: winnerWm.objective,
    work_path: winnerWm.work_path,
    recipe: winnerWm.recipe,
    features: mergedFeatures,
    deliverables: mergedDeliverables,
    // branch_label: null on a reconciled model (multiple branches contributed)
    branch_label: null,
    kind: winnerWm.kind,
    started: winnerWm.started,
    minimum_grade: winnerWm.minimum_grade,
    user_approved: winnerWm.user_approved,
  });

  return [reconciled, winnerText, winnerLabel];
}

// ---------------------------------------------------------------------------
// Worktree-aware work-directory resolver (WT-1) -- task-002; mirror reader.py
// resolve_work_dir / _peek_work_updated verbatim.
// ---------------------------------------------------------------------------

export function resolveWorkDir(servedRoot, workId) {
  // Resolve workId to the REAL on-disk work directory (worktree-aware; WT-1).
  //
  // Reuses _enumerateWorktreeRoots to walk the served repo's git worktrees,
  // selects every worktree whose <wt>/.aid/works/<workId> exists, and applies
  // the SAME winner rule as _reconcileSameWork step 2 (the shared
  // _pipelineWinnerSortKey: newest `updated` wins; tie -> branch_label lexical,
  // "main" first) -- so the directory returned is the very copy the reader
  // would render for this work_id (a write hits exactly what the reader
  // rendered).
  //
  // Returns null when no worktree of the served repo holds workId (the caller
  // maps this to 404 -- the reader would not have rendered this work either).
  // Inherits the reader's SD-3 degradation (git absent / non-git -> main-root-
  // only) via _enumerateWorktreeRoots, so this resolver can only ever be asked
  // to target a work the reader itself surfaced -- consistency by construction.
  //
  // servedRoot may be the repo root or a path ending in ".aid" (same convention
  // as readRepo). The caller is responsible for validating workId's shape
  // (^work-[0-9]+) before calling -- this function only resolves an
  // already-validated id to a directory; it never reconstructs a served-tree
  // path itself (each candidate directory comes verbatim from
  // _enumerateWorktreeRoots's real on-disk .aid dir).
  //
  // Read-only. Never throws.
  let root = resolve(servedRoot);
  if (basename(root) === ".aid") {
    root = resolve(root, "..");
  }

  const worktreeRoots = _enumerateWorktreeRoots(root);

  // [updated, branchLabel, workDir] for every worktree that actually holds workId.
  const candidates = [];
  for (const [branchLabel, wtAidDir] of worktreeRoots) {
    const workDir = join(wtAidDir, "works", workId);
    let isDir = false;
    try {
      isDir = statSync(workDir).isDirectory();
    } catch (_) {
      isDir = false;
    }
    if (!isDir) continue;
    candidates.push([_peekWorkUpdated(workDir, workId), branchLabel, workDir]);
  }

  if (candidates.length === 0) return null;

  candidates.sort((a, b) =>
    _pipelineWinnerKeyCmp(
      _pipelineWinnerSortKey(a[0], a[1]),
      _pipelineWinnerSortKey(b[0], b[1])
    )
  );
  return candidates[0][2];
}

function _peekWorkUpdated(workDir, workId) {
  // Best-effort read of a work directory's Pipeline State `updated` field.
  // Used only by resolveWorkDir to break ties between worktree copies of the
  // same work_id (the winner rule needs `updated`, not a full WorkModel). Reads
  // workDir/STATE.md -- present regardless of monolithic/flat/hierarchical
  // layout, since all three read the work-root STATE.md for Pipeline State --
  // and parses it with the SAME parseStateText() the always-on read path uses.
  //
  // Returns null on a missing STATE.md or any read/parse failure; never
  // throws. A null result only affects tie-break ordering, never candidate
  // inclusion -- the work_id directory's presence is the sole inclusion test
  // (WT-1).
  const statePath = join(workDir, "STATE.md");
  let isFile = false;
  try {
    isFile = statSync(statePath).isFile();
  } catch (_) {
    isFile = false;
  }
  if (!isFile) return null;
  try {
    const raw = readFileBounded(statePath);
    const text = raw.toString("utf-8");
    return parseStateText(text, workId, workDir).updated;
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Object builders -- FIELD ORDER matches Python dataclasses EXACTLY (DM-3)
// V8 preserves string-key insertion order; order here IS the serialization order.
// ---------------------------------------------------------------------------

function _buildToolInfo(ti) {
  // ToolInfo field order (models.py): manifest_present, aid_version, installed_at, tools_installed
  return {
    manifest_present: ti.manifest_present,
    aid_version: ti.aid_version,
    installed_at: ti.installed_at,
    tools_installed: ti.tools_installed,
  };
}

function _buildKbBaseline(bl) {
  // KbBaseline field order: branch, tip_date
  if (bl === null || bl === undefined) return null;
  return {
    branch:   bl.branch !== undefined ? bl.branch : null,
    tip_date: bl.tip_date !== undefined ? bl.tip_date : null,
  };
}

function _buildKbStateRef(kb) {
  if (kb === null) return null;
  // KbStateRef field order (DM-A3 deterministic, task-064):
  //   retained: summary_approved, last_summary_date, doc_count
  //   new:      status, summary_present, kb_baseline
  // task-042 additions: doc_freshness, suspect_count
  // work-003-state-schema task-002 additions: source_mode, kb_status, kb_grade,
  //   last_kb_review
  return {
    summary_approved:  kb.summary_approved,
    last_summary_date: kb.last_summary_date,
    doc_count:         kb.doc_count,
    status:            kb.status !== undefined ? kb.status : KbStatus.unknown,
    summary_present:   kb.summary_present !== undefined ? kb.summary_present : false,
    kb_baseline:       _buildKbBaseline(kb.kb_baseline),
    doc_freshness:     Array.isArray(kb.doc_freshness) ? kb.doc_freshness.map(_buildDocFreshness) : [],
    suspect_count:     typeof kb.suspect_count === "number" ? kb.suspect_count : 0,
    source_mode:       kb.source_mode !== undefined ? kb.source_mode : SourceMode.Fallback,
    kb_status:         kb.kb_status !== undefined ? kb.kb_status : null,
    kb_grade:          kb.kb_grade !== undefined ? kb.kb_grade : null,
    last_kb_review:    kb.last_kb_review !== undefined ? kb.last_kb_review : null,
  };
}

function _buildDocFreshness(df) {
  // DocFreshness field order: doc, verdict, suspect_sources
  // Twin of Python DocFreshness dataclass (models.py, task-042).
  return {
    doc:             df.doc,
    verdict:         df.verdict,
    suspect_sources: Array.isArray(df.suspect_sources) ? df.suspect_sources : [],
  };
}

function _buildConnectorRef(cr) {
  // ConnectorRef field order: stem, name, connection_type, endpoint,
  // auth_method, secret_reference, summary (feature-007, task-019).
  // Twin of Python ConnectorRef dataclass (models.py).
  return {
    stem:              cr.stem,
    name:              cr.name,
    connection_type:   cr.connection_type,
    endpoint:          cr.endpoint !== undefined ? cr.endpoint : null,
    auth_method:       cr.auth_method !== undefined ? cr.auth_method : null,
    secret_reference:  cr.secret_reference !== undefined ? cr.secret_reference : null,
    summary:           cr.summary !== undefined ? cr.summary : null,
  };
}

function _buildRepoInfo(ri) {
  // RepoInfo field order: project_name, project_description, minimum_grade,
  // aid_dir, kb_state (feature-002, work-017 task-005: two additive keys
  // inserted after project_name; schema_version stays 3), connectors
  // (feature-007, work-017 task-019: additive key inserted AFTER kb_state;
  // schema_version stays 3), external_sources (feature-010, work-017
  // task-021: additive key inserted AFTER connectors; schema_version stays
  // 3). Surfaced ONLY in the DM-1 model -- the DM-2 /api/home entry builder
  // never calls this function.
  return {
    project_name: ri.project_name,
    project_description: ri.project_description !== undefined ? ri.project_description : null,
    minimum_grade: ri.minimum_grade !== undefined ? ri.minimum_grade : null,
    aid_dir: ri.aid_dir,
    kb_state: _buildKbStateRef(ri.kb_state),
    connectors: Array.isArray(ri.connectors) ? ri.connectors.map(_buildConnectorRef) : [],
    external_sources: Array.isArray(ri.external_sources) ? ri.external_sources : [],
  };
}

function _buildPendingInput(pi) {
  // PendingInput field order: question_id, category, impact, context, suggested
  return {
    question_id: pi.question_id,
    category: pi.category,
    impact: pi.impact,
    context: pi.context,
    suggested: pi.suggested,
  };
}

function _buildTaskModel(t) {
  // TaskModel field order: task_id, type, wave, status, review_grade, elapsed, notes,
  //   short_name, delivery, lane  (schema_version 3 fields -- PF-3/PF-5),
  //   display_name (feature-005, work-017 task-008 -- additive, no schema_version bump),
  //   stop_requested (feature-008, work-017 task-029 -- additive derived field, no
  //   schema_version bump)
  return {
    task_id: t.task_id,
    type: t.type,
    wave: t.wave,
    status: t.status,
    review_grade: t.review_grade,
    elapsed: t.elapsed,
    notes: t.notes,
    short_name: t.short_name !== undefined ? t.short_name : null,
    delivery: t.delivery !== undefined ? t.delivery : null,
    lane: t.lane !== undefined ? t.lane : null,
    display_name: t.display_name !== undefined ? t.display_name : null,
    stop_requested: !!t.stop_requested,
  };
}

function _buildFeatureRef(f) {
  // FeatureRef field order: number, name
  return {
    number: f.number,
    name: f.name,
  };
}

function _buildDeliverableRef(d) {
  // DeliverableRef field order: number, name, task_count
  // NOTE: delivery_state (work-004 Pillar 1) is tracked internally but NOT
  // serialized here -- Python server.py _ser_deliverable_ref omits it for parity.
  // Both runtimes emit the same key set until server.py is updated to serialize it.
  return {
    number: d.number,
    name: d.name,
    task_count: d.task_count,
  };
}

function _buildWorkModel(wm) {
  // WorkModel field order: work_id, name, lifecycle, phase, active_skill, updated, created,
  //   pause_reason, block_reason, block_artifact, tasks, pending_inputs, source_mode,
  //   number, title, description, objective, work_path, recipe, features, deliverables,
  //   kind, started, minimum_grade, user_approved (work-003-state-schema task-002)
  //
  // NOTE: branch_label is an internal reconcile field (work-004 Pillar 4) tracked
  // directly on raw objects between readWork() and _reconcileSameWork(); it is NOT
  // included in the serialized output (Python server.py _ser_work omits it for
  // parity -- both runtimes emit the same key set).
  const built = {
    work_id: wm.work_id,
    name: wm.name,
    lifecycle: wm.lifecycle,
    phase: wm.phase,
    active_skill: wm.active_skill,
    updated: wm.updated,
    created: wm.created !== undefined ? wm.created : null,
    pause_reason: wm.pause_reason,
    block_reason: wm.block_reason,
    block_artifact: wm.block_artifact,
    tasks: (wm.tasks || []).map(_buildTaskModel),
    pending_inputs: (wm.pending_inputs || []).map(_buildPendingInput),
    source_mode: wm.source_mode,
    // prototype: work-overview header fields (declared order matches models.py WorkModel)
    number: wm.number !== undefined ? wm.number : null,
    title: wm.title !== undefined ? wm.title : null,
    description: wm.description !== undefined ? wm.description : null,
    objective: wm.objective !== undefined ? wm.objective : null,
    work_path: wm.work_path !== undefined ? wm.work_path : null,
    recipe: wm.recipe !== undefined ? wm.recipe : null,
    features: (wm.features || []).map(_buildFeatureRef),
    deliverables: (wm.deliverables || []).map(_buildDeliverableRef),
    kind: wm.kind !== undefined ? wm.kind : null,
    started: wm.started !== undefined ? wm.started : null,
    minimum_grade: wm.minimum_grade !== undefined ? wm.minimum_grade : null,
    user_approved: wm.user_approved !== undefined ? wm.user_approved : null,
  };
  // Carry branch_label as a non-enumerable property so the reconcile logic can
  // read it (wm.branch_label) without it appearing in JSON.stringify output.
  // This matches Python server.py _ser_work which omits the field entirely.
  Object.defineProperty(built, "branch_label", {
    value: wm.branch_label !== undefined ? wm.branch_label : null,
    writable: true,
    enumerable: false, // excluded from JSON.stringify
    configurable: true,
  });
  return built;
}

function _buildReadMeta(rm) {
  // ReadMeta field order: read_at, work_count, fallback_works, parse_warnings, bytes_read
  return {
    read_at: rm.read_at,
    work_count: rm.work_count,
    fallback_works: rm.fallback_works,
    parse_warnings: rm.parse_warnings,
    bytes_read: rm.bytes_read,
  };
}

function _buildRepoModel({ tool, repo, works, read }) {
  // RepoModel field order: tool, repo, works, read
  return {
    tool: _buildToolInfo(tool),
    repo: _buildRepoInfo(repo),
    works: works.map(_buildWorkModel),
    read: _buildReadMeta(read),
  };
}

// ---------------------------------------------------------------------------
// LC-TR: TaskDetail sub-parsers (feature-008, task-069)
// Detail-only: these run ONLY when detail_task_ids is supplied to readRepoDetail().
// The always-on readRepo() path does NOT call any function below.
// No write / no LLM / no subprocess (NFR2/NFR7).
// ASCII-only source (shipped script posture; coding-standards.md).
// ---------------------------------------------------------------------------

// Section header regexes for forensic sections (twin of parsers.py)
const RE_QUICK_CHECK_FINDINGS = /^##\s+Quick Check Findings\s*$/i;
const RE_DELIVERY_GATES_SECTION = /^##\s+Delivery Gates\s*$/i;
const RE_TASK_BLOCK_HEADER = /^###\s+(task-\S+)\s*$/i;
const RE_DELIVERY_BLOCK_HEADER = /^###\s+(delivery-\d+[^\s]*)\s*$/i;

const RE_FINDINGS_REVIEWER_TIER = /^\s*-\s*\*\*Reviewer Tier:\*\*\s*(.+)/i;
const RE_GATE_GRADE = /^\s*-\s*\*\*Grade:\*\*\s*(.+)/i;
const RE_GATE_REVIEWER_TIER = /^\s*-\s*\*\*Reviewer Tier:\*\*\s*(.+)/i;
const RE_GATE_TIMESTAMP = /^\s*-\s*\*\*Timestamp:\*\*\s*(.+)/i;
const RE_LOCATION = /\{([^}]+:[^}]*)\}/;

// Severity normalization (twin of _parse_severity in parsers.py)
function parseSeverity(tag) {
  const normalized = tag.toUpperCase().trim();
  if (normalized === "[CRITICAL]" || normalized === "[HIGH]") return normalized;
  return "[MINOR]";
}

// Disposition tokens
const DISPOSITION_TOKENS = ["Fixed-on-spot", "Deferred-to-gate"];

// Parse one **Findings:** bullet into a Finding object (twin of _parse_finding_bullet)
function parseFindingBullet(bulletText, reviewerTier) {
  const text = bulletText.trim();
  if (!text) return null;

  // Extract leading bracketed tag: [SEVERITY]
  const tagM = text.match(/^(\[\S+?\])\s+(.*)/);
  let tag, rest;
  if (tagM) {
    tag = tagM[1];
    rest = tagM[2].trim();
  } else {
    // No bracketed tag -- whole text is description with MINOR severity
    return {
      severity: "[MINOR]",
      description: text,
      location: null,
      disposition: null,
      reviewer_tier: reviewerTier,
    };
  }

  const severity = parseSeverity(tag);

  // Split on em-dash (U+2014, canonical) or legacy ' -- ' (ASCII double-dash).
  // The canonical findings template uses U+2014; accept both for back-compat.
  // \u2014 escape used (not literal em-dash) to satisfy the ASCII-only CI gate.
  const segments = rest.split(/ (?:\u2014|--) /);
  const description = segments.length > 0 ? segments[0].trim() : rest;

  // Extract location from any segment: {file:line}
  let location = null;
  for (let i = 1; i < segments.length; i++) {
    const lm = segments[i].match(RE_LOCATION);
    if (lm) {
      location = lm[1].trim();
      break;
    }
  }

  // Extract disposition
  let disposition = null;
  for (const seg of segments) {
    const stripped = seg.trim();
    for (const token of DISPOSITION_TOKENS) {
      if (stripped === token || stripped.startsWith(token)) {
        disposition = token;
        break;
      }
    }
    if (disposition) break;
  }

  return {
    severity: severity,
    description: description,
    location: location,
    disposition: disposition,
    reviewer_tier: reviewerTier,
  };
}

// DR-2: parse ## Quick Check Findings -> ### task-NNN -> **Findings:** bullets
// Twin of parse_quick_check_findings in parsers.py (byte-parity minded)
function parseQuickCheckFindings(stateText, taskId, parseWarnings) {
  const findings = [];
  let inFindingsSection = false;
  let inTaskBlock = false;
  let inFindingsList = false;
  let reviewerTier = null;
  const taskIdLower = taskId.toLowerCase();

  try {
    const lines = stateText.split("\n");
    for (const line of lines) {
      if (RE_QUICK_CHECK_FINDINGS.test(line)) {
        inFindingsSection = true;
        inTaskBlock = false;
        inFindingsList = false;
        reviewerTier = null;
        continue;
      }
      if (inFindingsSection) {
        // A ## section (not ###) ends the quick-check findings section
        if (/^##\s+\S/.test(line) && !/^###/.test(line)) {
          inFindingsSection = false;
          inTaskBlock = false;
          inFindingsList = false;
          continue;
        }
        // ### task-NNN sub-section header
        const tm = line.match(RE_TASK_BLOCK_HEADER);
        if (tm) {
          const blockTaskId = tm[1].toLowerCase();
          inTaskBlock = (blockTaskId === taskIdLower);
          inFindingsList = false;
          reviewerTier = null;
          continue;
        }
        if (inTaskBlock) {
          // **Reviewer Tier:** line
          const rtm = line.match(RE_FINDINGS_REVIEWER_TIER);
          if (rtm) {
            reviewerTier = rtm[1].trim();
            continue;
          }
          // **Findings:** heading line
          if (/^\s*-\s*\*\*Findings:\*\*\s*$/i.test(line)) {
            inFindingsList = true;
            continue;
          }
          if (inFindingsList) {
            const stripped = line.trim();
            if (stripped.startsWith("- [") || stripped.startsWith("-[")) {
              // Parse the bullet (strip the leading '- ')
              const bulletBody = stripped.replace(/^-\s*/, "");
              const f = parseFindingBullet(bulletBody, reviewerTier);
              if (f !== null) findings.push(f);
              continue;
            }
            // Blank line or non-bullet ends findings list
            if (stripped && !stripped.startsWith("-")) {
              inFindingsList = false;
            }
          }
        }
      }
    }
  } catch (exc) {
    parseWarnings.push(
      taskId + ": error parsing ## Quick Check Findings (" + exc + "); " +
      "returning best-effort findings"
    );
  }

  return findings;
}

// DR-3: parse ## Delivery Gates -> ### delivery-NNN for grade/tier/timestamp
// Twin of parse_delivery_gate in parsers.py (byte-parity minded)
//
// Fallback (flat/lite works): a shortcut-produced work promotes a SINGULAR
// "## Delivery Gate" block into the work-root STATE.md instead of the derived
// plural "## Delivery Gates" -> "### delivery-NNN" rollup. When no plural
// section is present at all, the singular block -- if any -- is read as
// delivery-001's gate. Additive: never fires when a plural section exists, so
// full/hierarchical works are unaffected.
function parseDeliveryGate(stateText, deliveryId, parseWarnings) {
  let grade = null;
  let reviewerTier = null;
  let gateTimestamp = null;

  let inGates = false;
  let inDeliveryBlock = false;
  let foundGatesSection = false;
  const deliveryIdLower = deliveryId.toLowerCase();

  try {
    for (const line of stateText.split("\n")) {
      if (RE_DELIVERY_GATES_SECTION.test(line)) {
        inGates = true;
        inDeliveryBlock = false;
        foundGatesSection = true;
        continue;
      }
      if (inGates) {
        // A ## section (not ###) ends the delivery gates section
        if (/^##\s+\S/.test(line) && !/^###/.test(line)) {
          inGates = false;
          inDeliveryBlock = false;
          continue;
        }
        // ### delivery-NNN sub-section header
        const dm = line.match(RE_DELIVERY_BLOCK_HEADER);
        if (dm) {
          const blockDeliveryId = dm[1].toLowerCase();
          inDeliveryBlock = (blockDeliveryId === deliveryIdLower);
          continue;
        }
        if (inDeliveryBlock) {
          const gm = line.match(RE_GATE_GRADE);
          if (gm && grade === null) {
            const raw = gm[1].trim();
            grade = raw ? raw.split(/\s+/)[0] : null;
            continue;
          }
          const rtm = line.match(RE_GATE_REVIEWER_TIER);
          if (rtm && reviewerTier === null) {
            const raw = rtm[1].trim();
            reviewerTier = raw ? raw.split(/\s+/)[0] : null;
            continue;
          }
          const tsm = line.match(RE_GATE_TIMESTAMP);
          if (tsm && gateTimestamp === null) {
            gateTimestamp = tsm[1].trim() || null;
            continue;
          }
          // Once all three are found, stop scanning
          if (grade && reviewerTier && gateTimestamp) break;
        }
      }
    }

    // Fallback: no plural ## Delivery Gates section anywhere in the text --
    // try the singular ## Delivery Gate block (flat/lite promoted layout),
    // treated as delivery-001's gate.
    if (!foundGatesSection && deliveryIdLower === "delivery-001") {
      let inGate = false;
      for (const line of stateText.split("\n")) {
        if (RE_DELIVERY_GATE_SECTION.test(line)) {
          inGate = true;
          continue;
        }
        if (inGate) {
          // Any ## section (not ###) ends the singular gate block
          if (/^##\s+\S/.test(line) && !/^###/.test(line)) {
            inGate = false;
            continue;
          }
          const gm = line.match(RE_GATE_GRADE);
          if (gm && grade === null) {
            const raw = gm[1].trim();
            grade = raw ? raw.split(/\s+/)[0] : null;
            continue;
          }
          const rtm = line.match(RE_GATE_REVIEWER_TIER);
          if (rtm && reviewerTier === null) {
            const raw = rtm[1].trim();
            reviewerTier = raw ? raw.split(/\s+/)[0] : null;
            continue;
          }
          const tsm = line.match(RE_GATE_TIMESTAMP);
          if (tsm && gateTimestamp === null) {
            gateTimestamp = tsm[1].trim() || null;
            continue;
          }
          if (grade && reviewerTier && gateTimestamp) break;
        }
      }
    }
  } catch (exc) {
    parseWarnings.push(
      deliveryId + ": error parsing ## Delivery Gates (" + exc + "); " +
      "returning best-effort gate fields"
    );
  }

  return [grade, reviewerTier, gateTimestamp];
}

// DR-4: parse delivery-NNN-issues.md and filter rows to Source task == task_id
// Twin of parse_deferred_issues in parsers.py (byte-parity minded)
function parseDeferredIssues(issuesPath, taskId, parseWarnings) {
  let isFile = false;
  try { isFile = statSync(issuesPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [];

  let raw;
  try {
    raw = readFileBounded(issuesPath);
  } catch (exc) {
    parseWarnings.push(
      taskId + ": could not read " + basename(issuesPath) + " (" + exc + "); " +
      "deferred_issues will be empty"
    );
    return [];
  }

  const text = raw.toString("utf-8");
  const deferred = [];
  let headerSeen = false;

  try {
    for (const line of text.split("\n")) {
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (RE_TABLE_SEP.test(stripped)) {
        headerSeen = true;
        continue;
      }
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (cols.length < 4) continue;
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      const sourceTask = cols[0].trim();
      const severity = cols[1].trim();
      const description = cols[2].trim();
      const status = cols[3].trim();

      if (sourceTask.toLowerCase() === taskId.toLowerCase()) {
        deferred.push({
          source_task: sourceTask,
          severity: severity || "[HIGH]",
          description: description,
          status: status || "Open",
        });
      }
    }
  } catch (exc) {
    parseWarnings.push(
      taskId + ": error parsing " + basename(issuesPath) + " (" + exc + "); " +
      "returning best-effort deferred issues"
    );
  }

  return deferred;
}

// DR-5: stat log/heartbeat paths for honest DM-4 log inventory
// Twin of parse_log_availability in parsers.py (byte-parity minded)
function parseLogAvailability(aidDir) {
  const serverLogPath = join(aidDir, ".temp", "dashboard.log");
  const heartbeatDir = join(aidDir, ".heartbeat");

  let serverLogPresent = false;
  let heartbeatPresent = false;

  try {
    serverLogPresent = statSync(serverLogPath).isFile();
  } catch (_) {
    serverLogPresent = false;
  }

  try {
    heartbeatPresent = statSync(heartbeatDir).isDirectory();
  } catch (_) {
    heartbeatPresent = false;
  }

  return {
    task_logs: "none",
    server_log_present: serverLogPresent,
    heartbeat_present: heartbeatPresent,
  };
}

// Object builders for TaskDetail sub-model (field order matches Python dataclasses, DM-3)

function _buildFinding(f) {
  // Finding field order: severity, description, location, disposition, reviewer_tier
  return {
    severity: f.severity,
    description: f.description,
    location: f.location !== undefined ? f.location : null,
    disposition: f.disposition !== undefined ? f.disposition : null,
    reviewer_tier: f.reviewer_tier !== undefined ? f.reviewer_tier : null,
  };
}

function _buildDeferredIssue(d) {
  // DeferredIssue field order: source_task, severity, description, status
  return {
    source_task: d.source_task,
    severity: d.severity,
    description: d.description,
    status: d.status,
  };
}

function _buildTaskLedger(l) {
  // TaskLedger field order: delivery_id, grade, reviewer_tier, gate_timestamp, deferred_issues
  return {
    delivery_id: l.delivery_id !== undefined ? l.delivery_id : null,
    grade: l.grade !== undefined ? l.grade : null,
    reviewer_tier: l.reviewer_tier !== undefined ? l.reviewer_tier : null,
    gate_timestamp: l.gate_timestamp !== undefined ? l.gate_timestamp : null,
    deferred_issues: (l.deferred_issues || []).map(_buildDeferredIssue),
  };
}

function _buildRawStateRef(r) {
  // RawStateRef field order: text, byte_len, path
  if (r === null || r === undefined) return null;
  return {
    text: r.text,
    byte_len: r.byte_len,
    path: r.path,
  };
}

function _buildLogAvailability(l) {
  // LogAvailability field order: task_logs, server_log_present, heartbeat_present
  if (l === null || l === undefined) return null;
  return {
    task_logs: l.task_logs,
    server_log_present: l.server_log_present,
    heartbeat_present: l.heartbeat_present,
  };
}

function _buildTaskDetail(d) {
  // TaskDetail field order: task_id, findings, ledger, raw_state, logs
  return {
    task_id: d.task_id,
    findings: (d.findings || []).map(_buildFinding),
    ledger: _buildTaskLedger(d.ledger || {}),
    raw_state: _buildRawStateRef(d.raw_state),
    logs: _buildLogAvailability(d.logs),
  };
}

// ---------------------------------------------------------------------------
// readRepoDetail(root, detailTaskIds) -- LC-TR entry point
// Twin of read_repo_detail in reader.py (byte-parity minded, task-069)
// ---------------------------------------------------------------------------

export function readRepoDetail(root, detailTaskIds) {
  // LC-TR: run full always-on pass then attach TaskDetail for requested task_ids.
  // detailTaskIds: array of composite 'work_id/task_id' strings.
  // Returns { model, details } where details is {} when detailTaskIds is empty.
  //
  // DR-1/DD-3/NFR4: STATE.md bytes are reused from the always-on pass cache.
  // No disk re-read for raw_state. Read-only / no-LLM / no subprocess (NFR2/NFR7).

  // Step 1: run full pass; get STATE.md cache as by-product (zero extra I/O).
  const { model, stateCache } = _readRepoFull(root);

  if (!detailTaskIds || detailTaskIds.length === 0) {
    return { model: model, details: {} };
  }

  // Normalize root
  let resolvedRoot = resolve(root);
  if (basename(resolvedRoot) === ".aid") {
    resolvedRoot = resolve(resolvedRoot, "..");
  }
  const aidDir = join(resolvedRoot, ".aid");

  // Build index of work models by work_id
  const workIndex = {};
  for (const w of model.works) {
    workIndex[w.work_id] = w;
  }

  const details = {};
  const extraWarnings = [];

  for (const compositeKey of detailTaskIds) {
    const slashIdx = compositeKey.indexOf("/");
    if (slashIdx < 0) {
      extraWarnings.push(
        "detail_task_ids: invalid key '" + compositeKey + "' " +
        "(expected 'work_id/task_id'); skipping"
      );
      continue;
    }

    const workId = compositeKey.slice(0, slashIdx);
    const taskId = compositeKey.slice(slashIdx + 1);

    if (!workId || !taskId) {
      extraWarnings.push(
        "detail_task_ids: empty work_id or task_id in '" + compositeKey + "'; skipping"
      );
      continue;
    }

    const taskWarnings = [];

    // DR-1: get STATE.md text from the always-on pass cache (no disk re-read).
    // If work_id was not enumerated (detail for a non-enumerated work), use empty
    // text and add a warning -- never re-read from disk (DR-1/DD-3/NFR4).
    let stateText = "";
    let statePathLabel = ".aid/works/" + workId + "/STATE.md";

    if (stateCache[workId] !== undefined) {
      [stateText, statePathLabel] = stateCache[workId];
    } else {
      taskWarnings.push(
        workId + "/" + taskId + ": work not found in always-on pass; " +
        "STATE.md unavailable; raw_state will be empty"
      );
    }

    // byte_len: length of UTF-8 encoded text (mirrors Python len(text.encode('utf-8')))
    const stateBytes = Buffer.byteLength(stateText, "utf-8");
    const rawState = {
      text: stateText,
      byte_len: stateBytes,
      path: statePathLabel,
    };

    // DR-2: parse ## Quick Check Findings
    const findings = parseQuickCheckFindings(stateText, taskId, taskWarnings);

    // DR-3: resolve delivery_id from work model
    let deliveryId = null;
    const workModel = workIndex[workId];
    if (workModel) {
      for (const task of workModel.tasks) {
        if (task.task_id.toLowerCase() === taskId.toLowerCase()) {
          if (task.delivery !== null && task.delivery !== undefined) {
            deliveryId = "delivery-" + String(task.delivery).padStart(3, "0");
          }
          break;
        }
      }
    }

    // DR-3: parse ## Delivery Gates
    let gateGrade = null;
    let gateReviewerTier = null;
    let gateTimestamp = null;
    if (deliveryId !== null && stateText) {
      [gateGrade, gateReviewerTier, gateTimestamp] = parseDeliveryGate(
        stateText, deliveryId, taskWarnings
      );
    }

    // DR-4: read delivery-NNN-issues.md and filter to Source task == task_id
    let deferredIssues = [];
    if (deliveryId !== null) {
      const issuesPath = join(aidDir, "works", workId, deliveryId + "-issues.md");
      deferredIssues = parseDeferredIssues(issuesPath, taskId, taskWarnings);
    }

    const ledger = {
      delivery_id: deliveryId,
      grade: gateGrade,
      reviewer_tier: gateReviewerTier,
      gate_timestamp: gateTimestamp,
      deferred_issues: deferredIssues,
    };

    // DR-5: stat log/heartbeat paths
    const logs = parseLogAvailability(aidDir);

    details[compositeKey] = _buildTaskDetail({
      task_id: taskId,
      findings: findings,
      ledger: ledger,
      raw_state: rawState,
      logs: logs,
    });

    extraWarnings.push(...taskWarnings);
  }

  // Append LC-TR warnings to model's parse_warnings (best-effort)
  if (extraWarnings.length > 0) {
    model.read.parse_warnings.push(...extraWarnings);
  }

  // Sort details ascending by composite key (parity requirement, DM-2 key-order)
  const sortedDetails = {};
  for (const k of Object.keys(details).sort()) {
    sortedDetails[k] = details[k];
  }

  return { model: model, details: sortedDetails };
}
