#!/usr/bin/env bash
# connector-secret.sh -- the single home for ALL `.aid/connectors/.secrets/`
# I/O (feature-003 "Local Auth Registration"). Exposes BOTH operations the
# connector-secret twin owns, per feature-003 SPEC.md "Layers & Components":
# feature-003 owns this twin and defines BOTH `write` and `purge` -- feature-006
# does NOT define its own purge twin; on REMOVE it CALLS this script's `purge`
# op instead.
#
# Two operations:
#   write <stem> [--root <dir>]  -- no-echo capture of a secret value (read
#                                    from stdin with terminal echo off via
#                                    `read -rs`) and an exact-bytes,
#                                    owner-only write to
#                                    `<root>/.secrets/<stem>`. Prints ONLY the
#                                    `file:<root>/.secrets/<stem>` reference to
#                                    stdout -- never the value.
#   purge <stem> [--root <dir>]  -- idempotent delete of `<root>/.secrets/<stem>`.
#                                    A missing file is a clean no-op success.
#                                    Prints nothing to stdout; silent on
#                                    contents.
#
# Usage:
#   connector-secret.sh write <stem> [--root <dir>]
#   connector-secret.sh purge <stem> [--root <dir>]
#
# Examples:
#   bash connector-secret.sh write github            # interactive, no-echo prompt
#   printf '%s\n' "$TOKEN" | bash connector-secret.sh write github   # automation/CI
#   bash connector-secret.sh purge github
#   bash connector-secret.sh write github --root .aid/connectors
#
# Exit codes:
#   0 -- success (write: value stored, `file:` reference printed; purge:
#        deleted, or already-absent no-op)
#   1 -- generic runtime failure (e.g. empty secret entered, underlying I/O error)
#   2 -- usage / argument error (bad/missing operation, missing <stem>, unknown flag)
#   3 -- path-confinement rejection: <stem> contains '/', '\', or '..' -- checked
#        BEFORE any read/write/delete; applies identically to write and purge
#        (feature-003 SPEC.md "Layers & Components" -- "Path confinement
#        (first-class guarantee -- BOTH ops)")
#   4 -- write only: fail-closed ignore-precondition failure -- the committed
#        `<root>/.gitignore` does not ignore `.secrets/`; refuses to write the
#        first byte of any secret (feature-003 SPEC.md "Security Specs" --
#        "Fail-closed on the ignore precondition"). purge does not require
#        this precondition.
#
# Output:
#   stdout: write's ONLY result -- the `file:` reference. Never the secret
#           value. purge prints nothing to stdout on either branch.
#   stderr: diagnostics only; never the secret value.
#
# Security (feature-003 SPEC.md "Security Specs" -- read this before touching
# this script; this is the most security-sensitive script in the connectors
# family):
#   - No-echo capture: `read -rs` -- terminal echo off on a real tty; a
#     harmless no-op silencer (nothing to suppress) when stdin is not a tty,
#     e.g. piped/redirected automation or test input.
#   - No `set -x` anywhere in this file, especially not around the read/write.
#   - The secret is NEVER passed as a process argument. `printf '%s'` below is
#     the Bash BUILTIN (no fork/exec) -- the value never appears as an
#     argument in a `ps`/process-table listing or shell history.
#   - The in-memory `SECRET` variable is `unset` immediately after the write
#     returns, before anything is printed to stdout.
#   - Exact bytes, no trailing newline: `printf '%s'` (never `echo`, which may
#     append one, and never `printf '%s\n'`).
#   - Owner-only from the outset: `( umask 077; ... )` around both the
#     directory creation and the write -- there is no window in which the
#     file/directory is group/world-readable.
set -euo pipefail

SCRIPT_NAME="connector-secret.sh"
DEFAULT_ROOT=".aid/connectors"
ROOT="$DEFAULT_ROOT"

usage() {
    cat <<'HELP'
connector-secret.sh -- write/purge a connector's secret value in the local file store.

Usage:
  connector-secret.sh write <stem> [--root <dir>]
  connector-secret.sh purge <stem> [--root <dir>]

Exit codes:
  0  success
  1  generic runtime failure
  2  usage / argument error
  3  path-confinement rejection (<stem> contains '/', '\', or '..')
  4  write only: fail-closed ignore-precondition failure
     (<root>/.gitignore does not ignore .secrets/)
HELP
}

# ---------------------------------------------------------------------------
# Argument parsing -- collect flags (--root) anywhere, remaining args positional.
# ---------------------------------------------------------------------------
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            [[ $# -ge 2 ]] || { echo "${SCRIPT_NAME}: --root requires a value" >&2; exit 2; }
            ROOT="$2"; shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do POSITIONAL+=("$1"); shift; done
            ;;
        -*)
            echo "${SCRIPT_NAME}: unknown flag: $1" >&2
            exit 2
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL[@]} -eq 0 ]]; then
    echo "${SCRIPT_NAME}: missing operation (write|purge)" >&2
    exit 2
fi

OP="${POSITIONAL[0]}"

case "$OP" in
    write|purge)
        if [[ ${#POSITIONAL[@]} -ne 2 ]]; then
            echo "${SCRIPT_NAME}: '$OP' requires <stem>" >&2
            exit 2
        fi
        ;;
    *)
        echo "${SCRIPT_NAME}: unknown operation: $OP (expected write|purge)" >&2
        exit 2
        ;;
esac

STEM="${POSITIONAL[1]}"

if [[ -z "$STEM" ]]; then
    echo "${SCRIPT_NAME}: <stem> must not be empty" >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Path confinement -- BEFORE any read/write/delete, identically for both ops.
# <stem> is a filename stem ONLY; reject any path separator or a '..'
# occurrence outright (a strict substring check -- fail-closed over
# under-rejection is the correct trade-off for a delete-capable op).
# ---------------------------------------------------------------------------
case "$STEM" in
    */*|*'\'*|*'..'*)
        echo "${SCRIPT_NAME}: invalid stem '$STEM' -- must be a bare filename (no '/', '\\', or '..')" >&2
        exit 3
        ;;
esac

SECRETS_DIR="${ROOT%/}/.secrets"
GITIGNORE_FILE="${ROOT%/}/.gitignore"
TARGET="${SECRETS_DIR}/${STEM}"

# ---------------------------------------------------------------------------
# gitignore_ignores_secrets FILE -- true (0) iff FILE has a line that ignores
# the `.secrets/` directory (feature-001's committed connectors-local
# `.aid/connectors/.gitignore`, sole entry `.secrets/`). Tolerates a leading
# `/` and a missing trailing `/` -- equivalent gitignore forms for the same
# directory. `[[:space:]]` already matches a trailing `\r` (CRLF-authored file).
# ---------------------------------------------------------------------------
gitignore_ignores_secrets() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    grep -Eq '^[[:space:]]*/?\.secrets/?[[:space:]]*$' "$file"
}

# ---------------------------------------------------------------------------
# purge -- idempotent delete. `rm -f` is a clean no-op when TARGET (or any of
# its parent directories) does not exist; never reads the file first, so it
# stays silent on contents even in an error path.
# ---------------------------------------------------------------------------
if [[ "$OP" == "purge" ]]; then
    rm -f -- "$TARGET"
    exit 0
fi

# ---------------------------------------------------------------------------
# write
# ---------------------------------------------------------------------------

# Fail-closed ignore precondition -- BEFORE the first byte of any secret is
# written (feature-003 SPEC.md "Security Specs"). Checked before the prompt
# too, so a refusal never needlessly captures a secret it will not store.
if ! gitignore_ignores_secrets "$GITIGNORE_FILE"; then
    echo "${SCRIPT_NAME}: refusing to write -- ${GITIGNORE_FILE} does not ignore .secrets/ (fail-closed)" >&2
    exit 4
fi

# Ensure the store directory exists, owner-only from the outset -- no window
# in which it is group/world-readable. `chmod` re-tightens an already-existing
# directory too (e.g. one created by an earlier run under a looser umask);
# `|| true` makes this best-effort on filesystems that do not honor POSIX modes
# (feature-001's git-ignore remains the load-bearing guarantee there).
( umask 077; mkdir -p "$SECRETS_DIR" )
chmod 700 "$SECRETS_DIR" 2>/dev/null || true

# No-echo capture. `read -rs`: terminal echo off on a real tty; a harmless
# no-op silencer when stdin is not a tty (piped/redirected automation or test
# input -- see tests/canonical/test-connector-secret.sh for the documented
# redirection pattern). `-r` disables backslash processing and a leading
# `IFS=` disables read's own leading/trailing whitespace trimming, so the
# captured bytes are exact.
printf 'Enter secret value for %s (input hidden): ' "$STEM" >&2
IFS= read -rs SECRET || true
echo >&2

if [[ -z "$SECRET" ]]; then
    echo "${SCRIPT_NAME}: no secret entered (empty input)" >&2
    exit 1
fi

# Exact-bytes, owner-only write -- no trailing newline (`printf '%s'`, never
# `echo`). `printf` here is the Bash BUILTIN (no fork/exec): the secret is
# NEVER passed as a process argument and never appears in a `ps` listing.
( umask 077; printf '%s' "$SECRET" > "$TARGET" )

# Clear the in-memory secret immediately after the write returns, before
# anything is printed to stdout.
unset SECRET

echo "file:${TARGET}"
exit 0
