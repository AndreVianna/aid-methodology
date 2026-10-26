# task-024: Design tokens and site stylesheet replacing casulo.css and shell.css

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

**Source:** feature-004-look-and-layout -> delivery-003 -> AC-9, AC-11

**Depends on:** task-023

**Scope:**
- Create `site/src/styles/tokens.css` exactly as Feature 004 § Data Model 1 specifies: two unlayered rule
  blocks, `:root { ... }` (the 21 dark colour tokens, the 22 non-colour tokens of the "Non-colour tokens"
  table, the 45 lines of the "Starlight mapping" table) and `:root[data-theme='light'] { ... }` (the 21 light
  colour tokens and nothing else); one declaration per line, colour lines in the form
  `  --aid-color-<name>: #rrggbb;` (lower-case 6-digit hex, values exactly as in the colour table); every
  `--sl-*` value is `var(--aid-...)` and nothing else; no web font. Budget (Layers & Components): at most 135 lines.
- Create `site/src/styles/site.css` with the ten rules of Feature 004 § UI Specs, "`site.css` rules", in that
  order (focus ring, reduced motion, content text, inline code, tables, code blocks/cards/asides, headings,
  `.version-badge`, `.aid-report-issue`, narrow screens), tokens only (no colour literal). Budget: at most 130 lines.
  So the order can be checked by command, each rule carries its marker and the marker first appears in that
  rule: 1 `focus-visible`, 2 `prefers-reduced-motion`, 3 `text-underline-offset`, 4 `0.1em 0.35em` (the inline
  code padding), 5 `var(--aid-space-2) var(--aid-space-3)` (the table cell padding), 6 `--aid-radius-md`,
  7 `--aid-space-6`, 8 `.version-badge`, 9 `.aid-report-issue`, 10 `max-width: 30rem`.
- In `site/astro.config.mjs`, set the `customCss` key to the Layers & Components line, verbatim and on one line:
  `customCss: ['./src/styles/tokens.css', './src/styles/site.css'],` (and drop its old comment). No other key.
- Delete `site/src/styles/casulo.css` and `site/src/styles/shell.css` with `git rm` (Feature 004 § Migration
  Plan: only the version badge and report link survive, restated in `site.css`; Inter, Mermaid, release-page and
  banner rules are dropped). This removes the only `@fontsource/inter` import, which Feature 005 step 6
  (task-033) requires first.
- Known interim state (accepted, PLAN.md delivery-003 Notes item 1): the old `Header.astro` loses its
  `shell.css` styling until task-025 rewrites it; `src/components/ReportForm.astro` keeps its `--casulo-*`
  fallbacks until Feature 005 step 5 (task-032) rewrites it.
- Not touched: `Header.astro`, `PageTitle.astro`, the `components`, `social` and `expressiveCode` keys
  (task-025, task-026); `ReportForm.astro`, `Footer.astro` (task-032); `package.json` (task-033);
  `site/tests/` (`tests/contrast.test.mjs` is delivery-004).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no change to any path outside the
  AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than the four named above and `astro.config.mjs`.

**Acceptance Criteria:**

Run from `site/` unless stated.

- [ ] Files: `test -f src/styles/tokens.css && test -f src/styles/site.css` exits 0;
  `test -e src/styles/casulo.css` and `test -e src/styles/shell.css` each exit 1; `ls src/styles | LC_ALL=C sort`
  prints exactly two lines, `site.css` then `tokens.css`.
- [ ] Token shape (Data Model 1): `grep -cE '^:root(\[data-theme=.light.\])? \{$' src/styles/tokens.css` prints
  `2` and `grep -c '{' src/styles/tokens.css` prints `2`; `grep -cE '^  --aid-color-[a-z-]+: #[0-9a-f]{6};$' src/styles/tokens.css`
  prints `42`; `grep -cE '^  --aid-(text|leading|space|radius|focus|content)-' src/styles/tokens.css` prints `22`;
  `grep -cE '^  --sl-[a-z0-9-]+: var\(--aid-[a-z0-9-]+\);$' src/styles/tokens.css` prints `45`, and `grep -E '^[[:space:]]*--sl-' src/styles/tokens.css | grep -cvE '^  --sl-[a-z0-9-]+: var\(--aid-[a-z0-9-]+\);$'`
  prints `0`; `wc -l < src/styles/tokens.css` prints at most `135`.
- [ ] Light block holds colours only: `sed -n "/^:root\[data-theme='light'\]/,/^}/p" src/styles/tokens.css | grep -c -- '--'`
  prints `21`, and every one of those lines starts with `  --aid-color-`.
- [ ] Colour values equal Feature 004 § Data Model 1's colour table (by command, the table read from the spec):
  `R=../.aid/works/work-005-site-rework/REQUIREMENTS.md; diff <(awk -F'|' '/^\| Token \140--aid-color-\140 \|/{f=1; next} f && /^\|---/{next} f && !/^\|/{exit} f{gsub("\140",""); gsub(/ /,""); n=split($2,a,","); split($3,d,","); split($4,l,","); for(i=1;i<=n;i++){print "dark " a[i] " " d[i]; print "light " a[i] " " l[i]}}' "$R" | sort) <(awk '/^:root \{$/{m="dark"; next} /^:root\[data-theme=.light.\] \{$/{m="light"; next} /^\}/{m=""} m && /^  --aid-color-/{sub(/^  --aid-color-/,""); sub(/;$/,""); sub(/: /," "); print m " " $0}' src/styles/tokens.css | sort)`
  (bash) prints nothing and exits 0 (42 pairs: 21 names, dark and light; the first list has 42 lines).
- [ ] Non-colour values equal the "Non-colour tokens" table:
  `for l in 'text-xs: 0.8125rem' 'text-sm: 0.875rem' 'text-base: 1rem' 'text-lg: 1.125rem' 'text-xl: 1.375rem' 'text-2xl: 1.75rem' 'text-3xl: 2.25rem' 'leading-body: 1.7' 'leading-heading: 1.25' 'space-1: 0.25rem' 'space-2: 0.5rem' 'space-3: 0.75rem' 'space-4: 1rem' 'space-5: 1.5rem' 'space-6: 2rem' 'space-7: 3rem' 'radius-sm: 0.25rem' 'radius-md: 0.5rem' 'radius-lg: 0.75rem' 'focus-width: 3px' 'focus-offset: 2px' 'content-width: 46rem'; do grep -qxF -- "  --aid-$l;" src/styles/tokens.css || echo "missing: $l"; done`
  prints nothing (22 tokens).
- [ ] Every mapping target exists: `grep -oE 'var\(--aid-[a-z0-9-]+\)' src/styles/tokens.css | sort -u | sed 's/var(\(.*\))/\1/' | while read -r t; do grep -qE "^  $t:" src/styles/tokens.css || echo "undefined: $t"; done`
  prints nothing.
- [ ] `site.css`: `wc -l < src/styles/site.css` prints at most `130`; each of `focus-visible`,
  `prefers-reduced-motion`, `text-underline-offset`, `.version-badge`, `.aid-report-issue`, `max-width: 30rem`
  is found by `grep -c` (count at least `1`); the ten rules appear in the UI Specs order (by their markers, see
  Scope): `for m in focus-visible prefers-reduced-motion text-underline-offset '0.1em 0.35em' 'var(--aid-space-2) var(--aid-space-3)' --aid-radius-md --aid-space-6 .version-badge .aid-report-issue 'max-width: 30rem'; do grep -nF -m1 -- "$m" src/styles/site.css | cut -d: -f1; done | awk 'NR>1 && $1+0<=p{bad=1} {p=$1+0} END{print (NR==10 && !bad) ? "ordered" : "not ordered"}'`
  prints `ordered` (a missing marker or a rule out of order prints `not ordered`).
- [ ] Tokens only (K4 rule, applied by command now; the test is delivery-004's):
  `grep -nEi '#[0-9a-f]{3,8}\b|rgba?\(|hsla?\(' src/styles/site.css` prints nothing;
  `grep -rn '@fontsource\|@import' src/styles` prints nothing; `grep -rln -- '--casulo-' src` prints exactly
  `src/components/ReportForm.astro` (task-032 removes the last ones).
- [ ] Config: `grep -c "customCss: \['./src/styles/tokens.css', './src/styles/site.css'\]," astro.config.mjs` prints
  `1`; `grep -c 'casulo.css\|shell.css' astro.config.mjs` prints `0`.
- [ ] Build (AC-1 still holds): `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  `grep -rl 'inter-latin\|@fontsource' dist --include='*.css'` prints nothing (no font file shipped, NFR-2).
- [ ] Links unchanged: after that build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's commit,
  `git status --porcelain --untracked-files=all site` lists only `site/src/styles/tokens.css`,
  `site/src/styles/site.css`, `site/src/styles/casulo.css`, `site/src/styles/shell.css` and
  `site/astro.config.mjs`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0. Unit tests: the token
  file's tests are `tests/contrast.test.mjs` K1-K5 (delivery-004, Feature 004 § Layers & Components); the
  legacy Vitest suite is not a criterion (PLAN.md Cross-Cutting Risks, row 1).
