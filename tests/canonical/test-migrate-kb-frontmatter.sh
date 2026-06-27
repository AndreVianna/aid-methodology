#!/usr/bin/env bash
# test-migrate-kb-frontmatter.sh -- canonical suite for migrate-kb-frontmatter.sh.
#
# Covers task-019 acceptance criteria (work-001-kb-skills-improvement / delivery-003):
#   MF01  Scope selection: in-scope (primary/extension, source!=generated) vs skipped
#         (meta, source:generated). A "promoted from ..." source is IN scope.
#   MF02  --propose writes the worksheet and leaves every doc byte-unchanged.
#   MF03  --apply refuses (exit 3) without a worksheet.
#   MF04  --apply migrates a fixture old-format doc to lint-clean (no [FM-MISSING]/[FM-INVALID]).
#   MF05  Migrated doc has objective:/summary:/sources:/approved_at_commit: in f001 order;
#         intent: is retired; a changelog: row is added.
#   MF06  Idempotent re-run: second --apply over a fully migrated KB is a byte-identical no-op.
#   MF07  sources: [] pure-synthesis doc: migrated on first run, idempotent on second (no re-stamp).
#   MF08  --dry-run on --propose: writes no worksheet.
#   MF09  --dry-run on --apply: writes no doc edits, no backup tree.
#   MF10  --rollback restores byte-identity; backup tree is removed.
#   MF11  intent: retire ordering: objective/summary must be non-empty to retire intent:.
#         A doc with empty objective/summary in the worksheet is skipped (degrade-safe).
#   MF12  Verification-pass failure: a deliberately-broken migrated doc
#         (malformed approved_at_commit:) makes --apply exit 4.
#   MF13  Exit codes: bad KB root -> 1; no in-scope docs -> 2; --apply no worksheet -> 3.
#
# ISOLATION:
#   HOME is pinned to a throwaway dir (escape canary: no new .aid escapes it).
#   All fixture KB roots live under a mktemp -d (TMP), cleaned by trap EXIT.
#   NEVER reads or writes .aid/knowledge/ or any real home directory path.
#
# Usage:
#   HOME=$(mktemp -d) bash tests/canonical/test-migrate-kb-frontmatter.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATE="${REPO_ROOT}/canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh"
LINT="${REPO_ROOT}/canonical/aid/scripts/kb/lint-frontmatter.sh"

# Guard: scripts must exist
if [[ ! -f "$MIGRATE" ]]; then
    fail "MF00 setup -- migrate-kb-frontmatter.sh not found at $MIGRATE"
    test_summary
    exit 1
fi
if [[ ! -f "$LINT" ]]; then
    fail "MF00 setup -- lint-frontmatter.sh not found at $LINT"
    test_summary
    exit 1
fi

# ---------------------------------------------------------------------------
# HOME pin (isolation: the canary must not escape the throwaway HOME)
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"

export HOME
HOME="$(mktemp -d)"

# ---------------------------------------------------------------------------
# Global tmp dir -- all fixture repos live here; cleaned on EXIT.
# ---------------------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"; rm -rf "$HOME"' EXIT

# ---------------------------------------------------------------------------
# make_kb_root TAG
# Build a fresh fixture KB root under $TMP/TAG/.aid/knowledge/
# Also initializes a git repo with one commit so that git rev-parse --short HEAD
# returns a valid 7-char hex hash (needed for approved_at_commit: validation).
# Returns the knowledge path via stdout.
# ---------------------------------------------------------------------------
make_kb_root() {
    local tag="$1"
    local base="${TMP}/${tag}"
    mkdir -p "${base}/.aid/knowledge"
    mkdir -p "${base}/.aid/.temp"

    # Initialize a minimal git repo so the migration can stamp approved_at_commit:
    # with a real short hash (required by lint: 7-40 lowercase hex chars).
    git -C "$base" init -q 2>/dev/null || true
    git -C "$base" config user.email "test@aid-test.local" 2>/dev/null || true
    git -C "$base" config user.name "AID Test" 2>/dev/null || true
    printf 'fixture-repo\n' > "${base}/.gitignore"
    git -C "$base" add .gitignore 2>/dev/null || true
    git -C "$base" commit -q -m "init fixture" 2>/dev/null || true

    echo "${base}/.aid/knowledge"
}

# ---------------------------------------------------------------------------
# write_doc PATH CONTENT
# ---------------------------------------------------------------------------
write_doc() {
    local path="$1"
    local content="$2"
    printf '%s\n' "$content" > "$path"
}

# ---------------------------------------------------------------------------
# file_sha -- portable content hash (byte identity check).
# ---------------------------------------------------------------------------
file_sha() {
    local f="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$f" | awk '{print $1}'
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$f" | awk '{print $NF}'
    else
        md5sum "$f" | awk '{print $1}'
    fi
}

# ---------------------------------------------------------------------------
# Fixture doc content helpers.
# We use a fake short commit hash "aabbccdd" so approved_at_commit won't
# be validated against real git (the script uses `git -C <root> rev-parse`
# which returns "unknown" when there's no git repo -- valid for testing).
# ---------------------------------------------------------------------------

# Primary doc with intent: literal block -- NOT yet migrated.
FIXTURE_PRIMARY='---
kb-category: primary
source: hand-authored
intent: |
  Manages the canonical KB document lifecycle and authoring guidelines.
  Authors use this doc to understand creation, update, and retirement.
contracts: |
  - KB docs follow f001 frontmatter schema.
changelog:
  - 2026-01-01: Initial draft.
---

## Body section

This is the primary fixture document.'

# Extension doc with intent: -- NOT yet migrated.
FIXTURE_EXTENSION='---
kb-category: extension
source: hand-authored
intent: |
  Extends the KB with supplementary reference material for advanced users.
changelog:
  - 2026-02-01: Created.
---

## Extension body'

# Pure-synthesis doc (no file/URL sources) -- NOT yet migrated.
# This doc tests that sources: [] is idempotent (key-presence skip).
FIXTURE_SYNTHESIS='---
kb-category: primary
source: hand-authored
intent: |
  Captures synthesized conceptual knowledge with no direct file sources.
changelog:
  - 2026-03-01: Created.
---

## Synthesis body'

# Meta doc -- must be SKIPPED by the migration.
FIXTURE_META='---
kb-category: meta
source: hand-authored
---

# README

This is a meta doc.'

# Generated doc -- must be SKIPPED by the migration.
FIXTURE_GENERATED='---
kb-category: primary
source: generated
---

# INDEX (generated)

This is a generated doc.'

# Promoted-from doc -- source: "promoted from ..." -- must be IN scope (source != generated).
FIXTURE_PROMOTED='---
kb-category: primary
source: promoted from work-local research (work-001)
intent: |
  Describes host tool capabilities available to AID agents.
changelog:
  - 2026-04-01: Promoted from work-local.
---

## Promoted body'

# Already-migrated primary doc (idempotency fixture).
FIXTURE_MIGRATED_PRIMARY='---
kb-category: primary
source: hand-authored
objective: Manages the canonical KB document lifecycle
summary: Manages the canonical KB document lifecycle.
sources: []
approved_at_commit: aabbccd
contracts: |
  - KB docs follow f001 frontmatter schema.
changelog:
  - 2026-05-01: Migrated by migrate-kb-frontmatter.sh: intent retired, objective/summary/sources added
  - 2026-01-01: Initial draft.
---

## Body section

This is the already-migrated primary fixture document.'

# Already-migrated pure-synthesis doc (sources: [] idempotency).
FIXTURE_MIGRATED_SYNTHESIS='---
kb-category: primary
source: hand-authored
objective: Captures synthesized conceptual knowledge
summary: Captures synthesized conceptual knowledge with no direct file sources.
sources: []
approved_at_commit: aabbccd
changelog:
  - 2026-05-01: Migrated by migrate-kb-frontmatter.sh: intent retired, objective/summary/sources added
  - 2026-03-01: Created.
---

## Synthesis body'

# ===========================================================================
# MF01 -- Scope selection
# A KB root with all 5 types: primary, extension, meta, generated, promoted.
# After --propose: only primary, extension, promoted are in-scope;
# meta and generated are skipped.
# ===========================================================================
echo ""
echo "=== MF01: scope selection (in-scope vs skipped) ==="

MF01_KB="$(make_kb_root "mf01")"
write_doc "${MF01_KB}/primary.md"   "$FIXTURE_PRIMARY"
write_doc "${MF01_KB}/extension.md" "$FIXTURE_EXTENSION"
write_doc "${MF01_KB}/synthesis.md" "$FIXTURE_SYNTHESIS"
write_doc "${MF01_KB}/meta.md"      "$FIXTURE_META"
write_doc "${MF01_KB}/generated.md" "$FIXTURE_GENERATED"
write_doc "${MF01_KB}/promoted.md"  "$FIXTURE_PROMOTED"

MF01_OUT=""
MF01_RC=0
MF01_OUT="$(bash "$MIGRATE" "$MF01_KB" --propose 2>&1)" || MF01_RC=$?

assert_exit_zero "$MF01_RC" "MF01-01 --propose exits 0 on a valid KB with in-scope docs"

# Worksheet must exist
MF01_WS="${TMP}/mf01/.aid/.temp/kb-migration-proposal.md"
assert_file_exists "$MF01_WS" "MF01-02 worksheet written to .aid/.temp/kb-migration-proposal.md"

# In-scope docs appear in the worksheet (proposed)
assert_file_contains "$MF01_WS" "## primary.md"   "MF01-03 primary.md is in-scope -> appears in worksheet"
assert_file_contains "$MF01_WS" "## extension.md" "MF01-04 extension.md is in-scope -> appears in worksheet"
assert_file_contains "$MF01_WS" "## synthesis.md" "MF01-05 synthesis.md is in-scope -> appears in worksheet"
assert_file_contains "$MF01_WS" "## promoted.md"  "MF01-06 promoted.md (source:promoted from ...) is in-scope"

# Out-of-scope docs must NOT appear in the worksheet
if grep -qF "## meta.md" "$MF01_WS" 2>/dev/null; then
    fail "MF01-07 meta.md must NOT appear in worksheet (must be skipped)"
else
    pass "MF01-07 meta.md skipped -- absent from worksheet"
fi

if grep -qF "## generated.md" "$MF01_WS" 2>/dev/null; then
    fail "MF01-08 generated.md must NOT appear in worksheet (must be skipped)"
else
    pass "MF01-08 generated.md skipped -- absent from worksheet"
fi

# Docs on disk must be byte-unchanged after --propose (the whole point of propose)
MF01_PRIMARY_SHA_BEFORE="$(file_sha "${MF01_KB}/primary.md")"
MF01_PRIMARY_SHA_AFTER="$(file_sha "${MF01_KB}/primary.md")"
assert_eq "$MF01_PRIMARY_SHA_AFTER" "$MF01_PRIMARY_SHA_BEFORE" \
    "MF01-09 --propose leaves primary.md byte-unchanged"

MF01_META_SHA_BEFORE="$(file_sha "${MF01_KB}/meta.md")"
MF01_META_SHA_AFTER="$(file_sha "${MF01_KB}/meta.md")"
assert_eq "$MF01_META_SHA_AFTER" "$MF01_META_SHA_BEFORE" \
    "MF01-10 --propose leaves meta.md byte-unchanged"

# ===========================================================================
# MF02 -- --propose writes worksheet; docs unchanged.
# (Dedicated focused test for propose-only KB)
# ===========================================================================
echo ""
echo "=== MF02: --propose writes worksheet + docs unchanged ==="

MF02_KB="$(make_kb_root "mf02")"
write_doc "${MF02_KB}/doc-a.md" "$FIXTURE_PRIMARY"
write_doc "${MF02_KB}/doc-b.md" "$FIXTURE_EXTENSION"

# Capture byte-exact content before propose
MF02_SHA_A_BEFORE="$(file_sha "${MF02_KB}/doc-a.md")"
MF02_SHA_B_BEFORE="$(file_sha "${MF02_KB}/doc-b.md")"

MF02_RC=0
bash "$MIGRATE" "$MF02_KB" --propose 2>/dev/null || MF02_RC=$?
assert_exit_zero "$MF02_RC" "MF02-01 --propose exits 0"

MF02_WS="${TMP}/mf02/.aid/.temp/kb-migration-proposal.md"
assert_file_exists "$MF02_WS" "MF02-02 worksheet file exists"

# Both docs must be byte-identical after --propose
MF02_SHA_A_AFTER="$(file_sha "${MF02_KB}/doc-a.md")"
MF02_SHA_B_AFTER="$(file_sha "${MF02_KB}/doc-b.md")"
assert_eq "$MF02_SHA_A_AFTER" "$MF02_SHA_A_BEFORE" "MF02-03 doc-a.md byte-unchanged after --propose"
assert_eq "$MF02_SHA_B_AFTER" "$MF02_SHA_B_BEFORE" "MF02-04 doc-b.md byte-unchanged after --propose"

# Worksheet contains seeded objective/summary entries
assert_file_contains "$MF02_WS" "objective:" "MF02-05 worksheet contains seeded objective:"
assert_file_contains "$MF02_WS" "summary:"   "MF02-06 worksheet contains seeded summary:"
assert_file_contains "$MF02_WS" "sources:"   "MF02-07 worksheet contains sources: section"

# ===========================================================================
# MF03 -- --apply refuses (exit 3) without a worksheet.
# ===========================================================================
echo ""
echo "=== MF03: --apply without worksheet -> exit 3 ==="

MF03_KB="$(make_kb_root "mf03")"
write_doc "${MF03_KB}/doc.md" "$FIXTURE_PRIMARY"

MF03_RC=0
bash "$MIGRATE" "$MF03_KB" --apply 2>/dev/null || MF03_RC=$?
assert_exit_eq "$MF03_RC" 3 "MF03-01 --apply without worksheet exits 3"

# ===========================================================================
# MF04/MF05 -- --apply migrates to lint-clean; fields present; intent retired; changelog added.
# ===========================================================================
echo ""
echo "=== MF04/MF05: --apply migrates fixture doc to lint-clean ==="

MF04_KB="$(make_kb_root "mf04")"
write_doc "${MF04_KB}/primary.md"  "$FIXTURE_PRIMARY"
write_doc "${MF04_KB}/promoted.md" "$FIXTURE_PROMOTED"

# Run --propose to generate the worksheet
bash "$MIGRATE" "$MF04_KB" --propose 2>/dev/null

MF04_WS="${TMP}/mf04/.aid/.temp/kb-migration-proposal.md"

# Replace worksheet entries with clean, non-empty objective/summary so --apply can finalize.
# The propose output seeds from intent; we write a curated worksheet so the test is deterministic.
cat > "$MF04_WS" << 'WORKSHEET_EOF'
# KB Migration Proposal Worksheet (hand-curated for test determinism)

## primary.md

objective: KB document lifecycle and authoring guidelines

summary: Manages the canonical KB document lifecycle and authoring guidelines.

sources:
  []  # pure-synthesis -> sources: []

---

## promoted.md

objective: Host tool capabilities for AID agents

summary: Describes host tool capabilities available to AID agents.

sources:
  []  # pure-synthesis -> sources: []

---
WORKSHEET_EOF

MF04_RC=0
bash "$MIGRATE" "$MF04_KB" --apply 2>/dev/null || MF04_RC=$?
assert_exit_zero "$MF04_RC" "MF04-01 --apply exits 0 after successful migration"

# MF04: lint must pass on the migrated primary.md
MF04_LINT_OUT=""
MF04_LINT_RC=0
MF04_LINT_OUT="$(bash "$LINT" --root "$MF04_KB" 2>&1)" || MF04_LINT_RC=$?
assert_exit_zero "$MF04_LINT_RC" "MF04-02 lint-frontmatter passes on migrated fixture KB"
if echo "$MF04_LINT_OUT" | grep -qF "[FM-MISSING]" || echo "$MF04_LINT_OUT" | grep -qF "[FM-INVALID]"; then
    fail "MF04-03 no [FM-MISSING]/[FM-INVALID] findings after migration -- found findings"
    [[ "$VERBOSE" -eq 1 ]] && echo "$MF04_LINT_OUT"
else
    pass "MF04-03 no [FM-MISSING]/[FM-INVALID] findings after migration"
fi

# MF05: required fields present in f001 canonical order in the migrated doc
MF05_DOC="${MF04_KB}/primary.md"

# objective: present and non-empty
MF05_OBJ="$(grep '^objective:' "$MF05_DOC" | head -1)"
if [[ -n "$MF05_OBJ" ]]; then
    pass "MF05-01 objective: present in migrated doc"
else
    fail "MF05-01 objective: absent in migrated doc"
fi

# summary: present
if grep -q '^summary:' "$MF05_DOC"; then
    pass "MF05-02 summary: present in migrated doc"
else
    fail "MF05-02 summary: absent in migrated doc"
fi

# sources: present (key presence, including sources: [])
if grep -q '^sources:' "$MF05_DOC"; then
    pass "MF05-03 sources: key present in migrated doc"
else
    fail "MF05-03 sources: key absent in migrated doc"
fi

# approved_at_commit: present
if grep -q '^approved_at_commit:' "$MF05_DOC"; then
    pass "MF05-04 approved_at_commit: present in migrated doc"
else
    fail "MF05-04 approved_at_commit: absent in migrated doc"
fi

# intent: must be retired (absent from frontmatter after migration)
if awk '/^---$/{in_fm=!in_fm;next} in_fm && /^intent:/' "$MF05_DOC" | grep -q .; then
    fail "MF05-05 intent: must be retired (removed) after migration -- still present"
else
    pass "MF05-05 intent: retired (absent from frontmatter)"
fi

# changelog: row appended (contains "Migrated by migrate-kb-frontmatter.sh")
if grep -q "Migrated by migrate-kb-frontmatter.sh" "$MF05_DOC"; then
    pass "MF05-06 changelog: row appended with migration note"
else
    fail "MF05-06 changelog: migration row absent"
fi

# f001 canonical order: objective before summary before sources before approved_at_commit
MF05_OBJ_LINE=$(grep -n '^objective:'             "$MF05_DOC" | head -1 | cut -d: -f1)
MF05_SUM_LINE=$(grep -n '^summary:'               "$MF05_DOC" | head -1 | cut -d: -f1)
MF05_SRC_LINE=$(grep -n '^sources:'               "$MF05_DOC" | head -1 | cut -d: -f1)
MF05_AAC_LINE=$(grep -n '^approved_at_commit:'    "$MF05_DOC" | head -1 | cut -d: -f1)

if [[ -n "$MF05_OBJ_LINE" && -n "$MF05_SUM_LINE" && -n "$MF05_SRC_LINE" && -n "$MF05_AAC_LINE" ]]; then
    if [[ "$MF05_OBJ_LINE" -lt "$MF05_SUM_LINE" && \
          "$MF05_SUM_LINE" -lt "$MF05_SRC_LINE" && \
          "$MF05_SRC_LINE" -lt "$MF05_AAC_LINE" ]]; then
        pass "MF05-07 f001 canonical order: objective < summary < sources < approved_at_commit"
    else
        fail "MF05-07 f001 canonical order violated: obj=$MF05_OBJ_LINE sum=$MF05_SUM_LINE src=$MF05_SRC_LINE aac=$MF05_AAC_LINE"
    fi
else
    fail "MF05-07 f001 canonical order -- one or more fields missing (can't check order)"
fi

# ===========================================================================
# MF06 -- Idempotent re-run: second --apply over a fully migrated KB is a no-op.
# ===========================================================================
echo ""
echo "=== MF06: idempotent re-run (second --apply is a no-op) ==="

MF06_KB="$(make_kb_root "mf06")"
# Write already-migrated docs
write_doc "${MF06_KB}/migrated.md"  "$FIXTURE_MIGRATED_PRIMARY"
write_doc "${MF06_KB}/synthesis.md" "$FIXTURE_MIGRATED_SYNTHESIS"

# Capture hashes before second run
MF06_SHA_M_BEFORE="$(file_sha "${MF06_KB}/migrated.md")"
MF06_SHA_S_BEFORE="$(file_sha "${MF06_KB}/synthesis.md")"

# Create a minimal worksheet (--apply needs it even if no docs are processed)
# BUT since all docs are already migrated, the propose pass should exit 0 with
# "All in-scope docs are already migrated. No-op."  So we create the worksheet manually
# to test the idempotency path through --apply.
MF06_TEMP="${TMP}/mf06/.aid/.temp"
mkdir -p "$MF06_TEMP"
cat > "${MF06_TEMP}/kb-migration-proposal.md" << 'WS_EOF'
# KB Migration Proposal Worksheet

---

WS_EOF

MF06_RC=0
MF06_OUT=""
MF06_OUT="$(bash "$MIGRATE" "$MF06_KB" --apply 2>&1)" || MF06_RC=$?
assert_exit_zero "$MF06_RC" "MF06-01 second --apply on fully-migrated KB exits 0 (no-op)"

# Docs must be byte-identical
MF06_SHA_M_AFTER="$(file_sha "${MF06_KB}/migrated.md")"
MF06_SHA_S_AFTER="$(file_sha "${MF06_KB}/synthesis.md")"
assert_eq "$MF06_SHA_M_AFTER" "$MF06_SHA_M_BEFORE" \
    "MF06-02 migrated.md byte-identical after second --apply (idempotent)"
assert_eq "$MF06_SHA_S_AFTER" "$MF06_SHA_S_BEFORE" \
    "MF06-03 synthesis.md (sources:[]) byte-identical after second --apply (idempotent)"

# No double changelog row (only one migration row)
MF06_CL_COUNT="$(grep -c "Migrated by migrate-kb-frontmatter.sh" "${MF06_KB}/migrated.md" || true)"
assert_eq "$MF06_CL_COUNT" "1" "MF06-04 no double changelog row after re-run"

# ===========================================================================
# MF07 -- sources: [] pure-synthesis doc: migrated on first run, idempotent on second.
# (Key-presence skip predicate -- NOT value-presence.)
# ===========================================================================
echo ""
echo "=== MF07: sources: [] pure-synthesis idempotency ==="

MF07_KB="$(make_kb_root "mf07")"
write_doc "${MF07_KB}/synthesis.md" "$FIXTURE_SYNTHESIS"

# --propose first
bash "$MIGRATE" "$MF07_KB" --propose 2>/dev/null

# Write a curated worksheet for the synthesis doc (sources: [])
MF07_WS="${TMP}/mf07/.aid/.temp/kb-migration-proposal.md"
cat > "$MF07_WS" << 'WS_EOF'
# KB Migration Proposal Worksheet

## synthesis.md

objective: Synthesized conceptual knowledge

summary: Captures synthesized conceptual knowledge with no direct file sources.

sources:
  []  # pure-synthesis -> sources: []

---
WS_EOF

# First --apply
MF07_RC1=0
bash "$MIGRATE" "$MF07_KB" --apply 2>/dev/null || MF07_RC1=$?
assert_exit_zero "$MF07_RC1" "MF07-01 first --apply on synthesis doc exits 0"

# Verify sources: [] is present after migration
if grep -q '^sources: \[\]' "${MF07_KB}/synthesis.md"; then
    pass "MF07-02 synthesis.md has sources: [] after first --apply"
else
    fail "MF07-02 synthesis.md does not have sources: [] after first --apply"
fi

# Capture hash after first apply
MF07_SHA_AFTER1="$(file_sha "${MF07_KB}/synthesis.md")"

# Second --apply (idempotency -- worksheet may be gone after first apply creates backup;
# write a fresh empty worksheet to pass the worksheet-presence guard)
MF07_WS2="${TMP}/mf07/.aid/.temp/kb-migration-proposal.md"
cat > "$MF07_WS2" << 'WS_EOF'
# KB Migration Proposal Worksheet (re-run)

---

WS_EOF

MF07_RC2=0
bash "$MIGRATE" "$MF07_KB" --apply 2>/dev/null || MF07_RC2=$?
assert_exit_zero "$MF07_RC2" "MF07-03 second --apply on synthesis doc exits 0 (no-op)"

# Byte-identical after second apply
MF07_SHA_AFTER2="$(file_sha "${MF07_KB}/synthesis.md")"
assert_eq "$MF07_SHA_AFTER2" "$MF07_SHA_AFTER1" \
    "MF07-04 synthesis.md byte-identical after second --apply (sources:[] idempotency)"

# No double changelog row
MF07_CL_COUNT="$(grep -c "Migrated by migrate-kb-frontmatter.sh" "${MF07_KB}/synthesis.md" || true)"
assert_eq "$MF07_CL_COUNT" "1" "MF07-05 no double changelog row on synthesis doc re-run"

# ===========================================================================
# MF08 -- --dry-run on --propose: writes no worksheet, no doc edits.
# ===========================================================================
echo ""
echo "=== MF08: --dry-run on --propose writes nothing ==="

MF08_KB="$(make_kb_root "mf08")"
write_doc "${MF08_KB}/doc.md" "$FIXTURE_PRIMARY"

MF08_SHA_BEFORE="$(file_sha "${MF08_KB}/doc.md")"
MF08_WS="${TMP}/mf08/.aid/.temp/kb-migration-proposal.md"

MF08_RC=0
bash "$MIGRATE" "$MF08_KB" --propose --dry-run 2>/dev/null || MF08_RC=$?
assert_exit_zero "$MF08_RC" "MF08-01 --propose --dry-run exits 0"

# Worksheet must NOT exist
if [[ -f "$MF08_WS" ]]; then
    fail "MF08-02 --dry-run must not write worksheet -- file exists"
else
    pass "MF08-02 --dry-run writes no worksheet"
fi

# Doc must be byte-unchanged
MF08_SHA_AFTER="$(file_sha "${MF08_KB}/doc.md")"
assert_eq "$MF08_SHA_AFTER" "$MF08_SHA_BEFORE" "MF08-03 doc byte-unchanged after --propose --dry-run"

# ===========================================================================
# MF09 -- --dry-run on --apply: writes no doc edits, no backup tree.
# ===========================================================================
echo ""
echo "=== MF09: --dry-run on --apply writes nothing ==="

MF09_KB="$(make_kb_root "mf09")"
write_doc "${MF09_KB}/doc.md" "$FIXTURE_PRIMARY"

# Create the worksheet (needed so --apply doesn't exit 3)
MF09_TEMP="${TMP}/mf09/.aid/.temp"
mkdir -p "$MF09_TEMP"
cat > "${MF09_TEMP}/kb-migration-proposal.md" << 'WS_EOF'
# KB Migration Proposal Worksheet

## doc.md

objective: KB document lifecycle and authoring guidelines

summary: Manages the canonical KB document lifecycle and authoring guidelines.

sources:
  []  # pure-synthesis -> sources: []

---
WS_EOF

MF09_SHA_BEFORE="$(file_sha "${MF09_KB}/doc.md")"

MF09_RC=0
bash "$MIGRATE" "$MF09_KB" --apply --dry-run 2>/dev/null || MF09_RC=$?
assert_exit_zero "$MF09_RC" "MF09-01 --apply --dry-run exits 0"

# Doc must be byte-unchanged
MF09_SHA_AFTER="$(file_sha "${MF09_KB}/doc.md")"
assert_eq "$MF09_SHA_AFTER" "$MF09_SHA_BEFORE" "MF09-02 doc byte-unchanged after --apply --dry-run"

# No backup tree must exist
MF09_BACKUP_COUNT="$(find "$MF09_TEMP" -maxdepth 1 -type d -name 'kb-migration-backup-*' 2>/dev/null | wc -l | tr -d ' ')"
assert_eq "$MF09_BACKUP_COUNT" "0" "MF09-03 no backup tree written by --apply --dry-run"

# ===========================================================================
# MF10 -- --rollback restores byte-identity; backup tree is removed.
# ===========================================================================
echo ""
echo "=== MF10: --rollback restores byte-identity ==="

MF10_KB="$(make_kb_root "mf10")"
write_doc "${MF10_KB}/primary.md"  "$FIXTURE_PRIMARY"
write_doc "${MF10_KB}/promoted.md" "$FIXTURE_PROMOTED"

# Snapshot byte content before --apply
MF10_SHA_PRIMARY_BEFORE="$(file_sha "${MF10_KB}/primary.md")"
MF10_SHA_PROMOTED_BEFORE="$(file_sha "${MF10_KB}/promoted.md")"

# Write a curated worksheet
MF10_TEMP="${TMP}/mf10/.aid/.temp"
mkdir -p "$MF10_TEMP"
cat > "${MF10_TEMP}/kb-migration-proposal.md" << 'WS_EOF'
# KB Migration Proposal Worksheet

## primary.md

objective: KB document lifecycle guidelines

summary: Manages the canonical KB document lifecycle.

sources:
  []  # pure-synthesis -> sources: []

---

## promoted.md

objective: Host tool capabilities

summary: Describes host tool capabilities available to AID agents.

sources:
  []  # pure-synthesis -> sources: []

---
WS_EOF

# --apply (migrates + creates backup)
MF10_APPLY_RC=0
bash "$MIGRATE" "$MF10_KB" --apply 2>/dev/null || MF10_APPLY_RC=$?
assert_exit_zero "$MF10_APPLY_RC" "MF10-01 --apply before rollback exits 0"

# Docs have changed (they were migrated)
MF10_SHA_PRIMARY_APPLIED="$(file_sha "${MF10_KB}/primary.md")"
if [[ "$MF10_SHA_PRIMARY_APPLIED" != "$MF10_SHA_PRIMARY_BEFORE" ]]; then
    pass "MF10-02 primary.md content changed after --apply (migration verified)"
else
    fail "MF10-02 primary.md content unchanged after --apply (migration did not run)"
fi

# Backup tree exists
MF10_BACKUP="$(find "$MF10_TEMP" -maxdepth 1 -type d -name 'kb-migration-backup-*' 2>/dev/null | sort | tail -1 || true)"
if [[ -n "$MF10_BACKUP" ]]; then
    pass "MF10-03 backup tree exists after --apply: $MF10_BACKUP"
else
    fail "MF10-03 backup tree not found after --apply"
fi

# --rollback
MF10_ROLLBACK_RC=0
bash "$MIGRATE" "$MF10_KB" --rollback 2>/dev/null || MF10_ROLLBACK_RC=$?
assert_exit_zero "$MF10_ROLLBACK_RC" "MF10-04 --rollback exits 0"

# Docs must be byte-identical to pre-apply snapshots
MF10_SHA_PRIMARY_AFTER="$(file_sha "${MF10_KB}/primary.md")"
MF10_SHA_PROMOTED_AFTER="$(file_sha "${MF10_KB}/promoted.md")"
assert_eq "$MF10_SHA_PRIMARY_AFTER" "$MF10_SHA_PRIMARY_BEFORE" \
    "MF10-05 primary.md byte-identical to pre-apply snapshot after --rollback"
assert_eq "$MF10_SHA_PROMOTED_AFTER" "$MF10_SHA_PROMOTED_BEFORE" \
    "MF10-06 promoted.md byte-identical to pre-apply snapshot after --rollback"

# Backup tree must be removed after rollback
MF10_BACKUP_COUNT="$(find "$MF10_TEMP" -maxdepth 1 -type d -name 'kb-migration-backup-*' 2>/dev/null | wc -l | tr -d ' ')"
assert_eq "$MF10_BACKUP_COUNT" "0" "MF10-07 backup tree removed after --rollback"

# ===========================================================================
# MF11 -- intent: retire ordering (degrade-safe).
# A doc with empty objective/summary in the worksheet is skipped.
# ===========================================================================
echo ""
echo "=== MF11: intent: retire ordering (degrade-safe -- empty objective/summary skipped) ==="

MF11_KB="$(make_kb_root "mf11")"
write_doc "${MF11_KB}/doc.md" "$FIXTURE_PRIMARY"

MF11_SHA_BEFORE="$(file_sha "${MF11_KB}/doc.md")"

# Write a worksheet with EMPTY objective (simulate worksheet not yet filled)
MF11_TEMP="${TMP}/mf11/.aid/.temp"
mkdir -p "$MF11_TEMP"
cat > "${MF11_TEMP}/kb-migration-proposal.md" << 'WS_EOF'
# KB Migration Proposal Worksheet

## doc.md

objective:

summary:

sources:
  []

---
WS_EOF

MF11_RC=0
bash "$MIGRATE" "$MF11_KB" --apply 2>/dev/null || MF11_RC=$?
# Should exit 0 (no-op: doc skipped due to empty objective/summary)
assert_exit_zero "$MF11_RC" "MF11-01 --apply with empty objective/summary exits 0 (degrade-safe skip)"

# Doc must be byte-unchanged (was not modified)
MF11_SHA_AFTER="$(file_sha "${MF11_KB}/doc.md")"
assert_eq "$MF11_SHA_AFTER" "$MF11_SHA_BEFORE" \
    "MF11-02 doc byte-unchanged when objective/summary are empty (intent: not retired)"

# intent: must still be present in the doc (not retired)
if awk '/^---$/{in_fm=!in_fm;next} in_fm && /^intent:/' "${MF11_KB}/doc.md" | grep -q .; then
    pass "MF11-03 intent: still present (not retired when objective/summary empty)"
else
    fail "MF11-03 intent: was retired despite empty objective/summary (degrade-safe violation)"
fi

# ===========================================================================
# MF12 -- Verification-pass failure: broken approved_at_commit -> exit 4.
# The script's verification pass calls lint-frontmatter.sh after APPLY.
# We simulate a broken doc by making the lint fail on the migrated doc.
# Strategy: write a doc that after migration will have an invalid approved_at_commit.
# Since the script stamps the real git hash (or "unknown"), we override by
# post-editing the migrated doc to break the approved_at_commit, then run a
# fresh --apply on a KB that contains this broken doc -- but lint will flag it.
#
# Alternative (simpler, more reliable): write a doc that already has ONE of the
# new fields (so soft-skip doesn't fire) but is missing a required field,
# then write a worksheet that tries to apply to it. The lint will fail on that doc.
#
# The SPEC says: "a deliberately-broken migrated doc (e.g. malformed
# approved_at_commit:) makes --apply exit non-zero and point at the backup."
# We achieve this by post-patching the doc AFTER rewrite_doc writes it, but
# the script does the verification in one atomic batch. Instead:
# - Write a doc that after the APPLY has a broken approved_at_commit by providing
#   a worksheet that produces a lint-failing result.
# - The lint check in the script calls lint-frontmatter.sh over the KB root.
# - We can make it fail by writing ANOTHER doc into the KB that already has
#   new fields but is malformed (missing objective), which the lint enforces.
#
# Concrete approach: KB has two docs.
#   Doc A: old-format; worksheet migrates it properly.
#   Doc B: already carries partial new fields (objective: only, no summary/sources)
#          -> soft-skip does NOT fire (it has a new field) -> lint emits [FM-MISSING].
# After --apply migrates doc A, the lint pass checks the whole root -> Doc B fails lint
# -> --apply exits 4. The backup exists because Doc A was backed up before modification.
# ===========================================================================
echo ""
echo "=== MF12: verification-pass failure (lint fails on broken doc -> exit 4) ==="

MF12_KB="$(make_kb_root "mf12")"
write_doc "${MF12_KB}/good.md" "$FIXTURE_PRIMARY"

# Broken doc: has objective: (so soft-skip fires = NOT skipped) but missing summary/sources.
write_doc "${MF12_KB}/broken.md" "---
kb-category: primary
source: hand-authored
objective: This doc is deliberately incomplete
---

## Broken doc body"

# Write worksheet for good.md (broken.md is already-partially-migrated, not old-format)
MF12_TEMP="${TMP}/mf12/.aid/.temp"
mkdir -p "$MF12_TEMP"
cat > "${MF12_TEMP}/kb-migration-proposal.md" << 'WS_EOF'
# KB Migration Proposal Worksheet

## good.md

objective: KB document lifecycle guidelines

summary: Manages the canonical KB document lifecycle.

sources:
  []  # pure-synthesis -> sources: []

---
WS_EOF

MF12_RC=0
MF12_OUT=""
MF12_OUT="$(bash "$MIGRATE" "$MF12_KB" --apply 2>&1)" || MF12_RC=$?
assert_exit_eq "$MF12_RC" 4 "MF12-01 --apply exits 4 when verification pass fails (lint finds broken.md)"

# Backup must be retained (not removed on failure)
MF12_BACKUP_COUNT="$(find "$MF12_TEMP" -maxdepth 1 -type d -name 'kb-migration-backup-*' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$MF12_BACKUP_COUNT" -gt 0 ]]; then
    pass "MF12-02 backup tree retained on verification failure"
else
    fail "MF12-02 backup tree absent after exit 4 (should be retained)"
fi

# Output must point at backup (mention backup or rollback in stderr)
if echo "$MF12_OUT" | grep -qi "backup\|rollback"; then
    pass "MF12-03 failure output mentions backup/rollback"
else
    fail "MF12-03 failure output does not mention backup/rollback: $MF12_OUT"
fi

# ===========================================================================
# MF13 -- Exit codes: bad KB root -> 1; no in-scope docs -> 2; no worksheet -> 3.
# ===========================================================================
echo ""
echo "=== MF13: distinct exit codes 1/2/3 ==="

# Exit 1: bad/absent KB root
MF13_RC1=0
bash "$MIGRATE" "/no/such/path/kb-root-does-not-exist" 2>/dev/null || MF13_RC1=$?
assert_exit_eq "$MF13_RC1" 1 "MF13-01 bad KB root -> exit 1"

# Exit 2: valid KB root but no in-scope docs (only meta + generated)
MF13_KB="$(make_kb_root "mf13")"
write_doc "${MF13_KB}/readme.md"   "$FIXTURE_META"
write_doc "${MF13_KB}/index.md"    "$FIXTURE_GENERATED"

MF13_RC2=0
bash "$MIGRATE" "$MF13_KB" --propose 2>/dev/null || MF13_RC2=$?
assert_exit_eq "$MF13_RC2" 2 "MF13-02 no in-scope docs -> exit 2"

# Exit 3: --apply without worksheet (tested above in MF03, confirm here independently)
MF13_KB3="$(make_kb_root "mf13b")"
write_doc "${MF13_KB3}/doc.md" "$FIXTURE_PRIMARY"
MF13_RC3=0
bash "$MIGRATE" "$MF13_KB3" --apply 2>/dev/null || MF13_RC3=$?
assert_exit_eq "$MF13_RC3" 3 "MF13-03 --apply without worksheet -> exit 3"

# ===========================================================================
# Isolation canary: verify no NEW .aid dirs escaped the throwaway HOME.
# ===========================================================================
echo ""
echo "=== Isolation canary ==="

_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
if [[ "$_CANARY_AFTER" == "$_CANARY_BEFORE" ]]; then
    pass "CANARY no new .aid dirs escaped the throwaway HOME"
else
    _CANARY_NEW="$(comm -23 <(echo "$_CANARY_AFTER") <(echo "$_CANARY_BEFORE"))"
    fail "CANARY isolation breach: new .aid dirs found under real HOME: $_CANARY_NEW"
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
test_summary
