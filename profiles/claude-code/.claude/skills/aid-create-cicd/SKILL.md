---
name: aid-create-cicd
description: >
  Realize a ready CI/CD seed from .aid/design/cicd.md into the project's shipping (C8)
  Knowledge Base document -- the pipeline stages and their order, the triggers, the
  environments and promotion between them, and the release flow. Use this skill when a CI/CD
  seed is ready and the project has no record of its delivery pipeline yet. It writes the KB
  record by default, and emits a workflow file only if you ask for one in that run. Creating
  the document also registers it, in the same run, which opts it into the Conformance Lane
  permanently -- a choice you make by running this skill. To revise C8 content already
  committed use /aid-update-cicd; for a resource the pipeline ships to, /aid-create-infra or
  /aid-update-infra; for a data pipeline rather than a delivery one,
  /aid-create-data-pipeline or /aid-update-data-pipeline; to ship a built artifact now,
  /aid-deploy.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[<direction>] -- which parts of the CI/CD seed to realize"
---

# Create CI/CD (realize a seed into the C8 document)

Bind **VERB=`create`**, **ARTIFACT=`cicd`** -- the `create` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.claude/aid/templates/design-lifecycle.md`. This skill binds that contract and restates
none of its rules. It consumes the seed `/aid-design-cicd` produces and touches
`.aid/design/` for no other purpose.

- **Boundary vs `/aid-update-cicd`:** that skill revises C8 content this lifecycle already
  committed; this one realizes a seed.
- **Boundary vs the resource and data-pipeline skills:** `/aid-create-infra` and
  `/aid-update-infra` provision or change a resource; `/aid-create-data-pipeline` and
  `/aid-update-data-pipeline` build a **data** pipeline; `/aid-deploy` ships a built
  artifact. This one writes the KB's C8 delivery-pipeline record.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> CREATE -> VERIFY -> PRESENT -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry
line on each state.

---

## State: INTAKE

1. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.claude/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-create-cicd`. `phase` is not driven.
2. **Read the seed** at `.aid/design/cicd.md`.
3. **Resolve the destination by concern, not filename.** This skill binds concern **C8**
   (shipping & operation, `.claude/aid/templates/kb-authoring/concern-model.md`). The seed's
   `## Destination` names the resolved path; where it does not, resolve C8 against
   `.aid/settings.yml` `knowledge.doc_set`, falling back to the C8 row of
   `.claude/aid/templates/kb-authoring/domain-doc-matrix.md`, and confirm with the user. An
   ambiguous realization is **asked**, never picked silently.
4. **Read the whole destination** if it exists, and note its `source:` field.
5. **Ask whether the user also wants production config this run.** Emitting a workflow file
   is **opt-in per run and never the default**; the KB record is what this skill writes
   unless the user asks in this run.
6. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** CREATE.

---

## State: CREATE

**Exactly three conditions refuse. There is no fourth.**

1. **No seed** at `.aid/design/cicd.md` -> refuse, name `/aid-design-cicd` as the skill that
   produces one, and write nothing.
2. **The seed's `## Open questions` still carries unresolved questions** by the detection
   rule in `design-lifecycle.md`, and no `--override-open-questions` was supplied -> refuse,
   naming each unresolved question and that override token. Leave the seed byte-identical.
3. **The destination's frontmatter says `source: generated`** -> refuse: a registered build
   script owns that content, so this skill must not write it.

Otherwise it **realizes**. Whatever the destination already holds is never itself a reason
to refuse -- an as-built C8 document is the normal case this skill is for.

**The realization event.** Merge the settled seed content into the destination per the
content rules below, emit a workflow file only if the user asked for one in this run, then
**delete the seed**. Situations resolve as:

- Destination absent, this skill owning the whole document -> create it, then register it
  (see *Registration* below). This arises on a `methodology-tooling` project.
- Destination present, the owned content absent -> add it. This is the dominant path.
- Destination present, carrying content **an earlier `create` for this artifact committed**
  -> that part routes to `/aid-update-cicd` rather than being overwritten. "Committed
  content" means content an earlier run of this lifecycle wrote, at the granularity of the
  sections the seed's `## Destination` names -- **not** the as-built content
  `/aid-discover` wrote.

**A repeat `create` never halts with nothing done.** Every part of the seed that is new is
written; each part that would overwrite previously committed content is **named and routed**
to `/aid-update-cicd`. The seed is deleted only when everything its `## Destination` named
was written; otherwise it stays in place carrying just the unrealized parts, which
`/aid-update-cicd` then consumes.

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to CREATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the realized document and assert: whether a
workflow file was emitted and that it was asked for; on the creation path both registration
surfaces were written; and anything routed to `/aid-update-cicd` is named.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.

---

## Owned region

The C8 document's pipeline sections -- `## Deployment Pipeline` / `## CI/CD Pipeline` and
`## Environments` -- plus whatever else the seed's `## Destination` names within that
document.

## What this skill writes -- and must not

**Writes (C8):** the stages and their order; the triggers; the environments and promotion
between them; the release flow; and **that** a stage runs a gate.

**Must not write** -- each of these is the non-owning half of a boundary, and neither side
restates the other's half:

- **Which test suites run.** Concern C6: `/aid-create-testing-strategy` and
  `/aid-update-testing-strategy` own the test-lane mapping.
- **What blocks a merge, any threshold, or any waiver rule.** That policy lives in the C6
  gate document. This skill names the stage, its order, its trigger, and **that** it runs the
  gate -- and **cites** the gate document instead of restating its policy.
- **Build-tool versions.** Concern C0: `/aid-create-stack` and `/aid-update-stack` own the
  build tool and its version; this skill owns the pipeline stage that invokes it.

## Production config is opt-in

`design` never touches `.github/` or any workflow file. This `create` writes the Knowledge
Base record by default, and may additionally emit a workflow file **only** when the user asks
for it in that run. A user who wants a provisioned resource is routed to `/aid-create-infra`.

## Registration (same run as creation)

When this skill creates the document it registers it **in the same run**, never later and
never by another skill:

1. Append exactly one `.aid/settings.yml` `knowledge.doc_set` entry
   `<file>|<owner>|required` -- presence `required`, and `<owner>` taken from the document's
   **matrix row** slot, never a blanket `skill-self`.
2. Append one `.aid/knowledge/README.md` Completeness row and increment that file's
   `**Doc-set:** N documents` line.

Both use the R13 append-block idiom -- one entry appended, never a rewrite of the block, and
`term_exclusions` is never touched. Both must succeed in the same run; if either fails,
report and halt.

## Frontmatter invariants

- A document **this skill creates** gets `source: forward-authored` and `sources: []`.
- A document that **already existed** keeps whatever `source:` value it had, **unchanged**.
- `source: generated` **refuses** (CREATE condition 3).
- `approved_at_commit:` is **never** written and never restamped -- it is generator-written
  by `/aid-discover` and `/aid-update-kb` on approval, and this skill is neither.
- `sources:` gains only what this run actually used.

## Write discipline

Read the destination whole, edit in place, and write back with everything outside the edited
range **byte-identical**. Never regenerate and never restructure the document. Adding a
`## ` section obliges updating that document's `## Contents` list in the **same** write.

## Constraints

- **`phase` is not driven** by this skill.
- **Full verify**, per `design-lifecycle.md`.
- **Seed consumed on the realizing path**, and left in place for the parts that routed.
- **Clean context**; verification always an `aid-reviewer` sub-agent dispatch.
- **Tracking:** write STATE `lifecycle` at every transition.
