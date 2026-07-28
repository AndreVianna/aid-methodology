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
# Profiles, en-dash ranges, resolution and range checking (work-003 delivery-002).
# ===========================================================================

# --- en-dash regression guard ------------------------------------------------
# The linespec class originally allowed only an ASCII hyphen. Every range citation in a work
# artifact uses an EN-DASH (U+2013), so all of them were silently truncated to their first
# number: harmless for a ban, fatal for a range check. CL09/CL10 are that guard.
ED="${WORK}/endash"; mkdir -p "$ED"
printf 'a\nb\nc\nd\ne\n' > "${ED}/short.md"                      # 5 lines
printf 'see `short.md:2\xe2\x80\x934` in range\n' > "${ED}/ok.md"
out="$(bash "$LINT" --root "$ED" 2>&1)"
assert_output_contains "$out" "short.md:2" "CL09 durable flags an en-dash range citation"
# The needle must be built with printf: inside single quotes grep sees a literal backslash-x
# sequence, not the en-dash bytes, so the naive form always fails.
ENDASH_RANGE="$(printf '2\xe2\x80\x934')"
if printf '%s\n' "$out" | grep -qF "$ENDASH_RANGE"; then
  pass "CL10 en-dash range is captured whole (not truncated to its first number)"
else
  fail "CL10 en-dash range truncated -- the tokenizer regression is back"
fi

# --- mode separation --------------------------------------------------------
# Same fixture, opposite verdicts: durable bans the form, resolvable only requires it to resolve.
bash "$LINT" --root "$ED" --profile durable >/dev/null 2>&1
assert_eq "$?" "1" "CL11 durable exits 1 on a resolvable in-range citation"
bash "$LINT" --root "$ED" --profile resolvable --search-root "$ED" >/dev/null 2>&1
assert_eq "$?" "0" "CL12 resolvable exits 0 on the same citation"

# --- OUT-OF-RANGE, via an en-dash range -------------------------------------
rm -f "${ED}/ok.md"
printf 'see `short.md:2\xe2\x80\x9399` out of range\n' > "${ED}/bad.md"
out="$(bash "$LINT" --root "$ED" --profile resolvable --search-root "$ED" 2>&1)"; rc=$?
assert_eq "$rc" "1" "CL13 resolvable exits 1 when a cited line exceeds the file length"
assert_output_contains "$out" "OUT-OF-RANGE" "CL14 reports OUT-OF-RANGE"
assert_output_contains "$out" "5 lines"      "CL15 names the actual line count"

# --- UNRESOLVED -------------------------------------------------------------
UN="${WORK}/unres"; mkdir -p "$UN"
printf 'see `nope-does-not-exist.md:7` here\n' > "${UN}/a.md"
out="$(bash "$LINT" --root "$UN" --profile resolvable --search-root "$UN" 2>&1)"; rc=$?
assert_eq "$rc" "1" "CL16 resolvable exits 1 on an unresolvable path"
assert_output_contains "$out" "UNRESOLVED" "CL17 reports UNRESOLVED"

# --- AMBIGUOUS, with the candidate count ------------------------------------
AM="${WORK}/ambig"; mkdir -p "${AM}/x" "${AM}/y" "${AM}/scan"
printf 'one\n' > "${AM}/x/dup.md"
printf 'one\n' > "${AM}/y/dup.md"
printf 'see `dup.md:1` here\n' > "${AM}/scan/a.md"
out="$(bash "$LINT" --root "${AM}/scan" --profile resolvable --search-root "$AM" 2>&1)"; rc=$?
assert_eq "$rc" "1" "CL18 resolvable exits 1 when a basename matches more than one file"
assert_output_contains "$out" "AMBIGUOUS"     "CL19 reports AMBIGUOUS"
assert_output_contains "$out" "2 candidates"  "CL20 states the candidate count"

# --- exemptions hold under BOTH profiles ------------------------------------
# The three durable-anchor exemptions are the hard-won part of this lint; reusing them across a
# second profile is unverified unless asserted per form.
EX="${WORK}/exempt"; mkdir -p "$EX"
cat > "${EX}/e.md" <<'EOF'
Durable: `qux.md:minimum_grade`, `concern-model.md:15-doc seed`, `server.mjs:127.0.0.1`.
EOF
bash "$LINT" --root "$EX" --profile durable >/dev/null 2>&1
assert_eq "$?" "0" "CL21 exemptions silent under durable"
bash "$LINT" --root "$EX" --profile resolvable --search-root "$EX" >/dev/null 2>&1
assert_eq "$?" "0" "CL22 exemptions silent under resolvable"

# --- fenced code blocks are skipped -----------------------------------------
# A citation inside a fence is an example or a test fixture, not a claim about the tree.
FC="${WORK}/fence"; mkdir -p "$FC"
printf '# Doc\n\n```bash\ngrep nope.md:999 fixture\n```\n\nprose has none.\n' > "${FC}/f.md"
bash "$LINT" --root "$FC" >/dev/null 2>&1
assert_eq "$?" "0" "CL23 citations inside fenced code blocks are not flagged"

# --- --depth reaches nested artifacts ---------------------------------------
# Work artifacts sit 2-4 levels below the work root; the default depth of 1 must not change.
DP="${WORK}/depth"; mkdir -p "${DP}/a/b"
printf 'see `deep.md:3` here\n' > "${DP}/a/b/nested.md"
bash "$LINT" --root "$DP" >/dev/null 2>&1
assert_eq "$?" "0" "CL24 default depth 1 does not reach a nested doc"
bash "$LINT" --root "$DP" --depth 4 >/dev/null 2>&1
assert_eq "$?" "1" "CL25 --depth 4 reaches the nested doc"

# --- argument validation ----------------------------------------------------
bash "$LINT" --root "$KB2" --profile bogus >/dev/null 2>&1
assert_eq "$?" "2" "CL26 an unknown --profile exits 2 (usage)"
bash "$LINT" --root "$KB2" --depth x >/dev/null 2>&1
assert_eq "$?" "2" "CL27 a non-numeric --depth exits 2 (usage)"

echo
test_summary
exit $?
