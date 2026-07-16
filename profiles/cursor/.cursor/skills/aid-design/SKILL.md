---
name: aid-design
description: >
  Produce a KEPT design artifact NOW -- a UX/interaction flow, a component or
  interface design, an architecture sketch, with accessibility notes -- meant to
  inform the real build. Single-shot; grounded in the Knowledge Base
  (.aid/knowledge/) and the project source (patterns, conventions, architecture).
  It RESOLVES NOTHING: it presents the design; you decide, and the build is a
  separate /aid-create* step. Produced by the aid-architect agent and
  independently verified by aid-reviewer (full verify -- a kept design drives a
  build, so its correctness matters). For a THROWAWAY model to merely validate a
  direction, use /aid-prototype instead. Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Terminal, Write, Edit, Agent
argument-hint: "<subject> -- what to design (a flow, a component/interface, a UI, an architecture sketch)"
---

# Design (produce a kept design, resolve nothing)

`/aid-design` produces a **design artifact meant to be kept and built** -- distinct from
`/aid-prototype`, whose model is throwaway and only validates a direction. Pin the
distinction: **prototype = throwaway, to *validate*; design = kept, to *inform the build*.**
It fills the DESIGN lite gap (DESIGN is a task type, but there was no lite entry point).

- **Boundary vs `/aid-create-document`:** `aid-design` *produces the design*
  (`aid-architect`, DESIGN); `aid-document` *writes documentation about* something
  (`aid-tech-writer`, DOCUMENT). A design needing a formal written spec -> print a handoff
  to `/aid-create-document`.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Behavior contract:** `.aid/work-005-lite-skills-refactor/specs/aid-prototype-design.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> HANDOFF? ->
DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What do you
   want designed, and what will it need to support?") and wait.
2. **Pick the path:** **Fast** -- a clear thing to design ("design the checkout flow",
   "design this service's interface") -> design now. **Guided** -- open-ended ("design our
   onboarding") -> scope the subject, constraints, and success criteria first.
3. **Classify complexity (model + effort):** simple (one component/flow) -> `aid-architect`
   at **sonnet / medium**; complex (a system architecture, a multi-screen flow) -> **opus /
   high**. Verifier tier >= producer tier.
4. **Allocate the work folder + STATE** (`pipeline.path: lite`, `initiator: aid-design`,
   `lifecycle: Running`, `active_skill: aid-design`; `phase` not driven).

**Advance:** DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to produce the design, **grounded in
the KB** (existing patterns, conventions, `architecture.md`) + the request: variables/flow,
control/interaction, component or interface shape, and **accessibility notes**
(`task-type-rules.md ## DESIGN`). It writes `DESIGN.md` into the work folder (the design's
kept record).

**Advance:** VERIFY.

---

## State: VERIFY  (full -- a kept design drives a build)

1. **Mechanical grounding check** (no dispatch): design decisions cite the KB/source they
   build on; accessibility is addressed.
2. **Adversarial verification** -- clean-context **`aid-reviewer`** checks `DESIGN.md`:
   grounded, complete, internally consistent, consistent with KB conventions + a11y, and
   buildable. Writes a review-quality ledger to `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade:** `bash .cursor/aid/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to DESIGN. Circuit-breaker: 3 cycles -> IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT  (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present `DESIGN.md` clearly. Assert no resolution --
the user decides whether/when to build it.

**Advance:** HANDOFF (optional) then DONE.

---

## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions: build it (`/aid-create*` / `/aid-change*`, referencing the design), or
capture it as a formal doc (`/aid-create-document`). Never auto-invoked; never a resolution.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Keep
`DESIGN.md` in the work folder as the kept design record.

---

## Constraints

- **Kept deliverable** -- the design is real, meant to inform a build (not throwaway).
- **Grounded in KB + source**, enforced (VERIFY step 1 + the architect brief).
- **Full verify** -- a kept design drives a build, so it is adversarially graded (unlike
  `/aid-prototype`'s light check).
- **Resolves nothing** -- presents the design; the build is a separate `/aid-create*` step.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Throwaway validation is `/aid-prototype`, not this.**
- **Tracking:** write STATE `lifecycle` at every transition.
