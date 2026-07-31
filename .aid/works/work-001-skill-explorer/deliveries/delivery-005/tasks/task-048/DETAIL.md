# task-048: `Head` key in the Starlight `components:` map

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-048. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-048/STATE.md.
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

**Type:** CONFIGURE

**Source:** work-001-skill-explorer -> delivery-005 (feature-006-interactive-node-panel)

**Depends on:** task-047

**Scope:**
- Add exactly one key -- `Head: './src/components/overrides/Head.astro'` -- to the existing `components:` map in `site/astro.config.mjs`. The map's own comment says to *add* keys, never rewrite the map; that one instruction is still correct and load-bearing even though the surrounding comment text is stale (KI-013 records that it claims the map is empty when it holds four keys, and reserves slots by a *previous* work's `feature-NNN` numbers).
- **This task is the THIRD editor of `site/astro.config.mjs` in this work -- risk R1.** It must be sequenced **after delivery-002's task-016** (the `Skills` sidebar group) **and after any KI-001 `themeVariables` ride-along**, and must **never** be applied concurrently with either. The three edits live in three different literals and do not conflict semantically, but concurrent agents on one file is the failure mode R1 names. This task touches only the `components:` map: the `sidebar` array and the `mermaid({ ... })` options object are out of scope here.
- No other change to the file, no new dependency, no script key.

**Acceptance Criteria:**
- [ ] Exactly one key is added to the `components:` map; the four existing keys and every other line of `astro.config.mjs` are untouched, verified by diff.
- [ ] The `sidebar` array and the `mermaid({ ... })` options object show **no diff** from this task.
- [ ] The edit is idempotent -- re-applying it adds no second key and produces no further diff.
- [ ] No secret, token or credential appears in plaintext.
- [ ] **AC-6.5, verified against a real build:** after a full `npm run build`, a grep over `site/dist/**/*.html` shows the controller referenced **exactly once on every generated skill detail page** and **on no other page in `dist/`, including `/skills/` itself**.
- [ ] The stylesheet link and the JSON island follow the same distribution as the controller -- present on skill detail pages, absent everywhere else.
- [ ] The four generated `reference/*.md` pages and every hand-authored page build unchanged, and the site builds green.
- [ ] Sequencing is honoured: this task runs after task-016 and after any KI-001 ride-along, and the delivery record shows it was not concurrent with either.
- [ ] All section-6 quality gates pass
