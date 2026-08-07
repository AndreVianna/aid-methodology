#!/usr/bin/env bash
# report-endpoint-satisfiability.sh - the W3 producer-satisfiability report, and
# the single home of the edge-relation map loader.
#
# Purpose:
#   Two jobs, both keyed on `aid/templates/graph/edge-relation-map.yml`.
#
#   1. LIBRARY. `load_edge_relation_map` is the fail-closed loader feature-005 D3
#      specifies: entry arity, completeness against the closed harvest-kind list,
#      pass legality and endpoint legality (AC-S5). It lives here and only here,
#      because the map is this script's own subject. harvest-declared.sh and
#      derive-edges.sh source this file for it rather than carrying a second copy
#      -- a second copy of a rule is a divergence waiting to happen. The shared
#      load sequence (schema, then vocabulary, then map) lives here too, as
#      `graph_load_context`, for the same reason.
#
#   2. ENTRY POINT. Emits the D8 W3 report: for every entry of the merged
#      vocabulary, for every `endpoint_kinds` token it declares, whether some
#      edge-relation map entry can produce that token (`producer`), whether only
#      the reading pass can (`inferred-only`), or whether nothing can
#      (`unreachable`). The report GATES NOTHING and always exits 0 once the
#      inputs load: a core vocabulary is deliberately larger than any one
#      project's producer set (feature-001 D3a).
#
#   Orientation safety, stated because this work has already paid for getting it
#   wrong. Marks are computed from the MAP and the VOCABULARY, never from emitted
#   rows. feature-003 D7 stores a row normalised, swapping the two (Id, Kind,
#   Name) triples AND the two relation labels together, so an accumulator reading
#   emitted rows would credit the inverse entry's token on roughly half of every
#   asymmetric pair. Here a map entry that can emit `a->b` as relation `r` is
#   recorded as a producer of `("a->b", r)` and of `("b->a", inverse(r))` in the
#   same step -- the transposition comes from the map, so no stored orientation
#   can reach the classification (feature-005 SPEC D8, "Orientation does not
#   disturb the classification").
#
#   No relation label is written anywhere in this file. Every label is read from
#   the merged vocabulary through feature-003's `rel_load_vocabulary`, and every
#   harvest-kind-to-relation binding is read from the map (feature-005 R8).
#
#   No top-level side effects when sourced: this file defines functions and
#   read-only constants only. `set -uo pipefail` is applied on direct execution
#   and nowhere else, so sourcing never mutates the caller's shell options -- the
#   posture significance-rules.sh and lib/aid-install-core.sh take. `-e` is
#   deliberately absent here, following the read-only reporting precedent
#   kb-citation-lint.sh sets (feature-005 SPEC, Conventions honoured).
#
# Usage:
#   report-endpoint-satisfiability.sh [options]
#   source "$(dirname "$0")/report-endpoint-satisfiability.sh"   # library use
#
# Options:
#   --schema <file>                relationship-schema.yml
#                                  (default: <aid-root>/templates/graph/relationship-schema.yml)
#   --vocabulary <file>            core relation-vocabulary.yml
#                                  (default: <aid-root>/templates/graph/relation-vocabulary.yml)
#   --vocabulary-extension <file>  project extension
#                                  (default: .aid/graph/relation-vocabulary.yml; absent is not an error)
#   --edge-map <file>              edge-relation-map.yml
#                                  (default: <aid-root>/templates/graph/edge-relation-map.yml)
#   --lib <file>                   feature-003's relationship-schema.sh
#                                  (default: alongside this script)
#   --temp-dir <dir>               scratch directory (default: .aid/.temp/graph)
#   --out <file>                   report destination (default: <temp-dir>/w3-satisfiability.tsv)
#   -h, --help                     print this header
#
# Provides:
#   -- shared load sequence --
#   graph_template_dir                        -> <aid-root>/templates/graph
#   graph_script_dir                          -> the directory holding this file
#   graph_require_functions <name ...>        -> exit 2 naming every absent D9 function
#   graph_require_path <flag> <value>         -> exit 2 when a required path is unset
#   graph_require_library <lib>               -> exit 2 when relationship-schema.sh is absent
#   graph_load_context <schema> <vocab> <vocab-ext> <edge-map>
#                                             -> rel_load_schema, rel_load_vocabulary,
#                                                load_edge_relation_map, in that order;
#                                                pass an empty <edge-map> to skip the map.
#                                                THE CALLER SOURCES THE LIBRARY, at top
#                                                level -- see the note above the function
#   -- the edge-relation map (feature-005 D3) --
#   graph_harvest_kinds                       -> the closed list of recognised harvest kinds
#   graph_unmapped_kinds                      -> the kinds deliberately carrying no mapping
#   load_edge_relation_map <file>             -> parse + the four gates; 2 on any failure
#   erm_is_known <kind>                       -> 0 when <kind> is in the closed list
#   erm_is_unmapped <kind>                    -> 0 when <kind> is deliberately unmapped
#   erm_is_mapped <kind>                      -> 0 when the loaded map carries <kind>
#   erm_relation <kind>                       -> the mapped relation label
#   erm_provenances <kind>                    -> the space-separated emitting provenances
#   erm_pairs <kind>                          -> the space-separated legal kind pairs
#   erm_admits_pair <kind> <pair>             -> 0 when <kind> may emit <source>-><target>
#   erm_admits_provenance <kind> <prov>       -> 0 when <kind> may emit <prov>
#   -- the W3 report (feature-005 D8) --
#   erm_w3_rows                               -> the report on stdout, LC_ALL=C sorted
#
# Exit codes:
#   0 - success (the report itself never fails once its inputs load)
#   1 - the report could not be written
#   2 - usage error, or a missing/malformed schema, vocabulary or edge-relation map

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

ERM_SELF="report-endpoint-satisfiability.sh"

# The closed list of harvest kinds this feature recognises -- feature-005 D4's
# twenty. Completeness is checked against THIS list rather than against the
# map's own contents, so a deliberate omission and an accidental one cannot look
# the same (D3, "Completeness is checked against a declared kind list").
GRAPH_HARVEST_KINDS="\
kb-doc-section kb-section-section kb-doc-fact kb-section-fact kb-fact-anchor \
kb-concept-definition kb-concept-mention frontmatter-see-also \
frontmatter-sources-path frontmatter-sources-url kb-inline-path-citation \
kb-inline-doc-link kb-image-reference kb-ext-key-citation \
invocation dependency include convention image-reference path-reference"

# The kinds that carry no map entry BY DESIGN. Exactly one today:
# `path-reference` -- the relation whose definition matches it declares no
# `source-artifact->` endpoint at all, so those observations become Pass-2 edge
# candidates (D3, "path-reference is deliberately unmapped"). A kind that is
# neither mapped nor listed here exits 2.
GRAPH_UNMAPPED_KINDS="path-reference"

# US (0x1f) joins a two-part associative-array key. It cannot occur in a
# relation label or in a kind token, which is the same ground feature-003 D7
# uses for the row key.
ERM_US=$'\x1f'

# ---------------------------------------------------------------------------
# Diagnostics
# ---------------------------------------------------------------------------

erm_warn() { printf '%s: %s\n' "$ERM_SELF" "$*" >&2; }

# Strip a trailing CR. `.gitattributes` pins *.sh, *.mjs, *.py and *.md to LF but
# says nothing about *.yml, so a Windows checkout can legitimately hand this
# loader CRLF template bytes.
erm_strip_cr() { printf '%s' "${1%$'\r'}"; }

# ---------------------------------------------------------------------------
# Path resolution -- no `realpath`, no `readlink -f` (neither is portable to the
# Git Bash / MSYS environment this work is authored in).
# ---------------------------------------------------------------------------

graph_script_dir() {
    local d
    d=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd) || return 1
    printf '%s' "$d"
}

# The graph template directory, resolved from this file's own location:
# <aid-root>/scripts/graph/ -> <aid-root>/templates/graph/.
graph_template_dir() {
    local d
    d=$(graph_script_dir) || return 1
    d=$(cd -- "$d/../../templates/graph" 2>/dev/null && pwd) || return 1
    printf '%s' "$d"
}

# ---------------------------------------------------------------------------
# The feature-003 D9 seam
# ---------------------------------------------------------------------------
#
# Every id, slug, token, term, display name, row normalisation, row key and sort
# key this feature writes is computed by a function of feature-003's
# `relationship-schema.sh` (feature-005 R3, D1). None is reimplemented here.
# This helper turns "the library is older than this consumer" from a confusing
# runtime error into one message naming every function that is missing.

graph_require_functions() {
    local missing="" fn
    for fn in "$@"; do
        command -v "$fn" >/dev/null 2>&1 || missing="$missing $fn"
    done
    if [ -n "$missing" ]; then
        erm_warn "relationship-schema.sh does not provide:${missing}"
        return 2
    fi
    return 0
}

# A required path that resolved to nothing -- because its flag was not given and
# the install tree could not be located -- is a usage error naming the flag,
# never a "file not found" naming the empty string.
graph_require_path() {
    if [ -z "${2:-}" ]; then
        erm_warn "no value for ${1}, and it could not be defaulted from the install tree"
        return 2
    fi
    return 0
}

graph_require_library() {
    if [ -z "${1:-}" ] || [ ! -f "$1" ]; then
        erm_warn "relationship-schema.sh not found at ${1:-<unset>}"
        return 2
    fi
    return 0
}

# The shared fail-closed load sequence: schema first (it carries the `Kind` enum
# every `endpoint_kinds` token is validated against), then the merged vocabulary,
# then the map. feature-005 Feature Flow steps 2-3.
#
# THE CALLER SOURCES relationship-schema.sh, AND MUST DO IT AT TOP LEVEL. This
# function deliberately does not, and the reason is a bash rule rather than a
# preference: a `.` executed inside a function makes every `declare` in the
# sourced file FUNCTION-LOCAL, so the library's loaded schema and vocabulary would
# be discarded the moment the sourcing function returned -- and the next
# `${REL_PASSES[has-part]}` would then be read as an arithmetic subscript on an
# unset name and fail under `set -u`. Sourcing at top level is what makes the
# loaded state global.
#
#   $1 schema     path to relationship-schema.yml
#   $2 vocab      path to the core relation-vocabulary.yml
#   $3 vocab_ext  path to the project extension, or empty; absent is not an error
#   $4 edge_map   path to edge-relation-map.yml, or empty to skip the map
graph_load_context() {
    local schema="$1" vocab="$2" vocab_ext="$3" edge_map="$4"

    graph_require_functions rel_load_schema rel_load_vocabulary || return 2

    rel_load_schema "$schema" || {
        erm_warn "rel_load_schema failed for ${schema}"
        return 2
    }
    if [ -n "$vocab_ext" ] && [ -f "$vocab_ext" ]; then
        rel_load_vocabulary "$vocab" "$vocab_ext" || {
            erm_warn "rel_load_vocabulary failed for ${vocab} + ${vocab_ext}"
            return 2
        }
    else
        rel_load_vocabulary "$vocab" || {
            erm_warn "rel_load_vocabulary failed for ${vocab}"
            return 2
        }
    fi

    graph_require_functions rel_is_relation rel_inverse_of rel_passes \
        rel_endpoint_kinds rel_vocab_relations || return 2

    if [ -n "$edge_map" ]; then
        load_edge_relation_map "$edge_map" || return 2
    fi
    return 0
}

# ---------------------------------------------------------------------------
# The edge-relation map (feature-005 D3)
# ---------------------------------------------------------------------------

declare -A ERM_RELATION=()
declare -A ERM_PROVENANCES=()
declare -A ERM_PAIRS=()

graph_harvest_kinds() { printf '%s' "$GRAPH_HARVEST_KINDS"; }
graph_unmapped_kinds() { printf '%s' "$GRAPH_UNMAPPED_KINDS"; }

erm_in_list() {
    local needle="$1" haystack="$2" item
    for item in $haystack; do
        if [ "$item" = "$needle" ]; then
            return 0
        fi
    done
    return 1
}

erm_is_known()    { erm_in_list "$1" "$GRAPH_HARVEST_KINDS"; }
erm_is_unmapped() { erm_in_list "$1" "$GRAPH_UNMAPPED_KINDS"; }
erm_is_mapped()   { [ -n "${ERM_RELATION[$1]:-}" ]; }

erm_relation()    { printf '%s' "${ERM_RELATION[$1]:-}"; }
erm_provenances() { printf '%s' "${ERM_PROVENANCES[$1]:-}"; }
erm_pairs()       { printf '%s' "${ERM_PAIRS[$1]:-}"; }

erm_admits_pair()       { erm_in_list "$2" "${ERM_PAIRS[$1]:-}"; }
erm_admits_provenance() { erm_in_list "$2" "${ERM_PROVENANCES[$1]:-}"; }

# load_edge_relation_map <file>
#
# Fail-closed, run before any row exists. Four gates, in the order feature-005 D3
# states them, each exiting 2 and naming the resolved absolute path:
#
#   arity        every entry is exactly four `|`-separated non-empty fields
#   completeness every kind in the closed list is either mapped with a label that
#                is a member of the merged vocabulary, or declared unmapped
#   pass         every provenance in field 2 is a member of that relation's `passes`
#   endpoint     every kind pair in field 3 is a member of that relation's
#                `endpoint_kinds`, compared AFTER PARSING and never textually --
#                this file's comma encoding and feature-001's double-quoted flow
#                sequence are two notations for one token set
load_edge_relation_map() {
    local file="$1" abs="" dir="" line raw in_map=0 kind provs pairs relation rest
    local p pair declared rc=0

    if [ -z "$file" ] || [ ! -f "$file" ]; then
        erm_warn "edge-relation map not found at ${file:-<unset>}"
        return 2
    fi
    dir=$(cd -- "$(dirname -- "$file")" 2>/dev/null && pwd) || dir=""
    if [ -n "$dir" ]; then
        abs="${dir}/$(basename -- "$file")"
    else
        abs="$file"
    fi

    graph_require_functions rel_is_relation rel_inverse_of rel_passes \
        rel_endpoint_kinds || return 2

    ERM_RELATION=()
    ERM_PROVENANCES=()
    ERM_PAIRS=()

    while IFS= read -r raw || [ -n "$raw" ]; do
        line=$(erm_strip_cr "$raw")
        case "$line" in
            'map:'*) in_map=1; continue ;;
            '#'*|'') continue ;;
        esac
        [ "$in_map" -eq 1 ] || continue
        case "$line" in
            '  - '*|'- '*) : ;;
            *) in_map=0; continue ;;          # a new top-level key ends the block
        esac
        line="${line#*- }"

        # Arity: exactly four fields, none empty. Split with `read` rather than
        # four `awk` forks -- forking is expensive under Git Bash / MSYS, and the
        # loader runs before every pass.
        rest=""
        IFS='|' read -r kind provs pairs relation rest <<< "$line"
        if [ -n "$rest" ]; then
            erm_warn "${abs}: entry carries more than four '|'-separated fields: ${line}"
            rc=2
            continue
        fi
        if [ -z "$kind" ] || [ -z "$provs" ] || [ -z "$pairs" ] || [ -z "$relation" ]; then
            erm_warn "${abs}: entry carries an empty field: ${line}"
            rc=2
            continue
        fi
        if ! erm_is_known "$kind"; then
            erm_warn "${abs}: '${kind}' is not a harvest kind this extractor recognises"
            rc=2
            continue
        fi
        if [ -n "${ERM_RELATION[$kind]:-}" ]; then
            erm_warn "${abs}: harvest kind '${kind}' is mapped more than once"
            rc=2
            continue
        fi
        if erm_is_unmapped "$kind"; then
            erm_warn "${abs}: harvest kind '${kind}' is declared unmapped and must carry no entry"
            rc=2
            continue
        fi
        if ! rel_is_relation "$relation"; then
            erm_warn "${abs}: '${relation}' (kind '${kind}') is not a member of the merged vocabulary"
            rc=2
            continue
        fi

        # Pass legality (AC-S5).
        declared=$(rel_passes "$relation")
        for p in ${provs//,/ }; do
            if ! erm_in_list "$p" "$declared"; then
                erm_warn "${abs}: kind '${kind}' emits '${p}', which is not in '${relation}' passes (${declared})"
                rc=2
            fi
        done

        # Endpoint legality (AC-S5), compared after parsing.
        declared=$(rel_endpoint_kinds "$relation")
        for pair in ${pairs//,/ }; do
            case "$pair" in
                *'->'*) : ;;
                *) erm_warn "${abs}: kind '${kind}' declares '${pair}', which is not a <kind>-><kind> token"
                   rc=2
                   continue ;;
            esac
            if ! erm_in_list "$pair" "$declared"; then
                erm_warn "${abs}: kind '${kind}' declares '${pair}', which is not in '${relation}' endpoint_kinds (${declared})"
                rc=2
            fi
        done

        ERM_RELATION["$kind"]="$relation"
        ERM_PROVENANCES["$kind"]="${provs//,/ }"
        ERM_PAIRS["$kind"]="${pairs//,/ }"
    done < "$file"

    # Completeness against the closed list.
    for kind in $GRAPH_HARVEST_KINDS; do
        if [ -n "${ERM_RELATION[$kind]:-}" ]; then
            continue
        fi
        if erm_is_unmapped "$kind"; then
            continue
        fi
        erm_warn "${abs}: harvest kind '${kind}' is neither mapped nor declared unmapped"
        rc=2
    done

    [ "$rc" -eq 0 ] || return 2
    return 0
}

# ---------------------------------------------------------------------------
# The W3 report (feature-005 D8)
# ---------------------------------------------------------------------------

# erm_w3_rows
#
#   relation <TAB> token <TAB> mark <TAB> producers
#
# `mark` is `producer` when some map entry can emit the token, `inferred-only`
# when no producer exists but the relation's `passes` admits `inferred`, and
# `unreachable` otherwise. `producers` is the `|`-separated harvest kinds, or
# `--`. Output is LC_ALL=C sorted on (relation, token), which keeps every
# entry's rows contiguous -- the "one block of rows per entry" shape -- while
# making the byte sequence a function of the map and the vocabulary alone rather
# than of either loader's iteration order.
erm_join_sorted() {
    local out="" item
    # shellcheck disable=SC2086  # deliberate word splitting over a space-separated list
    for item in $(printf '%s\n' $1 | LC_ALL=C sort -u); do
        if [ -z "$out" ]; then out="$item"; else out="${out}|${item}"; fi
    done
    printf '%s' "$out"
}

erm_w3_rows() {
    local -A producers=()
    local kind relation inverse pair src dst key token mark list

    for kind in $GRAPH_HARVEST_KINDS; do
        relation="${ERM_RELATION[$kind]:-}"
        [ -n "$relation" ] || continue
        inverse=$(rel_inverse_of "$relation")
        for pair in ${ERM_PAIRS[$kind]}; do
            src="${pair%%->*}"
            dst="${pair#*->}"
            key="${relation}${ERM_US}${src}->${dst}"
            producers["$key"]="${producers[$key]:-} $kind"
            # The transposed reading, taken from the map and never from a stored
            # row: emitting `a->b` as `r` is emitting `b->a` as `inverse(r)`.
            if [ -n "$inverse" ]; then
                key="${inverse}${ERM_US}${dst}->${src}"
                producers["$key"]="${producers[$key]:-} $kind"
            fi
        done
    done

    {
        while IFS= read -r relation; do
            [ -n "$relation" ] || continue
            for token in $(rel_endpoint_kinds "$relation"); do
                key="${relation}${ERM_US}${token}"
                list="${producers[$key]:-}"
                if [ -n "${list// /}" ]; then
                    mark="producer"
                    list=$(erm_join_sorted "$list")
                elif erm_in_list "inferred" "$(rel_passes "$relation")"; then
                    mark="inferred-only"
                    list="--"
                else
                    mark="unreachable"
                    list="--"
                fi
                printf '%s\t%s\t%s\t%s\n' "$relation" "$token" "$mark" "$list"
            done
        done < <(rel_vocab_relations)
    } | LC_ALL=C sort -t$'\t' -k1,1 -k2,2
}

# ---------------------------------------------------------------------------
# Direct execution
# ---------------------------------------------------------------------------

erm_help() {
    sed -n '2,/^$/p' "$0" | sed -e 's/^#$//' -e 's/^# //'
}

# The five paths every graph script resolves the same way, exposed as globals so
# the entry point can source the library at top level between parsing and loading.
GRAPH_LIB=""
GRAPH_SCHEMA=""
GRAPH_VOCAB=""
GRAPH_VOCAB_EXT=".aid/graph/relation-vocabulary.yml"
GRAPH_EDGE_MAP=""

# graph_default_paths <script-dir> -- the install-tree defaults, before any flag.
graph_default_paths() {
    local tpl
    GRAPH_LIB="${1}/relationship-schema.sh"
    tpl=$(graph_template_dir) || tpl=""
    if [ -n "$tpl" ]; then
        GRAPH_SCHEMA="${tpl}/relationship-schema.yml"
        GRAPH_VOCAB="${tpl}/relation-vocabulary.yml"
        GRAPH_EDGE_MAP="${tpl}/edge-relation-map.yml"
    fi
}

ERM_TEMP_DIR=".aid/.temp/graph"
ERM_OUT=""
ERM_HELP=0

erm_parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) ERM_HELP=1; return 0 ;;
            --schema)               GRAPH_SCHEMA="${2:-}"; shift 2 ;;
            --vocabulary)           GRAPH_VOCAB="${2:-}"; shift 2 ;;
            --vocabulary-extension) GRAPH_VOCAB_EXT="${2:-}"; shift 2 ;;
            --edge-map)             GRAPH_EDGE_MAP="${2:-}"; shift 2 ;;
            --lib)                  GRAPH_LIB="${2:-}"; shift 2 ;;
            --temp-dir)             ERM_TEMP_DIR="${2:-}"; shift 2 ;;
            --out)                  ERM_OUT="${2:-}"; shift 2 ;;
            *) erm_warn "unknown option '$1'"; return 2 ;;
        esac
    done
    [ -n "$ERM_OUT" ] || ERM_OUT="${ERM_TEMP_DIR}/w3-satisfiability.tsv"
    graph_require_path --schema "$GRAPH_SCHEMA" || return 2
    graph_require_path --vocabulary "$GRAPH_VOCAB" || return 2
    graph_require_path --edge-map "$GRAPH_EDGE_MAP" || return 2
    graph_require_library "$GRAPH_LIB" || return 2
    return 0
}

erm_run() {
    local out="$ERM_OUT"
    mkdir -p -- "$(dirname -- "$out")" || { erm_warn "cannot create $(dirname -- "$out")"; return 1; }
    erm_w3_rows > "$out" || { erm_warn "cannot write ${out}"; return 1; }

    local total producer inferred unreachable
    total=$(wc -l < "$out" | tr -d ' ')
    producer=$(awk -F'\t' '$3=="producer"' "$out" | wc -l | tr -d ' ')
    inferred=$(awk -F'\t' '$3=="inferred-only"' "$out" | wc -l | tr -d ' ')
    unreachable=$(awk -F'\t' '$3=="unreachable"' "$out" | wc -l | tr -d ' ')
    printf '[endpoints] %s tokens | producer %s | inferred-only %s | unreachable %s | %s\n' \
        "$total" "$producer" "$inferred" "$unreachable" "$out"
    return 0
}

# Everything below runs at TOP LEVEL, inside an `if` rather than a function, so
# that `. "$GRAPH_LIB"` makes the library's declarations global (see
# graph_load_context). `set -uo pipefail` is applied here and nowhere else, so
# sourcing this file never mutates the caller's shell options; `-e` is absent,
# following kb-citation-lint.sh's read-only reporting precedent.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    set -uo pipefail
    graph_default_paths "$(graph_script_dir)"
    erm_parse_args "$@" || exit $?
    if [ "$ERM_HELP" = "1" ]; then erm_help; exit 0; fi
    # shellcheck disable=SC1090  # resolved at run time, by design
    . "$GRAPH_LIB" || { erm_warn "cannot source ${GRAPH_LIB}"; exit 2; }
    graph_load_context "$GRAPH_SCHEMA" "$GRAPH_VOCAB" "$GRAPH_VOCAB_EXT" "$GRAPH_EDGE_MAP" || exit 2
    erm_run
    exit $?
fi
