# task-003: Bash install core + `install.sh` bootstrap

**Type:** IMPLEMENT

**Source:** feature-001-shared-install-core-and-bootstrap → delivery-001

**Depends on:** task-001

**Scope:**
- Author `lib/aid-install-core.sh` (sourceable, pure functions, no top-level side effects) and `install.sh` (Bash 4+ bootstrap) per feature-001 §Component-layout and §CLI-surface.
- Implement the authoritative CLI surface: modes install (default) / `--update` / `--uninstall`; flags `--tool <name>[,...]`, `--version <v>`, `--from-bundle <path>`, `--force`, `--target <dir>` / trailing positional, `-h|--help`; canonical tool ids `claude-code|codex|cursor|copilot-cli|antigravity` (case-insensitive normalize).
- Implement host-tool detection algorithm (per-tool markers; exactly-one/zero/ambiguous handling; `--tool` overrides; non-interactive — no menu).
- Implement the artifact-consumption contract (feature-002): online `/releases/latest` resolution + asset-URL fetch via `curl -fsSL`, `tar -xzf` into `mktemp -d`, `SHA256SUMS` verify-before-extract (fail on mismatch, best-effort warn if absent); `--from-bundle` offline path (single tarball or directory of tarballs).
- Implement copy semantics (skip-identical via SHA256 / skip-on-diff / `--force`; non-interactive — no `/dev/tty` prompt), the FR11 protect-on-diff algorithm for root agent files (self-computed sha256, `*.aid-new`, ownership/uninstall rules), the install manifest at `<target>/.aid/.aid-manifest.json` (schema v1) + `<target>/.aid/.aid-version` marker, and manifest-driven uninstall.
- Implement the exit-code table (0/1/2/3/4/5/6); use a jq/python-free Bash manifest reader (opportunistic `python3`/`jq` allowed only as a fast-path with pure-Bash fallback).

**Acceptance Criteria:**
- [ ] Fresh install per tool lands the correct tree (`.claude/`+`CLAUDE.md`; `.codex/`+`.agents/`+`AGENTS.md`; `.cursor/`+`AGENTS.md`; `.github/`+`AGENTS.md`; `.agent/`+`AGENTS.md`) byte-identical to `profiles/<tool>/`, writes the manifest with correct paths + per-tool version + root_agent sha256, and records `.aid/.aid-version`.
- [ ] Auto-detect uses a single marker, exits 2 (usage) on ambiguous (two markers) and on undetectable (zero markers) with the documented messages; `--tool` always overrides.
- [ ] Online resolution fetches the tarball + `SHA256SUMS` and verifies sha256 before extract (exit 4 on mismatch, exit 3 on fetch failure); `--from-bundle` installs with no network and verifies a sibling `SHA256SUMS` when present.
- [ ] **Protect-on-diff default:** a pre-existing root agent file the installer didn't write is NOT overwritten without `--force` — a warning is shown, `*.aid-new` is written, and the run exits 5 (the SPEC-flagged default for blocked protect-on-diff); `--force` overwrites; uninstall removes a root agent file only when it still checksum-matches what this tool wrote.
- [ ] **Manifest-path default:** the install manifest is written to `<target>/.aid/.aid-manifest.json` (the SPEC-flagged default location), excluded from a tool's own `paths`, and uninstall removes exactly the manifested paths + the manifest/version markers (exit 6 when no manifest), leaving the repo pre-install-clean.
- [ ] Idempotent re-install reports `Up to date:` and converges the manifest; the bootstrap consumes the **default tar.gz** artifact contract (no `.zip` path) and ignores any shipped `emission-manifest.jsonl`, self-computing root-file checksums.
- [ ] All §6 quality gates pass.
