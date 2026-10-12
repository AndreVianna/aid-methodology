#!/usr/bin/env bash
# test-layout-format-guard.sh - work-001 task-020 (AC-12): layout-format guard suite.
#
# Guards the format bump to 5 and the layout gates that depend on it:
#   S1  carrier equality: AID_SUPPORTED_FORMAT (bin/aid), AidSupportedFormat (bin/aid.ps1),
#       $script:_AidSupportedFormat (lib/AidInstallCore.psm1) and the format_version line of
#       canonical/aid/templates/settings.yml all equal 5.
#   S2  fresh fixture (no manifest, recovery record, v3 legacy evidence or settings) adds a
#       tool; a second add exits 0. A format-3 manifest with stamp 4 is refused unchanged.
#   S3  manifest-less v3 legacy project, migrated by `aid projects add`, is refused by add
#       and keeps stamp 4.
#   S4  a pending upgrade recovery record (no manifest, or a format-3 manifest) makes
#       aid add and aid remove exit 2 naming `aid update`.
#   S5  a manifest format_version above 3 is refused read-only (aid add, aid update,
#       aid status; with and without a recovery record) with `Run: aid update self`.
#       PowerShell twin of S5 runs only when pwsh is present.
#
# Every fixture is built under a fresh mktemp directory inside a throwaway HOME. No frozen
# v3 core and no guard artifact is used: fixtures are produced by the current CLI.
#
# Carrier override (negative check): AID_LAYOUT_GUARD_CARRIER_ROOT=<dir> makes S1 read the
# four carriers from <dir> instead of the repo root, so a scratch copy with one value changed
# to 6 must fail the carrier-equality assertion.
#
# Usage:  HOME=$(mktemp -d) bash tests/canonical/test-layout-format-guard.sh [--verbose]
# Exit:   0 all pass / 1 any fail.
#
# COVERS: bin/aid
# COVERS: bin/aid.ps1
# COVERS: lib/aid-install-core.sh
# COVERS: lib/AidInstallCore.psm1
# COVERS: canonical/aid/templates/settings.yml

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${HERE}/../.." && pwd)"
CARRIER_ROOT="${AID_LAYOUT_GUARD_CARRIER_ROOT:-$REPO_ROOT}"

source "${HERE}/../lib/assert.sh"
source "${HERE}/../lib/sandbox.sh"
source "${HERE}/../lib/bundle.sh"
source "${HERE}/../lib/pwsh.sh"
source "${HERE}/../lib/pwsh-batch.sh"

# Detect pwsh BEFORE pinning HOME (detect-before-pin invariant; see pwsh.sh).
PWSH="$(detect_pwsh || true)"

TMP="$(mktemp -d)"
trap '[[ -n "$PWSH" ]] && pwsh_session_stop >/dev/null 2>&1; rm -rf "$TMP"' EXIT

# ISOLATION: the whole process runs under a throwaway HOME; the real HOME's .aid is canaried.
sandbox_pin_home
export AID_NO_UPDATE_CHECK=1

BUNDLE="${TMP}/bundle"
mkdir -p "$BUNDLE"
aid_test_stage_bundle "$BUNDLE" >/dev/null 2>&1 \
    || { echo "ERROR: shared release staging failed" >&2; exit 1; }

# Code homes: the CLI under test, copied into TMP (never executed from the repo tree for writes).
CODE_SH="${TMP}/code-sh"
mkdir -p "${CODE_SH}/bin" "${CODE_SH}/lib"
cp "${REPO_ROOT}/bin/aid" "${CODE_SH}/bin/aid"
cp "${REPO_ROOT}/lib/aid-install-core.sh" "${CODE_SH}/lib/aid-install-core.sh"
cp "${REPO_ROOT}/VERSION" "${CODE_SH}/VERSION"

if [[ -n "$PWSH" ]]; then
    CODE_PS="${TMP}/code-ps"
    mkdir -p "${CODE_PS}/bin" "${CODE_PS}/lib"
    cp "${REPO_ROOT}/bin/aid.ps1" "${CODE_PS}/bin/aid.ps1"
    cp "${REPO_ROOT}/lib/AidInstallCore.psm1" "${CODE_PS}/lib/AidInstallCore.psm1"
    cp "${REPO_ROOT}/VERSION" "${CODE_PS}/VERSION"
    pwsh_session_start
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# tree_snapshot <dir>: one sha256 over sorted relative paths, object types and file bytes,
# so a refused write cannot hide behind an unchanged manifest.
tree_snapshot() {
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

# new_fixture <label>: a fresh project directory under TMP.
new_fixture() { mktemp -d "${TMP}/fx-$1.XXXXXX"; }

# sh_run <args...>: run the bash CLI under test; sets OUT and RC.
sh_run() {
    OUT=$(AID_HOME="$CODE_SH" AID_LIB_PATH="${CODE_SH}/lib/aid-install-core.sh" \
          AID_NO_UPDATE_CHECK=1 bash "${CODE_SH}/bin/aid" "$@" 2>&1); RC=$?
}

# ps_arg <bash-style arg>: map --flag-name to -FlagName for aid.ps1; other args pass through.
ps_arg() {
    local arg="$1" name part out="" parts=()
    if [[ "$arg" == --* ]]; then
        name="${arg#--}"
        IFS='-' read -ra parts <<< "$name"
        for part in "${parts[@]}"; do out+="${part^}"; done
        printf -- '-%s' "$out"
    else
        printf '%s' "$arg"
    fi
}

# ps_run <args...>: run aid.ps1 under pwsh with the same bash-style arguments; sets OUT and RC.
ps_run() {
    local -a pargs=() ; local a
    for a in "$@"; do pargs+=("$(ps_arg "$a")"); done
    pwsh_session_call "${CODE_PS}/bin/aid.ps1" "$TMP" \
        "AID_HOME=${CODE_PS}" "AID_LIB_PATH=${CODE_PS}/lib/AidInstallCore.psm1" \
        "AID_NO_UPDATE_CHECK=1" -- "${pargs[@]}"
    OUT=$(printf '%s' "$PWSH_CALL_OUT" | sed 's/\x1b\[[0-9;]*m//g'); RC=$PWSH_CALL_RC
}

# settings_stamp <dir>: the format_version value in .aid/settings.yml ("" when absent).
settings_stamp() {
    sed -n 's/^format_version: *\([0-9][0-9]*\).*/\1/p' "$1/.aid/settings.yml" 2>/dev/null | head -1
}

# set_settings_stamp <dir> <value>: rewrite the settings format_version line in place.
set_settings_stamp() {
    local f="$1/.aid/settings.yml"
    sed "s/^format_version: [0-9][0-9]*/format_version: $2/" "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
}

# set_manifest_format <dir> <value>: rewrite the manifest format_version in place.
set_manifest_format() {
    local f="$1/.aid/.aid-manifest.json"
    sed "s/\"format_version\":[[:space:]]*[0-9][0-9]*/\"format_version\": $2/" "$f" > "${f}.tmp" \
        && mv "${f}.tmp" "$f"
}

# write_recovery <dir>: a pending v3 upgrade record naming cursor.
write_recovery() {
    mkdir -p "$1/.aid/.temp"
    printf '%s\n' '{"format_version":1,"tools":["cursor"],"retired":false}' > "$1/.aid/.temp/v3-upgrade-tools.json"
}

# ---------------------------------------------------------------------------
# S1: carrier equality
# ---------------------------------------------------------------------------
BIN_VAL="$(sed -n 's/^readonly AID_SUPPORTED_FORMAT=\([0-9][0-9]*\).*/\1/p' "${CARRIER_ROOT}/bin/aid" | head -1)"
PS1_VAL="$(sed -n 's/^Set-Variable -Name AidSupportedFormat -Value \([0-9][0-9]*\) .*/\1/p' "${CARRIER_ROOT}/bin/aid.ps1" | head -1)"
PSM_VAL="$(sed -n 's/^\$script:_AidSupportedFormat = \([0-9][0-9]*\).*/\1/p' "${CARRIER_ROOT}/lib/AidInstallCore.psm1" | head -1)"
TPL_VAL="$(sed -n 's/^format_version: \([0-9][0-9]*\).*/\1/p' "${CARRIER_ROOT}/canonical/aid/templates/settings.yml" | head -1)"

assert_eq "$BIN_VAL" 5 "carrier equality: bin/aid AID_SUPPORTED_FORMAT is 5"
assert_eq "$PS1_VAL" 5 "carrier equality: bin/aid.ps1 AidSupportedFormat is 5"
assert_eq "$PSM_VAL" 5 "carrier equality: lib/AidInstallCore.psm1 _AidSupportedFormat is 5"
assert_eq "$TPL_VAL" 5 "carrier equality: settings.yml template format_version is 5"
assert_eq "${BIN_VAL}|${PS1_VAL}|${PSM_VAL}|${TPL_VAL}" "5|5|5|5" \
    "carrier equality: all four carriers hold the same value"

# ---------------------------------------------------------------------------
# S2: fresh missing-settings add, and format-3/stamp-4 refusal
# ---------------------------------------------------------------------------
F="$(new_fixture fresh)"
assert_eq "$(test -e "$F/.aid/settings.yml" && echo present || echo absent)" "absent" \
    "fresh missing-settings add: fixture starts with no settings file"
sh_run add cursor --from-bundle "$BUNDLE" --target "$F"
assert_exit_eq "$RC" 0 "fresh missing-settings add: first aid add cursor exits 0"
sh_run add claude-code --from-bundle "$BUNDLE" --target "$F"
assert_exit_eq "$RC" 0 "fresh missing-settings add: second aid add claude-code exits 0"
assert_eq "$(settings_stamp "$F")" 5 "fresh missing-settings add: settings stamp is 5"

F="$(new_fixture stamp4)"
sh_run add cursor --from-bundle "$BUNDLE" --target "$F"
assert_exit_eq "$RC" 0 "format-3/stamp-4 refusal: setup add cursor exits 0"
set_settings_stamp "$F" 4
assert_eq "$(settings_stamp "$F")" 4 "format-3/stamp-4 refusal: setup settings stamp rewritten to 4"
assert_file_contains "$F/.aid/.aid-manifest.json" '"format_version": 3' \
    "format-3/stamp-4 refusal: setup manifest records format_version 3"
BEFORE="$(tree_snapshot "$F")"
sh_run add claude-code --from-bundle "$BUNDLE" --target "$F"
assert_exit_ne "$RC" 0 "format-3/stamp-4 refusal: aid add claude-code exits non-zero"
assert_output_contains "$OUT" "aid update" "format-3/stamp-4 refusal: output names aid update"
assert_eq "$(tree_snapshot "$F")" "$BEFORE" "format-3/stamp-4 refusal: fixture snapshot unchanged"

# ---------------------------------------------------------------------------
# S3: manifest-less v3 legacy after projects-add migration
# ---------------------------------------------------------------------------
F="$(new_fixture legacy)"
mkdir -p "$F/.aid" "$F/.cursor/aid"
printf 'format_version: 4\nname: legacy-fixture\n' > "$F/.aid/settings.yml"
printf 'legacy rules\n' > "$F/.cursor/aid/rules.md"
sh_run projects add "$F"
assert_exit_eq "$RC" 0 "manifest-less legacy after projects-add migration: aid projects add exits 0"
assert_eq "$(settings_stamp "$F")" 4 \
    "manifest-less legacy after projects-add migration: settings stamp stays 4"
BEFORE="$(tree_snapshot "$F")"
sh_run add cursor --from-bundle "$BUNDLE" --target "$F"
assert_exit_ne "$RC" 0 "manifest-less legacy after projects-add migration: aid add cursor exits non-zero"
assert_output_contains "$OUT" "aid update" \
    "manifest-less legacy after projects-add migration: output names aid update"
assert_eq "$(tree_snapshot "$F")" "$BEFORE" \
    "manifest-less legacy after projects-add migration: fixture snapshot unchanged"

# ---------------------------------------------------------------------------
# S4: recovery add/remove gates (no manifest, and format-3 manifest)
# ---------------------------------------------------------------------------
F="$(new_fixture recovery-nomanifest)"
write_recovery "$F"
BEFORE="$(tree_snapshot "$F")"
sh_run add claude-code --from-bundle "$BUNDLE" --target "$F"
assert_exit_eq "$RC" 2 "recovery add/remove gate (no manifest): aid add exits 2"
assert_output_contains "$OUT" "aid update" "recovery add/remove gate (no manifest): aid add names aid update"
assert_eq "$(tree_snapshot "$F")" "$BEFORE" "recovery add/remove gate (no manifest): aid add leaves snapshot unchanged"
sh_run remove cursor --target "$F"
assert_exit_eq "$RC" 2 "recovery add/remove gate (no manifest): aid remove exits 2"
assert_output_contains "$OUT" "aid update" "recovery add/remove gate (no manifest): aid remove names aid update"
assert_eq "$(tree_snapshot "$F")" "$BEFORE" "recovery add/remove gate (no manifest): aid remove leaves snapshot unchanged"

F="$(new_fixture recovery-v3manifest)"
sh_run add cursor --from-bundle "$BUNDLE" --target "$F"
assert_exit_eq "$RC" 0 "recovery add/remove gate (format-3 manifest): setup add cursor exits 0"
write_recovery "$F"
BEFORE="$(tree_snapshot "$F")"
sh_run add claude-code --from-bundle "$BUNDLE" --target "$F"
assert_exit_eq "$RC" 2 "recovery add/remove gate (format-3 manifest): aid add exits 2"
assert_output_contains "$OUT" "aid update" "recovery add/remove gate (format-3 manifest): aid add names aid update"
assert_eq "$(tree_snapshot "$F")" "$BEFORE" "recovery add/remove gate (format-3 manifest): aid add leaves snapshot unchanged"
sh_run remove cursor --target "$F"
assert_exit_eq "$RC" 2 "recovery add/remove gate (format-3 manifest): aid remove exits 2"
assert_output_contains "$OUT" "aid update" "recovery add/remove gate (format-3 manifest): aid remove names aid update"
assert_eq "$(tree_snapshot "$F")" "$BEFORE" "recovery add/remove gate (format-3 manifest): aid remove leaves snapshot unchanged"

# ---------------------------------------------------------------------------
# S5: future-format read-only refusal (bash always; PowerShell when pwsh is present)
# ---------------------------------------------------------------------------
# future_fixture <label> <with-recovery:0|1>: a real v5 install whose manifest is bumped to 4.
future_fixture() {
    local f
    f="$(new_fixture "$1")"
    sh_run add cursor --from-bundle "$BUNDLE" --target "$f"
    [[ "$RC" -eq 0 ]] || { echo "ERROR: future-format setup add cursor failed: $OUT" >&2; return 1; }
    set_manifest_format "$f" 4
    [[ "$2" == 1 ]] && write_recovery "$f"
    printf '%s' "$f"
}

for variant in plain recovery; do
    if [[ "$variant" == recovery ]]; then RECOVERY=1; else RECOVERY=0; fi
    F="$(future_fixture "future-${variant}" "$RECOVERY")"
    assert_file_contains "$F/.aid/.aid-manifest.json" '"format_version": 4' \
        "future-format read-only refusal (${variant}): setup manifest records format_version 4"
    BEFORE="$(tree_snapshot "$F")"

    sh_run add claude-code --from-bundle "$BUNDLE" --target "$F"
    assert_exit_ne "$RC" 0 "future-format read-only refusal (${variant}): bash aid add exits non-zero"
    assert_output_contains "$OUT" "Run: aid update self" \
        "future-format read-only refusal (${variant}): bash aid add names Run: aid update self"
    assert_eq "$(tree_snapshot "$F")" "$BEFORE" \
        "future-format read-only refusal (${variant}): bash aid add leaves snapshot unchanged"

    sh_run update --from-bundle "$BUNDLE" --target "$F"
    assert_exit_ne "$RC" 0 "future-format read-only refusal (${variant}): bash aid update exits non-zero"
    assert_output_contains "$OUT" "Run: aid update self" \
        "future-format read-only refusal (${variant}): bash aid update names Run: aid update self"
    assert_eq "$(tree_snapshot "$F")" "$BEFORE" \
        "future-format read-only refusal (${variant}): bash aid update leaves snapshot unchanged"

    sh_run status --target "$F"
    assert_exit_ne "$RC" 0 "future-format read-only refusal (${variant}): bash aid status exits non-zero"
    assert_output_contains "$OUT" "Run: aid update self" \
        "future-format read-only refusal (${variant}): bash aid status names Run: aid update self"
    assert_eq "$(tree_snapshot "$F")" "$BEFORE" \
        "future-format read-only refusal (${variant}): bash aid status leaves snapshot unchanged"

    if [[ -n "$PWSH" ]]; then
        BEFORE="$(tree_snapshot "$F")"
        ps_run add claude-code --from-bundle "$BUNDLE" --target "$F"
        assert_exit_ne "$RC" 0 "future-format read-only refusal (${variant}): PowerShell aid add exits non-zero"
        assert_output_contains "$OUT" "Run: aid update self" \
            "future-format read-only refusal (${variant}): PowerShell aid add names Run: aid update self"
        assert_eq "$(tree_snapshot "$F")" "$BEFORE" \
            "future-format read-only refusal (${variant}): PowerShell aid add leaves snapshot unchanged"

        ps_run update --from-bundle "$BUNDLE" --target "$F"
        assert_exit_ne "$RC" 0 "future-format read-only refusal (${variant}): PowerShell aid update exits non-zero"
        assert_output_contains "$OUT" "Run: aid update self" \
            "future-format read-only refusal (${variant}): PowerShell aid update names Run: aid update self"
        assert_eq "$(tree_snapshot "$F")" "$BEFORE" \
            "future-format read-only refusal (${variant}): PowerShell aid update leaves snapshot unchanged"

        ps_run status --target "$F"
        assert_exit_ne "$RC" 0 "future-format read-only refusal (${variant}): PowerShell aid status exits non-zero"
        assert_output_contains "$OUT" "Run: aid update self" \
            "future-format read-only refusal (${variant}): PowerShell aid status names Run: aid update self"
        assert_eq "$(tree_snapshot "$F")" "$BEFORE" \
            "future-format read-only refusal (${variant}): PowerShell aid status leaves snapshot unchanged"
    fi
done

if [[ -z "$PWSH" ]]; then
    log "PowerShell future-format cases skipped: pwsh not found on PATH"
fi

# End-of-suite canary: the real HOME's .aid subtree must be untouched.
sandbox_assert_aid_untouched "layout-format guard: real HOME .aid subtree untouched"

test_summary
