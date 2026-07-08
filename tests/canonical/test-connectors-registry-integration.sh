#!/usr/bin/env bash
# test-connectors-registry-integration.sh -- delivery-level integration suite
# for work-002-external_sources / delivery-001 (task-012), tying task-001's
# frontmatter accessor (connector-registry.sh) and task-005's INDEX builder
# (build-connectors-index.sh) together over ONE shared fixture.
#
# CRITICAL SCOPE NOTE -- do NOT re-implement unit coverage that already exists:
#   - tests/canonical/test-build-connectors-index.sh (BCI01-BCI15, 42 assertions)
#     already covers the builder in isolation: all 6 columns, em-dash mapping,
#     own frontmatter, non-KB shape, no-timestamp, determinism, header-only
#     empty (both non-existent-root and existing-empty-root), sort order,
#     pipe-escaping, list-style exclusions, malformed descriptors, default
#     args, --help, unknown-flag.
#   - tests/canonical/test-connector-registry.sh (T1-T14, 14 assertions)
#     already covers the accessor in isolation: list exclusions/sorting,
#     read happy paths (scalar + quoted), frontmatter-block scoping, and every
#     non-zero error path (missing field/descriptor/operation/args).
# This suite asserts neither script's behavior against a hardcoded expectation
# again. Its only new value is DELIVERY-LEVEL: does the accessor's view of a
# descriptor set AGREE with the INDEX the builder composed from the SAME
# descriptor set? Two independently-implemented parsers (the accessor's
# read_field awk vs. the builder's ef() awk) could each pass their own unit
# suite while silently disagreeing with each other (e.g. one strips quotes
# the other doesn't) -- that class of bug is invisible to either unit suite
# and is exactly what this suite is for. This is the delivery gate's proof of
# AC-5 "machine-readable registry" (feature-005 SPEC "Acceptance Criteria";
# feature-001 SPEC "Connectors INDEX.md contract"): the registry (INDEX.md +
# descriptors) is self-consistent when read through either surface.
#
# Tests:
#   CRI01  setup -- shared fixture (3 descriptors: mcp/pat, cli/none, api/token)
#          builds cleanly via build-connectors-index.sh
#   CRI02  AGREEMENT -- accessor `list` stems == the connector set (and order)
#          rendered as INDEX.md rows, over the SAME fixture
#   CRI03  AGREEMENT -- per-connector Type cell == accessor `read <stem>
#          connection_type`
#   CRI04  AGREEMENT -- per-connector Endpoint cell == accessor `read <stem>
#          endpoint` (also proves both scripts' quote-stripping agree)
#   CRI05  AGREEMENT -- per-connector Auth cell == accessor `read <stem>
#          auth_method`
#   CRI06  AGREEMENT -- per-connector Secret Ref cell: em dash iff the
#          accessor's `read <stem> secret_reference` reports the field absent
#          (exit 1); otherwise the cell == the accessor's value
#   CRI07  delivery-gate re-assertion (THIN -- see test-build-connectors-index.sh
#          BCI06 for the exhaustive case): regenerating the INDEX from the SAME
#          shared fixture twice is byte-identical (the property feature-006
#          idempotence relies on)
#   CRI08  delivery-gate re-assertion (THIN -- see BCI07/BCI08 for the
#          exhaustive case) PAIRED with the accessor: on an empty root, the
#          builder emits a header-only INDEX.md (zero rows) AND the accessor's
#          `list` on that SAME root reports zero stems -- the zero-connector
#          case agrees across both surfaces too
#
# AC-8 (cross-platform) note: this suite's canonical lane is Bash, matching
# task-005/task-001's own Bash-first unit suites. PowerShell *functional*
# coverage for connector-registry.ps1 / build-connectors-index.ps1, INCLUDING
# the cross-twin byte-identity assertion between the .sh and .ps1 builders,
# lives in tests/canonical/test-connector-twins-ps1-parity.sh (delivery-001
# gate row #2) -- authoring it there rather than here keeps this suite's own
# scope Bash-only/delivery-level, matching task-012's mandate.
#
# Usage:
#   bash tests/canonical/test-connectors-registry-integration.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILDER="${REPO_ROOT}/canonical/aid/scripts/connectors/build-connectors-index.sh"
ACCESSOR="${REPO_ROOT}/canonical/aid/scripts/connectors/connector-registry.sh"

if [[ ! -f "$BUILDER" ]]; then
    fail "CRI00 setup -- build-connectors-index.sh not found at $BUILDER"
    test_summary
    exit 1
fi
if [[ ! -f "$ACCESSOR" ]]; then
    fail "CRI00 setup -- connector-registry.sh not found at $ACCESSOR"
    test_summary
    exit 1
fi

echo "== connectors registry <-> INDEX builder integration tests =="

# ---------------------------------------------------------------------------
# ONE shared fixture, throwaway tmpdir, cleaned up on exit (trap).
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

FIXTURE="${TMPDIR_BASE}/connectors"
mkdir -p "$FIXTURE"

make_doc() {
    local path="$1" content="$2"
    printf '%s\n' "$content" > "$path"
}

# mcp / pat -- quoted endpoint + quoted secret_reference (exercises
# quote-stripping agreement between the two scripts' independent awk parsers).
make_doc "${FIXTURE}/github.md" '---
name: GitHub
connection_type: mcp
endpoint: "npx -y @modelcontextprotocol/server-github"
auth_method: pat
secret_reference: "env:GITHUB_PERSONAL_ACCESS_TOKEN"
preset: github
objective: GitHub issues/PRs/repos via the GitHub MCP server.
summary: Read before connecting to GitHub.
tags: [connector, mcp, source-host]
audience: [developer, architect]
---

# GitHub'

# cli / none -- no secret_reference at all (em-dash / absent-field case).
make_doc "${FIXTURE}/local-cli.md" '---
name: Local CLI
connection_type: cli
endpoint: /usr/local/bin/mytool
auth_method: none
preset: custom
objective: A local CLI tool with no auth.
summary: No auth needed for this one.
---

# Local CLI'

# api / token -- unquoted endpoint, quoted secret_reference (mixed shape).
make_doc "${FIXTURE}/custom-api.md" '---
name: Custom API
connection_type: api
endpoint: https://api.example.com/v1
auth_method: token
secret_reference: "env:CUSTOM_API_TOKEN"
preset: custom
objective: A generic token-authenticated API.
summary: Generic API connector for integration testing.
---

# Custom API'

OUT="${TMPDIR_BASE}/INDEX.md"
bash "$BUILDER" --root "$FIXTURE" --output "$OUT" >/tmp/cri01-out.$$ 2>&1
ec01=$?
rm -f /tmp/cri01-out.$$
assert_exit_zero "$ec01" "CRI01 builder run over the shared 3-descriptor fixture"
assert_file_exists "$OUT" "CRI01 INDEX.md written"

# ---------------------------------------------------------------------------
# get_index_cell FILE STEM COL -- pull one table cell (1-based data column:
# 1=Connector 2=Type 3=Endpoint 4=Auth 5=SecretRef 6=Summary) for STEM's row,
# trimmed of surrounding whitespace.
# ---------------------------------------------------------------------------
get_index_cell() {
    local file="$1" stem="$2" col="$3" awkcol
    awkcol=$((col + 1))
    grep "](${stem}.md)" "$file" | awk -F'|' -v c="$awkcol" '{gsub(/^[ \t]+|[ \t]+$/, "", $c); print $c}'
}

EMDASH=$'\xe2\x80\x94'

# ===========================================================================
# CRI02  AGREEMENT -- accessor `list` stems == INDEX.md connector rows.
# ===========================================================================
list_stems="$(bash "$ACCESSOR" list --root "$FIXTURE")"
index_stems="$(sed -n 's/.*\](\([^)]*\)\.md).*/\1/p' "$OUT")"

assert_eq "$index_stems" "$list_stems" \
    "CRI02 AGREEMENT -- INDEX.md connector set/order equals accessor 'list' over the same fixture"

# ===========================================================================
# CRI03-CRI06  Per-connector field agreement: INDEX.md row vs. accessor `read`.
# ===========================================================================
while IFS= read -r stem; do
    [[ -z "$stem" ]] && continue

    idx_type=$(get_index_cell "$OUT" "$stem" 2)
    idx_endpoint=$(get_index_cell "$OUT" "$stem" 3)
    idx_auth=$(get_index_cell "$OUT" "$stem" 4)
    idx_secref=$(get_index_cell "$OUT" "$stem" 5)

    acc_type=$(bash "$ACCESSOR" read "$stem" connection_type --root "$FIXTURE" 2>/dev/null)
    assert_eq "$idx_type" "$acc_type" \
        "CRI03 AGREEMENT ($stem) -- INDEX Type cell equals accessor read connection_type"

    acc_endpoint=$(bash "$ACCESSOR" read "$stem" endpoint --root "$FIXTURE" 2>/dev/null)
    assert_eq "$idx_endpoint" "$acc_endpoint" \
        "CRI04 AGREEMENT ($stem) -- INDEX Endpoint cell equals accessor read endpoint"

    acc_auth=$(bash "$ACCESSOR" read "$stem" auth_method --root "$FIXTURE" 2>/dev/null)
    assert_eq "$idx_auth" "$acc_auth" \
        "CRI05 AGREEMENT ($stem) -- INDEX Auth cell equals accessor read auth_method"

    if [[ "$acc_auth" == "none" ]]; then
        bash "$ACCESSOR" read "$stem" secret_reference --root "$FIXTURE" >/dev/null 2>&1
        acc_secref_ec=$?
        assert_exit_eq "$acc_secref_ec" 1 \
            "CRI06 AGREEMENT ($stem) -- accessor read secret_reference exits 1 (absent), matching auth_method: none"
        assert_eq "$idx_secref" "$EMDASH" \
            "CRI06 AGREEMENT ($stem) -- INDEX Secret Ref cell is an em dash, matching the accessor's absent field"
    else
        acc_secref=$(bash "$ACCESSOR" read "$stem" secret_reference --root "$FIXTURE" 2>/dev/null)
        assert_eq "$idx_secref" "$acc_secref" \
            "CRI06 AGREEMENT ($stem) -- INDEX Secret Ref cell equals accessor read secret_reference"
    fi
done <<< "$list_stems"

# ===========================================================================
# CRI07  Delivery-gate re-assertion (THIN -- exhaustive case is BCI06):
# regenerating from the SAME shared fixture twice is byte-identical.
# ===========================================================================
OUT_REGEN="${TMPDIR_BASE}/INDEX-regen.md"
bash "$BUILDER" --root "$FIXTURE" --output "$OUT_REGEN" >/dev/null 2>&1
sha_first=$(sha256sum "$OUT" | awk '{print $1}')
sha_regen=$(sha256sum "$OUT_REGEN" | awk '{print $1}')
if [[ "$sha_first" == "$sha_regen" ]]; then
    pass "CRI07 delivery gate -- regenerating the INDEX from the same fixture is byte-identical ($sha_first)"
else
    fail "CRI07 delivery gate -- regeneration differs: $sha_first vs $sha_regen"
    [[ "$VERBOSE" -eq 1 ]] && diff "$OUT" "$OUT_REGEN"
fi

# ===========================================================================
# CRI08  Delivery-gate re-assertion (THIN -- exhaustive case is BCI07/BCI08)
# PAIRED with the accessor: zero descriptors agrees across both surfaces.
# ===========================================================================
EMPTY_ROOT="${TMPDIR_BASE}/empty-connectors"
mkdir -p "$EMPTY_ROOT"
EMPTY_OUT="${TMPDIR_BASE}/INDEX-empty.md"
bash "$BUILDER" --root "$EMPTY_ROOT" --output "$EMPTY_OUT" >/dev/null 2>&1

assert_file_contains "$EMPTY_OUT" "| Connector | Type | Endpoint | Auth | Secret Ref | Summary |" \
    "CRI08 delivery gate -- empty root yields a header-only INDEX.md"
empty_data_rows=$(grep -c '^| \[' "$EMPTY_OUT" || true)
assert_eq "$empty_data_rows" "0" "CRI08 delivery gate -- header-only INDEX.md has zero data rows"

empty_list=$(bash "$ACCESSOR" list --root "$EMPTY_ROOT")
assert_eq "$empty_list" "" \
    "CRI08 AGREEMENT -- accessor 'list' on the SAME empty root also reports zero stems"

# ===========================================================================
test_summary
