# Connector Registry Reconcile

> Shared reconcile logic for the `.aid/connectors/` registry, used in **two modes** by two
> different classes of caller:
>
> - **Bulk mode** — reconciles the *whole* declared set `D` (this cycle's tool declarations)
>   against the *whole* persisted set `P` (what is on disk): `REMOVE = P \ D`. Called by
>   `canonical/skills/aid-discover/references/state-elicit.md` Step E2, once per ELICIT cycle,
>   after that step resolves `D`. This is `aid-discover`'s pre-existing reconcile logic
>   (feature-006-idempotent-reconcile, work-002-external_sources), relocated here verbatim.
> - **Single-stem mode** — operates on **exactly one** named stem, never diffs against the rest
>   of the registry, and so never classifies any *other* connector REMOVE. Called by the net-new
>   `canonical/skills/aid-set-connector/SKILL.md` (upsert) and
>   `canonical/skills/aid-unset-connector/SKILL.md` (remove) — work-004-connector-consumption's
>   only net-new reconcile behavior.
>
> Both modes share the same descriptor-write mechanics ("Write one descriptor", under Bulk mode
> below) and the same REMOVE mechanics (purge-then-delete) and finish by handing off to the same
> deterministic `build-connectors-index.sh` builder — the registry's on-disk shape is identical
> regardless of which mode produced it.
>
> This is a `canonical/` artifact: it ships and installs byte-identically into every profile's
> `.claude/aid/templates/connectors/` (or equivalent per-tool) install tree, alongside
> [`preset-catalog.md`](preset-catalog.md) — a curated reference read directly from disk, not
> per-project templated at render time.

## Bulk mode (ELICIT)

### Reconcile the registry (Steps R0-R5; feature-006 orchestration)

Runs once per ELICIT cycle, after ELICIT's Step E2 "On resume — branch per reply"
(`state-elicit.md`) has resolved this cycle's declared set `D` (`SKIPPED` never reaches here;
`DECLARED-EMPTY` gives `D = {}`; `ENGAGED` gives `D` = the N declared tools, each keyed by its
stem). This is **pure orchestration** composing three existing ops — task-001's registry
accessor, task-006's secret-purge op, task-005's deterministic INDEX builder — plus feature-002's
own descriptor-authoring contract (`state-elicit.md`'s "Preset vs. custom declaration" /
"Management-mode branch"); it adds no new twin, builder, or wiring code. The reconcile diff itself
(R0-R5 below) is the only net-new logic (feature-006 SPEC "Layers & Components").

**Step R0 — guard (resolved by the caller before reconcile runs).** `SKIPPED` never reaches this
section — ELICIT's own branch (Step E2 "On resume — branch per reply", `state-elicit.md`) sends a
`SKIPPED` cycle straight to Step E3 without invoking reconcile at all, so nothing below ever runs
for a skipped cycle: no `list`, no `read`, no `purge`, no descriptor write, no INDEX rebuild. The
persisted registry is left byte-for-byte intact. Both `DECLARED-EMPTY` (`D = {}`) and `ENGAGED`
(`D` = the N declared tools) fall through to Step R1.

**Step R1 — enumerate the persisted set `P`.**

```bash
P_STEMS=""
while IFS= read -r stem; do
  [ -z "$stem" ] && continue
  P_STEMS="${P_STEMS:+$P_STEMS }$stem"
done < <(bash canonical/aid/scripts/connectors/connector-registry.sh list --root .aid/connectors)
```

(PowerShell twin: `connector-registry.ps1`.) `P` is the sorted set of `.aid/connectors/*.md`
stems, excluding `INDEX.md`; a not-yet-existing `.aid/connectors/` (the first-ever cycle) yields
an empty `P` with no error. This is task-001's dedicated accessor twin — **never**
`read-setting.sh` (KI-001), which only resolves `.aid/settings.yml` `section.key` pairs and
cannot address one-field-per-descriptor frontmatter.

**Step R2 — compute the diff.** Partition `D ∪ P` on the stem into exactly one class each:

| Class | Membership |
|---|---|
| ADD | `stem ∈ D \ P` — declared this cycle, no existing descriptor |
| UPDATE | `stem ∈ D ∩ P`, and any field differs from what is on disk |
| NO-OP | `stem ∈ D ∩ P`, and every field matches what is on disk |
| REMOVE | `stem ∈ P \ D` — persisted, not declared this cycle |

For each stem in `D ∩ P`, decide UPDATE vs NO-OP by comparing this cycle's freshly-resolved field
values against the on-disk descriptor, field by field — `name`, `connection_type`, `endpoint`,
`auth_method`, `secret_reference`, `preset`, and the routing text (`objective`, `summary`, `tags`,
`audience`; feature-001's descriptor fields only — `INDEX.md` is never consulted, it is derived,
not source of truth):

```bash
bash canonical/aid/scripts/connectors/connector-registry.sh read <stem> <field> --root .aid/connectors
```

Any field difference (including a field's presence/absence — e.g. an `auth_method` downgrade to
`none` that drops `secret_reference`) classifies the stem UPDATE; identical values on every field
classify it NO-OP.

**Step R3 — apply, per class:**

- **ADD** (`stem ∈ D \ P`) and **UPDATE** (`stem ∈ D ∩ P`, fields differ) both write via "Write
  one descriptor" below. Before the *first* ADD/UPDATE write this cycle (skip this entirely on a
  REMOVE-only or all-NO-OP cycle — nothing under `.aid/connectors/` needs touching then):
  ```bash
  mkdir -p .aid/connectors
  if [ ! -f .aid/connectors/.gitignore ]; then
    printf '%s\n' '.secrets/' > .aid/connectors/.gitignore
  fi
  ```
  **ADD** creates `.aid/connectors/<stem>.md` fresh; no existing entry is touched. **UPDATE**
  overwrites `.aid/connectors/<stem>.md` **in place** (same stem — same file path, same INDEX
  identity, same secret path) and **preserves `.aid/connectors/.secrets/<stem>` unconditionally**
  — it is never touched as a side effect of a descriptor edit; the secret-capture invocation in
  "Write one descriptor" step 2 below is skipped on UPDATE unless `auth_method` or
  `secret_reference` themselves changed this cycle. (An UPDATE that downgrades a surviving
  connector's `auth_method` to `none` — dropping `secret_reference` — leaves
  `.aid/connectors/.secrets/<stem>` unreferenced; disposing of that orphan is feature-003's
  secret-lifecycle concern, not reconcile's — Step R3's purge below is REMOVE-scoped only.)
- **NO-OP** (`stem ∈ D ∩ P`, identical) — write nothing: no descriptor write, no secret touch.
  This is what makes a repeat run byte-stable.
- **REMOVE** (`stem ∈ P \ D`) — for each stem classified REMOVE in Step R2, **purge the secret,
  then delete the descriptor.** This order is load-bearing for interrupt-safety: the descriptor
  is what keeps a stem in `P` (Step R1), so an interrupt between the two leaves the stem still in
  `P` and still absent from `D` — re-derived as REMOVE next run (a re-purge is a clean no-op, then
  the descriptor deletes). The reverse order could drop the stem from `P` on an interrupt while
  its secret survives, stranding it.
  ```bash
  bash canonical/aid/scripts/connectors/connector-secret.sh purge <stem> --root .aid/connectors
  rm -f -- ".aid/connectors/<stem>.md"
  ```
  (PowerShell twin: `connector-secret.ps1`.) The purge op deletes `.aid/connectors/.secrets/<stem>`
  if present and succeeds silently if already absent (task-006's guarantee — never reads, echoes,
  or logs the value); it is aid-managed-only **in effect**: a tool-managed (`mcp`) stem has no
  stored secret, so its purge is a harmless no-op, and an `env:`/`keychain:` reference has no
  local-store file either. **There is no unwire step, for any connection type, `mcp` included**
  (Q10 supersedes Q8, amends Q9) — AID never wrote a host MCP config, so a REMOVE has nothing to
  unwire; deleting the descriptor removes the catalog entry and nothing else.

**Write one descriptor** (used by ADD and UPDATE above — reused, unchanged, by single-stem mode's
Step S2 below):

1. **Write `.aid/connectors/<stem>.md`** with the frontmatter fields from feature-001's Data
   Model plus a short human body, branching by the management mode (tool-managed `mcp` vs
   aid-managed `api|ssh|url|cli` — resolved by the caller before this helper is invoked: ELICIT's
   "Management-mode branch" for bulk mode, or the `<type>` argument for single-stem mode):
   - **Tool-managed (`mcp`):** `name`, `connection_type: mcp`, `endpoint` (informational),
     `auth_method: none`, **no `secret_reference` field**, `preset`, `objective`, `summary`,
     `tags`, `audience`. Body mirrors feature-001's worked `github.md` example: a `# <Name>`
     heading, a `> Connection: mcp · Mode: tool-managed · Auth: handled by the host tool (no AID
     credential)` summary line, and one or two lines of human-readable purpose that instruct the
     agent to **request the connection from the host tool's own MCP/plugin** — AID stores no
     credential for it.
   - **Aid-managed (`api | ssh | url | cli`):** `name`, `connection_type`, `endpoint`,
     `auth_method`, `secret_reference` (when `auth_method != none`), `preset`, `objective`,
     `summary`, `tags`, `audience`. Body mirrors feature-001's worked `m365.md` example: a
     `# <Name>` heading, a `> Connection: <type> · Mode: aid-managed · Auth: <auth_method>
     (reference: <secret_reference>)` summary line, and one or two lines of human-readable
     purpose. The descriptor carries **only** the `secret_reference` — never a value.
2. **Secret capture is aid-managed-only (Q10).** For a **tool-managed (`mcp`)** connector, **no
   secret is captured** — no prompt is presented and feature-003's `connector-secret` twin is
   **never invoked** (there is no `secret_reference` to fill). For an **aid-managed
   (`api|ssh|url|cli`)** connector on ADD, or on UPDATE when `auth_method`/`secret_reference`
   changed this cycle, **hand the secret VALUE to feature-003's twin — never capture it here.**
   When `secret_reference` uses the `file:` form (the default), invoke:
   ```bash
   bash canonical/aid/scripts/connectors/connector-secret.sh write <stem> --root .aid/connectors
   ```
   (PowerShell twin: `connector-secret.ps1`.) The script owns the no-echo capture and the
   exact-bytes, owner-only write to `.aid/connectors/.secrets/<stem>`; the caller never reads,
   holds, or echoes the value — it only supplies `<stem>` and lets the script prompt.
   **Never construct the invocation with the literal secret text inlined** in a bash command,
   `STATE.md`, the KB, or the conversation transcript — the script's own stdin capture (or a
   piped shell *variable*, per its header's automation example) is the only sanctioned path.
   For `env:` / `keychain:` reference forms, **do not** invoke `connector-secret.sh write` — no
   local value is stored by AID for those forms (resolved externally at use-time).
3. **No wiring step (Q10).** Tool-managed (`mcp`) connectors require no wiring: AID writes no
   host MCP config and triggers no host-tool action here — the agent requests the connection from
   the host tool itself at use-time (feature-005's consumption contract).

**Step R4 — regenerate `INDEX.md`.** Once per cycle, after every class in Step R3 has been
applied (never per-tool):

```bash
bash canonical/aid/scripts/connectors/build-connectors-index.sh \
  --root .aid/connectors --output .aid/connectors/INDEX.md
```

(PowerShell twin: `build-connectors-index.ps1`.) The builder is deterministic (no run timestamp —
KI-010): an all-NO-OP cycle (unchanged registry, e.g. a second run over the same declared set)
produces a byte-identical `INDEX.md`; a REMOVE that empties the registry produces a header-only
`INDEX.md` (zero rows) rather than deleting the file, so the `@.aid/connectors/INDEX.md` context
pointer never dangles.

**Step R5 — trace the outcome.** Print a one-line diff summary; never print, log, or write a
secret value:

```
[reconcile] Registry: +<added> added, ~<updated> updated, -<removed> removed (<purged> secret(s) purged); INDEX regenerated.
```

On completion, ELICIT proceeds to its own Step E3 (`state-elicit.md`).

## Single-stem mode (set/unset)

Called by `aid-set-connector <tool> <type>` (upsert) and `aid-unset-connector <tool>` (remove) —
work-004-connector-consumption's only net-new reconcile behavior. Unlike bulk mode, single-stem
mode never enumerates the persisted set `P`, never computes a `D`/`P` diff, and never touches any
stem other than the one the caller names — there is no `persisted ∖ declared` computation here to
fall into, so no *other* connector can ever end up classified REMOVE as a side effect of a
single-stem operation.

**Step S1 — classify the one stem.** No `D`/`P` sets are built; only the named stem's on-disk
existence is checked:

| Caller | Class | Condition |
|---|---|---|
| `aid-set-connector <tool> <type>` | ADD | `.aid/connectors/<stem>.md` does not yet exist |
| `aid-set-connector <tool> <type>` | UPDATE | `.aid/connectors/<stem>.md` already exists — **including** when `<type>` differs from the on-disk `connection_type` (a type transition is still a single UPDATE, never a REMOVE-then-ADD pair) |
| `aid-unset-connector <tool>` | REMOVE | unconditional — the named stem, whether or not a descriptor currently exists (absent ⇒ Step S2's REMOVE apply is a clean no-op — AC5) |

No stem other than the one named is enumerated, read, or classified.

**Step S2 — apply:**

- **ADD / UPDATE** (`aid-set-connector`): write the descriptor via "Write one descriptor" above
  (bulk mode) — same frontmatter fields, same body shape, same management-mode branch (here
  driven by the `<type>` argument), same ADD-or-`auth_method`/`secret_reference`-changed
  secret-capture trigger. **A `connection_type` transition on UPDATE is the one point where
  single-stem mode's secret handling diverges from bulk mode:** bulk mode's UPDATE (Step R3 above)
  purges a secret **only** on REMOVE, never on an in-place field UPDATE. `aid-set-connector`'s own
  secret-reconcile rules purge the orphaned secret when a type change moves the stem to `mcp`/
  `none`, and capture a fresh one when the type moves it to a credentialed aid-managed type or
  `auth_method` changes — that decision is **set-skill logic**, owned by the calling skill
  (`aid-set-connector/SKILL.md`), not by this shared reconcile helper.
- **REMOVE** (`aid-unset-connector`): the same purge-then-delete mechanics as bulk mode's Step R3
  REMOVE bullet above — `connector-secret purge <stem>` then delete `.aid/connectors/<stem>.md` —
  same interrupt-safety ordering (purge before delete), same idempotence (an already-absent
  stem's purge and delete are both clean no-ops — AC5).

**Step S3 — regenerate `INDEX.md`.** Same builder, same invocation, as bulk mode's Step R4 above:

```bash
bash canonical/aid/scripts/connectors/build-connectors-index.sh \
  --root .aid/connectors --output .aid/connectors/INDEX.md
```

(PowerShell twin: `build-connectors-index.ps1`.) The builder reads every descriptor currently on
disk — never any cycle's declared set — so re-running it after a single-stem op is inherently
correct: every untouched connector's row regenerates unchanged, and only the target stem's row is
added, updated, or removed.

> **No-collateral guarantee (AC6).** Single-stem mode never computes bulk mode's `persisted ∖
> declared` (Step R2) or any other whole-registry diff — there is no `D`/`P` here, only the one
> target stem. Consequently no other stem is ever classified, read for comparison, purged, or
> deleted: with ≥2 connectors catalogued, `aid-set-connector`/`aid-unset-connector` acting on one
> stem leaves every other connector's descriptor and secret byte-for-byte untouched. This is the
> structural guard against the bulk-mode `persisted ∖ declared` REMOVE trap (traces to AC7 —
> `aid-discover` ELICIT keeps its whole-registry bulk-mode reconcile unchanged; the two modes are
> independent, never mixed).
