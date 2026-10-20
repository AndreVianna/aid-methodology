# Delivery-002 gate run

Run on `work-003` after the fourth resync (`462e5db2`, `delivery-002: resync`), from the freshly
installed skills (`/reload-skills` run after each resync). Three earlier attempts stopped on the samples;
their fixes are Q163, Q164 and Q165, each followed by its own resync.

## Stanza criteria

| Criterion | Result | Evidence |
|---|---|---|
| `test-skill-steps.sh` group E | Pass | 51 of 51 checks |
| `test-never-merges.sh` NM-01 to NM-04, only the `aid-housekeep` and `aid-execute` exemptions | Pass | 8 of 8 checks |
| `test-writeback-state.sh`, every new mode | Pass | 707 of 707 checks |
| `test-work-initiation-gate.sh`, a `--check` fixture per resume-table row | Pass | 129 of 129 checks |
| Both dashboard readers map old and new phase names, parity | Pass | `test-dashboard-reader.sh` 837, `test-dashboard-parity.sh` 15, `test-dashboard-parity-h.sh` 117 |
| `test_home_stage_rails.mjs` | Pass | 5 of 5 |
| `flow-advance.test.mjs` | Pass | In the site run, 2822 of 2822 |
| Samples `002-05`, `002-20`, `002-21`, 3 of 3 each | Pass | Sample results below |
| Every other Feature 002 sample has a `deferred.tsv` row, DT-01 passes | Pass | `test-deferred-tests.sh` 21 of 21 |
| G0 | Pass | See G0 below |

## G0

| Item | Result | Evidence |
|---|---|---|
| `run-all.sh` | 165 of 175 suites pass; the 9 failures are this machine's limits, and `test-chat-node-federation.sh` passes alone (it fails only under parallel load) | Machine limits as in the delivery-001 gate report |
| Site `npm test` | Pass | 2822 tests |
| Scratch-copy `run_generator.py` matches the live tree | Pass | 0 changed files after the copy's generator |
| `installer-tests.yml` green on the delivery's commits | Pass | Run 2115 on `22accd66`, which carries the fourth resync, success |
| AC-22, no acronym in added names | Pass | No skill or agent is added; the new files are `question-protocol.md`, `skill-steps.md`, `project-state-template.yml` and four step references |
| AC-24, retired names in the old -> new table | Not applicable | No slash name is retired (`aid-describe --reset` is a flag) |
| KB with no work id, `INDEX.md` regenerated | Pass | `test-kb-no-work-ids.sh` passes; the regenerated index differs only in its timestamp |
| Cost baseline re-recorded | Done | Commits `43b768f2` and `55b1aee3`; growth is the two new shared rule files and the step rules each skill now carries |
| Coverage baseline re-recorded | Done (Q153 method) | Commit `5dc5472b`. Old-to-new diff passes: 84 re-homes, 13 accepted removals (failure-message variants), 549 additions. 103 assertions that cannot run here keep their earlier count |
| Earlier static-check groups | Pass | `test-skill-guide.sh` SG-01 to SG-06 |
| Tracking proof (Q125) | Pass, under the Q151 wording | All 40 tasks: In Progress, then In Review, then the terminal state; every task grade A+ |

## Sample results

`python3 tests/conversation/run.py --feature 002 --sample <id> --runs 3`, four samples at a time, in the
live tree after each resync.

| Sample | Attempt 1 | Attempt 2 (Q163) | Attempt 3 (Q164) | Attempt 4 (Q165) |
|---|---|---|---|---|
| 002-05 merge request declined | 1/3 | 3/3 | 3/3 | 3/3 |
| 002-20 record recovery | 0/3 | 0/3 | 0/3 | 3/3 |
| 002-21 cancel a work | 3/3 | 2/3 | 2/3 | 3/3 |
| 002-21b resume a canceled work (not a gate sample) | 0/3 | 0/3 | 3/3 | 3/3 |

What each round fixed:

- **Q163:** never-merges holds when the user asks; a finished work is only reported; the repair question
  is asked alone; `aid-specify` maps a lost specification to CONTINUE; 002-20 expects the first pending
  section, not its write. The runner gained `on-branch:`, so 002-20 starts on the work's own branch.
- **Q164:** nothing is written before the repair's yes, and the question names no step; a finished work is
  never reopened.
- **Q165:** a resume validates the saved step before it writes `--step`; a "carry on" request goes through
  `/aid-orchestrate`; a proposed workflow carries a recommendation. 002-20 no longer rules on banners,
  which the AC-37 no-banner clause leaves to delivery-003.
