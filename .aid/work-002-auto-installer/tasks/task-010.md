# task-010: First manual release dry-run + delivery-001 end-to-end validation

**Type:** TEST

**Source:** feature-002-release-packaging-and-checksums → delivery-001

**Depends on:** task-001, task-007

**Scope:**
- Validate the full delivery-001 loop end-to-end: run `release.sh --dry-run` to produce the five tarballs + `SHA256SUMS` into staging, then drive both `install.sh` and `install.ps1` against those staged tarballs via `--from-bundle` into temp targets, asserting a real install (not a fixture) lands correctly and verifies against the staged `SHA256SUMS`.
- Validate the online resolution shape against the feature-002 asset-URL/`SHA256SUMS` contract using a stubbed/local server or a network-gated check (no dependence on a live published release).
- Confirm the artifact→install handshake works with the **default tar.gz-only** artifact set (no `.zip` variant) and the **default** manifest location.

**Acceptance Criteria:**
- [ ] `release.sh --dry-run` artifacts install correctly through both `install.sh --from-bundle` and `install.ps1 -FromBundle` and verify against the staged `SHA256SUMS` (exit 4 on a tampered tarball).
- [ ] The online resolution/verify path is validated against the feature-002 URL/`SHA256SUMS` contract via a stub or network-gated check, with no dependence on a live release.
- [ ] The full delivery-001 loop (package → verify → install → update → uninstall) passes across both bootstraps using the default manifest location `.aid/.aid-manifest.json`.
- [ ] All §6 quality gates pass.
