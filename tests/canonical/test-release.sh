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
assert_file_exists "${SUMS}" "RL04 SHA256SUMS file exists"
assert_line_count "${SUMS}" 9 "RL04 SHA256SUMS contains seven tarballs and two libraries"
FORMAT_OK=1
while IFS= read -r line; do
    if ! [[ "$line" =~ ^[0-9a-f]{64}\ \ [^[:space:]]+$ ]]; then FORMAT_OK=0; break; fi
done < "${SUMS}"
assert_eq "$FORMAT_OK" "1" "RL04 SHA256SUMS lines retain the two-space digest format"
assert_file_contains "${SUMS}" "aid-install-core.sh" "RL04 SHA256SUMS includes Bash library"
assert_file_contains "${SUMS}" "AidInstallCore.psm1" "RL04 SHA256SUMS includes PowerShell library"
assert_file_not_contains "${SUMS}" "SHA256SUMS" "RL04 SHA256SUMS does not hash itself"
SORT_STATUS=0
awk '{print $2}' "${SUMS}" | sort -c >/dev/null 2>&1 || SORT_STATUS=$?
assert_eq "$SORT_STATUS" "0" "RL04 SHA256SUMS entries are sorted by filename"
VERIFY=$(cd "${STAGE}" && sha256sum -c SHA256SUMS 2>&1); VERIFY_RC=$?
assert_exit_zero "$VERIFY_RC" "RL04 sha256sum -c passes for every staged artifact"

# RL05: the unchanged CLI bundle and library assets remain staged.
CLI="${STAGE}/aid-cli-v${VERSION}.tar.gz"
CLI_LIST="$(tar -tzf "${CLI}")"
for artifact in "${STAGE}"/aid-*.tar.gz; do
    name="$(basename "$artifact")"
    recorded="$(awk -v name="$name" '$2 == name {print $1}' "${SUMS}")"
    actual="$(sha256sum "$artifact" | awk '{print $1}')"
    assert_eq "$recorded" "$actual" "RL05 checksum matches for ${name}"
done
assert_output_contains "$CLI_LIST" "./bin/aid" "RL05b CLI bundle contains ./bin/aid"
assert_output_contains "$CLI_LIST" "./bin/aid.ps1" "RL05c CLI bundle contains ./bin/aid.ps1"
assert_output_contains "$CLI_LIST" "./bin/aid.cmd" "RL05d CLI bundle contains ./bin/aid.cmd"
assert_output_contains "$CLI_LIST" "./lib/aid-install-core.sh" "RL05e CLI bundle contains Bash library"
assert_output_contains "$CLI_LIST" "./lib/AidInstallCore.psm1" "RL05f CLI bundle contains PowerShell library"
assert_output_contains "$CLI_LIST" "./VERSION" "RL05g CLI bundle contains VERSION"
for libname in aid-install-core.sh AidInstallCore.psm1; do
    libfile="${STAGE}/${libname}"
    assert_file_exists "${libfile}" "RL05b staged installer library exists: ${libname}"
    actual="$(sha256sum "${libfile}" | awk '{print $1}')"
    recorded="$(awk -v name="${libname}" '$2 == name {print $1}' "${SUMS}")"
    assert_eq "$recorded" "$actual" "RL05b installer library checksum matches: ${libname}"
done
assert_file_contains "${STAGE}/release-notes-stub.md" "v4 requires CLI v4" \
    "RL10a staged release notes state v4 requires CLI v4"

# RL06: render drift is rejected after regeneration, even when the mismatched
#       generated profile change is committed.
DRIFT_CLONE="${TMP}/clone-render-drift"
git clone --no-hardlinks --quiet "${REPO_ROOT}" "${DRIFT_CLONE}"
cp "${SUT}" "${DRIFT_CLONE}/release.sh"
git -C "${DRIFT_CLONE}" update-index --assume-unchanged release.sh
git -C "${DRIFT_CLONE}" config user.email "test@example.com"
git -C "${DRIFT_CLONE}" config user.name "Test"
DRIFT_FILE="${DRIFT_CLONE}/profiles/claude-code/.claude/agents/aid-reviewer.md"
printf '\n<!-- committed render drift probe -->\n' >> "${DRIFT_FILE}"
git -C "${DRIFT_CLONE}" add "${DRIFT_FILE}"
git -C "${DRIFT_CLONE}" commit --quiet -m "test: introduce generated render drift"
OUT=$(cd "${DRIFT_CLONE}" && bash ./release.sh --dry-run 2>&1); RC=$?
assert_exit_nonzero "$RC" "RL06 --dry-run rejects committed generated-profile drift"
assert_output_contains "$OUT" "out of sync" "RL06 render-drift failure explains profile mismatch"
DRIFT_VERSION="$(tr -d '[:space:]' < "${DRIFT_CLONE}/VERSION")"
DRIFT_STAGE="${DRIFT_CLONE}/.aid/.temp/release-${DRIFT_VERSION}"
DRIFT_TARBALL_COUNT=$(find "${DRIFT_STAGE}" -maxdepth 1 -type f -name 'aid-*.tar.gz' 2>/dev/null | wc -l | tr -d ' ')
assert_eq "$DRIFT_TARBALL_COUNT" "0" "RL06 render-drift rejection occurs before packaging"

# RL06a: ordinary dry-run still enforces the clean-worktree precondition.
DRY_CLONE="${TMP}/clone-dry-run"
git clone --no-hardlinks --quiet "${REPO_ROOT}" "${DRY_CLONE}"
cp "${SUT}" "${DRY_CLONE}/release.sh"
printf '%s\n' '<!-- dirty precondition probe -->' >> "${DRY_CLONE}/README.md"
OUT=$(cd "${DRY_CLONE}" && bash ./release.sh --dry-run 2>&1); RC=$?
assert_exit_nonzero "$RC" "RL06a --dry-run still rejects this dirty worktree"
assert_output_contains "$OUT" "uncommitted changes" "RL06a dry-run explains its clean-tree precondition"

# RL07: explicit version mismatch remains a usage precondition.
OUT=$(cd "${REPO_ROOT}" && bash ./release.sh --version 9.9.9 --dry-run 2>&1); RC=$?
assert_exit_eq "$RC" 3 "RL07 mismatched --version exits 3"
assert_output_contains "$OUT" "9.9.9" "RL07 mismatch reports passed version"
assert_output_contains "$OUT" "${VERSION}" "RL07 mismatch reports VERSION-file value"

# RL08: help continues to document existing behavior and describes the new
#       shared payload and stage-only mode.
OUT=$(bash "${SUT}" --help 2>&1); RC=$?
assert_exit_zero "$RC" "RL08a --help exits 0"
assert_output_contains "$OUT" "dry-run" "RL08a help mentions dry-run"
assert_output_contains "$OUT" "version X.Y.Z" "RL08a help mentions version X.Y.Z"
assert_output_contains "$OUT" "No network I/O" "RL08a help describes dry-run network behavior"
assert_output_contains "$OUT" "--stage-only" "RL08a help describes stage-only"
assert_output_contains "$OUT" "shared payload" "RL08a help describes shared payload"

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

# RL11: Step 2b runs the three release checks with AID_RELEASE_CHECK=1 before
#       staging, in live publish mode only; a failing check stops the release
#       before anything is staged. Stub suites and a gh shim keep it offline.
GATE_LOG="${TMP}/gate-check.log"
GATE_FAIL="${TMP}/gate-fail-guide"
GATE_BIN="${TMP}/gate-bin"
GATE_CLONE="${TMP}/clone-release-gate"
GATE_EXPECTED="$(printf '%s\n' \
    'test-deferred-tests AID_RELEASE_CHECK=1' \
    'test-skill-steps AID_RELEASE_CHECK=1' \
    'test-skill-guide AID_RELEASE_CHECK=1')"
mkdir -p "${GATE_BIN}"
printf '#!/usr/bin/env bash\nexit 1\n' > "${GATE_BIN}/gh"
chmod +x "${GATE_BIN}/gh"
git clone --no-hardlinks --quiet "${REPO_ROOT}" "${GATE_CLONE}"
cp "${SUT}" "${GATE_CLONE}/release.sh"
for _gate_suite in test-deferred-tests test-skill-steps test-skill-guide; do
    cat > "${GATE_CLONE}/tests/canonical/${_gate_suite}.sh" <<EOF
#!/usr/bin/env bash
echo "${_gate_suite} AID_RELEASE_CHECK=\${AID_RELEASE_CHECK:-unset}" >> "${GATE_LOG}"
if [[ "${_gate_suite}" == "test-skill-guide" && -e "${GATE_FAIL}" ]]; then exit 1; fi
exit 0
EOF
done
git -C "${GATE_CLONE}" config user.email "test@example.com"
git -C "${GATE_CLONE}" config user.name "Test"
git -C "${GATE_CLONE}" add release.sh tests/canonical/test-deferred-tests.sh \
    tests/canonical/test-skill-steps.sh tests/canonical/test-skill-guide.sh
git -C "${GATE_CLONE}" commit --quiet -m "test: stub release check suites"
GATE_VERSION="$(tr -d '[:space:]' < "${GATE_CLONE}/VERSION")"
git -C "${GATE_CLONE}" tag -d "v${GATE_VERSION}" >/dev/null 2>&1 || true
GATE_STAGE_DIR="${GATE_CLONE}/.aid/.temp/release-${GATE_VERSION}"
# Run_generator.py rewrites tracked dogfood trees, so each run starts from a clean HEAD.
_gate_reset() {
    git -C "${GATE_CLONE}" checkout -q -- .
    git -C "${GATE_CLONE}" clean -qfdx
}

# RL11a: live publish runs the three checks in order with AID_RELEASE_CHECK=1.
_gate_reset; : > "${GATE_LOG}"; rm -f "${GATE_FAIL}"
OUT=$(cd "${GATE_CLONE}" && PATH="${GATE_BIN}:${PATH}" bash ./release.sh 2>&1); RC=$?
assert_output_contains "$OUT" "release checks passed" "RL11a live publish reports the release checks passed"
assert_eq "$(cat "${GATE_LOG}")" "${GATE_EXPECTED}" \
    "RL11a live publish runs the three release checks in order with AID_RELEASE_CHECK=1"

# RL11b: a failing release check stops the live publish before staging.
_gate_reset; : > "${GATE_LOG}"; touch "${GATE_FAIL}"; rm -rf "${GATE_STAGE_DIR}"
OUT=$(cd "${GATE_CLONE}" && PATH="${GATE_BIN}:${PATH}" bash ./release.sh 2>&1); RC=$?
assert_output_contains "$OUT" "release check test-skill-guide failed; nothing was staged" \
    "RL11b live publish names the failed release check"
STAGED_COUNT=$(find "${GATE_STAGE_DIR}" -maxdepth 1 -type f -name 'aid-*.tar.gz' 2>/dev/null | wc -l | tr -d ' ')
assert_eq "$STAGED_COUNT" "0" "RL11b failed release check leaves no artifact staged"

# RL11c: --dry-run skips the release checks.
_gate_reset; : > "${GATE_LOG}"; touch "${GATE_FAIL}"; rm -rf "${GATE_STAGE_DIR}"
OUT=$(cd "${GATE_CLONE}" && PATH="${GATE_BIN}:${PATH}" bash ./release.sh --dry-run 2>&1); RC=$?
assert_exit_zero "$RC" "RL11c --dry-run completes although a release check would fail"
assert_eq "$(cat "${GATE_LOG}")" "" "RL11c --dry-run runs no release check"

# RL11d: --stage-only skips the release checks.
_gate_reset; : > "${GATE_LOG}"; touch "${GATE_FAIL}"
GATE_STAGE_ONLY_DIR="${TMP}/gate-stage-only"
OUT=$(cd "${GATE_CLONE}" && PATH="${GATE_BIN}:${PATH}" bash ./release.sh --stage-only --out "${GATE_STAGE_ONLY_DIR}" 2>&1); RC=$?
assert_exit_zero "$RC" "RL11d --stage-only completes although a release check would fail"
assert_eq "$(cat "${GATE_LOG}")" "" "RL11d --stage-only runs no release check"

# Unknown flag remains exit 2.
OUT=$(bash "${SUT}" --unknown-flag-xyz 2>&1); RC=$?
assert_exit_eq "$RC" 2 "RL08b unknown flag exits 2"
assert_output_contains "$OUT" "unknown flag" "RL08b error identifies the unknown flag"

test_summary
