---
name: aid-design-architecture
description: >
  Develop the system's shape as a DESIGN SEED in `.aid/design/architecture.md` --
  components, boundaries, interactions, invariants, and what is deliberately not a
  component. Use this skill when how the system should be shaped is still being worked out,
  and you want that thinking captured before it is written into the Knowledge Base. Grounded
  in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO KB document
  and NO production code -- realize the seed into the project's C1 document with
  `/aid-create-architecture` once it is ready. For a subject with no dedicated design row
  use bare `/aid-design`; to write documentation about an existing architecture rather than
  design it, use `/aid-document-architecture`. Produced by the aid-architect agent and
  independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, Agent
argument-hint: "<subject> -- the system/subsystem to design (components, boundaries, interactions, invariants)"
---

# Design Architecture (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`architecture`** -- the `design` *stage* in the
contract's vocabulary -- then follow the shared contract at
`.cursor/aid/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/architecture.md`; realizing
it into the project's C1 document is `/aid-create-architecture`'s job, not this one's.

- **Boundary vs `/aid-create-architecture`:** that skill *realizes* the seed into the C1
  document; this one only *develops* the seed. Neither resolves anything on its own.
- **Boundary vs bare `/aid-design` and `/aid-document-architecture`:** bare `/aid-design`
  is the catch-all for a subject with no dedicated row; `/aid-document-architecture` writes
  *documentation about* an architecture -- the opposite side of the KB write boundary.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What system or
   subsystem do you want to design -- its components, boundaries, and invariants?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.cursor/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-architecture`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/architecture.md` if a
   prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/architecture.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the components, their boundaries and
interactions, the invariants, and what is deliberately NOT a component**.

**Destination resolution (by concern, not filename).** This skill binds concern **C1**
(build & shape, `.cursor/aid/templates/kb-authoring/concern-model.md`), never a hardcoded
filename. Resolve C1 against the project's declared doc-set (`.aid/settings.yml`
`knowledge.doc_set`), falling back to the C1 row of
`.cursor/aid/templates/kb-authoring/domain-doc-matrix.md`, and **confirm the resolution
with the user** before writing. Write the resolved path into the seed's **`## Destination`**
section (required for a class-1 seed). C1's default set holds both `project-structure.md`
and `architecture.md`; this skill resolves to the document describing the system's shape
and **never** `project-structure.md`, which describes the repo layout. Where the
realization is genuinely ambiguous, **ask -- never pick silently**.

**Writes only `.aid/design/architecture.md`.** Never writes `.aid/knowledge/`, never writes
production code -- the `design` invariant (`design-lifecycle.md`).

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-architecture`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/architecture.md`; consumption happens at
`/aid-create-architecture`.
