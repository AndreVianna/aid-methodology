---
name: aid-design-cicd
description: >
  Develop the delivery pipeline as a DESIGN SEED in `.aid/design/cicd.md` -- stages,
  triggers, environments, promotion, and release flow. Use this skill when how the project
  should be built, gated and shipped is still being worked out. Grounded in the Knowledge
  Base (`.aid/knowledge/`) and the project source. It WRITES NO KB document, NO production
  code, and NO workflow file -- realize the seed into the project's C8 document with
  `/aid-create-cicd` once it is ready. To design a resource the pipeline ships to, use
  `/aid-design-infra`; to design a data pipeline rather than a delivery one, use
  `/aid-design-data-pipeline`; to ship a built artifact now, use `/aid-deploy`. Produced by
  the aid-architect agent and independently verified by aid-reviewer (full verify).
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- the delivery pipeline to design (stages, triggers, environments, promotion)"
---

# Design CI/CD (develop a design seed, resolve nothing)

Bind **VERB=`design`**, **ARTIFACT=`cicd`** -- the `design` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.aid/runtime/templates/design-lifecycle.md`. This skill binds that contract and
restates none of its rules. The seed it writes is `.aid/design/cicd.md`; realizing it into
the project's C8 document is `/aid-create-cicd`'s job, not this one's.

- **Boundary vs `/aid-create-cicd`:** that skill *realizes* the seed into the C8 document;
  this one only *develops* the seed. Neither resolves anything on its own.
- **Boundary vs `/aid-design-infra`, `/aid-design-data-pipeline` and `/aid-deploy`:**
  `/aid-design-infra` designs a resource the pipeline ships to; `/aid-design-data-pipeline`
  designs a *data* pipeline, not a delivery one; `/aid-deploy` ships a built artifact.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Step rules:** the advance words, the step procedure and the work record are
  `.aid/runtime/templates/skill-steps.md`; this skill cites it and restates none of it.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

State machine: **INTAKE -> DESIGN -> VERIFY (loop) -> PRESENT [user decides] -> DONE**, as
`design-lifecycle.md § Skill shape` defines it.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What delivery
   pipeline do you want to design -- its stages, triggers, environments, and promotion
   flow?") and wait: acquire `.aid/design/` first (below), then record the question with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/cicd.md --category Scope --impact High --context '<the question, as shown>' --suggested '<your suggestion>' --asked-by aid-design-cicd`, which opens the seed document (`status: draft`) when it does not exist yet, and record the reply with `--answer --design .aid/design/cicd.md --id <id> --state Answered --value '<the reply>'`.
2. **Name the seed; open no work.** The seed is `.aid/design/cicd.md`. This skill allocates nothing through the Work Initiation Gate and writes nothing under `.aid/works/`: a work is opened later, by a build skill or `/aid-orchestrate`, which takes the seed into it. Record every question with `--ask --design .aid/design/cicd.md` and its reply with `--answer --design`, and track the step with `--step INTAKE --design .aid/design/cicd.md`, all through `.aid/runtime/scripts/execute/writeback-state.sh`.
3. **Acquire `.aid/design/`** per the contract, then read `.aid/design/cicd.md` if a prior
   seed exists -- re-invocation iterates it rather than starting over.
4. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**State Detection** (`.aid/runtime/templates/skill-steps.md`): detection shapes the entry
step of a fresh start (a prior seed in `.aid/design/` is iterated, not restarted), validates a
saved step on resume, and never routes; the seed's `step:` and `step_detail:` frontmatter alone decide where a design resumes.

**Advance:** CHAIN → [State: DESIGN].

---

## State: DESIGN

Resolve and confirm the destination first (below); then dispatch **`aid-architect`** (clean context, tiered) to write or iterate
`.aid/design/cicd.md` in the seed shape the contract fixes (`design-seed.md`;
feature-002 §4), grounded in `.aid/knowledge/` and the project source plus any seed read
in INTAKE. What this artifact's seed must settle: **the pipeline stages, triggers,
environments, and promotion and release flow**.

**Destination resolution (by concern, not filename).** This skill binds concern **C8**
(shipping & operation, `.aid/runtime/templates/kb-authoring/concern-model.md`), never a
hardcoded filename. Resolve C8 against `.aid/settings.yml` `knowledge.doc_set`, falling
back to the C8 row of `.aid/runtime/templates/kb-authoring/domain-doc-matrix.md`, and
**confirm the resolution with the user** before writing. Write the resolved path into the
seed's **`## Destination`** section. Where a realization is genuinely ambiguous, **ask --
never pick silently**.

**Writes only `.aid/design/cicd.md`.** Never writes `.aid/knowledge/`, never writes
production code, and **never writes a workflow file under `.github/`** -- the `design`
invariant (`design-lifecycle.md`).

The destination confirmation is a blocking question, asked before the dispatch writes anything: this step pauses on it until the user answers.

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to DESIGN; the
3-cycle circuit breaker there escalates to IMPEDIMENT, and the impediment is recorded with `--step VERIFY --design .aid/design/cicd.md --detail 'impediment: <reason>'`.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewer than 3 cycles have run; HALT when the 3-cycle circuit breaker has tripped.

---

## State: PRESENT (hard stop -- the user decides)

Present the seed clearly. Assert no resolution --
the user iterates (declining the approval below changes the seed in place) or realizes it now (`/aid-create-cicd`).

Then ask the user to approve the result, through the question protocol, and record the approval on the seed. Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design .aid/design/cicd.md --category Approval --impact High --context '<the approval, as shown>' --suggested 'Approve' --asked-by aid-design-cicd` (it prints the question's id, `D<n>`), and bring the step up to date with `--step PRESENT --design .aid/design/cicd.md --detail 'presented; waiting for D<n>'`. An approval cannot be skipped: the step stays open until the user approves or declines. Once it is answered, record the answer with `--answer --design .aid/design/cicd.md --id D<n> --state Answered --value '<Approved, or Declined with the changes asked>'`, and end the step with the advance below.
If the user declines or asks for changes, DESIGN iterates the seed with exactly what was asked, and VERIFY and this step run again.

**Advance:** CHAIN → DONE when the user approves; CHAIN → DESIGN when the user declines or asks for changes.

---

## State: DONE

Record the step with `--step DONE --design .aid/design/cicd.md --detail 'approved'`. The seed
persists at `.aid/design/cicd.md`; consumption happens at `/aid-create-cicd`.
