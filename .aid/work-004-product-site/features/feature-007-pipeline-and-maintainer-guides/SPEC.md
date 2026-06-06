# Pipeline & Maintainer Guides

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR6, FR7), §10 | /aid-interview |
| 2026-06-06 | Rescoped + renamed from feature-007-guides-and-releases: Releases (FR10) split out to feature-009-releases-and-banner. This feature is now pipeline + maintainer guides only (FR6, FR7). | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR6, FR7 · §4 Scope · §3 Secondary audience

## Description

Task-oriented how-to guides for working AID and for maintaining it. The pipeline guide walks
the end-to-end flow (discover → interview → specify → plan → detail → execute → deploy/monitor)
so a competent user can drive the methodology with a goal in mind. The maintainer guides cover
"cut a release" (sourced from `docs/release.md`) and "regenerate trees/profiles" for
contributors to AID itself. The Releases changelog page is not part of this feature — it is
owned by feature-009-releases-and-banner.

## User Stories

- As a new adopter, I want an end-to-end how-to for working the pipeline so that I can run a real piece of work from discovery through deploy.
- As a returning user, I want task-focused pipeline guides so that I can look up how to perform a specific phase.
- As a maintainer, I want a "cut a release" guide so that I can follow the release process reliably.
- As a maintainer, I want a "regenerate trees/profiles" guide so that I can keep generated artifacts current.

## Priority

Could

## Acceptance Criteria

- [ ] Given the Guides section, when a visitor opens the pipeline guide, then it documents the end-to-end flow (discover → interview → specify → plan → detail → execute → deploy/monitor). (AC3 partial)
- [ ] Given the maintainer guides, when a maintainer opens "cut a release", then it reflects the content of `docs/release.md`.
- [ ] Given the maintainer guides, when a maintainer opens "regenerate trees/profiles", then the regeneration workflow is documented.
- [ ] Given these guides, when migrated/derived content renders, then internal links resolve and any Mermaid diagrams render. (AC5 partial)

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
