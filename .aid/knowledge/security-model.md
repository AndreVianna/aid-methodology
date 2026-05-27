# Security Model

> **Source:** `discovery-quality` (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-27
> **Scope:** AID is a **code-generator + documentation repo with NO runtime services.** There is no user-facing API, no database, no daemon, no network listener. Security concerns reduce to: (1) what gets committed (secret hygiene), (2) supply-chain inputs (CDN-fetched assets), (3) input validation in the helper scripts that ingest user-controlled settings, and (4) the **AID agent permission model** (the `tools:` allowlist that bounds what each subagent may do when AID is installed into a real project).

> ⚠️ **Sensitivity note:** This document describes patterns and architecture — not values. The repo contains no real credentials.

---

## Threat Surface (Brief)

| Surface | Asset at risk | Adversary | Mitigation |
|---------|---------------|-----------|------------|
| Git commits | The repo itself; downstream installs | Accidental author leak | `.gitignore` excludes `.aid/.heartbeat/`, `*.temp`, `.aid/knowledge/.cache/`, IDE files, `.claude/settings.local.json` (`.gitignore:18-47`) |
| CDN-fetched Mermaid JS | End-user browsers viewing the offline KB summary | npm registry compromise / jsDelivr MITM | curl with `-sSf` (fails on HTTP error) and `--max-time` cap (`fetch-mermaid.sh:16, 43`); **but version is `latest`, not pinned** — see Supply-Chain Concerns |
| `read-setting.sh` input | Settings resolution behavior | Malformed `.aid/settings.yml` | `set -euo pipefail` (`canonical/scripts/config/read-setting.sh:44`); arg-parsing rejects unknown flags with exit 2 (line 75-77) |
| Subagent tool access | Files outside repo / shell execution | Buggy or malicious agent prompt | Per-agent `tools:` allowlist in YAML frontmatter (see Authorization below) |

There is **no authentication subsystem, no authorization middleware, no session management, no input validation framework** in the traditional web-app sense — none of those apply.

---

## Authentication

**Not applicable to the repo itself** — no runtime service.

Authentication concerns that DO apply:
- **GitHub push access** (per user memory `reference_repo-push-access.md`): pushing/PRs to `AndreVianna/aid-methodology` requires the `AndreVianna` `gh` CLI account. This is enforced by GitHub, not by repo code.
- **Claude Code / Codex / Cursor host authentication:** AID inherits whatever the host AI tool uses. There is no AID-controlled auth flow.

---

## Authorization

The repo's primary authorization model is the **AID agent permission model** — declared per-agent in the `tools:` field of each agent's YAML frontmatter at `canonical/agents/*/AGENT.md`. The host tool (Claude Code / Codex / Cursor) enforces the allowlist at dispatch time.

### Agent Tool Allowlist (cited evidence)

Enumeration from `canonical/agents/*/AGENT.md:5` (one row per agent — confirmed via `grep "^tools:" canonical/agents/**/AGENT.md`):

| Agent | tools: allowlist | Can write source? | Can run shell? | Notes |
|-------|------------------|-------------------|----------------|-------|
| `architect` | Read, Glob, Grep, Write, Edit, Bash | Yes | Yes | Full implementer access |
| `developer` | Read, Glob, Grep, Write, Edit, Bash | Yes | Yes | |
| `data-engineer` | Read, Glob, Grep, Write, Edit, Bash | Yes | Yes | |
| `devops` | Read, Glob, Grep, Write, Edit, Bash | Yes | Yes | |
| `tech-writer` | Read, Glob, Grep, Write, Edit | Yes (docs) | **No** | No Bash — docs-only |
| `simple-formatter` | Read, Write, Edit | Yes | No | Minimal — formatting only |
| `interviewer` | Read, Glob, Grep | **No** | **No** | Conversation-only — strictest writeable-tool exclusion in the agent set |
| `discovery-scout` | Read, Glob, Grep, Bash, Write | Yes (KB only) | Yes (read-only bash) | KB-write-only by prompt contract |
| `discovery-analyst` | Read, Glob, Grep, Bash, Write | Yes (KB only) | Yes | Same constraint |
| `discovery-architect` | Read, Glob, Grep, Bash, Write | Yes (KB only) | Yes | Same |
| `discovery-integrator` | Read, Glob, Grep, Bash, Write | Yes (KB only) | Yes | Same |
| `discovery-quality` | Read, Glob, Grep, Bash, Write | Yes (KB only) | Yes | Same |
| `discovery-reviewer` | Read, Glob, Grep, Bash, Write | Yes (review-doc only) | Yes | Per `canonical/agents/discovery-reviewer/AGENT.md:8` |
| `researcher` | Read, Glob, Grep, Bash, Write | Yes | Yes | |
| `operator` | Read, Glob, Grep, Bash, Write | Yes | Yes | |
| `security` | Read, Glob, Grep, Bash | **No** | Yes (read-only bash) | Audit-only; no Write or Edit |
| `reviewer` | Read, Glob, Grep, Bash | No | Yes | Audit-only |
| `performance` | Read, Glob, Grep, Bash | No | Yes | Audit-only |
| `ux-designer` | Read, Glob, Grep, Bash | No | Yes | |
| `orchestrator` | Read, Glob, Grep, Bash | No | Yes | Dispatch/coord only |
| `simple-extractor` | Read, Glob, Grep, Bash | No | Yes | |
| `simple-glob` | Glob, Bash | No | Yes | Smallest allowlist in the set |

**Pattern:** discovery sub-agents have a uniform `Read, Glob, Grep, Bash, Write` allowlist; audit/review agents (`security`, `reviewer`, `performance`) omit `Write`/`Edit`; the `interviewer` is the strictest — conversation-only.

⚠️ **Inferred from code — needs confirmation:** the **discipline that discovery agents write ONLY into `.aid/knowledge/`** is enforced by the agent's *prompt* (see the SYSTEM prompt block at the top of this very agent for an example), not by a path-scoped `Write` permission. A misbehaving discovery agent COULD write outside `.aid/knowledge/`. There is no path-scoping in the `tools:` schema.

### Claude Code repo-level allowlist

`.claude/settings.json:5-14` declares the bash command pattern allowlist for this repo when humans (or top-level agents) run shell commands directly:

```json
"allow": [
  "Bash(mkdir *)", "Bash(cp *)", "Bash(python *)",
  "Bash(rm *)", "Bash(./setup.sh *)", "Bash(grep *)", "Bash(chmod *)"
]
```

This is a **glob allowlist of command prefixes**, not a sandbox. `Bash(rm *)` allows arbitrary `rm` invocations; `Bash(python *)` allows arbitrary Python execution. The repo's per-tool agent allowlist (above) is the finer-grained control.

---

## Secrets Management

**No secrets are stored in this repo and none are loaded at runtime.** There are:

- **No `.env`, `.env.*`, `.envrc` files** (confirmed by repo search).
- **No `secrets.yml`, `vault.json`, `credentials.json`** (none present).
- **No environment-variable reads of secret values** anywhere in `canonical/scripts/` or `.claude/skills/aid-generate/scripts/` — every `$env:` / `$VAR` reference is for paths and config (verified by inspection during this pass).
- **`.claude/settings.local.json`** is gitignored (`.gitignore:44`) — it's the documented place for per-developer overrides that might contain personal preferences but, per the codebase, is not used for credentials.

The **`.aid/.heartbeat/`** directory holds ephemeral per-subagent status files. It MUST stay gitignored (it is, per `.gitignore:46-47`) — these files are not strictly secret but accumulate and pollute history. Confirmed: `git check-ignore -v .aid/.heartbeat/` returns line 47.

The **`.aid/.temp/`** directory is gitignored via the global `*.temp` pattern at `.gitignore:21`. ⚠️ This is **indirect** — relying on a glob pattern instead of an explicit directory entry; if the directory were ever renamed (e.g., to `.aid/work-temp/`) it would silently become tracked. Recommend adding an explicit `.aid/.temp/` line — see `tech-debt.md` M3.

---

## Input Validation

Input-validation surface is small (no HTTP API) and concentrated in the bash helpers:

- **`canonical/scripts/config/read-setting.sh`** (263 lines): the most exposed input handler — reads `.aid/settings.yml` which is potentially user-edited. Uses `set -euo pipefail` (line 44); rejects unknown flags with exit code 2 (lines 75-77); validates that `--skill` requires `--key` (covered by `tests/canonical/read-setting.sh` Test 11). Documented error semantics at `read-setting.sh:27-36`.
- **`canonical/scripts/interview/parse-recipe.sh`** (540 lines): parses user-authored recipe files (YAML front-matter + `{{slot}}` placeholders). Validation tested by 113 tests including malformed-front-matter, missing-blocks, bad-args paths (per `tests/canonical/parse-recipe.sh:11-29` Units 11–12).
- **`canonical/scripts/kb/verify-claims.sh`** (695 lines): validates citation patterns (file:line refs) emitted by KB authors. The pattern definition at `verify-claims.sh:135` constrains what counts as a path-line citation; bad input is reported, not executed.
- **`run_generator.py`** (86 lines): reads `profiles/*.toml`; `profile.validate(profile)` returns an error list which aborts execution with a non-zero exit on any error (lines 26-29).

No external HTTP request handlers exist. There is no SQL, no template engine that interpolates untrusted user data into shell commands.

---

## Supply-Chain Concerns

### Critical: `fetch-mermaid.sh` is NOT version-pinned

`canonical/scripts/summarize/fetch-mermaid.sh` is the **only outbound network dependency in the codebase** — invoked by `aid-summarize` to render Mermaid diagrams in the offline KB viewer.

**Reality vs claim:** the dispatcher prompt asserts this script is "version-pinned + sha256 verified." Source reading contradicts both claims:

- **Lines 16-18:** `LATEST=$(curl -sSf --max-time 30 "https://registry.npmjs.org/mermaid/latest" | sed -nE 's/.*"version":"([^"]+)".*/\1/p' | head -1)` — the script **queries the npm registry on every run for the latest version**, then downloads `https://cdn.jsdelivr.net/npm/mermaid@${LATEST}/dist/mermaid.min.js` (line 41).
- **Lines 59-65 + 67-73:** sha256 is **computed AFTER the download is already in place**, then written to the cache metadata. There is no `EXPECTED_SHA256` constant to compare against; the SHA is descriptive (for cache invalidation), **not verifying**.
- **Net effect:** a registry compromise, an npm registry poisoning, or a jsDelivr CDN MITM would silently push compromised JS to every end user invoking `/aid-summarize`. The script's only protection is `curl -sSf --max-time {30,120}` (fail on HTTP error, timeout cap).

This is logged as a **High** debt item in `tech-debt.md` H3.

### Other supply-chain notes

- **No `package.json`** anywhere in the repo (confirmed in `project-structure.md` line 96). Node 18+ is a runtime requirement only for `aid-summarize`'s `.mjs` validators; users install Node and Mermaid CLI ad hoc.
- **No `requirements.txt`, `pyproject.toml`, or `Pipfile`** — Python 3.11+ stdlib only (`tomllib`). No third-party Python deps to audit.
- **No language lock files** (`package-lock.json`, `Pipfile.lock`, `poetry.lock`, `Cargo.lock`). Nothing to `npm audit` / `pip-audit` / `cargo audit` against.

---

## OWASP Concerns Observed

⚠️ **OWASP web-app categories largely N/A** — no HTTP layer. The few applicable categories:

- **A02 Cryptographic Failures (adjacent):** the missing sha256 pin in `fetch-mermaid.sh` is a supply-chain integrity gap (above). No actual cryptographic primitive is misconfigured.
- **A05 Security Misconfiguration:** the `.claude/settings.json` allow list permits `Bash(rm *)` and `Bash(python *)` without path scoping — broader than minimum-necessary. Documented above (Authorization).
- **A06 Vulnerable & Outdated Components:** the runtime `mermaid@latest` fetch (above) defeats reproducibility; an end user installing AID today vs. six months from now will get different JS shipped to the browser.
- **A08 Software & Data Integrity Failures:** see Supply-Chain Concerns above.
- **A09 Security Logging & Monitoring Failures:** heartbeat files are the only operational telemetry; they are local-only, not aggregated. Acceptable for a local-only methodology repo.

⚠️ **Security assessment from static analysis only — dynamic testing required** for any AID-using project's own application code (the AID `security` agent at `canonical/agents/security/AGENT.md` is the dispatch point for that).

---

## Dependencies with Known Vulnerabilities

**Not detectable** — no lock files exist for any language ecosystem. The runtime npm dependency (`mermaid@latest`) is not version-recorded anywhere, so historical vulnerability scanning is impossible. See `tech-debt.md` H3.
