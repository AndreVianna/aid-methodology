// extract-engine.mjs — Engine-doorway extractor (feature-004, shape 3).
//
// Entry: extractEngineDoorway(skillRecord) → FlowChart
//        RESOLUTION_NOTICE — prose string; body provider emits above the fence.
//
// Builds a one-node prefix from readDoorwayBinding (compose.mjs), then
// composes it with getEngineCore() (engine-core.mjs) through composeDoorwayChart
// (compose.mjs).
//
// This module defines no model, no validator, no renderer, and no substrate.
// It consumes feature-003's as published: validateChart, renderMermaid,
// truncate, makeNode, makeEdge, and buildProvenance — all unchanged.
//
// Pure exports — no import-time side effect.

import { truncate, makeNode, makeEdge } from './model.mjs';
import { readDoorwayBinding, composeDoorwayChart } from './compose.mjs';
import { getEngineCore } from './engine-core.mjs';
import { GITHUB_BLOB_BASE } from '../../skills/paths.mjs';

// ── Constants ────────────────────────────────────────────────────────────────

/** Repo-relative path of the shared shortcut engine (mirrors engine-core.mjs). */
const ENGINE_TEMPLATE_REL = 'canonical/aid/templates/shortcut-engine.md';

/**
 * One-line prose notice for engine-doorway pages.
 *
 * Emitted **above** the Mermaid fence by the body provider (task-037) so
 * readers do not conclude the skill owns APPROVAL-HALT. Not a chart node —
 * feature-006's nodeById lookup never sees it and its cost is zero.
 *
 * Carries a GITHUB_BLOB_BASE link to the shared engine's canonical/ source,
 * matching the link format feature-001 uses for the same file.
 */
export const RESOLUTION_NOTICE =
  `> Derived from the [shared shortcut engine](${GITHUB_BLOB_BASE}/${ENGINE_TEMPLATE_REL}),` +
  ` which this doorway binds and runs.`;

// ── Extractor ─────────────────────────────────────────────────────────────────

/**
 * Extract a FlowChart for an engine-doorway skill (shape: 'engine-doorway').
 *
 * The prefix is exactly one node — the doorway itself — with:
 *   name  = skill directory name (the engine's `{name}` invocation parameter)
 *   label = "Bind VERB=<verb>, ARTIFACT=<artifact>" truncated to 60 code points
 *   kind  = 'entry'
 *   provenance = the single Bind-clause body line, sourceKind: 'skill'
 *
 * The hop edge is `sequence` with `condition: null`: a generated doorway
 * binds and runs the engine unconditionally.
 *
 * The composed chart has entries: ['n1'] and nodes n1…n10 (one prefix node
 * followed by the nine engine-segment nodes, including the two B1 nodes in
 * their deterministic positions as established by engine-core.mjs).
 *
 * @param {object} skillRecord  SkillRecord as produced by discover.mjs
 * @param {string} skillRecord.dirName        Skill directory name (e.g. 'aid-create-api')
 * @param {string} skillRecord.sourcePath     Repo-root-relative POSIX path to SKILL.md
 * @param {string} skillRecord.body           Body text (after frontmatter closing fence)
 * @param {number} skillRecord.bodyStartLine  1-based file line of body[0]
 * @returns {import('./model.mjs').FlowChart}
 */
export function extractEngineDoorway(skillRecord) {
  const { dirName: skill, sourcePath: file, body, bodyStartLine } = skillRecord;

  // ── 1. Read the doorway binding from the Bind clause ─────────────────────
  const binding = readDoorwayBinding({ body, bodyStartLine, sourcePath: file });

  // ── 2. Build the prefix node label ───────────────────────────────────────
  // The bare-verb form `ARTIFACT="" (bare verb)` is carried verbatim as
  // written in the source — it is one of the two binding forms the engine's
  // Invocation Contract defines, and the test fixture for aid-fix relies on it.
  const artifactPart = binding.provenance.excerpt.includes('"" (bare verb)')
    ? 'ARTIFACT="" (bare verb)'
    : `ARTIFACT=${binding.artifact}`;
  const label = truncate(`Bind VERB=${binding.verb}, ${artifactPart}`, 60);

  // ── 3. Build the prefix node ─────────────────────────────────────────────
  // id = 'n1' and kind = 'entry' are set explicitly because makeNode (per
  // model.mjs) returns a raw node without those fields — they are normally
  // assigned by buildChart. composeDoorwayChart reads prefixNodes[0].id
  // directly when computing entries, so both fields must be present.
  const prefixNode = {
    ...makeNode({
      order:      1,
      name:       skill,
      label,
      provenance: binding.provenance,
      terminal:   null,
      detail:     null,
    }),
    id:   'n1',
    kind: 'entry',
  };

  // ── 4. Get the engine core (deeply frozen, memoized) ─────────────────────
  const core = getEngineCore();

  // ── 5. Build the hop edge ─────────────────────────────────────────────────
  // kind: 'sequence', condition: null — unconditional binding and run.
  //
  // Target id is 'n2': the core's first node (INTAKE, c1, order = 1) will be
  // remapped to 'n' + (1 + offset) = 'n2' by composeDoorwayChart. prefixEdges
  // are shallow-copied as-is (NOT remapped), so we pre-compute the composed id
  // here rather than using 'c1'.
  const hopEdge = makeEdge({
    from:        'n1',
    to:          'n2',
    kind:        'sequence',
    condition:   null,
    advanceType: 'CHAIN',
    provenance:  binding.provenance,
  });

  // ── 6. Compose and return ─────────────────────────────────────────────────
  return composeDoorwayChart({
    skill,
    prefixNodes: [prefixNode],
    prefixEdges: [hopEdge],
    core,
    confidence:  'derived',
    shape:       'engine-doorway',
    extractor:   'extract-engine',
  });
}
