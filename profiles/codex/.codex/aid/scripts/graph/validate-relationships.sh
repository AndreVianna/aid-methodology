#!/usr/bin/env bash
# validate-relationships.sh -- grade `.aid/knowledge/relationships.md` against its
# own contract (feature-003, work-005-knowledge-graph).
#
# Purpose:
#   One read-only linter, fifteen checks. It decides mechanically -- never by a
#   reviewer's judgment -- whether a given relationship table conforms: the ten
#   column shape, the two closed enums, the per-kind id grammars and resolution
#   protocols, the merged relation vocabulary, the total row order, the emitted
#   frontmatter, and the coverage notes.
#
#   Every rule it applies lives in `relationship-schema.sh`, which it sources.
#   This file decides WHICH rule applies to WHICH cell and how a violation is
#   reported; it re-implements none of them, because a second copy of a rule is a
#   divergence waiting to happen.
#
#   Read-only: no file is written, ever. Findings go to stdout, diagnostics to
#   stderr.
#
# Usage:
#   validate-relationships.sh [options]
#
#   --file <path>                   the artifact under test
#                                   (default: .aid/knowledge/relationships.md)
#   --schema <path>                 the column/enum carrier
#                                   (default: <script>/../../templates/graph/relationship-schema.yml)
#   --vocabulary <path>             the core relation vocabulary
#                                   (default: <script>/../../templates/graph/relation-vocabulary.yml)
#   --vocabulary-extension <path>   the project vocabulary extension
#                                   (default: .aid/graph/relation-vocabulary.yml when it
#                                   exists; absent is not an error)
#   --kb-root <dir>                 the Knowledge Base scan root
#                                   (default: .aid/knowledge)
#   --external-sources <path>       the `ext:` key registry
#                                   (default: <kb-root>/external-sources.md)
#   --repo-root <dir>               the root `int:` paths resolve from
#                                   (default: `git rev-parse --show-toplevel`, else .)
#   --library <path>                relationship-schema.sh
#                                   (default: alongside this script)
#   --print-class0-block            print the D7b class-0 extraction to stdout and
#                                   exit, instead of printing findings. Runs the
#                                   carrier load and every check first and refuses
#                                   on any gating finding, because the extraction's
#                                   single-pass prefix scan is sound only on a
#                                   table whose class-0 block is a contiguous
#                                   prefix (V10). This is the byte sequence AC-5
#                                   compares. On refusal stdout carries NOTHING and
#                                   the findings go to stderr, so a caller
#                                   byte-comparing the stream is never handed a
#                                   findings list to compare; exit is 1.
#   -h, --help                      print this header
#
# Examples:
#   validate-relationships.sh
#   validate-relationships.sh --file tests/fixtures/graph/clean.md --kb-root tests/fixtures/graph/kb
#   validate-relationships.sh --print-class0-block > /tmp/class0.txt
#
# The checks:
#   V1  [REL-SHAPE]            header/delimiter byte-equal the carrier's column
#                              list; every data row has that many cells, with one
#                              space of padding per cell and a single space for an
#                              empty one; no required cell empty; no CR.
#   V2  [REL-UNRESOLVED]       each id resolves by the protocol for its own Kind.
#   V3  [REL-VOCAB]            both relation labels are in the merged vocabulary.
#   V4  [REL-PAIR]             (S2T, T2S) is a merged pair in either orientation;
#                              a symmetric relation's row is valid.
#   V5  [REL-DUPLICATE]        no two rows share a row key.
#   V6  [REL-PROVENANCE]       exactly one Provenance value, non-empty, lowercase.
#   V7  [REL-GRANULARITY]      no `int:` id carries any `#` fragment.
#   V8  [REL-IDENTITY]         each name equals the derived name for its kind; no
#                              id carries two names or two Kinds; no empty name.
#   V9  [REL-FRONTMATTER]      the frontmatter block is present and first, with
#                              its required scalars; no timestamp in the table or
#                              the AUTO-GENERATED marker.
#   V10 [REL-ORDER]            row order equals the recomputed sort order, and
#                              class 0 is a contiguous prefix.
#   V11 [REL-OBSERVATION]      on a class-0 row, Observation is empty or a durable
#                              anchor; no row carries a bare `file.ext:LINE`.
#   V12 [REL-ENDPOINT]         ADVISORY, per row: the row's (Source Kind, Target
#       [REL-ENDPOINT-UNUSED]  Kind) pair is in the chosen relation's declared set.
#                              ADVISORY, per run: declared tokens no row exercised,
#                              accumulated from BOTH readings of every row.
#   V13 [REL-KIND]             tier 1 kind/prefix agreement (so `image` + `ext:`
#                              passes), tier 2 kind-equals-grammar for `kb:` and
#                              kind-equals-extension for `int:`.
#   V14 [REL-COVERAGE]         the Coverage notes section: present, after the
#                              table, every enum kind once in enum order with a
#                              status and a count, the three exclusion rows in
#                              order, every extra-row rule, and no timestamp.
#   V15 [REL-CONCEPT-AMBIG]    ADVISORY: a term with more than one definition, and
#                              two terms differing only by plurality.
#
#   V12 and V15 are advisory by design and never gate: neither has an acceptance
#   criterion behind it, and gating either would fail the run for a property of an
#   artifact this tool is only permitted to observe.
#
# Output:
#   stdout  `[TAG] <file>: <message>` per finding, then
#           `Checked: N rows | Findings: M`. M counts EVERY finding printed,
#           advisories included; the exit code counts only the gating ones.
#   stderr  diagnostics only.
#
# Exit codes:
#   0 - clean, or advisories only
#   1 - one or more GATING findings
#   2 - usage error, unreadable input, or a malformed schema or vocabulary
#       (including any vocabulary collision or cross-entry violation, pair
#       coherence included)

set -uo pipefail

SELF="validate-relationships.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FILE=".aid/knowledge/relationships.md"
SCHEMA="$SCRIPT_DIR/../../templates/graph/relationship-schema.yml"
VOCAB="$SCRIPT_DIR/../../templates/graph/relation-vocabulary.yml"
VOCAB_EXT=""
VOCAB_EXT_SET=0
KB_ROOT=".aid/knowledge"
EXTERNAL_SOURCES=""
REPO_ROOT=""
LIBRARY="$SCRIPT_DIR/relationship-schema.sh"
PRINT_CLASS0=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file) FILE="${2:-}"; shift 2 ;;
        --schema) SCHEMA="${2:-}"; shift 2 ;;
        --vocabulary) VOCAB="${2:-}"; shift 2 ;;
        --vocabulary-extension) VOCAB_EXT="${2:-}"; VOCAB_EXT_SET=1; shift 2 ;;
        --kb-root) KB_ROOT="${2:-}"; shift 2 ;;
        --external-sources) EXTERNAL_SOURCES="${2:-}"; shift 2 ;;
        --repo-root) REPO_ROOT="${2:-}"; shift 2 ;;
        --library) LIBRARY="${2:-}"; shift 2 ;;
        --print-class0-block) PRINT_CLASS0=1; shift ;;
        # The header, to its LAST comment line and no further. A fixed line range
        # here is a `--help` that lies the moment the header changes length - the
        # first draft of this script printed fourteen lines of shell past the end
        # of its own documentation.
        -h|--help) awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$0"; exit 0 ;;
        *) echo "$SELF: unknown arg: $1" >&2; exit 2 ;;
    esac
done

[[ -f "$LIBRARY" ]] || { echo "$SELF: library not found at $LIBRARY" >&2; exit 2; }
# shellcheck source=./relationship-schema.sh disable=SC1090
. "$LIBRARY" || { echo "$SELF: cannot source $LIBRARY" >&2; exit 2; }

[[ -f "$FILE" ]] || { echo "$SELF: artifact not found at $(rel_abs_path "$FILE")" >&2; exit 2; }

# ---------------------------------------------------------------------------
# Step 2 - load both carriers BEFORE any check runs, so a configuration error is
# never reported as an artifact defect. Either load failing is exit 2, which is
# also how a vocabulary collision and every cross-entry violation - pair
# coherence included - reach the shell.
# ---------------------------------------------------------------------------

rel_load_schema "$SCHEMA" || exit 2

if [[ $VOCAB_EXT_SET -eq 0 ]] && [[ -f ".aid/graph/relation-vocabulary.yml" ]]; then
    VOCAB_EXT=".aid/graph/relation-vocabulary.yml"
fi
rel_load_vocabulary "$VOCAB" "$VOCAB_EXT" || exit 2

rel_set_kb_root "$KB_ROOT"
[[ -n "$EXTERNAL_SOURCES" ]] && rel_set_external_sources "$EXTERNAL_SOURCES"
[[ -n "$REPO_ROOT" ]] && rel_set_repo_root "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Finding accumulation. The validator emits RUBRIC TAGS, not severities: the
# skill's REVIEW state transcribes them into the reviewer ledger and grade.sh
# grades them.
# ---------------------------------------------------------------------------

FINDINGS=0
GATING=0
FINDING_LINES=""

finding() {   # finding <TAG> <message>
    FINDINGS=$((FINDINGS + 1))
    GATING=$((GATING + 1))
    FINDING_LINES="${FINDING_LINES}[$1] ${FILE}: $2"$'\n'
}

advisory() {  # advisory <TAG> <message> - counted, never gating
    FINDINGS=$((FINDINGS + 1))
    FINDING_LINES="${FINDING_LINES}[$1] ${FILE}: $2"$'\n'
}

# ---------------------------------------------------------------------------
# Column positions. The carrier fixes the ORDER; this contract fixes which
# column means what, so the positions are looked up BY NAME. Reordering the
# carrier moves them automatically, and a carrier missing one of them is a
# malformed carrier rather than a silently mis-indexed run.
# ---------------------------------------------------------------------------

NCOLS=0
COL_NAMES=()
while IFS= read -r _c; do
    [[ -n "$_c" ]] || continue
    COL_NAMES+=("$_c")
    NCOLS=$((NCOLS + 1))
done < <(rel_columns)

col_index() {  # col_index <name> -> 1-based position, or empty
    local want="$1" i=0
    for i in "${!COL_NAMES[@]}"; do
        [[ "${COL_NAMES[$i]}" == "$want" ]] && { printf '%d' "$((i + 1))"; return 0; }
    done
    return 1
}

IDX_SID="$(col_index 'Source Id')"      || { echo "$SELF: the schema carrier declares no 'Source Id' column" >&2; exit 2; }
IDX_SKIND="$(col_index 'Source Kind')"  || { echo "$SELF: the schema carrier declares no 'Source Kind' column" >&2; exit 2; }
IDX_SNAME="$(col_index 'Source Name')"  || { echo "$SELF: the schema carrier declares no 'Source Name' column" >&2; exit 2; }
IDX_TID="$(col_index 'Target Id')"      || { echo "$SELF: the schema carrier declares no 'Target Id' column" >&2; exit 2; }
IDX_TKIND="$(col_index 'Target Kind')"  || { echo "$SELF: the schema carrier declares no 'Target Kind' column" >&2; exit 2; }
IDX_TNAME="$(col_index 'Target Name')"  || { echo "$SELF: the schema carrier declares no 'Target Name' column" >&2; exit 2; }
IDX_S2T="$(col_index 'S2T Relation')"   || { echo "$SELF: the schema carrier declares no 'S2T Relation' column" >&2; exit 2; }
IDX_T2S="$(col_index 'T2S Relation')"   || { echo "$SELF: the schema carrier declares no 'T2S Relation' column" >&2; exit 2; }
IDX_PROV="$(col_index 'Provenance')"    || { echo "$SELF: the schema carrier declares no 'Provenance' column" >&2; exit 2; }

# The byte-exact header and delimiter, BUILT from the carrier - never a literal.
HEADER_WANT="|"
DELIM_WANT="|"
for _c in "${COL_NAMES[@]}"; do
    HEADER_WANT="$HEADER_WANT $_c |"
    DELIM_WANT="$DELIM_WANT---|"
done

# ---------------------------------------------------------------------------
# Read the artifact once. LINES[] is 1-based-by-convention (index 0 unused) so a
# reported line number is the file's own.
# ---------------------------------------------------------------------------

LINES=("")
HAS_CR=0
while IFS= read -r _l || [[ -n "$_l" ]]; do
    case "$_l" in *$'\r') HAS_CR=1; _l="${_l%$'\r'}" ;; esac
    LINES+=("$_l")
done < "$FILE"
NLINES=$((${#LINES[@]} - 1))

# ===========================================================================
# V9 - the emitted frontmatter (part 1: the block and its scalars)
# ===========================================================================

FM_END=0
if [[ "${LINES[1]:-}" != "---" ]]; then
    finding REL-FRONTMATTER "the frontmatter block is not the first content in the file (line 1 is not '---')"
else
    _i=2
    while [[ $_i -le $NLINES ]]; do
        [[ "${LINES[$_i]}" == "---" ]] && { FM_END=$_i; break; }
        _i=$((_i + 1))
    done
    [[ $FM_END -gt 0 ]] || finding REL-FRONTMATTER "the frontmatter block is never closed by a '---' line"
fi

fm_value() {  # fm_value <key> -> the raw value, or empty
    local key="$1" i=2 line
    [[ $FM_END -gt 0 ]] || return 1
    while [[ $i -lt $FM_END ]]; do
        line="${LINES[$i]}"
        if [[ "$line" == "$key:"* ]]; then
            line="${line#"$key":}"
            rel__trim_into "$line"
            printf '%s' "$REL_STR"
            return 0
        fi
        i=$((i + 1))
    done
    return 1
}

if [[ $FM_END -gt 0 ]]; then
    for _k in kb-category source generator objective summary tags; do
        if ! _v="$(fm_value "$_k")"; then
            finding REL-FRONTMATTER "frontmatter key '$_k' is absent"
        elif [[ -z "$_v" ]]; then
            finding REL-FRONTMATTER "frontmatter key '$_k' is empty"
        fi
    done
    # objective and summary must be single physical lines with no `|`: the index
    # generator reads them with a single-line scalar extractor and pipes each
    # through an escaper into a table cell, so a block scalar renders empty.
    for _k in objective summary; do
        if _v="$(fm_value "$_k")"; then
            case "$_v" in
                "|"|">"|"|-"|">-"|"|+"|">+")
                    finding REL-FRONTMATTER "frontmatter '$_k' is a block scalar; it must be a single physical line" ;;
                *"|"*)
                    finding REL-FRONTMATTER "frontmatter '$_k' contains a '|', which the index generator's cell escaper cannot carry" ;;
            esac
        fi
    done
fi

if [[ $HAS_CR -eq 1 ]]; then
    finding REL-SHAPE "the file carries CR characters; line endings are LF only, including the last line"
fi

# ===========================================================================
# Step 4 - locate the single table above `## Coverage notes`, assert its header
# and delimiter, then V1 over every data row.
# ===========================================================================

TABLE_HDR=0
TABLE_DELIM=0
TABLE_FIRST=0
TABLE_LAST=0
NOTES_LINE=0

# Two independent scans over the whole body, and that independence is what makes
# V14's positioning clause a real CHECK rather than something the locator quietly
# enforces. HDR_ANYWHERE finds the relationship table by its byte-exact header row
# wherever it sits - including BELOW the notes, which is the case V14 must be able
# to report; TABLE_HDR is the header the parse contract admits, i.e. the first
# table row above the notes heading.
HDR_ANYWHERE=0
_i=$((FM_END + 1))
[[ $_i -lt 1 ]] && _i=1
while [[ $_i -le $NLINES ]]; do
    if [[ $NOTES_LINE -eq 0 && "${LINES[$_i]}" == "## Coverage notes" ]]; then NOTES_LINE=$_i; fi
    if [[ $HDR_ANYWHERE -eq 0 && "${LINES[$_i]}" == "$HEADER_WANT" ]]; then HDR_ANYWHERE=$_i; fi
    if [[ $TABLE_HDR -eq 0 && $NOTES_LINE -eq 0 && "${LINES[$_i]}" == "|"* ]]; then TABLE_HDR=$_i; fi
    _i=$((_i + 1))
done

CHECKED=0
declare -a R_CELLS=()      # per row: the cells, US joined
declare -a R_LINENO=()
declare -a R_OK=()         # 1 when V1 passed, so V2-V8/V11-V13 may run

if [[ $TABLE_HDR -eq 0 ]]; then
    finding REL-SHAPE "no pipe table found in the body; the first non-blank line after the H1 must be the header row"
else
    [[ "${LINES[$TABLE_HDR]}" == "$HEADER_WANT" ]] || \
        finding REL-SHAPE "line $TABLE_HDR: the header row is not byte-equal the carrier's column list (want: $HEADER_WANT)"
    TABLE_DELIM=$((TABLE_HDR + 1))
    if [[ $TABLE_DELIM -gt $NLINES || "${LINES[$TABLE_DELIM]}" != "$DELIM_WANT" ]]; then
        finding REL-SHAPE "line $TABLE_DELIM: the delimiter row is not byte-equal '$DELIM_WANT'"
    fi
    TABLE_FIRST=$((TABLE_DELIM + 1))
    _i=$TABLE_FIRST
    while [[ $_i -le $NLINES && "${LINES[$_i]}" == "|"* ]]; do
        TABLE_LAST=$_i
        _i=$((_i + 1))
    done
    # the first non-table line is blank and the next non-blank line is the notes
    # heading: the notes are always AFTER the table, never interleaved.
    if [[ $TABLE_LAST -gt 0 && $((TABLE_LAST + 1)) -le $NLINES ]]; then
        [[ -z "${LINES[$((TABLE_LAST + 1))]}" ]] || \
            finding REL-SHAPE "line $((TABLE_LAST + 1)): the line after the table must be blank, so a parser stops at the table's end"
    fi

    _i=$TABLE_FIRST
    while [[ $_i -le ${TABLE_LAST:-0} ]]; do
        _line="${LINES[$_i]}"
        CHECKED=$((CHECKED + 1))
        _ok=1
        _cells=""
        _n=0
        if ! rel__row_cells_into "$_line"; then
            finding REL-SHAPE "line $_i: the row does not end with a '|', or a cell is unterminated"
            _ok=0
        fi
        for _cell in ${REL_ROW_CELLS+"${REL_ROW_CELLS[@]}"}; do
            _n=$((_n + 1))
            # padding: exactly one space either side; an empty cell renders as a
            # single space.
            if [[ "$_cell" == " " ]]; then
                _content=""
            elif [[ "$_cell" == " "* && "$_cell" == *" " && ${#_cell} -ge 3 ]]; then
                _content="${_cell# }"; _content="${_content% }"
                if [[ "$_content" == " "* || "$_content" == *" " ]]; then
                    finding REL-SHAPE "line $_i cell $_n: more than one space of padding"
                    _ok=0
                fi
            else
                finding REL-SHAPE "line $_i cell $_n: cell is not ' <content> ' and is not the single-space empty form"
                _ok=0
                _content="$_cell"
                rel__trim_into "$_content"; _content="$REL_STR"
            fi
            _cells="${_cells:+$_cells$REL_US}$_content"
            # A required column is never empty. Checked here, while the cell and
            # its position are both in hand, so no re-split is needed.
            #
            # This one does NOT set `_ok`, and the distinction is deliberate. The
            # parse-fatal conditions are the ones that stop the row being read at
            # all - a wrong cell count, broken padding, a missing terminator, a CR.
            # An empty required cell parses perfectly; it is a CONTENT defect, and
            # skipping the row for it would silently suppress every other rule on
            # the row's nine good cells. It also keeps V8's "no name is empty"
            # clause reachable: the two rules overlap on the two Name columns, by
            # design, and both fire.
            if [[ -z "$_content" && $_n -le $NCOLS ]] && rel__has_line "$REL_REQUIRED" "${COL_NAMES[$((_n - 1))]}"; then
                finding REL-SHAPE "line $_i: required column '${COL_NAMES[$((_n - 1))]}' is empty"
            fi
        done
        if [[ $_n -ne $NCOLS ]]; then
            finding REL-SHAPE "line $_i: $_n cells, want $NCOLS (an unescaped '|' inside a cell splits the row; escape it as '\\|')"
            _ok=0
        fi
        R_CELLS+=("$_cells")
        R_LINENO+=("$_i")
        R_OK+=("$_ok")
        _i=$((_i + 1))
    done
fi

NROWS=${#R_CELLS[@]}

# cell_into <row-index> <1-based column> -> CELL. Pure parameter expansion: this
# is called ten times per row and a command substitution here would be ten
# ~100 ms forks per row under Windows Git Bash / MSYS.
CELL=""
cell_into() {
    local rec="${R_CELLS[$1]}" i=1
    while [[ $i -lt $2 ]]; do
        rec="${rec#*"$REL_US"}"
        i=$((i + 1))
    done
    CELL="${rec%%"$REL_US"*}"
}
cell() { cell_into "$1" "$2"; printf '%s' "$CELL"; }

# ===========================================================================
# Step 5 - build the derived sets in ONE pass over the KB, so resolution is a set
# membership test per row rather than a rescan.
# ===========================================================================

rel_scan_kb

# ===========================================================================
# Steps 6-7 - the per-row checks.
# ===========================================================================

ID_NAME_TABLE=""       # lookup: id -> the name first seen, with its row
ID_KIND_TABLE=""       # lookup: id -> the Kind first seen, with its row
ROWKEY_TABLE=""        # lookup: row key -> the row it was first seen on
OBSERVED=""            # lookup-shaped accumulation: relation TAB token, both readings

# The bare-line-citation discrimination, reusing the KB citation lint's own
# pattern and its three durable-anchor exceptions verbatim: a colon followed by
# digits is a violation unless what follows is a letter, a `-` plus a letter, or a
# `.` plus a digit (an IP or a version).
#
# The awk fork is GATED on the cheap shell test below, so it happens only on an
# Observation that actually carries a colon-then-digit. A fork per row would
# dominate a large table's runtime under MSYS.
bare_line_citation() {
    case "$1" in
        *:[0-9]*) ;;
        *) return 1 ;;
    esac
    [[ "$(printf '%s' "$1" | awk -v pat="$REL_PATH_RE" '
        {
            line = $0
            while (match(line, pat ":[0-9]+([,-][0-9]+)*")) {
                a2 = substr(line, RSTART + RLENGTH, 2)
                a1 = substr(a2, 1, 1)
                bad = 1
                if (a1 ~ /[A-Za-z]/) bad = 0
                else if (a2 ~ /^\.[0-9]/) bad = 0
                else if (a2 ~ /^-[A-Za-z]/) bad = 0
                if (bad) { print "yes"; exit }
                line = substr(line, RSTART + RLENGTH)
            }
        }')" == "yes" ]]
}

# The durable-anchor predicate: the first whitespace-delimited token is a path
# naming a citable file. `rel__is_citation_path` IS that predicate - the same one
# the fact-anchor scan applies - so there is no second copy of it here, and no
# fork either.
durable_anchor() {
    local first="${1%%[[:space:]]*}"
    rel__is_citation_path "$first"
}

_r=0
while [[ $_r -lt $NROWS ]]; do
    _ln="${R_LINENO[$_r]}"
    if [[ "${R_OK[$_r]}" != "1" ]]; then _r=$((_r + 1)); continue; fi

    cell_into "$_r" "$IDX_SID";   sid="$CELL"
    cell_into "$_r" "$IDX_SKIND"; skind="$CELL"
    cell_into "$_r" "$IDX_SNAME"; sname="$CELL"
    cell_into "$_r" "$IDX_TID";   tid="$CELL"
    cell_into "$_r" "$IDX_TKIND"; tkind="$CELL"
    cell_into "$_r" "$IDX_TNAME"; tname="$CELL"
    cell_into "$_r" "$IDX_S2T";   s2t="$CELL"
    cell_into "$_r" "$IDX_T2S";   t2s="$CELL"
    cell_into "$_r" "$IDX_PROV";  prov="$CELL"
    obs=""
    for _oi in "${!COL_NAMES[@]}"; do
        if rel__has_line "$REL_OPTIONAL" "${COL_NAMES[$_oi]}"; then
            cell_into "$_r" "$((_oi + 1))"; obs="$CELL"
        fi
    done

    kind_ok=1

    # ---- V13 tier 1 + tier 2, and V7 -----------------------------------------
    for _side in source target; do
        if [[ "$_side" == source ]]; then _id="$sid"; _kd="$skind"; else _id="$tid"; _kd="$tkind"; fi

        # V7: no `int:` id carries ANY `#` fragment. The grammar admits none, so
        # the parser's own reason token routes the finding here rather than to
        # resolution - one rule, one place, one report.
        if ! rel_parse_id "$_id" && [[ "$REL_ID_REASON" == "int-fragment" ]]; then
            finding REL-GRANULARITY "line $_ln: $_side id '$_id' carries a '#' fragment; an int: id names a whole artifact and is never narrowed"
            kind_ok=0
            continue
        fi

        if ! rel_kind_prefix_ok "$_kd" "$_id"; then
            finding REL-KIND "line $_ln: $_side Kind '$_kd' / id '$_id': $REL_KIND_REASON"
            kind_ok=0
        fi

        # ---- V2 ---------------------------------------------------------------
        if rel__has_word "$REL_KINDS" "$_kd"; then
            rel_resolve_id_into "$_kd" "$_id" || \
                finding REL-UNRESOLVED "line $_ln: $_side id '$_id' (Kind $_kd) does not resolve: $REL_RESOLVE"
        fi

        # ---- V8: one name and one Kind per id, file-wide -----------------------
        if [[ "$_side" == source ]]; then _nm="$sname"; else _nm="$tname"; fi
        if [[ -z "$_nm" ]]; then
            finding REL-IDENTITY "line $_ln: $_side Name is empty"
        else
            if rel__lookup "$ID_NAME_TABLE" "$_id"; then
                if [[ "${REL_LOOKUP%%@*}" != "$_nm" ]]; then
                    finding REL-IDENTITY "line $_ln: id '$_id' carries name '$_nm' here and '${REL_LOOKUP%%@*}' on line ${REL_LOOKUP##*@}"
                fi
            else
                ID_NAME_TABLE="$ID_NAME_TABLE$REL_NL$_id$REL_TAB$_nm@$_ln"
            fi
            if rel__lookup "$ID_KIND_TABLE" "$_id"; then
                if [[ "${REL_LOOKUP%%@*}" != "$_kd" ]]; then
                    finding REL-IDENTITY "line $_ln: id '$_id' carries Kind '$_kd' here and '${REL_LOOKUP%%@*}' on line ${REL_LOOKUP##*@}"
                fi
            else
                ID_KIND_TABLE="$ID_KIND_TABLE$REL_NL$_id$REL_TAB$_kd@$_ln"
            fi
            # the name is a DERIVED value: recompute it and compare. When the
            # derivation cannot run - an id that does not resolve - V2 has already
            # reported that, so no second finding is raised here.
            if rel_display_name_into "$_kd" "$_id" 2>/dev/null; then
                [[ "$REL_NAME" == "$_nm" ]] || \
                    finding REL-IDENTITY "line $_ln: $_side Name is '$_nm'; the rule for Kind '$_kd' derives '$REL_NAME'"
            fi
        fi
    done

    # ---- V3 -------------------------------------------------------------------
    v3_ok=1
    for _lbl in "$s2t" "$t2s"; do
        if ! rel_is_relation "$_lbl"; then
            finding REL-VOCAB "line $_ln: relation '$_lbl' is not a member of the merged vocabulary"
            v3_ok=0
        fi
    done

    # ---- V4 -------------------------------------------------------------------
    if [[ $v3_ok -eq 1 ]] && ! rel_pair_ok "$s2t" "$t2s"; then
        finding REL-PAIR "line $_ln: ('$s2t', '$t2s') is not an inverse pair in either orientation"
    fi

    # ---- V6 -------------------------------------------------------------------
    if ! rel__has_word "$REL_PROVENANCE" "$prov"; then
        finding REL-PROVENANCE "line $_ln: Provenance '$prov' is not one of: $REL_PROVENANCE"
    fi

    # ---- V11 ------------------------------------------------------------------
    if [[ -n "$obs" ]]; then
        if [[ "$prov" != "inferred" ]] && ! durable_anchor "$obs"; then
            finding REL-OBSERVATION "line $_ln: on a $prov row, Observation must be empty or a durable anchor (a path plus a grep-recoverable string); '$obs' is neither"
        fi
        if bare_line_citation "$obs"; then
            finding REL-OBSERVATION "line $_ln: Observation carries a bare file.ext:LINE citation, which is forbidden on any row"
        fi
    fi

    # ---- V5 -------------------------------------------------------------------
    rel_row_key_into "$sid" "$skind" "$sname" "$tid" "$tkind" "$tname" "$s2t" "$t2s" "$prov" "$obs"
    _key="$REL_ROW_KEY"
    if rel__lookup "$ROWKEY_TABLE" "$_key"; then
        finding REL-DUPLICATE "line $_ln: this relationship is already recorded on line $REL_LOOKUP (a repeat, or the same relationship written in the opposite orientation)"
    else
        ROWKEY_TABLE="$ROWKEY_TABLE$REL_NL$_key$REL_TAB$_ln"
    fi

    # ---- V12, per row, and the accumulation the per-run direction consumes ----
    if [[ $kind_ok -eq 1 && $v3_ok -eq 1 ]]; then
        if rel_endpoint_kinds_into "$s2t"; then
            _decl="$REL_LOOKUP"
            rel__has_word "$_decl" "$skind->$tkind" || \
                advisory REL-ENDPOINT "line $_ln: relation '$s2t' does not declare the endpoint pair '$skind->$tkind' (declared: $_decl)"
        fi
        # BOTH readings the row asserts. Accumulating the stored S2T alone would
        # report the forward token of roughly half of every asymmetric pair as
        # unobserved, because rows are STORED in normalised orientation.
        OBSERVED="$OBSERVED$REL_NL$s2t$REL_TAB$skind->$tkind"
        OBSERVED="$OBSERVED$REL_NL$t2s$REL_TAB$tkind->$skind"
    fi

    _r=$((_r + 1))
done

# ===========================================================================
# Step 8 - V10, then the D7b extraction.
# ===========================================================================

if [[ $NROWS -gt 0 ]]; then
    # Built fork-free, then sorted ONCE. `-t <TAB> -k1,1` sorts on the key field
    # alone, so the row index appended for traceability cannot influence the
    # order. LC_ALL=C is what removes the environment from the contract: `int:`
    # ids carry exact on-disk case, so a case-folding locale would reorder rows.
    _seq=""
    _r=0
    while [[ $_r -lt $NROWS ]]; do
        if [[ "${R_OK[$_r]}" == "1" ]]; then
            cell_into "$_r" "$IDX_SID";   _f1="$CELL"
            cell_into "$_r" "$IDX_SKIND"; _f2="$CELL"
            cell_into "$_r" "$IDX_SNAME"; _f3="$CELL"
            cell_into "$_r" "$IDX_TID";   _f4="$CELL"
            cell_into "$_r" "$IDX_TKIND"; _f5="$CELL"
            cell_into "$_r" "$IDX_TNAME"; _f6="$CELL"
            cell_into "$_r" "$IDX_S2T";   _f7="$CELL"
            cell_into "$_r" "$IDX_T2S";   _f8="$CELL"
            cell_into "$_r" "$IDX_PROV";  _f9="$CELL"
            rel_sort_key_into "$_f1" "$_f2" "$_f3" "$_f4" "$_f5" "$_f6" "$_f7" "$_f8" "$_f9" ""
            _seq="${_seq}${REL_SORT_KEY}${REL_TAB}${_r}"$'\n'
        fi
        _r=$((_r + 1))
    done
    _seq="${_seq%$'\n'}"
    _want_order="$(printf '%s\n' "$_seq" | LC_ALL=C sort -t"$REL_TAB" -k1,1 | awk -F"$REL_TAB" '{print $2}')"
    _have_order="$(printf '%s\n' "$_seq" | awk -F"$REL_TAB" '{print $2}')"
    if [[ "$_want_order" != "$_have_order" ]]; then
        _first=""
        while IFS= read -r _w && IFS= read -r -u 3 _h; do
            if [[ "$_w" != "$_h" ]]; then _first="${R_LINENO[$_h]}"; break; fi
        done < <(printf '%s\n' "$_want_order") 3< <(printf '%s\n' "$_have_order")
        finding REL-ORDER "the table's row order is not the recomputed (class, source id, target id, S2T, T2S) LC_ALL=C ascending order${_first:+; the first row out of place is line $_first}"
    fi

    # class 0 must be a CONTIGUOUS PREFIX: adding, removing or rewording an
    # inferred row must not be able to move a deterministic one.
    _seen1=0
    _r=0
    while [[ $_r -lt $NROWS ]]; do
        if [[ "${R_OK[$_r]}" == "1" ]]; then
            cell_into "$_r" "$IDX_PROV"; _p="$CELL"
            if [[ "$_p" == "inferred" ]]; then
                _seen1=1
            elif [[ $_seen1 -eq 1 ]]; then
                finding REL-ORDER "line ${R_LINENO[$_r]}: a $_p (class 0) row appears after an inferred (class 1) row; the deterministic block must be a contiguous prefix"
                break
            fi
        fi
        _r=$((_r + 1))
    done
fi

# D7b's extraction, run AFTER V10 because its single-pass prefix scan is sound
# only on a V10-passing table. Its row count is compared against the class-0 rows
# this run counted, which is what turns D7b's soundness precondition into a
# machine-checked property rather than a trusted one.
CLASS0_BLOCK="$(rel_class0_block "$FILE")"
if [[ $NROWS -gt 0 && $GATING -eq 0 ]]; then
    _extracted=$(( $(printf '%s\n' "$CLASS0_BLOCK" | grep -c '^|') - 2 ))
    _counted=0
    _r=0
    while [[ $_r -lt $NROWS ]]; do
        cell_into "$_r" "$IDX_PROV"
        [[ "$CELL" == "inferred" ]] || _counted=$((_counted + 1))
        _r=$((_r + 1))
    done
    if [[ "$_extracted" -ne "$_counted" ]]; then
        finding REL-ORDER "the class-0 extraction found $_extracted rows but the table carries $_counted non-inferred rows; the extraction's prefix scan and the table disagree"
    fi
fi

if [[ $PRINT_CLASS0 -eq 1 ]]; then
    if [[ $GATING -gt 0 ]]; then
        # stdout carries the RESULT, so on refusal it carries NOTHING: a caller
        # byte-comparing this stream must never be handed a findings list to
        # compare. The findings and the refusal both go to stderr.
        printf '%s' "$FINDING_LINES" >&2
        echo "$SELF: refusing to print the class-0 block: the table has $GATING gating finding(s)" >&2
        exit 1
    fi
    printf '%s\n' "$CLASS0_BLOCK"
    exit 0
fi

# ===========================================================================
# V9, part 2 - the timestamp ban over the table and the AUTO-GENERATED marker.
#
# ONE implementation of the rule (has_timestamp), TWO regions: V9 owns the marker
# and the table, V14 owns the coverage-notes section. The regions partition the
# body, so nothing is reported twice and nothing is left unchecked - a second copy
# of the pattern in the second checker is exactly the divergence this split
# avoids.
# ===========================================================================

has_timestamp() {  # has_timestamp <from> <to> -> prints the first offending line number
    local from="$1" to="$2" i="$1"
    while [[ $i -le $to && $i -le $NLINES ]]; do
        case "${LINES[$i]}" in
            *[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*) printf '%d' "$i"; return 0 ;;
            *[0-9][0-9]:[0-9][0-9]:[0-9][0-9]*) printf '%d' "$i"; return 0 ;;
        esac
        i=$((i + 1))
    done
    return 1
}

_body_from=$((FM_END + 1))
[[ $_body_from -lt 1 ]] && _body_from=1
_table_to=$NLINES
[[ $NOTES_LINE -gt 0 ]] && _table_to=$((NOTES_LINE - 1))
if _ts="$(has_timestamp "$_body_from" "$_table_to")"; then
    finding REL-FRONTMATTER "line $_ts: a timestamp appears in the table or the AUTO-GENERATED marker; no date or time may appear there, or the deterministic content would differ across runs"
fi

# ===========================================================================
# Step 9 - V14 (the coverage notes), then the two whole-table advisories.
# ===========================================================================

if [[ $NOTES_LINE -eq 0 ]]; then
    finding REL-COVERAGE "the '## Coverage notes' section is absent; it is required on EVERY run, not only when something is missing"
else
    # Positioned AFTER the table. Decided against HDR_ANYWHERE, not against the
    # parsed table, so a relationship table sitting BELOW the notes is reported as
    # the ordering defect it is rather than as a missing table.
    #
    # There is deliberately no second comparison against the PARSED table: the
    # parsed table's rows stop at the first line that is not a table row, and the
    # notes heading is not one, so `TABLE_LAST < NOTES_LINE` holds by construction
    # and a check on it could never fire. HDR_ANYWHERE is the one reachable form.
    if [[ $HDR_ANYWHERE -gt 0 && $HDR_ANYWHERE -gt $NOTES_LINE ]]; then
        finding REL-COVERAGE "the '## Coverage notes' heading (line $NOTES_LINE) is ABOVE the relationship table's header row (line $HDR_ANYWHERE); the notes must follow the table, so that a parser reading the table stops at its end and never reads the notes"
    fi
    if _ts="$(has_timestamp "$NOTES_LINE" "$NLINES")"; then
        finding REL-COVERAGE "line $_ts: a timestamp appears in the Coverage notes section; no value there may vary between two runs on identical inputs"
    fi

    check_notes_table() {  # check_notes_table <table> <heading> <ncells>
        local table="$1" heading="$2" ncells="$3"
        local fixed; fixed="$(rel_coverage_fixed_keys "$table")" || return 2
        local nfixed=0 f
        while IFS= read -r f; do [[ -n "$f" ]] && nfixed=$((nfixed + 1)); done <<< "$fixed"

        local i=$NOTES_LINE start=0
        while [[ $i -le $NLINES ]]; do
            [[ "${LINES[$i]}" == "### $heading" ]] && { start=$i; break; }
            i=$((i + 1))
        done
        if [[ $start -eq 0 ]]; then
            finding REL-COVERAGE "the Coverage notes carry no '### $heading' table"
            return 0
        fi

        # collect the table's rows
        local rows=() rlines=()
        i=$((start + 1))
        while [[ $i -le $NLINES ]]; do
            case "${LINES[$i]}" in
                "|"*) rows+=("${LINES[$i]}"); rlines+=("$i") ;;
                "#"*) break ;;
            esac
            i=$((i + 1))
        done
        if [[ ${#rows[@]} -lt $((nfixed + 2)) ]]; then
            finding REL-COVERAGE "the '### $heading' table has ${#rows[@]} rows; its header, delimiter and $nfixed fixed rows are all required"
            return 0
        fi

        local keys=() r first_cell nc
        local ri=0
        for r in "${rows[@]}"; do
            ri=$((ri + 1))
            [[ $ri -le 2 ]] && continue          # the table's own header and delimiter
            rel__row_cells_into "$r" || true
            nc=${#REL_ROW_CELLS[@]}
            first_cell="${REL_ROW_CELLS[0]:-}"
            rel__trim_into "$first_cell"
            keys+=("$REL_STR")
            if [[ "$nc" -ne "$ncells" ]]; then
                finding REL-COVERAGE "line ${rlines[$((ri - 1))]}: row has $nc cells; the '### $heading' table carries $ncells"
            fi
        done

        # the fixed rows come first, complete and in their fixed order
        local k=0 want
        while IFS= read -r want; do
            [[ -n "$want" ]] || continue
            if [[ $k -ge ${#keys[@]} || "${keys[$k]}" != "$want" ]]; then
                finding REL-COVERAGE "the '### $heading' table's fixed row $((k + 1)) is '${keys[$k]:-(absent)}'; the fixed set must appear first, complete and in its fixed order, want '$want'"
                return 0
            fi
            k=$((k + 1))
        done <<< "$fixed"

        # the kinds table's fixed rows carry a status from the enum and a
        # non-negative integer count.
        if [[ "$table" == kinds ]]; then
            local j=0
            while [[ $j -lt $nfixed ]]; do
                rel__row_cells_into "${rows[$((j + 2))]}" || true
                local c3 c4
                c3="${REL_ROW_CELLS[2]:-}"
                c4="${REL_ROW_CELLS[3]:-}"
                rel__trim_into "$c3"; c3="$REL_STR"
                rel__trim_into "$c4"; c4="$REL_STR"
                case "$c3" in
                    present|absent) ;;
                    *) finding REL-COVERAGE "line ${rlines[$((j + 2))]}: Status '$c3' is not 'present' or 'absent'" ;;
                esac
                case "$c4" in
                    ""|*[!0-9]*) finding REL-COVERAGE "line ${rlines[$((j + 2))]}: Nodes '$c4' is not a non-negative integer" ;;
                esac
                j=$((j + 1))
            done
        fi

        # ---- the extra rows: contiguity, charset, collision, uniqueness, order
        local extra=() ei=$nfixed
        while [[ $ei -lt ${#keys[@]} ]]; do
            extra+=("${keys[$ei]}")
            ei=$((ei + 1))
        done
        local seen="" e n=0
        for e in ${extra+"${extra[@]}"}; do
            n=$((n + 1))
            if rel__has_line "$fixed" "$e"; then
                finding REL-COVERAGE "the '### $heading' table repeats fixed key '$e' below the fixed block; the two groups are contiguous and a fixed key may not appear as an extra row"
                continue
            fi
            case "$e" in
                [a-z0-9]*) ;;
                *) finding REL-COVERAGE "the '### $heading' table's extra key '$e' must match [a-z0-9][a-z0-9-]*" ; continue ;;
            esac
            case "$e" in
                *[!a-z0-9-]*) finding REL-COVERAGE "the '### $heading' table's extra key '$e' must match [a-z0-9][a-z0-9-]*" ; continue ;;
            esac
            if rel__has_line "$seen" "$e"; then
                finding REL-COVERAGE "the '### $heading' table carries extra key '$e' more than once; extra keys are unique within a table"
                continue
            fi
            seen="${seen:+$seen$REL_NL}$e"
        done

        # the sequence is RECOMPUTED and compared, exactly as V10 does for the
        # table: an order nothing validates is the same class of defect as a
        # guarantee nothing achieves.
        if [[ $n -gt 1 ]]; then
            local have="" srt
            for e in ${extra+"${extra[@]}"}; do have="${have:+$have$REL_NL}$e"; done
            rel__sort_lines "$have"; srt="$REL_STR"
            if [[ "$have" != "$srt" ]]; then
                finding REL-COVERAGE "the '### $heading' table's extra rows are not in LC_ALL=C ascending key order (file: $(printf '%s' "$have" | tr '\n' ' '); want: $(printf '%s' "$srt" | tr '\n' ' '))"
            fi
        fi

        # the file-order accessor must agree with what this pass read, which is
        # what keeps the exposed surface and the check from drifting apart.
        local acc; acc="$(rel_coverage_extra_keys "$FILE" "$table")" || true
        local mine=""
        for e in ${extra+"${extra[@]}"}; do mine="${mine:+$mine$REL_NL}$e"; done
        if [[ "$(printf '%s' "$acc")" != "$(printf '%s' "$mine")" ]]; then
            finding REL-COVERAGE "internal: rel_coverage_extra_keys disagrees with the '### $heading' scan"
        fi
        return 0
    }

    check_notes_table kinds "Node kinds" 4
    check_notes_table exclusions "Enumeration exclusions" 3
fi

# ---- V15: the concept advisories -------------------------------------------
_terms="$(rel_concept_terms)"
while IFS= read -r _t; do
    [[ -n "$_t" ]] || continue
    rel__count_defs "$_t"
    if [[ "$REL_DEF_COUNT" -gt 1 ]]; then
        advisory REL-CONCEPT-AMBIG "concept term '$_t' carries $REL_DEF_COUNT definitions; the plain kb:concept:$_t form is never emitted for it and each definition needs the qualified @<doc> form"
    fi
done <<< "$_terms"

while IFS= read -r _a; do
    [[ -n "$_a" ]] || continue
    while IFS= read -r _b; do
        [[ -n "$_b" ]] || continue
        [[ "$_a" == "$_b" ]] && continue
        _hit=""
        [[ "$_b" == "${_a}s"  ]] && _hit="trailing s"
        [[ "$_b" == "${_a}es" ]] && _hit="trailing es"
        if [[ "$_a" == *y && "$_b" == "${_a%y}ies" ]]; then _hit="y/ies alternation"; fi
        if [[ -n "$_hit" ]]; then
            advisory REL-CONCEPT-AMBIG "concept terms '$_a' and '$_b' differ only by plurality ($_hit); plurals are not folded, so these are two nodes - check the glossary"
        fi
    done <<< "$_terms"
done <<< "$_terms"

# ---- V12, per run: the declared tokens no row exercised ---------------------
# A set difference over the pairs step 6 accumulated from BOTH readings of every
# row. Partitioned: a relation WITH rows has its unobserved tokens listed
# individually, because that is the actionable over-declaration signal; the
# relations with NO rows are named together on ONE line, because for those every
# declared token is unobserved by construction and listing them would bury the
# actionable class in the routine one.
UNUSED_RELATIONS=""
while IFS= read -r _rel; do
    [[ -n "$_rel" ]] || continue
    rel_endpoint_kinds_into "$_rel" || continue
    _decl="$REL_LOOKUP"
    # does this relation appear in EITHER relation column of any row?
    _has_rows=0
    case "$OBSERVED" in *"$REL_NL$_rel$REL_TAB"*) _has_rows=1 ;; esac
    if [[ $_has_rows -eq 0 ]]; then
        UNUSED_RELATIONS="${UNUSED_RELATIONS:+$UNUSED_RELATIONS }$_rel"
        continue
    fi
    _missing=""
    for _tok in $_decl; do
        case "$OBSERVED" in
            *"$REL_NL$_rel$REL_TAB$_tok"*) ;;
            *) _missing="${_missing:+$_missing }$_tok" ;;
        esac
    done
    [[ -n "$_missing" ]] && \
        advisory REL-ENDPOINT-UNUSED "relation '$_rel' has rows but no row exercised its declared endpoint token(s): $_missing"
done < <(rel_vocab_relations)

if [[ -n "$UNUSED_RELATIONS" ]]; then
    advisory REL-ENDPOINT-UNUSED "no row used these relations at all, so every token each declares is unobserved: $UNUSED_RELATIONS"
fi

# ===========================================================================
# Step 10 - the findings and the fixed trailer.
# ===========================================================================

printf '%s' "$FINDING_LINES"
printf 'Checked: %d rows | Findings: %d\n' "$CHECKED" "$FINDINGS"

[[ $GATING -gt 0 ]] && exit 1
exit 0
