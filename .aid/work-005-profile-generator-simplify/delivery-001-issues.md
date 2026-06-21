# delivery-001 — carried issues for the A+ delivery gate

Per-task quick-checks defer [HIGH] findings here; [MINOR] notes worth a gate look are also recorded.
[CRITICAL] findings are fixed on the spot and not carried.

| # | Severity | Source task | Description | Suggested fix |
|---|----------|-------------|-------------|---------------|
| 1 | MINOR | task-003 | Em-dash (`—`) characters added in NEW comment lines of dev-time generators (`render_canonical_scripts.py`, `render_lib.py`, `render_recipes.py`, `render_templates.py`, `site/scripts/gen-reference.mjs`). Out of the ASCII-CI-guard allowlist (no CI break), bytes sit in comments only. | ASCII-ize the comments for house style during the gate sweep. |
| 2 | MINOR | task-003 | A few docstring/comment mentions of the old flat paths (`canonical/scripts|templates|recipes`) remain (e.g. `render_canonical_scripts.py:77,150`) — cosmetic staleness, not functional. | Update the stale docstrings to the nested `canonical/aid/...` form. |
