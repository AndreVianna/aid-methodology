// derived-values.mjs — the registry of facts that are DERIVED, not typed.
//
// WHY THIS EXISTS
//
// AID is ~400 files of prose that instruct agents, and those files are full of values: counts,
// severities, modalities, grade bands, sentinels, settings. Every one of them is written by hand,
// and until now nothing compared a written value against the thing it describes. The only detector
// was a reviewer reading carefully.
//
// That produces a specific, measurable failure loop. Across three delivery-gate ledgers
// (delivery-013, delivery-014, delivery-015 cycle 12), 20 of 32 findings were one shape: *the same
// fact is stated in two or more places and only one copy was updated*. They were not independent
// bugs. Each was created by the previous fix:
//
//   changing `minimum_grade` to B-   -> the KB's quality-gates.md became false   (cycle 12, [HIGH])
//   adding two skills                -> 42 count claims became false at once
//   re-anchoring SUMMARY-08          -> every prose restatement of it became false
//
// The precedent that proves the cure is in this repo already: `check-skill-counts.mjs` derives the
// skill-count family once and sweeps the whole tree for statements that disagree. When a merge
// changed the corpus, it found all 42 stale claims in seconds with file:line — where a reviewer had
// been finding a third of them per cycle, a day apart. This file generalises that from one value
// family to a registry, so the other families get the same treatment.
//
// SKILL COUNTS ARE DELIBERATELY NOT HERE. `check-skill-counts.mjs` already owns them and its
// derivation is genuinely specialised (catalog rows, curated, shortcuts, repurpose). Restating it
// here would be a second source of truth for the counts — the exact defect this file exists to stop.
//
// TWO KINDS OF ENTRY
//
//   scalar    A single value with a derivation. Claims are regexes with one capture group; the
//             captured text must equal the derived value.
//   relation  A lookup table (key -> expected token). Claims match a line carrying BOTH a key and a
//             token; the token must be the one the table gives for that key. This covers the
//             "severity restated instead of looked up" family, where the defect is not a wrong
//             number but a wrong pairing.

import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join } from 'node:path';

// ── derivation helpers ────────────────────────────────────────────────────────

function dirsIn(root, rel) {
  const abs = join(root, rel);
  if (!existsSync(abs)) return [];
  return readdirSync(abs).filter((d) => statSync(join(abs, d)).isDirectory());
}

function kbDocs(root) {
  const abs = join(root, '.aid', 'knowledge');
  if (!existsSync(abs)) return [];
  return readdirSync(abs)
    .filter((f) => f.endsWith('.md'))
    .map((f) => ({ name: f, text: readFileSync(join(abs, f), 'utf8') }));
}

/** The grade alphabet, from the one line in the rubric that states every grade AND their order.
 *  Same source `lint-settings.sh` reads, deliberately: two readers of one line, not two lists. */
export function deriveGrades(root) {
  const p = join(root, 'canonical/aid/templates/grading-rubric.md');
  if (!existsSync(p)) return [];
  const lines = readFileSync(p, 'utf8').split('\n');
  const i = lines.findIndex((l) => /^## Grade Ordering\s*$/.test(l));
  if (i < 0) return [];
  const ordering = lines.slice(i + 1).find((l) => l.includes('>'));
  return ordering ? ordering.split('>').map((g) => g.trim()).filter(Boolean) : [];
}

/** The live global minimum grade, read from settings the same way the pipeline reads it. */
export function deriveMinimumGrade(root) {
  const p = join(root, '.aid', 'settings.yml');
  if (!existsSync(p)) return null;
  const m = readFileSync(p, 'utf8').match(/^minimum_grade:\s*(\S+)\s*$/m);
  return m ? m[1].replace(/^["']|["']$/g, '') : null;
}

/** Per-skill `minimum_grade` overrides actually present in settings.yml.
 *
 *  Today this is empty, and structurally must be: `lint-settings.sh` S8 rejects any top-level key
 *  the template does not seed, and the template seeds no skill sections -- so the per-skill override
 *  `read-setting.sh` documents cannot be written into a file that passes its own lint (work-003 Q19).
 *  That is what makes the `<skill>.minimum_grade: X` claim below comparable against the GLOBAL bar:
 *  with no override possible, read-setting.sh's resolution order collapses to the global for every
 *  skill. If S8 is ever relaxed this returns non-empty and `buildRegistry` THROWS, rather than
 *  silently comparing a legitimately-different override against the wrong source. A loud stop beats
 *  a guard that quietly starts lying. */
export function derivePerSkillOverrides(root) {
  const p = join(root, '.aid', 'settings.yml');
  const out = new Map();
  if (!existsSync(p)) return out;
  let section = null;
  for (const line of readFileSync(p, 'utf8').split('\n')) {
    if (/^\s*#/.test(line)) continue;
    const top = line.match(/^([a-z][a-z0-9_-]*):\s*$/);
    if (top) { section = top[1]; continue; }
    if (/^\S/.test(line)) { section = null; continue; }
    const mg = line.match(/^\s+minimum_grade:\s*(\S+)\s*$/);
    if (mg && section) out.set(section, mg[1].replace(/^["']|["']$/g, ''));
  }
  return out;
}

/** rule id -> the severity token its catalog row declares.
 *  Only rows whose Severity cell OPENS with a bracketed token are included: a `Step 2` row is
 *  instance-derived and has nothing fixed to compare against. */
export function deriveRuleSeverity(root) {
  const dir = join(root, 'canonical/aid/templates/review-rubrics');
  const out = new Map();
  if (!existsSync(dir)) return out;
  for (const f of readdirSync(dir).filter((x) => x.endsWith('.md'))) {
    for (const line of readFileSync(join(dir, f), 'utf8').split('\n')) {
      const cells = line.split('|');
      if (cells.length < 8) continue;
      const id = cells[1].replace(/[`\s]/g, '');
      if (!/^[A-Z]+-\d+$/.test(id)) continue;
      const cell = cells[cells.length - 2].trim();
      const m = cell.match(/^`\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]/);
      if (m && !out.has(id)) out.set(id, `[${m[1]}]`);
    }
  }
  return out;
}

/** rule id -> the modality its catalog row declares. */
export function deriveRuleModality(root) {
  const dir = join(root, 'canonical/aid/templates/review-rubrics');
  const out = new Map();
  if (!existsSync(dir)) return out;
  for (const f of readdirSync(dir).filter((x) => x.endsWith('.md'))) {
    for (const line of readFileSync(join(dir, f), 'utf8').split('\n')) {
      const cells = line.split('|');
      if (cells.length < 8) continue;
      const id = cells[1].replace(/[`\s]/g, '');
      if (!/^[A-Z]+-\d+$/.test(id)) continue;
      const mod = cells[4].replace(/[*`\s]/g, '');
      if (/^(MUST|SHOULD|COULD)$/.test(mod) && !out.has(id)) out.set(id, mod);
    }
  }
  return out;
}

export function deriveCounts(root) {
  const docs = kbDocs(root);
  const isMeta = (d) => /^kb-category:\s*meta\s*$/m.test(d.text);
  const isGenerated = (d) => /^source:\s*generated\s*$/m.test(d.text);
  return {
    agents: dirsIn(root, 'canonical/agents').length,
    kbMeta: docs.filter(isMeta).length,
    kbGenerated: docs.filter(isGenerated).length,
    // The union, which is what "permanently skipped" means to lint-frontmatter.sh. Stated
    // separately from its two parts because prose has been wrong about WHICH of the three it meant.
    kbPermanentlySkipped: docs.filter((d) => isMeta(d) || isGenerated(d)).length,
    grades: deriveGrades(root).length,
  };
}

// ── the registry ──────────────────────────────────────────────────────────────

export function buildRegistry(root) {
  const counts = deriveCounts(root);
  const minGrade = deriveMinimumGrade(root);
  const ruleSeverity = deriveRuleSeverity(root);
  const ruleModality = deriveRuleModality(root);

  // Precondition for the `<skill>.minimum_grade: X` claim pattern below -- see
  // derivePerSkillOverrides. Throwing is deliberate: the alternative is comparing a legitimately
  // different per-skill bar against the global one and reporting a correct line as wrong.
  const overrides = derivePerSkillOverrides(root);
  if (overrides.size) {
    throw new Error(
      `derived-values: .aid/settings.yml now carries per-skill minimum_grade overrides (` +
      `${[...overrides.keys()].join(', ')}). The \`<skill>.minimum_grade: X\` claim pattern in the ` +
      `minimum-grade entry compares against the GLOBAL bar, which is only correct while no override ` +
      `exists. Teach that pattern read-setting.sh's resolution order before removing this check.`
    );
  }

  return [
    {
      id: 'agent-count',
      kind: 'scalar',
      label: 'canonical agent directories',
      derive: () => String(counts.agents),
      // `N agents`, `N AID agents`, `N specialized agents`, `N canonical agents`, and the
      // `agents/ (N)` tree-diagram form. Adjectives are a NAMED set, not an open \w+: an open run
      // swallows "3 tier agents", which counts tiers.
      claims: [
        /\b(\d+)\s+(?:AID\s+|canonical\s+|specialized\s+|pipeline\s+)?agents\b/g,
        /(?<![\w/*])`?agents\/`?\s*\((\d+)\)/g,
        // The SINGULAR noun: "9 agent directories under canonical/agents/". Every pattern above
        // requires `agents` plural, so module-map.md's frontmatter summary stated 9 while this
        // guard's own commit was fixing the same count three files away and reported all-agree.
        /\b(\d+)\s+agent (?:directories|dirs)\b/g,
      ],
    },
    {
      id: 'minimum-grade',
      kind: 'scalar',
      label: 'the global minimum_grade in .aid/settings.yml',
      derive: () => minGrade,
      // Only forms that STATE the project's configured bar. A sentence that merely mentions a grade
      // ("a lone KB-26 row grades B+") is not a claim about the setting and must not match.
      // NOT case-insensitive. With /i, `minimum_grade '${mg}' is a valid grade` captured the
      // ARTICLE "a" as the grade "A", reporting four false positives inside lint-settings.sh's own
      // error messages. Grades are uppercase tokens; requiring that removes the whole class. The
      // negative lookahead does the same job for `is Any`, `is Beta`, and similar.
      claims: [
        /minimum[_ ]grade[^\n`]{0,40}?\bis\s+`?([A-F][+-]?)`?(?![A-Za-z])/g,
        /(?:global|project|configured)\s+(?:minimum|bar)[^\n`]{0,30}?`?([A-F][+-]?)`?(?![A-Za-z])\s*(?:\.|,|$)/g,
        /\|\s*`?minimum_grade`?\s*\|\s*`?([A-F][+-]?)`?\s*\|/g,
        // A dotted per-skill pin quoted as live configuration: "this project pins
        // `summary.minimum_grade: A+`). CONFIRMED: `.aid/settings.yml`". Two KB docs asserted that
        // against a settings.yml that has never held a `summary:` key and cannot hold one (S8/Q19),
        // and every pattern above needs the word `is`, so both survived the sweep that changed the
        // global. Comparable against the global only while no override exists -- buildRegistry
        // throws the moment one does.
        /\b[a-z][a-z0-9_-]*\.minimum[_ ]grade:\s*`?([A-F][+-]?)`?(?![A-Za-z])/g,
      ],
    },
    {
      id: 'kb-permanently-skipped',
      kind: 'scalar',
      label: 'KB docs permanently skipped by lint-frontmatter (meta OR generated)',
      derive: () => String(counts.kbPermanentlySkipped),
      claims: [/this KB has (\d+) (?:meta|permanently[- ]skipped|out-of-scope) docs?/gi],
    },
    {
      id: 'grade-alphabet-size',
      kind: 'scalar',
      label: 'grades in grading-rubric.md § Grade Ordering',
      derive: () => String(counts.grades),
      claims: [/\bgrade\.sh knows\s+(\d+)\b/g, /\b(\d+)[- ]letter (?:grade )?(?:alphabet|ladder|scale)\b/g],
    },
    {
      id: 'rule-severity',
      kind: 'relation',
      label: 'a severity stated for a rule must be the anchor its catalog row declares',
      // The relational family. This is what SEV01 does for eight named files; here it is the whole
      // tree, which is where cycle 12 found twelve prose statements that SEV01 structurally could
      // not see (its feed is table rows, and these are bullets).
      table: ruleSeverity,
      keyPattern: /\b([A-Z]{2,12}-\d{2})\b/g,
      tokenPattern: /\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]/g,
      format: (t) => `[${t}]`,
      // A line may legitimately carry a severity that is NOT the cited rule's anchor when it is
      // describing the escape ("[LOW]; escaped (>1 doc) -> [MEDIUM]"), quoting a retired value, or
      // stating the scale itself. Those are recognised, not excluded by file.
      exempt: /escaped|used to|formerly|retired|no longer|previously|was\b.*->|Step 2|step 2/i,
    },
    {
      id: 'rule-modality',
      kind: 'relation',
      label: 'a modality stated for a rule must be the one its catalog row declares',
      table: ruleModality,
      keyPattern: /\b([A-Z]{2,12}-\d{2})\b/g,
      tokenPattern: /\b(MUST|SHOULD|COULD)\b/g,
      format: (t) => t,
      exempt: /used to|formerly|retired|no longer|previously|MUST NOT|inherits/i,
    },
  ];
}
