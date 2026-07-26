#!/usr/bin/env bash
# branch-commit.sh — ensure the aid/housekeep-<slug> branch and commit one stage.
#
# Purpose:
#   Two operations in one helper, used by the /aid-housekeep skill:
#
#   1. branch-ensure  — reads the current branch via `git rev-parse --abbrev-ref HEAD`.
#      If the current branch is `master`, creates and switches to `aid/housekeep-<slug>`
#      (off the current master HEAD) via `git switch -c`.  If already on a branch whose
#      name starts with `aid/housekeep-`, reuses it (resume case).  Refuses to operate
#      on `master` directly (exits non-zero with an error message).
#
#   2. stage-commit   — stages the supplied paths (`git add`) and makes exactly one
#      commit with the supplied message (`git commit`).  Never runs `git push`.
#
# Usage:
#   branch-commit.sh --ensure-branch --slug <slug>
#       Ensure an aid/housekeep-<slug> branch exists; switch to it if needed.
#
#   branch-commit.sh --commit --message <msg> [--add <path> ...]
#       Stage the listed paths (default: all tracked changes via --add-all)
#       and make ONE commit with the given message.  At least one --add path
#       OR --add-all is required.
#
#   branch-commit.sh --ensure-branch --slug <slug> --commit --message <msg> [--add <path> ...]
#       Combine: ensure the branch, then commit.
#
# Exit codes:
#   0  success
#   1  git error or unexpected failure
#   2  argument error (missing / unknown flag)
#   3  refused: current branch is master and --ensure-branch was not requested
#   4  refused: script contains git push (safety self-check; should never fire)
#
# Output:
#   stdout: progress messages (branch name, commit hash).
#   stderr: error messages on failure.

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die()  { echo "ERROR: branch-commit.sh: $*" >&2; exit "${2:-1}"; }
warn() { echo "WARN: branch-commit.sh: $*" >&2; }

usage() {
    sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

# ---------------------------------------------------------------------------
# Safety self-check: this script must never contain an executable git push call.
# We grep for lines that start with optional whitespace followed by `git push`
# (i.e., actual invocations, not comment text).
# ---------------------------------------------------------------------------
if grep -qE '^[[:space:]]*git push' "$0" 2>/dev/null; then
    die "SAFETY VIOLATION: this script contains an executable 'git push' call — aborted." 4
fi

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
DO_ENSURE=0
DO_COMMIT=0
SLUG=""
COMMIT_MSG=""
ADD_PATHS=()
ADD_ALL=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        --ensure-branch)
            DO_ENSURE=1
            shift
            ;;
        --slug)
            [[ $# -lt 2 ]] && die "--slug requires a value" 2
            SLUG="$2"
            shift 2
            ;;
        --commit)
            DO_COMMIT=1
            shift
            ;;
        --message)
            [[ $# -lt 2 ]] && die "--message requires a value" 2
            COMMIT_MSG="$2"
            shift 2
            ;;
        --add)
            [[ $# -lt 2 ]] && die "--add requires a path value" 2
            ADD_PATHS+=("$2")
            shift 2
            ;;
        --add-all)
            ADD_ALL=1
            shift
            ;;
        *)
            die "unknown flag: $1" 2
            ;;
    esac
done

# Validate: at least one operation requested
if [[ $DO_ENSURE -eq 0 && $DO_COMMIT -eq 0 ]]; then
    die "requires at least one of --ensure-branch or --commit" 2
fi

# Validate --ensure-branch requires --slug
if [[ $DO_ENSURE -eq 1 && -z "$SLUG" ]]; then
    die "--ensure-branch requires --slug <slug>" 2
fi

# Validate --commit requires --message and at least one staging directive
if [[ $DO_COMMIT -eq 1 ]]; then
    [[ -z "$COMMIT_MSG" ]] && die "--commit requires --message <msg>" 2
    if [[ $ADD_ALL -eq 0 && ${#ADD_PATHS[@]} -eq 0 ]]; then
        die "--commit requires at least one --add <path> or --add-all" 2
    fi
fi

# ---------------------------------------------------------------------------
# Operation 1: branch-ensure
# ---------------------------------------------------------------------------
if [[ $DO_ENSURE -eq 1 ]]; then
    # Validate slug is non-empty and looks safe (alphanumeric + hyphens)
    if [[ -z "$SLUG" || ! "$SLUG" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        die "--slug must be non-empty and contain only alphanumeric, hyphens, or underscores; got: '$SLUG'" 2
    fi

    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) \
        || die "git rev-parse --abbrev-ref HEAD failed — is this a git repository?" 1

    TARGET_BRANCH="aid/housekeep-${SLUG}"

    if [[ "$CURRENT_BRANCH" == "master" ]]; then
        # Create and switch to the new housekeep branch off the current master HEAD
        echo "branch-commit.sh: current branch is master — creating ${TARGET_BRANCH}"
        git switch -c "${TARGET_BRANCH}" \
            || die "git switch -c ${TARGET_BRANCH} failed" 1
        echo "branch-commit.sh: switched to new branch ${TARGET_BRANCH}"

    elif [[ "$CURRENT_BRANCH" == aid/housekeep-* ]]; then
        # Already on an aid/housekeep-* branch — resume case
        echo "branch-commit.sh: already on housekeep branch ${CURRENT_BRANCH} — reusing (resume)"

    else
        # On some other branch that is not master and not aid/housekeep-* — refuse
        die "current branch '${CURRENT_BRANCH}' is neither 'master' nor an 'aid/housekeep-*' branch. Refusing to operate." 3
    fi
fi

# ---------------------------------------------------------------------------
# Operation 2: stage-commit
# ---------------------------------------------------------------------------
if [[ $DO_COMMIT -eq 1 ]]; then
    # Safety check: must not be on master
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) \
        || die "git rev-parse --abbrev-ref HEAD failed — is this a git repository?" 1

    if [[ "$CURRENT_BRANCH" == "master" ]]; then
        die "refusing to commit on 'master' — run --ensure-branch first to switch to an aid/housekeep-* branch." 3
    fi

    # Stage changes
    if [[ $ADD_ALL -eq 1 ]]; then
        git add --all \
            || die "git add --all failed" 1
    else
        for path in "${ADD_PATHS[@]}"; do
            git add -- "$path" \
                || die "git add -- '$path' failed" 1
        done
    fi

    # Commit with the supplied message (exactly one commit)
    git commit -m "$COMMIT_MSG" \
        || die "git commit failed" 1

    COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo "branch-commit.sh: committed on ${CURRENT_BRANCH} (${COMMIT_HASH}): ${COMMIT_MSG}"
fi
