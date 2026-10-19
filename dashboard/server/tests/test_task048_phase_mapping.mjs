/**
 * dashboard/server/tests/test_task048_phase_mapping.mjs
 * Node-side phase-mapping fixtures for readRepo() in reader.mjs
 * (task-048, work-003 delivery-002, AC-41).
 *
 * Mirrors dashboard/reader/tests/test_task048_phase_mapping.py: each fixture
 * is a work at one FR-1 phase, a completed work, a work holding every old
 * phase name, and an unknown name. The phase must be the member the spec's
 * phase table gives (Describe -> Definition, Define and Specify ->
 * Specification, Plan and Detail -> Planning, Execute -> Building).
 *
 * Tests:
 *   - Each new phase name reads as itself.
 *   - A Completed work at CI keeps CI; a Completed work at Building keeps Building.
 *   - Each old phase name maps by the spec table.
 *   - An unknown phase name reads as Unknown.
 *
 * Run: node --test dashboard/server/tests/test_task048_phase_mapping.mjs
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

// The new FR-1 names: each maps to itself.
const NEW_PHASES = ["Definition", "Specification", "Planning", "Building", "CI"];

// The spec's phase table (REQUIREMENTS.md Feature 002, Work state layout).
const OLD_TO_NEW = {
  "Describe": "Definition",
  "Define": "Specification",
  "Specify": "Specification",
  "Plan": "Planning",
  "Detail": "Planning",
  "Execute": "Building",
};

function writeWork(root, phaseValue, lifecycle = "Running") {
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

  const workDir = join(aid, "works", "work-980-phase-fixture");
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
      `lifecycle: ${lifecycle}\n` +
      `phase: ${phaseValue}\n` +
      "active_skill: aid-execute\n" +
      'updated: "2026-10-01T12:00:00Z"\n',
    "utf8",
  );
  writeFileSync(
    join(taskDir, "DETAIL.md"),
    "# task-001: Demo task\n\n**Type:** REFACTOR\n",
    "utf8",
  );
}

function readWork(phaseValue, lifecycle = "Running") {
  const root = mkdtempSync(join(tmpdir(), "task048-phase-"));
  try {
    writeWork(root, phaseValue, lifecycle);
    const model = readRepo(root);
    return (model.works && model.works[0]) || null;
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

test("each new FR-1 phase name reads as itself", () => {
  for (const phase of NEW_PHASES) {
    const w = readWork(phase);
    assert.equal(w.phase, phase, `phase=${phase} must read as ${phase}`);
    assert.equal(w.lifecycle, "Running");
  }
});

test("a Completed work keeps its phase (CI and Building)", () => {
  const ci = readWork("CI", "Completed");
  assert.equal(ci.phase, "CI", "Completed work at CI must read as CI");
  assert.equal(ci.lifecycle, "Completed");

  const building = readWork("Building", "Completed");
  assert.equal(building.phase, "Building", "Completed work at Building must read as Building");
  assert.equal(building.lifecycle, "Completed");
});

test("old phase names map by the spec table", () => {
  for (const [oldName, newName] of Object.entries(OLD_TO_NEW)) {
    const w = readWork(oldName);
    assert.equal(w.phase, newName, `phase=${oldName} must read as ${newName}`);
  }
});

test("an unknown phase name reads as Unknown", () => {
  const w = readWork("Ship");
  assert.equal(w.phase, "Unknown");
});
