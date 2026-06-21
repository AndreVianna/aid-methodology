# Delivery SPEC -- delivery-003: Lockstep Dependents + Final Acceptance Gate

> **Delivery:** delivery-003
> **Work:** work-005-profile-generator-simplify
> **Created:** 2026-06-20

---

## Objective

The thin integrating closeout: bring every residual cross-cutting dependent into lockstep with the new layout, then run the final acceptance gate and land the work. Residuals (no sibling owns them): `release.sh` codex tarball roots, `docs/*` + synced `site/*`, `CONTRIBUTING.md`, profile READMEs, and the KB (the content-isolation cornerstone R6 revision for Codex, the rules-mechanism term retirement, the capability-study promotion to a new `host-tool-capabilities.md`, INDEX/README regen). It then runs AC3 (all-green CI) + AC4 (multi-tool no-contamination, structural suite + behavioral check) and lands via PR to PR-protected master. This delivery also closes the Release-Safety Gate (its `release.sh` root fix is the last piece making the new layout release-safe).

## Scope

- **feature-004-lockstep-ci-closeout** — `release.sh` codex roots (`.agents .codex` → `.codex`); `docs/*` + `site/*` re-sync; `CONTRIBUTING.md`; profile READMEs; KB lockstep (R6 revision, term retirement, capability-study promotion, INDEX/README regen); the `tests/canonical/test-multitool-isolation.sh` structural suite; the AC3 + AC4 final gate; PR to master.

**Out of scope:** the generator/profiles (delivery-001) and the install/CLI twins (delivery-002). Pure numeric count reconciliation (script/suite counts) is deferred to a `/aid-housekeep` pass (semantic layout/term edits are in-scope here).

## Gate Criteria

- [ ] **AC3** — CI fully green: render-drift, `tests/run-all.sh` (53+ suites), generator self-tests (post-collapse), installer (Windows + Linux), the docs (Astro) build, and version-sync all pass. *(docs.yml is post-merge, not a PR gate — run the Astro build + INDEX-fresh checks locally before the PR.)*
- [ ] **AC4** — a real multi-tool repo (claude-code + cursor + codex) verified: each tool uses its own tree, no cross-tree contamination (structural `test-multitool-isolation.sh` + the 3-tool behavioral check per AC4a; Copilot/Antigravity asserted-via-D1, not exercised).
- [ ] No shipped artifact references the retired layout (`.agents/`, `.cursor/rules/`, `.agent/rules/`, codex split).
- [ ] `content-isolation.md` R6 revised for Codex `.codex/{agents,skills,aid}`; capability study promoted to `host-tool-capabilities.md`; INDEX/README regenerated.
- [ ] All section-6 quality gates pass

## Tasks

_none yet_ -- aid-detail will fill this.

| Task | Type | Title |
|------|------|-------|

## Dependencies

- **Depends on:** delivery-001, delivery-002 (runs against the settled layout + install behavior)
- **Blocks:** -- (none; final delivery)

## Notes

- This delivery's `release.sh` root fix is the **last piece** of the Release-Safety Gate — once it merges (with 001 + 002), the new layout is release-safe and `aid-deploy` may run.
- numeric count drift (13→7 scripts — actual delivered, not the ~4-script headline; suite count) is reconciled via `/aid-housekeep`, not inline here.
- **AC4 is two-part:** the structural no-contamination suite (`test-multitool-isolation.sh`) is **task-020**; the **behavioral** 3-tool check (Cursor + Claude Code + Codex; Codex gated on E-CODEX-1; Copilot/Antigravity asserted-via-Finding-D1, not exercised) is a **manual delivery-gate step**, NOT a task (it produces no file artifact). **AC3** (all-green CI + version-sync) is likewise the delivery gate, not a task. The 7 authored tasks are task-014..020.
