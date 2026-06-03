#!/usr/bin/env bash
# test-housekeep-workfolder-safety.sh — (i)/(ii) decision matrix tests for
# cleanup-classify.sh work-folder safety rules.
#
# Builds throwaway git repos with fake origin/master and .aid/work-*/ fixtures.
# Signal (i) is tested via the ancestry fallback (git merge-base --is-ancestor)
# so this suite runs entirely offline without network or gh.
# The gh-PR path is guarded by `command -v gh` → SKIP if absent.
#
# Test scenarios:
#   Unit 1:  (i)✓ (ii)✓ → offered Tier-1, gate=offer, default_checked=false
#   Unit 2:  (i)✓ (ii)✗ → emitted with gate=explicit-confirm, default_checked=false
#   Unit 3:  (i)✗ (unmerged SHA) → offered, gate=explicit-confirm (merge unverified)
#   Unit 4:  no STATE.md → offered, gate=explicit-confirm (user decides)
#   Unit 5:  no PR/no SHA in STATE.md → offered, gate=explicit-confirm (merge unverified)
#   Unit 6:  --active-work caller exclusion → NEVER offered (still honored)
#   Unit 7:  non-Deployed (Executing) status → offered, explicit-confirm (rule (c) REMOVED)
#   Unit 8:  current-branch work folder (rule (b)) → NEVER offered (the one hard skip)
#   Unit 9:  stale ## Housekeep Status block in a work folder → offered (rule (a) REMOVED)
#   Unit 10: gh absent (SKIP guard) — command -v gh returns nonzero → no gh calls
#
# Usage:
#   test-housekeep-workfolder-safety.sh [-v | --verbose]
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

# Create a minimal git repo on master with an initial commit.
# The "origin" remote is faked by creating a bare clone so
# git merge-base --is-ancestor ... origin/master works offline.
make_git_repo_with_origin() {
    local repo="$1"
    mkdir -p "$repo"
    git -C "$repo" init -q --initial-branch=master 2>/dev/null \
        || { git -C "$repo" init -q; git -C "$repo" checkout -q -b master 2>/dev/null || true; }
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test"
    echo "init" > "${repo}/README.md"
    git -C "$repo" add README.md
    git -C "$repo" commit -q -m "chore: initial commit"

    # Record initial master SHA (this will be "origin/master")
    local master_sha
    master_sha=$(git -C "$repo" rev-parse HEAD)

    # Create bare "remote" directory and register as origin
    local bare="${repo}_bare.git"
    git -C "$repo" clone -q --bare "$repo" "$bare" 2>/dev/null || true
    git -C "$repo" remote add origin "file://${bare}" 2>/dev/null || true
    git -C "$repo" fetch -q origin 2>/dev/null || true
    git -C "$repo" branch --set-upstream-to=origin/master master 2>/dev/null || true

    echo "$bare"  # return bare path for cleanup
}

# Add a commit to a repo on its current branch, return the commit SHA.
add_commit() {
    local repo="$1"
    local msg="${2:-test commit}"
    echo "$msg $(date +%s%N)" >> "${repo}/change.txt"
    git -C "$repo" add change.txt
    git -C "$repo" commit -q -m "$msg"
    git -C "$repo" rev-parse HEAD
}

# Create a minimal .aid/ structure in a repo.
make_aid_dir() {
    local repo="$1"
    mkdir -p "${repo}/.aid/generated"
    mkdir -p "${repo}/.aid/knowledge"
    printf 'project:\n  name: test\n' > "${repo}/.aid/settings.yml"
    mkdir -p "${repo}/canonical/templates"
    cat > "${repo}/canonical/templates/generated-files.txt" <<'REGEOF'
# Generated Files Registry
.aid/generated/project-index.md|bash canonical/scripts/kb/build-project-index.sh
REGEOF
}

# Create a work-folder STATE.md with configurable Status and Deploy Status.
#
# Usage: make_work_state <repo> <folder_name> <status_value> [sha] [pr_label]
#   sha:      40-char commit SHA → placed in Tag column; ancestry fallback uses it
#             for signal(i).  If no sha, signal(i) fails (no SHA to check).
#   pr_label: value for the PR column.  Use a non-numeric string (e.g. "merged")
#             to satisfy signal(ii) non-empty check WITHOUT triggering gh lookup
#             (gh is only called for numeric PR values).  Leave empty for "—"
#             (signal(ii) will then fail: no non-empty PR row).
make_work_state() {
    local repo="$1"
    local folder_name="$2"
    local status_val="$3"
    local sha="${4:-}"
    local pr_label="${5:-}"

    local folder="${repo}/.aid/${folder_name}"
    mkdir -p "$folder"

    # Build the deploy row based on what's provided
    local pr_col="—"
    [[ -n "$pr_label" ]] && pr_col="$pr_label"

    local sha_col="—"
    [[ -n "$sha" ]] && sha_col="$sha"

    local row_state="Deployed"
    local deploy_row=""
    if [[ -n "$sha" || -n "$pr_label" ]]; then
        deploy_row="| delivery-001 | ${row_state} | ${pr_col} | yes | ${sha_col} | — |"
    fi

    cat > "${folder}/STATE.md" <<STATEEOF
# Work State — ${folder_name}

> **Status:** ${status_val}

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|-----|------------|-----|-------|
${deploy_row}

## Tasks Status

| # | Task | Type | Status |
|---|------|------|--------|
STATEEOF
}

# Run classify on a repo; returns stdout.
run_classify() {
    local repo="$1"; shift
    bash "$SUT" --root "$repo" "$@" 2>/dev/null
}

# Parse gate field from a candidate line matching the given path suffix.
parse_gate() {
    local output="$1"
    local path_suffix="$2"
    echo "$output" | grep -F "$path_suffix" | head -1 | cut -d'|' -f6
}

parse_tier() {
    local output="$1"
    local path_suffix="$2"
    echo "$output" | grep -F "$path_suffix" | head -1 | cut -d'|' -f2
}

parse_checked() {
    local output="$1"
    local path_suffix="$2"
    echo "$output" | grep -F "$path_suffix" | head -1 | cut -d'|' -f4
}

# ---------------------------------------------------------------------------
# Global teardown
# ---------------------------------------------------------------------------
CLEANUP_DIRS=()
CLEANUP_BARE=()
cleanup_all() {
    local d
    for d in "${CLEANUP_DIRS[@]:-}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
    for d in "${CLEANUP_BARE[@]:-}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup_all EXIT

# ===========================================================================
echo ""
echo "=== Unit 1: (i)✓ (ii)✓ → Tier-1 offer, unchecked ==="

REPO1=$(mktemp -d)
CLEANUP_DIRS+=("$REPO1")
BARE1=$(make_git_repo_with_origin "$REPO1")
CLEANUP_BARE+=("$BARE1")
make_aid_dir "$REPO1"

# Add a commit on master (simulate work deliverable merged to master)
SHA1=$(add_commit "$REPO1" "feat: deliver work-099")

# Push to fake origin to update origin/master
git -C "$REPO1" push -q origin master 2>/dev/null || true
# Fetch to update remote-tracking refs
git -C "$REPO1" fetch -q origin 2>/dev/null || true

# Create work folder STATE.md: Deployed + SHA in Tag column + non-numeric PR label
# "merged" as PR label: non-numeric so gh won't call it, but non-empty so signal(ii) passes.
make_work_state "$REPO1" "work-099-done" "Deployed" "$SHA1" "merged"

OUT1=$(run_classify "$REPO1" --active-work "NONE_ACTIVE")
log "OUT1=$OUT1"

# Verify work-099-done appears as Tier-1, gate=offer, unchecked
MATCHING1=$(echo "$OUT1" | grep -F "work-099-done" | head -1)
if [[ -z "$MATCHING1" ]]; then
    fail "U1: work-099-done not in output"
else
    pass "U1: work-099-done appears in output"
    TIER1=$(parse_tier "$OUT1" "work-099-done")
    CHECKED1=$(parse_checked "$OUT1" "work-099-done")
    GATE1=$(parse_gate "$OUT1" "work-099-done")
    assert_eq "$TIER1" "1" "U1: tier is 1"
    assert_eq "$CHECKED1" "false" "U1: default_checked is false (unchecked)"
    assert_eq "$GATE1" "offer" "U1: gate is offer"
fi

# ===========================================================================
echo ""
echo "=== Unit 2: (i)✓ (ii)✗ → explicit-confirm ==="

REPO2=$(mktemp -d)
CLEANUP_DIRS+=("$REPO2")
BARE2=$(make_git_repo_with_origin "$REPO2")
CLEANUP_BARE+=("$BARE2")
make_aid_dir "$REPO2"

SHA2=$(add_commit "$REPO2" "feat: deliver work-098")
git -C "$REPO2" push -q origin master 2>/dev/null || true
git -C "$REPO2" fetch -q origin 2>/dev/null || true

# (i)✓: SHA is ancestor of origin/master
# (ii)✗: Status IS Deployed (passes rule c) but no terminal Deploy Status row
# (empty deploy row means signal(ii) finds no non-empty PR + terminal state)
# We create a STATE.md manually to have Deployed status but no terminal row.
mkdir -p "${REPO2}/.aid/work-098-partial"
cat > "${REPO2}/.aid/work-098-partial/STATE.md" <<STATEEOF2
# Work State — work-098-partial

> **Status:** Deployed

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|-----|------------|-----|-------|
| delivery-001 | In Progress | — | no | ${SHA2} | deploy incomplete |

## Tasks Status

| # | Task | Type | Status |
|---|------|------|--------|
STATEEOF2

OUT2=$(run_classify "$REPO2" --active-work "NONE_ACTIVE")
log "OUT2=$OUT2"

MATCHING2=$(echo "$OUT2" | grep -F "work-098-partial" | head -1)
if [[ -z "$MATCHING2" ]]; then
    fail "U2: work-098-partial not in output (expected explicit-confirm)"
else
    pass "U2: work-098-partial appears in output"
    TIER2=$(parse_tier "$OUT2" "work-098-partial")
    CHECKED2=$(parse_checked "$OUT2" "work-098-partial")
    GATE2=$(parse_gate "$OUT2" "work-098-partial")
    assert_eq "$TIER2" "1" "U2: tier is 1"
    assert_eq "$CHECKED2" "false" "U2: default_checked is false"
    # Gate must start with "explicit-confirm:"
    if [[ "$GATE2" == explicit-confirm:* ]]; then
        pass "U2: gate starts with explicit-confirm:"
    else
        fail "U2: gate expected 'explicit-confirm:...' got '$GATE2'"
    fi
fi

# ===========================================================================
echo ""
echo "=== Unit 3: (i)✗ (unmerged SHA) → still offered (explicit-confirm; merge unverified) ==="

REPO3=$(mktemp -d)
CLEANUP_DIRS+=("$REPO3")
BARE3=$(make_git_repo_with_origin "$REPO3")
CLEANUP_BARE+=("$BARE3")
make_aid_dir "$REPO3"

# Create a branch and commit that is NOT merged to master
git -C "$REPO3" switch -c "feature/work-097-branch" -q 2>/dev/null || true
SHA3=$(add_commit "$REPO3" "feat: work-097 NOT merged")
git -C "$REPO3" switch master -q 2>/dev/null || true
git -C "$REPO3" fetch -q origin 2>/dev/null || true
# SHA3 is on a branch, NOT merged into master

make_work_state "$REPO3" "work-097-unmerged" "Deployed" "$SHA3" "merged"

OUT3=$(run_classify "$REPO3" --active-work "NONE_ACTIVE")
log "OUT3=$OUT3"

# New design: an unmerged folder is NOT silently hidden — it is offered as Tier-1
# explicit-confirm with the "merge unverified" caveat, so the user decides.
if echo "$OUT3" | grep -F "work-097-unmerged" | grep -q "|1|.*|explicit-confirm:"; then
    pass "U3: unmerged folder offered as Tier-1 explicit-confirm (merge unverified; user decides)"
else
    fail "U3: unmerged folder NOT offered (should be offered for explicit user confirmation)"
fi

# ===========================================================================
echo ""
echo "=== Unit 4: No STATE.md → NOT offered (conservative fail) ==="

REPO4=$(mktemp -d)
CLEANUP_DIRS+=("$REPO4")
BARE4=$(make_git_repo_with_origin "$REPO4")
CLEANUP_BARE+=("$BARE4")
make_aid_dir "$REPO4"

# Create work folder with NO STATE.md
mkdir -p "${REPO4}/.aid/work-096-nostatemd"
echo "some file" > "${REPO4}/.aid/work-096-nostatemd/notes.txt"

OUT4=$(run_classify "$REPO4" --active-work "NONE_ACTIVE")
log "OUT4=$OUT4"

# New design: every work folder is OFFERED (never silently hidden) — "the user has
# the last word". A folder with no STATE.md → merge unverified → offered as Tier-1
# explicit-confirm so the user can confirm or decline.
if echo "$OUT4" | grep -F "work-096-nostatemd" | grep -q "|1|.*|explicit-confirm:"; then
    pass "U4: work-096-nostatemd offered as Tier-1 explicit-confirm (no STATE.md; user decides)"
else
    fail "U4: work-096-nostatemd NOT offered (should be offered for explicit user confirmation)"
fi

# ===========================================================================
echo ""
echo "=== Unit 5: No PR / no SHA in STATE.md → offered (explicit-confirm) ==="

REPO5=$(mktemp -d)
CLEANUP_DIRS+=("$REPO5")
BARE5=$(make_git_repo_with_origin "$REPO5")
CLEANUP_BARE+=("$BARE5")
make_aid_dir "$REPO5"

# STATE.md with Deployed status but NO PR and NO SHA
make_work_state "$REPO5" "work-095-nopr" "Deployed" ""

OUT5=$(run_classify "$REPO5" --active-work "NONE_ACTIVE")
log "OUT5=$OUT5"

if echo "$OUT5" | grep -F "work-095-nopr" | grep -q "|1|.*|explicit-confirm:"; then
    pass "U5: work-095-nopr offered as Tier-1 explicit-confirm (no PR/SHA → merge unverified; user decides)"
else
    fail "U5: work-095-nopr NOT offered (should be offered for explicit user confirmation)"
fi

# ===========================================================================
echo ""
echo "=== Unit 6: Active folder (--active-work flag) → NEVER offered ==="

REPO6=$(mktemp -d)
CLEANUP_DIRS+=("$REPO6")
BARE6=$(make_git_repo_with_origin "$REPO6")
CLEANUP_BARE+=("$BARE6")
make_aid_dir "$REPO6"

SHA6=$(add_commit "$REPO6" "feat: deliver work-094")
git -C "$REPO6" push -q origin master 2>/dev/null || true
git -C "$REPO6" fetch -q origin 2>/dev/null || true

# Even fully merged + concluded — must be excluded because it's the active work
make_work_state "$REPO6" "work-094-active" "Deployed" "$SHA6" "merged"

OUT6=$(run_classify "$REPO6" --active-work "work-094-active")
log "OUT6=$OUT6"

if echo "$OUT6" | grep -qF "work-094-active"; then
    fail "U6: active folder appeared in output (must never be offered)"
else
    pass "U6: active folder correctly excluded from output"
fi

# ===========================================================================
echo ""
echo "=== Unit 7: non-Deployed (Executing) STATUS → still offered (rule (c) removed) ==="

REPO7=$(mktemp -d)
CLEANUP_DIRS+=("$REPO7")
BARE7=$(make_git_repo_with_origin "$REPO7")
CLEANUP_BARE+=("$BARE7")
make_aid_dir "$REPO7"

# Rule (c) ("Status != Deployed → hide") was REMOVED — the user has the last word.
# An Executing folder (no PR) → merge unverified → offered as explicit-confirm, with
# the STATE surfaced in the prompt so the user can decline in-progress work.
make_work_state "$REPO7" "work-093-executing" "Executing" ""

OUT7=$(run_classify "$REPO7")
log "OUT7=$OUT7"

if echo "$OUT7" | grep -F "work-093-executing" | grep -q "|1|.*|explicit-confirm:"; then
    pass "U7: Executing folder offered as Tier-1 explicit-confirm (rule c removed; user decides)"
else
    fail "U7: Executing folder NOT offered (should be offered for explicit user confirmation)"
fi

# ===========================================================================
echo ""
echo "=== Unit 8: Active folder via (b) branch match → NEVER offered ==="

REPO8=$(mktemp -d)
CLEANUP_DIRS+=("$REPO8")
BARE8=$(make_git_repo_with_origin "$REPO8")
CLEANUP_BARE+=("$BARE8")
make_aid_dir "$REPO8"

SHA8=$(add_commit "$REPO8" "feat: deliver work-092")
git -C "$REPO8" push -q origin master 2>/dev/null || true
git -C "$REPO8" fetch -q origin 2>/dev/null || true

# Create work-092, Deployed+SHA (would normally be offered — but branch match excludes it)
make_work_state "$REPO8" "work-092-branch" "Deployed" "$SHA8" "merged"

# Switch to a branch matching work-092 so rule (b) triggers
git -C "$REPO8" switch -c "aid/work-092-branch" -q 2>/dev/null || true

OUT8=$(run_classify "$REPO8")
log "OUT8=$OUT8"

if echo "$OUT8" | grep -F "work-092-branch" | grep -q "|1|"; then
    fail "U8: branch-matched folder emitted as Tier-1 (must be excluded by rule (b))"
else
    pass "U8: branch-matched folder not offered as Tier-1 (rule b)"
fi

# ===========================================================================
echo ""
echo "=== Unit 9: stale ## Housekeep Status block in a work folder → still offered (rule (a) removed) ==="

REPO9=$(mktemp -d)
CLEANUP_DIRS+=("$REPO9")
BARE9=$(make_git_repo_with_origin "$REPO9")
CLEANUP_BARE+=("$BARE9")
make_aid_dir "$REPO9"

SHA9=$(add_commit "$REPO9" "feat: deliver work-091")
git -C "$REPO9" push -q origin master 2>/dev/null || true
git -C "$REPO9" fetch -q origin 2>/dev/null || true

mkdir -p "${REPO9}/.aid/work-091-housekeep"

# STATE.md with Deployed + SHA + ## Housekeep Status block (rule a)
cat > "${REPO9}/.aid/work-091-housekeep/STATE.md" <<HKEOF
# Work State — work-091-housekeep

> **Status:** Deployed

## Deploy Status

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|-----|------------|-----|-------|
| delivery-001 | Deployed | — | yes | ${SHA9} | — |

## Housekeep Status

**State:** DONE
**KB Stage:** passed
**Summary Stage:** passed
**Cleanup Stage:** passed
HKEOF

OUT9=$(run_classify "$REPO9")
log "OUT9=$OUT9"

if echo "$OUT9" | grep -F "work-091-housekeep" | grep -q "|1|"; then
    pass "U9: folder with a stale ## Housekeep Status block offered as Tier-1 (rule a removed; user decides)"
else
    fail "U9: folder NOT offered (rule (a) removal should let it be offered for confirmation)"
fi

# ===========================================================================
echo ""
echo "=== Unit 10: gh absent → SKIP gh-PR path (ancestry fallback used) ==="

# This test verifies the gh guard works by checking the script handles
# the case where gh is not available. We do this by verifying the script
# still produces correct output (using ancestry fallback) without requiring gh.
# The SUT guards with: command -v gh → only calls gh if available.

REPO10=$(mktemp -d)
CLEANUP_DIRS+=("$REPO10")
BARE10=$(make_git_repo_with_origin "$REPO10")
CLEANUP_BARE+=("$BARE10")
make_aid_dir "$REPO10"

SHA10=$(add_commit "$REPO10" "feat: deliver work-090")
git -C "$REPO10" push -q origin master 2>/dev/null || true
git -C "$REPO10" fetch -q origin 2>/dev/null || true

# "merged" as PR label: non-numeric so gh won't call it; signal(ii) passes
make_work_state "$REPO10" "work-090-noph" "Deployed" "$SHA10" "merged"

# Run with a PATH that makes gh unavailable (even if it's installed on host)
OUT10=$(PATH="/usr/bin:/bin" bash "$SUT" --root "$REPO10" --active-work "NONE_ACTIVE" 2>/dev/null)
log "OUT10=$OUT10"

# With gh absent, the ancestry fallback (git merge-base --is-ancestor SHA origin/master)
# resolves against the LOCAL bare origin (set up by make_git_repo_with_origin), so the
# merged folder MUST be offered. This is a hard assertion — a miss is a real defect, not
# an environmental skip.
MATCHING10=$(echo "$OUT10" | grep -F "work-090-noph" | head -1)
if [[ -z "$MATCHING10" ]]; then
    fail "U10: ancestry fallback (gh absent) must offer the merged work folder, but it was not emitted"
else
    GATE10=$(echo "$MATCHING10" | cut -d'|' -f6)
    assert_eq "$GATE10" "offer" "U10: ancestry fallback used (gh absent) → gate=offer"
fi

# ===========================================================================
echo ""
test_summary
exit $?
