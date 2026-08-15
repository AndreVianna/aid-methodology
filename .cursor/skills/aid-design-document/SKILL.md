---
name: aid-design-document
description: >
  Develop a document design as a DESIGN SEED in .aid/design/document.md -- the document's
  kind and structure, its audience, and its placement. Use this skill when a document's
  angle, audience and shape are still being worked out, before it is drafted. Grounded in
  the Knowledge Base (.aid/knowledge/) and the project source. It WRITES NO production code
  and NO KB document -- realize the seed into the written document with /aid-create-document
  once it is ready. To write a general document now rather than develop its direction as a
  seed, use /aid-document. Produced by the aid-architect agent and independently verified by
  aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, Agent
argument-hint: "<subject> -- the document to design (kind, structure, audience, placement)"
---

# Design Document (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`document`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.cursor/aid/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/document.md`; realizing it
into the written document is `/aid-create-document`'s job, not this one's.

- **Boundary vs `/aid-create-document`:** that skill *writes* the document from a ready
  seed; this one only *develops* the seed. Neither resolves anything on its own -- the
  user decides when a seed is ready to realize.
- **Boundary vs bare `/aid-document`:** that skill writes a general document now; this one
  develops the document's direction as a reusable seed first. Design it here; write it
  there.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What document
   do you want to design -- its kind, structure, audience, and placement?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.cursor/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-document`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/document.md` if a
   prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/document.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the document's kind and structure, its
audience, and its placement**; its `## Destination` names where the written document
lands. **Never writes `.aid/knowledge/` and never writes production code** -- the `design`
invariant (`design-lifecycle.md`).

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-document`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/document.md`; consumption happens at `/aid-create-document`.
