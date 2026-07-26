// ac13-version-injection.test.ts — Task-013 acceptance criteria tests.
//
// Verifies:
//   AC13 — badge + all five install one-liners render the build-time version; no
//           hard-coded version literal in the source pages.
//   AC6  — Get Started section has Overview / Install / Your first work / Lite path.
//   AC7  — Installation guide documents all four channels + five tool tabs.
//   AC5  — Home pipeline diagram present; Installation guide prose faithful to source.
//
// Approach: these are build-time integration tests that inspect the SOURCE files
// (MDX/MD pages and version.ts) for structural and no-hardcoded-version invariants.
// Component rendering (Astro) is not testable in Vitest — we verify via the data
// layer and by asserting the source files do not contain hard-coded version literals.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
// __dirname = site/src/data/__tests__
// site root = ../../../  (data/__tests__ → data → src → site)
const siteRoot = resolve(__dirname, '../../..');
const docsRoot = resolve(siteRoot, 'src/content/docs');

// ── Helpers ──────────────────────────────────────────────────────────────────

function readDoc(relPath: string): string {
  return readFileSync(resolve(docsRoot, relPath), 'utf8');
}

// ── Mermaid topology helpers (AC5's pipeline guard) ──────────────────────────
//
// AC5's guard compares the home page's pipeline against README.md's canonical
// diagram. What broke it before was pinning NODE IDS and EDGE LABELS: commit
// ca4aad21 restructured the pipeline and left the guard asserting the old shape,
// the third time it had gone stale. So these helpers model edges and reachability
// instead, and node ids are never referenced — they differ between the two files
// (`Eng` vs `ENG`) and are not topology.
//
// SKILL NAMES and a few label phrases ARE pinned, deliberately: they are the
// vocabulary AC5 is about, and they are what lets the two diagrams be compared to
// each other at all. See the guard's own comment for how the two halves divide —
// one absolute anchor per diagram, plus a comparison derived from README.

const repoRoot = resolve(siteRoot, '..');

interface Flow {
  labels: Map<string, string>;
  edges: { from: string; to: string; dotted: boolean }[];
}

/** A bare Mermaid node id, once its shape and label have been stripped. */
const NODE_ID = /^[A-Za-z_]\w*$/;

/** `parseFlow` FAILS CLOSED. Anything it cannot account for throws here rather
 *  than being dropped.
 *
 *  This is the load-bearing design decision in this file, and it exists because
 *  the alternative was tried and failed four times. The guard below proves a
 *  NEGATIVE — that the lite path does not reach Specify/Plan/Detail — and a
 *  negative is satisfied by an absent edge. So a parser that silently ignores an
 *  unfamiliar construct does not merely lose coverage, it manufactures a PASS.
 *  Four separate Mermaid forms (`-->|x|`, `-- x -->`, the `<-->`/`o--o`/`x--x`
 *  family, `%%` comments, `;` separators, and the `{…}`/`>…]` shapes) each got
 *  past an earlier version of this parser exactly that way.
 *
 *  Failing closed converts an open-ended "did we enumerate every Mermaid form?"
 *  problem into a closed one: an unmodelled construct is a loud error naming the
 *  text it could not read, so the next unfamiliar form is caught on sight rather
 *  than at the next review. */
function unparsed(text: string, context: string): never {
  throw new Error(
    `parseFlow: cannot account for ${JSON.stringify(text)} in ${JSON.stringify(context)}. ` +
      `This Mermaid construct is not modelled. Teach parseFlow about it rather than ignoring ` +
      `it -- an unmodelled construct silently drops an edge, and a dropped edge makes the ` +
      `lite-path exclusion assertions vacuously true.`
  );
}

function mermaidBlock(src: string): string {
  const m = src.match(/```mermaid\n([\s\S]*?)\n```/);
  if (!m) throw new Error('no mermaid block found');
  return m[1];
}

// Replace each shaped node declaration with a bare `ID`, recording the label.
// Covers every Mermaid shape opener: `[rect]`, `(round)`, `([stadium])`,
// `[[subroutine]]`, `[(cylinder)]`, `((circle))`, `{rhombus}`, `{{hexagon}}`,
// `[/parallelogram/]`, `[\trapezoid\]` and `>asymmetric]`. Quote-aware, because
// labels legitimately contain brackets — the shortcut entry node's label is
// `/aid-&lt;verb&gt;[-&lt;artifact&gt;]…`.
function stripLabels(line: string, labels: Map<string, string>): string {
  let out = '';
  for (let i = 0; i < line.length; ) {
    const m = /^([A-Za-z_]\w*)(\{\{|\{|\[|\(|>)/.exec(line.slice(i));
    if (!m) {
      out += line[i++];
      continue;
    }
    let depth = 1;
    let inQuote = false;
    let sawQuote = false;
    let all = '';
    let quoted = '';
    let j = i + m[0].length;
    for (; j < line.length && depth > 0; j++) {
      const ch = line[j];
      if (ch === '"') {
        inQuote = !inQuote;
        sawQuote = true;
        continue;
      }
      if (!inQuote) {
        if (ch === '[' || ch === '{' || ch === '(') depth++;
        else if (ch === ']' || ch === '}' || ch === ')') {
          depth--;
          if (depth === 0) break;
        }
      } else {
        quoted += ch;
      }
      all += ch;
    }
    // The scan must have closed. Running off the end of the line means an
    // unbalanced quote or an unclosed bracket, and the remainder would otherwise
    // be bound as this node's label and the statement reduced to a lone
    // declaration — dropping the edge. That was the last fail-open path.
    if (depth > 0 || inQuote) {
      unparsed(line.slice(i), `unterminated ${inQuote ? 'quote' : 'shape'} in node ${m[1]}`);
    }
    // When the label is quoted, the label IS the quoted text — otherwise the
    // shape's own delimiters leak in (`A[/"one"/]` would bind `/one/`).
    labels.set(m[1], sawQuote ? quoted : all);
    out += m[1];
    i = j + 1;
  }
  return out;
}

// Mermaid's link grammar. An edge this misses is dropped SILENTLY, which makes
// `solidReach` under-approximate and the phase-exclusion assertions below
// vacuously true — the guard would then pass while the diagram regressed. So the
// roster covers the whole grammar, not just the forms the two diagrams use
// today, and `parseFlow: link grammar` below pins each one with its own case.
//
// Shape: an optional LEFT arrowhead, a body, an optional RIGHT arrowhead. The
// left head needs a whitespace/line-start lookbehind so the `o` and `x` heads
// (`A o--o B`, `A x--x B`) cannot be mistaken for the last letter of a node id.
// Longest body first, so `-- text -->` is not read as a bare `--` followed by
// stray words.
//
// `~~~`, Mermaid's invisible link, IS treated as a solid edge. It is a real edge
// in the layout graph, and a guard that ignored it could be defeated by routing
// a path through one.
const HEAD_L = String.raw`(?:(?<=^|\s)[<ox])?`;
const HEAD_R = String.raw`[>ox]?`;
const CONNECTOR = new RegExp(
  [
    `${HEAD_L}-\\.[^\\n]*?\\.-+${HEAD_R}`, //          -. text .->  dotted, with text
    `${HEAD_L}-\\.+-+${HEAD_R}`, //                    -.-> -..->   dotted, bare
    `${HEAD_L}--+\\s[^-|>\\n]*?\\s--+${HEAD_R}`, //    -- text -->  solid, inline text
    `${HEAD_L}==+\\s[^=|>\\n]*?\\s==+${HEAD_R}`, //    == text ==>  thick, inline text
    `${HEAD_L}==+${HEAD_R}`, //                        ==> === ==o  thick
    `${HEAD_L}--+${HEAD_R}`, //                        --> --- --x  solid
    String.raw`~~~+`, //                               ~~~          invisible
  ].join('|'),
  'g'
);

/** Drop a `%%` comment, ignoring one that sits inside a quoted label. A comment
 *  is not always on its own line — `A --> B %% temporary` is an ordinary edit,
 *  and leaving the comment glued to `B` would delete the edge from the graph. */
function stripComment(line: string): string {
  let inQuote = false;
  for (let i = 0; i < line.length; i++) {
    if (line[i] === '"') inQuote = !inQuote;
    else if (!inQuote && line[i] === '%' && line[i + 1] === '%') return line.slice(0, i);
  }
  return line;
}

/** Node tokens and connectors of one statement, in order. Throws on anything it
 *  cannot read as a node id — see `unparsed`. */
function readStatement(statement: string, into: Flow['edges']): void {
  const tokens: string[] = [];
  const ops: string[] = [];
  let cursor = 0;
  CONNECTOR.lastIndex = 0;
  let m: RegExpExecArray | null;
  while ((m = CONNECTOR.exec(statement)) !== null) {
    tokens.push(statement.slice(cursor, m.index));
    ops.push(m[0]);
    cursor = m.index + m[0].length;
    const pipe = /^\s*\|[^|]*\|/.exec(statement.slice(cursor)); // -->|text|
    if (pipe) cursor += pipe[0].length;
    CONNECTOR.lastIndex = cursor;
  }
  tokens.push(statement.slice(cursor));

  // `A & B --> C & D` fans out on both sides. Every token must be a bare id by
  // this point; if one is not, some shape or operator went unrecognised.
  const ids = (token: string) => {
    const parts = token
      .replace(/[\]})]/g, '')
      .split('&')
      .map((s) => s.trim())
      .filter(Boolean);
    for (const part of parts) if (!NODE_ID.test(part)) unparsed(part, statement);
    return parts;
  };

  if (ops.length === 0) {
    ids(tokens[0]); // a bare node declaration — validated, contributes no edge
    return;
  }
  // A chain `A --> B --> C` yields A->B and B->C.
  for (let i = 0; i < ops.length; i++) {
    for (const from of ids(tokens[i])) {
      for (const to of ids(tokens[i + 1])) {
        into.push({ from, to, dotted: ops[i].includes('-.') });
      }
    }
  }
}

// Statements that carry no edge and so contribute nothing to the graph. They are
// skipped rather than rejected: failing closed must not mean failing on valid
// Mermaid a maintainer has every reason to add. `accTitle` / `accDescr` are an
// accessibility improvement this diagram should welcome, and `click` is adjacent
// to this project's own node-interaction work.
//
// Known NOT supported, and deliberately loud rather than silent: Mermaid 11's
// edge-id form (`A e1@--> B`). It throws with the offending text named, which is
// the intended behaviour for an unmodelled construct — teach the parser then,
// rather than pre-emptively guessing at syntax the diagrams do not use.
// Every keyword needs a boundary after it. Without one the prefix shadows any
// node id that starts with it — `classDefault --> B` matches `classDef`, yields
// no edge and throws nothing, which is the silent drop this parser exists to
// forbid. The boundary is a single shared lookahead rather than a trailing space
// per alternative, so no alternative can be added later without one.
const NO_EDGE_STATEMENT =
  /^(classDef|class|style|linkStyle|direction|accTitle|accDescr|click|flowchart|graph|end)(?=$|[\s:{])/;

function parseFlow(block: string): Flow {
  const labels = new Map<string, string>();
  const edges: Flow['edges'] = [];
  const subgraphs = new Set<string>();
  let inAccBlock = false;

  for (const raw of block.split('\n')) {
    const line = stripComment(raw).trim();
    // `accDescr { … }` spans lines; its body is free text.
    if (inAccBlock) {
      if (line.includes('}')) inAccBlock = false;
      continue;
    }
    if (/^accDescr\s*\{/.test(line)) {
      inAccBlock = !line.includes('}');
      continue;
    }
    if (!line || NO_EDGE_STATEMENT.test(line)) continue;
    // Mermaid 11 node metadata: `A@{ shape: rect }` declares a shape, no edge.
    if (/^[A-Za-z_]\w*@\{/.test(line)) continue;
    // Record subgraph ids so an edge touching one can be rejected below rather
    // than quietly contributing nothing.
    const sub = /^subgraph\s+([A-Za-z_]\w*)/.exec(line);
    if (sub) {
      subgraphs.add(sub[1]);
      stripLabels(line.slice(sub[0].length), labels);
      continue;
    }
    if (line.startsWith('subgraph')) continue; // anonymous subgraph — no id to bind

    // Labels come out first, so the remaining skeleton carries no quoted text —
    // which is what makes splitting on `;` safe. Splitting the raw line would
    // corrupt any label holding an HTML entity, and every entity ends in `;`
    // (the shortcut entry's label is `/aid-&lt;verb&gt;[-&lt;artifact&gt;]…`).
    const skeleton = stripLabels(line, labels).replace(/:::\w+/g, '');
    for (const statement of skeleton.split(';')) {
      readStatement(statement, edges);
    }
  }

  // An unterminated `accDescr {` would skip every remaining line — a blast radius
  // of the whole diagram, not one edge. Throw, exactly as an unterminated shape
  // does; the two are the same defect and must not behave differently.
  if (inAccBlock) unparsed('accDescr {', 'unterminated accDescr block');

  // Subgraph containment is deliberately NOT modelled — reachability here is over
  // nodes only. So rather than let an edge into a subgraph box contribute
  // nothing (a reader sees the lite path entering Definition; the graph does
  // not), reject it. Same fail-closed rule as `unparsed`.
  for (const e of edges) {
    for (const end of [e.from, e.to]) {
      if (subgraphs.has(end)) {
        throw new Error(
          `parseFlow: edge ${e.from}->${e.to} touches subgraph id ${JSON.stringify(end)}. ` +
            `Subgraph containment is not modelled, so this edge's meaning cannot be checked. ` +
            `Point the edge at a node inside the subgraph instead.`
        );
      }
    }
  }
  return { labels, edges };
}

/** The `aid-…` skill a node's label names, or null. Node ids differ between the
 *  two diagrams (`Eng` vs `ENG`, `Exe` vs `EXE`); skill names do not, so they
 *  are what the two can be compared on. */
function skillOf(label: string): string | null {
  return /aid-(?:&lt;verb&gt;|[a-z-]+)/.exec(label)?.[0] ?? null;
}

function idOfSkill(flow: Flow, skill: string): string {
  const hits = [...flow.labels].filter(([, label]) => skillOf(label) === skill).map(([id]) => id);
  if (hits.length !== 1) {
    throw new Error(`expected exactly one node for ${skill}, found ${hits.length}`);
  }
  return hits[0];
}

/** The skills a node points at, by edge style. */
function targetSkills(flow: Flow, from: string, dotted: boolean): Set<string> {
  return new Set(
    flow.edges
      .filter((e) => e.from === from && e.dotted === dotted)
      .map((e) => skillOf(flow.labels.get(e.to) ?? ''))
      .filter((s): s is string => s !== null)
  );
}

/** The single node whose label mentions `phrase`. Throws if absent or ambiguous. */
function nodeMentioning(flow: Flow, phrase: string): string {
  const hits = [...flow.labels].filter(([, label]) => label.includes(phrase)).map(([id]) => id);
  if (hits.length !== 1) {
    throw new Error(`expected exactly one node mentioning ${phrase}, found ${hits.length}`);
  }
  return hits[0];
}

/** Nodes reachable from `start` over solid edges only. */
function solidReach(flow: Flow, start: string): Set<string> {
  const seen = new Set<string>();
  const queue = [start];
  while (queue.length) {
    const id = queue.shift()!;
    for (const e of flow.edges) {
      if (e.from !== id || e.dotted || seen.has(e.to)) continue;
      seen.add(e.to);
      queue.push(e.to);
    }
  }
  return seen;
}


const savedEnv: Record<string, string | undefined> = {};

function saveEnv(...keys: string[]) {
  for (const k of keys) savedEnv[k] = process.env[k];
}

function restoreEnv(...keys: string[]) {
  for (const k of keys) {
    if (savedEnv[k] === undefined) delete process.env[k];
    else process.env[k] = savedEnv[k];
  }
}

// ── AC13 — no hard-coded version in source pages ──────────────────────────────

describe('AC13 — no hard-coded version literal in source pages', () => {
  const HARDCODED_VERSION_RE = /\b1\.0\.0\b/g;

  it('index.mdx has no hard-coded version literal', () => {
    const src = readDoc('index.mdx');
    // Hard-coded "1.0.0" must not appear — version is injected via <InstallCommand>/<VersionBadge>
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('get-started/overview.md has no hard-coded version literal', () => {
    const src = readDoc('get-started/overview.md');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('get-started/install.md has no hard-coded version literal', () => {
    const src = readDoc('get-started/install.md');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('get-started/first-work.mdx has no hard-coded version literal', () => {
    const src = readDoc('get-started/first-work.mdx');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('get-started/lite-path.mdx has no hard-coded version literal', () => {
    const src = readDoc('get-started/lite-path.mdx');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });

  it('guides/installation.mdx has no hard-coded version literal', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).not.toMatch(HARDCODED_VERSION_RE);
  });
});

// ── AC13 — components import + channel usage ──────────────────────────────────

describe('AC13 — version-bearing commands rendered via <InstallCommand>', () => {
  it('index.mdx imports InstallCommand from correct depth', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain("import InstallCommand from '../../components/InstallCommand.astro'");
  });

  it('index.mdx imports VersionBadge from correct depth', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain("import VersionBadge from '../../components/VersionBadge.astro'");
  });

  it('index.mdx uses <InstallCommand channel="curl" />', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('channel="curl"');
  });

  it('index.mdx uses <VersionBadge> with href', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('<VersionBadge');
    expect(src).toContain('href=');
  });

  it('guides/installation.mdx imports InstallCommand from correct depth', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain("import InstallCommand from '../../../components/InstallCommand.astro'");
  });

  it('guides/installation.mdx uses all five channels', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="curl"');
    expect(src).toContain('channel="irm"');
    expect(src).toContain('channel="npm"');
    expect(src).toContain('channel="pypi"');
    expect(src).toContain('channel="offline"');
  });
});

// ── AC13 — AID_VERSION override propagation ───────────────────────────────────

describe('AC13 — AID_VERSION override propagates to all five commands (no runtime call)', () => {
  const ENV_KEY = 'AID_VERSION';

  beforeEach(() => saveEnv(ENV_KEY));
  afterEach(() => { restoreEnv(ENV_KEY); vi.resetModules(); });

  it('curl command reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.curl).toContain('5.0.0');
    expect(installCommands.curl).not.toContain('1.0.0');
  });

  it('irm command reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.irm).toContain('5.0.0');
    expect(installCommands.irm).not.toContain('1.0.0');
  });

  it('npm command reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.npm).toContain('5.0.0');
  });

  it('pypi command reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.pypi).toContain('5.0.0');
  });

  it('offline command reflects AID_VERSION override (v-prefixed tag)', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { installCommands } = await import('../version.js');
    expect(installCommands.offline).toContain('v5.0.0');
    expect(installCommands.offline).not.toContain('1.0.0');
  });

  it('VERSION reflects AID_VERSION override', async () => {
    process.env[ENV_KEY] = '5.0.0';
    const { VERSION } = await import('../version.js');
    expect(VERSION).toBe('5.0.0');
  });
});

// ── AC5 — Home pipeline diagram present ──────────────────────────────────────

describe('AC5 — Home pipeline diagram', () => {
  // The home pipeline is the canonical README diagram (a Mermaid flowchart with a
  // TRIAGE branch). It MUST show both the full and lite paths.
  it('index.mdx renders the pipeline as a Mermaid diagram', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('```mermaid');
    expect(src).toContain('flowchart TB');
  });

  it('index.mdx lists Discover and the six core phases in order', () => {
    const src = readDoc('index.mdx');
    for (const phase of ['Discover', 'Describe', 'Define', 'Specify', 'Plan', 'Detail', 'Execute']) {
      expect(src).toContain(phase);
    }
  });

  // Regression guard (this has been wrong three times, most recently when commit
  // ca4aad21 restructured the diagram and left the guard pinning the old shape).
  // It has two halves, and it needs both:
  //
  //   (1) an ABSOLUTE anchor, asserted of each diagram independently, so the two
  //       cannot drift together into agreement on the wrong thing; and
  //   (2) a DERIVED comparison, where what index.mdx must show is read out of
  //       README.md at run time rather than written down here.
  //
  // Node ids are never referenced — they differ between the two files and are
  // not topology. Label phrases are: renaming a node's skill or the shortcut
  // engine turns this red even if both diagrams are renamed together, which is
  // the deliberate trade — the vocabulary is part of what AC5 pins.
  it('index.mdx pipeline is topologically the README pipeline: suggest-only triage, lite path skipping Specify/Plan/Detail', () => {
    const readme = parseFlow(mermaidBlock(readFileSync(resolve(repoRoot, 'README.md'), 'utf8')));
    const home = parseFlow(mermaidBlock(readDoc('index.mdx')));

    // ── (1) the absolute anchor, of each diagram on its own ──────────────────
    for (const flow of [readme, home]) {
      // Triage is an entry point that only ever suggests. It never has a solid
      // edge, so it cannot be read as a routing step.
      const triage = idOfSkill(flow, 'aid-triage');
      expect(flow.edges.filter((e) => e.from === triage && e.dotted).length).toBeGreaterThan(0);
      expect(flow.edges.filter((e) => e.from === triage && !e.dotted)).toEqual([]);
      expect(flow.labels.get(triage)).toContain('suggest-only');

      // The shortcut engine's own label declares the Describe→Detail collapse.
      const engine = nodeMentioning(flow, 'Shortcut engine');
      const engineLabel = flow.labels.get(engine)!;
      expect(engineLabel).toContain('Describe');
      expect(engineLabel).toContain('Detail');
      expect(engineLabel).toMatch(/collapsed/i);

      // The lite path, measured from the shortcut ENTRY rather than from the
      // engine, runs through the engine to Execute and never touches Specify,
      // Plan or Detail. Starting at the engine would leave a phase inserted
      // upstream of it — `SC --> Spec --> Eng` — undetected.
      const liteReach = solidReach(flow, idOfSkill(flow, 'aid-&lt;verb&gt;'));
      expect(liteReach.has(engine)).toBe(true);
      expect(liteReach.has(idOfSkill(flow, 'aid-execute'))).toBe(true);
      for (const phase of ['aid-specify', 'aid-plan', 'aid-detail']) {
        expect(liteReach.has(idOfSkill(flow, phase))).toBe(false);
      }

      // The full path is still there, and it is the one that does traverse them.
      // `aid-define` is named here as well as the three excluded phases, so that
      // no phase can be deleted from a diagram without failing: `idOfSkill`
      // throws on a missing node, and the derived comparison below cannot catch
      // a phase that has vanished from BOTH sides of its own containment test.
      const fullReach = solidReach(flow, idOfSkill(flow, 'aid-describe'));
      for (const phase of ['aid-define', 'aid-specify', 'aid-plan', 'aid-detail', 'aid-execute']) {
        expect(fullReach.has(idOfSkill(flow, phase))).toBe(true);
      }
    }

    // ── (2) the derived comparison: index.mdx against README, not a checklist ─
    // The home page draws a subset of README's graph — it has no /aid-ask node —
    // so this is containment-shaped rather than equality: for every skill README
    // shows triage suggesting, IF index.mdx declares that skill anywhere, then
    // index.mdx must show triage suggesting it too.
    //
    // Be precise about the escape hatch, because it is wider than the /aid-ask
    // case that motivates it: `homeSkills` is every skill index.mdx declares, so
    // ANY skill index.mdx stops declaring drops out of both sides here and goes
    // unnoticed by this half. That is what the absolute anchor above is for — it
    // names the pipeline phases explicitly, so a phase cannot disappear quietly.
    // This half's job is edges, not node inventory.
    const homeSkills = new Set([...home.labels.values()].map(skillOf).filter(Boolean));
    const readmeSuggests = targetSkills(readme, idOfSkill(readme, 'aid-triage'), true);
    const expected = [...readmeSuggests].filter((s) => homeSkills.has(s)).sort();
    expect(expected.length).toBeGreaterThan(0); // the oracle is not vacuously true
    expect([...targetSkills(home, idOfSkill(home, 'aid-triage'), true)].sort()).toEqual(expected);

    // Same shape for the lite path: every skill README's shortcut entry reaches
    // over solid edges and that index.mdx also declares must be reachable there.
    const reachedSkills = (flow: Flow) =>
      new Set(
        [...solidReach(flow, idOfSkill(flow, 'aid-&lt;verb&gt;'))]
          .map((id) => skillOf(flow.labels.get(id) ?? ''))
          .filter(Boolean)
      );
    const readmeLite = [...reachedSkills(readme)].filter((s) => homeSkills.has(s)).sort();
    expect(readmeLite.length).toBeGreaterThan(0);
    expect([...reachedSkills(home)].sort()).toEqual(readmeLite);
  });
});

// ── AC5 — the guard's own parser ─────────────────────────────────────────────
//
// The guard above proves a NEGATIVE — that the lite path does not reach
// Specify/Plan/Detail. A parser that silently drops an edge makes that negative
// vacuously true, so the guard would pass while the diagram regressed. These
// cases pin every link form Mermaid can produce, asserting each edge is SEEN.

describe('AC5 — parseFlow: link grammar', () => {
  const edgeOf = (line: string) => parseFlow(`flowchart TD\n    ${line}`).edges;

  it.each([
    ['solid', 'A --> B', false],
    ['solid, long', 'A ----> B', false],
    ['open, no arrowhead', 'A --- B', false],
    ['circle head', 'A --o B', false],
    ['cross head', 'A --x B', false],
    ['solid, pipe label', 'A -->|also| B', false],
    ['solid, inline text', 'A -- also --> B', false],
    ['thick', 'A ==> B', false],
    ['thick, inline text', 'A == also ==> B', false],
    ['thick, pipe label', 'A ==>|also| B', false],
    ['dotted, bare', 'A -.-> B', true],
    ['dotted, long', 'A -..-> B', true],
    ['dotted, text', 'A -. also .-> B', true],
    ['dotted, text containing a period', 'A -. v1.2 ships .-> B', true],
    ['trailing semicolon', 'A --> B;', false],
    // Double-ended and bidirectional heads. These are the forms that can smuggle
    // an edge past a naive grammar: `TR x--x Plan` gives triage a non-dotted link
    // into the pipeline, which the suggest-only anchor must see.
    ['bidirectional solid', 'A <--> B', false],
    ['bidirectional, left head only', 'A <-- B', false],
    ['bidirectional thick', 'A <==> B', false],
    ['bidirectional dotted', 'A <-.-> B', true],
    ['circle both ends', 'A o--o B', false],
    ['cross both ends', 'A x--x B', false],
    ['circle both ends, thick', 'A o==o B', false],
    ['cross both ends, thick', 'A x==x B', false],
    ['invisible link', 'A ~~~ B', false],
  ])('sees the edge in %s: `%s`', (_form, line, dotted) => {
    expect(edgeOf(line)).toEqual([{ from: 'A', to: 'B', dotted }]);
  });

  it('does not mistake a trailing o or x in a node id for an arrowhead', () => {
    expect(edgeOf('Fox --> Box')).toEqual([{ from: 'Fox', to: 'Box', dotted: false }]);
    expect(edgeOf('Fox-->Box')).toEqual([{ from: 'Fox', to: 'Box', dotted: false }]);
  });

  // Whitespace is what disambiguates a circle/cross head from a node id that
  // begins with `o` or `x` — the same rule Mermaid's own lexer applies.
  it('splits an o/x head from an o/x-initial node id on whitespace, as Mermaid does', () => {
    expect(edgeOf('A --- oB')).toEqual([{ from: 'A', to: 'oB', dotted: false }]);
    expect(edgeOf('A---oB')).toEqual([{ from: 'A', to: 'B', dotted: false }]);
  });

  it('sees an edge that carries a trailing `%%` comment', () => {
    expect(edgeOf('A --> B %% temporary')).toEqual([{ from: 'A', to: 'B', dotted: false }]);
  });

  it('ignores a comment-only line', () => {
    expect(parseFlow('flowchart TD\n    %% A --> B').edges).toEqual([]);
  });

  it('keeps a `%%` that sits inside a quoted label', () => {
    const flow = parseFlow('flowchart TD\n    A["100%% done"] --> B');
    expect(flow.edges).toEqual([{ from: 'A', to: 'B', dotted: false }]);
    expect(flow.labels.get('A')).toBe('100%% done');
  });

  it('treats `;` as a statement separator, not just a line terminator', () => {
    expect(edgeOf('A --> B; C --> D')).toEqual([
      { from: 'A', to: 'B', dotted: false },
      { from: 'C', to: 'D', dotted: false },
    ]);
  });

  it('does not split on the `;` of an HTML entity inside a label', () => {
    const flow = parseFlow('flowchart TD\n    A["/aid-&lt;verb&gt;"] --> B');
    expect(flow.edges).toEqual([{ from: 'A', to: 'B', dotted: false }]);
    expect(flow.labels.get('A')).toBe('/aid-&lt;verb&gt;');
  });

  it('fans out an `&` target list', () => {
    expect(edgeOf('A --> B & C')).toEqual([
      { from: 'A', to: 'B', dotted: false },
      { from: 'A', to: 'C', dotted: false },
    ]);
  });

  it('reads a chain that mixes link styles', () => {
    expect(edgeOf('A --> B -.-> C ==> D')).toEqual([
      { from: 'A', to: 'B', dotted: false },
      { from: 'B', to: 'C', dotted: true },
      { from: 'C', to: 'D', dotted: false },
    ]);
  });

  it('expands a chain into one edge per hop', () => {
    expect(edgeOf('A --> B --> C')).toEqual([
      { from: 'A', to: 'B', dotted: false },
      { from: 'B', to: 'C', dotted: false },
    ]);
  });

  it('fans out an `&` source list', () => {
    expect(edgeOf('A & B --> C')).toEqual([
      { from: 'A', to: 'C', dotted: false },
      { from: 'B', to: 'C', dotted: false },
    ]);
  });

  it('reads node declarations written inline on the edge line', () => {
    const flow = parseFlow('flowchart TD\n    A["first"] --> B{{"second"}}');
    expect(flow.edges).toEqual([{ from: 'A', to: 'B', dotted: false }]);
    expect(flow.labels.get('A')).toBe('first');
    expect(flow.labels.get('B')).toBe('second');
  });

  it('keeps brackets that are inside a quoted label', () => {
    const flow = parseFlow('flowchart TD\n    A["/aid-&lt;verb&gt;[-&lt;artifact&gt;] here"] --> B');
    expect(flow.edges).toEqual([{ from: 'A', to: 'B', dotted: false }]);
    expect(flow.labels.get('A')).toBe('/aid-&lt;verb&gt;[-&lt;artifact&gt;] here');
  });

  it('ignores declarations, styling and subgraph scaffolding', () => {
    const flow = parseFlow(
      [
        'flowchart TD',
        '    classDef entry fill:#B45309,stroke:#B45309',
        '    subgraph G[" grouped "]',
        '        A["one"]:::entry',
        '    end',
        '    linkStyle 0 stroke:#fff',
        '    A --> B',
      ].join('\n')
    );
    expect(flow.edges).toEqual([{ from: 'A', to: 'B', dotted: false }]);
  });

  // Every Mermaid node shape, because an unrecognised opener leaves the shape
  // text glued to the id — which turns one node written two ways into TWO ids
  // and severs the graph at exactly the point being asserted about.
  it.each([
    ['rectangle', 'A["one"]'],
    ['round', 'A("one")'],
    ['stadium', 'A(["one"])'],
    ['subroutine', 'A[["one"]]'],
    ['cylinder', 'A[("one")]'],
    ['circle', 'A(("one"))'],
    ['rhombus', 'A{"one"}'],
    ['hexagon', 'A{{"one"}}'],
    ['parallelogram', 'A[/"one"/]'],
    ['trapezoid', 'A[\\"one"\\]'],
    ['asymmetric', 'A>"one"]'],
  ])('binds the id and label of a %s node: `%s`', (_shape, decl) => {
    const flow = parseFlow(`flowchart TD\n    ${decl} --> B`);
    expect(flow.edges).toEqual([{ from: 'A', to: 'B', dotted: false }]);
    expect(flow.labels.get('A')).toBe('one');
  });

  // The pattern that made the shape gap dangerous: a node declared with its
  // shape on one line and referenced bare on the next must remain ONE node.
  it.each([
    ['rhombus', 'Q{lite?}'],
    ['asymmetric', 'Q>flag]'],
    ['rectangle', 'Q[plain]'],
  ])('keeps a %s node declared inline and referenced bare as one id', (_shape, decl) => {
    const flow = parseFlow(`flowchart TD\n    A --> ${decl}\n    Q --> B`);
    expect(flow.edges).toEqual([
      { from: 'A', to: 'Q', dotted: false },
      { from: 'Q', to: 'B', dotted: false },
    ]);
  });

  it('ignores an init directive', () => {
    expect(parseFlow("flowchart TD\n    %%{init: {'theme':'dark'}}%%\n    A --> B").edges).toEqual([
      { from: 'A', to: 'B', dotted: false },
    ]);
  });

  // ── Fail-closed ────────────────────────────────────────────────────────────
  // The guard proves a NEGATIVE, so a silently-dropped edge is a false PASS.
  // parseFlow must refuse what it cannot model, loudly, rather than ignore it.

  it('throws on a construct it cannot model, naming the offending text', () => {
    expect(() => parseFlow('flowchart TD\n    A =!=> B')).toThrow(/cannot account for/);
  });

  it('throws rather than silently ignoring an edge into a subgraph id', () => {
    const block = [
      'flowchart TD',
      '    subgraph G2[" Definition "]',
      '        Spec["specify"]',
      '    end',
      '    A --> G2',
    ].join('\n');
    expect(() => parseFlow(block)).toThrow(/touches subgraph id/);
  });

  it('still binds the labels of nodes declared inside a subgraph', () => {
    const block = [
      'flowchart TD',
      '    subgraph G2[" Definition "]',
      '        Spec["specify"]',
      '    end',
      '    Spec --> B',
    ].join('\n');
    const flow = parseFlow(block);
    expect(flow.edges).toEqual([{ from: 'Spec', to: 'B', dotted: false }]);
    expect(flow.labels.get('Spec')).toBe('specify');
  });

  // Malformed input must throw too. Before this, an unterminated delimiter made
  // the scan run off the end of the line, bind the remainder as the node's label
  // and reduce the statement to a lone declaration — dropping the edge silently.
  it.each([
    ['unbalanced quote', 'A["oops] --> B'],
    ['unclosed bracket', 'A[oops --> B'],
    ['%% inside an unquoted label', 'A[100%% done] --> B'],
  ])('throws on %s rather than dropping the edge: `%s`', (_case, line) => {
    expect(() => edgeOf(line)).toThrow(/cannot account for/);
  });

  // Failing closed must not mean failing on valid Mermaid a maintainer would
  // reasonably add. These carry no edge and must be skipped, not rejected.
  it.each([
    ['accTitle', 'accTitle: The AID pipeline'],
    ['accDescr, inline', 'accDescr: Entry points and the two paths'],
    ['click handler', 'click A "https://example.com" _blank'],
    ['node metadata (Mermaid 11)', 'A@{ shape: rect }'],
  ])('skips the no-edge statement %s and still reads surrounding edges', (_case, stmt) => {
    const flow = parseFlow(`flowchart TD\n    ${stmt}\n    A --> B`);
    expect(flow.edges).toEqual([{ from: 'A', to: 'B', dotted: false }]);
  });

  it('skips a multi-line accDescr block', () => {
    const flow = parseFlow(
      ['flowchart TD', '    accDescr {', '      Free text --> not an edge', '    }', '    A --> B'].join('\n')
    );
    expect(flow.edges).toEqual([{ from: 'A', to: 'B', dotted: false }]);
  });

  it('throws on an unterminated accDescr block rather than skipping the rest of the diagram', () => {
    expect(() =>
      parseFlow(['flowchart TD', '    accDescr {', '      no closing brace', '    A --> B'].join('\n'))
    ).toThrow(/cannot account for/);
  });

  // A keyword prefix must not shadow a node id that begins with it. Each of
  // these ids starts with a no-edge-statement keyword and must still yield edges.
  it.each([
    'classDefault',
    'classRoom',
    'styleGuide',
    'linkStyleGuide',
    'directionSign',
    'accTitleNode',
    'accDescrNode',
    'clickTarget',
    'flowchartX',
    'graphNode',
    'endNode',
  ])('does not let a keyword prefix swallow the node id `%s`', (id) => {
    expect(edgeOf(`${id} --> B`)).toEqual([{ from: id, to: 'B', dotted: false }]);
    expect(edgeOf(`B --> ${id}`)).toEqual([{ from: 'B', to: id, dotted: false }]);
  });

  it('tolerates CRLF line endings', () => {
    expect(parseFlow('flowchart TD\r\n    A --> B\r\n').edges).toEqual([
      { from: 'A', to: 'B', dotted: false },
    ]);
  });
});

// ── AC6 — Get Started section structure ──────────────────────────────────────

describe('AC6 — Get Started section has required four pages', () => {
  it('overview.md exists and has sidebar.order: 1', () => {
    const src = readDoc('get-started/overview.md');
    expect(src).toContain('order: 1');
    expect(src).toContain("label: Overview");
  });

  it('install.md exists and has sidebar.order: 2', () => {
    const src = readDoc('get-started/install.md');
    expect(src).toContain('order: 2');
  });

  it('first-work.mdx exists and has sidebar.order: 3', () => {
    const src = readDoc('get-started/first-work.mdx');
    expect(src).toContain('order: 3');
  });

  it('lite-path.mdx exists and has sidebar.order: 4', () => {
    const src = readDoc('get-started/lite-path.mdx');
    expect(src).toContain('order: 4');
  });

  it('first-work.mdx uses <Steps> component (net-new content)', () => {
    const src = readDoc('get-started/first-work.mdx');
    expect(src).toContain('<Steps>');
    expect(src).toContain("import { Steps }");
  });

  it('lite-path.mdx uses <Steps> component (net-new content)', () => {
    const src = readDoc('get-started/lite-path.mdx');
    expect(src).toContain('<Steps>');
    expect(src).toContain("import { Steps }");
  });
});

// ── AC7 — Installation guide channels and tool tabs ──────────────────────────

describe('AC7 — Installation guide four channels and five tool tabs', () => {
  it('installation.mdx documents curl channel', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="curl"');
  });

  it('installation.mdx documents irm channel (Windows PowerShell)', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="irm"');
  });

  it('installation.mdx documents npm channel', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="npm"');
  });

  it('installation.mdx documents pypi channel', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="pypi"');
  });

  it('installation.mdx documents offline channel', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('channel="offline"');
  });

  it('installation.mdx has per-OS <Tabs syncKey="os">', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('syncKey="os"');
    expect(src).toContain('label="Linux"');
    expect(src).toContain('label="macOS"');
    expect(src).toContain('label="Windows"');
  });

  it('installation.mdx has per-tool <Tabs syncKey="tool">', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('syncKey="tool"');
    expect(src).toContain('label="Claude Code"');
    expect(src).toContain('label="Codex"');
    expect(src).toContain('label="Cursor"');
    expect(src).toContain('label="Copilot CLI"');
    expect(src).toContain('label="Antigravity"');
  });

  it('os and tool syncKey values are independent (different strings)', () => {
    // Confirm the two syncKey values are distinct strings
    expect('os').not.toBe('tool');
    // Source uses both
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('syncKey="os"');
    expect(src).toContain('syncKey="tool"');
  });

  it('installation.mdx has update instructions', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('Update');
    expect(src).toContain('aid update');
  });

  it('installation.mdx has remove instructions', () => {
    const src = readDoc('guides/installation.mdx');
    expect(src).toContain('Remove');
    expect(src).toContain('aid remove');
  });
});

// ── AC3 — Home doc page (Overview) structure ──────────────────────────────────
// The root page is a standard documentation page, NOT a marketing splash. The
// anti-splash invariant is the absence of `template: splash`, a `hero:` block, and
// CTA `actions:`. Per prototype-01 it DOES use a <CardGrid> of <LinkCard>s for doc
// navigation and the inline <PipelineDiagram /> — both are documentation patterns.

describe('AC3 — Home page is a documentation page (no marketing splash)', () => {
  it('index.mdx does NOT have template: splash', () => {
    const src = readDoc('index.mdx');
    expect(src).not.toContain('template: splash');
  });

  it('index.mdx does NOT have a hero block', () => {
    const src = readDoc('index.mdx');
    expect(src).not.toContain('hero:');
  });

  it('index.mdx does NOT have CTA actions (splash buttons)', () => {
    const src = readDoc('index.mdx');
    expect(src).not.toContain('actions:');
  });

  it('index.mdx uses <CardGrid>/<LinkCard> for documentation navigation', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('<CardGrid>');
    expect(src).toContain('<LinkCard');
  });

  it('index.mdx title is Overview (documentation voice)', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('title: Overview');
  });

  it('index.mdx links to /get-started/overview/ (navigation card)', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('/get-started/overview/');
  });

  it('index.mdx links to the Installation guide (all channels)', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('/guides/installation/');
  });

  it('index.mdx has a pipeline diagram (Mermaid)', () => {
    const src = readDoc('index.mdx');
    expect(src).toContain('```mermaid');
  });
});
