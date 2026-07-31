# task-046: Build-time panel logic -- gate, projection and island encoding

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-046. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-046/STATE.md.
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

**Depends on:** task-044

**Scope:**
- Create `site/src/lib/skill-node-panel.ts` -- the pure build-time half: `shouldMount(generatedFrom, known)`, `buildProjection(chart)` and `embedJson(projection)`. TypeScript, so `astro check` covers it and vitest can import it without a DOM.
- **`shouldMount` is a data test, not a path test.** It matches `entry.data.generatedFrom` against `^canonical/skills/([a-z0-9]+(?:-[a-z0-9]+)*)/SKILL\.md$` and then requires a sidecar to exist for the captured name. That is strictly better than `pathname.startsWith('/skills/')`, it is independent of `base`, and it **fails closed** if the sidecars have not been generated yet. The exclusions are measured rather than assumed: four pages carry `generatedFrom` today, three citing a path outside `canonical/skills/` and the fourth being the two-source comma-joined string feature-002's index page also carries -- which the pattern rejects on the `*` and on the trailing second source, so `/skills/index.md` is excluded by the same anchor rather than by a special case.
- **`buildProjection` is a projection of the sidecar, never a second model.** It emits exactly `PanelNode`'s field set -- `id`, `order`, `name`, `label`, `kind`, `exit`, `fragment`, `source`, `detail` -- inside `{ v: 1, skill, confidence, nodes }`. `source.url` is **not re-derived**: it is `blobUrl(file, startLine, endLine)` imported read-only from feature-005's `deep-link.mjs` (task-040), so the panel's link and the list's `[Source: ...]` link have one authority and cannot disagree about the anchor form.
- **`v` is a schema version and it is load-bearing.** The controller ships from `site/public/`, which Astro copies verbatim and does not content-hash, so a browser can hold a stale copy after a deploy. The controller refuses to run unless `v === 1`, which makes the stale-asset failure mode provably benign -- the page falls back to its no-JavaScript behaviour rather than mis-rendering.
- **Deliberately excluded from the projection**, to hold page weight down: `edges[]` and therefore every `FlowEdge.provenance.excerpt`, plus `sources`, `warnings`, `entries`, `exits`, `title`, `shape` and `extractor`. The panel is node-indexed; a self-edge adds nothing to it, exactly as it adds no entry to feature-005's list.
- **`embedJson` runs `JSON.stringify`, then replaces every `<` with `\u003c`.** In `stringify` output a `<` can only occur inside a JSON string, and `\u003c` is a valid escape there, so the transform is lossless and `JSON.parse` round-trips deep-equal. It closes `</script>` and `<!--` with one rule rather than two.
- Conventions: 2-space indentation matching everything under `site/src/`, ESM, kebab-case filename, pure exported functions with **no import-time side effect**.

**Acceptance Criteria:**
- [ ] `shouldMount` returns the captured directory name for a real skill `generatedFrom`, and `null` for each of: a `reference/*.md` page's `generatedFrom`, `undefined`, a skill name absent from the sidecar set, and a name failing the charset.
- [ ] `shouldMount` returns `null` for feature-002's index `generatedFrom` string, rejected on the `*` and the trailing second source -- **not** by a special case naming `index`.
- [ ] `shouldMount` is a pure regex match plus a `Set.has` with **no I/O**, and it fails closed (returns `null`) when the sidecar set is empty.
- [ ] `buildProjection` emits exactly `PanelNode`'s field set: assert that **no `edges`, `warnings`, `sources`, `entries`, `exits`, `title`, `shape` or `extractor` key survives anywhere in the serialized JSON**, at any depth.
- [ ] `nodes` keeps `chart.nodes` array order without re-sorting.
- [ ] `fragment === provenance.excerpt` byte-for-byte, and `source.url === blobUrl(...)` for both the single-line and multi-line anchor forms.
- [ ] `blobUrl` is **imported** from `site/scripts/lib/provenance/deep-link.mjs`; no URL construction is reimplemented here, verified by grep for `#L`.
- [ ] `detail` is `null` or link-only, carrying no excerpt.
- [ ] `v: 1` is emitted on every projection.
- [ ] `embedJson` output contains **no literal `<`**, and `JSON.parse` of it round-trips to a deep-equal object -- asserted with fixtures containing `</script>`, `<!--`, `<div>`, a 4-backtick run, a pipe and `{braces}`.
- [ ] All three functions are pure with no import-time side effect; `astro check` passes over the module.
- [ ] Unit tests exist for every exported function; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
