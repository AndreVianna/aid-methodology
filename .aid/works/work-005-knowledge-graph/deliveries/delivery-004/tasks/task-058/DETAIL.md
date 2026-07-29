# task-058: `graph-css.css` graph, table and control styles

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
- Create `canonical/aid/templates/knowledge-graph/graph-css.css`, inlined **after**
  `canonical/aid/templates/knowledge-summary/component-css.css`, carrying only what that file does
  not already provide: graph-region layout, control-panel layout, legend, the table's sort
  affordance and `[data-emphasis]` row rules, and the zero-row region's rules.
- Implement the responsive layout task-056 fixed: 1200 px max content width, a single 768 px
  breakpoint, the `<details>` collapse and single-column grid below it, and the CSS-driven visual
  order (graph-then-table wide, table-then-graph narrow) over the table-first DOM order.
- Implement the 2.4.11 sticky accounting: an explicit top offset on the reused sticky `.tbl th`
  equal to the top-bar height instead of the viewport edge, and `scroll-margin-top` on focusable
  targets inside `<tbody>` covering **both** sticky layers.
- **Out of scope:** any new colour token (the five semantic roles map onto existing tokens); any
  rule that duplicates or forks `component-css.css` (`.tbl-wrap`, `table.tbl`, `.badge-*`,
  `.skip-link`, `:focus-visible`, the reduced-motion, forced-colors and print blocks); markup
  (tasks 057, 063, 064); the drawing surface's own styling (feature-008, delivery-005).

**Acceptance Criteria:**
- [ ] Every colour, spacing, radius and font value is a `var(--token)` from
      `knowledge-summary/design-tokens.md`: `grep -E '#[0-9a-fA-F]{3,8}|rgb\(|rgba\(|hsl\('` over
      the file returns nothing, and the file declares no `--*` custom property of its own.
- [ ] The five semantic roles resolve to `--accent` (focus/selection), `--ok` (well-formed),
      `--warn` (`kb-unbacked`), `--err` (`int-undocumented`), `--purple` (`inferred` provenance)
      and `--text-dim` (dimmed) -- all already covered by pairs `contrast-check.mjs` checks, so no
      pair is added to that script.
- [ ] Exactly one breakpoint appears in the file, at 768 px, and the max content width is 1200 px:
      `grep -c '@media' `-matched width queries introduce no second breakpoint scale.
- [ ] Neither the graph nor the table region overflows its own container horizontally at 732 px or
      at 390 px (T4's container-relative predicate); horizontal scrolling for the wide table is
      confined to the reused `.tbl-wrap`.
- [ ] The sticky `.tbl th` top offset equals the top-bar height (~60 px per `design-tokens.md`
      § "Spacing & sizing") rather than `0`, and focusable elements inside `<tbody>` carry a
      `scroll-margin-top` at least the sum of the top bar and the sticky header.
- [ ] No rule in the file restates one already present in `component-css.css`; a reviewer diffing
      the two finds no duplicated selector body (C-4, AC-17).
- [ ] Meaning is never carried by colour alone: every emphasis rule pairs its colour with a
      non-colour carrier (badge text, shape, or removal-and-count), and the file adds no
      colour-only distinction (NFR-5).
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the named
      suite is `tests/canonical/test-graph-view-shell.sh` (tasks 070/071), with contrast and
      structural verification in task-073. *(Stated override of the IMPLEMENT default "unit tests
      for all new public methods": a stylesheet has no unit-test vehicle here.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes;
      the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
