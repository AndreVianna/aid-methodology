/**
 * dashboard/server/tests/test_task029_task_stop_resume_ops.mjs
 * "Derived stop_requested reader twin + task.stop/task.resume ops" (task-029,
 * feature-008-execution-control, delivery-005, work-017-cli-improvements) --
 * Node twin.
 *
 * Scope (per task-029 DETAIL.md): the DISPATCH/VALIDATION/MAPPING wiring for
 * the two new OP_TABLE rows only -- mirrors
 * test_task029_task_stop_resume_ops.py's own Python coverage exactly (see
 * that file's module docstring for the full scope note). A real
 * write-control-signal.sh round trip is task-033's job -- deliberately NOT
 * exercised here.
 *
 * server.mjs self-executes on import (parses argv, binds a socket
 * immediately -- no main-guard), so its internal functions (dispatchOp,
 * OP_TABLE, DEFAULT_MAP, mapExitCode, opTaskStopArgv, opTaskResumeArgv, ...)
 * are not importable as-is. This file reuses test_task025_pipeline_delete_
 * ops.mjs's own MAIN_MARKER slice-and-export workaround so every case below
 * drives the ACTUAL production functions -- no reimplementation, no "kept in
 * lockstep by inspection" gap. task.stop/task.resume need NO further
 * substitution (unlike task-017's aid-CLI-backed rows): write-control-
 * signal.sh is dispatched via runWriter, which always spawns bash regardless
 * of host OS (the KI-009 OS-branch lives in runAidCli, never touched here).
 *
 * Covers:
 *   1. OP_TABLE row shape: scope/writer/argSchema/buildArgv/semanticValidate,
 *      no statusMap override, no 'spawn' override, no workIdRe/workIdMaxLen/
 *      workIdInvalidStatus override (opt-in, unlike pipeline.delete).
 *   2. DEFAULT_MAP exit-code mapping (no per-op override): 4/5 -> 422,
 *      2 -> 409, other/unknown -> 500.
 *   3. Argv builders: argv is an array ending in the fixed --action
 *      stop|resume flag; AID_WORK_DIR is ALWAYS the dispatcher-resolved
 *      workDir, never echoed from the body; no AID_STATE_FILE is set.
 *   4. dispatchOp validation order (scope="task": work_id AND task_id both
 *      required), no spawn until every check passes: malformed/absent
 *      target -> 400; work_id present but task_id absent -> 400; malformed
 *      task_id -> 400; invalid work_id shape -> 400 (NOT 422 -- proves no
 *      opt-in to pipeline.delete's stricter override); resolveWorkDir ===
 *      null -> 404; non-empty args -> 422, no spawn.
 *   5. Every OTHER existing task-scoped OP_TABLE row (task.rename,
 *      task.set-notes) is untouched.
 *
 * LOCAL TEST NOTE: no live server.mjs process is spawned and no port is
 * bound anywhere in this file (the slice is imported in-process via a
 * file:// URL) -- every case calls dispatchOp directly, the same "no server
 * spawn" convention test_task025_pipeline_delete_ops.mjs already established
 * -- safe to run locally per the project's port-binding-server-test
 * constraint. No real write-control-signal.sh spawn happens anywhere in this
 * file (task-033's job); scratch directories are plain (non-git) tempdirs,
 * sufficient for resolveWorkDir's own SD-3 main-root-only degradation to
 * exercise every case above pre-spawn.
 *
 * Run: node dashboard/server/tests/test_task029_task_stop_resume_ops.mjs
 *
 * ASCII-only source. Node built-in modules only.
 */

import { readFileSync, mkdirSync, writeFileSync, rmSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath, pathToFileURL } from "url";
import { tmpdir } from "os";
import { randomBytes } from "crypto";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const SERVER_MJS_PATH = join(__dirname, "..", "server.mjs");
const MAIN_MARKER = "// Main: parse args, create server, bind, register SIGTERM";

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

function assertDeepEquals(a, b, msg) {
  assertEquals(JSON.stringify(a), JSON.stringify(b), msg);
}

// ---------------------------------------------------------------------------
// Slice server.mjs before the self-executing 'Main' tail (mirrors
// test_task025_pipeline_delete_ops.mjs's own sliceServerSource()).
// ---------------------------------------------------------------------------
function sliceServerSource() {
  const text = readFileSync(SERVER_MJS_PATH, "utf8");
  const idx = text.indexOf(MAIN_MARKER);
  if (idx === -1) {
    throw new Error(
      "server.mjs 'Main' marker is gone -- this test's slice cut point needs updating"
    );
  }
  return text.slice(0, idx) +
    "\nexport { dispatchOp, OP_TABLE, DEFAULT_MAP, mapExitCode, DEFAULT_FALLBACK, " +
    "resolveWorkDir, opTaskStopArgv, opTaskResumeArgv, validateNoArgs };\n";
}

// Written INTO dashboard/server/ (colocated with reader.mjs), NOT the OS tmp
// dir -- server.mjs's own `import ... from "./reader.mjs"` is relative, so the
// slice must sit beside reader.mjs to resolve (mirrors task-019/021/025's own
// sliceDir placement).
const sliceDir = join(__dirname, "..");
const slicePath = join(sliceDir, `_test_task029_slice_${randomBytes(8).toString("hex")}.mjs`);
writeFileSync(slicePath, sliceServerSource(), "utf8");

let dispatchOp, OP_TABLE, DEFAULT_MAP, mapExitCode, DEFAULT_FALLBACK;
let resolveWorkDir, opTaskStopArgv, opTaskResumeArgv, validateNoArgs;
try {
  const mod = await import(pathToFileURL(slicePath).href);
  ({
    dispatchOp, OP_TABLE, DEFAULT_MAP, mapExitCode, DEFAULT_FALLBACK,
    resolveWorkDir, opTaskStopArgv, opTaskResumeArgv, validateNoArgs,
  } = mod);
} finally {
  rmSync(slicePath, { force: true });
}

// ---------------------------------------------------------------------------
// Scratch repo helper
// ---------------------------------------------------------------------------

function makeTmpRepo() {
  const root = join(tmpdir(), `_test_task029_repo_${randomBytes(8).toString("hex")}`);
  mkdirSync(root, { recursive: true });
  return root;
}

function cleanup(root) {
  rmSync(root, { recursive: true, force: true });
}

function seedWork(root, workId, lifecycle = "Running") {
  const workDir = join(root, ".aid", "works", workId);
  mkdirSync(workDir, { recursive: true });
  writeFileSync(join(workDir, "STATE.md"), `---\nlifecycle: ${lifecycle}\n---\n`, "utf8");
  return workDir;
}

// ===========================================================================
// (1) OP_TABLE row shape
// ===========================================================================

function testTaskStopRowShape() {
  const row = OP_TABLE["task.stop"];
  assertEquals(row.scope, "task", "task.stop scope is 'task'");
  assertEquals(row.writer, "write-control-signal.sh", "task.stop writer is write-control-signal.sh");
  assertDeepEquals(row.argSchema, {}, "task.stop argSchema is empty");
  assert(typeof row.buildArgv === "function", "task.stop buildArgv is a function");
  assert(typeof row.semanticValidate === "function", "task.stop semanticValidate is a function");
  assert(row.semanticValidate === validateNoArgs, "task.stop semanticValidate reuses shared validateNoArgs");
  assertEquals(row.statusMap, null, "task.stop statusMap is null (DEFAULT_MAP used directly)");
  assert(!("spawn" in row), "task.stop has no 'spawn' override (default runWriter/KI-009 path)");
  assert(!("postVerify" in row), "task.stop has no postVerify hook");
  assert(!("resolveTarget" in row), "task.stop has no resolveTarget hook");
  assert(!("preValidate" in row), "task.stop has no preValidate hook");
  assert(!("workIdRe" in row), "task.stop has no workIdRe override (opt-in, unlike pipeline.delete)");
  assert(!("workIdMaxLen" in row), "task.stop has no workIdMaxLen override");
  assert(!("workIdInvalidStatus" in row), "task.stop has no workIdInvalidStatus override");
}

function testTaskResumeRowShape() {
  const row = OP_TABLE["task.resume"];
  assertEquals(row.scope, "task", "task.resume scope is 'task'");
  assertEquals(row.writer, "write-control-signal.sh", "task.resume writer is write-control-signal.sh");
  assertDeepEquals(row.argSchema, {}, "task.resume argSchema is empty");
  assert(typeof row.buildArgv === "function", "task.resume buildArgv is a function");
  assert(typeof row.semanticValidate === "function", "task.resume semanticValidate is a function");
  assert(row.semanticValidate === validateNoArgs, "task.resume semanticValidate reuses shared validateNoArgs");
  assertEquals(row.statusMap, null, "task.resume statusMap is null (DEFAULT_MAP used directly)");
  assert(!("spawn" in row), "task.resume has no 'spawn' override");
}

// ===========================================================================
// (2) DEFAULT_MAP exit-code mapping (no per-op override)
// ===========================================================================

function testStatusMapping() {
  for (const op of ["task.stop", "task.resume"]) {
    const row = OP_TABLE[op];
    for (const exitCode of [4, 5]) {
      const [status, errorClass] = mapExitCode(exitCode, row.statusMap, row.statusMapDefault);
      assertEquals(status, 422, op + " exit " + exitCode + " maps to 422");
      assertEquals(errorClass, "invalid-value", op + " exit " + exitCode + " maps to invalid-value");
    }
    const [busyStatus, busyClass] = mapExitCode(2, row.statusMap, row.statusMapDefault);
    assertEquals(busyStatus, 409, op + " exit 2 maps to 409");
    assertEquals(busyClass, "busy", op + " exit 2 maps to busy");

    const fallback = mapExitCode(42, row.statusMap, row.statusMapDefault);
    assertDeepEquals(fallback, DEFAULT_FALLBACK, op + " unmapped exit code falls back to DEFAULT_FALLBACK");
  }
}

// ===========================================================================
// (3) Argv builders
// ===========================================================================

function testTaskStopArgvBuilder() {
  const [argv, env] = opTaskStopArgv("/some/resolved/workdir", "/repo/root", { task_id: "008" }, {});
  assertDeepEquals(argv, ["--task-id", "008", "--action", "stop"], "task.stop argv ends in --action stop");
  assertDeepEquals(env, { AID_WORK_DIR: "/some/resolved/workdir" }, "task.stop env is { AID_WORK_DIR: workDir }");
  assert(!("AID_STATE_FILE" in env), "task.stop env has no AID_STATE_FILE (unlike task.rename)");

  const [argv2, env2] = opTaskStopArgv(
    "/real/resolved/dir", "/repo/root",
    { task_id: "008", AID_WORK_DIR: "/evil/path", work_dir: "/evil/path" },
    { AID_WORK_DIR: "/evil/path" },
  );
  assertEquals(env2.AID_WORK_DIR, "/real/resolved/dir", "AID_WORK_DIR never taken from target/args body");
  assert(!argv2.includes("/evil/path"), "argv never carries a body-supplied path");
  assert(!Object.values(env2).includes("/evil/path"), "env never carries a body-supplied path");
}

function testTaskResumeArgvBuilder() {
  const [argv, env] = opTaskResumeArgv("/some/resolved/workdir", "/repo/root", { task_id: "008" }, {});
  assertDeepEquals(argv, ["--task-id", "008", "--action", "resume"], "task.resume argv ends in --action resume");
  assertDeepEquals(env, { AID_WORK_DIR: "/some/resolved/workdir" }, "task.resume env is { AID_WORK_DIR: workDir }");
  assert(!("AID_STATE_FILE" in env), "task.resume env has no AID_STATE_FILE");

  const [argv2] = opTaskResumeArgv("/wd", "/repo/root", { task_id: "008" }, { foo: "bar" });
  assert(!argv2.includes("foo") && !argv2.includes("bar"), "args is accepted but unused by the builder");
}

// ===========================================================================
// (4) dispatchOp validation order -- no spawn until every check passes
// ===========================================================================

function testMissingTargetKeyReturns400() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(OP_TABLE, { op: "task.stop" }, root);
    assertEquals(status, 400, "missing target key -> 400");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testWorkIdPresentTaskIdAbsentReturns400() {
  const root = makeTmpRepo();
  try {
    seedWork(root, "work-042-sample");
    const [status, body] = dispatchOp(OP_TABLE, { op: "task.stop", target: { work_id: "work-042-sample" } }, root);
    assertEquals(status, 400, "work_id present but task_id absent -> 400");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testMalformedTaskIdReturns400() {
  const root = makeTmpRepo();
  try {
    seedWork(root, "work-042-sample");
    const [status, body] = dispatchOp(
      OP_TABLE,
      { op: "task.stop", target: { work_id: "work-042-sample", task_id: "not-numeric" } },
      root,
    );
    assertEquals(status, 400, "malformed task_id -> 400");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testInvalidWorkIdShapeReturns400NotBadRequest() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(
      OP_TABLE,
      { op: "task.stop", target: { work_id: "not-a-work-id", task_id: "001" } },
      root,
    );
    assertEquals(status, 400, "invalid work_id shape -> 400 (NOT 422 -- no opt-in to pipeline.delete's stricter override)");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testValidShapeNotFoundReturns404NoSpawn() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(
      OP_TABLE,
      { op: "task.stop", target: { work_id: "work-999-nonexistent", task_id: "001" } },
      root,
    );
    assertEquals(status, 404, "valid shape, not found -> 404");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "not-found", "error class is not-found");
  } finally {
    cleanup(root);
  }
}

function testNonEmptyArgsReturns422AfterResolveNoSpawn() {
  const root = makeTmpRepo();
  const row = OP_TABLE["task.stop"];
  const hadSpawn = "spawn" in row;
  const originalSpawn = row.spawn;
  const calls = [];
  row.spawn = (rowArg, argv, envOverrides) => {
    calls.push([argv, envOverrides]);
    return [0, ""];
  };
  try {
    seedWork(root, "work-042-sample");
    const [status, body] = dispatchOp(
      OP_TABLE,
      { op: "task.stop", target: { work_id: "work-042-sample", task_id: "001" }, args: { lifecycle: "Completed" } },
      root,
    );
    assertEquals(status, 422, "non-empty args -> 422 (evaluated after step-6 checks)");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "invalid-value", "error class is invalid-value");
    assertEquals(calls.length, 0, "no spawn happened -- semanticValidate rejected before dispatch");
  } finally {
    if (hadSpawn) {
      row.spawn = originalSpawn;
    } else {
      delete row.spawn;
    }
    cleanup(root);
  }
}

function testEmptyArgsObjectReachesSpawnStageWithCorrectArgv() {
  const root = makeTmpRepo();
  const row = OP_TABLE["task.stop"];
  const hadSpawn = "spawn" in row;
  const originalSpawn = row.spawn;
  const calls = [];
  row.spawn = (rowArg, argv, envOverrides) => {
    calls.push([argv, envOverrides]);
    return [0, ""];
  };
  try {
    seedWork(root, "work-042-sample");
    const [status, body] = dispatchOp(
      OP_TABLE, { op: "task.stop", target: { work_id: "work-042-sample", task_id: "001" }, args: {} }, root,
    );
    assertEquals(status, 200, "empty args + stubbed spawn -> 200 (dispatch-level checks all passed)");
    assertDeepEquals(
      JSON.parse(Buffer.from(body).toString("utf-8")), { ok: true, op: "task.stop" },
      "ok envelope",
    );
    assertEquals(calls.length, 1, "spawn stub invoked exactly once (no real writer spawned)");
    assertDeepEquals(calls[0][0], ["--task-id", "001", "--action", "stop"], "argv built by the dispatcher matches opTaskStopArgv");
    // Computed via the SAME resolveWorkDir() the dispatcher itself calls
    // (never a hand-built path string) -- avoids a Windows 8.3-short-path
    // mismatch some hosts introduce via realpath-style resolution.
    // forward-slashed: the builder posix-ifies AID_WORK_DIR for the bash writer
    // (toPosixArg(String(workDir))); backslash native form would break on Windows.
    const expectedWorkDir = String(resolveWorkDir(root, "work-042-sample")).replace(/\\/g, "/");
    assertDeepEquals(calls[0][1], { AID_WORK_DIR: expectedWorkDir }, "env built by the dispatcher matches opTaskStopArgv");
  } finally {
    if (hadSpawn) {
      row.spawn = originalSpawn;
    } else {
      delete row.spawn;
    }
    cleanup(root);
  }
}

function testTaskResumeReachesSpawnStageWithCorrectArgv() {
  const root = makeTmpRepo();
  const row = OP_TABLE["task.resume"];
  const hadSpawn = "spawn" in row;
  const originalSpawn = row.spawn;
  const calls = [];
  row.spawn = (rowArg, argv, envOverrides) => {
    calls.push([argv, envOverrides]);
    return [0, ""];
  };
  try {
    seedWork(root, "work-043-sample");
    const [status, body] = dispatchOp(
      OP_TABLE, { op: "task.resume", target: { work_id: "work-043-sample", task_id: "001" }, args: {} }, root,
    );
    assertEquals(status, 200, "empty args + stubbed spawn -> 200");
    assertDeepEquals(
      JSON.parse(Buffer.from(body).toString("utf-8")), { ok: true, op: "task.resume" },
      "ok envelope",
    );
    assertEquals(calls.length, 1, "spawn stub invoked exactly once");
    assertDeepEquals(calls[0][0], ["--task-id", "001", "--action", "resume"], "argv built by the dispatcher matches opTaskResumeArgv");
    // forward-slashed: the builder posix-ifies AID_WORK_DIR for the bash writer.
    const expectedWorkDir = String(resolveWorkDir(root, "work-043-sample")).replace(/\\/g, "/");
    assertDeepEquals(calls[0][1], { AID_WORK_DIR: expectedWorkDir }, "env built by the dispatcher matches opTaskResumeArgv");
  } finally {
    if (hadSpawn) {
      row.spawn = originalSpawn;
    } else {
      delete row.spawn;
    }
    cleanup(root);
  }
}

// ===========================================================================
// (5) Existing task-scoped rows are UNCHANGED
// ===========================================================================

function testTaskRenameRowUntouched() {
  const row = OP_TABLE["task.rename"];
  assertEquals(row.scope, "task", "task.rename scope still 'task' (unchanged)");
  assertEquals(row.writer, "writeback-state.sh", "task.rename writer still writeback-state.sh (unchanged)");
  assertEquals(row.statusMap, null, "task.rename statusMap still null (unchanged)");
}

function testTaskSetNotesRowUntouched() {
  const row = OP_TABLE["task.set-notes"];
  assertEquals(row.scope, "task", "task.set-notes scope still 'task' (unchanged)");
  assertEquals(row.writer, "writeback-state.sh", "task.set-notes writer still writeback-state.sh (unchanged)");
  assertEquals(row.statusMap, null, "task.set-notes statusMap still null (unchanged)");
}

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------

testTaskStopRowShape();
testTaskResumeRowShape();
testStatusMapping();
testTaskStopArgvBuilder();
testTaskResumeArgvBuilder();
testMissingTargetKeyReturns400();
testWorkIdPresentTaskIdAbsentReturns400();
testMalformedTaskIdReturns400();
testInvalidWorkIdShapeReturns400NotBadRequest();
testValidShapeNotFoundReturns404NoSpawn();
testNonEmptyArgsReturns422AfterResolveNoSpawn();
testEmptyArgsObjectReachesSpawnStageWithCorrectArgv();
testTaskResumeReachesSpawnStageWithCorrectArgv();
testTaskRenameRowUntouched();
testTaskSetNotesRowUntouched();

process.stdout.write(`\n${passed} passed, ${failed} failed\n`);
process.exit(failed > 0 ? 1 : 0);
