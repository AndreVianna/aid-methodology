# task-022: Per-page "Report an issue" Footer override + dedicated feedback page

**Type:** IMPLEMENT

**Source:** feature-010-feedback-and-issues → delivery-003

**Depends on:** task-021

**Scope:**
- Author `site/src/components/Footer.astro` (Starlight `Footer` override): re-render the default Footer, then render a "Report an issue with this page" anchor when `entry.data.reportIssue ?? true`. Build the URL in a single `buildIssueUrl(title, url)` seam (future serverless seam) via `URLSearchParams`: `template=feedback.yml`, `title=[Docs] {pageTitle}`, `labels=documentation,feedback`, `page={absolute page URL}`, `description=`. Read the current route via `Astro.locals.starlightRoute.entry`; absolute URL via `Astro.site`.
- Register `components: { Footer: './src/components/Footer.astro' }` by ADDING the key to feature-001's shared `components:` map (do not rewrite the map).
- Author `site/src/content/docs/concepts/feedback.md` (`reportIssue: false`, lands in the Concepts autogenerate group, `sidebar.order` last): explains the no-backend prefilled-issue path + a general page-agnostic prefilled-issue anchor (`title=[Docs] Feedback`, no `page=`).
- Append `.aid-report-issue` CSS to `casulo.css` (existing tokens). Do NOT enable any "Edit this page" link.

**Acceptance Criteria:**
- [ ] `Footer.astro` renders the "Report an issue" link on every doc page (and the `/releases/changelog` route) unless `reportIssue: false`; suppressed on the feedback page itself.
- [ ] The link opens `issues/new?template=feedback.yml` with title, labels, originating page URL (`page` field), and `description` field prefilled; URL-encoded; plain anchor, no backend/fetch (AC12).
- [ ] The feedback page opens a page-agnostic prefilled issue the same way (AC12).
- [ ] `Footer` key added to feature-001's shared `components:` map (Cross-Cutting Risk #1); no token/secret; `buildIssueUrl` is the single swap seam.
- [ ] No "Edit this page" link is present anywhere.
- [ ] Build passes; all existing tests still pass.
- [ ] All §6 quality gates pass.
