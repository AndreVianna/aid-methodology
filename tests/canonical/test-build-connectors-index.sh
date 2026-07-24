#!/usr/bin/env bash
# test-build-connectors-index.sh -- canonical suite for
# canonical/aid/scripts/connectors/build-connectors-index.sh (task-005,
# work-002-external_sources / feature-005, realizing feature-001's frozen
# INDEX.md contract).
#
# Tests:
#   BCI01  Full-field descriptor renders all 6 table cells populated;
#          Connector cell links to `<stem>.md`; quoted endpoint/secret_reference
#          render with surrounding quotes stripped.
#   BCI02  auth_method: none -> Secret Ref cell renders as an em dash.
#   BCI03  Own generated frontmatter: source: generated / generator: /
#          intent: / contracts: all present.
#   BCI04  NOT a KB doc -- no kb-category:, no Primary/Meta/Extension grouping
#          headers, no ../knowledge/ cross-links anywhere in the output.
#   BCI05  No run timestamp / no dated field anywhere in the output (KI-010).
#   BCI06  DETERMINISM -- two runs over an identical descriptor set produce a
#          byte-identical INDEX.md (sha256 compare).
#   BCI07  Zero descriptors (non-existent --root) -> header-only INDEX.md is
#          WRITTEN (not deleted, not a hard failure); zero data rows.
#   BCI08  Zero descriptors (existing, empty --root dir) produces a
#          byte-identical header-only INDEX.md to the non-existent-root case.
#   BCI09  Multiple descriptors sorted by filename stem in the output.
#   BCI10  A literal `|` in a descriptor field is escaped to `\|` in the cell.
#   BCI11  `list`-style exclusions: an existing INDEX.md / .gitignore under
#          --root are never rendered as descriptor rows.
#   BCI12  Malformed descriptor (missing optional fields) still renders a
#          well-formed 6-column row without failing the build.
#   BCI13  Default --root/--output apply when the flags are omitted (exercised
#          against a throwaway fixture cwd, never the repo's real
#          .aid/connectors/).
#   BCI14  -h/--help exits 0 and prints usage.
#   BCI15  Unknown flag exits 1 (argument error).
#
# Usage:
#   bash tests/canonical/test-build-connectors-index.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/canonical/aid/scripts/connectors/build-connectors-index.sh"

if [[ ! -f "$SCRIPT" ]]; then
    fail "BCI00 setup -- build-connectors-index.sh not found at $SCRIPT"
    test_summary
    exit 1
fi

echo "== build-connectors-index.sh tests =="

# ---------------------------------------------------------------------------
# Fixture root: throwaway tmpdir, cleaned up on exit. NEVER the repo's real
# .aid/connectors/.
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

make_doc() {
    local path="$1" content="$2"
    mkdir -p "$(dirname "$path")"
    printf '%s\n' "$content" > "$path"
}

run_builder() {
    local root="$1" out_file="$2"
    bash "$SCRIPT" --root "$root" --output "$out_file" >/dev/null 2>&1
}

# ===========================================================================
# BCI01  Full-field descriptor: all 6 cells populated; link + quote-stripping.
# ===========================================================================
FIX01="${TMPDIR_BASE}/fix01"
mkdir -p "$FIX01"
make_doc "${FIX01}/github.md" '---
name: GitHub
connection_type: mcp
endpoint: "npx -y @modelcontextprotocol/server-github"
auth_method: pat
secret_reference: "env:GITHUB_PERSONAL_ACCESS_TOKEN"
preset: github
objective: GitHub issues/PRs/repos via the GitHub MCP server.
summary: Read before connecting to GitHub; wired into installed hosts MCP config.
tags: [connector, mcp, source-host]
audience: [developer, architect]
---

# GitHub

Human-readable notes.'

OUT01="${TMPDIR_BASE}/INDEX01.md"
run_builder "$FIX01" "$OUT01"

assert_file_contains "$OUT01" "| [GitHub](github.md)" "BCI01 Connector cell -- linked to github.md"
assert_file_contains "$OUT01" "| mcp |" "BCI01 Type cell -- mcp"
assert_file_contains "$OUT01" "npx -y @modelcontextprotocol/server-github" "BCI01 Endpoint cell -- quotes stripped"
assert_file_not_contains "$OUT01" '"npx -y' "BCI01 Endpoint cell -- no leftover leading quote"
assert_file_contains "$OUT01" "| pat |" "BCI01 Auth cell -- pat"
assert_file_contains "$OUT01" "env:GITHUB_PERSONAL_ACCESS_TOKEN" "BCI01 Secret Ref cell -- quotes stripped"
assert_file_contains "$OUT01" "Read before connecting to GitHub" "BCI01 Summary cell -- populated"
assert_file_contains "$OUT01" "| Connector | Type | Endpoint | Auth | Secret Ref | Summary |" \
    "BCI01 table header row present"
assert_file_contains "$OUT01" "|-----------|------|----------|------|------------|---------|" \
    "BCI01 table separator row present"

# ===========================================================================
# BCI02  auth_method: none -> Secret Ref renders as an em dash.
# ===========================================================================
FIX02="${TMPDIR_BASE}/fix02"
mkdir -p "$FIX02"
make_doc "${FIX02}/local-cli.md" '---
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

# Local CLI'

OUT02="${TMPDIR_BASE}/INDEX02.md"
run_builder "$FIX02" "$OUT02"

data_row_02=$(grep "local-cli.md" "$OUT02" || true)
assert_output_contains "$data_row_02" "| none | "$'\xe2\x80\x94'" |" \
    "BCI02 Secret Ref renders as em dash when auth_method: none"

# ===========================================================================
# BCI03  Own generated frontmatter present.
# ===========================================================================
assert_file_contains "$OUT01" "source: generated" "BCI03 frontmatter -- source: generated"
assert_file_contains "$OUT01" "generator: build-connectors-index" "BCI03 frontmatter -- generator:"
assert_file_contains "$OUT01" "intent: |" "BCI03 frontmatter -- intent: literal block"
assert_file_contains "$OUT01" 'contracts:' "BCI03 frontmatter -- contracts: key present"
assert_file_contains "$OUT01" '"One row per connector descriptor under .aid/connectors/"' \
    "BCI03 frontmatter -- contracts: entry text"

# ===========================================================================
# BCI04  NOT a KB doc -- no kb-category:, no grouping headers, no KB links.
# ===========================================================================
assert_file_not_contains "$OUT01" "kb-category:" "BCI04 no kb-category: field"
assert_file_not_contains "$OUT01" "## Primary" "BCI04 no Primary grouping header"
assert_file_not_contains "$OUT01" "## Meta" "BCI04 no Meta grouping header"
assert_file_not_contains "$OUT01" "## Extension" "BCI04 no Extension grouping header"
assert_file_not_contains "$OUT01" "../knowledge/" "BCI04 no ../knowledge/ cross-links"

# ===========================================================================
# BCI05  No run timestamp / dated field anywhere (KI-010).
# ===========================================================================
assert_file_not_contains "$OUT01" "AUTO-GENERATED" "BCI05 no AUTO-GENERATED timestamp comment"
assert_file_not_contains "$OUT01" "Generated at:" "BCI05 no 'Generated at:' line"
assert_file_not_contains "$OUT01" "changelog:" "BCI05 no changelog: field (would carry a date)"
if grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$OUT01"; then
    fail "BCI05 no ISO date anywhere in output -- found one"
else
    pass "BCI05 no ISO date anywhere in output"
fi

# ===========================================================================
# BCI06  DETERMINISM -- two runs over an identical descriptor set are
#        byte-identical.
# ===========================================================================
OUT06A="${TMPDIR_BASE}/INDEX06a.md"
OUT06B="${TMPDIR_BASE}/INDEX06b.md"
run_builder "$FIX01" "$OUT06A"
run_builder "$FIX01" "$OUT06B"

sha_a=$(sha256sum "$OUT06A" | awk '{print $1}')
sha_b=$(sha256sum "$OUT06B" | awk '{print $1}')
if [[ "$sha_a" == "$sha_b" ]]; then
    pass "BCI06 determinism -- sha256 identical across two runs ($sha_a)"
else
    fail "BCI06 determinism -- sha256 differs: $sha_a vs $sha_b"
    [[ "$VERBOSE" -eq 1 ]] && diff "$OUT06A" "$OUT06B"
fi

# ===========================================================================
# BCI07  Zero descriptors (non-existent --root) -> header-only INDEX.md is
#        written, not a deletion, not a hard failure.
# ===========================================================================
OUT07="${TMPDIR_BASE}/INDEX07.md"
bash "$SCRIPT" --root "${TMPDIR_BASE}/does-not-exist" --output "$OUT07" >${TMPDIR_BASE}/bci07-out.$$ 2>&1
ec07=$?
assert_exit_zero "$ec07" "BCI07 non-existent root exits 0"
assert_file_exists "$OUT07" "BCI07 header-only INDEX.md is written (never deleted)"
assert_file_contains "$OUT07" "| Connector | Type | Endpoint | Auth | Secret Ref | Summary |" \
    "BCI07 header-only INDEX.md carries the table header"
data_rows_07=$(grep -c '^| \[' "$OUT07" || true)
assert_eq "$data_rows_07" "0" "BCI07 header-only INDEX.md has zero data rows"
rm -f ${TMPDIR_BASE}/bci07-out.$$

# ===========================================================================
# BCI08  Zero descriptors (existing, empty --root) -- byte-identical to BCI07.
# ===========================================================================
EMPTY_ROOT="${TMPDIR_BASE}/empty-connectors"
mkdir -p "$EMPTY_ROOT"
OUT08="${TMPDIR_BASE}/INDEX08.md"
run_builder "$EMPTY_ROOT" "$OUT08"

sha_07=$(sha256sum "$OUT07" | awk '{print $1}')
sha_08=$(sha256sum "$OUT08" | awk '{print $1}')
assert_eq "$sha_08" "$sha_07" "BCI08 empty-existing-root output byte-identical to non-existent-root output"

# ===========================================================================
# BCI09  Multiple descriptors sorted by filename stem.
# ===========================================================================
FIX09="${TMPDIR_BASE}/fix09"
mkdir -p "$FIX09"
make_doc "${FIX09}/zebra.md" '---
name: Zebra
connection_type: cli
endpoint: /bin/zebra
auth_method: none
summary: Z comes last.
---
body'
make_doc "${FIX09}/alpha.md" '---
name: Alpha
connection_type: cli
endpoint: /bin/alpha
auth_method: none
summary: A comes first.
---
body'
make_doc "${FIX09}/mango.md" '---
name: Mango
connection_type: cli
endpoint: /bin/mango
auth_method: none
summary: M comes middle.
---
body'

OUT09="${TMPDIR_BASE}/INDEX09.md"
run_builder "$FIX09" "$OUT09"

alpha_line=$(grep -n "alpha.md" "$OUT09" | head -1 | cut -d: -f1)
mango_line=$(grep -n "mango.md" "$OUT09" | head -1 | cut -d: -f1)
zebra_line=$(grep -n "zebra.md" "$OUT09" | head -1 | cut -d: -f1)
if [[ -n "$alpha_line" && -n "$mango_line" && -n "$zebra_line" && \
      "$alpha_line" -lt "$mango_line" && "$mango_line" -lt "$zebra_line" ]]; then
    pass "BCI09 sorted by stem -- alpha < mango < zebra"
else
    fail "BCI09 sorted by stem -- expected alpha($alpha_line) < mango($mango_line) < zebra($zebra_line)"
fi

# ===========================================================================
# BCI10  Literal `|` in a field is escaped to `\|`.
# ===========================================================================
FIX10="${TMPDIR_BASE}/fix10"
mkdir -p "$FIX10"
make_doc "${FIX10}/pipedoc.md" '---
name: Pipe Doc
connection_type: cli
endpoint: /bin/tool
auth_method: none
summary: Routes between A | B based on context.
---
body'

OUT10="${TMPDIR_BASE}/INDEX10.md"
run_builder "$FIX10" "$OUT10"

assert_file_contains "$OUT10" 'A \| B' "BCI10 pipe in summary escaped to \\|"

# ===========================================================================
# BCI11  list-style exclusions: existing INDEX.md / .gitignore under --root
#        are never rendered as descriptor rows.
# ===========================================================================
FIX11="${TMPDIR_BASE}/fix11"
mkdir -p "${FIX11}/.secrets"
make_doc "${FIX11}/github.md" '---
name: GitHub
connection_type: mcp
endpoint: gh
auth_method: none
summary: A connector.
---
body'
cat > "${FIX11}/INDEX.md" <<'EOF'
---
source: generated
generator: connectors-index-builder-stand-in
---
# Stale Index (fixture stand-in -- must be excluded from rebuild input)
EOF
echo ".secrets/" > "${FIX11}/.gitignore"
echo "super-secret" > "${FIX11}/.secrets/github"

OUT11="${TMPDIR_BASE}/INDEX11.md"
run_builder "$FIX11" "$OUT11"

data_rows_11=$(grep -c '^| \[' "$OUT11" || true)
assert_eq "$data_rows_11" "1" "BCI11 exactly one descriptor row rendered (INDEX.md/.gitignore/.secrets excluded)"
assert_file_not_contains "$OUT11" "Stale Index" "BCI11 stale INDEX.md content never leaks into rebuild"

# ===========================================================================
# BCI12  Malformed descriptor (missing optional fields) still renders a
#        well-formed 6-column row without failing the build.
# ===========================================================================
FIX12="${TMPDIR_BASE}/fix12"
mkdir -p "$FIX12"
make_doc "${FIX12}/bare.md" '---
connection_type: api
auth_method: token
secret_reference: "env:BARE_TOKEN"
---
body'

OUT12="${TMPDIR_BASE}/INDEX12.md"
bash "$SCRIPT" --root "$FIX12" --output "$OUT12" >${TMPDIR_BASE}/bci12-out.$$ 2>&1
ec12=$?
assert_exit_zero "$ec12" "BCI12 malformed descriptor (missing name/summary) does not fail the build"
assert_file_contains "$OUT12" "[bare](bare.md)" "BCI12 missing name: falls back to the filename stem"
rm -f ${TMPDIR_BASE}/bci12-out.$$

# ===========================================================================
# BCI13  Default --root/--output apply when flags are omitted (fixture cwd
#        only -- never the repo's real .aid/connectors/).
# ===========================================================================
FIX13_HOME="${TMPDIR_BASE}/fix13-home"
mkdir -p "${FIX13_HOME}/.aid/connectors"
make_doc "${FIX13_HOME}/.aid/connectors/onlyone.md" '---
name: Only One
connection_type: cli
endpoint: /bin/only
auth_method: none
summary: The only connector.
---
body'

( cd "$FIX13_HOME" && bash "$SCRIPT" >${TMPDIR_BASE}/bci13-out.$$ 2>&1 )
ec13=$?
assert_exit_zero "$ec13" "BCI13 default args -- exits 0"
assert_file_exists "${FIX13_HOME}/.aid/connectors/INDEX.md" "BCI13 default output path used (.aid/connectors/INDEX.md)"
assert_file_contains "${FIX13_HOME}/.aid/connectors/INDEX.md" "[Only One](onlyone.md)" \
    "BCI13 default root path used (.aid/connectors)"
rm -f ${TMPDIR_BASE}/bci13-out.$$

# ===========================================================================
# BCI14  -h/--help exits 0 and prints usage.
# ===========================================================================
help_out=$(bash "$SCRIPT" --help 2>&1)
ec14=$?
assert_exit_zero "$ec14" "BCI14 --help exits 0"
assert_output_contains "$help_out" "Usage:" "BCI14 --help prints a Usage section"

# ===========================================================================
# BCI15  Unknown flag exits 1 (argument error).
# ===========================================================================
bash "$SCRIPT" --bogus-flag >${TMPDIR_BASE}/bci15-out.$$ 2>&1
ec15=$?
assert_exit_eq "$ec15" "1" "BCI15 unknown flag exits 1"
rm -f ${TMPDIR_BASE}/bci15-out.$$

# ===========================================================================
test_summary
