#!/usr/bin/env bash
# test-release.sh — tests for release.sh, the maintainer helper that packages
# the five per-profile AID tarballs and SHA256SUMS for a GitHub Release.
#
# Drives release.sh --dry-run (hermetic: no network, no gh, no tag creation).
# Uses a local git clone per test group so the real profiles/ is untouched and
# the clean-worktree precondition is satisfied.
#
# Cases: RL01 naming, RL02 layout, RL03 flat root, RL04 SHA256SUMS format,
#        RL05 checksum correctness, RL06 render-drift FAIL, RL07 version-mismatch,
#        RL08 help/exit.
#
# Usage:
#   bash test-release.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/release.sh"

[[ -f "$SUT" ]] || { echo "ERROR: release.sh not found at $SUT" >&2; exit 1; }

# Require python (python or python3) for the render-drift gate.
PYTHON_CMD=""
if command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
fi
if [[ -z "$PYTHON_CMD" ]]; then
    echo "SKIP: python not found — render-drift gate requires python; skipping test-release.sh"
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# The commit to test: the current HEAD SHA. Using the SHA (not a branch name) is robust
# in CI's detached-HEAD checkouts (PR builds check out a merge commit, where the branch
# name resolves to the literal "HEAD"). Override with AID_TEST_REF for ad-hoc runs.
WORKTREE_REF="${AID_TEST_REF:-$(git -C "${REPO_ROOT}" rev-parse HEAD)}"
# Main .git directory (shared across worktrees) for cloning.
MAIN_GIT_DIR="$(git -C "${REPO_ROOT}" rev-parse --git-common-dir)"
MAIN_REPO_ROOT="$(cd "${MAIN_GIT_DIR}/.." 2>/dev/null && pwd)" || MAIN_REPO_ROOT="${REPO_ROOT}"

# ---------------------------------------------------------------------------
# make_clone <dest>
#   Create a fast local clone of the worktree branch at <dest> and inject
#   release.sh (which is untracked — not yet committed in the worktree).
#   Sets core.fileMode=false to match the main repo setting so that generator-
#   induced chmod changes on .sh files do not appear as render drift.
# ---------------------------------------------------------------------------
make_clone() {
    local dest="$1"
    # Clone the exact commit under test (current VERSION + profiles/ state), robust under
    # CI's detached-HEAD PR checkouts. A detached HEAD has no branch ref, so a plain local
    # clone can omit the commit; pin it with a temp tag, clone that tag, then remove it.
    local _ref="aid-test-clone-$$"
    git -C "${MAIN_REPO_ROOT}" tag -f "${_ref}" "${WORKTREE_REF}" >/dev/null 2>&1
    git clone --local --quiet --branch "${_ref}" "${MAIN_REPO_ROOT}" "${dest}" 2>/dev/null
    git -C "${MAIN_REPO_ROOT}" tag -d "${_ref}" >/dev/null 2>&1
    # Mirror the main repo's fileMode=false so chmod changes from run_generator.py
    # are not treated as render drift (same setting as the origin repo).
    git -C "${dest}" config core.fileMode false
    # Configure identity so any git operations in the clone succeed.
    git -C "${dest}" config user.email "test@example.com"
    git -C "${dest}" config user.name "Test"
    # Inject release.sh from the working tree.  The file may be committed in the
    # clone (part of the worktree branch) or untracked there.  In either case we
    # tell git to assume it's unchanged so that neither the post-clone sanity check
    # (`git diff --quiet`) nor release.sh's own precondition (`git diff --quiet`)
    # detects it as a modification.
    cp "${SUT}" "${dest}/release.sh"
    # Tell git to skip worktree tracking for this file (assume-unchanged) so it
    # does not appear in `git diff` output.
    if git -C "${dest}" ls-files --error-unmatch release.sh >/dev/null 2>&1; then
        git -C "${dest}" update-index --assume-unchanged release.sh 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------------
# RL08: help / unknown-flag (run directly against real repo; these flags
#       fail before any precondition check, so a dirty worktree is fine).
# ---------------------------------------------------------------------------

# RL08a --help exits 0 and contains key flag names in its output.
# Use substrings that won't be interpreted as grep flags (avoid leading dashes).
OUT=$(bash "$SUT" --help 2>&1); RC=$?
assert_exit_zero "$RC" "RL08a --help exits 0"
assert_output_contains "$OUT" "dry-run" "RL08a --help output mentions dry-run"
assert_output_contains "$OUT" "version X.Y.Z" "RL08a --help output mentions version X.Y.Z"
assert_output_contains "$OUT" "No network I/O" "RL08a --help output describes dry-run behaviour"

# RL08b unknown flag exits non-zero (exit 2).
OUT=$(bash "$SUT" --unknown-flag-xyz 2>&1); RC=$?
assert_exit_nonzero "$RC" "RL08b unknown flag exits non-zero"
assert_output_contains "$OUT" "unknown flag" "RL08b error message mentions unknown flag"

# RL07: version mismatch exits 3 (before clean-worktree check).
VERSION_ACTUAL="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
OUT=$(bash "$SUT" --version 9.9.9 --dry-run 2>&1); RC=$?
assert_exit_eq "$RC" 3 "RL07 --version 9.9.9 != VERSION file exits 3"
assert_output_contains "$OUT" "9.9.9" "RL07 error mentions the passed version"
assert_output_contains "$OUT" "${VERSION_ACTUAL}" "RL07 error mentions the VERSION-file version"

# ---------------------------------------------------------------------------
# Build the clean clone used for all happy-path cases (RL01–RL05).
# ---------------------------------------------------------------------------
CLONE="${TMP}/clone-happy"
make_clone "${CLONE}"

# Verify the clone is clean before driving release.sh.
if ! git -C "${CLONE}" diff --quiet; then
    fail "clone sanity — clone has unexpected uncommitted changes"
fi

# Run --dry-run inside the clone.
STAGE_VERSION="$(tr -d '[:space:]' < "${CLONE}/VERSION")"
STAGE_DIR="${CLONE}/.aid/.temp/release-${STAGE_VERSION}"

OUT=$(cd "${CLONE}" && bash ./release.sh --dry-run 2>&1); RC=$?
assert_exit_zero "$RC" "RL01 dry-run exits 0 (happy path)"

# ---------------------------------------------------------------------------
# RL01: Naming — exactly six tarballs: five profile + one CLI bundle
# ---------------------------------------------------------------------------
TOOLS=("claude-code" "codex" "cursor" "copilot-cli" "antigravity")
TARBALL_COUNT=$(ls "${STAGE_DIR}"/aid-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
assert_eq "${TARBALL_COUNT}" "6" "RL01 exactly 6 tarballs in staging dir (5 profile + 1 CLI bundle)"

for tool in "${TOOLS[@]}"; do
    assert_file_exists "${STAGE_DIR}/aid-${tool}-v${STAGE_VERSION}.tar.gz" \
        "RL01 aid-${tool}-v${STAGE_VERSION}.tar.gz exists"
done

# CLI bundle.
assert_file_exists "${STAGE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz" \
    "RL01 aid-cli-v${STAGE_VERSION}.tar.gz (CLI bundle) exists"

# ---------------------------------------------------------------------------
# RL02: Layout — expected roots present; no README.md; no emission-manifest.jsonl
# RL03: Flat root — no wrapping aid-<tool>/ prefix on any entry
# ---------------------------------------------------------------------------

# claude-code: .claude/ tree + CLAUDE.md
TARBALL="${STAGE_DIR}/aid-claude-code-v${STAGE_VERSION}.tar.gz"
LISTING="$(tar -tzf "${TARBALL}")"

assert_output_contains "${LISTING}" "./.claude/" \
    "RL02 claude-code tarball contains .claude/ dir"
assert_output_contains "${LISTING}" "./CLAUDE.md" \
    "RL02 claude-code tarball contains root CLAUDE.md"
assert_output_not_contains "${LISTING}" "README.md" \
    "RL02 claude-code tarball has no README.md"
assert_output_not_contains "${LISTING}" "emission-manifest.jsonl" \
    "RL02 claude-code tarball has no emission-manifest.jsonl"
assert_output_not_contains "${LISTING}" "aid-claude-code/" \
    "RL03 claude-code tarball has no wrapping aid-claude-code/ prefix"

# codex: .agents/ + .codex/ + AGENTS.md
TARBALL="${STAGE_DIR}/aid-codex-v${STAGE_VERSION}.tar.gz"
LISTING="$(tar -tzf "${TARBALL}")"

assert_output_contains "${LISTING}" "./.agents/" \
    "RL02 codex tarball contains .agents/ dir"
assert_output_contains "${LISTING}" "./.codex/" \
    "RL02 codex tarball contains .codex/ dir"
assert_output_contains "${LISTING}" "./AGENTS.md" \
    "RL02 codex tarball contains root AGENTS.md"
assert_output_not_contains "${LISTING}" "README.md" \
    "RL02 codex tarball has no README.md"
assert_output_not_contains "${LISTING}" "emission-manifest.jsonl" \
    "RL02 codex tarball has no emission-manifest.jsonl"
assert_output_not_contains "${LISTING}" "aid-codex/" \
    "RL03 codex tarball has no wrapping aid-codex/ prefix"

# cursor: .cursor/ + AGENTS.md
TARBALL="${STAGE_DIR}/aid-cursor-v${STAGE_VERSION}.tar.gz"
LISTING="$(tar -tzf "${TARBALL}")"

assert_output_contains "${LISTING}" "./.cursor/" \
    "RL02 cursor tarball contains .cursor/ dir"
assert_output_contains "${LISTING}" "./AGENTS.md" \
    "RL02 cursor tarball contains root AGENTS.md"
assert_output_not_contains "${LISTING}" "README.md" \
    "RL02 cursor tarball has no README.md"
assert_output_not_contains "${LISTING}" "emission-manifest.jsonl" \
    "RL02 cursor tarball has no emission-manifest.jsonl"
assert_output_not_contains "${LISTING}" "aid-cursor/" \
    "RL03 cursor tarball has no wrapping aid-cursor/ prefix"

# copilot-cli: .github/ + AGENTS.md
TARBALL="${STAGE_DIR}/aid-copilot-cli-v${STAGE_VERSION}.tar.gz"
LISTING="$(tar -tzf "${TARBALL}")"

assert_output_contains "${LISTING}" "./.github/" \
    "RL02 copilot-cli tarball contains .github/ dir"
assert_output_contains "${LISTING}" "./AGENTS.md" \
    "RL02 copilot-cli tarball contains root AGENTS.md"
assert_output_not_contains "${LISTING}" "README.md" \
    "RL02 copilot-cli tarball has no README.md"
assert_output_not_contains "${LISTING}" "emission-manifest.jsonl" \
    "RL02 copilot-cli tarball has no emission-manifest.jsonl"
assert_output_not_contains "${LISTING}" "aid-copilot-cli/" \
    "RL03 copilot-cli tarball has no wrapping aid-copilot-cli/ prefix"

# antigravity: .agent/ + AGENTS.md
TARBALL="${STAGE_DIR}/aid-antigravity-v${STAGE_VERSION}.tar.gz"
LISTING="$(tar -tzf "${TARBALL}")"

assert_output_contains "${LISTING}" "./.agent/" \
    "RL02 antigravity tarball contains .agent/ dir"
assert_output_contains "${LISTING}" "./AGENTS.md" \
    "RL02 antigravity tarball contains root AGENTS.md"
assert_output_not_contains "${LISTING}" "README.md" \
    "RL02 antigravity tarball has no README.md"
assert_output_not_contains "${LISTING}" "emission-manifest.jsonl" \
    "RL02 antigravity tarball has no emission-manifest.jsonl"
assert_output_not_contains "${LISTING}" "aid-antigravity/" \
    "RL03 antigravity tarball has no wrapping aid-antigravity/ prefix"

# ---------------------------------------------------------------------------
# RL04: SHA256SUMS format
#   - File exists
#   - Exactly 7 lines (5 tarballs + 2 lib files: aid-install-core.sh + AidInstallCore.psm1)
#   - Each line matches <64-hex>  <filename> (two spaces)
#   - Filenames are bare (no path prefix)
#   - No self-reference (SHA256SUMS itself) and no sig line
#   - Lines are sorted by filename (second field)
#   - sha256sum -c passes in the staging dir
# ---------------------------------------------------------------------------
SUMS_FILE="${STAGE_DIR}/SHA256SUMS"
assert_file_exists "${SUMS_FILE}" "RL04 SHA256SUMS file exists"
assert_line_count "${SUMS_FILE}" 8 "RL04 SHA256SUMS has exactly 8 lines (5 profile tarballs + 1 CLI bundle + 2 libs)"

# Validate each line matches the two-space format: <64-hex>  <filename>
LINE_CHECK_PASS=1
while IFS= read -r line; do
    if ! echo "${line}" | grep -qE '^[0-9a-f]{64}  [^ ]+$'; then
        LINE_CHECK_PASS=0
        break
    fi
done < "${SUMS_FILE}"
if [[ "$LINE_CHECK_PASS" -eq 1 ]]; then
    pass "RL04 all SHA256SUMS lines match <64-hex>  <filename> format"
else
    fail "RL04 SHA256SUMS line format — at least one line does not match '<64-hex>  <filename>'"
fi

# Lib files must be present in SHA256SUMS.
assert_file_contains "${SUMS_FILE}" "aid-install-core.sh" \
    "RL04 SHA256SUMS contains aid-install-core.sh entry"
assert_file_contains "${SUMS_FILE}" "AidInstallCore.psm1" \
    "RL04 SHA256SUMS contains AidInstallCore.psm1 entry"

# No self-reference and no sig line
assert_file_not_contains "${SUMS_FILE}" "SHA256SUMS" \
    "RL04 SHA256SUMS has no self-reference line"

# Lines must be sorted by filename (second field = tarball name).
SORTED_CHECK=$(awk '{print $2}' "${SUMS_FILE}" | sort -c 2>&1); SC_RC=$?
if [[ $SC_RC -eq 0 ]]; then
    pass "RL04 SHA256SUMS lines are sorted by filename"
else
    fail "RL04 SHA256SUMS lines are not sorted by filename: ${SORTED_CHECK}"
fi

# sha256sum -c verification (in staging dir).
VERIFY_OUT=$(cd "${STAGE_DIR}" && sha256sum -c SHA256SUMS 2>&1); VRC=$?
assert_exit_zero "$VRC" "RL04 sha256sum -c SHA256SUMS passes in staging dir"

# ---------------------------------------------------------------------------
# RL05: Checksum correctness — hex in SHA256SUMS matches independently computed sha256
# ---------------------------------------------------------------------------
for tool in "${TOOLS[@]}"; do
    tarball="${STAGE_DIR}/aid-${tool}-v${STAGE_VERSION}.tar.gz"
    # Independently compute the sha256 of the tarball.
    INDEP_HEX=$(sha256sum "${tarball}" | awk '{print $1}')
    # Look up the hex recorded in SHA256SUMS for this filename.
    FNAME="aid-${tool}-v${STAGE_VERSION}.tar.gz"
    RECORDED_HEX=$(grep " ${FNAME}$" "${SUMS_FILE}" | awk '{print $1}')
    assert_eq "${INDEP_HEX}" "${RECORDED_HEX}" \
        "RL05 checksum correctness for aid-${tool}-v${STAGE_VERSION}.tar.gz"
done

# CLI bundle checksum correctness.
_cli_tarball="${STAGE_DIR}/aid-cli-v${STAGE_VERSION}.tar.gz"
_cli_indep_hex=$(sha256sum "${_cli_tarball}" | awk '{print $1}')
_cli_fname="aid-cli-v${STAGE_VERSION}.tar.gz"
_cli_recorded_hex=$(grep " ${_cli_fname}$" "${SUMS_FILE}" | awk '{print $1}')
assert_eq "${_cli_indep_hex}" "${_cli_recorded_hex}" \
    "RL05 checksum correctness for aid-cli-v${STAGE_VERSION}.tar.gz (CLI bundle)"

# CLI bundle layout: must contain bin/aid, bin/aid.ps1, bin/aid.cmd, lib/aid-install-core.sh,
# lib/AidInstallCore.psm1, VERSION.
CLI_LISTING="$(tar -tzf "${_cli_tarball}")"
assert_output_contains "${CLI_LISTING}" "./bin/aid"                    "RL05b CLI bundle contains ./bin/aid"
assert_output_contains "${CLI_LISTING}" "./bin/aid.ps1"                "RL05c CLI bundle contains ./bin/aid.ps1"
assert_output_contains "${CLI_LISTING}" "./bin/aid.cmd"                "RL05d CLI bundle contains ./bin/aid.cmd"
assert_output_contains "${CLI_LISTING}" "./lib/aid-install-core.sh"    "RL05e CLI bundle contains ./lib/aid-install-core.sh"
assert_output_contains "${CLI_LISTING}" "./lib/AidInstallCore.psm1"    "RL05f CLI bundle contains ./lib/AidInstallCore.psm1"
assert_output_contains "${CLI_LISTING}" "./VERSION"                    "RL05g CLI bundle contains ./VERSION"

# Also verify lib files' checksums.
for libname in "aid-install-core.sh" "AidInstallCore.psm1"; do
    libfile="${STAGE_DIR}/${libname}"
    assert_file_exists "${libfile}" "RL05b lib file staged: ${libname}"
    INDEP_HEX=$(sha256sum "${libfile}" | awk '{print $1}')
    RECORDED_HEX=$(grep " ${libname}$" "${SUMS_FILE}" | awk '{print $1}')
    assert_eq "${INDEP_HEX}" "${RECORDED_HEX}" \
        "RL05b checksum correctness for ${libname}"
done

# ---------------------------------------------------------------------------
# RL06: Render-drift gate — release.sh fails when profiles/ is out of sync with HEAD.
#
# Approach:
#   1. Create a second clean clone and inject release.sh.
#   2. Dirty a profiles/ file and commit it (so HEAD has the contaminated file).
#   3. Run release.sh --dry-run: the generator regenerates clean profiles/, then
#      git diff --exit-code -- profiles/ detects the committed dirt → exits non-zero.
#   4. Assert staging dir has no tarballs / exit is non-zero.
# ---------------------------------------------------------------------------
CLONE2="${TMP}/clone-drift"
make_clone "${CLONE2}"

# Dirty a GENERATED profiles/ file and commit it.
# We must dirty a file that the generator actually regenerates from canonical/,
# not a hand-authored root file like CLAUDE.md or AGENTS.md (those are not
# in the emission manifest and the generator does not overwrite them).
# Derive the target dynamically from the live emission manifest (resilient to
# canonical renames — e.g. master's aid-* agent prefix refactor) by taking the
# first generated *.md dst under the claude-code profile.
DRIFT_REL="$(python3 -c "
import json,sys
for line in open('${CLONE2}/profiles/claude-code/emission-manifest.jsonl'):
    line=line.strip()
    if not line or line.startswith('{\"_'): continue
    try: r=json.loads(line)
    except Exception: continue
    d=r.get('dst','')
    if d.endswith('.md'): print(d); break
")"
if [ -z "${DRIFT_REL}" ]; then
    echo "SKIP: could not derive a generated .md from emission manifest" >&2
fi
DRIFT_FILE="${CLONE2}/profiles/claude-code/${DRIFT_REL}"
printf '\n<!-- DRIFT TEST LINE -->\n' >> "${DRIFT_FILE}"
git -C "${CLONE2}" add "${DRIFT_FILE}"
git -C "${CLONE2}" commit --quiet -m "test: dirty profiles for render-drift gate test"

# Run release.sh --dry-run in the drifted clone.
DRIFT_STAGE_VERSION="$(tr -d '[:space:]' < "${CLONE2}/VERSION")"
DRIFT_STAGE="${CLONE2}/.aid/.temp/release-${DRIFT_STAGE_VERSION}"

DRIFT_OUT=$(cd "${CLONE2}" && bash ./release.sh --dry-run 2>&1); DRIFT_RC=$?
assert_exit_nonzero "${DRIFT_RC}" "RL06 render-drift gate fails on dirtied profiles/ (exit non-zero)"
assert_output_contains "${DRIFT_OUT}" "out of sync" \
    "RL06 render-drift error mentions 'out of sync'"

# Staging dir must not contain tarballs (gate fired before packaging).
DRIFT_TARBALL_COUNT=$(ls "${DRIFT_STAGE}"/aid-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
assert_eq "${DRIFT_TARBALL_COUNT}" "0" \
    "RL06 staging dir has no tarballs when render-drift gate fires"

test_summary
