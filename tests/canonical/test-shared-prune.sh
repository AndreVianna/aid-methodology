#!/usr/bin/env bash
# test-shared-prune.sh — focused offline regression for task-010 shared pruning.
# Usage: bash tests/canonical/test-shared-prune.sh
# Exit: 0 when stale shared skills are removed according to the manifest.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"
source "${SCRIPT_DIR}/../lib/bundle.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FULL_BUNDLE="${TMP}/full"
PRUNED_BUNDLE="${TMP}/pruned"
TARGET="${TMP}/target"
HOME_DIR="${TMP}/home"
AID_HOME_DIR="${TMP}/aid-home"
mkdir -p "$FULL_BUNDLE" "$PRUNED_BUNDLE" "$TARGET" "$HOME_DIR" "$AID_HOME_DIR"

assert_file_absent() {
    local file="$1" label="$2"
    if [[ ! -e "$file" ]]; then pass "$label"; else fail "$label — unexpected file remains: $file"; fi
}

aid_test_stage_bundle "$FULL_BUNDLE" >/dev/null || {
    echo "ERROR: could not stage the offline release bundle" >&2
    exit 1
}
cp "$FULL_BUNDLE"/aid-*.tar.gz "$PRUNED_BUNDLE/"

# Omit one previously installed canonical skill from the next same-version
# shared payload. Its old manifest hash should make prune delete the unchanged
# installed copy rather than move it to trash.
SHARED_TARBALL="$(find "$PRUNED_BUNDLE" -maxdepth 1 -name 'aid-shared-v*.tar.gz' -print -quit)"
[[ -n "$SHARED_TARBALL" ]] || { echo "ERROR: staged bundle has no shared payload" >&2; exit 1; }
mkdir -p "${TMP}/payload"
tar -xzf "$SHARED_TARBALL" -C "${TMP}/payload"
KNOWN_OLD="skills/aid-define/SKILL.md"
[[ -f "${TMP}/payload/${KNOWN_OLD}" ]] || { echo "ERROR: expected canonical skill missing from staged payload" >&2; exit 1; }
rm -f "${TMP}/payload/${KNOWN_OLD}"
tar -czf "$SHARED_TARBALL" -C "${TMP}/payload" aid-payload.conf skills runtime
(cd "$PRUNED_BUNDLE" && sha256sum aid-*.tar.gz > SHA256SUMS)

run_aid() {
    HOME="$HOME_DIR" USERPROFILE="$HOME_DIR" AID_HOME="$AID_HOME_DIR" AID_NO_UPDATE_CHECK=1 \
        bash "${REPO_ROOT}/bin/aid" "$@"
}

OUT="$(run_aid add cursor --from-bundle "$FULL_BUNDLE" --target "$TARGET" 2>&1)" || {
    echo "ERROR: initial cursor add failed:" >&2; echo "$OUT" >&2; exit 1;
}
OLD_FILE="${TARGET}/.agents/skills/aid-define/SKILL.md"
assert_file_exists "$OLD_FILE" "Initial install records the canonical skill"
OLD_SHA="$(sha256sum "$OLD_FILE" | awk '{print $1}')"
assert_file_contains "${TARGET}/.aid/.aid-manifest.json" "$OLD_SHA" "Previous manifest records the old skill SHA"

mkdir -p "${TARGET}/.agents/skills/aid-zzz" "${TARGET}/.agents/skills/my-skill"
printf 'untracked aid skill\n' > "${TARGET}/.agents/skills/aid-zzz/SKILL.md"
printf 'user-owned skill\n' > "${TARGET}/.agents/skills/my-skill/SKILL.md"
STRAY_BYTES="$(cat "${TARGET}/.agents/skills/aid-zzz/SKILL.md")"
USER_SHA="$(sha256sum "${TARGET}/.agents/skills/my-skill/SKILL.md" | awk '{print $1}')"

OUT="$(run_aid add claude-code --from-bundle "$PRUNED_BUNDLE" --target "$TARGET" 2>&1)" || {
    echo "ERROR: claude-code add failed:" >&2; echo "$OUT" >&2; exit 1;
}

assert_file_absent "$OLD_FILE" "Manifested old skill is deleted when its previous SHA matches"
assert_file_absent "${TARGET}/.aid/.trash/.agents/skills/aid-define/SKILL.md" \
    "Clean previous skill is not copied to trash"
assert_file_absent "${TARGET}/.agents/skills/aid-zzz/SKILL.md" \
    "Unrecorded canonical aid skill leaves its source path"
assert_file_exists "${TARGET}/.aid/.trash/.agents/skills/aid-zzz/SKILL.md" \
    "Unrecorded canonical aid skill is preserved in trash"
assert_eq "$(cat "${TARGET}/.aid/.trash/.agents/skills/aid-zzz/SKILL.md")" "$STRAY_BYTES" \
    "Canonical stray trash bytes are unchanged"
assert_eq "$(sha256sum "${TARGET}/.agents/skills/my-skill/SKILL.md" | awk '{print $1}')" "$USER_SHA" \
    "Non-AID user skill remains unchanged"
assert_file_exists "${TARGET}/.agents/skills/aid-summarize/SKILL.md" \
    "Canonical skill present in the new manifest remains installed"
test_summary
