# delivery-006 — deferred [HIGH] log

> Per-task quick-checks defer [HIGH] findings here; the delivery gate aggregates them.
> [CRITICAL] findings are fixed on-spot. Schema: schemas.md §12.

| # | Task | Severity | Description | Source (file:line) | Status |
|---|------|----------|-------------|--------------------|--------|
| 1 | 040 | HIGH | reader.mjs dropped the first DATA row of a headerless `## Tasks Status` table (Python kept it) — latent Python↔Node task-count divergence (delivery-002 class) | dashboard/server/reader.mjs:~1169 | Fixed-on-spot (pattern-based header skip, matches Python; byte-identical) |
| 2 | 040 | HIGH | reader.mjs treated a `## Pipeline Status` block with zero typed fields as fallback/Running + dirtied fallback_works; Python treats the heading as normalized/Unknown | dashboard/server/reader.mjs:~1074 | Fixed-on-spot (heading = normalized source, matches Python; byte-identical) |
| 3 | 042 | HIGH | the Wave-2 parity fix introduced 2 em-dashes (U+2014) into reader.mjs comments → ASCII-only gate failed (3 suites red via delegation); dev mis-labeled "pre-existing" (branch base had 0 non-ASCII) | dashboard/server/reader.mjs:1075,1171 | Fixed-on-spot (em-dashes → `--`; ASCII gate + 3 suites green; caught by orchestrator) |
