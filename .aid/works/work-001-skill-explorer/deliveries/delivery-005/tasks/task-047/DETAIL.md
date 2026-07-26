# task-047: Route-gated `Head` component override

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-047. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-047/STATE.md.
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
- Create `site/src/components/overrides/Head.astro`, beside the two existing overrides. It renders Starlight's own packaged `Head` as `<Default />`, then -- only when `shouldMount()` passes -- emits three tags into `<head>`: the stylesheet link, the `<script type="application/json" id="aid-flow-data">` island, and the module script pointing at the `public/` controller.
- **Compose with the packaged default rather than reimplementing it.** Starlight's `exports` map publishes `./components/*`, and its `Head.astro` is a five-line pass-through over `Astro.locals.starlightRoute.head`; composing preserves Starlight's head output exactly, while reimplementing those five lines would be a copy that silently rots. Note that `Header.astro` is **not** a precedent for this pattern -- it is a complete reimplementation that never renders a default; its convention is the weaker one of importing individual built-ins it is not overriding.
- Sidecars are loaded with `import.meta.glob('../../data/skill-flows/*.flow.json', { import: 'default' })` **in the component frontmatter**, which Astro strips from the client, so no flow JSON and no glob machinery reaches a browser on any page. If the directory does not exist yet the glob is an empty object, every gate returns `null`, and the override is **inert rather than broken**.
- The island is emitted with `set:html`, **never an interpolated child**: the HTML parser does not decode character references inside a raw-text element, so an escaped `{json}` expression would be read back with literal `&amp;` and fail to parse.
- The controller tag is **`is:inline`**, and that is what makes the route gate observable. Astro's processed `<script>` tags are collected per page from the build's module graph, so a processed script inside a conditional in a component that renders on *every* page is not reliably excluded from pages where the condition is false. `is:inline` opts the tag out of processing entirely, so the runtime conditional genuinely controls whether it appears -- verifiable by grepping the build output, which is what task-048's gate check does.
- **This override renders on every page of the site**, so section 7's "the existing build and its four generated reference pages must keep working unchanged" is at stake in this one file. Three properties make that safe and each is a constraint on the implementation, not an observation: the failing path does **no work** (a regex plus a `Set.has`, no I/O, no sidecar await, emitting `<Default />` and nothing else); the sidecar load is build-time and server-only; and **nothing on the mounting path can throw** -- there is no `readFileSync`, no network and no `process.env`, and the only operations are a `JSON` serialization of an object the sidecar already round-tripped and a `blobUrl` call whose input feature-005's verifier already accepted at generation time.
- Rejected and not to be reintroduced: a `head:` entry in `astro.config.mjs` (a static array with no route predicate -- it would ship the script to the whole site); a `head:` key written into every generated page's frontmatter (it would change feature-001's fixed page shape for no gain); overriding `MarkdownContent` (it would put a `<link rel="stylesheet">` in the content column, where it is non-conforming); and fetching the sidecar at runtime from `public/` (feature-003's seam S2 already rejected that location for costing a network round-trip per page).

**Acceptance Criteria:**
- [ ] The override renders Starlight's packaged `Head` as `<Default />` on every page, and the head output of a non-skill page is **byte-identical** to the pre-change build.
- [ ] The failing path emits `<Default />` and nothing else, performs no I/O and never awaits the sidecar.
- [ ] `import.meta.glob` is evaluated in frontmatter only: **no flow JSON and no glob machinery appears in any client bundle or any emitted HTML**, verified against the build output.
- [ ] With `site/src/data/skill-flows/` absent, every gate returns `null` and the override is inert -- the build still succeeds and no page gains a tag.
- [ ] The island uses `set:html`, never an interpolated child, and its content parses with `JSON.parse` from the emitted HTML.
- [ ] The controller tag carries `is:inline`, so the tag's presence tracks the runtime conditional exactly.
- [ ] Exactly three tags are emitted on a mounting page: the stylesheet link, the JSON island and the module script -- **and no generated page byte changes except those three tags**.
- [ ] Nothing on the mounting path can throw: the module contains no `readFileSync`, no network call and no `process.env`, verified by grep.
- [ ] The four generated `reference/*.md` pages and every hand-authored page build unchanged.
- [ ] `astro check` passes and the build succeeds.
- [ ] Unit tests cover the pure half through task-046's exports; all existing tests still pass.
- [ ] All section-6 quality gates pass
