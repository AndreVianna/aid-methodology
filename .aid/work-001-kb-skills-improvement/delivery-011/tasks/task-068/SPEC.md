# task-068: Newcomer tone + page-shell consistency with home.html / index.html (Changes 4 + 5)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-068/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-011

**Depends on:** task-065, task-066

**Scope:**
- Implement feature-015 **Change 4 (FR-48, tone)** and **Change 5 (FR-49, shell consistency)** —
  the two content/UX changes that finish the correctness core. Edit **canonical** sources only
  (regen is task-070). These two changes share the "At a Glance" / inner-content surface, so they
  are one IMPLEMENT task.
- **Change 4 — non-technical newcomer tone.** `templates/knowledge-summary/prompt.md`, the kept
  `section-templates/*`, and `references/state-generate.md` target a **non-technical newcomer** —
  friendly, plain-language, explains the *what* and *why* accessibly. **Drop the KB's
  dual-audience / agent-frontmatter framing** from the summary (no frontmatter talk, no
  tier/audience machine-consumption language). The **"At a Glance"** leads with newcomer framing
  (what the project is / does), not software metrics.
- **Change 5 — page-shell consistency, inner-content freedom.**
  `templates/knowledge-summary/html-skeleton.html`'s **outer shell** (top bar, side panel, search,
  nav chrome) is **kept/aligned with `home.html` + the CLI `index.html`** for seamless dashboard
  navigation; **only the inner content region** is the redesign surface. Cross-check the shell
  structure against the live `home.html` and the CLI `index.html` (do not reinvent the chrome).
- This task does **not** change generation determinism (D-012) or drop Mermaid (D-012); the shell
  is realigned, not re-architected.

**Acceptance Criteria:**
- [ ] Summary prose targets a **non-technical newcomer** (friendly, plain-language, explains the
  *what* and *why*); the KB's **dual-audience / agent-frontmatter framing is dropped**; "At a
  Glance" no longer leads with software metrics. *(FR-48)*
- [ ] The outer page shell (top bar, side panel, search, nav chrome) in `html-skeleton.html` stays
  **consistent/aligned with `home.html` + the CLI `index.html`**; only the **inner content area**
  is redesigned (the chrome is not reinvented). A side-by-side check against the live `home.html`
  + CLI `index.html` confirms shell alignment. *(FR-49, §5b)*
- [ ] The keep-list is intact: design tokens, light/dark theming (FOUC-free, shared
  `aid-dashboard-theme`), the focus-trapped lightbox, the a11y baseline (skip-link, landmarks,
  `:focus-visible`, `prefers-reduced-motion`, `forced-colors`, `noscript`), and responsive layout
  are preserved (not rebuilt). *(keep-list)*
- [ ] Guardrails hold: C1 (path), C2/C3 (single self-contained file, no CDN/split asset/framework
  fetch), C5 (`## Knowledge Summary Status` approval signal), C6 (`README.md ## Completeness` +
  `kb_baseline:` shapes). Edits are in `canonical/...` only.
- [ ] All section-6 quality gates pass.
