# Idempotent Reconcile

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5 (FR-7) + §9 (AC-6) | /aid-define |
| 2026-07-08 | Technical Specification authored (Data Model, Feature Flow, State Machines, Layers & Components); binds to feature-001's frozen contract (descriptor filename stem = connector key; secret at `.aid/connectors/.secrets/<connector>`); encodes PURGE-on-remove per STATE.md Q3; mirrors the aid-discover idempotent re-entry pattern (`state-generate.md` Steps 0cx/0d/0f) | /aid-specify |
| 2026-07-08 | FIX pass (A+ gate, was D+; 1 HIGH + 1 MED): [HIGH] corrected the idempotence proof to rest on feature-005's DETERMINISTIC connectors builder (no run timestamp) — `build-kb-index.sh` embeds a `date -u` stamp, which is exactly why the connectors builder omits it (KI-010); [MED] reordered REMOVE to purge-before-delete for interrupt-safety; aligned ownership to STATE.md Q7 (feature-006 CALLS feature-003's `connector-secret purge` op + feature-005's INDEX builder — owns no twin/builder; only net-new code is the reconcile diff) | /aid-specify |
| 2026-07-08 | Cross-feature FIX (aid-plan gate, STATE.md Q8): REMOVE now also UNWIRES an `mcp`-typed connector's host config — feature-006 CALLS feature-004's `unwire <stem>` op (mirrors the feature-003 `purge` call), ordered purge + unwire BEFORE descriptor-delete for interrupt-safety; feature-006 still owns no wiring code (orchestration only). **[SUPERSEDED by the 2026-07-09 Q10 reframe — REMOVE no longer unwires.]** | /aid-specify |
| 2026-07-09 | **Q10 reframe (user-directed, mid-Execute) — TOUCH.** Catalog, not manager: AID never wires or unwires host MCP configs. REMOVE **drops the unwire step entirely** — corrected REMOVE = purge the local secret (aid-managed connectors only, via feature-003's `connector-secret purge`; a clean no-op for tool-managed `mcp` connectors, which store none) + delete the descriptor + regenerate the INDEX (feature-005 builder), purge-before-delete for interrupt-safety. Dropped every feature-004 `unwire`/`tools.installed`/host-config reference (intro, Data Model REMOVE row + side-effect note, Feature Flow R3, interrupt-safety rationale, ownership matrix row, algorithm, "host unwire" subsection, Boundary, Scope). Q9 SKIPPED (no-op) / DECLARED-EMPTY (remove-all) branch retained; "remove" no longer includes unwire. Supersedes Q8, amends Q9. | user / aid-execute loopback |

## Source

- REQUIREMENTS.md §5 FR-7 (Idempotent reconcile)
- REQUIREMENTS.md §9 Acceptance Criteria: AC-6

## Description

This feature makes re-running discovery safe and repeatable. When aid-discover is run again
after the project's external sources or tools have changed, the registry is reconciled rather
than rebuilt: new entries are added, changed entries are updated, and entries that are no longer
present are removed.

Reconciliation never clobbers what should be kept. Existing registry entries that are still
valid are preserved, and their stored secrets are never lost or overwritten as a side effect of
a re-run. When a tool is removed during reconcile, its associated local secret is purged from
the local store — removal is clean, leaving no orphaned credential behind — while every
surviving entry's secret is preserved. The result is that discovery can be run as many times as
needed and the registry stays in step with reality without the developer having to redo prior
work or re-enter secrets.

## User Stories

- As a developer/adopter, I want to re-run aid-discover after adding a tool and have the new
  entry added so that I can grow the registry incrementally.
- As a developer/adopter, I want to re-run after changing a tool and have the entry updated in
  place so that the registry reflects the change without losing other entries.
- As a developer/adopter, I want to re-run after removing a tool and have the absent entry
  dropped and its local secret purged, while my other entries and their stored secrets are
  preserved.

## Priority

Must

## Acceptance Criteria

- [ ] Given an existing registry, when aid-discover is re-run after a tool is added, then the new entry is added without clobbering existing entries or stored secrets. (FR-7, AC-6)
- [ ] Given an existing registry, when aid-discover is re-run after a tool is changed, then the changed entry is updated in place without losing other entries or stored secrets. (FR-7, AC-6)
- [ ] Given an existing registry, when aid-discover is re-run after a tool is removed, then the absent entry is removed and its associated local secret is purged from the local store, while other entries and their stored secrets are preserved. (FR-7, AC-6)

---

## Technical Specification

> Authored by `/aid-specify`. This feature adds **no new persisted shapes and no new store** — it
> is the re-entry behavior over the store feature-001 froze. It **binds to** feature-001's contract
> and does not redefine it: the registry is the set of descriptor files under `.aid/connectors/`,
> each keyed by its **filename stem** (the connector key); the secret value for a connector lives
> only in the git-ignored `.aid/connectors/.secrets/<connector>` (one file per connector, named by
> the stem); and `.aid/connectors/INDEX.md` is regenerated from descriptor frontmatter by the
> **connectors INDEX builder** — a contract feature-001 defines, regeneration **owned by feature-005**
> (Q7 item 5), and **deterministic** (no run timestamp), which is what lets reconcile re-run without
> churning the index. All reconcile writes fall inside `.aid/connectors/`, which is already on the
> P7-exempt allowlist feature-001 declares (Q6); this feature introduces no new write target and no
> new P7 carve-out.
>
> **Ownership (STATE.md `## Cross-phase Q&A` Q7; Q8 superseded by Q10).** feature-006 is pure
> **orchestration** — it owns no store, no descriptor writer, no secret twin, and no index builder.
> It composes feature-002 (descriptor authoring), feature-003 (the `connector-secret` twin — both
> `write` and `purge` ops; feature-006 **calls** the `purge` op, it does not define its own), and
> feature-005 (the deterministic INDEX builder). It does **not** compose any host-config wiring:
> under **Q10** AID never wires or unwires host MCP configs, so there is no `unwire` op to call (this
> supersedes Q8). Its only net-new contribution is the reconcile diff itself.
>
> **Q3 is the load-bearing behavior on REMOVE (Q10 amends Q9).** The associated local secret is
> **purged** (via feature-003's `purge` op — **aid-managed** connectors only; a tool-managed `mcp`
> connector has no stored secret, so purge is a clean no-op) and the descriptor is deleted; there is
> **no** unwire step. Every surviving entry and its secret is preserved.

### Data Model

Reconcile introduces **no new schema** and persists no new artifact. It operates over feature-001's
existing shapes and reasons about them as a **set diff keyed by the descriptor filename stem** — the
connector key defined in feature-001 (`.aid/connectors/<connector>.md`; the stem is the machine key,
`name` is the human label). The diff is computed each run and is never itself persisted; the registry
files on disk are the only state.

**The two sets being diffed:**

| Set | Symbol | Source | Members (keyed by stem) |
|-----|--------|--------|--------------------------|
| Declared set | `D` | The current run's tool elicitation (feature-002) — the tools the user declared this run | stem + the feature-001 descriptor fields (`name`, `connection_type`, `endpoint`, `auth_method`, `secret_reference`, `preset`, routing text) |
| Persisted set | `P` | The descriptor files on disk: `.aid/connectors/*.md` **excluding** `INDEX.md` (and excluding the non-descriptor `.gitignore` / `.secrets/`) | stem of each `<connector>.md`, plus its on-disk field values |

**The diff partition** (every stem lands in exactly one class):

| Class | Set membership | Descriptor `.aid/connectors/<stem>.md` | Secret `.aid/connectors/.secrets/<stem>` | INDEX row |
|-------|----------------|----------------------------------------|-------------------------------------------|-----------|
| ADD | `stem ∈ D \ P` | created (feature-002 authors it) | registered by feature-003 iff `auth_method != none` | appears after regen |
| UPDATE | `stem ∈ D ∩ P` **and** any field differs | overwritten in place (same stem) | preserved; re-registered by feature-003 only if `auth_method`/`secret_reference` changed | refreshed after regen |
| NO-OP | `stem ∈ D ∩ P` **and** all fields identical | untouched (no write) | untouched | unchanged after regen |
| REMOVE | `stem ∈ P \ D` | deleted (after purge) | **purged** (Q3) via feature-003 `purge` op — aid-managed only; see Feature Flow | dropped after regen |

The one-file-per-connector layout (feature-001) is what makes each class a **clean, isolated file
operation** — there is no monolithic registry to rewrite, so an op on one connector never risks a
sibling's descriptor or secret. Field-equality for the ADD/UPDATE/NO-OP split is decided over the
feature-001 descriptor fields only (frontmatter fields + routing text); the generated `INDEX.md` is
**never** an input to the diff (it is derived, not source of truth).

**REMOVE carries one composed side-effect (Q3; Q10 removes the former unwire).** Beyond deleting the
descriptor, a REMOVE **purges** the connector's secret (feature-003). Under **Q10** AID never wires
host MCP configs, so there is **no** unwire step for any connection type — REMOVE = purge +
descriptor-delete for every connector, `mcp` included. The purge affects only **aid-managed**
connectors that stored a `file:` secret; for a tool-managed (`mcp`) connector — which has no stored
secret — and for `env:`/`keychain:` references, the purge is a clean no-op. The purge is a call into
an op feature-003 owns (see Step R3); reconcile keys it on the same stem as everything else.

### Feature Flow

Reconcile is a step inside the P7-exempt connector state that feature-002 introduces (Q6); it runs
on **every** discovery cycle, after elicitation has resolved the declared set `D`. It never rebuilds
the registry — it converges the registry toward `D`.

**Step R0 — Guard the destructive path (clean-skip).** A **skipped** elicitation (the user opted out
of the tool step this run — feature-002 / AC-1) yields **no declared set**: `D` is undefined, NOT the
empty set. Reconcile is then a **no-op** — it touches nothing under `.aid/connectors/`, writes no
empty artifacts, and performs no purge; the prior registry is left exactly intact. A skip MUST NOT be
read as "remove every connector": REMOVE is only ever derived from a declared set the user actually
produced this run. (This mirrors the aid-discover re-entry discipline: absent input means "leave the
prior record intact", never "wipe it".) An **authoritative empty declaration** (`D = {}` — the user
ran the tool step and declared zero tools, which feature-002 distinguishes from a skip) IS a real
reconcile: every persisted entry falls into `P \ D` and is removed-and-purged per Step R3. The
skip-vs-empty determination is feature-002's; feature-006 acts on the result.

**Step R1 — Enumerate the persisted set `P`.** List the on-disk descriptors with feature-001's
registry accessor twin (`list connectors`), NOT `read-setting.sh` (KI-001). `P` is the set of
`.aid/connectors/*.md` stems excluding `INDEX.md`.

**Step R2 — Compute the diff.** Partition `D ∪ P` into ADD / UPDATE / NO-OP / REMOVE per the Data
Model table (set membership on the stem; field-equality for the `D ∩ P` split).

**Step R3 — Apply, per class:**

- **ADD** (`stem ∈ D \ P`) — feature-002 writes the new `.aid/connectors/<stem>.md`; if
  `auth_method != none`, feature-003 registers the secret at `.aid/connectors/.secrets/<stem>` and
  records only the `secret_reference` in the descriptor (reference-not-value; feature-001 Security
  Specs). No existing entry is touched.
- **UPDATE** (`stem ∈ D ∩ P`, fields differ) — overwrite the descriptor **in place** (same stem, so
  the file path, the INDEX identity, and the secret path are all stable). **Preserve the stored
  secret** `.aid/connectors/.secrets/<stem>` — it is never deleted or overwritten as a side effect
  of a descriptor edit. Re-registration of the secret **value** happens only when `auth_method` /
  `secret_reference` themselves changed, and that is feature-003's prompt, not reconcile's file op.
  One orphan edge on a *surviving* connector: an UPDATE that downgrades `auth_method` to `none`
  (dropping `secret_reference`) leaves `.aid/connectors/.secrets/<stem>` unreferenced. Feature-006's
  Q3 purge is **REMOVE-scoped**, so it does not fire here; disposing of a now-unreferenced secret on
  an auth-downgrade is feature-003's secret-lifecycle concern (it owns the `.secrets/` writes).
  Called out so the orphan is owned, not silently left ("no orphaned credential behind" — realized
  jointly: purge-on-REMOVE here + downgrade-disposal in feature-003).
- **NO-OP** (`stem ∈ D ∩ P`, identical) — write nothing. This is what makes a repeat run
  byte-stable: an unchanged connector produces zero descriptor churn.
- **REMOVE** (`stem ∈ P \ D`) — **purge FIRST, then delete the descriptor** (the ordering is
  load-bearing for interrupt-safety — see below):
  1. **PURGE the secret** (Q3) by invoking feature-003's `connector-secret purge <stem>` op —
     feature-003 owns the `.secrets/` twin (Q7 item 2), so feature-006 **calls** the op rather than
     deleting the file itself. The op deletes `.aid/connectors/.secrets/<stem>` if it exists, is
     path-confined to `.aid/connectors/.secrets/`, and is silent on the value; feature-006 relies on
     those guarantees. This affects only **aid-managed** connectors that stored a `file:` secret. A
     tool-managed (`mcp`) connector has **no** stored secret (Q10), and a connector whose reference
     was `env:<VAR>` or `keychain:<key>` (not the default `file:` form) has no local-store file — in
     both cases the purge is a harmless no-op, and reconcile never mutates the environment or the OS
     keychain (feature-001 Security Specs; §6).
  2. **Delete the descriptor** `.aid/connectors/<stem>.md`.
  **No unwire step (Q10 supersedes Q8, amends Q9).** AID never wrote a host MCP config, so a REMOVE
  has nothing to unwire — for any connection type, `mcp` included. A removed `mcp` connector was only
  ever a catalog entry telling the agent to request the connection from its host tool; deleting the
  descriptor removes that catalog entry and nothing else. Removal is clean — no orphaned credential is
  left behind.
  - **Interrupt-safety (why purge before delete).** The descriptor is the sole basis of `P`
    (Step R1). If a REMOVE is interrupted **before** the descriptor delete, the descriptor is still
    on disk, so the stem stays in `P`, stays absent from `D`, and is re-derived as REMOVE next run —
    which re-purges (a clean no-op: the secret is already gone) and then re-deletes. The other order
    (delete first) would drop the stem from `P` on an interrupt while leaving `.secrets/<stem>`
    behind; because the tool is also absent from `D`, that orphaned secret would never again be
    classified REMOVE and would be stranded. Purge-before-delete closes that hole — no interrupt can
    strand a secret.

**Step R4 — Regenerate `INDEX.md`.** After all class ops, rebuild `.aid/connectors/INDEX.md` from the
**remaining** descriptors' frontmatter by invoking **feature-005's INDEX builder** (regeneration is
feature-005's, per Q7 item 5; the contract — columns, frontmatter, one row per descriptor — is
feature-001's). Regeneration — not row-editing — is how ADD/UPDATE/REMOVE reach the index: the builder
emits exactly one row per descriptor on disk, so removed connectors drop out and added ones appear
with no manual row surgery. Like `.aid/knowledge/INDEX.md` it regenerates every discovery cycle
(`state-generate.md` Step 6), but **unlike** the KB's `build-kb-index.sh` the connectors builder emits
**no run timestamp** and is therefore **deterministic**: regenerating from unchanged descriptors
yields a byte-identical file (Q7 CF-INDEX; KI-010; see the idempotence proof). If REMOVE empties the
registry, the builder regenerates a **header-only INDEX.md** (zero rows) rather than deleting it, so
the `@.aid/connectors/INDEX.md` pointer in the context files (feature-001) never dangles. (This is
distinct from AC-1's clean-skip "no empty artifacts", which governs the never-had-connectors case in
Step R0 and is feature-002's concern.)

**Step R5 — Trace the outcome.** Print a one-line diff summary for traceability, in the
`state-generate.md` `[step]` house style, e.g.
`[reconcile] Registry: +2 added, ~1 updated, -1 removed (1 secret purged); INDEX regenerated.`
No secret value is ever printed, logged, or written to `STATE.md`/transcript (feature-001 Security
Specs; §6).

**Preservation guarantee (AC-6).** A surviving connector (NO-OP or UPDATE) and its secret are never
lost by a re-run: NO-OP writes nothing at all; UPDATE overwrites only the descriptor and leaves
`.aid/connectors/.secrets/<stem>` intact. Only a REMOVE — a connector the user dropped from the
declared set — deletes a descriptor and purges its secret.

### State Machines

Reconcile does **not** add a new top-level state to the discover lifecycle
(`GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE`). It is an **idempotent, re-entrant step**
inside feature-002's connector state, exactly as Steps 0cx / 0d / 0f are re-entrant steps inside
GENERATE. It mirrors their `#### Idempotent re-entry` contract from
`canonical/skills/aid-discover/references/state-generate.md`: **read the prior record first, then
converge; re-entry is always a reconcile, never a rebuild.**

Mapping the mirrored pattern:

| aid-discover re-entry pattern (`state-generate.md`) | feature-006 reconcile analogue |
|------------------------------------------------------|--------------------------------|
| Step 0cx/0d/0f read the prior record (`## Discovery Domain` / `discovery.doc_set` / `## Discovery Triage`) before measuring | Step R1 reads the persisted set `P` (the on-disk descriptors) before applying anything |
| "Prior exists → show it as a diff and converge; no prior → proceed fresh" | Prior registry (`P` non-empty) → diff `D` vs `P` and apply; no prior (`P` empty, first run) → pure ADD path — every declared connector is new |
| "Re-entry is always an overwrite" (Step 0cx/0d) | UPDATE overwrites the descriptor in place; INDEX is regenerated (overwritten) each cycle |
| Step 1 "Skip if both already exist" (no duplicate work) | NO-OP writes nothing when a connector is unchanged; the index has one row per descriptor, so re-runs never accumulate duplicate rows |
| AC-1 "skips cleanly when there are none (no empty artifacts written)" | Step R0 clean-skip: an absent/empty declared set is a no-op, no `.aid/connectors/` artifact is written |

**Idempotence proof obligation (AC-6, and "re-running produces no duplicate/empty artifacts").**
Running reconcile twice against the same declared set converges on the first run and is a pure no-op
on the second: on run 2, `D == P`, every shared stem hits NO-OP (zero descriptor writes, zero
purges). The byte-identical `INDEX.md` on run 2 rests specifically on **feature-005's builder being
deterministic** — it emits no run timestamp. This is a deliberate divergence from the KB's
`build-kb-index.sh`, which stamps each run with `TS="$(date -u ...)"` (emitted in its
`<!-- AUTO-GENERATED $TS ... -->` and `Generated at: $TS` lines) and is therefore **not**
byte-reproducible: two KB-builder runs on identical input differ at those timestamp lines. The
connectors builder omits that timestamp for exactly this reason (Q7 CF-INDEX; KI-010), so
regenerating from unchanged descriptors is byte-identical. The byte-identical claim relies on the
connectors builder's determinism — **not** on `build-kb-index.sh`, which does not have it. No
duplicate descriptor is ever created (ADD is create-if-absent on a unique stem), no duplicate INDEX
row is ever appended (rows are rebuilt from disk, not accumulated), and no empty artifact is ever
written (Step R0 guards the skip case; the header-only INDEX in Step R4 is a deliberate valid-pointer
state, not an empty-on-skip artifact).

**Re-entry after interruption.** Because the descriptor files on disk are the only state and each op
is an isolated file change, a reconcile interrupted mid-apply re-converges on the next run:
already-applied ADDs/UPDATEs land as NO-OPs, and a partially-applied REMOVE is re-derived from
`P \ D` and re-applied. That re-derivation is sound only because REMOVE **purges before it deletes
the descriptor** (Step R3): the descriptor is what keeps the stem in `P`, so an interrupt at any
point of a REMOVE leaves the stem still in `P` and still absent from `D` — hence still classified
REMOVE next run (its re-purge is a clean no-op, then the descriptor is deleted). There is no
partial-write bookkeeping to recover and no interrupt window in which a secret is stranded — the next
run's diff is genuinely self-correcting.

### Layers & Components

Reconcile is **pure orchestration**: it reuses components owned by feature-001/002/003/005 and adds
**no net-new twin or script** — its only net-new contribution is the reconcile diff logic itself
(Q7). Everything runs inside feature-002's P7-exempt connector state; all writes are within
`.aid/connectors/`, already on feature-001's declared allowlist (Q6).

**Components (by origin):**

| Component | Origin | Reconcile's use |
|-----------|--------|-----------------|
| Registry accessor twin (`.sh` + `.ps1`/`.psm1`): `list connectors`, `read field` | feature-001 (KI-001 — NOT `read-setting.sh`) | Step R1 enumerates `P`; field reads feed the UPDATE/NO-OP equality check |
| INDEX builder (deterministic, no run timestamp; contract per feature-001) | feature-005 (Q7 item 5) | Step R4 regenerates `INDEX.md` from surviving descriptors |
| Descriptor authoring (create/overwrite `<connector>.md`) | feature-002 (Q7 item 1) | Step R3 ADD/UPDATE |
| `connector-secret` twin — `write` op | feature-003 (Q7 item 2) | Step R3 ADD, and UPDATE when auth changed |
| `connector-secret` twin — `purge <stem>` op | feature-003 (Q7 item 2) | Step R3 REMOVE — feature-006 **calls** it; does not own it |

**The reconcile algorithm** (orchestrated inline in the connector state, in the `state-generate.md`
inline-bash style — the set diff needs the in-session declared set `D`, so it is not a standalone
script): guard-skip (R0) → `list connectors` for `P` (R1) → partition `D ∪ P` on the stem, splitting
`D ∩ P` by field-equality (R2) → dispatch each class to its owning component, REMOVE purging
(feature-003 `purge`) before deleting the descriptor — **no unwire step** (Q10) — (R3) → invoke
feature-005's deterministic INDEX builder (R4) → print the diff summary (R5). **This diff logic is
feature-006's sole net-new code.**

**The secret purge (feature-006 calls feature-003's op).** Deleting a secret file is **not**
feature-006's twin — the `.secrets/` store is owned end-to-end by feature-003's `connector-secret`
Bash+PowerShell twin, which exposes both `write` and `purge` ops (Q7 item 2). On REMOVE, feature-006
**invokes** `connector-secret purge <stem>`. The op's contract is specified and owned by feature-003;
feature-006 **relies on** these guarantees and does not re-implement them:

- **Path confinement:** the op refuses any target escaping `.aid/connectors/.secrets/` (a stem is a
  filename, never a path fragment — a stem containing a path separator or `..` is rejected).
- **Idempotent delete:** deletes `.aid/connectors/.secrets/<stem>` if present, succeeds silently if
  already absent — this is what makes the purge-before-delete interrupt re-entry above safe (a
  re-purge on the next run is a clean no-op).
- **Silent on the value:** never reads, echoes, logs, or copies the file contents; the value never
  surfaces in output, `STATE.md`, or the transcript (feature-001 Security Specs; §6).
- **Cross-platform, zero-dep:** pure Bash on POSIX / pure PowerShell on Windows (AC-8, §6), authored
  per the `.aid/knowledge/coding-standards.md` twin rule (both twins in one commit; shipped
  PowerShell WinPS-5.1-compatible + ASCII-only). This is feature-003's obligation, noted here so
  reconcile inherits a cross-platform purge.

**No host unwire (Q10 supersedes Q8).** feature-006 does **not** touch any host MCP configuration on
REMOVE. Under Q10 AID never wires or unwires host configs — a tool-managed (`mcp`) connector is only
a catalog entry directing the agent to request the connection from its host tool, so removing it is
just a descriptor-delete (plus a no-op purge, since it has no stored secret). There is **no** `unwire`
op, **no** `.aid/settings.yml tools.installed` read, and **no** host-config write anywhere in
reconcile.

**Boundary.** This SPEC defines only the **reconcile diff behavior**. The descriptor authoring
(feature-002), the `connector-secret` twin's `write` + `purge` ops (feature-003), the connection-mode
model + consumption semantics (feature-004 — no wiring, Q10), the INDEX builder (feature-005), and the
registry accessor + connectors contract (feature-001) are specified in their own features; feature-006
composes them and adds only the diff orchestration (owning no store, no twin, and no builder). The
P7-exempt state that hosts this step is introduced by feature-002; feature-006 does not add a new
carve-out (all its writes are within the `.aid/connectors/` allowlist feature-001 already declares).

**Scope — orchestration; owns no store/twin/builder.** Reconcile here covers the
**tool/integration registry** (`.aid/connectors/`) — the FR-7/AC-6 subject (tools, descriptors, and
stored secrets). It composes ops other features own (feature-003 `purge`, feature-005 INDEX build);
its own code is only the set-diff orchestration. It performs **no** host-config wiring/unwiring
(Q10). The **external-sources** side (keeping `.aid/knowledge/external-sources.md` fresh across
re-runs) is NOT this feature's: its single writer is the Scout pre-scan, made content-aware by
feature-002 (Q7 item 4; KI-008). feature-006 owns no source-side reconcile.
