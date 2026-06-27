#!/usr/bin/env bash
# test-kb-citation-lint.sh -- unit tests for kb-citation-lint.sh.
#
# Verifies the lint flags VOLATILE bare line-number citations and does NOT flag durable
# anchors / IPs / versions.
#
# Usage: bash tests/canonical/test-kb-citation-lint.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"

LINT="${REPO}/canonical/aid/scripts/kb/kb-citation-lint.sh"

echo "== test-kb-citation-lint.sh =="

[[ -f "$LINT" ]] || { echo "FATAL: lint not found at $LINT" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
KB="${WORK}/knowledge"
mkdir -p "$KB"

# ---------------------------------------------------------------------------
# Doc with a mix of bare citations (should flag) and durable/IP forms (should not).
# ---------------------------------------------------------------------------
cat > "${KB}/sample.md" <<'EOF'
# Sample
Bare single line: see `foo.sh:42` for the loop.
Bare range: see `bar.yml:10-20` for the gate.
Bare list: see `baz.py:3,9,12` here.
Durable symbol: see `qux.md:minimum_grade` here.
Durable digit-word: see `concern-model.md:15-doc seed` here.
IP bind: the server uses `server.mjs:127.0.0.1` to bind.
EOF

out="$(bash "$LINT" --root "$KB" 2>&1)"; rc=$?

assert_eq "$rc" "1" "CL01 exits 1 when violations present"
assert_output_contains "$out" "foo.sh:42"     "CL02 flags bare single line (foo.sh:42)"
assert_output_contains "$out" "bar.yml:10-20" "CL03 flags bare range (bar.yml:10-20)"
assert_output_contains "$out" "baz.py:3,9,12" "CL04 flags bare list (baz.py:3,9,12)"

# Durable / IP forms must NOT appear as findings.
if printf '%s\n' "$out" | grep -q 'minimum_grade'; then
  fail "CL05 must NOT flag durable symbol anchor (qux.md:minimum_grade)"
else
  pass "CL05 durable symbol anchor not flagged"
fi
if printf '%s\n' "$out" | grep -q '15-doc'; then
  fail "CL06 must NOT flag digit-word durable anchor (concern-model.md:15-doc seed)"
else
  pass "CL06 digit-word durable anchor not flagged"
fi
if printf '%s\n' "$out" | grep -q '127\.0\.0\.1'; then
  fail "CL07 must NOT flag IP / version (server.mjs:127.0.0.1)"
else
  pass "CL07 IP / version not flagged"
fi

# ---------------------------------------------------------------------------
# A clean doc exits 0.
# ---------------------------------------------------------------------------
KB2="${WORK}/clean"
mkdir -p "$KB2"
cat > "${KB2}/clean.md" <<'EOF'
# Clean
All anchors are durable: `foo.sh:run_loop`, `bar.yml:on-push-step`, `server.mjs:127.0.0.1`.
EOF
bash "$LINT" --root "$KB2" >/dev/null 2>&1
assert_eq "$?" "0" "CL08 exits 0 on a clean doc-set"

echo
test_summary
exit $?
