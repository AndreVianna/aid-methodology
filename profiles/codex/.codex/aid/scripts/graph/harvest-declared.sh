#!/usr/bin/env bash
# harvest-declared.sh - Pass 1a: the Knowledge Base scan.
#
# Purpose:
#   Emits the four KB-side node kinds -- `document`, `section`, `fact` and
#   `concept` -- and the fourteen KB-side harvest kinds of feature-005 D4, as
#   class-0 relationship rows. This is FR-30's deterministic pass: every node id
#   is a pure function of document bytes computed by a feature-003 D9 library
#   function, and every relation label is read from the merged vocabulary through
#   the edge-relation map. No relation label is written anywhere in this file
#   (feature-005 R8), and no repository traversal happens here -- feature-004's
#   scan-source.sh owns the one source walk, and this pass reads the KB root at
#   depth 1 only, which is the exemption feature-004's seam section names
#   (feature-005 R1, "The shared scanner seam").
#
#   Ordering, keying, normalisation, de-duplication, rendering and the merge are
#   NOT done here. This pass writes an unsorted, un-normalised row stream;
#   build-relationships.sh owns Feature Flow steps 11-16. No rule lives twice.
#
# Usage:
#   harvest-declared.sh [options]
#
# Options:
#   --kb-root <dir>                KB scan root (default: .aid/knowledge)
#   --temp-dir <dir>               scratch directory holding feature-004's
#                                  streams and this pass's output
#                                  (default: .aid/.temp/graph)
#   --repo-root <dir>              repository root the observation anchors are
#                                  rendered relative to (default:
#                                  git rev-parse --show-toplevel, falling back to
#                                  the working directory)
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
# Inputs (read, never written -- FR-10):
#   <kb-root>/*.md                 the scan set -- feature-003 D2a's membership
#                                  predicate, consumed as a set
#   <temp-dir>/nodes.tsv           feature-004 D1  -- the `source-artifact` set
#   <temp-dir>/media-nodes.tsv     feature-004 D1a -- the `image` / `web-page` set,
#                                  and the only carrier of the registered `ext:`
#                                  key set this pass reads
#
# Outputs (all under <temp-dir>, LF only, no header row):
#   kb-nodes.tsv                   node_id | node_kind | name | doc   (LC_ALL=C by node_id)
#   rows-pass1a.tsv                the D1 eleven-field row record, unsorted
#   candidates-pass1a.tsv          candidate_kind | subject | context | drop_reason
#   kb-stats.tsv                   key | value -- the counters D7's coverage rows need
#   pass2-inputs.tsv               row_kind | value -- the closed Pass-2 input set (D6 part 1)
#
# Exit codes:
#   0 - success
#   1 - a write failure
#   2 - usage error, or a missing/malformed schema, vocabulary, edge-relation map
#       or feature-004 stream
#
# ---------------------------------------------------------------------------
# The feature-003 D9 seam -- the record shapes this pass consumes
# ---------------------------------------------------------------------------
#
# D9 publishes the function names; the record shapes below are what this consumer
# requires of three of them, plus one primitive D9's table does not yet list.
# They are stated HERE, once, because harvest-declared.sh is their only caller.
# Every one of them keeps a feature-003 rule inside feature-003's library instead
# of copying it into this file, which is why the seam is drawn here rather than
# by reimplementing the scan:
#
#   rel_fence_mask <doc>       one line per physical line of <doc>: `0` outside a
#                              fenced code block, `1` inside one (the fence
#                              delimiters counting as inside).
#                              REQUIRED BY AC-S1. D2e's enclosing chain and D4
#                              kinds 11-14 are this feature's own rules but must
#                              share the single fenced-code state D2a-1, D2a-2 and
#                              D2a-3a already maintain. Reading the mask is what
#                              makes "the heading counter, the block boundaries
#                              and the marker scan cannot disagree about where a
#                              fence begins" true ACROSS the seam and not merely
#                              within one library.
#
#   rel_block_bodies <doc>     one record per ATX heading 1-6, document order:
#                                 <level> TAB <marked> TAB <start> TAB <end> TAB <text>
#                              <marked> is `1` when the heading's block body
#                              carries a D2a-3 definition marker -- the flag
#                              D2a-3a's own algorithm computes as `marked[owner]`.
#                              <start>..<end> is the 1-based inclusive body line
#                              range under D2a-3a's boundary rule (the next
#                              heading of ANY level closes it); <end> < <start>
#                              for an empty body.
#
#   rel_fact_records <doc>      one record per citation marker, document order:
#                                 <status> TAB <token> TAB <path> TAB <anchor> TAB <start> TAB <end>
#                              <status> is `anchored` for a well-formed checkable
#                              source anchor and `unanchored` for a marker with no
#                              grep-recoverable anchor string (D2a-2), whose count
#                              D7's `fact-unanchored` row reports. <path> is the
#                              cited path, <anchor> the anchor string; both empty
#                              on an `unanchored` record. <start>..<end> is the
#                              anchor block's 1-based inclusive line range -- the
#                              marker line plus D2a-2's continuation lines.
#
#   rel_doc_slugs <doc>        as D9 states it: the emitted heading slugs, in
#                              document order, counter and fence exclusion applied.
#   rel_slug_heading <text>    as D9 states it: D2a-1 steps 1-5, no counter. Read
#                              only to decide whether a heading's slug came out
#                              EMPTY -- the one thing the slug list cannot report,
#                              because such a heading emits nothing -- and only
#                              when the two counts disagree.
#
# Everything else is used exactly as D9 publishes it: rel_load_schema,
# rel_load_vocabulary, rel_normalise_term, rel_concept_defs, rel_display_name.
#
# One consequence of reading `ext:` keys from media-nodes.tsv rather than from
# the external-sources file: this pass never parses that file, so feature-003
# D2c's registry format has exactly one reader. A `sources:` URL therefore
# resolves only when the registry key IS the URL; any other URL becomes an
# `unresolved-reference` candidate, which is the treatment D4 already prescribes
# for an unregistered one.

set -euo pipefail

# Byte-deterministic collation AND byte-deterministic bracket expressions. The
# SPEC requires LC_ALL=C on every sort this feature writes, and each such sort
# still carries that prefix explicitly; this export additionally removes the
# ambient locale from the `case`/`[[ ]]` character-class tests that decide token
# boundaries and slug charsets, where a locale folding case or widening [a-z]
# would change what is matched. It is exported so a child process inherits it.
export LC_ALL=C

HD_SELF="harvest-declared.sh"
hd_warn() { printf '%s: %s\n' "$HD_SELF" "$*" >&2; }

HD_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./report-endpoint-satisfiability.sh
. "${HD_SCRIPT_DIR}/report-endpoint-satisfiability.sh"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

declare -A NODE_KIND=()          # node id -> Kind
declare -A NODE_NAME=()          # node id -> display name
declare -A PATH_TO_ID=()         # repo-relative path -> int: node id
declare -A BASE_IDS=()           # basename -> space-separated int: node ids
declare -A EXT_KEYS=()           # registered ext: key -> 1
declare -a EXT_KEY_LIST=()       # the same keys, LC_ALL=C ordered
declare -A SCAN_SET=()           # KB document basename -> 1
declare -a SCAN_DOCS=()          # the scan set, LC_ALL=C ordered
declare -a SOURCE_DOCS=()        # the scan set minus D2a's two generated documents
declare -a INT_PATHS=()          # every enumerated repo-relative path, for globbing
declare -a KB_NODE_ROWS=()

declare -A CONCEPT_DEFS=()       # normalised term -> \x1f-joined "<doc>\x1e<heading text>"
declare -a CONCEPT_TERMS=()      # discovery order (document order over sorted docs)
declare -A CONCEPT_TERM_SEEN=()
declare -a CONCEPT_IDS=()        # emitted concept node ids, creation order
declare -A CONCEPT_SURFACE=()    # concept id -> defining heading text, verbatim
declare -A CONCEPT_SURFACE_LC=() # concept id -> that text, lower-cased once
declare -A CONCEPT_HOME=()       # concept id -> defining document
declare -A CONCEPT_TERM=()       # concept id -> normalised term
declare -A DEF_BLOCK=()
declare -A INVERSE_CACHE=()      # relation -> its inverse, memoised
declare -A CACHE_BLOCKS=()       # doc -> rel_block_bodies output, verbatim
declare -A CACHE_SLUGS=()        # doc -> rel_doc_slugs output, verbatim
declare -A CACHE_FACTS=()        # doc -> rel_fact_records output, verbatim
declare -A CACHE_FENCE=()        # doc -> rel_fence_mask output, verbatim

# Per-document, rebuilt by hd_load_document / hd_build_regions.
declare -a DOC_LINES=()          # 1-based
declare -a DOC_LOWER=()          # 1-based, lower-cased once per document
declare -a DOC_FENCE=()          # 1-based, 0|1
declare -a LINE_SECTION=()       # 1-based, enclosing section id or ""
declare -a LINE_FACT=()          # 1-based, enclosing fact id or ""
declare -a LINE_FACT_PATH=()     # 1-based, that fact's cited path or ""
declare -a B_LEVEL=() B_MARKED=() B_START=() B_END=() B_TEXT=() B_SLUG=() B_STATE=()
declare -a F_STATUS=() F_TOKEN=() F_PATH=() F_ANCHOR=() F_START=() F_END=()
DOC_FM_END=0
DOC_N=0

CNT_DOCUMENTS=0
CNT_SECTIONS=0
CNT_FACTS=0
CNT_CONCEPTS=0
CNT_FACT_UNANCHORED=0
CNT_SECTION_EMPTY_SLUG=0
CNT_CONCEPT_QUALIFIED=0
CARRIER_HEADING=0
CARRIER_MARKER=0
CARRIER_CITATION=0

KB_ROOT=".aid/knowledge"
KB_REL=".aid/knowledge"
TEMP_DIR=".aid/.temp/graph"
REPO_ROOT=""
ROWS=""
CANDIDATES=""

# ---------------------------------------------------------------------------
# Small helpers -- `*_into` writes to a global and forks nothing, following the
# shape significance-rules.sh uses. These run once per row and once per matched
# literal, and a command substitution in either place costs a process on the Git
# Bash / MSYS host this work is authored on.
# ---------------------------------------------------------------------------

CELL_OUT=""
ANCHOR_OUT=""
NAME_OUT=""

hd_strip_cr() { printf '%s' "${1%$'\r'}"; }

# A cell bound for a TSV field and later for a markdown table: no tab, no
# newline, no CR, whitespace runs collapsed, ends trimmed. Pipe escaping belongs
# to the renderer (feature-003 D1), not here.
hd_cell_into() {
    local t="$1"
    t="${t//$'\r'/ }"
    t="${t//$'\n'/ }"
    t="${t//$'\t'/ }"
    while [ "$t" != "${t//  / }" ]; do t="${t//  / }"; done
    t="${t#"${t%%[![:space:]]*}"}"
    t="${t%"${t##*[![:space:]]}"}"
    CELL_OUT="$t"
}

# The observation anchor every class-0 row carries: a repo-relative path first,
# then a grep-recoverable literal. The leading whitespace-delimited token is a
# path, so feature-003 V11's durable-anchor predicate holds by construction
# (Feature Flow step 9), and no line number appears, so an edit above the anchor
# cannot churn the row (FR-32 mechanism 6).
hd_anchor_into() {
    hd_cell_into "$2"
    ANCHOR_OUT="${KB_REL}/${1} (search: \"${CELL_OUT}\")"
}

hd_name_into() {
    local id="$1" kind="$2"
    if [ -n "${NODE_NAME[$id]:-}" ]; then
        NAME_OUT="${NODE_NAME[$id]}"
        return 0
    fi
    NAME_OUT=$(rel_display_name "$kind" "$id") || NAME_OUT=""
    NODE_NAME["$id"]="$NAME_OUT"
}

hd_is_url() {
    case "$1" in
        [a-z]*://*)
            case "${1%%://*}" in
                *[!a-z0-9+.-]*) return 1 ;;
                *) return 0 ;;
            esac ;;
        *) return 1 ;;
    esac
}

# Token-bounded containment: the match must be preceded and followed by a
# non-alphanumeric character, a line start or a line end (feature-005 D2d).
# Both arguments arrive already folded to one case by the caller, which is what
# keeps the case-insensitive comparison fork-free.
hd_token_bounded() {
    local hay="$1" needle="$2" before after pos
    [ -n "$needle" ] || return 1
    while :; do
        case "$hay" in
            *"$needle"*) : ;;
            *) return 1 ;;
        esac
        before="${hay%%"$needle"*}"
        pos=${#before}
        after="${hay:$(( pos + ${#needle} ))}"
        if { [ "$pos" -eq 0 ] || case "${before: -1}" in [A-Za-z0-9]) false ;; *) true ;; esac; } && \
           { [ -z "$after" ] || case "${after:0:1}" in [A-Za-z0-9]) false ;; *) true ;; esac; }; then
            return 0
        fi
        hay="$after"
    done
}

# ---------------------------------------------------------------------------
# Inventory -- feature-004's two node streams, read and never re-derived.
# `node_kind` is carried as data (its field 7 / field 3), so no consumer here
# recovers a kind from an id prefix.
# ---------------------------------------------------------------------------

hd_load_inventory() {
    local nodes="$1" media="$2" id name kind path base key

    [ -f "$nodes" ] || { hd_warn "feature-004 stream not found at ${nodes}"; return 2; }
    [ -f "$media" ] || { hd_warn "feature-004 stream not found at ${media}"; return 2; }

    while IFS=$'\t' read -r id name _ _ _ _ kind || [ -n "${id:-}" ]; do
        [ -n "$id" ] || continue
        id=$(hd_strip_cr "$id"); kind=$(hd_strip_cr "$kind")
        NODE_KIND["$id"]="$kind"
        NODE_NAME["$id"]="$name"
        path="${id#int:}"
        PATH_TO_ID["$path"]="$id"
        INT_PATHS+=("$path")
        base="${path##*/}"
        BASE_IDS["$base"]="${BASE_IDS[$base]:-} $id"
    done < "$nodes"

    while IFS=$'\t' read -r id name kind _ _ || [ -n "${id:-}" ]; do
        [ -n "$id" ] || continue
        id=$(hd_strip_cr "$id"); kind=$(hd_strip_cr "$kind")
        NODE_KIND["$id"]="$kind"
        NODE_NAME["$id"]="$name"
        case "$id" in
            int:*)
                path="${id#int:}"
                PATH_TO_ID["$path"]="$id"
                INT_PATHS+=("$path")
                base="${path##*/}"
                BASE_IDS["$base"]="${BASE_IDS[$base]:-} $id"
                ;;
            ext:*) EXT_KEYS["${id#ext:}"]=1 ;;
        esac
    done < "$media"

    # Harvest kind 14's carrier is "a key the external-sources registry
    # registers", so the REGISTRY is the authority for membership and
    # feature-003's `rel_external_keys` is its one reader -- this pass never
    # parses that file and therefore holds no second copy of D2c's format. The
    # `Kind` still comes from feature-004's node record, because feature-003 D1a
    # records that an `ext:` id's image-versus-web-page distinction cannot be
    # recovered from the key; a registered key with no node record is reported and
    # skipped rather than guessed at.
    #
    # The list is ORDERED explicitly: an associative array has no defined
    # iteration order and this pass writes rows while iterating the key set, so an
    # unordered walk would make rows-pass1a.tsv differ between runs.
    while IFS= read -r key; do
        [ -n "$key" ] || continue
        EXT_KEYS["$key"]=1
        if [ -z "${NODE_KIND[ext:${key}]:-}" ]; then
            hd_warn "notice: external key '${key}' is registered but carries no media-nodes.tsv record; no edge is emitted for it"
            continue
        fi
        EXT_KEY_LIST+=("$key")
    done < <(rel_external_keys | LC_ALL=C sort)
    return 0
}

# ---------------------------------------------------------------------------
# Reference resolution -- never guesses (feature-005 D4), and reuses
# feature-004 D6's drop_reason values rather than inventing new ones.
# ---------------------------------------------------------------------------

RESOLVED_ID=""
RESOLVE_REASON=""

# Normalise a `.`/`..`-bearing reference against the KB root and confine it to
# the repository. The `..` lives in the REFERENCE TEXT; the emitted id is already
# `..`-free, which is what keeps feature-003 D2b's path-confinement rule intact
# at the one place a `..` could escape (feature-004 D5).
NORMALISED=""
hd_normalise_relative() {
    local ref="$1" seg out=""
    local -a parts=()
    local IFS='/'
    read -r -a parts <<< "${KB_REL}/${ref}"
    IFS=' '
    for seg in "${parts[@]}"; do
        case "$seg" in
            ''|'.') continue ;;
            '..')
                [ -n "$out" ] || return 1
                if [ "${out%/*}" = "$out" ]; then out=""; else out="${out%/*}"; fi
                ;;
            *) if [ -z "$out" ]; then out="$seg"; else out="${out}/${seg}"; fi ;;
        esac
    done
    [ -n "$out" ] || return 1
    NORMALISED="$out"
}

# A repo-relative path, a `./` or `../` reference resolved against the citing
# document's directory, or a bare basename resolving to exactly one surviving
# node -- which works precisely because feature-004's exclusion filter removes
# the render copies (feature-004 D5).
hd_resolve_int() {
    local ref="$1" ids count
    RESOLVED_ID=""
    RESOLVE_REASON=""
    [ -n "$ref" ] || { RESOLVE_REASON="unresolved-reference"; return 1; }
    if [ -n "${PATH_TO_ID[$ref]:-}" ]; then
        RESOLVED_ID="${PATH_TO_ID[$ref]}"
        return 0
    fi
    case "$ref" in
        ./*|../*|*/../*|*/./*)
            if hd_normalise_relative "$ref"; then
                if [ -n "${PATH_TO_ID[$NORMALISED]:-}" ]; then
                    RESOLVED_ID="${PATH_TO_ID[$NORMALISED]}"
                    return 0
                fi
            else
                RESOLVE_REASON="outside-repo-root"
                return 1
            fi ;;
    esac
    case "$ref" in
        */*)
            if hd_normalise_relative "$ref" && [ -n "${PATH_TO_ID[$NORMALISED]:-}" ]; then
                RESOLVED_ID="${PATH_TO_ID[$NORMALISED]}"
                return 0
            fi
            RESOLVE_REASON="unresolved-reference"
            return 1 ;;
    esac
    ids="${BASE_IDS[$ref]:-}"
    # shellcheck disable=SC2086  # deliberate word splitting over a space-separated list
    set -- $ids
    count=$#
    if [ "$count" -eq 1 ]; then
        RESOLVED_ID="$1"
        return 0
    fi
    if [ "$count" -gt 1 ]; then
        RESOLVE_REASON="ambiguous-basename"
        return 1
    fi
    RESOLVE_REASON="unresolved-reference"
    return 1
}

# A cited path naming a KB document. feature-004 D4 Class 4 cuts `.aid/**` from
# `int:` enumeration, so a path under the KB root cannot be a `source-artifact`
# and can only be a `document` -- which is what decides D2c's two-branch target
# without a guess.
hd_resolve_kb_doc() {
    local ref="${1#./}" base
    RESOLVED_ID=""
    base="${ref##*/}"
    [ -n "${SCAN_SET[$base]:-}" ] || return 1
    case "$ref" in
        "$base"|"${KB_REL}/${base}") RESOLVED_ID="kb:${base}"; return 0 ;;
    esac
    return 1
}

hd_candidate() {
    hd_cell_into "$1"; local subject="$CELL_OUT"
    hd_cell_into "$2"; local context="$CELL_OUT"
    printf 'edge\t%s\t%s\t%s\n' "$subject" "$context" "$3" >> "$CANDIDATES"
}

# ---------------------------------------------------------------------------
# Row emission -- one place, so the map gate, the inverse lookup and the class
# partition each exist exactly once
# ---------------------------------------------------------------------------

# hd_emit_row <harvest-kind> <src-id> <src-kind> <tgt-id> <tgt-kind> <provenance> <observation>
hd_emit_row() {
    local hk="$1" sid="$2" skind="$3" tid="$4" tkind="$5" prov="$6" obs="$7"
    local relation inverse class sname tname

    # The map's loaded tables are globals in this same shell, so they are read
    # directly rather than through `$(erm_relation ...)`: a command substitution
    # costs a process, this runs once per row, and Git Bash / MSYS charges about
    # 100 ms for each one.
    relation="${ERM_RELATION[$hk]:-}"
    if [ -z "$relation" ]; then
        hd_warn "internal: harvest kind '${hk}' carries no mapping"
        return 1
    fi
    if ! erm_admits_pair "$hk" "${skind}->${tkind}"; then
        hd_warn "internal: harvest kind '${hk}' may not emit ${skind}->${tkind}"
        return 1
    fi
    if ! erm_admits_provenance "$hk" "$prov"; then
        hd_warn "internal: harvest kind '${hk}' may not emit provenance '${prov}'"
        return 1
    fi
    # `t2s` is never chosen: it is looked up as the mapped relation's inverse, so
    # the pair is internally consistent by construction and feature-003's V4
    # cannot fire on this writer's output (D3).
    # `t2s` is looked up, never chosen, and the lookup is memoised: there are far
    # fewer relations than rows.
    inverse="${INVERSE_CACHE[$relation]:-}"
    if [ -z "$inverse" ]; then
        inverse=$(rel_inverse_of "$relation")
        INVERSE_CACHE["$relation"]="$inverse"
    fi
    case "$prov" in
        inferred) class=1 ;;
        *)        class=0 ;;
    esac
    hd_name_into "$sid" "$skind"; sname="$NAME_OUT"
    hd_name_into "$tid" "$tkind"; tname="$NAME_OUT"
    hd_cell_into "$obs"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$class" "$sid" "$skind" "$sname" "$tid" "$tkind" "$tname" \
        "$relation" "$inverse" "$prov" "$CELL_OUT" >> "$ROWS"
}

hd_add_node() {
    local id="$1" kind="$2" name="$3" doc="$4"
    NODE_KIND["$id"]="$kind"
    NODE_NAME["$id"]="$name"
    KB_NODE_ROWS+=("${id}"$'\t'"${kind}"$'\t'"${name}"$'\t'"${doc}")
}

# The finest member of the enclosing chain `fact > section > document` that the
# mapped relation admits (feature-005 D2e). The chain is uniform; THE CEILING IS
# DATA -- it is the map entry's kind-pair list, which the load-time gate has
# already proved is a subset of the relation's `endpoint_kinds`. No carve-out is
# written into this scanner, which is why `kb-image-reference` reaches `fact`
# while `kb-inline-doc-link` stops at `section` with no code saying so.
CHAIN_ID=""
CHAIN_KIND=""
hd_chain_source() {
    local hk="$1" doc="$2" lineno="$3" tkind="$4"
    local fact="${LINE_FACT[$lineno]:-}" sect="${LINE_SECTION[$lineno]:-}"
    CHAIN_ID=""; CHAIN_KIND=""
    if [ -n "$fact" ] && erm_admits_pair "$hk" "fact->${tkind}"; then
        CHAIN_ID="$fact"; CHAIN_KIND="fact"; return 0
    fi
    if [ -n "$sect" ] && erm_admits_pair "$hk" "section->${tkind}"; then
        CHAIN_ID="$sect"; CHAIN_KIND="section"; return 0
    fi
    if erm_admits_pair "$hk" "document->${tkind}"; then
        CHAIN_ID="kb:${doc}"; CHAIN_KIND="document"; return 0
    fi
    return 1
}

# ---------------------------------------------------------------------------
# Document loading and region derivation -- ONE implementation, two consumers.
#
# Phase 1 (hd_harvest_document) emits nodes and rows; phase 2 (hd_scan_mentions)
# needs the same enclosing-node map after the whole-KB concept merge has run.
# Both call hd_load_document + hd_build_regions, so the map is derived by one
# piece of code rather than by two readings of the same rule.
# ---------------------------------------------------------------------------

# The library is asked for each document ONCE. hd_build_regions has two callers --
# phase 1, which emits, and the mention scan, which needs the same enclosing-node
# map after the whole-KB concept merge -- and without this memo each of the four
# accessors would be invoked twice per document. Each invocation is a process, and
# a process costs about 100 ms on the Git Bash / MSYS host this work is authored
# on. The memo caches the library's OUTPUT; the derivation over it stays in one
# place, so no rule is duplicated by caching.
hd_memo_document() {
    local doc="$1"
    [ -z "${CACHE_BLOCKS[$doc]+set}" ] || return 0
    CACHE_BLOCKS["$doc"]=$(rel_block_bodies "$doc")
    CACHE_SLUGS["$doc"]=$(rel_doc_slugs "$doc")
    CACHE_FACTS["$doc"]=$(rel_fact_records "$doc")
    CACHE_FENCE["$doc"]=$(rel_fence_mask "$doc")
}

hd_load_document() {
    local doc="$1" path="${KB_ROOT}/${1}" line i
    DOC_LINES=("")
    DOC_LOWER=("")
    DOC_FENCE=("")
    DOC_FM_END=0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        DOC_LINES+=("$line")
        DOC_LOWER+=("${line,,}")
    done < "$path"
    DOC_N=$(( ${#DOC_LINES[@]} - 1 ))
    while IFS= read -r line; do DOC_FENCE+=("${line%$'\r'}"); done <<< "${CACHE_FENCE[$doc]}"
    for (( i=${#DOC_FENCE[@]}; i<=DOC_N; i++ )); do DOC_FENCE+=("0"); done
    # The frontmatter block is excluded from every inline-carrier scan: its
    # `see_also:` and `sources:` entries are harvest kinds 8-10 and must not be
    # counted a second time as prose citations.
    if [ "$DOC_N" -ge 1 ] && [ "${DOC_LINES[1]}" = "---" ]; then
        for (( i=2; i<=DOC_N; i++ )); do
            if [ "${DOC_LINES[$i]}" = "---" ]; then DOC_FM_END=$i; break; fi
        done
    fi
}

hd_build_regions() {
    local doc="$1" i j level marked start end text slug probe
    local status token cited anchor fstart fend
    local -a slugs=()
    local emitted=0 heading_2_6=0 cur_section=""

    B_LEVEL=(); B_MARKED=(); B_START=(); B_END=(); B_TEXT=(); B_SLUG=(); B_STATE=()
    F_STATUS=(); F_TOKEN=(); F_PATH=(); F_ANCHOR=(); F_START=(); F_END=()
    LINE_SECTION=(); LINE_FACT=(); LINE_FACT_PATH=()
    for (( i=0; i<=DOC_N; i++ )); do LINE_SECTION[$i]=""; LINE_FACT[$i]=""; LINE_FACT_PATH[$i]=""; done

    while IFS=$'\t' read -r level marked start end text; do
        [ -n "$level" ] || continue
        B_LEVEL+=("$level"); B_MARKED+=("$marked"); B_START+=("$start")
        B_END+=("$end"); B_TEXT+=("$text"); B_SLUG+=(""); B_STATE+=("skip")
        if [ "$level" -ge 2 ] && [ "$level" -le 6 ]; then
            heading_2_6=$(( heading_2_6 + 1 ))
        fi
    done <<< "${CACHE_BLOCKS[$doc]}"

    while IFS= read -r slug; do
        [ -n "$slug" ] || continue
        slugs+=("$slug")
    done <<< "${CACHE_SLUGS[$doc]}"

    # rel_doc_slugs omits exactly the headings whose slug came out empty, so the
    # two counts agreeing proves none was omitted. rel_slug_heading is consulted
    # only when they disagree -- the rule stays in the library either way, and
    # the common case costs no call at all.
    local probe_needed=0
    [ "$heading_2_6" -eq "${#slugs[@]}" ] || probe_needed=1

    for (( i=0; i<${#B_LEVEL[@]}; i++ )); do
        level="${B_LEVEL[$i]}"
        if [ "$level" -ge 2 ] && [ "$level" -le 6 ]; then
            if [ "$probe_needed" -eq 1 ]; then
                probe=$(rel_slug_heading "${B_TEXT[$i]}") || probe=""
            else
                probe="x"
            fi
            if [ -z "$probe" ]; then
                B_STATE[$i]="empty-slug"
            else
                slug="${slugs[$emitted]:-}"
                emitted=$(( emitted + 1 ))
                if [ -z "$slug" ]; then
                    hd_warn "${doc}: rel_doc_slugs returned fewer slugs than emitted headings"
                    B_STATE[$i]="empty-slug"
                else
                    B_STATE[$i]="emitted"
                    B_SLUG[$i]="$slug"
                    cur_section="kb:${doc}#${slug}"
                fi
            fi
        fi
        start="${B_START[$i]}"
        end="${B_END[$i]}"
        # The heading's own line belongs to the section it opens, or to the
        # section still current when this heading emits nothing.
        if [ "$start" -ge 2 ]; then LINE_SECTION[$(( start - 1 ))]="$cur_section"; fi
        if [ "$end" -ge "$start" ]; then
            for (( j=start; j<=end && j<=DOC_N; j++ )); do LINE_SECTION[$j]="$cur_section"; done
        fi
    done

    while IFS=$'\t' read -r status token cited anchor fstart fend; do
        [ -n "$status" ] || continue
        F_STATUS+=("$status"); F_TOKEN+=("$token"); F_PATH+=("$cited")
        F_ANCHOR+=("$anchor"); F_START+=("$fstart"); F_END+=("$fend")
        [ "$status" = "anchored" ] || continue
        for (( j=fstart; j<=fend && j<=DOC_N; j++ )); do
            LINE_FACT[$j]="kb:${doc}#fact:${token}"
            LINE_FACT_PATH[$j]="$cited"
        done
    done <<< "${CACHE_FACTS[$doc]}"
}

# ---------------------------------------------------------------------------
# Phase 1 -- nodes, containment, facts, frontmatter and inline carriers
# ---------------------------------------------------------------------------

hd_harvest_document() {
    local doc="$1" i j level text sec_id fact_id parent_id key
    local -a stack_level=() stack_id=()
    local depth=0

    hd_memo_document "$doc"
    hd_load_document "$doc"
    hd_build_regions "$doc"

    for (( i=0; i<${#B_LEVEL[@]}; i++ )); do
        level="${B_LEVEL[$i]}"
        text="${B_TEXT[$i]}"
        if [ "$level" -ge 2 ] && [ "$level" -le 6 ]; then
            CARRIER_HEADING=1
        fi
        case "${B_STATE[$i]}" in
            empty-slug)
                CNT_SECTION_EMPTY_SLUG=$(( CNT_SECTION_EMPTY_SLUG + 1 ))
                ;;
            emitted)
                sec_id="kb:${doc}#${B_SLUG[$i]}"
                hd_name_into "$sec_id" "section"
                hd_add_node "$sec_id" "section" "$NAME_OUT" "$doc"
                CNT_SECTIONS=$(( CNT_SECTIONS + 1 ))
                # Containment by LEVEL STACK. This is a different computation
                # from the block body and the two are never unified: D2a-3a's
                # body ends at the next heading of ANY level, while a section's
                # parent is the nearest preceding emitted heading of a SHALLOWER
                # level (D2b). Reusing the body scan here would attach a level-4
                # heading to a preceding level-5.
                while [ "$depth" -gt 0 ] && [ "${stack_level[$(( depth - 1 ))]}" -ge "$level" ]; do
                    depth=$(( depth - 1 ))
                done
                hd_anchor_into "$doc" "$text"
                if [ "$depth" -gt 0 ]; then
                    parent_id="${stack_id[$(( depth - 1 ))]}"
                    hd_emit_row "kb-section-section" "$parent_id" "section" "$sec_id" "section" \
                        "derived" "$ANCHOR_OUT"
                else
                    hd_emit_row "kb-doc-section" "kb:${doc}" "document" "$sec_id" "section" \
                        "derived" "$ANCHOR_OUT"
                fi
                stack_level[$depth]="$level"
                stack_id[$depth]="$sec_id"
                depth=$(( depth + 1 ))
                ;;
        esac
        if [ "$level" -ge 3 ] && [ "${B_MARKED[$i]}" = "1" ]; then
            CARRIER_MARKER=1
            hd_record_definition "$doc" "$text" "$(( ${B_START[$i]} - 1 ))" "${B_END[$i]}"
        fi
    done

    for (( i=0; i<${#F_STATUS[@]}; i++ )); do
        CARRIER_CITATION=1
        if [ "${F_STATUS[$i]}" != "anchored" ]; then
            CNT_FACT_UNANCHORED=$(( CNT_FACT_UNANCHORED + 1 ))
            continue
        fi
        fact_id="kb:${doc}#fact:${F_TOKEN[$i]}"
        hd_name_into "$fact_id" "fact"
        hd_add_node "$fact_id" "fact" "$NAME_OUT" "$doc"
        CNT_FACTS=$(( CNT_FACTS + 1 ))
        j="${F_START[$i]}"
        hd_anchor_into "$doc" "${F_ANCHOR[$i]}"
        sec_id="${LINE_SECTION[$j]:-}"
        if [ -n "$sec_id" ]; then
            hd_emit_row "kb-section-fact" "$sec_id" "section" "$fact_id" "fact" "derived" "$ANCHOR_OUT"
        else
            hd_emit_row "kb-doc-fact" "kb:${doc}" "document" "$fact_id" "fact" "derived" "$ANCHOR_OUT"
        fi
        hd_fact_anchor_edge "$doc" "$fact_id" "${F_PATH[$i]}" "${F_ANCHOR[$i]}"
    done

    hd_scan_frontmatter "$doc"
    hd_scan_inline "$doc"

    # Harvest kind 14 -- a prose citation of a registered `ext:` key, driven from
    # the registered key set outward so an unregistered key is not a reference
    # this pass can see at all.
    for key in "${EXT_KEY_LIST[@]:-}"; do
        [ -n "$key" ] || continue
        for (( i=1; i<=DOC_N; i++ )); do
            [ "$i" -gt "$DOC_FM_END" ] || continue
            [ "${DOC_FENCE[$i]}" = "0" ] || continue
            hd_token_bounded "${DOC_LINES[$i]}" "$key" || continue
            hd_chain_source "kb-ext-key-citation" "$doc" "$i" "${NODE_KIND[ext:${key}]}" || continue
            hd_anchor_into "$doc" "$key"
            hd_emit_row "kb-ext-key-citation" "$CHAIN_ID" "$CHAIN_KIND" "ext:${key}" \
                "${NODE_KIND[ext:${key}]}" "declared" "$ANCHOR_OUT"
        done
    done
}

# Harvest kind 5. One rule with a two-branch target, the branch decided by where
# the cited path lives (D2c). A path resolving to neither becomes a candidate,
# never a row.
hd_fact_anchor_edge() {
    local doc="$1" fact_id="$2" cited="$3" anchor="$4"
    [ -n "$cited" ] || return 0
    hd_anchor_into "$doc" "$anchor"
    if hd_resolve_kb_doc "$cited"; then
        hd_emit_row "kb-fact-anchor" "$fact_id" "fact" "$RESOLVED_ID" "document" "declared" "$ANCHOR_OUT"
        return 0
    fi
    if hd_resolve_int "$cited"; then
        hd_emit_row "kb-fact-anchor" "$fact_id" "fact" "$RESOLVED_ID" \
            "${NODE_KIND[$RESOLVED_ID]}" "declared" "$ANCHOR_OUT"
        return 0
    fi
    hd_candidate "$cited" "kb-fact-anchor in ${KB_REL}/${doc}" "$RESOLVE_REASON"
}

hd_record_definition() {
    local doc="$1" text="$2" bstart="$3" bend="$4" term key
    term=$(rel_normalise_term "$text") || term=""
    [ -n "$term" ] || return 0
    if [ -z "${CONCEPT_TERM_SEEN[$term]:-}" ]; then
        CONCEPT_TERM_SEEN["$term"]=1
        CONCEPT_TERMS+=("$term")
    fi
    CONCEPT_DEFS["$term"]="${CONCEPT_DEFS[$term]:-}${doc}"$'\x1e'"${text}"$'\x1f'
    key="${doc}"$'\x1f'"${term}"
    DEF_BLOCK["$key"]="${DEF_BLOCK[$key]:-}${bstart} ${bend} "
}

# ---------------------------------------------------------------------------
# Harvest kinds 8-10 -- frontmatter, one batched awk pass per document (the
# pattern lint-frontmatter.sh `load_frontmatter` and kb-freshness-check.sh
# `fm_scalar`/`fm_list` establish: arrays populated in one pass, no per-field
# fork -- a deliberate Windows-Git-Bash fork-cost optimisation)
# ---------------------------------------------------------------------------

hd_scan_frontmatter() {
    local doc="$1" field value entry frag doc_part
    while IFS=$'\t' read -r field value; do
        [ -n "$field" ] || continue
        hd_cell_into "$value"
        entry="$CELL_OUT"
        [ -n "$entry" ] || continue
        case "$field" in
            see_also)
                # An entry is split at `#` and only the document part is
                # resolved; the fragment -- which frontmatter-schema.md permits
                # without endorsing -- is carried in the Observation and drives
                # no section-level edge (D4 kind 8, Open Item 15).
                doc_part="$entry"
                frag=""
                case "$entry" in *'#'*) doc_part="${entry%%#*}"; frag="${entry#*#}" ;; esac
                hd_anchor_into "$doc" "$entry"
                if hd_resolve_kb_doc "$doc_part"; then
                    hd_emit_row "frontmatter-see-also" "kb:${doc}" "document" "$RESOLVED_ID" \
                        "document" "declared" "$ANCHOR_OUT"
                else
                    hd_candidate "$entry" "frontmatter-see-also in ${KB_REL}/${doc}" "unresolved-reference"
                fi
                ;;
            sources)
                hd_anchor_into "$doc" "$entry"
                if hd_is_url "$entry"; then
                    if [ -n "${EXT_KEYS[$entry]:-}" ]; then
                        hd_emit_row "frontmatter-sources-url" "kb:${doc}" "document" "ext:${entry}" \
                            "${NODE_KIND[ext:${entry}]}" "declared" "$ANCHOR_OUT"
                    else
                        hd_candidate "$entry" "frontmatter-sources-url in ${KB_REL}/${doc}" "unresolved-reference"
                    fi
                    continue
                fi
                case "$entry" in
                    *'*'*|*'?'*)
                        hd_emit_sources_glob "$doc" "$entry" || \
                            hd_candidate "$entry" "frontmatter-sources-path in ${KB_REL}/${doc}" "unresolved-reference"
                        ;;
                    *)
                        # AC-S8: provenance is keyed on the STATEMENT, so a bare
                        # basename that required resolution still emits
                        # `declared`. Generalising feature-001 D6c's
                        # resolution-keyed rule to this carrier would emit
                        # `derived`, which `documents` does not admit.
                        if hd_resolve_int "$entry"; then
                            hd_emit_row "frontmatter-sources-path" "kb:${doc}" "document" "$RESOLVED_ID" \
                                "${NODE_KIND[$RESOLVED_ID]}" "declared" "$ANCHOR_OUT"
                        else
                            hd_candidate "$entry" "frontmatter-sources-path in ${KB_REL}/${doc}" "$RESOLVE_REASON"
                        fi
                        ;;
                esac
                ;;
        esac
    done < <(hd_frontmatter_fields "${KB_ROOT}/${doc}")
}

# A `sources:` glob is expanded against feature-004's stream and each match
# becomes an edge; a glob matching nothing becomes a candidate (D4).
hd_emit_sources_glob() {
    local doc="$1" pattern="$2" p id hit=1
    for p in "${INT_PATHS[@]:-}"; do
        [ -n "$p" ] || continue
        # shellcheck disable=SC2053  # deliberate glob match, not a literal compare
        if [[ $p == $pattern ]]; then
            id="${PATH_TO_ID[$p]}"
            hd_emit_row "frontmatter-sources-path" "kb:${doc}" "document" "$id" \
                "${NODE_KIND[$id]}" "declared" "$ANCHOR_OUT"
            hit=0
        fi
    done
    return $hit
}

hd_frontmatter_fields() {
    awk '
        function emit(k, v) {
            gsub(/^[ \t]+|[ \t]+$/, "", v)
            gsub(/^"|"$/, "", v)
            if (v != "") printf "%s\t%s\n", k, v
        }
        NR == 1 { sub(/\r$/, "", $0); if ($0 != "---") exit; infm = 1; next }
        { sub(/\r$/, "", $0) }
        infm && $0 == "---" { exit }
        !infm { exit }
        {
            if ($0 ~ /^(see_also|sources):[ \t]*\[/) {
                key = $0; sub(/:.*$/, "", key)
                body = $0; sub(/^[^[]*\[/, "", body); sub(/\].*$/, "", body)
                nf = split(body, parts, ",")
                for (i = 1; i <= nf; i++) emit(key, parts[i])
                cur = ""
                next
            }
            if ($0 ~ /^(see_also|sources):[ \t]*$/) { cur = $0; sub(/:.*$/, "", cur); next }
            if ($0 ~ /^[A-Za-z_][A-Za-z0-9_-]*:/) { cur = ""; next }
            if (cur != "" && $0 ~ /^[ \t]*-[ \t]+/) {
                item = $0
                sub(/^[ \t]*-[ \t]+/, "", item)
                emit(cur, item)
            }
        }
    ' "$1"
}

# ---------------------------------------------------------------------------
# Harvest kinds 11-13 -- the inline carriers, one batched awk pass per document
# ---------------------------------------------------------------------------

hd_scan_inline() {
    local doc="$1" i tag lineno value
    local -a eligible=()

    for (( i=1; i<=DOC_N; i++ )); do
        [ "$i" -gt "$DOC_FM_END" ] || continue
        [ "${DOC_FENCE[$i]}" = "0" ] || continue
        eligible+=("${i}"$'\t'"${DOC_LINES[$i]}")
    done
    [ "${#eligible[@]}" -gt 0 ] || return 0

    while IFS=$'\t' read -r tag lineno value; do
        [ -n "$tag" ] || continue
        case "$tag" in
            link) hd_carrier_link  "$doc" "$lineno" "$value" ;;
            img)  hd_carrier_image "$doc" "$lineno" "$value" 1 ;;
            html) hd_carrier_image "$doc" "$lineno" "$value" 0 ;;
            path) hd_carrier_path  "$doc" "$lineno" "$value" ;;
        esac
    done < <(printf '%s\n' "${eligible[@]}" | hd_inline_awk)
}

# Harvest kind 12, whose ceiling D2e reads out of the map: `mentions` declares
# `document->document` and `section->document` but no `fact->document`, so a doc
# link inside a fact's anchor block attributes to the enclosing section. A link
# target that is NOT a KB document is a path citation written in link syntax and
# is handed to kind 11, so nothing is silently dropped by the span exclusion.
hd_carrier_link() {
    # Two statements, not one: `local a="$1" b="$a"` declares every name local
    # before performing the assignments, so `b` would read an unset local.
    local doc="$1" lineno="$2" target="$3"
    local doc_part="$target"
    hd_is_url "$target" && return 0
    case "$target" in
        '#'*) return 0 ;;
        *'#'*) doc_part="${target%%#*}" ;;
    esac
    [ -n "$doc_part" ] || return 0
    if hd_resolve_kb_doc "$doc_part"; then
        hd_chain_source "kb-inline-doc-link" "$doc" "$lineno" "document" || return 0
        hd_anchor_into "$doc" "$target"
        hd_emit_row "kb-inline-doc-link" "$CHAIN_ID" "$CHAIN_KIND" "$RESOLVED_ID" "document" \
            "declared" "$ANCHOR_OUT"
        return 0
    fi
    hd_carrier_path "$doc" "$lineno" "$doc_part"
}

# Harvest kind 13. <strict> is 1 for markdown image syntax, which ASSERTS an
# image and therefore yields a candidate when it does not resolve, and 0 for an
# HTML `src`/`href`, which asserts nothing of the sort: an unresolved `href` is
# ordinarily a link or a URL, and reporting each as a dropped image reference
# would bury the real ones.
hd_carrier_image() {
    local doc="$1" lineno="$2" ref="$3" strict="$4" tkind prov
    hd_is_url "$ref" && return 0
    case "$ref" in '#'*) return 0 ;; esac
    if ! hd_resolve_int "$ref"; then
        [ "$strict" -eq 1 ] && hd_candidate "$ref" "kb-image-reference in ${KB_REL}/${doc}" "$RESOLVE_REASON"
        return 0
    fi
    tkind="${NODE_KIND[$RESOLVED_ID]}"
    [ "$tkind" = "image" ] || return 0
    # feature-001 D6c, honoured for harvest kinds 13 and 19 and nowhere else: an
    # illustration row is `derived` where the target was reached by basename or
    # relative-path resolution rather than by a literal full path.
    if [ "${RESOLVED_ID#int:}" = "$ref" ]; then prov="declared"; else prov="derived"; fi
    hd_chain_source "kb-image-reference" "$doc" "$lineno" "$tkind" || return 0
    hd_anchor_into "$doc" "$ref"
    hd_emit_row "kb-image-reference" "$CHAIN_ID" "$CHAIN_KIND" "$RESOLVED_ID" "$tkind" \
        "$prov" "$ANCHOR_OUT"
}

# Harvest kind 11. A path that IS the anchor of the fact enclosing this line is
# already harvest kind 5's edge, so it is not harvested twice -- which is D4's
# "not part of a well-formed anchor", applied to the cited path itself rather
# than to the whole anchor block, so an unrelated citation inside the block is
# still harvested.
hd_carrier_path() {
    local doc="$1" lineno="$2" ref="$3" tkind
    [ "${LINE_FACT_PATH[$lineno]:-}" = "$ref" ] && return 0
    hd_resolve_kb_doc "$ref" && return 0
    if ! hd_resolve_int "$ref"; then
        hd_candidate "$ref" "kb-inline-path-citation in ${KB_REL}/${doc}" "$RESOLVE_REASON"
        return 0
    fi
    tkind="${NODE_KIND[$RESOLVED_ID]}"
    [ "$tkind" = "source-artifact" ] || return 0
    hd_chain_source "kb-inline-path-citation" "$doc" "$lineno" "$tkind" || return 0
    hd_anchor_into "$doc" "$ref"
    hd_emit_row "kb-inline-path-citation" "$CHAIN_ID" "$CHAIN_KIND" "$RESOLVED_ID" "$tkind" \
        "declared" "$ANCHOR_OUT"
}

# One pass over the eligible lines. Link and image targets are consumed first and
# their spans removed before path citations are matched, so one occurrence is
# attributed to exactly one carrier -- the same longest-form-wins discipline
# feature-004 D5 applies to its own literals. The character class and extension
# set are the ones kb-citation-lint.sh already uses (D4 kind 11).
hd_inline_awk() {
    awk '
        {
            t = index($0, "\t")
            ln = substr($0, 1, t - 1)
            s  = substr($0, t + 1)

            buf = s
            plain = ""
            while (match(buf, /!?\[[^]]*\]\([^)]*\)/)) {
                plain = plain substr(buf, 1, RSTART - 1) " "
                tok = substr(buf, RSTART, RLENGTH)
                p = index(tok, "](")
                target = substr(tok, p + 2, length(tok) - p - 2)
                sub(/[ \t]+"[^"]*"$/, "", target)
                gsub(/^[ \t]+|[ \t]+$/, "", target)
                if (target != "") {
                    if (substr(tok, 1, 1) == "!") printf "img\t%s\t%s\n", ln, target
                    else printf "link\t%s\t%s\n", ln, target
                }
                buf = substr(buf, RSTART + RLENGTH)
            }
            plain = plain buf

            h = s
            while (match(h, /(src|href)[ \t]*=[ \t]*"[^"]*"/)) {
                tok = substr(h, RSTART, RLENGTH)
                q = index(tok, "\"")
                target = substr(tok, q + 1, length(tok) - q - 1)
                if (target != "") printf "html\t%s\t%s\n", ln, target
                h = substr(h, RSTART + RLENGTH)
            }
            h = s
            while (match(h, /(src|href)[ \t]*=[ \t]*'"'"'[^'"'"']*'"'"'/)) {
                tok = substr(h, RSTART, RLENGTH)
                q = index(tok, "'"'"'")
                target = substr(tok, q + 1, length(tok) - q - 1)
                if (target != "") printf "html\t%s\t%s\n", ln, target
                h = substr(h, RSTART + RLENGTH)
            }

            while (match(plain, /[A-Za-z0-9_.\/-]+\.(md|sh|py|mjs|js|ts|yml|yaml|json|toml|txt|ps1)/)) {
                tok = substr(plain, RSTART, RLENGTH)
                after = substr(plain, RSTART + RLENGTH, 1)
                if (after !~ /[A-Za-z0-9]/) printf "path\t%s\t%s\n", ln, tok
                plain = substr(plain, RSTART + RLENGTH)
            }
        }
    '
}

# ---------------------------------------------------------------------------
# Step 8 -- the concept merge, and harvest kinds 6-7
# ---------------------------------------------------------------------------

# The merge point. It follows the per-document scan of EVERY document, because
# the plain-versus-qualified decision is a property of the whole KB and not of
# one file. Identity is the normalised term, so a term defined once and named in
# five documents is ONE node reached by five edges (Q13, AC-S2).
hd_resolve_concepts() {
    local term entry doc text defs count id
    local -a pairs=()

    for term in "${CONCEPT_TERMS[@]:-}"; do
        [ -n "$term" ] || continue
        pairs=()
        local IFS=$'\x1f'
        read -r -a pairs <<< "${CONCEPT_DEFS[$term]}"
        IFS=' '

        defs=0
        for entry in "${pairs[@]}"; do
            [ -n "$entry" ] && defs=$(( defs + 1 ))
        done
        [ "$defs" -ge 1 ] || continue

        # Resolution is feature-003's. rel_concept_defs decides how many
        # definitions the KB carries, and the exactly-one rule is what forces the
        # `@<doc>` form mechanically rather than by instruction; the count comes
        # from the library so writer and validator (V2) cannot disagree. Only the
        # definitions THIS pass harvested become nodes, which is what keeps D2a's
        # two excluded generated documents from minting one.
        count=$( { rel_concept_defs "$term" || true; } | grep -c . || true )
        [ -n "$count" ] || count=0
        if [ "$count" -lt "$defs" ]; then
            count="$defs"
        fi

        for entry in "${pairs[@]}"; do
            [ -n "$entry" ] || continue
            doc="${entry%%$'\x1e'*}"
            text="${entry#*$'\x1e'}"
            if [ "$count" -eq 1 ]; then
                id="kb:concept:${term}"
            else
                id="kb:concept:${term}@${doc}"
            fi
            if [ -z "${NODE_KIND[$id]:-}" ]; then
                hd_name_into "$id" "concept"
                [ -n "$NAME_OUT" ] || NAME_OUT="$text"
                NODE_NAME["$id"]="$NAME_OUT"
                hd_add_node "$id" "concept" "$NAME_OUT" ""
                CNT_CONCEPTS=$(( CNT_CONCEPTS + 1 ))
                CONCEPT_IDS+=("$id")
                CONCEPT_SURFACE["$id"]="$text"
                CONCEPT_SURFACE_LC["$id"]="${text,,}"
                CONCEPT_HOME["$id"]="$doc"
                CONCEPT_TERM["$id"]="$term"
                [ "$count" -eq 1 ] || CNT_CONCEPT_QUALIFIED=$(( CNT_CONCEPT_QUALIFIED + 1 ))
            fi
            # FR-30's declared edge from each DEFINING DOCUMENT. The
            # section-level alternative is not adopted (D2d): one definition edge
            # per (document, concept) keeps degree meaningful under Q13, and the
            # defining heading is not lost -- it is the Observation anchor.
            hd_anchor_into "$doc" "$text"
            hd_emit_row "kb-concept-definition" "kb:${doc}" "document" "$id" "concept" \
                "declared" "$ANCHOR_OUT"
        done
    done
}

# Harvest kind 7. Detection runs FROM THE NODE SET OUTWARD -- for each concept
# that exists, find its occurrences -- so a term nobody defined can never produce
# a mention edge with no node at its end, and there is no unmatched-term residue
# to account for (D2d). The matchable surface is the defining heading's text
# verbatim and nothing else; the `**Aliases:**` line is declined on FR-8a
# grounds, because the shipped glossary template does not define it.
hd_scan_mentions() {
    local doc id i surface home key ranges s e skip
    [ "${#CONCEPT_IDS[@]}" -gt 0 ] || return 0
    for doc in "${SOURCE_DOCS[@]}"; do
        hd_memo_document "$doc"
        hd_load_document "$doc"
        hd_build_regions "$doc"
        for id in "${CONCEPT_IDS[@]}"; do
            surface="${CONCEPT_SURFACE_LC[$id]}"
            home="${CONCEPT_HOME[$id]}"
            ranges=""
            if [ "$home" = "$doc" ]; then
                key="${doc}"$'\x1f'"${CONCEPT_TERM[$id]}"
                ranges="${DEF_BLOCK[$key]:-}"
            fi
            for (( i=1; i<=DOC_N; i++ )); do
                [ "$i" -gt "$DOC_FM_END" ] || continue
                [ "${DOC_FENCE[$i]}" = "0" ] || continue
                hd_token_bounded "${DOC_LOWER[$i]}" "$surface" || continue
                if [ -n "$ranges" ]; then
                    skip=0
                    # shellcheck disable=SC2086  # deliberate word splitting: "s e s e ..."
                    set -- $ranges
                    while [ $# -ge 2 ]; do
                        s="$1"; e="$2"; shift 2
                        if [ "$i" -ge "$s" ] && [ "$i" -le "$e" ]; then skip=1; break; fi
                    done
                    [ "$skip" -eq 0 ] || continue
                fi
                hd_chain_source "kb-concept-mention" "$doc" "$i" "concept" || continue
                hd_anchor_into "$doc" "${CONCEPT_SURFACE[$id]}"
                hd_emit_row "kb-concept-mention" "$CHAIN_ID" "$CHAIN_KIND" "$id" "concept" \
                    "derived" "$ANCHOR_OUT"
            done
        done
    done
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

hd_write_kb_nodes() {
    if [ "${#KB_NODE_ROWS[@]}" -eq 0 ]; then
        : > "${TEMP_DIR}/kb-nodes.tsv"
        return 0
    fi
    printf '%s\n' "${KB_NODE_ROWS[@]}" | LC_ALL=C sort -t$'\t' -k1,1 > "${TEMP_DIR}/kb-nodes.tsv"
}

hd_write_stats() {
    {
        printf 'documents\t%s\n'          "$CNT_DOCUMENTS"
        printf 'sections\t%s\n'           "$CNT_SECTIONS"
        printf 'facts\t%s\n'              "$CNT_FACTS"
        printf 'concepts\t%s\n'           "$CNT_CONCEPTS"
        printf 'fact-unanchored\t%s\n'    "$CNT_FACT_UNANCHORED"
        printf 'section-empty-slug\t%s\n' "$CNT_SECTION_EMPTY_SLUG"
        printf 'concept-qualified\t%s\n'  "$CNT_CONCEPT_QUALIFIED"
        printf 'carrier-document\t%s\n'   "$( [ "$CNT_DOCUMENTS" -gt 0 ] && echo 1 || echo 0 )"
        printf 'carrier-section\t%s\n'    "$CARRIER_HEADING"
        printf 'carrier-concept\t%s\n'    "$CARRIER_MARKER"
        printf 'carrier-fact\t%s\n'       "$CARRIER_CITATION"
    } > "${TEMP_DIR}/kb-stats.tsv"
}

# D6 part 1: Pass 2's inputs are fixed BEFORE it starts, so the set is finite,
# known up front, and its size is reportable before the pass runs. One
# `document` row per manifest document is what the read ledger is compared
# against in the completion check.
hd_write_pass2_inputs() {
    local doc
    {
        for doc in "${SOURCE_DOCS[@]}"; do
            printf 'document\t%s\n' "${KB_REL}/${doc}"
        done
        printf 'inventory\t%s\n' "${TEMP_DIR}/kb-nodes.tsv"
        printf 'inventory\t%s\n' "${TEMP_DIR}/nodes.tsv"
        printf 'inventory\t%s\n' "${TEMP_DIR}/media-nodes.tsv"
    } > "${TEMP_DIR}/pass2-inputs.tsv"
}

hd_relative_to_root() {
    local abs root
    abs=$(cd -- "$1" 2>/dev/null && pwd) || { printf '%s' "$1"; return 0; }
    root=$(cd -- "$REPO_ROOT" 2>/dev/null && pwd) || { printf '%s' "$1"; return 0; }
    case "$abs" in
        "$root")   printf '%s' "." ;;
        "$root"/*) printf '%s' "${abs#"$root"/}" ;;
        *)         printf '%s' "$1" ;;
    esac
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

hd_help() { sed -n '2,/^$/p' "$0" | sed -e 's/^#$//' -e 's/^# //'; }

HD_HELP=0

hd_parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) HD_HELP=1; return 0 ;;
            --kb-root)              KB_ROOT="${2:-}"; shift 2 ;;
            --temp-dir)             TEMP_DIR="${2:-}"; shift 2 ;;
            --repo-root)            REPO_ROOT="${2:-}"; shift 2 ;;
            --schema)               GRAPH_SCHEMA="${2:-}"; shift 2 ;;
            --vocabulary)           GRAPH_VOCAB="${2:-}"; shift 2 ;;
            --vocabulary-extension) GRAPH_VOCAB_EXT="${2:-}"; shift 2 ;;
            --edge-map)             GRAPH_EDGE_MAP="${2:-}"; shift 2 ;;
            --lib)                  GRAPH_LIB="${2:-}"; shift 2 ;;
            *) hd_warn "unknown option '$1'"; return 2 ;;
        esac
    done

    graph_require_path --schema "$GRAPH_SCHEMA" || return 2
    graph_require_path --vocabulary "$GRAPH_VOCAB" || return 2
    graph_require_path --edge-map "$GRAPH_EDGE_MAP" || return 2
    graph_require_library "$GRAPH_LIB" || return 2
    [ -d "$KB_ROOT" ] || { hd_warn "KB root not found at ${KB_ROOT}"; return 2; }

    if [ -z "$REPO_ROOT" ]; then
        REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT="$PWD"
    fi
    KB_REL=$(hd_relative_to_root "$KB_ROOT")
    return 0
}

hd_run() {
    local f doc rows_n cand_n

    graph_require_functions rel_fence_mask rel_block_bodies rel_doc_slugs rel_slug_heading rel_fact_records rel_normalise_term rel_concept_defs rel_display_name rel_kb_docs rel_external_keys || return 2

    mkdir -p -- "$TEMP_DIR" || { hd_warn "cannot create ${TEMP_DIR}"; return 1; }
    ROWS="${TEMP_DIR}/rows-pass1a.tsv"
    CANDIDATES="${TEMP_DIR}/candidates-pass1a.tsv"
    : > "$ROWS"
    : > "$CANDIDATES"

    hd_load_inventory "${TEMP_DIR}/nodes.tsv" "${TEMP_DIR}/media-nodes.tsv" || return 2

    # R1: the scan set is feature-003 D2a's membership predicate, consumed as a
    # SET -- the `find` predicates select the same set under any locale. The
    # ORDER below is this feature's own LC_ALL=C sort (FR-32 mechanism 5) and is
    # never inherited from build-kb-index.sh's bare `sort`.
    while IFS= read -r doc; do
        [ -n "$doc" ] || continue
        SCAN_DOCS+=("$doc")
        SCAN_SET["$doc"]=1
    done < <(rel_kb_docs)

    # R2 / D2a: two generated documents are excluded as SOURCES of sub-document
    # nodes and of edges, and both remain valid TARGETS -- they stay `document`
    # nodes, because membership is feature-003's predicate and diverging from it
    # would break AC-18. The test is a two-name literal, total whether or not
    # either file exists.
    for doc in "${SCAN_DOCS[@]:-}"; do
        [ -n "$doc" ] || continue
        CNT_DOCUMENTS=$(( CNT_DOCUMENTS + 1 ))
        hd_name_into "kb:${doc}" "document"
        hd_add_node "kb:${doc}" "document" "$NAME_OUT" "$doc"
        case "$doc" in
            relationships.md|INDEX.md) continue ;;
        esac
        SOURCE_DOCS+=("$doc")
    done

    for doc in "${SOURCE_DOCS[@]:-}"; do
        [ -n "$doc" ] && hd_harvest_document "$doc"
    done

    hd_resolve_concepts
    hd_scan_mentions

    hd_write_kb_nodes
    hd_write_stats
    hd_write_pass2_inputs

    rows_n=$(grep -c . "$ROWS" || true)
    cand_n=$(grep -c . "$CANDIDATES" || true)
    printf '[harvest] %s documents | %s sections | %s facts | %s concepts | %s rows | %s candidates\n' \
        "$CNT_DOCUMENTS" "$CNT_SECTIONS" "$CNT_FACTS" "$CNT_CONCEPTS" "$rows_n" "$cand_n"
    return 0
}

# Top level, never inside a function: a `.` executed inside a function makes the
# sourced file's own `declare` statements FUNCTION-LOCAL, so the library's loaded
# schema and vocabulary would vanish on return (see graph_load_context).
graph_default_paths "$HD_SCRIPT_DIR"
hd_parse_args "$@" || exit $?
if [ "$HD_HELP" = "1" ]; then hd_help; exit 0; fi
# shellcheck disable=SC1090  # resolved at run time, by design
. "$GRAPH_LIB" || { hd_warn "cannot source ${GRAPH_LIB}"; exit 2; }
graph_load_context "$GRAPH_SCHEMA" "$GRAPH_VOCAB" "$GRAPH_VOCAB_EXT" "$GRAPH_EDGE_MAP" || exit 2
hd_run
exit $?
