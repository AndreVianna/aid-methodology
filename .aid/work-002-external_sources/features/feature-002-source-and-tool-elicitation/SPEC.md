# Source and Tool Elicitation in Discovery

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5 (FR-1, FR-2) + §9 (AC-1, AC-2); see Source for other §refs | /aid-define |
| 2026-07-08 | Technical Specification authored (Feature Flow, Layers & Components, State Machines, Data Model). Introduces the P7-exempt `ELICIT` discover state (STATE.md Q6 soft default), the `canonical/aid/templates/connectors/preset-catalog.md` asset, and the source `## External Documentation` → Scout populate process (fills the KI-005 gap). Binds to feature-001's frozen `.aid/connectors/` contract; defines no new schema. Filed KI-008 (Scout skip-if-exists) and KI-009 (P7 guard is prose-only). | /aid-specify |
| 2026-07-08 | FIX pass (A+ gate, grade D → 7 findings). Made the KI-008 maintain-path real: specified a content-aware Step-1 skip (was falsely claiming GENERATE "already honours" `Pending`). Specified URL support end-to-end: Step 0b URL-reachability probe + `Accessible` write-back, and a Scout prompt extension to fetch/inventory `url` sources (dropped the blanket "reuse, do not extend"). Specified `tags`/`audience` derivation + optional preset columns. Added the greenfield Step-0f-HALT branch (source populate deferred; tools unaffected). Enumerated all ~8 SKILL.md sequence sites + the new `ELICIT` banner + the state-generate.md / agent-prompts.md edits. Added the `Resolved: no` mid-pause record shape. Reconciled INDEX-builder ownership to Q7 (feature-002 authors descriptors + triggers feature-005's deterministic builder). Updated KI-008. | /aid-specify |
| 2026-07-08 | Re-gate FIX (1 MED, row 9): decoupled URL cataloguing from reachability. `Accessible` is now an annotation only (`yes`/`unverified`/`unknown`), never a Scout inclusion gate — a declared URL is catalogued in `external-sources.md` regardless of probe outcome. Removed the hard `curl` dependency (not in AID's runtime toolchain); reachability is best-effort via existing-Python `urllib` (stdlib, zero new dep, AC-8), and probe-absent → `Accessible: unknown` yet still catalogued. Scout receives every declared URL and records URL + purpose when a fetch is not possible. Local file/dir `test -r` behavior unchanged. | /aid-specify |
| 2026-07-09 | **Q10 reframe (user-directed, mid-Execute) — TOUCH.** E2 now branches by **management mode** (derived from `connection_type`, feature-001): a **tool-managed** (`mcp`) connector records availability + a "request from the host tool's MCP/plugin" note, sets `auth_method: none`, writes **no** `secret_reference`, and does **NOT** prompt for or store a secret; an **aid-managed** (`api\|ssh\|url\|cli`) connector captures the connect descriptor and, when `auth_method != none`, prompts for the local secret (feature-003 write). **Removed** the `mcp` → feature-004 host-MCP-config wiring trigger/hook entirely (Q10: AID does not wire). Data Model `auth_method` / `secret_reference` / preset-catalog notes de-wired. Q9 SKIPPED / DECLARED-EMPTY marker retained (reconcile REMOVE no longer unwires — Q10 amends Q9). | user / aid-execute loopback |

## Source

- REQUIREMENTS.md §2 (Problem Statement — lost elicitation), §4 (Scope — generic + presets), §5 FR-1 (Elicitation in discovery), §5 FR-2 (Generic + preset declaration), §7 (Constraints — integrate with the existing aid-discover state machine)
- REQUIREMENTS.md §9 Acceptance Criteria: AC-1, AC-2

## Description

This feature restores the external-source prompt that discovery used to perform, and extends it
to cover external tools and integrations. When a developer runs aid-discover, the discovery flow
interactively elicits two differentiated kinds of thing, each with its own shape and its own
home:

- External sources — reference knowledge the project depends on (docs, vendor specs, reference
  URLs). These land in the existing external-sources.md Knowledge Base doc. That doc already
  exists but has no working process behind it (it currently records that none were provided);
  this feature builds the missing process to gather, populate, and maintain it.
- Tool integrations — connectable tools (for example issue trackers, chat, CI, source hosts,
  docs, and containers), each captured with a name, a connection type from the fixed set
  (mcp | api | ssh | url | cli), an endpoint or target, and a reference to where its local auth
  secret lives — never the secret value itself. These populate the net-new integration registry
  whose home is decided by the integration-store-placement feature.

The elicitation is skippable. A project with no external sources or tools can move past the
prompt cleanly, and nothing empty is written when there is nothing to record.

Tool declaration is generic and extensible. A curated set of commonly-used tools ships as
presets that pre-fill sensible defaults, so a developer can pick a known tool and confirm. Any
tool that is not in the preset list can still be declared through the generic descriptor.

This elicitation integrates with the existing aid-discover state machine and its authoring
conventions rather than introducing a parallel mechanism. The tool-side descriptor fields and
registry shape it fills are the schema defined by the integration-store-placement feature; the
source-side entries populate external-sources.md.

## User Stories

- As a developer/adopter running aid-discover, I want to be prompted for my project's external
  sources and tools so that the repo captures the real toolchain my project depends on.
- As a developer/adopter, I want to declare a preset tool with sensible defaults or a custom
  tool through a generic descriptor so that any tool I use can be recorded, not just a fixed
  list.
- As a developer/adopter whose project has no external sources or tools, I want to skip the
  prompt cleanly so that no empty artifacts are created.

## Priority

Must

## Acceptance Criteria

- [ ] Given a developer runs aid-discover, when the elicitation step runs, then they are prompted separately for external sources (docs, vendor specs, reference URLs) and for external tools/integrations, each captured in its own shape. (AC-1, FR-1)
- [ ] Given external sources are provided, when elicitation runs, then the gather/populate/maintain process records them into the existing external-sources.md doc. (AC-1, FR-1)
- [ ] Given a project has no external sources or tools, when the developer skips the elicitation, then discovery continues cleanly and no empty source or registry artifacts are written. (AC-1, FR-1)
- [ ] Given the preset catalog, when a developer declares a preset tool (for example GitHub), then its sensible defaults pre-fill and it is captured for the integration registry with connection type, endpoint or target, and an auth reference. (AC-2, FR-2)
- [ ] Given a tool that is not in the preset list, when a developer declares it via the generic descriptor, then it is captured for the integration registry with a connection type from the set (mcp | api | ssh | url | cli), an endpoint or target, and an auth reference. (AC-2, FR-2)

---

## Technical Specification

> Authored by `/aid-specify`. This feature adds the **interactive elicitation** to `aid-discover`:
> it captures external **sources** (docs / vendor specs / reference URLs) and tool
> **integrations** and routes them to their two distinct homes. It **binds to feature-001's
> frozen contract** — the `.aid/connectors/` layout, the connector-descriptor schema, the
> `INDEX.md` contract, and the three `secret_reference` forms — and **does not redefine any of
> them**. It introduces exactly two net-new mechanisms: (1) a dedicated P7-exempt `aid-discover`
> state, **`ELICIT`**, where the elicitation runs (STATE.md `## Cross-phase Q&A` **Q6** soft
> default: "elicitation as a new P7-exempt aid-discover state" — a dedicated state, **not**
> folded into the read-only `GENERATE`); and (2) a curated preset catalog asset. Secret **value**
> capture (aid-managed only) is feature-003; the connection-mode model + per-mode consumption
> semantics are feature-004 (no wiring — Q10); `INDEX.md` (re)generation and the consumption contract
> are feature-005; the reconcile diff is feature-006. This SPEC establishes only the elicitation
> flow, its state, and where they live.
>
> **Source-side reality (KI-005).** The `external-sources.md` doc exists but the "fed by
> `aid-config`" pipe that would populate it does **not** — `aid-config` never elicited external
> docs, and STATE.md `## External Documentation` is scaffolded empty and never filled. This
> feature therefore **builds** the gather/populate/maintain process from zero; it does not
> restore a live feed. Prose says "build", never "restore a feed".

### Data Model

This feature defines **no new schema.** It fills two shapes that already exist — one frozen by
feature-001 (tools), one already in the KB (sources) — plus one curated config asset (presets).

**Tool integrations → feature-001's connector-descriptor schema (bind, do not redefine).** Every
declared tool becomes one `.aid/connectors/<connector>.md` whose YAML frontmatter is exactly the
schema in feature-001 SPEC `### Data Model`. `ELICIT` populates these fields; it invents none:

| Field | Source of truth | What `ELICIT` sets |
|-------|-----------------|--------------------|
| `name` | feature-001 (required) | Human name from the preset row or the user |
| `connection_type` | feature-001 closed enum `mcp \| api \| ssh \| url \| cli` | Pre-filled by preset; user-chosen from the enum for custom (values outside the enum are rejected). **Derives the management mode** (`mcp` → tool-managed; else → aid-managed — feature-001 / feature-004) |
| `endpoint` | feature-001 (required) | Preset endpoint-template (user completes instance specifics) or user-supplied target. For a tool-managed (`mcp`) connector this is **informational** (the target the host tool's MCP/plugin reaches) |
| `auth_method` | feature-001 closed enum `none \| token \| pat \| oauth \| ssh-key` | For a **tool-managed** (`mcp`) connector: forced to **`none`** (AID registers no auth — the host tool authenticates). For an **aid-managed** connector: pre-filled by preset or user-chosen; orthogonal to `connection_type` |
| `secret_reference` | feature-001 three forms (`env:` / `keychain:` / `file:`) | **aid-managed connectors only** (when `auth_method != none`): set to the *reference* (default `file:.aid/connectors/.secrets/<connector>`); the **value** is written by feature-003, never here. **Omitted entirely for tool-managed (`mcp`) connectors** — the host tool handles their auth and AID stores no credential (Q10) |
| `preset` | feature-001 (`<preset-id>` or `custom`) | The chosen preset id, or `custom` for the generic descriptor |
| `objective` / `summary` | feature-001 KB-style routing text (required) | Composed from the preset row (`notes`) and the user's one-line purpose |
| `tags` / `audience` | feature-001 KB-style routing text (required) | **Auto-derived, never prompted:** `tags` defaults to `[connector, <connection_type>]` plus any preset-declared tags; `audience` defaults to `[developer, architect]` (feature-001's worked `github.md` example). A preset row MAY override either via its optional `tags` / `audience` columns (see the preset-catalog table) |

The filename stem `<connector>` is the connector's unique key (feature-001); `ELICIT` derives it
from `name` (slugified) and reuses it as the `.secrets/<connector>` key. `INDEX.md` is **never
hand-written by `ELICIT`**: after any descriptor add/update, `ELICIT` **triggers regeneration via
feature-005's connectors-index builder** — the contract is defined by feature-001, but
regeneration is owned by feature-005 (STATE.md `## Cross-phase Q&A` **Q7** item 5). That builder is
**deterministic (no run timestamp)** — unlike `build-kb-index.sh` — so a reconcile that changes no
descriptor produces no `INDEX.md` diff.

**External sources → the existing `external-sources.md` + `## External Documentation` shapes
(reuse the table shape; URL support extends two behaviors).** No new *table* schema is introduced,
but supporting reference **URLs** (FR-1 / AC-1, Must) requires extending two existing behaviors —
the `GENERATE` Step 0b accessibility check and the Scout inventory prompt (both specified in
Feature Flow):

- **STATE.md `## External Documentation`** — the existing table in `.aid/knowledge/STATE.md`
  (columns `Path | Type | Accessible | Notes`, per
  `canonical/aid/templates/discovery-state-template.md`; `Type` is a free text value, not a closed
  enum, so a `url` value is **not** a schema change). `ELICIT` is the single writer of `Path` /
  `Type` (`file` \| `directory` \| `url`) / `Notes`. The `Accessible` column is written by
  `GENERATE` Step 0b and is an **annotation only, never an inclusion gate**: for local
  `file`/`directory` rows it stays `yes`/`no` from the existing `test -r` check; for `url` rows it
  records `yes` / `unverified` / `unknown` (see Feature Flow). A declared source — a URL especially
  — is **never dropped** because it failed or could not be probed. This table is the durable machine
  record of the elicited source set and the reconcile anchor (feature-006).
- **`.aid/knowledge/external-sources.md`** — the existing meta KB doc (frontmatter
  `kb-category: meta`, `source`, `objective`, `summary`, `sources:`, `tags`, `intent`,
  `contracts`). It remains authored by its current single writer, the `GENERATE` Scout pre-scan
  (STATE.md Q7 item 4); `ELICIT` never writes it directly (avoids a double-writer, mirroring the
  KI-002 single-writer discipline). The Scout inventory prompt is **extended** to fetch and
  inventory `url`-type sources, not only files/directories (see Feature Flow).

**Preset catalog (new curated CONFIG asset — not a registry artifact).** A curated markdown table
(Q6d defers YAML) whose columns are the descriptor defaults a preset pre-fills:

| Column | Meaning |
|--------|---------|
| `preset-id` | Stable id written into the descriptor's `preset` field (e.g. `github`) |
| `name` | Default human name |
| `connection_type` | Default transport from feature-001's enum |
| `endpoint-template` | Endpoint skeleton; instance specifics completed at elicitation. For a tool-managed (`mcp`) preset this is **informational only** (e.g. "via the host tool's own GitHub MCP") — AID does not launch or wire it (Q10); for an aid-managed preset it is the API/CLI target |
| `auth_method` | Default auth axis value. For a tool-managed (`mcp`) preset this is `none` — AID registers no auth (the host tool authenticates) |
| `secret_reference-form` | Default reference form (`env:` / `keychain:` / `file:`), for **aid-managed** presets only (usually `file:`). **Tool-managed (`mcp`) presets carry no `secret_reference`** — AID stores no credential (Q10) |
| `notes` | One-line human guidance (also seeds the descriptor's `summary`) |
| `tags` (optional) | Tag override; when absent, `ELICIT` derives `[connector, <connection_type>]` |
| `audience` (optional) | Audience override; when absent, `ELICIT` defaults `[developer, architect]` |

It holds only **defaults and templates** — never a secret value and never a per-project instance
value. Seed rows cover the requirement-named tools (REQUIREMENTS §1): `github`, `gitlab`, `jira`,
`slack`, `confluence`, `notion`, `jenkins`, `docker`; the exact `endpoint-template` per row is
authored at implementation. This is a curated catalog a discovery gate reads, directly analogous
to `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` (read by `GENERATE` Step 0d).

### Feature Flow

The elicitation runs in the new **`ELICIT`** state (see State Machines). Its interaction is
modelled on the existing `GENERATE` PAUSE-FOR-USER-DECISION gates
(`canonical/skills/aid-discover/references/state-generate.md` Steps 0cx / 0d / 0f / 5c):
measure-or-read → present → **PAUSE** → the user re-runs `/aid-discover` → capture, write, chain.
The full flow is authored into a new `canonical/skills/aid-discover/references/state-elicit.md`
(rendered to all 5 profiles); this SPEC defines its behaviour.

**Entry trace (printed once, mirroring the `GENERATE` Step 0 banner):**

```
[ELICIT] Capturing the project's external sources and tool integrations.
         Both branches are SKIPPABLE — a project with none moves past cleanly.
  [E1] External SOURCES  (docs / specs / URLs -> external-sources.md)   -> you confirm  (PAUSE)
  [E2] Tool INTEGRATIONS (connectors -> .aid/connectors/)               -> you confirm  (PAUSE)
  [E3] Record + chain into GENERATE                                     (mechanical)
```

#### Step E0: Idempotent re-entry

Before prompting, read the `## Discovery Elicitation` block in `.aid/knowledge/STATE.md` (record
format in State Machines). If a prior run of the current cycle already captured input, show it and
resume where it paused; re-entry is always an overwrite of the block (mirrors Step 0cx/0d/0f
re-entry). If the block is absent, this is a first pass — proceed to E1.

#### Step E1: External SOURCES branch (PAUSE-FOR-USER-DECISION)

Sources are **reference knowledge** (docs, vendor specs, reference URLs), distinct from tools.
Present the source prompt (plain-text pause, matching the existing gates — no AskUserQuestion
preview):

```
External sources
----------------
List the external documentation this project depends on — local doc paths, directories, or
reference URLs (vendor specs, API docs). These are catalogued so agents find them before
fetching. This is separate from tool integrations (asked next).

Reply with one entry per line as:  <path-or-url> | file|directory|url | <one-line purpose>
  — or type `skip` if the project has no external sources.
```

**This is a genuine PAUSE-FOR-USER-DECISION.** Stop after presenting. On the resume run:

- **`skip` (or empty):** record `sources: none` in `## Discovery Elicitation`; **write nothing**
  to `## External Documentation` and **do not** touch `external-sources.md` (it keeps its existing
  baseline — no empty artifact is created). Chain to E2.
- **Entries provided:** append/overwrite the rows in STATE.md `## External Documentation`
  (`Path` / `Type` / `Notes`; the `Accessible` column is written by `GENERATE` Step 0b — see the
  populate step). If the recorded source set **differs** from what a prior cycle inventoried, reset
  `external-sources.md` to `Pending` so the Scout pre-scan re-inventories it with the new paths.
  This reset only re-runs Scout because feature-002 also makes Scout's Step-1 skip **content-aware**
  (a specified change — see the populate step and Layers & Components): the skip is currently
  *existence*-based, so a `Pending` file would otherwise still be skipped. This is the
  build/maintain half of the process; the populate half is Scout (below). Record
  `sources: <N declared>`. Chain to E2.

An entry that is ambiguous or contradictory (e.g. a path that cannot be classified file-vs-dir, a
URL of unclear authority) is **not** guessed — per the skill PRIME DIRECTIVE it is written as a
`## Q&A (Pending)` entry in STATE.md (Category `Source`) and resolved in the existing `Q-AND-A`
state, never silently reconciled.

**How sources land in `external-sources.md` (the populate step).** `ELICIT` feeds; the existing
`GENERATE` back-end populates, with three specified extensions to the current state-generate flow.
On the subsequent `GENERATE` run:

1. **Step 0b — accessibility annotation + write-back (extended).** `state-generate.md` Step 0b
   reads `## External Documentation` and verifies each path with `test -r <path>`, storing only the
   accessible paths for the Scout prompt. `test -r` fails on every `http(s)` URL, and Step 0b never
   writes its result anywhere. feature-002 extends Step 0b so that:
   - **Local `file`/`directory` rows are unchanged** — the existing `test -r` check still yields
     `Accessible: yes|no`.
   - **`url` rows are annotated, not gated.** Reachability for a URL is **best-effort and optional**:
     a probe using AID's **existing Python toolchain** (`urllib.request` with a short timeout —
     zero new dependency, AC-8) records `Accessible: yes` on a clear success, `unverified` when the
     probe ran but was inconclusive (timeout, non-2xx, auth-gated `401/403`, `405` on HEAD,
     bot-protection), and `unknown` when **no probe mechanism is available at all** (e.g. Python
     absent). **No URL is ever dropped** on `unverified`/`unknown` — the annotation is advisory
     only. There is **no hard `curl` dependency** (`curl` is not part of AID's runtime toolchain).
   - Step 0b **writes the result back** into the `Accessible` column (today it tests but never
     writes back), so the reconcile anchor (feature-006) is populated.
   - Step 0b passes **all** `url` rows to the Scout prompt regardless of `Accessible` (Scout does
     the real fetch); the annotation gates nothing.
2. **Step 1 — Scout skip made content-aware (specified change; STATE.md Q7 item 4).**
   `state-generate.md` Step 1 currently skips the Scout pre-scan when `project-structure.md` and
   `external-sources.md` both **exist** ("Skip if both already exist" — a bare existence test).
   feature-002 changes that predicate to be **content-aware**: skip only when both exist **with
   real content**, treating an `external-sources.md` that carries only `Pending` as missing — the
   exact convention Step 0 already applies to the declared doc-set scan. This is what makes E1's
   `Pending` reset re-run Scout on the maintain path (KI-008); without it the reset is inert.
3. **Scout inventory — URL fetch + guaranteed cataloguing (extended prompt).** Scout
   (`canonical/skills/aid-discover/references/agent-prompts.md` `## Scout`) inventories the declared
   sources into `external-sources.md` — the branch that until now always fell into the "No external
   documentation was provided" variant because its input was empty (KI-005). feature-002 extends the
   Scout prompt to also handle `url`-type sources, not only `file` / `directory`, and Scout receives
   **every** declared URL (Step 0b gates nothing). Scout **fetches and inventories** each URL with
   its `WebFetch` / `WebSearch` tools (available on `aid-researcher`); and — critically — **every
   declared URL is catalogued in `external-sources.md` regardless of fetch outcome**: on a
   successful fetch Scout records the URL + a content inventory; when a URL cannot be fetched
   (auth-gated, unreachable, or web-fetch unavailable on the host) Scout still records the URL plus
   its declared purpose and notes it was not fetched. This upholds E1's promise that a declared
   source is catalogued so agents can find it. Scout refreshes the frontmatter `summary:` /
   `sources:`, which self-heals the stale "none provided" routing summary mirrored into
   `.aid/knowledge/INDEX.md` (KI-004).

Scout remains the **single writer** of `external-sources.md` (STATE.md Q7 item 4); `ELICIT` only
supplies the `## External Documentation` input and, on change, the `Pending` re-inventory signal
that the now content-aware Step-1 skip honours (KI-008).

#### Step E2: Tool INTEGRATIONS branch (PAUSE-FOR-USER-DECISION)

Tools are **connectable integrations**, captured into `.aid/connectors/` per feature-001. Present
the tool prompt with the preset catalog offered first:

```
Tool integrations
------------------
Declare a tool the project's agents should be able to reach (issue tracker, chat, CI, source
host, docs, container runtime). Pick a preset for sensible defaults, or declare a custom tool.

Presets (from the catalog):  github  gitlab  jira  slack  confluence  notion  jenkins  docker  ...
Reply per tool with:  <preset-id>            (use a preset, then confirm/adjust its fields)
                 or:  custom                 (declare a generic descriptor)
  — or type `skip` if the project has no tool integrations.
```

**This is a genuine PAUSE-FOR-USER-DECISION.** Stop after presenting. On the resume run, branch
per declared tool:

- **`skip` (or empty):** record `tools: none`; create **nothing** under `.aid/connectors/` (no
  `.gitignore`, no `.secrets/`, no descriptor, no `INDEX.md` — no empty registry artifact). Chain
  to E3.
- **Preset declaration** (`<preset-id>`): read the matching row of
  `canonical/aid/templates/connectors/preset-catalog.md` (LLM-read, as Step 0d reads the
  domain-doc matrix) and **pre-fill** `name`, `connection_type`, `endpoint` (from the template),
  `auth_method`, `secret_reference`-form (aid-managed presets only), and `preset: <preset-id>`.
  Present the pre-filled descriptor; the user confirms or adjusts and supplies instance specifics.
  Apply the management-mode branch (below). Write the descriptor (below).
- **Custom / generic declaration** (`custom`): capture `name`, `connection_type` (validated
  against feature-001's closed enum `mcp | api | ssh | url | cli` — a value outside the set is
  refused, not coerced; `db` is not a value) and `endpoint`/target. Set `preset: custom`. Apply the
  management-mode branch (below). Write the descriptor (below).

**Management-mode branch (STATE.md Q10 — derived from `connection_type`, feature-001/feature-004).**
After `connection_type` is set (preset or custom), branch on the derived mode — this decides whether
a secret is captured at all:

- **tool-managed (`connection_type: mcp`):** the host tool provides its own MCP server/plugin for the
  target. Set `auth_method: none` and write **no** `secret_reference` (AID stores no credential). Do
  **NOT** prompt for a secret and do **NOT** invoke feature-003. Record in the descriptor body that
  the connection is **available via the host tool** and the agent must **request it from the tool**
  (the tool handles auth). There is **no** feature-004 wiring step (removed — Q10).
- **aid-managed (`connection_type: api | ssh | url | cli`):** capture `auth_method` (from
  `none | token | pat | oauth | ssh-key`), and when `auth_method != none` capture the
  `secret_reference` form (default `file:.aid/connectors/.secrets/<connector>`). The secret **value**
  is then prompted and stored by **feature-003** (below); the committed descriptor carries only the
  reference.

**Descriptor write sequence (binds feature-001's ordering guarantee).** The first time `ELICIT`
touches `.aid/connectors/` in a cycle it MUST, as its **first action**, write
`.aid/connectors/.gitignore` containing the single entry `.secrets/` — before creating the
`.secrets/` directory and before any secret is ever written (feature-001 Layers & Components; the
P7-exempt discover state is the single writer of this file). Then, per confirmed tool:

1. Derive `<connector>` = slugified `name` (the unique key; feature-001).
2. Write `.aid/connectors/<connector>.md` with the frontmatter fields above (Data Model) + a
   short human body. The committed descriptor carries only a `secret_reference` (aid-managed only) —
   never a value (feature-001 Security Specs; the absolute committed-no-secrets rule, STATE.md Q5).
3. **Secret capture is aid-managed-only (Q10).** For a **tool-managed (`mcp`)** connector, **no
   secret is captured** — the descriptor has `auth_method: none` and no `secret_reference`, and
   feature-003 is not invoked. For an **aid-managed (`api|ssh|url|cli`)** connector with
   `auth_method != none`, the **actual secret value** is prompted and stored by **feature-003** into
   `.aid/connectors/.secrets/<connector>` (for the `file:` form); `ELICIT` sets the reference and
   hands off. For `env:` / `keychain:` aid-managed forms no value is stored by AID (resolved
   externally at use-time).
4. **No wiring step (Q10).** `mcp` descriptors do **not** trigger any host MCP-config write — AID
   wires nothing. The management mode is simply derived from `connection_type` (tool-managed) and
   consumed at use-time (feature-004 / feature-005); there is no producer action here for `mcp`
   beyond writing the descriptor.
5. After the cycle's descriptor writes, **trigger `.aid/connectors/INDEX.md` regeneration via
   feature-005's connectors-index builder** (contract defined by feature-001; regeneration owned by
   feature-005 — STATE.md Q7 item 5). feature-002 **authors its own descriptors** (Q7 item 1) and
   triggers the builder; there is no central descriptor-writer it calls on another feature's behalf.
   The builder is **deterministic (no run timestamp)**, so an unchanged reconcile yields no
   `INDEX.md` diff.

Any unclear tool attribute (an endpoint an agent could not act on, an auth method the preset does
not cover) becomes a `## Q&A (Pending)` entry (Category `Integration`), never a guess.

#### Step E3: Record and chain

Write the `## Discovery Elicitation` resolution block (State Machines) with `Resolved: yes` and
the per-branch `Skipped:` record, then **CHAIN → `GENERATE`**. The connectors registry that
`ELICIT` produced is committed and rides through the remaining states unchanged; it is **not**
graded by the `REVIEW` panel and **not** scanned by `kb-citation-lint` (it lives outside
`.aid/knowledge/` — KI-003, feature-001).

**Skippability invariant (AC-1 / FR-1).** When both branches are skipped, `ELICIT` writes only the
`## Discovery Elicitation` state record (a tracking record, not a source/registry artifact) and
chains to `GENERATE`. No `external-sources.md` change, no `.aid/connectors/` tree — nothing empty
is created on either side.

**Greenfield interaction (Step 0f HALT).** `ELICIT` (State 0) runs before `GENERATE`, which on a
greenfield repo signposts and HALTs at Step 0f **before** the Step 1 Scout
(`state-generate.md` Step 0f greenfield branch). The two branches degrade differently and both
safely:

- **Tools** complete normally — descriptor writes to `.aid/connectors/` have no Scout dependency,
  so a greenfield project can still declare and register its toolchain.
- **Sources** are recorded to `## External Documentation` (and `Accessible` is still written —
  Step 0b runs *before* the 0f HALT), but the **populate into `external-sources.md` is deferred**
  to the first brownfield cycle, once code exists and Scout runs. No empty `external-sources.md` is
  created on greenfield (the file is simply not written until Scout first runs). The deferral is
  safe precisely because of the content-aware Step-1 skip: when code later lands,
  `external-sources.md` is absent (or `Pending`), so Scout fires and inventories the
  already-recorded sources. This matches greenfield's "the KB fills in as you build" model.

### Layers & Components

**Where the elicitation lives — a dedicated P7-exempt state.** The elicitation is a **new
`aid-discover` state, `ELICIT`**, not steps folded into `GENERATE` (STATE.md Q6 soft default). It
is kept separate deliberately: `GENERATE` / `REVIEW` / `FIX` remain **fully P7-bound** (read-only
on the repo, writing only within `.aid/knowledge/`, `.aid/generated/`, `.aid/.temp/`), and
`ELICIT` is the one state that carries feature-001's **P7 exemption** (writes **only** within
`.aid/connectors/` — under Q10 AID writes no host MCP config, so there is no other write target).
Folding elicitation into `GENERATE` would erase that clean read-only boundary — hence a dedicated
state.

- **Worker:** **inline (orchestrator-driven)**, matching the other interactive states in the
  `aid-discover` Dispatch table (`Q-AND-A`, `APPROVAL`). `ELICIT` is a user dialogue, not a
  heavy sub-agent analysis, so no `aid-architect`/`aid-researcher` fan-out is dispatched.
- **New reference doc:** `canonical/skills/aid-discover/references/state-elicit.md` (renders to
  all 5 profiles), holding the E0–E3 flow above.
- **New canonical asset:** `canonical/aid/templates/connectors/preset-catalog.md` — the curated
  preset table (Data Model). It renders into each profile's install tree like the other
  `canonical/aid/templates/**` assets (e.g. the KB-authoring templates), and is LLM-read at E2.

**P7 carve-out is prose, not a script guard (KI-009).** feature-001 scopes the P7 relaxation as a
downstream edit to `canonical/aid/templates/kb-authoring/principles.md` **P7** (adding a second
exception, alongside the existing one-time-migration exception). That principle **claims** the
rule is "a hard guard in the skill's pre-flight", but `canonical/aid/scripts/kb/discover-preflight.sh`
implements **no** write-scope allowlist (it checks only STATE.md presence and Plan Mode) — P7 is
enforced by agent adherence to the principle, not by code. So the carve-out `ELICIT` needs is the
**principles.md prose edit only**; there is no script guard to patch. This SPEC only *requires* the
carve-out; the `principles.md` edit itself is a downstream CONFIGURE/DOCUMENT task (feature-001),
not this feature.

**Code touch-points the state adds (specified here; authored downstream).** The `GENERATE →
REVIEW → Q-AND-A → FIX → APPROVAL → DONE` sequence is encoded in **~8 places** in
`canonical/skills/aid-discover/SKILL.md` alone; every one must gain the `ELICIT` prepend, plus a
net-new `ELICIT` block. Full set:

- **`canonical/skills/aid-discover/SKILL.md` (all sequence + dispatch locations):**
  1. frontmatter `description` line — `State-machine: GENERATE → …` → `… ELICIT → GENERATE → …`.
  2. the "State machine for this skill" summary banner (the `[ GENERATE ] → [ REVIEW ] → …` block).
  3. the **State Detection** ladder (the `State 1…State 6` list + the "Detection logic" prose) —
     add `State 0` (see State Machines) ahead of the existing states.
  4. the **Dispatch** table — add an `ELICIT` row (`references/state-elicit.md` · inline worker ·
     `→ GENERATE`).
  5–10. the **six per-state "you are here" maps + state-entry lines** (`GENERATE`, `REVIEW`,
     `Q-AND-A`, `FIX`, `APPROVAL`, `DONE`) — prepend `[ ELICIT ]` / `[✓ ELICIT ]` to each map.
  11. a **new `ELICIT` state-entry block** — its `[State: ELICIT] — …` description line and its own
     "you are here" map (`[● ELICIT ] → [ GENERATE ] → [ REVIEW ] → …`).
- **`canonical/skills/aid-discover/references/state-generate.md`** — two edits owned by this
  feature (see Feature Flow — populate step): **Step 0b** gains a best-effort, in-toolchain URL
  `Accessible` **annotation** (no hard `curl` dependency; never a Scout inclusion gate) + the
  `Accessible` write-back; **Step 1** gains the **content-aware skip** (skip only when both
  foundation docs exist with real content, not merely present).
- **`canonical/skills/aid-discover/references/agent-prompts.md` `## Scout`** — extend the prompt to
  fetch and inventory `url`-type sources, not only `file` / `directory`.
- **`.aid/knowledge/pipeline-contracts.md` `## Per-Skill State Machines`** — the `aid-discover` row
  (`GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE`) becomes stale and must be updated to
  `ELICIT → GENERATE → …`. A KB-doc consistency update (within `.aid/knowledge/`, no P7 exemption).

All of the above are specified by this feature and authored by downstream Detail/Execute tasks;
this SPEC does not edit the skill or its references directly.

**How `ELICIT` integrates with `GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE`:**

| Existing state | Interaction with `ELICIT` |
|----------------|---------------------------|
| `GENERATE` | Consumes `ELICIT`'s source output: Step 0b reads `## External Documentation` (extended — best-effort URL `Accessible` annotation + write-back, no inclusion gate); Step 1 Scout fetches/catalogues every declared source into `external-sources.md` (single writer; skip made content-aware). Tool descriptors are independent of GENERATE. `GENERATE` stays P7-bound. |
| `REVIEW` | Grades KB docs only. `external-sources.md` is graded like any KB doc (its quality is reviewed). The `.aid/connectors/` registry is **outside** the KB and is **not** in the review panel, nor in `kb-citation-lint` (KI-003). |
| `Q-AND-A` | Resolves any `## Q&A (Pending)` entries `ELICIT` raised for ambiguous sources/tools (Category `Source` / `Integration`), reusing the existing deferral machinery. |
| `FIX` / `APPROVAL` / `DONE` | Unchanged. They operate on the KB grade/approval; the committed connectors registry rides along without a grade gate. |

**Registry accessor / index builder (bind, do not build here).** Reading descriptors uses
feature-001's dedicated Bash+PowerShell twin frontmatter accessor — **not** `read-setting.sh`
(KI-001, 2-level only). `INDEX.md` **regeneration is owned by feature-005's connectors-index
builder** (contract from feature-001; STATE.md Q7 items 5–6) — a separate, **deterministic** (no
run timestamp) script from `build-kb-index.sh`, so reconcile does not churn. `ELICIT` **authors its
own descriptors** (Q7 item 1) and **triggers** that builder; it neither defines the builder/accessor
nor calls a central descriptor-writer on feature-005's behalf.

### State Machines

**Extension.** `aid-discover` gains one state, prepended:

```
Before:  GENERATE -> REVIEW -> Q-AND-A -> FIX -> APPROVAL -> DONE
After:   ELICIT   -> GENERATE -> REVIEW -> Q-AND-A -> FIX -> APPROVAL -> DONE
```

`ELICIT` is first because the **source** side must precede the `GENERATE` fan-out: sources feed
`external-sources.md`, a foundation doc the deep-dive researchers consume (state-generate.md Step 1
"foundation for all other agents"). This also faithfully restores the original placement — the
elicitation `aid-init` performed **before** bootstrap (REQUIREMENTS §2).

**State Detection (new State 0).** `ELICIT` is selected when the elicitation is unresolved for the
current cycle — added ahead of the existing 6-state detection in
`canonical/skills/aid-discover/SKILL.md`:

```
State 0: `## Discovery Elicitation` absent, or `**Resolved:** no`   -> ELICIT mode
State 1: (existing) Missing or empty KB docs                        -> GENERATE
... (existing States 2–6 unchanged)
```

Once `ELICIT` resolves (`Resolved: yes`), detection falls through to the existing States 1–6, so a
cycle runs `ELICIT` exactly once. `--reset` clears the block (re-run `ELICIT`).

**Entry / exit.**

- **Entry:** after pre-flight passes, when State Detection selects State 0.
- **Exit (advance types), per `canonical/aid/templates/state-machine-chaining.md`:**
  - E1 and E2 are **PAUSE-FOR-USER-DECISION** — present, then stop; the user re-runs
    `/aid-discover` to supply answers (identical to Steps 0cx/0d/0f).
  - E3 (resolution) is **CHAIN → GENERATE** — no exit; continues inline into the next state within
    the same invocation.

**Idempotent re-entry.** The `## Discovery Elicitation` block is the trackable record (mirroring
`## Discovery Domain` / `## Discovery Triage`), machine-parsed values in plain text. **The
`**Resolved:**` field is the machine-parsed key State Detection State 0 reads** — it MUST be
`no` from the moment the block is first written (as `ELICIT` pauses mid-flow) and flips to `yes`
only at E3. Two shapes:

Mid-pause (written when E1/E2 pauses for the user — State 0 stays selected, so the next run
resumes `ELICIT`):

```markdown
## Discovery Elicitation

- **Sources:** 2 declared            <!-- captured so far; may still be growing -->
- **Tools:** pending                 <!-- E2 not yet answered -->
- **Skipped:** none
- **Resolved:** no                   <!-- keeps State Detection on State 0 -> ELICIT -->
- **Elicited:** <date> (run N, paused at E2)
```

Resolved (written at E3 — State Detection then falls through to States 1–6):

```markdown
## Discovery Elicitation

- **Sources:** none | <N> declared
- **Tools:** none | <N> declared
- **Skipped:** none | sources | tools | both
- **Resolved:** yes
- **Elicited:** <date> (run N)
```

Re-entering `ELICIT` mid-cycle (a run that paused at E1/E2, `Resolved: no`) reads this block, shows
what was already captured, and resumes — re-entry overwrites the block, never appends. A
`Resolved: yes` block short-circuits the state on the next run so it is never re-asked within the
cycle.

**Cycle boundary and reconcile hand-off (feature-006).** A completed cycle keeps
`Resolved: yes`; a plain re-run of `/aid-discover` on an already-`DONE` KB therefore does **not**
re-prompt. Re-opening `ELICIT` to add/update/remove sources or tools on a later cycle — and the
diff/purge semantics (remove a descriptor + its `.secrets/<connector>`) — are **feature-006's**
reconcile contract; feature-002 provides only the state, its within-cycle idempotent re-entry, and
the `## External Documentation` / descriptor records feature-006 diffs against.
