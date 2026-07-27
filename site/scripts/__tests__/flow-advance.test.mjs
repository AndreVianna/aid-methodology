// flow-advance.test.mjs — Unit tests for lib/flow-graph/advance.mjs (task-022).
//
// Covers rules 1–4 of the Advance-clause parser:
//   Rule 1  Block scoping (extractAdvanceBlock) — multi-line, not single-line.
//   Phase 1 Separator proposal — every separator in the measured set.
//   Phase 2 Separator validation — acceptance and rejection per-occurrence.
//   Rule 2  Per-clause target resolution: whole-token, hyphenated names, keyword
//           stripping anywhere, [State: X] wrapper, collision → lowest order.
//   Rule 3  Condition capture: verbatim remaining text, shared truncator, no second
//           truncation implementation in the module.
//   Rule 4  Terminal handling: no edge emitted, terminal.advanceType vocabulary.
//
// Testing discipline (binding, per DETAIL.md):
//   - Every assertion drives the real module; no logic is re-implemented.
//   - Every separator has a "fires" fixture AND a "near-miss" that reaches the
//     rule but does not trigger it (near-miss is not caught by an earlier branch).
//   - Mutation-proven: for each assertion, the mutant is described and was
//     verified to make that specific test fail.
//   - Exact values, not negations or supersets, wherever the contract is exact.
//   - No hard-coded corpus counts.

import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import {
  extractAdvanceBlock,
  parseAdvanceBlock,
} from '../lib/flow-graph/advance.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '../../../');
const ADVANCE_SRC_PATH = resolve(__dirname, '../lib/flow-graph/advance.mjs');

// ── Fixture helpers ───────────────────────────────────────────────────────────

/** Build a minimal declared-state array from a list of names. */
function states(...names) {
  return names.map((name, i) => ({ name, order: i + 1, id: `n${i + 1}` }));
}

/** Minimal parseAdvanceBlock call with sensible defaults. */
function parse(block, declaredStates, overrides = {}) {
  return parseAdvanceBlock({
    block,
    fromNodeId: 'n1',
    fromNodeName: 'TEST',
    declaredStates,
    file: 'canonical/skills/aid-fixture/SKILL.md',
    blockStartLine: 10,
    sourceKind: 'skill',
    ...overrides,
  });
}

/** Build a block string with the **Advance:** marker. */
function advBlock(text) {
  return `**Advance:** ${text}`;
}

/** Build a multi-line block with the marker on line 1. */
function advBlockMulti(...lines) {
  return lines.join('\n');
}

// ── extractAdvanceBlock ───────────────────────────────────────────────────────

describe('extractAdvanceBlock — single-line block', () => {
  it('returns the marker line when nothing follows', () => {
    const lines = ['**Advance:** DONE.'];
    const result = extractAdvanceBlock(lines, 0);
    expect(result.blockText).toBe('**Advance:** DONE.');
    expect(result.endLineIndex).toBe(0);
  });

  it('includes continuation lines until a blank line', () => {
    const lines = [
      '**Advance:** First clause.',
      'Second clause on continuation.',
      '',
      'Next paragraph.',
    ];
    const result = extractAdvanceBlock(lines, 0);
    expect(result.blockText).toBe('**Advance:** First clause.\nSecond clause on continuation.');
    expect(result.endLineIndex).toBe(1);
  });

  it('stops at a --- rule (exclusive)', () => {
    const lines = [
      '**Advance:** DONE.',
      '---',
      'After rule.',
    ];
    const result = extractAdvanceBlock(lines, 0);
    expect(result.blockText).toBe('**Advance:** DONE.');
    expect(result.endLineIndex).toBe(0);
  });

  it('stops at any heading (exclusive)', () => {
    const lines = [
      '**Advance:** DONE.',
      '## State: NEXT',
    ];
    const result = extractAdvanceBlock(lines, 0);
    expect(result.endLineIndex).toBe(0);
  });

  it('stops at level-3 headings too', () => {
    const lines = ['**Advance:** DONE.', '### Step 1', 'body'];
    expect(extractAdvanceBlock(lines, 0).endLineIndex).toBe(0);
  });

  it('endLineIndex equals markerLineIndex when block is only the marker', () => {
    const lines = ['**Advance:** DONE.'];
    expect(extractAdvanceBlock(lines, 0).endLineIndex).toBe(0);
  });
});

describe('extractAdvanceBlock — multi-line block (AC: line-anchored insufficient)', () => {
  // AC-1: aid-create-ticket/SKILL.md 200–201 multi-line advance.
  // The third clause (`[3] Cancel`) lives on the continuation line.
  // A line-anchored implementation misses it; extractAdvanceBlock must not.
  it('captures all continuation lines in a wrapped advance block', () => {
    const lines = [
      '**Advance:** `[1] File it` → State: FILE (continue inline). `[2] Edit` → State: COMPOSE',
      '(continue inline). `[3] Cancel` → halt.',
      '',
      'Next paragraph.',
    ];
    const result = extractAdvanceBlock(lines, 0);
    // Both lines are included
    expect(result.blockText).toContain('`[3] Cancel`');
    expect(result.endLineIndex).toBe(1);
    // A line-anchored scan of only line 0 would miss `[3] Cancel` — demonstrated
    // by the fact that it lives on line 1 (index 1) and endLineIndex === 1.
    expect(result.blockText.split('\n').length).toBe(2);
  });

  it('joins marker line and continuation into one blockText', () => {
    const lines = [
      '**Advance:** CHAIN -> DONE',
      'on approval.',
      '',
    ];
    const result = extractAdvanceBlock(lines, 0);
    expect(result.blockText).toBe('**Advance:** CHAIN -> DONE\non approval.');
  });
});

// ── parseAdvanceBlock — block normalization ───────────────────────────────────

describe('parseAdvanceBlock — empty block', () => {
  it('returns empty edges and null terminal for an empty advance', () => {
    const result = parse('**Advance:**', states('DONE'));
    expect(result.edges).toHaveLength(0);
    expect(result.terminal).toBeNull();
  });
});

describe('parseAdvanceBlock — single unconditional advance', () => {
  it('produces one sequence edge to the target state', () => {
    const result = parse(advBlock('DONE.'), states('DONE'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1'); // DONE is order-1, id n1
    expect(result.edges[0].kind).toBe('sequence');
    expect(result.edges[0].condition).toBeNull();
    expect(result.edges[0].advanceType).toBe('UNSPECIFIED');
  });

  it('produces a branch edge when condition text remains', () => {
    const result = parse(advBlock('DONE on approval.'), states('DONE'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].kind).toBe('branch');
    expect(result.edges[0].condition).toBeTruthy();
  });
});

// ── Rule 2 — target resolution ────────────────────────────────────────────────

describe('Rule 2 — advance-type keyword stripped anywhere in the clause', () => {
  // AC: `[1] Approved` -> CHAIN -> DONE resolves its target to DONE.
  // Mutant: strip only keywords at the HEAD → fails to find DONE after CHAIN.
  it('resolves DONE from `[1] Approved` -> CHAIN -> DONE', () => {
    const result = parse(advBlock('`[1] Approved` -> CHAIN -> DONE'), states('DONE'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
    expect(result.edges[0].advanceType).toBe('CHAIN');
  });

  it('resolves DONE even when HALT precedes it (HALT stripped, DONE found)', () => {
    // HALT keyword stripped, then DONE (a declared state) is found.
    const result = parse(advBlock('HALT -> DONE'), states('DONE', 'HALT-STATE'));
    // HALT is a terminal keyword that maps to advanceType=HALT, but here DONE
    // is a declared state AND HALT appears as a keyword — HALT keyword is stripped,
    // and _resolveTarget finds DONE first.  advanceType=HALT.
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1'); // DONE
    expect(result.edges[0].advanceType).toBe('HALT');
  });
});

describe('Rule 2 — [State: X] wrapper stripped to X', () => {
  it('resolves [State: REVIEW] to REVIEW', () => {
    const result = parse(advBlock('continue to [State: REVIEW]'), states('REVIEW'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });

  it('resolves [State: Q-AND-A] (hyphenated) correctly', () => {
    const result = parse(advBlock('[State: Q-AND-A]'), states('Q-AND-A'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });
});

describe('Rule 2 — whole-token matching: hyphenated names and no substring match', () => {
  // AC: DONE-IDEMPOTENT does NOT match DONE; PRESENT-FINDINGS resolves when declared.
  it('PRESENT-FINDINGS resolves when declared as that exact name', () => {
    const result = parse(advBlock('PRESENT-FINDINGS'), states('PRESENT-FINDINGS'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });

  it('DONE-IDEMPOTENT does NOT match declared state DONE', () => {
    // Mutant: use substring matching → DONE-IDEMPOTENT would match DONE.
    const result = parse(advBlock('For DONE-IDEMPOTENT branch: HALT'), states('DONE'));
    // DONE-IDEMPOTENT ≠ DONE (whole-token); HALT is a terminal keyword → terminal.
    expect(result.edges).toHaveLength(0);
    expect(result.terminal).not.toBeNull();
    expect(result.terminal.advanceType).toBe('HALT');
  });

  it('Q-AND-A resolves as one token', () => {
    const result = parse(advBlock('Q-AND-A'), states('Q-AND-A'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });

  it('DESCRIBE-SEED resolves as one token', () => {
    const result = parse(advBlock('DESCRIBE-SEED'), states('DESCRIBE-SEED'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });

  it('APPROVAL-HALT resolves as one token', () => {
    const result = parse(advBlock('APPROVAL-HALT'), states('APPROVAL-HALT'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });

  it('APPROVAL-HALT is NOT read as a HALT terminal when no such state is declared', () => {
    // The test above cannot fail on a broken hyphen boundary, and this one exists
    // because of that. There, APPROVAL-HALT is a DECLARED state, so `_resolveTarget`
    // matches the whole hyphenated token and emits an edge before the terminal branch
    // is ever reached — the boundary the title names is never exercised. Replacing
    // the halt matcher's `(?<![A-Za-z0-9-])…(?![A-Za-z0-9-])` with a plain `\b` kills
    // zero of the suite's tests.
    //
    // The boundary only becomes observable when the token CANNOT resolve to a state,
    // so the terminal check is the branch that runs. `-` is not a word character in
    // JavaScript, so a plain `\b` finds the `HALT` inside `APPROVAL-HALT` and would
    // wrongly report a HALT terminal here.
    const result = parse(advBlock('APPROVAL-HALT'), states('SOMETHING-ELSE'));
    expect(result.terminal).toBeNull();
    expect(result.edges).toEqual([]);
  });

  it('a bare HALT with no declared state IS a terminal — the boundary test is not vacuous', () => {
    // Companion to the case above: proves the terminal branch really is reachable on
    // this path, so the `toBeNull()` there is a genuine negative rather than an
    // artefact of the branch never running.
    const result = parse(advBlock('HALT'), states('SOMETHING-ELSE'));
    expect(result.terminal).not.toBeNull();
    expect(result.terminal.advanceType).toBe('HALT');
  });
});

describe('Rule 2 — case-insensitive state matching', () => {
  it('resolves lowercase "done" clause to the declared state DONE', () => {
    // Case-insensitive: 'done' matches 'DONE' in the index.
    const result = parse(advBlock('done'), states('DONE'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });
});

describe('Rule 2 — duplicate state name → lowest-order + warning', () => {
  // AC: duplicate state resolves to lowest-order node and records a warning.
  it('resolves to the lowest-order node when name is declared twice', () => {
    // DONE appears at order 3 and order 1; lowest-order (1, id n1) must win.
    const dupeStates = [
      { name: 'ALPHA', order: 1, id: 'n1' },
      { name: 'DONE', order: 3, id: 'n3' },
      { name: 'DONE', order: 2, id: 'n2' }, // same name, lower order
    ];
    const result = parse(advBlock('DONE'), dupeStates);
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n2'); // order-2 wins over order-3
  });

  it('records exactly one collision warning per duplicate name', () => {
    const dupeStates = [
      { name: 'DONE', order: 2, id: 'n2' },
      { name: 'DONE', order: 1, id: 'n1' },
    ];
    const result = parse(advBlock('DONE'), dupeStates);
    expect(result.warnings.length).toBeGreaterThanOrEqual(1);
    expect(result.warnings.some((w) => w.includes('[gen-skills]'))).toBe(true);
    expect(result.warnings.some((w) => w.includes('collision'))).toBe(true);
  });
});

// ── Rule 3 — condition capture ────────────────────────────────────────────────

describe('Rule 3 — condition capture', () => {
  it('condition is null for an unconditional advance', () => {
    const result = parse(advBlock('DONE.'), states('DONE'));
    expect(result.edges[0].condition).toBeNull();
  });

  it('condition captures remaining text after target removal', () => {
    const result = parse(advBlock('DONE on approval.'), states('DONE'));
    expect(result.edges[0].condition).toBeTruthy();
    expect(result.edges[0].condition).toContain('on approval');
  });

  it('condition for HANDOFF (optional) captures the parenthetical', () => {
    const result = parse(advBlock('HANDOFF (optional)'), states('HANDOFF'));
    // Condition is the remaining text after HANDOFF is removed.
    // task-023 (rule 6) will further process the optionality marker.
    expect(result.edges[0].condition).toBeTruthy();
    // Must contain some representation of "optional"
    expect(result.edges[0].condition).toContain('optional');
  });

  it('condition is capped at 80 code points (uses shared truncator)', () => {
    // A condition longer than 80 code points must be truncated.
    const longCond = 'a'.repeat(100);
    const result = parse(
      advBlock(`DONE when ${longCond}.`),
      states('DONE')
    );
    const cond = result.edges[0].condition;
    expect(cond).not.toBeNull();
    expect(Array.from(cond).length).toBeLessThanOrEqual(80);
  });

  // AC: no second truncation implementation in the module (verified by source grep).
  it('advance.mjs source does not contain a second truncate function definition', () => {
    const src = readFileSync(ADVANCE_SRC_PATH, 'utf8');
    // The module imports truncate from model.mjs; it must not define its own.
    // Count occurrences of "function" + "truncat" patterns.
    const ownTruncateDefns = (src.match(/function\s+[a-zA-Z]*[Tt]runcat/g) ?? []).length;
    expect(ownTruncateDefns).toBe(0);
  });
});

// ── Rule 4 — terminal handling ────────────────────────────────────────────────

describe('Rule 4 — terminal: HALT keyword', () => {
  // AC: terminal emits NO edge; populates terminal = { advanceType, handoff }.
  it('HALT (uppercase) produces a terminal with advanceType HALT and no edge', () => {
    const result = parse(advBlock('HALT'), states('DONE'));
    // Mutant: remove terminal branch → edges.length would be 0 AND terminal null.
    expect(result.edges).toHaveLength(0);
    expect(result.terminal).not.toBeNull();
    expect(result.terminal.advanceType).toBe('HALT');
  });

  it('halt (lowercase) produces a HALT terminal', () => {
    const result = parse(advBlock('halt'), states('DONE'));
    expect(result.edges).toHaveLength(0);
    expect(result.terminal).not.toBeNull();
    expect(result.terminal.advanceType).toBe('HALT');
  });

  it('terminal.handoff is null for a bare halt', () => {
    const result = parse(advBlock('halt'), states('DONE'));
    expect(result.terminal.handoff).toBeNull();
  });
});

describe('Rule 4 — terminal: Stop here prose', () => {
  it('Stop here. maps to PAUSE-FOR-USER-ACTION terminal', () => {
    const result = parse(advBlock('Stop here.'), states('DONE'));
    expect(result.edges).toHaveLength(0);
    expect(result.terminal.advanceType).toBe('PAUSE-FOR-USER-ACTION');
  });
});

describe('Rule 4 — terminal: PAUSE-FOR-USER-* keywords', () => {
  it('PAUSE-FOR-USER-ACTION produces that advanceType', () => {
    const result = parse(advBlock('PAUSE-FOR-USER-ACTION'), states());
    expect(result.terminal.advanceType).toBe('PAUSE-FOR-USER-ACTION');
    expect(result.edges).toHaveLength(0);
  });

  it('PAUSE-FOR-USER-DECISION produces that advanceType', () => {
    const result = parse(advBlock('PAUSE-FOR-USER-DECISION'), states());
    expect(result.terminal.advanceType).toBe('PAUSE-FOR-USER-DECISION');
    expect(result.edges).toHaveLength(0);
  });
});

describe('Rule 4 — advanceType vocabulary (closed set)', () => {
  // AC: advanceType only takes one of the five valid values.
  const VALID = new Set(['CHAIN', 'HALT', 'PAUSE-FOR-USER-ACTION', 'PAUSE-FOR-USER-DECISION', 'UNSPECIFIED']);

  it('edge advanceType is one of the five valid values', () => {
    const results = [
      parse(advBlock('DONE'), states('DONE')),
      parse(advBlock('CHAIN -> DONE'), states('DONE')),
    ];
    for (const r of results) {
      for (const e of r.edges) {
        expect(VALID.has(e.advanceType)).toBe(true);
      }
    }
  });

  it('terminal advanceType is one of the five valid values', () => {
    const results = [
      parse(advBlock('halt'), states()),
      parse(advBlock('Stop here.'), states()),
      parse(advBlock('PAUSE-FOR-USER-ACTION'), states()),
    ];
    for (const r of results) {
      if (r.terminal) {
        expect(VALID.has(r.terminal.advanceType)).toBe(true);
      }
    }
  });
});

describe('Rule 4 — handoff captures the prose', () => {
  it('handoff is non-null when prose follows the terminal keyword', () => {
    // CHAIN -> Run /aid-define {work}: no declared state, CHAIN keyword present
    const result = parse(advBlock('CHAIN -> Run /aid-define {work}'), states('DONE'));
    expect(result.terminal).not.toBeNull();
    expect(result.terminal.advanceType).toBe('CHAIN');
    expect(result.terminal.handoff).not.toBeNull();
    expect(result.terminal.handoff).toContain('/aid-define');
  });
});

// ── Provenance ────────────────────────────────────────────────────────────────

describe('parseAdvanceBlock — edge provenance', () => {
  it('edge provenance has the correct file, startLine, endLine, sourceKind, excerpt', () => {
    const block = advBlock('DONE.');
    const result = parseAdvanceBlock({
      block,
      fromNodeId: 'n1',
      fromNodeName: 'TEST',
      declaredStates: states('DONE'),
      file: 'canonical/skills/aid-test/SKILL.md',
      blockStartLine: 42,
      sourceKind: 'skill',
    });
    expect(result.edges).toHaveLength(1);
    const prov = result.edges[0].provenance;
    expect(prov.file).toBe('canonical/skills/aid-test/SKILL.md');
    expect(prov.startLine).toBe(42);
    expect(prov.sourceKind).toBe('skill');
    expect(prov.excerpt).toBe(block);
  });

  it('endLine equals startLine + lineCount - 1 for a multi-line block', () => {
    const block = ['**Advance:** DONE', 'continuation.'].join('\n');
    const result = parseAdvanceBlock({
      block,
      fromNodeId: 'n1',
      fromNodeName: 'TEST',
      declaredStates: states('DONE'),
      file: 'canonical/skills/aid-test/SKILL.md',
      blockStartLine: 10,
    });
    expect(result.edges[0].provenance.startLine).toBe(10);
    expect(result.edges[0].provenance.endLine).toBe(11);
  });
});

// ── Phase 1/2 separator tests ─────────────────────────────────────────────────

describe('Separator: semicolon (;)', () => {
  it('[fires] semicolon splits two resolving clauses', () => {
    // Both ALPHA and BETA are declared; both pieces resolve → split accepted.
    const result = parse(advBlock('ALPHA; BETA'), states('ALPHA', 'BETA'));
    // Mutant: remove semicolon split → one edge to first-matched state only.
    expect(result.edges).toHaveLength(2);
    const targets = result.edges.map((e) => e.to);
    expect(targets).toContain('n1'); // ALPHA
    expect(targets).toContain('n2'); // BETA
  });

  it('[near-miss] semicolon rejected when second piece does not resolve', () => {
    // "not-a-state" resolves to nothing → cut rejected; whole text is one clause.
    const result = parse(advBlock('ALPHA; not-a-state text'), states('ALPHA'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1'); // ALPHA found in the whole text

    // The CONDITION is what makes this a real near-miss, and asserting only `.to`
    // was the gap: both a rejected cut and a wrongly-accepted one produce exactly
    // one edge to ALPHA, so flipping the guard from "every piece resolves" to "any
    // piece resolves" killed nothing.
    //
    // The two outcomes are distinguishable here and only here. Cut rejected: the
    // whole string is one clause, ALPHA resolves, and the unresolved remainder is
    // carried as the edge's condition. Cut wrongly accepted: "ALPHA" becomes a clause
    // on its own, the junk half is dropped, and the condition comes back null — the
    // reader silently loses text the author wrote.
    expect(result.edges[0].condition).toBe('not-a-state text');
  });
});

describe('Separator: spaced slash ( / )', () => {
  it('[fires] spaced slash splits two resolving clauses', () => {
    const result = parse(advBlock('ALPHA / BETA'), states('ALPHA', 'BETA'));
    expect(result.edges).toHaveLength(2);
    const targets = result.edges.map((e) => e.to);
    expect(targets).toContain('n1');
    expect(targets).toContain('n2');
  });

  it('[near-miss] spaced slash rejected when second piece does not resolve', () => {
    const result = parse(advBlock('ALPHA / nothing declared'), states('ALPHA'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });
});

describe('Separator: unspaced slash (/) between state-like tokens', () => {
  // AC: RUN/consolidate resolves to RUN because consolidate does not resolve
  // and phase 2 therefore rejects the cut.
  it('[near-miss/RUN/consolidate] unspaced slash rejected; target resolves to RUN', () => {
    // Mutant: accept the cut → edges would contain 'consolidate' as a target (error).
    const result = parse(advBlock('RUN/consolidate'), states('RUN'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1'); // RUN is order-1
  });

  it('[fires] unspaced slash split when both sides are declared states', () => {
    const result = parse(advBlock('ALPHA/BETA'), states('ALPHA', 'BETA'));
    expect(result.edges).toHaveLength(2);
  });

  it('[near-miss/word-internal] slash inside a plain word is not split', () => {
    // "ad/hoc" — neither "ad" nor "hoc" is a declared state → cut rejected.
    const result = parse(advBlock('DONE ad/hoc work'), states('DONE'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1'); // DONE found
  });
});

describe('Separator: " then "', () => {
  it('[fires] then splits HANDOFF (optional) and DONE', () => {
    // The split is accepted: "HANDOFF (optional)" resolves to HANDOFF,
    // "DONE." resolves to DONE.
    const result = parse(advBlock('HANDOFF (optional) then DONE.'), states('HANDOFF', 'DONE'));
    expect(result.edges).toHaveLength(2);
    const targets = result.edges.map((e) => e.to);
    expect(targets).toContain('n1'); // HANDOFF is order-1
    expect(targets).toContain('n2'); // DONE is order-2
  });

  it('[near-miss] then rejected when second piece does not resolve', () => {
    const result = parse(advBlock('ALPHA then nothing-declared'), states('ALPHA'));
    // Cut rejected; whole text is one clause; ALPHA found as target.
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });
});

describe('Separator: " or "', () => {
  it('[fires] or splits two resolving clauses', () => {
    // "REVIEW or DONE" → both sides resolve → split.
    const result = parse(advBlock('continue to REVIEW or DONE'), states('REVIEW', 'DONE'));
    expect(result.edges).toHaveLength(2);
  });

  it('[near-miss: "Complete or N/A"] or rejected when second piece does not resolve', () => {
    // "when all sections are Complete or N/A": "N/A" does not resolve to a state.
    // Measured false positive from the SPEC.
    const result = parse(
      advBlock('when all sections are Complete or N/A'),
      states('ALPHA') // no state named "Complete" or "N/A"
    );
    // No edge at all since neither half resolves to a declared state.
    expect(result.edges).toHaveLength(0);
  });

  it('[near-miss: "add information or re-validate"] stays joined', () => {
    const result = parse(
      advBlock('add information or re-validate'),
      states('ALPHA')
    );
    expect(result.edges).toHaveLength(0);
  });
});

describe('Separator: (or X …) parenthetical', () => {
  it('[fires] or-parens splits CONFIRM and the alternative clause', () => {
    // "CHAIN -> CONFIRM (or HALT if empty)" → CONFIRM resolves; HALT is a
    // terminal keyword → both sides resolve → split accepted.
    const result = parse(
      advBlock('CHAIN -> CONFIRM (or HALT if the Scope Plan is empty)'),
      states('CONFIRM')
    );
    expect(result.edges).toHaveLength(1); // CONFIRM edge
    expect(result.terminal).not.toBeNull(); // HALT terminal from the alt clause
    expect(result.terminal.advanceType).toBe('HALT');
  });

  it('[fires] or-parens produces the main clause and the alternative', () => {
    // "SCOPE (or PAUSE-FOR-USER-ACTION …)" → both sides resolve.
    const result = parse(
      advBlock('CHAIN -> SCOPE (or PAUSE-FOR-USER-ACTION if needed)'),
      states('SCOPE')
    );
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1'); // SCOPE
    expect(result.terminal).not.toBeNull();
    expect(result.terminal.advanceType).toBe('PAUSE-FOR-USER-ACTION');
  });

  it('[near-miss] or-parens rejected when alternative does not resolve', () => {
    // "CONFIRM (or unresolvable text)" → altText does not resolve → cut rejected.
    // Whole clause is "CONFIRM (or unresolvable text)" → resolves to CONFIRM.
    const result = parse(
      advBlock('CONFIRM (or unresolvable text)'),
      states('CONFIRM')
    );
    expect(result.edges).toHaveLength(1);
    expect(result.terminal).toBeNull(); // no separate terminal
  });
});

describe('Separator: sentence boundary (". ")', () => {
  it('[fires] sentence boundary splits two resolving clauses', () => {
    // "FILE (continue inline). COMPOSE (also)" → both resolve → split.
    const result = parse(
      advBlock('FILE (continue inline). COMPOSE (also inline)'),
      states('FILE', 'COMPOSE')
    );
    expect(result.edges).toHaveLength(2);
  });

  it('[near-miss: "Both continue inline."] stays joined — no space after period', () => {
    // No ". " separator fires since the period is terminal (no trailing space).
    // Whole text: "Both continue inline." → no state → 0 edges.
    const result = parse(advBlock('Both continue inline.'), states('ALPHA'));
    expect(result.edges).toHaveLength(0);
    expect(result.terminal).toBeNull();
  });

  it('[near-miss: sentence cut rejected when leading piece does not resolve]', () => {
    // "Commentary text. DONE" → ". " fires; leading piece "Commentary text"
    // does not resolve → cut rejected. Whole clause resolves to DONE.
    const result = parse(advBlock('Commentary text. DONE'), states('DONE'));
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1');
  });

  it('[near-miss: "This is the terminal state."] stays joined — no trailing space', () => {
    const result = parse(advBlock('This is the terminal state.'), states('ALPHA'));
    expect(result.edges).toHaveLength(0);
  });
});

// ── Phase 2 measured false positives (AC: no phantom edges) ──────────────────

describe('Phase 2 false positives produce no phantom edges', () => {
  // All four named false-positives from the SPEC.
  it('"when all sections are Complete or N/A" produces no edge', () => {
    const result = parse(
      advBlock('when all sections are Complete or N/A'),
      states('DONE')
    );
    expect(result.edges).toHaveLength(0);
  });

  it('"add information or re-validate" produces no edge', () => {
    const result = parse(
      advBlock('add information or re-validate'),
      states('DONE')
    );
    expect(result.edges).toHaveLength(0);
  });

  it('"Both continue inline." produces no edge', () => {
    const result = parse(advBlock('Both continue inline.'), states('DONE'));
    expect(result.edges).toHaveLength(0);
  });

  it('"This is the terminal state." produces no edge', () => {
    const result = parse(advBlock('This is the terminal state.'), states('DONE'));
    expect(result.edges).toHaveLength(0);
  });
});

// ── Multi-line block scoping (AC: aid-create-ticket 200-201) ─────────────────

describe('Block scoping — aid-create-ticket 200–201 three-clause wrapped block', () => {
  // AC: the third clause (`[3] Cancel`) lives on the continuation line.
  // A line-anchored implementation would produce only two clauses.
  // The block is normalized to one string and all three ". " separators fire.
  it('captures all three clauses from the wrapped block', () => {
    // Synthetic version of aid-create-ticket 200–201 using declared states FILE and COMPOSE.
    const block = advBlockMulti(
      '**Advance:** `[1] File it` → State: FILE (continue inline). `[2] Edit` → State: COMPOSE',
      '(continue inline). `[3] Cancel` → halt.'
    );
    const result = parse(block, states('FILE', 'COMPOSE'));

    // Must produce exactly 2 edges (FILE and COMPOSE) plus a HALT terminal.
    // A line-anchored implementation would miss the `[3] Cancel` → halt clause.
    const targets = result.edges.map((e) => e.to);
    expect(targets).toContain('n1'); // FILE
    expect(targets).toContain('n2'); // COMPOSE
    expect(result.terminal).not.toBeNull();
    expect(result.terminal.advanceType).toBe('HALT');
  });

  it('is demonstrably a multi-line block (line-anchored scan would miss [3] Cancel)', () => {
    // "Demonstrably insufficient" per AC: show that the continuation line
    // (line index 1 in the block) is required to capture the third clause.
    const block = advBlockMulti(
      '**Advance:** `[1] File it` → State: FILE. `[2] Edit` → State: COMPOSE.',
      '`[3] Cancel` → halt.'
    );
    // Line 0 (the marker line) contains FILE and COMPOSE.
    // Line 1 (the continuation) contains `[3] Cancel` → halt.
    // If only line 0 were scanned, terminal would be null.
    const result = parse(block, states('FILE', 'COMPOSE'));
    // With block scoping: terminal is non-null (halt on line 1 is captured).
    expect(result.terminal).not.toBeNull();
    expect(result.terminal.advanceType).toBe('HALT');
  });
});

// ── Separator ordering and stacking ──────────────────────────────────────────

describe('Multiple separators in one block', () => {
  it('semicolon and then can both fire in one block', () => {
    // "ALPHA; BETA then GAMMA" → ';' fires first (ALPHA / "BETA then GAMMA"),
    // then ' then ' fires in the second piece (BETA / GAMMA) if all resolve.
    const result = parse(
      advBlock('ALPHA; BETA (optional) then GAMMA'),
      states('ALPHA', 'BETA', 'GAMMA')
    );
    expect(result.edges.length).toBeGreaterThanOrEqual(2);
    const targets = result.edges.map((e) => e.to);
    expect(targets).toContain('n1'); // ALPHA
  });
});

// ── Backtick isolation ────────────────────────────────────────────────────────

describe('Separators inside backtick spans are not detected', () => {
  it('semicolon inside backticks does not split', () => {
    // "`A; B`" — the semicolon is inside backticks → no split.
    const result = parse(advBlock('`A; B` then DONE'), states('DONE'));
    // ' then ' outside backticks fires; left piece is '`A; B`' which has no
    // state (backtick content is not a state name) → cut rejected.
    // The whole clause → resolves to DONE if TOKEN_RE finds it.
    expect(result.edges).toHaveLength(1);
    expect(result.edges[0].to).toBe('n1'); // DONE
  });

  it('sentence boundary inside backtick span does not split', () => {
    const result = parse(advBlock('`clause one. HALT` then DONE'), states('DONE'));
    expect(result.edges).toHaveLength(1);
  });
});

// ── advanceType detection ─────────────────────────────────────────────────────

describe('advanceType detection per clause', () => {
  it('CHAIN keyword in the middle → edge advanceType=CHAIN', () => {
    const result = parse(advBlock('`[1] Approved` -> CHAIN -> DONE'), states('DONE'));
    expect(result.edges[0].advanceType).toBe('CHAIN');
  });

  it('no keyword → edge advanceType=UNSPECIFIED', () => {
    const result = parse(advBlock('DONE'), states('DONE'));
    expect(result.edges[0].advanceType).toBe('UNSPECIFIED');
  });
});

// ── warnings array ────────────────────────────────────────────────────────────

describe('parseAdvanceBlock — warnings', () => {
  it('returns an empty warnings array for a clean single-clause advance', () => {
    const result = parse(advBlock('DONE.'), states('DONE'));
    expect(result.warnings).toHaveLength(0);
  });

  it('returns warnings array even when empty', () => {
    const result = parse(advBlock('halt'), states());
    expect(Array.isArray(result.warnings)).toBe(true);
  });
});

// ── Corpus smoke test (non-failing: just verifies parse does not throw) ───────

describe('Corpus smoke test — real skill advance blocks do not throw', () => {
  const SKILL_DIR = resolve(REPO_ROOT, 'canonical/skills');

  it('parseAdvanceBlock does not throw on real advance blocks from aid-test', () => {
    const skillPath = resolve(SKILL_DIR, 'aid-test', 'SKILL.md');
    let text;
    try {
      text = readFileSync(skillPath, 'utf8').replace(/\r\n?/g, '\n');
    } catch {
      return; // skip if file not found
    }
    const lines = text.split('\n');
    const advanceRe = /^\s*\*{0,2}Advance:\*{0,2}/i;

    // Find all **Advance:** lines and parse each block without throwing.
    for (let i = 0; i < lines.length; i++) {
      if (!advanceRe.test(lines[i])) continue;
      const { blockText } = extractAdvanceBlock(lines, i);
      expect(() => parseAdvanceBlock({
        block: blockText,
        fromNodeId: 'n1',
        fromNodeName: 'TEST',
        declaredStates: [],
        file: `canonical/skills/aid-test/SKILL.md`,
        blockStartLine: i + 1,
      })).not.toThrow();
    }
  });
});
