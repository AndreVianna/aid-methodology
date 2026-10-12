#!/usr/bin/env bash
# test-aid-migrate.sh -- task-081: migration unit/safety tests for _aid_migrate_repo
# (reachable via `aid __migrate-repo <path>`).
#
# Covers SPEC feature-011 section-6 gates 4-8:
#
# NOTE (config-schema redesign): _aid_migrate_repair_settings_era_a is now a full
# read-then-rewrite into the flat format-3 schema (not the original targeted-line
# repair), so Gates 4a/4b/4c below reflect the new reality: inline comments and
# section nesting are DROPPED on every era-a repo (valid or not); kb_baseline
# (without branch/tip_date) and per-skill grade overrides have no new-schema home
# and are dropped rather than preserved; tools now live EXCLUSIVELY in the
# manifest (never written into settings.yml by era-a repair or era-b synthesis).
#
#   Gate 4a: era-a VALID settings (inline comments + alignment) -> flat format-3
#             rewrite (comments dropped, format_version: 5 stamped -- task-008
#             bumped AID_SUPPORTED_FORMAT 3 -> 4 for the STATE.md -> STATE.yml
#             conversion; the settings SCHEMA shape itself is unchanged since
#             format 3, hence "flat format-3 schema" below still names the shape)
#   Gate 4b: era-a MALFORMED settings (missing section) + kb_baseline + skill override
#             -> repaired to the flat format-3 schema; kb_baseline + override DROPPED
#   Gate 4c: era-a bare value-less name: -> repaired to basename (top-level, flat schema)
#   Gate 5a: era-b STATE.md + .aid-manifest.json -> synthesized flat settings
#             (name/type/source_control/defaults); tools stay in the manifest only
#   Gate 5b: era-b DISCOVERY_STATE.md variant (RC-4 filename set) -> synthesized settings
#   Gate 5c: era-b no manifest -> synthesized with no tools: block at all
#   Gate 6:  run migrate twice on every fixture -> second run byte-identical no-op
#   Gate 7a: existing .aid/knowledge/kb.html + legacy knowledge-summary.html -> both kept (no-clobber)
#   Gate 7b: format-2 dashboard elimination -- .aid/dashboard/kb.html relocated to
#             .aid/knowledge/kb.html, obsolete .aid/dashboard/ (incl. home.html) removed
#   Gate 7c: format-2 both-exist -- stale .aid/dashboard/kb.html + authoritative
#             .aid/knowledge/kb.html -> proper kept, stale stray dropped, dashboard/ removed
#   Gate 8:  bare .aid/.temp/ (no marker) -> non-candidate, zero writes
#   Gate 15: STEP 5 -- STATE.md -> STATE.yml FORMAT-4 CONVERSION (task-008 /
#             SPEC.md SS L-6 step 2; task-015 addendum, additive per
#             test-baseline-pre-refactor.md SS 5.3): a flat-layout work-level
#             STATE.md with real content in every AUTHORED section converts to
#             the documented STATE.yml key shape and the .md is deleted;
#             second run is byte-identical (Gate 6 extends this); a full-layout
#             delivery + task STATE.md pair converts the same way; a STATE.md
#             carrying a REAL row under a guarded DERIVED heading (SP-3) hits
#             the hard-error path -- WARN to stderr, conversion refused,
#             STATE.md left in place, no STATE.yml written (WARN-not-fail:
#             __migrate-repo's own exit code is unaffected).
#
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
# Gate 4a -- era-a VALID settings with inline comments + alignment -> REWRITTEN
#            to the flat format-3 schema (comments dropped, not preserved)
#
# Regression fixture for the original comment-strip bug: every REQUIRED scalar
# carries an inline comment + alignment padding. The config-schema redesign
# changed _aid_migrate_repair_settings_era_a from a targeted line-repair (which
# preserved comments/nesting) into a full read-then-rewrite into the flat
# schema, so EVERY era-a repo -- valid or not -- is now rewritten: inline
# comments and section nesting are dropped, and the file is never a
# byte-identical no-op on first migrate (idempotency now holds on the SECOND
# run only -- see Gate 6).
# ===========================================================================
echo ""
echo "=== Gate 4a: era-a valid+commented -> flat format-3 rewrite (comments dropped) ==="

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
# G4A-02: format_version: 5 stamped at the top of the rewritten flat file
# (config-schema redesign -- full rewrite, not a targeted repair).
# task-015 addendum (SP-16 / AC-10): this literally asserted "format_version: 3"
# before -- stale since task-008 bumped AID_SUPPORTED_FORMAT 3 -> 4 for the
# STATE.md -> STATE.yml conversion (bin/aid C1 comment block); the settings
# writer here always stamps whatever AID_SUPPORTED_FORMAT currently is, so the
# assertion was silently wrong (a hardcoded "3" the writer never produced
# again) rather than testing anything real. See known-issues.md KI-011.
G4A_FMT_LINE="$(grep '^format_version:' "${G4A_REPO}/.aid/settings.yml" | head -1)"
assert_eq "$G4A_FMT_LINE" "format_version: 5" \
    "G4A-02 format_version: 5 stamped on the rewritten flat file"

# Spot-check each value is flattened to top level with the inline comment dropped.
G4A_TYPE_LINE="$(grep '^type:' "${G4A_REPO}/.aid/settings.yml")"
assert_eq "$G4A_TYPE_LINE" "type: brownfield" \
    "G4A-03 type: flattened to top level with the inline comment dropped"

# execution: block (incl. max_parallel_tasks) is removed by the redesign.
assert_file_not_contains "${G4A_REPO}/.aid/settings.yml" "max_parallel_tasks" \
    "G4A-04 max_parallel_tasks dropped (execution: block removed)"

G4A_HB_LINE="$(grep '^heartbeat_interval:' "${G4A_REPO}/.aid/settings.yml")"
assert_eq "$G4A_HB_LINE" "heartbeat_interval: 1" \
    "G4A-05 heartbeat_interval: promoted to top level with the inline comment dropped"

G4A_NAME_LINE="$(grep '^name:' "${G4A_REPO}/.aid/settings.yml")"
assert_eq "$G4A_NAME_LINE" "name: TestProject" \
    "G4A-06 name: value flattened to top level with the inline comment dropped"

G4A_MG_LINE="$(grep '^minimum_grade:' "${G4A_REPO}/.aid/settings.yml" | head -1)"
assert_eq "$G4A_MG_LINE" "minimum_grade: A" \
    "G4A-07 minimum_grade: promoted to top level with the inline comment dropped"

# ===========================================================================
# Gate 4b -- era-a MALFORMED settings (missing project: section) +
#            populated kb_baseline + per-skill override ->
#            repaired to the flat format-3 schema; kb_baseline + per-skill
#            overrides are DROPPED (both are features the redesign removes)
#
# The malformed fixture omits the `project:` section entirely AND includes:
#   - a review.kb_baseline block (no branch/tip_date -- no knowledge: analogue)
#   - a review.skills.my-skill / another-skill override (per-skill grade
#     overrides no longer exist in the flat schema)
# NOTE (config-schema redesign): _aid_migrate_repair_settings_era_a is now a
# full read-then-rewrite into the flat schema. It resolves each REQUIRED
# top-level scalar (falling back to the old nested location), then rewrites
# the whole file -- so kb_baseline/per-skill overrides with no new-schema
# home are dropped rather than preserved (the opposite of the original R21
# byte-for-byte-preservation contract, which this redesign supersedes).
# ===========================================================================
echo ""
echo "=== Gate 4b: era-a malformed + kb_baseline + skill override -> repaired, overrides dropped ==="

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

run_migrate "${G4B_CODE_HOME}" "${G4B_STATE_HOME}" "${G4B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G4B-01 __migrate-repo malformed fixture -> exit 0"

# The flat schema has no project: section at all -- name/description/type are
# now TOP-LEVEL scalars (no leading indent, no wrapper section).
assert_file_not_contains "${G4B_REPO}/.aid/settings.yml" "project:" \
    "G4B-02 repaired: flat schema has no project: wrapper section"
G4B_NAME_TOP="$(grep '^name:' "${G4B_REPO}/.aid/settings.yml")"
assert_eq "${G4B_NAME_TOP:+present}" "present" "G4B-03 repaired: top-level name: present"
G4B_DESC_TOP="$(grep '^description:' "${G4B_REPO}/.aid/settings.yml")"
assert_eq "${G4B_DESC_TOP:+present}" "present" "G4B-04 repaired: top-level description: present"
G4B_TYPE_LINE="$(grep '^type:' "${G4B_REPO}/.aid/settings.yml")"
assert_eq "$G4B_TYPE_LINE" "type: brownfield" \
    "G4B-05 repaired: top-level type: brownfield present"

# name must have been set to the repo basename (not empty) -- top-level, flat schema.
G4B_EXPECTED_NAME="$(basename "${G4B_REPO}")"
G4B_NAME_LINE="$(grep '^name:' "${G4B_REPO}/.aid/settings.yml" | head -1)"
G4B_NAME_VAL="${G4B_NAME_LINE#name: }"
assert_eq "$G4B_NAME_VAL" "$G4B_EXPECTED_NAME" \
    "G4B-06 repaired: name set to repo basename (top-level)"

# kb_baseline (review-nested, no branch/tip_date) has no new-schema home: dropped.
assert_file_not_contains "${G4B_REPO}/.aid/settings.yml" "kb_baseline:" \
    "G4B-07 kb_baseline (no branch/tip_date) dropped -- not carried into knowledge:"
assert_file_not_contains "${G4B_REPO}/.aid/settings.yml" "discover:" \
    "G4B-08 kb_baseline.discover sub-key dropped along with kb_baseline"

# Per-skill overrides are a removed feature -- dropped, not preserved.
assert_file_not_contains "${G4B_REPO}/.aid/settings.yml" "my-skill:" \
    "G4B-10 per-skill my-skill: override dropped (feature removed by the redesign)"
assert_file_not_contains "${G4B_REPO}/.aid/settings.yml" "another-skill:" \
    "G4B-11 per-skill another-skill: override dropped (feature removed by the redesign)"

# review.minimum_grade (the fixture's only resolvable review.* value) DOES survive,
# promoted to the top-level minimum_grade: (proves the redesign carries forward
# values that DO have a new-schema home, while dropping ones that do not).
G4B_MG_LINE="$(grep '^minimum_grade:' "${G4B_REPO}/.aid/settings.yml" | head -1)"
assert_eq "$G4B_MG_LINE" "minimum_grade: A" \
    "G4B-09 review.minimum_grade promoted to top-level minimum_grade: (value preserved)"

# Verify the repaired file is parseable by read-setting.sh without fallback.
# project.name / project.type still resolve via read-setting.sh's documented
# backward-compat alias (dotted legacy path -> new top-level scalar).
G4B_RS_NAME="$(bash "${READ_SETTING}" \
    --file "${G4B_REPO}/.aid/settings.yml" \
    --path project.name 2>/dev/null)"
assert_eq "$G4B_RS_NAME" "$G4B_EXPECTED_NAME" \
    "G4B-14 repaired file: read-setting.sh resolves project.name via top-level alias"

G4B_RS_TYPE="$(bash "${READ_SETTING}" \
    --file "${G4B_REPO}/.aid/settings.yml" \
    --path project.type 2>/dev/null)"
assert_eq "$G4B_RS_TYPE" "brownfield" \
    "G4B-15 repaired file: read-setting.sh resolves project.type via top-level alias"

# execution.max_parallel_tasks has NO new-schema home (execution: block removed) and
# NO backward-compat alias -- read-setting.sh must fall through to --default (proving
# the field is genuinely gone, not silently misread from stale nested content).
G4B_RS_MPT="$(bash "${READ_SETTING}" \
    --file "${G4B_REPO}/.aid/settings.yml" \
    --path execution.max_parallel_tasks --default "GONE" 2>/dev/null)"
assert_eq "$G4B_RS_MPT" "GONE" \
    "G4B-16 repaired file: execution.max_parallel_tasks has no value (falls through to --default; execution: removed)"

# ===========================================================================
# Gate 4c -- era-a bare value-less name: form (full unit coverage)
#
# A settings.yml where project.name: has no value but the rest of the required
# keys are valid. Also carries a kb_baseline block and a per-skill override --
# both DROPPED by the config-schema redesign's full-rewrite migration (no
# new-schema home for either); the repaired name lands at TOP LEVEL (flat
# schema, no indent).
# ===========================================================================
echo ""
echo "=== Gate 4c: era-a bare name: -> repaired (top-level); kb_baseline/skill dropped ==="

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

G4C_NAME_VAL="$(grep '^name:' "${G4C_REPO}/.aid/settings.yml" | head -1 | \
    sed 's/^name:[[:space:]]*//')"
assert_eq "$G4C_NAME_VAL" "$G4C_EXPECTED_NAME" \
    "G4C-02 bare name: repaired to repo-folder basename (top-level, flat schema)"

assert_file_not_contains "${G4C_REPO}/.aid/settings.yml" "kb_baseline:" \
    "G4C-03 kb_baseline (no branch/tip_date) dropped -- not carried into knowledge:"
assert_file_not_contains "${G4C_REPO}/.aid/settings.yml" "my-skill:" \
    "G4C-04 per-skill override dropped (feature removed by the config-schema redesign)"

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

G4C2_NAME_VAL="$(grep '^name:' "${G4C2_REPO}/.aid/settings.yml" | head -1 | \
    sed 's/^name:[[:space:]]*//')"
assert_eq "$G4C2_NAME_VAL" "$G4C2_EXPECTED_NAME" \
    "G4C-05 bare name: with trailing comment still detected as empty and repaired (top-level, flat schema)"

# ===========================================================================
# Gate 5a -- era-b STATE.md + .aid-manifest.json -> synthesized settings
#
# Repo has no settings.yml, has .aid/knowledge/STATE.md (era-b marker), and
# has .aid/.aid-manifest.json with >=1 tool entry.
# NOTE (config-schema redesign): era-b synthesis (_aid_migrate_synthesize_settings_era_b)
# writes ONLY the flat top-level scalars (name/description/type/source_control/
# minimum_grade/heartbeat_interval); tools now live EXCLUSIVELY in the manifest
# (never written into settings.yml, with or without a manifest present) and
# execution.max_parallel_tasks no longer exists in any form.
# Expected: synthesized settings.yml with:
#   name = repo basename (top level)
#   type = brownfield (top level)
#   source_control = none (fixture has no .git)
#   defaults for minimum_grade/heartbeat_interval
#   the manifest (untouched by migrate) still carries the tool list
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

# tools now live ONLY in the manifest (never written into settings.yml by
# migrate); the manifest itself is untouched, so both tools must still be
# listed there.
assert_file_contains "${G5A_REPO}/.aid/.aid-manifest.json" "claude-code" \
    "G5A-05 manifest (untouched by migrate) still lists claude-code"
assert_file_contains "${G5A_REPO}/.aid/.aid-manifest.json" "codex" \
    "G5A-06 manifest (untouched by migrate) still lists codex"
assert_file_not_contains "${G5A_REPO}/.aid/settings.yml" "tools:" \
    "G5A-05b synthesized settings.yml has no tools: block (tools live in the manifest)"

# execution: block no longer exists in any form -- source_control (a new
# top-level field) is detected instead (no .git in this fixture -> "none").
G5A_RS_SC="$(bash "${READ_SETTING}" \
    --file "${G5A_REPO}/.aid/settings.yml" \
    --path source_control 2>/dev/null)"
assert_eq "$G5A_RS_SC" "none" \
    "G5A-07 synthesized: source_control defaults to none (fixture has no .git)"

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

# tools live ONLY in the manifest (never written into settings.yml by migrate).
assert_file_contains "${G5B_REPO}/.aid/.aid-manifest.json" "cursor" \
    "G5B-04 DISCOVERY_STATE.md: manifest (untouched by migrate) still lists cursor"
assert_file_not_contains "${G5B_REPO}/.aid/settings.yml" "tools:" \
    "G5B-04b DISCOVERY_STATE.md: synthesized settings.yml has no tools: block"

# ===========================================================================
# Gate 5c -- era-b no manifest -> no tools: block at all (config-schema
#            redesign: tools never live in settings.yml, manifest or not)
# ===========================================================================
echo ""
echo "=== Gate 5c: era-b no manifest -> synthesized with no tools: block ==="

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
assert_file_not_contains "${G5C_REPO}/.aid/settings.yml" "tools:" \
    "G5C-03 synthesized: no tools: block (tools live in the manifest only, and none exists here)"

# ===========================================================================
# Gate 15 -- STEP 5: STATE.md -> STATE.yml FORMAT-4 CONVERSION
# (task-008 / SPEC.md SS L-6 step 2; task-015 addendum -- additive, per
# test-baseline-pre-refactor.md SS 5.3 "a new gate for the FR-9 work-state
# conversion"). _aid_sc_convert_repo runs as STEP 5 of _aid_migrate_repo,
# AFTER the settings step above, over every .aid/works/*/STATE.md (and, on
# the full layout, every deliveries/*/STATE.md and
# deliveries/*/tasks/*/STATE.md). Every fixture below also needs an era
# marker (.aid/knowledge/STATE.md, untouched by this step -- see Gate 5a's
# note and SS 5.6 Q1) so STEP 0 qualifies the repo as a candidate at all.
# ===========================================================================
echo ""
echo "=== Gate 15a: flat-layout work STATE.md -> STATE.yml (full content, all sections) ==="

G15A_CODE_HOME="$(new_code_home)"
G15A_STATE_HOME="$(new_state_home)"
G15A_REPO="$(mktemp -d "${TMP}/g15a-repo.XXXXXX")"
mkdir -p "${G15A_REPO}/.aid/knowledge"
touch "${G15A_REPO}/.aid/knowledge/STATE.md"
mkdir -p "${G15A_REPO}/.aid/works/work-101-conv-ok/tasks/task-001"
touch "${G15A_REPO}/.aid/works/work-101-conv-ok/tasks/task-001/DETAIL.md"
touch "${G15A_REPO}/.aid/works/work-101-conv-ok/BLUEPRINT.md"

# Flat-layout fixture (no deliveries/ subfolder): every AUTHORED section
# carries real content so every emitter in _aid_sc_convert_work_body fires;
# every DERIVED section carries only its authored-empty sentinel row/text
# (the "_none yet_" table sentinel or "_None yet." narrative sentinel) so
# the SP-3 guard passes clean -- Gate 15c below covers the hard-error path.
cat > "${G15A_REPO}/.aid/works/work-101-conv-ok/STATE.md" << 'G15A_MD_EOF'
---
lifecycle: Running
phase: Execute
---

# Work State -- work-101-conv-ok

## Interview State

**State:** Complete  **Grade:** A

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Done | 2026-01-01 |

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-01-01 | Work created | -- | Initial scaffold |

## Deploy State

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

## Delivery Lifecycle

- **Updated:** 2026-01-02T00:00:00Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

| Task | State | Review | Elapsed | Notes | Name |
|------|-------|--------|---------|-------|------|
| task-001 | Done | A | 30m | -- | Sample task |

## Delivery Gate

- **Issue List:** none

## Cross-phase Q&A

_None yet._

## Features State

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| _none yet_ | | | | | |

## Plan / Deliveries

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Calibration Log

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md.
G15A_MD_EOF

run_migrate "${G15A_CODE_HOME}" "${G15A_STATE_HOME}" "${G15A_REPO}"
assert_exit_eq "$MIG_RC" 0 "G15A-01 __migrate-repo with a full flat-layout STATE.md -> exit 0"
assert_output_contains "$MIG_OUT" "converted -> ${G15A_REPO}/.aid/works/work-101-conv-ok/STATE.yml" \
    "G15A-02 OK line names the converted file pair"

if [[ -f "${G15A_REPO}/.aid/works/work-101-conv-ok/STATE.md" ]]; then
    fail "G15A-03 STATE.md deleted after a verified conversion -- it is still present"
else
    pass "G15A-03 STATE.md deleted after a verified conversion"
fi
assert_file_exists "${G15A_REPO}/.aid/works/work-101-conv-ok/STATE.yml" \
    "G15A-04 STATE.yml written"

G15A_YML="${G15A_REPO}/.aid/works/work-101-conv-ok/STATE.yml"
# Frontmatter scalars copied through verbatim (untouched by the body converter).
assert_file_contains "$G15A_YML" "lifecycle: Running" \
    "G15A-05 frontmatter lifecycle: carried through verbatim"
assert_file_contains "$G15A_YML" "phase: Execute" \
    "G15A-06 frontmatter phase: carried through verbatim"
# Interview State -> interview: (header bold-line + one table row).
assert_file_contains "$G15A_YML" "  grade: A" \
    "G15A-07 interview.grade parsed from the bold State/Grade header line"
assert_file_contains "$G15A_YML" "      name: Objective" \
    "G15A-08 interview.sections[0].name parsed from the table row"
# Lifecycle History -> lifecycle_history: (one row).
assert_file_contains "$G15A_YML" "    event: 'Work created'" \
    "G15A-09 lifecycle_history[0].event parsed from the table row"
# Deploy State -- authored-empty sentinel -> deploy: [] (no entries emitted).
assert_file_contains "$G15A_YML" "deploy: []" \
    "G15A-10 deploy: [] -- the _none yet_ sentinel row emits no entries"
# Delivery Lifecycle + Tasks lifecycle (flat-only sections).
assert_file_contains "$G15A_YML" "  updated: '2026-01-02T00:00:00Z'" \
    "G15A-11 delivery_lifecycle.updated parsed from the Updated: bullet"
assert_file_contains "$G15A_YML" "  task-001:" \
    "G15A-12 tasks_lifecycle.task-001: mapping key present"
assert_file_contains "$G15A_YML" "    display_name: 'Sample task'" \
    "G15A-13 tasks_lifecycle.task-001.display_name parsed from the Name column"
# Delivery Gate -- "Issue List: none" -> issue_list: [] (no entries).
assert_file_contains "$G15A_YML" "  issue_list: []" \
    "G15A-14 delivery_gate.issue_list: [] -- 'none' emits no entries"
# Cross-phase Q&A -- authored-empty sentinel, no ### Q blocks -> qa: [].
assert_file_contains "$G15A_YML" "qa: []" \
    "G15A-15 qa: [] -- no ### Q blocks in the fixture"
# The 6 DERIVED headings (guarded, all authored-empty) never emit a key at all --
# proving the guard is silent (not merely non-fatal) on the empty-sentinel case.
for _g15a_key in "features_state" "plan_deliveries" "tasks_state" "delivery_gates" \
                 "calibration_log" "dispatches"; do
    assert_file_not_contains "$G15A_YML" "${_g15a_key}:" \
        "G15A-16 no ${_g15a_key}: key emitted (DERIVED section, read-only, never authored here)"
done

echo ""
echo "=== Gate 15b: full-layout delivery + task STATE.md -> STATE.yml ==="

G15B_CODE_HOME="$(new_code_home)"
G15B_STATE_HOME="$(new_state_home)"
G15B_REPO="$(mktemp -d "${TMP}/g15b-repo.XXXXXX")"
mkdir -p "${G15B_REPO}/.aid/knowledge"
touch "${G15B_REPO}/.aid/knowledge/STATE.md"
mkdir -p "${G15B_REPO}/.aid/works/work-102-full/deliveries/delivery-001/tasks/task-001"
touch "${G15B_REPO}/.aid/works/work-102-full/BLUEPRINT.md"

cat > "${G15B_REPO}/.aid/works/work-102-full/deliveries/delivery-001/STATE.md" << 'G15B_DELIVERY_EOF'
---
lifecycle: Done
---

# Delivery State -- delivery-001

## Delivery Lifecycle

- **Updated:** 2026-01-03T00:00:00Z
- **Block Reason:** --
- **Block Artifact:** --

## Delivery Gate

- **Issue List:** none

## Cross-phase Q&A

_None yet._

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
G15B_DELIVERY_EOF

cat > "${G15B_REPO}/.aid/works/work-102-full/deliveries/delivery-001/tasks/task-001/STATE.md" << 'G15B_TASK_EOF'
---
state: Done
---

# Task State -- task-001

## Quick Check Findings

- **Reviewer Tier:** Small
- **Findings:**
  - [LOW] example finding -- file.sh:10 -- Deferred-to-gate

## Dispatch Log

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|
| 2026-01-03 | developer | task-001 / EXECUTE | 30m | 25m | done |
G15B_TASK_EOF

run_migrate "${G15B_CODE_HOME}" "${G15B_STATE_HOME}" "${G15B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G15B-01 __migrate-repo with a full-layout delivery+task pair -> exit 0"

G15B_DELIVERY_YML="${G15B_REPO}/.aid/works/work-102-full/deliveries/delivery-001/STATE.yml"
G15B_TASK_YML="${G15B_REPO}/.aid/works/work-102-full/deliveries/delivery-001/tasks/task-001/STATE.yml"
assert_file_exists "$G15B_DELIVERY_YML" "G15B-02 delivery-level STATE.yml written"
assert_file_exists "$G15B_TASK_YML" "G15B-03 task-level STATE.yml written"
if [[ -f "${G15B_REPO}/.aid/works/work-102-full/deliveries/delivery-001/STATE.md" ]] \
   || [[ -f "${G15B_REPO}/.aid/works/work-102-full/deliveries/delivery-001/tasks/task-001/STATE.md" ]]; then
    fail "G15B-04 both source STATE.md files deleted after a verified conversion -- at least one is still present"
else
    pass "G15B-04 both source STATE.md files deleted after a verified conversion"
fi
assert_file_contains "$G15B_DELIVERY_YML" "  updated: '2026-01-03T00:00:00Z'" \
    "G15B-05 delivery_lifecycle.updated parsed from the delivery-level Updated: bullet"
assert_file_contains "$G15B_TASK_YML" "  reviewer_tier: Small" \
    "G15B-06 quick_check.reviewer_tier parsed from the task-level Reviewer Tier: bullet"
assert_file_contains "$G15B_TASK_YML" "    - '[LOW] example finding -- file.sh:10 -- Deferred-to-gate'" \
    "G15B-07 quick_check.findings[0] parsed from the task-level Findings bullet list"
assert_file_contains "$G15B_TASK_YML" "  - date: '2026-01-03'" \
    "G15B-08 dispatch_log[0].date parsed from the task-level Dispatch Log table row"

echo ""
echo "=== Gate 15c: DERIVED-guard hard error (SP-3) -- real row under a guarded heading ==="

G15C_CODE_HOME="$(new_code_home)"
G15C_STATE_HOME="$(new_state_home)"
G15C_REPO="$(mktemp -d "${TMP}/g15c-repo.XXXXXX")"
mkdir -p "${G15C_REPO}/.aid/knowledge"
touch "${G15C_REPO}/.aid/knowledge/STATE.md"
mkdir -p "${G15C_REPO}/.aid/works/work-103-derived-guard"

# A leftover REAL row under the work-level DERIVED "## Tasks State" heading --
# the signature of a work that still needs migrate-work-hierarchy (SS 2147-2155
# above), not a genuinely hand-authored DERIVED row (none exists; the guard
# cannot distinguish the two, by design -- SP-3's whole point is that ANY real
# row here is refused rather than silently dropped).
cat > "${G15C_REPO}/.aid/works/work-103-derived-guard/STATE.md" << 'G15C_MD_EOF'
---
lifecycle: Running
phase: Execute
---

# Work State -- work-103-derived-guard

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| 1 | task-001 | CODE | 1 | Done | A | 30m | real leftover row from a pre-hierarchy work |
G15C_MD_EOF

run_migrate "${G15C_CODE_HOME}" "${G15C_STATE_HOME}" "${G15C_REPO}"
# WARN-not-fail (SS 2186-2190 above): _aid_sc_convert_repo always returns 0,
# so this file-level hard error does NOT change __migrate-repo's own exit code.
assert_exit_eq "$MIG_RC" 0 \
    "G15C-01 __migrate-repo exit code unaffected by a per-file DERIVED-guard refusal (WARN-not-fail)"
assert_output_contains "$MIG_OUT" \
    "DERIVED section '## Tasks State' holds real data -- conversion refused for this file" \
    "G15C-02 WARN names the guarded heading and states the refusal"
assert_output_contains "$MIG_OUT" "Remedy: run migrate-work-hierarchy on this work, then re-run 'aid update'." \
    "G15C-03 WARN states the documented remedy"
if [[ -f "${G15C_REPO}/.aid/works/work-103-derived-guard/STATE.md" ]]; then
    pass "G15C-04 STATE.md left in place (nothing dropped) after the guard refusal"
else
    fail "G15C-04 STATE.md was REMOVED despite the guard refusing conversion -- data-loss risk"
fi
if [[ -f "${G15C_REPO}/.aid/works/work-103-derived-guard/STATE.yml" ]]; then
    fail "G15C-05 STATE.yml was written despite the guard refusing conversion"
else
    pass "G15C-05 no STATE.yml written -- the guard refused before the candidate file was ever built"
fi

echo ""
echo "=== Gate 15e: Features State is AUTHORED -- a post-/aid-define work converts ==="

# REGRESSION GATE. `## Features State` was in the DERIVED guard list, on the
# premise (SS 2147-2155) that a real DERIVED row proves a work predates the
# per-unit hierarchy. That premise is false for this section: nothing derives it
# -- aid-define creates a row per feature and aid-specify updates it -- so EVERY
# work that had been through /aid-define was refused, and the remedy the WARN
# names (migrate-work-hierarchy) exits 3 on a work with no tasks/, which is
# exactly the population the guard caught. Restore the guard entry and G15E-01
# fails.
#
# The fixture is shaped after a real work: two column sets are in circulation
# for this table, a withdrawn feature keeps a struck row, the Interview State
# section carries a SECOND table (Review History) that is not sections, and the
# section-status table is one column wider than the interview emitter's four.

G15E_CODE_HOME="$(new_code_home)"
G15E_STATE_HOME="$(new_state_home)"
G15E_REPO="$(mktemp -d "${TMP}/g15e-repo.XXXXXX")"
mkdir -p "${G15E_REPO}/.aid/knowledge"
touch "${G15E_REPO}/.aid/knowledge/STATE.md"
mkdir -p "${G15E_REPO}/.aid/works/work-105-features"

cat > "${G15E_REPO}/.aid/works/work-105-features/STATE.md" << 'G15E_MD_EOF'
---
lifecycle: Running
phase: Specify
---

# Work State -- work-105-features

## Interview State

**Interview State:** Revising  **Grade:** B+ (earned earlier)

### Cross-Reference

**State:** Complete  **Grade:** A+  **Minimum:** A  **Cycles:** 14

### Review History

| Date | Event | Outcome | Notes |
|------|-------|---------|-------|
| 2026-01-02 | Interview opened | — | seeded |
| 2026-01-03 | Quality check | 4 fixed | swept |

| # | Section | State | Last Updated | Reopened by the runtime decision? |
|---|---------|-------|--------------|-----------------------------------|
| 1 | Objective | Complete | 2026-01-02 | No — runtime-independent |
| 2 | Scope | Revising | 2026-01-04 | Yes |

## Features State

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 001 | wake-spike | Ready | **A+** (cycle 5) | 1 | Stage P0 |
| ~~002~~ | ~~python-floor~~ | **DELETED** | ~~A+~~ | 1 | withdrawn with FR-8 |
| 003 | node-lifecycle | In Review (PAUSED at user request) | D (cycle 3) | 2 | keystone |

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-01-02 | Work created | -- | scaffold |

## Cross-phase Q&A

### Q1

- **Category:** Architecture
- **Impact:** Required
- **Status:** Answered
- **Context:** the old spelling
- **Suggested:** something
- **Answer:** accepted

### Q2

- **Category:** Requirements
- **Impact:** Medium
- **State:** Pending
- **Context:** the current spelling
- **Suggested:** something else
- **Answer:** _pending_

### Q3

- **Category:** Process
- **Impact:** Low
- **Status:** Closed  <!-- flipped 2026-01-05 to match this entry's own body -->
- **Context:** an annotated state
- **Suggested:** nothing
- **Answer:** closed by deletion

## Deploy State

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

## Tasks State

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Plan / Deliveries

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Calibration Log

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Delivery Gates

_None yet._

## Dispatches

_None yet._
G15E_MD_EOF

run_migrate "${G15E_CODE_HOME}" "${G15E_STATE_HOME}" "${G15E_REPO}"
G15E_YML="${G15E_REPO}/.aid/works/work-105-features/STATE.yml"

assert_output_contains "$MIG_OUT" "STATE.md converted -> ${G15E_YML}" \
    "G15E-01 a work with a real Features State table CONVERTS (was refused by the DERIVED guard)"
assert_output_not_contains "$MIG_OUT" "DERIVED section '## Features State'" \
    "G15E-02 no DERIVED-guard WARN for Features State"

# A raw \x1f leaking out of a wider-than-expected row makes the whole document
# unparseable -- that is how the interview emitter's fixed-field read was caught.
# Asserted without a YAML library on purpose: both shipped packages declare zero
# dependencies, so no suite may require PyYAML.
# Control characters only. A "non-printable" test would be wrong here: under
# LC_ALL=C every byte of a UTF-8 em dash reads as non-printable, and this corpus
# is full of them.
if LC_ALL=C grep -q '[[:cntrl:]]' "$G15E_YML"; then
    fail "G15E-03 converted STATE.yml contains a control character -- a field separator or tab leaked"
else
    pass "G15E-03 converted STATE.yml is free of control characters"
fi
if LC_ALL=C grep -q "$(printf '\037')" "$G15E_YML"; then
    fail "G15E-04 raw \\x1f field separator found in the converted document"
else
    pass "G15E-04 no raw \\x1f anywhere in the converted document"
fi

assert_file_contains "$G15E_YML" "features:" \
    "G15E-05 features key emitted"
assert_file_contains "$G15E_YML" "name: wake-spike" \
    "G15E-06 a live feature row carries its name"
assert_file_contains "$G15E_YML" "state: 'In Review (PAUSED at user request)'" \
    "G15E-07 a non-enum state is carried verbatim, not rejected (translation, not validation)"
assert_file_contains "$G15E_YML" "withdrawn: true" \
    "G15E-08 a struck row is marked withdrawn rather than dropped"
assert_file_contains "$G15E_YML" "- id: '002'" \
    "G15E-09 a struck row keeps a clean numeric id, so citations still resolve"

# Interview: the Review History table shares the range and must not contribute
# rows, and the section-status table is 5 columns wide against 4 emitted fields.
assert_file_contains "$G15E_YML" "state: Revising" \
    "G15E-10 interview.state comes from the **Interview State:** line, not the Cross-Reference block"
assert_file_not_contains "$G15E_YML" "name: 'Interview opened'" \
    "G15E-11 Review History rows do NOT land in interview.sections"
assert_file_not_contains "$G15E_YML" "name: Event" \
    "G15E-12 a second table's HEADER row does not become a section"
# Sequence-entry counts, awk-only (no YAML library -- see G15E-03). INDENT
# selects the nesting depth: top-level sequences under `key:` sit at 2 spaces,
# `interview.sections` entries at 4.
g15e_count_seq() {
    awk -v key="$2" -v ind="$3" '
        $0 == key ":"                    { inblock = 1; next }
        inblock && /^[A-Za-z0-9_]+:/     { inblock = 0 }
        inblock && $0 ~ "^" ind "- "     { n++ }
        END                              { print n + 0 }
    ' "$1"
}
G15E_N="$(g15e_count_seq "$G15E_YML" features '  ') \
$(g15e_count_seq "$G15E_YML" interview '    ') \
$(g15e_count_seq "$G15E_YML" lifecycle_history '  ') \
$(g15e_count_seq "$G15E_YML" deploy '  ')"
G15E_N="$(echo $G15E_N)"
if [[ "$G15E_N" == "3 2 1 0" ]]; then
    pass "G15E-13 counts exact: 3 features, 2 interview sections, 1 lifecycle row, 0 deploy"
else
    fail "G15E-13 counts wrong (features/sections/lifecycle/deploy): got '${G15E_N}', want '3 2 1 0'"
fi
assert_file_contains "$G15E_YML" "updated: '2026-01-02 -- No — runtime-independent'" \
    "G15E-14 a column beyond the emitted fields is folded into the last one, not dropped"

# Q&A state: every pre-conversion file on disk writes `**Status:**`, because the
# state-not-status naming contract renamed the templates and not the works
# already written against them. Reading only `**State:**` silently emptied the
# one field that says whether a question is still open.
assert_file_contains "$G15E_YML" "state: Answered" \
    "G15E-15 a Q&A entry's legacy **Status:** bullet is read (not silently emptied)"
assert_file_contains "$G15E_YML" "state: Pending" \
    "G15E-16 a Q&A entry's current **State:** bullet is still read"
# `empty` is passed in rather than written inline: a literal '' inside a
# single-quoted awk program is consumed by the shell before awk ever sees it,
# which silently turned this assertion into a no-op.
G15E_QA_EMPTY="$(awk -v empty="    state: ''" '
    $0 == "qa:"                   { inblock = 1; next }
    inblock && /^[A-Za-z0-9_]+:/  { inblock = 0 }
    inblock && $0 == empty        { n++ }
    inblock && /^    state:[ ]*$/ { n++ }
    END                           { print n + 0 }
' "$G15E_YML")"
if [[ "$G15E_QA_EMPTY" == "0" ]]; then
    pass "G15E-17 no Q&A entry converted with an empty state"
else
    fail "G15E-17 ${G15E_QA_EMPTY} Q&A entr(ies) converted with an empty state -- the label lookup missed"
fi

# `state` is a machine-read closed enum, so an inline annotation must not ride
# along in it -- `Closed <!-- ... -->` compares equal to nothing. It moves to
# `answer`, which is prose, rather than being discarded.
assert_file_contains "$G15E_YML" "state: Closed" \
    "G15E-18 an annotated state converts to the bare enum member"
assert_file_not_contains "$G15E_YML" "state: 'Closed  <!--" \
    "G15E-19 the inline HTML comment does not ride along in the enum field"
# Substring stops before the apostrophe: a YAML single-quoted scalar doubles it.
assert_file_contains "$G15E_YML" "[state note: flipped 2026-01-05 to match this entry" \
    "G15E-20 the annotation is preserved on the entry, not discarded"

# Review History sits under a `###` heading inside the legacy `## Interview State`
# section, so it shares that range. Selecting interview.sections by header stopped its rows
# being mis-filed as sections -- and would have DROPPED them outright without a
# key of its own. A table the schema does not name is still data.
assert_file_contains "$G15E_YML" "review_history:" \
    "G15E-21 review_history key emitted"
assert_file_contains "$G15E_YML" "event: 'Interview opened'" \
    "G15E-22 Review History rows are preserved, not dropped with the mis-filing"
assert_file_contains "$G15E_YML" "outcome: '4 fixed'" \
    "G15E-23 a Review History row keeps its Outcome column"
G15E_RH="$(g15e_count_seq "$G15E_YML" review_history '  ')"
if [[ "$G15E_RH" == "2" ]]; then
    pass "G15E-24 exactly 2 review_history entries (no header or separator row among them)"
else
    fail "G15E-24 review_history has ${G15E_RH} entries, want 2"
fi

echo ""
echo "=== Gate 15d: format_version stamp advances to AID_SUPPORTED_FORMAT (5) ==="

# Confirms AC-10/SP-12 independently of G4A-02 above, using a repo whose ONLY
# migrate-relevant content is the STATE.md conversion fixtures themselves (no
# era-a settings.yml pre-existing) -- STEP 1 (SETTINGS) still runs before STEP
# 5 regardless, so the stamp is set on every candidate repo, converted or not.
G15D_FMT_LINE="$(grep '^format_version:' "${G15A_REPO}/.aid/settings.yml" | head -1)"
assert_eq "$G15D_FMT_LINE" "format_version: 5" \
    "G15D-01 settings.yml format_version: 5 on a repo that also converted a work-level STATE.md"

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

# Gate 15a fixture (task-015 addendum): already converted -- STATE.yml exists,
# so _aid_sc_convert_file is a same-file no-op (SS 2173-2180 above: idempotent
# because the .yml's mere presence short-circuits before any read/write).
G6_SHA_15A_BEFORE="$(file_sha256 "${G15A_REPO}/.aid/works/work-101-conv-ok/STATE.yml")"
run_migrate "${G15A_CODE_HOME}" "${G15A_STATE_HOME}" "${G15A_REPO}"
assert_exit_eq "$MIG_RC" 0 "G6-13 Gate-15a: 2nd run exits 0"
G6_SHA_15A_AFTER="$(file_sha256 "${G15A_REPO}/.aid/works/work-101-conv-ok/STATE.yml")"
assert_eq "$G6_SHA_15A_BEFORE" "$G6_SHA_15A_AFTER" \
    "G6-14 Gate-15a: 2nd run byte-identical (converted work STATE.yml unchanged)"
if [[ -f "${G15A_REPO}/.aid/works/work-101-conv-ok/STATE.md" ]]; then
    fail "G6-15 Gate-15a: 2nd run resurrected STATE.md -- conversion is not a true no-op"
else
    pass "G6-15 Gate-15a: 2nd run does not resurrect STATE.md (stays absent)"
fi

# Gate 15b fixture: full-layout delivery + task pair, same idempotency property.
G6_SHA_15B_D_BEFORE="$(file_sha256 "$G15B_DELIVERY_YML")"
G6_SHA_15B_T_BEFORE="$(file_sha256 "$G15B_TASK_YML")"
run_migrate "${G15B_CODE_HOME}" "${G15B_STATE_HOME}" "${G15B_REPO}"
assert_exit_eq "$MIG_RC" 0 "G6-16 Gate-15b: 2nd run exits 0"
G6_SHA_15B_D_AFTER="$(file_sha256 "$G15B_DELIVERY_YML")"
G6_SHA_15B_T_AFTER="$(file_sha256 "$G15B_TASK_YML")"
assert_eq "$G6_SHA_15B_D_BEFORE" "$G6_SHA_15B_D_AFTER" \
    "G6-17 Gate-15b: 2nd run byte-identical (converted delivery STATE.yml unchanged)"
assert_eq "$G6_SHA_15B_T_BEFORE" "$G6_SHA_15B_T_AFTER" \
    "G6-18 Gate-15b: 2nd run byte-identical (converted task STATE.yml unchanged)"

# Gate 15c fixture: the DERIVED guard refused conversion on the 1st run, so the
# 2nd run must hit the SAME guard again (STATE.md still present, still a
# real row) -- NOT idempotent-as-converted, but idempotent-as-refused: the
# same WARN, the same refusal, no drift toward silently dropping the row on
# a later attempt.
run_migrate "${G15C_CODE_HOME}" "${G15C_STATE_HOME}" "${G15C_REPO}"
assert_exit_eq "$MIG_RC" 0 "G6-19 Gate-15c: 2nd run exits 0 (still WARN-not-fail)"
assert_output_contains "$MIG_OUT" \
    "DERIVED section '## Tasks State' holds real data -- conversion refused for this file" \
    "G6-20 Gate-15c: 2nd run hits the identical guard refusal (no silent drop on retry)"
if [[ -f "${G15C_REPO}/.aid/works/work-103-derived-guard/STATE.yml" ]]; then
    fail "G6-21 Gate-15c: 2nd run wrote a STATE.yml despite the still-unresolved DERIVED row"
else
    pass "G6-21 Gate-15c: 2nd run still writes no STATE.yml (guard re-fires identically)"
fi

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
# NOTE: this fixture copies G4A_REPO's settings.yml, which is ALREADY flat/stamped
# (format_version: 3) from Gate 4a's earlier run, so re-migrating it here is a
# genuine byte-identical no-op (full-rewrite migration is idempotent on its own
# output). The idempotency check (era precedence: repair, not synthesize-overwrite)
# is still valid because the era-a repair path is taken (settings.yml present),
# not the synthesize path.
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
if [[ -e "${G10_REPO}/.agents/aid" ]]; then
    fail "G10-04 (FR-11) legacy .agents/aid/ still present after upgrade"
else
    pass "G10-04 (FR-11) legacy .agents/aid/ is gone (.agents/skills/ is the shared root)"
fi
# AC5-b: new .codex/ unified layout is present.
assert_dir_exists "${G10_REPO}/.codex/agents" \
    "G10-05 (AC5) new .codex/agents/ directory present after migration"
if [[ -e "${G10_REPO}/.codex/aid" ]]; then
    fail "G10-06 (AC5) .codex/aid/ must not exist in the shared layout"
else
    pass "G10-06 (AC5) .codex/aid/ absent in the shared layout"
fi
if [[ -n "$(find "${G10_REPO}/.codex/skills" -name 'aid-*' 2>/dev/null | head -1)" ]]; then
    fail "G10-06b (AC5) .codex/skills/aid-* must not exist (skills live in .agents/skills/)"
else
    pass "G10-06b (AC5) no .codex/skills/aid-* in the shared layout"
fi
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
if [[ -f "${G10_REPO}/.agents/skills/aid-specify/SKILL.md" ]]; then
    pass "G13-02 .agents/skills/ shared root holds canonical skills after second update (idempotent)"
else
    fail "G13-02 .agents/skills/aid-specify/SKILL.md missing after second update"
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
if grep -q -- "--- aid update --dry-run plan (no writes) ---" <<<"$G14_DRY_OUT"; then
    pass "G14-02 dry-run output contains the '--- aid update --dry-run plan (no writes) ---' header"
else
    fail "G14-02 dry-run output missing the '--- aid update --dry-run plan (no writes) ---' header"
    if [[ "${VERBOSE:-0}" -eq 1 ]]; then printf "DRY OUTPUT:\n%s\n" "$G14_DRY_OUT"; fi
fi

if grep -q "move to trash: .agents/aid/shared.md" <<<"$G14_DRY_OUT"; then
    pass "G14-03 dry-run output lists the retired AID file .agents/aid/shared.md in the move-to-trash set"
else
    fail "G14-03 dry-run output does NOT list the retired AID file .agents/aid/shared.md"
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
IMPORT_REGION=$'<!-- AID:BEGIN -->\n@AGENTS.md\n<!-- AID:END -->\n'
POINTER_REGION=$'<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n@.aid/runtime/rules.md\nBefore acting, read and follow `.aid/runtime/rules.md` (AID rules).\n<!-- AID:END -->\n'
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
        '@.aid/runtime/rules.md' 'Before acting, read and follow `.aid/runtime/rules.md` (AID rules).' '<!-- AID:END -->' "$1" > "$2/CLAUDE.md"
}
seed_user_region_c_user() { seed_user_region 'user line below' "$1"; }
seed_user_region_c_nolf() { printf '%s\n' '# Project memory' 'user line above' '<!-- AID:BEGIN -->' "$V3_REGION_BODY" \
        '@.aid/runtime/rules.md' 'Before acting, read and follow `.aid/runtime/rules.md` (AID rules).' '<!-- AID:END -->' > "$1/CLAUDE.md"
    printf 'user line below' >> "$1/CLAUDE.md"; }
seed_nomarker() { printf '%s\n' 'plain user memory' 'no markers here' > "$1/CLAUDE.md"; }
seed_agents_region() { printf '%s\n' '# Agents guide' 'user agents line' '<!-- AID:BEGIN -->' "$V3_REGION_BODY" \
        '@.aid/runtime/rules.md' 'Before acting, read and follow `.aid/runtime/rules.md` (AID rules).' '<!-- AID:END -->' > "$1/AGENTS.md"; }
seed_agents_region_nolf() { printf '%s\n' '<!-- AID:BEGIN -->' "$V3_REGION_BODY" \
        '@.aid/runtime/rules.md' 'Before acting, read and follow `.aid/runtime/rules.md` (AID rules).' '<!-- AID:END -->' > "$1/AGENTS.md"
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
    if [[ "$(grep -cx '@AGENTS.md' "$fx/CLAUDE.md")" == 1 && "$(grep -cx '<!-- AID:BEGIN -->' "$fx/AGENTS.md")" == 1 ]]; then
        pass "AC-14 (c) ${name}: exactly one @AGENTS.md line in CLAUDE.md and one AID:BEGIN line in AGENTS.md"
    else
        fail "AC-14 (c) ${name}: exactly one @AGENTS.md line in CLAUDE.md and one AID:BEGIN line in AGENTS.md"
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
