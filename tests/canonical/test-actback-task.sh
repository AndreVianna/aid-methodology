#!/usr/bin/env bash
# test-actback-task.sh -- Canonical tests for kb-actback-task.sh (f013, task-028).
#
# Tests (AT01-AT14) cover the DETERMINISTIC half of kb-actback-task.sh only:
# Tests (AT15-AT20) cover off-software domain firing (task-082, FR-53):
#   data-ml.tsv / design.tsv doc-sets prove the safeguard fires off-software.
#
#   Representative-task selection (function 1):
#   AT01  task subcommand exits 0 and emits output over a valid doc-set TSV.
#   AT02  KB with schemas.md => representative task body names 'contract' shape.
#   AT03  KB with module-map.md + coding-standards.md (no schemas) => 'module' shape.
#   AT04  KB with architecture.md + coding-standards.md (no schemas/module) => 'component'.
#   AT05  KB with feature-inventory.md only => 'feature' shape.
#   AT06  Default (no matching key filenames) => 'endpoint' shape.
#   AT07  Priority: schemas.md wins over module-map.md + coding-standards.md.
#   AT08  Byte-reproducibility: two runs on the same TSV produce sha256-identical output.
#
#   Operational-structure presence check (function 2):
#   AT09  check subcommand: coding-standards.md WITH ## Conventions => present.
#   AT10  check subcommand: module-map.md WITHOUT ## Conventions => absent.
#         (module-map.md IS an expected Conventions owner per the owning-table.)
#   AT11  Scoped: domain-glossary.md is NOT reported absent for Contracts
#         (domain-glossary.md is NOT a Contracts owner in the owning-table).
#   AT12  Scoped: tech-debt.md IS checked for Gotchas (expected owner); fixture
#         carries ## Gotchas => reported present.
#   AT13  Opt-in: a non-table doc that carries ## Conventions is reported present
#         (auto-detect ownership: section present => always emit a row).
#   AT14  ASCII-only guard: kb-actback-task.sh passes the ascii-only gate
#         (the allow-list entry added in task-028 is present and the file has no
#         non-ASCII bytes).
#
#   Off-software domain firing (task-082 / FR-53):
#   AT15  data-ml.tsv => task shape is NOT 'endpoint' (domain-appropriate: 'contract').
#   AT16  data-ml.tsv => presence check is non-empty (C5 data-schemas.md checked for
#         Contracts; C2 data-pipeline.md checked for Conventions/Invariants/Contracts;
#         C3 coding-standards.md checked for Conventions).
#   AT17  data-ml.tsv => byte-reproducibility: two runs produce sha256-identical output.
#   AT18  design.tsv => task shape is NOT 'endpoint' (domain-appropriate: 'contract').
#   AT19  design.tsv => presence check is non-empty (C5 design-tokens.md checked for
#         Contracts; C2 component-inventory.md checked for Conventions/Invariants/Contracts;
#         C3 design-principles.md checked for Conventions).
#   AT20  design.tsv => data-schemas.md / design-tokens.md are checked for Contracts
#         (C5 owning-table fires off-software; the row appears in the presence table).
#
# Boundary: this suite asserts the DETERMINISTIC/MECHANICAL half only.
#   - The SPIKE-A1 task-shape heuristic is calibrated judgment; tests AT02-AT07 assert
#     only the OUTPUT SHAPE header ("Task shape: <type>") and "Task:" line, not the
#     plan's accuracy or the heuristic's tuning correctness.
#   - No reference to f012's V-E family or the actback-pass/fail-KB corpus (delivery-006).
#   - Fixtures are small, in-suite, and ASCII-only; no committed fixture is mutated.
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# HOME-pinned (mktemp -d) inside the suite to prevent .aid/ leakage.
#
# Usage:
#   HOME=$(mktemp -d) bash tests/canonical/test-actback-task.sh [--verbose]
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
SUT="${REPO}/canonical/aid/scripts/kb/kb-actback-task.sh"

FIXTURES_BASE="${SCRIPT_DIR}/fixtures/actback-task"
KB_DIR="${FIXTURES_BASE}/kb"

# TSV fixtures
TSV_CONTRACT="${FIXTURES_BASE}/docset-contract.tsv"
TSV_MODULE="${FIXTURES_BASE}/docset-module.tsv"
TSV_COMPONENT="${FIXTURES_BASE}/docset-component.tsv"
TSV_FEATURE="${FIXTURES_BASE}/docset-feature.tsv"
TSV_ENDPOINT="${FIXTURES_BASE}/docset-endpoint.tsv"
TSV_CHECK="${FIXTURES_BASE}/docset-check.tsv"
TSV_OPTIN="${FIXTURES_BASE}/docset-optin.tsv"
# Off-software domain fixtures (task-082 / FR-53)
TSV_DATA_ML="${FIXTURES_BASE}/data-ml.tsv"
TSV_DESIGN="${FIXTURES_BASE}/design.tsv"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-actback-task.sh =="

# ---------------------------------------------------------------------------
# Guard: SUT and all fixture files must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
  echo "FATAL: kb-actback-task.sh not found at $SUT" >&2
  exit 2
fi

for fix in "$TSV_CONTRACT" "$TSV_MODULE" "$TSV_COMPONENT" "$TSV_FEATURE" \
           "$TSV_ENDPOINT" "$TSV_CHECK" "$TSV_OPTIN" \
           "$TSV_DATA_ML" "$TSV_DESIGN" \
           "${KB_DIR}/coding-standards.md" \
           "${KB_DIR}/schemas.md" \
           "${KB_DIR}/module-map.md" \
           "${KB_DIR}/tech-debt.md" \
           "${KB_DIR}/domain-glossary.md" \
           "${KB_DIR}/custom-doc.md"; do
  if [[ ! -f "$fix" ]]; then
    echo "FATAL: fixture not found: $fix" >&2
    exit 2
  fi
done

# ---------------------------------------------------------------------------
# Shared scratch area: fixtures are COPIED here before each invocation.
# The committed fixtures are static/read-only; only the copies are used at
# run time. Cleaned up on exit.
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
# Helper: copy the fixture KB dir into a fresh scratch sub-dir.
# Returns the scratch KB dir path via stdout.
# ---------------------------------------------------------------------------
scratch_kb() {
  local d
  d=$(mktemp -d -p "$TMPDIR_BASE")
  cp -r "${KB_DIR}/." "${d}/"
  echo "$d"
}

# ---------------------------------------------------------------------------
# Helper: run kb-actback-task.sh task subcommand; return output file path.
# Pins HOME to a throwaway dir to prevent .aid/ leakage.
# Usage: run_task <tsv> <kb_dir>
# ---------------------------------------------------------------------------
run_task() {
  local tsv="$1"
  local kb="$2"
  local out
  out=$(mktemp -p "$TMPDIR_BASE")
  HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" task \
    --doc-set "$tsv" \
    --kb-dir  "$kb" \
    > "$out" 2>/dev/null
  echo "$out"
}

# ---------------------------------------------------------------------------
# Helper: run kb-actback-task.sh check subcommand; return output file path.
# ---------------------------------------------------------------------------
run_check() {
  local tsv="$1"
  local kb="$2"
  local out
  out=$(mktemp -p "$TMPDIR_BASE")
  HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" check \
    --doc-set "$tsv" \
    --kb-dir  "$kb" \
    > "$out" 2>/dev/null
  echo "$out"
}

# ---------------------------------------------------------------------------
# AT01: task subcommand exits 0 and emits non-empty output over a valid TSV.
# ---------------------------------------------------------------------------
log "AT01: task subcommand exits 0 and emits output"

KB_AT01=$(scratch_kb)
EXIT_AT01=0
OUT_AT01=$(mktemp -p "$TMPDIR_BASE")
HOME=$(mktemp -d -p "$TMPDIR_BASE") bash "$SUT" task \
  --doc-set "$TSV_CONTRACT" \
  --kb-dir  "$KB_AT01" \
  > "$OUT_AT01" 2>/dev/null || EXIT_AT01=$?

assert_exit_zero "$EXIT_AT01" "AT01 task subcommand exits 0"
if [[ -s "$OUT_AT01" ]]; then
  pass "AT01 task subcommand emits non-empty output"
else
  fail "AT01 task subcommand emitted empty output"
fi
assert_file_contains "$OUT_AT01" "Representative Task Spec" \
  "AT01 output contains 'Representative Task Spec' header"

# ---------------------------------------------------------------------------
# AT02: schemas.md in doc-set => 'contract' task shape.
#
# The heuristic (SPIKE-A1) is documented and calibrated; this assertion checks
# only the MECHANICAL OUTPUT SHAPE: the "Task shape:" header and "Task:" line.
# It does NOT assert heuristic tuning correctness.
# ---------------------------------------------------------------------------
log "AT02: schemas.md => contract task shape"

KB_AT02=$(scratch_kb)
OUT_AT02=$(run_task "$TSV_CONTRACT" "$KB_AT02")

assert_file_contains "$OUT_AT02" "Task shape: contract" \
  "AT02 schemas.md doc-set => task shape is 'contract'"
assert_file_contains "$OUT_AT02" "Add a new field to a data contract or schema." \
  "AT02 contract task body contains expected task description"

# ---------------------------------------------------------------------------
# AT03: module-map.md + coding-standards.md (no schemas) => 'module' shape.
# ---------------------------------------------------------------------------
log "AT03: module-map.md + coding-standards.md => module task shape"

KB_AT03=$(scratch_kb)
OUT_AT03=$(run_task "$TSV_MODULE" "$KB_AT03")

assert_file_contains "$OUT_AT03" "Task shape: module" \
  "AT03 module-map+coding-standards doc-set => task shape is 'module'"
assert_file_contains "$OUT_AT03" "Wire a new module into the system." \
  "AT03 module task body contains expected task description"

# ---------------------------------------------------------------------------
# AT04: architecture.md + coding-standards.md (no schemas, no module-map) => 'component'.
# ---------------------------------------------------------------------------
log "AT04: architecture.md + coding-standards.md => component task shape"

KB_AT04=$(scratch_kb)
OUT_AT04=$(run_task "$TSV_COMPONENT" "$KB_AT04")

assert_file_contains "$OUT_AT04" "Task shape: component" \
  "AT04 architecture+coding-standards doc-set => task shape is 'component'"
assert_file_contains "$OUT_AT04" "Make a change that must follow the project's conventions." \
  "AT04 component task body contains expected task description (C3-seeded convention probe)"

# ---------------------------------------------------------------------------
# AT05: feature-inventory.md only => 'feature' shape.
# ---------------------------------------------------------------------------
log "AT05: feature-inventory.md only => feature task shape"

KB_AT05=$(scratch_kb)
OUT_AT05=$(run_task "$TSV_FEATURE" "$KB_AT05")

assert_file_contains "$OUT_AT05" "Task shape: feature" \
  "AT05 feature-inventory-only doc-set => task shape is 'feature'"
assert_file_contains "$OUT_AT05" "Add a new capability of the kind catalogued in feature-inventory.md." \
  "AT05 feature task body contains expected task description (C9-seeded capability probe)"

# ---------------------------------------------------------------------------
# AT06: Default (no key filenames match) => 'endpoint' shape.
# tech-debt.md is the only doc in the endpoint fixture; no heuristic matches.
# ---------------------------------------------------------------------------
log "AT06: no matching key filenames => endpoint (default) task shape"

KB_AT06=$(scratch_kb)
OUT_AT06=$(run_task "$TSV_ENDPOINT" "$KB_AT06")

assert_file_contains "$OUT_AT06" "Task shape: endpoint" \
  "AT06 default (no key filenames) => task shape is 'endpoint'"
assert_file_contains "$OUT_AT06" "Add a new entry point to the project." \
  "AT06 endpoint task body contains expected task description (fallback: no C5/C2/C3/C9)"

# ---------------------------------------------------------------------------
# AT07: Priority ordering -- schemas.md wins over module-map.md + coding-standards.md.
#
# A TSV containing both schemas.md AND module-map.md + coding-standards.md must
# produce 'contract' (schemas.md is the highest-priority heuristic match).
# ---------------------------------------------------------------------------
log "AT07: priority: schemas.md wins over module-map+coding-standards"

KB_AT07=$(scratch_kb)
# Build a combined TSV containing both contract and module triggers
TSV_PRIORITY="${TMPDIR_BASE}/docset-priority.tsv"
{
  printf 'filename\towner\tpresence\n'
  printf 'schemas.md\taid-researcher\tpresent\n'
  printf 'module-map.md\taid-researcher\tpresent\n'
  printf 'coding-standards.md\taid-researcher\tpresent\n'
} > "$TSV_PRIORITY"

OUT_AT07=$(run_task "$TSV_PRIORITY" "$KB_AT07")

assert_file_contains "$OUT_AT07" "Task shape: contract" \
  "AT07 schemas.md present => contract shape wins over module heuristic"
assert_file_not_contains "$OUT_AT07" "Task shape: module" \
  "AT07 module shape is NOT selected when schemas.md is also present"

# ---------------------------------------------------------------------------
# AT08: Byte-reproducibility -- two runs on the same inputs are sha256-identical.
#
# Uses the contract TSV (a typical multi-doc set).
# The representative-task output must be byte-for-byte identical.
# ---------------------------------------------------------------------------
log "AT08: byte-reproducibility (sha256 identical across two runs)"

KB_AT08A=$(scratch_kb)
KB_AT08B=$(scratch_kb)
OUT_AT08A=$(run_task "$TSV_CONTRACT" "$KB_AT08A")
OUT_AT08B=$(run_task "$TSV_CONTRACT" "$KB_AT08B")

HASH_AT08A=$(sha256sum "$OUT_AT08A" | cut -d' ' -f1)
HASH_AT08B=$(sha256sum "$OUT_AT08B" | cut -d' ' -f1)

if [[ "$HASH_AT08A" == "$HASH_AT08B" ]]; then
  pass "AT08 task output is byte-identical on re-run (sha256 match, NFR-3)"
else
  fail "AT08 task output differs between runs (sha256 mismatch, NFR-3 violated)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    diff "$OUT_AT08A" "$OUT_AT08B" || true
  fi
fi

# ---------------------------------------------------------------------------
# AT08b: Byte-reproducibility -- two runs of the check subcommand are sha256-identical.
#
# Verifies the operational-structure presence table (function 2) is also stable-sorted
# and byte-reproducible per task-028 AC4 (NFR-3).
# ---------------------------------------------------------------------------
log "AT08b: check subcommand byte-reproducibility (sha256 identical across two runs)"

KB_AT08bA=$(scratch_kb)
KB_AT08bB=$(scratch_kb)
OUT_AT08bA=$(run_check "$TSV_CHECK" "$KB_AT08bA")
OUT_AT08bB=$(run_check "$TSV_CHECK" "$KB_AT08bB")

HASH_AT08bA=$(sha256sum "$OUT_AT08bA" | cut -d' ' -f1)
HASH_AT08bB=$(sha256sum "$OUT_AT08bB" | cut -d' ' -f1)

if [[ "$HASH_AT08bA" == "$HASH_AT08bB" ]]; then
  pass "AT08b check output is byte-identical on re-run (sha256 match, NFR-3)"
else
  fail "AT08b check output differs between runs (sha256 mismatch, NFR-3 violated)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    diff "$OUT_AT08bA" "$OUT_AT08bB" || true
  fi
fi

# ---------------------------------------------------------------------------
# AT09: Presence check -- coding-standards.md WITH ## Conventions => 'present'.
#
# The check TSV includes coding-standards.md; the fixture KB doc carries
# ## Conventions. The presence check must report it as present.
# ---------------------------------------------------------------------------
log "AT09: coding-standards.md with ## Conventions => present"

KB_AT09=$(scratch_kb)
OUT_AT09=$(run_check "$TSV_CHECK" "$KB_AT09")

# Row format: | coding-standards.md | Conventions | present |
coding_conv_row=$(grep -F "coding-standards.md" "$OUT_AT09" | grep -F "Conventions" || true)
if echo "$coding_conv_row" | grep -qF "present"; then
  pass "AT09 coding-standards.md + ## Conventions => status 'present'"
else
  fail "AT09 coding-standards.md Conventions row -- expected 'present', got: $coding_conv_row"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT09"
fi

# ---------------------------------------------------------------------------
# AT10: Presence check -- module-map.md WITHOUT ## Conventions => 'absent'.
#
# module-map.md IS an expected Conventions owner per the owning-table
# (coding-standards.md, module-map.md, pipeline-contracts.md).
# The fixture KB doc intentionally carries NO named operational sections.
# ---------------------------------------------------------------------------
log "AT10: module-map.md without ## Conventions => absent"

KB_AT10=$(scratch_kb)
OUT_AT10=$(run_check "$TSV_CHECK" "$KB_AT10")

module_conv_row=$(grep -F "module-map.md" "$OUT_AT10" | grep -F "Conventions" || true)
if echo "$module_conv_row" | grep -qF "absent"; then
  pass "AT10 module-map.md without ## Conventions => status 'absent'"
else
  fail "AT10 module-map.md Conventions row -- expected 'absent', got: $module_conv_row"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT10"
fi

# ---------------------------------------------------------------------------
# AT11: Scoped -- domain-glossary.md is NOT reported absent for Contracts.
#
# domain-glossary.md is mapped in the owning-table as an Invariants owner (C4)
# but NOT as a Contracts owner. The presence check must NOT emit any row for
# (domain-glossary.md, Contracts, absent).
# This verifies the scoping rule prevents over-reporting legitimate absences.
# ---------------------------------------------------------------------------
log "AT11: domain-glossary.md is NOT reported absent for Contracts (scoped)"

KB_AT11=$(scratch_kb)
OUT_AT11=$(run_check "$TSV_CHECK" "$KB_AT11")

gloss_contracts_row=$(grep -F "domain-glossary.md" "$OUT_AT11" | grep -F "Contracts" || true)
if [[ -z "$gloss_contracts_row" ]]; then
  pass "AT11 domain-glossary.md has no Contracts row (not an expected Contracts owner)"
elif echo "$gloss_contracts_row" | grep -qF "absent"; then
  fail "AT11 domain-glossary.md -- over-reported Contracts absent (scoping violated)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT11"
else
  # If present row (opt-in), that is acceptable; it means someone added ## Contracts
  pass "AT11 domain-glossary.md has no absent Contracts row (opt-in present row only)"
fi

# Confirm domain-glossary.md IS reported for Invariants (it IS an expected owner).
gloss_inv_row=$(grep -F "domain-glossary.md" "$OUT_AT11" | grep -F "Invariants" || true)
if [[ -n "$gloss_inv_row" ]]; then
  pass "AT11b domain-glossary.md does have an Invariants row (expected owner)"
else
  fail "AT11b domain-glossary.md -- expected an Invariants row (expected owner), got none"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT11"
fi

# ---------------------------------------------------------------------------
# AT12: Scoped -- tech-debt.md IS checked for Gotchas (expected owner).
#
# tech-debt.md is the default Gotchas owner in the owning-table.
# The fixture carries ## Gotchas, so the row must say 'present'.
# ---------------------------------------------------------------------------
log "AT12: tech-debt.md IS checked for Gotchas; fixture has ## Gotchas => present"

KB_AT12=$(scratch_kb)
OUT_AT12=$(run_check "$TSV_CHECK" "$KB_AT12")

debt_gotcha_row=$(grep -F "tech-debt.md" "$OUT_AT12" | grep -F "Gotchas" || true)
if echo "$debt_gotcha_row" | grep -qF "present"; then
  pass "AT12 tech-debt.md with ## Gotchas => status 'present' (expected owner)"
else
  fail "AT12 tech-debt.md Gotchas row -- expected 'present', got: $debt_gotcha_row"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT12"
fi

# ---------------------------------------------------------------------------
# AT13: Opt-in auto-detect -- a non-table doc with ## Conventions => reported present.
#
# custom-doc.md is NOT in the default owning-table for any class. It carries
# ## Conventions. The presence check must auto-detect this and emit a 'present' row
# (opt-in ownership: section present => emit a row, even for non-table docs).
# The scoping rule says "don't emit absent for non-table docs"; it does NOT prevent
# emitting "present" when the section IS actually there.
# ---------------------------------------------------------------------------
log "AT13: non-table doc with ## Conventions => opt-in auto-detect (present row)"

KB_AT13=$(scratch_kb)
OUT_AT13=$(run_check "$TSV_OPTIN" "$KB_AT13")

custom_conv_row=$(grep -F "custom-doc.md" "$OUT_AT13" | grep -F "Conventions" || true)
if echo "$custom_conv_row" | grep -qF "present"; then
  pass "AT13 custom-doc.md (non-table) with ## Conventions => opt-in 'present' row"
else
  fail "AT13 custom-doc.md -- expected opt-in 'present' Conventions row, got: $custom_conv_row"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT13"
fi

# Also verify that custom-doc.md is NOT reported absent for classes it does NOT carry
# (Invariants, Gotchas, Contracts are not in the fixture doc and not in the owning-table).
for class_name in Invariants Gotchas Contracts; do
  absent_row=$(grep -F "custom-doc.md" "$OUT_AT13" | grep -F "$class_name" | grep -F "absent" || true)
  if [[ -z "$absent_row" ]]; then
    pass "AT13 custom-doc.md not over-reported absent for $class_name (not a table owner)"
  else
    fail "AT13 custom-doc.md -- over-reported $class_name absent (scoping violated): $absent_row"
  fi
done

# ---------------------------------------------------------------------------
# AT14: ASCII-only guard -- kb-actback-task.sh has no non-ASCII bytes.
#
# This mirrors what test-ascii-only.sh asserts (the allow-list entry is added in
# task-028). We assert the script passes here too so this suite stands alone.
# ---------------------------------------------------------------------------
log "AT14: kb-actback-task.sh is ASCII-only (no non-ASCII bytes)"

if grep -qP '[^\x00-\x7F]' "$SUT" 2>/dev/null; then
  fail "AT14 kb-actback-task.sh -- non-ASCII bytes found (C2 violated)"
else
  pass "AT14 kb-actback-task.sh is ASCII-only (C2 satisfied)"
fi

# Confirm the allow-list entry exists in test-ascii-only.sh.
ASCII_ONLY="${SCRIPT_DIR}/test-ascii-only.sh"
if [[ -f "$ASCII_ONLY" ]]; then
  if grep -qF "kb-actback-task.sh" "$ASCII_ONLY"; then
    pass "AT14b kb-actback-task.sh is on the test-ascii-only.sh SHIPPED_SCRIPTS allow-list"
  else
    fail "AT14b kb-actback-task.sh NOT found in test-ascii-only.sh SHIPPED_SCRIPTS"
  fi
else
  fail "AT14b test-ascii-only.sh not found at $ASCII_ONLY"
fi

# ---------------------------------------------------------------------------
# AT15: data-ml doc-set => task shape is NOT 'endpoint' (FR-53 off-software gate).
#
# data-ml.tsv contains data-schemas.md (C5), data-pipeline.md (C2),
# coding-standards.md (C3), model-cards.md (C9).  C5 is highest priority, so
# the shape must be 'contract' -- NOT 'endpoint' (the software-fallback guard).
# ---------------------------------------------------------------------------
log "AT15: data-ml.tsv => task shape is NOT 'endpoint' (off-software domain, FR-53)"

KB_AT15=$(scratch_kb)
OUT_AT15=$(run_task "$TSV_DATA_ML" "$KB_AT15")

if grep -qF "Task shape: endpoint" "$OUT_AT15"; then
  fail "AT15 data-ml.tsv -- task shape is 'endpoint' (off-software generalization broken)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT15"
else
  pass "AT15 data-ml.tsv => task shape is NOT 'endpoint' (FR-53 off-software gate passed)"
fi

assert_file_contains "$OUT_AT15" "Task shape: contract" \
  "AT15 data-ml.tsv => C5 data-schemas.md wins priority; shape is 'contract'"

# ---------------------------------------------------------------------------
# AT16: data-ml doc-set => presence check is non-empty (C5/C2/C3 owning-table fires).
#
# data-schemas.md (C5) -> expected for Conventions + Contracts.
# data-pipeline.md (C2) -> expected for Conventions + Invariants + Contracts.
# coding-standards.md (C3) -> expected for Conventions.
# model-cards.md (C9) -> no owning-table rows (C9 carries no operational classes).
# The presence table MUST be non-empty (>=1 row beyond the header).
# ---------------------------------------------------------------------------
log "AT16: data-ml.tsv => presence check is non-empty (C5/C2/C3 owning-table fires)"

KB_AT16=$(scratch_kb)
OUT_AT16=$(run_check "$TSV_DATA_ML" "$KB_AT16")

# Count data rows (exclude the header lines: "## Operational...", "", "| doc |...", "|---...")
row_count_16=$(grep -c "^| " "$OUT_AT16" || true)
# Subtract 1 for the "| doc | class | status |" header row
data_rows_16=$(( row_count_16 - 1 ))
if [[ "$data_rows_16" -gt 0 ]]; then
  pass "AT16 data-ml presence check is non-empty ($data_rows_16 data rows; C5/C2/C3 owning-table fired)"
else
  fail "AT16 data-ml presence check is empty (expected >=1 row for C5/C2/C3 docs)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT16"
fi

# Assert data-schemas.md (C5) appears with a Contracts row (the C5 owning-table fires).
schemas_contracts_row_16=$(grep -F "data-schemas.md" "$OUT_AT16" | grep -F "Contracts" || true)
if [[ -n "$schemas_contracts_row_16" ]]; then
  pass "AT16b data-schemas.md has a Contracts row in data-ml presence check (C5 owning-table)"
else
  fail "AT16b data-schemas.md -- no Contracts row in data-ml presence check (C5 owning-table missing)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT16"
fi

# Assert coding-standards.md (C3) appears with a Conventions row.
coding_conv_row_16=$(grep -F "coding-standards.md" "$OUT_AT16" | grep -F "Conventions" || true)
if [[ -n "$coding_conv_row_16" ]]; then
  pass "AT16c coding-standards.md has a Conventions row in data-ml presence check (C3 owning-table)"
else
  fail "AT16c coding-standards.md -- no Conventions row in data-ml presence check (C3 owning-table missing)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT16"
fi

# ---------------------------------------------------------------------------
# AT17: data-ml doc-set => byte-reproducibility (two runs sha256-identical).
# ---------------------------------------------------------------------------
log "AT17: data-ml.tsv => byte-reproducibility (sha256 identical across two runs)"

KB_AT17A=$(scratch_kb)
KB_AT17B=$(scratch_kb)
OUT_AT17A=$(run_task "$TSV_DATA_ML" "$KB_AT17A")
OUT_AT17B=$(run_task "$TSV_DATA_ML" "$KB_AT17B")

HASH_AT17A=$(sha256sum "$OUT_AT17A" | cut -d' ' -f1)
HASH_AT17B=$(sha256sum "$OUT_AT17B" | cut -d' ' -f1)

if [[ "$HASH_AT17A" == "$HASH_AT17B" ]]; then
  pass "AT17 data-ml task output is byte-identical on re-run (sha256 match, NFR-3)"
else
  fail "AT17 data-ml task output differs between runs (sha256 mismatch, NFR-3 violated)"
  [[ "$VERBOSE" -eq 1 ]] && diff "$OUT_AT17A" "$OUT_AT17B" || true
fi

# ---------------------------------------------------------------------------
# AT18: design doc-set => task shape is NOT 'endpoint' (FR-53 off-software gate).
#
# design.tsv contains design-tokens.md (C5), component-inventory.md (C2),
# design-principles.md (C3), design-overview.md (C9).  C5 wins; shape must be
# 'contract' -- NOT 'endpoint'.
# ---------------------------------------------------------------------------
log "AT18: design.tsv => task shape is NOT 'endpoint' (off-software domain, FR-53)"

KB_AT18=$(scratch_kb)
OUT_AT18=$(run_task "$TSV_DESIGN" "$KB_AT18")

if grep -qF "Task shape: endpoint" "$OUT_AT18"; then
  fail "AT18 design.tsv -- task shape is 'endpoint' (off-software generalization broken)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT18"
else
  pass "AT18 design.tsv => task shape is NOT 'endpoint' (FR-53 off-software gate passed)"
fi

assert_file_contains "$OUT_AT18" "Task shape: contract" \
  "AT18 design.tsv => C5 design-tokens.md wins priority; shape is 'contract'"

# ---------------------------------------------------------------------------
# AT19: design doc-set => presence check is non-empty (C5/C2/C3 owning-table fires).
#
# design-tokens.md (C5) -> expected for Conventions + Contracts.
# component-inventory.md (C2) -> expected for Conventions + Invariants + Contracts.
# design-principles.md (C3) -> expected for Conventions.
# design-overview.md (C9) -> no owning-table rows.
# ---------------------------------------------------------------------------
log "AT19: design.tsv => presence check is non-empty (C5/C2/C3 owning-table fires)"

KB_AT19=$(scratch_kb)
OUT_AT19=$(run_check "$TSV_DESIGN" "$KB_AT19")

row_count_19=$(grep -c "^| " "$OUT_AT19" || true)
data_rows_19=$(( row_count_19 - 1 ))
if [[ "$data_rows_19" -gt 0 ]]; then
  pass "AT19 design presence check is non-empty ($data_rows_19 data rows; C5/C2/C3 owning-table fired)"
else
  fail "AT19 design presence check is empty (expected >=1 row for C5/C2/C3 docs)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT19"
fi

# Assert design-tokens.md (C5) appears with a Contracts row.
tokens_contracts_row_19=$(grep -F "design-tokens.md" "$OUT_AT19" | grep -F "Contracts" || true)
if [[ -n "$tokens_contracts_row_19" ]]; then
  pass "AT19b design-tokens.md has a Contracts row in design presence check (C5 owning-table)"
else
  fail "AT19b design-tokens.md -- no Contracts row in design presence check (C5 owning-table missing)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT19"
fi

# Assert component-inventory.md (C2) appears with a Conventions row.
comp_conv_row_19=$(grep -F "component-inventory.md" "$OUT_AT19" | grep -F "Conventions" || true)
if [[ -n "$comp_conv_row_19" ]]; then
  pass "AT19c component-inventory.md has a Conventions row in design presence check (C2 owning-table)"
else
  fail "AT19c component-inventory.md -- no Conventions row in design presence check (C2 owning-table missing)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT19"
fi

# ---------------------------------------------------------------------------
# AT20: C5 owning-table fires off-software: data-schemas.md and design-tokens.md
#       both appear in their respective presence checks with Contracts rows.
#
# This is the definitive FR-53 guard: the dimension-keyed owning-table
# (_dim_owns_class C5 Contracts -> true) fires identically for software schemas
# and non-software data/design contracts.  Same rule; different domain.
# ---------------------------------------------------------------------------
log "AT20: C5 owning-table fires off-software (data-schemas.md + design-tokens.md both get Contracts rows)"

# data-ml: data-schemas.md Contracts row (AT16b already checks this; this asserts the cross-domain
# invariant explicitly as its own test).
KB_AT20_ML=$(scratch_kb)
OUT_AT20_ML=$(run_check "$TSV_DATA_ML" "$KB_AT20_ML")
ds_contracts=$(grep -F "data-schemas.md" "$OUT_AT20_ML" | grep -F "Contracts" || true)
if [[ -n "$ds_contracts" ]]; then
  pass "AT20a data-schemas.md has a Contracts row (C5 _dim_owns_class fires for data-ml domain)"
else
  fail "AT20a data-schemas.md -- no Contracts row (C5 owning-table did not fire for data-ml)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT20_ML"
fi

# design: design-tokens.md Contracts row.
KB_AT20_DS=$(scratch_kb)
OUT_AT20_DS=$(run_check "$TSV_DESIGN" "$KB_AT20_DS")
dt_contracts=$(grep -F "design-tokens.md" "$OUT_AT20_DS" | grep -F "Contracts" || true)
if [[ -n "$dt_contracts" ]]; then
  pass "AT20b design-tokens.md has a Contracts row (C5 _dim_owns_class fires for design domain)"
else
  fail "AT20b design-tokens.md -- no Contracts row (C5 owning-table did not fire for design)"
  [[ "$VERBOSE" -eq 1 ]] && cat "$OUT_AT20_DS"
fi

# Cross-domain symmetry: both domains select 'contract' task shape from C5.
if grep -qF "Task shape: contract" "$OUT_AT15" && grep -qF "Task shape: contract" "$OUT_AT18"; then
  pass "AT20c both data-ml and design domains select 'contract' shape via C5 (cross-domain symmetry)"
else
  fail "AT20c cross-domain symmetry broken: expected both data-ml and design to select 'contract'"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
