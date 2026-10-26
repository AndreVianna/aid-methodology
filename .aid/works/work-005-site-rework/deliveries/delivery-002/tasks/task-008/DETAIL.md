# task-008: Pipeline diagrams D1, D2 and D10 on their host pages

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
  `title`, `desc`, `caption`, drawing and text equivalent exactly as Feature 003 § Data Model ("Content
  of each diagram") states them:
  - `Pipeline.astro`: D1, `id="pipeline"`, viewBox 400 x 720, text equivalent an `<ol>` of 6 items, item 3
    with its nested two-item list.
  - `TwoPaths.astro`: D2, `id="two-paths"`, 400 x 560, text equivalent the 9-row table (Step | Full path |
    Shortcut path) plus the `/aid-triage` `<p>`.
  - `TaskLoop.astro`: D10, `id="task-loop"`, 400 x 420, text equivalent an `<ol>` of 5 items.
- Each file follows the "Diagram file pattern":
  - it imports `../Diagram.astro` (task-007) and passes all six props;
  - ``const arrow = `url(#dg-${id}-arrow)` ``;
  - the shapes go in the default slot, the text equivalent in `slot="text"`.
  It obeys every "Drawing rules" bullet:
  - 8-unit grid, `rx="6"`;
  - edges as `path`/`line` with `marker-end={arrow}`, never crossing a label;
  - `rect.dg-label-bg` under edge labels;
  - at most two lines per box;
  - optional steps both `.dg-optional` and worded "optional" or "(if ...)";
  - only the allowed SVG elements;
  - no `style`/`fill`/`stroke`/`color` attribute;
  - commands written as their SKILL.md `argument-hint`;
  - tables with `<th scope="col">` headers and `<th scope="row">` first cells (UI Specs, Accessibility).
- Host pages, under `site/src/content/docs/`. The import paths follow Feature 003 § Feature Flow step 1.
  - `index.mdx`: the fence under "The pipeline at a glance" is replaced by `<Pipeline />`, imported from
    `'../../components/diagrams/Pipeline.astro'`.
  - `concepts/pipeline.mdx`: the § 1 The Pipeline fence is replaced by `<Pipeline />`, and the fence under
    "The Lite Path: Direct-Entry Shortcuts" by `<TwoPaths />`, both imported from
    `'../../../components/diagrams/...'`.
  - `guides/pipeline.mdx`:
    - The fence under "The pipeline at a glance" is deleted, and that section links to
      `/concepts/pipeline/` with link text that names the page (Feature 001 rules P7, P9).
    - `<TaskLoop />` is placed under `### Phase 6 — Execute`, before the next heading.
- Only the fence or image is replaced. The words around it are the audit tasks' (Feature 001 owns them).
- At most 150 lines per diagram file (Feature 003 § Layers & Components).
- Not in this task:
  - The other seven diagrams.
  - The Mermaid removal in `astro.config.mjs` (task-011).
  - Audit rows (set by the audit task of each host page, after this diagram is in place).
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`). Inside that set, only the three new files and the
    three host pages change.

**Acceptance Criteria:**
- [ ] Sizes: `wc -l site/src/components/diagrams/{Pipeline,TwoPaths,TaskLoop}.astro` shows each file at
  most 150 lines.
- [ ] Drawing rules in the source. Run each check below with `F` set to each of the three files.
  - `grep -cE "const id = '(pipeline|two-paths|task-loop)'" $F` prints `1`.
  - `grep -cE '\s(style|fill|stroke|color)=' $F` prints `0`.
  - `grep -cE '#[0-9a-fA-F]{3,8}\b|rgba?\(|hsla?\(|<script|tabindex' $F` prints `0`.
  - `grep -oE '<[A-Za-z][A-Za-z0-9]*' $F | sort -u | grep -vxE '<(Diagram|g|rect|circle|ellipse|path|line|polyline|polygon|text|tspan|ol|ul|li|table|thead|tbody|tr|th|td|p|code|a)'`
    prints nothing.
  - `grep -c '<th>' $F` prints `0`: every `th` has a `scope`.
- [ ] Words as specified. Each command prints at least `1`.
  - `grep -c 'Set AID up once with' site/src/components/diagrams/Pipeline.astro`
  - `grep -c 'GATE grades every document' site/src/components/diagrams/TwoPaths.astro`
  - `grep -c 'Below the minimum grade, the work goes back to FIX' site/src/components/diagrams/TaskLoop.astro`
  - each file holds its spec `desc` string verbatim; the check is `grep -cF` of the first sentence of the
    `desc`.
- [ ] Hosts. From `site/src/content/docs/`:
  - `grep -c '^```mermaid'` prints `0` for `index.mdx` and `guides/pipeline.mdx`.
  - `grep -c '^```mermaid' concepts/pipeline.mdx` prints `0`.
  - `grep -c '](/concepts/pipeline/' guides/pipeline.mdx` prints at least `1`.
  - `awk '/^### Phase 6/{f=1;next} /^#/{f=0} f&&/<TaskLoop/' guides/pipeline.mdx | wc -l` prints `1`.
- [ ] AC-1 and the placement counts of Feature 003 § Feature Flow, verification table. From `site/`,
  `npm run build` exits 0. Then
  `for f in dist/index.html dist/concepts/pipeline/index.html dist/guides/pipeline/index.html; do echo "$f $(grep -o '<figure class="diagram' "$f" | wc -l)"; done`
  prints exactly these three lines:
  - `dist/index.html 1`
  - `dist/concepts/pipeline/index.html 2`
  - `dist/guides/pipeline/index.html 1`
- [ ] Built markup (U2, U3, U6 by hand), from `site/`. The scoped style of `Diagram.astro` adds a
  `data-astro-cid-*` attribute to its elements, so tags are matched by name plus an attribute fragment,
  never with their closing `>`. Each command prints `1`:
  - `tr -d '\n' < dist/index.html | grep -oE '<title [^>]*id="dg-pipeline-title"[^>]*>The AID pipeline</title>' | wc -l`;
  - `grep -o 'aria-describedby="dg-two-paths-desc"' dist/concepts/pipeline/index.html | wc -l`;
  - `grep -o 'id="dg-task-loop"' dist/guides/pipeline/index.html | wc -l`.
- [ ] No link and no `foreignObject` inside a drawing (U6). From `site/`, this loop prints nothing (it
  cuts each page after every `</svg>`, keeps the `<svg role="img"` drawings, and reports any `<a ` or
  `<foreignObject` inside them, or a page with no drawing at all):
  `for f in dist/index.html dist/concepts/pipeline/index.html dist/guides/pipeline/index.html; do D=$(tr -d '\n' < "$f" | sed 's#</svg>#</svg>\n#g' | grep -oE '<svg [^>]*role="img".*</svg>'); [ -n "$D" ] || echo "no drawing: $f"; printf '%s\n' "$D" | grep -qE '<a |<foreignObject' && echo "link or foreignObject in drawing: $f"; done`
- [ ] The drawing matches the text equivalent (judged by the reviewer, reading each file's shapes and
  labels against Feature 003 § Data Model for D1, D2 and D10): every box and edge stands for a step or
  link of the text equivalent and nothing else; optional steps are dashed and worded as optional; no
  edge path crosses a `<text>` box.
- [ ] Facts untouched: from `site/`, `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only the three
    diagram files, `index.mdx`, `concepts/pipeline.mdx` and `guides/pipeline.mdx`.
  - `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
