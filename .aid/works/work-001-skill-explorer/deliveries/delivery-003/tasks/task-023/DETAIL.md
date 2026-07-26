# task-023: Advance-clause edge shaping, the residual guard and V9 enforcement

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-023. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-023/STATE.md.
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

**Depends on:** task-022

**Scope:**
- Continue `site/scripts/lib/flow-graph/advance.mjs` with **rules 5-9, the rule-10 residual guard, and V9 enforcement**. This task and task-022 own the same file and are a strict sequence; they must never run concurrently.
- **Rule 5 -- single-target conditional implies a self-loop.** A clause with exactly one target and a `when <guard>` condition emits a `loop-back` self-edge with `condition: 'otherwise'`. **The rule fires unconditionally** -- it is *not* suppressed by the presence of other outgoing edges, and specifically not by a dispatch row that already branches, because the worker's guard and the row's conditions partition different things. The only guard is local: at most one rule-5 self-edge per node, and none if the node's own clauses already name that node.
- **Rule 6 -- `X then Y`, the optional side-trip (KI-008).** ` then ` is sequential prose, so the two clauses are **not** symmetric alternatives. When `X` carries an optionality marker -- `(optional)`, a bare `optional`, a trailing `?`, or an `if <cond>` qualifier -- emit **two `branch` edges**: `-> X` with the marker text verbatim as its condition, and `-> Y` with `condition: null`, the skip path. The `X -> Y` edge is not emitted here; it belongs to `X`'s own advance. When `X` carries no marker, emit a single `sequence` edge to `X` plus a warning recording that the `then Y` tail was read as `X`'s onward flow -- that case does not occur in the corpus today, so a warning is the honest default rather than an invented edge.
- **Rule 7 -- back-reference implies loop-back**, over the measured phrasing set (`loops? back to X`, `loops? to X`, `-> [State: X]`), scanned per the block rule. The same phrasings pointing at `Step N` / `PD-2` identifiers resolve to no declared state and correctly emit nothing -- a step inside a state is not a chart node. **Kind is decided by position, not phrasing:** any edge whose target sits earlier in the declared spine than its source is `loop-back`, whichever rule produced it, so a missed phrasing costs a *missing* edge (which rule 10 reports) rather than a *mis-kinded* one.
- **Rule 8 -- re-entry.** A heading whose text contains `Loopback` or `Re-entry` and whose body names a declared state emits a single `re-entry` edge into that state. Rule 8 takes precedence over rule 7.
- **Rule 9 -- pause-resume targets are metadata, not edges.** A `PAUSE-FOR-USER-*` clause naming the state the user resumes into records that state in `terminal.handoff` and emits **no** edge; the transition does not happen within a run.
- **Rule 10 -- the residual guard.** After clause extraction, subtract the accepted clauses' spans from the block and inspect what is left. Residue that is not pure commentary produces a **W-1 warning** carrying the skill, the state, the residue text and the `file:line`, surfaced with a run-level count and never thrown. "Pure commentary" is mechanical, not a judgement call: residue containing no declared-state token, no advance-type keyword and no `[State: ...]` reference.
- **V9 enforcement lives here, in the parser -- owner decision, recorded as work `STATE.md` Q3 and delivery-003's fifth seam.** Residue containing a reference to a **declared state of this chart** that is neither already an edge target from this node nor captured in `terminal.handoff` is an **error, and this module throws** with V9's stable name. The reason it lives here and not in `validate.mjs` is that the residue is leftover *source text* that exists only during parsing -- `FlowChart` carries no field holding it, so a validator handed the finished chart cannot distinguish "this state was never mentioned" from "this state was mentioned and its edge was dropped", which is exactly the KI-008 failure V9 exists to catch. The rejected alternative was a residue carrier on the model, which would flow into the `<skill>.flow.json` sidecar and then need exclusion from feature-006's browser projection.
- V9 is deliberately **narrow**, because a noisy guard is an ignored guard: it must stay silent on every measured residue in the corpus -- commentary carrying no state token, `Step E3` / `Step 1` which are not declared states, `/aid-define` which is a skill not a state, an already-consumed edge target, and the two pause-resume targets that rule 9 routes to `terminal.handoff`.

**Acceptance Criteria:**
- [ ] Rule 5 fires unconditionally, at most once per node, and never when the node's own clauses already name that node as a target; `aid-describe`'s `CONTINUE` ends with out-degree 3 -- two `branch` edges plus one `loop-back` self-edge.
- [ ] Rule 6's marked form emits two `branch` edges with the marker text verbatim on the first and `null` on the second, so `PRESENT.kind === 'decision'` falls out of the existing kind rule rather than being special-cased; the unmarked form emits one `sequence` edge plus a warning.
- [ ] Rule 7 emits nothing for `loop back to Step 4`-style phrasings that name no declared state, and edge kind is assigned by spine position rather than by which phrasing matched.
- [ ] Rule 8 takes precedence over rule 7: an explicitly-headed re-entry is kind `re-entry`, not `loop-back`, even though it also points backwards.
- [ ] Rule 9 populates `terminal.handoff` and emits no edge for a pause-resume target.
- [ ] Rule 10's W-1 warning carries skill, state, residue text and `file:line`, is reported with a run-level count, and **never throws**.
- [ ] "Pure commentary" is implemented as the stated mechanical test -- no declared-state token, no advance-type keyword, no `[State: ...]` -- and not as a heuristic.
- [ ] **V9 throws from this module**, with its stable guard name in the message, naming the skill, the state and the unconsumed declared state found in the residue.
- [ ] **The KI-008 case fails loudly.** Given `**Advance:** HANDOFF (optional) then DONE.` with ` then ` deliberately removed from the separator set, `DONE` is left named in the residue and unconsumed, and V9 **throws** -- it does not warn, and it does not pass. This is the regression that must never recur silently: pre-fix, `DONE` stayed reachable via `HANDOFF -> DONE`, so reachability was satisfied, no validator rule fired, and the chart was simply wrong.
- [ ] V9 stays **silent** on every measured benign residue: commentary with no state token, `Step E3` / `Step 1`, `/aid-define`, a state already an edge target from that node, and rule 9's two pause-resume targets.
- [ ] Post-fix, the five ` then ` blocks (`aid-test`, `aid-design`, `aid-prototype`, `aid-report`, `aid-research`) leave **no residue at all**.
- [ ] The module documents, at the V9 implementation site, that `validate.mjs` implements V1-V8 and that V9 lives here -- with the reason -- so a reader of either file finds the other.
- [ ] Unit tests exist for rules 5-9, rule 10 and V9, including the KI-008 throw case; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
