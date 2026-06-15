# task-014: v1.0/v1.1 bootstrap runbook (manual, per-repo, no scan)

**Type:** DOCUMENT

**Source:** feature-005-bootstrap-and-test-migration → delivery-003

**Depends on:** task-013

**Scope:**
- Document the bootstrap procedure (feature-005 "Approach — Bootstrap"). This task carries **no production code** — bootstrap is a procedure composed from feature-003 (stamp) + feature-004 (register); the behavior already ships in tasks 005/006/010/011/012.
  - Write the runbook: on encounter (`cd <repo>` + any repo-command) the feature-003 stamp comparison fires; `aid update` runs `__migrate-repo`, writes `format_version: 1`, and feature-004 registers the repo in the appropriate tier (user always; shared on global + opt-in, best-effort). Carry-forward: subsequent visits read the current stamp and do nothing.
  - Concrete dogfood-machine recipe: visit each known repo one-by-one — `~/projects/*` and the `/srv/projects/*` `group developers` repos the old `$HOME`-only scan never saw — `cd <repo> && aid update`. No globbing into a scan loop; the maintainer chooses the order. Note that `update self` additionally batch-migrates already-registered repos with per-repo confirm. External upgraders follow the identical procedure.
  - Cover the edge cases as runbook notes: no-git repo (operates anyway, no-persistence note), no-`.aid/` (offer `aid add`, not a target), mid-bootstrap interruption (each repo's stamp is its own done-state; lazy catch-all), elevation-declined shared register (skip+warn, stamp still written).
- Place the runbook at `.aid/work-001-cli-install-scope/bootstrap-runbook.md` (the work's rollout-docs location).

**Acceptance Criteria:**
- [ ] The runbook documents the on-encounter stamp+register flow and the carry-forward no-op, with the explicit `cd <repo> && aid update` per-repo recipe and the "no scan, maintainer chooses order" guarantee.
- [ ] It names the dogfood targets (`~/projects/*`, `/srv/projects/*`) and the external-upgrader procedure, and distinguishes the manual first-pass from `update self` batch migration of already-registered repos.
- [ ] The edge cases (no-git, no-`.aid/`, mid-bootstrap interruption, elevation-declined) are documented as runbook notes.
- [ ] The doc is ASCII-only and references no machine-wide scan.
- [ ] All §6 quality gates pass.
