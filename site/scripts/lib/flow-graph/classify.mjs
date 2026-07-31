// classify.mjs — Body-inspection shape classifier.
//
// Classifies a skill into one of five shapes by inspecting the body text only.
// Discriminators D1-D5 are applied in strict first-match-wins precedence.
//
// Classification is by body-text inspection only. The shortcut catalog is
// never consulted — shape is an output of this classifier, not an input.
//
// Pure exported function; no import-time side effect, no filesystem access.

// ── Discriminator patterns ──────────────────────────────────────────────────

// D1: heading (level >= 2) whose text is exactly "Dispatch" or "State Machine".
const D1_HEADING_RE = /^(#{2,})\s+(Dispatch|State Machine)\s*$/;

// D1: terminates section scan; any heading of any level.
const D1_SECTION_END_RE = /^#+\s/;

// D2: ## State: followed by whitespace and at least one non-whitespace char.
const D2_STATE_RE = /^## State:\s+\S/;

// D3: phrase declaring no logic of its own (case-insensitive).
const D3_NO_LOGIC_RE = /no logic of its own/i;

// D3: a canonical/skills/<name>/SKILL.md reference; global copy created per call.
const D3_SIBLING_PATTERN = /canonical\/skills\/([^/\s]+)\/SKILL\.md/g;

// D4: GENERATED-by-build-shortcut-skills.py HTML comment.
const D4_GENERATED_RE = /<!--\s*GENERATED\s+by\s+[^\n]*build-shortcut-skills\.py/;

// D4: reference to shortcut-engine.md template.
const D4_ENGINE_REF = 'canonical/aid/templates/shortcut-engine.md';

// ── Internal helpers ────────────────────────────────────────────────────────

/**
 * Return the 1-based line number of character position `idx` within `text`.
 * @param {string} text
 * @param {number} idx  0-based character index.
 * @returns {number}
 */
function lineOf(text, idx) {
  return text.slice(0, idx).split('\n').length;
}

/**
 * D1 probe: find the first level->=2 heading whose text is exactly "Dispatch"
 * or "State Machine" AND whose section (up to the next heading) contains a
 * GFM table header row carrying both a "State" and an "Advance" column.
 *
 * A heading merely containing "Dispatch" (e.g. "## Dispatch Protocol") does
 * not match.  A heading followed by a table whose header lacks "Advance" (e.g.
 * "## Invocation Contract" with "Value | Source | Notes") does not match.
 *
 * @param {string} body
 * @returns {{ shape: 'dispatch-table', evidence: string[], delegatesTo: null } | null}
 */
function tryD1(body) {
  const lines = body.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const hm = lines[i].match(D1_HEADING_RE);
    if (!hm) continue;

    const headingText = hm[2]; // 'Dispatch' or 'State Machine'
    const headingLine = i + 1; // 1-based within body

    // Collect the section until the next heading of any level.
    let j = i + 1;
    while (j < lines.length && !D1_SECTION_END_RE.test(lines[j])) j++;

    // Locate the first GFM table row within the section.
    for (let k = i + 1; k < j; k++) {
      if (!lines[k].trimStart().startsWith('|')) continue;
      // This is the (candidate) header row.
      const cols = lines[k].split('|').map((c) => c.trim()).filter(Boolean);
      if (cols.includes('State') && cols.includes('Advance')) {
        return {
          shape: 'dispatch-table',
          evidence: [
            `D1 dispatch-table: heading '## ${headingText}' at body line ${headingLine}`,
            `table header: '${lines[k].trim()}' at body line ${k + 1}`,
          ],
          delegatesTo: null,
        };
      }
      // First pipe-row is the only candidate header; stop scanning this section.
      break;
    }
  }
  return null;
}

/**
 * D2 probe: two or more headings matching `^## State:\s+\S`.
 *
 * @param {string} body
 * @returns {{ shape: 'inline-states', evidence: string[], delegatesTo: null } | null}
 */
function tryD2(body) {
  const lines = body.split('\n');
  const hits = [];
  for (let i = 0; i < lines.length; i++) {
    if (D2_STATE_RE.test(lines[i])) {
      hits.push(`'${lines[i].trim()}' at body line ${i + 1}`);
    }
  }
  if (hits.length < 2) return null;
  return {
    shape: 'inline-states',
    evidence: [`D2 inline-states: ${hits.length} '## State:' heading(s)`, ...hits],
    delegatesTo: null,
  };
}

/**
 * D3 probe: body contains "no logic of its own" (case-insensitive) AND
 * references exactly one distinct canonical/skills/<name>/SKILL.md target.
 *
 * Multiple occurrences of the same target count as one distinct reference.
 *
 * @param {string} body
 * @returns {{ shape: 'sibling-doorway', evidence: string[], delegatesTo: string } | null}
 */
function tryD3(body) {
  const nlm = D3_NO_LOGIC_RE.exec(body);
  if (!nlm) return null;
  const noLogicLine = lineOf(body, nlm.index);

  // Collect all distinct skill names referenced via canonical/skills/<name>/SKILL.md.
  const re = new RegExp(D3_SIBLING_PATTERN.source, 'g');
  const names = new Set();
  let m;
  while ((m = re.exec(body)) !== null) names.add(m[1]);

  if (names.size !== 1) return null;
  const delegatesTo = [...names][0];

  return {
    shape: 'sibling-doorway',
    evidence: [
      `D3 sibling-doorway: 'no logic of its own' at body line ${noLogicLine}`,
      `single SKILL.md reference: canonical/skills/${delegatesTo}/SKILL.md (delegatesTo: '${delegatesTo}')`,
    ],
    delegatesTo,
  };
}

/**
 * D4 probe: a GENERATED-by-build-shortcut-skills.py HTML comment in the body,
 * OR a reference to canonical/aid/templates/shortcut-engine.md.
 *
 * @param {string} body
 * @returns {{ shape: 'engine-doorway', evidence: string[], delegatesTo: null } | null}
 */
function tryD4(body) {
  const gm = D4_GENERATED_RE.exec(body);
  if (gm) {
    return {
      shape: 'engine-doorway',
      evidence: [`D4 engine-doorway: GENERATED comment at body line ${lineOf(body, gm.index)}`],
      delegatesTo: null,
    };
  }
  const ei = body.indexOf(D4_ENGINE_REF);
  if (ei !== -1) {
    return {
      shape: 'engine-doorway',
      evidence: [
        `D4 engine-doorway: reference to '${D4_ENGINE_REF}' at body line ${lineOf(body, ei)}`,
      ],
      delegatesTo: null,
    };
  }
  return null;
}

// ── Public API ──────────────────────────────────────────────────────────────

/**
 * @typedef {'dispatch-table'|'inline-states'|'sibling-doorway'|'engine-doorway'|'residual'} Shape
 */

/**
 * @typedef {object} Classification
 * @property {Shape}        shape        The discriminated shape.
 * @property {string[]}     evidence     Human-readable strings naming what triggered the
 *                                       classification (discriminator + body construct +
 *                                       1-based body line), suitable for diagnosing a
 *                                       misclassification without re-reading the source.
 * @property {string|null}  delegatesTo  Parent skill's directory name for a D3
 *                                       (sibling-doorway) match; `null` for every other
 *                                       shape — never `undefined`, never absent.
 */

/**
 * Classify the shape of a skill by inspecting its body text only.
 *
 * Discriminators are applied in strict first-match-wins precedence:
 *   D1 dispatch-table  → level->=2 heading "Dispatch" or "State Machine" followed
 *                         by a GFM table with both "State" and "Advance" columns.
 *   D2 inline-states   → two or more `## State: <name>` headings.
 *   D3 sibling-doorway → "no logic of its own" phrase AND exactly one distinct
 *                         canonical/skills/<name>/SKILL.md reference.
 *   D4 engine-doorway  → GENERATED-by-build-shortcut-skills.py comment OR a
 *                         reference to canonical/aid/templates/shortcut-engine.md.
 *   D5 residual        → none of the above.
 *
 * Classification is total: every input produces exactly one shape.
 *
 * This function is keyed on body inspection only. Skills like `aid-review`
 * (full state machine) classify as inline-states. `aid-test-security` (a thin
 * delegation skill) classifies as sibling-doorway. Neither catalog flag
 * nor catalog row content is read or consulted.
 *
 * @param {{ name: string, dir: string, frontmatter: object, body: string }} skill
 *   `body` is the SKILL.md text after the closing frontmatter fence.
 * @returns {Classification}
 */
export function classifySkill({ name, dir, frontmatter, body }) {
  return (
    tryD1(body) ??
    tryD2(body) ??
    tryD3(body) ??
    tryD4(body) ?? {
      shape: 'residual',
      evidence: ['D5 residual: no D1-D4 discriminator matched'],
      delegatesTo: null,
    }
  );
}
