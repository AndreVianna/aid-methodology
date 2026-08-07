#!/usr/bin/env bash
# build-relationships.sh - merge, freeze, bound, render and self-validate.
#
# Purpose:
#   Feature Flow steps 11-16 of feature-005. This is the `generator:` value in
#   feature-003 D8's frontmatter and the only writer of
#   `.aid/knowledge/relationships.md`:
#
#     11   merge Pass 1a's and Pass 1b's rows, normalise every one with
#          feature-003 `rel_normalise_row`, key with `rel_row_key`, de-duplicate
#          by a TOTAL rule, sort by `rel_sort_key` under LC_ALL=C, and freeze the
#          class-0 block
#     11a  compute the D2f false-merge candidate report over the frozen set --
#          advisory, gating nothing, with AC-S7a's four reach counters
#     13   apply D6's four rejections to Pass 2's returned rows and merge class 1
#     14   the completion check (D6 part 4) -- a shortfall exits 1 AFTER the
#          artifact is written, naming every item
#     15   render the ten-column table, then run feature-010's
#          assemble-coverage-notes.sh over this feature's own kb-coverage.tsv
#          (D7) and feature-004's coverage.tsv and render its output VERBATIM as
#          the `## Coverage notes` section -- this script composes none of that
#          section's content itself (feature-010 D7, Open Item 7)
#     16   self-validate with feature-003's validate-relationships.sh
#
#   Ordering, keying and normalisation are reached through feature-003 D9 and are
#   NOT reimplemented here, so writer and validator cannot disagree about where a
#   row sorts or whether two rows are the same relationship. No relation label
#   appears anywhere in this file: the two labels D2f's predicate needs are read
#   from the edge-relation map (feature-005 R8).
#
# Usage:
#   build-relationships.sh [options]
#
# Options:
#   --temp-dir <dir>               scratch directory holding every input stream
#                                  (default: .aid/.temp/graph)
#   --out <file>                   the artifact
#                                  (default: .aid/knowledge/relationships.md)
#   --coverage <file>              feature-004 D7's coverage contribution, passed through
#                                  unread to the coverage-notes assembler
#                                  (default: <temp-dir>/coverage.tsv)
#   --schema <file>                relationship-schema.yml
#                                  (default: <aid-root>/templates/graph/relationship-schema.yml)
#   --vocabulary <file>            core relation-vocabulary.yml (same default directory)
#   --vocabulary-extension <file>  project extension
#                                  (default: .aid/graph/relation-vocabulary.yml; absent is not an error)
#   --edge-map <file>              edge-relation-map.yml (same default directory)
#   --lib <file>                   feature-003's relationship-schema.sh
#                                  (default: alongside this script)
#   --validator <file>             feature-003's validate-relationships.sh
#                                  (default: alongside this script; step 16 is
#                                  skipped with a notice when it is absent)
#   --assembler <file>             feature-010's assemble-coverage-notes.sh
#                                  (default: alongside this script; UNLIKE --validator,
#                                  step 15's hand-off is never skipped when this is
#                                  absent -- a missing, failing, empty or truncated
#                                  hand-off aborts the run with nothing written)
#   --skip-validate                do not run step 16 even when the validator exists
#   -h, --help                     print this header
#
# Inputs (all under <temp-dir> unless a flag overrides):
#   rows-pass1a.tsv    rows-pass1b.tsv        the two class-0 row streams
#   rows-class1.tsv                           Pass 2's returned rows (optional)
#   dispositions.tsv                          candidate_key | disposition | reason (optional)
#   pass2-inputs.tsv                          the Pass-2 manifest (D6 part 1)
#   pass2-reads.tsv                           the read ledger; ABSENT means Pass 2 was
#                                             never dispatched, which is the one
#                                             degradation case and not a shortfall
#   kb-nodes.tsv  nodes.tsv  media-nodes.tsv  the closed node set the merge tests against
#   candidates.tsv  candidates-pass1a.tsv  candidates-pass1b.tsv
#   kb-stats.tsv                              Pass 1a's counters
#   coverage.tsv                              feature-004 D7's contribution
#
# Outputs:
#   <out>                                     the artifact (the only write outside <temp-dir>)
#   <temp-dir>/rows-class0.tsv                the frozen class-0 rows, in D7 order
#   <temp-dir>/rows-class1-accepted.tsv       the class-1 rows that survived D6
#   <temp-dir>/kb-coverage.tsv                this feature's D7 coverage contribution
#   <temp-dir>/coverage-notes.md              feature-010's assembled `## Coverage notes`
#                                             hand-off (feature-010 D7, Open Item 7) --
#                                             produced by running --assembler over the
#                                             line above and --coverage, then rendered
#                                             into <out> VERBATIM
#   <temp-dir>/concept-merge-candidates.tsv   D2f's advisory candidate list
#   <temp-dir>/dispositions.tsv               appended to for every rejected class-1 row
#
# Exit codes:
#   0 - success
#   1 - a write failure, a validator finding, or a completion shortfall
#   2 - usage error, or a missing/malformed schema, vocabulary, edge-relation map,
#       input stream, or coverage-notes hand-off (absent, failing, empty or
#       truncated -- nothing is written in any of these cases)
#
# ---------------------------------------------------------------------------
# The feature-003 D9 seam -- one accessor shape this renderer requires
# ---------------------------------------------------------------------------
#
#   rel_columns  the column names of D1's contract, ONE PER LINE, in their fixed
#                left-to-right order. The emitted header and delimiter rows are
#                built from this list, so no script hard-codes the column set
#                (feature-003 D1).
#
#   The `Kind` enum (`rel_kinds`) that fixes the coverage notes' kinds-table row
#   order is NOT read here. assemble-coverage-notes.sh reads it through its own
#   copy of the same schema loader, so this script no longer needs the function
#   at all (feature-010 D7).
#
# Everything else is used exactly as feature-003's Provides index publishes it:
# rel_load_schema, rel_load_vocabulary, rel_normalise_row (TEN LINES out, and
# REL_NORM_ROW set), rel_row_key, rel_sort_key, rel_display_name, and
# rel_is_relation / rel_inverse_of / rel_passes / rel_endpoint_kinds.
#
# ---------------------------------------------------------------------------
# The candidate key, defined here because nothing upstream defines it
# ---------------------------------------------------------------------------
#
# D6 part 4 keys dispositions on a `candidate_key` that no producer's record
# carries. It is fixed here as `<subject>\x1f<context>` -- fields 2 and 3 of a
# feature-004 D6 candidate row, joined by US. `drop_reason` is deliberately
# EXCLUDED, so re-classifying why a reference failed does not silently invalidate
# a disposition already written for it.
#
# The union D6 part 4 takes the difference against has two arms, and both are
# computed: a disposition row bearing the key, OR -- for a candidate whose
# `subject` names two node ids (`<id> -> <id>`, which is the shape derive-edges.sh
# writes) -- an accepted class-1 row over that unordered id pair. A candidate
# naming an UNRESOLVED literal has no node at either end, so FR-31a part 2 makes
# a class-1 row for it impossible and only a disposition can discharge it. That
# asymmetry is why the second arm is keyed on the id pair rather than on the row.

set -euo pipefail

# Byte-deterministic collation AND byte-deterministic bracket expressions; see
# the note in harvest-declared.sh. Exported so a child process inherits it.
export LC_ALL=C

BR_SELF="build-relationships.sh"
br_warn() { printf '%s: %s\n' "$BR_SELF" "$*" >&2; }

BR_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./report-endpoint-satisfiability.sh
. "${BR_SCRIPT_DIR}/report-endpoint-satisfiability.sh"

US=$'\x1f'
TAB=$'\t'
NL=$'\n'

TEMP_DIR=".aid/.temp/graph"
OUT=".aid/knowledge/relationships.md"
COVERAGE=""
VALIDATOR=""
ASSEMBLER=""
SKIP_VALIDATE=0
SHORTFALL=0
VALIDATOR_FINDINGS=0

declare -A NODE_KIND=()
declare -A NODE_NAME=()

declare -a ROW_LIST=()        # index -> the 11-field record (class + D1's ten fields)
declare -A BEST_INDEX=()      # rel_row_key -> index into ROW_LIST
declare -A CLASS0_KEYS=()     # the frozen class-0 key set (rejection 2)
declare -a CLASS0_KEY_LIST=()
declare -a CLASS1_KEY_LIST=()
declare -A ACCEPTED_PAIRS=()  # "<idA>\x1f<idB>", LC_ALL=C ordered, for accepted class-1 rows
declare -a BR_F=()

CNT_CLASS0=0
CNT_CLASS1=0
CNT_REJECTED=0

D2F_PAIRS_1_3=0
D2F_FILTERED=0
D2F_SKIPPED_SINGLE=0
D2F_CANDIDATES=0

declare -A STATS=()

# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

# Split an 11-field record into BR_F[0..10]. A record whose final field is empty
# loses it to `read -a`, so every consumer reads through `${BR_F[i]:-}`.
br_split() {
    BR_F=()
    local IFS="$TAB"
    read -r -a BR_F <<< "$1"
}

# The same, for feature-003's newline-separated row shape: rel_normalise_row
# returns TEN LINES and also sets REL_NORM_ROW. Split by hand rather than with
# `read -a`, because `read -a` drops a trailing empty field and the tenth field --
# `Observation` -- is legitimately empty on most rows.
br_split_nl() {
    local rest="$1" i
    BR_F=()
    for i in 1 2 3 4 5 6 7 8 9; do
        BR_F+=("${rest%%"$NL"*}")
        rest="${rest#*"$NL"}"
    done
    BR_F+=("$rest")
}

br_prov_rank() {
    case "$1" in
        declared) printf '3' ;;
        derived)  printf '2' ;;
        inferred) printf '1' ;;
        *)        printf '0' ;;
    esac
}

# The KB document a node belongs to, at the granularity D2f condition 3 needs. A
# `concept` is NOT document-scoped (feature-003 D2), so it owns no document --
# which is exactly why a `mentions` row cannot itself satisfy condition 3.
br_owner_doc() {
    local id="$1" kind="$2" body
    case "$kind" in
        document) printf '%s' "${id#kb:}" ;;
        section|fact) body="${id#kb:}"; printf '%s' "${body%%#*}" ;;
        *) printf '' ;;
    esac
}

br_lexleast() {
    if [ "$1" = "$2" ]; then printf '%s' "$1"; return 0; fi
    printf '%s\n%s\n' "$1" "$2" | LC_ALL=C sort | head -1
}

# ---------------------------------------------------------------------------
# The node universe -- the union of the three streams. Both endpoint ids of every
# Pass-2 row are tested against THIS set and nothing else, which is D6 part 2 and
# the downstream half of feature-004's `no-inferred-node` invariant.
# ---------------------------------------------------------------------------

br_load_nodes() {
    local kb="$1" nodes="$2" media="$3" id name kind f

    for f in "$kb" "$nodes" "$media"; do
        [ -f "$f" ] || { br_warn "node stream not found at ${f}"; return 2; }
    done
    while IFS="$TAB" read -r id kind name _ || [ -n "${id:-}" ]; do
        [ -n "$id" ] || continue
        NODE_KIND["${id%$'\r'}"]="${kind%$'\r'}"
        NODE_NAME["${id%$'\r'}"]="$name"
    done < "$kb"
    while IFS="$TAB" read -r id name _ _ _ _ kind || [ -n "${id:-}" ]; do
        [ -n "$id" ] || continue
        NODE_KIND["${id%$'\r'}"]="${kind%$'\r'}"
        NODE_NAME["${id%$'\r'}"]="$name"
    done < "$nodes"
    while IFS="$TAB" read -r id name kind _ _ || [ -n "${id:-}" ]; do
        [ -n "$id" ] || continue
        NODE_KIND["${id%$'\r'}"]="${kind%$'\r'}"
        NODE_NAME["${id%$'\r'}"]="$name"
    done < "$media"
    return 0
}

# ---------------------------------------------------------------------------
# Step 11 -- merge and freeze class 0
# ---------------------------------------------------------------------------
#
# Every row passes through `rel_normalise_row`, whose D7 rule swaps the two
# `(Id, Kind, Name)` TRIPLES together AND swaps the two relation labels. This
# feature calls the library function rather than implementing the swap, which is
# what makes the eight-column carry-over bug -- moving ids and names while
# leaving the two `Kind` cells in place, so V13 fails on a row that was correct
# before normalisation -- unrepresentable here (D1).
#
# De-duplication is a TOTAL rule, so the survivor never depends on arrival order:
# a repeated key keeps the row with the stronger provenance (`declared` over
# `derived`) and, on a tie, the lexicographically smaller `Observation`.

br_merge_rows() {
    local file="$1" want_class="$2" list_name="$3"
    local class sid skind sname tid tkind tname s2t t2s prov obs
    local key idx cur_prov cur_obs record least

    [ -f "$file" ] || return 0
    while IFS="$TAB" read -r class sid skind sname tid tkind tname s2t t2s prov obs || [ -n "${class:-}" ]; do
        [ -n "${sid:-}" ] || continue
        [ "$class" = "$want_class" ] || continue
        obs="${obs:-}"
        # rel_normalise_row emits TEN LINES and also sets REL_NORM_ROW. The global
        # is read instead of a command substitution because `$( )` would strip the
        # trailing empty Observation, and it forks nothing.
        rel_normalise_row "$sid" "$skind" "$sname" "$tid" "$tkind" "$tname" "$s2t" "$t2s" "$prov" "$obs" >/dev/null || {
            br_warn "rel_normalise_row failed for ${sid} -> ${tid}"
            continue
        }
        br_split_nl "$REL_NORM_ROW"
        sid="${BR_F[0]:-}";   skind="${BR_F[1]:-}"; sname="${BR_F[2]:-}"
        tid="${BR_F[3]:-}";   tkind="${BR_F[4]:-}"; tname="${BR_F[5]:-}"
        s2t="${BR_F[6]:-}";   t2s="${BR_F[7]:-}";   prov="${BR_F[8]:-}"
        obs="${BR_F[9]:-}"
        key=$(rel_row_key "$sid" "$skind" "$sname" "$tid" "$tkind" "$tname" \
                          "$s2t" "$t2s" "$prov" "$obs") || {
            br_warn "rel_row_key failed for ${sid} -> ${tid}"
            continue
        }
        record="${class}${TAB}${sid}${TAB}${skind}${TAB}${sname}${TAB}${tid}${TAB}${tkind}${TAB}${tname}${TAB}${s2t}${TAB}${t2s}${TAB}${prov}${TAB}${obs}"
        idx="${BEST_INDEX[$key]:-}"
        if [ -z "$idx" ]; then
            ROW_LIST+=("$record")
            BEST_INDEX["$key"]=$(( ${#ROW_LIST[@]} - 1 ))
            eval "${list_name}+=(\"\$key\")"
            continue
        fi
        br_split "${ROW_LIST[$idx]}"
        cur_prov="${BR_F[9]:-}"
        cur_obs="${BR_F[10]:-}"
        if [ "$(br_prov_rank "$prov")" -gt "$(br_prov_rank "$cur_prov")" ]; then
            ROW_LIST[$idx]="$record"
        elif [ "$(br_prov_rank "$prov")" -eq "$(br_prov_rank "$cur_prov")" ]; then
            least=$(br_lexleast "$obs" "$cur_obs")
            if [ "$least" = "$obs" ] && [ "$obs" != "$cur_obs" ]; then
                ROW_LIST[$idx]="$record"
            fi
        fi
    done < "$file"
    return 0
}

# Emit the rows for <key ...> in D7's order.
#
# The sort key is joined to the row's INDEX -- never to the row -- and the index
# is the last tab-separated field, so the row is recovered with `${line##*<TAB>}`
# however many separators `rel_sort_key` puts inside its own tuple. TAB (0x09) is
# lower than every printable byte, so appending it cannot reorder two keys where
# one is a prefix of the other, and the emitted order is exactly D7's. Because
# V5 forbids two rows to share a row key, the key is unique per row and the order
# is strict and total; the index tie-break below is therefore unreachable on a
# V5-passing table and deterministic if it were ever reached.
br_sorted_rows() {
    local key idx line sortkey
    [ "$#" -gt 0 ] || return 0
    {
        for key in "$@"; do
            [ -n "$key" ] || continue
            idx="${BEST_INDEX[$key]}"
            br_split "${ROW_LIST[$idx]}"
            sortkey=$(rel_sort_key "${BR_F[1]:-}" "${BR_F[2]:-}" "${BR_F[3]:-}" \
                                   "${BR_F[4]:-}" "${BR_F[5]:-}" "${BR_F[6]:-}" \
                                   "${BR_F[7]:-}" "${BR_F[8]:-}" "${BR_F[9]:-}" \
                                   "${BR_F[10]:-}") || sortkey=""
            printf '%s\t%s\n' "$sortkey" "$idx"
        done
    } | LC_ALL=C sort | while IFS= read -r line; do
        printf '%s\n' "${ROW_LIST[${line##*$TAB}]}"
    done
}

br_freeze_class0() {
    local key
    br_merge_rows "${TEMP_DIR}/rows-pass1a.tsv" 0 CLASS0_KEY_LIST || return 1
    br_merge_rows "${TEMP_DIR}/rows-pass1b.tsv" 0 CLASS0_KEY_LIST || return 1
    for key in "${CLASS0_KEY_LIST[@]:-}"; do
        [ -n "$key" ] && CLASS0_KEYS["$key"]=1
    done
    br_sorted_rows "${CLASS0_KEY_LIST[@]:-}" > "${TEMP_DIR}/rows-class0.tsv"
    CNT_CLASS0=${#CLASS0_KEY_LIST[@]}
    return 0
}

# ---------------------------------------------------------------------------
# Step 11a -- D2f, the false-merge candidate report
# ---------------------------------------------------------------------------
#
# Computed over the FROZEN class-0 set, which is where a concept's neighbourhood
# first exists. Advisory throughout: it changes no row, writes no gap-ledger row
# and does not touch the exit code (AC-S7).
#
# ORIENTATION SAFETY. feature-003 D7 stores rows normalised, swapping the two
# triples AND the two labels, so on roughly half of every asymmetric pair the
# stored `S2T Relation` is the INVERSE of the relation the scan discovered. A
# predicate reading the stored `s2t` cell alone would therefore miss those rows
# entirely. Both readings of every row are tested instead -- `s2t` source->target
# and `t2s` target->source -- which is the same construction feature-003's V12
# uses for its own accumulation and is why the swap cannot change a verdict here.

br_detect_merge_candidates() {
    local r_mention r_defines
    local -A def_doc=() mention_docs=() mention_anchor=() doc_concepts=() doc_links=()
    local class sid skind sname tid tkind tname s2t t2s prov obs
    local cdoc cid mdoc odoc a b pair c shared others n_concepts
    local out="${TEMP_DIR}/concept-merge-candidates.tsv"

    r_mention=$(erm_relation "kb-concept-mention")
    r_defines=$(erm_relation "kb-concept-definition")
    : > "$out"
    if [ -z "$r_mention" ] || [ -z "$r_defines" ]; then
        br_warn "notice: the edge-relation map carries no mention or definition entry; D2f is inert"
        return 0
    fi

    while IFS="$TAB" read -r class sid skind sname tid tkind tname s2t t2s prov obs || [ -n "${class:-}" ]; do
        [ -n "${sid:-}" ] || continue
        obs="${obs:-}"

        # Definition, in whichever orientation the row was stored in.
        cdoc=""; cid=""
        if [ "$s2t" = "$r_defines" ]; then
            cdoc="$sid"; cid="$tid"
        elif [ "$t2s" = "$r_defines" ]; then
            cdoc="$tid"; cid="$sid"
        fi
        if [ -n "$cid" ]; then
            odoc="${cdoc#kb:}"
            def_doc["$cid"]="$odoc"
            doc_concepts["$odoc"]="${doc_concepts[$odoc]:-} $cid"
        fi

        # Mention, likewise.
        cdoc=""; cid=""
        if [ "$s2t" = "$r_mention" ]; then
            cdoc=$(br_owner_doc "$sid" "$skind"); cid="$tid"
        elif [ "$t2s" = "$r_mention" ]; then
            cdoc=$(br_owner_doc "$tid" "$tkind"); cid="$sid"
        fi
        if [ -n "$cid" ] && [ -n "$cdoc" ]; then
            mention_docs["$cid"]="${mention_docs[$cid]:-} $cdoc"
            doc_concepts["$cdoc"]="${doc_concepts[$cdoc]:-} $cid"
            pair="${cid}${US}${cdoc}"
            if [ -z "${mention_anchor[$pair]:-}" ]; then
                mention_anchor["$pair"]="$obs"
            else
                mention_anchor["$pair"]=$(br_lexleast "$obs" "${mention_anchor[$pair]}")
            fi
        fi

        # Condition 3's link relation: any class-0 row whose two endpoints both
        # belong to a KB document, at document granularity, in either direction.
        a=$(br_owner_doc "$sid" "$skind")
        b=$(br_owner_doc "$tid" "$tkind")
        if [ -n "$a" ] && [ -n "$b" ] && [ "$a" != "$b" ]; then
            doc_links["${a}${US}${b}"]=1
            doc_links["${b}${US}${a}"]=1
        fi
    done < "${TEMP_DIR}/rows-class0.tsv"

    for cid in $(printf '%s\n' "${!def_doc[@]}" | LC_ALL=C sort); do
        # Condition 1: the PLAIN id form only. The `>= 2` case is split
        # structurally into `@<doc>` nodes (D2d case 1), so no merge occurred and
        # none can be false.
        case "$cid" in
            kb:concept:*'@'*) continue ;;
            kb:concept:*) : ;;
            *) continue ;;
        esac
        odoc="${def_doc[$cid]}"

        # The degenerate exclusion, stated explicitly because it would otherwise
        # make condition 4 vacuous: if D defines C and names no other concept,
        # every mentioning document trivially shares nothing else with it, so
        # condition 4 would fire on all of them while discriminating nothing.
        # shellcheck disable=SC2086  # deliberate word splitting over a space-separated list
        n_concepts=$(printf '%s\n' ${doc_concepts[$odoc]:-} | LC_ALL=C sort -u | grep -c . || true)
        if [ "${n_concepts:-0}" -le 1 ]; then
            D2F_SKIPPED_SINGLE=$(( D2F_SKIPPED_SINGLE + 1 ))
            continue
        fi

        # shellcheck disable=SC2086  # deliberate word splitting over a space-separated list
        for mdoc in $(printf '%s\n' ${mention_docs[$cid]:-} | LC_ALL=C sort -u); do
            [ -n "$mdoc" ] || continue
            # Condition 2: M != D.
            [ "$mdoc" != "$odoc" ] || continue
            # Condition 3: no class-0 row links M and D in either direction.
            [ -z "${doc_links[${mdoc}${US}${odoc}]:-}" ] || continue
            D2F_PAIRS_1_3=$(( D2F_PAIRS_1_3 + 1 ))
            # Condition 4: M and D share no concept but C.
            shared=0
            # shellcheck disable=SC2086  # deliberate word splitting over a space-separated list
            others=$(printf '%s\n' ${doc_concepts[$odoc]:-} | LC_ALL=C sort -u)
            # shellcheck disable=SC2086  # deliberate word splitting over a space-separated list
            for c in $(printf '%s\n' ${doc_concepts[$mdoc]:-} | LC_ALL=C sort -u); do
                [ -n "$c" ] || continue
                [ "$c" != "$cid" ] || continue
                if printf '%s\n' "$others" | grep -qxF -- "$c"; then shared=1; break; fi
            done
            if [ "$shared" -eq 1 ]; then
                D2F_FILTERED=$(( D2F_FILTERED + 1 ))
                continue
            fi
            printf '%s\t%s\t%s\t%s\n' "$cid" "$odoc" "$mdoc" \
                "${mention_anchor[${cid}${US}${mdoc}]:-}" >> "$out"
        done
    done

    if [ -s "$out" ]; then
        LC_ALL=C sort "$out" -o "$out"
    fi
    D2F_CANDIDATES=$(( D2F_PAIRS_1_3 - D2F_FILTERED ))

    while IFS="$TAB" read -r cid odoc mdoc obs; do
        [ -n "$cid" ] || continue
        printf '[LOW] %s: concept %s is defined in %s and mentioned in %s, which links neither -- %s\n' \
            "$OUT" "$cid" "$odoc" "$mdoc" "$obs"
    done < "$out"
    printf '[LOW] %s: pairs_1_3=%s filtered_by_shared_vocabulary=%s skipped_single_concept=%s candidates=%s\n' \
        "$OUT" "$D2F_PAIRS_1_3" "$D2F_FILTERED" "$D2F_SKIPPED_SINGLE" "$D2F_CANDIDATES"
    return 0
}

# ---------------------------------------------------------------------------
# Step 13 -- the four rejections, and the class-1 merge
# ---------------------------------------------------------------------------
#
# Enforced HERE and not in the dispatch prompt: a prompt-only bound is not a
# bound. A rejection is never fatal (FR-25's reporting-not-gating posture), and a
# rejected row still gets a disposition -- otherwise a rejection would create the
# very shortfall part 4 exists to catch.

br_reject() {
    local reason="$1" sid="$2" tid="$3" line f
    br_warn "class-1 row rejected (${reason}): ${sid} -> ${tid}"
    line="${sid} -> ${tid}${TAB}cannot-type${TAB}rejected: ${reason}"
    f="${TEMP_DIR}/dispositions.tsv"
    # Append only what is not already recorded. A blind append would make the
    # scratch file grow by one duplicate row per re-run, so two runs on identical
    # inputs would leave different bytes behind -- which is the shape of drift
    # this feature exists to make detectable, even though the file itself sits
    # outside FR-32's boundary.
    if [ ! -f "$f" ] || ! grep -qxF -- "$line" "$f"; then
        printf '%s\n' "$line" >> "$f"
    fi
    CNT_REJECTED=$(( CNT_REJECTED + 1 ))
}

br_merge_class1() {
    local file="${TEMP_DIR}/rows-class1.tsv" staged="${TEMP_DIR}/.rows-class1-staged.tsv"
    local class sid skind sname tid tkind tname s2t t2s prov obs
    local inverse passes endpoints key a b

    : > "${TEMP_DIR}/rows-class1-accepted.tsv"
    [ -f "$file" ] || return 0
    : > "$staged"

    while IFS="$TAB" read -r class sid skind sname tid tkind tname s2t t2s prov obs || [ -n "${class:-}" ]; do
        [ -n "${sid:-}" ] || continue
        obs="${obs:-}"

        # Rejection 1 -- the closed node set (D6 part 2, AC-S3).
        if [ -z "${NODE_KIND[$sid]:-}" ] || [ -z "${NODE_KIND[$tid]:-}" ]; then
            br_reject "endpoint id is in none of the three node streams" "$sid" "$tid"
            continue
        fi
        # The two kinds are taken from the NODE RECORDS, never from the returned
        # row and never from an id prefix (Q21).
        skind="${NODE_KIND[$sid]}"
        tkind="${NODE_KIND[$tid]}"
        sname="${NODE_NAME[$sid]:-}"
        tname="${NODE_NAME[$tid]:-}"
        [ -n "$sname" ] || sname=$(rel_display_name "$skind" "$sid") || sname=""
        [ -n "$tname" ] || tname=$(rel_display_name "$tkind" "$tid") || tname=""

        # Rejection 3 -- class 1 only.
        if [ "$prov" != "inferred" ]; then
            br_reject "provenance '${prov}' is not 'inferred'" "$sid" "$tid"
            continue
        fi
        # Rejection 4 -- typed from the vocabulary, with the KIND pair and never a
        # prefix pair. Under seven kinds a prefix pair cannot distinguish a
        # document defining a concept from a section mentioning one, which is the
        # Q17 defect in miniature.
        if ! rel_is_relation "$s2t"; then
            br_reject "'${s2t}' is not a member of the merged vocabulary" "$sid" "$tid"
            continue
        fi
        inverse=$(rel_inverse_of "$s2t")
        t2s="$inverse"
        passes=$(rel_passes "$s2t")
        if ! erm_in_list "inferred" "$passes"; then
            br_reject "'${s2t}' passes (${passes}) excludes 'inferred'" "$sid" "$tid"
            continue
        fi
        endpoints=$(rel_endpoint_kinds "$s2t")
        if ! erm_in_list "${skind}->${tkind}" "$endpoints"; then
            br_reject "'${s2t}' endpoint_kinds excludes ${skind}->${tkind}" "$sid" "$tid"
            continue
        fi
        # Rejection 2 -- no revisiting. This is the mechanical form of FR-31's
        # "runs only over what the scan could not settle", and it is tested HERE,
        # before the row is staged, rather than after the merge: ROW_LIST and
        # BEST_INDEX are shared with the frozen class-0 rows, so a colliding row
        # reaching br_merge_rows would be quietly absorbed by the de-duplication
        # rule -- surviving as neither an accepted row nor a reported rejection,
        # and leaving the candidate it was typing with no disposition at all.
        key=$(rel_row_key "$sid" "$skind" "$sname" "$tid" "$tkind" "$tname" \
                          "$s2t" "$t2s" "inferred" "$obs") || key=""
        if [ -n "$key" ] && [ -n "${CLASS0_KEYS[$key]:-}" ]; then
            br_reject "row key collides with a frozen class-0 row" "$sid" "$tid"
            continue
        fi
        printf '1\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tinferred\t%s\n' \
            "$sid" "$skind" "$sname" "$tid" "$tkind" "$tname" "$s2t" "$t2s" "$obs" >> "$staged"
    done < "$file"

    br_merge_rows "$staged" 1 CLASS1_KEY_LIST || return 1

    for key in "${CLASS1_KEY_LIST[@]:-}"; do
        [ -n "$key" ] || continue
        br_split "${ROW_LIST[${BEST_INDEX[$key]}]}"
        a="${BR_F[1]:-}"; b="${BR_F[4]:-}"
        if [ "$(br_lexleast "$a" "$b")" = "$a" ]; then
            ACCEPTED_PAIRS["${a}${US}${b}"]=1
        else
            ACCEPTED_PAIRS["${b}${US}${a}"]=1
        fi
        CNT_CLASS1=$(( CNT_CLASS1 + 1 ))
    done
    br_sorted_rows "${CLASS1_KEY_LIST[@]:-}" > "${TEMP_DIR}/rows-class1-accepted.tsv"
    rm -f -- "$staged"
    return 0
}

# ---------------------------------------------------------------------------
# Step 14 -- the completion check (D6 part 4, AC-S4)
# ---------------------------------------------------------------------------

br_completion_check() {
    local -A dispositions=()
    local key ck kind subject context reason f a b lo hi
    local -a undispositioned=() unread=()
    local doc count reads="${TEMP_DIR}/pass2-reads.tsv"

    if [ -f "${TEMP_DIR}/dispositions.tsv" ]; then
        while IFS="$TAB" read -r ck _ _ || [ -n "${ck:-}" ]; do
            [ -n "$ck" ] && dispositions["$ck"]=1
        done < "${TEMP_DIR}/dispositions.tsv"
    fi

    for f in "${TEMP_DIR}/candidates.tsv" "${TEMP_DIR}/candidates-pass1a.tsv" \
             "${TEMP_DIR}/candidates-pass1b.tsv"; do
        [ -f "$f" ] || continue
        while IFS="$TAB" read -r kind subject context reason || [ -n "${kind:-}" ]; do
            [ -n "${subject:-}" ] || continue
            key="${subject}${US}${context:-}"
            [ -z "${dispositions[$key]:-}" ] || continue
            # A rejection written by the merge knows the row's two ids but not the
            # candidate's context, so it keys on the subject alone. Accepting the
            # bare subject as well is what stops a rejection from creating the
            # very shortfall part 4 exists to catch.
            [ -z "${dispositions[$subject]:-}" ] || continue
            # The second arm of the union: a candidate whose subject names two node
            # ids is discharged by an accepted class-1 row over that pair.
            case "$subject" in
                *' -> '*)
                    a="${subject%% -> *}"
                    b="${subject##* -> }"
                    lo=$(br_lexleast "$a" "$b")
                    if [ "$lo" = "$a" ]; then hi="$b"; else hi="$a"; fi
                    [ -z "${ACCEPTED_PAIRS[${lo}${US}${hi}]:-}" ] || continue
                    ;;
            esac
            undispositioned+=("${reason:-} ${subject} (${context:-})")
        done < "$f"
    done

    if [ -f "$reads" ]; then
        while IFS="$TAB" read -r kind doc || [ -n "${kind:-}" ]; do
            [ "$kind" = "document" ] || continue
            count=$(grep -cxF -- "$doc" "$reads" || true)
            [ "$count" = "1" ] || unread+=("${doc} (read-ledger entries: ${count})")
        done < "${TEMP_DIR}/pass2-inputs.tsv"
    else
        # The one degradation case, and the reason it is not a loophole: an ABSENT
        # ledger means Pass 2 was never dispatched, which is a recorded, total
        # outcome. A ledger that EXISTS means the pass ran, and then every
        # manifest document must appear in it exactly once.
        br_warn "notice: ${reads} is absent; Pass 2 was not dispatched, so the read ledger is not checked"
    fi

    # Every item is NAMED, because FR-31a part 4's whole point is that the pass
    # cannot "finish" by giving up quietly. One printf per item: a single printf
    # with a reused format string would consume the second item as the script
    # name on its second cycle.
    local item
    for item in "${undispositioned[@]:-}"; do
        [ -n "$item" ] || continue
        SHORTFALL=1
        br_warn "undispositioned candidate: ${item}"
    done
    for item in "${unread[@]:-}"; do
        [ -n "$item" ] || continue
        SHORTFALL=1
        br_warn "unread manifest document: ${item}"
    done
    return 0
}

# ---------------------------------------------------------------------------
# D7 -- this feature's coverage contribution
# ---------------------------------------------------------------------------

br_load_stats() {
    local k v
    [ -f "${TEMP_DIR}/kb-stats.tsv" ] || { br_warn "Pass 1a stream not found at ${TEMP_DIR}/kb-stats.tsv"; return 2; }
    while IFS="$TAB" read -r k v || [ -n "${k:-}" ]; do
        [ -n "$k" ] && STATS["$k"]="${v%$'\r'}"
    done < "${TEMP_DIR}/kb-stats.tsv"
    return 0
}

br_status_of() { if [ "${1:-0}" = "1" ]; then printf 'present'; else printf 'absent'; fi; }

# The `note` text of all four fixed rows reproduces feature-003 D7a's example
# wording verbatim; the four extra rows use the extension mechanism D7a provides.
# All four extras report their numbers in the `note` and carry `--` in `count`,
# because feature-004 D7 fixes `count` as a NODE count so the rendered `Nodes`
# column stays summable -- none of the four is a node count.
br_write_kb_coverage() {
    local out="${TEMP_DIR}/kb-coverage.tsv"
    {
        printf 'kind\tdocument\t%s\t%s\tKB documents under `.aid/knowledge/`\n' \
            "$(br_status_of "${STATS[carrier-document]:-0}")" "${STATS[documents]:-0}"
        printf 'kind\tconcept\t%s\t%s\tdefinition marker under a level-3+ heading\n' \
            "$(br_status_of "${STATS[carrier-concept]:-0}")" "${STATS[concepts]:-0}"
        printf 'kind\tfact\t%s\t%s\tcheckable source anchor (path + grep-recoverable string)\n' \
            "$(br_status_of "${STATS[carrier-fact]:-0}")" "${STATS[facts]:-0}"
        printf 'kind\tsection\t%s\t%s\tATX headings, levels 2-6\n' \
            "$(br_status_of "${STATS[carrier-section]:-0}")" "${STATS[sections]:-0}"
        printf 'kind\tconcept-merge-candidates\t--\t--\tconcept mentions sitting in the structural position of a false merge, advisory: %s; filtered by shared vocabulary: %s; concepts skipped as single-concept-defining: %s\n' \
            "$D2F_CANDIDATES" "$D2F_FILTERED" "$D2F_SKIPPED_SINGLE"
        printf 'kind\tconcept-qualified\t--\t--\tterms carrying more than one definition, emitted in the @<doc> qualified form: %s\n' \
            "${STATS[concept-qualified]:-0}"
        printf 'kind\tfact-unanchored\t--\t--\tcitation markers skipped for want of an anchor string: %s\n' \
            "${STATS[fact-unanchored]:-0}"
        printf 'kind\tsection-empty-slug\t--\t--\theadings whose slug normalised to empty, emitting no section node: %s\n' \
            "${STATS[section-empty-slug]:-0}"
    } > "$out"
}

# ---------------------------------------------------------------------------
# Step 15 -- render
# ---------------------------------------------------------------------------

br_escape_cell() { local t="$1"; printf '%s' "${t//|/\\|}"; }

# A leading `|`, then each cell surrounded by exactly one space, then a trailing
# `|`; an EMPTY cell renders as a single space, which is the well-formed-empty
# rule build-kb-index.sh already applies (feature-003 D1).
br_render_row() {
    local cell out="|"
    for cell in "$@"; do
        if [ -z "$cell" ]; then out="${out} |"; else out="${out} $(br_escape_cell "$cell") |"; fi
    done
    printf '%s\n' "$out"
}

br_render_delimiter() {
    local n="$1" i out="|"
    for (( i=0; i<n; i++ )); do out="${out}---|"; done
    printf '%s\n' "$out"
}

# ---------------------------------------------------------------------------
# Step 15's hand-off half (feature-010 D7, Open Item 7)
# ---------------------------------------------------------------------------
#
# feature-003 owns the `## Coverage notes` section's shape, row set, order and
# validation (its D7a, V14); this feature supplies the content of its own four
# kind rows and four extra rows via `kb-coverage.tsv`, just written above; and
# feature-010's assemble-coverage-notes.sh is the ONE place those bytes and
# feature-004's coverage.tsv become the rendered section -- the field
# reordering, the exclusion-key -> label translation and the extra-row total
# sort all live there and NOWHERE else (D7a-1). This function's only job is to
# run it and verify what it wrote; br_render_coverage() below then moves those
# bytes without composing a single one of its own, which is what makes this
# feature's contribution and feature-010's assembly a single code path instead
# of two renderers that could silently disagree.
#
# An absent, failing, empty or truncated hand-off is a LOUD failure and never a
# silent fall-back to self-rendering -- self-rendering is exactly the defect
# this function replaces. Every branch below returns 2, the same
# "malformed/missing input stream" bucket br_parse_args already uses for a
# missing schema or vocabulary, because in every one of them not one byte of
# the artifact has been written yet (br_render, and therefore br_render_coverage,
# has not run): a hand-off failure here costs nothing already committed to disk.
br_assemble_coverage() {
    local notes="${TEMP_DIR}/coverage-notes.md" first_line

    if [ ! -f "$ASSEMBLER" ]; then
        br_warn "the coverage-notes assembler is not found at ${ASSEMBLER}; the '## Coverage notes' section cannot be rendered without it"
        return 2
    fi
    # A stale file from an earlier run must never be mistaken for this run's
    # hand-off -- the checks below would otherwise validate the WRONG bytes on
    # a run whose assembler silently failed to write anything.
    rm -f -- "$notes"
    if ! bash "$ASSEMBLER" --coverage "$COVERAGE" --kb-coverage "${TEMP_DIR}/kb-coverage.tsv" \
            --schema "$GRAPH_SCHEMA" --output "$notes"; then
        br_warn "assemble-coverage-notes.sh failed; the coverage-notes hand-off was not produced"
        return 2
    fi
    if [ ! -s "$notes" ]; then
        br_warn "the coverage-notes hand-off at ${notes} is absent or empty after the assembler ran -- nothing guarantees feature-010's step ran first, and this run did not produce it either"
        return 2
    fi
    first_line=$(head -n 1 -- "$notes")
    if [ "$first_line" != "## Coverage notes" ]; then
        br_warn "the coverage-notes hand-off at ${notes} is truncated or malformed -- it does not begin with '## Coverage notes'"
        return 2
    fi
    return 0
}

# The consumer half. feature-003 D7a-1's fixed-block-then-sorted-extras order and
# feature-004/feature-005's exclusion-key -> label translation are NOT
# reimplemented here -- br_assemble_coverage() already verified the file above IS
# that rendered section, so this function moves its bytes and composes none of
# its own. The leading blank line is the separator from the relationship table
# above it, not part of the hand-off; the hand-off's own bytes follow untouched,
# which is what makes AC-5's byte-comparison of the whole section a comparison
# against feature-010's own output rather than a second, possibly-diverging
# rendering of the same content.
br_render_coverage() {
    printf '\n'
    cat -- "${TEMP_DIR}/coverage-notes.md"
    return 0
}

# feature-003 D8's frontmatter, emitted verbatim: no timestamp, no `changelog:`,
# and no value that varies between two runs on identical inputs. feature-010's
# `graph_inputs_digest` / `graph_generated_at` sit OUTSIDE the byte-identity
# boundary by D8's design and are not written here.
br_render() {
    local ncols line
    local -a columns=()
    while IFS= read -r line; do
        [ -n "$line" ] && columns+=("$line")
    done < <(rel_columns)
    ncols=${#columns[@]}
    if [ "$ncols" -eq 0 ]; then
        br_warn "rel_columns returned no column names"
        return 2
    fi

    mkdir -p -- "$(dirname -- "$OUT")" || { br_warn "cannot create $(dirname -- "$OUT")"; return 1; }
    {
        cat <<'FRONTMATTER'
---
kb-category: primary
source: generated
generator: build-relationships.sh
objective: Every recorded relationship among Knowledge Base documents, sections, facts and concepts, project source artifacts, images and web pages, with both readings named on one row.
summary: Read this to trace which Knowledge Base claim is backed by which source artifact or external source; it is the single input to the graph view and the machine-readable structure agents route over.
sources:
  - .aid/knowledge/
  - .aid/knowledge/external-sources.md
tags: [C2, relationships, graph, provenance, coverage, routing]
see_also: [INDEX.md, external-sources.md]
owner: architect
audience: [developer, architect]
contracts:
  - "Ten columns in fixed order: Source Id / Source Kind / Source Name / Target Id / Target Kind / Target Name / S2T Relation / T2S Relation / Provenance / Observation"
  - "Source Kind and Target Kind are members of a closed enum and agree with their id prefix"
  - "Every row carries a Provenance of declared, derived, or inferred"
  - "One row per relationship; both readings named on the same row"
  - "A Coverage notes section follows the table on every run"
---
<!-- AUTO-GENERATED by aid/scripts/graph/build-relationships.sh -- regenerate with /aid-graph. Do not edit. -->

# Relationships

FRONTMATTER
        br_render_row "${columns[@]}"
        br_render_delimiter "$ncols"
        # Class-major order makes class 0 a contiguous PREFIX, so no class-1
        # change can move, split or reflow a deterministic row (FR-32 mechanism 1).
        local class sid skind sname tid tkind tname s2t t2s prov obs f
        for f in "${TEMP_DIR}/rows-class0.tsv" "${TEMP_DIR}/rows-class1-accepted.tsv"; do
            [ -f "$f" ] || continue
            while IFS="$TAB" read -r class sid skind sname tid tkind tname s2t t2s prov obs || [ -n "${class:-}" ]; do
                [ -n "${sid:-}" ] || continue
                br_render_row "$sid" "$skind" "$sname" "$tid" "$tkind" "$tname" \
                    "$s2t" "$t2s" "$prov" "${obs:-}"
            done < "$f"
        done
        br_render_coverage
    } > "${OUT}.tmp" || { br_warn "cannot write ${OUT}.tmp"; rm -f -- "${OUT}.tmp"; return 1; }

    mv -f -- "${OUT}.tmp" "$OUT" || { br_warn "cannot move ${OUT}.tmp into place"; return 1; }
    return 0
}

# ---------------------------------------------------------------------------
# Step 16 -- self-validate
# ---------------------------------------------------------------------------

br_self_validate() {
    if [ "$SKIP_VALIDATE" -eq 1 ]; then
        return 0
    fi
    if [ ! -f "$VALIDATOR" ]; then
        br_warn "notice: ${VALIDATOR} is absent; step 16 self-validation was not run"
        return 0
    fi
    # A non-zero exit is REPORTED and the artifact stays written, so the failure
    # is visible rather than hidden behind a missing file.
    if ! bash "$VALIDATOR" --file "$OUT"; then
        VALIDATOR_FINDINGS=1
        br_warn "validate-relationships.sh reported findings against ${OUT}"
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

br_help() { sed -n '2,/^$/p' "$0" | sed -e 's/^#$//' -e 's/^# //'; }

BR_HELP=0

br_parse_args() {
    VALIDATOR="${BR_SCRIPT_DIR}/validate-relationships.sh"
    ASSEMBLER="${BR_SCRIPT_DIR}/assemble-coverage-notes.sh"
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) BR_HELP=1; return 0 ;;
            --temp-dir)             TEMP_DIR="${2:-}"; shift 2 ;;
            --out)                  OUT="${2:-}"; shift 2 ;;
            --coverage)             COVERAGE="${2:-}"; shift 2 ;;
            --schema)               GRAPH_SCHEMA="${2:-}"; shift 2 ;;
            --vocabulary)           GRAPH_VOCAB="${2:-}"; shift 2 ;;
            --vocabulary-extension) GRAPH_VOCAB_EXT="${2:-}"; shift 2 ;;
            --edge-map)             GRAPH_EDGE_MAP="${2:-}"; shift 2 ;;
            --lib)                  GRAPH_LIB="${2:-}"; shift 2 ;;
            --validator)            VALIDATOR="${2:-}"; shift 2 ;;
            --assembler)            ASSEMBLER="${2:-}"; shift 2 ;;
            --skip-validate)        SKIP_VALIDATE=1; shift ;;
            *) br_warn "unknown option '$1'"; return 2 ;;
        esac
    done
    [ -n "$COVERAGE" ] || COVERAGE="${TEMP_DIR}/coverage.tsv"
    graph_require_path --schema "$GRAPH_SCHEMA" || return 2
    graph_require_path --vocabulary "$GRAPH_VOCAB" || return 2
    graph_require_path --edge-map "$GRAPH_EDGE_MAP" || return 2
    graph_require_path --out "$OUT" || return 2
    graph_require_library "$GRAPH_LIB" || return 2
    [ -f "$COVERAGE" ] || { br_warn "feature-004 coverage contribution not found at ${COVERAGE}"; return 2; }
    return 0
}

br_run() {
    graph_require_functions rel_normalise_row rel_row_key rel_sort_key \
        rel_display_name rel_columns || return 2

    br_load_nodes "${TEMP_DIR}/kb-nodes.tsv" "${TEMP_DIR}/nodes.tsv" \
        "${TEMP_DIR}/media-nodes.tsv" || return 2
    br_load_stats || return 2

    br_freeze_class0 || return 1
    br_detect_merge_candidates || return 1
    br_merge_class1 || return 1
    br_completion_check || return 1
    br_write_kb_coverage
    br_assemble_coverage || return 2
    br_render || return 1
    br_self_validate

    printf '[relationships] %s class-0 rows | %s class-1 rows | %s rejected | %s merge candidates | %s\n' \
        "$CNT_CLASS0" "$CNT_CLASS1" "$CNT_REJECTED" "$D2F_CANDIDATES" "$OUT"

    if [ "$SHORTFALL" -eq 1 ] || [ "$VALIDATOR_FINDINGS" -eq 1 ]; then
        return 1
    fi
    return 0
}

# Top level, never inside a function -- see the note in harvest-declared.sh.
graph_default_paths "$BR_SCRIPT_DIR"
br_parse_args "$@" || exit $?
if [ "$BR_HELP" = "1" ]; then br_help; exit 0; fi
# shellcheck disable=SC1090  # resolved at run time, by design
. "$GRAPH_LIB" || { br_warn "cannot source ${GRAPH_LIB}"; exit 2; }
graph_load_context "$GRAPH_SCHEMA" "$GRAPH_VOCAB" "$GRAPH_VOCAB_EXT" "$GRAPH_EDGE_MAP" || exit 2
br_run
exit $?
