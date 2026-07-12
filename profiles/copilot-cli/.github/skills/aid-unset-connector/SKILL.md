---
name: aid-unset-connector
description: >
  On-demand, off-pipeline removal from the connector catalog. `aid-unset-connector <tool>` deletes
  `.aid/connectors/<stem>.md` and purges its secret via connector-secret purge -- never invokes
  /aid-discover. Runs reconcile.md's single-stem REMOVE (purge-then-delete) so every OTHER
  catalogued connector is left byte-for-byte untouched, then rebuilds INDEX.md from whatever
  descriptors remain on disk. Idempotent: an already-absent stem is a clean no-op.
allowed-tools: Read, shell
argument-hint: "<tool>  -- e.g. aid-unset-connector Jira"
---

# Unset Connector

`aid-unset-connector <tool>` removes **one** connector from `.aid/connectors/` without touching any
other catalogued connector and without requiring — or triggering — an `/aid-discover` cycle. It is
the incremental, single-tool counterpart to `aid-set-connector`'s upsert
(`.github/skills/aid-set-connector/SKILL.md`), and shares its `reconcile.md` single-stem plumbing.

**Absent from the mandatory pipeline flow.** Like `aid-set-connector`, `/aid-config`, and
`/aid-housekeep`, this is an optional, on-demand skill — no phase gate references it, and it never
invokes `/aid-discover`.

**Keyed by `<tool>` → one descriptor, unconditionally removed.** Unlike `aid-set-connector`'s
ADD-vs-UPDATE classification, this skill has exactly one class: REMOVE. Whether `<tool>`'s stem is
currently catalogued or not, the same purge-then-delete sequence runs — on an already-absent stem
both operations are themselves clean no-ops (idempotent by construction; AC5), never a
special-cased branch that checks first and skips.

---

## Pre-flight

- `Default` or `Auto-accept edits` → proceed.
- `Plan mode` → STOP. This skill deletes files under `.aid/connectors/`.
- Requires exactly one positional argument: `<tool>`. No optional flags.

### Step 0: Validate arguments

1. Not exactly one positional argument → print and exit non-zero:
   ```
   Usage: aid-unset-connector <tool>
   Example: aid-unset-connector Jira
   ```
2. Any flag or extra argument is unknown:
   ```
   Unknown argument: <arg>
   Usage: aid-unset-connector <tool>
   ```
   exit non-zero.

From here on, `$TOOL` names the resolved `<tool>` argument (already validated above) — used as a
shell variable in the bash snippets below, never as literal angle-bracket text.

---

## Step 1: Resolve `<tool>` → descriptor stem

Derive the stem exactly as ELICIT and `aid-set-connector` do (feature-002's slug rule) — lowercase,
non-alphanumeric runs collapsed to `-`, no leading/trailing `-`:

```bash
STEM=$(echo "$TOOL" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
```

No other stem is derived, enumerated, read, or compared anywhere in this skill — **no
whole-registry diff, ever** (AC6).

---

## Step 2: Single-stem REMOVE (`reconcile.md`)

Per [`.github/aid/templates/connectors/reconcile.md`](../../aid/templates/connectors/reconcile.md)
§ "Single-stem mode (set/unset)" Step S1, classification for `aid-unset-connector` is
**unconditional** — REMOVE, whether or not `.aid/connectors/${STEM}.md` currently exists. There is
no existence check gating this step, no `list` over the registry, and no `read`/field comparison
(unlike `aid-set-connector`'s ADD/UPDATE classification) — REMOVE does not compare fields, it only
disposes of them. Apply Step S2's REMOVE mechanics — the same purge-then-delete sequence bulk mode
uses:

```bash
bash .github/aid/scripts/connectors/connector-secret.sh purge "$STEM" --root .aid/connectors
rm -f -- ".aid/connectors/${STEM}.md"
```

(PowerShell twin: `connector-secret.ps1`.) Purge-before-delete is the same interrupt-safety ordering
`reconcile.md` documents for REMOVE: the descriptor is what keeps a stem catalogued, so an interrupt
between the two commands leaves the stem still catalogued and still targeted for removal — nothing
is stranded, and a retry lands on the same two idempotent calls. `connector-secret.sh purge` deletes
`.aid/connectors/.secrets/${STEM}` if present and succeeds silently if already absent (it requires
no `.secrets/` gitignore precondition — only `write` fails closed on that); `rm -f` on an
already-absent descriptor is likewise a clean no-op. Running these same two commands unconditionally
— never gated on a prior existence check — is exactly what makes a second
`aid-unset-connector Jira` against an already-removed stem exit 0 with no error and no registry
churn (AC5): the identical two calls run, they simply have nothing left to act on.

No stem other than `$STEM` is read, purged, or deleted (AC6).

---

## Step 3: Rebuild `INDEX.md`

Same builder, same invocation, as `reconcile.md`'s Step S3 / R4:

```bash
bash .github/aid/scripts/connectors/build-connectors-index.sh \
  --root .aid/connectors --output .aid/connectors/INDEX.md
```

(PowerShell twin: `build-connectors-index.ps1`.) The builder is deterministic (no run timestamp —
KI-010) and reads every descriptor currently on disk — never any prior declared set — so it
regenerates every surviving connector's row unchanged and simply omits `$STEM`'s row (dropped in
Step 2, or never present to begin with). A repeat run over an unchanged registry (the idempotent
second-call case above) reproduces a byte-identical `INDEX.md`.

Print a one-line trace (mirrors `reconcile.md`'s Step R5 shape, singular — never print, log, or
write a secret value):
```
[aid-unset-connector] <STEM>: removed (secret purged if present); INDEX regenerated.
```

Exit 0.

---

## Write-zone

This skill writes (only to delete) **within** `.aid/connectors/` — the same P7 exemption ELICIT and
`aid-set-connector` use (`.github/aid/templates/kb-authoring/principles.md` P7 "Exception
(connector sub-phase)"): it removes `.aid/connectors/<stem>.md` and, via `connector-secret.sh`,
`.aid/connectors/.secrets/<stem>`, then regenerates `.aid/connectors/INDEX.md`. It never touches
`.aid/knowledge/`, never invokes `/aid-discover`, and never writes or unwires any host tool's MCP
configuration (STATE.md Q10 — AID is a catalog, not a connection manager; there was never a wire
step for it to undo). Unlike `aid-set-connector`, it never establishes or depends on the
`.secrets/` gitignore precondition — `connector-secret purge` has no fail-closed gate (only `write`
does), and this skill never calls `write`.

---

## Reused scripts (no new scripts)

| Script | Op used here | Purpose |
|---|---|---|
| `connector-secret.sh` | `purge <stem>` | Idempotently delete the one secret `$STEM` may have (Step 2) |
| `build-connectors-index.sh` | default | Rebuild `INDEX.md` from every descriptor left on disk (Step 3) |

(PowerShell twins: `connector-secret.ps1`, `build-connectors-index.ps1`.) No new script is
introduced by this skill; `connector-registry.sh` (`list`/`read`) is never invoked — this skill never
enumerates or field-compares the registry.

---

## Worked examples

- **`aid-unset-connector Jira`** with `.aid/connectors/jira.md` catalogued → Step 1 resolves
  `STEM=jira` → Step 2 purges `.aid/connectors/.secrets/jira` (if present) and deletes `jira.md` →
  Step 3 rebuilds `INDEX.md`, dropping the `jira` row (AC5).
- **`aid-unset-connector Jira`** run a second time, immediately after the above → Step 2's purge and
  `rm -f` both find nothing left to act on and exit 0 exactly as before → Step 3 rebuilds a
  byte-identical `INDEX.md` (no `jira` row either time) → no error, no registry churn (AC5,
  idempotent).
- With `jira` and `github` both catalogued, `aid-unset-connector Jira` never enumerates, reads,
  purges, or deletes `github.md` or its secret (AC6) — Step 1/Step 2 operate on `$STEM` (`jira`)
  only, and Step 3's builder simply re-reads `github.md` unchanged off disk into the rebuilt index.
- **Off-pipeline:** none of the steps above read or write `.aid/knowledge/`, invoke `/aid-discover`,
  or touch any host tool's MCP configuration — the only files touched are
  `.aid/connectors/<stem>.md`, `.aid/connectors/.secrets/<stem>`, and `.aid/connectors/INDEX.md`
  (AC10, write-zone confinement).
