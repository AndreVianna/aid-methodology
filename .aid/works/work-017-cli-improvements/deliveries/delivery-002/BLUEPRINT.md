# Delivery BLUEPRINT -- delivery-002: Registry & Tooling Management

[!NOTE]
This is the DELIVERY-LEVEL BLUEPRINT.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-002
> **Work:** work-017-cli-improvements
> **Created:** 2026-07-18

---

## Objective

Make the all-projects Home grid (`index.html`) a control surface for which projects the
dashboard tracks and for keeping installed tooling current. A user can Add a project by typing an
absolute path (registered via `aid projects add`, register-only -- no `.aid/` scaffolding) and
Remove a tracked project per card (untrack-only via `aid projects remove`, no files removed);
and can Update Tools per-project (`aid update --target <repo>`) plus a global Update CLI
(`aid update self`). Both action families shell out to the `aid` CLI through feature-001's
argv-array child dispatch (the server stays LLM-free, SEC-4), and the grid / machine panel
re-render from a post-op `/api/home` read so the registry state and version chips never drift.
These two P1 index.html features form one cohesive "manage your registry + tooling" MVP and are
grouped because they must share a single `aid`-CLI resolver, the `card-actions` sibling-row
scaffold, and feature-001's per-op `status_map` override (KI-004) rather than each inventing its
own.

## Scope

In scope:
- **feature-003-project-registry** -- home `OP_TABLE` rows `project.add` / `project.remove` on `POST /api/op` (child `aid projects add/remove`, fail-open post-dispatch verification guard); `index.html` Add-project form + per-card Remove; introduces the shared `aid`-resolver + `card-actions` scaffold. Sequence FIRST.
- **feature-004-update-tools** -- `OP_TABLE` rows `tools.update` (per-repo, `aid update --target`) + `tools.update-self` (home, `aid update self`); `index.html` machine-panel "Update CLI" + per-repo-card "Update Tools" reusing the shared scaffold; restart-advisory on observed `machine.aid_version` change (KI-002/KI-006) and UI busy-state (KI-003).

**Out of scope:** everything on `home.html` (deliveries 001, 003, 004, 005); building any net-new `aid` CLI verb or per-tool selection (uses `aid projects` / `aid update` as-is).

## Gate Criteria

- [ ] AC1 (add/remove project) -- `aid projects add/remove` runs from the dashboard and the registry change persists to disk; a fail-open shared-tier no-op is surfaced as 500 `write-unverified`, never a phantom success.
- [ ] AC1 (update tools) -- the per-project "Update Tools" control runs `aid update --target <repo>` and the tooling update persists; if the run also self-updated a stale CLI (observable as a changed `machine.aid_version`), the success notice advises restarting `aid dashboard`.
- [ ] AC1b (update CLI) -- the global "Update CLI" control runs `aid update self`, the channel CLI update persists, and the success notice advises restarting `aid dashboard`.
- [ ] AC2 -- after add/remove or update, the grid / machine panel re-renders from a post-op `/api/home` read with no drift (new card appears, removed card disappears, version chips reflect disk).
- [ ] AC4 -- the Python reader and `reader.mjs` stay byte-consistent for the additive registry/tooling model fields (parity suites green; golden fixtures regenerated in lockstep).
- [ ] KI-004 -- the `aid`-CLI resolver, the `card-actions` sibling-row scaffold, and the per-op `status_map` override are single-sourced (introduced by feature-003, reused by feature-004), not independently re-invented.
- [ ] AC8 (inherited) -- controls and server honour `write_enabled`: interactive on loopback, read-only under `--remote` without `--allow-writes`.
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-013 | IMPLEMENT | project.add / project.remove handlers + shared aid-CLI resolver |
| task-014 | IMPLEMENT | index.html Add/Remove Project UI + card-actions scaffold |
| task-015 | IMPLEMENT | tools.update / tools.update-self handlers |
| task-016 | IMPLEMENT | Update-tools UI on index.html |
| task-017 | TEST | Registry + tooling op round-trips |

## Dependencies

- **Depends on:** delivery-001 (write foundation + home-op `/api/op` skeleton + `OP_TABLE` `status_map` hook)
- **Blocks:** -- (none)

## Notes

KI-004 is the load-bearing coordination for this delivery -- sequence feature-003 before
feature-004. KI-002 / KI-006 (both `aid update` verbs can mutate the running server's own code)
and KI-003 (Node event-loop freeze during a long update) are feature-004-local limitations with
shipped mitigations (restart advisory + busy-state); the update controls must not ship without
the restart-advisory notice.
