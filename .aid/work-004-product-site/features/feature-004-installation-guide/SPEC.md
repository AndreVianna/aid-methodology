# Installation Guide

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR5), §3, §10 | /aid-interview |
| 2026-06-06 | Revised: install commands across all channels consume the build-time-injected current version (FR15, owned by feature-008-version-injection); no hard-coded versions. | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR5 (consumes FR15) · §4 Scope · §7 Constraints; sourced from `docs/install.md`

## Description

The full installation how-to under Guides, sourced from `docs/install.md`. It covers a
channels overview and per-channel instructions for all four channels — curl/irm, npm, PyPI,
and the offline tarball — plus per-tool "add to project" instructions (Claude Code / Codex /
Cursor / Copilot / …) in tabbed blocks, and update / remove procedures. Every install command
renders the latest released version injected at build time (feature-008), so the documented
commands never go stale.

## User Stories

- As a new adopter, I want per-channel install instructions for curl/irm, npm, PyPI, and offline so that I can install via whichever channel fits my environment.
- As a new adopter, I want per-tool "add to project" instructions in tabbed blocks so that I can wire AID into my specific agent tool quickly.
- As a new adopter in an air-gapped environment, I want the offline tarball install documented so that I can install without internet access.
- As a returning user, I want update and remove instructions so that I can manage an existing install.
- As a returning user, I want install commands to always show the current version so that copied commands work without edits.

## Priority

Must

## Acceptance Criteria

- [ ] Given the Installation guide, when a visitor reads it, then all four channels (curl/irm, npm, PyPI, offline tarball) are documented with copyable commands. (AC7)
- [ ] Given the per-tool "add to project" section, when a visitor views it, then instructions are presented in tabbed blocks per tool (Claude Code / Codex / Cursor / Copilot / …). (AC7)
- [ ] Given the guide, when a visitor reads it, then update and remove procedures are present.
- [ ] Given the source `docs/install.md`, when the guide is published, then its install content appears with no content loss and internal links resolve. (AC5)
- [ ] Given a build, when each install command renders, then it shows the latest released version injected at build time, matching the `VERSION` file / latest GitHub Release. (AC13)

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
