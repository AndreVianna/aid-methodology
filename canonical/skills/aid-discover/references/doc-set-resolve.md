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
deterministically from `canonical/templates/knowledge-base/*.md` paired to the ownership map
below. This satisfies FR-P0-4 (no hardcoded doc-count/doc-list literal) by making the default
set self-describing from the templates that exist on disk.

### Ownership map (§2.2 single source of truth)

| Template file | Owner |
|---|---|
| `project-structure.md` | `aid-researcher-scout` |
| `external-sources.md` | `aid-researcher-scout` |
| `architecture.md` | `aid-researcher-architecture` |
| `technology-stack.md` | `aid-researcher-architecture` |
| `module-map.md` | `aid-researcher-analyst` |
| `coding-standards.md` | `aid-researcher-analyst` |
| `schemas.md` | `aid-researcher-analyst` |
| `pipeline-contracts.md` | `aid-researcher-integrator` |
| `integration-map.md` | `aid-researcher-integrator` |
| `domain-glossary.md` | `aid-researcher-integrator` |
| `test-landscape.md` | `aid-researcher-quality` |
| `tech-debt.md` | `aid-researcher-quality` |
| `infrastructure.md` | `aid-researcher-quality` |
| `feature-inventory.md` | `skill-self` |
| `README.md` | `skill-self` |

`INDEX.md` is generated meta-only (not a KB-template artifact); it is owned by `skill-self`
and not synthesized from templates. (The `skill-self` owner value denotes the skill itself — not a dispatched agent.)

```bash
# synth_default_seed — enumerate canonical/templates/knowledge-base/*.md and emit
# filename<TAB>owner<TAB>presence rows for each template using the §2.2 ownership map.
# Called by resolve_doc_set when discovery.doc_set is unset/empty.
#
# REPO must be set to the repository root before calling (or defaults to the CWD).
synth_default_seed() {
  local tmpl_dir="${REPO:-$(pwd)}/canonical/aid/templates/knowledge-base"
  # Ownership map: pairs of "filename owner" (no commas, no pipes — safe for IFS split)
  # This is the §2.2 single source; edit here to change the default ownership.
  local -a MAP=(
    "project-structure.md    aid-researcher-scout"
    "external-sources.md     aid-researcher-scout"
    "architecture.md         aid-researcher-architecture"
    "technology-stack.md     aid-researcher-architecture"
    "module-map.md           aid-researcher-analyst"
    "coding-standards.md     aid-researcher-analyst"
    "schemas.md              aid-researcher-analyst"
    "pipeline-contracts.md   aid-researcher-integrator"
    "integration-map.md      aid-researcher-integrator"
    "domain-glossary.md      aid-researcher-integrator"
    "test-landscape.md       aid-researcher-quality"
    "tech-debt.md            aid-researcher-quality"
    "infrastructure.md       aid-researcher-quality"
    "feature-inventory.md    skill-self"
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

## Usage pattern

```bash
# 1. Read the declared set (returns comma-joined items, or empty if section unset).
raw="$(bash "$REPO/canonical/scripts/config/read-setting.sh" \
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
> `canonical/scripts/kb/`.
