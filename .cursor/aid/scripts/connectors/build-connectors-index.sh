#!/usr/bin/env bash
# build-connectors-index.sh -- generate .aid/connectors/INDEX.md from connector
# descriptor frontmatter (feature-001 "Integration Store Placement and Schema"
# owns the frozen contract; feature-005 "Registry Persistence and Consumption"
# owns this builder and its regeneration -- work-002-external_sources).
#
# INDEX.md is the routing table between agents and the tool/integration
# registry under `.aid/connectors/`: an agent reaches it via the `## Connectors`
# context-file pointer (`@.aid/connectors/INDEX.md`), scans it to find a
# connector, then opens the specific `<connector>.md` descriptor. Each row is
# composed mechanically from that descriptor's frontmatter (name,
# connection_type, endpoint, auth_method, secret_reference, summary) -- the
# same dependency-free approach as
# canonical/aid/scripts/kb/build-kb-index.sh -- but this is a SEPARATE script
# with a SEPARATE contract:
#
#   - Columns: Connector | Type | Endpoint | Auth | Secret Ref | Summary.
#     Unlike the KB index, connection_type/endpoint/auth_method are columns in
#     their own right (an agent must see transport + auth at a glance).
#   - Secret Ref renders as an em dash when auth_method: none.
#   - NOT a KB doc: no `kb-category:`, no primary/meta/extension grouping (a
#     single flat table), no `../knowledge/` cross-links (descriptor links are
#     relative within `.aid/connectors/`).
#   - DETERMINISTIC -- unlike build-kb-index.sh, this script emits NO run
#     timestamp and NO dated changelog entry anywhere in its output (KI-010),
#     so two runs over an identical descriptor set are byte-identical. That
#     property is what feature-006's reconcile idempotence relies on.
#
# Triggered by feature-002 (author) and feature-006 (reconcile) after any
# descriptor add/update/remove; this script only builds
# the index, it does not decide when to run.
#
# Usage:
#   bash build-connectors-index.sh [--root <dir>] [--output <path>]
#   Defaults: --root .aid/connectors --output .aid/connectors/INDEX.md
#
# Zero descriptors (including a --root that does not exist yet) is NOT an
# error: the script writes a header-only INDEX.md (frontmatter + table header,
# zero rows) so the `@.aid/connectors/INDEX.md` context pointer never dangles.
#
# Exit codes:
#   0 - success (including the zero-descriptor case)
#   1 - argument error
#   2 - I/O error (output directory could not be created)

set -euo pipefail

SCRIPT_NAME="build-connectors-index.sh"
ROOT=".aid/connectors"
OUTPUT=".aid/connectors/INDEX.md"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            [[ $# -ge 2 ]] || { echo "${SCRIPT_NAME}: --root requires a value" >&2; exit 1; }
            ROOT="$2"; shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || { echo "${SCRIPT_NAME}: --output requires a value" >&2; exit 1; }
            OUTPUT="$2"; shift 2
            ;;
        -h|--help)
            cat <<'HELP_EOF'
build-connectors-index.sh -- generate .aid/connectors/INDEX.md from connector
descriptor frontmatter.

Composes the connectors routing table (Connector | Type | Endpoint | Auth |
Secret Ref | Summary) from each descriptor's frontmatter. DETERMINISTIC: no
run timestamp or dated field is ever emitted, so two runs over an identical
descriptor set produce a byte-identical INDEX.md.

Usage:
  bash build-connectors-index.sh [--root <dir>] [--output <path>]
  Defaults: --root .aid/connectors --output .aid/connectors/INDEX.md

Exit codes:
  0 - success (including zero descriptors -> header-only INDEX.md)
  1 - argument error
  2 - I/O error
HELP_EOF
            exit 0
            ;;
        *)
            echo "${SCRIPT_NAME}: unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

OUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUT_DIR" 2>/dev/null || { echo "${SCRIPT_NAME}: cannot create output dir: $OUT_DIR" >&2; exit 2; }

# Em dash used for Secret Ref when auth_method: none (feature-001 contract).
# Embedded literally -- this is a generated .md artifact, not shipped
# PowerShell, so the ASCII-only rule (coding-standards.md) does not apply here.
EMDASH="—"

# ---------------------------------------------------------------------------
# Per-descriptor render program (one awk subprocess per descriptor). Extracts
# the 6 frontmatter fields the INDEX.md contract needs and prints them
# tab-separated on one line. First-frontmatter-block scoping mirrors
# connector-registry.sh's read_field / build-kb-index.sh's extract_field: a
# body-level thematic-break `---` is never re-entered as frontmatter, so a
# decoy "field: value" line in the descriptor body is never read.
# ---------------------------------------------------------------------------
CIDX_AWK="$(mktemp)"
trap 'rm -f "$CIDX_AWK"' EXIT

cat > "$CIDX_AWK" <<'CIDX_AWK_EOF'
# --- ef: single-line YAML scalar from the FIRST frontmatter block, with one
#     pair of surrounding quotes stripped (same semantics as
#     connector-registry.sh's read_field).
function ef(field,   i, ln, in_fm) {
    in_fm = 0
    for (i = 1; i <= NL; i++) {
        ln = L[i]
        if (ln == "---") { in_fm = !in_fm; if (i > 1 && !in_fm) return ""; continue }
        if (in_fm && ln ~ ("^" field ":")) {
            sub("^" field ":[[:space:]]*", "", ln)
            sub("[[:space:]]+$", "", ln)
            gsub(/^["\047]|["\047]$/, "", ln)
            return ln
        }
    }
    return ""
}

# --- esc: escape a literal table-cell pipe so it cannot break the row.
function esc(s) { gsub(/\|/, "\\|", s); return s }

{ L[++NL] = $0 }

END {
    name     = ef("name");            if (name == "")     name = STEM
    ctype    = ef("connection_type"); if (ctype == "")    ctype = " "
    endpoint = ef("endpoint");        if (endpoint == "") endpoint = " "
    auth     = ef("auth_method")
    secref   = ef("secret_reference")
    summary  = ef("summary");         if (summary == "")  summary = " "

    auth_cell = (auth == "") ? " " : esc(auth)

    # Secret Ref: em dash when auth_method: none (feature-001 contract), or
    # when secret_reference is absent (malformed descriptor -- keep the table
    # well-formed rather than emit a blank cell).
    if (auth == "none" || secref == "") { secref_cell = EMDASH } else { secref_cell = esc(secref) }

    print esc(name) "\t" esc(ctype) "\t" esc(endpoint) "\t" auth_cell "\t" secref_cell "\t" esc(summary)
}
CIDX_AWK_EOF

# ---------------------------------------------------------------------------
# Collect descriptor files: same filter as connector-registry.sh `list` --
# *.md, excluding INDEX.md and dotfiles, sorted by filename (== by stem, since
# every descriptor lives directly under $ROOT). A non-existent $ROOT is NOT an
# error -- it is treated as zero descriptors, mirroring connector-registry.sh
# `list`'s own non-existent-root behavior (exit 0, empty).
# ---------------------------------------------------------------------------
declare -a DESCRIPTORS=()
if [[ -d "$ROOT" ]]; then
    while IFS= read -r f; do
        DESCRIPTORS+=("$f")
    done < <(find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name 'INDEX.md' ! -name '.*' | sort)
fi

# ---------------------------------------------------------------------------
# Compose the file. Frontmatter carries no dated/timestamped field (KI-010):
# source: generated / generator: / intent: / contracts: only (feature-001's
# frozen "own frontmatter" contract) -- no kb-category:, no changelog:. The
# body is title + single flat table only: feature-005 explicitly does not add
# a consumption-contract preamble here (that documentation lives in the
# `## Connectors` context-file section, not in this generated file).
# ---------------------------------------------------------------------------
{
    cat <<'FRONTMATTER_EOF'
---
source: generated
generator: build-connectors-index
intent: |
  Routing table for the tool/integration registry under .aid/connectors/,
  regenerated from connector descriptor frontmatter after any
  add/update/remove (feature-002 author, feature-006
  reconcile trigger this builder; feature-005 owns it). An agent reaches this
  file via the "## Connectors" context-file pointer, then opens the specific
  descriptor.
contracts:
  - "One row per connector descriptor under .aid/connectors/"
---

# Connectors Index

| Connector | Type | Endpoint | Auth | Secret Ref | Summary |
|-----------|------|----------|------|------------|---------|
FRONTMATTER_EOF

    for f in "${DESCRIPTORS[@]}"; do
        name="${f##*/}"
        stem="${name%.md}"
        row=$(awk -v STEM="$stem" -v EMDASH="$EMDASH" -f "$CIDX_AWK" "$f")
        IFS=$'\t' read -r r_name r_ctype r_endpoint r_auth r_secref r_summary <<< "$row"
        echo "| [${r_name}](${stem}.md) | ${r_ctype} | ${r_endpoint} | ${r_auth} | ${r_secref} | ${r_summary} |"
    done

} > "$OUTPUT"

SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
LINES=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "OK: Wrote $OUTPUT ($SIZE bytes, $LINES lines)"
