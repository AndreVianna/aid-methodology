# task-094: Ship-time Knowledge Base updates

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

**Depends on:** task-091, task-093

**Scope:**
- Land feature-013 § D3's four unconditional ship-time Knowledge Base updates, now that the
  artifacts they describe exist.
- **`.aid/knowledge/capability-inventory.md`** -- one capability entry for `/aid-graph`, in the
  shape its neighbouring entries use.
- **`.aid/knowledge/module-map.md` -- two rows in "Script Modules by Area", not one.** The new
  `graph/` area, **and** the pre-existing missing `works` row: the table lists eight areas while
  `canonical/aid/scripts/` holds nine on disk, so `graph` makes ten. **Correcting the omission in
  the same edit is deliberate and in scope, not scope creep** -- the document is being updated
  anyway and the gap was found during specification (feature-012 § U6, carried to feature-013
  § D3). Also update the `canonical/skills/*` count and add a `canonical/skills/aid-graph/`
  mention.
- **`.aid/knowledge/release-tracking.md`** -- an `## Unreleased` `[NEW]` item recording the
  addition.
- **`.aid/knowledge/test-landscape.md`** -- the canonical-suite count stated as the **live** figure
  at ship time (`ls tests/canonical/test-*.sh | wc -l`; it read 133 before this work), plus a row
  for the graph suites. It is derived, so it is read off disk rather than predicted.
- **Nothing mechanical will catch a missed row here.** `tests/canonical/test-doc-counts.sh` scopes
  itself to "the public-facing docs a reader trusts (README + docs/ + profile READMEs)" and
  deliberately excludes `.aid/knowledge/`, which "carries heavy version-history sections and is
  reconciled by `/aid-housekeep`". That is why these updates are a named acceptance criterion
  rather than a step in a list.
- **Out of scope:** the conditional deferred drafts -- `artifact-schemas.md`, `domain-glossary.md`,
  `technology-stack.md` and `infrastructure.md` -- which land in task-095; `.aid/knowledge/kb.html`
  (generated and hand-edit-forbidden; corrected by a `/aid-housekeep` SUMMARY-DELTA regeneration);
  and the `docs/` and `README.md` roster entries (task-090).

**Acceptance Criteria:**
- [ ] Accuracy verified against the current codebase: every figure is derived on disk at ship time
      rather than carried forward from a specification.
- [ ] `capability-inventory.md` carries exactly one `/aid-graph` capability entry, matching the
      shape of its neighbours.
- [ ] `module-map.md` "Script Modules by Area" gains **both** a `graph/` row and the missing
      `works` row, taking the table to ten areas, and both follow the table's existing
      Area / Scripts / Consumed by / Purpose shape.
- [ ] `module-map.md`'s `canonical/skills/*` count states the live derived figure, and a
      `canonical/skills/aid-graph/` mention is present.
- [ ] `release-tracking.md` has an `## Unreleased` `[NEW]` item for the addition.
- [ ] `test-landscape.md` states the live canonical-suite count and carries a row for the graph
      suites.
- [ ] Every edited Knowledge Base document still passes
      `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and carries its changelog entry per
      `.aid/knowledge/authoring-conventions.md`.
- [ ] No count needle guarded by `tests/canonical/test-doc-counts.sh` is touched, and that suite
      still passes.
- [ ] `.aid/knowledge/kb.html` is not hand-edited.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
