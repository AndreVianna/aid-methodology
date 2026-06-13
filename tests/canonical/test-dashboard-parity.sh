#!/usr/bin/env bash
# test-dashboard-parity.sh -- PT-1 cross-runtime byte-parity test (feature-003, task-018).
#
# Asserts that the Python server (dashboard/server/server.py) and the Node server
# (dashboard/server/server.mjs) emit byte-identical /r/<id>/api/model responses for the
# same .aid/ snapshot, after stripping generated_by and normalizing model.read.read_at.
#
# Updated for delivery-008 (task-056): servers use AID_HOME env var (registry.yml)
# instead of --aid-home flag. Each fixture is wrapped in a temporary aid-home with a
# single-entry registry.yml at test runtime. The /r/<id>/api/model route replaces the
# old /api/model root route. The parity contract is unchanged.
#
# Mandatory (R7): the fixture includes a manifest with U+2028/U+2029 in aid_version,
# verifying that both servers apply the canonical escaping post-process and neither
# emits raw line/paragraph-separator bytes in the JSON output.
#
# Fixture cases covered:
#   1. Full fixture (.aid/ with Running+parallel, Paused, Blocked+IMPEDIMENT,
#      Completed, and Fallback works) -- dashboard/server/tests/fixtures/pt1-aid/
#   2. No .aid/ directory present -- dashboard/server/tests/fixtures/pt1-no-aid/
#
# Skip-if-absent:
#   - python3 half: only if python3 is present
#   - node half   : only if node is present
#   - parity check: only if BOTH runtimes are present
#
# Usage:
#   bash tests/canonical/test-dashboard-parity.sh [-v | --verbose]
# Exit codes:
#   0 -- all asserted checks passed (or all were skipped)
#   1 -- one or more checks failed
#
# Source is ASCII-only (shipped script posture; coding-standards.md).
# The fixture data files (dashboard/server/tests/fixtures/pt1-aid/) MAY contain U+2028/U+2029 --
# they are test DATA, not shipped scripts, and are not scanned by test-ascii-only.sh.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "${SCRIPT_DIR}/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Runtime availability
# ---------------------------------------------------------------------------

HAS_PYTHON=0
HAS_NODE=0

if command -v python3 >/dev/null 2>&1; then
    HAS_PYTHON=1
fi
if command -v node >/dev/null 2>&1; then
    HAS_NODE=1
fi

echo "=== PT-1 cross-runtime byte-parity test ==="
echo "  python3 present: $HAS_PYTHON"
echo "  node present:    $HAS_NODE"

if [[ $HAS_PYTHON -eq 0 && $HAS_NODE -eq 0 ]]; then
    echo "  SKIP: neither python3 nor node found; skipping all PT-1 checks."
    echo "=== Summary ==="
    echo "  Tests passed: 0"
    echo "  Tests failed: 0"
    echo ""
    echo "All tests passed."
    exit 0
fi

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

FIXTURE_FULL="${REPO_ROOT}/dashboard/server/tests/fixtures/pt1-aid"
FIXTURE_EMPTY="${REPO_ROOT}/dashboard/server/tests/fixtures/pt1-no-aid"

# ---------------------------------------------------------------------------
# Cleanup registry: track pids to kill on exit
# ---------------------------------------------------------------------------

declare -a _BGPIDS=()
PT1_TMP="$(mktemp -d /tmp/pt1_XXXXXX)"

cleanup() {
    for pid in "${_BGPIDS[@]+"${_BGPIDS[@]}"}"; do
        kill "$pid" 2>/dev/null || true
    done
    _BGPIDS=()
    rm -rf "$PT1_TMP"
    rm -f /tmp/pt1_py_raw.json /tmp/pt1_node_raw.json /tmp/pt1_py_norm.json /tmp/pt1_node_norm.json
}

trap cleanup EXIT

# ---------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------

# Find a free port on 127.0.0.1 by binding to port 0.
find_free_port() {
    python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(('127.0.0.1', 0))
print(s.getsockname()[1])
s.close()
"
}

# Wait until 127.0.0.1:PORT serves /api/home, with timeout.
# Uses urllib (not raw socket) to avoid sandbox restrictions on socket.create_connection.
# Args: PORT TIMEOUT_SECS
# Returns 0 if endpoint becomes available within timeout, 1 otherwise.
#
# NOTE: python3 invocation is a standalone command (not inside 'if' or pipeline)
# to avoid interactions between bash pipefail and python's urllib internals.
wait_for_port() {
    local port="$1"
    local timeout="${2:-12}"
    local attempts=$(( timeout * 3 + 1 ))
    local i=0 rc
    while [[ $i -lt $attempts ]]; do
        python3 "${SCRIPT_DIR}/../lib/pt1h_probe.py" "$port"
        rc=$?
        if [[ $rc -eq 0 ]]; then
            return 0
        fi
        sleep 0.3
        i=$(( i + 1 ))
    done
    return 1
}

# ---------------------------------------------------------------------------
# Build a temporary aid-home wrapping a single fixture repo.
# The registry.yml points to the fixture directory as the single repo entry.
# Returns the aid-home path on stdout.
# ---------------------------------------------------------------------------

build_single_repo_aid_home() {
    local fixture_root="$1"
    local label="$2"
    local aid_home="${PT1_TMP}/aid-home-${label//\//-}"
    mkdir -p "${aid_home}/dashboard"
    cat > "${aid_home}/registry.yml" << REGEOF
schema: 1
repos:
  - ${fixture_root}
REGEOF
    echo "${aid_home}"
}

# ---------------------------------------------------------------------------
# Start server helpers (AID_HOME via env -- no --aid-home flag)
# ---------------------------------------------------------------------------

start_python_server() {
    local port="$1"
    local aid_home="$2"
    AID_HOME="$aid_home" python3 "${REPO_ROOT}/dashboard/server/server.py" \
        --host 127.0.0.1 --port "$port" \
        >/dev/null 2>&1 &
    _BGPIDS+=($!)
}

start_node_server() {
    local port="$1"
    local aid_home="$2"
    AID_HOME="$aid_home" node "${REPO_ROOT}/dashboard/server/server.mjs" \
        --host 127.0.0.1 --port "$port" \
        >/dev/null 2>&1 &
    _BGPIDS+=($!)
}

# ---------------------------------------------------------------------------
# Fetch the first /r/<id>/api/model from a running server and write to FILE.
# The server's /api/home is consulted to discover the id for the first registered repo.
# Args: PORT AID_HOME FILE
# ---------------------------------------------------------------------------

fetch_api_model() {
    local port="$1"
    local outfile="$2"
    python3 -c "
import urllib.request, json, sys
try:
    resp = urllib.request.urlopen('http://127.0.0.1:$port/api/home', timeout=10)
    home_data = json.loads(resp.read().decode('utf-8'))
    repos = home_data.get('repos', [])
    if not repos:
        sys.stderr.write('no repos in /api/home\n')
        sys.exit(1)
    repo_id = repos[0]['id']
    resp2 = urllib.request.urlopen('http://127.0.0.1:$port/r/' + repo_id + '/api/model', timeout=10)
    data = resp2.read()
    open('$outfile', 'wb').write(data)
    sys.exit(0)
except Exception as e:
    sys.stderr.write('fetch failed: ' + str(e) + '\n')
    sys.exit(1)
"
}

# ---------------------------------------------------------------------------
# Normalize JSON: strip generated_by and set model.read.read_at to "NORMALIZED".
# U+2028/U+2029 post-process uses chr() to avoid non-ASCII in the script source.
# Args: INFILE OUTFILE
# ---------------------------------------------------------------------------

normalize_json() {
    local infile="$1"
    local outfile="$2"
    python3 -c "
import json, sys
LS = chr(0x2028)
PS = chr(0x2029)
with open('$infile', 'rb') as f:
    raw = f.read()
data = json.loads(raw.decode('utf-8'))
data.pop('generated_by', None)
if 'model' in data and 'read' in data['model']:
    data['model']['read']['read_at'] = 'NORMALIZED'
out = json.dumps(data, separators=(',', ':'), ensure_ascii=False)
out = out.replace(LS, '\\\\u2028').replace(PS, '\\\\u2029')
open('$outfile', 'w', encoding='utf-8').write(out)
"
}

# ---------------------------------------------------------------------------
# Single-fixture parity check.
# Args: FIXTURE_ROOT FIXTURE_LABEL CHECK_R7
#   CHECK_R7: "1" = run R7 escaping check (fixture has U+2028/U+2029 in aid_version);
#             "0" = skip R7 check (fixture has no U+2028/U+2029).
# ---------------------------------------------------------------------------

check_fixture_parity() {
    local fixture_root="$1"
    local label="$2"
    local check_r7="${3:-0}"

    local py_port node_port
    py_port=$(find_free_port)
    node_port=$(find_free_port)

    # Ensure the two ports differ (vanishingly rare collision)
    while [[ "$node_port" == "$py_port" ]]; do
        node_port=$(find_free_port)
    done

    log "Fixture: $label  py=$py_port node=$node_port"

    # Build temporary aid-home with a single-entry registry for this fixture.
    local aid_home
    aid_home=$(build_single_repo_aid_home "$fixture_root" "$label")

    # --- Python half ---
    if [[ $HAS_PYTHON -eq 1 ]]; then
        start_python_server "$py_port" "$aid_home"
        local py_pid="${_BGPIDS[-1]}"

        if wait_for_port "$py_port" 12; then
            if fetch_api_model "$py_port" "/tmp/pt1_py_raw.json"; then
                pass "[$label] python server responds on /r/<id>/api/model"
                if python3 -c "import json; json.load(open('/tmp/pt1_py_raw.json'))" 2>/dev/null; then
                    pass "[$label] python /r/<id>/api/model is valid JSON"
                else
                    fail "[$label] python /r/<id>/api/model is not valid JSON"
                fi
            else
                fail "[$label] python server /r/<id>/api/model fetch failed"
            fi
        else
            fail "[$label] python server did not start within 12s on port $py_port"
        fi

        kill "$py_pid" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$py_pid}")
    fi

    # --- Node half ---
    if [[ $HAS_NODE -eq 1 ]]; then
        start_node_server "$node_port" "$aid_home"
        local node_pid="${_BGPIDS[-1]}"

        if wait_for_port "$node_port" 12; then
            if fetch_api_model "$node_port" "/tmp/pt1_node_raw.json"; then
                pass "[$label] node server responds on /r/<id>/api/model"
                if python3 -c "import json; json.load(open('/tmp/pt1_node_raw.json'))" 2>/dev/null; then
                    pass "[$label] node /r/<id>/api/model is valid JSON"
                else
                    fail "[$label] node /r/<id>/api/model is not valid JSON"
                fi
            else
                fail "[$label] node server /r/<id>/api/model fetch failed"
            fi
        else
            fail "[$label] node server did not start within 12s on port $node_port"
        fi

        kill "$node_pid" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$node_pid}")
    fi

    # --- Parity check (only when BOTH runtimes are present and both fetches succeeded) ---
    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 ]]; then
        if [[ -f /tmp/pt1_py_raw.json && -f /tmp/pt1_node_raw.json ]]; then
            normalize_json /tmp/pt1_py_raw.json /tmp/pt1_py_norm.json
            normalize_json /tmp/pt1_node_raw.json /tmp/pt1_node_norm.json

            # Byte-identical comparison (PT-1 core assertion)
            if cmp -s /tmp/pt1_py_norm.json /tmp/pt1_node_norm.json; then
                pass "[$label] python == node (byte-identical after strip+normalize)"
            else
                fail "[$label] python != node (NOT byte-identical after strip+normalize)"
                if [[ "$VERBOSE" -eq 1 ]]; then
                    echo "  --- diff (python vs node) ---"
                    diff /tmp/pt1_py_norm.json /tmp/pt1_node_norm.json || true
                fi
            fi

            # R7: U+2028/U+2029 escaping guarantee.
            # Only checked for fixtures that contain U+2028/U+2029 (e.g. full-fixture).
            # The fixture manifest has literal U+2028/U+2029 bytes in aid_version.
            # Both servers MUST escape them (\\u2028/\\u2029) -- no raw bytes in output.
            if [[ "$check_r7" == "1" ]]; then
                python3 "${SCRIPT_DIR}/../lib/pt1_r7_check.py" \
                    /tmp/pt1_py_raw.json /tmp/pt1_node_raw.json
                local r7_rc=$?
                if [[ $r7_rc -eq 0 ]]; then
                    pass "[$label] R7: U+2028/U+2029 escaped (not raw) in both servers"
                else
                    fail "[$label] R7: U+2028/U+2029 escaping violated (see above)"
                fi
            fi
        else
            log "[$label] skipping parity check: one or both fetches failed"
        fi
    else
        log "[$label] skipping parity check: only one runtime present"
    fi

    rm -f /tmp/pt1_py_raw.json /tmp/pt1_node_raw.json /tmp/pt1_py_norm.json /tmp/pt1_node_norm.json
}

# ---------------------------------------------------------------------------
# Run checks for each fixture
# ---------------------------------------------------------------------------

# full-fixture: has U+2028/U+2029 in manifest -> R7 escaping check enabled
check_fixture_parity "$FIXTURE_FULL" "full-fixture" "1"
# no-aid fixture: no manifest, no U+2028/U+2029 in output -> R7 check skipped
check_fixture_parity "$FIXTURE_EMPTY" "no-aid" "0"

# ---------------------------------------------------------------------------
# Schema version and generated_by field checks
# ---------------------------------------------------------------------------

FULL_AID_HOME=$(build_single_repo_aid_home "$FIXTURE_FULL" "full-check")

if [[ $HAS_PYTHON -eq 1 ]]; then
    local_py_port=$(find_free_port)
    start_python_server "$local_py_port" "$FULL_AID_HOME"
    local_py_pid="${_BGPIDS[-1]}"

    if wait_for_port "$local_py_port" 12; then
        fetch_api_model "$local_py_port" "/tmp/pt1_py_raw.json"

        schema_ver=$(python3 -c "import json; d = json.load(open('/tmp/pt1_py_raw.json')); print(d.get('schema_version', 'MISSING'))")
        assert_eq "$schema_ver" "3" "[full-fixture] python schema_version == 3"

        gen_by=$(python3 -c "import json; d = json.load(open('/tmp/pt1_py_raw.json')); print(d.get('generated_by', 'MISSING'))")
        assert_eq "$gen_by" "python" "[full-fixture] python generated_by == 'python'"

        read_at=$(python3 -c "import json; d = json.load(open('/tmp/pt1_py_raw.json')); print(d['model']['read']['read_at'])")
        if [[ -n "$read_at" && "$read_at" != "None" ]]; then
            pass "[full-fixture] python model.read.read_at is non-empty"
        else
            fail "[full-fixture] python model.read.read_at is empty or None"
        fi
    fi

    kill "$local_py_pid" 2>/dev/null || true
    _BGPIDS=("${_BGPIDS[@]/$local_py_pid}")
    rm -f /tmp/pt1_py_raw.json
fi

if [[ $HAS_NODE -eq 1 && $HAS_PYTHON -eq 1 ]]; then
    local_node_port=$(find_free_port)
    start_node_server "$local_node_port" "$FULL_AID_HOME"
    local_node_pid="${_BGPIDS[-1]}"

    if wait_for_port "$local_node_port" 12; then
        fetch_api_model "$local_node_port" "/tmp/pt1_node_raw.json"

        gen_by=$(python3 -c "import json; d = json.load(open('/tmp/pt1_node_raw.json')); print(d.get('generated_by', 'MISSING'))")
        assert_eq "$gen_by" "node" "[full-fixture] node generated_by == 'node'"
    fi

    kill "$local_node_pid" 2>/dev/null || true
    _BGPIDS=("${_BGPIDS[@]/$local_node_pid}")
    rm -f /tmp/pt1_node_raw.json
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

test_summary
