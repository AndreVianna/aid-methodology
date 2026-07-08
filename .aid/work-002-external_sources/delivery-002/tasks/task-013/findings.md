# task-013 findings — Per-host MCP-config mechanism spike

**Type:** RESEARCH (findings document only — no code changes)
**Work / Delivery:** work-002-external_sources / delivery-002
**Feeds:** task-014 (committed mechanism-table DATA artifact) -> task-015 (wire/unwire twin)
**Author method:** repo artifact (grounded on disk) + web verification against official / host-authoritative docs
**Web-source access date:** 2026-07-08

---

## 1. Purpose & method

For each of the five host profiles AID renders into (`claude-code`, `cursor`, `codex`, `copilot-cli`,
`antigravity`), determine the MCP-config mechanism: (a) config-file path, (b) scope (project vs
user-home), (c) format, (d) the servers container key, (e) the per-server entry shape
(command/args/env). Each row carries a CONFIDENCE flag and a cited source; no unknown path is
fabricated — where evidence is ambiguous it is stated as ambiguous and candidate encodings are
compared.

Two distinct notions of "confidence" are used and kept separate on purpose:

- Research confidence (the CONFIDENCE column in section 2) — how well this spike verified the
  mechanism: CONFIRMED (repo artifact), CONFIRMED (official docs), or LIKELY (docs; residual
  ambiguity).
- Artifact flag (the enum task-014 materializes, section 5) — the wire-policy flag the committed
  data artifact carries: CONFIRMED (safe to wire now) vs verify-at-install (re-verify against the
  actual installed host before the first real write). These are NOT the same: a mechanism can be
  well-documented (high research confidence) yet still carry verify-at-install because its host is
  not installed and docs drift / paths vary by version (see section 4, Antigravity).

---

## 2. Per-host MCP-config mechanism table

| Host | Config file | Scope | Format | Servers container | Per-server entry shape | CONFIDENCE | Source |
|------|-------------|-------|--------|-------------------|------------------------|------------|--------|
| `claude-code` | `.mcp.json` (repo root) | project (committed, shared) | JSON | top-level `mcpServers` object, keyed by server name | `{ "type": "stdio", "command": <bin>, "args": [...], "env": { <VAR>: "${<VAR>}" } }` | CONFIRMED (repo artifact) | this repo `.mcp.json` (`playwright-project` — type/command/args observed directly) |
| `cursor` | `.cursor/mcp.json` (project); also `~/.cursor/mcp.json` (global) — project wins on conflict | project (committed); global user-home also supported | JSON | `mcpServers` object, keyed by server name | `{ "type": "stdio", "command", "args": [...], "env": {...} }` (+ `envFile`; remote uses `url`+`headers`) | CONFIRMED (official docs) | Cursor Docs — Model Context Protocol |
| `codex` | `~/.codex/config.toml` (`CODEX_HOME` default `~/.codex`); project-scoped `.codex/config.toml` for trusted projects only | user-home — NOT committed (project scope is opt-in/trusted) | TOML | `[mcp_servers.<name>]` tables | `command = "<bin>"`, `args = [...]`, `env = { <VAR> = "..." }` (inline) or `[mcp_servers.<name>.env]` sub-table; also cwd, startup_timeout_sec, enabled | CONFIRMED (official docs) | OpenAI Codex Docs — MCP + Config Reference |
| `copilot-cli` | `~/.copilot/mcp-config.json` (Windows `%USERPROFILE%\.copilot\mcp-config.json`; `COPILOT_HOME` override). Note the hyphenated `mcp-config.json`. Project `.copilot/mcp-config.json` + auto-discovered `.github/mcp.json` also supported | user-home primary; project + `.github/` discovery also supported | JSON | `mcpServers` object (NOT `servers`) | `{ "type": "local"/"http"/"sse", "command", "args": [...], "env": {...}, "tools": [...] }` (remote uses `url`+`headers`) | CONFIRMED (official docs) | GitHub Docs — Adding MCP servers for GitHub Copilot CLI |
| `antigravity` | `~/.gemini/config/mcp_config.json` (preferred, shared across IDE+CLI) — path has a second live candidate `~/.gemini/antigravity/mcp_config.json` (Windows `%USERPROFILE%\.gemini\antigravity\mcp_config.json`); both user-home under `~/.gemini/` (see section 4) | user-home (no documented project scope) | JSON | `mcpServers` object | `{ "command", "args": [...], "env": {...} }`; remote uses `serverUrl` (NOT `url`) + `headers`; also disabled, authProviderType/oauth | LIKELY (docs; config-file path ambiguous — two candidates) | github/github-mcp-server install-antigravity.md + Google Cloud community (Dazbo) |

Two load-bearing axes (carried forward from the feature SPEC, now evidence-backed):

- Scope (project vs user-home). `claude-code` and `cursor` write project-scoped, committed files
  inside the repo tree (feature-001's P7 allowlist / reference-not-value target). `codex`,
  `copilot-cli`, and `antigravity` default to user-home files outside the repo tree — per-machine
  mutations that cannot be committed/shared (KI-007). `copilot-cli` additionally supports in-repo
  `.copilot/mcp-config.json` / `.github/mcp.json`, and `codex` supports an opt-in `.codex/config.toml`
  in trusted projects — but neither is the default, so the user-home write path (KI-007) still applies
  at first install.
- Endpoint -> entry translation. feature-001's `endpoint` (an MCP server launch spec, e.g.
  `npx -y @modelcontextprotocol/server-github`) tokenizes into the host's `command` (first token) +
  `args` (the rest); the secret attaches as an `env` reference (name only). One descriptor field,
  five host encodings, one generic routine.

---

## 3. Per-host evidence & notes

### claude-code — CONFIRMED (repo artifact)
Grounded directly on disk. The repo `.mcp.json` (repo root, JSON) has a top-level `mcpServers` object
whose one entry, `playwright-project`, is `{ "type": "stdio", "command": "npx", "args": [...] }`.
type/command/args are observed directly; the `env` reference form (`{ <VAR>: "${<VAR>}" }`) is Claude
Code's documented MCP-config behavior and is the worked example in the feature-004 SPEC. This is the
one row backed by a repo artifact rather than external docs — the strongest source class.

### cursor — CONFIRMED (official docs)
Cursor's official MCP docs confirm two config files: project `.cursor/mcp.json` and global
`~/.cursor/mcp.json` (project wins on conflict). JSON, top-level `mcpServers`. STDIO entries take
`type: "stdio"`, `command` (required), `args`, `env` (and `envFile`); remote servers use `url` +
`headers`. The format is deliberately Claude-Desktop-compatible — an `mcpServers` block copies across
Claude Desktop / Cursor / Claude Code directly. Upgraded from the pre-spike "high" flag to CONFIRMED.
For AID's committed-config purpose, the project `.cursor/mcp.json` is the in-repo target (directly
parallel to `claude-code`'s `.mcp.json`).

### codex — CONFIRMED (official docs); TOML write nuance for task-015
`~/.codex/config.toml` (user-home; `CODEX_HOME` defaults to `~/.codex`), TOML, servers as
`[mcp_servers.<name>]` tables with command / args / env (env either inline `{ VAR = "..." }` or a
`[mcp_servers.<name>.env]` sub-table); optional cwd, startup_timeout_sec, tool_timeout_sec, enabled.
A trusted project may use a project-scoped `.codex/config.toml`, but the default is user-home.
task-015-critical nuance: Python's stdlib is read-only for TOML — `tomllib` (Python 3.11+) parses TOML
but has NO writer. So the codex write path cannot be a pure-stdlib read -> merge -> write the way the
JSON hosts can; it needs a line-oriented `[mcp_servers.<name>]` section edit or an added TOML writer
(a real dependency decision). This is a concrete reason codex is carried as verify-at-install and is
deferred cleanly (KI-006). Whether codex resolves `${VAR}` in TOML values is itself verify-at-install;
if not, the committed-safe fallback is to omit `env` and let the server inherit the ambient
environment (feature-004 Security Specs).

### copilot-cli — CONFIRMED (official docs)
GitHub's official Copilot CLI docs confirm `~/.copilot/mcp-config.json` (user-home;
`%USERPROFILE%\.copilot\mcp-config.json` on Windows; `COPILOT_HOME` override). JSON, root key
`mcpServers` (explicitly NOT `servers`). Per-server keys: type (local/http/sse), command, args, env,
tools (and url/headers for remote). It also discovers project-level `.copilot/mcp-config.json` and
`.github/mcp.json`, and accepts `--additional-mcp-config` at runtime. Two watch-outs for
task-014/015: (1) the filename is hyphenated `mcp-config.json`, not the `mcp.json` every other JSON
host uses — do not normalize it; (2) it has a genuine project-vs-home scope choice (see section 4).
Not installed today -> verify-at-install.

### antigravity — LIKELY (docs; path ambiguous — see section 4)
Format, container, and entry shape are well-corroborated: user-home JSON under `~/.gemini/`,
top-level `mcpServers`, per-server command/args/env, remote via `serverUrl` (a real divergence from
`url` — matters if AID ever emits a remote entry) plus disabled / authProviderType / oauth. The
config-file path, however, has two live candidates across authoritative-ish sources (section 4). No
documented project scope -> user-home only. Not installed today -> verify-at-install, with a note to
probe the installed host for the path.

---

## 4. Candidate-encoding comparison (ambiguous mechanisms)

The spike resolved a documented mechanism for every host, so no host remains fully unknown. Two hosts
carry residual, evidence-backed ambiguity; per the AC, the candidates are compared before recommending
defer.

### 4a. antigravity config-file path — two candidates
| # | Candidate path | Evidence | Notes |
|---|----------------|----------|-------|
| A | `~/.gemini/config/mcp_config.json` (Win `%USERPROFILE%\.gemini\config\mcp_config.json`) | Google Cloud community guide (Dazbo/Medium) — "create mcp_config.json ... in the new ~/.gemini/config folder"; shared across Antigravity IDE + CLI; corroborated by Google Codelabs | Described as the new / shared location; the IDE "picked up the same MCP configuration" from it. Best current candidate. |
| B | `~/.gemini/antigravity/mcp_config.json` (Win `%USERPROFILE%\.gemini\antigravity\mcp_config.json`) | github/github-mcp-server install-antigravity.md (GitHub-official install guide) | Likely an older / IDE-specific layout, or a version-specific variant. |

Both are user-home under `~/.gemini/`, JSON, `mcpServers` — so only the sub-path differs; format,
container, and entry shape are stable across both. The divergence reads as a version/surface migration
(a "new ~/.gemini/config" shared location superseding a per-app ~/.gemini/antigravity path).
Recommendation: record candidate A (`~/.gemini/config/mcp_config.json`) as the preferred path in the
task-014 artifact, keep candidate B as a documented fallback, and verify by probing the installed host
before the first write (KI-007). This ambiguity alone justifies verify-at-install.

### 4b. copilot-cli scope — two candidate write targets
| # | Candidate | Evidence | Notes |
|---|-----------|----------|-------|
| A | user-home `~/.copilot/mcp-config.json` (`COPILOT_HOME` override) | GitHub Docs — the CLI's default MCP-config location | Default; per-machine (KI-007, out-of-repo write). |
| B | project `.copilot/mcp-config.json` and/or auto-discovered `.github/mcp.json` | GitHub Docs + github/copilot-cli discussions/issues | In-repo, committable — parallels claude-code/cursor; but not the documented default target for the `copilot mcp add` write. |
| — | (format/container/entry are NOT ambiguous — CONFIRMED JSON `mcpServers`, keys above) |  |  |

Recommendation: treat user-home (A) as the mechanism-table default (matches the documented CLI write
behavior and the KI-007 user-home framing) while noting B as an installed-time option; confirm which
the installed CLI actually writes to before wiring. Scope choice, not mechanism, is the open item —
hence verify-at-install, not unknown.

---

## 5. Recommendation — wire-now vs deferred set (task-014 artifact shape)

Driver is wire-only-installed. feature-004 wires only hosts in `.aid/settings.yml` `tools.installed`.
On disk that list is `claude-code` only (`codex` / `cursor` commented out; `copilot-cli` /
`antigravity` absent). So exactly one host is wired today; the other four are carried in the mechanism
table for coverage/future installs and skipped cleanly (no error, no empty file) until their host is
installed.

- WIRE-NOW set: `claude-code` — CONFIRMED (repo artifact), installed today -> `.mcp.json`.
- DEFERRED set (verify-at-install): `cursor`, `codex`, `copilot-cli`, `antigravity`. Their mechanisms
  are now documented (cursor/codex/copilot-cli CONFIRMED via official docs; antigravity LIKELY with a
  path to probe), so the defer reason is "not installed" + "re-verify at first write" — NOT "mechanism
  unknown". verify-at-install here is a wire-policy flag: verify the row against the actual host the
  moment that host enters `tools.installed`, then wire.

### Committed data artifact rows (the shape task-014 materializes)

task-014 records `Host | Config file | Scope | Format | Servers container | Per-server entry shape |
CONFIDENCE` (no Source column) under `canonical/aid/scripts/connectors/`. The `env` value in every
per-server shape is an interpolation reference (`${VAR}` — name only, never the value; section 6 /
feature-004 Security Specs):

| Host | Config file | Scope | Format | Servers container | Per-server entry shape | CONFIDENCE |
|------|-------------|-------|--------|-------------------|------------------------|------------|
| `claude-code` | `.mcp.json` (repo root) | project | JSON | `mcpServers` (object, by name) | `{ "type": "stdio", "command": <bin>, "args": [...], "env": { <VAR>: "${<VAR>}" } }` | CONFIRMED |
| `cursor` | `.cursor/mcp.json` (project) | project | JSON | `mcpServers` (object, by name) | `{ "type": "stdio", "command": <bin>, "args": [...], "env": { <VAR>: "${<VAR>}" } }` | verify-at-install |
| `codex` | `~/.codex/config.toml` | user-home | TOML | `[mcp_servers.<name>]` (table) | `command = <bin>`, `args = [...]`, `[mcp_servers.<name>.env]` -> `<VAR> = "${<VAR>}"` (interp support verify-at-install; else omit env) | verify-at-install |
| `copilot-cli` | `~/.copilot/mcp-config.json` | user-home | JSON | `mcpServers` (object, by name) | `{ "type": "local", "command": <bin>, "args": [...], "env": { <VAR>: "${<VAR>}" } }` | verify-at-install |
| `antigravity` | `~/.gemini/config/mcp_config.json` (fallback `~/.gemini/antigravity/mcp_config.json`) | user-home | JSON | `mcpServers` (object, by name) | `{ "command": <bin>, "args": [...], "env": { <VAR>: "${<VAR>}" } }` (remote: `serverUrl`, not `url`) | verify-at-install |

Notes for task-014/task-015 to carry forward:
- KI-007 (out-of-repo writes): `codex`, `copilot-cli`, `antigravity` default to user-home config —
  outside the repo tree, beyond feature-001's repo-tree P7 carve-out. Any real write to these needs
  its own idempotency + an installed-host check before touching home config. Deferred cleanly by
  wire-only-installed.
- KI-006 (codex TOML write): stdlib `tomllib` is read-only; no stdlib TOML writer. The codex path
  needs a line-oriented section edit or an added writer — a genuine task-015 dependency decision.
- Filename traps: `copilot-cli` uses hyphenated `mcp-config.json`; `antigravity` uses `mcp_config.json`
  (underscore). Do not normalize either to the bare `mcp.json` the other hosts use.
- Remote-key trap: `antigravity` uses `serverUrl` (not `url`) for remote servers; matters only if AID
  emits a remote (non-stdio) entry.
- `env` interpolation is per-host: `${VAR}` passthrough is verified for the JSON hosts' intent but
  must be confirmed per installed host; where unsupported, the committed-safe fallback is to omit
  `env` (server inherits ambient environment). No host config ever stores a secret value.

---

## 6. Sources (accessed 2026-07-08)

- claude-code — repo artifact: `.mcp.json` (this repository). CONFIRMED.
- cursor — Cursor Docs, "Model Context Protocol (MCP)": https://cursor.com/docs/mcp
- codex — OpenAI Codex Docs, "Model Context Protocol": https://developers.openai.com/codex/mcp ;
  "Configuration Reference": https://developers.openai.com/codex/config-reference
- copilot-cli — GitHub Docs, "Adding MCP servers for GitHub Copilot CLI":
  https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers
- antigravity — github/github-mcp-server install guide:
  https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-antigravity.md ;
  Google Cloud community (Dazbo), "Configuring MCP Servers and Skills for Antigravity CLI and IDE":
  https://medium.com/google-cloud/configuring-mcp-servers-and-skills-for-antigravity-cli-and-ide-a938c7eebb78

Web sources cited: 4 hosts (cursor, codex, copilot-cli, antigravity), across 6 distinct URLs (codex
and antigravity each corroborated by 2 sources). claude-code cited to the repo artifact.

Unresolved / stated-as-unknown: none fully unknown. The one residual is the antigravity config-file
path (two candidates, section 4a), carried as verify-at-install with a preferred candidate and a
documented fallback — not fabricated, not guessed.

---

## 7. section-6 quality-gate self-check (RESEARCH doc)

- No secret values anywhere in this doc — every `env` shape is a `${VAR}` reference (name only).
  (REQUIREMENTS section 6 secret hygiene; feature-004 Security Specs.) PASS.
- No fabricated paths — every non-repo path is cited; the one ambiguous path (antigravity) is
  presented as two evidenced candidates. PASS.
- Cross-platform noted — Windows `%USERPROFILE%` equivalents recorded for the user-home hosts; codex
  TOML-writer + no-heavy-dependency (AC-8) implications flagged for task-015. PASS.
- RESEARCH-only — findings document; no code, no data artifact written (that is task-014), no git
  operations. PASS.
