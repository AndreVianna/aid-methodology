# task-007: First-sentence skill summary rule

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-007. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-007/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-002 (feature-002-grouped-skill-index)

**Depends on:** task-004

**Scope:**
- Create `site/scripts/skills/summary.mjs`: `skillSummary(record) -> string` -- the **first sentence** of the skill's frontmatter `description` (text up to and including the first `. `), hard-cut at the last word boundary at or below 157 characters with a trailing `…` if longer, falling back to `AID skill <dir> — declared frontmatter contract, generated from canonical/.` when the skill carries no `description`.
- This module is deliberately the **single authority** for that rule. feature-002's SPEC states that if feature-001's page-`description` rule and feature-002's card-intent rule are implemented in one sitting, `render-page.mjs` should import `skillSummary` rather than keep a private copy -- delivery-002 implements both, so that sanctioned path applies. `render-page.mjs` (task-010) and `render-index.mjs` (task-014) both consume this module; neither reimplements the rule.
- Rejected here and not to be reintroduced: sourcing card intent from the catalog's `intent` field, which exists for only 94 of the 111 skills and would need a second rule and a second authority.
- Same conventions as the rest of the cluster: ESM `.mjs`, `node:` builtins only, 2-space indentation, a pure exported function with no import-time side effect, no new dependency.

**Acceptance Criteria:**
- [ ] Output is identical across repeated calls for the same input -- no clock, no environment read, no randomness.
- [ ] A description shorter than the cap returns its first sentence unchanged, including the terminating `.`.
- [ ] A description longer than 157 characters is cut at the **last word boundary at or below 157** and gains a trailing `…`; the cut never lands mid-word.
- [ ] A description with no `. ` returns the whole value, still subject to the 157-character cap.
- [ ] A skill with no `description` field returns feature-001's fallback string byte-for-byte, with the directory name interpolated.
- [ ] The boundary cases at exactly 156, 157 and 158 characters each behave as specified.
- [ ] Unit tests exist for the exported function covering short, at-cap, over-cap, no-sentence-terminator and absent-description inputs; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
