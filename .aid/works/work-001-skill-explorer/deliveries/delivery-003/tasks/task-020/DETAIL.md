# task-020: Flow-graph model and source addressing

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-020. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-020/STATE.md.
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

**Depends on:** task-019

**Scope:**
- Create `site/scripts/lib/flow-graph/model.mjs`: the `FlowChart` / `FlowNode` / `FlowEdge` / `Provenance` constructors, `n1...nN` id assignment by first appearance in source order, the `kind` precedence rule (`exit > entry > decision > loop-back > step`, where `decision` counts **`branch` edges only** so a node that merely loops is not drawn as a rhombus), the `entries` and `exits` computation, the shared code-point truncator, and `serializeChart()`.
- `entries` = every in-degree-0 node, **plus** the lowest-`order` node of any weakly-connected component that has none (a pure cycle), so `entries` is non-empty by construction and the reachability rule is always satisfiable. `exits` = every node whose advance is `HALT`, a `PAUSE-FOR-USER-*` value, absent, or resolves only to an out-of-chart handoff, **with a fallback**: if that set is empty, the highest-`order` node is designated an exit and a `warnings` entry is recorded. Both rules make AC-3 satisfiable by construction rather than by a repair pass.
- The **shared truncator** is one implementation used by both labels (<= 60 code points) and edge conditions (<= 80): measure with `Array.from`, never `String.length`; slice through `Array.from` so a surrogate pair can never be split; cut at the last whitespace boundary at or below the limit minus one, strip a trailing `,` `;` `:` `--` and append the ellipsis; and when there is **no** whitespace boundary, hard-cut at exactly the limit minus one. That character-level fallback is what makes the bound unconditional.
- Create `site/scripts/lib/flow-graph/source.mjs`: frontmatter split, line-addressed slicing, the `Provenance` builder, **and the shared `## State: NAME` section reader**.
- **Placement call, recorded because the SPEC did not assign it.** feature-003 states that extractor 2's section reader is "a shared helper rather than private to that extractor" -- extractor 1 needs it for `inline` Detail cells and feature-004's engine derivation needs it for the engine's `below` cells -- but it names no owning file. It is placed in `source.mjs`, the module that already owns line-addressed slicing. This is a placement decision taken at Detail, not a contract stated by feature-003.
- Conventions: `site/`-local 2-space ESM, `node:`-scheme builtins only, kebab-case filenames, no new dependency, its own minimal frontmatter parser rather than a YAML dependency, `canonical/` read and `profiles/*` never.

**Acceptance Criteria:**
- [ ] `entries` is non-empty for every constructible chart, including one that is a single pure cycle with no in-degree-0 node.
- [ ] `exits` is non-empty for every constructible chart; the highest-`order` fallback fires only when the primary rule yields nothing, and it records a `warnings` entry when it does.
- [ ] `kind` follows the documented precedence, and `decision` is determined by counting **`branch`** edges -- a node with one `sequence` edge plus a rule-5 self-edge is **not** a `decision`.
- [ ] The truncator is a single exported function used for both the 60-code-point label bound and the 80-code-point condition bound; `String.length` appears nowhere in the measurement path, and `Array.from` slicing is used so no surrogate pair is split.
- [ ] The truncator's no-whitespace-boundary path hard-cuts at the limit minus one, so **no input can produce a label exceeding 60 code points**.
- [ ] Node ids are assigned `n1...nN` by first appearance in source order -- never hashed, never random -- and every id matches `^[A-Za-z][A-Za-z0-9_]{0,31}$`.
- [ ] `serializeChart` emits fixed key order matching the field order of feature-003's schema tables, `JSON.stringify(chart, null, 2)` plus exactly one trailing newline, LF endings only.
- [ ] Edge emission order is `(from.order, to.order, condition)`, and two calls on the same chart produce identical output.
- [ ] The shared `## State: NAME` section reader is exported from `source.mjs` and returns both the heading-through-lead-paragraph range and the full-section range, so extractor 1, extractor 2 and the engine derivation can all consume it unchanged.
- [ ] `Provenance` carries `file` (repo-root-relative POSIX under `canonical/`), 1-based inclusive `startLine`/`endLine`, `sourceKind`, and an `excerpt` that is the verbatim LF-joined slice of that range.
- [ ] Unit tests exist for every new public function; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
