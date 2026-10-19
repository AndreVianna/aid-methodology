---
name: aid-design-data-model
description: >
  Develop a data-model design as a DESIGN SEED in `.aid/design/data-model.md` -- its
  entities, their relationships, and the migration impact of introducing them. Use this
  skill when an entity's shape and its relationships are still being worked out, before any
  migration is written. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project
  source. It WRITES NO production code and NO KB document -- realize the seed into the built
  model and its migration with `/aid-create-data-model` once it is ready. Produced by the
  aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a
  work-NNN folder.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- the data model to design (entities, relationships, migration impact)"
---

# Design Data Model (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`data-model`** -- the `design` *stage* in the
contract's vocabulary -- then follow the shared contract at
`.aid/runtime/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/data-model.md`; realizing
it into the built model and its migration is `/aid-create-data-model`'s job, not this
one's.

- **Boundary vs `/aid-create-data-model`:** that skill *builds* the model and its
  migration from a ready seed; this one only *develops* the seed. Neither resolves
  anything on its own -- the user decides when a seed is ready to realize.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What data
   model do you want to design -- its entities, relationships, and migration impact?") and
   wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-design-data-model` given to the gate's `--create`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/data-model.md` if a
   prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the work record alone decides where a work continues.

**Advance:** CHAIN -> [State: DESIGN].

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/data-model.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **its entities, their relationships, and
the migration impact of introducing them**; its `## Destination` names where the built
model and its migration land. **Never writes `.aid/knowledge/` and never writes production
code** -- the `design` invariant (`design-lifecycle.md`).

**Advance:** CHAIN -> [State: VERIFY].

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.

**Advance:** CHAIN -> [State: PRESENT].

---

## State: PRESENT (hard stop -- the user decides)

Set the lifecycle to `Paused-Awaiting-Input` through the writer. Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-data-model`).

**Advance:** ASK -> [State: DONE].

---

## State: DONE

Set the lifecycle to `Completed` through the writer, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/data-model.md`; consumption happens at `/aid-create-data-model`.
