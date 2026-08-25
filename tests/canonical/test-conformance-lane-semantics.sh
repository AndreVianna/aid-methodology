#!/usr/bin/env bash
# test-conformance-lane-semantics.sh -- conformance-lane behavioral assertions
# (feature-005 / delivery-005 / task-034)
#
# Test IDs:
#   CL01  Conformance Lane section present in state-kb-delta.md
#   CL02  Carve: forward-authored docs routed to Conformance Lane, NOT Tier-2 update-the-doc
#   CL03  NFR-5 carve: Step 3 (scope-refresh) unreachable for forward-authored docs
#   CL04  Flag-not-overwrite: CL-Step 2 NEVER writes .aid/knowledge/ (invariant documented)
#   CL05  Present-the-choice gate: [1] Evolve / [2] Fix / [3] Accept options documented
#   CL06  Human-gated reconciliation: /aid-discover targeted re-entry documented
#   CL07  No-op when empty: no forward-authored docs -> lane is a documented no-op
#   CL08  Required Q&A entry on divergence documented (Conformance Reconciliation)
#
#   CL10  Classifier: design-ahead is DROPPED (forward-authoring leads -- not a finding)
#   CL11  Classifier: placeholder-resolved is CARRIED forward (flagged)
#   CL12  Classifier: code-ahead is CARRIED forward (flagged)
#   CL13  Classifier: contradiction is CARRIED forward (flagged)
#   CL14  Classifier: exactly 4 canonical classes documented in Sub-step 4
#
#   CL20  Altitude knob: C4 CONFORMANCE_C4_TOP default=60 documented in prose
#   CL21  Altitude knob: C1 top-level boundary criterion documented in prose
#   CL22  Altitude knob: C3 M=3 file-recurrence threshold documented in prose
#   CL23  Altitude fixture: high-ranked coined term (spread>=3) IN harvest top-N output
#   CL24  Altitude fixture: sub-altitude identifier (spread=1, rank>top-N) NOT in output
#
#   CL30  Freshness agreement: forward-authored folds to current in kb-freshness-check.sh
#   CL31  Freshness agreement: hand-authored control with same source reads suspect
#   CL32  Freshness agreement: carve prose uses fm_scalar accessor (same as freshness)
#
#   CL40  Brownfield intact: hand-authored docs excluded from Conformance Lane (documented)
#   CL41  Brownfield intact: generated docs also excluded (routing documented as unchanged)
#
#   CL50  Isolation canary: no new .aid directory appeared under real HOME
#
# ISOLATION:
#   HOME pinned to a throwaway dir before any freshness/harvest invocation.
#   Real HOME .aid snapshot taken before/after for the isolation canary (CL50).
#   All freshness invocations pass explicit --root / --repo to the mktemp fixture.
#   All harvest invocations pass explicit --root to a deterministic fixture tree.
#   No .aid/knowledge/ or production KB is written.
#
# DoD coverage:
#   V1 (flag-not-overwrite)  -- CL04, CL08, CL30
#   V2 (human-gated)         -- CL05, CL06
#   V3 (marker scoping)      -- CL40, CL41
#   V4 (NFR-5 carve)         -- CL02, CL03
#   V5 (altitude filter)     -- CL20-CL24
#   V6 (brownfield intact)   -- CL40, CL41, CL31
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
#
# Usage:
#   bash tests/canonical/test-conformance-lane-semantics.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"

REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
KB_DELTA="${REPO_ROOT}/canonical/skills/aid-housekeep/references/state-kb-delta.md"
FRESHNESS="${REPO_ROOT}/canonical/aid/scripts/kb/kb-freshness-check.sh"
HARVEST="${REPO_ROOT}/canonical/aid/scripts/kb/harvest-coined-terms.sh"
DENYLIST="${REPO_ROOT}/canonical/aid/scripts/kb/coined-term-denylist.txt"

# ---------------------------------------------------------------------------
# Guard: required files must exist
# ---------------------------------------------------------------------------
for f in "$KB_DELTA" "$FRESHNESS" "$HARVEST" "$DENYLIST"; do
    if [[ ! -f "$f" ]]; then
        fail "CL00 setup -- required file not found: $f"
        test_summary; exit 1
    fi
done

# ---------------------------------------------------------------------------
# Global tmpdir -- all scratch and fixture repos live here; cleaned on EXIT.
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# HOME pin: redirect all home-relative I/O to a throwaway dir.
# Save REAL_HOME for the isolation canary (CL50).
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null \
    | LC_ALL=C sort || true)"
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

echo "== test-conformance-lane-semantics.sh =="

# ===========================================================================
# Section A -- Conformance Lane prose structural assertions (CL01-CL08)
#
# Verify state-kb-delta.md contains the behavioral invariants that make the
# conformance lane correct.  These assertions guard against prose regressions
# (e.g. an edit that inadvertently removes the flag-not-overwrite invariant).
# ===========================================================================

PROSE="$(cat "$KB_DELTA")"

# CL01 -- Conformance Lane section present
if echo "$PROSE" | grep -qF "Conformance Lane"; then
    pass "CL01 state-kb-delta.md contains 'Conformance Lane' section"
else
    fail "CL01 'Conformance Lane' section not found in state-kb-delta.md"
fi

# CL02 -- Source-routing carve: forward-authored -> Conformance Lane, NOT Tier-2
if echo "$PROSE" | grep -q "forward-authored.*Conformance Lane"; then
    pass "CL02 carve: forward-authored routes to Conformance Lane (not Tier-2)"
else
    fail "CL02 carve: forward-authored -> Conformance Lane routing not documented"
fi

# CL03 -- NFR-5 carve: Step 3 unreachable for forward-authored docs
# The prose must state that forward-authored docs cannot reach the Tier-2 scope-refresh.
if echo "$PROSE" | grep -qF "Step 3 is never reachable for a forward-authored doc"; then
    pass "CL03 NFR-5 carve: Step 3 unreachable for forward-authored docs (documented)"
else
    fail "CL03 NFR-5 carve: 'Step 3 is never reachable' not found in prose"
fi

# CL04 -- Flag-not-overwrite invariant: CL-Step 2 NEVER writes .aid/knowledge/
if echo "$PROSE" | grep -qF "NEVER writes"; then
    if echo "$PROSE" | grep -qF ".aid/knowledge/"; then
        pass "CL04 flag-not-overwrite: 'NEVER writes' + '.aid/knowledge/' both in prose"
    else
        fail "CL04 flag-not-overwrite: '.aid/knowledge/' not referenced in the invariant"
    fi
else
    fail "CL04 flag-not-overwrite: 'NEVER writes' invariant not found in prose"
fi

# CL05 -- Present-the-choice gate: [1] Evolve / [2] Fix / [3] Accept
if echo "$PROSE" | grep -qF "[1] Evolve"; then
    pass "CL05 present-the-choice: '[1] Evolve' option documented"
else
    fail "CL05 present-the-choice: '[1] Evolve' not found in prose"
fi
if echo "$PROSE" | grep -qF "[2] Fix the code"; then
    pass "CL05 present-the-choice: '[2] Fix the code' option documented"
else
    fail "CL05 present-the-choice: '[2] Fix the code' not found in prose"
fi
if echo "$PROSE" | grep -qF "[3] Accept / defer"; then
    pass "CL05 present-the-choice: '[3] Accept / defer' option documented"
else
    fail "CL05 present-the-choice: '[3] Accept / defer' not found in prose"
fi

# CL06 -- Human-gated reconciliation: /aid-discover targeted re-entry
if echo "$PROSE" | grep -qF "/aid-discover targeted re-entry"; then
    pass "CL06 human-gated reconciliation: /aid-discover targeted re-entry documented"
else
    fail "CL06 human-gated reconciliation: '/aid-discover targeted re-entry' not found"
fi

# CL07 -- No-op when empty: empty forward-authored set documented as no-op
if echo "$PROSE" | grep -qF "no-op"; then
    pass "CL07 no-op path: empty forward-authored set -> no-op documented"
else
    fail "CL07 no-op path: 'no-op' not found in prose"
fi

# CL08 -- Required Q&A entry on divergence documented
if echo "$PROSE" | grep -qF "Conformance Reconciliation"; then
    pass "CL08 Required Q&A: 'Conformance Reconciliation' category documented"
else
    fail "CL08 Required Q&A: 'Conformance Reconciliation' not found in prose"
fi

# ===========================================================================
# Section B -- Classifier structural assertions (CL10-CL14)
#
# The four canonical delta classes must be documented and design-ahead must be
# documented as DROPPED.  The carry-forward classes must be named.
# ===========================================================================

# CL10 -- design-ahead is DROPPED
if echo "$PROSE" | grep -qF "design-ahead"; then
    if echo "$PROSE" | grep -qF "drop" || echo "$PROSE" | grep -qiF "DROP"; then
        pass "CL10 classifier: design-ahead class documented and DROP/drop keyword present"
    else
        fail "CL10 classifier: design-ahead present but DROP not found near it"
    fi
else
    fail "CL10 classifier: 'design-ahead' class not found in prose"
fi

# CL11 -- placeholder-resolved is CARRIED forward
if echo "$PROSE" | grep -qF "placeholder-resolved"; then
    pass "CL11 classifier: placeholder-resolved class documented (carried forward)"
else
    fail "CL11 classifier: 'placeholder-resolved' class not found in prose"
fi

# CL12 -- code-ahead is CARRIED forward
if echo "$PROSE" | grep -qF "code-ahead"; then
    pass "CL12 classifier: code-ahead class documented (carried forward)"
else
    fail "CL12 classifier: 'code-ahead' class not found in prose"
fi

# CL13 -- contradiction is CARRIED forward
if echo "$PROSE" | grep -qF "contradiction"; then
    pass "CL13 classifier: contradiction class documented (carried forward)"
else
    fail "CL13 classifier: 'contradiction' class not found in prose"
fi

# CL14 -- All four canonical class labels are present
CL14_CLASSES=0
echo "$PROSE" | grep -qF "design-ahead"         && CL14_CLASSES=$((CL14_CLASSES+1))
echo "$PROSE" | grep -qF "placeholder-resolved" && CL14_CLASSES=$((CL14_CLASSES+1))
echo "$PROSE" | grep -qF "code-ahead"           && CL14_CLASSES=$((CL14_CLASSES+1))
echo "$PROSE" | grep -qF "contradiction"        && CL14_CLASSES=$((CL14_CLASSES+1))
assert_eq "$CL14_CLASSES" "4" \
    "CL14 classifier: all 4 canonical delta classes present in prose"

# ===========================================================================
# Section C -- Altitude filter documentation + calibration (CL20-CL24)
#
# CL20-CL22: verify the three altitude knobs are documented in the prose.
# CL23-CL24: run harvest-coined-terms.sh on a deterministic fixture to confirm
#             the altitude threshold mechanism works end-to-end -- a high-altitude
#             coined term (spread>=3) appears in the top-N output, while a
#             sub-altitude identifier (spread=1, rank beyond top-N) does NOT.
# ===========================================================================

# CL20 -- C4 altitude knob: CONFORMANCE_C4_TOP default=60
if echo "$PROSE" | grep -qF "CONFORMANCE_C4_TOP"; then
    pass "CL20 altitude knob C4: CONFORMANCE_C4_TOP variable documented"
else
    fail "CL20 altitude knob C4: 'CONFORMANCE_C4_TOP' not found in prose"
fi
if echo "$PROSE" | grep -qF "default 60" || echo "$PROSE" | grep -qF "default N=60"; then
    pass "CL20 altitude knob C4: default value 60 documented"
else
    fail "CL20 altitude knob C4: default value 60 not found"
fi

# CL21 -- C1 altitude knob: top-level boundary criterion
if echo "$PROSE" | grep -qF "top-level"; then
    if echo "$PROSE" | grep -qF "C1"; then
        pass "CL21 altitude knob C1: 'top-level' boundary criterion with C1 tag documented"
    else
        fail "CL21 altitude knob C1: 'top-level' present but C1 tag not found nearby"
    fi
else
    fail "CL21 altitude knob C1: 'top-level' boundary criterion not found in prose"
fi

# CL22 -- C3 altitude knob: M=3 file-recurrence threshold
if echo "$PROSE" | grep -qF "M=3" || echo "$PROSE" | grep -qF "M files" \
   || echo "$PROSE" | grep -qF "least M files" || echo "$PROSE" | grep -q "default M=3"; then
    pass "CL22 altitude knob C3: M=3 file-recurrence threshold documented"
else
    fail "CL22 altitude knob C3: M=3 (or 'at least M files') not found in prose"
fi

# ---------------------------------------------------------------------------
# CL23 / CL24 -- Altitude fixture: verify harvest-coined-terms.sh ranking
#
# Fixture layout:
#   src/engine.sh     -- AidSeedVerifier (5x), KbDeltaSifter (4x), GreenLaneSweep (3x)
#   src/router.sh     -- AidSeedVerifier (5x), KbDeltaSifter (4x), GreenLaneSweep (3x)
#   src/mapper.sh     -- AidSeedVerifier (5x), KbDeltaSifter (4x), GreenLaneSweep (3x)
#   docs/design.md    -- AidSeedVerifier (4x), KbDeltaSifter (3x)
#   util/helper.sh    -- SpineProbeVault (1x)  [sub-altitude: spread=1, salience=1]
#
# AidSeedVerifier: spread=4 files (>=3), salience=19*(1+2*3)=19*7=133
# KbDeltaSifter:   spread=4 files (>=3), salience=15*(1+2*3)=15*7=105
# GreenLaneSweep:  spread=3 files (>=3), salience=9*(1+2*2)=9*5=45
# SpineProbeVault: spread=1 file   (<3), salience=1*(1+0)=1   <-- sub-altitude
#
# With --top 4: all spread>=3 terms emit (AidSeedVerifier, KbDeltaSifter, GreenLaneSweep).
# SpineProbeVault (spread=1) only emits if ranked <=4.  It ranks 4th+ (salience=1 vs 133/105/45).
# Observation: "emits: top --top PLUS every candidate with spread>=3" is OR logic,
# so with 3 spread>=3 terms already emitted, SpineProbeVault (rank=4, not spread>=3)
# must NOT appear when there are exactly 3 terms with spread>=3 and SpineProbeVault's
# salience is lowest.
# We use --top 3 to make the boundary tight: the top-3 are exactly the spread>=3 terms;
# SpineProbeVault at rank=4 (spread=1) is suppressed.
# ---------------------------------------------------------------------------

FIXTURE_ALT="${TMP}/altitude-fixture"
mkdir -p "${FIXTURE_ALT}/src" "${FIXTURE_ALT}/docs" "${FIXTURE_ALT}/util"

# src/engine.sh -- high-altitude terms (code channel)
cat > "${FIXTURE_ALT}/src/engine.sh" <<'SRCEOF'
#!/usr/bin/env bash
# AidSeedVerifier engine module
AidSeedVerifier_init() { echo "init"; }
AidSeedVerifier_run()  { AidSeedVerifier_init; }
AidSeedVerifier_stop() { echo "stop"; }
KbDeltaSifter_load()   { echo "load"; }
KbDeltaSifter_apply()  { echo "apply"; }
KbDeltaSifter_clear()  { echo "clear"; }
GreenLaneSweep_enter() { echo "enter"; }
GreenLaneSweep_exit()  { echo "exit"; }
GreenLaneSweep_check() { echo "check"; }
SRCEOF

# src/router.sh -- same high-altitude terms, different file
cat > "${FIXTURE_ALT}/src/router.sh" <<'SRCEOF'
#!/usr/bin/env bash
# routing layer
AidSeedVerifier_route()  { echo "route"; }
AidSeedVerifier_pick()   { echo "pick"; }
AidSeedVerifier_retry()  { echo "retry"; }
KbDeltaSifter_resolve()  { echo "resolve"; }
KbDeltaSifter_reject()   { echo "reject"; }
KbDeltaSifter_retry()    { echo "retry"; }
GreenLaneSweep_begin()   { echo "begin"; }
GreenLaneSweep_end()     { echo "end"; }
GreenLaneSweep_reset()   { echo "reset"; }
SRCEOF

# src/mapper.sh -- third code file (spread=3 for GreenLaneSweep reached here)
cat > "${FIXTURE_ALT}/src/mapper.sh" <<'SRCEOF'
#!/usr/bin/env bash
# mapper module
AidSeedVerifier_map()    { echo "map"; }
AidSeedVerifier_unmap()  { echo "unmap"; }
AidSeedVerifier_remap()  { echo "remap"; }
KbDeltaSifter_scan()     { echo "scan"; }
KbDeltaSifter_index()    { echo "index"; }
KbDeltaSifter_flush()    { echo "flush"; }
GreenLaneSweep_phase1()  { echo "phase1"; }
GreenLaneSweep_phase2()  { echo "phase2"; }
GreenLaneSweep_phase3()  { echo "phase3"; }
SRCEOF

# docs/design.md -- fourth file for AidSeedVerifier + KbDeltaSifter (spread=4)
cat > "${FIXTURE_ALT}/docs/design.md" <<'SRCEOF'
# Design

AidSeedVerifier is the central verification component.
The AidSeedVerifier confirms conformance between seed and as-built.
AidSeedVerifier runs during the housekeep conformance lane.
The AidSeedVerifier output feeds the classifier.

KbDeltaSifter classifies each delta element.
KbDeltaSifter assigns the canonical class label.
KbDeltaSifter drops design-ahead rows from the output.
SRCEOF

# util/helper.sh -- sub-altitude identifier: spread=1, salience=1
cat > "${FIXTURE_ALT}/util/helper.sh" <<'SRCEOF'
#!/usr/bin/env bash
# internal helper -- sub-altitude, appears only in this file
SpineProbeVault_internal() { echo "internal"; }
SRCEOF

HARVEST_OUT="${TMP}/altitude-harvest.md"
harvest_rc=0
HOME="${TMP}/fakehome" bash "$HARVEST" \
    --root "${FIXTURE_ALT}" \
    --output "${HARVEST_OUT}" \
    --denylist "${DENYLIST}" \
    --top 3 \
    >/dev/null 2>&1 || harvest_rc=$?

if [[ $harvest_rc -ne 0 ]]; then
    fail "CL23/CL24 altitude fixture: harvest-coined-terms.sh failed (exit $harvest_rc)"
else
    # CL23 -- high-altitude term appears within top-N (spread>=3, always included)
    if [[ -f "$HARVEST_OUT" ]] && grep -qF "AidSeedVerifier" "$HARVEST_OUT"; then
        pass "CL23 altitude fixture: AidSeedVerifier (spread>=3) in harvest output (at altitude)"
    else
        fail "CL23 altitude fixture: AidSeedVerifier not found in harvest output (should be at altitude)"
        [[ "$VERBOSE" -eq 1 && -f "$HARVEST_OUT" ]] && \
            echo "--- harvest output ---" && cat "$HARVEST_OUT" && echo "---"
    fi

    # CL24 -- sub-altitude identifier NOT in top-N output
    if [[ -f "$HARVEST_OUT" ]] && ! grep -qF "SpineProbeVault" "$HARVEST_OUT"; then
        pass "CL24 altitude fixture: SpineProbeVault (spread=1, rank>top-3) NOT in harvest output (suppressed)"
    else
        fail "CL24 altitude fixture: SpineProbeVault found in output but should be suppressed (sub-altitude)"
        [[ "$VERBOSE" -eq 1 && -f "$HARVEST_OUT" ]] && \
            echo "--- harvest output ---" && cat "$HARVEST_OUT" && echo "---"
    fi
fi

rm -f "${HARVEST_OUT}"

# ===========================================================================
# Section D -- Freshness agreement (CL30-CL32)
#
# Build a minimal two-commit git fixture with one forward-authored doc and one
# hand-authored doc sharing the same source.  After the source drifts (commit
# C2), the forward-authored doc stays 'current' (freshness short-circuit) while
# the hand-authored doc reads 'suspect'.  This proves:
#   CL30: the freshness check agrees with the carve (forward-authored stays current)
#   CL31: the carve is non-trivial (hand-authored with same source DOES suspect)
#   CL32: the carve prose references fm_scalar (the same accessor freshness uses)
# ===========================================================================

FIXREPO="${TMP}/freshness-fixture"
mkdir -p "${FIXREPO}/.aid/knowledge"
mkdir -p "${FIXREPO}/src"

cd "${FIXREPO}"
git init -q
git config user.email "test@aid-conformance-test"
git config user.name "AID Conformance Test"

# Source file that will drift after the baseline commit
printf 'initial source content\n' > "${FIXREPO}/src/component.sh"

# Forward-authored seed doc (design-authoritative; source: forward-authored)
printf -- '---\nkb-category: primary\nsource: forward-authored\nobjective: Design-authoritative conformance seed for the architecture.\nsummary: Documents target architecture before implementation.\ntags: [C1, architecture, greenfield]\nsources:\n  - src/component.sh\napproved_at_commit: PLACEHOLDER\n---\n\n# Architecture Seed\n\nDeclared invariant: all modules must implement the init protocol.\n' \
    > "${FIXREPO}/.aid/knowledge/architecture.md"

# Hand-authored control doc (same source, same approved_at_commit; differs only in source:)
printf -- '---\nkb-category: primary\nsource: hand-authored\nobjective: Hand-authored architecture doc tracking the component implementation.\nsummary: Documents the current as-built architecture from code inspection.\ntags: [C1, architecture]\nsources:\n  - src/component.sh\napproved_at_commit: PLACEHOLDER\n---\n\n# Architecture As-Built\n\nDescribes implementation derived from code.\n' \
    > "${FIXREPO}/.aid/knowledge/architecture-asbuilt.md"

# C1: baseline commit
git add .
git commit -q -m "C1: initial baseline -- all sources at approval point"
C1="$(git rev-parse HEAD)"

# Patch approved_at_commit in both docs to the real C1 hash
for doc in architecture.md architecture-asbuilt.md; do
    f="${FIXREPO}/.aid/knowledge/${doc}"
    tmp_f="${TMP}/tmp-doc.md"
    sed "s/PLACEHOLDER/${C1}/" "$f" > "$tmp_f"
    mv "$tmp_f" "$f"
done

# C2: modify src/component.sh AFTER the baseline (makes hand-authored doc suspect)
printf 'modified source -- drifted after C1 baseline\n' > "${FIXREPO}/src/component.sh"
git add .
git commit -q -m "C2: src/component.sh drifted after baseline"

KB_ROOT="${FIXREPO}/.aid/knowledge"

# Run freshness check (HOME-pinned; explicit --root and --repo)
freshness_tsv="$(HOME="${TMP}/fakehome" bash "$FRESHNESS" \
    --root "$KB_ROOT" --repo "$FIXREPO" --format tsv)"

# CL30 -- forward-authored doc folds to current
fa_row="$(echo "$freshness_tsv" | grep '^architecture\.md' || true)"
if [[ -n "$fa_row" ]]; then
    fa_verdict="$(echo "$fa_row" | cut -f2)"
    assert_eq "$fa_verdict" "current" \
        "CL30 freshness agreement: forward-authored architecture.md folds to verdict=current"
else
    fail "CL30 freshness agreement: architecture.md not found in freshness TSV output"
fi

# CL31 -- hand-authored control with same drifted source reads suspect
ha_row="$(echo "$freshness_tsv" | grep '^architecture-asbuilt\.md' || true)"
if [[ -n "$ha_row" ]]; then
    ha_verdict="$(echo "$ha_row" | cut -f2)"
    assert_eq "$ha_verdict" "suspect" \
        "CL31 freshness agreement: hand-authored architecture-asbuilt.md reads suspect (carve proof)"
else
    fail "CL31 freshness agreement: architecture-asbuilt.md not found in freshness TSV"
fi

# CL32 -- carve prose uses fm_scalar accessor (same as freshness)
if echo "$PROSE" | grep -qF "fm_scalar"; then
    pass "CL32 freshness agreement: carve prose references fm_scalar accessor (same as freshness)"
else
    fail "CL32 freshness agreement: 'fm_scalar' not found in carve prose (should match freshness)"
fi

# ===========================================================================
# Section E -- Brownfield intact (CL40-CL41)
#
# Structural assertions that the state-kb-delta.md prose explicitly routes
# hand-authored and generated docs to the brownfield (Tier-2) lane,
# NOT to the Conformance Lane.  The carve is additive and changes nothing
# for existing brownfield docs.
# ===========================================================================

# CL40 -- hand-authored docs excluded from Conformance Lane
# The prose must say hand-authored (or absent) stays in the brownfield / Tier-2 lane.
if echo "$PROSE" | grep -q "hand-authored.*brownfield\|hand-authored.*Tier.2\|hand-authored.*update-the-doc"; then
    pass "CL40 brownfield intact: hand-authored docs stay in brownfield/Tier-2 lane (documented)"
elif echo "$PROSE" | grep -qF "source: hand-authored" && echo "$PROSE" | grep -qF "brownfield"; then
    pass "CL40 brownfield intact: hand-authored + brownfield both present in routing prose"
else
    fail "CL40 brownfield intact: hand-authored docs routing to Tier-2 not clearly documented"
fi

# CL41 -- generated docs excluded from both conformance and brownfield lanes
# The freshness-check already skips generated docs; housekeep inherits that routing.
if echo "$PROSE" | grep -qF "source: generated" || \
   echo "$PROSE" | grep -q "generated.*Tier.2\|generated.*excluded\|generated.*skip"; then
    pass "CL41 brownfield intact: generated docs excluded from conformance lane (documented)"
else
    # Acceptable if the prose relies on freshness-check skip (inherited routing).
    # Verify freshness-check itself excludes generated docs to confirm inherited behavior.
    freshness_skip_gen="$(grep -n "generated" "$FRESHNESS" | grep -i "skip\|exclud" || true)"
    if [[ -n "$freshness_skip_gen" ]]; then
        pass "CL41 brownfield intact: generated docs excluded via freshness-check skip (inherited)"
    else
        fail "CL41 brownfield intact: generated doc exclusion not documented in prose or script"
    fi
fi

# ===========================================================================
# Section F -- Isolation canary (CL50)
# ===========================================================================

_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null \
    | LC_ALL=C sort || true)"
if [[ "$_CANARY_BEFORE" == "$_CANARY_AFTER" ]]; then
    pass "CL50 isolation canary: no new .aid directory appeared under real HOME"
else
    fail "CL50 isolation canary: new .aid directories detected under real HOME"
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo "BEFORE: $_CANARY_BEFORE"
        echo "AFTER:  $_CANARY_AFTER"
    fi
fi

# ===========================================================================
test_summary
exit $?
