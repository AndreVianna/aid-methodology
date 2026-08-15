---
name: aid-create-architecture
description: >
  Realize a ready architecture seed from .aid/design/architecture.md into the project's
  build-and-shape (C1) Knowledge Base document -- components and their responsibilities,
  boundaries, interactions, and the invariants a change must not break. Use this skill when
  an architecture seed is ready and the project has no architecture document yet. When it
  creates the document it also registers it in .aid/settings.yml and
  .aid/knowledge/README.md in the same run, which opts that document into the Conformance
  Lane permanently -- a choice you are making by running this skill. To revise C1 content
  this lifecycle already committed, use /aid-update-architecture; to write documentation
  ABOUT an architecture rather than realize a design seed, use /aid-document-architecture.
  Produced by the aid-architect agent and independently verified by aid-reviewer (full
  verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[<direction>] -- which parts of the architecture seed to realize"
---

# Create Architecture (realize a seed into the C1 document)

Bind **VERB=`create`**, **ARTIFACT=`architecture`** -- the `create` *stage* in the
contract's vocabulary -- then follow the shared contract at
`.agent/aid/templates/design-lifecycle.md`. This skill binds that contract and restates
none of its rules. It consumes the seed `/aid-design-architecture` produces and touches
`.aid/design/` for no other purpose.

- **Boundary vs `/aid-update-architecture`:** that skill revises C1 content this lifecycle
  already committed; this one realizes a seed.
- **Boundary vs `/aid-document-architecture`:** that skill writes documentation *about* an
  architecture (`aid-tech-writer`); this one realizes a design seed into the Knowledge Base.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> CREATE -> VERIFY -> PRESENT -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry
line on each state.

---

## State: INTAKE

1. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agent/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-create-architecture`. `phase` is not driven.
2. **Read the seed** at `.aid/design/architecture.md`.
3. **Resolve the destination by concern, not filename.** This skill binds concern **C1**
   (build & shape, `.agent/aid/templates/kb-authoring/concern-model.md`). The seed's
   `## Destination` names the resolved path; where it does not, resolve C1 against
   `.aid/settings.yml` `knowledge.doc_set`, falling back to the C1 row of
   `.agent/aid/templates/kb-authoring/domain-doc-matrix.md`, and confirm with the user.
   C1's default set holds both `project-structure.md` and `architecture.md`; this skill
   targets the document describing the system's shape and **never**
   `project-structure.md`. An ambiguous realization is **asked**, never picked silently.
4. **Read the whole destination** if it exists, and note its `source:` field.
5. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** CREATE.

---

## State: CREATE

**Exactly three conditions refuse. There is no fourth.**

1. **No seed** at `.aid/design/architecture.md` -> refuse, name `/aid-design-architecture`
   as the skill that produces one, and write nothing.
2. **The seed's `## Open questions` still carries unresolved questions** by the detection
   rule in `design-lifecycle.md`, and no `--override-open-questions` was supplied -> refuse,
   naming each unresolved question and that override token. Leave the seed byte-identical.
3. **The destination's frontmatter says `source: generated`** -> refuse: a registered build
   script owns that content, so this skill must not write it.

Otherwise it **realizes**. Whatever the destination already holds is never itself a reason
to refuse -- an as-built C1 document is the normal case this skill is for.

**The realization event.** Merge the settled seed content into the destination per the
content rules below, offer any additional output the user asks for, then **delete the seed**.
Four situations resolve as:

- Destination absent, this skill owning the whole document -> create it, then register it
  (see *Registration* below).
- Destination present, the owned content absent -> add it. This is the dominant path.
- Destination present, carrying content **an earlier `create` for this artifact committed**
  -> that part routes to `/aid-update-architecture` rather than being overwritten.
  "Committed content" means content an earlier run of this lifecycle wrote, at the
  granularity of the sections the seed's `## Destination` names -- **not** the as-built
  content `/aid-discover` wrote.

**A repeat `create` never halts with nothing done.** Every part of the seed that is new is
written; each part that would overwrite previously committed content is **named and routed**
to `/aid-update-architecture`. The seed is deleted only when everything its `## Destination`
named was written; otherwise it stays in place carrying just the unrealized parts, which
`/aid-update-architecture` then consumes.

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to CREATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the realized document and assert: the seed
was consumed only for what was written; on the creation path both registration surfaces were
written; and anything routed to `/aid-update-architecture` is named.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.

---

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

## What this skill writes -- and must not

**Writes (C1):** components and their responsibilities; boundaries and what crosses them;
interactions and data flow; the invariants a change must not break; and what is deliberately
*not* a component. Into an existing section wherever one fits; a new `## ` section only when
the seed's content maps to none.

**Must not write:**

- **Framework or runtime versions** -- concern C0, `/aid-create-stack`'s.
- **Pipeline stages or environments** -- concern C8, `/aid-create-cicd`'s.
- **Rejected alternatives** -- concern D. They go to the project's D document
  (`decisions.md` by default, owner `aid-researcher-architecture`), never into the C1 doc.

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

## Constraints

- **`phase` is not driven** by this skill.
- **Full verify**, per `design-lifecycle.md`.
- **Seed consumed on the realizing path**, and left in place for the parts that routed.
- **Clean context**; verification always an `aid-reviewer` sub-agent dispatch.
- **Tracking:** write STATE `lifecycle` at every transition.
