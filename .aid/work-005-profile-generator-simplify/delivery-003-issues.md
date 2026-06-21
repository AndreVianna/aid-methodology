# delivery-003 — carried issues for the A+ delivery gate

Per-task quick-checks defer [HIGH] here; sub-HIGH notes worth a gate look are also recorded.
[CRITICAL] are fixed on the spot and not carried.

| # | Severity | Source task | Description | Suggested disposition |
|---|----------|-------------|-------------|----------------------|
| 1 | MINOR | task-015 | `profiles/cursor/README.md` "Notes" still references `templates/scripts/grade.sh` / the repo `templates/` dir while its layout section uses `.cursor/aid/`. A stale support-file path (NOT a retired-layout string). | Update the path to the nested `aid/scripts/` form, or fold into task-017's KB/term sweep / a gate cleanup. |
| 2 | LOW | task-019 | The KB index builder (`canonical/aid/scripts/kb/build-kb-index.sh`) embeds a STALE self-reference into INDEX.md (`canonical/scripts/kb/build-kb-index.sh` at INDEX lines 15/16/223) — a dead path (work-005's aid/ nest moved canonical/scripts/ → canonical/aid/scripts/). CI INDEX-fresh check still passes (self-consistent regen). README pointer fixed to the real path in task-019; the builder template was NOT (out of task-019 scope — needs a canonical/ source edit + render-drift regen). | Fix the embedded pointer in the builder template via a canonical edit + run the full generator (render-drift), or fold into /aid-housekeep. |
