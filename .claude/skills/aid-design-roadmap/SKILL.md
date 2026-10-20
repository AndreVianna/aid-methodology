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
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<direction> -- what to develop (committed vs. wanted, sequencing, rejected alternatives)"
---

# Design Roadmap (develop direction as a design seed, resolve nothing)

`/aid-design-roadmap` develops the project's committed direction as a **design seed** in
`.aid/design/roadmap.md`. It is a `design`-stage skill under the shared contract in
`.aid/runtime/templates/design-lifecycle.md`, which this skill binds to and does not
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
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   direction do you want to develop -- what's committed, what's merely wanted, and why?")
   and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work Initiation Gate, whose `--create` is given `--skill aid-design-roadmap`, `--step INTAKE` and `--path lite`; the record starts `Running`. `phase` is not driven.
3. **Acquire `.aid/design/`.** Per `design-lifecycle.md § Before writing a seed` -- ensure
   the folder exists and seed its `README.md` on first use, before writing anything.
4. **Read the existing seed, if one is present.** `.aid/design/roadmap.md` --
   re-invocation iterates the same seed rather than starting over.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the work record alone decides where a work continues.

**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing work (the gate's § 3b takes it over).

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

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to DESIGN; the circuit-breaker there governs escalation to
IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user decides whether to iterate further (declining the approval below changes the seed in place) or realize it now
(`/aid-create-roadmap`).

Then ask the user to approve the result, through the question protocol. The approval blocks the work, so this step pauses on it (`.aid/runtime/templates/skill-steps.md`, part 3). Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-design-roadmap --step PRESENT --covers 'the seed .aid/design/roadmap.md'` (it prints the question's id), bring the step detail up to date with `--step` (done: presented; waiting for that id), and set the lifecycle to `Paused-Awaiting-Input` and the pause reason to that open question through the writer. An approval cannot be skipped: the step stays paused until the user approves or declines. Once it is answered, record the answer with `--answer --id <id> --state Answered --value '<Approved, or Declined with the changes asked>' --applied-to 'the seed .aid/design/roadmap.md'`, set the lifecycle back to `Running` through the writer, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Set the lifecycle to `Completed` through the writer. The seed
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
- **Tracking:** set the STATE lifecycle through the writer at every transition.
