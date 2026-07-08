# Registry Persistence and Consumption

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5 (FR-5, FR-6) + §9 (AC-5); see Source for other §refs | /aid-define |
| 2026-07-08 | Technical Specification authored (Feature Flow, Layers & Components, Data Model, External Integrations); binds to feature-001's FROZEN `.aid/connectors/` contract (schema, separate connectors-index builder, context-file wiring) — references, does not redefine; FR-6 "consumable" realized (machine-readable registry + documented consumption contract); non-MCP agent rewiring stated OUT OF SCOPE (Q4) | /aid-specify |
| 2026-07-08 | FIX pass (A+ gate, grade C+): reconciled ownership to the Q7 matrix — feature-005 owns the connectors `INDEX.md` builder (DETERMINISTIC, no timestamp) + regeneration, the documented consumption contract (home = `## Connectors` context section, NOT an INDEX.md preamble; Row 1 MEDIUM), and the serialization/consumption VIEW; removed the source-writer and descriptor-writer components (Scout writes sources / feature-002 authors descriptors / feature-003 writes-purges secrets — Q7 items 1–5, resolving the 3 OOS drifts); quoted `external-sources.md` `summary:` in full (Row 1 MINOR) | /aid-specify |

## Source

- REQUIREMENTS.md §3 (Users & Stakeholders — AID agents are the primary consumer), §5 FR-5 (KB landing / persistence), §5 FR-6 (Agent consumption), §6 (resolve secrets at use-time)
- REQUIREMENTS.md §9 Acceptance Criteria: AC-5

## Description

This feature persists what elicitation captured, routing each kind to its own home: external
sources persist to the existing external-sources.md Knowledge Base doc, and the tool integration
registry persists to its own home (the location decided by the integration-store-placement
feature). Both are written in a machine-readable form that agents can read, and documented for
humans as well.

Consumable, here, has a precise meaning: a machine-readable registry plus a documented
consumption contract. The contract describes how an agent discovers a registered source or tool
and how it connects — MCP-wired tools are directly usable via each host's MCP config, and the
rest are described by the recorded descriptor plus the local auth resolved at use-time from its
reference. Registered sources and tools are discoverable through the KB.

Scope boundary (approved): this feature delivers the machine-readable registry, the documented
consumption contract, and KB discoverability. MCP-wired tools are directly usable via each
host's MCP config. Rewiring individual agents (for example aid-researcher, aid-developer) to
actively consume the non-MCP connection descriptors is deferred and is out of scope for this
work — the registry is made consumable and the contract is documented, but agent-side
descriptor consumption is not built here.

## User Stories

- As an AID agent, I want the sources and integration registry persisted in a machine-readable
  form at a known home so that I can discover the project's toolchain without re-eliciting it.
- As an AID agent, I want MCP-wired tools usable directly via each host's MCP config and a
  documented contract for the rest so that I know how connections are meant to work.
- As a developer/adopter, I want the persisted registry documented for humans so that I can read
  and verify what was captured.

## Priority

Must

## Acceptance Criteria

- [ ] Given elicited sources and declared tools, when persistence runs, then sources are written to the existing external-sources.md doc and the tool integration registry is written to its determined home (per feature-001), both in a machine-readable form and documented for humans. (AC-5, FR-5)
- [ ] Given the persisted registry, when an agent needs the project's toolchain, then it is consumable as a machine-readable registry plus a documented consumption contract describing how to connect (MCP-wired tools directly usable via each host's MCP config; the rest via descriptor plus use-time-resolved auth), discoverable through the KB. (AC-5, FR-6)
- [ ] Given an mcp-wired tool, when an agent operates, then the tool is directly usable via each host's MCP config. (FR-6, approved lean scope)

---

## Technical Specification

> Authored by `/aid-specify`. Per the **Q7 cross-feature ownership matrix** (STATE.md
> `## Cross-phase Q&A` Q7), feature-005 owns exactly three things: (1) **regeneration of the
> connectors `INDEX.md`** — feature-005 owns the builder, feature-001 froze its contract; (2) the
> **documented consumption contract** (FR-6), incl. use-time secret resolution; and (3) the
> **machine-readable serialization / consumption VIEW** over what the producers write. It is
> **NOT** a descriptor / secret / source writer that producers "call": producers write their own
> artifacts (feature-002 authors descriptors, feature-003 writes/purges secret values,
> feature-004 writes host MCP config + wiring fields), and external **sources** persist via the
> existing **Scout** back-end fed by feature-002 elicitation — feature-005 defers to Scout there
> (Q7 items 1–6; REQUIREMENTS §7 "no parallel mechanism"). It does NOT redefine the store, the
> descriptor schema, the `INDEX.md` contract, or the context-file wiring — those are **FROZEN by
> feature-001**
> (`.aid/work-002-external_sources/features/feature-001-integration-store-placement/SPEC.md`)
> and are **referenced** here, never re-derived. Two homes: external **sources** →
> `.aid/knowledge/external-sources.md` (STATE.md Q2, via Scout); the tool/integration **registry**
> → `.aid/connectors/` (producer-written descriptors + a feature-005-regenerated `INDEX.md`, per
> feature-001). Both are machine-readable AND human-documented (FR-5, AC-5).
>
> **FR-6 "consumable" scope (Q4).** Consumable = a **machine-readable registry** PLUS a
> **documented consumption contract**; MCP-wired tools are directly usable via each host's MCP
> config (feature-004). **Rewiring individual agents (`aid-researcher`, `aid-developer`, …) to
> actively consume the non-MCP connection descriptors is OUT OF SCOPE** (STATE.md Q4,
> REQUIREMENTS §4 Out-of-Scope, FR-6). The registry is made consumable and the contract is
> documented; the agent-side descriptor-consumption code is not built here.

### Feature Flow

This feature indexes, documents, and defines the consumption view for what the producers persist
into feature-001's contract. There are **two persistence routes** (each with its own
discoverability mechanism) and one documented consumption (READ) flow. feature-005 does not write
the route artifacts; it owns the connectors `INDEX.md` regeneration, the consumption contract, and
the serialization/consumption view.

**Route A — external sources → the Knowledge Base (writer = Scout; feature-005 does NOT write it).**

1. Elicitation (feature-002 ELICIT) captures the declared external sources (docs / vendor specs /
   reference URLs) and feeds the `## External Documentation` STATE table, making the existing
   **Scout** back-end's Step-1 skip **content-aware** (Q7 item 4).
2. The **single writer** of `.aid/knowledge/external-sources.md` remains **Scout** — it writes the
   `## Sources` body and refreshes the frontmatter `sources:` list and `summary:` (the `summary:`
   is currently "Read this before fetching documentation that may already be cataloged here. No
   external documentation was provided during discovery." and MUST be refreshed on populate or the
   RAG routing table misleads agents — **KI-004**, owned by feature-002/Scout, not feature-005).
   feature-005 introduces **no** parallel source-writer (REQUIREMENTS §7; Q7 item 4).
3. Because `external-sources.md` lives **inside** `.aid/knowledge/`, it is (a) written in the
   **normal P7-allowed KB write zone** (P7 permits writes within `.aid/knowledge/`,
   `.aid/generated/`, `.aid/.temp/`; see feature-001 §"P7 read-only carve-out"); (b) re-indexed by
   the KB index builder `build-kb-index.sh`, which runs LAST in the discover cycle
   (`canonical/aid/templates/kb-authoring/principles.md` P3), refreshing the `external-sources.md`
   row in `.aid/knowledge/INDEX.md`; and (c) discoverable through the existing `## Knowledge Base`
   context pointer (`@.aid/knowledge.`). feature-005's contribution here is the **serialization /
   consumption VIEW** (Data Model) — how an agent reads sources — not the write.
4. Skippable (AC-1): when no sources are declared, Scout leaves `external-sources.md` in its "none"
   state — no empty-artifact churn.

**Route B — tool integrations → the connectors registry (producers write; feature-005 regenerates
`INDEX.md`).**

1. Producers write their own artifacts (Q7 items 1–2): feature-002 **authors** the
   `.aid/connectors/<connector>.md` descriptor (feature-001 frontmatter schema) with its
   `secret_reference` (never a value); feature-003's secret twin writes the secret **value** to
   `.aid/connectors/.secrets/<stem>`; feature-004 **updates** wiring fields and writes the host MCP
   config for `mcp` connectors.
2. After **any** descriptor add / update / remove / wire, the producer **triggers feature-005's
   connectors `INDEX.md` builder** to regenerate `.aid/connectors/INDEX.md` from descriptor
   frontmatter — one row per descriptor (feature-001 §"Connectors INDEX.md contract"). The builder
   is **DETERMINISTIC — it stamps no run timestamp** (unlike `build-kb-index.sh`), so a no-change
   reconcile produces a byte-identical index and does not churn (Q7 item 5). It is a **SEPARATE
   script** from `build-kb-index.sh` so the future KB-index→YAML migration (Q6e) does not couple to
   it.
3. Because `.aid/connectors/` lives **outside** `.aid/knowledge/`, these writes and the index
   regeneration run under feature-001's P7 carve-out (the connector sub-phase allowlist) and are
   NOT touched by `build-kb-index.sh` nor scanned by the KB citation-lint gate `kb-citation-lint.sh`
   (**KI-003**; the gate only scans `.aid/knowledge/`). Tool discoverability is via the connectors
   `INDEX.md` referenced by the `## Connectors` context pointer (`@.aid/connectors/INDEX.md`),
   **NOT** the KB auto-index.

**Discoverability reconciliation (grounding note).** REQUIREMENTS §3 / this feature's Description
say registered sources and tools are "discoverable through the KB." The placement decision
(feature-001 / STATE.md Q6) refined this: connectors live **outside** `.aid/knowledge/`, so
**tool** discoverability is realized via the connectors' OWN `INDEX.md`, referenced in
`CLAUDE.md`/`AGENTS.md` the same way the KB index is — not via `build-kb-index.sh`'s
`.aid/knowledge/INDEX.md`. **Source** discoverability remains through the KB proper
(`external-sources.md` in the KB auto-index). This is the placement decision applied, not a scope
change.

**Consumption flow (READ) — the documented contract (FR-6).** An agent that needs the project
toolchain:

1. reads the `## Connectors` section of its context file → follows the `@.aid/connectors/INDEX.md`
   pointer (feature-001 wiring, referenced);
2. scans `.aid/connectors/INDEX.md` (columns `Connector | Type | Endpoint | Auth | Secret Ref |
   Summary` — feature-001) to route to a connector;
3. opens the specific `.aid/connectors/<connector>.md` descriptor — via feature-001's dedicated
   frontmatter accessor twin, **NOT** `read-setting.sh` (which resolves only 2-level dotted paths
   — **KI-001**) — for full fields + human notes;
4. connects, by `connection_type`:
   - `mcp` → the server is **already** wired into the host's MCP config (feature-004); the agent
     invokes it directly through the host harness's native MCP tool-calling. No descriptor
     consumption at connect-time — the descriptor exists for discovery/audit.
   - `api | ssh | url | cli` → the descriptor conveys `endpoint` + `auth_method` +
     `secret_reference`; the credential is **resolved at use-time** from the reference
     (`env:` → read the env var; `file:` → read `.aid/connectors/.secrets/<connector>`;
     `keychain:` → OS keychain — feature-001 §Security). **Use-time secret resolution is owned by
     feature-005's consumption contract / the consuming agent** — there is no feature-003 resolver
     (Q7 item 3). Per FR-6 / Q4 this consumption path is **documented** and the registry is
     **machine-readable** for it, but the agent-side code that performs it is **OUT OF SCOPE**.

**Producer / consumer / reconciler cross-reference (bind to feature-001 §"Feature Flow" + Q7 — do
NOT restate):** the **producers write their own artifacts** — feature-002 authors descriptors,
feature-003 writes/purges secret values, feature-004 writes host MCP config + wiring fields — and
each **triggers feature-005's `INDEX.md` regeneration**. feature-005 owns that regeneration, the
documented consumption contract (incl. use-time secret resolution), and the serialization /
consumption view. feature-006 reconciles (add / update / remove) and, on full REMOVE, **calls
feature-003's purge op** (it defines no purge twin of its own — Q7 item 2); an auth-downgrade
orphan (`auth_method` → `none` on a surviving connector) is disposed by feature-003's secret
lifecycle, not feature-006 (Q7 item 7).

### Layers & Components

**Ownership boundary (Q7 item 6 — the authoritative matrix).** feature-005 is **not** a
descriptor / secret / source writer that producers call. It owns three things: (1) the connectors
`INDEX.md` builder + its regeneration, (2) the documented consumption contract (FR-6), and (3) the
machine-readable serialization / consumption VIEW. The producers write their own artifacts and
trigger feature-005's index regeneration: feature-002 authors `.aid/connectors/<connector>.md`
descriptors (incl. `secret_reference`); feature-003's secret twin writes/purges the secret VALUE
under `.aid/connectors/.secrets/`; feature-004 writes host MCP config + updates wiring fields; and
external **sources** are written by the existing **Scout** back-end (fed by feature-002 ELICIT),
never by feature-005.

**Component 1 — Connectors `INDEX.md` builder + regeneration (feature-005-owned).**
A Bash+PowerShell **twin** (`.sh` + `.ps1`/`.psm1`, per `coding-standards.md` twin rule) that
regenerates `.aid/connectors/INDEX.md` from the descriptor frontmatter under `.aid/connectors/`,
implementing feature-001's FROZEN `INDEX.md` contract (columns `Connector | Type | Endpoint | Auth
| Secret Ref | Summary`; its own `source: generated` / `generator:` / `intent:` / `contracts:`
frontmatter; a single flat table, no KB grouping, no `../knowledge/` cross-links — feature-005 does
NOT restate or alter that contract). It follows the `build-kb-index.sh` pattern (accepts
`--root`/`--output`) but is a **SEPARATE script** so the future KB-index→YAML migration (Q6e) does
not couple to it. It is **DETERMINISTIC — it emits no run timestamp** (contrast the
`<!-- AUTO-GENERATED <TS> -->` line `build-kb-index.sh` writes), so a no-change reconcile yields a
byte-identical index and does not churn (Q7 item 5, CF-INDEX). Triggered on every descriptor
add / update / remove / wire by feature-002 (author), feature-004 (wire), and feature-006
(reconcile). Runs within feature-001's P7 carve-out allowlist (`.aid/connectors/`).

**Component 2 — Documented consumption contract (FR-6).**
The consumption contract is human-readable documentation of the READ flow above, and its **single
home is the `## Connectors` section of the context files** (feature-001's wiring — **referenced**,
not re-derived; **NOT** an `INDEX.md` preamble — feature-001's frozen `INDEX.md` contract defines
no body preamble, and adding one would amend the frozen builder, Q7 item 6 / gate Row 1). That
section carries the protocol: "scan `@.aid/connectors/INDEX.md` → open the descriptor → for `mcp`
use the host's MCP config (feature-004), else resolve the `secret_reference` at use-time (`env:` env
var, `file:` `.aid/connectors/.secrets/<connector>`, `keychain:` OS keychain)", plus the explicit
**OUT-OF-SCOPE** boundary (rewiring `aid-researcher` / `aid-developer` / … to actively consume
non-MCP descriptors is not built — Q4). The machine-readable substrate the contract relies on is
feature-001's registry (`INDEX.md` + descriptors) plus feature-001's dedicated frontmatter accessor
twin (**KI-001** — NOT `read-setting.sh`, which resolves only 2-level dotted paths). Use-time secret
resolution is part of this contract (Q7 item 3); there is no feature-003 resolver.

**Component 3 — Machine-readable serialization / consumption VIEW (feature-005-owned).**
feature-005 defines the read/consumption projection over what the producers write — it specifies
**no** new persisted shape and writes nothing. The view is: for a connector, `INDEX.md` →
`{Type, Endpoint, Auth, Secret Ref}` → the descriptor frontmatter (feature-001 schema) → secret
resolution; for a source, the `external-sources.md` frontmatter (`sources:` / `summary:`) surfaced
as its `.aid/knowledge/INDEX.md` row. Field-level detail is in Data Model.

**Component 4 — context-file + `settings.yml` wiring (BIND to feature-001; do NOT re-derive).**
feature-001 §"Context-file + `settings.yml` wiring" **FROZE** this mechanism; feature-005 depends
on it (it is the home of the Component 2 consumption contract) and adds nothing new. Binding points
feature-005 relies on:

- The `## Connectors` section in the AID-managed region (`<!-- AID:BEGIN -->` / `<!-- AID:END -->`)
  of all five root context files (`profiles/claude-code/CLAUDE.md` + the four `AGENTS.md`),
  referencing `@.aid/connectors/INDEX.md`.
- Those five files are **hand-maintained** (not canonical→profiles rendered — Q6(f) correction);
  the repo-root `CLAUDE.md` receives the change via the installer's in-place managed-region updater
  (`lib/aid-install-core.sh` / `lib/AidInstallCore.psm1`).
- Byte-identity guards: **FR12** — the four `AGENTS.md` files stay byte-identical
  (`tests/canonical/test-agents-md-invariant.sh`); the heading-stem allowlist lives in BOTH
  installer twins (`is_aid_heading` awk function + the parity PowerShell `switch`).

feature-005 introduces **no** new context-file section or managed-region heading beyond
feature-001's `## Connectors` (and the `settings.yml` pointer feature-001 folds into an allowlisted
section). Any consumption-doc text goes **inside** the existing `## Connectors` region — no new stem
— which avoids the C2 (no-marker) duplication hazard feature-001 documents.

**Component 5 — scope guards.**
feature-005 is **not** a writer of descriptors, secrets, or `external-sources.md` (Q7 items 1–4),
and it ships **no** bespoke per-tool client code (REQUIREMENTS §4 Out-of-Scope; feature-001) — no
Jira / Slack / GitHub / etc. client. Agents connect via MCP (feature-004) or the recorded
descriptor. feature-005 ships the `INDEX.md` builder, the consumption documentation, and the
serialization / consumption view only.

### Data Model

**Tool registry serialization view (from feature-001 — referenced, NOT redefined).** The
machine-readable registry is feature-001's descriptor frontmatter schema + `INDEX.md` table.
feature-005 adds or alters **no** field and writes no descriptor; feature-002 authors the
descriptors, feature-005's builder composes each `INDEX.md` row from the frontmatter below, and the
consumption view reads it:

- Descriptor frontmatter: `name`, `connection_type` (`mcp|api|ssh|url|cli`), `endpoint`,
  `auth_method` (`none|token|pat|oauth|ssh-key`), `secret_reference` (present when
  `auth_method != none`), `preset`, plus KB-style routing text (`objective`/`summary`/`tags`/
  `audience`). See feature-001 §"Connector descriptor schema".
- `INDEX.md` columns (machine + at-a-glance consumption view): `Connector | Type | Endpoint |
  Auth | Secret Ref | Summary`. See feature-001 §"Connectors INDEX.md contract".
- Secret-reference forms: `env:<VAR_NAME>`, `keychain:<key>`, and the default
  `file:.aid/connectors/.secrets/<connector>`. See feature-001 §Security Specs.

**Sources serialization / consumption view (feature-005 documents the VIEW; the writer is Scout —
Q7 item 4).** `external-sources.md` is a hand-authored KB doc: its machine-readable view is its
frontmatter, its human view is the `## Sources` body. feature-005 does NOT write it — it documents
how an agent reads it. The columns below are the current on-disk shape and what Scout writes on
populate (`.aid/knowledge/external-sources.md` frontmatter). Note: the current `summary:` value is
the full string `Read this before fetching documentation that may already be cataloged here. No
external documentation was provided during discovery.` — the excerpts below quote only the trailing
clause Scout must refresh:

| Frontmatter field | Current shape | On populate (by Scout) |
|-------------------|---------------|------------------------|
| `sources:` | YAML list, `- (none)` | one entry per external source (a URL, or `label — url` / vendor-spec ref); replaces `(none)` |
| `summary:` | full value above; trailing clause `…No external documentation was provided during discovery.` | trailing clause refreshed to a populated summary (**KI-004**) — else the KB `INDEX.md` row misleads agents |
| `see_also:` | `[integration-map.md]` | unchanged unless a source relates to another KB doc |
| body `## Sources` | "No external documentation was provided during discovery. …" | one human-readable entry per source |

The `external-sources.md` row in `.aid/knowledge/INDEX.md` is the machine-routing consumption view
for sources; it is regenerated mechanically by `build-kb-index.sh` from the frontmatter above
(source-of-truth = the frontmatter, not the row).

**Consumption view (read projection — no new serialization).** For a connector the minimal parse
is `INDEX.md` → `{Type, Endpoint, Auth, Secret Ref}`, then the descriptor frontmatter for full
fields, then secret resolution from `secret_reference`. This is a read projection over
feature-001's schema — it defines no new persisted shape.

### External Integrations

Activated **light**: the consumption contract points at feature-004's per-host MCP configs; this
feature adds no integration surface of its own.

- For `connection_type: mcp`, "consumable" is realized entirely through the **host's MCP
  configuration**, which feature-004 writes per-host across the five profiles (claude-code,
  codex, cursor, copilot-cli, antigravity), each via its own MCP mechanism (`.mcp.json` is the
  Claude Code case; the per-host mechanism map is feature-004's Q1-authorized spike). The agent
  uses the MCP server directly through the host harness — the descriptor is for discovery/audit,
  not connect-time consumption.
- KB grounding: `integration-map.md` §"MCP and Playwright" and §"Host AI-Tool Harnesses (the five
  profiles)" describe the MCP surface and the five install targets. feature-005 introduces **no**
  new runtime integration, no network service, and no new heavy runtime dependency (AC-8) — it
  points at feature-004's outputs.
- **Reference-not-value extends to host MCP config.** Any committed MCP config feature-004 writes
  (e.g. a project-scoped `.mcp.json`) MUST carry env-var references, never secret values — the
  same rule as `.aid/connectors/` (feature-001 §Security cross-reference).
- Non-MCP transports (`api|ssh|url|cli`) have **no** wired integration here: their consumption is
  the documented descriptor + use-time secret resolution, with the agent-side consumption code
  **OUT OF SCOPE** (Q4) — restated for the boundary.
