---
name: aid-design
description: >
  Produce a design artifact you intend to keep -- a UX or interaction flow, a component or
  interface design, with accessibility notes -- meant to inform the real build. Use this
  skill when the subject has no dedicated design row of its own; when a dedicated
  `/aid-design-`<artifact> row exists, use that row instead. It is grounded in the Knowledge
  Base (`.aid/knowledge/`) and the project source, produced by aid-architect and
  independently verified by aid-reviewer, because a kept design drives a build and its
  correctness matters. It resolves nothing: it presents the design, you decide, and building
  it is a separate `/aid-create` step. For a throwaway model that only validates a
  direction, use `/aid-prototype` instead.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- what to design (a flow, a component/interface, a UI; use a dedicated /aid-design-<artifact> row when one exists)"
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

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> HANDOFF? ->
DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.

Steps, advance words, record writes and hand-offs follow `.aid/runtime/templates/skill-steps.md`;
this skill keeps only its own step table.

---

## State: INTAKE

**State Detection.** Detection shapes the entry step of a fresh start and validates a saved step
on resume; it never routes. Which skill and step a work continues at come from its work record
(`.aid/runtime/templates/skill-steps.md`, § State Detection).

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What do you
   want designed, and what will it need to support?") and wait.
2. **Pick the path:** **Fast** -- a clear thing to design ("design the checkout flow",
   "design this service's interface") -> design now. **Guided** -- open-ended ("design our
   onboarding") -> scope the subject, constraints, and success criteria first.
3. **Classify complexity (model + effort):** simple (one component/flow) -> `aid-architect`
   at **sonnet / medium**; complex (a system architecture, a multi-screen flow) -> **opus /
   high**. Verifier tier >= producer tier.
4. **Consult the Work Initiation Gate, then allocate the work.** First run the gate
   (`.aid/runtime/templates/work-initiation-gate.md`):
   `bash .aid/runtime/scripts/works/enumerate-works.sh` (main tree + every git worktree).
   Empty -> allocate, no prompt. Works exist -> ask new-vs-continuation. On **continuation**,
   follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names,
   at its saved step; allocate nothing. On **new work**, follow the gate's `§ 3a`: create and
   enter the worktree (`worktree-lifecycle.sh create <work-id> <name>`, STOP on a non-zero exit
   or empty path, else enter the resolved path), **then** allocate (`writeback-state.sh --create`
   with `--path lite`, `--skill aid-design` and this skill's entry step; `phase` not driven).
   The gate writes the record; this skill adds nothing by hand.

**Advance:** CHAIN -> DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to produce the design, **grounded in
the KB** (existing patterns, conventions, `architecture.md`) + the request: variables/flow,
control/interaction, component or interface shape, and **accessibility notes**
(`task-type-rules.md ## DESIGN`). It writes `DESIGN.md` into the work folder (the design's
kept record).

**Advance:** CHAIN -> VERIFY.

---

## State: VERIFY  (full -- a kept design drives a build)

1. **Mechanical grounding check** (no dispatch): design decisions cite the KB/source they
   build on; accessibility is addressed.
2. **Adversarial verification** -- clean-context **`aid-reviewer`** checks `DESIGN.md`:
   grounded, complete, internally consistent, consistent with KB conventions + a11y, and
   buildable. Writes a review-quality ledger to `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade:** `bash .aid/runtime/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to DESIGN. Circuit-breaker: 3 cycles -> IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.

**Advance:** CHAIN -> PRESENT when the verify is clean; CHAIN -> DESIGN when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT  (hard stop -- the user decides)

Present `DESIGN.md` clearly. Assert no resolution --
the user decides whether/when to build it.

The user's decision is a blocking question: this step pauses on it until the user answers.

**Advance:** ASK -> HANDOFF.

---

## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions: build it (`/aid-create*` / `/aid-update*`, referencing the design), or
capture it as a formal doc (`/aid-create-document`). Never auto-invoked; never a resolution.

**Advance:** CHAIN -> DONE.

---

## State: DONE

Set the lifecycle to `Completed` through the writer. Keep
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
- **Tracking:** set the STATE lifecycle through the writer at every transition.
