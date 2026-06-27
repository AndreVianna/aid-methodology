# task-073: Provision the Playwright browser-render dependency (+ CI support) for the visual-fidelity gate

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-073/STATE.md.

**Type:** CONFIGURE

**Source:** work-001-kb-skills-improvement -> delivery-012

**Depends on:** -- (none intra-delivery; the §7 gate validator task-074 consumes this provisioning)

**Scope:**
- The §7 gate requires a **Playwright headless-browser render** of every authored visual — a
  **new browser-render dependency** the feature-015 SPEC explicitly flags the DETAIL/EXECUTE phase
  must **provision** and **CI must support**. The current `validate-diagrams.mjs` uses **JSDOM**
  (a non-browser DOM), which cannot attest real layout/overlap/legibility. This task lands the
  dependency + CI wiring **before** the validator is written (task-074), so task-074 has a working
  browser-render harness.
- **Provision the dependency:** add Playwright (with a Chromium headless browser) to the project's
  dev/test dependency set in the canonical location used by the summarize toolchain (e.g. the
  package manifest the `.mjs` validators run under), pinned to a known-good version. Document the
  browser-install step (`playwright install chromium` or equivalent) needed in CI.
- **CI support:** wire the CI lane that runs the summarize validation suite to install the
  Playwright browser and run it headless (no display server assumptions). Keep it isolated to the
  summarize/visual-fidelity job so it does not slow unrelated lanes.
- **Determinism + isolation:** the browser render must be reproducible (pinned version, headless,
  no network for the inlined single-file page) and must not require any external fetch (consistent
  with C2/C3 self-containment — the validator renders a local self-contained file).
- This is **CONFIGURE only** — provisioning + CI wiring; the validator logic + state rework is
  task-074. No skill behavior changes here.

**Acceptance Criteria:**
- [ ] Playwright + a pinned headless Chromium are added to the summarize toolchain's dependency
  set; the browser-install step is documented and reproducible. *(FR-51, §7 — new browser-render
  dependency)*
- [ ] The CI lane that runs the summarize visual-fidelity suite **installs and runs** the
  Playwright browser headless (no display-server assumption), isolated to that job. *(§7, CI
  support)*
- [ ] The render harness is **deterministic** (pinned version, headless) and needs **no external
  fetch** to render the inlined single-file `kb.html` (consistent with C2/C3). *(guardrails)*
- [ ] No skill generation behavior changes in this task (CONFIGURE only); edits are in the
  canonical/dependency + CI config, not the rendered `.claude/` copy.
- [ ] All section-6 quality gates pass.
