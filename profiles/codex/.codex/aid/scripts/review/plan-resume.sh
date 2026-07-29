#!/usr/bin/env bash
# plan-resume.sh -- decide, per coverage unit, whether a resumed review may keep it or must re-examine.
#
# WHY THIS EXISTS
# A review that was interrupted has a coverage manifest saying what it had already examined. Trusting
# that blindly is wrong: the artifact may have changed since, or the rule set it was measured against
# may have. This recomputes both fingerprints and emits a per-unit verdict.
#
# THE RULE
#   A unit is INVALIDATED -- must be re-examined -- if any of:
#     - its Status is `In Progress`   (an involuntary death mid-unit; "never finished" is not "done")
#     - its `art=` digest no longer matches the artifact
#     - its `rs=`  digest no longer matches its rule set
#   Otherwise it is KEPT.
#
# WHY IT NEVER WRITES
# The orchestrator applies the plan with `writeback-ledger.sh --set-status`, which preserves the
# single-writer invariant on the ledger. A planner that also wrote would be a second writer of the
# same file, and the sentinel lock exists precisely so that never happens by accident.
#
# WHY THE LINTER EXIT ALPHABET
# This REPORTS staleness, so it follows the convention the coding standard states for linters --
# 0 clean, 1 violations, 2 usage -- rather than writeback-state.sh's writer alphabet where 1 means
# unreadable and 2 means lock contention. One script cannot honour both, which is why the planner and
# the writer are separate scripts.
#
# GRANULARITY, AND ITS COST STATED PLAINLY
# Invalidation is per (rule-set x artifact), not per rule. Per-rule would need each unit to record
# which of its rule set's rules actually fired -- a runtime claim no static check can verify, and
# unfalsifiable in the direction that matters (a rule that finds nothing leaves no trace, so "I
# applied it" cannot be checked). The cost of the coarser choice is OVER-invalidation inside a rule
# set: change one rule and every unit measured against that set is re-examined. That is bounded and
# cheap. Under-invalidation would be a correctness bug.
#
# USAGE
#   plan-resume.sh --ledger PATH [--rubric-root DIR] [--quiet]
#
#   TSV to stdout: row-id <tab> keep|invalidate <tab> reason
#   reason is one of: ok | in-progress | artifact-changed | criteria-changed | artifact-missing
#
# EXIT CODES (linter alphabet)
#   0  nothing stale -- every unit may be kept
#   1  at least one unit must be re-examined
#   2  usage error, or the ledger is unreadable
set -uo pipefail

SCRIPT_NAME="plan-resume.sh"
LEDGER=""
RUBRIC_ROOT=""
QUIET=0

die() { echo "ERROR: ${SCRIPT_NAME}: $*" >&2; exit 2; }
usage() { sed -n '/^# USAGE/,/^set -uo/p' "$0" | sed 's/^# \{0,1\}//; $d'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ledger)      [[ $# -lt 2 ]] && die "--ledger requires a path"; LEDGER="$2"; shift 2 ;;
        --rubric-root) [[ $# -lt 2 ]] && die "--rubric-root requires a path"; RUBRIC_ROOT="$2"; shift 2 ;;
        --quiet)       QUIET=1; shift ;;
        -h|--help)     usage; exit 0 ;;
        *)             die "unknown argument: $1" ;;
    esac
done

[[ -n "$LEDGER" ]] || die "--ledger is required"
[[ -f "$LEDGER" ]] || die "ledger does not exist: $LEDGER"
[[ -r "$LEDGER" ]] || die "ledger is not readable: $LEDGER"

HERE="$(dirname "$0")"
WB="${HERE}/writeback-ledger.sh"
[[ -f "$WB" ]] || die "writeback-ledger.sh not found beside this script: $WB"

# Relative, with no `canonical/` prefix, so this resolves identically in the canonical tree and in
# every rendered profile -- the renderer rewrites `canonical/...` forms and leaves relative ones alone.
[[ -n "$RUBRIC_ROOT" ]] || RUBRIC_ROOT="${HERE}/../../templates/review-rubrics"

# ---------------------------------------------------------------------------
# Digests -- the same idiom and the same sha256sum/shasum fallback the tree
# already uses, so a machine without sha256sum degrades identically everywhere.
# ---------------------------------------------------------------------------
sha_stdin() {
    if   command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -c1-12
    elif command -v shasum    >/dev/null 2>&1; then shasum -a 256 | cut -c1-12
    else printf 'nodigest'
    fi
}

sha_of_file() {
    local f="$1"
    [[ -f "$f" ]] || { printf 'absent'; return 0; }
    sha_stdin < "$f"
}

# The rule-set digest deliberately covers the catalog file PLUS every document its Criterion cells
# cite. A rule set whose DECLARING documents moved has effectively changed even when the catalog file
# did not -- and that is the common case: someone edits the coding standard, not the rubric.
sha_of_rule_set() {
    local rs="$1" base="" lower cand
    lower="$(printf '%s' "$rs" | tr 'A-Z' 'a-z')"
    for cand in "$RUBRIC_ROOT/${lower}.md" "$RUBRIC_ROOT/INDEX.md"; do
        [[ -f "$cand" ]] && { base="$cand"; break; }
    done
    [[ -n "$base" ]] || { printf 'absent'; return 0; }
    {
        cat "$base"
        awk -F'|' '/^\|/ { print $4 }' "$base" 2>/dev/null \
          | grep -oE '`[^`]+`' | tr -d '`' | sed 's/ *§.*//' | sort -u \
          | while IFS= read -r dep; do
                [[ -z "$dep" ]] && continue
                for root in ".aid/knowledge" "$RUBRIC_ROOT/../.." "."; do
                    [[ -f "$root/$dep" ]] && { cat "$root/$dep"; break; }
                done
            done
    } 2>/dev/null | sha_stdin
}

# ---------------------------------------------------------------------------
# Plan
# ---------------------------------------------------------------------------
stale=0; total=0

while IFS=$'\t' read -r id status doc rs stamp art rsd; do
    [[ -z "${id:-}" ]] && continue
    total=$((total + 1))

    verdict="keep"; reason="ok"

    if [[ "$status" == "In Progress" ]]; then
        # An involuntary death mid-unit. Without the leading `In Progress` write this case would be
        # indistinguishable from "never reached", and re-examining exactly the interrupted unit would
        # be impossible.
        verdict="invalidate"; reason="in-progress"
    elif [[ "$status" == "Skipped" ]]; then
        # Skipped is a deliberate deferral (usually blocked by an open gap). It is not stale; the
        # orchestrator re-opens it when the blocking gap resolves.
        verdict="keep"; reason="ok"
    else
        if [[ -n "${doc:-}" && "$doc" != "--" && ! -f "$doc" ]]; then
            verdict="invalidate"; reason="artifact-missing"
        else
            if [[ -n "${art:-}" && "$art" != "--" ]]; then
                now_art="$(sha_of_file "$doc")"
                [[ "$now_art" != "$art" ]] && { verdict="invalidate"; reason="artifact-changed"; }
            fi
            if [[ "$verdict" == "keep" && -n "${rsd:-}" && "$rsd" != "--" ]]; then
                # The recorded token is `<name>@<digest>`; compare only the digest half.
                rs_name="${rsd%@*}"; rs_hash="${rsd##*@}"
                [[ "$rs_name" == "$rsd" ]] && rs_name="$rs"
                now_rs="$(sha_of_rule_set "$rs_name")"
                [[ "$now_rs" != "$rs_hash" ]] && { verdict="invalidate"; reason="criteria-changed"; }
            fi
        fi
    fi

    [[ "$verdict" == "invalidate" ]] && stale=$((stale + 1))
    [[ "$QUIET" -eq 1 ]] || printf '%s\t%s\t%s\n' "$id" "$verdict" "$reason"
done < <(bash "$WB" --ledger "$LEDGER" --list-units 2>/dev/null)

if [[ "$QUIET" -eq 0 ]]; then
    printf '# %s: %s unit(s), %s to re-examine\n' "$SCRIPT_NAME" "$total" "$stale" >&2
fi

[[ "$stale" -eq 0 ]] && exit 0
exit 1
