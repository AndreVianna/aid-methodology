# Requirements

- **Name:** release-aid — Maintainer Release Skill
- **Description:** A repo-local, maintainer-only operations skill that executes the AID repo's own release process end-to-end — `/release-aid <level>` (`major|minor|patch|beta`) — from the command to artifacts published on every channel with all checks green, making the release-notes + documentation sweep a mandatory step of every release.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | Initial capture | direct |

## 1. Objective

Turn the AID repo's release *process* into a runnable artifact. Today the process
exists only as a static format/architecture spec (`.aid/knowledge/infrastructure.md`)
plus a partial manual runbook (`docs/release.md`); nothing *executes* it and nothing
enforces that the release notes and documentation are brought current as part of the
release. `release-aid` is a maintainer skill invoked `/release-aid <level>` that runs
the whole sequence — resolve the target version, check preconditions, bump the version
carriers, rewrite the release notes and sweep every documentation surface, open the
release PR, dry-run and tag the release, and verify every channel is green — pausing
only at the three irreversible, human-gated points (PR merge, tag push, publish
confirmation). It is a maintainer tool like `generate-profile`: it operates on the AID
repo itself and is never shipped to adopters.

## 2. Problem Statement

The release procedure had no enforced step to update the notes or audit the docs, so
they drifted — a defect the settled design fixes by making the release-notes + full
documentation sweep (Step 3) a mandatory part of every release. Concretely, at capture
time (VERSION = `2.2.3-beta.1`):

- **Release notes drifted.** `.aid/knowledge/release-tracking.md`'s newest version
  section is `v2.0.6` (2026-07-07); `v2.1.0`, `v2.2.1`, `v2.2.2`, and `v2.2.3-beta.1`
  all shipped with **no section**, and its `## Unreleased` block still holds
  already-shipped items (e.g. work-018/PR #147, work-002/PR #133).
- **README froze.** `README.md` still leads with `## What's New in v1.1.0` — two majors
  stale for a repo now on the `2.x` line.
- **The KB contradicts reality.** `infrastructure.md` still states `NPM_ENABLED` /
  `PYPI_ENABLED` = false ("releases publish to GitHub Releases only") even though
  `v2.1.0`+ publish to both npm and PyPI.

Root cause: the release had no runnable procedure and no step that owned the notes and
docs. A static spec and a partial runbook cannot enforce "update the notes every time."

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| AID repo maintainer | Runs `/release-aid <level>` to cut a beta or stable release of the AID methodology repo | One command drives the whole release; the notes + docs are brought current automatically; irreversible steps pause for a human; a red gate stops rather than being forced |
| Adopter / repo visitor | Reads the README, changelog, KB, and docs site | Never sees a version two releases stale or a KB fact that contradicts what actually ships |
| AID methodology (this repo) | Owns the release format/architecture (`infrastructure.md`) and runbook (`docs/release.md`) | The skill executes that documented process faithfully and closes the notes/docs gap the spec + runbook leave open |

## 4. Scope

### In Scope

- A `.claude/skills/release-aid/SKILL.md` skill invoked `/release-aid <level>` with a
  **required** `<level>` argument (`major|minor|patch|beta`).
- The full release sequence: RESOLVE (Step 0) → PRECHECK (Step 1) → BUMP (Step 2) →
  DOCS+NOTES (Step 3: 3.1 ledger + 3.2 documentation sweep) → PR (Step 4, human-gated
  merge) → DRY-RUN (Step 5) → TAG (Step 6, human-gated) → VERIFY (Step 7) → CONFIRM
  (Step 8) → close-out (Step 9).
- Version math that bumps the named level and zeros every level below it, including the
  patch-from-beta **promote** rule.
- The mandatory Step 3 that (3.1) renames the release-notes ledger and (3.2) audits and
  updates every affected documentation surface (README, KB, `docs/`, the docs site,
  methodology content).
- The beta-vs-stable channel matrix and the four version carriers, including the npm
  carrier exemption for betas.
- The three human-gated pauses and otherwise-autonomous execution.
- A one-time reconciliation of the pre-existing broken ledger + docs backlog
  (`v2.1.0`–`v2.2.3-beta.1`) — surfaced by this work; handled as the separate one-time
  task-003, run now (OD-1 resolved — see §8).

### Out of Scope

- Modifying the release CI (`release.yml`), `release.sh`, `check-version-sync.sh`, or
  any other release infrastructure — the skill *drives* the existing pipeline; it does
  not change it.
- Shipping the skill to adopters: it is never added to `canonical/`, never rendered to
  `profiles/`, and never included in a release tarball (see NFR-1).
- Authoring *adopter-project* changelogs — that is the `aid-document-changelog` skill's
  job; this skill owns only the AID-repo ledger rename (3.1) and doc sweep (3.2).
- Automating the human-gated steps (PR merge, tag push, publish confirmation).

## 5. Functional Requirements

- **FR-1 — Required level argument.** `/release-aid <level>` requires exactly one of
  `major | minor | patch | beta`. If the argument is missing or not one of the four
  values, the skill STOPs and asks one clear question which level to release — it does
  **not** default, guess, read `VERSION`, or proceed until a valid level is chosen.
- **FR-2 — Resolve the target version (Step 0).** Read the current version from the
  `VERSION` file (the source of truth; never trust a version hard-coded in prose).
  Compute the target by bumping the named level and **zeroing every level below it**:
  `major`→`(M+1).0.0`; `minor`→`M.(m+1).0`; `patch`→ from stable `M.m.(p+1)`, **from a
  beta PROMOTE to `M.m.p` (drop the `-beta.N`, do not bump)**; `beta`→ from stable
  `M.m.(p+1)-beta.1`, from a beta `M.m.p-beta.(N+1)`. Print `current -> target` and the
  resulting channel plan.
- **FR-3 — Preconditions (Step 1).** STOP on any failure, never force: on `master`;
  clean worktree up to date with `origin/master`; no `v<target>` tag collision; the
  latest `master` `test.yml` run green; render-drift clean (`run_generator.py` then
  `git diff --exit-code -- profiles/`). The sole tolerated local mod is
  `.aid/.aid-manifest.json` (`git checkout --` it — it is not a release carrier).
- **FR-4 — Bump the version carriers (Step 2).** The four carriers are `VERSION`,
  `packages/npm/package.json`, `packages/pypi/pyproject.toml`, and the git tag
  `v<target>`. For a **stable** release set all three files to `<target>`; for a
  **beta** set only `VERSION` + `pyproject.toml` (SemVer `X.Y.Z-beta.N`) and leave
  `packages/npm/package.json` at the last stable — the version-sync gate detects the
  pre-release and exempts the npm carrier. A beta version MUST be SemVer
  `X.Y.Z-beta.N` (with the dash), never PEP 440 `X.Y.ZbN`.
- **FR-5 — Release-notes ledger (Step 3.1).** Rename `release-tracking.md`'s
  `## Unreleased` to `## v<target> - <YYYY-MM-DD>` (today, UTC), open a fresh empty
  `## Unreleased` above it, and add a row to the file's `## Change Log` table. Only
  items that genuinely ship in THIS version belong; if the ledger has fallen behind
  (Unreleased holds already-shipped items, or intermediate versions have no section),
  reconcile against the published GitHub Releases + `git log <last-tag>..HEAD` before
  renaming.
- **FR-6 — Documentation sweep (Step 3.2).** Derive "what changed" from this version's
  `release-tracking.md` items + `git log <last-tag>..HEAD`, then audit and update every
  affected surface: `README.md` (a short "recent releases → changelog / GitHub Releases"
  pointer — **no** per-version "What's New" block, per OD-2; plus any command/feature
  enumeration the release changed); the KB under
  `.aid/knowledge/` (`capability-inventory.md`, `module-map.md`, `infrastructure.md`,
  `technology-stack.md`, and any other affected doc); `docs/`; the docs site under
  `site/src/content/docs/` (leave the release changelog page — a sibling tree at
  `site/src/pages/releases/changelog.astro`, not under `content/docs/` — auto-sourced
  from GitHub Releases); and methodology content (edit `canonical/` and re-render via
  `generate-profile` — never hand-edit `profiles/`). Every edit stays truthful: never
  backfill a newer feature into a historical, version-frozen section.
- **FR-7 — PR the bump + notes (Step 4, human-gated merge).** Branch off `master`,
  commit all of Steps 2–3 (the carriers, the ledger rename, and every file the 3.2
  sweep touched — never `.aid/.aid-manifest.json`), push, and open a PR (switch `gh` to
  `AndreVianna` for the push/PR, restore after). Verify each PR check individually,
  then PAUSE and hand the `gh pr merge` command to the human — the auto-mode classifier
  blocks `gh pr merge`.
- **FR-8 — Sync + dry-run (Step 5).** After the merge, `git checkout master && git pull`,
  then dispatch `release.yml` with `-f ref=master -f dry_run=true` (publishes nothing:
  npm does `npm pack --dry-run`, PyPI skips upload). Verify each dry-run job green before
  tagging. Use `-f ref=master` (not the not-yet-existing tag).
- **FR-9 — Tag + push (Step 6, human-gated).** PAUSE for explicit confirmation before
  tagging — a published version can never be reused. On confirmation, switch `gh` to
  `AndreVianna`, `git tag v<target> && git push origin v<target>` (triggers `release.yml`).
- **FR-10 — Verify the release workflow (Step 7).** Inspect each job's conclusion
  individually (a `gh run watch` / `gh ... --watch` exit 0 is **not** proof every job
  passed). Expected by channel — stable: `gate` pass, `github-release` pass (release =
  latest), `pypi-publish` pass, `npm-publish` pass; beta: `gate` pass, `github-release`
  pass (release marked **prerelease**, carries skill tarballs), `pypi-publish` pass,
  `npm-publish` **skipped**. A failing `NM08` npm-pack on a stable is a known flake —
  `gh run rerun --failed`.
- **FR-11 — Confirm artifacts + close out (Steps 8–9, human-gated publish confirmation).**
  (Step 8) Confirm the artifacts landed — PyPI via `/simple/` (beta normalizes
  `-beta.N`→`bN`); the GitHub Release (beta = `Pre-release: true` and NOT
  `/releases/latest`; stable = latest; assets = 5 profile tarballs +
  `aid-cli-v<target>.tar.gz` + the 2 install-core libs + `SHA256SUMS`); npm for stable
  only — then PAUSE and present the confirmed-publish report to the human, awaiting
  acknowledgment before close-out (the third human-gated point; the version is now live
  and can never be reused). (Step 9) Restore the `gh` account to `AndreVianna-Ross` and
  report the version, the channels, the release URL, and that `release-tracking.md` +
  README were updated (so the next run starts from a clean Unreleased).
- **FR-12 — Autonomy + pause contract.** Run Steps 0–9 straight through without
  per-step check-ins EXCEPT the three ⏸ human-gated points: the PR merge (Step 4), the
  tag push (Step 6), and confirming the publish (Step 8). Surface any precondition
  failure, red check, or version-math ambiguity rather than working around it.

## 6. Non-Functional Requirements

- **NFR-1 — Repo-local, never shipped.** The skill lives only at
  `.claude/skills/release-aid/`; it is NOT in `canonical/skills/`, is NOT rendered to
  any `profiles/*` tree, carries **no** `aid-` prefix, and is never included in a
  release tarball — a maintainer tool exactly like `generate-profile`. It is edited
  directly (no canonical source to render from).
- **NFR-2 — Fail-safe gating.** The skill STOPs and surfaces the failure on any red
  precondition, any red CI check, or any version-math ambiguity — it never forces a
  dirty tree, never publishes past a red gate, and never works around a failure.
- **NFR-3 — `gh` account hygiene.** The active `gh` account silently reverts to
  `AndreVianna-Ross`; the skill switches to `AndreVianna` immediately before EACH
  push/PR/tag and restores `AndreVianna-Ross` after.
- **NFR-4 — Documentation truthfulness.** The 3.2 sweep never adds an unreleased/newer
  feature to a historical, version-frozen section; cumulative history lives in the
  changelog / GitHub Releases, and a "What's New in vX" block describes only vX.
- **NFR-5 — Beta version-format integrity.** A beta version is always SemVer
  `X.Y.Z-beta.N` (with the separator); a PEP 440 `X.Y.ZbN` form is never written,
  because the CLI tool-bundle name regex needs the separator (PyPI normalizes
  `-beta.N`→`bN` on publish) and a PEP-440 form makes `aid add/update --from-bundle`
  reject the bundle and CI go red.

## 7. Constraints

- The skill is a markdown procedure driven by `Read, Glob, Grep, Bash, Write, Edit`; it
  drives the existing release pipeline (`release.yml`, `release.sh`,
  `check-version-sync.sh`) and does not modify it.
- `VERSION` is the single source of truth for the current version; the target is always
  computed from it, never from a number in prose.
- The four version carriers must agree (the release `gate` runs `check-version-sync.sh`);
  betas exempt the npm carrier.
- Pushes/PRs/tags to `AndreVianna/aid-methodology` require the `AndreVianna` `gh`
  account.
- The PR merge cannot be performed by the skill (auto-mode classifier blocks
  `gh pr merge`); it is handed to the human.

## 8. Assumptions & Dependencies

- **Depends on** the existing release infrastructure: `.github/workflows/release.yml`
  (tag-triggered gate → github-release → npm/PyPI), `release.sh`,
  `canonical/aid/scripts/release/check-version-sync.sh`, and the `generate-profile`
  skill for render-drift + methodology re-render.
- **Depends on** `gh` authenticated with both the `AndreVianna` and `AndreVianna-Ross`
  accounts, and on branch protection requiring a PR into `master`.
- Assumes `.aid/knowledge/release-tracking.md` is the release-history ledger and its
  `## Unreleased` block is the accumulator for the next version.
- **OD-1 (RESOLVED 2026-07-22 — separate one-time cleanup).** The pre-existing broken
  ledger backlog (`v2.1.0`–`v2.2.3-beta.1` sections + the stale Unreleased items, the
  frozen README, and `infrastructure.md`'s stale npm/PyPI claim) is handled as a
  **separate one-time cleanup** — this work's **task-003**, run now while the release is
  on hold — **not** auto-reconciled by the skill's first run. The skill's Step 3.1
  "reconcile if behind" guard remains only as a safety net; the skill maintains the
  ledger going forward.
- **OD-2 (RESOLVED 2026-07-22 — pointer only).** The 3.2 sweep keeps `README.md` as a
  short **"recent releases → changelog / GitHub Releases" pointer** with **no**
  version-specific "What's New" block (the shape that froze at v1.1.0). Self-maintaining;
  nothing version-specific to go stale. SKILL.md Step 3.2 and FR-6 state this definitively.

## 9. Acceptance Criteria

- **AC-1 (FR-1)** — Given `/release-aid` invoked with no argument or an argument outside
  `{major, minor, patch, beta}`, when the skill starts, then it stops and asks one clear
  question naming the four valid levels, and does not read `VERSION` or proceed until a
  valid level is chosen.
- **AC-2 (FR-2)** — Given `VERSION` = `2.2.3-beta.1`, when the level is `beta` / `patch`
  / `minor` / `major`, then the resolved target is `2.2.3-beta.2` / `2.2.3` / `2.3.0` /
  `3.0.0` respectively (patch-from-beta **promotes** by dropping `-beta.N`); and given a
  stable `2.2.3`, `patch`→`2.2.4` and `beta`→`2.2.4-beta.1`. The target is always derived
  from the `VERSION` file, never from prose.
- **AC-3 (FR-3, NFR-2)** — Given any precondition fails (not on `master`, a dirty tree
  beyond `.aid/.aid-manifest.json`, a `v<target>` tag collision, a red latest `test.yml`,
  or render drift), when PRECHECK runs, then the skill STOPs and reports the failure
  rather than forcing it; the only local mod it auto-cleans is `.aid/.aid-manifest.json`.
- **AC-4 (FR-4, NFR-5)** — Given a stable target, when BUMP runs, then `VERSION`,
  `packages/npm/package.json`, and `packages/pypi/pyproject.toml` are all set to
  `<target>`; given a beta target, then only `VERSION` + `pyproject.toml` are set to the
  SemVer `X.Y.Z-beta.N` form and `packages/npm/package.json` stays at the last stable
  (npm carrier exempt). A PEP-440 `X.Y.ZbN` form is never written.
- **AC-5 (FR-5)** — Given the release, when the notes are stamped, then
  `release-tracking.md`'s `## Unreleased` becomes `## v<target> - <UTC-date>`, a fresh
  empty `## Unreleased` is opened above it, a `## Change Log` row is added, and only
  items shipping in THIS version appear — if the ledger is behind, it is reconciled
  against the GitHub Releases + `git log <last-tag>..HEAD` before renaming.
- **AC-6 (FR-6, NFR-4)** — Given the release, when the 3.2 sweep runs, then `README.md`,
  every affected `.aid/knowledge/` doc (`capability-inventory`, `module-map`,
  `infrastructure`, `technology-stack`, …), `docs/`, and the docs site under
  `site/src/content/docs/` are audited and updated for every changed
  command/behavior/version (the release changelog page — a sibling tree at
  `site/src/pages/releases/changelog.astro`, not under `content/docs/` — is auto-sourced
  from GitHub Releases and left alone); methodology-surface changes are
  made in `canonical/` and re-rendered via `generate-profile` (never hand-edited in
  `profiles/`); and no newer feature is backfilled into a version-frozen section.
- **AC-7 (FR-7, NFR-3)** — Given Steps 2–3 are committed on a `release-<target>` branch
  (never including `.aid/.aid-manifest.json`), when the PR is opened (as `AndreVianna`),
  then the skill verifies each PR check individually and PAUSEs, handing the
  `gh pr merge` command to the human rather than merging itself, and restores
  `AndreVianna-Ross` after the push/PR.
- **AC-8 (FR-8)** — Given a merged `master`, when DRY-RUN runs, then `release.yml` is
  dispatched with `-f ref=master -f dry_run=true` (publishing nothing), and each
  dry-run job is verified green before any tag is pushed.
- **AC-9 (FR-9)** — Given a green dry-run, when TAG runs, then the skill PAUSEs for
  explicit human confirmation before pushing the irreversible `v<target>` tag.
- **AC-10 (FR-10)** — Given the tag triggered `release.yml`, when VERIFY runs, then each
  job's conclusion is inspected individually (not just the `gh run watch` exit code);
  for a stable, `gate` / `github-release` (latest) / `pypi-publish` / `npm-publish` all
  pass; for a beta, `gate` / `github-release` (prerelease, carries skill tarballs) /
  `pypi-publish` pass and `npm-publish` is **skipped**.
- **AC-11 (FR-11, NFR-3)** — Given `release.yml` succeeded, when CONFIRM runs, then PyPI
  is checked via `/simple/` (beta normalized to `bN`); the GitHub Release is verified
  (beta = `Pre-release: true` and not latest; stable = latest; assets = 5 profile
  tarballs + `aid-cli-v<target>.tar.gz` + the 2 install-core libs + `SHA256SUMS`); npm
  is checked for stable only; the skill then PAUSEs to present the confirmed-publish
  report and awaits human acknowledgment before close-out (the third human-gated point);
  and at close-out the report names the version, channels, and release URL, notes that
  `release-tracking.md` + README were updated, and the `gh` account is restored to
  `AndreVianna-Ross`.
- **AC-12 (FR-12)** — Given a valid level and passing preconditions, when the skill
  runs, then Steps 0–9 proceed autonomously with exactly three human-gated pauses (PR
  merge, tag push, publish confirmation) and no other per-step check-ins.
- **AC-13 (NFR-1)** — Given the skill exists, then it is present only at
  `.claude/skills/release-aid/`, carries no `aid-` prefix, is absent from
  `canonical/skills/` and from every `profiles/*/` tree, and is never included in a
  release tarball.

## 10. Priority

**Must.** The skill (SKILL.md) is already authored and is the authoritative procedure;
this work formalizes it and defines validation + the pre-existing-backlog reconciliation.
