---
name: aid-design-stack
description: >
  Develop the technology choice as a DESIGN SEED in `.aid/design/stack.md` -- languages,
  runtimes, frameworks, and build and test tooling with versions, plus the alternatives
  rejected and why. Use this skill when which technologies to build on is still an open
  choice. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It
  WRITES NO KB document and NO production code -- realize the seed into the project's C0
  document with `/aid-create-stack` once it is ready. To design a configuration option
  within a stack rather than choose the stack, use `/aid-design-config`; for an open
  question with a researchable answer, use `/aid-research`. Produced by the aid-architect
  agent and independently verified by aid-reviewer (full verify). Allocates a work-NNN
  folder.
allowed-tools: Read, Glob, Grep, shell, Write, Edit, Agent
argument-hint: "<subject> -- the technology stack to design (languages, runtimes, frameworks, tooling with versions)"
---

# Design Stack (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`stack`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.github/aid/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/stack.md`; realizing it into
the project's C0 document is `/aid-create-stack`'s job, not this one's.

- **Boundary vs `/aid-create-stack`:** that skill *realizes* the seed into the C0 document;
  this one only *develops* the seed. Neither resolves anything on its own.
- **Boundary vs `/aid-design-config` and `/aid-research`:** `/aid-design-config` configures
  a chosen stack rather than choosing one; `/aid-research` answers an already-formed question
  -- a decision to make vs a question with an answer.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What technology
   stack do you want to design -- its languages, runtimes, frameworks, and tooling?") and
   wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.github/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-stack`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/stack.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/stack.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the languages, runtimes, frameworks and
build/test tooling WITH VERSIONS, plus the alternatives rejected and why**.

**Destination resolution (by concern, not filename).** This skill binds concern **C0**
(technology, `.github/aid/templates/kb-authoring/concern-model.md`), never a hardcoded
filename. Resolve C0 against `.aid/settings.yml` `knowledge.doc_set`, falling back to the
C0 row of `.github/aid/templates/kb-authoring/domain-doc-matrix.md`, and **confirm the
resolution with the user** before writing. This seed records **two destinations** in its
**`## Destination`** section: the resolved C0 document for the chosen stack, and the
project's **D** document (direction/decisions) for the rejected alternatives and their
rationale (§7d). Where a realization is genuinely ambiguous, **ask -- never pick silently**.

**Writes only `.aid/design/stack.md`.** Never writes `.aid/knowledge/`, never writes
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
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-stack`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/stack.md`; consumption happens at `/aid-create-stack`.
