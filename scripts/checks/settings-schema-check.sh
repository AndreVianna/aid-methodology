#!/usr/bin/env bash
# settings-schema-check.sh -- assert the shape of a settings.yml, mechanically.
#
# WHAT IT REPLACES, MEASURED
#
# Before this check, "is settings.yml well-formed?" was answered by a reviewer
# reading the file against `artifact-schemas.md § settings.yml` and re-deriving
# the answer each cycle. That re-derivation is what this script removes, and it
# was not small. Re-run these to reproduce the figures:
#
#   $ grep -rn 'read-setting\.sh' canonical bin --include='*.sh' --include='*.md' \
#       | grep -v '^canonical/aid/scripts/config/read-setting.sh:' \
#       | grep -E '\-\-(path|skill)' | wc -l
#   45          # invocation lines, across 36 files
#
#   ... | grep -c -- '--default'      ->  38
#   ... | grep -vc -- '--default'     ->   7
#
# The 38/7 split is the point. Thirty-eight call sites carry their own
# `--default`, so a key missing from settings.yml is invisible at those sites --
# the caller silently gets its fallback and nothing reports a malformed file.
# Only the seven without a default fail loudly. So reading the file is the ONLY
# way a shape error surfaces for 84% of reads (38/45), and reading is exactly
# what is unreliable: a reviewer re-deriving 14 distinct key selectors by eye,
# every cycle, produces a different answer on different days.
#
#   ... | grep -ohE '\-\-path [a-z_.]+|--skill [a-z-]+ --key [a-z_]+' | sort -u | wc -l
#   14          # distinct key selectors
#
# This script answers the same question with no judgment, in one run.
#
# WHAT IT CHECKS
#   1. `format_version` present, an integer, and equal to bin/aid's
#      AID_SUPPORTED_FORMAT.
#   2. `minimum_grade`, if present, is a value grade.sh can actually emit.
#   3. Every top-level key is one artifact-schemas.md documents.
#   4. The file declares at least one key -- examining nothing is a failure.
#
# It does NOT check values a project legitimately chooses (a project name, a
# branch), only shape.
#
# Usage:
#   settings-schema-check.sh --path <settings.yml> [--quiet]
#
# Exit codes:
#   0  shape is valid
#   1  at least one violation, each naming its key; or the file declares no keys
#   2  invocation error / unreadable input

set -uo pipefail

SETTINGS=""
QUIET=0

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0"; exit 0 ;;
        --path)  SETTINGS="${2:-}"; shift 2 ;;
        --quiet) QUIET=1; shift ;;
        *) echo "settings-schema-check.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
done

[ -n "$SETTINGS" ] || { echo "settings-schema-check.sh: --path is required" >&2; exit 2; }
[ -r "$SETTINGS" ] || { echo "settings-schema-check.sh: cannot read: $SETTINGS" >&2; exit 2; }

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SELF_DIR}/../.." && pwd)"

say() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }

VIOLATIONS=0
violation() { VIOLATIONS=$((VIOLATIONS + 1)); say "[FAIL] $1"; say "       $2"; }

# Every check prints what it examined beside what it expected, so a passing run
# is auditable rather than merely silent.
row() { printf '  %-22s examined %-28s expected %s\n' "$1" "$2" "$3"; }

# --- top-level keys actually declared -----------------------------------------
# LC_ALL=C so ordering is byte-stable and the output does not vary by locale.
#
# The character class is deliberately wider than the keys AID itself uses. An
# earlier `^[a-z_]+:` could not see a CamelCase key at all, so `ForbiddenKey:`
# was not reported as undocumented -- it was invisible, and the file passed with
# the key counted as absent. An extractor that silently drops what it cannot
# name is the worst kind, because the omission looks like a clean result.
mapfile -t KEYS < <(grep -oE '^[A-Za-z_][A-Za-z0-9_-]*:' "$SETTINGS" 2>/dev/null | tr -d ':' | LC_ALL=C sort -u)
KEY_COUNT="${#KEYS[@]}"

say "== settings-schema-check: ${SETTINGS} =="

# --- 4. examining nothing is a failure ----------------------------------------
if [ "$KEY_COUNT" -eq 0 ]; then
    say ""
    echo "settings-schema-check: FAIL -- the file declares no top-level keys." >&2
    echo "  A shape check that examined nothing cannot distinguish a valid file" >&2
    echo "  from an empty or unparsed one, so this is a failure, not a pass." >&2
    exit 1
fi

row "top-level keys" "${KEY_COUNT}" "at least 1"

# --- 1. format_version --------------------------------------------------------
FV_LINE="$(grep -m1 '^format_version:' "$SETTINGS" 2>/dev/null || true)"
FV="$(printf '%s' "$FV_LINE" | sed -E 's/^format_version:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//')"

EXPECTED_FV="$(grep -oE 'AID_SUPPORTED_FORMAT=[0-9]+' "${REPO_ROOT}/bin/aid" 2>/dev/null \
                | head -1 | cut -d= -f2)"
EXPECTED_FV="${EXPECTED_FV:-4}"

if [ -z "$FV_LINE" ]; then
    violation "format_version is missing" \
              "bin/aid stamps and reads it; expected 'format_version: ${EXPECTED_FV}'"
elif ! printf '%s' "$FV" | grep -qE '^[0-9]+$'; then
    violation "format_version is not an integer: '${FV}'" \
              "expected an integer, ${EXPECTED_FV}"
elif [ "$FV" -gt "$EXPECTED_FV" ]; then
    violation "format_version is ${FV}, newer than this CLI supports" \
              "bin/aid's AID_SUPPORTED_FORMAT is ${EXPECTED_FV}; it REFUSES to operate on this project"
elif [ "$FV" -lt "$EXPECTED_FV" ]; then
    # Not a violation. `bin/aid`'s own `_aid_format_gate` treats an older stamp
    # as non-blocking -- it warns and offers `aid update` -- and refuses only a
    # NEWER one. A check that failed here would be stricter than the tool whose
    # schema it is checking, and would red-flag every project mid-upgrade.
    row "format_version" "$FV" "${EXPECTED_FV}; older is non-blocking"
    say "[NOTE]  format_version ${FV} is behind AID_SUPPORTED_FORMAT ${EXPECTED_FV}."
    say "        bin/aid warns and offers 'aid update'; it refuses only a newer stamp."
else
    row "format_version" "$FV" "$EXPECTED_FV (AID_SUPPORTED_FORMAT)"
fi

# --- 2. minimum_grade ---------------------------------------------------------
# The domain grade.sh emits. F is reachable only via --non-functional, but it is
# a legitimate floor to configure, so it is accepted here.
VALID_GRADES=" A+ A A- B+ B B- C+ C C- D+ D D- E+ E E- F "

check_grade() {
    local key="$1" val="$2"
    case "$VALID_GRADES" in
        *" $val "*) row "$key" "$val" "a grade grade.sh emits" ;;
        *) violation "${key} is '${val}', which grade.sh cannot emit" \
                     "expected one of: A+ A A- B+ B B- C+ C C- D+ D D- E+ E E- F" ;;
    esac
}

MG_LINE="$(grep -m1 '^minimum_grade:' "$SETTINGS" 2>/dev/null || true)"
if [ -n "$MG_LINE" ]; then
    MG="$(printf '%s' "$MG_LINE" | sed -E 's/^minimum_grade:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//')"
    check_grade "minimum_grade" "$MG"
fi

# --- 3. every top-level key is documented -------------------------------------
# The documented set, from artifact-schemas.md § settings.yml "Stored keys".
# A per-skill override block (`discover:` carrying `minimum_grade:`) is a
# documented shape too, so any key matching a known skill name is accepted.
DOCUMENTED=" format_version name description type source_control minimum_grade heartbeat_interval knowledge "
SKILL_KEYS=" discover describe define specify plan detail execute summary summarize interview update-kb deploy review research "

for k in "${KEYS[@]}"; do
    case "$DOCUMENTED" in *" $k "*) continue ;; esac
    case "$SKILL_KEYS"  in *" $k "*) row "per-skill override" "$k" "a documented skill name"; continue ;; esac
    violation "top-level key '${k}' is not documented" \
              "artifact-schemas.md § settings.yml lists the stored keys; add it there or remove it"
done
row "documented keys" "${KEY_COUNT}" "all documented"

# --- verdict ------------------------------------------------------------------
say ""
if [ "$VIOLATIONS" -gt 0 ]; then
    echo "settings-schema-check: FAIL -- ${VIOLATIONS} violation(s)." >&2
    exit 1
fi

say "settings-schema-check: PASS -- ${KEY_COUNT} top-level key(s), all valid."
exit 0
