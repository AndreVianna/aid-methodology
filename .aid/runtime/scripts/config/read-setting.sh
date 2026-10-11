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
#   # Probe mode (declared/undeclared availability, e.g. graph-source-enumeration's
#   # D4a ignore-list check) — direct dotted --path only, no --default consulted:
#   bash read-setting.sh --probe --path graph.ignore
#   # → "declared" when the section+key line is present (even with zero items),
#   #   "undeclared" when it is not. Warns on stderr, once per item, for any raw
#   #   list item containing a comma (still reported; split downstream by the
#   #   comma-joined transport).
#
# Exit codes:
#   0 — value found (printed to stdout) or default used; --probe: always
#       (declared/undeclared is the answer, not a failure)
#   1 — value missing AND no --default provided (not applicable to --probe)
#   2 — argument error / settings.yml unreadable / malformed YAML
#
# Output:
#   stdout: the resolved value (single line, no trailing newline beyond echo's default).
#           For list-valued keys, items are comma-joined. --probe: exactly
#           "declared" or "undeclared".
#   stderr: nothing on success; error messages on failure (always include the
#           absolute resolved path of the settings file for debuggability).
#           --probe: also a warning per raw list item containing a comma.
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
PROBE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skill)   SKILL="$2";   shift 2 ;;
        --key)     KEY="$2";     shift 2 ;;
        --path)    DPATH="$2";   shift 2 ;;
        --default) DEFAULT="$2"; HAS_DEFAULT=1; shift 2 ;;
        --file)    SETTINGS_FILE="$2"; shift 2 ;;
        --probe)   PROBE=1; shift ;;
        -h|--help)
            cat <<'HELP'
read-setting.sh — resolve a setting from .aid/settings.yml.

Modes:
  --skill X --key Y     # Resolves X.Y if present, else review.Y, else default
  --path A.B            # Direct dotted-path lookup, no override resolution
  --probe --path A.B    # declared/undeclared availability probe (no --default)

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

# --probe is additive over path mode only: it answers "is section.key declared",
# which is a question about a nested section+key line, not the flat top-level
# scheme --path also serves. A dotless --path or --skill combination is a usage
# error here rather than a silent no-op.
if [[ $PROBE -eq 1 ]]; then
    if [[ "$MODE" != "path" || "$DPATH" != *.* ]]; then
        echo "read-setting.sh: --probe requires a dotted --path A.B (section.key)" >&2
        exit 2
    fi
fi

# Resolve to absolute path before existence check + error reporting.
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
# abs_path is computed lazily at the two error sites below (not here) to avoid a
# realpath fork on every successful lookup — this is the most-invoked script in the repo.

# settings.yml missing → use default if provided, else exit 1. --probe never
# consults --default or the error path: a missing file declares nothing, which
# is "undeclared" by the same logic as an absent section, and the probe's own
# exit-0 contract (D4a) is unconditional on this branch.
if [[ ! -f "$SETTINGS_FILE" ]]; then
    if [[ $PROBE -eq 1 ]]; then
        echo "undeclared"
        exit 0
    fi
    if [[ $HAS_DEFAULT -eq 1 ]]; then
        echo "$DEFAULT"
        exit 0
    fi
    echo "read-setting.sh: settings file not found at $(abs_path "$SETTINGS_FILE") and no --default provided" >&2
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
    local file="$1" section="$2" key="$3" probe="${4:-}"
    # `|| true` so an awk that finds no match (returns 0 with empty output)
    # or a defensive nonzero (rare) doesn't trigger the script's `set -e`.
    awk -v section="$section" -v key="$key" -v probe="$probe" '
        # Enter the named top-level section when we see its bare line
        $0 ~ "^"section":[[:space:]]*$" { in_section=1; next }
        # Leave the section when we see another top-level key (column 0)
        in_section && /^[a-zA-Z]/ { in_section=0 }
        # Inside the section, look for an indented "key: value"
        in_section && $0 ~ "^[[:space:]]+"key":" {
            # Probe mode (--probe, D4a): the declaration hit IS this branch --
            # the same one lookup_list() enters on the identical regex -- so a
            # 4th-arg-less call (every existing caller) never reaches this line.
            if (probe == "1") { print "1"; exit }
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
    local file="$1" section="$2" key="$3" mode="${4:-}"
    awk -v section="$section" -v key="$key" -v mode="$mode" '
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
            # D4a comma warning (--probe warn mode only): the transport joins
            # items with a comma, so a raw item that already contains one is
            # indistinguishable downstream from two items. Warn once here, on
            # the raw item, while it is still a separate scalar -- the item is
            # still accumulated into items below (split and reported, never
            # silently dropped). Existing 3-arg callers never set mode=="warn".
            if (mode == "warn" && index(item, ",") > 0) {
                print "read-setting.sh: warning: " section "." key " item \"" item "\" contains a comma; it will be split into separate patterns" > "/dev/stderr"
            }
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
# --probe (D4a): declared/undeclared availability, decided by the SAME
# lookup() branch the existing modes use to find a value -- not a second,
# parallel parser, so the probe and --path can never disagree about the same
# file. Runs only when --probe was passed (PROBE=1); every existing caller
# leaves PROBE at its default 0 and never reaches this block. Settings-file-
# missing is handled earlier (undeclared, exit 0) before this point, so
# $SETTINGS_FILE is guaranteed to exist here.
# ---------------------------------------------------------------------------
if [[ $PROBE -eq 1 ]]; then
    _probe_section="${DPATH%%.*}"
    _probe_key="${DPATH#*.}"
    if [[ -n "$(lookup "$SETTINGS_FILE" "$_probe_section" "$_probe_key" 1)" ]]; then
        # Declared: warn on stderr for any raw list item containing a comma
        # (D4a) -- decidable only here, before the comma-joined transport
        # collapses the distinction. A scalar-valued key has no list items to
        # warn about; lookup_list simply finds none and stays silent.
        lookup_list "$SETTINGS_FILE" "$_probe_section" "$_probe_key" "warn" >/dev/null
        echo "declared"
    else
        echo "undeclared"
    fi
    exit 0
fi

# ---------------------------------------------------------------------------
# Top-level scalar lookup — reads a column-0 `key: value`. The flat settings
# schema keeps name/description/type/minimum_grade at the top level (no longer
# nested under project:/review:). Returns empty if absent, or if the value is an
# inline list / block marker.
# ---------------------------------------------------------------------------
lookup_toplevel() {
    local file="$1" key="$2"
    awk -v key="$key" '
        $0 ~ "^"key":([[:space:]]|$)" {
            sub("^"key":[[:space:]]*", "")
            sub("[[:space:]]+#.*$", "")
            if ($0 ~ /^\[.*\]$/ || $0 == "") { exit }
            gsub("^[\"\047]|[\"\047]$", "")
            print
            exit
        }
    ' "$file" || true
}

# ---------------------------------------------------------------------------
# Skill mode: per-skill override; then global (flat top-level <key>, legacy
# review.<key> fallback); then --default
# ---------------------------------------------------------------------------
if [[ "$MODE" == "skill" ]]; then
    # 1. Per-skill override
    val=$(lookup "$SETTINGS_FILE" "$SKILL" "$KEY")
    if [[ -n "$val" ]]; then
        echo "$val"
        exit 0
    fi
    # 2. Global default: flat top-level <key> (e.g. minimum_grade), with a
    #    legacy nested fallback to review.<key> for not-yet-migrated projects.
    val=$(lookup_toplevel "$SETTINGS_FILE" "$KEY")
    if [[ -z "$val" ]]; then
        val=$(lookup "$SETTINGS_FILE" "review" "$KEY")
    fi
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
    if [[ "$DPATH" != *.* ]]; then
        # Dotless path -> flat top-level scalar (name/description/type/
        # minimum_grade), with a legacy nested fallback for the four keys that
        # used to live under project:/review: (backward compat for un-migrated
        # projects).
        val=$(lookup_toplevel "$SETTINGS_FILE" "$DPATH")
        if [[ -z "$val" ]]; then
            case "$DPATH" in
                name|description|type) val=$(lookup "$SETTINGS_FILE" "project" "$DPATH") ;;
                minimum_grade)         val=$(lookup "$SETTINGS_FILE" "review" "$DPATH") ;;
            esac
        fi
        if [[ -n "$val" ]]; then
            echo "$val"
            exit 0
        fi
        if [[ $HAS_DEFAULT -eq 1 ]]; then
            echo "$DEFAULT"
            exit 0
        fi
        echo "read-setting.sh: no value for $DPATH in $(abs_path "$SETTINGS_FILE") and no --default" >&2
        exit 1
    fi
    # Dotted path A.B -> nested section.key lookup (scalar, then list).
    section="${DPATH%%.*}"
    key="${DPATH#*.}"
    val=$(lookup "$SETTINGS_FILE" "$section" "$key")
    if [[ -z "$val" ]]; then
        val=$(lookup_list "$SETTINGS_FILE" "$section" "$key")
    fi
    # Legacy compatibility: a caller may still pass the pre-flatten dotted path
    # (project.name / review.minimum_grade) against a now-flat file -> fall back
    # to the top-level scalar.
    if [[ -z "$val" ]]; then
        case "$DPATH" in
            project.name)         val=$(lookup_toplevel "$SETTINGS_FILE" "name") ;;
            project.description)  val=$(lookup_toplevel "$SETTINGS_FILE" "description") ;;
            project.type)         val=$(lookup_toplevel "$SETTINGS_FILE" "type") ;;
            review.minimum_grade) val=$(lookup_toplevel "$SETTINGS_FILE" "minimum_grade") ;;
            # heartbeat_interval promoted to top level (traceability: wrapper removed)
            traceability.heartbeat_interval) val=$(lookup_toplevel "$SETTINGS_FILE" "heartbeat_interval") ;;
            # doc_set / term_exclusions moved from discovery: into knowledge:
            discovery.doc_set)         val=$(lookup_list "$SETTINGS_FILE" "knowledge" "doc_set") ;;
            discovery.term_exclusions) val=$(lookup_list "$SETTINGS_FILE" "knowledge" "term_exclusions") ;;
        esac
    fi
    if [[ -n "$val" ]]; then
        echo "$val"
        exit 0
    fi
    if [[ $HAS_DEFAULT -eq 1 ]]; then
        echo "$DEFAULT"
        exit 0
    fi
    echo "read-setting.sh: no value for $DPATH in $(abs_path "$SETTINGS_FILE") and no --default" >&2
    exit 1
fi
