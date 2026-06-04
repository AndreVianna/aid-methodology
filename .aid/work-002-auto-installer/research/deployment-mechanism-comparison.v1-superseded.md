# Deployment Mechanism Comparison — AID Auto-Installer

**Work:** work-002-auto-installer
**Task:** task-001 (RESEARCH)
**Date:** 2026-06-04
**Author:** Researcher sub-agent

---

## Context

AID today requires an adopter to `git clone` the full repository (~2 MB, ~257 files per
profile), then run `setup.sh` or `setup.ps1` to interactively copy one profile tree into
their project. This carries three friction points:

1. The adopter downloads the full repo (canonical sources, tests, maintainer-only tooling
   they do not need).
2. Install is interactive-only; no scriptable one-liner, no host-tool auto-detection.
3. No update, version-pinning, or uninstall path — re-running setup is the only recourse.

The goal is a **frictionless one-command installer** that: (a) fetches only the ONE chosen
profile tree, (b) auto-detects the host tool with an override, (c) records the installed
version, (d) supports update and uninstall, and (e) works both online and offline.

### Key AID constraints (from KB)

| Constraint | Source |
|------------|--------|
| No third-party runtime dependencies | `technology-stack.md` "Python uses stdlib only"; no `requirements.txt`, no `package.json` |
| No existing release/package-registry pipeline | `infrastructure.md` "There is no published package on npm, PyPI, Homebrew, Chocolatey, or any other package registry" |
| No existing Release pipeline in GitHub Actions | `infrastructure.md` "There is also no release pipeline"; CI job is test-only (`test.yml`) |
| Toolchain baseline: git, curl, tar, PowerShell 5.1+, Bash 4+ | `technology-stack.md` Runtime table; `infrastructure.md` Toolchain table |
| Installer fetches ONE rendered profile tree, not whole repo | `architecture.md` Profile Install Trees; each tree is ~257 files, ~2 MB |
| Profile trees are already pre-rendered and committed | `infrastructure.md` Build Pipeline; profiles/ committed in the repo |
| Repo hosted on GitHub (AndreVianna/aid-methodology) | `infrastructure.md` Source Control table |
| `gh` CLI available to maintainer for PR/issue/release ops | `infrastructure.md` Toolchain table |

The five profile install roots are:
- **claude-code:** `profiles/claude-code/.claude/` + `CLAUDE.md`
- **codex:** `profiles/codex/.codex/` + `profiles/codex/.agents/` + `AGENTS.md`
- **cursor:** `profiles/cursor/.cursor/` + `AGENTS.md`
- **copilot-cli:** `profiles/copilot-cli/.github/` + `AGENTS.md`
- **antigravity:** `profiles/antigravity/.agent/` + `AGENTS.md`

---

## Candidate Mechanisms

Five mechanisms are evaluated:

1. `curl ... | bash` / `irm ... | iex` — one-liner hosted off GitHub raw
2. Versioned GitHub Release tarball + tiny bootstrap script
3. `npx` / `pipx`-style published CLI
4. `gh` GitHub CLI extension
5. `degit` / git sparse-checkout

---

## Scoring Matrix

Each mechanism is scored against the eight SPEC axes on a 1–5 scale (5 = fully satisfies;
3 = partial/workaround needed; 1 = does not satisfy or requires new infrastructure).

### Scale definition

| Score | Meaning |
|-------|---------|
| 5 | Fully satisfies the axis with no new infrastructure |
| 4 | Mostly satisfies; minor gap or caveat |
| 3 | Partial — workaround exists but adds complexity |
| 2 | Weak — significant gap or manual step required |
| 1 | Does not satisfy; requires new infrastructure or is incompatible |

### Axis definitions (from SPEC)

| Axis | What it tests |
|------|--------------|
| **A1: Zero-clone footprint** | Fetches only the target profile tree; does NOT require cloning the full repo |
| **A2: Host-tool detection** | Can auto-detect which host tool is in use (with override flag) |
| **A3: Cross-platform** | Works on both Bash (Linux/macOS/git-bash) and PowerShell (Windows) with the same mechanism |
| **A4: Update path** | Can re-run to update to a newer pinned version cleanly |
| **A5: Uninstall** | Can cleanly remove all AID-installed files |
| **A6: Online/offline** | Supports both online (fetch from remote) and offline (pre-downloaded bundle) modes |
| **A7: Minimal-dependency fit** | Relies only on the baseline toolchain (git/curl/tar or PowerShell equivalents); no heavy runtime |
| **A8: Maintainer upkeep** | Low ongoing cost for the maintainer to publish and maintain new releases |

### Scoring table

| Axis | M1: curl\|bash + irm\|iex | M2: GitHub Release tarball | M3: npx/pipx CLI | M4: gh extension | M5: degit/sparse-checkout |
|------|:---:|:---:|:---:|:---:|:---:|
| **A1: Zero-clone footprint** | 4 | 5 | 5 | 3 | 4 |
| **A2: Host-tool detection** | 4 | 5 | 4 | 3 | 4 |
| **A3: Cross-platform** | 3 | 5 | 2 | 2 | 3 |
| **A4: Update path** | 3 | 5 | 4 | 3 | 3 |
| **A5: Uninstall** | 3 | 5 | 4 | 3 | 3 |
| **A6: Online/offline** | 2 | 5 | 1 | 1 | 2 |
| **A7: Minimal-dependency fit** | 4 | 5 | 1 | 2 | 3 |
| **A8: Maintainer upkeep** | 3 | 3 | 2 | 3 | 4 |
| **Total (max 40)** | **26** | **38** | **23** | **20** | **26** |

---

## Per-Mechanism Trade-off Analysis

### M1 — `curl ... | bash` / `irm ... | iex` one-liner

**Description:** A bootstrap script is hosted at a fixed GitHub Raw URL (e.g.,
`https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh`).
The adopter runs `curl -sSf <url> | bash -s -- --tool claude-code` (or the PowerShell
`irm`/`iex` equivalent). The script itself fetches the profile tree — either by a
`git clone --sparse` or by downloading per-file via the GitHub contents API.

**Pros:**
- Minimal setup: no tooling beyond `curl` (or PowerShell's `Invoke-RestMethod`)
- Familiar UX pattern (Homebrew, Rust's rustup, many Linux package managers use it)
- No release pipeline required if fetching from `master` HEAD

**Cons:**
- Two scripts required (`.sh` + `.ps1`) or one polyglot that handles both platforms;
  achieving true cross-platform parity in a single-step one-liner is hard
- Without version pinning, fetching from `master` HEAD is not reproducible; adopters
  cannot pin to a specific AID version
- Adding version pinning requires a release tagging convention and either: (a) a separate
  bootstrap script per release tag (proliferates scripts), or (b) the bootstrap script
  internally resolves the tag (adds complexity)
- Offline mode is not supported by the one-liner itself; a separate bundle step is needed
- Security concern: `curl | bash` is widely criticized for bypassing signature verification
  (though the risk here is low since the source is the maintainer's own GitHub repo)
- A1 score of 4 (not 5): The bootstrap script must still fetch the tree somehow; if it
  uses the GitHub contents API file-by-file, it is fragile (rate limits, many HTTP calls);
  if it uses sparse-checkout it requires git with sparse-checkout support

**A3 cross-platform gap:** A `curl | bash` one-liner does not work natively on Windows
PowerShell without WSL. The Windows path requires a separate `irm ... | iex` idiom, and
the two scripts must be kept in sync. This is an ongoing maintenance burden.

CONFIRMED from KB: `infrastructure.md` lists `curl` only as a tool for `fetch-mermaid.sh`
outbound; `setup.ps1` uses PowerShell's built-in `Copy-Item` without curl.

---

### M2 — Versioned GitHub Release tarball + tiny bootstrap script (RECOMMENDED)

**Description:** At release time, the maintainer creates a GitHub Release (via `gh release
create`) with five per-profile tarballs (one per tool: `aid-claude-code-v0.1.0.tar.gz`,
`aid-codex-v0.1.0.tar.gz`, etc.) plus a `VERSION` file. A tiny cross-platform bootstrap
pair (`install.sh` + `install.ps1`) is committed to the repo root; the adopter runs:

- **Bash:** `curl -sSf https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash -s -- --tool claude-code [--version 0.1.0]`
- **PowerShell:** `irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex; Install-AID -Tool ClaudeCode [-Version 0.1.0]`

Or, after the first install, re-run with `--update` / `--uninstall`.

The bootstrap script:
1. Resolves the version (default = latest GitHub Release; override with `--version`)
2. Downloads and extracts the corresponding per-profile tarball
3. Applies the same copy logic as the existing `setup.sh` (skip-identical, prompt on diff,
   `--force` to overwrite, Option-A AGENTS.md collision handling)
4. Writes a `.aid-version` (or similar) record file to the target project root

**Offline mode:** Download the tarball manually; run `install.sh --from-bundle path/to/bundle.tar.gz --tool claude-code`. The bootstrap script branches on `--from-bundle` to skip the download and extract from the local path instead.

**Pros:**
- **True zero-clone footprint:** Each tarball contains only the files for ONE profile tree
  (~257 files, ~2 MB) — no canonical/, tests/, or maintainer tooling
- **Version pinning:** Each GitHub Release is immutable; adopters pin with `--version 0.1.0`
- **Reproducible updates:** Re-run with `--update`; the script compares `.aid-version` to
  the latest release and downloads only if changed
- **Uninstall:** A manifest (list of installed files) is written to the target project at
  install time (e.g., `.aid/.aid-manifest.txt`); `--uninstall` reads this manifest and
  removes only those files
- **Full offline support:** Pre-download the tarball; pass `--from-bundle`; no network
  needed at install time
- **Cross-platform with existing toolchain:** Bash uses `curl` + `tar`; PowerShell uses
  `Invoke-WebRequest` + `Expand-Archive` — both are already in the toolchain baseline
  (`infrastructure.md` Toolchain table) or are stdlib PowerShell 5.1+
- **Host-tool auto-detection:** The bootstrap script probes for known host-tool config
  files (`.claude/`, `.cursor/`, `.codex/`, `.github/copilot-instructions.md`, `.agent/`)
  with an `--tool` flag override
- **No new runtime dependency:** Pure Bash + PowerShell; no Python, Node, npm, or pipx
  required
- **Stays in the lite path:** Creating a GitHub Release is a single `gh release create`
  command; no CI/CD release pipeline or package registry is required

**Cons:**
- **Requires establishing a release convention:** The maintainer must run `gh release create`
  and attach the five per-profile tarballs. This is a NEW maintainer step (not done today).
  However, it is a single command, not a new pipeline — see Scope Checkpoint below.
- **Bootstrap script duplication:** Two scripts (.sh and .ps1) must be kept in sync, similar
  to the existing `setup.sh`/`setup.ps1` pair. This is pre-existing upkeep cost, not new.
- **GitHub Releases API dependency for online mode:** The `latest` version resolution requires
  a call to `https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest`.
  This is a standard GitHub API call available without authentication for public repos. The
  rate limit (60 unauthenticated requests/hour) is not a concern for an install script that
  runs once per project. (Note: verify the unauthenticated rate limit applies — general
  knowledge, not confirmed against live docs.)
- **Tarball assembly step:** The release process requires packaging each profile tree. This
  can be scripted as a `release.sh` helper (a one-time authoring cost, not ongoing
  infrastructure) — see Scope Checkpoint.
- **A8 (Maintainer upkeep) score of 3:** Each release requires the maintainer to run the
  release script and create the GitHub Release. This is low-friction but not zero-friction.

CONFIRMED from KB: `infrastructure.md` "The `gh` CLI is the maintainer's primary tool for
PR creation, issue triage, and release operations." The `gh release create` command is
already in the maintainer's standard workflow.

---

### M3 — `npx` / `pipx`-style published CLI

**Description:** Publish `aid-installer` as an npm package (or `aid` as a PyPI package)
and let adopters run `npx aid-installer --tool claude-code` or `pipx run aid`.

**Pros:**
- Familiar pattern for developers; one command with no script download
- Version management handled by the package registry (npm/PyPI)
- Could bundle detection and uninstall logic neatly

**Cons:**
- **Violates the no-third-party-runtime-deps constraint directly:** Requires Node.js (npm)
  or Python's pipx to be installed. Node is listed as optional in AID's runtime requirements
  (`technology-stack.md` "Node 18+ is optional — only `/aid-summarize` uses it"); requiring
  it for the installer would elevate it to mandatory
- **Requires publishing to a package registry:** AID has no existing npm or PyPI presence
  (`infrastructure.md` "no published package on npm, PyPI, Homebrew, Chocolatey, or any
  other package registry"). Setting this up requires: (a) creating and maintaining an npm
  org or PyPI account, (b) a publish step in CI or manual publish workflow, (c) managing
  npm/PyPI access tokens, package naming, versioning policy — all new infrastructure
- **Not truly cross-platform without extra work:** `npx` requires Node installed;
  `pipx` requires Python 3.11+ AND the `pipx` tool itself. Neither is guaranteed on Windows
  without additional setup.
- **Offline mode is not supported:** `npx` always hits npm registry (even `npx --offline`
  requires a prior cache hit); PyPI-based `pipx run` similarly
- **Scope escalation:** This mechanism forces publishing to a package registry — the SPEC
  explicitly calls this out as a potential scope-escalation trigger:
  `infrastructure.md` "the project distributes via... git clone"; there is no release
  pipeline. Selecting M3 would mandate a full-path escalation.

CONFIRMED: M3 is **incompatible** with AID's minimal-dependency stance and would force
package-registry publishing that warrants a full-path escalation.

---

### M4 — `gh` GitHub CLI extension

**Description:** Publish a `gh extension` (e.g., `gh-aid`) that adopters install via
`gh extension install AndreVianna/gh-aid` and then run `gh aid --tool claude-code`.

**Pros:**
- `gh` is already in the maintainer's standard toolkit (`infrastructure.md` Toolchain table)
- Extensions are native to the GitHub ecosystem; clean UX for adopters who already use `gh`
- Extensions can be implemented in Bash, making them cross-platform in theory

**Cons:**
- **Requires `gh` CLI to be installed on the adopter's machine:** `gh` is NOT listed as a
  required tool in AID's runtime requirements (`README.md` "Runtime requirements: one or
  more of the five supported AI tools · Bash or PowerShell 5.1+ · Git · Node 18+
  (optional)"). This adds a hard new dependency for adopters.
- **Not cross-platform for Windows:** `gh` extensions are Bash-based; the Windows path
  requires WSL or git-bash. PowerShell-native Windows users cannot use a `gh` extension
  without additional tooling.
- **`gh extension install` clones the extension repo:** This means the extension repo
  (containing the installer logic) is cloned, but the extension still needs to download the
  AID profile tarball separately — the extension is just a bootstrap wrapper. Zero-clone
  footprint is not achieved for the AID content itself (though the extension repo is
  small if it contains only the installer script). Score is 3 (partial) because the extension
  repo is cloned, but the AID profile tarball download would still require a Release.
- **Offline mode not supported:** `gh extension install` requires network; there is no
  documented offline extension installation path (verify against gh docs).
- **Narrow audience:** Adopters who don't use `gh` (common on Windows) are excluded.
  This effectively restricts AID adoption to users already in the GitHub CLI ecosystem.
- **Maintainer must register and maintain a separate extension repo:** This is a new artifact
  (a `gh-aid` repo separate from `aid-methodology`) that must track the main repo's releases.

CONFIRMED from KB: `gh` is a maintainer tool, NOT listed as an end-user requirement.
Adopting M4 would add a hard `gh` dependency for adopters.

---

### M5 — `degit` / git sparse-checkout

**Description:**
- **`degit` variant:** `npx degit AndreVianna/aid-methodology/profiles/claude-code --tool claude-code` — fetches the HEAD of one profile subtree without the git history
- **`git sparse-checkout` variant:** Clone with `--filter=blob:none --sparse`, then
  `git sparse-checkout set profiles/claude-code` — downloads only the files matching the
  sparse pattern

**Pros:**
- Sparse-checkout is native git (no extra tool)
- `degit` provides a clean no-history clone of a subtree

**Cons (degit):**
- **Requires Node + npx:** Same problem as M3. `degit` is an npm package. Not appropriate.
- **Not actively maintained:** `degit` has had minimal maintenance activity (general
  knowledge — verify against degit GitHub repo status if needed). Relying on it for an
  installer is fragile.

**Cons (git sparse-checkout):**
- **Still clones the repo** (even with `--filter=blob:none`, the `.git/` directory is
  created and object metadata is fetched). The working tree is restricted, but this is
  not a true zero-clone — the adopter ends up with a git repo checkout in a temp dir,
  which they must then copy from. More complex than a tar extract.
- **Version pinning works via tags** (`git clone --branch v0.1.0`) but requires tags to
  be pushed — same prerequisite as M2 Releases
- **Offline mode requires pre-cloning** the repo or mirroring it locally — not as clean
  as a tarball bundle
- **Cross-platform gap:** `git sparse-checkout` syntax varies by git version (the
  `git sparse-checkout` subcommand was added in git 2.25; the `--filter=blob:none` flag
  requires git 2.19+). Older git installs (common on some corporate Windows environments)
  may not have these features. The PowerShell path would need to invoke git, then copy
  extracted files — doable but more complex than M2's `Expand-Archive`.
- **A1 score of 4 (not 5):** Even with sparse-checkout, the adopter's machine downloads
  a git object database, not just the profile files. The git database is compact, but it
  is not equivalent to a single-profile tarball.
- **No clean manifest/uninstall:** Sparse-checkout gives you the files but no install
  manifest. Uninstall requires tracking what was copied manually.

CONFIRMED from KB: `technology-stack.md` lists `Git (unpinned, any modern version)` as a
required tool. Git is available on all platforms. However, sparse-checkout feature
availability depends on the git version, not just presence.

---

## Recommendation

### Recommended mechanism: M2 — Versioned GitHub Release tarball + tiny bootstrap script

**Single recommendation rationale:**

M2 is the only mechanism that scores 5 on every axis except maintainer upkeep (where it
scores 3 — the creation of release tarballs is a new but minimal step). It is the only
mechanism that:

1. **Achieves true zero-clone footprint** by packaging only the chosen profile tree into a
   tarball. An adopter running `install.sh --tool claude-code` downloads exactly
   `aid-claude-code-v0.1.0.tar.gz` (~2 MB) — no canonical/, no tests/, no other profiles.

2. **Stays within the existing toolchain** (Bash + curl + tar on Unix; PowerShell 5.1+ +
   `Invoke-WebRequest` + `Expand-Archive` on Windows). No new dependency is introduced for
   adopters. `curl` and `tar` are already in AID's toolchain baseline
   (`infrastructure.md` Toolchain table); `Invoke-WebRequest` and `Expand-Archive` are
   PowerShell 5.1+ stdlib.

3. **Requires no package registry.** A GitHub Release is a GitHub-native feature available
   to any public repo. It does not require npm, PyPI, or Homebrew accounts. The creation
   command (`gh release create v0.1.0 --title "AID v0.1.0" --notes "..." aid-*.tar.gz`) is
   a single invocation of the `gh` CLI that is already in the maintainer's toolkit.

4. **Delivers version pinning and update naturally.** The GitHub Releases API's `/latest`
   endpoint gives the current release; `--version 0.1.0` pins to a specific immutable tag.
   Update is a re-run with no extra steps beyond what install already does.

5. **Supports offline mode cleanly.** The bootstrap script accepts `--from-bundle
   /path/to/aid-claude-code-v0.1.0.tar.gz`; it branches entirely on this flag and skips
   all network calls.

No other mechanism achieves all five of these properties simultaneously within AID's
actual constraints.

---

### Design sketch for the recommended mechanism

#### Online mode — install or update

**Bash (Linux / macOS / git-bash on Windows):**

```
curl -sSf https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh \
  | bash -s -- --tool claude-code [--version 0.1.0] [--force] [TARGET_DIR]
```

Or, if the bootstrap is already present in the adopter's project:

```
bash install.sh --tool claude-code [--version 0.1.0] [--force] [TARGET_DIR]
```

**PowerShell (Windows):**

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 `
  | Invoke-Expression
Install-AID -Tool ClaudeCode [-Version 0.1.0] [-Force] [-TargetDirectory .]
```

Or, with a local bootstrap:

```powershell
.\install.ps1 -Tool ClaudeCode [-Version 0.1.0] [-Force] [-TargetDirectory .]
```

**Install flow:**

1. Resolve version: if `--version` not given, call GitHub Releases API
   (`https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest`) to get
   `tag_name`. (General knowledge: this API endpoint is available unauthenticated for public
   repos at 60 req/hour; verify rate-limit behavior in edge cases.)
2. Download tarball from the GitHub Release asset URL:
   `https://github.com/AndreVianna/aid-methodology/releases/download/v{VERSION}/aid-{tool}-v{VERSION}.tar.gz`
3. Extract into a temp dir.
4. Apply the same copy semantics as the existing `setup.sh`: skip identical files, prompt
   on diff (or `--force` overwrite), Option-A AGENTS.md collision handling for multi-tool.
5. Write an install manifest to `{TARGET}/.aid/.aid-manifest` (a text file listing every
   installed file path, one per line, plus the installed version).
6. Print "Installed AID v{VERSION} for {tool} into {TARGET}".

#### Offline mode — from pre-downloaded bundle

```bash
bash install.sh --from-bundle /path/to/aid-claude-code-v0.1.0.tar.gz --tool claude-code [TARGET_DIR]
```

The `--from-bundle` flag causes the script to:
- Skip all network calls
- Extract the provided tarball directly
- Apply the same copy + manifest steps as the online path

The adopter pre-downloads the tarball by visiting the GitHub Release page or running:

```bash
curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/v0.1.0/aid-claude-code-v0.1.0.tar.gz
```

#### Host-tool auto-detection

The bootstrap script probes for known host-tool indicators in `TARGET_DIR` (default: current
directory):

| Signal file/dir | Detected tool |
|----------------|---------------|
| `.claude/` directory | claude-code |
| `.cursor/` directory | cursor |
| `.codex/` directory | codex |
| `.github/copilot-instructions.md` (verify naming) | copilot-cli |
| `.agent/` directory | antigravity |

If exactly one indicator is found, it is used without prompting. If zero or multiple are
found, and `--tool` is not given, the script falls back to the interactive menu (same
as the existing `setup.sh` menu). The `--tool` flag always overrides detection.

#### Version pinning + update

- Install writes the installed version to `{TARGET}/.aid/.aid-manifest` header line, e.g.,
  `# AID version: 0.1.0 tool: claude-code`
- Running `install.sh --update` reads the manifest, fetches the latest release version,
  and re-runs the install flow if the versions differ.
- Running `install.sh --update --version 0.2.0` pins to a specific version.

#### Uninstall

```bash
bash install.sh --uninstall [TARGET_DIR]
```

Reads the manifest (`{TARGET}/.aid/.aid-manifest`), removes only the listed files (leaving
any file NOT in the manifest untouched), then removes the manifest itself. Prints a
confirmation list.

#### Tarball packaging (maintainer step)

A helper script `release.sh` (committed to the repo root) is run by the maintainer at
release time:

```bash
bash release.sh v0.1.0
```

It:
1. Runs `python run_generator.py` to ensure profiles/ is up to date.
2. Packages each of the five profile trees into `aid-{tool}-v{VERSION}.tar.gz` files.
3. Runs `gh release create v{VERSION} --title "AID v{VERSION}" --notes-file CHANGELOG.md aid-*.tar.gz`.

This is a single command, not a new CI/CD pipeline. It is added to the maintainer
workflow but does not change the CI `test.yml` job. (The SPEC allows the lite plan to
hold if the release mechanism does not require a new build/CI pipeline.)

---

## Scope Checkpoint (SPEC Re-plan checkpoint)

**Verdict: LITE PLAN HOLDS.**

The recommended mechanism (M2 — GitHub Release tarball + tiny bootstrap) does NOT force:
- Package registry publishing (no npm, PyPI, Homebrew, or Chocolatey account required)
- A new release/build pipeline in CI (no new GitHub Actions workflow required; the release
  is created manually via `gh release create` by the maintainer, consistent with existing
  use of `gh` as the maintainer's primary PR/release tool per `infrastructure.md`)
- Any new runtime dependency for adopters (curl/tar on Bash; PowerShell stdlib on Windows)

The new elements introduced are:
1. A `release.sh` helper script (authored once, run by the maintainer at release time)
2. Two bootstrap scripts (`install.sh` + `install.ps1`) that replace/extend `setup.sh`/`setup.ps1`
3. A new GitHub Release per version (a `gh release create` command)

All three are consistent with the lite 4-task plan:
- task-001 (RESEARCH): this document — DONE
- task-002 (IMPLEMENT): author `install.sh`, `install.ps1`, and `release.sh`; define the
  manifest format
- task-003 (TEST): test the new installer pair (happy path, --from-bundle, --uninstall,
  detection logic)
- task-004 (DOCUMENT): update README install section; document update/uninstall flow

No escalation to the full path is warranted.

**Condition for re-evaluation:** If the maintainer later decides to automate the release
creation in GitHub Actions (e.g., trigger on a version tag push), that would add a new
CI workflow — but that addition is optional and post-scope. The lite plan is for a
manually-triggered release via `gh release create`, which requires no new pipeline.

---

## Summary of Evidence Sources

| Claim | Evidence |
|-------|---------|
| No existing release pipeline | `infrastructure.md` "There is also no release pipeline" |
| No package registry presence | `infrastructure.md` "There is no published package on npm, PyPI, Homebrew, Chocolatey, or any other package registry" |
| Toolchain baseline: curl, Bash 4+, PowerShell 5.1+ | `technology-stack.md` Runtime table; `infrastructure.md` Toolchain table |
| Profile trees are pre-rendered and committed | `infrastructure.md` Build Pipeline; confirmed by `ls profiles/claude-code/` — `.claude/`, `CLAUDE.md`, `emission-manifest.jsonl` are committed |
| Profile tree size: ~257 files, ~2 MB per profile | Direct filesystem measurement (`find profiles/claude-code -type f | wc -l` = 257; `du -sh profiles/claude-code` = 2.0M) |
| `gh` CLI is in the maintainer's toolkit | `infrastructure.md` Toolchain table: "GitHub CLI (gh) — PR/issue/release operations" |
| Current install requires full repo clone | `README.md` `## Install`: `git clone https://github.com/AndreVianna/aid-methodology.git` |
| VERSION file exists at repo root | Confirmed: `VERSION` contains `0.1.0-dev` |
| Interactive menu: 5 tools + Done | `setup.sh` `print_menu()` function, confirmed by direct read |
| `--force` flag supported by existing setup | `setup.sh` line 15: `if [[ "${2:-}" == "--force" ]]; then FORCE=1; fi` |
| Option-A AGENTS.md collision handler exists | `setup.sh` lines 143-165: `AGENTS_COLLISION` variable + collision warning + last-writer-wins logic |
| No Node or Python required for install today | `setup.sh` is pure Bash; `setup.ps1` is pure PowerShell; confirmed no Python/Node calls in either file |
| General knowledge flagged (unverified claims) | GitHub Releases API unauthenticated rate limit (60 req/hr); `degit` maintenance status; sparse-checkout git version requirements. These should be verified against live docs before implementation. |
