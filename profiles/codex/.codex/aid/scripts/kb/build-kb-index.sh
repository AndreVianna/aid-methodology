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
# source: value is a pass-through -- this generator groups docs strictly by
# kb-category (primary/meta/extension) and is source-value-agnostic. A
# forward-authored (f003 greenfield seed) doc with kb-category: primary renders
# in the Primary table identically to a hand-authored one. The INDEX 6-column
# schema (Document/Objective/Summary/Tags/See-instead/Audience) is unchanged.
#
# PERFORMANCE (work-007): the render is BATCHED -- one awk subprocess per doc
# instead of the former ~19. The previous doubled loop (3 categories x N docs)
# recomputed basename + kb-category 3x per doc, and its heavy branch spawned ~13
# awk/sed/tr helpers per doc (extract_field x2, extract_list x3, extract_literal,
# collapse_lines, first_sentence, escape_pipe, render_tags/see_also/audience). On
# Windows Git Bash / MSYS (~10-50 ms per fork) that dominated the run. Now basename
# is a shell builtin (${f##*/}, no spawn), kb-category is read once per doc, and a
# single awk pass parses every needed field AND renders all five middle cells for a
# doc. Each doc is rendered exactly once and cached, then the category grouping loop
# consults the cache. Output is byte-identical to the old pipeline.
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

Per .codex/aid/templates/kb-authoring/principles.md P3, this script runs LAST
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

# ---------------------------------------------------------------------------
# Per-doc render program (one awk subprocess per doc).
#
# This is a faithful, byte-for-byte port of the former shell helpers -- the
# whole frontmatter is read into L[1..NL] once, then each former helper runs as
# an awk function over that array (exit -> return, next -> continue, print ->
# accumulate). The END block applies the coexistence fallbacks and prints:
#
#     <kb-category>\n<obj_cell> | <sum_cell> | <tags_cell> | <see_cell> | <aud_cell>
#
# The caller wraps the second line with the Document link + outer pipes, exactly
# reproducing the old per-row `echo`. Ported helpers and their originals:
#   ef()               = extract_field   (single-line YAML scalar, first FM block)
#   el()               = extract_list    (inline [a,b] or block "- x")
#   literal_collapsed()= extract_literal | collapse_lines (intent: literal, joined)
#   first_sentence()   = first_sentence  (bounded [.!?] predicate, 200-char cap)
#   esc()              = escape_pipe      (sed s/|/\|/g)
#   render_tags/see_also/audience = the three render_* awk helpers
# ---------------------------------------------------------------------------
KBIDX_AWK="$(mktemp)"
trap 'rm -f "$KBIDX_AWK"' EXIT

cat > "$KBIDX_AWK" <<'KBIDX_AWK_EOF'
# --- extract_field: single-line YAML scalar from the FIRST --- ... --- block.
function ef(field,   i, ln, in_fm) {
    in_fm = 0
    for (i = 1; i <= NL; i++) {
        ln = L[i]
        if (ln == "---") { in_fm = !in_fm; if (i > 1 && !in_fm) return ""; continue }
        if (in_fm && ln ~ ("^" field ":")) {
            sub("^" field ":[[:space:]]*", "", ln)
            return ln
        }
    }
    return ""
}

# --- extract_list: inline [a, b, c] or block "  - value"; fills arr[1..n], returns n.
function el(field, arr,   i, ln, in_fm, in_field, rest, inner, n, items, item, cnt, k) {
    in_fm = 0; in_field = 0; cnt = 0
    for (i = 1; i <= NL; i++) {
        ln = L[i]
        if (ln == "---") { in_fm = !in_fm; if (i > 1 && !in_fm) return cnt; continue }
        if (in_fm && in_field) {
            if (ln ~ /^[[:space:]]+-[[:space:]]/) {
                sub(/^[[:space:]]+-[[:space:]]+/, "", ln)
                sub(/[[:space:]]+$/, "", ln)
                arr[++cnt] = ln
                continue
            }
            return cnt
        }
        if (in_fm && ln ~ ("^" field ":")) {
            rest = ln
            sub("^" field ":[[:space:]]*", "", rest)
            if (rest ~ /^\[/) {
                inner = rest
                sub(/^\[/, "", inner)
                sub(/\][[:space:]]*$/, "", inner)
                if (inner == "") return cnt
                n = split(inner, items, /[[:space:]]*,[[:space:]]*/)
                for (k = 1; k <= n; k++) {
                    item = items[k]
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", item)
                    gsub(/^['"]|['"]$/, "", item)
                    if (item != "") arr[++cnt] = item
                }
                return cnt
            } else if (rest == "" || rest ~ /^[[:space:]]*$/) {
                in_field = 1
                continue
            }
            return cnt
        }
    }
    return cnt
}

# --- extract_literal(intent) piped through collapse_lines, in one pass.
function literal_collapsed(field,   i, ln, in_fm, in_field, indent, olines, nout, j, joined) {
    in_fm = 0; in_field = 0; indent = -1; nout = 0
    for (i = 1; i <= NL; i++) {
        ln = L[i]
        if (ln == "---") { in_fm = !in_fm; if (!in_fm) break; continue }
        if (in_fm && in_field) {
            # Determine indent on first content line
            if (indent == -1 && ln ~ /^[[:space:]]+/) {
                match(ln, /^[[:space:]]+/)
                indent = RLENGTH
            }
            # Stop at a line at lower indent (new field) or top-level
            if (ln ~ /^[^[:space:]-]/ || ln ~ /^[a-zA-Z][a-zA-Z0-9_-]*:/) break
            # Strip leading indent
            sub("^[[:space:]]{" indent "}", "", ln)
            olines[++nout] = ln
            continue
        }
        if (in_fm && ln ~ ("^" field ":[[:space:]]*\\|")) {
            in_field = 1
            continue
        }
    }
    # collapse_lines: tr '\n' ' ' (a space after EVERY line, incl. last) then
    # sed 's/  */ /g; s/^ //; s/ $//' (squeeze spaces, strip one leading/trailing).
    joined = ""
    for (j = 1; j <= nout; j++) joined = joined olines[j] " "
    gsub(/ +/, " ", joined)
    sub(/^ /, "", joined)
    sub(/ $/, "", joined)
    return joined
}

# --- escape_pipe: sed 's/|/\|/g'
function esc(s) { gsub(/\|/, "\\|", s); return s }

# --- first_sentence: first [.!?] followed by (whitespace+uppercase ASCII) or EOL;
#     200-char cap with ASCII "..." suffix.
function first_sentence(line,   result, n, i, c, next_c, j, after) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
    if (length(line) == 0) return ""
    result = line
    n = length(line)
    for (i = 1; i <= n; i++) {
        c = substr(line, i, 1)
        if (c == "." || c == "!" || c == "?") {
            if (i == n) { result = substr(line, 1, i); break }
            next_c = substr(line, i + 1, 1)
            if (next_c == " " || next_c == "\t") {
                j = i + 1
                while (j <= n && (substr(line, j, 1) == " " || substr(line, j, 1) == "\t")) j++
                if (j <= n) {
                    after = substr(line, j, 1)
                    if (after >= "A" && after <= "Z") { result = substr(line, 1, i); break }
                } else {
                    result = substr(line, 1, i); break
                }
            }
        }
    }
    if (length(result) > 200) result = substr(result, 1, 200) "..."
    return result
}

# --- render_tags: comma-joined inline-code.
function render_tags(a, n,   i, out, item) {
    out = ""
    for (i = 1; i <= n; i++) {
        item = a[i]
        gsub(/\|/, "\\|", item)
        if (i == 1) out = "`" item "`"
        else out = out ", `" item "`"
    }
    return out
}

# --- render_see_also: doc-name link (.md suffix OR bare token) or verbatim prose.
function render_see_also(a, n,   i, out, entry, cell) {
    out = ""
    for (i = 1; i <= n; i++) {
        entry = a[i]
        gsub(/\|/, "\\|", entry)
        if (entry ~ /\.md$/ || entry !~ / /) {
            cell = "[" entry "](../knowledge/" entry ")"
        } else {
            cell = entry
        }
        if (i == 1) out = cell
        else out = out ", " cell
    }
    return out
}

# --- render_audience: verbatim comma-joined labels.
function render_audience(a, n,   i, out, item) {
    out = ""
    for (i = 1; i <= n; i++) {
        item = a[i]
        gsub(/\|/, "\\|", item)
        if (i == 1) out = item
        else out = out ", " item
    }
    return out
}

{ L[++NL] = $0 }

END {
    cat = ef("kb-category")
    if (cat == "") cat = "primary"   # default if missing

    objective = ef("objective")
    summary   = ef("summary")
    ntags = el("tags", TAGS)
    nsee  = el("see_also", SEE)
    naud  = el("audience", AUD)

    # Collapse intent: literal to single line for fallback use
    intent_collapsed = ""
    if (objective == "" || summary == "")
        intent_collapsed = literal_collapsed("intent")

    # Objective: use objective: if present, else collapsed intent:, else marker
    if (objective != "")             obj_cell = esc(objective)
    else if (intent_collapsed != "") obj_cell = esc(intent_collapsed)
    else                             obj_cell = "*(no objective declared)*"

    # Summary: use summary: if present, else first sentence of collapsed intent:, else blank
    if (summary != "")               sum_cell = esc(summary)
    else if (intent_collapsed != "") sum_cell = esc(first_sentence(intent_collapsed))
    else                             sum_cell = ""

    # Tags: inline-code, comma-joined; blank when empty
    if (ntags > 0) { tags_cell = render_tags(TAGS, ntags) } else { tags_cell = "" }
    # See-instead: doc-name links or verbatim; blank when empty
    if (nsee > 0)  { see_cell  = render_see_also(SEE, nsee) } else { see_cell = "" }
    # Audience: verbatim comma-joined; blank when empty
    if (naud > 0)  { aud_cell  = render_audience(AUD, naud) } else { aud_cell = "" }

    # Empty cell renders as a single space (keeps table well-formed)
    if (obj_cell  == "") obj_cell  = " "
    if (sum_cell  == "") sum_cell  = " "
    if (tags_cell == "") tags_cell = " "
    if (see_cell  == "") see_cell  = " "
    if (aud_cell  == "") aud_cell  = " "

    print cat
    print obj_cell " | " sum_cell " | " tags_cell " | " see_cell " | " aud_cell
}
KBIDX_AWK_EOF

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

<!-- AUTO-GENERATED $TS by .codex/aid/scripts/kb/build-kb-index.sh -->
<!-- DO NOT EDIT - regenerate with: bash .codex/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md -->

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

    # --- Per-doc render pass: one awk subprocess per doc; result cached ---------
    # basename via ${f##*/} (no spawn); kb-category + all five cells come from the
    # single $KBIDX_AWK pass. doc_cat[i]/doc_row[i] parallel all_docs; the category
    # grouping loop below just replays the cache in the same order.
    declare -a doc_cat=()
    declare -a doc_row=()
    for f in "${all_docs[@]}"; do
        name="${f##*/}"
        rendered=$(awk -f "$KBIDX_AWK" "$f")
        cat_line="${rendered%%$'\n'*}"   # line 1: kb-category (default primary)
        cells="${rendered#*$'\n'}"       # line 2: obj | sum | tags | see | aud
        doc_cat+=("$cat_line")
        doc_row+=("| [${name}](../knowledge/${name}) | ${cells} |")
    done

    for category in primary meta extension; do
        emitted_header=0
        for i in "${!all_docs[@]}"; do
            if [[ "${doc_cat[$i]}" == "$category" ]]; then
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
                echo "${doc_row[$i]}"
            fi
        done
        # Add blank line after each category table (if any docs emitted)
        if [[ $emitted_header -eq 1 ]]; then
            echo ""
        fi
    done

    echo "---"
    echo ""
    echo "*To regenerate this index, run \`bash .codex/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md\`.*"

} > "$OUTPUT"

SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
LINES=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "OK: Wrote $OUTPUT ($SIZE bytes, $LINES lines)"
