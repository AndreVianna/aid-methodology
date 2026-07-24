# pwsh-batch.sh -- warm pwsh "responder" session driver for the parity suite
# (work-024 delivery-003, feature-004 / FR-4). Sourced, NOT a test-*.sh suite.
#
# Source it from a suite AFTER pwsh.sh (it needs $PWSH from detect_pwsh):
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/pwsh.sh"
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/pwsh-batch.sh"
#   PWSH="$(detect_pwsh || true)"
#   [[ -z "$PWSH" ]] && { echo "SKIP ..."; exit 0; }
#   sandbox_pin_home ...          # pin HOME BEFORE spawning (fidelity, below)
#   pwsh_session_start            # spawn ONE warm responder (or set cold mode)
#   trap 'pwsh_session_stop; rm -rf "$TMP"' EXIT
#
# Provides:
#   pwsh_session_start
#     Spawn ONE warm `"$PWSH" -NoProfile -File tests/lib/pwsh-responder.ps1`
#     over a FIFO pair and verify it with a PING round-trip. On any failure (or
#     AID_PWSH_NO_SESSION=1, or no $PWSH) leaves PWSH_SESSION_MODE=cold so every
#     call transparently uses the cold `-File` path -- never worse than today.
#     MUST be called AFTER the suite's HOME pin: the responder inherits the
#     pinned env at spawn, exactly as a cold `-File` start would, so a non-scan
#     wrapper (no per-call HOME) resolves the SAME $HOME warm vs cold.
#   pwsh_session_call <aid_ps1_path> <cwd> [NAME=VALUE ...] -- [aid_args ...]
#     Run ONE aid.ps1 invocation through the warm session (or the cold
#     fallback). Sets:
#       PWSH_CALL_OUT  raw combined stdout+stderr (UNFILTERED -- the caller
#                      applies its existing sed ANSI-strip / slash-norm)
#       PWSH_CALL_RC   integer exit code
#     A byte-for-byte drop-in for a cold
#       env NAME=VALUE ... "$PWSH" -NoProfile -File <aid> <args> 2>&1
#     (both are normalized by the caller's `$(...)` trailing-newline strip).
#   pwsh_session_stop
#     Tear the responder down: close the request channel -> responder sees stdin
#     EOF -> exits its loop -> one process reaped. Idempotent; safe when no
#     session was ever started.
#
# Transparent cold-start fallback (SPEC "Transparent fallback", NFR-3/NFR-5): if
# the responder cannot be spawned, fails its handshake, or a round-trip breaks
# (closed channel / timeout / malformed terminator), the driver degrades to the
# cold `-File` path for this and every subsequent call. AID_PWSH_NO_SESSION=1
# forces the cold path from the start -- the toggle task-018's byte-parity
# self-check drives to compare warm vs cold.
#
# Framing is nonce-terminated (SPEC Risk R6): the responder echoes a per-request
# random token on the terminator line, so output that happens to contain the
# token cannot false-trigger the frame boundary.
#
# snake_case fns / UPPER_SNAKE globals; LF + ASCII.

PWSH_BATCH_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PWSH_SESSION_MODE="cold"
PWSH_SESSION_PID=""
PWSH_SESSION_DIR=""
PWSH_REQ_FD=""
PWSH_RESP_FD=""
PWSH_CALL_OUT=""
PWSH_CALL_RC=0
_PWSH_SESSION_SEQ=0
: "${PWSH_SESSION_READ_TIMEOUT:=180}"
: "${PWSH_SESSION_PING_TIMEOUT:=30}"

# Per-request nonce: monotonic seq + PID + $RANDOM. The fixed "AIDEOF" prefix
# plus the random suffix makes a collision with real aid.ps1 output negligible.
_pwsh_session_nonce() {
    _PWSH_SESSION_SEQ=$((_PWSH_SESSION_SEQ + 1))
    printf 'AIDEOF%s.%s.%s.%s' "$$" "${_PWSH_SESSION_SEQ}" "${RANDOM}" "${RANDOM}"
}

_pwsh_session_cleanup() {
    [[ -n "$PWSH_SESSION_DIR" && -d "$PWSH_SESSION_DIR" ]] && rm -rf "$PWSH_SESSION_DIR"
    PWSH_SESSION_DIR=""
}

_pwsh_session_close_fds() {
    [[ -n "$PWSH_REQ_FD" ]]  && eval "exec ${PWSH_REQ_FD}>&-"  2>/dev/null
    [[ -n "$PWSH_RESP_FD" ]] && eval "exec ${PWSH_RESP_FD}>&-" 2>/dev/null
    PWSH_REQ_FD=""
    PWSH_RESP_FD=""
}

_pwsh_session_kill() {
    if [[ -n "$PWSH_SESSION_PID" ]]; then
        kill "$PWSH_SESSION_PID" 2>/dev/null || true
        wait "$PWSH_SESSION_PID" 2>/dev/null || true
        PWSH_SESSION_PID=""
    fi
}

# Give up the warm path (for this + every later call) and tear down cleanly.
_pwsh_session_degrade() {
    PWSH_SESSION_MODE="cold"
    _pwsh_session_close_fds
    _pwsh_session_kill
    _pwsh_session_cleanup
}

# Cold `-File` path: byte-identical to the pre-batching wrapper body.
_pwsh_session_cold_call() {
    local aid_path="$1" cwd="$2"; shift 2
    local -a cenv=() cargs=()
    while [[ $# -gt 0 && "$1" != "--" ]]; do cenv+=("$1"); shift; done
    [[ "${1:-}" == "--" ]] && shift
    cargs=("$@")
    PWSH_CALL_OUT="$( cd "$cwd" 2>/dev/null; env "${cenv[@]}" "$PWSH" -NoProfile -File "$aid_path" "${cargs[@]}" 2>&1 )"
    PWSH_CALL_RC=$?
}

# Handshake: prove the round-trip channel before the suite relies on it.
_pwsh_session_ping() {
    local nonce; nonce="$(_pwsh_session_nonce)"
    {
        printf '%s\n' 'PING'
        printf 'NONCE %s\n' "$nonce"
        printf '%s\n' 'GO'
    } >&"$PWSH_REQ_FD" 2>/dev/null || return 1

    local line
    while IFS= read -t "$PWSH_SESSION_PING_TIMEOUT" -r line <&"$PWSH_RESP_FD"; do
        line="${line%$'\r'}"
        [[ "$line" == "${nonce} "* ]] && return 0
    done
    return 1
}

pwsh_session_start() {
    PWSH_CALL_OUT=""
    PWSH_CALL_RC=0
    PWSH_SESSION_MODE="cold"

    [[ "${AID_PWSH_NO_SESSION:-0}" == "1" ]] && return 0
    [[ -z "${PWSH:-}" ]] && return 0

    local responder="${PWSH_BATCH_LIB_DIR}/pwsh-responder.ps1"
    [[ -f "$responder" ]] || return 0

    PWSH_SESSION_DIR="$(mktemp -d "${TMPDIR:-/tmp}/aidpwshsess.XXXXXX" 2>/dev/null)" \
        || { PWSH_SESSION_DIR=""; return 0; }
    local req="${PWSH_SESSION_DIR}/req" resp="${PWSH_SESSION_DIR}/resp"
    mkfifo "$req" "$resp" 2>/dev/null || { _pwsh_session_cleanup; return 0; }

    # Launch the responder FIRST (so it does NOT inherit the parent's persistent
    # req/resp fds opened below), then open the parent's RDWR fds. Opening a FIFO
    # RDWR never blocks, so this ordering avoids the classic FIFO open deadlock.
    "$PWSH" -NoProfile -File "$responder" \
        <"$req" >"$resp" 2>"${PWSH_SESSION_DIR}/responder.err" &
    PWSH_SESSION_PID=$!

    if ! exec {PWSH_REQ_FD}<>"$req";  then _pwsh_session_degrade; return 0; fi
    if ! exec {PWSH_RESP_FD}<>"$resp"; then _pwsh_session_degrade; return 0; fi

    PWSH_SESSION_MODE="warm"
    if ! _pwsh_session_ping; then
        _pwsh_session_degrade
        return 0
    fi
    return 0
}

pwsh_session_call() {
    local aid_path="$1" cwd="$2"; shift 2
    local -a call_env=() call_args=()
    while [[ $# -gt 0 && "$1" != "--" ]]; do call_env+=("$1"); shift; done
    [[ "${1:-}" == "--" ]] && shift
    call_args=("$@")

    if [[ "$PWSH_SESSION_MODE" != "warm" ]]; then
        _pwsh_session_cold_call "$aid_path" "$cwd" "${call_env[@]}" -- "${call_args[@]}"
        return
    fi

    local nonce; nonce="$(_pwsh_session_nonce)"
    if ! {
        printf '%s\n' 'CALL'
        printf 'NONCE %s\n' "$nonce"
        printf 'CWD %s\n' "$cwd"
        printf 'AID %s\n' "$aid_path"
        local e name val
        for e in "${call_env[@]}"; do
            name="${e%%=*}"; val="${e#*=}"
            printf 'ENV %s %s\n' "$name" "$val"
        done
        local a
        for a in "${call_args[@]}"; do
            printf 'ARG %s\n' "$a"
        done
        printf '%s\n' 'GO'
    } >&"$PWSH_REQ_FD" 2>/dev/null; then
        _pwsh_session_degrade
        _pwsh_session_cold_call "$aid_path" "$cwd" "${call_env[@]}" -- "${call_args[@]}"
        return
    fi

    local line raw="" got_rc="" saw_term=0
    while IFS= read -t "$PWSH_SESSION_READ_TIMEOUT" -r line <&"$PWSH_RESP_FD"; do
        if [[ "$line" == "${nonce} "* ]]; then
            got_rc="${line#${nonce} }"
            saw_term=1
            break
        fi
        raw+="${line}"$'\n'
    done
    got_rc="${got_rc%$'\r'}"

    if [[ "$saw_term" -ne 1 ]] || ! [[ "$got_rc" =~ ^-?[0-9]+$ ]]; then
        _pwsh_session_degrade
        _pwsh_session_cold_call "$aid_path" "$cwd" "${call_env[@]}" -- "${call_args[@]}"
        return
    fi

    PWSH_CALL_OUT="$raw"
    PWSH_CALL_RC="$got_rc"
}

pwsh_session_stop() {
    if [[ "$PWSH_SESSION_MODE" != "warm" ]]; then
        _pwsh_session_close_fds
        _pwsh_session_kill
        _pwsh_session_cleanup
        PWSH_SESSION_MODE="cold"
        return 0
    fi
    # Close the request channel -> responder's stdin EOFs -> it exits its loop.
    [[ -n "$PWSH_REQ_FD" ]] && eval "exec ${PWSH_REQ_FD}>&-" 2>/dev/null
    PWSH_REQ_FD=""
    if [[ -n "$PWSH_SESSION_PID" ]]; then
        local i=0
        while kill -0 "$PWSH_SESSION_PID" 2>/dev/null && [[ $i -lt 30 ]]; do
            sleep 0.1
            i=$((i + 1))
        done
    fi
    _pwsh_session_kill
    [[ -n "$PWSH_RESP_FD" ]] && eval "exec ${PWSH_RESP_FD}>&-" 2>/dev/null
    PWSH_RESP_FD=""
    _pwsh_session_cleanup
    PWSH_SESSION_MODE="cold"
}
