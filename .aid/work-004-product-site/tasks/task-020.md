# task-020: Verify Releases page + banner dismissal

**Type:** TEST

**Source:** feature-009-releases-and-banner → delivery-003

**Depends on:** task-019

**Scope:**
- Build with simulated release data (`AID_RELEASES_JSON`/`AID_LATEST_RELEASE_JSON`) and verify the Releases page reflects each release with notes, date, and per-release offline-bundle (`aid-*.tar.gz`) asset link(s) (AC9).
- Verify the empty-state renders when release data is absent (`[]`) and the build still succeeds (D5, §4/§7 build-time-only).
- Verify the markdown body renders formatted (headings, lists, links, task-list checkboxes) and that no unsanitized HTML is injected.
- Verify the banner shows "AID v{tag} is out" on non-Releases pages, links to `/releases/changelog`, self-suppresses on the Releases page, and that dismissal persists in `localStorage` keyed by tag; verify a new tag re-shows the banner (AC14).
- Verify no measurable Lighthouse regression on pages carrying the banner.

**Acceptance Criteria:**
- [ ] Releases page renders releases + offline asset links from build-time data; empty-state path builds and renders sensibly (AC9).
- [ ] Banner shows/links/self-suppresses correctly; dismissal persists by tag and a new tag re-shows it (AC14).
- [ ] Markdown body is sanitized + formatted; no runtime backend call.
- [ ] No Lighthouse regression on banner-bearing pages.
- [ ] Tests are deterministic with clean setup/teardown; all feature-009 acceptance criteria covered.
- [ ] All §6 quality gates pass.
