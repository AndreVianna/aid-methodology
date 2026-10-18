# h006: quick reviews of delivery-002 wave 3 (task-023, task-026, task-027, task-031)

**From:** Claude. **To:** Codex. **Type:** review only. Read `handoff/PROTOCOL.md` first. Start only
when `NEXT.md` names h006.

Four independent task reviews in one job, as in h005. For each: read the task file in full, then
check the task's commit against **every** acceptance criterion and its Scope, and against
`REQUIREMENTS.md` § 11 Feature 002 where the task cites it, and the rows that
`research/delivery-002-sites.md` assigns to it. Report what does not hold, with a path and a line.
No fix, no grade, no other file.

Task files are under `.aid/works/work-003-full-aid-restructure/deliveries/delivery-002/tasks/`.

| Task | Commit | What it changed |
|---|---|---|
| task-023 | `8c1945de` | new `canonical/aid/templates/skill-steps.md` (the step rules) |
| task-026 | `af3fbc73` | samples `002-01` to `002-04` and `002-14`, fixture `skipped-question/` |
| task-027 | `92623432` | samples `002-15` to `002-19`, fixtures `two-trackers/` and `usage-export/` |
| task-031 | `a56eb959` | `dashboard/reader/*.py`, `dashboard/server/reader.mjs`, `server.py`, their tests and goldens |

Points the builders flagged, for you to judge:

- task-023: the file holds no record example at all, so SS-14 (b) holds trivially; check that the
  spec's step procedure (steps 1-6) and the nine-row approvals table are complete, not just present.
- task-026: the spec's sample table names no skill for `002-03` and `002-04`; the builder chose
  `aid-config` and `aid-set-connector`. `002-04` ("a skipped question answered by another person in a
  later session") is one conversation over a prepared fixture, because the runner drives one
  conversation per sample. Say whether that still tests what AC-28 asks.
- task-027: `002-16` and `002-18` exempt their intake question from the protocol, as the spec's
  intake exception says.
- task-031: the old phase names stay only between `legacy-phase-map: begin` / `end` markers; the
  readers serialize `intent.phases` as `phases`. 13 Python and 4 Node dashboard tests fail on the base
  commit too (environment); the builder compared them against the base.

Tests you may run (each changes no tracked file): `python3 tests/conversation/run.py --feature 002
--validate`; `HOME="$(mktemp -d)" bash tests/canonical/test-dashboard-parity.sh` and
`test-dashboard-reader.sh`; `python3 -m pytest dashboard/reader/tests -q`. Do not run live samples.

## Output

- `.aid/works/work-003-full-aid-restructure/analysis/task-023-review-codex.md`
- `.aid/works/work-003-full-aid-restructure/analysis/task-026-review-codex.md`
- `.aid/works/work-003-full-aid-restructure/analysis/task-027-review-codex.md`
- `.aid/works/work-003-full-aid-restructure/analysis/task-031-review-codex.md`
- `handoff/replies/h006.md`

Each ledger a single 7-column table, Status `Pending` on every row (a header with no rows when you
find nothing). Commit the five files together as `h006: Codex reviews of delivery-002 wave 3`, push,
and tell the maintainer: "h006 done".
