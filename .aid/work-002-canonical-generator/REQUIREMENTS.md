# Requirements — Canonical-Source Generator

> Split from `work-001-aid-lite` during the fresh-eyes scope reshape (2026-05-22).
> What was originally FR5 + `feature-001` in `work-001` is its own work item
> because (a) it is unrelated to the four user pain points `work-001-aid-lite`
> addresses, and (b) it is a **sequencing prerequisite**: every edit to AID's
> skills / agents / templates is currently triplicated across the three install
> trees, so completing this work first turns all subsequent edits — including
> `work-001-aid-lite`'s 5 features — into single-source changes.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Created via split from `work-001-aid-lite` during the fresh-eyes scope reshape. `feature-001-profile-driven-generator` SPEC carried over (graded A in the prior `/aid-specify` cycle). Status: Approved — ready for `/aid-plan`. | reshape |

## 1. Objective

Replace the 4-way hand-maintained duplication of AID's skills + agents + templates
(canonical README copies at the repo root + three per-tool install trees) with one
**canonical source** + **per-tool profiles** + a deterministic **generator** that
renders the three install trees from the canonical source.

## 2. Problem

Today every change to an AID skill / agent / template must be applied **four
times**: once to the human-readable canonical at the repo root and once each into
`claude-code/.claude/`, `codex/.codex/` + `codex/.agents/`, and `cursor/.cursor/`.
This:

- Creates documented body drift (tech-debt **H1**) — `aid-discover/SKILL.md` is
  453 / 1,078 / 1,090 lines across the three trees.
- Multiplies every future edit by 4× (tech-debt **H4** — the quadruplication
  pattern itself).
- Has already produced installer omissions (tech-debt **H6** — `setup.sh` /
  `setup.ps1`'s Codex branch never copies `codex/.agents/`).
- Has no enforcement (no linter, no schema validation, no drift-checker — see
  `coding-standards.md` §10).

## 3. Scope

**In scope:**
- One `canonical/` source tree (skills, agents, templates, hooks) at the repo
  root.
- Per-tool **TOML** `profiles/*.toml` declaring each host tool's conventions
  (frontmatter schema, file extensions, model-tier map, capability flags).
- A **maintainer-side deterministic Python generator** that renders the three
  install trees from `canonical/` + `profiles/`.
- **VERIFY-4a (deterministic hard gate):** byte-identical re-runs; every expected
  file emitted; frontmatter parses.
- **VERIFY-4b (advisory):** conformance review of generated files against vendor
  documentation (degrades to "skipped with warning" until vendor URLs in
  `external-sources.md` are fetched).
- **Pure-mirror RENDER** bounded by a per-run **emission manifest** — deletion is
  restricted to paths the manifest tracks; user-added files outside the generator's
  output set are untouchable.
- Fix tech-debt **H6** (the Codex installer omission) as part of the cutover.

**Out of scope:**
- The four user pain points that motivated `work-001-aid-lite` (those are
  `work-001`'s scope).
- Future host-tool additions (the generator is extensible — adding a tool is one
  new profile — but each is its own follow-up work).

## 4. Constraint — End users require no Python

The generator runs **only on the AID maintainer's machine at build time**; the
generated install trees are committed to the repo; `setup.sh` / `setup.ps1`
continue to copy pre-generated trees — there is **no end-user runtime change**.
Python is a maintainer-only build dependency, never a runtime dependency for users
of AID.

## 5. Feature

This work has one feature:

| # | Feature | Status |
|---|---------|--------|
| 001 | `feature-001-profile-driven-generator` | Spec **Ready** at grade **A** (carried over from `work-001-aid-lite` Wave-1 cycle + independent re-grade) |

See `features/feature-001-profile-driven-generator/SPEC.md` for the full Technical
Specification (Data Model · Feature Flow · Layers & Components · Migration Plan).

## 6. Acceptance Criteria

- [ ] AC1: A single `canonical/` source renders every install tree.
- [ ] AC2: Re-running the generator on unchanged `canonical/` + profiles produces
      byte-identical output (deterministic).
- [ ] AC3: Onboarding a new host tool requires only a new profile — `canonical/`
      and existing profiles are untouched.
- [ ] AC4: The profile is the per-tool capability registry (hooks,
      `skill_chaining`, `background_execution`, `stop_hook_autocontinue`).
- [ ] AC5: `CONTRIBUTING.md`'s "update all locations" rule is replaced with "edit
      `canonical/`, run the generator" — retires tech-debt **H4** and **H5**.
- [ ] AC6: The `setup.sh` / `setup.ps1` Codex branch copies the full Codex tree
      (`codex/.codex/` and `codex/.agents/`) — retires tech-debt **H6**.

## 7. Status

- Interview: complete (this REQUIREMENTS.md is the slim derivation from
  `work-001`'s prior FR5 + cross-reference research).
- Specify: complete (feature-001 SPEC graded A; independently re-graded A with
  5 cosmetic MINORs).
- **Ready for `/aid-plan`.**
