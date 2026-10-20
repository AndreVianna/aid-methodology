# Delivery-003 gate fix round: design

The one sample fix round of Q166, widened by Q169 and Q170. Nothing is built until this is approved.

## Area A: questions before a work exists (Q169, backlog W7-19)

| Part | Change |
|---|---|
| Where the record lives | The design seed in `.aid/design/<subject>.md` gets a `## Questions` table: id, question, answer, state. A question asked before any seed exists opens one (`.aid/design/<slug>.md`) |
| Writer | `writeback-state.sh --ask/--answer --design <file>` writes that table, so the record is still "before shown" and still made by a script |
| Design and brainstorm skills | Open no work. They write only their seed. Their "Allocates a work-NNN folder" line goes |
| Taking the seed into a work | `--create --seed <file>` adds the seed to the work's `sources:` and copies its questions into the work's qa with their ids kept |
| Rule text | One wording, the same in `rules.md`, `skill-steps.md`, `question-protocol.md`, `protocol-checks.md`; `design-lifecycle.md` states the model |
| Test | A suite runs a design skill's writes and asserts `.aid/works/` is unchanged; writer tests for `--design` and `--seed` |
| Samples | 002-16 and 002-18 expect the design-file record |

## Area B: `--by` removed (Q170)

Remove it from `writeback-state.sh` (option, parse, help) and from `aid-describe/references/state-q-and-a.md`. A test asserts the writer rejects it.

## Area C: root causes 1 and 2

| Fix | Where |
|---|---|
| Say what counts as a question: any message that waits on the user's reply, including the go-ahead | `rules.md` "Asking the user" |
| The one-line proposal is asked as one confirmation question in the form | `rules.md` Handling a request, line 83 |
| No data source: one question in the form | `aid-monitor` `state-observe.md` |
| The closing question asked in the form and recorded | `aid-report` and `aid-review` `SKILL.md` |
| Walk mode: groups of 3-5, a break offered between groups, each question recorded, skipped ones offered again | `aid-config` |

## Area D: smaller fixes

- Answer sheets in 002-16 and 002-18: "say yes and nothing more".
- `protocol-checks.md`: stop reading `answered_by: --` as a failure; the break check applies only between groups.
- `aid-set-connector`: drop the name question when the name is obvious; offer only usable connection types.

## How it runs

| Step | Who |
|---|---|
| Build, one Sonnet fixer per area (A, B, C, D) in worktrees | Sonnet |
| Review, then verify, capped by Q166 | Opus review, Sonnet fix |
| Resync, then the user runs `/reload-skills` | Me, then the user |
| Re-run the 9 failing samples, 3 runs each; still failing becomes a known issue for delivery-014 | Me |
| G0, gate report, delivery-003 Gated and Done | Me |
