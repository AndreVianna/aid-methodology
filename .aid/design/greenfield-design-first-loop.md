# Design Note — Greenfield "Design-First" Loop (INVESTIGATE FIRST)

**Status:** Pre-scoping — NOT yet a tracked work, and **may dissolve into "no work needed".** Captured
2026-06-29 (post-v2.0.0). Unlike the other three seeds, this one starts with a **read-only investigation**,
because the owner challenged the premise and is likely substantially right: the pipeline may already flow
for greenfield, in which case there is little or nothing to build.

**Honest framing (the discussion that produced this seed).** I initially proposed "build the greenfield
full loop" and **overstated the gap.** The owner pointed out that greenfield `/aid-describe` produces both
`REQUIREMENTS.md` *and* the forward-authored seed KB, and that the later phases already ground on those —
so the journey probably works mechanically today. This note records what is actually true, the two
corrections that refine it, and the narrow open question worth checking before assuming any work exists.

---

## What is already true (shipped in v2.0.0)

- `/aid-describe` (greenfield, no code) **forward-authors a 5-element seed KB** (glossary / architecture /
  conventions / tech-stack / decisions, stamped `source: forward-authored`) **and** produces
  `REQUIREMENTS.md`.
- `/aid-housekeep`'s **Conformance Lane** compares as-built code **against** the forward-authored design
  (code → design) and **flags** divergence for human reconciliation (flag-not-overwrite; design is
  authoritative).

So the two *endpoints* exist. The subsequent phases (`aid-define` → `aid-specify` → `aid-plan` →
`aid-detail` → `aid-execute`) read `REQUIREMENTS.md` + the KB the same way in greenfield as in brownfield.

## Two corrections (refining the owner's model)

1. **`REQUIREMENTS.md` is not the forward-authored *design*.** Different roles:
   - `REQUIREMENTS.md` = **what** to build (user stories, acceptance criteria, scope) — product intent.
   - the seed KB (`architecture`/`decisions`/`conventions`/`tech-stack`) = **how** it is designed — the
     thing code must conform to.
   Phases ground on `REQUIREMENTS.md` for *what* and conform to the **KB** for *how*. In brownfield the
   "how" is *extracted from code*; in greenfield it is *forward-authored*. So the **seed KB**, not
   `REQUIREMENTS.md`, is the design source of truth.

2. **The housekeep direction is *inverted* in greenfield — and that is the whole point.**
   - Brownfield: build code → housekeep re-discovers it → **KB updated to match code** (KB follows code).
     This is the "results reabsorbed into the KB" the owner described — correct *for brownfield*.
   - Greenfield: the seed KB is **authoritative**; code is built to match it; the conformance lane **flags**
     code↔design drift and **does not** overwrite the design with as-built reality. Greenfield deliberately
     **resists** reabsorbing code into the KB, because the design is meant to lead.

## The narrow open question (what the investigation must answer)

> Does the **design-authoritative inversion hold consistently** through the *middle* phases
> (`aid-specify`/`aid-plan`/`aid-detail`/`aid-execute`) and `aid-housekeep` — or does greenfield silently
> slip back into brownfield "KB-follows-code" semantics somewhere?

Specifically:
- Do `aid-specify`/`aid-plan` treat the **forward-authored architecture as authoritative** (conform to it),
  the same way they conform to *extracted* architecture in brownfield — or do they assume code exists?
- When the conformance lane **finds drift**, is there a **defined resolution loop** — "update the design
  (deliberate change) *vs.* fix the code (conform)"? Today that close-the-loop step may be undefined.
- Is there a **graduation** point where a greenfield project, once built, transitions to brownfield-style
  maintenance (KB-follows-code becomes appropriate)? If so, what triggers it?

## Proposed first step (read-only, cheap)

**Trace one greenfield run through the actual skills** — `aid-describe` (DESCRIBE-SEED) → `aid-define` →
`aid-specify` → `aid-plan` → `aid-detail` → `aid-execute` → `aid-housekeep` (Conformance Lane) — reading
the SKILL.md + references, and answer the three questions above.

- If the inversion holds and the loop closes → **close this seed; no work.** (A perfectly good outcome.)
- If gaps exist → they are likely **narrow** (enforce the inversion in one or two phases; define the
  conformance-drift resolution loop; define graduation), not a from-scratch build.

## Scope boundaries

Investigation only, until the trace proves a real gap. Do not build "a greenfield loop" on the assumption
of a gap that may not exist.

## Relation to other work

Builds entirely on work-001's DESCRIBE-SEED + the Conformance Lane (v2.0.0). The forward-authored-KB
inversion is already articulated in the (now-implemented) `.aid/design/aid-interview-improvements.md`
Thread 1 — this seed is about verifying that inversion *survives the whole pipeline*, not re-deciding it.
