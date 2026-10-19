---
name: aid-design-testing-strategy
description: >
  Develop the testing policy as a DESIGN SEED in `.aid/design/testing-strategy.md` -- test
  levels, coverage expectations, which gates block a merge, and who may waive one. Use this
  skill when how the project should be tested is still being decided, rather than which
  tests to write. Grounded in the Knowledge Base (`.aid/knowledge/`) and the project source.
  It WRITES NO KB document and NO test code -- realize the seed into the project's C6
  document(s) with `/aid-create-testing-strategy` once it is ready. To design a specific set
  of tests rather than the policy, use `/aid-design-test`; to RUN existing suites, use
  `/aid-test`. Produced by the aid-architect agent and independently verified by
  aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- the testing policy to design (levels, coverage, merge-blocking gates, waivers)"
---

# Design Testing Strategy (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`testing-strategy`** -- the `design` *stage* in the
contract's vocabulary -- then follow the shared contract at
`.aid/runtime/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/testing-strategy.md`;
realizing it into the project's C6 document(s) is `/aid-create-testing-strategy`'s job, not
this one's.

- **Boundary vs `/aid-create-testing-strategy`:** that skill *realizes* the seed into the
  C6 document(s); this one only *develops* the seed. Neither resolves anything on its own.
- **Boundary vs `/aid-design-test` and `/aid-test`:** `/aid-design-test` designs specific
  tests, not the policy; `/aid-test` *runs* existing suites rather than designing them.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`
entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What testing
   policy do you want to design -- its levels, coverage expectations, and merge-blocking
   gates?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agents/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `--skill aid-design-testing-strategy` given to the gate's `--create`. `phase` is not driven.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/testing-strategy.md`
   if a prior seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the work record alone decides where a work continues.

**Advance:** CHAIN -> [State: DESIGN].

---

## State: DESIGN

Resolve and confirm the destination first (below); then dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/testing-strategy.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the test levels, coverage expectations,
which gates block a merge, and who may waive one**.

**Destination resolution (by concern, not filename).** This skill binds concern **C6**
(quality & testing, `.aid/runtime/templates/kb-authoring/concern-model.md`), never a
hardcoded filename. Resolve C6 against `.aid/settings.yml` `knowledge.doc_set`, falling
back to the C6 row of `.aid/runtime/templates/kb-authoring/domain-doc-matrix.md`, and
**confirm the resolution with the user** before writing. C6 can be realized by two
documents; where it is, the seed's **`## Destination`** section records the **test-landscape
half** (the levels/coverage record) and the **gate-policy half** (the merge-blocking gates
and waivers) **separately** -- on this repository that is `test-landscape.md` and
`quality-gates.md`. Where a realization is genuinely ambiguous, **ask -- never pick
silently**.

**Writes only `.aid/design/testing-strategy.md`.** Never writes `.aid/knowledge/`, never
writes test code -- the `design` invariant (`design-lifecycle.md`).

The destination confirmation is a blocking question, asked before the dispatch writes anything: this step pauses on it until the user answers.

**Advance:** CHAIN -> [State: VERIFY].

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.

**Advance:** CHAIN -> [State: PRESENT] when the verify is clean; CHAIN -> [State: DESIGN] when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Set the lifecycle to `Paused-Awaiting-Input` through the writer. Present the seed clearly. Assert no resolution --
the user iterates (re-invoke this skill) or realizes it now
(`/aid-create-testing-strategy`).

**Advance:** ASK -> [State: DONE].

---

## State: DONE

Set the lifecycle to `Completed` through the writer. The seed
persists at `.aid/design/testing-strategy.md`; consumption happens at
`/aid-create-testing-strategy`.
