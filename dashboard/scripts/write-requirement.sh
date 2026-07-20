#!/usr/bin/env bash
# write-requirement.sh -- surgically rewrite the `- **Name:**` / `- **Description:**` bullet
# in a work's REQUIREMENTS.md (Q3 resolution; feature-001-write-infrastructure, work-017
# task-003).
#
# Dispatched by the dashboard server's `pipeline.rename` op. The bullet this script writes is
# the SAME line dashboard/reader/parsers.py's `parse_requirements_md` (`_re_name`/`_re_desc`,
# ~line 664) and reader.mjs's `parseRequirementsMd` (`RE_NAME`/`RE_DESC`, ~line 1695) already
# parse into `WorkModel.title` / description -- so a dashboard rename is byte-indistinguishable
# from a hand-edit of REQUIREMENTS.md.
#
# Usage:
#   write-requirement.sh --field <Name|Description> --value <V>
#
# Target file: $AID_REQUIREMENTS_FILE if set, else <cwd>/REQUIREMENTS.md.
#
# --value constraints: a --value containing a literal newline or a pipe (|) is rejected ->
# exit 4 (the same line/row-corruption guard class writeback-state.sh's mode_field applies).
#
# Write model: a SURGICAL single-bullet rewrite. The first line matching
# `^\s*-\s*\*\*<Field>:\*\*` (case-insensitive, matching the reader regex) is replaced whole
# with `- **<Field>:** <value>`. If no such bullet exists yet, one is inserted directly under
# the leading `# Requirements` heading. Every OTHER line is reproduced byte-for-byte. The write
# is atomic (temp-file + mv). Non-destructive: this script touches ONLY that single bullet
# line -- it never renames/moves the work folder, never touches the git branch, and never
# touches the worktree (AC5).
#
# Exit codes (conforms to the dashboard server's DEFAULT_MAP -- see
# feature-001-write-infrastructure SPEC.md Sec API Contracts; the lock-contention exit code
# (writeback-state.sh's -> HTTP 409 busy) is RESERVED and MUST NEVER be emitted here):
#   0 -- value written
#   4 -- invalid --field (not Name/Description), or invalid --value (newline / pipe)  -> 422 invalid-value
#   5 -- missing/malformed required arg (--field/--value given with no value, unknown
#        flag, --field or --value omitted entirely, or no bullet/heading anchor to
#        place the value -- no valid write mode)                                     -> 422 invalid-value
#   3 -- IO or unverifiable-write failure (REQUIREMENTS.md missing/unreadable, write
#        produced no output, or sanity check failed)                                 -> 500 write-failed
#
# bash-only (no external dependency).

set -euo pipefail

REQ_FILE="${AID_REQUIREMENTS_FILE:-REQUIREMENTS.md}"
FIELD=""
VALUE=""
HAS_VALUE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --field)
            [[ $# -lt 2 ]] && { echo "write-requirement.sh: --field requires a value" >&2; exit 5; }
            FIELD="$2"; shift 2
            ;;
        --value)
            [[ $# -lt 2 ]] && { echo "write-requirement.sh: --value requires a value" >&2; exit 5; }
            VALUE="$2"; HAS_VALUE=1; shift 2
            ;;
        -h|--help)
            cat <<'HELP'
write-requirement.sh -- write the Name/Description bullet in REQUIREMENTS.md.

Usage:
  write-requirement.sh --field <Name|Description> --value <V>

Target file: $AID_REQUIREMENTS_FILE if set, else <cwd>/REQUIREMENTS.md.
HELP
            exit 0
            ;;
        *)
            echo "write-requirement.sh: unknown flag: $1" >&2
            exit 5
            ;;
    esac
done

if [[ -z "$FIELD" || "$HAS_VALUE" -eq 0 ]]; then
    echo "write-requirement.sh: requires --field <Name|Description> and --value V" >&2
    exit 5
fi

# Closed field allowlist (case-insensitive input; canonical output case is Title-case,
# matching both the reader regex's case-insensitive match and the template's own bullet
# casing).
case "${FIELD,,}" in
    name)        FIELD="Name" ;;
    description) FIELD="Description" ;;
    *)
        echo "write-requirement.sh: unknown --field '$FIELD'; allowed: Name, Description" >&2
        exit 4
        ;;
esac

if [[ "$VALUE" == *$'\n'* ]]; then
    echo "write-requirement.sh: --value cannot contain a newline" >&2
    exit 4
fi
if [[ "$VALUE" == *'|'* ]]; then
    echo "write-requirement.sh: --value cannot contain '|' (reserved column separator elsewhere in this artifact set)" >&2
    exit 4
fi

if [[ ! -f "$REQ_FILE" ]]; then
    echo "write-requirement.sh: requirements file not found at $REQ_FILE" >&2
    exit 3
fi

# Decide the write mode BEFORE touching the file: replace the existing bullet if present,
# else insert a new one under the leading heading -- fail if neither anchor exists.
BULLET_RE="^[[:space:]]*-[[:space:]]*\\*\\*${FIELD}:\\*\\*"
HEADING_RE='^#[[:space:]]+[Rr]equirements[[:space:]]*$'

if grep -qiE "$BULLET_RE" "$REQ_FILE"; then
    MODE="replace"
elif grep -qE "$HEADING_RE" "$REQ_FILE"; then
    MODE="insert"
else
    echo "write-requirement.sh: no '${FIELD}' bullet and no '# Requirements' heading found in $REQ_FILE; no valid write mode -- cannot place it" >&2
    exit 5
fi

tmp=$(mktemp)

# The value is read from ENVIRON (not an awk `-v` assignment) because awk's
# `-v var=value` re-processes C-style escape sequences in `value` -- a
# `foo\tbar` assigned this way silently becomes "foo<TAB>bar", corrupting the
# bullet with a literal control character the caller never wrote (delivery-001
# gate finding; same bug class writeback-state.sh's wb_set_frontmatter already
# fixed via WB_FM_RAW_VALUE -- see its doc comment above). ENVIRON values are
# NOT escape-reprocessed, so the value arrives byte-for-byte.
if [[ "$MODE" == "replace" ]]; then
    AID_WR_RAW_VALUE="$VALUE" awk -v field="$FIELD" '
        BEGIN { done = 0; patt = "^[[:space:]]*-[[:space:]]*\\*\\*" tolower(field) ":\\*\\*"; value = ENVIRON["AID_WR_RAW_VALUE"] }
        !done && tolower($0) ~ patt {
            print "- **" field ":** " value
            done = 1
            next
        }
        { print }
    ' "$REQ_FILE" > "$tmp"
else
    AID_WR_RAW_VALUE="$VALUE" awk -v field="$FIELD" '
        BEGIN { done = 0; value = ENVIRON["AID_WR_RAW_VALUE"] }
        !done && $0 ~ /^#[[:space:]]+[Rr]equirements[[:space:]]*$/ {
            print
            print "- **" field ":** " value
            done = 1
            next
        }
        { print }
    ' "$REQ_FILE" > "$tmp"
fi

# A no-trailing-newline source file must not silently gain one.
if [[ -s "$REQ_FILE" ]] && [[ "$(tail -c1 "$REQ_FILE" | wc -l)" -eq 0 ]] && [[ -s "$tmp" ]]; then
    printf '%s' "$(cat "$tmp")" > "${tmp}.trimmed"
    mv "${tmp}.trimmed" "$tmp"
fi

if [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    echo "write-requirement.sh: write produced empty output; $REQ_FILE preserved" >&2
    exit 3
fi

if ! grep -qE "^-[[:space:]]*\\*\\*${FIELD}:\\*\\*" "$tmp"; then
    rm -f "$tmp"
    echo "write-requirement.sh: sanity check failed: '${FIELD}' bullet not found in output; $REQ_FILE preserved" >&2
    exit 3
fi

mv "$tmp" "$REQ_FILE"
echo "OK: $REQ_FILE updated -- ${FIELD} set to '${VALUE}'"
