#!/usr/bin/env bash
# test-severity-why-line.sh -- the why-line and severity-provenance contract.
#
# COVERS: canonical/aid/templates/reviewer-ledger-schema.md
# COVERS: canonical/agents/aid-reviewer/AGENT.md
# COVERS: canonical/aid/scripts/grade.sh
#
# Asserted against FIXTURES, not against a live ledger. A real ledger is
# transient -- it lives under .aid/.temp/ and is deleted at DONE -- so a suite
# reading one passes on the machine that just ran a review and is vacuous in CI.
#
# Cases:
#   WL01  a compliant row                       -- has a consequence and a token
#   WL02  a row with no consequence clause       -- detected
#   WL03  a row with no provenance token         -- detected
#   WL04  a Description containing an escaped pipe -- the field shift
#   WL05  each fixture's grade, asserted individually
#   WL06  the screen's masking is load-bearing

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-severity-why-line.sh =="

GRADER="${REPO_ROOT}/canonical/aid/scripts/grade.sh"
FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT

HDR='| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|'

# ---------------------------------------------------------------------------
# The screen. Masks the schema's `\|` escape BEFORE splitting, then reads the
# Description and Evidence cells by position.
# ---------------------------------------------------------------------------
screen() {  # screen <ledger> [--no-mask]
    local mask=1
    [ "${2:-}" = "--no-mask" ] && mask=0
    awk -v mask="$mask" '
        /^\|[[:space:]]*[0-9]+[[:space:]]*\|/ {
            line = $0
            if (mask) gsub(/\\\|/, "\001", line)
            n = split(line, c, "|")
            rows++
            desc = (n >= 7) ? c[7] : ""
            evid = (n >= 8) ? c[8] : ""
            if (tolower(desc) ~ /(so |because|which means|otherwise|leaving)/) why++
            if (evid ~ /severity: (declared|override|judged)/) tok++
            if (n != 9) shifted++
        }
        END { printf "rows=%d why=%d tok=%d shifted=%d\n", rows, why+0, tok+0, shifted+0 }
    ' "$1"
}

# --- WL01 compliant --------------------------------------------------------
cat > "${FIX}/compliant.md" <<EOF
${HDR}
| 1 | [LOW] | Pending | a.md | 4 | G-02 — the citation is a bare line number, so it points at the wrong line after the next edit above it | \`grep -n\` shows the anchor moved; \`severity: declared\` |
EOF
out="$(screen "${FIX}/compliant.md")"
assert_eq "$out" "rows=1 why=1 tok=1 shifted=0" "WL01 a compliant row has a consequence and a token"

# --- WL02 no consequence ---------------------------------------------------
cat > "${FIX}/nowhy.md" <<EOF
${HDR}
| 1 | [LOW] | Pending | a.md | 4 | G-02 — the citation is a bare line number | \`grep -n\` shows it; \`severity: declared\` |
EOF
out="$(screen "${FIX}/nowhy.md")"
assert_eq "$out" "rows=1 why=0 tok=1 shifted=0" "WL02 a row with no consequence clause is detected"

# --- WL03 no provenance token ----------------------------------------------
cat > "${FIX}/notok.md" <<EOF
${HDR}
| 1 | [LOW] | Pending | a.md | 4 | G-02 — bare line number, so the anchor rots | \`grep -n\` shows it |
EOF
out="$(screen "${FIX}/notok.md")"
assert_eq "$out" "rows=1 why=1 tok=0 shifted=0" "WL03 a row with no provenance token is detected"

# ---------------------------------------------------------------------------
# WL04  An escaped pipe in the Description.
#
# The measured field shift is the point. `\|` is the schema's own escape, so the
# cell legitimately contains it -- and a naive split on `|` gives that row TEN
# fields where its siblings have nine, moving Evidence out from under c[8]. The
# screen then reads the wrong cell and reports a compliant row as missing its
# token.
# ---------------------------------------------------------------------------
cat > "${FIX}/escaped.md" <<EOF
${HDR}
| 1 | [LOW] | Pending | a.md | 4 | G-02 — the cell says a \\| b, so the split shifts | \`grep -n\` shows it; \`severity: declared\` |
EOF
masked="$(screen "${FIX}/escaped.md")"
naive="$(screen "${FIX}/escaped.md" --no-mask)"

assert_eq "$masked" "rows=1 why=1 tok=1 shifted=0" "WL04 with masking the escaped-pipe row reads correctly"
# Measured, not assumed: the shift misreads BOTH cells, not only Evidence. The
# tenth field pushes Description out from under c[7] as well, so `why` drops to
# 0 too. That is a stronger demonstration than the one first written here --
# an unmasked screen does not miss one thing about the row, it reads the wrong
# row entirely.
assert_eq "$naive"  "rows=1 why=0 tok=0 shifted=1" "WL04 without masking the split shifts and BOTH cells are misread"

# --- WL06 the masking is load-bearing --------------------------------------
if [ "$masked" != "$naive" ]; then
    pass "WL06 removing the masking changes the screen's verdict -- the assertion is not vacuous"
else
    fail "WL06 masked and unmasked agree; WL04 would pass against a screen with no masking at all"
fi

# ---------------------------------------------------------------------------
# WL05  Each fixture's grade, asserted individually.
#
# One assertion per fixture, so a failure names the row that moved. An aggregate
# would report that something changed without saying which -- the same defect
# task-030 records about SC15.
# ---------------------------------------------------------------------------
for pair in compliant:B+ nowhy:B+ notok:B+ escaped:B+; do
    name="${pair%%:*}"; want="${pair##*:}"
    got="$(bash "$GRADER" "${FIX}/${name}.md")"
    assert_eq "$got" "$want" "WL05 ${name}.md grades ${want} -- the why-line is inert to grade.sh"
done

cat > "${FIX}/emptyled.md" <<EOF
${HDR}
EOF
assert_eq "$(bash "$GRADER" "${FIX}/emptyled.md")" "A+" "WL05 an empty ledger still grades A+"

# --- determinism -----------------------------------------------------------
a="$(screen "${FIX}/compliant.md")"; b="$(screen "${FIX}/compliant.md")"
assert_eq "$a" "$b" "WL07 two consecutive screens agree"
c="$(LC_ALL=C screen "${FIX}/escaped.md")"; d="$(LC_ALL=en_US.UTF-8 screen "${FIX}/escaped.md")"
assert_eq "$c" "$d" "WL07 the screen does not depend on locale"

rm -rf "$FIX"
trap - EXIT

echo
test_summary
exit $?
