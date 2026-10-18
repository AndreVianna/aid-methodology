# Delivery-001 Feature 001 sample runs (task-369)

Runs: `python3 tests/conversation/run.py --feature 001 --sample <id> --runs 3` in a scratch copy made after its own generator (`run_generator.py`, then the resync commit). Agent model per run: `claude-sonnet-5-5` (`model.txt` in run-3 folders; run-1/run-2 folders hold the same default). Run folders: `/tmp/t369-jAIu/c/.aid/.temp/conversation-tests/<batch>/<sample>/run-<n>/`. The batch id is per invocation; the batch column gives it for each sample.

Cause classes: PRODUCT (agent behaviour against a clear expectation), HARNESS (run.py, simulated user, judge), SAMPLE (sample or fixture wrong). `EO-n` = Expected outcome item, `MN-n` = Must not item, `check` = a Checks line in `checks.txt`.

## Per-sample results

| Sample | Covered AC | Run 1 | Run 2 | Run 3 | Pass | Batch (run folder base) |
|---|---|---|---|---|---|---|
| 001-01-one-match | AC-1 | PASS | PASS | FAIL: PRODUCT -- EO-1, KB basis for the bug reading not stated | 2/3 | 20261018T074506Z-claude-code-1920 |
| 001-02-several-decide | AC-2 | FAIL: PRODUCT -- EO-1, no workflow named or reasoned | FAIL: PRODUCT -- EO-1, no workflow named; MN-1, asks the user to pick from A/B/C | FAIL: PRODUCT -- EO-1, no workflow named or reasoned | 0/3 | 20261018T074611Z-claude-code-13313 |
| 001-03-several-ask | AC-2 | PASS | FAIL: PRODUCT -- MN-1, two questions in one turn | FAIL: PRODUCT -- EO-2, second question widens the choice | 1/3 | 20261018T075030Z-claude-code-30926 |
| 001-04-no-match | AC-3 | PASS | PASS | PASS | 3/3 | 20261018T075152Z-claude-code-2826 |
| 001-05-project-question | AC-4 | PASS | PASS | FAIL: PRODUCT (borderline) -- EO-1, unsupported "notes.csv if one is produced" added to a KB answer | 2/3 | 20261018T074506Z-claude-code-1919 |
| 001-06-kb-conflict | AC-5 | FAIL: PRODUCT -- EO-1 and EO-2, conflict settled by the agent, "nothing else persisted" not surfaced | FAIL: PRODUCT -- EO-2, conflict not put to the user, SQLite plan chosen alone | PASS | 1/3 | 20261018T074620Z-claude-code-15379 |
| 001-07-rich-ticket | AC-7, AC-21 | FAIL: PRODUCT -- EO-4 and MN-2, two approval requests before building | FAIL: PRODUCT -- check `tool-called Skill` no match; EO-3, no Skill call; EO-4 | FAIL: PRODUCT -- EO-4 and MN-2, two approval requests | 0/3 | 20261018T074752Z-claude-code-22275 |
| 001-08-bare-idea | AC-7 | FAIL: PRODUCT -- EO-2, sized lite, not full | FAIL: PRODUCT -- EO-1 and EO-3, no question before drafting, seven questions listed at once; EO-2 sized lite | FAIL: PRODUCT -- EO-2, sized lite | 0/3 | 20261018T074949Z-claude-code-27953 |
| 001-09-bug-fix-phases | AC-14 | FAIL: HARNESS -- judge row EO-1 is marked Pending while its own text says the item is met ("no row is warranted") | FAIL: PRODUCT -- EO-2, no Specification/Planning/Building/CI steps; EO-4, no reproduction before the edit | FAIL: PRODUCT -- EO-2, no CI step; EO-3, second approval request | 0/3 | 20261018T074506Z-claude-code-1918 |
| 001-10-release-own-work | AC-14 | FAIL: PRODUCT -- EO-4, approval and questions asked three times | FAIL: HARNESS + PRODUCT -- check `no-push` false positive (run.py:630, prose "git push" inside a heredoc; no real push, see note H-1); EO-3, delivery gate skipped | FAIL: PRODUCT -- check `tool-called Bash *writeback-state.sh*Lifecycle*Completed*` no match (lifecycle set by an inline Python edit); EO-3 | 0/3 | 20261018T075536Z-claude-code-8637 |
| 001-11-ticket-mid-work | AC-29 | FAIL: PRODUCT -- check `ref:`/`kind: ticket` no match; EO-2, ticket added as a bare string, not a `ref`/`kind` entry | PASS | FAIL: PRODUCT -- same as run 1 | 1/3 | 20261018T080540Z-claude-code-18554 |
| 001-12-write-back-limit | AC-29 | FAIL: PRODUCT (borderline) -- EO-2, recommendation weak and partly inconsistent | PASS | PASS | 2/3 | 20261018T080817Z-claude-code-22807 |
| 001-13-project-source-unattached | AC-29 | PASS | FAIL: PRODUCT -- MN-1 and EO-3, payments project source added to the work's `sources:` in Turn 1, undone only on user request | FAIL: PRODUCT -- same as run 2 | 1/3 | 20261018T074506Z-claude-code-1921 |
| 001-14-refactor-is-new-capability | AC-1 | PASS | FAIL: PRODUCT (borderline) -- EO-2, reading given as a paragraph, not one line | PASS | 2/3 | 20261018T074748Z-claude-code-20816 |
| 001-15-no-kb-offers-preparation | AC-14 | PASS | PASS | PASS | 3/3 | 20261018T080957Z-claude-code-26806 |
| 001-16-work-closes-done | AC-14 | PASS | FAIL: PRODUCT -- EO-1, work closed by `writeback-state.sh` directly, no closing step, no `lifecycle_history` entry | PASS | 2/3 | 20261018T081311Z-claude-code-30928 |

## Totals

- 3/3 passing: 2 (001-04, 001-15)
- 2/3 passing: 5 (001-01, 001-05, 001-12, 001-14, 001-16)
- 1/3 passing: 4 (001-03, 001-06, 001-11, 001-13)
- 0/3 passing: 5 (001-02, 001-07, 001-08, 001-09, 001-10)
- Runs: 48. Passing 20, failing 28. Failing runs by cause: 26 PRODUCT only, 1 HARNESS only (001-09 run 1), 1 HARNESS + PRODUCT (001-10 run 2).
- SAMPLE: no failing run has a SAMPLE cause.

## Harness notes

- H-1 `tests/conversation/run.py:630`: the `no-push` check is `re.search(r"\bgit\b.*\bpush\b", command)` applied to the whole Bash command text. It matches prose on one line of a heredoc body. In 001-10 run 2 the only occurrence of "git push" is inside a Python heredoc that edits `REQUIREMENTS.md` ("...no `git push` was run."); the transcript has no real push command. The check should match a command word, not any text, for example by matching against the command lines outside heredoc bodies.
- H-2 Judge (`tests/conversation/judge.md` line 38 rule: "An item the run met gets no row"): in 001-09 run 1 the judge wrote a Pending row for EO-1 and its own text says "met in substance ... no row is warranted". The run was failed on this row alone. The judge output contradicts its rule.
- Latent SAMPLE fragility (not the cause of any failure here): 001-11 checks use single quotes, `ref: 'tickets/PROJ-42.md'`, while `canonical/aid/templates/work-state-template.yml` says only "(quoted)". A correct double-quoted `ref` would fail the check.

## Known issue

The product-behaviour failures are recorded as one entry in `known-issues.md` (KI-007), to be re-checked at the full integration run at delivery-014's gate. Not written here; see the task report.

## Identity check

No credential, email address or session URL is in this file.
