# AID Install / Update / Uninstall Guide

Complete reference for the `install.sh` / `install.ps1` one-command installer across all supported channels and platforms.

---

## Contents

- [Channels](#channels)
- [Quick start](#quick-start)
- [Tool selection and auto-detect](#tool-selection-and-auto-detect)
- [Version pinning](#version-pinning)
- [Offline install from a bundle](#offline-install-from-a-bundle)
- [Updating an existing install](#updating-an-existing-install)
- [Uninstalling](#uninstalling)
- [Protect-on-diff for root agent files](#protect-on-diff-for-root-agent-files)
- [Version recording and the manifest](#version-recording-and-the-manifest)
- [Exit codes](#exit-codes)
- [GitHub API rate limits and authentication](#github-api-rate-limits-and-authentication)
- [Full flag reference](#full-flag-reference)

---

## Channels

| Channel | Status | Command |
|---------|--------|---------|
| `curl … \| bash` (online, Linux/macOS/git-bash) | Available | See [Quick start](#quick-start) |
| `irm … \| iex` (online, Windows PowerShell) | Available | See [Quick start](#quick-start) |
| `--from-bundle <path>` (offline tar) | Available | See [Offline install](#offline-install-from-a-bundle) |
| `npx aid-installer` (npm) | Coming in a later delivery | — |
| `pipx run aid` (PyPI) | Coming in a later delivery | — |

---

## Quick start

### Online install (Linux / macOS / git-bash)

Run from inside the project root where you want AID installed:

```bash
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash
```

The installer auto-detects your host tool from the project tree. Pass `--tool <name>` if you want to target a specific tool or the detection is ambiguous.

### Online install (Windows PowerShell 5.1+)

```powershell
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex
```

### Pinned-version install (recommended for CI and reproducibility)

```bash
# Bash — pin to a specific release
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash -s -- --version 0.7.0
```

```powershell
# PowerShell — pin to a specific release
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1))) -Version 0.7.0
```

Pinning `--version` is strongly recommended for any automated or reproducible install. Without it the installer resolves the latest GitHub Release, which can change.

### Trust model for online installs

When running via `curl|bash` or `irm|iex`, the bootstrap installer:

1. **Pins the lib to an immutable release tag.** The shared install-core library (`lib/aid-install-core.sh` / `lib/AidInstallCore.psm1`) is fetched from the release tag `v<VERSION>` (not the mutable `master` branch). When `--version` is given, that exact version is used; otherwise the latest release is resolved first, then the lib is fetched from that tag.
2. **Verifies the lib's checksum before sourcing it — fails closed.** The installer fetches `SHA256SUMS` from the same release tag and verifies the lib's SHA-256 before sourcing/importing it:
   - **Checksum mismatch** → aborts with exit 4.
   - **SHA256SUMS cannot be fetched** (404, network error, or MITM dropping the request) → aborts with exit 3; the lib is **not** sourced.
   - **Entry for the lib missing from SHA256SUMS** → aborts with exit 3; the lib is **not** sourced.
   - Only when SHA256SUMS is fetched successfully and the hash matches does the install proceed.

   The only way to skip verification is to set `AID_INSECURE_SKIP_LIB_VERIFY=1` explicitly — this is a deliberate, loud insecure override intended for restricted test environments only. Do not set it in production.

3. **Offline `--from-bundle` remains the strongest path.** No network is used at all; you verify the tarball yourself before running the installer. Recommended for air-gapped or high-security environments.

A pinned install (`--version 0.7.0`) with online channels is reproducible and tamper-detectable: the lib is fetched from an immutable tag URL and its SHA-256 is verified against the signed release artifact before any code runs. An unpinned install resolves the latest release version first, then applies the same verification.

---

## Tool selection and auto-detect

### Canonical tool ids

Pass one of these values to `--tool` / `-Tool`:

| Tool id | Installs into | Root agent file |
|---------|--------------|-----------------|
| `claude-code` | `.claude/` | `CLAUDE.md` |
| `codex` | `.codex/` + `.agents/` | `AGENTS.md` |
| `cursor` | `.cursor/` | `AGENTS.md` |
| `copilot-cli` | `.github/` | `AGENTS.md` |
| `antigravity` | `.agent/` | `AGENTS.md` |

Tool ids are accepted case-insensitively in Bash. PowerShell additionally accepts PascalCase aliases: `ClaudeCode`, `Codex`, `Cursor`, `CopilotCli`, `Antigravity`.

### Auto-detect

When `--tool` is omitted the installer probes the target directory for per-tool markers:

| Marker present in target | Detected tool |
|--------------------------|---------------|
| `.claude/` dir | `claude-code` |
| `.codex/` dir or `.agents/` dir | `codex` |
| `.cursor/` dir | `cursor` |
| `.github/` with AID-specific children (`agents/` or `skills/`) | `copilot-cli` |
| `.agent/` dir | `antigravity` |

A plain `.github/` directory (without the AID copilot subtree) does **not** trigger `copilot-cli` detection — many repos have `.github/` for Actions/templates.

- Exactly one marker found → that tool is used.
- Zero markers found → error, exit 2: `cannot auto-detect host tool; pass --tool <name>`
- More than one marker found → error, exit 2: `ambiguous host tool (found: X, Y); pass --tool <name>`

### Installing multiple tools at once

Pass a comma-separated list to install several tools in one invocation:

```bash
bash install.sh --tool codex,cursor --version 0.7.0
```

Each tool is installed independently into its own directory tree. With a comma-list, the second tool's root agent file (`AGENTS.md`) may trigger [protect-on-diff](#protect-on-diff-for-root-agent-files) if it differs from the first tool's version (see the pre-FR12 note there).

### Custom target directory

Install into a specific directory instead of the current working directory:

```bash
# Trailing positional argument
bash install.sh --tool claude-code /path/to/your/project

# Named flag
bash install.sh --tool claude-code --target /path/to/your/project

# PowerShell
.\install.ps1 -Tool ClaudeCode -TargetDirectory C:\path\to\your\project
```

The target directory must already exist. A missing target is a usage error (exit 2).

---

## Version pinning

```bash
# Bash
bash install.sh --tool claude-code --version 0.7.0

# PowerShell
.\install.ps1 -Tool ClaudeCode -Version 0.7.0
```

- `<v>` accepts `0.7.0` or `v0.7.0` (the leading `v` is optional).
- Omitting `--version` resolves the latest GitHub Release via the API (see [rate limits](#github-api-rate-limits-and-authentication)).
- `--version` and `--from-bundle` are mutually exclusive.

**Recommendation:** always pin `--version` in CI pipelines and team onboarding scripts. This guarantees everyone installs the same artifact and makes the install reproducible without relying on the GitHub API.

---

## Offline install from a bundle

Download the tarball (and optionally `SHA256SUMS`) from the [GitHub Releases page](https://github.com/AndreVianna/aid-methodology/releases), then install without any network access:

```bash
# 1. Download the tarball (example: claude-code at 0.7.0)
curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/v0.7.0/aid-claude-code-v0.7.0.tar.gz
curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/v0.7.0/SHA256SUMS

# 2. Verify the download (strongly recommended)
sha256sum --check --ignore-missing SHA256SUMS   # Linux
shasum -a 256 -c SHA256SUMS                      # macOS

# 3. Install offline
bash install.sh --tool claude-code --from-bundle aid-claude-code-v0.7.0.tar.gz
```

PowerShell equivalent:

```powershell
# Verify (PowerShell)
$expected = (Get-Content SHA256SUMS | Where-Object { $_ -match 'aid-claude-code' }) -split '\s+' | Select-Object -First 1
$actual   = (Get-FileHash .\aid-claude-code-v0.7.0.tar.gz -Algorithm SHA256).Hash.ToLower()
if ($expected -ne $actual) { Write-Error "Checksum mismatch"; exit 4 }

# Install offline
.\install.ps1 -Tool ClaudeCode -FromBundle .\aid-claude-code-v0.7.0.tar.gz
```

### Multiple tools offline

When installing a comma-list of tools offline, provide a directory containing the per-tool tarballs (named per the `aid-<tool>-v<VERSION>.tar.gz` pattern):

```bash
# Assuming aid-codex-v0.7.0.tar.gz and aid-cursor-v0.7.0.tar.gz are in ./bundles/
bash install.sh --tool codex,cursor --from-bundle ./bundles/
```

### Checksum verification behavior

For `--from-bundle` (offline) installs:

- If a `SHA256SUMS` file is present beside the bundle (`--from-bundle <path>` → `SHA256SUMS` in the same directory), the installer verifies the tarball's SHA-256 automatically.
- A checksum mismatch aborts with exit 4.
- No `SHA256SUMS` present beside the bundle → a warning is emitted and the install continues (the tarball itself is not the remotely-fetched lib; you chose and supplied it).

For online (`curl|bash` / `irm|iex`) installs, the verification is **fail-closed** — see [Trust model for online installs](#trust-model-for-online-installs) above.

---

## Updating an existing install

Re-run the installer with `--update` to refresh to a new (or the latest) version:

```bash
# Update to latest
bash install.sh --update

# Update to a specific version
bash install.sh --update --version 0.8.0

# Update a specific tool only
bash install.sh --update --tool claude-code --version 0.8.0

# PowerShell
.\install.ps1 -Update -Version 0.8.0
```

`--update` reads the manifest to determine which tools are currently installed. It re-installs their trees, refreshing files that have changed and skipping identical ones.

Re-running the plain install command (without `--update`) behaves identically — it is safe to re-run at any time. Files that are already up to date are skipped.

---

## Uninstalling

```bash
# Remove all AID-installed files (reads the manifest)
bash install.sh --uninstall

# Remove a single tool only
bash install.sh --uninstall --tool claude-code

# PowerShell
.\install.ps1 -Uninstall
.\install.ps1 -Uninstall -Tool ClaudeCode
```

Uninstall is manifest-driven: only files that AID wrote (recorded in `.aid/.aid-manifest.json`) are removed. Files you created or modified yourself are left in place.

Calling `--uninstall` with no manifest present exits with code 6 (nothing installed). A second `--uninstall` call after a successful uninstall is therefore idempotent (exit 6, not an error in the failure sense).

---

## Protect-on-diff for root agent files

Root agent files — `CLAUDE.md` (claude-code) and `AGENTS.md` (codex, cursor, copilot-cli, antigravity) — sit at your project root and may contain your own customizations. The installer protects them from silent overwrites.

### How it works

On install or update, when writing a root agent file `F`:

1. `F` does not exist → installer writes it, records ownership in the manifest.
2. `F` exists and is byte-identical to the incoming version → no-op; `Up to date: F`.
3. `F` exists and the manifest shows AID wrote the current version → AID owns it; installer updates it in place.
4. `F` exists, differs from the incoming version, and is **not** recorded in the manifest (or differs from what AID recorded) → **someone else owns it**:
   - **Without `--force`:** installer does NOT overwrite. It writes the incoming version beside it as `F.aid-new` (e.g. `AGENTS.md.aid-new`) and warns:
     > `AGENTS.md exists and was not written by AID; wrote incoming version to AGENTS.md.aid-new — review and merge, or re-run with --force to overwrite`
     The install exits with code 5 so CI pipelines notice.
   - **With `--force`:** installer overwrites `F` and takes ownership.

### Resolving an `*.aid-new` file

```bash
# Review the diff between your current file and the incoming version
diff AGENTS.md AGENTS.md.aid-new

# Option A: keep your version, discard the incoming
rm AGENTS.md.aid-new

# Option B: accept the incoming version
mv AGENTS.md.aid-new AGENTS.md && bash install.sh  # re-run so AID records ownership

# Option C: merge manually, then re-run so AID records ownership
# (edit AGENTS.md to merge, then re-run install)
bash install.sh --force
```

### Uninstall safety

On uninstall, a root agent file is only removed if it still matches the checksum AID recorded. If you have edited it since AID wrote it, the file is left in place and reported as `Left in place (modified or not AID-owned): F`.

### Pre-FR12 multi-tool note

Installing a second `AGENTS.md`-writing tool (e.g. `codex` then `cursor`) will trigger protect-on-diff because each tool's `AGENTS.md` currently differs by one line (the profile path). You will see `AGENTS.md.aid-new` created and exit 5. This is correct behavior, not a bug — it prevents silent overwrites. Use `--force` to accept the second tool's version if that is your intent. This behavior normalizes in delivery-005 (feature-006), which makes all `AGENTS.md` files byte-identical.

---

## Version recording and the manifest

After every install, AID records what it installed at `.aid/.aid-manifest.json` in your target repo. This manifest drives update and uninstall — do not delete it.

### Manifest location

`.aid/.aid-manifest.json` — a single JSON file shared across all tools installed into one repo. AID also writes a human-readable convenience file: `.aid/.aid-version` (one line: the installed version string).

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

- `tools.<id>.paths` — every file AID installed for that tool (relative paths, POSIX separators). Uninstall removes exactly these.
- `tools.<id>.root_agent_files[].sha256` — checksum AID recorded when it wrote the root agent file. Used for ownership decisions on update and uninstall.
- `status: "owned"` — AID owns this file. `status: "pending-merge"` — AID could not write the file (protect-on-diff triggered); a `.aid-new` sibling exists.

The manifest file itself is not listed in `paths` (it is metadata, not a profile file). The `.aid/` directory is not removed on uninstall — only the manifest and version files are removed (since `.aid/` may also contain your KB and work-area files).

---

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success. Install/update/uninstall completed. "Nothing to do" is success. |
| `1` | Generic runtime failure (extract failed, write failed). |
| `2` | Usage error: unknown flag, bad argument, ambiguous tool, undetectable tool, missing target directory, `--from-bundle` + `--version` together. |
| `3` | Network / fetch failure: download or latest-release resolution failed and no `--from-bundle`. |
| `4` | Checksum mismatch: tarball `sha256` did not match `SHA256SUMS`. |
| `5` | Protect-on-diff: at least one root agent file was blocked (not written); a `.aid-new` sibling was created. Other files were installed successfully. |
| `6` | Uninstall with no manifest: nothing was installed (idempotent). |

Exit 5 means the install partially succeeded — all files other than the blocked root agent file were written. Review the `.aid-new` file and either merge manually or re-run with `--force`.

---

## GitHub API rate limits and authentication

Online installs (without `--version`) resolve the latest release via `GET https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest`. Unauthenticated requests are rate-limited (~60/hour per IP). Shared NAT environments (CI farms, corporate networks) can exhaust this quickly.

Mitigations, in order of preference:

1. **Pin `--version`** (best for CI and reproducibility): skips the API call entirely.
2. **Set `$GITHUB_TOKEN` or `$GH_TOKEN`**: the installer sends it as a bearer token, raising the rate limit to ~5,000/hour.
3. **Use `--from-bundle`**: no API call at all.

```bash
# With a token
GITHUB_TOKEN=ghp_... bash install.sh --tool claude-code

# PowerShell
$env:GITHUB_TOKEN = 'ghp_...'
.\install.ps1 -Tool ClaudeCode
```

---

## Full flag reference

### Bash (`install.sh`)

```
bash install.sh [--tool <name>[,<name>...]] [--version <v>] [--from-bundle <path>]
                [--force] [--target <dir>] [<target-dir>]
bash install.sh --update   [--tool <name>[,...]] [--version <v>] [--from-bundle <path>]
                [--force] [--target <dir>]
bash install.sh --uninstall [--tool <name>[,...]] [--target <dir>]
bash install.sh -h | --help
```

| Flag | Default | Description |
|------|---------|-------------|
| `--tool <name>[,...]` | auto-detect | Host tool(s). Canonical ids: `claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`. Comma-list for multiple. |
| `--version <v>` | latest release | Pin to a release version (`0.7.0` or `v0.7.0`). Mutually exclusive with `--from-bundle`. |
| `--from-bundle <path>` | — | Offline install from a tarball (single tool) or a directory of tarballs (comma-list). No network. |
| `--force` | off | Overwrite differing files, including protected root agent files. |
| `--update` | — | Mode: re-install over an existing AID setup. |
| `--uninstall` | — | Mode: manifest-driven removal. |
| `--target <dir>` | `.` (cwd) | Install root. Also accepted as a trailing positional argument. |
| `-h`, `--help` | — | Print help and exit 0. |

### PowerShell (`install.ps1`)

```
.\install.ps1 [-Tool <name[,name...]>] [-Version <v>] [-FromBundle <path>]
              [-Force] [-TargetDirectory <dir>]
.\install.ps1 -Update    [-Tool ...] [-Version <v>] [-FromBundle <path>] [-Force] [-TargetDirectory <dir>]
.\install.ps1 -Uninstall [-Tool ...] [-TargetDirectory <dir>]
.\install.ps1 -Help
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-Tool <name>[,...]` | auto-detect | Canonical ids or PascalCase aliases (`ClaudeCode`, `Codex`, `Cursor`, `CopilotCli`, `Antigravity`). |
| `-Version <v>` | latest release | Pin to a release version. Mutually exclusive with `-FromBundle`. |
| `-FromBundle <path>` | — | Offline mode. Single tarball (single `-Tool`) or directory of tarballs (comma-list). |
| `-Force` | off | Overwrite differing files including protected root agent files. |
| `-Update` | — | Mode: re-install over an existing AID setup. |
| `-Uninstall` | — | Mode: manifest-driven removal. |
| `-TargetDirectory <dir>` | `.` (cwd) | Install root. |
| `-Help` | — | Print help and exit 0. |

### Behavioral parity

`install.sh` and `install.ps1` are behaviorally identical: same flags (different naming convention), same exit codes, same user-visible messages, same manifest output. No WSL is required — `install.ps1` runs in native PowerShell 5.1+ and `pwsh` on Linux CI.
