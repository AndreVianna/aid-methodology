# Shared Install Core & Bootstrap (M2)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Feature identified from REQUIREMENTS.md §4, §5 (FR1–FR5, FR9), §7, §10 | /aid-interview |
| 2026-06-04 | **CLI evolution** — installer reshaped into a persistent global `aid` CLI (subcommands, PATH wiring, self-uninstall); bootstrap becomes arg-free CLI installer; §"CLI Evolution" added. User-approved new direction, folded into delivery-001 (no re-interview). | /aid-architect |

## Source

- REQUIREMENTS.md §4 Scope, §5 (FR1, FR2, FR3, FR4, FR5, FR9), §6, §7, §9, §10.1

## Description

The foundation of the AID auto-installer. Provides a single **canonical install core** plus the
cross-platform **`install.sh` / `install.ps1`** bootstrap that drives it — so an adopter can
install, update, or uninstall AID into their repo with one command, fetching only the rendered
profile tree they need (not the whole repo). The core is the shared logic that the npm and PyPI
CLIs (features 003/004) wrap, ensuring install behavior is defined once, not duplicated per surface.
This feature also **removes the legacy `setup.sh` / `setup.ps1`** scripts and updates their
references (README, docs, `infrastructure.md`).

## User Stories

- As an adopter with no Node/Python, I want to install AID with a single `curl … | bash` (or `irm … | iex`) so that I don't have to clone the whole repo or install extra tooling.
- As an air-gapped / security-conscious adopter, I want to install from a pre-downloaded bundle (`--from-bundle`) with no network so that I can review the artifact before installing.
- As an adopter, I want the installer to detect my host tool automatically (with a `--tool` override) so that I get the right profile tree without guessing.
- As an adopter, I want to re-run to update or to cleanly uninstall so that AID is reversible and reproducible.

## Priority

Must (P0 — foundation; everything else depends on it)

## Acceptance Criteria

- [ ] Given a repo with no prior AID setup, when I run the one-command installer (auto-detect or `--tool`), then the correct rendered profile tree is installed **or updated** at a pinned version without cloning the full repo.
- [ ] Given an installed setup, when I run uninstall, then exactly the AID-installed files are removed (manifest-based), leaving the repo pre-install-clean.
- [ ] Given the host tool is unspecified, when the installer runs, then it auto-detects the host tool (or errors clearly if ambiguous), and `--tool` always overrides.
- [ ] Given Unix and Windows, when the installer runs, then both the Bash and PowerShell paths work (no WSL requirement).
- [ ] Given both online and offline contexts, when I install, then both online (remote fetch) and offline (`--from-bundle`) modes succeed.
- [ ] Given an install/update, then the installed version is recorded in the target repo for reproducibility.
- [ ] Given the new installer is in place, then `setup.sh` / `setup.ps1` are removed and their references updated.
- [ ] The install core honors the existing copy semantics (skip-identical, prompt-on-diff / `--force`) across all five host-tool tree layouts.
- [ ] **Per-tool selection (FR2):** installs one tool per invocation via `--tool` (auto-detect default; optional comma-list); the interactive multi-select menu is removed. Each tool dir is isolated.
- [ ] **Protect-on-diff for root agent files (FR11):** given an existing `CLAUDE.md`/`AGENTS.md` the installer didn't write (checksum vs. manifest), install without `--force` does NOT overwrite — it warns and writes the incoming version as `*.aid-new`; `--force` overwrites.
- [ ] **Uninstall safety (FR11):** a root agent file is removed only if it still checksum-matches what this tool installed; otherwise it is left in place (the user or another tool owns it).

## Dependencies

- **feature-002** (release-packaging-and-checksums) — supplies the tarball + checksum artifact the bootstrap downloads (online) or consumes (`--from-bundle`). The core can be authored against a stubbed artifact, but end-to-end install needs feature-002.

---

## Technical Specification

> Added by `/aid-specify`. Foundation feature — the interfaces below (CLI surface, manifest
> schema, shared-core delegation contract, protect-on-diff algorithm, artifact-consumption
> contract) are **authoritative** and are referenced by features 003 (npm CLI), 004 (PyPI CLI),
> and 005 (CI release automation). Treat every named flag, path, exit code, and manifest field
> as a contract: downstream features depend on these exact spellings.

### Scope boundaries with neighbouring features

| Concern | Owner | This feature does |
|---------|-------|-------------------|
| Per-profile tarball layout, naming, `SHA256SUMS`, `gh release create` | **feature-002** | **Consumes** the artifact contract; does not produce or redefine it. |
| Byte-identical root `AGENTS.md` across the 4 AGENTS.md writers (FR12) | **feature-006** | **Assumes** it; until 006 lands, tool-vs-tool `AGENTS.md` diffs are real and protect-on-diff (FR11) handles them. |
| npm `@aid/installer` wrapper (`npx aid-installer …`) | **feature-003** | **Defines** the delegation contract the wrapper calls (see §"Shared-core delegation contract"). |
| PyPI `aid-installer` wrapper (`pipx run aid …`) | **feature-004** | Same delegation contract. |
| Tag-triggered CI that runs `release.sh` + publishes | **feature-005** | Out of scope; manual `gh release create` (feature-002) until 005 lands. |

### Data Model

No database schema. This feature introduces two on-disk file contracts in the **target repo**
(not the AID repo): the **install manifest** and a copy of the **shared-core lib** is NOT
written to the target — only the manifest and the rendered profile tree are. Both are defined
in §"Install manifest schema (FR4 + FR3)".

### Component layout

All new files live at the **AID repo root** (mirroring the existing `setup.sh`/`setup.ps1`
pair) except the shared-core lib/module, which live under a new `lib/` dir so the bootstraps
and the 003/004 wrappers can source them.

| New file | Platform | Role |
|----------|----------|------|
| `install.sh` | Bash 4+ | Bootstrap CLI (Unix/macOS/git-bash). Parses args, sources `lib/aid-install-core.sh`, dispatches install/update/uninstall. |
| `install.ps1` | PowerShell 5.1+ | Bootstrap CLI (Windows). Parses params, imports `lib/AidInstallCore.psm1`, dispatches the same modes. |
| `lib/aid-install-core.sh` | Bash 4+ | **Shared core (Bash side).** Sourceable library of functions: detect, resolve-version, fetch/extract, copy-tree, copy-file (skip/diff/force), protect-on-diff, write/read manifest, uninstall. Pure functions; no top-level side effects when sourced. |
| `lib/AidInstallCore.psm1` | PowerShell 5.1+ | **Shared core (PowerShell side).** Behaviorally identical module exporting the same operations as PowerShell functions. Bash and PowerShell cannot share code, so these two files are the **single canonical logic** kept in lockstep (FR9) — every behavior change edits both, and parity is enforced by tests. |

| Removed file | Replaced by |
|--------------|-------------|
| `setup.sh` | `install.sh` (+ core lib) |
| `setup.ps1` | `install.ps1` (+ core module) |

**References to update when `setup.sh`/`setup.ps1` are removed.** The authoritative set is
**every hand-maintained doc matching `grep -rl 'setup\.\(sh\|ps1\)'` outside `.aid/knowledge/`
and `profiles/`** — the implementation MUST re-run this grep at build time and update **every**
hit (the list below is the snapshot confirmed on disk for this spec; treat the live grep as the
source of truth, since docs may drift). Two carve-outs are excluded by the `.aid/knowledge/` and
`profiles/` path filter and are **not** hand-edited here: `.aid/knowledge/*` (refreshed by the
KB-housekeep cycle) and the rendered `profiles/*` trees, including the `.claude/` skill/template
copies under them (regenerated by the profiles re-render from the `canonical/` sources below).
Everything else the grep returns IS hand-maintained and must be updated — including
repo-root `.claude/settings.json`, whose permission allow-rule references `./setup.sh`.
- `README.md` — install instructions.
- `CONTRIBUTING.md` — contributor install/test mentions.
- `docs/faq.md` — install FAQ.
- `examples/greenfield/README.md` — names `setup.sh` / `setup.ps1` in the install walkthrough.
- `examples/brownfield-full-path/README.md` — uses `bash setup.sh` in the worked example.
- `methodology/aid-methodology.md` — the pipeline diagram (`setup.sh / setup.ps1` end-user
  installer node, ~line 865) and the multi-tool-install prose (~line 874, which also describes
  the now-removed last-writer-wins selection — reword for per-tool install + protect-on-diff).
- `tests/README.md` — test-suite description.
- `tests/canonical/test-setup.sh` → rename/replace with `test-install.sh`; `test-setup-ps1.sh`
  → `test-install-ps1.sh` (see §Testing).
- Maintainer/methodology re-render **sources** that name the scripts
  (`canonical/skills/aid-discover/SKILL.md`, `canonical/templates/rough-time-hints.md`,
  `canonical/templates/knowledge-summary/section-templates/agentic-pipeline.md`) — update the
  text in `canonical/` (the `.claude/*` and `profiles/*` copies re-render from these, so they
  are *not* edited directly).
- KB docs (`infrastructure.md`, `repo-presentation.md`, `technology-stack.md`,
  `coding-standards.md`, `test-landscape.md`, etc.) reflect reality post-change — refreshed by
  the KB-housekeep cycle, **not** hand-edited inside this delivery.

### CLI surface (authoritative — 003/004 mirror these)

Three modes, selected by flag; **install is the default** (no mode flag). One tool per dir; the
interactive multi-select menu of `setup.sh`/`setup.ps1` is **removed**.

**Bash:**
```
install.sh [--tool <name>[,<name>...]] [--version <v>] [--from-bundle <path>]
           [--force] [--target <dir>] [<target-dir>]
install.sh --update   [--tool <name>[,...]] [--version <v>] [--from-bundle <path>] [--force] [--target <dir>]
install.sh --uninstall [--tool <name>[,...]] [--target <dir>]
install.sh -h | --help
```

**PowerShell (behaviorally identical):**
```powershell
.\install.ps1 [-Tool <name[,name...]>] [-Version <v>] [-FromBundle <path>]
              [-Force] [-TargetDirectory <dir>]
.\install.ps1 -Update    [-Tool ...] [-Version <v>] [-FromBundle <path>] [-Force] [-TargetDirectory <dir>]
.\install.ps1 -Uninstall [-Tool ...] [-TargetDirectory <dir>]
.\install.ps1 -Help
```

| Flag (Bash / PS) | Meaning |
|------------------|---------|
| `--tool <name>` / `-Tool` | Host tool to install. Accepts the **canonical tool ids** (see below) and a **comma-separated list** (`--tool codex,cursor`) to install several in one invocation. Each is installed independently into its own dir. Omitted → **auto-detect** (see detection algorithm); error if ambiguous. **Always overrides** detection. |
| `--version <v>` / `-Version` | Pin to a release version (e.g. `0.7.0`; with or without a leading `v`). Omitted → resolve **latest** GitHub Release. |
| `--from-bundle <path>` / `-FromBundle` | **Offline mode.** Install from a pre-downloaded per-profile tarball; **no network**. With a single `--tool`, `<path>` is the one tarball. With a comma-list, `<path>` is a **directory** containing the per-tool tarballs named per the feature-002 contract. Mutually exclusive with `--version`. |
| `--force` / `-Force` | Overwrite files that exist and differ (incl. protected root agent files — see FR11). Without it, a differing tracked file is skipped and a differing **root agent file** is written as `*.aid-new`. |
| `--update` / `-Update` | Re-install over an existing AID install, refreshing to `--version` or latest. Reads the manifest to know which tool(s)/version are installed. Equivalent to a normal install whose diff-handling defaults to the same skip/prompt semantics. |
| `--uninstall` / `-Uninstall` | Manifest-driven removal. With `--tool`, removes only that tool's manifest entries; without, removes **all** AID-installed entries. |
| `--target <dir>` / `-TargetDirectory`, or trailing positional `<target-dir>` | Install root. Default: current working directory (`.`). Must exist; a missing/invalid target is treated as a **usage error → exit 2** (see exit-code table). **Intentional change from `setup.sh:21` / `setup.ps1:18`**, which exit 1 for a non-existent target — the installer reclassifies it as a usage error for consistency with the exit-code table, not a faithful-parity behavior. |
| `-h`/`--help` / `-Help` | Print usage from the header block (per coding-standards §3c) and exit 0. |

**Canonical tool ids** (the `--tool` vocabulary — these are the contract strings 003/004 accept):
`claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`. These match `profiles/<id>/`
directory names exactly. (Accept case-insensitively; normalize to lower-case-hyphen. PowerShell
also accepts the PascalCase aliases `ClaudeCode`, `Codex`, `Cursor`, `CopilotCli`, `Antigravity`
for ergonomics, normalized to the canonical id.)

### Host-tool detection algorithm

When `--tool` is omitted, probe `<target-dir>` for per-tool project markers. Markers are the
**installed-tree roots** each tool owns (from `profiles/<tool>/` on disk and the `setup.sh`
per-tool blocks):

| Marker present in target | Detected tool |
|--------------------------|---------------|
| `.claude/` dir | `claude-code` |
| `.codex/` dir (and/or `.agents/`) | `codex` |
| `.cursor/` dir | `cursor` |
| `.github/` **with** `.github/agents/` or `.github/skills/` (AID's copilot subtree) | `copilot-cli` |
| `.agent/` dir | `antigravity` |

Algorithm:
1. Collect the set of tools whose marker is present.
2. **Exactly one** → use it (no prompt).
3. **Zero** → no AID install detected. Error: `cannot auto-detect host tool; pass --tool <name>`
   (exit code 2). Do **not** fall back to an interactive menu (the menu is removed; this keeps
   the CLI scriptable/non-interactive by default).
4. **More than one** → ambiguous. Error listing the candidates: `ambiguous host tool (found:
   codex, cursor); pass --tool <name>` (exit 2).
5. `--tool` always wins and skips detection entirely.

Note: `.github/` alone (without the AID copilot subtree) does **not** match — many repos have a
`.github/` for Actions/templates. Require an AID-specific child to avoid false positives.

### Artifact-consumption contract (boundary with feature-002)

The bootstrap obtains a **per-profile tarball** per tool. feature-002 **owns** the tarball
layout, naming, and checksums; this feature only consumes them via the contract below. The
implementation MUST treat the following as the agreed interface (any change is a feature-002
decision):

- **Release host / repo slug:** `github.com/AndreVianna/aid-methodology` (GitHub Releases).
- **Latest-version resolution (online, no `--version`):** GET
  `https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest`, read `tag_name`
  (strip leading `v`). Unauthenticated for a public repo. **Risk:** unauthenticated rate limit
  (see Risks). If `$GITHUB_TOKEN`/`$GH_TOKEN` is set, send it as a bearer token to raise the
  limit (optional, best-effort).
- **Asset URL pattern (online):**
  `https://github.com/AndreVianna/aid-methodology/releases/download/v<VERSION>/aid-<tool>-v<VERSION>.tar.gz`
  where `<tool>` is the canonical tool id. This naming is the feature-002 contract; do not
  invent a different scheme.
- **Checksums:** when online, also fetch `SHA256SUMS` from the same release and verify the
  downloaded tarball's sha256 against it before extracting (best-effort: warn and continue if
  `SHA256SUMS` is absent on older releases; **fail** on a mismatch). `--from-bundle` skips the
  download but, if a sibling `SHA256SUMS` is present next to the bundle, verifies against it.
- **Tarball internal layout (assumed from feature-002):** each tarball, when extracted, yields
  the **contents of `profiles/<tool>/`** as it should land in the target — i.e. the tool's dot
  dir(s) (`.claude/`, `.codex/`+`.agents/`, `.cursor/`, `.github/`, `.agent/`) plus the root
  agent file (`CLAUDE.md` for claude-code; `AGENTS.md` for the other four). It does **not**
  include `README.md` (presentation-only; `setup.sh` never copies it — REQUIREMENTS §4 Out of
  Scope) and need not include `emission-manifest.jsonl`. If feature-002 nests the payload under
  a top-level dir, the bootstrap strips that one leading component on extract.
- **Root-agent-file checksums are NOT taken from any shipped manifest.** feature-002's
  `emission-manifest.jsonl` (if present in a tarball) covers only the dot-dir install trees and
  carries **no record for the root agent file** (`CLAUDE.md`/`AGENTS.md`) — verified on disk
  against the profiles. The bootstrap therefore **ignores `emission-manifest.jsonl` entirely**
  and **self-computes** the root-agent-file `sha256` at install time from the exact bytes it is
  about to write (see §"Protect-on-diff" and §"Install manifest schema"). Whether or not 002
  ships the emission manifest is immaterial to this feature.

Fetch/extract toolchain: Bash uses `curl -fsSL` + `tar -xzf` into a `mktemp -d` staging dir;
PowerShell uses `Invoke-WebRequest`/`Invoke-RestMethod` + `tar.exe` (ships in Windows 10 1803+)
or `Expand-Archive` fallback, into a temp dir. Staging dir is removed on exit (trap /
`try/finally`). `curl` and `sha256sum`/`shasum` are listed in `infrastructure.md` Toolchain;
`tar` is **not** in that table and is treated as an **assumed OS-baseline tool** (present on
Unix/macOS; on Windows `tar.exe` has shipped since Win10 1803, with `Expand-Archive` as the
PowerShell-side fallback).

### Copy semantics (preserve setup.sh behavior)

Per-file copy mirrors `setup.sh::copy_file` / `setup.ps1::Copy-Item-Safe` exactly, extended to
record into the manifest:

1. Destination **absent** → copy; report `Copied: <dst>`; record path in manifest.
2. Destination **present and identical** (byte-compare: Bash `cmp -s`; PS `Get-FileHash`) →
   `Up to date: <dst>`; ensure path is in manifest (idempotent).
3. Destination **present and differs**:
   - `--force` → overwrite; `Updated: <dst>`; record/refresh.
   - else, for a **non-root-agent** tracked file → **skip** with `Skipped (differs; use
     --force): <dst>`. (Difference from `setup.sh`: the new installer is **non-interactive by
     default** — it does **not** prompt on `/dev/tty`. This makes `curl | bash` and CI usage
     safe. The old prompt-on-diff behavior is replaced by skip-or-`--force`. Root agent files
     follow FR11 below, not this generic branch.)
4. Directory trees are walked file-by-file (preserving empty dirs), exactly as
   `setup.sh::copy_dir` / `setup.ps1::Copy-Dir-Safe`.

The old multi-select **Option-A `AGENTS_COLLISION` last-writer-wins** branch is **removed** —
superseded by per-tool install (FR2) + protect-on-diff (FR11). A comma-list install runs the
tools sequentially; each tool's `AGENTS.md` write goes through the FR11 path, so the second
writer of a differing `AGENTS.md` triggers protect-on-diff rather than silent last-writer-wins.

### Protect-on-diff for root agent files (FR11) — authoritative algorithm

Applies **only** to the two root agent files: `<target>/CLAUDE.md` (claude-code) and
`<target>/AGENTS.md` (codex, cursor, copilot-cli, antigravity). Driven by the manifest's
`root_agent_files` checksums.

**Checksum provenance (authoritative):** the root-agent-file `sha256` is **always self-computed
by this feature at install time** — hashing the incoming bytes the bootstrap is about to write
(extracted from the tarball, before copy). It is **never** read from a shipped
`emission-manifest.jsonl` or any other feature-002 artifact (that manifest carries no root-file
record — see §"Artifact-consumption contract"). The self-computed value both populates
`manifest.root_agent_files[].sha256` and drives every comparison below.

**On install/update**, when about to write a root agent file `F` with incoming content `INC`:
1. Compute `inc_sha = sha256(INC)`.
2. If `F` does **not** exist on disk → write it; record `{path, tool, sha256: inc_sha}` in the
   manifest. `Copied: F`.
3. If `F` exists and `sha256(F) == inc_sha` → no-op; `Up to date: F`; ensure manifest entry
   exists with `inc_sha`.
4. If `F` exists and **`sha256(F)` equals a sha256 recorded for `F` in the manifest** (i.e. AID
   wrote the current on-disk file) → **AID owns it**; overwrite to `INC`; refresh manifest
   sha256 to `inc_sha`. `Updated: F`. (No `--force` needed — we are updating our own file.)
5. If `F` exists, differs from `INC`, **and is not recorded in the manifest** (or its on-disk
   sha matches no recorded sha) → **someone else owns it** (the user, or another tool whose
   `AGENTS.md` differs pre-FR12):
   - **Without `--force`:** do **not** overwrite. Write `INC` beside it as `F.aid-new` (e.g.
     `AGENTS.md.aid-new`). Warn: `<F> exists and was not written by AID; wrote incoming version
     to <F>.aid-new — review and merge, or re-run with --force to overwrite`. Record the
     **intended** entry as `{path, tool, sha256: inc_sha, status: "pending-merge"}` so a later
     `--force` or manual merge can reconcile; do **not** claim ownership of the on-disk `F`.
   - **With `--force`:** overwrite `F` with `INC`; record `{path, tool, sha256: inc_sha}`
     (ownership now AID's). `Updated: F (forced over existing)`.

**On uninstall**, for each `root_agent_files` entry `{path: F, sha256: recorded}`:
- If `F` exists and `sha256(F) == recorded` → AID's file is unchanged → **remove** it.
- Else (missing, or modified since AID wrote it, or now owned by another tool) → **leave in
  place**; report `Left in place (modified or not AID-owned): F`.

This is the rule that lets two AGENTS.md-writing tools coexist safely and never silently
clobbers the adopter's file. (Pre-FR12, installing a 2nd AGENTS.md tool over a 1st triggers the
`*.aid-new` branch because the two profiles' `AGENTS.md` differ by one line; once feature-006
makes them byte-identical, step 3 short-circuits and the warning only ever fires for the user's
own edits.)

### Install manifest schema (FR4 + FR3) — authoritative

**Location:** `<target>/.aid/.aid-manifest.json` (JSON; one file per target repo, shared across
tools installed into that repo). Rationale for JSON over the line-per-path sketch in the
research doc: root-agent checksums + per-tool grouping + version need structure; JSON is
parseable by Bash (via a small hand-rolled reader or `python3` when present — but the core must
**not require** python; a `jq`-free, grep/sed reader is the fallback) and trivially by
PowerShell (`ConvertFrom-Json`) and by the 003/004 wrappers. **Risk/decision flagged below**:
location collision with the adopter's own `.aid/` is possible; mitigated by the dotted filename
and by uninstall removing only this file.

**Schema:**
```json
{
  "manifest_version": 1,
  "aid_version": "0.7.0",
  "installed_at": "2026-06-04T12:00:00Z",
  "tools": {
    "claude-code": {
      "version": "0.7.0",
      "installed_at": "2026-06-04T12:00:00Z",
      "paths": [
        ".claude/skills/aid-interview/SKILL.md",
        ".claude/...",
        "CLAUDE.md"
      ],
      "root_agent_files": [
        { "path": "CLAUDE.md", "sha256": "<hex>", "status": "owned" }
      ]
    },
    "codex": {
      "version": "0.7.0",
      "installed_at": "...",
      "paths": [".codex/...", ".agents/...", "AGENTS.md"],
      "root_agent_files": [
        { "path": "AGENTS.md", "sha256": "<hex>", "status": "owned" }
      ]
    }
  }
}
```

Field contract (consumed by uninstall and by 003/004):
- `manifest_version` — schema version (currently `1`); readers reject unknown majors.
- `aid_version` — the version of the **most recent** install/update across any tool (FR3 repo
  marker; convenience). Per-tool `version` is the source of truth for that tool.
- `tools.<id>.paths` — **every** file this tool installed, **relative to `<target>`**, POSIX
  separators (PowerShell normalizes `\`→`/` on write). Uninstall removes exactly these (then
  prunes now-empty AID dirs), and the manifest file itself last (if no tools remain).
- `tools.<id>.root_agent_files[].sha256` — sha256 of the root agent file **as AID wrote it**,
  **computed by this installer** from the bytes it writes (never sourced from any shipped
  manifest); drives FR11 ownership checks on update and uninstall. `status`: `owned` |
  `pending-merge`.
- The manifest path (`.aid/.aid-manifest.json`) is **excluded** from a tool's own `paths`
  (it's installer metadata, not a profile file).

### Version recording (FR3)

The recorded version lives in the manifest (`aid_version` + per-tool `version`). For human
visibility and parity with the old `echo "Installed AID version: …"`, also write a plain marker
`<target>/.aid/.aid-version` containing the single line `<VERSION>` (the most-recent install).
This is a convenience read-surface (e.g. for `--update` and for users); the manifest remains
authoritative. Both are created under `<target>/.aid/` and removed by a full uninstall.

### Shared-core delegation contract (FR9 — what 003/004 call)

The "single canonical logic" (FR9) is the `lib/aid-install-core.sh` / `lib/AidInstallCore.psm1`
pair. **The npm (003) and PyPI (004) CLIs are thin wrappers that do NOT re-implement install
logic** — they parse their own CLI, then **shell out to the bootstrap** with the same flags.
Contract:

- **Delegation target:** the wrapper invokes `install.sh` (Unix) or `install.ps1` (Windows),
  passing through the normalized flags above (`--tool`, `--version`, `--from-bundle`, `--force`,
  `--update`, `--uninstall`, `--target`). On Windows a Node/Python wrapper detects the platform
  and calls `pwsh -File install.ps1 …` (or `powershell -File`); on Unix it calls `bash
  install.sh …`. The wrappers ship the `install.*` + `lib/*` files inside their package payload
  (003/004 own how they bundle these; this feature guarantees the scripts are
  invocation-stable and flag-stable).
- **Stable contract surface** (003/004 may rely on, and the implementation must keep stable):
  1. The flag names/spellings in the CLI table above.
  2. The canonical tool ids.
  3. Exit codes (below).
  4. The manifest path + schema.
  5. The `--from-bundle` semantics (single tarball vs directory of tarballs).
- **Non-goal:** 003/004 do **not** call individual core functions across the language boundary
  (Node/Python → Bash/PS internals). They call the **bootstrap CLI**. The internal function set
  of the core libs is a private implementation detail (free to change as long as the CLI
  contract holds). The sole "library reuse" is `install.sh`↔`lib/aid-install-core.sh` and
  `install.ps1`↔`lib/AidInstallCore.psm1` — i.e. dedup between the two bootstraps and any future
  in-language caller, **not** cross-language FFI.

### Cross-platform parity (FR9 / NFR cross-platform)

Bash and PowerShell cannot share code, so parity is a **maintained invariant**, not a shared
binary:
- The two core files expose the **same operation set** with the same observable behavior:
  identical user-visible message strings (`Copied:`, `Up to date:`, `Updated:`, `Skipped
  (differs; use --force):`, the FR11 warning, the ambiguity error), identical exit codes,
  identical manifest output (byte-identical JSON given the same inputs — same key order, 2-space
  indent, `\n` newlines, no trailing whitespace), identical sha256 of installed files.
- No WSL requirement: `install.ps1` runs in native PowerShell 5.1+ and joins paths with
  `Join-Path` (no hard-coded `\`), so it resolves on Windows and on `pwsh` on Linux CI.
- Hashing: Bash uses `sha256sum` (or `shasum -a 256` on macOS); PowerShell uses `Get-FileHash
  -Algorithm SHA256`. Both lower-case hex for manifest comparison. (Note: `setup.ps1` used MD5
  for its identical-check; the installer standardizes on **SHA256** everywhere for the manifest
  and identity checks.)

### Error handling, exit codes, idempotency

Exit codes (per coding-standards §3b/§4a: 0 ok, 1 generic, 2 usage, 3+ specific). 003/004
surface these:

| Code | Meaning |
|------|---------|
| 0 | Success (install/update/uninstall completed; "nothing to do" is success). |
| 1 | Generic runtime failure (extract failed, write failed). |
| 2 | Usage error (unknown flag, missing required value, ambiguous/undetectable tool, target dir does not exist, `--from-bundle` + `--version` together). **Note:** missing/invalid `--target` → 2 is an *intentional* reclassification (`setup.sh`/`setup.ps1` exit 1 for that) so all usage errors share one code; not a parity claim. |
| 3 | Network/fetch failure (download or `/latest` resolution failed and no `--from-bundle`). |
| 4 | Checksum verification failed (tarball sha256 ≠ `SHA256SUMS`). |
| 5 | Protect-on-diff blocked a root agent file and `--force` was not given (install otherwise completed for other files; emit a clear summary). *Decision flagged below: whether this is a hard non-zero exit or a 0-with-warning — default here is exit 5 so CI notices, overridable.* |
| 6 | Uninstall found no manifest (nothing installed). |

Idempotency: re-running install with the same version is a no-op beyond `Up to date:` lines;
the manifest converges (paths de-duplicated; checksums refreshed only when AID owns the file).
`--update` to the same version is a no-op; to a new version, re-copies changed files and updates
the manifest version. Uninstall is idempotent (a second run hits exit 6).

### Testing approach

Mirror the existing `tests/canonical/test-*.sh` conventions (auto-discovered by
`tests/run-all.sh`; `source ../lib/assert.sh`; `mktemp -d` targets; exit 0/1) and the
`test-setup-ps1.sh` **skip-if-no-`pwsh`** pattern.

- `tests/canonical/test-install.sh` — drives `install.sh` against temp targets. Cases (mapping
  the SU-series): fresh install per tool (`.claude/`+`CLAUDE.md`; `.codex/`+`.agents/`+
  `AGENTS.md`; `.cursor/`; `.github/`; `.agent/`); byte-fidelity of installed files vs
  `profiles/<tool>/` (reuse SU06f/SU14 patterns); idempotent re-install → `Up to date:`;
  `--force` over a locally-edited file restores source; **manifest written** with correct paths
  + version + root_agent sha; **uninstall** removes exactly the manifested paths and leaves the
  repo pre-install-clean; **protect-on-diff**: pre-place a user `AGENTS.md`, install codex → no
  overwrite, `AGENTS.md.aid-new` created, exit 5; with `--force` → overwritten; **uninstall
  safety**: modify an AID-owned `AGENTS.md` post-install, uninstall → left in place; comma-list
  `--tool codex,cursor` installs both, second AGENTS.md write triggers protect-on-diff
  (pre-FR12); auto-detect (single marker → used; two markers → exit 2 ambiguous; none → exit 2);
  usage errors (unknown flag → 2, missing target → 2). Network paths are exercised via
  `--from-bundle` using a locally-built fixture tarball (no live GitHub calls in CI); the
  online `/latest`+download path is covered by a thin function-level test that can be stubbed
  (or marked network-gated/skipped in CI) to avoid rate-limit flakiness.
- `tests/canonical/test-install-ps1.sh` — thin `pwsh` wrapper, **SKIP (exit 0) when `pwsh`
  absent**. On Linux CI exercises the platform-independent paths (arg parsing, detection,
  manifest JSON shape parity, message-string parity, `--from-bundle` extract via `tar`); asserts
  the same message strings and exit codes as the Bash suite to enforce FR9 parity. (The
  CI `canonical-tests` job asserts `pwsh` IS present, so the skip never silently fires there.)
- Update the two suites' filenames/refs and remove `test-setup.sh`/`test-setup-ps1.sh`.

### Risks / open questions (flag for /aid-specify Q&A where noted)

1. **GitHub API rate limit (research-flagged, UNCERTAIN).** Unauthenticated
   `/releases/latest` is limited (~60 req/hr/IP per general knowledge). For `curl | bash`
   one-liners behind shared NAT this could throttle. Mitigation: optional `$GITHUB_TOKEN`
   bearer; recommend `--version` for reproducible/CI installs; `--from-bundle` avoids the API
   entirely. **Verify the live limit before build.**
2. **Manifest location collision with adopter `.aid/`.** AID itself stores work under `.aid/`;
   an adopter installing AID into a repo that *also* uses AID could have a populated `.aid/`.
   The manifest is a single dotted file `.aid/.aid-manifest.json` and uninstall removes only it
   + `.aid/.aid-version` (never the whole `.aid/` dir), so collision risk is contained — but
   **confirm** `.aid/.aid-manifest.json` is the desired path vs. e.g. a top-level
   `.aid-manifest.json`. *(Q&A candidate.)*
3. **Manifest JSON parsing in pure Bash with no jq/python guaranteed.** NFR forbids new runtime
   deps. The reader must be a small hand-rolled parser (the schema is flat enough) or opportunistically
   use `python3`/`jq` if present with a pure-Bash fallback. **Confirm** acceptable complexity vs.
   switching the manifest to a simpler line-oriented format. *(Q&A candidate — recommend keeping JSON; readers only need `tools.<id>.paths`, per-tool `version`, and `root_agent_files`.)*
4. **Pre-FR12 AGENTS.md tool-vs-tool diffs.** Until feature-006 lands, installing a 2nd
   AGENTS.md-writing tool over a 1st **will** hit protect-on-diff and write `*.aid-new` (the
   profiles differ by one path line — verified on disk: codex/cursor/copilot-cli/antigravity
   `AGENTS.md` have 4 distinct sha256). This is **correct, not a bug**, but documentation must
   set expectations until 006 normalizes them. No blocker for 001.
5. **Exit-5 policy for blocked protect-on-diff** (above) — hard non-zero vs. 0-with-warning.
   Default exit 5; confirm with owner. *(Q&A candidate.)*
6. **Windows `tar` availability.** `tar.exe` ships in Windows 10 1803+; older hosts need the
   `Expand-Archive` fallback (which handles `.zip`, not `.tar.gz`). **Confirm with feature-002**
   whether to also publish a `.zip` per profile for old-Windows offline installs, or require
   `tar.exe`. *(Cross-feature Q&A with 002.)*

---

## CLI Evolution — persistent global `aid` CLI

> Added by `/aid-architect` (2026-06-04). **User-approved new direction, folded into
> delivery-001 — no re-interview.** This section evolves the one-shot bootstrap above into a
> persistent, globally-installed **`aid` CLI** that operates on the AID project in the current
> working directory. Everything above this line remains the **per-tool install engine**; this
> section adds the **CLI surface, the global install layout, PATH wiring, and the bootstrap
> reshape** on top of it. Where this section and the original CLI surface conflict, **this
> section governs** (the conflicts are enumerated in §"Resolved conflicts with the original
> spec"). The reuse mandate is strict: the install/update/uninstall/manifest/protect-on-diff
> engine in `lib/aid-install-core.sh` + `lib/AidInstallCore.psm1` is reused **unchanged** except
> for the small, enumerated additions in §"Core additions". FR9 (Bash↔PowerShell parity), FR11
> (protect-on-diff), the manifest schema, and the exit-code table are **preserved and extended,
> not broken**.

### Motivation (what changes and why)

The original bootstrap is a **one-shot script** fetched per use (`curl … | bash` /
`irm … | iex`). Two problems motivate the evolution:

1. **No persistent command.** An adopter who wants to add a second tool, update, or uninstall
   later must re-fetch and re-pipe the script and re-remember its flags. There is no `aid` on
   their PATH.
2. **The PowerShell `irm | iex` arg problem.** `irm <url> | iex` cannot forward arguments to the
   downloaded script (iex evaluates a string; positional/named args do not thread through
   cleanly). The original spec works around this with `$env:AID_TOOL` env-var input only.

The evolution **dissolves both**: the fetched script becomes an **arg-free bootstrap** that
installs a persistent `aid` command into a global location and wires it onto PATH. After
bootstrap, the adopter runs `aid add codex`, `aid status`, `aid update`, `aid uninstall`
directly — no re-fetch, no `iex` arg threading. A one-line convenience chain
(`curl … | bash -s -- add codex`, or `$env:AID_TOOL='codex'` for the PowerShell side) still lets
first-run bootstrap-then-add in a single command.

### Global install layout (the `aid` CLI itself)

The **`aid` CLI is a global, per-user tool** (installed once per machine), distinct from the
**per-project AID files** it installs (the profile trees + `.aid/.aid-manifest.json` in each
adopter repo). Do not confuse the two install locations.

**Unix (Linux / macOS / git-bash):** `~/.aid/` (override with `$AID_HOME`)
```
~/.aid/
  bin/aid                    # dispatcher (Bash); the file added to PATH
  lib/aid-install-core.sh    # the shared core, copied verbatim from the release
  VERSION                    # the CLI's own version (== the release it was installed from)
```
- Add `~/.aid/bin` to PATH via the user's shell profile (see §"PATH wiring (Unix)").
- `bin/aid` is `chmod +x`. It locates its sibling core at `$AID_HOME/lib/aid-install-core.sh`
  (no network needed for local subcommands; only `add`/`update` online fetch the profile
  tarball, exactly as today).

**Windows (native PowerShell / cmd.exe):** `%LOCALAPPDATA%\aid\` (override with `$env:AID_HOME`)
```
%LOCALAPPDATA%\aid\
  aid.cmd                    # cmd.exe shim → forwards to aid.ps1 via pwsh/powershell
  aid.ps1                    # dispatcher (PowerShell)
  lib\AidInstallCore.psm1    # the shared core module, copied verbatim
  VERSION
```
- Two entry files so `aid` resolves in **both** `cmd.exe` and `pwsh`/`powershell`: `aid.cmd` is
  what cmd.exe/Explorer find on PATH; it execs `pwsh -NoProfile -File "%~dp0aid.ps1" %*` (falling
  back to `powershell` when `pwsh` is absent). Inside `pwsh`, `aid` resolves to `aid.cmd` (which
  re-enters PowerShell) — acceptable; alternatively a `aid` function/alias may be added to the
  PowerShell profile, but the `.cmd` shim is the MUST and the profile alias is a SHOULD.
- Add `%LOCALAPPDATA%\aid` to the **USER** PATH (see §"PATH wiring (Windows)").

**Rationale for `~/.aid` vs `~/.local/bin`:** keeping the CLI, its core lib, and VERSION
together under one self-contained, removable dir makes `aid self-uninstall` a single `rm -rf`
plus one PATH-block removal, and avoids scattering files into shared bin dirs. Only the
`bin/`/`%LOCALAPPDATA%\aid` entry goes on PATH.

### Subcommand surface (authoritative)

The dispatcher parses `aid <subcommand> [args] [flags]`. The **flags** are the existing
engine flags, unchanged in spelling (§"CLI surface" above): `--version <v>` / `-Version`,
`--from-bundle <path>` / `-FromBundle`, `--force` / `-Force`, `--target <dir>` /
`-TargetDirectory`, `--verbose` / `-Verbose`, plus the new `--no-path` (bootstrap/self-install
only, see PATH wiring). Env-var fallbacks (`AID_TOOL`, `AID_VERSION`, `AID_TARGET`, `AID_FORCE`,
`AID_VERBOSE`) are **preserved** and apply to the subcommand they map to.

The **target project** for every project-scoped subcommand defaults to the **current working
directory** (`--target`/`-TargetDirectory`/`AID_TARGET` override, exactly as today). The CLI
operates on `./.aid/.aid-manifest.json` of that cwd.

| Subcommand | Maps to (engine) | Behavior | Exit codes |
|---|---|---|---|
| `aid` (bare) | — | Alias for `aid status`. | per `status` |
| `aid status` | manifest reader (new thin surface) | Print the AID state of the cwd project read from `./.aid/.aid-manifest.json` (see §"`aid status` output"). **No network.** | 0 if a manifest exists; **7** "not an AID project here" if absent (see exit-code addition) |
| `aid add <tool>[,<tool>…]` | `MODE=install` (`install_tool`) | Install/add tool(s) into the cwd project. Identical to today's default install path; `<tool>` list replaces `--tool`. Auto-detect applies **only** when `<tool>` is omitted AND `AID_TOOL` is unset (rare for `add`; mainly for the bootstrap convenience chain). | 0/1/2/3/4/**5** as today |
| `aid remove <tool>[,…]` | `MODE=uninstall` with tool list (`uninstall_tool` per tool) | Remove specific tool(s) from the cwd project. Per-tool manifest removal; protect-on-diff uninstall-safety (FR11) honored on root agent files (removed only if still checksum-matches what AID wrote). `<tool>` is **required** (≥1). | 0/1/2; **6** if no manifest |
| `aid update [<tool>…]` | `MODE=update` (`install_tool` over existing) | Update installed tool(s) to `--version`/`-Version` or latest. **No tool args → update every tool currently in the manifest.** Reads manifest for installed set + versions. | 0/1/2/3/4/5; **6** if no manifest |
| `aid uninstall` | `MODE=uninstall`, no tool list (all tools) | Remove AID **entirely** from the cwd project (today's full uninstall: all manifested tools, prune empty AID dirs, remove `.aid/.aid-manifest.json` + `.aid/.aid-version`). Does **not** touch the global `aid` CLI. | 0; **6** if no manifest |
| `aid version` | — | Print the **CLI's own** version (from `$AID_HOME/VERSION`) and exit 0. Distinct from `--version`, which pins a profile release. | 0 |
| `aid help` / `aid -h` / `aid --help` | usage block | Print usage and exit 0. `aid help <subcommand>` MAY print subcommand-specific usage (SHOULD). | 0 |
| `aid self-uninstall` | new (global teardown) | Remove the global `aid` CLI: delete `$AID_HOME` and the PATH-wiring block/entry. Does **not** touch any per-project AID install (those are removed via `aid uninstall` per project). Prompts unless `--force`/`-Force` or `AID_FORCE`. **MUST.** | 0; 1 on partial teardown |
| `aid self-update` | new (global upgrade) | Re-fetch the latest (or `--version`) release and replace `$AID_HOME/bin`+`lib`+`VERSION` in place; idempotent; no duplicate PATH entries. **SHOULD** (the bootstrap chain re-run achieves the same; provide as ergonomic sugar). | 0/1/3/4 |

**Unknown subcommand** → usage error, exit **2**, message `unknown command: <x> (see 'aid help')`.

**Bash↔PowerShell subcommand parity (FR9):** `aid.ps1`'s dispatcher accepts the **same
subcommand words** (`status`, `add`, `remove`, `update`, `uninstall`, `version`, `help`,
`self-uninstall`, `self-update`) and the same `<tool>` list grammar; it normalizes PascalCase
tool aliases as the engine already does. Message strings, output format, and exit codes are
byte-for-byte identical to the Bash dispatcher (enforced by the parity test, §Testing).

#### `aid status` output (authoritative format)

`aid status` reads `./.aid/.aid-manifest.json` (and `./.aid/.aid-version`) and prints:

```
AID <aid_version>  (project: <cwd>)
Installed tools:
  claude-code   v0.7.0   root: CLAUDE.md (owned)
  codex         v0.7.0   root: AGENTS.md (owned)
```
- Header line: `aid_version` from the manifest + the resolved project dir.
- One line per tool in `tools.<id>`: `<id>` (padded), `v<version>`, and root-agent status
  rendered as `root: <file> (<status>)` where `<status>` is the `root_agent_files[].status`
  (`owned` | `pending-merge`); tools with no root agent file omit the `root:` segment.
- **Not-installed case** (no manifest at cwd): print to **stdout**
  `No AID install found in <cwd>. Run 'aid add <tool>' to install.` and exit **7**.
- `aid status --verbose`/`-Verbose` additionally lists each tool's installed file count (from
  `tools.<id>.paths` length). No new manifest fields are required — `status` is a **pure
  reader** over the existing schema.

This is the only genuinely new read-surface; it reuses `manifest_read_tool_version`,
`manifest_read_root_agent_status`, `manifest_read_tool_paths`, and a new tiny
`manifest_list_tools` helper (the tool-id enumeration already implemented inline in `install.sh`
`_resolve_tools` and the PS equivalent — promote it to a named core function for reuse).

### Bootstrap reshape (arg-free CLI installer)

`install.sh` / `install.ps1` (the files fetched via `curl`/`irm`) are **repurposed** from
"install AID into this repo" to "**install the `aid` CLI into the global location and wire
PATH**". This is the change that dissolves the `irm | iex` arg problem.

**New default behavior (no args):**
1. Resolve the release version (`--version`/`-Version`/`AID_VERSION` or latest GitHub release —
   reuses `resolve_version`).
2. Fetch (or use sibling, or `--from-bundle`) the **core lib** for that version (reuses the
   existing fail-closed checksum-verified lib fetch — unchanged).
3. Create `$AID_HOME` (`~/.aid` / `%LOCALAPPDATA%\aid`); write `bin/aid`(+`aid.cmd`/`aid.ps1`),
   copy the verified `lib/*`, write `VERSION`. **Idempotent**: re-running upgrades these files in
   place (the dispatcher and lib are overwritten; VERSION refreshed).
4. Wire PATH (see below) unless `--no-path`/`-NoPath`/`AID_NO_PATH=1`.
5. Print the post-install hint: `aid CLI v<ver> installed to <AID_HOME>. Open a new shell, or
   run: <source-or-refresh-hint>. Then: aid add <tool>`.

**Convenience chain (bootstrap-then-act in one line):** trailing args after the bootstrap are
interpreted as **an `aid` subcommand to run immediately after install**:
- Bash: `curl -fsSL <url> | bash -s -- add codex` → bootstrap installs the CLI, then execs
  `aid add codex` in the **current cwd** (using the just-installed `bin/aid`, so PATH-refresh is
  not required for this first action). `AID_TOOL=codex curl … | bash` is equivalent (env-var
  fallback → `add codex`).
- PowerShell: because `irm | iex` cannot forward args, the supported first-run form is
  `$env:AID_TOOL='codex'; irm <url> | iex` → bootstrap installs the CLI, then runs
  `aid add codex`. (A downloaded-then-invoked `install.ps1 add codex` also works for users who
  save the file; the env-var form is the documented `iex` path.)
- If **no** trailing subcommand/`AID_TOOL` is given, the bootstrap installs the CLI **only**
  (no project install) and prints the hint. This is the clean "install the tool, I'll add
  profiles later" path.

**Idempotent re-bootstrap:** re-running the bootstrap on a machine that already has `aid`
**upgrades in place** — overwrites `bin`/`lib`/`VERSION`, and re-runs PATH wiring which is itself
idempotent (no duplicate profile blocks / no duplicate PATH entries — see wiring sections).

### PATH wiring (Unix) — authoritative

Goal: add `$AID_HOME/bin` to PATH **idempotently**, in a **clearly-marked, removable block**, in
the right profile file, without clobbering the user's config.

- **Profile detection (in order):** honor `$SHELL`/login shell — for **zsh** target
  `~/.zshrc`; for **bash** target `~/.bashrc` (Linux) or `~/.bash_profile` (macOS login bash);
  fall back to `~/.profile` when neither is identifiable. If the chosen file does not exist,
  create it. (Detect, don't guess: probe `$SHELL` basename; `ZDOTDIR` honored for zsh.)
- **Idempotent marked block** appended once:
  ```
  # >>> aid CLI >>>
  export PATH="$HOME/.aid/bin:$PATH"
  # <<< aid CLI <<<
  ```
  Before appending, the wiring **greps for the `# >>> aid CLI >>>` marker**; if present, it
  **replaces** the block (in place) rather than appending a second one. This guarantees a
  re-bootstrap never duplicates the entry.
- **`--no-path` / `-NoPath` / `AID_NO_PATH=1`** skips the profile edit entirely and prints a
  manual instruction (`add "$HOME/.aid/bin" to your PATH`).
- **Refresh hint:** PATH edits don't affect the *current* shell. Print:
  `Open a new shell, or run: export PATH="$HOME/.aid/bin:$PATH" (or: source <profile>)`. The
  convenience chain's first `aid` action bypasses this by invoking `bin/aid` directly.
- **Removal (`self-uninstall`):** delete the marked block by matching the `>>> aid CLI >>>` …
  `<<< aid CLI <<<` fence (sed range delete on the detected profile(s); tolerate absence).

### PATH wiring (Windows) — authoritative

- Add `%LOCALAPPDATA%\aid` to the **USER** PATH via
  `[Environment]::SetEnvironmentVariable('Path', <new>, 'User')`. **Idempotent:** read the
  current User Path, split on `;`, and **only append if the entry is not already present**
  (case-insensitive compare; ignore empty segments) — no duplicate entries on re-run.
- Edit the **User** scope only (never Machine — no admin required, no system-wide mutation).
- **Refresh:** the new PATH applies to **new** processes only; the current session is updated
  in-process (`$env:Path = "$env:Path;$dir"`) so the convenience-chain `aid add …` works
  immediately, but the user is told to open a new terminal for persistence to take effect
  elsewhere.
- **`-NoPath` / `AID_NO_PATH=1`** skips the SetEnvironmentVariable call and prints the manual
  instruction.
- **Windows PATH length:** the User PATH has a practical length ceiling (see Risks). The wiring
  appends a **single short entry**; if the resulting User Path would exceed a safe bound, warn
  and print the manual instruction rather than truncating.
- **Removal (`self-uninstall`):** read User Path, remove the `%LOCALAPPDATA%\aid` segment
  (case-insensitive), write back; tolerate absence.

### Self-uninstall (global CLI teardown) — authoritative

`aid self-uninstall` (MUST):
1. Confirm (prompt) unless `--force`/`-Force`/`AID_FORCE`.
2. Remove the PATH wiring (the marked block on Unix; the User-Path segment on Windows).
3. Delete `$AID_HOME` (`~/.aid` / `%LOCALAPPDATA%\aid`) recursively.
4. Print: `aid CLI removed. Per-project AID installs are unaffected; run 'aid uninstall' in a
   project before removing the CLI if you also want to remove those` — i.e. **self-uninstall
   does not walk projects**; it only removes the global tool. Exit 0 (1 on partial teardown, with
   a clear note about what remained).

The bootstrap script retains a **`--uninstall-cli` / `-UninstallCli`** equivalent (for users who
still have the fetched script but no `aid` on PATH) that performs the same teardown — so the
global tool is removable even if PATH wiring failed.

### Core additions (the only changes to the reused engine)

The engine in `lib/aid-install-core.sh` / `lib/AidInstallCore.psm1` is reused **unchanged**
except for these **additive, non-breaking** helpers (no existing function signature or behavior
changes; FR11/manifest/exit-engine untouched):

1. `manifest_list_tools <manifest>` (Bash) / `Get-ManifestToolList` (PS) — enumerate
   `tools.<id>` keys. (Promotes logic already inlined in `install.sh::_resolve_tools` and the PS
   equivalent; `aid status` and `aid update`/`aid uninstall`-all reuse it.)
2. `aid_status <target>` (Bash) / `Get-AidStatus` (PS) — render the §"`aid status` output"
   block from the manifest. Pure reader; no writes.
3. PATH-wiring + global-layout helpers — these live in the **bootstrap/dispatcher**, not the
   install engine (install-engine purity is preserved): `_wire_path_unix`,
   `_unwire_path_unix`, `_install_global_cli`, `_self_uninstall` (Bash) and the PS analogues.
   They are new code, but they sit **outside** the manifest/copy/protect-on-diff engine.

Everything else — `install_tool`, `uninstall_tool`, `copy_file`, `copy_dir`,
`_copy_root_agent_file`, all `manifest_*` read/write functions, `fetch_tarball`,
`extract_tarball`, `resolve_version`, the fail-closed lib-fetch — is **called as-is**. The `aid`
dispatcher is a thin argument-shaper that translates `aid add codex` → the same internal calls
`install.sh --tool codex` makes today.

### Exit-code additions (extends, does not break, the table above)

The original table (0–6) is preserved with identical meanings. The CLI adds:

| Code | Meaning |
|------|---------|
| 7 | **`aid status` (or any project-scoped read) found no AID install in the cwd** — "not an AID project here". Distinct from 6 (uninstall-with-no-manifest) so `status` and `uninstall`/`remove` report the "nothing here" condition with the verb-appropriate code. `aid remove`/`aid update`/`aid uninstall` keep **6** (their semantics are uninstall-family); only the read-only `status` uses **7**. |

No existing code's meaning changes. `aid add` failures map to the same 1–5 as `install.sh`
today; `aid remove`/`update`/`uninstall` map to the same as `--uninstall`/`--update` today.

### Boundary note — ripple to features 003 (npm) & 004 (PyPI)

The CLI evolution changes what "install AID" means for the npm/PyPI wrappers, and this is a
**flagged cross-feature implication**, not a change made here:

- **Today (003/004 SPECs):** the wrappers ship a bin named **`aid-installer`** that vendors
  `install.sh`/`install.ps1` + `lib/*` and **shells out to do a per-repo install** (feature-003
  §S2–S5; feature-004 §"flag translation"). They do **not** put an `aid` command on PATH; the
  user runs `npx aid-installer …` / `pipx run aid-installer …` per invocation.
- **Implication of this evolution:** the reshaped bootstrap installs a persistent **`aid`**
  command. The npm/PyPI channels SHOULD converge so that `npm i -g @aid/installer` /
  `pipx install aid-installer` **put the `aid` command onto PATH** (npm bin → `aid`; the Python
  console-script entry point → `aid`), making the three channels (curl, npm, PyPI) deliver the
  **same `aid` CLI** rather than three differently-named one-shot wrappers. feature-003's S8
  open question #4 ("support `npm i -g`") and feature-004's pipx-install path already anticipate
  a global install; this evolution makes that the **primary** shape and renames the surfaced
  command to `aid`.
- **This feature does NOT rewrite 003/004.** It only (a) keeps the **delegation contract**
  stable (flag names, tool ids, manifest schema, exit codes, `--from-bundle` semantics — all
  preserved), and (b) records this implication so 003/004 are re-specified separately (their
  deliveries 002/003 are downstream and out of scope for delivery-001). **Action for 003/004
  owners:** rename the published binary/entry-point to `aid`, target a global install, and have
  it dispatch the subcommand surface above (or continue to delegate to the bootstrap's global
  install). Tracked as a cross-feature note; no edit to 003/004 SPECs in this change.

### Resolved conflicts with the original spec

| # | Original spec said | CLI evolution says | Resolution |
|---|---|---|---|
| C1 | Bootstrap (`install.sh`) **installs profiles into the target repo** by default (no mode flag → install). | Bootstrap **installs the global `aid` CLI** by default (no args → install CLI + wire PATH). | The **arg-free default changes meaning**. Project install now happens via `aid add <tool>` (or the `curl … \| bash -s -- add <tool>` convenience chain). The original "default = install profiles" is **superseded**; the engine that did it is unchanged and is now reached through `aid add`. Tests that invoked `install.sh --tool X` to install profiles are reframed as `aid add X` (and a back-compat note: `install.sh --tool X` MAY be retained as a hidden alias for one release to avoid breaking the existing test fixtures — SHOULD, decided at IMPLEMENT). |
| C2 | Modes selected by `--update`/`--uninstall` flags on one script. | Modes are **subcommands** of `aid` (`add`/`remove`/`update`/`uninstall`). | The engine modes are unchanged; only the **surface** moves from flags to subcommands. The bootstrap still accepts the flag forms internally for the convenience chain and for 003/004 delegation stability (the delegation contract's flag spellings are preserved). |
| C3 | `--tool <name>` carries the tool list. | `aid add <tool>[,…]` / `aid remove <tool>[,…]` carry the list **positionally**; `--tool`/`AID_TOOL` remain as fallbacks. | Positional tool args are the CLI ergonomic; `--tool`/`-Tool`/`AID_TOOL` still work (engine reads them) so the delegation contract and env-var inputs are intact. |
| C4 | Exit codes 0–6; `status` did not exist. | Adds exit **7** for `aid status` "not an AID project here". | Additive; no 0–6 meaning changes (see §"Exit-code additions"). |
| C5 | "All new files live at the AID repo root … `lib/` for the core." (component layout) | Adds a **global install layout** (`~/.aid` / `%LOCALAPPDATA%\aid`) and **dispatcher files** (`bin/aid`, `aid.cmd`, `aid.ps1`). | The repo-root `install.sh`/`install.ps1`/`lib/*` are the **source/bootstrap**; the global layout is the **installed** form. Both coexist: the repo files are what the release ships and what the bootstrap deploys into `$AID_HOME`. |

No contradiction is left unresolved. The single load-bearing decision flagged for the user at
IMPLEMENT is **C1's back-compat alias** (retain `install.sh --tool X` as a hidden
profile-install alias for one release, or hard-cut to `aid add`) — recommend **retain as hidden
alias** to keep delivery-001's existing test fixtures green while the CLI surface stabilizes.
