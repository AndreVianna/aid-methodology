#!/usr/bin/env bash
# delete-pipeline.sh -- guarded destructive writer for the pipeline.delete op
# (feature-009-pipeline-delete, work-017 task-024).
#
# The ONLY component that performs a pipeline delete. Removes a work's
# on-disk artifacts worktree-aware: the work folder .aid/works/<work_id>, and
# -- ONLY when that folder occupies a DEDICATED (single-work) non-main
# worktree -- the worktree itself, via `git worktree remove --force`. The git
# BRANCH is NEVER touched (OQ-PL3: it is the sole recovery anchor; worktree
# removal stays reversible via `git worktree add <path> <branch>`, whereas
# branch deletion is not).
#
# Dispatched by the dashboard server's `pipeline.delete` op (OP_TABLE row +
# argv-builder added by task-025 -- this task ships ONLY the writer, unchanged
# by any server/UI edit). Also directly scriptable.
#
# Usage:
#   delete-pipeline.sh --work-id <work_id>     [env AID_REPO_ROOT=<abs repo root>]
#   delete-pipeline.sh -h | --help
#
# <work_id> is the FULL work-folder name (e.g. work-017-cli-improvements),
# validated ^work-[0-9]+(-[a-z0-9][a-z0-9-]*)?$ -- a defense-in-depth backstop:
# the server already validated work_id regex+length and rejected a non-empty
# `args` inline BEFORE spawning this writer (feature-009 SPEC.md Sec API
# Contracts / Sec Feature Flow steps 6-7).
#
# AID_REPO_ROOT defaults to $PWD. It may be ANY worktree root of the repo
# (main or a linked worktree) -- `git worktree list --porcelain` returns the
# SAME full worktree set no matter which checkout it is invoked from, so the
# enumeration below is correct either way.
#
# Algorithm (mirrors dashboard/reader/locator.py `enumerate_worktree_roots`,
# dashboard/reader/reader.py `_reconcile_same_work` / `resolve_work_dir`
# (WT-1), and the bash mirror .claude/aid/scripts/works/enumerate-works.sh):
#   1. Parse args; missing --work-id -> 5; invalid work_id shape -> 4.
#   2. REPO="${AID_REPO_ROOT:-$PWD}".
#   3. Enumerate worktree roots via `git -C "$REPO" worktree list --porcelain`
#      (main worktree always first, always included; degrade to main-only on
#      ANY git failure -- git absent / non-git / timeout / parse failure).
#   4. FOUND = every root R where -d "$R/.aid/works/<work_id>". Empty -> 1.
#   5. Select the SINGLE reconciled winner $W among FOUND: newest STATE.md
#      frontmatter `updated` wins; tie -> branch_label lexical, "main" first
#      -- the SAME rule `_reconcile_same_work` / `resolve_work_dir` use, so
#      $W is exactly the copy the reader rendered / the dashboard confirmed.
#      Only $W is removed -- a work_id shadowed in another worktree is left
#      untouched (WT-1 symmetry).
#   6. Guards (before ANY removal), evaluated on $W:
#        - Running guard: $W/.aid/works/<work_id>/STATE.md frontmatter
#          `lifecycle` == Running -> 7 (no removal).
#        - Current-worktree guard: $W is non-main AND its realpath equals
#          the realpath of `git -C "$PWD" rev-parse --show-toplevel` -> 7
#          (never remove the worktree this process is running from; the
#          main worktree is never a removal target).
#   7. Removal of $W (best-effort sentinel lock on the work folder first,
#      writeback-state.sh style; contention -> 2):
#        - Containment check: realpath of $W/.aid/works/<work_id> MUST be a
#          child of realpath $W/.aid/works/ (defeats symlink/".." traversal)
#          -- else 3.
#        - $W is main                    -> rm -rf the folder only (the main
#          worktree is never removed).
#        - $W is a DEDICATED non-main worktree -- its .aid/works/ holds ONLY
#          <work_id>, decided by CONTENT, never by a path-name match (a
#          persistent worktree may be registered at any user-chosen path) --
#          -> `git -C "$REPO" worktree remove --force -- "$W"` (removes
#          folder + worktree together; git auto-cleans .git/worktrees/<name>).
#        - $W is a SHARED non-main worktree (hosts other works too)
#          -> rm -rf the folder only (sibling works untouched).
#   8. Verify: the removed folder must no longer exist -- residue -> 3.
#   9. Branch: never touched (retained -- OQ-PL3).
#  10. Print `OK: deleted <work_id> (folder[, worktree <path>])`; exit 0.
#
# Exit codes (feeds feature-001's exit->HTTP map + the exit-7 row task-025
# adds):
#   0 -- deleted (folder[, worktree <path>])
#   1 -- work_id not found in any enumerated worktree root
#   2 -- lock contention (another writer holds the sentinel)
#   3 -- removal failed / post-removal residue / containment violation
#   4 -- invalid --work-id value (regex backstop)
#   5 -- missing --work-id
#   7 -- guard tripped (lifecycle=Running, or target is the current worktree)
#
# `set -euo pipefail` stays the dominant, UN-weakened strict mode throughout
# (this is an irreversible destructive op, not a case for a relaxed mode).
# Fixed-argv git only (`git -C <repo> ...`), no shell string, no `eval`, no
# body-supplied path -- every path the writer ever touches is built here from
# the regex-validated work_id and git's own worktree-list truth, never echoed
# from an untrusted caller. Every git call that can legitimately fail
# (worktree list, symbolic-ref, rev-parse) is guarded in an `if`/`||` so its
# expected non-zero exit degrades safely instead of tripping `set -e` --
# exactly the discipline enumerate-works.sh and dashboard/reader/derivation.py
# use -- rather than relaxing the whole script's strict mode.

set -euo pipefail

# Force byte-wise (locale-invariant) comparisons: the winner-selection string
# ordering (`[[ "$a" > "$b" ]]`), the branch_label lexical tie-break, and the
# ^work-[0-9]+... regex's [a-z0-9] classes must all behave deterministically
# regardless of the invoking environment's locale.
export LC_ALL=C

GIT_TIMEOUT_S=2

usage() {
    cat <<'HELP'
delete-pipeline.sh -- guarded destructive writer for the pipeline.delete op.

Usage:
  delete-pipeline.sh --work-id <work_id>   [env AID_REPO_ROOT=<abs repo root>]

<work_id> is the full work-folder name, validated
  ^work-[0-9]+(-[a-z0-9][a-z0-9-]*)?$

Removes .aid/works/<work_id> (worktree-aware) and, when that folder occupies
a dedicated non-main worktree, the worktree itself. The git branch is never
touched. See the file header for the full algorithm and exit-code alphabet.
HELP
}

# ---------------------------------------------------------------------------
# Bounded, read-only git runner + git-toplevel guard + branch-label detector.
# Mirrors the reader's fixed-argv / no-shell / 2s-timeout / degrade pattern
# (dashboard/reader/derivation.py) and enumerate-works.sh's own bash mirror.
# stderr is suppressed; only read-only verbs are ever passed by call sites in
# this section (the ONE mutating call -- `worktree remove --force` -- lives
# separately, below, where its exit code is checked explicitly).
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

# _is_git_toplevel <dir> -> 0 if <dir> IS the git worktree toplevel (not
# merely a subdirectory of one). Guards against a nested fixture/repo
# inheriting an enclosing repo's worktrees. False on any failure (git absent
# / non-git / timeout).
_is_git_toplevel() {
    local dir="$1" top rp_top rp_dir
    top="$(_git_bounded "$dir" rev-parse --show-toplevel)" || return 1
    [[ -n "$top" ]] || return 1
    rp_top="$(cd "$top" 2>/dev/null && pwd -P)" || return 1
    rp_dir="$(cd "$dir" 2>/dev/null && pwd -P)" || return 1
    [[ "$rp_top" == "$rp_dir" ]]
}

# _main_branch_label <dir> -> the current branch name, else the literal
# "main" (the fallback label used when git worktree enumeration degrades).
_main_branch_label() {
    local dir="$1" label
    label="$(_git_bounded "$dir" symbolic-ref --short HEAD)" || label=""
    if [[ -n "$label" ]]; then printf '%s' "$label"; else printf 'main'; fi
}

# _frontmatter_value <state-file> <key> -> the value of a top-level
# frontmatter scalar (e.g. lifecycle / updated). Reads only the YAML block
# delimited by the leading `---` fences; strips surrounding quotes + inline
# `#` comments. Empty output if absent. Verbatim mirror of enumerate-works.sh
# so a lifecycle/updated read here can never diverge from the skill-facing
# helper's own reading of the SAME frontmatter shape.
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

# ---------------------------------------------------------------------------
# 1. Parse args
# ---------------------------------------------------------------------------
WORK_ID=""
HAS_WORK_ID=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --work-id)
            if [[ $# -lt 2 ]]; then
                echo "delete-pipeline.sh: --work-id requires a value" >&2
                exit 5
            fi
            WORK_ID="$2"; HAS_WORK_ID=1; shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "delete-pipeline.sh: unknown flag: $1" >&2
            exit 5
            ;;
    esac
done

if [[ "$HAS_WORK_ID" -eq 0 ]]; then
    echo "delete-pipeline.sh: --work-id is required" >&2
    exit 5
fi

_RE_WORK_ID='^work-[0-9]+(-[a-z0-9][a-z0-9-]*)?$'
if ! [[ "$WORK_ID" =~ $_RE_WORK_ID ]]; then
    echo "delete-pipeline.sh: invalid --work-id '$WORK_ID'; must match ^work-[0-9]+(-[a-z0-9][a-z0-9-]*)?\$" >&2
    exit 4
fi

# ---------------------------------------------------------------------------
# 2. Resolve REPO
# ---------------------------------------------------------------------------
REPO="${AID_REPO_ROOT:-$PWD}"

# ---------------------------------------------------------------------------
# 3. Enumerate worktree roots (mirrors locator.py enumerate_worktree_roots).
#    Main worktree is always first, always included. Degrades to a single
#    main-only fallback root on ANY git failure.
# ---------------------------------------------------------------------------
ROOT_LABELS=()
ROOT_PATHS=()

main_label="$(_main_branch_label "$REPO")"

porcelain=""
if _is_git_toplevel "$REPO"; then
    porcelain="$(_git_bounded "$REPO" worktree list --porcelain)" || porcelain=""
fi

if [[ -n "$porcelain" ]]; then
    cur_path=""; cur_branch=""
    while IFS= read -r raw || [[ -n "$raw" ]]; do
        line="${raw%$'\r'}"
        if [[ -z "$line" ]]; then
            if [[ -n "$cur_path" ]]; then
                lbl="$cur_branch"; [[ -z "$lbl" ]] && lbl="(detached)"
                ROOT_LABELS+=("$lbl"); ROOT_PATHS+=("$cur_path")
            fi
            cur_path=""; cur_branch=""
            continue
        fi
        case "$line" in
            "worktree "*)
                if [[ -n "$cur_path" ]]; then
                    lbl="$cur_branch"; [[ -z "$lbl" ]] && lbl="(detached)"
                    ROOT_LABELS+=("$lbl"); ROOT_PATHS+=("$cur_path")
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
        ROOT_LABELS+=("$lbl"); ROOT_PATHS+=("$cur_path")
    fi
fi

if [[ ${#ROOT_PATHS[@]} -eq 0 ]]; then
    ROOT_LABELS+=("$main_label")
    ROOT_PATHS+=("$REPO")
fi

# ---------------------------------------------------------------------------
# 4. FOUND = every root holding .aid/works/<work_id>. Empty -> 1.
# ---------------------------------------------------------------------------
FOUND_LABELS=()
FOUND_PATHS=()
FOUND_UPDATED=()

for i in "${!ROOT_PATHS[@]}"; do
    wt="${ROOT_PATHS[$i]}"
    candidate="$wt/.aid/works/$WORK_ID"
    if [[ -d "$candidate" ]]; then
        upd="$(_frontmatter_value "$candidate/STATE.md" updated)"
        FOUND_LABELS+=("${ROOT_LABELS[$i]}")
        FOUND_PATHS+=("$wt")
        FOUND_UPDATED+=("$upd")
    fi
done

if [[ ${#FOUND_PATHS[@]} -eq 0 ]]; then
    echo "delete-pipeline.sh: work_id '$WORK_ID' not found in any enumerated worktree root" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 5. Select the single reconciled winner (the SAME rule as
#    _pipeline_winner_sort_key / _reconcile_same_work / resolve_work_dir):
#    newest `updated` wins; tie -> branch_label lexical, "main" first.
# ---------------------------------------------------------------------------
_winner_is_better() {
    # args: new_updated new_label best_updated best_label
    # Returns 0 (true) when the "new" candidate should replace "best".
    local nu="$1" nl="$2" bu="$3" bl="$4"
    if [[ -n "$nu" && -z "$bu" ]]; then return 0; fi
    if [[ -z "$nu" && -n "$bu" ]]; then return 1; fi
    if [[ -n "$nu" && -n "$bu" ]]; then
        if [[ "$nu" > "$bu" ]]; then return 0; fi
        if [[ "$nu" < "$bu" ]]; then return 1; fi
        # equal updated -> fall through to the label tie-break below
    fi
    # both absent, or equal `updated` -> branch_label tie-break, main first
    if [[ "$nl" == "main" && "$bl" != "main" ]]; then return 0; fi
    if [[ "$bl" == "main" && "$nl" != "main" ]]; then return 1; fi
    if [[ "$nl" < "$bl" ]]; then return 0; fi
    return 1
}

BEST_IDX=0
for ((i = 1; i < ${#FOUND_PATHS[@]}; i++)); do
    if _winner_is_better "${FOUND_UPDATED[$i]}" "${FOUND_LABELS[$i]}" \
                         "${FOUND_UPDATED[$BEST_IDX]}" "${FOUND_LABELS[$BEST_IDX]}"; then
        BEST_IDX=$i
    fi
done

W="${FOUND_PATHS[$BEST_IDX]}"
CANDIDATE="$W/.aid/works/$WORK_ID"

# is-main determination (git's own first-porcelain-record truth, never a
# path-name guess): compare realpaths so a differently-formed but identical
# path (e.g. an MSYS vs native form on Windows) still compares equal.
MAIN_PATH="${ROOT_PATHS[0]}"
MAIN_REAL="$(cd "$MAIN_PATH" 2>/dev/null && pwd -P)" || MAIN_REAL=""
W_REAL="$(cd "$W" 2>/dev/null && pwd -P)" || W_REAL=""

IS_MAIN=0
if [[ -n "$MAIN_REAL" && -n "$W_REAL" && "$W_REAL" == "$MAIN_REAL" ]]; then
    IS_MAIN=1
fi

# ---------------------------------------------------------------------------
# 6. Guards (before ANY removal)
# ---------------------------------------------------------------------------

# Running guard
LIFECYCLE="$(_frontmatter_value "$CANDIDATE/STATE.md" lifecycle)"
if [[ "$LIFECYCLE" == "Running" ]]; then
    echo "delete-pipeline.sh: '$WORK_ID' lifecycle=Running -- refusing to delete a running pipeline" >&2
    exit 7
fi

# Current-worktree guard: never remove the worktree this process itself runs
# from (the main worktree is never a removal target, so this only applies to
# a non-main winner).
if [[ "$IS_MAIN" -eq 0 ]]; then
    CUR="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" || CUR=""
    if [[ -n "$CUR" ]]; then
        CUR_REAL="$(cd "$CUR" 2>/dev/null && pwd -P)" || CUR_REAL=""
        if [[ -n "$CUR_REAL" && -n "$W_REAL" && "$CUR_REAL" == "$W_REAL" ]]; then
            echo "delete-pipeline.sh: '$WORK_ID' resolves to the worktree this process is running from -- refusing to remove it" >&2
            exit 7
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Classification BY CONTENT (never by a path-name match): main / dedicated
# (this worktree's .aid/works/ holds ONLY <work_id>) / shared (hosts others).
# ---------------------------------------------------------------------------
if [[ "$IS_MAIN" -eq 1 ]]; then
    CLASS="main"
else
    # dotglob: a work is ANY direct subfolder of .aid/works/ (locator.py
    # _enumerate_work_dirs enumerates via Path.iterdir(), which is NOT
    # name-filtered -- a dot-prefixed directory counts as a work there too).
    # Without dotglob, bash's `*/` glob silently skips dot-directories, which
    # could under-count and misclassify a worktree as "dedicated" (over-
    # deletion risk) when the Python reader would call it "shared".
    shopt -s dotglob
    count=0
    for d in "$W/.aid/works"/*/; do
        [[ -d "$d" ]] || continue
        count=$((count + 1))
    done
    shopt -u dotglob
    if [[ "$count" -le 1 ]]; then
        CLASS="dedicated"
    else
        CLASS="shared"
    fi
fi

# ---------------------------------------------------------------------------
# 7. Removal of $W -- sentinel lock first (contention -> 2), then containment
#    check (else -> 3), then the classification-appropriate removal.
# ---------------------------------------------------------------------------
LOCK_FILE="$CANDIDATE/.writeback-state.lock"
LOCK_TIMEOUT="${AID_LOCK_TIMEOUT:-10}"

# LOCK_ACQUIRED guards the release below so a contention exit (this process
# never actually held the sentinel) can NEVER delete another process's lock
# file -- same discipline as writeback-state.sh's acquire_lock/release_lock.
LOCK_ACQUIRED=0
_release_lock() {
    if [[ "$LOCK_ACQUIRED" -eq 1 ]]; then
        rm -f "$LOCK_FILE" 2>/dev/null || true
        LOCK_ACQUIRED=0
    fi
}
trap _release_lock EXIT

attempts=0
while true; do
    # Atomic create -- succeeds only if the sentinel does not already exist
    # (same noclobber idiom as writeback-state.sh's acquire_lock).
    if ( set -o noclobber; echo $$ > "$LOCK_FILE" ) 2>/dev/null; then
        LOCK_ACQUIRED=1
        break
    fi
    attempts=$((attempts + 1))
    if [[ "$attempts" -ge "$LOCK_TIMEOUT" ]]; then
        echo "delete-pipeline.sh: lock contention: $LOCK_FILE is held after ${attempts} retries. Another process is writing this pipeline. Try again." >&2
        exit 2
    fi
    sleep 0.5
done

# Containment check: realpath of $CANDIDATE MUST be a proper child of
# realpath $W/.aid/works/ (defeats a symlinked/".."-escaping work_id dir).
TARGET_REAL="$(cd "$CANDIDATE" 2>/dev/null && pwd -P)" || {
    echo "delete-pipeline.sh: cannot resolve realpath of $CANDIDATE" >&2
    exit 3
}
WORKS_DIR="$W/.aid/works"
WORKS_REAL="$(cd "$WORKS_DIR" 2>/dev/null && pwd -P)" || {
    echo "delete-pipeline.sh: cannot resolve realpath of $WORKS_DIR" >&2
    exit 3
}
case "$TARGET_REAL" in
    "$WORKS_REAL"/*)
        ;;
    *)
        echo "delete-pipeline.sh: containment check failed: $CANDIDATE (realpath $TARGET_REAL) escapes $WORKS_REAL" >&2
        exit 3
        ;;
esac

WT_REMOVED=""
case "$CLASS" in
    main|shared)
        rm -rf -- "$CANDIDATE" 2>/dev/null || true
        ;;
    dedicated)
        if ! git -C "$REPO" worktree remove --force -- "$W" 1>&2; then
            echo "delete-pipeline.sh: git worktree remove failed for $W" >&2
            exit 3
        fi
        WT_REMOVED="$W"
        ;;
esac

# ---------------------------------------------------------------------------
# 8. Verify: the removed folder must no longer exist. Residue -> 3.
# ---------------------------------------------------------------------------
if [[ -e "$CANDIDATE" ]]; then
    echo "delete-pipeline.sh: removal verification failed: $CANDIDATE still exists after removal" >&2
    exit 3
fi

# ---------------------------------------------------------------------------
# 9. Branch: never touched (retained -- OQ-PL3).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 10. Success.
# ---------------------------------------------------------------------------
if [[ -n "$WT_REMOVED" ]]; then
    echo "OK: deleted $WORK_ID (folder, worktree $WT_REMOVED)"
else
    echo "OK: deleted $WORK_ID (folder)"
fi
exit 0
