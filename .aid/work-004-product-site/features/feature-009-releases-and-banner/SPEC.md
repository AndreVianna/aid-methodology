# Releases Page & Announcement Banner

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | New feature, split from the combined feature-008-release-integration per user request: owns the Releases page (FR10) and the dismissible release-announcement banner (FR16). The always-current version binding (FR15) moved to feature-008-version-injection. | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR10, FR16 · §4 Scope · §6 NFRs · §7 Constraints (live-project bindings) · §8 Assumptions

## Description

The release-visible surface of the live-project binding. At build time this feature consumes the
release data fetched by feature-002 (the GitHub Releases API and/or `CHANGELOG.md`) and produces
two outputs: (1) a **Releases page** auto-populated from GitHub Releases with each release's
notes, date, and per-release **offline-tarball download asset link**, rebuilt automatically on
the `release: published` event so it stays current hands-free; and (2) a **dismissible
release-announcement banner** surfacing the latest release (e.g. "AID vX.Y.Z is out") and linking
to the Releases page, with the dismissal persisted for the visitor. Both are read at build time —
no runtime backend — and are decoupled from `release.yml`, which is never modified. Per §10 the
Releases page is **Should** and the announcement banner is **Could**, so this feature is a
coherent post-MVP slice that can follow the first deploy.

## User Stories

- As a returning user, I want the Releases page to reflect the latest GitHub Releases with offline-tarball links so that I can see what changed and download an air-gapped build.
- As a new adopter in an air-gapped environment, I want each release's offline-tarball download link so that I can fetch the exact version I need.
- As an evaluator, I want a clear "latest release" banner so that I can immediately see the project is active and current.
- As an adopter, I want the announcement banner to be dismissible and stay dismissed so that it doesn't nag me on every visit.
- As a maintainer, I want publishing a GitHub Release to refresh the Releases page and banner automatically so that I never hand-edit the site and never modify `release.yml`.

## Priority

Should

> Slice priorities (mirroring §10): FR10 Releases page = **Should**; FR16 announcement banner = **Could**.

## Acceptance Criteria

- [ ] Given a build, when the Releases page renders, then it reflects GitHub Releases / `CHANGELOG.md` with per-release offline-tarball download links. (AC9)
- [ ] Given the latest release data, when any page renders, then a dismissible banner shows the latest release and links to the Releases page, and dismissal persists for the visitor. (AC14)
- [ ] Given a published GitHub Release, when the `release: published` rebuild runs, then the Releases page and the banner update with no manual steps and no change to `release.yml`. (AC15 — releases-page/banner portion)
- [ ] Given the binding, when release data is read, then it is read at build time with no runtime backend call. (§4, §7)

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
