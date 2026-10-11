#!/usr/bin/env bash
# test-release.sh — focused checks for release artifact staging.
#
# Purpose: Verify the shared payload, tool artifacts, checksums, and stage-only mode.
# Usage: bash tests/canonical/test-release.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/bundle.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/release.sh"
TMP="$(mktemp -d)"
_cleanup() { rm -rf "${TMP}"; }
trap _cleanup EXIT

VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
STAGE="${TMP}/stage"
OUT=$(aid_test_stage_bundle "${STAGE}" 2>&1); RC=$?
assert_exit_zero "$RC" "RL01 --stage-only stages artifacts from a dirty working tree"

TOOLS=(claude-code codex cursor copilot-cli antigravity)
EXPECTED=("aid-cli-v${VERSION}.tar.gz" "aid-shared-v${VERSION}.tar.gz")
for tool in "${TOOLS[@]}"; do EXPECTED+=("aid-${tool}-v${VERSION}.tar.gz"); done
ACTUAL=()
for artifact in "${STAGE}"/aid-*.tar.gz; do ACTUAL+=("$(basename "$artifact")"); done
IFS=$'\n' ACTUAL_SORTED=( $(printf '%s\n' "${ACTUAL[@]}" | sort) )
EXPECTED_SORTED=( $(printf '%s\n' "${EXPECTED[@]}" | sort) )
assert_eq "${ACTUAL_SORTED[*]}" "${EXPECTED_SORTED[*]}" \
    "RL01 exact artifact set: shared, five tools, and CLI"

# RL02: the shared tarball is a byte-verbatim canonical payload at archive root.
SHARED="${STAGE}/aid-shared-v${VERSION}.tar.gz"
SHARED_LIST="$(tar -tzf "${SHARED}")"
if printf '%s\n' "${SHARED_LIST}" | grep -q '^\./'; then
    fail "RL02 shared artifact has no leading ./ members"
else
    pass "RL02 shared artifact has no leading ./ members"
fi
assert_output_not_contains "${SHARED_LIST}" "AGENTS.md" "RL02 shared payload contains no AGENTS.md"
mkdir -p "${TMP}/extract-shared"
tar -xzf "${SHARED}" -C "${TMP}/extract-shared"
assert_eq "$(cat "${TMP}/extract-shared/aid-payload.conf")" "aid_version=${VERSION}" \
    "RL02 payload descriptor has only the current aid_version"
DIFF_OUT=$(diff -r -x node_modules -x '.*' "${TMP}/extract-shared/skills" "${REPO_ROOT}/canonical/skills" 2>&1); DIFF_RC=$?
assert_exit_zero "$DIFF_RC" "RL02 staged skills match canonical skills with declared exclusions"
DIFF_OUT=$(diff -r -x node_modules -x '.*' "${TMP}/extract-shared/runtime" "${REPO_ROOT}/canonical/aid" 2>&1); DIFF_RC=$?
assert_exit_zero "$DIFF_RC" "RL02 staged runtime matches canonical/aid with declared exclusions"
assert_exit_zero "$(cmp -s "${TMP}/extract-shared/runtime/rules.md" "${REPO_ROOT}/canonical/aid/rules.md"; echo $?)" \
    "RL02 runtime/rules.md matches byte-for-byte"

# RL03: every tool artifact contains only its descriptor and its agents tree.
ROOTS=(.claude .codex .cursor .github .agent)
for i in "${!TOOLS[@]}"; do
    tool="${TOOLS[$i]}"
    artifact="${STAGE}/aid-${tool}-v${VERSION}.tar.gz"
    listing="$(tar -tzf "${artifact}")"
    if printf '%s\n' "${listing}" | grep -q '^\./'; then
        fail "RL03 ${tool} artifact has no leading ./ members"
    else
        pass "RL03 ${tool} artifact has no leading ./ members"
    fi
    assert_output_contains "${listing}" "aid-tool.conf" "RL03 ${tool} artifact contains descriptor"
    if printf '%s\n' "${listing}" | grep -vE "^(aid-tool\.conf|${ROOTS[$i]}/agents(/.*)?)$" | grep -q .; then
        fail "RL03 ${tool} artifact contains only descriptor and ${ROOTS[$i]}/agents"
    else
        pass "RL03 ${tool} artifact contains only descriptor and ${ROOTS[$i]}/agents"
    fi
    if printf '%s\n' "${listing}" | grep -qE '(^|/)skills/|/aid/'; then
        fail "RL03 ${tool} artifact has no shared skills or runtime paths"
    else
        pass "RL03 ${tool} artifact has no shared skills or runtime paths"
    fi
done

# RL04: SHA256SUMS covers all seven artifacts and both libraries.
SUMS="${STAGE}/SHA256SUMS"
assert_line_count "${SUMS}" 9 "RL04 SHA256SUMS contains seven tarballs and two libraries"
VERIFY=$(cd "${STAGE}" && sha256sum -c SHA256SUMS 2>&1); VERIFY_RC=$?
assert_exit_zero "$VERIFY_RC" "RL04 sha256sum -c passes for every staged artifact"

# RL05: the unchanged CLI bundle and library assets remain staged.
CLI="${STAGE}/aid-cli-v${VERSION}.tar.gz"
CLI_LIST="$(tar -tzf "${CLI}")"
assert_output_contains "${CLI_LIST}" "./bin/aid" "RL05 CLI bundle retains its existing member layout"
assert_file_exists "${STAGE}/aid-install-core.sh" "RL05b Bash installer library remains staged"
assert_file_exists "${STAGE}/AidInstallCore.psm1" "RL05c PowerShell installer library remains staged"
assert_file_contains "${SUMS}" "aid-cli-v${VERSION}.tar.gz" "RL05d SHA256SUMS includes CLI bundle"
assert_file_contains "${SUMS}" "aid-install-core.sh" "RL05e SHA256SUMS includes Bash library"
assert_file_contains "${SUMS}" "AidInstallCore.psm1" "RL05f SHA256SUMS includes PowerShell library"
assert_file_contains "${STAGE}/release-notes-stub.md" "v4 requires CLI v4" \
    "RL05g staged release notes state v4 requires CLI v4"

# RL06: ordinary dry-run still enforces the clean-worktree precondition.
DRY_CLONE="${TMP}/clone-dry-run"
git clone --no-hardlinks --quiet "${REPO_ROOT}" "${DRY_CLONE}"
cp "${SUT}" "${DRY_CLONE}/release.sh"
printf '%s\n' '<!-- dirty precondition probe -->' >> "${DRY_CLONE}/README.md"
OUT=$(cd "${DRY_CLONE}" && bash ./release.sh --dry-run 2>&1); RC=$?
assert_exit_nonzero "$RC" "RL06 --dry-run still rejects this dirty worktree"
assert_output_contains "$OUT" "uncommitted changes" "RL06 dry-run explains its clean-tree precondition"

# RL07: explicit version mismatch remains a usage precondition.
OUT=$(cd "${REPO_ROOT}" && bash ./release.sh --version 9.9.9 --stage-only --out "${TMP}/bad" 2>&1); RC=$?
assert_exit_eq "$RC" 3 "RL07 mismatched --version exits 3"
assert_output_contains "$OUT" "${VERSION}" "RL07 mismatch reports VERSION-file value"

# RL08: help describes both staging modes and artifact set.
OUT=$(bash "${SUT}" --help 2>&1); RC=$?
assert_exit_zero "$RC" "RL08a --help exits 0"
assert_output_contains "$OUT" "--stage-only" "RL08 help describes stage-only"
assert_output_contains "$OUT" "shared payload" "RL08 help describes shared payload"

# RL09: stage-only includes uncommitted canonical files, omits excluded paths,
#       and ignores a conflicting local tag.
CLONE="${TMP}/clone-stage-only"
git clone --no-hardlinks --quiet "${REPO_ROOT}" "${CLONE}"
mkdir -p "${CLONE}/tests/lib"
cp "${SUT}" "${CLONE}/release.sh"
cp "${REPO_ROOT}/tests/lib/bundle.sh" "${CLONE}/tests/lib/bundle.sh"
PROBE="canonical/skills/aid-discover/references/stage-only-uncommitted.txt"
printf 'included from uncommitted tree\n' > "${CLONE}/${PROBE}"
printf 'excluded hidden file\n' > "${CLONE}/canonical/aid/.stage-only-hidden"
mkdir -p "${CLONE}/canonical/skills/aid-discover/node_modules/stage-only"
printf 'excluded node_modules file\n' > "${CLONE}/canonical/skills/aid-discover/node_modules/stage-only/excluded.txt"
CLONE_VERSION="$(tr -d '[:space:]' < "${CLONE}/VERSION")"
if git -C "${CLONE}" rev-parse -q --verify "HEAD^" >/dev/null 2>&1; then
    git -C "${CLONE}" tag "v${CLONE_VERSION}" HEAD^
fi
CLONE_STAGE="${TMP}/clone-stage-output"
OUT=$(cd "${CLONE}" && bash ./release.sh --stage-only --out "${CLONE_STAGE}" 2>&1); RC=$?
assert_exit_zero "$RC" "RL09 --stage-only succeeds with uncommitted source and a conflicting tag"
assert_file_exists "${CLONE_STAGE}/aid-shared-v${CLONE_VERSION}.tar.gz" \
    "RL09 custom --out receives shared artifact"
tar -xzf "${CLONE_STAGE}/aid-shared-v${CLONE_VERSION}.tar.gz" -C "${TMP}"
assert_file_exists "${TMP}/skills/aid-discover/references/stage-only-uncommitted.txt" \
    "RL09 uncommitted canonical file is included"
if [[ -e "${TMP}/runtime/.stage-only-hidden" ]]; then fail "RL09 dot-files are excluded"; else pass "RL09 dot-files are excluded"; fi
if [[ -e "${TMP}/skills/aid-discover/node_modules/stage-only/excluded.txt" ]]; then
    fail "RL09 node_modules files are excluded"
else
    pass "RL09 node_modules files are excluded"
fi
assert_file_contains "${CLONE_STAGE}/release-notes-stub.md" "v4 requires CLI v4" \
    "RL09 stage-only release notes state v4 requires CLI v4"

# Unknown flag remains exit 2.
OUT=$(bash "${SUT}" --unknown-flag-xyz 2>&1); RC=$?
assert_exit_eq "$RC" 2 "RL08b unknown flag exits 2"

test_summary
