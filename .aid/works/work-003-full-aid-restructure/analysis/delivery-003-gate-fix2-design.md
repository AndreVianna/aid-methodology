# Delivery-003 gate fix round 2: design

The second sample fix round, asked for under Q175 (it overrides Q166's one-round cap for this gate). It
answers the attempt-2 results in `delivery-003-gate.md`. Nothing is built until this design is approved.

## A: an approval offers no skip (002-01, 002-17)

The form shows one closing line, with "skip this question", and agents copy it onto approvals.

| Change | Where |
|---|---|
| The form shows two closing lines: the question line, and the approval line `Or answer in your own words, or ask me to explain.` with "use this one for an approval (a go-ahead, a yes before building, a document approval)" | `canonical/aid/templates/question-protocol.md` § One question; `canonical/aid/rules.md` § Asking the user |
| Every site that shows an approval with the skip line takes the approval line | the go-ahead and approval prompts among the 30 `skip this question` sites in `canonical/` (for example `work-initiation-gate.md`, `shortcut-engine.md`, `aid-detail/references/confirm.md`); plain questions keep their line |
| `protocol-checks.md` PC-5(e) quotes the approval line | `tests/conversation/protocol-checks.md` |

## B: `aid-config` asks every setting, and never offers a placeholder (002-02, 002-03)

| Change | Where |
|---|---|
| The walk covers all six settings, in the two groups it already has; a setting that is set and sensible is asked with its current value as the recommendation | `canonical/skills/aid-config/SKILL.md` Mode 1 Step 3 |
| `Keep current value` is never offered for a `⚠ unset` value; `name` and `description` then ask for the user's own words, with no numbered option | Mode 1 Step 3, Mode 2 Step 4 and the Suggestions note |
| The go-ahead and the walk are one subject: no break is offered between them | Mode 1 Step 3 |

## C: no go-ahead for what the user already asked for (002-16, 002-19); the skill is always started (002-04, 002-14, 002-17)

| Change | Where |
|---|---|
| When the user's own words ask for exactly the matched skill's action and it changes no project source (review this, research that, check production, report on this), start it at once and say so in one line; any other match keeps the one confirmation question | `canonical/aid/rules.md` § Handling a request; `aid-orchestrate` SHOW-READING note |
| After the yes (or the one-line start), the skill is started with its slash command or the Skill tool; its work is never done by hand | the same rules bullet |

Basis: AC-28 ("answered or trivial questions skipped") and question-protocol Rule 5.3 (no obvious
questions). A request that builds or changes code still needs its approval (AC-10).

## D: every question, not only the first, gets the form and its record (002-04, 14, 16, 17, 18, 19)

| Change | Where |
|---|---|
| One end-of-turn check: before ending a turn that waits on the user, the message has the form's first line with its importance, `Why I ask`, `My recommendation`, the closing line, and its `--ask` ran first. A closing or follow-up question ("Your call", "which would you like?", "fix them now?") is a question | `canonical/aid/rules.md` § Asking the user; `question-protocol.md` |
| The closing and follow-up questions named in the ledgers are written out in the form, with their `--ask` line | `aid-research` (the impediment "Your call"), `aid-monitor` `state-observe.md` (the Turn 2 data request), `aid-review` (fix now or later), `aid-set-connector` (the follow-up offer), `aid-report` (the closing follow-up) |

## E: the runner's per-call limit (002-16)

Two of 002-16's three runs stopped on the 600 s limit of one `claude` call, while the research skill ran its
review rounds. `TURN_TIMEOUT` in `tests/conversation/run.py` rises to 1200 s, with its docstring line.

## How it runs

| Step | Who |
|---|---|
| Build A-E, one Sonnet builder per area, in the `work-003` worktree | `aid-developer` (Q141) |
| Tests: the suites that assert changed text, then the full suite | main conversation |
| Review: one Opus review of the round's diff, one fix round, one verify (Q166 cap) | `aid-reviewer` |
| Resync, committed alone | main conversation |
| `/reload-skills`, then the 9 samples, 3 runs each, on the maintainer's machine | maintainer |
| Gate report attempt 3, then close (still-failing samples go to KI-008) | main conversation |
