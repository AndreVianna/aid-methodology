---
name: aid-design-architecture
description: >
  Develop the system's shape as a DESIGN SEED in `.aid/design/architecture.md` --
  components, boundaries, interactions, invariants, and what is deliberately not a
  component. Use this skill when how the system should be shaped is still being worked out,
  and you want that thinking captured before it is written into the Knowledge Base. Grounded
  in the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO KB document
  and NO production code -- realize the seed into the project's C1 document with
  `/aid-create-architecture` once it is ready. For a subject with no dedicated design row
  use bare `/aid-design`; to write documentation about an existing architecture rather than
  design it, use `/aid-document-architecture`. Produced by the aid-architect agent and
  independently verified by aid-reviewer (full verify).
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- the system/subsystem to design (components, boundaries, interactions, invariants)"
---

# Design Architecture (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`architecture`** -- the `design` *stage* in the
contract's vocabulary -- then follow the shared contract at
`.aid/runtime/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/architecture.md`; realizing
it into the project's C1 document is `/aid-create-architecture`'s job, not this one's.

- **Boundary vs `/aid-create-architecture`:** that skill *realizes* the seed into the C1
  document; this one only *develops* the seed. Neither resolves anything on its own.
- **Boundary vs bare `/aid-design` and `/aid-document-architecture`:** bare `/aid-design`
  is the catch-all for a subject with no dedicated row; `/aid-document-architecture` writes
  *documentation about* an architecture -- the opposite side of the KB write boundary.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What system or
   subsystem do you want to design -- its components, boundaries, and invariants?") and wait: acquire `.aid/design/` first (below), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/architecture.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-design-architecture`, which opens the seed document (`status: draft`) when it does not exist yet, and record the reply with `--answer --design .aid/design/architecture.md --id <id> --state Answered --value '<the reply>'`.
2. **Name the seed; open no work.** The seed is `.aid/design/architecture.md`. This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Record every question with `--ask --design .aid/design/architecture.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/architecture.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/architecture.md` if a
   prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the seed's `step:` and `step_detail:` frontmatter alone decide where a design resumes.

**Advance:** CHAIN → [State: DESIGN].

---

## State: DESIGN

Resolve and confirm the destination first (below); then dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/architecture.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the components, their boundaries and
interactions, the invariants, and what is deliberately NOT a component**.

**Destination resolution (by concern, not filename).** This skill binds concern **C1**
(build & shape, `.aid/runtime/templates/kb-authoring/concern-model.md`), never a hardcoded
filename. Resolve C1 against the project's declared doc-set (`.aid/settings.yml`
`knowledge.doc_set`), falling back to the C1 row of
`.aid/runtime/templates/kb-authoring/domain-doc-matrix.md`, and **confirm the resolution
with the user** before writing. Write the resolved path into the seed's **`## Destination`**
section (required for a class-1 seed). C1's default set holds both `project-structure.md`
and `architecture.md`; this skill resolves to the document describing the system's shape
and **never** `project-structure.md`, which describes the repo layout. Where the
realization is genuinely ambiguous, **ask -- never pick silently**.

**Writes only `.aid/design/architecture.md`.** Never writes `.aid/knowledge/`, never writes
production code -- the `design` invariant (`design-lifecycle.md`).

The destination confirmation is a blocking question, asked before the dispatch writes anything: this step pauses on it until the user answers.

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/architecture.md --detail 'impediment: <reason>'`.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (declining the approval below changes the seed in place) or realizes it now (`/aid-create-architecture`).

Then ask the user to approve the result, through the question protocol, and record the approval on the seed. Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/architecture.md --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-design-architecture` (it prints the question's id, `D<n>`), and bring the step up to date with `--step PRESENT --design .aid/design/architecture.md --detail 'presented; waiting for D<n>'`. An approval cannot be skipped: the step stays open until the user approves or declines. Once it is answered, record the answer with `--answer --design .aid/design/architecture.md --id D<n> --state Answered --value '<Approved, or Declined with the changes asked>'`, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Record the step with `--step DONE --design .aid/design/architecture.md --detail 'approved'`. The seed
persists at `.aid/design/architecture.md`; consumption happens at
`/aid-create-architecture`.
