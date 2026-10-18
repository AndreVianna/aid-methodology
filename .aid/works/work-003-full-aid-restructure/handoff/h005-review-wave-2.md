# h005: quick reviews of delivery-002 wave 2 (task-021, task-022, task-024)

**From:** Claude. **To:** Codex. **Type:** review only. Read `handoff/PROTOCOL.md` first. Start only
when `NEXT.md` names h005.

Three independent task reviews in one job, as in h004. For each: read the task file in full, then
check the task's commit against **every** acceptance criterion and its Scope, and against
`REQUIREMENTS.md` § 11 Feature 002 where the task cites it. Also check the rows that
`research/delivery-002-sites.md` assigns to the task were handled. Report what does not hold, with a
path and a line. No fix, no grade, no other file.

Task files are under `.aid/works/work-003-full-aid-restructure/deliveries/delivery-002/tasks/`.

| Task | Commit | What it changed |
|---|---|---|
| task-021 | `0558785e` | `canonical/aid/templates/work-state-template.yml`, new `project-state-template.yml`, `tests/canonical/test-work-state-template.sh` |
| task-022 | `fa6802cf` | new `canonical/aid/templates/question-protocol.md` |
| task-024 | `d06494d5` | `site/scripts/lib/flow-graph/*.mjs`, `site/scripts/__tests__/flow-advance.test.mjs` |

Points the builders flagged, for you to judge:

- task-021: `qa` is marked `[W]` (work-level, written) following the spec's example block; it was `[A]`.
- task-022: the template describes `writeback-state.sh --ask / --answer / --project`, which another task
  implements later; it names `project-state-template.yml` in prose only.
- task-024: the four new words take the lowest precedence and are not added to the clause resolver,
  because an existing fixture holds the prose "(scope-diff already PASS)"; `ASK` / `WAIT` naming a state
  stay ordinary edges, not pause terminals; for `PASS` and `CALL` "edge kind" was read as the
  `advanceType` the edge carries.

Tests you may run (each changes no tracked file):
`HOME="$(mktemp -d)" bash tests/canonical/test-work-state-template.sh`, and
`cd site && npx vitest run scripts/__tests__/flow-advance.test.mjs` (needs `npm ci` in `site/` first if
`site/node_modules` is absent; `npm ci` writes only `site/node_modules`, which git ignores).

## Output

- `.aid/works/work-003-full-aid-restructure/analysis/task-021-review-codex.md`
- `.aid/works/work-003-full-aid-restructure/analysis/task-022-review-codex.md`
- `.aid/works/work-003-full-aid-restructure/analysis/task-024-review-codex.md`
- `handoff/replies/h005.md`

Each ledger a single 7-column table, Status `Pending` on every row (a header with no rows when you
find nothing). Commit the four files together as `h005: Codex reviews of delivery-002 wave 2`, push,
and tell the maintainer: "h005 done".
