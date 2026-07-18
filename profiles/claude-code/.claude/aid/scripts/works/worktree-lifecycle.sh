#!/usr/bin/env bash
# worktree-lifecycle.sh -- create/locate the isolated git worktree for a work.
#
# Purpose:
#   The single shared implementation of the git-worktree mechanics every
#   worktree-consuming feature binds to (work-starting automation, downstream
#   locate-and-enter, housekeep teardown): create a work's worktree (branch
#   <work-id>, directory .claude/worktrees/<work-id>-<name>, off master) and
#   resolve-and-enter an existing one via the 4-rung "most-intact-state-first"
#   fallback ladder. This script is PURE GIT MECHANICS -- it never switches a
#   session; see canonical/aid/templates/worktree-lifecycle.md for the agent
#   host-switch contract that follows a call to this script.
#
# Usage:
#   worktree-lifecycle.sh create <work-id> <name> [--base <ref>]
#       <work-id>   the work id and branch name, e.g. work-018 (^work-[0-9]+$)
#       <name>      the work slug, e.g. worktree-isolation (single path segment)
#       --base <ref>  base ref for a fresh branch (default: master)
#   worktree-lifecycle.sh locate <work-id> [--name <slug>]
#       --name <slug>  directory-slug override (default: auto-derived)
#   worktree-lifecycle.sh -h | --help
#
# Output (stdout):
#   create   -- on success/no-op: exactly the worktree's absolute path, one
#                line, nothing else. On failure: EMPTY stdout.
#   locate   -- exactly one TAB-separated line: <absolute-path>\t<status>
#                where <status> is one of registered|recreated|created|current.
#                Split on TAB, never on space (a worktree path can contain
#                spaces).
#   stderr carries diagnostics only, one line per condition, prefixed
#   "worktree-lifecycle.sh:"; never mixed into stdout.
#
# Exit codes:
#   0  create: success or no-op (idempotent, keyed on the <work-id> branch).
#      locate: EVERY resolution, including the git-broken degrade -- locate
#              never fails the caller.
#   1  create ONLY: an isolated worktree could not be produced (a genuine
#      `git worktree add` failure, or git-absent / not-a-git-repo / a
#      target-dir collision surviving `git worktree prune`). create FAILS
#      CLOSED: empty stdout, one-line stderr diagnostic. locate NEVER returns
#      1 -- on the identical condition it degrades to `<cwd-abs>\tcurrent`
#      and still exits 0.
#   2  argument error (unknown operation/flag, missing positional) OR a
#      traversal-bearing / malformed <work-id> / <name> / --base value --
#      rejected before any git verb runs.
#
# Read-only vs mutating: read verbs (rev-parse, symbolic-ref, show-ref,
# worktree list) run under a 2s `timeout` bound and degrade gracefully on
# failure/timeout. Mutating verbs (`git worktree add`, `git worktree prune`)
# run UNBOUNDED so an add is never killed mid-operation; their own stdout and
# stderr are suppressed and replaced with this script's own one-line
# diagnostic on failure, so the stdout/stderr contract above always holds.
#
# The one non-git mutation this script performs is `locate` rung 3's
# work-folder relocate: a single guarded `mv` of the untracked
# .aid/works/<work-id>-<slug>/ folder from the current checkout into the
# freshly created worktree (git worktree add cannot carry untracked content).
# It runs only when the source exists and the target does not (never
# overwrites), and both endpoints are realpath-confined under their
# respective .aid/works/ before the move. No other destructive verb is used;
# teardown is exclusively feature-004 / aid-housekeep.

set -euo pipefail

SCRIPT_NAME="worktree-lifecycle.sh"
GIT_TIMEOUT_S=2

print_help() {
    cat <<'HELP'
worktree-lifecycle.sh -- create/locate a work's isolated git worktree.

Usage:
  worktree-lifecycle.sh create <work-id> <name> [--base <ref>]
  worktree-lifecycle.sh locate <work-id> [--name <slug>]
  worktree-lifecycle.sh -h | --help

create: prints the worktree's absolute path on stdout (nothing else) and
exits 0 on success/no-op; on failure, stdout is EMPTY and exit is 1 (fails
closed -- a NEW work must land in an isolated worktree).

locate: prints one TAB-separated line "<abs-path>\t<status>" where <status>
is registered|recreated|created|current, and exits 0 on EVERY resolution,
including a git-broken degrade to "<cwd-abs>\tcurrent" -- locate never fails
the caller.

Both operations exit 2 on an argument error, or on a traversal-bearing /
malformed <work-id> / <name> / --base value, before any git verb runs.

Entering the resolved worktree is an AGENT action (the claude-code
EnterWorktree tool, or a cwd-fallback with the path surfaced on hosts
without one) -- see .claude/aid/templates/worktree-lifecycle.md. This
script only prints the path; it never switches a session.
HELP
}

# ---------------------------------------------------------------------------
# Bounded, read-only git runner (mirrors enumerate-works.sh's helper). stderr
# is suppressed; returns git's exit status (or 124 from `timeout`). Only
# read-only verbs are ever passed by this script's own call sites.
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

# _abs_path <dir> -> THE single path-normalization resolver. Every absolute
# path this script ever emits (create's stdout; locate's field-1 for EVERY
# rung, including the degrade) -- and every internal path composition that
# feeds those emit sites -- is funneled through this one function, so the
# SAME directory always yields the IDENTICAL byte-string regardless of which
# rung resolved it.
#
# Why this is needed: on Windows, git's own path output (`git worktree list
# --porcelain`'s "worktree <path>" line, `git rev-parse --show-toplevel`)
# uses the Git-for-Windows form ("C:/Users/..."), while bash's `pwd -P` on
# the same MSYS/Git-Bash host uses the MSYS form ("/c/Users/...") -- two
# different byte-strings for the identical directory. Left unreconciled, a
# caller doing a literal string-equality check across two `locate`/`create`
# calls (e.g. the frozen idempotency contract's "re-prints the existing
# path") could see it change between calls depending on which rung answered.
#
# `pwd -P` (not git's own output) is the chosen convergence point: the
# degrade path cannot invoke git at all (that is why it is degrading), so it
# can ONLY ever produce a `pwd -P`-derived string -- every other emit site
# must converge on that same, git-independent form to match it. It is also
# what every subsequent bash file operation (`cd`, `mv`, `test -d`) already
# natively consumes/produces, and on non-Windows hosts it is byte-identical
# to git's own output anyway (no drive-letter distinction exists there), so
# this normalization is a zero-cost no-op off Windows.
#
# Empty + non-zero on failure (caller degrades/fails per its own contract).
_abs_path() {
    (cd "$1" 2>/dev/null && pwd -P)
}

# _is_git_toplevel <dir> -> 0 if <dir> IS the git worktree toplevel (not
# merely a subdirectory of one). False on any failure (git absent / non-git /
# timeout). Identical guard to enumerate-works.sh's.
_is_git_toplevel() {
    local dir="$1" top rp_top rp_dir
    top="$(_git_bounded "$dir" rev-parse --show-toplevel)" || return 1
    [[ -n "$top" ]] || return 1
    rp_top="$(_abs_path "$top")" || return 1
    rp_dir="$(_abs_path "$dir")" || return 1
    [[ "$rp_top" == "$rp_dir" ]]
}

# _main_root -> the absolute path of the repository's MAIN worktree (the one
# whose .claude/worktrees/ every work's worktree nests under), regardless of
# which worktree the script is currently running from. Derived from the
# shared git-common-dir (the one .git directory every worktree links back
# to): its parent is always the main worktree's root. Empty + non-zero on
# any git failure.
_main_root() {
    local gcd abs
    gcd="$(_git_bounded "." rev-parse --git-common-dir)" || return 1
    [[ -n "$gcd" ]] || return 1
    abs="$(_abs_path "$gcd")" || return 1
    dirname "$abs"
}

# _worktrees_root_from <main-root> -> the realpath-canonicalized, created
# .claude/worktrees/ container under <main-root>. Empty + non-zero on
# failure (e.g. cannot create the directory).
_worktrees_root_from() {
    local main_root="$1" wt_root
    wt_root="${main_root}/.claude/worktrees"
    mkdir -p "$wt_root" 2>/dev/null || return 1
    _abs_path "$wt_root"
}

# _worktree_path_for_branch <porcelain> <work-id> -> the absolute path of the
# registered worktree whose branch is refs/heads/<work-id>, parsed from
# `git worktree list --porcelain` output (mirrors enumerate-works.sh's
# porcelain parse). Empty + non-zero if no such record exists.
_worktree_path_for_branch() {
    local porcelain="$1" work_id="$2"
    local cur_path="" cur_branch="" raw line
    while IFS= read -r raw || [[ -n "$raw" ]]; do
        line="${raw%$'\r'}"
        if [[ -z "$line" ]]; then
            if [[ -n "$cur_path" && "$cur_branch" == "$work_id" ]]; then
                printf '%s' "$cur_path"; return 0
            fi
            cur_path=""; cur_branch=""
            continue
        fi
        case "$line" in
            "worktree "*)
                if [[ -n "$cur_path" && "$cur_branch" == "$work_id" ]]; then
                    printf '%s' "$cur_path"; return 0
                fi
                cur_path="${line#worktree }"
                cur_branch=""
                ;;
            "branch refs/heads/"*)
                cur_branch="${line#branch refs/heads/}"
                ;;
        esac
    done <<< "$porcelain"
    if [[ -n "$cur_path" && "$cur_branch" == "$work_id" ]]; then
        printf '%s' "$cur_path"; return 0
    fi
    return 1
}

# _confine_dir <dir> <root> -> 0 if <dir>'s parent is exactly <root> (both
# already-composed, already-validated absolute paths). The realpath-prefix
# backstop behind the "namespaced path" security claim -- structurally
# guaranteed by construction (work-id/name are traversal-free by the time
# they reach here), asserted again here in case a future edit skips upstream
# validation.
_confine_dir() {
    local dir="$1" root="$2"
    [[ "$(dirname "$dir")" == "$root" ]]
}

# ---------------------------------------------------------------------------
# Input validation (Security -- runs before any git verb that could mutate
# state; check-ref-format for --base is the one sanctioned exception, itself
# a pure format-check).
# ---------------------------------------------------------------------------
_valid_work_id() {
    [[ "$1" =~ ^work-[0-9]+$ ]]
}

_valid_slug() {
    local v="$1"
    [[ "$v" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || return 1
    case "$v" in
        *..*) return 1 ;;
    esac
    return 0
}

# ---------------------------------------------------------------------------
# locate's shared degrade: git cannot resolve any rung. Never fail the
# caller -- one-line stderr note, <cwd-abs>\tcurrent, exit 0.
# ---------------------------------------------------------------------------
_locate_degrade() {
    echo "${SCRIPT_NAME}: git unavailable or unrecoverable; operating in current directory" >&2
    printf '%s\tcurrent\n' "$(_abs_path ".")"
    exit 0
}

# ---------------------------------------------------------------------------
# create <work-id> <name> <base-ref>
# ---------------------------------------------------------------------------
op_create() {
    local work_id="$1" name="$2" base_ref="$3"

    # Preflight -- fail CLOSED (mirror of locate's degrade): a NEW work MUST
    # land in an isolated worktree.
    if ! _is_git_toplevel "."; then
        echo "${SCRIPT_NAME}: not a git repo; cannot isolate" >&2
        exit 1
    fi

    # Rung 4 -- already inside the target branch's own worktree: no-op.
    local cur_branch
    cur_branch="$(_git_bounded "." symbolic-ref --short HEAD)" || cur_branch=""
    if [[ "$cur_branch" == "$work_id" ]]; then
        local top
        top="$(_git_bounded "." rev-parse --show-toplevel)" || top=""
        if [[ -n "$top" ]]; then
            top="$(_abs_path "$top")" || top=""
        fi
        if [[ -n "$top" ]]; then
            printf '%s\n' "$top"
            exit 0
        fi
        echo "${SCRIPT_NAME}: cannot resolve current worktree path; cannot isolate" >&2
        exit 1
    fi

    # Rung 1 -- a worktree is already registered AND its directory exists:
    # idempotent no-op (NFR2), keyed on the <work-id> BRANCH, not on <name>.
    local porcelain path=""
    porcelain="$(_git_bounded "." worktree list --porcelain)" || porcelain=""
    if [[ -n "$porcelain" ]]; then
        path="$(_worktree_path_for_branch "$porcelain" "$work_id")" || path=""
    fi
    if [[ -n "$path" && -d "$path" ]]; then
        path="$(_abs_path "$path")" || { echo "${SCRIPT_NAME}: cannot resolve registered worktree path; cannot isolate" >&2; exit 1; }
        local existing_base
        existing_base="$(basename "$path")"
        if [[ "$existing_base" != "${work_id}-${name}" ]]; then
            echo "${SCRIPT_NAME}: create: worktree already exists at ${path} (branch ${work_id}); ignoring differing name '${name}'" >&2
        fi
        printf '%s\n' "$path"
        exit 0
    fi

    # Resolve the main worktree root + the .claude/worktrees/ container.
    local main_root worktrees_root
    main_root="$(_main_root)" || { echo "${SCRIPT_NAME}: cannot resolve repository root; cannot isolate" >&2; exit 1; }
    worktrees_root="$(_worktrees_root_from "$main_root")" || { echo "${SCRIPT_NAME}: cannot create worktrees container; cannot isolate" >&2; exit 1; }

    # Clear any stale registration before attempting an add (idempotent, safe).
    git worktree prune >/dev/null 2>&1 || true

    local dir
    dir="${worktrees_root}/${work_id}-${name}"
    _confine_dir "$dir" "$worktrees_root" || { echo "${SCRIPT_NAME}: computed path escapes the worktrees container; cannot isolate" >&2; exit 2; }

    # Rung 2 -- branch exists, no live worktree: recreate from the branch's
    # COMMITTED tree only (never re-branches, never loses committed work).
    if _git_bounded "." show-ref --verify --quiet "refs/heads/${work_id}"; then
        if ! git worktree add "$dir" "$work_id" >/dev/null 2>&1; then
            echo "${SCRIPT_NAME}: git worktree add failed; cannot isolate" >&2
            exit 1
        fi
        local resolved
        resolved="$(_abs_path "$dir")" || { echo "${SCRIPT_NAME}: cannot resolve created worktree path" >&2; exit 1; }
        printf '%s\n' "$resolved"
        exit 0
    fi

    # Rung 3 (create's "fresh" case) -- neither worktree nor branch exists:
    # branch a fresh worktree off <base-ref> (default master). create never
    # relocates -- a NEW work has no prior folder to migrate; the starter
    # scaffolds .aid/works/<work-id>-<name>/ inside the new worktree after.
    if ! git worktree add -b "$work_id" "$dir" "$base_ref" >/dev/null 2>&1; then
        echo "${SCRIPT_NAME}: git worktree add failed; cannot isolate" >&2
        exit 1
    fi
    local resolved
    resolved="$(_abs_path "$dir")" || { echo "${SCRIPT_NAME}: cannot resolve created worktree path" >&2; exit 1; }
    printf '%s\n' "$resolved"
    exit 0
}

# ---------------------------------------------------------------------------
# locate <work-id> <name-override-or-empty>
# ---------------------------------------------------------------------------
op_locate() {
    local work_id="$1" name_override="$2"

    # Preflight -- DEGRADE, never fail the caller.
    _is_git_toplevel "." || _locate_degrade

    # Rung 4 -- already inside the target branch's own worktree.
    local cur_branch
    cur_branch="$(_git_bounded "." symbolic-ref --short HEAD)" || cur_branch=""
    if [[ "$cur_branch" == "$work_id" ]]; then
        local top
        top="$(_git_bounded "." rev-parse --show-toplevel)" || top=""
        if [[ -n "$top" ]]; then
            top="$(_abs_path "$top")" || top=""
        fi
        if [[ -n "$top" ]]; then
            printf '%s\tcurrent\n' "$top"
            exit 0
        fi
        _locate_degrade
    fi

    # Rung 1 -- registered worktree whose directory still exists.
    local porcelain path=""
    porcelain="$(_git_bounded "." worktree list --porcelain)" || porcelain=""
    if [[ -n "$porcelain" ]]; then
        path="$(_worktree_path_for_branch "$porcelain" "$work_id")" || path=""
    fi
    if [[ -n "$path" && -d "$path" ]]; then
        path="$(_abs_path "$path")" || _locate_degrade
        printf '%s\tregistered\n' "$path"
        exit 0
    fi

    # Resolve the main worktree root + the .claude/worktrees/ container.
    local main_root worktrees_root
    main_root="$(_main_root)" || _locate_degrade
    worktrees_root="$(_worktrees_root_from "$main_root")" || _locate_degrade

    # Clear any stale registration before attempting an add.
    git worktree prune >/dev/null 2>&1 || true

    # Rung 2 -- branch-only recreate from the COMMITTED tree. No slug source
    # (.aid/works/ is never committed) unless --name overrides it: falls
    # back to the bare <work-id> directory. Performs NO relocate.
    if _git_bounded "." show-ref --verify --quiet "refs/heads/${work_id}"; then
        local dir_name dir
        if [[ -n "$name_override" ]]; then
            dir_name="${work_id}-${name_override}"
        else
            dir_name="$work_id"
        fi
        dir="${worktrees_root}/${dir_name}"
        _confine_dir "$dir" "$worktrees_root" || { echo "${SCRIPT_NAME}: computed path escapes the worktrees container" >&2; exit 2; }

        if ! git worktree add "$dir" "$work_id" >/dev/null 2>&1; then
            _locate_degrade
        fi
        local resolved
        resolved="$(_abs_path "$dir")" || _locate_degrade
        printf '%s\trecreated\n' "$resolved"
        exit 0
    fi

    # Rung 3 -- neither branch nor worktree: derive the slug from the local
    # untracked .aid/works/<work-id>-*/ folder (unless --name overrides),
    # branch a fresh worktree off HEAD, then RELOCATE that folder into it
    # (git worktree add cannot carry untracked content).
    local slug="" folder=""
    if [[ -n "$name_override" ]]; then
        slug="$name_override"
    else
        local d base
        for d in "${main_root}"/.aid/works/"${work_id}"-*/; do
            [[ -d "$d" ]] || continue
            base="$(basename "$d")"
            slug="${base#${work_id}-}"
            folder="$d"
            break
        done
    fi

    if [[ -n "$slug" ]] && ! _valid_slug "$slug"; then
        echo "${SCRIPT_NAME}: derived work-folder name fails path-confinement validation" >&2
        exit 2
    fi

    local dir_name dir
    if [[ -n "$slug" ]]; then
        dir_name="${work_id}-${slug}"
    else
        dir_name="$work_id"
    fi
    dir="${worktrees_root}/${dir_name}"
    _confine_dir "$dir" "$worktrees_root" || { echo "${SCRIPT_NAME}: computed path escapes the worktrees container" >&2; exit 2; }

    if ! git worktree add -b "$work_id" "$dir" HEAD >/dev/null 2>&1; then
        _locate_degrade
    fi

    # Guarded relocate: source exists, target absent (never overwrite), both
    # realpath-confined under their respective .aid/works/.
    if [[ -n "$folder" ]]; then
        local src_real dst
        src_real="$(_abs_path "$folder")" || src_real=""
        case "$src_real" in
            "${main_root}/.aid/works/"*) ;;
            *) src_real="" ;;
        esac
        if [[ -n "$src_real" ]]; then
            dst="${dir}/.aid/works/$(basename "$src_real")"
            case "$dst" in
                "${dir}/.aid/works/"*) ;;
                *) dst="" ;;
            esac
        fi
        if [[ -n "$src_real" && -n "$dst" && -e "$src_real" && ! -e "$dst" ]]; then
            mkdir -p "$(dirname "$dst")" 2>/dev/null || true
            if ! mv "$src_real" "$dst" 2>/dev/null; then
                echo "${SCRIPT_NAME}: warning: could not relocate work folder into new worktree" >&2
            fi
        elif [[ -n "$src_real" && -n "$dst" && -e "$dst" ]]; then
            echo "${SCRIPT_NAME}: warning: target work folder already populated; skipped relocate" >&2
        fi
    fi

    local resolved
    resolved="$(_abs_path "$dir")" || _locate_degrade
    printf '%s\tcreated\n' "$resolved"
    exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing (validate before any git verb runs -- Security).
# ---------------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
    echo "${SCRIPT_NAME}: missing operation (create|locate); see --help" >&2
    exit 2
fi

case "$1" in
    -h|--help) print_help; exit 0 ;;
esac

OP="$1"; shift

case "$OP" in
    create)
        [[ $# -ge 1 ]] || { echo "${SCRIPT_NAME}: create requires <work-id> <name>" >&2; exit 2; }
        WORK_ID="$1"; shift
        [[ $# -ge 1 ]] || { echo "${SCRIPT_NAME}: create requires <name>" >&2; exit 2; }
        NAME="$1"; shift

        BASE_REF="master"
        BASE_GIVEN=0
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --base)
                    [[ $# -ge 2 ]] || { echo "${SCRIPT_NAME}: --base requires a value" >&2; exit 2; }
                    BASE_REF="$2"; BASE_GIVEN=1; shift 2 ;;
                -h|--help) print_help; exit 0 ;;
                *) echo "${SCRIPT_NAME}: unknown argument: $1" >&2; exit 2 ;;
            esac
        done

        _valid_work_id "$WORK_ID" || { echo "${SCRIPT_NAME}: invalid <work-id>: ${WORK_ID}" >&2; exit 2; }
        _valid_slug "$NAME" || { echo "${SCRIPT_NAME}: invalid <name>: ${NAME}" >&2; exit 2; }
        if [[ $BASE_GIVEN -eq 1 ]]; then
            git check-ref-format "refs/heads/${BASE_REF}" >/dev/null 2>&1 || { echo "${SCRIPT_NAME}: invalid --base ref: ${BASE_REF}" >&2; exit 2; }
        fi

        op_create "$WORK_ID" "$NAME" "$BASE_REF"
        ;;
    locate)
        [[ $# -ge 1 ]] || { echo "${SCRIPT_NAME}: locate requires <work-id>" >&2; exit 2; }
        WORK_ID="$1"; shift

        NAME_OVERRIDE=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --name)
                    [[ $# -ge 2 ]] || { echo "${SCRIPT_NAME}: --name requires a value" >&2; exit 2; }
                    NAME_OVERRIDE="$2"; shift 2 ;;
                -h|--help) print_help; exit 0 ;;
                *) echo "${SCRIPT_NAME}: unknown argument: $1" >&2; exit 2 ;;
            esac
        done

        _valid_work_id "$WORK_ID" || { echo "${SCRIPT_NAME}: invalid <work-id>: ${WORK_ID}" >&2; exit 2; }
        if [[ -n "$NAME_OVERRIDE" ]]; then
            _valid_slug "$NAME_OVERRIDE" || { echo "${SCRIPT_NAME}: invalid --name: ${NAME_OVERRIDE}" >&2; exit 2; }
        fi

        op_locate "$WORK_ID" "$NAME_OVERRIDE"
        ;;
    *)
        echo "${SCRIPT_NAME}: unknown operation: ${OP}" >&2
        exit 2
        ;;
esac
