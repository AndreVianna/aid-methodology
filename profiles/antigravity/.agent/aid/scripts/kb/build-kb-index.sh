#!/usr/bin/env bash
# build-kb-index.sh - generate .aid/knowledge/INDEX.md from KB doc frontmatter.
#
# INDEX.md is the RAG (Retrieval-Augmented Generation) routing table between agents
# and the KB: every agent task prompt carries INDEX.md so the agent knows what KB
# doc to load for what knowledge. It is composed mechanically from each KB doc's
# frontmatter fields (objective, summary, tags, see_also, audience -- with intent:
# coexistence fallbacks), so it stays deterministic, git-diffable, and dependency-
# free. See canonical/templates/kb-authoring/frontmatter-schema.md for the field
# schema (f001).
#
# Coexistence fallbacks (f002): objective falls back to collapsed intent: when
# objective: is absent; summary falls back to the first sentence of collapsed
# intent:; tags/see_also/audience blank when absent. Un-migrated intent:-only
# docs render a valid table row.
#
# Per canonical/templates/kb-authoring/principles.md P3, this script runs LAST in
# any /aid-discover cycle (after all hand-edits land), so the index reflects final
# state.
#
# Usage:
#   bash build-kb-index.sh --root <kb-root> --output <output-path>
#
# Exit codes:
#   0 - success
#   1 - argument error
#   2 - I/O error
#   3 - frontmatter parse error in input

set -eu

ROOT=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)   ROOT="$2";   shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        -h|--help)
            cat <<'HELP_EOF'
build-kb-index.sh - generate .aid/knowledge/INDEX.md from KB doc frontmatter.

Composes the RAG routing table from each KB doc's frontmatter fields.
INDEX.md is the agent-facing self-service map; every task prompt loads it.

Per .agent/aid/templates/kb-authoring/principles.md P3, this script runs LAST
in any /aid-discover cycle so the index reflects final state.

Usage:
  bash build-kb-index.sh --root <kb-root> --output <output-path>

Exit codes:
  0 - success
  1 - argument error
  2 - I/O error
  3 - frontmatter parse error in input
HELP_EOF
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

[[ -n "$ROOT" ]]   || { echo "--root is required" >&2; exit 1; }
[[ -n "$OUTPUT" ]] || { echo "--output is required" >&2; exit 1; }
[[ -d "$ROOT" ]]   || { echo "Root not a directory: $ROOT" >&2; exit 2; }

ROOT="$(cd "$ROOT" && pwd)"
OUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUT_DIR"

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Helper: extract a single-line YAML field value from frontmatter
# Args: <file> <field-name>
extract_field() {
    local f="$1" field="$2"
    # Only look inside the FIRST --- ... --- block.
    # Symmetric with extract_literal: exit when we leave that block, so a body-level
    # thematic-break `---` cannot re-enter "frontmatter mode" and surface body values.
    awk -v field="$field" '
        BEGIN { in_fm=0 }
        /^---$/ { in_fm = !in_fm; if (NR > 1 && !in_fm) exit; next }
        in_fm && $0 ~ "^"field":" {
            sub("^"field":[[:space:]]*", "")
            print
            exit
        }
    ' "$f"
}

# Helper: extract multi-line YAML literal (|) field
# Args: <file> <field-name>
extract_literal() {
    local f="$1" field="$2"
    awk -v field="$field" '
        BEGIN { in_fm=0; in_field=0; indent=-1 }
        /^---$/ { in_fm = !in_fm; if (!in_fm) exit; next }
        in_fm && in_field {
            # Determine indent on first content line
            if (indent == -1 && /^[[:space:]]+/) {
                match($0, /^[[:space:]]+/)
                indent = RLENGTH
            }
            # Stop when we see a line at lower indent (new field) or top-level
            if (/^[^[:space:]-]/ || /^[a-zA-Z][a-zA-Z0-9_-]*:/) {
                exit
            }
            # Strip leading indent
            sub("^[[:space:]]{" indent "}", "")
            print
            next
        }
        in_fm && $0 ~ "^"field":[[:space:]]*\\|" {
            in_field = 1
            next
        }
    ' "$f"
}

# Helper: extract a YAML list field from frontmatter - handles both inline and block forms.
# Inline:  tags: [a, b, c]
# Block:   tags:
#            - a
#            - b
# Returns items one per line (empty output when field is absent or list is empty).
# Args: <file> <field-name>
extract_list() {
    local f="$1" field="$2"
    awk -v field="$field" '
        BEGIN { in_fm=0; in_field=0 }
        /^---$/ {
            in_fm = !in_fm
            if (NR > 1 && !in_fm) exit
            next
        }
        in_fm && in_field {
            # Continuation: block list item "  - value"
            if (/^[[:space:]]+-[[:space:]]/) {
                sub(/^[[:space:]]+-[[:space:]]+/, "")
                # strip trailing whitespace
                sub(/[[:space:]]+$/, "")
                print
                next
            }
            # Next top-level field or end of block list
            exit
        }
        in_fm && $0 ~ "^"field":" {
            rest = $0
            sub("^"field":[[:space:]]*", "", rest)
            if (rest ~ /^\[/) {
                # Inline list: [a, b, c] or []
                inner = rest
                sub(/^\[/, "", inner)
                sub(/\][[:space:]]*$/, "", inner)
                if (inner == "") { exit }
                n = split(inner, items, /[[:space:]]*,[[:space:]]*/)
                for (i = 1; i <= n; i++) {
                    item = items[i]
                    # strip leading/trailing whitespace and optional quotes
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", item)
                    gsub(/^['\''"]|['\''"]$/, "", item)
                    if (item != "") print item
                }
                exit
            } else if (rest == "" || rest ~ /^[[:space:]]*$/) {
                # Block list - read following lines
                in_field = 1
                next
            }
            # Scalar (not a list) - produce no output
            exit
        }
    ' "$f"
}

# Helper: collapse a multi-line string to a single space-joined line.
# Joins lines with a single space and squeezes multiple spaces to one.
# Reads from stdin.
collapse_lines() {
    tr '\n' ' ' | sed 's/  */ /g; s/^ //; s/ $//'
}

# Helper: extract first sentence from a single-line string using the bounded predicate:
# first match of [.!?] immediately followed by (whitespace + uppercase ASCII) or end-of-string.
# Truncates at 200 chars with ASCII "..." if needed. Reads from stdin.
first_sentence() {
    awk '
    {
        line = $0
        # Remove leading/trailing whitespace
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        if (length(line) == 0) { next }

        # Find first sentence boundary: [.!?] followed by (space+uppercase or end)
        # We scan char by char looking for . ! ? and check what follows.
        found = 0
        result = line
        n = length(line)
        for (i = 1; i <= n; i++) {
            c = substr(line, i, 1)
            if (c == "." || c == "!" || c == "?") {
                # Check what follows
                if (i == n) {
                    # end of string - this is a boundary
                    result = substr(line, 1, i)
                    found = 1
                    break
                }
                # Check next char(s): must be whitespace then uppercase ASCII
                next_c = substr(line, i + 1, 1)
                if (next_c == " " || next_c == "\t") {
                    # Look past the whitespace for uppercase
                    j = i + 1
                    while (j <= n && (substr(line, j, 1) == " " || substr(line, j, 1) == "\t")) {
                        j++
                    }
                    if (j <= n) {
                        after = substr(line, j, 1)
                        if (after >= "A" && after <= "Z") {
                            result = substr(line, 1, i)
                            found = 1
                            break
                        }
                    } else {
                        # Only whitespace after terminator - treat as end
                        result = substr(line, 1, i)
                        found = 1
                        break
                    }
                }
            }
        }

        # Cap at 200 chars
        if (length(result) > 200) {
            result = substr(result, 1, 200) "..."
        }

        print result
    }
    '
}

# Helper: escape literal pipe characters in a cell value.
# Reads from stdin, writes escaped value to stdout.
escape_pipe() {
    sed 's/|/\\|/g'
}

# Helper: render a tags list (newline-separated items from extract_list) as
# comma-joined inline-code. Empty input -> empty output.
render_tags() {
    awk '
    BEGIN { first=1; out="" }
    { gsub(/\|/, "\\|"); if (first) { out="`"$0"`"; first=0 } else { out=out", `"$0"`" } }
    END { print out }
    '
}

# Helper: render a see_also list (newline-separated items from extract_list) as
# comma-joined doc-name links or verbatim prose. A .md entry or a bare token
# (no spaces, looks like a doc name) is rendered as a link; other entries verbatim.
render_see_also() {
    awk '
    BEGIN { first=1; out="" }
    {
        entry = $0
        gsub(/\|/, "\\|", entry)
        # Link if it ends in .md or contains no spaces (bare token)
        if (entry ~ /\.md$/ || entry !~ / /) {
            cell = "[" entry "](../knowledge/" entry ")"
        } else {
            cell = entry
        }
        if (first) { out=cell; first=0 } else { out=out", "cell }
    }
    END { print out }
    '
}

# Helper: render an audience list (newline-separated items from extract_list) as
# comma-joined verbatim labels. Empty input -> empty output.
render_audience() {
    awk '
    BEGIN { first=1; out="" }
    { gsub(/\|/, "\\|"); if (first) { out=$0; first=0 } else { out=out", "$0 } }
    END { print out }
    '
}

# --- Begin output -----------------------------------------------------------
{
    cat <<EOF
---
kb-category: primary
source: generated
generator: build-kb-index.sh
intent: |
  RAG routing table - every agent task prompt loads this file so the agent knows
  which KB doc to read for what knowledge. Each row carries Document, Objective,
  Summary, Tags, See-instead, and Audience columns composed from frontmatter.
  Regenerated on every /aid-discover cycle.
contracts:
  - "One entry per non-dot, non-recursive KB document under .aid/knowledge/"
changelog:
  - $(date -u +%Y-%m-%d): Generated
---

<!-- AUTO-GENERATED $TS by .agent/aid/scripts/kb/build-kb-index.sh -->
<!-- DO NOT EDIT - regenerate with: bash .agent/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md -->

# Knowledge Base Index

> Auto-generated by \`build-kb-index.sh\` from each doc's frontmatter fields.
> Do not edit by hand. Generated at: $TS.

Routing table: each row is a KB doc with Objective, Summary, Tags, See-instead, and Audience columns
composed mechanically from frontmatter. Use Objective+Tags to route to the right doc; See-instead
for negative routing (what NOT to use); Audience to filter by role.

EOF

    # Group output by kb-category
    declare -a all_docs=()

    while IFS= read -r f; do
        all_docs+=("$f")
    done < <(find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*' | sort)

    if [[ ${#all_docs[@]} -eq 0 ]]; then
        echo "*(no KB docs found at \`$ROOT\`)*"
        echo ""
    fi

    for category in primary meta extension; do
        emitted_header=0
        for f in "${all_docs[@]}"; do
            name=$(basename "$f")
            doc_cat=$(extract_field "$f" "kb-category")
            doc_cat=${doc_cat:-primary}   # default if missing

            if [[ "$doc_cat" == "$category" ]]; then
                if [[ $emitted_header -eq 0 ]]; then
                    case "$category" in
                        primary)   echo "## Primary - load-bearing knowledge" ;;
                        meta)      echo "## Meta - process / ledger (review-exempt)" ;;
                        extension) echo "## Extension - project-specific (outside the declared default seed)" ;;
                    esac
                    echo ""
                    echo "| Document | Objective | Summary | Tags | See-instead | Audience |"
                    echo "|----------|-----------|---------|------|-------------|----------|"
                    emitted_header=1
                fi

                # --- Field extraction ---
                objective=$(extract_field "$f" "objective")
                summary=$(extract_field "$f" "summary")
                tags_raw=$(extract_list "$f" "tags")
                see_also_raw=$(extract_list "$f" "see_also")
                audience_raw=$(extract_list "$f" "audience")

                # --- Coexistence fallbacks ---
                # Collapse intent: literal to single line for fallback use
                intent_collapsed=""
                if [[ -z "$objective" ]] || [[ -z "$summary" ]]; then
                    intent_collapsed=$(extract_literal "$f" "intent" | collapse_lines)
                fi

                # Objective: use objective: if present, else collapsed intent:, else marker
                if [[ -n "$objective" ]]; then
                    obj_cell=$(printf '%s' "$objective" | escape_pipe)
                elif [[ -n "$intent_collapsed" ]]; then
                    obj_cell=$(printf '%s' "$intent_collapsed" | escape_pipe)
                else
                    obj_cell="*(no objective declared)*"
                fi

                # Summary: use summary: if present, else first sentence of collapsed intent:, else blank
                if [[ -n "$summary" ]]; then
                    sum_cell=$(printf '%s' "$summary" | escape_pipe)
                elif [[ -n "$intent_collapsed" ]]; then
                    sum_cell=$(printf '%s' "$intent_collapsed" | first_sentence | escape_pipe)
                else
                    sum_cell=""
                fi

                # Tags: inline-code, comma-joined; blank when empty
                if [[ -n "$tags_raw" ]]; then
                    tags_cell=$(printf '%s\n' "$tags_raw" | render_tags)
                else
                    tags_cell=""
                fi

                # See-instead: doc-name links or verbatim; blank when empty
                if [[ -n "$see_also_raw" ]]; then
                    see_cell=$(printf '%s\n' "$see_also_raw" | render_see_also)
                else
                    see_cell=""
                fi

                # Audience: verbatim comma-joined; blank when empty
                if [[ -n "$audience_raw" ]]; then
                    aud_cell=$(printf '%s\n' "$audience_raw" | render_audience)
                else
                    aud_cell=""
                fi

                # Empty cell renders as a single space (keeps table well-formed)
                [[ -n "$obj_cell" ]] || obj_cell=" "
                [[ -n "$sum_cell" ]] || sum_cell=" "
                [[ -n "$tags_cell" ]] || tags_cell=" "
                [[ -n "$see_cell" ]] || see_cell=" "
                [[ -n "$aud_cell" ]] || aud_cell=" "

                echo "| [${name}](../knowledge/${name}) | ${obj_cell} | ${sum_cell} | ${tags_cell} | ${see_cell} | ${aud_cell} |"
            fi
        done
        # Add blank line after each category table (if any docs emitted)
        if [[ $emitted_header -eq 1 ]]; then
            echo ""
        fi
    done

    echo "---"
    echo ""
    echo "*To regenerate this index, run \`bash .agent/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md\`.*"

} > "$OUTPUT"

SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
LINES=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "OK: Wrote $OUTPUT ($SIZE bytes, $LINES lines)"
