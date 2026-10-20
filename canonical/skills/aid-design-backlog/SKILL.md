---
name: aid-design-backlog
description: >
  Develop the defined-and-prioritized item set as a DESIGN SEED in `.aid/design/backlog.md`
  -- item definitions, done-conditions, priorities, and which tech-debt.md rows the user is
  accepting into the plan. Use this skill when what belongs in the backlog is still being
  decided, and you want that thinking captured as a seed before the document is written.
  Grounded in the Knowledge Base (`.aid/knowledge/`, including tech-debt.md) and the project
  source. It WRITES NO KB DOCUMENT and NO production code -- realize the seed into
  backlog.md with `/aid-create-backlog` once it is ready. For direction rather than items,
  use `/aid-design-roadmap` instead. Produced by the aid-architect agent and independently
  verified by aid-reviewer (full verify).
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<items> -- the items to define and prioritize, and any tech-debt.md rows to accept"
---

# Design Backlog (develop the item set as a design seed, resolve nothing)

`/aid-design-backlog` develops the defined-and-prioritized item set as a **design seed**
in `.aid/design/backlog.md`. It is a `design`-stage skill under the shared contract in
`.aid/runtime/templates/design-lifecycle.md`, which this skill binds to and does not
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
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What items do
   you want to define and prioritize, and are there `tech-debt.md` rows you're ready to
   accept into the plan?") and wait: acquire `.aid/design/` first (below), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/backlog.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-design-backlog`, which opens the seed document (`status: draft`) when it does not exist yet, and record the reply with `--answer --design .aid/design/backlog.md --id <id> --state Answered --value '<the reply>'`.
2. **Name the seed; open no work.** The seed is `.aid/design/backlog.md`. This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Record every question with `--ask --design .aid/design/backlog.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/backlog.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.
3. **Acquire `.aid/design/`.** Per `design-lifecycle.md § Before writing a seed` -- ensure
   the folder exists and seed its `README.md` on first use, before writing anything.
4. **Read the existing seed, if one is present.** `.aid/design/backlog.md` --
   re-invocation iterates the same seed rather than starting over.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the seed's `step:` and `step_detail:` frontmatter alone decide where a design resumes.

**Advance:** CHAIN → [State: DESIGN].

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

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to DESIGN; the circuit-breaker there governs escalation to
IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/backlog.md --detail 'impediment: <reason>'`.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user decides whether to iterate further (declining the approval below changes the seed in place) or realize it now
(`/aid-create-backlog`).

Then ask the user to approve the result, through the question protocol, and record the approval on the seed. Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/backlog.md --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-design-backlog` (it prints the question's id, `D<n>`), and bring the step up to date with `--step PRESENT --design .aid/design/backlog.md --detail 'presented; waiting for D<n>'`. An approval cannot be skipped: the step stays open until the user approves or declines. Once it is answered, record the answer with `--answer --design .aid/design/backlog.md --id D<n> --state Answered --value '<Approved, or Declined with the changes asked>'`, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Record the step with `--step DONE --design .aid/design/backlog.md --detail 'approved'`. The seed
stays at `.aid/design/backlog.md` -- consumption happens at `/aid-create-backlog`, not
here.

---

## Constraints

- **`design` never writes `.aid/knowledge/` and never writes production code**
  (`design-lifecycle.md § The three stages`), without exception -- including
  `tech-debt.md`, which is proposed from, never written to, here.
- **No work is opened** by this skill, and nothing is written under `.aid/works/`; the seed's `## Questions` table is its question record.
- **Full verify**, per `design-lifecycle.md`, unlike a light single-pass check.
- **Iterative, not terminal** -- re-invocation rewrites `## Current direction` and
  accumulates `## Options considered`; the user decides when to stop.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** set the seed's `step:` through `--step --design` at every transition.
