#!/usr/bin/env bash
# kb-freshness-check.sh -- deterministic per-doc staleness check for KB docs.
#
# For each hand-authored primary/extension KB doc, reads its sources: and
# approved_at_commit: frontmatter fields (f001 schema) and determines whether
# any LOCAL-FILE source has changed in git since the doc was last approved.
#
# Algorithm (per doc, per f007 SPEC):
#   1. Absence gate:
#      - approved_at_commit: absent/empty -> verdict=unknown (never suspect on
#        missing baseline; pre-migration docs are acceptable).
#      - sources: absent or [] -> verdict=current (nothing to drift against).
#   2. Per-source last-changed commit:
#      - URL (^[a-z][a-z0-9+.-]*://) -> source verdict=unknown (cannot git log a URL).
#      - Path/glob (repo-relative) -> git log -1 --format=%H -- <entry>;
#        empty output -> source verdict=unknown (untracked file).
#   3. Compare: for each source commit C_src, run:
#        git merge-base --is-ancestor C_src <approved_at_commit>
#      exit 0 = ancestor/equal -> source CURRENT
#      exit 1 = NOT ancestor -> source SUSPECT
#      any other exit (e.g. 128, unknown commit) -> source UNKNOWN (never a false suspect)
#   4. Fold rule:
#      - SUSPECT if any source is suspect
#      - else CURRENT if >=1 source is current and no suspect
#      - else UNKNOWN
#
# Skip routing (mirrors build-kb-index.sh / lint-frontmatter.sh):
#   - Skip kb-category: meta docs
#   - Skip source: generated docs
#   - Skip INDEX.md, README.md, STATE.md by name (meta docs)
#   - Only check source: hand-authored primary/extension docs
#
# Output (--format tsv, one row per doc):
#   <doc-relpath>\t<verdict>\t<approved_at_commit>\t<n_current>\t<n_suspect>\t<n_unknown>\t<suspect_sources_csv>
#   verdict in {current, suspect, unknown}
#   suspect_sources_csv: comma-separated drifted source entries (empty unless suspect)
#
# Exit codes:
#   0 -- successful scan (suspect is a normal verdict, not an error)
#   1 -- argument error
#   2 -- I/O error
#
# Read-only: no file writes. stdout only.
#
# Usage:
#   bash kb-freshness-check.sh --root <kb-root> [--repo <repo-root>]
#                               [--format text|tsv] [--doc <relpath>]
#
# Defaults:
#   --root: .aid/knowledge/
#   --repo: git toplevel containing --root
#   --format: text

set -eu

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
ROOT=".aid/knowledge"
REPO=""
FORMAT="text"
DOC_FILTER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)   ROOT="$2";       shift 2 ;;
        --repo)   REPO="$2";       shift 2 ;;
        --format) FORMAT="$2";     shift 2 ;;
        --doc)    DOC_FILTER="$2"; shift 2 ;;
        -h|--help)
            cat <<'HELP_EOF'
kb-freshness-check.sh -- deterministic per-doc staleness check for KB docs.

For each hand-authored primary/extension KB doc, reads sources: and
approved_at_commit: from YAML frontmatter and checks whether any local-file
source has changed in git since the doc was approved.

Algorithm (per f007 SPEC):
  - absent approved_at_commit: -> unknown (never suspect on missing baseline)
  - absent/empty sources: -> current (nothing to drift against)
  - URL source -> source unknown (cannot git log a URL)
  - path/glob source -> git log -1 --format=%H -- <entry>; empty -> unknown
  - comparison via git merge-base --is-ancestor C_src <approved_at_commit>
  - fold: suspect if any source suspect; current if >=1 current+no suspect; else unknown

Usage:
  bash kb-freshness-check.sh --root <kb-root> [--repo <repo-root>]
                              [--format text|tsv] [--doc <relpath>]

Options:
  --root    KB root directory (default: .aid/knowledge/)
  --repo    Repo root for resolving sources: paths (default: git toplevel of --root)
  --format  Output format: text (default) or tsv
  --doc     Check only this doc (repo-relative path under --root)

TSV columns (stable order):
  doc-relpath, verdict, approved_at_commit, n_current, n_suspect, n_unknown, suspect_sources_csv

Exit codes:
  0  successful scan (suspect is a normal verdict)
  1  argument error
  2  I/O error
HELP_EOF
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# Validate format
case "$FORMAT" in
    text|tsv) ;;
    *)
        echo "--format must be 'text' or 'tsv'" >&2
        exit 1
        ;;
esac

# Resolve ROOT to absolute path
[[ -d "$ROOT" ]] || { echo "Root not a directory: $ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd)"

# Resolve REPO: default to git toplevel containing ROOT
if [[ -z "$REPO" ]]; then
    REPO="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)" || {
        echo "Cannot determine git repo root from --root $ROOT" >&2
        exit 2
    }
fi
[[ -d "$REPO" ]] || { echo "Repo not a directory: $REPO" >&2; exit 2; }
REPO="$(cd "$REPO" && pwd)"

# ---------------------------------------------------------------------------
# Frontmatter extraction helpers (awk-based, deterministic, no perl/python)
# ---------------------------------------------------------------------------

# Extract a single-line scalar YAML field from frontmatter.
# Args: <file> <field-name>
# Output: the trimmed value, or empty string if absent.
fm_scalar() {
    local f="$1" field="$2"
    awk -v field="$field" '
        BEGIN { in_fm=0 }
        /^---$/ { in_fm = !in_fm; if (NR > 1 && !in_fm) exit; next }
        in_fm && $0 ~ "^"field":" {
            sub("^"field":[[:space:]]*", "")
            # trim trailing whitespace
            sub(/[[:space:]]+$/, "")
            print
            exit
        }
    ' "$f"
}

# Extract YAML list field items, one per line.
# Handles both inline [a, b] and block (- a\n  - b) and empty [].
# Args: <file> <field-name>
# Output: items one per line; empty output if absent or empty list.
fm_list() {
    local f="$1" field="$2"
    awk -v field="$field" '
        BEGIN { in_fm=0; in_field=0 }
        /^---$/ {
            in_fm = !in_fm
            if (NR > 1 && !in_fm) exit
            next
        }
        in_fm && in_field {
            # Block list item
            if (/^[[:space:]]+-[[:space:]]/ || /^[[:space:]]+-$/) {
                item = $0
                sub(/^[[:space:]]+-[[:space:]]*/, "", item)
                sub(/[[:space:]]+$/, "", item)
                if (item != "") print item
                next
            }
            # Next top-level key or end of block
            exit
        }
        in_fm && $0 ~ "^"field":" {
            rest = $0
            sub("^"field":[[:space:]]*", "", rest)
            if (rest ~ /^\[\]/) {
                # Empty inline list -- emit nothing
                exit
            } else if (rest ~ /^\[/) {
                # Inline list: [a, b, c]
                inner = rest
                sub(/^\[/, "", inner)
                sub(/\][[:space:]]*$/, "", inner)
                if (inner == "") { exit }
                n = split(inner, items, /[[:space:]]*,[[:space:]]*/)
                for (i = 1; i <= n; i++) {
                    item = items[i]
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", item)
                    gsub(/^['"'"'"]|['"'"'"]$/, "", item)
                    if (item != "") print item
                }
                exit
            } else if (rest ~ /^[[:space:]]*$/) {
                # Block list -- read following lines
                in_field = 1
                next
            }
            # Scalar (not a list) -- no output
            exit
        }
    ' "$f"
}

# Check whether a sources: field is present (regardless of value).
# Returns 1 if the field line exists (even as sources: []), 0 if absent.
fm_sources_present() {
    local f="$1"
    awk '
        BEGIN { in_fm=0; found=0 }
        /^---$/ { in_fm = !in_fm; if (NR > 1 && !in_fm) exit; next }
        in_fm && /^sources:/ { found=1; exit }
        END { if (found) print "1" }
    ' "$f"
}

# ---------------------------------------------------------------------------
# URL detector: matches scheme://... (per f007 SPEC)
# ---------------------------------------------------------------------------
is_url() {
    # Matches: one or more lowercase alpha, then any of [a-z0-9+.-], then ://
    # e.g. http://, https://, ftp://, git+ssh://, etc.
    # Called only from inside an 'if' guard, so set -e does not apply.
    echo "$1" | grep -qE '^[a-z][a-z0-9+.-]*://'
}

# ---------------------------------------------------------------------------
# Per-source staleness check
# Returns one of: current  suspect  unknown
# ---------------------------------------------------------------------------
check_source() {
    local entry="$1" approval_commit="$2"

    # URL source -> unknown (cannot git log a URL)
    if is_url "$entry"; then
        echo "unknown"
        return
    fi

    # Path/glob source: get last-changed commit via git log
    local c_src
    c_src="$(LC_ALL=C git -C "$REPO" log -1 --format="%H" -- "$entry" 2>/dev/null || true)"
    c_src="$(echo "$c_src" | tr -d '[:space:]')"

    if [[ -z "$c_src" ]]; then
        # Empty output: file untracked or pathspec matched nothing -> unknown
        echo "unknown"
        return
    fi

    # Compare: is C_src an ancestor of (or equal to) approved_at_commit?
    # exit 0 = ancestor/equal = source unchanged since approval -> current
    # exit 1 = NOT ancestor = source changed after approval -> suspect
    # other exit (128 = bad object, etc.) = unknown (never a false suspect)
    # Use || true to prevent set -e from aborting on non-zero exit.
    local rc=0
    LC_ALL=C git -C "$REPO" merge-base --is-ancestor "$c_src" "$approval_commit" \
        2>/dev/null || rc=$?
    if [[ $rc -eq 0 ]]; then
        echo "current"
    elif [[ $rc -eq 1 ]]; then
        echo "suspect"
    else
        # Any unexpected exit code (bad object, etc.) -> safe fallback
        echo "unknown"
    fi
}

# ---------------------------------------------------------------------------
# Check a single doc; emit one row to stdout.
# ---------------------------------------------------------------------------
check_doc() {
    local f="$1" rel="$2"

    # --- Frontmatter extraction ---
    local approval
    approval="$(fm_scalar "$f" "approved_at_commit")"

    # Absence gate: missing/empty approved_at_commit -> unknown
    if [[ -z "$approval" ]]; then
        if [[ "$FORMAT" == "tsv" ]]; then
            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$rel" "unknown" "" "0" "0" "0" ""
        else
            printf '%-50s  %-8s  (no approved_at_commit)\n' "$rel" "unknown"
        fi
        return
    fi

    # Check if sources: field is present at all (including empty [])
    local sources_present
    sources_present="$(fm_sources_present "$f")"

    if [[ -z "$sources_present" ]]; then
        # sources: field absent -> current (nothing to drift against)
        if [[ "$FORMAT" == "tsv" ]]; then
            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$rel" "current" "$approval" "0" "0" "0" ""
        else
            printf '%-50s  %-8s  %s  (sources: absent -> current)\n' \
                "$rel" "current" "$approval"
        fi
        return
    fi

    # Extract sources list
    local sources_raw
    sources_raw="$(fm_list "$f" "sources")"

    if [[ -z "$sources_raw" ]]; then
        # sources: [] (empty list) -> current
        if [[ "$FORMAT" == "tsv" ]]; then
            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$rel" "current" "$approval" "0" "0" "0" ""
        else
            printf '%-50s  %-8s  %s  (sources: [] -> current)\n' \
                "$rel" "current" "$approval"
        fi
        return
    fi

    # Per-source checks
    local n_current=0 n_suspect=0 n_unknown=0
    local suspect_list=""

    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        local src_verdict
        src_verdict="$(check_source "$entry" "$approval")"
        case "$src_verdict" in
            current) n_current=$((n_current + 1)) ;;
            suspect)
                n_suspect=$((n_suspect + 1))
                if [[ -z "$suspect_list" ]]; then
                    suspect_list="$entry"
                else
                    suspect_list="${suspect_list},${entry}"
                fi
                ;;
            unknown) n_unknown=$((n_unknown + 1)) ;;
        esac
    done <<< "$sources_raw"

    # Fold rule
    local verdict
    if [[ $n_suspect -gt 0 ]]; then
        verdict="suspect"
    elif [[ $n_current -gt 0 ]]; then
        verdict="current"
    else
        verdict="unknown"
    fi

    if [[ "$FORMAT" == "tsv" ]]; then
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$rel" "$verdict" "$approval" \
            "$n_current" "$n_suspect" "$n_unknown" \
            "$suspect_list"
    else
        local detail=""
        [[ $n_suspect -gt 0 ]] && detail="  SUSPECT: $suspect_list"
        printf '%-50s  %-8s  %s  current=%d suspect=%d unknown=%d%s\n' \
            "$rel" "$verdict" "$approval" \
            "$n_current" "$n_suspect" "$n_unknown" \
            "$detail"
    fi
}

# ---------------------------------------------------------------------------
# Doc routing (mirrors build-kb-index.sh / lint-frontmatter.sh)
# Skip: meta, generated, INDEX.md, README.md, STATE.md
# Check: source: hand-authored, kb-category in {primary, extension}
# ---------------------------------------------------------------------------
should_check() {
    local f="$1"
    local name
    name="$(basename "$f")"

    # Always-skipped by name
    case "$name" in
        INDEX.md|README.md|STATE.md) return 1 ;;
    esac

    local cat src
    cat="$(fm_scalar "$f" "kb-category")"
    cat="${cat:-primary}"
    src="$(fm_scalar "$f" "source")"
    src="${src:-hand-authored}"

    # Skip meta and generated
    [[ "$cat" == "meta" ]] && return 1
    [[ "$src" == "generated" ]] && return 1

    # Only primary and extension with hand-authored (or absent) source
    case "$cat" in
        primary|extension) return 0 ;;
        *) return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Main: collect docs, sort, emit header (text only), check each doc
# ---------------------------------------------------------------------------

if [[ "$FORMAT" == "text" ]]; then
    printf '%-50s  %-8s  %s\n' "DOC" "VERDICT" "APPROVED_AT / DETAIL"
    printf '%s\n' "$(printf '%.0s-' {1..90})"
fi

# Collect docs: sorted by path for determinism (matches build-kb-index.sh)
declare -a docs=()

if [[ -n "$DOC_FILTER" ]]; then
    # Single-doc mode
    target="${ROOT}/${DOC_FILTER}"
    if [[ ! -f "$target" ]]; then
        echo "Doc not found: $target" >&2
        exit 2
    fi
    docs+=("$target")
else
    while IFS= read -r f; do
        docs+=("$f")
    done < <(LC_ALL=C find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*' | LC_ALL=C sort)
fi

for f in "${docs[@]}"; do
    should_check "$f" || continue

    # Compute relative path (strip ROOT prefix + leading slash)
    rel="${f#"$ROOT/"}"

    check_doc "$f" "$rel"
done

exit 0
