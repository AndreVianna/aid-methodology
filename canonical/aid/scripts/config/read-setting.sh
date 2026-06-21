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
#   # Path mode against a list-valued key (returns comma-joined items):
#   bash read-setting.sh --path tools.installed --default claude-code
#   # → "claude-code,codex" when the file has tools.installed: [claude-code, codex]
#
# Exit codes:
#   0 — value found (printed to stdout) or default used
#   1 — value missing AND no --default provided
#   2 — argument error / settings.yml unreadable / malformed YAML
#
# Output:
#   stdout: the resolved value (single line, no trailing newline beyond echo's default).
#           For list-valued keys, items are comma-joined.
#   stderr: nothing on success; error messages on failure (always include the
#           absolute resolved path of the settings file for debuggability).
#
# Format: settings.yml is YAML 1.2. This script does NOT require a YAML parser
# binary (yq, python) — uses awk for the simple flat-section dotted-path
# lookups that AID actually stores, plus list-valued top-level keys
# (e.g., tools.installed: [a, b] or block-list form). For nested or complex
# YAML, install yq and the script will defer to it.

set -euo pipefail

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

# Resolve to absolute path before existence check + error reporting (F20).
# realpath/readlink coverage varies across BSD/GNU/macOS; use a portable fallback.
abs_path() {
    local p="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath -m "$p" 2>/dev/null || printf '%s/%s' "$(pwd)" "$p"
    else
        # Strip leading ./ for cleaner output; prepend $PWD if relative
        case "$p" in
            /*) printf '%s' "$p" ;;
            *)  printf '%s/%s' "$(pwd)" "${p#./}" ;;
        esac
    fi
}
SETTINGS_FILE_ABS=$(abs_path "$SETTINGS_FILE")

# settings.yml missing → use default if provided, else exit 1
if [[ ! -f "$SETTINGS_FILE" ]]; then
    if [[ $HAS_DEFAULT -eq 1 ]]; then
        echo "$DEFAULT"
        exit 0
    fi
    echo "read-setting.sh: settings file not found at $SETTINGS_FILE_ABS and no --default provided" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# YAML lookup helper — extracts the value of a dotted path from a simple YAML
# document. Handles three cases:
#   1) Top-level scalar key:            review.minimum_grade
#   2) Per-skill override (top-level):  discover.minimum_grade
#   3) List-valued key, either inline   tools.installed: [claude-code, codex]
#      or block form                    tools:
#                                         installed:
#                                           - claude-code
#                                           - codex
#      Returns items comma-joined: "claude-code,codex".
#
# Top-level shape uses the flat-section layout:
#   <section>:
#     <key>: <value>
#
# Sub-shell awk return codes are checked: on awk failure (e.g., malformed
# YAML that the simple parser can't handle), the lookup returns empty AND
# the caller falls back to --default or exit 1 / 2. set -e is active so
# unhandled failures abort.
# ---------------------------------------------------------------------------
lookup() {
    local file="$1" section="$2" key="$3"
    # `|| true` so an awk that finds no match (returns 0 with empty output)
    # or a defensive nonzero (rare) doesn't trigger the script's `set -e`.
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
            # If the value looks like an inline list ([...]) or empty (block-form
            # marker), return empty so the list lookup runs as fallback.
            if ($0 ~ /^\[.*\]$/ || $0 == "") { exit }
            # Strip surrounding quotes if any
            gsub("^[\"\047]|[\"\047]$", "")
            print
            exit
        }
    ' "$file" || true
}

# ---------------------------------------------------------------------------
# List lookup — handles both inline `[a, b]` and block `- a\n- b` forms
# for a single dotted path (section.key). Returns items comma-joined; empty
# if the key is not present or has no items.
# ---------------------------------------------------------------------------
lookup_list() {
    local file="$1" section="$2" key="$3"
    awk -v section="$section" -v key="$key" '
        # Enter section
        $0 ~ "^"section":[[:space:]]*$" { in_section=1; next }
        in_section && /^[a-zA-Z]/ { in_section=0; in_list=0 }
        in_section && $0 ~ "^[[:space:]]+"key":" {
            line = $0
            sub("^[[:space:]]+"key":[[:space:]]*", "", line)
            sub("[[:space:]]+#.*$", "", line)
            # Inline list form: [a, b, c]
            if (match(line, /^\[.*\]$/)) {
                inner = substr(line, 2, length(line) - 2)
                gsub(/[[:space:]]+/, "", inner)
                gsub(/["\047]/, "", inner)
                print inner
                exit
            }
            # Block list form: the next lines begin with "  - item"
            if (line == "") {
                in_list=1
                next
            }
        }
        # Block-form list items (indented "- item")
        in_list && /^[[:space:]]+-[[:space:]]/ {
            item = $0
            sub("^[[:space:]]+-[[:space:]]+", "", item)
            sub("[[:space:]]+#.*$", "", item)
            gsub(/["\047]/, "", item)
            items = items (items == "" ? "" : ",") item
            next
        }
        # Anything else terminates the list
        in_list && /^[[:space:]]*$/ { next }
        in_list { in_list=0 }
        END { if (items != "") print items }
    ' "$file" || true
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
# Path mode: direct dotted-path lookup, e.g. execution.max_parallel_tasks.
# Tries scalar lookup first; falls back to list lookup (inline or block form).
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
    # Fall back to list lookup (handles tools.installed and similar)
    val=$(lookup_list "$SETTINGS_FILE" "$section" "$key")
    if [[ -n "$val" ]]; then
        echo "$val"
        exit 0
    fi
    if [[ $HAS_DEFAULT -eq 1 ]]; then
        echo "$DEFAULT"
        exit 0
    fi
    echo "read-setting.sh: no value for $DPATH in $SETTINGS_FILE_ABS and no --default" >&2
    exit 1
fi
