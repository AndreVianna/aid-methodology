# task-065: Front-end 5-state KB card repoint (home.html) — 2-state → pending/generating/preparing/approved/outdated + ./kb.html

**Type:** IMPLEMENT

**Source:** feature-007-kb-dashboard → delivery-009

**Depends on:** task-064, task-054

**Scope:**
- Repoint feature-006's KB-card **slot** in `<repo>/.aid/dashboard/home.html` (the file d008 task-054 renamed from `index.html` and where the carried-over **2-state** card now lives) from the 2-state form to feature-007's **5-state** render (LC-A3, UI-A). This is the d009 step deferred from d008's KB-card slot (feature-006 R-3; the d004 `null`→"no KB" maps onto `pending`). Single front-end writer in d009 — no write race (task-054 in d008 owns the rename; this owns the card body).
- **5-state card (UI-A), reader-derived — never re-derived client-side:** read `kb_state.status` literally and render per the UI-A table:
  - `pending` → `.badge-dim` ⊘ "No KB", meta "run `/aid-discover`…", **dead card** (non-link);
  - `generating` → `.badge-info` ◴ "Building", meta "discovery is building the KB…", non-link;
  - `preparing` → `.badge-info` ◴ "Preparing", meta "summary generating — KB approved", non-link;
  - `approved` → `.badge-ok` ✓ "Ready", `doc_count` "docs", meta "summary updated {last_summary_date}", **clickable → `./kb.html`**;
  - `outdated` → `.badge-warn` ⚠ "Outdated", meta "KB reflects {kb_baseline.tip_date}; branch has advanced" + **refresh prompt**, **clickable → `./kb.html`** (stale but usable).
  An `unknown`/missing `status` degrades to the empty (`pending`-style dim) treatment (DM-A2).
- **Only `approved`/`outdated` are clickable** (FR32); `pending`/`generating`/`preparing` render a dead (non-link) affordance.
- **Location-relative link (LC-A3, UI-A) — no `<id>` in the model:** the clickable href is `./kb.html`. The card is served inside `home.html` at `/r/<id>/home.html`, so the browser resolves `./kb.html` against `/r/<id>/` → `/r/<id>/kb.html` (the d008-served sibling route) automatically. The client never needs `<id>`; `/api/model` carries **no** `<id>` field (mirrors task-054's `./api/model` poll pattern). Do NOT add a network call beyond the shared `/api/model`.
- **Outdated refresh prompt (FR18-style, FR32):** the `outdated` card shows the inline step prompt — "The branch has advanced past the KB baseline. 1. Run `/aid-housekeep` to reconcile + refresh the summary. 2. Verify: this card returns to **Ready** on the next refresh." It still opens the stale `kb.html`.
- **Visual family (NFR8):** built on the `knowledge-summary/` design family — `.card`, `.badge-*`, `.kicker`/`.stat`/`.meta`, light+dark tokens — exactly as feature-006 UI-1 enumerates.
- Front-end stays **no-LLM / read-only**; renders reader output literally (no client-side status derivation, no KB-file fetch). **NO `schema_version`/`EXPECTED` bump** (DM-A3 — the envelope grows additively at the same path).

**Acceptance Criteria:**
- [ ] The KB card in `home.html` renders all **5** states from `kb_state.status` per the UI-A table (badge color+shape, stat/meta text); an unknown/missing `status` degrades to the empty (dim) treatment; status is read literally — **no** client-side re-derivation.
- [ ] Only `approved`/`outdated` are clickable; `pending`/`generating`/`preparing` render a non-link dead card.
- [ ] The clickable href is the **location-relative** `./kb.html` (resolves to `/r/<id>/kb.html` against the served `/r/<id>/home.html`); no `<id>` field is read from or required in `/api/model`; no network call beyond the shared `/api/model` is added.
- [ ] The `outdated` card shows the FR18-style refresh prompt ("run `/aid-housekeep`" → returns to Ready next refresh) and still opens the stale `kb.html`.
- [ ] The card uses the `knowledge-summary/` visual family (NFR8) with light+dark tokens; no `schema_version`/`EXPECTED` bump is introduced (DM-A3).
- [ ] Static self-checks: `home.html` writes nothing to `.aid/`, no agent/LLM import, same-origin fetch only; the front-end re-derives no status.
- [ ] All §6 quality gates pass; rendered behavior (the 5 card states incl. outdated + the served `kb.html`) is Playwright-validated by task-067 — this task adds the front-end change only.
