#!/usr/bin/env bash
# Purpose: verify release checksum parsing against real sha256sum formats.
# Usage: bash tests/canonical/test-release-checksum-format.sh [--verbose]
# Exit codes: 0 all checks pass; 1 one or more checks fail.
# COVERS: lib/aid-install-core.sh lib/AidInstallCore.psm1
set -uo pipefail
VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
source "$HERE/../lib/assert.sh"
source "$ROOT/lib/aid-install-core.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
artifact="$TMP/aid.tool-v1.tar.gz"
sums="$TMP/SHA256SUMS"
printf 'release payload\n' > "$artifact"
hash="$(sha256_file "$artifact")"
wrong="$(printf 'wrong payload\n' | sha256sum | awk '{print $1}')"

printf '%s  %s\n' "$hash" 'aid.tool-v1.tar.gz' > "$sums"
_verify_checksum "$artifact" "$sums" >/dev/null 2>&1; rc=$?
assert_exit_zero "$rc" 'CS01 standard text-mode sha256sum entry accepts matching SHA'

printf '%s *%s\n' "$hash" 'aid.tool-v1.tar.gz' > "$sums"
_verify_checksum "$artifact" "$sums" >/dev/null 2>&1; rc=$?
assert_exit_zero "$rc" 'CS02 standard binary-mode sha256sum entry accepts matching SHA'

for mode in text binary; do
    if [[ "$mode" == text ]]; then printf '%s  %s\n' "$wrong" 'aid.tool-v1.tar.gz' > "$sums"
    else printf '%s *%s\n' "$wrong" 'aid.tool-v1.tar.gz' > "$sums"; fi
    _verify_checksum "$artifact" "$sums" >/dev/null 2>&1; rc=$?
    assert_exit_eq "$rc" 4 "CS03 $mode mode rejects incorrect SHA"
done

printf '%s  %s\n' "$hash" 'aidXtool-v1XtarXgz' > "$sums"
_verify_checksum "$artifact" "$sums" >/dev/null 2>&1; rc=$?
assert_exit_eq "$rc" 4 'CS04 missing exact filename cannot match regex lookalike'

if command -v pwsh >/dev/null 2>&1; then
    # The test enters module scope to exercise the real, private function.
    cat > "$TMP/check.ps1" <<'PS1'
$module = Import-Module -Name $env:CHECK_CORE_PS -PassThru -Force
$result = & $module { param($artifact, $sums) Invoke-VerifyChecksum $artifact $sums } $env:CHECK_ARTIFACT $env:CHECK_SUMS
if ($result) { exit 0 } else { exit 4 }
PS1
    native() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi; }
    export CHECK_CORE_PS="$(native "$ROOT/lib/AidInstallCore.psm1")"
    export CHECK_ARTIFACT="$(native "$artifact")" CHECK_SUMS="$(native "$sums")"
    pscheck() { pwsh -NoProfile -NonInteractive -File "$(native "$TMP/check.ps1")" >/dev/null 2>&1; }
    printf '%s  %s\n' "$hash" 'aid.tool-v1.tar.gz' > "$sums"
    pscheck; rc=$?
    assert_exit_zero "$rc" 'CS07 PowerShell accepts text-mode matching SHA'
    printf '%s *%s\n' "$hash" 'aid.tool-v1.tar.gz' > "$sums"
    pscheck; rc=$?
    assert_exit_zero "$rc" 'CS08 PowerShell accepts binary-mode matching SHA'
    for mode in text binary; do
        if [[ "$mode" == text ]]; then printf '%s  %s\n' "$wrong" 'aid.tool-v1.tar.gz' > "$sums"
        else printf '%s *%s\n' "$wrong" 'aid.tool-v1.tar.gz' > "$sums"; fi
        pscheck; rc=$?
        assert_exit_eq "$rc" 4 "CS09 PowerShell $mode mode rejects incorrect SHA"
    done
    printf '%s  %s\n' "$hash" 'aidXtool-v1XtarXgz' > "$sums"
    pscheck; rc=$?
    assert_exit_eq "$rc" 4 'CS10 PowerShell rejects regex-lookalike filename'
else
    echo 'SKIP: PowerShell checksum checks (pwsh not available)'
fi

test_summary
