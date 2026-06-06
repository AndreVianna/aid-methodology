# Build & Deploy

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR12), §6, §7, §8 | /aid-interview |
| 2026-06-06 | Revised: add `release: published` trigger and a generic build-time data-fetch capability (latest VERSION + GitHub Releases API) consumed by feature-008-version-injection and feature-009-releases-and-banner; release.yml remains unmodified (decoupled). | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR12 (enabling FR10, FR15, FR16) · §4 Scope · §6 NFRs · §7 Constraints · §8 Assumptions

## Description

A GitHub Actions workflow builds the Astro Starlight site and deploys it to GitHub Pages at
the custom domain `aid.casuloailabs.com` over enforced HTTPS, shipping a `CNAME` in the build
output and generating `sitemap.xml` and `robots.txt`, with pinned build dependencies for
reproducible builds. Beyond push-to-default-branch deploys, the workflow also triggers on the
GitHub `release: published` event so the site can refresh release-bound content hands-free.
To support that, the workflow provides a generic build-time data-fetch capability — reading the
repository `VERSION` file and the GitHub Releases API using the workflow's `GITHUB_TOKEN` — and
exposes that data to the build for the version-injection (feature-008) and releases-and-banner
(feature-009) features to consume. This binding is fully decoupled from `release.yml`, which is
not modified.

## User Stories

- As an adopter, I want the site live at a stable HTTPS custom domain so that I can trust and bookmark it.
- As a maintainer, I want the site to build and deploy automatically on every change to the default branch so that publishing requires no manual steps.
- As a maintainer, I want the docs to rebuild automatically when I publish a GitHub Release so that release-bound content refreshes without touching the release process.
- As a maintainer, I want build dependencies pinned so that builds are reproducible and don't break on upstream churn.
- As an evaluator, I want the site discoverable (sitemap, robots, valid HTTPS) so that it presents as a credible product.

## Priority

Must

## Acceptance Criteria

- [ ] Given a push to the default branch, when the workflow runs, then the Starlight site builds with no errors and deploys to GitHub Pages automatically. (AC1)
- [ ] Given the deployed site, when a visitor loads `https://aid.casuloailabs.com`, then it is reachable over enforced HTTPS with the `CNAME` and Pages custom-domain configured. (AC2)
- [ ] Given the build output, when it is published, then `sitemap.xml` and `robots.txt` are present and valid.
- [ ] Given the build pipeline, when it runs in CI, then build dependencies are pinned so the build is reproducible.
- [ ] Given a published GitHub Release, when the `release: published` event fires, then the docs workflow triggers a rebuild with no manual steps and with no change to `release.yml`. (AC15, enabling)
- [ ] Given the workflow, when it builds, then a build-time data-fetch step reads the `VERSION` file and the GitHub Releases API (via `GITHUB_TOKEN`) and exposes that data to the build for features 008 and 009 to consume.

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
