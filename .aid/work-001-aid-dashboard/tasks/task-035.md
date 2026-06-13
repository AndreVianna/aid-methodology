# task-035: feature-008 drill-down view (LC-DV/RV) — findings, ledger, escaped read-only raw STATE.md, honest logs, parallel drill

**Type:** IMPLEMENT

**Source:** feature-008-skill-task-drilldown → delivery-005

**Depends on:** task-032, task-033, task-028

**Scope:**
- Implement, front-end-only inside feature-003's `index.html`, the Level-3 forensic drill view on the SEAM-2 route `#/work/<id>/task/<task-id>` (defined+consumed in feature-006's hash-router family — no `pushState`, no server route), reached from a task chip in the pipeline view (feature-003 UI-3):
  - LC-DV drill view (FC-2/FC-3): on entering a task route, add the composite `<work_id>/<task_id>` to the live `?detail=` set so the shared poll carries that `TaskDetail`; render findings (UI-2 — severity color+shape chips `[CRITICAL]`→err/octagon, `[HIGH]`→warn/triangle, unknown→neutral; description; location; disposition chip), the ledger/grade panel (UI-2 — delivery-level grade chip captioned "delivery grade (delivery-NNN)", never "task grade"; tier + gate timestamp; the deferred-`[HIGH]` issues table), and the honest logs panel (UI-4 — "No per-task logs are captured" + FR18 step-by-step guidance; the server log labeled "tool diagnostic — not a task log"; heartbeat advisory "last seen"; the IMPEDIMENT-artifact pointer when Blocked).
  - LC-RV raw-state viewer (UI-3): `raw_state.text` in a `<pre>` monospace, HTML-ESCAPED (incl. `<`/`>`/`&`/`U+2028`/`U+2029`), scrollable, READ-ONLY (no `contenteditable`/`<textarea>`/form — NFR2 structural), collapsed by default, deep-anchored to this task's `### task-NNN` / `## Tasks Status` row.
  - FC-5 parallel drill (FR14): N open task routes each carry their composite key in the `?detail=` comma-list and render an independent panel; never merged. First-tick "loading detail…" (never blank); a disappeared task → notice + back link. Back → `#/work/<id>` drops that key. Live forensics re-render on the shared loop within one interval (FR4/NFR3). `localStorage`-only; nothing written to `.aid/` (NFR2/NFR7).

**Acceptance Criteria:**
- [ ] Drilling a task opens its detail (findings, review ledger/grades, raw STATE.md content, logs) read-only (FR13/NFR2), reached from a task chip via the SEAM-2 route; back is reversible.
- [ ] The raw STATE.md is rendered in a non-editable escaped `<pre>` (no write affordance, escapes `<`/`>`/`&`/`U+2028`/`U+2029`), collapsed by default, deep-anchored to the task's block (DD-3); displayed, never edited (NFR2 structural).
- [ ] The ledger is honestly labeled a delivery-level grade join (never "task grade"); findings/grades are rendered literally, never re-derived (NFR7); the logs panel is honest ("no per-task logs captured" + FR18 guidance; server log labeled a tool diagnostic — KI-008/DD-4), never a fabricated viewer.
- [ ] Parallel tasks each drill independently into their own forensic panel (FR14); a `?detail=` comma-list carries all open drills; first-tick shows "loading", never blanks; a disappeared task shows a notice.
- [ ] No new server route/endpoint (rides the shared `fetch('/api/model?detail=…')`); responsive/cross-browser (NFR5/NFR6); matches the visual family (NFR8).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit/behavior tests for the drill view + raw-state escaping/read-only logic added where feasible; existing tests pass; build passes (Playwright visual validation is task-037).
