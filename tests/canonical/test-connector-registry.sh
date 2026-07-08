#!/usr/bin/env bash
# test-connector-registry.sh -- Unit tests for
# canonical/aid/scripts/connectors/connector-registry.sh (task-001,
# work-002-external_sources / feature-001).
#
# Tests cover:
#   T1   list: one line per descriptor stem, sorted
#   T2   list: excludes INDEX.md
#   T3   list: excludes the non-descriptor .gitignore file
#   T4   list: excludes the .secrets/ directory (and its contents)
#   T5   list: exits 0 with empty output when the root does not exist
#   T6   read: happy path -- scalar field
#   T7   read: happy path -- quoted-string field, quotes stripped
#   T8   read: frontmatter-scoped -- a body line that looks like "field: value"
#        (after a body-level thematic-break `---`) is never matched
#   T9   read: missing field -- exits 1 with an stderr diagnostic
#   T10  read: missing descriptor -- exits 1 with an stderr diagnostic
#   T11  unknown operation -- exits 2
#   T12  read with missing <stem>/<field> -- exits 2
#   T13  no operation at all -- exits 2
#   T14  read: secret_reference (auth_method: none) is absent -- exits 1
#
# Usage:
#   bash test-connector-registry.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/aid/scripts/connectors/connector-registry.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

if [[ ! -f "$SUT" ]]; then
    echo "FATAL: SUT not found at $SUT"
    exit 2
fi

echo "== connector-registry.sh tests =="

# ---------------------------------------------------------------------------
# Fixture: a throwaway .aid/connectors/ tree, cleaned up on exit.
# ---------------------------------------------------------------------------
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

CONNECTORS_ROOT="${TMPDIR}/connectors"
mkdir -p "${CONNECTORS_ROOT}/.secrets"

cat > "${CONNECTORS_ROOT}/github.md" <<'EOF'
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

cat > "${CONNECTORS_ROOT}/local-cli.md" <<'EOF'
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

cat > "${CONNECTORS_ROOT}/INDEX.md" <<'EOF'
---
source: generated
generator: connectors-index-builder
---

# Connectors Index (fixture stand-in -- must be excluded from `list`)
EOF

echo ".secrets/" > "${CONNECTORS_ROOT}/.gitignore"
echo "super-secret-value" > "${CONNECTORS_ROOT}/.secrets/github"
echo "another-secret" > "${CONNECTORS_ROOT}/.secrets/decoy.md"

# ---------------------------------------------------------------------------
# T1-T4: list
# ---------------------------------------------------------------------------
out=$(bash "$SUT" list --root "$CONNECTORS_ROOT" 2>&1)
ec=$?
expected=$'github\nlocal-cli'
if [[ "$out" == "$expected" && $ec -eq 0 ]]; then
    pass "T1: list returns sorted stems (github, local-cli)"
else
    fail "T1: list sorted stems -- got '$out' (ec=$ec), expected '$expected'"
fi

if ! echo "$out" | grep -qF "INDEX"; then
    pass "T2: list excludes INDEX.md"
else
    fail "T2: list excludes INDEX.md -- got '$out'"
fi

if ! echo "$out" | grep -qF "gitignore"; then
    pass "T3: list excludes the .gitignore file"
else
    fail "T3: list excludes .gitignore -- got '$out'"
fi

if ! echo "$out" | grep -qF "decoy"; then
    pass "T4: list excludes .secrets/ directory contents"
else
    fail "T4: list excludes .secrets/ contents -- got '$out'"
fi

# ---------------------------------------------------------------------------
# T5: list on a non-existent root -- exits 0, no output
# ---------------------------------------------------------------------------
out=$(bash "$SUT" list --root "${TMPDIR}/does-not-exist" 2>&1)
ec=$?
if [[ -z "$out" && $ec -eq 0 ]]; then
    pass "T5: list on non-existent root exits 0 with empty output"
else
    fail "T5: list on non-existent root -- got '$out' (ec=$ec), expected empty output, exit 0"
fi

# ---------------------------------------------------------------------------
# T6: read happy path -- scalar field
# ---------------------------------------------------------------------------
out=$(bash "$SUT" read github connection_type --root "$CONNECTORS_ROOT" 2>&1)
ec=$?
if [[ "$out" == "mcp" && $ec -eq 0 ]]; then
    pass "T6: read github connection_type -> mcp"
else
    fail "T6: read scalar field -- got '$out' (ec=$ec), expected 'mcp'"
fi

# ---------------------------------------------------------------------------
# T7: read happy path -- quoted-string field, quotes stripped
# ---------------------------------------------------------------------------
out=$(bash "$SUT" read github endpoint --root "$CONNECTORS_ROOT" 2>&1)
ec=$?
if [[ "$out" == "npx -y @modelcontextprotocol/server-github" && $ec -eq 0 ]]; then
    pass "T7: read github endpoint -- surrounding quotes stripped"
else
    fail "T7: read quoted field -- got '$out' (ec=$ec)"
fi

# ---------------------------------------------------------------------------
# T8: frontmatter-scoped -- decoy "name:" line in the body is never read
# ---------------------------------------------------------------------------
out=$(bash "$SUT" read github name --root "$CONNECTORS_ROOT" 2>&1)
ec=$?
if [[ "$out" == "GitHub" && $ec -eq 0 ]]; then
    pass "T8: read is scoped to the first frontmatter block (decoy body line ignored)"
else
    fail "T8: frontmatter scoping -- got '$out' (ec=$ec), expected 'GitHub'"
fi

# ---------------------------------------------------------------------------
# T9: read missing field -- exits 1 with stderr diagnostic
# ---------------------------------------------------------------------------
err=$(bash "$SUT" read local-cli secret_reference --root "$CONNECTORS_ROOT" 2>&1 1>/dev/null)
ec=$?
if [[ $ec -eq 1 ]] && [[ "$err" == *"secret_reference"* ]] && [[ "$err" == *"local-cli"* ]]; then
    pass "T9: read missing field exits 1 with a diagnostic naming the field + descriptor"
else
    fail "T9: missing field -- got '$err' (ec=$ec)"
fi

# ---------------------------------------------------------------------------
# T10: read missing descriptor -- exits 1 with stderr diagnostic
# ---------------------------------------------------------------------------
err=$(bash "$SUT" read no-such-connector name --root "$CONNECTORS_ROOT" 2>&1 1>/dev/null)
ec=$?
if [[ $ec -eq 1 ]] && [[ "$err" == *"no-such-connector"* ]]; then
    pass "T10: read missing descriptor exits 1 with a diagnostic naming the descriptor"
else
    fail "T10: missing descriptor -- got '$err' (ec=$ec)"
fi

# ---------------------------------------------------------------------------
# T11: unknown operation -- exits 2
# ---------------------------------------------------------------------------
out=$(bash "$SUT" bogus --root "$CONNECTORS_ROOT" 2>&1)
ec=$?
if [[ $ec -eq 2 ]]; then
    pass "T11: unknown operation exits 2"
else
    fail "T11: unknown operation -- got ec=$ec, expected 2; out='$out'"
fi

# ---------------------------------------------------------------------------
# T12: read with missing <stem>/<field> -- exits 2
# ---------------------------------------------------------------------------
out=$(bash "$SUT" read github --root "$CONNECTORS_ROOT" 2>&1)
ec=$?
if [[ $ec -eq 2 ]]; then
    pass "T12: read with only <stem> (missing <field>) exits 2"
else
    fail "T12: read missing args -- got ec=$ec, expected 2; out='$out'"
fi

# ---------------------------------------------------------------------------
# T13: no operation at all -- exits 2
# ---------------------------------------------------------------------------
out=$(bash "$SUT" 2>&1)
ec=$?
if [[ $ec -eq 2 ]]; then
    pass "T13: no operation supplied exits 2"
else
    fail "T13: no operation -- got ec=$ec, expected 2; out='$out'"
fi

# ---------------------------------------------------------------------------
# T14: read secret_reference on a none-auth connector (field genuinely absent)
# ---------------------------------------------------------------------------
err=$(bash "$SUT" read local-cli secret_reference --root "$CONNECTORS_ROOT" 2>&1 1>/dev/null)
ec=$?
if [[ $ec -eq 1 ]]; then
    pass "T14: secret_reference absent for auth_method: none connector exits 1"
else
    fail "T14: absent secret_reference -- got ec=$ec, expected 1; err='$err'"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo
test_summary
exit $?
