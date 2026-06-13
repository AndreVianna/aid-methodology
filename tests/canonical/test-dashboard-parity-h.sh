#!/usr/bin/env bash
# test-dashboard-parity-h.sh -- PT-1-H cross-runtime byte-parity test (task-056, feature-010).
#
# Extends PT-1 (test-dashboard-parity.sh) to cover the NEW multi-repo server shape
# introduced by delivery-008: AID_HOME (env-or-self-locate) with registry.yml, /api/home, and
# /r/<id>/{home.html,kb.html,api/model} routes.
#
# Assertions:
#   1. GET /api/home is byte-identical across Python and Node after excluding
#      {generated_by, machine.cli_runtime, read.read_at}.
#   2. GET /r/<id>/api/model is byte-identical for each repo including U+2028/U+2029
#      escape (R7), and the <id> derivation is byte-identical (DD-1/DD-5).
#   3. SEC-2 traversal-refusal set: ../, %2e%2e, absolute path, /r/<id>/../settings.yml,
#      /r/<id>/<workfolder>/STATE.md, broken-symlink leaf, unregistered <id>,
#      malformed <id> -- all return identical 404 from both runtimes.
#   4. SEC-1: no wildcard/0.0.0.0 bind in either server source.
#   5. SEC-3: no fs.write*/append*/os.remove/unlink in either server source.
#   6. SEC-4: no agent/LLM import in either server source.
#
# Registry fixture (checked-in under dashboard/server/tests/fixtures/):
#   pt1h-repo-a/  -- .aid/ with home+kb, manifest with U+2028/U+2029, STATE.md with chars
#   pt1h-repo-b/  -- .aid/ minimal (no dashboard/ subdir, no home/kb files)
#   [entry C]     -- nonexistent path (available=false, NFR10 degrade)
#
# The registry.yml is written into a temp dir at runtime with the actual absolute paths.
# (CAN-1: stored form is what the server hashes for id derivation.)
#
# Harness posture:
#   - python3 half: only if python3 present
#   - node half   : only if node present
#   - cross-runtime parity: only if BOTH runtimes present
#   - symlink test: skipped gracefully on filesystems without symlink support
#
# Usage:
#   bash tests/canonical/test-dashboard-parity-h.sh [-v | --verbose]
# Exit codes:
#   0 -- all asserted checks passed (or all were skipped)
#   1 -- one or more checks failed
#
# Source is ASCII-only (shipped script posture; coding-standards.md).
# Fixture data files may contain U+2028/U+2029 -- they are test DATA, not shipped scripts.

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

echo "=== PT-1-H cross-runtime byte-parity test (multi-repo shape) ==="
echo "  python3 present: $HAS_PYTHON"
echo "  node present:    $HAS_NODE"

if [[ $HAS_PYTHON -eq 0 && $HAS_NODE -eq 0 ]]; then
    echo "  SKIP: neither python3 nor node found; skipping all PT-1-H checks."
    echo "=== Summary ==="
    echo "  Tests passed: 0"
    echo "  Tests failed: 0"
    echo ""
    echo "All tests passed."
    exit 0
fi

# ---------------------------------------------------------------------------
# Checked-in fixture roots (absolute)
# ---------------------------------------------------------------------------

FIXTURE_BASE="${REPO_ROOT}/dashboard/server/tests/fixtures"
FIXTURE_REPO_A="${FIXTURE_BASE}/pt1h-repo-a"
FIXTURE_REPO_B="${FIXTURE_BASE}/pt1h-repo-b"
SERVER_PY="${REPO_ROOT}/dashboard/server/server.py"
SERVER_MJS="${REPO_ROOT}/dashboard/server/server.mjs"

# ---------------------------------------------------------------------------
# Temp dir: holds the runtime-built aid-home (registry.yml + temp dirs)
# ---------------------------------------------------------------------------

PT1H_TMP="$(mktemp -d /tmp/pt1h_XXXXXX)"

# ---------------------------------------------------------------------------
# Cleanup: kill background servers, remove temp files
# ---------------------------------------------------------------------------

declare -a _BGPIDS=()

cleanup() {
    for pid in "${_BGPIDS[@]+"${_BGPIDS[@]}"}"; do
        kill "$pid" 2>/dev/null || true
    done
    _BGPIDS=()
    rm -rf "$PT1H_TMP"
    rm -f /tmp/pt1h_py_home.json /tmp/pt1h_node_home.json \
          /tmp/pt1h_py_home_norm.json /tmp/pt1h_node_home_norm.json \
          /tmp/pt1h_py_model_a.json /tmp/pt1h_node_model_a.json \
          /tmp/pt1h_py_model_b.json /tmp/pt1h_node_model_b.json \
          /tmp/pt1h_py_model_a_norm.json /tmp/pt1h_node_model_a_norm.json \
          /tmp/pt1h_py_model_b_norm.json /tmp/pt1h_node_model_b_norm.json
}

trap cleanup EXIT

# ---------------------------------------------------------------------------
# AID_HOME builder: writes registry.yml with actual absolute paths
#
# Repos:
#   repo-a  : FIXTURE_REPO_A (with home+kb)
#   repo-b  : FIXTURE_REPO_B (minimal, no home+kb)
#   entry-c : nonexistent path (PT1H_TMP/nonexistent-repo-c)
#
# Returns the AID_HOME path in stdout.
# ---------------------------------------------------------------------------

build_aid_home() {
    local aid_home="${PT1H_TMP}/aid-home"
    mkdir -p "${aid_home}/dashboard"

    # Nonexistent entry: a path that definitely does not exist.
    local entry_c="${PT1H_TMP}/nonexistent-repo-c"

    # Write registry.yml with CAN-1 absolute paths.
    cat > "${aid_home}/registry.yml" << REGEOF
schema: 1
repos:
  - ${FIXTURE_REPO_A}
  - ${FIXTURE_REPO_B}
  - ${entry_c}
REGEOF

    echo "${aid_home}"
}

# AID_HOME is built once and shared across all sub-tests.
AID_HOME="$(build_aid_home)"
log "AID_HOME: ${AID_HOME}"
log "registry.yml:"
[[ "$VERBOSE" -eq 1 ]] && cat "${AID_HOME}/registry.yml"

# ---------------------------------------------------------------------------
# Port helpers
# ---------------------------------------------------------------------------

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
# Args: PORT TIMEOUT_SECS
wait_for_port_h() {
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
# Server start helpers
# ---------------------------------------------------------------------------

start_python_server_h() {
    local port="$1"
    local aid_home="$2"
    AID_HOME="$aid_home" python3 "${SERVER_PY}" \
        --host 127.0.0.1 --port "$port" \
        >/dev/null 2>&1 &
    _BGPIDS+=($!)
}

start_node_server_h() {
    local port="$1"
    local aid_home="$2"
    AID_HOME="$aid_home" node "${SERVER_MJS}" \
        --host 127.0.0.1 --port "$port" \
        >/dev/null 2>&1 &
    _BGPIDS+=($!)
}

# ---------------------------------------------------------------------------
# HTTP fetch helpers
# ---------------------------------------------------------------------------

# Fetch a URL and write to FILE. Returns 0 on success.
# Args: PORT PATH OUTFILE
fetch_url() {
    local port="$1"
    local urlpath="$2"
    local outfile="$3"
    python3 -c "
import urllib.request, sys
try:
    resp = urllib.request.urlopen('http://127.0.0.1:$port$urlpath', timeout=10)
    data = resp.read()
    open('$outfile', 'wb').write(data)
    sys.exit(0)
except Exception as e:
    sys.stderr.write('fetch failed: ' + str(e) + '\n')
    sys.exit(1)
"
}

# Fetch a URL and return the HTTP status code.
# Args: PORT PATH
fetch_status() {
    local port="$1"
    local urlpath="$2"
    python3 -c "
import urllib.request, urllib.error, sys
url = 'http://127.0.0.1:$port$urlpath'
try:
    resp = urllib.request.urlopen(url, timeout=10)
    print(resp.status)
except urllib.error.HTTPError as e:
    print(e.code)
except Exception as e:
    sys.stderr.write('fetch_status error: ' + str(e) + '\n')
    print(-1)
" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Normalization
# ---------------------------------------------------------------------------

# Normalize /api/home JSON: strip {generated_by, machine.cli_runtime, read.read_at}.
# U+2028/U+2029 post-process: replace raw chars with escaped form before compare.
normalize_home_json() {
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
if 'machine' in data:
    data['machine'].pop('cli_runtime', None)
if 'read' in data:
    data['read'].pop('read_at', None)
out = json.dumps(data, separators=(',', ':'), ensure_ascii=False)
out = out.replace(LS, '\\\\u2028').replace(PS, '\\\\u2029')
open('$outfile', 'w', encoding='utf-8').write(out)
"
}

# Normalize /r/<id>/api/model JSON: strip {generated_by, model.read.read_at}.
normalize_model_json() {
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
    data['model']['read'].pop('read_at', None)
out = json.dumps(data, separators=(',', ':'), ensure_ascii=False)
out = out.replace(LS, '\\\\u2028').replace(PS, '\\\\u2029')
open('$outfile', 'w', encoding='utf-8').write(out)
"
}

# ---------------------------------------------------------------------------
# Extract repo id for a given repo path from /api/home JSON
# Args: HOME_JSON_FILE REPO_PATH_SUFFIX
# Prints the id on stdout.
# ---------------------------------------------------------------------------

extract_repo_id() {
    local home_json="$1"
    local path_suffix="$2"
    python3 -c "
import json, sys
data = json.load(open('$home_json'))
for r in data.get('repos', []):
    if r['path'].endswith('$path_suffix'):
        print(r['id'])
        sys.exit(0)
sys.exit(1)
"
}

# ---------------------------------------------------------------------------
# Bring up BOTH servers (or one, if only one runtime present).
# Returns py_port and node_port via globals PY_PORT / NODE_PORT.
# ---------------------------------------------------------------------------

PY_PORT=""
NODE_PORT=""
PY_PID=""
NODE_PID=""

start_servers() {
    if [[ $HAS_PYTHON -eq 1 ]]; then
        PY_PORT=$(find_free_port)
        start_python_server_h "$PY_PORT" "$AID_HOME"
        PY_PID="${_BGPIDS[-1]}"
    fi

    if [[ $HAS_NODE -eq 1 ]]; then
        NODE_PORT=$(find_free_port)
        while [[ $HAS_PYTHON -eq 1 && "$NODE_PORT" == "$PY_PORT" ]]; do
            NODE_PORT=$(find_free_port)
        done
        start_node_server_h "$NODE_PORT" "$AID_HOME"
        NODE_PID="${_BGPIDS[-1]}"
    fi

    if [[ $HAS_PYTHON -eq 1 ]]; then
        if ! wait_for_port_h "$PY_PORT" 12; then
            fail "[PT-1-H] python server did not start within 12s on port $PY_PORT"
            return 1
        fi
        pass "[PT-1-H] python server started on port $PY_PORT"
    fi

    if [[ $HAS_NODE -eq 1 ]]; then
        if ! wait_for_port_h "$NODE_PORT" 12; then
            fail "[PT-1-H] node server did not start within 12s on port $NODE_PORT"
            return 1
        fi
        pass "[PT-1-H] node server started on port $NODE_PORT"
    fi

    return 0
}

stop_servers() {
    if [[ -n "$PY_PID" ]]; then
        kill "$PY_PID" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$PY_PID}")
        PY_PID=""
    fi
    if [[ -n "$NODE_PID" ]]; then
        kill "$NODE_PID" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$NODE_PID}")
        NODE_PID=""
    fi
}

# Start the servers once for all checks.
if ! start_servers; then
    test_summary
    exit 1
fi

log "Servers: py=$PY_PORT node=$NODE_PORT"

# ---------------------------------------------------------------------------
# Section 1: /api/home parity
# ---------------------------------------------------------------------------

echo ""
echo "--- Section 1: /api/home parity ---"

PY_HOME_OK=0
NODE_HOME_OK=0
PY_HOME_ID_A=""
NODE_HOME_ID_A=""
PY_HOME_ID_B=""
NODE_HOME_ID_B=""

if [[ $HAS_PYTHON -eq 1 ]]; then
    if fetch_url "$PY_PORT" "/api/home" "/tmp/pt1h_py_home.json"; then
        pass "[home] python /api/home responds"
        if python3 -c "import json; json.load(open('/tmp/pt1h_py_home.json'))" 2>/dev/null; then
            pass "[home] python /api/home is valid JSON"
            PY_HOME_OK=1
            PY_HOME_ID_A=$(extract_repo_id /tmp/pt1h_py_home.json "pt1h-repo-a") || true
            PY_HOME_ID_B=$(extract_repo_id /tmp/pt1h_py_home.json "pt1h-repo-b") || true
            log "python repo-a id: $PY_HOME_ID_A"
            log "python repo-b id: $PY_HOME_ID_B"
        else
            fail "[home] python /api/home is not valid JSON"
        fi
    else
        fail "[home] python /api/home fetch failed"
    fi
fi

if [[ $HAS_NODE -eq 1 ]]; then
    if fetch_url "$NODE_PORT" "/api/home" "/tmp/pt1h_node_home.json"; then
        pass "[home] node /api/home responds"
        if python3 -c "import json; json.load(open('/tmp/pt1h_node_home.json'))" 2>/dev/null; then
            pass "[home] node /api/home is valid JSON"
            NODE_HOME_OK=1
            NODE_HOME_ID_A=$(extract_repo_id /tmp/pt1h_node_home.json "pt1h-repo-a") || true
            NODE_HOME_ID_B=$(extract_repo_id /tmp/pt1h_node_home.json "pt1h-repo-b") || true
            log "node repo-a id: $NODE_HOME_ID_A"
            log "node repo-b id: $NODE_HOME_ID_B"
        else
            fail "[home] node /api/home is not valid JSON"
        fi
    else
        fail "[home] node /api/home fetch failed"
    fi
fi

# Parity check: /api/home byte-identical after normalization
if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && $PY_HOME_OK -eq 1 && $NODE_HOME_OK -eq 1 ]]; then
    normalize_home_json /tmp/pt1h_py_home.json /tmp/pt1h_py_home_norm.json
    normalize_home_json /tmp/pt1h_node_home.json /tmp/pt1h_node_home_norm.json

    if cmp -s /tmp/pt1h_py_home_norm.json /tmp/pt1h_node_home_norm.json; then
        pass "[home] python == node (byte-identical after strip+normalize)"
    else
        fail "[home] python != node (NOT byte-identical after strip+normalize)"
        if [[ "$VERBOSE" -eq 1 ]]; then
            echo "  --- diff (python vs node) ---"
            diff /tmp/pt1h_py_home_norm.json /tmp/pt1h_node_home_norm.json || true
        fi
    fi

    # --- Symlinked-AID_HOME parity (regression guard) ---
    # A symlinked $AID_HOME must NOT diverge machine.aid_home / machine.registry_path
    # across runtimes (those fields are NOT in the SEC-5 parity-excluded set). Python must
    # use the AID_HOME env value VERBATIM (no Path.resolve()/realpath), matching Node's
    # verbatim process.env.AID_HOME. This sub-test booted-with-a-symlinked-home guards the
    # exact "fixture-only parity masks real divergence" gap (PLAN R9). Skip gracefully where
    # the filesystem has no symlink support.
    _sl_home="${PT1H_TMP}/aid-home-symlink"
    if ln -s "$AID_HOME" "$_sl_home" 2>/dev/null; then
        _sl_py_port="$(find_free_port)"; _sl_node_port="$(find_free_port)"
        start_python_server_h "$_sl_py_port" "$_sl_home"
        start_node_server_h "$_sl_node_port" "$_sl_home"
        if wait_for_port_h "$_sl_py_port" 12 && wait_for_port_h "$_sl_node_port" 12 \
           && fetch_url "$_sl_py_port" "/api/home" "/tmp/pt1h_sl_py.json" \
           && fetch_url "$_sl_node_port" "/api/home" "/tmp/pt1h_sl_node.json"; then
            normalize_home_json /tmp/pt1h_sl_py.json /tmp/pt1h_sl_py_norm.json
            normalize_home_json /tmp/pt1h_sl_node.json /tmp/pt1h_sl_node_norm.json
            if cmp -s /tmp/pt1h_sl_py_norm.json /tmp/pt1h_sl_node_norm.json; then
                pass "[home] symlinked AID_HOME: python == node (no realpath divergence on aid_home/registry_path)"
            else
                fail "[home] symlinked AID_HOME: python != node (realpath divergence on aid_home/registry_path)"
                [[ "$VERBOSE" -eq 1 ]] && diff /tmp/pt1h_sl_py_norm.json /tmp/pt1h_sl_node_norm.json || true
            fi
        else
            fail "[home] symlinked AID_HOME: servers did not both come up / fetch failed"
        fi
    else
        pass "[home] symlinked AID_HOME parity [SKIPPED: filesystem has no symlink support]"
    fi

    # repo_count assertion: must have 3 entries (2 available + 1 unavailable)
    py_count=$(python3 -c "
import json
d = json.load(open('/tmp/pt1h_py_home.json'))
print(len(d.get('repos', [])))
")
    assert_eq "$py_count" "3" "[home] /api/home repos array has 3 entries (2 repos + 1 unavailable)"

    # available_count: repo-a and repo-b are available; entry-c is not
    unavail=$(python3 -c "
import json
d = json.load(open('/tmp/pt1h_py_home.json'))
print(d.get('read', {}).get('unavailable_count', -1))
")
    assert_eq "$unavail" "1" "[home] unavailable_count == 1 (entry-c nonexistent)"

    # repo-a has_home=true, has_kb=true
    repo_a_flags=$(python3 -c "
import json
d = json.load(open('/tmp/pt1h_py_home.json'))
for r in d.get('repos', []):
    if r['path'].endswith('pt1h-repo-a'):
        print(r['has_home'], r['has_kb'], r['available'])
        break
")
    assert_eq "$repo_a_flags" "True True True" "[home] repo-a has_home=True has_kb=True available=True"

    # repo-b has_home=false, has_kb=false, available=true
    repo_b_flags=$(python3 -c "
import json
d = json.load(open('/tmp/pt1h_py_home.json'))
for r in d.get('repos', []):
    if r['path'].endswith('pt1h-repo-b'):
        print(r['has_home'], r['has_kb'], r['available'])
        break
")
    assert_eq "$repo_b_flags" "False False True" "[home] repo-b has_home=False has_kb=False available=True"

    # entry-c (nonexistent) is available=false
    repo_c_avail=$(python3 -c "
import json
d = json.load(open('/tmp/pt1h_py_home.json'))
for r in d.get('repos', []):
    if 'nonexistent' in r['path']:
        print(r['available'])
        break
")
    assert_eq "$repo_c_avail" "False" "[home] entry-c available=False (NFR10)"
fi

# ID parity: same <id> for each repo from both runtimes (DD-1/DD-5)
if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && $PY_HOME_OK -eq 1 && $NODE_HOME_OK -eq 1 ]]; then
    if [[ -n "$PY_HOME_ID_A" && -n "$NODE_HOME_ID_A" ]]; then
        if [[ "$PY_HOME_ID_A" == "$NODE_HOME_ID_A" ]]; then
            pass "[home] repo-a id byte-identical across runtimes: $PY_HOME_ID_A"
        else
            fail "[home] repo-a id differs: python=$PY_HOME_ID_A node=$NODE_HOME_ID_A (DD-1/DD-5 violation)"
        fi
    else
        fail "[home] could not extract repo-a id from one or both /api/home responses"
    fi

    if [[ -n "$PY_HOME_ID_B" && -n "$NODE_HOME_ID_B" ]]; then
        if [[ "$PY_HOME_ID_B" == "$NODE_HOME_ID_B" ]]; then
            pass "[home] repo-b id byte-identical across runtimes: $PY_HOME_ID_B"
        else
            fail "[home] repo-b id differs: python=$PY_HOME_ID_B node=$NODE_HOME_ID_B (DD-1/DD-5 violation)"
        fi
    else
        fail "[home] could not extract repo-b id from one or both /api/home responses"
    fi
fi

# ---------------------------------------------------------------------------
# Section 2: /r/<id>/api/model parity (per repo)
# ---------------------------------------------------------------------------

echo ""
echo "--- Section 2: /r/<id>/api/model parity ---"

# Use repo-a id from python (or node if python absent); both should be identical.
MODEL_ID_A="${PY_HOME_ID_A:-$NODE_HOME_ID_A}"
MODEL_ID_B="${PY_HOME_ID_B:-$NODE_HOME_ID_B}"

if [[ -z "$MODEL_ID_A" || -z "$MODEL_ID_B" ]]; then
    fail "[model] could not determine repo ids; skipping /r/<id>/api/model tests"
else
    # Fetch /r/<id>/api/model for repo-a from both runtimes
    PY_MODEL_A_OK=0
    NODE_MODEL_A_OK=0

    if [[ $HAS_PYTHON -eq 1 ]]; then
        if fetch_url "$PY_PORT" "/r/${MODEL_ID_A}/api/model" "/tmp/pt1h_py_model_a.json"; then
            pass "[model-a] python /r/${MODEL_ID_A}/api/model responds"
            if python3 -c "import json; json.load(open('/tmp/pt1h_py_model_a.json'))" 2>/dev/null; then
                pass "[model-a] python /r/${MODEL_ID_A}/api/model is valid JSON"
                PY_MODEL_A_OK=1
            else
                fail "[model-a] python /r/${MODEL_ID_A}/api/model is not valid JSON"
            fi
        else
            fail "[model-a] python /r/${MODEL_ID_A}/api/model fetch failed"
        fi
    fi

    if [[ $HAS_NODE -eq 1 ]]; then
        if fetch_url "$NODE_PORT" "/r/${MODEL_ID_A}/api/model" "/tmp/pt1h_node_model_a.json"; then
            pass "[model-a] node /r/${MODEL_ID_A}/api/model responds"
            if python3 -c "import json; json.load(open('/tmp/pt1h_node_model_a.json'))" 2>/dev/null; then
                pass "[model-a] node /r/${MODEL_ID_A}/api/model is valid JSON"
                NODE_MODEL_A_OK=1
            else
                fail "[model-a] node /r/${MODEL_ID_A}/api/model is not valid JSON"
            fi
        else
            fail "[model-a] node /r/${MODEL_ID_A}/api/model fetch failed"
        fi
    fi

    # Parity + R7 for repo-a
    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && $PY_MODEL_A_OK -eq 1 && $NODE_MODEL_A_OK -eq 1 ]]; then
        normalize_model_json /tmp/pt1h_py_model_a.json /tmp/pt1h_py_model_a_norm.json
        normalize_model_json /tmp/pt1h_node_model_a.json /tmp/pt1h_node_model_a_norm.json

        if cmp -s /tmp/pt1h_py_model_a_norm.json /tmp/pt1h_node_model_a_norm.json; then
            pass "[model-a] python == node (byte-identical after strip+normalize)"
        else
            fail "[model-a] python != node (NOT byte-identical after strip+normalize)"
            if [[ "$VERBOSE" -eq 1 ]]; then
                echo "  --- diff (python vs node) ---"
                diff /tmp/pt1h_py_model_a_norm.json /tmp/pt1h_node_model_a_norm.json || true
            fi
        fi

        # R7: U+2028/U+2029 escaped in /r/<id>/api/model for repo-a (manifest has them)
        python3 "${SCRIPT_DIR}/../lib/pt1h_r7_check.py" \
            /tmp/pt1h_py_model_a.json /tmp/pt1h_node_model_a.json
        r7_rc=$?
        if [[ $r7_rc -eq 0 ]]; then
            pass "[model-a] R7: U+2028/U+2029 escaped (not raw) in both runtimes"
        else
            fail "[model-a] R7: U+2028/U+2029 escaping violated (see above)"
        fi
    else
        log "[model-a] skipping parity check: one or both fetches failed or single runtime"
    fi

    # Fetch /r/<id>/api/model for repo-b from both runtimes
    PY_MODEL_B_OK=0
    NODE_MODEL_B_OK=0

    if [[ $HAS_PYTHON -eq 1 ]]; then
        if fetch_url "$PY_PORT" "/r/${MODEL_ID_B}/api/model" "/tmp/pt1h_py_model_b.json"; then
            pass "[model-b] python /r/${MODEL_ID_B}/api/model responds"
            if python3 -c "import json; json.load(open('/tmp/pt1h_py_model_b.json'))" 2>/dev/null; then
                pass "[model-b] python /r/${MODEL_ID_B}/api/model is valid JSON"
                PY_MODEL_B_OK=1
            else
                fail "[model-b] python /r/${MODEL_ID_B}/api/model is not valid JSON"
            fi
        else
            fail "[model-b] python /r/${MODEL_ID_B}/api/model fetch failed"
        fi
    fi

    if [[ $HAS_NODE -eq 1 ]]; then
        if fetch_url "$NODE_PORT" "/r/${MODEL_ID_B}/api/model" "/tmp/pt1h_node_model_b.json"; then
            pass "[model-b] node /r/${MODEL_ID_B}/api/model responds"
            if python3 -c "import json; json.load(open('/tmp/pt1h_node_model_b.json'))" 2>/dev/null; then
                pass "[model-b] node /r/${MODEL_ID_B}/api/model is valid JSON"
                NODE_MODEL_B_OK=1
            else
                fail "[model-b] node /r/${MODEL_ID_B}/api/model is not valid JSON"
            fi
        else
            fail "[model-b] node /r/${MODEL_ID_B}/api/model fetch failed"
        fi
    fi

    # Parity for repo-b
    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && $PY_MODEL_B_OK -eq 1 && $NODE_MODEL_B_OK -eq 1 ]]; then
        normalize_model_json /tmp/pt1h_py_model_b.json /tmp/pt1h_py_model_b_norm.json
        normalize_model_json /tmp/pt1h_node_model_b.json /tmp/pt1h_node_model_b_norm.json

        if cmp -s /tmp/pt1h_py_model_b_norm.json /tmp/pt1h_node_model_b_norm.json; then
            pass "[model-b] python == node (byte-identical after strip+normalize)"
        else
            fail "[model-b] python != node (NOT byte-identical after strip+normalize)"
            if [[ "$VERBOSE" -eq 1 ]]; then
                echo "  --- diff (python vs node) ---"
                diff /tmp/pt1h_py_model_b_norm.json /tmp/pt1h_node_model_b_norm.json || true
            fi
        fi
    else
        log "[model-b] skipping parity check: one or both fetches failed or single runtime"
    fi

    # Cross-id check: a URL minted under one runtime resolves under the other (DD-1/DD-5)
    # We already verified the ids are byte-identical above (Section 1).
    # Here we additionally confirm that the id from the python /api/home resolves in node and vice-versa.
    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && -n "$PY_HOME_ID_A" && -n "$NODE_HOME_ID_A" ]]; then
        # GET /r/<py-derived-id>/api/model from node server (cross-runtime URL resolution)
        cross_status=$(fetch_status "$NODE_PORT" "/r/${PY_HOME_ID_A}/api/model")
        if [[ "$cross_status" == "200" ]]; then
            pass "[model-a] DD-1/DD-5: python-minted id resolves on node server (200)"
        else
            fail "[model-a] DD-1/DD-5: python-minted id returned $cross_status on node server (expected 200)"
        fi

        # GET /r/<node-derived-id>/api/model from python server
        cross_status=$(fetch_status "$PY_PORT" "/r/${NODE_HOME_ID_A}/api/model")
        if [[ "$cross_status" == "200" ]]; then
            pass "[model-a] DD-1/DD-5: node-minted id resolves on python server (200)"
        else
            fail "[model-a] DD-1/DD-5: node-minted id returned $cross_status on python server (expected 200)"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Section 3: SEC-2 traversal-refusal set
# ---------------------------------------------------------------------------

echo ""
echo "--- Section 3: SEC-2 traversal-refusal set ---"

# We need a valid registered id to construct /r/<id>/... traversal attempts.
# Use MODEL_ID_A (repo-a) which is definitely registered.
# We also need a work folder name to construct /r/<id>/<workfolder>/STATE.md
WORK_FOLDER_A="work-001-with-unicode"

# Helper: assert both runtimes return 404 for a given path
check_traversal_refusal() {
    local urlpath="$1"
    local label="$2"
    local py_status="" node_status=""

    if [[ $HAS_PYTHON -eq 1 ]]; then
        py_status=$(fetch_status "$PY_PORT" "$urlpath")
    fi
    if [[ $HAS_NODE -eq 1 ]]; then
        node_status=$(fetch_status "$NODE_PORT" "$urlpath")
    fi

    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 ]]; then
        if [[ "$py_status" == "404" && "$node_status" == "404" ]]; then
            pass "[sec2] $label: both return 404"
        elif [[ "$py_status" != "404" && "$node_status" != "404" ]]; then
            fail "[sec2] $label: both returned non-404 (py=$py_status node=$node_status)"
        elif [[ "$py_status" != "404" ]]; then
            fail "[sec2] $label: python returned $py_status (expected 404)"
        else
            fail "[sec2] $label: node returned $node_status (expected 404)"
        fi
    elif [[ $HAS_PYTHON -eq 1 ]]; then
        if [[ "$py_status" == "404" ]]; then
            pass "[sec2] $label: python returns 404"
        else
            fail "[sec2] $label: python returned $py_status (expected 404)"
        fi
    else
        if [[ "$node_status" == "404" ]]; then
            pass "[sec2] $label: node returns 404"
        else
            fail "[sec2] $label: node returned $node_status (expected 404)"
        fi
    fi
}

# Also assert that both runtimes return IDENTICAL status codes
check_traversal_status_identical() {
    local urlpath="$1"
    local label="$2"
    local py_status="" node_status=""

    if [[ $HAS_PYTHON -eq 1 ]]; then
        py_status=$(fetch_status "$PY_PORT" "$urlpath")
    fi
    if [[ $HAS_NODE -eq 1 ]]; then
        node_status=$(fetch_status "$NODE_PORT" "$urlpath")
    fi

    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 ]]; then
        if [[ "$py_status" == "$node_status" ]]; then
            pass "[sec2] $label: both return $py_status (identical)"
        else
            fail "[sec2] $label: statuses differ (py=$py_status node=$node_status)"
        fi
    fi
}

# --- Traversal attacks via URL path ---

# 1. Simple ../ in path (not matching route regex -> 404)
check_traversal_refusal "/r/../settings.yml" "path ../ traversal"

# 2. %2e%2e (URL-encoded dot-dot) -> server decodes to .. but regex fails
check_traversal_refusal "/r/%2e%2e/settings.yml" "%2e%2e traversal"

# 3. Absolute path attempt (not matching route regex)
check_traversal_refusal "/etc/passwd" "absolute /etc/passwd path"

# 4. /r/<id>/../settings.yml (valid id prefix, then traversal in leaf position)
# The route regex requires leaf to be (home\.html|kb\.html|api/model); ../ won't match.
if [[ -n "$MODEL_ID_A" ]]; then
    check_traversal_refusal "/r/${MODEL_ID_A}/../settings.yml" "/r/<id>/../settings.yml traversal"
fi

# 5. /r/<id>/<workfolder>/STATE.md (non-leaf path component not in allowlist)
if [[ -n "$MODEL_ID_A" ]]; then
    check_traversal_refusal "/r/${MODEL_ID_A}/${WORK_FOLDER_A}/STATE.md" "/r/<id>/<workfolder>/STATE.md"
fi

# 6. Unregistered <id> (valid hex format but not in the registry map)
# Use a known hex string that won't collide with real ids.
check_traversal_refusal "/r/deadbeef/api/model" "unregistered id (deadbeef)"
check_traversal_refusal "/r/deadbeefdeadbeef/api/model" "unregistered id (deadbeefdeadbeef)"

# 7. Malformed <id> (too short, non-hex chars -- route regex won't match at all)
check_traversal_refusal "/r/abc/api/model" "malformed id (too short: abc)"
check_traversal_refusal "/r/DEADBEEF/api/model" "malformed id (uppercase hex: DEADBEEF)"
check_traversal_refusal "/r/xyz12345/api/model" "malformed id (non-hex chars: xyz12345)"

# 8. Symlinked leaf -> outside (broken symlink: is_file() returns False -> 404)
# Create a broken symlink at pt1h-repo-a/.aid/dashboard/broken.html -> nonexistent target.
# Note: the route only accepts home.html/kb.html/api/model, so broken.html won't match anyway.
# Instead test with a symlink replacing home.html itself in a temp repo.
SYMLINK_SUPPORTED=0
SYMLINK_REPO="${PT1H_TMP}/symlink-repo"

mkdir -p "${SYMLINK_REPO}/.aid/dashboard"
cp "${FIXTURE_REPO_A}/.aid/.aid-manifest.json" "${SYMLINK_REPO}/.aid/"
cp "${FIXTURE_REPO_A}/.aid/settings.yml" "${SYMLINK_REPO}/.aid/"

# Attempt to create a broken symlink: home.html -> /nonexistent/outside/path
if ln -s "/nonexistent/outside/path/that/does/not/exist" \
       "${SYMLINK_REPO}/.aid/dashboard/home.html" 2>/dev/null; then
    SYMLINK_SUPPORTED=1
    log "Symlink created at ${SYMLINK_REPO}/.aid/dashboard/home.html"
fi

if [[ $SYMLINK_SUPPORTED -eq 1 ]]; then
    # Add symlink-repo to the registry and restart servers with updated registry.
    # Write an extended registry pointing to the symlink-repo too.
    SYMLINK_AID_HOME="${PT1H_TMP}/aid-home-sym"
    mkdir -p "${SYMLINK_AID_HOME}/dashboard"
    cat > "${SYMLINK_AID_HOME}/registry.yml" << SYMEOF
schema: 1
repos:
  - ${FIXTURE_REPO_A}
  - ${FIXTURE_REPO_B}
  - ${SYMLINK_REPO}
  - ${PT1H_TMP}/nonexistent-repo-c
SYMEOF

    # Start fresh servers against the symlink registry.
    SPYPORT=$(find_free_port)
    SNODEPORT=$(find_free_port)
    while [[ "$SNODEPORT" == "$SPYPORT" ]]; do SNODEPORT=$(find_free_port); done

    SYM_PY_PID="" SYM_NODE_PID=""

    if [[ $HAS_PYTHON -eq 1 ]]; then
        AID_HOME="$SYMLINK_AID_HOME" python3 "${SERVER_PY}" \
            --host 127.0.0.1 --port "$SPYPORT" \
            >/dev/null 2>&1 &
        SYM_PY_PID=$!
        _BGPIDS+=($SYM_PY_PID)
    fi
    if [[ $HAS_NODE -eq 1 ]]; then
        AID_HOME="$SYMLINK_AID_HOME" node "${SERVER_MJS}" \
            --host 127.0.0.1 --port "$SNODEPORT" \
            >/dev/null 2>&1 &
        SYM_NODE_PID=$!
        _BGPIDS+=($SYM_NODE_PID)
    fi

    SYMLINK_READY=0
    if [[ $HAS_PYTHON -eq 1 ]]; then
        if wait_for_port_h "$SPYPORT" 10; then
            SYMLINK_READY=1
        fi
    elif [[ $HAS_NODE -eq 1 ]]; then
        if wait_for_port_h "$SNODEPORT" 10; then
            SYMLINK_READY=1
        fi
    fi

    if [[ $SYMLINK_READY -eq 1 ]]; then
        # Get the id for symlink-repo from python or node
        SYM_HOME_JSON="${PT1H_TMP}/sym-home.json"
        SYM_FETCH_PORT="${SPYPORT}"
        [[ $HAS_PYTHON -eq 0 ]] && SYM_FETCH_PORT="${SNODEPORT}"

        if fetch_url "$SYM_FETCH_PORT" "/api/home" "$SYM_HOME_JSON" 2>/dev/null; then
            SYM_ID=$(python3 -c "
import json, sys
data = json.load(open('$SYM_HOME_JSON'))
for r in data.get('repos', []):
    if 'symlink-repo' in r['path']:
        print(r['id'])
        sys.exit(0)
sys.exit(1)
" 2>/dev/null) || SYM_ID=""

            if [[ -n "$SYM_ID" ]]; then
                # The broken symlink should cause is_file() to return False -> 404
                SYM_PY_STATUS="" SYM_NODE_STATUS=""
                if [[ $HAS_PYTHON -eq 1 ]]; then
                    SYM_PY_STATUS=$(fetch_status "$SPYPORT" "/r/${SYM_ID}/home.html")
                fi
                if [[ $HAS_NODE -eq 1 ]]; then
                    SYM_NODE_STATUS=$(fetch_status "$SNODEPORT" "/r/${SYM_ID}/home.html")
                fi

                if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 ]]; then
                    if [[ "$SYM_PY_STATUS" == "404" && "$SYM_NODE_STATUS" == "404" ]]; then
                        pass "[sec2] broken symlink leaf: both return 404 (identical)"
                    else
                        fail "[sec2] broken symlink leaf: py=$SYM_PY_STATUS node=$SYM_NODE_STATUS (expected both 404)"
                    fi
                elif [[ $HAS_PYTHON -eq 1 ]]; then
                    if [[ "$SYM_PY_STATUS" == "404" ]]; then
                        pass "[sec2] broken symlink leaf: python returns 404"
                    else
                        fail "[sec2] broken symlink leaf: python returned $SYM_PY_STATUS (expected 404)"
                    fi
                else
                    if [[ "$SYM_NODE_STATUS" == "404" ]]; then
                        pass "[sec2] broken symlink leaf: node returns 404"
                    else
                        fail "[sec2] broken symlink leaf: node returned $SYM_NODE_STATUS (expected 404)"
                    fi
                fi
            else
                log "[sec2] symlink-repo id not found; skipping broken-symlink assertion"
            fi
        else
            log "[sec2] could not fetch /api/home from symlink server; skipping broken-symlink assertion"
        fi
    else
        log "[sec2] symlink server did not start; skipping broken-symlink assertion"
    fi

    # Clean up symlink servers
    [[ -n "$SYM_PY_PID" ]] && { kill "$SYM_PY_PID" 2>/dev/null || true; _BGPIDS=("${_BGPIDS[@]/$SYM_PY_PID}"); }
    [[ -n "$SYM_NODE_PID" ]] && { kill "$SYM_NODE_PID" 2>/dev/null || true; _BGPIDS=("${_BGPIDS[@]/$SYM_NODE_PID}"); }
else
    log "[sec2] symlink not supported on this filesystem; skipping broken-symlink assertion"
fi

# Additionally: non-GET methods return 405 identically from both runtimes.
# fetch_status uses GET; for method parity we issue a POST explicitly.
check_method_refusal() {
    local urlpath="$1"
    local method="$2"
    local label="$3"
    local py_status="" node_status=""

    if [[ $HAS_PYTHON -eq 1 ]]; then
        py_status=$(python3 -c "
import urllib.request, urllib.error, sys
url = 'http://127.0.0.1:$PY_PORT$urlpath'
req = urllib.request.Request(url, data=b'{}', method='$method')
try:
    resp = urllib.request.urlopen(req, timeout=10)
    print(resp.status)
except urllib.error.HTTPError as e:
    print(e.code)
except Exception as e:
    sys.stderr.write('fetch error: ' + str(e) + '\n')
    print(-1)
" 2>/dev/null)
    fi

    if [[ $HAS_NODE -eq 1 ]]; then
        node_status=$(python3 -c "
import urllib.request, urllib.error, sys
url = 'http://127.0.0.1:$NODE_PORT$urlpath'
req = urllib.request.Request(url, data=b'{}', method='$method')
try:
    resp = urllib.request.urlopen(req, timeout=10)
    print(resp.status)
except urllib.error.HTTPError as e:
    print(e.code)
except Exception as e:
    sys.stderr.write('fetch error: ' + str(e) + '\n')
    print(-1)
" 2>/dev/null)
    fi

    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 ]]; then
        if [[ "$py_status" == "405" && "$node_status" == "405" ]]; then
            pass "[sec2] $label: both return 405"
        else
            fail "[sec2] $label: py=$py_status node=$node_status (expected both 405)"
        fi
    elif [[ $HAS_PYTHON -eq 1 ]]; then
        [[ "$py_status" == "405" ]] && pass "[sec2] $label: python returns 405" \
            || fail "[sec2] $label: python returned $py_status (expected 405)"
    else
        [[ "$node_status" == "405" ]] && pass "[sec2] $label: node returns 405" \
            || fail "[sec2] $label: node returned $node_status (expected 405)"
    fi
}

check_method_refusal "/api/home" "POST" "POST /api/home -> 405 (non-GET refusal parity)"

# ---------------------------------------------------------------------------
# Section 4: SEC-1 self-check (no wildcard/0.0.0.0 bind in server source)
# ---------------------------------------------------------------------------

echo ""
echo "--- Section 4: SEC-1/3/4 source self-checks ---"

SERVER_PY_PATH="${REPO_ROOT}/dashboard/server/server.py"
SERVER_MJS_PATH="${REPO_ROOT}/dashboard/server/server.mjs"

# SEC-1: no 0.0.0.0 or wildcard bind (exclude comment lines).
# Only flag non-comment lines containing 0.0.0.0 (actual code, not documentation).
if grep -v "^\s*#\|^\s*//" "${SERVER_PY_PATH}" | grep -q "0\.0\.0\.0"; then
    fail "[sec1] server.py contains '0.0.0.0' in non-comment code (wildcard bind)"
else
    pass "[sec1] server.py: no '0.0.0.0' bind in non-comment code"
fi

if grep -v "^\s*//\|^\s*\*" "${SERVER_MJS_PATH}" | grep -q "0\.0\.0\.0"; then
    fail "[sec1] server.mjs contains '0.0.0.0' in non-comment code (wildcard bind)"
else
    pass "[sec1] server.mjs: no '0.0.0.0' bind in non-comment code"
fi

# SEC-1 positive: must contain literal 127.0.0.1 bind
if grep -q "127\.0\.0\.1" "${SERVER_PY_PATH}"; then
    pass "[sec1] server.py contains '127.0.0.1' (loopback bind)"
else
    fail "[sec1] server.py: missing '127.0.0.1' bind"
fi

if grep -q "127\.0\.0\.1" "${SERVER_MJS_PATH}"; then
    pass "[sec1] server.mjs contains '127.0.0.1' (loopback bind)"
else
    fail "[sec1] server.mjs: missing '127.0.0.1' bind"
fi

# SEC-3: no write/append/remove/unlink primitives in server source
# Python server: no open(... 'w'), no .write( on file objects opened for write,
# no os.remove, os.unlink, shutil calls (note: socket.wfile.write is OK -- that's HTTP response)
if grep -Eo "open\([^)]*['\"][wa]['\"]" "${SERVER_PY_PATH}" | grep -vq "^$"; then
    fail "[sec3] server.py: open() with write/append mode found"
else
    pass "[sec3] server.py: no open() with write/append mode"
fi

if grep -qE "\bos\.remove\b|\bos\.unlink\b|\bshutil\." "${SERVER_PY_PATH}"; then
    fail "[sec3] server.py: os.remove/os.unlink/shutil found"
else
    pass "[sec3] server.py: no os.remove/os.unlink/shutil"
fi

# Node server: no fs.writeFile, appendFile, fs.unlink, fs.rm
if grep -qE "\bfs\.(writeFile|appendFile|write|unlink|rm)\b" "${SERVER_MJS_PATH}"; then
    fail "[sec3] server.mjs: fs.write*/appendFile/unlink/rm found"
else
    pass "[sec3] server.mjs: no fs.write*/appendFile/unlink/rm"
fi

# SEC-4: no agent/LLM import
LLM_PATTERNS="anthropic|openai|langchain|llm|agent|claude-code|codex"

if grep -qiE "import.*(${LLM_PATTERNS})|require\(.*(${LLM_PATTERNS})" "${SERVER_PY_PATH}"; then
    fail "[sec4] server.py: agent/LLM import found"
else
    pass "[sec4] server.py: no agent/LLM import"
fi

if grep -qiE "import.*(${LLM_PATTERNS})|require\(.*(${LLM_PATTERNS})" "${SERVER_MJS_PATH}"; then
    fail "[sec4] server.mjs: agent/LLM import found"
else
    pass "[sec4] server.mjs: no agent/LLM import"
fi

# Also check the reader modules (they are imported by the servers)
READER_PY="${REPO_ROOT}/dashboard/reader/reader.py"
READER_MJS="${REPO_ROOT}/dashboard/server/reader.mjs"

if [[ -f "$READER_PY" ]]; then
    if grep -qiE "import.*(${LLM_PATTERNS})" "${READER_PY}"; then
        fail "[sec4] reader/reader.py: agent/LLM import found"
    else
        pass "[sec4] reader/reader.py: no agent/LLM import"
    fi
fi

if [[ -f "$READER_MJS" ]]; then
    if grep -qiE "import.*(${LLM_PATTERNS})|require\(.*(${LLM_PATTERNS})" "${READER_MJS}"; then
        fail "[sec4] server/reader.mjs: agent/LLM import found"
    else
        pass "[sec4] server/reader.mjs: no agent/LLM import"
    fi
fi

# ---------------------------------------------------------------------------
# Stop servers
# ---------------------------------------------------------------------------

stop_servers

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
test_summary
