#!/usr/bin/env bash
# connector-registry.sh -- dedicated frontmatter accessor for the tool/integration
# registry under `.aid/connectors/` (feature-001 "Integration Store Placement and
# Schema"). NOT a reuse of read-setting.sh (KI-001): that script resolves only
# 2-level `section.key` dotted paths in `.aid/settings.yml` and cannot address
# one-field-per-descriptor YAML frontmatter. This script is the dedicated twin
# feature-001 requires; feature-005's connectors INDEX.md builder is its primary
# consumer.
#
# Two operations:
#   list                  -- one line per `.aid/connectors/*.md` descriptor stem
#                             (sorted), excluding `INDEX.md` and the non-descriptor
#                             `.gitignore` file / `.secrets/` directory.
#   read <stem> <field>   -- print the frontmatter value of <field> from
#                             `.aid/connectors/<stem>.md` to stdout.
#
# Usage:
#   connector-registry.sh list [--root <dir>]
#   connector-registry.sh read <stem> <field> [--root <dir>]
#
# Examples:
#   bash connector-registry.sh list
#   bash connector-registry.sh read github connection_type
#   bash connector-registry.sh read github endpoint --root .aid/connectors
#
# Exit codes:
#   0 -- success (list: zero or more stems printed; read: value printed)
#   1 -- read: descriptor not found, or field absent from its frontmatter
#   2 -- argument error (bad/missing operation, missing <stem>/<field>, unknown flag)
#
# Output:
#   stdout: the result (list: one stem per line; read: the raw value, with a
#           single pair of surrounding quotes stripped if present).
#   stderr: nothing on success; diagnostics on failure.
#
# Format: descriptor frontmatter is simple flat YAML (feature-001 SPEC "Connector
# descriptor schema"). This parses single-line scalar fields only -- the same
# dependency-free awk approach as build-kb-index.sh's `extract_field` -- and does
# NOT resolve list-valued fields (e.g. tags/audience); out of scope by design
# (YAGNI): the connectors INDEX.md builder (feature-005) only composes scalar
# columns (Connector/Type/Endpoint/Auth/Secret Ref/Summary).

set -euo pipefail

SCRIPT_NAME="connector-registry.sh"
DEFAULT_ROOT=".aid/connectors"
ROOT="$DEFAULT_ROOT"

usage() {
    cat <<'HELP'
connector-registry.sh -- list connector descriptor stems / read a frontmatter field.

Usage:
  connector-registry.sh list [--root <dir>]
  connector-registry.sh read <stem> <field> [--root <dir>]

Exit codes:
  0  success
  1  read: descriptor not found or field absent
  2  argument error
HELP
}

# ---------------------------------------------------------------------------
# Argument parsing -- collect flags (--root) anywhere, remaining args positional.
# ---------------------------------------------------------------------------
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            [[ $# -ge 2 ]] || { echo "${SCRIPT_NAME}: --root requires a value" >&2; exit 2; }
            ROOT="$2"; shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do POSITIONAL+=("$1"); shift; done
            ;;
        -*)
            echo "${SCRIPT_NAME}: unknown flag: $1" >&2
            exit 2
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL[@]} -eq 0 ]]; then
    echo "${SCRIPT_NAME}: missing operation (list|read)" >&2
    exit 2
fi

OP="${POSITIONAL[0]}"
STEM=""
FIELD=""

case "$OP" in
    list)
        if [[ ${#POSITIONAL[@]} -ne 1 ]]; then
            echo "${SCRIPT_NAME}: 'list' takes no positional arguments" >&2
            exit 2
        fi
        ;;
    read)
        if [[ ${#POSITIONAL[@]} -ne 3 ]]; then
            echo "${SCRIPT_NAME}: 'read' requires <stem> <field>" >&2
            exit 2
        fi
        STEM="${POSITIONAL[1]}"
        FIELD="${POSITIONAL[2]}"
        ;;
    *)
        echo "${SCRIPT_NAME}: unknown operation: $OP (expected list|read)" >&2
        exit 2
        ;;
esac

# ---------------------------------------------------------------------------
# read_field FILE FIELD -- single-line YAML scalar from the FIRST frontmatter
# block, with one pair of surrounding quotes stripped. Same first-block scoping
# as build-kb-index.sh's extract_field: a body-level thematic-break `---` never
# re-enters frontmatter mode. Quote-stripping mirrors read-setting.sh's lookup().
# ---------------------------------------------------------------------------
read_field() {
    local file="$1" field="$2"
    awk -v field="$field" '
        BEGIN { in_fm = 0 }
        /^---$/ { in_fm = !in_fm; if (NR > 1 && !in_fm) exit; next }
        in_fm && $0 ~ "^" field ":" {
            sub("^" field ":[[:space:]]*", "")
            sub("[[:space:]]+$", "")
            gsub("^[\"\047]|[\"\047]$", "")
            print
            exit
        }
    ' "$file"
}

# ---------------------------------------------------------------------------
# list
# ---------------------------------------------------------------------------
if [[ "$OP" == "list" ]]; then
    if [[ ! -d "$ROOT" ]]; then
        exit 0
    fi
    find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name 'INDEX.md' ! -name '.*' \
        | sed 's#.*/##; s/\.md$//' \
        | sort
    exit 0
fi

# ---------------------------------------------------------------------------
# read
# ---------------------------------------------------------------------------
DESCRIPTOR="${ROOT%/}/${STEM}.md"

if [[ ! -f "$DESCRIPTOR" ]]; then
    echo "${SCRIPT_NAME}: descriptor not found: $DESCRIPTOR" >&2
    exit 1
fi

VALUE="$(read_field "$DESCRIPTOR" "$FIELD")"

if [[ -z "$VALUE" ]]; then
    echo "${SCRIPT_NAME}: field '$FIELD' not found in $DESCRIPTOR" >&2
    exit 1
fi

echo "$VALUE"
exit 0
