# Maintainer Release Runbook

Step-by-step guide for cutting a GitHub Release using `release.sh`. This is the pre-feature-005 manual path — the CI release automation (tag-triggered workflow) comes in a later delivery.

---

## Contents

- [Prerequisites](#prerequisites)
- [What release.sh produces](#what-releasesh-produces)
- [Step 1 — Verify preconditions](#step-1--verify-preconditions)
- [Step 2 — Dry run](#step-2--dry-run)
- [Step 3 — Inspect staged artifacts](#step-3--inspect-staged-artifacts)
- [Step 4 — Create a draft release](#step-4--create-a-draft-release)
- [Step 5 — Review and publish the draft](#step-5--review-and-publish-the-draft)
- [Recovery and idempotency](#recovery-and-idempotency)
- [Flag reference](#flag-reference)

---

## Prerequisites

Before running `release.sh`:

- **Clean git worktree.** `git status` must show no modified tracked files. Untracked files are ignored. The script fails at step 1 if tracked files are dirty.
- **Render-drift clean.** `profiles/` must be up to date with `canonical/`. Run `python .claude/skills/aid-generate/scripts/run_generator.py` and commit the result if it produces any diff. The script re-runs the generator and fails if it detects drift.
- **`VERSION` file matches your intended release.** The script reads `./VERSION` for the version string. If you want to release at a different version, update `VERSION` and commit it first.
- **`gh` CLI authenticated.** `gh auth status` must show an authenticated account with write access to the repo. The script calls `gh release create` at the final step.
- **Tag does not already exist.** The script pre-checks that neither a local git tag `v<VERSION>` nor a GitHub Release with that tag exists. It fails early on a collision.

```bash
# Quick precondition check
git status
git tag -l "v$(cat VERSION)"          # must print nothing
gh auth status
python .claude/skills/aid-generate/scripts/run_generator.py && git diff --exit-code -- profiles/
```

---

## What release.sh produces

A single run produces the following artifacts under `.aid/.temp/release-<VERSION>/` (gitignored; stays untracked):

- **Five per-profile tarballs**, one per canonical tool id:
  - `aid-claude-code-v<VERSION>.tar.gz`
  - `aid-codex-v<VERSION>.tar.gz`
  - `aid-cursor-v<VERSION>.tar.gz`
  - `aid-copilot-cli-v<VERSION>.tar.gz`
  - `aid-antigravity-v<VERSION>.tar.gz`
- **`SHA256SUMS`** — one `<64-hex>  <filename>` line per tarball, sorted by filename.

These six files become the GitHub Release assets. Each tarball contains exactly the install-relevant files for that tool (the tool's dot directory tree and its root agent file — no `README.md`, no internal build manifests). The tarball layout is flat/root-relative — `tar -xzf` into a temp directory yields the files as they land in the target repo, with no wrapping directory to strip.

---

## Step 1 — Verify preconditions

```bash
bash release.sh --dry-run
```

`--dry-run` runs every step up to (but not including) `gh release create`. If preconditions are not met, it exits non-zero and prints a remediation message. Fix any reported issues and re-run `--dry-run` until it completes cleanly.

Common failures and their fixes:

| Failure | Message | Fix |
|---------|---------|-----|
| Dirty worktree | `working tree has uncommitted changes` | `git stash` or commit the changes |
| Render drift | `profiles/ is out of sync with canonical/` | `python .claude/skills/aid-generate/scripts/run_generator.py && git add profiles/ && git commit -m "..."` |
| Version mismatch | `--version X does not match VERSION file (Y)` | Either drop `--version` or update `./VERSION` |
| Tag already exists | `tag v0.7.0 already exists` | The release was already cut; see [Recovery](#recovery-and-idempotency) |

---

## Step 2 — Dry run

```bash
bash release.sh --dry-run
```

Expected output (all lines on stdout):

```
[release.sh] version: 0.7.0  tag: v0.7.0
[release.sh] checking worktree is clean...  ok
[release.sh] checking tag v0.7.0 does not exist...  ok
[release.sh] verifying render-drift gate...  ok
[release.sh] staging dir: .aid/.temp/release-0.7.0/
[release.sh] packaging aid-antigravity-v0.7.0.tar.gz...  ok
[release.sh] packaging aid-claude-code-v0.7.0.tar.gz...  ok
[release.sh] packaging aid-codex-v0.7.0.tar.gz...  ok
[release.sh] packaging aid-copilot-cli-v0.7.0.tar.gz...  ok
[release.sh] packaging aid-cursor-v0.7.0.tar.gz...  ok
[release.sh] writing SHA256SUMS...  ok
[release.sh] --dry-run: staging complete. Run without --dry-run to create the GitHub Release.
```

If the dry run exits 0, the artifacts are correct and you are ready to proceed.

---

## Step 3 — Inspect staged artifacts

After a successful dry run, inspect the staged artifacts before publishing:

```bash
ls -lh .aid/.temp/release-0.7.0/
```

Verify the five tarballs and `SHA256SUMS` are present. Spot-check a tarball's contents:

```bash
# Confirm the tarball is flat (no wrapping directory) and contains expected paths
tar -tzf .aid/.temp/release-0.7.0/aid-claude-code-v0.7.0.tar.gz | head -20

# Confirm SHA256SUMS passes self-check
cd .aid/.temp/release-0.7.0/
sha256sum --check SHA256SUMS        # Linux
shasum -a 256 -c SHA256SUMS         # macOS
```

Expected tarball contents for `claude-code`:
- `./CLAUDE.md`
- `./.claude/skills/...`
- `./.claude/agents/...`

Expected tarball contents for `codex`:
- `./AGENTS.md`
- `./.codex/...`
- `./.agents/...`

No tarball should contain `README.md` or `emission-manifest.jsonl`.

---

## Step 4 — Create a draft release

Create the GitHub Release as a draft so you can review it on the web before publishing:

```bash
bash release.sh --draft
```

This runs all the same steps as the dry run, then calls:

```bash
gh release create "v0.7.0" --title "AID v0.7.0" --draft \
  aid-antigravity-v0.7.0.tar.gz \
  aid-claude-code-v0.7.0.tar.gz \
  aid-codex-v0.7.0.tar.gz \
  aid-copilot-cli-v0.7.0.tar.gz \
  aid-cursor-v0.7.0.tar.gz \
  SHA256SUMS
```

`gh release create` also pushes the `v<VERSION>` git tag if it does not already exist.

### Optional: supply release notes

```bash
bash release.sh --draft --notes-file /path/to/RELEASE-NOTES.md
```

Without `--notes-file` the script generates a stub. You can also edit the notes on the GitHub draft release page before publishing.

---

## Step 5 — Review and publish the draft

Open the draft release on the GitHub web UI (the `gh release create` output prints the URL). Verify:

- Title: `AID v0.7.0`
- All six assets are attached (five tarballs + `SHA256SUMS`)
- Release notes are correct
- Tag: `v0.7.0` pointing at the expected commit

When satisfied, click **Publish release** on the GitHub UI. Alternatively, publish from the CLI:

```bash
gh release edit v0.7.0 --draft=false
```

Once published, the release is live and the installers can resolve and download it.

### Publishing directly (skip draft)

If you do not need a draft review step:

```bash
bash release.sh
```

This runs all steps and publishes immediately (no `--draft`).

---

## Recovery and idempotency

### Dry run is always safe to re-run

`--dry-run` never creates a tag, never calls `gh`, and overwrites the staging directory on each run. Re-run it as many times as needed.

### If gh release create fails mid-upload

`release.sh` aborts on any failure. A partial upload leaves an incomplete draft release on GitHub. Recovery:

1. Delete the draft release from the GitHub web UI (Releases → Edit → Delete).
2. Delete the local tag: `git tag -d v0.7.0`
3. Delete the remote tag if it was pushed: `git push origin :refs/tags/v0.7.0`
4. Re-run `bash release.sh --dry-run` to confirm the staging dir is still valid (or re-run the full release).

### If the tag already exists but no release exists

```bash
# Delete the local and remote tag
git tag -d v0.7.0
git push origin :refs/tags/v0.7.0

# Then re-run
bash release.sh --draft
```

### Re-running on the same version

The script fails with exit 4 if the tag already exists. This is a safety guard — it prevents accidentally overwriting a published release. If you need to re-package a released version (e.g. to fix a packaging bug), you must delete the release and tag first (see above), then release again. Adopters who installed the previous cut are unaffected.

### Staging directory cleanup

The staging directory at `.aid/.temp/release-<VERSION>/` is gitignored. It persists after the release for your reference. Clean it up manually when no longer needed:

```bash
rm -rf .aid/.temp/release-0.7.0/
```

---

## Flag reference

```bash
bash release.sh [--version X.Y.Z] [--sign] [--draft] [--dry-run]
                [--notes-file FILE] [-h|--help]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--version X.Y.Z` | content of `VERSION` file | Release version. Must match `VERSION` file; fails on mismatch (exit 3). |
| `--sign` | off | Emit a detached signature over `SHA256SUMS`. Currently exits non-zero — the signing approach is deferred to feature-005. Do not use on the manual path. |
| `--draft` | off | Create the GitHub Release as a draft. Recommended workflow: always draft first, review, then publish. |
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
