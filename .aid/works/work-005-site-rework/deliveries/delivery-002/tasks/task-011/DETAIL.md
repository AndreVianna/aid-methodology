# task-011: Mermaid integration and node:fs import removed from astro.config.mjs

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

**Source:** feature-003-accessible-diagrams -> delivery-002 -> AC-8

**Depends on:** task-006, task-008, task-009, task-010

**Scope:**
- Feature 003 § Feature Flow, "Removal of Mermaid". This runs only once the last hand-written fence is
  gone: tasks 008-010 replace all ten. In `site/astro.config.mjs`, delete:
  - `import mermaid from 'astro-mermaid';`;
  - the whole `mermaid({...})` entry in `integrations`;
  - the `head` entry whose `attrs` is `{ 'data-aid': 'mermaid-source-cache' }`. It is the only `head`
    entry, so the `head` key goes with it;
  - every comment line that describes these:
    - the integration-order note at the top of the file;
    - the comments inside and above `mermaid({...})`;
    - the KI-018 comment above `head`;
  - `import { readFileSync } from 'node:fs';`, whose only use is that `head` entry. Feature 005 step 2
    adds it back in delivery-003 (Cross-Cutting Risk 2).
- Nothing else in the file changes. The `sidebar` and `redirects` written by task-006 stay as they are.
- Not in this task. Feature 005 does these in delivery-003, and Feature 004 handles the `.mermaid` CSS
  rules in `casulo.css`:
  - deleting `site/src/scripts/mermaid-source-cache.js`;
  - removing `astro-mermaid` / `@mermaid-js/layout-elk` from `package.json` and the lockfile.
  The build stays green because the config stops reading the file before the file is deleted.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`). Inside that set, only `site/astro.config.mjs`
    changes.

**Acceptance Criteria:**
- [ ] Precondition: from the repo root,
  `grep -rln '^```mermaid' site/src/content/docs --include='*.md*' | grep -v '/skills/'` prints nothing
  before this task's edit.
- [ ] AC-8, Mermaid gone from the config (delivery-002 gate): `grep -n 'mermaid' site/astro.config.mjs`
  prints nothing, and `grep -cE 'KI-018|head:' site/astro.config.mjs` prints `0`.
- [ ] `node:fs` import removed (delivery-002 gate, Cross-Cutting Risk 2):
  `grep -c "from 'node:fs'" site/astro.config.mjs` prints `0`, and `grep -c 'readFileSync' site/astro.config.mjs`
  prints `0`.
- [ ] Other keys untouched:
  - `grep -c "link: '/releases/changelog'" site/astro.config.mjs` prints `1`;
  - `grep -c "'/reference/skills': '/skills/'" site/astro.config.mjs` prints `1`;
  - `grep -cE "customCss|components:|social:" site/astro.config.mjs` prints the same number as before this
    task's edit.
- [ ] AC-1: from `site/`, `npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] No Mermaid on built pages. From `site/`, after the build:
  - `grep -rlE 'class="mermaid|data-language="mermaid"' dist --include='*.html'` prints nothing (U5; the
    skill pages carry no fence since Feature 002);
  - `grep -rl 'mermaid-source-cache' dist --include='*.html'` prints nothing.
- [ ] Configuration is idempotent: a second `npm run build` exits 0. No plaintext secrets: the diff only
  deletes lines.
- [ ] Facts untouched: from `site/`, `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/astro.config.mjs`.
  - `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
