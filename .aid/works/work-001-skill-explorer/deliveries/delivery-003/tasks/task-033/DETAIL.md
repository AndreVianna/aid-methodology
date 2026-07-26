# task-033: Engine core derivation, memo and deep-freeze

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-033. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-033/STATE.md.
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
- **This is the first feature-004 task. It must not start before task-032 is Done** -- feature-004 edits `flow-graph/index.mjs` and `skills/body.mjs`, both owned by feature-003 tasks, and delivery-003's BLUEPRINT requires the two features to be sequenced, never concurrent.
- Create `site/scripts/lib/flow-graph/engine-core.mjs`: `getEngineCore() -> EngineCore`, deriving the shared shortcut-engine chart **once per process** from `canonical/aid/templates/shortcut-engine.md` and `canonical/aid/templates/work-initiation-gate.md`, then deep-freezing it.
- Derive the spine with feature-003's `extract-dispatch.mjs` **verbatim and unmodified**: `shortcut-engine.md`'s `## State Machine` heading has text exactly `State Machine` and is followed by a GFM table carrying `State` and `Advance` columns, so D1 matches cleanly. D1's "exactly" clause is load-bearing here -- the engine has an earlier `## Dispatch Protocol` heading whose section holds no table, and an `## Invocation Contract` table whose columns are `Value | Source | Notes`; a looser discriminator would select the wrong one and yield zero nodes.
- The engine's `Detail` cell says `below`, not `inline`, so bind each `## State: NAME` section through **feature-003's shared section reader in `source.mjs`** rather than widening feature-003's vocabulary. Teaching `extract-dispatch.mjs` that `below` means `inline` is rejected: a one-token change to a graded module for a vocabulary used by one file.
- **E-rules L1 and B1 fire here. Placement call, recorded because the SPEC is ambiguous.** feature-004 describes both rules as "scoped to `extract-engine.mjs` and to nothing else", yet the `EngineCore` it specifies already contains their output -- `CONTINUATION`, `Circuit breaker` and the GATE self-edge are all in the ten-node chart and in the nine engine-segment node names its own test group asserts. Since the derivation happens in `getEngineCore()`, the rules must fire here. This is a Detail-time placement decision, not a contract feature-004 states.
- **E-rule L1** -- internal loop implies a self-edge: inside a state section, an explicit loop phrasing whose target resolves to no declared state but which is written within that state's own section emits one `loop-back` **self-edge** on that state, `condition: null` unless the loop phrasing's own sentence states a guard. At most one per node, and none if the node's own advance clauses already name it. Measured firing site: **GATE only**. Pairing the self-edge with the `Otherwise` ten lines away in a different rung is rejected as an unstated heuristic.
- **E-rule B1** -- named early-halt arm implies a branch: inside a state section, a bolded arm lead-in whose sentence terminates the run before the state's declared advance target (trigger tokens `HALTS`, `STOP`, `does not run`, `instead of looping further`) emits an `exit` node named **verbatim** from the arm's own name token in the resolved source, a `branch` edge to it, and a re-kinding of the state's declared advance edge from `sequence` to `branch` with the continuing arm's guard as its condition. Each condition is the verbatim guard clause, emphasis- and backtick-stripped, capped by feature-003's **shared truncator**. At most one B1 node per state. Measured firing sites: **INTAKE** (`CONTINUATION`) and **GATE** (`Circuit breaker`).
- **W5**: warn when the engine's `## State Machine` rows disagree with its own Maintenance note's declared order -- a cheap drift detector on the file this feature depends on most.
- `EngineCore` carries `nodes`, `edges`, `exits`, `sources` and `warnings` only. It carries **no** `skill`, `title`, `entries` or `confidence`: those are properties of a *page's* chart, and leaving them off is what makes it impossible for one page's values to leak into the next.

**Acceptance Criteria:**
- [ ] The second call to `getEngineCore()` returns the **identical object reference** -- the memo is held at module level and the two source files are read once per process.
- [ ] The returned graph is **deeply frozen** over nodes, edges and every `Provenance`: a write attempt throws in strict mode. This is the load-bearing AC-6 defence -- a shared mutable memo is how page 40 ends up carrying page 39's edits, and freezing turns that class of bug into a build-time `TypeError`.
- [ ] The nine core node names are the seven `## State Machine` table rows in table order, with each B1 node inserted **immediately after its parent state**, deterministically.
- [ ] `extract-dispatch.mjs` is **byte-unmodified** by this task, verified by diff, and the engine's `## State:` sections are bound through the shared reader in `source.mjs` rather than through a private implementation.
- [ ] L1 emits exactly one self-edge, on **GATE**, with `condition: null`, provenance covering the loop-phrasing line.
- [ ] B1 emits exactly two early-halt nodes -- `CONTINUATION` under INTAKE and `Circuit breaker` under GATE -- each named verbatim from its source, each with a `branch` edge in and the parent's declared advance edge re-kinded to `branch`.
- [ ] `CONTINUATION`'s provenance cites `work-initiation-gate.md` and `Circuit breaker`'s cites `shortcut-engine.md`; both names are **read from source, not coined**.
- [ ] Every B1 condition is the verbatim guard clause, capped by the shared truncator imported from `model.mjs` -- no second truncation implementation exists.
- [ ] `EngineCore` has no `skill`, `title`, `entries` or `confidence` key.
- [ ] W5 fires when the table rows disagree with the Maintenance note's declared order, as a warning and never a throw.
- [ ] Every node's `provenance` is under `canonical/` and its `excerpt` equals the live slice -- including nodes citing the engine and gate templates, which are not under `canonical/skills/`.
- [ ] Unit tests exist for the memo identity, the deep-freeze throw, the node-name spine, L1 and B1; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
