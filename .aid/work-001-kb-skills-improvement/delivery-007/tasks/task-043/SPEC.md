# task-043: home.html per-doc suspect marker on the KB card (minimal UI)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-007

**Depends on:** task-042

**Scope:**
- Surface the per-doc freshness signal in the existing per-repo KB card in `dashboard/home.html`
  (`_renderKbCard`, line 1589) -- **no new page, no redesign** (O5, f007 SPEC "Minimal UI surface").
- When `kb_state.suspect_count > 0`, render a **per-doc suspect marker** -- a small `badge badge-warn`
  reading `N doc(s) suspect`, reusing the existing warn-badge style already used for the whole-KB
  "Outdated" state (line 1700). List the suspect doc names in the card meta and, where present,
  *which source* drifted (from `suspect_sources`). This is the actionable per-doc signal FR-6 / the
  doc-owner story asks for ("which doc my change made suspect").
- Update the existing whole-KB "Outdated" refresh-prompt copy (line 1730) to per-doc language
  ("N doc(s) are suspect -- run /aid-housekeep to reconcile the affected docs"), KEEPING the
  `/aid-housekeep` call-to-action (which f010/delivery-009 consumes).
- `home.html` reads `kb_state.doc_freshness` / `suspect_count` **literally** (the existing
  "never re-derive client-side" rule, line 1584) -- the readers (task-042) do all derivation; the UI
  only displays.
- Augment-and-supersede (SPIKE-1, settled in task-042): the per-doc suspect marker becomes the
  primary freshness signal on the card, while the existing 5-state `KbStatus` waterfall / `outdated`
  state is RETAINED as the coarse rollup. Do NOT hard-remove the whole-KB `outdated` badge (that would
  enlarge the change beyond O5 and touch `derive_kb_status` / `kb_baseline`).
- The multi-repo CLI home (`index.html`) shows only a coarse "KB" chip (line 870) and is **NOT**
  changed (O5 -- per-doc detail belongs on the per-repo card).
- `home.html` lives under `dashboard/` (NOT canonical-rendered); edit in place (C3/NFR-4 -- no
  `run_generator.py`).

**Boundary:** f007 PROVIDES + SURFACES the freshness signal. This task does NOT author the reader
derivation (task-042 -- it consumes `kb_state.doc_freshness`/`suspect_count` literally), does NOT
change `index.html`, and does NOT build `/aid-housekeep` itself (f010/delivery-009 -- only the existing
call-to-action copy is repointed to per-doc language).

**Acceptance Criteria:**
- [ ] `dashboard/home.html` `_renderKbCard` (line 1589): when `kb_state.suspect_count > 0`, renders a
  `badge badge-warn` reading `N doc(s) suspect` (reusing the existing warn-badge style, line 1700) and
  lists the suspect doc names (plus the drifted source where `suspect_sources` is present) in the card
  meta.
- [ ] The whole-KB "Outdated" refresh-prompt copy (line 1730) is updated to per-doc language and KEEPS
  the `/aid-housekeep` call-to-action.
- [ ] `home.html` reads `kb_state.doc_freshness` / `suspect_count` literally (no client-side
  re-derivation, per line 1584); the existing 5-state `KbStatus` / `outdated` badge is RETAINED
  (augment-and-supersede, not hard-removed).
- [ ] `index.html` is unchanged (O5); no new page or redesign is introduced.
- [ ] Web validation (per the project hard gate): render `home.html` in Playwright against a fixture
  repo model with `suspect_count > 0` and confirm the per-doc suspect badge + suspect doc/source list
  actually render, and against `suspect_count == 0` confirm the badge is absent -- a snapshot/screenshot
  proves it, not source inspection.
- [ ] All section-6 quality gates pass (existing dashboard tests still pass; no regression to the KB
  card's other states).
