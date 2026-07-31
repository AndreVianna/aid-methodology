# task-022: Advance-clause block scoping, separator proposal and target resolution

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-022. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-022/STATE.md.
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
- Create `site/scripts/lib/flow-graph/advance.mjs` and implement **rules 1-4 only**: block scoping, the two-phase separator proposal and validation, per-clause target resolution, and rule 4's terminal handling. Rules 5-9, the rule-10 residual guard and V9 enforcement are **task-023**, which continues in this same file -- the two tasks are a strict sequence and must never run concurrently.
- **Input is a block, not a line.** An `**Advance:**` runs from its marker to the first blank line, `---` rule, or heading. 19 advances in `canonical/skills/**/*.md` wrap, and at least one hides an entire clause on its continuation line -- `aid-create-ticket/SKILL.md`:200-201 ends line 200 mid-clause and carries a third branch, `` `[3] Cancel` -> halt ``, on line 201. The same block rule is what task-023's body scans will need.
- **Phase 1 -- propose.** Cut the block at every occurrence of a member of the measured separator set, outside backticks: `;`; ` / ` (spaced slash); unspaced `/` between two state-like tokens; ` then `; ` or `; the `(or X ...)` parenthetical alternative; and the sentence boundary `. `.
- **Phase 2 -- validate, then accept or reject.** A proposed cut is accepted **only if every resulting clause resolves** to a declared state or to a terminal keyword (`halt`, `HALT`, `Stop here`, a `PAUSE-FOR-USER-*` keyword). Otherwise the cut is discarded and the text stays joined. Phase 2 is what makes the aggressive separators safe: ` or ` appears inside conditions and prose, and 13 of the 16 measured `. `-bearing blocks are commentary, and in every one the trailing fragment resolves to nothing.
- **Rule 2 -- target resolution.** Per clause: strip advance-type keywords **wherever they appear**, not only at the head (the measured `<condition> -> CHAIN -> TARGET` form puts one in the middle); strip `->` and its arrow forms; strip a `[State: X]` wrapper to `X`; the first token matching a declared state name case-insensitively is the target. Matching is **whole-token and exact, never substring**, and a hyphenated state name is one token. A name declared more than once resolves to the **lowest-`order`** node and records a collision warning -- resolution must be total and deterministic, since ids are positional while advance clauses address states by name.
- **Rule 3 -- condition capture.** Remaining text becomes `condition`, verbatim, capped at 80 code points by the **shared truncator from task-020**, never reimplemented and never normalized into a predicate.
- **Rule 4 -- terminals.** A clause whose target resolves to no declared state becomes the node's `terminal = { advanceType, handoff }` and the node joins `exits`, emitting **no edge**. This is what keeps "every edge target resolves in-chart" true by construction rather than by a later repair pass.
- `advanceType` uses the closed four-value vocabulary of `canonical/aid/templates/state-machine-chaining.md` plus `UNSPECIFIED`; no fifth value is invented. Untyped `Stop here.` prose maps to `PAUSE-FOR-USER-ACTION`.

**Acceptance Criteria:**
- [ ] The parser consumes a **block**, not a line: `aid-create-ticket/SKILL.md`:200-201's third clause on the continuation line is captured, and a line-anchored implementation is demonstrably insufficient.
- [ ] A proposed cut is accepted only when **every** resulting clause resolves; the measured false positives produce no phantom edge -- `when all sections are Complete or N/A`, `add information or re-validate`, `Both continue inline.` and `This is the terminal state.` each leave the text joined.
- [ ] Every separator in the measured set has a passing case: `;`, ` / `, unspaced `/` between state tokens, ` then `, ` or `, the `(or X ...)` parenthetical, and `. `.
- [ ] Target matching is whole-token and exact: `DONE-IDEMPOTENT` does **not** match `DONE`, while `PRESENT-FINDINGS`, `Q-AND-A`, `DESCRIBE-SEED` and `APPROVAL-HALT` all resolve.
- [ ] `RUN/consolidate` resolves to `RUN`, because `consolidate` resolves to nothing and phase 2 therefore rejected that cut.
- [ ] Advance-type keywords are stripped **anywhere** in a clause, so `` `[1] Approved` -> CHAIN -> DONE `` resolves its target to `DONE`.
- [ ] A duplicate state name resolves to the lowest-`order` node and records a collision entry in `warnings`; resolution never returns ambiguously.
- [ ] `condition` is captured verbatim, capped at 80 code points **by the shared truncator imported from `model.mjs`** -- the module contains no second truncation implementation, verified by grep.
- [ ] Rule 4: a clause resolving to no declared state emits **no edge**, populates `terminal = { advanceType, handoff }`, and adds the node to `exits`.
- [ ] `advanceType` only ever takes one of `CHAIN`, `HALT`, `PAUSE-FOR-USER-ACTION`, `PAUSE-FOR-USER-DECISION`, `UNSPECIFIED`.
- [ ] Unit tests exist for every rule and every separator in this task's scope; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
