# task-006: Page-set cut-over: stub pages removed, redirects and final sidebar

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

**Source:** feature-001-content-audit -> delivery-002 -> AC-3

**Depends on:** task-005

**Scope:**
- Feature 001 § Feature Flow step 6, the configuration half of § Migration Plan. Everything below lands in
  one commit, because Astro rejects a redirect whose source is still a page.
- Delete these five pages under `site/src/content/docs/`. Their text was moved by task-005.
  - `get-started/index.md`
  - `concepts/index.md`
  - `reference/index.md`
  - `concepts/overview.md`
  - `reference/skills.md`
- `site/astro.config.mjs`, two keys only (PLAN.md delivery-002 Notes):
  - Add a top-level `redirects` object, exactly the five entries of Feature 001 § Migration Plan:
    - `/get-started` to `/get-started/overview/`
    - `/concepts` and `/concepts/overview` to `/concepts/methodology/`
    - `/reference` to `/reference/overview/`
    - `/reference/skills` to `/skills/`
  - Replace the `sidebar` array with Feature 001's "Final sidebar", with two exceptions:
    - The Skills group stays byte-for-byte as it is today (Feature 002 owns it), in the position the
      spec shows.
    - The Releases entry keeps the interim `{ label: 'Changelog', link: '/releases/changelog' }`
      (Feature 001 § Migration Plan; PLAN.md delivery-002 Notes), because `releases/changelog.mdx` does
      not exist until delivery-003.
  - The comment lines inside the replaced array go with it.
  - The "Sidebar contract" lines of the file's header comment are made true for the new array, or deleted.
  - No other key, import or comment changes. The Mermaid lines and the `node:fs` import are task-011's.
- Audit file `.aid/works/work-005-site-rework/site-audit.md`:
  - In § Pages, the rows of the five deleted pages take verdict `removed`. Each Correction cell names the
    redirect target, and for `reference/skills.md` also the page that took its text
    (`/get-started/lite-path/`).
  - In § Redirects, each row's status becomes `done`.
  - No other row changes.
- Not in this task:
  - No page text edited. Links in other pages to the removed URLs still resolve through the redirects;
    re-pointing them is the audit tasks' P9/P7 work.
  - No `<Tabs>` change, no `components`, `customCss`, `head` or `integrations` change.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`). Inside that set, only the five deletions,
    `site/astro.config.mjs` and the audit file change.

**Acceptance Criteria:**
- [ ] Pages gone: from `site/src/content/docs/`, this loop prints nothing:
  `for p in get-started/index.md concepts/index.md reference/index.md concepts/overview.md reference/skills.md; do test -e "$p" && echo "present: $p"; done`.
- [ ] AC-1: from `site/`, `npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] Redirects: from `site/`, each command below prints `1`. Each target is the URL in Feature 001
  § Migration Plan.
  - `grep -cE 'http-equiv="refresh"[^>]*url=/get-started/overview/' dist/get-started/index.html`
  - `grep -cE 'http-equiv="refresh"[^>]*url=/concepts/methodology/' dist/concepts/index.html`
  - `grep -cE 'http-equiv="refresh"[^>]*url=/concepts/methodology/' dist/concepts/overview/index.html`
  - `grep -cE 'http-equiv="refresh"[^>]*url=/reference/overview/' dist/reference/index.html`
  - `grep -cE 'http-equiv="refresh"[^>]*url=/skills/' dist/reference/skills/index.html`
- [ ] Interim Releases entry (delivery-002 gate): `grep -c "link: '/releases/changelog'" site/astro.config.mjs`
  prints `1` and `grep -c "slug: 'releases/changelog'" site/astro.config.mjs` prints `0`.
- [ ] Final sidebar slugs:
  - `grep -cE "slug: '(concepts/overview|reference/skills)'" site/astro.config.mjs` prints `0`.
  - `for s in concepts/pipeline concepts/knowledge-base concepts/agents concepts/feedback-loops concepts/case-studies concepts/aid-and-sdd reference/cli reference/kb contact/contact-request; do [ "$(grep -c "slug: '$s'" site/astro.config.mjs)" = 1 ] || echo "slug not once: $s"; done`
    prints nothing.
  - `grep -c "label: 'Home', slug: ''" site/astro.config.mjs` prints `1`.
  - From `site/`, after the build, `dist/index.html` holds a link to each of `/concepts/pipeline/` and
    `/concepts/aid-and-sdd/`.
- [ ] Skills group untouched. `git diff site-aid -- site/astro.config.mjs` changes no line from
  `label: 'Skills',` to the end of that group's `items` array: the four lines
  `{ label: 'All skills', slug: 'skills' },`, `label: 'Every skill',`, `collapsed: true,` and
  `items: [{ autogenerate: { directory: 'skills' } }],` each still appear exactly once.
- [ ] Only `sidebar`, `redirects` and the header comment changed in `site/astro.config.mjs`, so the
  Mermaid lines are unchanged:
  - `grep -c 'mermaid' site/astro.config.mjs` prints the same number as
    `git show site-aid:site/astro.config.mjs | grep -c 'mermaid'`;
  - `grep -c "from 'node:fs'" site/astro.config.mjs` prints `1`.
- [ ] Audit rows. From `site/`, the AC-3 completeness check of Feature 001 § Data Model, piped through
  `grep -E 'src/content/docs/(get-started|concepts|reference)/index\.md|concepts/overview\.md|reference/skills\.md'`,
  prints nothing. `sed -n '/^## Redirects/,/^## /p' ../.aid/works/work-005-site-rework/site-audit.md | grep -c '| planned |'`
  prints `0`.
- [ ] Configuration is idempotent: a second `npm run build` exits 0 with the same five redirect pages.
  No plaintext secrets: the diff adds no token, key or URL with credentials.
- [ ] Facts untouched: from `site/`, `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only the five
    deletions and `site/astro.config.mjs`.
  - `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
