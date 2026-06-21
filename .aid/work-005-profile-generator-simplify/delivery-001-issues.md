# delivery-001 — carried issues for the A+ delivery gate

Per-task quick-checks defer [HIGH] findings here; [MINOR] notes worth a gate look are also recorded.
[CRITICAL] findings are fixed on the spot and not carried.

| # | Severity | Source task | Description | Suggested fix |
|---|----------|-------------|-------------|---------------|
| 1 | MINOR | task-003 | Em-dash (`—`) characters added in NEW comment lines of dev-time generators (`render_canonical_scripts.py`, `render_lib.py`, `render_recipes.py`, `render_templates.py`, `site/scripts/gen-reference.mjs`). Out of the ASCII-CI-guard allowlist (no CI break), bytes sit in comments only. | ASCII-ize the comments for house style during the gate sweep. |
| 2 | MINOR | task-003 | A few docstring/comment mentions of the old flat paths (`canonical/scripts|templates|recipes`) remain (e.g. `render_canonical_scripts.py:77,150`) — cosmetic staleness, not functional. | Update the stale docstrings to the nested `canonical/aid/...` form. |
| 3 | MINOR | task-004 | Dogfood-instance consistency: the repo's OWN root `/CLAUDE.md` (install-merged, governs this repo's agents) still lacks the `## Workflow` + consult-KB lines now in the shipped `profiles/claude-code/CLAUDE.md` template. Not a shipped-profile defect (the 5 profile templates are now consistent); the repo root file is a separate install-merged instance not covered by task-006's `.claude/` dogfood re-render. | Gate decision: fold the same block into the repo `/CLAUDE.md` AID region for dogfood parity, or defer to a dogfood-refresh / `/aid-housekeep`. |
| 4 | MINOR (cross-delivery) | task-007 | KB prose in `.aid/knowledge/{architecture,coding-standards,domain-glossary}.md` still names the now-deleted per-renderer scripts (render_agents/skills/templates/recipes/canonical_scripts) and the old per-renderer architecture. Non-CI docs; stale prose only. | Owned by **delivery-003 task-017** (KB term-retirement) — reconcile there; not a delivery-001 gate blocker. |
