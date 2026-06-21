#!/usr/bin/env bash
# test-dogfood-byte-identity.sh -- SS7a / C2 dogfood byte-identity guard.
#
# Asserts that the repo-root .claude/ tree and profiles/claude-code/.claude/
# are byte-identical for EVERY file that the generator owns -- both directions:
#
#   Direction 1 (forward):  for each dst entry in the emission manifest that
#       starts with ".claude/", assert the corresponding file under repo-root
#       .claude/ exists AND its sha256 matches the manifest record.
#
#   Direction 2 (reverse):  for each file present under
#       profiles/claude-code/.claude/, assert it appears as a dst in the
#       manifest (i.e. the manifest is complete -- no generator-produced file
#       was silently omitted from the manifest).
#
# The manifest is the authoritative comparison set.  Non-generator files that
# legitimately exist in the dogfood .claude/ (settings.json, projects/,
# worktrees/, skills/README.md, the skills/generate-profile/ toolchain) are
# NOT in the manifest and are therefore NOT compared -- this avoids false
# positives on those user-owned files.
#
# On any mismatch the suite fails loudly, naming the first divergent path.
#
# Registered automatically: tests/run-all.sh discovers all
# tests/canonical/test-*.sh by glob; no workflow YAML edit is needed.
#
# Usage:
#   bash tests/canonical/test-dogfood-byte-identity.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

MANIFEST="${REPO_ROOT}/profiles/claude-code/emission-manifest.jsonl"
PROFILE_CLAUDE="${REPO_ROOT}/profiles/claude-code/.claude"
DOGFOOD_CLAUDE="${REPO_ROOT}/.claude"

echo "=== dogfood byte-identity guard (SS7a / C2) ==="

# ---------------------------------------------------------------------------
# DBI00 -- prerequisites: manifest and both .claude/ trees must exist.
# ---------------------------------------------------------------------------
assert_file_exists "$MANIFEST" "DBI00 emission-manifest.jsonl exists"
assert_dir_exists  "$PROFILE_CLAUDE" "DBI00b profiles/claude-code/.claude/ exists"
assert_dir_exists  "$DOGFOOD_CLAUDE" "DBI00c repo-root .claude/ exists"

# Bail early if any prerequisite is missing -- remaining asserts would all
# cascade-fail with misleading messages.
if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

# ---------------------------------------------------------------------------
# Build the comparison set from the manifest: every dst under .claude/.
# We parse with awk to stay pure-bash-toolchain (no python3 dependency).
#
# awk extracts the value of "dst" from each JSON object line that contains
# a "dst" field starting with ".claude/".  The manifest is simple one-record-
# per-line JSONL so a targeted regex is safe.
# ---------------------------------------------------------------------------
mapfile -t MANIFEST_DSTS < <(
    awk '/"dst"[[:space:]]*:[[:space:]]*"\.claude\// {
        match($0, /"dst"[[:space:]]*:[[:space:]]*"([^"]+)"/, arr)
        if (arr[1] != "") print arr[1]
    }' "$MANIFEST" | sort
)

MANIFEST_SHA_OF() {
    # Extract sha256 for a given dst from the manifest.
    local dst="$1"
    # Escape for use as a fixed string in awk.
    awk -v target="$dst" '
    index($0, "\"dst\"") && index($0, target) {
        match($0, /"sha256"[[:space:]]*:[[:space:]]*"([a-f0-9]{64})"/, arr)
        if (arr[1] != "") { print arr[1]; exit }
    }' "$MANIFEST"
}

TOTAL_MANIFEST=${#MANIFEST_DSTS[@]}

if [[ $TOTAL_MANIFEST -eq 0 ]]; then
    fail "DBI01 manifest contains no .claude/ entries -- is the manifest empty?"
    test_summary
    exit 1
fi

pass "DBI01 manifest loaded -- ${TOTAL_MANIFEST} generator-owned .claude/ entries"

# ---------------------------------------------------------------------------
# Direction 1 (forward): every manifest entry must exist in the dogfood tree
# AND its sha256 must match the manifest record.
# ---------------------------------------------------------------------------
log "Direction 1: manifest -> dogfood .claude/"

for dst in "${MANIFEST_DSTS[@]}"; do
    # Strip the leading ".claude/" to get the relative path inside .claude/.
    rel="${dst#.claude/}"

    profile_file="${PROFILE_CLAUDE}/${rel}"
    dogfood_file="${DOGFOOD_CLAUDE}/${rel}"
    expected_sha="$(MANIFEST_SHA_OF "$dst")"

    # a) The file must exist in the dogfood tree.
    if [[ ! -f "$dogfood_file" ]]; then
        fail "DBI-FWD ${dst} -- MISSING in dogfood .claude/ (${dogfood_file})"
        continue
    fi

    # b) The dogfood file sha256 must match the manifest record.
    actual_sha="$(sha256sum "$dogfood_file" | awk '{print $1}')"
    if [[ "$actual_sha" != "$expected_sha" ]]; then
        fail "DBI-FWD ${dst} -- sha256 MISMATCH: manifest=${expected_sha} dogfood=${actual_sha}"
        continue
    fi

    # c) For completeness: the profile file sha256 must also match (guards
    #    the profile tree itself against silent drift, e.g. an accidental
    #    direct edit to the profile file that bypassed the generator).
    if [[ ! -f "$profile_file" ]]; then
        fail "DBI-FWD ${dst} -- MISSING in profile .claude/ (${profile_file})"
        continue
    fi
    profile_sha="$(sha256sum "$profile_file" | awk '{print $1}')"
    if [[ "$profile_sha" != "$expected_sha" ]]; then
        fail "DBI-FWD ${dst} -- sha256 MISMATCH: manifest=${expected_sha} profile=${profile_sha}"
        continue
    fi

    pass "DBI-FWD ${dst}"
done

# ---------------------------------------------------------------------------
# Direction 2 (reverse): every file present under profiles/claude-code/.claude/
# must have a corresponding manifest entry (ensures the manifest is complete
# and no generator-produced file was silently dropped from the manifest).
# ---------------------------------------------------------------------------
log "Direction 2: profiles/claude-code/.claude/ -> manifest"

# Build a lookup set from MANIFEST_DSTS for O(1) membership checks.
# We use an associative array keyed by the full dst string.
declare -A MANIFEST_SET
for dst in "${MANIFEST_DSTS[@]}"; do
    MANIFEST_SET["$dst"]=1
done

while IFS= read -r profile_file; do
    # Derive the dst key as it would appear in the manifest.
    rel="${profile_file#${PROFILE_CLAUDE}/}"
    dst=".claude/${rel}"

    if [[ -z "${MANIFEST_SET[$dst]+_}" ]]; then
        fail "DBI-REV ${dst} -- file exists in profiles/claude-code/.claude/ but is NOT in manifest"
    else
        pass "DBI-REV ${dst}"
    fi
done < <(find "$PROFILE_CLAUDE" -type f | sort)

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
