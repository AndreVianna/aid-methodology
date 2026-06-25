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
