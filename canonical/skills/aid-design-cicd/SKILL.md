---
name: aid-design-cicd
description: >
  Develop the delivery pipeline as a DESIGN SEED in .aid/design/cicd.md -- stages,
  triggers, environments, promotion, and release flow. Grounded in the Knowledge
  Base (.aid/knowledge/) and the project source. It WRITES NO KB document, NO
  production code, and NO workflow file -- realize the seed into the project's C8
  document with /aid-create-cicd once it is ready. To design a resource the
  pipeline ships to, use /aid-design-infra; to design a data pipeline rather than a
  delivery one, use /aid-design-data-pipeline; to ship a built artifact now, use
  /aid-deploy. Produced by the aid-architect agent and independently verified by
  aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<subject> -- the delivery pipeline to design (stages, triggers, environments, promotion)"
---

# Design CI/CD (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`cicd`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`canonical/aid/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/cicd.md`; realizing it into
the project's C8 document is `/aid-create-cicd`'s job, not this one's.

- **Boundary vs `/aid-create-cicd`:** that skill *realizes* the seed into the C8 document;
  this one only *develops* the seed. Neither resolves anything on its own.
- **Boundary vs `/aid-design-infra`, `/aid-design-data-pipeline` and `/aid-deploy`:**
  `/aid-design-infra` designs a resource the pipeline ships to; `/aid-design-data-pipeline`
  designs a *data* pipeline, not a delivery one; `/aid-deploy` ships a built artifact.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What delivery
   pipeline do you want to design -- its stages, triggers, environments, and promotion
   flow?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`canonical/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-design-cicd`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/cicd.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/cicd.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the pipeline stages, triggers,
environments, and promotion and release flow**.

**Destination resolution (by concern, not filename).** This skill binds concern **C8**
(shipping & operation, `canonical/aid/templates/kb-authoring/concern-model.md`), never a
hardcoded filename. Resolve C8 against `.aid/settings.yml` `knowledge.doc_set`, falling
back to the C8 row of `canonical/aid/templates/kb-authoring/domain-doc-matrix.md`, and
**confirm the resolution with the user** before writing. Write the resolved path into the
seed's **`## Destination`** section. Where a realization is genuinely ambiguous, **ask --
never pick silently**.

**Writes only `.aid/design/cicd.md`.** Never writes `.aid/knowledge/`, never writes
production code, and **never writes a workflow file under `.github/`** -- the `design`
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
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-cicd`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
persists at `.aid/design/cicd.md`; consumption happens at `/aid-create-cicd`.
