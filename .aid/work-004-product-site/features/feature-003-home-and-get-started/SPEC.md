# Home & Get Started

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR3, FR4), §3, §10 | /aid-interview |
| 2026-06-06 | Revised: the home install one-liner consumes the build-time-injected current version (FR15, owned by feature-008-version-injection); version is no longer hard-coded. | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR3, FR4 (consumes FR15) · §4 Scope · §3 Users

## Description

The site's front door. The Home / landing page communicates the AID value proposition,
renders the pipeline diagram, shows the primary install one-liner, and presents primary CTAs
(Get Started, GitHub). The Get Started section carries an evaluator from "what is AID" through
installation into running their first work: an overview / "What is AID", an Install AID entry
point, a new "Your first work" guided walkthrough, and a new "Lite path quickstart" for small
changes. The home install one-liner does not hard-code a version — it renders the latest
released version injected at build time (feature-008) so it never goes stale.

## User Stories

- As an evaluator, I want to grasp what AID is and why it exists within seconds of landing so that I can decide whether it is worth my time.
- As an evaluator, I want a single visible install one-liner and clear CTAs so that I can move from interest to action without hunting.
- As a new adopter, I want a guided "Your first work" walkthrough so that I can go from installed to running my first work with minimal friction.
- As a new adopter, I want a Lite path quickstart so that I can make a small change fast without learning the full pipeline.
- As a returning user, I want the home install one-liner to always reflect the current release so that copied commands are never stale.

## Priority

Must

## Acceptance Criteria

- [ ] Given the Home page, when a visitor loads it, then it shows the value proposition, the pipeline diagram, the install one-liner, and CTAs to Get Started and GitHub. (AC3 partial)
- [ ] Given the Get Started section, when a visitor navigates it, then Overview / "What is AID", Install AID, "Your first work" walkthrough, and "Lite path quickstart" all exist. (AC6 partial)
- [ ] Given the "Your first work" walkthrough and "Lite path quickstart", when a visitor reads them, then they are present as new content (not migrated). (AC6)
- [ ] Given a build, when the Home page renders, then its install one-liner shows the latest released version injected at build time, matching the `VERSION` file / latest GitHub Release. (AC13 partial)
- [ ] Given the pipeline diagram on Home, when the page is built, then the diagram renders correctly. (AC5)

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
