# Delivery SPEC -- delivery-002: Infra Debt Paydown

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-002
> **Work:** work-001-aid-interview-improvements
> **Created:** 2026-06-27

---

## Objective

Pay down four pieces of maintainer-infrastructure debt that were folded into this work as small,
self-contained side tasks. They are wholly independent of the elicitation/interview redesign and of
each other, so they ship as one coherent "infra hardening" delivery that can run in parallel with
the research spike. The value is durable CI/release safety: the install manifests can no longer
silently drift, the repository-structure doc stops lying about counts/paths, the visual validator
catches responsive breakage, and the npm/PyPI publish-enablement debt (M1) is resolved -- either
closed (publishing enabled + verified by the owner) or, as feature-007 recommends, explicitly
deferred-with-rationale (its closure is externally blocked and owner-only).

## Scope

feature-007-infra-debt-paydown, comprising:
- **H1** -- `tests/canonical/test-install-manifests-lockstep.sh`: assert the 5 install manifests
  agree on the dashboard 12-file set.
- **M3** -- refresh `repository-structure.md`: correct the file/script counts, all three prose
  paths (templates / recipes / scripts), and the ASCII directory tree.
- **M4** -- add a multi-viewport check (T4) to `validate-visuals.mjs`.
- **M1** -- npm/PyPI publish **enablement** (NOT a code change: the `release.yml` jobs are already
  correct and gated on `vars.NPM_ENABLED`/`vars.PYPI_ENABLED`). Closure is owner-only + externally
  blocked (account/scope/Trusted-Publisher setup + a repo-variable flip); feature-007 recommends
  **deferral with rationale**, which satisfies AC-9 for this item.
- **R1 (added 2026-06-27, owner direction)** -- grant `aid-researcher` web tools (`WebSearch` +
  `WebFetch`) + regen. Debt discovered executing delivery-001: the RESEARCH spike needed a web
  survey but the canonical RESEARCH executor had no web tools, forcing a `general-purpose` fallback.

**Out of scope:** the elicitation research (delivery-001); features 002-006; any change to the
`aid-interview` skill itself. No new product behavior -- this is maintainer tooling/test/doc only.

## Gate Criteria

- [ ] H1 test exists, fails when any one of the 5 manifests diverges on the dashboard file set, and
  passes on the current (agreeing) tree; wired into the canonical suite run by CI.
- [ ] M3 -- `repository-structure.md` counts, all three prose paths, and the ASCII tree match the
  current tree on disk (verifiable by re-counting).
- [ ] M4 -- `validate-visuals.mjs` exercises multiple viewports and flags responsive regressions.
- [ ] R1 -- `aid-researcher` frontmatter `tools:` includes `WebSearch` + `WebFetch`, propagated to
  the 5 profiles + `.claude` mirror (DBI byte-identity, render-drift clean); no other agent changed.
- [ ] M1 -- the publish-enablement debt is **either closed** (owner has created the npm `@aid`
  scope + PyPI org/Trusted-Publisher and flipped `NPM_ENABLED`/`PYPI_ENABLED`, with a tagged
  release confirming both publish jobs run + the package resolves on each channel) **or explicitly
  deferred-with-rationale** recorded in the work `STATE.md` + the `tech-debt.md` M1 row (per
  feature-007 AC-9 — an explicit deferral satisfies the criterion; the existing OIDC-ready gate is
  NOT itself the deliverable).
- [ ] All section-6 quality gates pass (incl. the master-only heavy gates: `tests/run-all.sh`
  HOME-pinned + the `site` Astro build, per the master-CI-only-on-master constraint).

## Tasks

{Filled by aid-detail -- likely one task per debt item (H1 TEST, M3 DOCUMENT, M4 TEST, M1 CONFIGURE).}

| Task | Type | Title |
|------|------|-------|
| task-004 | TEST | install-manifests-lockstep suite (H1) |
| task-005 | DOCUMENT | refresh docs/repository-structure.md (M3) |
| task-006 | IMPLEMENT | T4 multi-viewport check in validate-visuals.mjs (M4) |
| task-007 | TEST | verify T4 catches a clip + wire suite (M4) |
| task-008 | DOCUMENT | record M1 publish-enablement deferral (M1) |
| task-009 | CONFIGURE | grant aid-researcher web tools (R1) |

## Dependencies

- **Depends on:** -- (none; fully independent)
- **Blocks:** -- (none)

## Notes

Parallel-capable with delivery-001 (disjoint surfaces: this touches install/test/doc/release infra,
the spike touches only `.aid/` research artifacts). The four items are mutually independent, so
aid-detail can wave them in parallel within the delivery. M1 cannot be closed by an agent (its
work is external + owner-only); the realistic execution path is the recommended
deferral-with-rationale, recorded in the work `STATE.md` + `tech-debt.md` M1 row.
