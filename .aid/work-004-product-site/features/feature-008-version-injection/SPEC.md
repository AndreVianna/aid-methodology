# Version Injection: Always-Current Version & Install Commands

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | New feature, split from the combined feature-008-release-integration per user request: owns the always-current version binding (FR15) only. Releases page + announcement banner moved to feature-009-releases-and-banner. | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR15 · §4 Scope · §6 NFRs (Maintainability) · §7 Constraints (live-project bindings) · §8 Assumptions

## Description

The single build-time binding that keeps every documented version current with the live AID
project. At build time this feature consumes the version data fetched by feature-002 (the
repository `VERSION` file and the latest GitHub Release) and injects it into the site's version
badge and into **all** install one-liners across the site — curl/irm, npm, PyPI, and the offline
tarball. It is the one owner of "what is the current version" so there is a single source of
truth: the Home install one-liner (feature-003) and the Installation guide commands (feature-004)
are pure consumers of this injected value rather than hard-coding a version. The injection is
read at build time only — no runtime backend — and is refreshed automatically when the docs
rebuild on the `release: published` event (trigger provided by feature-002), so a new release
makes every command and badge current with no hand-editing and no change to `release.yml`. This
is the FR15 slice the project marks **Must** for the first deploy, isolated from the Should/Could
releases-page and banner work so it cannot be delayed by them.

## User Stories

- As a returning user, I want the version badge and every install command to show the current release so that I never copy a stale version.
- As a new adopter, I want the install one-liner I copy to "just work" with the current version so that my first install doesn't fail on a wrong version.
- As a maintainer, I want a single owner of the current-version value so that there is no risk of three different hard-coded versions drifting across the site.
- As a maintainer, I want the version to refresh automatically when I publish a release so that I never hand-edit version numbers in the docs.

## Priority

Must

## Acceptance Criteria

- [ ] Given a build, when the version badge and the install one-liners (curl/irm, npm, PyPI, offline) render, then each shows the latest released version, matching the `VERSION` file / latest GitHub Release. (AC13)
- [ ] Given features 003 and 004, when they render version-bearing commands, then they consume the value injected by this feature rather than hard-coding a version. (AC13)
- [ ] Given a published GitHub Release, when the docs rebuild on the `release: published` event, then the badge and all install commands update with no manual steps and no change to `release.yml`. (AC15 — version/install portion)
- [ ] Given the binding, when the version is read, then it is read at build time with no runtime backend call. (§4, §7)

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
