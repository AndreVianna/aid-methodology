---
name: aid-create-stack
description: >
  Realize a ready stack seed from .aid/design/stack.md into the project's technology (C0)
  Knowledge Base document -- languages, runtimes, frameworks, package managers, and build
  and test tooling, each with its version. Use this skill when a stack seed is ready and the
  project has no technology-stack document yet. When it creates the document it also
  registers it in .aid/settings.yml and .aid/knowledge/README.md in the same run, which opts
  that document into the Conformance Lane permanently -- a choice you are making by running
  this skill. To revise C0 content this lifecycle already committed, use /aid-update-stack;
  to create or revise a configuration option within a chosen stack rather than the stack
  itself, use /aid-create-config or /aid-update-config. Produced by the aid-architect agent
  and independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[<direction>] -- which parts of the stack seed to realize"
---

# Create Stack (realize a seed into the C0 document)

Bind **VERB=`create`**, **ARTIFACT=`stack`** -- the `create` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.agent/aid/templates/design-lifecycle.md`. This skill binds that contract and restates
none of its rules. It consumes the seed `/aid-design-stack` produces and touches
`.aid/design/` for no other purpose.

- **Boundary vs `/aid-update-stack`:** that skill revises C0 content this lifecycle already
  committed; this one realizes a seed.
- **Boundary vs `/aid-create-config` and `/aid-update-config`:** those act on a configuration
  option *within* a chosen stack; this one records the stack choice itself.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> CREATE -> VERIFY -> PRESENT -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry
line on each state.

---

## State: INTAKE

1. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agent/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-create-stack`. `phase` is not driven.
2. **Read the seed** at `.aid/design/stack.md`.
3. **Resolve the destination by concern, not filename.** This skill binds concern **C0**
   (technology, `.agent/aid/templates/kb-authoring/concern-model.md`). The seed's
   `## Destination` names the resolved path; where it does not, resolve C0 against
   `.aid/settings.yml` `knowledge.doc_set`, falling back to the C0 row of
   `.agent/aid/templates/kb-authoring/domain-doc-matrix.md`, and confirm with the user.
   An ambiguous realization is **asked**, never picked silently. The seed also names a
   **second** destination -- the project's D document, for the rejected alternatives.
4. **Read the whole destination** if it exists, and note its `source:` field.
5. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** CREATE.

---

## State: CREATE

**Exactly three conditions refuse. There is no fourth.**

1. **No seed** at `.aid/design/stack.md` -> refuse, name `/aid-design-stack` as the skill
   that produces one, and write nothing.
2. **The seed's `## Open questions` still carries unresolved questions** by the detection
   rule in `design-lifecycle.md`, and no `--override-open-questions` was supplied -> refuse,
   naming each unresolved question and that override token. Leave the seed byte-identical.
3. **The destination's frontmatter says `source: generated`** -> refuse: a registered build
   script owns that content, so this skill must not write it.

Otherwise it **realizes**. Whatever the destination already holds is never itself a reason
to refuse -- an as-built C0 document is the normal case this skill is for.

**The realization event.** Merge the settled seed content into the destination per the
content rules below, offer any additional output the user asks for, then **delete the seed**.
Four situations resolve as:

- Destination absent, this skill owning the whole document -> create it, then register it
  (see *Registration* below).
- Destination present, the owned content absent -> add it. This is the dominant path.
- Destination present, carrying content **an earlier `create` for this artifact committed**
  -> that part routes to `/aid-update-stack` rather than being overwritten. "Committed
  content" means content an earlier run of this lifecycle wrote, at the granularity of the
  sections the seed's `## Destination` names -- **not** the as-built content
  `/aid-discover` wrote.

**A repeat `create` never halts with nothing done.** Every part of the seed that is new is
written; each part that would overwrite previously committed content is **named and routed**
to `/aid-update-stack`. The seed is deleted only when everything its `## Destination` named
was written; otherwise it stays in place carrying just the unrealized parts, which
`/aid-update-stack` then consumes.

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
written; the rejected alternatives went to the D document; and anything routed to
`/aid-update-stack` is named.

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

**Writes (C0):** languages, runtimes, frameworks, package managers, and build and test
tooling **each with its version**, plus version constraints and floors. Among the twelve
foundation skills this is the **only** writer of framework and tool versions.

**Must not write:**

- **Rejected alternatives into the C0 document.** That document has no section for them, and
  inventing one would put concern-D content in a C0 doc. They go to the project's D document
  (`decisions.md` by default, owner `aid-researcher-architecture`) -- the second destination
  the seed names.
- **Architecture structure** -- concern C1, `/aid-create-architecture`'s.
- **CI runner configuration** -- concern C8, `/aid-create-cicd`'s.

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
