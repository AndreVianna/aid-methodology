# Requirements

- **Name:** External Sources & Tool Integrations
- **Description:** Restore external-source elicitation in `aid-discover` and extend it to external tool integrations — **cataloguing** the connections available to the repo's agents (which the host tool already provides via its own MCP/plugin, versus which AID must describe directly as a raw `api|ssh|url|cli`), and registering local auth **only** for the connections AID itself manages — so the agents know what they can reach and how. AID catalogs and informs; it does not provision or wire host tool configurations.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Initial interview started | /aid-describe |
| 2026-07-07 | Objective + Problem Statement captured; scope boundary confirmed (registration-and-wiring only, no bespoke per-tool clients; integration-store placement is an analysis deliverable) | /aid-describe |
| 2026-07-07 | Tool set confirmed generic + presets (user may declare others); connection-type set finalized: mcp, api, ssh, url, cli (db folded in; auth axis kept separate) | /aid-describe |
| 2026-07-07 | Auth/secret-hygiene rules confirmed (reference-not-value, local-only, no echo/persist); functional flow FR-1..FR-7 confirmed | /aid-describe |
| 2026-07-07 | Users, Priority (all Must), Assumptions/Deps, cross-platform + footprint NFRs, and Acceptance Criteria AC-1..AC-8 confirmed; all sections Complete | /aid-describe |
| 2026-07-07 | KB hydration assessed — no as-built KB changes (requirements are forward-looking feature design; belongs in the feature SPEC, not the as-built KB per brownfield rule) | /aid-describe |
| 2026-07-07 | Interview complete — approved | /aid-describe |
| 2026-07-07 | Cross-reference FIX (aid-define): differentiate sources vs tool integrations + build source populate/maintain process (Q2); multi-host MCP wiring across all 5 profiles (Q1); FR-6 reworded "consumable" + non-MCP agent rewiring out-of-scope (Q4); purge secret on tool removal (Q3); absolute KB-no-secrets rule + pre-existing-secret cleanup out-of-scope + AC-3 scope clarified (Q5); §1 CLI added (#4) | /aid-define |
| 2026-07-07 | Cross-reference complete — all 6 findings fixed, regraded A+ | /aid-define |
| 2026-07-09 | **Q10 reframe (user-directed, mid-Execute):** catalog, not manager. AID does NOT wire/manage host MCP configs; it catalogs connection availability + how to connect. Tool-managed connectors (host provides MCP/plugin) → agent requests from the tool, tool handles auth, no AID cred; aid-managed connectors (direct api/ssh/url/cli) → AID records descriptor + local auth. De-wired Description/§1/§4/FR-4/FR-6/§8/AC-4; supersedes Q1+Q8, amends Q9. | user / aid-execute loopback |

## 1. Objective

Restore the external-source elicitation that `aid-init` performed before project bootstrap
migrated into `aid-config`/`settings.yml`, relocating that responsibility to `aid-discover`,
and extend it into full external **tool/integration** support. During discovery the user can
declare the external sources and tools the project depends on (e.g., Jira, Slack,
GitLab/GitHub, Confluence, Notion, Jenkins, Docker). For each declared tool AID **catalogs the
connection and how an agent reaches it**: when the host tool (Claude Code, Codex, Cursor, …)
already provides its own MCP server or plugin for the target, the catalog points the agent to
the tool's own MCP/plugin (the **tool** handles auth); when the target is reached by a direct
API/SSH/URL/CLI the tool does **not** provide, AID records a connect-sufficient descriptor and
registers its auth **locally only**. AID stores credentials **only** for the connections it
manages, never for tool-managed ones. The resulting registry is a catalog the repo's agents
consult to know what they can reach and how. Determining where these integration descriptors
and local auth live (within the KB vs a separate folder) is itself part of the work.

**External sources** and **tool integrations** are distinct and handled separately (see §4):
sources are reference material (docs/specs/URLs); tool integrations are connectable tools.

## 2. Problem Statement

`aid-init` used to prompt the user for the external sources associated with a project. That
prompt was lost when project bootstrap migrated to `settings.yml` via `aid-config`, so
external sources are no longer captured — the `external-sources.md` KB doc exists but has no
working gather/populate/maintain process behind it (it still records "No external documentation
was provided during discovery"). Separately, AID has never had a way to capture external
*tools*/integrations at all, nor to register connections and (local) credentials that its
agents could then use. As a result the repo's agents cannot discover or connect to the
project's real toolchain (issue trackers, chat, CI, source hosts, docs, containers).

## 3. Users & Stakeholders

- **Primary user** — the developer/adopter running `aid-discover` on their project, who declares the external sources and tools.
- **Primary consumer** — the repo's **AID agents** (aid-researcher, aid-developer, etc.) that read the registry and connect to the tools to do their work. (Implies the registry must be machine-readable, not just human prose — see FR-6.)
- **Stakeholder** — AID maintainers (this work changes `aid-discover` and the KB/registry schema).
- **Indirect** — the project's team, who benefit when agents can reach the real toolchain (issue trackers, CI, chat, docs, containers).

## 4. Scope

### In Scope

- **Differentiate two distinct kinds of external dependency** (different shapes, different homes): **external sources** = docs / vendor specs / reference URLs (reference knowledge) → land in the existing `external-sources.md`; **tool integrations** = connectable tools + connection type + endpoint + local auth reference → a net-new registry (home decided by the placement analysis).
- Restore external-**source** elicitation as a responsibility of `aid-discover`: build the gather/populate/maintain **process** (the `external-sources.md` doc exists but has no working process behind it) and land sources there.
- Extend elicitation to external **tools/integrations**. The mechanism is **generic and extensible**: a curated list of commonly-used tools ships as presets (sensible defaults), and the user can declare any other tool that isn't listed.
- Support a fixed set of **connection types** (the transport an agent uses to reach a tool): `mcp`, `api`, `ssh`, `url`, `cli` (local binary / local socket — covers Docker + dev CLIs). `db` is deliberately not a first-class type (folds under `cli`/`api`). Connection **type** is orthogonal to **auth** method (token/PAT/OAuth/SSH-key), which is registered separately and locally.
- Register any required auth **locally only** (never committed to the repo).
- Make the tool registry consumable by the repo's agents: a machine-readable **catalog** + a documented consumption contract. Each connector records its **management mode** — **tool-managed** (the host tool provides its own MCP/plugin; the catalog instructs the agent to request the connection from the tool, which handles auth) or **aid-managed** (a direct `api|ssh|url|cli` the tool does not provide; AID records a connect-sufficient descriptor + a local auth reference). AID does **not** write, wire, or manage any host tool's MCP configuration.
- **Analyze and decide where integration descriptors + local auth should live** (within the KB vs a separate folder) — a deliverable of this work, not a pre-settled assumption.

### Out of Scope

- Building bespoke per-tool client code/adapters (a Jira client, a Slack client, etc.). Agents connect via MCP or the recorded descriptor, not custom clients.
- **Building agent-side code that actively consumes connection descriptors.** The registry is made consumable (machine-readable catalog + documented consumption contract), but code that rewires individual agents to act on descriptors is not built here.
- **Writing, wiring, or managing any host tool's MCP configuration.** For tool-managed connectors the agent requests the connection from the host tool's own MCP/plugin (the tool owns that config and its auth); AID only catalogs availability (Q10).
- **Remediating or cleaning pre-existing secrets already committed in the project's source or codebase.** Those are surfaced as tech-debt / risk by the discovery phase (`aid-discover`), not remediated by this feature.

## 5. Functional Requirements

**FR-1 — Elicitation in discovery.** `aid-discover` MUST interactively prompt the user for (a) external **sources** (docs, vendor specs, reference URLs) and (b) external **tools/integrations**. The elicitation MUST be skippable when a project has none. Sources and tool integrations are captured as **distinct kinds**: the source side builds the gather/populate/maintain process and lands results in `external-sources.md`; tool integrations populate the net-new registry.

**FR-2 — Generic + preset declaration.** For each declared tool the system MUST capture: name, connection type (`mcp|api|ssh|url|cli`), endpoint/target, and auth method plus a *reference* to where the secret lives. A curated set of commonly-used tools MUST be offered as **presets** that pre-fill sensible defaults; the user MUST be able to declare any tool not in the preset list via the **generic** descriptor.

**FR-3 — Local auth registration.** When a tool requires auth, the system MUST prompt for the secret and store it in a local, git-ignored / OS-appropriate location, recording only a reference in the registry (per §6 security rules).

**FR-4 — Connection cataloguing (management mode).** For each declared tool the system MUST record its **management mode** and how an agent connects:
- **tool-managed** — when the host tool already provides an MCP server or plugin for the target, the catalog MUST record that the connection is available through the host tool and instruct the agent to **request it from the tool** (which handles auth). AID MUST NOT write any host MCP configuration and MUST NOT store a credential for it.
- **aid-managed** — when the target is reached by a direct `api|ssh|url|cli` the host tool does not provide, the system MUST record a connection descriptor sufficient for an agent to connect (endpoint/target + connection type) and register its auth locally (FR-3).

AID does not provision, wire, or manage host tool configurations; it catalogs availability and how to connect.

**FR-5 — Persistence.** The system MUST persist **external sources** to `external-sources.md` and the **tool/integration registry** to its determined home (the placement decided by the work's analysis — KB vs separate folder).

**FR-6 — Agent consumption.** The registered sources/tools MUST be **consumable** by the repo's agents: a machine-readable catalog plus a documented consumption contract. For a **tool-managed** connector the contract MUST tell the agent to request the connection from the host tool's own MCP/plugin; for an **aid-managed** connector it MUST tell the agent to resolve the local auth reference at use-time and connect via the recorded descriptor. (Building agent-side code that actively consumes descriptors is out of scope — the contract is documented + machine-readable; see §4.)

**FR-7 — Idempotent reconcile.** Re-running `aid-discover` MUST reconcile the registry (add new, update changed, remove absent) without clobbering surviving entries or their stored secrets. When a tool is **removed**, its associated local secret MUST be **purged** from the local store.

## 6. Non-Functional Requirements

### Security & secret hygiene

- Secrets are **never** written to the repo or the KB. The committed registry stores only a *reference* to a secret (an env-var name, an OS-keychain key, or a path to a git-ignored local file) — never the secret value.
- Actual secret values live in a **local, git-ignored / OS-appropriate location** (exact location decided by the work's placement analysis).
- Discovery **must not echo or persist entered secrets** into transcripts, STATE.md, or the KB.
- Agents **resolve secrets at use-time** from the local store via the reference; the descriptor conveys *how* to connect and *where* to find the credential, not the credential itself.
- **Absolute rule:** under **no circumstance** does the KB (or the committed registry) expose *any* secret — neither our registered secrets nor any secret encountered during elicitation or scanning. (This mechanism's local-only guarantee is scoped to the secrets it registers; pre-existing secrets already committed in project source are out of scope for cleanup — see §4 — and are flagged as tech-debt/risk by discovery.)

### Cross-platform & footprint

- The local secret store and `cli`/socket handling MUST work on **Windows, macOS, and Linux**.
- **No new heavy runtime dependency** — implement within AID's existing shell/Python/Node toolchain (per `coding-standards.md`).

## 7. Constraints

- The KB is **committed and shared**, so the registry/descriptors must be safe to commit and the secret **reference-not-value** split is mandatory (a hard environmental constraint, not a preference).
- The feature must **integrate with the existing `aid-discover` state machine and KB/authoring conventions**, not introduce a parallel mechanism.

## 8. Assumptions & Dependencies

### Dependencies

- The existing `aid-discover` machinery (`GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE`) and the KB authoring/schema conventions — elicitation slots into discovery; the registry follows KB conventions.
- Host-tool **MCP/plugin support** — a tool-managed connector assumes the host tool provides an MCP server or plugin for that target, which the agent requests from the tool. AID does not create that support; it catalogs its availability. (No AID-side MCP-config wiring — Q10.)
- Cross-platform behavior across Windows, macOS, and Linux (see §6).

### Assumptions

- Discovery runs **locally in a trusted environment**, so prompting for secrets is acceptable.
- A **git-ignored local location** is available (the repo's `.gitignore` can be extended).
- The work stays within AID's existing shell/Python/Node toolchain — no new heavy runtime dependency (see §6).

## 9. Acceptance Criteria

- **AC-1** — Running `aid-discover` prompts for external **sources** and **tools** (as distinct kinds), and skips cleanly when there are none (no empty artifacts written).
- **AC-2** — A user can declare both a **preset** tool (e.g., GitHub) and a **custom/non-preset** tool via the generic descriptor; each is captured with connection type, endpoint/target, and an auth *reference*.
- **AC-3** — After entering a secret, grepping the **repo + KB + STATE + transcript** for that secret value finds **nothing**; the value exists only in the local git-ignored store (reference-not-value proven). Scope: this verifies *our registered* secret never leaks — it is NOT a repo-wide scan for pre-existing committed secrets (those are discovery's tech-debt/risk concern).
- **AC-4** — A **tool-managed** connector is catalogued as available via the host tool's own MCP/plugin, and the consumption contract instructs the agent to request it from the tool — **no host MCP config is written and no credential is stored** for it; an **aid-managed** `api|ssh|url|cli` connector yields a connect-sufficient descriptor plus a local auth reference an agent can act on.
- **AC-5** — External sources are persisted to `external-sources.md` and the tool/integration registry to its determined home, both in a **machine-readable** form agents can read (FR-6), and documented for humans.
- **AC-6** — Re-running `aid-discover` after add/change/remove **reconciles** the registry without losing surviving entries or their stored secrets; a **removed** tool's associated local secret is **purged** from the local store.
- **AC-7** — The **placement decision** (where registry + auth live) is produced as an explicit analysis artifact/decision in the work.
- **AC-8** — Verified on **Windows, macOS, and Linux**; no new heavy runtime dependency introduced.

## 10. Priority

All requirements (FR-1..FR-7, the security NFRs, and the constraints) are **Must-have** for
this work — there is no Should/Could tier and no deferred phase; the feature is delivered
complete. (Non-MCP agent-side descriptor consumption is **out of scope**, per §4 — a scope
boundary, not a deferred phase.) The **placement analysis** still leads in *sequencing* (it
gates the registry schema everything else writes to), but that is an ordering concern for
`/aid-plan`, not a lower priority.
