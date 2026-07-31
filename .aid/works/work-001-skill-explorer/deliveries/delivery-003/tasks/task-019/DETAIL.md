# task-019: The five cross-feature seam reconciliations

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-019. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-019/STATE.md.
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

**Type:** DESIGN

**Source:** work-001-skill-explorer -> delivery-003 (feature-003-authored-flow-charts)

**Depends on:** task-018

**Scope:**
- Decide and record, as one-line contract statements, the **five** seams listed in delivery-003's BLUEPRINT Notes. Four of them are open decisions; the fifth is already answered and needs only its delta written down. Collectively they mean this delivery **reopens contract text delivery-002 froze**, which feature-001 anticipates by framing the harness as "a published interface those SPECs are written against; changing it is a cross-feature change, not a local one."
- **Seam 1 -- S3, sidecars in the manifest and drift guard.** feature-003 requires that both a page and its `<skill>.flow.json` sidecar be recorded in feature-001's manifest so AC-1's guard covers sidecars too; feature-001's manifest records pages only, its guard compares `*.md` under `src/content/docs/skills/`, and its exhaustive touch list says "nothing else". Decide whether the guard extends to sidecars, and state the effect on AC-1's error message. Implemented by task-030.
- **Seam 2 -- the fourth manifest key.** feature-003 writes `shapeCounts` into a manifest feature-001 specifies as "the same three-key shape" as `.reference-manifest.json`. Not a behavioural conflict -- feature-001's assertions still pass -- but the contract text needs one line. Implemented by task-030.
- **Seam 3 -- the body-slot heading.** feature-004 fixes it to `## Flow`; feature-003 only requires "an H2". Pick one and state it once. Consumed by task-029 and task-037, which must emit the identical string.
- **Seam 4 -- `delegatesTo`.** feature-003's discriminator D3 says the classifier captures it, while its published signature returns `{shape, evidence}`. feature-004 has a fallback in `resolveSiblingParent()`, so only duplicated work is at stake -- but the signature should say what it returns. Implemented by task-021.
- **Seam 5 -- where validator rule V9 is enforced. ALREADY DECIDED; this task RECORDS THE DELTA, it does not decide.** Owner-answered as work `STATE.md` **Q3** and carried in delivery-003's BLUEPRINT as seam 5: **V9 is enforced at extraction, in `advance.mjs`, where the residue still exists; `validate.mjs` implements V1–V8 and documents that V9 lives in the parser.** The rejected alternative was a residue carrier on the model, which would flow into the `<skill>.flow.json` sidecar and then need explicit exclusion from feature-006's browser projection -- three contracts widened to serve one rule. This task's job is to write the delta against the SPEC text that now contradicts it. Implemented by task-023 (enforcement) and task-024 (V1–V8 plus the documenting comment).
- Record all five in `deliveries/delivery-003/STATE.md`, not only in a task file. **No code is written by this task.**

**Acceptance Criteria:**
- [ ] All **five** seams carry a written decision with a one-line rationale; none is deferred to "whichever feature is implemented second", and none is left for an implementer to discover.
- [ ] Each decision names the task that implements it -- seam 1 and seam 2 to task-030, seam 3 to task-029 and task-037, seam 4 to task-021, seam 5 to task-023 and task-024 -- and states the consequence for feature-001's existing assertions.
- [ ] Seam 1's record states whether the drift guard's `*.md` comparison gains a parallel sidecar comparison or the sidecars stay outside it, **and** what AC-1's error message says in the chosen case.
- [ ] Seam 5's record is written as a **delta against the SPEC text that is now wrong**, not as a fresh decision, and cites work `STATE.md` Q3 as its authority.
- [ ] **The record explicitly notes that feature-003's SPEC is now incorrect where it states `validateChart` implements V1–V9** -- specifically its § Contract -- the well-formedness validator V-table, whose V9 row and closing paragraph both place V9 inside `validateChart`, and its § Layers & Components module table row for `validate.mjs`.
- [ ] The record also names the **other** documents carrying the same now-stale claim, so the correction is scoped as a class rather than one instance: feature-004's § Validator conformance (AC-3) V-table row for V9 and its "feature-003's `validateChart` is used **unchanged**" sentence; feature-005's citation of "the paragraph closing the V1–V9 table"; and `known-issues.md` KI-008's closing line "the only contract movement is `validateChart` gaining V9".
- [ ] Each decision is stated as a delta against the specific SPEC section it changes, so a reader can see exactly what moved and where.
- [ ] The record confirms that delivery-003's BLUEPRINT **already reflects all five seams** -- its Gate Criteria and its Scope both say five, and a gate criterion now states the V1–V8 / V9 module split explicitly -- so no BLUEPRINT correction is owed by this task. The outstanding correction is to **feature-003's SPEC text**, which still says `validateChart` implements V1–V9 and is wrong on that point.
- [ ] All five decisions are written into `deliveries/delivery-003/STATE.md`.
- [ ] No file under `site/` or `canonical/` is modified by this task, and no SPEC or BLUEPRINT is edited.
- [ ] All section-6 quality gates pass
