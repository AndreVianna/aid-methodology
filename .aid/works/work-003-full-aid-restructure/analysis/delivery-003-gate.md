# Delivery-003 gate status

**Current outcome: not passed. Delivery grade: Pending.** The historical approval below used
Q166's known-issue exception; Q180, Q186 and Q189 require fresh success on every selected
sample, three runs each. That exception cannot close the current gate.

At the 2026-10-24T20:50Z evidence snapshot:

- Strict attempt 11 ended failed/incomplete after 14 passes. `002-14` run 3 changed the
  same-issue question subject while advancing its counter (PC-8). Its exact batch is
  `20261024T184825Z-codex-user-codex-judge-codex-24029`. Independent inspection confirms
  the existing Rule 8 and shortcut engine were loaded; no conflicting instruction or
  source cause was established. A reviewed pre-send header comparison reinforces that
  rule. Subsequent focused retries exposed premature symptom intake, an incorrect
  answer flag and a prohibited retry after a failed write. Scope ordering and the local
  answer recipe were corrected and reviewed, with an actual writer smoke check.
  An earlier batch failed because recording order could not be proved. Passive raw
  capture is now implemented, independently reviewed and covered by the passing 279/0
  offline regression. Subsequent raw traces establish actual write order; the older
  missing chronology remains unrecoverable. The latest default-profile focused batch,
  `20261024T202557Z-codex-user-codex-judge-codex-147593`, was judged 3/3, but its actual
  audit rejects acceptance: two runs halted after omitting a required directory, and
  one retried the failed write and omitted a recorded approval condition in its display.
  A controlled same-source comparison using the existing model override for all three
  Codex roles (`gpt-6-astra`) passed one trial then failed scope ordering. It does not
  approve a different final profile. The default adapter probe selected `gpt-6.1-sol`
  with no explicit effort value; no low-effort cause is established. No model batch is
  active and no full gate passed. Reviewed source is complete; further wording changes
  are not justified solely by these execution failures. Host-contract diagnosis is
  read-only while a stable source candidate is prepared for final local validation.
- At resync commit `d6cfb5f7bf0d2abc1f8a7061fe45bfbe0a945cce`, the official canonical
  run passed all 178 suites with unchanged defaults. Full site testing passed all 50
  files and 2,822 tests. Scratch generator/install parity passed with an empty tracked
  diff and a separate raw-byte comparison of all 3,513 tracked files. Only four
  platform-specific skip lines remain; native Windows evidence is still owed by CI.
- All 87 current generated site outputs match the tested site run, were independently
  verified and were committed as `c12a0716f343464343528c180aec794d5fd1829c`. That commit
  changes no model instruction, installed payload or test input.
- Official coverage collection executed all 178 suites. Actual supplementary cohorts
  supply the previously missing quiet assertions, native-rg comparison and real
  Playwright-absence checks. Their independently verified maximum-count union has
  10,989 keys and 13,364 emissions across five actual passing datasets. The native
  Windows remote suite passed 50/50 without skips after private runtime preparation.
  An additive malformed-handle assertion exercises the real installed function and
  preserves all 66 existing assertion lines. The reviewed label mappings and stale
  target correction are integrated; the official comparison now passes with 21 rehomes
  and no accepted removals used. Failed runs are excluded from the union. This comparison
  covers the audited source and remote-test addition; final candidate collection and
  coverage/cost baselines remain open as the evidence-capture change proceeds.
- Source reviews are A+ source-only. The earlier research focused run was judged 3/3,
  but its manual decision-ownership finding remains Pending until fresh `002-16`
  evidence proves it. All 30 fresh successes, final candidate validation, report/grade,
  baselines and exact-commit Installer CI remain required. The maintainer's push follows
  completed local preparation. No push or merge has been performed.

Exact current captures, review ledgers and provisioned-runtime evidence are under
`.aid/.temp/runner-codex-checks/` and `.aid/.temp/review-pending/`; the work STATE records
the current step. The historical `002-14` routing success did not prove successful tracking
setup or repair: the agent omitted the required directory creation and truthfully halted.

## Historical gate report — superseded for current closure

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
| 002-14 orchestrate, unsure reading | Fail | 0/3 | PC-10: questions before the work are not written to the design document; once MN-3 (CRITICAL), several questions in one turn; once no `aid-orchestrate` call | 0/3 | EO-1, PC-1, PC-4, PC-5, PC-10, PC-11: the first clarifying question is asked outside the form and unrecorded; once MN-3 (CRITICAL), two questions in one turn; once PC-5, an approval option that drops the test |
| 002-15 which tracker | 3/3 | Not re-run | | Not re-run |  |
| 002-16 research without a question | Fail | 0/3 | Runs 1 and 3 hit the runner's 600 s limit on one `claude` call (the research skill's review rounds); run 2: PC-5, PC-10, PC-11 on the follow-up "Your call" question; run 3: PC-5(c), the go-ahead is asked although the user had already asked for the research | 2/3 | PC-9 once: a skipped scoping question is not recorded `Assumed`. The 1200 s limit held: no run timed out |
| 002-17 review publish approval | Fail | 0/3 | PC-5, PC-10, PC-11: the go-ahead offers a skip, later questions unrecorded and unlabelled; EO-3 once, publish asked without the exact text; twice no `aid-review` call. Nothing was published, pushed or edited in any run | 1/3 | Run 1: MN-2 and MN-3 (CRITICAL): the agent proposed applying code fixes, the simulated user said yes, and the run went through `/aid-fix` and `/aid-execute`, editing `src/` and `tests/` and committing (nothing pushed); run 3: PC-10, the publish question unrecorded |
| 002-18 report what to analyze | Fail | 1/3 | PC-10: the first or the closing question is shown unrecorded; EO-1 once | 1/3 | EO-1 twice: under area C `/aid-report` starts at once and picks the only data file, so the sample's expected question about what to analyze is never asked; PC-5 once, a closing line without "ask me to explain" |
| 002-19 monitor finding question | Fail | 0/3 | PC-4, PC-5, PC-10, PC-11: the Turn 2 follow-up has no recommendation, label, closing line or record | 0/3 | EO-2, PC-4, PC-5, PC-10, PC-11: the no-data question is asked by hand, before `/aid-monitor` runs, outside the form and unrecorded; PC-3 once |

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
