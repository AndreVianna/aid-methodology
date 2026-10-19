#!/usr/bin/env bash
# test-never-merges.sh - Static guard: AID never merges, and never opens or merges a PR
# outside the pipeline's own skill (Feature 002 section 8, groups NM-01 to NM-04).
#
# COVERS: canonical/
# COVERS: bin/
# COVERS: lib/
# COVERS: dashboard/
# COVERS: chat-node/
# COVERS: scripts/
# COVERS: release.sh
# COVERS: install.sh
# COVERS: install.ps1
#
# Scope: the tracked files (git ls-files) under the include globs below, minus every path
# with a tests/ or __tests__/ folder (their fixtures name merge commands on purpose) and
# the two knowledge document templates whose example commands are text for a reader.
#
#   NM-01  no `git merge` and no `git pull` without --ff-only, except `git merge-base` /
#          `git merge-tree` and canonical/aid/scripts/pipeline/merge-parent.sh (which only
#          brings the parent branch or the work branch's own remote copy into the work branch)
#   NM-02  no `gh pr merge`, `glab mr merge`, merge-endpoint call, or `git push` to main/master
#   NM-03  `gh pr create` / `glab mr create` only under canonical/skills/aid-monitor-pipeline/;
#          exempt: canonical/skills/aid-housekeep/references/state-done.md (until Feature 004)
#   NM-04  no "merge to main" under canonical/skills/;
#          exempt: aid-execute SKILL.md, references/reviewer-brief.md and
#          references/state-delivery-gate.md (until Feature 007)
#
# An exemption that names a file which no longer exists fails: its feature has landed and
# the exemption must go with it.
#
# Usage:
#   bash test-never-merges.sh
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

INCLUDE=(
    ':(glob)canonical/**'
    ':(glob)bin/**'
    ':(glob)lib/**'
    ':(glob)dashboard/**'
    ':(glob)chat-node/**'
    ':(glob)scripts/**'
    release.sh
    install.sh
    install.ps1
)
EXCLUDE=(
    ':(exclude,glob)**/tests/**'
    ':(exclude,glob)**/__tests__/**'
    ':(exclude,glob)canonical/aid/templates/knowledge-summary/**'
    ':(exclude,glob)canonical/aid/templates/knowledge-base/**'
)

MERGE_ALLOWED_PATH='canonical/aid/scripts/pipeline/merge-parent.sh'
PR_CREATE_ALLOWED_PREFIX='canonical/skills/aid-monitor-pipeline/'
NM03_EXEMPT='canonical/skills/aid-housekeep/references/state-done.md'
NM04_EXEMPT='canonical/skills/aid-execute/SKILL.md canonical/skills/aid-execute/references/reviewer-brief.md canonical/skills/aid-execute/references/state-delivery-gate.md'

mapfile -d '' SCAN_FILES < <(git ls-files -z -- "${INCLUDE[@]}" "${EXCLUDE[@]}")

echo "=== Never-merges static guard ==="

if [[ ${#SCAN_FILES[@]} -eq 0 ]]; then
    fail "NM scope: no tracked files matched the include and exclude globs"
    test_summary
    exit $?
fi
log "scanning ${#SCAN_FILES[@]} tracked file(s)"

# scan_hits [-i] PATTERN -- print "path:line:text" for each scanned line matching the ERE.
scan_hits() {
    local pattern
    if [[ "${1:-}" == "-i" ]]; then
        pattern="$2"
        grep -I -n -i -E -e "$pattern" -- "${SCAN_FILES[@]}" 2>/dev/null || true
    else
        pattern="$1"
        grep -I -n -E -e "$pattern" -- "${SCAN_FILES[@]}" 2>/dev/null || true
    fi
}

# judge GROUP EXEMPT_PATHS HITS -- every hit must sit in an exempt path; any other hit fails.
judge() {
    local group="$1" exempt=" $2 " hits="$3" line path exempt_lines=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        path="${line%%:*}"
        if [[ "$exempt" == *" $path "* ]]; then
            exempt_lines=$((exempt_lines + 1))
            log "$group exempt: $line"
        else
            fail "$group -- $line"
        fi
    done <<< "$hits"
    if [[ $exempt_lines -gt 0 ]]; then
        pass "$group: $exempt_lines line(s) fire only in the exempt paths"
    else
        pass "$group: no line in an exempt path fires"
    fi
}

# exempt_exists GROUP EXEMPT_PATHS -- an exemption whose file is gone fails (its feature landed).
exempt_exists() {
    local group="$1" path
    for path in $2; do
        if [[ -f "$path" ]]; then
            pass "$group exemption present: $path"
        else
            fail "$group exemption stale -- $path no longer exists; remove the exemption"
        fi
    done
}

# NM-01: git merge / git pull without --ff-only.
nm01_hits=$(scan_hits 'git (merge|pull)' \
    | grep -v -E 'git merge-(base|tree)' \
    | grep -v -E 'git pull.*--ff-only' \
    | grep -v -E "^${MERGE_ALLOWED_PATH}:" || true)
judge "NM-01 git merge / git pull" "" "$nm01_hits"

# NM-02: merge commands, merge endpoints, git push to main or master.
nm02_hits=$(scan_hits 'gh pr merge|glab mr merge|pulls/[^ ]*/merge|merge_requests/[^ ]*/merge|git push[^|;]* (main|master)\b' || true)
judge "NM-02 merge command / endpoint / push to main" "" "$nm02_hits"

# NM-03: PR or MR creation only under the monitor pipeline skill.
nm03_hits=$(scan_hits 'gh pr create|glab mr create' \
    | grep -v -E "^${PR_CREATE_ALLOWED_PREFIX}" || true)
judge "NM-03 gh pr create / glab mr create" "$NM03_EXEMPT" "$nm03_hits"
exempt_exists "NM-03" "$NM03_EXEMPT"

# NM-04: no "merge to main" under canonical/skills/.
nm04_hits=$(scan_hits -i 'merge to main' | grep -E '^canonical/skills/' || true)
judge "NM-04 merge to main" "$NM04_EXEMPT" "$nm04_hits"
exempt_exists "NM-04" "$NM04_EXEMPT"

test_summary
