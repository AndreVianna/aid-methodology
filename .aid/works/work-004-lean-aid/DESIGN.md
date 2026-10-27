# Lean AID: design

Three needs (maintainer, 2026-10-26): small tasks fast and correct; complex tasks on track with no drift,
hallucination, gaps or over-engineering; every change consistent with the project's rules.

The principle under all of it: **"is it right" is decided by evidence (tests, project checks, hard rules), not by
opinion.** Evidence converges; opinions loop. Agent review only covers what evidence cannot, with a fixed limit,
and the human decides what is left.

## A. Consistent with the project (all tasks)

| Piece | What it is |
|---|---|
| **Project card** | One page, always loaded: stack, how to build, test and lint, where things live, the top non-negotiable rules. Replaces today's 237-line rules file plus the skill guide |
| **Rule checks** | The project's conventions as scripts, linters, tests and hooks (in this repo: bash/PowerShell parity, tests for every change, no history in the knowledge base). "Follows the project's rules" means these pass |
| **Reference by relevance** | The rest of the knowledge base stays as documents behind a short index; a task loads only the one or two it needs |
| **Hard rules as hooks** | Never push or merge without the user, protected files: blocked by a hook, not hoped for |

## B. Small tasks: the direct lane

Chosen by a cheap size and risk test: few files, one capability, no schema, security, data or public-API change.

1. Read the project card and the relevant code.
2. Say in one line what will change; ask first only when the request is ambiguous or the change is risky.
3. Capture the request as a test (for a bug, a failing test first).
4. Make the change; run the project checks.
5. Self-check the diff against the request: nothing missing, nothing unneeded.
6. Show the diff and the check results; commit on the user's yes.

No documents, no work folder, no helper agents. One independent review only when a risk flag fires.
Target: close to the cost of a plain prompt (today about 100 times more through `/aid-fix`).

## C. Complex tasks: the planned lane

| Risk | Guard |
|---|---|
| **Drift** | A **goal card**, approved once, in the user's words: goal, out of scope, acceptance criteria, budget (time and cost). Every milestone is checked against it. Changing it needs the user's yes, with the cost shown |
| **Gaps** | Each criterion becomes an **acceptance test, written before the code** by a different agent from the builder. A criterion without a passing test is a gap, found mechanically |
| **Hallucination** | Claims are verified by tools: the file exists, the API exists, the test ran. A review finding needs evidence: a failing test, or a cited rule or criterion |
| **Over-engineering** | Every change traces to a criterion. Reviewers check necessity ("remove this"), not only conformance. Each task has a size budget |
| **The fix-and-break loop** | Bounded review: one pass, blocking defects with evidence only, at most one fix round. A fix that breaks a passing check is undone, not patched. Only the fix's own change is re-checked. Over the limit: stop and show the user |
| **Losing control** | The user decides four times: the goal card, the plan, each milestone (progress, budget used, anything outside the goal), the result. Small decisions are taken and listed, not asked |

### Review and tests that converge (draft, from the maintainer's challenge)

Severity is the wrong axis: it mixes proof, impact and taste. A finding is sorted by **evidence and what it touches**:

| Class | When | What happens |
|---|---|---|
| **Blocking** | Proven: a failing test or command, a broken acceptance criterion, a broken written project rule, or a risk category (security, data loss, public API) | Fixed. The finding must carry its proof; a claim with no proof is dropped, not argued |
| **Decision** | Real but not proven to break anything (most of today's "Medium") | The reviewer states the risk if left and the cost to fix. Cheap and local: fixed in the one fix round. Otherwise listed for the user at the milestone, never looped on |
| **Note** | Taste and style (today's "Minor"/"Low") | Never blocks. Fixed only on lines the fix already touches. A note that keeps recurring becomes a lint rule or a card rule, and from then on it is Blocking by rule, not by mood |

Tests are judged by effect, not count:
- written from the acceptance criteria, before the code, by a different agent than the builder;
- each new test must **fail on the old code** (checked by running it), or it tests nothing;
- small mutations of the changed lines must be caught (mutation check on the diff), which measures test strength;
- the review flags tests that are redundant, test wording or internals, or trace to no criterion: **unneeded is a finding**.

Where reviews look (from the site benchmark: 5 of 98 planning findings would have changed the result, and all 5
were checked against the request, the repo or the result; the 93 others compared AID's documents with each other):
- **Before building, plan against request:** every clause of the request maps to a task and every task to a clause.
  An unmapped clause is a gap (blocking); an unmapped task is scope creep (a Decision for the user).
- **After each milestone, result against reality:** the project checks run (build, tests, accessibility, links, names
  of real things), and a reviewer checks the claims the change makes against the repo.
- A finding blocks only when it cites a request line it breaks or misses, a repo fact (file and line) it contradicts,
  or a failing check's output. Criteria come only from the request or the project's written rules, never invented.
- Risky actions get a fixed rule, not a review (for example: move before delete).
- Every finding records whether it changed the result; a review type that keeps changing nothing is dropped.

Gates that can pass: every check a gate uses is run on the starting commit before work begins. A check that already
fails there (environment, flaky, unrelated suites) is recorded as pre-existing and never blocks; a check that cannot
run at all is removed from the gate. A flaky check is re-run once; inconsistent results make it a Note, not a blocker.
A finding that comes back after its fix, or a fix that makes another check fail, stops the loop and goes to the user.

The loop stops by rule: one review pass, one fix round; the second look checks only the fixes and the full test run; a
fix that breaks a passing check is reverted; no new Notes or Decisions in the second look. Thresholds (what "cheap"
means, the size budget) are tuned on the benchmark by counting escaped defects against cost.

Plan: deliveries as vertical slices, each with its criteria and tests; tasks as lines in the plan, not files.
State: one small file, written by script in batches.

## D. How the design is proven

The measurement harness (`tests/measure/measure.py`) and a brownfield benchmark on this repo: a small change and a
complex change, each run with today's AID and with lean AID. Hidden checks grade the repo's rules and the
change's criteria; cost and time are compared. Each build step below must move these numbers.

## E. Build order

1. Foundation: project card, rule checks, hard-rule hooks, the always-loaded diet.
2. The direct lane.
3. Goal card, tests-first, bounded review: the planned lane.
4. The benchmark, before and after.
