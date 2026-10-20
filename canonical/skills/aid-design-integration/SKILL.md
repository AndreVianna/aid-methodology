---
name: aid-design-integration
description: >
  Develop an external-service integration design as a DESIGN SEED in
  `.aid/design/integration.md` -- the external service, the client/adapter surface, and the
  auth and failure modes. Use this skill when how to talk to an external service is still
  being worked out, including how failures should behave. Grounded in the Knowledge Base
  (`.aid/knowledge/`) and the project source. It WRITES NO production code and NO KB
  document -- realize the seed into the built client/adapter with `/aid-create-integration`
  once it is ready. Produced by the aid-architect agent and independently verified by
  aid-reviewer (full verify).
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- the integration to design (service, client surface, auth/failure)"
---

# Design Integration (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`integration`** -- the `design` *stage* in the
contract's vocabulary -- then follow the shared contract at
`.aid/runtime/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/integration.md`; realizing
it into the built client/adapter is `/aid-create-integration`'s job, not this one's.

- **Boundary vs `/aid-create-integration`:** that skill *builds* the client/adapter from a
  ready seed; this one only *develops* the seed. Neither resolves anything on its own --
  the user decides when a seed is ready to realize.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   integration do you want to design -- the service, its client surface, and its auth and
   failure modes?") and wait: acquire `.aid/design/` first (below), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/integration.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-design-integration`, which opens the seed document (`status: draft`) when it does not exist yet, and record the reply with `--answer --design .aid/design/integration.md --id <id> --state Answered --value '<the reply>'`.
2. **Name the seed; open no work.** The seed is `.aid/design/integration.md`. This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Record every question with `--ask --design .aid/design/integration.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/integration.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/integration.md` if a
   prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the seed's `step:` and `step_detail:` frontmatter alone decide where a design resumes.

**Advance:** CHAIN → [State: DESIGN].

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/integration.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the external service, the
client/adapter surface, and the auth and failure modes**; its `## Destination` names where
the built client/adapter lands. **Never writes `.aid/knowledge/` and never writes
production code** -- the `design` invariant (`design-lifecycle.md`).

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/integration.md --detail 'impediment: <reason>'`.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (declining the approval below changes the seed in place) or realizes it now (`/aid-create-integration`).

Then ask the user to approve the result, through the question protocol, and record the approval on the seed. Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/integration.md --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-design-integration` (it prints the question's id, `D<n>`), and bring the step up to date with `--step PRESENT --design .aid/design/integration.md --detail 'presented; waiting for D<n>'`. An approval cannot be skipped: the step stays open until the user approves or declines. Once it is answered, record the answer with `--answer --design .aid/design/integration.md --id D<n> --state Answered --value '<Approved, or Declined with the changes asked>'`, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Record the step with `--step DONE --design .aid/design/integration.md --detail 'approved'`. The seed
persists at `.aid/design/integration.md`; consumption happens at `/aid-create-integration`.
