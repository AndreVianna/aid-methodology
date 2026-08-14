#!/usr/bin/env bash
# assemble-coverage-notes.sh - render the `## Coverage notes` section from both
# producer contributions.
#
# Purpose:
#   The section's shape, row set, order and validation belong to the relationship-table
#   schema; its content is produced by the source enumeration and the two-pass
#   extraction. ASSEMBLING the rendered section is this script's job, and it is the
#   only place the producers' machine shape meets the artifact's rendered shape.
#
#   Three rules, each answering a way a naive assembler gets it wrong:
#
#   1. THE FIELDS ARE REORDERED, NOT PASSED THROUGH. The contribution shape is
#      `scope | key | status | count | note`. The rendered kind table is
#      `| Kind | Carrier convention | Status | Nodes |`, so a kind row emits
#      key, note, status, count. The rendered exclusions table is
#      `| Exclusion | Applied | Note |`, so an exclusion row emits label, status, note
#      and drops `count` entirely. A pass-through implementation produces a section
#      the table validator rejects.
#
#   2. EXCLUSION KEYS ARE TRANSLATED; KIND KEYS ARE NOT. The producers emit machine
#      keys and the section carries rendered labels. The translation table lives here,
#      in one place, because the producer cannot see the labels. An extra exclusion key
#      has no label and is rendered as its own key.
#
#   3. EXTRA ROWS SORT BY KEY ACROSS BOTH FILES. Each row's host table is its own
#      `scope`; fixed rows come first in their fixed order, then every extra row of
#      that scope from BOTH producers in LC_ALL=C ascending key order. Because the
#      order keys on the row and never on its origin, the contributions may be read in
#      any order and the output is the same bytes.
#
#   Nothing in the output varies between two runs on identical inputs -- no timestamp,
#   no count-dependent ordering -- because the whole section sits inside the artifact's
#   byte-identity guarantee.
#
# Usage:
#   assemble-coverage-notes.sh [--coverage PATH] [--kb-coverage PATH]
#                              [--schema PATH] [--output PATH]
#   assemble-coverage-notes.sh -h | --help
#
# Flags:
#   --coverage PATH     The enumeration's contribution.
#                       Default: .aid/.temp/graph/coverage.tsv
#   --kb-coverage PATH  The extraction's contribution.
#                       Default: .aid/.temp/graph/kb-coverage.tsv
#   --schema PATH       relationship-schema.yml, for the `Kind` enum and its declared
#                       order. Default: <install-root>/aid/templates/graph/
#                       relationship-schema.yml, resolved from this script's own
#                       location. The enum is read through the schema loader where it
#                       is installed, so no copy of the enum lives here.
#   --output PATH       Where the rendered section is written.
#                       Default: .aid/.temp/graph/coverage-notes.md
#
# Input shape (both contributions, tab-separated, no header):
#   scope | key | status | count | note
#   scope is `kind` or `exclusion`; `--` is the unset marker in status and count.
#
# Two assembly failures exit 1 naming the offenders, rather than writing a section a
# validator will reject afterwards:
#   - a table's fixed block did not receive exactly one row per fixed key -- the
#     `Kind` enum for the kinds table, the three exclusions for the exclusions table;
#   - an extra key collides with a fixed key, or with another extra row in the same
#     table.
# Both are cheaper to name at this seam than to diagnose from a validator failure on
# an emitted artifact. The first is stated over BOTH fixed blocks rather than only the
# kinds table, because a missing or doubled exclusion row is the same defect on the
# other table and leaves the same section invalid. A key that collides with a fixed
# key is reported by the first check, which is where a second row for a fixed key
# lands.
#
# Output:
#   stdout: the row counts written. stderr: diagnostics, prefixed
#           `assemble-coverage-notes.sh: `.
#
# Exit codes:
#   0 - the section was written
#   1 - an assembly conflict, with every offender named
#   2 - a usage error, or a missing/unreadable input

set -euo pipefail
export LC_ALL=C

SELF="assemble-coverage-notes.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
INSTALL_ROOT=$(cd -- "${SCRIPT_DIR}/../../.." && pwd)

COVERAGE=""
KB_COVERAGE=""
SCHEMA=""
OUTPUT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --coverage)    COVERAGE="$2"; shift 2 ;;
        --kb-coverage) KB_COVERAGE="$2"; shift 2 ;;
        --schema)      SCHEMA="$2"; shift 2 ;;
        --output)      OUTPUT="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0"
            exit 0
            ;;
        *)
            echo "${SELF}: unknown flag: $1" >&2
            exit 2
            ;;
    esac
done

[ -n "$COVERAGE" ]    || COVERAGE=".aid/.temp/graph/coverage.tsv"
[ -n "$KB_COVERAGE" ] || KB_COVERAGE=".aid/.temp/graph/kb-coverage.tsv"
[ -n "$SCHEMA" ]      || SCHEMA="${INSTALL_ROOT}/aid/templates/graph/relationship-schema.yml"
[ -n "$OUTPUT" ]      || OUTPUT=".aid/.temp/graph/coverage-notes.md"

for f in "$COVERAGE" "$KB_COVERAGE"; do
    if [ ! -r "$f" ]; then
        echo "${SELF}: contribution not readable at ${f}" >&2
        exit 2
    fi
done

# ---------------------------------------------------------------------------
# The `Kind` enum and its declared order. Read through the schema loader where it is
# installed, so this script holds no copy of the enum; where the loader is not yet
# installed the schema's own `kinds:` block is read directly, with a notice, exactly
# as the sibling enumerator degrades.
# ---------------------------------------------------------------------------
if [ ! -r "$SCHEMA" ]; then
    echo "${SELF}: schema not readable at ${SCHEMA}" >&2
    exit 2
fi

KINDS=""
SCHEMA_LOADER="${SCRIPT_DIR}/relationship-schema.sh"
if [ -f "$SCHEMA_LOADER" ]; then
    # shellcheck disable=SC1090
    if . "$SCHEMA_LOADER" && command -v rel_load_schema >/dev/null 2>&1 \
        && rel_load_schema "$SCHEMA"; then
        KINDS="${REL_KINDS:-}"
    fi
fi
if [ -z "$KINDS" ]; then
    echo "${SELF}: notice: the schema loader is not installed; reading the Kind enum directly from ${SCHEMA}" >&2
    KINDS=$(awk '
        /^kinds:[[:space:]]*$/ { in_kinds = 1; next }
        in_kinds && /^[a-zA-Z]/ { in_kinds = 0 }
        in_kinds && /^[[:space:]]*-[[:space:]]*"/ {
            line = $0
            sub(/^[[:space:]]*-[[:space:]]*"/, "", line)
            sub(/".*$/, "", line)
            sub(/\|.*$/, "", line)
            printf "%s ", line
        }
    ' "$SCHEMA")
fi
KINDS=$(printf '%s' "$KINDS" | tr ',' ' ')
if [ -z "${KINDS// /}" ]; then
    echo "${SELF}: no Kind enum could be read from ${SCHEMA}" >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# The fixed exclusion rows, in their fixed order, and the key -> rendered label
# translation. This is the one place the translation lives.
# ---------------------------------------------------------------------------
EXCLUSION_KEYS="generated-trees vendored-code ignore-list"

exclusion_label() {
    case "$1" in
        generated-trees) printf '%s' "generated/derived trees" ;;
        vendored-code)   printf '%s' "vendored third-party code" ;;
        ignore-list)     printf '%s' '`.aid/settings.yml` ignore list' ;;
        *)               printf '%s' "$1" ;;
    esac
}

W=$(mktemp -d 2>/dev/null) || { echo "${SELF}: cannot create a scratch directory" >&2; exit 2; }
trap 'rm -rf "$W"' EXIT

# Both contributions, concatenated. Order of concatenation is immaterial by rule 3;
# the producer each row came from is carried only so a collision can name it.
: > "$W/rows"
awk -F'\t' -v origin="$COVERAGE" 'NF >= 2 { print origin "\t" $0 }' "$COVERAGE"    >> "$W/rows"
awk -F'\t' -v origin="$KB_COVERAGE" 'NF >= 2 { print origin "\t" $0 }' "$KB_COVERAGE" >> "$W/rows"

# Fields after the origin prefix: 2=scope 3=key 4=status 5=count 6=note
lookup_rows() {
    local scope="$1" key="$2"
    awk -F'\t' -v scope="$scope" -v key="$key" '$2 == scope && $3 == key' "$W/rows"
}

CONFLICTS=0
conflict() {
    echo "${SELF}: ${1}" >&2
    CONFLICTS=1
}

# --- the kind table's fixed block: exactly one row per enum value ----------
: > "$W/kind.fixed"
# shellcheck disable=SC2086  # deliberate splitting: the enum is a space-separated list
for kind in $KINDS; do
    n=$(lookup_rows kind "$kind" | wc -l | tr -d ' ')
    if [ "$n" -eq 0 ]; then
        conflict "no producer supplied a kind row for '${kind}'; the kinds table needs exactly one fixed row per Kind enum value"
    elif [ "$n" -gt 1 ]; then
        producers=$(lookup_rows kind "$kind" | cut -f1 | sort -u | tr '\n' ' ')
        conflict "kind '${kind}' was supplied ${n} times, by: ${producers}"
    else
        lookup_rows kind "$kind" >> "$W/kind.fixed"
    fi
done

# --- the exclusions table's fixed block ------------------------------------
: > "$W/exclusion.fixed"
# shellcheck disable=SC2086  # deliberate splitting: a space-separated fixed-key list
for key in $EXCLUSION_KEYS; do
    n=$(lookup_rows exclusion "$key" | wc -l | tr -d ' ')
    if [ "$n" -eq 0 ]; then
        conflict "no producer supplied the exclusion row for '${key}'"
    elif [ "$n" -gt 1 ]; then
        producers=$(lookup_rows exclusion "$key" | cut -f1 | sort -u | tr '\n' ' ')
        conflict "exclusion '${key}' was supplied ${n} times, by: ${producers}"
    else
        lookup_rows exclusion "$key" >> "$W/exclusion.fixed"
    fi
done

# --- extra rows: everything whose key is not a fixed key of its table ------
# shellcheck disable=SC2086  # deliberate splitting: space-separated key lists
printf '%s\n' $KINDS          | sort > "$W/kind.keys"
# shellcheck disable=SC2086
printf '%s\n' $EXCLUSION_KEYS | sort > "$W/exclusion.keys"

# Ordered by KEY under LC_ALL=C, never by the producer the row came from -- which is
# the property that lets the two contributions be read in either order.
extras_of() {
    local scope="$1" keyfile="$2"
    awk -F'\t' -v scope="$scope" '
        NR == FNR { fixed[$0] = 1; next }
        $2 == scope && !($3 in fixed)
    ' "$keyfile" "$W/rows" | sort -t$'\t' -k3,3
}

extras_of kind      "$W/kind.keys"      > "$W/kind.extra"
extras_of exclusion "$W/exclusion.keys" > "$W/exclusion.extra"

# An extra key must be unique among the extra rows of its own table.
for pair in "kind:$W/kind.extra" "exclusion:$W/exclusion.extra"; do
    scope="${pair%%:*}"
    file="${pair#*:}"
    while IFS= read -r dupkey; do
        [ -n "$dupkey" ] || continue
        producers=$(awk -F'\t' -v k="$dupkey" '$3 == k { print $1 }' "$file" | sort -u | tr '\n' ' ')
        conflict "extra ${scope} key '${dupkey}' appears more than once, from: ${producers}"
    done < <(cut -f3 "$file" | sort | uniq -d)
done

if [ "$CONFLICTS" -ne 0 ]; then
    echo "${SELF}: the section was not written" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Render. Field reordering happens here and nowhere else.
# ---------------------------------------------------------------------------
OUT_DIR=$(dirname -- "$OUTPUT")
mkdir -p "$OUT_DIR" || { echo "${SELF}: cannot create ${OUT_DIR}" >&2; exit 2; }

emit_kind_rows() {
    # rendered order: key, note, status, count
    awk -F'\t' '{ printf "| %s | %s | %s | %s |\n", $3, $6, $4, $5 }' "$1"
}

TMP_OUT="$W/coverage-notes.md"
{
    echo "## Coverage notes"
    echo ""
    echo "### Node kinds"
    echo ""
    echo "| Kind | Carrier convention | Status | Nodes |"
    echo "|------|--------------------|--------|-------|"
    emit_kind_rows "$W/kind.fixed"
    emit_kind_rows "$W/kind.extra"
    echo ""
    echo "### Enumeration exclusions"
    echo ""
    echo "| Exclusion | Applied | Note |"
    echo "|-----------|---------|------|"
    # rendered order: label, status, note -- `count` is dropped entirely
    while IFS=$'\t' read -r _origin _scope key status _count note; do
        [ -n "$key" ] || continue
        printf '| %s | %s | %s |\n' "$(exclusion_label "$key")" "$status" "$note"
    done < "$W/exclusion.fixed"
    while IFS=$'\t' read -r _origin _scope key status _count note; do
        [ -n "$key" ] || continue
        printf '| %s | %s | %s |\n' "$(exclusion_label "$key")" "$status" "$note"
    done < "$W/exclusion.extra"
} > "$TMP_OUT"

mv -f "$TMP_OUT" "$OUTPUT"

KIND_FIXED=$(wc -l < "$W/kind.fixed" | tr -d ' ')
KIND_EXTRA=$(wc -l < "$W/kind.extra" | tr -d ' ')
EXCL_FIXED=$(wc -l < "$W/exclusion.fixed" | tr -d ' ')
EXCL_EXTRA=$(wc -l < "$W/exclusion.extra" | tr -d ' ')

echo "[coverage-notes] kinds: ${KIND_FIXED} fixed + ${KIND_EXTRA} extra; exclusions: ${EXCL_FIXED} fixed + ${EXCL_EXTRA} extra -> ${OUTPUT}"
exit 0
