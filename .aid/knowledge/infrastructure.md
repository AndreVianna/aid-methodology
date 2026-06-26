---
kb-category: primary
source: hand-authored
objective: How AID moves from source to running/published software — source control, CI/CD, the multi-profile render, the three distribution channels, versioning/version-sync, the bootstrap installers, and the dashboard runtime.
summary: Read this for release/deploy/runtime context before any infrastructure-touching work — it maps the canonical→profiles render, release.sh and the GitHub/npm/PyPI channels, the four version carriers, the install bootstrap, and the local dashboard server.
sources:
  - release.sh
  - .github/workflows/release.yml
  - .github/workflows/docs.yml
  - .github/workflows/test.yml
  - .github/workflows/installer-tests.yml
  - install.sh
  - install.ps1
  - .claude/aid/scripts/release/check-version-sync.sh
  - .claude/skills/generate-profile/SKILL.md
  - bin/aid
tags: [C8, infrastructure, ci-cd, release, distribution, versioning, dashboard]
see_also: [technology-stack.md, integration-map.md, tech-debt.md, test-landscape.md]
owner: devops
audience: [developer, devops, architect]
intent: |
  How AID ships and runs: source control, CI/CD, the multi-profile render, the
  release pipeline (release.sh + 3 channels), install bootstrap + manifests,
  versioning/version-sync, and the dashboard server runtime.
contracts:
  - "The release tag v<VERSION> is the single trigger that gates + publishes all channels"
  - "All four version carriers (VERSION, package.json, pyproject.toml, tag) must agree or the release gate fails"
  - "github-release runs before npm/PyPI so the authoritative artifact channel exists first"
changelog:
  - 2026-06-25: Initial discovery (aid-discover quality deep-dive)
---

# Infrastructure

AID is a **methodology delivered as a multi-profile CLI installer** — not a hosted
application. So "infrastructure" here means *how the toolkit is built, versioned, packaged,
published, installed, and (optionally) served locally* — not cloud compute. There is **no
cloud hosting, no containers, no production database, and no always-on server** for AID
itself; the only long-running process is the optional local dashboard a user starts on their
own machine.

## Contents

- [Source Control](#source-control)
- [The Build: Multi-Profile Render](#the-build-multi-profile-render)
- [CI/CD Pipeline](#cicd-pipeline)
- [Versioning and Version-Sync](#versioning-and-version-sync)
- [The Release Pipeline](#the-release-pipeline)
- [Distribution Channels](#distribution-channels)
- [Install Bootstrap and Manifests](#install-bootstrap-and-manifests)
- [The Documentation Site](#the-documentation-site)
- [Runtime: The Dashboard Server](#runtime-the-dashboard-server)
- [Project Management Tooling](#project-management-tooling)
- [Hosting / Containers / Data — None](#hosting--containers--data--none)
- [Release Commands](#release-commands)
- [Change Log](#change-log)

---

## Source Control

| Property | Value |
|---|---|
| VCS | Git |
| Hosting | GitHub (`AndreVianna/aid-methodology`, repo slug per `release.yml` Trusted-Publisher config) |
| Default branch | `master` (branch-protected: PR + passing checks required) |
| Bot identity | The agent pushes as a **non-admin** bot and CANNOT push to `master` — always via PR |
| Delivery branch naming | `aid/work-NNN-delivery-NNN` (work-scoped, to avoid cross-work collisions) |
| Line endings | Enforced LF for `*.sh` (CI `kb-hygiene` rejects committed CRLF; see `.gitattributes`) |
| `core.fileMode` | Maintained `false`; CI sets it false so exec-bit diffs are not spurious drift |

CONFIRMED via the workflow files + `.gitattributes` + the `kb-hygiene` CRLF check in
`.github/workflows/test.yml`.

---

## The Build: Multi-Profile Render

AID's "build" is a render, not a compile. The single source of truth is `canonical/`; a
Python generator renders it into five per-tool install trees under `profiles/`.

- **Generator:** `python .claude/skills/generate-profile/scripts/run_generator.py` (the
  `generate-profile` skill; maintainer-only, the lone skill outside `canonical/`).
- **Profiles produced:** `claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`
  (derived from `ls profiles/*.toml`).
- **Safety boundary:** the generator only writes/deletes files it previously emitted, recorded
  per profile in `profiles/{tool}/emission-manifest.jsonl`; user-created files inside install
  trees are never touched.
- **Drift gate:** CI (`test.yml` `render-drift`) and the release `gate` re-run the generator
  and `git diff --exit-code -- profiles/`; any uncommitted drift fails the build. So
  `profiles/` is treated as committed build output that must always equal a fresh render.

CONFIRMED in `.claude/skills/generate-profile/SKILL.md` + `.github/workflows/test.yml`.

---

## CI/CD Pipeline

Four GitHub Actions workflows. See `test-landscape.md` for the test detail; the
release/deploy view:

| Workflow | Trigger | Role |
|---|---|---|
| `.github/workflows/test.yml` | push/PR to `master` | Correctness gate: render-drift, full canonical suite, visual-fidelity, generator self-tests, KB/repo hygiene |
| `.github/workflows/installer-tests.yml` | push to any non-`master` branch | Cross-platform installer/CLI/release validation (ubuntu bash-harness + windows native-ps1) so feature branches are validated remotely |
| `.github/workflows/release.yml` | push of a `v*` tag (or `workflow_dispatch`) | Gate → build → publish all channels |
| `.github/workflows/docs.yml` | push to `master` (site/docs/VERSION paths) + `release: published` | Build the Astro site and deploy to GitHub Pages |

CONFIRMED by each workflow's `on:` block.

---

## Versioning and Version-Sync

- **Scheme:** semantic versioning. Current `VERSION` = `1.1.1` (CONFIRMED via `cat VERSION`).
- **Source of truth:** the single-line `VERSION` file at the repo root.
- **Carriers (must all agree):** (1) `VERSION`, (2) `packages/npm/package.json` `version`,
  (3) `packages/pypi/pyproject.toml` `[project].version`, (4) the git tag `v<VERSION>`.
- **Gate:** `bash canonical/aid/scripts/release/check-version-sync.sh --expect <ver>` asserts
  all present carriers equal the expected version; the release `gate` job runs it before any
  packaging. A manifest that is present is always checked; an absent manifest is skipped only
  when its channel is not enabled. CONFIRMED in `check-version-sync.sh`.
- **Release history:** lives in `.aid/knowledge/release-tracking.md` (`[NEW]`/`[CHANGE]`/`[FIX]`,
  newest-first); the root `RELEASE_NOTES.md` is retired.

**Gotcha:** bump all four carriers together, or the release gate fails. See `tech-debt.md`.

---

## The Release Pipeline

Primary path: a maintainer pushes a `v<VERSION>` tag → one tag drives all channels.
CONFIRMED in `.github/workflows/release.yml`.

Job order and dependencies:
1. **`gate`** — checks out the tagged commit; derives the bare semver from the tag; runs
   version-sync, render-drift, the full canonical suite, and the generator self-tests on that
   exact commit. (KB-hygiene checks are deliberately not re-run here — they are repo hygiene,
   not release correctness.) Emits the version as a job output.
2. **`github-release`** (`needs: gate`) — runs `release.sh` to build artifacts and create the
   GitHub Release. Runs first so the authoritative artifact channel exists before the package
   registries are hit.
3. **`npm-publish`** + **`pypi-publish`** (`needs: gate, github-release`) — publish to npm and
   PyPI in parallel; each is gated by `NPM_ENABLED` / `PYPI_ENABLED` repo variables and is
   idempotent on re-run (npm `npm view` pre-check; PyPI `skip-existing`).

`release.sh` itself (the maintainer runbook script): asserts a clean worktree, re-verifies
render state (render-drift), stages `.aid/.temp/release-<VERSION>/`, packages **five
per-profile tarballs + one CLI bundle (`aid-cli-v<VERSION>.tar.gz`) + the two installer libs +
`SHA256SUMS`**, then `gh release create` (or `gh release upload --clobber` for idempotent
recovery re-runs). `--dry-run` stages artifacts and stops before any network I/O; `--sign` is
deferred (exits non-zero). Exit codes: 0 ok, 1 general, 2 usage, 3 version mismatch, 4 tag
conflict. CONFIRMED in `release.sh`.

---

## Distribution Channels

Three channels, all from the same tag:

| Channel | Artifact(s) | How built | Auth |
|---|---|---|---|
| GitHub Releases | 5 profile tarballs + `aid-cli-v*.tar.gz` + `aid-install-core.sh` + `AidInstallCore.psm1` + `SHA256SUMS` | `release.sh` via `gh release create` | built-in `GITHUB_TOKEN` (`contents: write`) |
| npm (`aid-installer`) | npm package vendoring the aid-cli payload | `packages/npm/scripts/vendor.js` runs at `prepack`; `npm publish --provenance` | OIDC Trusted Publishing (token-less; optional classic `NPM_TOKEN` fallback) |
| PyPI (`aid-installer`) | sdist + wheel vendoring the aid-cli payload | hatchling build hook `packages/pypi/scripts/vendor.py`; `python -m build` | OIDC Trusted Publishing via `pypa/gh-action-pypi-publish` (PEP 740 attestations) |

The npm and PyPI channels are correct but currently **blocked on external account setup**
(scope/org not yet provisioned; `NPM_ENABLED` / `PYPI_ENABLED` = false) — see `tech-debt.md`
M1. Until enabled, releases publish to GitHub Releases only. CONFIRMED in `release.yml`
header.

---

## Install Bootstrap and Manifests

End users install via one of:

- **Bash bootstrap:** `bash install.sh` (or `curl … | bash`) — installs the global `aid` CLI
  into `$AID_HOME` (default `~/.aid`) and wires PATH; `bash install.sh add <tool>` bootstraps
  then runs `aid add` in the current repo.
- **PowerShell bootstrap:** `install.ps1` (`irm … | iex`) — installs into `%LOCALAPPDATA%\aid\`.
- **Package managers:** `npm i -g aid-installer` / `pipx install aid-installer` put `aid` on
  PATH once the channels are enabled.

The bootstrap fetches the CLI bundle + libs from the **pinned release tag** and verifies them
against `SHA256SUMS` before sourcing — the GitHub Release is the trust root (see `tech-debt.md`
Security Observations).

**The five install manifests (lockstep invariant):** the dashboard server+reader file set is
vendored independently by `install.sh`, `install.ps1`, `packages/npm/scripts/vendor.js`,
`packages/pypi/scripts/vendor.py`, and `release.sh` (the CLI bundle). All five must stay
byte-lockstep on that file set or one channel silently provisions the wrong files. CONFIRMED
in `release.sh` (the `home.html` lockstep comment names the other four). See `tech-debt.md` H1.

---

## The Documentation Site

A standalone Astro Starlight site under `site/` (separate build, own `package.json` /
`node_modules` / `dist/`), deployed to **GitHub Pages at https://aid.casuloailabs.com**.
`docs.yml` runs `npm ci && npm run build` (with a build-time fetch of `VERSION` + the GitHub
Releases API for version injection) and deploys via `actions/deploy-pages`. It is decoupled
from `release.yml` — it merely *listens* for `release: published` to refresh release-bound
content. CONFIRMED in `.github/workflows/docs.yml`.

---

## Runtime: The Dashboard Server

The one component AID *runs* is a local, read-only web dashboard over `.aid/` pipeline state.

| Property | Value |
|---|---|
| Command | `aid dashboard start <node\|python> [--remote] [--port <n>]` / `aid dashboard stop` |
| Implementations | Node (`dashboard/server/server.mjs`) and Python (`dashboard/server/server.py`) |
| Scope | Machine-level: serves all registered projects; CLI home page at `/` |
| Bind | `127.0.0.1` only; `--remote` is a clear-fail stub (exit 10) — cannot accidentally expose state |
| State home | `$AID_HOME` (env-overridable; default `~/.aid`); pid/log under `$AID_HOME/.temp/dashboard.pid` |
| Lifecycle | `start` exits 8 if already running; `stop` is idempotent (exit 0) |

CONFIRMED in `bin/aid` (dashboard help block) + `installer-tests.yml` dashboard smoke test
(exit-code contract).

The dashboard reader (`dashboard/reader/*.py`) parses `.aid/work-NNN/STATE.md`
(Pipeline Status + Tasks Status) plus the KB — `STATE.md` is the tracking spine the reader and
`/aid-execute` both consume.

---

## Project Management Tooling

**No external project-management tool** (Jira/Azure Boards/etc.). All work, tasks, and
deliverables are tracked **in-repo** in `.aid/work-NNN-*/STATE.md` files (the tracking spine),
plus `.aid/knowledge/STATE.md` for cross-phase process state. GitHub Issue templates exist
(`.github/ISSUE_TEMPLATE/feedback.yml`) for user feedback, and `.github/dependabot.yml` tracks
dependency updates. CONFIRMED via `.aid/settings.yml` + the `.github/` listing.

---

## Hosting / Containers / Data — None

Explicit "none" for stages that do not exist (per the C8 floor — do not assume a stage is
present):

| Stage | Present? |
|---|---|
| Cloud provider / compute hosting | **None** — AID is installed into the user's repo; nothing is hosted |
| Containers (Docker/K8s) | **None** in the product (a Docker channel×path E2E grid was built then retired as over-built) |
| Production database | **None** — state is plain files under `.aid/` |
| Always-on server | **None** — only the optional, local, localhost-bound dashboard |
| Infrastructure-as-Code | **None** |
| Monitoring / APM / alerting | **None** (no runtime to monitor) |

CONFIRMED — no Dockerfile/Terraform/Helm/cloud config exists in the tracked tree; the sole
"deployment" is GitHub Pages for the docs site.

---

## Release Commands

```bash
# Verify version-sync across all carriers (release-gate parity)
bash canonical/aid/scripts/release/check-version-sync.sh --expect "$(tr -d '[:space:]' < VERSION)"

# Re-render from canonical and assert no profile drift (build parity)
python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/

# Stage release artifacts WITHOUT publishing (no network I/O)
bash release.sh --version "$(tr -d '[:space:]' < VERSION)" --dry-run

# Cut the GitHub Release (maintainer; needs gh + clean worktree)
bash release.sh --version "$(tr -d '[:space:]' < VERSION)"

# The end-to-end channel path is normally driven by pushing the tag:
#   git tag v$(tr -d '[:space:]' < VERSION) && git push origin v$(...)   # triggers release.yml

# Start / stop the local dashboard
aid dashboard start node --port 8799
aid dashboard stop
```

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial infrastructure mapping (quality deep-dive) |
