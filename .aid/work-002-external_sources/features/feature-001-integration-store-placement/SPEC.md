# Integration Store Placement and Schema

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5 (FR-2/FR-3/FR-5 contract side) + §9 (AC-7); see Source for other §refs | /aid-define |
| 2026-07-08 | Technical Specification authored (Data Model, Layers & Components, Security Specs, Feature Flow); encodes placement decision `.aid/connectors/` per STATE.md Q6 + Q1–Q5 (AC-7 satisfied) | /aid-specify |
| 2026-07-08 | FIX pass (A+ gate, 6 findings): corrected dogfood byte-identity claim; reconciled descriptor frontmatter with the connectors-index builder; specified the concrete `INDEX.md` contract; moved `.secrets/` git-ignore to a single-writer connectors-local `.gitignore` (ordering-safe); pinned the secret file key to the descriptor stem; scoped the KB-format reuse claim | /aid-specify |
| 2026-07-08 | Coherence pass (STATE.md Q7 ownership matrix): CF4 repo-relative secret store (no user-profile path); CF-INDEX deterministic builder (no timestamp) + regen owned by feature-005 / triggered by 002/004/006; CF5 non-Claude-Code MCP-config repo-tree edge flagged as deferred scope; Feature Flow producer/consumer attribution reconciled to Q7 (002 authors descriptors, 003 owns value write+purge twin, 004 updates wiring + records reference, 006 calls purge) | /aid-specify |

## Source

- REQUIREMENTS.md §1 (Objective), §4 (Scope — placement is an analysis deliverable), §6 (Security & secret hygiene, cross-platform store location), §7 (Constraints — committed-and-shared KB, integrate not fork)
- REQUIREMENTS.md §5 Functional Requirements (contract side): FR-2 (descriptor fields), FR-3 (store location + reference format), FR-5 (the determined home)
- REQUIREMENTS.md §9 Acceptance Criteria: AC-7

## Description

This is the foundation feature: it decides where the tool/integration registry and the local
auth references live, and it defines the shared shapes everything else in the work writes to
and reads from.

External sources and tool integrations differ, and so do their homes. External sources (docs,
vendor specs, reference URLs) already have a landing doc — the existing external-sources.md in
the Knowledge Base — so this feature does not decide their home; it only ensures the schema and
placement work accommodates them. The tool/integration registry is the net-new store: whether
its connection descriptors and local auth references belong inside the Knowledge Base or in a
separate folder is undecided, and analyzing and deciding that is a deliverable of this work, not
a pre-settled assumption. This feature produces that decision as an explicit analysis artifact
(AC-7), with the rationale recorded so downstream work can trust it.

On top of the placement decision, this feature authors three contracts the rest of the work
binds to:

- The machine-readable registry / connection-descriptor schema — the fields captured per tool
  (name, connection type from the fixed set mcp | api | ssh | url | cli, endpoint or target,
  and auth method plus a reference to where the secret lives).
- The secret-reference conventions — the allowed forms of a committed reference (an env-var
  name, an OS-keychain key, or a path to a git-ignored local file), and the hard rule that a
  secret value is never written to the repo or the KB.
- The cross-platform local-store strategy — a git-ignored, OS-appropriate location for the
  actual secret values that works on Windows, macOS, and Linux, chosen to fit the existing AID
  toolchain without a new heavy runtime dependency.

Hard rule (schema/placement constraint): under no circumstance does a committed artifact — the
registry, a descriptor, or any KB doc — hold a secret value. Committed artifacts carry only
secret references; the KB never holds a secret. Because the KB is committed and shared, the
placement and schema decisions here must keep the committed registry safe to commit
(reference-not-value is mandatory), and must integrate with the existing aid-discover state
machine and KB authoring conventions rather than introduce a parallel mechanism.

## User Stories

- As an AID maintainer, I want an explicit, grounded decision on where the integration registry
  and local auth live (KB versus a separate folder) so that every downstream feature writes to
  one agreed home instead of inventing its own.
- As an AID maintainer, I want a machine-readable descriptor schema plus secret-reference
  conventions defined up front so that elicitation, auth registration, wiring, and persistence
  all produce a consistent, committable registry.
- As a developer/adopter, I want the local secret store to be defined for Windows, macOS, and
  Linux so that credential handling behaves the same wherever I run discovery.

## Priority

Must

## Acceptance Criteria

- [ ] Given the work must decide where the integration registry and local auth live, when the placement analysis completes, then an explicit decision artifact records the chosen home (KB versus a separate folder) together with the rationale. (AC-7)
- [ ] Given the placement decision, when the registry / connection-descriptor schema is authored, then it defines a machine-readable shape capturing tool name, connection type (mcp | api | ssh | url | cli), endpoint or target, and auth method plus a secret reference. (contract side of FR-2 and FR-5)
- [ ] Given the security rules, when the secret-reference conventions are defined, then every committed artifact (registry, descriptor, or KB doc) carries only a secret reference — an env-var name, an OS-keychain key, or a path to a git-ignored local file — and never a secret value; the KB never holds a secret. (FR-3 contract side, §6)
- [ ] Given cross-platform support is required, when the local secret-store strategy is defined, then it specifies a git-ignored / OS-appropriate location that works on Windows, macOS, and Linux without a new heavy runtime dependency. (§6, AC-7 scope)

---

## Technical Specification

> Authored by `/aid-specify`. This feature defines the **contract and placement only** — the
> registry/descriptor schema, the physical home, the secret-reference conventions, and the
> cross-platform store strategy. features 002–006 realize this contract; they do not redefine it.
>
> **Placement decision (AC-7).** `.aid/connectors/` is the single home for everything
> connector/integration-related, decided in `.aid/work-002-external_sources/STATE.md`
> `## Cross-phase Q&A` **Q6** (with rationale) and encoded below. This Technical Specification
> is the explicit analysis artifact AC-7 requires. External **sources** (docs / vendor specs /
> reference URLs) are NOT part of this home — they continue to land in
> `.aid/knowledge/external-sources.md` per **Q2**; `.aid/connectors/` holds tool integrations only.

### Data Model

The tool/integration **registry** is a directory of committed, human-and-machine-readable
markdown files under `.aid/connectors/`, structured to mirror the Knowledge Base
(`.aid/knowledge/`): a generated routing index plus one descriptor file per connector. No
standalone YAML files are introduced — machine-readable fields live in YAML **frontmatter**,
reusing the frontmatter *format* the KB uses (`.aid/knowledge/*.md`) but NOT its required field
set: connector descriptors do NOT carry the KB's `kb-category:` / `source:` / `sources:` fields,
and because they live OUTSIDE `.aid/knowledge/` the KB citation-lint gate does not scan them
(KI-003). Converting index files to a pure-YAML format is explicit FUTURE WORK and out of scope
here (STATE.md Q6e).

**Artifacts under `.aid/connectors/`:**

| Artifact | Committed? | Shape | Mirrors |
|----------|-----------|-------|---------|
| `INDEX.md` | yes (references only) | Generated routing table — one row per connector descriptor, composed from each descriptor's frontmatter | `.aid/knowledge/INDEX.md` |
| `<connector>.md` | yes (references only) | One descriptor per connector: KB-style frontmatter (the machine-readable fields) + a human-readable body | a `.aid/knowledge/*.md` doc |
| `.secrets/` | **no — git-ignored** | File store: one secret **value** file per connector, named by the descriptor filename stem (the connector key) | (net-new; no KB analogue) |

**Connector descriptor schema** (`.aid/connectors/<connector>.md` frontmatter — the FR-2 fields).
`<connector>` (the filename stem) is the connector's unique key; reconcile (feature-006) keys
add/update/remove on it.

| Field | Type / enum | Required | Notes |
|-------|-------------|----------|-------|
| `name` | string | yes | Human name; filename stem is the machine key |
| `connection_type` | closed enum: `mcp` \| `api` \| `ssh` \| `url` \| `cli` | yes | The transport an agent uses (REQUIREMENTS §4). `db` folds into `cli`/`api` and is NOT a value |
| `endpoint` | string | yes | Endpoint/target: a URL, host, socket path, local binary name, or MCP server launch spec — shape depends on `connection_type` |
| `auth_method` | closed enum: `none` \| `token` \| `pat` \| `oauth` \| `ssh-key` | yes | Auth axis — **orthogonal** to `connection_type` (REQUIREMENTS §4) |
| `secret_reference` | string (one of the three reference forms below) | yes when `auth_method != none`; else omitted | A *reference*, never a value (§6) |
| `preset` | string preset-id, or `custom` | yes | FR-2 preset-vs-generic marker; a preset pre-fills defaults, `custom` is the generic descriptor |
| `objective` / `summary` / `tags` / `audience` | KB-style routing text | yes | Human-routing fields; composed into `INDEX.md` by the connectors-index builder (a SEPARATE script — NOT `build-kb-index.sh`) |

**The three `secret_reference` forms** (REQUIREMENTS §6; STATE.md Q6b). The reference conveys
*where* the credential lives, never the credential:

- `env:<VAR_NAME>` — an environment-variable name resolved at use-time.
- `keychain:<key>` — an OS-keychain key (alternative form; see Security Specs for the
  cross-platform caveat).
- `file:.aid/connectors/.secrets/<connector>` — a path to the git-ignored local file for this
  connector, where `<connector>` is the descriptor filename stem (the connector key), so the
  reference, the descriptor, and the stored value all share one key. **This is the default** (the
  only form implementable in pure Bash+PowerShell with zero heavy dependency on
  Windows/macOS/Linux — see Security Specs).

**Worked descriptor example** (`.aid/connectors/github.md`) — illustrative shape, not shipped
content:

```markdown
---
name: GitHub
connection_type: mcp
endpoint: "npx -y @modelcontextprotocol/server-github"
auth_method: pat
secret_reference: "env:GITHUB_PERSONAL_ACCESS_TOKEN"
preset: github
objective: GitHub issues/PRs/repos via the GitHub MCP server.
summary: Read before connecting to GitHub; wired into installed hosts' MCP config.
tags: [connector, mcp, source-host]
audience: [developer, architect]
---

# GitHub

> Connection: mcp · Auth: pat (reference: env:GITHUB_PERSONAL_ACCESS_TOKEN)

Human-readable notes: what this connector is for, how an agent reaches it.
```

The **registry** = `INDEX.md` (the machine-readable table agents scan first) + the descriptor
files it indexes. Prior art for "index-of-frontmatter": `.aid/knowledge/INDEX.md` frontmatter
`contracts:` ("One entry per non-dot, non-recursive KB document under .aid/knowledge/"). The
connectors `INDEX.md` reuses that one-row-per-file idea but is its own artifact with its own
builder — it is a connectors table, not a KB doc.

**Connectors `INDEX.md` contract** (binds feature-005 — do not re-decide):

- **Columns** — one row per descriptor, each column sourced from that descriptor's frontmatter:
  `Connector` (`name`, linked to its `<connector>.md`), `Type` (`connection_type`), `Endpoint`
  (`endpoint`), `Auth` (`auth_method`), `Secret Ref` (`secret_reference`, or `—` when
  `auth_method: none`), `Summary` (`summary`). Unlike the KB index, the per-connector structural
  fields **`connection_type`, `endpoint`, and `auth_method` DO appear as columns** (an agent must
  see the transport and auth at a glance).
- **Own frontmatter** — `source: generated`, `generator: <connectors-index-builder>`, `intent:`,
  and `contracts: ["One row per connector descriptor under .aid/connectors/"]`. It is
  references-only (never a secret value), like every committed artifact here.
- **Not a KB doc** — it has **no `primary` / `meta` / `extension` grouping** (a single flat
  connectors table), no `kb-category:`, and **no `../knowledge/` cross-links** (descriptor links
  are relative within `.aid/connectors/`). It is outside the KB citation-lint scan path.
- **Deterministic builder** — the connectors-index builder embeds **NO run timestamp** (unlike
  `build-kb-index.sh`, which stamps `date -u` into `.aid/knowledge/INDEX.md`), so regeneration on
  unchanged input is **byte-identical** and reconcile (feature-006) does not churn the file.
- **Regeneration ownership** — the builder is OWNED by feature-005; it is TRIGGERED by feature-002
  (on author), feature-004 (on wire), and feature-006 (on reconcile) — per STATE.md Q7 item 5.
  Rebuilt from descriptor frontmatter after any add/update/remove; idempotent, mirroring how
  `.aid/knowledge/INDEX.md` regenerates each discovery cycle.

### Layers & Components

**Folder layout (net-new):**

```
.aid/connectors/
  .gitignore          committed  · single entry `.secrets/` (written by the discover state before any secret)
  INDEX.md            committed  · connectors routing table (markdown + frontmatter; mirrors .aid/knowledge/INDEX.md)
  <connector>.md      committed  · one descriptor per connector (references only — never a secret value)
  .secrets/           GIT-IGNORED · file store: one secret value file per connector
    <connector>       GIT-IGNORED · the secret value for <connector> (descriptor filename stem = key; restrictive perms where the OS supports)
```

**Secret-store git-ignore (single writer, ordering-safe).** `.secrets/` is git-ignored by a
committed, connectors-local **`.aid/connectors/.gitignore`** whose sole entry is `.secrets/`
(git honours nested `.gitignore` files). The **single writer is the P7-exempt discover state**
(feature-002) — NOT the installer's root AID-managed block. Relying on the installer would leave
a leak window on an already-installed repo that has not yet re-run `aid update`. Ordering
guarantee: on first touching `.aid/connectors/`, the discover state writes
`.aid/connectors/.gitignore` (containing `.secrets/`) as its FIRST action — before it creates the
`.secrets/` directory and before any secret value is ever written. This closes the leak window
independent of installer state and eliminates the double-writer hazard: the root `.gitignore` is
NOT touched for this path (see updated **KI-002**). The committed registry (`.gitignore`,
`INDEX.md`, descriptors) is deliberately tracked; only `.secrets/` is ignored.

**P7 read-only carve-out (design).** `aid-discover` and its family are hard-guarded to write
only within `.aid/knowledge/`, `.aid/generated/`, `.aid/.temp/`
(`canonical/aid/templates/kb-authoring/principles.md` **P7. "Review is read-only on the repo"** —
"Modifying repo code, configs, skills, templates, or installers from within a `/aid-discover`
cycle is a category violation and a hard guard in the skill's pre-flight"). P7 already carries
one scoped exception (the one-time KB-format migration, directly under the P7 body). This work
adds a **second, narrowly-scoped exception**: the connector sub-phase (the new P7-exempt
`aid-discover` state introduced by feature-002, per Q6) may write ONLY within a declared
allowlist:

1. `.aid/connectors/` (registry `INDEX.md` + descriptors + `.secrets/` + the connectors-local `.aid/connectors/.gitignore`),
2. the per-host MCP-config paths (feature-004, installed hosts only).

The root `.gitignore` is **not** in the allowlist — the secret store is ignored by the
connectors-local `.aid/connectors/.gitignore` instead (see the git-ignore note above), so no
out-of-tree config write is needed for it.

**MCP-config repo-tree edge (CF5, known scope edge — not a silent extension).** Allowlist item 2's
per-host MCP paths are only partly inside the repo tree. `claude-code` — the only host in
`settings.yml tools.installed` today — uses a repo-root `.mcp.json`, which is in-repo and within
reach of an in-tree write. The other four hosts' MCP configs live in **user-home, OUTSIDE the repo
tree** (e.g. Codex `~/.codex/config.toml`), beyond the `.aid/connectors/` repo-tree carve-out — a
separate write-scope question this feature does not resolve. Wiring those hosts is **DEFERRED**
(feature-004 wires only `tools.installed` hosts, per Q6). Flagged here as a bounded scope edge so
the P7 exemption is not read as covering arbitrary user-home writes.

The KB-generation states (`GENERATE` / `REVIEW` / `FIX`) stay fully P7-bound. This SPEC *defines*
the carve-out; the edit to `principles.md` (a canonical template that renders to all 5 profiles)
and the pre-flight-guard relaxation are executed by a downstream CONFIGURE/DOCUMENT task, not
here.

**Context-file + `settings.yml` wiring (all 5 profiles).** Agents discover the KB today via the
`## Knowledge Base` section of the root context file (`profiles/claude-code/CLAUDE.md` §"Knowledge
Base": `@.aid/knowledge.` + bullets). Mirror it for connectors:

- Add a new `## Connectors` section to the **AID-managed region** (between `<!-- AID:BEGIN -->`
  and `<!-- AID:END -->`) of all five root context files:
  `profiles/claude-code/CLAUDE.md` and
  `profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md`. It references
  `@.aid/connectors/INDEX.md` in the same style as `@.aid/knowledge.`, and instructs agents to
  consult it before connecting to an external tool.
- Add a reference to `.aid/settings.yml` in those context files (STATE.md Q6c) so agents know
  the pipeline-config source.
- **Propagation mechanism (correction to Q6f).** These five root context files are the ONE
  asset NOT produced by the canonical→profiles render: they are **hand-maintained** (confirmed by
  `tests/canonical/test-agents-md-invariant.sh` header — "hand-maintained root AGENTS.md files";
  they are absent from `profiles/*/emission-manifest.jsonl` and `run_generator.py` has no
  root-file branch). So the `## Connectors` + settings.yml change is applied by editing the five
  files directly, NOT by editing a canonical source — Q6f's "canonical→profiles render" framing
  does not hold for the context files specifically (it holds for `principles.md` and every other
  canonical asset).
- **Byte-identity guards the change must satisfy:**
  - **FR12** — the four `AGENTS.md` files (`codex`, `cursor`, `copilot-cli`, `antigravity`) MUST
    remain byte-identical (single sha256), enforced by `tests/canonical/test-agents-md-invariant.sh`
    (rationale: two such tools installed in one repo both write `AGENTS.md` to the project root; a
    difference triggers a false protect-on-diff). The `## Connectors` addition must therefore be
    applied **identically** to all four `AGENTS.md`, plus to `CLAUDE.md`.
  - **Dogfood (NOT a byte-identity guard for this file).** `tests/canonical/test-dogfood-byte-identity.sh`
    compares only the `.claude/` tree — the repo-root `CLAUDE.md` and `profiles/claude-code/CLAUDE.md`
    are deliberately NOT byte-identical (the repo-root carries the dogfood Project name; the profile
    carries the `(pending discovery)` placeholder — `profiles/claude-code/CLAUDE.md` §"Project"), and
    **no dogfood test guards this file**. The repo-root `CLAUDE.md` receives the
    `## Connectors`/settings-pointer edit the same way any adopter's file does: via the installer's
    in-place **managed-region updater** replacing only the marked region (`<!-- AID:BEGIN -->` /
    `<!-- AID:END -->` markers at `CLAUDE.md` lines 7 / 53), NOT a full-file resync.
- **Load-bearing gotcha:** the installer's in-place region updater enforces a heading-stem
  allowlist for the managed region, in BOTH twins — `lib/aid-install-core.sh` (`is_aid_heading`
  awk function; current stems: Tracking discipline, Knowledge Base, Workflow, Review output
  format, Permissions) and `lib/AidInstallCore.psm1` (parity `switch`, same stems). Adding a
  `## Connectors` heading (and any new `## Settings`/`## Configuration` heading for the
  settings.yml reference, if a separate section is used) REQUIRES adding the stem to BOTH twins.
  Omitting a stem duplicates that section on the C2 (no-marker) migration path — documented
  precedent: work-007, "Workflow was omitted" (`aid-install-core.sh` / `AidInstallCore.psm1`
  comments). Prefer folding the settings.yml pointer into an existing allowlisted section (e.g.
  `## Knowledge Base` or `## Workflow`) to avoid a new stem where practical.

**Registry accessor (dedicated Bash+PowerShell twin).** Reading connector descriptors needs a
frontmatter parser; `read-setting.sh` MUST NOT be assumed — it resolves only 2-level
`section.key` dotted paths (**KI-001**). Provide a twin accessor (`.sh` + `.ps1`/`.psm1`, per the
`coding-standards.md` twin rule) that lists connectors and reads a field from a descriptor. The
connectors `INDEX.md` builder follows the `build-kb-index.sh` pattern (it already accepts
`--root`/`--output`) but is a **separate script** so the future KB-index→YAML migration (Q6e)
does not couple to the connectors index.

### Security Specs

- **Reference-not-value (mandatory).** Every committed artifact — a connector descriptor,
  `INDEX.md`, or any KB doc — carries only a `secret_reference` (`env:` / `keychain:` / `file:`),
  never a secret value. (FR-3, REQUIREMENTS §6; realized by feature-003.)
- **Absolute committed-no-secrets rule.** Under no circumstance does any committed artifact
  expose any secret — ours or one encountered during elicitation/scanning (STATE.md Q5c). Scope:
  this governs secrets THIS mechanism registers; pre-existing secrets already committed in
  project source are OUT OF SCOPE for cleanup (Q5b) and are flagged as tech-debt/risk by
  discovery.
- **Local secret store.** `.aid/connectors/.secrets/`, git-ignored via the committed
  connectors-local `.aid/connectors/.gitignore` (written before any secret — see Layers &
  Components); a **file store** is the default (one value file per connector, keyed by the
  descriptor filename stem). The store is **repo-relative** (`.aid/connectors/.secrets/`, per the
  layout diagram) — never a user-home / user-profile path. On POSIX, set owner-only permissions
  where supported; on Windows (WinPS 5.1, ASCII-only per `coding-standards.md`) the guarantee is
  the git-ignore plus a best-effort restrictive ACL on the directory (NOT a user-profile
  relocation). Secrets are never echoed and never persisted into transcripts, `STATE.md`, or the
  KB (REQUIREMENTS §6; feature-003).
- **Cross-platform, no new heavy dependency (AC-8).** The `file:` store works in pure
  Bash+PowerShell on Windows/macOS/Linux with zero added runtime dependency. `keychain:` is
  offered as an alternative reference form but is NOT the default: OS keychains diverge (macOS
  `security`, Windows Credential Manager, Linux `libsecret`/`secret-tool`), and the Linux path
  would require an added package — a breach of "no new heavy runtime dependency" (§6).
- **Committed-safe by construction.** Because the KB and `.aid/connectors/` registry are
  committed and shared (REQUIREMENTS §7), the reference-not-value split is exactly what makes
  `.aid/connectors/` safe to commit.
- **Leak proof (AC-3).** After a secret is registered, grepping repo + KB + STATE + transcript
  for the value finds nothing; the value exists only under `.aid/connectors/.secrets/`.
- **Cross-reference:** feature-004 may write committed project-scoped MCP config (e.g., a host's
  `.mcp.json`); those files MUST also carry env-var references, never values — the same rule
  extends beyond `.aid/connectors/`.

### Feature Flow

This feature defines the contract lifecycle; the other five features are its producers,
consumers, and reconciler. Writes occur inside the new P7-exempt `aid-discover` state (Q6 /
feature-002); this feature only establishes that `.aid/connectors/` is the write target and that
the P7 carve-out covers it.

**Producers (WRITE):**

- **feature-002 (elicitation)** creates/updates a `.aid/connectors/<connector>.md` descriptor per
  declared tool (`name`, `connection_type`, `endpoint`, `auth_method`, `preset|custom`) and sets
  the `secret_reference` field. External *sources* are routed elsewhere — to
  `.aid/knowledge/external-sources.md` (Q2) — not into `.aid/connectors/`.
- **feature-003 (auth)** writes only the actual secret **value** to
  `.aid/connectors/.secrets/<connector>` via its `connector-secret` twin (`write` op; the same twin
  owns `purge`, per Q7 item 2). The descriptor's `secret_reference` field is authored by
  feature-002 (Q7 item 1) and points at the value; the value is never written to any committed
  artifact.
- **feature-004 (wiring)** UPDATES the wiring-related fields of the descriptor feature-002
  authored (it does not author descriptors — Q7 item 1); for `mcp` it writes the host MCP config
  (per-host mechanism, installed hosts only) and records the secret *reference* (e.g. `env:VAR`)
  into that config, never the value (Q7 item 3); for `api|ssh|url|cli` it records the connection
  descriptor's wiring fields. No bespoke per-tool client code.
- After any descriptor change, `.aid/connectors/INDEX.md` is regenerated by feature-005's
  deterministic connectors-index builder — OWNED by feature-005, TRIGGERED by feature-002 (author) /
  feature-004 (wire) / feature-006 (reconcile) per Q7 item 5 — mirroring how `.aid/knowledge/INDEX.md`
  is regenerated every discovery cycle.

**Consumers (READ):**

- **feature-005 (consumption)** documents the contract. An agent discovers connectors via the
  context-file `## Connectors` pointer → reads `.aid/connectors/INDEX.md` → reads the specific
  descriptor → resolves the secret at use-time from its reference. MCP-wired tools are consumed
  directly via each host's MCP config; **rewiring agents to actively consume non-MCP descriptors
  is OUT OF SCOPE** (Q4).

**Reconciler (feature-006):**

- Re-running discovery diffs the elicited set against `.aid/connectors/`, keyed by the descriptor
  filename stem: **add** = new descriptor + `INDEX.md` row; **update** = edit descriptor in place
  (preserve the stored secret); **remove** = purge the secret (call **feature-003's
  `connector-secret purge` op** on `.aid/connectors/.secrets/<connector>`; Q3) + for an `mcp`
  connector, unwire the host config (call **feature-004's `unwire` op**; Q8) + delete the
  descriptor + its `INDEX.md` row — with purge/unwire BEFORE the descriptor-delete for
  interrupt-safety. feature-006 defines neither purge nor wiring; it composes feature-003's and
  feature-004's ops (Q7 item 2, Q8). Surviving descriptors and their secrets
  are preserved; a surviving connector whose `auth_method` drops to `none` has its now-unreferenced
  secret disposed by feature-003's secret lifecycle, not by reconcile (Q7 item 7). The
  one-file-per-connector layout keeps each reconcile op a clean, isolated file change (no rewrite
  of a monolithic registry).
