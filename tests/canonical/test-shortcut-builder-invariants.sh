#!/usr/bin/env bash
# test-shortcut-builder-invariants.sh -- task-012 (work-004-optimize-skill-library,
# delivery-003, feature-006 write-set item 16): the two invariants of the shortcut
# builder, .claude/skills/generate-profile/scripts/build-shortcut-skills.py.
#
#   1. INVARIANT I1 (feature-002 SPEC "Invariant I1", the acceptance test for FR-3a):
#      render_doorway(row) output is INDEPENDENT of row["alias_of"]. Render the same
#      row twice -- once with alias_of null, once with it set to an arbitrary name --
#      and the emitted bytes must be IDENTICAL. Compared with `cmp`, byte for byte;
#      a semantic comparison is not this invariant.
#
#      I1 varies the field's VALUE, never its PRESENCE. `_REQUIRED_FIELDS` in the
#      builder still lists "alias_of", so a row with the key removed fails validation
#      before rendering and the invariant would be untested. SBI04 proves that premise
#      rather than asserting it. The field's removal from the schema is a scheduled
#      follow-on (work STATE Q4), outside this suite.
#
#   2. TWO-PROCESS IDEMPOTENCE (feature-006 proof P4): run the builder, run it AGAIN
#      in a fresh process, then run its own --check. BOTH halves are asserted -- the
#      second write-mode run must report 0 doorway(s) refreshed AND --check must exit
#      0 with no orphans. Either one alone only proves the script ran twice.
#
# HERMETICITY IS A WAVE-LEVEL REQUIREMENT, NOT SUITE HYGIENE. The builder resolves
# REPO_ROOT = Path(".") -- it writes relative to the CURRENT WORKING DIRECTORY. This
# suite runs it in WRITE mode. An unhermetic run would rewrite the repository's own
# canonical/skills/ while tests/canonical/test-catalog-dirs-parity.sh is executing its
# CDP-HELPER assertion (the same builder, --check, against committed bytes), producing
# a red in a file this suite does not own with nothing in its diff to explain it. So
# EVERY builder invocation here runs after `cd` into a scratch root under `mktemp -d`,
# against a COPIED catalogue and a COPIED skills tree, and SBI06 asserts -- rather than
# intends -- that the repository tree is byte-unchanged across the whole run.
#
# ---------------------------------------------------------------------------
# DEMONSTRATED RED -- what I1 was shown failing against, and how to reproduce it.
# ---------------------------------------------------------------------------
# Recorded here, in the suite itself, deliberately: a guard nobody has seen fail is a
# guard nobody has tested, and the proof must outlive the transient work folder.
#
# I1's negative control is a PAST REVISION of a product file, not a mutation of the
# present tree, so it cannot be a permanent fixture-based leg. Reach it through the
# ${BUILDER:-...} override below -- never by editing and reverting this file, which
# would leave the suite transiently wrong and the revert unreviewable.
#
# THE REVISION IS DERIVED, NEVER HARD-CODED. Two independent routes, which must agree:
#
#   P=.claude/skills/generate-profile/scripts/build-shortcut-skills.py
#   BASE=$(git merge-base HEAD origin/master)          # pre-work baseline
#   # route 1 -- write-set: the first post-baseline commit that touched the builder
#   LAND=$(git log --format=%H --reverse "$BASE"..HEAD -- "$P" | head -1)
#   # route 2 -- pickaxe: the last commit that changed `alias_of` occurrences in it
#   LAND2=$(git log --format=%H -1 -S'alias_of' -- "$P")
#   [ "$LAND" = "$LAND2" ] || echo "ROUTES DISAGREE -- do not proceed"
#   PRE=$(git rev-parse "${LAND}^1")                   # its first parent
#
# Derive from the PATH, not from a feature name. FR-3a / Invariant I1 is owned by
# feature-002 (feature-002-alias-description-rendering/SPEC.md), not by feature-004:
# feature-004 is tree-regeneration-and-prune, a different write set, and deriving from
# it lands at a revision where FR-3a is ALREADY APPLIED -- so I1 would run GREEN and
# demonstrate nothing.
#
# Confirmation that PRE is the right revision (content anchors, not a SHA):
#   git show "$PRE:$P" | grep -n 'if alias_of:'      # the conditional that gates the
#   git show "$PRE:$P" | grep -n 'thin alias of'     # "thin alias of" paragraph
# Both must hit. At the current revision both return exit 1.
#
# Reproduce:
#   git show "$PRE:$P" > /tmp/pre-fr3a-builder.py
#   BUILDER=/tmp/pre-fr3a-builder.py bash tests/canonical/test-shortcut-builder-invariants.sh --verbose
#   # EXPECTED: SBI03a/SBI03b (the two byte comparisons) and SBI03c/SBI03d (the
#   #           `thin alias`/`alias_of` content assertions) FAIL; the suite exits 1.
#   #           The idempotence legs stay green -- main() is unchanged between the two
#   #           revisions -- which is what isolates the red to FR-3a.
#
# When it was run: 2026-07-31, at which LAND resolved to 2609046e and PRE to 0069041b,
# and `if alias_of:` / the "thin alias of" f-string sat at lines 284 and 286 of the
# retrieved file. Those values are RECORDED as a measurement, not to be reused -- re-run
# the derivation above.
#
# ---------------------------------------------------------------------------
# Overridable subject: `${BUILDER:-<repo default>}`. In-repo precedent for overriding a
# revision this way: tests/canonical/test-release.sh (WORKTREE_REF="${AID_TEST_REF:-...}")
# and tests/canonical/test-release-install-e2e.sh, both of which point a suite at a
# materialised revision for exactly this purpose.
#
# Follows tests/canonical/test-assemble-determinism.sh, the in-repo determinism
# precedent: the same VERBOSE parse, SCRIPT_DIR/REPO_ROOT resolution, SUT binding with
# an existence guard, mktemp scratch root removed by a trap, and `cmp`-based byte
# comparison of two renders.
#
# No registration edit is needed anywhere: tests/run-all.sh discovers suites by the
# glob tests/canonical/test-*.sh.
#
# Usage:
#   bash tests/canonical/test-shortcut-builder-invariants.sh [-v | --verbose]
#   BUILDER=/path/to/other/build-shortcut-skills.py bash tests/canonical/test-shortcut-builder-invariants.sh
#
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

# Capture whether BUILDER came from the environment BEFORE the default is applied --
# SBI07a cannot otherwise tell "resolved the default" from "was handed the same path".
BUILDER_FROM_ENV=0
[[ -n "${BUILDER:-}" ]] && BUILDER_FROM_ENV=1
DEFAULT_BUILDER="${REPO_ROOT}/.claude/skills/generate-profile/scripts/build-shortcut-skills.py"
BUILDER="${BUILDER:-$DEFAULT_BUILDER}"

CATALOG_SRC="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SKILLS_SRC="${REPO_ROOT}/canonical/skills"

PY="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"

echo "=== Shortcut-builder invariants (task-012, feature-006: I1 + two-process idempotence) ==="

# ---------------------------------------------------------------------------
# SBI01 -- preconditions. Everything below is meaningless if one of these is absent,
# and an absent subject must read as a FAILURE, never as a vacuous pass.
# ---------------------------------------------------------------------------
assert_file_exists "$BUILDER"      "SBI01a builder script exists at the resolved BUILDER path"
assert_file_exists "$CATALOG_SRC"  "SBI01b shortcut-catalog.yml exists"
assert_dir_exists  "$SKILLS_SRC"   "SBI01c canonical/skills/ exists"
if [[ -n "$PY" ]]; then
    pass "SBI01d a python interpreter is available"
else
    fail "SBI01d a python interpreter is available -- neither python3 nor python on PATH"
fi

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

# ---------------------------------------------------------------------------
# Scratch root. Created with mktemp -d, removed by a trap on EVERY exit path
# including failure; SBI06d confirms the recorded path is gone.
# ---------------------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
SANDBOX="${TMP}/repo"
PROBE_OUT="${TMP}/probe"
mkdir -p "${SANDBOX}/canonical/aid/templates" "$PROBE_OUT"

# Every builder invocation goes through here, and only through here, so "ran from the
# scratch root" is a property of the harness rather than of each call site.
BUILDER_RUNS=0
BUILDER_CWDS=()
OUT=""
RC=0
run_builder() {
    OUT=$(cd "$SANDBOX" && "$PY" "$BUILDER" "$@" 2>&1)
    RC=$?
    BUILDER_RUNS=$((BUILDER_RUNS + 1))
    BUILDER_CWDS+=("$SANDBOX")
    # The cwd is RECORDED with the mktemp root masked to <SCRATCH>. The record still
    # shows the invocation ran under the scratch root, which is what the criterion
    # asks for, while keeping this suite's output byte-identical run to run -- an
    # unmasked mktemp path re-keys every line on every run.
    log "builder invocation ${BUILDER_RUNS}: cwd=<SCRATCH>${SANDBOX#$TMP} args=[$*] rc=${RC}"
}

# Fingerprint a directory tree as "<sorted-file-list sha> <concatenated-content sha>".
# Two hashes, not one: the content hash alone cannot distinguish a deleted file from an
# emptied one, and the list hash alone cannot see an edit.
tree_fingerprint() {
    local d="$1" lst lsha csha
    lst=$(find "$d" -type f 2>/dev/null | LC_ALL=C sort)
    lsha=$(printf '%s\n' "$lst" | sha256sum | cut -d' ' -f1)
    csha=$(printf '%s\n' "$lst" | tr '\n' '\0' | xargs -0 cat 2>/dev/null | sha256sum | cut -d' ' -f1)
    printf '%s %s' "$lsha" "$csha"
}

# Baseline of everything OUTSIDE the scratch root that an unhermetic run could damage,
# taken BEFORE the first builder invocation. SBI06b-d compare against these.
REPO_SKILLS_BEFORE=$(tree_fingerprint "$SKILLS_SRC")
REPO_CATALOG_BEFORE=$(sha256sum < "$CATALOG_SRC" | cut -d' ' -f1)
BUILDER_BEFORE=$(sha256sum < "$BUILDER" | cut -d' ' -f1)

# ---------------------------------------------------------------------------
# SBI02 -- the hermetic sandbox: a COPIED catalogue and a COPIED skills tree.
#
# The copy is then stripped of every GENERATED-marker doorway. What survives is
# exactly the hand-authored set (curated skills + `repurpose: true` rows), which
# SBI05g proves the builder never touches. Stripping is what makes SBI05's counts
# EXACT and independent of whether the repository tree happens to be drift-free --
# the alternative couples this suite's green to a state it does not own.
# ---------------------------------------------------------------------------
SANDBOX_CATALOG="${SANDBOX}/canonical/aid/templates/shortcut-catalog.yml"
SANDBOX_SKILLS="${SANDBOX}/canonical/skills"

cp "$CATALOG_SRC" "$SANDBOX_CATALOG"
cp -R "$SKILLS_SRC" "$SANDBOX_SKILLS"

assert_file_exists "$SANDBOX_CATALOG" "SBI02a catalogue copied into the scratch root"
assert_dir_exists  "$SANDBOX_SKILLS"  "SBI02b skills tree copied into the scratch root"

# The marker is READ FROM THE BUILDER, never re-typed here: a hand-copied marker that
# drifts from the script's own would silently disable orphan detection in this suite.
cat > "${TMP}/probe.py" <<'PYEOF'
"""Load the builder by path and emit the artefacts the bash suite asserts over.

Loaded via importlib.util.spec_from_file_location because the filename carries
hyphens and is therefore not importable by module name.
"""
import importlib.util
import sys
from pathlib import Path

builder_path, out_dir = sys.argv[1], Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("_builder_under_test", builder_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

(out_dir / "marker.txt").write_text(mod._GENERATED_MARKER, encoding="utf-8")

# In-memory fixture rows. Synthetic on purpose: I1 is a property of the function, and
# binding it to a live catalogue row would make the invariant hostage to catalogue edits.
def base_row(artifact):
    return {
        "name": "aid-i1-fixture",
        "verb": "create",
        "artifact": artifact,
        "alias_of": None,
        "default_type": "IMPLEMENT",
        "group": "G1",
        "intent": "I1 fixture row",
    }

for tag, artifact in (("std", "widget"), ("bare", "")):
    null_row = base_row(artifact)
    set_row = base_row(artifact)
    set_row["alias_of"] = "aid-some-other-shortcut"   # value varied, key never removed
    (out_dir / f"{tag}_alias_null.md").write_bytes(
        mod.render_doorway(null_row).encode("utf-8"))
    (out_dir / f"{tag}_alias_set.md").write_bytes(
        mod.render_doorway(set_row).encode("utf-8"))

# Premise probe for "set the field empty, do not delete it": validate_row MUST reject a
# row whose alias_of key is absent. If it ever stops rejecting, I1's chosen shape needs
# revisiting -- so the premise is measured here, not asserted in a comment.
probe = base_row("widget")
del probe["alias_of"]
try:
    mod.validate_row(probe, 0)
    verdict = "NOT_RAISED"
except Exception as exc:                      # CatalogError, by contract
    verdict = "RAISED:" + type(exc).__name__
(out_dir / "validate_missing.txt").write_text(verdict, encoding="utf-8")

# And the same row WITH the key present must validate, so the probe above is not merely
# rejecting a fixture that was malformed for some unrelated reason.
try:
    mod.validate_row(base_row("widget"), 0)
    verdict2 = "OK"
except Exception as exc:
    verdict2 = "RAISED:" + type(exc).__name__
(out_dir / "validate_present.txt").write_text(verdict2, encoding="utf-8")
PYEOF

PROBE_ERR=$(cd "$SANDBOX" && "$PY" "${TMP}/probe.py" "$BUILDER" "$PROBE_OUT" 2>&1)
PROBE_RC=$?
assert_exit_zero "$PROBE_RC" "SBI02c render_doorway loads by path (importlib) and renders the fixtures"
[[ $PROBE_RC -ne 0 ]] && log "probe stderr: ${PROBE_ERR}"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

MARKER=$(cat "${PROBE_OUT}/marker.txt")
if [[ -n "$MARKER" ]]; then
    pass "SBI02d the GENERATED marker was read from the builder rather than re-typed here"
else
    fail "SBI02d the GENERATED marker was read from the builder -- came back empty"
fi

# ---------------------------------------------------------------------------
# SBI03 -- INVARIANT I1, as a BYTE comparison.
# ---------------------------------------------------------------------------
echo ""
echo "=== SBI03: Invariant I1 -- render_doorway output is independent of alias_of ==="

if cmp -s "${PROBE_OUT}/std_alias_null.md" "${PROBE_OUT}/std_alias_set.md"; then
    pass "SBI03a I1 standard row: alias_of null vs set renders byte-identical output"
else
    fail "SBI03a I1 standard row: alias_of null vs set renders DIFFERENT bytes"
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo "---I1 DIFF (standard row)---"
        diff "${PROBE_OUT}/std_alias_null.md" "${PROBE_OUT}/std_alias_set.md"
        echo "---END---"
    fi
fi

if cmp -s "${PROBE_OUT}/bare_alias_null.md" "${PROBE_OUT}/bare_alias_set.md"; then
    pass "SBI03b I1 bare-verb row: alias_of null vs set renders byte-identical output"
else
    fail "SBI03b I1 bare-verb row: alias_of null vs set renders DIFFERENT bytes"
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo "---I1 DIFF (bare-verb row)---"
        diff "${PROBE_OUT}/bare_alias_null.md" "${PROBE_OUT}/bare_alias_set.md"
        echo "---END---"
    fi
fi

# I1 as stated is satisfiable by a renderer that emits the alias paragraph on BOTH
# branches. These two close that hole: the retired vocabulary must be absent outright.
# Read into a variable and asserted with the *_output_* helpers rather than the *_file_*
# ones deliberately: the file helpers print the scratch path in their failure label,
# which would make the FAILING output non-deterministic run to run -- and the failing
# output is exactly what a demonstrated-red record quotes.
STD_SET_CONTENT=$(cat "${PROBE_OUT}/std_alias_set.md")
assert_output_not_contains "$STD_SET_CONTENT" "thin alias" \
    "SBI03c a render with alias_of SET emits no 'thin alias' paragraph"
assert_output_not_contains "$STD_SET_CONTENT" "alias_of" \
    "SBI03d a render with alias_of SET emits no 'alias_of' mention"

# Non-vacuity: the renders are real, non-empty documents, so the two absence
# assertions above were applied to something.
STD_BYTES=$(wc -c < "${PROBE_OUT}/std_alias_set.md")
if [[ "$STD_BYTES" -gt 200 ]]; then
    pass "SBI03e non-vacuity: the rendered doorway is a real, non-empty document"
else
    fail "SBI03e non-vacuity: rendered doorway is implausibly small (${STD_BYTES} bytes)"
fi
assert_output_contains "$STD_SET_CONTENT" "name: aid-i1-fixture" \
    "SBI03f non-vacuity: the render carries the fixture row's own frontmatter name"

# ---------------------------------------------------------------------------
# SBI04 -- the premise behind "vary the VALUE, never the PRESENCE", measured.
# ---------------------------------------------------------------------------
VMISSING=$(cat "${PROBE_OUT}/validate_missing.txt")
VPRESENT=$(cat "${PROBE_OUT}/validate_present.txt")
case "$VMISSING" in
    RAISED:*) pass "SBI04a validate_row REJECTS a row whose alias_of key is absent (${VMISSING})" ;;
    *)        fail "SBI04a validate_row REJECTS a row whose alias_of key is absent -- got '${VMISSING}'" ;;
esac
assert_eq "$VPRESENT" "OK" \
    "SBI04b the same row WITH alias_of present validates, so SBI04a is not rejecting a broken fixture"

# ---------------------------------------------------------------------------
# SBI05 -- two-process idempotence (proof P4), against the copied tree.
#
# Both halves are asserted separately, because either alone only proves the script ran
# twice: the second WRITE-mode run must report 0 refreshed, AND --check must exit 0.
# ---------------------------------------------------------------------------
echo ""
echo "=== SBI05: two-process idempotence + --check, hermetic, against the copied tree ==="

# Derive the expected counts from the COPIED catalogue -- no literal anywhere.
mapfile -t EMITTING < <(awk '
  /^  - name: / { if (n != "") { if (!r) print n } ; n = $3; r = 0 }
  /^    repurpose: true/ { r = 1 }
  END { if (n != "" && !r) print n }
' "$SANDBOX_CATALOG" | LC_ALL=C sort)
TOTAL_ROWS=$(grep -c '^  - name: ' "$SANDBOX_CATALOG")
EXPECTED_N=${#EMITTING[@]}
REPURPOSE_N=$((TOTAL_ROWS - EXPECTED_N))
log "derived from the copied catalogue: rows=${TOTAL_ROWS} emitting=${EXPECTED_N} repurpose=${REPURPOSE_N}"

if [[ "$EXPECTED_N" -gt 0 && "$TOTAL_ROWS" -gt "$EXPECTED_N" ]]; then
    pass "SBI05a the copied catalogue yields a non-empty emitting set and a non-empty repurpose set"
else
    fail "SBI05a the copied catalogue yields a non-empty emitting set and a non-empty repurpose set -- rows=${TOTAL_ROWS} emitting=${EXPECTED_N}"
fi

# Strip every GENERATED-marker directory from the copy, in sorted order.
STRIPPED=0
while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    md="${d}/SKILL.md"
    [[ -f "$md" ]] || continue
    if grep -qF -- "$MARKER" "$md"; then
        rm -rf "$d"
        STRIPPED=$((STRIPPED + 1))
    fi
done < <(find "$SANDBOX_SKILLS" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort)
log "stripped ${STRIPPED} marker-carrying doorway(s) from the copied tree"

# Plant one orphan (marker present, no catalog row) and one hand-authored decoy (no
# marker, no catalog row). The builder must delete the first and never touch the second.
ORPHAN_DIR="${SANDBOX_SKILLS}/aid-zz-orphan-fixture"
DECOY_DIR="${SANDBOX_SKILLS}/aid-zz-handauthored-fixture"
mkdir -p "$ORPHAN_DIR" "$DECOY_DIR"
{ printf '%s\n' "$MARKER"; printf 'orphan fixture body\n'; } > "${ORPHAN_DIR}/SKILL.md"
printf 'hand-authored fixture body, no generated marker\n' > "${DECOY_DIR}/SKILL.md"

# Fingerprint the hand-authored survivors BEFORE any builder run.
HAND_BEFORE=$(tree_fingerprint "$SANDBOX_SKILLS")

# -- run 1: write mode, fresh process --------------------------------------
run_builder
assert_exit_zero "$RC" "SBI05b first write-mode run exits 0"
assert_output_contains "$OUT" "Generated/refreshed ${EXPECTED_N} doorway(s)" \
    "SBI05c first write-mode run generates every emitting row"
assert_output_contains "$OUT" "(0 already up to date)" \
    "SBI05d first write-mode run finds nothing already up to date (the tree was stripped)"
assert_output_contains "$OUT" "skipped ${REPURPOSE_N} repurpose row(s)" \
    "SBI05e first write-mode run skips every repurpose row"
assert_output_contains "$OUT" "removed 1 orphan(s)." \
    "SBI05f first write-mode run removes the planted marker-carrying orphan"

# The marker gate: a directory without the marker is never a deletion candidate.
# Path-free label, for the same reason SBI03c/d avoid the *_file_* helpers.
if [[ -f "${DECOY_DIR}/SKILL.md" ]]; then
    pass "SBI05g the hand-authored decoy (no marker, no catalog row) survives the write run"
else
    fail "SBI05g the hand-authored decoy (no marker, no catalog row) survives the write run -- it was deleted"
fi

# -- run 2: write mode again, a SEPARATE process ---------------------------
run_builder
assert_exit_zero "$RC" "SBI05h second write-mode run exits 0"
assert_output_contains "$OUT" "Generated/refreshed 0 doorway(s)" \
    "SBI05i P4 half 1: the second write-mode run reports 0 refreshed"
assert_output_contains "$OUT" "(${EXPECTED_N} already up to date)" \
    "SBI05j second write-mode run reports every doorway already up to date"
assert_output_contains "$OUT" "removed 0 orphan(s)." \
    "SBI05k second write-mode run removes no further orphan"

# -- run 3: the builder's own --check --------------------------------------
run_builder --check
assert_exit_zero "$RC" "SBI05l P4 half 2: --check exits 0 after the two write runs"
assert_output_contains "$OUT" "OK: ${EXPECTED_N} doorway(s) up to date" \
    "SBI05m --check reports every doorway up to date"
assert_output_contains "$OUT" "0 orphan(s)." \
    "SBI05n --check reports no orphan remaining"
assert_output_not_contains "$OUT" "DRIFT DETECTED" \
    "SBI05o --check reports no drift"

# -- the two write runs must also have produced IDENTICAL trees ------------
# Idempotence of the MESSAGE is not idempotence of the TREE: a builder could report 0
# refreshed while having rewritten something outside the doorway set.
HAND_AFTER=$(tree_fingerprint "$SANDBOX_SKILLS")
if [[ -f "${DECOY_DIR}/SKILL.md" ]]; then
    pass "SBI05p the hand-authored decoy still exists after all three runs"
else
    fail "SBI05p the hand-authored decoy still exists after all three runs -- it was deleted"
fi
if [[ ! -e "$ORPHAN_DIR" ]]; then
    pass "SBI05q the planted orphan directory is gone"
else
    fail "SBI05q the planted orphan directory is gone -- it survived"
fi
if [[ "$HAND_BEFORE" != "$HAND_AFTER" ]]; then
    pass "SBI05r non-vacuity: the sandbox tree DID change across the runs, so the fingerprint is live"
else
    fail "SBI05r non-vacuity: the sandbox tree fingerprint did not change, so nothing was generated"
fi

# ---------------------------------------------------------------------------
# SBI06 -- hermeticity, ASSERTED rather than intended.
# ---------------------------------------------------------------------------
echo ""
echo "=== SBI06: hermeticity -- every builder run stayed inside the scratch root ==="

CWD_OK=1
CWD_BAD=""
for cwd in "${BUILDER_CWDS[@]}"; do
    log "recorded builder cwd: <SCRATCH>${cwd#$TMP}"
    if [[ "$cwd" != "$TMP"/* ]]; then CWD_OK=0; CWD_BAD="<masked>"; fi
    if [[ "$cwd" == "$REPO_ROOT" ]]; then CWD_OK=0; CWD_BAD="the repository root"; fi
done
if [[ "$BUILDER_RUNS" -ge 3 && "$CWD_OK" -eq 1 ]]; then
    pass "SBI06a all ${BUILDER_RUNS} builder invocations ran from a cwd under the scratch root"
else
    fail "SBI06a all builder invocations ran from a cwd under the scratch root -- runs=${BUILDER_RUNS} offending='${CWD_BAD}'"
fi

REPO_SKILLS_AFTER=$(tree_fingerprint "$SKILLS_SRC")
if [[ "$REPO_SKILLS_AFTER" == "$REPO_SKILLS_BEFORE" ]]; then
    pass "SBI06b the repository's canonical/skills/ is byte-unchanged across the whole run"
else
    fail "SBI06b the repository's canonical/skills/ CHANGED across the run -- a builder invocation escaped the scratch root"
fi
REPO_CATALOG_AFTER=$(sha256sum < "$CATALOG_SRC" | cut -d' ' -f1)
assert_eq "$REPO_CATALOG_AFTER" "$REPO_CATALOG_BEFORE" \
    "SBI06c the repository's shortcut-catalog.yml is byte-unchanged across the whole run"
BUILDER_AFTER=$(sha256sum < "$BUILDER" | cut -d' ' -f1)
assert_eq "$BUILDER_AFTER" "$BUILDER_BEFORE" \
    "SBI06d the builder script itself is byte-unchanged (this suite never edits and reverts it)"

# Positive control for SBI06b: the fingerprint function distinguishes real trees, so an
# equal fingerprint means "unchanged" rather than "the function always returns the same".
EMPTY_DIR="${TMP}/empty"
mkdir -p "$EMPTY_DIR"
if [[ "$(tree_fingerprint "$EMPTY_DIR")" != "$REPO_SKILLS_AFTER" ]]; then
    pass "SBI06e positive control: tree_fingerprint distinguishes an empty tree from canonical/skills/"
else
    fail "SBI06e positive control: tree_fingerprint returns the same value for an empty tree"
fi

# ---------------------------------------------------------------------------
# SBI08 -- teardown, proved rather than declared.
#
# This suite cannot assert `test ! -e "$TMP"` about itself: its own root is removed by
# the EXIT trap, which fires after the last assertion. So the IDIOM is proved instead,
# in a child process that exits NON-ZERO -- the case that actually matters, since a
# teardown that only runs on success leaks a directory on every failure. The path is
# never printed, keeping this suite's output identical run to run.
# ---------------------------------------------------------------------------
CHILD_PATH_FILE="${TMP}/child-scratch-path"
bash -c '
    set -uo pipefail
    T=$(mktemp -d)
    trap "rm -rf \"$T\"" EXIT
    printf "%s" "$T" > "$1"
    exit 1
' _ "$CHILD_PATH_FILE"
CHILD_RC=$?
CHILD_PATH=$(cat "$CHILD_PATH_FILE" 2>/dev/null || true)
if [[ "$CHILD_RC" -ne 0 && -n "$CHILD_PATH" && ! -e "$CHILD_PATH" ]]; then
    pass "SBI08a the mktemp -d + trap idiom removes its scratch root even on a NON-ZERO exit (test ! -e on the recorded path)"
else
    fail "SBI08a the mktemp -d + trap idiom removes its scratch root on a non-zero exit -- child rc=${CHILD_RC}, path recorded=$([[ -n "$CHILD_PATH" ]] && echo yes || echo no), still present=$([[ -e "$CHILD_PATH" ]] && echo yes || echo no)"
fi
# Negative control: without the trap, the same child leaks its directory -- so SBI08a
# is testing the trap and not merely the fact that mktemp paths vanish on their own.
bash -c '
    set -uo pipefail
    T=$(mktemp -d)
    printf "%s" "$T" > "$1"
    exit 1
' _ "${CHILD_PATH_FILE}.notrap"
NOTRAP_PATH=$(cat "${CHILD_PATH_FILE}.notrap" 2>/dev/null || true)
if [[ -n "$NOTRAP_PATH" && -e "$NOTRAP_PATH" ]]; then
    pass "SBI08b negative control: the same child WITHOUT the trap leaks its scratch root"
    rm -rf "$NOTRAP_PATH"
else
    fail "SBI08b negative control: the trap-less child's directory vanished anyway, so SBI08a proves nothing"
fi
# This suite's own EXIT trap is installed on its scratch root.
TRAP_SPEC=$(trap -p EXIT)
assert_output_contains "$TRAP_SPEC" "rm -rf" \
    "SBI08c this suite has an EXIT trap that removes its own scratch root"

# ---------------------------------------------------------------------------
# SBI07 -- the override contract itself.
# ---------------------------------------------------------------------------
if [[ "$BUILDER_FROM_ENV" -eq 0 ]]; then
    assert_eq "$BUILDER" "$DEFAULT_BUILDER" \
        "SBI07a with no environment override, BUILDER resolves to the repository's own builder"
else
    log "BUILDER was overridden from the environment: ${BUILDER}"
    pass "SBI07a BUILDER override honoured from the environment (default-resolution check n/a this run)"
fi

echo ""
test_summary
exit $?
