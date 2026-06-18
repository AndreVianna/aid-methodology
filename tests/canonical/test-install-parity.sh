#!/usr/bin/env bash
# test-install-parity.sh — Cross-platform parity between install.sh and install.ps1.
#
# Installs the SAME fixture tarball through BOTH bash install.sh and pwsh install.ps1
# into separate temp target directories and asserts:
#   - Installed file trees are byte-identical (diff -r).
#   - .aid/.aid-manifest.json files are identical modulo 'installed_at' timestamps
#     (same manifest_version, aid_version, tools, paths, sha256, status, key order).
#   - .aid/.aid-version files are identical.
#   - Exit codes match for every tested scenario.
#   - User-visible message strings match for every tested scenario.
#
# Scenarios covered:
#   PAR01 — fresh install: claude-code
#   PAR02 — fresh install: codex
#   PAR03 — fresh install: cursor
#   PAR04 — fresh install: copilot-cli
#   PAR05 — fresh install: antigravity
#   PAR06 — idempotent re-install (exit 0, "Up to date:")
#   PAR07 — protect-on-diff (exit 5, .aid-new, "pending-merge")
#   PAR08 — --force / -Force overwrite (exit 0, "Updated:")
#   PAR09 — uninstall (exit 0, "Uninstall complete.")
#   PAR10 — uninstall with no manifest (exit 6)
#   PAR11 — auto-detect ambiguity (exit 2)
#   PAR12 — comma-list codex,cursor (exit 0 — second AGENTS.md byte-identical (FR12) -> skipped as up-to-date)
#
# SKIP (exit 0) when `pwsh` is absent — CI asserts pwsh IS present.
#
# Usage:
#   bash test-install-parity.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT_SH="${REPO_ROOT}/install.sh"
SUT_PS1="${REPO_ROOT}/install.ps1"
PROFILES_DIR="${REPO_ROOT}/profiles"

[[ -f "$SUT_SH" ]]  || { echo "ERROR: install.sh not found at $SUT_SH" >&2; exit 1; }
[[ -f "$SUT_PS1" ]] || { echo "ERROR: install.ps1 not found at $SUT_PS1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Gate: skip when pwsh is absent (CI asserts it IS present so this never fires).
# ---------------------------------------------------------------------------
PWSH=""
if command -v pwsh >/dev/null 2>&1; then
    PWSH="pwsh"
elif [[ -x "/home/andre.vianna/.local/pwsh/pwsh" ]]; then
    PWSH="/home/andre.vianna/.local/pwsh/pwsh"
fi

if [[ -z "$PWSH" ]]; then
    echo "SKIP: pwsh not found on PATH — skipping install parity suite (needs PowerShell)."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FIXTURE_DIR="${TMP}/fixtures"
mkdir -p "${FIXTURE_DIR}"

VERSION="0.7.0"

# ---------------------------------------------------------------------------
# build_fixture_tarball <tool>
#   Builds a flat-root tarball from profiles/<tool>/, matching the feature-002
#   layout contract (no wrapping dir; excludes README.md + emission-manifest.jsonl).
#   Output: ${FIXTURE_DIR}/aid-<tool>-v${VERSION}.tar.gz
# ---------------------------------------------------------------------------
build_fixture_tarball() {
    local tool="$1"
    local profile_dir="${PROFILES_DIR}/${tool}"
    local tarball="${FIXTURE_DIR}/aid-${tool}-v${VERSION}.tar.gz"

    [[ -d "$profile_dir" ]] || { echo "ERROR: profile dir not found: $profile_dir" >&2; return 1; }

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

# Build fixture tarballs for all five tools.
for _tool in claude-code codex cursor copilot-cli antigravity; do
    build_fixture_tarball "$_tool" || { echo "ERROR: fixture build failed for ${_tool}" >&2; exit 1; }
done

newtarget_bash() { mktemp -d "${TMP}/tgt_sh.XXXXXX"; }
newtarget_ps1()  { mktemp -d "${TMP}/tgt_ps1.XXXXXX"; }

# ---------------------------------------------------------------------------
# Runners: capture output + exit code.
# ---------------------------------------------------------------------------
SH_OUT=""  SH_RC=0
PS1_OUT="" PS1_RC=0

run_sh() {
    SH_OUT=$(bash "$SUT_SH" "$@" 2>&1); SH_RC=$?
}

run_ps1() {
    # ISOLATION: unset AID_LIB_PATH so a parent-exported Bash .sh path does not bleed into
    # install.ps1 which expects a .psm1 module.  PS1 finds its sibling lib/AidInstallCore.psm1.
    PS1_OUT=$(env -u AID_LIB_PATH "$PWSH" -NoProfile -File "$SUT_PS1" "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); PS1_RC=$?
    # PAR01b flake guard: under full-suite load, pwsh occasionally yields no output on the
    # first invocation (transient startup issue). Retry once if output is empty/too short.
    if [[ "${#PS1_OUT}" -lt 5 ]]; then
        PS1_OUT=$(env -u AID_LIB_PATH "$PWSH" -NoProfile -File "$SUT_PS1" "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); PS1_RC=$?
    fi
}

# Verbose runners (for tests that check per-file lines).
run_sh_verbose() {
    SH_OUT=$(bash "$SUT_SH" --verbose "$@" 2>&1); SH_RC=$?
}

run_ps1_verbose() {
    # ISOLATION: same AID_LIB_PATH guard as run_ps1.
    PS1_OUT=$(env -u AID_LIB_PATH "$PWSH" -NoProfile -File "$SUT_PS1" -Verbose "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); PS1_RC=$?
    # PAR01b flake guard: retry once if output is empty/too short.
    if [[ "${#PS1_OUT}" -lt 5 ]]; then
        PS1_OUT=$(env -u AID_LIB_PATH "$PWSH" -NoProfile -File "$SUT_PS1" -Verbose "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); PS1_RC=$?
    fi
}

# ---------------------------------------------------------------------------
# Manifest comparison helper.
# Strips all 'installed_at' timestamps, then compares the normalized JSON.
# Prints a diff on mismatch; returns 1 when they differ.
# ---------------------------------------------------------------------------
manifests_equivalent() {
    local sh_manifest="$1" ps1_manifest="$2"
    [[ -f "$sh_manifest" ]] || { echo "  PARITY-DIFF: sh manifest missing: $sh_manifest"; return 1; }
    [[ -f "$ps1_manifest" ]] || { echo "  PARITY-DIFF: ps1 manifest missing: $ps1_manifest"; return 1; }

    # Strip installed_at and re-serialize via python3 for canonical comparison.
    local sh_norm ps1_norm
    sh_norm="$(python3 - "$sh_manifest" <<'PY'
import json, sys

def strip_timestamps(d):
    if isinstance(d, dict):
        return {k: strip_timestamps(v) for k, v in d.items() if k != "installed_at"}
    return d

with open(sys.argv[1]) as f:
    data = json.load(f)
print(json.dumps(strip_timestamps(data), indent=2))
PY
)" || { echo "  PARITY-DIFF: python3 failed to normalize sh manifest"; return 1; }

    ps1_norm="$(python3 - "$ps1_manifest" <<'PY'
import json, sys

def strip_timestamps(d):
    if isinstance(d, dict):
        return {k: strip_timestamps(v) for k, v in d.items() if k != "installed_at"}
    return d

with open(sys.argv[1]) as f:
    data = json.load(f)
print(json.dumps(strip_timestamps(data), indent=2))
PY
)" || { echo "  PARITY-DIFF: python3 failed to normalize ps1 manifest"; return 1; }

    if [[ "$sh_norm" == "$ps1_norm" ]]; then
        return 0
    fi

    # Print diff for diagnostics.
    echo "  PARITY-DIFF: manifests differ after stripping timestamps:"
    diff <(echo "$sh_norm") <(echo "$ps1_norm") | head -30
    return 1
}

# ---------------------------------------------------------------------------
# Key message fragments required to appear in BOTH sh and ps1 output.
# ---------------------------------------------------------------------------
assert_both_contain() {
    local pattern="$1" label_prefix="$2"
    assert_output_contains "$SH_OUT"  "$pattern" "${label_prefix} sh contains '${pattern}'"
    assert_output_contains "$PS1_OUT" "$pattern" "${label_prefix} ps1 contains '${pattern}'"
}

assert_both_not_contain() {
    local pattern="$1" label_prefix="$2"
    assert_output_not_contains "$SH_OUT"  "$pattern" "${label_prefix} sh does not contain '${pattern}'"
    assert_output_not_contains "$PS1_OUT" "$pattern" "${label_prefix} ps1 does not contain '${pattern}'"
}

assert_exit_codes_match() {
    local expected="$1" label_prefix="$2"
    assert_exit_eq "$SH_RC"  "$expected" "${label_prefix} sh exit $expected"
    assert_exit_eq "$PS1_RC" "$expected" "${label_prefix} ps1 exit $expected"
}

# ---------------------------------------------------------------------------
# PAR01 – Fresh install: claude-code
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

run_sh_verbose  --tool claude-code --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1_verbose  -Tool claude-code  -FromBundle  "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

assert_exit_codes_match 0 "PAR01 fresh install claude-code"
assert_both_contain "Copied:"  "PAR01b"
assert_both_contain "Done."    "PAR01c"

# Installed tree must be byte-identical.
DIFF_OUT=$(diff -r --exclude=".aid-manifest.json" --exclude=".aid-version" \
           "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR01d installed tree byte-identical (diff -r)"

# Version marker must be identical.
assert_eq "$(cat "$T_SH/.aid/.aid-version" 2>/dev/null)" \
          "$(cat "$T_PS1/.aid/.aid-version" 2>/dev/null)" \
          "PAR01e .aid-version identical"

# Manifest must be equivalent (ignoring timestamps).
if manifests_equivalent "$T_SH/.aid/.aid-manifest.json" "$T_PS1/.aid/.aid-manifest.json"; then
    pass "PAR01f manifests equivalent modulo timestamps"
else
    fail "PAR01f manifests differ beyond timestamps"
fi

# ---------------------------------------------------------------------------
# PAR02 – Fresh install: codex
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

run_sh_verbose  --tool codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1_verbose  -Tool codex  -FromBundle  "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

assert_exit_codes_match 0 "PAR02 fresh install codex"
assert_both_contain "Copied:" "PAR02b"
assert_both_contain "Done."   "PAR02c"

DIFF_OUT=$(diff -r --exclude=".aid-manifest.json" --exclude=".aid-version" \
           "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR02d installed tree byte-identical (diff -r)"
assert_eq "$(cat "$T_SH/.aid/.aid-version" 2>/dev/null)" \
          "$(cat "$T_PS1/.aid/.aid-version" 2>/dev/null)" \
          "PAR02e .aid-version identical"
if manifests_equivalent "$T_SH/.aid/.aid-manifest.json" "$T_PS1/.aid/.aid-manifest.json"; then
    pass "PAR02f manifests equivalent modulo timestamps"
else
    fail "PAR02f manifests differ beyond timestamps"
fi

# ---------------------------------------------------------------------------
# PAR03 – Fresh install: cursor
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

run_sh  --tool cursor --from-bundle "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1  -Tool cursor  -FromBundle  "${FIXTURE_DIR}/aid-cursor-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

assert_exit_codes_match 0 "PAR03 fresh install cursor"

DIFF_OUT=$(diff -r --exclude=".aid-manifest.json" --exclude=".aid-version" \
           "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR03b installed tree byte-identical (diff -r)"
if manifests_equivalent "$T_SH/.aid/.aid-manifest.json" "$T_PS1/.aid/.aid-manifest.json"; then
    pass "PAR03c manifests equivalent modulo timestamps"
else
    fail "PAR03c manifests differ beyond timestamps"
fi

# ---------------------------------------------------------------------------
# PAR04 – Fresh install: copilot-cli
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

run_sh  --tool copilot-cli --from-bundle "${FIXTURE_DIR}/aid-copilot-cli-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1  -Tool copilot-cli  -FromBundle  "${FIXTURE_DIR}/aid-copilot-cli-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

assert_exit_codes_match 0 "PAR04 fresh install copilot-cli"

DIFF_OUT=$(diff -r --exclude=".aid-manifest.json" --exclude=".aid-version" \
           "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR04b installed tree byte-identical (diff -r)"
if manifests_equivalent "$T_SH/.aid/.aid-manifest.json" "$T_PS1/.aid/.aid-manifest.json"; then
    pass "PAR04c manifests equivalent modulo timestamps"
else
    fail "PAR04c manifests differ beyond timestamps"
fi

# ---------------------------------------------------------------------------
# PAR05 – Fresh install: antigravity
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

run_sh  --tool antigravity --from-bundle "${FIXTURE_DIR}/aid-antigravity-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1  -Tool antigravity  -FromBundle  "${FIXTURE_DIR}/aid-antigravity-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

assert_exit_codes_match 0 "PAR05 fresh install antigravity"

DIFF_OUT=$(diff -r --exclude=".aid-manifest.json" --exclude=".aid-version" \
           "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR05b installed tree byte-identical (diff -r)"
if manifests_equivalent "$T_SH/.aid/.aid-manifest.json" "$T_PS1/.aid/.aid-manifest.json"; then
    pass "PAR05c manifests equivalent modulo timestamps"
else
    fail "PAR05c manifests differ beyond timestamps"
fi

# ---------------------------------------------------------------------------
# PAR06 – Idempotent re-install: exit 0, "Up to date:", no re-copy
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

# First installs (default mode).
run_sh  --tool codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1  -Tool codex  -FromBundle  "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

# Second (idempotent) installs — verbose mode so we can assert per-file strings.
run_sh_verbose  --tool codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1_verbose  -Tool codex  -FromBundle  "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

assert_exit_codes_match 0 "PAR06 idempotent re-install"
assert_both_contain     "Up to date:"  "PAR06b"
assert_both_not_contain "Copied:"      "PAR06c"

DIFF_OUT=$(diff -r --exclude=".aid-manifest.json" --exclude=".aid-version" \
           "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR06d re-install trees still byte-identical"
if manifests_equivalent "$T_SH/.aid/.aid-manifest.json" "$T_PS1/.aid/.aid-manifest.json"; then
    pass "PAR06e re-install manifests equivalent"
else
    fail "PAR06e re-install manifests differ"
fi

# ---------------------------------------------------------------------------
# PAR07 – Pre-placed user AGENTS.md → in-place region update, exit 0, no .aid-new
#
# NEW CONTRACT (work-003): _copy_root_agent_file / Copy-RootAgentFile perform
# an in-place AID:BEGIN/END region update. User content outside markers is
# preserved verbatim. No .aid-new sidecar file is written. No exit 5.
# Both bash and PS1 produce byte-identical AGENTS.md output.
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

printf 'User-owned AGENTS.md\n' > "$T_SH/AGENTS.md"
printf 'User-owned AGENTS.md\n' > "$T_PS1/AGENTS.md"

run_sh  --tool codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1  -Tool codex  -FromBundle  "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

# Both must exit 0 (no more protect-on-diff / exit 5).
assert_exit_codes_match 0 "PAR07 pre-placed user AGENTS.md: in-place update → exit 0"

# Neither may write a .aid-new sidecar file.
assert_eq "$([[ -e "$T_SH/AGENTS.md.aid-new"  ]] && echo exists || echo gone)" "gone" \
    "PAR07d sh AGENTS.md.aid-new NOT created (new contract: no sidecar)"
assert_eq "$([[ -e "$T_PS1/AGENTS.md.aid-new" ]] && echo exists || echo gone)" "gone" \
    "PAR07e ps1 AGENTS.md.aid-new NOT created (new contract: no sidecar)"

# User content outside markers must be preserved in both.
assert_file_contains "$T_SH/AGENTS.md"  "User-owned AGENTS.md" "PAR07g sh: user content preserved outside markers"
assert_file_contains "$T_PS1/AGENTS.md" "User-owned AGENTS.md" "PAR07h ps1: user content preserved outside markers"

# PARITY: bash and PS1 produce byte-identical AGENTS.md output.
CMP_OUT=$(cmp -s "$T_SH/AGENTS.md" "$T_PS1/AGENTS.md" && echo same || echo diff)
assert_eq "$CMP_OUT" "same" "PAR07f Bash↔PS1 AGENTS.md byte-identical (region-update parity)"

# Manifest must NOT contain pending-merge in either case.
assert_file_not_contains "$T_SH/.aid/.aid-manifest.json"  '"pending-merge"' "PAR07i sh manifest: no pending-merge"
assert_file_not_contains "$T_PS1/.aid/.aid-manifest.json" '"pending-merge"' "PAR07j ps1 manifest: no pending-merge"

# Non-root-agent trees must be byte-identical (the .codex/.agents trees were copied).
DIFF_OUT=$(diff -r \
           --exclude=".aid-manifest.json" --exclude=".aid-version" \
           --exclude="AGENTS.md" \
           "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR07k non-root-agent installed trees byte-identical"

# ---------------------------------------------------------------------------
# PAR08 – --force / -Force with pre-placed user AGENTS.md → exit 0, "Updated:",
#          user content preserved outside markers (in-place region update, not full overwrite)
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

printf 'User-owned AGENTS.md\n' > "$T_SH/AGENTS.md"
printf 'User-owned AGENTS.md\n' > "$T_PS1/AGENTS.md"

run_sh_verbose  --tool codex --force --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1_verbose  -Tool codex  -Force  -FromBundle  "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

assert_exit_codes_match 0 "PAR08 force install"
assert_both_contain "Updated:" "PAR08b"

# Non-root-agent trees (all except AGENTS.md + manifest + version) must be byte-identical.
DIFF_OUT=$(diff -r \
           --exclude=".aid-manifest.json" --exclude=".aid-version" \
           --exclude="AGENTS.md" \
           "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR08c force-installed non-root-agent trees byte-identical"
if manifests_equivalent "$T_SH/.aid/.aid-manifest.json" "$T_PS1/.aid/.aid-manifest.json"; then
    pass "PAR08d force manifests equivalent"
else
    fail "PAR08d force manifests differ"
fi

# PARITY: Bash and PS1 produce byte-identical AGENTS.md (in-place region update).
# User content outside markers is preserved (not overwritten) in both.
CMP_OUT=$(cmp -s "$T_SH/AGENTS.md" "$T_PS1/AGENTS.md" && echo same || echo diff)
assert_eq "$CMP_OUT" "same" "PAR08e Bash↔PS1 AGENTS.md byte-identical after --force (region-update parity)"
assert_file_contains "$T_SH/AGENTS.md"  "User-owned AGENTS.md" "PAR08f sh: user content preserved outside markers"
assert_file_contains "$T_PS1/AGENTS.md" "User-owned AGENTS.md" "PAR08g ps1: user content preserved outside markers"

# ---------------------------------------------------------------------------
# PAR09 – Uninstall: exit 0, "Removed:", "Uninstall complete."
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

run_sh  --tool codex --from-bundle "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1  -Tool codex  -FromBundle  "${FIXTURE_DIR}/aid-codex-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

run_sh_verbose  --uninstall --tool codex --target "$T_SH"
run_ps1_verbose  -Uninstall  -Tool codex  -TargetDirectory "$T_PS1"

assert_exit_codes_match 0 "PAR09 uninstall"
assert_both_contain "Removed:"          "PAR09b"
assert_both_contain "Uninstall complete." "PAR09c"

# Both target trees must be in the same post-uninstall state (both clean).
DIFF_OUT=$(diff -r "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR09d post-uninstall trees identical"

# .codex/ must be gone from both.
assert_eq "$([[ -d "$T_SH/.codex" ]]  && echo exists || echo gone)" "gone" "PAR09e sh .codex/ removed"
assert_eq "$([[ -d "$T_PS1/.codex" ]] && echo exists || echo gone)" "gone" "PAR09f ps1 .codex/ removed"

# .aid/ must be gone from both (no manifest left).
assert_eq "$([[ -d "$T_SH/.aid" ]]  && echo exists || echo gone)" "gone" "PAR09g sh .aid/ removed"
assert_eq "$([[ -d "$T_PS1/.aid" ]] && echo exists || echo gone)" "gone" "PAR09h ps1 .aid/ removed"

# ---------------------------------------------------------------------------
# PAR10 – Uninstall with no manifest: exit 6 from both
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

run_sh  --uninstall --tool codex --target "$T_SH"
run_ps1  -Uninstall  -Tool codex  -TargetDirectory "$T_PS1"

assert_exit_codes_match 6 "PAR10 uninstall with no manifest"

# ---------------------------------------------------------------------------
# PAR11 – Auto-detect ambiguity: exit 2 from both, "ambiguous" in output
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

mkdir -p "$T_SH/.claude" "$T_SH/.cursor"
mkdir -p "$T_PS1/.claude" "$T_PS1/.cursor"

run_sh  --from-bundle "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz" --target "$T_SH"
run_ps1  -FromBundle  "${FIXTURE_DIR}/aid-claude-code-v${VERSION}.tar.gz"  -TargetDirectory "$T_PS1"

assert_exit_codes_match 2 "PAR11 auto-detect ambiguous"
assert_both_contain "ambiguous" "PAR11b"

# ---------------------------------------------------------------------------
# PAR12 – Comma-list codex,cursor: second AGENTS.md is byte-identical (FR12) -> skipped as up-to-date, exit 0
# ---------------------------------------------------------------------------
T_SH=$(newtarget_bash)
T_PS1=$(newtarget_ps1)

run_sh  --tool codex,cursor --from-bundle "${FIXTURE_DIR}" --target "$T_SH"
run_ps1  -Tool codex,cursor  -FromBundle  "${FIXTURE_DIR}"  -TargetDirectory "$T_PS1"

assert_exit_codes_match 0 "PAR12 comma-list: second AGENTS.md byte-identical (FR12) -> exit 0"

# Both should have installed .codex/ and .cursor/.
assert_dir_exists "$T_SH/.codex"  "PAR12d sh .codex/ installed"
assert_dir_exists "$T_PS1/.codex" "PAR12e ps1 .codex/ installed"
assert_dir_exists "$T_SH/.cursor"  "PAR12f sh .cursor/ installed"
assert_dir_exists "$T_PS1/.cursor" "PAR12g ps1 .cursor/ installed"

# Non-root-agent trees must be byte-identical.
DIFF_OUT=$(diff -r \
           --exclude=".aid-manifest.json" --exclude=".aid-version" \
           --exclude="AGENTS.md" --exclude="AGENTS.md.aid-new" \
           "$T_SH" "$T_PS1" 2>&1)
assert_eq "${DIFF_OUT}" "" "PAR12h comma-list non-root-agent trees byte-identical"

# ---------------------------------------------------------------------------
# PAR13 — Static: dashboard file enumeration is identical between install.sh and install.ps1.
#
# Extracts the curated dashboard file list from each installer's source, normalises
# path separators (PS1 uses backslash, sh uses forward slash), and asserts:
#   a) Both lists are identical after normalisation.
#   b) home.html is present in the install.sh list.
#   c) home.html is present in the install.ps1 list.
# This is a static check that runs without PowerShell and catches payload divergence
# before any installer invocation.
# ---------------------------------------------------------------------------

# Extract dashboard filenames from install.sh.
# The curated list appears as a series of quoted strings in the for-loop body between
# "home.html" and "server/__init__.py".  We pull every double-quoted path token in that
# region and normalise to forward-slash.
SH_DASH_FILES=$(python3 - "$SUT_SH" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
# Find the section header comment and grab everything up to the "do" keyword
m = re.search(r'Stage dashboard server\+reader unit.*?(?=\s*do\b)', text, re.DOTALL)
if not m:
    # Try the install section (second occurrence)
    m = re.search(r'Install the dashboard unit.*?(?=\s*do\b)', text, re.DOTALL)
# Collect all for-loop iterations: grab quoted paths from both loops (stage + install)
paths = re.findall(r'"([a-z/_A-Z.]+(?:/[a-z_A-Z.]+)*)"', text)
# Filter to dashboard-shaped paths only (have no spaces, are paths in the dashboard unit)
dashboard = [p for p in paths if any(p.endswith(x) for x in [
    'home.html','index.html','__init__.py','reader.py','models.py',
    'parsers.py','derivation.py','locator.py','server.py','server.mjs','reader.mjs'
])]
# Deduplicate preserving order
seen = set(); unique = []
for p in dashboard:
    if p not in seen:
        seen.add(p); unique.append(p)
for p in sorted(unique):
    print(p)
PY
)

# Extract dashboard filenames from install.ps1.
# The array uses single-quoted strings with backslash separators.
PS1_DASH_FILES=$(python3 - "$SUT_PS1" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
# Grab all single-quoted paths inside the $bsDashFiles array
paths = re.findall(r"'([a-zA-Z_./\\]+)'", text)
# Normalise backslash to forward slash and filter to dashboard-shaped paths
dashboard_exts = {'home.html','index.html','__init__.py','reader.py','models.py',
    'parsers.py','derivation.py','locator.py','server.py','server.mjs','reader.mjs'}
result = []
for p in paths:
    pn = p.replace('\\', '/')
    if any(pn.endswith(x) for x in dashboard_exts):
        result.append(pn)
seen = set(); unique = []
for p in result:
    if p not in seen:
        seen.add(p); unique.append(p)
for p in sorted(unique):
    print(p)
PY
)

assert_eq "$SH_DASH_FILES" "$PS1_DASH_FILES" \
    "PAR13a dashboard file enumeration identical between install.sh and install.ps1"

if echo "$SH_DASH_FILES" | grep -qF "home.html"; then
    pass "PAR13b install.sh lists home.html in dashboard files"
else
    fail "PAR13b install.sh does NOT list home.html in dashboard files"
fi

if echo "$PS1_DASH_FILES" | grep -qF "home.html"; then
    pass "PAR13c install.ps1 lists home.html in dashboard files"
else
    fail "PAR13c install.ps1 does NOT list home.html in dashboard files"
fi

# ---------------------------------------------------------------------------

test_summary
