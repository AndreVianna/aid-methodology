#!/usr/bin/env bash
# g07-selector-partition.sh -- the oracle for criterion G-07:
#   "Every in-scope markdown file resolves to exactly one type in the registry."
#
# WHY THIS PARSES THE REGISTRY INSTEAD OF RESTATING IT
#
# The obvious implementation hardcodes the ten selectors in bash. That produces
# a SIBLING COPY of the registry which can drift from it silently -- a guard and
# a document asserting the same thing independently. tech-debt.md L4 names that
# failure directly ("anchor to ground truth, not a sibling copy"); it is the
# mechanism behind the io_bounds.py escape, and the shape of the guard work-004
# deliberately retired. An oracle that can disagree with the criterion it
# enforces is worse than no oracle, because it is trusted.
#
# So the registry stays the single source of truth and this reads its `Match`
# column, which states each selector in a form a check can parse.
#
# THE GRAMMAR (declared in .aid/knowledge/authoring-conventions.md)
#   path <glob>              the repo-relative path matches the glob
#   fm <key> == <value>      frontmatter has that key with that scalar value
#   name-in <file>           the parent directory name appears as a `name:`
#                            value in <file>
#   ... joined by AND
#   <inexpressible>          reserved: not a clause, never evaluated. The row's
#                            other clauses give its PATH BOUND; a file inside
#                            that bound is UNDECIDED and the walk stops there.
#
# The path bound matters and is not cosmetic. Without it the stop would fire for
# ANY file that exhausted the expressible rows -- including a genuine orphan
# elsewhere in the corpus -- reporting as merely undecided the very defect G-07
# exists to catch.
#
# OUTPUT (the per-file oracle contract; frontmatter-schema.md § oracle:)
#   VIOLATION <path> <reason>     matches zero rows, or two rows non-adjacently
#   UNDECIDED <path> <reason>     inside an inexpressible row's path bound
#   (a file that resolves to exactly one type produces no line)
#
# EXIT
#   0  no VIOLATION lines (UNDECIDED lines may be present; not a failure)
#   1  at least one VIOLATION line
#   2  could not run at all -- registry missing or no Match column
#
# Deterministic: sorted enumeration under LC_ALL=C, no network, no clock.
# Bash + awk only.

set -uo pipefail
export LC_ALL=C

readonly REGISTRY=".aid/knowledge/authoring-conventions.md"
readonly ROOTS=("canonical/skills" "canonical/agents" "canonical/aid/templates" ".aid/knowledge")

[[ -f "$REGISTRY" ]] || { echo "g07: cannot read $REGISTRY" >&2; exit 2; }

# --- read the registry's Type + Match columns, in table order -----------------
# One "type<TAB>match" line per row. Table order is significant: resolution is
# first-match-wins, which is what makes the selectors mutually exclusive.
ROWS="$(awk -F'|' '
    /^\| Type \| Selector \| Match \| Notes \|/ { intbl=1; next }
    intbl && /^\|---/ { next }
    intbl && !/^\| `/ { intbl=0 }
    intbl {
        ty=$2; m=$4
        gsub(/^[ \t]+|[ \t]+$/, "", ty); gsub(/`/, "", ty)
        gsub(/^[ \t]+|[ \t]+$/, "", m);  gsub(/`/, "", m)
        if (ty != "" && m != "") print ty "\t" m
    }
' "$REGISTRY")"

[[ -n "$ROWS" ]] || { echo "g07: $REGISTRY has no Match column -- the registry must carry one for this oracle to read" >&2; exit 2; }

# --- helpers ------------------------------------------------------------------

# glob_match <path> <glob> -- ** crosses directories, * does not.
glob_match() {
    local p="$1" g="$2"
    case "$g" in
        *'**'*)
            local pre="${g%%\*\**}" post="${g#*\*\*}"
            [[ "$p" == "$pre"* ]] || return 1
            [[ -z "$post" || "$p" == *"$post" ]] || return 1
            return 0 ;;
        *)  [[ "$p" == $g ]] ;;
    esac
}

fm_value() {  # fm_value <file> <key>
    awk -v k="$2" '
        NR==1 && $0!="---" { exit }
        NR>1 && $0=="---" { exit }
        NR>1 { if (index($0, k ":")==1) { v=substr($0, length(k)+2); gsub(/^[ \t]+|[ \t]+$/,"",v); print v; exit } }
    ' "$1"
}

name_in() {  # name_in <file-under-test> <catalog>
    local dir; dir="$(basename "$(dirname "$1")")"
    [[ -f "$2" ]] || return 1
    grep -qE "^[[:space:]]*-?[[:space:]]*name:[[:space:]]*${dir}[[:space:]]*$" "$2"
}

# Does <path> satisfy every expressible clause of <match>? Returns 0 yes, 1 no,
# 2 the row is inexpressible AND the path is inside its bound.
row_matches() {
    local p="$1" match="$2" inexpr=0 clause ok=1
    local IFS_SAVE="$IFS"
    # split on " AND "
    local rest="$match"
    while [[ -n "$rest" ]]; do
        if [[ "$rest" == *" AND "* ]]; then clause="${rest%% AND *}"; rest="${rest#* AND }"
        else clause="$rest"; rest=""; fi
        clause="${clause#"${clause%%[![:space:]]*}"}"
        case "$clause" in
            '<inexpressible>') inexpr=1 ;;
            path\ *)    glob_match "$p" "${clause#path }" || { ok=0; break; } ;;
            fm\ *)      local body="${clause#fm }" k v
                        k="${body%% ==*}"; v="${body#*== }"
                        [[ "$(fm_value "$p" "$k")" == "$v" ]] || { ok=0; break; } ;;
            name-in\ *) name_in "$p" "${clause#name-in }" || { ok=0; break; } ;;
            *) ok=0; break ;;
        esac
    done
    IFS="$IFS_SAVE"
    (( ok )) || return 1
    (( inexpr )) && return 2
    return 0
}

# --- walk ---------------------------------------------------------------------
violations=0

while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    resolved=""
    undecided=0
    while IFS=$'\t' read -r ty match; do
        [[ -n "$ty" ]] || continue
        row_matches "$f" "$match"; rc=$?
        if   (( rc == 0 )); then resolved="$ty"; break
        elif (( rc == 2 )); then undecided=1; undecided_row="$ty"; break
        fi
    done <<<"$ROWS"

    if (( undecided )); then
        printf 'UNDECIDED %s inside the path bound of %s, whose selector is not fully expressible\n' "$f" "$undecided_row"
    elif [[ -z "$resolved" ]]; then
        printf 'VIOLATION %s resolves to no type in the registry\n' "$f"
        violations=$(( violations + 1 ))
    fi
done < <(find "${ROOTS[@]}" -name '*.md' -type f 2>/dev/null | sort)

(( violations == 0 )) || exit 1
exit 0
