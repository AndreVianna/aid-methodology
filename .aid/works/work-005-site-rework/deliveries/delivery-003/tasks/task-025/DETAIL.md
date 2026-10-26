# task-025: One-row header override and PageTitle override removed

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

**Source:** feature-004-look-and-layout -> delivery-003 -> AC-9, AC-10, AC-11

**Depends on:** task-024

**Scope:**
- Rewrite `site/src/components/overrides/Header.astro` exactly as Feature 004 § Layers & Components,
  "`Header.astro`", gives it: the four imports (`Search`, `SocialIcons`, `ThemeSelect` from
  `@astrojs/starlight/components/`, and `logo` from `../../assets/casulo-ai-labs.png`); the markup in that order
  (logo link to `https://casuloailabs.com` with `alt="Casulo AI Labs"` and no `target="_blank"`, the
  `aid-brand` home link "AID" with the `aid-brand-long` span " AI Integrated Development", then
  `aid-header-end` holding `SocialIcons` + `ThemeSelect` in `sl-hidden md:sl-flex aid-prefs print:hidden`,
  then `Search` in `print:hidden`); a scoped `<style>` with a flex row, the logo 30px high and
  `.aid-brand-long` hidden below 50rem, tokens only (no colour literal). Budget: at most 60 lines with its
  `<style>`. The header layout per width follows Feature 004 § UI Specs, "Layout" (height 3.5rem, `nav`
  background, `border` bottom line).
- Delete `site/src/components/overrides/PageTitle.astro` (`git rm`) and, in the same change, remove the
  `PageTitle` entry (and the comment above the map's `Header`/`PageTitle` lines that describes the old
  two-row shell) from the `components` map of `site/astro.config.mjs`. The `Header`, `Footer`, `Banner` and
  `Head` entries stay (Feature 004 removes only `PageTitle`; `Banner` and `Head` leave in task-028 and
  task-029). No other key of `astro.config.mjs` is edited.
- The two comments of `astro.config.mjs` that list or count the map's keys become false with this removal, so
  this task owns them: the file-header paragraph "components: map is OWNED HERE. It already holds four keys
  (Header, PageTitle, Banner, Footer) — do not rewrite the map, only add. ..." and the comment directly above
  `components: {` ("Already holds four keys below; ..."). Each is reworded so it names no key and states no
  count (for example "components: map is OWNED HERE; add to it, do not rewrite it."), so neither this task's
  `PageTitle` check nor task-028's `Banner` check is held up by a comment.
- `src/assets/casulo-ai-labs.png` is kept unchanged (Feature 005, "Components and config after the cut").
- Not in this task (binding): no deploy, no publish, no push, no tag, no `npm publish`; no network use other
  than `npm ci` / `npm install` run from `site/`; no edit under `canonical/`; no change to any path outside the
  AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10 KB documents,
  `.aid/works/work-005-site-rework/`), and inside it no file other than `Header.astro`, `PageTitle.astro` and
  `astro.config.mjs`. The `social` and `expressiveCode` keys are task-026.

**Acceptance Criteria:**

Run from `site/` unless stated.

- [ ] Size and imports: `wc -l < src/components/overrides/Header.astro` prints at most `60`;
  `grep -cE "^import (Search|SocialIcons|ThemeSelect) from '@astrojs/starlight/components/(Search|SocialIcons|ThemeSelect)\.astro';$" src/components/overrides/Header.astro`
  prints `3` and `grep -c "^import logo from '../../assets/casulo-ai-labs.png';$" src/components/overrides/Header.astro`
  prints `1`; `grep -c '^import' src/components/overrides/Header.astro` prints `4`.
- [ ] No new tab, tokens only: `grep -c 'target="_blank"' src/components/overrides/Header.astro` prints `0`;
  `grep -nEi '#[0-9a-f]{3,8}\b|rgba?\(|hsla?\(' src/components/overrides/Header.astro` prints nothing;
  `grep -c '50rem' src/components/overrides/Header.astro` prints at least `1`.
- [ ] PageTitle gone: `test -e src/components/overrides/PageTitle.astro` exits 1; `grep -c 'PageTitle' astro.config.mjs`
  prints `0` (the header comment included); `grep -cE "^\s*(Header|Footer|Banner|Head): '" astro.config.mjs` prints `4`.
- [ ] Key-listing comments reworded (fails before: the file has two "four keys" comments):
  `grep -c 'four keys' astro.config.mjs` prints `0`, and
  `grep -E '^//' astro.config.mjs | grep -cE 'Header|PageTitle|Banner|Footer'` prints `0` (the file-header comment
  names no component key).
- [ ] Build: `npm run build` exits 0 and `test -f dist/index.html` exits 0.
- [ ] Header order in the built page (AC-9 order, by command): `node -e "const h=require('fs').readFileSync('dist/skills/aid-define/index.html','utf8'); const s=h.slice(h.indexOf('<header'), h.indexOf('</header>')); const m=['href=\"https://casuloailabs.com\"','class=\"aid-brand','href=\"https://github.com/AndreVianna/aid-methodology\"','starlight-theme-select','site-search']; const i=m.map(x=>s.indexOf(x)); console.log(i.every((v,k)=>v>=0&&(k===0||v>i[k-1])))"`
  prints `true`; the same command on `dist/index.html` prints `true`.
- [ ] One `h1` from Starlight's own `PageTitle` (AC-10 by command; S2 is delivery-004's test):
  `grep -o '<h1' dist/skills/aid-define/index.html | wc -l` prints `1`, `grep -c 'id="_top"' dist/skills/aid-define/index.html`
  prints `1` and `grep -c 'href="#_top"' dist/skills/aid-define/index.html` prints at least `1` (skip link
  target intact); no breadcrumb or eyebrow markup of the old override remains:
  `grep -rlE 'aid-breadcrumb|aid-eyebrow' src dist --include='*.astro' --include='*.html'` prints nothing.
- [ ] Old two-row shell gone: `grep -rlE 'aid-tabs|aid-header-bar|aid-casulo|aid-brand-sep' src/components dist/index.html` prints nothing
  (the section tabs go, Feature 004 § Migration Plan).
- [ ] Links: after the build,
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"`
  prints nothing.
- [ ] Facts untouched: `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
  prints nothing; `git diff --name-only site-aid...HEAD -- canonical` prints nothing; before this task's commit,
  `git status --porcelain --untracked-files=all site` lists only `site/src/components/overrides/Header.astro`,
  `site/src/components/overrides/PageTitle.astro` and `site/astro.config.mjs`; `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass: here, the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute) as they apply to one task -- from the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0. Unit tests: the header's
  automated checks are S5, S6 and K4 of delivery-004 (Feature 004 § Layers & Components); the visual and
  keyboard result is task-034's (AC-9, AC-11).
