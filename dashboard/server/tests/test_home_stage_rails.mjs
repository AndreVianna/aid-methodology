/**
 * dashboard/server/tests/test_home_stage_rails.mjs
 * Stage rail of dashboard/home.html (task-053, work-003 delivery-002, AC-41).
 *
 * Takes PHASE_ORDER and renderStageRail from home.html by name, runs them
 * inside a node:vm context against a small stand-in for the page (one
 * element with id "stage-rail"), and checks the stages drawn and the marked
 * stage.
 *
 * Tests:
 *   - PHASE_ORDER is the canonical five-phase rail.
 *   - A work with no Definition at Building: its own intent.phases draw the
 *     rail, and the Building stage (not the first one) is marked.
 *   - A work with no intent.phases draws PHASE_ORDER, and an empty
 *     intent.phases list does the same.
 *   - A Completed work marks Done, with every stage before it done.
 *   - A phase outside the rail shows the neutral not-yet-recorded sentinel.
 *
 * Run: node --test dashboard/server/tests/test_home_stage_rails.mjs
 *
 * Reads only dashboard/home.html. Deterministic: no clock, no environment.
 * ASCII-only source (the glyphs are written as \u escapes). Node built-in
 * modules only.
 */

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createContext, runInContext } from "node:vm";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HOME_HTML = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "home.html");
const PAGE = readFileSync(HOME_HTML, "utf8");

// Glyphs used by renderStageRail, as escapes so this source stays ASCII.
const DONE = "\u2713";     // check mark: prior stage
const CURRENT = "\u25B8";  // small triangle: current stage
const LATER = "\u25CB";    // white circle: upcoming stage
const NOT_YET = "\u2014 phase not yet recorded"; // em dash: sentinel

// Return the source of `var PHASE_ORDER = [...];` from the page.
function extractPhaseOrderSource(src) {
  const re = /var PHASE_ORDER = \[[^\]]*\];/g;
  const hits = src.match(re) || [];
  assert.equal(hits.length, 1, "home.html must declare PHASE_ORDER exactly once");
  return hits[0];
}

// Return the source of `function <name>(...) { ... }` from the page, by
// matching its braces. The function body holds no brace inside a string.
function extractFunctionSource(src, name) {
  const head = `function ${name}(`;
  assert.equal(src.split(head).length - 1, 1, `home.html must define ${name} exactly once`);
  const start = src.indexOf(head);
  const open = src.indexOf("{", start);
  let depth = 0;
  for (let i = open; i < src.length; i++) {
    if (src[i] === "{") depth++;
    else if (src[i] === "}") {
      depth--;
      if (depth === 0) return src.slice(start, i + 1);
    }
  }
  throw new Error(`unterminated function ${name} in home.html`);
}

const PHASE_ORDER_SRC = extractPhaseOrderSource(PAGE);
const RENDER_SRC = extractFunctionSource(PAGE, "renderStageRail");

// A stand-in for the page: one element with id "stage-rail".
function makeElement(tag) {
  return {
    tagName: tag,
    className: "",
    textContent: "",
    attributes: {},
    children: [],
    setAttribute(name, value) {
      this.attributes[name] = String(value);
    },
    appendChild(child) {
      this.children.push(child);
      return child;
    },
  };
}

function makePage() {
  const rail = makeElement("div");
  const document = {
    getElementById(id) {
      return id === "stage-rail" ? rail : null;
    },
    createElement(tag) {
      return makeElement(tag);
    },
  };
  // innerHTML = '' empties the rail, as a browser does.
  Object.defineProperty(rail, "innerHTML", {
    set(value) {
      if (value === "") this.children = [];
    },
    get() {
      return "";
    },
  });
  return { rail, document };
}

// Run the page's PHASE_ORDER and renderStageRail on one work; return the
// pills drawn, in order, as { text, current, className }.
function drawRail(work) {
  const { rail, document } = makePage();
  const context = createContext({ document });
  runInContext(`${PHASE_ORDER_SRC}\n${RENDER_SRC}`, context);
  context.renderStageRail(work);
  return rail.children.map((pill) => ({
    text: pill.textContent,
    current: pill.attributes["aria-current"],
    className: pill.className,
  }));
}

function currentStages(pills) {
  return pills.filter((p) => p.current === "step").map((p) => p.text);
}

test("PHASE_ORDER is the canonical five-phase rail", () => {
  const { document } = makePage();
  const context = createContext({ document });
  runInContext(PHASE_ORDER_SRC, context);
  assert.deepEqual(
    [...context.PHASE_ORDER],
    ["Definition", "Specification", "Planning", "Building", "CI"],
  );
});

test("a work with no Definition at Building marks the Building stage", () => {
  const pills = drawRail({
    lifecycle: "Running",
    phase: "Building",
    phases: ["Specification", "Planning", "Building", "CI"],
  });
  assert.deepEqual(
    pills.map((p) => p.text),
    [
      `${DONE} Specification`,
      `${DONE} Planning`,
      `${CURRENT} Building`,
      `${LATER} CI`,
      `${LATER} Done`,
    ],
  );
  assert.deepEqual(currentStages(pills), [`${CURRENT} Building`]);
  assert.equal(pills[2].className, "badge badge-primary");
});

test("a work with no intent.phases draws PHASE_ORDER", () => {
  const expected = [
    `${DONE} Definition`,
    `${DONE} Specification`,
    `${DONE} Planning`,
    `${CURRENT} Building`,
    `${LATER} CI`,
    `${LATER} Done`,
  ];
  for (const phases of [null, undefined, []]) {
    const pills = drawRail({ lifecycle: "Running", phase: "Building", phases });
    assert.deepEqual(pills.map((p) => p.text), expected, `phases=${JSON.stringify(phases)}`);
    assert.deepEqual(currentStages(pills), [`${CURRENT} Building`]);
  }
});

test("a Completed work marks Done, with every stage before it done", () => {
  const withoutPhases = drawRail({ lifecycle: "Completed", phase: "CI", phases: null });
  assert.deepEqual(
    withoutPhases.map((p) => p.text),
    [
      `${DONE} Definition`,
      `${DONE} Specification`,
      `${DONE} Planning`,
      `${DONE} Building`,
      `${DONE} CI`,
      `${CURRENT} Done`,
    ],
  );
  assert.deepEqual(currentStages(withoutPhases), [`${CURRENT} Done`]);

  const withPhases = drawRail({
    lifecycle: "Completed",
    phase: "Building",
    phases: ["Specification", "Planning", "Building", "CI"],
  });
  assert.deepEqual(
    withPhases.map((p) => p.text),
    [
      `${DONE} Specification`,
      `${DONE} Planning`,
      `${DONE} Building`,
      `${DONE} CI`,
      `${CURRENT} Done`,
    ],
  );
  assert.deepEqual(currentStages(withPhases), [`${CURRENT} Done`]);
});

test("a phase outside the rail shows the not-yet-recorded sentinel", () => {
  for (const phase of ["Describe", "Unknown", null]) {
    const pills = drawRail({ lifecycle: "Running", phase, phases: null });
    assert.equal(pills.length, 1, `phase=${phase}`);
    assert.equal(pills[0].text, NOT_YET);
    assert.equal(pills[0].className, "badge badge-dim");
    assert.equal(pills[0].current, undefined);
  }
});
