#!/usr/bin/env bash
# enumerate-works.sh -- list AID works across the main tree AND every git worktree.
#
# Purpose:
#   The shared enumeration primitive behind the Work Initiation Gate
#   (canonical/aid/templates/work-initiation-gate.md): "what works already
#   exist?" -- scanned across the main tree and every persistent git worktree,
#   so every work-starter decides new-vs-continuation from one definition of
#   the answer.
#
#   This MIRRORS the dashboard reader's already-proven cross-worktree routine
#   (dashboard/reader/locator.py `enumerate_worktree_roots` ->
#   dashboard/reader/derivation.py `run_worktree_list`): the same fixed-argv,
#   no-shell, git-toplevel-guarded, 2s-bounded `git -C <root> worktree list
#   --porcelain` parse, degrading to main-tree-only on any git failure. It is a
#   deliberate MIRROR, not an import -- skills are prose+bash and cannot call the
#   Python reader, so worktree discovery has two implementations of ONE behavior.
#
#   For each discovered root it lists the direct subfolders of <root>/.aid/works/
#   (the container from Concern A) and surfaces, per work:
#     id / phase / lifecycle / branch-label / title.
#
# Usage:
#   enumerate-works.sh [--root REPO_ROOT]
#       --root REPO_ROOT   Repo root whose .aid/works/ (and worktrees) to scan.
#                          Default: the current directory.
#   enumerate-works.sh -h | --help
#
# Output (stdout): one TAB-separated record per work, ONE line each --
#     <work_id>\t<phase>\t<lifecycle>\t<branch_label>\t<title>
#   Fields that cannot be resolved are emitted as the literal "--".
#   NO records are emitted when no works exist across any root -- an empty
#   stdout is exactly the "empty/absent .aid/works/ -> NEW, no prompt" signal
#   the gate keys on. Records are ordered per root (main worktree first), and
#   lexicographically by work id within each root (same order the reader uses).
#
#   This is the ENUMERATE layer only (mirroring the reader's per-root
#   enumerate_worktree_roots + works listing) -- it does NOT reconcile. A work
#   that was committed and is thus checked out in more than one worktree appears
#   once PER branch label it is present on (the reader's separate higher-level
#   RECONCILE pass, which this helper deliberately does not mirror, is what
#   dedupes those). The gate consumes the raw records and groups by work id for
#   display (work-initiation-gate.md).
#
#   stderr: diagnostics only (e.g. a one-line note when git degradation kicks
#   in); never mixed into stdout.
#
# Exit codes:
#   0  success (the record list -- possibly empty -- was emitted)
#   2  argument error (unknown flag / missing value)
#   NB: git absence / non-git dir / timeout are NOT errors -- the helper
#       degrades to main-tree-only and still exits 0 (never fail the caller).
#
# Read-only: no writes, no git mutation. The only git verbs used are the
# read-only rev-parse / symbolic-ref / worktree-list (all hard-coded argv;
# no shell, no user-supplied string executed) -- the identical safe-by-
# construction set the reader restricts itself to.

set -euo pipefail

GIT_TIMEOUT_S=2
ROOT="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root) [[ $# -lt 2 ]] && { echo "enumerate-works.sh: --root requires a value" >&2; exit 2; }
                ROOT="$2"; shift 2 ;;
        -h|--help)
            cat <<'HELP'
enumerate-works.sh -- list AID works across the main tree and every git worktree.

Usage:
  enumerate-works.sh [--root REPO_ROOT]
    --root REPO_ROOT   Repo root to scan (default: current directory).

Output (stdout): one TAB-separated record per work:
  <work_id>\t<phase>\t<lifecycle>\t<branch_label>\t<title>
Empty stdout means no works exist anywhere (the gate's "-> NEW, no prompt").
Git absent / non-git / timeout: degrades to main-tree-only, still exits 0.
HELP
            exit 0 ;;
        *) echo "enumerate-works.sh: unknown flag: $1" >&2; exit 2 ;;
    esac
done

# ---------------------------------------------------------------------------
# Bounded, read-only git runner. Mirrors the reader's fixed-argv / no-shell /
# 2s-timeout pattern (derivation.py). stderr is suppressed; returns git's exit
# status (or 124 from `timeout`). Never mutates; only read-only verbs are ever
# passed by this script's own call sites.
#   _git_bounded <dir> <verb> [args...]
# ---------------------------------------------------------------------------
_git_bounded() {
    local dir="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${GIT_TIMEOUT_S}s" git -C "$dir" "$@" 2>/dev/null
    else
        git -C "$dir" "$@" 2>/dev/null
    fi
}

# _is_git_toplevel <dir> -> 0 if <dir> IS the git worktree toplevel (not merely
# a subdirectory of one). Guards against a nested fixture dir inheriting an
# enclosing repo's worktrees -- the same guard the reader applies before
# `worktree list`. False on any failure (git absent / non-git / timeout).
_is_git_toplevel() {
    local dir="$1" top rp_top rp_dir
    top="$(_git_bounded "$dir" rev-parse --show-toplevel)" || return 1
    [[ -n "$top" ]] || return 1
    rp_top="$(cd "$top" 2>/dev/null && pwd -P)" || return 1
    rp_dir="$(cd "$dir" 2>/dev/null && pwd -P)" || return 1
    [[ "$rp_top" == "$rp_dir" ]]
}

# _main_branch_label <dir> -> the current branch name, else the literal "main".
# The fallback label for main-tree-only degradation (twin of the reader's
# detect_main_branch_label).
_main_branch_label() {
    local dir="$1" label
    label="$(_git_bounded "$dir" symbolic-ref --short HEAD)" || label=""
    if [[ -n "$label" ]]; then printf '%s' "$label"; else printf 'main'; fi
}

# _frontmatter_value <state-file> <key> -> the value of a top-level frontmatter
# scalar (e.g. phase / lifecycle). Reads only the YAML block delimited by the
# leading `---` fences; strips surrounding quotes + inline `#` comments. Empty
# output if absent (caller substitutes "--").
_frontmatter_value() {
    local file="$1" key="$2"
    [[ -f "$file" ]] || return 0
    awk -v key="$key" '
        NR==1 && $0=="---" { infm=1; next }
        infm && $0=="---" { exit }
        infm && $0 ~ "^"key":" {
            sub("^"key":[[:space:]]*", "")
            sub("[[:space:]]+#.*$", "")
            gsub("^[\"\047]|[\"\047]$", "")
            print
            exit
        }
    ' "$file" 2>/dev/null || true
}

# _work_title <work-dir> -> the work's title/objective, from REQUIREMENTS.md's
# `**Name:**` identity line. Empty if absent or still a `*(pending)*` placeholder
# (caller substitutes "--"). Any embedded TAB is flattened to a space so the
# record stays single-field-per-column.
_work_title() {
    local work="$1" req="$1/REQUIREMENTS.md" t=""
    if [[ -f "$req" ]]; then
        t="$(awk '
            /\*\*Name:\*\*/ {
                sub(/^.*\*\*Name:\*\*[[:space:]]*/, "")
                print
                exit
            }' "$req" 2>/dev/null || true)"
    fi
    case "$t" in
        '*(pending)*'|'') t="" ;;
    esac
    t="${t//$'\t'/ }"
    printf '%s' "$t"
}

# ---------------------------------------------------------------------------
# Build the (branch_label \t aid_dir) root list, mirroring the reader's
# enumerate_worktree_roots. Main worktree is always first. Degrade to
# main-tree-only on any git failure.
# ---------------------------------------------------------------------------
main_aid="$ROOT/.aid"
main_label="$(_main_branch_label "$ROOT")"

porcelain=""
if _is_git_toplevel "$ROOT"; then
    porcelain="$(_git_bounded "$ROOT" worktree list --porcelain)" || porcelain=""
fi

ROOTS=()
if [[ -n "$porcelain" ]]; then
    cur_path=""; cur_branch=""
    while IFS= read -r raw || [[ -n "$raw" ]]; do
        line="${raw%$'\r'}"
        if [[ -z "$line" ]]; then
            if [[ -n "$cur_path" ]]; then
                lbl="$cur_branch"; [[ -z "$lbl" ]] && lbl="(detached)"
                ROOTS+=("$lbl"$'\t'"$cur_path/.aid")
            fi
            cur_path=""; cur_branch=""
            continue
        fi
        case "$line" in
            "worktree "*)
                if [[ -n "$cur_path" ]]; then
                    lbl="$cur_branch"; [[ -z "$lbl" ]] && lbl="(detached)"
                    ROOTS+=("$lbl"$'\t'"$cur_path/.aid")
                    cur_branch=""
                fi
                cur_path="${line#worktree }"
                ;;
            "branch refs/heads/"*)
                cur_branch="${line#branch refs/heads/}"
                ;;
        esac
    done <<< "$porcelain"
    if [[ -n "$cur_path" ]]; then
        lbl="$cur_branch"; [[ -z "$lbl" ]] && lbl="(detached)"
        ROOTS+=("$lbl"$'\t'"$cur_path/.aid")
    fi
fi

# Degrade: nothing parsed (git absent / non-git / timeout / empty) -> main only.
if [[ ${#ROOTS[@]} -eq 0 ]]; then
    echo "enumerate-works.sh: git worktree enumeration unavailable; scanning main tree only" >&2
    ROOTS+=("$main_label"$'\t'"$main_aid")
fi

# ---------------------------------------------------------------------------
# For each root, list the direct subfolders of <aid_dir>/works/ and emit one
# record per work. Sorted lexicographically within each root (glob default).
# ---------------------------------------------------------------------------
for entry in "${ROOTS[@]}"; do
    label="${entry%%$'\t'*}"
    aid_dir="${entry#*$'\t'}"
    works_dir="$aid_dir/works"
    [[ -d "$works_dir" ]] || continue
    for work_path in "$works_dir"/*/; do
        [[ -d "$work_path" ]] || continue
        work_path="${work_path%/}"
        work_id="$(basename "$work_path")"
        state_file="$work_path/STATE.md"
        phase="$(_frontmatter_value "$state_file" phase)"
        lifecycle="$(_frontmatter_value "$state_file" lifecycle)"
        title="$(_work_title "$work_path")"
        printf '%s\t%s\t%s\t%s\t%s\n' \
            "$work_id" \
            "${phase:---}" \
            "${lifecycle:---}" \
            "${label:---}" \
            "${title:---}"
    done
done
