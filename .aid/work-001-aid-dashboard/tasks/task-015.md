# task-015: feature-003 UI Specs — pipeline-view component breakdown

**Type:** DESIGN

**Source:** feature-003-pipeline-dashboard-app → delivery-002

**Depends on:** task-010

**Scope:**
- Produce the implementable UI breakdown for the single-pipeline progress view (feature-003 UI-1..UI-6), grounded in the `canonical/templates/knowledge-summary/` design family (NFR8): which `design-tokens.md` colors, `component-css.css` classes, and `html-skeleton.html` shell elements each component reuses.
- Specify: the stage rail (UI-2 — phase pills from `model.works[].phase`, current emphasized, full/lite path reflected by data); the wave-grouped parallel task chips (UI-3 — every concurrent task its own chip, FR14); the attention badge mapping (UI-4 — the two-color amber-Input / red-Blocked scheme, color **and** shape per glyph table, reasons surfaced read-only); the refresh-interval control (UI-5 — default 5s, clamp [1s,600s], localStorage); responsive breakpoints (UI-6 — 768px collapse) + cross-browser baseline primitives.
- Define the freshness/stale/disconnected badge + `parse_warnings` "data note" treatment (Telemetry). Map each AC1-AC5 to its component.

**Acceptance Criteria:**
- [ ] The component breakdown names the exact `knowledge-summary/` design-family assets reused per component (design tokens + CSS classes + shell), satisfying NFR8.
- [ ] The attention scheme is the resolved FR16 two-color reading (amber Input / red Blocked), color **and** shape, with the per-lifecycle glyph/word table (UI-4) and the design-note flag (input-vs-approval sub-distinction) carried for user attention.
- [ ] Stage rail, parallel task chips (FR14 side-by-side), interval control, and freshness badge are each specified against the `/api/model` fields they read (feature-003 DM-2 / feature-002 types).
- [ ] Responsive breakpoints + cross-browser primitives (UI-6) and the AC1-AC5 → component map are documented.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] DESIGN default: design tokens reused (no new palette) + responsive layout specified; rationale + trade-offs documented; grounded in the feature-003 SPEC.
