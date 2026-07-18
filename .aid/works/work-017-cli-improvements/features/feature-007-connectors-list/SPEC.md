# Connectors List

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-17 | Feature identified from REQUIREMENTS.md §5.1 (FR-P5) | /aid-define |
| 2026-07-17 | Technical Specification authored (autonomous run): connectors read into `RepoInfo.connectors` (twin parser), `connector.set` / `connector.remove` op handlers on feature-001's OP_TABLE, new non-interactive `write-connector.sh` writer, home.html Connectors section. Q2 RESOLVED (option a, refined): native dashboard forms → writer scripts, NOT the agent skills (SEC-4 held); secret VALUE capture deferred out-of-band. KI flagged in return. | /aid-specify |
| 2026-07-17 | Fix cycle (REVIEW E+): aligned `write-connector.sh` exit codes to feature-001's shared alphabet (0/4/5/3·6 — never 1/2) so the generic OP_TABLE dispatcher maps HTTP correctly; reconciled request shape (project-scoped ops omit `target`); refined AC1 wording to the satisfiable effect (writer reproduces the skill, per Q2/SEC-4); flagged the module-map connectors-area bash-only deviation as a KB follow-up; renamed the new parser to `parse_connectors`/`parseConnectors` (parse_* convention). | /aid-specify |
| 2026-07-17 | Fix cycle (REVIEW D+, cycle 3): made `secret_reference` conditionally required in both the `connector.set` arg schema and `write-connector.sh`'s per-type normalize step — a credentialed connector (`ssh` always; `api`/`url`/`cli` when `auth != none`) can no longer persist without a reference (writer defaults the skill's `file:.aid/connectors/.secrets/<stem>` form when omitted), closing the row-7 skill-parity gap for the secret field; strengthened the Data Model row to state the required direction; added the KB `artifact-schemas.md` Connector-descriptor citation ("yes iff aid-managed AND `auth_method != none`", line 438) to the Grounding anchors — HIGH. Replaced a fabricated NFR1 quote in the Q2 rationale with the requirement's actual wording ("show manual CLI steps instead of a button" → "real action controls") — MEDIUM. Corrected the home.html envelope-field citation (was 1084–1087; actual `schema_version` 1069 / `details` 1081 / `generated_by` 1085–1086, all in `onSuccess`) in both the Grounding anchors and UI Specs — MINOR. | /aid-specify |
| 2026-07-17 | Fix cycle (REVIEW D+): per-repo ops now send `target: {}` (present-but-empty), consuming feature-002's `settings.set` envelope precedent instead of dropping `target` entirely (that is home-level feature-003's case) — HIGH; made `endpoint`/`auth` conditionally required per type in the arg-schema + writer (`api`/`url`/`cli` require both, `ssh` requires `endpoint`; missing ⇒ exit 5) so the dashboard cannot persist descriptors the skill would never author — skill-parity gap closed; dropped the phantom `KI-010` citation (not registered in this work's known-issues.md — only KI-001..004; it is a work-002 tag in the script comment) and re-grounded the INDEX determinism claim in `build-connectors-index.sh` source (no timestamp/dated field, header lines 24–27 / 68–70); labeled the inherited work-level AC4 citation (local ACs are AC1–AC2 only). | /aid-specify |

## Source

- REQUIREMENTS.md §5.1 FR-P5 (Connectors list)

## Description

A separate list on the project page (`home.html`) to view, add, and remove connectors
(`.aid/connectors/`). Add/remove use the existing `aid-set-connector` / `aid-unset-connector`
skills and regenerate the connector `INDEX.md`, so the dashboard becomes a UI over working
commands.

Depends on the write-infrastructure foundation (feature-001) for the operation endpoints and
on the existing connector skills.

## User Stories

- As a developer running AID on my own project, I want to view and manage my project's
  connectors from the dashboard, so that I can add or remove a connector without invoking the
  connector skills by hand.

## Priority

Should

## Acceptance Criteria

- [ ] AC1 — Given the connectors list, when I add or remove a connector, then the add/remove runs
  from the dashboard — via the non-interactive `write-connector.sh` writer that reproduces the
  connector skill's effect (Q2/SEC-4: the LLM-free server cannot invoke the agent skill itself) —
  and the change (plus INDEX regeneration) persists to disk.
- [ ] AC2 — Given a connector is added or removed, when the list re-renders, then it reflects
  the new on-disk connector registry with no drift.

## Open Questions

- **Q2 — Add-Connector needs interactive elicitation (found by cross-reference). RESOLVED
  (2026-07-17, /aid-specify): option (a), refined.** The ADD path of `aid-set-connector`
  requires `AskUserQuestion` interactive elicitation, which the LLM-free dashboard server
  cannot invoke (`integration-map.md` SEC-4: "no agent/LLM import"). The REMOVE path
  (`aid-unset-connector`, Read/Bash-only) is unaffected.
  **Decision:** **native dashboard forms for both Add and Remove, dispatched as per-repo ops
  to a new non-interactive `write-connector.sh` writer** — the server never invokes the agent
  skills (SEC-4 held). This mirrors feature-001's own precedent (`write-setting.sh` is the
  non-interactive counterpart to the interactive `/aid-config`); the connector descriptor is
  deterministic flat YAML, so a browser form + shell writer replaces the skill's
  AskUserQuestion + LLM authoring with no LLM in the server. Option (b) rejected as the primary
  mechanism (regresses NFR1's intent to replace the old "show manual CLI steps instead of a button"
  UX patterns with "real action controls", and does
  not satisfy AC1's "runs from the dashboard"); option (c) rejected (SEC-4 is load-bearing for
  the whole write-infrastructure security model — feature-001 SEC-3/SEC-4). **Scope caveat:**
  the secret VALUE is not transported through the dashboard — `connector.set` writes the
  descriptor (incl. its `secret_reference` FORM) + regenerates `INDEX.md`; the credential value
  for an aid-managed connector is captured out-of-band via the existing `connector-secret.sh
  write` path (resolved at use-time). See §Security Specs and the technical spec below.

---

## Technical Specification

> Authored by `/aid-specify` (autonomous run, 2026-07-17). This feature adds the **Connectors
> list** to the project page: a read view of `<repo>/.aid/connectors/`, plus Add and Remove
> controls. It **consumes** the write mechanism from feature-001 (it does not re-invent it):
> it registers two op handlers on feature-001's `OP_TABLE`, honors the `write_enabled` /
> `--allow-writes` gate, uses the child-process writer dispatch (server stays LLM-free per
> SEC-4), keeps the reader twins in byte-parity, and re-renders truthfully from disk.
>
> **Grounding anchors (all verified on disk):** connector scripts
> `canonical/aid/scripts/connectors/connector-registry.sh` (read-only `list`/`read`),
> `connector-secret.sh` (`write`/`purge`), `build-connectors-index.sh` (deterministic INDEX
> builder); agent skills `canonical/skills/aid-set-connector/SKILL.md` (`allowed-tools:` incl.
> `AskUserQuestion`, line 12) and `canonical/skills/aid-unset-connector/SKILL.md`
> (`allowed-tools: Read, Bash`, line 9); elicitation surface
> `canonical/skills/aid-set-connector/references/question-sets.md`; defaults
> `canonical/aid/templates/connectors/preset-catalog.md`; KB `integration-map.md` (SEC-4 line
> 267; Connectors section lines 203–251) and `artifact-schemas.md` (Connector descriptor schema,
> lines 430–448 — `secret_reference` "yes iff aid-managed AND `auth_method != none`; omitted
> otherwise", line 438); dashboard reader `dashboard/reader/models.py`
> (`RepoInfo` lines 220–226), `dashboard/reader/reader.py` (`read_repo` line 318, `RepoInfo`
> build ~line 373/425), serializer twins `dashboard/server/server.py` (`_ser_repo_info` lines
> 595–601, `serialize_model` envelope lines 806–818) + `dashboard/server/reader.mjs`
> (`_buildRepoInfo` lines 4328–4332); UI `dashboard/home.html` (polls `./api/model` line 1042,
> envelope-field reads in `onSuccess` (`schema_version` line 1069, `details` line 1081,
> `generated_by` lines 1085–1086), KB section render lines 1346–1351);
> foundation `features/feature-001-write-infrastructure/SPEC.md` (OP_TABLE, `/r/<id>/api/op`,
> write gate, exit-code→HTTP map, `write_enabled` envelope key, co-vendor-via-`dashboard/MANIFEST`).

### Applicable sections

| Section | Status | Why |
|---------|--------|-----|
| Data Model | Present (no DB) | A new read-model record (`ConnectorRef`) sourced from the on-disk flat-YAML descriptors under `.aid/connectors/`; no relational schema. |
| Feature Flow | Present | The Add/Remove POST → gate → dispatch → `write-connector.sh` → `INDEX.md` regen → re-fetch round-trip (consuming feature-001's flow). |
| Layers & Components | Present | Server (2 OP_TABLE rows), writer (`write-connector.sh` + co-vendored connector scripts), reader/model (new parser twin + `ConnectorRef`), UI (Connectors section). |
| API Contracts | Present | The two op handlers (`connector.set`, `connector.remove`) + the `write-connector.sh` contract. |
| Security Specs | Present | SEC-4 preservation (the Q2 crux); the secret-VALUE-out-of-band decision; stem path-confinement; inherited write gate + injection/traversal defenses. |
| UI Specs | Present | The home.html Connectors section — controls, `write_enabled` gating, re-render. |
| Migration / New Plumbing | Present | New `write-connector.sh`; co-vendoring three connector scripts (one `dashboard/MANIFEST` edit); additive `connectors` model field (no schema_version bump); golden-fixture regen. |
| State Machines | N/A | A connector is a stateless catalog entry — no lifecycle/status enum, no transitions. |
| Telemetry & Tracking | N/A | Single-user trust model; the writer prints an `OK:`/trace line and the server logs failures to stderr (inherited from feature-001). No audit requirement. |
| Events & Messaging, DDD, BDD, CQRS, Cache, External Integrations, Batch/Jobs, Mobile, Search, AI, Recovery, Cloud, Hardware | N/A | None apply to a loopback file-catalog add/remove built on the feature-001 foundation. |

### Data Model

**No database.** The "store" is the on-disk connectors registry `<repo>/.aid/connectors/`:
one `<stem>.md` descriptor per connector (flat-YAML frontmatter), a generated `INDEX.md`
routing table, and a git-ignored `.secrets/` directory. This is exactly the shape
`integration-map.md` (Connectors, lines 212–214) records and the three connector scripts
already read/write.

**On-disk descriptor schema (frozen; feature-001 of work-002).** The frontmatter scalars this
feature's consumers read are the same six `build-connectors-index.sh` composes
(`build-connectors-index.sh` `ef()`/`END`, lines 113–148) and `connector-registry.sh read`
addresses (`read_field`, lines 129–142):

| Field | Enum / form | Notes |
|-------|-------------|-------|
| `name` | free scalar | human name; defaults to `<stem>` |
| `connection_type` | `mcp \| api \| ssh \| url \| cli` | closed enum (preset-catalog.md "Columns"; question-sets.md) |
| `endpoint` | free scalar | informational for `mcp`; concrete target for aid-managed types |
| `auth_method` | `none \| token \| pat \| oauth \| ssh-key` | closed enum; forced `none` for `mcp`, forced `ssh-key` for `ssh` (question-sets.md §mcp/§ssh) |
| `secret_reference` | `env:<VAR> \| file:.aid/connectors/.secrets/<stem> \| keychain:<key>` | **required when `auth_method != none`** (aid-managed credentialed; `ssh` always, since its `auth_method` is forced `ssh-key`); absent for `mcp` / `auth_method: none` |
| `summary` | free scalar | one-line human guidance |

**New read-model record `ConnectorRef`** (`dashboard/reader/models.py`, a new dataclass beside
`KbStateRef`), one per descriptor, read-only (never persisted — NFR2):

```
ConnectorRef:
    stem: str                       # descriptor filename stem == the remove key
    name: str
    connection_type: str            # raw scalar; reader adds no enum (a connector has no lifecycle)
    endpoint: Optional[str] = None
    auth_method: Optional[str] = None
    secret_reference: Optional[str] = None
    summary: Optional[str] = None
```

**Attachment point:** a new field `connectors: list[ConnectorRef]` on `RepoInfo` (Level-1
project state, `models.py` lines 220–226) — connectors are a **project-level** registry (under
`<repo>/.aid/`), so they belong on `RepoInfo`, exactly where `kb_state` (the other project-level
`.aid/` reference) lives. The list is sorted by `stem` (same order as `connector-registry.sh
list` / `build-connectors-index.sh`, which both `sort`). It is surfaced **only** in the DM-1
`RepoModel` served by `GET /r/<id>/api/model` (the project page); the DM-2 home model
(`/api/home`, all-projects grid) is **not** touched by this feature.

**Not in the model:** never the secret VALUE, and never the `.secrets/` path contents — the
reader stats/reads descriptor frontmatter only. `secret_reference` is a reference literal, not a
credential (preset-catalog.md preamble).

### Feature Flow

```
Browser (home.html, project page)                Dashboard server (server.py | server.mjs)
─────────────────────────────────                ──────────────────────────────────────────
VIEW: list renders from model.repo.connectors (read-only; always shown)

ADD (form: name, type, endpoint?, auth?, secret_reference form?)   [rendered only if write_enabled]
  ▼  POST /r/<id>/api/op  { op:"connector.set", target:{},
  │     args:{ name, type, endpoint?, auth?, secret_ref? } }   (empty target — project-scoped, no work_id)
  │                                             ── feature-001 pipeline ──▶
  │                                             SEC-6 host allowlist → write gate → op∈OP_TABLE
  │                                             → resolve <id>→repo path (id_map; SEC-2) → validate
  │                                               args per schema → build argv ARRAY → spawn child:
  │                                               bash write-connector.sh set --root <repo>/.aid/
  │                                               connectors --name … --type … [--endpoint …]
  │                                               [--auth …] [--secret-ref …]     (SEC-3/SEC-4)
  │                                                 · author/overwrite <stem>.md (deterministic)
  │                                                 · ensure .gitignore precondition
  │                                                 · [type→mcp/none] connector-secret.sh purge (orphan)
  │                                                 · build-connectors-index.sh  → INDEX.md
  ◀── 200 {ok:true} / 4xx-5xx {ok:false,…} ──── map exit code → HTTP (feature-001 table)
  ▼ on ok
REMOVE (per row)   [button rendered only if write_enabled]
  ▼  POST /r/<id>/api/op  { op:"connector.remove", target:{}, args:{ stem } }
  │                                             → spawn: bash write-connector.sh remove
  │                                               --root <repo>/.aid/connectors --stem <stem>
  │                                                 · connector-secret.sh purge <stem>
  │                                                 · rm -f <stem>.md
  │                                                 · build-connectors-index.sh  → INDEX.md
  ◀── 200 / 4xx-5xx
  ▼ on ok (either op)
targeted re-fetch: GET /r/<id>/api/model  → reader re-enumerates .aid/connectors/*.md from disk
  ▼
swap model → re-render Connectors list (truthful re-render; drift window = one round-trip)  (AC2)
```

The Add form is the non-interactive substitute for `aid-set-connector`'s `AskUserQuestion`
elicitation (Step 2); `write-connector.sh set` is the non-LLM substitute for the skill's
LLM-authored descriptor (Step 5a) + `build-connectors-index.sh` rebuild (Step 6). Remove maps
1:1 onto `aid-unset-connector`'s Step 2 (`connector-secret.sh purge` + `rm`) + Step 3
(`build-connectors-index.sh`) — that skill is already Read/Bash-only and elicitation-free, so
the port is exact.

### Layers & Components

**1. Server layer** (`server.py` + `server.mjs`, byte-parity twins) — **append two rows to
feature-001's `OP_TABLE`; no other server change.** Both ops are per-repo (`POST /r/<id>/api/op`)
and **project-scoped** (they send `target: {}` and do NOT consume `target.work_id`, exactly like
sibling feature-002's per-repo `settings.set`): `<id>` alone resolves the repo path (verbatim from
`id_map`, SEC-2), and the
writer's `--root` is the server-built absolute `<repo>/.aid/connectors`. The argv is an array
(never a shell string); per-op arg validation runs before the child spawn. See §API Contracts.

**2. Writer layer** — one **new** canonical script, `write-connector.sh`, the non-interactive
counterpart to the `aid-set-connector`/`aid-unset-connector` skills (which the server cannot run
— they require `AskUserQuestion`/LLM tools, SEC-4). Two subcommands:

- `set` — deterministically author/overwrite `<root>/<stem>.md` from the supplied field values,
  then rebuild `INDEX.md`. Because a form supplies every field, no LLM prose composition is
  needed (the descriptor's `objective`/`summary`/body are templated from the fields). Upsert
  semantics (re-`set` of an existing stem overwrites in place), matching the skill's single-stem
  UPDATE (SKILL.md Step 5a "(over)written on every UPDATE").
- `remove` — `connector-secret.sh purge` + `rm -f` the descriptor + rebuild `INDEX.md` (a 1:1
  port of `aid-unset-connector` Steps 2–3; idempotent — an already-absent stem is a clean no-op).

`write-connector.sh` internally invokes the two existing connector scripts it must stay
version-locked to:
- `connector-secret.sh purge <stem>` — orphan-secret disposal on `set` when the result is
  `mcp`/`auth_method: none` (mirrors `aid-set-connector` Step 5b's purge branch), and the sole
  disposal step on `remove`. (`connector-secret.sh` lines 184–187.)
- `build-connectors-index.sh --root <root> --output <root>/INDEX.md` — the deterministic INDEX
  regeneration both ops end with (`build-connectors-index.sh` emits no run timestamp or dated field
  — script header lines 24–27 / 68–70 — so two runs over an identical descriptor set are
  byte-identical ⇒ AC2 idempotence).
It does **not** invoke `connector-registry.sh` (that script is read-only and the dashboard reads
descriptors in-process; see layer 3) and it does **not** write a secret VALUE (see §Security).

**Locating the writers at runtime — co-vendor with the dashboard (feature-001 mechanism).** The
canonical connector scripts live in the per-profile tree (`.claude/aid/scripts/connectors/`, …),
not in the CLI/dashboard vendor, and the descriptor/INDEX format is a shared contract, so the
scripts MUST be version-locked to the running server+reader unit. **Decision (identical to
feature-001's for its writers):** co-vendor `write-connector.sh`, `connector-secret.sh`, and
`build-connectors-index.sh` with the dashboard unit and self-locate them from `$AID_CODE_HOME`;
`write-connector.sh` resolves its two siblings from its own directory. Adding these three scripts
is a **one-file edit of `dashboard/MANIFEST`** (feature-001's single-source-of-truth mechanism,
guarded by `tests/canonical/test-dashboard-manifest.sh`). The dashboard already requires bash
(feature-001), so the `.sh` twins suffice; the `.ps1` twins are not vendored for the server.

**3. Reader / model layer** (`dashboard/reader/parsers.py` + `dashboard/server/reader.mjs`) —
**one new parser, added to BOTH twins in lockstep (reader-twin parity).** Unlike feature-001
(zero parser changes), this feature introduces a small source-of-truth parser
`parse_connectors(connectors_dir)` (Python) / `parseConnectors(connectorsDir)` (Node) — following
the readers' established `parse_*` / `parse…` naming convention (all existing reader functions use
it):

- Enumerate `<aid_dir>/connectors/*.md` with the **exact filter** `connector-registry.sh list`
  uses — `*.md`, excluding `INDEX.md` and dotfiles, sorted by stem (`connector-registry.sh`
  lines 151–154). A missing `connectors/` dir ⇒ empty list (non-error; mirrors the script).
- Per descriptor, extract the six frontmatter scalars using the readers' existing
  first-frontmatter-block single-line-scalar extraction (the same semantics as
  `connector-registry.sh` `read_field` / `build-connectors-index.sh` `ef()`: a body-level `---`
  never re-enters frontmatter). Build one `ConnectorRef` (`stem` = filename).
- Wire into `read_repo` where `RepoInfo` is constructed (`reader.py` ~line 373/425) and the Node
  twin (`reader.mjs` `repoInfo`, ~line 2640): `RepoInfo(..., connectors=parse_connectors(...))`.

Serializer twins gain `connectors` **after** `kb_state` in the RepoInfo dict — `server.py`
`_ser_repo_info` (lines 595–601) and `reader.mjs` `_buildRepoInfo` (lines 4328–4332) — each
`ConnectorRef` serialized in declared field order (`stem, name, connection_type, endpoint,
auth_method, secret_reference, summary`). Both twins + their golden fixtures regenerate together;
the cross-runtime parity suites (`dashboard/server/tests/test_server_node.mjs`,
`test_server_py.py`; `dashboard/reader/tests/`) gate byte-consistency (DM-3, AC4 — inherited
work-level, feature-001; this feature's own local ACs are AC1–AC2).

**4. UI layer** (`dashboard/home.html`) — a new Connectors section (see §UI Specs). It reads the
`write_enabled` signal feature-001 adds to the envelope and gates its Add/Remove controls
accordingly; the read-only list renders regardless.

### API Contracts

**Two rows appended to feature-001's `OP_TABLE`** (per-repo, project-scoped — no `work_id`):

| `op` | Scope | Writer + argv (repo path server-resolved; args validated pre-spawn) | Owning FR | Introduced by |
|------|-------|---------------------------------------------------------------------|-----------|---------------|
| `connector.set` | per-repo (project) | `write-connector.sh set --root <repo>/.aid/connectors --name <n> --type <mcp\|api\|ssh\|url\|cli> [--endpoint <e>] [--auth <none\|token\|pat\|oauth\|ssh-key>] [--secret-ref <ref>]` | FR-P5 (Add) | feature-007 |
| `connector.remove` | per-repo (project) | `write-connector.sh remove --root <repo>/.aid/connectors --stem <stem>` | FR-P5 (Remove) | feature-007 |

**Request** (feature-001 envelope; `POST /r/<id>/api/op`, body ≤ 64 KiB). Both ops are per-repo and
project-scoped, so — per feature-001's rule that `target.work_id` "is omitted for project-scoped
ops" — the `target` object is **present but empty (`target: {}`)**: only the pipeline-scoped
`work_id` (and `delivery_id`/`task_id`) is omitted, **consuming sibling feature-002's per-repo
`settings.set` envelope precedent verbatim** (`{ "op": "settings.set", "target": {}, "args": … }`)
rather than re-inventing the shape. (feature-003's `project.add` is the one precedent that drops
`target` entirely — but only because it is a **home-level** op on `POST /api/op`, not a per-repo
one.) `<id>` alone resolves the repo path (SEC-2). This matches the Feature Flow above:

```json
{ "op": "connector.set", "target": {},
  "args": { "name": "Jira", "type": "api", "endpoint": "https://acme.atlassian.net/rest/api/3",
            "auth": "token", "secret_ref": "file:.aid/connectors/.secrets/jira" } }
```
```json
{ "op": "connector.remove", "target": {}, "args": { "stem": "jira" } }
```

**Per-op arg schema (validated server-side before any spawn — feature-001 §API Contracts):**

- `connector.set`:
  - `name` — required; 1–80 chars; reject newline / `|` / control chars → 422. (The **stem** is
    derived by the writer from `name` via the skills' slug rule so dashboard- and skill-authored
    stems are identical — SKILL.md Step 1: `tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g;
    s/^-+|-+$//g'`.)
  - `type` — required; ∈ `mcp|api|ssh|url|cli` → else 422.
  - `endpoint` — **required when `type ∈ {api, ssh, url, cli}`** (question-sets.md marks it "yes"
    for every aid-managed type — it is the concrete connect target/host/command the agent uses);
    optional and informational only for `mcp`. Missing on an aid-managed type → 422. When present:
    ≤ 200 chars; reject newline / `|` → 422.
  - `auth` — **required when `type ∈ {api, url, cli}`** (∈ `none|token|pat|oauth`; question-sets.md
    marks it "yes"). For `ssh` and `mcp` it MAY be omitted because the writer forces it
    (`ssh`⇒`ssh-key`, `mcp`⇒`none`; normalized, not rejected). Missing on `api`/`url`/`cli` → 422.
    When present: ∈ `none|token|pat|oauth|ssh-key` → else 422.
  - `secret_ref` — **conditionally required for a credentialed connector** (`ssh` always; or
    `api`/`url`/`cli` with `auth != none`): a credentialed descriptor MUST carry a
    `secret_reference` (Data Model above; `artifact-schemas.md` "yes iff aid-managed AND
    `auth_method != none`", line 438; question-sets.md §api-url/§ssh/§cli). The client MAY omit it —
    the writer then supplies the skill's default `file:.aid/connectors/.secrets/<stem>` form
    (never fabricating a value), so the invariant holds without a 422; forbidden for `mcp` /
    `auth == none` (the writer drops it). When supplied it must match
    `^(env:[A-Za-z_][A-Za-z0-9_]*|file:[^\n|]+|keychain:[^\n|]+)$`; ≤ 200 chars → else 422.
    **Reference form only — never a secret value.**
- `connector.remove`:
  - `stem` — required; `^[a-z0-9][a-z0-9-]*$` (a bare filename, matching `connector-secret.sh`'s
    path-confinement alphabet) → else 422. This is the row key the reader already exposed.

**Response** — feature-001's contract verbatim: success `{ "ok": true, "op": "<op>" }` (200), then
the client re-fetches `GET /r/<id>/api/model` and re-renders (NFR3/AC2). Failure
`{ "ok": false, "op": "<op>", "error": "<class>", "detail": "<stderr, ≤1 KiB>" }` with status per
feature-001's exit-code→HTTP map. **`write-connector.sh` emits feature-001's shared exit-code
alphabet verbatim** — invalid value ⇒ `4`, missing required arg ⇒ `5`, runtime/write failure ⇒ `3`
(or `6`/other) — and never emits `1` (`not-found`) or `2` (`busy`), which feature-001 reserves for
server-level conditions. So the generic OP_TABLE dispatcher's **literal** feature-001 table yields
the correct HTTP status with no per-op remapping:

| Condition | `write-connector.sh` exit | HTTP | `error` |
|-----------|---------------------------|------|---------|
| Success | 0 | 200 | — |
| Bad enum / bad value / bad stem (path-confinement) | 4 | 422 | `invalid-value` |
| Missing required arg | 5 | 422 | `invalid-value` |
| Underlying I/O failure, unverifiable write, INDEX rebuild failed | 3 / 6 / other | 500 | `write-failed` |

(The `write_enabled` 403 gate, SEC-6 `bad-host` 403, malformed-body 400, unknown-`op` 400, and
unknown-`<id>` 404 are all enforced by feature-001's shared POST pipeline before dispatch.)

**`write-connector.sh` contract** (new; the non-interactive connector-skill counterpart):

```
write-connector.sh set    --root <dir> --name <N> --type <T> [--endpoint <E>] [--auth <A>] [--secret-ref <R>]
write-connector.sh remove --root <dir> --stem <STEM>
```
- **`set`** — derive `<stem>` from `--name` (slug rule above); **normalize + enforce per type** to
  keep dashboard-authored descriptors byte-consistent with skill-authored ones (question-sets.md
  §mcp/§api-url/§ssh/§cli): `mcp` ⇒ force `auth_method: none`, drop `secret_reference`, `endpoint`
  informational; `ssh` ⇒ force `auth_method: ssh-key`; **`api`/`url`/`cli` ⇒ both `--endpoint` and
  `--auth` are REQUIRED**, and `--endpoint` is likewise required for `ssh` (question-sets.md marks
  these "yes" for every aid-managed type). A missing required field **fail-closes (exit `5`,
  missing-required)** rather than persisting a descriptor the skill would never author — closing the
  skill-parity gap the loose "universally optional" schema would otherwise open. **`secret_reference`
  is enforced the same way, by the skill's own normalize step:** a credentialed connector (`ssh`
  always — `auth_method` is forced `ssh-key`; `api`/`url`/`cli` when `auth != none`) MUST carry a
  `secret_reference` (Data Model; `artifact-schemas.md` "yes iff aid-managed AND `auth_method != none`",
  line 438; question-sets.md §api-url/§ssh/§cli), so when `--secret-ref` is omitted the writer defaults
  it to the skill's `file:.aid/connectors/.secrets/<stem>` form (never fabricating a value) — a
  credentialed descriptor can therefore never persist without a reference, closing for the secret field
  the same skill-parity gap row 7 closed for `endpoint`/`auth`; `mcp` and any `auth_method: none`
  connector carry none (dropped, as above). Ensure the
  `.secrets/` gitignore precondition
  (`mkdir -p <root>; [ -f <root>/.gitignore ] || printf '%s\n' '.secrets/' > <root>/.gitignore`) —
  the same load-bearing write `aid-set-connector` Step 4 performs, so a later out-of-band
  `connector-secret.sh write` never fail-closes (exit 4). Author/overwrite `<root>/<stem>.md`
  (full frontmatter — `name, connection_type, endpoint, auth_method, secret_reference?, preset:
  custom, objective, summary, tags: [connector, <type>], audience: [developer, architect]` — plus
  a `# <Name>` heading + a `> Connection: … · Mode: <tool-managed|aid-managed> · Auth: <auth>`
  line, templated deterministically). When the result is `mcp`/`auth_method: none`, run
  `connector-secret.sh purge <stem>` to dispose of any orphaned secret (mirrors SKILL.md Step 5b).
  Rebuild `INDEX.md`. Atomic descriptor write (temp-file + `mv`). Never writes, prompts for, or
  echoes a secret value.
- **`remove`** — `connector-secret.sh purge <stem>` → `rm -f <root>/<stem>.md` →
  `build-connectors-index.sh`. Idempotent (already-absent stem = clean no-op), purge-before-delete
  (interrupt-safe), exactly as `aid-unset-connector` Step 2.
- **Exit codes (feature-001's shared alphabet verbatim, so the generic OP_TABLE dispatcher maps
  them correctly):** `0` ok; `4` invalid value (bad enum / bad value / path-confinement bad stem);
  `5` missing required arg; `3` (or `6`/other) runtime / I-O failure / unverifiable write / INDEX
  rebuild failed. Codes `1` (`not-found`) and `2` (`busy`/lock contention) are feature-001-reserved
  and never emitted by this writer. It **normalizes** its helpers' native codes into this alphabet
  rather than propagating them raw (e.g. `connector-secret.sh`'s exit `2`/usage and exit
  `3`/path-confinement, and a `build-connectors-index.sh` failure, all surface as `4` or `3` here
  as appropriate). bash-only (as the dashboard already requires).
- **SEC-4/SEC-3:** it is a shell script (never an agent/LLM) and does all filesystem mutation in
  its own process (the server performs none); the argv is an array (no shell string).

### Security Specs

**SEC-4 preservation is the crux of this feature (Q2).** The dashboard server must not import or
invoke an agent/LLM (`integration-map.md` SEC-4, line 267; feature-001 SEC-4). The connector
*skills* cannot be run server-side because they require agent-only tools —
`aid-set-connector`'s `allowed-tools` includes `AskUserQuestion` (SKILL.md line 12) and it
authors the descriptor with LLM `Write`/`Edit`. This feature therefore **replaces the skills'
interactive/LLM parts with a browser form (elicitation) + a deterministic shell writer
(authoring)**, dispatched through feature-001's existing child-process mechanism (SEC-3: the
server holds no in-process fs-write; SEC-4: the child is a shell script). No agent/LLM is added
to the server. Option (c) — relaxing SEC-4 to let the server drive an agent — was rejected: SEC-4
underpins the entire write-infrastructure security posture feature-001 established.

**Secret VALUE is not transported through the dashboard (deliberate scope boundary).** `connector.set`
writes the descriptor and its `secret_reference` *form* only; it never accepts, pipes, or stores a
credential value. Rationale: `connector-secret.sh` is purpose-built for TTY / piped-automation
capture with an elaborate no-leak design (no-echo `read -rs`, builtin `printf` so the value is
never a process arg, immediate `unset`, `umask 077` — lines 209–231); routing a raw secret through
the loopback HTTP layer and the LLM-free server's memory would materially widen the credential's
exposure surface (and cross the tailnet under `--remote --allow-writes`) for no functional gain —
the registry needs the *reference*, not the value, which is resolved at use-time
(`integration-map.md` Connectors, line 230). The connector is fully added (descriptor + `INDEX.md`)
without it; the value is captured out-of-band via the existing `connector-secret.sh write` path,
and the UI shows a "secret not yet stored" hint with the exact command for an aid-managed
credentialed connector (see §UI Specs). **In-dashboard secret capture is a flagged follow-up**
requiring human sign-off, loopback-only and never under `--remote` (see the RETURN's high-stakes
note).

**Path confinement / injection / traversal (inherited + local):**
- The repo `--root` is built server-side as absolute `<repo>/.aid/connectors` from `id_map`
  (SEC-2) — never taken from the request body (traversal-proof).
- `stem` is derived by the writer (slug rule) or validated `^[a-z0-9][a-z0-9-]*$`;
  `connector-secret.sh` independently re-rejects any `/`, `\`, or `..` in the stem before any I/O
  (lines 155–160, exit 3) — defense in depth for the delete-capable `purge`.
- All op args pass a closed per-op schema (enums + length + charset) before the child spawn; the
  argv is an array (no `shell=True`, no concatenated command string) — feature-001's posture,
  unchanged.

**Write gate (AC8, inherited).** Both ops ride feature-001's single POST pipeline: SEC-6
Host-header allowlist, then the `write_enabled` gate (403 `read-only` unless spawned
`--allow-writes`). Loopback ⇒ writable; `--remote` ⇒ read-only unless `--remote --allow-writes`
+ tailnet ACL. This feature adds **no new network surface** (C3) and no new listener.

**C1 / C2 untouched.** Connectors live entirely outside `STATE.md`, so no STATE write occurs —
`writeback-state.sh` (C1) is not involved, and no DERIVED union view (C2) is written. `INDEX.md`
is a generated artifact regenerated only by its owning generator `build-connectors-index.sh`
(never hand-edited by the server), which is the same discipline C2 applies to derived views.

### UI Specs

**Placement.** A new **Connectors** section on the project page (`home.html`), rendered as a
sibling of the existing "Knowledge Base" section (`home.html` `knowledge-tool-section`, rendered
via `_renderKbCard(model.repo.kb_state)`, lines 1346–1351). Grounded in the existing section
pattern: a `<h2 class="main-section-head">Connectors</h2>` heading plus a container div populated
by a new `_renderConnectorsCard(model.repo.connectors, writeEnabled)` in `renderModel`. Both
`model.repo.kb_state` and `model.repo.connectors` are project-level `.aid/` references on
`RepoInfo`, so they sit together naturally.

**View (always shown, read-only).** A table with the connector columns already established by
`INDEX.md` and the reader model: **Connector (name) · Type · Endpoint · Auth · Secret Ref ·
Summary** — matching `build-connectors-index.sh`'s column contract (lines 17–18) so the dashboard
view and the on-disk `INDEX.md` present the same shape. Empty registry ⇒ an empty-state line
("No connectors registered."). No control depends on `write_enabled` for viewing.

**Add / Remove controls (rendered only when `envelope.write_enabled === true`).** feature-001
adds `write_enabled` to the DM-1 envelope; `home.html` reads it in `onSuccess` alongside the
other envelope-level fields it already consumes (`schema_version` line 1069, `details` line 1081,
`generated_by` lines 1085–1086, all in `onSuccess`) and passes it to the render. When false
(read-only `--remote`), the section
renders the view only — no Add form, no Remove buttons (defense-in-depth: the server would 403
them anyway).
- **Add form:** inputs for `name`, a `type` `<select>` (`mcp|api|ssh|url|cli`), `endpoint`, an
  `auth_method` `<select>` (`none|token|pat|oauth|ssh-key`), and a `secret_reference` field. The
  form MAY progressively show/hide fields by type (mirroring question-sets.md: `mcp` hides
  auth/secret; `ssh` forces `ssh-key`) — a client-side convenience, not required for AC1/AC2.
  Submit → `POST /r/<id>/api/op` `connector.set`. On 200, re-fetch `./api/model`. Optional preset
  prefill (from a static copy of `preset-catalog.md`) is a nice-to-have, explicitly deferred
  (YAGNI for AC1/AC2).
- **Secret hint:** for an aid-managed connector (`auth_method != none`) whose `secret_reference`
  uses the `file:` form, the row shows a passive "secret not yet stored — run
  `connector-secret.sh write <stem>`" hint (the value is out-of-band, per §Security). No secret
  input is posted.
- **Remove:** each row gets a Remove button with a confirm() guard → `POST /r/<id>/api/op`
  `connector.remove` with `{stem}` → on 200, re-fetch `./api/model`.

**Re-render (AC2).** On any op success the client performs the immediate targeted re-fetch of
`./api/model` (the page's existing fetch, line 1042); the reader re-enumerates
`.aid/connectors/*.md` from disk, so the re-rendered list reflects the exact on-disk registry
with no drift (feature-001 re-render contract; NFR3).

### Migration / New Plumbing

- **New script `write-connector.sh`** (canonical, under `aid/scripts/connectors/` alongside its
  siblings) — the non-interactive counterpart to the connector skills. **Bash-only (no `.ps1`
  twin) — a deliberate departure from the connectors/ area convention** that `module-map.md`
  (Script Modules by Area, connectors row) records as "Bash+PowerShell twins throughout" (true for
  all three existing scripts, which each ship a `.ps1` twin). Rationale: this writer is invoked
  **only** by the LLM-free dashboard server via feature-001's child-process dispatch, and the
  dashboard already requires bash (feature-001); it is never reached by the Windows-PowerShell CLI
  path the twins exist to serve. Flagged as a KB follow-up (below) so the area-convention note is
  amended rather than silently contradicted.
- **Co-vendoring — one `dashboard/MANIFEST` edit.** Add `write-connector.sh`,
  `connector-secret.sh`, and `build-connectors-index.sh` to `dashboard/MANIFEST` (one path per
  line); `vendor.js`, `vendor.py`, `install.sh`, `install.ps1`, and `release.sh`'s CLI bundle all
  derive from that single source, guarded by `tests/canonical/test-dashboard-manifest.sh`
  (feature-001's H1 mechanism). This version-locks the connector machinery to the running
  server+reader unit.
- **Additive model field `connectors`** on `RepoInfo` / the DM-1 `repo` dict. Back-compat: an
  older UI ignores it; the new UI treats missing ⇒ `[]`. Following feature-001's additive-key
  precedent (and DM-A3/RC-2), **do not bump** `schema_version` (DM-1 stays 3). Golden fixtures for
  the twin parity suites regenerate in lockstep.
- **No data migration** — existing `.aid/connectors/` is read/written in place; the descriptor,
  `INDEX.md`, and `.secrets/` formats are unchanged (the existing scripts own them).
- **KB follow-up (out of scope for this write; flagged):** (a) `integration-map.md`'s Connectors
  section and the dashboard-server "Write surface = none" row (line 267) describe the pre-feature
  read-only server; once features 001+007 ship, the SEC-3-refined wording (server dispatches
  connector writers) and the new dashboard-driven add/remove path want a KB delta (same post-ship
  punch-list feature-001 already flagged). (b) `module-map.md`'s Script Modules by Area connectors
  row — "Bash+PowerShell twins throughout" — needs a delta recording `write-connector.sh` as a
  deliberate bash-only exception (server-dispatched, never on the PowerShell CLI path), so the
  area-convention statement stays truthful once this ships.

### How the Acceptance Criteria are satisfied

- **AC1 — add/remove runs from the dashboard and persists (plus INDEX regeneration).** Remove is a
  1:1 non-interactive port of `aid-unset-connector` (purge + `rm` + `build-connectors-index.sh`);
  Add is `write-connector.sh set` (deterministic descriptor authoring + INDEX rebuild), the
  non-LLM counterpart to `aid-set-connector`'s Step 5a/6. Both run entirely from the dashboard via
  feature-001's child-process dispatch to a **shell script** (SEC-4 held — the server never runs
  the agent skills), and both end by regenerating `INDEX.md` from disk. _SEC-4 note:_ AC1 was
  refined during specification (Q2 resolution) to state this **satisfiable effect** — the connector
  is added/removed from the dashboard and persists — instead of the unsatisfiable literal "the
  connector skill runs": the skills are agent/LLM programs the LLM-free server cannot invoke
  (SEC-4), so the dashboard reproduces their non-interactive effect via the same connector
  machinery (`connector-secret.sh purge`, `build-connectors-index.sh`) plus a new deterministic
  descriptor writer. Secret VALUE capture is
  out-of-band by design (§Security) — the connector (descriptor + reference + INDEX) still fully
  persists.
- **AC2 — re-render reflects the on-disk registry with no drift.** On op success the client
  re-fetches `/r/<id>/api/model`; the reader re-enumerates `.aid/connectors/*.md` from disk into
  `RepoInfo.connectors`, so the list is rendered from a post-write read off disk and cannot drift.
  `build-connectors-index.sh`'s determinism (it emits no run timestamp or dated field — script
  header lines 24–27 / 68–70) means a repeat op over an unchanged registry reproduces a
  byte-identical `INDEX.md`, and the reader reads descriptors (source of truth), not
  the derived index — the view is truthful to disk (NFR3).
