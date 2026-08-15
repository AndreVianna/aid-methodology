---
name: aid-design-dashboard
description: >
  Develop a dashboard / BI-view design as a DESIGN SEED in .aid/design/dashboard.md -- the
  data source, the visualizations, and the refresh cadence. Use this skill when what a
  dashboard should show, and to whom, is still being decided. Grounded in the Knowledge Base
  (.aid/knowledge/) and the project source. It WRITES NO production code and NO KB document
  -- realize the seed into the built dashboard with /aid-create-dashboard once it is ready.
  Produced by the aid-architect agent and independently verified by aid-reviewer (full
  verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, shell, Write, Edit, Agent
argument-hint: "<subject> -- the dashboard to design (source, visualizations, refresh cadence)"
---

# Design Dashboard (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`dashboard`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.github/aid/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/dashboard.md`; realizing it
into the built dashboard is `/aid-create-dashboard`'s job, not this one's.

- **Boundary vs `/aid-create-dashboard`:** that skill *builds* the dashboard from a ready
  seed; this one only *develops* the seed. Neither resolves anything on its own -- the
  user decides when a seed is ready to realize.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What dashboard
   do you want to design -- its data source, visualizations, and refresh cadence?") and
   wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.github/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-dashboard`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/dashboard.md` if a
   prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/dashboard.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the data source, the visualizations,
and the refresh cadence**; its `## Destination` names where the built dashboard lands.
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
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-dashboard`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/dashboard.md`; consumption happens at `/aid-create-dashboard`.
