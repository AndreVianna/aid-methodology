#!/usr/bin/env bash
# relationship-schema.sh - sourceable loader/normaliser library for the
# `.aid/knowledge/relationships.md` relationship table (feature-003,
# work-005-knowledge-graph).
#
# Purpose:
#   The single home for every RULE the relationship table's contract states, and
#   the single reader of the two data carriers that contract keeps as DATA:
#
#     aid/templates/graph/relationship-schema.yml   the ten columns, the
#                                                   Provenance enum, the id-prefix
#                                                   set, the Kind enum with its
#                                                   per-kind permitted-prefix
#                                                   sets, and image_extensions
#     aid/templates/graph/relation-vocabulary.yml   the core relation vocabulary,
#                                                   merged with an optional
#                                                   project extension at
#                                                   .aid/graph/relation-vocabulary.yml
#
#   validate-relationships.sh sources this file and calls these functions; the
#   test suite calls the same functions. Neither re-implements a rule and neither
#   parses either carrier itself, so there is exactly ONE implementation of each
#   rule rather than two readings of it.
#
#   No relation label, category name or standards key from the vocabulary appears
#   anywhere in this file. It knows the SHAPE of vocabulary content and never its
#   values, which is what keeps a `grep` of the shipped graph/ script tree clean.
#
# Usage:
#   source "$(dirname "$0")/relationship-schema.sh"
#   bash relationship-schema.sh --help        # print this header
#
#   Load order matters and is checked: rel_load_schema populates the Kind and
#   Provenance enums that rel_load_vocabulary validates `endpoint_kinds` and
#   `passes` against, so the closed sets have one carrier and one loader.
#
#     rel_load_schema      <schema.yml>                      || exit 2
#     rel_load_vocabulary  <core.yml> [<extension.yml>]      || exit 2
#     rel_set_repo_root    <dir>          # default: git toplevel, else .
#     rel_set_kb_root      <dir>          # default: .aid/knowledge
#     rel_set_external_sources <file>     # default: <kb-root>/external-sources.md
#
# No import-time side effects: this file defines functions and initialises its own
# globals to empty, and nothing else. `set -eu` is applied only on DIRECT
# execution, at the tail of the file - a sourced `set -e` would mutate the
# sourcing shell, and validate-relationships.sh deliberately runs `set -uo
# pipefail` without `-e` (the read-only linter posture kb-citation-lint.sh
# establishes). This is the same posture significance-rules.sh takes for the same
# reason.
#
# Provides:
#   -- carrier loading (fail closed) --
#   rel_load_schema <file>                    the schema carrier; 2 on absent/empty/malformed
#   rel_load_vocabulary <core> [<extension>]  merged vocabulary; 2 on any violation
#   -- schema accessors --
#   rel_columns                               the ten column names, in order, one per line
#   rel_required_columns                      the columns whose cell is never empty
#   rel_optional_columns                      the complement
#   rel_provenance_values                     the closed Provenance enum
#   rel_prefixes                              the closed id-prefix set
#   rel_kinds                                 the closed Kind enum, in carrier order
#   rel_kind_prefixes <kind>                  that kind's permitted prefixes (space separated)
#   rel_image_extensions                      the image-extension set (space separated)
#   -- vocabulary accessors (the exposure surface D9 fixes) --
#   rel_vocab_relations                       every merged relation label, LC_ALL=C ascending
#   rel_categories                            every merged category name, LC_ALL=C ascending
#   rel_is_relation <label>                   membership: some entry's relation or inverse (V3)
#   rel_pair_ok <s2t> <t2s>                   the ordered pair is a merged pair, either way (V4)
#   rel_inverse_of <relation>                 that entry's inverse
#   rel_category <relation>                   that entry's category
#   rel_endpoint_kinds <relation>             that entry's endpoint tokens (space separated)
#   rel_passes <relation>                     that entry's passes values (space separated)
#     -- and rel_endpoint_kinds_into / rel_passes_into, which leave the value in
#        REL_LOOKUP for a per-row loop; a `$(...)` there is one fork per row
#   rel_definition <relation>                 that entry's one-sentence definition
#   rel_derived_from <relation>               that entry's standards attribution tokens
#   rel_relation_origin <relation>            `core` or `extension`
#   -- id grammar and resolution --
#   rel_parse_id <id>                         -> REL_ID_* ; 1 + REL_ID_REASON on a grammar violation
#   rel_kind_prefix_ok <kind> <id>            D1a's two tiers; 1 + REL_KIND_REASON
#   rel_resolve_id <kind> <id>                prints `ok` or a reason token
#                                             (rel_resolve_id_into -> REL_RESOLVE)
#   rel_display_name <kind> <id>              the derived display name
#                                             (rel_display_name_into -> REL_NAME)
#   -- the string rules, each implemented exactly once --
#   rel_strip_markup <text>                   step 2: inline markup delimiters, link text kept
#   rel_slug_heading <text>                   the heading slug, without the duplicate counter
#   rel_normalise_term <text>                 the concept-label normalisation
#   rel_fact_token <path> <anchor>            the fact anchor-token, without the ordinal
#   -- the KB scan (one awk pass over the scan set; every set below shares it) --
#   rel_scan_kb                               force the scan; lazily triggered otherwise
#   rel_kb_docs                               the KB scan set, basenames, LC_ALL=C ascending
#   rel_doc_slugs <doc>                       emitted heading slugs, document order
#   rel_fact_tokens <doc>                     anchor tokens, document order
#   rel_fact_records <doc>                    status TAB token TAB path TAB anchor TAB from TAB to
#                                             (`anchored` | `unanchored`) -- beyond D9's table
#   rel_fence_mask <doc>                      one 0/1 per physical line -- beyond D9's table
#   rel_block_bodies <doc>                    level TAB marker TAB from TAB to TAB heading-text
#   rel_concept_defs <term>                   the <doc>s defining <term>; resolution needs exactly one
#   rel_concept_terms                         every defined normalised term, LC_ALL=C ascending
#   rel_external_keys                         the keys the external-sources file registers
#   -- rows --
#   rel_normalise_row <10 fields>             the orientation swap, ten lines out
#                                             (also leaves it in REL_NORM_ROW)
#   rel_row_key <10 fields>                   the duplicate key, US separated
#                                             (rel_row_key_into -> REL_ROW_KEY)
#   rel_sort_key <10 fields>                  the (class, ids, relations) sort tuple
#                                             (rel_sort_key_into -> REL_SORT_KEY)
#   rel_class0_block <file>                   header + delimiter + the class-0 prefix
#   rel_coverage_extra_keys <file> <table>    extra-row keys of `kinds`|`exclusions`, file order
#   rel_coverage_fixed_keys <table>           the fixed-row keys of that table, in fixed order
#
# TWO of the functions above sit BEYOND the specified loader surface, and the
# deviation is deliberate rather than accidental: `rel_fact_records` and
# `rel_fence_mask`. Both are named by the declared-fact harvester's documented seam,
# and the only alternative to exposing them is that caller re-implementing this
# library's fenced-code state and its citation predicate - a second copy of two
# rules that live here, in the one place where "cannot disagree about where a fence
# begins" has to hold ACROSS a feature boundary. Both are strictly additive: no
# other function's contract changes, and nothing inside this file depends on them.
# The specified surface owes two rows.
#
# Exit codes (direct execution; also the RETURN codes of the functions above):
#   0 - success / predicate true
#   1 - predicate false, or not found
#   2 - usage error, or a fail-closed carrier load
#
#   The loaders RETURN 2 and print a diagnostic naming the resolved absolute path;
#   they never call `exit`. A library that exited would kill a sourcing test
#   harness, and the contract's "exit 2" is a property of the RUN: every caller
#   pairs the load with `|| exit 2`, so the observable behaviour of
#   validate-relationships.sh is exactly the specified one.

# ---------------------------------------------------------------------------
# Separators and constants
# ---------------------------------------------------------------------------

REL_NL=$'\n'
REL_TAB=$'\t'
REL_US=$'\x1f'          # the row-key separator; cannot occur in any id or label

# The declared key set of a vocabulary entry, in the FIXED order the loader
# enforces. This is the contract's own list - field NAMES, not vocabulary
# content - and a new key is inserted before `endpoint_kinds`, never after
# `definition`, so the one prose field stays terminal.
REL_VOCAB_KEYS="relation inverse symmetry category derived_from endpoint_kinds passes definition"

# The fixed first-cell keys of the `### Enumeration exclusions` coverage table, in
# their fixed order. The kinds table's fixed keys are the Kind enum itself and are
# read from the schema carrier, never repeated here. These three have no carrier:
# they are stated once, here, because a second copy of a fixed row set is a
# divergence waiting to happen.
REL_COVERAGE_EXCLUSION_KEYS="generated/derived trees${REL_NL}vendored third-party code${REL_NL}\`.aid/settings.yml\` ignore list"

# The path pattern a durable anchor's first token must match, and the file
# extensions a citation may name. One pattern, one home.
#
# The `\\.` is deliberate and load-bearing: this string is consumed through
# `awk -v`, which processes escape sequences in the assigned value, so a single
# `\.` reaches awk as a bare `.` -- an any-character wildcard that would let a
# prose sentence satisfy the durable-anchor predicate. Doubling it makes awk see
# `\.`, a literal dot. awk warns about the single form, which is how this was
# caught.
#
# The charset and the extension set are the two carriers; the regex is BUILT from
# them and `rel__is_citation_path` tests against the same two. A second copy of
# either would be a divergence waiting to happen.
REL_PATH_CHARSET='A-Za-z0-9_./-'
REL_CITE_EXTENSIONS='md sh py mjs js ts yml yaml json toml txt ps1'
REL_PATH_RE="[${REL_PATH_CHARSET}]+\\\\.(${REL_CITE_EXTENSIONS// /|})"

# The fenced-code-block delimiter. ONE carrier, two consumers - the whole-KB
# tokeniser and `rel_fence_mask` - passed to each by `awk -v`, because "the heading
# counter, the block boundaries and the marker scan cannot disagree about where a
# fence begins" is only true while there is one predicate to disagree about. It is
# the single reason `rel_fence_mask` exists rather than each caller writing its own
# fence scan.
REL_FENCE_RE='^[[:space:]]*(```|~~~)'

# ---------------------------------------------------------------------------
# Globals. Declared and emptied here so a reader can find every one of them.
# ---------------------------------------------------------------------------

# schema carrier
REL_SCHEMA_FILE=""
REL_COLUMNS=""            # LF separated, carrier order
REL_REQUIRED=""           # LF separated
REL_OPTIONAL=""           # LF separated
REL_PROVENANCE=""         # space separated
REL_PREFIXES=""           # space separated
REL_KINDS=""              # space separated, carrier order
REL_KIND_PREFIX_TABLE=""  # lookup: LF kind TAB prefix,prefix
REL_IMAGE_EXTENSIONS=""   # space separated (significance-rules.sh reads this name)

# vocabulary carrier
REL_VOCAB_CORE=""
REL_VOCAB_EXT=""
REL_VOCAB_RELATIONS=""    # LF separated, LC_ALL=C ascending
REL_VOCAB_CATEGORIES=""   # LF separated, LC_ALL=C ascending
REL_T_INVERSE=""          # the eight lookup tables: LF relation TAB value
REL_T_SYMMETRY=""
REL_T_CATEGORY=""
REL_T_DERIVED_FROM=""
REL_T_ENDPOINT_KINDS=""
REL_T_PASSES=""
REL_T_DEFINITION=""
REL_T_ORIGIN=""

# roots
REL_REPO_ROOT=""
REL_KB_ROOT=".aid/knowledge"
REL_EXTERNAL_SOURCES=""

# the KB scan
REL_KB_SCANNED=0
REL_KB_DOCS=""            # LF separated basenames, LC_ALL=C ascending
REL_SECTION_IDS=""        # LF separated <doc>#<slug>, document order within a doc
REL_T_SECTION_TEXT=""     # lookup: <doc>#<slug> -> heading text
REL_FACT_IDS=""           # LF separated <doc>#fact:<token>
REL_T_FACT_ANCHOR=""      # lookup: <doc>#fact:<token> -> anchor string
REL_FACT_RECORDS=""       # LF separated: doc TAB status TAB token TAB path TAB anchor TAB from TAB to
REL_DEFS=""               # LF separated: term TAB doc TAB level TAB as-written
REL_EXTERNAL_KEYS=""      # LF separated
REL_EXTERNAL_SCANNED=0
REL_BLOCKS=""             # LF separated: doc TAB level TAB marker TAB from TAB to TAB text

# scratch outputs
REL_LOOKUP=""
REL_ID_PREFIX=""; REL_ID_BODY=""; REL_ID_DOC=""; REL_ID_FRAGMENT=""
REL_ID_TERM=""; REL_ID_QUAL_DOC=""; REL_ID_KIND=""; REL_ID_REASON=""
REL_KIND_REASON=""
REL_STR=""                # the string rules' `_into` output
REL_SET=""                # rel__sorted_set output
REL_NORM_ROW=""           # LF separated ten fields
REL_DEF_COUNT=0           # rel__count_defs output
REL_CITES=()              # rel__block_citations_into output
REL_ROW_CELLS=()          # rel__row_cells_into output
REL_RESOLVE=""            # rel_resolve_id_into output
REL_NAME=""               # rel_display_name_into output
REL_ROW_KEY=""            # rel_row_key_into output
REL_SORT_KEY=""           # rel_sort_key_into output

# ---------------------------------------------------------------------------
# Diagnostics and paths
# ---------------------------------------------------------------------------

rel__err() { printf 'relationship-schema.sh: %s\n' "$*" >&2; }

# An absolute path for a diagnostic. `realpath` is probed, never assumed - its
# flags differ across GNU/BSD/macOS and it is absent on some Git Bash installs.
rel_abs_path() {
    local p="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath -m "$p" 2>/dev/null || printf '%s/%s' "$(pwd)" "${p#./}"
    else
        case "$p" in
            /*|[A-Za-z]:[/\\]*) printf '%s' "$p" ;;
            *) printf '%s/%s' "$(pwd)" "${p#./}" ;;
        esac
    fi
}

# ---------------------------------------------------------------------------
# Fork-free primitives
# ---------------------------------------------------------------------------

# Case folding. `${v,,}` needs bash 4 and bash 3.2 cannot parse it, so the fast
# form is installed behind a version probe and the fallback forks tr once.
if [ "${BASH_VERSINFO[0]:-3}" -ge 4 ]; then
    eval 'rel__lower_into() { REL_STR="${1,,}"; }'
else
    rel__lower_into() {
        REL_STR=$(printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')
    }
fi

rel__trim_into() {
    local t="$1"
    t="${t#"${t%%[![:space:]]*}"}"
    REL_STR="${t%"${t##*[![:space:]]}"}"
}

# rel__lookup <table> <key>  -> REL_LOOKUP ; 1 when absent.
# A table is  LF key TAB value  repeated. Pure parameter expansion: no fork, and
# no associative array (bash 3.2 has none).
rel__lookup() {
    local hay="$1" key="$2" rest
    case "$hay" in
        *"$REL_NL$key$REL_TAB"*) ;;
        *) REL_LOOKUP=""; return 1 ;;
    esac
    rest="${hay#*"$REL_NL$key$REL_TAB"}"
    REL_LOOKUP="${rest%%"$REL_NL"*}"
    return 0
}

# rel__has_line <lf-list> <line>
rel__has_line() {
    case "$REL_NL$1$REL_NL" in
        *"$REL_NL$2$REL_NL"*) return 0 ;;
    esac
    return 1
}

# rel__has_word <space-list> <word>
rel__has_word() {
    case " $1 " in
        *" $2 "*) return 0 ;;
    esac
    return 1
}

# rel__sorted_set <token ...> -> REL_SET (space separated, LC_ALL=C ascending,
# deduplicated). An in-shell insertion sort: the lists are a handful of tokens and
# a `sort` fork costs ~100 ms under MSYS. `local LC_ALL=C` pins the collation of
# the `<` comparison to the same total byte order `LC_ALL=C sort` produces.
rel__sorted_set() {
    local LC_ALL=C
    local out="" t cur rest placed
    for t in "$@"; do
        [ -n "$t" ] || continue
        case " $out " in *" $t "*) continue ;; esac
        placed=0; cur=""; rest="$out"
        while [ -n "$rest" ]; do
            local head="${rest%% *}"
            rest="${rest#"$head"}"; rest="${rest# }"
            if [ "$placed" -eq 0 ] && [[ "$t" < "$head" ]]; then
                cur="${cur:+$cur }$t"; placed=1
            fi
            cur="${cur:+$cur }$head"
        done
        [ "$placed" -eq 1 ] || cur="${cur:+$cur }$t"
        out="$cur"
    done
    REL_SET="$out"
}

# rel__sort_lines <lf-list> -> REL_STR, LC_ALL=C ascending, deduplicated.
rel__sort_lines() {
    local LC_ALL=C
    local line out=""
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        rel__has_line "$out" "$line" && continue
        # insertion into the LF list
        local cur="" rest="$out" placed=0 h
        while [ -n "$rest" ]; do
            h="${rest%%"$REL_NL"*}"
            if [ "$h" = "$rest" ]; then rest=""; else rest="${rest#*"$REL_NL"}"; fi
            if [ "$placed" -eq 0 ] && [[ "$line" < "$h" ]]; then
                cur="${cur:+$cur$REL_NL}$line"; placed=1
            fi
            cur="${cur:+$cur$REL_NL}$h"
        done
        [ "$placed" -eq 1 ] || cur="${cur:+$cur$REL_NL}$line"
        out="$cur"
    done <<EOF
$1
EOF
    REL_STR="$out"
}

# ===========================================================================
# D1 / D1a - the schema carrier
# ===========================================================================

# One awk pass, emitting  key TAB normalised-value  for a flat restricted-YAML
# file: top-level `key: [flow, sequence]` scalars plus one block sequence
# (`kinds:`). Full-line comments and blank lines are skipped anywhere; a `#`
# inside a value is content, never a comment. Violations are emitted as
# `!` records so the shell decides the diagnostic, never awk.
rel__schema_awk() {
    awk '
        function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
        { line = $0; sub(/\r$/, "", line) }
        line ~ /^[[:space:]]*#/ { next }
        line ~ /^[[:space:]]*$/ { next }
        line == "---" { printf "!\t%d\tsecond YAML document\n", FNR; next }
        # a block-sequence item belongs to the most recent top-level key
        line ~ /^  - / {
            if (cur == "") { printf "!\t%d\tlist item outside any key\n", FNR; next }
            v = trim(substr(line, 5))
            printf "L\t%s\t%s\t%d\n", cur, v, FNR
            next
        }
        line ~ /^[[:space:]]/ { printf "!\t%d\tunexpected indentation\n", FNR; next }
        match(line, /^[A-Za-z_][A-Za-z0-9_]*:/) {
            k = substr(line, 1, RLENGTH - 1)
            v = trim(substr(line, RLENGTH + 1))
            if (k == "<<") { printf "!\t%d\tmerge key\n", FNR; next }
            if (v ~ /^[&*]/) { printf "!\t%d\tanchor or alias\n", FNR; next }
            if (v == "|" || v == ">" || v == "|-" || v == ">-" || v == "|+" || v == ">+") {
                printf "!\t%d\tblock scalar\n", FNR; next
            }
            if (v ~ /^\[/ && v !~ /\]$/) { printf "!\t%d\tflow sequence not on one physical line\n", FNR; next }
            cur = k
            printf "K\t%s\t%s\t%d\n", k, v, FNR
            next
        }
        { printf "!\t%d\tunparseable line\n", FNR }
    ' "$1"
}

# Split a `[a, b, c]` flow sequence into LF-separated tokens, quotes stripped.
rel__flow_into() {
    local v="$1" body t out=""
    case "$v" in
        \[*\]) body="${v#\[}"; body="${body%\]}" ;;
        *) REL_STR=""; return 1 ;;
    esac
    local IFS=','
    # shellcheck disable=SC2086  # deliberate split on the flow separator
    set -- $body
    IFS=' '
    for t in "$@"; do
        rel__trim_into "$t"; t="$REL_STR"
        case "$t" in \"*\") t="${t#\"}"; t="${t%\"}" ;; esac
        [ -n "$t" ] || continue
        out="${out:+$out$REL_NL}$t"
    done
    REL_STR="$out"
    return 0
}

# rel_load_schema <file>
rel_load_schema() {
    local file="${1:-}"
    if [ -z "$file" ]; then rel__err "rel_load_schema: a schema file is required"; return 2; fi
    if [ ! -f "$file" ]; then
        rel__err "schema carrier not found at $(rel_abs_path "$file")"; return 2
    fi
    local abs; abs="$(rel_abs_path "$file")"

    REL_SCHEMA_FILE="$abs"
    REL_COLUMNS=""; REL_REQUIRED=""; REL_OPTIONAL=""; REL_PROVENANCE=""
    REL_PREFIXES=""; REL_KINDS=""; REL_KIND_PREFIX_TABLE=""; REL_IMAGE_EXTENSIONS=""

    local rec kind key val lineno seen="" kinds_raw=""
    while IFS= read -r rec; do
        [ -n "$rec" ] || continue
        kind="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
        case "$kind" in
            '!')
                lineno="${rec%%"$REL_TAB"*}"; val="${rec#*"$REL_TAB"}"
                rel__err "$abs:$lineno: restricted-YAML violation: $val"
                return 2 ;;
            K)
                key="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
                val="${rec%%"$REL_TAB"*}"; lineno="${rec##*"$REL_TAB"}"
                if rel__has_word "$seen" "$key"; then
                    rel__err "$abs:$lineno: duplicate top-level key '$key'"; return 2
                fi
                seen="${seen:+$seen }$key"
                case "$key" in
                    columns|required|optional|provenance|prefixes|image_extensions)
                        if ! rel__flow_into "$val"; then
                            rel__err "$abs:$lineno: '$key' must be a one-line flow sequence"; return 2
                        fi
                        case "$key" in
                            columns)  REL_COLUMNS="$REL_STR" ;;
                            required) REL_REQUIRED="$REL_STR" ;;
                            optional) REL_OPTIONAL="$REL_STR" ;;
                            provenance)       REL_PROVENANCE="${REL_STR//"$REL_NL"/ }" ;;
                            prefixes)         REL_PREFIXES="${REL_STR//"$REL_NL"/ }" ;;
                            image_extensions) REL_IMAGE_EXTENSIONS="${REL_STR//"$REL_NL"/ }" ;;
                        esac ;;
                    kinds)
                        if [ -n "$val" ]; then
                            rel__err "$abs:$lineno: 'kinds' must be a block sequence, not an inline value"
                            return 2
                        fi ;;
                    *)
                        rel__err "$abs:$lineno: unknown top-level key '$key'"; return 2 ;;
                esac ;;
            L)
                key="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
                val="${rec%%"$REL_TAB"*}"; lineno="${rec##*"$REL_TAB"}"
                if [ "$key" != "kinds" ]; then
                    rel__err "$abs:$lineno: '$key' takes no block-sequence items"; return 2
                fi
                case "$val" in
                    \"*\") val="${val#\"}"; val="${val%\"}" ;;
                    *) rel__err "$abs:$lineno: a 'kinds' item must be a double-quoted token"; return 2 ;;
                esac
                kinds_raw="${kinds_raw:+$kinds_raw$REL_NL}$val" ;;
        esac
    done < <(rel__schema_awk "$file")

    local k
    for k in columns required optional provenance prefixes kinds image_extensions; do
        if ! rel__has_word "$seen" "$k"; then
            rel__err "$abs: required key '$k' is absent"; return 2
        fi
    done
    for k in REL_COLUMNS REL_REQUIRED REL_OPTIONAL REL_PROVENANCE REL_PREFIXES REL_IMAGE_EXTENSIONS; do
        if [ -z "${!k}" ]; then
            rel__err "$abs: '$k' resolved empty"; return 2
        fi
    done
    if [ -z "$kinds_raw" ]; then rel__err "$abs: 'kinds' is empty"; return 2; fi

    # required and optional must partition columns.
    local c
    while IFS= read -r c; do
        [ -n "$c" ] || continue
        if rel__has_line "$REL_REQUIRED" "$c"; then
            rel__has_line "$REL_OPTIONAL" "$c" && { rel__err "$abs: column '$c' is both required and optional"; return 2; }
        elif ! rel__has_line "$REL_OPTIONAL" "$c"; then
            rel__err "$abs: column '$c' is in neither 'required' nor 'optional'"; return 2
        fi
    done <<EOF
$REL_COLUMNS
EOF
    while IFS= read -r c; do
        [ -n "$c" ] || continue
        rel__has_line "$REL_COLUMNS" "$c" || { rel__err "$abs: 'required' names '$c', which is not a column"; return 2; }
    done <<EOF
$REL_REQUIRED
EOF
    while IFS= read -r c; do
        [ -n "$c" ] || continue
        rel__has_line "$REL_COLUMNS" "$c" || { rel__err "$abs: 'optional' names '$c', which is not a column"; return 2; }
    done <<EOF
$REL_OPTIONAL
EOF

    # kinds: "<kind>|<prefix>[,<prefix>...]" - the pairing is DATA, so the
    # branching kind (two permitted prefixes) is a value the loader reads and a
    # one-to-one implementation is unrepresentable rather than merely discouraged.
    local tok name prefs p
    while IFS= read -r tok; do
        [ -n "$tok" ] || continue
        case "$tok" in
            *"|"*) ;;
            *) rel__err "$abs: kinds token '$tok' is not '<kind>|<prefixes>'"; return 2 ;;
        esac
        name="${tok%%|*}"; prefs="${tok#*|}"
        if [ -z "$name" ] || [ -z "$prefs" ]; then
            rel__err "$abs: kinds token '$tok' has an empty side"; return 2
        fi
        if rel__has_word "$REL_KINDS" "$name"; then
            rel__err "$abs: kind '$name' is declared twice"; return 2
        fi
        local IFS=','
        # shellcheck disable=SC2086  # deliberate split on the prefix separator
        set -- $prefs
        IFS=' '
        for p in "$@"; do
            rel__trim_into "$p"; p="$REL_STR"
            if [ -z "$p" ] || ! rel__has_word "$REL_PREFIXES" "$p"; then
                rel__err "$abs: kind '$name' names prefix '$p', which is not in 'prefixes'"; return 2
            fi
        done
        REL_KINDS="${REL_KINDS:+$REL_KINDS }$name"
        REL_KIND_PREFIX_TABLE="$REL_KIND_PREFIX_TABLE$REL_NL$name$REL_TAB${prefs// /}"
    done <<EOF
$kinds_raw
EOF
    return 0
}

rel_columns()           { printf '%s\n' "$REL_COLUMNS"; }
rel_required_columns()  { printf '%s\n' "$REL_REQUIRED"; }
rel_optional_columns()  { printf '%s\n' "$REL_OPTIONAL"; }
rel_provenance_values() { printf '%s' "$REL_PROVENANCE"; }
rel_prefixes()          { printf '%s' "$REL_PREFIXES"; }
rel_kinds()             { printf '%s' "$REL_KINDS"; }
rel_image_extensions()  { printf '%s' "$REL_IMAGE_EXTENSIONS"; }

rel_kind_prefixes() {
    rel__lookup "$REL_KIND_PREFIX_TABLE" "$1" || return 1
    printf '%s' "${REL_LOOKUP//,/ }"
}

# ===========================================================================
# D4 - the relation vocabulary: core plus optional project extension
# ===========================================================================

# One awk pass per vocabulary file. Emits, per record:
#   E TAB ordinal TAB lineno                       an entry starts
#   K TAB ordinal TAB seq TAB key TAB value        an entry key, in physical order
#   C TAB lineno TAB token                         a categories item, quotes stripped
#   ! TAB lineno TAB message                       a restricted-subset violation
# Values are opaque data. Every judgment about them is the shell's.
rel__vocab_awk() {
    awk '
        function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
        function bad(m) { printf "!\t%d\t%s\n", FNR, m }
        BEGIN { section = ""; ord = 0; seq = 0 }
        { line = $0; sub(/\r$/, "", line) }
        line ~ /^[[:space:]]*#/ { next }
        line ~ /^[[:space:]]*$/ { next }
        line == "---" { bad("second YAML document"); next }
        line == "pairs:" { section = "pairs"; next }
        line == "categories:" { section = "categories"; next }
        line !~ /^[[:space:]]/ {
            if (match(line, /^[A-Za-z_][A-Za-z0-9_]*:/)) bad("unknown top-level key " substr(line, 1, RLENGTH - 1))
            else bad("unparseable top-level line")
            next
        }
        section == "" { bad("content before any top-level key"); next }
        section == "categories" {
            if (line !~ /^  - /) { bad("a categories item must be `  - \"<name>|<meaning>\"`"); next }
            v = trim(substr(line, 5))
            if (v !~ /^".*"$/) { bad("a categories item must be double quoted"); next }
            printf "C\t%d\t%s\n", FNR, substr(v, 2, length(v) - 2)
            next
        }
        # section == "pairs"
        line ~ /^  - / {
            v = substr(line, 5)
            if (!match(v, /^[A-Za-z_][A-Za-z0-9_]*:/)) { bad("an entry must open with `  - <key>: <value>`"); next }
            ord++; seq = 1
            printf "E\t%d\t%d\n", ord, FNR
            printf "K\t%d\t%d\t%s\t%s\n", ord, seq, substr(v, 1, RLENGTH - 1), trim(substr(v, RLENGTH + 1))
            next
        }
        line ~ /^    [^ ]/ {
            if (ord == 0) { bad("an entry key before any entry"); next }
            v = substr(line, 5)
            if (!match(v, /^[A-Za-z_][A-Za-z0-9_]*:/)) { bad("unparseable entry key"); next }
            k = substr(v, 1, RLENGTH - 1)
            val = trim(substr(v, RLENGTH + 1))
            if (k == "<<") { bad("merge key"); next }
            if (val ~ /^[&*]/) { bad("anchor or alias in " k); next }
            if (val == "|" || val == ">" || val == "|-" || val == ">-" || val == "|+" || val == ">+") {
                bad("block scalar in " k); next
            }
            if (val ~ /^\[/ && val !~ /\]$/) { bad(k " flow sequence is not on one physical line"); next }
            if (val == "") { bad(k " has an empty value"); next }
            seq++
            printf "K\t%d\t%d\t%s\t%s\n", ord, seq, k, val
            next
        }
        { bad("unexpected indentation - nesting below an entry is not in the restricted subset") }
    ' "$1"
}

# rel_load_vocabulary <core> [<extension>]
rel_load_vocabulary() {
    local core="${1:-}" ext="${2:-}"
    if [ -z "$REL_KINDS" ] || [ -z "$REL_PROVENANCE" ]; then
        rel__err "rel_load_vocabulary: call rel_load_schema first - the Kind and Provenance enums are its carrier's"
        return 2
    fi
    if [ -z "$core" ]; then rel__err "rel_load_vocabulary: a core vocabulary file is required"; return 2; fi
    if [ ! -f "$core" ]; then
        rel__err "core relation vocabulary not found at $(rel_abs_path "$core") - feature-001 is the blocking dependency"
        return 2
    fi
    REL_VOCAB_CORE="$(rel_abs_path "$core")"
    REL_VOCAB_EXT=""
    if [ -n "$ext" ]; then
        if [ -f "$ext" ]; then
            REL_VOCAB_EXT="$(rel_abs_path "$ext")"
        else
            # A missing extension is not an error: most projects have none, and
            # failing on absence would break the genericity claim on the majority
            # case. An extension path that was ASKED for and is absent is still
            # only a notice.
            rel__err "notice: no project vocabulary extension at $(rel_abs_path "$ext"); using the core alone"
        fi
    fi

    REL_VOCAB_RELATIONS=""; REL_VOCAB_CATEGORIES=""
    REL_T_INVERSE=""; REL_T_SYMMETRY=""; REL_T_CATEGORY=""; REL_T_DERIVED_FROM=""
    REL_T_ENDPOINT_KINDS=""; REL_T_PASSES=""; REL_T_DEFINITION=""; REL_T_ORIGIN=""

    local cat_names="" cat_origin=""
    local file origin
    for origin in core extension; do
        if [ "$origin" = core ]; then file="$REL_VOCAB_CORE"; else file="$REL_VOCAB_EXT"; fi
        [ -n "$file" ] || continue

        local rec type ord seq key val lineno
        local e_ord="" e_line="" e_keys="" e_seq=0
        local v_relation="" v_inverse="" v_symmetry="" v_category=""
        local v_derived="" v_endpoints="" v_passes="" v_definition=""
        local saw_entry=0

        # rel__vocab_flush validates the entry just completed. Declared as a
        # nested closure over the locals above deliberately: the entry state is
        # the loop's, and passing eight values through an argument list would
        # invite one of them being forgotten at one of the two call sites.
        rel__vocab_flush() {
            [ -n "$e_ord" ] || return 0
            local ident="entry $e_ord"
            [ -n "$v_relation" ] && ident="relation '$v_relation'"

            # totality and fixed key order, in one comparison
            if [ "$e_keys" != "$REL_VOCAB_KEYS" ]; then
                local want got missing="" unknown="" k
                for want in $REL_VOCAB_KEYS; do
                    rel__has_word "$e_keys" "$want" || missing="${missing:+$missing }$want"
                done
                for got in $e_keys; do
                    rel__has_word "$REL_VOCAB_KEYS" "$got" || unknown="${unknown:+$unknown }$got"
                done
                if [ -n "$missing" ]; then
                    rel__err "$file:$e_line: $ident is missing declared key(s): $missing"; return 2
                fi
                if [ -n "$unknown" ]; then
                    rel__err "$file:$e_line: $ident carries key(s) outside the declared set: $unknown"; return 2
                fi
                for k in $e_keys; do
                    local n=0 j
                    for j in $e_keys; do [ "$j" = "$k" ] && n=$((n + 1)); done
                    if [ "$n" -gt 1 ]; then
                        rel__err "$file:$e_line: $ident carries key '$k' more than once"; return 2
                    fi
                done
                rel__err "$file:$e_line: $ident presents its keys out of the fixed order (want: $REL_VOCAB_KEYS; got: $e_keys)"
                return 2
            fi

            # relation / inverse charset
            local l
            for l in relation:"$v_relation" inverse:"$v_inverse"; do
                local lk="${l%%:*}" lv="${l#*:}"
                case "$lv" in
                    [a-z]*) ;;
                    *) rel__err "$file:$e_line: $ident: '$lk' value '$lv' must match [a-z][a-z0-9-]*"; return 2 ;;
                esac
                case "$lv" in
                    *[!a-z0-9-]*) rel__err "$file:$e_line: $ident: '$lk' value '$lv' must match [a-z][a-z0-9-]*"; return 2 ;;
                esac
            done

            case "$v_symmetry" in
                asymmetric|symmetric) ;;
                *) rel__err "$file:$e_line: $ident: 'symmetry' must be asymmetric or symmetric, not '$v_symmetry'"; return 2 ;;
            esac

            case "$v_category" in
                *[[:space:]]*|\[*) rel__err "$file:$e_line: $ident: 'category' must be a single plain scalar"; return 2 ;;
            esac

            # definition: a double-quoted scalar on one physical line
            case "$v_definition" in
                \"*\") ;;
                *) rel__err "$file:$e_line: $ident: 'definition' must be a double-quoted scalar"; return 2 ;;
            esac
            local defbody="${v_definition#\"}"; defbody="${defbody%\"}"
            case "$defbody" in
                *\"*) rel__err "$file:$e_line: $ident: 'definition' carries an inner double quote"; return 2 ;;
            esac
            [ -n "$defbody" ] || { rel__err "$file:$e_line: $ident: 'definition' is empty"; return 2; }

            # derived_from: shape, token grammar, the coined clauses. The token's
            # <key> is NOT checked for membership of any standard-key set: that
            # set has no carrier this loader reads, and writing it here would put
            # vocabulary content in this tree.
            rel__flow_into "$v_derived" || { rel__err "$file:$e_line: $ident: 'derived_from' must be a one-line flow sequence"; return 2; }
            local dtokens="$REL_STR" t n_coined=0 n_std=0
            [ -n "$dtokens" ] || { rel__err "$file:$e_line: $ident: 'derived_from' is empty"; return 2; }
            case "$v_derived" in *\"*) ;; *) rel__err "$file:$e_line: $ident: 'derived_from' tokens must be double quoted"; return 2 ;; esac
            while IFS= read -r t; do
                [ -n "$t" ] || continue
                if [ "$t" = coined ]; then
                    n_coined=$((n_coined + 1))
                    if [ "$origin" = core ]; then
                        rel__err "$file:$e_line: $ident: 'coined' is forbidden in the core vocabulary"; return 2
                    fi
                    continue
                fi
                n_std=$((n_std + 1))
                if ! rel__derived_token_ok "$t"; then
                    rel__err "$file:$e_line: $ident: 'derived_from' token '$t' matches neither 'coined' nor [a-z][a-z0-9]*:[A-Za-z][A-Za-z0-9-]*"
                    return 2
                fi
            done <<EOF
$dtokens
EOF
            if [ "$n_coined" -gt 0 ] && [ "$n_std" -gt 0 ]; then
                rel__err "$file:$e_line: $ident: 'coined' may not share an entry with a standard token"; return 2
            fi

            # endpoint_kinds: <kind>-><kind>, both sides a name in the Kind enum
            # rel_load_schema already holds. No second copy of that closed set.
            rel__flow_into "$v_endpoints" || { rel__err "$file:$e_line: $ident: 'endpoint_kinds' must be a one-line flow sequence"; return 2; }
            local etokens="$REL_STR" a b
            [ -n "$etokens" ] || { rel__err "$file:$e_line: $ident: 'endpoint_kinds' is empty"; return 2; }
            case "$v_endpoints" in *\"*) ;; *) rel__err "$file:$e_line: $ident: 'endpoint_kinds' tokens must be double quoted"; return 2 ;; esac
            while IFS= read -r t; do
                [ -n "$t" ] || continue
                case "$t" in
                    *"->"*) ;;
                    *) rel__err "$file:$e_line: $ident: 'endpoint_kinds' token '$t' is not '<kind>-><kind>'"; return 2 ;;
                esac
                a="${t%%->*}"; b="${t#*->}"
                case "$b" in *"->"*) rel__err "$file:$e_line: $ident: 'endpoint_kinds' token '$t' carries more than one arrow"; return 2 ;; esac
                if ! rel__has_word "$REL_KINDS" "$a" || ! rel__has_word "$REL_KINDS" "$b"; then
                    rel__err "$file:$e_line: $ident: 'endpoint_kinds' token '$t' names something that is not a Kind (the enum is $REL_KINDS)"
                    return 2
                fi
            done <<EOF
$etokens
EOF

            # passes: a non-empty subset of the Provenance enum.
            rel__flow_into "$v_passes" || { rel__err "$file:$e_line: $ident: 'passes' must be a one-line flow sequence"; return 2; }
            local ptokens="$REL_STR"
            [ -n "$ptokens" ] || { rel__err "$file:$e_line: $ident: 'passes' is empty"; return 2; }
            while IFS= read -r t; do
                [ -n "$t" ] || continue
                rel__has_word "$REL_PROVENANCE" "$t" || {
                    rel__err "$file:$e_line: $ident: 'passes' value '$t' is not in the Provenance enum ($REL_PROVENANCE)"; return 2
                }
            done <<EOF
$ptokens
EOF

            # relation uniqueness across the MERGED set; an extension colliding
            # with the core names both resolved paths.
            if rel__lookup "$REL_T_ORIGIN" "$v_relation"; then
                local other="$REL_LOOKUP" opath="$REL_VOCAB_CORE"
                [ "$other" = extension ] && opath="$REL_VOCAB_EXT"
                rel__err "relation '$v_relation' is declared twice: $opath ($other) and $file ($origin)"
                return 2
            fi

            REL_VOCAB_RELATIONS="${REL_VOCAB_RELATIONS:+$REL_VOCAB_RELATIONS$REL_NL}$v_relation"
            REL_T_INVERSE="$REL_T_INVERSE$REL_NL$v_relation$REL_TAB$v_inverse"
            REL_T_SYMMETRY="$REL_T_SYMMETRY$REL_NL$v_relation$REL_TAB$v_symmetry"
            REL_T_CATEGORY="$REL_T_CATEGORY$REL_NL$v_relation$REL_TAB$v_category"
            REL_T_DERIVED_FROM="$REL_T_DERIVED_FROM$REL_NL$v_relation$REL_TAB${dtokens//"$REL_NL"/ }"
            REL_T_ENDPOINT_KINDS="$REL_T_ENDPOINT_KINDS$REL_NL$v_relation$REL_TAB${etokens//"$REL_NL"/ }"
            REL_T_PASSES="$REL_T_PASSES$REL_NL$v_relation$REL_TAB${ptokens//"$REL_NL"/ }"
            REL_T_DEFINITION="$REL_T_DEFINITION$REL_NL$v_relation$REL_TAB$defbody"
            REL_T_ORIGIN="$REL_T_ORIGIN$REL_NL$v_relation$REL_TAB$origin"
            return 0
        }

        while IFS= read -r rec; do
            [ -n "$rec" ] || continue
            type="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
            case "$type" in
                '!')
                    lineno="${rec%%"$REL_TAB"*}"; val="${rec#*"$REL_TAB"}"
                    rel__err "$file:$lineno: restricted-YAML violation: $val"
                    unset -f rel__vocab_flush; return 2 ;;
                E)
                    rel__vocab_flush || { unset -f rel__vocab_flush; return 2; }
                    ord="${rec%%"$REL_TAB"*}"; lineno="${rec##*"$REL_TAB"}"
                    e_ord="$ord"; e_line="$lineno"; e_keys=""; e_seq=0; saw_entry=1
                    v_relation=""; v_inverse=""; v_symmetry=""; v_category=""
                    v_derived=""; v_endpoints=""; v_passes=""; v_definition="" ;;
                K)
                    ord="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
                    seq="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
                    key="${rec%%"$REL_TAB"*}"; val="${rec#*"$REL_TAB"}"
                    e_seq="$seq"
                    e_keys="${e_keys:+$e_keys }$key"
                    case "$key" in
                        relation)       v_relation="$val" ;;
                        inverse)        v_inverse="$val" ;;
                        symmetry)       v_symmetry="$val" ;;
                        category)       v_category="$val" ;;
                        derived_from)   v_derived="$val" ;;
                        endpoint_kinds) v_endpoints="$val" ;;
                        passes)         v_passes="$val" ;;
                        definition)     v_definition="$val" ;;
                    esac ;;
                C)
                    lineno="${rec%%"$REL_TAB"*}"; val="${rec#*"$REL_TAB"}"
                    case "$val" in
                        *"|"*) ;;
                        *) rel__err "$file:$lineno: categories item '$val' is not '<name>|<meaning>'"
                           unset -f rel__vocab_flush; return 2 ;;
                    esac
                    local cname="${val%%|*}" cmeaning="${val#*|}"
                    if [ -z "$cname" ] || [ -z "$cmeaning" ]; then
                        rel__err "$file:$lineno: categories item '$val' has an empty side"
                        unset -f rel__vocab_flush; return 2
                    fi
                    case "$cname" in
                        *[[:space:]]*) rel__err "$file:$lineno: category name '$cname' carries whitespace"
                                       unset -f rel__vocab_flush; return 2 ;;
                    esac
                    # name uniqueness over the MERGED block: an extension name
                    # equal to a core name is a hard failure, so an extension can
                    # never silently redefine a core category's meaning.
                    if rel__lookup "$cat_origin" "$cname"; then
                        local oc="$REL_LOOKUP" ocp="$REL_VOCAB_CORE"
                        [ "$oc" = extension ] && ocp="$REL_VOCAB_EXT"
                        rel__err "category '$cname' is declared twice: $ocp ($oc) and $file ($origin)"
                        unset -f rel__vocab_flush; return 2
                    fi
                    cat_names="${cat_names:+$cat_names$REL_NL}$cname"
                    cat_origin="$cat_origin$REL_NL$cname$REL_TAB$origin" ;;
            esac
        done < <(rel__vocab_awk "$file")
        rel__vocab_flush || { unset -f rel__vocab_flush; return 2; }
        unset -f rel__vocab_flush

        if [ "$origin" = core ] && [ "$saw_entry" -eq 0 ]; then
            rel__err "$file: no 'pairs:' entries - an absent or empty core vocabulary halts validation rather than passing every row"
            return 2
        fi
    done

    if [ -z "$REL_VOCAB_RELATIONS" ]; then
        rel__err "$REL_VOCAB_CORE: the merged vocabulary is empty"; return 2
    fi
    rel__sort_lines "$cat_names"; REL_VOCAB_CATEGORIES="$REL_STR"
    rel__sort_lines "$REL_VOCAB_RELATIONS"; REL_VOCAB_RELATIONS="$REL_STR"

    rel__vocab_cross_check || return 2
    return 0
}

# The `derived_from` token grammar, less its standard-key membership:
#   coined | [a-z][a-z0-9]*:[A-Za-z][A-Za-z0-9-]*
rel__derived_token_ok() {
    local t="$1" k v
    [ "$t" = coined ] && return 0
    case "$t" in *:*) ;; *) return 1 ;; esac
    k="${t%%:*}"; v="${t#*:}"
    case "$v" in *:*) return 1 ;; esac
    case "$k" in [a-z]*) ;; *) return 1 ;; esac
    case "$k" in *[!a-z0-9]*) return 1 ;; esac
    case "$v" in [A-Za-z]*) ;; *) return 1 ;; esac
    case "$v" in *[!A-Za-z0-9-]*) return 1 ;; esac
    return 0
}

# The cross-entry invariants, over the MERGED set. This list is the contract:
# closure, involution, symmetric consistency, category totality, and pair
# coherence. Totality and the value rules are enforced per entry above. Any
# violation returns 2 - these are file-level defects, never row findings.
rel__vocab_cross_check() {
    local r inv sym
    while IFS= read -r r; do
        [ -n "$r" ] || continue
        rel__lookup "$REL_T_INVERSE" "$r" || { rel__err "internal: no inverse recorded for '$r'"; return 2; }
        inv="$REL_LOOKUP"
        rel__lookup "$REL_T_SYMMETRY" "$r"; sym="$REL_LOOKUP"

        # closure
        if ! rel__lookup "$REL_T_INVERSE" "$inv"; then
            rel__err "closure: relation '$r' declares inverse '$inv', which is no entry's 'relation'"; return 2
        fi
        # involution
        if [ "$REL_LOOKUP" != "$r" ]; then
            rel__err "involution: inverse(inverse('$r')) is '$REL_LOOKUP', not '$r'"; return 2
        fi
        # symmetric consistency - no third case
        if [ "$inv" = "$r" ] && [ "$sym" != symmetric ]; then
            rel__err "symmetric consistency: '$r' is its own inverse but declares symmetry '$sym'"; return 2
        fi
        if [ "$inv" != "$r" ] && [ "$sym" != asymmetric ]; then
            rel__err "symmetric consistency: '$r' has inverse '$inv' but declares symmetry '$sym'"; return 2
        fi
        # category totality - a REFERENCE check; re-declaration is the
        # name-uniqueness check's, above.
        rel__lookup "$REL_T_CATEGORY" "$r"
        if ! rel__has_line "$REL_VOCAB_CATEGORIES" "$REL_LOOKUP"; then
            rel__err "category totality: relation '$r' names category '$REL_LOOKUP', which the merged 'categories:' block does not declare"
            return 2
        fi
        rel__pair_coherent "$r" "$inv" "$sym" || return 2
    done <<EOF
$REL_VOCAB_RELATIONS
EOF
    return 0
}

# Pair coherence - the sixth cross-entry property, and a GATE.
#
#   asymmetric (r, r'):  category, derived_from and passes are EQUAL across the
#                        two entries - equal as token SETS, so order is not
#                        significant and a repeated token is not a difference -
#                        and endpoint_kinds(r') is the exact TRANSPOSE of
#                        endpoint_kinds(r).
#   symmetric  r:        endpoint_kinds is CLOSED under transposition.
#
# `category` is single-valued, so scalar equality is the only reading available to
# it. Checked once per relation rather than once per pair: the check is symmetric
# in its two arguments, so running it from both ends costs one set comparison and
# removes any need to pick a canonical half.
rel__pair_coherent() {
    local r="$1" inv="$2" sym="$3"
    local ek_r ek_i t a b

    rel__lookup "$REL_T_ENDPOINT_KINDS" "$r"; ek_r="$REL_LOOKUP"

    if [ "$sym" = symmetric ]; then
        for t in $ek_r; do
            a="${t%%->*}"; b="${t#*->}"
            if ! rel__has_word "$ek_r" "$b->$a"; then
                rel__err "pair coherence: symmetric relation '$r' declares endpoint token '$t' without its mirror '$b->$a'; a symmetric entry's endpoint_kinds must be closed under transposition"
                return 2
            fi
        done
        return 0
    fi

    rel__lookup "$REL_T_ENDPOINT_KINDS" "$inv"; ek_i="$REL_LOOKUP"
    for t in $ek_r; do
        a="${t%%->*}"; b="${t#*->}"
        if ! rel__has_word "$ek_i" "$b->$a"; then
            rel__err "pair coherence: '$r' declares endpoint token '$t' but its inverse '$inv' does not declare the transpose '$b->$a'"
            return 2
        fi
    done
    for t in $ek_i; do
        a="${t%%->*}"; b="${t#*->}"
        if ! rel__has_word "$ek_r" "$b->$a"; then
            rel__err "pair coherence: '$inv' declares endpoint token '$t' but its inverse '$r' does not declare the transpose '$b->$a'"
            return 2
        fi
    done

    local key
    for key in category derived_from passes; do
        local ta tb
        case "$key" in
            category)     rel__lookup "$REL_T_CATEGORY" "$r";     ta="$REL_LOOKUP"
                          rel__lookup "$REL_T_CATEGORY" "$inv";   tb="$REL_LOOKUP" ;;
            derived_from) rel__lookup "$REL_T_DERIVED_FROM" "$r"; ta="$REL_LOOKUP"
                          rel__lookup "$REL_T_DERIVED_FROM" "$inv"; tb="$REL_LOOKUP" ;;
            passes)       rel__lookup "$REL_T_PASSES" "$r";       ta="$REL_LOOKUP"
                          rel__lookup "$REL_T_PASSES" "$inv";     tb="$REL_LOOKUP" ;;
        esac
        # shellcheck disable=SC2086  # deliberate split: these are token lists
        rel__sorted_set $ta; local sa="$REL_SET"
        # shellcheck disable=SC2086
        rel__sorted_set $tb; local sb="$REL_SET"
        if [ "$sa" != "$sb" ]; then
            rel__err "pair coherence: '$r' and its inverse '$inv' disagree on '$key' ('$ta' vs '$tb'); the two halves of a pair must carry the same token set"
            return 2
        fi
    done
    return 0
}

rel_vocab_relations() { printf '%s\n' "$REL_VOCAB_RELATIONS"; }
rel_categories()      { printf '%s\n' "$REL_VOCAB_CATEGORIES"; }

# Membership (V3): a label is valid iff it is some merged entry's relation or
# inverse. Closure makes the second clause redundant and it is checked anyway,
# because closure is the loader's guarantee and this is the row's question.
rel_is_relation() {
    rel__lookup "$REL_T_INVERSE" "$1" >/dev/null 2>&1 && return 0
    local r
    while IFS= read -r r; do
        [ -n "$r" ] || continue
        rel__lookup "$REL_T_INVERSE" "$r"
        [ "$REL_LOOKUP" = "$1" ] && return 0
    done <<EOF
$REL_VOCAB_RELATIONS
EOF
    return 1
}

# Pairing (V4): (S2T, T2S) is valid iff some merged entry has
# relation == S2T && inverse == T2S, OR relation == T2S && inverse == S2T.
# Accepting the mirror is what makes the storage-orientation normalisation safe.
# A symmetric entry yields S2T == T2S and is VALID, not a disagreement.
rel_pair_ok() {
    local s="$1" t="$2"
    if rel__lookup "$REL_T_INVERSE" "$s" && [ "$REL_LOOKUP" = "$t" ]; then return 0; fi
    if rel__lookup "$REL_T_INVERSE" "$t" && [ "$REL_LOOKUP" = "$s" ]; then return 0; fi
    return 1
}

# `_into` twins for the two accessors a per-row loop touches. Both leave the value
# in REL_LOOKUP, which the caller must read before the next lookup.
rel_endpoint_kinds_into() { rel__lookup "$REL_T_ENDPOINT_KINDS" "$1"; }
rel_passes_into()         { rel__lookup "$REL_T_PASSES" "$1"; }

rel_inverse_of()       { rel__lookup "$REL_T_INVERSE" "$1" || return 1; printf '%s' "$REL_LOOKUP"; }
rel_category()         { rel__lookup "$REL_T_CATEGORY" "$1" || return 1; printf '%s' "$REL_LOOKUP"; }
rel_endpoint_kinds()   { rel__lookup "$REL_T_ENDPOINT_KINDS" "$1" || return 1; printf '%s' "$REL_LOOKUP"; }
rel_passes()           { rel__lookup "$REL_T_PASSES" "$1" || return 1; printf '%s' "$REL_LOOKUP"; }
rel_definition()       { rel__lookup "$REL_T_DEFINITION" "$1" || return 1; printf '%s' "$REL_LOOKUP"; }
rel_derived_from()     { rel__lookup "$REL_T_DERIVED_FROM" "$1" || return 1; printf '%s' "$REL_LOOKUP"; }
rel_relation_origin()  { rel__lookup "$REL_T_ORIGIN" "$1" || return 1; printf '%s' "$REL_LOOKUP"; }

# ===========================================================================
# The string rules. Each is implemented EXACTLY ONCE, here, in shell - the awk
# scan below is a tokeniser that emits raw text and decides nothing, so writer
# and validator cannot disagree about where a cut fell.
# ===========================================================================

# Step 2 - remove inline markup delimiters that carry no text: backticks, `*`,
# and the brackets of a link, keeping the link text. `_` is NOT removed: no
# mechanical rule distinguishes emphasis-`_` from a literal one, and the section
# slug retains `_` (verified against this KB's own Contents links), so removing it
# here would break the id-equals-anchor property.
rel_strip_markup_into() {
    local s="$1" pre post
    # `[text](target)` -> `text`: drop the `](target)` span, then the brackets.
    while : ; do
        case "$s" in *"]("*) ;; *) break ;; esac
        pre="${s%%"]("*}"
        post="${s#*"]("}"
        case "$post" in *")"*) post="${post#*)}" ;; *) post="" ;; esac
        s="$pre$post"
    done
    s="${s//\[/}"
    s="${s//\]/}"
    s="${s//\`/}"
    s="${s//\*/}"
    REL_STR="$s"
}
rel_strip_markup() { rel_strip_markup_into "$1"; printf '%s' "$REL_STR"; }

# D2a-1 steps 1-5 - the heading slug, without the duplicate counter.
#   1 trim; 2 strip markup; 3 lowercase; 4 delete every character outside
#   [a-z0-9_ -], the character only and never a neighbouring space; 5 replace
#   EACH space with one `-`, one for one - runs are NOT collapsed, which is what
#   keeps a `/`-between-spaces heading resolving to the anchor its own Contents
#   link encodes.
rel_slug_heading_into() {
    local s
    rel__trim_into "$1"; s="$REL_STR"
    rel_strip_markup_into "$s"; s="$REL_STR"
    rel__lower_into "$s"; s="$REL_STR"
    s="${s//[!a-z0-9_ -]/}"
    s="${s// /-}"
    REL_STR="$s"
}
rel_slug_heading() { rel_slug_heading_into "$1"; printf '%s' "$REL_STR"; }

# Collapse runs of `-` and trim the ends. Used by the fact tokeniser and by the
# concept normaliser - deliberately NOT by rel_slug_heading, which owes an
# anchor-equality obligation the other two do not.
rel__collapse_hyphens_into() {
    local s="$1"
    while [ "${s//--/-}" != "$s" ]; do s="${s//--/-}"; done
    while [ "${s#-}" != "$s" ]; do s="${s#-}"; done
    while [ "${s%-}" != "$s" ]; do s="${s%-}"; done
    REL_STR="$s"
}

# Collapse whitespace runs (tabs and newlines included) to single spaces.
rel__collapse_space_into() {
    local s="$1"
    s="${s//"$REL_TAB"/ }"
    s="${s//"$REL_NL"/ }"
    s="${s//$'\r'/ }"
    while [ "${s//  / }" != "$s" ]; do s="${s//  / }"; done
    rel__trim_into "$s"
}

# D2a-3 steps 1-5 - the concept label normalisation.
rel_normalise_term_into() {
    local s out="" i n c p nx
    rel_strip_markup_into "$1"; s="$REL_STR"
    # step 2: split compounds - a space at a lower-or-digit -> upper boundary and
    # at an ACRONYM -> Word boundary. The project's own precedent
    # (harvest-coined-terms.sh's two passes), so `AidInstallCore` normalises to
    # `aid-install-core` and not `aidinstallcore`.
    n=${#s}
    i=0
    while [ "$i" -lt "$n" ]; do
        c="${s:i:1}"
        if [ "$i" -gt 0 ]; then
            p="${s:i-1:1}"
            nx=""
            [ $((i + 1)) -lt "$n" ] && nx="${s:i+1:1}"
            case "$c" in
                [A-Z])
                    case "$p" in
                        [a-z0-9]) out="$out " ;;
                        [A-Z]) case "$nx" in [a-z]) out="$out " ;; esac ;;
                    esac ;;
            esac
        fi
        out="$out$c"
        i=$((i + 1))
    done
    rel__lower_into "$out"; s="$REL_STR"
    # step 4: `_`, `-` and whitespace runs each become a single `-`
    s="${s//_/-}"
    rel__collapse_space_into "$s"; s="$REL_STR"
    s="${s// /-}"
    # step 5: delete outside [a-z0-9-]; collapse runs; trim
    s="${s//[!a-z0-9-]/}"
    rel__collapse_hyphens_into "$s"
}
rel_normalise_term() { rel_normalise_term_into "$1"; printf '%s' "$REL_STR"; }

# D2a-2 - the <anchor-token> for a fact id, WITHOUT the collision ordinal.
#   <path-slug> "--" <anchor-slug>
# path-slug: lowercased, `/` and `.` -> `-`, then steps 4-5, runs collapsed,
#            ends trimmed.
# anchor-slug: whitespace runs collapsed, then steps 2-5, runs collapsed, ends
#            trimmed, then truncated by the four-step rule - a hard cut at
#            exactly 40 characters when no `-` lies in range, because totality is
#            a requirement and legibility only a preference.
rel_fact_token_into() {
    local path="$1" anchor="$2" p a
    rel__lower_into "$path"; p="$REL_STR"
    p="${p//\//-}"
    p="${p//./-}"
    p="${p//[!a-z0-9_ -]/}"
    p="${p// /-}"
    rel__collapse_hyphens_into "$p"; p="$REL_STR"

    rel__collapse_space_into "$anchor"; a="$REL_STR"
    rel_strip_markup_into "$a"; a="$REL_STR"
    rel__lower_into "$a"; a="$REL_STR"
    a="${a//[!a-z0-9_ -]/}"
    a="${a// /-}"
    rel__collapse_hyphens_into "$a"; a="$REL_STR"
    rel__truncate_anchor_into "$a"; a="$REL_STR"

    REL_STR="$p--$a"
}
rel_fact_token() { rel_fact_token_into "$1" "$2"; printf '%s' "$REL_STR"; }

rel__truncate_anchor_into() {
    local s="$1" head p
    if [ "${#s}" -le 40 ]; then REL_STR="$s"; return 0; fi
    head="${s:0:40}"
    if [ "${head#*-}" != "$head" ]; then
        # the LAST `-` at index <= 40 is the word-boundary cut: it is the longest
        # prefix that ends on a boundary, and index 1 cannot be a `-` because
        # leading `-` is trimmed before truncation.
        p="${head%-*}"
        if [ -n "$p" ]; then REL_STR="${p%-}"; return 0; fi
    fi
    s="${head}"
    while [ "${s%-}" != "$s" ]; do s="${s%-}"; done
    REL_STR="$s"
}

# ===========================================================================
# D2 - id grammar
# ===========================================================================

# rel_parse_id <id>
#   -> REL_ID_PREFIX REL_ID_BODY REL_ID_DOC REL_ID_FRAGMENT REL_ID_TERM
#      REL_ID_QUAL_DOC REL_ID_KIND
#   REL_ID_KIND is the kind the GRAMMAR implies, and is set only for a `kb:` id -
#   the split is total there without consulting the Kind column, which is what
#   keeps the two-tier kind check from being circular. For `int:` the kind needs
#   the extension set and for `ext:` it is unrecoverable from the key, so both
#   leave it empty.
#   Returns 1 with REL_ID_REASON on a grammar violation.
rel_parse_id() {
    local id="$1" prefix body
    REL_ID_PREFIX=""; REL_ID_BODY=""; REL_ID_DOC=""; REL_ID_FRAGMENT=""
    REL_ID_TERM=""; REL_ID_QUAL_DOC=""; REL_ID_KIND=""; REL_ID_REASON=""

    case "$id" in
        *:*) ;;
        *) REL_ID_REASON="no-prefix"; return 1 ;;
    esac
    prefix="${id%%:*}"; body="${id#*:}"
    if ! rel__has_word "$REL_PREFIXES" "$prefix"; then
        REL_ID_REASON="unknown-prefix"; return 1
    fi
    [ -n "$body" ] || { REL_ID_REASON="empty-body"; return 1; }
    REL_ID_PREFIX="$prefix"; REL_ID_BODY="$body"

    case "$prefix" in
        kb)
            case "$body" in
                concept:*)
                    local term="${body#concept:}"
                    [ -n "$term" ] || { REL_ID_REASON="empty-concept-term"; return 1; }
                    case "$term" in
                        *@*)
                            REL_ID_TERM="${term%%@*}"
                            REL_ID_QUAL_DOC="${term#*@}"
                            case "$REL_ID_QUAL_DOC" in *@*) REL_ID_REASON="concept-multiple-at"; return 1 ;; esac
                            rel__doc_basename_ok "$REL_ID_QUAL_DOC" || { REL_ID_REASON="bad-qualifier-doc"; return 1; } ;;
                        *) REL_ID_TERM="$term" ;;
                    esac
                    [ -n "$REL_ID_TERM" ] || { REL_ID_REASON="empty-concept-term"; return 1; }
                    case "$REL_ID_TERM" in
                        [a-z0-9]*) ;;
                        *) REL_ID_REASON="bad-concept-term"; return 1 ;;
                    esac
                    case "$REL_ID_TERM" in
                        *[!a-z0-9-]*) REL_ID_REASON="bad-concept-term"; return 1 ;;
                    esac
                    REL_ID_KIND="concept" ;;
                *)
                    local doc frag
                    case "$body" in
                        *"#"*) doc="${body%%#*}"; frag="${body#*#}" ;;
                        *) doc="$body"; frag="" ;;
                    esac
                    rel__doc_basename_ok "$doc" || { REL_ID_REASON="bad-doc"; return 1; }
                    REL_ID_DOC="$doc"; REL_ID_FRAGMENT="$frag"
                    case "$frag" in *"#"*) REL_ID_REASON="multiple-fragments"; return 1 ;; esac
                    if [ -z "$frag" ]; then
                        case "$body" in
                            *"#") REL_ID_REASON="empty-fragment"; return 1 ;;
                        esac
                        REL_ID_KIND="document"
                    elif [ "${frag#fact:}" != "$frag" ]; then
                        local tokv="${frag#fact:}"
                        [ -n "$tokv" ] || { REL_ID_REASON="empty-fact-token"; return 1; }
                        case "$tokv" in *[!a-z0-9_-]*) REL_ID_REASON="bad-fact-token"; return 1 ;; esac
                        REL_ID_KIND="fact"
                    else
                        case "$frag" in *[!a-z0-9_-]*) REL_ID_REASON="bad-section-slug"; return 1 ;; esac
                        REL_ID_KIND="section"
                    fi ;;
            esac ;;
        int)
            # Repo-relative, `/`-separated, exact on-disk case. `..`, `\` and a
            # drive letter are rejected BEFORE any I/O. No `#` fragment of any
            # kind: the symbol-narrowing clause is struck, so the grammar admits
            # none and the reason token routes the finding to the granularity
            # check rather than to resolution.
            case "$body" in *"#"*) REL_ID_REASON="int-fragment"; return 1 ;; esac
            case "$body" in
                /*) REL_ID_REASON="absolute-path"; return 1 ;;
                ./*) REL_ID_REASON="dot-slash-path"; return 1 ;;
                *\\*) REL_ID_REASON="backslash-path"; return 1 ;;
                [A-Za-z]:*) REL_ID_REASON="drive-letter-path"; return 1 ;;
                ..|../*|*/..|*/../*) REL_ID_REASON="parent-segment-path"; return 1 ;;
                *//*) REL_ID_REASON="empty-path-segment"; return 1 ;;
            esac
            case "$body" in *[[:space:]]*) REL_ID_REASON="whitespace-in-path"; return 1 ;; esac ;;
        ext)
            case "$body" in
                [A-Za-z0-9]*) ;;
                *) REL_ID_REASON="bad-external-key"; return 1 ;;
            esac
            case "$body" in *[!A-Za-z0-9._-]*) REL_ID_REASON="bad-external-key"; return 1 ;; esac ;;
    esac
    return 0
}

# `<doc>` is `[A-Za-z0-9._-]+\.md`, exact on-disk case, no path separator - a
# basename, because the scan set is flat by its own `-maxdepth 1` predicate.
rel__doc_basename_ok() {
    local d="$1"
    [ -n "$d" ] || return 1
    case "$d" in *.md) ;; *) return 1 ;; esac
    [ "$d" != ".md" ] || return 1
    case "$d" in *[!A-Za-z0-9._-]*) return 1 ;; esac
    return 0
}

# rel_kind_prefix_ok <kind> <id>  - D1a's two tiers.
#   tier 1  <kind> is in the enum and the id's prefix is in that kind's permitted
#           prefix SET, so `image` + `ext:` passes.
#   tier 2  for a `kb:` id, <kind> equals the kind its own fragment grammar
#           implies; for an `int:` id, `image` iff the lower-cased extension is in
#           image_extensions and `source-artifact` otherwise, with a trailing-`/`
#           directory id always `source-artifact`.
#   For an `ext:` id there is no tier 2: `image` versus `web-page` is not
#   recoverable from an opaque key, and a check that claimed to verify it would
#   have to guess.
rel_kind_prefix_ok() {
    local kind="$1" id="$2" prefix allowed
    REL_KIND_REASON=""
    if ! rel__has_word "$REL_KINDS" "$kind"; then
        REL_KIND_REASON="kind '$kind' is not in the Kind enum ($REL_KINDS)"; return 1
    fi
    case "$id" in
        *:*) prefix="${id%%:*}" ;;
        *) REL_KIND_REASON="id '$id' carries no prefix"; return 1 ;;
    esac
    rel__lookup "$REL_KIND_PREFIX_TABLE" "$kind" || {
        REL_KIND_REASON="internal: no prefix set for kind '$kind'"; return 1; }
    allowed="${REL_LOOKUP//,/ }"
    if ! rel__has_word "$allowed" "$prefix"; then
        REL_KIND_REASON="kind '$kind' permits prefix(es) '$allowed', not '$prefix'"; return 1
    fi

    if [ "$prefix" = kb ]; then
        if ! rel_parse_id "$id"; then
            REL_KIND_REASON="id '$id' is not a well-formed kb: id ($REL_ID_REASON)"; return 1
        fi
        if [ "$REL_ID_KIND" != "$kind" ]; then
            REL_KIND_REASON="the id's own grammar implies kind '$REL_ID_KIND', not '$kind'"; return 1
        fi
        return 0
    fi

    if [ "$prefix" = int ]; then
        if ! rel_parse_id "$id"; then
            REL_KIND_REASON="id '$id' is not a well-formed int: id ($REL_ID_REASON)"; return 1
        fi
        local body="$REL_ID_BODY" want ext base
        case "$body" in
            */) want="source-artifact" ;;
            *)
                base="${body##*/}"
                case "$base" in
                    *.*) ext="${base##*.}"
                         rel__lower_into "$ext"; ext="$REL_STR"
                         if [ -n "${base%.*}" ] && rel__has_word "$REL_IMAGE_EXTENSIONS" "$ext"; then
                             want="image"
                         else
                             want="source-artifact"
                         fi ;;
                    *) want="source-artifact" ;;
                esac ;;
        esac
        if [ "$want" != "$kind" ]; then
            REL_KIND_REASON="an int: path of this shape is '$want', not '$kind'"; return 1
        fi
        return 0
    fi

    # ext: - tier 1 only, by construction. Recorded rather than pretended.
    if ! rel_parse_id "$id"; then
        REL_KIND_REASON="id '$id' is not a well-formed ext: id ($REL_ID_REASON)"; return 1
    fi
    return 0
}

# ===========================================================================
# The KB scan - ONE awk pass over the scan set, feeding every derived set, so the
# heading counter, the block boundaries, the anchor blocks and the marker scan
# cannot disagree about where a fence begins.
# ===========================================================================

rel_set_kb_root() { REL_KB_ROOT="$1"; REL_KB_SCANNED=0; }
rel_set_repo_root() { REL_REPO_ROOT="$1"; }
rel_set_external_sources() { REL_EXTERNAL_SOURCES="$1"; REL_EXTERNAL_SCANNED=0; }

# Resolve the repo root ONCE. `int:` resolution asks for it per endpoint, and a
# `git rev-parse` fork per endpoint would dominate a large table's runtime.
rel__ensure_repo_root() {
    [ -n "$REL_REPO_ROOT" ] && return 0
    REL_REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || printf '.')"
}

rel__repo_root() { rel__ensure_repo_root; printf '%s' "$REL_REPO_ROOT"; }

# The tokeniser. Emits, in document order, with ONE fenced-code state shared by
# every consumer below:
#   H TAB doc TAB lineno TAB level TAB raw-heading-text
#   M TAB doc TAB lineno                                a definition marker line
#   P TAB doc TAB lineno TAB collapsed-block-text       a non-blank block
#   Z TAB doc TAB lastline                              end of document
# It decides nothing: every slug, token and term is computed from this raw text by
# the shell rules above.
rel__kb_awk() {
    awk -v fence_re="$REL_FENCE_RE" '
        function flushblock() {
            if (buf != "") { printf "P\t%s\t%d\t%d\t%s\n", bufdoc, bstart, bend, buf; buf = "" }
        }
        function base(p) { sub(/^.*\//, "", p); return p }
        FILENAME != curfile {
            if (curfile != "") { flushblock(); printf "Z\t%s\t%d\n", curdoc, lastline }
            curfile = FILENAME; curdoc = base(FILENAME); infence = 0; buf = ""; lastline = 0
        }
        { line = $0; sub(/\r$/, "", line); lastline = FNR }
        line ~ fence_re { flushblock(); infence = 1 - infence; next }
        infence { next }
        line ~ /^[[:space:]]*$/ { flushblock(); next }
        {
            if (match(line, /^#+[[:space:]]/)) {
                nh = RLENGTH - 1
                if (nh >= 1 && nh <= 6) {
                    flushblock()
                    t = substr(line, nh + 1)
                    sub(/^[[:space:]]+/, "", t); sub(/[[:space:]]+$/, "", t)
                    printf "H\t%s\t%d\t%d\t%s\n", curdoc, FNR, nh, t
                    next
                }
            }
            if (line ~ /^\*\*Definition(-as-used-here)?:\*\*/) printf "M\t%s\t%d\n", curdoc, FNR
            b = line
            gsub(/\t/, " ", b)
            if (buf == "") { bufdoc = curdoc; bstart = FNR; buf = b }
            else { buf = buf " " b }
            bend = FNR
        }
        END { flushblock(); if (curfile != "") printf "Z\t%s\t%d\n", curdoc, lastline }
    ' "$@"
}

# Extract every citation occurrence from one collapsed block. A citation is a
# backticked path token followed by a grep-recoverable anchor in one of the two
# forms `authoring-conventions.md`'s Citation Rule verdict table admits:
#
#   symbol form        `<path>` -> `<symbol>`
#   quoted-string form `<path>` "<string>"        (`(search: "..."` is an instance)
#
# The lead-in set is ENUMERATED - `->`, `(search:`, or nothing - rather than
# given as a permissive charset, so prose between a path and a later quotation can
# never be read as a citation. A backticked anchor requires the `->` lead-in:
# without it, two adjacent backticked paths would read as path plus anchor.
# A citation naming a path with NO anchor string is NOT checkable - there is
# nothing to grep for - so it yields no fact node. It is still RECORDED, as an
# `unanchored` occurrence, because the count of markers skipped for want of an
# anchor is what the coverage notes' `fact-unanchored` row reports; dropping it
# silently would leave that row with no producer.
#
# `_into` fills REL_CITES with  status TAB path TAB anchor  per occurrence
# (`anchored` or `unanchored`); the printing shape wraps it. The twin is not
# decoration: the KB carries hundreds of blocks and a command substitution costs
# ~100 ms under Windows Git Bash / MSYS, so a per-block fork is a minutes-long scan.
rel__block_citations_into() {
    local block="$1" rest tok after r anchor
    REL_CITES=()
    rest="$block"
    while :; do
        case "$rest" in *'`'*) ;; *) break ;; esac
        after="${rest#*\`}"
        case "$after" in *'`'*) ;; *) break ;; esac
        tok="${after%%\`*}"
        rest="${after#*\`}"
        rel__is_citation_path "$tok" || continue
        r="$rest"
        rel__trim_into "$r"; r="$REL_STR"
        anchor=""
        case "$r" in
            '->'*)
                r="${r#->}"
                rel__trim_into "$r"; r="$REL_STR"
                case "$r" in
                    '`'*) anchor="${r#\`}"
                          case "$anchor" in *'`'*) rest="${anchor#*\`}"; anchor="${anchor%%\`*}" ;; *) anchor="" ;; esac ;;
                esac ;;
            '(search:'*)
                r="${r#(search:}"
                rel__trim_into "$r"; r="$REL_STR"
                case "$r" in
                    '"'*) anchor="${r#\"}"
                          case "$anchor" in *'"'*) rest="${anchor#*\"}"; anchor="${anchor%%\"*}" ;; *) anchor="" ;; esac ;;
                esac ;;
            '"'*)
                anchor="${r#\"}"
                case "$anchor" in *'"'*) rest="${anchor#*\"}"; anchor="${anchor%%\"*}" ;; *) anchor="" ;; esac ;;
        esac
        if [ -n "$anchor" ]; then
            REL_CITES+=("anchored$REL_TAB$tok$REL_TAB$anchor")
        else
            REL_CITES+=("unanchored$REL_TAB$REL_TAB")
        fi
    done
}

rel__block_citations() {
    rel__block_citations_into "$1"
    local c
    for c in ${REL_CITES+"${REL_CITES[@]}"}; do printf '%s\n' "$c"; done
}

rel__is_citation_path() {
    local t="$1" ext base
    case "$t" in *[[:space:]]*|"") return 1 ;; esac
    case "$t" in *.*) ;; *) return 1 ;; esac
    base="${t##*/}"
    case "$base" in *.*) ;; *) return 1 ;; esac
    [ -n "${base%.*}" ] || return 1
    ext="${t##*.}"
    # the same charset and extension set the regex is built from - unquoted so the
    # expansion becomes part of the pattern.
    case "$t" in *[!${REL_PATH_CHARSET}]*) return 1 ;; esac
    rel__has_word "$REL_CITE_EXTENSIONS" "$ext" || return 1
    return 0
}

# rel_scan_kb - build every derived set. Idempotent; lazily triggered by the
# resolvers and by every per-document accessor.
rel_scan_kb() {
    REL_KB_DOCS=""; REL_SECTION_IDS=""; REL_T_SECTION_TEXT=""
    REL_FACT_IDS=""; REL_T_FACT_ANCHOR=""; REL_DEFS=""; REL_BLOCKS=""
    REL_FACT_RECORDS=""
    REL_KB_SCANNED=1

    if [ ! -d "$REL_KB_ROOT" ]; then
        rel__err "notice: KB root $(rel_abs_path "$REL_KB_ROOT") is not a directory; the scan set is empty"
        return 0
    fi

    local docs=() d
    while IFS= read -r d; do
        [ -n "$d" ] || continue
        docs+=("$d")
        REL_KB_DOCS="${REL_KB_DOCS:+$REL_KB_DOCS$REL_NL}${d##*/}"
    done < <(find "$REL_KB_ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*' 2>/dev/null | LC_ALL=C sort)
    [ "${#docs[@]}" -gt 0 ] || return 0

    # Pass 1 over the tokeniser stream: headings (slug counter over levels 1-6,
    # emission over 2-6), anchor blocks (fact tokens with their ordinal), markers,
    # and the block-body walk that turns a marker into a concept definition.
    local rec type doc lineno level text
    local slug_counts="" tok_counts=""
    local pend_doc="" pend_line="" pend_level="" pend_text="" pend_marked=0
    while IFS= read -r rec; do
        [ -n "$rec" ] || continue
        type="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
        doc="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
        case "$type" in
            H)
                lineno="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
                level="${rec%%"$REL_TAB"*}"; text="${rec#*"$REL_TAB"}"
                rel__close_block "$((lineno - 1))"
                pend_doc="$doc"; pend_line="$lineno"; pend_level="$level"
                pend_text="$text"; pend_marked=0

                # the slug counter runs over ALL heading levels 1-6, even though
                # only 2-6 are emitted: a counter that skipped level 1 would
                # number an H2 colliding with the H1 differently.
                rel_slug_heading_into "$text"
                local slug="$REL_STR" n=0
                if [ -n "$slug" ]; then
                    if rel__lookup "$slug_counts" "$doc#$slug"; then n="$REL_LOOKUP"; fi
                    n=$((n + 1))
                    slug_counts="$slug_counts$REL_NL$doc#$slug$REL_TAB$n"
                    [ "$n" -gt 1 ] && slug="$slug-$((n - 1))"
                    if [ "$level" -ge 2 ]; then
                        REL_SECTION_IDS="${REL_SECTION_IDS:+$REL_SECTION_IDS$REL_NL}$doc#$slug"
                        rel_strip_markup_into "$text"
                        REL_T_SECTION_TEXT="$REL_T_SECTION_TEXT$REL_NL$doc#$slug$REL_TAB$REL_STR"
                    fi
                fi ;;
            M)
                pend_marked=1 ;;
            P)
                lineno="${rec%%"$REL_TAB"*}"; rec="${rec#*"$REL_TAB"}"
                local blockend="${rec%%"$REL_TAB"*}"; text="${rec#*"$REL_TAB"}"
                local cite status path anchor base_tok tn
                rel__block_citations_into "$text"
                for cite in ${REL_CITES+"${REL_CITES[@]}"}; do
                    [ -n "$cite" ] || continue
                    status="${cite%%"$REL_TAB"*}"; cite="${cite#*"$REL_TAB"}"
                    path="${cite%%"$REL_TAB"*}"; anchor="${cite#*"$REL_TAB"}"
                    if [ "$status" != anchored ]; then
                        # recorded for the coverage notes, but no fact node: an
                        # anchor-less citation resolves to nothing, which is exactly
                        # what the resolution check exists to prevent.
                        REL_FACT_RECORDS="${REL_FACT_RECORDS:+$REL_FACT_RECORDS$REL_NL}$doc$REL_TAB""unanchored$REL_TAB$REL_TAB$REL_TAB$lineno$REL_TAB$blockend"
                        continue
                    fi
                    rel_fact_token_into "$path" "$anchor"
                    base_tok="$REL_STR"; tn=0
                    if rel__lookup "$tok_counts" "$doc#$base_tok"; then tn="$REL_LOOKUP"; fi
                    tn=$((tn + 1))
                    tok_counts="$tok_counts$REL_NL$doc#$base_tok$REL_TAB$tn"
                    [ "$tn" -gt 1 ] && base_tok="$base_tok-$((tn - 1))"
                    REL_FACT_IDS="${REL_FACT_IDS:+$REL_FACT_IDS$REL_NL}$doc#fact:$base_tok"
                    rel__collapse_space_into "$anchor"
                    REL_T_FACT_ANCHOR="$REL_T_FACT_ANCHOR$REL_NL$doc#fact:$base_tok$REL_TAB$REL_STR"
                    REL_FACT_RECORDS="${REL_FACT_RECORDS:+$REL_FACT_RECORDS$REL_NL}$doc$REL_TAB""anchored$REL_TAB$base_tok$REL_TAB$path$REL_TAB$REL_STR$REL_TAB$lineno$REL_TAB$blockend"
                done ;;
            Z)
                rel__close_block "$rec" ;;
        esac
    done < <(rel__kb_awk "${docs[@]}")
    return 0
}

# Close the pending heading's block body at <to>, recording it and - when the
# body carried a marker and the heading is at level 3 or deeper - the concept
# definition it declares. A heading's body runs to the line before the NEXT ATX
# heading of ANY level 1-6, so each marker is owned by exactly one heading and
# one definition can never mint a node per ancestor.
rel__close_block() {
    local to="$1"
    [ -n "$pend_doc" ] || return 0
    local from=$((pend_line + 1))
    [ "$to" -ge "$from" ] || to="$((from - 1))"
    REL_BLOCKS="${REL_BLOCKS:+$REL_BLOCKS$REL_NL}$pend_doc$REL_TAB$pend_level$REL_TAB$pend_marked$REL_TAB$from$REL_TAB$to$REL_TAB$pend_text"
    if [ "$pend_marked" -eq 1 ] && [ "$pend_level" -ge 3 ]; then
        rel_normalise_term_into "$pend_text"
        local term="$REL_STR"
        if [ -n "$term" ]; then
            rel_strip_markup_into "$pend_text"
            REL_DEFS="${REL_DEFS:+$REL_DEFS$REL_NL}$term$REL_TAB$pend_doc$REL_TAB$pend_level$REL_TAB$REL_STR"
        fi
    fi
    pend_doc=""; pend_line=""; pend_level=""; pend_text=""; pend_marked=0
}

rel__ensure_kb() { [ "$REL_KB_SCANNED" -eq 1 ] || rel_scan_kb; }

rel_kb_docs() { rel__ensure_kb; printf '%s\n' "$REL_KB_DOCS"; }

rel_doc_slugs() {
    rel__ensure_kb
    local want="$1" line
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        [ "${line%%#*}" = "$want" ] || continue
        printf '%s\n' "${line#*#}"
    done <<EOF
$REL_SECTION_IDS
EOF
}

rel_fact_tokens() {
    rel__ensure_kb
    local want="$1" line
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        [ "${line%%#*}" = "$want" ] || continue
        printf '%s\n' "${line#*#fact:}"
    done <<EOF
$REL_FACT_IDS
EOF
}

# level TAB marker TAB from TAB to TAB heading-text, in document order. The body
# is given as a LINE RANGE rather than as text: the range is exactly what D2a-3a
# fixes, and it is checkable against the document without re-collapsing anything.
# An EMPTY body - a heading immediately followed by the next heading, or by end of
# file - is reported as `to == from - 1`, so the range is empty rather than the
# accessor having to carry a separate "no body" signal.
rel_block_bodies() {
    rel__ensure_kb
    local want="$1" line
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        [ "${line%%"$REL_TAB"*}" = "$want" ] || continue
        printf '%s\n' "${line#*"$REL_TAB"}"
    done <<EOF
$REL_BLOCKS
EOF
}

# One record per citation occurrence in <doc>, document order:
#   <status> TAB <token> TAB <path> TAB <anchor> TAB <from> TAB <to>
# <status> is `anchored` for a well-formed checkable source anchor and `unanchored`
# for a citation carrying no grep-recoverable anchor string, whose count the
# coverage notes' `fact-unanchored` row reports; <token>, <path> and <anchor> are
# empty on an `unanchored` record. <from>..<to> is the anchor BLOCK's 1-based
# inclusive line range - the marker line plus its continuation lines.
#
# Exposed beyond D9's table deliberately: without it, the only way to obtain the
# unanchored count and the anchored token/anchor pairing is to re-implement this
# library's citation predicate and its fact tokeniser in the caller, which is the
# second copy of a rule the one-copy discipline exists to prevent.
rel_fact_records() {
    rel__ensure_kb
    local want="$1" line
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        [ "${line%%"$REL_TAB"*}" = "$want" ] || continue
        printf '%s\n' "${line#*"$REL_TAB"}"
    done <<EOF
$REL_FACT_RECORDS
EOF
}

# One line per physical line of <doc>: `0` outside a fenced code block, `1` inside
# one, the fence delimiters themselves counting as inside.
#
# Exposed beyond D9's table for the same reason as rel_fact_records, and for one
# more: it shares REL_FENCE_RE with the whole-KB tokeniser, so a caller that needs
# its own line classification reads THIS library's fence state instead of writing a
# second fence scan that could disagree about where a fence begins.
rel_fence_mask() {
    # <doc> is a basename in the KB scan set, as it is for every other per-document
    # accessor here.
    local path="$REL_KB_ROOT/$1"
    if [ ! -f "$path" ]; then
        rel__err "rel_fence_mask: no such KB document: $(rel_abs_path "$path")"
        return 1
    fi
    awk -v fence_re="$REL_FENCE_RE" '
        { line = $0; sub(/\r$/, "", line) }
        line ~ fence_re { print 1; infence = 1 - infence; next }
        { print (infence ? 1 : 0) }
    ' "$path"
}

rel_concept_defs() {
    rel__ensure_kb
    local want="$1" line
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        [ "${line%%"$REL_TAB"*}" = "$want" ] || continue
        line="${line#*"$REL_TAB"}"
        printf '%s\n' "${line%%"$REL_TAB"*}"
    done <<EOF
$REL_DEFS
EOF
}

# rel__count_defs <term> [<doc>] -> REL_DEF_COUNT. The fork-free twin of
# `rel_concept_defs | wc -l`: resolution asks this per concept row.
rel__count_defs() {
    rel__ensure_kb
    local want="$1" qual="${2:-}" line term d rest
    REL_DEF_COUNT=0
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        term="${line%%"$REL_TAB"*}"
        [ "$term" = "$want" ] || continue
        rest="${line#*"$REL_TAB"}"
        d="${rest%%"$REL_TAB"*}"
        if [ -n "$qual" ] && [ "$d" != "$qual" ]; then continue; fi
        REL_DEF_COUNT=$((REL_DEF_COUNT + 1))
    done <<EOF
$REL_DEFS
EOF
}

rel_concept_terms() {
    rel__ensure_kb
    local line out=""
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        out="${out:+$out$REL_NL}${line%%"$REL_TAB"*}"
    done <<EOF
$REL_DEFS
EOF
    rel__sort_lines "$out"
    printf '%s\n' "$REL_STR"
}

# The external-sources registry: inside `## Sources`, a table row whose first
# cell is a key rendered as inline code registers that key. Against a prose-only
# file the predicate registers zero keys, which is the literal truth.
rel__ensure_external() {
    if [ "$REL_EXTERNAL_SCANNED" -eq 0 ]; then
        REL_EXTERNAL_SCANNED=1
        REL_EXTERNAL_KEYS=""
        local f="$REL_EXTERNAL_SOURCES"
        [ -n "$f" ] || f="$REL_KB_ROOT/external-sources.md"
        if [ -f "$f" ]; then
            REL_EXTERNAL_KEYS="$(awk '
                { line = $0; sub(/\r$/, "", line) }
                line ~ /^##[[:space:]]+Sources[[:space:]]*$/ { ins = 1; next }
                line ~ /^##[[:space:]]/ { ins = 0; next }
                ins && match(line, /^\|[[:space:]]*`[^`]+`[[:space:]]*\|/) {
                    s = substr(line, RSTART, RLENGTH)
                    sub(/^\|[[:space:]]*`/, "", s)
                    sub(/`[[:space:]]*\|$/, "", s)
                    if (s != "") print s
                }
            ' "$f" | LC_ALL=C sort -u)"
        fi
    fi
}

rel_external_keys() { rel__ensure_external; printf '%s\n' "$REL_EXTERNAL_KEYS"; }

# ===========================================================================
# Resolution and display names
# ===========================================================================

# rel_resolve_id <kind> <id>  - `ok` or a reason token. Resolution is by the
# protocol for <kind>, never by prefix.
#
# `_into` is the PRIMARY shape and sets REL_RESOLVE; the printing function wraps
# it. A validator calls this once per endpoint per row, so the printing shape's
# command substitution would be one ~100 ms fork per endpoint under MSYS.
rel_resolve_id_into() {
    local kind="$1" id="$2"
    REL_RESOLVE=""
    if ! rel_parse_id "$id"; then REL_RESOLVE="$REL_ID_REASON"; return 1; fi
    rel__ensure_kb
    rel__ensure_repo_root
    local root="$REL_REPO_ROOT"
    case "$kind" in
        document)
            rel__has_line "$REL_KB_DOCS" "$REL_ID_DOC" || { REL_RESOLVE=no-such-document; return 1; } ;;
        section)
            rel__has_line "$REL_SECTION_IDS" "$REL_ID_DOC#$REL_ID_FRAGMENT" || { REL_RESOLVE=no-such-section; return 1; } ;;
        fact)
            rel__has_line "$REL_FACT_IDS" "$REL_ID_DOC#$REL_ID_FRAGMENT" || { REL_RESOLVE=no-such-fact-anchor; return 1; } ;;
        concept)
            # exactly one definition block: zero is unresolvable, and two or more
            # is ALSO unresolvable for the plain form, which is what forces the
            # `@<doc>` qualified form mechanically rather than by instruction.
            rel__count_defs "$REL_ID_TERM" "$REL_ID_QUAL_DOC"
            if [ "$REL_DEF_COUNT" -eq 0 ]; then REL_RESOLVE=no-such-concept-definition; return 1; fi
            if [ "$REL_DEF_COUNT" -gt 1 ]; then REL_RESOLVE=ambiguous-concept-definition; return 1; fi ;;
        source-artifact)
            case "$REL_ID_BODY" in
                */) [ -d "$root/${REL_ID_BODY%/}" ] || { REL_RESOLVE=no-such-directory; return 1; } ;;
                *)  [ -f "$root/$REL_ID_BODY" ] || { REL_RESOLVE=no-such-file; return 1; } ;;
            esac ;;
        image)
            if [ "$REL_ID_PREFIX" = int ]; then
                [ -f "$root/$REL_ID_BODY" ] || { REL_RESOLVE=no-such-file; return 1; }
            else
                rel__ensure_external
                rel__has_line "$REL_EXTERNAL_KEYS" "$REL_ID_BODY" || { REL_RESOLVE=unregistered-external-key; return 1; }
            fi ;;
        web-page)
            rel__ensure_external
            rel__has_line "$REL_EXTERNAL_KEYS" "$REL_ID_BODY" || { REL_RESOLVE=unregistered-external-key; return 1; } ;;
        *)
            REL_RESOLVE=unknown-kind; return 1 ;;
    esac
    REL_RESOLVE=ok
    return 0
}

rel_resolve_id() {
    local rc=0
    rel_resolve_id_into "$1" "$2" || rc=1
    printf '%s' "$REL_RESOLVE"
    return "$rc"
}

# rel_display_name <kind> <id>  - the derived name. Never authored per row, and
# never truncated: shortening for legibility is a render-time concern.
# `_into` sets REL_NAME and is the primary shape, for the same reason.
rel_display_name_into() {
    local kind="$1" id="$2"
    REL_NAME=""
    rel_parse_id "$id" || return 1
    rel__ensure_kb
    case "$kind" in
        document) REL_NAME="$REL_ID_DOC" ;;
        section)
            rel__lookup "$REL_T_SECTION_TEXT" "$REL_ID_DOC#$REL_ID_FRAGMENT" || return 1
            REL_NAME="$REL_ID_DOC § $REL_LOOKUP" ;;
        fact)
            rel__lookup "$REL_T_FACT_ANCHOR" "$REL_ID_DOC#$REL_ID_FRAGMENT" || return 1
            REL_NAME="$REL_ID_DOC § $REL_LOOKUP" ;;
        concept)
            local line term written="" restl d
            while IFS= read -r line; do
                [ -n "$line" ] || continue
                term="${line%%"$REL_TAB"*}"
                [ "$term" = "$REL_ID_TERM" ] || continue
                restl="${line#*"$REL_TAB"}"
                d="${restl%%"$REL_TAB"*}"
                if [ -n "$REL_ID_QUAL_DOC" ] && [ "$d" != "$REL_ID_QUAL_DOC" ]; then continue; fi
                written="${restl##*"$REL_TAB"}"
                break
            done <<EOF
$REL_DEFS
EOF
            [ -n "$written" ] || return 1
            if [ -n "$REL_ID_QUAL_DOC" ]; then
                REL_NAME="$written ($REL_ID_QUAL_DOC)"
            else
                REL_NAME="$written"
            fi ;;
        source-artifact|image|web-page)
            # `<path>` / `<path>/` verbatim for an in-repo id, `<key>` for an
            # external one - the body is the name in both cases.
            REL_NAME="$REL_ID_BODY" ;;
        *) return 1 ;;
    esac
    return 0
}

rel_display_name() { rel_display_name_into "$1" "$2" || return 1; printf '%s' "$REL_NAME"; }

# ===========================================================================
# D7 - normalisation, keys and ordering
# ===========================================================================

# rel_normalise_row <10 fields>  - the canonical orientation. If
# Source Id > Target Id under LC_ALL=C byte ordering, the two (Id, Kind, Name)
# TRIPLES swap and S2T swaps with T2S. The TRIPLE is what swaps, not the pair: a
# rule that moved ids and names while leaving the Kind cells in place would
# produce a row whose kinds no longer match their ids. Self-edges are left as
# written. Prints the ten fields, one per line - a cell carries no newline, so
# this shape needs no separator and cannot collide with cell content.
rel_normalise_row() {
    local LC_ALL=C
    if [ "$#" -ne 10 ]; then rel__err "rel_normalise_row: ten fields required, got $#"; return 2; fi
    local sid="$1" skind="$2" sname="$3" tid="$4" tkind="$5" tname="$6" s2t="$7" t2s="$8" prov="$9" obs="${10}"
    if [[ "$sid" > "$tid" ]]; then
        REL_NORM_ROW="$tid$REL_NL$tkind$REL_NL$tname$REL_NL$sid$REL_NL$skind$REL_NL$sname$REL_NL$t2s$REL_NL$s2t$REL_NL$prov$REL_NL$obs"
    else
        REL_NORM_ROW="$sid$REL_NL$skind$REL_NL$sname$REL_NL$tid$REL_NL$tkind$REL_NL$tname$REL_NL$s2t$REL_NL$t2s$REL_NL$prov$REL_NL$obs"
    fi
    printf '%s\n' "$REL_NORM_ROW"
}

# rel_row_key <10 fields>  - source_id US target_id US s2t US t2s, on the
# NORMALISED row. A verbatim repeat and a separately written inverse row collapse
# to the same key. Kind is deliberately not in the key: an id determines its kind,
# so adding it could only mask a duplicate.
rel_row_key_into() {
    rel_normalise_row "$@" >/dev/null || return 2
    local f1 f4 f7 f8 rest
    rest="$REL_NORM_ROW"
    f1="${rest%%"$REL_NL"*}"; rest="${rest#*"$REL_NL"}"
    rest="${rest#*"$REL_NL"}"; rest="${rest#*"$REL_NL"}"
    f4="${rest%%"$REL_NL"*}"; rest="${rest#*"$REL_NL"}"
    rest="${rest#*"$REL_NL"}"; rest="${rest#*"$REL_NL"}"
    f7="${rest%%"$REL_NL"*}"; rest="${rest#*"$REL_NL"}"
    f8="${rest%%"$REL_NL"*}"
    REL_ROW_KEY="$f1$REL_US$f4$REL_US$f7$REL_US$f8"
}

# The printing shape is a WRAPPER, never a second extraction: two copies of the
# field walk would be two chances to pick the wrong cell.
rel_row_key() { rel_row_key_into "$@" || return 2; printf '%s' "$REL_ROW_KEY"; }

# rel_sort_key <10 fields>  - (class, source_id, target_id, s2t, t2s), US
# separated, reading the STORED values. class is 0 for declared/derived and 1 for
# inferred, which is what makes the deterministic block a contiguous prefix.
rel_sort_key_into() {
    if [ "$#" -ne 10 ]; then rel__err "rel_sort_key: ten fields required, got $#"; return 2; fi
    local class=0
    case "$9" in inferred) class=1 ;; esac
    REL_SORT_KEY="$class$REL_US$1$REL_US$4$REL_US$7$REL_US$8"
}

rel_sort_key() { rel_sort_key_into "$@" || return 2; printf '%s' "$REL_SORT_KEY"; }

# ===========================================================================
# The artifact's own structure - the table, the class-0 block, the coverage notes
# ===========================================================================

# Split one table row into its cells, honouring the `\|` escape. Prints one cell
# VERBATIM per line, padding included, so the caller can check the padding rule.
# `_into` fills REL_ROW_CELLS with the cells VERBATIM, padding included, so the
# caller can check the padding rule. Returns 1 when the row does not end on a `|`.
# The twin exists because a table has thousands of rows and a command
# substitution costs ~100 ms under Windows Git Bash / MSYS.
rel__row_cells_into() {
    # `n` is assigned on its own line deliberately: `local` expands all of its
    # arguments BEFORE binding any of them, so `local line="$1" n=${#line}` reads
    # the CALLER's `line` and trips `set -u`.
    local line="$1" cell="" i=0 c
    local n=${#line}
    REL_ROW_CELLS=()
    case "$line" in \|*) ;; *) return 1 ;; esac
    i=1
    while [ "$i" -lt "$n" ]; do
        c="${line:i:1}"
        if [ "$c" = '\' ] && [ "${line:i+1:1}" = '|' ]; then
            cell="$cell\\|"; i=$((i + 2)); continue
        fi
        if [ "$c" = '|' ]; then
            REL_ROW_CELLS+=("$cell"); cell=""; i=$((i + 1)); continue
        fi
        cell="$cell$c"; i=$((i + 1))
    done
    if [ "$cell" != "" ]; then REL_ROW_CELLS+=("$cell"); return 1; fi
    return 0
}

rel__row_cells() {
    local rc=0 c
    rel__row_cells_into "$1" || rc=1
    for c in ${REL_ROW_CELLS+"${REL_ROW_CELLS[@]}"}; do printf '%s\n' "$c"; done
    return "$rc"
}

# rel_class0_block <file>  - the byte sequence AC-5 compares: the header row, the
# delimiter row, and the maximal prefix of data rows whose Provenance is not
# `inferred`, each LF terminated, frontmatter excluded. Callers must run the row
# ordering check first: the single-pass prefix scan equals "all class-0 rows"
# exactly when the class-0 block is a contiguous prefix.
rel_class0_block() {
    local file="$1"
    [ -f "$file" ] || { rel__err "rel_class0_block: no such file: $(rel_abs_path "$file")"; return 2; }
    awk '
        BEGIN { fm = 0; fmdone = 0; state = 0 }
        { line = $0; sub(/\r$/, "", line) }
        NR == 1 && line == "---" { fm = 1; next }
        fm == 1 && line == "---" { fm = 0; fmdone = 1; next }
        fm == 1 { next }
        state == 0 && line ~ /^\|/ { print line; state = 1; next }
        state == 1 && line ~ /^\|/ { print line; state = 2; next }
        state == 2 {
            if (line !~ /^\|/) { exit }
            # the `\|` escape is neutralised before the split, so a pipe inside a
            # display name cannot shift the Provenance cell.
            tmp = line
            gsub(/\\\|/, "\001", tmp)
            n = split(tmp, c, "|")
            prov = (n >= 10) ? c[10] : ""
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", prov)
            if (prov == "inferred") exit
            print line
            next
        }
        { next }
    ' "$file"
}

# rel_coverage_fixed_keys <table>  - `kinds` yields the Kind enum in carrier
# order (its fixed row set is the enum itself, read from the schema carrier);
# `exclusions` yields the three FR-22 rows in their fixed order.
rel_coverage_fixed_keys() {
    case "$1" in
        kinds) printf '%s\n' "${REL_KINDS// /$REL_NL}" ;;
        exclusions) printf '%s\n' "$REL_COVERAGE_EXCLUSION_KEYS" ;;
        *) rel__err "rel_coverage_fixed_keys: unknown table '$1' (want kinds|exclusions)"; return 2 ;;
    esac
}

# rel_coverage_extra_keys <file> <table>  - the first-cell keys of that table's
# EXTRA rows, in FILE order. The fixed block is identified by its own keys and
# excluded. Separated from any emitter deliberately: the ordering check must
# recompute the sort and compare, never trust the file.
rel_coverage_extra_keys() {
    local file="$1" table="$2" heading
    [ -f "$file" ] || { rel__err "rel_coverage_extra_keys: no such file: $(rel_abs_path "$file")"; return 2; }
    case "$table" in
        kinds) heading="Node kinds" ;;
        exclusions) heading="Enumeration exclusions" ;;
        *) rel__err "rel_coverage_extra_keys: unknown table '$table' (want kinds|exclusions)"; return 2 ;;
    esac
    local fixed; fixed="$(rel_coverage_fixed_keys "$table")" || return 2
    local line key cells
    local in_notes=0 in_table=0 row=0
    while IFS= read -r line; do
        line="${line%$'\r'}"
        case "$line" in
            "## Coverage notes"*) in_notes=1; continue ;;
            "## "*) in_notes=0; in_table=0; continue ;;
        esac
        [ "$in_notes" -eq 1 ] || continue
        case "$line" in
            "### $heading"*) in_table=1; row=0; continue ;;
            "### "*) in_table=0; continue ;;
        esac
        [ "$in_table" -eq 1 ] || continue
        case "$line" in \|*) ;; *) continue ;; esac
        row=$((row + 1))
        [ "$row" -le 2 ] && continue          # the table's own header and delimiter
        cells="$(rel__row_cells "$line")" || true
        key="${cells%%"$REL_NL"*}"
        rel__trim_into "$key"; key="$REL_STR"
        rel__has_line "$fixed" "$key" && continue
        printf '%s\n' "$key"
    done < "$file"
    return 0
}

# ---------------------------------------------------------------------------
# Direct execution: --help only. `set -eu` is applied HERE and not at the top of
# the file, because a sourced `set -e` would mutate the sourcing shell.
#
# The guard is TWO tests, and the second is load-bearing. The familiar
# `[ "${BASH_SOURCE[0]}" = "$0" ]` idiom alone is WRONG: under
# `bash -c '. "$0" ...' <this-file> <args>` - a perfectly ordinary way to source a
# library from a harness - `$0` IS this file, so the idiom reports "direct
# execution" for a genuine source, applies `set -eu` to the sourcing shell
# (undoing validate-relationships.sh's deliberate no-`-e` posture) and then exits
# 2 on the caller's first argument. `(return 0 2>/dev/null)` succeeds only inside
# a sourced file and is the reliable half; requiring both keeps the readable
# intent and removes the misfire.
# ---------------------------------------------------------------------------

if [ "${BASH_SOURCE[0]}" = "${0}" ] && ! (return 0 2>/dev/null); then
    set -eu
    case "${1:-}" in
        -h|--help)
            # The header, to its LAST comment line and no further: a fixed line
            # range is a `--help` that lies the moment the header changes length.
            awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$0"
            exit 0 ;;
        "")
            rel__err "this file is a library; source it, or run it with --help"
            exit 2 ;;
        *)
            rel__err "unknown argument: $1 (this file is a library; only --help is accepted)"
            exit 2 ;;
    esac
fi
