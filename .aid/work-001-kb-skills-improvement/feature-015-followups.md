# feature-015 — fast-follow / deferred items (non-blocking)

Recorded during the autonomous build. None blocks the A+ gates; all are cosmetic or
constraint-deferred. To clean up before/with the final handoff.

- **[from task-070 AC3]** `release-tracking.md` `[CHANGE]` entry + INDEX.md regen — deferred:
  the executor was constrained "do not touch `.aid/knowledge/`" (uncommitted experiment KB).
  A release-note item, not a code gap. Add when the KB constraint is lifted.
- **[D-011 gate MINOR-1]** `canonical/aid/templates/knowledge-summary/section-templates/web-app.md` §1
  retains the old metric-grid body text as a "kept rendering reference" (header flags it retired;
  the authoritative generation path enforces the newcomer lead). Cosmetic doc-consistency.
- **[D-011 gate MINOR-2]** non-ASCII em-dash in `canonical/aid/scripts/summarize/writeback-state.sh:2`
  comment. The operative `test-ascii-only.sh` excludes agent-side summarize bash scripts (green),
  but shipped-script ASCII hygiene is the standing rule — replace with ASCII '-'.

- **[CC09 transient]** a canonical test (CC09) fails while `.aid/dashboard/kb.html` is absent
  (deleted during the experiment). RESOLVES automatically when Phase-2 regenerates kb.html. Not a code defect.

- **[OUT of feature-015 scope — server-gzip/cache fast-follow]** The dashboard server
  (`dashboard/server/server.mjs` + `server.py` byte-parity twins) does not yet apply
  server-side gzip compression or cache headers to the `kb.html` leaf. With inline SVG
  and no runtime Mermaid engine the file is significantly smaller than in D-011, but
  adding `Content-Encoding: gzip` + `Cache-Control: max-age=3600` to the server response
  for `kb.html` (and `home.html`) is the highest-ROI remaining perf step. This is a
  **server change, not a skill change** — it belongs in a follow-on task targeting the
  dashboard server component, not in feature-015 (which scopes to the aid-summarize skill
  and its canonical assets). Recommended action: open a new feature/task against
  `dashboard/server/` when server maintenance is next scheduled.

- **[§7 gate viewport gap — found in Phase-3 visual review]** `validate-visuals.mjs` renders at a
  single WIDE viewport (~1152px content), so it PASSED the lifecycle-timeline visual whose 8 stages
  only clip at the dashboard's narrower ~732px column ("Monitor" pill cut by 24px). The generated
  `kb.html` was hand-corrected (shrink pill padding/font → fits at 732px; re-verified). RECOMMENDED
  gate improvement (design choice for the user): validate each visual at REPRESENTATIVE widths
  (e.g. the dashboard column ~720-760px AND a mobile ~390px), not just one wide viewport — i.e. add
  a "no horizontal overflow-clip at target widths" check (T4). Deferred as a design decision, not
  guessed overnight.
