# Maintainer Release Runbook

How to cut a release of AID. The primary path is the tag-triggered CI workflow
(`release.yml`). The manual path via `release.sh` is also supported as a fallback.

---

## Contents

- [How releases work](#how-releases-work)
- [Primary path — tag-triggered CI](#primary-path--tag-triggered-ci)
- [Pre-release (beta) channel — CLI + skills](#pre-release-beta-channel--cli--skills)
- [Manual path — release.sh](#manual-path--releasesh)
- [What a release produces](#what-a-release-produces)
- [Prerequisites](#prerequisites)
- [Step 1 — Verify preconditions](#step-1--verify-preconditions)
- [Step 2 — Dry run (optional)](#step-2--dry-run-optional)
- [Step 3 — Push the version tag](#step-3--push-the-version-tag)
- [Step 4 — Monitor the workflow](#step-4--monitor-the-workflow)
- [Recovery and idempotency](#recovery-and-idempotency)
- [Manual path details](#manual-path-details)
- [Flag reference (release.sh)](#flag-reference-releasesh)

---

## How releases work

A single pushed `v*` tag triggers `release.yml`, which:

1. **Gates** — re-runs the full correctness suite (render-drift + canonical helper
   suites + generator self-tests + FR10 version-sync) on the tagged commit.
2. **GitHub Release** — builds five per-profile tarballs, the `aid-cli` bundle, two
   install-core library files, and `SHA256SUMS`; creates the GitHub Release with all
   assets via `release.sh`.
3. **npm** — publishes `aid-installer` to npm with OIDC provenance (gated by the
   `NPM_ENABLED` repo variable).
4. **PyPI** — publishes `aid-installer` to PyPI via Trusted Publishing (OIDC; gated
   by the `PYPI_ENABLED` repo variable).

All four channels — GitHub tarballs, npm, PyPI, and the offline bundle — are produced
from the same tag in one workflow run.

---

## Primary path — tag-triggered CI

### Prerequisites

- **`VERSION` file is set to the intended release version.** `release.yml` reads
  `VERSION` and enforces that the tag, `VERSION`, `packages/npm/package.json`, and
  `packages/pypi/pyproject.toml` all agree (FR10 version-sync gate).
- **Clean, passing CI on master.** Push the tag only from a commit where `test.yml`
  is green.
- **Render-drift clean.** `profiles/` must be in sync with `canonical/`. The gate
  re-runs the check and fails the workflow if they diverge.
- **No existing tag `v<VERSION>`.** The gate fails early on a collision.

### Step 1 — Verify preconditions

```bash
git status                                     # must be clean
git tag -l "v$(cat VERSION)"                   # must print nothing
gh run list --workflow test.yml --limit 5      # confirm CI is green on master
python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/
```

### Step 2 — Dry run (optional)

Use the `workflow_dispatch` trigger with `dry_run: true` to build and validate without
publishing:

```bash
gh workflow run release.yml --ref master -f ref="v$(cat VERSION)" -f dry_run=true
gh run watch   # monitor progress
```

### Step 3 — Push the version tag

```bash
git tag "v$(cat VERSION)"
git push origin "v$(cat VERSION)"
```

This triggers the full `release.yml` run: gate → github-release → npm-publish +
pypi-publish (in parallel).

### Step 4 — Monitor the workflow

```bash
gh run watch
```

On success, the GitHub Release is live and the package registries are updated. On any
failure, see [Recovery](#recovery-and-idempotency).

---

## Pre-release (beta) channel — CLI + skills

To get a build in front of specific testers without touching the stable channels,
cut a **pre-release**. It ships to **two** channels:

- **CLI → PyPI.** Use the **SemVer** pre-release form (`2.2.3-beta.1`) for the version
  and tag — the CLI's tool-bundle naming requires a separator before the pre-release,
  so PEP 440 `2.2.3b1` (no separator) would be rejected by `aid add`/`update`. PyPI
  **normalizes** `2.2.3-beta.1` → `2.2.3b1` on publish, and `pip`/`pipx` hide
  pre-releases from a plain install/upgrade, so a tester opts in explicitly.
- **Skills → a GitHub Release marked `--prerelease`** (the `v2.2.3-beta.1` profile
  tarballs). GitHub excludes pre-releases from `/releases/latest`, so a normal
  `aid update` (which resolves latest) still gets the **stable** skills — untouched.

**npm is not involved** in betas (it ships no pre-releases).

### Versioning

Bump **only** the PyPI-side carriers to the SemVer pre-release — leave
`packages/npm/package.json` on the last stable (npm publishes no beta):

```bash
# beta of the upcoming 2.2.3
printf '2.2.3-beta.1\n' > VERSION
# packages/pypi/pyproject.toml: version = "2.2.3-beta.1"
# packages/npm/package.json:    LEAVE at the last stable (e.g. 2.2.2)
```

The version-sync gate detects the pre-release and **exempts the npm carrier** — it
enforces only `VERSION == pyproject.toml == tag`.

### Cut it

```bash
git commit -am "chore(release): 2.2.3-beta.1 (beta)"
git tag "v2.2.3-beta.1"
git push origin "v2.2.3-beta.1"        # triggers release.yml
```

On a pre-release tag `release.yml` runs: gate → **github-release** (Release marked
`--prerelease`, carries the skill tarballs) + **pypi-publish** (the CLI beta);
**npm-publish is skipped**. Confirm on the run that npm-publish shows *skipped*,
github-release created a **pre-release**, and pypi-publish is green.

### Testers use it

```bash
pipx install "aid-installer==2.2.3b1"     # the beta CLI (PyPI's normalized form of 2.2.3-beta.1)
```

Then, inside a project, a plain **`aid update`** — no flags — automatically installs
the **beta skills**: because the running CLI is itself a pre-release, version
resolution first looks for the newest **pre-release** skills Release and uses it,
**falling back to the latest stable** if none exists. (An explicit `aid update
--version 2.2.3-beta.1` also works.)

For everyone else, nothing changes: a **stable** CLI's `aid update` always resolves
`/releases/latest` (stable), and a plain `pipx install`/`upgrade aid-installer` never
picks up the beta.

> A pre-release does **not** bump `VERSION`/`pyproject.toml` toward the eventual
> stable in a way that blocks it: when ready, set the carriers to the stable `2.2.3`
> (all four in sync) and cut it normally — the stable release then supersedes the beta.

---

## What a release produces

### GitHub Release assets

`release.sh` (invoked by the CI workflow) stages artifacts under
`.aid/.temp/release-<VERSION>/` and uploads them to the GitHub Release:

- **Five per-profile tarballs:**
  - `aid-claude-code-v<VERSION>.tar.gz`
  - `aid-codex-v<VERSION>.tar.gz`
  - `aid-cursor-v<VERSION>.tar.gz`
  - `aid-copilot-cli-v<VERSION>.tar.gz`
  - `aid-antigravity-v<VERSION>.tar.gz`
- **`aid-cli-v<VERSION>.tar.gz`** — the `aid` CLI bundle (bootstrapped by
  `install.sh` / `install.ps1` and by `aid update self`).
- **Two install-core library files:**
  - `aid-install-core.sh` — Bash install-core library sourced by `install.sh`.
  - `AidInstallCore.psm1` — PowerShell install-core module imported by `install.ps1`.
- **`SHA256SUMS`** — one `<64-hex>  <filename>` line per asset, sorted by filename.

Each tarball contains exactly the install-relevant files for that tool (dot directory
tree + root agent file). The layout is flat/root-relative — `tar -xzf` into a temp
directory yields the files as they land in the target project, with no wrapping
directory to strip.

### npm

`aid-installer` published at the version from `packages/npm/package.json`. The package
vendors the `bin/` CLI payload and wires `aid` onto PATH at install time.

### PyPI

`aid-installer` published at the version from `packages/pypi/pyproject.toml`. The
package vendors the `bin/` CLI payload via a hatchling build hook.

---

## Manual path — release.sh

If you need to cut a release outside of CI (e.g. for a hotfix), use `release.sh`
directly. It produces the same GitHub Release assets as the CI path but does not
publish to npm or PyPI.

```bash
# Dry run (no gh release create, no network I/O)
bash release.sh --dry-run

# Create a draft release for review
bash release.sh --draft

# Publish immediately (no draft review)
bash release.sh
```

See [Manual path details](#manual-path-details) below for the full step-by-step.

---

## Prerequisites

Before running either path:

- **Clean git worktree.** `git status` must show no modified tracked files.
- **Render-drift clean.** Run `python .claude/skills/generate-profile/scripts/run_generator.py` and commit if it produces a diff.
- **`VERSION` file matches the intended release.** Update and commit `VERSION` before proceeding.
- **`gh` CLI authenticated.** `gh auth status` must show write access to the repo.
- **Tag does not already exist.** Both paths fail early on a collision.

```bash
# Quick precondition check
git status
git tag -l "v$(cat VERSION)"
gh auth status
python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/
```

---

## Step 1 — Verify preconditions

Run `--dry-run` to validate without creating a tag or release:

```bash
bash release.sh --dry-run
```

Expected output:

```
[release.sh] version: 1.1.0  tag: v1.1.0
[release.sh] checking worktree is clean...  ok
[release.sh] checking tag v1.1.0 does not exist...  ok
[release.sh] verifying render-drift gate...  ok
[release.sh] staging dir: .aid/.temp/release-1.1.0/
[release.sh] packaging aid-antigravity-v1.1.0.tar.gz...  ok
[release.sh] packaging aid-claude-code-v1.1.0.tar.gz...  ok
[release.sh] packaging aid-codex-v1.1.0.tar.gz...  ok
[release.sh] packaging aid-copilot-cli-v1.1.0.tar.gz...  ok
[release.sh] packaging aid-cursor-v1.1.0.tar.gz...  ok
[release.sh] packaging aid-cli-v1.1.0.tar.gz...  ok
[release.sh] writing SHA256SUMS...  ok
[release.sh] --dry-run: staging complete. Run without --dry-run to create the GitHub Release.
```

Common failures and fixes:

| Failure | Message | Fix |
|---------|---------|-----|
| Dirty worktree | `working tree has uncommitted changes` | `git stash` or commit the changes |
| Render drift | `profiles/ is out of sync with canonical/` | `python .claude/skills/generate-profile/scripts/run_generator.py && git add profiles/ && git commit -m "..."` |
| Version mismatch | `--version X does not match VERSION file (Y)` | Drop `--version` or update `./VERSION` |
| Tag already exists | `tag v1.1.0 already exists` | The release was already cut; see [Recovery](#recovery-and-idempotency) |

---

## Step 2 — Dry run (optional)

The `--dry-run` output above doubles as the validation step. Re-run it until it exits 0
before proceeding.

---

## Step 3 — Push the version tag

**CI path:**

```bash
git tag "v$(cat VERSION)"
git push origin "v$(cat VERSION)"
```

**Manual path:**

```bash
bash release.sh --draft           # recommended: create draft, review, then publish
# — or —
bash release.sh                   # publish immediately
```

---

## Step 4 — Monitor the workflow

CI path:

```bash
gh run watch
```

Manual path: the `gh release create` output from `release.sh` prints the draft URL.
Open it, verify the assets and release notes, then publish:

```bash
gh release edit "v$(cat VERSION)" --draft=false
```

---

## Recovery and idempotency

### Dry run is always safe to re-run

`--dry-run` never creates a tag, never calls `gh`, and overwrites the staging directory
on each run. Re-run as many times as needed.

### If the CI workflow fails mid-publish

The `npm-publish` and `pypi-publish` jobs are idempotent: they skip with a notice if
the version is already published. Re-triggering `workflow_dispatch` with the same tag
is safe.

If `github-release` fails mid-upload:

1. Delete the draft release: GitHub web UI → Releases → Edit → Delete.
2. Delete the local tag: `git tag -d v1.1.0`
3. Delete the remote tag: `git push origin :refs/tags/v1.1.0`
4. Fix the root cause and re-run from [Step 1](#step-1--verify-preconditions).

### If the tag already exists but no release exists

```bash
git tag -d v1.1.0
git push origin :refs/tags/v1.1.0
# Then re-run
git tag v1.1.0 && git push origin v1.1.0
```

### Staging directory cleanup

The staging directory at `.aid/.temp/release-<VERSION>/` is gitignored. Clean it up
when no longer needed:

```bash
rm -rf ".aid/.temp/release-$(cat VERSION)/"
```

---

## Manual path details

For reference when running `release.sh` outside CI.

### Step 3 — Inspect staged artifacts

After a successful dry run:

```bash
ls -lh ".aid/.temp/release-$(cat VERSION)/"
```

Verify the five profile tarballs, the `aid-cli` bundle, two lib files, and `SHA256SUMS`
are present. Spot-check a tarball:

```bash
tar -tzf ".aid/.temp/release-$(cat VERSION)/aid-claude-code-v$(cat VERSION).tar.gz" | head -20
cd ".aid/.temp/release-$(cat VERSION)/"
sha256sum --check SHA256SUMS        # Linux
shasum -a 256 -c SHA256SUMS         # macOS
```

Expected tarball contents for `claude-code`:
- `./CLAUDE.md`
- `./.claude/skills/...`
- `./.claude/agents/...`

No tarball should contain `README.md` or `emission-manifest.jsonl`.

### Step 4 — Create a draft release

```bash
bash release.sh --draft
```

This calls `gh release create "v<VERSION>" --title "AID v<VERSION>" --draft` with all
assets attached. Open the draft URL on the GitHub web UI, verify all assets and release
notes, then publish.

### Optional: supply release notes

```bash
bash release.sh --draft --notes-file /path/to/RELEASE-NOTES.md
```

Without `--notes-file` the script generates a stub. You can also edit the notes on the
GitHub draft release page before publishing.

---

## Flag reference (release.sh)

```bash
bash release.sh [--version X.Y.Z] [--sign] [--draft] [--dry-run]
                [--notes-file FILE] [-h|--help]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--version X.Y.Z` | content of `VERSION` file | Release version. Must match `VERSION` file; fails on mismatch (exit 3). |
| `--sign` | off | Emit a detached signature over `SHA256SUMS`. Currently exits non-zero — signing is deferred. Do not use. |
| `--draft` | off | Create the GitHub Release as a draft. Recommended: always draft first, review, then publish. |
| `--dry-run` | off | Assemble tarballs and `SHA256SUMS`, stop before `gh release create`. No network I/O; no tag created. |
| `--notes-file FILE` | generated stub | Release notes body passed to `gh release create`. |
| `-h`, `--help` | — | Print help and exit 0. |

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success (dry-run: staging complete; live: release created). |
| `1` | General failure (dirty worktree, render-drift, `gh` error). |
| `2` | Usage / argument error. |
| `3` | Version mismatch (`--version` does not match `VERSION` file). |
| `4` | Tag already exists (local git tag or GitHub Release). |
