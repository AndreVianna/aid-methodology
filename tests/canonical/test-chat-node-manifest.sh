#!/usr/bin/env bash
# test-chat-node-manifest.sh — guards the single-source chat-node file manifest.
#
# chat-node/MANIFEST is the ONE list of the agent chat node's curated file set. Five
# channels vendor/provision that component (install.sh, install.ps1,
# packages/npm/scripts/vendor.js, packages/pypi/scripts/vendor.py, release.sh), and the
# node ships inside the aid payload precisely so there is nothing to fetch at chat time
# (FR-7.6). A source file present in the repository but absent from one channel's copy is
# therefore an install that looks healthy and cannot start its own node.
#
# This suite is a deliberate mirror of test-dashboard-manifest.sh. The dashboard learned
# this lesson the expensive way — home.html and io_bounds.py each shipped imported at
# runtime and absent from every manifest (tech-debt H1) — and one component having learned
# it does not protect the next one. Same shape, same checks, one component over.
#
#   CN01  chat-node/MANIFEST exists and is non-empty
#   CN02  every path in MANIFEST resolves to a real file under chat-node/
#   CN03  MANIFEST == the curated chat-node/ tree (no missing, no extra)
#         curated = all files under chat-node/ MINUS tests/, __pycache__, *.pyc,
#         README.md, and MANIFEST itself
#   CN04  the entry point server/node.mjs is listed (without it the component provisions
#         as an empty directory and the failure surfaces only at first start)
#   CN05  each of the five consumers references chat-node/MANIFEST (i.e. derives its file
#         set from the manifest rather than re-inlining a hand-maintained list)
#   CN06  no third-party dependency is introduced by the node: every publication manifest
#         that declares dependencies still declares none
#   CN07  each channel actually DELIVERS the component, not merely reads its manifest.
#         CN05 alone is not enough and that is not hypothetical: the first version of this
#         wiring staged the node in install.sh without installing it, and listed its
#         manifest in release.sh without adding its files to the tar list -- and CN05
#         passed both, because the string it greps for was present in the reading half.
#         A guard that certifies a channel which demonstrably omits the component is worse
#         than no guard, so each consumer gets a destination-side assertion of its own.
#   CN08  packages/npm/package.json's `files` array ships chat-node/ (npm publishes only
#         what `files` names, so vendoring it and not listing it ships nothing)
#
# Fast + hermetic: reads files only, binds no port, mutates nothing, git-independent.
#
# Usage: bash test-chat-node-manifest.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NODE_DIR="${REPO_ROOT}/chat-node"
MANIFEST="${NODE_DIR}/MANIFEST"

# CN01 — manifest present.
assert_file_exists "$MANIFEST" "CN01 chat-node/MANIFEST exists"
if [[ ! -f "$MANIFEST" ]]; then
    test_summary; exit 1
fi

# Parse MANIFEST -> declared set. Strip #-comments and trim leading/trailing whitespace
# ONLY, matching what the actual consumers do — so an accidental internal space in a path
# stays malformed and CN02/CN03 fail loudly rather than being normalised away here.
declared=$(sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$MANIFEST" | grep -v '^$' | sort -u)
if [[ -n "$declared" ]]; then
    pass "CN01b MANIFEST is non-empty after stripping comments"
else
    fail "CN01b MANIFEST is empty after stripping comments"
    test_summary; exit 1
fi

# CN02 — every declared path is a real chat-node file.
_missing=""
while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    [[ -f "${NODE_DIR}/${rel}" ]] || _missing+="${rel} "
done <<< "$declared"
if [[ -z "$_missing" ]]; then
    pass "CN02 every MANIFEST path resolves to a real chat-node file"
else
    fail "CN02 MANIFEST lists non-existent files: ${_missing}"
fi

# Curated tree from the filesystem (chat-node-relative), git-independent.
curated=$(cd "$NODE_DIR" && find . -type f \
    -not -path '*/tests/*' \
    -not -path '*/__pycache__/*' \
    -not -name '*.pyc' \
    -not -name 'README.md' \
    -not -name 'MANIFEST' \
    | sed 's|^\./||' | sort -u)

# CN03 — MANIFEST is exactly the curated tree, both directions.
only_curated=$(comm -13 <(echo "$declared") <(echo "$curated"))
only_declared=$(comm -23 <(echo "$declared") <(echo "$curated"))
if [[ -z "$only_declared" && -z "$only_curated" ]]; then
    pass "CN03 MANIFEST matches the curated chat-node/ tree"
else
    [[ -n "$only_curated"  ]] && fail "CN03 chat-node files NOT in MANIFEST (would be omitted from install channels): $(echo $only_curated)"
    [[ -n "$only_declared" ]] && fail "CN03 MANIFEST lists files not present in chat-node/: $(echo $only_declared)"
fi

# CN04 — the entry point must be listed.
if grep -qx "server/node.mjs" <<<"$declared"; then
    pass "CN04 server/node.mjs is listed in MANIFEST"
else
    fail "CN04 server/node.mjs missing from MANIFEST (the component would provision as an empty directory)"
fi

# CN05 — every consumer derives from the manifest (references chat-node/MANIFEST).
for consumer in \
    "install.sh" \
    "install.ps1" \
    "packages/npm/scripts/vendor.js" \
    "packages/pypi/scripts/vendor.py" \
    "release.sh"
do
    f="${REPO_ROOT}/${consumer}"
    if [[ -f "$f" ]] && grep -qF "chat-node/MANIFEST" "$f"; then
        pass "CN05 ${consumer} references chat-node/MANIFEST"
    else
        fail "CN05 ${consumer} does not reference chat-node/MANIFEST (reverted to an inline list?)"
    fi
done

# CN06 — the node adds no third-party dependency. FR-7.6 is satisfied literally rather than
# by a carve-out, so the declared dependency lists must still be empty after it ships.
_pypi_toml="${REPO_ROOT}/packages/pypi/pyproject.toml"
if [[ -f "$_pypi_toml" ]]; then
    # Match `dependencies = []` allowing whitespace; a non-empty list fails.
    if grep -qE '^[[:space:]]*dependencies[[:space:]]*=[[:space:]]*\[[[:space:]]*\]' "$_pypi_toml"; then
        pass "CN06 packages/pypi/pyproject.toml declares no third-party dependency"
    else
        fail "CN06 packages/pypi/pyproject.toml declares a third-party dependency (FR-7.6 requires none)"
    fi
fi

_npm_pkg="${REPO_ROOT}/packages/npm/package.json"
if [[ -f "$_npm_pkg" ]]; then
    if python3 - "$_npm_pkg" <<'PY'
import json, sys
pkg = json.load(open(sys.argv[1]))
deps = {}
for key in ("dependencies", "peerDependencies", "optionalDependencies"):
    deps.update(pkg.get(key) or {})
sys.exit(0 if not deps else 1)
PY
    then
        pass "CN06 packages/npm/package.json declares no third-party dependency"
    else
        fail "CN06 packages/npm/package.json declares a third-party dependency (FR-7.6 requires none)"
    fi
fi

# CN07 — destination side: each channel must actually deliver the component.
# One assertion per consumer, each naming the specific thing that channel does with the
# files after reading the manifest.
#
# EACH NEEDLE MUST BE UNIQUE TO THE DELIVERING LINE. Two of these originally were not: a
# bare 'chat-node' also matched vendor.js's clean-slate rmSync, and a bare
# _chat_node_copies also matched vendor.py's comment and its own def -- so deleting the
# delivery while leaving those behind would have passed. That is the same false pass CN07
# exists to prevent, reproduced inside CN07 itself, which is why the needles now include
# their call arguments.
_cn07() {  # $1 = consumer path, $2 = needle, $3 = what the needle proves
    local f="${REPO_ROOT}/${1}"
    if [[ -f "$f" ]] && grep -qF -- "$2" "$f"; then
        pass "CN07 ${1} ${3}"
    else
        fail "CN07 ${1} fails to ${3} (reads the manifest but never delivers the files?)"
    fi
}
_cn07 "install.sh"                      '${AID_HOME}/chat-node'   "install the node into AID_HOME"
_cn07 "install.ps1"                     "Join-Path \$aidHome 'chat-node'" "install the node into aidHome"
_cn07 "packages/npm/scripts/vendor.js"  "readComponentManifest(repoRoot, 'chat-node')" "vendor the node into the npm payload"
_cn07 "packages/pypi/scripts/vendor.py" "_chat_node_copies(repo_root)" "vendor the node into the pypi payload"
_cn07 "release.sh"                      "./chat-node/%s"          "add the node's files to the CLI-bundle tar list"

# CN08 — npm ships only what `files` names.
_npm_pkg_json="${REPO_ROOT}/packages/npm/package.json"
if [[ -f "$_npm_pkg_json" ]]; then
    if python3 - "$_npm_pkg_json" <<'PY'
import json, sys
sys.exit(0 if "chat-node/" in (json.load(open(sys.argv[1])).get("files") or []) else 1)
PY
    then
        pass "CN08 packages/npm/package.json files[] includes chat-node/"
    else
        fail "CN08 packages/npm/package.json files[] omits chat-node/ (npm would publish without the node)"
    fi
fi

test_summary
