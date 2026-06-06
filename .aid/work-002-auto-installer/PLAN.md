# Plan — work-002-auto-installer

> Delivery roadmap for the AID auto-installer. Each delivery is a standalone-functional MVP.
> Build order honors REQUIREMENTS §10 (M2 → M3a/M3b → M7); npm/PyPI are split into separate
> deliveries so the PyPI org-registration blocker cannot hold up the npm channel, and the
> independent feature-006 is its own delivery (sequence early).

## Deliverables

### delivery-001: Foundation install (curl + offline tar)
- **What it delivers:** An adopter installs / updates / uninstalls AID into their repo with one
  command — `curl … | bash` / `irm … | iex` (online) or verify-then-install from an offline
  `--from-bundle` tarball. Host-tool auto-detect or `--tool`, version-pinned, manifest-based
  uninstall, protect-on-diff for root agent files. Maintainer cuts releases manually via
  `release.sh` + `gh release create`. Replaces `setup.sh` / `setup.ps1`.
- **Features:** feature-002-release-packaging-and-checksums, feature-001-shared-install-core-and-bootstrap
- **Depends on:** —
- **Priority:** Must
- **Standalone MVP:** the load-bearing deliverable — after it ships, an adopter can fully adopt
  AID (online or air-gapped) with zero Node/Python, and the maintainer can cut real releases.
  002 + 001 must ship together: 001's end-to-end install needs 002's tarball+checksum artifact,
  and 002 alone produces artifacts nothing consumes.

### delivery-002: npm install channel
- **What it delivers:** Node developers run `npx @aid/installer …` for the same install/update
  with registry integrity. Thin vendor-and-spawn wrapper over the delivery-001 core.
- **Features:** feature-003-npm-installer-cli
- **Depends on:** delivery-001
- **Priority:** Must
- **Standalone MVP:** a self-contained convenience surface for the Node audience; `@aid` scope is
  acquirable, so it ships unblocked. Parallelizable with delivery-003.

### delivery-003: PyPI install channel
- **What it delivers:** Python / data / AI developers run `pipx run aid-installer …` for the same
  install/update. Symmetric with the npm channel.
- **Features:** feature-004-pypi-installer-cli
- **Depends on:** delivery-001
- **Priority:** Must
- **Standalone MVP:** a self-contained surface for the Python audience. Carries the CasuloAI Labs
  PyPI-org registration prerequisite (see Risk 1); split from delivery-002 so npm is not blocked
  by it. Parallelizable with delivery-002.

### delivery-004: One-tag CI release automation
- **What it delivers:** Maintainer pushes one version tag → GitHub Release tarballs + `SHA256SUMS`
  + npm (`--provenance`) + PyPI (Trusted Publishing) all published automatically, with FR10
  version-sync enforced and branch protection preserved. Adopters get provenance/attestations.
- **Features:** feature-005-ci-release-automation-and-version-sync
- **Depends on:** delivery-001, delivery-002, delivery-003
- **Priority:** Should
- **Standalone MVP:** replaces manual release-cutting with one-tag automation across all three
  artifact surfaces. Ships last because it automates what 001/002/003 do manually.

### delivery-005: Invariant root AGENTS.md
- **What it delivers:** A multi-tool adopter installing two AGENTS.md-writing tools gets a
  byte-identical root `AGENTS.md`, so the second install never triggers a protect-on-diff
  false-positive warning.
- **Features:** feature-006-invariant-agents-md
- **Depends on:** — (independent)
- **Priority:** Should
- **Standalone MVP:** independent canonical-content normalization; blocks nothing, requires
  nothing. **Sequence early** (before/alongside delivery-001) so the first multi-tool installs
  are collision-free.

## Sequence

`delivery-005` (independent, early) → `delivery-001` → `delivery-002 ∥ delivery-003` → `delivery-004`

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | CasuloAI Labs PyPI org not registered (hard external blocker, delivery-003) | H | Kick off org registration + `aid-installer` name reservation as a parallel non-engineering track when delivery-001 starts; the 003/004 split keeps npm unblocked. |
| 2 | Non-atomic partial publish across 3 registries (delivery-004) | M | Idempotent / re-runnable `release.yml` with a "which artifacts already published" recovery path; FR10 version-sync gate prevents wrong-version publishes. |
| 3 | First-release bootstrapping — no `v*` tags yet; `package.json`/`pyproject.toml` created by 003/004; first Trusted-Publishing trust setup | M | delivery-001 cuts the first release manually via `release.sh`, de-risking the virgin-repo edge cases before delivery-004 automates them; `NPM_ENABLED`/`PYPI_ENABLED` flags gate first publishes. |
| 4 | `@aid` npm scope ownership (delivery-002) | L | Verify/acquire the scope early (softer than the PyPI blocker — acquirable, not unregistered). |

## Deferred

*(None — all six features are assigned to deliveries.)*

## Execution Graph

> Per-delivery task dependency graphs and parallel waves. Tasks map: delivery-001 → 001–010;
> delivery-002 → 011–012; delivery-003 → 013–015; delivery-004 → 016–017; delivery-005 → 018–019.
> `∥` denotes tracks that run in parallel.

### delivery-001 — Foundation install (curl + offline tar)

Two parallel core tracks (bash, PowerShell) fork from the artifact contract, then converge for
cross-platform parity, the setup-script removal, docs, and the end-to-end release validation.

| Task | Type | Depends on |
|------|------|------------|
| 001 | IMPLEMENT | — (none) |
| 002 | TEST | 001 |
| 003 | IMPLEMENT | 001 |
| 004 | TEST | 003 |
| 005 | IMPLEMENT | 001 |
| 006 | TEST | 005 |
| 007 | TEST | 004, 006 |
| 008 | REFACTOR | 004 |
| 009 | DOCUMENT | 006, 008 |
| 010 | TEST | 007 |

**Waves:**
- **Wave 1:** 001 (release-artifact contract — root of everything).
- **Wave 2:** 002 (release tests) ∥ 003 (bash core) ∥ 005 (PowerShell core).
- **Wave 3:** 004 (bash tests, after 003) ∥ 006 (PowerShell tests, after 005).
- **Wave 4:** 007 (cross-platform parity; needs 004 + 006) ∥ 008 (remove setup.sh/ps1; needs 004).
- **Wave 5:** 009 (M2 docs; needs 006 + 008) ∥ 010 (end-to-end release validation; needs 007).

**Bash track:** 001 → 003 → 004 → (007, 008). **PowerShell track:** 001 → 005 → 006 → (007, 009).
**Critical path:** 001 → 003 → 004 → … with 006 required for 007 → 007 → 010, i.e.
`001 → 003 → 004 → 006 → 007 → 010` (006 gates 007 alongside 004; 005 → 006 runs in parallel with the bash track).

### delivery-002 — npm install channel

The npm wrapper vendors and spawns **both** bootstraps, so it needs both cores before it can be built.

| Task | Type | Depends on |
|------|------|------------|
| 011 | IMPLEMENT | 003, 005 |
| 012 | TEST | 011 |

**Waves:**
- **Wave 1:** 011 (npm vendor-and-spawn CLI; needs the bash core 003 + PowerShell core 005 from delivery-001).
- **Wave 2:** 012 (npm wrapper tests; needs 011).

**Critical path:** `(003, 005) → 011 → 012`.

### delivery-003 — PyPI install channel

Symmetric with delivery-002; the registration prerequisite runbook is the human-track tail.

| Task | Type | Depends on |
|------|------|------------|
| 013 | IMPLEMENT | 003, 005 |
| 014 | TEST | 013 |
| 015 | DOCUMENT | 014 |

**Waves:**
- **Wave 1:** 013 (PyPI vendor-and-spawn CLI; needs bash core 003 + PowerShell core 005).
- **Wave 2:** 014 (PyPI wrapper tests + vendored-payload parity; needs 013).
- **Wave 3:** 015 (PyPI org-registration prerequisite + publish runbook; needs 014).

**Critical path:** `(003, 005) → 013 → 014 → 015`. Parallelizable end-to-end with delivery-002.

### delivery-004 — One-tag CI release automation

The release workflow needs the packaging core (001) plus both package manifests (011, 013) to
reconcile FR10 version-sync across all carriers.

| Task | Type | Depends on |
|------|------|------------|
| 016 | IMPLEMENT | 001, 011, 013 |
| 017 | TEST | 016 |

**Waves:**
- **Wave 1:** 016 (`release.yml` + version-sync gate; needs `release.sh` 001 + `package.json` 011 + `pyproject.toml` 013).
- **Wave 2:** 017 (version-sync unit test + workflow validation; needs 016).

**Critical path:** `(001, 011, 013) → 016 → 017`. Ships last (automates what 001/002/003 do manually).

### delivery-005 — Invariant root AGENTS.md

Fully independent; sequence early (before/alongside delivery-001) so the first multi-tool installs
are collision-free.

| Task | Type | Depends on |
|------|------|------------|
| 018 | IMPLEMENT | — (none) |
| 019 | TEST | 018 |

**Waves:**
- **Wave 1:** 018 (normalize the four root `AGENTS.md` to byte-invariant).
- **Wave 2:** 019 (CI invariance guard; needs 018).

**Critical path:** `018 → 019`. Independent of deliveries 001–004.
