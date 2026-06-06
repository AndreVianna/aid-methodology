# task-013: Verify version injection + install commands (AC13)

**Type:** TEST

**Source:** feature-008-version-injection, feature-003-home-and-get-started, feature-004-installation-guide → delivery-002

**Depends on:** task-011, task-012

**Scope:**
- Build `site/` and verify `<VersionBadge>` and all five `<InstallCommand>` channels (curl, irm, npm, pypi, offline) render the resolved `VERSION` (currently `1.0.0` from the `VERSION` file), matching the `VERSION` file / latest GitHub Release (AC13).
- Verify the Home install one-liner and the Installation guide commands carry no hard-coded version literal — they consume the injected value (AC13).
- Verify a simulated version change (env `AID_VERSION` override) propagates to the badge and every install command after rebuild (AC15 version/install portion), with no runtime fetch.
- Verify the Home page renders value prop, pipeline diagram, one-liner, and CTAs; Get Started has Overview/Install/Your first work/Lite path (AC3-partial, AC6).
- Verify the installation guide's four channels + per-tool tabs render and tab `syncKey`s behave independently (AC7).

**Acceptance Criteria:**
- [ ] Badge + all five install one-liners render the build-time version; no hard-coded version found in `index.mdx`, `get-started/*`, or `guides/installation.mdx`.
- [ ] An `AID_VERSION` override rebuild updates every badge/command (no runtime backend call).
- [ ] Home + Get Started structure present per AC3/AC6; installation per AC7.
- [ ] Tests are deterministic with clean setup/teardown; all AC13/AC6/AC7 acceptance criteria from the source features are covered.
- [ ] All §6 quality gates pass.
