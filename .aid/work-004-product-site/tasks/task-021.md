# task-021: GitHub issue-form template + repo labels

**Type:** CONFIGURE

**Source:** feature-010-feedback-and-issues → delivery-003

**Depends on:** task-009

**Scope:**
- Author `.github/ISSUE_TEMPLATE/feedback.yml` — a GitHub issue *form*: `name`, `description`, `labels: ["documentation", "feedback"]`, a cosmetic `title:` default, and `body:` fields whose `id`s are the prefill query keys: markdown intro, required dropdown `type` (six options), optional input `page` (originating URL), required textarea `description`, optional textarea `expected`.
- Author `.github/ISSUE_TEMPLATE/config.yml` — `blank_issues_enabled: true` + optional `contact_links` (e.g. casuloailabs.com). This is the repo's first issue template (sets the convention).
- Ensure the repo labels `documentation` and `feedback` exist (one-time setup) so `labels=` is not silently dropped by GitHub.

**Acceptance Criteria:**
- [ ] `.github/ISSUE_TEMPLATE/feedback.yml` is a valid GitHub issue form with fields `type`/`page`/`description`/`expected` and labels `documentation,feedback`.
- [ ] `.github/ISSUE_TEMPLATE/config.yml` sets `blank_issues_enabled: true`.
- [ ] Repo labels `documentation` and `feedback` exist.
- [ ] Configuration is idempotent; no plaintext secrets/tokens.
- [ ] All §6 quality gates pass.
