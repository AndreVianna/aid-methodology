# Design Note — CI: Stronger *and* Faster

**Status:** Pre-scoping — NOT yet a tracked work. Captured 2026-06-29 (post-v2.0.0). Reframed during
discussion from "release-pipeline hardening" — the goal is **more release safety without making the
per-PR pipeline slower** (it is already ~5 min on every push, which the owner flagged as a real cost).

**Motivation.** Two release-*blocking* bugs were latent in the v2.0.0 release and were only caught by a
manual pre-tag dry-run:
1. `check-version-sync.sh` resolved the repo root at a fixed `../../..` depth that broke when work-005
   moved scripts under `canonical/aid/scripts/` → it couldn't find `VERSION`, exit 1.
2. `release.yml`'s gate ran a "Pre-seed pinned Mermaid" step calling a script (`fetch-mermaid.sh`)
   deleted when the Mermaid engine was dropped → exit 127.

Both hid for the same reason: **`release.yml`'s gate has no `pull_request` trigger** — it runs only on a
tag push or manual dispatch, so normal PR CI never exercises it. Bugs in the release machinery surface
only on release day, at the worst moment.

---

## Problem (two halves)

- **Release machinery is untested during normal work.** The gate + build half of `release.yml` (run
  tests, assert version-sync, build tarballs) is exactly where both bugs lived, and it never runs on a PR.
- **Every PR runs the full lane set regardless of what changed.** The heavy lanes (the Windows installer
  lane — slow even to spin up — and the Astro site build) run on a docs-only or script-only PR that can't
  possibly affect them. That is the ~5-min tax.

## Proposed approach (cheap-everywhere, expensive-only-when-relevant)

1. **Cheap release-safety lint on every PR (seconds).** Assert that every script the workflows reference
   exists, and the workflow YAML is structurally sound (gate present, publish jobs `needs: [gate]`,
   permissions least-privilege, actions SHA-pinned — several of these already live in
   `test-version-sync.sh` WF01–WF05; extend with a "no dangling `run:`/`bash` script path" check). This
   alone would have caught the Mermaid bug instantly. Bolt onto an existing fast lane (KB hygiene ≈ 6 s).
2. **Expensive dry-run off the per-PR path.** The full publish-nothing dry-run (build tarballs, `npm pack
   --dry-run`, version-sync) runs on a **schedule** (e.g. nightly/weekly on master) and/or only on PRs
   that **touch release files** (`release.yml`, `release.sh`, `canonical/aid/scripts/release/**`, the
   version carriers). 95% of PRs touch none of these and pay nothing.
3. **Path-filter the heavy existing lanes.** Skip lanes a PR's changed paths can't affect (docs-only →
   skip installer + render-drift; script-only → skip Astro build; etc.). Most PRs then run a *subset* and
   go green **faster than today**.

**Net:** stronger where it matters (release machinery is now exercised), faster on the common case (most
PRs run less). The publish trigger is **unchanged** — publishing still happens only on a `v*` tag push.

## Key decisions / options to settle in scoping

- **Required-checks × path-filters gotcha (the main risk).** GitHub branch protection blocks merge on a
  *required* check that is *skipped*. If we path-filter a required lane, we must use the "skip but report
  a neutral/passing status" pattern (a stub job that succeeds when the real lane is filtered) — otherwise
  a docs-only PR can never go green. This is the one piece that needs careful design.
- **Schedule cadence** for the full dry-run (nightly vs weekly) — trade timeliness vs runner minutes.
- **Path-filter granularity** — per-lane changed-path globs; keep them conservative (false "skip" is worse
  than a false "run").

## Scope boundaries

CI / workflow configuration only. No change to what gets published or when. Not a rewrite of the test
suites — only *which* lanes run *when*.

## Open questions (need to read the workflows first)

- Current parallelism: are the lanes already independent jobs (so wall-clock = slowest lane)? What *is*
  the slowest lane (likely the Windows installer or the canonical suite)?
- Is there existing caching (Playwright browsers, npm/pip deps) that could be improved?
- Can the canonical suite shard, or is it dominated by a few slow suites?

## Relation to other work

Pairs with the fact-consistency gate (both CI-quality). The release-safety lint is a natural sibling of
`check-version-sync.sh`.
