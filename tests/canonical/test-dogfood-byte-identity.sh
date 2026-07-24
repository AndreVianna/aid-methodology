#!/usr/bin/env bash
# test-dogfood-byte-identity.sh -- SS7a / C2 dogfood byte-identity guard.
#
# Asserts that the repo-root .claude/ tree and profiles/claude-code/.claude/
# are byte-identical for EVERY file that the generator owns -- THREE directions:
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
#   Direction 3 (repo-orphan sweep):  for each file present under the repo-root
#       dogfood .claude/, assert it is EITHER a generator-owned manifest dst OR
#       an explicitly DOCUMENTED non-generator file (the closed allowlist in
#       dbi_allowlisted below) -- so a generator-shaped repo-side orphan that
#       bypassed the manifest is caught (SS7a: the guard excludes nothing in
#       the AID-owned tree; the only un-compared files are the documented ones).
#
# The manifest is the authoritative comparison set.  The non-generator files
# that legitimately live in the dogfood .claude/ (Claude Code settings +
# session/memory state, the maintainer-only generate-profile toolchain and the
# release-aid ops skill, and the skills README) are DOCUMENTED in the
# Direction-3 allowlist rather than blindly skipped.
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
# Build the comparison set from the manifest: every dst under .claude/, plus
# its sha256, in a SINGLE awk pass (no python3 dependency, no per-entry
# re-scan). awk extracts "dst"/"sha256" from each JSON object line that
# contains a "dst" field starting with ".claude/" and emits "dst<TAB>sha256";
# the single sort keys on the unique dst, giving the same deterministic
# iteration order as before. A dst with no matched sha256 is still emitted
# (with an empty sha field) so it is never silently dropped from
# MANIFEST_DSTS -- its DBI-FWD check falls through to the MISMATCH branch
# below instead of vanishing from the comparison set.
# ---------------------------------------------------------------------------
declare -A MANIFEST_SHA
MANIFEST_DSTS=()
while IFS=$'\t' read -r dst sha; do
    [[ -z "$dst" ]] && continue
    MANIFEST_DSTS+=("$dst")
    MANIFEST_SHA["$dst"]="$sha"
done < <(
    awk '/"dst"[[:space:]]*:[[:space:]]*"\.claude\// {
        d=""; s=""
        if (match($0, /"dst"[[:space:]]*:[[:space:]]*"([^"]+)"/, da))         d=da[1]
        if (match($0, /"sha256"[[:space:]]*:[[:space:]]*"([a-f0-9]{64})"/, sa)) s=sa[1]
        if (d != "") print d "\t" s
    }' "$MANIFEST" | sort
)

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
#
# Setup (outside the loop, no fork-in-loop): collect the existing dogfood +
# profile paths via the builtin [[ -f ]] test (no forks), then batch-hash
# each list ONCE via a single `sha256sum` invocation over all paths (piped
# through `xargs -0` so an arbitrarily long list never overflows argv), into
# DOGFOOD_SHA / PROFILE_SHA maps keyed by absolute path. This replaces the
# previous 2 sha256sum forks PER manifest entry with 2 forks total.
# ---------------------------------------------------------------------------
log "Direction 1: manifest -> dogfood .claude/"

declare -a dogfood_list profile_list
for dst in "${MANIFEST_DSTS[@]}"; do
    rel="${dst#.claude/}"
    [[ -f "${DOGFOOD_CLAUDE}/${rel}" ]] && dogfood_list+=("${DOGFOOD_CLAUDE}/${rel}")
    [[ -f "${PROFILE_CLAUDE}/${rel}" ]] && profile_list+=("${PROFILE_CLAUDE}/${rel}")
done

declare -A DOGFOOD_SHA PROFILE_SHA
hash_into() {
    # $1 = target map name (DOGFOOD_SHA / PROFILE_SHA), rest = file list.
    local -n _map="$1"; shift
    [[ $# -eq 0 ]] && return 0
    local line
    while IFS= read -r line; do
        # sha256sum emits "<64-hex><SEP><SEP>path" where SEP SEP is "  " in
        # text mode or " *" in cygwin binary mode -- always exactly 2 chars
        # after the fixed 64-hex hash. The fixed-offset parse is mode-
        # agnostic and needs no per-line awk fork.
        _map["${line:66}"]="${line:0:64}"
    done < <(printf '%s\0' "$@" | xargs -0 -r sha256sum)
}
hash_into DOGFOOD_SHA "${dogfood_list[@]}"
hash_into PROFILE_SHA "${profile_list[@]}"

for dst in "${MANIFEST_DSTS[@]}"; do
    # Strip the leading ".claude/" to get the relative path inside .claude/.
    rel="${dst#.claude/}"

    profile_file="${PROFILE_CLAUDE}/${rel}"
    dogfood_file="${DOGFOOD_CLAUDE}/${rel}"
    expected_sha="${MANIFEST_SHA[$dst]}"

    # a) The file must exist in the dogfood tree.
    if [[ ! -f "$dogfood_file" ]]; then
        fail "DBI-FWD ${dst} -- MISSING in dogfood .claude/ (${dogfood_file})"
        continue
    fi

    # b) The dogfood file sha256 must match the manifest record.
    actual_sha="${DOGFOOD_SHA[$dogfood_file]:-}"
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
    profile_sha="${PROFILE_SHA[$profile_file]:-}"
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
done < <(find "$PROFILE_CLAUDE" -type f -not -path '*/node_modules/*' -not -path '*/.git/*' | sort)

# ---------------------------------------------------------------------------
# Direction 3 (repo-orphan sweep): every file under the repo-root dogfood
# .claude/ must be EITHER a generator-owned manifest dst (asserted in
# Direction 1) OR an explicitly DOCUMENTED non-generator file. A
# generator-shaped repo-side orphan -- a file that bypassed the manifest --
# fails loudly. This closes the SS7a requirement that the guard excludes
# nothing in the AID-owned tree: nothing is blindly skipped; the only files
# not compared are the closed, documented allowlist below.
# ---------------------------------------------------------------------------
log "Direction 3: repo .claude/ -> manifest-or-allowlist (orphan sweep)"

# Allowlist = the non-generator files that legitimately live in the dogfood
# .claude/ (no profile counterpart, not emitted by render.py):
#   settings.json / settings.local.json : Claude Code settings
#   projects/**                          : Claude Code session + memory state
#   worktrees/**                         : git worktree metadata
#   skills/README.md                     : maintainer index of skills (AID doc, not profile-emitted)
#   skills/generate-profile/**           : the generate-profile toolchain itself (render.py et al + caches)
#   skills/release-aid/**                : the maintainer-only release-aid ops skill (repo-local, never shipped)
dbi_allowlisted() {
    local rel="$1"
    case "$rel" in
        settings.json | settings.local.json) return 0 ;;
        projects/*)                return 0 ;;
        worktrees/*)               return 0 ;;
        skills/README.md)          return 0 ;;
        skills/generate-profile/*) return 0 ;;
        skills/release-aid/*)      return 0 ;;
        *) return 1 ;;
    esac
}

orphan_found=0
while IFS= read -r dogfood_file; do
    rel="${dogfood_file#${DOGFOOD_CLAUDE}/}"
    dst=".claude/${rel}"
    [[ -n "${MANIFEST_SET[$dst]+_}" ]] && continue   # generator-owned: covered by Direction 1
    if dbi_allowlisted "$rel"; then
        [[ $VERBOSE -eq 1 ]] && log "DBI-ORPHAN skip (documented non-generator): ${dst}"
        continue
    fi
    fail "DBI-ORPHAN ${dst} -- generator-shaped file in repo .claude/ is NOT in the manifest and NOT in the documented allowlist (a repo-side orphan that bypassed the generator)"
    orphan_found=1
done < <(find "$DOGFOOD_CLAUDE" -type f | sort)
[[ $orphan_found -eq 0 ]] && pass "DBI-ORPHAN repo .claude/ has no undocumented generator-shaped orphans"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
