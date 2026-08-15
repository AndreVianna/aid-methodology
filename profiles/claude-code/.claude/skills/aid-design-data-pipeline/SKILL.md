---
name: aid-design-data-pipeline
description: >
  Develop a data-pipeline design as a DESIGN SEED in .aid/design/data-pipeline.md -- the
  source, the transform, the sink, and the schedule. Use this skill when where the data
  comes from, what happens to it, and where it lands are still open questions. Grounded in
  the Knowledge Base (.aid/knowledge/) and the project source. It WRITES NO production code
  and NO KB document -- realize the seed into the built pipeline with
  /aid-create-data-pipeline once it is ready. Produced by the aid-architect agent and
  independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<subject> -- the data pipeline to design (source, transform, sink, schedule)"
---

# Design Data Pipeline (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`data-pipeline`** -- the `design` *stage* in the
contract's vocabulary -- then follow the shared contract at
`.claude/aid/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/data-pipeline.md`; realizing
it into the built pipeline is `/aid-create-data-pipeline`'s job, not this one's.

- **Boundary vs `/aid-create-data-pipeline`:** that skill *builds* the pipeline from a
  ready seed; this one only *develops* the seed. Neither resolves anything on its own --
  the user decides when a seed is ready to realize.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What data
   pipeline do you want to design -- its source, transform, sink, and schedule?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.claude/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-data-pipeline`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/data-pipeline.md` if
   a prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/data-pipeline.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the source, the transform, the sink,
and the schedule**; its `## Destination` names where the built pipeline lands. **Never
writes `.aid/knowledge/` and never writes production code** -- the `design` invariant
(`design-lifecycle.md`).

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-data-pipeline`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/data-pipeline.md`; consumption happens at
`/aid-create-data-pipeline`.
