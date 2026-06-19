#!/usr/bin/env bash
# test-migrate-hierarchy.sh -- canonical suite for migrate-work-hierarchy.sh + .ps1
#
# Guards:
#   1. Hierarchy creation: delivery-NNN/{SPEC,STATE}.md + delivery-NNN/tasks/task-NNN/{SPEC,STATE}.md
#   2. No data loss: every task's State/Review/Elapsed/Notes, Quick Check Findings, Dispatch rows;
#      every delivery's gate block + Cross-phase Q&A; work STATE.md rewritten to derived placeholders.
#   3. Correct delivery placement: Source -> delivery-NNN token; task-004 (no token) -> delivery-001
#      with a warning emitted.
#   4. Idempotency: second run is a no-op (no duplication, same file tree).
#   5. Bash <-> PowerShell parity: both helpers produce equivalent results against the golden fixture.
#      If pwsh is absent the parity gate is skipped (exit 0 from the suite).
#
# Isolation discipline:
#   - HOME pinned to a throwaway dir so no home-relative write touches the real $HOME.
#   - All sandbox dirs live under mktemp -d (TMP), cleaned up on EXIT.
#   - Isolation canary: asserts no NEW .aid dirs escaped the throwaway HOME.
#   - NEVER runs a $HOME / $AID_HOME scan.
#
# Usage:
#   bash tests/canonical/test-migrate-hierarchy.sh [--verbose]
#   HOME=$(mktemp -d) AID_HOME="$HOME/.aid" bash tests/canonical/test-migrate-hierarchy.sh
# Exit codes: 0 all pass / 1 any fail.
#
# ASCII-only (see tests/canonical/test-ascii-only.sh).

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

MIGRATE_SH="${REPO_ROOT}/canonical/scripts/migrate/migrate-work-hierarchy.sh"
MIGRATE_PS1="${REPO_ROOT}/canonical/scripts/migrate/migrate-work-hierarchy.ps1"
FIXTURE_SRC="${REPO_ROOT}/tests/canonical/fixtures/migrate/fixture-source/work-999-migration-test"
GOLDEN_DIR="${REPO_ROOT}/tests/canonical/fixtures/migrate/fixture/work-999-migration-test"

[[ -f "$MIGRATE_SH" ]]  || { echo "ERROR: migrate-work-hierarchy.sh not found at $MIGRATE_SH" >&2; exit 1; }
[[ -f "$MIGRATE_PS1" ]] || { echo "ERROR: migrate-work-hierarchy.ps1 not found at $MIGRATE_PS1" >&2; exit 1; }
[[ -d "$FIXTURE_SRC" ]] || { echo "ERROR: fixture-source dir not found at $FIXTURE_SRC" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Global tmp dir + HOME pin
# ---------------------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

REAL_HOME="${HOME}"
# Snapshot pre-existing .aid dirs under real HOME for the isolation canary.
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"

export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

# ---------------------------------------------------------------------------
# pwsh detection (skip PS parity gate if absent)
# ---------------------------------------------------------------------------
if command -v pwsh >/dev/null 2>&1; then
    PWSH="pwsh"
elif [[ -x "/home/andre.vianna/.local/pwsh/pwsh" ]]; then
    PWSH="/home/andre.vianna/.local/pwsh/pwsh"
else
    PWSH=""
fi

# ---------------------------------------------------------------------------
# Helper: file_contains FILE PATTERN LABEL
# Uses grep -eF to handle patterns that begin with '-' (avoids option-parse
# ambiguity in ugrep/GNU grep when the pattern string starts with a dash).
# ---------------------------------------------------------------------------
file_has() {
    local file="$1" pattern="$2" label="$3"
    if grep -qFe "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label -- pattern not found: '$pattern' in $file"
        [[ "$VERBOSE" -eq 1 ]] && echo "---FILE---" && cat "$file" && echo "---END---"
    fi
}

file_lacks() {
    local file="$1" pattern="$2" label="$3"
    if ! grep -qFe "$pattern" "$file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label -- unexpected pattern found: '$pattern' in $file"
    fi
}

# ---------------------------------------------------------------------------
# Helper: make a fresh sandbox copy of the fixture-source.
# Returns the path to the copied work dir.
# ---------------------------------------------------------------------------
make_sandbox() {
    local tag="$1"
    local sandbox
    sandbox="$(mktemp -d "${TMP}/sandbox-${tag}.XXXXXX")"
    cp -r "${FIXTURE_SRC}/." "${sandbox}/work-999-migration-test"
    echo "${sandbox}/work-999-migration-test"
}

# ---------------------------------------------------------------------------
# Helper: run the bash migrate helper on a sandbox dir.
# Sets MIG_OUT and MIG_RC.
# ---------------------------------------------------------------------------
run_bash_migrate() {
    local work_dir="$1"
    MIG_OUT=$(bash "${MIGRATE_SH}" "${work_dir}" 2>&1)
    MIG_RC=$?
}

# ---------------------------------------------------------------------------
# Helper: run the PS1 migrate helper on a sandbox dir.
# Sets PS_OUT and PS_RC.
# ---------------------------------------------------------------------------
run_ps_migrate() {
    local work_dir="$1"
    PS_OUT=$("${PWSH}" -NoProfile -NonInteractive -File "${MIGRATE_PS1}" "${work_dir}" 2>&1)
    PS_RC=$?
}

# ===========================================================================
# Gate 1 -- Bash: initial migration succeeds + hierarchy created
# ===========================================================================
echo ""
echo "=== Gate 1: bash migrate -- hierarchy created ==="

G1_WORK="$(make_sandbox g1)"

run_bash_migrate "${G1_WORK}"
assert_exit_eq "${MIG_RC}" 0 "G1-01 migrate-work-hierarchy.sh exits 0"

# Delivery-001 structure.
assert_dir_exists  "${G1_WORK}/delivery-001"                          "G1-02 delivery-001/ dir created"
assert_file_exists "${G1_WORK}/delivery-001/SPEC.md"                  "G1-03 delivery-001/SPEC.md created"
assert_file_exists "${G1_WORK}/delivery-001/STATE.md"                 "G1-04 delivery-001/STATE.md created"
assert_dir_exists  "${G1_WORK}/delivery-001/tasks"                    "G1-05 delivery-001/tasks/ dir created"
assert_file_exists "${G1_WORK}/delivery-001/tasks/task-001/SPEC.md"   "G1-06 delivery-001/tasks/task-001/SPEC.md"
assert_file_exists "${G1_WORK}/delivery-001/tasks/task-001/STATE.md"  "G1-07 delivery-001/tasks/task-001/STATE.md"
assert_file_exists "${G1_WORK}/delivery-001/tasks/task-002/SPEC.md"   "G1-08 delivery-001/tasks/task-002/SPEC.md"
assert_file_exists "${G1_WORK}/delivery-001/tasks/task-002/STATE.md"  "G1-09 delivery-001/tasks/task-002/STATE.md"
# task-004 has no Source token -> defaults to delivery-001.
assert_file_exists "${G1_WORK}/delivery-001/tasks/task-004/SPEC.md"   "G1-10 delivery-001/tasks/task-004/SPEC.md (default)"
assert_file_exists "${G1_WORK}/delivery-001/tasks/task-004/STATE.md"  "G1-11 delivery-001/tasks/task-004/STATE.md (default)"

# Delivery-002 structure.
assert_dir_exists  "${G1_WORK}/delivery-002"                          "G1-12 delivery-002/ dir created"
assert_file_exists "${G1_WORK}/delivery-002/SPEC.md"                  "G1-13 delivery-002/SPEC.md created"
assert_file_exists "${G1_WORK}/delivery-002/STATE.md"                 "G1-14 delivery-002/STATE.md created"
assert_file_exists "${G1_WORK}/delivery-002/tasks/task-003/SPEC.md"   "G1-15 delivery-002/tasks/task-003/SPEC.md"
assert_file_exists "${G1_WORK}/delivery-002/tasks/task-003/STATE.md"  "G1-16 delivery-002/tasks/task-003/STATE.md"

# Legacy flat task files must be retained.
assert_file_exists "${G1_WORK}/tasks/task-001.md" "G1-17 legacy tasks/task-001.md retained"
assert_file_exists "${G1_WORK}/tasks/task-004.md" "G1-18 legacy tasks/task-004.md retained"

# ===========================================================================
# Gate 2 -- Bash: data preservation (no data loss)
# ===========================================================================
echo ""
echo "=== Gate 2: bash migrate -- no data loss ==="

# Note: patterns avoid leading '-' to dodge ugrep/grep option-parse ambiguity;
# use grep -e via file_has() which passes -qFe to the grep binary.

# task-001: State=Done, Review=A+, Elapsed=2h, Notes=alpha done.
file_has "${G1_WORK}/delivery-001/tasks/task-001/STATE.md" \
    "**State:** Done"         "G2-01 task-001 State preserved"
file_has "${G1_WORK}/delivery-001/tasks/task-001/STATE.md" \
    "**Review:** A+"          "G2-02 task-001 Review preserved"
file_has "${G1_WORK}/delivery-001/tasks/task-001/STATE.md" \
    "**Elapsed:** 2h"         "G2-03 task-001 Elapsed preserved"
file_has "${G1_WORK}/delivery-001/tasks/task-001/STATE.md" \
    "**Notes:** alpha done"   "G2-04 task-001 Notes preserved"

# task-001 Quick Check Findings must carry the HIGH finding.
file_has "${G1_WORK}/delivery-001/tasks/task-001/STATE.md" \
    "[HIGH] Example deferred finding from task-001" \
    "G2-05 task-001 Quick Check Findings preserved"

# task-001 Dispatch row.
file_has "${G1_WORK}/delivery-001/tasks/task-001/STATE.md" \
    "| 2026-01-02 | developer | 1h | 2h | Done |" \
    "G2-06 task-001 dispatch row preserved"

# task-002: State=Done, Review=A+, Elapsed=1h, Notes=beta done.
file_has "${G1_WORK}/delivery-001/tasks/task-002/STATE.md" \
    "**State:** Done"         "G2-07 task-002 State preserved"
file_has "${G1_WORK}/delivery-001/tasks/task-002/STATE.md" \
    "**Review:** A+"          "G2-08 task-002 Review preserved"
file_has "${G1_WORK}/delivery-001/tasks/task-002/STATE.md" \
    "**Elapsed:** 1h"         "G2-09 task-002 Elapsed preserved"
file_has "${G1_WORK}/delivery-001/tasks/task-002/STATE.md" \
    "**Notes:** beta done"    "G2-10 task-002 Notes preserved"

# task-002 dispatch row.
file_has "${G1_WORK}/delivery-001/tasks/task-002/STATE.md" \
    "| 2026-01-02 | developer | 1h | 1h | Done |" \
    "G2-11 task-002 dispatch row preserved"

# task-003: State=In Progress, Notes=gamma wip.
file_has "${G1_WORK}/delivery-002/tasks/task-003/STATE.md" \
    "**State:** In Progress"  "G2-12 task-003 State preserved"
file_has "${G1_WORK}/delivery-002/tasks/task-003/STATE.md" \
    "**Notes:** gamma wip"    "G2-13 task-003 Notes preserved"

# task-004: State=Pending, Notes=no source token.
file_has "${G1_WORK}/delivery-001/tasks/task-004/STATE.md" \
    "**State:** Pending"             "G2-14 task-004 State preserved"
file_has "${G1_WORK}/delivery-001/tasks/task-004/STATE.md" \
    "**Notes:** no source token"     "G2-15 task-004 Notes preserved"

# delivery-001 gate block: Grade=A+.
file_has "${G1_WORK}/delivery-001/STATE.md" \
    "**Grade:** A+"                  "G2-16 delivery-001 gate Grade preserved"
file_has "${G1_WORK}/delivery-001/STATE.md" \
    "delivery-001 gate passed clean" "G2-17 delivery-001 gate Notes preserved"

# delivery-001 Cross-phase Q&A: Q1 entry.
file_has "${G1_WORK}/delivery-001/STATE.md" \
    "### Q1"                         "G2-18 delivery-001 Q&A Q1 heading preserved"
file_has "${G1_WORK}/delivery-001/STATE.md" \
    "delivery-001-scoped question about alpha task approach" \
    "G2-19 delivery-001 Q1 context preserved"

# delivery-002 gate block: Grade=Pending.
file_has "${G1_WORK}/delivery-002/STATE.md" \
    "**Grade:** Pending"             "G2-20 delivery-002 gate Grade preserved"

# delivery-002 Cross-phase Q&A: Q2 entry.
file_has "${G1_WORK}/delivery-002/STATE.md" \
    "### Q2"                         "G2-21 delivery-002 Q&A Q2 heading preserved"
file_has "${G1_WORK}/delivery-002/STATE.md" \
    "delivery-002-scoped question about gamma task rollout" \
    "G2-22 delivery-002 Q2 context preserved"

# Work STATE.md must now contain derived-view placeholders and no old sections.
file_has "${G1_WORK}/STATE.md" \
    "| _derived_ |"                  "G2-23 work STATE.md has derived placeholder row"
file_has "${G1_WORK}/STATE.md" \
    "_See delivery-NNN/STATE.md for each delivery gate block._" \
    "G2-24 work STATE.md Delivery Gates section replaced with derived ref"
file_lacks "${G1_WORK}/STATE.md" \
    "| task-001 | Alpha task in delivery-001 |" \
    "G2-25 work STATE.md old Tasks Status table rows removed"

# Lifecycle History block must be preserved in work STATE.md.
file_has "${G1_WORK}/STATE.md" \
    "| 2026-01-01 | Work created |"  "G2-26 work STATE.md Lifecycle History preserved"

# Work-level Q3 (no delivery mention) must remain in work STATE.md.
file_has "${G1_WORK}/STATE.md" \
    "### Q3"                         "G2-27 work STATE.md work-level Q3 preserved"
file_has "${G1_WORK}/STATE.md" \
    "Work-level question not clearly scoped to any delivery" \
    "G2-28 work STATE.md Q3 content preserved"

# Q1 and Q2 (delivery-scoped) must NOT appear in the work STATE.md.
file_lacks "${G1_WORK}/STATE.md" \
    "delivery-001-scoped question" \
    "G2-29 work STATE.md Q1 (delivery-scoped) not present"
file_lacks "${G1_WORK}/STATE.md" \
    "delivery-002-scoped question" \
    "G2-30 work STATE.md Q2 (delivery-scoped) not present"

# ===========================================================================
# Gate 3 -- Bash: correct delivery placement + default-delivery warning
# ===========================================================================
echo ""
echo "=== Gate 3: bash migrate -- delivery placement + default-delivery warning ==="

# task-001 and task-002 are in delivery-001 (Source line says delivery-001).
file_has "${G1_WORK}/delivery-001/tasks/task-001/STATE.md" \
    "**Delivery:** delivery-001" "G3-01 task-001 placed in delivery-001"
file_has "${G1_WORK}/delivery-001/tasks/task-002/STATE.md" \
    "**Delivery:** delivery-001" "G3-02 task-002 placed in delivery-001"

# task-003 is in delivery-002 (Source line says delivery-002).
file_has "${G1_WORK}/delivery-002/tasks/task-003/STATE.md" \
    "**Delivery:** delivery-002" "G3-03 task-003 placed in delivery-002"

# task-004 has no delivery token -- must land in delivery-001.
file_has "${G1_WORK}/delivery-001/tasks/task-004/STATE.md" \
    "**Delivery:** delivery-001" "G3-04 task-004 (no token) defaulted to delivery-001"
# task-004 must NOT appear in delivery-002.
if [[ -d "${G1_WORK}/delivery-002/tasks/task-004" ]]; then
    fail "G3-05 task-004 must NOT be in delivery-002 (no-token default is delivery-001)"
else
    pass "G3-05 task-004 correctly absent from delivery-002"
fi

# A warning must have been emitted for task-004.
assert_output_contains "${MIG_OUT}" \
    "task-004" "G3-06 migrate output mentions task-004"
assert_output_contains "${MIG_OUT}" \
    "no parseable delivery token" "G3-07 warning: no parseable delivery token emitted"

# SPEC.md content: delivery-001 SPEC lists task-004 (default) + task-001 + task-002.
file_has "${G1_WORK}/delivery-001/SPEC.md" \
    "| task-001 |"             "G3-08 delivery-001 SPEC.md lists task-001"
file_has "${G1_WORK}/delivery-001/SPEC.md" \
    "| task-004 |"             "G3-09 delivery-001 SPEC.md lists task-004 (default)"

# delivery-002 SPEC lists only task-003.
file_has "${G1_WORK}/delivery-002/SPEC.md" \
    "| task-003 |"             "G3-10 delivery-002 SPEC.md lists task-003"
file_lacks "${G1_WORK}/delivery-002/SPEC.md" \
    "| task-001 |"             "G3-11 delivery-002 SPEC.md does NOT list task-001"

# ===========================================================================
# Gate 4 -- Bash: idempotency (second run = no-op)
# ===========================================================================
echo ""
echo "=== Gate 4: bash migrate -- idempotency (second run) ==="

# Snapshot file tree before the second run.
_TREE_BEFORE="$(find "${G1_WORK}" -type f | sort)"
_STATE_SHA_BEFORE="$(sha256sum "${G1_WORK}/STATE.md" | cut -d' ' -f1)"
_T001_STATE_SHA_BEFORE="$(sha256sum "${G1_WORK}/delivery-001/tasks/task-001/STATE.md" | cut -d' ' -f1)"
_D001_STATE_SHA_BEFORE="$(sha256sum "${G1_WORK}/delivery-001/STATE.md" | cut -d' ' -f1)"

run_bash_migrate "${G1_WORK}"
assert_exit_eq "${MIG_RC}" 0 "G4-01 second migrate run exits 0"
assert_output_contains "${MIG_OUT}" "IDEMPOTENT" "G4-02 second run reports IDEMPOTENT no-op"

# File tree must be identical (no new files, no deletions).
_TREE_AFTER="$(find "${G1_WORK}" -type f | sort)"
assert_eq "${_TREE_BEFORE}" "${_TREE_AFTER}" \
    "G4-03 second run: file tree identical (no new files, no deletions)"

# Key files must be byte-for-byte unchanged.
_STATE_SHA_AFTER="$(sha256sum "${G1_WORK}/STATE.md" | cut -d' ' -f1)"
assert_eq "${_STATE_SHA_BEFORE}" "${_STATE_SHA_AFTER}" \
    "G4-04 second run: work STATE.md byte-identical"

_T001_STATE_SHA_AFTER="$(sha256sum "${G1_WORK}/delivery-001/tasks/task-001/STATE.md" | cut -d' ' -f1)"
assert_eq "${_T001_STATE_SHA_BEFORE}" "${_T001_STATE_SHA_AFTER}" \
    "G4-05 second run: task-001 STATE.md byte-identical"

_D001_STATE_SHA_AFTER="$(sha256sum "${G1_WORK}/delivery-001/STATE.md" | cut -d' ' -f1)"
assert_eq "${_D001_STATE_SHA_BEFORE}" "${_D001_STATE_SHA_AFTER}" \
    "G4-06 second run: delivery-001 STATE.md byte-identical"

# Third run: confirm determinism.
run_bash_migrate "${G1_WORK}"
assert_exit_eq "${MIG_RC}" 0 "G4-07 third migrate run exits 0"
_STATE_SHA_3="$(sha256sum "${G1_WORK}/STATE.md" | cut -d' ' -f1)"
assert_eq "${_STATE_SHA_AFTER}" "${_STATE_SHA_3}" \
    "G4-08 third run: work STATE.md still byte-identical"

# ===========================================================================
# Gate 5 -- Bash vs. golden fixture parity
# ===========================================================================
echo ""
echo "=== Gate 5: bash output vs. golden fixture parity ==="

if [[ -d "${GOLDEN_DIR}" ]]; then
    # Every file path present in the golden must exist in the bash sandbox.
    GOLDEN_PATHS="$(find "${GOLDEN_DIR}" -type f | sed "s|${GOLDEN_DIR}/||" | sort)"

    while IFS= read -r rel; do
        if [[ -f "${G1_WORK}/${rel}" ]]; then
            pass "G5-file-${rel}: present in bash sandbox"
        else
            fail "G5-file-${rel}: missing from bash sandbox (present in golden)"
        fi
    done <<< "${GOLDEN_PATHS}"

    # Spot-check content parity (key fields; not date-stamped).
    _SB_T001="${G1_WORK}/delivery-001/tasks/task-001/STATE.md"
    file_has "${_SB_T001}" "**State:** Done"    "G5-01 golden parity: task-001 State"
    file_has "${_SB_T001}" "**Review:** A+"     "G5-02 golden parity: task-001 Review"
    file_has "${_SB_T001}" "**Elapsed:** 2h"    "G5-03 golden parity: task-001 Elapsed"
    file_has "${_SB_T001}" "[HIGH] Example deferred finding from task-001" \
        "G5-04 golden parity: task-001 Findings"
    file_has "${_SB_T001}" "| 2026-01-02 | developer | 1h | 2h | Done |" \
        "G5-05 golden parity: task-001 dispatch row"

    _SB_D001="${G1_WORK}/delivery-001/STATE.md"
    file_has "${_SB_D001}" "**Grade:** A+"      "G5-06 golden parity: delivery-001 Grade"
    file_has "${_SB_D001}" "delivery-001 gate passed clean" \
        "G5-07 golden parity: delivery-001 gate Notes"
    file_has "${_SB_D001}" "### Q1"             "G5-08 golden parity: delivery-001 Q1"

    _SB_WORK="${G1_WORK}/STATE.md"
    file_has "${_SB_WORK}" "## Tasks State"     "G5-09 golden parity: work STATE.md Tasks State heading"
    file_has "${_SB_WORK}" "## Plan / Deliveries" "G5-10 golden parity: work STATE.md Plan heading"
    file_has "${_SB_WORK}" "### Q3"             "G5-11 golden parity: work STATE.md Q3 preserved"
    file_has "${_SB_WORK}" "## Lifecycle History" "G5-12 golden parity: work STATE.md Lifecycle History"
else
    pass "G5-00 golden fixture dir absent -- parity check skipped (not blocking)"
fi

# ===========================================================================
# Gate 6 -- PowerShell parity (skipped when pwsh absent)
# ===========================================================================
echo ""
echo "=== Gate 6: PowerShell parity ==="

if [[ -z "${PWSH}" ]]; then
    echo "SKIP: pwsh not found -- PowerShell parity gate skipped."
    pass "G6-00 PowerShell parity gate skipped (pwsh absent)"
else
    G6_WORK="$(make_sandbox g6)"

    run_ps_migrate "${G6_WORK}"
    assert_exit_eq "${PS_RC}" 0 "G6-01 migrate-work-hierarchy.ps1 exits 0"

    # Same hierarchy checks as Gate 1.
    assert_dir_exists  "${G6_WORK}/delivery-001"                          "G6-02 PS: delivery-001/ created"
    assert_file_exists "${G6_WORK}/delivery-001/SPEC.md"                  "G6-03 PS: delivery-001/SPEC.md"
    assert_file_exists "${G6_WORK}/delivery-001/STATE.md"                 "G6-04 PS: delivery-001/STATE.md"
    assert_file_exists "${G6_WORK}/delivery-001/tasks/task-001/SPEC.md"   "G6-05 PS: task-001/SPEC.md"
    assert_file_exists "${G6_WORK}/delivery-001/tasks/task-001/STATE.md"  "G6-06 PS: task-001/STATE.md"
    assert_file_exists "${G6_WORK}/delivery-001/tasks/task-002/SPEC.md"   "G6-07 PS: task-002/SPEC.md"
    assert_file_exists "${G6_WORK}/delivery-001/tasks/task-004/SPEC.md"   "G6-08 PS: task-004/SPEC.md (default delivery)"
    assert_dir_exists  "${G6_WORK}/delivery-002"                          "G6-09 PS: delivery-002/ created"
    assert_file_exists "${G6_WORK}/delivery-002/tasks/task-003/STATE.md"  "G6-10 PS: task-003/STATE.md"

    # Data preservation: task-001 key fields.
    file_has "${G6_WORK}/delivery-001/tasks/task-001/STATE.md" \
        "**State:** Done"     "G6-11 PS: task-001 State preserved"
    file_has "${G6_WORK}/delivery-001/tasks/task-001/STATE.md" \
        "**Review:** A+"      "G6-12 PS: task-001 Review preserved"
    file_has "${G6_WORK}/delivery-001/tasks/task-001/STATE.md" \
        "[HIGH] Example deferred finding from task-001" \
        "G6-13 PS: task-001 Findings preserved"
    file_has "${G6_WORK}/delivery-001/tasks/task-001/STATE.md" \
        "| 2026-01-02 | developer | 1h | 2h | Done |" \
        "G6-14 PS: task-001 dispatch row preserved"

    # task-004 default delivery.
    file_has "${G6_WORK}/delivery-001/tasks/task-004/STATE.md" \
        "**Delivery:** delivery-001" "G6-15 PS: task-004 defaulted to delivery-001"
    assert_output_contains "${PS_OUT}" \
        "no parseable delivery token" "G6-16 PS: task-004 no-token warning emitted"

    # Delivery-001 gate.
    file_has "${G6_WORK}/delivery-001/STATE.md" \
        "**Grade:** A+"       "G6-17 PS: delivery-001 Grade preserved"
    file_has "${G6_WORK}/delivery-001/STATE.md" \
        "### Q1"              "G6-18 PS: delivery-001 Q1 Q&A preserved"

    # Work STATE.md derived placeholders.
    file_has "${G6_WORK}/STATE.md" \
        "| _derived_ |"       "G6-19 PS: work STATE.md derived placeholder"
    file_has "${G6_WORK}/STATE.md" \
        "### Q3"              "G6-20 PS: work STATE.md Q3 (work-level) preserved"
    file_lacks "${G6_WORK}/STATE.md" \
        "delivery-001-scoped question" \
        "G6-21 PS: work STATE.md Q1 (delivery-scoped) absent"

    # PS idempotency.
    _PS_TREE_BEFORE="$(find "${G6_WORK}" -type f | sort)"
    run_ps_migrate "${G6_WORK}"
    assert_exit_eq "${PS_RC}" 0 "G6-22 PS: second run exits 0"
    assert_output_contains "${PS_OUT}" "IDEMPOTENT" "G6-23 PS: second run reports IDEMPOTENT"
    _PS_TREE_AFTER="$(find "${G6_WORK}" -type f | sort)"
    assert_eq "${_PS_TREE_BEFORE}" "${_PS_TREE_AFTER}" \
        "G6-24 PS: second run file tree unchanged"

    # Bash <-> PS structural equivalence on separate sandboxes.
    _BASH_PATHS="$(find "${G1_WORK}" -type f | sed "s|${G1_WORK}/||" | sort)"
    _PS_PATHS="$(find "${G6_WORK}" -type f | sed "s|${G6_WORK}/||" | sort)"
    assert_eq "${_BASH_PATHS}" "${_PS_PATHS}" \
        "G6-25 bash/PS parity: identical file trees produced"
fi

# ===========================================================================
# Isolation canary
# ===========================================================================
echo ""
echo "=== Isolation canary: real HOME untouched ==="

_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
if [[ "${_CANARY_AFTER}" == "${_CANARY_BEFORE}" ]]; then
    pass "ISO-01 real HOME (${REAL_HOME}) gained no .aid dirs (no scan escaped throwaway HOME)"
else
    _CANARY_NEW="$(comm -13 <(printf '%s\n' "${_CANARY_BEFORE}") <(printf '%s\n' "${_CANARY_AFTER}") 2>/dev/null || true)"
    fail "ISO-01 real HOME blast surface: NEW .aid dirs appeared: ${_CANARY_NEW}"
fi

# ===========================================================================
test_summary
