# task-005: Methodology page split into the Concepts pages

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

**Type:** REFACTOR

**Source:** feature-001-content-audit -> delivery-002 -> AC-3

**Depends on:** task-004

**Scope:**
- Feature 001 § Feature Flow step 6, the text half of § Migration Plan ("Why the methodology page splits",
  "File extensions" and the split table). This task moves text; it does not correct it. The audit and
  plain-language rewrite of every page touched here is a later task. All paths are under
  `site/src/content/docs/`.
- Rename: `git mv concepts/methodology.md concepts/methodology.mdx`, in the same commit as the split. The
  URL `/concepts/methodology/` stays the same.
- Create, by moving the sections of the old page without rewording them:
  - `concepts/pipeline.mdx`: § 1 The Pipeline and § 4 The Phases.
  - `concepts/knowledge-base.mdx`: § 3 The Knowledge Base.
  - `concepts/agents.mdx`: § 5 The Agent Model. The agent roster stays on `reference/agents`.
  - `concepts/feedback-loops.mdx`: § 6 Feedback Loops.
  - `concepts/case-studies.md`: § 8 Case Studies. It hosts no diagram, so it stays `.md`.
  - `concepts/aid-and-sdd.mdx`: § 9 Comparison with SDD.
  Each new page gets frontmatter with `title` set to its sidebar label from Feature 001's final sidebar
  ("The pipeline", "Knowledge Base", "Agents", "Feedback loops", "Case studies", "AID and spec-driven
  development") and a `description`. A later task writes the final P1 sentence. No `sourceDoc:` key is
  added to any page.
- `concepts/methodology.mdx` keeps its frontmatter, including its `sourceDoc:` line (Feature 005 step 4
  removes it in delivery-003), and § 2 Philosophy. Above § 2 it gets a short intro with one link to each
  Concepts page. The intro takes over the pointers of `concepts/overview.md`. The § Table of Contents
  is deleted (P8).
- Merge into existing pages:
  - § 7 Artifacts Reference goes into `reference/artifacts.md`. Its own heading `7. Artifacts Reference`
    is dropped (the page's `h1` takes its place); its two child headings survive, raised to `##` because
    the page body starts at `##`: `## Core Artifacts` (the table, moved as is) and
    `## Templates Reference`. Under `## Templates Reference`, each template excerpt is replaced by a
    link to that template under
    `https://github.com/AndreVianna/aid-methodology/blob/master/canonical/aid/templates/`, so the
    heading stays and holds the links. The page's "Sync manifest" and "Reference manifest" rows stay
    (PLAN.md delivery-002 Notes).
  - § 10 Adoption Guide:
    - The brownfield and greenfield starts go into `get-started/first-work.mdx`.
    - Anti-Patterns goes into `concepts/faq.md`.
    - "Getting AID onto Your Machine" is dropped, because the install pages hold it.
    - The spec names no target for "Using the Direct-Entry Shortcuts" and "Adopting Incrementally". They
      move with the adoption text into `get-started/first-work.mdx`, where the Home and Get Started audit
      applies P9.
  - The shortcut-engine text of `reference/skills.md` (its § Direct-entry shortcuts, including the links
    to `canonical/aid/templates/shortcut-engine.md` and `canonical/aid/templates/shortcut-catalog.yml`,
    which `lite-path.mdx` does not hold today) goes into `get-started/lite-path.mdx`. Removing the
    duplicate wording there is the later audit's job. `reference/skills.md`, `concepts/overview.md` and
    the three `index.md` stubs are not deleted here: task-006 deletes them together with their redirects.
- Diagrams move with their sections, unchanged (Feature 001 § Layers & Components, Boundaries). After
  the split:
  - The seven Mermaid fences of the old page sit in `pipeline.mdx` (2: § 1 and "The Lite Path:
    Direct-Entry Shortcuts"), `knowledge-base.mdx` (2), `agents.mdx` (1), `feedback-loops.mdx` (1) and
    `aid-and-sdd.mdx` (1).
  - The `3-ironman.png` image stays in `methodology.mdx`, under "The Iron Man Model".
  Tasks 008-010 replace them.
- MDX escaping: in every `.mdx` page, a literal `{`, `}` or `<` outside code is escaped (`\{`, `\}`,
  `&lt;`). Heading text is kept. A heading level changes only where P8 needs it: the body starts at `##`
  and never skips a level.
- Links:
  - A same-page link (`](#...)`) whose target section moved is re-pointed to its new page and anchor.
  - The same applies to every link from a hand-written page to `/concepts/methodology/#<anchor>`.
  - Generated pages (Feature 002) are not edited.
- Page weight: every new or kept page builds to at most 150 KB. A page that does not is split again
  along its `##` sections (Feature 001 § Migration Plan).
- Not in this task:
  - No edit of `site/astro.config.mjs` (sidebar and redirects are task-006).
  - No diagram component (tasks 007-010).
  - No claim corrected and no audit row changed (the audit tasks do both).
  - No `<Tabs>` conversion (Feature 004, delivery-003).
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`). Inside that set, only the pages named above change.

**Acceptance Criteria:**
- [ ] Page set: from `site/src/content/docs/`, `ls concepts | LC_ALL=C sort` prints exactly these ten
  lines, in this order: `agents.mdx`, `aid-and-sdd.mdx`, `case-studies.md`, `faq.md`, `feedback-loops.mdx`,
  `index.md`, `knowledge-base.mdx`, `methodology.mdx`, `overview.md`, `pipeline.mdx` (`agents` sorts before
  `aid-and-sdd` because `g` precedes `i`). `test -e concepts/methodology.md` exits 1.
- [ ] Text preserved, checked by headings. Every heading of the old page outside code fences, except
  `Table of Contents`, `Getting AID onto Your Machine`, `7. Artifacts Reference` and `10. Adoption Guide`,
  occurs exactly once across the target pages. From `site/src/content/docs/`, with
  `hl() { awk '/^ *(```|~~~)/{c=!c;next} !c&&/^#+ /{sub(/^#+ /,"");print}' "$@"; }` and
  `H=$(hl concepts/{methodology,pipeline,knowledge-base,agents,feedback-loops,aid-and-sdd}.mdx concepts/case-studies.md concepts/faq.md reference/artifacts.md get-started/first-work.mdx)`,
  the loop `git show site-aid:site/src/content/docs/concepts/methodology.md | hl | grep -vxE 'Table of Contents|Getting AID onto Your Machine|7\. Artifacts Reference|10\. Adoption Guide' | while IFS= read -r h; do [ "$(printf '%s\n' "$H" | grep -cxF -- "$h")" = 1 ] || echo "missing or doubled: $h"; done`
  prints nothing.
- [ ] Diagrams moved, not lost. `grep -c '^```mermaid'` gives:
  - `concepts/pipeline.mdx` 2, `knowledge-base.mdx` 2, `agents.mdx` 1, `feedback-loops.mdx` 1,
    `aid-and-sdd.mdx` 1;
  - `methodology.mdx` 0, `case-studies.md` 0.
  `grep -c '3-ironman.png' concepts/methodology.mdx` prints `1`. From the repo root,
  `grep -rl '^```mermaid' site/src/content/docs --include='*.md*' | grep -v '/skills/' | wc -l` prints `8`,
  the pages holding the 10 fences of Feature 003 § Data Model.
- [ ] Merges done:
  - `grep -ciE '^#+ table of contents' concepts/methodology.mdx` prints `0`.
  - `grep -c 'canonical/aid/templates/' reference/artifacts.md` prints at least `1`, and the old § 7
    template excerpts are gone: `grep -cE '^## [0-9]+\. (Objective|Problem Statement)' reference/artifacts.md`
    prints `0`.
  - `grep -cE '^#+ .*(Brownfield|Greenfield)' get-started/first-work.mdx` prints `2`.
  - `grep -c 'Anti-Patterns' concepts/faq.md` prints at least `1`.
  - § 7's child headings survive on the artifacts page:
    `grep -cxE '## (Core Artifacts|Templates Reference)' reference/artifacts.md` prints `2`.
  - The shortcut-engine text reached the lite path page before task-006 deletes `reference/skills.md`
    (both print `0` before this task): `grep -c 'canonical/aid/templates/shortcut-engine.md' get-started/lite-path.mdx`
    and `grep -c 'canonical/aid/templates/shortcut-catalog.yml' get-started/lite-path.mdx` each print at
    least `1`.
  - The intro links to every Concepts page: for each `p` in `pipeline knowledge-base agents feedback-loops
    case-studies aid-and-sdd`, `grep -c "](/concepts/$p/" concepts/methodology.mdx` prints at least `1`.
- [ ] No behaviour change (REFACTOR). From `site/`, `npm run build` exits 0 before this task's edits and
  after them, and `test -f dist/index.html` exits 0 (AC-1). After the build, each of
  `dist/concepts/{methodology,pipeline,knowledge-base,agents,feedback-loops,case-studies,aid-and-sdd}/index.html`
  exists and `/concepts/methodology/` is still served at the same URL.
- [ ] Links into moved sections resolve. From `site/`, after the build, the link check prints no line for
  a page under `/concepts/` and no line naming a target under `/concepts/`:
  `node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);" | grep -E '(^/concepts/|-> /concepts/)'`
  prints nothing.
- [ ] Page weight: from `site/`, `find dist/concepts dist/reference dist/get-started -name '*.html' -size +150k`
  prints nothing.
- [ ] Facts untouched: from `site/`, `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing, and `git diff --name-only site-aid...HEAD -- canonical` prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only paths under
    `site/src/content/docs/concepts/` and the files `reference/artifacts.md`, `get-started/first-work.mdx`
    and `get-started/lite-path.mdx`.
  - `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
