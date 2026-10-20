---
name: aid-design-mvp
description: >
  Draw the MVP line as a DESIGN SEED in `.aid/design/mvp.md` -- what is in the first
  shippable slice, what defers, and the reason for each cut. Use this skill when what the
  first shippable slice should contain is still an open question. Grounded in the Knowledge
  Base (`.aid/knowledge/`) and the project source. It WRITES NO KB DOCUMENT and NO
  production code -- realize the seed into roadmap.md's ## MVP section with
  `/aid-create-mvp` once it is ready. For direction beyond the first slice, use
  `/aid-design-roadmap` instead. Produced by the aid-architect agent and independently
  verified by aid-reviewer (full verify).
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<slice> -- what belongs in the first shippable slice, and what to cut"
---

# Design MVP (draw the first-slice line as a design seed, resolve nothing)

`/aid-design-mvp` draws the line for the first shippable slice as a **design seed** in
`.aid/design/mvp.md`. It is a `design`-stage skill under the shared contract in
`.aid/runtime/templates/design-lifecycle.md`, which this skill binds to and does not
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
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   belongs in the first shippable slice, and what should defer?") and wait: acquire `.aid/design/` first (below), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/mvp.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-design-mvp`, which opens the seed document (`status: draft`) when it does not exist yet, and record the reply with `--answer --design .aid/design/mvp.md --id <id> --state Answered --value '<the reply>'`.
2. **Name the seed; open no work.** The seed is `.aid/design/mvp.md`. This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Record every question with `--ask --design .aid/design/mvp.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/mvp.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.
3. **Acquire `.aid/design/`.** Per `design-lifecycle.md § Before writing a seed` -- ensure
   the folder exists and seed its `README.md` on first use, before writing anything.
4. **Read the existing seed, if one is present.** `.aid/design/mvp.md` -- re-invocation
   iterates the same seed rather than starting over.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the seed's `step:` and `step_detail:` frontmatter alone decide where a design resumes.

**Advance:** CHAIN → [State: DESIGN].

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

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to DESIGN; the circuit-breaker there governs escalation to
IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/mvp.md --detail 'impediment: <reason>'`.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user decides whether to iterate further (declining the approval below changes the seed in place) or realize it now
(`/aid-create-mvp`).

Then ask the user to approve the result, through the question protocol, and record the approval on the seed. Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/mvp.md --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-design-mvp` (it prints the question's id, `D<n>`), and bring the step up to date with `--step PRESENT --design .aid/design/mvp.md --detail 'presented; waiting for D<n>'`. An approval cannot be skipped: the step stays open until the user approves or declines. Once it is answered, record the answer with `--answer --design .aid/design/mvp.md --id D<n> --state Answered --value '<Approved, or Declined with the changes asked>'`, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Record the step with `--step DONE --design .aid/design/mvp.md --detail 'approved'`. The seed
stays at `.aid/design/mvp.md` -- consumption happens at `/aid-create-mvp`, not here.

---

## Constraints

- **`design` never writes `.aid/knowledge/` and never writes production code**
  (`design-lifecycle.md § The three stages`), without exception.
- **No work is opened** by this skill, and nothing is written under `.aid/works/`; the seed's `## Questions` table is its question record.
- **Full verify**, per `design-lifecycle.md`, unlike a light single-pass check.
- **Iterative, not terminal** -- re-invocation rewrites `## Current direction` and
  accumulates `## Options considered`; the user decides when to stop.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** set the seed's `step:` through `--step --design` at every transition.
