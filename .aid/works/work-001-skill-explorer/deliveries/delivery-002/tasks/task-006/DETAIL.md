# task-006: Code-span-aware frontmatter value renderer

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-006. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-006/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-002 (feature-001-skill-detail-pages)

**Depends on:** task-004

**Scope:**
- Create `site/scripts/skills/render-value.mjs`: `renderFrontmatterValue(field) -> string`, applied uniformly and keyed on `Field.kind`, **never on the key's name** -- AC-2 must hold for a frontmatter key nobody has written yet.
- `kind: 'list'` renders as items joined `` `a`, `b`, `c` ``, each in a code span.
- `kind: 'scalar'` renders the text with `&` -> `&amp;` and `<` -> `&lt;` applied **only outside the author's own inline code spans**: tokenize the value into code-span runs and text runs using CommonMark's backtick-run rule, escape text runs only, and pass code-span runs through byte-identical. This is load-bearing, not defensive -- 39 frontmatter values carry `<` followed by a letter or `/`, several inside an authored code span (e.g. `aid-read-ticket`'s `` `aid-read-ticket [<connector>:]<ticket-id>` ``). Escaping blindly prints a literal `&lt;` to the reader because entities are not decoded inside code spans; not escaping lets markdown swallow `<connector>` as an HTML tag.
- No pipe escaping: the header is a bullet list, not a table, precisely so the 8 values containing `|` need no second escaping layer.
- Same conventions as the rest of the cluster: ESM `.mjs`, `node:` builtins only, 2-space indentation, a pure exported function with no import-time side effect, no new dependency.

**Acceptance Criteria:**
- [ ] A `<` outside a code span is escaped to `&lt;`; a `<` inside an authored inline code span passes through byte-identical -- asserted with a fixture drawn from `aid-read-ticket`'s real `description`.
- [ ] `&` is escaped outside code spans and passed through inside them, by the same rule.
- [ ] A `|` is emitted unescaped in both run types.
- [ ] The rule never branches on a key's name: a synthetic frontmatter key that exists nowhere in the corpus renders correctly by `kind` alone.
- [ ] Backtick runs of length 1 through 4 are tokenized correctly, matching CommonMark's rule that a code span is closed by a backtick run of equal length.
- [ ] `kind: 'list'` output wraps every item in its own code span and joins with `, `.
- [ ] Unit tests exist for the exported function covering each case above; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
