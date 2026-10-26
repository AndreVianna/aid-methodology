# task-010: Diagrams D7, D8 and D9: feedback loops, AID vs SDD, release flow

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

**Source:** feature-003-accessible-diagrams -> delivery-002 -> AC-8

**Depends on:** task-005, task-007

**Scope:**
- Create three diagram components under `site/src/components/diagrams/`. Each takes its `id`, viewBox,
  `title`, `desc`, `caption`, drawing and text equivalent exactly as Feature 003 § Data Model states them.
  - `FeedbackLoops.astro`: D7, `id="feedback-loops"`, viewBox 480 x 640.
    - Text equivalent: the loop table of § The Eleven Loops, moved out of the page's Markdown into the
      slot as a `<table>` with header row Loop | From | To | When. Its rows are moved as they are today;
      the Concepts audit task checks and corrects them in this file, as D7's "Source" bullet states.
    - Drawing: one badge `L1` ... `L11` per row, on dashed arcs spaced 16 units apart. L11 starts from a
      dashed bracket. Only the badge is drawn.
    - The page keeps its prose explanation of the loops.
  - `AidVsSdd.astro`: D8, `id="aid-vs-sdd"`, 400 x 600, text equivalent the 8-row table (Step | Spec-driven
    development | AID). The AID column is titled "AID (AI Integrated Development)".
  - `ReleaseFlow.astro`: D9, `id="release-flow"`, 400 x 520, text equivalent an `<ol>` of 6 items. Checked
    against `.github/workflows/release.yml`: trigger `tags: ['v*']`, jobs `gate`, `github-release`,
    `npm-publish` and `pypi-publish`, with their `needs:` and `if:`.
- Each file follows the "Diagram file pattern":
  - it imports `../Diagram.astro` (task-007) and passes all six props;
  - ``const arrow = `url(#dg-${id}-arrow)` ``;
  - the shapes go in the default slot, the text equivalent in `slot="text"`.
  It obeys every "Drawing rules" bullet:
  - 8-unit grid, `rx="6"`;
  - edges never cross a label;
  - `rect.dg-label-bg` under edge labels;
  - optional parts (Deploy, Monitor, npm-publish, pypi-publish) both `.dg-optional` and worded "optional"
    or "(if ...)";
  - only the allowed SVG elements;
  - no `style`/`fill`/`stroke`/`color` attribute;
  - tables with `<th scope="col">` headers and `<th scope="row">` first cells.
- Host pages. The components are imported per Feature 003 § Feature Flow step 1.
  - `site/src/content/docs/concepts/feedback-loops.mdx`: the § 6 fence is replaced by
    `<FeedbackLoops />`, and the Markdown loop table under "The Eleven Loops" is deleted, because the
    component now holds it.
  - `site/src/content/docs/concepts/aid-and-sdd.mdx`: the fence under "Where We Diverge" is replaced by
    `<AidVsSdd />`.
  - `site/src/content/docs/guides/maintainer.mdx`: the fence under "How releases work" is replaced by
    `<ReleaseFlow />`, imported from `'../../../components/diagrams/ReleaseFlow.astro'`.
- Only the fence and the loop table change on the hosts; the other words are the audit tasks'. The
  "AI-Assisted Development" correction is recorded by the Concepts audit in the `concepts/aid-and-sdd.mdx`
  row (Feature 003, D8).
- Sizes: at most 150 lines per file, except `FeedbackLoops.astro`, which may have at most 200.
- Not in this task:
  - The other seven diagrams.
  - `astro.config.mjs`.
  - Audit rows.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`. `release.yml` is read, never run.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/` or `.github/workflows/release.yml`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`). Inside that set, only the three new files and the
    three host pages change.

**Acceptance Criteria:**
- [ ] Sizes: `wc -l site/src/components/diagrams/{AidVsSdd,ReleaseFlow}.astro` shows each file at most 150
  lines, and `wc -l < site/src/components/diagrams/FeedbackLoops.astro` prints at most 200.
- [ ] Drawing rules in the source. Run each check below with `F` set to each of the three files.
  - `grep -cE "const id = '(feedback-loops|aid-vs-sdd|release-flow)'" $F` prints `1`.
  - `grep -cE '\s(style|fill|stroke|color)=' $F` prints `0`.
  - `grep -cE '#[0-9a-fA-F]{3,8}\b|rgba?\(|hsla?\(|<script|tabindex' $F` prints `0`.
  - `grep -oE '<[A-Za-z][A-Za-z0-9]*' $F | sort -u | grep -vxE '<(Diagram|g|rect|circle|ellipse|path|line|polyline|polygon|text|tspan|ol|ul|li|table|thead|tbody|tr|th|td|p|code|a)'`
    prints nothing.
  - `grep -c '<th>' $F` prints `0`.
- [ ] D7 holds the loops once:
  - in `FeedbackLoops.astro`, `grep -cE '<th scope="row">L([1-9]|1[01])</th>'` prints `11`, and the badge
    count `grep -cE '>L([1-9]|1[01])<'` is at least `11`;
  - `grep -cE '^\| L([1-9]|1[01]) \|' site/src/content/docs/concepts/feedback-loops.mdx` prints `0` (the
    Markdown table is gone).
- [ ] D8 and D9 words:
  - `grep -c 'AI Integrated Development' site/src/components/diagrams/AidVsSdd.astro` prints at least `1`;
  - `grep -c 'AI-Assisted' site/src/components/diagrams/AidVsSdd.astro` prints `0`;
  - in `ReleaseFlow.astro`, `grep -c 'NPM_ENABLED'` and `grep -c 'PYPI_ENABLED'` each print at least `1`.
  - Each job name in `ReleaseFlow.astro` exists in the workflow:
    `for j in gate github-release npm-publish pypi-publish; do grep -q "^  $j:" .github/workflows/release.yml || echo "no job $j"; done`
    prints nothing.
- [ ] Hosts: `grep -c '^```mermaid'` prints `0` for `concepts/feedback-loops.mdx`, `concepts/aid-and-sdd.mdx`
  and `guides/maintainer.mdx` (under `site/src/content/docs/`).
- [ ] AC-1 and placement counts (Feature 003 verification table). From `site/`, `npm run build` exits 0.
  Then
  `for f in dist/concepts/feedback-loops/index.html dist/concepts/aid-and-sdd/index.html dist/guides/maintainer/index.html; do echo "$f $(grep -o '<figure class="diagram' "$f" | wc -l)"; done`
  prints each of the three paths followed by ` 1`.
- [ ] Built markup, from `site/`. The scoped style of `Diagram.astro` adds a `data-astro-cid-*` attribute
  to its elements, so tags are matched by name plus an attribute fragment, never with their closing `>`.
  Each command prints `1`:
  - `grep -o 'aria-labelledby="dg-feedback-loops-title"' dist/concepts/feedback-loops/index.html | wc -l`;
  - `tr -d '\n' < dist/guides/maintainer/index.html | grep -oE '<desc [^>]*id="dg-release-flow-desc"' | wc -l`.
- [ ] No link and no `foreignObject` inside a drawing (U6). From `site/`, this loop prints nothing (it
  cuts each page after every `</svg>`, keeps the `<svg role="img"` drawings, and reports any `<a ` or
  `<foreignObject` inside them, or a page with no drawing at all):
  `for f in dist/concepts/feedback-loops/index.html dist/concepts/aid-and-sdd/index.html dist/guides/maintainer/index.html; do D=$(tr -d '\n' < "$f" | sed 's#</svg>#</svg>\n#g' | grep -oE '<svg [^>]*role="img".*</svg>'); [ -n "$D" ] || echo "no drawing: $f"; printf '%s\n' "$D" | grep -qE '<a |<foreignObject' && echo "link or foreignObject in drawing: $f"; done`
- [ ] The drawing matches the text equivalent (judged by the reviewer, reading each file's shapes and
  labels against Feature 003 § Data Model for D7 to D9): every arc, badge, box and edge stands for a row
  or step of the text equivalent and nothing else; D7 badges do not overlap (arcs 16 units apart); no
  edge path crosses a `<text>` box.
- [ ] Facts untouched: from `site/`, `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site .github` lists only the
    three diagram files and the three host pages.
  - `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
