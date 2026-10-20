---
name: aid-brainstorm
description: >
  Shape an unformed idea into a design seed, a written note of framings and candidate
  directions. Use when the problem is still unclear and you need to explore it before
  committing to one direction.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- a fuzzy problem or theme to explore (not yet a formed question)"
---

# Brainstorm (diverge then converge to a design seed, resolve nothing)

Bind **VERB=`brainstorm`**, **ARTIFACT=`` (none)** -- the `design` *stage* in the
contract's vocabulary -- then follow the shared contract at
`.aid/runtime/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. It serves the case `/aid-research` cannot: a problem not yet
formed into a question. It has no `create` counterpart -- the seed it produces is the
whole deliverable, and the user decides where it goes next.

- **Boundary vs `/aid-research`:** that skill answers an already-formed, answerable
  technical question; this one explores a problem that has not yet become one. Unformed vs
  answerable is the distinction (FR-7).
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it.

Steps, advance words, record writes and hand-offs follow `.aid/runtime/templates/skill-steps.md`;
this skill keeps only its own step table.

---

## State: INTAKE

**State Detection.** Detection shapes the entry step of a fresh start and validates a saved step
on resume; it never routes. The step a design resumes at comes from the seed's `step:` and `step_detail:` frontmatter
(`.aid/runtime/templates/skill-steps.md`, § State Detection).

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What problem
   or theme do you want to explore?") and wait: acquire `.aid/design/` first (step 3), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/draft.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-brainstorm`, which opens the provisional document `.aid/design/draft.md` (`status: draft`), and record the reply with `--answer --design .aid/design/draft.md --id D1 --state Answered --value '<the reply>'`; once the reply names the subject, rename that document to the seed (step 2), questions and all. With an argument, no provisional document is needed. The subject may be fuzzy -- an unformed
   problem is exactly this skill's case, so INTAKE never refuses an argument for not being
   a question.
2. **Name the seed.** Because `artifact` is empty, feature-002 §4's `<token>` = `artifact`
   rule does not apply: derive a kebab-case `<slug>` from the subject and state it in the same
   message as your first question about the idea (for example "I'll call the seed
   `note-tagging`; first question: ..."), not as a question of its own. The seed is then
   `.aid/design/<slug>.md`.
3. **Open no work; acquire `.aid/design/`.** This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Acquire `.aid/design/` per the contract, then record every question with `--ask --design .aid/design/<slug>.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/<slug>.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** CHAIN → DESIGN.

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/<slug>.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any prior seed.
It diverges -- framings, angles, prior art -- then converges to the candidate directions
worth pursuing. The seed's `## Destination` is **optional** here: brainstorm has no fixed
destination until the user promotes the seed. **Never writes `.aid/knowledge/` and never
writes production code** -- the `design` invariant (`design-lifecycle.md`).

**Advance:** CHAIN → VERIFY.

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/<slug>.md --detail 'impediment: <reason>'`.

**Advance:** CHAIN → PRESENT when the verify is clean; CHAIN → DESIGN when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (declining the approval below changes the seed in place), promotes the seed into a `design` lifecycle
entry, or takes it forward however they choose.

Then ask the user to approve the result, through the question protocol, and record the approval on the seed. Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/<slug>.md --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-brainstorm` (it prints the question's id, `D<n>`), and bring the step up to date with `--step PRESENT --design .aid/design/<slug>.md --detail 'presented; waiting for D<n>'`. An approval cannot be skipped: the step stays open until the user approves or declines. Once it is answered, record the answer with `--answer --design .aid/design/<slug>.md --id D<n> --state Answered --value '<Approved, or Declined with the changes asked>'`, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Record the step with `--step DONE --design .aid/design/<slug>.md --detail 'approved'`. The seed
persists at `.aid/design/<slug>.md`; brainstorm has no `create` counterpart to consume it.
