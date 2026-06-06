# Feedback & Issues

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | New feature (numbered feature-010 after the feature-008 split): feedback page + per-page "Report an issue" link opening a prefilled GitHub issue, backed by a `.github/ISSUE_TEMPLATE/` issue-form template. Static, no backend/secrets; structured for a future serverless auto-create path. "Edit this page" links explicitly out of scope. | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR14 · §4 Scope (incl. Out of Scope) · §7 Constraints · §8 Assumptions

## Description

A low-friction feedback path with no backend. A dedicated feedback page and a per-page
"Report an issue" link each open a prefilled GitHub issue — the title, body, labels, and the
originating page URL are prefilled via the `issues/new` query parameters — backed by a GitHub
issue-form template under `.github/ISSUE_TEMPLATE/`. The visitor reviews and submits on GitHub;
no token, no secret, no serverless function. The form is structured so a serverless auto-create
path could replace the prefilled link later without changing the UI. "Edit this page" links are
explicitly out of scope (content is migrated/generated, so edit links would target copies and
invite drift).

## User Stories

- As a returning user, I want a "Report an issue" link on every page so that I can flag a problem from exactly where I found it.
- As a returning user, I want the issue to open prefilled with the page URL and a template so that I don't have to assemble context manually.
- As an adopter, I want a dedicated feedback page so that I can give general feedback even when not on a specific doc page.
- As a maintainer, I want incoming feedback to land as well-labeled GitHub issues backed by a form template so that triage is consistent and no backend is needed.
- As a maintainer, I want the feedback path structured so a serverless auto-create path can be added later so that we aren't locked into the prefilled-link approach.

## Priority

Should

## Acceptance Criteria

- [ ] Given any documentation page, when a visitor clicks "Report an issue", then a GitHub issue opens prefilled with the correct issue-form template, title, body, labels, and the originating page URL, with no backend call. (AC12)
- [ ] Given the dedicated feedback page, when a visitor uses it, then it opens a prefilled GitHub issue the same way, with no backend call. (AC12)
- [ ] Given the repository, when the feedback path is wired, then a GitHub issue-form template exists under `.github/ISSUE_TEMPLATE/`. (§8)
- [ ] Given the implementation, when reviewed, then it uses no token/secret and the form is structured so a serverless auto-create path could replace the prefilled link without changing the UI. (§4, §7)
- [ ] Given the site, when pages render, then no "Edit this page" links are present. (§4 Out of Scope)

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
