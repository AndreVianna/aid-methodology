#!/usr/bin/env bash
# derive-edges.sh - Pass 1b: types feature-004's untyped observations.
#
# Purpose:
#   feature-004's scan-source.sh emits `observations.tsv` WITHOUT typing it -- it
#   records that one node's bytes referenced another and says nothing about what
#   the reference means. This pass supplies the meaning, and nothing else: it
#   looks each `observation_kind` up in the edge-relation map, resolves `s2t` and
#   `t2s` through the merged vocabulary, carries both `node_kind` values from the
#   node records, and emits a class-0 row per typed observation.
#
#   It adds NO TRAVERSAL OF ITS OWN. feature-004 owns the single walk of the
#   project source and `tests/canonical/test-graph-single-scanner.sh` asserts that
#   no other file under this directory contains a repository traversal, so this
#   pass cannot grow a second one without failing that suite.
#
#   An unmapped observation kind -- `path-reference`, by design (feature-005 D3)
#   -- becomes a Pass-2 edge candidate and emits nothing. There is no code path
#   here that writes a row with a blank or invented relation, and no relation
#   label appears anywhere in this file (feature-005 R8).
#
# Usage:
#   derive-edges.sh [options]
#
# Options:
#   --temp-dir <dir>               scratch directory holding feature-004's streams
#                                  and this pass's output (default: .aid/.temp/graph)
#   --schema <file>                relationship-schema.yml
#                                  (default: <aid-root>/templates/graph/relationship-schema.yml)
#   --vocabulary <file>            core relation-vocabulary.yml (same default directory)
#   --vocabulary-extension <file>  project extension
#                                  (default: .aid/graph/relation-vocabulary.yml; absent is not an error)
#   --edge-map <file>              edge-relation-map.yml (same default directory)
#   --lib <file>                   feature-003's relationship-schema.sh
#                                  (default: alongside this script)
#   -h, --help                     print this header
#
# Inputs (read, never written):
#   <temp-dir>/observations.tsv    feature-004 D5 -- from_id | to_id | observation_kind | evidence
#   <temp-dir>/nodes.tsv           feature-004 D1  -- `node_kind` is field 7, READ and never derived
#   <temp-dir>/media-nodes.tsv     feature-004 D1a -- `node_kind` is field 3, likewise
#   <temp-dir>/kb-nodes.tsv        Pass 1a -- so a `dependency` observation whose
#                                  target is a KB document has a kind to carry
#
# Outputs (all under <temp-dir>, LF only, no header row):
#   rows-pass1b.tsv                the D1 eleven-field row record, unsorted
#   candidates-pass1b.tsv          candidate_kind | subject | context | drop_reason
#
# Exit codes:
#   0 - success
#   1 - a write failure
#   2 - usage error, or a missing/malformed schema, vocabulary, edge-relation map
#       or feature-004 stream

set -euo pipefail

# Byte-deterministic collation AND byte-deterministic bracket expressions; see
# the note in harvest-declared.sh. Exported so a child process inherits it.
export LC_ALL=C

DE_SELF="derive-edges.sh"
de_warn() { printf '%s: %s\n' "$DE_SELF" "$*" >&2; }

DE_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./report-endpoint-satisfiability.sh
. "${DE_SCRIPT_DIR}/report-endpoint-satisfiability.sh"

declare -A NODE_KIND=()
declare -A NODE_NAME=()

TEMP_DIR=".aid/.temp/graph"
ROWS=""
CANDIDATES=""

CNT_TYPED=0
CNT_UNMAPPED=0
CNT_DROPPED=0

CELL_OUT=""
NAME_OUT=""

de_cell_into() {
    local t="$1"
    t="${t//$'\r'/ }"
    t="${t//$'\n'/ }"
    t="${t//$'\t'/ }"
    while [ "$t" != "${t//  / }" ]; do t="${t//  / }"; done
    t="${t#"${t%%[![:space:]]*}"}"
    t="${t%"${t##*[![:space:]]}"}"
    CELL_OUT="$t"
}

de_name_into() {
    local id="$1" kind="$2"
    if [ -n "${NODE_NAME[$id]:-}" ]; then
        NAME_OUT="${NODE_NAME[$id]}"
        return 0
    fi
    NAME_OUT=$(rel_display_name "$kind" "$id") || NAME_OUT=""
    NODE_NAME["$id"]="$NAME_OUT"
}

# ---------------------------------------------------------------------------
# The node records. `node_kind` is READ from its field in every stream and never
# recovered from an id prefix -- which is the Q21 rule this pass would otherwise
# be the easiest place to break, because both of its endpoints are usually `int:`
# and a prefix cannot tell a source artifact from an image.
# ---------------------------------------------------------------------------

de_load_nodes() {
    local nodes="$1" media="$2" kb="$3" id name kind f

    for f in "$nodes" "$media"; do
        [ -f "$f" ] || { de_warn "feature-004 stream not found at ${f}"; return 2; }
    done

    while IFS=$'\t' read -r id name _ _ _ _ kind || [ -n "${id:-}" ]; do
        [ -n "$id" ] || continue
        NODE_KIND["${id%$'\r'}"]="${kind%$'\r'}"
        NODE_NAME["${id%$'\r'}"]="$name"
    done < "$nodes"

    while IFS=$'\t' read -r id name kind _ _ || [ -n "${id:-}" ]; do
        [ -n "$id" ] || continue
        NODE_KIND["${id%$'\r'}"]="${kind%$'\r'}"
        NODE_NAME["${id%$'\r'}"]="$name"
    done < "$media"

    # Pass 1a's stream is optional here only so this pass stays independently
    # runnable; without it a KB-side target simply has no kind and becomes a
    # candidate, which is the same outcome D3 already specifies for the
    # `knowledge.doc_set` edge.
    if [ -f "$kb" ]; then
        while IFS=$'\t' read -r id kind name _ || [ -n "${id:-}" ]; do
            [ -n "$id" ] || continue
            NODE_KIND["${id%$'\r'}"]="${kind%$'\r'}"
            NODE_NAME["${id%$'\r'}"]="$name"
        done < "$kb"
    else
        de_warn "notice: ${kb} is absent; a KB-side observation target will have no kind and will become a candidate"
    fi
    return 0
}

de_candidate() {
    de_cell_into "$1"; local subject="$CELL_OUT"
    de_cell_into "$2"; local context="$CELL_OUT"
    printf 'edge\t%s\t%s\t%s\n' "$subject" "$context" "$3" >> "$CANDIDATES"
}

# ---------------------------------------------------------------------------
# Provenance for a kind the map lets emit more than one value
# ---------------------------------------------------------------------------
#
# Exactly one harvest kind here carries two: `image-reference`. feature-001 D6c
# stamps an illustration row `derived` "where the target is reached by
# feature-004's basename or relative-path resolution rather than by a literal
# full path", and that contract is honoured for harvest kinds 13 and 19 and
# NOWHERE ELSE -- D5 keys every other carrier's provenance on the STATEMENT, and
# generalising D6c would leave `cites`, `cites-as-evidence`, `defines`,
# `documents` and `cross-references` with no producer for any basename-resolved
# target.
#
# The literal is recoverable from the observation itself: feature-004 D5's
# evidence is D3b template 13 byte for byte, whose `(search: "<literal>" in
# <path>)` tail carries the matched literal AS WRITTEN in the citing file. An
# evidence string that does not carry the tail yields `derived`, which is the
# conservative direction: it under-claims what the carrier stated rather than
# asserting a literal path the scanner never saw.
PROV_OUT=""
de_provenance_into() {
    local kind="$1" to_id="$2" evidence="$3" provs literal
    provs=$(erm_provenances "$kind")
    case "$provs" in
        *' '*) : ;;
        *) PROV_OUT="$provs"; return 0 ;;
    esac
    literal=""
    case "$evidence" in
        *'(search: "'*'" in '*)
            literal="${evidence#*'(search: "'}"
            literal="${literal%%'" in '*}"
            ;;
    esac
    if [ -n "$literal" ] && [ "$literal" = "${to_id#int:}" ]; then
        PROV_OUT="declared"
    else
        PROV_OUT="derived"
    fi
    # Whatever the rule concluded must still be a value the map admits for this
    # kind; a mismatch is a configuration defect, not a row to ship.
    if ! erm_admits_provenance "$kind" "$PROV_OUT"; then
        de_warn "internal: '${PROV_OUT}' is not an emitting provenance of '${kind}' (${provs})"
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Pass 1b
# ---------------------------------------------------------------------------

de_type_observations() {
    local file="$1" from_id to_id kind evidence skind tkind relation inverse sname tname

    [ -f "$file" ] || { de_warn "feature-004 stream not found at ${file}"; return 2; }

    while IFS=$'\t' read -r from_id to_id kind evidence || [ -n "${from_id:-}" ]; do
        [ -n "$from_id" ] || continue
        kind="${kind%$'\r'}"
        [ -n "$kind" ] || continue

        if ! erm_is_known "$kind"; then
            de_warn "observation kind '${kind}' is not one this extractor recognises"
            de_candidate "${from_id} -> ${to_id}" "${kind} observation" "no-rule-match"
            CNT_DROPPED=$(( CNT_DROPPED + 1 ))
            continue
        fi
        if erm_is_unmapped "$kind"; then
            # By design, not by omission: the relation whose definition matches a
            # coarse path reference declares no `source-artifact->` endpoint at
            # all, so typing it would assert a data dependency the observation
            # does not evidence. Pass 2's typing half is what this exists for
            # (FR-31a part 3).
            de_candidate "${from_id} -> ${to_id}" "${kind} observation" "no-rule-match"
            CNT_UNMAPPED=$(( CNT_UNMAPPED + 1 ))
            continue
        fi

        skind="${NODE_KIND[$from_id]:-}"
        tkind="${NODE_KIND[$to_id]:-}"
        if [ -z "$skind" ] || [ -z "$tkind" ]; then
            de_candidate "${from_id} -> ${to_id}" "${kind} observation" "unresolved-reference"
            CNT_DROPPED=$(( CNT_DROPPED + 1 ))
            continue
        fi
        if ! erm_admits_pair "$kind" "${skind}->${tkind}"; then
            # The `.aid/settings.yml knowledge.doc_set` edge lands here: its
            # target is a `document` that `depends-on` does not declare, so it
            # becomes a Pass-2 candidate rather than a row the endpoint gate
            # would reject (D3, Open Item 3).
            de_candidate "${from_id} -> ${to_id}" \
                "${kind} observation, ${skind}->${tkind} not declared" "no-rule-match"
            CNT_DROPPED=$(( CNT_DROPPED + 1 ))
            continue
        fi

        de_provenance_into "$kind" "$to_id" "$evidence" || continue
        relation=$(erm_relation "$kind")
        inverse=$(rel_inverse_of "$relation")
        de_name_into "$from_id" "$skind"; sname="$NAME_OUT"
        de_name_into "$to_id" "$tkind";   tname="$NAME_OUT"
        de_cell_into "$evidence"
        # `class` is 0 for every row this pass writes: `provenance` is `declared`
        # or `derived` by the map, never `inferred` -- Pass 2 is the only writer
        # of class 1.
        printf '0\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$from_id" "$skind" "$sname" "$to_id" "$tkind" "$tname" \
            "$relation" "$inverse" "$PROV_OUT" "$CELL_OUT" >> "$ROWS"
        CNT_TYPED=$(( CNT_TYPED + 1 ))
    done < "$file"
    return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

de_help() { sed -n '2,/^$/p' "$0" | sed -e 's/^#$//' -e 's/^# //'; }

DE_HELP=0

de_parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) DE_HELP=1; return 0 ;;
            --temp-dir)             TEMP_DIR="${2:-}"; shift 2 ;;
            --schema)               GRAPH_SCHEMA="${2:-}"; shift 2 ;;
            --vocabulary)           GRAPH_VOCAB="${2:-}"; shift 2 ;;
            --vocabulary-extension) GRAPH_VOCAB_EXT="${2:-}"; shift 2 ;;
            --edge-map)             GRAPH_EDGE_MAP="${2:-}"; shift 2 ;;
            --lib)                  GRAPH_LIB="${2:-}"; shift 2 ;;
            *) de_warn "unknown option '$1'"; return 2 ;;
        esac
    done
    graph_require_path --schema "$GRAPH_SCHEMA" || return 2
    graph_require_path --vocabulary "$GRAPH_VOCAB" || return 2
    graph_require_path --edge-map "$GRAPH_EDGE_MAP" || return 2
    graph_require_library "$GRAPH_LIB" || return 2
    return 0
}

de_run() {
    graph_require_functions rel_display_name || return 2

    mkdir -p -- "$TEMP_DIR" || { de_warn "cannot create ${TEMP_DIR}"; return 1; }
    ROWS="${TEMP_DIR}/rows-pass1b.tsv"
    CANDIDATES="${TEMP_DIR}/candidates-pass1b.tsv"
    : > "$ROWS"
    : > "$CANDIDATES"

    de_load_nodes "${TEMP_DIR}/nodes.tsv" "${TEMP_DIR}/media-nodes.tsv" \
        "${TEMP_DIR}/kb-nodes.tsv" || return 2
    de_type_observations "${TEMP_DIR}/observations.tsv" || return 2

    printf '[derive] %s rows | %s unmapped-kind candidates | %s dropped\n' \
        "$CNT_TYPED" "$CNT_UNMAPPED" "$CNT_DROPPED"
    return 0
}

# Top level, never inside a function -- see the note in harvest-declared.sh.
graph_default_paths "$DE_SCRIPT_DIR"
de_parse_args "$@" || exit $?
if [ "$DE_HELP" = "1" ]; then de_help; exit 0; fi
# shellcheck disable=SC1090  # resolved at run time, by design
. "$GRAPH_LIB" || { de_warn "cannot source ${GRAPH_LIB}"; exit 2; }
graph_load_context "$GRAPH_SCHEMA" "$GRAPH_VOCAB" "$GRAPH_VOCAB_EXT" "$GRAPH_EDGE_MAP" || exit 2
de_run
exit $?
