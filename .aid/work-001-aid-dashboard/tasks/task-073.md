# task-073: Playwright R5 visual gate — drill view (findings/ledger/escaped read-only raw STATE.md/honest logs) + parallel-task drill

**Type:** TEST

**Source:** feature-008-skill-task-drilldown → delivery-010

**Depends on:** task-071, task-072

**Scope:**
- The hard R5 visual gate (project CLAUDE.md policy + feature-008 UI-Specs web-review gate): **render the
  drill view in Playwright and visually validate** — source-only review is an **automatic FAIL**. Runs
  over a live d008 multi-repo server loaded with the task-072 fixture (the full `TaskDetail` surface), so
  the rendered forensics are real, not invented. The page is the per-repo `home.html` served at
  `/r/<id>/home.html`; the drill is reached via the `#/work/<work_id>/task/<task-id>` SEAM-2 route.
- **Drill arrival + findings/ledger (UI-2):** click a task chip in the pipeline view → confirm the drill
  view opens (hash route), the **severity-tagged findings list** renders across severities (`[CRITICAL]`
  ✕ err, `[HIGH]` ⚠ warn, unknown dim — color+shape distinct), and the **ledger** renders as a
  **delivery** grade chip captioned "delivery grade (delivery-NNN)" (never "task grade"), with the
  reviewer tier / gate ts and the deferred-`[HIGH]` table; confirm the empty-findings ("No quick-check
  findings…") and `delivery_id==null` ("Not yet graded…") states render where the fixture exercises them.
- **Raw STATE.md viewer (UI-3, R15):** expand the collapsed-by-default raw-state `<pre>` → confirm it
  renders **monospace, escaped, scrollable, read-only** (no editable control / write affordance), is
  deep-anchored to the task's `### task-NNN` block, and that a STATE.md containing markup/HTML +
  `U+2028`/`U+2029` (from the fixture) is **displayed escaped, not injected/executed** (R15 no-injection
  — confirm no script ran, no layout break). Confirm the `byte_len` "show N KB" affordance.
- **Honest logs panel (UI-4, KI-008):** confirm the panel shows "No per-task logs are captured." + the
  FR18 step-by-step guidance (not a fake empty viewer); where the fixture sets it, the clearly-labeled
  "Dashboard server log (tool diagnostic — not a task log)" affordance and the Blocked-work IMPEDIMENT
  pointer render.
- **Parallel-task drill (UI-5, FR14):** drill **several** concurrent tasks → confirm each renders an
  **independent** forensic panel (side-by-side on desktop, stacked on mobile), the view never merges two
  tasks' forensics, and a task that disappears between polls shows the "no longer in the work's state"
  notice + back link (never a blank). Confirm **back** returns to the pipeline view.
- **Responsive + dark + no-errors:** validate the 768px responsive collapse (findings+ledger stack; raw
  `<pre>` horizontally-scrollable, never wrap-corrupt) and dark theme (NFR8); **zero JS console errors**
  across all states. Tailscale may serve the page privately for the visual confirmation (global CLAUDE.md).
  Capture screenshots for each validated state (drill arrival, findings severities, raw-state expanded,
  logs panel, parallel drill, back nav, dark + responsive).
- **Read-only throughout (NFR2):** the gate observes, never mutates `.aid/`; the server stays bound to
  `127.0.0.1` for the run.

**Acceptance Criteria:**
- [ ] The drill view is **rendered in Playwright** (not source-inspected) and screenshotted: drill arrival
      from a task chip, the findings list across `[CRITICAL]`/`[HIGH]`/unknown (color+shape distinct), and
      the **delivery-grade-not-task-grade** ledger (captioned per DM-1) + deferred-`[HIGH]` table + the
      empty/`null` states the fixture exercises.
- [ ] The raw STATE.md `<pre>` renders **read-only, monospace, escaped, scrollable**, deep-anchored to
      `### task-NNN`; STATE.md markup + `U+2028`/`U+2029` is **displayed escaped, not injected/executed**
      (R15 — no script ran, no layout break); the `byte_len` "show N KB" affordance is visible.
- [ ] The logs panel shows the honest "No per-task logs are captured." + FR18 guidance (not a fake viewer),
      plus the server-log diagnostic / IMPEDIMENT pointer where the fixture sets them (KI-008).
- [ ] **Parallel drill** of several concurrent tasks renders **independent** panels (no merge; desktop
      side-by-side, mobile stacked); a disappeared task shows the notice + back link (never blank); back
      returns to the pipeline view.
- [ ] Dark theme + the 768px responsive collapse are visually confirmed; **zero JS console errors** across
      all states; screenshots are captured for each validated state.
- [ ] No `.aid/` is mutated during the gate (read-only, NFR2); the server stayed bound to `127.0.0.1`.
- [ ] All §6 quality gates pass; the R5 hard gate is satisfied by visual (Playwright) validation, not
      source review.
