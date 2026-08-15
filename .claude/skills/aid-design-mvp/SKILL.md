---
name: aid-design-mvp
description: >
  Draw the MVP line as a DESIGN SEED in .aid/design/mvp.md -- what is in the first shippable
  slice, what defers, and the reason for each cut. Use this skill when what the first
  shippable slice should contain is still an open question. Grounded in the Knowledge Base
  (.aid/knowledge/) and the project source. It WRITES NO KB DOCUMENT and NO production code
  -- realize the seed into roadmap.md's ## MVP section with /aid-create-mvp once it is
  ready. For direction beyond the first slice, use /aid-design-roadmap instead. Produced by
  the aid-architect agent and independently verified by aid-reviewer (full verify).
  Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<slice> -- what belongs in the first shippable slice, and what to cut"
---

# Design MVP (draw the first-slice line as a design seed, resolve nothing)

`/aid-design-mvp` draws the line for the first shippable slice as a **design seed** in
`.aid/design/mvp.md`. It is a `design`-stage skill under the shared contract in
`.claude/aid/templates/design-lifecycle.md`, which this skill binds to and does not
restate. It never writes `.aid/knowledge/roadmap.md` and never writes production code
(`design-lifecycle.md § The three stages` -- the `design` invariant); realizing a ready
seed into `roadmap.md`'s `## MVP` section is `/aid-create-mvp`'s job, not this one's --
this skill writes no KB document at all, only within `.aid/design/`.

- **Boundary vs `/aid-design-roadmap`:** this skill draws the first-slice line only -- what
  ships first, what defers, and why each cut was made. Direction beyond that slice is
  `/aid-design-roadmap`'s own act, not this one's.
- **Boundary vs `/aid-create-mvp`:** that skill *realizes* a ready seed into `roadmap.md`'s
  `## MVP` section only; this one only develops it. Neither resolves anything on its own --
  the user decides when a seed is ready to realize.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**. Print
the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   belongs in the first shippable slice, and what should defer?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work
   Initiation Gate, then `initiator: aid-design-mvp`, `active_skill: aid-design-mvp`,
   `pipeline.path: lite`, `lifecycle: Running`. `phase` is not driven.
3. **Acquire `.aid/design/`.** Per `design-lifecycle.md § Before writing a seed` -- ensure
   the folder exists and seed its `README.md` on first use, before writing anything.
4. **Read the existing seed, if one is present.** `.aid/design/mvp.md` -- re-invocation
   iterates the same seed rather than starting over.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to develop or iterate the seed,
grounded in `.aid/knowledge/` and the project source, plus the seed read in INTAKE if one
exists. Draws out: **the line -- what is in the first shippable slice, what defers, and
the reason for each cut.**

Writes `.aid/design/mvp.md` **only**, in `design-seed.md`'s shape -- `## Current
direction` rewritten to the latest proposal, `## Options considered` accumulating rather
than being replaced. **Never writes `.aid/knowledge/`; never writes production code** --
the `design` invariant, binding without exception.

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
(`/aid-create-mvp`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
stays at `.aid/design/mvp.md` -- consumption happens at `/aid-create-mvp`, not here.

---

## Constraints

- **`design` never writes `.aid/knowledge/` and never writes production code**
  (`design-lifecycle.md § The three stages`), without exception.
- **`phase` is not driven** by this skill (`design-lifecycle.md § Skill shape --
  Allocation`).
- **Full verify**, per `design-lifecycle.md`, unlike a light single-pass check.
- **Iterative, not terminal** -- re-invocation rewrites `## Current direction` and
  accumulates `## Options considered`; the user decides when to stop.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** write STATE `lifecycle` at every transition.
