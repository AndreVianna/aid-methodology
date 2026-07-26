# task-036: Sibling-doorway extractor

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-036. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-036/STATE.md.
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

**Depends on:** task-033, task-034

**Scope:**
- Create `site/scripts/lib/flow-graph/extract-sibling.mjs` -- shape 4, `sibling-doorway`: `extractSiblingDoorway(skillRecord) -> FlowChart`, plus `resolveSiblingParent({ body })` and the `parentChartCache`.
- **`resolveSiblingParent()` is placed here as a Detail-time placement call, recorded because feature-004's SPEC did not assign it a file.** Only shape 4 uses it, so unlike `readDoorwayBinding` (which both extractors need and which therefore lives in `compose.mjs`, task-034) it has no reason to be shared. Resolve the parent by D3's own rule: the single distinct `canonical/skills/<name>/SKILL.md` reference in the body. Two or more distinct references contradicts D3 and cannot occur for a skill the classifier routed here. If task-019's seam-4 decision put `delegatesTo` on the classifier's return, prefer that value and keep this function as the fallback feature-004 specifies.
- Build the parent's chart with feature-003's `buildFlowChart({ name: parent })`, **memoized per parent name** in `parentChartCache` -- `aid-create-document`'s chart is built once and reused by the ten siblings that resolve to it, and that memoization is a contract, not an optimization, because re-deriving it ten times would be visible in build time.
- **Splice the parent's chart whole, verbatim, after the hop.** **No feature-004 rule -- not L1, not B1 -- is applied to the spliced segment.** This is an invariant, not an omission: a reader who opens `/skills/aid-test/` and `/skills/aid-test-security/` must see the same `aid-test` flow. It is also why `aid-test`'s own early-halt gate arm is not drawn on either page.
- Entry node and hop edge by sub-form. **Kind-sibling** (body carries `{verb, artifact}`): label is the braced group verbatim; hop `condition` is the bolded facet binding, e.g. `kind bound to security`. **Pure alias** (body carries `alias_of` and no facet binding): label is `alias of <parent>`; hop `condition` is `null`, because an alias binds nothing and an unconditional arrow is the truthful rendering. **Neither** (none today): label `Delegates to <parent>`, `condition: null`, plus warning **W1**.
- `confidence` is **the weaker of the two** -- `approximate` if the parent's chart is, `derived` otherwise (warning **W4** when it weakens). Today this matters for exactly one skill, whose parent is a residual-shape skill.
- Resolution is capped at **4 hops** with a visited-set cycle guard. On exceeding either, the hop terminates in an `exit` node naming the unresolved parent and warning **W3** is recorded -- never a throw. No chain deeper than one hop exists today; the cap is durability, and the classifier stays the authority.
- Warning **W2**: a sibling body carrying H2 sections beyond the hop prose -- those sections are not drawn and the warning names them.
- Emit the one-line **sibling resolution notice** above the fence, naming the parent and the facet binding, with a `GITHUB_BLOB_BASE` link.

**Acceptance Criteria:**
- [ ] For `aid-test-security`: `shape === 'sibling-doorway'`, `extractor === 'extract-sibling'`, resolved parent `aid-test`; `nodes[0].name === 'aid-test-security'` with `kind === 'entry'` and a label containing `verb: test` and `artifact: security`.
- [ ] The hop is exactly one edge from `nodes[0]`, `kind === 'sequence'`, `condition === 'kind bound to security'`, `sourceKind === 'sibling'`, targeting the parent chart's own entry node.
- [ ] **Splice fidelity:** the spliced segment is deep-equal to `buildFlowChart({ name: parent })`'s own chart under the id/order offset -- `/skills/aid-test/` and `/skills/aid-test-security/` cannot disagree about `aid-test`. Neither L1 nor B1 touches the spliced segment, so `aid-test`'s own gate arm is drawn on neither page.
- [ ] The parent's node names after the entry are exactly the parent's own spine, every one carrying `provenance.file` pointing at the parent's `SKILL.md`.
- [ ] `parentChartCache` is keyed by parent directory name; `aid-create-document`'s chart is derived **once** and reused by all ten of its siblings, asserted by call count or object identity.
- [ ] The pure-alias sub-form yields the `alias of <parent>` label and a hop with `condition === null`; the no-binding sub-form yields `Delegates to <parent>` plus W1.
- [ ] `confidence` weakens to `approximate` when the parent's chart is approximate, recording W4; the one skill whose parent is residual-shaped renders feature-003's approximate notice.
- [ ] Exceeding the 4-hop cap or hitting a resolution cycle emits W3 and an `exit` node naming the unresolved parent -- and **never throws**.
- [ ] W2 fires for a sibling body carrying its own H2 sections and names them.
- [ ] `validateChart(chart).ok === true` with `entries.length === 1` and `exits.length >= 1` for every sibling doorway.
- [ ] The resolution notice is prose above the fence with a `GITHUB_BLOB_BASE` link, not a chart node.
- [ ] Unit tests exist for parent resolution, the memo, both sub-forms, the cap and the cycle guard; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
