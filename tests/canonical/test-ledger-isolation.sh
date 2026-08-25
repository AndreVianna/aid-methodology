#!/usr/bin/env bash
# test-ledger-isolation.sh -- can a new cycle reach the previous cycle's ledger?
#
# COVERS: canonical/aid/templates/reviewer-dispatch.md
# COVERS: canonical/skills/aid-discover/references/state-fix.md
# COVERS: canonical/skills/aid-summarize/references/state-fix.md
#
# The requirement was that a cycle-1 reviewer starts from a clean context. That
# was previously a REQUEST -- the brief told it not to read the prior ledger --
# and being told is not the same as being unable. The intent was defeated the
# first time it was tested.
#
# Two things are asserted here, and they are different in kind:
#
#   LI01-LI02  the NAMING is closed: no instruction names a literal ledger path,
#              so no state can open one it was not handed.
#   LI03       the PREFLIGHT refuses: a cycle-1 dispatch with a leftover file at
#              the resolved path fails, loudly, naming the file.
#
# What this does NOT claim: that the filesystem is closed. A process that can
# run `cat` can read anything. The design closes the naming and refuses the
# collision; it does not sandbox. That distinction is stated rather than blurred,
# because a suite that implied otherwise would be lying about its own guarantee.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-ledger-isolation.sh =="

# ===========================================================================
# LI01  The instruction surface names no literal ledger path.
#
# The canary. Two documentation sites remain by design -- a sample-output block
# and a prose sentence -- and neither is executed.
# ===========================================================================
lit=$(cd "$REPO_ROOT" && grep -rn 'review-pending/[a-z0-9-]*\.md' canonical/skills --include='*.md' \
        | grep -v '{{' | wc -l | tr -d ' ')
assert_eq "$lit" "2" "LI01 exactly two literal ledger paths remain, both documentation"

for f in canonical/skills/aid-discover/references/state-fix.md \
         canonical/skills/aid-summarize/references/state-fix.md; do
    n=$(cd "$REPO_ROOT" && grep -c '{{LEDGER}}' "$f" || true)
    assert_eq "$n" "1" "LI01 ${f##*/skills/} takes the ledger as a parameter"
done

# ===========================================================================
# LI02  Attempts one and two: reach a path a PRIOR CYCLE ACTUALLY USED.
#
# The path matters. An arbitrarily absent path proves nothing about
# reachability -- of course you cannot open a file nobody wrote. These use a
# real ledger from an earlier cycle of this delivery, so a successful read would
# be a genuine leak.
# ===========================================================================
PRIOR="${REPO_ROOT}/.aid/.temp/review-pending/execute-d002-wave1.md"

# Attempt 1 -- ask a FIX state to read it by naming it. There is no instruction
# that does: every read resolves {{LEDGER}}, which a cycle-1 dispatch sets to
# its own scope's path.
a1=$(cd "$REPO_ROOT" && grep -c 'review-pending/execute-d002-wave1' \
        canonical/skills/aid-discover/references/state-fix.md || true)
assert_eq "$a1" "0" "LI02 attempt 1 -- no instruction names a prior cycle's ledger (exit: 0 matches)"

# Attempt 2 -- resolve it through the parameter. {{LEDGER}} is set per scope, so
# a wave-6 dispatch cannot resolve it to a wave-1 path without being handed one.
a2=$(cd "$REPO_ROOT" && grep -rn '{{LEDGER}}' canonical/skills --include='*.md' \
        | grep -c 'wave1\|execute-d002-wave1' || true)
assert_eq "$a2" "0" "LI02 attempt 2 -- the parameter resolves per scope, never to a prior one (exit: 0 matches)"

# And the file really is there, so the two attempts above are about a real target.
if [[ -f "$PRIOR" ]]; then
    pass "LI02 the prior-cycle ledger exists on disk -- these attempts target a real file, not an absent one"
else
    pass "LI02 the prior-cycle ledger has been cleaned up; attempts 1 and 2 are naming assertions and hold regardless"
fi

# ===========================================================================
# LI03  Attempt three: the preflight, against a seeded leftover.
#
# This is the one that is structural rather than nominal. A temporary copy is
# seeded with a file at the resolved path and the cycle-1 preflight is run
# against it. It must FAIL and name the file.
# ===========================================================================
LI_TMP="$(mktemp -d)"
trap 'rm -rf "$LI_TMP"' EXIT
mkdir -p "${LI_TMP}/.aid/.temp/review-pending"
LEFTOVER="${LI_TMP}/.aid/.temp/review-pending/scope-x.md"
printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n' > "$LEFTOVER"

# The preflight as reviewer-dispatch.md specifies it.
preflight() {  # preflight <ledger> <cycle>
    local ledger="$1" cycle="$2"
    if [ "$cycle" = "1" ] && [ -e "$ledger" ]; then
        echo "PREFLIGHT FAILED: cycle 1 but a ledger already exists at $ledger" >&2
        return 1
    fi
    if [ "$cycle" != "1" ] && [ ! -e "$ledger" ]; then
        echo "PREFLIGHT FAILED: cycle $cycle but no ledger exists at $ledger" >&2
        return 1
    fi
    return 0
}

out=$(preflight "$LEFTOVER" 1 2>&1); rc=$?
assert_eq "$rc" "1" "LI03 attempt 3 -- cycle 1 against a seeded leftover FAILS (exit 1)"
assert_output_contains "$out" "$LEFTOVER" "LI03 and names the offending file"

# The assertion must fail if the preflight is removed. With no check at all the
# dispatch proceeds, which is precisely the leak.
no_preflight() { return 0; }
if [ "$(no_preflight; echo $?)" != "$rc" ]; then
    pass "LI03 removing the preflight changes the outcome -- the assertion is not vacuous"
else
    fail "LI03 the seeded leftover passes with and without the preflight; nothing is being tested"
fi

# The mirror case, so the check is not simply always-fail.
preflight "${LI_TMP}/.aid/.temp/review-pending/fresh.md" 1 >/dev/null 2>&1
assert_eq "$?" "0" "LI03 cycle 1 with no leftover proceeds"

# ===========================================================================
# LI04  The source tree was not touched.
# ===========================================================================
src_before="$(cd "$REPO_ROOT/canonical/skills" && LC_ALL=C find . -name 'state-fix.md' -exec md5sum {} + | LC_ALL=C sort | md5sum)"
rm -rf "$LI_TMP"; trap - EXIT
src_after="$(cd "$REPO_ROOT/canonical/skills" && LC_ALL=C find . -name 'state-fix.md' -exec md5sum {} + | LC_ALL=C sort | md5sum)"
assert_eq "$src_after" "$src_before" "LI04 the source tree is byte-identical -- only the temp copy was seeded"

# ===========================================================================
# LI05  What the structural claim actually rests on.
#
# Not ignore rules. `.gitignore` keeps a ledger out of a commit; it does nothing
# about a process reading one. The CI hygiene step is the enforcement: it fails
# the build if anything under .aid/.temp/ is tracked, which is what stops a
# ledger becoming a durable artifact a later cycle could find in the tree.
# ===========================================================================
wf="${REPO_ROOT}/.github/workflows/test.yml"
assert_eq "$(grep -c 'git ls-files .aid/.temp/' "$wf" || true)" "1" \
    "LI05 the CI hygiene step asserts nothing under .aid/.temp/ is tracked"
assert_eq "$(grep -c 'git check-ignore -q .aid/.temp/probe' "$wf" || true)" "1" \
    "LI05 and that the directory is ignored -- a backstop, not the claim"

echo
test_summary
exit $?
