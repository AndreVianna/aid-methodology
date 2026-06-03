#!/usr/bin/env bash
# test-housekeep-classify.sh — tier-assignment tests for cleanup-classify.sh
#
# Verifies that the scan + classify phase assigns tiers correctly against
# a fixture .aid/ tree constructed in a throwaway temp directory.
#
# Test scenarios:
#   Unit 1:  S1 .aid/.temp/** → Tier-0 checked
#   Unit 2:  S2 .aid/.heartbeat/** → Tier-0 checked
#   Unit 3:  S3 .aid/knowledge/.cache/** → Tier-0 checked
#   Unit 4:  S3 .aid/knowledge/.manual-checklist.json → Tier-0 checked
#   Unit 5:  S3 .aid/knowledge/.spot-check-facts.txt → Tier-0 checked
#   Unit 6:  S4 stray verify-deterministic-report.json → Tier-0 checked
#   Unit 7:  S4 stray verify-advisory-report.json → Tier-0 checked
#   Unit 8:  S5 unregistered .aid/generated/ output → Tier-0 checked
#   Unit 9:  S5 registered .aid/generated/ output → NOT emitted
#   Unit 10: Tier-2 loose .aid/ file (hand-authored) → Tier-2 unchecked
#   Unit 11: .aid/settings.yml → NOT emitted (protected system file)
#   Unit 12: .aid/knowledge/*.md live KB files → NOT emitted
#   Unit 13: Empty .aid/ (no candidates) → zero output lines
#
# Usage:
#   test-housekeep-classify.sh [-v | --verbose]
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/scripts/housekeep/cleanup-classify.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "${SCRIPT_DIR}/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

# Create a minimal git repo at path with a committed README so git ls-files works.
make_git_repo() {
    local repo="$1"
    mkdir -p "$repo"
    git -C "$repo" init -q --initial-branch=master 2>/dev/null \
        || { git -C "$repo" init -q; git -C "$repo" checkout -q -b master 2>/dev/null || true; }
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test"
    echo "init" > "${repo}/README.md"
    git -C "$repo" add README.md
    git -C "$repo" commit -q -m "chore: initial commit"
}

# Create the .aid/ directory structure in a repo.
make_aid_dir() {
    local repo="$1"
    mkdir -p "${repo}/.aid/generated"
    mkdir -p "${repo}/.aid/knowledge"
    # Create a minimal settings.yml (protected — must never be emitted as candidate)
    printf 'project:\n  name: test\n' > "${repo}/.aid/settings.yml"
    # Create a canonical/templates/generated-files.txt with one registered file
    mkdir -p "${repo}/canonical/templates"
    cat > "${repo}/canonical/templates/generated-files.txt" <<'REGEOF'
# Generated Files Registry
.aid/generated/project-index.md|bash canonical/scripts/kb/build-project-index.sh
.aid/generated/metrics.md|bash canonical/scripts/kb/build-metrics.sh
REGEOF
}

# Run SUT against a fixture repo and return stdout.
# Usage: run_classify <repo_dir> [extra_args...]
run_classify() {
    local repo="$1"; shift
    bash "$SUT" --root "$repo" "$@" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Global teardown
# ---------------------------------------------------------------------------
CLEANUP_DIRS=()
cleanup_all() {
    local d
    for d in "${CLEANUP_DIRS[@]:-}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup_all EXIT

# ---------------------------------------------------------------------------
# Helper: assert a line with given path prefix appears in output with expected
# tier and default_checked fields.
# Usage: assert_candidate OUTPUT PATH_SUFFIX EXPECTED_TIER EXPECTED_CHECKED LABEL
assert_candidate() {
    local output="$1"
    local path_suffix="$2"
    local expected_tier="$3"
    local expected_checked="$4"
    local label="$5"

    # Find the line containing path_suffix
    local matching_line
    matching_line=$(echo "$output" | grep -F "$path_suffix" | head -1) || matching_line=""

    if [[ -z "$matching_line" ]]; then
        fail "${label} — no output line contains path suffix '${path_suffix}'"
        return
    fi

    # Parse fields: PATH|TIER|TRACKED|DEFAULT_CHECKED|REASON[|GATE]
    local tier
    tier=$(echo "$matching_line" | cut -d'|' -f2)
    local checked
    checked=$(echo "$matching_line" | cut -d'|' -f4)

    assert_eq "$tier" "$expected_tier" "${label} tier"
    assert_eq "$checked" "$expected_checked" "${label} default_checked"
}

# Helper: assert a path suffix does NOT appear in output.
assert_not_candidate() {
    local output="$1"
    local path_suffix="$2"
    local label="$3"
    assert_output_not_contains "$output" "$path_suffix" "$label"
}

# ===========================================================================
echo ""
echo "=== Unit 1: S1 .aid/.temp/** → Tier-0 checked ==="

REPO1=$(mktemp -d)
CLEANUP_DIRS+=("$REPO1")
make_git_repo "$REPO1"
make_aid_dir "$REPO1"
mkdir -p "${REPO1}/.aid/.temp/review-pending"
echo "scratch" > "${REPO1}/.aid/.temp/scratch.txt"
echo "ledger" > "${REPO1}/.aid/.temp/review-pending/scope.md"

OUT1=$(run_classify "$REPO1")
assert_candidate "$OUT1" ".aid/.temp/scratch.txt" "0" "true" "U1 scratch.txt"
assert_candidate "$OUT1" ".aid/.temp/review-pending/scope.md" "0" "true" "U1 review-pending/scope.md"

# ===========================================================================
echo ""
echo "=== Unit 2: S2 .aid/.heartbeat/** → Tier-0 checked ==="

REPO2=$(mktemp -d)
CLEANUP_DIRS+=("$REPO2")
make_git_repo "$REPO2"
make_aid_dir "$REPO2"
mkdir -p "${REPO2}/.aid/.heartbeat"
echo "beat" > "${REPO2}/.aid/.heartbeat/agent-123.txt"

OUT2=$(run_classify "$REPO2")
assert_candidate "$OUT2" ".aid/.heartbeat/agent-123.txt" "0" "true" "U2 heartbeat file"

# ===========================================================================
echo ""
echo "=== Unit 3: S3 .aid/knowledge/.cache/** → Tier-0 checked ==="

REPO3=$(mktemp -d)
CLEANUP_DIRS+=("$REPO3")
make_git_repo "$REPO3"
make_aid_dir "$REPO3"
mkdir -p "${REPO3}/.aid/knowledge/.cache"
echo "cached" > "${REPO3}/.aid/knowledge/.cache/mermaid.json"

OUT3=$(run_classify "$REPO3")
assert_candidate "$OUT3" ".aid/knowledge/.cache/mermaid.json" "0" "true" "U3 cache file"

# ===========================================================================
echo ""
echo "=== Unit 4: S3 .manual-checklist.json → Tier-0 checked ==="

REPO4=$(mktemp -d)
CLEANUP_DIRS+=("$REPO4")
make_git_repo "$REPO4"
make_aid_dir "$REPO4"
echo '{"items":[]}' > "${REPO4}/.aid/knowledge/.manual-checklist.json"

OUT4=$(run_classify "$REPO4")
assert_candidate "$OUT4" ".aid/knowledge/.manual-checklist.json" "0" "true" "U4 manual-checklist.json"

# ===========================================================================
echo ""
echo "=== Unit 5: S3 .spot-check-facts.txt → Tier-0 checked ==="

REPO5=$(mktemp -d)
CLEANUP_DIRS+=("$REPO5")
make_git_repo "$REPO5"
make_aid_dir "$REPO5"
echo "facts" > "${REPO5}/.aid/knowledge/.spot-check-facts.txt"

OUT5=$(run_classify "$REPO5")
assert_candidate "$OUT5" ".aid/knowledge/.spot-check-facts.txt" "0" "true" "U5 spot-check-facts.txt"

# ===========================================================================
echo ""
echo "=== Unit 6: S4 stray verify-deterministic-report.json → Tier-0 checked ==="

REPO6=$(mktemp -d)
CLEANUP_DIRS+=("$REPO6")
make_git_repo "$REPO6"
make_aid_dir "$REPO6"
mkdir -p "${REPO6}/.aid/work-002-stray"
echo '{}' > "${REPO6}/.aid/work-002-stray/verify-deterministic-report.json"
# This work folder has no STATE.md → signal(i) fails → not offered as S6 folder.
# But the JSON file inside it should still be scanned as S4.

OUT6=$(run_classify "$REPO6" --active-work "work-002-stray")
assert_candidate "$OUT6" "verify-deterministic-report.json" "0" "true" "U6 verify-deterministic-report.json"

# ===========================================================================
echo ""
echo "=== Unit 7: S4 stray verify-advisory-report.json → Tier-0 checked ==="

REPO7=$(mktemp -d)
CLEANUP_DIRS+=("$REPO7")
make_git_repo "$REPO7"
make_aid_dir "$REPO7"
echo '{}' > "${REPO7}/.aid/verify-advisory-report.json"

OUT7=$(run_classify "$REPO7")
assert_candidate "$OUT7" "verify-advisory-report.json" "0" "true" "U7 verify-advisory-report.json"

# ===========================================================================
echo ""
echo "=== Unit 8: S5 unregistered .aid/generated/ output → Tier-0 checked ==="

REPO8=$(mktemp -d)
CLEANUP_DIRS+=("$REPO8")
make_git_repo "$REPO8"
make_aid_dir "$REPO8"
# Create an UNREGISTERED file (not in generated-files.txt)
echo "stale output" > "${REPO8}/.aid/generated/stale-output.json"

OUT8=$(run_classify "$REPO8")
assert_candidate "$OUT8" ".aid/generated/stale-output.json" "0" "true" "U8 unregistered generated file"

# ===========================================================================
echo ""
echo "=== Unit 9: S5 registered .aid/generated/ output → NOT emitted ==="

REPO9=$(mktemp -d)
CLEANUP_DIRS+=("$REPO9")
make_git_repo "$REPO9"
make_aid_dir "$REPO9"
# Create a REGISTERED file (in generated-files.txt: .aid/generated/project-index.md)
echo "# Project Index" > "${REPO9}/.aid/generated/project-index.md"

OUT9=$(run_classify "$REPO9")
assert_not_candidate "$OUT9" ".aid/generated/project-index.md" "U9 registered file not emitted"

# ===========================================================================
echo ""
echo "=== Unit 10: Tier-2 loose .aid/ file → Tier-2 unchecked ==="

REPO10=$(mktemp -d)
CLEANUP_DIRS+=("$REPO10")
make_git_repo "$REPO10"
make_aid_dir "$REPO10"
# Loose file directly under .aid/ — not matching S1–S5 patterns
echo "# Hand authored notes" > "${REPO10}/.aid/my-notes.md"

OUT10=$(run_classify "$REPO10")
assert_candidate "$OUT10" ".aid/my-notes.md" "2" "false" "U10 loose file tier-2"

# ===========================================================================
echo ""
echo "=== Unit 11: .aid/settings.yml → NOT emitted (protected) ==="

REPO11=$(mktemp -d)
CLEANUP_DIRS+=("$REPO11")
make_git_repo "$REPO11"
make_aid_dir "$REPO11"
# settings.yml already created by make_aid_dir

OUT11=$(run_classify "$REPO11")
assert_not_candidate "$OUT11" "settings.yml" "U11 settings.yml not emitted"

# ===========================================================================
echo ""
echo "=== Unit 12: .aid/knowledge/*.md live KB → NOT emitted ==="

REPO12=$(mktemp -d)
CLEANUP_DIRS+=("$REPO12")
make_git_repo "$REPO12"
make_aid_dir "$REPO12"
echo "# Knowledge doc" > "${REPO12}/.aid/knowledge/architecture.md"

OUT12=$(run_classify "$REPO12")
assert_not_candidate "$OUT12" "architecture.md" "U12 knowledge doc not emitted"

# ===========================================================================
echo ""
echo "=== Unit 13: Empty .aid/ (no stale artifacts) → zero output lines ==="

REPO13=$(mktemp -d)
CLEANUP_DIRS+=("$REPO13")
make_git_repo "$REPO13"
make_aid_dir "$REPO13"
# Only settings.yml and generated-files.txt — no candidates

OUT13=$(run_classify "$REPO13")
# Count lines containing '|' (pipe) — each candidate line has at least one.
# Use awk to avoid the grep -c empty-input ambiguity.
LINE_COUNT13=$(echo "$OUT13" | awk '/\|/{c++} END{print c+0}')
assert_eq "$LINE_COUNT13" "0" "U13 empty scan produces zero candidate lines"

# ===========================================================================
echo ""
test_summary
exit $?
