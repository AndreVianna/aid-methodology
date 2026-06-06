# Release Packaging & Checksums

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Feature identified from REQUIREMENTS.md §5 (FR1 artifact side, FR5), §6, §9 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR1 release/artifact side, FR5 bundle source), §6 (supply-chain), §9

## Description

Defines the **release artifact contract** every install channel consumes. A maintainer helper
(`release.sh`) assembles the five per-profile tarballs from a clean rendered state (reusing the
existing render-drift check — it does **not** modify the canonical→profiles render pipeline),
emits a `SHA256SUMS` file (and optional signature), and cuts the first GitHub Release manually via
`gh release create`. This is the verify-before-install surface for the offline / enterprise path
and the single source of artifacts for the curl, offline-tar, npm, and PyPI experiences.

## User Stories

- As a security-conscious adopter, I want a published `SHA256SUMS` (and optional signature) so that I can verify a downloaded tarball before installing it.
- As the maintainer, I want a one-command `release.sh` that packages the per-profile tarballs and creates a GitHub Release so that I can cut a release before the CI automation (feature-005) exists.
- As any install channel, I want one canonical per-profile tarball per release so that all four install experiences produce equivalent results.

## Priority

Must (P0 — foundation; the artifact all channels depend on)

## Acceptance Criteria

- [ ] Given a clean rendered state, when `release.sh` runs, then it produces five per-profile tarballs (`aid-<tool>-v<VERSION>.tar.gz`) and a `SHA256SUMS` file.
- [ ] Given a published release, when an adopter downloads a tarball, then they can verify it against the published `SHA256SUMS` (and optional signature) before install.
- [ ] Given the same release, when any of the four channels installs, then the installed result is equivalent (same files) across channels.
- [ ] Packaging is cut from a render-drift-clean state and does not modify the canonical→profiles render pipeline.

## Dependencies

- None (consumes existing generator output). feature-001 depends on this; features 003/004/005 consume it.

---

## Technical Specification

> **Authored by:** /aid-specify (Architect). Grounded against live repo state on 2026-06-04:
> `VERSION`=`0.7.0`; five profile trees confirmed under `profiles/` (`claude-code`, `codex`,
> `cursor`, `copilot-cli`, `antigravity`); render-drift job confirmed in `.github/workflows/test.yml`
> (`render-drift` job: `python run_generator.py` then `git diff --exit-code -- profiles/`).

### S0. Scope of this feature (the release artifact contract)

This feature defines the **release artifact contract** — the bytes that land on a GitHub Release —
and the maintainer helper (`release.sh`) that produces them. It is the single source of artifacts
for all four install channels and the thing CI later automates. It does **not** define the installer
(feature-001) or the CI workflow (feature-005); those are referenced as the consumer and the
automator at S7 (boundary statements).

What this feature owns:

1. `release.sh` — a maintainer-only helper at repo root that cuts a release from a render-drift-clean state.
2. The **tarball naming + internal layout** contract (S2).
3. The **`SHA256SUMS`** format and optional-signature approach (S3).
4. The **tag / version** contract for the artifact side of version-sync (S4).

What this feature explicitly does NOT own: the canonical→profiles render pipeline (consumed read-only,
never modified); the installer extract/copy/protect-on-diff logic (feature-001); full FR10 version
reconciliation across `package.json`/`pyproject.toml` (feature-005); npm/PyPI publishing (features 003/004/005).

### S1. `release.sh` — maintainer helper

A new Bash script at repo root, maintainer-only (never run on an adopter machine). Follows
`coding-standards.md §3b–3d`: `#!/usr/bin/env bash`, fixed header block, `set -euo pipefail`,
`-h|--help` via `sed -n` of the header, `while [[ $# -gt 0 ]] / case` argument parsing,
POSIX-portable (no GNU-only flags; runs on Linux/macOS/Git Bash).

**Invocation:**

```bash
bash release.sh [--version X.Y.Z] [--sign] [--draft] [--dry-run] [--notes-file FILE]
```

- `--version` — release version, default = the `VERSION` file content (currently `0.7.0`). Used
  verbatim for tarball names and to derive the tag `v<VERSION>`. If `--version` is passed it must
  match the `VERSION` file, else FAIL (the `VERSION` file is the single in-repo source of truth;
  feature-005 owns reconciling it with the git tag and the package manifests).
- `--sign` — also emit a detached signature over `SHA256SUMS` (optional; S3).
- `--draft` — create the GitHub Release as a draft (default: published).
- `--dry-run` — assemble tarballs + `SHA256SUMS` into the staging dir and stop before `gh release create`.
- `--notes-file FILE` — release notes body for `gh release create` (default: a generated stub).

**Steps (in order; any failure aborts the whole release — no partial publish):**

1. **Preconditions.** Assert run from repo root; assert clean git worktree (`git diff --quiet`
   on tracked files); resolve `VERSION` and `TAG="v${VERSION}"`. Assert the tag does not already exist (`git rev-parse -q --verify "refs/tags/${TAG}"` must fail) and that no GitHub Release with that tag exists.
2. **Verify clean rendered state (reuse, do not reimplement, the render-drift check).** Run
   `python run_generator.py`, then `git diff --exit-code -- profiles/`. If either fails, **FAIL**
   with the same remediation message CI uses ("profiles/ is out of sync with canonical/. Run
   `python run_generator.py` and commit the result."). `release.sh` **never modifies the render
   pipeline and never commits a render**; it only invokes the generator to prove the committed
   `profiles/` matches `canonical/`. This is the exact invariant the CI `render-drift` job protects,
   reused here so manual and automated releases share one gate.
3. **Stage.** Create a clean staging dir under `.aid/.temp/release-<VERSION>/` (gitignored per
   `infrastructure.md`; the kb-hygiene CI job asserts `.aid/.temp/` stays untracked, so staging
   here cannot leak into git).
4. **Package five per-profile tarballs** (S2). For each `(tool, profile_dir)` in the fixed map,
   `tar -czf` the install-relevant subset of `profiles/<profile_dir>/` into
   `aid-<tool>-v<VERSION>.tar.gz` with deterministic options (S2.3).
5. **Emit `SHA256SUMS`** (S3) over the five tarballs, one line per asset.
6. **(Optional) Sign** (S3) — if `--sign`, emit `SHA256SUMS.sig` (or `.minisig`/cosign bundle;
   approach flagged optional, settled in feature-005 / a follow-up `/aid-specify` if adopted).
7. **Create the GitHub Release.** `gh release create "${TAG}" --title "AID v${VERSION}"
   --notes-file "<notes>" [--draft] <staging>/aid-*.tar.gz <staging>/SHA256SUMS [SHA256SUMS.sig]`.
   `gh` is the maintainer's confirmed release tool (`infrastructure.md` Project Management).
   `gh release create` also creates and pushes the `${TAG}` git tag if absent.

`--dry-run` stops after step 6. Steps 4–6 are idempotent against the staging dir (re-runnable);
step 7 is the only network/irreversible action.

### S2. Tarball contract (CONSUMED BY feature-001, AUTOMATED BY feature-005)

#### S2.1 Naming convention (SETTLED HERE)

```
aid-<tool>-v<VERSION>.tar.gz
```

- `<tool>` is the **canonical tool id**, identical to the profile directory name (S2.2). This was
  the open cross-ref question routed to this feature — it is settled as: tool id == profile dir
  name == the `--tool` value feature-001 accepts (no separate alias table to keep in sync).
- `<VERSION>` is the bare semver from the `VERSION` file (e.g. `0.7.0`), no `v` prefix inside the
  version token; the literal `v` precedes it (matching the research sketch and the tag `v<VERSION>`).
- Examples at 0.7.0: `aid-claude-code-v0.7.0.tar.gz`, `aid-codex-v0.7.0.tar.gz`,
  `aid-cursor-v0.7.0.tar.gz`, `aid-copilot-cli-v0.7.0.tar.gz`, `aid-antigravity-v0.7.0.tar.gz`.

#### S2.2 Tool → profile-dir map (FIXED, FIVE ENTRIES)

| Tool id (`<tool>`, == `--tool`) | Profile dir | Install roots inside tarball |
|---|---|---|
| `claude-code`  | `profiles/claude-code`  | `.claude/` + `CLAUDE.md` |
| `codex`        | `profiles/codex`        | `.agents/` + `.codex/` + `AGENTS.md` |
| `cursor`       | `profiles/cursor`       | `.cursor/` + `AGENTS.md` |
| `copilot-cli`  | `profiles/copilot-cli`  | `.github/` + `AGENTS.md` |
| `antigravity`  | `profiles/antigravity`  | `.agent/` + `AGENTS.md` |

`release.sh` iterates this map as a literal ordered list of `tool` ids (each id is also the dir
name), so adding a sixth tool is a one-line edit here and a new `profiles/<id>` dir — no rename.

#### S2.3 Internal layout (extraction-root-relative)

A tarball is **flat at the install root**: extracting it yields exactly what the installer copies
into the target repo, with no wrapping directory. For `aid-codex-v0.7.0.tar.gz`:

```
./AGENTS.md
./.agents/...
./.codex/...
```

Rules:

- **Include** every install root for that tool (the dir(s) + the root agent file from S2.2).
- **Exclude `README.md`.** `profiles/{claude-code,codex,cursor}/README.md` exist but are
  repo-presentation only and are NOT installed (REQUIREMENTS §4 Out of Scope; the legacy `setup.sh`
  never copied them). `copilot-cli` and `antigravity` have no README (confirmed). The tarball must
  not contain `README.md` for any tool, so all five tarballs install an equivalent, README-free tree.
- **No wrapping dir / no leading `aid-<tool>/`** — extraction is install-root-relative so feature-001
  can `tar -xzf` into a temp dir and copy the entries directly, with no `--strip-components` guesswork.
  (PowerShell `Expand-Archive` in feature-001's `install.ps1` likewise yields a flat root.)

#### S2.4 Build-time emission manifest is NOT shipped

Each `profiles/<dir>/` carries a committed build-time `emission-manifest.jsonl` (records of the form
`{"dst": "...", "profile": "...", "sha256": "...", "src": "..."}`, preceded by a
`{"_manifest_version": 1}` header). **It is deliberately excluded from the tarball.** Its `dst` set
covers only the dot-dir install trees — it does **not** carry a record for the root agent file
(`AGENTS.md` / `CLAUDE.md`), which is the exact file feature-001's protect-on-diff (FR11) guards
(verified on disk: `grep -c '"dst": "AGENTS.md"' profiles/codex/emission-manifest.jsonl` → 0). Shipping
it would advertise an FR11/FR4 checksum surface it does not actually provide. feature-001's spec already
states the bootstrap ignores any emission manifest and computes its own per-file checksums (including the
root agent file) at install time from the extracted bytes, so the manifest is unused by the consumer.
Excluding it keeps the tarball to install-relevant bytes only and avoids a misleading, unconsumed
contract. (The build-time manifest remains in `profiles/` for render tooling; it is simply not a
release-artifact surface.)

### S3. Checksums and optional signing

#### S3.1 `SHA256SUMS` (REQUIRED; CONSUMED BY feature-001 offline path)

One `SHA256SUMS` file per release, listing **only the five tarball assets** (not `SHA256SUMS` itself,
not the signature). Standard `sha256sum`-compatible format — `<64-hex>  <filename>` (two spaces,
"binary" mode), filenames bare (no path prefix, since all assets sit at the Release root):

```
3f2a...e9  aid-antigravity-v0.7.0.tar.gz
7c41...b0  aid-claude-code-v0.7.0.tar.gz
9ab2...1d  aid-codex-v0.7.0.tar.gz
0e55...8f  aid-copilot-cli-v0.7.0.tar.gz
b18c...44  aid-cursor-v0.7.0.tar.gz
```

- Generated with `sha256sum aid-*.tar.gz > SHA256SUMS` (Linux) or `shasum -a 256` (macOS) — both
  are in the confirmed toolchain (`infrastructure.md` Toolchain lists `sha256sum or shasum`).
  `release.sh` selects whichever is present (prefer `sha256sum`, fall back to `shasum -a 256`),
  normalizing output to the two-space format so an adopter can verify with either tool.
- **Lines sorted by filename** for a deterministic, diffable file.
- Consumer (feature-001 `--from-bundle` / online verify): `sha256sum --check SHA256SUMS` (or
  `shasum -a 256 -c`), or compute-and-compare the single relevant tarball. This is the
  verify-before-install surface the offline/enterprise path depends on (REQUIREMENTS §3, §6).

#### S3.2 Optional detached signature (FLAGGED OPTIONAL)

A detached signature over `SHA256SUMS` (sign the checksum file, not each tarball — the checksum file
transitively covers all assets). Emitted only with `--sign`. Two candidate approaches, **both deferred
to a follow-up `/aid-specify` decision (and to feature-005, which owns the automated signing path):**

- **sigstore / cosign keyless** (`cosign sign-blob --yes SHA256SUMS` → `SHA256SUMS.sig` +
  certificate/bundle) — keyless OIDC signing aligns with the npm `--provenance` / PyPI Trusted
  Publishing posture feature-005 already targets (REQUIREMENTS §6, §8); strongest origin story, but
  adds a `cosign` dependency and an OIDC identity. **Recommended candidate** for the automated path.
- **minisign / GPG detached** (`SHA256SUMS.minisig` / `SHA256SUMS.asc`) — simpler, but introduces a
  long-lived signing key to manage, which the §8 OIDC-preferred stance wants to avoid.

For the **manual** first release (this feature), signing is OPTIONAL and OFF by default; `SHA256SUMS`
alone satisfies the verify-before-install AC. The signature approach is settled when feature-005
designs automated release signing — flagged here, not redefined.

### S4. Release / version contract (artifact side of FR10)

- **Tag format:** `v<VERSION>` (e.g. `v0.7.0`). `release.sh` derives the tag from the `VERSION`
  file; `gh release create` creates/pushes it.
- **VERSION → tarball names:** the bare `VERSION` content feeds both `<VERSION>` in every tarball
  name and the tag. One token, one source of truth (the `VERSION` file).
- **Asset URLs (immutable per release):**
  - Direct asset: `https://github.com/AndreVianna/aid-methodology/releases/download/v<VERSION>/aid-<tool>-v<VERSION>.tar.gz`
  - Checksums:    `https://github.com/AndreVianna/aid-methodology/releases/download/v<VERSION>/SHA256SUMS`
  - Latest resolution (online default): `https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest` → `tag_name`, then substitute into the direct-asset URL above.
- **Boundary with feature-005 (FR10):** this feature only guarantees `git tag` ⇆ `VERSION` ⇆ tarball
  names are consistent at release time (it FAILs on a `--version`/`VERSION` mismatch). Full
  reconciliation across `package.json` and `pyproject.toml`, and making mismatch fail in CI, is
  feature-005's job — referenced, not redefined here.

### S5. Design decisions and trade-offs (grounded)

- **Reuse the render-drift gate, don't reinvent it.** `release.sh` runs the exact
  `run_generator.py` + `git diff --exit-code -- profiles/` pair the CI `render-drift` job runs, so a
  manually-cut release and a future CI-cut release (feature-005) enforce one identical invariant.
  This satisfies AC "Packaging is cut from a render-drift-clean state and does not modify the
  canonical→profiles render pipeline."
- **Flat, README-free, install-root-relative tarballs** make feature-001's extract+copy trivial and
  guarantee the "equivalent install across channels" AC: every channel ships byte-identical tool
  trees because they all extract the same tarball.
- **Do NOT ship the build-time emission manifest.** It lacks a record for the root agent file — the
  file FR11 actually guards — so it cannot serve as feature-001's FR11/FR4 surface. feature-001 ignores
  it and computes its own per-file checksums (root file included) from the extracted bytes at install
  time, so shipping it would advertise an unconsumed, misleading contract. (S2.4)
- **`gh release create` over the raw REST API** — `gh` is the maintainer's confirmed tool; it handles
  tag creation, multi-asset upload, and auth in one command.
- **`tar -czf` with deterministic flags.** Use stable member ordering and a fixed mtime where
  practical so re-running `release.sh` on the same render produces stable archives (helps feature-005
  reproducibility). gzip embeds an mtime; if bit-for-bit reproducibility is required, pass
  `--no-name`/normalize via `gzip -n`. (Flagged as a refinement; the `SHA256SUMS` is what adopters
  verify against, regenerated each release, so non-reproducible gzip headers do not break verification.)

### S6. Testing (per `tests/canonical/test-*.sh` conventions)

A new suite `tests/canonical/test-release.sh`, auto-discovered by `tests/run-all.sh`'s
`tests/canonical/test-*.sh` glob (no edit to `run-all.sh` needed), following the suite shape of
`test-setup.sh`: `#!/usr/bin/env bash`, fixed header, `set -u`, `source ../lib/assert.sh`, `mktemp -d`
+ `trap 'rm -rf' EXIT`, one assert per case. The SUT is `release.sh` run in `--dry-run` (no network,
no `gh`, no tag creation) so the suite is hermetic and CI-safe.

Cases (illustrative):

- **RL01 naming:** `--dry-run` produces exactly five tarballs named `aid-<tool>-v<VERSION>.tar.gz`
  for the five tool ids at the `VERSION`-file version.
- **RL02 layout:** for each tarball, `tar -tzf` lists the expected install roots (S2.2), contains the
  root agent file, contains **no `README.md`**, and contains **no `emission-manifest.jsonl`**
  (build-time manifest is not shipped; S2.4).
- **RL03 flat root:** no entry is prefixed with a wrapping `aid-<tool>/` dir (extraction-root-relative).
- **RL04 SHA256SUMS format:** one `<64-hex>␠␠<filename>` line per tarball, sorted by filename, no
  self/sig lines; `sha256sum -c SHA256SUMS` (or `shasum -a 256 -c`) passes against the staged tarballs.
- **RL05 checksum correctness:** the hex in `SHA256SUMS` equals an independently computed sha256 of
  each staged tarball.
- **RL06 render-drift gate:** with a deliberately dirtied `profiles/` (a scratch copy), `release.sh`
  FAILs at the verify step and does not produce tarballs (assert the staging dir stays empty / exit
  non-zero). (Drive against a temp clone of the relevant inputs so the real `profiles/` is untouched.)
- **RL07 version mismatch:** `--version 9.9.9` against a `VERSION` of `0.7.0` FAILs before packaging.
- **RL08 help/exit:** `release.sh --help` renders the header block and exits 0; an unknown flag exits non-zero.

PowerShell parity is NOT required for `release.sh` (it is a maintainer-only Bash helper run on the
maintainer's machine; unlike `install.ps1`, there is no adopter-facing Windows release path).

### S7. Boundary statements (do NOT redefine here)

- **feature-001 (consumer)** extracts and installs these tarballs: **online** via the GitHub Release
  asset URL (`.../releases/download/v<VERSION>/aid-<tool>-v<VERSION>.tar.gz`, with `/releases/latest`
  resolving the default version) and **offline** via `--from-bundle <path-to-tarball>`. feature-001
  owns extract/copy semantics, host-tool detection, `--tool`, protect-on-diff (FR11), the install-time
  manifest, and uninstall (FR4). This feature only guarantees the **artifact shape** those consume.
- **feature-005 (automator)** wraps `release.sh` in a tag-triggered GitHub Actions workflow (one tag →
  Release + npm + PyPI), owns full FR10 version reconciliation, and owns automated signing/provenance.
  This feature is the **manual** release path that exists until feature-005 lands; it must not author
  CI or publish to any registry.
- **The render pipeline** is consumed read-only. `release.sh` invokes `run_generator.py` to PROVE a
  clean state and FAILs on drift — it never edits the pipeline and never commits a render.

### S8. Risks / open questions

- **R1 — gzip non-reproducibility (LOW).** gzip headers embed mtime, so re-archiving the same render
  may not be bit-identical across runs/machines. Mitigation: adopters verify against the per-release
  `SHA256SUMS`, not against an expected constant. If feature-005 wants reproducible artifacts, settle
  `gzip -n` / fixed-mtime tar there. Not a blocker for this feature.
- **R2 — signing approach unsettled (DEFERRED).** sigstore/cosign vs minisign/GPG is flagged optional
  and routed to feature-005 / a follow-up `/aid-specify`. The required `SHA256SUMS` stands alone for
  the manual path.
- **R3 — `gh` rate/auth + tag pre-existence.** `gh release create` needs maintainer auth and a
  non-existent tag. `release.sh` pre-checks tag existence (step 1) to fail early rather than mid-upload.
- **R4 — emission-manifest scope (RESOLVED).** Earlier drafts shipped the build-time
  `emission-manifest.jsonl` as an FR11/FR4 checksum surface. Disk verification showed its `dst` set
  omits the root agent file (`grep -c '"dst": "AGENTS.md"' profiles/codex/emission-manifest.jsonl` → 0),
  which is the exact file FR11 guards — so it cannot back FR11/FR4. Resolution: the manifest is **not
  shipped** (S2.4); feature-001 computes its own per-file checksums (root file included) from the
  extracted bytes at install time, matching its own spec which ignores any emission manifest. No
  cross-feature verification is outstanding.
- **R5 — empty/partial release safety.** `release.sh` aborts the whole run on any step failure (no
  partial `gh release create`); if `gh` fails mid-upload, the maintainer deletes the draft/tag and
  re-runs. Surfaced for feature-005 to make atomic in CI.
