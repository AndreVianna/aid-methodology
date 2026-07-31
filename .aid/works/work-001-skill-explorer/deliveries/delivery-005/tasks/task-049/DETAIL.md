# task-049: Client controller attachment lifecycle and node decoration

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-049. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-049/STATE.md.
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
- Create `site/public/skill-node-panel.mjs` and implement **the attachment half only**: the per-container machine (`UNBOUND` / `BOUND_PENDING` / `BOUND_READY` / `BOUND_INERT`), delegated `click` and `keydown` on the `pre.mermaid` container, the `MutationObserver`, `WeakSet` identity tracking, `data-aid-node` idempotent decoration, id recovery with resolve-or-skip, the `astro:after-swap` re-scan, and the island read with its `v === 1` schema guard. **Task-050 writes the panel half into this same file; the two tasks are strictly sequential and must never run concurrently.**
- **This task lands an intentionally incomplete intermediate state, and that is by design, not a defect.** At the end of task-049 a node is decorated with `role`, `tabindex`, `aria-label`, `aria-expanded` and `aria-controls`, and an activation resolves the node id and invokes a **panel entry point that task-050 implements** -- so `aria-controls` names a panel element that does not exist yet and activation produces no visible panel. A reviewer seeing that at this task's gate should read it as the planned seam, not a bug. The file is not shippable until task-050 is Done, which is why delivery-005 has no gate between them.
- **Readiness is the three-part predicate, and this task owns it (KI-011):** `data-processed` **and** a non-null `container.querySelector('svg')` **and** at least one resolvable node id. `data-processed` means "mermaid attempted this diagram", not "an SVG exists" -- the integration's catch block sets it after a *failed* render too, having replaced the container's contents with a plain error `<div>`. A consumer treating it as the latter would run its node query against a container with no `<svg>` at all.
- **Install listeners and the observer BEFORE sampling the current state.** Rendering is asynchronous and the script order is not defined; installing first closes the race where a render completes between script parse and check. Nothing polls and nothing times out.
- **The `WeakSet` is the duplicate-handler guard.** Containers are tracked by element identity, not by a DOM attribute: a container that survives a theme change is recognised as already bound, while a container in a document replaced by `astro:after-swap` is a different object and binds cleanly. A theme change strips `data-processed` and rewrites the container's `innerHTML`, destroying every listener bound to a node inside it -- which is why delegation is on the container, which survives.
- Decoration is **idempotent** via a `data-aid-node` marker, so a spurious or duplicated readiness transition cannot double-decorate. This absorbs KI-014, where two rapid theme toggles can interleave two render loops and fire the transition twice.
- **Id recovery and resolve-or-skip.** Selection uses `g.node.aidNode` (hook H3), not the `flowchart-<id>-<n>` id template, because the `-<n>` suffix is a parser-call counter that nothing in the model predicts, because one class query beats N prefix queries, because H3 is a hook feature-003 owns and guarantees for both chart families, and because it excludes foreign diagrams. The id is then recovered with `/^flowchart-([A-Za-z][A-Za-z0-9_]{0,31})-\d+$/`; the capture group is feature-003's id charset, which contains no `-`, so `flowchart-n7-1` can never be confused with `flowchart-n71-5`. A node whose id does not match or does not resolve in the projection is **left undecorated** -- no `tabindex`, no `role`, not activatable, never a broken panel. If **zero** nodes resolve for a container it goes `BOUND_INERT` with one warning.
- **One chart per page is an assumption with a guard:** bind the first `pre.mermaid` inside `.sl-markdown-content`; if more are found, bind the first, leave the rest alone, and emit the `panel container` warning rather than guessing which chart the single projection describes.
- `astro:after-swap` is registered and **currently inert** -- the site enables no view transitions -- and must be documented as such rather than claimed as working, because an untriggerable path is untested by definition.
- Vanilla ESM, IIFE-scoped, in the same plain-DOM style as the site's two existing client scripts. **No `import`, no `fetch`, no `localStorage`/`sessionStorage`, no cookie, no `eval`, no `new Function`, no `innerHTML`.** `init()` is wrapped so an unexpected error degrades to the no-JavaScript state rather than leaving half-decorated nodes. Console is **silent on success**; failures use `console.warn('[aid-node-panel] <guard>: <detail>')` **at most once per guard per page**, with the stable guard names `panel schema`, `panel data`, `panel container` and `panel nodes`.

**Acceptance Criteria:**
- [ ] Readiness requires all three of `data-processed`, a non-null `<svg>` child, and at least one resolvable node id; the failed-render shape (attribute set, error `<div>`, no `<svg>`) reaches `BOUND_INERT` with exactly one warning and no decoration.
- [ ] Listeners and the `MutationObserver` are installed **before** the current state is sampled, so a render completing in that gap is caught by the mutation rather than missed.
- [ ] Handlers are bound **exactly once per container**, tracked by element identity in a `WeakSet`, and survive a theme re-render without duplicating -- three simulated cycles produce one binding.
- [ ] Decoration is idempotent: a node already carrying `data-aid-node` is skipped, so a repeated readiness transition re-decorates the current subtree and cannot double-decorate.
- [ ] Delegation is on the `pre.mermaid` container, never per node, and both `click` and `keydown` resolve their target with `closest('g.node.aidNode')` so a click on a node's `<text>` or `<tspan>` descendant works.
- [ ] Selection uses `g.node.aidNode`; the id is recovered by the anchored pattern, and a node whose id fails to match or fails to resolve in the projection is left **entirely undecorated** and cannot be activated.
- [ ] Zero resolvable nodes for a container yields `BOUND_INERT` with one warning; more than one `pre.mermaid` binds the first and emits the `panel container` warning.
- [ ] The island is read inside `try`/`catch`; a parse failure warns once and no-ops, and `v !== 1` no-ops entirely with one warning.
- [ ] The shipped file contains no `import `, no `fetch(`, no `localStorage`, no `sessionStorage`, no cookie access, no `eval`, no `new Function` and no `innerHTML` -- verified by grep over the source.
- [ ] `init()` cannot throw out: an injected unexpected error degrades to the no-JavaScript state.
- [ ] The console is silent on a successful run; each of the four stable guard names warns at most once per page.
- [ ] `astro:after-swap` is registered, and the source documents that it is currently inert because the site enables no view transitions.
- [ ] **The intermediate state is documented in the source** at the panel entry point: a comment stating that task-050 implements it and that `aria-controls` resolves once it lands.
- [ ] All existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
