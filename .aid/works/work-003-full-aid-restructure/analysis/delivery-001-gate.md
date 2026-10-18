# Delivery-001 gate run

Run on `work-003` after the resync commit (`delivery-001: resync`), from the freshly installed
skills (Q150: the session's folder was switched to `work-003` and `/reload-skills` run). Head at the
start of the gate: `cb44bdc8`.

## Stanza criteria

| Criterion | Result | Evidence |
|---|---|---|
| `test-skill-guide.sh` SG-01 to SG-06 | Pass | 17 of 17 checks |
| Samples `001-01` to `001-16`, 3 of 3 each | 5 of 16 pass 3 of 3; the rest recorded in KI-007 (Q149) | Sample results below |
| Template `intent:` and `sources:`, no `ticket_ref` | Pass | `work-state-template.yml` lines 156 and 180; `git grep ticket_ref -- canonical/aid/templates` finds nothing |
| `rules.md` § Tracking discipline names `STATE.yml` (KI-001) | Pass | `canonical/aid/rules.md` line 19 |
| G0 | See G0 below | |

## G0

| Item | Result | Evidence |
|---|---|---|
| `run-all.sh` exits 0 | 162 of 171 suites pass; the 9 failures are this machine's limits | Machine limits below |
| Site `npm test` | Pass | 50 files, 2747 tests |
| Scratch-copy `run_generator.py` matches the live tree | Pass | 0 changed files after the copy's generator |
| `installer-tests.yml` green on the delivery's commits | Pass | Run 1859 on `8ead21e8` (the resync), success |
| AC-22, no acronym in added names | Pass | `aid-orchestrate` |
| AC-24, retired names in the old -> new table | Pass | `backlog.md` W7-16 (`/aid-triage`), W7-17 (`aid-orchestrator`) |
| KB with no work id, `INDEX.md` regenerated | Pass | Regenerated index differs only in its timestamp; the one `work-NNN` text in the KB is a command example in `release-tracking.md`, older than this work |
| Cost baseline re-recorded | Done | Commit `011ca21d`; growth before re-recording was a few characters in skill descriptions and one more skill |
| Coverage baseline re-recorded | Open | 29 un-excused reductions, every one in a machine-limit or environment suite; 42 re-homes excused |
| Samples the stanza names | As above | |
| Earlier static-check groups | Not applicable | Delivery-001 is the first delivery |
| Tracking proof (Q125) | Pass, under the Q151 wording | In Progress then In Review precede each task's own commit; the terminal state and grade sit in a separate state-only commit after it, and parallel waves share one In Progress commit |

### Machine limits

| Cause | Suites |
|---|---|
| Runs as root, so the unwritable-path cases can write | test-aid-provisioning, test-review-cost-meter, test-summarize-preflight |
| No `en_US.UTF-8` locale | test-kb-export, test-kb-html-claims-check, test-review-recall, test-settings-schema-check |
| Playwright not installed for the summarize scripts | test-kb-export, test-visual-fidelity |
| The simulated crash leaves the child alive | test-aid-dashboard-cli |

## Sample results

`python3 tests/conversation/run.py --feature 001 --sample <id> --runs 3`, 4 samples at a time, in the
live tree after the resync. 22 of 48 runs pass (task-369's runs: 23 of 48).

| Sample | task-369 | Gate | Main failure in the gate runs |
|---|---|---|---|
| 001-01 | 2/3 | 1/3 | EO-1, the bug reading without its KB basis |
| 001-02 | 0/3 | 0/3 | EO-1, no read-only investigation workflow named with its reason |
| 001-03 | 3/3 | 1/3 | EO-2 and MN-1, the approval and the clarifying question asked in one turn |
| 001-04 | 3/3 | 3/3 | |
| 001-05 | 2/3 | 3/3 | |
| 001-06 | 1/3 | 3/3 | |
| 001-07 | 0/3 | 0/3 | EO-1 and EO-2, no one-line routing or sizing; once no Skill call |
| 001-08 | 0/3 | 0/3 | EO-2, no sizing as full with its reason |
| 001-09 | 2/3 | 0/3 | EO-3, approval asked twice; EO-2, the fix built by hand without the lite path and CI |
| 001-10 | 0/3 | 0/3 | EO-3, the release closed by hand, not through the write-back and CI |
| 001-11 | 1/3 | 1/3 | EO-4, no one-line statement of how the ticket changed the work |
| 001-12 | 2/3 | 3/3 | |
| 001-13 | 1/3 | 1/3 | MN-1 and EO-3, the project source attached to the work |
| 001-14 | 1/3 | 1/3 | EO-3, the lite path not followed; EO-4, behaviour said to be unchanged |
| 001-15 | 3/3 | 2/3 | EO-1, Preparation not offered before the first question |
| 001-16 | 2/3 | 3/3 | |

Run folders: `.aid/.temp/conversation-tests/<batch>/<sample>/run-<n>/` (not committed).
