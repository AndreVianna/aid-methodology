# delivery-003 — carried issues for the A+ delivery gate

Per-task quick-checks defer [HIGH] here; sub-HIGH notes worth a gate look are also recorded.
[CRITICAL] are fixed on the spot and not carried.

| # | Severity | Source task | Description | Suggested disposition |
|---|----------|-------------|-------------|----------------------|
| 1 | MINOR | task-015 | `profiles/cursor/README.md` "Notes" still references `templates/scripts/grade.sh` / the repo `templates/` dir while its layout section uses `.cursor/aid/`. A stale support-file path (NOT a retired-layout string). | Update the path to the nested `aid/scripts/` form, or fold into task-017's KB/term sweep / a gate cleanup. |
