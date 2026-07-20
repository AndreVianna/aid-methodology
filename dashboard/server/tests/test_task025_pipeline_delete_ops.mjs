/**
 * dashboard/server/tests/test_task025_pipeline_delete_ops.mjs
 * "pipeline.delete op row + exit-7->409 map" (task-025,
 * feature-009-pipeline-delete, delivery-004, work-017-cli-improvements) --
 * Node twin.
 *
 * Scope (per task-025 DETAIL.md): the DISPATCH/VALIDATION/MAPPING wiring
 * only -- the OP_TABLE row, the statusMap exit-7->409 override (preserving
 * every DEFAULT_MAP row), the argv-builder, and the server-side validation
 * order (work_id shape/length -> resolveWorkDir -> args-empty) BEFORE any
 * spawn. Full end-to-end delete round-trips through the real
 * delete-pipeline.sh writer (git worktree fixtures, guard trips, actual
 * removal) are task-027's job -- deliberately NOT exercised here.
 *
 * server.mjs self-executes on import (parses argv, binds a socket
 * immediately -- no main-guard), so its internal functions (dispatchOp,
 * OP_TABLE, DEFAULT_MAP, mapExitCode, RE_WORK_ID_SHAPE, opPipelineDeleteArgv,
 * ...) are not importable as-is. This file reuses
 * test_task017_registry_tooling_round_trips.py's `_sliced_server_mjs_source`
 * cut point (the same MAIN_MARKER comment, "// Main: parse args, create
 * server, bind, register SIGTERM") to export the needed bindings from a
 * slice of the REAL source, so every case below drives the ACTUAL
 * production functions -- no reimplementation, no "kept in lockstep by
 * inspection" gap. pipeline.delete needs NO further substitution (unlike
 * task-017's aid-CLI-backed rows): delete-pipeline.sh is dispatched via
 * runWriter, which always spawns bash regardless of host OS (the KI-009
 * OS-branch lives in runAidCli, never touched here).
 *
 * Covers:
 *   1. OP_TABLE row shape: scope/writer/argSchema/buildArgv/semanticValidate,
 *      no 'spawn' override, workIdRe/workIdMaxLen/workIdInvalidStatus present.
 *   2. statusMap (OP-SM): exit 7 -> 409 'pipeline-active', DEFAULT_MAP rows
 *      preserved verbatim (dict-equality + mapExitCode spot checks).
 *   3. Argv builder: argv is an array, AID_REPO_ROOT is ALWAYS server-built,
 *      never echoed from the body; workDir never forwarded.
 *   4. dispatchOp validation order (Feature Flow steps 6-7), no spawn until
 *      every check passes: malformed/absent target -> 400; a present-string
 *      work_id failing the FULL anchored shape/length -> 422 (including a
 *      value that would PASS every other pipeline/task-scoped op's looser
 *      prefix-only check); resolveWorkDir === null -> 404; non-empty args
 *      (evaluated AFTER work_id/resolve) -> 422, no spawn.
 *   5. Every OTHER existing pipeline/task-scoped OP_TABLE row is untouched --
 *      the new workIdRe/workIdMaxLen/workIdInvalidStatus fields are opt-in.
 *
 * LOCAL TEST NOTE: no live server.mjs process is spawned and no port is
 * bound anywhere in this file (the slice is imported in-process via a
 * file:// URL) -- every case calls dispatchOp directly, the same "no server
 * spawn" convention test_task019_connector_ops.mjs / test_task021_
 * external_source_ops.mjs already established -- safe to run locally per the
 * project's port-binding-server-test constraint. No real delete-pipeline.sh
 * spawn happens anywhere in this file (task-027's job); scratch directories
 * are plain (non-git) tempdirs, sufficient for resolveWorkDir's own SD-3
 * main-root-only degradation to exercise every case above pre-spawn.
 *
 * Run: node dashboard/server/tests/test_task025_pipeline_delete_ops.mjs
 *
 * ASCII-only source. Node built-in modules only.
 */

import { readFileSync, mkdirSync, writeFileSync, rmSync, existsSync } from "fs";
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
// test_task019_connector_ops.mjs / test_task021_external_source_ops.mjs's
// own sliceServerSource()).
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
    "RE_WORK_ID_SHAPE, RE_WORK_ID_STRICT, opPipelineDeleteArgv, validateNoArgs };\n";
}

// Written INTO dashboard/server/ (colocated with reader.mjs), NOT the OS tmp
// dir -- server.mjs's own `import ... from "./reader.mjs"` is relative, so the
// slice must sit beside reader.mjs to resolve (mirrors task-019/021's own
// sliceDir placement).
const sliceDir = join(__dirname, "..");
const slicePath = join(sliceDir, `_test_task025_slice_${randomBytes(8).toString("hex")}.mjs`);
writeFileSync(slicePath, sliceServerSource(), "utf8");

let dispatchOp, OP_TABLE, DEFAULT_MAP, mapExitCode, DEFAULT_FALLBACK;
let RE_WORK_ID_SHAPE, RE_WORK_ID_STRICT, opPipelineDeleteArgv, validateNoArgs;
try {
  const mod = await import(pathToFileURL(slicePath).href);
  ({
    dispatchOp, OP_TABLE, DEFAULT_MAP, mapExitCode, DEFAULT_FALLBACK,
    RE_WORK_ID_SHAPE, RE_WORK_ID_STRICT, opPipelineDeleteArgv, validateNoArgs,
  } = mod);
} finally {
  rmSync(slicePath, { force: true });
}

// ---------------------------------------------------------------------------
// Scratch repo helper
// ---------------------------------------------------------------------------

function makeTmpRepo() {
  const root = join(tmpdir(), `_test_task025_repo_${randomBytes(8).toString("hex")}`);
  mkdirSync(root, { recursive: true });
  return root;
}

function cleanup(root) {
  rmSync(root, { recursive: true, force: true });
}

function seedWork(root, workId, lifecycle = "Completed") {
  const workDir = join(root, ".aid", "works", workId);
  mkdirSync(workDir, { recursive: true });
  writeFileSync(join(workDir, "STATE.md"), `---\nlifecycle: ${lifecycle}\n---\n`, "utf8");
  return workDir;
}

// ===========================================================================
// (1) OP_TABLE row shape
// ===========================================================================

function testOpTableRowShape() {
  const row = OP_TABLE["pipeline.delete"];
  assertEquals(row.scope, "pipeline", "pipeline.delete scope is 'pipeline'");
  assertEquals(row.writer, "delete-pipeline.sh", "pipeline.delete writer is delete-pipeline.sh");
  assertDeepEquals(row.argSchema, {}, "pipeline.delete argSchema is empty");
  assert(typeof row.buildArgv === "function", "pipeline.delete buildArgv is a function");
  assert(typeof row.semanticValidate === "function", "pipeline.delete semanticValidate is a function");
  assert(row.semanticValidate === validateNoArgs, "pipeline.delete semanticValidate reuses shared validateNoArgs");
  assert(!("spawn" in row), "pipeline.delete has no 'spawn' override (default runWriter/KI-009 path)");
  assert(!("postVerify" in row), "pipeline.delete has no postVerify hook");
  assert(!("resolveTarget" in row), "pipeline.delete has no resolveTarget hook");
  assert(!("preValidate" in row), "pipeline.delete has no preValidate hook");
  assert(row.workIdRe === RE_WORK_ID_STRICT, "pipeline.delete workIdRe is the strict regex");
  assertEquals(row.workIdMaxLen, 64, "pipeline.delete workIdMaxLen is 64");
  assertDeepEquals(row.workIdInvalidStatus, [422, "invalid-value"], "pipeline.delete workIdInvalidStatus is [422, 'invalid-value']");
}

// ===========================================================================
// (2) statusMap (OP-SM): exit 7 -> 409 'pipeline-active'; DEFAULT_MAP
//     preserved verbatim
// ===========================================================================

function testStatusMap() {
  const row = OP_TABLE["pipeline.delete"];
  const [status, errorClass] = mapExitCode(7, row.statusMap, row.statusMapDefault);
  assertEquals(status, 409, "exit 7 maps to 409");
  assertEquals(errorClass, "pipeline-active", "exit 7 maps to 'pipeline-active'");

  for (const exitCode of Object.keys(DEFAULT_MAP)) {
    const got = mapExitCode(Number(exitCode), row.statusMap, row.statusMapDefault);
    assertDeepEquals(got, DEFAULT_MAP[exitCode], `exit ${exitCode} resolves identically to DEFAULT_MAP`);
  }

  const expected = { ...DEFAULT_MAP, 7: [409, "pipeline-active"] };
  assertDeepEquals(row.statusMap, expected, "statusMap equals DEFAULT_MAP plus exactly exit 7");

  const fallback = mapExitCode(42, row.statusMap, row.statusMapDefault);
  assertDeepEquals(fallback, DEFAULT_FALLBACK, "unmapped exit code falls back to DEFAULT_FALLBACK");
}

// ===========================================================================
// (3) Argv builder
// ===========================================================================

function testArgvBuilder() {
  const [argv, env] = opPipelineDeleteArgv(null, "/repo/root", { work_id: "work-042-sample" }, {});
  assertDeepEquals(argv, ["--work-id", "work-042-sample"], "argv is ['--work-id', work_id]");
  assertDeepEquals(env, { AID_REPO_ROOT: "/repo/root" }, "env is { AID_REPO_ROOT: servedRoot }");

  const [argv2, env2] = opPipelineDeleteArgv(
    null, "/repo/root",
    { work_id: "work-042-sample", repo_root: "/evil/path", AID_REPO_ROOT: "/evil/path" },
    { repo_root: "/evil/path" },
  );
  assertEquals(env2.AID_REPO_ROOT, "/repo/root", "AID_REPO_ROOT never taken from target/args body");
  assert(!argv2.includes("/evil/path"), "argv never carries a body-supplied path");
  assert(!Object.values(env2).includes("/evil/path"), "env never carries a body-supplied path");

  const [argv3, env3] = opPipelineDeleteArgv("/some/resolved/workdir", "/repo/root", { work_id: "work-042-sample" }, {});
  assert(!argv3.includes("/some/resolved/workdir"), "workDir is not forwarded in argv");
  assert(!Object.values(env3).includes("/some/resolved/workdir"), "workDir is not forwarded in env");
}

// ===========================================================================
// (4) dispatchOp validation order (Feature Flow steps 6-7) -- no spawn until
//     every check passes
// ===========================================================================

function testMissingTargetKeyReturns400() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.delete" }, root);
    assertEquals(status, 400, "missing target key -> 400");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testTargetPresentNoWorkIdKeyReturns400() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.delete", target: {} }, root);
    assertEquals(status, 400, "target present but no work_id key -> 400");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testWorkIdNonStringReturns400() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.delete", target: { work_id: 12345 } }, root);
    assertEquals(status, 400, "non-string work_id -> 400");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testMalformedTargetShapeReturns400() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.delete", target: "not-an-object" }, root);
    assertEquals(status, 400, "target not an object -> 400 (shared generic check)");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testInvalidWorkIdShapeReturns422NotBadRequest() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.delete", target: { work_id: "not-a-work-id" } }, root);
    assertEquals(status, 422, "invalid work_id shape -> 422, not 400");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "invalid-value", "error class is invalid-value");
  } finally {
    cleanup(root);
  }
}

function testValuePassingLoosePrefixButFailingStrictShapeReturns422() {
  const root = makeTmpRepo();
  try {
    assert(RE_WORK_ID_SHAPE.test("work-123$$$"), "sanity: loose prefix check would pass this value");
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.delete", target: { work_id: "work-123$$$" } }, root);
    assertEquals(status, 422, "value passing the loose prefix check but failing the strict shape -> 422");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "invalid-value", "error class is invalid-value");
  } finally {
    cleanup(root);
  }
}

function testOverlongWorkIdReturns422() {
  const root = makeTmpRepo();
  try {
    const longId = "work-1-" + "a".repeat(60); // 67 chars > 64
    assert(longId.length > 64, "sanity: longId exceeds 64 chars");
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.delete", target: { work_id: longId } }, root);
    assertEquals(status, 422, "overlong work_id -> 422");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "invalid-value", "error class is invalid-value");
  } finally {
    cleanup(root);
  }
}

function testWorkIdAtMaxLengthPassesShapeCheck() {
  const root = makeTmpRepo();
  try {
    const workId = "work-1-" + "a".repeat(57); // exactly 64 chars, valid slug shape
    assertEquals(workId.length, 64, "sanity: workId is exactly 64 chars");
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.delete", target: { work_id: workId } }, root);
    assertEquals(status, 404, "at-max-length work_id passes shape check (not found, not 422)");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "not-found", "error class is not-found");
  } finally {
    cleanup(root);
  }
}

function testValidShapeNotFoundReturns404NoSpawn() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.delete", target: { work_id: "work-999-nonexistent" } }, root);
    assertEquals(status, 404, "valid shape, not found -> 404");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "not-found", "error class is not-found");
  } finally {
    cleanup(root);
  }
}

function testNonEmptyArgsReturns422AfterResolveNoSpawn() {
  const root = makeTmpRepo();
  try {
    const workDir = seedWork(root, "work-042-sample");
    const [status, body] = dispatchOp(
      OP_TABLE,
      { op: "pipeline.delete", target: { work_id: "work-042-sample" }, args: { foo: "bar" } },
      root,
    );
    assertEquals(status, 422, "non-empty args -> 422 (evaluated after step-6 checks)");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "invalid-value", "error class is invalid-value");
    assert(existsSync(workDir), "no spawn happened -- seeded work dir must still exist");
  } finally {
    cleanup(root);
  }
}

function testEmptyArgsObjectReachesSpawnStageWithCorrectArgv() {
  const root = makeTmpRepo();
  const row = OP_TABLE["pipeline.delete"];
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
      OP_TABLE, { op: "pipeline.delete", target: { work_id: "work-042-sample" }, args: {} }, root,
    );
    assertEquals(status, 200, "empty args + stubbed spawn -> 200 (dispatch-level checks all passed)");
    assertDeepEquals(
      JSON.parse(Buffer.from(body).toString("utf-8")), { ok: true, op: "pipeline.delete" },
      "ok envelope",
    );
    assertEquals(calls.length, 1, "spawn stub invoked exactly once (no real writer spawned)");
    assertDeepEquals(calls[0][0], ["--work-id", "work-042-sample"], "argv built by the dispatcher matches opPipelineDeleteArgv");
    assertDeepEquals(calls[0][1], { AID_REPO_ROOT: root }, "env built by the dispatcher matches opPipelineDeleteArgv");
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
// (5) Existing pipeline/task-scoped rows are UNCHANGED (opt-in)
// ===========================================================================

function testPipelineFinishInvalidWorkIdStillReturns400() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(OP_TABLE, { op: "pipeline.finish", target: { work_id: "not-a-work-id" } }, root);
    assertEquals(status, 400, "pipeline.finish invalid work_id still -> 400 (unchanged)");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testPipelineRenameInvalidWorkIdStillReturns400() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(
      OP_TABLE,
      { op: "pipeline.rename", target: { work_id: "not-a-work-id" }, args: { value: "x" } },
      root,
    );
    assertEquals(status, 400, "pipeline.rename invalid work_id still -> 400 (unchanged)");
    assertEquals(JSON.parse(Buffer.from(body).toString("utf-8")).error, "bad-request", "error class is bad-request");
  } finally {
    cleanup(root);
  }
}

function testPipelineFinishNoWorkIdShapeOverrideFields() {
  const row = OP_TABLE["pipeline.finish"];
  assert(!("workIdRe" in row), "pipeline.finish has no workIdRe override (opt-in)");
  assert(!("workIdMaxLen" in row), "pipeline.finish has no workIdMaxLen override (opt-in)");
  assert(!("workIdInvalidStatus" in row), "pipeline.finish has no workIdInvalidStatus override (opt-in)");
}

function testPipelineRenameStatusMapStillNull() {
  const row = OP_TABLE["pipeline.rename"];
  assertEquals(row.statusMap, null, "pipeline.rename statusMap is still null (unchanged)");
}

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------

testOpTableRowShape();
testStatusMap();
testArgvBuilder();
testMissingTargetKeyReturns400();
testTargetPresentNoWorkIdKeyReturns400();
testWorkIdNonStringReturns400();
testMalformedTargetShapeReturns400();
testInvalidWorkIdShapeReturns422NotBadRequest();
testValuePassingLoosePrefixButFailingStrictShapeReturns422();
testOverlongWorkIdReturns422();
testWorkIdAtMaxLengthPassesShapeCheck();
testValidShapeNotFoundReturns404NoSpawn();
testNonEmptyArgsReturns422AfterResolveNoSpawn();
testEmptyArgsObjectReachesSpawnStageWithCorrectArgv();
testPipelineFinishInvalidWorkIdStillReturns400();
testPipelineRenameInvalidWorkIdStillReturns400();
testPipelineFinishNoWorkIdShapeOverrideFields();
testPipelineRenameStatusMapStillNull();

process.stdout.write(`\n${passed} passed, ${failed} failed\n`);
process.exit(failed > 0 ? 1 : 0);
