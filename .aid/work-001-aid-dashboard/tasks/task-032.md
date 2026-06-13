# task-032: feature-007 KB view (LC-KV/KT/KF) — doc table, freshness/summary panels, FR18 remediation

**Type:** IMPLEMENT

**Source:** feature-007-kb-dashboard → delivery-005

**Depends on:** task-030, task-031, task-028

**Scope:**
- Implement, front-end-only inside feature-003's `index.html` on feature-006's `#/kb` route (SEAM-1, consumed not redefined), per the task-030 breakdown:
  - LC-KV KB view: render `model.repo.kb_state`; `null` → "No Knowledge Base yet" FR18 empty-state (UI-5, `/aid-discover` step + verify + back link); `KbModel` → the KB dashboard.
  - LC-KT doc table/cards (UI-2): one row/card per `KbDoc` — name (monospace), category badge (primary/meta/extension/null), status badge (known literal → colored, unknown → neutral verbatim, never throws), last-reviewed, notes-on-demand. The overall completeness chip ("K of N Populated") as a literal tally (no LLM).
  - LC-KF freshness + summary panel (UI-3): INDEX `fresh`/`stale`/`unknown` chip with the cheap-proxy reason + "likely stale" wording (KI-007); the summary approval/grade/dates/output-present card; "summary behind KB" flag.
  - FR18 remediation panels (UI-4): no-KB / INDEX stale / docs incomplete / summary unapproved-or-behind — each inline next to the offending card, only when active, with the exact verified command + verify-on-next-poll; no remediation noise on a fully-fresh/approved KB.
- Renders from the shared poll loop (no new endpoint/fetch); live freshness/approval flip within one interval; `localStorage`-only; nothing written to `.aid/` (NFR2/NFR7); back/brand → `#/`.

**Acceptance Criteria:**
- [ ] Clicking the KB card opens the dedicated KB dashboard at `#/kb` (FR15); the view lists KB docs with completeness/status and shows INDEX freshness + summary current/approved + last update (read-only, NFR2).
- [ ] Status/freshness are rendered literally from the reader (never re-derived); an unknown status literal shows a neutral chip without throwing (NFR7); the freshness chip carries the "likely stale" advisory wording (KI-007).
- [ ] The four FR18 remediation panels appear only when their trigger is active, each with the exact verified command + verify step; a fully-fresh/all-Populated/Approved KB shows no remediation noise.
- [ ] The view matches the summary visual style (NFR8) and is responsive/cross-browser (NFR5/NFR6); it adds no network call beyond the shared `fetch('/api/model')` and no server surface.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit/behavior tests for the KB view render logic added where feasible; existing tests pass; build passes (Playwright visual validation is task-037).
