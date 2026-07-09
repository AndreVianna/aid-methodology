# Connection Modes and Consumption

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5 (FR-4) + §9 (AC-4, AC-8); see Source for other §refs | /aid-define |
| 2026-07-08 | Technical Specification authored (External Integrations, Data Model, Layers & Components, Feature Flow, Security Specs). Executed the Q1-authorized per-host MCP-config spike: mechanism table for all 5 hosts with CONFIDENCE flags. Binds feature-001 FROZEN keystone; wire-only-installed; added KI-007. **[SUPERSEDED by the 2026-07-09 Q10 reframe — the wiring premise is removed.]** | /aid-specify |
| 2026-07-08 | FIX pass (A+ gate, C+ → 1 MEDIUM): removed the invented "feature-003 resolver"; use-time resolution owned by feature-005 / the consuming agent. **[SUPERSEDED by Q10.]** | /aid-specify |
| 2026-07-08 | Cross-feature FIX (aid-plan gate, STATE.md Q8): defined a feature-004-OWNED `unwire` op symmetric to `wire`; feature-006 reconcile REMOVE composes it. **[SUPERSEDED by Q10 — AID neither wires nor unwires; there is no `wire`/`unwire` op.]** | /aid-specify |
| 2026-07-09 | **Q10 reframe (user-directed, mid-Execute) — feature REWRITTEN "Connection Wiring" → "Connection Modes and Consumption".** The connectors registry is a CATALOG, not a connection manager: AID does NOT write, wire, or manage any host tool's MCP configuration, and stores no credential for connections a host tool manages. Removed the entire wiring premise — the per-host MCP-config mechanism table, the `wire`/`unwire` twin, the read-merge-write host-config path, and the KI-007 out-of-repo-write edge are all DELETED. The feature now (a) defines the two **management modes** — **tool-managed** ⟺ `connection_type: mcp`, **aid-managed** ⟺ `api\|ssh\|url\|cli` (derived from `connection_type`, per feature-001) — and (b) defines the **per-mode consumption semantics**: tool-managed → the agent requests the connection from the host tool's own MCP/plugin (the tool handles auth; AID writes nothing and stores no credential); aid-managed → the agent resolves the local `secret_reference` at use-time and connects via the recorded descriptor. Supersedes Q1 + Q8; aligns with corrected REQUIREMENTS FR-4 / FR-6 / AC-4 / §4 / §8. | user / aid-execute loopback |

## Source

- REQUIREMENTS.md §4 (Scope — connection types + management mode; no bespoke per-tool clients; AID does not wire host configs), §5 FR-4 (Connection cataloguing / management mode), §8 (Dependencies — host-tool MCP/plugin support the agent requests)
- REQUIREMENTS.md §9 Acceptance Criteria: AC-4, AC-8 (cross-cutting, cli/socket handling)
- STATE.md `## Cross-phase Q&A` **Q10** (authoritative model — catalog, not manager); supersedes **Q1** and **Q8**

## Description

This feature turns a declared connector into something an agent knows **how to reach**, without
building any bespoke per-tool client code and **without AID provisioning, wiring, or managing any
host tool's configuration**. Every connector carries one of two **management modes**, and the
feature defines what each mode means and how an agent consumes it.

- **tool-managed** (the common case, `connection_type: mcp`) — the host tool (Claude Code, Codex,
  Cursor, Copilot CLI, Antigravity) already provides its **own** MCP server or plugin for the target
  (e.g. Jira, GitHub). The catalog records that the connection is **available via the host tool** and
  instructs the agent to **request it from the tool**. The **tool handles authentication**; AID
  writes **no** host MCP configuration and stores **no** credential for it.
- **aid-managed** (the rarer case, `connection_type: api | ssh | url | cli`) — the target is reached
  by a direct transport the host tool does **not** provide (e.g. a Microsoft 365 REST API when no MCP
  exists). The catalog records a connect-sufficient **descriptor** (transport + endpoint/target +
  auth reference) and AID stores the required credential in the local git-ignored store (feature-003),
  which the agent resolves at use-time.

The management mode is **derived from `connection_type`** (feature-001's schema): `mcp` ⟺
tool-managed; `api | ssh | url | cli` ⟺ aid-managed. `cli` covers local binaries and local sockets,
which must be handled consistently across Windows, macOS, and Linux and within AID's existing
toolchain, introducing no new heavy runtime dependency.

The descriptor shape this feature reasons over is the schema FROZEN by the
integration-store-placement feature; the connectors classified here are the ones captured by
source-and-tool elicitation. This feature writes no artifact of its own — it is a **contract**:
the management-mode model plus the per-mode consumption semantics that feature-005 publishes into
the documented consumption contract.

## User Stories

- As a developer/adopter, I want each mcp connector catalogued as **available via my host tool's own
  MCP/plugin** so that an agent knows to request it from the tool (which handles auth) rather than
  expecting AID to wire or authenticate it.
- As a developer/adopter, I want each api/ssh/url/cli connector recorded as a connection descriptor
  with a local auth reference so that an agent has a concrete, client-free way to connect directly.
- As an AID agent, I want an unambiguous rule for how to connect **per management mode** so that I
  never try to consume a tool-managed connector as if AID had wired it, nor a raw descriptor as if a
  host tool provided it.
- As a developer/adopter on any of Windows, macOS, or Linux, I want cli and socket handling to behave
  consistently so that aid-managed consumption is not platform-specific.

## Priority

Must

## Acceptance Criteria

- [ ] Given a declared **tool-managed** (`mcp`) connector, when it is catalogued, then it is recorded as available via the host tool's own MCP/plugin and the consumption contract instructs the agent to **request it from the tool** — **no host MCP config is written and no credential is stored** for it. (FR-4, AC-4)
- [ ] Given a declared **aid-managed** (`api | ssh | url | cli`) connector, when it is catalogued, then a connection descriptor sufficient for an agent to connect is recorded (transport + endpoint/target + local auth reference), with no bespoke per-tool client code, and the consumption contract instructs the agent to resolve the local reference at use-time and connect via the descriptor. (FR-4, AC-4)
- [ ] Given the management mode, when a connector is classified, then its mode is derived deterministically from `connection_type` (`mcp` → tool-managed; `api | ssh | url | cli` → aid-managed) with no separate, drift-prone stored field. (FR-4, feature-001 schema)
- [ ] Given aid-managed `cli` and socket handling, when consumption is exercised on Windows, macOS, and Linux, then it works on all three and introduces no new heavy runtime dependency. (AC-8)

---

## Technical Specification

> Authored by `/aid-specify`; **rewritten by the 2026-07-09 Q10 loopback**. This feature defines the
> **management-mode model** and the **per-mode consumption semantics**; it does NOT define the schema,
> the home, or the secret rules (FROZEN by
> `feature-001-integration-store-placement/SPEC.md`, the keystone — this SPEC BINDS to it and does not
> redefine it), and it **writes no artifact**. The old "wire the MCP server into each host's MCP
> config" premise is **gone** (STATE.md **Q10**, superseding **Q1** + **Q8**): AID does not write,
> wire, or manage any host tool's MCP configuration. Two management modes, derived from
> `connection_type`:
>
> - **tool-managed** (`connection_type: mcp`) → the host tool provides its **own** MCP server/plugin
>   for the target. The catalog records availability and tells the agent to **request the connection
>   from the tool**; the **tool handles auth**. AID writes **no** host config and stores **no**
>   credential (FR-4, AC-4).
> - **aid-managed** (`connection_type: api | ssh | url | cli`) → a direct transport the host tool does
>   not provide. The **descriptor** recorded per feature-001 (transport + endpoint/target + auth
>   reference) IS the connect artifact, plus a local secret in feature-003's store; the agent resolves
>   the reference at use-time and connects directly. **No bespoke per-tool client code** (REQUIREMENTS
>   §4).
>
> **Ownership boundary with feature-005 (no drift).** feature-004 is the authoritative source of the
> **mode model + connect semantics**. feature-005 **publishes** those semantics into the documented
> consumption contract (its home is the `## Connectors` context section, per STATE.md Q7 item 6) and
> owns `INDEX.md` regeneration + the serialization/consumption VIEW; it **references** this model and
> does not redefine it. feature-004 introduces no writer, no twin, and no host-config write.

### External Integrations

The only external integration surface in play is the one the **host tool** owns, and AID never
touches it.

**tool-managed (`mcp`).** The integration is the host tool's **own** MCP server or plugin for the
target (Claude Code, Codex, Cursor, Copilot CLI, Antigravity each provide their own). AID does **not**
create, write, or manage that MCP configuration — there is **no** per-host MCP-config mechanism table,
**no** read-merge-write, and **no** `wire`/`unwire` op (all removed at the Q10 reframe). The catalog
records only that the connection is **available via the host tool** and instructs the agent to
**request it from the tool at use-time**; the tool prompts for / supplies whatever auth it needs. This
is grounded in `integration-map.md` §"Host AI-Tool Harnesses (the five profiles)" — the five hosts are
integrated by render, and each host owns its own MCP surface; AID catalogs availability, it does not
provision the surface.

**aid-managed (`api | ssh | url | cli`).** There is **no** host-tool integration; the target is
reached **directly** using the recorded descriptor. `endpoint` holds the URL/host/socket/binary the
agent connects to, `secret_reference` names where the local credential lives (feature-001 /
feature-003), and the agent resolves it at use-time. `cli` covers local binaries and local sockets,
handled consistently across Windows / macOS / Linux with no new heavy runtime dependency (AC-8). No
bespoke per-tool client is built (REQUIREMENTS §4).

**What AID never does (Q10, hard rule).** AID does not write any host tool's MCP configuration
(`.mcp.json`, `.cursor/mcp.json`, `~/.codex/config.toml`, or any other), does not merge server
entries, and does not store a credential for a tool-managed connector. The former per-host mechanism
spike (task-013) and mechanism-table artifact (task-014) are obsolete under this model (see the
delivery re-plan the orchestrator applies).

### Data Model

**No new fields; management mode is DERIVED, not stored.** feature-004 consumes the FROZEN
connector-descriptor schema from feature-001 (`.aid/connectors/<connector>.md` frontmatter) exactly
as-is and introduces no schema of its own. The management-mode axis is a **derivation** over the
existing `connection_type` field (feature-001 §"Connector descriptor schema"), not a separate
persisted field — a single source of truth, so the two can never drift:

| `connection_type` | Management mode (derived) | Consumption |
|-------------------|---------------------------|-------------|
| `mcp` | **tool-managed** | Agent requests the connection from the host tool's own MCP/plugin; tool handles auth; AID stored nothing |
| `api` \| `ssh` \| `url` \| `cli` | **aid-managed** | Agent resolves the local `secret_reference` at use-time and connects via the recorded descriptor |

The fields this feature reads (all owned/frozen by feature-001):

| Field (feature-001) | How feature-004 uses it |
|---------------------|-------------------------|
| `connection_type` (`mcp` \| `api` \| `ssh` \| `url` \| `cli`) | The mode key: `mcp` → tool-managed; the other four → aid-managed |
| `endpoint` | For tool-managed: informational (the target the host tool's MCP/plugin reaches). For aid-managed: the concrete connect target — URL/host/socket path/local binary the agent uses directly (`cli` cross-platform, no new heavy dependency — AC-8) |
| `auth_method` / `secret_reference` | For tool-managed: `auth_method` is `none` and there is **no** `secret_reference` (AID stores no credential; the tool authenticates). For aid-managed: `secret_reference` names the local credential the agent resolves at use-time |
| `name` / `<connector>` stem | Identity/routing only |

The `INDEX.md` row, the descriptor body, the connectors-index builder, and the descriptor authoring
are feature-001 / feature-002 / feature-005 concerns; feature-004 does not write any of them.

### Layers & Components

**No code, no twin — this is a contract feature.** The Q10 reframe **deletes** feature-004's former
implementation surface: the per-host MCP-config mechanism table, the Bash+PowerShell `wire`/`unwire`
twin, the Python-stdlib nested-JSON/TOML writer, the idempotent read-merge-write, wire-only-installed,
and the KI-007 out-of-repo-write edge are all gone. AID writes **nothing** here.

What remains is a **definition** realized by other features:

- **Classification (author time).** feature-002 ELICIT records `connection_type` on each descriptor.
  The management mode follows by the derivation rule above — no extra capture step, no wiring trigger.
  (feature-002's former "mcp → trigger feature-004 wiring" hook is removed.)
- **Consumption semantics (use time).** The per-mode connect steps below (Feature Flow) are the
  normative contract. They are **published** by feature-005 into the `## Connectors` context section
  (feature-001's wiring; STATE.md Q7 item 6) and are what an agent follows. feature-005 owns the
  published contract text + INDEX regeneration; feature-004 owns the model those reference.
- **aid-managed cross-platform note.** For `cli`/socket connectors the agent connects directly via the
  descriptor `endpoint`; this must behave the same on Windows/macOS/Linux and stay within AID's
  existing shell/Python/Node toolchain (AC-8). No new heavy runtime dependency is introduced (nothing
  is implemented here at all).

**No context-file / byte-identity coupling.** feature-004 edits no `canonical/`, `profiles/`,
`CLAUDE.md`, `AGENTS.md`, or host config — it authors a contract consumed by feature-005's published
`## Connectors` section, whose byte-identity guards (FR12) are feature-001's / feature-005's concern.

### Feature Flow

feature-004 produces **no** write. It contributes a classification rule (applied at author time) and
the per-mode consumption semantics (applied at agent use-time).

**Classification (at descriptor author time — feature-002):**

1. feature-002 records `connection_type` on the `.aid/connectors/<connector>.md` descriptor.
2. Management mode is derived: `mcp` → tool-managed; `api | ssh | url | cli` → aid-managed.
3. **tool-managed:** the descriptor records availability via the host tool; `auth_method: none` and
   **no** `secret_reference` (AID stores no credential). No feature-003 secret capture, no host-config
   write, no wiring trigger.
4. **aid-managed:** feature-002 records the connect descriptor; when `auth_method != none`, feature-003
   stores the local secret and the descriptor carries its `secret_reference`.

**Consumption (at agent use-time — the normative per-mode contract feature-005 publishes):**

- **tool-managed (`mcp`):** the agent **requests the connection from its host tool's own MCP/plugin**
  (the host harness's native MCP mechanism). The **tool** establishes and authenticates the
  connection. AID contributed no host config and no credential; the descriptor exists for
  discovery/audit and to tell the agent which tool-provided connection to request.
- **aid-managed (`api | ssh | url | cli`):** the agent reads the descriptor (`endpoint` +
  `auth_method` + `secret_reference`), **resolves the credential at use-time** from the reference
  (`env:` → env var; `file:` → `.aid/connectors/.secrets/<connector>`; `keychain:` → OS keychain —
  feature-001 §Security), and connects **directly** via `endpoint`. No bespoke client. `cli` reaches a
  local binary/socket cross-platform (AC-8).

**Consumption boundary (noted).** Building agent-side code that actively consumes descriptors is **OUT
OF SCOPE** (STATE.md Q4; REQUIREMENTS §4). The contract is documented + machine-readable (feature-005);
the code that acts on it is not built here.

### Security Specs

- **No credential for tool-managed connectors (Q10).** A tool-managed (`mcp`) connector has **no**
  AID-stored credential and **no** `secret_reference` — the host tool owns and resolves its auth. AID
  writes no host MCP config, so there is no host-config leak vector at all.
- **Reference-not-value for aid-managed connectors (mandatory).** An aid-managed connector's descriptor
  carries only a `secret_reference` (`env:` / `file:` / `keychain:`), never a value (feature-001
  Security Specs; realized by feature-003). Use-time resolution — reading the value from the local
  store and using it to connect — is owned by **feature-005's consumption contract / the consuming
  agent** (STATE.md Q7 item 3), not by feature-004.
- **Leak proof (AC-3) holds.** Nothing feature-004 does can leak a secret: it writes nothing. For
  aid-managed connectors the value lives only under `.aid/connectors/.secrets/` (feature-001 /
  feature-003) and the committed descriptor names only the reference; grepping repo + KB + STATE +
  transcript for the value finds nothing.
- **No host-config writes anywhere (Q10).** Because AID writes no host MCP configuration — neither the
  in-repo `claude-code` `.mcp.json` nor any user-home config (codex/cursor/copilot-cli/antigravity) —
  the former CF5 / KI-007 out-of-repo-write concern no longer exists.
