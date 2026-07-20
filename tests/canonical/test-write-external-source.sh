#!/usr/bin/env bash
# test-write-external-source.sh -- unit tests for
# dashboard/scripts/write-external-source.sh (feature-010-external-sources-list,
# work-017 task-020): the atomic single-entry add/remove writer for a KB
# external-sources.md registry's frontmatter `sources:` list + `## Sources` body mirror.
#
# Tests cover:
#   U1   add: happy path -- contiguous `  - <v>` item inserted, exit 0
#   U2   add: reader-visibility (AC2) -- parse_doc_frontmatter (Python reader twin) sees
#        the added value in sources_list after the write
#   U3   add: idempotent -- a repeat add of an already-present value is an exit-0 no-op
#        with the file byte-for-byte unchanged
#   U4   add: drops a lone `- (none)` placeholder (even when preceded by a comment line
#        that breaks contiguity) and normalizes to a clean contiguous block
#   U5   add: the written item line carries no inline `# comment`
#   U6   add: first add replaces the "No external documentation..." placeholder
#        paragraph with the managed bullet block (bounded by the marker pair)
#   U7   remove: happy path -- matching frontmatter item + body bullet removed
#   U8   remove: emptying the real list writes `sources: []` and restores the canonical
#        placeholder paragraph in the body
#   U9   remove: absent value -> exit 1, file left byte-for-byte unchanged
#   U10  add/remove: a pre-existing hand-authored table in ## Sources is preserved
#        verbatim; the managed block is inserted adjacent on add and fully removed
#        (table intact) when the list empties again
#   U11  value validation: embedded whitespace -> exit 4
#   U12  value validation: embedded newline -> exit 4
#   U13  value validation: embedded '|' -> exit 4
#   U14  value validation: empty --value -> exit 4
#   U15  invalid --op -> exit 4
#   U16  missing --op -> exit 4
#   U17  missing --value -> exit 4
#   U18  unknown flag -> exit 4
#   U19  -h/--help -> exit 0, usage printed
#   U20  target file missing -> exit 3
#   U21  atomic write -- no stray temp file left behind under the target directory
#   U22  every non-target line (unrelated frontmatter scalars, unrelated body
#        sections) is byte-preserved across an add
#   U23  CRLF source file -- line endings preserved throughout (frontmatter + body)
#   U24  both a URL value and a whitespace-free path/glob value are accepted
#   U25  --file defaults to .aid/knowledge/external-sources.md (relative to CWD)
#   U26  dashboard/MANIFEST lists this writer (co-vendor guard; the fuller check is
#        tests/canonical/test-dashboard-manifest.sh -- this is a lightweight sanity dup)
#
# Usage:
#   bash tests/canonical/test-write-external-source.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/dashboard/scripts/write-external-source.sh"

source "${SCRIPT_DIR}/../lib/assert.sh"

if [[ ! -f "$SUT" ]]; then
    echo "FATAL: SUT not found at $SUT"
    exit 2
fi

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

echo "== write-external-source.sh tests =="

PLACEHOLDER='No external documentation was provided during discovery. All knowledge was derived from repository content only. If external documentation becomes available, re-run discovery or add paths during Q&A.'

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# fixture_seed_none FILE -- the live-repo shape: `- (none)` placeholder preceded
# by a comment line (breaks reader contiguity today), placeholder body paragraph.
fixture_seed_none() {
    cat > "$1" <<EOF
---
kb-category: meta
source: hand-authored
objective: Registry of external documentation, vendor specs, and reference URLs the project depends on.
summary: Read this before fetching documentation that may already be cataloged here.
sources:
  # EXTERNAL URLs/docs cataloged in this registry (none provided during discovery).
  - (none)
tags: [meta, external-docs, vendor-specs, references]
see_also: [integration-map.md]
owner: architect
audience: [developer, architect]
---

# External Sources

## Contents

- [Sources](#sources)
- [Change Log](#change-log)

---

## Sources

$PLACEHOLDER

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial external source analysis (none provided) |
EOF
}

# fixture_hand_table FILE -- a doc with a pre-existing hand-authored rich table
# in ## Sources (the discover-authored form this writer must never synthesize
# and must never clobber).
fixture_hand_table() {
    cat > "$1" <<'EOF'
---
kb-category: primary
source: hand-authored
sources:
  - /some/path/already/there
tags: [external-docs]
---

# External Sources

## Sources

> List all external documentation provided by the user.

| # | Path | Type | Accessible | Key Content |
|---|------|------|------------|-------------|
| 1 | /path/to/docs | directory | yes | Some inventory |

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-01-01 | aid-discover | seed |
EOF
}

# Python-friendly (native-Windows) absolute paths: on a Cygwin/MSYS bash, a
# native `python3.exe` cannot resolve a POSIX-style path like `/c/Projects/...`
# (it silently fails to find any module rooted there), so REPO_ROOT/paths must
# be converted via `cygpath -w` before being handed to python. Harmless no-op
# on Linux/macOS CI, where cygpath is absent and paths are already native.
to_py_path() {
    local p="$1"
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$p"
    else
        printf '%s' "$p"
    fi
}
PY_REPO_ROOT="$(to_py_path "$REPO_ROOT")"

# reader_sources_list FILE -- invoke the Python reader twin's parse_doc_frontmatter
# and print its sources_list as newline-separated items (AC2 assertion helper).
# Written to a temp .py file (not a multi-line `python3 -c "..."` string): some
# python launchers on this platform (e.g. a pyenv-win shim) mishandle a
# multi-line -c argument, so a file invocation is used for portability.
reader_sources_list() {
    local f="$1"
    local py_f
    py_f="$(to_py_path "$f")"
    local py="${TMPDIR_BASE}/_reader_check.py"
    cat > "$py" <<PYEOF
import sys
sys.path.insert(0, r"${PY_REPO_ROOT}")
from dashboard.reader import parsers
from pathlib import Path
_, items, _ = parsers.parse_doc_frontmatter(Path(r"${py_f}"))
for it in items:
    print(it)
PYEOF
    python3 "$py"
}

# ---------------------------------------------------------------------------
# U1 -- add happy path
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u1.md"
fixture_seed_none "$f"
out=$(bash "$SUT" --op add --value "https://example.com/docs" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U1 add exits 0"
assert_file_contains "$f" "  - https://example.com/docs" "U1 contiguous frontmatter item inserted"
assert_file_not_contains "$f" "- (none)" "U1 (none) placeholder dropped"

# ---------------------------------------------------------------------------
# U2 -- reader-visibility (AC2)
# ---------------------------------------------------------------------------
if command -v python3 >/dev/null 2>&1; then
    got=$(reader_sources_list "$f")
    if echo "$got" | grep -qxF "https://example.com/docs"; then
        pass "U2 parse_doc_frontmatter sees the added value (AC2)"
    else
        fail "U2 parse_doc_frontmatter did NOT see the added value; got: [$got]"
    fi
else
    fail "U2 python3 not found; cannot verify reader-visibility"
fi

# ---------------------------------------------------------------------------
# U3 -- idempotent add (no-op, byte-identical)
# ---------------------------------------------------------------------------
before=$(cat "$f")
out=$(bash "$SUT" --op add --value "https://example.com/docs" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U3 repeat add exits 0"
after=$(cat "$f")
assert_eq "$after" "$before" "U3 repeat add leaves file byte-for-byte unchanged"
assert_output_contains "$out" "no-op" "U3 trace line reports no-op"

# ---------------------------------------------------------------------------
# U4 -- (none) placeholder dropped + contiguous normalization (fresh fixture,
# add a SECOND value to confirm both land in one contiguous block)
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u4.md"
fixture_seed_none "$f"
bash "$SUT" --op add --value "docs/spec.pdf" --file "$f" >/dev/null 2>&1
assert_file_contains "$f" "  - docs/spec.pdf" "U4 first real value inserted"
assert_file_not_contains "$f" "(none)" "U4 placeholder fully dropped"
# The sources: block must be contiguous: no comment line survives between
# 'sources:' and its item.
block=$(awk '/^sources:/{f=1;next} f && /^[a-z]/{exit} f{print}' "$f")
if echo "$block" | grep -q '^[[:space:]]*#'; then
    fail "U4 a comment line survives inside the sources: block (breaks reader contiguity)"
else
    pass "U4 sources: block is contiguous (no interstitial comment)"
fi

# ---------------------------------------------------------------------------
# U5 -- no inline comment on the written item line
# ---------------------------------------------------------------------------
assert_file_not_contains "$f" "docs/spec.pdf  #" "U5 item line carries no inline comment"

# ---------------------------------------------------------------------------
# U6 -- body mirror: placeholder replaced by the managed bullet block
# ---------------------------------------------------------------------------
assert_file_contains "$f" "<!-- managed:external-sources -->" "U6 managed block start marker present"
assert_file_contains "$f" "<!-- /managed:external-sources -->" "U6 managed block end marker present"
assert_file_contains "$f" "- docs/spec.pdf" "U6 body bullet mirrors the added value"
assert_file_not_contains "$f" "$PLACEHOLDER" "U6 placeholder paragraph replaced"

# ---------------------------------------------------------------------------
# U7 -- remove happy path
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u7.md"
fixture_seed_none "$f"
bash "$SUT" --op add --value "https://a.example.com" --file "$f" >/dev/null 2>&1
bash "$SUT" --op add --value "https://b.example.com" --file "$f" >/dev/null 2>&1
out=$(bash "$SUT" --op remove --value "https://a.example.com" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U7 remove exits 0"
assert_file_not_contains "$f" "https://a.example.com" "U7 removed value gone from frontmatter+body"
assert_file_contains "$f" "https://b.example.com" "U7 sibling value untouched"

# ---------------------------------------------------------------------------
# U8 -- removing the last entry empties to sources: [] and restores placeholder
# ---------------------------------------------------------------------------
out=$(bash "$SUT" --op remove --value "https://b.example.com" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U8 remove last entry exits 0"
assert_file_contains "$f" "sources: []" "U8 empty list writes sources: []"
assert_file_contains "$f" "$PLACEHOLDER" "U8 canonical placeholder paragraph restored"
assert_file_not_contains "$f" "managed:external-sources" "U8 managed markers gone once list is empty"

# ---------------------------------------------------------------------------
# U9 -- remove absent value -> exit 1, unchanged
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u9.md"
fixture_seed_none "$f"
before=$(cat "$f")
out=$(bash "$SUT" --op remove --value "https://nope.example.com" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 1 "U9 remove absent value exits 1"
after=$(cat "$f")
assert_eq "$after" "$before" "U9 file byte-for-byte unchanged on remove-not-found"

# ---------------------------------------------------------------------------
# U10 -- hand-authored table preserved through add + remove-to-empty
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u10.md"
fixture_hand_table "$f"
bash "$SUT" --op add --value "https://new.example.com" --file "$f" >/dev/null 2>&1
assert_file_contains "$f" "| 1 | /path/to/docs | directory | yes | Some inventory |" "U10 hand-authored table row preserved after add"
assert_file_contains "$f" "> List all external documentation provided by the user." "U10 hand-authored blockquote preserved after add"
assert_file_contains "$f" "<!-- managed:external-sources -->" "U10 managed block inserted adjacent to table"
bash "$SUT" --op remove --value "https://new.example.com" --file "$f" >/dev/null 2>&1
bash "$SUT" --op remove --value "/some/path/already/there" --file "$f" >/dev/null 2>&1
assert_file_contains "$f" "| 1 | /path/to/docs | directory | yes | Some inventory |" "U10 hand-authored table row survives full drain"
assert_file_not_contains "$f" "managed:external-sources" "U10 managed block removed once list empties (table-only left)"
assert_file_contains "$f" "sources: []" "U10 frontmatter empties to sources: []"

# ---------------------------------------------------------------------------
# U11/U12/U13/U14 -- value validation
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u11.md"
fixture_seed_none "$f"
out=$(bash "$SUT" --op add --value "bad value" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U11 embedded whitespace exits 4"

out=$(bash "$SUT" --op add --value $'bad\nvalue' --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U12 embedded newline exits 4"

out=$(bash "$SUT" --op add --value "bad|value" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U13 embedded '|' exits 4"

out=$(bash "$SUT" --op add --value "" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U14 empty --value exits 4"

# ---------------------------------------------------------------------------
# U15/U16/U17/U18 -- arg validation
# ---------------------------------------------------------------------------
out=$(bash "$SUT" --op bogus --value "https://x.example.com" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U15 invalid --op exits 4"

out=$(bash "$SUT" --value "https://x.example.com" --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U16 missing --op exits 4"

out=$(bash "$SUT" --op add --file "$f" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U17 missing --value exits 4"

out=$(bash "$SUT" --op add --value "https://x.example.com" --bogus 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U18 unknown flag exits 4"

# ---------------------------------------------------------------------------
# U19 -- -h/--help
# ---------------------------------------------------------------------------
out=$(bash "$SUT" -h 2>&1)
ec=$?
assert_exit_zero "$ec" "U19 -h exits 0"
assert_output_contains "$out" "Usage:" "U19 usage text printed"

# ---------------------------------------------------------------------------
# U20 -- target file missing
# ---------------------------------------------------------------------------
out=$(bash "$SUT" --op add --value "https://x.example.com" --file "${TMPDIR_BASE}/does-not-exist.md" 2>&1)
ec=$?
assert_exit_eq "$ec" 3 "U20 missing target file exits 3"

# ---------------------------------------------------------------------------
# U21 -- atomic write: no stray temp file left under the target directory
# ---------------------------------------------------------------------------
u21_dir="${TMPDIR_BASE}/u21"
mkdir -p "$u21_dir"
f="${u21_dir}/external-sources.md"
fixture_seed_none "$f"
bash "$SUT" --op add --value "https://x.example.com" --file "$f" >/dev/null 2>&1
leftover=$(find "$u21_dir" -maxdepth 1 -name '.write-external-source.*' 2>/dev/null)
if [[ -z "$leftover" ]]; then
    pass "U21 no stray temp file left under target directory"
else
    fail "U21 stray temp file found: $leftover"
fi

# ---------------------------------------------------------------------------
# U22 -- byte-preservation of every non-target line
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u22.md"
fixture_seed_none "$f"
bash "$SUT" --op add --value "https://x.example.com" --file "$f" >/dev/null 2>&1
assert_file_contains "$f" "kb-category: meta" "U22 unrelated frontmatter scalar preserved"
assert_file_contains "$f" "see_also: [integration-map.md]" "U22 unrelated frontmatter list preserved"
assert_file_contains "$f" "owner: architect" "U22 unrelated frontmatter scalar 2 preserved"
assert_file_contains "$f" "## Change Log" "U22 unrelated body heading preserved"
assert_file_contains "$f" "| 1.0 | 2026-06-25 | aid-discover | Initial external source analysis (none provided) |" "U22 unrelated body table row preserved"

# ---------------------------------------------------------------------------
# U23 -- CRLF source file: line endings preserved
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u23.md"
printf -- '---\r\nsources:\r\n  - (none)\r\n---\r\n\r\n## Sources\r\n\r\n%s\r\n\r\n---\r\n\r\n## Change Log\r\n' "$PLACEHOLDER" > "$f"
bash "$SUT" --op add --value "https://x.example.com" --file "$f" >/dev/null 2>&1
crlf_count=$(grep -c $'\r$' "$f")
total_lines=$(wc -l < "$f")
if [[ "$crlf_count" -gt 0 && "$crlf_count" -eq "$total_lines" ]]; then
    pass "U23 CRLF line endings preserved on every line"
else
    fail "U23 CRLF preservation broken (crlf_count=$crlf_count total_lines=$total_lines)"
fi
assert_file_contains "$f" "https://x.example.com" "U23 value present in CRLF file"

# ---------------------------------------------------------------------------
# U24 -- URL and path/glob values both accepted
# ---------------------------------------------------------------------------
f="${TMPDIR_BASE}/u24.md"
fixture_seed_none "$f"
out=$(bash "$SUT" --op add --value "https://vendor.example.com/spec.pdf" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U24 URL value accepted"
out=$(bash "$SUT" --op add --value "docs/api/*.yaml" --file "$f" 2>&1)
ec=$?
assert_exit_zero "$ec" "U24 path/glob value accepted"
assert_file_contains "$f" "docs/api/*.yaml" "U24 glob value written verbatim"

# ---------------------------------------------------------------------------
# U25 -- --file defaults to .aid/knowledge/external-sources.md (relative CWD)
# ---------------------------------------------------------------------------
u25_dir="${TMPDIR_BASE}/u25"
mkdir -p "${u25_dir}/.aid/knowledge"
fixture_seed_none "${u25_dir}/.aid/knowledge/external-sources.md"
out=$(cd "$u25_dir" && bash "$SUT" --op add --value "https://default-path.example.com" 2>&1)
ec=$?
assert_exit_zero "$ec" "U25 default --file resolves under CWD"
assert_file_contains "${u25_dir}/.aid/knowledge/external-sources.md" "https://default-path.example.com" "U25 default-path write landed in .aid/knowledge/external-sources.md"

# ---------------------------------------------------------------------------
# U26 -- dashboard/MANIFEST lists this writer (lightweight sanity dup of
# tests/canonical/test-dashboard-manifest.sh's fuller DM01-DM05 coverage)
# ---------------------------------------------------------------------------
if grep -qx "scripts/write-external-source.sh" "${REPO_ROOT}/dashboard/MANIFEST" 2>/dev/null; then
    pass "U26 dashboard/MANIFEST lists scripts/write-external-source.sh"
else
    fail "U26 dashboard/MANIFEST does NOT list scripts/write-external-source.sh"
fi

echo
test_summary
exit $?
