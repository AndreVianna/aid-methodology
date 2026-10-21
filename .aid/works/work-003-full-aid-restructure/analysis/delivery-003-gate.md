# Delivery-003 gate run

Run on `work-003` after the resync that followed the gate fix round (`a3dbfe25`, `delivery-003: resync after
the gate fix round`), from the freshly installed skills (`/reload-skills` run by the maintainer). The first
attempt stopped on the samples; Q166 allowed one sample fix round (widened by Q169 and Q170, design approved
under Q171, seed copy fixed under Q172). The cloud session could not log the runner's `claude` in (Q173,
Q174), so the second sample run was made on the maintainer's machine, in WSL Ubuntu, on `e12d2afc`
(`d6d55e6a` plus a `master` merge that changes only the Playwright version in `package.json`).

## Stanza criteria

| Criterion | Result | Evidence |
|---|---|---|
| `test-skill-steps.sh` group S passes and group E still passes: no banner form, no chaining file and no citation of it, no `AskUserQuestion`, no `interviewer` in scope, no delivery-level `qa` write, every asking skill with a sample or a `skill:` row, every reviewer file with `### What to report` | Pass | 67 of 67 checks |
| Samples `002-01` to `002-04` and `002-14` to `002-19` each 3 of 3, judged with `protocol-checks.md` | 002-15 passes 3 of 3 (attempt 1); the other nine fail and are recorded in KI-008 (Q166) | Sample results below |
| Dashboard fixtures: card lines at each phase, during a call, with a missing and an inconsistent record; both readers in parity; SS-07 for `chat-node/` | Pass | `test-dashboard-reader.sh` 850, `test-dashboard-parity.sh` 15, `test-dashboard-parity-h.sh` 117; SS-07 inside `test-skill-steps.sh` |
| G0 | Pass, but for the 9 machine-limit suites | See G0 below |

## G0

| Item | Result | Evidence |
|---|---|---|
| `run-all.sh` | After fix round 2's resync (`aecc8602`): 160 of 176 suites pass. The 16 failures are the 9 machine-limit suites, plus 7 that fail only because this container's `awk` is `mawk` (no `gawk`): `test-conformance-lane-semantics`, `test-domain-doc-matrix`, `test-essence-capture`, `test-harvest-batching`, `test-harvest-coined-terms`, `test-kb-scanner-exclusions`, `test-kb-scanner-scope` | Machine limits as in the delivery-001 gate report. The 7 fail identically on `a3dbfe25`, the commit before this session, where they passed on the earlier container; `harvest-coined-terms.sh` stops with `awk: syntax error` under `mawk`. No script changed in this session |
| Site `npm test` | Pass | 2822 of 2822 (`npx vitest run`) |
| Scratch-copy `run_generator.py` matches the live tree | Pass | `test-dogfood-byte-identity` 625 of 625 after the resync |
| `installer-tests.yml` green on the delivery's commits | Pass | Run 2256 on the resync commit `a3dbfe25`, success |
| AC-22, no acronym in added names | Pass | The delivery adds no skill or agent; the gate fix round adds `test-design-no-work.sh` (167 of 167) |
| AC-24, retired names in the old -> new table | Not applicable | No slash name is retired; `aid-interviewer` is an agent, not a slash name |
| KB with no work id, `INDEX.md` regenerated | Pass | `test-kb-no-work-ids.sh` 5 of 5; the regenerated index differs only in its timestamp |
| Cost baseline re-recorded | Done | Commit `b3727800`, in the first attempt |
| Coverage baseline re-recorded | Done (Q153 method) | Commit `0def8408`. Old-to-new diff: 18 re-homes, 83 accepted removals (69 failure-message variants, 5 deliberate removals), 445 additions; no real coverage loss |
| Earlier static-check groups | Pass | `test-skill-steps.sh` group E inside the 67 checks; `test-never-merges.sh` passes; `test-deferred-tests.sh` 113 of 113 |
| Tracking proof (Q125) | Pass, under the Q151 wording | Tasks 058-081: In Progress, then In Review, then the terminal state |

## Sample results

`python3 tests/conversation/run.py --feature 002 --sample <id> --runs 3`, four samples at a time. Attempt 1
ran in the cloud session after the first resync; attempt 2 ran on the maintainer's machine after the fix
round's resync. Attempt 1 recorded which samples failed, not their run counts.

| Sample | Attempt 1 | Attempt 2 (fix round) | Main failure in attempt 2 | Attempt 3 (fix round 2) | Main failure in attempt 3 |
|---|---|---|---|---|---|
| 002-01 connector question | Fail | 2/3 | PC-5: the go-ahead, an approval, offers "skip this question" | 3/3 |  |
| 002-02 settings groups and breaks | Fail | 1/3 | PC-4: the name question has no recommendation; PC-5: "Keep current value" keeps a placeholder | 3/3 |  |
| 002-03 follow-up, skip answered | Fail | 0/3 | EO-3: `aid-config` asks only the unset settings, so the minimum-grade question is never asked or skipped; PC-5 placeholder option; PC-7 no break between groups once | 2/3 | PC-5 once: the walk offers `none`, `svn`, `mercurial` for a git project and `greenfield` for one with code |
| 002-04 skip, then another user | Fail | 0/3 | PC-10 and PC-4: the follow-up question is shown unrecorded and without a recommendation; twice no `aid-set-connector` call; EO-5 once | 0/3 | PC-10 and PC-4/PC-11: the follow-up offer to run `/aid-set-connector` is still shown unrecorded, twice without the form; no `aid-set-connector` call; EO-5 once |
| 002-14 orchestrate, unsure reading | Fail | 0/3 | PC-10: questions before the work are not written to the design document; once MN-3 (CRITICAL), several questions in one turn; once no `aid-orchestrate` call | Re-run pending (usage limit) |  |
| 002-15 which tracker | 3/3 | Not re-run | | Not re-run |  |
| 002-16 research without a question | Fail | 0/3 | Runs 1 and 3 hit the runner's 600 s limit on one `claude` call (the research skill's review rounds); run 2: PC-5, PC-10, PC-11 on the follow-up "Your call" question; run 3: PC-5(c), the go-ahead is asked although the user had already asked for the research | Re-run pending (usage limit) |  |
| 002-17 review publish approval | Fail | 0/3 | PC-5, PC-10, PC-11: the go-ahead offers a skip, later questions unrecorded and unlabelled; EO-3 once, publish asked without the exact text; twice no `aid-review` call. Nothing was published, pushed or edited in any run | Re-run pending (usage limit) |  |
| 002-18 report what to analyze | Fail | 1/3 | PC-10: the first or the closing question is shown unrecorded; EO-1 once | Re-run pending (usage limit) |  |
| 002-19 monitor finding question | Fail | 0/3 | PC-4, PC-5, PC-10, PC-11: the Turn 2 follow-up has no recommendation, label, closing line or record | Re-run pending (usage limit) |  |

The common cause: the first question of a run follows the protocol, and the follow-up questions later in the
same conversation often do not (no record before shown, no recommendation, no importance label, no closing
line). A second cause is the skill not being started at all: the agent answers by hand.

What the fix round changed (Q166, Q169-Q172):

- **Before a work exists (Q169):** every question asked then is recorded in a design document under
  `.aid/design/` (`--ask --design`, `--answer --design`, ids D1, D2, ...). Design-stage skills open no work.
  Every starter's `--create` passes `--seed`, which moves the questions into the work's `qa`.
- **`--by` removed (Q170):** the writer alone sets `answered_by`.
- **Rule text:** any message that waits on a reply counts as a question; the workflow proposal is one
  confirmation question in the form. `aid-monitor`, `aid-report` and `aid-review` ask in the form and record.
  `aid-config` gained a walk mode; `aid-set-connector` asks no obvious name.
- **Samples:** the 002-16 and 002-18 answer sheets say "say yes and nothing more"; `protocol-checks.md` accepts
  `answered_by: --` and checks for a break only between groups.

## Outcome

Q166 allows one sample fix round. Every sample still failing after it is recorded in KI-008 and re-checked at
the full integration run at delivery-014's gate; it does not block this gate. None of the nine is a
never-merges or other safety sample: 002-17, the nearest, held every `Must not` in all three runs (no publish,
no push, no `src/` edit), and its failures are the form of its questions. The delivery verification ledgers
(`delivery-003-verify-c3.md`, `delivery-003-gfix-verify3.md`) grade A+.

Gate: **passed**, grade A+, with KI-008 open.
