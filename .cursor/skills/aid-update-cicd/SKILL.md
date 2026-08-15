---
name: aid-update-cicd
description: >
  Revise the project's shipping (C8) Knowledge Base document -- pipeline stages and their
  order, triggers, environments and promotion, and the release flow -- plus any previously
  created outputs you name. Use this skill when the pipeline record already exists and a
  stage, trigger, environment or promotion rule has changed. Requires no design seed: the
  change you state in the run is a sufficient input. Reads and consumes a CI/CD seed when
  one is present in .aid/design/. When the C8 document does not yet exist, routes to
  /aid-create-cicd. To provision or change a resource the pipeline ships to, use
  /aid-create-infra or /aid-update-infra; to change a DATA pipeline rather than a delivery
  one, use /aid-create-data-pipeline or /aid-update-data-pipeline; to ship a built artifact
  now, use /aid-deploy. Produced by the aid-architect agent and independently verified by
  aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, Agent
argument-hint: "<change> -- what to revise in the delivery-pipeline record"
---

# Update CI/CD (revise the C8 document)

Bind **VERB=`update`**, **ARTIFACT=`cicd`** -- the `update` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.cursor/aid/templates/design-lifecycle.md`. This skill binds that contract and restates
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
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry
line on each state.

---

## State: INTAKE

1. **Require a stated change.** Empty argument -> ask one bootstrapping question ("What should
   change in the delivery-pipeline record?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.cursor/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-update-cicd`. `phase` is not driven.
3. **No seed is required.** The change stated in this run is a sufficient input, and this
   skill completes without a seed. **Read and consume one when present** at
   `.aid/design/cicd.md`, carrying its `## Current direction` into the destination and
   deleting it once realized.
4. **Resolve the destination by concern.** This skill binds concern **C8** (shipping &
   operation). Where a seed supplied a `## Destination`, use it; otherwise apply the concern
   rule here -- resolve C8 against `.aid/settings.yml` `knowledge.doc_set`, falling back to the
   C8 row of `.cursor/aid/templates/kb-authoring/domain-doc-matrix.md` -- and **confirm the
   resolution with the user before writing**. Never resolve silently.
5. **Read the whole destination**, and note its `source:` field. Absent destination -> route to
   `/aid-create-cicd` and write nothing.
6. **Ask whether the user also wants production config this run.** Touching a workflow file is
   **opt-in per run and never the default**; the KB record is what this skill revises unless
   the user asks in this run.
7. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** UPDATE.

---

## State: UPDATE

1. **Apply only the change the user named in this run**, to the owned C8 content, per the
   content rules below.
2. **Ask, every run, which derived outputs to update alongside this one.** This step is
   unconditional -- it runs on every invocation, and the answer is **stored nowhere**: no
   frontmatter backlink, no manifest, no registry, and no state carried between runs. The
   question is asked afresh each time.
3. **Write no tracking metadata** into any output this run touches -- no `derived-from`, no
   `source-doc`, no `generated-by`, no `aid-tracked` field, and no skill-attribution line.
4. **`source: generated` refuses.** A registered build script owns that content.

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to UPDATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the revision, say whether a workflow file was
touched and that it was asked for, name every output touched, and assert that a consumed seed
is gone.

**Advance:** DONE.

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
- **Tracking:** write STATE `lifecycle` at every transition.
