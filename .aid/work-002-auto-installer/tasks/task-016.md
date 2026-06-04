# task-016: One-tag release workflow (`release.yml`) + version-sync gate

**Type:** IMPLEMENT

**Source:** feature-005-ci-release-automation-and-version-sync → delivery-004

**Depends on:** task-001, task-011, task-013

**Scope:**
- Author `.github/workflows/release.yml` per feature-005 §S1–§S6: `on: push tags ['v*']` + `workflow_dispatch` (`ref`, `dry_run`); workflow-level `permissions: contents: write, id-token: write` (default-deny otherwise).
- Implement the `gate` job re-running the exact `test.yml` invariants on the tagged commit (render-drift with the byte-identical remediation string, the runtime-presence loud-fail block, `tests/run-all.sh`, generator self-tests, version-sync), reusing `test.yml`'s exact pinned action SHAs; derive the authoritative bare semver from the tag/ref and expose it via `$GITHUB_OUTPUT` (`gate.outputs.version`). The `gate` job deliberately runs only the release-correctness suites (render-drift, canonical-tests, generator self-tests, version-sync) and **deliberately omits `kb-hygiene`** — per SPEC §S2, `kb-hygiene` is repo-hygiene (PR-time on `test.yml`), not a release-correctness invariant, so its absence here is intentional, not an oversight.
- Implement the FR10 `version-sync` step (in `gate`) asserting `VERSION` == `package.json` == `pyproject.toml` == the tag-derived semver, failing the release on any mismatch; honor missing-manifest-skip only when that channel is disabled.
- Implement publish jobs each `needs:` `gate`: `github-release` (invokes feature-002 `release.sh`, `GH_TOKEN`, first), `npm-publish` (`needs: [gate, github-release]`, fail-closed `npm ci` + `npm publish --provenance --access public` — the `npm ci` step **requires the committed `package-lock.json` delivered by task-011** to be present in the npm package; without it `npm ci` fails closed), `pypi-publish` (`needs: [gate, github-release]`, `python -m build` + SHA-pinned `pypa/gh-action-pypi-publish` via Trusted Publishing); re-import `gate.outputs.version` as job-level `env: VERSION`.
- Implement `dry_run`, per-channel idempotency guards (`npm view` skip / PyPI `skip-existing`), and the `vars.NPM_ENABLED`/`vars.PYPI_ENABLED` first-release bootstrap flags (default false).
- SHA-pin every `uses:` (no moving tags), matching `test.yml` + the `infrastructure.md` C1 supply-chain posture; never edit `test.yml` or weaken branch protection.

**Acceptance Criteria:**
- [ ] A pushed `v*` tag (or `workflow_dispatch`) runs `gate` then, only when green, publishes the GitHub Release (tarballs + `SHA256SUMS` via `release.sh`) and the enabled npm/PyPI channels — all from one tag.
- [ ] npm publishes with `--provenance --access public`; PyPI publishes via Trusted Publishing (OIDC, sigstore attestations) using a SHA-pinned `pypa/gh-action-pypi-publish`; every `uses:` is SHA-pinned.
- [ ] `version-sync` reconciles git tag ⇆ `VERSION` ⇆ `package.json` ⇆ `pyproject.toml` and **fails the release on any mismatch**; missing manifests skip-with-notice only when their channel flag is off.
- [ ] The workflow never edits `test.yml` and never weakens branch protection (separate trigger, re-runs the gate on the tagged commit); `dry_run` builds + asserts version-sync with zero irreversible side effects.
- [ ] **npm auth default:** the publish keeps the `NPM_TOKEN` + `--provenance` path with the OIDC/Trusted-Publishing fallback noted (the SPEC-flagged default), rather than silently dropping `NPM_TOKEN`.
- [ ] **`npm ci` precondition (cross-ref task-011):** the `npm-publish` job's `npm ci` step is fail-closed and depends on the committed `package-lock.json` delivered by task-011 being shipped in the npm package; this task references that precondition but does not itself create the lockfile (task-011 owns it).
- [ ] **`kb-hygiene` deliberately excluded:** the `gate` job runs the release-correctness suites (render-drift, canonical-tests, generator self-tests, version-sync) and intentionally omits `kb-hygiene` per SPEC §S2 (repo-hygiene runs at PR time on `test.yml`, not as a release-correctness invariant); the omission is by design.
- [ ] All §6 quality gates pass.
