# Work-003 re-analysis: report

Goal (maintainer, Q208): **AID must be faster, cheaper and less bureaucratic.** Users find every task slow,
token-hungry, and forced through a long process even when it is simple.

Sources: six independent analyses (definition, plan, testing, task cost, feasibility, online research on testing
agent skills, Claude Code's own test tooling) and one independent check that re-measured every key number. Marks:
**[V]** verified by the check, **[E]** estimate with a stated basis.

## 0. Why AID exists (maintainer, 2026-10-26)

1. **Brownfield context.** A project's existing information, constraints, standards, documentation and
   requirements, which a plain prompt to a coding agent ignores: spec-driven development extended with a
   Knowledge Base.
2. **Staying on track in complex work.** Many features, several deliveries, hundreds of atomic tasks, all traced to
   the requirements.
3. **Agents reviewing agents.** Catching drift, hallucination, gaps and over-engineering in another agent's output.

These add overhead by design. The redesign keeps all three and makes each proportional to the task, instead of
applying them at full strength to everything.

## 1. Verdict

Work-003 aims at the wrong target. It reorganizes AID's names, phases and documents and adds new capabilities, but
it does not attack what makes a task slow and expensive. As written, it keeps or raises the cost of a small task.
Its own plan became an example of the problem: too much process, too much text, too many parts.

## 2. What one small task costs today

A one-line bug fix asked in plain words ("the list shows a note twice, fix it"):

| What | Today | Basis |
|---|---|---|
| Process depth | `full` | Any of five details missing means `full` (`rules.md`, `size-and-route.md`) [V] |
| Rules allow a shortcut for small work | No | `rules.md`: "No step of the chosen workflow is skipped"; the engine: "Size never skips a step ... for a one-line change too" [V] |
| Always-loaded rules | 237 lines, 17k characters, **loaded twice** per agent and per helper | `CLAUDE.md` imports it and also orders a Read of it [V] |
| Skill list in every prompt | 114 descriptions, about 50k characters (~12.5k tokens); 78 are kind variants | [V] |
| Base cost of each helper session | about 11-14k tokens before any work | agent file with inlined boilerplate, plus the rules twice [V] |
| AID instructions the main agent loads | up to about 113-140k tokens over two sessions | sizes [V]; an upper bound, some files load only on some paths |
| Helper sessions | 9 (per-task path) to about 11 (pool path), more with each failed review cycle | the check's own trace [V] |
| State-writer calls | about 54-67 | the check's own count [V] |
| Waits for the user before code changes | 2 approvals, plus typing `/aid-execute`, plus possible extra questions | [V] |
| Documents for the fix | a 10-section requirements file, a technical spec, 2 task files, a state file | [V] |
| Just doing it | about 15-30k tokens, no helpers, one approval | [E] |

Defects found on the way, each confirmed [V]:

| # | Defect |
|---|---|
| D1 | The engine assumes a review bar of A+; the installed settings give A, so its A+ logic never runs |
| D2 | The small-task path reads a plan file that the engine never writes |
| D3 | The delivery-level code review runs only in one execution mode; the per-task path never gets it |
| D4 | Helpers are told to dispatch a reviewer, but no agent has the tool to do so |
| D5 | The review instructions call a script that exists only in this repo, not in installed projects |
| D6 | `aid-define` refuses to start unless an old-format interview record exists |
| D7 | `aid-specify` asks "reopen for review?" the first time a spec is finished |
| D8 | The rules forbid skipping any step, whatever the size of the change |

**Honest limit:** no real run has been measured for tokens or time. The cost above is built from instruction sizes
and traced steps. The direction is clear (most of the cost is process); a precise percentage is not supported yet.

## 3. Why work-003 will not reach the goal

### The definition

| Adds process or cost | Where |
|---|---|
| Graded verify, simplify and re-verify after every task and every delivery (today: one quick check per task) | FR-19, Feature 007 |
| Pull-request watching with polling, a three-angle review and correction rebuilds | FR-7, Feature 008 |
| A knowledge-base check at every work start, an update call after tasks and decisions | Feature 004, 005, 007 |
| An effort-level question, an extra business approval, keep/park questions for drafts | FR-15, Feature 005, Feature 003 |
| Every typed command loses today's single pass and goes through the full chain | Feature 009 |

What drives today's cost is barely addressed: the rules loaded twice, the size of the always-loaded text, helper
fan-out, documents for small work, review loops, and the rule that no step may be skipped. Only two parts help:
collapsing 78 kind skills into a few (planned for deliveries 011-012) and the lean-instruction checks (Feature 010,
added late).

### The plan

| Fact | Value |
|---|---|
| Tasks planned / done | 367 / 88 (279 still to do) [V] |
| Ceremony per task | about 4 helper sessions and 4 commits, only one of which builds [E] |
| Order | edit files first, delete them later; the big deletions come last (delivery-012) |
| Instructions since the work began | grew, did not shrink: `rules.md` 115 → 237 lines; all instructions about 43.1k → 44.8k lines [E] |
| Work-folder text vs product change | about 120k lines vs about 9.5k [E] |

### The testing

- Most suites that check skills grep the instruction text for exact wording. That proves nothing about what the
  agent does, and it makes every wording change cost test edits.
- The delivery gate required every one of 30 agent runs to pass. With an agent that passes about 92% of runs, that
  gate fails most of the time by design. (The check notes the failures also cluster on one sample, 002-14, so this
  is a design flaw plus one weak flow, not pure chance.)

## 4. What AID should become

Targets, to be measured on real runs:

| Small fix | Today | Target |
|---|---|---|
| AID instruction text | ~113-140k tokens | under ~5k |
| Helper sessions | 9-11+ | 0, or 1 when a risk flag fires |
| User steps | 2 approvals + typed command | one short confirmation before the edit, one look at the result |
| Documents | 4 + state file | none; one line in the record |
| State-writer calls | ~54-67 | 1-2 |

### The new requirements (about eight, instead of 22)

1. **Three lanes by size and risk**, chosen by a cheap explicit test (files touched, schema, security, public API,
   data, number of capabilities). **Direct** (small fix or change): a one-line confirmation of what will change,
   build, test, show the diff, one record line; no documents; no helper unless a risk flag fires. **Planned**
   (medium): a one-screen plan, one approval, build, one review of the final diff. **Full** (large): requirements and
   plan as today, merged where two skills do one job. The user can always say "plan first".
2. **Token diet:** rules loaded once and under ~100 lines; no skill guide that repeats the host's skill list; kind
   variants become arguments of a few skills; no inlined boilerplate per agent; size limits per file; no history.
3. **Review in proportion:** review code, not paperwork; at most two cycles; one consistent bar (fixes D1).
4. **Fewer stops:** no typed command to start building, no "run the next command" stops, one approval per lane plus
   the result.
5. **Mechanics in scripts:** recording a question prints its form; state written in batches; hooks enforce hard
   rules (never merge, never push).
6. **Fix D1-D8.**
7. **Test behaviour, not wording:**

| Layer | What | When | Pass rule |
|---|---|---|---|
| Scripts and hooks | unit tests of the writer, checkers, hooks | every change | all pass |
| Structure | sizes, links, frontmatter, no history, referenced scripts exist | every change | all pass |
| Routing | does request X start skill Y (first tool call) | when rules or descriptions change | pooled rate vs baseline |
| Scenarios | start from a prepared state, send a fixed reply, check files, state and tool calls by code | changed skills on each change; all nightly | pooled rate vs baseline, with a floor per scenario |
| Judged quality | plain words, reasoned recommendation | nightly or weekly | trend only |
| Simulated user | a few open-ended flows | weekly | read by a human |

   Tools exist: `claude plugin eval` (checks tool calls, order, files, text; cost cap; CI exit codes) and headless
   `claude -p --output-format stream-json`. A pooled gate of about 60 runs catches a real drop from 92% to 80% about
   87% of the time with about 5% false alarms. Delete the wording-grep suites as their checks move to these layers.
   Record cost per run.

**Separate works, later:** knowledge-base automation (Feature 004), verify/simplify (Feature 007), pull-request
watching (Feature 008), the specify/plan merges (Features 005, 006), renames, other domains.

## 5. How to get there

| Phase | What | Done when |
|---|---|---|
| 0 | Measure: token, turn and time capture on real runs of a small fix, a small feature and a large feature | a baseline exists |
| 1 | Token diet and defects: load rules once and cut them, kind variants as arguments, fix D1-D8, drop "no step is skipped" | small-fix tokens fall, measured |
| 2 | Lanes: direct, planned, full | a small fix meets the targets above |
| 3 | Testing: scripts, structure, routing and scenario layers; delete wording-grep suites as they are replaced | the new gate runs on every change |

Each phase is small, built directly (no per-task ceremony), reviewed once, and measured against Phase 0.

**Work-003:** close it, keeping what deliveries 001-003 built (plain-language routing, the question form, banner
removal, retired agents), and open one small work with this definition. Their text growth is cut in Phase 1.

## 6. What the independent check corrected

| Claim | Correction |
|---|---|
| "90-95% of the cost is ceremony" | Direction likely right; the number is not measured |
| "Approvals go from 1 to 2 under the new design" | A plain request already has 2 today; the pull-request question rides on the final approval |
| Helper sessions for a small fix | 9 on the per-task path, about 11 on the pool path (not 11-15) |
| "Approve only the result" for small work | Unsafe: keep a short confirmation before the edit and a minimal record |
| Gate pass chance of 8.8% | Not a true probability; failures cluster on one sample |
