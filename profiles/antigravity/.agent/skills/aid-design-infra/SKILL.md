---
name: aid-design-infra
description: >
  Develop an infrastructure-resource design as a DESIGN SEED in .aid/design/infra.md -- the
  resource, its configuration, and its provisioning and teardown. Use this skill when a
  resource's shape and access policy are still being worked out, before anything is
  provisioned. Grounded in the Knowledge Base (.aid/knowledge/) and the project source. It
  WRITES NO production code and NO KB document -- realize the seed into the provisioned
  resource with /aid-create-infra once it is ready. To design the pipeline that ships to the
  resource rather than the resource itself, use /aid-design-cicd instead. Produced by the
  aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a
  work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<subject> -- the infrastructure resource to design (resource, config, provisioning)"
---

# Design Infrastructure (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`infra`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.agent/aid/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/infra.md`; realizing it
into the provisioned resource is `/aid-create-infra`'s job, not this one's.

- **Boundary vs `/aid-create-infra`:** that skill *provisions* the resource from a ready
  seed; this one only *develops* the seed. Neither resolves anything on its own -- the
  user decides when a seed is ready to realize.
- **Boundary vs `/aid-design-cicd`:** that skill designs the pipeline that ships to a
  resource; this one designs the resource itself. Designing a resource vs the pipeline.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   infrastructure resource do you want to design -- the resource, its configuration, and
   its provisioning?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agent/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-infra`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/infra.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/infra.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the resource, its configuration, and
its provisioning and teardown**; its `## Destination` names where the provisioned resource
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
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-infra`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/infra.md`; consumption happens at `/aid-create-infra`.
