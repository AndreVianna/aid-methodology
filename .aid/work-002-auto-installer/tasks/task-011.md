# task-011: npm wrapper package (`@aid/installer`) — vendor-and-spawn CLI

**Type:** IMPLEMENT

**Source:** feature-003-npm-installer-cli → delivery-002

**Depends on:** task-003, task-005

**Scope:**
- Author the npm package at `packages/npm/` per feature-003 §S1: `package.json` named `@aid/installer`, single `bin` `aid-installer` → `bin/aid-installer.js`, `type: commonjs`, `engines.node: ">=18"`, empty `dependencies`, and the `files` allowlist shipping `bin/`, vendored `install.sh`, `install.ps1`, `lib/`, `VERSION`, `README.md`, `LICENSE`.
- Vendor feature-001's `install.sh`/`install.ps1`/`lib/*` verbatim into the package payload (§S2) and resolve them via `path.join(__dirname, '..')`.
- Implement the Node bin (pure built-ins) per §S3/§S4: platform-shell selection (`win32` → `pwsh -NoProfile -ExecutionPolicy Bypass -File install.ps1`, fallback `powershell`; else `bash install.sh`), 1:1 opaque arg passthrough with the Unix→PowerShell flag-translation table, `spawnSync(cmd, argvArray, {stdio:'inherit'})` (array spawn, no `shell:true`), and verbatim exit-code relay (0–6; signal→1).
- Set `package.json` `version` equal to the `VERSION` file; declare (do not implement) the FR10 `package.json ⇆ VERSION` edge for feature-005.
- The bin originates only the missing-shell error (exit 1) and forwards `-h|--help` to the bootstrap; it does NOT validate `--tool`/mutual-exclusion/target (the bootstrap is the single validator).
- Commit a git-tracked `package-lock.json` inside the npm package (an empty-`dependencies` lockfile is acceptable) and include it in the publish `files` allowlist, so feature-005/delivery-004's fail-closed release `npm ci` has a committed lockfile to install against (cross-delivery requirement from delivery-004).
- npm scope ownership: the `@aid` npm scope must be owned/acquired before first publish (a prerequisite — softer than PyPI's hard blocker, as the scope is acquirable rather than reserved). The manual `npm publish --access public` path exists here; automated publish + `--provenance` is owned by feature-005/delivery-004 (pointer — not redefined here). Publish-credential default per the SPEC's flagged default = keep `NPM_TOKEN` plus provenance, with OIDC Trusted-Publishing as the fallback, to verify before first publish.
- npx offline caveat (SPEC §S9.1): the "verify `npx --offline`/`--prefer-offline` semantics against npm docs before build" caveat is owned here; air-gapped users are pointed at the M2 channels / `--from-bundle` rather than relying on npx offline behavior.

**Acceptance Criteria:**
- [ ] `npx @aid/installer` (auto-detect or `--tool`) installs/updates AID by spawning the vendored bootstrap, with the same result as the M2 channels; the package contains zero install logic.
- [ ] Args forward 1:1 to `install.sh` on Unix and translate to `install.ps1` `-Param` spellings on the Windows path (per the S3 table); values with spaces/metachars pass as single argv elements (array spawn).
- [ ] Exit codes 0–6 from the bootstrap propagate unchanged; a missing platform shell exits 1 with the documented message.
- [ ] `package.json` declares `version` == the repo `VERSION` (declaration only — feature-005 owns the enforcing CI gate per SPEC §S6); the `files` allowlist ships `install.sh`, `install.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`, `VERSION`, `bin/aid-installer.js`, `package-lock.json` and excludes `tests/` and `.aid/`.
- [ ] A git-tracked `package-lock.json` exists inside the npm package and `npm ci` succeeds against it (empty-`dependencies` lockfile acceptable), satisfying feature-005's fail-closed release `npm ci`.
- [ ] On the Windows path the spawn resolves `pwsh` and falls back to `powershell` when `pwsh` is absent (SPEC §S4 fallback).
- [ ] The `@aid` npm scope is owned/acquired before publish, and the publish-credential default is confirmed (`NPM_TOKEN` + provenance, OIDC Trusted-Publishing fallback) before first publish; automated publish/`--provenance` is deferred to feature-005/delivery-004.
- [ ] All §6 quality gates pass.
