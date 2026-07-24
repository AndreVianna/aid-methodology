#!/usr/bin/env bash
# test-coverage-parity.sh -- self-test for the coverage-parity gate tool
# (tests/coverage-parity.sh), work-024 feature-001. IDs CPG01-CPG11.
#
# Drives tests/coverage-parity.sh against SYNTHETIC fixtures this suite builds
# itself in a `mktemp -d` scratch dir -- hermetic, with NO dependence on the real
# canonical corpus or any work folder ("tests build their own fixtures").
#
# The diff-logic scenarios (CPG02-06, CPG10, CPG11) feed the tool hand-built
# baseline/after inventory files via `diff --after`, so they exercise the diff
# engine in isolation without running any suite. The collect/normalization
# scenarios (CPG01, CPG07, CPG08) build tiny synthetic `test-*.sh` suites that
# emit assert.sh-style PASS lines and run them through `collect`. CPG09 forces a
# required runtime absent by invoking the tool under an empty PATH.
#
# This is a net-new glob-discovered suite (+1 to the live canonical count); its
# CPG0x keys are net-added relative to the master baseline (which was captured
# before this file existed, per task-002 ordering).
#
# Usage:
#   bash tests/canonical/test-coverage-parity.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUT="${REPO_ROOT}/tests/coverage-parity.sh"
ASSERT_SH="${REPO_ROOT}/tests/lib/assert.sh"
TAB=$'\t'

if [[ ! -f "$SUT" ]]; then
    echo "  FAIL: coverage-parity.sh not found at $SUT"
    exit 1
fi

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

echo "=== coverage-parity self-test (CPG01-11) ==="

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

# mk_suite DIR NAME  -- write a synthetic canonical suite; body (a sequence of
# `pass "<label>"` lines) is read from stdin. The suite sources the real
# assert.sh and honors --verbose, exactly like a real suite, so `collect` sees
# genuine `  PASS: <label>` lines.
mk_suite() {
    local dir="$1" name="$2"
    mkdir -p "$dir"
    {
        echo '#!/usr/bin/env bash'
        echo 'set -uo pipefail'
        echo 'VERBOSE=0'
        echo '[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1'
        printf 'source "%s"\n' "$ASSERT_SH"
        cat
        echo 'test_summary'
    } > "${dir}/${name}"
}

# write_tsv FILE  -- write a TSV file; stdin lines use '|' as the field
# separator (converted to a real TAB). Keys/justifications here contain no '|'.
write_tsv() {
    local file="$1"
    sed "s/|/${TAB}/g" > "$file"
}

# run_diff ...  -- run `coverage-parity.sh diff` capturing combined output + rc.
DOUT=""; DRC=0
run_diff() {
    DOUT="$(bash "$SUT" diff "$@" 2>&1)"
    DRC=$?
}

# run_collect ...  -- run `coverage-parity.sh collect` capturing rc.
CRC=0
run_collect() {
    bash "$SUT" collect "$@" >/dev/null 2>&1
    CRC=$?
}

# =====================================================================
# CPG01 -- collect over a 2-suite synthetic dir, run twice -> byte-identical.
# =====================================================================
D01="${SCRATCH}/cpg01"
mk_suite "$D01" test-alpha.sh <<'EOF'
pass "CLI027-A01 alpha one"
pass "CLI027-A02 alpha two"
EOF
mk_suite "$D01" test-beta.sh <<'EOF'
pass "DC01 beta one"
pass "DC02 beta two"
EOF
run_collect --out "${SCRATCH}/c1.tsv" --dir "$D01" --allow-missing-runtime
run_collect --out "${SCRATCH}/c2.tsv" --dir "$D01" --allow-missing-runtime
if cmp -s "${SCRATCH}/c1.tsv" "${SCRATCH}/c2.tsv"; then
    pass "CPG01 collect over a 2-suite dir is byte-identical run-to-run (determinism)"
else
    fail "CPG01 collect not byte-identical across two runs"
    [[ "$VERBOSE" -eq 1 ]] && { echo "--- run1 ---"; cat "${SCRATCH}/c1.tsv"; echo "--- run2 ---"; cat "${SCRATCH}/c2.tsv"; }
fi
assert_line_count "${SCRATCH}/c1.tsv" 4 "CPG01 inventory has one row per distinct (suite,key) (4 rows)"

# =====================================================================
# CPG02 -- diff identical baseline == after -> exit 0 (no net-removed).
# =====================================================================
write_tsv "${SCRATCH}/base.tsv" <<'EOF'
test-x.sh|AAA01|1
test-x.sh|BBB01|1
EOF
run_diff --baseline "${SCRATCH}/base.tsv" --after "${SCRATCH}/base.tsv"
assert_exit_eq "$DRC" 0 "CPG02 diff of identical baseline==after"
assert_output_contains "$DOUT" "RESULT: PASS" "CPG02 reports PASS (no net-removed)"

# =====================================================================
# CPG03 -- one assertion removed, no allowlist rule -> exit 1, names (suite,key).
# =====================================================================
write_tsv "${SCRATCH}/after03.tsv" <<'EOF'
test-x.sh|AAA01|1
EOF
run_diff --baseline "${SCRATCH}/base.tsv" --after "${SCRATCH}/after03.tsv"
assert_exit_eq "$DRC" 1 "CPG03 un-excused removal exits 1"
assert_output_contains "$DOUT" "test-x.sh" "CPG03 report names the removed suite"
assert_output_contains "$DOUT" "BBB01" "CPG03 report names the removed key"

# =====================================================================
# CPG04 -- removed WITH an allowlist re-home whose target is present -> exit 0.
# =====================================================================
write_tsv "${SCRATCH}/allow04.tsv" <<'EOF'
test-x.sh|BBB01|test-y.sh|YYY01|relocated to peer suite
EOF
write_tsv "${SCRATCH}/after04.tsv" <<'EOF'
test-x.sh|AAA01|1
test-y.sh|YYY01|1
EOF
run_diff --baseline "${SCRATCH}/base.tsv" --after "${SCRATCH}/after04.tsv" --allow "${SCRATCH}/allow04.tsv"
assert_exit_eq "$DRC" 0 "CPG04 removal excused by a re-home whose target is present in after"
assert_output_contains "$DOUT" "RE-HOME" "CPG04 report marks the excused re-home"

# =====================================================================
# CPG05 -- allowlist re-home whose target is ABSENT from after -> exit 1.
# =====================================================================
run_diff --baseline "${SCRATCH}/base.tsv" --after "${SCRATCH}/after03.tsv" --allow "${SCRATCH}/allow04.tsv"
assert_exit_eq "$DRC" 1 "CPG05 re-home whose target is absent from after exits 1"
assert_output_contains "$DOUT" "claimed but not landed" "CPG05 report says the re-home is claimed but not landed"

# =====================================================================
# CPG06 -- net-ADDED assertions only -> exit 0, added reported as INFO.
# =====================================================================
write_tsv "${SCRATCH}/after06.tsv" <<'EOF'
test-x.sh|AAA01|1
test-x.sh|BBB01|1
test-x.sh|NEW01|1
EOF
run_diff --baseline "${SCRATCH}/base.tsv" --after "${SCRATCH}/after06.tsv"
assert_exit_eq "$DRC" 0 "CPG06 net-added assertions only -> exit 0"
assert_output_contains "$DOUT" "INFO" "CPG06 added assertions reported as INFO"
assert_output_contains "$DOUT" "NEW01" "CPG06 report names the added key"

# =====================================================================
# CPG07 -- free-form label with a volatile temp path / version normalizes to
# the SAME key across two independent logs.
# =====================================================================
D07a="${SCRATCH}/cpg07a"
D07b="${SCRATCH}/cpg07b"
mk_suite "$D07a" test-vol.sh <<'EOF'
pass "verified output at /tmp/aid.AAAA/run-1 version v1.2.3 ok"
EOF
mk_suite "$D07b" test-vol.sh <<'EOF'
pass "verified output at /tmp/aid.ZZZZ/run-9 version v9.8.7 ok"
EOF
run_collect --out "${SCRATCH}/v7a.tsv" --dir "$D07a" --allow-missing-runtime
run_collect --out "${SCRATCH}/v7b.tsv" --dir "$D07b" --allow-missing-runtime
if cmp -s "${SCRATCH}/v7a.tsv" "${SCRATCH}/v7b.tsv"; then
    pass "CPG07 volatile temp-path/version free-form label normalizes to one stable key across two logs"
else
    fail "CPG07 volatile free-form label produced different keys"
    [[ "$VERBOSE" -eq 1 ]] && { echo "--- log a ---"; cat "${SCRATCH}/v7a.tsv"; echo "--- log b ---"; cat "${SCRATCH}/v7b.tsv"; }
fi

# =====================================================================
# CPG08 -- ID-prefixed vs free-form: the [SKIPPED: ...] shim collapses to the ID
# key, and a single-letter-prefix label (T07) takes the free-form path.
# =====================================================================
D08="${SCRATCH}/cpg08"
mk_suite "$D08" test-mix.sh <<'EOF'
pass "PAR023-M13 pwsh path check"
pass "PAR023-M13 pwsh path check [SKIPPED: pwsh absent]"
pass "T07 build output check"
EOF
run_collect --out "${SCRATCH}/o8.tsv" --dir "$D08" --allow-missing-runtime
par_count="$(awk -F'\t' '$1=="test-mix.sh" && $2=="PAR023-M13"{print $3}' "${SCRATCH}/o8.tsv")"
t07_free="$(awk -F'\t' '$1=="test-mix.sh" && $2=="T07 build output check"{c++} END{print c+0}' "${SCRATCH}/o8.tsv")"
t07_bare="$(awk -F'\t' '$1=="test-mix.sh" && $2=="T07"{c++} END{print c+0}' "${SCRATCH}/o8.tsv")"
assert_eq "${par_count:-0}" "2" "CPG08 ID-prefixed label + [SKIPPED] shim collapse to one key (count 2)"
assert_eq "$t07_free" "1" "CPG08 single-letter-prefix T07 takes the free-form path (masked full label is the key)"
assert_eq "$t07_bare" "0" "CPG08 T07 is NOT treated as a bare ID token"

# =====================================================================
# CPG09 -- collect with a required runtime forced absent -> exit 3.
# Force absence hermetically via an empty PATH; the tool computes its repo root
# and checks runtimes with builtins only, so it exits 3 before any external
# command is invoked (works whether or not the runtimes are truly installed).
# =====================================================================
D09="${SCRATCH}/cpg09"
mkdir -p "$D09"
printf '#!/usr/bin/env bash\necho placeholder\n' > "${D09}/test-z.sh"
EMPTY_PATH_DIR="${SCRATCH}/empty-path"
mkdir -p "$EMPTY_PATH_DIR"
BASH_BIN="$(command -v bash)"
PATH="$EMPTY_PATH_DIR" "$BASH_BIN" "$SUT" collect --out "${SCRATCH}/rt9.tsv" --dir "$D09" >/dev/null 2>&1
rc9=$?
assert_exit_eq "$rc9" 3 "CPG09 collect with a required runtime absent -> exit 3 (precondition)"

# =====================================================================
# CPG10 -- shared-ID loop assertion whose emission COUNT drops (3 -> 2, same
# key) -> exit 1 (the multiset catches the count reduction; false-negative guard).
# =====================================================================
write_tsv "${SCRATCH}/base10.tsv" <<'EOF'
test-loop.sh|LOOP01|3
EOF
write_tsv "${SCRATCH}/after10.tsv" <<'EOF'
test-loop.sh|LOOP01|2
EOF
run_diff --baseline "${SCRATCH}/base10.tsv" --after "${SCRATCH}/after10.tsv"
assert_exit_eq "$DRC" 1 "CPG10 shared-ID loop count drop (3->2, same key) -> exit 1"
assert_output_contains "$DOUT" "LOOP01" "CPG10 report names the count-reduced key"

# =====================================================================
# CPG11 -- net-removed key with no re-home target:
#   (a) listed in accepted-removals with justification -> exit 0 (excused).
#   (b) absent from a comments-only accepted-removals    -> exit 1.
# =====================================================================
write_tsv "${SCRATCH}/base11.tsv" <<'EOF'
test-x.sh|AAA01|1
test-x.sh|BBB01|1
EOF
write_tsv "${SCRATCH}/after11.tsv" <<'EOF'
test-x.sh|AAA01|1
EOF
write_tsv "${SCRATCH}/accept11.tsv" <<'EOF'
test-x.sh|BBB01|delivery-002|redundant nested peer-suite check; peer runs standalone via the run-all.sh glob
EOF
run_diff --baseline "${SCRATCH}/base11.tsv" --after "${SCRATCH}/after11.tsv" --accept "${SCRATCH}/accept11.tsv"
assert_exit_eq "$DRC" 0 "CPG11a removal listed in accepted-removals with justification -> exit 0 (excused)"
assert_output_contains "$DOUT" "ACCEPTED" "CPG11a report marks the accepted removal"

printf '# only comment lines here, no data rows\n#\n' > "${SCRATCH}/accept11empty.tsv"
run_diff --baseline "${SCRATCH}/base11.tsv" --after "${SCRATCH}/after11.tsv" --accept "${SCRATCH}/accept11empty.tsv"
assert_exit_eq "$DRC" 1 "CPG11b removal absent from a comments-only accepted-removals -> exit 1 (comments ignored)"

# ---------------------------------------------------------------------------
echo ""
test_summary
