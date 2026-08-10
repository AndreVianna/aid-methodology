# task-006: KB doctrine amendment admitting project-level governance documents

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-005

**Scope:**
- Source spec: `features/feature-001-kb-doc-set-restructure/SPEC.md` §2a, §2b (AC-1);
  its §6 step 1, which must land **before** the documents are reviewed and before
  registration surface 2 can name them as conditional.
- Ordered after task-005 so that feature-002's commit range -- the range BLUEPRINT gate
  criterion 2 evaluates over -- has closed before any feature-001 edit lands under
  `canonical/`. This is a sequencing constraint of the gate, not a content dependency:
  feature-001 § *Dependencies* states it is *"independent of feature-002"*.
- **§2a, in `canonical/aid/templates/kb-authoring/concern-model.md`** § "Why
  product-concerns, not governance-artifacts": keep the rule, add the distinguishing test it
  lacks -- **scope**, not genre. Per-work governance (a sprint backlog, a work plan, a task
  register) stays banned and maps to `REQUIREMENTS.md` / `SPEC.md` / `PLAN.md` / the per-work
  `STATE.md`. Project-level governance (the roadmap, the backlog, the release ledger) is
  admissible **as a conditional document**, because the pipeline artifacts it would otherwise
  route to are per-work and transient -- pruned when the work ships -- leaving no durable
  home.
- The rationale is **edited, not appended to**: the clause *"which already exist"* is the
  premise the amendment overturns and is **replaced**, not qualified. That is what makes
  AC-1's oracle a zero-count on that exact string rather than a presence check.
- **§2b, in the same file**: the shipped model admits a conditional doc *"via the
  propose->confirm gate"* at discovery. Amend it to admit **skill-created** conditional
  documents (`skill-self` as declared owner) alongside discovery-proposed ones, written as a
  general rule rather than as named exceptions -- otherwise the mechanism FR-9 specifies has
  no home in the model it cites.
- **`.aid/knowledge/authoring-conventions.md` § Concern Model**: restate the amended
  doctrine for this repository's own KB. Its current text carries only the one-sentence
  unqualified ban and no *"which already exist"* premise, so `concern-model.md`'s oracle does
  not transfer and this carrier is checked separately. Reach is **dogfood only** -- it
  carries no adopter-facing obligation.
- Out of scope: naming the three documents as conditional (registration surface 2, task-007
  -- feature-001 §6 orders doctrine before registration); the pre-existing 15-vs-14 seed
  drift between `concern-model.md` and the matrix, routed to `/aid-housekeep` (§2c);
  `.aid/settings.yml` and `.aid/knowledge/README.md` counts, which are effects of running a
  `create` skill (REQUIREMENTS CC-2).

**Acceptance Criteria:**
- [ ] AC-1 oracle A, **section-scoped** to § "Why product-concerns" via the `awk` extractor
      the SPEC prints: `grep -c 'which already exist'` -> `0` (it is `1` today);
      `grep -c 'project-level'` -> `>= 1` (it is `0` in-section today, and `2` file-wide, so
      an unscoped grep would be vacuously true); and file-wide
      `grep -c 'skill-created' canonical/aid/templates/kb-authoring/concern-model.md` ->
      `>= 1` (`0` today)
- [ ] AC-1 oracle B: `grep -n 'governance artifact' .aid/knowledge/authoring-conventions.md`
      returns a sentence that names the per-work / project-level split, and
      `grep -c 'project-level' .aid/knowledge/authoring-conventions.md` -> `>= 1` (`0` today)
- [ ] The transient-pipeline-artifact reasoning appears **in place of** the premise it
      overturns, not beside it -- the zero-count above is the check that distinguishes the two
- [ ] None of the nine "15 docs" seed statements in `concern-model.md` is touched: the
      pre-existing drift stays routed to `/aid-housekeep` and AC-3 stays satisfiable
- [ ] `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` is clean (AC-3;
      the full six-oracle re-run is task-020)
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
