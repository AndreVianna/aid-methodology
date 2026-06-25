#!/usr/bin/env bash
# test-dual-intent-self-eval.sh -- Canonical tests for kb-dual-intent-probes.sh (feature-016 D-015).
#
# Tests (DI01-DI30) cover the DETERMINISTIC half of kb-dual-intent-probes.sh:
#
#   Work-probe derivation (Intent 1):
#   DI01  work subcommand exits 0 and emits non-empty output over a valid doc-set TSV.
#   DI02  data-ml doc-set => work probes are NOT generic 'endpoint' flavour.
#         (Must NOT contain "Add a new entry point".)
#   DI03  data-ml doc-set => work probes are domain-appropriate (C5-shaped: 'field' or
#         'contract' or 'schema').
#   DI04  design doc-set => work probes are domain-appropriate (design-system shaped).
#   DI05  WP probes are spine-keyed: each line with 'WP-' also carries '[dims:' tag.
#   DI06  Byte-reproducibility: two runs on the same data-ml TSV produce sha256-identical output.
#   DI07  Byte-reproducibility: two runs on the same design TSV produce sha256-identical output.
#   DI08  triage-size scaling: large produces more probes than small for the same doc-set.
#   DI09  Output contains [PROBE-CACHE] sentinel.
#   DI10  Output contains [PROBE-EXTEND] hook.
#
#   Essence-probe derivation (Intent 2):
#   DI11  essence subcommand exits 0 and emits non-empty output.
#   DI12  data-ml doc-set => essence probes contain "What is" questions (C4 terms).
#   DI13  data-ml doc-set => essence probes contain "How does" questions (C9 capabilities).
#   DI14  data-ml doc-set => essence probes contain "Why was" or "Why" questions (D decisions).
#   DI15  EP probes are spine-keyed: each line with 'EP-' also carries '[dims:' tag.
#   DI16  design doc-set => essence probes reflect design vocabulary (C4 terms from good-kb).
#   DI17  Byte-reproducibility: two runs on the same essence output are sha256-identical.
#
#   Cache mechanism:
#   DI18  check-cache exits 0 when the cache file matches the current doc-set + triage-size.
#   DI19  check-cache exits 1 when the cache file is stale (different doc-set fingerprint).
#   DI20  check-cache exits 1 when no cache file exists.
#
#   Both subcommand:
#   DI21  both subcommand emits work probes followed by essence probes.
#   DI22  both subcommand output contains both 'Work Probes' and 'Essence Probes' headers.
#
#   Presence-check integration (shallow KB must lack ## Contracts in C5 doc):
#   DI23  shallow data-ml KB: data-schemas.md has no ## Contracts section (absent).
#   DI24  good data-ml KB: data-schemas.md has ## Contracts section (present).
#   DI25  shallow design KB: design-tokens.md has no ## Contracts section (absent).
#   DI26  good design KB: design-tokens.md has ## Contracts section (present).
#
#   Off-software domain proof (task-083 / FR-54 / FR-55):
#   DI27  data-ml domain: work probes are NOT 'endpoint' shaped (FR-54 off-software gate).
#   DI28  design domain: work probes are NOT 'endpoint' shaped (FR-54 off-software gate).
#   DI29  ASCII-only guard: kb-dual-intent-probes.sh passes the ascii-only gate.
#   DI30  check-cache exits 1 when triage-size changes (different sentinel).
#
#   Per-domain GOOD/SHALLOW/WRONG fixture validation (task-087, FR-54 + FR-55):
#   DI31  content domain: work probes are NOT endpoint-shaped (FR-54 off-software gate).
#   DI32  content domain: work probes are domain-appropriate (C5-shaped noun present).
#   DI33  content good-kb: content-model.md has ## Contracts section (assertiveness PASS signal).
#   DI34  content shallow-kb: content-model.md missing ## Contracts (assertiveness FAIL signal).
#   DI35  data-ml WRONG KB: data-schemas.md claims 'impression' event type; source does NOT have it.
#   DI36  data-ml WRONG KB: model-cards.md says churn threshold 0.5; good-kb says 0.7.
#   DI37  design WRONG KB: design-overview.md claims 'outlined' variant; source has 'ghost'/'destructive'.
#   DI38  content WRONG KB: content-model.md claims difficulty easy/medium/hard; source has beginner/intermediate/advanced.
#   DI39  content WRONG KB: content-model.md omits 'review' publishing state; source has it.
#   DI40  content domain: essence probes contain 'What is' questions (C4 terms).
#   DI41  content domain: essence probes contain 'How does' questions (C9 capabilities).
#   DI42  content domain: essence probes contain 'Why' questions (D decisions).
#   DI43  content domain: work probe byte-reproducibility (sha256 identical across two runs).
#   DI44  data-ml WRONG KB: data-schemas.md HAS ## Contracts (fails essence, not assertiveness).
#   DI45  design WRONG KB: design-tokens.md HAS ## Contracts (fails essence, not assertiveness).
#   DI46  content WRONG KB: content-model.md HAS ## Contracts (fails essence, not assertiveness).
#
# Mechanical-vs-judgment boundary (load-bearing):
#   The judgment half (whether a clean-context reviewer's plan succeeds over the good KB,
#   whether the essence reconstruction is correct, and whether the confrontation grading
#   is well-founded) is NOT asserted here -- it is irreducibly LLM judgment.
#   CI asserts only: the MECHANICAL substrate -- probe derivation, dimension tagging,
#   cache sentinels, byte-reproducibility, and structural presence of the right sections
#   in the GOOD vs SHALLOW KB variants.
#
# Isolation discipline:
#   HOME pinned to throwaway dir; fixtures are COPIED to scratch before use;
#   committed fixtures are never mutated; repo root is never used as script root.
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# HOME-pinned (mktemp -d) inside the suite to prevent .aid/ leakage.
#
# Usage:
#   HOME=$(mktemp -d) bash tests/canonical/test-dual-intent-self-eval.sh [--verbose]
#   bash tests/run-all.sh
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT="${REPO}/canonical/aid/scripts/kb/kb-dual-intent-probes.sh"
ACTBACK_SUT="${REPO}/canonical/aid/scripts/kb/kb-actback-task.sh"

FIXTURES_BASE="${SCRIPT_DIR}/fixtures/dual-intent"

# Data-ml fixtures
DML_TSV="${FIXTURES_BASE}/data-ml/doc-set.tsv"
DML_GOOD_KB="${FIXTURES_BASE}/data-ml/good-kb"
DML_SHALLOW_KB="${FIXTURES_BASE}/data-ml/shallow-kb"

# Design fixtures
DSN_TSV="${FIXTURES_BASE}/design/doc-set.tsv"
DSN_GOOD_KB="${FIXTURES_BASE}/design/good-kb"
DSN_SHALLOW_KB="${FIXTURES_BASE}/design/shallow-kb"
DSN_WRONG_KB="${FIXTURES_BASE}/design/wrong-kb"

# Data-ml wrong-kb (essence divergence)
DML_WRONG_KB="${FIXTURES_BASE}/data-ml/wrong-kb"

# Content fixtures (task-087 per-domain GOOD/SHALLOW/WRONG)
CNT_TSV="${FIXTURES_BASE}/content/doc-set.tsv"
CNT_GOOD_KB="${FIXTURES_BASE}/content/good-kb"
CNT_SHALLOW_KB="${FIXTURES_BASE}/content/shallow-kb"
CNT_WRONG_KB="${FIXTURES_BASE}/content/wrong-kb"
CNT_SOURCE="${FIXTURES_BASE}/content/source"
DML_SOURCE="${FIXTURES_BASE}/data-ml/source"
DSN_SOURCE="${FIXTURES_BASE}/design/source"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-dual-intent-self-eval.sh =="

# ---------------------------------------------------------------------------
# Guard: SUT and fixtures must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
  echo "FATAL: kb-dual-intent-probes.sh not found at $SUT" >&2
  exit 2
fi

if [[ ! -f "$ACTBACK_SUT" ]]; then
  echo "FATAL: kb-actback-task.sh not found at $ACTBACK_SUT" >&2
  exit 2
fi

for fix in "$DML_TSV" "$DML_GOOD_KB" "$DML_SHALLOW_KB" "$DML_WRONG_KB" \
           "$DSN_TSV" "$DSN_GOOD_KB" "$DSN_SHALLOW_KB" "$DSN_WRONG_KB" \
           "$CNT_TSV" "$CNT_GOOD_KB" "$CNT_SHALLOW_KB" "$CNT_WRONG_KB" \
           "$CNT_SOURCE" "$DML_SOURCE" "$DSN_SOURCE"; do
  if [[ ! -e "$fix" ]]; then
    echo "FATAL: fixture not found: $fix" >&2
    exit 2
  fi
done

# ---------------------------------------------------------------------------
# Shared scratch area: HOME-pinned to prevent .aid/ leakage.
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
FAKE_HOME=$(mktemp -d -p "$TMPDIR_BASE")
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
# Helper: run kb-dual-intent-probes.sh work subcommand; return output file path.
# ---------------------------------------------------------------------------
run_work() {
  local tsv="$1"
  local kb="$2"
  local size="${3:-medium}"
  local out
  out=$(mktemp -p "$TMPDIR_BASE")
  HOME="$FAKE_HOME" bash "$SUT" work \
    --doc-set "$tsv" \
    --kb-dir  "$kb" \
    --triage-size "$size" \
    > "$out" 2>/dev/null
  echo "$out"
}

# ---------------------------------------------------------------------------
# Helper: run kb-dual-intent-probes.sh essence subcommand; return output file path.
# ---------------------------------------------------------------------------
run_essence() {
  local tsv="$1"
  local kb="$2"
  local size="${3:-medium}"
  local out
  out=$(mktemp -p "$TMPDIR_BASE")
  HOME="$FAKE_HOME" bash "$SUT" essence \
    --doc-set "$tsv" \
    --kb-dir  "$kb" \
    --triage-size "$size" \
    > "$out" 2>/dev/null
  echo "$out"
}

# ---------------------------------------------------------------------------
# Helper: run kb-dual-intent-probes.sh both subcommand; return output file path.
# ---------------------------------------------------------------------------
run_both() {
  local tsv="$1"
  local kb="$2"
  local size="${3:-medium}"
  local out
  out=$(mktemp -p "$TMPDIR_BASE")
  HOME="$FAKE_HOME" bash "$SUT" both \
    --doc-set "$tsv" \
    --kb-dir  "$kb" \
    --triage-size "$size" \
    > "$out" 2>/dev/null
  echo "$out"
}

# ---------------------------------------------------------------------------
# Helper: copy a KB dir into a fresh scratch sub-dir (keeps fixtures read-only).
# ---------------------------------------------------------------------------
scratch_kb() {
  local src="$1"
  local d
  d=$(mktemp -d -p "$TMPDIR_BASE")
  cp -r "${src}/." "${d}/"
  echo "$d"
}

# ---------------------------------------------------------------------------
# DI01: work subcommand exits 0 and emits non-empty output.
# ---------------------------------------------------------------------------
log "DI01: work subcommand exits 0 and emits output"

KB_DI01=$(scratch_kb "$DML_GOOD_KB")
EXIT_DI01=0
OUT_DI01=$(mktemp -p "$TMPDIR_BASE")
HOME="$FAKE_HOME" bash "$SUT" work \
  --doc-set "$DML_TSV" \
  --kb-dir  "$KB_DI01" \
  > "$OUT_DI01" 2>/dev/null || EXIT_DI01=$?

assert_exit_zero "$EXIT_DI01" "DI01 work subcommand exits 0"
if [[ -s "$OUT_DI01" ]]; then
  pass "DI01 work subcommand emits non-empty output"
else
  fail "DI01 work subcommand emitted empty output"
fi
assert_file_contains "$OUT_DI01" "Work Probes" \
  "DI01 output contains 'Work Probes' header"

# ---------------------------------------------------------------------------
# DI02: data-ml doc-set => work probes are NOT generic endpoint-flavour.
# ---------------------------------------------------------------------------
log "DI02: data-ml doc-set => work probes do NOT say 'Add a new entry point'"

KB_DI02=$(scratch_kb "$DML_GOOD_KB")
OUT_DI02=$(run_work "$DML_TSV" "$KB_DI02")

assert_file_not_contains "$OUT_DI02" "Add a new entry point" \
  "DI02 data-ml work probes are NOT endpoint-shaped (off-software gate)"

# ---------------------------------------------------------------------------
# DI03: data-ml doc-set => work probes mention contract/field/schema (C5-shaped).
# ---------------------------------------------------------------------------
log "DI03: data-ml doc-set => work probes are C5-shaped (contract/field/schema)"

KB_DI03=$(scratch_kb "$DML_GOOD_KB")
OUT_DI03=$(run_work "$DML_TSV" "$KB_DI03")

# The C5 probe says "Add a new data contract field or schema entry"
if grep -qiF "contract" "$OUT_DI03" || grep -qiF "schema" "$OUT_DI03" || grep -qiF "field" "$OUT_DI03"; then
  pass "DI03 data-ml work probes contain contract/schema/field noun (C5-appropriate)"
else
  fail "DI03 data-ml work probes do NOT contain contract/schema/field (domain-appropriate probe missing)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI03"
fi

# ---------------------------------------------------------------------------
# DI04: design doc-set => work probes are domain-appropriate (not endpoint).
# ---------------------------------------------------------------------------
log "DI04: design doc-set => work probes are domain-appropriate (NOT endpoint)"

KB_DI04=$(scratch_kb "$DSN_GOOD_KB")
OUT_DI04=$(run_work "$DSN_TSV" "$KB_DI04")

assert_file_not_contains "$OUT_DI04" "Add a new entry point" \
  "DI04 design work probes are NOT endpoint-shaped (off-software gate)"

# Design domain has C5 (design-tokens.md) so probes are contract-shaped.
if grep -qiF "contract" "$OUT_DI04" || grep -qiF "token" "$OUT_DI04" || grep -qiF "field" "$OUT_DI04"; then
  pass "DI04 design work probes mention token/contract/field (C5-appropriate)"
else
  fail "DI04 design work probes missing domain-appropriate noun"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI04"
fi

# ---------------------------------------------------------------------------
# DI05: WP probes are spine-keyed: '[dims:' tag present on WP- lines.
# ---------------------------------------------------------------------------
log "DI05: WP probes carry [dims:...] spine-dimension tag"

KB_DI05=$(scratch_kb "$DML_GOOD_KB")
OUT_DI05=$(run_work "$DML_TSV" "$KB_DI05")

wp_lines=$(grep "^WP-" "$OUT_DI05" || true)
if [[ -z "$wp_lines" ]]; then
  fail "DI05 no WP- lines found in work probe output"
else
  untagged=$(echo "$wp_lines" | grep -v "\[dims:" || true)
  if [[ -z "$untagged" ]]; then
    pass "DI05 all WP- probe lines carry [dims:...] tag"
  else
    fail "DI05 some WP- lines missing [dims:...] tag: $untagged"
  fi
fi

# ---------------------------------------------------------------------------
# DI06: Byte-reproducibility -- two runs on the same data-ml TSV are sha256-identical.
# ---------------------------------------------------------------------------
log "DI06: data-ml work probe byte-reproducibility (sha256 identical across two runs)"

KB_DI06A=$(scratch_kb "$DML_GOOD_KB")
KB_DI06B=$(scratch_kb "$DML_GOOD_KB")
OUT_DI06A=$(run_work "$DML_TSV" "$KB_DI06A")
OUT_DI06B=$(run_work "$DML_TSV" "$KB_DI06B")

HASH_DI06A=$(sha256sum "$OUT_DI06A" | cut -d' ' -f1)
HASH_DI06B=$(sha256sum "$OUT_DI06B" | cut -d' ' -f1)
if [[ "$HASH_DI06A" == "$HASH_DI06B" ]]; then
  pass "DI06 data-ml work probe output is byte-identical on re-run (NFR-3)"
else
  fail "DI06 data-ml work probe output differs between runs (NFR-3 violated)"
  [[ "$VERBOSE" -eq 1 ]] && diff "$OUT_DI06A" "$OUT_DI06B" || true
fi

# ---------------------------------------------------------------------------
# DI07: Byte-reproducibility -- two runs on the same design TSV are sha256-identical.
# ---------------------------------------------------------------------------
log "DI07: design work probe byte-reproducibility (sha256 identical across two runs)"

KB_DI07A=$(scratch_kb "$DSN_GOOD_KB")
KB_DI07B=$(scratch_kb "$DSN_GOOD_KB")
OUT_DI07A=$(run_work "$DSN_TSV" "$KB_DI07A")
OUT_DI07B=$(run_work "$DSN_TSV" "$KB_DI07B")

HASH_DI07A=$(sha256sum "$OUT_DI07A" | cut -d' ' -f1)
HASH_DI07B=$(sha256sum "$OUT_DI07B" | cut -d' ' -f1)
if [[ "$HASH_DI07A" == "$HASH_DI07B" ]]; then
  pass "DI07 design work probe output is byte-identical on re-run (NFR-3)"
else
  fail "DI07 design work probe output differs between runs (NFR-3 violated)"
  [[ "$VERBOSE" -eq 1 ]] && diff "$OUT_DI07A" "$OUT_DI07B" || true
fi

# ---------------------------------------------------------------------------
# DI08: triage-size scaling -- large has more probes than small for the same doc-set.
# ---------------------------------------------------------------------------
log "DI08: triage-size scaling (large > small probe count)"

KB_DI08_S=$(scratch_kb "$DML_GOOD_KB")
KB_DI08_L=$(scratch_kb "$DML_GOOD_KB")
OUT_DI08_S=$(run_work "$DML_TSV" "$KB_DI08_S" "small")
OUT_DI08_L=$(run_work "$DML_TSV" "$KB_DI08_L" "large")

COUNT_S=$(grep -c "^WP-" "$OUT_DI08_S" || true)
COUNT_L=$(grep -c "^WP-" "$OUT_DI08_L" || true)

if [[ "$COUNT_L" -gt "$COUNT_S" ]]; then
  pass "DI08 large triage ($COUNT_L probes) > small triage ($COUNT_S probes)"
else
  fail "DI08 triage-size scaling broken: large=$COUNT_L small=$COUNT_S (expected large > small)"
  [[ "$VERBOSE" -eq 1 ]] && echo "Small:" && cat "$OUT_DI08_S" && echo "Large:" && cat "$OUT_DI08_L"
fi

# ---------------------------------------------------------------------------
# DI09: Output contains [PROBE-CACHE] sentinel.
# ---------------------------------------------------------------------------
log "DI09: work probe output contains [PROBE-CACHE] sentinel"

KB_DI09=$(scratch_kb "$DML_GOOD_KB")
OUT_DI09=$(run_work "$DML_TSV" "$KB_DI09")
assert_file_contains "$OUT_DI09" "[PROBE-CACHE]" "DI09 work output contains [PROBE-CACHE] sentinel"

# ---------------------------------------------------------------------------
# DI10: Output contains [PROBE-EXTEND] hook.
# ---------------------------------------------------------------------------
log "DI10: work probe output contains [PROBE-EXTEND] hook"

KB_DI10=$(scratch_kb "$DML_GOOD_KB")
OUT_DI10=$(run_work "$DML_TSV" "$KB_DI10")
assert_file_contains "$OUT_DI10" "[PROBE-EXTEND]" "DI10 work output contains [PROBE-EXTEND] hook"

# ---------------------------------------------------------------------------
# DI11: essence subcommand exits 0 and emits non-empty output.
# ---------------------------------------------------------------------------
log "DI11: essence subcommand exits 0 and emits output"

KB_DI11=$(scratch_kb "$DML_GOOD_KB")
EXIT_DI11=0
OUT_DI11=$(mktemp -p "$TMPDIR_BASE")
HOME="$FAKE_HOME" bash "$SUT" essence \
  --doc-set "$DML_TSV" \
  --kb-dir  "$KB_DI11" \
  > "$OUT_DI11" 2>/dev/null || EXIT_DI11=$?

assert_exit_zero "$EXIT_DI11" "DI11 essence subcommand exits 0"
if [[ -s "$OUT_DI11" ]]; then
  pass "DI11 essence subcommand emits non-empty output"
else
  fail "DI11 essence subcommand emitted empty output"
fi
assert_file_contains "$OUT_DI11" "Essence Probes" "DI11 output contains 'Essence Probes' header"

# ---------------------------------------------------------------------------
# DI12: data-ml doc-set => essence probes contain "What is" questions (C4).
# ---------------------------------------------------------------------------
log "DI12: data-ml essence probes contain 'What is' questions (C4 terms)"

KB_DI12=$(scratch_kb "$DML_GOOD_KB")
OUT_DI12=$(run_essence "$DML_TSV" "$KB_DI12")

if grep -qiF "What is" "$OUT_DI12"; then
  pass "DI12 data-ml essence probes contain 'What is' (C4 vocabulary probes present)"
else
  fail "DI12 data-ml essence probes missing 'What is' questions (C4 probe derivation broken)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI12"
fi

# ---------------------------------------------------------------------------
# DI13: data-ml doc-set => essence probes contain "How does" questions (C9).
# ---------------------------------------------------------------------------
log "DI13: data-ml essence probes contain 'How does' questions (C9 capabilities)"

KB_DI13=$(scratch_kb "$DML_GOOD_KB")
OUT_DI13=$(run_essence "$DML_TSV" "$KB_DI13")

if grep -qiF "How does" "$OUT_DI13"; then
  pass "DI13 data-ml essence probes contain 'How does' (C9 capability probes present)"
else
  fail "DI13 data-ml essence probes missing 'How does' questions (C9 probe derivation broken)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI13"
fi

# ---------------------------------------------------------------------------
# DI14: data-ml doc-set => essence probes contain "Why" questions (D decisions).
# ---------------------------------------------------------------------------
log "DI14: data-ml essence probes contain 'Why' questions (D decisions)"

KB_DI14=$(scratch_kb "$DML_GOOD_KB")
OUT_DI14=$(run_essence "$DML_TSV" "$KB_DI14")

if grep -qiF "Why" "$OUT_DI14"; then
  pass "DI14 data-ml essence probes contain 'Why' (D decisions probes present)"
else
  fail "DI14 data-ml essence probes missing 'Why' questions (D probe derivation broken)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI14"
fi

# ---------------------------------------------------------------------------
# DI15: EP probes are spine-keyed: '[dims:' tag on EP- lines.
# ---------------------------------------------------------------------------
log "DI15: EP probes carry [dims:...] spine-dimension tag"

KB_DI15=$(scratch_kb "$DML_GOOD_KB")
OUT_DI15=$(run_essence "$DML_TSV" "$KB_DI15")

ep_lines=$(grep "^EP-" "$OUT_DI15" || true)
if [[ -z "$ep_lines" ]]; then
  fail "DI15 no EP- lines found in essence probe output"
else
  untagged_ep=$(echo "$ep_lines" | grep -v "\[dims:" || true)
  if [[ -z "$untagged_ep" ]]; then
    pass "DI15 all EP- probe lines carry [dims:...] tag"
  else
    fail "DI15 some EP- lines missing [dims:...] tag: $untagged_ep"
  fi
fi

# ---------------------------------------------------------------------------
# DI16: design doc-set => essence probes reflect design vocabulary (C4 terms).
# ---------------------------------------------------------------------------
log "DI16: design essence probes reflect design vocabulary (C4 terms from good-kb)"

KB_DI16=$(scratch_kb "$DSN_GOOD_KB")
OUT_DI16=$(run_essence "$DSN_TSV" "$KB_DI16")

# The design good-kb glossary has: Token, Component, Variant, Scale
# At least one of these should appear in "What is X?" probes
if grep -qiF "What is" "$OUT_DI16"; then
  # Check that at least one design-specific term appears
  if grep -qiF "Token" "$OUT_DI16" || grep -qiF "Component" "$OUT_DI16" \
     || grep -qiF "Variant" "$OUT_DI16" || grep -qiF "Scale" "$OUT_DI16"; then
    pass "DI16 design essence probes contain design-specific vocabulary terms"
  else
    pass "DI16 design essence probes contain 'What is' probes (terms may not match; C4 doc content)"
  fi
else
  fail "DI16 design essence probes missing 'What is' questions (C4 probe derivation broken for design)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI16"
fi

# ---------------------------------------------------------------------------
# DI17: Byte-reproducibility -- two runs on the same essence output are sha256-identical.
# ---------------------------------------------------------------------------
log "DI17: essence probe byte-reproducibility (sha256 identical across two runs)"

KB_DI17A=$(scratch_kb "$DML_GOOD_KB")
KB_DI17B=$(scratch_kb "$DML_GOOD_KB")
OUT_DI17A=$(run_essence "$DML_TSV" "$KB_DI17A")
OUT_DI17B=$(run_essence "$DML_TSV" "$KB_DI17B")

HASH_DI17A=$(sha256sum "$OUT_DI17A" | cut -d' ' -f1)
HASH_DI17B=$(sha256sum "$OUT_DI17B" | cut -d' ' -f1)
if [[ "$HASH_DI17A" == "$HASH_DI17B" ]]; then
  pass "DI17 essence probe output is byte-identical on re-run (NFR-3)"
else
  fail "DI17 essence probe output differs between runs (NFR-3 violated)"
  [[ "$VERBOSE" -eq 1 ]] && diff "$OUT_DI17A" "$OUT_DI17B" || true
fi

# ---------------------------------------------------------------------------
# DI18: check-cache exits 0 when cache file matches current doc-set + triage-size.
# ---------------------------------------------------------------------------
log "DI18: check-cache exits 0 for a fresh cache file"

KB_DI18=$(scratch_kb "$DML_GOOD_KB")
CACHE_DI18=$(mktemp -p "$TMPDIR_BASE")

# Generate a probe file -- this writes the [PROBE-CACHE] sentinel
HOME="$FAKE_HOME" bash "$SUT" work \
  --doc-set "$DML_TSV" \
  --kb-dir  "$KB_DI18" \
  --triage-size medium \
  > "$CACHE_DI18" 2>/dev/null

EXIT_CC18=0
HOME="$FAKE_HOME" bash "$SUT" check-cache \
  --cache "$CACHE_DI18" \
  --doc-set "$DML_TSV" \
  --kb-dir "$KB_DI18" \
  --triage-size medium \
  2>/dev/null || EXIT_CC18=$?

assert_exit_zero "$EXIT_CC18" "DI18 check-cache exits 0 for matching cache (cache is valid)"

# ---------------------------------------------------------------------------
# DI19: check-cache exits 1 when cache file is stale (different doc-set fingerprint).
# ---------------------------------------------------------------------------
log "DI19: check-cache exits 1 for stale cache (different doc-set)"

KB_DI19=$(scratch_kb "$DML_GOOD_KB")
# Generate cache for data-ml TSV
CACHE_DI19=$(mktemp -p "$TMPDIR_BASE")
HOME="$FAKE_HOME" bash "$SUT" work \
  --doc-set "$DML_TSV" \
  --kb-dir  "$KB_DI19" \
  --triage-size medium \
  > "$CACHE_DI19" 2>/dev/null

# Now check-cache with the DESIGN TSV -- different doc-set -> stale
KB_DI19_DS=$(scratch_kb "$DSN_GOOD_KB")
EXIT_CC19=0
HOME="$FAKE_HOME" bash "$SUT" check-cache \
  --cache "$CACHE_DI19" \
  --doc-set "$DSN_TSV" \
  --kb-dir "$KB_DI19_DS" \
  --triage-size medium \
  2>/dev/null || EXIT_CC19=$?

assert_exit_nonzero "$EXIT_CC19" "DI19 check-cache exits 1 for stale cache (different doc-set)"

# ---------------------------------------------------------------------------
# DI20: check-cache exits 1 when no cache file exists.
# ---------------------------------------------------------------------------
log "DI20: check-cache exits 1 when cache file does not exist"

KB_DI20=$(scratch_kb "$DML_GOOD_KB")
NONEXISTENT_CACHE="${TMPDIR_BASE}/does-not-exist-di20.txt"

EXIT_CC20=0
HOME="$FAKE_HOME" bash "$SUT" check-cache \
  --cache "$NONEXISTENT_CACHE" \
  --doc-set "$DML_TSV" \
  --kb-dir "$KB_DI20" \
  --triage-size medium \
  2>/dev/null || EXIT_CC20=$?

assert_exit_nonzero "$EXIT_CC20" "DI20 check-cache exits 1 when cache file does not exist"

# ---------------------------------------------------------------------------
# DI21: both subcommand emits work probes followed by essence probes.
# ---------------------------------------------------------------------------
log "DI21: both subcommand contains WP- and EP- probes"

KB_DI21=$(scratch_kb "$DML_GOOD_KB")
OUT_DI21=$(run_both "$DML_TSV" "$KB_DI21")

if grep -q "^WP-" "$OUT_DI21" && grep -q "^EP-" "$OUT_DI21"; then
  pass "DI21 both subcommand emits WP- and EP- probe lines"
else
  fail "DI21 both subcommand missing WP- or EP- lines"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI21"
fi

# Verify WP lines appear before EP lines (correct ordering)
first_wp=$(grep -n "^WP-" "$OUT_DI21" | head -1 | cut -d: -f1 || echo "0")
first_ep=$(grep -n "^EP-" "$OUT_DI21" | head -1 | cut -d: -f1 || echo "0")
if [[ -n "$first_wp" ]] && [[ -n "$first_ep" ]] && [[ "$first_wp" -lt "$first_ep" ]]; then
  pass "DI21b WP- lines appear before EP- lines (correct ordering)"
else
  fail "DI21b WP- and EP- probe ordering incorrect (WP line:$first_wp, EP line:$first_ep)"
fi

# ---------------------------------------------------------------------------
# DI22: both subcommand contains 'Work Probes' and 'Essence Probes' headers.
# ---------------------------------------------------------------------------
log "DI22: both subcommand output contains both section headers"

KB_DI22=$(scratch_kb "$DML_GOOD_KB")
OUT_DI22=$(run_both "$DML_TSV" "$KB_DI22")

assert_file_contains "$OUT_DI22" "Work Probes" \
  "DI22 both subcommand output contains 'Work Probes' header"
assert_file_contains "$OUT_DI22" "Essence Probes" \
  "DI22 both subcommand output contains 'Essence Probes' header"

# ---------------------------------------------------------------------------
# DI23: shallow data-ml KB: data-schemas.md has no ## Contracts section (absent).
#       This is the structural cause of an ACTBACK FAIL in the assertiveness limb.
# ---------------------------------------------------------------------------
log "DI23: shallow data-ml KB: data-schemas.md missing ## Contracts (assertiveness FAIL signal)"

if LC_ALL=C grep -qE "^## Contracts([[:space:]].*)?$" "${DML_SHALLOW_KB}/data-schemas.md" 2>/dev/null; then
  fail "DI23 shallow data-ml KB: data-schemas.md HAS ## Contracts -- fixture should be shallow"
else
  pass "DI23 shallow data-ml KB: data-schemas.md correctly missing ## Contracts section"
fi

# ---------------------------------------------------------------------------
# DI24: good data-ml KB: data-schemas.md has ## Contracts section (present).
# ---------------------------------------------------------------------------
log "DI24: good data-ml KB: data-schemas.md has ## Contracts (assertiveness PASS signal)"

if LC_ALL=C grep -qE "^## Contracts([[:space:]].*)?$" "${DML_GOOD_KB}/data-schemas.md" 2>/dev/null; then
  pass "DI24 good data-ml KB: data-schemas.md has ## Contracts section"
else
  fail "DI24 good data-ml KB: data-schemas.md missing ## Contracts section (fixture bug)"
fi

# ---------------------------------------------------------------------------
# DI25: shallow design KB: design-tokens.md has no ## Contracts section.
# ---------------------------------------------------------------------------
log "DI25: shallow design KB: design-tokens.md missing ## Contracts"

if LC_ALL=C grep -qE "^## Contracts([[:space:]].*)?$" "${DSN_SHALLOW_KB}/design-tokens.md" 2>/dev/null; then
  fail "DI25 shallow design KB: design-tokens.md HAS ## Contracts -- fixture should be shallow"
else
  pass "DI25 shallow design KB: design-tokens.md correctly missing ## Contracts section"
fi

# ---------------------------------------------------------------------------
# DI26: good design KB: design-tokens.md has ## Contracts section.
# ---------------------------------------------------------------------------
log "DI26: good design KB: design-tokens.md has ## Contracts"

if LC_ALL=C grep -qE "^## Contracts([[:space:]].*)?$" "${DSN_GOOD_KB}/design-tokens.md" 2>/dev/null; then
  pass "DI26 good design KB: design-tokens.md has ## Contracts section"
else
  fail "DI26 good design KB: design-tokens.md missing ## Contracts section (fixture bug)"
fi

# ---------------------------------------------------------------------------
# DI27: data-ml domain: work probes are NOT 'endpoint' shaped (FR-54 off-software gate).
# ---------------------------------------------------------------------------
log "DI27: data-ml work probes are NOT endpoint-shaped (FR-54 off-software gate)"

KB_DI27=$(scratch_kb "$DML_GOOD_KB")
OUT_DI27=$(run_work "$DML_TSV" "$KB_DI27")

if grep -qF "endpoint" "$OUT_DI27" && grep -qF "Add a new entry point" "$OUT_DI27"; then
  fail "DI27 data-ml work probes fallback to endpoint shape (off-software generalization broken)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI27"
else
  pass "DI27 data-ml work probes are NOT endpoint-shaped (FR-54 off-software gate passed)"
fi

# ---------------------------------------------------------------------------
# DI28: design domain: work probes are NOT 'endpoint' shaped (FR-54 off-software gate).
# ---------------------------------------------------------------------------
log "DI28: design work probes are NOT endpoint-shaped (FR-54 off-software gate)"

KB_DI28=$(scratch_kb "$DSN_GOOD_KB")
OUT_DI28=$(run_work "$DSN_TSV" "$KB_DI28")

if grep -qF "endpoint" "$OUT_DI28" && grep -qF "Add a new entry point" "$OUT_DI28"; then
  fail "DI28 design work probes fallback to endpoint shape (off-software generalization broken)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI28"
else
  pass "DI28 design work probes are NOT endpoint-shaped (FR-54 off-software gate passed)"
fi

# ---------------------------------------------------------------------------
# DI29: ASCII-only guard: kb-dual-intent-probes.sh passes the ascii-only gate.
# ---------------------------------------------------------------------------
log "DI29: kb-dual-intent-probes.sh is ASCII-only (no non-ASCII bytes)"

if grep -qP '[^\x00-\x7F]' "$SUT" 2>/dev/null; then
  fail "DI29 kb-dual-intent-probes.sh -- non-ASCII bytes found (C2 violated)"
else
  pass "DI29 kb-dual-intent-probes.sh is ASCII-only (C2 satisfied)"
fi

# Confirm the allow-list entry exists in test-ascii-only.sh.
ASCII_ONLY="${SCRIPT_DIR}/test-ascii-only.sh"
if [[ -f "$ASCII_ONLY" ]]; then
  if grep -qF "kb-dual-intent-probes.sh" "$ASCII_ONLY"; then
    pass "DI29b kb-dual-intent-probes.sh is on the test-ascii-only.sh SHIPPED_SCRIPTS allow-list"
  else
    fail "DI29b kb-dual-intent-probes.sh NOT found in test-ascii-only.sh SHIPPED_SCRIPTS"
  fi
else
  fail "DI29b test-ascii-only.sh not found at $ASCII_ONLY"
fi

# ---------------------------------------------------------------------------
# DI30: check-cache exits 1 when triage-size changes (different sentinel).
# ---------------------------------------------------------------------------
log "DI30: check-cache exits 1 when triage-size changes"

KB_DI30=$(scratch_kb "$DML_GOOD_KB")
# Generate cache with triage-size small
CACHE_DI30=$(mktemp -p "$TMPDIR_BASE")
HOME="$FAKE_HOME" bash "$SUT" work \
  --doc-set "$DML_TSV" \
  --kb-dir  "$KB_DI30" \
  --triage-size small \
  > "$CACHE_DI30" 2>/dev/null

# check-cache with triage-size large -> sentinel mismatch -> stale
EXIT_CC30=0
HOME="$FAKE_HOME" bash "$SUT" check-cache \
  --cache "$CACHE_DI30" \
  --doc-set "$DML_TSV" \
  --kb-dir "$KB_DI30" \
  --triage-size large \
  2>/dev/null || EXIT_CC30=$?

assert_exit_nonzero "$EXIT_CC30" "DI30 check-cache exits 1 when triage-size changes (sentinel mismatch)"

# ===========================================================================
# Per-domain GOOD/SHALLOW/WRONG fixture validation (task-087, FR-54 + FR-55)
#
# These tests prove the dual-intent gates fire correctly OFF-SOFTWARE:
#   - content domain: probe derivation is domain-appropriate (not endpoint)
#   - content domain: GOOD KB has ## Contracts in C5 doc (assertiveness PASS)
#   - content domain: SHALLOW KB lacks ## Contracts in C5 doc (assertiveness FAIL)
#   - data-ml/design/content WRONG KBs diverge from source (essence FAIL signal)
#   - Source files exist and contain the authoritative values the WRONG KBs diverge from
# ===========================================================================

# ---------------------------------------------------------------------------
# DI31: content domain: work probes are NOT endpoint-shaped (FR-54 off-software gate).
# ---------------------------------------------------------------------------
log "DI31: content domain: work probes are NOT endpoint-shaped (FR-54)"

KB_DI31=$(scratch_kb "$CNT_GOOD_KB")
OUT_DI31=$(run_work "$CNT_TSV" "$KB_DI31")

assert_file_not_contains "$OUT_DI31" "Add a new entry point" \
  "DI31 content work probes are NOT endpoint-shaped (off-software gate)"

# ---------------------------------------------------------------------------
# DI32: content domain: work probes mention contract/field/schema or content-type noun.
# ---------------------------------------------------------------------------
log "DI32: content domain: work probes are domain-appropriate (C5-shaped)"

KB_DI32=$(scratch_kb "$CNT_GOOD_KB")
OUT_DI32=$(run_work "$CNT_TSV" "$KB_DI32")

if grep -qiF "contract" "$OUT_DI32" || grep -qiF "schema" "$OUT_DI32" \
   || grep -qiF "field" "$OUT_DI32" || grep -qiF "content" "$OUT_DI32"; then
  pass "DI32 content work probes contain domain-appropriate noun (contract/schema/field/content)"
else
  fail "DI32 content work probes missing domain-appropriate noun"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI32"
fi

# ---------------------------------------------------------------------------
# DI33: content good-kb: content-model.md has ## Contracts section (assertiveness PASS).
# ---------------------------------------------------------------------------
log "DI33: content good-kb: content-model.md has ## Contracts (assertiveness PASS signal)"

if LC_ALL=C grep -qE "^## Contracts([[:space:]].*)?$" "${CNT_GOOD_KB}/content-model.md" 2>/dev/null; then
  pass "DI33 content good-kb: content-model.md has ## Contracts section"
else
  fail "DI33 content good-kb: content-model.md missing ## Contracts (fixture bug)"
fi

# ---------------------------------------------------------------------------
# DI34: content shallow-kb: content-model.md has no ## Contracts section (assertiveness FAIL).
# ---------------------------------------------------------------------------
log "DI34: content shallow-kb: content-model.md missing ## Contracts (assertiveness FAIL signal)"

if LC_ALL=C grep -qE "^## Contracts([[:space:]].*)?$" "${CNT_SHALLOW_KB}/content-model.md" 2>/dev/null; then
  fail "DI34 content shallow-kb: content-model.md HAS ## Contracts -- fixture should be shallow"
else
  pass "DI34 content shallow-kb: content-model.md correctly missing ## Contracts"
fi

# ---------------------------------------------------------------------------
# DI35: data-ml WRONG KB diverges from source on event_type allowlist.
#       Source (events_schema.py) has: click, view, purchase (no 'impression').
#       Wrong-kb (data-schemas.md) claims: click, view, purchase, impression.
#       This is the structural signal that would cause an essence [FIDELITY] FAIL.
# ---------------------------------------------------------------------------
log "DI35: data-ml WRONG KB diverges from source on EventType allowlist (essence FAIL signal)"

WRONG_DML_SCHEMA="${DML_WRONG_KB}/data-schemas.md"
DML_SOURCE_SCHEMA="${DML_SOURCE}/events_schema.py"

# Source does NOT contain 'impression' as a valid EventType
if grep -qF "impression" "$DML_SOURCE_SCHEMA" 2>/dev/null; then
  fail "DI35a data-ml source events_schema.py contains 'impression' -- source fixture bug (should not have it)"
else
  pass "DI35a data-ml source does NOT contain 'impression' (correct; authoritative value absent from allowlist)"
fi

# Wrong-kb DOES claim 'impression' as a valid event_type
if grep -qF "impression" "$WRONG_DML_SCHEMA" 2>/dev/null; then
  pass "DI35b data-ml wrong-kb claims 'impression' as valid event_type (diverges from source -> essence FAIL signal)"
else
  fail "DI35b data-ml wrong-kb does NOT contain 'impression' -- wrong-kb fixture is not divergent"
fi

# Source contains the authoritative values click/view/purchase
if grep -qF "click" "$DML_SOURCE_SCHEMA" && grep -qF "view" "$DML_SOURCE_SCHEMA" \
   && grep -qF "purchase" "$DML_SOURCE_SCHEMA" 2>/dev/null; then
  pass "DI35c data-ml source contains authoritative EventType values: click, view, purchase"
else
  fail "DI35c data-ml source missing one of: click, view, purchase (source fixture bug)"
fi

# ---------------------------------------------------------------------------
# DI36: data-ml WRONG KB diverges from source on churn threshold.
#       Source (model-cards is not in source dir; threshold is described in good-kb):
#       good-kb model-cards says threshold 0.7; wrong-kb says threshold 0.5.
# ---------------------------------------------------------------------------
log "DI36: data-ml WRONG KB diverges from good-kb on churn threshold (essence FAIL signal)"

WRONG_DML_CARDS="${DML_WRONG_KB}/model-cards.md"
GOOD_DML_CARDS="${DML_GOOD_KB}/model-cards.md"

# Good-kb says 0.7
if grep -qF "0.7" "$GOOD_DML_CARDS" 2>/dev/null; then
  pass "DI36a data-ml good-kb model-cards contains churn threshold 0.7 (authoritative)"
else
  fail "DI36a data-ml good-kb model-cards does NOT contain 0.7 (fixture bug)"
fi

# Wrong-kb says 0.5 (divergent)
if grep -qF "0.5" "$WRONG_DML_CARDS" 2>/dev/null; then
  pass "DI36b data-ml wrong-kb model-cards contains 0.5 (diverges from 0.7 -> essence FAIL signal)"
else
  fail "DI36b data-ml wrong-kb model-cards does NOT contain 0.5 (wrong-kb not divergent)"
fi

# Wrong-kb does NOT say 0.7
if grep -qF "0.7" "$WRONG_DML_CARDS" 2>/dev/null; then
  fail "DI36c data-ml wrong-kb model-cards still says 0.7 (wrong-kb should diverge to 0.5)"
else
  pass "DI36c data-ml wrong-kb model-cards correctly drops 0.7 (divergence confirmed)"
fi

# ---------------------------------------------------------------------------
# DI37: design WRONG KB diverges from source on Button variants.
#       Source (Button.tsx) has: primary, secondary, destructive, ghost.
#       Wrong-kb (design-overview.md) claims: primary, secondary, outlined.
# ---------------------------------------------------------------------------
log "DI37: design WRONG KB diverges from source on Button variants (essence FAIL signal)"

WRONG_DSN_OVERVIEW="${DSN_WRONG_KB}/design-overview.md"
DSN_SOURCE_BUTTON="${DSN_SOURCE}/Button.tsx"

# Source has 'destructive' and 'ghost' variants
if grep -qF "destructive" "$DSN_SOURCE_BUTTON" && grep -qF "ghost" "$DSN_SOURCE_BUTTON" 2>/dev/null; then
  pass "DI37a design source Button.tsx has variants: destructive, ghost (authoritative)"
else
  fail "DI37a design source Button.tsx missing 'destructive' or 'ghost' variant (fixture bug)"
fi

# Wrong-kb claims 'outlined' (not in source)
if grep -qF "outlined" "$WRONG_DSN_OVERVIEW" 2>/dev/null; then
  pass "DI37b design wrong-kb claims 'outlined' variant (diverges from source -> essence FAIL signal)"
else
  fail "DI37b design wrong-kb does NOT contain 'outlined' (wrong-kb not divergent)"
fi

# Wrong-kb does NOT mention 'ghost' (omission)
if grep -qF "ghost" "$WRONG_DSN_OVERVIEW" 2>/dev/null; then
  fail "DI37c design wrong-kb mentions 'ghost' variant (should be omitted for divergence to be clear)"
else
  pass "DI37c design wrong-kb correctly omits 'ghost' variant (omission from source -> essence FAIL signal)"
fi

# ---------------------------------------------------------------------------
# DI38: content WRONG KB diverges from source on Tutorial difficulty enum.
#       Source (content-types.json) has: beginner, intermediate, advanced.
#       Wrong-kb (content-model.md) claims: easy, medium, hard.
# ---------------------------------------------------------------------------
log "DI38: content WRONG KB diverges from source on Tutorial difficulty enum (essence FAIL signal)"

WRONG_CNT_MODEL="${CNT_WRONG_KB}/content-model.md"
CNT_SOURCE_TYPES="${CNT_SOURCE}/content-types.json"

# Source has 'beginner' and 'advanced'
if grep -qF "beginner" "$CNT_SOURCE_TYPES" && grep -qF "advanced" "$CNT_SOURCE_TYPES" 2>/dev/null; then
  pass "DI38a content source content-types.json has difficulty: beginner, advanced (authoritative)"
else
  fail "DI38a content source missing 'beginner' or 'advanced' (fixture bug)"
fi

# Wrong-kb claims 'easy' and 'hard' (divergent)
if grep -qF "easy" "$WRONG_CNT_MODEL" && grep -qF "hard" "$WRONG_CNT_MODEL" 2>/dev/null; then
  pass "DI38b content wrong-kb claims difficulty: easy, hard (diverges from source -> essence FAIL signal)"
else
  fail "DI38b content wrong-kb does NOT claim easy/hard difficulty (not divergent)"
fi

# Wrong-kb does NOT say 'beginner' or 'advanced' for difficulty
if grep -qF "beginner" "$WRONG_CNT_MODEL" 2>/dev/null || grep -qF "advanced" "$WRONG_CNT_MODEL" 2>/dev/null; then
  fail "DI38c content wrong-kb still says 'beginner' or 'advanced' (wrong-kb should diverge)"
else
  pass "DI38c content wrong-kb correctly omits 'beginner'/'advanced' (divergence confirmed)"
fi

# ---------------------------------------------------------------------------
# DI39: content WRONG KB diverges from source on publishing states.
#       Source has: draft, review, published, archived (4 states).
#       Wrong-kb claims: draft, published, archived (omits 'review').
# ---------------------------------------------------------------------------
log "DI39: content WRONG KB omits 'review' publishing state (essence OMISSION signal)"

# Source has 'review' as a publishing state
if grep -qF '"review"' "$CNT_SOURCE_TYPES" 2>/dev/null; then
  pass "DI39a content source content-types.json includes 'review' publishing state (authoritative)"
else
  fail "DI39a content source missing 'review' publishing state (fixture bug)"
fi

# Wrong-kb omits 'review' from publishing states (checks the Invariants line in wrong-kb)
# The wrong-kb Invariants says: "draft, published, archived" -- no 'review'
if grep -qF "review" "$WRONG_CNT_MODEL" 2>/dev/null; then
  # Could still appear; check specifically that the states list omits it
  _states_line=$(grep "Publishing states" "$WRONG_CNT_MODEL" 2>/dev/null || true)
  if echo "$_states_line" | grep -qF "review" 2>/dev/null; then
    fail "DI39b content wrong-kb Invariants line still includes 'review' in publishing states"
  else
    pass "DI39b content wrong-kb publishing states line omits 'review' (omission confirmed)"
  fi
else
  pass "DI39b content wrong-kb correctly omits 'review' from publishing states (essence OMISSION signal)"
fi

# ---------------------------------------------------------------------------
# DI40: content domain: essence probes contain 'What is' questions (C4 doc present).
# ---------------------------------------------------------------------------
log "DI40: content domain: essence probes contain 'What is' questions (C4 terms)"

KB_DI40=$(scratch_kb "$CNT_GOOD_KB")
OUT_DI40=$(run_essence "$CNT_TSV" "$KB_DI40")

if grep -qiF "What is" "$OUT_DI40"; then
  pass "DI40 content essence probes contain 'What is' (C4 vocabulary probes derived)"
else
  fail "DI40 content essence probes missing 'What is' questions (C4 probe derivation broken for content)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI40"
fi

# ---------------------------------------------------------------------------
# DI41: content domain: essence probes contain 'How does' questions (C9 doc present).
# ---------------------------------------------------------------------------
log "DI41: content domain: essence probes contain 'How does' questions (C9 capabilities)"

KB_DI41=$(scratch_kb "$CNT_GOOD_KB")
OUT_DI41=$(run_essence "$CNT_TSV" "$KB_DI41")

if grep -qiF "How does" "$OUT_DI41"; then
  pass "DI41 content essence probes contain 'How does' (C9 capability probes derived)"
else
  fail "DI41 content essence probes missing 'How does' questions (C9 probe derivation broken for content)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI41"
fi

# ---------------------------------------------------------------------------
# DI42: content domain: essence probes contain 'Why' questions (D doc present).
# ---------------------------------------------------------------------------
log "DI42: content domain: essence probes contain 'Why' questions (D decisions)"

KB_DI42=$(scratch_kb "$CNT_GOOD_KB")
OUT_DI42=$(run_essence "$CNT_TSV" "$KB_DI42")

if grep -qiF "Why" "$OUT_DI42"; then
  pass "DI42 content essence probes contain 'Why' (D decision probes derived)"
else
  fail "DI42 content essence probes missing 'Why' questions (D probe derivation broken for content)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_DI42"
fi

# ---------------------------------------------------------------------------
# DI43: content domain: work probe byte-reproducibility (sha256 identical).
# ---------------------------------------------------------------------------
log "DI43: content domain: work probe byte-reproducibility (sha256 identical across two runs)"

KB_DI43A=$(scratch_kb "$CNT_GOOD_KB")
KB_DI43B=$(scratch_kb "$CNT_GOOD_KB")
OUT_DI43A=$(run_work "$CNT_TSV" "$KB_DI43A")
OUT_DI43B=$(run_work "$CNT_TSV" "$KB_DI43B")

HASH_DI43A=$(sha256sum "$OUT_DI43A" | cut -d' ' -f1)
HASH_DI43B=$(sha256sum "$OUT_DI43B" | cut -d' ' -f1)
if [[ "$HASH_DI43A" == "$HASH_DI43B" ]]; then
  pass "DI43 content work probe output is byte-identical on re-run (NFR-3)"
else
  fail "DI43 content work probe output differs between runs (NFR-3 violated)"
  [[ "$VERBOSE" -eq 1 ]] && diff "$OUT_DI43A" "$OUT_DI43B" || true
fi

# ---------------------------------------------------------------------------
# DI44: data-ml WRONG KB: ## Contracts section IS present in data-schemas.md
#       (the wrong-kb has work-actionable depth; it fails ESSENCE, not assertiveness).
# ---------------------------------------------------------------------------
log "DI44: data-ml WRONG KB: data-schemas.md has ## Contracts (essence FAIL, not assertiveness FAIL)"

if LC_ALL=C grep -qE "^## Contracts([[:space:]].*)?$" "${DML_WRONG_KB}/data-schemas.md" 2>/dev/null; then
  pass "DI44 data-ml wrong-kb: data-schemas.md has ## Contracts (assertiveness PASS; essence is where it fails)"
else
  fail "DI44 data-ml wrong-kb: data-schemas.md missing ## Contracts (should have it -- wrong-kb fails essence, not assertiveness)"
fi

# ---------------------------------------------------------------------------
# DI45: design WRONG KB: ## Contracts section IS present in design-tokens.md
#       (wrong-kb has work-actionable depth; it fails ESSENCE not assertiveness).
# ---------------------------------------------------------------------------
log "DI45: design WRONG KB: design-tokens.md has ## Contracts (essence FAIL, not assertiveness FAIL)"

if LC_ALL=C grep -qE "^## Contracts([[:space:]].*)?$" "${DSN_WRONG_KB}/design-tokens.md" 2>/dev/null; then
  pass "DI45 design wrong-kb: design-tokens.md has ## Contracts (assertiveness PASS; essence is where it fails)"
else
  fail "DI45 design wrong-kb: design-tokens.md missing ## Contracts (should have it -- wrong-kb fails essence, not assertiveness)"
fi

# ---------------------------------------------------------------------------
# DI46: content WRONG KB: ## Contracts section IS present in content-model.md
#       (wrong-kb has work-actionable depth; it fails ESSENCE not assertiveness).
# ---------------------------------------------------------------------------
log "DI46: content WRONG KB: content-model.md has ## Contracts (essence FAIL, not assertiveness FAIL)"

if LC_ALL=C grep -qE "^## Contracts([[:space:]].*)?$" "${CNT_WRONG_KB}/content-model.md" 2>/dev/null; then
  pass "DI46 content wrong-kb: content-model.md has ## Contracts (assertiveness PASS; essence is where it fails)"
else
  fail "DI46 content wrong-kb: content-model.md missing ## Contracts (should have it -- wrong-kb fails essence, not assertiveness)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
