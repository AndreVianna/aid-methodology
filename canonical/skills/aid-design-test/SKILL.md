---
name: aid-design-test
description: >
  Develop a test design as a DESIGN SEED in .aid/design/test.md -- the units under test, the
  cases, and the framework and fixtures. Use this skill when what a test should actually
  assert is still being worked out. Grounded in the Knowledge Base (.aid/knowledge/) and the
  project source. It WRITES NO production code and NO KB document -- realize the seed into
  authored tests with /aid-create-test once it is ready. To design the testing policy rather
  than specific tests, use /aid-design-testing-strategy; to RUN existing suites rather than
  design them, use /aid-test. Produced by the aid-architect agent and independently verified
  by aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<subject> -- the tests to design (units under test, cases, framework/fixtures)"
---

# Design Test (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`test`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`canonical/aid/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/test.md`; realizing it into
authored tests is `/aid-create-test`'s job, not this one's.

- **Boundary vs `/aid-create-test`:** that skill *authors* the tests from a ready seed;
  this one only *develops* the seed. Neither resolves anything on its own -- the user
  decides when a seed is ready to realize.
- **Boundary vs `/aid-design-testing-strategy` and `/aid-test`:** the first designs the
  testing *policy*, not specific tests; `/aid-test` *runs* existing suites rather than
  designing them.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What tests do
   you want to design -- the units under test, the cases, and the framework?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`canonical/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-test`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/test.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/test.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the units under test, the cases, and
the framework and fixtures**; its `## Destination` names where the authored tests land.
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
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-test`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/test.md`; consumption happens at `/aid-create-test`.
