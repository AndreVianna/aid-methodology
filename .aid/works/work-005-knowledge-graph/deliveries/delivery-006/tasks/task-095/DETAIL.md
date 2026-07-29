# task-095: Deferred Knowledge Base drafts landed

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

**Source:** work-005-knowledge-graph -> delivery-006

**Depends on:** task-094

**Scope:**
- Land the Knowledge Base entries that other features drafted in delivery-001 and deliberately
  deferred to ship time. Each of the three is conditional on a decision already recorded there --
  read the decision records first, and **record the not-applicable outcome explicitly** where a
  condition does not hold rather than silently omitting the edit.
- **`.aid/knowledge/artifact-schemas.md`** -- unconditional within this task: add
  `relationships.md` and the relation-vocabulary contract, following that document's **own
  convention for adding an artifact type** (required fields, closed enums, producer, consumers,
  validation points). Drafted by feature-001 in delivery-001.
- **`.aid/knowledge/domain-glossary.md`** -- an entry **only if** delivery-001's vocabulary
  research coined a Concept Spine term. Relation names themselves are data values, not spine
  concepts, so the expected outcome is no entry at all.
- **`.aid/knowledge/technology-stack.md` and `.aid/knowledge/infrastructure.md`** -- the rows
  feature-002 drafted and task-083's G6 handed over, **only if** a third-party approach or a build
  step was actually adopted. `technology-stack.md` gains rows in "Frameworks & Tooling" and "Key
  Dependencies"; `infrastructure.md` gains the build step in its render/build chain. If neither
  was adopted, neither document is edited.
- Nothing mechanical guards these documents either: `tests/canonical/test-doc-counts.sh` excludes
  `.aid/knowledge/` by its own scoping.
- **Out of scope:** the four unconditional ship-time updates (task-094); drafting any of this
  content, which happened in delivery-001 and, for the packaging rows, in task-083; and
  `.aid/knowledge/kb.html`, which is generated.

**Acceptance Criteria:**
- [ ] Accuracy verified against the current codebase and against the delivery-001 decision records
      each entry derives from.
- [ ] `artifact-schemas.md` gains `relationships.md` and the relation-vocabulary contract,
      following that document's own convention for adding an artifact type.
- [ ] `domain-glossary.md` gains an entry **if and only if** the vocabulary research coined a
      Concept Spine term; if it did not, the not-applicable outcome is recorded and the document
      is untouched.
- [ ] `technology-stack.md` and `infrastructure.md` gain feature-002's drafted entries **if and
      only if** a third-party approach or a build step was adopted; if neither was, the
      not-applicable outcome is recorded and neither document is edited.
- [ ] Where task-083 fired, the entries landed here match the rows it drafted, with no new
      decision introduced at this point.
- [ ] Every edited Knowledge Base document still passes
      `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and carries its changelog entry per
      `.aid/knowledge/authoring-conventions.md`.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
