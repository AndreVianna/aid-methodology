# AID Install / Update / Remove Guide

Complete reference for the `aid` CLI: bootstrap, per-project subcommands, what gets
installed per tool, offline install, and uninstall — across Linux, macOS, and Windows.

---

## Contents

- [How it works (two steps)](#how-it-works-two-steps)
- [Install channels](#install-channels)
- [Step 1 — Bootstrap the `aid` CLI (once per machine)](#step-1--bootstrap-the-aid-cli-once-per-machine)
- [Step 2 — Use `aid` per project](#step-2--use-aid-per-project)
- [One-line first install (bootstrap + add in one command)](#one-line-first-install-bootstrap--add-in-one-command)
- [Offline / air-gapped install](#offline--air-gapped-install)
- [What gets installed per tool](#what-gets-installed-per-tool)
- [Removing AID](#removing-aid)
- [Update check](#update-check)
- [Trust model and checksum verification](#trust-model-and-checksum-verification)
- [Protect-on-diff for root agent files](#protect-on-diff-for-root-agent-files)
- [Version recording and the manifest](#version-recording-and-the-manifest)
- [GitHub API rate limits and authentication](#github-api-rate-limits-and-authentication)
- [Reference](#reference)

---

## How it works (two steps)

AID separates into two install layers:

1. **The `aid` CLI** — a persistent, global command installed once per machine into
   `~/.aid` (Unix) or `%LOCALAPPDATA%\aid` (Windows). It never changes when you add or
   remove AID from a project. Bootstrap it once with the one-liners below.

2. **Per-project AID files** — the profile trees (`.claude/`, `.codex/`, `CLAUDE.md`,
   `AGENTS.md`, etc.) that `aid add <tool>` installs into a repo. Each repo tracks what
   was installed in its own `.aid/.aid-manifest.json`.

---

## Install channels

All channels deliver the same `aid` CLI (same `aid add / status / update / remove`). The
difference is only how `aid` lands on your PATH.

| Channel | Requires | Status |
|---------|----------|--------|
| `curl` / `irm` bootstrap (online) | Bash or PowerShell 5.1+ | Available — see [Step 1](#step-1--bootstrap-the-aid-cli-once-per-machine) |
| `--from-bundle` (offline / air-gapped) | Bash or PowerShell 5.1+ | Available — see [Offline install](#offline--air-gapped-install) |
| npm: `npm i -g aid-installer` | Node >=18 | Published / live — see [npm channel](#npm-channel) |
| PyPI: `pipx install aid-installer` | Python >=3.8 | Published / live — see [PyPI channel](#pypi-channel) |

---

### npm channel

Requires Node >=18.

**Global install** — puts `aid` on PATH permanently:

```bash
npm i -g aid-installer      # short form
# or: npm install -g aid-installer
aid add claude-code
```

**Without a global install** — invoke once with `npx`:

```bash
npx aid-installer add claude-code
```

`npx` downloads and runs the package without adding it to PATH. Useful for one-off installs
or CI.

After either form, usage is identical:

```bash
aid add <tool>          # install a tool profile into the current project
aid status              # show installed tools
aid update [<tool>]     # update a tool (or all tools)
aid remove [<tool>]     # remove a tool (or all AID from the project)
```

**Updating the `aid` CLI itself (npm channel):**

```bash
npm install -g aid-installer@latest
```

Or via `aid`:

```bash
aid update self
# Prints: npm install -g aid-installer@latest
```

The CLI detects the npm channel (`AID_INSTALL_CHANNEL=npm`) and prints the correct
command automatically.

---

### PyPI channel

Requires Python >=3.8.

**pipx (recommended)** — installs `aid` into an isolated environment and puts it on PATH:

```bash
pipx install aid-installer
aid add claude-code
```

**pip** — use `--user` to avoid system-level writes:

```bash
pip install --user aid-installer
aid add claude-code
```

`pipx` is preferred because it isolates the install and avoids dependency conflicts. Use
`pip --user` only if `pipx` is unavailable.

After either form, usage is identical — same `aid add / status / update / remove`.

**Updating the `aid` CLI itself (PyPI channel):**

With pipx:

```bash
pipx upgrade aid-installer
```

Or via `aid`:

```bash
aid update self
# Prints: pipx upgrade aid-installer
```

The CLI detects the PyPI channel (`AID_INSTALL_CHANNEL=pypi`) and prints the correct
command automatically.

---

### Multiple channels on PATH

If `aid` is installed via more than one channel (for example, both via `curl` bootstrap
and via npm), PATH order determines which one runs. Pick one channel per machine and
remove the others to avoid confusion.

To check which `aid` is active:

```bash
which aid      # Linux / macOS
where aid      # Windows (cmd)
Get-Command aid | Select-Object Source   # Windows (PowerShell)
```

---

## Step 1 — Bootstrap the `aid` CLI (once per machine)

Run this once. The bootstrap installs the `aid` command and wires it onto your PATH. You
do not need to be inside a project directory.

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash
```

- Installs to `~/.aid/` (override with `$AID_HOME`).
- Adds `~/.aid/bin` to your PATH via `~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`
  depending on your shell.
- Pass `--no-path` to skip the profile edit and wire PATH yourself.

### Windows (PowerShell 5.1+)

```powershell
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex
```

- Installs to `%LOCALAPPDATA%\aid\` (override with `$env:AID_HOME`).
- Adds `%LOCALAPPDATA%\aid` to your **User** PATH (no admin required).
- Pass `-NoPath` to skip the PATH edit:
  ```powershell
  $env:AID_NO_PATH = '1'; irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex
  ```

> **After bootstrap, open a new shell** (or source your profile) to pick up the
> updated PATH. The `aid` command is then available everywhere.

### Pinned-version bootstrap (recommended for teams and CI)

```bash
# Linux / macOS  (replace X.Y.Z with the version to pin; omit --version entirely for the latest)
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash -s -- --version X.Y.Z
```

```powershell
# Windows  (set the version to pin; omit AID_VERSION for the latest)
$env:AID_VERSION = 'X.Y.Z'
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex
```

Pinning ensures every machine bootstraps the same CLI version.

---

## Step 2 — Use `aid` per project

After bootstrap, `cd` into the project repo where you want AID and use subcommands
directly. No re-downloading. No re-piping.

### Check what is installed

```bash
aid status
```

```
AID 1.1.0  (project: /path/to/your/project)
Installed tools:
  claude-code   v1.1.0   root: CLAUDE.md (owned)
```

Bare `aid` (no subcommand) shows a text status screen: the installed CLI version, the project
status, the full command list, and any pending update notice. Exit 7 when no AID install
is found in the current directory. For the browser-based web dashboard, use `aid dashboard start node` or `aid dashboard start python`.

### Install a tool into this project

```bash
aid add claude-code
```

Canonical tool ids: `claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`.

Install multiple tools at once:

```bash
aid add codex,cursor
```

Pin to a specific version:

```bash
aid add claude-code --version 1.1.0
```

Without `--version` the installer resolves the latest GitHub Release
(see [GitHub API rate limits](#github-api-rate-limits-and-authentication)).

### Update installed tools

```bash
# Update all installed tools to latest
aid update

# Update a specific tool
aid update claude-code

# Update to a pinned version
aid update --version 0.8.0
```

### Update the aid CLI itself

```bash
aid update self
```

The command is channel-aware: it detects how `aid` was installed and prints the right
upgrade instruction.

| Install channel | What `aid update self` does |
|----------------|------------------------------|
| `curl` / `irm` bootstrap | Re-runs the bootstrap script to fetch and install the latest CLI |
| npm | Prints: `npm install -g aid-installer@latest` |
| PyPI / pipx | Prints: `pipx upgrade aid-installer` |

### Remove a specific tool

```bash
aid remove codex
```

### Remove AID entirely from this project

```bash
aid remove
```

Removes all AID-installed files (manifest-driven — only what `aid add` wrote). Your own
edits to `CLAUDE.md`/`AGENTS.md` are left in place (see
[Protect-on-diff](#protect-on-diff-for-root-agent-files)).

`aid remove` (no tool argument) prompts for confirmation before proceeding. The prompt is
bypassed automatically when `--force` is given or when running non-interactively (CI /
piped stdin).

### Print the CLI version

```bash
aid version
```

This prints the version of the global `aid` CLI itself (from `~/.aid/VERSION`), not the
version of tools installed in the current project (those are in the manifest).

### Per-command help

```bash
aid <command> -h
# e.g.:
aid add -h
aid remove -h
aid update -h
aid status -h
```

---

## One-line first install (bootstrap + add in one command)

If you want to bootstrap the CLI **and** add a tool to the current project in a single
command:

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash -s -- add claude-code
```

The bootstrap installs `aid`, then immediately runs `aid add claude-code` in the current
directory. No need to open a new shell first — the bootstrapped `bin/aid` is invoked
directly.

### Windows

Because `irm … | iex` cannot forward arguments, use the `AID_TOOL` environment variable:

```powershell
$env:AID_TOOL = 'claude-code'
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex
```

This bootstraps the CLI and then runs `aid add claude-code` in the current directory.

---

## Offline / air-gapped install

Download the tarball and optional checksum file from the
[GitHub Releases page](https://github.com/AndreVianna/aid-methodology/releases), then
use `aid add --from-bundle` — no network required.

### Download and verify

```bash
# Resolve the latest release tag (or set VERSION manually from the Releases page)
VERSION="$(curl -fsSL https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')"
# Download (example: claude-code)
curl -LO "https://github.com/AndreVianna/aid-methodology/releases/download/v${VERSION}/aid-claude-code-v${VERSION}.tar.gz"
curl -LO "https://github.com/AndreVianna/aid-methodology/releases/download/v${VERSION}/SHA256SUMS"

# Verify (Linux)
sha256sum --check --ignore-missing SHA256SUMS

# Verify (macOS)
shasum -a 256 -c SHA256SUMS
```

```powershell
# Verify (Windows)
$expected = (Get-Content SHA256SUMS | Where-Object { $_ -match 'aid-claude-code' }) -split '\s+' | Select-Object -First 1
$actual   = (Get-FileHash .\aid-claude-code-v1.1.0.tar.gz -Algorithm SHA256).Hash.ToLower()
if ($expected -ne $actual) { Write-Error "Checksum mismatch"; exit 4 }
```

### Install offline

```bash
# After bootstrapping the CLI (see Step 1)
aid add claude-code --from-bundle aid-claude-code-v1.1.0.tar.gz
```

For multiple tools, pass a directory containing the per-tool tarballs
(`aid-<tool>-v<version>.tar.gz` naming):

```bash
aid add codex,cursor --from-bundle ./bundles/
```

`--from-bundle` and `--version` are mutually exclusive.

---

## What gets installed per tool

`aid add <tool>` copies the AID profile for one tool into the current project directory.
The files written depend on the tool.

### Claude Code

Installs into `.claude/`:

- `.claude/aid/scripts/` — helper scripts (phase-specific, e.g. interview, summarize)
- `.claude/aid/templates/` — KB document templates, task templates, and the shortcut system (`shortcut-catalog.yml`, `shortcut-engine.md`, `shortcut-scaffolding/`)
- `.claude/skills/` — 82 `aid-`-prefixed skill markdown files (14 classic pipeline / on-demand skills + `aid-triage` + 67 Lite-Path shortcut skills)
- `.claude/agents/` — 9 `aid-`-prefixed agent markdown files
- `CLAUDE.md` — project-context file at the project root (AID content fenced by `<!-- AID:BEGIN -->`/`<!-- AID:END -->`)

### Codex CLI

Installs into `.codex/`:

- `.codex/agents/` — agent TOML files (`aid-`-prefixed)
- `.codex/skills/` — `aid-`-prefixed skill markdown files
- `.codex/aid/scripts/`, `.codex/aid/templates/` — AID-own support files
- `AGENTS.md` — project-context file at the project root (AID content fenced by `<!-- AID:BEGIN -->`/`<!-- AID:END -->`)

### Cursor

Installs into `.cursor/`:

- `.cursor/skills/` — `aid-`-prefixed skill markdown files
- `.cursor/agents/` — `aid-`-prefixed agent markdown files
- `.cursor/aid/scripts/`, `.cursor/aid/templates/` — AID-own support files
- `AGENTS.md` — project-context file at the project root (AID content fenced by `<!-- AID:BEGIN -->`/`<!-- AID:END -->`)

### GitHub Copilot CLI

Installs into `.github/`:

- `.github/agents/` — `aid-`-prefixed agent markdown files
- `.github/skills/` — `aid-`-prefixed skill markdown files
- `.github/aid/scripts/`, `.github/aid/templates/` — AID-own support files
- `AGENTS.md` — project-context file at the project root (AID content fenced by `<!-- AID:BEGIN -->`/`<!-- AID:END -->`)

### Antigravity

Installs into `.agent/`:

- `.agent/agents/` — `aid-`-prefixed agent markdown files
- `.agent/skills/` — `aid-`-prefixed skill markdown files
- `.agent/aid/scripts/`, `.agent/aid/templates/` — AID-own support files
- `AGENTS.md` — project-context file at the project root (AID content fenced by `<!-- AID:BEGIN -->`/`<!-- AID:END -->`)

### Notes

All five profiles contain byte-identical skill and agent bodies — only the wrapper format
differs per tool. The source of truth is `canonical/`; `profiles/` are generated output.

**Content isolation:** AID's own support folders (`scripts/`, `templates/`)
nest under an `aid/` subtree inside each profile's assets root. AID files in tool-native
directories (`agents/`, `skills/`) all carry the `aid-` prefix. Your files in
those same directories are never touched. AID's section in root agent files (`CLAUDE.md`/
`AGENTS.md`) is fenced by `<!-- AID:BEGIN -->`/`<!-- AID:END -->` markers and updated
in place, preserving your content outside the fence.

`.aid/` is appended to your `.gitignore` by default (the Knowledge Base stays out of git;
remove the entry if you want to commit it).

---

## Removing AID

### Remove a specific tool from a project

```bash
aid remove claude-code
```

### Remove all AID from a project

```bash
aid remove
```

Prompts for confirmation. Pass `--force` to skip the prompt, or run non-interactively
(CI / piped stdin) and the prompt is bypassed automatically.

Uninstall is manifest-driven: only files that `aid add` wrote are removed. Files you
created or modified yourself are left in place.

### Remove the global `aid` CLI itself

```bash
aid remove self
```

Prompts for confirmation before removing `~/.aid` (or `%LOCALAPPDATA%\aid`) and the
PATH-wiring block. It does **not** touch per-project AID installs — run `aid remove`
inside each project first if you want to clean those up too.

The prompt is bypassed by `--force` or when running non-interactively.

If `aid` is not on your PATH (for example, because PATH wiring failed during bootstrap),
use the bootstrap scripts directly:

```bash
# Linux / macOS
bash install.sh --uninstall-cli
```

```powershell
# Windows
.\install.ps1 -UninstallCli
```

---

## Update check

When `aid` runs (bare `aid`, `aid status`, and other subcommands), it checks whether a
newer CLI version has been published and prints a one-line notice if so:

```
⬆ A newer aid CLI is available: v0.7.2 (you have v0.7.1). Run: aid update self
```

- The check is **throttled**: at most once per 24 hours per machine.
- The result is **cached** at `~/.aid/.update-check` between checks.
- The check is **fail-silent**: network errors, JSON parse failures, or an absent `curl`
  are swallowed — the check never blocks or errors a command.
- **Opt out** permanently by setting `AID_NO_UPDATE_CHECK=1` in your environment.

---

## Trust model and checksum verification

When running the bootstrap via `curl | bash` or `irm | iex`:

1. **The shared install-core library is pinned to an immutable release tag.** When
   `--version` is given, that exact tag is used. Otherwise the latest release is resolved
   first, then the lib is fetched from that tag (never from the mutable bootstrap branch).

2. **The library's checksum is verified before use — fail-closed.** The bootstrap fetches
   `SHA256SUMS` from the same release tag and verifies the library's SHA-256 before
   sourcing or importing it:
   - Checksum mismatch → abort, exit 4.
   - `SHA256SUMS` cannot be fetched (404, network error) → abort, exit 3; the library is
     **not** sourced.
   - Entry missing from `SHA256SUMS` → abort, exit 3; the library is **not** sourced.
   - Only a successful fetch **and** matching hash allows the install to proceed.

3. **`--from-bundle` is the strongest path.** No network is used; you verify the tarball
   yourself. Recommended for air-gapped or security-sensitive environments.

The only way to bypass verification is `AID_INSECURE_SKIP_LIB_VERIFY=1` — a deliberate
override intended for restricted test environments only. Do not set it in production.

For online `--from-bundle` (offline) installs: if a `SHA256SUMS` file is present beside
the bundle in the same directory, the installer verifies automatically. A mismatch
aborts with exit 4. If no `SHA256SUMS` is present, a warning is emitted and the install
continues (you supplied the tarball yourself).

---

## Protect-on-diff for root agent files

Root agent files — `CLAUDE.md` (claude-code) and `AGENTS.md` (codex, cursor, copilot-cli,
antigravity) — sit at your project root and may contain your own customizations. `aid add`
protects them from silent overwrites.

### How it works

When `aid add` (or `aid update`) writes a root agent file `F`:

1. `F` does not exist → installer writes it, records ownership in the manifest.
2. `F` exists and is byte-identical to the incoming version → no-op; `Up to date: F`.
3. `F` exists and the manifest shows AID wrote the current version → AID owns it;
   installer updates it in place.
4. `F` exists, differs from the incoming version, and is not recorded as AID-owned in
   the manifest → **someone else owns it**:
   - **Without `--force`:** installer does NOT overwrite. It writes the incoming version
     beside it as `F.aid-new` (e.g. `AGENTS.md.aid-new`) and exits 5 so CI pipelines
     notice:
     > `AGENTS.md exists and was not written by AID; wrote incoming version to AGENTS.md.aid-new — review and merge, or re-run with --force to overwrite`
   - **With `--force`:** installer overwrites `F` and takes ownership.

### Resolving an `*.aid-new` file

```bash
# Review the diff
diff AGENTS.md AGENTS.md.aid-new

# Option A: keep your version, discard the incoming
rm AGENTS.md.aid-new

# Option B: accept the incoming version
mv AGENTS.md.aid-new AGENTS.md
aid add <tool> --force    # re-run so AID records ownership

# Option C: merge manually, then let AID record ownership
# (edit AGENTS.md to merge, then:)
aid add <tool> --force
```

### Uninstall safety

On `aid remove`, a root agent file is only removed if it still matches the checksum AID
recorded at install time. If you have edited it since, the file is left in place:
`Left in place (modified or not AID-owned): AGENTS.md`.

### Pre-FR12 multi-tool note

Installing a second `AGENTS.md`-writing tool (e.g. `codex` then `cursor`) triggers
protect-on-diff because each tool's `AGENTS.md` currently differs by one line (the profile
path). You will see `AGENTS.md.aid-new` created and exit 5. This is correct behavior —
it prevents silent overwrites. Use `--force` to accept the second tool's version if that
is your intent. This normalizes in delivery-005 (feature-006), which makes all `AGENTS.md`
files byte-identical.

---

## Version recording and the manifest

After every `aid add` or `aid update`, AID records what it installed at
`.aid/.aid-manifest.json` in the target repo. This manifest drives `aid update`,
`aid remove` — do not delete it.

### Manifest location

`.aid/.aid-manifest.json` — one JSON file per repo, shared across all tools installed
into that repo. A human-readable convenience file is also written: `.aid/.aid-version`
(one line: the installed version string).

### Manifest structure (abbreviated)

```json
{
  "manifest_version": 1,
  "aid_version": "1.1.0",
  "installed_at": "2026-06-04T12:00:00Z",
  "tools": {
    "claude-code": {
      "version": "1.1.0",
      "installed_at": "2026-06-04T12:00:00Z",
      "paths": [".claude/skills/...", "CLAUDE.md"],
      "root_agent_files": [
        { "path": "CLAUDE.md", "sha256": "<hex>", "status": "owned" }
      ]
    }
  }
}
```

- `tools.<id>.paths` — every file AID installed for that tool (relative, POSIX
  separators). Uninstall removes exactly these.
- `tools.<id>.root_agent_files[].sha256` — checksum AID recorded when it wrote the root
  agent file. Used for ownership decisions on update and uninstall.
- `status: "owned"` — AID owns this file. `status: "pending-merge"` — protect-on-diff
  fired; a `.aid-new` sibling exists.

The manifest file itself is not listed in `paths`. The `.aid/` directory is not removed
on uninstall — only the manifest and version files are removed, since `.aid/` may also
contain your Knowledge Base and work-area files.

---

## GitHub API rate limits and authentication

Online installs without `--version` resolve the latest release via the GitHub API.
Unauthenticated requests are rate-limited (~60/hour per IP). Shared NAT environments
(CI, corporate networks) can exhaust this quickly.

Mitigations, in order of preference:

1. **Pin `--version`** (best for CI): skips the API call entirely.
2. **Set `$GITHUB_TOKEN` or `$GH_TOKEN`**: sent as a bearer token, raising the limit to
   ~5,000/hour.
3. **Use `--from-bundle`**: no API call at all.

```bash
# With a token (Linux / macOS)
GITHUB_TOKEN=ghp_... aid add claude-code
```

```powershell
# With a token (Windows)
$env:GITHUB_TOKEN = 'ghp_...'
aid add claude-code
```

---

## Reference

### Command surface

```
aid                              Show the dashboard (status + help + update notice)
aid -h | --help                  Show help
aid version                      Print the CLI version
aid status                       Show AID state of the current project
aid add <tool>[,...]             Add tool(s): claude-code, codex, cursor, copilot-cli, antigravity
aid update [<tool>... | self]    Update to latest; no arg = all installed tools; 'self' = the aid CLI
aid remove [<tool>... | self]    Remove; no arg = ALL AID from the project (asks to confirm); 'self' = the aid CLI (asks to confirm)
aid dashboard start node|python [--port N] [--remote]
                                 Start the local web dashboard (pipeline status, KB freshness, task drill-down); --remote exposes the machine-level dashboard over your private tailnet
aid dashboard stop               Stop the running dashboard (and any tailnet exposure)
aid projects [list|add|remove]   Manage the projects this AID install tracks; list shows state, tools, tier, and current-directory marker
aid <command> -h | --help        Per-command help
```

### Flags

PowerShell flags use the same words; the `-` prefix is accepted alongside `--`:
`-Force`, `-Verbose`, `-Version <v>`, `-FromBundle <path>`, `-Target <dir>`.

| Flag | Applies to | Default | Description |
|------|-----------|---------|-------------|
| `--version <v>` | `add`, `update` | latest release | Pin to a release version (`1.1.0` or `v1.1.0`). Mutually exclusive with `--from-bundle`. |
| `--from-bundle <path>` | `add`, `update` | — | Offline install from a tarball (single tool) or a directory of tarballs. No network required. |
| `--force` | `add`, `update`, `remove` | off | Overwrite differing files and skip confirmation prompts. |
| `--verbose` | all | off | Print per-file `Copied:` / `Up to date:` / `Updated:` / `Removed:` lines. Default: concise summary. |
| `--target <dir>` | all | `.` (cwd) | Project root. Must exist; a missing target is a usage error (exit 2). |
| `--no-path` | bootstrap, `update self` | off | Skip automatic PATH wiring. |

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success. Install/update/remove completed. "Nothing to do" is success. |
| `1` | Generic runtime failure (extract failed, write failed). |
| `2` | Usage error: unknown subcommand, bad argument, ambiguous tool, undetectable tool, missing target directory, `--from-bundle` + `--version` together. |
| `3` | Network / fetch failure: download or latest-release resolution failed and no `--from-bundle`. |
| `4` | Checksum mismatch: SHA-256 of downloaded file did not match `SHA256SUMS`. |
| `5` | Protect-on-diff: at least one root agent file was blocked. Other files were installed successfully. Review the `.aid-new` file and merge manually, or re-run with `--force`. |
| `6` | No manifest: `remove` or `update` found no `.aid-manifest.json` (nothing installed — idempotent). |
| `7` | `aid status` / bare `aid`: no AID install found in the current directory. |

### Environment variables

**User-facing** — set these to control `aid` behavior without passing flags:

| Variable | Equivalent flag / effect |
|----------|--------------------------|
| `AID_TOOL` | Positional tool argument for `add` / `remove` / `update`. Also used by the bootstrap convenience-chain (`AID_TOOL=claude-code irm … \| iex`). |
| `AID_VERSION` | `--version` |
| `AID_TARGET` | `--target` |
| `AID_FORCE` | `--force` — set to `1` or `true`. |
| `AID_VERBOSE` | `--verbose` — set to `1`. |
| `AID_NO_UPDATE_CHECK` | Set to `1` to permanently disable the automatic update-available notice. |
| `AID_HOME` | Override the global CLI install directory (default: `~/.aid` on Unix, `%LOCALAPPDATA%\aid` on Windows). |
| `AID_NO_PATH` | Set to `1` to skip PATH wiring during bootstrap or `update self`. |

**Advanced / test hooks** — override internal URLs and paths; not intended for normal use:

| Variable | Effect |
|----------|--------|
| `AID_LIB_PATH` | Absolute path to a local `aid-install-core.sh` — bypasses remote fetch. |
| `AID_LIB_BASE` | Base URL for remote lib fetch (default: GitHub release download base). |
| `AID_SUMS_URL` | Override URL for the `SHA256SUMS` verification file. |
| `AID_LIB_VERSION` | Pin the remote lib fetch to a specific release version. |
| `AID_INSECURE_SKIP_LIB_VERIFY` | Set to `1` to bypass lib checksum verification. **INSECURE** — test environments only; never in production. |
| `AID_CLI_BUNDLE_URL` | Direct URL for the CLI bundle tarball (bypasses computed URL). |
| `AID_CLI_BUNDLE_BASE` | Base URL for CLI bundle fetch (default: release download base). |
| `AID_UPDATE_CHECK_URL` | Override the GitHub API URL used for the update check (also bypasses the 24h throttle — useful in tests). |
| `AID_INSTALL_URL` | Override the bootstrap `install.sh` URL used by `aid update self`. |

### Canonical tool ids

| Tool id | Installs into | Root agent file |
|---------|--------------|-----------------|
| `claude-code` | `.claude/` | `CLAUDE.md` |
| `codex` | `.codex/` | `AGENTS.md` |
| `cursor` | `.cursor/` | `AGENTS.md` |
| `copilot-cli` | `.github/` | `AGENTS.md` |
| `antigravity` | `.agent/` | `AGENTS.md` |

Tool ids are accepted case-insensitively. On Windows, PascalCase aliases are also
accepted: `ClaudeCode`, `Codex`, `Cursor`, `CopilotCli`, `Antigravity`.

### Tool auto-detect

When `aid add` is run without a tool name, the CLI probes the current directory for
per-tool markers:

| Marker present in target | Detected tool |
|--------------------------|---------------|
| `.claude/` dir | `claude-code` |
| `.codex/` dir | `codex` |
| `.cursor/` dir | `cursor` |
| `.github/` with AID-specific children (`agents/` or `skills/`) | `copilot-cli` |
| `.agent/` dir | `antigravity` |

A plain `.github/` directory (without the AID copilot subtree) does **not** trigger
`copilot-cli` detection.

- Exactly one marker found → that tool is used.
- Zero markers found → error, exit 2: `cannot auto-detect host tool; pass tool name as argument`.
- More than one marker found → error, exit 2: `ambiguous host tool (found: X, Y)`.

### Bootstrap scripts (fallback / back-compat)

`install.sh` and `install.ps1` retain the legacy direct-install flag style for **one
release** as a back-compat path. Prefer `aid add` / `aid remove` / `aid update` for new
workflows.

```bash
# Linux / macOS (legacy back-compat — retained one release)
bash install.sh --tool <name>[,...] [--version <v>] [--from-bundle <path>]
                [--force] [--verbose] [--target <dir>]
bash install.sh --update   [--tool ...] [--version <v>] ...
bash install.sh --uninstall [--tool ...] ...
bash install.sh --uninstall-cli [--force]
```

```powershell
# Windows (legacy back-compat — retained one release)
.\install.ps1 -Tool <name>[,...] [-Version <v>] [-FromBundle <path>]
              [-Force] [-Verbose] [-TargetDirectory <dir>]
.\install.ps1 -Update   [-Tool ...] [-Version <v>] ...
.\install.ps1 -Uninstall [-Tool ...] ...
.\install.ps1 -UninstallCli [-Force]
```

### Bootstrap `--no-path` / `-NoPath`

Skips the automatic PATH edit during the bootstrap step. The `aid` binary is still
installed; you wire PATH yourself.

```bash
curl -fsSL .../install.sh | bash -s -- --no-path
```

```powershell
$env:AID_NO_PATH = '1'
irm .../install.ps1 | iex
```

---

## Channels

| Channel | Requires | Status | Command |
|---------|----------|--------|---------|
| `curl … \| bash` (online, Linux / macOS / git-bash) | Bash | Available | See [Step 1](#step-1--bootstrap-the-aid-cli-once-per-machine) |
| `irm … \| iex` (online, Windows PowerShell) | PowerShell 5.1+ | Available | See [Step 1](#step-1--bootstrap-the-aid-cli-once-per-machine) |
| `--from-bundle <path>` (offline tarball) | Bash or PowerShell 5.1+ | Available | See [Offline install](#offline--air-gapped-install) |
| `npm install -g aid-installer` → `aid` | Node >=18 | Published / live | See [npm channel](#npm-channel) |
| `pipx install aid-installer` → `aid` | Python >=3.8 | Published / live | See [PyPI channel](#pypi-channel) |

All four channels — `curl`/`irm` bootstrap, `--from-bundle`, npm, and PyPI — are
available and deliver an identical `aid` CLI.
