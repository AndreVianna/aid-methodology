# Lean AID: design

Three needs (maintainer, 2026-10-26): small tasks fast and correct; complex tasks on track with no drift,
hallucination, gaps or over-engineering; every change consistent with the project's rules.

Principle: **"is it right" is decided by evidence (tests, checks, the request, the repo), not by opinion.** Evidence
converges; opinions loop. What can be decided by code is done by a script, not written as an instruction.

## What the agent reads (the whole instruction budget)

Always loaded: the project card (stack, commands, where things live, the rules that never bend) and the short rules
file. KB documents are read only when relevant. Hard rules (never merge or push without the user) are hooks.

One entry skill, `/aid-change`, with five rules:

1. **Size the work.** Few files, one capability, no schema, security, data or public-API change: work directly.
   Otherwise write a one-page **goal card** (goal, out of scope, testable criteria from the user's words, budget) and a
   **plan** (milestones; tasks as lines, each tied to a criterion), and get one approval for both.
2. **Tests first.** For a bug, a failing test; for planned work, a different agent writes the criteria's tests.
3. **Build, then run `checks`.** Work in the foreground; nothing depends on a helper outliving the turn.
4. **A finding blocks only with proof:** a request line it breaks or misses, a repo fact (file and line) it
   contradicts, or a failing check's output. Everything else is listed for the user, never looped on.
5. **One fix round.** Not clean after it: stop and show the user, with the evidence. Stopping is escalating, not
   accepting.

Budget: `/aid-change` at most about 100 lines, its review brief at most about 60, held by a test. A new rule is added
only when a benchmark failure needs it, and it replaces or removes something else.

## What scripts do (deterministic, not instructions)

| Script | Does |
|---|---|
| `checks` | Runs the card's build, test and lint commands and the rule checks. Records a baseline on the starting commit (each failing test, its message, and how many tests ran, suites run to the end); afterwards blocks on a new failure, a changed message or fewer tests run; reports pre-existing failures to the user every time |
| `trace` | Every criterion on the goal card has a task and every task names a criterion: gaps and scope creep, found mechanically |
| `red-first` | Runs the new tests on the old code; a test that already passes tests nothing |
| `state` | One small state file (goal, plan checklist, milestones, decisions, budget used), written in one call |

## Where review looks

Two points only, each one pass by an independent reviewer: **plan against request** before building (what `trace`
cannot judge: a criterion that misreads the request), and **result against reality** after each milestone (claims on
the changed pages or code checked against the repo). Never documents against documents. Every finding records whether
it changed the result; a kind of finding that keeps changing nothing is dropped.

Evidence for these choices: `site-run-notes.md` and `site-run-analysis-planning.md` (of 98 planning findings, the 5
that would have changed the site were all checked against the request, the repo or the result; during the build, 10 of
14 content tasks needed a fix found by checking the result against the repo).

## How the design is proven

`tests/measure/` and the brownfield benchmark on this repo (the tags task and the site rework), run plain, with today's
AID and with lean AID. Targets: hidden checks as good or better; about 1.5 to 2 times plain cost; for planned work at
most two approvals (goal card with plan, then the result); most review findings change the result.
