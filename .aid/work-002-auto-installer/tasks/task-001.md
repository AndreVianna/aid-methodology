# task-001: Release-artifact contract & `release.sh` packaging core

**Type:** IMPLEMENT

**Source:** feature-002-release-packaging-and-checksums → delivery-001

**Depends on:** — (none)

**Scope:**
- Author `release.sh` at repo root (maintainer-only Bash helper) per feature-002 §S1: `#!/usr/bin/env bash`, fixed header block, `set -euo pipefail`, `-h|--help` via `sed -n` of the header, `while [[ $# -gt 0 ]] / case` arg parsing; POSIX-portable (Linux/macOS/Git Bash).
- Implement flags `--version X.Y.Z` (default = `VERSION` file; FAIL on mismatch), `--sign`, `--draft`, `--dry-run`, `--notes-file FILE`.
- Implement preconditions (run-from-root, clean worktree, tag-not-exists), the render-drift reuse gate (`python run_generator.py` + `git diff --exit-code -- profiles/` with the byte-identical CI remediation message), and staging under `.aid/.temp/release-<VERSION>/`.
- Implement the five-entry tool→profile-dir map (§S2.2) and `tar -czf` packaging of each profile's install-relevant subset into `aid-<tool>-v<VERSION>.tar.gz` with the flat, README-free, no-wrapping-dir, no-`emission-manifest.jsonl` layout (§S2.3, §S2.4).
- Emit `SHA256SUMS` over the five tarballs (sorted by filename, two-space format, `sha256sum` with `shasum -a 256` fallback) per §S3.1; `--dry-run` stops before `gh release create`.
- Defer the optional `--sign` signature mechanism to feature-005 (emit only if `--sign`; approach not redefined here).

**Acceptance Criteria:**
- [ ] `release.sh --dry-run` produces exactly five tarballs named `aid-<tool>-v<VERSION>.tar.gz` for the five canonical tool ids at the `VERSION`-file version.
- [ ] Each tarball, listed via `tar -tzf`, contains the §S2.2 install roots + the root agent file, is flat (no wrapping `aid-<tool>/` dir), and contains no `README.md` and no `emission-manifest.jsonl`.
- [ ] `SHA256SUMS` lists exactly the five tarballs (no self/sig lines), sorted by filename, in `<64-hex>␠␠<filename>` format, and `sha256sum -c` / `shasum -a 256 -c` passes against the staged tarballs.
- [ ] A deliberately dirtied `profiles/` causes the render-drift gate to FAIL before any tarball is produced; `--version 9.9.9` against `VERSION` 0.7.0 FAILs before packaging.
- [ ] `release.sh --help` renders the header block and exits 0; an unknown flag exits non-zero; `release.sh` never modifies the render pipeline and never commits a render.
- [ ] The tarball asset-naming and `SHA256SUMS` format match the feature-002 contract that the **default** offline/online consumer in task-003 verifies against (tar.gz only — no `.zip` variant in this task).
- [ ] All §6 quality gates pass.
