# One-command AID installer for adopter repos

- **Work:** work-002-auto-installer
- **Created:** 2026-06-04
- **Source:** /aid-interview lite path — LITE-FEATURE
- **Status:** Ready

## Goal

Today, adopting AID requires a developer to manually clone the entire AID repository
and run the platform-specific `setup.sh` / `setup.ps1` script to copy the methodology
into their project. That is friction: it pulls down the whole repo (canonical sources,
all profiles, tests, and maintainer-only tooling the adopter does not need), requires
knowing which script to run, and offers no clean update or uninstall path. The goal is a
frictionless, ideally one-command way to **deploy the AID methodology into an adopter's
repo** — fetching only what the target needs, detecting the host tool (Claude Code /
Codex / Cursor / Copilot CLI / Antigravity), and making install, update, and uninstall
trivial. Distribution should work both online (fetch from the remote) and offline (from a
pre-downloaded bundle).

## Context

**Scope:**

*In scope:*
- **Research & recommend** a deployment mechanism, comparing candidate approaches:
  `curl … | bash` / `irm … | iex` one-liner hosted off GitHub, a versioned GitHub Release
  tarball + tiny bootstrap, an `npx` / `pipx`-style published CLI, a `gh` extension, and
  `degit` / sparse-checkout. Score on: zero-clone footprint, host-tool detection,
  cross-platform (bash + PowerShell), update path, uninstall, offline/online support, and
  maintainer upkeep. Produce a written, scored recommendation with rationale.
- **Implement the chosen mechanism**: a bootstrap entry point that fetches only the
  relevant rendered profile tree (`.claude/`, `.cursor/`, `.agents/`, `.github/`,
  `.agent/`) into the target repo — not the whole AID repo.
- **Host-tool detection / selection** — auto-detect with an explicit override flag.
- **Versioning + update** — install a pinned AID release; re-run to update; record the
  installed version in the target repo for reproducibility.
- **Uninstall** — cleanly remove all AID-installed files.
- **Online and offline installer modes** — fetch-from-remote and install-from-bundle.
- **Docs** for the new install/update/uninstall flow.

*Out of scope (this work):*
- Changing the canonical → profiles render pipeline itself.
- Publishing to package registries (npm / PyPI / Homebrew) — unless the research
  explicitly selects that path.

**Constraints / preferences:**
- **Minimal dependencies (best-effort).** Prefer commonly-available tooling
  (git / curl / tar, or PowerShell equivalents) and AID's "no third-party runtime deps"
  stance (see KB `technology-stack.md`, `infrastructure.md`). A heavier runtime
  (Node / Python) is acceptable only if the research clearly justifies it.

**KB references:**
- `infrastructure.md` — current `setup.sh` / `setup.ps1` install scripts and the
  canonical → 5-profiles render model.
- `technology-stack.md` — Bash / PowerShell / Python (stdlib-only) toolchain; no
  third-party runtime libraries.
- `architecture.md` — canonical → render → install pipeline emitting per-host-tool
  install trees.

## Acceptance Criteria

- [ ] **Given** a developer in a target repository with no prior AID setup, **when** they run the documented one-command installer (specifying or auto-detecting their host tool), **then** the correct rendered profile tree (e.g. `.claude/`, `.cursor/`, `.agents/`, `.github/`, `.agent/`) is installed **or updated** in the repo at a pinned AID version — without cloning the full AID repository.
- [ ] **Given** the research task is complete, **when** the recommendation is reviewed, **then** a written comparison of the candidate mechanisms exists with a scored recommendation and rationale.
- [ ] **Given** an installed AID setup in a target repo, **when** the developer runs the uninstall command, **then** all AID-installed files are removed cleanly, leaving the repo as it was pre-install.
- [ ] **Given** the host tool is not specified, **when** the installer runs, **then** it auto-detects the host tool (or prompts/errors clearly if it cannot), with an explicit override flag available.
- [ ] **Given** both Unix and Windows environments, **when** the installer runs, **then** it works cross-platform (bash and PowerShell paths).
- [ ] **Given** AID's minimal-dependency stance, **when** the chosen mechanism is implemented, **then** it relies only on commonly-available tooling (git / curl / tar or PowerShell equivalents) unless the research explicitly justifies otherwise.
- [ ] **Given** a pinned AID release, **when** install or update runs, **then** the installed version is recorded in the target repo so updates are reproducible.
- [ ] **Given** environments with and without network access, **when** the developer installs AID, **then** both an **online installer** (fetches the pinned release from the remote) and an **offline installer** (installs from a pre-downloaded bundle/archive, no network) are supported.
- [ ] All applicable quality gates pass — the universal grading rubric enforced per task by `/aid-execute` (this lite SPEC has no numbered §6; the gate is the rubric-driven review).

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | RESEARCH | Deployment-mechanism comparison + scored recommendation |
| task-002 | IMPLEMENT | Installer for the chosen mechanism |
| task-003 | TEST | Installer verification suite |
| task-004 | DOCUMENT | Install / update / uninstall flow docs |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-002 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
| 3 | task-003, task-004 |

### Re-plan checkpoint (mandatory gate between wave 1 and wave 2)

After task-001 (RESEARCH) lands, re-evaluate scope before starting task-002 based on the
**implementation effort** the recommended mechanism demands — *not* on whether AID
currently has that capability. The absence of a release pipeline or package-registry
presence today is the status quo this work may legitimately change, **not** a constraint;
likewise, minimal external dependencies is a *weighted preference* (best-effort per the
Goal), **not** a disqualifier. Escalate to the full path (or split task-002) only if the
chosen mechanism's implementation genuinely exceeds a single bounded IMPLEMENT unit — e.g.
it requires standing up and maintaining substantial new CI/release automation or a
multi-component publishing toolchain. Otherwise the lite 4-task plan holds and wave 2
proceeds.

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Initial lite-path SPEC created | /aid-interview LITE-FEATURE |
| 2026-06-04 | LITE-REVIEW fixes: reworded dangling §6 gate; added mandatory re-plan checkpoint | /aid-interview LITE-REVIEW |
| 2026-06-04 | Re-plan checkpoint de-biased: current-state (no pipeline/registry) and minimal-deps reframed as effort/preference, not hard constraints — triggers task-001 re-run | /aid-execute task-001 (user correction) |
