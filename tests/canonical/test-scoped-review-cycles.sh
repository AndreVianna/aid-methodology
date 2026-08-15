#!/usr/bin/env bash
# test-scoped-review-cycles.sh -- the three guards, by seeded defect
#
# COVERS: canonical/aid/templates/reviewer-ledger-schema.md
# COVERS: canonical/aid/templates/reviewer-dispatch.md
#
# Scoping a review cycle is only safe because of three guards. Asserting that
# the guards are DOCUMENTED would prove nothing -- prose always says the right
# thing. So the two mechanical guards are exercised against SEEDED DEFECTS
# using the same derivations the protocol specifies, and the third (the ledger
# verification set) is exercised against a real ledger table.
#
# What this suite can and cannot do, stated plainly: the reviewer is an LLM, so
# these assertions exercise the DERIVATIONS the protocol mandates -- the hunt
# set, the referrer expansion, the verification set -- not an agent's obedience
# to them. That is the honest boundary. A derivation that cannot find a seeded
# defect is a defect in the design; an agent that ignores a correct derivation
# is a different failure, out of reach of a shell suite.
#
# Assertions:
#   SC01-03  AC-2: a defect in a file that REFERENCES a changed file is inside
#            the scoped surface -- the referrer expansion finds it
#   SC04-05  AC-3: a defect OUTSIDE the scoped surface is missed by the scoped
#            hunt and caught by the full pass -- the backstop demonstrated
#   SC06-08  AC-4: the verification set is unscoped, including a `Doc: —` row
#   SC09-11  AC-13: the contradiction pass is declared once per phase, at three
#            sites, and NOT at aid-specify
#   SC12-13  FR-1 / FR-6: cycle 1 unchanged; a scoped cycle never approves
#   SC14     the fallback: no previous-cycle commit means an unscoped cycle
#   SC15     C-3: the ledger is still 7 columns and grade.sh is untouched
#
# Usage:  test-scoped-review-cycles.sh [--verbose]
# Exit:   0 all passed / 1 one or more failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SCHEMA="${REPO_ROOT}/canonical/aid/templates/reviewer-ledger-schema.md"
DISPATCH="${REPO_ROOT}/canonical/aid/templates/reviewer-dispatch.md"

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# A miniature corpus with a real reference edge, in its own git repo so the
# hunt-set derivation (git diff) is exercised for real rather than simulated.
# ---------------------------------------------------------------------------
CORPUS="${TMP}/corpus"
mkdir -p "$CORPUS"
(
  cd "$CORPUS"
  git init -q . && git config user.email t@t && git config user.name t
  printf '# Alpha\n\nThe canonical value is 10.\n' > alpha.md
  printf '# Beta\n\nBeta defers to `alpha.md` for the canonical value, which is 10.\n' > beta.md
  printf '# Gamma\n\nGamma is unrelated to anything else here.\n' > gamma.md
  git add -A && git commit -qm base
) >/dev/null 2>&1
BASE_COMMIT="$( cd "$CORPUS" && git rev-parse HEAD )"

# The derivations the protocol specifies, implemented exactly as written.
hunt_changed() { ( cd "$CORPUS" && git diff --name-only "$1"..HEAD ) ; }
hunt_referrers() {   # every file naming any changed path
    local changed="$1" f c
    ( cd "$CORPUS"
      for c in $changed; do
          grep -l -- "$c" ./*.md 2>/dev/null | sed 's|^\./||'
      done )
}
hunt_set() {
    local changed; changed="$(hunt_changed "$1")"
    { printf '%s\n' $changed; hunt_referrers "$changed"; } | sort -u | sed '/^$/d'
}

# ---------------------------------------------------------------------------
echo "=== SC01-03 (AC-2): a defect in a REFERRING file is inside the scoped surface ==="
# ---------------------------------------------------------------------------
# The FIX changes alpha.md's value. beta.md restates it and is now wrong --
# a defect in a file the FIX never touched. The referrer expansion must reach it.
( cd "$CORPUS" && sed -i 's/The canonical value is 10./The canonical value is 20./' alpha.md && git commit -qam "fix: alpha 10 -> 20" ) >/dev/null 2>&1
CHANGED="$(hunt_changed "$BASE_COMMIT")"
HUNT="$(hunt_set "$BASE_COMMIT")"
assert_eq "$CHANGED" "alpha.md" "SC01 the FIX changed exactly alpha.md"
if grep -qx 'beta.md' <<<"$HUNT"; then
    pass "SC02 (AC-2) beta.md REFERENCES alpha.md and is pulled into the scoped surface"
else
    fail "SC02 (AC-2) the referrer expansion missed beta.md -- a seeded defect would escape"
fi
if grep -qx 'gamma.md' <<<"$HUNT"; then
    fail "SC03 gamma.md references nothing changed yet was pulled in -- the scope is not scoped"
else
    pass "SC03 gamma.md references nothing changed and is correctly OUTSIDE the scope"
fi

# ---------------------------------------------------------------------------
echo "=== SC04-05 (AC-3): a defect outside the scope is missed, then caught by the full pass ==="
# ---------------------------------------------------------------------------
# Seed a defect in gamma.md, which is outside the scoped surface by construction.
( cd "$CORPUS" && printf 'This claim is false: the canonical value is 99.\n' >> gamma.md ) >/dev/null 2>&1
SCOPED_FINDS="$(grep -l 'value is 99' $(printf '%s\n' $HUNT | sed "s|^|${CORPUS}/|") 2>/dev/null || true)"
if [[ -z "$SCOPED_FINDS" ]]; then
    pass "SC04 (AC-3) the scoped hunt does NOT see the defect seeded outside its surface"
else
    fail "SC04 (AC-3) the scoped hunt saw a file it should not have"
fi
FULL_FINDS="$( cd "$CORPUS" && grep -l 'value is 99' ./*.md | sed 's|^\./||' )"
assert_eq "$FULL_FINDS" "gamma.md" \
    "SC05 (AC-3) the FULL pass catches it -- the backstop works end to end"

# ---------------------------------------------------------------------------
echo "=== SC06-08 (AC-4): the verification set is unscoped, Doc: — included ==="
# ---------------------------------------------------------------------------
LEDGER="${TMP}/ledger.md"
cat >"$LEDGER" <<'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [HIGH] | Pending | gamma.md | 3 | G-01 — stale claim | disk shows otherwise |
| 2 | [LOW] | Fixed | beta.md | 3 | G-02 — bad cite | fixed cycle 2 |
| 3 | [MEDIUM] | Pending | — | — | KB-02 — doc-wide concern | spans the set |
EOF
# The verification set is every Doc value; a `—` widens it to the whole cycle-1 set.
VERIFY="$(awk -F'|' 'NR>2 && NF>3 {gsub(/ /,"",$5); if ($5!="") print $5}' "$LEDGER" | sort -u)"
if grep -qx 'gamma.md' <<<"$VERIFY"; then
    pass "SC06 (AC-4) gamma.md is in the VERIFY set from its ledger row, though outside the hunt scope"
else
    fail "SC06 (AC-4) a Pending row's Doc is not in the verification set -- Recurred detection would break"
fi
if grep -qx 'beta.md' <<<"$VERIFY"; then
    pass "SC07 (AC-4) a FIXED row's Doc is verified too -- that is how a regression becomes Recurred"
else
    fail "SC07 (AC-4) a Fixed row's Doc is not re-verified"
fi
if grep -q '—' <<<"$VERIFY"; then
    pass "SC08 (AC-4) a Doc: — row is present and must widen verification to the full cycle-1 set"
else
    fail "SC08 (AC-4) the Doc: — row vanished from the verification set -- it could never be re-verified"
fi

# ---------------------------------------------------------------------------
echo "=== SC09-11 (AC-13): the contradiction pass -- once per phase, three sites, not aid-specify ==="
# ---------------------------------------------------------------------------
assert_file_contains "$DISPATCH" "once-per-phase" \
    "SC09 (AC-13) the pass is declared once per phase in the dispatch protocol"
SITES=0
for f in aid-define/references/state-cross-reference.md \
         aid-plan/references/review-deliverables.md \
         aid-detail/references/review.md; do
    grep -q "Guard 2" "${REPO_ROOT}/canonical/skills/${f}" && SITES=$(( SITES + 1 ))
done
assert_eq "$SITES" "3" "SC10 (AC-13) all three multi-artifact reviews invoke it"
if grep -rq "Guard 2" "${REPO_ROOT}/canonical/skills/aid-specify/references/"; then
    fail "SC11 (AC-13) aid-specify invokes Guard 2 -- it dispatches per artifact, so it would run once per FEATURE"
else
    pass "SC11 (AC-13) aid-specify correctly invokes no pass -- its specs are covered at aid-plan"
fi

# ---------------------------------------------------------------------------
echo "=== SC12-15: FR-1, FR-6, the fallback, and C-3 ==="
# ---------------------------------------------------------------------------
assert_file_contains "$SCHEMA" "REVIEW (cycle 1)" "SC12 (FR-1) cycle 1 is still declared as the full read"
assert_file_contains "$SCHEMA" "scoped cycle never approves" \
    "SC13 (FR-6) a scoped cycle cannot approve -- only a full pass can"
assert_file_contains "$SCHEMA" "the cycle is UNSCOPED" \
    "SC14 no previous-cycle commit degrades to an unscoped cycle, the safe direction"
# C-3 / AC-10 assert that the 7-column ledger and its grader still work together.
# An earlier version proved that by diffing grade.sh against `origin/master`, which
# passed locally and FAILED IN CI: a shallow clone has no such ref, so the diff errored
# and took the assertion down with it. That is exactly the defect class `tech-debt.md`
# W4-3 lists as "(H) dependence on local origin/master ancestry", committed by a suite
# written in a repo that happened to have the ref.
#
# Behaviour is the better assertion anyway. What C-3 protects is not grade.sh's bytes but
# that the grader still reads a 7-column ledger positionally and prices it correctly. A
# byte-diff would also fail on a harmless comment change while passing a semantic break.
GRADER="${REPO_ROOT}/canonical/aid/scripts/grade.sh"
LED="${TMP}/grade-fixture.md"
grade_of() { printf '%s\n' "$@" >"$LED"; ( cd "$REPO_ROOT" && bash "$GRADER" "$LED" ) 2>/dev/null; }
HDR='| # | Severity | Status | Doc | Line | Description | Evidence |'
SEP='|---|---|---|---|---|---|---|'
G_EMPTY="$(grade_of "$HDR" "$SEP")"
G_LOW="$(grade_of   "$HDR" "$SEP" '| 1 | [LOW] | Pending | a.md | 1 | G-01 — x | y |')"
G_MIX="$(grade_of   "$HDR" "$SEP" '| 1 | [HIGH] | Pending | a.md | 1 | G-01 — x | y |' \
                                   '| 2 | [LOW] | Fixed | b.md | 2 | G-02 — z | w |')"
if grep -q "shape stays 7 columns" "$SCHEMA" \
   && [[ "$G_EMPTY" == "A+" ]] && [[ "$G_LOW" == "B+" ]] && [[ "$G_MIX" == "D+" ]]; then
    pass "SC15 (C-3, AC-10) the 7-column ledger and grade.sh still agree: empty=A+, one LOW=B+, HIGH+Fixed-LOW=D+ (a Fixed row correctly does not count)"
else
    fail "SC15 (C-3, AC-10) grader/ledger contract broken -- empty='$G_EMPTY' (want A+), one-LOW='$G_LOW' (want B+), mixed='$G_MIX' (want D+)"
fi

echo
test_summary
exit $?
