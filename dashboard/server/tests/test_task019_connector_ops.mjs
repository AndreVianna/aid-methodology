/**
 * dashboard/server/tests/test_task019_connector_ops.mjs
 * "ConnectorRef reader/model + connector.set/remove ops" (task-019,
 * feature-007-connectors-list, delivery-003, work-017-cli-improvements) --
 * Node twin.
 *
 * server.mjs self-executes on import (parses argv, binds a socket
 * immediately -- no main-guard), so its internal functions (dispatchOp,
 * OP_TABLE, validateConnectorSetArgs, opConnectorSetArgv, ...) are not
 * importable as-is. This file reuses test_task017_registry_tooling_round_
 * trips.py's `_sliced_server_mjs_source` cut point (the same MAIN_MARKER
 * comment, "// Main: parse args, create server, bind, register SIGTERM") to
 * export { dispatchOp, OP_TABLE } from a slice of the REAL source, so every
 * case below drives the ACTUAL production functions -- no reimplementation,
 * no "kept in lockstep by inspection" gap. Connector ops need NO further
 * substitution (unlike task-017's aid-CLI-backed rows): write-connector.sh is
 * dispatched via runWriter, which always spawns bash regardless of host OS
 * (the KI-009 OS-branch lives in runAidCli, never touched here).
 *
 * Covers:
 *   1. OP_TABLE row shape: connector.set / connector.remove carry the
 *      expected scope/writer/argSchema/semanticValidate, no statusMap
 *      override.
 *   2. validateConnectorSetArgs / validateConnectorRemoveArgs: name/type/
 *      endpoint/auth/secret_ref/stem cases (mirrors the Python twin's own
 *      matrix).
 *   3. Full dispatchOp round-trips through the REAL co-vendored
 *      write-connector.sh writer (bash) -- 200 happy paths (descriptor
 *      authored, INDEX.md regenerated), 422 short-circuit before any spawn.
 *
 * LOCAL TEST NOTE: no live server.mjs process is spawned and no port is
 * bound anywhere in this file (the slice is imported in-process via a
 * file:// URL) -- every case here calls dispatchOp directly, the same "no
 * server spawn" convention test_task004_op_dispatch.py's real-writer
 * round-trips already established -- safe to run locally per the project's
 * port-binding-server-test constraint, and exercised directly as part of
 * this task's own verification pass.
 *
 * Run: node dashboard/server/tests/test_task019_connector_ops.mjs
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

// ---------------------------------------------------------------------------
// Slice server.mjs before the self-executing 'Main' tail (mirrors
// test_task017_registry_tooling_round_trips.py's _sliced_server_mjs_source(),
// minus the AID_CLI_PATH/timeout/KI-009 substitutions that task's aid-CLI-
// backed rows need -- connector ops never touch those constants).
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
// slice must sit beside reader.mjs to resolve (mirrors test_task017's own
// _SERVER_DIR placement for its sliced copy).
const sliceDir = join(__dirname, "..");
const slicePath = join(sliceDir, `_test_task019_slice_${randomBytes(8).toString("hex")}.mjs`);
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

// ---------------------------------------------------------------------------
// Scratch repo helper
// ---------------------------------------------------------------------------

function makeTmpRepo() {
  const root = join(tmpdir(), `_test_task019_repo_${randomBytes(8).toString("hex")}`);
  mkdirSync(root, { recursive: true });
  return root;
}

function cleanup(root) {
  rmSync(root, { recursive: true, force: true });
}

// ===========================================================================
// (1) OP_TABLE row shape
// ===========================================================================

function testOpTableRowShape() {
  const setRow = OP_TABLE["connector.set"];
  assertEquals(setRow.scope, "project", "connector.set scope is 'project'");
  assertEquals(setRow.writer, "write-connector.sh", "connector.set writer is write-connector.sh");
  assert(setRow.argSchema.name.required === true, "connector.set argSchema.name required");
  assert(setRow.argSchema.type.required === true, "connector.set argSchema.type required");
  for (const key of ["endpoint", "auth", "secret_ref"]) {
    assert(Object.prototype.hasOwnProperty.call(setRow.argSchema, key), `connector.set argSchema has ${key}`);
    assert(!setRow.argSchema[key].required, `connector.set argSchema.${key} not required`);
  }
  assert(typeof setRow.buildArgv === "function", "connector.set buildArgv is a function");
  assert(typeof setRow.semanticValidate === "function", "connector.set semanticValidate is a function");
  assert(setRow.statusMap === null, "connector.set statusMap is null (uses DEFAULT_MAP)");

  const removeRow = OP_TABLE["connector.remove"];
  assertEquals(removeRow.scope, "project", "connector.remove scope is 'project'");
  assertEquals(removeRow.writer, "write-connector.sh", "connector.remove writer is write-connector.sh");
  assert(removeRow.argSchema.stem.required === true, "connector.remove argSchema.stem required");
  assert(typeof removeRow.buildArgv === "function", "connector.remove buildArgv is a function");
  assert(typeof removeRow.semanticValidate === "function", "connector.remove semanticValidate is a function");
  assert(removeRow.statusMap === null, "connector.remove statusMap is null (uses DEFAULT_MAP)");
}

// ===========================================================================
// (2) Pure semantic validation (via OP_TABLE's own semanticValidate hook)
// ===========================================================================

function validateSet(args) {
  return OP_TABLE["connector.set"].semanticValidate(args);
}

function validateRemove(args) {
  return OP_TABLE["connector.remove"].semanticValidate(args);
}

function testValidateConnectorSetArgs() {
  assertEquals(validateSet({ name: "GitHub", type: "mcp" }), null, "valid mcp name/type passes");
  assert(validateSet({ name: "", type: "mcp" }) !== null, "empty name rejected");
  assert(validateSet({ name: "x".repeat(81), type: "mcp" }) !== null, "overlong name rejected");
  assertEquals(validateSet({ name: "x".repeat(80), type: "mcp" }), null, "name at max length passes");
  assert(validateSet({ name: "a\nb", type: "mcp" }) !== null, "name with newline rejected");
  assert(validateSet({ name: "a|b", type: "mcp" }) !== null, "name with pipe rejected");
  assert(validateSet({ name: "a\x01b", type: "mcp" }) !== null, "name with control char rejected");

  assert(validateSet({ name: "n", type: "ftp" }) !== null, "invalid type rejected");
  assertEquals(
    validateSet({ name: "n", type: "api", endpoint: "https://x", auth: "token" }),
    null, "valid api type with required fields passes"
  );
  assertEquals(
    validateSet({ name: "n", type: "ssh", endpoint: "host:22" }),
    null, "valid ssh type (auth omitted, writer forces ssh-key) passes"
  );

  for (const ctype of ["api", "ssh", "url", "cli"]) {
    const args = { name: "n", type: ctype };
    if (ctype !== "ssh") args.auth = "token";
    assert(validateSet(args) !== null, `endpoint required for type ${ctype}`);
  }
  assertEquals(validateSet({ name: "n", type: "mcp" }), null, "endpoint optional for mcp");

  for (const ctype of ["api", "url", "cli"]) {
    assert(
      validateSet({ name: "n", type: ctype, endpoint: "https://x" }) !== null,
      `auth required for type ${ctype}`
    );
  }
  assert(
    validateSet({ name: "n", type: "api", endpoint: "https://x", auth: "bearer" }) !== null,
    "invalid auth enum rejected"
  );
  assert(
    validateSet({ name: "n", type: "api", endpoint: "x".repeat(201), auth: "token" }) !== null,
    "overlong endpoint rejected"
  );
  assert(
    validateSet({ name: "n", type: "api", endpoint: "https://x|evil", auth: "token" }) !== null,
    "endpoint with pipe rejected"
  );

  assertEquals(
    validateSet({ name: "n", type: "api", endpoint: "https://x", auth: "token" }),
    null, "omitted secret_ref never rejected"
  );
  assertEquals(
    validateSet({
      name: "n", type: "api", endpoint: "https://x", auth: "token", secret_ref: "env:MY_TOKEN",
    }),
    null, "env: form accepted"
  );
  assertEquals(
    validateSet({ name: "n", type: "ssh", endpoint: "host", secret_ref: "file:.aid/connectors/.secrets/n" }),
    null, "file: form accepted"
  );
  assert(
    validateSet({
      name: "n", type: "api", endpoint: "https://x", auth: "token", secret_ref: "not-a-valid-ref",
    }) !== null,
    "malformed secret_ref rejected"
  );
  assert(
    validateSet({ name: "n", type: "mcp", secret_ref: "env:MY_TOKEN" }) !== null,
    "secret_ref forbidden for mcp"
  );
  assert(
    validateSet({
      name: "n", type: "url", endpoint: "https://x", auth: "none", secret_ref: "env:MY_TOKEN",
    }) !== null,
    "secret_ref forbidden for auth none"
  );
}

function testValidateConnectorRemoveArgs() {
  assertEquals(validateRemove({ stem: "github" }), null, "valid stem passes");
  assertEquals(validateRemove({ stem: "my-connector-2" }), null, "valid stem with digits/dashes passes");
  assert(validateRemove({ stem: "GitHub" }) !== null, "uppercase stem rejected");
  assert(validateRemove({ stem: "-github" }) !== null, "stem starting with dash rejected");
  assert(validateRemove({ stem: "a/b" }) !== null, "stem with slash rejected");
  assert(validateRemove({ stem: "../etc" }) !== null, "stem with dotdot rejected");
}

// ===========================================================================
// (3) Full dispatchOp round-trips through the REAL write-connector.sh writer
// ===========================================================================

function readFile(path) {
  return readFileSync(path, "utf8");
}

async function testConnectorSetMcpSuccess() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(
      OP_TABLE, { op: "connector.set", target: {}, args: { name: "GitHub", type: "mcp" } }, root
    );
    assertEquals(status, 200, "connector.set mcp success status");
    const parsed = JSON.parse(Buffer.from(body).toString("utf-8"));
    assertEquals(JSON.stringify(parsed), JSON.stringify({ ok: true, op: "connector.set" }), "connector.set ok envelope");
    const descriptorPath = join(root, ".aid", "connectors", "github.md");
    assert(existsSync(descriptorPath), "github.md descriptor written");
    const text = readFile(descriptorPath);
    assert(text.includes("connection_type: mcp"), "descriptor carries connection_type: mcp");
    assert(text.includes("auth_method: none"), "descriptor carries auth_method: none");
    assert(!text.includes("secret_reference:"), "descriptor carries no secret_reference for mcp");
    assert(existsSync(join(root, ".aid", "connectors", "INDEX.md")), "INDEX.md regenerated");
  } finally {
    cleanup(root);
  }
}

async function testConnectorSetApiWithDefaultSecretRef() {
  const root = makeTmpRepo();
  try {
    const [status] = dispatchOp(
      OP_TABLE,
      {
        op: "connector.set", target: {},
        args: { name: "Jira", type: "api", endpoint: "https://acme.atlassian.net/rest/api/3", auth: "token" },
      },
      root
    );
    assertEquals(status, 200, "connector.set api success status");
    const text = readFile(join(root, ".aid", "connectors", "jira.md"));
    assert(text.includes("auth_method: token"), "descriptor carries auth_method: token");
    assert(
      text.includes('secret_reference: "file:.aid/connectors/.secrets/jira"'),
      "descriptor carries the default secret_reference form"
    );
  } finally {
    cleanup(root);
  }
}

async function testConnectorSetSemanticFailureIs422BeforeSpawn() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(
      OP_TABLE, { op: "connector.set", target: {}, args: { name: "n", type: "ftp" } }, root
    );
    assertEquals(status, 422, "invalid type maps to 422");
    const parsed = JSON.parse(Buffer.from(body).toString("utf-8"));
    assertEquals(parsed.error, "invalid-value", "error class is invalid-value");
    assert(!existsSync(join(root, ".aid", "connectors")), "no spawn happened (connectors dir never created)");
  } finally {
    cleanup(root);
  }
}

async function testConnectorRemoveSuccess() {
  const root = makeTmpRepo();
  try {
    const [setStatus] = dispatchOp(
      OP_TABLE, { op: "connector.set", target: {}, args: { name: "GitHub", type: "mcp" } }, root
    );
    assertEquals(setStatus, 200, "seed connector.set succeeds");
    const descriptorPath = join(root, ".aid", "connectors", "github.md");
    assert(existsSync(descriptorPath), "seeded descriptor exists before remove");

    const [status, body] = dispatchOp(
      OP_TABLE, { op: "connector.remove", target: {}, args: { stem: "github" } }, root
    );
    assertEquals(status, 200, "connector.remove success status");
    const parsed = JSON.parse(Buffer.from(body).toString("utf-8"));
    assertEquals(JSON.stringify(parsed), JSON.stringify({ ok: true, op: "connector.remove" }), "connector.remove ok envelope");
    assert(!existsSync(descriptorPath), "descriptor removed from disk");
  } finally {
    cleanup(root);
  }
}

async function testConnectorRemoveBadStemIs422BeforeSpawn() {
  const root = makeTmpRepo();
  try {
    const [status, body] = dispatchOp(
      OP_TABLE, { op: "connector.remove", target: {}, args: { stem: "../etc" } }, root
    );
    assertEquals(status, 422, "bad stem maps to 422");
    const parsed = JSON.parse(Buffer.from(body).toString("utf-8"));
    assertEquals(parsed.error, "invalid-value", "error class is invalid-value");
  } finally {
    cleanup(root);
  }
}

async function testTargetWorkIdIgnoredForProjectScope() {
  const root = makeTmpRepo();
  try {
    const [status] = dispatchOp(
      OP_TABLE,
      { op: "connector.set", target: { work_id: "work-999-does-not-exist" }, args: { name: "GitHub", type: "mcp" } },
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
testValidateConnectorSetArgs();
testValidateConnectorRemoveArgs();
await testConnectorSetMcpSuccess();
await testConnectorSetApiWithDefaultSecretRef();
await testConnectorSetSemanticFailureIs422BeforeSpawn();
await testConnectorRemoveSuccess();
await testConnectorRemoveBadStemIs422BeforeSpawn();
await testTargetWorkIdIgnoredForProjectScope();

process.stdout.write(`\n${passed} passed, ${failed} failed\n`);
process.exit(failed > 0 ? 1 : 0);
