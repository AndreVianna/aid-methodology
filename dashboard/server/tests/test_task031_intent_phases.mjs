/**
 * dashboard/server/tests/test_task031_intent_phases.mjs
 * Node-side intent.phases fixtures for readRepo() in reader.mjs
 * (task-031, work-003 delivery-002, AC-41).
 *
 * Mirrors dashboard/reader/tests/test_task031_intent_phases.py: a STATE.yml
 * whose intent block carries a phases block list must reach the serialized
 * work as that same list, in order; a work with no intent block must read
 * phases as null.
 *
 * Tests:
 *   - intent.phases reaches the work as the same list, in order.
 *   - A work with no intent block reads phases as null.
 *
 * Run: node --test dashboard/server/tests/test_task031_intent_phases.mjs
 *
 * Each fixture builds its own temporary repository.
 * ASCII-only source. Node built-in modules only.
 */

import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { readRepo } from "../reader.mjs";

const PHASES = ["Definition", "Specification", "Building", "CI"];

const WITH_PHASES =
  "intent:\n" +
  "  phases:\n" +
  PHASES.map((p) => `    - ${p}\n`).join("");

function writeWork(root, intentBlock) {
  const aid = join(root, ".aid");
  mkdirSync(aid, { recursive: true });
  writeFileSync(
    join(aid, ".aid-manifest.json"),
    JSON.stringify({
      manifest_version: 1,
      aid_version: "1.0.0",
      installed_at: "2026-01-01T00:00:00Z",
      tools: { "claude-code": {} },
    }),
    "utf8",
  );
  writeFileSync(join(aid, "settings.yml"), "project:\n  name: TestRepo\n", "utf8");

  const workDir = join(aid, "works", "work-981-intent-fixture");
  const taskDir = join(workDir, "tasks", "task-001");
  mkdirSync(taskDir, { recursive: true });
  writeFileSync(
    join(workDir, "STATE.yml"),
    "pipeline:\n" +
      "  path: full\n" +
      "  initiator: aid-describe\n" +
      'started: "2026-10-01"\n' +
      "minimum_grade: A\n" +
      "user_approved: no\n" +
      "lifecycle: Running\n" +
      "phase: Building\n" +
      "active_skill: aid-execute\n" +
      'updated: "2026-10-01T12:00:00Z"\n' +
      intentBlock,
    "utf8",
  );
  writeFileSync(
    join(taskDir, "DETAIL.md"),
    "# task-001: Demo task\n\n**Type:** REFACTOR\n",
    "utf8",
  );
}

function readWork(intentBlock) {
  const root = mkdtempSync(join(tmpdir(), "task031-intent-"));
  try {
    writeWork(root, intentBlock);
    const model = readRepo(root);
    return (model.works && model.works[0]) || null;
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

test("intent.phases reaches the work as the same list, in order", () => {
  const w = readWork(WITH_PHASES);
  assert.ok(w, "the fixture work must be read");
  assert.deepEqual(w.phases, PHASES);
});

test("a work with no intent block reads phases as null", () => {
  const w = readWork("");
  assert.ok(w, "the fixture work must be read");
  assert.equal(w.phases, null);
});
