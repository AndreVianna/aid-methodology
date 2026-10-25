# Size and Route

The routing rule, stated once: **the reading decides which phases run; the richness check decides the depth.**

## 1. Which phases run

| Reading | Phases |
|---------|--------|
| Question about the project | none: answered from the Knowledge Base |
| Bug fix, refactor, change, new capability, document -- with a clear problem | Specification -> Planning -> Building -> CI |
| Any reading whose problem is unclear, or a bare idea | Definition (`/aid-brainstorm`) -> Specification -> Planning -> Building -> CI |
| Knowledge update ("we moved to Postgres") | KB update only (Preparation on demand) |
| Investigation -- a check, a prototype, research, a review, a report; nothing lands in the project | the investigating skill -> CI, closed with nothing to land |
| Operational -- release, deploy, monitor | a work of its own, run by its own skill, closed by CI |
| Before the first phase, when an existing codebase has no Knowledge Base | Preparation is offered first |
| Every work | CI closes it |

Definition runs only when the problem itself must be shaped: an idea, or a problem that is
unclear. Missing details in an otherwise clear bug fix, change or capability are asked inside
Specification, through the question rule. They never add Definition.

A reading that matches an action skill -- `/aid-create`, `/aid-update`, `/aid-fix`,
`/aid-refactor`, `/aid-document`, `/aid-test`, `/aid-prototype` -- is sized here first, like any
other reading: Preparation is offered when the project has no Knowledge Base, the phases and the
depth are shown in one line, and only after the user answers is the reading handed to that skill
(SKILL.md steps SIZE-READING to START-ACTION). Its START creates the work through the gate, and the `intent:` record is
written into that work. A typed `/aid-<skill>` still goes straight to that skill.

## 2. How much the user reviews

| Input | Depth |
|-------|-------|
| Objective, users, scope, acceptance criteria and constraints all present. Each counts as present when the request, a source or the Knowledge Base states it, for example a complete ticket | `lite`: one approval before building, plus the final result |
| Any of the five missing | `full`: the user confirms every document |
| Several user-visible capabilities, a data migration, or security-sensitive work | `full`, whatever the input |

Judge the scope before the depth. A request with one concrete target (an endpoint, an entity, a
rule, a document, a page) and one clear action on it is a single well-scoped change. Several
unrelated targets, a whole subsystem, a chain of distinct activities joined by "and", or no
concrete target at all is broad or ambiguous. Broad or ambiguous work is `full`.

## 3. Close

CI closes every work. It closes at minimum by marking the work done. Until `/aid-monitor-pipeline`
exists, this skill does that minimum itself, and only when every task of the work is `Done` (or,
for an investigation, when nothing was to land). It sets the phase to CI, the last one, then the
lifecycle. Both writes name the work, as the cancel step does, so they land on that work and on no other:

```bash
AID_STATE_FILE=<work>/STATE.yml AID_WORK_DIR=<work> bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value CI
AID_STATE_FILE=<work>/STATE.yml AID_WORK_DIR=<work> bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed
```

Push nothing. Pushing is never part of the close.

## 4. Re-routing

When the work turns out bigger or different, re-route it and say so in one line. Write the
re-route into the work's `STATE.yml` at once: append an entry to `intent.changes` with `at`,
`from`, `to` and `why`, and update `intent.phases` and `intent.depth` to match.

## 5. Preparation

When the work needs a Knowledge Base and the project has none, offer Preparation before the first
phase, with a recommendation, under the question rule. The offer goes in the same message as the
reading (SKILL.md step SHOW-READING). Build no Knowledge Base file before the user agrees.

## 6. Start at once, without a go-ahead

Rule 5.3 of the question protocol and the skipped-question rule (AC-28) say not to ask what the user
already settled. So the start-at-once path applies only to `/aid-ask`, `/aid-research`, `/aid-review`,
`/aid-report`, `/aid-monitor` and `/aid-read-ticket`, and only when the user's own words already ask for
exactly that action. Show the reading and its reason in one line and start the skill in the same turn, with no
go-ahead question and no wait: the flow goes on to FIND-OR-CREATE. Every other skill keeps its one
confirmation question, and so does a reading that carries a Preparation offer (section 5): it waits for the
answer. That confirmation is an approval (a yes lets the work start and change the project), so it ends with the
approval closing line, `Or answer in your own words, or ask me to explain.`, never with a skip. The reading goes inside that
go-ahead, never on a separate clarifying question. Clarification precedes the go-ahead only when no reading
can be shown without it. An answer to a clarifying question is a go-ahead only when it names a reading in the
user's own words, and no work is created before the yes. A choice between readings is not a clarifying
question: the go-ahead offers the readings as its options, and the pick is the yes, so no second approval
follows. The approvals inside a listed skill's own run
(aid-review's publish approval, aid-monitor's routing approval, anything that writes outside its own report
or record) are unchanged.

After the yes, or after the one-line start, activate the skill by `.aid/runtime/templates/skill-steps.md`
§ Starting a skill in the same turn. Load its instructions before doing its work.
