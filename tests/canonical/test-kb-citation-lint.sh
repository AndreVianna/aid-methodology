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

# ===========================================================================
# CL09  Depth. The default is 1 and must stay 1, because the KB's own shape is
#       flat and changing it would silently rescope every existing caller.
#
#       These assert the OPENED COUNT, not the verdict. A depth-1 scan of a
#       nested tree returns exit 0 having opened almost nothing, and that
#       verdict is byte-identical to a genuinely clean run -- so a suite that
#       checked only the verdict would pass against the bug.
# ===========================================================================
NEST="$(mktemp -d)"
mkdir -p "${NEST}/root/features/feature-001"

cat > "${NEST}/root/TOP.md" <<'EOF'
A top-level doc with a durable anchor: `foo.sh:run_loop`.
EOF
cat > "${NEST}/root/features/feature-001/SPEC.md" <<'EOF'
A nested doc with a BARE citation: see handler.py:88 for the branch.
EOF

opened_1="$(bash "$LINT" --root "${NEST}/root" 2>&1 >/dev/null | grep -oE 'opened [0-9]+' | grep -oE '[0-9]+')"
bash "$LINT" --root "${NEST}/root" >/dev/null 2>&1
code_1=$?

opened_all="$(bash "$LINT" --root "${NEST}/root" --depth all 2>&1 >/dev/null | grep -oE 'opened [0-9]+' | grep -oE '[0-9]+')"
bash "$LINT" --root "${NEST}/root" --depth all >/dev/null 2>&1
code_all=$?

assert_eq "$opened_1"   "1" "CL09 default depth opens only the top level (1 file)"
assert_eq "$code_1"     "0" "CL09 ...and returns a CLEAN verdict while the nested violation stands"
assert_eq "$opened_all" "2" "CL09 --depth all opens the nested doc too (2 files)"
assert_eq "$code_all"   "1" "CL09 ...and finds the violation depth-1 missed"

assert_eq "$(bash "$LINT" --root "${NEST}/root" --recursive 2>&1 >/dev/null | grep -oE 'opened [0-9]+' | grep -oE '[0-9]+')" \
          "2" "CL09 --recursive is an alias for --depth all"

bash "$LINT" --root "${NEST}/root" --depth 0 >/dev/null 2>&1
assert_eq "$?" "2" "CL09 --depth 0 is an invocation error, not a silent no-op"
bash "$LINT" --root "${NEST}/root" --depth banana >/dev/null 2>&1
assert_eq "$?" "2" "CL09 --depth banana is an invocation error"

# ===========================================================================
# CL10  A reviewer ledger's `Line` column is not a citation.
#
#       The 7-column ledger puts the line number in its own cell, so it never
#       forms a `file.ext:LINE` token. Flagging it would make the lint
#       unusable against exactly the artifacts reviews produce.
# ===========================================================================
LEDG="$(mktemp -d)"
mkdir -p "${LEDG}/root"
cat > "${LEDG}/root/FINDINGS.md" <<'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [HIGH] | Pending | handler.py | 88 | branch is unreachable | proven by the suite |
EOF

bash "$LINT" --root "${LEDG}/root" --depth all >/dev/null 2>&1
assert_eq "$?" "0" "CL10 a ledger Line cell is not treated as a bare citation"

rm -rf "$NEST" "$LEDG"

echo
test_summary
exit $?
