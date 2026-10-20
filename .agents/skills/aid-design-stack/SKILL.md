---
name: aid-design-stack
description: >
  Develop the technology choice as a DESIGN SEED in `.aid/design/stack.md` -- languages,
  runtimes, frameworks, and build and test tooling with versions, plus the alternatives
  rejected and why. Use this skill when which technologies to build on is still an open
  choice. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source. It
  WRITES NO KB document and NO production code -- realize the seed into the project's C0
  document with `/aid-create-stack` once it is ready. To design a configuration option
  within a stack rather than choose the stack, use `/aid-design-config`; for an open
  question with a researchable answer, use `/aid-research`. Produced by the aid-architect
  agent and independently verified by aid-reviewer (full verify).
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- the technology stack to design (languages, runtimes, frameworks, tooling with versions)"
---

# Design Stack (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`stack`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.aid/runtime/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/stack.md`; realizing it into
the project's C0 document is `/aid-create-stack`'s job, not this one's.

- **Boundary vs `/aid-create-stack`:** that skill *realizes* the seed into the C0 document;
  this one only *develops* the seed. Neither resolves anything on its own.
- **Boundary vs `/aid-design-config` and `/aid-research`:** `/aid-design-config` configures
  a chosen stack rather than choosing one; `/aid-research` answers an already-formed question
  -- a decision to make vs a question with an answer.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What technology
   stack do you want to design -- its languages, runtimes, frameworks, and tooling?") and wait: acquire `.aid/design/` first (below), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/stack.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-design-stack`, which opens the seed document (`status: draft`) when it does not exist yet, and record the reply with `--answer --design .aid/design/stack.md --id <id> --state Answered --value '<the reply>'`.
2. **Name the seed; open no work.** The seed is `.aid/design/stack.md`. This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Record every question with `--ask --design .aid/design/stack.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/stack.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/stack.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the seed's `step:` and `step_detail:` frontmatter alone decide where a design resumes.

**Advance:** CHAIN → [State: DESIGN].

---

## State: DESIGN

Resolve and confirm the destination first (below); then dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/stack.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the languages, runtimes, frameworks and
build/test tooling WITH VERSIONS, plus the alternatives rejected and why**.

**Destination resolution (by concern, not filename).** This skill binds concern **C0**
(technology, `.aid/runtime/templates/kb-authoring/concern-model.md`), never a hardcoded
filename. Resolve C0 against `.aid/settings.yml` `knowledge.doc_set`, falling back to the
C0 row of `.aid/runtime/templates/kb-authoring/domain-doc-matrix.md`, and **confirm the
resolution with the user** before writing. This seed records **two destinations** in its
**`## Destination`** section: the resolved C0 document for the chosen stack, and the
project's **D** document (direction/decisions) for the rejected alternatives and their
rationale (§7d). Where a realization is genuinely ambiguous, **ask -- never pick silently**.

**Writes only `.aid/design/stack.md`.** Never writes `.aid/knowledge/`, never writes
production code -- the `design` invariant (`design-lifecycle.md`).

The destination confirmation is a blocking question, asked before the dispatch writes anything: this step pauses on it until the user answers.

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/stack.md --detail 'impediment: <reason>'`.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (declining the approval below changes the seed in place) or realizes it now (`/aid-create-stack`).

Then ask the user to approve the result, through the question protocol, and record the approval on the seed. Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/stack.md --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-design-stack` (it prints the question's id, `D<n>`), and bring the step up to date with `--step PRESENT --design .aid/design/stack.md --detail 'presented; waiting for D<n>'`. An approval cannot be skipped: the step stays open until the user approves or declines. Once it is answered, record the answer with `--answer --design .aid/design/stack.md --id D<n> --state Answered --value '<Approved, or Declined with the changes asked>'`, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Record the step with `--step DONE --design .aid/design/stack.md --detail 'approved'`. The seed
persists at `.aid/design/stack.md`; consumption happens at `/aid-create-stack`.
