# delivery-003 — carried issues for the A+ delivery gate

Per-task quick-checks defer [HIGH] here; sub-HIGH notes worth a gate look are also recorded.
[CRITICAL] are fixed on the spot and not carried.

| # | Severity | Source task | Description | Suggested disposition |
|---|----------|-------------|-------------|----------------------|
| 1 | MINOR | task-015 | `profiles/cursor/README.md` "Notes" still references `templates/scripts/grade.sh` / the repo `templates/` dir while its layout section uses `.cursor/aid/`. A stale support-file path (NOT a retired-layout string). | Update the path to the nested `aid/scripts/` form, or fold into task-017's KB/term sweep / a gate cleanup. |
| 2 | LOW | task-019 | The KB index builder (`canonical/aid/scripts/kb/build-kb-index.sh`) embeds a STALE self-reference into INDEX.md (`canonical/scripts/kb/build-kb-index.sh` at INDEX lines 15/16/223) — a dead path (work-005's aid/ nest moved canonical/scripts/ → canonical/aid/scripts/). CI INDEX-fresh check still passes (self-consistent regen). README pointer fixed to the real path in task-019; the builder template was NOT (out of task-019 scope — needs a canonical/ source edit + render-drift regen). | Fix the embedded pointer in the builder template via a canonical edit + run the full generator (render-drift), or fold into /aid-housekeep. |
| 3 | LOW | gate (HIGH#2 residual) | The KB **visual summary** source `.aid/knowledge/summary-src/sections/{06,08,09}*.html` still carries semantic split-layout / `.agents/` refs, and `kb.html` is its generated output. The 4 primary KB `.md` docs were swept at the gate, but the visual summary was NOT — regenerating `kb.html` is an `/aid-summarize` job (its own machine+human visual gate, Playwright-validated), not a delivery-003 inline edit. KB-internal, not adopter-shipped. | Run `/aid-summarize` (or fold into `/aid-housekeep` SUMMARY-DELTA) to re-author the summary-src sections + regenerate `kb.html` for the unified Codex layout. |
