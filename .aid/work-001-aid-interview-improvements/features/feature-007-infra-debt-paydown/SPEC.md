# Infra Tech-Debt Paydown

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-7, §9 AC-9, §10 P4 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR-7, §9 AC-9, §10 P4

## Description

A bundle of opportunistic infrastructure tech-debt side-tasks (carried over from tech-debt.md)
paid down alongside the core work. These are debt, not features — kept separate so they do not
dilute the core interview threads, and each is individually deferrable with rationale. The items
are: H1 — add a CI/test check that the dashboard file set agrees across the five install
manifests (install.sh, install.ps1, vendor.js, vendor.py, release.sh), the highest-leverage and
only HIGH item; M3 — refresh docs/repository-structure.md (stale skill/recipe counts and a wrong
path), reconciled via aid-housekeep; M4 — add a multi-viewport visual gate so a visual cannot
pass at a wide viewport yet clip at the dashboard column or mobile width; and M1 — npm/PyPI
publish enablement, which is owner-gated and external (account + token setup), scheduled only
when publishing the next public version.

## User Stories

- As an AID maintainer, I want a CI check that the five install manifests agree on the dashboard
  file set so that a forgotten update cannot silently ship a broken dashboard on one channel.
- As an AID adopter reading the docs, I want repository-structure.md to reflect the real skill /
  recipe counts and paths so that the documentation is accurate.
- As an AID maintainer, I want the visual gate to check multiple viewport widths so that a visual
  that clips at the dashboard column or mobile width is caught before merge.
- As the project owner, I want npm/PyPI publish enablement tracked so that the external account /
  token setup is scheduled when the next public version ships, or explicitly deferred with
  rationale.

## Priority

Could

## Acceptance Criteria

- [ ] Given the debt bundle, when this feature completes, then H1, M3, M4, and M1 are each closed
  or explicitly deferred with rationale. *(AC-9)*
- [ ] Given H1, when the install manifests disagree on the dashboard file set, then the CI/test
  check fails. *(AC-9)*
- [ ] Given M4, when a visual clips at the dashboard-column or mobile target width, then the
  multi-viewport gate flags it. *(AC-9)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
