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

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> HANDOFF? ->
DONE**.

Steps, advance words, record writes and hand-offs follow `.aid/runtime/templates/skill-steps.md`;
this skill keeps only its own step table.

---

## State: INTAKE

**State Detection.** Detection shapes the entry step of a fresh start and validates a saved step
on resume; it never routes. The step a design resumes at comes from the seed's `step:` and `step_detail:` frontmatter
(`.aid/runtime/templates/skill-steps.md`, § State Detection).

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What do you
   want designed, and what will it need to support?") and wait: acquire `.aid/design/` first (step 4), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/draft.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-design`, which opens the provisional document `.aid/design/draft.md` (`status: draft`), and record the reply with `--answer --design .aid/design/draft.md --id D1 --state Answered --value '<the reply>'`; once the reply names the subject, rename that document to the seed (step 4), questions and all.
2. **Pick the path:** **Fast** -- a clear thing to design ("design the checkout flow",
   "design this service's interface") -> design now. **Guided** -- open-ended ("design our
   onboarding") -> scope the subject, constraints, and success criteria first.
3. **Classify complexity (model + effort):** simple (one component/flow) -> `aid-architect`
   at **sonnet / medium**; complex (a system architecture, a multi-screen flow) -> **opus /
   high**. Verifier tier >= producer tier.
4. **Name the seed; open no work.** Derive a kebab-case `<slug>` from the subject; the design is kept as the seed `.aid/design/<slug>.md` (acquire `.aid/design/` per `.aid/runtime/templates/design-lifecycle.md` first, and read the seed if a prior one exists). This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Record every question with `--ask --design .aid/design/<slug>.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/<slug>.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.

**Advance:** CHAIN → DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to produce the design, **grounded in
the KB** (existing patterns, conventions, `architecture.md`) + the request: variables/flow,
control/interaction, component or interface shape, and **accessibility notes**
(`task-type-rules.md ## DESIGN`). It writes the design into the seed `.aid/design/<slug>.md` (the design's
kept record).

**Advance:** CHAIN → VERIFY.

---

## State: VERIFY  (full -- a kept design drives a build)

1. **Mechanical grounding check** (no dispatch): design decisions cite the KB/source they
   build on; accessibility is addressed.
2. **Adversarial verification** -- clean-context **`aid-reviewer`** checks the seed:
   grounded, complete, internally consistent, consistent with KB conventions + a11y, and
   buildable. Writes a review-quality ledger to `.aid/.temp/review-pending/<slug>-verify.md`.
3. **Grade:** `bash .aid/runtime/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to DESIGN. Circuit-breaker: 3 cycles -> IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/<slug>.md --detail 'impediment: <reason>'`.

**Advance:** CHAIN → PRESENT when the verify is clean; CHAIN → DESIGN when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT  (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user decides whether/when to build it.

Then ask the user to approve the result, through the question protocol, and record the approval on the seed. Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/<slug>.md --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-design` (it prints the question's id, `D<n>`), and bring the step up to date with `--step PRESENT --design .aid/design/<slug>.md --detail 'presented; waiting for D<n>'`. An approval cannot be skipped: the step stays open until the user approves or declines. Once it is answered, record the answer with `--answer --design .aid/design/<slug>.md --id D<n> --state Answered --value '<Approved, or Declined with the changes asked>'`, and end the step with the advance below.
If the user declines or asks for changes, DESIGN revises the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → HANDOFF when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: HANDOFF  (optional; printed suggestions only)

Printed suggestions: build it (`/aid-create*` / `/aid-update*`, referencing the design), or
capture it as a formal doc (`/aid-create-document`). Never auto-invoked; never a resolution.

**Advance:** CHAIN → DONE.

---

## State: DONE

Record the step with `--step DONE --design .aid/design/<slug>.md --detail 'approved'`. Keep
the seed in `.aid/design/` as the kept design record.

---

## Constraints

- **Kept deliverable** -- the design is real, meant to inform a build (not throwaway).
- **Grounded in KB + source**, enforced (VERIFY step 1 + the architect brief).
- **Full verify** -- a kept design drives a build, so it is adversarially graded (unlike
  `/aid-prototype`'s light check).
- **Resolves nothing** -- presents the design; the build is a separate `/aid-create*` step.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Throwaway validation is `/aid-prototype`, not this.**
- **No work is opened** by this skill, and nothing is written under `.aid/works/`; the seed's `## Questions` table is its question record.
- **Tracking:** set the seed's `step:` through `--step --design` at every transition.
