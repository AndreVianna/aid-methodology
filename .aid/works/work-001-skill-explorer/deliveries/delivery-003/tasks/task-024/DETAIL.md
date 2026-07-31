# task-024: Well-formedness validator V1-V8

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-024. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-024/STATE.md.
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
- Create `site/scripts/lib/flow-graph/validate.mjs`: `validateChart(chart) -> { ok, errors }`, a pure function over a `FlowChart`, implementing **V1 through V8 only**. It is the same function feature-004's doorway charts must pass, used unchanged there.
- V1: `nodes` non-empty, ids unique, every id matching `^[A-Za-z][A-Za-z0-9_]{0,31}$`. V2: `entries.length >= 1` and every entry id is a node id (**AC-3**). V3: `exits.length >= 1` and every exit id is a node id (**AC-3**). V4: every `edge.from` and `edge.to` is a node id -- no dangling edges (**AC-3**); a self-edge satisfies this trivially, since `from === to` and that node exists. V5: no duplicate `(from, to, condition)` triple. V6: every node reachable by walking edges from some entry -- always satisfiable, given task-020's `entries` rule. V7: every node has `provenance` with a non-empty `file` under `canonical/`, `1 <= startLine <= endLine`, and an `excerpt` whose line count equals `endLine - startLine + 1`. V8: every `label` non-empty and <= 60 Unicode code points, measured with `Array.from` -- the **same measure the shared truncator uses**, so the two cannot disagree.
- **V9 is deliberately NOT implemented here, and the module must say so.** Owner decision, recorded as work `STATE.md` **Q3** and as delivery-003's fifth seam: V9 is enforced at extraction, in `advance.mjs` (task-023), because the residue it tests is leftover *source text* that exists only during parsing. `FlowChart` carries no field holding a residue, so a validator handed the finished chart cannot distinguish "this state was never mentioned" from "this state was mentioned and its edge was dropped" -- exactly the KI-008 failure V9 exists to catch. The rejected alternative was a residue carrier on the model, which would flow into the `<skill>.flow.json` sidecar and then need explicit exclusion from feature-006's browser projection: three contracts widened to serve one rule.
- **Write that as a comment in `validate.mjs`, at the end of the rule list**, naming `advance.mjs` as V9's home and Q3 as the authority -- so nobody reading this module concludes a rule was forgotten. Note that feature-003's SPEC still states `validateChart` implements V1-V9 and is wrong on that point; task-019 records the delta.
- **Renumber nothing.** V1 through V8 keep exactly the meanings feature-003's V-table assigns them; the gap left by V9 is documented, not closed by shifting the numbers.
- `validateChart` is **pure and throws nothing** -- it returns `{ ok, errors }`. The **caller** throws, which is task-029's `buildFlowChart` façade. `chart.warnings` are logged, never thrown: a chart may be *approximate*, never *malformed*.

**Acceptance Criteria:**
- [ ] Each of V1 through V8 fails independently against a synthetic chart violating only that rule, and each error message names the rule and the offending node or edge.
- [ ] V2, V3 and V4 read `entries` / `exits` / edge endpoints -- **not `kind`** -- so a node that is both an entry and an exit still satisfies AC-3.
- [ ] V4 accepts a self-edge (`from === to`) as resolving, so the rule-5 and E-rule-L1 self-edges need no tolerance beyond what the rule already gives.
- [ ] V8 measures with `Array.from(label).length`, identical to the shared truncator's measure; `String.length` appears nowhere in the measurement path.
- [ ] V6's reachability walk starts from `entries` and never fails for a chart built through task-020's construction rules.
- [ ] **The module implements exactly eight rules.** No V9 implementation is present, and no rule is renumbered to close the gap -- V1-V8 keep their feature-003 meanings.
- [ ] A comment at the end of the rule list states that V9 is enforced in `advance.mjs`, gives the one-line reason (the residue exists only during parsing), and cites work `STATE.md` Q3 as the authority.
- [ ] `validateChart` is pure: it throws nothing, mutates nothing, and returns `{ ok, errors }` for every input including a malformed one.
- [ ] Unit tests exist for all eight rules; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
