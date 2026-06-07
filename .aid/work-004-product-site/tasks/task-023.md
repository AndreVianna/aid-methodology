# task-023: Verify feedback path — prefilled issue, no backend, no edit links

**Type:** TEST

**Source:** feature-010-feedback-and-issues → delivery-003

**Depends on:** task-022

**Scope:**
- Verify the per-page "Report an issue" link is present on every doc page (and the `/releases/changelog` route) and absent on the feedback page (`reportIssue: false`) (AC12).
- Verify each link's href is `issues/new?template=feedback.yml` with correctly URL-encoded `title=[Docs] {pageTitle}`, `labels=documentation,feedback`, `page=<absolute page URL>`, and `description=` (AC12).
- Verify the dedicated feedback page renders a general (page-agnostic, no `page=`) prefilled-issue anchor (AC12).
- Verify no backend/fetch is involved (plain anchors, no secrets) and the `buildIssueUrl` seam is the only feedback-URL construction point.
- Verify no "Edit this page" link is present on any page (§4 Out of Scope).
- Verify the form `id`-based prefill (`page`, `description`) matches the `feedback.yml` field ids.

**Acceptance Criteria:**
- [ ] "Report an issue" present on all doc pages + the changelog route; absent on the feedback page (AC12).
- [ ] Link query params (template/title/labels/page/description) are correct and URL-encoded; field ids match `feedback.yml` (AC12).
- [ ] Feedback page page-agnostic anchor works (AC12).
- [ ] No backend/secret; no "Edit this page" link anywhere.
- [ ] Tests are deterministic with clean setup/teardown; all feature-010 acceptance criteria covered.
- [ ] All §6 quality gates pass.
