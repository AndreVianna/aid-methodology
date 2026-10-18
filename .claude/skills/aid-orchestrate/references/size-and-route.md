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
(SKILL.md steps 3 to 5). Its START creates the work through the gate, and the `intent:` record is
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
for an investigation, when nothing was to land). It sets the phase to the last one, then the
lifecycle. Both writes name the work, as the cancel step does, so they land on that work and on no other:

```bash
AID_STATE_FILE=<work>/STATE.yml AID_WORK_DIR=<work> bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Execute
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
reading (SKILL.md step 4). Build no Knowledge Base file before the user agrees.
