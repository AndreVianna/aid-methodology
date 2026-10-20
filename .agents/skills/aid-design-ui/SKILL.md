---
name: aid-design-ui
description: >
  Develop a UI design as a DESIGN SEED in `.aid/design/ui.md` -- the screen/flow structure,
  the interaction model, and accessibility notes. Use this skill when a screen's layout and
  behaviour are still being worked out and you want a design you intend to keep. Grounded in
  the Knowledge Base (`.aid/knowledge/`) and the project source. It WRITES NO production
  code and NO KB document -- realize the seed into the built component/page with
  `/aid-create-ui` once it is ready. For a THROWAWAY low-fidelity mock that merely validates
  a UX direction rather than a kept design, use `/aid-prototype-ui` instead. Produced by the
  aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a
  work-NNN folder.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- the UI screen(s)/flow to design (structure, interaction, accessibility)"
---

# Design UI (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`ui`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.aid/runtime/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/ui.md`; realizing it into
the built component/page is `/aid-create-ui`'s job, not this one's.

- **Boundary vs `/aid-create-ui`:** that skill *builds* the UI from a ready seed; this one
  only *develops* the seed. Neither resolves anything on its own -- the user decides when a
  seed is ready to realize.
- **Boundary vs `/aid-prototype-ui`:** that skill builds a **throwaway** low-fidelity mock
  to *validate* a direction; this one develops a **kept** design meant to *inform the
  build*. Kept vs throwaway is the distinction.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What UI
   screen(s) or flow do you want to design, and what must it support?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-design-ui` given to the gate's `--create`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/ui.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the work record alone decides where a work continues.

**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing work (the gate's § 3b takes it over).

---

## State: DESIGN

Dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/ui.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the screen and flow structure, the
interaction model, and accessibility notes**; its `## Destination` names where the built
component/page lands. **Never writes `.aid/knowledge/` and never writes production code**
-- the `design` invariant (`design-lifecycle.md`).

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now (`/aid-create-ui`).

Then ask the user to approve the result, through the question protocol. The approval blocks the work, so this step pauses on it (`.aid/runtime/templates/skill-steps.md`, part 3). Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-design-ui --step PRESENT --covers 'the seed .aid/design/ui.md'` (it prints the question's id), bring the step detail up to date with `--step` (done: presented; waiting for that id), and set the lifecycle to `Paused-Awaiting-Input` and the pause reason to that open question through the writer. An approval cannot be skipped: the step stays paused until the user approves or declines. Once it is answered, record the answer with `--answer --id <id> --state Answered --value '<Approved, or Declined with the changes asked>' --applied-to 'the seed .aid/design/ui.md'`, set the lifecycle back to `Running` through the writer, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Set the lifecycle to `Completed` through the writer. The seed
persists at `.aid/design/ui.md`; consumption happens at `/aid-create-ui`.
