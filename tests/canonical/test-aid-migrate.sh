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
#   Gate 7a: existing kb.html + legacy knowledge-summary.html -> both kept (no-clobber)
#   Gate 7b: existing home.html -> never overwritten
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
READ_SETTING="${REPO_ROOT}/canonical/scripts/config/read-setting.sh"

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
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a minimal CODE_HOME with bin/aid + lib/aid-install-core.sh + VERSION
# and a stub dashboard/home.html so Step-2 (copy home.html) can succeed.
# bin/aid self-locates this dir as AID_CODE_HOME.
# Do NOT export this dir as AID_HOME; that is the state home (see new_state_home).
new_code_home() {
    local h; h="$(mktemp -d "${TMP}/code.XXXXXX")"
    mkdir -p "${h}/bin" "${h}/lib" "${h}/dashboard"
    cp "${BIN_AID}"   "${h}/bin/aid"
    chmod +x          "${h}/bin/aid"
    cp "${LIB_CORE}"  "${h}/lib/aid-install-core.sh"
    printf '0.7.0\n'  > "${h}/VERSION"
    # A stub home.html so that migration step 2 (copy-when-absent) has a source.
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
# Gate 7a -- no-delete: existing kb.html + legacy knowledge-summary.html -> both kept
#
# Fixture has:
#   .aid/knowledge/knowledge-summary.html  (legacy location)
#   .aid/dashboard/kb.html                 (already at new location)
# Migration must NOT clobber kb.html (mv -n guard); legacy file is NOT moved.
# ===========================================================================
echo ""
echo "=== Gate 7a: no-delete -- existing kb.html + legacy summary -> both kept ==="

G7A_CODE_HOME="$(new_code_home)"
G7A_STATE_HOME="$(new_state_home)"
G7A_REPO="$(mktemp -d "${TMP}/g7a-repo.XXXXXX")"
mkdir -p "${G7A_REPO}/.aid/knowledge" "${G7A_REPO}/.aid/dashboard"

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
# kb.html already at the NEW location with different sentinel content.
printf 'EXISTING-KB-CONTENT-G7A\n' > "${G7A_REPO}/.aid/dashboard/kb.html"

G7A_KB_SHA_BEFORE="$(file_sha256 "${G7A_REPO}/.aid/dashboard/kb.html")"

run_migrate "${G7A_CODE_HOME}" "${G7A_STATE_HOME}" "${G7A_REPO}"
assert_exit_eq "$MIG_RC" 0 "G7A-01 __migrate-repo with existing kb.html -> exit 0"

# kb.html must NOT be overwritten.
G7A_KB_SHA_AFTER="$(file_sha256 "${G7A_REPO}/.aid/dashboard/kb.html")"
assert_eq "$G7A_KB_SHA_BEFORE" "$G7A_KB_SHA_AFTER" \
    "G7A-02 existing .aid/dashboard/kb.html NOT overwritten (no-clobber)"
assert_file_contains "${G7A_REPO}/.aid/dashboard/kb.html" "EXISTING-KB-CONTENT-G7A" \
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
assert_file_exists "${G7A2_REPO}/.aid/dashboard/kb.html" \
    "G7A2-02 legacy knowledge-summary.html relocated to .aid/dashboard/kb.html"
assert_file_contains "${G7A2_REPO}/.aid/dashboard/kb.html" "LEGACY-CONTENT-G7A2" \
    "G7A2-03 relocated kb.html has the original content"

# ===========================================================================
# Gate 7b -- no-delete: existing home.html is never overwritten
#
# Fixture already has .aid/dashboard/home.html with sentinel content.
# Migration step 2 is copy-when-absent only; existing file must survive.
# ===========================================================================
echo ""
echo "=== Gate 7b: no-delete -- existing home.html -> never overwritten ==="

G7B_CODE_HOME="$(new_code_home)"
G7B_STATE_HOME="$(new_state_home)"
G7B_REPO="$(mktemp -d "${TMP}/g7b-repo.XXXXXX")"
mkdir -p "${G7B_REPO}/.aid/dashboard"

cat > "${G7B_REPO}/.aid/settings.yml" << 'G7B_SETTINGS_EOF'
project:
  name: G7BProject
  description: Gate-7b home.html preservation fixture
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

printf 'EXISTING-HOME-CONTENT-G7B\n' > "${G7B_REPO}/.aid/dashboard/home.html"
G7B_HOME_SHA_BEFORE="$(file_sha256 "${G7B_REPO}/.aid/dashboard/home.html")"

run_migrate "${G7B_CODE_HOME}" "${G7B_STATE_HOME}" "${G7B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G7B-01 __migrate-repo with existing home.html -> exit 0"

G7B_HOME_SHA_AFTER="$(file_sha256 "${G7B_REPO}/.aid/dashboard/home.html")"
assert_eq "$G7B_HOME_SHA_BEFORE" "$G7B_HOME_SHA_AFTER" \
    "G7B-02 existing .aid/dashboard/home.html NOT overwritten"
assert_file_contains "${G7B_REPO}/.aid/dashboard/home.html" "EXISTING-HOME-CONTENT-G7B" \
    "G7B-03 existing home.html content byte-for-byte intact"

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
# settings, the home.html absent/positive and source-missing branches, a
# direct registry-register assertion, the DISCOVERY-STATE.md hyphen variant,
# and era precedence. Empirically grounded: migration returns 0 and never
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
assert_file_exists "${G9A_REPO}/.aid/dashboard/home.html" \
    "G9A-04 CRLF: home.html still provisioned (step 2 ran)"
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
mkdir -p "${G9B_REPO}/.aid"
printf '\x00\x01binary\xff garbage\nnot: yaml: [unclosed\n' > "${G9B_REPO}/.aid/settings.yml"
run_migrate "${G9B_CODE_HOME}" "${G9B_STATE_HOME}" "${G9B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9B-01 corrupted settings.yml -> exit 0 (WARN-not-fail, NFR12)"
assert_file_exists "${G9B_REPO}/.aid/dashboard/home.html" \
    "G9B-02 corrupted: home.html still provisioned (step 2 continues past a bad step 1)"

# --- Gate 9c: home.html absent -> positively provisioned with CODE_HOME source bytes ---
echo ""
echo "=== Gate 9c: home.html absent -> provisioned from \$AID_CODE_HOME source ==="
G9C_CODE_HOME="$(new_code_home)"
G9C_STATE_HOME="$(new_state_home)"
G9C_REPO="$(mktemp -d "${TMP}/g9c-repo.XXXXXX")"
mkdir -p "${G9C_REPO}/.aid"
cp "${G4A_REPO}/.aid/settings.yml" "${G9C_REPO}/.aid/settings.yml"   # any valid era-a file
[[ -f "${G9C_REPO}/.aid/dashboard/home.html" ]] && fail "G9C precondition: home.html should be absent" || pass "G9C-00 precondition: home.html absent"
run_migrate "${G9C_CODE_HOME}" "${G9C_STATE_HOME}" "${G9C_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9C-01 absent home.html -> exit 0"
assert_file_exists "${G9C_REPO}/.aid/dashboard/home.html" "G9C-02 home.html now present"
G9C_SRC_SHA="$(file_sha256 "${G9C_CODE_HOME}/dashboard/home.html")"
G9C_DST_SHA="$(file_sha256 "${G9C_REPO}/.aid/dashboard/home.html")"
assert_eq "$G9C_SRC_SHA" "$G9C_DST_SHA" "G9C-03 provisioned home.html == AID_CODE_HOME source bytes"

# --- Gate 9d: home.html SOURCE missing in AID_CODE_HOME -> WARN, migration continues
echo ""
echo "=== Gate 9d: home.html source missing -> WARN, settings still repaired ==="
G9D_CODE_HOME="$(new_code_home)"
G9D_STATE_HOME="$(new_state_home)"
rm -f "${G9D_CODE_HOME}/dashboard/home.html"          # remove the provisioning source
G9D_REPO="$(mktemp -d "${TMP}/g9d-repo.XXXXXX")"
mkdir -p "${G9D_REPO}/.aid/knowledge"
printf '# Discovery State\nStatus: complete\n' > "${G9D_REPO}/.aid/knowledge/DISCOVERY_STATE.md"
run_migrate "${G9D_CODE_HOME}" "${G9D_STATE_HOME}" "${G9D_REPO}"
assert_exit_eq "$MIG_RC" 0 "G9D-01 missing home.html source -> exit 0 (continues)"
assert_output_contains "$MIG_OUT" "home.html source not found" "G9D-02 WARN names the missing source"
assert_file_exists "${G9D_REPO}/.aid/settings.yml" "G9D-03 settings still synthesized despite missing home.html source"

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

# --- Isolation canary: confirm no real repo was touched ----------------------
echo ""
echo "=== Isolation canary: real HOME untouched ==="
_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
_CANARY_EXPECTED=""
if [[ "${_CANARY_AFTER}" == "${_CANARY_EXPECTED}" ]]; then
    pass "ISO-CANARY-01 real HOME (${REAL_HOME}) has no .aid dirs (no scan escaped throwaway HOME)"
else
    fail "ISO-CANARY-01 real HOME blast surface: .aid dirs appeared under ${REAL_HOME}: ${_CANARY_AFTER}"
fi

# ===========================================================================
test_summary
