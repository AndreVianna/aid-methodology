#!/usr/bin/env bash
# lint-frontmatter.sh -- deterministic presence+shape check over KB frontmatter.
#
# In-scope predicate (f011 scope-widening, [SPIKE-M1] resolved):
#   kb-category in {primary, extension} AND source: != generated
# This covers hand-authored docs (source: hand-authored), forward-authored
# greenfield seed docs (source: forward-authored, f003), AND promoted docs
# (e.g. source: "promoted from work-local research ...") while keeping
# generator-written docs (source: generated) permanently out of scope.
# NOTE: if a future source: allow-list check is ever added to this script,
# it MUST include forward-authored (seed docs must never be skipped; they
# receive the same full presence+shape lint as hand-authored docs).
#
# Soft-skip rule (day-one compatibility, NFR-7 -- RETAINED verbatim):
#   Any doc that carries NONE of the f001 new fields
#   (objective, summary, sources, tags, see_also, owner, audience)
#   is treated as "pre-migration" and skipped entirely.
#   This keeps CI green on un-migrated KB docs until f011 migrates them.
#   Adopters who upgrade but have not yet migrated remain degrade-graceful.
#
# Always skipped:
#   - docs with kb-category: meta
#   - docs with source: generated
#
# Emits findings using the existing rubric tags:
#   [FM-MISSING]  -- required field is absent or empty
#   [FM-INVALID]  -- field is present but malformed (wrong shape/type/value)
#
# No new tags are introduced by this linter.
#
# Usage:
#   bash lint-frontmatter.sh --root <kb-root>
#   bash lint-frontmatter.sh --root .aid/knowledge
#
# Exit codes:
#   0 -- all checked docs pass (skipped docs do not count as failures)
#   1 -- one or more findings emitted

set -eu

ROOT=""
VERBOSE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)    ROOT="$2";   shift 2 ;;
        --verbose) VERBOSE=1;   shift   ;;
        -h|--help)
            cat <<'HELP_EOF'
lint-frontmatter.sh -- presence+shape lint for KB doc frontmatter.

In-scope: kb-category in {primary, extension} AND source: != generated.
Covers hand-authored docs and promoted docs; keeps generator-written docs
permanently out of scope. Day-one soft-skip: docs carrying none of the
new fields are skipped (pre-migration). meta docs and source:generated docs
are always skipped.

Emits [FM-MISSING] for absent required fields and [FM-INVALID] for malformed
shapes. No new tags are introduced.

Usage:
  bash lint-frontmatter.sh --root <kb-root>

Exit codes:
  0  all checked docs pass
  1  one or more findings emitted
HELP_EOF
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

[[ -n "$ROOT" ]] || { echo "--root is required" >&2; exit 1; }
[[ -d "$ROOT" ]] || { echo "Root not a directory: $ROOT" >&2; exit 1; }

ROOT="$(cd "$ROOT" && pwd)"

# ---------------------------------------------------------------------------
# Frontmatter loader: parse a doc's YAML frontmatter ONCE with a single awk
# and populate global associative arrays. Previously each fm_* helper spawned
# its own awk to re-parse the frontmatter, so lint_doc paid ~25 awk spawns per
# doc; now it pays one. The four fm_* helpers below read from these arrays and
# preserve their exact original semantics for every field:
#
#   FM_PRESENT[field]  1 iff the field key is present         (fm_field_present)
#   FM_SCALAR[field]   text after "field:[[:space:]]*"        (fm_field)
#   FM_SHAPE[field]    inline|block|empty|scalar, or unset    (fm_list_shape)
#                      (unset also covers the block-form field whose block is
#                       terminated by the closing '---' delimiter, for which
#                       fm_list_shape emitted nothing / returned "")
#   FM_ITEMS[field]    newline-joined list items              (fm_list_items)
#
# The single awk reproduces the frontmatter delimiter logic and the branch
# structure of all four helpers exactly. It emits records as
# "TYPE<SOH>field<SOH>value" lines (SOH = 0x01, which cannot appear in a field
# name or a frontmatter value); bash parses them with IFS=$'\001'. Only the
# FIRST occurrence of any field is recorded (matching each helper's exit-on-
# first-match behaviour).
# ---------------------------------------------------------------------------
declare -gA FM_PRESENT FM_SCALAR FM_SHAPE FM_ITEMS

load_frontmatter() {
    local f="$1"
    FM_PRESENT=()
    FM_SCALAR=()
    FM_SHAPE=()
    FM_ITEMS=()

    local tag key val
    while IFS=$'\001' read -r tag key val; do
        case "$tag" in
            P) FM_PRESENT["$key"]=1 ;;
            S) FM_SCALAR["$key"]="$val" ;;
            H) FM_SHAPE["$key"]="$val" ;;
            I)
                if [[ -n "${FM_ITEMS[$key]+set}" ]]; then
                    FM_ITEMS["$key"]+=$'\n'"$val"
                else
                    FM_ITEMS["$key"]="$val"
                fi
                ;;
        esac
    done < <(awk '
        BEGIN { in_fm=0; collecting=0; curfield=""; sawfirst=0; SEP=sprintf("%c", 1) }
        /^---$/ {
            in_fm = !in_fm
            if (NR > 1 && !in_fm) exit
            next
        }
        in_fm {
            # --- Block-list continuation (mirrors fm_list_shape/fm_list_items
            #     "in_field" branch, which is tested before the field match). ---
            if (collecting) {
                if (/^[[:space:]]+-[[:space:]]/ || /^[[:space:]]+-$/) {
                    if (!sawfirst) { print "H" SEP curfield SEP "block"; sawfirst=1 }
                    item = $0
                    sub(/^[[:space:]]+-[[:space:]]*/, "", item)
                    sub(/[[:space:]]+$/, "", item)
                    if (item != "") print "I" SEP curfield SEP item
                    next
                } else {
                    if (!sawfirst) { print "H" SEP curfield SEP "empty"; sawfirst=1 }
                    collecting = 0
                    curfield = ""
                    # fall through: this line may itself be a new top-level key
                }
            }
            # --- Top-level key line (mirrors the "$0 ~ ^field:" match). ---
            if ($0 ~ /^[A-Za-z0-9_-]+:/) {
                key = $0
                sub(/:.*/, "", key)
                if (!(key in seen)) {
                    seen[key] = 1
                    print "P" SEP key
                    rest = $0
                    sub("^" key ":[[:space:]]*", "", rest)
                    print "S" SEP key SEP rest
                    if (rest ~ /^\[\]/) {
                        print "H" SEP key SEP "empty"
                    } else if (rest ~ /^\[/) {
                        print "H" SEP key SEP "inline"
                        inner = rest
                        sub(/^\[/, "", inner)
                        sub(/\][[:space:]]*$/, "", inner)
                        if (inner != "") {
                            n = split(inner, items, /[[:space:]]*,[[:space:]]*/)
                            for (i = 1; i <= n; i++) {
                                it = items[i]
                                gsub(/^[[:space:]]+|[[:space:]]+$/, "", it)
                                gsub(/^['\''"]|['\''"]$/, "", it)
                                if (it != "") print "I" SEP key SEP it
                            }
                        }
                    } else if (rest ~ /^[[:space:]]*$/) {
                        collecting = 1
                        curfield = key
                        sawfirst = 0
                    } else {
                        print "H" SEP key SEP "scalar"
                    }
                }
            }
        }
    ' "$f")

    return 0
}

# ---------------------------------------------------------------------------
# Frontmatter helper: extract a single-line scalar field value.
# Returns empty string if field is absent. Reads FM_SCALAR/FM_PRESENT.
# ---------------------------------------------------------------------------
fm_field() {
    local f="$1" field="$2"
    if [[ -n "${FM_PRESENT[$field]-}" ]]; then
        printf '%s\n' "${FM_SCALAR[$field]-}"
    fi
}

# ---------------------------------------------------------------------------
# Frontmatter helper: check if a field name is present (regardless of value).
# Prints "1" if present, "" if absent.
# ---------------------------------------------------------------------------
fm_field_present() {
    local f="$1" field="$2"
    if [[ -n "${FM_PRESENT[$field]-}" ]]; then
        printf '1\n'
    fi
}

# ---------------------------------------------------------------------------
# Frontmatter helper: check if a list field is present and is a YAML list.
# A list field is one that has either:
#   - An inline form: field: [...]
#   - A block form: field:\n  - item
#   - An empty inline form: field: []
# Returns "inline", "block", "empty", or "" (absent/scalar).
# ---------------------------------------------------------------------------
fm_list_shape() {
    local f="$1" field="$2"
    if [[ -n "${FM_SHAPE[$field]-}" ]]; then
        printf '%s\n' "${FM_SHAPE[$field]}"
    fi
}

# ---------------------------------------------------------------------------
# Frontmatter helper: extract all items from a YAML list field (one per line).
# Handles both inline [a, b] and block:
#   - a
#   - b
# Returns empty output if field is absent or list is empty.
# ---------------------------------------------------------------------------
fm_list_items() {
    local f="$1" field="$2"
    if [[ -n "${FM_ITEMS[$field]+set}" ]]; then
        printf '%s\n' "${FM_ITEMS[$field]}"
    fi
}

# ---------------------------------------------------------------------------
# Shape validators
# ---------------------------------------------------------------------------

# Check if a scalar value is a single line (no newline in it -- which would
# indicate a block scalar was used). Since we extract with awk (single line),
# we just check the extracted value is non-empty.
# Returns "ok" or "empty".
scalar_nonempty() {
    local val="$1"
    val="${val#"${val%%[![:space:]]*}"}"  # ltrim
    val="${val%"${val##*[![:space:]]}"}"  # rtrim
    if [[ -n "$val" ]]; then
        echo "ok"
    else
        echo "empty"
    fi
}

# Check if a sources: entry has a valid shape:
#   - URL: starts with http:// or https://
#   - repo-relative path/glob: a non-empty string that doesn't contain spaces
#     and doesn't read like a prose sentence (no period-space-Capital pattern).
# We check: not a free sentence (no ". " inside, no starts-with-capital-and-ends-with-period
# unless it's a URL). Paths/globs can contain /, *, ?, ., -, _, alphanumeric.
# Returns "ok" or "invalid".
sources_entry_shape() {
    local entry="$1"
    # Empty entry is invalid
    [[ -z "$entry" ]] && echo "invalid" && return

    # URL shape
    if echo "$entry" | grep -qE '^https?://'; then
        echo "ok"
        return
    fi

    # Path/glob shape: disallow spaces (free sentences have spaces).
    # A valid path/glob entry contains no whitespace characters.
    if echo "$entry" | grep -qE '^[^[:space:]]+$'; then
        echo "ok"
        return
    fi

    # Contains spaces -- likely a free sentence, not a path/glob/URL
    echo "invalid"
}

# Check approved_at_commit: value is 7-40 lowercase hex chars.
# Returns "ok" or "invalid".
approved_at_commit_shape() {
    local val="$1"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    if echo "$val" | grep -qE '^[0-9a-f]{7,40}$'; then
        echo "ok"
    else
        echo "invalid"
    fi
}

# ---------------------------------------------------------------------------
# Lint a single doc. Prints findings; returns number of findings.
# ---------------------------------------------------------------------------
lint_doc() {
    local f="$1"
    local doc
    doc="$(basename "$f")"
    local findings=0

    # Parse this doc's frontmatter once; all fm_* helpers read the arrays.
    load_frontmatter "$f"

    # --- Determine category and source ---
    local cat
    cat="$(fm_field "$f" "kb-category")"
    cat="${cat:-primary}"

    local src
    src="$(fm_field "$f" "source")"
    src="${src:-hand-authored}"

    # --- Skip: meta docs ---
    if [[ "$cat" == "meta" ]]; then
        [[ "$VERBOSE" -eq 1 ]] && echo "  SKIP (meta): $doc"
        return 0
    fi

    # --- Skip: generated docs ---
    if [[ "$src" == "generated" ]]; then
        [[ "$VERBOSE" -eq 1 ]] && echo "  SKIP (generated): $doc"
        return 0
    fi

    # --- Only lint primary and extension categories ---
    if [[ "$cat" != "primary" && "$cat" != "extension" ]]; then
        [[ "$VERBOSE" -eq 1 ]] && echo "  SKIP (category=$cat): $doc"
        return 0
    fi

    # --- Day-one soft-skip: skip if NONE of the new f001 fields are present ---
    local has_new_fields=0
    for new_field in objective summary sources tags see_also owner audience; do
        if [[ -n "$(fm_field_present "$f" "$new_field")" ]]; then
            has_new_fields=1
            break
        fi
    done

    if [[ "$has_new_fields" -eq 0 ]]; then
        [[ "$VERBOSE" -eq 1 ]] && echo "  SKIP (pre-migration): $doc"
        return 0
    fi

    [[ "$VERBOSE" -eq 1 ]] && echo "  CHECK: $doc (category=$cat source=$src)"

    # --- Required field: objective: ---
    local obj
    obj="$(fm_field "$f" "objective")"
    if [[ -z "$(fm_field_present "$f" "objective")" ]]; then
        echo "  [FM-MISSING] $doc: required field 'objective:' is absent"
        findings=$((findings + 1))
    elif [[ "$(scalar_nonempty "$obj")" == "empty" ]]; then
        echo "  [FM-MISSING] $doc: required field 'objective:' is present but empty"
        findings=$((findings + 1))
    fi

    # --- Required field: summary: ---
    local summ
    summ="$(fm_field "$f" "summary")"
    if [[ -z "$(fm_field_present "$f" "summary")" ]]; then
        echo "  [FM-MISSING] $doc: required field 'summary:' is absent"
        findings=$((findings + 1))
    elif [[ "$(scalar_nonempty "$summ")" == "empty" ]]; then
        echo "  [FM-MISSING] $doc: required field 'summary:' is present but empty"
        findings=$((findings + 1))
    fi

    # --- Required field: sources: (must be a YAML list, possibly empty []) ---
    local src_shape
    src_shape="$(fm_list_shape "$f" "sources")"
    if [[ -z "$(fm_field_present "$f" "sources")" ]]; then
        echo "  [FM-MISSING] $doc: required field 'sources:' is absent (use 'sources: []' for a pure-synthesis doc)"
        findings=$((findings + 1))
    elif [[ "$src_shape" == "scalar" ]]; then
        echo "  [FM-INVALID] $doc: 'sources:' must be a YAML list, not a scalar value"
        findings=$((findings + 1))
    else
        # sources is a list -- check each entry's shape
        while IFS= read -r entry; do
            [[ -z "$entry" ]] && continue
            if [[ "$(sources_entry_shape "$entry")" == "invalid" ]]; then
                echo "  [FM-INVALID] $doc: 'sources:' entry is not a path/glob/URL (free sentence?): $entry"
                findings=$((findings + 1))
            fi
        done < <(fm_list_items "$f" "sources")
    fi

    # --- Optional field: tags: (if present, must be a list) ---
    if [[ -n "$(fm_field_present "$f" "tags")" ]]; then
        local tags_shape
        tags_shape="$(fm_list_shape "$f" "tags")"
        if [[ "$tags_shape" == "scalar" ]]; then
            echo "  [FM-INVALID] $doc: 'tags:' must be a YAML list, not a scalar value"
            findings=$((findings + 1))
        fi
    fi

    # --- Optional field: see_also: (if present, must be a list) ---
    if [[ -n "$(fm_field_present "$f" "see_also")" ]]; then
        local see_also_shape
        see_also_shape="$(fm_list_shape "$f" "see_also")"
        if [[ "$see_also_shape" == "scalar" ]]; then
            echo "  [FM-INVALID] $doc: 'see_also:' must be a YAML list, not a scalar value"
            findings=$((findings + 1))
        fi
    fi

    # --- Optional field: audience: (if present, must be a list) ---
    if [[ -n "$(fm_field_present "$f" "audience")" ]]; then
        local aud_shape
        aud_shape="$(fm_list_shape "$f" "audience")"
        if [[ "$aud_shape" == "scalar" ]]; then
            echo "  [FM-INVALID] $doc: 'audience:' must be a YAML list, not a scalar value"
            findings=$((findings + 1))
        fi
    fi

    # --- Optional field: owner: (if present, must be a non-empty scalar) ---
    if [[ -n "$(fm_field_present "$f" "owner")" ]]; then
        local owner_val
        owner_val="$(fm_field "$f" "owner")"
        if [[ "$(scalar_nonempty "$owner_val")" == "empty" ]]; then
            echo "  [FM-INVALID] $doc: 'owner:' is present but empty; must be a non-empty scalar"
            findings=$((findings + 1))
        fi
    fi

    # --- Optional field: approved_at_commit: (if present, must be 7-40 lowercase hex) ---
    if [[ -n "$(fm_field_present "$f" "approved_at_commit")" ]]; then
        local aac_val
        aac_val="$(fm_field "$f" "approved_at_commit")"
        if [[ "$(approved_at_commit_shape "$aac_val")" == "invalid" ]]; then
            echo "  [FM-INVALID] $doc: 'approved_at_commit:' must be 7-40 lowercase hex chars, got: $aac_val"
            findings=$((findings + 1))
        fi
    fi

    return "$findings"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "=== Frontmatter lint: $ROOT ==="

total_checked=0
total_skipped=0
total_findings=0

while IFS= read -r f; do
    # Parse frontmatter once for the skip pre-check below (lint_doc re-parses
    # for the docs it actually lints).
    load_frontmatter "$f"

    # Determine if this doc will be skipped by lint_doc
    cat="$(fm_field "$f" "kb-category")"
    cat="${cat:-primary}"
    src="$(fm_field "$f" "source")"
    src="${src:-hand-authored}"

    if [[ "$cat" == "meta" || "$src" == "generated" || \
          ( "$cat" != "primary" && "$cat" != "extension" ) ]]; then
        total_skipped=$((total_skipped + 1))
        [[ "$VERBOSE" -eq 1 ]] && echo "  SKIP: $(basename "$f")"
        continue
    fi

    # Check soft-skip
    has_new=0
    for nf in objective summary sources tags see_also owner audience; do
        if [[ -n "$(fm_field_present "$f" "$nf")" ]]; then
            has_new=1
            break
        fi
    done
    if [[ "$has_new" -eq 0 ]]; then
        total_skipped=$((total_skipped + 1))
        [[ "$VERBOSE" -eq 1 ]] && echo "  SKIP (pre-migration): $(basename "$f")"
        continue
    fi

    total_checked=$((total_checked + 1))
    doc_findings=0
    lint_doc "$f" || doc_findings=$?
    total_findings=$((total_findings + doc_findings))

done < <(find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*' | sort)

echo ""
echo "Checked: $total_checked docs | Skipped: $total_skipped docs | Findings: $total_findings"

if [[ "$total_findings" -gt 0 ]]; then
    echo "FAIL: $total_findings frontmatter finding(s) - see [FM-MISSING]/[FM-INVALID] above"
    exit 1
fi

echo "PASS: all checked docs are lint-clean"
exit 0
