---
name: aid-design-roadmap
description: >
  Develop the project's committed direction as a DESIGN SEED in `.aid/design/roadmap.md` --
  what is committed vs. merely wanted, the sequencing rationale, and the alternatives being
  rejected and why. Use this skill when the direction for the coming horizons is still being
  argued out, and you want it settled as a seed before it becomes the roadmap. Grounded in
  the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO KB DOCUMENT
  and NO production code -- realize the seed into roadmap.md with `/aid-create-roadmap` once
  it is ready. For drawing the MVP line as its own act, use `/aid-design-mvp` instead.
  Produced by the aid-architect agent and independently verified by aid-reviewer (full
  verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<direction> -- what to develop (committed vs. wanted, sequencing, rejected alternatives)"
---

# Design Roadmap (develop direction as a design seed, resolve nothing)

`/aid-design-roadmap` develops the project's committed direction as a **design seed** in
`.aid/design/roadmap.md`. It is a `design`-stage skill under the shared contract in
`.agent/aid/templates/design-lifecycle.md`, which this skill binds to and does not
restate. It never writes `.aid/knowledge/roadmap.md` and never writes production code
(`design-lifecycle.md § The three stages` -- the `design` invariant); realizing a ready
seed into `roadmap.md` is `/aid-create-roadmap`'s job, not this one's.

- **Boundary vs `/aid-design-mvp`:** this skill develops direction at roadmap altitude --
  what's committed, what's merely wanted, sequencing, rejected alternatives. Drawing the
  line for the first shippable slice is `/aid-design-mvp`'s own act, not this one's.
- **Boundary vs `/aid-create-roadmap`:** that skill *realizes* a ready seed into
  `roadmap.md`; this one only develops it. Neither resolves anything on its own -- the user
  decides when a seed is ready to realize.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**. Print
the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   direction do you want to develop -- what's committed, what's merely wanted, and why?")
   and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work
   Initiation Gate, then `initiator: aid-design-roadmap`, `active_skill:
   aid-design-roadmap`, `pipeline.path: lite`, `lifecycle: Running`. `phase` is not
   driven.
3. **Acquire `.aid/design/`.** Per `design-lifecycle.md § Before writing a seed` -- ensure
   the folder exists and seed its `README.md` on first use, before writing anything.
4. **Read the existing seed, if one is present.** `.aid/design/roadmap.md` --
   re-invocation iterates the same seed rather than starting over.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to develop or iterate the seed,
grounded in `.aid/knowledge/` and the project source, plus the seed read in INTAKE if one
exists. Draws out: **direction and its *why*; what is committed vs. merely wanted;
sequencing rationale; the alternatives being rejected and why.**

Writes `.aid/design/roadmap.md` **only**, in `design-seed.md`'s shape --
`## Current direction` rewritten to the latest proposal, `## Options considered`
accumulating rather than being replaced. **Never writes `.aid/knowledge/`; never writes
production code** -- the `design` invariant, binding without exception.

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
(`/aid-create-roadmap`).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed
stays at `.aid/design/roadmap.md` -- consumption happens at `/aid-create-roadmap`, not
here.

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
