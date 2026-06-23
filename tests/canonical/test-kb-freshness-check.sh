#!/usr/bin/env bash
# test-kb-freshness-check.sh -- f007 staleness regression suite for kb-freshness-check.sh.
#
# Exercises the as-built staleness script (task-040) over a scripted git fixture repo
# so the merge-base/ancestry algorithm is genuinely exercised.
#
# Test IDs:
#   FR01  Git fixture repo setup -- baseline commit + approval recorded
#   FR02  suspect verdict -- source changed after approved_at_commit (merge-base logic)
#   FR03  suspect_sources_csv populated with the drifted path
#   FR04  current verdict -- source at-or-before approved_at_commit
#   FR05  unknown verdict -- URL source (cannot git log a URL)
#   FR06  unknown verdict -- no approved_at_commit (pre-migration doc)
#   FR07  unknown verdict -- untracked source (git log returns empty)
#   FR08  current verdict -- sources: absent (no field at all)
#   FR09  current verdict -- sources: [] (empty inline list)
#   FR10  TSV column order: 7 tab-separated columns in the declared stable order
#   FR11  TSV byte-reproducibility: sha256 identical across two consecutive runs
#   FR12  exit code 0 on a scan that yields a suspect doc
#   FR13  exit code 1 on an argument error (unknown flag)
#   FR14  text-format smoke: default invocation renders current/suspect/unknown lines
#   FR15  --doc single-filter returns ONLY the target doc; other docs absent
#   FR16  routing: meta doc excluded from output
#   FR17  routing: source: generated doc excluded from output
#   FR18  routing: INDEX.md excluded from output
#   FR19  routing: README.md excluded from output
#   FR20  routing: STATE.md excluded from output
#   FR21  isolation canary: no .aid directory appeared under real HOME
#
# ISOLATION:
#   HOME pinned to a throwaway dir before any script invocation.
#   Real HOME .aid snapshot taken before/after to detect escapes (CI-safe canary).
#   All invocations pass explicit --root / --repo pointing at the mktemp fixture repo.
#   The fixture git repo lives entirely in scratch; AID repo git history is never touched.
#
# Usage:
#   HOME=$(mktemp -d) bash tests/canonical/test-kb-freshness-check.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/canonical/aid/scripts/kb/kb-freshness-check.sh"

if [[ ! -f "$SCRIPT" ]]; then
    fail "FR00 setup -- kb-freshness-check.sh not found at $SCRIPT"
    test_summary
    exit 1
fi

# ---------------------------------------------------------------------------
# Global tmpdir -- all scratch + fixture repos live here; cleaned on EXIT.
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# HOME pin: write all home-relative IO to a throwaway dir.
# Save REAL_HOME for the isolation canary.
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | LC_ALL=C sort || true)"
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

# ---------------------------------------------------------------------------
# FR01 -- Build git fixture repo with scripted commit history.
#
# Layout inside FIXREPO:
#   .aid/knowledge/
#     suspect-doc.md  -- sources: [docs/source-a.md]; will be stale after baseline
#     current-doc.md  -- sources: [docs/source-b.md]; will remain current after baseline
#     url-doc.md      -- sources: [https://example.com/spec]; URL always unknown
#     premig-doc.md   -- no approved_at_commit at all; unknown
#     untracked-doc.md -- sources: [docs/untracked.md] (never committed); unknown
#     nosources-doc.md -- no sources: field at all; current
#     emptysources-doc.md -- sources: []; current
#     meta-doc.md     -- kb-category: meta; EXCLUDED by routing
#     generated-doc.md -- source: generated; EXCLUDED by routing
#     INDEX.md        -- excluded by name
#     README.md       -- excluded by name
#     STATE.md        -- excluded by name
#   docs/
#     source-a.md     -- changed AFTER baseline commit (-> suspect)
#     source-b.md     -- NOT changed after baseline commit (-> current)
#
# Git history:
#   C1: initial commit -- docs/source-a.md + docs/source-b.md + all KB docs
#   C2: change docs/source-a.md ONLY (this commit is AFTER C1 which is the approval baseline)
#
# KB docs record approved_at_commit: C1 for the docs that have it.
# After C2, source-a.md's last-changed commit is C2, which is NOT an ancestor of C1
#   => merge-base --is-ancestor C2 C1 returns exit 1 => suspect.
# source-b.md's last-changed commit is still C1, ancestor of C1 (equal) => current.
# ---------------------------------------------------------------------------

FIXREPO="${TMP}/fixture-repo"
mkdir -p "${FIXREPO}/.aid/knowledge"
mkdir -p "${FIXREPO}/docs"

cd "${FIXREPO}"
git init -q
git config user.email "test@aid-suite"
git config user.name "AID Test"

# Write initial source files
printf 'initial content of source-a\n' > "${FIXREPO}/docs/source-a.md"
printf 'initial content of source-b\n' > "${FIXREPO}/docs/source-b.md"

# Write placeholder KB docs (approved_at_commit filled in after C1)
# url-doc, premig, untracked, nosources, emptysources, meta, generated, routed names
# Use distinct placeholder for approved_at_commit that we replace after C1.

write_kb_doc() {
    # write_kb_doc <path> <content>
    printf '%s' "$2" > "$1"
}

write_kb_doc "${FIXREPO}/.aid/knowledge/url-doc.md" "---
kb-category: primary
source: hand-authored
approved_at_commit: PLACEHOLDER
sources:
  - https://example.com/spec
---
URL source doc.
"

write_kb_doc "${FIXREPO}/.aid/knowledge/premig-doc.md" "---
kb-category: primary
source: hand-authored
sources:
  - docs/source-b.md
---
Pre-migration doc (no approved_at_commit).
"

write_kb_doc "${FIXREPO}/.aid/knowledge/untracked-doc.md" "---
kb-category: primary
source: hand-authored
approved_at_commit: PLACEHOLDER
sources:
  - docs/untracked.md
---
Source was never committed.
"

write_kb_doc "${FIXREPO}/.aid/knowledge/nosources-doc.md" "---
kb-category: primary
source: hand-authored
approved_at_commit: PLACEHOLDER
---
No sources field at all.
"

write_kb_doc "${FIXREPO}/.aid/knowledge/emptysources-doc.md" "---
kb-category: primary
source: hand-authored
approved_at_commit: PLACEHOLDER
sources: []
---
Empty inline sources list.
"

write_kb_doc "${FIXREPO}/.aid/knowledge/meta-doc.md" "---
kb-category: meta
source: hand-authored
approved_at_commit: PLACEHOLDER
sources:
  - docs/source-b.md
---
Meta doc (routing exclusion).
"

write_kb_doc "${FIXREPO}/.aid/knowledge/generated-doc.md" "---
kb-category: primary
source: generated
generator: some-generator.sh
approved_at_commit: PLACEHOLDER
---
Generated doc (routing exclusion).
"

write_kb_doc "${FIXREPO}/.aid/knowledge/INDEX.md" "---
kb-category: primary
source: generated
---
INDEX routing exclusion.
"

write_kb_doc "${FIXREPO}/.aid/knowledge/README.md" "---
kb-category: meta
source: hand-authored
---
README routing exclusion.
"

write_kb_doc "${FIXREPO}/.aid/knowledge/STATE.md" "---
kb-category: meta
source: hand-authored
---
STATE routing exclusion.
"

# Temporary placeholders for suspect-doc and current-doc (approved_at_commit set after C1)
write_kb_doc "${FIXREPO}/.aid/knowledge/suspect-doc.md" "---
kb-category: primary
source: hand-authored
approved_at_commit: PLACEHOLDER
sources:
  - docs/source-a.md
---
Suspect doc: source-a will change after baseline.
"

write_kb_doc "${FIXREPO}/.aid/knowledge/current-doc.md" "---
kb-category: primary
source: hand-authored
approved_at_commit: PLACEHOLDER
sources:
  - docs/source-b.md
---
Current doc: source-b will NOT change after baseline.
"

# Stage and create C1
git add .
git commit -q -m "C1: initial commit -- all sources at baseline"
C1="$(git rev-parse HEAD)"

# Now fill in the real C1 hash as approved_at_commit in all docs that need it
for doc in url-doc untracked-doc nosources-doc emptysources-doc meta-doc generated-doc suspect-doc current-doc; do
    f="${FIXREPO}/.aid/knowledge/${doc}.md"
    # Replace PLACEHOLDER with actual C1 hash
    tmp_f="${TMP}/tmp-doc.md"
    sed "s/PLACEHOLDER/${C1}/" "$f" > "$tmp_f"
    mv "$tmp_f" "$f"
done

# Stage the updated KB docs and create C2: also change source-a.md
printf 'modified content of source-a -- this change is AFTER the baseline C1\n' \
    > "${FIXREPO}/docs/source-a.md"

git add .
git commit -q -m "C2: update source-a.md after baseline (makes suspect-doc stale)"
C2="$(git rev-parse HEAD)"

# Verify ancestry: C1 should be an ancestor of C2 (C1 comes before C2)
# C2 is NOT an ancestor of C1 (C2 came after C1)
rc_ancestor=0
git -C "${FIXREPO}" merge-base --is-ancestor "$C1" "$C2" 2>/dev/null || rc_ancestor=$?
if [[ "$rc_ancestor" -eq 0 ]]; then
    pass "FR01 git fixture: C1 is ancestor of C2 (history correct)"
else
    fail "FR01 git fixture: C1 should be ancestor of C2 (rc=$rc_ancestor)"
fi

# C2 should NOT be ancestor of C1
rc_not_ancestor=0
git -C "${FIXREPO}" merge-base --is-ancestor "$C2" "$C1" 2>/dev/null || rc_not_ancestor=$?
if [[ "$rc_not_ancestor" -eq 1 ]]; then
    pass "FR01 git fixture: C2 is NOT ancestor of C1 (merge-base logic correct)"
else
    fail "FR01 git fixture: C2 should NOT be ancestor of C1 (rc=$rc_not_ancestor)"
fi

KB_ROOT="${FIXREPO}/.aid/knowledge"

# ---------------------------------------------------------------------------
# FR02 -- suspect verdict: source changed after approved_at_commit
# ---------------------------------------------------------------------------
out_fr02="$(bash "$SCRIPT" --root "$KB_ROOT" --repo "$FIXREPO" --format tsv)"
suspect_row="$(echo "$out_fr02" | grep '^suspect-doc\.md' || true)"

if [[ -n "$suspect_row" ]]; then
    verdict_fr02="$(echo "$suspect_row" | cut -f2)"
    assert_eq "$verdict_fr02" "suspect" "FR02 suspect verdict for source changed after baseline"
else
    fail "FR02 suspect verdict -- suspect-doc.md not found in TSV output"
fi

# ---------------------------------------------------------------------------
# FR03 -- suspect_sources_csv populated with the drifted path
# ---------------------------------------------------------------------------
if [[ -n "$suspect_row" ]]; then
    suspect_csv="$(echo "$suspect_row" | cut -f7)"
    assert_eq "$suspect_csv" "docs/source-a.md" \
        "FR03 suspect_sources_csv contains the drifted source path"
else
    fail "FR03 suspect_sources_csv -- suspect-doc.md row absent"
fi

# ---------------------------------------------------------------------------
# FR04 -- current verdict: source at-or-before approved_at_commit
# ---------------------------------------------------------------------------
current_row="$(echo "$out_fr02" | grep '^current-doc\.md' || true)"
if [[ -n "$current_row" ]]; then
    verdict_fr04="$(echo "$current_row" | cut -f2)"
    assert_eq "$verdict_fr04" "current" "FR04 current verdict for source unchanged after baseline"
else
    fail "FR04 current verdict -- current-doc.md not found in TSV output"
fi

# ---------------------------------------------------------------------------
# FR05 -- unknown verdict: URL source
# ---------------------------------------------------------------------------
url_row="$(echo "$out_fr02" | grep '^url-doc\.md' || true)"
if [[ -n "$url_row" ]]; then
    verdict_fr05="$(echo "$url_row" | cut -f2)"
    assert_eq "$verdict_fr05" "unknown" "FR05 unknown verdict for URL source"
else
    fail "FR05 unknown verdict (URL) -- url-doc.md not found in TSV output"
fi

# ---------------------------------------------------------------------------
# FR06 -- unknown verdict: no approved_at_commit (pre-migration doc)
# ---------------------------------------------------------------------------
premig_row="$(echo "$out_fr02" | grep '^premig-doc\.md' || true)"
if [[ -n "$premig_row" ]]; then
    verdict_fr06="$(echo "$premig_row" | cut -f2)"
    assert_eq "$verdict_fr06" "unknown" "FR06 unknown verdict for missing approved_at_commit"
else
    fail "FR06 unknown verdict (pre-migration) -- premig-doc.md not found in TSV output"
fi

# ---------------------------------------------------------------------------
# FR07 -- unknown verdict: untracked source (git log returns empty)
# ---------------------------------------------------------------------------
untracked_row="$(echo "$out_fr02" | grep '^untracked-doc\.md' || true)"
if [[ -n "$untracked_row" ]]; then
    verdict_fr07="$(echo "$untracked_row" | cut -f2)"
    assert_eq "$verdict_fr07" "unknown" "FR07 unknown verdict for untracked source"
else
    fail "FR07 unknown verdict (untracked) -- untracked-doc.md not found in TSV output"
fi

# ---------------------------------------------------------------------------
# FR08 -- current verdict: sources: field absent entirely
# ---------------------------------------------------------------------------
nosrc_row="$(echo "$out_fr02" | grep '^nosources-doc\.md' || true)"
if [[ -n "$nosrc_row" ]]; then
    verdict_fr08="$(echo "$nosrc_row" | cut -f2)"
    assert_eq "$verdict_fr08" "current" "FR08 current verdict for absent sources: field"
else
    fail "FR08 current verdict (no sources field) -- nosources-doc.md not found in TSV output"
fi

# ---------------------------------------------------------------------------
# FR09 -- current verdict: sources: [] (empty inline list)
# ---------------------------------------------------------------------------
emptysrc_row="$(echo "$out_fr02" | grep '^emptysources-doc\.md' || true)"
if [[ -n "$emptysrc_row" ]]; then
    verdict_fr09="$(echo "$emptysrc_row" | cut -f2)"
    assert_eq "$verdict_fr09" "current" "FR09 current verdict for sources: [] empty list"
else
    fail "FR09 current verdict (empty sources) -- emptysources-doc.md not found in TSV output"
fi

# ---------------------------------------------------------------------------
# FR10 -- TSV column order: 7 tab-separated columns in declared stable order
#   doc-relpath, verdict, approved_at_commit, n_current, n_suspect, n_unknown, suspect_sources_csv
# ---------------------------------------------------------------------------
# Use the suspect row as the canonical check (all 7 fields populated)
if [[ -n "$suspect_row" ]]; then
    col_count="$(echo "$suspect_row" | awk -F'\t' '{print NF}')"
    assert_eq "$col_count" "7" "FR10 TSV row has exactly 7 tab-separated columns"

    col1="$(echo "$suspect_row" | cut -f1)"
    col2="$(echo "$suspect_row" | cut -f2)"
    col3="$(echo "$suspect_row" | cut -f3)"
    col4="$(echo "$suspect_row" | cut -f4)"
    col5="$(echo "$suspect_row" | cut -f5)"
    col6="$(echo "$suspect_row" | cut -f6)"
    col7="$(echo "$suspect_row" | cut -f7)"

    assert_eq "$col1" "suspect-doc.md" "FR10 col1 = doc-relpath"
    assert_eq "$col2" "suspect" "FR10 col2 = verdict"
    assert_eq "$col3" "$C1" "FR10 col3 = approved_at_commit (C1 hash)"
    # col4 = n_current (0 for a doc whose only source is suspect)
    assert_eq "$col4" "0" "FR10 col4 = n_current (0)"
    # col5 = n_suspect (1)
    assert_eq "$col5" "1" "FR10 col5 = n_suspect (1)"
    # col6 = n_unknown (0)
    assert_eq "$col6" "0" "FR10 col6 = n_unknown (0)"
    # col7 = suspect_sources_csv
    assert_eq "$col7" "docs/source-a.md" "FR10 col7 = suspect_sources_csv"
else
    fail "FR10 TSV column order -- suspect-doc.md row absent"
fi

# ---------------------------------------------------------------------------
# FR11 -- TSV byte-reproducibility: sha256 identical across two consecutive runs
# ---------------------------------------------------------------------------
tsv_file1="${TMP}/run1.tsv"
tsv_file2="${TMP}/run2.tsv"

bash "$SCRIPT" --root "$KB_ROOT" --repo "$FIXREPO" --format tsv > "$tsv_file1"
bash "$SCRIPT" --root "$KB_ROOT" --repo "$FIXREPO" --format tsv > "$tsv_file2"

sha1="$(sha256sum "$tsv_file1" | cut -d' ' -f1)"
sha2="$(sha256sum "$tsv_file2" | cut -d' ' -f1)"

if [[ "$sha1" == "$sha2" ]]; then
    pass "FR11 TSV byte-reproducibility: sha256 identical across two runs"
else
    fail "FR11 TSV byte-reproducibility: sha256 differs between runs (sha1=$sha1 sha2=$sha2)"
    if [[ "$VERBOSE" -eq 1 ]]; then
        diff "$tsv_file1" "$tsv_file2" || true
    fi
fi

# Also verify diff is clean
if diff -q "$tsv_file1" "$tsv_file2" >/dev/null 2>&1; then
    pass "FR11 TSV byte-reproducibility: diff clean between two runs"
else
    fail "FR11 TSV byte-reproducibility: diff shows differences between two runs"
fi

# ---------------------------------------------------------------------------
# FR12 -- exit code 0 on a scan that yields a suspect doc
# ---------------------------------------------------------------------------
rc_fr12=0
bash "$SCRIPT" --root "$KB_ROOT" --repo "$FIXREPO" --format tsv > /dev/null 2>&1 || rc_fr12=$?
assert_exit_zero "$rc_fr12" "FR12 exit code 0 on successful scan (even with suspect docs)"

# ---------------------------------------------------------------------------
# FR13 -- exit code 1 on argument error (unknown flag)
# ---------------------------------------------------------------------------
rc_fr13=0
bash "$SCRIPT" --unknown-flag 2>/dev/null || rc_fr13=$?
assert_exit_eq "$rc_fr13" "1" "FR13 exit code 1 on argument error"

# ---------------------------------------------------------------------------
# FR14 -- text-format smoke: default invocation renders current/suspect/unknown
# ---------------------------------------------------------------------------
text_out="$(bash "$SCRIPT" --root "$KB_ROOT" --repo "$FIXREPO")"

# Each verdict class should appear in the text output
if echo "$text_out" | grep -qF "current"; then
    pass "FR14 text format: 'current' verdict line present"
else
    fail "FR14 text format: 'current' verdict not found in text output"
fi

if echo "$text_out" | grep -qF "suspect"; then
    pass "FR14 text format: 'suspect' verdict line present"
else
    fail "FR14 text format: 'suspect' verdict not found in text output"
fi

if echo "$text_out" | grep -qF "unknown"; then
    pass "FR14 text format: 'unknown' verdict line present"
else
    fail "FR14 text format: 'unknown' verdict not found in text output"
fi

# Verify verdict parity: TSV and text rows cover the same set of docs
# (same count of checked docs -- routing-excluded docs should not appear in either)
tsv_doc_count="$(echo "$out_fr02" | grep -c '	' || true)"
# text output: non-header, non-separator lines that contain a verdict
text_verdict_count="$(echo "$text_out" | grep -E 'current|suspect|unknown' | grep -v '^DOC' | grep -v '^-' | wc -l | tr -d ' ')"
if [[ "$tsv_doc_count" -eq "$text_verdict_count" ]]; then
    pass "FR14 text format: verdict count matches TSV row count ($tsv_doc_count docs)"
else
    fail "FR14 text format: text verdict count ($text_verdict_count) != TSV row count ($tsv_doc_count)"
fi

# ---------------------------------------------------------------------------
# FR15 -- --doc single-filter returns ONLY the target doc; other docs absent
# ---------------------------------------------------------------------------
filter_out="$(bash "$SCRIPT" --root "$KB_ROOT" --repo "$FIXREPO" --format tsv --doc "suspect-doc.md")"
filter_rows="$(echo "$filter_out" | grep -c '.' || true)"

# Should have exactly 1 row
assert_eq "$filter_rows" "1" "FR15 --doc filter: exactly 1 row returned"

# That row must be for suspect-doc.md
if echo "$filter_out" | grep -qF "suspect-doc.md"; then
    pass "FR15 --doc filter: target doc present in output"
else
    fail "FR15 --doc filter: target doc not found in single-doc output"
fi

# Other docs must NOT be present
assert_output_not_contains "$filter_out" "current-doc.md" \
    "FR15 --doc filter: current-doc.md absent from single-doc output"
assert_output_not_contains "$filter_out" "url-doc.md" \
    "FR15 --doc filter: url-doc.md absent from single-doc output"
assert_output_not_contains "$filter_out" "premig-doc.md" \
    "FR15 --doc filter: premig-doc.md absent from single-doc output"

# ---------------------------------------------------------------------------
# FR16 -- routing: meta doc excluded from output
# ---------------------------------------------------------------------------
assert_output_not_contains "$out_fr02" "meta-doc.md" \
    "FR16 routing: meta-doc.md (kb-category: meta) excluded from output"

# ---------------------------------------------------------------------------
# FR17 -- routing: source: generated doc excluded from output
# ---------------------------------------------------------------------------
assert_output_not_contains "$out_fr02" "generated-doc.md" \
    "FR17 routing: generated-doc.md (source: generated) excluded from output"

# ---------------------------------------------------------------------------
# FR18 -- routing: INDEX.md excluded from output
# ---------------------------------------------------------------------------
assert_output_not_contains "$out_fr02" "INDEX.md" \
    "FR18 routing: INDEX.md excluded from output by name"

# ---------------------------------------------------------------------------
# FR19 -- routing: README.md excluded from output
# ---------------------------------------------------------------------------
assert_output_not_contains "$out_fr02" "README.md" \
    "FR19 routing: README.md excluded from output by name"

# ---------------------------------------------------------------------------
# FR20 -- routing: STATE.md excluded from output
# ---------------------------------------------------------------------------
assert_output_not_contains "$out_fr02" "STATE.md" \
    "FR20 routing: STATE.md excluded from output by name"

# ---------------------------------------------------------------------------
# FR21 -- isolation canary: no .aid directory appeared under real HOME
# ---------------------------------------------------------------------------
_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | LC_ALL=C sort || true)"
if [[ "$_CANARY_BEFORE" == "$_CANARY_AFTER" ]]; then
    pass "FR21 isolation canary: no new .aid directory appeared under real HOME"
else
    fail "FR21 isolation canary: new .aid directories detected under real HOME"
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo "BEFORE: $_CANARY_BEFORE"
        echo "AFTER:  $_CANARY_AFTER"
    fi
fi

# ---------------------------------------------------------------------------
test_summary
exit $?
