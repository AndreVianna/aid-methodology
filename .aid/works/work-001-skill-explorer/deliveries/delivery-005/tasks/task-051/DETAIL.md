# task-051: Panel and focus stylesheet

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-051. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-051/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** work-001-skill-explorer -> delivery-005 (feature-006-interactive-node-panel)

**Depends on:** task-046

**Scope:**
- Create `site/public/skill-node-panel.css` -- the panel block and its elements (`aid-node-panel` plus `__bar`, `__order`, `__kind`, `__exit`, `__close`, `__label`, `__fragment`, `__links`), the focus styling, and the small-screen rules. The class names are fixed by feature-006's Anatomy block, which is what lets this task run in parallel with the controller rather than behind it.
- **Focus visibility:** `:focus-visible` styling on the node group and, as a belt-and-braces measure for engines with patchy `outline` support on SVG, also on its child shape via a stroke change. Both are colour-and-width changes; there is **no animation**, so `prefers-reduced-motion` needs no special case.
- **Contrast and theming:** focus and open-state indication use stroke width plus colours drawn from the casulo tokens already defined in `src/styles/casulo.css` and Starlight's own `--sl-color-*` variables, so they track both themes without a second palette. KI-001 does not reach here -- this is CSS, not mermaid `themeVariables`.
- **Small screens:** the panel is in normal flow, so it stacks under the chart at any width and needs no positioning, no overlay and no scroll lock. Below the site's existing narrow breakpoint it goes full-bleed within the content column. The fragment block is capped with `max-height` plus `overflow:auto` so a long dispatch row cannot push feature-005's list off the screen, and it wraps (`white-space: pre-wrap; overflow-wrap: anywhere`) rather than scrolling horizontally -- the same readability choice feature-005 makes with its `wrap` meta option. **Rejected: a fixed bottom sheet**, which would need a scroll lock and a dismissal overlay, i.e. the modal complexity the disclosure pattern exists to avoid.
- **This is a linked `public/*.css` file, not a runtime-injected `<style>`.** That is deliberate and is what keeps the feature CSP-friendly: if a Content Security Policy is ever added, this feature needs only `script-src 'self'` and `style-src 'self'`, because both assets are same-origin files and **no style is injected from JavaScript**.
- 2-space indentation matching the site's existing stylesheets; no preprocessor, no new dependency.

**Acceptance Criteria:**
- [ ] Every class name in the stylesheet matches feature-006's Anatomy block exactly, and every element the controller creates has a corresponding rule -- verified by cross-checking the two lists.
- [ ] `:focus-visible` styling is applied to the node group **and** to its child shape via a stroke change, so focus remains visible on engines with patchy SVG `outline` support.
- [ ] Focus and open-state indication use only colour and stroke-width changes; the file contains **no `animation` and no `transition` on those states**, so `prefers-reduced-motion` needs no branch.
- [ ] All colours resolve from existing `casulo.css` tokens or Starlight `--sl-color-*` variables; **no new palette or hard-coded hex colour is introduced**, verified by grep.
- [ ] Both light and dark themes render the panel and the focus ring legibly, with no second palette defined.
- [ ] The panel is in normal flow: the file contains no `position: fixed`, no overlay element rule and no scroll-lock rule.
- [ ] The fragment block is capped with `max-height` plus `overflow:auto` and wraps with `white-space: pre-wrap; overflow-wrap: anywhere` -- it never scrolls horizontally and cannot push feature-005's list off screen.
- [ ] Below the site's existing narrow breakpoint the panel goes full-bleed within the content column and remains usable.
- [ ] The stylesheet is a static `site/public/*.css` file linked from `<head>`; **no style is injected from JavaScript anywhere in this feature.**
- [ ] All existing tests still pass; the build passes and the file is copied verbatim into `dist/`.
- [ ] All section-6 quality gates pass
