# task-039: `flow-graph-doorways.test.mjs` AC-4 / corpus tier

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-039. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-039/STATE.md.
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

**Type:** TEST

**Source:** work-001-skill-explorer -> delivery-003 (feature-004-doorway-engine-charts)

**Depends on:** task-038

**Scope:**
- Append the corpus and AC-4 groups to `site/scripts/__tests__/flow-graph-doorways.test.mjs`. This task and task-038 own the same file and are a strict sequence. **This task closes delivery-003.**
- **AC-4 fixture 1 -- `aid-create-api`** (generated doorway to engine), with `aid-fix` as a lighter second case for the bare-verb binding the primary fixture cannot exercise.
- **AC-4 fixture 2 -- `aid-test-security`** (kind-sibling to sibling skill).
- **Cross-page identity (AC-6)**, **splice fidelity**, **validator conformance** over every doorway chart, the **provider partition**, **provenance** equality including nodes citing the engine and gate templates, and **idempotence**.
- Assertions are structural properties plus **named landmarks**, so prose edits in the engine do not break the suite while a change to its state set does. Where a group says "for every ...", it iterates the live directory listing.

**Acceptance Criteria:**
- [ ] `aid-create-api`: `shape === 'engine-doorway'`, `extractor === 'extract-engine'`, `confidence === 'derived'`; `entries` is exactly `[nodes[0].id]`; the entry label contains `VERB=create` and `ARTIFACT=api`.
- [ ] **The loop:** exactly one self-edge in the chart, `from === to === <GATE id>`, `kind === 'loop-back'`, provenance citing `shortcut-engine.md`.
- [ ] **The INTAKE branch:** exactly two `branch` edges, to `CAPTURE` and `CONTINUATION`, `INTAKE.kind === 'decision'`, with the two conditions asserted verbatim.
- [ ] **The GATE branch:** exactly two `branch` edges, to `APPROVAL-HALT` and `Circuit breaker`, **plus** the `loop-back` self-edge -- so `edges.filter(e => e.from === GATE)` has length 3 with kinds `{branch, branch, loop-back}` -- and `GATE.kind === 'decision'`.
- [ ] **The exit:** `exits` contains `APPROVAL-HALT` with `terminal.advanceType === 'HALT'` and a `terminal.handoff` mentioning `/aid-execute`, and also contains `CONTINUATION` and `Circuit breaker`.
- [ ] **The spine:** node names in `order` are exactly the doorway followed by `INTAKE`, `CONTINUATION`, `CAPTURE`, `SPEC`, `PLAN`, `DETAIL`, `GATE`, `Circuit breaker`, `APPROVAL-HALT`.
- [ ] `aid-fix` is asserted as a second, lighter case: the same nine engine-segment node names, and an entry label containing `ARTIFACT="" (bare verb)`.
- [ ] `aid-test-security`: `shape === 'sibling-doorway'`, parent `aid-test`; exactly one hop edge from `nodes[0]`, `kind === 'sequence'`, `condition === 'kind bound to security'`, `sourceKind === 'sibling'`, targeting the parent's entry node; the node names after the entry are exactly the parent's six-state spine, each with `provenance.file` pointing at `aid-test`'s `SKILL.md`; a `loop-back` edge `VERIFY -> RUN`; `PRESENT` with exactly two `branch` edges to `HANDOFF` (condition `optional`) and `DONE` (condition `null`) and `kind === 'decision'`; `DONE` in `exits` with `terminal.advanceType === 'UNSPECIFIED'`; `confidence === 'derived'`.
- [ ] **Cross-page identity (AC-6):** for **every** `engine-doorway` skill, `renderMermaid(chart)` minus the entry-node declaration and hop-edge lines is **string-equal** to the same slice of `aid-create-api`'s. This is a sharper guard than a two-run diff -- it fails the moment anything per-page leaks into the shared segment.
- [ ] **Splice fidelity:** for **every** `sibling-doorway` skill, the spliced segment is deep-equal to `buildFlowChart({ name: parent })`'s own chart under the id/order offset.
- [ ] **Validator conformance:** `validateChart(chart).ok === true` for every doorway chart, with `entries.length === 1`, `exits.length >= 1`, every self-edge satisfying `from === to` with both resolving, and no `(from, to, condition)` triple repeating.
- [ ] **Provider partition:** for every directory under `canonical/skills/`, exactly one `BODY_PROVIDERS` entry's `applies()` returns `true`.
- [ ] **Provenance:** every node's `provenance.excerpt` equals the live slice of its cited file, including nodes citing `shortcut-engine.md` and `work-initiation-gate.md`, which are not under `canonical/skills/`.
- [ ] **Idempotence:** two runs produce byte-equal `serializeChart` and `renderMermaid` output for both fixtures.
- [ ] **No literal corpus or per-shape count appears in any assertion**; every "for every ..." group iterates the live directory listing.
- [ ] Delivery-002's guarantees still hold: AC-1, AC-2 and AC-8 pass unchanged and `gen-reference.mjs` remains byte-unmodified.
- [ ] Both of feature-004's AC-4 fixtures are covered, and tests are deterministic with clean setup/teardown.
- [ ] All section-6 quality gates pass
