# Delivery BLUEPRINT -- delivery-001: Green, CI-gated site test suite

[!NOTE]
This is the IMMUTABLE DEFINITION of delivery-001. Written once by aid-plan; not a state file —
delivery-001's lifecycle, gate and Q&A live in `deliveries/delivery-001/STATE.md`.

> **Delivery:** delivery-001
> **Work:** work-001-skill-explorer
> **Created:** 2026-07-26

---

## Objective

Make the `site/` test suite trustworthy before anything in this work depends on it. The suite is
red today — two of its roster assertions hard-code a 94-directory corpus and a 76-shortcut total
against a real 111 and 64 — and no CI workflow runs it at all, which is precisely why that
staleness went unnoticed. Every acceptance criterion in this work after AC-1 is specified as a
vitest test, so shipping the generator ahead of a working, CI-gated suite would leave the
quality claims of every later deliverable unenforced on the pull requests that introduce them.
This delivery corrects the stale assertions by re-deriving them from source, triages the five
TypeScript suites that have never executed in CI, and only then wires `npm test` into
`docs.yml`. It is scoped as a distinct unit because its final step is an open-ended triage whose
findings must not be able to block the generator's own gate.

## Scope

Feature-001's owner-amended §7 build-integration scope only (REQUIREMENTS.md §7, "Amended
2026-07-25"), in three ordered parts:

- **Part A — correct the stale roster assertions** in `site/scripts/__tests__/gen-reference.test.mjs`.
  Eight items, not the two originally named: the `CURATED_SKILL_NAMES` constant (18 names where
  the generator curates 21 — missing the three ticket skills), two `toHaveLength` assertions, one
  latent length assertion, the family-table `**Total**` regex, two `it` titles and one comment.
  Each replaced by a check **re-derived** from `canonical/skills/` and `shortcut-catalog.yml`, plus
  a clamp that fails by name for any on-disk directory that is neither a catalog row nor in the
  curated roster.
- **Part C — triage the full suite on a clean install.** Five TypeScript suites have never run in
  CI and cannot load in this worktree; their assertions are unverified and may carry staleness of
  the same kind.
- **Part B — add the `npm test` step** to `docs.yml`'s build job, between `npm ci` (vitest is a
  devDependency) and `npm run build` (fail fast; a red suite must not produce a Pages artifact).

Also decided here, while `docs.yml` is already open: **feature-005's OQ-3** — whether the
workflow's path filter should gain `canonical/**`, since today a commit editing `canonical/`
without regenerating pages triggers no docs build.

**Out of scope:** the `/skills/` generator itself and every page it emits (delivery-002);
`gen-reference.mjs`, which §7 freezes — it is **byte-unmodified** by this delivery, so KI-003,
KI-009 and KI-010 stay open; `site/astro.config.mjs`, untouched here.

## Gate Criteria

- [ ] All eight stale roster items in `gen-reference.test.mjs` are corrected, and **no corrected
      assertion carries a hard-coded corpus count** — each re-derives from `canonical/skills/` and
      `shortcut-catalog.yml` (§8 forbids hard-coded counts, and a hard-coded count is the defect
      that produced KI-005).
- [ ] The clamp assertion fails **by name** for an on-disk skill directory that is neither a
      catalog row nor in the curated roster — verified against the three ticket skills, which is
      the drift that went unnoticed.
- [ ] `npm test` in `site/` exits 0 on a clean `npm ci`, for the **whole** suite — including the
      five TypeScript suites that have never executed in CI, not only the corrected file.
- [ ] Anything Part C surfaces beyond the eight known items is either fixed within this delivery
      or **escalated to the owner as a gate escalation** — not absorbed as silent scope.
- [ ] `docs.yml`'s build job runs the suite between `npm ci` and `npm run build`, so a red suite
      fails the pull request and no Pages artifact is produced from one.
- [ ] `gen-reference.mjs` is **byte-unmodified**, its throw-on-drift guard still passes, and its
      four generated reference pages are byte-unchanged after a full `prebuild`.
- [ ] feature-005's OQ-3 (whether `docs.yml`'s path filter gains `canonical/**`) is answered and
      recorded, either way.
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | TEST | Source-derived roster checks and the drift clamp in `gen-reference.test.mjs` |
| task-002 | RESEARCH | Clean-install triage record for the whole `site/` vitest suite |
| task-003 | TEST | Absorbed stale-assertion corrections in the five TypeScript suites |
| task-004 | CONFIGURE | `npm test` gate step in `docs.yml`'s build job |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** delivery-002 (and, transitively, every later delivery — each of their acceptance
  criteria is a vitest test that nothing would run until this lands)

## Notes

- Splitting feature-001 across delivery-001 and delivery-002 is **deliberate**: clauses (b), (c)
  and (d) of its build-integration criterion belong here; clause (a) and AC-1 / AC-2 / AC-6 belong
  to delivery-002. Feature-001's own Migration Plan argues for exactly this separability.
- The two `git diff`-based idempotency failures observed in this worktree are **environmental** —
  the worktree's `.git` file holds a WSL path Windows `git` cannot resolve. Re-running both
  generators left every tracked output byte-identical. Do not chase them as defects.
- KI-005 and KI-006 are the two known issues this delivery closes.
