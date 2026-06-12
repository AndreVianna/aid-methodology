/**
 * dashboard/server/reader.mjs
 * Node runtime reader: port of dashboard/reader/ (Python) for the Node thin server.
 *
 * Exports readRepo(root) -> model object (same shape as Python RepoModel serialized).
 *
 * Read-only by construction: uses only fs.readFileSync / fs.readdirSync / fs.statSync.
 * No fs.write* / fs.appendFile / fs.unlink / fs.open for write anywhere in this file.
 * No agent/LLM import. No third-party deps. Node built-in modules only.
 *
 * Source MUST be ASCII-only (shipped script posture; coding-standards.md).
 * UTF-8 payload content is emitted at runtime, not in source.
 */

import { readFileSync, readdirSync, statSync, existsSync } from "fs";
import { resolve, join, basename } from "path";

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

const Phase = {
  Interview: "Interview",
  Specify: "Specify",
  Plan: "Plan",
  Detail: "Detail",
  Execute: "Execute",
  Deploy: "Deploy",
  Monitor: "Monitor",
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

// ---------------------------------------------------------------------------
// Null-value sentinels (mirrors parsers.py _NULL_SENTINELS)
// ---------------------------------------------------------------------------

const NULL_SENTINELS = new Set(["-", "--", "\u2014", ""]);

function isNull(val) {
  return NULL_SENTINELS.has(val);
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
  "Interview": Phase.Interview,
  "Specify": Phase.Specify,
  "Plan": Phase.Plan,
  "Detail": Phase.Detail,
  "Execute": Phase.Execute,
  "Deploy": Phase.Deploy,
  "Monitor": Phase.Monitor,
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

const WORK_RE = /^work-[0-9]+-/;

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
  let entries;
  try {
    entries = readdirSync(aidDir);
  } catch (_) {
    return [];
  }

  const result = [];
  for (const name of entries) {
    if (!WORK_RE.test(name)) continue;
    const fullPath = join(aidDir, name);
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
      raw = readFileSync(manifestPath);
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
      raw = readFileSync(versionPath);
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

function parseProjectName(settingsPath) {
  if (!existsSync(settingsPath)) return ["", 0];
  let raw;
  try {
    raw = readFileSync(settingsPath);
  } catch (_) {
    return ["", 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  let inProject = false;
  for (const line of text.split("\n")) {
    const stripped = line.trim();
    if (stripped === "project:" || stripped.startsWith("project: ")) {
      inProject = true;
      continue;
    }
    if (inProject) {
      if (line.length > 0 && !/^\s/.test(line) && !line.startsWith("#") && line.includes(":")) {
        const key = line.split(":")[0].trim();
        if (key !== "name") {
          if (!/^\s/.test(line)) break;
        }
      }
      const m = line.match(/^\s+name:\s+(.+)/);
      if (m) {
        // PF-6: strip inline YAML comment
        let val = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        return [val, bytesRead];
      }
    }
  }
  return ["", bytesRead];
}

function parseKbSummaryApproval(text) {
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
        return [approved, date];
      }
    }
  }
  return [false, null];
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

  const statePath = join(kbDir, "STATE.md");
  if (existsSync(statePath)) {
    let raw;
    try {
      raw = readFileSync(statePath);
      bytesRead += raw.length;
      const stateText = raw.toString("utf-8");
      [summaryApproved, lastSummaryDate] = parseKbSummaryApproval(stateText);
    } catch (_) {
      // ignore
    }
  }

  const readmePath = join(kbDir, "README.md");
  if (existsSync(readmePath)) {
    let raw;
    try {
      raw = readFileSync(readmePath);
      bytesRead += raw.length;
      const readmeText = raw.toString("utf-8");
      docCount = parseKbDocCount(readmeText);
    } catch (_) {
      // ignore
    }
  }

  return [
    { summary_approved: summaryApproved, last_summary_date: lastSummaryDate, doc_count: docCount },
    bytesRead,
  ];
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
    raw = readFileSync(reqPath);
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
      title = m[1].trim();
      continue;
    }
    m = line.match(RE_DESC);
    if (m && description === null) {
      description = m[1].trim();
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
    raw = readFileSync(taskPath);
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
    raw = readFileSync(planPath);
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

const RE_PIPELINE_STATUS = /^##\s+Pipeline Status\s*$/i;
const RE_TASKS_STATUS = /^##\s+Tasks Status\s*$/i;
const RE_CROSSPHASE_QA = /^##\s+Cross-phase Q&A/i;
const RE_TRIAGE = /^##\s+Triage\s*$/i;
const RE_FEATURES_STATUS = /^##\s+Features Status\s*$/i;
// RE_PLAN_DELIVERIES already declared in derivation helpers above (reused here)
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

  let inPipelineStatus = false;
  let pipelineStatusFound = false;
  let inTasks = false;
  let inCrossphase = false;
  let inTriage = false;
  let inFeatures = false;
  let inDeliveries = false;
  let tasksHeaderSeen = false;
  let featuresHeaderSeen = false;
  let deliveriesHeaderSeen = false;

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
        if ((m = line.match(RE_QN_STATUS))) {
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
  }

  flushQ();

  if (pipelineStatusFound) {
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
    return _buildRepoModel({
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
  }

  // Step 2: LEVEL-0 ToolInfo
  const [toolInfo, br0] = parseToolInfo(loc.manifestPath, loc.versionPath);
  bytesRead += br0;

  // Step 3: LEVEL-1 RepoInfo
  let [projectName, br1] = parseProjectName(loc.settingsPath);
  bytesRead += br1;
  if (!projectName) {
    projectName = basename(resolvedRoot);
  }

  const [kbState, br2] = parseKbState(loc.kbDir);
  bytesRead += br2;

  const repoInfo = { project_name: projectName, aid_dir: loc.aidDir, kb_state: kbState };

  // Steps 4-5: ENUMERATE + PER WORK
  const works = [];
  const fallbackWorks = [];

  for (const workDir of loc.workDirs) {
    const workId = basename(workDir);
    const [workModel, workWarnings, workBytes] = readWork(workDir, workId);
    works.push(workModel);
    parseWarnings.push(...workWarnings);
    bytesRead += workBytes;
    if (workModel.source_mode !== SourceMode.Normalized) {
      fallbackWorks.push(workId);
    }
  }

  // Step 6: ASSEMBLE
  return _buildRepoModel({
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
}

function readWork(workDir, workId) {
  const statePath = join(workDir, "STATE.md");
  const parseWarnings = [];
  let bytesRead = 0;

  let isFile = false;
  try {
    isFile = statSync(statePath).isFile();
  } catch (_) {
    isFile = false;
  }

  if (!isFile) {
    parseWarnings.push(`${workId}: STATE.md not found; returning minimal WorkModel.`);
    return [_minimalWorkModel(workId), parseWarnings, 0];
  }

  let text;
  let raw;
  try {
    raw = readFileSync(statePath);
    bytesRead = raw.length;
    text = raw.toString("utf-8");
  } catch (exc) {
    parseWarnings.push(`${workId}: STATE.md read error (${exc}); returning minimal WorkModel.`);
    return [_minimalWorkModel(workId), parseWarnings, 0];
  }

  const pw = parseStateText(text, workId, workDir);
  parseWarnings.push(...pw.parseWarnings);

  const name = slugFromWorkId(workId);

  // Prototype: parse work number from folder prefix (work-NNN-...)
  const workNumber = numberFromWorkId(workId);

  // Prototype: parse REQUIREMENTS.md for identity fields
  const reqPath = join(workDir, "REQUIREMENTS.md");
  const [reqTitle, reqDescription, reqObjective, reqBytes] = parseRequirementsMd(reqPath);
  bytesRead += reqBytes;

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
    });
  });

  const workModel = _buildWorkModel({
    work_id: workId,
    name,
    lifecycle: pw.lifecycle,
    phase: pw.phase,
    active_skill: pw.activeSkill,
    updated: pw.updated,
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
  });

  return [workModel, parseWarnings, bytesRead];
}

function _minimalWorkModel(workId) {
  return _buildWorkModel({
    work_id: workId,
    name: slugFromWorkId(workId),
    lifecycle: Lifecycle.Unknown,
    phase: null,
    active_skill: null,
    updated: null,
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

function _buildKbStateRef(kb) {
  if (kb === null) return null;
  // KbStateRef field order: summary_approved, last_summary_date, doc_count
  return {
    summary_approved: kb.summary_approved,
    last_summary_date: kb.last_summary_date,
    doc_count: kb.doc_count,
  };
}

function _buildRepoInfo(ri) {
  // RepoInfo field order: project_name, aid_dir, kb_state
  return {
    project_name: ri.project_name,
    aid_dir: ri.aid_dir,
    kb_state: _buildKbStateRef(ri.kb_state),
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
  //   short_name, delivery, lane  (schema_version 3 fields -- PF-3/PF-5)
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
  return {
    number: d.number,
    name: d.name,
    task_count: d.task_count,
  };
}

function _buildWorkModel(wm) {
  // WorkModel field order: work_id, name, lifecycle, phase, active_skill, updated,
  //   pause_reason, block_reason, block_artifact, tasks, pending_inputs, source_mode,
  //   number, title, description, objective, work_path, recipe, features, deliverables
  return {
    work_id: wm.work_id,
    name: wm.name,
    lifecycle: wm.lifecycle,
    phase: wm.phase,
    active_skill: wm.active_skill,
    updated: wm.updated,
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
  };
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
