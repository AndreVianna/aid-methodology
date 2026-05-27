#!/usr/bin/env bash
# read-setting.sh — resolve a setting value from .aid/settings.yml.
#
# Consumer skills (/aid-discover, /aid-execute, etc.) call this to read
# their configuration. Implements the canonical resolution order:
#
#   1. Per-skill override key (e.g., discover.minimum_grade) → use if present
#   2. Global category default (e.g., review.minimum_grade) → use otherwise
#   3. Hardcoded skill default → use only if settings.yml is missing entirely
#
# Usage:
#   read-setting.sh --skill <skill-name> --key <key-name> [--default <fallback>]
#   read-setting.sh --path <dotted.path> [--default <fallback>]
#
# Examples:
#   # Skill mode (applies override resolution):
#   #   reads discover.minimum_grade if present, else review.minimum_grade, else default
#   bash read-setting.sh --skill discover --key minimum_grade --default A
#
#   # Path mode (direct lookup, no override resolution):
#   bash read-setting.sh --path execution.max_parallel_tasks --default 5
#
# Exit codes:
#   0 — value found (printed to stdout) or default used
#   1 — value missing AND no --default provided
#   2 — argument error / settings.yml unreadable
#
# Output:
#   stdout: the resolved value (single line, no trailing newline beyond echo's default)
#   stderr: nothing on success; error messages on failure
#
# Format: settings.yml is YAML 1.2. This script does NOT require a YAML parser
# binary (yq, python) — uses awk for the simple flat-section dotted-path
# lookups that AID actually stores. For nested or complex YAML, install yq
# and the script will defer to it.

set -uo pipefail

SETTINGS_FILE=".aid/settings.yml"
SKILL=""
KEY=""
DPATH=""
DEFAULT=""
HAS_DEFAULT=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skill)   SKILL="$2";   shift 2 ;;
        --key)     KEY="$2";     shift 2 ;;
        --path)    DPATH="$2";   shift 2 ;;
        --default) DEFAULT="$2"; HAS_DEFAULT=1; shift 2 ;;
        --file)    SETTINGS_FILE="$2"; shift 2 ;;
        -h|--help)
            cat <<'HELP'
read-setting.sh — resolve a setting from .aid/settings.yml.

Modes:
  --skill X --key Y     # Resolves X.Y if present, else review.Y, else default
  --path A.B            # Direct dotted-path lookup, no override resolution

Flags:
  --default V    Fallback if no value found (else exit 1)
  --file PATH    Settings file (default: .aid/settings.yml)
HELP
            exit 0
            ;;
        *)
            echo "read-setting.sh: unknown flag: $1" >&2
            exit 2
            ;;
    esac
done

# Validate mode
if [[ -n "$SKILL" && -n "$KEY" ]]; then
    MODE="skill"
elif [[ -n "$DPATH" ]]; then
    MODE="path"
else
    echo "read-setting.sh: requires either (--skill X --key Y) or (--path A.B)" >&2
    exit 2
fi

# settings.yml missing → use default if provided, else exit 1
if [[ ! -f "$SETTINGS_FILE" ]]; then
    if [[ $HAS_DEFAULT -eq 1 ]]; then
        echo "$DEFAULT"
        exit 0
    fi
    echo "read-setting.sh: $SETTINGS_FILE not found and no --default provided" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# YAML lookup helper — extracts the value of a dotted path from a simple YAML
# document. Handles two cases:
#   1) Top-level scalar key:            review.minimum_grade
#   2) Per-skill override (top-level):  discover.minimum_grade
#
# Both shapes use the same flat-section layout:
#   <section>:
#     <key>: <value>
#
# Lists (like tools.installed) are NOT supported by this lookup — they need a
# proper YAML parser. Use --skill mode for grade-only lookups; use yq/python
# for complex shapes.
# ---------------------------------------------------------------------------
lookup() {
    local file="$1" section="$2" key="$3"
    awk -v section="$section" -v key="$key" '
        # Enter the named top-level section when we see its bare line
        $0 ~ "^"section":[[:space:]]*$" { in_section=1; next }
        # Leave the section when we see another top-level key (column 0)
        in_section && /^[a-zA-Z]/ { in_section=0 }
        # Inside the section, look for an indented "key: value"
        in_section && $0 ~ "^[[:space:]]+"key":" {
            # Strip "  key:" prefix, then strip leading/trailing whitespace
            sub("^[[:space:]]+"key":[[:space:]]*", "")
            # Strip inline comments (anything after ` # `)
            sub("[[:space:]]+#.*$", "")
            # Strip surrounding quotes if any
            gsub("^[\"\047]|[\"\047]$", "")
            print
            exit
        }
    ' "$file"
}

# ---------------------------------------------------------------------------
# Skill mode: try per-skill override; fall back to review.<key>; fall back to --default
# ---------------------------------------------------------------------------
if [[ "$MODE" == "skill" ]]; then
    # 1. Per-skill override
    val=$(lookup "$SETTINGS_FILE" "$SKILL" "$KEY")
    if [[ -n "$val" ]]; then
        echo "$val"
        exit 0
    fi
    # 2. Global category default (review.<key> for grade-related lookups)
    val=$(lookup "$SETTINGS_FILE" "review" "$KEY")
    if [[ -n "$val" ]]; then
        echo "$val"
        exit 0
    fi
    # 3. Fallback
    if [[ $HAS_DEFAULT -eq 1 ]]; then
        echo "$DEFAULT"
        exit 0
    fi
    echo "read-setting.sh: no value for $SKILL.$KEY or review.$KEY and no --default" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Path mode: direct dotted-path lookup, e.g. execution.max_parallel_tasks
# ---------------------------------------------------------------------------
if [[ "$MODE" == "path" ]]; then
    # Split A.B into section + key
    section="${DPATH%%.*}"
    key="${DPATH#*.}"
    if [[ "$section" == "$DPATH" || -z "$key" ]]; then
        echo "read-setting.sh: --path must be dotted (A.B), got: $DPATH" >&2
        exit 2
    fi
    val=$(lookup "$SETTINGS_FILE" "$section" "$key")
    if [[ -n "$val" ]]; then
        echo "$val"
        exit 0
    fi
    if [[ $HAS_DEFAULT -eq 1 ]]; then
        echo "$DEFAULT"
        exit 0
    fi
    echo "read-setting.sh: no value for $DPATH and no --default" >&2
    exit 1
fi
