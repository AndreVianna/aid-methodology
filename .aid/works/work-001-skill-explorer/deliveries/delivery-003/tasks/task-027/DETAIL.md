# task-027: Residual heuristic extractor

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-027. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-027/STATE.md.
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

**Depends on:** task-020, task-021, task-023

**Scope:**
- Create `site/scripts/lib/flow-graph/extract-residual.mjs` -- feature-003's **named sub-scope**. FR-2 forbids a "no flow derivable" fallback state, so this extractor **always** emits a chart, and every chart it emits is stamped `confidence: 'approximate'`.
- A ladder; the first rung producing at least 2 nodes wins. **R1**: an ASCII state map -- a fenced or indented block of `->`/arrow-separated bracketed tokens -- or a `State machine:` line with arrow-separated tokens; tokens in order, sequence edges between consecutive tokens, bracketed or parenthesised suffixes becoming conditions. **R2**: `^###\s+State\s+\d+\s*[--]\s*(NAME)` headings, the form the three ticket skills use; headings in order, sequence edges consecutive. **R3**: `^###\s+Step\s+\d+` headings, where a `## Mode N` ancestor heading **starts a separate lane, each with its own entry** -- this is `aid-config`'s two-mode shape, and it is the residual extractor's fixture. **R4**: a top-level ordered list whose items begin with a verb. **R5**: last resort -- a three-node spine `Entry -> "Run <skill>" -> Exit`, labelled from the frontmatter `description`.
- R1's token parser also runs as a **corroborating spine** for the two authored shapes (evidence precedence 1); it is the same parser, exported for that use.
- `aid-triage` is **not** a residual skill and must not be treated as one: it carries a full `## Dispatch` table with `State` and `Advance` columns and classifies `dispatch-table`. The real residual population is curated on-demand skills such as `aid-config`, the ticket skills and the connector skills.

**Acceptance Criteria:**
- [ ] The extractor **always** returns a chart -- there is no code path that returns null, empty or a "no flow derivable" marker, for any input including an empty body.
- [ ] Every chart it emits carries `confidence: 'approximate'`.
- [ ] The ladder is evaluated in order and the first rung yielding at least 2 nodes wins; a lower rung is never consulted once a higher one succeeds.
- [ ] R3's `## Mode N` ancestor starts a separate lane with its own entry node, reproducing `aid-config`'s two-mode shape.
- [ ] R2 handles the `### State N — NAME` form the three ticket skills use.
- [ ] R5 always produces a valid three-node spine labelled from the frontmatter `description`, so **no skill is left chart-less** even when every other rung fails.
- [ ] Every chart the extractor emits passes `validateChart` (V1-V8) with `ok === true`.
- [ ] R1's token parser is exported and is the same implementation the authored extractors use as a corroborating spine -- there is no second token parser, verified by grep.
- [ ] Unit tests exist per rung, including an input that reaches R5; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
