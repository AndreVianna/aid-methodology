#!/usr/bin/env bash
# write-external-source.sh -- atomic single-entry writer for the `.aid/knowledge/`
# external-sources registry (feature-010-external-sources-list, work-017 task-020). A
# scriptable sibling of feature-001's write-setting.sh / write-requirement.sh (and of
# .claude/aid/scripts/config/read-setting.sh). Bash-only (the dashboard already requires
# bash); lives under dashboard/scripts/ only -- there is no CLI/skill counterpart (unlike
# write-connector.sh's canonical/aid/scripts/ + profiles/ twin), so it is NOT
# run_generator-rendered, matching write-setting.sh / write-requirement.sh.
#
# Usage:
#   write-external-source.sh --op <add|remove> --value <url|path> [--file <external-sources.md>]
#
# --file defaults to .aid/knowledge/external-sources.md (repo-relative to $PWD).
#
# Authoritative target: the frontmatter `sources:` YAML list is the machine-readable
# registry (the one KB template where `sources:` holds external URLs/paths, not
# repo-relative cites). The `## Sources` BODY is maintained only as a minimal managed
# bullet mirror bounded by a stable HTML-comment marker pair -- this script NEVER
# synthesizes the rich `| Path | Type | Accessible | Key Content |` table (those columns
# need semantic knowledge the LLM-free server cannot produce -- discover-authoritative /
# OQ-P4). Per work known-issues.md KI-005 / STATE.md Q6: external-sources.md is
# DISCOVERY-OWNED (aid-discover's Scout is the authoritative writer and may wholesale-
# rewrite the frontmatter on its next pass); this script is a SUBORDINATE, atomic
# single-entry maintainer only -- it edits exactly one `sources:` entry per invocation
# and never rewrites the whole file.
#
# --op add (idempotent):
#   If --value is already present in the sources: list -> exit 0, no-op, NO write at all.
#   Else insert a `  - <value>` item IMMEDIATELY under the `sources:` key line as a
#   CONTIGUOUS block (the only form dashboard/reader/parsers.py's parse_doc_frontmatter() /
#   reader.mjs's parseDocFrontmatter() twin consumes -- a comment or blank line between
#   `sources:` and its items ends the block, per that parser's own block-continuation
#   regex). If the existing block held only the discovery placeholder `- (none)` (optionally
#   preceded by a comment line), it is dropped. Every item is re-emitted as a clean
#   `  - <item>` line with NO inline `# comment` (the parser does not strip trailing inline
#   comments from a block item). Also adds a `- <value>` bullet to the `## Sources` body
#   managed-mirror list (see below).
#
# --op remove:
#   Removes every matching `  - <value>` frontmatter item (and its `## Sources` body
#   mirror bullet). If the real list empties, writes the lint-clean empty form
#   `sources: []` and restores the canonical "No external documentation..." paragraph in
#   the body (when the body held only the managed mirror / was otherwise empty). If
#   --value is not present in the list -> exit 1 (-> 404 not-found; an edge/racing case,
#   since the dashboard UI only offers Remove for listed entries).
#
# ## Sources body handling -- minimal managed mirror:
#   A simple `- <entry>` bullet list bounded by the stable marker pair
#   `<!-- managed:external-sources -->` / `<!-- /managed:external-sources -->`. The FIRST
#   add replaces the "No external documentation was provided..." placeholder paragraph (or
#   any otherwise-blank section) with the marked list; removing the last entry restores
#   that paragraph. If a hand-authored table (or any other non-placeholder content) already
#   occupies the section, the managed block is inserted/updated adjacent to it (above,
#   separated by a blank line) WITHOUT rewriting those human rows -- the body is never
#   machine-read, so this is cosmetic-truthfulness only.
#
# Value validation -- mirrors canonical/aid/scripts/kb/lint-frontmatter.sh's
# sources_entry_shape() (line ~270): a URL (`^https?://`) OR a whitespace-free path/glob
# (`^[^[:space:]]+$`). This script additionally rejects any embedded `|` (a stricter,
# writer-only guard -- feature-010 SPEC Security Specs -- since a path/glob value is
# whitespace-free by definition and would otherwise pass the lint shape even with a `|`).
# An empty --value, or one containing whitespace/newline/`|`, is rejected. Any value this
# script accepts keeps lint-frontmatter.sh green.
#
# Atomicity & preservation: surgical edit via temp-file (created alongside the target, same
# filesystem) + `mv`; every non-target line is byte-preserved; the frontmatter block
# boundary is the leading `---`...`---` fence pair. No lock is used (single-file,
# single-user; correctness does not require one -- feature-010 SPEC).
#
# Exit codes -- feature-001's canonical OP_TABLE exit->HTTP map (the writeback-state.sh
# alphabet; NOT write-setting.sh's / read-setting.sh's LOCAL alphabet, which assigns exit
# 2 to arg/IO rather than lock contention):
#   0 -- ok
#   1 -- remove target absent (value not found in sources:)      -> 404 not-found
#   2 -- lock contention (RESERVED; never emitted -- no lock used by this script)
#                                                                  -> 409 busy
#   3 -- IO / write error (file missing, malformed KB doc, unverifiable write)
#                                                                  -> 500 write-failed
#   4 -- invalid value (bad --op, bad/missing --value, missing required arg)
#                                                                  -> 422 invalid-value
#
# Output:
#   stdout: one `OK: ...` trace line on success.
#   stderr: diagnostics only.

set -euo pipefail

SCRIPT_NAME="write-external-source.sh"
FILE=".aid/knowledge/external-sources.md"
OP=""
VALUE=""
HAS_OP=0
HAS_VALUE=0

MARK_START='<!-- managed:external-sources -->'
MARK_END='<!-- /managed:external-sources -->'
PLACEHOLDER_TEXT='No external documentation was provided during discovery. All knowledge was derived from repository content only. If external documentation becomes available, re-run discovery or add paths during Q&A.'

die() {
    echo "${SCRIPT_NAME}: $1" >&2
    exit "${2:-4}"
}

usage() {
    cat <<'HELP'
write-external-source.sh -- atomic single-entry add/remove for the frontmatter
sources: list (+ ## Sources body mirror) of a KB external-sources.md registry.

Usage:
  write-external-source.sh --op <add|remove> --value <url|path> [--file <external-sources.md>]

--file defaults to .aid/knowledge/external-sources.md

--value: a URL (^https?://) or a whitespace-free path/glob; rejects whitespace, newline, or '|'.

Exit codes (feature-001 canonical map -- never write-setting.sh's local alphabet):
  0  ok
  1  remove target not found                 -> 404 not-found
  2  lock contention (RESERVED; unused here)  -> 409 busy
  3  IO / write error                         -> 500 write-failed
  4  invalid --op / --value / missing arg     -> 422 invalid-value
HELP
}

# ---------------------------------------------------------------------------
# trim S -- strip leading/trailing whitespace (standard bash parameter-expansion idiom).
# ---------------------------------------------------------------------------
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# ---------------------------------------------------------------------------
# strip_item_quotes S -- strip one layer of surrounding double- or single-quotes
# (permissive bookkeeping only; this script never emits quoted values itself).
# ---------------------------------------------------------------------------
strip_item_quotes() {
    local s="$1"
    s="${s%\"}"; s="${s#\"}"
    s="${s%\'}"; s="${s#\'}"
    printf '%s' "$s"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --op)
            [[ $# -ge 2 ]] || die "--op requires a value" 4
            OP="$2"; HAS_OP=1; shift 2
            ;;
        --value)
            [[ $# -ge 2 ]] || die "--value requires a value" 4
            VALUE="$2"; HAS_VALUE=1; shift 2
            ;;
        --file)
            [[ $# -ge 2 ]] || die "--file requires a value" 4
            FILE="$2"; shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown flag: $1" 4
            ;;
    esac
done

[[ "$HAS_OP" -eq 1 ]] || die "--op is required" 4
[[ "$HAS_VALUE" -eq 1 ]] || die "--value is required" 4

case "$OP" in
    add|remove) ;;
    *) die "invalid --op '$OP' (expected add|remove)" 4 ;;
esac

# --- Value validation (sources_entry_shape() alphabet + the '|' guard) ---
if [[ -z "$VALUE" ]]; then
    die "--value must not be empty" 4
fi
if [[ "$VALUE" =~ [[:space:]] ]]; then
    die "--value '$VALUE' must not contain whitespace or a newline" 4
fi
if [[ "$VALUE" == *'|'* ]]; then
    die "--value '$VALUE' must not contain '|'" 4
fi
# Any non-empty, whitespace-free, pipe-free value is either a URL or a valid
# whitespace-free path/glob -- both branches of sources_entry_shape() accept it.

[[ -f "$FILE" ]] || die "file not found: $FILE" 3

# ---------------------------------------------------------------------------
# Load the file into an array of lines (trailing \n stripped per element by
# mapfile; a source file with no final newline is handled correctly too).
# ---------------------------------------------------------------------------
mapfile -t LINES < "$FILE"
N=${#LINES[@]}

# CRLF detection (defensive -- KB docs in this repo are LF-only, but a Windows
# checkout could produce CRLF). Strip any trailing \r from every loaded line so
# all downstream comparisons operate on clean content; re-added uniformly at
# write time.
HAS_CRLF=0
if [[ "${N}" -gt 0 && "${LINES[0]}" == *$'\r' ]]; then
    HAS_CRLF=1
fi
if [[ "$HAS_CRLF" -eq 1 ]]; then
    for ((_i = 0; _i < N; _i++)); do
        LINES[$_i]="${LINES[$_i]%$'\r'}"
    done
fi

# A no-trailing-newline source file must not silently gain one.
HAD_TRAILING_NL=1
if [[ -s "$FILE" ]] && [[ "$(tail -c1 "$FILE" | wc -l)" -eq 0 ]]; then
    HAD_TRAILING_NL=0
fi

[[ "${LINES[0]:-}" == "---" ]] || die "malformed KB doc: no opening frontmatter fence in $FILE" 3

FM_END=-1
for ((i = 1; i < N; i++)); do
    if [[ "${LINES[$i]}" == "---" ]]; then
        FM_END=$i
        break
    fi
done
[[ "$FM_END" -ge 0 ]] || die "malformed KB doc: no closing frontmatter fence in $FILE" 3

# ---------------------------------------------------------------------------
# Locate the sources: key within the frontmatter block and extract the REAL
# existing items (permissive scan -- unlike the reader's parse_doc_frontmatter,
# this scan looks past interstitial comments/blank lines so nothing pre-
# existing is silently lost; the (none) placeholder is filtered out here).
# SRC_BLOCK_END is the index (exclusive) of the first line NOT belonging to
# the sources: region -- either a new top-level frontmatter key or FM_END.
# ---------------------------------------------------------------------------
SRC_IDX=-1
SRC_BLOCK_END=-1
declare -a EXISTING_ITEMS=()

for ((i = 1; i < FM_END; i++)); do
    if [[ "${LINES[$i]}" =~ ^sources:(.*)$ ]]; then
        SRC_IDX=$i
        SRC_REST="${BASH_REMATCH[1]}"
        break
    fi
done

if [[ "$SRC_IDX" -ge 0 ]]; then
    rest_trimmed="$(trim "$SRC_REST")"
    if [[ "$rest_trimmed" == "[]" ]]; then
        # sources: [] -- explicit empty inline list, single line.
        SRC_BLOCK_END=$((SRC_IDX + 1))
    elif [[ -n "$rest_trimmed" ]]; then
        # sources: [a, b, c] -- inline non-empty list, single line.
        SRC_BLOCK_END=$((SRC_IDX + 1))
        inner="${rest_trimmed#\[}"
        inner="${inner%\]}"
        if [[ -n "$(trim "$inner")" ]]; then
            IFS=',' read -ra _parts <<< "$inner"
            for _p in "${_parts[@]}"; do
                _item="$(trim "$_p")"
                _item="$(strip_item_quotes "$_item")"
                if [[ -n "$_item" && "$_item" != "(none)" ]]; then
                    EXISTING_ITEMS+=("$_item")
                fi
            done
        fi
    else
        # Bare `sources:` -- a block-style list (or empty block) follows.
        j=$((SRC_IDX + 1))
        while [[ $j -lt $FM_END ]]; do
            _line="${LINES[$j]}"
            if [[ "$_line" =~ ^[[:space:]] ]]; then
                if [[ "$_line" =~ ^[[:space:]]+-[[:space:]]*(.*)$ ]]; then
                    _item="${BASH_REMATCH[1]}"
                    # Strip a trailing inline "  # comment" if present (this
                    # script's OWN emitted items never carry one; a hand-
                    # authored file might).
                    if [[ "$_item" == *' #'* ]]; then
                        _item="${_item%% #*}"
                    fi
                    _item="$(trim "$_item")"
                    _item="$(strip_item_quotes "$_item")"
                    if [[ -n "$_item" && "$_item" != "(none)" ]]; then
                        EXISTING_ITEMS+=("$_item")
                    fi
                fi
                j=$((j + 1))
                continue
            fi
            break
        done
        SRC_BLOCK_END=$j
    fi
fi

# ---------------------------------------------------------------------------
# value_in_existing VALUE -- membership test against EXISTING_ITEMS.
# ---------------------------------------------------------------------------
value_in_existing() {
    local v="$1" it
    for it in "${EXISTING_ITEMS[@]}"; do
        [[ "$it" == "$v" ]] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------------
# Decide NEW_ITEMS per --op (frontmatter authoritative list).
# ---------------------------------------------------------------------------
declare -a NEW_ITEMS=()
IS_NOOP=0

if [[ "$OP" == "add" ]]; then
    if value_in_existing "$VALUE"; then
        IS_NOOP=1
    else
        NEW_ITEMS=("${EXISTING_ITEMS[@]}" "$VALUE")
    fi
else
    if ! value_in_existing "$VALUE"; then
        die "remove target not found: '$VALUE' is not present in sources: of $FILE" 1
    fi
    for _it in "${EXISTING_ITEMS[@]}"; do
        [[ "$_it" == "$VALUE" ]] && continue
        NEW_ITEMS+=("$_it")
    done
fi

if [[ "$IS_NOOP" -eq 1 ]]; then
    echo "OK: $FILE unchanged -- '$VALUE' already present in sources: (no-op)"
    exit 0
fi

# ---------------------------------------------------------------------------
# Build the replacement frontmatter sources: lines.
# ---------------------------------------------------------------------------
declare -a FM_SRC_LINES=()
if [[ "${#NEW_ITEMS[@]}" -eq 0 ]]; then
    FM_SRC_LINES=("sources: []")
else
    FM_SRC_LINES=("sources:")
    for _it in "${NEW_ITEMS[@]}"; do
        FM_SRC_LINES+=("  - ${_it}")
    done
fi

# ---------------------------------------------------------------------------
# Locate the ## Sources body section (heading + extent) and its managed
# marker pair, if present.
# ---------------------------------------------------------------------------
BODY_START=$((FM_END + 1))
H_IDX=-1
for ((i = BODY_START; i < N; i++)); do
    if [[ "${LINES[$i]}" =~ ^##[[:space:]]+Sources[[:space:]]*$ ]]; then
        H_IDX=$i
        break
    fi
done

SEND=$N
MSTART=-1
MEND=-1
declare -a SECTION_LINES=()

if [[ "$H_IDX" -ge 0 ]]; then
    for ((i = H_IDX + 1; i < N; i++)); do
        if [[ "${LINES[$i]}" =~ ^##[[:space:]] ]] || [[ "${LINES[$i]}" == "---" ]]; then
            SEND=$i
            break
        fi
    done

    if [[ $((SEND - H_IDX - 1)) -gt 0 ]]; then
        SECTION_LINES=("${LINES[@]:$((H_IDX + 1)):$((SEND - H_IDX - 1))}")
    fi

    for ((i = 0; i < ${#SECTION_LINES[@]}; i++)); do
        if [[ "${SECTION_LINES[$i]}" == "$MARK_START" ]]; then MSTART=$i; fi
        if [[ "${SECTION_LINES[$i]}" == "$MARK_END" ]]; then MEND=$i; fi
    done
    if ! [[ "$MSTART" -ge 0 && "$MEND" -ge 0 && "$MEND" -gt "$MSTART" ]]; then
        MSTART=-1
        MEND=-1
    fi
fi

# ---------------------------------------------------------------------------
# Determine whether the section (excluding any managed block) is "empty"
# (blank, or exactly the canonical placeholder paragraph) or holds
# hand-authored content that must be preserved verbatim.
# ---------------------------------------------------------------------------
EMPTY_STATE=1
if [[ "$H_IDX" -ge 0 ]]; then
    OTHER_TEXT=""
    for ((i = 0; i < ${#SECTION_LINES[@]}; i++)); do
        if [[ "$MSTART" -ge 0 && $i -ge $MSTART && $i -le $MEND ]]; then
            continue
        fi
        OTHER_TEXT+="${SECTION_LINES[$i]} "
    done
    OTHER_TEXT_NORM="$(trim "$(echo "$OTHER_TEXT" | tr -s '[:space:]' ' ')")"
    PLACEHOLDER_NORM="$(trim "$(echo "$PLACEHOLDER_TEXT" | tr -s '[:space:]' ' ')")"
    if [[ -z "$OTHER_TEXT_NORM" || "$OTHER_TEXT_NORM" == "$PLACEHOLDER_NORM" ]]; then
        EMPTY_STATE=1
    else
        EMPTY_STATE=0
    fi
fi

# ---------------------------------------------------------------------------
# Build the new section content (NEW_SECTION_LINES), self-contained (spacing
# baked in per case -- no separate blank-line bookkeeping needed by the caller).
# ---------------------------------------------------------------------------
declare -a ITEMS_BLOCK=()
if [[ "${#NEW_ITEMS[@]}" -gt 0 ]]; then
    ITEMS_BLOCK=("$MARK_START")
    for _it in "${NEW_ITEMS[@]}"; do
        ITEMS_BLOCK+=("- ${_it}")
    done
    ITEMS_BLOCK+=("$MARK_END")
fi

declare -a NEW_SECTION_LINES=()
if [[ "$H_IDX" -ge 0 ]]; then
    if [[ "$MSTART" -ge 0 ]]; then
        # Existing managed block -- surgical replace in place. Exception: if
        # the new list is empty AND nothing else (no hand-authored content)
        # shares the section, restore the canonical placeholder paragraph
        # instead of leaving a bare blank section behind.
        if [[ "${#ITEMS_BLOCK[@]}" -eq 0 && "$EMPTY_STATE" -eq 1 ]]; then
            NEW_SECTION_LINES=("" "$PLACEHOLDER_TEXT" "")
        else
            if [[ "$MSTART" -gt 0 ]]; then
                NEW_SECTION_LINES+=("${SECTION_LINES[@]:0:MSTART}")
            fi
            NEW_SECTION_LINES+=("${ITEMS_BLOCK[@]}")
            tail_start=$((MEND + 1))
            tail_count=$((${#SECTION_LINES[@]} - tail_start))
            if [[ "$tail_count" -gt 0 ]]; then
                NEW_SECTION_LINES+=("${SECTION_LINES[@]:tail_start:tail_count}")
            fi
        fi
    elif [[ "$EMPTY_STATE" -eq 1 ]]; then
        if [[ "${#ITEMS_BLOCK[@]}" -gt 0 ]]; then
            NEW_SECTION_LINES=("" "${ITEMS_BLOCK[@]}" "")
        else
            NEW_SECTION_LINES=("" "$PLACEHOLDER_TEXT" "")
        fi
    else
        # Hand-authored content present, no managed block yet.
        if [[ "${#ITEMS_BLOCK[@]}" -gt 0 ]]; then
            NEW_SECTION_LINES=("" "${ITEMS_BLOCK[@]}" "" "${SECTION_LINES[@]}")
        else
            NEW_SECTION_LINES=("${SECTION_LINES[@]}")
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Assemble the full output file: frontmatter (with sources: replaced/inserted)
# + body (with the ## Sources section replaced, if the heading was found).
# ---------------------------------------------------------------------------
declare -a OUT=()

if [[ "$SRC_IDX" -ge 0 ]]; then
    if [[ "$SRC_IDX" -gt 0 ]]; then
        OUT+=("${LINES[@]:0:SRC_IDX}")
    fi
    OUT+=("${FM_SRC_LINES[@]}")
    if [[ "$SRC_BLOCK_END" -lt "$FM_END" ]]; then
        OUT+=("${LINES[@]:SRC_BLOCK_END:$((FM_END - SRC_BLOCK_END))}")
    fi
else
    # No sources: key existed -- insert a fresh one just before the closing fence.
    if [[ "$FM_END" -gt 0 ]]; then
        OUT+=("${LINES[@]:0:FM_END}")
    fi
    OUT+=("${FM_SRC_LINES[@]}")
fi
OUT+=("---")

if [[ "$H_IDX" -ge 0 ]]; then
    OUT+=("${LINES[@]:BODY_START:$((H_IDX - BODY_START + 1))}")
    OUT+=("${NEW_SECTION_LINES[@]}")
    OUT+=("${LINES[@]:SEND}")
else
    if [[ "$BODY_START" -lt "$N" ]]; then
        OUT+=("${LINES[@]:BODY_START}")
    fi
fi

# ---------------------------------------------------------------------------
# Write atomically (temp file alongside the target + mv), restoring CRLF /
# no-trailing-newline byte characteristics to match the source.
# ---------------------------------------------------------------------------
TARGET_DIR="$(dirname "$FILE")"
TMP="$(mktemp "${TARGET_DIR}/.write-external-source.XXXXXX")" \
    || die "cannot create a temp file under $TARGET_DIR" 3
trap 'rm -f -- "$TMP"' EXIT

if [[ "$HAS_CRLF" -eq 1 ]]; then
    printf '%s\r\n' "${OUT[@]}" > "$TMP"
else
    printf '%s\n' "${OUT[@]}" > "$TMP"
fi

# A no-trailing-newline SOURCE file must not silently gain one. Strip exactly
# the one trailing line terminator our printf added above (an 'X' terminator
# is appended before capture so command substitution's own trailing-newline
# stripping never eats a real one).
if [[ "$HAD_TRAILING_NL" -eq 0 ]]; then
    _tmpcontent="$(cat "$TMP"; printf 'X')"
    _tmpcontent="${_tmpcontent%X}"
    if [[ "$HAS_CRLF" -eq 1 ]]; then
        _tmpcontent="${_tmpcontent%$'\r\n'}"
    else
        _tmpcontent="${_tmpcontent%$'\n'}"
    fi
    printf '%s' "$_tmpcontent" > "$TMP"
fi

if [[ ! -s "$TMP" ]]; then
    die "write produced empty output; $FILE preserved" 3
fi

if ! grep -q '^sources:' "$TMP"; then
    die "sanity check failed: 'sources:' key not found in output; $FILE preserved" 3
fi

mv -- "$TMP" "$FILE" || die "failed to move written file into place: $FILE" 3
trap - EXIT

if [[ "$OP" == "add" ]]; then
    echo "OK: $FILE updated -- '${VALUE}' added to sources:"
else
    echo "OK: $FILE updated -- '${VALUE}' removed from sources:"
fi
