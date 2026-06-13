# delivery-002 — deferred [HIGH] log

> Per-task quick-checks defer [HIGH] findings here; the delivery gate aggregates them.
> [CRITICAL] findings are fixed on-spot during the task, not deferred.
> Schema: schemas.md §12. All findings below were FIXED ON-SPOT during execution (none left open
> for the gate), recorded here for the gate AGGREGATE audit trail.

| # | Task | Severity | Description | Source (file:line) | Status |
|---|------|----------|-------------|--------------------|--------|
| 1 | 015 | HIGH | UI doc referenced `model.generated_by`; it is an envelope-level sibling of `model` (`{schema_version,generated_by,model}`) — would mislead task-019 | design/feature-003-ui-breakdown.md:24 | Fixed-on-spot (doc corrected; front-end reads `envelope.generated_by`) |
| 2 | 017 | CRITICAL | U+2028/U+2029 serialization divergence — SPEC premise "Node default escapes them" is false; both runtimes emit raw by default, so Python's escaping post-process diverged from Node's raw output (breaks PT-1/R7) | dashboard/server/server.mjs:23,165-167 | Fixed-on-spot (Node now escapes to the canonical escaped form; proven byte-identical) |
| 3 | 017 | HIGH | `index.html` resolved to different dirs across servers (Node dashboard/server/, Python dashboard/) — one runtime's GET / would 404 | dashboard/server/server.mjs:91 | Fixed-on-spot (both → dashboard/index.html) |
| 4 | 016 | HIGH | Python server SIGTERM handler deadlocked (server.shutdown() on main thread blocks serve_forever) — never exited on SIGTERM, violating LC-1 "clean exit on signal"; forced aid dashboard stop to always SIGKILL-escalate | dashboard/server/server.py:287-292 | Fixed-on-spot (shutdown on daemon thread; exits ~15ms; +SIGTERM test) · commit 571728a |

## Visual-polish findings (Playwright gate, task-020 — all Fixed-on-spot)

| # | Severity | Description | Status |
|---|----------|-------------|--------|
| 5 | LOW | Task chips sparse/empty — full-width badge bars, no per-task info | Fixed (compact + task_id/type/grade/elapsed, content-width badges, align-items:flex-start) · c49b320 |
| 6 | LOW | Lone-task wave chip stretched full-width (auto-fit grid collapse) | Fixed (fixed-column grid 3/2/1) · c49b320 |
| 7 | LOW | Left-clustered content in full-width cards (unbalanced at desktop) | Fixed (centered ~860px content column) · c49b320 |
| 8 | LOW | Callouts over-tall for one-line content | Fixed (reduced padding) · c49b320 |
| 9 | LOW | Done-wave plain inline text vs boxed active waves (inconsistent) | Fixed (consistent muted pill) · c49b320 |
| 10 | LOW | Mobile header controls clipped below ~420px | Fixed (top-bar flex-wrap) · c49b320 |
| 11 | LOW | Tablet stayed 3-col (design intended 2-col) | Fixed (769-1024px → 2-col) · c49b320 |
