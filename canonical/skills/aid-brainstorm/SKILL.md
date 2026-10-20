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
on resume; it never routes. Which skill and step a work continues at come from its work record
(`.aid/runtime/templates/skill-steps.md`, § State Detection).

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What problem
   or theme do you want to explore?") and wait. The subject may be fuzzy -- an unformed
   problem is exactly this skill's case, so INTAKE never refuses an argument for not being
   a question.
2. **Name the seed.** Because `artifact` is empty, feature-002 §4's `<token>` = `artifact`
   rule does not apply: derive a kebab-case `<slug>` from the subject and state it in the same
   message as your first question about the idea (for example "I'll call the seed
   `note-tagging`; first question: ..."), not as a question of its own. The seed is then
   `.aid/design/<slug>.md`.
3. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-brainstorm` given to the gate's `--create`. `phase` is not driven. The `work-NNN` folder is where
   `STATE.md` and the review gate live, even though the seed is the deliverable.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** CHAIN → DESIGN when the gate allocated a new work; HALT when the user continues an existing work (the gate's § 3b takes it over).

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
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.

**Advance:** CHAIN → PRESENT when the verify is clean; CHAIN → DESIGN when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill), promotes the seed into a `design` lifecycle
entry, or takes it forward however they choose.

Then ask the user to approve the result, through the question protocol. The approval blocks the work, so this step pauses on it (`.aid/runtime/templates/skill-steps.md`, part 3). Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-brainstorm --step PRESENT --covers 'the seed .aid/design/<slug>.md'` (it prints the question's id), bring the step detail up to date with `--step` (done: presented; waiting for that id), and set the lifecycle to `Paused-Awaiting-Input` and the pause reason to that open question through the writer. An approval cannot be skipped: the step stays paused until the user approves or declines. Once it is answered, record the answer with `--answer --id <id> --state Answered --value '<Approved, or Declined with the changes asked>' --applied-to 'the seed .aid/design/<slug>.md'`, set the lifecycle back to `Running` through the writer, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Set the lifecycle to `Completed` through the writer. The seed
persists at `.aid/design/<slug>.md`; brainstorm has no `create` counterpart to consume it.
