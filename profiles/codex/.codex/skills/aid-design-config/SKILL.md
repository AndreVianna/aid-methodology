---
name: aid-design-config
description: >
  Develop a configuration-option or feature-flag design as a DESIGN SEED in
  `.aid/design/config.md` -- the option or flag, its default and scope, and how it is read.
  Use this skill when a new option's shape, default and blast radius are still being worked
  out. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES
  NO production code and NO KB document -- realize the seed into the built option with
  `/aid-create-config` once it is ready. To design the technology stack itself rather than a
  configuration option within it, use `/aid-design-stack` instead. Produced by the
  aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a
  work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<subject> -- the config option/flag to design (default, scope, how it is read)"
---

# Design Config (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`config`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.codex/aid/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/config.md`; realizing it
into the built option is `/aid-create-config`'s job, not this one's.

- **Boundary vs `/aid-create-config`:** that skill *builds* the option from a ready seed;
  this one only *develops* the seed. Neither resolves anything on its own -- the user
  decides when a seed is ready to realize.
- **Boundary vs `/aid-design-stack`:** that skill designs the technology stack itself;
  this one designs a configuration option within it. Configuring a stack vs choosing one.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   configuration option or flag do you want to design -- its default, scope, and how it is
   read?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.codex/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-config`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/config.md` if a
   prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/config.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the option or flag, its default and
scope, and how it is read**; its `## Destination` names where the built option lands.
**Never writes `.aid/knowledge/` and never writes production code** -- the `design`
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
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-config`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/config.md`; consumption happens at `/aid-create-config`.
