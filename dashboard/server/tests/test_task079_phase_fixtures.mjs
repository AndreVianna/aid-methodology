/**
 * dashboard/server/tests/test_task079_phase_fixtures.mjs
 * work-003 delivery-003 task-079 (Feature 002 section 8 Testing, AC-41).
 *
 * Reads the work fixtures of dashboard/reader/tests/fixtures/task079/ (works.txt:
 * one STATE.yml per `@@ <work-id>` section; expected.json: the expected values),
 * writes them into a temporary repository, and reads it through readRepo() of
 * dashboard/server/reader.mjs. The Python twin is
 * dashboard/reader/tests/test_task079_phase_fixtures.py, which also checks that
 * both readers serialize each fixture identically.
 *
 * Run: node --test dashboard/server/tests/test_task079_phase_fixtures.mjs
 *
 * Each test builds its own temporary repository; no work folder is read.
 * Node built-in modules only.
 */

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { readRepo } from "../reader.mjs";

const FIXTURE_DIR = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "reader", "tests", "fixtures", "task079");

// Parse works.txt: each `@@ <work-id>` line opens a STATE.yml section.
function loadWorks() {
  const works = new Map();
  let current = null;
  for (const line of readFileSync(join(FIXTURE_DIR, "works.txt"), "utf8").split("\n")) {
    if (line.startsWith("@@ ")) {
      current = line.slice(3).trim();
      works.set(current, []);
    } else if (current !== null) {
      works.get(current).push(line);
    }
  }
  const out = new Map();
  for (const [id, lines] of works) out.set(id, lines.join("\n") + "\n");
  return out;
}

const EXPECTED = JSON.parse(readFileSync(join(FIXTURE_DIR, "expected.json"), "utf8")).works;

// Write the fixtures into a fresh repository and return its root.
function writeRepo(works) {
  const root = mkdtempSync(join(tmpdir(), "task079-"));
  const aid = join(root, ".aid");
  mkdirSync(aid, { recursive: true });
  writeFileSync(join(aid, "settings.yml"), "project:\n  name: TestRepo\n");
  writeFileSync(
    join(aid, ".aid-manifest.json"),
    JSON.stringify({
      manifest_version: 1,
      aid_version: "1.0.0",
      installed_at: "2026-01-01T00:00:00Z",
      tools: { "claude-code": {} },
    }),
  );
  for (const [id, text] of works) {
    const dir = join(aid, "works", id);
    mkdirSync(dir, { recursive: true });
    writeFileSync(join(dir, "STATE.yml"), text);
  }
  return root;
}

function readFixtureWorks() {
  const works = loadWorks();
  const root = writeRepo(works);
  try {
    const model = readRepo(root);
    return new Map((model.works || []).map((w) => [w.work_id, w]));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

test("the fixture set read by the Node reader is the expected set", () => {
  const got = readFixtureWorks();
  assert.deepEqual([...got.keys()].sort(), Object.keys(EXPECTED).sort());
});

test("each fixture carries its expected phase, lifecycle, step and step_detail", () => {
  const got = readFixtureWorks();
  for (const [id, exp] of Object.entries(EXPECTED)) {
    const w = got.get(id);
    assert.ok(w, `work ${id} missing`);
    assert.equal(w.phase, exp.phase, `${id} phase`);
    assert.equal(w.lifecycle, exp.lifecycle, `${id} lifecycle`);
    assert.equal(w.step, exp.step, `${id} step`);
    assert.equal(w.step_detail, exp.step_detail, `${id} step_detail`);
  }
});

test("each fixture carries its expected open call, open questions and record_status", () => {
  const got = readFixtureWorks();
  for (const [id, exp] of Object.entries(EXPECTED)) {
    const w = got.get(id);
    assert.deepEqual(w.open_call, exp.open_call, `${id} open_call`);
    assert.equal(w.pending_inputs.length, exp.pending, `${id} open questions`);
    assert.equal(w.record_status, exp.record_status, `${id} record_status`);
  }
});

test("a call in progress names the phase the work returns to", () => {
  const w = readFixtureWorks().get("work-105-building-during-call");
  assert.equal(w.open_call.returns_to, "Building");
  assert.equal(w.open_call.to, "aid-kb-update");
  assert.equal(w.open_call.why, "the KB is stale");
});

test("an old phase name reads as its new name", () => {
  const w = readFixtureWorks().get("work-108-old-phase-names");
  assert.equal(w.phase, "Building");
});

test("a work with no intent.reading reads record_status missing; a finished work with a saved skill reads inconsistent", () => {
  const got = readFixtureWorks();
  assert.equal(got.get("work-109-missing-record").record_status, "missing");
  assert.equal(got.get("work-110-inconsistent-record").record_status, "inconsistent");
});
