# task-019: Static front-end index.html — boot, poll loop, render, attention, interval, freshness

**Type:** IMPLEMENT

**Source:** feature-003-pipeline-dashboard-app → delivery-002

**Depends on:** task-015, task-016

**Scope:**
- Implement the dependency-free static front-end `index.html` (feature-003 LC-F + LC-A; CSS + JS inlined, no build step, no web fonts, no CDN at runtime), per the task-015 UI breakdown and the `knowledge-summary/` design family (NFR8).
- Boot (Feature Flow step 2): read poll interval from `localStorage` (default 5000ms, FR5), immediate first `fetch('/api/model')`.
- Poll loop (step 3, self-rescheduling `setTimeout`, single in-flight): on 200 parse + check `schema_version === EXPECTED` (mismatch → stale-assets banner, keep last good view); `render(model)` — stage rail (UI-2), wave-grouped parallel task chips (UI-3, FR14), two-color attention badges color+shape with reasons surfaced read-only (UI-4); freshness/stale/disconnected badge from `model.read.read_at` + heartbeat (Telemetry); `parse_warnings` data note. Network error → keep last good view + "reconnecting" badge, back off (never blank).
- Interval control (UI-5): clamp [1s,600s], persist to `localStorage`, reschedule next tick. Tolerate unrecognized enum strings with a neutral badge (forward-compat, never throw). Responsive (UI-6) + baseline cross-browser primitives.

**Acceptance Criteria:**
- [ ] On open, the page shows the pipeline's stages + current position (AC1) and the current + parallel task(s) with state side-by-side (AC2/FR14).
- [ ] Paused vs Blocked are distinguished by the two-color amber-Input/red-Blocked scheme (color **and** shape), with `pause_reason`/`block_reason`/`block_artifact` surfaced read-only (AC3/FR11).
- [ ] The view updates within the poll interval (default 5s, configurable + clamped + persisted); displayed state lags disk by ≤ one interval (AC4/NFR3); the freshness badge shows live/stale/disconnected.
- [ ] On `schema_version` mismatch the stale-assets banner shows and the last good view is kept; on network error the page never blanks; an unrecognized enum renders a neutral badge without throwing (NFR7).
- [ ] The page matches the `knowledge-summary.html` visual style (NFR8), uses only baseline cross-browser primitives (NFR5), and is responsive (NFR6); it makes only same-origin `fetch('/api/model')` and writes nothing to `.aid/` (NFR2).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit/behavior tests for the boot/poll/render/interval logic added where feasible; existing tests pass; build passes (Playwright visual validation is task-020).
