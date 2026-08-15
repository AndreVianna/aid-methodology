---
name: aid-design-backlog
description: >
  Develop the defined-and-prioritized item set as a DESIGN SEED in .aid/design/backlog.md --
  item definitions, done-conditions, priorities, and which tech-debt.md rows the user is
  accepting into the plan. Use this skill when what belongs in the backlog is still being
  decided, and you want that thinking captured as a seed before the document is written.
  Grounded in the Knowledge Base (.aid/knowledge/, including tech-debt.md) and the project
  source. It WRITES NO KB DOCUMENT and NO production code -- realize the seed into
  backlog.md with /aid-create-backlog once it is ready. For direction rather than items, use
  /aid-design-roadmap instead. Produced by the aid-architect agent and independently
  verified by aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<items> -- the items to define and prioritize, and any tech-debt.md rows to accept"
---

# Design Backlog (develop the item set as a design seed, resolve nothing)

`/aid-design-backlog` develops the defined-and-prioritized item set as a **design seed**
in `.aid/design/backlog.md`. It is a `design`-stage skill under the shared contract in
`canonical/aid/templates/design-lifecycle.md`, which this skill binds to and does not
restate. It never writes `.aid/knowledge/backlog.md` and never writes production code
(`design-lifecycle.md § The three stages` -- the `design` invariant); realizing a ready
seed into `backlog.md` -- including moving accepted rows out of `tech-debt.md` -- is
`/aid-create-backlog`'s job, not this one's.

- **Boundary vs `/aid-design-roadmap`:** this skill develops item definitions,
  done-conditions and priorities at item granularity; direction at roadmap altitude, with
  no item ids in it, is `/aid-design-roadmap`'s own act, not this one's.
- **Boundary vs `/aid-create-backlog`:** that skill *realizes* a ready seed into
  `backlog.md` and performs the `tech-debt.md` promotion; this one only proposes which
  rows to accept. Neither resolves anything on its own -- the user confirms every
  promotion at `/aid-create-backlog`'s own gate.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**. Print
the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What items do
   you want to define and prioritize, and are there `tech-debt.md` rows you're ready to
   accept into the plan?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work
   Initiation Gate, then `initiator: aid-design-backlog`, `active_skill:
   aid-design-backlog`, `pipeline.path: lite`, `lifecycle: Running`. `phase` is not
   driven.
3. **Acquire `.aid/design/`.** Per `design-lifecycle.md § Before writing a seed` -- ensure
   the folder exists and seed its `README.md` on first use, before writing anything.
4. **Read the existing seed, if one is present.** `.aid/design/backlog.md` --
   re-invocation iterates the same seed rather than starting over.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to develop or iterate the seed,
grounded in `.aid/knowledge/` (including `tech-debt.md`'s open inventory) and the project
source, plus the seed read in INTAKE if one exists. Draws out: **item definitions,
done-conditions and priorities; which `tech-debt.md` rows the user is accepting into the
plan.**

Writes `.aid/design/backlog.md` **only**, in `design-seed.md`'s shape -- `## Current
direction` rewritten to the latest proposal, `## Options considered` accumulating rather
than being replaced. **Never writes `.aid/knowledge/`; never writes production code** --
the `design` invariant, binding without exception. Proposing a `tech-debt.md` row for
acceptance is not a write to it -- the seed only names candidates; the move itself, and
its per-item confirmation, happen at `/aid-create-backlog` or `/aid-update-backlog`.

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to DESIGN; the circuit-breaker there governs escalation to
IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the seed clearly. Assert no resolution --
the user decides whether to iterate further (re-invoke this skill) or realize it now
(`/aid-create-backlog`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
stays at `.aid/design/backlog.md` -- consumption happens at `/aid-create-backlog`, not
here.

---

## Constraints

- **`design` never writes `.aid/knowledge/` and never writes production code**
  (`design-lifecycle.md § The three stages`), without exception -- including
  `tech-debt.md`, which is proposed from, never written to, here.
- **`phase` is not driven** by this skill (`design-lifecycle.md § Skill shape --
  Allocation`).
- **Full verify**, per `design-lifecycle.md`, unlike a light single-pass check.
- **Iterative, not terminal** -- re-invocation rewrites `## Current direction` and
  accumulates `## Options considered`; the user decides when to stop.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** write STATE `lifecycle` at every transition.
