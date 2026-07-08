#!/usr/bin/env bash
# test-connector-twins-ps1-parity.sh -- PowerShell functional parity coverage
# for connector-registry.ps1 and build-connectors-index.ps1 (task-001 AC3,
# task-005 AC4, work-002-external_sources / delivery-001 gate row #2).
#
# Neither connector-registry.ps1 nor build-connectors-index.ps1 had a
# functional PS test before this suite -- only connector-secret.ps1 (the
# security-sensitive twin) did (test-connector-secret-ps1.sh). That left the
# "behavior-equal twin" AC and cross-twin byte-identity unverified, which is
# the exact gap that let a generator: frontmatter divergence between the two
# build-connectors-index.{sh,ps1} twins ship undetected.
#
# This suite is a thin bash wrapper (like test-connector-secret-ps1.sh): it
# invokes `pwsh` as the SUT and asserts via tests/lib/assert.sh. Skips
# (exit 0) when pwsh is not on PATH. It deliberately does NOT re-implement the
# full Bash suites' case lists (test-connector-registry.sh T1-T14,
# test-build-connectors-index.sh BCI01-BCI15) -- it covers PS-twin behavior
# plus the one assertion neither Bash suite can make on its own: that the two
# twins of build-connectors-index produce byte-identical output over the SAME
# fixture (this locks the generator: field fix permanently).
#
# Tests:
#   Registry (connector-registry.ps1):
#     R1   list: sorted stems, excludes INDEX.md/.gitignore/.secrets contents
#     R2   list: exits 0 with empty output when the root does not exist
#     R3   read: happy path -- scalar field
#     R4   read: happy path -- quoted-string field, quotes stripped
#     R5   read: frontmatter-scoped -- a decoy body "field: value" line (after
#          a body-level thematic-break) is never matched
#     R6   read: missing field -- exits 1
#     R7   read: missing descriptor -- exits 1
#     R8   unknown operation -- exits 2
#     R9   read with missing <Field> -- exits 2
#   Builder (build-connectors-index.ps1):
#     B1   auth_method: none -> Secret Ref renders as an em dash
#     B2   full-field descriptor -- all 6 cells populated, linked
#     B3   DETERMINISM -- two PS runs over an identical descriptor set are
#          byte-identical (sha256 compare)
#     B4   header-only empty case (non-existent root) -> zero data rows
#   Cross-twin:
#     X1   BYTE-IDENTITY -- running the .sh builder and the .ps1 builder over
#          the SAME fixture root produces byte-identical INDEX.md output
#          (locks the generator: field fix permanently; feature-001 frozen
#          "regeneration is byte-identical" contract, KI-010, AC-8)
#
# Usage:
#   bash test-connector-twins-ps1-parity.sh [--verbose]
# Exit codes: 0 all pass (or skip, no pwsh) / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY_PS="${REPO_ROOT}/canonical/aid/scripts/connectors/connector-registry.ps1"
BUILDER_PS="${REPO_ROOT}/canonical/aid/scripts/connectors/build-connectors-index.ps1"
BUILDER_SH="${REPO_ROOT}/canonical/aid/scripts/connectors/build-connectors-index.sh"

for f in "$REGISTRY_PS" "$BUILDER_PS" "$BUILDER_SH"; do
    [[ -f "$f" ]] || { echo "ERROR: SUT not found at $f" >&2; exit 1; }
done

if ! command -v pwsh >/dev/null 2>&1; then
    echo "SKIP: pwsh not found on PATH -- skipping connector PS1 twin parity suite (needs PowerShell)."
    exit 0
fi

echo "== connector-registry.ps1 / build-connectors-index.ps1 twin parity tests =="

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# run_ps SUT ARGS... -> no stdin piped (stdin closed); sets OUT, ERR, RC
# pwsh writes CRLF line endings on a Windows host when stdout is redirected
# (a host/runtime artifact, not SUT behavior -- multi-line output on disk via
# [System.IO.File]::WriteAllText, e.g. the builder's INDEX.md, is unaffected:
# that path joins with a literal "`n"). Strip \r from captured OUT/ERR so
# multi-line stdout comparisons (e.g. `list`) are not host-dependent.
run_ps() {
    local sut="$1"; shift
    OUT=$(pwsh -NoProfile -NonInteractive -File "$sut" "$@" </dev/null 2>"${TMPDIR}/_stderr")
    RC=$?
    OUT="${OUT//$'\r'/}"
    ERR="$(cat "${TMPDIR}/_stderr")"
    ERR="${ERR//$'\r'/}"
}

# ===========================================================================
# Shared fixture: same shape as test-connector-registry.sh's fixture, so
# results are directly comparable to the Bash twin's own suite.
# ===========================================================================
ROOT="${TMPDIR}/connectors"
mkdir -p "${ROOT}/.secrets"

cat > "${ROOT}/github.md" <<'EOF'
---
name: GitHub
connection_type: mcp
endpoint: "npx -y @modelcontextprotocol/server-github"
auth_method: pat
secret_reference: "env:GITHUB_PERSONAL_ACCESS_TOKEN"
preset: github
objective: GitHub issues/PRs/repos via the GitHub MCP server.
summary: Read before connecting to GitHub; wired into installed hosts' MCP config.
tags: [connector, mcp, source-host]
audience: [developer, architect]
---

# GitHub

Human-readable notes: what this connector is for, how an agent reaches it.

---

Body text after a thematic break, deliberately containing a decoy line:
name: this-must-not-be-read-as-frontmatter
EOF

cat > "${ROOT}/local-cli.md" <<'EOF'
---
name: Local CLI
connection_type: cli
endpoint: /usr/local/bin/mytool
auth_method: none
preset: custom
objective: A local CLI tool with no auth.
summary: No auth needed for this one.
tags: [connector, cli]
audience: [developer]
---

# Local CLI
EOF

cat > "${ROOT}/INDEX.md" <<'EOF'
---
source: generated
generator: connectors-index-builder
---

# Connectors Index (fixture stand-in -- must be excluded from `list`)
EOF

echo ".secrets/" > "${ROOT}/.gitignore"
echo "super-secret-value" > "${ROOT}/.secrets/github"
echo "another-secret" > "${ROOT}/.secrets/decoy.md"

# ===========================================================================
# R1-R2: list
# ===========================================================================
run_ps "$REGISTRY_PS" list -Root "$ROOT"
expected=$'github\nlocal-cli'
if [[ "$OUT" == "$expected" && $RC -eq 0 ]]; then
    pass "R1: list returns sorted stems (github, local-cli), excludes INDEX.md/.gitignore/.secrets"
else
    fail "R1: list sorted stems -- got '$OUT' (rc=$RC), expected '$expected'"
fi

run_ps "$REGISTRY_PS" list -Root "${TMPDIR}/does-not-exist"
if [[ -z "$OUT" && $RC -eq 0 ]]; then
    pass "R2: list on non-existent root exits 0 with empty output"
else
    fail "R2: list on non-existent root -- got '$OUT' (rc=$RC), expected empty output, exit 0"
fi

# ===========================================================================
# R3-R5: read happy paths + frontmatter scoping
# ===========================================================================
run_ps "$REGISTRY_PS" read github connection_type -Root "$ROOT"
assert_eq "$OUT" "mcp" "R3: read github connection_type -> mcp"
assert_exit_zero "$RC" "R3b: read scalar field exits 0"

run_ps "$REGISTRY_PS" read github endpoint -Root "$ROOT"
assert_eq "$OUT" "npx -y @modelcontextprotocol/server-github" "R4: read github endpoint -- surrounding quotes stripped"

run_ps "$REGISTRY_PS" read github name -Root "$ROOT"
assert_eq "$OUT" "GitHub" "R5: read is scoped to the first frontmatter block (decoy body line ignored)"

# ===========================================================================
# R6-R9: error paths -- behavior-equal to the Bash twin's exit codes
# ===========================================================================
run_ps "$REGISTRY_PS" read local-cli secret_reference -Root "$ROOT"
assert_exit_eq "$RC" 1 "R6: read missing field (secret_reference absent on auth_method: none) exits 1"

run_ps "$REGISTRY_PS" read no-such-connector name -Root "$ROOT"
assert_exit_eq "$RC" 1 "R7: read missing descriptor exits 1"

run_ps "$REGISTRY_PS" bogus -Root "$ROOT"
assert_exit_eq "$RC" 2 "R8: unknown operation exits 2"

run_ps "$REGISTRY_PS" read github -Root "$ROOT"
assert_exit_eq "$RC" 2 "R9: read with missing <Field> exits 2"

# ===========================================================================
# B1-B2: builder -- em dash mapping + full-field rendering
# ===========================================================================
OUT_B1="${TMPDIR}/INDEX-b1.md"
run_ps "$BUILDER_PS" -Root "$ROOT" -OutputPath "$OUT_B1"
assert_exit_zero "$RC" "B1 setup: builder run over shared fixture exits 0"

data_row_local=$(grep "local-cli.md" "$OUT_B1" || true)
assert_output_contains "$data_row_local" "| none | "$'\xe2\x80\x94'" |" \
    "B1: Secret Ref renders as em dash when auth_method: none"

assert_file_contains "$OUT_B1" "| [GitHub](github.md)" "B2: Connector cell -- linked to github.md"
assert_file_contains "$OUT_B1" "| mcp |" "B2: Type cell -- mcp"
assert_file_contains "$OUT_B1" "npx -y @modelcontextprotocol/server-github" "B2: Endpoint cell -- quotes stripped"
assert_file_contains "$OUT_B1" "| pat |" "B2: Auth cell -- pat"
assert_file_contains "$OUT_B1" "env:GITHUB_PERSONAL_ACCESS_TOKEN" "B2: Secret Ref cell -- quotes stripped"

# ===========================================================================
# B3: determinism -- two PS runs over the same fixture are byte-identical
# ===========================================================================
OUT_B3A="${TMPDIR}/INDEX-b3a.md"
OUT_B3B="${TMPDIR}/INDEX-b3b.md"
run_ps "$BUILDER_PS" -Root "$ROOT" -OutputPath "$OUT_B3A"
run_ps "$BUILDER_PS" -Root "$ROOT" -OutputPath "$OUT_B3B"
sha_b3a=$(sha256sum "$OUT_B3A" | awk '{print $1}')
sha_b3b=$(sha256sum "$OUT_B3B" | awk '{print $1}')
if [[ "$sha_b3a" == "$sha_b3b" ]]; then
    pass "B3: determinism -- two PS runs sha256 identical ($sha_b3a)"
else
    fail "B3: determinism -- sha256 differs: $sha_b3a vs $sha_b3b"
    [[ "$VERBOSE" -eq 1 ]] && diff "$OUT_B3A" "$OUT_B3B"
fi

# ===========================================================================
# B4: header-only empty case (non-existent root)
# ===========================================================================
OUT_B4="${TMPDIR}/INDEX-b4.md"
run_ps "$BUILDER_PS" -Root "${TMPDIR}/does-not-exist" -OutputPath "$OUT_B4"
assert_exit_zero "$RC" "B4: non-existent root exits 0"
assert_file_exists "$OUT_B4" "B4: header-only INDEX.md is written"
assert_file_contains "$OUT_B4" "| Connector | Type | Endpoint | Auth | Secret Ref | Summary |" \
    "B4: header-only INDEX.md carries the table header"
data_rows_b4=$(grep -c '^| \[' "$OUT_B4" || true)
assert_eq "$data_rows_b4" "0" "B4: header-only INDEX.md has zero data rows"

# ===========================================================================
# X1: CROSS-TWIN BYTE-IDENTITY -- .sh builder vs .ps1 builder over the SAME
# fixture root. This is the assertion that locks the generator: field fix
# (delivery-001 gate row #1) permanently.
# ===========================================================================
OUT_SH="${TMPDIR}/INDEX-sh.md"
OUT_PS="${TMPDIR}/INDEX-ps.md"
bash "$BUILDER_SH" --root "$ROOT" --output "$OUT_SH" >/dev/null 2>&1
run_ps "$BUILDER_PS" -Root "$ROOT" -OutputPath "$OUT_PS"

sha_sh=$(sha256sum "$OUT_SH" | awk '{print $1}')
sha_ps=$(sha256sum "$OUT_PS" | awk '{print $1}')
if [[ "$sha_sh" == "$sha_ps" ]]; then
    pass "X1: cross-twin byte-identity -- .sh and .ps1 builders produce identical INDEX.md ($sha_sh)"
else
    fail "X1: cross-twin byte-identity -- .sh sha256 $sha_sh != .ps1 sha256 $sha_ps"
    [[ "$VERBOSE" -eq 1 ]] && diff "$OUT_SH" "$OUT_PS"
fi

test_summary
exit $?
