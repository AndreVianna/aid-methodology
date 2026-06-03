#!/usr/bin/env bash
# cleanup-classify.sh — scan .aid/ and emit a tiered candidate list for cleanup.
#
# Purpose:
#   Deterministic scan + classify phase of the /aid-housekeep CLEANUP stage.
#   Inspects the fixed conservative roots S1–S6 under .aid/ and emits one
#   pipe-delimited candidate record per artifact. Read-only: performs no
#   deletion, no commit, no push, no UI interaction.
#
#   Output format (one line per candidate, stdout):
#     PATH|TIER|TRACKED|DEFAULT_CHECKED|REASON[|GATE]
#
#   Where:
#     PATH            — relative path from REPO_ROOT
#     TIER            — 0, 1, or 2
#     TRACKED         — "tracked" or "untracked"
#     DEFAULT_CHECKED — "true" or "false"
#     REASON          — human-readable classification reason
#     GATE            — (Tier-1 only) "offer" or "explicit-confirm:<reason>"
#
# Usage:
#   cleanup-classify.sh --root REPO_ROOT [--active-work WORK_FOLDER_NAME]
#       REPO_ROOT          absolute path to the repo root (where .aid/ lives)
#       --active-work      name of the currently-active work folder (e.g.
#                          "work-001-aid-housekeep"); excluded from S6 results.
#                          May be supplied multiple times for multiple exclusions.
#
#   cleanup-classify.sh -h | --help
#       Print this help.
#
# Exit codes:
#   0  success (candidate list emitted; may be empty if nothing stale)
#   1  REPO_ROOT not found or .aid/ absent
#   2  argument error (unknown flag, missing required value)
#
# Output:
#   stdout: pipe-delimited candidate records (one per line)
#   stderr: diagnostic messages only (never mixed into stdout)
#
# Safety self-check:
#   This script must never contain an executable rm, git rm, git commit, or
#   git push call. The check below fires before any real work.

set -uo pipefail
# Note: no -e because we use many subcommands that may fail non-fatally (e.g.
# git ls-files returning 1 for untracked paths, git merge-base comparisons).

# ---------------------------------------------------------------------------
# Safety self-check: this script must contain no destructive commands.
# ---------------------------------------------------------------------------
_self_check_passed=0
for _bad_pattern in \
    '^[[:space:]]*rm ' \
    '^[[:space:]]*git rm' \
    '^[[:space:]]*git commit' \
    '^[[:space:]]*git push'; do
    if grep -qE "$_bad_pattern" "$0" 2>/dev/null; then
        echo "ERROR: cleanup-classify.sh: SAFETY VIOLATION — script contains destructive command matching '$_bad_pattern'" >&2
        exit 1
    fi
done
unset _bad_pattern _self_check_passed

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die()  { echo "ERROR: cleanup-classify.sh: $*" >&2; exit "${2:-1}"; }
warn() { echo "WARN: cleanup-classify.sh: $*" >&2; }

usage() {
    sed -n '2,42p' "$0" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
REPO_ROOT=""
ACTIVE_WORK_FOLDERS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --root)
            [[ $# -lt 2 ]] && die "--root requires a value" 2
            REPO_ROOT="$2"; shift 2
            ;;
        --active-work)
            [[ $# -lt 2 ]] && die "--active-work requires a value" 2
            ACTIVE_WORK_FOLDERS+=("$2"); shift 2
            ;;
        *)
            die "unknown flag: $1" 2
            ;;
    esac
done

[[ -z "$REPO_ROOT" ]] && die "--root REPO_ROOT is required" 2
[[ ! -d "$REPO_ROOT" ]] && die "REPO_ROOT not found: $REPO_ROOT" 1
[[ ! -d "${REPO_ROOT}/.aid" ]] && die ".aid/ not found under REPO_ROOT: $REPO_ROOT" 1

AID_DIR="${REPO_ROOT}/.aid"

# ---------------------------------------------------------------------------
# Active-folder resolution
# Builds the set of work-folder names that must NEVER be offered.
#
# (caller) Any name passed via --active-work (highest priority).
# (b)      The folder matching the current branch (aid/work-NNN-* pattern).
#
# Removed in the run-state-relocation change: the former (a) "STATE.md carries
# ## Housekeep Status" and (c) "STATE.md Status != Deployed" exclusions. Housekeep
# run-state now lives in .aid/.temp/HOUSEKEEP_STATE_*.md (not in a work folder), so
# (a) is obsolete; (c) was over-conservative and is superseded by the (i)/(ii)
# matrix, which routes merged-but-not-concluded folders to explicit-confirm.
# ---------------------------------------------------------------------------

# is_active_folder <folder_name>
# Returns 0 (true) if the folder should be excluded from S6 results.
is_active_folder() {
    local folder_name="$1"

    # Caller-supplied exclusions (highest priority)
    local af
    for af in "${ACTIVE_WORK_FOLDERS[@]:-}"; do
        [[ "$af" == "$folder_name" ]] && return 0
    done

    # (b) Matches the current branch pattern aid/work-NNN-* — never offer the work
    # folder whose branch is currently checked out.
    #
    # NOTE: the former signal (a) (folder STATE.md carries ## Housekeep Status) and
    # signal (c) (STATE.md Status != Deployed) were REMOVED. Housekeep run-state no
    # longer lives in any work folder (it lives in .aid/.temp/HOUSEKEEP_STATE_*.md),
    # so (a) is obsolete; and (c) was over-conservative — it pre-empted the (i)/(ii)
    # matrix's own explicit-confirm path, which is exactly how a merged-but-not-
    # concluded folder should be handled. With (c) gone, such folders reach the
    # matrix and are surfaced for explicit per-folder confirmation (never deleted
    # without it).
    local current_branch
    current_branch=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null) || current_branch=""
    if [[ -n "$current_branch" && "$current_branch" =~ ^aid/work-([0-9]+)-(.+)$ ]]; then
        local branch_num="${BASH_REMATCH[1]}"
        if [[ "$folder_name" =~ ^work-([0-9]+)- ]]; then
            local folder_num="${BASH_REMATCH[1]}"
            [[ "$folder_num" == "$branch_num" ]] && return 0
        fi
    fi

    return 1
}

# ---------------------------------------------------------------------------
# Tracked/untracked discriminator
# classify_tracked <path>
# Prints "tracked" or "untracked" to stdout.
# Uses git ls-files (primary) and git check-ignore (fallback for untracked).
# ---------------------------------------------------------------------------
classify_tracked() {
    local path="$1"
    local rel_path="${path#${REPO_ROOT}/}"

    # git ls-files with --error-unmatch exits 0 iff the path is tracked
    if git -C "$REPO_ROOT" ls-files --error-unmatch -- "$rel_path" >/dev/null 2>&1; then
        echo "tracked"
        return 0
    fi

    # Non-empty output from git ls-files (without --error-unmatch) also means tracked
    local ls_out
    ls_out=$(git -C "$REPO_ROOT" ls-files -- "$rel_path" 2>/dev/null)
    if [[ -n "$ls_out" ]]; then
        echo "tracked"
        return 0
    fi

    echo "untracked"
}

# ---------------------------------------------------------------------------
# Emit a candidate record to stdout.
# emit_candidate <path> <tier> <tracked> <default_checked> <reason> [<gate>]
# ---------------------------------------------------------------------------
emit_candidate() {
    local path="$1"
    local tier="$2"
    local tracked="$3"
    local default_checked="$4"
    local reason="$5"
    local gate="${6:-}"

    local rel_path="${path#${REPO_ROOT}/}"

    if [[ -n "$gate" ]]; then
        echo "${rel_path}|${tier}|${tracked}|${default_checked}|${reason}|${gate}"
    else
        echo "${rel_path}|${tier}|${tracked}|${default_checked}|${reason}"
    fi
}

# ---------------------------------------------------------------------------
# Load the registered generated files list.
# Returns space-separated list of registered .aid/generated/* paths (relative).
# ---------------------------------------------------------------------------
load_registered_generated() {
    local registry="${REPO_ROOT}/.claude/templates/generated-files.txt"
    if [[ ! -f "$registry" ]]; then
        echo ""
        return 0
    fi
    # Parse lines of format: <output-path>|<build-command>
    # Extract the output-path column (first field before |)
    grep -v '^[[:space:]]*#' "$registry" | grep -v '^[[:space:]]*$' \
        | awk -F'|' '{print $1}' | tr '\n' ' '
}

# ---------------------------------------------------------------------------
# S1: .aid/.temp/** (gitignored scratch)
# ---------------------------------------------------------------------------
scan_s1() {
    [[ ! -d "${AID_DIR}/.temp" ]] && return 0

    while IFS= read -r -d '' path; do
        [[ -e "$path" ]] || continue
        # Skip /aid-housekeep run-state files — they live in .aid/.temp/ but are
        # owned by the skill's DONE state (which removes HOUSEKEEP_STATE_*.md at run
        # end). Never offer the active run's own state file for deletion.
        case "$(basename "$path")" in
            HOUSEKEEP_STATE_*.md) continue ;;
        esac
        local tracked
        tracked=$(classify_tracked "$path")
        emit_candidate "$path" "0" "$tracked" "true" "S1: gitignored temp scratch (.aid/.temp/)"
    done < <(find "${AID_DIR}/.temp" -mindepth 1 \( -type f -o -type d \) -print0 2>/dev/null)
}

# ---------------------------------------------------------------------------
# S2: .aid/.heartbeat/** (gitignored ephemeral heartbeat files)
# ---------------------------------------------------------------------------
scan_s2() {
    [[ ! -d "${AID_DIR}/.heartbeat" ]] && return 0

    while IFS= read -r -d '' path; do
        [[ -e "$path" ]] || continue
        local tracked
        tracked=$(classify_tracked "$path")
        emit_candidate "$path" "0" "$tracked" "true" "S2: gitignored heartbeat file (.aid/.heartbeat/)"
    done < <(find "${AID_DIR}/.heartbeat" -mindepth 1 \( -type f -o -type d \) -print0 2>/dev/null)
}

# ---------------------------------------------------------------------------
# S3: .aid/knowledge/.cache/**, .manual-checklist.json, .spot-check-facts.txt
# ---------------------------------------------------------------------------
scan_s3() {
    local knowledge_dir="${AID_DIR}/knowledge"
    [[ ! -d "$knowledge_dir" ]] && return 0

    # .cache directory
    if [[ -d "${knowledge_dir}/.cache" ]]; then
        while IFS= read -r -d '' path; do
            [[ -e "$path" ]] || continue
            local tracked
            tracked=$(classify_tracked "$path")
            emit_candidate "$path" "0" "$tracked" "true" "S3: gitignored KB cache (.aid/knowledge/.cache/)"
        done < <(find "${knowledge_dir}/.cache" -mindepth 1 \( -type f -o -type d \) -print0 2>/dev/null)
    fi

    # .manual-checklist.json
    local mcj="${knowledge_dir}/.manual-checklist.json"
    if [[ -f "$mcj" ]]; then
        local tracked
        tracked=$(classify_tracked "$mcj")
        emit_candidate "$mcj" "0" "$tracked" "true" "S3: gitignored KB scratch (.manual-checklist.json)"
    fi

    # .spot-check-facts.txt
    local sct="${knowledge_dir}/.spot-check-facts.txt"
    if [[ -f "$sct" ]]; then
        local tracked
        tracked=$(classify_tracked "$sct")
        emit_candidate "$sct" "0" "$tracked" "true" "S3: gitignored KB scratch (.spot-check-facts.txt)"
    fi
}

# ---------------------------------------------------------------------------
# S4: stray verify reports (**/verify-deterministic-report.json,
#     **/verify-advisory-report.json) anywhere under .aid/
# ---------------------------------------------------------------------------
scan_s4() {
    while IFS= read -r -d '' path; do
        [[ -f "$path" ]] || continue
        local tracked
        tracked=$(classify_tracked "$path")
        emit_candidate "$path" "0" "$tracked" "true" "S4: stray tool report (verify JSON)"
    done < <(find "$AID_DIR" \( \
        -name "verify-deterministic-report.json" \
        -o -name "verify-advisory-report.json" \
        \) -print0 2>/dev/null)
}

# ---------------------------------------------------------------------------
# S5: unregistered .aid/generated/** outputs
# ---------------------------------------------------------------------------
scan_s5() {
    [[ ! -d "${AID_DIR}/generated" ]] && return 0

    # Load registered outputs
    local registered_str
    registered_str=$(load_registered_generated)

    while IFS= read -r -d '' path; do
        [[ -f "$path" ]] || continue
        local rel_path="${path#${REPO_ROOT}/}"

        # Check if this path is registered
        local is_registered=0
        local reg
        for reg in $registered_str; do
            if [[ "$rel_path" == "$reg" ]]; then
                is_registered=1
                break
            fi
        done

        [[ "$is_registered" -eq 1 ]] && continue  # registered → skip

        local tracked
        tracked=$(classify_tracked "$path")
        emit_candidate "$path" "0" "$tracked" "true" "S5: unregistered generated output (.aid/generated/)"
    done < <(find "${AID_DIR}/generated" -mindepth 1 -type f -print0 2>/dev/null)
}

# ---------------------------------------------------------------------------
# Signal (i): merged to master
#
# compute_signal_i <work_folder_name>
# Returns via stdout: "pass" or "fail:<reason>"
#
# Priority order:
#   1. gh pr view <N> --json state,mergedAt (if gh is available + PR recorded)
#   2. git merge-base --is-ancestor <sha> origin/master (ancestry fallback)
#   3. Conservative fail if neither is evaluable
# ---------------------------------------------------------------------------
compute_signal_i() {
    local folder_name="$1"
    local state_md="${AID_DIR}/${folder_name}/STATE.md"

    # No STATE.md → unevaluable → fail
    if [[ ! -f "$state_md" ]]; then
        echo "fail:no STATE.md found"
        return 0
    fi

    # ---------- Attempt 1: gh PR check ----------
    local pr_numbers=()
    if command -v gh >/dev/null 2>&1; then
        # Extract PR column from ## Deploy Status table
        # Table row format: | Delivery | State | PR | KB Updated | Tag | Notes |
        # We look for lines inside ## Deploy Status that have a numeric PR field
        local in_deploy=0
        local pr_num
        while IFS= read -r line; do
            if echo "$line" | grep -q "^## Deploy Status"; then
                in_deploy=1
                continue
            fi
            if [[ $in_deploy -eq 1 ]] && echo "$line" | grep -q "^## "; then
                in_deploy=0
            fi
            if [[ $in_deploy -eq 1 ]]; then
                # Extract 3rd pipe-delimited field (PR number)
                pr_num=$(echo "$line" | awk -F'|' 'NF>=4 { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4 }')
                if [[ "$pr_num" =~ ^[0-9]+$ ]]; then
                    pr_numbers+=("$pr_num")
                fi
            fi
        done < "$state_md"

        # Check each PR
        local pn
        for pn in "${pr_numbers[@]:-}"; do
            local gh_state
            gh_state=$(gh pr view "$pn" --json state -q .state 2>/dev/null) || gh_state=""
            if [[ "$gh_state" == "MERGED" ]]; then
                echo "pass"
                return 0
            fi
        done
        # gh available but no MERGED PR found
        if [[ ${#pr_numbers[@]} -gt 0 ]]; then
            echo "fail:gh reports PR not MERGED"
            return 0
        fi
    fi

    # ---------- Attempt 2: ancestry fallback ----------
    # Read any recorded merge SHA or branch tip from STATE.md.
    # Look for a field that contains a commit SHA in ## Deploy Status or
    # a "**Branch:**" field in ## Housekeep Status.
    local recorded_sha=""

    # Try Housekeep Status "Branch" field for a SHA (may be a branch name, not SHA)
    # More robustly: look for any 40-char hex SHA in the ## Deploy Status section
    local in_deploy=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "^## Deploy Status"; then
            in_deploy=1
            continue
        fi
        if [[ $in_deploy -eq 1 ]] && echo "$line" | grep -q "^## "; then
            break
        fi
        if [[ $in_deploy -eq 1 ]]; then
            # Look for a 40-char hex SHA anywhere on the row (Tag column or Notes)
            local sha_candidate
            sha_candidate=$(echo "$line" | grep -oE '[0-9a-f]{40}' | head -1) || sha_candidate=""
            if [[ -n "$sha_candidate" ]]; then
                recorded_sha="$sha_candidate"
                break
            fi
        fi
    done < "$state_md"

    if [[ -n "$recorded_sha" ]]; then
        # Attempt fetch (best-effort; failure is tolerated — conservative fail)
        git -C "$REPO_ROOT" fetch origin >/dev/null 2>&1 || true

        if git -C "$REPO_ROOT" merge-base --is-ancestor "$recorded_sha" origin/master >/dev/null 2>&1; then
            echo "pass"
            return 0
        else
            echo "fail:SHA not ancestor of origin/master"
            return 0
        fi
    fi

    # No PR recorded, no SHA recorded → conservative fail
    echo "fail:no PR number and no merge SHA recorded in STATE.md"
}

# ---------------------------------------------------------------------------
# Signal (ii): STATE.md concluded
#
# compute_signal_ii <folder_name>
# Returns via stdout: "pass" or "fail:<reason>"
#
# Passes iff:
#   - > **Status:** Deployed  (top-level status blockquote)
#   - AND >= 1 ## Deploy Status row has non-empty PR + terminal State
# ---------------------------------------------------------------------------
compute_signal_ii() {
    local folder_name="$1"
    local state_md="${AID_DIR}/${folder_name}/STATE.md"

    [[ ! -f "$state_md" ]] && { echo "fail:no STATE.md"; return 0; }

    # Check top-level > **Status:** Deployed
    local status_line
    status_line=$(grep -m1 '^> \*\*Status:\*\*' "$state_md" 2>/dev/null) || status_line=""
    if [[ -z "$status_line" ]]; then
        echo "fail:no top-level > **Status:** found"
        return 0
    fi
    local status_val
    status_val=$(echo "$status_line" | sed 's/^> \*\*Status:\*\* *//')
    if [[ "$status_val" != "Deployed" ]]; then
        echo "fail:STATUS is '${status_val}' (not Deployed)"
        return 0
    fi

    # Check >= 1 ## Deploy Status table row with terminal State + non-empty PR
    local in_deploy=0
    local found_terminal=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "^## Deploy Status"; then
            in_deploy=1
            continue
        fi
        if [[ $in_deploy -eq 1 ]] && echo "$line" | grep -q "^## "; then
            break
        fi
        if [[ $in_deploy -eq 1 ]]; then
            # Table row: | Delivery | State | PR | ...
            # State is field 3, PR is field 4 (1-indexed after leading |)
            local row_state row_pr
            row_state=$(echo "$line" | awk -F'|' 'NF>=4 { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3 }')
            row_pr=$(echo "$line" | awk -F'|' 'NF>=4 { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4 }')
            # Terminal states (case-insensitive check)
            local lc_state
            lc_state=$(echo "$row_state" | tr '[:upper:]' '[:lower:]')
            if [[ -n "$row_pr" && "$row_pr" != "PR" && "$row_pr" != "—" && "$row_pr" != "-" ]]; then
                case "$lc_state" in
                    merged|deployed|done|complete|completed)
                        found_terminal=1
                        break
                        ;;
                esac
            fi
        fi
    done < "$state_md"

    if [[ $found_terminal -eq 1 ]]; then
        echo "pass"
    else
        echo "fail:no terminal Deploy Status row found (no non-empty PR with Merged/Deployed state)"
    fi
}

# ---------------------------------------------------------------------------
# compute_status_note <folder_name>
# Print the work's top-level `> **Status:**` value (informational context shown
# in the explicit-confirm prompt). Never gates; just informs the user.
# ---------------------------------------------------------------------------
compute_status_note() {
    local state_md="${AID_DIR}/$1/STATE.md"
    [[ -f "$state_md" ]] || { echo "no STATE.md"; return 0; }
    local s
    s=$(grep -m1 '^> \*\*Status:\*\*' "$state_md" 2>/dev/null | sed 's/^> \*\*Status:\*\* *//')
    [[ -n "$s" ]] && echo "$s" || echo "status unknown"
}

# ---------------------------------------------------------------------------
# S6: .aid/work-*/ folders
# Every work folder is offered (never silently hidden); the (i)/(ii) signals are
# informational context only. The single hard exclusion is the work folder whose
# branch is currently checked out (is_active_folder). The user confirms each.
# ---------------------------------------------------------------------------
scan_s6() {
    local folder_path
    for folder_path in "${AID_DIR}"/work-*/; do
        [[ -d "$folder_path" ]] || continue
        local folder_name
        folder_name=$(basename "$folder_path")

        # Active-folder exclusion: only the work folder whose branch is currently
        # checked out is hard-skipped (don't offer to delete your active checkout).
        # Everything else is ALWAYS offered — "the user has the last word."
        if is_active_folder "$folder_name"; then
            warn "S6: skipping active folder (current branch): $folder_name"
            continue
        fi

        # Compute signals — these are now INFORMATIONAL context only; they no
        # longer GATE whether a folder is offered. Every work folder is surfaced
        # and the user confirms (or declines) each one. No merge proof is required.
        local sig_i sig_ii
        sig_i=$(compute_signal_i "$folder_name")
        sig_ii=$(compute_signal_ii "$folder_name")

        local tracked
        tracked=$(classify_tracked "$folder_path")

        if [[ "$sig_i" == "pass" && "$sig_ii" == "pass" ]]; then
            # Merged + concluded → clear-cut: offer unchecked in the main checklist.
            emit_candidate "$folder_path" "1" "$tracked" "false" \
                "S6: work folder merged+concluded" "offer"

        elif [[ "$sig_i" == "pass" ]]; then
            # Merged but STATE not concluded → explicit per-folder confirm.
            local why="${sig_ii#fail:}"
            emit_candidate "$folder_path" "1" "$tracked" "false" \
                "S6: work folder merged but STATE not concluded" \
                "explicit-confirm:${why}"

        else
            # Merge could not be auto-verified → STILL offer, via explicit per-folder
            # confirm (never silently hidden). The user decides with full context.
            local why_i="${sig_i#fail:}"
            local why_ii; why_ii="$(compute_status_note "$folder_name")"
            emit_candidate "$folder_path" "1" "$tracked" "false" \
                "S6: work folder — merge unverified (${why_i})" \
                "explicit-confirm:merge could not be auto-verified (${why_i}); STATE: ${why_ii}. Confirm only if this work is finished and its content is safely on master."
        fi
    done
}

# ---------------------------------------------------------------------------
# Tier-2: loose .aid/ files matching none of S1–S5
# Hand-authored-looking files found directly under .aid/ (not in subdirs
# that are covered by S1–S5 or S6).
# ---------------------------------------------------------------------------
scan_tier2() {
    # Only direct children of .aid/ that are files
    local path
    for path in "${AID_DIR}"/*; do
        [[ -e "$path" ]] || continue
        [[ -f "$path" ]] || continue  # directories handled by other scans or S6

        local filename
        filename=$(basename "$path")

        # Skip known system files
        case "$filename" in
            settings.yml) continue ;;  # must never be touched
        esac

        # Skip files covered by S4
        case "$filename" in
            verify-deterministic-report.json|verify-advisory-report.json) continue ;;
        esac

        local tracked
        tracked=$(classify_tracked "$path")
        emit_candidate "$path" "2" "$tracked" "false" \
            "Tier-2: loose .aid/ file (hand-authored, not in a known scan root)"
    done
}

# ---------------------------------------------------------------------------
# Main scan
# ---------------------------------------------------------------------------
scan_s1
scan_s2
scan_s3
scan_s4
scan_s5
scan_s6
scan_tier2
