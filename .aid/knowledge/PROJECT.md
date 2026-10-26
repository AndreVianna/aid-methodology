---
kb-category: primary
source: hand-authored
objective: The one-page card of AID, covering what it is, its stack, how to build, test and lint it, where things live, and the rules that never bend.
summary: Read this first in every session; open INDEX.md only to find a specific KB document.
sources: [VERSION, tests/run-all.sh, .github/workflows/test.yml, .claude/skills/generate-profile/scripts/run_generator.py]
---

# AID -- Project Card

## What it is

AID (AI Integrated Development) is a methodology for building software with AI agents, shipped as a multi-tool CLI installer.
Its content is authored once in `canonical/`; the repo also runs AID on itself (the dogfood install).

## Stack

- Markdown content (skills, agents, templates, KB); Bash and PowerShell (5.1 floor) twins; Astro website in `site/`.
- Python >=3.8 (CI 3.11); Node >=22 (CI 24). Product version: the `VERSION` file, same in the npm and PyPI wrappers.

## Commands

Run from the repo root.
- Build (render `profiles/`, resync the dogfood install): `python3 .claude/skills/generate-profile/scripts/run_generator.py`
- Test, all (throwaway HOME, so no real repo is migrated): `HOME=$(mktemp -d) bash tests/run-all.sh`; one suite: `bash tests/canonical/test-<name>.sh`
- Test, the suites a change touches: `bash tests/canonical/select-suites.sh --run`
- Lint, KB: `bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge`, then `bash .aid/runtime/scripts/kb/kb-citation-lint.sh --root .aid/knowledge`
- Lint, PowerShell 5.1: `pwsh tests/canonical/ps51-compat-check.ps1`
- Rebuild the KB index: `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`

## Where things live

- `canonical/` is the source of truth: `canonical/skills/`, `canonical/agents/`, `canonical/aid/` (runtime scripts, templates, `rules.md`).
- `profiles/`, `.agents/`, `.claude/skills/aid-*`, `.cursor/`, `.aid/runtime/` are generated or installed from it; never hand-edit them.
- `bin/`, `lib/`, `install.sh`, `install.ps1`: the `aid` CLI and installers. `tests/`: `run-all.sh`, `canonical/test-*.sh`, `tests/windows/`.
- `packages/` (npm, PyPI wrappers), `dashboard/`, `site/`. `.aid/knowledge/` is this KB; `.aid/works/` is transient per-work state.

## Rules that never bend

1. Edit `canonical/`, then resync and commit the resync output alone (CI job `render-drift` in `.github/workflows/test.yml`).
2. Every change ships with its tests, in the same change (`test-landscape.md`).
3. Bash and PowerShell twins change in the same commit and print byte-identical output (`tests/canonical/test-aid-cli-parity.sh`).
4. Shipped PowerShell is ASCII-only and 5.1-compatible; shipped `.sh` is LF-only (`ps51-compat-check.ps1`, CI).
5. `.aid/knowledge/**` names no work id or work-folder path and keeps no history (`tests/canonical/test-kb-no-work-ids.sh`).
6. Resolve a file's review criteria before writing it (`authoring-conventions.md`).
7. Record every state change in the work's STATE file at once; work folders are transient (`canonical/aid/rules.md`).
8. Read settings only through `read-setting.sh`, never by parsing `settings.yml` (`coding-standards.md`).

## Detail

- Layout, boundaries, invariants: `project-structure.md`, `architecture.md`, `module-map.md`. Tool versions: `technology-stack.md`.
- Code conventions: `coding-standards.md`. Suites and CI lanes: `test-landscape.md`. KB authoring and grading: `authoring-conventions.md`, `quality-gates.md`.
