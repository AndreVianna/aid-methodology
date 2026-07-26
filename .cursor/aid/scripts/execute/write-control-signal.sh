#!/usr/bin/env bash
# write-control-signal.sh -- cooperative task-level stop/resume signal writer
# (feature-008-execution-control, work-017 task-028).
#
# The dashboard server is LLM-free (SEC-4) and cannot kill a separate agent
# session directly, so Task Stop/Resume (FR-T3) is implemented as a
# cooperative file-signal the running `aid-execute` orchestrator/sub-agent
# polls at its own dispatch-boundary / heartbeat tick (mirrors the
# `.aid/.heartbeat/` design in `subagent-heartbeat-protocol.md`). This script
# is the ONLY process that creates or removes that signal file -- the server
# never touches the filesystem in-process (SEC-3); it dispatches this script
# as a child process with an argv array, exactly like its sibling
# `writeback-state.sh`.
#
# Co-vendored with the dashboard unit (dashboard/scripts/, via a one-line
# `dashboard/MANIFEST` edit -- the single-source mechanism feature-001
# established; drift guarded by `tests/canonical/test-dashboard-manifest.sh`)
# and, as a canonical script, rendered to all five profiles under
# `aid/scripts/execute/` by `generate-profile`'s `run_generator.py`. Bash-only
# (as the other writers are).
#
# Usage:
#   write-control-signal.sh --task-id <NNN> --action <stop|resume>
#       env AID_WORK_DIR=<abs work dir>  (optional; falls back to $PWD)
#
# Target work dir: `AID_WORK_DIR` if set (even to a non-empty value), else the
# current working directory. The dashboard server always sets `AID_WORK_DIR`
# to feature-001's `resolve_work_dir` output -- the worktree-aware REAL
# directory the reader rendered (WT-1) -- NEVER a reconstructed
# `<served-root>/.aid/works/<work_id>` path. The control directory is derived
# RELATIVE to that work dir as `<work_dir>/../../.control/<work_id>` (the
# `.aid/.control/<work_id>/` sibling of the work dir's own `.aid/works/`),
# where `<work_id>` is the work dir's own basename -- so the signal always
# lands in the SAME worktree tree the executor polls, never a foreign one.
#
# `--task-id` is validated against `^[0-9]{1,3}$` (exit 4 otherwise) and
# normalized to `task-<zero-padded-3>` -- the exact padding convention
# `writeback-state.sh` itself uses (base-10 arithmetic before `printf '%03d'`,
# so a value like "008"/"090" is never misread as an invalid octal literal).
# The `.stop` filename is built from this NORMALIZED token only -- no
# client-supplied string ever reaches a path segment, so `../` traversal into
# or out of `.aid/.control/` is impossible (SEC-3).
#
# `--action stop`: `mkdir -p` the control directory, then atomically
# (temp-file + `mv`) create `<control-dir>/task-<NNN>.stop` containing one
# informational line:
#   [<ISO-8601 UTC>] stop | source=dashboard
# Presence of the file IS the signal; its content is advisory only (never
# parsed by the reader or the executor). Idempotent: stopping an
# already-stopped task re-writes the file (fresh timestamp) and still exits 0
# -- a no-op from the caller's point of view.
#
# `--action resume`: `rm -f` that same file. Idempotent: resuming a task with
# no `.stop` file present is a clean no-op, exit 0.
#
# This script NEVER reads or writes `STATE.md`, never touches the work
# folder's tracked contents, and never invokes git or touches any worktree --
# the control file is a new gitignored control-artifact class (like
# `.aid/.heartbeat/`), entirely outside `STATE.md`'s C1 single-writer scope.
#
# Exit codes (reuses `writeback-state.sh`'s shared alphabet verbatim, so the
# dashboard's generic OP_TABLE exit->HTTP mapping needs no per-op remap;
# 4/5 -> 422, 2 -> 409, other -> 500):
#   0 -- success (signal created/refreshed, or removed/already-absent)
#   2 -- IO failure (control dir could not be created, temp file could not be
#        written/renamed, or the signal file could not be removed)
#   4 -- invalid argument value (`--task-id` outside `^[0-9]{1,3}$`, or
#        `--action` not one of `stop`/`resume`)
#   5 -- missing required argument (`--task-id`/`--action` absent, or given
#        with no value; unknown flag)
#
# Output:
#   stdout: one `OK: ...` trace line on success.
#   stderr: diagnostics only.

set -u

# ---------------------------------------------------------------------------
usage() {
    sed -n '2,74p' "$0" | sed 's/^# \{0,1\}//'
}

die() { echo "ERROR: write-control-signal.sh: $*" >&2; exit "${2:-1}"; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
TASK_ID=""
ACTION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --task-id)
            [[ $# -lt 2 ]] && die "--task-id requires a value" 5
            TASK_ID="$2"; shift 2
            ;;
        --action)
            [[ $# -lt 2 ]] && die "--action requires a value" 5
            ACTION="$2"; shift 2
            ;;
        *)
            die "unknown argument: $1" 5
            ;;
    esac
done

[[ -z "$TASK_ID" ]] && die "--task-id is required" 5
[[ -z "$ACTION" ]] && die "--action is required" 5

case "$ACTION" in
    stop|resume) ;;
    *) die "invalid --action '$ACTION': must be one of: stop | resume" 4 ;;
esac

# Validate BEFORE normalizing -- a client-supplied string never reaches a
# path segment (SEC-3): only the zero-padded token derived from a value that
# already matched this pattern is ever used to build a filename.
[[ "$TASK_ID" =~ ^[0-9]{1,3}$ ]] || die "invalid --task-id '$TASK_ID': must match ^[0-9]{1,3}\$" 4

# Force base-10 arithmetic before padding: a zero-padded id containing 8/9
# (e.g. "008", "090") would otherwise be misparsed as an invalid octal
# literal (same guard writeback-state.sh applies at every one of its own
# padding call sites).
TASK_TOKEN="task-$(printf '%03d' "$((10#$TASK_ID))")"

# ---------------------------------------------------------------------------
# Path resolution -- WT-1: derive relative to AID_WORK_DIR (or $PWD), NEVER a
# reconstructed served-tree path.
# ---------------------------------------------------------------------------
WORK_DIR="${AID_WORK_DIR:-$(pwd)}"
WORK_DIR="${WORK_DIR%/}"
[[ -z "$WORK_DIR" ]] && WORK_DIR="/"

WORK_ID="${WORK_DIR##*/}"
CONTROL_DIR="${WORK_DIR}/../../.control/${WORK_ID}"
SIGNAL_FILE="${CONTROL_DIR}/${TASK_TOKEN}.stop"

# ---------------------------------------------------------------------------
# Action dispatch
# ---------------------------------------------------------------------------
case "$ACTION" in
    stop)
        if ! mkdir -p "$CONTROL_DIR" 2>/dev/null; then
            die "cannot create control directory: $CONTROL_DIR" 2
        fi

        tmp=$(mktemp) || die "cannot create temp file" 2
        if ! printf '[%s] stop | source=dashboard\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$tmp"; then
            rm -f "$tmp"
            die "cannot write temp file" 2
        fi
        if ! mv "$tmp" "$SIGNAL_FILE" 2>/dev/null; then
            rm -f "$tmp"
            die "cannot move temp file into place: $SIGNAL_FILE" 2
        fi
        echo "OK: $SIGNAL_FILE created -- stop signal for ${TASK_TOKEN}"
        ;;
    resume)
        if ! rm -f -- "$SIGNAL_FILE" 2>/dev/null; then
            die "cannot remove $SIGNAL_FILE" 2
        fi
        echo "OK: $SIGNAL_FILE removed (or already absent) -- resume for ${TASK_TOKEN}"
        ;;
esac

exit 0
