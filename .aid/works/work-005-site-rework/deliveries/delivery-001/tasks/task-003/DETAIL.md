# task-003: Facts script gen-facts.mjs and its committed pages

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** feature-002-canonical-facts -> delivery-001 -> AC-2

**Depends on:** task-001, task-002

**Scope:**
- Create `site/scripts/gen-facts.mjs` exactly as Feature 002 § Technical Specification specifies:
  - § Data Model: the four read-only inputs (`canonical/skills/*/SKILL.md`, `canonical/agents/*/AGENT.md`,
    `canonical/aid/templates/shortcut-catalog.yml`, `canonical/aid/templates/settings.yml`); "Frontmatter
    subset" (`readFrontmatter`); "Settings template parse" (`parseSettings`, exit 2 on zero keys); the
    `catalog` line parse (`parseCatalog`); the JSDoc typedefs of "In-memory shapes"; the `GROUPS` table
    (12 groups, ids, labels, membership, `ordered`, blurbs, anchor rule) as the only hand data; the output
    set, marker line, `<source>` strings and Starlight-only frontmatter keys (`title`, `description`,
    `sidebar`).
  - § Feature Flow: CLI `[--check] [--canonical <dir>] [--out <dir>]` with defaults resolved from
    `import.meta.url`, unknown argument exits 2 with a usage line; steps 1-9 (load skills with the
    `purpose`/`rest` split regex, load catalog family rows, assign groups with the three named exit-2
    messages, `sidebar.order` numbering, load agents with the `TIERS` check, load settings, render,
    compare as missing/stale/extra, `--check` messages and exit 1, write mode with marker-guarded deletion
    and the `wrote <w>, removed <r>, unchanged <u>` line); the exit-code contract (0 / 1 only for drift
    under `--check` / 2 for input, usage or crash), all messages on stderr prefixed `gen-facts:`.
  - § Layers & Components: one file, at most 300 lines (target 265, section budgets as in its table);
    imports only `node:fs`, `node:path`, `node:url`, `node:process`; nothing from `scripts/skills/*` or
    `scripts/lib/*`; `InputError`; one `try`/`catch` in `main()` setting `process.exitCode = 2` (an
    unexpected error prints `gen-facts: internal error` and the stack); exports nothing; direct-run guard;
    the helpers `yamlStr`, `md`, `code`, `cell`; the four page layouts ("Skill page", "Skills index",
    "Agents page", "Settings page") with their bullet rules.
- Run `node site/scripts/gen-facts.mjs` (write mode) and commit its output in the same change: every
  `site/src/content/docs/skills/<name>.md` (one per `canonical/skills/*` directory),
  `site/src/content/docs/skills/index.md`, `site/src/content/docs/reference/agents.md` and
  `site/src/content/docs/reference/settings.md`, replacing the old generators' versions of those files.
- Render facts faithfully: the folded description of `aid-experiment` stays "/aid- execute" (Feature 002
  § Data Model, "Frontmatter subset"); it is not corrected here, and `canonical/` is not edited.
- Not touched: the old generators, `scripts/skills/`, `scripts/lib/`, their tests (Feature 005 step 4,
  delivery-003); `reference/kb.md` and `reference/skills.md` (Feature 005 step 4 and Feature 001);
  `site/astro.config.mjs` (the Skills sidebar group stays exactly as it is); `site/src/content.config.ts`;
  `site/package.json` (task-001 already added `facts` and `facts:check`); `site/vitest.config.mjs`.
- Order (PLAN.md delivery-001 Notes, item 3): task-001's `scripts` block is committed before this task's
  first commit, so no build reruns the old generators over these pages.
- Work sequence, with checkpoints so the session can stop at a known point:
  1. Write the file section by section in the table's order (header, imports, typedefs, constants,
     `InputError`, `parseArgs`, parsers, helpers, loaders, renderers, `main`, guard). After the parsers and
     after the renderers, run `wc -l site/scripts/gen-facts.mjs`; a section over its budget takes lines from
     the 35-line headroom only.
  2. Before touching `site/src/content/docs/`, run write mode into a temp folder
     (`T=$(mktemp -d); node site/scripts/gen-facts.mjs --out "$T"`), compare it by eye with the old pages and
     `rm -rf "$T"`; only then run write mode in place and commit.
  3. Overrun rule: if the file cannot be brought to 300 lines or fewer without dropping a behaviour that
     Feature 002 specifies, stop, set this task `Failed` and report the section sizes (`wc -l` per section)
     to the orchestrator; never drop a behaviour and never move code into a second file (the spec fixes one
     file). This is the split point: a re-plan, not a workaround inside this task.
- The drift and grouping cases (stale page, extra page, ungrouped skill, write into an empty folder) are
  proven by task-004's tests C2-C5, which run this file right after this task; this task's own exit-code
  criteria cover only what C1-C5 do not (usage error, empty settings template).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no change to any path outside
  the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than `site/scripts/gen-facts.mjs` and the
  generated pages listed above. `site/tests/facts.test.mjs` is task-004.

**Acceptance Criteria:**
- [ ] Order: before this task's commit, from the repo root, `git diff --name-only site-aid...HEAD -- site/package.json`
  prints `site/package.json` (task-001 is committed).
- [ ] Size cap (FR-2, AC-4): `wc -l < site/scripts/gen-facts.mjs` prints a number at most 300.
- [ ] Imports: `grep -E "^import" site/scripts/gen-facts.mjs` prints exactly four lines, importing from
  `node:fs`, `node:path`, `node:url` and `node:process`; `grep -cE "scripts/(skills|lib)/|^export" site/scripts/gen-facts.mjs`
  prints `0`.
- [ ] AC-2, first half: from `site/`, `node scripts/gen-facts.mjs --check` exits 0 and prints
  `gen-facts: <n> pages up to date` with `<n>` equal to `$(( $(ls ../canonical/skills | wc -l) + 3 ))`;
  `npm run facts:check` exits 0 too.
- [ ] Write mode is idempotent: from `site/`, `node scripts/gen-facts.mjs` exits 0 and prints
  `gen-facts: wrote 0, removed 0, unchanged <n>` (same `<n>`), and `git status --porcelain src/content/docs`
  prints nothing afterwards. It also runs from another working directory: from the repo root,
  `node site/scripts/gen-facts.mjs --check` exits 0.
- [ ] Committed pages: `ls site/src/content/docs/skills/*.md | wc -l` equals `ls canonical/skills | wc -l`
  plus 1; `grep -L 'generated by site/scripts/gen-facts.mjs from' site/src/content/docs/skills/*.md site/src/content/docs/reference/agents.md site/src/content/docs/reference/settings.md`
  prints nothing; `grep -lE '^(generatedFrom|sourceDoc):|^# |<script' site/src/content/docs/skills/*.md site/src/content/docs/reference/agents.md site/src/content/docs/reference/settings.md`
  prints nothing (today every old skill page holds a `generatedFrom:` line, so this fails before the task);
  every skill page holds exactly one `## Facts` line and a `- **Source:**` link to
  `https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/<name>/SKILL.md`.
- [ ] Layouts (Feature 002 § Layers & Components, "Page layouts"): `skills/aid-deploy.md` holds
  `- **Arguments:** none declared`; `skills/index.md` has `hidden: true` under `sidebar:`, its first `## `
  heading is `## Full path`, and its sentence `AID has <k> skills.` has `<k>` equal to
  `ls canonical/skills | wc -l`; `reference/agents.md` has `## Large tier` before `## Medium tier`, and its
  `### ` heading count equals `ls canonical/agents | wc -l`; `reference/settings.md` holds the header row
  `| Key | Starts as | What it does |` and a `` | `format_version` | `` row.
- [ ] Exit codes not covered by task-004 (from the repo root; nothing written under `site/src/content/docs/`):
  `node site/scripts/gen-facts.mjs --bogus >/dev/null 2>&1; echo "exit=$?"` prints `exit=2`, and
  `node site/scripts/gen-facts.mjs --bogus 2>&1 >/dev/null | grep -c '^gen-facts:.*--check'` prints at
  least `1` (the usage line is on stderr, prefixed, and names the options); and
  `C=$(mktemp -d); mkdir -p "$C/aid/templates"; cp -r canonical/skills canonical/agents "$C/"; cp canonical/aid/templates/shortcut-catalog.yml "$C/aid/templates/"; : > "$C/aid/templates/settings.yml"; node site/scripts/gen-facts.mjs --check --canonical "$C"; echo "exit=$?"; rm -rf "$C"`
  prints `exit=2` last. The stale, extra, ungrouped and empty-folder cases are task-004's C2-C5.
- [ ] AC-2, second half: from `site/`, `npm run build` exits 0, then
  `find dist/skills -mindepth 1 -maxdepth 1 -type d | wc -l` equals `ls ../canonical/skills | wc -l`, and
  `git status --porcelain src/content/docs` prints nothing (no regeneration at build time).
- [ ] AC-1: from `site/`, `test -f dist/index.html` exits 0 after that build. The legacy Vitest suite is not a
  criterion (PLAN.md Cross-Cutting Risks, row 1); task-004 adds the facts test.
- [ ] Scope (AC-13, NFR-5): from the repo root, `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's
  commit, `git status --porcelain --untracked-files=all site` lists only `site/scripts/gen-facts.mjs` and
  files under `site/src/content/docs/skills/` or named `site/src/content/docs/reference/agents.md` /
  `reference/settings.md`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
