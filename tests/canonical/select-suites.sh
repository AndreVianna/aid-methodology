#!/usr/bin/env bash
# select-suites.sh -- print the suites whose declared coverage intersects a change set.
#
# Why this exists: on a Windows/MSYS shell a process spawn costs ~85-135 ms against
# ~3 ms for a bash builtin, so a suite's wall time is set almost entirely by how many
# external processes it starts. Running a suite that cannot be affected by the change in
# hand is therefore not a small waste, it is tens of seconds each time.
#
# Usage:
#   select-suites.sh                 # changed vs HEAD, including untracked
#   select-suites.sh --since REF     # changed vs REF
#   select-suites.sh PATH...         # an explicit change set
#   select-suites.sh --all           # every suite, for a milestone run
#   select-suites.sh --run [...]     # select, then run the selection sequentially
#
# The contract a suite opts into, as a comment block anywhere in its header:
#   # COVERS: canonical/aid/scripts/summarize/contrast-check.mjs
#   # COVERS: canonical/aid/templates/knowledge-summary/
# A trailing slash means "this directory and everything under it".
#
# FAIL-SAFE, and the reason this is safe to put in front of an agent: a suite that
# declares no COVERS line at all is treated as covering EVERYTHING, so it is always
# selected. Forgetting the header can only cost time, never coverage. The one thing that
# could lose coverage -- a WRONG COVERS line -- is a reviewable one-line claim sitting in
# the suite it describes.
#
# This script spawns no external process for the matching itself.

set -euo pipefail

SELF=${0##*/}
HERE=${0%/*}
[ "$HERE" = "$0" ] && HERE=.
cd "$HERE" || exit 2

MODE=changed
REF=HEAD
RUN=0
GLOB='test-*.sh'
declare -a EXPLICIT=()

while [ $# -gt 0 ]; do
    case "$1" in
        --all)   MODE=all; shift ;;
        --since) MODE=changed; REF=${2:?--since needs a ref}; shift 2 ;;
        --glob)  GLOB=${2:?--glob needs a pattern}; shift 2 ;;
        --run)   RUN=1; shift ;;
        -h|--help) sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        --*)     echo "${SELF}: unknown option $1" >&2; exit 2 ;;
        *)       MODE=explicit; EXPLICIT+=("$1"); shift ;;
    esac
done

# ---------------------------------------------------------------------------
# The change set.
# ---------------------------------------------------------------------------
declare -a CHANGED=()
case "$MODE" in
    all) ;;
    explicit) CHANGED=("${EXPLICIT[@]}") ;;
    changed)
        # Tracked modifications plus untracked files: a brand-new subject or a
        # brand-new suite must select, and neither shows up in a plain diff.
        while IFS= read -r p; do
            [ -n "$p" ] && CHANGED+=("$p")
        done < <(
            git diff --name-only "$REF" 2>/dev/null || true
            git diff --name-only --cached 2>/dev/null || true
            git ls-files --others --exclude-standard 2>/dev/null || true
        )
        ;;
esac

# ---------------------------------------------------------------------------
# The suites, and what each declares. No spawn per suite: one read each.
# ---------------------------------------------------------------------------
declare -a SUITES=()
for s in $GLOB; do
    [ -f "$s" ] || continue
    [ "$s" = "$SELF" ] && continue
    SUITES+=("$s")
done

if [ "${#SUITES[@]}" -eq 0 ]; then
    echo "${SELF}: no suites found in $(pwd)" >&2
    exit 2
fi

matches() {                      # matches <changed-path> <covers-entry>
    local c=$1 e=$2
    case "$e" in
        */) [ "${c#"$e"}" != "$c" ] && return 0
            # a change to the directory itself
            [ "$c" = "${e%/}" ] && return 0
            return 1 ;;
        *)  [ "$c" = "$e" ] && return 0
            # a COVERS file entry also matches a change to a path under it, so a
            # directory named without its slash still behaves sanely
            [ "${c#"$e"/}" != "$c" ] && return 0
            return 1 ;;
    esac
}

declare -a SELECTED=()
declare -a REASONS=()

for s in "${SUITES[@]}"; do
    declare -a covers=()
    while IFS= read -r line; do
        case "$line" in
            '#'*COVERS:*) ;;
            *) continue ;;
        esac
        entry=${line#*COVERS:}
        # strip surrounding whitespace without a spawn
        entry=${entry#"${entry%%[![:space:]]*}"}
        entry=${entry%"${entry##*[![:space:]]}"}
        [ -n "$entry" ] && covers+=("$entry")
    done < "$s"

    if [ "$MODE" = all ]; then
        SELECTED+=("$s"); REASONS+=("milestone: --all")
        continue
    fi

    if [ "${#covers[@]}" -eq 0 ]; then
        SELECTED+=("$s"); REASONS+=("NO COVERS HEADER -- selected fail-safe")
        continue
    fi

    hit=""
    for c in ${CHANGED[@]+"${CHANGED[@]}"}; do
        for e in "${covers[@]}"; do
            if matches "$c" "$e"; then hit="$c" ; break 2; fi
        done
    done
    if [ -n "$hit" ]; then
        SELECTED+=("$s"); REASONS+=("$hit")
    fi
done

# ---------------------------------------------------------------------------
# Report. The unselected list is printed too: a selection you cannot see the
# complement of is a coverage claim you cannot audit.
# ---------------------------------------------------------------------------
if [ "$RUN" -eq 0 ]; then
    if [ "$MODE" != all ]; then
        echo "# change set: ${#CHANGED[@]} path(s) vs ${REF}" >&2
    fi
    i=0
    for s in ${SELECTED[@]+"${SELECTED[@]}"}; do
        printf '%s\n' "$s"
        printf '#   ^ %s\n' "${REASONS[$i]}" >&2
        i=$((i + 1))
    done
    if [ "${#SELECTED[@]}" -eq 0 ]; then
        echo "# nothing selected: no suite declares coverage of this change set" >&2
    fi
    skipped=$(( ${#SUITES[@]} - ${#SELECTED[@]} ))
    echo "# selected ${#SELECTED[@]} of ${#SUITES[@]} suite(s); ${skipped} not affected by this change set" >&2
    exit 0
fi

RC=0
for s in ${SELECTED[@]+"${SELECTED[@]}"}; do
    echo "=== ${s} ==="
    if bash "$s"; then :; else RC=1; echo "=== ${s}: FAILED ==="; fi
done
echo "=== ran ${#SELECTED[@]} of ${#SUITES[@]} suite(s) ==="
exit "$RC"
