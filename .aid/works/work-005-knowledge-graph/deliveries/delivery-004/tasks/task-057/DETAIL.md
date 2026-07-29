# task-057: `graph-skeleton.html` shell, landmarks and prerequisites footer

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-056

**Scope:**
- Create `canonical/aid/templates/knowledge-graph/graph-skeleton.html`, the placeholder shell for
  `graph.html`, seeded from `canonical/aid/templates/knowledge-summary/html-skeleton.html` and
  laid out exactly as task-056's wireframe fixes it.
- Author the landmark spine: `<html lang>`, the `skip-link` as first focusable element,
  `<header role="banner">` (title, breadcrumb, theme toggle on the shared `aid-dashboard-theme`
  key), `<nav aria-label="Preset lenses">`, `<main>`, the graph and table `<section>`s as
  siblings in table-first DOM order, and `<footer>`.
- Author both live regions as empty containers present from load: the `.callout.err`
  `role="alert"` integrity banner as **first child of `<main>`**, and the single
  `aria-live="polite"` status line. No third live region.
- Author the `<noscript>` region linking `./relationships.md` and `./INDEX.md`, and the footer
  carrying the generation stamp, the relative link to `./relationships.md`, and the **AC-6
  runtime-prerequisites block** (network access, companion asset files, build output).
- Retain the `{{INLINE_LIGHTBOX_JS}}` tail contract the summary shell already carries, so
  `lightbox.js` is inlined verbatim and A2/A3 pass against unforked code.
- **Out of scope:** all styling (task-058); how the shell is split into
  `skeleton-head.html` / `skeleton-foot.html` / `post-script.html` under
  `.aid/.temp/graph/graph-src/` and assembled, and the embedded payload (task-065); control
  behaviour and any write into either live region (tasks 062, 061); table and zero-row markup
  (tasks 063, 064); any second focus trap -- the reused lightbox is the page's only one.

**Acceptance Criteria:**
- [ ] `validate-html-output.sh`'s A1 sub-checks pass against the assembled page: `lang` on
      `<html>`, `<header role="banner">`, `<main>`, `<nav>`, `<footer>`, and a `<title>`.
- [ ] The structural checks pass: a `class="skip-link"` first focusable element whose `href`
      target `id` exists (L1), a `<noscript>` region, and a `color-scheme` declaration.
- [ ] The graph and table `<section>`s are siblings inside `<main>`, neither nested in the other,
      in table-first DOM order (visual order is task-058's).
- [ ] The `role="alert"` container exists in the shipped markup, is a `.callout.err`, is the first
      child of `<main>`, is **empty at load**, and is not dismissible -- there is no close control
      in the markup.
- [ ] Exactly one `aria-live="polite"` region exists in the file, and `grep -c 'aria-live'` plus
      `grep -c 'role="alert"'` over the assembled page total two live regions and no more.
- [ ] The `<noscript>` region links `./relationships.md` and `./INDEX.md` as relative hrefs that
      resolve against the HTML file's own directory (L2).
- [ ] The footer states the artifact's runtime prerequisites explicitly as prose, in the shape
      delivery-001's rendering decision record wrote (AC-6); task-074 checks the two against each
      other.
- [ ] The file adds no colour, no inline `style` attribute and no `<script>` of its own; it
      reuses `component-css.css` and `lightbox.js` rather than forking either (C-4, AC-17).
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the named
      suite for this shell is `tests/canonical/test-graph-view-shell.sh` (tasks 070/071), with the
      structural and WCAG verification in task-073. *(This replaces the IMPLEMENT default "unit
      tests for all new public methods": an HTML template has no unit-test vehicle here, and the
      one-type-per-task rule puts the suites in their own TEST tasks.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes
      over the new template set; the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
