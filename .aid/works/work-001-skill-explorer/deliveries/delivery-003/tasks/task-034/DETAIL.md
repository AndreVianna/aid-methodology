# task-034: Doorway composition and the binding reader

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-034. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-034/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-003 (feature-004-doorway-engine-charts)

**Depends on:** task-032

**Scope:**
- Create `site/scripts/lib/flow-graph/compose.mjs` with two exports: `composeDoorwayChart({ skill, prefixNodes, prefixEdges, core, confidence })` and `readDoorwayBinding({ body, bodyStartLine, sourcePath })`.
- **`readDoorwayBinding` is placed here as a Detail-time placement call, recorded because feature-004's SPEC did not assign it a file.** Its module table names four files and its Public API names seven functions, but never says which file owns `readDoorwayBinding`. It is placed in `compose.mjs` on feature-004's own stated reason for that module existing: the memo and the splice "are needed by **both** extractors and putting them in either one would make the other import its sibling." The binding reader is used by both extractors and has exactly that property. (`resolveSiblingParent()` is *not* placed here -- only shape 4 uses it, so it lives in `extract-sibling.mjs`, task-036.)
- **`composeDoorwayChart` is a pure prefix-and-offset splice.** It returns **new** node and edge objects, copying each core member with `id` and `order` shifted by the prefix length and `from`/`to` remapped through the same offset map. The core is read, never touched -- no `structuredClone` of a frozen graph, no in-place `node.id = ...`. Every doorway prefix is exactly one node, so the offset is `1` on every page and the core's `c1...cN` become `n2...nN+1` identically everywhere. That is what makes the engine segment byte-identical **across pages**, not merely across runs.
- `entries` is **recomputed as `[n1]` by construction**, never copied -- the parent's or core's entry nodes gain the hop's in-edge, so their in-degree is no longer 0. `exits` is the core's exits offset; `sources` is the ASCII-sorted union; `warnings` is concatenated.
- `readDoorwayBinding` implements both ladders, reading **only the doorway's own body and never `shortcut-catalog.yml`**. That is not merely consistency with the classifier rule -- the engine's own Invocation Contract names the doorway body as the source of `{verb}` and `{artifact}`. Reading the catalog would report what the doorway *should* bind; reading the body reports what it *does*, and a build/catalog drift -- a case the engine explicitly handles at INTAKE as "a build defect" -- would then be invisible on the page that has it.
- Engine ladder: the `Bind **VERB=...**, **ARTIFACT=...**` clause, including the bare-verb form `**ARTIFACT="" (bare verb)**` carried through as written. Sibling ladder: the braced `{verb, artifact}` group, the `alias_of` form, and the no-binding fallback which emits warning **W1** and the label `Delegates to <parent-or-engine>`.

**Acceptance Criteria:**
- [ ] Composition returns **new** objects: no composed chart shares node or edge **object identity** with the core, asserted by reference comparison and not by deep equality alone.
- [ ] After composing two different doorways, `getEngineCore()`'s output is deep-equal to a fresh derivation -- the core is provably unmutated.
- [ ] Ids and `order` shift by the prefix length and `from`/`to` remap through the same offset map; with a one-node prefix the core's `c1...cN` become `n2...nN+1`.
- [ ] `entries` is recomputed as `[n1]` by construction and is never copied from the core; `exits` is offset, `sources` is the ASCII-sorted union, `warnings` is concatenated.
- [ ] `readDoorwayBinding` never reads `shortcut-catalog.yml`, verified by grep over the module.
- [ ] Every binding form has a passing case: `Bind **VERB=...**, **ARTIFACT=...**`; the bare-verb `**ARTIFACT="" (bare verb)**` carried through verbatim; `{verb, artifact}`; `{verb, artifact: ""}`; `alias_of`; and the no-binding fallback emitting W1 with the `Delegates to ...` label.
- [ ] `resolveSiblingParent` is **not** in this module -- it belongs to task-036.
- [ ] The module reads only the doorway's own body plus what it is handed; it performs no directory scan and no catalog read.
- [ ] Unit tests exist for splice purity and for every binding rung; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
