/**
 * dashboard/server/tests/test_task002_resolve_work_dir.mjs
 * Unit tests for resolveWorkDir(servedRoot, workId) -> path | null in reader.mjs
 * (task-002, feature-001-write-infrastructure/delivery-001 -- WT-1).
 *
 * Mirrors dashboard/reader/tests/test_task002_resolve_work_dir.py.
 *
 * Tests:
 *   - Resolves to the on-disk work directory when exactly one worktree holds workId.
 *   - Returns null when no worktree of the served repo holds workId.
 *   - SD-3 degradation: a non-git served root still resolves via the main-root-only
 *     fallback (no real git needed for this group).
 *   - Real-git group (skipped if git is unavailable, mirroring test_server_node.mjs's
 *     [11e] pattern): a genuine `git worktree add` fixture verifies --
 *       * a worktree-isolated pipeline resolves to ITS worktree copy, never a
 *         reconstructed <served-root>/.aid/works/<work_id> path (WT-1)
 *       * newest `updated` wins across worktree copies
 *       * tie-break: branch_label lexical sort, "main" sorting first
 *   - Never throws on a missing/malformed STATE.md (presence-only inclusion test).
 *
 * Run: node dashboard/server/tests/test_task002_resolve_work_dir.mjs
 *
 * No server spawn, no port binding -- safe to run standalone.
 * ASCII-only source. Node built-in modules only.
 */

import { mkdirSync, writeFileSync, rmSync, realpathSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { spawnSync } from "child_process";
import { resolveWorkDir } from "../reader.mjs";

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
  const ok = a === b;
  if (ok) {
    process.stdout.write("  PASS: " + msg + "\n");
    passed++;
  } else {
    process.stderr.write("  FAIL: " + msg + " -- got " + JSON.stringify(a) + " expected " + JSON.stringify(b) + "\n");
    failed++;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeRepo(dir) {
  const aid = join(dir, ".aid");
  mkdirSync(aid, { recursive: true });
  writeFileSync(
    join(aid, ".aid-manifest.json"),
    JSON.stringify({ manifest_version: 1, aid_version: "1.0.0", installed_at: "2026-01-01T00:00:00Z", tools: { "claude-code": {} } }),
    "utf8"
  );
  writeFileSync(join(aid, "settings.yml"), "project:\n  name: TestRepo\n", "utf8");
  return aid;
}

function stateText(updated) {
  return [
    "## Pipeline State",
    "",
    "- **Lifecycle:** Running",
    "- **Phase:** Execute",
    "- **Active Skill:** aid-execute",
    "- **Updated:** " + updated,
    "- **Pause Reason:** --",
    "- **Block Reason:** --",
    "- **Block Artifact:** --",
    "",
    "## Tasks State",
    "",
    "| # | Task | Type | Wave | State | Review | Elapsed | Notes |",
    "|---|------|------|------|-------|--------|---------|-------|",
    "",
  ].join("\n");
}

function writeWork(aidDir, workId, updated, withState = true) {
  const workDir = join(aidDir, "works", workId);
  mkdirSync(workDir, { recursive: true });
  if (withState) {
    writeFileSync(join(workDir, "STATE.md"), stateText(updated), "utf8");
  }
  return workDir;
}

function freshTmp(label) {
  const dir = join(tmpdir(), "aid-t002-" + label + "-" + Date.now() + "-" + Math.random().toString(36).slice(2));
  mkdirSync(dir, { recursive: true });
  // Normalize to the OS's canonical long-form path (realpathSync.native): on
  // Windows, os.tmpdir() can return an 8.3 short-name form (e.g. "ANDRE~1.VIA")
  // that differs textually from what `git rev-parse --show-toplevel` reports
  // (the long form) -- a pure test-fixture/environment artifact, not a
  // resolveWorkDir defect. Normalizing here keeps path comparisons in this
  // suite exact without touching production code.
  return realpathSync.native(dir);
}

// ---------------------------------------------------------------------------
// Group 1: single-copy resolution (no git required -- non-git temp dir)
// ---------------------------------------------------------------------------

{
  const dir = freshTmp("single");
  try {
    const aid = makeRepo(dir);
    const workDir = writeWork(aid, "work-001-solo", "2026-06-10T12:00:00Z");

    const result = resolveWorkDir(dir, "work-001-solo");
    assertEquals(result, workDir, "1.1: resolves single worktree copy (non-git main-only fallback)");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// Group 2: not-found -> null
// ---------------------------------------------------------------------------

{
  const dir = freshTmp("notfound");
  try {
    const aid = makeRepo(dir);
    writeWork(aid, "work-001-exists", "2026-06-10T12:00:00Z");

    const result = resolveWorkDir(dir, "work-999-does-not-exist");
    assert(result === null, "2.1: returns null when no worktree holds work_id");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

{
  const dir = freshTmp("noaid");
  try {
    // No .aid/ at all
    const result = resolveWorkDir(dir, "work-001-anything");
    assert(result === null, "2.2: returns null when no .aid/ exists at all");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// Group 3: SD-3 degradation -- non-git served root -> main-root-only fallback
// (exercises the REAL _enumerateWorktreeRoots on a genuinely non-git dir)
// ---------------------------------------------------------------------------

{
  const dir = freshTmp("nongit");
  try {
    const aid = makeRepo(dir);
    const workDir = writeWork(aid, "work-004-nongit", "2026-06-10T12:00:00Z");

    const result = resolveWorkDir(dir, "work-004-nongit");
    assertEquals(result, workDir, "3.1: non-git root resolves via main-root-only fallback (SD-3)");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// Group 4: presence-only inclusion -- missing / malformed STATE.md never
// excludes a candidate and never throws.
// ---------------------------------------------------------------------------

{
  const dir = freshTmp("nostate");
  try {
    const aid = makeRepo(dir);
    const workDir = writeWork(aid, "work-005-nostate", null, false);

    const result = resolveWorkDir(dir, "work-005-nostate");
    assertEquals(result, workDir, "4.1: missing STATE.md still resolves (presence-only inclusion)");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

{
  const dir = freshTmp("malformed");
  try {
    const aid = makeRepo(dir);
    const workDir = join(aid, "works", "work-005-malformed");
    mkdirSync(workDir, { recursive: true });
    writeFileSync(join(workDir, "STATE.md"), "## Pipeline Sta", "utf8"); // truncated

    const result = resolveWorkDir(dir, "work-005-malformed");
    assertEquals(result, workDir, "4.2: malformed STATE.md does not throw; still resolves");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

// ---------------------------------------------------------------------------
// Group 5 (real-git; skipped if git unavailable): WT-1 worktree resolution +
// winner-rule (newest updated) + tie-break (main first).
// ---------------------------------------------------------------------------

function gitEnv() {
  return Object.assign({}, process.env, {
    GIT_AUTHOR_NAME: "test",
    GIT_AUTHOR_EMAIL: "test@test.com",
    GIT_COMMITTER_NAME: "test",
    GIT_COMMITTER_EMAIL: "test@test.com",
  });
}

function initRepoWithCommit(dir) {
  const env = gitEnv();
  spawnSync("git", ["init", "-b", "main", dir], { env, timeout: 5000 });
  writeFileSync(join(dir, "seed.txt"), "seed\n", "utf8");
  spawnSync("git", ["-C", dir, "add", "seed.txt"], { env, timeout: 5000 });
  spawnSync("git", ["-C", dir, "commit", "-m", "seed"], { env, timeout: 5000 });
}

let gitAvailable = false;
try {
  const r = spawnSync("git", ["--version"], { timeout: 2000, encoding: "utf8" });
  gitAvailable = r.status === 0;
} catch (_) {}

if (gitAvailable) {
  process.stdout.write("  [group5] git available -- running real-worktree tests\n");

  // --- 5.1: worktree-isolated pipeline resolves to its worktree copy, never a
  // reconstructed <served-root>/.aid/works/<work_id> path.
  {
    const dir = freshTmp("wt-isolated");
    try {
      initRepoWithCommit(dir);
      const mainAid = join(dir, ".aid");
      mkdirSync(mainAid, { recursive: true }); // main root has .aid/ but NOT this work

      const wtPath = join(dir, "wt-feat");
      const env = gitEnv();
      const wtResult = spawnSync("git", ["-C", dir, "worktree", "add", wtPath, "-b", "feat-branch"], { env, timeout: 8000 });

      if (wtResult.status === 0) {
        const wtAid = join(wtPath, ".aid");
        const wtWorkDir = writeWork(wtAid, "work-017-cli-improvements", "2026-07-17T00:00:00Z");

        const reconstructedServedPath = join(mainAid, "works", "work-017-cli-improvements");

        const result = resolveWorkDir(dir, "work-017-cli-improvements");
        assertEquals(result, wtWorkDir, "5.1: worktree-isolated pipeline resolves to its worktree copy (WT-1)");
        assert(result !== reconstructedServedPath, "5.1b: result is NOT the reconstructed served-root path");
      } else {
        process.stdout.write("  SKIP: 5.1 -- git worktree add failed (status=" + wtResult.status + ")\n");
      }
    } finally {
      // Best-effort cleanup: remove worktree registration before deleting the dir tree.
      try { spawnSync("git", ["-C", dir, "worktree", "remove", "--force", join(dir, "wt-feat")], { timeout: 5000 }); } catch (_) {}
      rmSync(dir, { recursive: true, force: true });
    }
  }

  // --- 5.2: newest `updated` wins across two worktree copies of the same work_id.
  {
    const dir = freshTmp("wt-newest");
    try {
      initRepoWithCommit(dir);
      const mainAid = join(dir, ".aid");
      mkdirSync(mainAid, { recursive: true });
      const workId = "work-002-multi";
      const mainWorkDir = writeWork(mainAid, workId, "2026-06-10T09:00:00Z");

      const wtPath = join(dir, "wt-newer");
      const env = gitEnv();
      const wtResult = spawnSync("git", ["-C", dir, "worktree", "add", wtPath, "-b", "feat-newer"], { env, timeout: 8000 });

      if (wtResult.status === 0) {
        const wtAid = join(wtPath, ".aid");
        const wtWorkDir = writeWork(wtAid, workId, "2026-06-10T12:00:00Z"); // NEWER

        const result = resolveWorkDir(dir, workId);
        assertEquals(result, wtWorkDir, "5.2: newest `updated` wins across worktree copies");
        assert(result !== mainWorkDir, "5.2b: older main copy does not win");
      } else {
        process.stdout.write("  SKIP: 5.2 -- git worktree add failed (status=" + wtResult.status + ")\n");
      }
    } finally {
      try { spawnSync("git", ["-C", dir, "worktree", "remove", "--force", join(dir, "wt-newer")], { timeout: 5000 }); } catch (_) {}
      rmSync(dir, { recursive: true, force: true });
    }
  }

  // --- 5.3: tie-break -- equal `updated` -> "main" branch wins.
  {
    const dir = freshTmp("wt-tie");
    try {
      initRepoWithCommit(dir);
      const mainAid = join(dir, ".aid");
      mkdirSync(mainAid, { recursive: true });
      const workId = "work-003-tie";
      const sameTs = "2026-06-10T12:00:00Z";
      const mainWorkDir = writeWork(mainAid, workId, sameTs);

      const wtPath = join(dir, "wt-tie-feat");
      const env = gitEnv();
      const wtResult = spawnSync("git", ["-C", dir, "worktree", "add", wtPath, "-b", "aaa-branch"], { env, timeout: 8000 });
      // "aaa-branch" is lexically BEFORE "main" -- proves it's "main" the special-case
      // wins, not merely lexical-first.

      if (wtResult.status === 0) {
        const wtAid = join(wtPath, ".aid");
        writeWork(wtAid, workId, sameTs);

        const result = resolveWorkDir(dir, workId);
        assertEquals(result, mainWorkDir, "5.3: equal `updated` tie-break -- 'main' branch wins over lexically-earlier label");
      } else {
        process.stdout.write("  SKIP: 5.3 -- git worktree add failed (status=" + wtResult.status + ")\n");
      }
    } finally {
      try { spawnSync("git", ["-C", dir, "worktree", "remove", "--force", join(dir, "wt-tie-feat")], { timeout: 5000 }); } catch (_) {}
      rmSync(dir, { recursive: true, force: true });
    }
  }
} else {
  process.stdout.write("  SKIP: group5 -- git not available on this host\n");
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

process.stdout.write("\n--- Result: " + passed + " passed, " + failed + " failed ---\n");

if (failed > 0) {
  process.exit(1);
}
