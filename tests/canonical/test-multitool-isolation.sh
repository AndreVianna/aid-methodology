#!/usr/bin/env bash
# test-multitool-isolation.sh -- task-020: structural acceptance suite for AC4 multi-tool
# isolation (feature-004-lockstep-ci-closeout).
#
# Installs claude-code + cursor + codex into a single throwaway repo (via
# aid add --from-bundle) and asserts the three structural invariants:
#
#   T01-T12  Each tool's tree exists with the uniform {agents,skills,aid} shape
#            under its own root (.claude/, .cursor/, .codex/).
#
#   T13-T20  Representative canonical files that carry no per-tool substitution
#            are byte-identical across the three installed trees (AC1 -- same
#            canonical skill/agent bodies).
#
#   T21-T26  No operational script in any tree references a foreign root basename
#            (grep each tool's aid/scripts/ subtree for the OTHER two tools'
#            root names), asserting tool isolation (AC4 structural half).
#            Scope is narrowed to aid/scripts/ to avoid false positives from
#            cross-tool documentation prose in reference and template files.
#
#   T27-T30  Escape canary and HOME-pin verification.
#
# HOME pin + escape canary (MANDATORY): HOME is forced to a throwaway dir for
# the entire run; a baseline snapshot of the real user HOME's .aid/ dirs is
# taken before any work begins, and an escape canary at the very end asserts
# no NEW .aid/ appeared outside the throwaway HOME.
#
# NOTE on SIGPIPE (set -o pipefail): grep -rl ... | grep -q . triggers SIGPIPE
# when grep -q exits after the first match.  All "found any?" checks use the
# pattern: found="$(grep ... | head -1)" ; [[ -n "$found" ]] to avoid SIGPIPE.
#
# ASCII-only: this file contains only 7-bit ASCII bytes.
#
# Auto-discovered by tests/run-all.sh via the tests/canonical/test-*.sh glob;
# no run-all.sh or workflow edit is needed.
#
# Usage:
#   HOME=$(mktemp -d) bash tests/canonical/test-multitool-isolation.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BIN_AID="${REPO_ROOT}/bin/aid"
LIB_CORE="${REPO_ROOT}/lib/aid-install-core.sh"
PROFILES_DIR="${REPO_ROOT}/profiles"
VERSION="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"

[[ -f "$BIN_AID" ]]  || { echo "ERROR: bin/aid not found at $BIN_AID" >&2; exit 1; }
[[ -f "$LIB_CORE" ]] || { echo "ERROR: lib/aid-install-core.sh not found at $LIB_CORE" >&2; exit 1; }

# ---------------------------------------------------------------------------
# HOME pin (MANDATORY): redirect all home-relative writes to a throwaway dir.
# REAL_HOME is saved and the escape canary uses it at the very end.
# Also redirect USERPROFILE (Windows portability defence).
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="${TMP}/fakehome"
export USERPROFILE="${TMP}/fakehome"
mkdir -p "${HOME}"

# ---------------------------------------------------------------------------
# Portable sha256 helper (mirrors test-aid-migrate.sh).
# ---------------------------------------------------------------------------
file_sha256() {
    local f="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$f" | cut -d' ' -f1
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$f" | awk '{print $NF}'
    else
        md5sum "$f" | cut -d' ' -f1
    fi
}

# ---------------------------------------------------------------------------
# tree_has_ref <tree_dir> <pattern>
#
# Returns 0 (success/true) if ANY file under tree_dir contains <pattern>
# as a fixed string; 1 (failure/false) if none do.
#
# Avoids the grep -rl ... | grep -q . SIGPIPE hazard (set -o pipefail +
# grep -q exits early after first match, closing the pipe, causing SIGPIPE
# on the upstream grep).  Safe idiom: capture to variable + test non-empty.
# ---------------------------------------------------------------------------
tree_has_ref() {
    local tree_dir="$1"
    local pattern="$2"
    local found
    found="$(grep -rlF "${pattern}" "${tree_dir}" 2>/dev/null | head -1)"
    [[ -n "$found" ]]
}

# ---------------------------------------------------------------------------
# scripts_have_foreign_root <scripts_dir> <foreign_root>
#
# Returns 0 (success/true) if any file under <scripts_dir> contains the
# foreign root basename (e.g. ".cursor/") as a literal string.  Used for
# the AC4 structural isolation check scoped to aid/scripts/ (operational
# files only -- avoids false positives from cross-tool documentation prose
# in reference files and agent bodies that discuss the multi-tool system).
# ---------------------------------------------------------------------------
scripts_have_foreign_root() {
    local scripts_dir="$1"
    local foreign_root="$2"
    local found
    found="$(grep -rlF "${foreign_root}/" "${scripts_dir}" 2>/dev/null | head -1)"
    [[ -n "$found" ]]
}

# ---------------------------------------------------------------------------
# Build a minimal AID code home: bin/aid + lib/ + VERSION + dashboard/home.html.
# bin/aid self-locates AID_CODE_HOME as the parent of its own bin/ directory.
# ---------------------------------------------------------------------------
CODE_HOME="$(mktemp -d "${TMP}/code.XXXXXX")"
mkdir -p "${CODE_HOME}/bin" "${CODE_HOME}/lib" "${CODE_HOME}/dashboard"
cp "${BIN_AID}"  "${CODE_HOME}/bin/aid"
chmod +x         "${CODE_HOME}/bin/aid"
cp "${LIB_CORE}" "${CODE_HOME}/lib/aid-install-core.sh"
printf '%s\n' "${VERSION}" > "${CODE_HOME}/VERSION"
printf '<html><body>AID Dashboard</body></html>\n' > "${CODE_HOME}/dashboard/home.html"

# ---------------------------------------------------------------------------
# Build fixture tarballs from profiles/ (mirrors test-aid-cli.sh pattern).
# Excludes README.md and emission-manifest.jsonl (non-installed meta files).
# ---------------------------------------------------------------------------
BUNDLE_DIR="$(mktemp -d "${TMP}/bundle.XXXXXX")"

build_fixture_tarball() {
    local tool="$1"
    local profile_dir="${PROFILES_DIR}/${tool}"
    local tarball="${BUNDLE_DIR}/aid-${tool}-v${VERSION}.tar.gz"

    [[ -d "$profile_dir" ]] || {
        echo "ERROR: profile dir not found: $profile_dir" >&2
        return 1
    }

    local filelist
    filelist="$(mktemp "${TMP}/filelist-${tool}.XXXXXX")"
    while IFS= read -r f; do
        local fname
        fname="$(basename "$f")"
        [[ "$fname" == "README.md" ]] && continue
        [[ "$fname" == "emission-manifest.jsonl" ]] && continue
        local rel="${f#${profile_dir}/}"
        printf './%s\n' "$rel"
    done < <(find "${profile_dir}" -type f | sort) > "$filelist"

    (cd "${profile_dir}" && tar -czf "${tarball}" --no-recursion -T "${filelist}") || {
        echo "ERROR: failed to build fixture tarball for ${tool}" >&2
        rm -f "$filelist"
        return 1
    }
    rm -f "$filelist"
}

echo ""
echo "=== Setup: build fixture tarballs and run aid add claude-code,cursor,codex ==="

for _tool in claude-code cursor codex; do
    build_fixture_tarball "$_tool" || {
        echo "ERROR: fixture tarball build failed for ${_tool}" >&2
        exit 1
    }
done

# ---------------------------------------------------------------------------
# Throwaway repo: run aid add claude-code,cursor,codex --from-bundle.
# AID_HOME redirected to a throwaway state dir so registry.yml never touches
# the real user state.  AID_NO_UPDATE_CHECK=1 prevents network calls.
# ---------------------------------------------------------------------------
TARGET="$(mktemp -d "${TMP}/repo.XXXXXX")"
STATE_HOME="$(mktemp -d "${TMP}/state.XXXXXX")"

ADD_OUT="$(AID_HOME="${STATE_HOME}" \
           AID_NO_UPDATE_CHECK=1 \
           bash "${CODE_HOME}/bin/aid" add claude-code,cursor,codex \
               --from-bundle "${BUNDLE_DIR}" \
               --target "${TARGET}" 2>&1)" || {
    echo "ERROR: aid add failed:" >&2
    echo "$ADD_OUT" >&2
    exit 1
}
log "aid add output: ${ADD_OUT}"

echo "Setup complete. Asserting invariants..."

# ===========================================================================
# T01-T12: Each tool's tree exists with the uniform {agents,skills,aid} shape
#          under its own root.
# ===========================================================================
echo ""
echo "=== T01-T12: per-tool tree shape ==="

assert_dir_exists "${TARGET}/.claude"                "T01 .claude/ root exists"
assert_dir_exists "${TARGET}/.claude/agents"         "T02 .claude/agents/ exists"
assert_dir_exists "${TARGET}/.claude/skills"         "T03 .claude/skills/ exists"
assert_dir_exists "${TARGET}/.claude/aid"            "T04 .claude/aid/ exists"

assert_dir_exists "${TARGET}/.cursor"                "T05 .cursor/ root exists"
assert_dir_exists "${TARGET}/.cursor/agents"         "T06 .cursor/agents/ exists"
assert_dir_exists "${TARGET}/.cursor/skills"         "T07 .cursor/skills/ exists"
assert_dir_exists "${TARGET}/.cursor/aid"            "T08 .cursor/aid/ exists"

assert_dir_exists "${TARGET}/.codex"                 "T09 .codex/ root exists"
assert_dir_exists "${TARGET}/.codex/agents"          "T10 .codex/agents/ exists"
assert_dir_exists "${TARGET}/.codex/skills"          "T11 .codex/skills/ exists"
assert_dir_exists "${TARGET}/.codex/aid"             "T12 .codex/aid/ exists"

# ===========================================================================
# T13-T20: Byte-identity of representative canonical files across all three
#          installed trees (AC1).
#
# These files carry no per-tool root-path substitution (pure canonical bodies:
# individual template/script files that reference no tool-specific paths).  They
# should be bit-for-bit identical across .claude/, .cursor/, .codex/.
# ===========================================================================
echo ""
echo "=== T13-T20: byte-identity of canonical bodies across trees (AC1) ==="

# Representative files known to be canonical-body-identical (no root refs).
# Sourced from aid/templates/ (pure canonical Markdown that names no
# install-path -- unlike e.g. grading-rubric.md/reviewer-ledger-schema.md/
# state-machine-chaining.md/task-detail-template.md, which legitimately cite
# `canonical/scripts/...` and `canonical/templates/...` paths in their own
# prose and are therefore REWRITTEN per tool by the renderer, NOT
# byte-identical -- confirmed by direct sha256 diff across profiles/*/) and
# aid/scripts/ whose bodies are purely computational with no tool-root
# references.
CANONICAL_BODIES=(
    "aid/templates/delivery-blueprint-template.md"
    "aid/templates/delivery-plans/task-template.md"
    "aid/templates/requirements.md"
    "aid/templates/known-issues.md"
    "aid/scripts/execute/complexity-score.sh"
    "aid/scripts/execute/compute-block-radius.sh"
    "aid/scripts/config/read-setting.sh"
    "aid/scripts/grade.sh"
)

T_IDX=13
for rel in "${CANONICAL_BODIES[@]}"; do
    CC_FILE="${TARGET}/.claude/${rel}"
    CU_FILE="${TARGET}/.cursor/${rel}"
    CO_FILE="${TARGET}/.codex/${rel}"

    if [[ ! -f "$CC_FILE" ]]; then
        fail "T${T_IDX} .claude/${rel} -- file not installed in .claude/ tree"
        T_IDX=$((T_IDX + 1))
        continue
    fi
    if [[ ! -f "$CU_FILE" ]]; then
        fail "T${T_IDX} .cursor/${rel} -- file not installed in .cursor/ tree"
        T_IDX=$((T_IDX + 1))
        continue
    fi
    if [[ ! -f "$CO_FILE" ]]; then
        fail "T${T_IDX} .codex/${rel} -- file not installed in .codex/ tree"
        T_IDX=$((T_IDX + 1))
        continue
    fi

    sha_cc="$(file_sha256 "$CC_FILE")"
    sha_cu="$(file_sha256 "$CU_FILE")"
    sha_co="$(file_sha256 "$CO_FILE")"

    if [[ "$sha_cc" == "$sha_cu" && "$sha_cu" == "$sha_co" ]]; then
        pass "T${T_IDX} ${rel} -- byte-identical across .claude/.cursor/.codex (AC1)"
    else
        fail "T${T_IDX} ${rel} -- byte-identity MISMATCH: .claude=${sha_cc} .cursor=${sha_cu} .codex=${sha_co}"
    fi
    T_IDX=$((T_IDX + 1))
done

# ===========================================================================
# T21-T26: No operational script references a foreign root basename (AC4).
#
# Scope: aid/scripts/ subdirectory in each tree.  Operational scripts MUST
# only reference their own tool root.  Reference files and agent bodies that
# contain cross-tool documentation prose (e.g. explaining how the renderer
# works across all three tools) are excluded to avoid false positives.
#
# The three tool roots and their basenames:
#   claude-code -> .claude
#   cursor      -> .cursor
#   codex       -> .codex
#
# A "foreign root reference" in aid/scripts/ means the wrong tree's path
# would be invoked at runtime.  This catches generator bugs where a script
# ends up with another tool's root-path prefix.
# ===========================================================================
echo ""
echo "=== T21-T26: no foreign-root refs in operational scripts (AC4 structural) ==="

# Helper: format the list of offending files for the fail message.
list_files_with_ref() {
    local dir="$1" pattern="$2"
    grep -rlF "${pattern}/" "${dir}" 2>/dev/null | head -5 | sed 's/^/    /'
}

# --- .claude/aid/scripts/ must not reference .cursor/ or .codex/ ----------
CC_SCRIPTS="${TARGET}/.claude/aid/scripts"
if [[ -d "$CC_SCRIPTS" ]]; then
    if scripts_have_foreign_root "$CC_SCRIPTS" ".cursor"; then
        OFFENDERS="$(list_files_with_ref "$CC_SCRIPTS" ".cursor")"
        fail "T21 .claude/aid/scripts/ contains .cursor/ reference (foreign root contamination):
${OFFENDERS}"
    else
        pass "T21 .claude/aid/scripts/ has no .cursor/ references"
    fi

    if scripts_have_foreign_root "$CC_SCRIPTS" ".codex"; then
        OFFENDERS="$(list_files_with_ref "$CC_SCRIPTS" ".codex")"
        fail "T22 .claude/aid/scripts/ contains .codex/ reference (foreign root contamination):
${OFFENDERS}"
    else
        pass "T22 .claude/aid/scripts/ has no .codex/ references"
    fi
else
    fail "T21 .claude/aid/scripts/ does not exist -- cannot check foreign refs"
    fail "T22 .claude/aid/scripts/ does not exist -- cannot check foreign refs"
fi

# --- .cursor/aid/scripts/ must not reference .claude/ or .codex/ ----------
CU_SCRIPTS="${TARGET}/.cursor/aid/scripts"
if [[ -d "$CU_SCRIPTS" ]]; then
    if scripts_have_foreign_root "$CU_SCRIPTS" ".claude"; then
        OFFENDERS="$(list_files_with_ref "$CU_SCRIPTS" ".claude")"
        fail "T23 .cursor/aid/scripts/ contains .claude/ reference (foreign root contamination):
${OFFENDERS}"
    else
        pass "T23 .cursor/aid/scripts/ has no .claude/ references"
    fi

    if scripts_have_foreign_root "$CU_SCRIPTS" ".codex"; then
        OFFENDERS="$(list_files_with_ref "$CU_SCRIPTS" ".codex")"
        fail "T24 .cursor/aid/scripts/ contains .codex/ reference (foreign root contamination):
${OFFENDERS}"
    else
        pass "T24 .cursor/aid/scripts/ has no .codex/ references"
    fi
else
    fail "T23 .cursor/aid/scripts/ does not exist -- cannot check foreign refs"
    fail "T24 .cursor/aid/scripts/ does not exist -- cannot check foreign refs"
fi

# --- .codex/aid/scripts/ must not reference .claude/ or .cursor/ ----------
CO_SCRIPTS="${TARGET}/.codex/aid/scripts"
if [[ -d "$CO_SCRIPTS" ]]; then
    if scripts_have_foreign_root "$CO_SCRIPTS" ".claude"; then
        OFFENDERS="$(list_files_with_ref "$CO_SCRIPTS" ".claude")"
        fail "T25 .codex/aid/scripts/ contains .claude/ reference (foreign root contamination):
${OFFENDERS}"
    else
        pass "T25 .codex/aid/scripts/ has no .claude/ references"
    fi

    if scripts_have_foreign_root "$CO_SCRIPTS" ".cursor"; then
        OFFENDERS="$(list_files_with_ref "$CO_SCRIPTS" ".cursor")"
        fail "T26 .codex/aid/scripts/ contains .cursor/ reference (foreign root contamination):
${OFFENDERS}"
    else
        pass "T26 .codex/aid/scripts/ has no .cursor/ references"
    fi
else
    fail "T25 .codex/aid/scripts/ does not exist -- cannot check foreign refs"
    fail "T26 .codex/aid/scripts/ does not exist -- cannot check foreign refs"
fi

# ===========================================================================
# T27-T30: Escape canary and HOME-pin verification.
#
# Assert the real user HOME was never touched by this suite.  A snapshot of
# all .aid/ dirs under the REAL HOME is taken at startup; any NEW .aid/ that
# appeared outside ${TMP} after the suite runs indicates a migration-scan
# escape (the migration scan defaults to $HOME; pinning HOME defensively
# catches this class of bug).
# ===========================================================================
echo ""
echo "=== T27-T30: escape canary -- real HOME untouched ==="

_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
if [[ "$_CANARY_BEFORE" == "$_CANARY_AFTER" ]]; then
    pass "T27 escape canary: no new .aid/ dirs appeared in real HOME (${REAL_HOME})"
else
    _NEW_AID="$(comm -13 <(echo "$_CANARY_BEFORE") <(echo "$_CANARY_AFTER"))"
    fail "T27 escape canary: new .aid/ dirs escaped to real HOME -- isolation breach: ${_NEW_AID}"
fi

# Registry was written to STATE_HOME, not to the real AID_HOME.
_REAL_REGISTRY="${REAL_HOME}/.aid/registry.yml"
if [[ -f "$_REAL_REGISTRY" ]] && tree_has_ref "$_REAL_REGISTRY" "${TARGET}"; then
    fail "T28 throwaway repo leaked into real HOME registry (isolation breach)"
else
    pass "T28 throwaway repo absent from real HOME registry"
fi

# The fakehome dir must NOT be the same as the real HOME.
if [[ "${HOME}" == "${REAL_HOME}" ]]; then
    fail "T29 HOME pin broken: HOME still points to real HOME after export"
else
    pass "T29 HOME pin: fakehome (${HOME}) is distinct from real HOME (${REAL_HOME})"
fi

# AID_NO_UPDATE_CHECK=1 was set, so the update-check cache must NOT appear in
# the fakehome (it would only appear if AID ignored the env var or if HOME
# was pointing somewhere wrong).
_FAKE_UPDATE_CHECK="${HOME}/.aid/.update-check"
if [[ -f "$_FAKE_UPDATE_CHECK" ]]; then
    fail "T30 unexpected .update-check in fakehome -- AID_NO_UPDATE_CHECK=1 was ignored or HOME pin broken"
else
    pass "T30 no .update-check in fakehome (AID_NO_UPDATE_CHECK=1 honoured)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
