---
kb-category: primary
source: hand-authored
objective: AID's own source-code conventions -- shell, PowerShell, Python, and JS/Node rules mined from the actual scripts, with project examples and the security conventions a contributor must honor.
summary: Read this before writing or reviewing any AID script (Bash, PowerShell, Python, Node) to follow the project's real conventions for headers, error handling, naming, exit codes, cross-platform compatibility, and download integrity.
sources:
  - .claude/aid/scripts/config/read-setting.sh
  - .claude/aid/scripts/execute/writeback-state.sh
  - .claude/aid/scripts/kb/kb-citation-lint.sh
  - lib/aid-install-core.sh
  - lib/AidInstallCore.psm1
  - .claude/skills/generate-profile/scripts/aid_profile.py
  - .claude/aid/scripts/summarize/contrast-check.mjs
  - tests/canonical/ps51-compat-check.ps1
tags: [C3, conventions, shell, powershell, python, javascript, security, exit-codes]
see_also: [authoring-conventions.md, module-map.md, test-landscape.md]
owner: architect
audience: [developer, reviewer]
contracts:
  - "Shipped PowerShell is Windows-PowerShell-5.1 compatible and ASCII-only"
  - "Install-core exit codes: 0 ok, 1 runtime, 2 usage, 3 fetch, 4 checksum, 6 uninstall-no-manifest"
  - "Every script carries a header comment block (Purpose/Usage/Exit codes)"
changelog:
  - 2026-06-25: Initial authoring (aid-discover brownfield deep-dive / Analyst)
---

# Coding Standards

These are AID's **own** source-code conventions, mined from the scripts as they
actually are -- not general best practice. AID is polyglot by necessity: the same
install logic exists in Bash and PowerShell (it must run on every host), and it
ships through both npm and PyPI. The rules below keep those language twins
consistent and the shipped scripts portable.

> Scope note: this doc is about **source code** (shell/PS/Python/Node). The
> methodology's *artifact-authoring* rules (KB docs, reviewer ledger, frontmatter,
> content-isolation) live in [authoring-conventions.md](authoring-conventions.md).
> Do not look for KB-authoring rules here.

## Contents

- [File Header Convention](#file-header-convention)
- [Naming Conventions](#naming-conventions)
- [Shell (Bash) Conventions](#shell-bash-conventions)
- [PowerShell Conventions](#powershell-conventions)
- [Python Conventions](#python-conventions)
- [JavaScript / Node Conventions](#javascript--node-conventions)
- [Error Handling](#error-handling)
- [Exit Codes](#exit-codes)
- [Logging and Output](#logging-and-output)
- [Configuration Access](#configuration-access)
- [Security Conventions](#security-conventions)
- [Observed Inconsistencies](#observed-inconsistencies)
- [Conventions](#conventions)
- [Change Log](#change-log)

---

## File Header Convention

Every executable script opens with a structured header comment block, not just a
shebang. The block states **Purpose**, **Usage** (with examples), **Exit codes**,
and (for libraries) a **Provides:** function index.

Evidence: `read-setting.sh` opens with `Purpose / Usage / Examples / Exit codes /
Output / Format` sections; `aid-install-core.sh` and `AidInstallCore.psm1` open
with a `Provides:` block listing every public function and its signature;
`aid_profile.py` opens with `Purpose / Schema / Usage / Requirements`.

- **Rule:** a new script MUST carry a header block documenting at minimum its
  purpose, invocation, and (if it can fail) its exit codes.
- The `-h`/`--help` handler typically re-prints a slice of this header (see
  `read-setting.sh` HELP heredoc; `kb-citation-lint.sh` `sed -n '2,20p' "$0"`).

---

## Naming Conventions

| Element | Convention | Example | Evidence |
|---------|-----------|---------|----------|
| Script files | kebab-case + extension | `read-setting.sh`, `build-kb-index.sh` | `canonical/aid/scripts/**` |
| Python modules | snake_case | `aid_profile.py`, `render_lib.py` | `generate-profile/scripts/` |
| Node modules | kebab-case + `.mjs` (ESM) | `contrast-check.mjs`, `validate-visuals.mjs` | `scripts/summarize/` |
| PowerShell modules | PascalCase + `.psm1` | `AidInstallCore.psm1` | `lib/` |
| Bash functions | snake_case | `lookup_list`, `abs_path`, `fetch_tarball` | `read-setting.sh`, `aid-install-core.sh` |
| Bash variables | UPPER_SNAKE (globals), lower (locals) | `SETTINGS_FILE`, `HAS_DEFAULT`; `local p`, `local file` | `read-setting.sh` |
| PowerShell functions | `Verb-AidNoun` (approved verb) | `Get-Sha256File`, `Install-AidTool`, `Write-AidManifest` | `AidInstallCore.psm1` |
| Python functions | snake_case | `load_profile`, `validate`, `_parse_model_tiers` | `aid_profile.py` |
| Python dataclasses | PascalCase | `Profile`, `CapabilitiesConfig`, `ModelTierSimple` | `aid_profile.py` |
| Private Python helpers | leading underscore | `_parse_capabilities`, `_KNOWN_TIERS` | `aid_profile.py` |
| Settings keys | snake_case, dotted path | `review.minimum_grade`, `execution.max_parallel_tasks` | `settings.yml` |

**Domain prefix:** all AID-delivered content (skills, agents) is namespaced with an
`aid-` prefix (`aid-discover`, `aid-architect`); install-core functions use an
`Aid` infix (`Install-AidTool`). This is the content-isolation cornerstone -- see
[authoring-conventions.md](authoring-conventions.md) for the full namespacing rule.

---

## Shell (Bash) Conventions

- **Shebang:** `#!/usr/bin/env bash` (not `/bin/sh`; Bash features are used).
- **Strict mode:** `set -euo pipefail`. The dominant choice -- ~20 of the canonical
  scripts use it; a few read-only linters use `set -uo pipefail` (no `-e`) when they
  intentionally tolerate non-zero from `grep`/`awk` (e.g. `kb-citation-lint.sh`).
- **`set -e` safety on expected non-zero:** subshell helpers that may legitimately
  return non-zero append `|| true` so `set -e` does not abort. Example
  (`read-setting.sh` `lookup()`):
  ```bash
  awk -v section="$section" -v key="$key" '...' "$file" || true
  ```
- **Argument parsing:** a `while [[ $# -gt 0 ]]; do case "$1" in ... esac done`
  loop with `shift 2` per flag (see `read-setting.sh`). Unknown flag -> message to
  stderr + `exit 2`.
- **YAML/text parsing without binaries:** scripts parse the simple, flat YAML AID
  stores with `awk`, avoiding a hard `yq`/`python` dependency
  (`read-setting.sh` `lookup`/`lookup_list`). Prefer this for AID's own simple
  configs; defer to `yq` only for genuinely nested YAML.
- **Portability fallbacks:** capability is probed before use --
  `command -v realpath >/dev/null 2>&1` with a pure-shell fallback (`abs_path` in
  `read-setting.sh`) because `realpath`/`readlink` flags differ across GNU/BSD/macOS.

---

## PowerShell Conventions

The shipped PowerShell (`install.ps1`, `bin/aid.ps1`, `lib/AidInstallCore.psm1`)
must run on a **bare Windows box**, where the default shell is Windows PowerShell
5.1 -- not pwsh 7. This drives several hard rules, enforced by
`tests/canonical/ps51-compat-check.ps1` (an AST lint) and a real 5.1 CI lane.

- **Version pin:** files declare `#Requires -Version 5.1` and advertise "5.1+".
- **Strict mode:** `Set-StrictMode -Version Latest` at module top.
- **TLS 1.2 must be enabled before any web call** -- 5.1 on .NET Framework defaults
  to SSL3/TLS1.0, which GitHub/npm/PyPI reject:
  ```powershell
  try { [Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
  ```
- **ASCII-only.** Shipped `.ps1`/`.psm1` MUST contain no non-ASCII bytes: Windows
  decodes no-BOM UTF-8 in the ANSI codepage and mis-parses them. CI-guarded.
- **5.1-incompatible constructs are banned** (the AST lint catches what
  PSScriptAnalyzer misses): 3-argument `Join-Path` (`-AdditionalChildPath`),
  `-Encoding utf8NoBOM`/`utf8BOM`, `Split-Path -LeafBase`, ternary / null-coalescing
  / pipeline-chain operators, `ForEach-Object -Parallel`, and the automatic
  variables `$IsWindows`/`$IsLinux`/`$IsMacOS` (they do not exist in 5.1 and throw
  under StrictMode).
- **No side effects on import.** A module defines functions only; nothing runs at
  import time, and an import-once guard prevents double-load
  (`AidInstallCore.psm1` `_AID_INSTALL_CORE_LOADED`).
- **Approved-verb function names:** `Get-`, `Install-`, `Write-`, `Read-`,
  `Remove-`, `Test-`, with an `Aid` noun infix.

---

## Python Conventions

- **Shebang + version:** `#!/usr/bin/env python3`; minimum version stated in the
  header (`aid_profile.py` needs 3.11+ for stdlib `tomllib`). The PyPI package
  targets `>=3.8`.
- **`from __future__ import annotations`** at the top of typed modules.
- **Type hints everywhere**, including modern union syntax
  (`ModelTierSimple | ModelTierDetailed`) and `list[str]` / `dict[str, str]`
  generics.
- **Dataclasses for structured data:** `@dataclass` with `field(default_factory=...)`
  for mutable defaults (`Profile`, `CapabilitiesConfig`).
- **Docstrings** on public functions/classes, often NumPy-style
  (`Parameters`/`Returns`/`Raises`), e.g. `load_profile`.
- **CLI shape:** `argparse` in `main() -> int`; `if __name__ == "__main__":
  sys.exit(main())`. Errors print to `sys.stderr`; the function returns the exit
  code rather than calling `exit()` mid-logic.
- **Stdlib-first / zero runtime deps for maintainer tooling:** the generator uses
  only `tomllib`, `json`, `argparse`, `pathlib` (NFR: no end-user dependency added).

---

## JavaScript / Node Conventions

- **ESM modules** (`.mjs`), `#!/usr/bin/env node`, `import ... from 'node:...'`
  with the `node:` scheme (`import fs from 'node:fs/promises'`) -- see
  `contrast-check.mjs`.
- **Tab indentation** in `.mjs` scripts (note: differs from the space-indented
  shell/Python -- see [Observed Inconsistencies](#observed-inconsistencies)).
- **Exit codes via `process.exit(n)`**; usage error -> `process.exit(2)`, failure
  -> `process.exit(1)`, success -> `0`.
- **The Node reader is a behavior twin of the Python reader** -- `reader.mjs` must
  match `dashboard/reader/parsers.py` output; parity is test-enforced.

---

## Error Handling

| Property | Pattern | Evidence |
|----------|---------|----------|
| Primary mechanism | Exit codes + stderr messages (shell/PS); return-code from `main()` (Python); `process.exit` (Node) | `read-setting.sh`, `aid_profile.py`, `contrast-check.mjs` |
| Where validated | At the argument-parse boundary and before any side effect | `read-setting.sh` mode validation; `validate(profile)` before render |
| Error message content | Always actionable; include the resolved absolute path for file errors | `read-setting.sh` prints `SETTINGS_FILE_ABS` in every file error (F20) |
| Expected non-zero | Swallowed with `|| true` so `set -e` does not abort | `read-setting.sh` `lookup` |
| Validation style | Collect all errors into a list, report together (don't fail on first) | `aid_profile.py` `validate()` returns `list[str]` |

**Example (the project's error-with-absolute-path pattern):**
```bash
echo "read-setting.sh: settings file not found at $SETTINGS_FILE_ABS and no --default provided" >&2
exit 1
```

---

## Exit Codes

AID assigns **stable, documented exit codes**. The install-core family uses a shared
scheme (from `AidInstallCore.psm1` / `aid-install-core.sh` headers):

| Code | Meaning |
|------|---------|
| 0 | success |
| 1 | generic runtime failure |
| 2 | usage / argument error (also: malformed config) |
| 3 | network / fetch failure |
| 4 | checksum mismatch |
| 6 | uninstall requested with no manifest |

`read-setting.sh` uses `0` (found/default), `1` (missing, no default), `2` (arg
error / unreadable / malformed YAML). Linters use `0` clean, `1` violations,
`2` usage (`kb-citation-lint.sh`). A new failure mode SHOULD reuse an existing code
with matching semantics rather than inventing a new one.

---

## Logging and Output

| Property | Convention |
|----------|-----------|
| Framework | None -- plain `echo`/`printf` (shell), `Write-*` (PS), `print(..., file=sys.stderr)` (Python). No logging library. |
| stdout vs stderr | stdout carries the **result** (the resolved value); stderr carries diagnostics. `read-setting.sh` prints the value to stdout, errors to stderr. |
| Verbosity | Opt-in via a flag, default quiet. Install-core copy logging is per-tool summary by default; `-AidVerbose $true` enables per-file lines. |
| Message prefix | Messages are prefixed with the script name (`read-setting.sh: ...`, `kb-citation-lint: ...`). |
| Heartbeat output | Long-running sub-agents emit a shell-generated timestamp line to a heartbeat file (`echo "[$(date -u ...)] ..." > "$HEARTBEAT_FILE"`); see `agent-boilerplate.md`. |

---

## Configuration Access

| Property | Value |
|----------|-------|
| Source of truth | `.aid/settings.yml` (YAML 1.2), managed by `/aid-config`. |
| Access pattern | Read via `read-setting.sh`; **never hand-parse the YAML in another script.** |
| Resolution order | per-skill override (`discover.minimum_grade`) -> category default (`review.minimum_grade`) -> hardcoded `--default`. |
| Secrets | None stored in settings -- it is non-secret project config (name, grades, parallelism). |
| Env vars | `AID_HOME` (state-home), `HEARTBEAT_FILE`/`HEARTBEAT_INTERVAL` (sub-agent dispatch). |

---

## Security Conventions

> The C3 floor requires this project's own security-relevant rules. AID downloads
> and installs executable content, so download-integrity and host-isolation are the
> load-bearing security concerns.

- **Download integrity is mandatory.** Every release tarball is verified by SHA-256
  against a sibling `SHA256SUMS` before extraction; mismatch -> hard fail (exit 4).
  Evidence: `fetch_tarball` / `verify_bundle_checksum` (`aid-install-core.sh`),
  `Verify-BundleChecksum` (`AidInstallCore.psm1`), `Get-Sha256File`.
- **TLS 1.2 enforced** before any HTTPS call on Windows PowerShell 5.1 (see
  PowerShell conventions) -- weak-protocol fallback would expose downloads.
- **Removal is manifest-driven.** Uninstall removes only paths recorded in the
  install manifest (`uninstall_tool` / `Uninstall-AidTool`); AID never blind-deletes
  a directory. Orphan pruning is by the `aid-` prefix only.
- **Root agent files are edited in place via an AID:BEGIN/END boundary**, never
  overwritten -- user content outside the managed region is preserved (see
  `CLAUDE.md` lines `AID:BEGIN`/`AID:END`; full rule in
  [authoring-conventions.md](authoring-conventions.md)).
- **Discovery is read-only on the repo.** `/aid-discover` and its agents MUST NOT
  modify any file outside `.aid/knowledge/`, `.aid/generated/`, `.aid/.temp/`
  (kb-authoring P7) -- a category guard in the skill pre-flight.
- **No secrets in committed config.** `settings.yml` holds no credentials; there is
  no secret store in the repo.

---

## Observed Inconsistencies

> Awareness items (tech-debt-adjacent), not blockers.

| Area | Inconsistency | Where | Note |
|------|--------------|-------|------|
| Indentation | `.mjs` scripts use tabs; shell/Python use spaces. | `scripts/summarize/*.mjs` vs `scripts/**/*.sh` | Per-language norm; not unified repo-wide. |
| Strict mode | Most Bash uses `set -euo pipefail`; read-only linters drop `-e` (`set -uo pipefail`). | `kb-citation-lint.sh` | Intentional (tolerates grep/awk non-zero), but the divergence is undocumented in-file. |
| Twin drift risk | Bash/PowerShell and Python/Node twins are hand-kept in sync; no generator enforces equality. | install-core, dashboard readers, migrate scripts | Parity is test-enforced, not generated -- a gap a contributor must respect. |

---

## Conventions

> The project's own way of doing each recurring code change. Imperative rules.

- **Adding a script:** write `#!/usr/bin/env <interp>`, a header block
  (Purpose/Usage/Exit codes), `set -euo pipefail` (Bash) or `Set-StrictMode -Version
  Latest` (PS); read settings via `read-setting.sh`; print results to stdout and
  diagnostics to stderr; reuse the shared exit-code scheme.
- **Adding PowerShell:** stay ASCII-only and WinPS-5.1-compatible; enable TLS 1.2
  before any web call; define functions with no import-time side effects; run
  `ps51-compat-check.ps1` before pushing.
- **Touching a language twin:** change BOTH twins in the same commit
  (`*.sh` + `*.psm1`/`.ps1`; `parsers.py` + `reader.mjs`; migrate `.sh` + `.ps1`).
- **Adding a failure mode:** reuse the documented exit code with matching semantics;
  document any new code in the script header.
- **Reading config:** always via `read-setting.sh` -- never re-parse `settings.yml`.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial conventions mined from code (Analyst) |
