# release-aid — Maintainer Release Skill

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-22 | SPEC drafted from the settled SKILL.md design | direct |

## Source

- REQUIREMENTS.md §5 Functional Requirements (FR-1..FR-12)
- REQUIREMENTS.md §6 Non-Functional Requirements (NFR-1..NFR-5)
- REQUIREMENTS.md §9 Acceptance Criteria (AC-1..AC-13)
- Authoritative design: `.claude/skills/release-aid/SKILL.md` (mirrored below)
- Release format/architecture: `.aid/knowledge/infrastructure.md`; runbook: `docs/release.md`
- Repo-local, never-shipped precedent: `.claude/skills/generate-profile/SKILL.md`

## Description

`release-aid` is a maintainer-only skill that cuts one release of the AID methodology
repo — beta or stable — from a single command to artifacts published on every channel
with all checks green. It is invoked `/release-aid <level>` where `<level>` is exactly
one of `major | minor | patch | beta`. It runs the whole sequence autonomously except at
the three irreversible, human-gated points (the PR merge, the tag push, and confirming
the publish). Beyond executing the existing release pipeline, it closes the gap that the
static spec (`infrastructure.md`) and partial runbook (`docs/release.md`) leave open: it
**always** rewrites the release notes and sweeps every documentation surface as a
mandatory step (Step 3) of every release, so the notes and docs never drift again.

## User Stories

- As the AID repo maintainer, I want one command to cut a release end-to-end so that I do not have to hand-run a ten-step runbook and risk skipping a step.
- As the maintainer, I want the release to bring the release notes and all documentation current automatically so that the README, KB, and changelog never fall two releases behind.
- As the maintainer, I want the skill to pause only at the irreversible steps (PR merge, tag push, publish) and stop on any red gate so that automation never publishes a broken or unreviewed release.
- As an adopter, I want a released version's notes, README, and KB facts to reflect what actually shipped so that the docs never contradict the software.

## Priority

Must.

## Acceptance Criteria

- [ ] AC-1 (FR-1) — `/release-aid` with a missing/invalid level stops and asks one question naming the four valid levels; it does not read `VERSION` or proceed until a valid level is chosen.
- [ ] AC-2 (FR-2) — From `VERSION` = `2.2.3-beta.1`: `beta`→`2.2.3-beta.2`, `patch`→`2.2.3` (promote), `minor`→`2.3.0`, `major`→`3.0.0`; from stable `2.2.3`: `patch`→`2.2.4`, `beta`→`2.2.4-beta.1`. Target always derived from the `VERSION` file.
- [ ] AC-3 (FR-3, NFR-2) — Any failed precondition (not on `master`, dirty tree beyond `.aid/.aid-manifest.json`, tag collision, red `test.yml`, render drift) STOPs the release; only `.aid/.aid-manifest.json` is auto-cleaned.
- [ ] AC-4 (FR-4, NFR-5) — Stable sets all three files to `<target>`; beta sets only `VERSION` + `pyproject.toml` (SemVer `X.Y.Z-beta.N`) and leaves `package.json` at the last stable; a PEP-440 `X.Y.ZbN` form is never written.
- [ ] AC-5 (FR-5) — `## Unreleased` is renamed to `## v<target> - <UTC-date>`, a fresh empty `## Unreleased` opened above, a `## Change Log` row added, and only this-version items appear (reconcile if the ledger is behind).
- [ ] AC-6 (FR-6, NFR-4) — README, affected `.aid/knowledge/` docs, `docs/`, and `site/src/content/docs/` are audited and updated (the release changelog page — a sibling tree at `site/src/pages/releases/changelog.astro`, not under `content/docs/` — is auto-sourced from GitHub Releases and left alone); methodology changes go through `canonical/` + `generate-profile`, never hand-edited `profiles/`; no backfill into a version-frozen section.
- [ ] AC-7 (FR-7, NFR-3) — Steps 2–3 are committed on a `release-<target>` branch (never `.aid/.aid-manifest.json`); each PR check is verified individually; the skill PAUSEs and hands `gh pr merge` to the human; `AndreVianna-Ross` is restored after.
- [ ] AC-8 (FR-8) — DRY-RUN dispatches `release.yml` with `-f ref=master -f dry_run=true` (no publish) and each job is verified green before tagging.
- [ ] AC-9 (FR-9) — TAG PAUSEs for explicit human confirmation before pushing the irreversible `v<target>` tag.
- [ ] AC-10 (FR-10) — Each release-workflow job is inspected individually; stable = gate/github-release(latest)/pypi/npm all pass; beta = gate/github-release(prerelease + tarballs)/pypi pass, npm-publish **skipped**.
- [ ] AC-11 (FR-11, NFR-3) — PyPI checked via `/simple/` (beta→`bN`); GitHub Release verified (beta prerelease + not latest; stable latest; 5 tarballs + aid-cli + 2 libs + SHA256SUMS); npm for stable only; the skill then PAUSEs to present the confirmed-publish report and awaits human acknowledgment before close-out (third human-gated point); at close-out the report names version/channels/URL + notes-and-README update and `gh` is restored to `AndreVianna-Ross`.
- [ ] AC-12 (FR-12) — Steps 0–9 run autonomously with exactly three human-gated pauses (PR merge, tag push, publish confirmation).
- [ ] AC-13 (NFR-1) — The skill lives only at `.claude/skills/release-aid/`, has no `aid-` prefix, is absent from `canonical/skills/` and every `profiles/*/`, and is never in a release tarball.

---

## Technical Specification

> Mirrors `.claude/skills/release-aid/SKILL.md` (the authoritative artifact). Where this
> SPEC and the SKILL.md disagree, the SKILL.md wins and this SPEC is corrected.

### Where the skill lives & how it is invoked

- **Location:** `.claude/skills/release-aid/SKILL.md` — repo-local, maintainer-only.
  NOT in `canonical/skills/`, NOT rendered to any `profiles/*` tree, **no** `aid-`
  prefix, never shipped in a release tarball. Edited directly (no canonical source),
  exactly like `generate-profile` (NFR-1 / AC-13).
- **Invocation:** `/release-aid <level>`, `allowed-tools: Read, Glob, Grep, Bash, Write,
  Edit`, `argument-hint: "<level> REQUIRED: major | minor | patch | beta"`. The
  argument is **required**; a missing/invalid value STOPs and asks (FR-1 / AC-1).

### Workflow (the sequence + the three pause points)

Ten numbered steps (Step 0–Step 9) grouped into the named phase sequence RESOLVE →
PRECHECK → BUMP → DOCS+NOTES → PR → DRY-RUN → TAG → VERIFY → CONFIRM → close-out. `⏸`
marks a human-gated pause.

| Step | Phase | What happens | FR / AC |
|------|-------|--------------|---------|
| 0 | RESOLVE | Read `VERSION`; compute target by the level (bump named level, zero below; patch-from-beta promotes); print `current -> target` + channel plan | FR-2 / AC-2 |
| 1 | PRECHECK | STOP on any failure: on `master`; clean tree up-to-date w/ `origin/master`; no `v<target>` tag; latest `master` `test.yml` green; render-drift clean. Only `.aid/.aid-manifest.json` is auto-cleaned | FR-3 / AC-3 |
| 2 | BUMP | Set the version carriers per the channel matrix (stable = 3 files; beta = `VERSION` + `pyproject.toml`, npm exempt) | FR-4 / AC-4 |
| 3.1 | DOCS+NOTES | Rename `release-tracking.md` `## Unreleased` → `## v<target> - <UTC-date>`; open fresh `## Unreleased`; add `## Change Log` row; reconcile if behind | FR-5 / AC-5 |
| 3.2 | DOCS+NOTES | Audit + update every affected doc surface (README, KB, `docs/`, docs site, methodology via `canonical/` + re-render); truthfulness guard | FR-6 / AC-6 |
| 4 | PR ⏸ | Branch `release-<target>`, commit Steps 2–3 (never the manifest), push + open PR as `AndreVianna`; verify each PR check; **PAUSE — hand `gh pr merge` to the human**; restore `AndreVianna-Ross` | FR-7 / AC-7 |
| 5 | DRY-RUN | `checkout master && pull`; dispatch `release.yml -f ref=master -f dry_run=true` (no publish); verify each job green | FR-8 / AC-8 |
| 6 | TAG ⏸ | **PAUSE for explicit confirmation**; switch `gh` to `AndreVianna`; `git tag v<target> && git push origin v<target>` (triggers `release.yml`) | FR-9 / AC-9 |
| 7 | VERIFY | Inspect each release-workflow job's conclusion individually (watch exit 0 ≠ all-pass); channel matrix below; `NM08` flake → `gh run rerun --failed` | FR-10 / AC-10 |
| 8 | CONFIRM ⏸ | Confirm artifacts landed on each channel (PyPI `/simple/`, GitHub Release, npm for stable); **the publish confirmation is the third human-gated point** | FR-11 / AC-11 |
| 9 | close-out | Restore `gh` to `AndreVianna-Ross`; report version, channels, release URL, and that `release-tracking.md` + README were updated | FR-11 / AC-11 |

**The three ⏸ human-gated pauses (AC-12):** (1) the PR merge — the auto-mode classifier
blocks `gh pr merge`, so the command is handed to the human; (2) the tag push — a
published version can never be reused, so it is confirmed first; (3) confirming the
publish. Everything else (version math, carrier bumps, notes rewrite, doc sweep,
branch/PR, dry-run, verification) proceeds autonomously. Any precondition failure, red
check, or version-math ambiguity is surfaced, never worked around (NFR-2).

### Data Model — version math (Step 0)

`VERSION` (single line, `M.m.p` optionally `-beta.N`) is the source of truth; the target
is computed by bumping the named level and **zeroing every level below it**:

| level | current stable `M.m.p` | current beta `M.m.p-beta.N` |
|-------|------------------------|-----------------------------|
| `major` | `(M+1).0.0` (stable) | `(M+1).0.0` (stable) |
| `minor` | `M.(m+1).0` (stable) | `M.(m+1).0` (stable) |
| `patch` | `M.m.(p+1)` (stable) | **`M.m.p` (stable — PROMOTE: drop `-beta.N`)** |
| `beta`  | `M.m.(p+1)-beta.1` | `M.m.p-beta.(N+1)` |

Worked from `2.2.3-beta.1`: `beta`→`2.2.3-beta.2`, `patch`→`2.2.3`, `minor`→`2.3.0`,
`major`→`3.0.0`. From stable `2.2.3`: `patch`→`2.2.4`, `beta`→`2.2.4-beta.1`.
Rationale for patch-from-beta = promote: `X.Y.Z-beta.N` is the release candidate *for*
`X.Y.Z`, so finalizing that beta line ships `X.Y.Z` (never skips to `X.Y.Z+1`).

### Data Model — version carriers & the channel matrix (Steps 2, 7)

Four carriers must agree (the release `gate` runs `check-version-sync.sh`): `VERSION`,
`packages/npm/package.json`, `packages/pypi/pyproject.toml`, and the git tag `v<target>`.

| level | `VERSION` | `pyproject.toml` | `package.json` (npm) | tag | version format |
|-------|-----------|------------------|----------------------|-----|----------------|
| stable | `<target>` | `<target>` | `<target>` | `v<target>` | `X.Y.Z` |
| beta | `<target>` | `<target>` | **left at last stable (exempt)** | `v<target>` | SemVer `X.Y.Z-beta.N` (never PEP-440 `bN`) — NFR-5 |

Release-workflow jobs verified in Step 7 (each inspected individually):

| level | `gate` | `github-release` | `pypi-publish` | `npm-publish` |
|-------|--------|------------------|----------------|---------------|
| stable | pass | pass (release = latest) | pass | pass |
| beta | pass | pass (marked **prerelease**, carries skill tarballs) | pass | **skipped** |

Step 8 artifact confirmation: PyPI via `/simple/` (beta normalizes `-beta.N`→`bN`; the
`/pypi/<pkg>/json` `info.version` lags); GitHub Release via `gh release view` (beta =
`Pre-release: true` and NOT `/releases/latest`; stable = latest; assets = 5 profile
tarballs + `aid-cli-v<target>.tar.gz` + `aid-install-core.sh` + `AidInstallCore.psm1` +
`SHA256SUMS`); npm via `npm view aid-installer@<target> version` (stable only).

### Documentation sweep — surfaces touched (Step 3.2)

"What changed" is derived from this version's `release-tracking.md` items +
`git log <last-tag>..HEAD`; every affected surface below is audited and updated:

| Surface | Path | Notes |
|---------|------|-------|
| README | `README.md` | Version/highlights + any command/feature enumeration. Prefer a short "recent releases → changelog / Releases" pointer over a per-version "What's New in vX" block (OD-2). |
| Knowledge Base | `.aid/knowledge/` | `capability-inventory.md` + `module-map.md` (new/changed command or module), `infrastructure.md` (release/channel/version facts — e.g. which channels are enabled), `technology-stack.md`, and any other affected doc. |
| Repo docs | `docs/` | `install.md` (command surface), `release.md`, any versioned reference. |
| Docs site | `site/src/content/docs/` (+ `site/src/pages/releases/`) | `reference/cli.mdx`, guides, reference pages. **Leave the release changelog page** (`site/src/pages/releases/changelog.astro`, a sibling tree — not under `content/docs/`) — it is auto-sourced from GitHub Releases. |
| Methodology content | `canonical/` → `profiles/` | Edit the SOURCE in `canonical/` and re-render via the `generate-profile` skill; **never hand-edit `profiles/`**. The render-drift gate (Step 1 + the release gate) catches a missed re-render. |

**Truthfulness guard (NFR-4):** never add an unreleased/newer feature to a historical,
version-frozen section; a "What's New in vX" block describes only vX, cumulative history
lives in the changelog / GitHub Releases. Related skill boundary: `aid-document-changelog`
authors *adopter-project* changelogs; the AID-repo ledger rename (3.1) and this doc sweep
(3.2) are `release-aid`'s own responsibility.

### Gotchas (from SKILL.md — all enforced by the steps above)

- `gh` active account silently reverts to `AndreVianna-Ross`; switch to `AndreVianna`
  immediately before EACH push/PR/tag and restore after (NFR-3).
- Classifier BLOCKS `gh pr merge` in auto-mode — hand it to the human (FR-7).
- Beta = SemVer `X.Y.Z-beta.N`, not PEP 440 `bN`; npm carrier exempt for betas (NFR-5).
- `gh ... --watch` exit 0 ≠ all-pass — verify each job (FR-10).
- PyPI `/json` lags; use `/simple/`. `NM08` npm-pack is a flake; `gh run rerun --failed`.
- Never bump/commit `.aid/.aid-manifest.json` as part of a release (not a gate carrier).
- Always dry-run (`-f ref=master -f dry_run=true`) before the tag.

### Open points (recorded, not resolved — see REQUIREMENTS §8)

- **OD-1** — Whether `release-aid` auto-reconciles the pre-existing broken ledger
  backlog (`v2.1.0`–`v2.2.3-beta.1` sections + the stale `## Unreleased` items) on its
  first run, or whether that backlog is a separate one-time cleanup (task-003) with the
  skill only maintaining the ledger going forward. Human decision pending.
- **OD-2** — README shape: a self-maintaining "recent releases → changelog" pointer vs.
  a maintained per-release highlights block. SKILL.md prefers the pointer; human
  decision pending.
