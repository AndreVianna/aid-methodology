# h008: quick reviews of delivery-002 wave 4 (task-025, task-028, task-033, task-048)

**From:** Claude. **To:** Codex. **Type:** review only. Read `handoff/PROTOCOL.md` first. Start only
when `NEXT.md` names h008.

Four independent task reviews in one job, as in h006: read each task file in full, check its commit
against **every** acceptance criterion, its Scope, `REQUIREMENTS.md` § 11 Feature 002 where it cites
it, and the rows `research/delivery-002-sites.md` assigns to it. Report what does not hold, with a
path and a line. No fix, no grade, no other file.

Task files are under `.aid/works/work-003-full-aid-restructure/deliveries/delivery-002/tasks/`.

| Task | Commit | What it changed |
|---|---|---|
| task-025 | `90c9de93` | `canonical/aid/scripts/execute/writeback-state.sh` (new phase names; modes `--create`, `--step`, `--reroute`, `--check`, `--repair`; staged atomic writes), the dashboard fork, three suites, `test_integration.py`, 72 re-home rows |
| task-028 | `fad7f44c` | samples `002-06` to `002-13`, six fixtures |
| task-033 | `3e7ab8fc` | `dashboard/home.html` (five phases, one stage rail per work), `test_index_html.py` |
| task-048 | `e4b705a6` | new `dashboard/reader/tests/test_task048_phase_mapping.py` (Python/Node parity) |

task-025 is the largest and riskiest change: give it the most attention.

Points the builders flagged, for you to judge:

- task-025: the forced-failure check used a held lock, not an unwritable file (the build machine runs as
  root; yours does not, so try the unwritable case: a write that fails must leave the file's sha256sum
  unchanged and no temp file behind). `--check` treats a skill as installed when `<skill>/SKILL.md`
  exists under `.claude/skills`, `.codex/skills`, `.cursor/skills`, `.github/skills`, `.agents/skills`
  or `AID_SKILLS_DIR`, and passes when none of those folders exists. The walkthrough's six-step
  progression became five steps, so 66 labels were re-homed. Deploy writes in 17a/17b became Building.
  The new modes have no unit cases yet: task-046 and task-052 add them.
- task-028: check globs cannot hold spaces, so `002-10` uses `*gh*pr*create*`. The samples are not run
  live until the features they wait for land.
- task-033: the old lite rail (`_renderLiteStageRail`, `LITE_STAGES`) is deleted; a phase outside the
  rail shows "phase not yet recorded".
- task-048: the Node side runs inside the Python test through `reader.mjs`, as the existing parity
  tests do, with no separate `.mjs` file. Say if the Scope needs one.

Tests you may run (each changes no tracked file): `HOME="$(mktemp -d)" bash tests/canonical/<suite>`
for `test-writeback-state.sh`, `test-pipeline-status-walkthrough.sh`, `test-disjoint-merge.sh`,
`test-dashboard-reader.sh`, `test-dashboard-parity.sh`; `python3 -m pytest
dashboard/reader/tests/test_task048_phase_mapping.py dashboard/reader/tests/test_integration.py
dashboard/server/tests/test_index_html.py -q`; `python3 tests/conversation/run.py --feature 002 --validate`.

## Output

- `.aid/works/work-003-full-aid-restructure/analysis/task-025-review-codex.md`
- `.aid/works/work-003-full-aid-restructure/analysis/task-028-review-codex.md`
- `.aid/works/work-003-full-aid-restructure/analysis/task-033-review-codex.md`
- `.aid/works/work-003-full-aid-restructure/analysis/task-048-review-codex.md`
- `handoff/replies/h008.md`

Each ledger a single 7-column table, Status `Pending` on every row. Commit the five files together as
`h008: Codex reviews of delivery-002 wave 4`, push, and tell the maintainer: "h008 done".
