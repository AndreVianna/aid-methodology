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
source "${SCRIPT_DIR}/../lib/net.sh"

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
PT1_TMP="$(mktemp -d)"
PT1_PY_RAW="${PT1_TMP}/pt1_py_raw.json"
PT1_NODE_RAW="${PT1_TMP}/pt1_node_raw.json"
PT1_PY_NORM="${PT1_TMP}/pt1_py_norm.json"
PT1_NODE_NORM="${PT1_TMP}/pt1_node_norm.json"

# Pinned HOME for server processes: no .aid/registry.yml -> server sees only AID_HOME tier.
# This prevents the developer's real ~/.aid/registry.yml from bleeding into the union read,
# which would cause repos[0] to no longer be the fixture repo (R7/registry-union fix).
PT1_PINNED_HOME="${PT1_TMP}/pinned-home"
mkdir -p "${PT1_PINNED_HOME}"

cleanup() {
    for pid in "${_BGPIDS[@]+"${_BGPIDS[@]}"}"; do
        kill "$pid" 2>/dev/null || true
    done
    _BGPIDS=()
    rm -rf "$PT1_TMP"
    rm -f ${PT1_PY_RAW} ${PT1_NODE_RAW} ${PT1_PY_NORM} ${PT1_NODE_NORM}
}

trap cleanup EXIT

# ---------------------------------------------------------------------------
# Port helpers: find_free_port / wait_for_port -- see tests/lib/net.sh.
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
    # Pin HOME to a throwaway dir so the server's user-tier fallback reads an absent
    # $HOME/.aid/registry.yml (empty) rather than the developer's real one (registry-union fix).
    HOME="${PT1_PINNED_HOME}" AID_HOME="$aid_home" python3 "${REPO_ROOT}/dashboard/server/server.py" \
        --host 127.0.0.1 --port "$port" \
        >/dev/null 2>&1 &
    _BGPIDS+=($!)
}

start_node_server() {
    local port="$1"
    local aid_home="$2"
    # Pin HOME to a throwaway dir (same reason as above).
    HOME="${PT1_PINNED_HOME}" AID_HOME="$aid_home" node "${REPO_ROOT}/dashboard/server/server.mjs" \
        --host 127.0.0.1 --port "$port" \
        >/dev/null 2>&1 &
    _BGPIDS+=($!)
}

# ---------------------------------------------------------------------------
# start_server_with_retry SERVER_FN AID_HOME
#   Bounded pick->start->verify retry so the suite is safe in the
#   bounded-parallel runner (feature-003 Port Isolation, FR-3/NFR-3): pick an
#   ephemeral port (net.sh find_free_port), start SERVER_FN on it, and confirm
#   bring-up with wait_for_port. On a lost-port TOCTOU race (the server never
#   comes up because another process grabbed the port in the pick->bind gap) it
#   kills the stray child, re-picks a fresh port, and retries up to a small
#   bound -- turning a rare concurrency race into a deterministic re-pick.
#   Wraps SETUP only (never an assertion -- AC-3). On success sets _RETRY_PORT /
#   _RETRY_PID and returns 0; after the bound is exhausted returns 1 with
#   _RETRY_PORT / _RETRY_PID set to the last attempt (for the caller's fail
#   message + cleanup).
# ---------------------------------------------------------------------------
_RETRY_PORT=""
_RETRY_PID=""
start_server_with_retry() {
    local server_fn="$1"
    local aid_home="$2"
    local attempts=3
    local i port pid
    for (( i=1; i<=attempts; i++ )); do
        port=$(find_free_port)
        "$server_fn" "$port" "$aid_home"
        pid="${_BGPIDS[-1]}"
        if wait_for_port "$port" 12; then
            _RETRY_PORT="$port"
            _RETRY_PID="$pid"
            return 0
        fi
        kill "$pid" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$pid}")
    done
    _RETRY_PORT="$port"
    _RETRY_PID="$pid"
    return 1
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

    # Ports are picked inside start_server_with_retry (per-server ephemeral
    # allocation + bounded re-pick); the py/node servers run sequentially here
    # (each is killed before the next starts), so no cross-port coordination is
    # needed. The OS will not hand out a still-bound port, so the two are distinct.
    local py_port="" node_port=""

    log "Fixture: $label"

    # Build temporary aid-home with a single-entry registry for this fixture.
    local aid_home
    aid_home=$(build_single_repo_aid_home "$fixture_root" "$label")

    # --- Python half ---
    if [[ $HAS_PYTHON -eq 1 ]]; then
        local py_pid
        if start_server_with_retry start_python_server "$aid_home"; then
            py_port="$_RETRY_PORT"; py_pid="$_RETRY_PID"
            if fetch_api_model "$py_port" "${PT1_PY_RAW}"; then
                pass "[$label] python server responds on /r/<id>/api/model"
                if python3 -c "import json; json.load(open('${PT1_PY_RAW}'))" 2>/dev/null; then
                    pass "[$label] python /r/<id>/api/model is valid JSON"
                else
                    fail "[$label] python /r/<id>/api/model is not valid JSON"
                fi
            else
                fail "[$label] python server /r/<id>/api/model fetch failed"
            fi
        else
            py_port="$_RETRY_PORT"; py_pid="$_RETRY_PID"
            fail "[$label] python server did not start within 12s on port $py_port"
        fi

        kill "$py_pid" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$py_pid}")
    fi

    # --- Node half ---
    if [[ $HAS_NODE -eq 1 ]]; then
        local node_pid
        if start_server_with_retry start_node_server "$aid_home"; then
            node_port="$_RETRY_PORT"; node_pid="$_RETRY_PID"
            if fetch_api_model "$node_port" "${PT1_NODE_RAW}"; then
                pass "[$label] node server responds on /r/<id>/api/model"
                if python3 -c "import json; json.load(open('${PT1_NODE_RAW}'))" 2>/dev/null; then
                    pass "[$label] node /r/<id>/api/model is valid JSON"
                else
                    fail "[$label] node /r/<id>/api/model is not valid JSON"
                fi
            else
                fail "[$label] node server /r/<id>/api/model fetch failed"
            fi
        else
            node_port="$_RETRY_PORT"; node_pid="$_RETRY_PID"
            fail "[$label] node server did not start within 12s on port $node_port"
        fi

        kill "$node_pid" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$node_pid}")
    fi

    # --- Parity check (only when BOTH runtimes are present and both fetches succeeded) ---
    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 ]]; then
        if [[ -f ${PT1_PY_RAW} && -f ${PT1_NODE_RAW} ]]; then
            normalize_json ${PT1_PY_RAW} ${PT1_PY_NORM}
            normalize_json ${PT1_NODE_RAW} ${PT1_NODE_NORM}

            # Byte-identical comparison (PT-1 core assertion)
            if cmp -s ${PT1_PY_NORM} ${PT1_NODE_NORM}; then
                pass "[$label] python == node (byte-identical after strip+normalize)"
            else
                fail "[$label] python != node (NOT byte-identical after strip+normalize)"
                if [[ "$VERBOSE" -eq 1 ]]; then
                    echo "  --- diff (python vs node) ---"
                    diff ${PT1_PY_NORM} ${PT1_NODE_NORM} || true
                fi
            fi

            # R7: U+2028/U+2029 escaping guarantee.
            # Only checked for fixtures that contain U+2028/U+2029 (e.g. full-fixture).
            # The fixture manifest has literal U+2028/U+2029 bytes in aid_version.
            # Both servers MUST escape them (\\u2028/\\u2029) -- no raw bytes in output.
            if [[ "$check_r7" == "1" ]]; then
                python3 "${SCRIPT_DIR}/../lib/pt1_r7_check.py" \
                    ${PT1_PY_RAW} ${PT1_NODE_RAW}
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

    rm -f ${PT1_PY_RAW} ${PT1_NODE_RAW} ${PT1_PY_NORM} ${PT1_NODE_NORM}
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
    if start_server_with_retry start_python_server "$FULL_AID_HOME"; then
        local_py_port="$_RETRY_PORT"
        fetch_api_model "$local_py_port" "${PT1_PY_RAW}"

        schema_ver=$(python3 -c "import json; d = json.load(open('${PT1_PY_RAW}')); print(d.get('schema_version', 'MISSING'))")
        assert_eq "$schema_ver" "3" "[full-fixture] python schema_version == 3"

        gen_by=$(python3 -c "import json; d = json.load(open('${PT1_PY_RAW}')); print(d.get('generated_by', 'MISSING'))")
        assert_eq "$gen_by" "python" "[full-fixture] python generated_by == 'python'"

        read_at=$(python3 -c "import json; d = json.load(open('${PT1_PY_RAW}')); print(d['model']['read']['read_at'])")
        if [[ -n "$read_at" && "$read_at" != "None" ]]; then
            pass "[full-fixture] python model.read.read_at is non-empty"
        else
            fail "[full-fixture] python model.read.read_at is empty or None"
        fi
    fi

    local_py_pid="$_RETRY_PID"
    kill "$local_py_pid" 2>/dev/null || true
    _BGPIDS=("${_BGPIDS[@]/$local_py_pid}")
    rm -f ${PT1_PY_RAW}
fi

if [[ $HAS_NODE -eq 1 && $HAS_PYTHON -eq 1 ]]; then
    if start_server_with_retry start_node_server "$FULL_AID_HOME"; then
        local_node_port="$_RETRY_PORT"
        fetch_api_model "$local_node_port" "${PT1_NODE_RAW}"

        gen_by=$(python3 -c "import json; d = json.load(open('${PT1_NODE_RAW}')); print(d.get('generated_by', 'MISSING'))")
        assert_eq "$gen_by" "node" "[full-fixture] node generated_by == 'node'"
    fi

    local_node_pid="$_RETRY_PID"
    kill "$local_node_pid" 2>/dev/null || true
    _BGPIDS=("${_BGPIDS[@]/$local_node_pid}")
    rm -f ${PT1_NODE_RAW}
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

test_summary
