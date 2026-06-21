# delivery-002 — carried issues for the A+ delivery gate

Per-task quick-checks defer [HIGH] here; sub-HIGH notes worth a gate look are also recorded.
[CRITICAL] are fixed on the spot and not carried. (delivery-002 had zero CRITICAL/HIGH — all 5 tasks passed clean.)

| # | Severity | Source task | Description | Suggested disposition |
|---|----------|-------------|-------------|----------------------|
| 1 | LOW | task-013 | Bash G11-12 separately asserts the user heading `## My Custom Section`; the PS twin T50 covers the same cursor AGENTS.md user region via BEFORE/AFTER-region sentinels + both markers but omits that one heading-string assert. Load-bearing user-content preservation is fully covered. | Accept (cosmetic parity gap; user-content byte-identity is the load-bearing check and is present). |
| 2 | MINOR | task-013 | Bash `run_update` sets `AID_NO_UPDATE_CHECK=1`; PS `Run-AidPs1Home` does not, but the `.update-check` cache reads `$HOME/.aid` which is pinned to the throwaway, so it stays hermetic (no real-home leak). | Accept (hermetic via pinned HOME) — or add the env for symmetry. |
| 3 | MINOR | task-012/013 | The migration acceptance gates assert the new codex layout as `.codex/{agents,aid}` (not `{agents,skills,aid}`) — a pre-existing bash-gate choice the PS twin faithfully mirrors. | Gate: confirm `skills` presence is covered elsewhere (the dogfood byte-identity guard + render tests) or add a `skills` assertion if the migration should verify it. |
