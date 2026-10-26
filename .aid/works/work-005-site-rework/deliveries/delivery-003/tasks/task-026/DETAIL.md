# task-026: Social links and code-block copy button settings in astro.config.mjs

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

**Type:** CONFIGURE

**Source:** feature-004-look-and-layout -> delivery-003 -> AC-15

**Depends on:** task-025

**Scope:**
- In the `starlight({ ... })` options of `site/astro.config.mjs`, set the two keys exactly as Feature 004
  § Layers & Components, "`astro.config.mjs`", writes them, each verbatim on one line:
  - `social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/AndreVianna/aid-methodology' }],`
    (the Casulo AI Labs entry leaves: the header logo already links to casuloailabs.com), replacing the
    current multi-line `social` array and its comment;
  - `expressiveCode: { frames: { showCopyToClipboardButton: false } },` (new key: the copy button's script is
    none of the three kinds NFR-2 allows; a command stays copyable by selection).
- No other key is edited (`customCss` is task-024's, `components` task-025's; `Banner`, `Head`, the version
  read and the sidebar Releases entry are Feature 005's, tasks 028 and 029).
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no change to any path outside the
  AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than `site/astro.config.mjs`.

**Acceptance Criteria:**

Run from `site/` unless stated.

- [ ] Keys verbatim: `grep -cF "social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/AndreVianna/aid-methodology' }]," astro.config.mjs`
  prints `1`; `grep -cF "expressiveCode: { frames: { showCopyToClipboardButton: false } }," astro.config.mjs`
  prints `1`; `grep -c "icon: 'external'" astro.config.mjs` prints `0`; `grep -c 'social:' astro.config.mjs`
  prints `1`.
- [ ] Build: `npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] Copy button and its script gone (NFR-2, AC-15): `grep -rl 'title="Copy to clipboard"' dist --include='*.html'`
  prints nothing and `grep -rlF 'navigator.clipboard' dist --include='*.html' --include='*.js'` prints nothing;
  code blocks still render: `grep -c 'class="expressive-code' dist/guides/installation/index.html` prints at
  least `1`.
- [ ] One social link: `grep -o 'href="https://casuloailabs.com"' dist/skills/aid-define/index.html | wc -l`
  prints `1` (the header logo only), and `grep -c 'href="https://github.com/AndreVianna/aid-methodology"' dist/skills/aid-define/index.html`
  prints at least `1`.
- [ ] Configuration is idempotent (CONFIGURE default): the two lines are plain literals; building twice in a row
  (`npm run build` again) exits 0 and leaves `git status --porcelain astro.config.mjs src` unchanged between the
  two runs.
- [ ] No plaintext secrets (CONFIGURE default): `git diff site-aid...HEAD -- astro.config.mjs | grep -iE 'token|secret|password|api[_-]?key'`
  prints nothing.
- [ ] Links: after the build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's commit,
  `git status --porcelain --untracked-files=all site` lists only `site/astro.config.mjs`;
  `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
