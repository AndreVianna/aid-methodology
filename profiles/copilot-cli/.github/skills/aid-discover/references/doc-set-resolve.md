# Doc-Set Resolve — Shared Snippet

Shared bash snippet for resolving the project's declared doc-set from `.aid/settings.yml`.
Referenced from `state-generate.md` and `state-review.md` rather than duplicated there.

---

## Schema: `discovery.doc_set` in `.aid/settings.yml`

`discovery.doc_set` is a block-list of pipe-delimited scalars inside the existing
`.aid/settings.yml` (YAML 1.2). Each list item is one record; fields are separated by `|`.

```yaml
discovery:
  doc_set:
    - architecture.md|aid-researcher-architecture|required
    - schemas.md|aid-researcher-analyst|required
    - tech-debt.md|aid-researcher-quality|required
    - infrastructure.md|aid-researcher-quality|conditional:project has deployment/CI configuration
    - repo-presentation.md|aid-researcher-architecture|conditional
    # each item: filename | owner | presence(required|conditional[:when])
    # category and expectations are NOT declared here:
    #   - category resolves from the doc's own frontmatter `kb-category:` (build-kb-index.sh)
    #   - expectations resolve from references/document-expectations.md keyed by ### <filename>
    # Absent section → the canonical default seed is used unchanged (backward compatible).
```

### Field grammar

- **field 1 — `filename`** — basename under `.aid/knowledge/`; the key that joins to frontmatter
  (`kb-category`) and to `document-expectations.md` (`### <filename>`).
- **field 2 — `owner`** — MUST be one of the parameterized `aid-researcher` slots
  (`aid-researcher-scout|aid-researcher-architecture|aid-researcher-analyst|aid-researcher-integrator|aid-researcher-quality`)
  or `skill-self` for generated/meta docs (`feature-inventory.md`, `README.md`, `INDEX.md`) — meaning
  the skill itself generates this file, no agent is dispatched.
  No new agent enum value is introduced by this feature.
- **field 3 — `presence`** — `required` | `conditional`. `conditional` MAY carry a free-text
  `when` after a colon (`conditional:<when>`) — a human hint shown at propose→confirm, not
  machine-evaluated; the user's confirm is the gate. The `when` hint MUST be comma-free (see the
  delimiter constraint below): rephrase any enumeration with `;` or `/`
  (e.g. `conditional:has CI; CD; or deploy config`), never a comma.
- `category` and `expectations` are intentionally absent from this schema (no-duplication):
  `category` resolves from each doc's own frontmatter `kb-category:`, and `expectations` resolve
  from `references/document-expectations.md` keyed by `### <filename>`.

### Delimiter constraint — no field value may contain a comma

`read-setting.sh`'s `lookup_list` returns block-list items **comma-joined into one string**, and
the caller re-splits on `,` to recover the items. The comma is therefore the **item separator**
and cannot appear inside ANY field value (`filename`, `owner`, `presence`, or the free-text `when`
hint). A comma in `when` (e.g. `conditional:has CI, CD, or deploy config`) would be shredded by
the comma-join/comma-split round-trip into spurious records. Rephrase any list-like `when` with
`;` or `/`. The `|` field separator is safe because filenames, the agent enum, and `presence`
never contain `|`; a `when` hint is free text but is the last field, so any residual `|` in it is
tolerated (everything after the 3rd `|` is treated as part of `presence`/`when`).

> **Comment placement constraint:** inline `# comment` on an item line is stripped by
> `lookup_list` (verified `read-setting.sh:197`). A full-line comment between items terminates
> list accumulation early (`read-setting.sh:204` — `in_list { in_list=0 }`); place full-line
> comments only **after** the last item, never between items.

---

## `synth_default_seed` — Default seed when `discovery.doc_set` is unset

When the `discovery.doc_set` section is absent/empty, synthesize the default seed
deterministically from `.github/aid/templates/knowledge-base/*.md` paired to the ownership map
below. This satisfies FR-P0-4 (no hardcoded doc-count/doc-list literal) by making the default
set self-describing from the templates that exist on disk.

### Ownership map (§2.2 single source of truth)

Concern ids follow the model in `.github/aid/templates/kb-authoring/concern-model.md`.
The concern column is documentation only -- it is NOT a machine field; the emitted TSV
stays `filename<TAB>owner<TAB>presence` (three fields only).

| Template file | Owner | Concern |
|---|---|---|
| `project-structure.md` | `aid-researcher-scout` | C1 (Build & shape) |
| `external-sources.md` | `aid-researcher-scout` | orientation |
| `architecture.md` | `aid-researcher-architecture` | C1 (Build & shape) |
| `technology-stack.md` | `aid-researcher-architecture` | C0 (Technology) |
| `module-map.md` | `aid-researcher-analyst` | C2 (Parts & connections) |
| `coding-standards.md` | `aid-researcher-analyst` | C3 (Conventions) |
| `schemas.md` | `aid-researcher-analyst` | C5 (Data & contracts) |
| `pipeline-contracts.md` | `aid-researcher-integrator` | C2 (Parts & connections) |
| `integration-map.md` | `aid-researcher-integrator` | C2 (Parts & connections) |
| `domain-glossary.md` | `aid-researcher-integrator` | C4 (Vocabulary / concept spine) |
| `test-landscape.md` | `aid-researcher-quality` | C6 (Quality & testing) |
| `tech-debt.md` | `aid-researcher-quality` | C7 (Risk & debt) |
| `infrastructure.md` | `aid-researcher-quality` | C8 (Shipping & operation) |
| `feature-inventory.md` | `skill-self` | C9 (What it does for users) |
| `README.md` | `skill-self` | orientation |

`INDEX.md` is generated meta-only (not a KB-template artifact); it is owned by `skill-self`
and not synthesized from templates. (The `skill-self` owner value denotes the skill itself — not a dispatched agent.)

> **Two independent axes — concern vs. role:** The concern column above uses `orientation`
> to mean *cross-cutting* (not mapped to a single spine dimension C0-C9). This is the
> **concern axis**. Do NOT conflate it with the **role axis** value `kb-category: meta`
> (review/lint-exempt process/state ledgers: INDEX.md, README.md, STATE.md). A document
> can be `kb-category: primary` (standard authored content, role axis) while carrying an
> *orientation* concern (concern axis). `external-sources.md` is exactly this: it is a
> standard, authored, review-eligible KB document (`kb-category: primary`) whose concern
> is *orientation* (cross-cutting). Tagging it as `kb-category: meta` because of its
> orientation concern is a mis-tag — the two axes are orthogonal.

```bash
# synth_default_seed — enumerate canonical/templates/knowledge-base/*.md and emit
# filename<TAB>owner<TAB>presence rows for each template using the §2.2 ownership map.
# Called by resolve_doc_set when discovery.doc_set is unset/empty.
#
# REPO must be set to the repository root before calling (or defaults to the CWD).
synth_default_seed() {
  local tmpl_dir="${REPO:-$(pwd)}/.github/aid/templates/knowledge-base"
  # Ownership map: pairs of "filename owner" (no commas, no pipes — safe for IFS split)
  # This is the §2.2 single source; edit here to change the default ownership.
  # Concern annotations follow concern-model.md (documentation only -- NOT a 4th field;
  # the emitted TSV stays filename<TAB>owner<TAB>presence with no change to parsing).
  # Each concern comment is a standalone bash comment line before its entry.
  local -a MAP=(
    # C1 Build & shape
    "project-structure.md    aid-researcher-scout"
    # orientation (cross-cutting, not a newcomer concern; kb-category: primary, not meta)
    "external-sources.md     aid-researcher-scout"
    # C1 Build & shape
    "architecture.md         aid-researcher-architecture"
    # C0 Technology
    "technology-stack.md     aid-researcher-architecture"
    # C2 Parts & connections
    "module-map.md           aid-researcher-analyst"
    # C3 Conventions
    "coding-standards.md     aid-researcher-analyst"
    # C5 Data & contracts
    "schemas.md              aid-researcher-analyst"
    # C2 Parts & connections
    "pipeline-contracts.md   aid-researcher-integrator"
    # C2 Parts & connections
    "integration-map.md      aid-researcher-integrator"
    # C4 Vocabulary / concept spine
    "domain-glossary.md      aid-researcher-integrator"
    # C6 Quality & testing
    "test-landscape.md       aid-researcher-quality"
    # C7 Risk & debt
    "tech-debt.md            aid-researcher-quality"
    # C8 Shipping & operation
    "infrastructure.md       aid-researcher-quality"
    # C9 What it does for users
    "feature-inventory.md    skill-self"
    # orientation (cross-cutting; skill-self-generated)
    "README.md               skill-self"
  )
  local entry fn owner
  for entry in "${MAP[@]}"; do
    read -r fn owner <<<"$entry"
    # Emit only templates that exist on disk (guards against future template removals).
    if [ -f "$tmpl_dir/$fn" ]; then
      printf '%s\t%s\t%s\n' "$fn" "$owner" "required"
    fi
  done
}
```

---

## Dimension recovery

`discovery.doc_set` and `synth_default_seed` remain **three-field** (`filename | owner |
presence`).  The spine-dimension column present in `domain-doc-matrix.md` is **dropped**
when a row is materialized into the TSV -- it is documentation, not machine state, and is
"recoverable from this matrix or `concern-model.md`" (per the matrix schema note).

A consumer that needs a doc's spine dimension (e.g. `kb-actback-task.sh`'s
operational-structure presence check, FR-53) **resolves it via a shipped
`filename -> spine-dimension` map** (`_dim_of_filename` in `kb-actback-task.sh`), whose
entries are sourced from `domain-doc-matrix.md` (the matrix is the authority; the map is
a rendered view kept lockstep with it, analogous to the seed-consistency guard).

**The TSV wire format is UNCHANGED** -- all four accessors and every consumer continue to
read three-field TSV rows.  The dimension is NOT a fourth field, NOT persisted in
`discovery.doc_set`, and NOT added to `synth_default_seed`.

**Unknown/custom filenames** (a project-renamed split like `module-map-frontend.md`, or an
`auto-researched` doc) return `""` from `_dim_of_filename`.  A `""` dimension means the
doc contributes no owning-table rows to the presence check (safe degradation: no false
`absent` for a doc whose dimension the map cannot prove) while the opt-in auto-detect
branch still reports any section physically present.  Carrying the dimension for arbitrary
custom docs is a follow-up enhancement; the shipped map covers all curated-row filenames
(the FR-53 target).

---

## `resolve_doc_set` — Split the declared set into TSV rows

Reads the comma-joined output of `read-setting.sh --path discovery.doc_set`, splits on `,`
then on `|`, and emits one `filename<TAB>owner<TAB>presence` row per item. When the raw input is
empty (section unset), delegates to `synth_default_seed`.

```bash
# resolve_doc_set — echoes: filename<TAB>owner<TAB>presence  per line
#
# Usage:
#   raw="$(bash "$REPO/canonical/scripts/config/read-setting.sh" \
#           --path discovery.doc_set 2>/dev/null || true)"
#   resolve_doc_set "$raw"
#
# When raw is empty (section unset / exit-1), synthesizes the default seed.
# Malformed records (missing filename or owner) are warned and skipped.
# Unknown owners are routed to aid-researcher-architecture with a non-fatal warning (FR-P1-5).
resolve_doc_set() {
  local raw="$1" item fn owner pres rest
  # Empty raw → section unset → synthesize default seed (backward-compat, FR-P1-2)
  if [ -z "$raw" ]; then synth_default_seed; return; fi

  local IFS=','
  for item in $raw; do
    IFS='|' read -r fn owner pres rest <<<"$item"
    # Malformed-record guard (delimiter constraint, §1.2):
    # A comma in a `when` hint shreds one record across the comma-join/comma-split round-trip:
    #   fragment 1  (e.g. `infrastructure.md|aid-researcher-quality|conditional:has CI`)
    #     → KEEPS its filename+owner → PASSES this guard → resolves to a VALID owner;
    #       its `when` hint is silently truncated (display-only, never machine-evaluated).
    #   fragments 2+ (e.g. `[ CD]`, `[ or deploy config]`)
    #     → carry no `|` → owner/pres are empty → CAUGHT here → warned + skipped.
    # The guard therefore does NOT reject fragment 1. The residual effect is a cosmetically
    # shortened `when`, which is benign. The grammar (§1.2) forbids commas outright; this
    # guard is defense-in-depth for the malformed fragments 2+ only.
    if [ -z "$fn" ] || [ -z "$owner" ]; then
      printf 'warn: malformed doc_set record %q (missing field — comma in a value? commas are forbidden per §1.2) → skipped\n' \
        "$item" >&2
      continue
    fi
    pres="${pres:-required}"
    # Owner-enum validation with aid-researcher-architecture fallback (FR-P1-5).
    case "$owner" in
      aid-researcher-scout|aid-researcher-architecture|aid-researcher-analyst|\
      aid-researcher-integrator|aid-researcher-quality|skill-self) ;;
      *) printf 'warn: unknown owner %s for %s → aid-researcher-architecture\n' \
           "$owner" "$fn" >&2
         owner='aid-researcher-architecture' ;;
    esac
    printf '%s\t%s\t%s\n' "$fn" "$owner" "$pres"
  done
}
```

---

## The 4 Accessors

All accessors derive from `resolve_doc_set`. Callers must have `raw` set (see usage above).

### list-filenames

Returns every declared filename, one per line. Emits the full default seed when the section is
unset.

```bash
resolve_doc_set "$raw" | cut -f1
```

### owner-of `<filename>`

Returns the owning agent for a specific filename (empty if not in the set).

```bash
resolve_doc_set "$raw" | awk -F'\t' -v f="$fn" '$1==f{print $2}'
```

### owns-`<agent>` (inverse — "what does this agent generate in THIS project?")

Returns all filenames assigned to the given agent in this project's declared set.

```bash
resolve_doc_set "$raw" | awk -F'\t' -v a="$agent" '$2==a{print $1}'
```

### resolve (full TSV)

Returns all `filename<TAB>owner<TAB>presence` rows. This is the `resolve_doc_set` output itself.

```bash
resolve_doc_set "$raw"
```

---

## `list_reviewable` — the reviewed knowledge surface (keystone gates)

The four accessors above resolve the *declared* doc-set (from `discovery.settings`). The
**reviewed knowledge surface** is a different thing: the set of KB docs on disk that a
reviewer should treat as *hand-authored project knowledge*. It is used by the M3 (Essence /
teach-back) and M4 (Assertiveness / act-back) keystone gates in `state-review.md`, which must
NOT ingest process/ledger or generated files.

`list_reviewable` globs `.aid/knowledge/*.md` and keeps only docs whose frontmatter is
**hand-authored knowledge** — `kb-category != meta` AND `source != generated`. This
deterministically excludes:
- the process/ledger docs (`STATE.md`, `README.md` — `kb-category: meta`), and
- generated docs (`INDEX.md` — `source: generated`).

It is **tag-driven** (reads each doc's own frontmatter), so it needs no hardcoded filename
list and adapts automatically if a doc's `kb-category`/`source` is corrected. A doc with no
frontmatter (or no `kb-category`/`source`) defaults to *reviewable* — the surface never
silently shrinks below the primary docs. One batched `awk` pass (no per-file spawn); portable
(no `nextfile`/`ENDFILE`); `LC_ALL=C` for deterministic ordering.

```bash
# list_reviewable [kb_dir] — echoes the reviewed-knowledge doc paths, one per line, sorted.
# Default kb_dir = .aid/knowledge. Keeps kb-category != meta AND source != generated.
list_reviewable() {
  local kb_dir="${1:-.aid/knowledge}"
  LC_ALL=C awk '
    FNR==1 { seen[FILENAME]=1; cat[FILENAME]=""; src[FILENAME]=""; fm[FILENAME]=0; done_[FILENAME]=0 }
    !done_[FILENAME] && /^---[[:space:]]*$/ { fm[FILENAME]++; if (fm[FILENAME]>=2) done_[FILENAME]=1; next }
    !done_[FILENAME] && fm[FILENAME]==1 && /^kb-category:/ { v=$0; sub(/^kb-category:[[:space:]]*/,"",v); sub(/[[:space:]]+$/,"",v); cat[FILENAME]=v }
    !done_[FILENAME] && fm[FILENAME]==1 && /^source:/      { v=$0; sub(/^source:[[:space:]]*/,"",v);      sub(/[[:space:]]+$/,"",v); src[FILENAME]=v }
    END { for (f in seen) if (cat[f] != "meta" && src[f] != "generated") print f }
  ' "$kb_dir"/*.md 2>/dev/null | LC_ALL=C sort
}
```

> **Two exclusion mechanisms, one intent.** M1 (Correctness) and M2 (Anatomy) already
> *route by* `kb-category` (a `meta` doc gets only a Spot-Check Snapshot, not the full graded
> checklist). `list_reviewable` extends the same intent to the M3/M4 keystone gates, which
> otherwise read a raw `.aid/knowledge/*.md` glob and would ingest `STATE.md`/`README.md` as
> if they were knowledge. Keystone gates force grade ≤ D, so leaking ledger text there is the
> highest-impact contamination — `list_reviewable` closes it deterministically.

---

## Usage pattern

```bash
# 1. Read the declared set (returns comma-joined items, or empty if section unset).
raw="$(bash "$REPO/.github/aid/scripts/config/read-setting.sh" \
        --path discovery.doc_set 2>/dev/null || true)"

# 2. Resolve to TSV rows (default seed if unset).
#    REPO must be set before calling synth_default_seed (called internally when raw is empty).
tsv="$(resolve_doc_set "$raw")"

# 3. Use the accessors.
filenames="$(echo "$tsv" | cut -f1)"
owner_of_arch="$(echo "$tsv" | awk -F'\t' -v f="architecture.md" '$1==f{print $2}')"
analyst_files="$(echo "$tsv" | awk -F'\t' -v a="aid-researcher-analyst" '$2==a{print $1}')"
```

> **Implementation constraint:** This snippet is pure bash+awk over the existing
> `read-setting.sh`. No new script, no `yq`, no `python`. The `resolve_doc_set` and
> `synth_default_seed` functions are inlined into the caller (state-generate.md, state-review.md,
> or any state that needs them) rather than living in a standalone script under
> `.github/aid/scripts/kb/`.

---

## Propose->confirm flow (concern model)

The default seed (`synth_default_seed`) is the **deterministic fallback** when no
`discovery.doc_set` override exists. The **concern model** (see
`.github/aid/templates/kb-authoring/concern-model.md`) adds an adaptivity layer above
it: during the recon/triage phase, `aid-discover` walks the 10 universal concerns (C0,
C1-C9) and for each concern proposes the default doc(s), a split, a project-specific
addition, or `conditional`. The proposal is written into `discovery.doc_set` (this schema)
and confirmed by the user.

**Three proposal variants:**

- **Split a large concern** -- propose multiple `discovery.doc_set` rows for the same
  concern when one doc would be oversized (e.g. `module-map-frontend.md` +
  `module-map-backend.md` for a monorepo's C2). Each row carries `conditional:<when>`.
- **Add a project-specific doc** -- propose a new row mapped to the nearest concern when
  the project has a concern-relevant area no seed doc covers (e.g. `ml-pipeline.md`
  under C2/C5 for a data project).
- **Mark conditional / drop** -- propose `conditional` for a concern whose default doc
  does not apply (e.g. `infrastructure.md`/C8 for a library with no deployment).

**Invariant:** the fallback path is untouched. A project that accepts the defaults (or
never runs the propose step) gets `synth_default_seed`'s 15 docs exactly as before.
Adaptivity is opt-in via the human-confirmed gate, never forced. The concern is the stable
spine; the docs are derived per project -- every concern must be covered by at least one
confirmed doc.

`repo-presentation.md` is a **conditional extension example** -- NOT a default seed doc.
A project MAY add it under C9 (capabilities / user-facing presentation) via this gate.
It never appears in `synth_default_seed`.
