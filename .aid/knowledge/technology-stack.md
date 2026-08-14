---
kb-category: primary
source: hand-authored
objective: Every language, runtime, framework, package manager, build tool, and test/lint tool AID uses — with actual versions from config files and the exact runnable build/lint/test commands.
summary: Read this for any language-version or tool-version question, and for the exact commands to render, build, lint, and test AID before making a toolchain decision.
sources:
  - packages/npm/package.json
  - packages/pypi/pyproject.toml
  - site/package.json
  - VERSION
  - .github/workflows/test.yml
  - .claude/skills/generate-profile/scripts/run_generator.py
  - tests/run-all.sh
tags: [C0, languages, runtimes, frameworks, build-tools, testing, polyglot]
see_also: [architecture.md, infrastructure.md, test-landscape.md]
owner: architect
audience: [developer, architect, devops]
review-criteria:
  - id: F-01
    kind: validate
    criterion: >
      Every version this doc states for AID itself is asserted as lockstep with the `VERSION`
      file, never written as a literal number.
    severity: MEDIUM
    why: >
      A hard-coded version is stale at the next release and this doc is where a reader checks
      it. The number moved 1.1.1 to 2.0.6 to 2.3.0 while three literals here stayed put.
---

# Technology Stack

> **Source:** aid-discover (Phase 1)
> **Status:** Complete
> **Last Updated:** 2026-07-09

## Contents

- [Why AID Is Polyglot](#why-aid-is-polyglot)
- [Languages & Runtimes](#languages--runtimes)
- [Frameworks & Tooling](#frameworks--tooling)
- [Package Managers & Distribution](#package-managers--distribution)
- [Build Commands](#build-commands)
- [Lint Commands](#lint-commands)
- [Test Commands](#test-commands)
- [Key Dependencies](#key-dependencies)
- [Version Concerns](#version-concerns)

---

## Why AID Is Polyglot

AID is polyglot **by obligation, not preference** (a SYNTHESIS concept — "polyglot parity
obligation"): it must bootstrap on bare Bash and bare PowerShell hosts and ship through both
npm and PyPI, so the same install logic exists in two languages and is published through two
channels. CONFIRMED in `project-structure.md` (search: "AID is polyglot by design: it must
install through Bash and PowerShell hosts and ship via both npm and PyPI") and the parity
suite `tests/canonical/test-aid-cli-parity.sh`.

Product version: whatever `VERSION` holds — read it rather than trusting a number written here.
The invariant is **lockstep**: the npm and PyPI wrappers carry the same value, so
`packages/npm/package.json` (search: `"version"`) and `packages/pypi/pyproject.toml` (search:
`version =`) must both match `VERSION`, and `canonical/aid/scripts/release/check-version-sync.sh`
is what enforces it. A literal here was stale within three releases (1.1.1, then 2.0.6, then the
current value), which is why this doc asserts the lockstep and not the number.

---

## Languages & Runtimes

| Language | Version (source) | Role |
|----------|------------------|------|
| **Markdown** | n/a | The dominant artifact by file count (skills, agents, templates, KB, docs) — run `find . -name '*.md' \| wc -l` for the live total. The methodology IS markdown. |
| **Bash / Shell** | POSIX bash | Installers, CLI (`bin/aid`), install-core (`lib/aid-install-core.sh`), phase scripts, test suites — run `find . -name '*.sh' \| wc -l` for the live count. |
| **PowerShell** | **Windows PowerShell 5.1+** (compat floor) | Windows installer/CLI parity (`install.ps1`, `lib/AidInstallCore.psm1`, `bin/aid.ps1`). CONFIRMED `README.md` (search: "PowerShell 5.1+"). |
| **Python** | **>=3.8** (PyPI); CI pins **3.11** | The profile renderer, dashboard reader, PyPI wrapper. CONFIRMED `packages/pypi/pyproject.toml` (search: "requires-python = \">=3.8\"") and `.github/workflows/test.yml` (search: "python-version: '3.11'"). |
| **JavaScript (Node)** | **>=22** (npm wrapper and summarize validators); CI pins **24** | npm wrapper, dashboard Node server/reader (`reader.mjs`). The summarize validators (`validate-visuals.mjs`, `contrast-check.mjs`) require >=20 because Playwright 1.61.1 declared in their `package.json` does not support Node 18/19. CONFIRMED `packages/npm/package.json` (search: "node\": \">=18") and the repository-root `package.json` (search: "\"node\": \">=20\"") and `.github/workflows/test.yml` (search: "node-version: '20'"). |
| **TypeScript** | **6.0.3** (site dev dep) | The Astro website only. CONFIRMED `site/package.json` (search: "typescript"). |

**Node version policy (one floor, one test target -- they are different promises):** every
adopter-facing context requires Node **>=22**, and CI pins **24**.

The floor is 22 because Node 20 reached END-OF-LIFE on 2026-04-30 (nodejs/Release
`schedule.json`) while 22 is supported through 2027-04-30. Until 2026-08-08 the npm wrapper
declared >=18 and the summarize validators >=20, and CI pinned 20 -- so for three months every
merge was gated on a runtime receiving no security patches. The floor was raised in v3.0.0,
which is the release that could carry a breaking change.

CI pins **24** (Active LTS through 2028-04-30) rather than the floor, deliberately: we test on
the newest LTS and require only the oldest supported one. A pin with no expiry is how the
previous one silently became a pin to a dead runtime, so the number is re-checked each LTS
cycle. `site/` keeps its own higher floor of >=22.12.0 (Astro), which the shared 22 satisfies.

CONFIRMED `packages/npm/package.json` and the repository-root `package.json` (search:
"node"), `site/package.json` (search: ">=22.12.0"), and `.github/workflows/test.yml`
(search: "node-version").

Target OS: cross-platform (Linux/macOS via Bash, Windows via PowerShell). CONFIRMED by the
dual installer set and the Windows-only test lane (`tests/windows/`).

---

## Frameworks & Tooling

| Tool / Framework | Version (source) | Purpose |
|------------------|------------------|---------|
| **hatchling** | build backend | Builds the PyPI wheel/sdist; custom vendor hook `scripts/vendor.py`. CONFIRMED `packages/pypi/pyproject.toml` (search: "hatchling"). |
| **Astro** | **6.4.4** | The standalone product/docs website (`site/`). CONFIRMED `site/package.json`. |
| **@astrojs/starlight** | **0.39.3** | Docs theme for the site. CONFIRMED `site/package.json`. |
| **astro-mermaid** | **2.0.2** | Mermaid diagrams in the site. CONFIRMED `site/package.json`. |
| **marked** | **16.4.2** | Markdown parsing in site scripts. CONFIRMED `site/package.json`. |
| **sanitize-html** | **2.17.0** | HTML sanitization in site. CONFIRMED `site/package.json`. |
| **Playwright** | (npm `latest` via `npx playwright install chromium`) | Headless visual-fidelity gate for the summarize KB viewer. CONFIRMED `.github/workflows/test.yml` (search: "npx playwright install chromium") and `canonical/aid/scripts/summarize/validate-visuals.mjs`. |
| **GitHub Actions** | n/a | CI/CD — five workflows. CONFIRMED `.github/workflows/*.yml`. |

There is **no application framework** (no React/Django/Spring) — AID is content + scripts.
The only web framework (Astro) is confined to the marketing/docs site, which is an
independent build from the CLI/toolkit.

---

## Package Managers & Distribution

| Manager | Manifest | Lock file | Publishes |
|---------|----------|-----------|-----------|
| **npm** | `packages/npm/package.json` | (summarize: `package-lock.json`) | `aid-installer` (Node >=18). |
| **pip / pipx** | `packages/pypi/pyproject.toml` | — | `aid-installer` (Python >=3.8). |
| **GitHub Releases** | `release.sh` | `SHA256SUMS` | Five per-profile `aid-<tool>-v<VERSION>.tar.gz` bundles for offline/air-gapped install. |
| **curl \| bash / irm \| iex** | `install.sh` / `install.ps1` | — | Direct bootstrap of the `aid` CLI. |

All four channels deliver the same `aid` CLI. CONFIRMED `README.md` "Install" (search: "All
four channels deliver the same aid CLI").

---

## Build Commands

AID has several distinct "builds". The authoritative commands are what CI runs
(`.github/workflows/test.yml`):

```bash
# 1. Render the product: canonical/ -> profiles/ (the core build). Run from repo root.
python .claude/skills/generate-profile/scripts/run_generator.py

# 2. Build the PyPI distribution (wheel + sdist) — from packages/pypi/
python -m build            # uses hatchling backend per pyproject.toml

# 3. Pack the npm distribution (runs scripts/vendor.js via prepack) — from packages/npm/
npm pack                   # or: npm publish

# 4. Build the Astro website — from site/
npm ci && npm run build    # 'build' = 'astro build'; prebuild syncs docs+reference+release data

# 5. Cut a release (maintainer) — from repo root
bash release.sh            # packages the five per-profile tarballs + GitHub Release
```

CONFIRMED: command (1) in `run_generator.py` and `.github/workflows/test.yml` (search:
"Regenerate install trees from canonical/"); (3) in `packages/npm/package.json` (search:
"prepack"); (4) in `site/package.json` (search: `"build": "astro build"`); (5) in
`docs/repository-structure.md` / `release.sh` header.

---

## Lint Commands

AID has no general source linter (no eslint/ruff/shellcheck gate in CI). Its "lint" surface
is **KB hygiene + generator/parity self-checks + render determinism**:

```bash
# KB frontmatter lint (shipped tool)
bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge

# KB citation lint (every claim must carry a durable anchor)
bash .claude/aid/scripts/kb/kb-citation-lint.sh --root .aid/knowledge

# INDEX freshness (regenerate + diff)
bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output /tmp/INDEX.regen.md

# Render-drift check (profiles/ must match canonical/): re-render then `git diff --exit-code -- profiles/`
python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/

# PowerShell 5.1 compatibility lint (Windows-shipped scripts)
pwsh tests/canonical/ps51-compat-check.ps1

# Astro type/content check — from site/
npm run check              # = 'astro check'
```

CONFIRMED in `.github/workflows/test.yml` (search: "Frontmatter lint", "INDEX.md is fresh",
"profiles/ is out of sync") and `site/package.json` (search: `"check": "astro check"`).

---

## Test Commands

```bash
# All canonical cross-platform suites (the shared CI + local gate). HOME-pin to avoid
# migrating the developer's real repos.
HOME=/tmp/aid-throwaway bash tests/run-all.sh
bash tests/run-all.sh -v          # verbose

# Generator unit self-tests (Python)
python .claude/skills/generate-profile/scripts/render_lib.py --self-test
python .claude/skills/generate-profile/scripts/test_manifest_safety.py --self-test
python .claude/skills/generate-profile/scripts/render.py --self-test --canonical-root .
python .claude/skills/generate-profile/scripts/verify_deterministic.py --self-test --canonical-root .
python .claude/skills/generate-profile/scripts/verify_advisory.py --self-test --canonical-root .

# Dashboard Python reader tests
pytest dashboard/reader/tests/

# Dashboard Node server tests
node dashboard/server/tests/test_server_node.mjs

# Site data tests — from site/
npm test                          # = 'vitest run'

# Windows-only installer tests (runs only on the windows-latest CI lane)
pwsh tests/windows/Test-AidInstaller.ps1
```

CONFIRMED in `.github/workflows/test.yml` (jobs: `canonical-tests`, `generator-selftests`)
and `tests/run-all.sh` (search: "run every canonical test suite"). The canonical suites are
discovered by glob (`tests/canonical/test-*.sh`), each run under `timeout 300`. See
`test-landscape.md` for coverage detail.

---

## Key Dependencies

> AID deliberately ships **zero runtime dependencies** for the CLI — both wrappers declare
> empty dependency sets so install is fast and supply-chain-light.

| Package | Version | Where | Concern |
|---------|---------|-------|---------|
| npm `dependencies` | `{}` (empty) | `packages/npm/package.json` | None — CLI is pure Bash/Node-stdlib. CONFIRMED. |
| pypi `dependencies` | `[]` (empty) | `packages/pypi/pyproject.toml` | None — wrapper is stdlib-only. CONFIRMED. |
| astro | 6.4.4 | `site/` only | Site-only; not in the shipped CLI. |
| typescript | 6.0.3 | `site/` dev | Site-only. |
| vitest | ^4.1.8 | `site/` dev | Site test runner. |
| yaml (override) | ^2.8.3 | `site/` | Pinned via `overrides` to resolve a transitive constraint. CONFIRMED `site/package.json` (search: "overrides"). |

The Python renderer and dashboard reader use **only the standard library** (no third-party
imports needed at runtime) — CONFIRMED by the empty PyPI dependency set and
`canonical/EMISSION-MANIFEST.md` (search: "Zero runtime dependency").

---

## Version Concerns

| Item | Current | Status | Note |
|------|---------|--------|------|
| Windows PowerShell | 5.1 floor | OK (intentional) | Shipped PS MUST stay 5.1-compatible; a dedicated CI lane + AST lint guard this. |
| Python | >=3.8 (CI 3.11) | OK | Wide floor for broad adopter reach. |
| Node | >=18 (CLI), >=20 (summarize validators), >=22.12 (site), 20 (CI) | OK but split | **Four** different Node floors across contexts — verify the right one per task. CONFIRMED the repository-root `package.json` (search: "\"node\": \">=20\""). |
| PyPI classifier | "4 - Beta" | Informational | `pyproject.toml` declares Beta development status. |

No EOL or known-CVE runtime dependency was observed (the CLI ships none). See
`tech-debt.md` for risk items beyond versioning.
