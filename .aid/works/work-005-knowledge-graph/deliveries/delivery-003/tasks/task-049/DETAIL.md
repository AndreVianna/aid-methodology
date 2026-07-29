# task-049: Drafted ledger-retention carve-out and the Q8 external-dependency record

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

**Type:** DOCUMENT

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** task-048

**Scope:**
- Write one document at
  `.aid/works/work-005-knowledge-graph/deliveries/delivery-003/q8-ledger-retention-carve-out.md`
  carrying two halves: **(a)** the drafted carve-out text, and **(b)** the FR-26 not-closed record.
- **(a) The drafted carve-out.** The exact proposed text for
  `canonical/aid/templates/reviewer-ledger-schema.md`'s `## Lifecycle (per skill invocation)`
  section: a **named** retention exception covering `.aid/.temp/review-pending/graph-kb-gaps.md`,
  worded so a future orchestrator reading the schema does not delete it. Its lifecycle is written at
  GAP-REPORT, retained past DONE, and replaced wholesale by the next `/aid-graph` run (which reads
  the previous file first to compute the `Fixed` / `Recurred` transitions); it is removed by whoever
  consumes it. The draft also enumerates the consequential edits the carve-out implies elsewhere in
  the same file, so a future implementer does not land a carve-out the rest of the document
  contradicts: the `contracts:` frontmatter line "Persists across REVIEW->FIX cycles within one skill
  invocation; deleted at skill DONE"; the `DONE` branch of the lifecycle diagram; the `## Authoring
  rules for the orchestrator` "At skill DONE: delete the ledger file" and "Never carry a ledger past
  skill DONE" lines; and the workflow step "Skill reaches DONE: orchestrator deletes the ledger file".
- **(b) The record.** State what delivery-003 **does** land -- the file-separation half of
  feature-006 D7 (`graph.md` graded and deleted at DONE; `graph-kb-gaps.md` never graded and
  retained), plus task-048's two additive scope rows. State what **remains** -- the shared-schema
  carve-out. State **why it is out of scope** -- a methodology-level change beyond work-005, cited to
  STATE.md Q8 and PLAN.md cross-cutting risk 1, better raised as its own work than absorbed here.
  State the **gate consequence** -- delivery-003's gate records Q8 as an **accepted external
  dependency** and must **not** record FR-26 as closed.
- **This task lands nothing in `canonical/aid/templates/reviewer-ledger-schema.md`.** It drafts and
  records only. The two additive scope rows are task-048's and are already in. Amending the shared
  Lifecycle section here would change ledger behaviour for every skill that reads the schema, which
  is exactly the boundary task-048 and this task exist to keep.
- Out of scope: landing the carve-out (a separate work, outside work-005); the two scope rows and the
  `kb_gaps:` field (task-048); the detector's retention behaviour, which is already structural via
  file separation (tasks 046 and 047).

**Acceptance Criteria:**
- [ ] The document exists at
      `.aid/works/work-005-knowledge-graph/deliveries/delivery-003/q8-ledger-retention-carve-out.md`
      and carries both halves -- the drafted carve-out text and the FR-26 not-closed record.
- [ ] The carve-out text is quotable and pasteable: it names the exact target section
      (`## Lifecycle (per skill invocation)`), quotes the current `DONE` branch it modifies, and
      names the retained path `.aid/.temp/review-pending/graph-kb-gaps.md` **literally**, rather than
      by a class an orchestrator would have to infer.
- [ ] The carve-out states the full lifecycle it grants: written at GAP-REPORT, retained past DONE,
      replaced wholesale by the next run, removed by whoever consumes it.
- [ ] Every consequential edit is enumerated -- the `contracts:` frontmatter line, the lifecycle
      diagram's `DONE` branch, the workflow's step 5, and both orchestrator authoring-rule lines --
      each quoted as it currently reads.
- [ ] `git diff -- canonical/aid/templates/reviewer-ledger-schema.md` is **empty** for this task:
      nothing lands in the shared schema, and no other file under `canonical/` is touched.
- [ ] The record states, separately and unambiguously, what delivery-003 lands, what remains, why it
      is out of scope, and that FR-26 does not close here.
- [ ] The record cites STATE.md **Q8** and PLAN.md cross-cutting risk **1** by name.
- [ ] The record names the gate consequence explicitly: delivery-003's gate records Q8 as an accepted
      external dependency and must not mark FR-26 closed.
- [ ] **Accuracy verified against the current codebase (DOCUMENT default):** every line quoted from
      `reviewer-ledger-schema.md` is checked to read exactly that way on disk **after task-048**, and
      every path named is checked to exist.
- [ ] The document matches the project's existing documentation style (DOCUMENT default) and, being
      a decision record, follows the Context -> Decision -> Consequences shape.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
