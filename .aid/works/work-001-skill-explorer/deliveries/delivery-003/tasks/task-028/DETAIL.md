# task-028: Mermaid chart renderer

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-028. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-028/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-003 (feature-003-authored-flow-charts)

**Depends on:** task-020

**Scope:**
- Create `site/scripts/lib/flow-graph/render-mermaid.mjs`: `renderMermaid(chart) -> string`, producing the **fence body only**. The enclosing H2, the fence markers and the `approximate` notice belong to the body provider (task-029), because feature-001's body slot specifies that providers own their own headings.
- Dialect `flowchart TB`, matching the site's established usage. Node shapes by `kind`: `entry` and `exit` stadium, `decision` rhombus, `step` and `loop-back` rectangle. Node label is the two-line `"NAME<br/>derived label"` pattern the site already uses.
- Edges: `-->` for `sequence`; `-->|"condition"|` for `branch`; `-. "condition" .->` for `loop-back` and `re-entry`.
- Escaping: `&`, `<`, `>`, `"` become HTML entities; any residual backtick or pipe becomes a space. This matters concretely for feature-004's charts, whose GATE branch condition contains `>=` and `{floor}` and whose bare-verb entry label contains `""`.
- **Every chart carries its own `classDef` block** in the casulo palette rather than relying on the integration's theme configuration -- `astro-mermaid` 2.0.2 silently drops the site's `themeVariables` (KI-001), and self-contained `classDef`s are also what the site's existing hand-authored diagrams do. The charts are therefore correct whether or not KI-001 is ever fixed.
- Every node also emits a `class <id> aidNode;` statement backed by a `classDef aidNode` in the same fence. This is **hook H3** -- the id-template-independent selector feature-006 binds to -- so it is a published contract, not decoration.

**Acceptance Criteria:**
- [ ] Output is the fence body only: it contains no ``` fence markers, no H2 and no notice line.
- [ ] Each of the five `kind` values renders its specified shape, and each of the four edge kinds renders its specified arrow form.
- [ ] Escaping converts `&`, `<`, `>` and `"` to entities and replaces any residual backtick or pipe with a space -- verified against a condition containing `>=` and `{floor}` and a label containing `""`.
- [ ] Every chart emits its own `classDef` block, so rendering does not depend on `themeVariables` and KI-001 cannot degrade it.
- [ ] **Every node carries a `class <id> aidNode` statement backed by a `classDef aidNode` in the same fence** -- hook H3, which feature-006 depends on.
- [ ] Node declarations follow `order`; edge lines follow `(from.order, to.order, condition)`.
- [ ] Two calls on the same chart return **identical strings**, and the function reads no clock, environment or random source.
- [ ] Unit tests cover every node kind, every edge kind, the escaping table and the `classDef`/`aidNode` emission; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
