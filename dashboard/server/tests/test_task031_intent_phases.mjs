/**
 * dashboard/server/tests/test_task031_intent_phases.mjs
 * Node-side work-level fixtures for readRepo() in reader.mjs
 * (task-031, work-003 delivery-002, AC-41; task-070, feature-002 section 6).
 *
 * Mirrors dashboard/reader/tests/test_task031_intent_phases.py: a STATE.yml
 * whose intent block carries a phases block list must reach the serialized
 * work as that same list, in order; a work with no intent block must read
 * phases as null.
 *
 * task-070 section-6 record fields, the Node side of the Python cases:
 *   - an open call (returns yes, returned unset) reads open_call with to, why
 *     and returns_to (the phase the work is in); a closed call is skipped;
 *   - a work with no intent.reading reads record_status missing;
 *   - a Completed work that still names a saved skill reads inconsistent;
 *   - step and step_detail come through;
 *   - a qa entry in state Skipped counts as open (pending_inputs).
 *
 * Tests:
 *   - intent.phases reaches the work as the same list, in order.
 *   - A work with no intent block reads phases as null.
 *   - The open-call, record_status, step and skipped-qa cases above.
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

const INTENT_READ = "intent:\n  reading: Build the thing\n";

const STEP = 'step: "3"\nstep_detail: review the diff\n';

// One closed call (returned set) then one open call: the newest open one wins.
const HANDOFFS =
  "handoffs:\n" +
  "  - from: aid-execute\n" +
  '    from_step: "2"\n' +
  "    from_detail: --\n" +
  "    to: aid-plan\n" +
  "    why: old question\n" +
  "    returns: yes\n" +
  '    returned: "2026-10-02T09:00:00Z"\n' +
  "  - from: aid-execute\n" +
  '    from_step: "3"\n' +
  "    from_detail: --\n" +
  "    to: aid-review\n" +
  "    why: needs a second look\n" +
  "    returns: yes\n" +
  "    returned: --\n";

// Skipped and Pending are open; Answered is not.
const QA =
  "qa:\n" +
  "  - id: 1\n" +
  "    category: Scope\n" +
  "    impact: Low\n" +
  "    state: Skipped\n" +
  "    context: first question\n" +
  "    suggested: Yes\n" +
  "  - id: 2\n" +
  "    category: Scope\n" +
  "    impact: High\n" +
  "    state: Pending\n" +
  "    context: second question\n" +
  "    suggested: No\n" +
  "  - id: 3\n" +
  "    category: Scope\n" +
  "    impact: High\n" +
  "    state: Answered\n" +
  "    context: third question\n" +
  "    suggested: No\n";

/**
 * Build a work STATE.yml: the identity keys, `extra` top-level blocks
 * (step, handoffs, qa), then `intentBlock` last (may be empty).
 */
function stateText(intentBlock, { lifecycle = "Running", activeSkill = "aid-execute", extra = "" } = {}) {
  return (
    "pipeline:\n" +
    "  path: full\n" +
    "  initiator: aid-describe\n" +
    'started: "2026-10-01"\n' +
    "minimum_grade: A\n" +
    "user_approved: no\n" +
    `lifecycle: ${lifecycle}\n` +
    "phase: Building\n" +
    `active_skill: ${activeSkill}\n` +
    extra +
    'updated: "2026-10-01T12:00:00Z"\n' +
    intentBlock
  );
}

function writeRepo(root, stateTextValue) {
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
  writeFileSync(join(workDir, "STATE.yml"), stateTextValue, "utf8");
  writeFileSync(
    join(taskDir, "DETAIL.md"),
    "# task-001: Demo task\n\n**Type:** REFACTOR\n",
    "utf8",
  );
}

function readWorkFrom(stateTextValue) {
  const root = mkdtempSync(join(tmpdir(), "task031-intent-"));
  try {
    writeRepo(root, stateTextValue);
    const model = readRepo(root);
    return (model.works && model.works[0]) || null;
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

function readWork(intentBlock) {
  return readWorkFrom(stateText(intentBlock));
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

test("an open call reads open_call with to, why and returns_to", () => {
  const w = readWorkFrom(stateText(INTENT_READ, { extra: STEP + HANDOFFS }));
  assert.ok(w, "the fixture work must be read");
  assert.deepEqual(w.open_call, {
    to: "aid-review",
    why: "needs a second look",
    returns_to: "Building",
  });
});

test("no open_call when every call is returned", () => {
  const closedOnly = HANDOFFS.split('  - from: aid-execute\n    from_step: "3"')[0];
  const w = readWorkFrom(stateText(INTENT_READ, { extra: STEP + closedOnly }));
  assert.ok(w, "the fixture work must be read");
  assert.equal(w.open_call, null);
});

test("a work with no intent.reading reads record_status missing", () => {
  const w = readWorkFrom(stateText("", { extra: STEP }));
  assert.ok(w, "the fixture work must be read");
  assert.equal(w.record_status, "missing");
});

test("a Completed work with a saved skill reads record_status inconsistent", () => {
  const w = readWorkFrom(
    stateText(INTENT_READ, { lifecycle: "Completed", extra: STEP }),
  );
  assert.ok(w, "the fixture work must be read");
  assert.equal(w.record_status, "inconsistent");
});

test("a Completed work without a saved skill reads record_status ok", () => {
  const w = readWorkFrom(
    stateText(INTENT_READ, { lifecycle: "Completed", activeSkill: "none", extra: STEP }),
  );
  assert.ok(w, "the fixture work must be read");
  assert.equal(w.record_status, "ok");
});

test("step and step_detail come through", () => {
  const w = readWorkFrom(stateText(INTENT_READ, { extra: STEP }));
  assert.ok(w, "the fixture work must be read");
  assert.equal(w.step, "3");
  assert.equal(w.step_detail, "review the diff");
  assert.equal(w.record_status, "ok");
  assert.equal(w.open_call, null);
});

test("a Skipped qa entry counts as open (pending_inputs)", () => {
  const w = readWorkFrom(stateText(INTENT_READ, { extra: STEP + QA }));
  assert.ok(w, "the fixture work must be read");
  assert.deepEqual(
    w.pending_inputs.map((p) => p.question_id),
    ["Q1", "Q2"],
  );
});
