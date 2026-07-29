# task-048: `reviewer-ledger-schema.md` scope rows and the `kb_gaps` frontmatter field

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

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** -- (none)

**Scope:**
- **`canonical/aid/templates/reviewer-ledger-schema.md`** -- add **exactly two rows** to the
  `## File: location` scope table (the `| Skill invocation | Ledger path |` table): `/aid-graph`
  own-artifact validators -> `.aid/.temp/review-pending/graph.md`, and `/aid-graph` KB-gap findings
  -> `.aid/.temp/review-pending/graph-kb-gaps.md`. This is the file-separation half of feature-006
  D7, which is what makes conflating the graded ledger with the delivered one impossible rather than
  merely discouraged: `grade.sh` grades exactly one file passed as its argument and has no
  row-filtering flag.
- **`canonical/aid/templates/kb-authoring/frontmatter-schema.md`** -- add the `kb_gaps:` field as
  **generator-written**, in the same class as `generator:` and `approved_at_commit:`. Record its
  YAML shape (a list of entries, each carrying `id`, `name`, `severity` and `clause`), name
  `detect-kb-gaps.mjs` as its sole producer, and state that it is never hand-authored. Add it to the
  same places `approved_at_commit:` appears -- the generated-doc frontmatter example, the
  fields-at-a-glance table, and its own per-field section -- so the document does not contradict
  itself.
- **This task lands only the additive, in-scope half of the shared-schema change.** The
  ledger-retention carve-out is **out of scope here and must not be written**. Specifically, in
  `reviewer-ledger-schema.md` the following stay byte-unchanged: the `## Lifecycle (per skill
  invocation)` section and its `DONE` branch; the `contracts:` frontmatter line "Persists across
  REVIEW->FIX cycles within one skill invocation; deleted at skill DONE"; the `## Status values` and
  `## grade.sh integration` sections; and the `## Authoring rules for the orchestrator` lines "At
  skill DONE: delete the ledger file" and "Never carry a ledger past skill DONE".
- **Why the boundary is hard.** Q8 is an accepted external dependency: the retention carve-out is a
  methodology-level change beyond work-005's scope (STATE.md Q8, PLAN.md risk 1), and **FR-26 does
  not close in delivery-003**. Task-049 drafts that text and records the gap; it lands nothing here.
  An executor who "helpfully" amends the shared Lifecycle section would change ledger behaviour for
  every other skill that reads this schema -- discover, execute, specify, plan, detail, interview,
  summarize, deploy -- which is precisely the failure this split exists to prevent.
- Neither amendment changes an existing rule, so no existing ledger and no existing KB document is
  invalidated.
- Both files are canonical templates, so both require the **FULL** generator afterwards. That run is
  **task-055**, not this task; no `profiles/`, `.claude/` or `.cursor/` copy is hand-edited here.
- Out of scope: the Lifecycle carve-out draft and the Q8 record (task-049); the FULL render
  (task-055); the detector that writes `kb_gaps` (tasks 046 and 047); the ledger's runtime shape
  assertions (tasks 052 and 053).

**Acceptance Criteria:**
- [ ] `reviewer-ledger-schema.md`'s `## File: location` table gains exactly two rows, both naming a
      path under `.aid/.temp/review-pending/`, one for `graph.md` and one for `graph-kb-gaps.md`.
- [ ] `git diff -- canonical/aid/templates/reviewer-ledger-schema.md` shows **only** those two added
      rows. In particular `## Lifecycle (per skill invocation)`, the `contracts:` frontmatter list,
      `## Status values`, `## grade.sh integration`, and `## Authoring rules for the orchestrator`
      are byte-unchanged.
- [ ] `frontmatter-schema.md` declares `kb_gaps:` as generator-written, in the same class as
      `generator:` and `approved_at_commit:`, with its YAML shape shown, `detect-kb-gaps.mjs` named
      as its sole producer, and "never hand-authored" stated explicitly.
- [ ] `kb_gaps:` is present consistently wherever the document enumerates fields -- the generated-doc
      frontmatter example, the fields-at-a-glance table, and a per-field section -- so no listing
      omits it.
- [ ] No existing field's rules change in `frontmatter-schema.md`: the required set (`objective:` /
      `summary:` / `sources:`), every existing well-formedness rule, and the `[FM-MISSING]` /
      `[FM-INVALID]` tag definitions are byte-unchanged, and no new rubric tag is introduced.
- [ ] `bash tests/canonical/test-grade.sh` still passes -- the amendments add scopes and a field and
      change no parsing rule.
- [ ] `canonical/aid/scripts/kb/lint-frontmatter.sh` emits nothing for a document carrying
      `kb_gaps:`, confirming the key is tolerated as unrecognised and needs no validator change.
- [ ] Only the canonical copies are edited: `git status --porcelain` shows no change under
      `profiles/`, `.claude/` or `.cursor/` from this task.
- [ ] All existing canonical suites still pass -- `bash tests/run-all.sh` reports no newly red suite.
- [ ] **The paired-TEST-task convention is deliberately overridden here, and the reason is recorded:**
      both edits are template prose with no runtime behaviour of their own, so no new suite is
      warranted. The standing proofs are the **unmodified** `tests/canonical/test-grade.sh` (which
      asserts no parsing rule moved) and **task-055**'s render-drift confirmation (which asserts the
      five rendered copies moved with the canonical source).
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
