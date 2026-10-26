# task-028: Version read from VERSION and network-free changelog page

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

**Source:** feature-005-machinery-cut -> delivery-003 -> AC-1, AC-6

**Depends on:** task-026, task-027

**Scope:**
- Feature 005 § Feature Flow step 2, with the shapes of § Data Model 2 and 3, in one change:
  - `site/astro.config.mjs`: add `import { readFileSync } from 'node:fs';` at the top (Feature 003 removed it in
    delivery-002; if it is present, leave it, so exactly one such line exists); add, before `defineConfig`, the
    `AID_VERSION` read and its guard exactly as Data Model 2 states them
    (`const AID_VERSION = readFileSync(new URL('../VERSION', import.meta.url), 'utf8').trim().replace(/^v/, '');`
    then `if (!/^\d+\.\d+\.\d+/.test(AID_VERSION)) throw new Error('astro.config.mjs: ../VERSION is not a version: ' + AID_VERSION);`);
    add the top-level `vite: { define: { __AID_VERSION__: JSON.stringify(AID_VERSION) } }` key to `defineConfig`;
    remove the `Banner` entry from the `components` map; and switch the sidebar Releases entry from the interim
    `{ label: 'Changelog', link: '/releases/changelog' }` to Feature 001's `{ label: 'Changelog', slug: 'releases/changelog' }`
    (PLAN.md delivery-003 Notes, item 3), dropping the comment that explains the `link:` form. No other key.
  - Comments that this change makes false are this task's (they name what it removes): the file-header
    "Sidebar contract" line about Releases ("Releases: link: to src/pages/releases/changelog.astro (not a docs
    page)"), if task-006 kept it, is reworded to the `slug:` form (for example "Releases: slug item
    (releases/changelog, a docs page).") or deleted; any comment that still names `Banner` is deleted
    (task-025 already rewrote the key-listing comments, so normally none is left).
  - `site/src/data/version.ts`: rewritten per Data Model 2: `declare const __AID_VERSION__: string;` then
    `export const VERSION: string = __AID_VERSION__;`; `VERSION_TAG`, `InstallChannel` and `installCommands`
    stay as they are; `channelLabels` and the `release-data` import are removed, and the header comment no
    longer describes `process.env` or file probing.
  - Create `site/src/content/docs/releases/changelog.mdx` with exactly the content of Data Model 3.
  - Delete with `git rm`: `site/src/pages/releases/changelog.astro` (the `src/pages/` folder empties and is
    removed from disk), `site/src/components/Banner.astro`, `site/src/lib/release-data.ts`.
  - `site/.gitignore`: remove the three `.release-data.json` lines (the two comment lines and the entry).
- `src/components/VersionBadge.astro` and `src/components/InstallCommand.astro` are kept unchanged (Data Model 2,
  "shown").
- In `.aid/works/work-005-site-rework/site-audit.md` § Pages (PLAN.md delivery-003 Notes, item 4; Feature 001
  § Data Model, "Verdict"): the `src/content/docs/releases/changelog.mdx` row gets the verdict `new`, after its
  words are checked against Feature 001 rules P1 and P7 (Correction: one sentence saying the page shows the
  `VERSION` value and links to GitHub Releases); the `src/pages/releases/changelog.astro` row gets `removed`,
  its Correction naming `src/content/docs/releases/changelog.mdx` at the same URL `/releases/changelog/`.
- Not touched: the `Head` key and the node panel (task-029); `src/lib/skill-node-panel.ts` and `src/lib/__tests__/`
  (tasks 029, 030); `scripts/fetch-release-data.mjs` (task-030); the FR-9 table's "Release banner" row
  (delivery-004, Feature 005 step 8).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/` or of the repo-root `VERSION`; no
  change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB
  documents, `.aid/works/work-005-site-rework/`), and inside it no file other than those named above.

**Acceptance Criteria:**

Run from `site/` unless stated. Let `V=$(tr -d '[:space:]' < ../VERSION | sed 's/^v//')`.

- [ ] Version read (Data Model 2): `grep -c "from 'node:fs'" astro.config.mjs` prints `1`;
  `grep -cF "readFileSync(new URL('../VERSION', import.meta.url), 'utf8').trim().replace(/^v/, '')" astro.config.mjs`
  prints `1`; `grep -cF "'astro.config.mjs: ../VERSION is not a version: '" astro.config.mjs` prints `1`;
  `grep -cF '__AID_VERSION__: JSON.stringify(AID_VERSION)' astro.config.mjs` prints `1`.
- [ ] `version.ts`: `grep -c '^declare const __AID_VERSION__: string;$' src/data/version.ts` and
  `grep -c '^export const VERSION: string = __AID_VERSION__;$' src/data/version.ts` each print `1`;
  `grep -cE '^export (const|type) (VERSION_TAG|InstallChannel|installCommands)\b' src/data/version.ts` prints `3`;
  `grep -c 'channelLabels\|release-data\|process\.env\|^import' src/data/version.ts` prints `0`.
- [ ] Changelog page: `test -f src/content/docs/releases/changelog.mdx` exits 0 and its content equals the
  Data Model 3 block of Feature 005, read from the spec:
  `awk '/^\*\*3\. The changelog page\.\*\*/{f=1; next} f && $0=="\140\140\140mdx"{p=1; next} p && $0=="\140\140\140"{exit} p' ../.aid/works/work-005-site-rework/REQUIREMENTS.md | diff - src/content/docs/releases/changelog.mdx`
  prints nothing and exits 0 (the extracted block is 17 lines; a different word, line or blank line fails);
  `grep -c '^title: Changelog$' src/content/docs/releases/changelog.mdx` prints `1`.
- [ ] Deleted and removed (Feature 005 step 2): `for p in src/pages src/components/Banner.astro src/lib/release-data.ts; do test -e "$p" && echo "present: $p"; done`
  prints nothing; `grep -c 'Banner' astro.config.mjs` prints `0`; `grep -c 'release-data' .gitignore` prints `0`
  and `grep -v '^$' .gitignore` prints exactly the three lines `node_modules/`, `dist/`, `.astro/`.
- [ ] Releases sidebar entry switched (delivery-003 gate): `grep -c "slug: 'releases/changelog'" astro.config.mjs`
  prints `1` and `grep -c "link: '/releases/changelog'" astro.config.mjs` prints `0`; no comment still names the
  deleted page: `grep -c 'changelog\.astro\|src/pages' astro.config.mjs` prints `0`.
- [ ] Build and version shown (AC-1, Data Model 2 "shown"): `npm run build` exits 0; `grep -c "v$V" dist/index.html`
  and `grep -c "v$V" dist/releases/changelog/index.html` each print at least `1`;
  `grep -c 'href="https://github.com/AndreVianna/aid-methodology/releases"' dist/releases/changelog/index.html`
  prints at least `1`; `grep -rl 'aid-banner' dist --include='*.html'` prints nothing.
- [ ] No network or environment in the version path (FR-12, NFR-4, the part this task owns):
  `grep -rnE --exclude-dir=__tests__ "fetch\(|node:https?|https?\.get\(|process\.env" src/components src/data astro.config.mjs`
  prints nothing. The legacy tests under `src/data/__tests__` still mention `process.env` here; task-030 deletes
  them, and its own full check (without the exclusion) covers them.
- [ ] Links (AC-6, by command): after the build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing.
- [ ] Audit rows: the AC-3 completeness check of Feature 001 § Data Model, run from `site/`, prints no line that
  contains `releases/changelog`; `grep -E '^\| .src/pages/releases/changelog\.astro. ' ../.aid/works/work-005-site-rework/site-audit.md | grep -c '| removed |'`
  prints `1` and `grep -E '^\| .src/content/docs/releases/changelog\.mdx. ' ../.aid/works/work-005-site-rework/site-audit.md | grep -c '| new |'`
  prints `1` (each `.` in the first pattern stands for the backtick around the path in the audit row).
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical VERSION` prints nothing; before this task's
  commit, `git status --porcelain --untracked-files=all site .aid/works/work-005-site-rework/site-audit.md`
  lists only `site/astro.config.mjs`, `site/src/data/version.ts`, `site/src/content/docs/releases/changelog.mdx`,
  `site/src/pages/releases/changelog.astro`, `site/src/components/Banner.astro`, `site/src/lib/release-data.ts`,
  `site/.gitignore` and `site-audit.md`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0. Unit tests: the version
  display's test is build case B3 (delivery-004, Feature 005 § Layers & Components); the legacy Vitest suite
  is not a criterion (PLAN.md Cross-Cutting Risks, row 1).
