# task-050: The node panel -- disclosure, focus and key handling

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-050. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-050/STATE.md.
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

**Depends on:** task-049

**Scope:**
- Complete `site/public/skill-node-panel.mjs` by implementing the **panel disclosure machine** behind the entry point task-049 left: panel creation, fill from the projection, `CLOSED` / `OPEN(nodeId)` transitions, ARIA state, focus movement and key handling. This task and task-049 own the same file and are strictly sequential; **this task is what makes the file shippable.**
- The controller creates **one panel per bound container** and inserts it as the container's **next sibling** inside `.sl-markdown-content`, so it appears directly beneath the chart and above feature-005's `## Source fragments` section -- "in place, without leaving the chart". It is **not server-rendered**: an empty hidden shell would serve nobody without JavaScript and would be one more thing to keep correct, and creating it on first successful decoration means the no-JavaScript page and the mermaid-failed page are byte-identical below the chart.
- **Pattern: disclosure, not dialog.** Each node is the disclosure control (`role="button"`, `tabindex="0"`, `aria-expanded`, `aria-controls`); the panel is the disclosed region; one panel is shared and only the open node carries `aria-expanded="true"`. **Rejected: `<dialog>` / `role="dialog"` with `aria-modal`** -- a modal would hide the chart and the list behind it, contradicting "without losing my place", and would oblige a focus trap.
- **No focus trap, deliberately.** The panel is non-modal and in the document flow; Tab out of it continues into the page, which is what a reader comparing the panel against the list below actually wants. Trapping focus on a docs page is hostile and there is nothing to trap it *for* -- no state is lost by leaving.
- **Focus is still managed.** Opening moves focus to the panel container (`tabindex="-1"`) so the content is announced and the close button is one Tab away; the browser scrolls it minimally into view, which is also the correct small-screen behaviour, so no `preventScroll` is used. **`Escape` and the close button return focus to the invoking node**, guarded by a re-resolution in case a theme re-render replaced it.
- Transitions: `CLOSED -> OPEN(a)` on click / `Enter` / `Space`; `OPEN(a) -> OPEN(b)` on activating a different node, refilling content and returning focus to the panel; `OPEN(a) -> CLOSED` on re-activating `a` (toggle), the close button, or `Escape` while focus is inside the panel or on a node; and `OPEN(a) -> CLOSED` when the open node disappears and cannot be re-resolved after a re-render. **Clicking elsewhere on the page is NOT a dismissal trigger** -- rejected explicitly rather than omitted, because a reader scrolling to the list to compare, or selecting text, must not lose the panel.
- Across a re-render while open, the open node id is re-resolved in the new subtree and `aria-expanded="true"` re-applied there; the panel stays open with valid content. Note that during the doomed-subtree window an activation still works, **because the panel's content comes from the projection and never from the SVG.**
- **Keys:** `Enter` and `Space` activate; `Space` calls `preventDefault()` so the page does not scroll; `Escape` closes. No other key is bound and no key is intercepted globally.
- **Accessible names are composed, not scraped:** `aria-label` is `"Step <order>: <name> — <label>"` plus `" (exit: <advanceType>)"` when `exit` is non-null. Mermaid renders the two-line node text as `<tspan>`s or a `foreignObject`, so a computed name from content would be unreliable and unpunctuated.
- Panel content is written with **`textContent` and `createElement` only -- no `innerHTML`, anywhere, ever.** The fragment is arbitrary repository text and will contain `<`, `&` and complete code fences. The fragment is rendered with **no syntax highlighting**: a grammar reinterpreting the one text whose literalness is the point is the same trap feature-005 rejected. Link hrefs come only from `source.url` / `detail.url` in the projection and the `#fragment-<id>` anchor -- no user input and no `javascript:` reachable.
- The heading level inside the panel is `h3`, semantically under the chart's `## Flow` H2. Starlight builds its table of contents from the markdown at build time, so a DOM-inserted heading cannot pollute it.
- **Feature-005's list is read by nothing here.** The panel's data path is the projection; the `#fragment-<id>` link is a plain in-page anchor and the panel does not read anything at that target. No collapsing or de-duplication of the list is applied.

**Acceptance Criteria:**
- [ ] Activating any decorated node opens a panel showing that node's `order`, `name`, `kind`, `exit` (only when non-null), derived `label`, byte-exact `fragment`, and a `[Source]` link whose href equals `source.url`; the `full step` link appears if and only if `detail !== null`; the `#fragment-<id>` link is present.
- [ ] The panel is created on first successful decoration and inserted as the container's **next sibling**; it is not server-rendered, so a no-JavaScript page and a mermaid-failed page are byte-identical below the chart.
- [ ] Only the open node carries `aria-expanded="true"`; every other decorated node carries `false`.
- [ ] `Enter` and `Space` open; `Space` calls `preventDefault`; re-activating the open node toggles it closed; the close button closes.
- [ ] **`Escape` closes and returns focus to the invoking node**, re-resolving that node first in case a re-render replaced it.
- [ ] Opening moves focus to the panel container, which carries `tabindex="-1"`; `preventScroll` is not used.
- [ ] **There is no focus trap**: Tab from the last focusable element in the panel continues into the page rather than cycling.
- [ ] Clicking elsewhere on the page does **not** dismiss the panel.
- [ ] With the panel open across a simulated re-render, the open node is re-resolved, `aria-expanded="true"` is re-applied and the content stays valid; if the id no longer exists the panel closes and focus is not moved.
- [ ] `aria-label` is composed from the projection as `"Step <order>: <name> — <label>"`, with the exit clause appended when `exit` is non-null -- never scraped from SVG text.
- [ ] All panel content is written with `textContent` / `createElement`; **`innerHTML` appears nowhere in the finished file**, verified by grep, and the fragment is rendered without syntax highlighting.
- [ ] Link hrefs come only from `source.url`, `detail.url` and `#fragment-<id>`; no other href source exists in the module.
- [ ] The panel heading is an `h3`.
- [ ] The module reads nothing from feature-005's rendered list, and applies no collapsing or hiding to it.
- [ ] The finished file still contains no `import `, no `fetch(`, no storage access, no `eval` and no `new Function`; the console remains silent on success.
- [ ] All existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
