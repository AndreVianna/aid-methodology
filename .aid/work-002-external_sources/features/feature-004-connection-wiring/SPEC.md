# Connection Wiring

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5 (FR-4) + §9 (AC-4, AC-8); see Source for other §refs | /aid-define |
| 2026-07-08 | Technical Specification authored (External Integrations, Data Model, Layers & Components, Feature Flow, Security Specs). Executed the Q1-authorized per-host MCP-config spike: mechanism table for all 5 hosts with CONFIDENCE flags (claude-code CONFIRMED from repo `.mcp.json`; cursor high; codex/copilot-cli/antigravity SPIKE-verify-at-implementation — flagged, not fabricated). Binds feature-001 FROZEN keystone; wire-only-installed; added KI-007 | /aid-specify |
| 2026-07-08 | FIX pass (A+ gate, C+ → 1 MEDIUM): removed the invented "feature-003 resolver". Per STATE.md Q7 item 3, use-time secret RESOLUTION is owned by feature-005's consumption contract / the consuming agent; feature-004 RECORDS the reference only into the host MCP config (External Integrations `${VAR}`-fallback + Security Specs `env:` bullet reworded). Home-scoped-write OOS (ledger row 2) routed to feature-001 CF5; KI-007 flag retained (deferred — only claude-code installed today) | /aid-specify |
| 2026-07-08 | Cross-feature FIX (aid-plan gate, STATE.md Q8): defined the `unwire` op as a first-class, feature-004-OWNED op on the host-MCP-config twin, symmetric to `wire` (remove the connector's `mcpServers`/`[mcp_servers.<name>]` entry from each installed host; idempotent no-op if absent; preserves other servers; wire-only-installed). feature-006 reconcile REMOVE COMPOSES `unwire <stem>` (mirrors feature-003 `purge`). Updated intro blockquote, External Integrations, Data Model, Layers & Components, Feature Flow (added `unwire` sub-flow); the former "feature-006 deletes the entry" pointer now targets this owned op | /aid-specify |

## Source

- REQUIREMENTS.md §4 (Scope — connection types; no bespoke per-tool clients), §5 FR-4 (Connection wiring), §8 (Dependencies — host-tool MCP support)
- REQUIREMENTS.md §9 Acceptance Criteria: AC-4, AC-8 (cross-cutting, cli/socket handling)

## Description

This feature turns a declared tool into something an agent can actually connect to, without
building any bespoke per-tool client code. It handles the two wiring outcomes the connection
types call for.

For an mcp-capable tool, the feature wires the MCP server into the host profile's MCP
configuration, using each host's own MCP-config mechanism. This is in scope for all five host
profiles AID renders into (claude-code, codex, cursor, copilot-cli, antigravity); Claude Code's
.mcp.json is one host's case, not a universal format. There is no MCP-config wiring in the
codebase yet, so mapping each host's per-host mechanism is a research item for /aid-specify.

For an api, ssh, url, or cli tool, the feature records a connection descriptor that carries
enough information for an agent to connect — the transport, the endpoint or target, and the auth
reference — again without any custom client. cli covers local binaries and local sockets, which
must be handled consistently across Windows, macOS, and Linux and within AID's existing
toolchain, introducing no new heavy runtime dependency.

The descriptor shape written here is the schema defined by the integration-store-placement
feature, and the tools wired here are the ones captured by source-and-tool elicitation.

## User Stories

- As a developer/adopter, I want each mcp-capable tool wired into the host's MCP configuration
  so that agents can use it immediately through MCP.
- As a developer/adopter, I want each api/ssh/url/cli tool recorded as a connection descriptor
  so that an agent has a concrete, client-free way to connect.
- As a developer/adopter on any of Windows, macOS, or Linux, I want cli and socket handling to
  behave consistently so that wiring is not platform-specific.

## Priority

Must

## Acceptance Criteria

- [ ] Given a declared mcp-capable tool, when connection wiring runs, then the MCP server is wired into each host profile's MCP configuration via that host's per-host mechanism (for all five profiles: claude-code, codex, cursor, copilot-cli, antigravity; Claude Code's .mcp.json is one case, not universal). (FR-4, AC-4)
- [ ] Given a declared api, ssh, url, or cli tool, when connection wiring runs, then a connection descriptor sufficient for an agent to connect is recorded, with no bespoke per-tool client code. (FR-4, AC-4)
- [ ] Given cli and socket handling, when wiring runs on Windows, macOS, and Linux, then it works on all three and introduces no new heavy runtime dependency. (AC-8)

---

## Technical Specification

> Authored by `/aid-specify`. This feature **wires** declared connectors; it does not define the
> schema, the home, or the secret rules — those are FROZEN by
> `feature-001-integration-store-placement/SPEC.md` (the keystone), and this SPEC BINDS to it and
> does not redefine it. Two wiring outcomes, driven by the connector's `connection_type`:
>
> - **`mcp`** → write/merge the MCP server into **each INSTALLED host's** MCP configuration, each
>   via that host's own MCP-config mechanism (FR-4, AC-4). Claude Code's repo-root `.mcp.json` is
>   **one** host's case, not a universal format. feature-004 owns a **symmetric `wire`/`unwire`
>   pair** on this twin; feature-006's reconcile REMOVE composes `unwire` (STATE.md Q8).
> - **`api` | `ssh` | `url` | `cli`** → the connection **descriptor** recorded per feature-001 IS
>   the wiring artifact (transport + endpoint/target + auth reference). No host-config write, and
>   **no bespoke per-tool client code** (REQUIREMENTS §4).
>
> All writes here occur inside the new P7-exempt `aid-discover` state (feature-002 / STATE.md Q6);
> this feature is a **producer** in feature-001's Feature Flow. Writes are confined to feature-001's
> P7 write allowlist item 2 — "the per-host MCP-config paths (feature-004, installed hosts only)".

### External Integrations

This is the primary surface of the feature. FR-4 / AC-4 require an `mcp` connector to be wired into
**each of the five host profiles' MCP configuration** (claude-code, codex, cursor, copilot-cli,
antigravity), each via its **own** mechanism. There is **no MCP-config wiring anywhere in
`canonical/` or `profiles/` today** — confirmed by grep: the only `mcpServers` in the repository is
the developer-time repo-root `.mcp.json` (a Playwright dev config), and neither `canonical/` nor
`profiles/` contains any `mcpServers` / `mcp.json` / `mcp_servers` token. Per STATE.md **Q1**
(Answered) broad multi-host wiring is IN SCOPE, and mapping each host's mechanism is a
`/aid-specify` spike. This section executes that spike to the extent the codebase and the author's
knowledge allow.

**Honesty flag (spike limits).** `/aid-specify` (aid-architect) **cannot web-research**. Only the
Claude Code row is CONFIRMED from a repo artifact. Every other row is the best-known mechanism from
the author's knowledge, carried with a `CONFIDENCE` flag; rows flagged `SPIKE-verify-at-implementation`
MUST be verified at implementation time (host docs / probing an installed host) and are deliberately
**NOT** invented — where a path is unknown it is stated as unknown, never fabricated.

**Per-host MCP-config mechanism table** (the single source of truth BOTH the `wire` and the `unwire`
op key off — DATA, not per-host code; see Layers & Components):

| Host | Config file | Scope | Format | Servers container | Per-server entry shape | CONFIDENCE |
|------|-------------|-------|--------|-------------------|------------------------|------------|
| `claude-code` | `.mcp.json` (repo root) | project (committed, shared) | JSON | top-level `mcpServers` object, keyed by server name | `{ "type": "stdio", "command": <bin>, "args": [...], "env": { <VAR>: "${<VAR>}" } }` | CONFIRMED (repo-root `.mcp.json`, this repo — `type`/`command`/`args` shape) |
| `cursor` | `.cursor/mcp.json` (project) | project (committed) | JSON | `mcpServers` object, keyed by server name | `{ "command", "args": [...], "env": {...} }` (Cursor also supports remote `url`/SSE servers) | high (schema mirrors Claude's; exact keys verify-at-implementation) |
| `codex` | `~/.codex/config.toml` (user home) | **user-home — NOT committed** | TOML | `[mcp_servers.<name>]` tables | `command`, `args`, `env` TOML keys | SPIKE-verify-at-implementation (KI-006: profile `agent_format` DORMANT; home-scoped; TOML *write* is nontrivial in-toolchain) |
| `copilot-cli` | MCP-config path **unconfirmed** for the CLI variant | unconfirmed | likely JSON | unconfirmed | unconfirmed | SPIKE-verify-at-implementation (path NOT fabricated; profile installs under `.github/`, which is a hint, not the MCP path) |
| `antigravity` | `mcp_config.json` (path **unconfirmed**; Windsurf-lineage host, likely under a user-config dir) | likely user-home | JSON | likely `mcpServers` | likely `{ "command", "args": [...], "env": {...} }` | SPIKE-verify-at-implementation (Windsurf-lineage inference only) |

Two properties in the table are load-bearing for the design below:

- **Scope axis (project vs user-home).** `claude-code` and `cursor` write **project-scoped,
  committed** files inside the repo tree — these are the files feature-001's P7 allowlist and
  reference-not-value rule target. `codex` (and, pending the spike, likely `antigravity` /
  `copilot-cli`) write **user-home** files **outside** the repo tree: those are per-machine state
  mutations, cannot be committed or shared, and are a nuance beyond feature-001's repo-tree framing
  (see Layers & Components + **KI-007**).
- **Endpoint → entry translation.** feature-001 defines an `mcp` connector's `endpoint` as "an MCP
  server launch spec" (worked example: `endpoint: "npx -y @modelcontextprotocol/server-github"`).
  The wiring adapter tokenizes that string into the host's `command` (first token) + `args` (the
  rest) and attaches the secret as an `env` **reference** (name only — never the value; see Security
  Specs). One descriptor field, five host encodings, one generic routine.

**Worked wiring example** (feature-001's `github` descriptor → the `claude-code` case), merged under
the existing top-level `mcpServers` object, preserving the repo's `playwright-project` entry:

```json
"github": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}" }
}
```

The `env` value is an interpolation **reference** (`${VAR}` passthrough), never the token. Where a
host does not support `${VAR}` interpolation (verify-at-implementation per host), the committed-safe
fallback is to omit `env` and let the MCP server inherit the ambient environment. feature-004
**records the reference only**; reading the value and populating that environment at use-time is
**use-time resolution**, owned by **feature-005's consumption contract / the consuming agent**
(feature-001 Feature Flow; STATE.md Q7 item 3) — not by feature-004.

**Wire-only-installed.** feature-004 wires **only** the hosts present in `.aid/settings.yml`
`tools.installed` (STATE.md Q6 soft default). `tools.installed` is a 2-level list path reachable via
`read-setting.sh --path tools.installed` (within KI-001's 2-level limit — unlike the nested
connectors registry). In this repo `tools.installed` currently lists **`claude-code` only**
(`codex` / `cursor` are commented out), so today only `.mcp.json` is wired; the other four rows are
carried in the mechanism table for coverage and future installs but are **skipped cleanly** (no
error, no empty config file created — AC-1 clean-skip spirit) until their host is installed.

### Data Model

**No new fields.** feature-004 consumes the FROZEN connector-descriptor schema from feature-001
(`.aid/connectors/<connector>.md` frontmatter) exactly as-is; it introduces no schema of its own.
The fields this feature reads:

| Field (feature-001) | How feature-004 uses it |
|---------------------|-------------------------|
| `connection_type` (`mcp` \| `api` \| `ssh` \| `url` \| `cli`) | The router key: `mcp` → host-config wiring; the other four → descriptor is the artifact (no wiring) |
| `endpoint` | For `mcp`: the MCP server launch spec, tokenized into per-host `command` + `args`. For `cli`: a local binary name or local socket path (cross-platform, no new heavy dependency — AC-8). For `api`/`ssh`/`url`: the target the descriptor records |
| `secret_reference` (`env:` \| `keychain:` \| `file:`) | For `mcp`: mapped to an `env` **reference** in the host config (name only). `mcp` connectors SHOULD prefer the `env:` form (see Security Specs) |
| `name` / `<connector>` stem | The server-entry key in the host config; also the merge key for idempotent `wire`/`unwire` |

The `INDEX.md` row, the descriptor body, and the connectors-index builder are feature-001 / feature-005
concerns; feature-004 does not touch them.

### Layers & Components

**One twin, two symmetric ops (`wire` / `unwire`), keyed off the mechanism table (data, not code).**
Per the KB convention "host tools are integrated by render, not adapter … there is no per-tool
runtime branching" (`integration-map.md` Conventions), the wiring twin exposes a **symmetric pair**
of ops that both read the same per-host **mechanism table** (the External Integrations table,
materialized as a committed DATA artifact under the connectors tooling) and both use the same
per-host `config path + format + servers container` resolution and the same idempotent
read-merge-write:

- **`wire <stem>`** — add/update the connector's server entry in each installed host's config (uses `entry template`).
- **`unwire <stem>`** — remove the connector's server entry from each installed host's config (the inverse; no `entry template` needed).

Adding or correcting a host after the spike is a **data-row** edit that both ops inherit at once, not
new code — mirroring how the five profiles are a render, not five adapters.

**Bash + PowerShell twin (mandatory).** Per `coding-standards.md` ("Touching a language twin: change
BOTH twins in the same commit") the wiring ships as a `.sh` + `.ps1`/`.psm1` twin, the same twin rule
feature-001's registry accessor follows. Cross-platform processing of the host configs:

- **PowerShell twin** — native `ConvertFrom-Json` / `ConvertTo-Json` for JSON hosts; ASCII-only and
  Windows-PowerShell-5.1-compatible per `coding-standards.md` (no `utf8NoBOM`, no ternary/null-coalesce,
  no `$IsWindows`). CI-guarded by `ps51-compat-check.ps1`.
- **Bash twin** — the host configs are **genuinely nested JSON/TOML**, not the flat YAML AID parses
  with `awk`. `coding-standards.md` sanctions deferring to a richer processor for genuinely nested
  input ("parse the simple, flat YAML … with `awk` … defer to `yq` only for genuinely nested YAML").
  The in-toolchain processor for nested JSON here is **Python** (`json` stdlib) — Python is explicitly
  within AID's allowed shell/Python/Node toolchain (REQUIREMENTS §6; `aid_profile.py` already relies
  on Python 3.11+), so this is **not a new heavy runtime dependency** (AC-8). Do NOT introduce a hard
  `jq` requirement. **TOML write nuance (codex):** Python's stdlib `tomllib` is **read-only** (no
  writer), so the codex TOML write path needs a line-oriented edit or an added writer — a concrete
  reason codex is `SPIKE-verify-at-implementation` (see KI-006).

**Idempotent MERGE, never overwrite (both ops).** Each host config is **read → merge → write**,
keyed by the server name (the `<connector>` stem), and **preserves every other server** (e.g., the
repo's existing `playwright-project` in `.mcp.json`) plus any user-authored content — the same
in-place philosophy the installer uses for the `AID:BEGIN/END` managed region (`integration-map.md`
"Host AI-Tool Harnesses"):

- **`wire`** — create the file if absent; add/update only this connector's entry. Re-running
  discovery re-wires in place with no duplication.
- **`unwire`** — remove only this connector's entry (its `mcpServers` key, or the per-host
  equivalent — e.g. the codex TOML `[mcp_servers.<name>]` section). Idempotent: a **clean-success
  no-op** if the entry (or the whole file) is already absent; other servers survive untouched. It
  does NOT delete the config file even when it empties the last AID-written entry (a user's other
  servers, or the repo's `playwright-project`, may remain).

**`unwire` ownership + caller (STATE.md Q8).** feature-004 **owns** `unwire` as a first-class op on
this twin; **feature-006's reconcile REMOVE composes it** — invoking `unwire <stem>` for an
`mcp`-typed connector exactly as it invokes feature-003's `purge <stem>` for the secret. So REMOVE =
purge secret (feature-003) + `unwire` host config (feature-004, `mcp` only) + delete descriptor +
regenerate `INDEX.md` (feature-005), with purge/unwire **before** descriptor-delete for
interrupt-safety. feature-006 composes the op; it does not define its own host-config removal.

**Where each config lives / P7 write allowlist.** The write targets are exactly the mechanism-table
`Config file` paths for installed hosts — feature-001's P7 allowlist item 2 ("the per-host MCP-config
paths (feature-004, installed hosts only)"). **Refinement / open item:** feature-001's allowlist is
framed as a **repo-tree** carve-out and cleanly covers the project-scoped configs (`.mcp.json`,
`.cursor/mcp.json`). Hosts whose config is **user-home-scoped** (codex confirmed; antigravity /
copilot-cli pending the spike) require writing **outside the repo tree** — a per-machine mutation the
P7 repo-tree framing does not squarely cover. This SPEC flags it (KI-007) rather than silently
extending the frozen keystone: the out-of-repo write path needs its own idempotency and (given it
mutates user machine state) should confirm the host is installed before touching its home config; the
exact contract is a spike/implementation decision, deferred cleanly by wire-only-installed until such
a host is actually in `tools.installed`.

**No context-file / byte-identity coupling.** The per-host MCP configs are **per-project generated
files**, not profile-rendered assets, so no canonical→profiles render and **no byte-identity guard**
applies to them (contrast feature-001's `## Connectors` context-file edit, which the FR12 AGENTS.md
invariant and the managed-region updater DO constrain). feature-004 writes the config files directly;
it does not edit `canonical/`, `profiles/`, `CLAUDE.md`, or `AGENTS.md`.

### Feature Flow

feature-004 runs as a **producer** inside the P7-exempt `aid-discover` state, after feature-002 has
written the descriptor and feature-003 has stored any secret.

**`mcp` connector — `wire` path (produce / update):**

1. Read `.aid/settings.yml` `tools.installed` → the set of installed hosts (via `read-setting.sh --path tools.installed`).
2. Read the descriptor: `connection_type: mcp`, `endpoint` (launch spec), `secret_reference`.
3. For **each installed host** (skip absent hosts cleanly — no error, no empty file):
   a. Look up the host's row in the mechanism table → `config path`, `format`, `servers container`, `entry template`.
   b. Tokenize `endpoint` → `command` + `args`; attach `env` as a **reference** (var name only) derived from `secret_reference` (prefer `env:`; see Security Specs).
   c. **Read → merge → write** the host config, keyed by the `<connector>` server name; preserve all other servers + user content; idempotent on re-run.
4. `SPIKE-verify-at-implementation` hosts: verify the mechanism-table row before the first real write to that host; do not write to an unconfirmed path.

**`mcp` connector — `unwire` path (reconcile REMOVE; called by feature-006):**

1. Resolve the installed hosts the same way (`read-setting.sh --path tools.installed`); wire-only-installed applies identically — skip hosts not installed.
2. For **each installed host**: look up its mechanism-table row → `config path`, `format`, `servers container`, then **read → merge → write** to delete only this `<connector>`'s server entry (its `mcpServers` key, or the codex TOML `[mcp_servers.<name>]` section, etc.), preserving all other servers + user content.
3. Idempotent: if the entry (or the config file) is already absent, it is a **clean-success no-op**. The config file is not deleted even if the last AID entry is removed.
4. feature-006 REMOVE composes this: `unwire <stem>` (feature-004) + `purge <stem>` (feature-003) run **before** descriptor-delete + `INDEX.md` regenerate (feature-005), for interrupt-safety (STATE.md Q8).

**`api` | `ssh` | `url` | `cli` connector (descriptor path):**

- **No host-config write, no bespoke client.** The feature-001 connection descriptor (transport +
  `endpoint`/target + `secret_reference`) recorded by feature-002 **is** the deliverable; feature-004
  validates it is sufficient for an agent to connect (AC-4 second clause). `cli` covers local binaries
  and local sockets — `endpoint` holds the binary name or socket path, handled consistently across
  Windows / macOS / Linux with no new heavy runtime dependency (AC-8).

**Consumption (out of feature-004, noted for boundary).** MCP-wired tools are consumed directly via
each host's MCP config (feature-005). **Rewiring agents to actively consume non-MCP descriptors is
OUT OF SCOPE** (STATE.md Q4; REQUIREMENTS §4).

### Security Specs

- **Reference-not-value extends to host MCP configs (mandatory).** feature-001's cross-reference bullet
  already states it: "feature-004 may write committed project-scoped MCP config (e.g., a host's
  `.mcp.json`); those files MUST also carry env-var references, never values." A committed MCP config
  (`.mcp.json`, `.cursor/mcp.json`) carries an `env` entry naming the variable (`${VAR}` passthrough),
  never the secret. This is the same rule that makes `.aid/connectors/` safe to commit (feature-001
  Security Specs), now applied to the host configs feature-004 writes.
- **Prefer `env:` for `mcp` connectors.** MCP hosts inject secrets via an `env` block, so the `env:`
  reference form (feature-001) maps cleanly and keeps the committed config value-free. feature-004
  **records only the reference** (the env-var name) into the host config. Where a connector's secret
  is stored under `file:`/`keychain:`, **use-time resolution** — reading the value from the local
  store and exporting it to the named env var — is owned by **feature-005's consumption contract /
  the consuming agent** (feature-001 Feature Flow; STATE.md Q7 item 3), NOT feature-004. Either way
  the committed config names only the variable — the value never enters the file.
- **Leak proof (AC-3) holds after wiring.** After wiring, grepping repo + KB + STATE + transcript for
  the secret value finds nothing: committed host configs carry only the variable name, and the value
  lives only under `.aid/connectors/.secrets/` (feature-001 / feature-003).
- **User-home configs (codex, likely antigravity/copilot-cli).** Not committed (outside the repo), so
  no repo-leak vector — but the **same** no-value rule applies: write only an `env` reference; the
  value stays in the local store. The write is a per-machine mutation (see Layers & Components /
  KI-007).
- **Shipped-code hygiene.** The PowerShell wiring twin is ASCII-only and Windows-PowerShell-5.1
  compatible (`coding-standards.md`); secrets are never echoed or persisted to transcripts / STATE /
  KB (REQUIREMENTS §6).
