#!/usr/bin/env bash
# test-aid-migrate.sh -- task-081: migration unit/safety tests for _aid_migrate_repo
# (reachable via `aid __migrate-repo <path>`).
#
# Scope: v4 upgrades only from v3.x projects (anything older goes to v3 first), so the
# pre-v3 migration gates (era-a/era-b settings, format-2 dashboard elimination,
# work-level STATE.md -> STATE.yml conversion, a schema-1 split .agents/ Codex repo) are
# no longer covered here. What remains:
#
#   Gate 8:  bare .aid/.temp/ (no marker) -> non-candidate, zero writes
#   ISO:     the dogfood .aid/settings.yml is never touched
#   Gate 9e: migrate registers the repo in STATE_HOME/registry.yml
#   Gate 11: .cursor/rules/aid-* swept by aid update; user content intact
#   Gate 12: .agent/rules/aid-* swept by aid update; user content intact
#   AC-13 (work-001 task-021): hand-built v3 fixtures for claude-code, codex (with the legacy
#             .agents/aid/ layout), cursor, copilot-cli, antigravity, a legacy-only Codex layout and a
#             two-tool layout, manifest-backed and manifest-less. Interrupted runs (retire-partial,
#             after-retired, after-one-v4-copy, pre-clear) are injected into patched COPIES of the CLI;
#             refusals (invalid recovery data, future formats, staging, dry-run, atomic record writes,
#             add/remove and out-of-set tool gates) and frozen-clock trash collisions follow.
#   AC-14 (c): v3 claude-code CLAUDE.md (user content above and below the region, no final LF, no
#             markers) and v3 AGENTS.md (full region, user text after it).
#
# ISOLATION: every test builds a throwaway CODE_HOME (bin/aid + lib/ + VERSION + dashboard/)
# and a separate throwaway STATE_HOME (AID_HOME= for mutable state only), plus a throwaway
# fixture repo under mktemp -d.  `trap ... EXIT` cleans up.  NEVER scans real $HOME.
# NEVER writes to ~/.aid/registry.yml or modifies this repo's .aid/.
#
# HOME is pinned to a throwaway dir so no home-relative writes touch the real $HOME.
#
# Usage:
#   bash tests/canonical/test-aid-migrate.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BIN_AID="${REPO_ROOT}/bin/aid"
LIB_CORE="${REPO_ROOT}/lib/aid-install-core.sh"
READ_SETTING="${REPO_ROOT}/canonical/aid/scripts/config/read-setting.sh"

[[ -f "$BIN_AID" ]]    || { echo "ERROR: bin/aid not found at $BIN_AID" >&2; exit 1; }
[[ -f "$LIB_CORE" ]]   || { echo "ERROR: lib/aid-install-core.sh not found" >&2; exit 1; }
[[ -f "$READ_SETTING" ]] || { echo "ERROR: read-setting.sh not found at $READ_SETTING" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Global tmp dir: all fixture repos and AID_HOMEs live here.
# Cleaned up unconditionally on exit (EXIT trap).
# ---------------------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# HOME pin: all home-relative writes (e.g. ~/.aid/.update-check) land in a
# throwaway dir.  REAL_HOME is saved for the isolation canary check.
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
# Snapshot any pre-existing .aid dirs under the real HOME BEFORE the suite runs,
# so the isolation canary asserts no NEW .aid escaped the throwaway HOME (rather
# than assuming the real HOME starts empty -- it does not under CI, where the repo
# checkout lives under $HOME, nor for a dev with .aid repos under ~).
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a minimal CODE_HOME with bin/aid + lib/aid-install-core.sh + VERSION
# and a stub dashboard/home.html (the CLI install-tree template the server serves;
# NOT a per-repo migrate source -- format 2 no longer copies home.html into repos).
# bin/aid self-locates this dir as AID_CODE_HOME.
# Do NOT export this dir as AID_HOME; that is the state home (see new_state_home).
new_code_home() {
    local h; h="$(mktemp -d "${TMP}/code.XXXXXX")"
    mkdir -p "${h}/bin" "${h}/lib" "${h}/dashboard"
    cp "${BIN_AID}"   "${h}/bin/aid"
    chmod +x          "${h}/bin/aid"
    cp "${LIB_CORE}"  "${h}/lib/aid-install-core.sh"
    printf '0.7.0\n'  > "${h}/VERSION"
    # The CLI-served home.html template lives in the install tree ($AID_CODE_HOME/dashboard/).
    printf '<html><body>AID Dashboard</body></html>\n' > "${h}/dashboard/home.html"
    echo "$h"
}

# Build a minimal STATE_HOME (mutable state only: registry.yml etc.).
# Export this dir as AID_HOME= when invoking aid so state is redirected here.
new_state_home() {
    local h; h="$(mktemp -d "${TMP}/state.XXXXXX")"
    echo "$h"
}

# Run aid __migrate-repo in a fully isolated environment.
# $1 = code_home (bin/aid + lib/ + VERSION + dashboard/)
# $2 = state_home (AID_HOME redirect, holds registry.yml etc.)
# $3 = repo path
# Sets AID_NO_UPDATE_CHECK=1 to skip network/cache side-effects.
# Stores output in MIG_OUT and exit code in MIG_RC.
run_migrate() {
    local code_home="$1" state_home="$2" repo="$3"
    MIG_OUT=$(AID_HOME="${state_home}" \
              AID_NO_UPDATE_CHECK=1 \
              bash "${code_home}/bin/aid" __migrate-repo "${repo}" 2>&1)
    MIG_RC=$?
}

# Compute SHA-256 of a file (portable: try sha256sum first, fall back to
# openssl which is present on most Linux/macOS).
file_sha256() {
    local f="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$f" | cut -d' ' -f1
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$f" | awk '{print $NF}'
    else
        md5sum "$f" | cut -d' ' -f1  # last-resort fallback
    fi
}

# ===========================================================================
# Gate 8 -- bare .aid/.temp/ (no marker) -> non-candidate, zero writes
#
# A folder with only .aid/.temp/ (no settings.yml, no knowledge marker).
# _aid_migrate_repo must return 0 without writing anything.
# ===========================================================================
echo ""
echo "=== Gate 8: bare .aid/.temp/ only -> non-candidate, zero writes ==="

G8_CODE_HOME="$(new_code_home)"
G8_STATE_HOME="$(new_state_home)"
G8_REPO="$(mktemp -d "${TMP}/g8-repo.XXXXXX")"
mkdir -p "${G8_REPO}/.aid/.temp"
# No settings.yml, no knowledge/ directory, no STATE.md.

# Snapshot the entire .aid/ subtree before the call.
G8_TREE_BEFORE="$(find "${G8_REPO}/.aid" -type f | sort)"
G8_AID_DIR_BEFORE_COUNT="$(find "${G8_REPO}/.aid" | wc -l | tr -d ' ')"

run_migrate "${G8_CODE_HOME}" "${G8_STATE_HOME}" "${G8_REPO}"
assert_exit_eq "$MIG_RC" 0 "G8-01 __migrate-repo bare-.aid/.temp/ -> exits 0 (no error)"

# The .aid/ subtree must be identical (zero writes, zero deletes).
G8_TREE_AFTER="$(find "${G8_REPO}/.aid" -type f | sort)"
assert_eq "$G8_TREE_BEFORE" "$G8_TREE_AFTER" \
    "G8-02 bare .aid/.temp/ is non-candidate: no files created or deleted"
G8_AID_DIR_AFTER_COUNT="$(find "${G8_REPO}/.aid" | wc -l | tr -d ' ')"
assert_eq "$G8_AID_DIR_BEFORE_COUNT" "$G8_AID_DIR_AFTER_COUNT" \
    "G8-03 bare .aid/.temp/ is non-candidate: directory count unchanged"

# No settings.yml must have been created.
if [[ -f "${G8_REPO}/.aid/settings.yml" ]]; then
    fail "G8-04 bare .aid/.temp/: settings.yml must NOT be created"
else
    pass "G8-04 bare .aid/.temp/: settings.yml correctly absent"
fi

# No dashboard/ directory must have been created.
if [[ -d "${G8_REPO}/.aid/dashboard" ]]; then
    fail "G8-05 bare .aid/.temp/: dashboard/ must NOT be created"
else
    pass "G8-05 bare .aid/.temp/: dashboard/ correctly absent"
fi

# STATE_HOME registry.yml must NOT contain this repo path.
if [[ -f "${G8_STATE_HOME}/registry.yml" ]]; then
    if grep -qF "${G8_REPO}" "${G8_STATE_HOME}/registry.yml" 2>/dev/null; then
        fail "G8-06 bare .aid/.temp/: non-candidate must NOT be registered"
    else
        pass "G8-06 bare .aid/.temp/: non-candidate correctly absent from registry"
    fi
else
    pass "G8-06 bare .aid/.temp/: registry.yml not created for non-candidate"
fi

# ===========================================================================
# ISOLATION GUARD: confirm the real .aid/settings.yml in this repo is
# untouched.  This verifies the test never scanned or modified the dogfood
# repo.
# ===========================================================================
echo ""
echo "=== Isolation guard: dogfood .aid/settings.yml untouched ==="

DOGFOOD_SETTINGS="${REPO_ROOT}/.aid/settings.yml"
if [[ -f "$DOGFOOD_SETTINGS" ]]; then
    # The file must still contain the dogfood project name (AID). The dogfood
    # settings.yml is now the flat format-3 schema (top-level name:, no indent).
    assert_file_contains "$DOGFOOD_SETTINGS" "name: AID" \
        "ISO-01 real .aid/settings.yml is untouched (name: AID still present)"
    assert_file_contains "$DOGFOOD_SETTINGS" "type: brownfield" \
        "ISO-02 real .aid/settings.yml type line untouched"
else
    pass "ISO-01 real .aid/settings.yml not found (acceptable: untouched)"
    pass "ISO-02 real .aid/settings.yml not found (acceptable: untouched)"
fi

# --- Gate 9e: direct registry-register assertion ----------------------------
echo ""
echo "=== Gate 9e: migrate registers the repo in STATE_HOME/registry.yml ==="
G9E_CODE_HOME="$(new_code_home)"
G9E_STATE_HOME="$(new_state_home)"
G9E_REPO="$(mktemp -d "${TMP}/g9e-repo.XXXXXX")"
mkdir -p "${G9E_REPO}/.aid"
# A current-format (format_version 5) settings.yml: the bytes migrate itself writes.
printf 'format_version: 5\nname: TestProject\ndescription: Gate-4a fixture project with inline comments\ntype: brownfield\nsource_control: none\nminimum_grade: A\nheartbeat_interval: 1\n' \
    > "${G9E_REPO}/.aid/settings.yml"
run_migrate "${G9E_CODE_HOME}" "${G9E_STATE_HOME}" "${G9E_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9E-01 migrate -> exit 0"
G9E_CANON="$(cd "${G9E_REPO}" && pwd)"
assert_file_contains "${G9E_STATE_HOME}/registry.yml" "${G9E_CANON}" \
    "G9E-02 repo canonical path registered in STATE_HOME/registry.yml"

# ===========================================================================
# Gates 11-12: OLD-LAYOUT FIXTURE MIGRATION (AC5 + AC8)
#
# These gates build an old-layout repo (retired `.cursor/rules/`, `.agent/rules/` AID
# content) and run `aid update` against each fixture, asserting:
#   (AC5) Retired AID trees are GONE; new layout present; user content intact
#   (AC8) tools.*.version is uniform after migration (no mixed-version state)
#
# Bundles are staged once through tests/lib/bundle.sh (release.sh --stage-only), so the
# offline --from-bundle directory carries the shared payload and every tool artifact.
# No network calls.
# HOME is pinned for the whole suite already; the escape canary is at the end.
# ===========================================================================
source "${REPO_ROOT}/tests/lib/bundle.sh"
VERSION_STR="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
BUNDLE_DIR="$(mktemp -d "${TMP}/bundles.XXXXXX")"
aid_test_stage_bundle "$BUNDLE_DIR" >"${TMP}/stage-bundle.log" 2>&1 \
    || { echo "ERROR: release staging failed (see ${TMP}/stage-bundle.log)" >&2; exit 1; }

# run_update: invoke 'aid update --from-bundle <dir> --target <repo>'
# Uses a minimal code_home built from the repo's own bin/aid + lib/.
# Sets AID_NO_UPDATE_CHECK=1 to avoid network/cache side-effects.
# Stores output in UPD_OUT and exit code in UPD_RC.
run_update() {
    local code_home="$1" state_home="$2" repo="$3"
    UPD_OUT=$(AID_HOME="${state_home}" \
              AID_NO_UPDATE_CHECK=1 \
              bash "${code_home}/bin/aid" update \
              --from-bundle "${BUNDLE_DIR}" \
              --target "${repo}" 2>&1)
    UPD_RC=$?
}

# Write a minimal pre-work-005 manifest (era-b shape; version pre-dates work-005).
# This lets the tools-to-update list be resolved by `manifest_list_tools`.
_write_old_manifest() {
    local manifest_path="$1"  # e.g. <repo>/.aid/.aid-manifest.json
    local tool="$2"
    local old_ver="${3:-0.7.0}"
    cat > "$manifest_path" << MANIFEST_EOF
{
  "schema": 1,
  "tools": {
    "${tool}": {
      "version": "${old_ver}",
      "status": "active",
      "installed_at": "2025-01-01T00:00:00Z",
      "paths": []
    }
  }
}
MANIFEST_EOF
}

# Write a minimal settings.yml (era-a, without format_version so the format gate
# issues a warn-not-fail: format 0 < supported 1 -> non-blocking WARN).
_write_old_settings() {
    local settings_path="$1"
    local tool="$2"
    cat > "$settings_path" << SETTINGS_EOF
project:
  name: OldLayoutFixture
  description: Pre-work-005 old layout
  type: brownfield

tools:
  installed:
    - ${tool}

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
SETTINGS_EOF
}

# ===========================================================================
# Gate 11 -- Cursor old-layout fixture (AC5: retired .cursor/rules/ swept)
#
# Fixture: pre-work-005 cursor repo with:
#   .cursor/rules/aid-architect.mdc   (AID content, marker 1: aid- prefix)
#   .cursor/rules/aid-clerk.mdc       (AID content, marker 1: aid- prefix)
#   .cursor/rules/my.mdc              (USER content: no aid- prefix)
#   AGENTS.md with AID:BEGIN..END + user lines outside the region
#
# After `aid update`:
#   (AC5-a) .cursor/rules/aid-*.mdc files are GONE
#   (AC5-b) New .cursor/agents/ and .cursor/aid/ are present
#   (AC5-c) .cursor/rules/my.mdc is byte-identical (user content untouched)
#   (AC5-d) User lines outside the AID:BEGIN..END region in AGENTS.md are intact
#   (AC8)   tools.cursor.version in manifest == VERSION_STR
# ===========================================================================
echo ""
echo "=== Gate 11: Cursor .cursor/rules/ swept; new .cursor/agents/ present; user content intact ==="

G11_CODE_HOME="$(new_code_home)"
G11_STATE_HOME="$(new_state_home)"
G11_REPO="$(mktemp -d "${TMP}/g11-repo.XXXXXX")"
mkdir -p "${G11_REPO}/.aid"
mkdir -p "${G11_REPO}/.cursor/rules"

# AID-owned content under retired .cursor/rules/ (marker 1: aid- prefix).
printf 'old cursor architect rule\n' > "${G11_REPO}/.cursor/rules/aid-architect.mdc"
printf 'old cursor clerk rule\n' > "${G11_REPO}/.cursor/rules/aid-clerk.mdc"
# USER content under .cursor/rules/ (no AID marker -- must survive byte-identical).
printf 'USER-CURSOR-MY-RULE-SENTINEL\n' > "${G11_REPO}/.cursor/rules/my.mdc"
G11_USER_SHA="$(file_sha256 "${G11_REPO}/.cursor/rules/my.mdc")"

# AGENTS.md: AID:BEGIN..END region + user lines outside it.
# The user lines outside the region must survive byte-identical after migration.
cat > "${G11_REPO}/AGENTS.md" << 'G11_AGENTS_EOF'
# AGENTS.md

## My Project Notes
USER-LINE-BEFORE-REGION

<!-- AID:BEGIN -->
## Old AID section (will be replaced by migration)
This is old AID content inside the region.
<!-- AID:END -->

## My Custom Section
USER-LINE-AFTER-REGION
G11_AGENTS_EOF

# Capture sha256 of just the user lines outside the region (before migration).
G11_AGENTS_SHA_BEFORE="$(file_sha256 "${G11_REPO}/AGENTS.md")"

_write_old_manifest "${G11_REPO}/.aid/.aid-manifest.json" "cursor"
_write_old_settings "${G11_REPO}/.aid/settings.yml" "cursor"

run_update "${G11_CODE_HOME}" "${G11_STATE_HOME}" "${G11_REPO}"
assert_exit_eq "$UPD_RC" 0 "G11-01 aid update on cursor old-layout -> exit 0"

# AC5-a: retired .cursor/rules/ AID-owned files are gone from original location.
if [[ -f "${G11_REPO}/.cursor/rules/aid-architect.mdc" ]]; then
    fail "G11-02 (AC5) .cursor/rules/aid-architect.mdc must be moved out (AID-owned, marker 1)"
else
    pass "G11-02 (AC5) .cursor/rules/aid-architect.mdc moved out of retired root by sweep"
fi
if [[ -f "${G11_REPO}/.cursor/rules/aid-clerk.mdc" ]]; then
    fail "G11-03 (AC5) .cursor/rules/aid-clerk.mdc must be moved out (AID-owned, marker 1)"
else
    pass "G11-03 (AC5) .cursor/rules/aid-clerk.mdc moved out of retired root by sweep"
fi

# AC5-b: new .cursor/agents/ layout present.
assert_dir_exists "${G11_REPO}/.cursor/agents" \
    "G11-04 (AC5) new .cursor/agents/ directory present after migration"
if [[ -e "${G11_REPO}/.cursor/aid" ]]; then
    fail "G11-05 (AC5) .cursor/aid/ must not exist in the shared layout"
else
    pass "G11-05 (AC5) .cursor/aid/ absent in the shared layout"
fi
if [[ -n "$(find "${G11_REPO}/.cursor/skills" -name 'aid-*' 2>/dev/null | head -1)" ]]; then
    fail "G11-05b (AC5) .cursor/skills/aid-* must not exist (skills live in .agents/skills/)"
else
    pass "G11-05b (AC5) no .cursor/skills/aid-* in the shared layout"
fi
G11_NEW_AGENTS="$(find "${G11_REPO}/.cursor/agents" -name 'aid-*.md' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${G11_NEW_AGENTS}" -gt 0 ]]; then
    pass "G11-06 (AC5) new .cursor/agents/ contains aid- agent files from new bundle"
else
    fail "G11-06 (AC5) .cursor/agents/ should contain aid-*.md files from new bundle"
fi

# AC5-c: user .cursor/rules/my.mdc is byte-identical (user content untouched).
assert_file_exists "${G11_REPO}/.cursor/rules/my.mdc" \
    "G11-07 (AC5) .cursor/rules/my.mdc (user content) still exists after migration"
G11_USER_SHA_AFTER="$(file_sha256 "${G11_REPO}/.cursor/rules/my.mdc")"
assert_eq "$G11_USER_SHA" "$G11_USER_SHA_AFTER" \
    "G11-08 (AC5) .cursor/rules/my.mdc is byte-identical (user content untouched)"

# AC5-d: user lines outside AID:BEGIN..END in AGENTS.md are preserved.
assert_file_exists "${G11_REPO}/AGENTS.md" \
    "G11-09 (AC5) AGENTS.md still exists after migration"
assert_file_contains "${G11_REPO}/AGENTS.md" "USER-LINE-BEFORE-REGION" \
    "G11-10 (AC5) AGENTS.md: user line BEFORE region is preserved"
assert_file_contains "${G11_REPO}/AGENTS.md" "USER-LINE-AFTER-REGION" \
    "G11-11 (AC5) AGENTS.md: user line AFTER region is preserved"
assert_file_contains "${G11_REPO}/AGENTS.md" "My Custom Section" \
    "G11-12 (AC5) AGENTS.md: user section heading preserved"

# The AID:BEGIN..END region must still be present (region merge keeps the markers).
assert_file_contains "${G11_REPO}/AGENTS.md" "<!-- AID:BEGIN -->" \
    "G11-13 (AC5) AGENTS.md: AID:BEGIN marker present after region merge"
assert_file_contains "${G11_REPO}/AGENTS.md" "<!-- AID:END -->" \
    "G11-14 (AC5) AGENTS.md: AID:END marker present after region merge"

# AC8: tools.cursor.version in manifest == VERSION_STR.
G11_MANIFEST="${G11_REPO}/.aid/.aid-manifest.json"
assert_file_exists "$G11_MANIFEST" "G11-15 (AC8) manifest exists after aid update"
G11_VER="$(grep -A 10 '"cursor"' "$G11_MANIFEST" 2>/dev/null | grep '"version"' | head -1 | sed 's/.*"version"[^"]*"\([^"]*\)".*/\1/')"
assert_eq "$G11_VER" "${VERSION_STR}" \
    "G11-16 (AC8) tools.cursor.version == current version (uniform)"

# W3: reversibility -- AID-owned cursor files moved to .aid/.trash/ (not deleted).
assert_file_exists "${G11_REPO}/.aid/.trash/.cursor/rules/aid-architect.mdc" \
    "G11-17 (W3) aid-architect.mdc in .aid/.trash/ (reversible move, not delete)"
assert_file_exists "${G11_REPO}/.aid/.trash/.cursor/rules/aid-clerk.mdc" \
    "G11-18 (W3) aid-clerk.mdc in .aid/.trash/ (reversible move, not delete)"
# W3: user my.mdc must NOT be in the trash (user content never trashed).
if [[ -f "${G11_REPO}/.aid/.trash/.cursor/rules/my.mdc" ]]; then
    fail "G11-19 (W3) my.mdc must NOT be in .aid/.trash/ (user content untouched)"
else
    pass "G11-19 (W3) my.mdc absent from .aid/.trash/ (user content never trashed)"
fi

# ===========================================================================
# Gate 12 -- Antigravity old-layout fixture (AC5: retired .agent/rules/ swept)
#
# Fixture: pre-work-005 antigravity repo with:
#   .agent/rules/aid-architect.md   (AID content, marker 1: aid- prefix)
#   .agent/rules/my-team-rules.md   (USER content: no aid- prefix)
#   AGENTS.md with AID:BEGIN..END + user lines outside the region
#
# After `aid update`:
#   (AC5-a) .agent/rules/aid-*.md files are GONE
#   (AC5-b) New .agent/agents/ and .agent/aid/ are present
#   (AC5-c) .agent/rules/my-team-rules.md is byte-identical
#   (AC5-d) User lines outside AGENTS.md region are intact
#   (AC8)   tools.antigravity.version == VERSION_STR
# ===========================================================================
echo ""
echo "=== Gate 12: Antigravity .agent/rules/ swept; new .agent/agents/ present; user content intact ==="

G12_CODE_HOME="$(new_code_home)"
G12_STATE_HOME="$(new_state_home)"
G12_REPO="$(mktemp -d "${TMP}/g12-repo.XXXXXX")"
mkdir -p "${G12_REPO}/.aid"
mkdir -p "${G12_REPO}/.agent/rules"

# AID-owned content under retired .agent/rules/ (marker 1: aid- prefix).
printf 'old antigravity architect rule\n' > "${G12_REPO}/.agent/rules/aid-architect.md"
printf 'old antigravity clerk rule\n' > "${G12_REPO}/.agent/rules/aid-clerk.md"
# USER content under .agent/rules/ (no AID marker -- must survive byte-identical).
printf 'USER-AGENT-RULES-SENTINEL\n' > "${G12_REPO}/.agent/rules/my-team-rules.md"
G12_USER_SHA="$(file_sha256 "${G12_REPO}/.agent/rules/my-team-rules.md")"

# AGENTS.md with AID:BEGIN..END + user content outside region.
cat > "${G12_REPO}/AGENTS.md" << 'G12_AGENTS_EOF'
# AGENTS.md

USER-ANTIGRAVITY-LINE-BEFORE

<!-- AID:BEGIN -->
## Old AID agents section
Some old AID content.
<!-- AID:END -->

USER-ANTIGRAVITY-LINE-AFTER
G12_AGENTS_EOF

_write_old_manifest "${G12_REPO}/.aid/.aid-manifest.json" "antigravity"
_write_old_settings "${G12_REPO}/.aid/settings.yml" "antigravity"

run_update "${G12_CODE_HOME}" "${G12_STATE_HOME}" "${G12_REPO}"
assert_exit_eq "$UPD_RC" 0 "G12-01 aid update on antigravity old-layout -> exit 0"

# AC5-a: retired .agent/rules/ AID-owned files are gone from original location.
if [[ -f "${G12_REPO}/.agent/rules/aid-architect.md" ]]; then
    fail "G12-02 (AC5) .agent/rules/aid-architect.md must be moved out (AID-owned, marker 1)"
else
    pass "G12-02 (AC5) .agent/rules/aid-architect.md moved out of retired root by sweep"
fi
if [[ -f "${G12_REPO}/.agent/rules/aid-clerk.md" ]]; then
    fail "G12-03 (AC5) .agent/rules/aid-clerk.md must be moved out (AID-owned, marker 1)"
else
    pass "G12-03 (AC5) .agent/rules/aid-clerk.md moved out of retired root by sweep"
fi

# AC5-b: new .agent/agents/ and .agent/aid/ present.
assert_dir_exists "${G12_REPO}/.agent/agents" \
    "G12-04 (AC5) new .agent/agents/ directory present after migration"
if [[ -e "${G12_REPO}/.agent/aid" ]]; then
    fail "G12-05 (AC5) .agent/aid/ must not exist in the shared layout"
else
    pass "G12-05 (AC5) .agent/aid/ absent in the shared layout"
fi
if [[ -n "$(find "${G12_REPO}/.agent/skills" -name 'aid-*' 2>/dev/null | head -1)" ]]; then
    fail "G12-05b (AC5) .agent/skills/aid-* must not exist (skills live in .agents/skills/)"
else
    pass "G12-05b (AC5) no .agent/skills/aid-* in the shared layout"
fi
G12_NEW_AGENTS="$(find "${G12_REPO}/.agent/agents" -name 'aid-*.md' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${G12_NEW_AGENTS}" -gt 0 ]]; then
    pass "G12-06 (AC5) new .agent/agents/ contains aid- agent files from new bundle"
else
    fail "G12-06 (AC5) .agent/agents/ should contain aid-*.md files from new bundle"
fi

# AC5-c: user .agent/rules/my-team-rules.md is byte-identical.
assert_file_exists "${G12_REPO}/.agent/rules/my-team-rules.md" \
    "G12-07 (AC5) .agent/rules/my-team-rules.md (user content) still exists"
G12_USER_SHA_AFTER="$(file_sha256 "${G12_REPO}/.agent/rules/my-team-rules.md")"
assert_eq "$G12_USER_SHA" "$G12_USER_SHA_AFTER" \
    "G12-08 (AC5) .agent/rules/my-team-rules.md is byte-identical (user content untouched)"

# AC5-d: user lines outside AGENTS.md region are preserved.
assert_file_exists "${G12_REPO}/AGENTS.md" \
    "G12-09 (AC5) AGENTS.md still exists after migration"
assert_file_contains "${G12_REPO}/AGENTS.md" "USER-ANTIGRAVITY-LINE-BEFORE" \
    "G12-10 (AC5) AGENTS.md: user line BEFORE region preserved"
assert_file_contains "${G12_REPO}/AGENTS.md" "USER-ANTIGRAVITY-LINE-AFTER" \
    "G12-11 (AC5) AGENTS.md: user line AFTER region preserved"
assert_file_contains "${G12_REPO}/AGENTS.md" "<!-- AID:BEGIN -->" \
    "G12-12 (AC5) AGENTS.md: AID:BEGIN marker present after region merge"
assert_file_contains "${G12_REPO}/AGENTS.md" "<!-- AID:END -->" \
    "G12-13 (AC5) AGENTS.md: AID:END marker present after region merge"

# AC8: tools.antigravity.version in manifest == VERSION_STR.
G12_MANIFEST="${G12_REPO}/.aid/.aid-manifest.json"
assert_file_exists "$G12_MANIFEST" "G12-14 (AC8) manifest exists after aid update"
G12_VER="$(grep -A 10 '"antigravity"' "$G12_MANIFEST" 2>/dev/null | grep '"version"' | head -1 | sed 's/.*"version"[^"]*"\([^"]*\)".*/\1/')"
assert_eq "$G12_VER" "${VERSION_STR}" \
    "G12-15 (AC8) tools.antigravity.version == current version (uniform)"

# W3: reversibility -- AID-owned antigravity files moved to .aid/.trash/ (not deleted).
assert_file_exists "${G12_REPO}/.aid/.trash/.agent/rules/aid-architect.md" \
    "G12-16 (W3) aid-architect.md in .aid/.trash/ (reversible move, not delete)"
assert_file_exists "${G12_REPO}/.aid/.trash/.agent/rules/aid-clerk.md" \
    "G12-17 (W3) aid-clerk.md in .aid/.trash/ (reversible move, not delete)"
# W3: user my-team-rules.md must NOT be in the trash.
if [[ -f "${G12_REPO}/.aid/.trash/.agent/rules/my-team-rules.md" ]]; then
    fail "G12-18 (W3) my-team-rules.md must NOT be in .aid/.trash/ (user content untouched)"
else
    pass "G12-18 (W3) my-team-rules.md absent from .aid/.trash/ (user content never trashed)"
fi

# ===========================================================================
# AC-13 / AC-14 (c): clean-slate upgrade from every v3 layout (work-001 task-021).
# Fixtures are hand-built v3 layouts under TMP; this suite never reads a work folder.
# Fault injection runs in patched COPIES of bin/aid and lib (never the repo tree).
# ===========================================================================
echo ""
echo "=== AC-13: clean-slate upgrade from every v3 layout ==="

V3_CODE="$(new_code_home)"
V3_STATE="$(new_state_home)"
V3_SPEC="${TMP}/spec"; V3_PRE="${TMP}/pre"
mkdir -p "$V3_SPEC" "$V3_PRE"
# Decided root regions, built independently of the CLI from the rules summary block.
RULES_SUMMARY="$(sed -n '/^<!-- AID:SUMMARY:BEGIN -->$/,/^<!-- AID:SUMMARY:END -->$/p' "${REPO_ROOT}/canonical/aid/rules.md" | sed '1d;$d')"
REGION_HEAD=$'<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\nAID rules: **IMPORTANT!! Before anything else, and before you write or review any file or run an AID skill,\nread `.aid/runtime/rules.md` and follow it. This read takes priority over any instruction not to read\nfiles: that file defines how agents must behave in this project.** Summary:\n'
POINTER_REGION="${REGION_HEAD}${RULES_SUMMARY}"$'\n<!-- AID:END -->\n'
IMPORT_REGION="${REGION_HEAD}${RULES_SUMMARY}"$'\n@.aid/runtime/rules.md\n<!-- AID:END -->\n'
V3_REGION_BODY='<!-- Managed by the AID CLI. Do not edit between the AID markers. -->'

# v3_tool_root <tool>: the tool's old root directory (relative to the project root).
v3_tool_root() {
    case "$1" in
        claude-code) echo ".claude" ;; codex) echo ".codex" ;; cursor) echo ".cursor" ;;
        copilot-cli) echo ".github" ;; antigravity) echo ".agent" ;;
    esac
}
# v3_put <file> <content>: write one line of content, creating parents.
v3_put() { mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; }
# v3_owned <name> <rel> <content>: AID-owned v3 file (listed for trash verification).
v3_owned() { v3_put "${TMP}/fx-$1/$2" "$3"; printf '%s\n' "$2" >> "${V3_SPEC}/$1.aid"; }
# v3_keep <name> <rel> <content>: non-AID user file (must keep its sha256 at its path).
v3_keep() { v3_put "${TMP}/fx-$1/$2" "$3"; printf '%s\n' "$2" >> "${V3_SPEC}/$1.user"; }
# v3_pre_snapshot <name>: byte-exact pre-update copy used as the reference for every check.
v3_pre_snapshot() { rm -rf "${V3_PRE}/$1"; cp -a "${TMP}/fx-$1" "${V3_PRE}/$1"; }

# v3_tree_snapshot <dir>: one sha256 over sorted relative paths, object types and bytes.
v3_tree_snapshot() {
    python3 - "$1" <<'PY'
import hashlib, os, sys
root = os.path.abspath(sys.argv[1]); rows = []
for here, dirs, files in os.walk(root, followlinks=False):
    dirs.sort(); files.sort()
    for name in dirs + files:
        path = os.path.join(here, name)
        rel = os.path.relpath(path, root).replace(os.sep, '/')
        if os.path.islink(path):
            rows.append('L ' + rel + ' ' + os.readlink(path))
        elif os.path.isdir(path):
            rows.append('D ' + rel)
        else:
            with open(path, 'rb') as stream:
                rows.append('F ' + rel + ' ' + hashlib.sha256(stream.read()).hexdigest())
print(hashlib.sha256(('\n'.join(rows) + '\n').encode()).hexdigest())
PY
}

# v3_fixture <name> <manifest:yes|no> <full|legacy-only> <tool...>
# Hand-built v3 layout. full: each tool's old skills/aid-*, aid/, user-notes.txt and
# non-aid skills file; codex also gets the legacy .agents/aid/ subtree. legacy-only:
# just the legacy .agents/aid/ Codex layout.
v3_fixture() {
    local name="$1" manifest="$2" shape="$3" fx tool root body="" sep=""
    shift 3
    fx="${TMP}/fx-${name}"
    rm -rf "$fx"; mkdir -p "$fx/.aid/.temp"
    : > "${V3_SPEC}/${name}.aid"; : > "${V3_SPEC}/${name}.user"
    printf 'format_version: 4\nproject:\n  name: V3Fixture\n  type: brownfield\n' > "$fx/.aid/settings.yml"
    if [[ "$manifest" == yes ]]; then
        for tool in "$@"; do
            body+="${sep}\"${tool}\":{\"version\":\"2.0.0\",\"status\":\"active\",\"installed_at\":\"2026-01-01T00:00:00Z\",\"paths\":[]}"
            sep=","
        done
        printf '{"format_version":2,"tools":{%s}}\n' "$body" > "$fx/.aid/.aid-manifest.json"
    fi
    for tool in "$@"; do
        if [[ "$tool" == codex ]]; then
            v3_owned "$name" ".agents/aid/shared.md" "old legacy shared config (codex)"
            v3_owned "$name" ".agents/aid/user-created.txt" "user-created under legacy .agents/aid"
            v3_keep "$name" ".agents/user-notes.txt" "NOTES legacy codex"
            v3_keep "$name" ".agents/skills/my-skill/SKILL.md" "MY SKILL legacy codex"
            [[ "$shape" == legacy-only ]] && continue
        fi
        root="$(v3_tool_root "$tool")"
        v3_owned "$name" "$root/skills/aid-plan/SKILL.md" "USER-EDITED aid-plan skill ($tool)"
        v3_owned "$name" "$root/skills/aid-plan/references/x.md" "reference untouched ($tool)"
        v3_owned "$name" "$root/aid/rules.md" "USER-EDITED old aid rules ($tool)"
        v3_owned "$name" "$root/aid/scripts/untouched.sh" "echo untouched ($tool)"
        v3_owned "$name" "$root/aid/user-created.txt" "USER-CREATED under old aid ($tool)"
        v3_keep "$name" "$root/user-notes.txt" "NOTES ($tool)"
        v3_keep "$name" "$root/skills/my-skill/SKILL.md" "MY SKILL ($tool)"
    done
    v3_pre_snapshot "$name"
}

# v3_aid <code-home> <args...>: run bin/aid against the shared state home; sets OUT and RC.
# V3_FAULT / V3_FAULT_FILE / V3_RECORD_FAIL are optional injection controls (see v3_fault_home).
v3_aid() {
    local code="$1"; shift
    OUT=$(AID_HOME="$V3_STATE" AID_NO_UPDATE_CHECK=1 \
          AID_TEST_FAULT="${V3_FAULT:-}" AID_TEST_FAULT_FILE="${V3_FAULT_FILE:-/dev/null}" AID_TEST_FAULT_AT=1 \
          AID_TEST_RECORD_FAIL="${V3_RECORD_FAIL:-}" \
          bash "${code}/bin/aid" "$@" 2>&1); RC=$?
}
# v3_update <fx> [extra args...]: aid update --from-bundle against the clean CLI.
v3_update() { local fx="$1"; shift; v3_aid "$V3_CODE" update --target "$fx" --from-bundle "$BUNDLE_DIR" "$@"; }

# v3_fault_home <mode...>: a copy of the clean CLI with fault hooks patched in. Each mode
# anchors on exactly one line; a missing anchor fails the suite instead of skipping the fault.
#   retire-partial     fail inside retire_v3_layout after the first old file is trashed
#   after-retired      exit after the record is written with retired=true (before any v4 copy)
#   after-one-v4-copy exit after the first v4 file is copied (before the manifest write)
#   pre-clear          exit after the manifest and stamp, before record cleanup
#   frozen-clock       pin the trash collision stamp to 20260101T000000Z
#   record-write       honour AID_TEST_RECORD_FAIL=<retired value>: that record write fails
v3_fault_home() {
    local home
    home="$(new_code_home)"
    if ! python3 - "$home" "$@" <<'PY'
import pathlib, sys
home, modes = pathlib.Path(sys.argv[1]), sys.argv[2:]
lib_p = home / 'lib' / 'aid-install-core.sh'; bin_p = home / 'bin' / 'aid'
lib = lib_p.read_text(encoding='utf-8'); binx = bin_p.read_text(encoding='utf-8')
def once(text, old, new):
    if text.count(old) != 1:
        raise SystemExit('anchor matched %d times: %r' % (text.count(old), old[:70]))
    return text.replace(old, new)
HOOK = '''
_aid_test_fault() {
    [[ "${AID_TEST_FAULT:-}" == "$1" ]] || return 0
    local n=0 f="${AID_TEST_FAULT_FILE:-/dev/null}"
    [[ -f "$f" ]] && n="$(cat "$f")"
    n=$((n + 1)); printf '%s' "$n" > "$f" 2>/dev/null || true
    [[ "$n" -eq "${AID_TEST_FAULT_AT:-1}" ]] && return 1
    return 0
}
'''
lib += HOOK
for mode in modes:
    if mode == 'retire-partial':
        lib = once(lib, '                count=$((count+1))\n            fi\n        done < <(find "${target}/${root}" -type f -print0 | sort -z)',
                   '                count=$((count+1)); _aid_test_fault retire-partial || return 1\n            fi\n        done < <(find "${target}/${root}" -type f -print0 | sort -z)')
    elif mode == 'after-retired':
        binx = once(binx, '                _AID_UPGRADE_RETIRED=true\n',
                    "                _AID_UPGRADE_RETIRED=true\n                _aid_test_fault after-retired || { echo 'injected fault: after-retired' >&2; exit 1; }\n")
    elif mode == 'after-one-v4-copy':
        # copy_file and copy_file_guarded share this tail; the v4 install uses the guarded one.
        anchor = '        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Copied: ${dst}"\n        return 0'
        if lib.count(anchor) != 2:
            raise SystemExit('copy anchor matched %d times' % lib.count(anchor))
        lib = lib.replace(anchor, '        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Copied: ${dst}"\n        _aid_test_fault after-one-v4-copy || { echo "injected fault: after-one-v4-copy" >&2; exit 1; }\n        return 0')
    elif mode == 'pre-clear':
        binx = once(binx, '                clear_upgrade_recovery "${_AID_TARGET}" || {',
                    "                _aid_test_fault pre-clear || { echo 'injected fault: pre-clear' >&2; exit 1; }\n                clear_upgrade_recovery \"${_AID_TARGET}\" || {")
    elif mode == 'frozen-clock':
        lib += '\n_aid_utc_stamp() { echo 20260101T000000Z; }\n'
    elif mode == 'record-write':
        lib += ('\neval "$(declare -f write_upgrade_recovery | sed \'1s/^write_upgrade_recovery /_aid_test_orig_write_recovery /\')"\n'
                'write_upgrade_recovery() {\n'
                '    if [[ -n "${AID_TEST_RECORD_FAIL:-}" && "$2" == "${AID_TEST_RECORD_FAIL}" ]]; then return 1; fi\n'
                '    _aid_test_orig_write_recovery "$@"\n'
                '}\n')
    else:
        raise SystemExit('unknown mode ' + mode)
lib_p.write_text(lib, encoding='utf-8'); bin_p.write_text(binx, encoding='utf-8')
PY
    then
        echo "ERROR: fault patch failed for: $*" >&2
        return 1
    fi
    printf '%s\n' "$home"
}

# v3_shared_checks <label> <fx> <tool...>: AC-3 and AC-7 after an upgrade.
declare -A V3_SUM=()
# v3_same <a> <b>: cmp -s, answered from the batched hashes in V3_SUM when both are known.
v3_same() {
    if [[ -n "${V3_SUM[$1]:-}" && -n "${V3_SUM[$2]:-}" ]]; then [[ "${V3_SUM[$1]}" == "${V3_SUM[$2]}" ]]
    else cmp -s "$1" "$2"; fi
}
v3_shared_checks() {
    local lbl="$1" fx="$2" rel tool bad=0 root line
    local -a rels=() files=()
    shift 2
    mapfile -t rels < <(cd "${REPO_ROOT}/canonical/skills" && find . -type f | sed 's#^\./##' | sort)
    # One sha256sum pass over every compared file instead of a cmp per file pair.
    V3_SUM=()
    for rel in "${rels[@]}"; do
        files+=("${REPO_ROOT}/canonical/skills/${rel}" "${fx}/.agents/skills/${rel}" "${fx}/.claude/skills/${rel}")
    done
    while IFS= read -r line; do
        [[ "${line:0:64}" =~ ^[0-9a-f]{64}$ && "${line:64:2}" == "  " ]] && V3_SUM["${line:66}"]="${line:0:64}"
    done < <(printf '%s\0' "${files[@]}" | xargs -0 sha256sum 2>/dev/null)
    for rel in "${rels[@]}"; do
        v3_same "${REPO_ROOT}/canonical/skills/${rel}" "${fx}/.agents/skills/${rel}" || bad=$((bad + 1))
        for tool in "$@"; do
            [[ "$tool" == claude-code ]] || continue
            v3_same "${REPO_ROOT}/canonical/skills/${rel}" "${fx}/.claude/skills/${rel}" || bad=$((bad + 1))
        done
    done
    if [[ "$bad" -eq 0 ]]; then pass "${lbl}: AC-3 installed skills byte-identical to canonical"
    else fail "${lbl}: AC-3 installed skills byte-identical to canonical — ${bad} mismatch(es)"; fi
    if diff -r -x node_modules -x '.*' "${REPO_ROOT}/canonical/aid/scripts" "${fx}/.aid/runtime/scripts" >/dev/null 2>&1 \
       && diff -r -x node_modules -x '.*' "${REPO_ROOT}/canonical/aid/templates" "${fx}/.aid/runtime/templates" >/dev/null 2>&1 \
       && cmp -s "${REPO_ROOT}/canonical/aid/rules.md" "${fx}/.aid/runtime/rules.md"; then
        pass "${lbl}: AC-7 runtime scripts, templates and rules.md equal canonical"
    else
        fail "${lbl}: AC-7 runtime scripts, templates and rules.md equal canonical"
    fi
    bad=0
    for root in .codex .cursor .github .agent; do
        [[ -z "$(find "${fx}/${root}/skills" -name 'aid-*' 2>/dev/null | head -1)" ]] || bad=$((bad + 1))
    done
    for root in .claude .codex .cursor .github .agent .agents; do
        [[ ! -e "${fx}/${root}/aid" ]] || bad=$((bad + 1))
    done
    if [[ "$bad" -eq 0 ]]; then pass "${lbl}: no aid-* under .codex/.cursor/.github/.agent skills and no <root>/aid/ remains"
    else fail "${lbl}: no aid-* under tool skills and no <root>/aid/ remains — ${bad} violation(s)"; fi
}

# v3_verify <name> <fx> <tool...>: AC-13 clauses for one fixture after an upgrade.
v3_verify() {
    local name="$1" fx="$2" pre="${V3_PRE}/$1" rel lbl="AC-13 $1" bad=0 n=0 sum="" kept_bad=0 aid_bad=0
    shift 2
    v3_shared_checks "$lbl" "$fx" "$@"
    while IFS= read -r rel; do
        n=$((n + 1))
        cmp -s "${pre}/${rel}" "${fx}/.aid/.trash/${rel}" || aid_bad=$((aid_bad + 1))
    done < "${V3_SPEC}/${name}.aid"
    if [[ "$n" -gt 0 && "$aid_bad" -eq 0 ]]; then pass "${lbl}: every old AID-owned file (modified or not) byte-identical at .aid/.trash/<path> (${n} files)"
    else fail "${lbl}: every old AID-owned file byte-identical at .aid/.trash/<path> — ${aid_bad} of ${n} differ"; fi
    bad=0; n=0
    while IFS= read -r rel; do
        [[ "$rel" == */aid/* ]] || continue
        n=$((n + 1))
        cmp -s "${pre}/${rel}" "${fx}/.aid/.trash/${rel}" || bad=$((bad + 1))
    done < "${V3_SPEC}/${name}.aid"
    if [[ "$n" -gt 0 && "$bad" -eq 0 ]]; then
        pass "${lbl}: every file under an old <root>/aid/ (user-created included) at its mirrored .aid/.trash/ path, none left under <root>/aid/ (${n} files)"
    else
        fail "${lbl}: old <root>/aid/ files mirrored into .aid/.trash/ and none left — ${bad} differ of ${n}"
    fi
    while IFS= read -r rel; do
        [[ -n "$rel" ]] || continue
        [[ "$(file_sha256 "${pre}/${rel}")" == "$(file_sha256 "${fx}/${rel}")" ]] || kept_bad=$((kept_bad + 1))
    done < "${V3_SPEC}/${name}.user"
    if [[ "$kept_bad" -eq 0 ]]; then pass "${lbl}: non-AID user files keep identical sha256 at their original paths"
    else fail "${lbl}: non-AID user files keep identical sha256 — ${kept_bad} changed"; fi
    if grep -qx 'format_version: 5' "${fx}/.aid/settings.yml" && grep -q '"format_version": 3' "${fx}/.aid/.aid-manifest.json" \
       && [[ "$(grep -c '"migration"' "${fx}/.aid/.aid-manifest.json")" == 0 ]]; then
        pass "${lbl}: .aid/settings.yml format_version 5, manifest format_version 3, no migration key"
    else
        fail "${lbl}: settings format_version 5 and manifest format_version 3 without a migration key"
    fi
    [[ ! -e "${fx}/.aid/.temp/v3-upgrade-tools.json" ]] && pass "${lbl}: recovery record absent after success" \
        || fail "${lbl}: recovery record absent after success"
}

# v3_second_run <name> <fx> <tool...>: a second aid update is a no-op and keeps the trash.
v3_second_run() {
    local name="$1" fx="$2" before after ups
    shift 2
    before="$(v3_tree_snapshot "${fx}/.aid/.trash")"
    v3_update "$fx"
    if [[ "$RC" -eq 0 ]]; then pass "AC-13 ${name}: second aid update exits 0"
    else fail "AC-13 ${name}: second aid update exits 0 — got ${RC}"; fi
    ups="$(grep -c 'up to date (' <<< "$OUT")"
    if [[ "$ups" -eq $(( $# + 1 )) ]]; then pass "AC-13 ${name}: second aid update prints up to date for shared and every tool"
    else fail "AC-13 ${name}: second aid update prints up to date for shared and every tool — ${ups} line(s)"; fi
    after="$(v3_tree_snapshot "${fx}/.aid/.trash")"
    [[ "$before" == "$after" ]] && pass "AC-13 ${name}: second aid update leaves .aid/.trash/ unchanged" \
        || fail "AC-13 ${name}: second aid update leaves .aid/.trash/ unchanged"
}

# AC-13 per-tool fixtures: five tools (manifest-backed and manifest-less), the legacy
# Codex .agents/aid/ layout on its own, and a two-tool layout.
echo "=== AC-13 per-tool v3 fixtures ==="
V3_FIXTURES=(
    "claude-code-m yes full claude-code"
    "codex-m yes full codex"
    "cursor-m yes full cursor"
    "copilot-m yes full copilot-cli"
    "antigravity-m yes full antigravity"
    "codex-legacy-m yes legacy-only codex"
    "two-tools-m yes full claude-code cursor"
    "claude-code-n no full claude-code"
    "codex-n no full codex"
    "cursor-n no full cursor"
    "copilot-n no full copilot-cli"
    "antigravity-n no full antigravity"
    "codex-legacy-n no legacy-only codex"
    "two-tools-n no full claude-code cursor"
)
for entry in "${V3_FIXTURES[@]}"; do
    read -r name manifest shape rest <<< "$entry"
    read -ra tools <<< "$rest"
    v3_fixture "$name" "$manifest" "$shape" "${tools[@]}"
    fx="${TMP}/fx-${name}"
    v3_update "$fx"
    if [[ "$RC" -eq 0 ]]; then pass "AC-13 ${name}: aid update --from-bundle exits 0"
    else fail "AC-13 ${name}: aid update --from-bundle exits 0 — got ${RC}"; [[ "$VERBOSE" -eq 1 ]] && echo "$OUT"; fi
    if grep -q 'old AID file(s) moved to .aid/.trash/' <<< "$OUT"; then pass "AC-13 ${name}: prints the old-file trash notice"
    else fail "AC-13 ${name}: prints the old-file trash notice"; fi
    v3_verify "$name" "$fx" "${tools[@]}"
    v3_second_run "$name" "$fx" "${tools[@]}"
done

# run_interrupted <name> <point> <manifest:yes|no> <tool...>: inject one failure with the
# clean CLI interrupted at <point>, then re-run aid update with the clean CLI.
run_interrupted() {
    local name="$1" point="$2" manifest="$3" fx code rec exp_retired joined="" sep="" t
    shift 3
    local -a tools=("$@")
    local lbl="AC-13 interrupted ${name}"
    v3_fixture "$name" "$manifest" full "${tools[@]}"
    fx="${TMP}/fx-${name}"; rec="${fx}/.aid/.temp/v3-upgrade-tools.json"
    for t in "${tools[@]}"; do joined+="${sep}\"${t}\""; sep=","; done
    code="$(v3_fault_home "$point")" || { fail "${lbl}: fault patch for ${point} applied"; return 0; }
    rm -f "${TMP}/fault-${name}"
    V3_FAULT="$point" V3_FAULT_FILE="${TMP}/fault-${name}" v3_aid "$code" update --target "$fx" --from-bundle "$BUNDLE_DIR"
    if [[ "$RC" -eq 1 ]]; then pass "${lbl}: injected ${point} stops the run with exit 1"
    else fail "${lbl}: injected ${point} stops the run with exit 1 — got ${RC}"; [[ "$VERBOSE" -eq 1 ]] && echo "$OUT"; fi
    exp_retired=true; [[ "$point" == retire-partial ]] && exp_retired=false
    if [[ -f "$rec" ]] && grep -qx "{\"format_version\":1,\"tools\":\[${joined}\],\"retired\":${exp_retired}}" "$rec"; then
        pass "${lbl}: recovery record survives ${point} with exactly the recorded tools and retired=${exp_retired}"
    else
        fail "${lbl}: recovery record survives ${point} with retired=${exp_retired}"
    fi
    if [[ "$manifest" == yes ]]; then
        if [[ "$point" == pre-clear ]]; then
            grep -q '"format_version": 3' "${fx}/.aid/.aid-manifest.json" && grep -qx 'format_version: 5' "${fx}/.aid/settings.yml" \
                && pass "${lbl}: manifest and stamp already written before the ${point} fault" \
                || fail "${lbl}: manifest and stamp already written before the ${point} fault"
        else
            grep -q '"format_version":2' "${fx}/.aid/.aid-manifest.json" \
                && pass "${lbl}: manifest still format 2 at the ${point} fault (no manifest write yet)" \
                || fail "${lbl}: manifest still format 2 at the ${point} fault"
        fi
    else
        if [[ "$point" == pre-clear ]]; then
            [[ -f "${fx}/.aid/.aid-manifest.json" ]] && pass "${lbl}: manifest written before the ${point} fault" \
                || fail "${lbl}: manifest written before the ${point} fault"
        else
            [[ ! -e "${fx}/.aid/.aid-manifest.json" ]] && pass "${lbl}: no manifest written before the ${point} fault" \
                || fail "${lbl}: no manifest written before the ${point} fault"
        fi
    fi
    local before after
    before="$(v3_tree_snapshot "${fx}/.aid/.trash")"
    v3_update "$fx"
    if [[ "$RC" -eq 0 ]]; then pass "${lbl}: retry aid update exits 0"
    else fail "${lbl}: retry aid update exits 0 — got ${RC}"; [[ "$VERBOSE" -eq 1 ]] && echo "$OUT"; fi
    if [[ "$(grep -c '"migration"' "${fx}/.aid/.aid-manifest.json" 2>/dev/null)" == 0 ]]; then
        pass "${lbl}: grep -c '\"migration\"' on the manifest prints 0"
    else
        fail "${lbl}: grep -c '\"migration\"' on the manifest prints 0"
    fi
    local got="" gsep=""
    got="$(python3 -c 'import json,sys; print(",".join(sorted(json.load(open(sys.argv[1])).get("tools", {}))))' "${fx}/.aid/.aid-manifest.json" 2>/dev/null)"
    local want
    want="$(printf '%s\n' "${tools[@]}" | sort | paste -sd, -)"
    [[ "$got" == "$want" ]] && pass "${lbl}: retry restores exactly the recorded tool set (${want})" \
        || fail "${lbl}: retry restores exactly the recorded tool set — manifest has '${got}', record has '${want}'"
    v3_verify "$name" "$fx" "${tools[@]}"
    [[ ! -e "$rec" ]] && pass "${lbl}: recovery record removed after success" || fail "${lbl}: recovery record removed after success"
    after="$(v3_tree_snapshot "${fx}/.aid/.trash")"
    if [[ "$point" == retire-partial ]]; then
        pass "${lbl}: retry completes the partial retirement (trash grows; prior trash bytes verified above)"
    elif [[ "$before" == "$after" ]]; then
        pass "${lbl}: retry leaves the trash snapshot unchanged (no copied v4 file retired)"
    else
        fail "${lbl}: retry leaves the trash snapshot unchanged (no copied v4 file retired)"
    fi
    v3_second_run "$name" "$fx" "${tools[@]}"
}

echo "=== AC-13 interrupted-run recovery ==="
for point in retire-partial after-retired after-one-v4-copy pre-clear; do
    run_interrupted "int-${point}-m" "$point" yes claude-code
    run_interrupted "int-${point}-n" "$point" no claude-code
done
run_interrupted "int-two-tools-m" after-retired yes claude-code cursor
run_interrupted "int-two-tools-n" after-retired no claude-code cursor

echo "=== AC-13 refusals, staging, dry-run, atomic writes, add/remove gates ==="
# Invalid recovery data: exit 2 before any repository write; the record is left untouched.
BAD_RECORDS=(
    'not-json{'
    '{"format_version":2,"tools":["claude-code"],"retired":false}'
    '{"format_version":1,"tools":["gemini"],"retired":false}'
    '{"format_version":1,"tools":["claude-code","claude-code"],"retired":false}'
    '{"format_version":1,"tools":["claude-code"]}'
    '{"format_version":1,"tools":["claude-code"],"retired":false,"migration":{}}'
    '{"format_version":1,"tools":["claude-code"],"retired":"false"}'
    '{"format_version":1,"tools":["cursor","claude-code"],"retired":false}'
    '{"format_version":1,"tools":[],"retired":false}'
)
i=0
for bad in "${BAD_RECORDS[@]}"; do
    i=$((i + 1))
    name="refuse-record-${i}"
    v3_fixture "$name" yes full claude-code
    fx="${TMP}/fx-${name}"
    printf '%s\n' "$bad" > "${fx}/.aid/.temp/v3-upgrade-tools.json"
    before="$(v3_tree_snapshot "$fx")"
    v3_update "$fx"
    if [[ "$RC" -eq 2 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && grep -q 'invalid recovery data' <<< "$OUT"; then
        pass "AC-13 invalid record ${i}: aid update exits 2 with a recovery-data diagnostic and writes nothing"
    else
        fail "AC-13 invalid record ${i}: aid update exits 2 and writes nothing — got ${RC}"
    fi
done
name=refuse-record-symlink; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
ln -s "${fx}/.aid/settings.yml" "${fx}/.aid/.temp/v3-upgrade-tools.json"; before="$(v3_tree_snapshot "$fx")"
v3_update "$fx"
[[ "$RC" -eq 2 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && pass "AC-13 symlink recovery record: aid update exits 2 and writes nothing" \
    || fail "AC-13 symlink recovery record: aid update exits 2 and writes nothing — got ${RC}"
name=refuse-record-dir; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
mkdir -p "${fx}/.aid/.temp/v3-upgrade-tools.json"; before="$(v3_tree_snapshot "$fx")"
v3_update "$fx"
[[ "$RC" -eq 2 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && pass "AC-13 non-regular recovery record: aid update exits 2 and writes nothing" \
    || fail "AC-13 non-regular recovery record: aid update exits 2 and writes nothing — got ${RC}"

# Future formats refuse first, with or without a pending record.
name=future-manifest; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
printf '{"format_version":4,"tools":{"claude-code":{"version":"2.0.0","status":"active","installed_at":"2026-01-01T00:00:00Z","paths":[]}}}\n' > "${fx}/.aid/.aid-manifest.json"
before="$(v3_tree_snapshot "$fx")"; v3_update "$fx"
[[ "$RC" -ne 0 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && grep -q 'aid update self' <<< "$OUT" \
    && pass "AC-13 future manifest format 4: refused with 'Run: aid update self' and nothing written (exit ${RC})" \
    || fail "AC-13 future manifest format 4: refused with 'Run: aid update self' and nothing written — got ${RC}"
printf '{"format_version":1,"tools":["claude-code"],"retired":false}\n' > "${fx}/.aid/.temp/v3-upgrade-tools.json"
before="$(v3_tree_snapshot "$fx")"; v3_update "$fx"
[[ "$RC" -ne 0 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && grep -q 'aid update self' <<< "$OUT" \
    && pass "AC-13 future manifest format 4 with pending record: record does not bypass the refusal (exit ${RC})" \
    || fail "AC-13 future manifest format 4 with pending record: record does not bypass the refusal — got ${RC}"
name=future-settings; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
printf 'format_version: 6\n' > "${fx}/.aid/settings.yml"; before="$(v3_tree_snapshot "$fx")"; v3_update "$fx"
[[ "$RC" -ne 0 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && grep -q 'newer than this CLI supports' <<< "$OUT" \
    && pass "AC-13 future settings format 6: refused and nothing written (exit ${RC})" \
    || fail "AC-13 future settings format 6: refused and nothing written — got ${RC}"

# Staging failure: a corrupt staged artifact aborts before any repository write.
mkdir -p "${TMP}/bundle-corrupt"; cp "${BUNDLE_DIR}"/* "${TMP}/bundle-corrupt/"
printf 'corrupt' >> "${TMP}/bundle-corrupt/aid-claude-code-v${VERSION_STR}.tar.gz"
name=stage-fail; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
before="$(v3_tree_snapshot "$fx")"
v3_aid "$V3_CODE" update --target "$fx" --from-bundle "${TMP}/bundle-corrupt"
[[ "$RC" -ne 0 && "$(v3_tree_snapshot "$fx")" == "$before" && ! -e "${fx}/.aid/.temp/v3-upgrade-tools.json" ]] \
    && pass "AC-13 staging failure: corrupt artifact aborts (exit ${RC}), no record, whole tree unchanged" \
    || fail "AC-13 staging failure: corrupt artifact aborts with the tree unchanged — got ${RC}"
printf '{"format_version":1,"tools":["claude-code"],"retired":false}\n' > "${fx}/.aid/.temp/v3-upgrade-tools.json"
before="$(v3_tree_snapshot "$fx")"
v3_aid "$V3_CODE" update --target "$fx" --from-bundle "${TMP}/bundle-corrupt"
[[ "$RC" -ne 0 && "$(v3_tree_snapshot "$fx")" == "$before" ]] \
    && pass "AC-13 staging failure with a valid pending record: record and tree unchanged (exit ${RC})" \
    || fail "AC-13 staging failure with a valid pending record: record and tree unchanged — got ${RC}"

# Dry-run: reports the plan and writes nothing, with and without a pending record.
name=dry-run; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
before="$(v3_tree_snapshot "$fx")"
OUT=$(AID_HOME="$V3_STATE" AID_NO_UPDATE_CHECK=1 bash "${V3_CODE}/bin/aid" update --dry-run --target "$fx" --from-bundle "$BUNDLE_DIR" 2>&1); RC=$?
[[ "$RC" -eq 0 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && grep -q 'dry-run plan (no writes)' <<< "$OUT" \
    && pass "AC-13 dry-run on a v3 layout: exits 0, prints the plan, writes nothing" \
    || fail "AC-13 dry-run on a v3 layout: exits 0 and writes nothing — got ${RC}"
printf '{"format_version":1,"tools":["claude-code"],"retired":false}\n' > "${fx}/.aid/.temp/v3-upgrade-tools.json"
before="$(v3_tree_snapshot "$fx")"
OUT=$(AID_HOME="$V3_STATE" AID_NO_UPDATE_CHECK=1 bash "${V3_CODE}/bin/aid" update --dry-run --target "$fx" --from-bundle "$BUNDLE_DIR" 2>&1); RC=$?
[[ "$RC" -eq 0 && "$(v3_tree_snapshot "$fx")" == "$before" ]] \
    && pass "AC-13 dry-run with a valid pending record: exits 0, record and tree unchanged" \
    || fail "AC-13 dry-run with a valid pending record: exits 0, record and tree unchanged — got ${RC}"

# Atomic record writes: a failed first write retires nothing; a failed retired=true write
# copies no v4 file and leaves the manifest at format 2.
name=record-fail-first; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
before="$(v3_tree_snapshot "$fx")"
RECORD_CODE="$(v3_fault_home record-write)" || { fail "AC-13 record write: fault patch applied"; RECORD_CODE="$V3_CODE"; }
V3_RECORD_FAIL=false; V3_FAULT=; v3_aid "$RECORD_CODE" update --target "$fx" --from-bundle "$BUNDLE_DIR"; V3_RECORD_FAIL=
[[ "$RC" -eq 1 && "$(v3_tree_snapshot "$fx")" == "$before" ]] \
    && pass "AC-13 atomic record write failure (retired=false): exits 1, nothing retired, tree unchanged" \
    || fail "AC-13 atomic record write failure (retired=false): nothing retired, tree unchanged — got ${RC}"
name=record-fail-second; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
RECORD_CODE="$(v3_fault_home record-write)" || { fail "AC-13 record write: fault patch applied"; RECORD_CODE="$V3_CODE"; }
V3_RECORD_FAIL=true; v3_aid "$RECORD_CODE" update --target "$fx" --from-bundle "$BUNDLE_DIR"; V3_RECORD_FAIL=
if [[ "$RC" -eq 1 && -f "${fx}/.aid/.temp/v3-upgrade-tools.json" ]] && grep -qx '{"format_version":1,"tools":\["claude-code"\],"retired":false}' "${fx}/.aid/.temp/v3-upgrade-tools.json" \
   && [[ -f "${fx}/.aid/.trash/.claude/aid/rules.md" ]] && [[ ! -e "${fx}/.agents/skills/aid-ask/SKILL.md" ]] \
   && grep -q '"format_version":2' "${fx}/.aid/.aid-manifest.json"; then
    pass "AC-13 atomic record write failure (retired=true): retirement stopped, no v4 copy, manifest still format 2"
else
    fail "AC-13 atomic record write failure (retired=true): retirement stopped, no v4 copy, manifest still format 2 — got ${RC}"
fi
v3_update "$fx"
[[ "$RC" -eq 0 ]] && v3_verify "$name" "$fx" claude-code && pass "AC-13 ${name}: retry after the failed retired=true write completes" \
    || fail "AC-13 ${name}: retry after the failed retired=true write completes — got ${RC}"

# Pending-record gates: add and remove refuse and name aid update; a named tool outside the
# recorded set is refused; a named tool inside it proceeds.
name=pending-gates; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
printf '{"format_version":1,"tools":["claude-code"],"retired":false}\n' > "${fx}/.aid/.temp/v3-upgrade-tools.json"
before="$(v3_tree_snapshot "$fx")"
v3_aid "$V3_CODE" add cursor --target "$fx" --from-bundle "$BUNDLE_DIR"
[[ "$RC" -eq 2 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && grep -q 'aid update' <<< "$OUT" \
    && pass "AC-13 pending record: aid add exits 2, names aid update, writes nothing" \
    || fail "AC-13 pending record: aid add exits 2, names aid update, writes nothing — got ${RC}"
v3_aid "$V3_CODE" remove claude-code --target "$fx"
[[ "$RC" -eq 2 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && grep -q 'aid update' <<< "$OUT" \
    && pass "AC-13 pending record: aid remove exits 2, names aid update, writes nothing" \
    || fail "AC-13 pending record: aid remove exits 2, names aid update, writes nothing — got ${RC}"
v3_update "$fx" cursor
[[ "$RC" -eq 2 && "$(v3_tree_snapshot "$fx")" == "$before" ]] && grep -q 'outside the pending recovery set' <<< "$OUT" \
    && pass "AC-13 pending record: update naming a tool outside the record exits 2 and writes nothing" \
    || fail "AC-13 pending record: update naming a tool outside the record exits 2 and writes nothing — got ${RC}"
v3_update "$fx" claude-code
[[ "$RC" -eq 0 && ! -e "${fx}/.aid/.temp/v3-upgrade-tools.json" ]] && v3_verify "$name" "$fx" claude-code \
    && pass "AC-13 pending record: update naming a tool inside the record completes recovery" \
    || fail "AC-13 pending record: update naming a tool inside the record completes recovery — got ${RC}"

# Frozen clock: a preoccupied .N suffix chain keeps every backup byte; a repeated collision
# under the same stamp appends the next free suffix.
echo "=== AC-13 frozen-clock trash collisions ==="
name=frozen-clock; v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
mkdir -p "${fx}/.aid/.trash/.claude/aid"
printf 'PRIOR-ORIGINAL\n' > "${fx}/.aid/.trash/.claude/aid/rules.md"
printf 'PREOCCUPIED-1\n' > "${fx}/.aid/.trash/.claude/aid/rules.md.20260101T000000Z"
printf 'PREOCCUPIED-2\n' > "${fx}/.aid/.trash/.claude/aid/rules.md.20260101T000000Z.1"
FROZEN_CODE="$(v3_fault_home frozen-clock)" || { fail "AC-13 frozen clock: fault patch applied"; FROZEN_CODE="$V3_CODE"; }
V3_FAULT= v3_aid "$FROZEN_CODE" update --target "$fx" --from-bundle "$BUNDLE_DIR"
t="${fx}/.aid/.trash/.claude/aid/rules.md"
if [[ "$RC" -eq 0 ]] && cmp -s "$t" "${V3_PRE}/${name}/.claude/aid/rules.md" \
   && [[ "$(cat "${t}.20260101T000000Z")" == "PREOCCUPIED-1" ]] && [[ "$(cat "${t}.20260101T000000Z.1")" == "PREOCCUPIED-2" ]] \
   && [[ "$(cat "${t}.20260101T000000Z.2")" == "PRIOR-ORIGINAL" ]]; then
    pass "AC-13 frozen clock: preoccupied .N suffixes kept and the prior bytes moved to .20260101T000000Z.2"
else
    fail "AC-13 frozen clock: preoccupied .N suffixes kept and prior bytes moved to .2 — got ${RC}"
fi
v3_put "${fx}/.claude/aid/rules.md" "THIRD-EDIT"
# The project is format 3 now, so a restored legacy path alone no longer re-triggers the
# upgrade (FR-11); an interrupted-upgrade record is what legitimately runs retirement again.
printf '{"format_version":1,"tools":["claude-code"],"retired":false}\n' > "${fx}/.aid/.temp/v3-upgrade-tools.json"
v3_aid "$FROZEN_CODE" update --target "$fx" --from-bundle "$BUNDLE_DIR"
if [[ "$RC" -eq 0 ]] && [[ "$(cat "$t")" == "THIRD-EDIT" ]] && cmp -s "${t}.20260101T000000Z.3" "${V3_PRE}/${name}/.claude/aid/rules.md" \
   && [[ "$(cat "${t}.20260101T000000Z")" == "PREOCCUPIED-1" ]] && [[ "$(cat "${t}.20260101T000000Z.1")" == "PREOCCUPIED-2" ]] \
   && [[ "$(cat "${t}.20260101T000000Z.2")" == "PRIOR-ORIGINAL" ]]; then
    pass "AC-13 frozen clock: repeated collision under the same stamp takes the next free suffix (.3); every prior byte kept"
else
    fail "AC-13 frozen clock: repeated collision keeps every prior byte in order — got ${RC}"
fi

# --- AC-14 case (c): v3 claude-code root context files ---------------------
echo "=== AC-14 (c): v3 claude-code root context files ==="
root_case() {
    local name="$1" fx pre="${V3_PRE}/$1"
    v3_fixture "$name" yes full claude-code; fx="${TMP}/fx-${name}"
    shift
    "$@" "$fx"
    v3_pre_snapshot "$name"
    v3_update "$fx"
}
seed_user_region() {
    printf '%s\n' '# Project memory' 'user line above' '<!-- AID:BEGIN -->' "$V3_REGION_BODY" \
        'v3 AID rules (full region body)' '<!-- AID:END -->' "$1" > "$2/CLAUDE.md"
}
seed_user_region_c_user() { seed_user_region 'user line below' "$1"; }
seed_user_region_c_nolf() { printf '%s\n' '# Project memory' 'user line above' '<!-- AID:BEGIN -->' "$V3_REGION_BODY" \
        'v3 AID rules (full region body)' '<!-- AID:END -->' > "$1/CLAUDE.md"
    printf 'user line below' >> "$1/CLAUDE.md"; }
seed_nomarker() { printf '%s\n' 'plain user memory' 'no markers here' > "$1/CLAUDE.md"; }
seed_agents_region() { printf '%s\n' '# Agents guide' 'user agents line' '<!-- AID:BEGIN -->' "$V3_REGION_BODY" \
        'v3 AID rules (full region body)' '<!-- AID:END -->' > "$1/AGENTS.md"; }
seed_agents_region_nolf() { printf '%s\n' '<!-- AID:BEGIN -->' "$V3_REGION_BODY" \
        'v3 AID rules (full region body)' '<!-- AID:END -->' > "$1/AGENTS.md"
    printf 'user tail without newline' >> "$1/AGENTS.md"; }

# (c1) user-edited CLAUDE.md with user content above and below the full old region.
root_case ac14-claude-user seed_user_region_c_user
fx="${TMP}/fx-ac14-claude-user"; exp="${TMP}/exp-ac14-claude-user"
printf '%s\n' '# Project memory' 'user line above' 'user line below' > "$exp"; printf '%s' "$IMPORT_REGION" >> "$exp"
if [[ "$RC" -eq 0 ]] && cmp -s "$exp" "$fx/CLAUDE.md" && cmp -s "${V3_PRE}/ac14-claude-user/CLAUDE.md" "$fx/.aid/.trash/CLAUDE.md"; then
    pass "AC-14 (c) claude-code user-edited CLAUDE.md: user bytes kept in order, old region removed, one import region appended, pre-update file at .aid/.trash/CLAUDE.md"
else
    fail "AC-14 (c) claude-code user-edited CLAUDE.md: exact user bytes plus one import region, pre-update file at .aid/.trash/CLAUDE.md — got ${RC}"
fi
# (c1b) same, user content not ending in LF: exactly one LF is inserted before the import region.
root_case ac14-claude-nolf seed_user_region_c_nolf
fx="${TMP}/fx-ac14-claude-nolf"; exp="${TMP}/exp-ac14-claude-nolf"
printf '%s\n' '# Project memory' 'user line above' 'user line below' > "$exp"; printf '%s' "$IMPORT_REGION" >> "$exp"
if [[ "$RC" -eq 0 ]] && cmp -s "$exp" "$fx/CLAUDE.md" && cmp -s "${V3_PRE}/ac14-claude-nolf/CLAUDE.md" "$fx/.aid/.trash/CLAUDE.md"; then
    pass "AC-14 (c) claude-code CLAUDE.md without final LF: one LF inserted before the single import region"
else
    fail "AC-14 (c) claude-code CLAUDE.md without final LF: one LF then one import region — got ${RC}"
fi
# (c2) no-marker CLAUDE.md: pre-update bytes are a byte-exact prefix, only the import region follows.
root_case ac14-claude-nomarker seed_nomarker
fx="${TMP}/fx-ac14-claude-nomarker"; pre="${V3_PRE}/ac14-claude-nomarker/CLAUDE.md"; exp="${TMP}/exp-ac14-nomarker"
cp "$pre" "$exp"; printf '%s' "$IMPORT_REGION" >> "$exp"
if [[ "$RC" -eq 0 ]] && cmp -s "$exp" "$fx/CLAUDE.md"; then
    pass "AC-14 (c) claude-code no-marker CLAUDE.md: pre-update bytes are a byte-exact prefix followed only by the import region"
else
    fail "AC-14 (c) claude-code no-marker CLAUDE.md: pre-update bytes prefix then import region — got ${RC}"
fi
# (c3) v3 AGENTS.md holding the full region: pointer region appended by the same LF rule.
root_case ac14-agents seed_agents_region
fx="${TMP}/fx-ac14-agents"; exp="${TMP}/exp-ac14-agents"
printf '%s\n' '# Agents guide' 'user agents line' > "$exp"; printf '%s' "$POINTER_REGION" >> "$exp"
if [[ "$RC" -eq 0 ]] && cmp -s "$exp" "$fx/AGENTS.md" && cmp -s "${V3_PRE}/ac14-agents/AGENTS.md" "$fx/.aid/.trash/AGENTS.md" \
   && [[ "$(grep -cx '<!-- AID:BEGIN -->' "$fx/AGENTS.md")" == 1 ]]; then
    pass "AC-14 (c) v3 AGENTS.md full region: user bytes kept, pointer region appended, pre-update file at .aid/.trash/AGENTS.md"
else
    fail "AC-14 (c) v3 AGENTS.md full region: user bytes then one pointer region, pre-update file at .aid/.trash/AGENTS.md — got ${RC}"
fi
# (c3b) v3 AGENTS.md whose user text is only the tail after the region (no LF): one LF inserted.
root_case ac14-agents-nolf seed_agents_region_nolf
fx="${TMP}/fx-ac14-agents-nolf"; exp="${TMP}/exp-ac14-agents-nolf"
printf '%s\n' 'user tail without newline' > "$exp"; printf '%s' "$POINTER_REGION" >> "$exp"
if [[ "$RC" -eq 0 ]] && cmp -s "$exp" "$fx/AGENTS.md"; then
    pass "AC-14 (c) v3 AGENTS.md without final LF: one LF inserted before the pointer region"
else
    fail "AC-14 (c) v3 AGENTS.md without final LF: one LF then one pointer region — got ${RC}"
fi
for name in ac14-claude-user ac14-claude-nolf ac14-claude-nomarker ac14-agents ac14-agents-nolf; do
    fx="${TMP}/fx-${name}"
    if [[ "$(grep -cx '@AGENTS.md' "$fx/CLAUDE.md")" == 0 && "$(grep -cx '<!-- AID:BEGIN -->' "$fx/AGENTS.md")" == 1 ]]; then
        pass "AC-14 (c) ${name}: no @AGENTS.md line in CLAUDE.md and one AID:BEGIN line in AGENTS.md"
    else
        fail "AC-14 (c) ${name}: no @AGENTS.md line in CLAUDE.md and one AID:BEGIN line in AGENTS.md"
    fi
    if [[ "$(grep -cx '@.aid/runtime/rules.md' "$fx/CLAUDE.md")" == 1 && "$(grep -c '^@' "$fx/AGENTS.md")" == 0 ]]; then
        pass "AC-14 (c) ${name}: CLAUDE.md imports the rules once and AGENTS.md has no @ line"
    else
        fail "AC-14 (c) ${name}: CLAUDE.md imports the rules once and AGENTS.md has no @ line"
    fi
done

# --- Isolation canary: confirm no real repo was touched ----------------------
echo ""
echo "=== Isolation canary: real HOME untouched ==="
_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
if [[ "${_CANARY_AFTER}" == "${_CANARY_BEFORE}" ]]; then
    pass "ISO-CANARY-01 real HOME (${REAL_HOME}) gained no .aid dirs (no scan escaped throwaway HOME)"
else
    # Report only the NEW dirs (set difference after - before) for a clear signal.
    _CANARY_NEW="$(comm -13 <(printf '%s\n' "${_CANARY_BEFORE}") <(printf '%s\n' "${_CANARY_AFTER}") 2>/dev/null || true)"
    fail "ISO-CANARY-01 real HOME blast surface: NEW .aid dirs appeared under ${REAL_HOME}: ${_CANARY_NEW}"
fi

# ===========================================================================
test_summary
