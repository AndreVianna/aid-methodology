/**
 * dashboard/server/tests/test_reader_task069.mjs
 * Unit tests for LC-TR TaskDetail sub-parsers in reader.mjs (task-069).
 *
 * Tests:
 *   - parseQuickCheckFindings (DR-2): ## Quick Check Findings -> ### task-NNN
 *   - parseDeliveryGate (DR-3): ## Delivery Gates -> ### delivery-NNN
 *   - parseDeferredIssues (DR-4): delivery-NNN-issues.md filtered to Source task
 *   - parseLogAvailability (DR-5): stat dashboard.log + .heartbeat/
 *   - readRepoDetail (LC-TR): detail-only, always-on path untouched
 *   - Torn-read tolerance: never throws (NFR7)
 *   - Clean task: empty findings (not an error)
 *   - No TaskDetail on bare readRepo() call (NFR4, DD-1)
 *
 * Run: node dashboard/server/tests/test_reader_task069.mjs
 *
 * ASCII-only source. Node built-in modules only.
 */

import {
  mkdirSync, writeFileSync, rmSync, statSync, existsSync,
} from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { tmpdir } from "os";
import { readRepo, readRepoDetail } from "../reader.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

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
  const ok = JSON.stringify(a) === JSON.stringify(b);
  if (ok) {
    process.stdout.write("  PASS: " + msg + "\n");
    passed++;
  } else {
    process.stderr.write("  FAIL: " + msg + " -- got " + JSON.stringify(a) + " expected " + JSON.stringify(b) + "\n");
    failed++;
  }
}

// ---------------------------------------------------------------------------
// Helpers: we import the internals by testing them via readRepoDetail,
// but we also test lower-level functions by re-importing them with dynamic import.
// Since the functions are not all exported, we test via integration paths
// and also expose internal functions for direct test through a test helper.
// ---------------------------------------------------------------------------

// To test internal functions, we import reader.mjs and use readRepoDetail as the
// integration point. For unit-level tests we construct minimal STATE.md fixtures.

// Fixture content (mirroring test_task069_detail_parser.py)
const FINDINGS_STATE_MD = [
  "## Pipeline Status",
  "",
  "- **Lifecycle:** Running",
  "- **Phase:** Execute",
  "- **Active Skill:** aid-execute",
  "- **Updated:** 2026-06-13T00:00:00Z",
  "",
  "## Tasks Status",
  "",
  "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |",
  "|---|------|------|------|--------|--------|---------|-------|",
  "| 1 | task-001 | IMPLEMENT | delivery-009 | Done | A+ | 1h | -- |",
  "| 2 | task-002 | IMPLEMENT | delivery-009 | Done | -- | 2h | -- |",
  "",
  "## Delivery Gates",
  "",
  "### delivery-009",
  "",
  "- **Reviewer Tier:** Large (complexity score 14)",
  "- **Grade:** A+ (cycle 1)",
  "- **Timestamp:** 2026-06-13T10:00:00Z",
  "",
  "## Quick Check Findings",
  "",
  "> One block per task.",
  "",
  "### task-001",
  "",
  "- **Reviewer Tier:** Small (quick check always uses Small tier)",
  "- **Findings:**",
  "  - [CRITICAL] Missing null check — {reader.py:42} — Fixed-on-spot",
  "  - [HIGH] Stale comment in derivation — {derivation.py:88} — Deferred-to-gate",
  "",
  "### task-002",
  "",
  "- **Reviewer Tier:** Small (quick check always uses Small tier)",
  "- **Findings:**",
  "",
  "## Lifecycle History",
  "",
  "| Date | Phase Transition / Gate | Grade | Notes |",
  "|------|------------------------|-------|-------|",
  "| 2026-06-10 | Work created | -- | Initial scaffold |",
].join("\n");

const ISSUES_MD = [
  "# Deferred [HIGH] Issues",
  "",
  "| Source task | Severity | Description | Status |",
  "|-------------|----------|-------------|--------|",
  "| --- | --- | --- | --- |",
  "| task-001 | [HIGH] | Stale comment in derivation | Open |",
  "| task-001 | [HIGH] | Another deferred issue | Resolved |",
  "| task-002 | [HIGH] | Task-002 issue | Open |",
].join("\n");

// ---------------------------------------------------------------------------
// Fixture builder
// ---------------------------------------------------------------------------

function makeTempDir() {
  const base = join(tmpdir(), "aid-test-069-" + Date.now());
  mkdirSync(base, { recursive: true });
  return base;
}

function makeAidFixture(base) {
  const aid = join(base, ".aid");
  mkdirSync(aid, { recursive: true });
  writeFileSync(join(aid, ".aid-manifest.json"), JSON.stringify({
    manifest_version: 1,
    aid_version: "1.0.0-test",
    installed_at: "2026-06-10T00:00:00Z",
    tools: {},
  }), "utf8");
  writeFileSync(join(aid, "settings.yml"), "project:\n  name: test-detail\n", "utf8");
  return aid;
}

function makeWorkDir(aid, workId, stateContent) {
  const wdir = join(aid, workId);
  mkdirSync(wdir, { recursive: true });
  writeFileSync(join(wdir, "STATE.md"), stateContent, "utf8");
  return wdir;
}

// ---------------------------------------------------------------------------
// [1] DR-2: Quick Check Findings integration tests
// ---------------------------------------------------------------------------

process.stdout.write("\n[1] DR-2: parseQuickCheckFindings (via readRepoDetail)\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    const wdir = makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);
    writeFileSync(join(wdir, "delivery-009-issues.md"), ISSUES_MD, "utf8");

    const { model, details } = readRepoDetail(base, ["work-001-test/task-001"]);

    assert("work-001-test/task-001" in details, "DR-2: task-001 key present");

    const td = details["work-001-test/task-001"];
    assert(td.findings.length === 2, "DR-2: task-001 has 2 findings");
    assertEquals(td.findings[0].severity, "[CRITICAL]", "DR-2: first finding is [CRITICAL]");
    assertEquals(td.findings[1].severity, "[HIGH]", "DR-2: second finding is [HIGH]");
    assertEquals(td.findings[0].location, "reader.py:42", "DR-2: first finding location");
    assertEquals(td.findings[0].disposition, "Fixed-on-spot", "DR-2: first finding disposition");
    // reviewer_tier is verbatim from the **Reviewer Tier:** line (may include parenthetical)
    assert(
      typeof td.findings[0].reviewer_tier === "string" && td.findings[0].reviewer_tier.includes("Small"),
      "DR-2: first finding reviewer_tier contains 'Small'"
    );
    assertEquals(td.findings[1].location, "derivation.py:88", "DR-2: second finding location");
    assertEquals(td.findings[1].disposition, "Deferred-to-gate", "DR-2: second finding disposition");

    // Clean task: task-002 has empty Findings
    const { details: details2 } = readRepoDetail(base, ["work-001-test/task-002"]);
    const td2 = details2["work-001-test/task-002"];
    assertEquals(td2.findings.length, 0, "DR-2: task-002 (clean task) has 0 findings");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [2] DR-2: Unknown/lower severity -> [MINOR] neutral, never throws
// ---------------------------------------------------------------------------

process.stdout.write("\n[2] DR-2: Severity normalization\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    const stateText = [
      "## Pipeline Status",
      "",
      "- **Lifecycle:** Running",
      "- **Phase:** Execute",
      "- **Active Skill:** --",
      "- **Updated:** 2026-06-13T00:00:00Z",
      "",
      "## Tasks Status",
      "",
      "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |",
      "|---|------|------|------|--------|--------|---------|-------|",
      "| 1 | task-001 | IMPLEMENT | -- | Done | -- | 1h | -- |",
      "",
      "## Quick Check Findings",
      "",
      "### task-001",
      "",
      "- **Reviewer Tier:** Small",
      "- **Findings:**",
      "  - [LOW] Cosmetic issue -- {file.py:10} -- Fixed-on-spot",
      "  - [MINOR] Another minor -- no location",
      "  - [UNKNOWN_TAG] Some issue",
    ].join("\n");
    makeWorkDir(aid, "work-001-test", stateText);

    const { details } = readRepoDetail(base, ["work-001-test/task-001"]);
    const td = details["work-001-test/task-001"];
    assert(td.findings.length >= 1, "DR-2 severity: at least 1 finding parsed");
    for (const f of td.findings) {
      assert(
        f.severity === "[CRITICAL]" || f.severity === "[HIGH]" || f.severity === "[MINOR]",
        "DR-2 severity: all severities are CRITICAL/HIGH/MINOR (never throws)"
      );
    }
    // [LOW] -> [MINOR]
    assertEquals(td.findings[0].severity, "[MINOR]", "DR-2 severity: [LOW] normalized to [MINOR]");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [3] DR-3: parseDeliveryGate integration tests
// ---------------------------------------------------------------------------

process.stdout.write("\n[3] DR-3: parseDeliveryGate (via readRepoDetail)\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    const wdir = makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);
    writeFileSync(join(wdir, "delivery-009-issues.md"), ISSUES_MD, "utf8");

    const { details } = readRepoDetail(base, ["work-001-test/task-001"]);
    const td = details["work-001-test/task-001"];

    assertEquals(td.ledger.delivery_id, "delivery-009", "DR-3: delivery_id resolved");
    assertEquals(td.ledger.grade, "A+", "DR-3: grade is A+ (verbatim)");
    assertEquals(td.ledger.reviewer_tier, "Large", "DR-3: reviewer_tier is Large (first word)");
    assertEquals(td.ledger.gate_timestamp, "2026-06-13T10:00:00Z", "DR-3: gate_timestamp");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [4] DR-3: Unassociated task -> delivery_id=null, grade=null
// ---------------------------------------------------------------------------

process.stdout.write("\n[4] DR-3: Unassociated task (no delivery wave)\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    const stateNoDelivery = [
      "## Pipeline Status",
      "",
      "- **Lifecycle:** Running",
      "- **Phase:** Execute",
      "- **Active Skill:** --",
      "- **Updated:** 2026-06-13T00:00:00Z",
      "",
      "## Tasks Status",
      "",
      "| # | Task | Type | Wave | Status | Review | Elapsed | Notes |",
      "|---|------|------|------|--------|--------|---------|-------|",
      "| 1 | task-010 | IMPLEMENT | -- | In Progress | -- | -- | -- |",
      "",
      "## Delivery Gates",
      "",
      "## Quick Check Findings",
      "",
      "### task-010",
      "",
      "- **Reviewer Tier:** Small",
      "- **Findings:**",
      "",
      "## Lifecycle History",
      "",
      "| Date | Phase Transition / Gate | Grade | Notes |",
      "|------|------------------------|-------|-------|",
      "| 2026-06-10 | Work created | -- | Initial |",
    ].join("\n");
    makeWorkDir(aid, "work-002-nodelivery", stateNoDelivery);

    const { details } = readRepoDetail(base, ["work-002-nodelivery/task-010"]);
    const td = details["work-002-nodelivery/task-010"];

    assertEquals(td.ledger.delivery_id, null, "DR-3: unassociated task delivery_id=null");
    assertEquals(td.ledger.grade, null, "DR-3: unassociated task grade=null");
    assertEquals(td.ledger.deferred_issues.length, 0, "DR-3: unassociated task deferred_issues=[]");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [5] DR-4: parseDeferredIssues integration tests
// ---------------------------------------------------------------------------

process.stdout.write("\n[5] DR-4: parseDeferredIssues (via readRepoDetail)\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    const wdir = makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);
    writeFileSync(join(wdir, "delivery-009-issues.md"), ISSUES_MD, "utf8");

    const { details } = readRepoDetail(base, ["work-001-test/task-001"]);
    const td = details["work-001-test/task-001"];

    assertEquals(td.ledger.deferred_issues.length, 2, "DR-4: 2 deferred issues for task-001");
    for (const issue of td.ledger.deferred_issues) {
      assertEquals(issue.source_task, "task-001", "DR-4: deferred issue source_task == task-001");
    }
    assertEquals(td.ledger.deferred_issues[0].status, "Open", "DR-4: first issue status Open");
    assertEquals(td.ledger.deferred_issues[1].status, "Resolved", "DR-4: second issue status Resolved");

    // task-002 should only get its own deferred issues (1 row in ISSUES_MD)
    const { details: details2 } = readRepoDetail(base, ["work-001-test/task-002"]);
    const td2 = details2["work-001-test/task-002"];
    assertEquals(td2.ledger.deferred_issues.length, 1, "DR-4: 1 deferred issue for task-002");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [6] DR-4: Absent issues file -> deferred_issues=[]
// ---------------------------------------------------------------------------

process.stdout.write("\n[6] DR-4: Absent issues file\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    // Write STATE.md with delivery-009 wave but NO issues file
    makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);

    const { details } = readRepoDetail(base, ["work-001-test/task-001"]);
    const td = details["work-001-test/task-001"];

    assertEquals(td.ledger.deferred_issues.length, 0, "DR-4: absent issues file -> deferred_issues=[]");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [7] DR-1: raw_state reuse (text/byte_len/path)
// ---------------------------------------------------------------------------

process.stdout.write("\n[7] DR-1: raw_state fields\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    const wdir = makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);

    const { details } = readRepoDetail(base, ["work-001-test/task-001"]);
    const td = details["work-001-test/task-001"];

    assert(td.raw_state !== null, "DR-1: raw_state is not null");
    assert(typeof td.raw_state.text === "string", "DR-1: raw_state.text is string");
    assert(td.raw_state.text.includes("## Pipeline Status"), "DR-1: raw_state.text contains Pipeline Status");
    assert(td.raw_state.byte_len > 0, "DR-1: raw_state.byte_len > 0");
    assert(typeof td.raw_state.path === "string", "DR-1: raw_state.path is string");
    assert(td.raw_state.path.includes("STATE.md"), "DR-1: raw_state.path contains STATE.md");

    // byte_len should equal Buffer.byteLength(text, 'utf-8')
    const { Buffer: BufClass } = await import("buffer");
    const expectedByteLen = BufClass.byteLength(td.raw_state.text, "utf-8");
    assertEquals(td.raw_state.byte_len, expectedByteLen, "DR-1: byte_len == Buffer.byteLength(text, utf-8)");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [8] DR-5: LogAvailability fields
// ---------------------------------------------------------------------------

process.stdout.write("\n[8] DR-5: parseLogAvailability (via readRepoDetail)\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);

    const { details } = readRepoDetail(base, ["work-001-test/task-001"]);
    const td = details["work-001-test/task-001"];

    assert(td.logs !== null, "DR-5: logs is not null");
    assertEquals(td.logs.task_logs, "none", "DR-5: task_logs is always 'none'");
    assert(typeof td.logs.server_log_present === "boolean", "DR-5: server_log_present is boolean");
    assert(typeof td.logs.heartbeat_present === "boolean", "DR-5: heartbeat_present is boolean");
    // server_log_present should be false (no .temp/dashboard.log in test fixture)
    assertEquals(td.logs.server_log_present, false, "DR-5: server_log_present=false (no log file)");
    assertEquals(td.logs.heartbeat_present, false, "DR-5: heartbeat_present=false (no .heartbeat/)");

    // Now create the log file and heartbeat dir
    const tempDir = join(aid, ".temp");
    mkdirSync(tempDir, { recursive: true });
    writeFileSync(join(tempDir, "dashboard.log"), "server log line\n", "utf8");
    const hbDir = join(aid, ".heartbeat");
    mkdirSync(hbDir, { recursive: true });

    const { details: details2 } = readRepoDetail(base, ["work-001-test/task-001"]);
    const td2 = details2["work-001-test/task-001"];
    assertEquals(td2.logs.server_log_present, true, "DR-5: server_log_present=true (log file present)");
    assertEquals(td2.logs.heartbeat_present, true, "DR-5: heartbeat_present=true (.heartbeat/ present)");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [9] NFR4/DD-1: No TaskDetail on bare readRepo() call
// ---------------------------------------------------------------------------

process.stdout.write("\n[9] NFR4/DD-1: Always-on readRepo() produces no TaskDetail\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);

    const model = readRepo(base);

    assert(model.works.length === 1, "NFR4: works list populated");
    const work = model.works[0];
    assert(work.tasks.length === 2, "NFR4: tasks list populated");

    // TaskModel fields must NOT include TaskDetail fields
    for (const task of work.tasks) {
      assert(!("findings" in task), "NFR4: TaskModel has no 'findings' field");
      assert(!("ledger" in task), "NFR4: TaskModel has no 'ledger' field");
      assert(!("raw_state" in task), "NFR4: TaskModel has no 'raw_state' field");
      assert(!("logs" in task), "NFR4: TaskModel has no 'logs' field");
    }
    assert(!("details" in model), "NFR4: RepoModel has no 'details' field");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [10] Empty / null detail_task_ids -> details={}
// ---------------------------------------------------------------------------

process.stdout.write("\n[10] NFR4/DD-1: Empty detail_task_ids -> details={}\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);

    const { details: d1 } = readRepoDetail(base, []);
    assertEquals(JSON.stringify(d1), "{}", "DD-1: empty array -> details={}");

    const { details: d2 } = readRepoDetail(base, null);
    assertEquals(JSON.stringify(d2), "{}", "DD-1: null -> details={}");

    const { details: d3 } = readRepoDetail(base);
    assertEquals(JSON.stringify(d3), "{}", "DD-1: no arg -> details={}");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [11] Invalid composite key -> warning, no crash
// ---------------------------------------------------------------------------

process.stdout.write("\n[11] Torn-read / invalid key tolerance\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);

    const { model, details } = readRepoDetail(base, ["invalid-no-slash"]);
    assertEquals(JSON.stringify(details), "{}", "tolerance: invalid key -> details={}");
    const warnings = model.read.parse_warnings;
    assert(
      warnings.some(w => w.includes("invalid key")),
      "tolerance: invalid key adds parse_warning"
    );
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [12] Absent work dir -> raw_state.text='', parse_warning
// ---------------------------------------------------------------------------

process.stdout.write("\n[12] Absent work dir -> raw_state empty, warning\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    // work-999-nonexistent does not exist

    const { model, details } = readRepoDetail(base, ["work-999-nonexistent/task-001"]);
    const td = details["work-999-nonexistent/task-001"];

    assert(td !== undefined, "absent-work: TaskDetail still produced (best-effort)");
    assertEquals(td.raw_state.text, "", "absent-work: raw_state.text='' for missing STATE.md");
    assert(
      model.read.parse_warnings.some(w => w.includes("STATE.md")),
      "absent-work: parse_warning about STATE.md"
    );
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [13] Multiple tasks: independent, sorted ascending
// ---------------------------------------------------------------------------

process.stdout.write("\n[13] Multiple task_ids: independent results, sorted keys\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    const wdir = makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);
    writeFileSync(join(wdir, "delivery-009-issues.md"), ISSUES_MD, "utf8");

    const { details } = readRepoDetail(base, [
      "work-001-test/task-002",
      "work-001-test/task-001",
    ]);

    const keys = Object.keys(details);
    const sorted = [...keys].sort();
    assertEquals(keys, sorted, "multi: details keys are sorted ascending");
    assert("work-001-test/task-001" in details, "multi: task-001 present");
    assert("work-001-test/task-002" in details, "multi: task-002 present");
    assertEquals(details["work-001-test/task-001"].findings.length, 2, "multi: task-001 has 2 findings");
    assertEquals(details["work-001-test/task-002"].findings.length, 0, "multi: task-002 has 0 findings");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [14] TaskDetail object shape (field order matches Python dataclass)
// ---------------------------------------------------------------------------

process.stdout.write("\n[14] TaskDetail field shape\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    const wdir = makeWorkDir(aid, "work-001-test", FINDINGS_STATE_MD);
    writeFileSync(join(wdir, "delivery-009-issues.md"), ISSUES_MD, "utf8");

    const { details } = readRepoDetail(base, ["work-001-test/task-001"]);
    const td = details["work-001-test/task-001"];

    // TaskDetail fields
    assert("task_id" in td, "shape: task_id field");
    assert("findings" in td, "shape: findings field");
    assert("ledger" in td, "shape: ledger field");
    assert("raw_state" in td, "shape: raw_state field");
    assert("logs" in td, "shape: logs field");

    // Finding fields
    const f = td.findings[0];
    assert("severity" in f, "shape: Finding.severity");
    assert("description" in f, "shape: Finding.description");
    assert("location" in f, "shape: Finding.location");
    assert("disposition" in f, "shape: Finding.disposition");
    assert("reviewer_tier" in f, "shape: Finding.reviewer_tier");

    // TaskLedger fields
    const l = td.ledger;
    assert("delivery_id" in l, "shape: TaskLedger.delivery_id");
    assert("grade" in l, "shape: TaskLedger.grade");
    assert("reviewer_tier" in l, "shape: TaskLedger.reviewer_tier");
    assert("gate_timestamp" in l, "shape: TaskLedger.gate_timestamp");
    assert("deferred_issues" in l, "shape: TaskLedger.deferred_issues");

    // DeferredIssue fields
    if (l.deferred_issues.length > 0) {
      const di = l.deferred_issues[0];
      assert("source_task" in di, "shape: DeferredIssue.source_task");
      assert("severity" in di, "shape: DeferredIssue.severity");
      assert("description" in di, "shape: DeferredIssue.description");
      assert("status" in di, "shape: DeferredIssue.status");
    }

    // RawStateRef fields
    const rs = td.raw_state;
    assert("text" in rs, "shape: RawStateRef.text");
    assert("byte_len" in rs, "shape: RawStateRef.byte_len");
    assert("path" in rs, "shape: RawStateRef.path");

    // LogAvailability fields
    const la = td.logs;
    assert("task_logs" in la, "shape: LogAvailability.task_logs");
    assert("server_log_present" in la, "shape: LogAvailability.server_log_present");
    assert("heartbeat_present" in la, "shape: LogAvailability.heartbeat_present");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// [15] Torn-read tolerance: no exception on malformed STATE.md
// ---------------------------------------------------------------------------

process.stdout.write("\n[15] Torn-read tolerance: malformed STATE.md never throws\n");

{
  const base = makeTempDir();
  try {
    const aid = makeAidFixture(base);
    // Write a completely malformed STATE.md
    const malformed = [
      "## Quick Check Findings",
      "### task-001",
      "- **Reviewer Tier:** Small",
      "- **Findings:**",
      "  - [HIGH] Truncated --",
    ].join("\n");
    makeWorkDir(aid, "work-001-test", malformed);

    let error = null;
    try {
      const { details } = readRepoDetail(base, ["work-001-test/task-001"]);
      assert(details !== undefined, "torn-read: result is defined (no exception)");
    } catch (exc) {
      error = exc;
    }
    assertEquals(error, null, "torn-read: no exception thrown on malformed STATE.md");
  } finally {
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

process.stdout.write("\n--- Result: " + passed + " passed, " + failed + " failed ---\n");

if (failed > 0) {
  process.exit(1);
}
