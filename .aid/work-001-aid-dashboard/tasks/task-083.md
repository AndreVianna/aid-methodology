# task-083: TEST — R5 Playwright hard gate on a freshly-migrated repo's home.html (resolves KI-010) §6 gate 10

**Type:** TEST

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** task-081, task-082

**Scope:**
- The **R5 hard visual gate** (project + user CLAUDE.md policy; SPEC §6 gate 10) — **render the
  freshly-migrated repo's `home.html` in Playwright and visually validate it**. Source-only inspection is
  an **automatic FAIL (grade F)**. This is the concrete proof **KI-010 is resolved** (the per-repo dashboard
  is now serveable for a repo that did not previously have `home.html`).
- **Provision via the migration (not a hand-placed file):** build an **era-b fixture repo** (no
  `settings.yml`, a `.aid/knowledge/STATE.md`, a `.aid/.aid-manifest.json`, and **no** prior
  `.aid/dashboard/home.html`) in a tmp tree, then run the migration on it (`_aid_migrate_repo` /
  `aid update` per-repo reach, task-077/079) so the SETTINGS step synthesizes the config, the ADD step
  copies the vendored `$AID_HOME/dashboard/home.html` (task-076's source) into the repo's
  `.aid/dashboard/home.html`, and the REGISTER step registers it in `$AID_HOME/registry.yml`. The page under
  test is the **migration-provisioned** copy, not a committed one.
- **Serve + render:** start the feature-010 multi-repo server over the registry containing the migrated
  repo (bound to `127.0.0.1`; Tailscale may serve it privately for the visual confirmation per global
  CLAUDE.md), then load that repo's page at `/r/<id>/home.html` in Playwright. **Visually validate**: the
  provisioned SPA shell **loads** (not a 404, not a blank page), polls `/r/<id>/api/model`, and **renders**
  the project view derived from the synthesized `settings.yml` (project name = the fixture basename).
  Capture screenshots (loaded shell, the rendered model view, dark theme if applicable).
- **Zero console errors:** confirm zero functional JS console errors across the rendered states (a benign
  favicon 404 is acceptable per the d010 precedent). Confirm the page is the relocated `dashboard/home.html`
  source served per-repo (R18 — the source-move did not break serving).
- **Read-only throughout (NFR2):** the gate observes; it never mutates the dogfood `.aid/` (the migrated
  repo is the tmp fixture); the server stays bound to `127.0.0.1` for the run. No production file changed.

**Acceptance Criteria:**
- [ ] An **era-b fixture repo with no prior `home.html`** is provisioned **by running the migration**
      (synthesize settings + copy vendored `home.html` + register) — the page under test is the
      migration-provisioned copy, not a hand-placed one.
- [ ] The freshly-migrated repo's `home.html` is **rendered in Playwright** (not source-inspected) and
      screenshotted: the SPA shell **loads** (no 404, no blank page), polls `/r/<id>/api/model`, and renders
      the project view from the synthesized `settings.yml` (KI-010 resolved; R5 hard gate satisfied by
      visual validation).
- [ ] **Zero functional JS console errors** across the rendered states; the served page is the per-repo
      file from the relocated source (R18 — serving not broken); screenshots captured.
- [ ] No `.aid/` is mutated outside the tmp fixture (read-only, NFR2); the server stayed bound to
      `127.0.0.1`; all §6 quality gates pass and the R5 hard gate is satisfied by Playwright, not source
      review.
