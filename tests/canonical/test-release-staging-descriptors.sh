#!/usr/bin/env bash
# Focused preflight regressions for release descriptor parsing.
# Usage: bash tests/canonical/test-release-staging-descriptors.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u
VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/bundle.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
STAGE="${TMP}/stage"
OUT="$(aid_test_stage_bundle "$STAGE" 2>&1)"; RC=$?
assert_exit_zero "$RC" "RSD01 stage release fixture"

rewrite_descriptor() {
    local bundle="$1" kind="$2" contents="$3" tool="${4:-cursor}"
    local artifact member extract list rebuilt digest sums_tmp
    if [[ "$kind" == shared ]]; then
        artifact="${bundle}/aid-shared-v${VERSION}.tar.gz"; member=aid-payload.conf
    else
        artifact="${bundle}/aid-${tool}-v${VERSION}.tar.gz"; member=aid-tool.conf
    fi
    extract="${TMP}/extract-${kind}-${tool}-$(basename "$bundle")"
    mkdir -p "$extract"
    tar -xzf "$artifact" -C "$extract"
    printf '%s' "$contents" > "${extract}/${member}"
    list="${TMP}/members-${kind}-${tool}-$(basename "$bundle")"
    tar -tzf "$artifact" > "$list"
    rebuilt="${artifact}.new"
    tar --hard-dereference -czf "$rebuilt" -C "$extract" -T "$list"
    mv "$rebuilt" "$artifact"
    digest="$(sha256sum "$artifact" | awk '{print $1}')"
    sums_tmp="${bundle}/SHA256SUMS.new"
    awk -v name="$(basename "$artifact")" -v hash="$digest" '$2 == name {$1 = hash} {print}' \
        "${bundle}/SHA256SUMS" > "$sums_tmp"
    mv "$sums_tmp" "${bundle}/SHA256SUMS"
}

snapshot() {
    find "$1" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
}

run_refusal() {
    local id="$1" bundle="$2" file="$3" diagnostic="$4"
    local target="${TMP}/target-${id}" home="${TMP}/home-${id}" before after output rc
    mkdir -p "$target" "$home"
    git -C "$target" init -q
    before="$(snapshot "$target")"
    output="$(AID_HOME="$home" AID_NO_UPDATE_CHECK=1 TMPDIR="$TMP" \
        bash "${REPO_ROOT}/bin/aid" add cursor --from-bundle "$bundle" --target "$target" 2>&1)"
    rc=$?
    after="$(snapshot "$target")"
    assert_exit_eq "$rc" 1 "${id} invalid descriptor refuses staging"
    assert_output_contains "$output" "$file" "${id} diagnostic names descriptor file"
    assert_output_contains "$output" "$diagnostic" "${id} diagnostic names invalid bytes or key"
    assert_eq "$after" "$before" "${id} refusal leaves target tree unchanged"
}

# CRLF makes read_kv_conf fail before it can return keys. Its failure must reach
# validate_release_descriptor, even when a raw grep would still see the key.
CRLF_SHARED="${TMP}/crlf-shared"
cp -a "${STAGE}/." "$CRLF_SHARED"; rewrite_descriptor "$CRLF_SHARED" shared $'aid_version=9.9.9\r\n'
run_refusal RSD02 "$CRLF_SHARED" aid-payload.conf 'ASCII with LF line endings only'

CRLF_TOOL="${TMP}/crlf-tool"
cp -a "${STAGE}/." "$CRLF_TOOL"; rewrite_descriptor "$CRLF_TOOL" tool $'tool=cursor\r\nskill_mirror=.agents/skills\r\n'
run_refusal RSD03 "$CRLF_TOOL" aid-tool.conf 'ASCII with LF line endings only'

BAD_VERSION="${TMP}/bad-version"
cp -a "${STAGE}/." "$BAD_VERSION"; rewrite_descriptor "$BAD_VERSION" shared $'aid_version=9.9.9\n'
run_refusal RSD04 "$BAD_VERSION" aid-payload.conf aid_version

BAD_MIRROR="${TMP}/bad-mirror"
cp -a "${STAGE}/." "$BAD_MIRROR"; rewrite_descriptor "$BAD_MIRROR" tool $'tool=cursor\nskill_mirror=.agents/skills\n'
run_refusal RSD05 "$BAD_MIRROR" aid-tool.conf skill_mirror

NONASCII_TOOL="${TMP}/nonascii-tool"
cp -a "${STAGE}/." "$NONASCII_TOOL"
rewrite_descriptor "$NONASCII_TOOL" tool "$(printf 'tool=cursor\n# invalid byte: \303\251\nskill_mirror=.agents/skills\n')"
run_refusal RSD06 "$NONASCII_TOOL" aid-tool.conf 'ASCII with LF line endings only'

# Empty reader output still produces a blank here-string record. Both empty and
# comment-only descriptors must reach the required-key diagnostic safely.
EMPTY_SHARED="${TMP}/empty-shared"
cp -a "${STAGE}/." "$EMPTY_SHARED"; rewrite_descriptor "$EMPTY_SHARED" shared ''
run_refusal RSD07 "$EMPTY_SHARED" aid-payload.conf 'missing aid_version'

COMMENT_SHARED="${TMP}/comment-shared"
cp -a "${STAGE}/." "$COMMENT_SHARED"; rewrite_descriptor "$COMMENT_SHARED" shared $'# no descriptor entries\n'
run_refusal RSD08 "$COMMENT_SHARED" aid-payload.conf 'missing aid_version'

EMPTY_TOOL="${TMP}/empty-tool"
cp -a "${STAGE}/." "$EMPTY_TOOL"; rewrite_descriptor "$EMPTY_TOOL" tool ''
run_refusal RSD09 "$EMPTY_TOOL" aid-tool.conf 'missing tool'

COMMENT_TOOL="${TMP}/comment-tool"
cp -a "${STAGE}/." "$COMMENT_TOOL"; rewrite_descriptor "$COMMENT_TOOL" tool $'# no descriptor entries\n'
run_refusal RSD10 "$COMMENT_TOOL" aid-tool.conf 'missing tool'

# Host hook keys (hook_settings, hook): a descriptor that declares them is accepted and the
# installer places the hook; malformed or misplaced ones are refused before anything is written.
HOOK_OK="${TMP}/hook-ok"
cp -a "${STAGE}/." "$HOOK_OK"
rewrite_descriptor "$HOOK_OK" tool $'tool=claude-code\nskill_mirror=.claude/skills\nhook_settings=.claude/settings.json\nhook=Stop:aid-question-form\nhook=Stop:aid-other-check\n' claude-code
HOOK_TARGET="${TMP}/target-RSD11"; mkdir -p "$HOOK_TARGET"; git -C "$HOOK_TARGET" init -q
HOOK_OUT="$(AID_HOME="${TMP}/home-RSD11" AID_NO_UPDATE_CHECK=1 TMPDIR="$TMP" \
    bash "${REPO_ROOT}/bin/aid" add claude-code --from-bundle "$HOOK_OK" --target "$HOOK_TARGET" 2>&1)"; HOOK_RC=$?
assert_exit_zero "$HOOK_RC" "RSD11 descriptor with hook keys is accepted"
assert_output_contains "$HOOK_OUT" "Hook: aid-question-form (Stop) in .claude/settings.json" "RSD11 install reports the first hook"
assert_output_contains "$HOOK_OUT" "Hook: aid-other-check (Stop) in .claude/settings.json" "RSD11 install reports every declared hook"
assert_eq "$(grep -c 'aid/runtime/scripts/hooks/aid-' "${HOOK_TARGET}/.claude/settings.json")" 2 "RSD11 both handlers are in the settings file"

BAD_HOOK_SETTINGS="${TMP}/bad-hook-settings"
cp -a "${STAGE}/." "$BAD_HOOK_SETTINGS"; rewrite_descriptor "$BAD_HOOK_SETTINGS" tool $'tool=cursor\nhook_settings=.cursor/other.json\nhook=Stop:aid-question-form\n'
run_refusal RSD12 "$BAD_HOOK_SETTINGS" aid-tool.conf hook_settings

WRONG_ROOT_SETTINGS="${TMP}/wrong-root-settings"
cp -a "${STAGE}/." "$WRONG_ROOT_SETTINGS"; rewrite_descriptor "$WRONG_ROOT_SETTINGS" tool $'tool=cursor\nhook_settings=.claude/settings.json\nhook=Stop:aid-question-form\n'
run_refusal RSD13 "$WRONG_ROOT_SETTINGS" aid-tool.conf hook_settings

DUP_HOOK_SETTINGS="${TMP}/dup-hook-settings"
cp -a "${STAGE}/." "$DUP_HOOK_SETTINGS"; rewrite_descriptor "$DUP_HOOK_SETTINGS" tool $'tool=cursor\nhook_settings=.cursor/settings.json\nhook_settings=.cursor/settings.json\nhook=Stop:aid-question-form\n'
run_refusal RSD14 "$DUP_HOOK_SETTINGS" aid-tool.conf 'hook_settings may appear only once'

BAD_HOOK_NAME="${TMP}/bad-hook-name"
cp -a "${STAGE}/." "$BAD_HOOK_NAME"; rewrite_descriptor "$BAD_HOOK_NAME" tool $'tool=cursor\nhook_settings=.cursor/settings.json\nhook=Stop:question-form\n'
run_refusal RSD15 "$BAD_HOOK_NAME" aid-tool.conf "invalid hook 'Stop:question-form'"

BAD_HOOK_EVENT="${TMP}/bad-hook-event"
cp -a "${STAGE}/." "$BAD_HOOK_EVENT"; rewrite_descriptor "$BAD_HOOK_EVENT" tool $'tool=cursor\nhook_settings=.cursor/settings.json\nhook=Start:aid-question-form\n'
run_refusal RSD16 "$BAD_HOOK_EVENT" aid-tool.conf "invalid hook 'Start:aid-question-form'"

BAD_HOOK_PATH="${TMP}/bad-hook-path"
cp -a "${STAGE}/." "$BAD_HOOK_PATH"; rewrite_descriptor "$BAD_HOOK_PATH" tool $'tool=cursor\nhook_settings=.cursor/settings.json\nhook=Stop:aid-../x\n'
run_refusal RSD17 "$BAD_HOOK_PATH" aid-tool.conf "invalid hook"

ORPHAN_HOOK="${TMP}/orphan-hook"
cp -a "${STAGE}/." "$ORPHAN_HOOK"; rewrite_descriptor "$ORPHAN_HOOK" tool $'tool=cursor\nhook=Stop:aid-question-form\n'
run_refusal RSD18 "$ORPHAN_HOOK" aid-tool.conf 'hook needs hook_settings'

test_summary
