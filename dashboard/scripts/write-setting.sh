#!/usr/bin/env bash
# write-setting.sh -- write a single scalar into .aid/settings.yml (scriptable counterpart
# to read-setting.sh; feature-001-write-infrastructure, work-017 task-003).
#
# Dispatched by the dashboard server's `settings.set` op so a dashboard edit and a manual
# .aid/settings.yml edit produce the same on-disk shape. Also directly scriptable.
#
# Usage:
#   write-setting.sh --path <section.key> --value <V> [--file <settings.yml>]
#
# Closed --path allowlist (the dashboard's current write surface only -- NOT every key
# settings.yml may hold; any other --path -> exit 4):
#   project.name
#   project.description
#   review.minimum_grade   -- validated ^[A-F][+-]?$ (same alphabet as writeback-state.sh's
#                              --gate-field Grade / grade.sh's own output alphabet)
#
# --value constraints (KI-001: keeps the written value inside the strip-only alphabet every
# settings reader -- server.py's _read_settings, server.mjs's readSettings, the reader-twin
# parseProjectName, and this script's own sibling read-setting.sh -- round-trips identically):
# a --value containing a literal newline, an embedded double-quote ("), or a backslash (\)
# is rejected -> exit 4.
#
# Write model: a SURGICAL flat-section rewrite -- mirrors read-setting.sh's `lookup` model in
# reverse. The target `<section>:` top-level mapping is located; its `  <key>: <value>` child
# line is replaced in place if present, appended at the end of the section if the section
# exists but the key does not, or a fresh `<section>:` / `  <key>: <value>` pair is appended at
# EOF if the section itself is entirely absent. Every OTHER line in the file is reproduced
# byte-for-byte. The write is atomic (temp-file + mv).
#
# Exit codes (conforms to the dashboard server's DEFAULT_MAP -- see
# feature-001-write-infrastructure SPEC.md Sec API Contracts; the lock-contention exit code
# (writeback-state.sh's -> HTTP 409 busy) is RESERVED and MUST NEVER be emitted here):
#   0 -- value written
#   4 -- invalid --path (not in the allowlist), invalid review.minimum_grade format, or
#        invalid --value (KI-001 charset)                                    -> 422 invalid-value
#   5 -- missing/malformed required arg (--path/--value/--file given with no value,
#        unknown flag, or neither --path nor --value supplied)               -> 422 invalid-value
#   3 -- IO or unverifiable-write failure (settings.yml missing/unreadable, write
#        produced no output, or sanity check failed)                        -> 500 write-failed
#
# Format: settings.yml is YAML 1.2, flat two-level sections only (same assumption
# read-setting.sh makes). bash-only (no external YAML parser dependency).

set -euo pipefail

SETTINGS_FILE=".aid/settings.yml"
DPATH=""
VALUE=""
HAS_VALUE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            [[ $# -lt 2 ]] && { echo "write-setting.sh: --path requires a value" >&2; exit 5; }
            DPATH="$2"; shift 2
            ;;
        --value)
            [[ $# -lt 2 ]] && { echo "write-setting.sh: --value requires a value" >&2; exit 5; }
            VALUE="$2"; HAS_VALUE=1; shift 2
            ;;
        --file)
            [[ $# -lt 2 ]] && { echo "write-setting.sh: --file requires a value" >&2; exit 5; }
            SETTINGS_FILE="$2"; shift 2
            ;;
        -h|--help)
            cat <<'HELP'
write-setting.sh -- write a scalar into .aid/settings.yml.

Usage:
  write-setting.sh --path <section.key> --value <V> [--file <settings.yml>]

Allowed --path: project.name | project.description | review.minimum_grade
HELP
            exit 0
            ;;
        *)
            echo "write-setting.sh: unknown flag: $1" >&2
            exit 5
            ;;
    esac
done

if [[ -z "$DPATH" || "$HAS_VALUE" -eq 0 ]]; then
    echo "write-setting.sh: requires --path A.B and --value V" >&2
    exit 5
fi

# Closed allowlist. Rejection here is an invalid-VALUE-class error (exit 4), not an argument
# error: --path is well-formed, it is simply not one the dashboard may write.
case "$DPATH" in
    project.name)         SECTION="project"; KEY="name";          TOPKEY="name" ;;
    project.description)  SECTION="project"; KEY="description";   TOPKEY="description" ;;
    review.minimum_grade) SECTION="review";  KEY="minimum_grade"; TOPKEY="minimum_grade" ;;
    *)
        echo "write-setting.sh: --path '$DPATH' is not writable; allowed: project.name, project.description, review.minimum_grade" >&2
        exit 4
        ;;
esac

# review.minimum_grade: closed grade alphabet.
if [[ "$DPATH" == "review.minimum_grade" ]]; then
    if ! [[ "$VALUE" =~ ^[A-F][+-]?$ ]]; then
        echo "write-setting.sh: invalid review.minimum_grade value '$VALUE'; must match ^[A-F][+-]?\$ (e.g. A, A-, B+, F)" >&2
        exit 4
    fi
fi

# KI-001 charset guard (applies to every allowed --path).
if [[ "$VALUE" == *$'\n'* ]]; then
    echo "write-setting.sh: --value cannot contain a newline" >&2
    exit 4
fi
if [[ "$VALUE" == *'"'* ]]; then
    echo 'write-setting.sh: --value cannot contain a double-quote (")' >&2
    exit 4
fi
if [[ "$VALUE" == *'\'* ]]; then
    echo 'write-setting.sh: --value cannot contain a backslash (\)' >&2
    exit 4
fi

if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "write-setting.sh: settings file not found at $SETTINGS_FILE" >&2
    exit 3
fi

# ---------------------------------------------------------------------------
# Schema-aware surgical rewrite. The flat schema keeps these keys at the TOP
# level (name/description/minimum_grade); the legacy schema nested them under
# project:/review:. Write to whichever shape the file already uses -- matching
# where the readers look (they prefer the nested block when one is present):
#   - legacy nested `<section>:` block present -> replace/append its `  <key>:` child.
#   - otherwise (flat file)                    -> replace/append the top-level `<key>:`.
# Every other line is reproduced byte-for-byte; the write is atomic (temp + mv).
# ---------------------------------------------------------------------------
if grep -qE "^${SECTION}:[[:space:]]*$" "$SETTINGS_FILE"; then
    WRITE_MODE="nested"
else
    WRITE_MODE="flat"
fi

NESTED_WRITE_AWK='
    BEGIN { in_section = 0; section_seen = 0; done = 0 }
    $0 ~ "^" section ":[[:space:]]*$" { in_section = 1; section_seen = 1; print; next }
    in_section && /^[A-Za-z]/ { if (!done) { print "  " key ": " value; done = 1 } in_section = 0; print; next }
    in_section && $0 ~ "^[[:space:]]+" key ":" { print "  " key ": " value; done = 1; next }
    { print }
    END {
        if (in_section && !done) { print "  " key ": " value; done = 1 }
        if (!section_seen) { print section ":"; print "  " key ": " value }
    }
'
FLAT_WRITE_AWK='
    BEGIN { done = 0 }
    $0 ~ "^" key ":" { print key ": " value; done = 1; next }
    { print }
    END { if (!done) print key ": " value }
'

tmp=$(mktemp)
if [[ "$WRITE_MODE" == "nested" ]]; then
    awk -v section="$SECTION" -v key="$KEY" -v value="$VALUE" "$NESTED_WRITE_AWK" "$SETTINGS_FILE" > "$tmp"
    SANITY_RE="^  ${KEY}:"
else
    awk -v key="$TOPKEY" -v value="$VALUE" "$FLAT_WRITE_AWK" "$SETTINGS_FILE" > "$tmp"
    SANITY_RE="^${TOPKEY}:"
fi

# A no-trailing-newline source file must not silently gain one.
if [[ -s "$SETTINGS_FILE" ]] && [[ "$(tail -c1 "$SETTINGS_FILE" | wc -l)" -eq 0 ]] && [[ -s "$tmp" ]]; then
    printf '%s' "$(cat "$tmp")" > "${tmp}.trimmed"
    mv "${tmp}.trimmed" "$tmp"
fi

if [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    echo "write-setting.sh: write produced empty output; $SETTINGS_FILE preserved" >&2
    exit 3
fi

if ! grep -qE "$SANITY_RE" "$tmp"; then
    rm -f "$tmp"
    echo "write-setting.sh: sanity check failed: key '${KEY}' not found in output; $SETTINGS_FILE preserved" >&2
    exit 3
fi

mv "$tmp" "$SETTINGS_FILE"
echo "OK: $SETTINGS_FILE updated -- ${DPATH} set to '${VALUE}'"
