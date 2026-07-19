/**
 * dashboard/server/tests/test_task021_external_source_ops.mjs
 * "External-sources reader/model + external-source.add/remove ops" (task-021,
 * feature-010-external-sources-list, delivery-003, work-017-cli-improvements)
 * -- Node twin.
 *
 * server.mjs self-executes on import (parses argv, binds a socket
 * immediately -- no main-guard), so its internal functions (dispatchOp,
 * OP_TABLE, validateExternalSourceArgs, opExternalSourceAddArgv, ...) are not
 * importable as-is. This file reuses test_task017_registry_tooling_round_
 * trips.py's `_sliced_server_mjs_source` cut point (the same MAIN_MARKER
 * comment, "// Main: parse args, create server, bind, register SIGTERM") to
 * export { dispatchOp, OP_TABLE } from a slice of the REAL source, so every
 * case below drives the ACTUAL production functions -- no reimplementation,
 * no "kept in lockstep by inspection" gap. External-source ops need NO
 * further substitution (unlike task-017's aid-CLI-backed rows):
 * write-external-source.sh is dispatched via runWriter, which always spawns
 * bash regardless of host OS (the KI-009 OS-branch lives in runAidCli, never
 * touched here).
 *
 * Covers:
 *   1. OP_TABLE row shape: external-source.add / external-source.remove
 *      carry the expected scope/writer/argSchema/semanticValidate, no
 *      statusMap override.
 *   2. validateExternalSourceArgs: length bounds, newline/'|' rejection,
 *      URL-or-whitespace-free-path/glob shape (mirrors the Python twin's own
 *      matrix).
 *   3. Full dispatchOp round-trips through the REAL co-vendored
 *      write-external-source.sh writer (bash) -- 200 happy paths for
 *      add/remove, 404 remove-target-absent, 422 short-circuit before any
 *      spawn.
 *   4. Reader-visibility: after a real dispatch, parseExternalSources() sees
 *      exactly the written entry (joint task-020/task-021 verification).
 *
 * LOCAL TEST NOTE: no live server.mjs process is spawned and no port is
 * bound anywhere in this file (the slice is imported in-process via a
 * file:// URL) -- every case here calls dispatchOp directly, the same "no
 * server spawn" convention test_task019_connector_ops.mjs already
 * established -- safe to run locally per the project's port-binding-
 * server-test constraint, and exercised directly as part of this task's own
 * verification pass.
 *
 * Run: node dashboard/server/tests/test_task021_external_source_ops.mjs
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
const READER_MJS_PATH = join(__dirname, "..", "reader.mjs");
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

// ---------------------------------------------------------------------------
// Slice server.mjs before the self-executing 'Main' tail (mirrors
// test_task019_connector_ops.mjs's own sliceServerSource()).
// ---------------------------------------------------------------------------
function sliceServerSource() {
  const text = readFileSync(SERVER_MJS_PATH, "utf8");
  const idx = text.indexOf(MAIN_MARKER);
  if (idx === -1) {
    throw new Error(
      "server.mjs 'Main' marker is gone -- this test's slice cut point needs updating"
    );
  }
  return text.slice(0, idx) + "\nexport { dispatchOp, OP_TABLE };\n";
}

// Written INTO dashboard/server/ (colocated with reader.mjs), NOT the OS tmp
// dir -- server.mjs's own `import ... from "./reader.mjs"` is relative, so the
// slice must sit beside reader.mjs to resolve (mirrors test_task019's own
// sliceDir placement).
const sliceDir = join(__dirname, "..");
const slicePath = join(sliceDir, `_test_task021_slice_${randomBytes(8).toString("hex")}.mjs`);
writeFileSync(slicePath, sliceServerSource(), "utf8");

let dispatchOp;
let OP_TABLE;
try {
  const mod = await import(pathToFileURL(slicePath).href);
  dispatchOp = mod.dispatchOp;
  OP_TABLE = mod.OP_TABLE;
} finally {
  rmSync(slicePath, { force: true });
}

const { parseExternalSources } = await import(pathToFileURL(READER_MJS_PATH).href);

// ---------------------------------------------------------------------------
// Scratch repo helper
// ---------------------------------------------------------------------------

function makeTmpRepo() {
  const root = join(tmpdir(), `_test_task021_repo_${randomBytes(8).toString("hex")}`);
  mkdirSync(root, { recursive: true });
  return root;
}

function cleanup(root) {
  rmSync(root, { recursive: true, force: true });
}

function seedExternalSourcesMd(root) {
  const kbDir = join(root, ".aid", "knowledge");
  mkdirSync(kbDir, { recursive: true });
  const extFile = join(kbDir, "external-sources.md");
  writeFileSync(
    extFile,
    "---\nsources:\n  - (none)\n---\n\n## Sources\n\n" +
    "No external documentation was provided during discovery. All knowledge was " +
    "derived from repository content only. If external documentation becomes " +
    "available, re-run discovery or add paths during Q&A.\n",
    "utf8"
  );
  return extFile;
}

// ===========================================================================
// (1) OP_TABLE row shape
// ===========================================================================

function testOpTableRowShape() {
  const addRow = OP_TABLE["external-source.add"];
  assertEquals(addRow.scope, "project", "external-source.add scope is 'project'");
  assertEquals(addRow.writer, "write-external-source.sh", "external-source.add writer is write-external-source.sh");
  assert(addRow.argSchema.value.required === true, "external-source.add argSchema.value required");
  assert(typeof addRow.buildArgv === "function", "external-source.add buildArgv is a function");
  assert(typeof addRow.semanticValidate === "function", "external-source.add semanticValidate is a function");
  assert(addRow.statusMap === null, "external-source.add statusMap is null (uses DEFAULT_MAP)");

  const removeRow = OP_TABLE["external-source.remove"];
  assertEquals(removeRow.scope, "project", "external-source.remove scope is 'project'");
  assertEquals(removeRow.writer, "write-external-source.sh", "external-source.remove writer is write-external-source.sh");
  assert(removeRow.argSchema.value.required === true, "external-source.remove argSchema.value required");
  assert(typeof removeRow.buildArgv === "function", "external-source.remove buildArgv is a function");
  assert(typeof removeRow.semanticValidate === "function", "external-source.remove semanticValidate is a function");
  assert(removeRow.statusMap === null, "external-source.remove statusMap is null (uses DEFAULT_MAP)");
}

// ===========================================================================
// (2) Pure semantic validation (via OP_TABLE's own semanticValidate hook)
// ===========================================================================

function validate(args) {
  return OP_TABLE["external-source.add"].semanticValidate(args);
}

function testValidateExternalSourceArgs() {
  assertEquals(validate({ value: "https://example.com/doc" }), null, "valid URL passes");
  assertEquals(validate({ value: "http://example.com/doc" }), null, "valid http URL passes");
  assertEquals(validate({ value: "docs/reference.md" }), null, "valid whitespace-free path passes");
  assertEquals(validate({ value: "docs/**/*.md" }), null, "valid glob passes");
  assert(validate({ value: "" }) !== null, "empty value rejected");
  assert(validate({ value: "x".repeat(2049) }) !== null, "overlong value rejected");
  assertEquals(validate({ value: "x".repeat(2048) }), null, "value at max length passes");
  assert(validate({ value: "a\nb" }) !== null, "value with newline rejected");
  assert(validate({ value: "a|b" }) !== null, "value with pipe rejected");
  assert(validate({ value: "a path with spaces" }) !== null, "value with space rejected");
  assert(validate({ value: "a\tb" }) !== null, "value with tab rejected");
  assert(validate({ value: "https://example.com/a b" }) !== null, "URL with embedded space rejected");
}

// ===========================================================================
// (3) Full dispatchOp round-trips through the REAL write-external-source.sh
//     writer
// ===========================================================================

function readFile(path) {
  return readFileSync(path, "utf8");
}

async function testAddSuccess() {
  const root = makeTmpRepo();
  try {
    seedExternalSourcesMd(root);
    const [status, body] = dispatchOp(
      OP_TABLE, { op: "external-source.add", target: {}, args: { value: "https://example.com/doc" } }, root
    );
    assertEquals(status, 200, "external-source.add success status");
    const parsed = JSON.parse(Buffer.from(body).toString("utf-8"));
    assertEquals(
      JSON.stringify(parsed), JSON.stringify({ ok: true, op: "external-source.add" }),
      "external-source.add ok envelope"
    );
    const extFile = join(root, ".aid", "knowledge", "external-sources.md");
    const text = readFile(extFile);
    assert(text.includes("https://example.com/doc"), "registry carries the added value");
    assert(!text.includes("- (none)"), "placeholder dropped");
  } finally {
    cleanup(root);
  }
}

async function testAddIsReaderVisible() {
  const root = makeTmpRepo();
  try {
    seedExternalSourcesMd(root);
    const [status] = dispatchOp(
      OP_TABLE, { op: "external-source.add", target: {}, args: { value: "https://example.com/doc" } }, root
    );
    assertEquals(status, 200, "seed add succeeds");
    const kbDir = join(root, ".aid", "knowledge");
    const visible = parseExternalSources(kbDir);
    assertEquals(JSON.stringify(visible), JSON.stringify(["https://example.com/doc"]),
      "parseExternalSources sees exactly the added entry (joint task-020/021 AC2)");
  } finally {
    cleanup(root);
  }
}

async function testAddSemanticFailureIs422BeforeSpawn() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(
      OP_TABLE, { op: "external-source.add", target: {}, args: { value: "a b c" } }, root
    );
    assertEquals(status, 422, "invalid value maps to 422");
    const parsed = JSON.parse(Buffer.from(body).toString("utf-8"));
    assertEquals(parsed.error, "invalid-value", "error class is invalid-value");
    // Proof no spawn happened: the registry file was never created.
    assert(!existsSync(join(root, ".aid", "knowledge", "external-sources.md")), "no spawn happened (file never created)");
  } finally {
    cleanup(root);
  }
}

async function testRemoveSuccess() {
  const root = makeTmpRepo();
  try {
    seedExternalSourcesMd(root);
    const [setStatus] = dispatchOp(
      OP_TABLE, { op: "external-source.add", target: {}, args: { value: "https://example.com/doc" } }, root
    );
    assertEquals(setStatus, 200, "seed add succeeds");

    const [status, body] = dispatchOp(
      OP_TABLE, { op: "external-source.remove", target: {}, args: { value: "https://example.com/doc" } }, root
    );
    assertEquals(status, 200, "external-source.remove success status");
    const parsed = JSON.parse(Buffer.from(body).toString("utf-8"));
    assertEquals(
      JSON.stringify(parsed), JSON.stringify({ ok: true, op: "external-source.remove" }),
      "external-source.remove ok envelope"
    );
    const kbDir = join(root, ".aid", "knowledge");
    assertEquals(JSON.stringify(parseExternalSources(kbDir)), JSON.stringify([]), "entry removed, reader sees []");
  } finally {
    cleanup(root);
  }
}

async function testRemoveAbsentValueIs404() {
  const root = makeTmpRepo();
  try {
    seedExternalSourcesMd(root);
    const [status, body] = dispatchOp(
      OP_TABLE, { op: "external-source.remove", target: {}, args: { value: "https://example.com/never-added" } }, root
    );
    assertEquals(status, 404, "remove absent value maps to 404");
    const parsed = JSON.parse(Buffer.from(body).toString("utf-8"));
    assertEquals(parsed.error, "not-found", "error class is not-found");
  } finally {
    cleanup(root);
  }
}

async function testRemoveSemanticFailureIs422BeforeSpawn() {
  const root = makeTmpRepo();
  try {
    seedExternalSourcesMd(root);
    const [status, body] = dispatchOp(
      OP_TABLE, { op: "external-source.remove", target: {}, args: { value: "bad value" } }, root
    );
    assertEquals(status, 422, "invalid value maps to 422");
    const parsed = JSON.parse(Buffer.from(body).toString("utf-8"));
    assertEquals(parsed.error, "invalid-value", "error class is invalid-value");
  } finally {
    cleanup(root);
  }
}

async function testTargetWorkIdIgnoredForProjectScope() {
  const root = makeTmpRepo();
  try {
    seedExternalSourcesMd(root);
    const [status] = dispatchOp(
      OP_TABLE,
      { op: "external-source.add", target: { work_id: "work-999-does-not-exist" }, args: { value: "https://example.com/doc" } },
      root
    );
    assertEquals(status, 200, "project-scoped op ignores target.work_id (never 404s)");
  } finally {
    cleanup(root);
  }
}

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------

testOpTableRowShape();
testValidateExternalSourceArgs();
await testAddSuccess();
await testAddIsReaderVisible();
await testAddSemanticFailureIs422BeforeSpawn();
await testRemoveSuccess();
await testRemoveAbsentValueIs404();
await testRemoveSemanticFailureIs422BeforeSpawn();
await testTargetWorkIdIgnoredForProjectScope();

process.stdout.write(`\n${passed} passed, ${failed} failed\n`);
process.exit(failed > 0 ? 1 : 0);
