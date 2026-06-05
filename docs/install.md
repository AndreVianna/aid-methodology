# AID Install / Update / Uninstall Guide

Complete reference for the `aid` CLI: bootstrap, per-project subcommands, offline install,
and uninstall — across Linux, macOS, and Windows.

---

## Contents

- [How it works (two steps)](#how-it-works-two-steps)
- [Step 1 — Bootstrap the `aid` CLI (once per machine)](#step-1--bootstrap-the-aid-cli-once-per-machine)
- [Step 2 — Use `aid` per project](#step-2--use-aid-per-project)
- [One-line first install (bootstrap + add in one command)](#one-line-first-install-bootstrap--add-in-one-command)
- [Offline / air-gapped install](#offline--air-gapped-install)
- [Uninstalling](#uninstalling)
- [Trust model and checksum verification](#trust-model-and-checksum-verification)
- [Protect-on-diff for root agent files](#protect-on-diff-for-root-agent-files)
- [Version recording and the manifest](#version-recording-and-the-manifest)
- [Exit codes](#exit-codes)
- [GitHub API rate limits and authentication](#github-api-rate-limits-and-authentication)
- [Full flag reference](#full-flag-reference)
- [Channels](#channels)

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

## Step 1 — Bootstrap the `aid` CLI (once per machine)

Run this once. The bootstrap installs the `aid` command and wires it onto your PATH. You
do not need to be inside a project directory.

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/<ref>/install.sh | bash
```

- Installs to `~/.aid/` (override with `$AID_HOME`).
- Adds `~/.aid/bin` to your PATH via `~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`
  depending on your shell.
- Pass `--no-path` to skip the profile edit and wire PATH yourself.

### Windows (PowerShell 5.1+)

```powershell
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/<ref>/install.ps1 | iex
```

- Installs to `%LOCALAPPDATA%\aid\` (override with `$env:AID_HOME`).
- Adds `%LOCALAPPDATA%\aid` to your **User** PATH (no admin required).
- Pass `-NoPath` to skip the PATH edit:
  ```powershell
  $env:AID_NO_PATH = '1'; irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/<ref>/install.ps1 | iex
  ```

> **After bootstrap, open a new shell** (or source your profile) to pick up the
> updated PATH. The `aid` command is then available everywhere.

### Pinned-version bootstrap (recommended for teams and CI)

```bash
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/<ref>/install.sh | bash -s -- --version 0.7.0
```

```powershell
# Windows
$env:AID_VERSION = '0.7.0'
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/<ref>/install.ps1 | iex
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
AID 0.7.0  (project: /path/to/your/project)
Installed tools:
  claude-code   v0.7.0   root: CLAUDE.md (owned)
```

Bare `aid` (no subcommand) is an alias for `aid status`. Exit 7 when no AID install is
found in the current directory.

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
aid add claude-code --version 0.7.0
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

### Remove a specific tool

```bash
aid remove codex
```

### Remove AID entirely from this project

```bash
aid uninstall
```

Removes all AID-installed files (manifest-driven — only what `aid add` wrote). Your own
edits to `CLAUDE.md`/`AGENTS.md` are left in place (see
[Protect-on-diff](#protect-on-diff-for-root-agent-files)).

### Print the CLI version

```bash
aid version
```

This prints the version of the global `aid` CLI itself (from `~/.aid/VERSION`), not the
version of tools installed in the current project (those are in the manifest).

---

## One-line first install (bootstrap + add in one command)

If you want to bootstrap the CLI **and** add a tool to the current project in a single
command:

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/<ref>/install.sh | bash -s -- add claude-code
```

The bootstrap installs `aid`, then immediately runs `aid add claude-code` in the current
directory. No need to open a new shell first — the bootstrapped `bin/aid` is invoked
directly.

### Windows

Because `irm … | iex` cannot forward arguments, use the `AID_TOOL` environment variable:

```powershell
$env:AID_TOOL = 'claude-code'
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/<ref>/install.ps1 | iex
```

This bootstraps the CLI and then runs `aid add claude-code` in the current directory.

---

## Offline / air-gapped install

Download the tarball and optional checksum file from the
[GitHub Releases page](https://github.com/AndreVianna/aid-methodology/releases), then
use `aid add --from-bundle` — no network required.

### Download and verify

```bash
# Download (example: claude-code at v0.7.0)
curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/v0.7.0/aid-claude-code-v0.7.0.tar.gz
curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/v0.7.0/SHA256SUMS

# Verify (Linux)
sha256sum --check --ignore-missing SHA256SUMS

# Verify (macOS)
shasum -a 256 -c SHA256SUMS
```

```powershell
# Verify (Windows)
$expected = (Get-Content SHA256SUMS | Where-Object { $_ -match 'aid-claude-code' }) -split '\s+' | Select-Object -First 1
$actual   = (Get-FileHash .\aid-claude-code-v0.7.0.tar.gz -Algorithm SHA256).Hash.ToLower()
if ($expected -ne $actual) { Write-Error "Checksum mismatch"; exit 4 }
```

### Install offline

```bash
# After bootstrapping the CLI (see Step 1)
aid add claude-code --from-bundle aid-claude-code-v0.7.0.tar.gz
```

For multiple tools, pass a directory containing the per-tool tarballs
(`aid-<tool>-v<version>.tar.gz` naming):

```bash
aid add codex,cursor --from-bundle ./bundles/
```

`--from-bundle` and `--version` are mutually exclusive.

---

## Uninstalling

### Remove AID from a project

```bash
# Remove all tools
aid uninstall

# Remove a specific tool
aid remove claude-code
```

Uninstall is manifest-driven: only files that `aid add` wrote are removed. Files you
created or modified yourself are left in place.

### Remove the global `aid` CLI itself

```bash
aid self-uninstall
```

This removes `~/.aid` (or `%LOCALAPPDATA%\aid`) and the PATH-wiring block. It does
**not** touch per-project AID installs — run `aid uninstall` inside each project first
if you want to clean those up too.

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

On `aid uninstall` / `aid remove`, a root agent file is only removed if it still matches
the checksum AID recorded at install time. If you have edited it since, the file is left
in place: `Left in place (modified or not AID-owned): AGENTS.md`.

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
`aid remove`, and `aid uninstall` — do not delete it.

### Manifest location

`.aid/.aid-manifest.json` — one JSON file per repo, shared across all tools installed
into that repo. A human-readable convenience file is also written: `.aid/.aid-version`
(one line: the installed version string).

### Manifest structure (abbreviated)

```json
{
  "manifest_version": 1,
  "aid_version": "0.7.0",
  "installed_at": "2026-06-04T12:00:00Z",
  "tools": {
    "claude-code": {
      "version": "0.7.0",
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

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success. Install/update/uninstall completed. "Nothing to do" is success. |
| `1` | Generic runtime failure (extract failed, write failed). |
| `2` | Usage error: unknown subcommand, bad argument, ambiguous tool, undetectable tool, missing target directory, `--from-bundle` + `--version` together. |
| `3` | Network / fetch failure: download or latest-release resolution failed and no `--from-bundle`. |
| `4` | Checksum mismatch: SHA-256 of downloaded file did not match `SHA256SUMS`. |
| `5` | Protect-on-diff: at least one root agent file was blocked. Other files were installed successfully. Review the `.aid-new` file and merge manually, or re-run with `--force`. |
| `6` | Uninstall with no manifest: nothing installed (idempotent — not a hard error). |
| `7` | `aid status` / `aid` (bare): no AID install found in the current directory. |

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

## Full flag reference

### `aid` subcommands

```
aid                            Alias for aid status
aid status [--verbose] [--target <dir>]
aid add <tool>[,...] [--version <v>] [--from-bundle <path>]
                     [--force] [--verbose] [--target <dir>]
aid remove <tool>[,...] [--verbose] [--target <dir>]
aid update [<tool>...] [--version <v>] [--from-bundle <path>]
                       [--force] [--verbose] [--target <dir>]
aid uninstall [--verbose] [--target <dir>]
aid version
aid self-uninstall [--force]
aid help [<subcommand>]
```

PowerShell flags use the same words; the `-` prefix is accepted alongside `--`:
`-Force`, `-Verbose`, `-Version <v>`, `-FromBundle <path>`, `-Target <dir>`.

| Flag | Default | Description |
|------|---------|-------------|
| `--version <v>` | latest release | Pin to a release version (`0.7.0` or `v0.7.0`). Mutually exclusive with `--from-bundle`. |
| `--from-bundle <path>` | — | Offline install from a tarball (single tool) or a directory of tarballs (comma-list). No network. |
| `--force` | off | Overwrite differing files, including protected root agent files. |
| `--verbose` | off | Print per-file `Copied:` / `Up to date:` / `Updated:` / `Removed:` lines. Default: concise per-tool summary. |
| `--target <dir>` | `.` (cwd) | Project root. Must exist; a missing target is a usage error (exit 2). |

**Env-var equivalents** (flags take precedence over env vars):

| Env var | Equivalent flag | Notes |
|---------|-----------------|-------|
| `AID_TOOL` | positional tool arg | Accepted by `add`/`remove`/`update`. |
| `AID_VERSION` | `--version` | |
| `AID_TARGET` | `--target` | |
| `AID_FORCE` | `--force` | Set to `1` or `true`. |
| `AID_VERBOSE` | `--verbose` | Set to `1`. |

### Canonical tool ids

| Tool id | Installs into | Root agent file |
|---------|--------------|-----------------|
| `claude-code` | `.claude/` | `CLAUDE.md` |
| `codex` | `.codex/` + `.agents/` | `AGENTS.md` |
| `cursor` | `.cursor/` | `AGENTS.md` |
| `copilot-cli` | `.github/` | `AGENTS.md` |
| `antigravity` | `.agent/` | `AGENTS.md` |

Tool ids are accepted case-insensitively. On Windows, PascalCase aliases are also
accepted: `ClaudeCode`, `Codex`, `Cursor`, `CopilotCli`, `Antigravity`.

### Bootstrap scripts (fallback / back-compat)

`install.sh` and `install.ps1` retain the legacy direct-install flag style for **one
release** as a back-compat path. Prefer `aid add` for new workflows.

```
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

### Tool auto-detect

When `aid add` is run without a tool name, the CLI probes the current directory for
per-tool markers:

| Marker present in target | Detected tool |
|--------------------------|---------------|
| `.claude/` dir | `claude-code` |
| `.codex/` dir or `.agents/` dir | `codex` |
| `.cursor/` dir | `cursor` |
| `.github/` with AID-specific children (`agents/` or `skills/`) | `copilot-cli` |
| `.agent/` dir | `antigravity` |

A plain `.github/` directory (without the AID copilot subtree) does **not** trigger
`copilot-cli` detection.

- Exactly one marker found → that tool is used.
- Zero markers found → error, exit 2: `cannot auto-detect host tool; pass tool name as argument`.
- More than one marker found → error, exit 2: `ambiguous host tool (found: X, Y)`.

---

## Channels

| Channel | Status | Command |
|---------|--------|---------|
| `curl … \| bash` (online, Linux / macOS / git-bash) | Available | See [Step 1](#step-1--bootstrap-the-aid-cli-once-per-machine) |
| `irm … \| iex` (online, Windows PowerShell) | Available | See [Step 1](#step-1--bootstrap-the-aid-cli-once-per-machine) |
| `--from-bundle <path>` (offline tarball) | Available | See [Offline install](#offline--air-gapped-install) |
| `npm i -g @aid/installer` → `aid` | Coming in a later delivery (003) | — |
| `pipx install aid-installer` → `aid` | Coming in a later delivery (004) | — |

> **Note (003/004 ripple):** The npm and PyPI packages for features 003 and 004 will publish
> the `aid` command directly, making `npm i -g @aid/installer` and `pipx install aid-installer`
> equivalent bootstrap paths to `curl | bash`. Those deliveries are not yet shipped; the
> `curl`/`irm` path is the only supported bootstrap today.
