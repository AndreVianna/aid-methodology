# task-007: Shared diagram component Diagram.astro

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

**Depends on:** task-004

**Scope:**
- Create `site/src/components/Diagram.astro` exactly as Feature 003 § Layers & Components specifies.
  - **Frontmatter:** the doc comment; the `Props` interface (`id`, `title`, `desc`, `caption`, `width`,
    `height`); the four checks that throw, with their exact messages:
    - `Diagram: bad id "<id>"`
    - `Diagram <id>: bad size` (width over 480 or not positive, or height not positive)
    - `Diagram <id>: empty text`
    - `Diagram <id>: no text equivalent` (no `text` slot)
    It also derives `titleId` and `descId`.
  - **Markup:**
    - `<figure class="diagram" id="dg-<id>">` holding, in this order: `<figcaption>`, then the `<svg>`,
      then `<div class="diagram-text">`.
    - The `<svg>` has `role="img"`, `aria-labelledby`, `aria-describedby`, `viewBox`, `width`, `height`
      and `data-pagefind-ignore`. Inside it: `<title>`, `<desc>`, then `<defs>` with the
      `dg-<id>-arrow` marker and its `dg-arrowhead` path, then the default slot.
    - The `div.diagram-text` holds the lead `<p class="diagram-text-lead">The same information as
      text:</p>` and the `text` slot.
  - **`<style>`:** the "Style" block verbatim. That is the `--dg-*` custom properties mapped to
    Starlight's `--sl-*` variables, the `:global()` rules for slotted shapes, and the `forced-colors`
    block. No colour literal, no `<script>`, no animation or transition.
- At most 110 lines (Feature 003 § Layers & Components).
- The component's check is done by command, not by a test file (Feature 005 fixes the test set; U1-U7
  become tests in delivery-004). A temporary probe page `site/src/content/docs/dg-probe.mdx` imports the
  component, the build is read, and the probe is deleted before the commit. No probe file is committed.
- The only file created is `site/src/components/Diagram.astro`. No diagram file (tasks 008-010), no host
  page, no `astro.config.mjs` edit.
- Binding limits:
  - No deploy, no publish, no push, no tag, no `npm publish`.
  - No network use other than `npm ci` / `npm install` run from `site/`.
  - No edit under `canonical/`.
  - No change to any path outside the AC-13 allowed set (`site/`, `.github/workflows/docs.yml`, the FR-10
    KB documents, `.aid/works/work-005-site-rework/`).

**Acceptance Criteria:**
- [ ] Size: `wc -l < site/src/components/Diagram.astro` prints a number at most 110.
- [ ] Contract text, `site/src/components/Diagram.astro`:
  - `grep -c 'width <= 480' ` prints `1`;
  - `grep -c "Astro.slots.has('text')"` prints `1`;
  - `grep -c 'data-pagefind-ignore'` prints `1`;
  - `grep -c 'forced-colors: active'` prints `1`;
  - `grep -cE '#[0-9a-fA-F]{3,8}\b|rgba?\(|hsla?\(|<script|transition|animation'` prints `0`.
- [ ] Good props render the contract. Write the probe `dg-probe.mdx` with a title, a description and
  `<Diagram id="probe-ok" title="T" desc="D" caption="C" width={400} height={100}>`, holding one
  `<rect class="dg-node" .../>` and `<ol slot="text"><li>a</li><li>b</li></ol>`. From `site/`,
  `npm run build` exits 0. The scoped `<style>` makes Astro add a `data-astro-cid-*` attribute to every
  element of the component, so each check below matches an opening tag by name plus an attribute
  fragment, never a whole tag with its closing `>`. With `H=$(tr -d '\n' < dist/dg-probe/index.html)`,
  each command prints `1`:
  - the figure: `printf '%s' "$H" | grep -oE '<figure [^>]*>' | grep 'id="dg-probe-ok"' | grep -c 'class="diagram'`;
  - its first child is a `<figcaption>` holding `C`:
    `printf '%s' "$H" | grep -oE '<figure [^>]*id="dg-probe-ok"[^>]*>\s*<figcaption[^>]*>\s*C\s*</figcaption>' | wc -l`;
  - the `<svg`: with `S=$(printf '%s' "$H" | grep -oE '<svg [^>]*aria-labelledby="dg-probe-ok-title"[^>]*>')`,
    `printf '%s\n' "$S" | wc -l` prints `1`, and for each `a` in `role="img"`,
    `aria-describedby="dg-probe-ok-desc"`, `viewBox="0 0 400 100"` and `data-pagefind-ignore`,
    `printf '%s\n' "$S" | grep -cF -- "$a"` prints `1`;
  - `printf '%s' "$H" | grep -oE '<title [^>]*id="dg-probe-ok-title"[^>]*>T</title>' | wc -l`;
  - `printf '%s' "$H" | grep -oE '<desc [^>]*id="dg-probe-ok-desc"[^>]*>D</desc>' | wc -l`;
  - `printf '%s' "$H" | grep -o 'id="dg-probe-ok-arrow"' | wc -l`;
  - the text block, lead line, then the list:
    `printf '%s' "$H" | grep -oE 'class="diagram-text[ "][^>]*>\s*<p [^>]*>The same information as text:</p>\s*<ol' | wc -l`.
- [ ] Bad props fail the build with the spec's message. Four probe variants, one at a time. For each,
  from `site/`, `npm run build` exits non-zero and its output contains the stated text:
  - `id="Bad_Id"` gives `Diagram: bad id "Bad_Id"`;
  - `width={481}` gives `Diagram probe-ok: bad size`;
  - `title=" "` gives `Diagram probe-ok: empty text`;
  - no `slot="text"` child gives `Diagram probe-ok: no text equivalent`.
- [ ] Probe removed. After the checks, `test -e site/src/content/docs/dg-probe.mdx` exits 1. From
  `site/`, `npm run build` exits 0 again and `test -e dist/dg-probe` exits 1.
- [ ] All existing checks still pass, and the build passes (AC-1). From `site/`:
  - `npm run build` exits 0 and `test -f dist/index.html` exits 0;
  - `node scripts/gen-facts.mjs --check` exits 0;
  - `npx vitest run tests/facts.test.mjs` exits 0.
  The legacy Vitest suite is not a criterion (PLAN.md Cross-Cutting Risks, row 1).
- [ ] Scope (AC-13, NFR-5), from the repo root:
  - `git diff --name-only site-aid...HEAD | grep -vE '^(site/|\.github/workflows/docs\.yml$|\.aid/works/work-005-site-rework/)'`
    prints nothing.
  - Before this task's commit, `git status --porcelain --untracked-files=all site` lists only
    `site/src/components/Diagram.astro`.
  - `git tag --points-at HEAD` prints nothing.
- [ ] All section-6 quality gates pass. Here these are the project gates of `.aid/knowledge/quality-gates.md`
  § The Delivery Gate (aid-execute), as they apply to one task. From the repo root,
  `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` and
  `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge` exit 0.
