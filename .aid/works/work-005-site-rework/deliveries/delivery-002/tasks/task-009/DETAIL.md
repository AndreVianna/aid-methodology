# task-009: Concepts diagrams D3 to D6 and removal of the Iron Man image

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
- Create four diagram components under `site/src/components/diagrams/`. Each takes its `id`, viewBox,
  `title`, `desc`, `caption`, drawing and text equivalent exactly as Feature 003 § Data Model states them.
  - `ReviewLoop.astro`: D3, `id="review-loop"`, viewBox 400 x 420, text equivalent an `<ol>` of 5 items.
  - `KbStructure.astro`: D4, `id="kb-structure"`, 400 x 440. Its text equivalent is the 5-row table (Part |
    Files | Written by). The phrase "the Knowledge Base documents page" in that table links to
    `/reference/kb/`.
  - `ContextLoading.astro`: D5, `id="context-loading"`, 400 x 300, text equivalent an `<ol>` of 3 items. The
    spec's "Diagram file pattern" is this file, abridged.
  - `AgentTiers.astro`: D6, `id="agent-tiers"`, 400 x 360. Its text equivalent is the 3-row table (Tier | Work
    it gets | Examples) plus the `<p>` that links to `/reference/agents/`. Per the spec, no agent name
    appears in the drawing.
- Each file follows the "Diagram file pattern":
  - it imports `../Diagram.astro` (task-007) and passes all six props;
  - ``const arrow = `url(#dg-${id}-arrow)` ``;
  - the shapes go in the default slot, the text equivalent in `slot="text"`.
  It obeys every "Drawing rules" bullet:
  - 8-unit grid, `rx="6"`;
  - edges as `path`/`line` with `marker-end={arrow}`, never crossing a label;
  - `rect.dg-label-bg` under edge labels;
  - at most two lines per box;
  - optional parts both `.dg-optional` and worded "optional";
  - only the allowed SVG elements;
  - no `style`/`fill`/`stroke`/`color` attribute;
  - link text that names its destination (P7);
  - tables with `<th scope="col">` headers and `<th scope="row">` first cells.
- Host pages, under `site/src/content/docs/concepts/`. The components are imported from
  `'../../../components/diagrams/...'`.
  - `methodology.mdx`: the `3-ironman.png` image line under "The Iron Man Model: Human-in-the-Middle" is
    replaced by `<ReviewLoop />`.
  - `knowledge-base.mdx`: the § 3 fence is replaced by `<KbStructure />`, and the fence under "Context
    Feeding Strategy — RAG by Convention" by `<ContextLoading />`.
  - `agents.mdx`: the § 5 fence is replaced by `<AgentTiers />`.
- Delete `site/src/assets/3-ironman.png` in the same change (Feature 003, D3). `docs/images/3-ironman.png`
  outside `site/` stays untouched.
- Only the fence or image is replaced. The words around it are the audit tasks'. Two corrections are
  recorded in the `concepts/knowledge-base.mdx` audit row by the audit task, not here:
  - D5 fixes the old drawing's "INDEX.md always loaded" and adds the project card;
  - D5 drops the "exact path:line" tier.
- At most 150 lines per diagram file.
- Not in this task:
  - The other six diagrams.
  - `astro.config.mjs`.
  - Audit rows.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`). Inside that set, only the four new files, the
    three host pages and the deleted PNG change.

**Acceptance Criteria:**
- [ ] Sizes: `wc -l site/src/components/diagrams/{ReviewLoop,KbStructure,ContextLoading,AgentTiers}.astro`
  shows each file at most 150 lines.
- [ ] Drawing rules in the source. Run each check below with `F` set to each of the four files.
  - `grep -cE "const id = '(review-loop|kb-structure|context-loading|agent-tiers)'" $F` prints `1`.
  - `grep -cE '\s(style|fill|stroke|color)=' $F` prints `0`.
  - `grep -cE '#[0-9a-fA-F]{3,8}\b|rgba?\(|hsla?\(|<script|tabindex' $F` prints `0`.
  - `grep -oE '<[A-Za-z][A-Za-z0-9]*' $F | sort -u | grep -vxE '<(Diagram|g|rect|circle|ellipse|path|line|polyline|polygon|text|tspan|ol|ul|li|table|thead|tbody|tr|th|td|p|code|a)'`
    prints nothing.
  - `grep -c '<th>' $F` prints `0`.
- [ ] Words as specified. Each command prints at least `1`.
  - `grep -c 'grade below minimum' site/src/components/diagrams/ReviewLoop.astro`
  - `grep -c 'href="/reference/kb/"' site/src/components/diagrams/KbStructure.astro`
  - `grep -c 'only to find a specific document' site/src/components/diagrams/ContextLoading.astro`
  - `grep -c 'href="/reference/agents/"' site/src/components/diagrams/AgentTiers.astro`
  - No agent name appears in the AgentTiers drawing:
    `grep -cE 'aid-(architect|clerk|developer|interviewer|operator|orchestrator|researcher|reviewer|tech-writer)' site/src/components/diagrams/AgentTiers.astro`
    prints `0`.
- [ ] Raster removed (delivery-002 gate): `grep -rn '3-ironman' site/src` prints nothing, and
  `test -e site/src/assets/3-ironman.png` exits 1.
- [ ] Hosts. From `site/src/content/docs/concepts/`, `grep -c '^```mermaid' knowledge-base.mdx agents.mdx`
  prints `0` for each file.
- [ ] AC-1 and placement counts (Feature 003 verification table). From `site/`, `npm run build` exits 0.
  Then
  `for p in methodology knowledge-base agents; do echo "$p $(grep -o '<figure class="diagram' "dist/concepts/$p/index.html" | wc -l)"; done`
  prints exactly the three lines `methodology 1`, `knowledge-base 2` and `agents 1`.
- [ ] Built markup, from `site/`. The scoped style of `Diagram.astro` adds a `data-astro-cid-*` attribute
  to its elements, so tags are matched by name plus an attribute fragment, never with their closing `>`.
  Each command prints `1`:
  - `tr -d '\n' < dist/concepts/knowledge-base/index.html | grep -oE '<title [^>]*id="dg-context-loading-title"[^>]*>How an agent finds what it needs</title>' | wc -l`;
  - `grep -o 'aria-describedby="dg-review-loop-desc"' dist/concepts/methodology/index.html | wc -l`.
- [ ] No link and no `foreignObject` inside a drawing (U6). From `site/`, this loop prints nothing (it
  cuts each page after every `</svg>`, keeps the `<svg role="img"` drawings, and reports any `<a ` or
  `<foreignObject` inside them, or a page with no drawing at all):
  `for p in methodology knowledge-base agents; do f="dist/concepts/$p/index.html"; D=$(tr -d '\n' < "$f" | sed 's#</svg>#</svg>\n#g' | grep -oE '<svg [^>]*role="img".*</svg>'); [ -n "$D" ] || echo "no drawing: $f"; printf '%s\n' "$D" | grep -qE '<a |<foreignObject' && echo "link or foreignObject in drawing: $f"; done`
- [ ] The drawing matches the text equivalent (judged by the reviewer, reading each file's shapes and
  labels against Feature 003 § Data Model for D3 to D6): every box and edge stands for a step, part or
  tier of the text equivalent and nothing else; the "Extensions (optional)" box of D4 is dashed and
  worded optional; no edge path crosses a `<text>` box.
- [ ] Facts untouched: from `site/`, `node scripts/gen-facts.mjs --check` exits 0.
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only the four
    diagram files, the three host pages and `site/src/assets/3-ironman.png` (deleted).
  - `git status --porcelain docs` prints nothing.
  - `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
