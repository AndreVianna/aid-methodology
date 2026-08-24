#!/usr/bin/env bash
# test-settings-schema-check.sh -- canonical test suite for settings-schema-check.sh.
#
# Five fixtures, one per outcome:
#   SS01  a valid settings file                    -> exit 0
#   SS02  missing format_version                   -> exit 1, names the key
#   SS03  a minimum_grade grade.sh cannot emit     -> exit 1, names the key
#   SS04  an undocumented top-level key            -> exit 1, names the key
#   SS05  zero keys                                -> exit 1, NOT a quiet pass
#
# SS05 is the one to keep. A shape check over an empty or unparsed file produces
# "no violations", which is byte-identical to a valid file's result. Letting it
# pass would be the exact vacuity this gate exists to forbid, so the suite
# asserts the exit code rather than the absence of complaints.
#
# Every assertion is on the EXIT CODE first and the message second. A suite that
# only matched output text would pass against a script that printed the right
# words and exited 0.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-settings-schema-check.sh =="

CHECK="${REPO_ROOT}/scripts/checks/settings-schema-check.sh"

if [[ ! -f "$CHECK" ]]; then
    fail "setup -- check script not found at $CHECK"
    test_summary
    exit $?
fi

# The supported stamp is read from bin/aid rather than hardcoded, so a future
# format bump moves this suite with the tool instead of breaking it.
SUPPORTED="$(grep -oE 'AID_SUPPORTED_FORMAT=[0-9]+' "${REPO_ROOT}/bin/aid" | head -1 | cut -d= -f2)"
SUPPORTED="${SUPPORTED:-4}"

FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT

# run <fixture-basename> -> sets $out and returns the exit code
run_check() {
    out="$(bash "$CHECK" --path "${FIX}/$1" 2>&1)"
    return $?
}

# ===========================================================================
# SS01  A valid settings file -> exit 0
# ===========================================================================
cat > "${FIX}/valid.yml" <<EOF
format_version: ${SUPPORTED}
name: FixtureProject
description: A fixture
type: brownfield
source_control: git
minimum_grade: A
heartbeat_interval: 1
knowledge:
  source: master
EOF

run_check valid.yml; code=$?
assert_eq "$code" "0" "SS01 valid file -- exit 0"
assert_output_contains "$out" "PASS" "SS01 valid file -- reports PASS"

# ===========================================================================
# SS02  Missing format_version -> exit 1, naming the key
# ===========================================================================
cat > "${FIX}/no-format-version.yml" <<'EOF'
name: FixtureProject
type: brownfield
minimum_grade: A
EOF

run_check no-format-version.yml; code=$?
assert_eq "$code" "1" "SS02 missing format_version -- exit 1"
assert_output_contains "$out" "format_version is missing" "SS02 -- names the missing key"

# ===========================================================================
# SS03  A minimum_grade grade.sh cannot emit -> exit 1, naming the key
#
# 'Z' is not in the sixteen-value domain. The fixture uses a letter outside
# A-F on purpose: a check that only validated the modifier would accept it.
# ===========================================================================
cat > "${FIX}/bad-grade.yml" <<EOF
format_version: ${SUPPORTED}
name: FixtureProject
minimum_grade: Z
EOF

run_check bad-grade.yml; code=$?
assert_eq "$code" "1" "SS03 ungradeable minimum_grade -- exit 1"
assert_output_contains "$out" "minimum_grade is 'Z'" "SS03 -- names the key and the bad value"

# ===========================================================================
# SS04  An undocumented top-level key -> exit 1, naming the key
# ===========================================================================
cat > "${FIX}/undocumented-key.yml" <<EOF
format_version: ${SUPPORTED}
name: FixtureProject
minimum_grade: A
banana: yes
EOF

run_check undocumented-key.yml; code=$?
assert_eq "$code" "1" "SS04 undocumented key -- exit 1"
assert_output_contains "$out" "'banana' is not documented" "SS04 -- names the undocumented key"

# ===========================================================================
# SS05  Zero keys -> exit 1. Examining nothing is never a pass.
# ===========================================================================
cat > "${FIX}/zero-keys.yml" <<'EOF'
# A settings file that declares nothing.
# Every line here is a comment.
EOF

run_check zero-keys.yml; code=$?
assert_eq "$code" "1" "SS05 zero keys -- exit 1, not a quiet pass"
assert_output_contains "$out" "declares no top-level keys" "SS05 -- says why it failed"
assert_output_not_contains "$out" "PASS" "SS05 -- does not report PASS"

# ===========================================================================
# SS06  A stamp NEWER than the CLI supports -> exit 1.
#
# The mirror image of the note-only older-stamp path. bin/aid REFUSES to
# operate on a newer project, so the check must too. Without this, the
# three-way gate could collapse to "never fail on format_version" and the
# suite would not notice.
# ===========================================================================
cat > "${FIX}/newer-stamp.yml" <<EOF
format_version: $((SUPPORTED + 95))
name: FixtureProject
minimum_grade: A
EOF

run_check newer-stamp.yml; code=$?
assert_eq "$code" "1" "SS06 newer stamp -- exit 1"
assert_output_contains "$out" "newer than this CLI supports" "SS06 -- says the CLI would refuse"

# ===========================================================================
# SS07  A stamp OLDER than the CLI supports -> exit 0 with a note.
#
# bin/aid's _aid_format_gate warns and offers `aid update` rather than
# refusing, so a check stricter than that would fail every project
# mid-upgrade. Asserted so the leniency is deliberate and cannot be
# tightened by accident.
# ===========================================================================
if [[ "$SUPPORTED" -gt 1 ]]; then
    cat > "${FIX}/older-stamp.yml" <<EOF
format_version: $((SUPPORTED - 1))
name: FixtureProject
minimum_grade: A
EOF

    run_check older-stamp.yml; code=$?
    assert_eq "$code" "0" "SS07 older stamp -- exit 0 (bin/aid warns, does not refuse)"
    assert_output_contains "$out" "[NOTE]" "SS07 -- but says the stamp is behind"
else
    pass "SS07 skipped -- AID_SUPPORTED_FORMAT is 1, no older stamp exists"
fi

# ===========================================================================
# SS08  Key shapes the extractor must not silently drop.
#
# Every past narrowing of this pattern HID a key rather than rejecting it, and
# a hidden key reads as a clean file. Each shape below must be COUNTED and
# NAMED, not merely rejected.
# ===========================================================================
i=0
for shape in 'CamelCaseKey' '"quoted-key"' 'dotted.key'; do
    i=$((i + 1))
    cat > "${FIX}/shape-${i}.yml" <<EOF
format_version: ${SUPPORTED}
name: FixtureProject
${shape}: value
EOF
    run_check "shape-${i}.yml"; code=$?
    bare="${shape//\"/}"
    assert_eq "$code" "1" "SS08 ${shape} -- exit 1 (not silently dropped)"
    assert_output_contains "$out" "'${bare}' is not documented" "SS08 ${shape} -- named in the finding"
done

# ===========================================================================
# SS09  Lines that are NOT top-level keys must not be picked up.
#
# The widened extractor trades misses for false positives, and a false positive
# is worse: it fails a valid file. Comments, nested keys and colon-bearing
# values must all be invisible to it.
# ===========================================================================
cat > "${FIX}/non-keys.yml" <<EOF
# a comment: with a colon in it
format_version: ${SUPPORTED}
name: FixtureProject
description: "A value: containing a colon"
minimum_grade: A
knowledge:
  source: master
  last_update: 2026-01-01T00:00:00Z
EOF

run_check non-keys.yml; code=$?
assert_eq "$code" "0" "SS09 comments, nested keys and colon-bearing values -- exit 0"
assert_output_not_contains "$out" "[FAIL]" "SS09 -- no false positive"

# ===========================================================================
# SS10  Determinism.
# ===========================================================================
a="$(bash "$CHECK" --path "${FIX}/valid.yml" 2>&1)"
b="$(bash "$CHECK" --path "${FIX}/valid.yml" 2>&1)"
assert_eq "$a" "$b" "SS10 two consecutive runs are byte-identical"

c="$(LC_ALL=C bash "$CHECK" --path "${FIX}/undocumented-key.yml" 2>&1)"
d="$(LC_ALL=en_US.UTF-8 bash "$CHECK" --path "${FIX}/undocumented-key.yml" 2>&1)"
assert_eq "$c" "$d" "SS10 output does not depend on locale"

# ===========================================================================
# SS11  Invocation errors are distinguishable from findings (exit 2, not 1).
# ===========================================================================
bash "$CHECK" --path "${FIX}/does-not-exist.yml" >/dev/null 2>&1
assert_eq "$?" "2" "SS11 unreadable file -- exit 2, not a finding"

bash "$CHECK" >/dev/null 2>&1
assert_eq "$?" "2" "SS11 missing --path -- exit 2"

rm -rf "$FIX"
trap - EXIT

echo
test_summary
exit $?
