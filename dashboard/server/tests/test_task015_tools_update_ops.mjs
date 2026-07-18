/**
 * dashboard/server/tests/test_task015_tools_update_ops.mjs
 * "tools.update / tools.update-self handlers" (task-015, feature-004-update-tools,
 * delivery-002, work-017-cli-improvements) -- Node twin.
 *
 * Mirrors test_task015_tools_update_ops.py's scope, adapted to this codebase's
 * established Node-testing constraint: server.mjs self-executes on import
 * (parses argv, binds a socket immediately -- no main-guard), so its internal
 * functions (dispatchOp, opToolsUpdateArgv, mapExitCode, ...) are NOT importable
 * in-process. Per the SAME convention test_task011_dispatch_round_trip.mjs's own
 * "OP-SM hook" group and test_task013_project_registry_ops.mjs's own groups
 * [A]/[B] already established (mirror the logic verbatim into this file, kept
 * in lockstep with server.mjs by inspection -- never eval/import), this file:
 *
 *   [A] Structural source-presence checks, scoped regex extraction of the new
 *       OP_TABLE["tools.update"] / HOME_OP_TABLE["tools.update-self"] row
 *       literals -- proves both rows reuse spawnAidCli (KI-004: the SAME
 *       shared resolver task-013 introduced, never re-invented), carry the
 *       TOOLS_UPDATE_STATUS_MAP / TOOLS_UPDATE_STATUS_DEFAULT / TOOLS_UPDATE_
 *       TIMEOUT constants, and (tools.update only) the "project" scope.
 *   [B] Mirrored pure-function unit tests: validateNoArgs, opToolsUpdateArgv,
 *       opToolsUpdateSelfArgv, and mapExitCode's 'defaultStatus' parameter
 *       (task-015's extension to the shared OP-SM hook) -- in-process, no
 *       spawn, kept in lockstep with server.mjs by inspection.
 *
 * Deliberately NOT covered here (out of this task's scope / a task-017
 * target, and NOT mirrored in the Python twin either -- see that file's own
 * docstring): a live-server group dispatching through the REAL bin/aid CLI.
 * Unlike project.add/remove (fast local filesystem ops, which task-013's own
 * group [C] exercises live), `aid update`/`aid update self` perform real
 * network fetches (GitHub/npm/PyPI) and can take seconds-to-minutes --
 * unsuitable for a bounded local/CI unit test. task-017 (Registry + tooling
 * op round-trips) is the integration-level TEST task for the full round trip.
 *
 * Run: node dashboard/server/tests/test_task015_tools_update_ops.mjs
 *
 * LOCAL TEST NOTE: this file spawns NOTHING (no child process, no socket
 * bind) -- every group is either a static source-presence check or an
 * in-process mirrored-function assertion, so the whole file is safe to run
 * locally per the project's port-binding-server-test constraint.
 *
 * ASCII-only source. Node built-in modules only.
 */

import { readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const SERVER_MJS = join(__dirname, "..", "server.mjs");

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

const serverSrc = readFileSync(SERVER_MJS, "utf-8");

// ---------------------------------------------------------------------------
// [A] Structural source-presence checks -- scoped regex extraction of the new
// OP_TABLE / HOME_OP_TABLE row literals (mirrors test_task013's own
// TestHomeOpTableRegistration checks, adapted to this file's source-inspection
// constraint since server.mjs cannot be imported).
// ---------------------------------------------------------------------------

process.stdout.write("\n[A] tools.update / tools.update-self row wiring (source-presence, scoped regex)\n");

{
  // Extract the "tools.update": { ... } row literal out of the OP_TABLE block.
  const opRowMatch = serverSrc.match(/"tools\.update":\s*\{([\s\S]*?)\n {2}\},/);
  assert(!!opRowMatch, "A.1: OP_TABLE carries a \"tools.update\" row");
  const opRow = opRowMatch ? opRowMatch[1] : "";

  assert(/scope:\s*"project"/.test(opRow), "A.2: tools.update row scope is \"project\" (per-repo, no work_id)");
  assert(/argSchema:\s*\{\s*\}/.test(opRow), "A.3: tools.update row argSchema is {} (argument-free)");
  assert(/buildArgv:\s*opToolsUpdateArgv/.test(opRow), "A.4: tools.update row buildArgv is opToolsUpdateArgv");
  assert(/semanticValidate:\s*validateNoArgs/.test(opRow), "A.5: tools.update row semanticValidate is validateNoArgs");
  assert(/spawn:\s*spawnAidCli/.test(opRow),
    "A.6: tools.update row spawn is spawnAidCli (KI-004: the SAME shared resolver, not re-invented)");
  assert(/aidCliTimeout:\s*TOOLS_UPDATE_TIMEOUT/.test(opRow), "A.7: tools.update row aidCliTimeout is TOOLS_UPDATE_TIMEOUT");
  assert(/statusMap:\s*TOOLS_UPDATE_STATUS_MAP/.test(opRow), "A.8: tools.update row statusMap is TOOLS_UPDATE_STATUS_MAP");
  assert(/statusMapDefault:\s*TOOLS_UPDATE_STATUS_DEFAULT/.test(opRow),
    "A.9: tools.update row statusMapDefault is TOOLS_UPDATE_STATUS_DEFAULT");
  assert(!/resolveTarget/.test(opRow), "A.10: tools.update row has no resolveTarget (id resolution happens in serveOp)");
  assert(!/postVerify/.test(opRow), "A.11: tools.update row has no postVerify (no fail-open guard -- not `aid projects`)");
}

{
  const homeRowMatch = serverSrc.match(/"tools\.update-self":\s*\{([\s\S]*?)\n {2}\},/);
  assert(!!homeRowMatch, "A.12: HOME_OP_TABLE carries a \"tools.update-self\" row");
  const homeRow = homeRowMatch ? homeRowMatch[1] : "";

  assert(/scope:\s*"home"/.test(homeRow), "A.13: tools.update-self row scope is \"home\"");
  assert(/argSchema:\s*\{\s*\}/.test(homeRow), "A.14: tools.update-self row argSchema is {} (argument-free)");
  assert(/buildArgv:\s*opToolsUpdateSelfArgv/.test(homeRow), "A.15: tools.update-self row buildArgv is opToolsUpdateSelfArgv");
  assert(/semanticValidate:\s*validateNoArgs/.test(homeRow), "A.16: tools.update-self row semanticValidate is validateNoArgs");
  assert(/spawn:\s*spawnAidCli/.test(homeRow),
    "A.17: tools.update-self row spawn is spawnAidCli (KI-004: the SAME shared resolver, not re-invented)");
  assert(/aidCliTimeout:\s*TOOLS_UPDATE_TIMEOUT/.test(homeRow), "A.18: tools.update-self row aidCliTimeout is TOOLS_UPDATE_TIMEOUT");
  assert(/statusMap:\s*TOOLS_UPDATE_STATUS_MAP/.test(homeRow), "A.19: tools.update-self row statusMap is TOOLS_UPDATE_STATUS_MAP");
  assert(/statusMapDefault:\s*TOOLS_UPDATE_STATUS_DEFAULT/.test(homeRow),
    "A.20: tools.update-self row statusMapDefault is TOOLS_UPDATE_STATUS_DEFAULT");
}

{
  // TOOLS_UPDATE_TIMEOUT must be strictly greater than the fast-registry-op default.
  const timeoutMatch = serverSrc.match(/const TOOLS_UPDATE_TIMEOUT = (\d+);/);
  const defaultTimeoutMatch = serverSrc.match(/const DEFAULT_AID_CLI_TIMEOUT = (\d+);/);
  assert(!!timeoutMatch && !!defaultTimeoutMatch, "A.21: both TOOLS_UPDATE_TIMEOUT and DEFAULT_AID_CLI_TIMEOUT are found");
  if (timeoutMatch && defaultTimeoutMatch) {
    assert(Number(timeoutMatch[1]) > Number(defaultTimeoutMatch[1]),
      "A.22: TOOLS_UPDATE_TIMEOUT (" + timeoutMatch[1] + "ms) exceeds DEFAULT_AID_CLI_TIMEOUT (" + defaultTimeoutMatch[1] + "ms)");
  }
}

{
  // dispatchOp must stash aidHome into target._aidHome (the pass-through
  // opToolsUpdateArgv relies on, since buildArgv's signature is frozen).
  assert(/target\._aidHome\s*=/.test(serverSrc),
    "A.23: dispatchOp stashes the resolved aidHome into target._aidHome");
  // serveOp must thread AID_HOME through to dispatchOp (the per-repo call site
  // -- servedRoot there is canonPath, NOT aidHome, so this argument is load-bearing).
  assert(/dispatchOp\(OP_TABLE,\s*parsed,\s*canonPath,\s*AID_HOME\)/.test(serverSrc),
    "A.24: serveOp passes AID_HOME explicitly to dispatchOp (canonPath alone is the repo path, not aid_home)");
}

// ---------------------------------------------------------------------------
// [B] Mirrored pure-function unit tests (server.mjs self-executes on import --
// see module docstring), in-process, no spawn. Mirrors server.mjs's real
// validateNoArgs / opToolsUpdateArgv / opToolsUpdateSelfArgv / mapExitCode
// verbatim -- kept in lockstep by inspection, same convention as this suite
// family's DEFAULT_MAP / isAllowedHost mirrors.
// ---------------------------------------------------------------------------

process.stdout.write("\n[B] Mirrored pure-function unit tests (kept in lockstep with server.mjs)\n");

function mirroredValidateNoArgs(args) {
  if (args && Object.keys(args).length > 0) {
    return "this op accepts no arguments";
  }
  return null;
}

function mirroredToPosixArg(p) {
  return p.split("\\").join("/");
}

function mirroredOpToolsUpdateArgv(workDir, servedRoot, target, args) {
  const argv = ["update", "--target", mirroredToPosixArg(servedRoot)];
  const env = { AID_HOME: target._aidHome };
  return [argv, env];
}

function mirroredOpToolsUpdateSelfArgv(workDir, servedRoot, target, args) {
  const argv = ["update", "self"];
  const env = { AID_HOME: servedRoot };
  return [argv, env];
}

const MIRRORED_AID_CLI_TIMEOUT_EXIT = -1;
const MIRRORED_TOOLS_UPDATE_STATUS_MAP = {
  [MIRRORED_AID_CLI_TIMEOUT_EXIT]: [504, "timed-out"],
};
const MIRRORED_TOOLS_UPDATE_STATUS_DEFAULT = [500, "update-failed"];
const MIRRORED_DEFAULT_FALLBACK = [500, "write-failed"];

function mirroredMapExitCode(exitCode, statusMap, defaultStatus) {
  const effective = statusMap || {};
  return effective[exitCode] || defaultStatus || MIRRORED_DEFAULT_FALLBACK;
}

{
  assertEquals(mirroredValidateNoArgs({}), null, "B.1: absent/empty args -> null (accepted)");
  assertEquals(mirroredValidateNoArgs({ foo: "bar" }), "this op accepts no arguments", "B.2: non-empty args -> rejected");
}

{
  const target = { _aidHome: "/state/home" };
  const [argv, env] = mirroredOpToolsUpdateArgv(null, "/repo/path", target, {});
  assert(JSON.stringify(argv) === JSON.stringify(["update", "--target", "/repo/path"]),
    "B.3: opToolsUpdateArgv builds [\"update\", \"--target\", <repo>]");
  assertEquals(env.AID_HOME, "/state/home", "B.4: opToolsUpdateArgv env.AID_HOME comes from target._aidHome, not servedRoot");
}

{
  const target = { _aidHome: "C:\\state\\home" };
  const [argv] = mirroredOpToolsUpdateArgv(null, "C:\\repo\\path", target, {});
  assert(JSON.stringify(argv) === JSON.stringify(["update", "--target", "C:/repo/path"]),
    "B.5: opToolsUpdateArgv posix-ifies the ARGV path element (Windows backslash form)");
}

{
  const [argv, env] = mirroredOpToolsUpdateSelfArgv(null, "/state/home", {}, {});
  assert(JSON.stringify(argv) === JSON.stringify(["update", "self"]), "B.6: opToolsUpdateSelfArgv builds [\"update\", \"self\"]");
  assertEquals(env.AID_HOME, "/state/home", "B.7: opToolsUpdateSelfArgv env.AID_HOME comes from servedRoot (home scope == aid_home)");
}

{
  // Unenumerated exit falls back to the row's own statusMapDefault -- NOT the
  // shared (500, write-failed) DEFAULT_FALLBACK.
  const [status1, err1] = mirroredMapExitCode(9, MIRRORED_TOOLS_UPDATE_STATUS_MAP, MIRRORED_TOOLS_UPDATE_STATUS_DEFAULT);
  assertEquals(status1, 500, "B.8: unenumerated exit -> statusMapDefault status (500)");
  assertEquals(err1, "update-failed", "B.8b: unenumerated exit -> statusMapDefault error class ('update-failed', not 'write-failed')");

  // The out-of-band timeout sentinel IS enumerated -- wins over the default.
  const [status2, err2] = mirroredMapExitCode(MIRRORED_AID_CLI_TIMEOUT_EXIT, MIRRORED_TOOLS_UPDATE_STATUS_MAP, MIRRORED_TOOLS_UPDATE_STATUS_DEFAULT);
  assertEquals(status2, 504, "B.9: timeout sentinel -> 504 (enumerated row wins over statusMapDefault)");
  assertEquals(err2, "timed-out", "B.9b: timeout sentinel error class 'timed-out'");

  // No statusMapDefault given (e.g. project.add/remove's PROJECT_OP_STATUS_MAP) -- unchanged behavior.
  const [status3, err3] = mirroredMapExitCode(9, { 2: [422, "invalid-value"] }, undefined);
  assertEquals(status3, 500, "B.10: no statusMapDefault -> shared DEFAULT_FALLBACK status (500)");
  assertEquals(err3, "write-failed", "B.10b: no statusMapDefault -> shared DEFAULT_FALLBACK error class 'write-failed'");
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

process.stdout.write("\n--- Result: " + passed + " passed, " + failed + " failed ---\n");

if (failed > 0) {
  process.exit(1);
}
