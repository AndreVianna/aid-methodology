#!/usr/bin/env bash
# test-install-manifests-lockstep.sh - Assert all 5 install manifests agree on
# the dashboard 12-file set (H1 debt item from tech-debt.md).
#
# The dashboard server+reader unit is a 12-file set hard-coded independently in
# five manifests. A silent omission breaks provisioning on exactly one channel.
# This suite catches drift before it can merge.
#
# Checks:
#   LCK01 - install.sh internal consistency (stage loop == install loop)
#   LCK02 - release.sh internal consistency (cp block == tar file-list)
#   LCK03a - install.ps1 matches install.sh
#   LCK03b - vendor.js matches install.sh
#   LCK03c - vendor.py matches install.sh
#   LCK03d - release.sh matches install.sh
#   LCK04a - self-canary: union is non-empty
#   LCK04b - self-canary: union contains sentinel home.html
#   LCK04c - self-canary: union contains sentinel server/reader.mjs
#
# Pure text/structural: no network, no Playwright, no installs, no $HOME access.
# HOME is NOT pinned (this suite does not invoke AID scan surfaces).
#
# Manifest paths can be overridden via env vars for mutation testing:
#   LOCKSTEP_INSTALL_SH  LOCKSTEP_INSTALL_PS1  LOCKSTEP_VENDOR_JS
#   LOCKSTEP_VENDOR_PY   LOCKSTEP_RELEASE_SH
#
# Usage:
#   bash test-install-manifests-lockstep.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Manifest paths -- overridable via env vars for mutation testing.
INSTALL_SH="${LOCKSTEP_INSTALL_SH:-${REPO_ROOT}/install.sh}"
INSTALL_PS1="${LOCKSTEP_INSTALL_PS1:-${REPO_ROOT}/install.ps1}"
VENDOR_JS="${LOCKSTEP_VENDOR_JS:-${REPO_ROOT}/packages/npm/scripts/vendor.js}"
VENDOR_PY="${LOCKSTEP_VENDOR_PY:-${REPO_ROOT}/packages/pypi/scripts/vendor.py}"
RELEASE_SH="${LOCKSTEP_RELEASE_SH:-${REPO_ROOT}/release.sh}"

echo "=== Install-manifest lockstep check ==="

# Verify all 5 manifests exist before any extraction.
for _mf in "$INSTALL_SH" "$INSTALL_PS1" "$VENDOR_JS" "$VENDOR_PY" "$RELEASE_SH"; do
    [[ -f "$_mf" ]] || { echo "ERROR: manifest not found: $_mf" >&2; exit 1; }
done

log "install.sh  : $INSTALL_SH"
log "install.ps1 : $INSTALL_PS1"
log "vendor.js   : $VENDOR_JS"
log "vendor.py   : $VENDOR_PY"
log "release.sh  : $RELEASE_SH"

# ---------------------------------------------------------------------------
# Extraction functions.
# Each function emits one path per line (relative to dashboard/, forward-slash,
# sorted, deduplicated). Exits 1 on parse failure so the caller can abort.
# ---------------------------------------------------------------------------

# install.sh: extract paths from occurrence N of the "for _df in \" for loop.
# Occurrence 1 = stage loop, occurrence 2 = install loop.
# Paths are listed WITHOUT a dashboard/ prefix in the for loop body.
_extract_install_sh_loop() {
    local occ="$1"
    python3 - "$INSTALL_SH" "$occ" <<'PY'
import re, sys

text = open(sys.argv[1]).read()
occ = int(sys.argv[2])

# Match: for _df in \<NL> then lines "path" \ (with trailing backslash) or
# "path"<NL> (last item, no backslash), then do.
pattern = re.compile(
    r'for _df in \\\n'
    r'((?:[ \t]+"[^"]+"\s*\\\n)*'
    r'[ \t]+"[^"]+"\s*\n)'
    r'[ \t]*do',
    re.MULTILINE
)
matches = list(pattern.finditer(text))
if not matches:
    print("ERROR: no 'for _df in' loop found in install.sh", file=sys.stderr)
    sys.exit(1)
if occ > len(matches):
    print(
        "ERROR: occurrence {} not found ({} loops found)".format(
            occ, len(matches)
        ),
        file=sys.stderr
    )
    sys.exit(1)

block = matches[occ - 1].group(1)
paths = re.findall(r'"([^"]+)"', block)
for p in sorted(set(paths)):
    print(p)
PY
}

# install.ps1: extract paths from the $bsDashFiles = @(...) array.
# Backslash separators are normalized to forward slash.
_extract_install_ps1() {
    python3 - "$INSTALL_PS1" <<'PY'
import re, sys

text = open(sys.argv[1]).read()
m = re.search(r'\$bsDashFiles\s*=\s*@\((.*?)\)', text, re.DOTALL)
if not m:
    print("ERROR: $bsDashFiles array not found in install.ps1", file=sys.stderr)
    sys.exit(1)

paths = re.findall(r"'([^']+)'", m.group(1))
normalized = [p.replace('\\', '/') for p in paths]
for p in sorted(set(normalized)):
    print(p)
PY
}

# vendor.js: extract paths from ['dashboard/<path>', ...] entries in var copies.
# Strips the 'dashboard/' prefix.
_extract_vendor_js() {
    python3 - "$VENDOR_JS" <<'PY'
import re, sys

text = open(sys.argv[1]).read()
# Match ['dashboard/<path>', ...] entries (COPIES array, not doc-comment).
paths = re.findall(r"\['(dashboard/[^']+)'", text)
if not paths:
    print("ERROR: no ['dashboard/...'] entries found in vendor.js", file=sys.stderr)
    sys.exit(1)
stripped = [p[len('dashboard/'):] for p in paths]
for p in sorted(set(stripped)):
    print(p)
PY
}

# vendor.py: extract paths from ("dashboard/<path>", ...) tuples in COPIES list.
# Strips the 'dashboard/' prefix.
_extract_vendor_py() {
    python3 - "$VENDOR_PY" <<'PY'
import re, sys

text = open(sys.argv[1]).read()
# Match ("dashboard/<path>", ...) tuples (COPIES list, not doc-comment).
paths = re.findall(r'\("(dashboard/[^"]+)"', text)
if not paths:
    print("ERROR: no (\"dashboard/...\") tuples found in vendor.py", file=sys.stderr)
    sys.exit(1)
stripped = [p[len('dashboard/'):] for p in paths]
for p in sorted(set(stripped)):
    print(p)
PY
}

# release.sh cp block: extract paths from cp "${REPO_ROOT}/dashboard/<path>" lines.
_extract_release_sh_cp() {
    python3 - "$RELEASE_SH" <<'PY'
import re, sys

text = open(sys.argv[1]).read()
paths = re.findall(r'cp "\$\{REPO_ROOT\}/dashboard/([^"]+)"', text)
if not paths:
    print("ERROR: no cp \"${REPO_ROOT}/dashboard/...\" lines found in release.sh",
          file=sys.stderr)
    sys.exit(1)
for p in sorted(set(paths)):
    print(p)
PY
}

# release.sh tar file-list: extract paths from "./dashboard/<path>" entries.
_extract_release_sh_tar() {
    python3 - "$RELEASE_SH" <<'PY'
import re, sys

text = open(sys.argv[1]).read()
paths = re.findall(r'"./dashboard/([^"]+)"', text)
if not paths:
    print("ERROR: no \"./dashboard/...\" entries found in release.sh", file=sys.stderr)
    sys.exit(1)
for p in sorted(set(paths)):
    print(p)
PY
}

# Helper: print a per-manifest diff report when two sorted sets differ.
_diff_report() {
    local label_a="$1" set_a="$2" label_b="$3" set_b="$4"
    echo "  ${label_a} (reference):"
    echo "$set_a" | sed 's/^/    /'
    echo "  ${label_b}:"
    echo "$set_b" | sed 's/^/    /'
    echo "  Missing from ${label_b} (in reference but not in ${label_b}):"
    comm -23 <(echo "$set_a") <(echo "$set_b") | sed 's/^/    /'
    echo "  Extra in ${label_b} (in ${label_b} but not in reference):"
    comm -13 <(echo "$set_a") <(echo "$set_b") | sed 's/^/    /'
}

# ---------------------------------------------------------------------------
# LCK01 -- install.sh internal consistency (stage loop == install loop)
# ---------------------------------------------------------------------------
echo "--- LCK01: install.sh internal consistency ---"
ISH_LOOP1=$(_extract_install_sh_loop 1) \
    || { echo "ERROR: install.sh loop 1 extraction failed" >&2; exit 1; }
ISH_LOOP2=$(_extract_install_sh_loop 2) \
    || { echo "ERROR: install.sh loop 2 extraction failed" >&2; exit 1; }

if [[ "$ISH_LOOP1" == "$ISH_LOOP2" ]]; then
    pass "LCK01 install.sh stage loop == install loop"
else
    fail "LCK01 install.sh stage loop != install loop"
    _diff_report "stage loop" "$ISH_LOOP1" "install loop" "$ISH_LOOP2"
fi

# ---------------------------------------------------------------------------
# LCK02 -- release.sh internal consistency (cp block == tar file-list)
# ---------------------------------------------------------------------------
echo "--- LCK02: release.sh internal consistency ---"
RSH_CP=$(_extract_release_sh_cp) \
    || { echo "ERROR: release.sh cp block extraction failed" >&2; exit 1; }
RSH_TAR=$(_extract_release_sh_tar) \
    || { echo "ERROR: release.sh tar list extraction failed" >&2; exit 1; }

if [[ "$RSH_CP" == "$RSH_TAR" ]]; then
    pass "LCK02 release.sh cp block == tar file-list"
else
    fail "LCK02 release.sh cp block != tar file-list"
    _diff_report "cp block" "$RSH_CP" "tar file-list" "$RSH_TAR"
fi

# ---------------------------------------------------------------------------
# Extract canonical set from each manifest for cross-manifest comparison.
# Reference: install.sh loop 1 (internally verified in LCK01 above).
# ---------------------------------------------------------------------------
SET_INSTALL_SH="$ISH_LOOP1"
SET_INSTALL_PS1=$(_extract_install_ps1) \
    || { echo "ERROR: install.ps1 extraction failed" >&2; exit 1; }
SET_VENDOR_JS=$(_extract_vendor_js) \
    || { echo "ERROR: vendor.js extraction failed" >&2; exit 1; }
SET_VENDOR_PY=$(_extract_vendor_py) \
    || { echo "ERROR: vendor.py extraction failed" >&2; exit 1; }
SET_RELEASE_SH="$RSH_CP"

# ---------------------------------------------------------------------------
# LCK03 -- Cross-manifest: all 5 sets must be identical.
# ---------------------------------------------------------------------------
echo "--- LCK03: cross-manifest agreement ---"

_check_manifest_match() {
    local label="$1" name="$2" set_actual="$3"
    if [[ "$set_actual" == "$SET_INSTALL_SH" ]]; then
        pass "$label $name matches install.sh"
    else
        fail "$label $name DIFFERS from install.sh"
        _diff_report "install.sh" "$SET_INSTALL_SH" "$name" "$set_actual"
    fi
}

_check_manifest_match "LCK03a" "install.ps1" "$SET_INSTALL_PS1"
_check_manifest_match "LCK03b" "vendor.js"   "$SET_VENDOR_JS"
_check_manifest_match "LCK03c" "vendor.py"   "$SET_VENDOR_PY"
_check_manifest_match "LCK03d" "release.sh"  "$SET_RELEASE_SH"

# ---------------------------------------------------------------------------
# LCK04 -- Self-canary: union is non-empty and contains sentinel paths.
# Guards against a parser that silently extracts nothing (vacuous PASS).
# ---------------------------------------------------------------------------
echo "--- LCK04: self-canary ---"

UNION_SET=$(printf '%s\n%s\n%s\n%s\n%s\n' \
    "$SET_INSTALL_SH" "$SET_INSTALL_PS1" \
    "$SET_VENDOR_JS"  "$SET_VENDOR_PY" \
    "$SET_RELEASE_SH" \
    | sort -u)

# Count non-empty lines (safe: no grep exit-code ambiguity).
FILE_COUNT=0
while IFS= read -r _path; do
    [[ -n "$_path" ]] && FILE_COUNT=$((FILE_COUNT + 1))
done <<< "$UNION_SET"

if [[ "$FILE_COUNT" -gt 0 ]]; then
    pass "LCK04a union is non-empty ($FILE_COUNT files)"
else
    fail "LCK04a union is empty -- parser extracted nothing"
fi

if echo "$UNION_SET" | grep -qF "home.html"; then
    pass "LCK04b union contains sentinel home.html"
else
    fail "LCK04b union does NOT contain sentinel home.html"
fi

if echo "$UNION_SET" | grep -qF "server/reader.mjs"; then
    pass "LCK04c union contains sentinel server/reader.mjs"
else
    fail "LCK04c union does NOT contain sentinel server/reader.mjs"
fi

echo ""
echo "Agreed dashboard file set ($FILE_COUNT files):"
echo "$UNION_SET" | sed 's/^/  /'

test_summary
