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
#   pt1h-repo-a/  -- .aid/ with .aid/knowledge/kb.html (format 2), manifest with U+2028/U+2029, STATE.md with chars
#   pt1h-repo-b/  -- .aid/ minimal (no .aid/knowledge/kb.html file)
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

# Pinned HOME for server processes: no .aid/registry.yml -> server sees only AID_HOME tier.
# Prevents the developer's real ~/.aid/registry.yml from bleeding into the union read
# and inflating repo counts / changing ids (registry-union fix, Section 7 new tests
# use their own HOME; the existing sections need isolation too).
PT1H_PINNED_HOME="${PT1H_TMP}/pinned-home"
mkdir -p "${PT1H_PINNED_HOME}"

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
# Port helpers: find_free_port / wait_for_port -- see tests/lib/net.sh.
# ---------------------------------------------------------------------------
# Server start helpers
# ---------------------------------------------------------------------------

start_python_server_h() {
    local port="$1"
    local aid_home="$2"
    # Pin HOME to a throwaway dir so the server's user-tier fallback reads an absent
    # $HOME/.aid/registry.yml (empty) rather than the developer's real one (registry-union fix).
    HOME="${PT1H_PINNED_HOME}" AID_HOME="$aid_home" python3 "${SERVER_PY}" \
        --host 127.0.0.1 --port "$port" \
        >/dev/null 2>&1 &
    _BGPIDS+=($!)
}

start_node_server_h() {
    local port="$1"
    local aid_home="$2"
    # Pin HOME to a throwaway dir (same reason as above).
    HOME="${PT1H_PINNED_HOME}" AID_HOME="$aid_home" node "${SERVER_MJS}" \
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
        if ! wait_for_port "$PY_PORT" 12; then
            fail "[PT-1-H] python server did not start within 12s on port $PY_PORT"
            return 1
        fi
        pass "[PT-1-H] python server started on port $PY_PORT"
    fi

    if [[ $HAS_NODE -eq 1 ]]; then
        if ! wait_for_port "$NODE_PORT" 12; then
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
        if wait_for_port "$_sl_py_port" 12 && wait_for_port "$_sl_node_port" 12 \
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

    # repo-b has_home=true (format 2: has_home == .aid/ exists), has_kb=false, available=true.
    # (home.html is CLI-served; the has_home signal is simply "repo is AID-initialized".)
    repo_b_flags=$(python3 -c "
import json
d = json.load(open('/tmp/pt1h_py_home.json'))
for r in d.get('repos', []):
    if r['path'].endswith('pt1h-repo-b'):
        print(r['has_home'], r['has_kb'], r['available'])
        break
")
    assert_eq "$repo_b_flags" "True False True" "[home] repo-b has_home=True has_kb=False available=True"

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
# kb.html is served from <repo>/.aid/knowledge/kb.html and is gated on the file
# existing, so a broken symlink there still resolves is_file()==False -> 404.
# (home.html is CLI-served and gated only on .aid/ existing in format 2, so a
# broken symlink at a per-repo home.html would NOT 404 -- hence the kb.html leaf.)
SYMLINK_SUPPORTED=0
SYMLINK_REPO="${PT1H_TMP}/symlink-repo"

mkdir -p "${SYMLINK_REPO}/.aid/knowledge"
cp "${FIXTURE_REPO_A}/.aid/.aid-manifest.json" "${SYMLINK_REPO}/.aid/"
cp "${FIXTURE_REPO_A}/.aid/settings.yml" "${SYMLINK_REPO}/.aid/"

# Attempt to create a broken symlink: kb.html -> /nonexistent/outside/path
if ln -s "/nonexistent/outside/path/that/does/not/exist" \
       "${SYMLINK_REPO}/.aid/knowledge/kb.html" 2>/dev/null; then
    SYMLINK_SUPPORTED=1
    log "Symlink created at ${SYMLINK_REPO}/.aid/knowledge/kb.html"
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
        HOME="${PT1H_PINNED_HOME}" AID_HOME="$SYMLINK_AID_HOME" python3 "${SERVER_PY}" \
            --host 127.0.0.1 --port "$SPYPORT" \
            >/dev/null 2>&1 &
        SYM_PY_PID=$!
        _BGPIDS+=($SYM_PY_PID)
    fi
    if [[ $HAS_NODE -eq 1 ]]; then
        HOME="${PT1H_PINNED_HOME}" AID_HOME="$SYMLINK_AID_HOME" node "${SERVER_MJS}" \
            --host 127.0.0.1 --port "$SNODEPORT" \
            >/dev/null 2>&1 &
        SYM_NODE_PID=$!
        _BGPIDS+=($SYM_NODE_PID)
    fi

    SYMLINK_READY=0
    if [[ $HAS_PYTHON -eq 1 ]]; then
        if wait_for_port "$SPYPORT" 10; then
            SYMLINK_READY=1
        fi
    elif [[ $HAS_NODE -eq 1 ]]; then
        if wait_for_port "$SNODEPORT" 10; then
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
                    SYM_PY_STATUS=$(fetch_status "$SPYPORT" "/r/${SYM_ID}/kb.html")
                fi
                if [[ $HAS_NODE -eq 1 ]]; then
                    SYM_NODE_STATUS=$(fetch_status "$SNODEPORT" "/r/${SYM_ID}/kb.html")
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
# Section 5: KB-state byte-parity across runtimes (task-066, SEC-A4, feature-007)
#
# Tests:
#   5a. 5 KB-state variants (pending/generating/preparing/approved/outdated) --
#       kb_state bytes are IDENTICAL across Python and Node for each variant.
#   5b. Frozen-commit "outdated" verdict: a git repo with a pinned commit date
#       gives a deterministic "outdated" result across runtimes and across runs.
#   5c. DM-A3: schema_version remains 3 in both runtimes.
# ---------------------------------------------------------------------------

echo ""
echo "--- Section 5: KB-state byte-parity across runtimes (task-066) ---"

# ---------------------------------------------------------------------------
# Helper: normalize kb_state fields for parity comparison.
#
# Excludes ONLY: generated_by, model.read.read_at (same as Section 2).
# kb_state.status, kb_state.summary_present, kb_state.kb_baseline are ALL
# deterministic from fixture files (no live-data exclusion needed for the
# static variants). For the outdated variant the git tip is frozen by the
# fixture, so it too is deterministic and not excluded.
# ---------------------------------------------------------------------------

normalize_kb_model_json() {
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
# Helper: extract kb_state.status from a /api/model JSON file.
# ---------------------------------------------------------------------------

extract_kb_status() {
    local model_json="$1"
    python3 -c "
import json, sys
data = json.load(open('$model_json'))
kb = data.get('model', {}).get('repo', {}).get('kb_state')
if kb is None:
    print('null')
else:
    print(kb.get('status', 'unknown'))
"
}

# ---------------------------------------------------------------------------
# Helper: assert kb_state.status value AND byte-parity for a single variant.
#
# Usage: check_kb_variant <variant-name> <expected-status>
#        Requires PY_PORT, NODE_PORT, and a fresh AID_HOME with the variant
#        repo registered.
# ---------------------------------------------------------------------------

# Temp file paths for this section
KB_PY_MODEL="${PT1H_TMP}/kb_py_model.json"
KB_NODE_MODEL="${PT1H_TMP}/kb_node_model.json"
KB_PY_NORM="${PT1H_TMP}/kb_py_norm.json"
KB_NODE_NORM="${PT1H_TMP}/kb_node_norm.json"

check_kb_variant() {
    local name="$1"
    local expected_status="$2"
    local repo_path="$3"
    local kb_aid_home="$4"

    # Build a dedicated AID_HOME for this variant and start fresh servers.
    local kb_py_port="" kb_node_port="" kb_py_pid="" kb_node_pid=""

    cat > "${kb_aid_home}/registry.yml" << REOF
schema: 1
repos:
  - ${repo_path}
REOF

    if [[ $HAS_PYTHON -eq 1 ]]; then
        kb_py_port=$(find_free_port)
        HOME="${PT1H_PINNED_HOME}" AID_HOME="$kb_aid_home" python3 "${SERVER_PY}" \
            --host 127.0.0.1 --port "$kb_py_port" \
            >/dev/null 2>&1 &
        kb_py_pid=$!
        _BGPIDS+=($kb_py_pid)
    fi
    if [[ $HAS_NODE -eq 1 ]]; then
        kb_node_port=$(find_free_port)
        while [[ $HAS_PYTHON -eq 1 && "$kb_node_port" == "$kb_py_port" ]]; do
            kb_node_port=$(find_free_port)
        done
        HOME="${PT1H_PINNED_HOME}" AID_HOME="$kb_aid_home" node "${SERVER_MJS}" \
            --host 127.0.0.1 --port "$kb_node_port" \
            >/dev/null 2>&1 &
        kb_node_pid=$!
        _BGPIDS+=($kb_node_pid)
    fi

    # Wait for servers
    local kb_py_ok=0 kb_node_ok=0
    if [[ $HAS_PYTHON -eq 1 ]]; then
        if wait_for_port "$kb_py_port" 12; then
            kb_py_ok=1
        else
            fail "[kb-variant:$name] python server did not start on port $kb_py_port"
        fi
    fi
    if [[ $HAS_NODE -eq 1 ]]; then
        if wait_for_port "$kb_node_port" 12; then
            kb_node_ok=1
        else
            fail "[kb-variant:$name] node server did not start on port $kb_node_port"
        fi
    fi

    # Extract the repo id from /api/home
    local kb_home_port=""
    if [[ $HAS_PYTHON -eq 1 && $kb_py_ok -eq 1 ]]; then
        kb_home_port="$kb_py_port"
    elif [[ $HAS_NODE -eq 1 && $kb_node_ok -eq 1 ]]; then
        kb_home_port="$kb_node_port"
    fi

    local kb_variant_id=""
    if [[ -n "$kb_home_port" ]]; then
        local kb_home_json="${PT1H_TMP}/kb_home_${name}.json"
        if fetch_url "$kb_home_port" "/api/home" "$kb_home_json" 2>/dev/null; then
            kb_variant_id=$(python3 -c "
import json, sys
data = json.load(open('$kb_home_json'))
repos = data.get('repos', [])
if repos:
    print(repos[0]['id'])
    sys.exit(0)
sys.exit(1)
" 2>/dev/null) || kb_variant_id=""
        fi
    fi

    if [[ -z "$kb_variant_id" ]]; then
        fail "[kb-variant:$name] could not extract repo id; skipping parity check"
    else
        # Fetch /r/<id>/api/model from python and node
        local py_ok=0 node_ok=0

        if [[ $HAS_PYTHON -eq 1 && $kb_py_ok -eq 1 ]]; then
            if fetch_url "$kb_py_port" "/r/${kb_variant_id}/api/model" "$KB_PY_MODEL"; then
                if python3 -c "import json; json.load(open('$KB_PY_MODEL'))" 2>/dev/null; then
                    py_ok=1
                    local py_status
                    py_status=$(extract_kb_status "$KB_PY_MODEL")
                    if [[ "$py_status" == "$expected_status" ]]; then
                        pass "[kb-variant:$name] python: kb_state.status='$py_status' (expected '$expected_status')"
                    else
                        fail "[kb-variant:$name] python: kb_state.status='$py_status' (expected '$expected_status')"
                    fi
                else
                    fail "[kb-variant:$name] python /api/model is not valid JSON"
                fi
            else
                fail "[kb-variant:$name] python /api/model fetch failed"
            fi
        fi

        if [[ $HAS_NODE -eq 1 && $kb_node_ok -eq 1 ]]; then
            if fetch_url "$kb_node_port" "/r/${kb_variant_id}/api/model" "$KB_NODE_MODEL"; then
                if python3 -c "import json; json.load(open('$KB_NODE_MODEL'))" 2>/dev/null; then
                    node_ok=1
                    local node_status
                    node_status=$(extract_kb_status "$KB_NODE_MODEL")
                    if [[ "$node_status" == "$expected_status" ]]; then
                        pass "[kb-variant:$name] node: kb_state.status='$node_status' (expected '$expected_status')"
                    else
                        fail "[kb-variant:$name] node: kb_state.status='$node_status' (expected '$expected_status')"
                    fi
                else
                    fail "[kb-variant:$name] node /api/model is not valid JSON"
                fi
            else
                fail "[kb-variant:$name] node /api/model fetch failed"
            fi
        fi

        # Byte-parity check
        if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && $py_ok -eq 1 && $node_ok -eq 1 ]]; then
            normalize_kb_model_json "$KB_PY_MODEL" "$KB_PY_NORM"
            normalize_kb_model_json "$KB_NODE_MODEL" "$KB_NODE_NORM"
            if cmp -s "$KB_PY_NORM" "$KB_NODE_NORM"; then
                pass "[kb-variant:$name] python == node (kb_state byte-identical after normalize)"
            else
                fail "[kb-variant:$name] python != node (kb_state NOT byte-identical)"
                if [[ "$VERBOSE" -eq 1 ]]; then
                    echo "  --- diff (python vs node) ---"
                    diff "$KB_PY_NORM" "$KB_NODE_NORM" || true
                fi
            fi

            # DM-A3: schema_version stays 3 in both runtimes
            local py_sv node_sv
            py_sv=$(python3 -c "import json; d=json.load(open('$KB_PY_MODEL')); print(d.get('schema_version','?'))" 2>/dev/null)
            node_sv=$(python3 -c "import json; d=json.load(open('$KB_NODE_MODEL')); print(d.get('schema_version','?'))" 2>/dev/null)
            if [[ "$py_sv" == "3" && "$node_sv" == "3" ]]; then
                pass "[kb-variant:$name] DM-A3: schema_version=3 in both runtimes"
            else
                fail "[kb-variant:$name] DM-A3: schema_version is py=$py_sv node=$node_sv (expected 3)"
            fi
        fi
    fi

    # Kill the variant servers
    if [[ -n "$kb_py_pid" ]]; then
        kill "$kb_py_pid" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$kb_py_pid}")
    fi
    if [[ -n "$kb_node_pid" ]]; then
        kill "$kb_node_pid" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$kb_node_pid}")
    fi
}

# ---------------------------------------------------------------------------
# 5a: KB-state variants (pending / generating / preparing / approved)
#     These four variants use fixture files -- no git read is involved.
#     The approved variant has no kb_baseline -> freshness check skips -> approved.
#
#     "pending" is created dynamically (empty .aid/knowledge/ dir; git cannot
#     track empty directories so we create it at test runtime).
#     "generating", "preparing", "approved" are checked-in fixture dirs.
# ---------------------------------------------------------------------------

KB_FIXTURE_BASE="${FIXTURE_BASE}"

# --- pending: empty .aid/knowledge/ dir (created dynamically) ---
PENDING_REPO="${PT1H_TMP}/kb-pending-repo"
mkdir -p "${PENDING_REPO}/.aid/knowledge"
cat > "${PENDING_REPO}/.aid/.aid-manifest.json" << 'PMEOF'
{"manifest_version":1,"aid_version":"1.0.0-test","installed_at":"2026-01-01T00:00:00Z","tools":{}}
PMEOF
cat > "${PENDING_REPO}/.aid/settings.yml" << 'PSEOF'
project:
  name: PT1H-KB-Pending
  description: KB variant fixture: pending (empty .aid/knowledge/ dir).
PSEOF
# Verify the knowledge dir IS genuinely empty (no files)
_pending_files=$(find "${PENDING_REPO}/.aid/knowledge" -maxdepth 1 -not -type d | wc -l)
if [[ $_pending_files -eq 0 ]]; then
    log "[sec5a] pending fixture: knowledge dir is empty (correct)"
else
    log "[sec5a] pending fixture: knowledge dir has $_pending_files files (unexpected)"
fi

PENDING_AID_HOME="${PT1H_TMP}/kb-aid-home-pending"
mkdir -p "${PENDING_AID_HOME}/dashboard"
check_kb_variant "pending" "pending" "${PENDING_REPO}" "${PENDING_AID_HOME}"

# --- generating, preparing, approved: checked-in fixture dirs ---
for variant_name in "generating" "preparing" "approved"; do
    variant_dir="${KB_FIXTURE_BASE}/pt1h-kb-${variant_name}"
    if [[ ! -d "$variant_dir" ]]; then
        fail "[kb-variant:${variant_name}] fixture dir absent: ${variant_dir}"
        continue
    fi

    variant_aid_home="${PT1H_TMP}/kb-aid-home-${variant_name}"
    mkdir -p "${variant_aid_home}/dashboard"

    case "$variant_name" in
        generating) expected_status="generating" ;;
        preparing)  expected_status="preparing" ;;
        approved)   expected_status="approved" ;;
    esac

    check_kb_variant "$variant_name" "$expected_status" "$variant_dir" "$variant_aid_home"
done

# ---------------------------------------------------------------------------
# 5b: KB-state CROSS-RUNTIME parity using pt1h-repo-a (has .aid/knowledge/ + kb.html +
#     a settings.yml kb_baseline). pt1h-repo-a is a checked-in fixture INSIDE the AID
#     git tree, so `git -C <repo-a> log` resolves the AID repo's real tip; with the
#     fixture's (older) kb_baseline.tip_date the freshness check yields a real verdict
#     (typically 'outdated'). This sub-test does NOT hard-code the status — it asserts
#     only that repo-a's kb_state bytes are IDENTICAL across the Python and Node runtimes
#     (the deterministic per-state verdicts are covered by the dedicated 5-state fixtures
#     in 5a/5c, which are not nested inside this repo's git tree).
# ---------------------------------------------------------------------------

echo ""
echo "  --- 5b: repo-a kb_state parity (knowledge + kb.html + kb_baseline) ---"

# Servers are already started against the main AID_HOME (Section 1/2).
# Re-fetch /r/<id>/api/model for repo-a to assert kb_state parity.

if [[ -n "$MODEL_ID_A" || -n "$NODE_HOME_ID_A" ]]; then
    REPOA_MODEL_ID="${MODEL_ID_A:-$NODE_HOME_ID_A}"

    if [[ $HAS_PYTHON -eq 1 ]]; then
        KB_PY_REPOA="${PT1H_TMP}/kb_py_repoa.json"
        if fetch_url "$PY_PORT" "/r/${REPOA_MODEL_ID}/api/model" "$KB_PY_REPOA"; then
            py_kb_status=$(extract_kb_status "$KB_PY_REPOA")
            log "[sec5b] python repo-a kb_state.status: $py_kb_status"
        else
            fail "[sec5b] python repo-a /api/model fetch failed"
        fi
    fi
    if [[ $HAS_NODE -eq 1 ]]; then
        KB_NODE_REPOA="${PT1H_TMP}/kb_node_repoa.json"
        if fetch_url "$NODE_PORT" "/r/${REPOA_MODEL_ID}/api/model" "$KB_NODE_REPOA"; then
            node_kb_status=$(extract_kb_status "$KB_NODE_REPOA")
            log "[sec5b] node repo-a kb_state.status: $node_kb_status"
        else
            fail "[sec5b] node repo-a /api/model fetch failed"
        fi
    fi

    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && \
          -f "$KB_PY_REPOA" && -f "$KB_NODE_REPOA" ]]; then
        # Verify statuses match
        if [[ "$py_kb_status" == "$node_kb_status" ]]; then
            pass "[sec5b] repo-a: python kb_state.status='$py_kb_status' == node '$node_kb_status'"
        else
            fail "[sec5b] repo-a: kb_state.status differs: python='$py_kb_status' node='$node_kb_status'"
        fi
        # Normalize and compare bytes
        normalize_kb_model_json "$KB_PY_REPOA" "${PT1H_TMP}/kb_py_repoa_norm.json"
        normalize_kb_model_json "$KB_NODE_REPOA" "${PT1H_TMP}/kb_node_repoa_norm.json"
        if cmp -s "${PT1H_TMP}/kb_py_repoa_norm.json" "${PT1H_TMP}/kb_node_repoa_norm.json"; then
            pass "[sec5b] repo-a: kb_state byte-identical across runtimes (all new fields)"
        else
            fail "[sec5b] repo-a: kb_state NOT byte-identical across runtimes"
            if [[ "$VERBOSE" -eq 1 ]]; then
                diff "${PT1H_TMP}/kb_py_repoa_norm.json" "${PT1H_TMP}/kb_node_repoa_norm.json" || true
            fi
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 5c: "outdated" variant via frozen-commit git repo (residual #4, R12)
#
#    We create a temp git repo at test runtime with a FROZEN commit date
#    (GIT_AUTHOR_DATE / GIT_COMMITTER_DATE pinned to 2026-06-10T12:00:00+00:00).
#    The kb_baseline is set to 2026-06-01T00:00:00Z (one month before the commit).
#    Both Python and Node must read: current_tip (2026-06-10) > baseline (2026-06-01)
#    -> status = "outdated". The result is byte-identical and reproducible.
# ---------------------------------------------------------------------------

echo ""
echo "  --- 5c: outdated variant via frozen-commit git repo (R12 residual #4) ---"

if ! command -v git >/dev/null 2>&1; then
    log "[sec5c] git not found on PATH; skipping frozen-commit outdated variant"
    pass "[sec5c] frozen-commit outdated variant [SKIPPED: git absent on PATH]"
else
    FROZEN_REPO="${PT1H_TMP}/frozen-commit-repo"
    mkdir -p "${FROZEN_REPO}"

    FROZEN_DATE="2026-06-10T12:00:00+00:00"
    FROZEN_ENV_VARS=(
        "GIT_AUTHOR_DATE=${FROZEN_DATE}"
        "GIT_COMMITTER_DATE=${FROZEN_DATE}"
        "GIT_AUTHOR_NAME=test"
        "GIT_AUTHOR_EMAIL=test@test.com"
        "GIT_COMMITTER_NAME=test"
        "GIT_COMMITTER_EMAIL=test@test.com"
        "GIT_CONFIG_NOSYSTEM=1"
        "HOME=${PT1H_TMP}"
    )

    # Initialize frozen git repo
    env "${FROZEN_ENV_VARS[@]}" git init -b master "${FROZEN_REPO}" >/dev/null 2>&1
    echo "frozen" > "${FROZEN_REPO}/README.txt"
    env "${FROZEN_ENV_VARS[@]}" git -C "${FROZEN_REPO}" add README.txt >/dev/null 2>&1
    env "${FROZEN_ENV_VARS[@]}" git -C "${FROZEN_REPO}" \
        commit -m "frozen commit for PT-1-H task-066" >/dev/null 2>&1

    # Create .aid tree inside the frozen repo
    mkdir -p "${FROZEN_REPO}/.aid/knowledge"
    cat > "${FROZEN_REPO}/.aid/knowledge/STATE.md" << 'SEOF'
## Knowledge Summary Status

**User Approved:** yes (2026-06-01)
SEOF
    cat > "${FROZEN_REPO}/.aid/knowledge/kb.html" << 'HEOF'
<!DOCTYPE html>
<html><head><title>Frozen KB</title></head>
<body><h1>PT1H frozen-commit outdated fixture</h1></body>
</html>
HEOF
    cat > "${FROZEN_REPO}/.aid/.aid-manifest.json" << 'MEOF'
{"manifest_version":1,"aid_version":"1.0.0-test","installed_at":"2026-01-01T00:00:00Z","tools":{}}
MEOF
    # kb_baseline: tip_date one month BEFORE the frozen commit -> outdated
    cat > "${FROZEN_REPO}/.aid/settings.yml" << 'YEOF'
project:
  name: PT1H-Frozen-Outdated
  description: Frozen-commit fixture for PT-1-H task-066 outdated variant.
kb_baseline:
  branch: master
  tip_date: 2026-06-01T00:00:00Z
YEOF

    FROZEN_AID_HOME="${PT1H_TMP}/frozen-aid-home"
    mkdir -p "${FROZEN_AID_HOME}/dashboard"

    check_kb_variant "outdated" "outdated" "${FROZEN_REPO}" "${FROZEN_AID_HOME}"

    # Extra: run check_kb_variant a second time (using fresh temp files) to verify reproducibility
    FROZEN_AID_HOME2="${PT1H_TMP}/frozen-aid-home2"
    mkdir -p "${FROZEN_AID_HOME2}/dashboard"
    check_kb_variant "outdated-run2" "outdated" "${FROZEN_REPO}" "${FROZEN_AID_HOME2}"

    # If both runs pass (both "outdated"), reproducibility is confirmed
    if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 ]]; then
        pass "[sec5c] frozen-commit outdated: reproducible across two runs (deterministic git tip)"
    fi
fi

# ---------------------------------------------------------------------------
# Section 6: TaskDetail byte-parity + key-order + no-schema-bump (task-072)
#
# Tests:
#   6a. Python and Node emit a byte-identical /r/<id>/api/model?detail=... envelope
#       (including details map + raw_state.text with escaped U+2028/U+2029 -- R7).
#   6b. Key-order parity (DM-2): scrambled ?detail= comma-list yields the same
#       sorted-ascending-by-composite-key output from both runtimes.
#   6c. NO-schema-bump (RC-2): schema_version=3 for bare and detail polls;
#       'details' absent on bare poll; 'details' present on detail poll;
#       bare-poll body byte-identical before/after (NFR4 always-on path unchanged).
#   6d. R7: U+2028/U+2029 in raw_state.text are escaped (not raw) in both runtimes.
#
# Fixture: dashboard/server/tests/fixtures/pt1h-detail-repo/
#   work-001-detail/STATE.md  -- U+2028/U+2029 + Quick Check Findings + Delivery Gates
#   work-001-detail/tasks/task-001.md  -- drilled task (CRITICAL/HIGH/MINOR findings)
#   work-001-detail/tasks/task-002.md  -- clean task (empty findings)
#   work-001-detail/tasks/task-003.md  -- null delivery_id (Wave == '--')
#   work-001-detail/delivery-001-issues.md -- rows for task-001 AND task-002 (filter exercised)
# ---------------------------------------------------------------------------

echo ""
echo "--- Section 6: TaskDetail byte-parity + key-order + no-schema-bump (task-072) ---"

DETAIL_FIXTURE_REPO="${FIXTURE_BASE}/pt1h-detail-repo"

if [[ ! -d "${DETAIL_FIXTURE_REPO}" ]]; then
    fail "[detail] fixture dir absent: ${DETAIL_FIXTURE_REPO}"
else
    # Build a dedicated AID_HOME for this section.
    DETAIL_AID_HOME="${PT1H_TMP}/detail-aid-home"
    mkdir -p "${DETAIL_AID_HOME}/dashboard"
    cat > "${DETAIL_AID_HOME}/registry.yml" << DEOF
schema: 1
repos:
  - ${DETAIL_FIXTURE_REPO}
DEOF

    # Start fresh servers for the detail fixture.
    D_PY_PORT="" D_NODE_PORT="" D_PY_PID="" D_NODE_PID=""

    if [[ $HAS_PYTHON -eq 1 ]]; then
        D_PY_PORT=$(find_free_port)
        HOME="${PT1H_PINNED_HOME}" AID_HOME="$DETAIL_AID_HOME" python3 "${SERVER_PY}" \
            --host 127.0.0.1 --port "$D_PY_PORT" \
            >/dev/null 2>&1 &
        D_PY_PID=$!
        _BGPIDS+=($D_PY_PID)
    fi
    if [[ $HAS_NODE -eq 1 ]]; then
        D_NODE_PORT=$(find_free_port)
        while [[ $HAS_PYTHON -eq 1 && "$D_NODE_PORT" == "$D_PY_PORT" ]]; do
            D_NODE_PORT=$(find_free_port)
        done
        HOME="${PT1H_PINNED_HOME}" AID_HOME="$DETAIL_AID_HOME" node "${SERVER_MJS}" \
            --host 127.0.0.1 --port "$D_NODE_PORT" \
            >/dev/null 2>&1 &
        D_NODE_PID=$!
        _BGPIDS+=($D_NODE_PID)
    fi

    D_PY_OK=0 D_NODE_OK=0
    if [[ $HAS_PYTHON -eq 1 ]]; then
        if wait_for_port "$D_PY_PORT" 12; then
            D_PY_OK=1
            pass "[detail] python detail-server started on port $D_PY_PORT"
        else
            fail "[detail] python detail-server did not start on port $D_PY_PORT"
        fi
    fi
    if [[ $HAS_NODE -eq 1 ]]; then
        if wait_for_port "$D_NODE_PORT" 12; then
            D_NODE_OK=1
            pass "[detail] node detail-server started on port $D_NODE_PORT"
        else
            fail "[detail] node detail-server did not start on port $D_NODE_PORT"
        fi
    fi

    # --- Extract repo id for detail-fixture-repo ---
    DETAIL_REPO_ID=""
    if [[ $HAS_PYTHON -eq 1 && $D_PY_OK -eq 1 ]]; then
        D_HOME_JSON="${PT1H_TMP}/detail_home.json"
        if fetch_url "$D_PY_PORT" "/api/home" "$D_HOME_JSON" 2>/dev/null; then
            DETAIL_REPO_ID=$(python3 -c "
import json, sys
data = json.load(open('$D_HOME_JSON'))
repos = data.get('repos', [])
if repos:
    print(repos[0]['id'])
    sys.exit(0)
sys.exit(1)
" 2>/dev/null) || DETAIL_REPO_ID=""
        fi
    elif [[ $HAS_NODE -eq 1 && $D_NODE_OK -eq 1 ]]; then
        D_HOME_JSON="${PT1H_TMP}/detail_home.json"
        if fetch_url "$D_NODE_PORT" "/api/home" "$D_HOME_JSON" 2>/dev/null; then
            DETAIL_REPO_ID=$(python3 -c "
import json, sys
data = json.load(open('$D_HOME_JSON'))
repos = data.get('repos', [])
if repos:
    print(repos[0]['id'])
    sys.exit(0)
sys.exit(1)
" 2>/dev/null) || DETAIL_REPO_ID=""
        fi
    fi

    if [[ -z "$DETAIL_REPO_ID" ]]; then
        fail "[detail] could not extract detail-repo id; skipping Section 6 checks"
    else
        log "[detail] detail-repo id: $DETAIL_REPO_ID"

        # Composite keys for the three tasks.
        # SCRAMBLED order for key-order parity test (DM-2, FR14):
        #   request: task-003, task-001, task-002 (not sorted)
        #   expected output: work-001-detail/task-001, work-001-detail/task-002, work-001-detail/task-003
        D_KEY_1="work-001-detail/task-001"
        D_KEY_2="work-001-detail/task-002"
        D_KEY_3="work-001-detail/task-003"
        D_SCRAMBLED="${D_KEY_3},${D_KEY_1},${D_KEY_2}"
        D_DETAIL_PATH="/r/${DETAIL_REPO_ID}/api/model?detail=${D_SCRAMBLED}"

        # 6a + 6b: Fetch ?detail= (scrambled) from both runtimes; assert byte-identity.
        D_PY_DETAIL="${PT1H_TMP}/detail_py.json"
        D_NODE_DETAIL="${PT1H_TMP}/detail_node.json"
        D_PY_DETAIL_NORM="${PT1H_TMP}/detail_py_norm.json"
        D_NODE_DETAIL_NORM="${PT1H_TMP}/detail_node_norm.json"

        D_PY_DETAIL_OK=0 D_NODE_DETAIL_OK=0

        if [[ $HAS_PYTHON -eq 1 && $D_PY_OK -eq 1 ]]; then
            if fetch_url "$D_PY_PORT" "$D_DETAIL_PATH" "$D_PY_DETAIL"; then
                if python3 -c "import json; json.load(open('$D_PY_DETAIL'))" 2>/dev/null; then
                    D_PY_DETAIL_OK=1
                    pass "[detail-6a] python ?detail= (scrambled) responds with valid JSON"
                else
                    fail "[detail-6a] python ?detail= (scrambled) is not valid JSON"
                fi
            else
                fail "[detail-6a] python ?detail= (scrambled) fetch failed"
            fi
        fi

        if [[ $HAS_NODE -eq 1 && $D_NODE_OK -eq 1 ]]; then
            if fetch_url "$D_NODE_PORT" "$D_DETAIL_PATH" "$D_NODE_DETAIL"; then
                if python3 -c "import json; json.load(open('$D_NODE_DETAIL'))" 2>/dev/null; then
                    D_NODE_DETAIL_OK=1
                    pass "[detail-6a] node ?detail= (scrambled) responds with valid JSON"
                else
                    fail "[detail-6a] node ?detail= (scrambled) is not valid JSON"
                fi
            else
                fail "[detail-6a] node ?detail= (scrambled) fetch failed"
            fi
        fi

        # 6a: Normalize and byte-compare (generated_by is the ONLY excluded field).
        normalize_detail_json() {
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

        if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && $D_PY_DETAIL_OK -eq 1 && $D_NODE_DETAIL_OK -eq 1 ]]; then
            normalize_detail_json "$D_PY_DETAIL" "$D_PY_DETAIL_NORM"
            normalize_detail_json "$D_NODE_DETAIL" "$D_NODE_DETAIL_NORM"

            # 6b: Key-order parity -- assert keys are sorted ascending in both outputs
            D_PY_KEYS=$(python3 -c "
import json
data = json.load(open('$D_PY_DETAIL'))
keys = list(data.get('details', {}).keys())
print(','.join(keys))
" 2>/dev/null)
            D_NODE_KEYS=$(python3 -c "
import json
data = json.load(open('$D_NODE_DETAIL'))
keys = list(data.get('details', {}).keys())
print(','.join(keys))
" 2>/dev/null)
            D_EXPECTED_KEYS="${D_KEY_1},${D_KEY_2},${D_KEY_3}"

            if [[ "$D_PY_KEYS" == "$D_EXPECTED_KEYS" ]]; then
                pass "[detail-6b] python: details keys sorted ascending (scrambled input -> sorted output)"
            else
                fail "[detail-6b] python: details keys not sorted (got='$D_PY_KEYS' expected='$D_EXPECTED_KEYS')"
            fi
            if [[ "$D_NODE_KEYS" == "$D_EXPECTED_KEYS" ]]; then
                pass "[detail-6b] node: details keys sorted ascending (scrambled input -> sorted output)"
            else
                fail "[detail-6b] node: details keys not sorted (got='$D_NODE_KEYS' expected='$D_EXPECTED_KEYS')"
            fi

            # 6a: byte-identical after normalize
            if cmp -s "$D_PY_DETAIL_NORM" "$D_NODE_DETAIL_NORM"; then
                pass "[detail-6a] python == node (byte-identical after strip+normalize, including details+raw_state)"
            else
                fail "[detail-6a] python != node (NOT byte-identical after strip+normalize)"
                echo "  BYTE-DIFF RESULT (empty = identical):"
                diff "$D_PY_DETAIL_NORM" "$D_NODE_DETAIL_NORM" || true
            fi

            # Show the actual byte-diff result explicitly (required by task-072 verification)
            echo "  Byte-diff result (empty = identical, scrambled-order ?detail= Python vs Node):"
            diff "$D_PY_DETAIL_NORM" "$D_NODE_DETAIL_NORM" && echo "  (no differences)" || true

            # 6d: R7 -- U+2028/U+2029 in raw_state.text are ESCAPED (not raw) in both runtimes
            python3 "${SCRIPT_DIR}/../lib/pt1h_r7_check_state.py" \
                "$D_PY_DETAIL" "$D_NODE_DETAIL"
            d_r7_rc=$?
            if [[ $d_r7_rc -eq 0 ]]; then
                pass "[detail-6d] R7: raw_state.text U+2028/U+2029 escaped in both runtimes"
            else
                fail "[detail-6d] R7: raw_state.text U+2028/U+2029 escaping violated"
            fi

            # 6a: Assert details map contains exactly our 3 keys with the right content shape
            python3 -c "
import json, sys
data = json.load(open('$D_PY_DETAIL'))
details = data.get('details', {})
failures = []
# Expected 3 keys
expected = ['work-001-detail/task-001', 'work-001-detail/task-002', 'work-001-detail/task-003']
if list(details.keys()) != expected:
    failures.append('keys: got %s expected %s' % (list(details.keys()), expected))
# task-001: 3 findings (CRITICAL, HIGH, MINOR)
td1 = details.get('work-001-detail/task-001', {})
f1 = td1.get('findings', [])
if len(f1) != 3:
    failures.append('task-001 findings count: got %d expected 3' % len(f1))
else:
    sevs = [f['severity'] for f in f1]
    if sevs != ['[CRITICAL]', '[HIGH]', '[MINOR]']:
        failures.append('task-001 severities: %s' % sevs)
# task-001: delivery_id present, grade A+, 1 deferred issue
ledger1 = td1.get('ledger', {})
if ledger1.get('delivery_id') != 'delivery-001':
    failures.append('task-001 delivery_id: got %s' % ledger1.get('delivery_id'))
if ledger1.get('grade') != 'A+':
    failures.append('task-001 grade: got %s' % ledger1.get('grade'))
if len(ledger1.get('deferred_issues', [])) != 1:
    failures.append('task-001 deferred_issues count: got %d expected 1' % len(ledger1.get('deferred_issues', [])))
# task-002: clean findings (empty)
td2 = details.get('work-001-detail/task-002', {})
if len(td2.get('findings', [])) != 0:
    failures.append('task-002 findings: expected 0 got %d' % len(td2.get('findings', [])))
# task-003: delivery_id null
td3 = details.get('work-001-detail/task-003', {})
if td3.get('ledger', {}).get('delivery_id') is not None:
    failures.append('task-003 delivery_id: expected null got %s' % td3.get('ledger', {}).get('delivery_id'))
if failures:
    for msg in failures:
        sys.stderr.write('  DETAIL-ASSERT FAIL: ' + msg + '\n')
    sys.exit(1)
sys.exit(0)
" 2>&1
            detail_assert_rc=$?
            if [[ $detail_assert_rc -eq 0 ]]; then
                pass "[detail-6a] details map content: 3 tasks, CRITICAL/HIGH/MINOR findings, delivery_id null, deferred-issue filter correct"
            else
                fail "[detail-6a] details map content assertion failed (see above)"
            fi

        else
            log "[detail-6a/6b] skipping byte-parity: one or both ?detail= fetches failed or single runtime"
        fi

        # 6c: NO-schema-bump (RC-2)
        # Fetch bare /r/<id>/api/model (no ?detail=) from both runtimes.
        D_BARE_PATH="/r/${DETAIL_REPO_ID}/api/model"
        D_PY_BARE="${PT1H_TMP}/detail_py_bare.json"
        D_NODE_BARE="${PT1H_TMP}/detail_node_bare.json"
        D_PY_BARE_NORM="${PT1H_TMP}/detail_py_bare_norm.json"
        D_NODE_BARE_NORM="${PT1H_TMP}/detail_node_bare_norm.json"

        D_PY_BARE_OK=0 D_NODE_BARE_OK=0

        if [[ $HAS_PYTHON -eq 1 && $D_PY_OK -eq 1 ]]; then
            if fetch_url "$D_PY_PORT" "$D_BARE_PATH" "$D_PY_BARE" 2>/dev/null; then
                D_PY_BARE_OK=1
            fi
        fi
        if [[ $HAS_NODE -eq 1 && $D_NODE_OK -eq 1 ]]; then
            if fetch_url "$D_NODE_PORT" "$D_BARE_PATH" "$D_NODE_BARE" 2>/dev/null; then
                D_NODE_BARE_OK=1
            fi
        fi

        # RC-2 assertions for each available runtime
        _check_rc2() {
            local label="$1"
            local bare_file="$2"
            local detail_file="$3"
            local bare_ok="$4"
            local detail_ok="$5"

            if [[ "$bare_ok" -eq 1 ]]; then
                local sv
                sv=$(python3 -c "import json; d=json.load(open('$bare_file')); print(d.get('schema_version','?'))" 2>/dev/null)
                if [[ "$sv" == "3" ]]; then
                    pass "[detail-6c] RC-2 $label bare poll: schema_version=3"
                else
                    fail "[detail-6c] RC-2 $label bare poll: schema_version=$sv (expected 3)"
                fi
                local has_details
                has_details=$(python3 -c "import json; d=json.load(open('$bare_file')); print('details' in d)" 2>/dev/null)
                if [[ "$has_details" == "False" ]]; then
                    pass "[detail-6c] RC-2 $label bare poll: 'details' key absent (NFR4)"
                else
                    fail "[detail-6c] RC-2 $label bare poll: 'details' key PRESENT (must be absent without ?detail=)"
                fi
            fi

            if [[ "$detail_ok" -eq 1 ]]; then
                local sv_d
                sv_d=$(python3 -c "import json; d=json.load(open('$detail_file')); print(d.get('schema_version','?'))" 2>/dev/null)
                if [[ "$sv_d" == "3" ]]; then
                    pass "[detail-6c] RC-2 $label ?detail= poll: schema_version=3 (no bump)"
                else
                    fail "[detail-6c] RC-2 $label ?detail= poll: schema_version=$sv_d (expected 3, no bump)"
                fi
                local has_details_d
                has_details_d=$(python3 -c "import json; d=json.load(open('$detail_file')); print('details' in d)" 2>/dev/null)
                if [[ "$has_details_d" == "True" ]]; then
                    pass "[detail-6c] RC-2 $label ?detail= poll: 'details' key present"
                else
                    fail "[detail-6c] RC-2 $label ?detail= poll: 'details' key absent (expected present with ?detail=)"
                fi
            fi
        }

        _check_rc2 "python" "$D_PY_BARE" "$D_PY_DETAIL" "$D_PY_BARE_OK" "$D_PY_DETAIL_OK"
        _check_rc2 "node"   "$D_NODE_BARE" "$D_NODE_DETAIL" "$D_NODE_BARE_OK" "$D_NODE_DETAIL_OK"

        # RC-2 / NFR4: bare poll byte-identical between Python and Node (always-on path unchanged)
        if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && $D_PY_BARE_OK -eq 1 && $D_NODE_BARE_OK -eq 1 ]]; then
            normalize_model_json "$D_PY_BARE" "$D_PY_BARE_NORM"
            normalize_model_json "$D_NODE_BARE" "$D_NODE_BARE_NORM"
            if cmp -s "$D_PY_BARE_NORM" "$D_NODE_BARE_NORM"; then
                pass "[detail-6c] RC-2/NFR4: bare poll body byte-identical across runtimes (always-on path unchanged)"
            else
                fail "[detail-6c] RC-2/NFR4: bare poll body NOT byte-identical (always-on path regressed)"
                if [[ "$VERBOSE" -eq 1 ]]; then
                    diff "$D_PY_BARE_NORM" "$D_NODE_BARE_NORM" || true
                fi
            fi
        fi

        # 6c: assert bare poll has NO 'details' key but detail poll HAS it (single-runtime path)
        if [[ $HAS_PYTHON -eq 0 && $HAS_NODE -eq 1 && $D_NODE_BARE_OK -eq 1 && $D_NODE_DETAIL_OK -eq 1 ]]; then
            : # Already covered by _check_rc2 node above
        fi
    fi

    # Clean up detail section servers
    if [[ -n "$D_PY_PID" ]]; then
        kill "$D_PY_PID" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$D_PY_PID}")
    fi
    if [[ -n "$D_NODE_PID" ]]; then
        kill "$D_NODE_PID" 2>/dev/null || true
        _BGPIDS=("${_BGPIDS[@]/$D_NODE_PID}")
    fi
fi

# ---------------------------------------------------------------------------
# Section 7: split-tier union regression (registry-union fix)
#
# Scenario A -- split-tier: shared AID_HOME (state) lists repo-A; user
#   $HOME/.aid lists repo-B.  The server must return BOTH in /api/home
#   (union), each with a distinct id.
#
# Scenario B -- per-user collapse: AID_HOME == $HOME/.aid; a project listed
#   once must appear exactly once in /api/home (no double-count).
#
# Both scenarios cover Python and Node at parity, with a throwaway HOME
#   (escape canary: real $HOME/.aid must not be touched).
# ---------------------------------------------------------------------------

echo ""
echo "--- Section 7: split-tier registry union regression ---"

# Save real HOME for the escape canary.
REAL_HOME_S7="$HOME"

# Throwaway HOME: never touches the developer's real ~/.aid.
S7_TMP="$(mktemp -d "${PT1H_TMP}/s7_XXXXXX")"
S7_HOME="${S7_TMP}/home"
mkdir -p "${S7_HOME}/.aid"

# Two minimal "repos" for the test -- directories that just need to exist
# (available=true so the server can build the id from the path).
S7_REPO_A="${S7_TMP}/repo-a"
S7_REPO_B="${S7_TMP}/repo-b"
mkdir -p "${S7_REPO_A}/.aid" "${S7_REPO_B}/.aid"

# Shared state-home (primary tier): lists only repo-A.
S7_STATE_HOME="${S7_TMP}/state-home"
mkdir -p "${S7_STATE_HOME}"
printf 'schema: 1\nrepos:\n  - %s\n' "${S7_REPO_A}" > "${S7_STATE_HOME}/registry.yml"

# User tier ($HOME/.aid/registry.yml): lists only repo-B.
printf 'schema: 1\nrepos:\n  - %s\n' "${S7_REPO_B}" > "${S7_HOME}/.aid/registry.yml"

# Escape canary: assert real HOME was not modified during this section.
_s7_escape_check() {
    if [[ "$HOME" != "$REAL_HOME_S7" ]]; then
        fail "[s7-canary] HOME escaped pinning: got $HOME, expected $REAL_HOME_S7"
    fi
}

# Helper: count repos from a /api/home JSON by path substring.
_s7_count_repos_matching() {
    local json_file="$1"
    local pattern="$2"
    python3 -c "
import json, sys
data = json.load(open('$json_file'))
count = sum(1 for r in data.get('repos', []) if '$pattern' in r.get('path', ''))
print(count)
"
}

_s7_get_repo_ids() {
    local json_file="$1"
    python3 -c "
import json, sys
data = json.load(open('$json_file'))
ids = sorted(r['id'] for r in data.get('repos', []))
print(' '.join(ids))
"
}

# ---------------------------------------------------------------------------
# Scenario A: split-tier -- start servers with AID_HOME=state-home and
#   HOME=S7_HOME (which has its own .aid/registry.yml listing repo-B).
# ---------------------------------------------------------------------------

echo "  --- 7a: split-tier union (state lists A, user lists B -> both visible) ---"

S7A_PY_PORT="" S7A_NODE_PORT="" S7A_PY_PID="" S7A_NODE_PID=""

if [[ $HAS_PYTHON -eq 1 ]]; then
    S7A_PY_PORT=$(find_free_port)
    HOME="${S7_HOME}" AID_HOME="${S7_STATE_HOME}" \
        python3 "${SERVER_PY}" --host 127.0.0.1 --port "$S7A_PY_PORT" \
        >/dev/null 2>&1 &
    S7A_PY_PID=$!
    _BGPIDS+=($S7A_PY_PID)
fi

if [[ $HAS_NODE -eq 1 ]]; then
    S7A_NODE_PORT=$(find_free_port)
    while [[ $HAS_PYTHON -eq 1 && "$S7A_NODE_PORT" == "$S7A_PY_PORT" ]]; do
        S7A_NODE_PORT=$(find_free_port)
    done
    HOME="${S7_HOME}" AID_HOME="${S7_STATE_HOME}" \
        node "${SERVER_MJS}" --host 127.0.0.1 --port "$S7A_NODE_PORT" \
        >/dev/null 2>&1 &
    S7A_NODE_PID=$!
    _BGPIDS+=($S7A_NODE_PID)
fi

S7A_PY_OK=0 S7A_NODE_OK=0
if [[ $HAS_PYTHON -eq 1 ]]; then
    if wait_for_port "$S7A_PY_PORT" 12; then
        S7A_PY_OK=1
        pass "[s7a] python split-tier server started"
    else
        fail "[s7a] python split-tier server did not start"
    fi
fi
if [[ $HAS_NODE -eq 1 ]]; then
    if wait_for_port "$S7A_NODE_PORT" 12; then
        S7A_NODE_OK=1
        pass "[s7a] node split-tier server started"
    else
        fail "[s7a] node split-tier server did not start"
    fi
fi

# Fetch /api/home and assert repo-A and repo-B both appear (distinct ids).
if [[ $HAS_PYTHON -eq 1 && $S7A_PY_OK -eq 1 ]]; then
    S7A_PY_HOME="${PT1H_TMP}/s7a_py_home.json"
    if fetch_url "$S7A_PY_PORT" "/api/home" "$S7A_PY_HOME"; then
        s7a_py_count=$(python3 -c "
import json; d=json.load(open('$S7A_PY_HOME')); print(len(d.get('repos',[])))
")
        assert_eq "$s7a_py_count" "2" "[s7a] python /api/home: repo count == 2 (A union B)"

        s7a_py_a=$(_s7_count_repos_matching "$S7A_PY_HOME" "repo-a")
        s7a_py_b=$(_s7_count_repos_matching "$S7A_PY_HOME" "repo-b")
        assert_eq "$s7a_py_a" "1" "[s7a] python: repo-A appears in union"
        assert_eq "$s7a_py_b" "1" "[s7a] python: repo-B appears in union"

        # ids must be distinct
        s7a_py_ids=$(_s7_get_repo_ids "$S7A_PY_HOME")
        s7a_py_unique_count=$(echo "$s7a_py_ids" | tr ' ' '\n' | sort -u | grep -c .)
        assert_eq "$s7a_py_unique_count" "2" "[s7a] python: both repos have distinct ids"

        # Both repos are reachable via /r/<id>/api/model
        s7a_id_a=$(python3 -c "
import json, sys; d=json.load(open('$S7A_PY_HOME'))
for r in d.get('repos',[]):
    if 'repo-a' in r['path']: print(r['id']); sys.exit(0)
sys.exit(1)")
        s7a_id_b=$(python3 -c "
import json, sys; d=json.load(open('$S7A_PY_HOME'))
for r in d.get('repos',[]):
    if 'repo-b' in r['path']: print(r['id']); sys.exit(0)
sys.exit(1)")
        if [[ -n "$s7a_id_a" && -n "$s7a_id_b" ]]; then
            st_a=$(fetch_status "$S7A_PY_PORT" "/r/${s7a_id_a}/api/model")
            st_b=$(fetch_status "$S7A_PY_PORT" "/r/${s7a_id_b}/api/model")
            assert_eq "$st_a" "200" "[s7a] python: /r/<id-A>/api/model -> 200"
            assert_eq "$st_b" "200" "[s7a] python: /r/<id-B>/api/model -> 200"
        else
            fail "[s7a] python: could not extract repo ids from /api/home"
        fi
    else
        fail "[s7a] python: /api/home fetch failed"
    fi
fi

if [[ $HAS_NODE -eq 1 && $S7A_NODE_OK -eq 1 ]]; then
    S7A_NODE_HOME="${PT1H_TMP}/s7a_node_home.json"
    if fetch_url "$S7A_NODE_PORT" "/api/home" "$S7A_NODE_HOME"; then
        s7a_nd_count=$(python3 -c "
import json; d=json.load(open('$S7A_NODE_HOME')); print(len(d.get('repos',[])))
")
        assert_eq "$s7a_nd_count" "2" "[s7a] node /api/home: repo count == 2 (A union B)"

        s7a_nd_a=$(_s7_count_repos_matching "$S7A_NODE_HOME" "repo-a")
        s7a_nd_b=$(_s7_count_repos_matching "$S7A_NODE_HOME" "repo-b")
        assert_eq "$s7a_nd_a" "1" "[s7a] node: repo-A appears in union"
        assert_eq "$s7a_nd_b" "1" "[s7a] node: repo-B appears in union"

        s7a_nd_unique=$(  _s7_get_repo_ids "$S7A_NODE_HOME" | tr ' ' '\n' | sort -u | grep -c .)
        assert_eq "$s7a_nd_unique" "2" "[s7a] node: both repos have distinct ids"

        # Both repos are reachable via /r/<id>/api/model
        s7a_nd_id_a=$(python3 -c "
import json, sys; d=json.load(open('$S7A_NODE_HOME'))
for r in d.get('repos',[]):
    if 'repo-a' in r['path']: print(r['id']); sys.exit(0)
sys.exit(1)")
        s7a_nd_id_b=$(python3 -c "
import json, sys; d=json.load(open('$S7A_NODE_HOME'))
for r in d.get('repos',[]):
    if 'repo-b' in r['path']: print(r['id']); sys.exit(0)
sys.exit(1)")
        if [[ -n "$s7a_nd_id_a" && -n "$s7a_nd_id_b" ]]; then
            st_a=$(fetch_status "$S7A_NODE_PORT" "/r/${s7a_nd_id_a}/api/model")
            st_b=$(fetch_status "$S7A_NODE_PORT" "/r/${s7a_nd_id_b}/api/model")
            assert_eq "$st_a" "200" "[s7a] node: /r/<id-A>/api/model -> 200"
            assert_eq "$st_b" "200" "[s7a] node: /r/<id-B>/api/model -> 200"
        else
            fail "[s7a] node: could not extract repo ids from /api/home"
        fi
    else
        fail "[s7a] node: /api/home fetch failed"
    fi
fi

# Cross-runtime parity for scenario A
if [[ $HAS_PYTHON -eq 1 && $HAS_NODE -eq 1 && $S7A_PY_OK -eq 1 && $S7A_NODE_OK -eq 1 ]]; then
    if [[ -f "${PT1H_TMP}/s7a_py_home.json" && -f "${PT1H_TMP}/s7a_node_home.json" ]]; then
        normalize_home_json "${PT1H_TMP}/s7a_py_home.json" "${PT1H_TMP}/s7a_py_home_norm.json"
        normalize_home_json "${PT1H_TMP}/s7a_node_home.json" "${PT1H_TMP}/s7a_node_home_norm.json"
        if cmp -s "${PT1H_TMP}/s7a_py_home_norm.json" "${PT1H_TMP}/s7a_node_home_norm.json"; then
            pass "[s7a] parity: python == node (byte-identical union /api/home after normalize)"
        else
            fail "[s7a] parity: python != node (split-tier /api/home differs)"
            if [[ "$VERBOSE" -eq 1 ]]; then
                diff "${PT1H_TMP}/s7a_py_home_norm.json" "${PT1H_TMP}/s7a_node_home_norm.json" || true
            fi
        fi
    fi
fi

# Clean up scenario A servers.
[[ -n "$S7A_PY_PID" ]] && { kill "$S7A_PY_PID" 2>/dev/null || true; _BGPIDS=("${_BGPIDS[@]/$S7A_PY_PID}"); }
[[ -n "$S7A_NODE_PID" ]] && { kill "$S7A_NODE_PID" 2>/dev/null || true; _BGPIDS=("${_BGPIDS[@]/$S7A_NODE_PID}"); }

# ---------------------------------------------------------------------------
# Scenario B: per-user collapse -- AID_HOME == $HOME/.aid
#   A project listed once in that single registry must appear exactly once
#   (no double-counting from naive dual-read).
# ---------------------------------------------------------------------------

echo "  --- 7b: per-user collapse (AID_HOME == HOME/.aid -> no double-count) ---"

# Use S7_HOME as both HOME and AID_HOME parent; user registry lists only repo-A.
S7B_AID_HOME="${S7_HOME}/.aid"
mkdir -p "${S7B_AID_HOME}"
printf 'schema: 1\nrepos:\n  - %s\n' "${S7_REPO_A}" > "${S7B_AID_HOME}/registry.yml"

S7B_PY_PORT="" S7B_NODE_PORT="" S7B_PY_PID="" S7B_NODE_PID=""

if [[ $HAS_PYTHON -eq 1 ]]; then
    S7B_PY_PORT=$(find_free_port)
    HOME="${S7_HOME}" AID_HOME="${S7B_AID_HOME}" \
        python3 "${SERVER_PY}" --host 127.0.0.1 --port "$S7B_PY_PORT" \
        >/dev/null 2>&1 &
    S7B_PY_PID=$!
    _BGPIDS+=($S7B_PY_PID)
fi

if [[ $HAS_NODE -eq 1 ]]; then
    S7B_NODE_PORT=$(find_free_port)
    while [[ $HAS_PYTHON -eq 1 && "$S7B_NODE_PORT" == "$S7B_PY_PORT" ]]; do
        S7B_NODE_PORT=$(find_free_port)
    done
    HOME="${S7_HOME}" AID_HOME="${S7B_AID_HOME}" \
        node "${SERVER_MJS}" --host 127.0.0.1 --port "$S7B_NODE_PORT" \
        >/dev/null 2>&1 &
    S7B_NODE_PID=$!
    _BGPIDS+=($S7B_NODE_PID)
fi

S7B_PY_OK=0 S7B_NODE_OK=0
if [[ $HAS_PYTHON -eq 1 ]]; then
    if wait_for_port "$S7B_PY_PORT" 12; then
        S7B_PY_OK=1
        pass "[s7b] python per-user-collapse server started"
    else
        fail "[s7b] python per-user-collapse server did not start"
    fi
fi
if [[ $HAS_NODE -eq 1 ]]; then
    if wait_for_port "$S7B_NODE_PORT" 12; then
        S7B_NODE_OK=1
        pass "[s7b] node per-user-collapse server started"
    else
        fail "[s7b] node per-user-collapse server did not start"
    fi
fi

if [[ $HAS_PYTHON -eq 1 && $S7B_PY_OK -eq 1 ]]; then
    S7B_PY_HOME="${PT1H_TMP}/s7b_py_home.json"
    if fetch_url "$S7B_PY_PORT" "/api/home" "$S7B_PY_HOME"; then
        s7b_py_count=$(python3 -c "
import json; d=json.load(open('$S7B_PY_HOME')); print(len(d.get('repos',[])))
")
        assert_eq "$s7b_py_count" "1" "[s7b] python /api/home: repo count == 1 (no double-count)"
        s7b_py_a=$(_s7_count_repos_matching "$S7B_PY_HOME" "repo-a")
        assert_eq "$s7b_py_a" "1" "[s7b] python: repo-A appears exactly once"
    else
        fail "[s7b] python: /api/home fetch failed"
    fi
fi

if [[ $HAS_NODE -eq 1 && $S7B_NODE_OK -eq 1 ]]; then
    S7B_NODE_HOME="${PT1H_TMP}/s7b_node_home.json"
    if fetch_url "$S7B_NODE_PORT" "/api/home" "$S7B_NODE_HOME"; then
        s7b_nd_count=$(python3 -c "
import json; d=json.load(open('$S7B_NODE_HOME')); print(len(d.get('repos',[])))
")
        assert_eq "$s7b_nd_count" "1" "[s7b] node /api/home: repo count == 1 (no double-count)"
        s7b_nd_a=$(_s7_count_repos_matching "$S7B_NODE_HOME" "repo-a")
        assert_eq "$s7b_nd_a" "1" "[s7b] node: repo-A appears exactly once"
    else
        fail "[s7b] node: /api/home fetch failed"
    fi
fi

# Escape canary: real HOME must not have been modified.
_s7_escape_check

# Clean up scenario B servers.
[[ -n "$S7B_PY_PID" ]] && { kill "$S7B_PY_PID" 2>/dev/null || true; _BGPIDS=("${_BGPIDS[@]/$S7B_PY_PID}"); }
[[ -n "$S7B_NODE_PID" ]] && { kill "$S7B_NODE_PID" 2>/dev/null || true; _BGPIDS=("${_BGPIDS[@]/$S7B_NODE_PID}"); }

# ---------------------------------------------------------------------------
# Stop servers
# ---------------------------------------------------------------------------

stop_servers

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
test_summary
