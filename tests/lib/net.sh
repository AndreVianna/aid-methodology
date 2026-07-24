# net.sh -- shared ephemeral-port helpers for suites that bind local test servers.
#
# Source it from a suite:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/net.sh"
#   PORT="$(find_free_port)"
#   wait_for_port "$PORT" 12 || fail "server never came up on port $PORT"
#
# Provides:
#   find_free_port
#     Echo a free 127.0.0.1 port by binding to port 0 via python3.
#   wait_for_port PORT [TIMEOUT_SECS=12]
#     Poll 127.0.0.1:PORT until it serves /api/home (timeout*3+1 attempts,
#     0.3s apart), delegating to the co-located pt1h_probe.py. Return 0 if it
#     comes up within the timeout, 1 otherwise. Multi-port coordination (two
#     distinct ports for the Python/Node twins) stays in the caller -- this
#     is a single-port primitive.
#
# _NET_LIB_DIR is resolved ONCE at source time (not relative to the caller's
# own SCRIPT_DIR/CWD), so pt1h_probe.py is found regardless of where the
# sourcing suite lives or what its working directory is at call time.

_NET_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# find_free_port
#   Echo a free 127.0.0.1 port by binding to port 0 via python3.
find_free_port() {
    python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(('127.0.0.1', 0))
print(s.getsockname()[1])
s.close()
"
}

# wait_for_port PORT [TIMEOUT_SECS=12]
#   Poll until 127.0.0.1:PORT serves /api/home, delegating to pt1h_probe.py.
#   Return 0 if it comes up within the timeout, 1 otherwise.
#
# NOTE: the python3 invocation is a standalone command (not inside 'if' or a
# pipeline) to avoid interactions between bash pipefail and urllib's internal
# pipes.
wait_for_port() {
    local port="$1"
    local timeout="${2:-12}"
    local attempts=$(( timeout * 3 + 1 ))
    local i=0 rc
    while [[ $i -lt $attempts ]]; do
        python3 "${_NET_LIB_DIR}/pt1h_probe.py" "$port"
        rc=$?
        if [[ $rc -eq 0 ]]; then
            return 0
        fi
        sleep 0.3
        i=$(( i + 1 ))
    done
    return 1
}
