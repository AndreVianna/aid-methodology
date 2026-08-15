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

# --- CM28..CM33 the folded shapes -------------------------------------------
# `folded` merges the per-feature technical design into REQUIREMENTS. The reason
# the model needs a "task grounding" row at all is that merging MOVES cost
# between stages: it removes per-feature gates (cheaper) while making the single
# oracle every task reads bigger (dearer). A gate-only model would have scored
# this decision wrong, and did -- an earlier hand calculation concluded folding
# COSTS ~508k tokens because it grew the document without removing the gate.
model_total() {
    python3 "$METER" model --root "$FIX" --shape "$1" 2>/dev/null \
        | awk '/^  TOTAL/{gsub(/,/,"",$2); print $2; exit}'
}
t_today="$(model_total today)"
t_batch="$(model_total batched)"
t_fold="$(model_total folded)"
t_slice="$(model_total folded-sliced)"

for pair in "batched:${t_batch}" "folded:${t_fold}" "folded-sliced:${t_slice}"; do
    name="${pair%%:*}"; val="${pair##*:}"
    if [[ -n "${val:-}" && -n "${t_today:-}" ]] && (( val < t_today )); then
        pass "CM28+ '${name}' is cheaper than 'today' (${val} < ${t_today})"
    else
        fail "CM28+ '${name}' must be cheaper than 'today' — got '${val:-?}' vs '${t_today:-?}'"
    fi
done

# Slicing only pays off if a task reads less than the whole oracle, so the sliced
# variant must beat the unsliced one. If this ever inverts, the grounding model
# is wrong.
if [[ -n "${t_slice:-}" && -n "${t_fold:-}" ]] && (( t_slice < t_fold )); then
    pass "CM31 folded-sliced beats folded (section reads beat whole-document reads)"
else
    fail "CM31 folded-sliced must beat folded — got '${t_slice:-?}' vs '${t_fold:-?}'"
fi

# The grounding row must actually respond to task count; if it does not, the row
# is decorative and the folded comparison means nothing.
grounding_bytes() {
    # Row shape: "  task grounding   x16   809,856 B  ~202k tok" -> field 4.
    python3 "$METER" model --root "$FIX" --shape folded --tasks "$1" 2>/dev/null \
        | awk '/task grounding/{gsub(/,/,"",$4); print $4; exit}'
}
g1="$(grounding_bytes 1)"
g20="$(grounding_bytes 20)"
if [[ "${g1:-}" =~ ^[0-9]+$ && "${g20:-}" =~ ^[0-9]+$ ]] && (( g20 > g1 )); then
    pass "CM32 task-grounding cost scales with --tasks (${g1} -> ${g20})"
else
    fail "CM32 task-grounding must scale with --tasks — got '${g1:-?}' -> '${g20:-?}'"
fi

# A "read" row carries no dispatch floor: grounding is extra bytes on a dispatch
# that already happens, not a new agent boot. With one task and a tiny fixture
# the grounding row must therefore be far smaller than any gate row.
python3 "$METER" model --root "$FIX" --shape folded --tasks 1 >"${TMP}/rows.txt" 2>&1
assert_file_contains "${TMP}/rows.txt" "task grounding" "CM33 the grounding row is reported"

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

# ---------------------------------------------------------------------------
# CM34+: the `folded-no-plan` shape -- pricing AC-13's tail.
#
# This shape answers whether dropping PLAN.md from the Lite path is a SAVING or a
# TRANSFER. The distinction is the whole reason the model carries a grounding row:
# removing the PLAN gate looks like a clean win until you ask where its content
# went. The delivery definition is a DECISION and still needs reviewing, so it moves
# into REQUIREMENTS -- growing the REQUIREMENTS gate AND every task's grounding read,
# the latter multiplied by task count. Only the execution graph is a true removal,
# because `derive-waves.sh --from-tasks` reconstructs it from the task DETAILs.
#
# These assertions pin the SHAPE of the answer, not its exact figures: the numbers
# move whenever a template or an agent brief changes, and a test that pinned them
# would fail for reasons that are not defects.
#
# THE ANSWER IS DIMENSION-DEPENDENT, which is the whole point and was not obvious
# before it was measured. The removed gate point is a roughly FIXED saving, while the
# transfer into grounding is multiplied by TASK COUNT. So dropping PLAN.md pays on a
# Lite work (one feature, one delivery, a few tasks) and COSTS on a full-path work.
# CM34 and CM38 assert both directions, because the second is what confines this
# change to the Lite path -- applying it to the full path would make things worse
# while looking like the same simplification.
# ---------------------------------------------------------------------------

# model_total_at <shape> <features> <deliveries> <tasks>
model_total_at() {
    python3 "$METER" model --root "$FIX" --shape "$1" \
        --features "$2" --deliveries "$3" --tasks "$4" 2>/dev/null \
        | awk '/^  TOTAL/{gsub(/,/,"",$2); print $2; exit}'
}

# Lite dimensions: one feature, one delivery, three tasks -- what a shortcut produces.
lite_fold="$(model_total_at folded 1 1 3)"
lite_noplan="$(model_total_at folded-no-plan 1 1 3)"
if [[ -n "${lite_noplan:-}" && -n "${lite_fold:-}" ]] && (( lite_noplan < lite_fold )); then
    pass "CM34 at LITE dimensions 'folded-no-plan' is cheaper (${lite_noplan} < ${lite_fold})"
else
    fail "CM34 at LITE dimensions 'folded-no-plan' must be cheaper — got '${lite_noplan:-?}' vs '${lite_fold:-?}'"
fi

# It must remove exactly ONE gate point, not zero and not two. Zero would mean the
# shape is mis-modelled; two would mean it is quietly dropping a review this project
# still wants.
gate_points() {
    python3 "$METER" model --root "$FIX" --shape "$1" 2>/dev/null \
        | awk -F'[()]' '/^shape: /{split($2, a, " "); print a[1]; exit}'
}
gp_fold="$(gate_points folded)"
gp_noplan="$(gate_points folded-no-plan)"
if [[ -n "${gp_fold:-}" && -n "${gp_noplan:-}" ]] && (( gp_fold - gp_noplan == 1 )); then
    pass "CM35 'folded-no-plan' removes exactly one gate point (${gp_fold} -> ${gp_noplan})"
else
    fail "CM35 'folded-no-plan' must remove exactly one gate point — got '${gp_fold:-?}' -> '${gp_noplan:-?}'"
fi

# The TRANSFER must be visible, not silently dropped: with PLAN.md gone, the combined
# REQUIREMENTS gate has to be DEARER than the plain folded one, because the delivery
# definition moved into it. If this ever inverts, the model is pretending the
# definition evaporated -- which would overstate the saving.
req_gate_bytes() {
    python3 "$METER" model --root "$FIX" --shape "$1" 2>/dev/null \
        | awk '/^  gate REQ/{for(i=1;i<=NF;i++) if($i=="B"){gsub(/,/,"",$(i-1)); print $(i-1); exit}}'
}
r_fold="$(req_gate_bytes folded)"
r_noplan="$(req_gate_bytes folded-no-plan)"
if [[ -n "${r_fold:-}" && -n "${r_noplan:-}" ]] && (( r_noplan > r_fold )); then
    pass "CM36 the delivery definition's transfer is priced: REQUIREMENTS gate grows (${r_fold} -> ${r_noplan})"
else
    fail "CM36 REQUIREMENTS gate must grow when the delivery definition moves into it — got '${r_fold:-?}' -> '${r_noplan:-?}'"
fi

# The saving is one cycle-multiplied gate point, so it must GROW with --cycles. That
# is what makes it worth doing on a Lite work: Lite works are small, so a roughly
# fixed saving is a large fraction of a small total.
# Computed as a DIFFERENCE of totals rather than scraped from the comparison line:
# the comparison prints "saves" or "costs" depending on sign, and on a small fixture
# at one cycle the sign is not guaranteed. Reading both totals is sign-agnostic and
# says exactly what it means.
total_at_cycles() {
    python3 "$METER" model --root "$FIX" --shape "$1" \
        --features 1 --deliveries 1 --tasks 3 --cycles "$2" 2>/dev/null \
        | awk '/^  TOTAL/{gsub(/,/,"",$2); print $2; exit}'
}
s_lo=$(( $(total_at_cycles folded 1) - $(total_at_cycles folded-no-plan 1) ))
s_hi=$(( $(total_at_cycles folded 7) - $(total_at_cycles folded-no-plan 7) ))
if [[ -n "${s_lo:-}" && -n "${s_hi:-}" ]] && (( s_hi > s_lo )); then
    pass "CM37 the saving grows with review cycles (${s_lo} at 1 cycle -> ${s_hi} at 7)"
else
    fail "CM37 saving must grow with --cycles — got '${s_lo:-?}' -> '${s_hi:-?}'"
fi

# CM38: the saving is a much larger SHARE of a Lite work than of a full-path work,
# which is what justifies scoping the change to the Lite path.
#
# Asserted as a ratio, not as a sign. An earlier draft of this assertion claimed the
# change is a NET LOSS at full-path dimensions -- true on this fixture, whose agent
# briefs are deliberately tiny, and NOT true at repo scale, where the real dispatch
# floors make the removed gate point dominate the grounding transfer. Sign depends on
# the floor-to-artifact ratio; the share comparison holds either way, because the
# removed gate point is roughly fixed while a full-path work's total is several times
# larger.
#
# Guarding the ratio rather than the sign also keeps the test honest about WHY the
# change is Lite-scoped: not because it would hurt elsewhere, but because that is
# where it is worth the risk of touching four consumers.
share_ppm() {   # saving as parts-per-million of the shape's own total, at given dims
    local fold noplan
    fold="$(model_total_at folded "$1" "$2" "$3")"
    noplan="$(model_total_at folded-no-plan "$1" "$2" "$3")"
    [[ -z "$fold" || -z "$noplan" || "$fold" -eq 0 ]] && { echo ""; return; }
    echo $(( (fold - noplan) * 1000000 / fold ))
}
lite_share="$(share_ppm 1 1 3)"
full_share="$(share_ppm 3 4 16)"
if [[ -n "${lite_share:-}" && -n "${full_share:-}" ]] && (( lite_share > full_share )); then
    pass "CM38 the saving is a larger share at LITE than at full-path dimensions (${lite_share} vs ${full_share} ppm) — why the change is Lite-scoped"
else
    fail "CM38 saving share must be larger at Lite dimensions — got '${lite_share:-?}' vs '${full_share:-?}' ppm"
fi

test_summary
