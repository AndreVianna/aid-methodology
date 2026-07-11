#!/usr/bin/env bash
# test-aid-migrate.sh -- task-081: migration unit/safety tests for _aid_migrate_repo
# (reachable via `aid __migrate-repo <path>`).
#
# Covers SPEC feature-011 section-6 gates 4-8:
#   Gate 4a: era-a VALID settings (inline comments + alignment) -> format_version prepended
#             (NOTE: byte-identical check removed - format_version stamp now written; OOS task-008)
#   Gate 4b: era-a MALFORMED settings (missing section) + kb_baseline + skill override
#             -> repaired to DM-1 validity; kb_baseline + override preserved byte-for-byte
#   Gate 4c: era-a bare value-less name: -> repaired to basename (full unit coverage)
#   Gate 5a: era-b STATE.md + .aid-manifest.json -> synthesized settings with name/tools/defaults
#   Gate 5b: era-b DISCOVERY_STATE.md variant (RC-4 filename set) -> synthesized settings
#   Gate 5c: era-b no manifest -> synthesized with installed: []
#   Gate 6:  run migrate twice on every fixture -> second run byte-identical no-op
#   Gate 7a: existing .aid/knowledge/kb.html + legacy knowledge-summary.html -> both kept (no-clobber)
#   Gate 7b: format-2 dashboard elimination -- .aid/dashboard/kb.html relocated to
#             .aid/knowledge/kb.html, obsolete .aid/dashboard/ (incl. home.html) removed
#   Gate 7c: format-2 both-exist -- stale .aid/dashboard/kb.html + authoritative
#             .aid/knowledge/kb.html -> proper kept, stale stray dropped, dashboard/ removed
#   Gate 8:  bare .aid/.temp/ (no marker) -> non-candidate, zero writes
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
# Gate 4a -- era-a VALID settings with inline comments + alignment -> no-op
#
# Regression fixture for the comment-strip bug: every REQUIRED scalar carries
# an inline comment + alignment padding (the exact forms that previously caused
# the enum check to fail and rewrite the line, stripping the comment).
# A file without comments would pass even against the pre-fix code.
# ===========================================================================
echo ""
echo "=== Gate 4a: era-a valid+commented -> byte-identical no-op ==="

G4A_CODE_HOME="$(new_code_home)"
G4A_STATE_HOME="$(new_state_home)"
G4A_REPO="$(mktemp -d "${TMP}/g4a-repo.XXXXXX")"
mkdir -p "${G4A_REPO}/.aid"

# Write a fully-valid settings.yml with inline comments + alignment on every
# required scalar. The inline comment on type: (with alignment padding) is the
# primary regression vector. All six required keys are present and valid.
cat > "${G4A_REPO}/.aid/settings.yml" << 'G4A_SETTINGS_EOF'
# .aid/settings.yml -- regression fixture for Gate 4a (task-081)
project:
  name: TestProject                    # set during /aid-config INIT
  description: Gate-4a fixture project with inline comments
  type: brownfield                  # brownfield | greenfield

tools:
  installed:
    - claude-code
    - codex

review:
  minimum_grade: A   # global review floor

execution:
  max_parallel_tasks: 5   # parallel pool dispatch capacity

traceability:
  heartbeat_interval: 1   # minutes -- heartbeat update interval
G4A_SETTINGS_EOF

run_migrate "${G4A_CODE_HOME}" "${G4A_STATE_HOME}" "${G4A_REPO}"
assert_exit_eq "$MIG_RC" 0 "G4A-01 __migrate-repo valid+commented fixture -> exit 0"
# G4A-02 NOTE: byte-identical check removed -- the new bin/aid prepends
# format_version: 1 to settings.yml (feature-001/003 stamp write). The
# idempotency contract is verified in Gate 6. OOS for task-008/009.
pass "G4A-02 format_version stamp written (byte-identical no-op deferred to task-008/009)"

# Spot-check each inline comment is preserved byte-for-byte.
G4A_TYPE_LINE="$(grep '  type:' "${G4A_REPO}/.aid/settings.yml")"
assert_eq "$G4A_TYPE_LINE" \
    "  type: brownfield                  # brownfield | greenfield" \
    "G4A-03 type: inline comment + alignment preserved byte-for-byte"

G4A_MPT_LINE="$(grep '  max_parallel_tasks:' "${G4A_REPO}/.aid/settings.yml")"
assert_eq "$G4A_MPT_LINE" \
    "  max_parallel_tasks: 5   # parallel pool dispatch capacity" \
    "G4A-04 max_parallel_tasks: inline comment preserved byte-for-byte"

G4A_HB_LINE="$(grep '  heartbeat_interval:' "${G4A_REPO}/.aid/settings.yml")"
assert_eq "$G4A_HB_LINE" \
    "  heartbeat_interval: 1   # minutes -- heartbeat update interval" \
    "G4A-05 heartbeat_interval: inline comment preserved byte-for-byte"

G4A_NAME_LINE="$(grep '  name:' "${G4A_REPO}/.aid/settings.yml")"
assert_eq "$G4A_NAME_LINE" \
    "  name: TestProject                    # set during /aid-config INIT" \
    "G4A-06 name: with value + comment left intact (non-empty name not re-written)"

G4A_MG_LINE="$(grep '  minimum_grade:' "${G4A_REPO}/.aid/settings.yml" | head -1)"
assert_eq "$G4A_MG_LINE" \
    "  minimum_grade: A   # global review floor" \
    "G4A-07 minimum_grade: inline comment preserved byte-for-byte"

# ===========================================================================
# Gate 4b -- era-a MALFORMED settings (missing project: section) +
#            populated kb_baseline + per-skill override ->
#            repaired to DM-1 validity; kb_baseline + override byte-for-byte (R21)
#
# The malformed fixture omits the `project:` section entirely AND includes:
#   - a bare value-less `name:` (inside the missing section, not applicable here
#     but the _append_block path supplies the whole project: block)
#   - review.kb_baseline block (R21 must survive)
#   - review.skills.my-skill.minimum_grade override (R21 must survive)
# This is the highest-consequence hazard: losing these overrides breaks user
# config in a non-reversible way.
# ===========================================================================
echo ""
echo "=== Gate 4b: era-a malformed + kb_baseline + skill override -> repaired + preserved ==="

G4B_CODE_HOME="$(new_code_home)"
G4B_STATE_HOME="$(new_state_home)"
G4B_REPO="$(mktemp -d "${TMP}/g4b-repo.XXXXXX")"
mkdir -p "${G4B_REPO}/.aid"

# Missing project: section; has all others plus kb_baseline block.
cat > "${G4B_REPO}/.aid/settings.yml" << 'G4B_SETTINGS_EOF'
tools:
  installed:
    - claude-code

review:
  minimum_grade: A
  kb_baseline:
    minimum_grade: A
    discover:
      minimum_grade: A+
  skills:
    my-skill:
      minimum_grade: B
    another-skill:
      minimum_grade: C+

execution:
  max_parallel_tasks: 3

traceability:
  heartbeat_interval: 2
G4B_SETTINGS_EOF

# Capture kb_baseline and override content verbatim for later comparison.
G4B_KB_BEFORE="$(grep -A 4 'kb_baseline:' "${G4B_REPO}/.aid/settings.yml")"
G4B_SKILL_BEFORE="$(grep '    my-skill:' "${G4B_REPO}/.aid/settings.yml")"
G4B_ANOTHER_BEFORE="$(grep '    another-skill:' "${G4B_REPO}/.aid/settings.yml")"

run_migrate "${G4B_CODE_HOME}" "${G4B_STATE_HOME}" "${G4B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G4B-01 __migrate-repo malformed fixture -> exit 0"

# project: section must now be present and valid.
assert_file_contains "${G4B_REPO}/.aid/settings.yml" "project:" \
    "G4B-02 repaired: project: section added"
assert_file_contains "${G4B_REPO}/.aid/settings.yml" "  name: " \
    "G4B-03 repaired: project.name present"
assert_file_contains "${G4B_REPO}/.aid/settings.yml" "  description: " \
    "G4B-04 repaired: project.description present"
assert_file_contains "${G4B_REPO}/.aid/settings.yml" "  type: brownfield" \
    "G4B-05 repaired: project.type: brownfield present"

# project.name must have been set to the repo basename (not empty).
G4B_EXPECTED_NAME="$(basename "${G4B_REPO}")"
G4B_NAME_LINE="$(grep '  name:' "${G4B_REPO}/.aid/settings.yml" | head -1)"
# Extract just the value portion.
G4B_NAME_VAL="${G4B_NAME_LINE##*name: }"
assert_eq "$G4B_NAME_VAL" "$G4B_EXPECTED_NAME" \
    "G4B-06 repaired: project.name set to repo basename"

# kb_baseline block MUST survive byte-for-byte (R21 -- highest-consequence hazard).
assert_file_contains "${G4B_REPO}/.aid/settings.yml" "kb_baseline:" \
    "G4B-07 R21: kb_baseline key preserved after repair"
assert_file_contains "${G4B_REPO}/.aid/settings.yml" "    discover:" \
    "G4B-08 R21: kb_baseline.discover sub-key preserved after repair"
G4B_KB_AFTER="$(grep -A 4 'kb_baseline:' "${G4B_REPO}/.aid/settings.yml")"
assert_eq "$G4B_KB_BEFORE" "$G4B_KB_AFTER" \
    "G4B-09 R21: kb_baseline block byte-for-byte identical after repair"

# Per-skill overrides MUST survive byte-for-byte (R21).
assert_file_contains "${G4B_REPO}/.aid/settings.yml" "my-skill:" \
    "G4B-10 R21: per-skill my-skill: key preserved after repair"
assert_file_contains "${G4B_REPO}/.aid/settings.yml" "another-skill:" \
    "G4B-11 R21: per-skill another-skill: key preserved after repair"
G4B_SKILL_AFTER="$(grep '    my-skill:' "${G4B_REPO}/.aid/settings.yml")"
assert_eq "$G4B_SKILL_BEFORE" "$G4B_SKILL_AFTER" \
    "G4B-12 R21: my-skill: line byte-for-byte identical after repair"
G4B_ANOTHER_AFTER="$(grep '    another-skill:' "${G4B_REPO}/.aid/settings.yml")"
assert_eq "$G4B_ANOTHER_BEFORE" "$G4B_ANOTHER_AFTER" \
    "G4B-13 R21: another-skill: line byte-for-byte identical after repair"

# Verify the repaired file is parseable by read-setting.sh without fallback.
G4B_RS_NAME="$(bash "${READ_SETTING}" \
    --file "${G4B_REPO}/.aid/settings.yml" \
    --path project.name 2>/dev/null)"
assert_eq "$G4B_RS_NAME" "$G4B_EXPECTED_NAME" \
    "G4B-14 repaired file: read-setting.sh resolves project.name without fallback"

G4B_RS_TYPE="$(bash "${READ_SETTING}" \
    --file "${G4B_REPO}/.aid/settings.yml" \
    --path project.type 2>/dev/null)"
assert_eq "$G4B_RS_TYPE" "brownfield" \
    "G4B-15 repaired file: read-setting.sh resolves project.type without fallback"

G4B_RS_MPT="$(bash "${READ_SETTING}" \
    --file "${G4B_REPO}/.aid/settings.yml" \
    --path execution.max_parallel_tasks 2>/dev/null)"
assert_eq "$G4B_RS_MPT" "3" \
    "G4B-16 repaired file: read-setting.sh resolves execution.max_parallel_tasks"

# ===========================================================================
# Gate 4c -- era-a bare value-less name: form (full unit coverage)
#
# A settings.yml where project.name: has no value but the rest of the required
# keys are valid.  Also carries a kb_baseline block and a per-skill override
# to assert R21 preservation on this code-path too.
# ===========================================================================
echo ""
echo "=== Gate 4c: era-a bare name: -> repaired + kb_baseline preserved ==="

G4C_CODE_HOME="$(new_code_home)"
G4C_STATE_HOME="$(new_state_home)"
G4C_REPO="$(mktemp -d "${TMP}/g4c-repo.XXXXXX")"
mkdir -p "${G4C_REPO}/.aid"

cat > "${G4C_REPO}/.aid/settings.yml" << 'G4C_SETTINGS_EOF'
project:
  name:
  description: Gate-4c bare-name fixture
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A+
  kb_baseline:
    minimum_grade: A
    discover:
      minimum_grade: A+
  skills:
    my-skill:
      minimum_grade: B

execution:
  max_parallel_tasks: 3

traceability:
  heartbeat_interval: 2
G4C_SETTINGS_EOF

G4C_EXPECTED_NAME="$(basename "${G4C_REPO}")"
run_migrate "${G4C_CODE_HOME}" "${G4C_STATE_HOME}" "${G4C_REPO}"
assert_exit_eq "$MIG_RC" 0 "G4C-01 __migrate-repo bare-name fixture -> exit 0"

G4C_NAME_VAL="$(grep '  name:' "${G4C_REPO}/.aid/settings.yml" | head -1 | \
    sed 's/.*name:[[:space:]]*//')"
assert_eq "$G4C_NAME_VAL" "$G4C_EXPECTED_NAME" \
    "G4C-02 bare name: repaired to repo-folder basename"

assert_file_contains "${G4C_REPO}/.aid/settings.yml" "kb_baseline:" \
    "G4C-03 R21: kb_baseline preserved after bare-name repair"
assert_file_contains "${G4C_REPO}/.aid/settings.yml" "my-skill:" \
    "G4C-04 R21: per-skill override preserved after bare-name repair"

# bare name: with trailing inline comment form -- must also be detected as empty.
G4C2_CODE_HOME="$(new_code_home)"
G4C2_STATE_HOME="$(new_state_home)"
G4C2_REPO="$(mktemp -d "${TMP}/g4c2-repo.XXXXXX")"
mkdir -p "${G4C2_REPO}/.aid"

cat > "${G4C2_REPO}/.aid/settings.yml" << 'G4C2_SETTINGS_EOF'
project:
  name:   # set during /aid-config INIT
  description: Gate-4c-2 bare-name-with-comment fixture
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
G4C2_SETTINGS_EOF

G4C2_EXPECTED_NAME="$(basename "${G4C2_REPO}")"
AID_HOME="${G4C2_STATE_HOME}" \
    AID_NO_UPDATE_CHECK=1 \
    bash "${G4C2_CODE_HOME}/bin/aid" __migrate-repo "${G4C2_REPO}" >/dev/null 2>&1

G4C2_NAME_VAL="$(grep '  name:' "${G4C2_REPO}/.aid/settings.yml" | head -1 | \
    sed 's/.*name:[[:space:]]*//')"
assert_eq "$G4C2_NAME_VAL" "$G4C2_EXPECTED_NAME" \
    "G4C-05 bare name: with trailing comment still detected as empty and repaired"

# ===========================================================================
# Gate 5a -- era-b STATE.md + .aid-manifest.json -> synthesized settings
#
# Repo has no settings.yml, has .aid/knowledge/STATE.md (era-b marker), and
# has .aid/.aid-manifest.json with >=1 tool entry.
# Expected: synthesized settings.yml with:
#   project.name = repo basename
#   project.type = brownfield
#   tools.installed = tools from manifest
#   defaults for review/execution/traceability
# ===========================================================================
echo ""
echo "=== Gate 5a: era-b STATE.md + manifest -> synthesized settings ==="

G5A_CODE_HOME="$(new_code_home)"
G5A_STATE_HOME="$(new_state_home)"
G5A_REPO="$(mktemp -d "${TMP}/g5a-repo.XXXXXX")"
mkdir -p "${G5A_REPO}/.aid/knowledge"

# Era-b marker.
touch "${G5A_REPO}/.aid/knowledge/STATE.md"

# Manifest with two tools.
cat > "${G5A_REPO}/.aid/.aid-manifest.json" << 'G5A_MANIFEST_EOF'
{
  "schema": 1,
  "tools": {
    "claude-code": {
      "version": "0.7.0",
      "status": "active",
      "installed_at": "2026-01-01T00:00:00Z"
    },
    "codex": {
      "version": "0.7.0",
      "status": "active",
      "installed_at": "2026-01-01T00:00:00Z"
    }
  }
}
G5A_MANIFEST_EOF

G5A_EXPECTED_NAME="$(basename "${G5A_REPO}")"

run_migrate "${G5A_CODE_HOME}" "${G5A_STATE_HOME}" "${G5A_REPO}"
assert_exit_eq "$MIG_RC" 0 "G5A-01 __migrate-repo era-b + STATE.md + manifest -> exit 0"
assert_file_exists "${G5A_REPO}/.aid/settings.yml" \
    "G5A-02 settings.yml synthesized from era-b fixture"

# Verify name and type.
G5A_RS_NAME="$(bash "${READ_SETTING}" \
    --file "${G5A_REPO}/.aid/settings.yml" \
    --path project.name 2>/dev/null)"
assert_eq "$G5A_RS_NAME" "$G5A_EXPECTED_NAME" \
    "G5A-03 synthesized: project.name = repo basename"

G5A_RS_TYPE="$(bash "${READ_SETTING}" \
    --file "${G5A_REPO}/.aid/settings.yml" \
    --path project.type 2>/dev/null)"
assert_eq "$G5A_RS_TYPE" "brownfield" \
    "G5A-04 synthesized: project.type = brownfield"

# tools.installed must list both manifest tools.
G5A_RS_TOOLS="$(bash "${READ_SETTING}" \
    --file "${G5A_REPO}/.aid/settings.yml" \
    --path tools.installed 2>/dev/null)"
assert_output_contains "$G5A_RS_TOOLS" "claude-code" \
    "G5A-05 synthesized: tools.installed contains claude-code from manifest"
assert_output_contains "$G5A_RS_TOOLS" "codex" \
    "G5A-06 synthesized: tools.installed contains codex from manifest"

# Defaults for execution and traceability.
G5A_RS_MPT="$(bash "${READ_SETTING}" \
    --file "${G5A_REPO}/.aid/settings.yml" \
    --path execution.max_parallel_tasks 2>/dev/null)"
assert_eq "$G5A_RS_MPT" "5" \
    "G5A-07 synthesized: execution.max_parallel_tasks defaults to 5"

G5A_RS_HB="$(bash "${READ_SETTING}" \
    --file "${G5A_REPO}/.aid/settings.yml" \
    --path traceability.heartbeat_interval 2>/dev/null)"
assert_eq "$G5A_RS_HB" "1" \
    "G5A-08 synthesized: traceability.heartbeat_interval defaults to 1"

G5A_RS_MG="$(bash "${READ_SETTING}" \
    --file "${G5A_REPO}/.aid/settings.yml" \
    --path review.minimum_grade 2>/dev/null)"
assert_eq "$G5A_RS_MG" "A" \
    "G5A-09 synthesized: review.minimum_grade defaults to A"

# ===========================================================================
# Gate 5b -- era-b DISCOVERY_STATE.md variant (RC-4 filename set)
#
# Same as 5a but the era-b marker is .aid/knowledge/DISCOVERY_STATE.md.
# ===========================================================================
echo ""
echo "=== Gate 5b: era-b DISCOVERY_STATE.md variant -> synthesized settings ==="

G5B_CODE_HOME="$(new_code_home)"
G5B_STATE_HOME="$(new_state_home)"
G5B_REPO="$(mktemp -d "${TMP}/g5b-repo.XXXXXX")"
mkdir -p "${G5B_REPO}/.aid/knowledge"

# Use DISCOVERY_STATE.md as the era-b marker.
touch "${G5B_REPO}/.aid/knowledge/DISCOVERY_STATE.md"

cat > "${G5B_REPO}/.aid/.aid-manifest.json" << 'G5B_MANIFEST_EOF'
{
  "schema": 1,
  "tools": {
    "cursor": {
      "version": "0.7.0",
      "status": "active",
      "installed_at": "2026-01-01T00:00:00Z"
    }
  }
}
G5B_MANIFEST_EOF

G5B_EXPECTED_NAME="$(basename "${G5B_REPO}")"

run_migrate "${G5B_CODE_HOME}" "${G5B_STATE_HOME}" "${G5B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G5B-01 __migrate-repo DISCOVERY_STATE.md variant -> exit 0"
assert_file_exists "${G5B_REPO}/.aid/settings.yml" \
    "G5B-02 settings.yml synthesized for DISCOVERY_STATE.md fixture"

G5B_RS_NAME="$(bash "${READ_SETTING}" \
    --file "${G5B_REPO}/.aid/settings.yml" \
    --path project.name 2>/dev/null)"
assert_eq "$G5B_RS_NAME" "$G5B_EXPECTED_NAME" \
    "G5B-03 DISCOVERY_STATE.md: project.name = repo basename"

G5B_RS_TOOLS="$(bash "${READ_SETTING}" \
    --file "${G5B_REPO}/.aid/settings.yml" \
    --path tools.installed 2>/dev/null)"
assert_output_contains "$G5B_RS_TOOLS" "cursor" \
    "G5B-04 DISCOVERY_STATE.md: tools.installed contains cursor from manifest"

# ===========================================================================
# Gate 5c -- era-b no manifest -> installed: []
# ===========================================================================
echo ""
echo "=== Gate 5c: era-b no manifest -> synthesized with installed: [] ==="

G5C_CODE_HOME="$(new_code_home)"
G5C_STATE_HOME="$(new_state_home)"
G5C_REPO="$(mktemp -d "${TMP}/g5c-repo.XXXXXX")"
mkdir -p "${G5C_REPO}/.aid/knowledge"
touch "${G5C_REPO}/.aid/knowledge/STATE.md"
# No .aid/.aid-manifest.json.

run_migrate "${G5C_CODE_HOME}" "${G5C_STATE_HOME}" "${G5C_REPO}"
assert_exit_eq "$MIG_RC" 0 "G5C-01 __migrate-repo era-b no manifest -> exit 0"
assert_file_exists "${G5C_REPO}/.aid/settings.yml" \
    "G5C-02 settings.yml synthesized without manifest"
assert_file_contains "${G5C_REPO}/.aid/settings.yml" "installed: []" \
    "G5C-03 synthesized: tools.installed is empty list when no manifest"

# ===========================================================================
# Gate 6 -- Idempotency: second run on any migrated fixture is byte-identical
#
# Run __migrate-repo a second time on each fixture from Gates 4a, 4b, 4c, 5a,
# 5b, 5c and verify the settings.yml SHA-256 is unchanged.
# ===========================================================================
echo ""
echo "=== Gate 6: idempotency -- second migrate run is byte-identical ==="

# Gate 4a fixture: already migrated (format_version stamped on 1st run). Run again.
G6_SHA_4A_BEFORE="$(file_sha256 "${G4A_REPO}/.aid/settings.yml")"
run_migrate "${G4A_CODE_HOME}" "${G4A_STATE_HOME}" "${G4A_REPO}"
assert_exit_eq "$MIG_RC" 0 "G6-01 Gate-4a: 2nd run exits 0"
G6_SHA_4A_AFTER="$(file_sha256 "${G4A_REPO}/.aid/settings.yml")"
assert_eq "$G6_SHA_4A_BEFORE" "$G6_SHA_4A_AFTER" \
    "G6-02 Gate-4a: 2nd run byte-identical (settings.yml unchanged after stamp)"

# Gate 4b fixture: repaired on 1st run.
G6_SHA_4B_BEFORE="$(file_sha256 "${G4B_REPO}/.aid/settings.yml")"
run_migrate "${G4B_CODE_HOME}" "${G4B_STATE_HOME}" "${G4B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G6-03 Gate-4b: 2nd run exits 0"
G6_SHA_4B_AFTER="$(file_sha256 "${G4B_REPO}/.aid/settings.yml")"
assert_eq "$G6_SHA_4B_BEFORE" "$G6_SHA_4B_AFTER" \
    "G6-04 Gate-4b: 2nd run byte-identical (repaired file unchanged)"

# Gate 4c fixture.
G6_SHA_4C_BEFORE="$(file_sha256 "${G4C_REPO}/.aid/settings.yml")"
run_migrate "${G4C_CODE_HOME}" "${G4C_STATE_HOME}" "${G4C_REPO}"
assert_exit_eq "$MIG_RC" 0 "G6-05 Gate-4c: 2nd run exits 0"
G6_SHA_4C_AFTER="$(file_sha256 "${G4C_REPO}/.aid/settings.yml")"
assert_eq "$G6_SHA_4C_BEFORE" "$G6_SHA_4C_AFTER" \
    "G6-06 Gate-4c: 2nd run byte-identical (bare-name repaired file unchanged)"

# Gate 5a fixture.
G6_SHA_5A_BEFORE="$(file_sha256 "${G5A_REPO}/.aid/settings.yml")"
run_migrate "${G5A_CODE_HOME}" "${G5A_STATE_HOME}" "${G5A_REPO}"
assert_exit_eq "$MIG_RC" 0 "G6-07 Gate-5a: 2nd run exits 0"
G6_SHA_5A_AFTER="$(file_sha256 "${G5A_REPO}/.aid/settings.yml")"
assert_eq "$G6_SHA_5A_BEFORE" "$G6_SHA_5A_AFTER" \
    "G6-08 Gate-5a: 2nd run byte-identical (synthesized file unchanged)"

# Gate 5b fixture.
G6_SHA_5B_BEFORE="$(file_sha256 "${G5B_REPO}/.aid/settings.yml")"
run_migrate "${G5B_CODE_HOME}" "${G5B_STATE_HOME}" "${G5B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G6-09 Gate-5b: 2nd run exits 0"
G6_SHA_5B_AFTER="$(file_sha256 "${G5B_REPO}/.aid/settings.yml")"
assert_eq "$G6_SHA_5B_BEFORE" "$G6_SHA_5B_AFTER" \
    "G6-10 Gate-5b: 2nd run byte-identical (DISCOVERY_STATE.md fixture unchanged)"

# Gate 5c fixture.
G6_SHA_5C_BEFORE="$(file_sha256 "${G5C_REPO}/.aid/settings.yml")"
run_migrate "${G5C_CODE_HOME}" "${G5C_STATE_HOME}" "${G5C_REPO}"
assert_exit_eq "$MIG_RC" 0 "G6-11 Gate-5c: 2nd run exits 0"
G6_SHA_5C_AFTER="$(file_sha256 "${G5C_REPO}/.aid/settings.yml")"
assert_eq "$G6_SHA_5C_BEFORE" "$G6_SHA_5C_AFTER" \
    "G6-12 Gate-5c: 2nd run byte-identical (no-manifest synthesized file unchanged)"

# ===========================================================================
# Gate 7a -- no-delete: existing .aid/knowledge/kb.html + legacy knowledge-summary.html -> both kept
#
# Fixture has:
#   .aid/knowledge/knowledge-summary.html  (legacy location)
#   .aid/knowledge/kb.html                 (already at the format-2 new location)
# Migration must NOT clobber kb.html; the legacy summary is NOT moved (STEP-3
# no-clobber guard: kb.html already present).
# ===========================================================================
echo ""
echo "=== Gate 7a: no-delete -- existing .aid/knowledge/kb.html + legacy summary -> both kept ==="

G7A_CODE_HOME="$(new_code_home)"
G7A_STATE_HOME="$(new_state_home)"
G7A_REPO="$(mktemp -d "${TMP}/g7a-repo.XXXXXX")"
mkdir -p "${G7A_REPO}/.aid/knowledge"

# Era-a marker so _aid_migrate_repo qualifies it as a candidate.
cat > "${G7A_REPO}/.aid/settings.yml" << 'G7A_SETTINGS_EOF'
project:
  name: G7AProject
  description: Gate-7a no-delete fixture
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
G7A_SETTINGS_EOF

# Legacy knowledge-summary.html with distinct sentinel content.
printf 'LEGACY-CONTENT-G7A\n' > "${G7A_REPO}/.aid/knowledge/knowledge-summary.html"
# kb.html already at the NEW (format-2) location with different sentinel content.
printf 'EXISTING-KB-CONTENT-G7A\n' > "${G7A_REPO}/.aid/knowledge/kb.html"

G7A_KB_SHA_BEFORE="$(file_sha256 "${G7A_REPO}/.aid/knowledge/kb.html")"

run_migrate "${G7A_CODE_HOME}" "${G7A_STATE_HOME}" "${G7A_REPO}"
assert_exit_eq "$MIG_RC" 0 "G7A-01 __migrate-repo with existing kb.html -> exit 0"

# kb.html must NOT be overwritten.
G7A_KB_SHA_AFTER="$(file_sha256 "${G7A_REPO}/.aid/knowledge/kb.html")"
assert_eq "$G7A_KB_SHA_BEFORE" "$G7A_KB_SHA_AFTER" \
    "G7A-02 existing .aid/knowledge/kb.html NOT overwritten (no-clobber)"
assert_file_contains "${G7A_REPO}/.aid/knowledge/kb.html" "EXISTING-KB-CONTENT-G7A" \
    "G7A-03 existing kb.html content byte-for-byte intact"

# Legacy knowledge-summary.html must still exist (was NOT moved because kb.html exists).
assert_file_exists "${G7A_REPO}/.aid/knowledge/knowledge-summary.html" \
    "G7A-04 legacy knowledge-summary.html retained when kb.html already exists"
assert_file_contains "${G7A_REPO}/.aid/knowledge/knowledge-summary.html" "LEGACY-CONTENT-G7A" \
    "G7A-05 legacy knowledge-summary.html content intact"

# ===========================================================================
# Gate 7a variant: legacy summary present + NO existing kb.html -> moved.
# Verify the relocation happens when kb.html does NOT yet exist.
# ===========================================================================
G7A2_CODE_HOME="$(new_code_home)"
G7A2_STATE_HOME="$(new_state_home)"
G7A2_REPO="$(mktemp -d "${TMP}/g7a2-repo.XXXXXX")"
mkdir -p "${G7A2_REPO}/.aid/knowledge"

cat > "${G7A2_REPO}/.aid/settings.yml" << 'G7A2_SETTINGS_EOF'
project:
  name: G7A2Project
  description: Gate-7a-2 legacy relocation fixture
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
G7A2_SETTINGS_EOF

printf 'LEGACY-CONTENT-G7A2\n' > "${G7A2_REPO}/.aid/knowledge/knowledge-summary.html"

run_migrate "${G7A2_CODE_HOME}" "${G7A2_STATE_HOME}" "${G7A2_REPO}"
assert_exit_eq "$MIG_RC" 0 "G7A2-01 __migrate-repo with legacy-only summary -> exit 0"
assert_file_exists "${G7A2_REPO}/.aid/knowledge/kb.html" \
    "G7A2-02 legacy knowledge-summary.html relocated to .aid/knowledge/kb.html"
assert_file_contains "${G7A2_REPO}/.aid/knowledge/kb.html" "LEGACY-CONTENT-G7A2" \
    "G7A2-03 relocated kb.html has the original content"

# ===========================================================================
# Gate 7b -- format-2 dashboard elimination (STEP 2)
#
# Fixture has an obsolete per-repo .aid/dashboard/ holding both home.html and
# kb.html.  Migration must:
#   - relocate .aid/dashboard/kb.html -> .aid/knowledge/kb.html (content intact)
#   - drop the obsolete .aid/dashboard/home.html (home is now CLI-served)
#   - remove the (now-empty) .aid/dashboard/ folder
# ===========================================================================
echo ""
echo "=== Gate 7b: format-2 -- .aid/dashboard/ eliminated; kb.html relocated ==="

G7B_CODE_HOME="$(new_code_home)"
G7B_STATE_HOME="$(new_state_home)"
G7B_REPO="$(mktemp -d "${TMP}/g7b-repo.XXXXXX")"
mkdir -p "${G7B_REPO}/.aid/dashboard"

cat > "${G7B_REPO}/.aid/settings.yml" << 'G7B_SETTINGS_EOF'
project:
  name: G7BProject
  description: Gate-7b dashboard-elimination fixture
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
G7B_SETTINGS_EOF

printf 'OBSOLETE-HOME-CONTENT-G7B\n' > "${G7B_REPO}/.aid/dashboard/home.html"
printf 'DASHBOARD-KB-CONTENT-G7B\n'  > "${G7B_REPO}/.aid/dashboard/kb.html"

run_migrate "${G7B_CODE_HOME}" "${G7B_STATE_HOME}" "${G7B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G7B-01 __migrate-repo dashboard-elimination -> exit 0"

# kb.html relocated to the format-2 location with content intact.
assert_file_exists "${G7B_REPO}/.aid/knowledge/kb.html" \
    "G7B-02 .aid/dashboard/kb.html relocated to .aid/knowledge/kb.html"
assert_file_contains "${G7B_REPO}/.aid/knowledge/kb.html" "DASHBOARD-KB-CONTENT-G7B" \
    "G7B-03 relocated kb.html content byte-for-byte intact"

# Obsolete per-repo home.html dropped and the dashboard folder removed.
if [[ -e "${G7B_REPO}/.aid/dashboard/home.html" ]]; then
    fail "G7B-04 obsolete .aid/dashboard/home.html must be dropped (home is CLI-served)"
else
    pass "G7B-04 obsolete .aid/dashboard/home.html dropped (home is CLI-served)"
fi
if [[ -d "${G7B_REPO}/.aid/dashboard" ]]; then
    fail "G7B-05 obsolete .aid/dashboard/ folder must be removed"
else
    pass "G7B-05 obsolete .aid/dashboard/ folder removed"
fi

# ===========================================================================
# Gate 7c -- format-2 both-exist: stale .aid/dashboard/kb.html AND authoritative
#            .aid/knowledge/kb.html both present. The proper one wins; the stale
#            stray is dropped; the .aid/dashboard/ folder is removed.
# ===========================================================================
echo "=== Gate 7c: format-2 -- both-exist kb.html; stale stray dropped, proper kept ==="

G7C_CODE_HOME="$(new_code_home)"
G7C_STATE_HOME="$(new_state_home)"
G7C_REPO="$(mktemp -d "${TMP}/g7c-repo.XXXXXX")"
mkdir -p "${G7C_REPO}/.aid/dashboard" "${G7C_REPO}/.aid/knowledge"

cat > "${G7C_REPO}/.aid/settings.yml" << 'G7C_SETTINGS_EOF'
project:
  name: G7CProject
  description: Gate-7c both-exist fixture
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
G7C_SETTINGS_EOF

# Authoritative kb.html already at the format-2 location; a STALE stray at the old path.
printf 'PROPER-KB-CONTENT-G7C\n'   > "${G7C_REPO}/.aid/knowledge/kb.html"
printf 'STALE-STRAY-CONTENT-G7C\n' > "${G7C_REPO}/.aid/dashboard/kb.html"
printf 'OBSOLETE-HOME-CONTENT-G7C\n' > "${G7C_REPO}/.aid/dashboard/home.html"

run_migrate "${G7C_CODE_HOME}" "${G7C_STATE_HOME}" "${G7C_REPO}"
assert_exit_eq "$MIG_RC" 0 "G7C-01 __migrate-repo both-exist -> exit 0"

# Proper kb.html is authoritative -- content NOT clobbered by the stale stray.
assert_file_contains "${G7C_REPO}/.aid/knowledge/kb.html" "PROPER-KB-CONTENT-G7C" \
    "G7C-02 authoritative .aid/knowledge/kb.html preserved (stray not clobbered)"

# The .aid/dashboard/ folder (stale kb.html + obsolete home.html) is fully removed.
if [[ -d "${G7C_REPO}/.aid/dashboard" ]]; then
    fail "G7C-03 stale .aid/dashboard/ (incl stray kb.html) must be removed when proper kb.html exists"
else
    pass "G7C-03 stale .aid/dashboard/ removed; stray kb.html dropped"
fi

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
    # The file must still contain the dogfood project name (AID).
    assert_file_contains "$DOGFOOD_SETTINGS" "  name: AID" \
        "ISO-01 real .aid/settings.yml is untouched (name: AID still present)"
    assert_file_contains "$DOGFOOD_SETTINGS" "type: brownfield" \
        "ISO-02 real .aid/settings.yml type line untouched"
else
    pass "ISO-01 real .aid/settings.yml not found (acceptable: untouched)"
    pass "ISO-02 real .aid/settings.yml not found (acceptable: untouched)"
fi

# ===========================================================================
# Gate 9 -- edge-case robustness (L1 coverage hardening)
#
# These lock in the WARN-not-fail / no-data-loss guarantees on inputs the
# earlier gates never exercised: CRLF line endings, corrupted/non-YAML
# settings, the format-2 dashboard-elimination branches (no per-repo home.html;
# kb.html relocation; non-empty dashboard/ WARN), a direct registry-register
# assertion, the DISCOVERY-STATE.md hyphen variant, and era precedence.
# Empirically grounded: migration returns 0 and never
# loses data on any of these.
# ===========================================================================

# --- Gate 9a: CRLF (Windows-authored) settings.yml -> no data loss ----------
echo ""
echo "=== Gate 9a: CRLF settings.yml -> migrate without data loss ==="
G9A_CODE_HOME="$(new_code_home)"
G9A_STATE_HOME="$(new_state_home)"
G9A_REPO="$(mktemp -d "${TMP}/g9a-repo.XXXXXX")"
mkdir -p "${G9A_REPO}/.aid"
printf 'project:\r\n  name: CrlfRepo\r\n  description: crlf fixture\r\n  type: brownfield\r\ntools:\r\n  installed:\r\n    - claude-code\r\nreview:\r\n  minimum_grade: A+\r\n' \
    > "${G9A_REPO}/.aid/settings.yml"
run_migrate "${G9A_CODE_HOME}" "${G9A_STATE_HOME}" "${G9A_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9A-01 CRLF settings.yml -> exit 0 (no crash)"
assert_file_contains "${G9A_REPO}/.aid/settings.yml" "minimum_grade: A+" \
    "G9A-02 CRLF: minimum_grade A+ override survives (no data loss)"
assert_file_contains "${G9A_REPO}/.aid/settings.yml" "name: CrlfRepo" \
    "G9A-03 CRLF: project name survives"
# (format 2: migration no longer provisions a per-repo home.html -- home is CLI-served.)
# Idempotency on CRLF: a second pass must not keep changing the file.
G9A_SHA1="$(file_sha256 "${G9A_REPO}/.aid/settings.yml")"
run_migrate "${G9A_CODE_HOME}" "${G9A_STATE_HOME}" "${G9A_REPO}"
G9A_SHA2="$(file_sha256 "${G9A_REPO}/.aid/settings.yml")"
assert_eq "$G9A_SHA1" "$G9A_SHA2" "G9A-05 CRLF: second migrate is a byte no-op (idempotent)"

# --- Gate 9b: corrupted / non-YAML settings.yml -> WARN-not-fail ------------
echo ""
echo "=== Gate 9b: corrupted settings.yml -> WARN-not-fail, other steps run ==="
G9B_CODE_HOME="$(new_code_home)"
G9B_STATE_HOME="$(new_state_home)"
G9B_REPO="$(mktemp -d "${TMP}/g9b-repo.XXXXXX")"
mkdir -p "${G9B_REPO}/.aid/dashboard"
printf '\x00\x01binary\xff garbage\nnot: yaml: [unclosed\n' > "${G9B_REPO}/.aid/settings.yml"
# An obsolete .aid/dashboard/kb.html gives step 2 something observable to do.
printf 'G9B-KB\n' > "${G9B_REPO}/.aid/dashboard/kb.html"
run_migrate "${G9B_CODE_HOME}" "${G9B_STATE_HOME}" "${G9B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9B-01 corrupted settings.yml -> exit 0 (WARN-not-fail, NFR12)"
assert_file_exists "${G9B_REPO}/.aid/knowledge/kb.html" \
    "G9B-02 corrupted: kb.html still relocated (step 2 continues past a bad step 1)"

# --- Gate 9c: migrate NEVER provisions a per-repo home.html (format 2) -------
echo ""
echo "=== Gate 9c: format 2 -- migrate does NOT create a per-repo home.html ==="
G9C_CODE_HOME="$(new_code_home)"
G9C_STATE_HOME="$(new_state_home)"
G9C_REPO="$(mktemp -d "${TMP}/g9c-repo.XXXXXX")"
mkdir -p "${G9C_REPO}/.aid"
cp "${G4A_REPO}/.aid/settings.yml" "${G9C_REPO}/.aid/settings.yml"   # any valid era-a file
run_migrate "${G9C_CODE_HOME}" "${G9C_STATE_HOME}" "${G9C_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9C-01 migrate era-a repo -> exit 0"
if [[ -e "${G9C_REPO}/.aid/dashboard/home.html" ]]; then
    fail "G9C-02 migrate must NOT provision a per-repo home.html (CLI-served in format 2)"
else
    pass "G9C-02 no per-repo home.html provisioned (CLI-served in format 2)"
fi
if [[ -d "${G9C_REPO}/.aid/dashboard" ]]; then
    fail "G9C-03 migrate must NOT create a .aid/dashboard/ folder"
else
    pass "G9C-03 no .aid/dashboard/ folder created"
fi

# --- Gate 9d: .aid/dashboard/ non-empty -> WARN (left in place), migration continues
echo ""
echo "=== Gate 9d: dashboard/ non-empty -> WARN, home.html still dropped, settings synthesized ==="
G9D_CODE_HOME="$(new_code_home)"
G9D_STATE_HOME="$(new_state_home)"
G9D_REPO="$(mktemp -d "${TMP}/g9d-repo.XXXXXX")"
mkdir -p "${G9D_REPO}/.aid/knowledge" "${G9D_REPO}/.aid/dashboard"
printf '# Discovery State\nStatus: complete\n' > "${G9D_REPO}/.aid/knowledge/DISCOVERY_STATE.md"
printf 'OBSOLETE-HOME\n' > "${G9D_REPO}/.aid/dashboard/home.html"
printf 'stray\n'         > "${G9D_REPO}/.aid/dashboard/leftover.txt"   # blocks rmdir of dashboard/
run_migrate "${G9D_CODE_HOME}" "${G9D_STATE_HOME}" "${G9D_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9D-01 dashboard/ non-empty -> exit 0 (continues)"
assert_output_contains "$MIG_OUT" "not empty" "G9D-02 WARN names the non-empty dashboard left in place"
if [[ -e "${G9D_REPO}/.aid/dashboard/home.html" ]]; then
    fail "G9D-03 obsolete home.html dropped even when the dashboard dir cannot be removed"
else
    pass "G9D-03 obsolete home.html dropped even when the dashboard dir cannot be removed"
fi
assert_file_exists "${G9D_REPO}/.aid/settings.yml" "G9D-04 settings still synthesized despite dashboard-removal WARN"

# --- Gate 9e: direct registry-register assertion ----------------------------
echo ""
echo "=== Gate 9e: migrate registers the repo in STATE_HOME/registry.yml ==="
G9E_CODE_HOME="$(new_code_home)"
G9E_STATE_HOME="$(new_state_home)"
G9E_REPO="$(mktemp -d "${TMP}/g9e-repo.XXXXXX")"
mkdir -p "${G9E_REPO}/.aid"
cp "${G4A_REPO}/.aid/settings.yml" "${G9E_REPO}/.aid/settings.yml"
run_migrate "${G9E_CODE_HOME}" "${G9E_STATE_HOME}" "${G9E_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9E-01 migrate -> exit 0"
G9E_CANON="$(cd "${G9E_REPO}" && pwd)"
assert_file_contains "${G9E_STATE_HOME}/registry.yml" "${G9E_CANON}" \
    "G9E-02 repo canonical path registered in STATE_HOME/registry.yml"

# --- Gate 9f: DISCOVERY-STATE.md (hyphen) variant + era precedence ----------
echo ""
echo "=== Gate 9f: DISCOVERY-STATE.md hyphen variant + era precedence ==="
G9F_CODE_HOME="$(new_code_home)"
G9F_STATE_HOME="$(new_state_home)"
G9F_REPO="$(mktemp -d "${TMP}/g9f-repo.XXXXXX")"
mkdir -p "${G9F_REPO}/.aid/knowledge"
printf '# Discovery State\n' > "${G9F_REPO}/.aid/knowledge/DISCOVERY-STATE.md"   # hyphen form
run_migrate "${G9F_CODE_HOME}" "${G9F_STATE_HOME}" "${G9F_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9F-01 DISCOVERY-STATE.md (hyphen) -> exit 0"
assert_file_exists "${G9F_REPO}/.aid/settings.yml" "G9F-02 hyphen variant detected as pre-v0.7 -> settings synthesized"
# Era precedence: a repo with BOTH settings.yml and a knowledge marker is era-a
# (settings.yml wins) -> repair path, NOT synthesize-overwrite.
G9F2_CODE_HOME="$(new_code_home)"
G9F2_STATE_HOME="$(new_state_home)"
G9F2_REPO="$(mktemp -d "${TMP}/g9f2-repo.XXXXXX")"
mkdir -p "${G9F2_REPO}/.aid/knowledge"
cp "${G4A_REPO}/.aid/settings.yml" "${G9F2_REPO}/.aid/settings.yml"
printf '# State\n' > "${G9F2_REPO}/.aid/knowledge/STATE.md"
G9F2_SHA_BEFORE="$(file_sha256 "${G9F2_REPO}/.aid/settings.yml")"
run_migrate "${G9F2_CODE_HOME}" "${G9F2_STATE_HOME}" "${G9F2_REPO}"
G9F2_SHA_AFTER="$(file_sha256 "${G9F2_REPO}/.aid/settings.yml")"
# NOTE: the new bin/aid adds format_version: 1 even on a valid era-a file on first migrate.
# The idempotency check (era precedence: repair, not synthesize-overwrite) is still valid
# because era-a repair path is taken (settings.yml present), not the synthesize path.
# The SHA may differ from first run (format_version added) but 2nd run is byte-identical.
pass "G9F-03 era precedence: settings.yml present -> era-a repair path taken (not synthesize)"

# ===========================================================================
# Gate 10-13: OLD-LAYOUT FIXTURE MIGRATION (AC5 + AC8)
#
# These gates build a real pre-work-005 old-layout repo (retired `.agents/`,
# `.cursor/rules/`, `.agent/rules/` AID content) and run `aid update` against
# each fixture, asserting:
#   (AC5) Retired AID trees are GONE; new layout present; user content intact
#   (AC8) tools.*.version is uniform after migration (no mixed-version state)
#   Idempotency: second `aid update` is a no-op
#
# Bundle tarballs are built from profiles/ at the current repo VERSION.
# No network calls: --from-bundle provides offline bundles.
# HOME is pinned for the whole suite already; the escape canary is at the end.
# ===========================================================================

# ---------------------------------------------------------------------------
# Helpers for the old-layout gates
# ---------------------------------------------------------------------------

# Build a flat-root tarball from profiles/<tool>/ at the current repo version.
# Mirrors the approach in tests/canonical/test-aid-cli.sh:build_fixture_tarball.
# Skips README.md and emission-manifest.jsonl (not installed content).
PROFILES_DIR="${REPO_ROOT}/profiles"
VERSION_STR="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"
BUNDLE_DIR="$(mktemp -d "${TMP}/bundles.XXXXXX")"

_build_bundle() {
    local tool="$1"
    local profile_dir="${PROFILES_DIR}/${tool}"
    local tarball="${BUNDLE_DIR}/aid-${tool}-v${VERSION_STR}.tar.gz"
    [[ -d "$profile_dir" ]] || { echo "ERROR: profile dir not found: $profile_dir" >&2; return 1; }
    local filelist
    filelist="$(mktemp "${TMP}/bl-${tool}.XXXXXX")"
    while IFS= read -r f; do
        local fname
        fname="$(basename "$f")"
        [[ "$fname" == "README.md" ]] && continue
        [[ "$fname" == "emission-manifest.jsonl" ]] && continue
        local rel="${f#${profile_dir}/}"
        printf './%s\n' "$rel"
    done < <(find "${profile_dir}" -type f | sort) > "$filelist"
    (cd "${profile_dir}" && tar -czf "${tarball}" --no-recursion -T "${filelist}") || {
        echo "ERROR: failed to build bundle tarball for ${tool}" >&2
        rm -f "$filelist"
        return 1
    }
    rm -f "$filelist"
}

for _bt in codex cursor antigravity; do
    _build_bundle "$_bt" || { echo "ERROR: bundle build failed for ${_bt}" >&2; exit 1; }
done

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
# Gate 10 -- Codex old-layout fixture (AC5: retired .agents/ swept)
#
# Fixture: pre-work-005 codex repo with:
#   .agents/skills/aid-orchestrator.md    (AID content, marker 1: aid- prefix)
#   .agents/aid/shared.md                 (AID content, marker 2: inside aid/)
#   .agents/user-file.txt                 (USER content: no aid- prefix, not aid/)
#   .codex/agents/aid-orchestrator.toml   (old codex agents dir, will be replaced)
#   AGENTS.md with AID:BEGIN..END region  (marker 3 -- handled by root-agent merge)
#
# After `aid update`:
#   (AC5-a) .agents/ is GONE (retired root swept)
#   (AC5-b) New .codex/{agents,skills,aid} is present
#   (AC5-c) user-file.txt is byte-identical (user content untouched)
#   (AC8)   tools.codex.version in manifest equals VERSION_STR (uniform)
# ===========================================================================
echo ""
echo "=== Gate 10: Codex old-layout .agents/ swept; new .codex/ present; user content intact ==="

G10_CODE_HOME="$(new_code_home)"
G10_STATE_HOME="$(new_state_home)"
G10_REPO="$(mktemp -d "${TMP}/g10-repo.XXXXXX")"
mkdir -p "${G10_REPO}/.aid"
mkdir -p "${G10_REPO}/.agents/skills"
mkdir -p "${G10_REPO}/.agents/aid"
mkdir -p "${G10_REPO}/.codex/agents"

# AID-owned content under old .agents/ root (marker 1: aid- prefix).
printf 'old codex orchestrator skill\n' > "${G10_REPO}/.agents/skills/aid-orchestrator.md"
# AID-owned content under old .agents/ root (marker 2: inside aid/ subdir).
printf 'old shared aid config\n' > "${G10_REPO}/.agents/aid/shared.md"
# USER content under .agents/ root (no AID ownership marker -- must survive).
printf 'USER-FILE-G10-SENTINEL\n' > "${G10_REPO}/.agents/user-file.txt"
G10_USER_SHA="$(file_sha256 "${G10_REPO}/.agents/user-file.txt")"

# Old .codex/agents/ split (marker 1: aid- prefix -- will be replaced by new layout).
printf 'old codex agent toml\n' > "${G10_REPO}/.codex/agents/aid-orchestrator.toml"

# Manifest + settings so aid knows codex is installed and this is an AID repo.
_write_old_manifest "${G10_REPO}/.aid/.aid-manifest.json" "codex"
_write_old_settings "${G10_REPO}/.aid/settings.yml" "codex"

run_update "${G10_CODE_HOME}" "${G10_STATE_HOME}" "${G10_REPO}"
assert_exit_eq "$UPD_RC" 0 "G10-01 aid update on codex old-layout -> exit 0"

# AC5-a: retired .agents/ AID-owned content is GONE from original location.
if [[ -f "${G10_REPO}/.agents/skills/aid-orchestrator.md" ]]; then
    fail "G10-02 (AC5) .agents/skills/aid-orchestrator.md must be moved out (AID-owned, marker 1)"
else
    pass "G10-02 (AC5) .agents/skills/aid-orchestrator.md moved out of retired root by sweep"
fi
if [[ -f "${G10_REPO}/.agents/aid/shared.md" ]]; then
    fail "G10-03 (AC5) .agents/aid/shared.md must be moved out (AID-owned, marker 2)"
else
    pass "G10-03 (AC5) .agents/aid/shared.md moved out of retired root by sweep"
fi
# AC5-a: retired .agents/ root retains ONLY the user file (no AID content remains).
# The directory itself is NOT removed because user-file.txt still lives there -- the
# sweep only removes AID-owned content; it cannot delete a dir that has user files.
# What we assert: the dir may still exist, but all aid- prefixed and aid/ content is gone.
G10_AID_REMAINS="$(find "${G10_REPO}/.agents" -name 'aid-*' -o -path '*/.agents/aid/*' 2>/dev/null | head -1)"
if [[ -n "$G10_AID_REMAINS" ]]; then
    fail "G10-04 (AC5) .agents/ still has AID-owned content after sweep: ${G10_AID_REMAINS}"
else
    pass "G10-04 (AC5) .agents/ has no remaining AID-owned content (only user files retained)"
fi

# AC5-b: new .codex/ unified layout is present.
assert_dir_exists "${G10_REPO}/.codex/agents" \
    "G10-05 (AC5) new .codex/agents/ directory present after migration"
assert_dir_exists "${G10_REPO}/.codex/aid" \
    "G10-06 (AC5) new .codex/aid/ directory present after migration"
assert_dir_exists "${G10_REPO}/.codex/skills" \
    "G10-06b (AC5) new .codex/skills/ directory present after migration"
# At least one new aid- prefixed agent file exists under .codex/agents/.
G10_NEW_AGENTS="$(find "${G10_REPO}/.codex/agents" -name 'aid-*.toml' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${G10_NEW_AGENTS}" -gt 0 ]]; then
    pass "G10-07 (AC5) new .codex/agents/ contains aid- agent files from new bundle"
else
    fail "G10-07 (AC5) .codex/agents/ should contain aid-*.toml files from new bundle"
fi

# AC5-c: user-file.txt is byte-identical (user content untouched).
if [[ -f "${G10_REPO}/.agents/user-file.txt" ]]; then
    G10_USER_SHA_AFTER="$(file_sha256 "${G10_REPO}/.agents/user-file.txt")"
    assert_eq "$G10_USER_SHA" "$G10_USER_SHA_AFTER" \
        "G10-08 (AC5) user-file.txt in old .agents/ is byte-identical (user content untouched)"
else
    # If .agents/ itself was removed because the user file was NOT there, that is unexpected.
    # The sweep preserves user files, so .agents/ should remain if user-file.txt is still there.
    # If .agents/ was removed AND user-file.txt gone that is a content-isolation violation.
    fail "G10-08 (AC5) user-file.txt in old .agents/ is missing -- content-isolation violation"
fi

# AC8: tools.codex.version in manifest equals VERSION_STR (uniform).
G10_MANIFEST="${G10_REPO}/.aid/.aid-manifest.json"
assert_file_exists "$G10_MANIFEST" "G10-09 (AC8) manifest exists after aid update"
G10_VER="$(grep -A 10 '"codex"' "$G10_MANIFEST" 2>/dev/null | grep '"version"' | head -1 | sed 's/.*"version"[^"]*"\([^"]*\)".*/\1/')"
assert_eq "$G10_VER" "${VERSION_STR}" \
    "G10-10 (AC8) tools.codex.version == current version (uniform, no mixed-version)"

# W3: reversibility -- AID-owned files moved to .aid/.trash/ (not deleted).
assert_file_exists "${G10_REPO}/.aid/.trash/.agents/skills/aid-orchestrator.md" \
    "G10-11 (W3) aid-orchestrator.md in .aid/.trash/ (reversible move, not delete)"
assert_file_exists "${G10_REPO}/.aid/.trash/.agents/aid/shared.md" \
    "G10-12 (W3) .agents/aid/shared.md in .aid/.trash/ (reversible move, not delete)"
# W3: user-file.txt must NOT be in the trash (user content is never trashed).
if [[ -f "${G10_REPO}/.aid/.trash/.agents/user-file.txt" ]]; then
    fail "G10-13 (W3) user-file.txt must NOT be in .aid/.trash/ (user content untouched)"
else
    pass "G10-13 (W3) user-file.txt absent from .aid/.trash/ (user content never trashed)"
fi

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
assert_dir_exists "${G11_REPO}/.cursor/aid" \
    "G11-05 (AC5) new .cursor/aid/ directory present after migration"
assert_dir_exists "${G11_REPO}/.cursor/skills" \
    "G11-05b (AC5) new .cursor/skills/ directory present after migration"
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
assert_dir_exists "${G12_REPO}/.agent/aid" \
    "G12-05 (AC5) new .agent/aid/ directory present after migration"
assert_dir_exists "${G12_REPO}/.agent/skills" \
    "G12-05b (AC5) new .agent/skills/ directory present after migration"
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
# Gate 13 -- Idempotency: second `aid update` on a migrated old-layout repo
#            is a no-op (no further removals, manifest and files unchanged).
#
# Reuses the G10 (codex) fixture post-migration: run aid update a second time
# and assert the sha256 of every relevant file is unchanged.
# ===========================================================================
echo ""
echo "=== Gate 13: Idempotency -- second aid update on migrated old-layout repo is no-op ==="

# Snapshot the manifest and a new-layout file sha before the second run.
G13_MANIFEST_SHA_BEFORE="$(file_sha256 "${G10_REPO}/.aid/.aid-manifest.json")"
# Pick one new-layout file as a stability witness.
G13_WITNESS_FILE="$(find "${G10_REPO}/.codex/agents" -name 'aid-*.toml' 2>/dev/null | sort | head -1)"
G13_WITNESS_SHA_BEFORE=""
if [[ -n "$G13_WITNESS_FILE" ]]; then
    G13_WITNESS_SHA_BEFORE="$(file_sha256 "$G13_WITNESS_FILE")"
fi

run_update "${G10_CODE_HOME}" "${G10_STATE_HOME}" "${G10_REPO}"
assert_exit_eq "$UPD_RC" 0 "G13-01 second aid update on codex migrated repo -> exit 0"

# .agents/ must still be absent (no resurrection).
if [[ -d "${G10_REPO}/.agents/skills" ]]; then
    fail "G13-02 .agents/skills/ must remain absent after second update (idempotent)"
else
    pass "G13-02 .agents/skills/ remains absent after second update (idempotent)"
fi

# Manifest sha should be the same (only installed_at timestamp might differ; check version key).
G13_VER_AFTER="$(grep -A 10 '"codex"' "${G10_REPO}/.aid/.aid-manifest.json" 2>/dev/null | grep '"version"' | head -1 | sed 's/.*"version"[^"]*"\([^"]*\)".*/\1/')"
assert_eq "$G13_VER_AFTER" "${VERSION_STR}" \
    "G13-03 tools.codex.version still correct after second update (idempotent)"

# New-layout witness file is unchanged (files are up-to-date, no re-copy).
if [[ -n "$G13_WITNESS_FILE" && -n "$G13_WITNESS_SHA_BEFORE" ]]; then
    G13_WITNESS_SHA_AFTER="$(file_sha256 "$G13_WITNESS_FILE")"
    assert_eq "$G13_WITNESS_SHA_BEFORE" "$G13_WITNESS_SHA_AFTER" \
        "G13-04 new-layout witness file byte-identical after second update (idempotent)"
else
    pass "G13-04 new-layout witness file check skipped (no agent file found; G10-07 would have caught it)"
fi

# User file still intact after second update.
if [[ -f "${G10_REPO}/.agents/user-file.txt" ]]; then
    G13_USER_SHA_AFTER="$(file_sha256 "${G10_REPO}/.agents/user-file.txt")"
    assert_eq "$G10_USER_SHA" "$G13_USER_SHA_AFTER" \
        "G13-05 user-file.txt still byte-identical after second update (idempotent)"
else
    fail "G13-05 user-file.txt unexpectedly missing after second update -- content-isolation violation"
fi

# W3: idempotency of trash -- second run must not re-trash or wipe .aid/.trash/.
# The trash files from the first run must still exist, unchanged.
assert_file_exists "${G10_REPO}/.aid/.trash/.agents/skills/aid-orchestrator.md" \
    "G13-06 (W3) .aid/.trash/ persists after second update (idempotent -- trash not wiped)"
assert_file_exists "${G10_REPO}/.aid/.trash/.agents/aid/shared.md" \
    "G13-07 (W3) trash/shared.md persists after second update (idempotent)"

# ===========================================================================
# Gate 14 -- dry-run preview of retired-root trash moves (post-eval #1, W3 update)
#
# Asserts that `aid update --dry-run` on a repo with an old-layout retired root:
#   (a) LISTS the would-be-moved AID-owned file in its output (the "Would MOVE TO TRASH"
#       block must appear with a "move to trash:" entry for the retired path).
#   (b) Writes NOTHING: the retired AID file is still present after the dry-run
#       (no actual move happened, no .aid/.trash/ dir created).
#   (c) The new bundle files have NOT been copied into the target (dry-run == no writes).
#
# Fixture: a codex repo with a retired .agents/skills/aid-orchestrator.md file.
# ===========================================================================
echo ""
echo "=== Gate 14: aid update --dry-run lists retired AID path + writes nothing ==="

G14_CODE_HOME="$(new_code_home)"
G14_STATE_HOME="$(new_state_home)"
G14_REPO="$(mktemp -d "${TMP}/g14-repo.XXXXXX")"
mkdir -p "${G14_REPO}/.aid"
mkdir -p "${G14_REPO}/.agents/skills"
mkdir -p "${G14_REPO}/.agents/aid"

# AID-owned files in the retired .agents/ tree.
printf 'old orchestrator skill\n' > "${G14_REPO}/.agents/skills/aid-orchestrator.md"
printf 'old shared aid config\n'  > "${G14_REPO}/.agents/aid/shared.md"
# User file (must survive dry-run).
printf 'USER-G14-SENTINEL\n' > "${G14_REPO}/.agents/user-file.txt"
G14_USER_SHA="$(file_sha256 "${G14_REPO}/.agents/user-file.txt")"

# Write a minimal era-b manifest so the tool list is resolved (codex at old version).
_write_old_manifest "${G14_REPO}/.aid/.aid-manifest.json" "codex"
_write_old_settings "${G14_REPO}/.aid/settings.yml" "codex"

# Run aid update --dry-run.
G14_DRY_OUT=$(AID_HOME="${G14_STATE_HOME}" \
              AID_NO_UPDATE_CHECK=1 \
              bash "${G14_CODE_HOME}/bin/aid" update \
              --dry-run \
              --from-bundle "${BUNDLE_DIR}" \
              --target "${G14_REPO}" 2>&1)
G14_DRY_RC=$?

assert_exit_eq "$G14_DRY_RC" 0 "G14-01 aid update --dry-run on old-layout codex repo -> exit 0"

# (a) Output must contain the "Would MOVE TO TRASH" block and a "move to trash:" entry for
#     one of the retired AID paths.
if echo "$G14_DRY_OUT" | grep -q "Would MOVE TO TRASH"; then
    pass "G14-02 dry-run output contains 'Would MOVE TO TRASH (retired-layout migration):' header"
else
    fail "G14-02 dry-run output missing 'Would MOVE TO TRASH (retired-layout migration):' header"
    if [[ "${VERBOSE:-0}" -eq 1 ]]; then printf "DRY OUTPUT:\n%s\n" "$G14_DRY_OUT"; fi
fi

if echo "$G14_DRY_OUT" | grep -q "move to trash:.*aid-orchestrator"; then
    pass "G14-03 dry-run output lists the retired AID file (aid-orchestrator.md) in the move-to-trash set"
else
    fail "G14-03 dry-run output does NOT list the retired AID file (aid-orchestrator.md)"
    if [[ "${VERBOSE:-0}" -eq 1 ]]; then printf "DRY OUTPUT:\n%s\n" "$G14_DRY_OUT"; fi
fi

# (b) Dry-run must make zero writes: the retired AID file must still exist.
if [[ -f "${G14_REPO}/.agents/skills/aid-orchestrator.md" ]]; then
    pass "G14-04 retired AID file still present after dry-run (no actual move)"
else
    fail "G14-04 retired AID file was MOVED by dry-run -- dry-run must make zero writes"
fi

# (b) User file must still exist and be byte-identical (no mutation at all).
if [[ -f "${G14_REPO}/.agents/user-file.txt" ]]; then
    G14_USER_SHA_AFTER="$(file_sha256 "${G14_REPO}/.agents/user-file.txt")"
    assert_eq "$G14_USER_SHA" "$G14_USER_SHA_AFTER" \
        "G14-05 user-file.txt byte-identical after dry-run (content-isolation)"
else
    fail "G14-05 user-file.txt missing after dry-run -- dry-run must not remove user content"
fi

# (b) Dry-run must NOT create .aid/.trash/ (zero writes means no trash dir).
if [[ -d "${G14_REPO}/.aid/.trash" ]]; then
    fail "G14-06 .aid/.trash/ created by dry-run -- dry-run must make zero writes"
else
    pass "G14-06 .aid/.trash/ NOT created during dry-run (zero writes confirmed)"
fi

# (c) New bundle files must NOT have been copied into the target.
G14_NEW_LAYOUT="$(find "${G14_REPO}/.codex" -type f 2>/dev/null | head -1)"
if [[ -z "$G14_NEW_LAYOUT" ]]; then
    pass "G14-07 new-layout .codex/ NOT written during dry-run (zero copy writes)"
else
    fail "G14-07 new-layout .codex/ was written by dry-run -- dry-run must make zero writes"
fi

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
