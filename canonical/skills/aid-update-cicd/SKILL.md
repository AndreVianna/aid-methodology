---
name: aid-update-cicd
description: >
  Revise the project's shipping (C8) Knowledge Base document -- pipeline stages and their
  order, triggers, environments and promotion, and the release flow -- plus any previously
  created outputs you name. Use this skill when the pipeline record already exists and a
  stage, trigger, environment or promotion rule has changed. Requires no design seed: the
  change you state in the run is a sufficient input. Reads and consumes a CI/CD seed when
  one is present in `.aid/design/`. When the C8 document does not yet exist, routes to
  `/aid-create-cicd`. To provision or change a resource the pipeline ships to, use
  `/aid-create-infra` or `/aid-update-infra`; to change a DATA pipeline rather than a
  delivery one, use `/aid-create-data-pipeline` or `/aid-update-data-pipeline`; to ship a
  built artifact now, use `/aid-deploy`. Produced by the aid-architect agent and
  independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<change> -- what to revise in the delivery-pipeline record"
---

# Update CI/CD (revise the C8 document)

Bind **VERB=`update`**, **ARTIFACT=`cicd`** -- the `update` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.aid/runtime/templates/design-lifecycle.md`. This skill binds that contract and restates
none of its rules.

- **Boundary vs `/aid-create-cicd`:** that skill realizes a seed and owns the creation path;
  this one is the maintenance verb. Where the destination is absent this skill routes there
  rather than standing one up itself.
- **Boundary vs the resource and data-pipeline skills:** `/aid-create-infra` and
  `/aid-update-infra` provision or change a resource; `/aid-create-data-pipeline` and
  `/aid-update-data-pipeline` act on a **data** pipeline; `/aid-deploy` ships a built
  artifact. This one revises the KB's C8 delivery-pipeline record.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> UPDATE -> VERIFY -> PRESENT -> DONE**, as
`design-lifecycle.md § Skill shape` defines it.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

---

## State Detection

Steps move and record by `.aid/runtime/templates/skill-steps.md` (the step entry, the advance words and the
work record); this skill restates none of them.

**Detection shapes the entry step and validates a saved step, and never routes.** A fresh start on a work
runs INTAKE's reads to decide how far the entry step goes. On resume the saved step is checked against what
is on disk, and a mismatch goes to recovery, never to a silent re-route. Which skill and which step a work
continues at come only from its work record.

---

## State: INTAKE

Every question this step asks (the opening, the destination confirmation, the production-config and the derived-outputs question) is asked before the work exists, so each is recorded in a design document, as the gate's "Recording the questions asked before a work exists" says (`.aid/runtime/templates/work-initiation-gate.md`): `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design <file> --category <category> --impact <High|Medium|Low> --context '<the question, as shown>' --suggested '<your recommendation>' --asked-by aid-update-cicd` before it is shown (it prints the question's id), then `--answer --design <file> --id <the printed id> --state Answered|Skipped|Assumed --value '<the reply>'` after the reply. `<file>` is `.aid/design/cicd.md` when that seed exists, otherwise `.aid/design/untitled-<YYYYMMDD-HHMMSS>.md`, stamped at the first question and reused for the whole run. A question recorded in the seed leaves the rest of the seed untouched.

1. **Require a stated change.** Empty argument -> ask one bootstrapping question ("What should
   change in the delivery-pipeline record?") and wait.
2. **No seed is required.** The change stated in this run is a sufficient input, and this
   skill completes without a seed. **Read and consume one when present** at
   `.aid/design/cicd.md`, carrying its `## Current direction` into the destination and
   deleting it once realized.
3. **Resolve the destination by concern.** This skill binds concern **C8** (shipping &
   operation). Where a seed supplied a `## Destination`, use it; otherwise apply the concern
   rule here -- resolve C8 against `.aid/settings.yml` `knowledge.doc_set`, falling back to the
   C8 row of `.aid/runtime/templates/kb-authoring/domain-doc-matrix.md` -- and **confirm the
   resolution with the user before writing**. Never resolve silently.
4. **Read the whole destination**, and note its `source:` field. Absent destination -> allocate nothing and
   write nothing: tell the user to run `/aid-create-cicd`, and end the run.
5. **Ask whether the user also wants production config this run.** Touching a workflow file is
   **opt-in per run and never the default**; the KB record is what this skill revises unless
   the user asks in this run.
6. **Ask, every run, which derived outputs to update alongside this one.** This question is
   unconditional -- it is asked on every invocation, and the answer is **stored nowhere** but this
   run's step detail: no frontmatter backlink, no manifest, no registry, and no state carried
   between runs. The question is asked afresh each time, and UPDATE applies the answer.
7. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).
8. **Allocate** once the destination is present, so a route leaves no work behind. Go through the Work
   Initiation Gate exactly as the contract's Allocation rule requires
   (`.aid/runtime/templates/work-initiation-gate.md` § 3a is the shape), with
   `initiator: aid-update-cicd`, saved step `UPDATE` (INTAKE runs before the record and saves nothing), and `--seed .aid/design/cicd.md` on the gate's `--create` when that seed exists, or `--seed` the untitled design document when INTAKE recorded its questions there instead (the gate adds it to the work's `sources:` and copies its `## Questions` into the work's record). `phase` is not driven.

Every `--step` call after the allocation passes in its `--detail` the change, the destination, whether a workflow file is wanted, the derived
outputs the user named and the complexity tier, so a resume finds them in the record.

**Advance:** CHAIN → [State: UPDATE]; HALT when the destination is absent.

---

## State: UPDATE

**Before the first edit,** copy every file this step will edit or delete (the destination, each output the user
named in INTAKE, a consumed seed and, for a promotion, `tech-debt.md`) into `rollback/` in the work folder, under the same
relative path, so PRESENT can restore them if the user declines. Copy only once: when UPDATE runs
again (after VERIFY or a requested change), a file already under `rollback/` is kept, so a decline restores
the original, not an earlier revision.

1. **Apply only the change the user named in this run**, to the owned C8 content, per the
   content rules below.
2. **Update the derived outputs the user named in INTAKE**, and only those, each by the same rules.
3. **Write no tracking metadata** into any output this run touches -- no `derived-from`, no
   `source-doc`, no `generated-by`, no `aid-tracked` field, and no skill-attribution line.
4. **`source: generated` refuses.** A registered build script owns that content.

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to UPDATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: UPDATE] when it is not clean and fewer than 3 cycles have run; HALT when the circuit-breaker has blocked the work.

---

## State: PRESENT (hard stop -- the user decides)

Present the revision, say whether a workflow file was
touched and that it was asked for, name every output touched, and assert that a consumed seed
is gone.

Then ask the approval question: keep this revision, change it, or decline it. It is an approval under
`.aid/runtime/templates/question-protocol.md`: record it with `--ask` (category `Approval`, `covers` the revision), set
`lifecycle` to `Paused-Awaiting-Input` and the pause reason through the writer, and ask. The question pauses this step
where it stands and cannot be skipped. Once it is answered, record the answer with `--answer` and set `lifecycle` back to
`Running` through the writer (`skill-steps.md` part 3). Then:

- **Approve:** the revision stays as written.
- **Change:** the changes the user asks for go into the step detail, and UPDATE applies them; the verify runs again.
- **Decline:** copy every file saved under `rollback/` back to its place (a consumed seed included), so the Knowledge
  Base is as it was before this run and nothing lands.

**Advance:** CHAIN → [State: DONE] when the user approves; CHAIN → [State: DONE] when the user declines (the revision is rolled back first); CHAIN → [State: UPDATE] when the user asks for changes.

---

## State: DONE

Set `lifecycle` to `Completed` through the writer (`--pipeline --field Lifecycle --value Completed`), which also clears the saved skill and step.

**Advance:** HALT.

---

## Owned region

The C8 document's pipeline sections -- `## Deployment Pipeline` / `## CI/CD Pipeline` and
`## Environments` -- plus whatever else a consumed seed's `## Destination` named within that
document.

## What this skill writes -- and must not

**Writes (C8):** the stages and their order; the triggers; the environments and promotion
between them; the release flow; and **that** a stage runs a gate.

**Must not write** -- each is the non-owning half of a boundary, and neither side restates the
other's half:

- **Which test suites run.** Concern C6: the testing-strategy skills own the test-lane mapping.
- **Any threshold, verdict or waiver rule.** That policy lives in the C6 gate document. This
  skill names the stage, its order, its trigger, and **that** it runs the gate -- and **cites**
  the gate document instead of restating its policy.
- **Build-tool versions.** Concern C0: the stack skills own the build tool and its version;
  this skill owns the pipeline stage that invokes it.

## Frontmatter invariants

- The destination's `source:` is left **unchanged**, whatever it was -- neither verb rewrites
  it.
- `source: generated` **refuses**.
- `approved_at_commit:` is **never** written and never restamped -- it is generator-written by
  `/aid-discover` and `/aid-update-kb` on approval, and this skill is neither.
- `sources:` gains only what this run actually used.

## Write discipline

Read the destination whole, edit in place, and write back with everything outside the edited
range **byte-identical**. Never regenerate and never restructure the document. Adding a
`## ` section obliges updating that document's `## Contents` list in the **same** write.

## Conformance Lane

This skill changes **only what the user named in that run**. It does **not** resolve a flagged
Conformance-Lane divergence on its own -- reconciliation there is human by the lane's design --
so a flag the user did not point at survives this run untouched.

## Constraints

- **`phase` is not driven** by this skill.
- **Full verify**, per `design-lifecycle.md`.
- **No seed required; a present seed is consumed.**
- **Never stands up its destination** -- that path belongs to `/aid-create-cicd`.
- **Clean context**; verification always an `aid-reviewer` sub-agent dispatch.
- **Tracking:** set the lifecycle through the writer (`--pipeline --field Lifecycle`) at every transition.
