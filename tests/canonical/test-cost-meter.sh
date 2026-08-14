#!/usr/bin/env bash
# test-cost-meter.sh — guards tests/cost-meter.py, the static token-cost
# inventory + regression gate for the AID instruction surface.
#
# Rationale: the meter exists so a cost optimization can be PROVEN rather than
# argued. That only holds if the meter itself is trustworthy, so this suite pins
# the properties the gate depends on:
#   - determinism    two collects of an unchanged tree are byte-identical
#                    (otherwise every diff is noise and the gate cries wolf)
#   - sensitivity    planted growth FAILS with exit 1
#                    (otherwise the gate is decorative)
#   - directionality a SHRINK passes and is reported as a reduction
#                    (otherwise the gate blocks the very cuts it exists to enable)
#   - read-only      measuring a tree never modifies it
#
# Every mutation happens in a throwaway fixture under a temp dir, built by this
# suite rather than pointed at a work folder, so the suite depends on no
# transient state (CLAUDE.md transient-work-folder invariant).
#
# Usage:
#   bash test-cost-meter.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
METER="${REPO_ROOT}/tests/cost-meter.py"

echo "=== cost-meter guard ==="

assert_file_exists "$METER" "CM01 tests/cost-meter.py exists"

if ! command -v python3 >/dev/null 2>&1; then
    echo "SKIP: python3 unavailable — cost-meter suite cannot run"
    test_summary
    exit $?
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- fixture ----------------------------------------------------------------
# A minimal tree shaped like AID. Using a fixture rather than the real repo
# proves the meter works on any adopter repo, and lets us plant growth safely.
FIX="${TMP}/fixture"
mkdir -p "${FIX}/canonical/skills/aid-demo/references" \
         "${FIX}/canonical/aid/templates" \
         "${FIX}/canonical/agents/aid-x"

cat > "${FIX}/canonical/skills/aid-demo/SKILL.md" <<'EOF'
---
name: aid-demo
description: >
  A demo skill used only by the cost-meter test fixture.
allowed-tools: Read
---

# Demo

Delegates to `canonical/aid/templates/demo-engine.md`.
EOF

printf 'Body of a reference file.\n' > "${FIX}/canonical/skills/aid-demo/references/state-go.md"
printf 'Engine body naming references/state-go.md\n' > "${FIX}/canonical/aid/templates/demo-engine.md"
printf 'Agent body.\n' > "${FIX}/canonical/agents/aid-x/AGENT.md"
printf 'Context file body.\n' > "${FIX}/AGENTS.md"

FIXTURE_SNAPSHOT() { (cd "$FIX" && find . -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum); }

# --- CM02..CM07 collect ------------------------------------------------------
python3 "$METER" collect --root "$FIX" --out "${TMP}/base.tsv" >/dev/null 2>&1
rc=$?
assert_exit_zero "$rc" "CM02 collect exits 0"
assert_file_exists "${TMP}/base.tsv" "CM03 collect writes the inventory TSV"
assert_file_exists "${TMP}/base.meta" "CM04 collect writes the .meta provenance sidecar"
assert_file_contains "${TMP}/base.tsv" "always-on" "CM05 inventory carries the always-on metric"
assert_file_contains "${TMP}/base.tsv" "skill-names-instr" \
    "CM06 inventory carries the depth-1 named-instruction metric"

# The fixture's SKILL.md names demo-engine.md, so depth-1 must be non-zero.
# This is the one assertion proving the reachability walk resolves a mention to
# a real file rather than silently finding nothing.
names_val="$(awk -F'\t' '$1=="skill-names-instr" && $2=="aid-demo" {print $3}' "${TMP}/base.tsv")"
if [[ "${names_val:-0}" -gt 0 ]]; then
    pass "CM07 depth-1 reachability resolves a named template (${names_val} chars)"
else
    fail "CM07 depth-1 reachability resolves a named template — got '${names_val:-<empty>}'"
fi

# --- CM08 determinism --------------------------------------------------------
python3 "$METER" collect --root "$FIX" --out "${TMP}/base2.tsv" >/dev/null 2>&1
if diff -q "${TMP}/base.tsv" "${TMP}/base2.tsv" >/dev/null 2>&1; then
    pass "CM08 two collects of an unchanged tree are byte-identical"
else
    fail "CM08 two collects of an unchanged tree are byte-identical — output differs"
fi

# --- CM09/CM10 unchanged tree passes ----------------------------------------
python3 "$METER" diff --baseline "${TMP}/base.tsv" --collect --root "$FIX" >"${TMP}/pass.txt" 2>&1
rc=$?
assert_exit_zero "$rc" "CM09 unchanged tree passes the gate"
assert_file_contains "${TMP}/pass.txt" "PASS" "CM10 unchanged tree reports PASS"

# --- CM11..CM13 planted growth fails ----------------------------------------
cp "${FIX}/canonical/skills/aid-demo/SKILL.md" "${TMP}/skill.bak"
python3 - "$FIX" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1]) / "canonical/skills/aid-demo/SKILL.md"
p.write_text(p.read_text().replace("description: >", "description: >\n  " + "PAD " * 40, 1))
PY
python3 "$METER" diff --baseline "${TMP}/base.tsv" --collect --root "$FIX" >"${TMP}/fail.txt" 2>&1
rc=$?
assert_exit_eq "$rc" 1 "CM11 planted description growth exits 1"
assert_file_contains "${TMP}/fail.txt" "FAIL" "CM12 planted growth reports FAIL"
assert_file_contains "${TMP}/fail.txt" "skill-descriptions" \
    "CM13 failure names the always-on metric that grew"
cp "${TMP}/skill.bak" "${FIX}/canonical/skills/aid-demo/SKILL.md"

# --- CM14/CM15 a shrink passes and is reported ------------------------------
cp "${FIX}/AGENTS.md" "${TMP}/agents.bak"
printf 'x\n' > "${FIX}/AGENTS.md"
python3 "$METER" diff --baseline "${TMP}/base.tsv" --collect --root "$FIX" >"${TMP}/shrink.txt" 2>&1
rc=$?
assert_exit_zero "$rc" "CM14 a shrink passes (the gate must never block a cut)"
assert_file_contains "${TMP}/shrink.txt" "net reduction" \
    "CM15 a shrink is reported as a net reduction"
cp "${TMP}/agents.bak" "${FIX}/AGENTS.md"

# --- CM16 tolerance is honoured ---------------------------------------------
python3 - "$FIX" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1]) / "canonical/aid/templates/demo-engine.md"
p.write_text(p.read_text() + "aaaa")
PY
python3 "$METER" diff --baseline "${TMP}/base.tsv" --collect --root "$FIX" \
    --tolerance 100 >"${TMP}/tol.txt" 2>&1
rc=$?
assert_exit_zero "$rc" "CM16 growth within --tolerance passes"

# --- CM17 read-only ---------------------------------------------------------
before="$(FIXTURE_SNAPSHOT)"
python3 "$METER" report --root "$FIX" >/dev/null 2>&1
python3 "$METER" collect --root "$FIX" --out "${TMP}/ro.tsv" >/dev/null 2>&1
after="$(FIXTURE_SNAPSHOT)"
assert_eq "$after" "$before" "CM17 measuring a tree never modifies it"

# --- CM19..CM24 the gate model -----------------------------------------------
# The model's absolute output is indicative, so the properties worth pinning are
# the ones a decision rests on: it runs, it prices both shapes, the batched shape
# is cheaper, and it scales with the multipliers it claims to model.
python3 "$METER" model --root "$FIX" --shape today --shape batched >"${TMP}/model.txt" 2>&1
rc=$?
assert_exit_zero "$rc" "CM19 model exits 0"
assert_file_contains "${TMP}/model.txt" "shape: today" "CM20 model prices the 'today' shape"
assert_file_contains "${TMP}/model.txt" "shape: batched" "CM21 model prices the 'batched' shape"
assert_file_contains "${TMP}/model.txt" "saves" \
    "CM22 batched is cheaper than today (reports a saving, not a cost)"

# CM23 -- cost must scale with review cycles. If it does not, the model is not
# actually modelling the multiplier that motivates the whole change.
one=$(python3 "$METER" model --root "$FIX" --shape today --cycles 1 2>/dev/null \
      | awk '/^  TOTAL/{gsub(/,/,"",$2); print $2; exit}')
ten=$(python3 "$METER" model --root "$FIX" --shape today --cycles 10 2>/dev/null \
      | awk '/^  TOTAL/{gsub(/,/,"",$2); print $2; exit}')
if [[ -n "${one:-}" && -n "${ten:-}" ]] && (( ten > one )); then
    pass "CM23 modelled cost rises with --cycles (${one} -> ${ten})"
else
    fail "CM23 modelled cost rises with --cycles — got '${one:-?}' -> '${ten:-?}'"
fi

# CM24 -- and with feature count, which is the per-feature gate fan-out.
f1=$(python3 "$METER" model --root "$FIX" --shape today --features 1 2>/dev/null \
     | awk '/^  TOTAL/{gsub(/,/,"",$2); print $2; exit}')
f8=$(python3 "$METER" model --root "$FIX" --shape today --features 8 2>/dev/null \
     | awk '/^  TOTAL/{gsub(/,/,"",$2); print $2; exit}')
if [[ -n "${f1:-}" && -n "${f8:-}" ]] && (( f8 > f1 )); then
    pass "CM24 modelled cost rises with --features (${f1} -> ${f8})"
else
    fail "CM24 modelled cost rises with --features — got '${f1:-?}' -> '${f8:-?}'"
fi

# CM25 -- dispatch floors come from the tree, not constants: shrinking an agent
# definition must lower the modelled cost. This is what makes the model able to
# score a real optimization instead of just describing one.
mkdir -p "${FIX}/canonical/agents/aid-reviewer" "${FIX}/canonical/aid/templates"
printf '%s\n' "$(head -c 20000 /dev/zero | tr '\0' 'x')" > "${FIX}/canonical/agents/aid-reviewer/AGENT.md"
big=$(python3 "$METER" model --root "$FIX" --shape today 2>/dev/null \
      | awk '/^  TOTAL/{gsub(/,/,"",$2); print $2; exit}')
printf 'x\n' > "${FIX}/canonical/agents/aid-reviewer/AGENT.md"
small=$(python3 "$METER" model --root "$FIX" --shape today 2>/dev/null \
        | awk '/^  TOTAL/{gsub(/,/,"",$2); print $2; exit}')
if [[ -n "${big:-}" && -n "${small:-}" ]] && (( small < big )); then
    pass "CM25 shrinking aid-reviewer/AGENT.md lowers modelled cost (${big} -> ${small})"
else
    fail "CM25 shrinking an agent definition must lower modelled cost — got '${big:-?}' -> '${small:-?}'"
fi
rm -f "${FIX}/canonical/agents/aid-reviewer/AGENT.md"

# --- CM26/CM27 --from-work must not present defaults as measurements --------
# A flat/Lite work has no features/ and no BLUEPRINT, so SPEC/PLAN/BP fall back
# to built-in defaults. Reporting those under the heading "artifact sizes from:
# <that work>" without marking them is how a fabricated number survives into a
# decision.
FW="${TMP}/flatwork"
mkdir -p "${FW}/tasks/task-001"
printf 'requirements body\n' > "${FW}/REQUIREMENTS.md"
printf 'detail body\n' > "${FW}/tasks/task-001/DETAIL.md"
python3 "$METER" model --root "$FIX" --from-work "$FW" --shape today >"${TMP}/fw.txt" 2>&1
assert_file_contains "${TMP}/fw.txt" "built-in default used" \
    "CM26 fallback artifact sizes are disclosed, not passed off as measured"
assert_file_contains "${TMP}/fw.txt" "SPEC" "CM27 the fallback list names the absent artifact"

# --- CM18 the committed baseline is present and current ---------------------
# Advisory on drift by design: the meter exists to ENABLE cuts, so a shrunk tree
# must never fail CI. Only growth is reported for review.
assert_file_exists "${REPO_ROOT}/tests/cost-baseline.tsv" "CM18 repo baseline is committed"
if [[ -f "${REPO_ROOT}/tests/cost-baseline.tsv" ]]; then
    python3 "$METER" diff --baseline "${REPO_ROOT}/tests/cost-baseline.tsv" \
        --collect --root "$REPO_ROOT" >"${TMP}/repo.txt" 2>&1 || true
    if grep -q "GREW beyond tolerance" "${TMP}/repo.txt"; then
        echo "NOTE: canonical/ has grown since tests/cost-baseline.tsv was captured."
        echo "      Review the growth below, then re-collect if it is intended:"
        echo "      python3 tests/cost-meter.py collect --out tests/cost-baseline.tsv"
        grep '^  !' "${TMP}/repo.txt" | head -10
    fi
fi

test_summary
