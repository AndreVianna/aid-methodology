#!/usr/bin/env bash
# closure-check.sh -- deterministic single coverage oracle for AID essence capture.
#
# Consumes:
#   .aid/generated/candidate-concepts.md  -- term universe (harvest + synthesis rows)
#   domain-glossary.md                    -- concept spine (defined terms + relates-to)
#   KB docs + their resolved sources: frontmatter
#
# Emits TWO separately-parsable outputs (sections or files):
#
#   (a) Ungrounded / un-closed concept set:
#       term | used-in-doc | anchor
#       A row IS the finding (used-but-not-defined in the spine).
#       Term universe = BOTH harvest and synthesis rows of candidate-concepts.md
#       PLUS spine relates-to terms.
#       Closed => zero rows (loop termination oracle).
#
#   (b) Per-doc sources:-anchored coverage:
#       term | doc | anchoring-source | present|absent
#       absent IS the finding.
#       local-readable-file sources: entries are scanned (literal, case-normalized).
#       URL entries (or unresolvable) -> anchoring-source = N/A, no absent finding.
#
# (A former output (c) -- a per-doc lexical transcription-ratio hint -- was
# retired: transcription ("too fat" / verbatim source copy) is now a reviewer
# judgment the M2 Anatomy mandate makes from the doc text plus output (b)'s
# coverage table, not a noisy mechanical ratio. The oracle ships outputs (a)+(b).)
#
# All scanning: literal/lexical, case-normalized. No fetch, no network.
# Coreutils + git only. ASCII. CI-reproducible (byte-identical re-runs).
#
# Usage:
#   closure-check.sh [--root PATH] [--concepts PATH] [--spine PATH]
#                    [--kb-dir PATH] [--denylist PATH]
#                    [--output-a PATH] [--output-b PATH]
#                    [--output-all PATH]
#
# Defaults (resolved relative to --root or cwd):
#   --concepts  .aid/generated/candidate-concepts.md
#   --spine     .aid/knowledge/domain-glossary.md
#   --kb-dir    .aid/knowledge
#   --denylist  (canonical/aid/scripts/kb/coined-term-denylist.txt or shipped copy)
#   --output-a  stdout (section A)
#   --output-b  stdout (section B)
#   --output-all  if given, both sections written to this single file
#
# Exit codes:
#   0  oracle ran successfully (even if findings exist -- findings are data)
#   1  input error (required file not found, parse error)
#   2  usage error

set -euo pipefail

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
ROOT="."
CONCEPTS_ARG=""
SPINE_ARG=""
KB_DIR_ARG=""
DENYLIST_ARG=""
DISMISSED_ARG=""
OUTPUT_A=""
OUTPUT_B=""
OUTPUT_ALL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)       ROOT="$2";         shift 2 ;;
    --concepts)   CONCEPTS_ARG="$2"; shift 2 ;;
    --spine)      SPINE_ARG="$2";    shift 2 ;;
    --kb-dir)     KB_DIR_ARG="$2";   shift 2 ;;
    --denylist)   DENYLIST_ARG="$2"; shift 2 ;;
    --dismissed)  DISMISSED_ARG="$2"; shift 2 ;;
    --output-a)   OUTPUT_A="$2";     shift 2 ;;
    --output-b)   OUTPUT_B="$2";     shift 2 ;;
    --output-all) OUTPUT_ALL="$2";   shift 2 ;;
    -h|--help)
      sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "closure-check.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve all paths to absolute BEFORE cd into ROOT
# ---------------------------------------------------------------------------
resolve_abs() {
  local p="$1"
  case "$p" in
    /*|[A-Za-z]:[/\\]*) echo "$p" ;;
    *) echo "$PWD/$p" ;;
  esac
}

ROOT=$(resolve_abs "$ROOT")

[[ -n "$CONCEPTS_ARG" ]]  && CONCEPTS_ARG=$(resolve_abs "$CONCEPTS_ARG")
[[ -n "$SPINE_ARG" ]]     && SPINE_ARG=$(resolve_abs "$SPINE_ARG")
[[ -n "$KB_DIR_ARG" ]]    && KB_DIR_ARG=$(resolve_abs "$KB_DIR_ARG")
[[ -n "$DENYLIST_ARG" ]]  && DENYLIST_ARG=$(resolve_abs "$DENYLIST_ARG")
[[ -n "$DISMISSED_ARG" ]] && DISMISSED_ARG=$(resolve_abs "$DISMISSED_ARG")
[[ -n "$OUTPUT_A" ]]      && OUTPUT_A=$(resolve_abs "$OUTPUT_A")
[[ -n "$OUTPUT_B" ]]      && OUTPUT_B=$(resolve_abs "$OUTPUT_B")
[[ -n "$OUTPUT_ALL" ]]    && OUTPUT_ALL=$(resolve_abs "$OUTPUT_ALL")

# Set defaults (relative to ROOT)
CONCEPTS="${CONCEPTS_ARG:-${ROOT}/.aid/generated/candidate-concepts.md}"
SPINE="${SPINE_ARG:-${ROOT}/.aid/knowledge/domain-glossary.md}"
KB_DIR="${KB_DIR_ARG:-${ROOT}/.aid/knowledge}"

# Denylist: try shipped sibling, then root-relative fallback
if [[ -n "$DENYLIST_ARG" ]]; then
  DENYLIST="$DENYLIST_ARG"
else
  # Look for the denylist relative to this script's own directory (shipped sibling)
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "${SCRIPT_DIR}/coined-term-denylist.txt" ]]; then
    DENYLIST="${SCRIPT_DIR}/coined-term-denylist.txt"
  elif [[ -f "${ROOT}/canonical/aid/scripts/kb/coined-term-denylist.txt" ]]; then
    DENYLIST="${ROOT}/canonical/aid/scripts/kb/coined-term-denylist.txt"
  else
    DENYLIST=""
  fi
fi

if [[ -n "$OUTPUT_A" ]]; then mkdir -p "$(dirname "$OUTPUT_A")"; fi
if [[ -n "$OUTPUT_B" ]]; then mkdir -p "$(dirname "$OUTPUT_B")"; fi
if [[ -n "$OUTPUT_ALL" ]]; then mkdir -p "$(dirname "$OUTPUT_ALL")"; fi

# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------
if [[ ! -f "$CONCEPTS" ]]; then
  echo "[closure-check] WARNING: candidate-concepts.md not found at $CONCEPTS -- all outputs will be empty" >&2
fi
if [[ ! -f "$SPINE" ]]; then
  echo "[closure-check] WARNING: spine (domain-glossary.md) not found at $SPINE -- output (a) will be empty" >&2
fi
if [[ ! -d "$KB_DIR" ]]; then
  echo "[closure-check] WARNING: kb-dir not found at $KB_DIR -- output (b) will be empty" >&2
fi

# ---------------------------------------------------------------------------
# Temporary files
# ---------------------------------------------------------------------------
TMPDIR_CC=$(mktemp -d)
trap 'rm -rf "$TMPDIR_CC"' EXIT

TERMS_FILE="${TMPDIR_CC}/terms.txt"       # term (lowercased, one per line, sorted)
DEFINED_FILE="${TMPDIR_CC}/defined.txt"   # defined spine terms (lowercased, sorted)
RELATES_FILE="${TMPDIR_CC}/relates.txt"   # spine relates-to terms (lowercased, sorted)

touch "$TERMS_FILE" "$DEFINED_FILE" "$RELATES_FILE"

# ---------------------------------------------------------------------------
# Helpers: lowercase, normalize
# ---------------------------------------------------------------------------
normalize() {
  # lowercase, collapse multiple spaces
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -s ' '
}

# ---------------------------------------------------------------------------
# Step 1: Extract term universe from candidate-concepts.md
#   Rows with Source=harvest or Source=synthesis contribute their Term column.
#   Format: | # | Source | Term | ... |
# ---------------------------------------------------------------------------
if [[ -f "$CONCEPTS" ]]; then
  # Parse markdown table rows: | digit | harvest|synthesis | `term` | ...
  # The Term column (3rd pipe-delimited field after the leading |) may be wrapped
  # in backticks. We strip them.
  awk -F'|' '
    /\|[[:space:]]*[0-9]+[[:space:]]*\|/ {
      # Field 3 is the Term column (0-indexed from split: $1=empty, $2=#, $3=Source, $4=Term)
      src = $3; sub(/^[[:space:]]+/, "", src); sub(/[[:space:]]+$/, "", src)
      trm = $4; sub(/^[[:space:]]+/, "", trm); sub(/[[:space:]]+$/, "", trm)
      # Strip backticks
      gsub(/`/, "", trm)
      if ((src == "harvest" || src == "synthesis") && trm != "" && trm != "Term") {
        print trm
      }
    }
  ' "$CONCEPTS" | tr '[:upper:]' '[:lower:]' | sort -u > "$TERMS_FILE"
fi

# ---------------------------------------------------------------------------
# Step 2: Extract defined terms and relates-to terms from the spine
#
# Spine structure (domain-glossary.md):
#   ### {ConceptName}            <- concept heading (defined term)
#   **Relates-to:** {term (how), term2 (how)}
#
# We parse:
#   (a) H3 headings under "## Concept Spine" section -> defined terms
#   (b) **Relates-to:** lines -> relates-to terms (comma-separated, strip parens)
# ---------------------------------------------------------------------------
if [[ -f "$SPINE" ]]; then
  awk '
    /^## Concept Spine/ { in_spine=1; next }
    /^## / && in_spine  { in_spine=0 }
    in_spine && /^### / {
      term = $0
      sub(/^### /, "", term)
      # The heading is the term IDENTIFIER. Convention: "### Unique Term (optional
      # explanation)" -- the identifier is the text BEFORE any "(...)", which is a human
      # explanation, not part of the identifier. Strip the parenthetical so a used term
      # resolves to exactly one concept entry (idempotent + identifiable; feature-014).
      sub(/[[:space:]]*\(.*$/, "", term)
      sub(/[[:space:]]+$/, "", term)
      # Strip template placeholders like {ConceptName}
      if (term !~ /^\{/) print "DEFINED:" term
    }
    in_spine && /\*\*Aliases:\*\*/ {
      # Aliases are ALTERNATE IDENTIFIERS for this concept (synonyms used in the docs). They
      # count as DEFINED, exactly like the heading -- so a synonym such as "concept spine"
      # resolves to its concept without a duplicate heading or a parenthetical synonym list.
      line = $0
      sub(/.*\*\*Aliases:\*\*[[:space:]]*/, "", line)
      sub(/[[:space:]]+$/, "", line)
      n = split(line, parts, /,/)
      for (i=1; i<=n; i++) {
        a = parts[i]
        sub(/[[:space:]]*\(.*$/, "", a)
        sub(/^[[:space:]]+/, "", a)
        sub(/[[:space:]]+$/, "", a)
        gsub(/[.;]$/, "", a)
        if (a != "" && a !~ /^\{/) print "DEFINED:" a
      }
    }
    in_spine && /\*\*Relates-to:\*\*/ {
      line = $0
      sub(/.*\*\*Relates-to:\*\*[[:space:]]*/, "", line)
      sub(/[[:space:]]+$/, "", line)
      # Split on commas, strip parens explanations, strip trailing punctuation
      n = split(line, parts, /,/)
      for (i=1; i<=n; i++) {
        t = parts[i]
        sub(/[[:space:]]*\(.*$/, "", t)  # strip (explanation)
        sub(/^[[:space:]]+/, "", t)
        sub(/[[:space:]]+$/, "", t)
        gsub(/[.;]$/, "", t)
        if (t != "" && t !~ /^\{/) print "RELATES:" t
      }
    }
  ' "$SPINE" | awk -F: '
    /^DEFINED:/ { d=$2; sub(/^[[:space:]]+/,"",d); print tolower(d) >> "'"$DEFINED_FILE"'" }
    /^RELATES:/ { r=$2; sub(/^[[:space:]]+/,"",r); print tolower(r) >> "'"$RELATES_FILE"'" }
  '
  sort -u -o "$DEFINED_FILE" "$DEFINED_FILE" 2>/dev/null || true
  sort -u -o "$RELATES_FILE" "$RELATES_FILE" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Step 3: Build unified term universe for output (a)
#   = candidate-concepts.md terms + spine relates-to terms
# ---------------------------------------------------------------------------
UNIVERSE_FILE="${TMPDIR_CC}/universe.txt"
cat "$TERMS_FILE" "$RELATES_FILE" | sort -u > "$UNIVERSE_FILE"

# Subtract EXCLUDED terms from the universe, where EXCLUDED =
#   the coined-term denylist  UNION  the closure loop's own DISMISSED decisions (--dismissed).
# Two structural causes made the oracle un-closable before this:
#   (1) generic code tokens (echo, grep, exit, branch, docs, ...) legitimately appear in KB
#       prose but are NOT concepts -- the denylist covers the ones it lists;
#   (2) project-specific non-concepts (skill names, tokenizer artifacts) that the loop has
#       already DISMISSED in spine-todo.md -- the denylist can never enumerate these, so the
#       loop passes them via --dismissed. Once every used term is GROUNDED (matches a concept
#       heading) or DISMISSED, output (a) is empty and the loop closes deterministically.
# Compare case-insensitively (denylist authored lowercase; dismissed terms lowercased here).
EXCLUDE_LC="${TMPDIR_CC}/exclude_lc.txt"
: > "$EXCLUDE_LC"
if [[ -n "${DENYLIST:-}" && -f "$DENYLIST" ]]; then
  # `|| true`: on an empty/all-comment file the trailing `grep -v` exits 1, which under
  # `set -euo pipefail` would abort the script. The extraction is best-effort.
  LC_ALL=C tr '[:upper:]' '[:lower:]' < "$DENYLIST" \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -v '^[[:space:]]*$' \
    | grep -v '^#' >> "$EXCLUDE_LC" || true
fi
if [[ -n "${DISMISSED_ARG:-}" && -f "$DISMISSED_ARG" ]]; then
  LC_ALL=C tr '[:upper:]' '[:lower:]' < "$DISMISSED_ARG" \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -v '^[[:space:]]*$' \
    | grep -v '^#' >> "$EXCLUDE_LC" || true
fi
if [[ -s "$EXCLUDE_LC" ]]; then
  LC_ALL=C sort -u -o "$EXCLUDE_LC" "$EXCLUDE_LC"
  univ_lc="${TMPDIR_CC}/universe_lc.txt"
  LC_ALL=C tr '[:upper:]' '[:lower:]' < "$UNIVERSE_FILE" | LC_ALL=C sort -u > "$univ_lc"
  LC_ALL=C comm -23 "$univ_lc" "$EXCLUDE_LC" > "${UNIVERSE_FILE}.filtered" \
    && mv "${UNIVERSE_FILE}.filtered" "$UNIVERSE_FILE"
fi

# ---------------------------------------------------------------------------
# Term normalization:
#   #1 slash-split  -- a compound joined by "/" is treated as its separate words; each part
#                      is its own term (e.g. "canonical / profile" -> "canonical", "profile").
#   #2 singular     -- a best-effort FILTER for REGULAR plurals (-s/-es/-ies, e.g. "tasks" ->
#                      "task"), applied symmetrically to defined identifiers and used terms. It
#                      is NOT a full lemmatizer: irregular plurals (indices/index, matrices/
#                      matrix, people/person) that escape it stay flagged and defer to the user
#                      via the exclusion-review gate (Step 5c) / Q&A -- typically resolved as an
#                      alias. Do NOT extend this to chase irregular plurals (NO-ASSUMPTIONS).
# norm_terms reads terms on stdin and emits their normalized parts (one per line, lowercase).
# ---------------------------------------------------------------------------
norm_terms() {
  awk '{
    n = split($0, P, "/")
    for (i=1;i<=n;i++) {
      t = P[i]; gsub(/^[ \t]+|[ \t]+$/, "", t); t = tolower(t)
      if (t=="") continue
      if (t ~ /ies$/)                  sub(/ies$/, "y", t)
      else if (t ~ /(s|x|z|ch|sh)es$/) sub(/es$/, "", t)
      else if (t ~ /[a-z][^s]s$/)      sub(/s$/, "", t)
      print t
    }
  }'
}

# Normalized defined-identifier set (each heading/alias identifier slash-split + singularized).
DEFINED_NORM="${TMPDIR_CC}/defined_norm.txt"
norm_terms < "$DEFINED_FILE" 2>/dev/null | LC_ALL=C sort -u > "$DEFINED_NORM" || true

# Pre-compute the UNDEFINED subset of the universe in ONE awk pass (performance: the previous
# per-term approach spawned an awk + greps per universe term and re-globbed the doc list each
# time, which timed out on a large universe). A term is "defined" iff EVERY slash-split (#1) +
# singularized (#2) part is a defined identifier; only NOT-defined terms need a doc scan.
UNDEFINED_FILE="${TMPDIR_CC}/undefined.txt"
awk -v dnf="$DEFINED_NORM" '
  function sing(t) {
    if (t ~ /ies$/)                  sub(/ies$/, "y", t)
    else if (t ~ /(s|x|z|ch|sh)es$/) sub(/es$/, "", t)
    else if (t ~ /[a-z][^s]s$/)      sub(/s$/, "", t)
    return t
  }
  BEGIN { while ((getline d < dnf) > 0) { gsub(/^[ \t]+|[ \t]+$/,"",d); if (d!="") DEF[d]=1 } }
  {
    line=$0; n=split(line, P, "/"); alldef=1
    for (i=1; i<=n; i++) {
      t=P[i]; gsub(/^[ \t]+|[ \t]+$/,"",t); t=sing(tolower(t))
      if (t=="") continue
      if (!(t in DEF)) { alldef=0; break }
    }
    if (!alldef) print line
  }
' "$UNIVERSE_FILE" > "$UNDEFINED_FILE" 2>/dev/null || true

# Glob the KB doc list ONCE (was re-run per term).
DOC_LIST="${TMPDIR_CC}/doc_list.txt"
find "$KB_DIR" -maxdepth 1 -type f -name '*.md' ! -name '.*' 2>/dev/null | sort > "$DOC_LIST" || true

# ---------------------------------------------------------------------------
# sources: helpers (used by the batched presence scan below AND by output (b))
# ---------------------------------------------------------------------------
# Extract sources: list items from a doc's frontmatter (one awk per doc).
extract_sources() {
  local doc="$1"
  awk '
    BEGIN { in_fm=0; in_sources=0 }
    /^---$/ {
      if (!in_fm) { in_fm=1; next }
      else { exit }
    }
    in_fm && /^sources:/ {
      rest = $0
      sub(/^sources:[[:space:]]*/, "", rest)
      if (rest ~ /^\[\]/) { exit }
      if (rest ~ /^\[/) {
        # inline list: [a, b, c]
        inner = rest
        sub(/^\[/, "", inner); sub(/\][[:space:]]*$/, "", inner)
        n = split(inner, items, /[[:space:]]*,[[:space:]]*/)
        for (i=1; i<=n; i++) {
          it = items[i]
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", it)
          gsub(/^['"'"'"]|['"'"'"]$/, "", it)
          if (it != "") print it
        }
        exit
      } else if (rest ~ /^[[:space:]]*$/) {
        in_sources = 1
        next
      } else {
        exit
      }
    }
    in_fm && in_sources {
      if (/^[[:space:]]+-[[:space:]]/ || /^[[:space:]]+-$/) {
        item = $0
        sub(/^[[:space:]]+-[[:space:]]*/, "", item)
        sub(/[[:space:]]+$/, "", item)
        # Strip inline comments (# ...)
        sub(/[[:space:]]+#.*$/, "", item)
        if (item != "") print item
        next
      }
      # Next top-level key or blank line -> end of sources block
      if (/^[a-zA-Z]/ || /^[[:space:]]*$/) exit
    }
  ' "$doc"
}

# Is an entry a URL?  (bash builtin -- no subshell fork)
is_url() {
  [[ "$1" =~ ^https?:// ]]
}

# Resolve a sources: entry to an absolute path under ROOT. Result is returned in the
# global RESOLVE_OUT (set instead of echoed, so callers avoid a per-call command-
# substitution fork -- the O(term x source) hot path in output (b)).
resolve_source() {
  local entry="$1"
  local candidate="${ROOT}/${entry}"
  if [[ -f "$candidate" && -r "$candidate" ]]; then RESOLVE_OUT="$candidate"; return; fi
  if [[ -f "$entry" && -r "$entry" ]]; then RESOLVE_OUT="$entry"; return; fi
  RESOLVE_OUT=""
}

# ---------------------------------------------------------------------------
# Batched term-presence scan (PERFORMANCE FIX).
#
# Replaces the per-(term x doc)[/x source] `grep -qiF` spawns in outputs (a) and (b)
# -- which on a ~500-term universe x ~15 docs x sources reached tens of thousands of
# fork()/exec calls and timed out (>3 min) on Windows Git Bash / MSYS -- with a SINGLE
# awk pass that builds a term->file presence map (plus per-doc first-match anchors).
#
# Reproduces `grep -qiF` EXACTLY: case-insensitive (tolower both sides), fixed-string
# literal substring (awk index()), per line, C locale, per-term-independent (each term
# checked on its own, so a term that is a substring of another -- "bus" in "relative
# bus" -- is never masked). One awk process = zero per-item spawns, and identical
# output on every OS since it is the same interpreter everywhere.
#
# (ripgrep was evaluated and rejected HERE: rg.exe on Windows/MSYS rewrites the input
# path `/c/x` -> `C:/x` in its output, which would key presence under a different
# string than the find/resolve paths the output loops look up -- silently breaking the
# cross-OS byte-identity this oracle guarantees. awk keys by FILENAME = the exact path,
# so there is no path-form mismatch. rg's only role here would have been line pre-
# filtering, not worth an OS-divergence bug; the file set is small (KB docs + sources).)
# ---------------------------------------------------------------------------
PRESENT_TSV="${TMPDIR_CC}/present.tsv"     # <term>\x01<file>
ANCHOR_TSV="${TMPDIR_CC}/anchor.tsv"       # <term>\x01<doc>\x01<anchor>
: > "$PRESENT_TSV"; : > "$ANCHOR_TSV"

# Terms actually looked up: output (b) uses TERMS_FILE, output (a) uses the UNDEFINED
# subset (both subsets of the universe). Union, lowercased, non-empty.
SCAN_TERMS="${TMPDIR_CC}/scan_terms.txt"
cat "$TERMS_FILE" "$UNDEFINED_FILE" 2>/dev/null | LC_ALL=C sort -u | grep -v '^[[:space:]]*$' > "$SCAN_TERMS" || true

# In ONE pass over the docs: (1) build the scan file set = KB docs UNION every
# resolved (local, readable) sources: file, and (2) record per-doc source info for
# output (b) -- so extract_sources/resolve run once per (doc,source), not per term.
# SRCINFO rows (DOC_LIST order, source order): <doc>\x01<type>\x01<resolved>\x01<src_rel>
# where type is url | unresolved | file.
SCANSET="${TMPDIR_CC}/scanset.txt"
SRCINFO="${TMPDIR_CC}/srcinfo.tsv"
cp "$DOC_LIST" "$SCANSET" 2>/dev/null || : > "$SCANSET"
: > "$SRCINFO"
if [[ -d "$KB_DIR" && -s "$DOC_LIST" ]]; then
  while IFS= read -r _doc; do
    [[ -f "$_doc" ]] || continue
    while IFS= read -r _src; do
      [[ -z "$_src" ]] && continue
      if is_url "$_src"; then
        printf '%s\001url\001\001\n' "$_doc" >> "$SRCINFO"
        continue
      fi
      resolve_source "$_src"
      if [[ -z "$RESOLVE_OUT" ]]; then
        printf '%s\001unresolved\001\001\n' "$_doc" >> "$SRCINFO"
        continue
      fi
      printf '%s\001file\001%s\001%s\n' "$_doc" "$RESOLVE_OUT" "${RESOLVE_OUT#${ROOT}/}" >> "$SRCINFO"
      printf '%s\n' "$RESOLVE_OUT" >> "$SCANSET"
    done < <(extract_sources "$_doc")
  done < "$DOC_LIST"
fi
LC_ALL=C sort -u "$SCANSET" -o "$SCANSET"

# Attribution awk: reads the scan files DIRECTLY. curfile = FILENAME (the exact path
# string passed in, = the find/resolve strings the output loops key by -> no path-form
# mismatch). For each line: lowercase it and, for each not-yet-seen-in-this-file term,
# index() -> presence (+ first-line anchor for KB docs). SEP = \x01 (never in terms/
# paths/anchors, so serialization survives terms-with-spaces and anchor-with-tabs).
ATTR_AWK="${TMPDIR_CC}/attribute.awk"
cat > "$ATTR_AWK" <<'ATTR'
BEGIN {
  SEP = sprintf("%c", 1)
  while ((getline t < termsf) > 0) { if (t != "") TERMS[++NT] = t }
  while ((getline d < docsf) > 0) { if (d != "") ISDOC[d] = 1 }
}
FNR == 1 { curfile = FILENAME; isdoc = (curfile in ISDOC) }
{
  lc = tolower($0)
  for (i = 1; i <= NT; i++) {
    t = TERMS[i]
    key = t SEP curfile
    if (key in SEEN) continue              # presence already recorded for this file
    if (index(lc, t) > 0) {
      SEEN[key] = 1
      print t SEP curfile > presfile
      if (isdoc) {
        a = $0                             # first matching line = anchor (original case)
        sub(/^[[:space:]]+/, "", a)        # strip leading whitespace
        a = substr(a, 1, 80)               # first 80 bytes (LC_ALL=C)
        gsub(/\|/, "/", a)                 # pipes -> slashes (table safety)
        print t SEP curfile SEP a > ancfile
      }
    }
  }
}
ATTR

if [[ -s "$SCAN_TERMS" && -s "$SCANSET" ]]; then
  mapfile -t _SCAN_ARR < "$SCANSET"
  # Single awk pass over the scan file set -- was tens of thousands of per-(term x doc
  # x source) `grep -qiF` spawns. LC_ALL=C makes tolower()/substr() byte-wise, matching
  # `grep -qiF` / `cut -c` in the C locale.
  LC_ALL=C awk -v termsf="$SCAN_TERMS" -v docsf="$DOC_LIST" -v presfile="$PRESENT_TSV" -v ancfile="$ANCHOR_TSV" -f "$ATTR_AWK" "${_SCAN_ARR[@]}" 2>/dev/null || true
fi

# Outputs (a) and (b) are generated by awk (below), reading the presence map / anchors
# / per-doc source info directly from the temp files. Doing the derivation in awk (not
# a bash triple-loop) is what keeps it O(seconds): output (b) is docs x all-terms x
# sources rows, which a bash loop -- even fork-free -- is far too slow to emit on MSYS.

# ---------------------------------------------------------------------------
# Output (a) computation:
#   Only NOT-defined terms (pre-computed above) reach the doc scan. A term USED in a KB doc
#   body that is not defined is an ungrounded term. Output one row per (term, doc) pair.
#   Doc scanning: literal, case-insensitive (grep -i -F) on the original term.
# ---------------------------------------------------------------------------
OUTPUT_A_TMP="${TMPDIR_CC}/output_a.md"

{
  echo "## Output (a): Ungrounded / Un-closed Concept Set"
  echo ""
  echo "| term | used-in-doc | anchor |"
  echo "|------|-------------|--------|"

  if [[ -d "$KB_DIR" ]] && [[ -s "$UNDEFINED_FILE" ]]; then
    # One awk pass (was a bash term x doc loop with a per-(term,doc) `grep -qiF` +
    # 4-process anchor pipeline). Emits one row per (undefined term, doc) where the
    # term is present, in UNDEFINED_FILE order x DOC_LIST order -- identical to before.
    LC_ALL=C awk -v presf="$PRESENT_TSV" -v ancf="$ANCHOR_TSV" -v doclistf="$DOC_LIST" '
      BEGIN {
        SEP = sprintf("%c", 1)
        while ((getline p < presf) > 0) { if (p != "") PRES[p] = 1 }
        while ((getline a < ancf) > 0) {
          if (a == "") continue
          n = split(a, F, SEP)                 # F[1]=term F[2]=doc F[3]=anchor
          if (n >= 3) ANC[F[1] SEP F[2]] = F[3]
        }
        nd = 0
        while ((getline d < doclistf) > 0) { if (d != "") DOCS[++nd] = d }
      }
      {
        term = $0
        if (term == "") next
        for (k = 1; k <= nd; k++) {
          doc = DOCS[k]; key = term SEP doc
          if (key in PRES) {
            b = doc; sub(/.*\//, "", b)
            print "| " term " | " b " | " ANC[key] " |"
          }
        }
      }
    ' "$UNDEFINED_FILE"
  fi
} > "$OUTPUT_A_TMP"

# ---------------------------------------------------------------------------
# Output (b) computation:
#   For each KB doc, parse its sources: frontmatter.
#   For each sources: entry that is a local readable file, scan for each term.
#   URL entries -> anchoring-source = N/A, skip (no absent finding).
# ---------------------------------------------------------------------------
OUTPUT_B_TMP="${TMPDIR_CC}/output_b.md"

# (extract_sources / is_url / resolve_source are defined above, before the batched
# presence scan that also uses them.)

{
  echo "## Output (b): Per-doc sources:-anchored Coverage"
  echo ""
  echo "| term | doc | anchoring-source | present|absent |"
  echo "|------|-----|------------------|--------|"

  if [[ -d "$KB_DIR" ]] && [[ -s "$TERMS_FILE" ]]; then
    # One awk pass (was a bash doc x term x source triple loop with 2 `grep -qiF` +
    # is_url + resolve_source per innermost iteration). Emits one row per (doc, term,
    # source) in DOC_LIST order x TERMS_FILE order x source order -- identical to before.
    # Per-doc source info (type/resolved/src_rel) comes from SRCINFO (computed once
    # above); present/absent comes from the presence map (term in doc OR resolved src).
    LC_ALL=C awk -v presf="$PRESENT_TSV" -v termsf="$TERMS_FILE" -v doclistf="$DOC_LIST" -v srcinfof="$SRCINFO" '
      BEGIN {
        SEP = sprintf("%c", 1)
        while ((getline p < presf) > 0) { if (p != "") PRES[p] = 1 }
        nt = 0
        while ((getline t < termsf) > 0) { if (t != "") TERMS[++nt] = t }
        nd = 0
        while ((getline d < doclistf) > 0) { if (d != "") DOCS[++nd] = d }
        # Per-doc ordered sources (grouped by doc, in file order).
        while ((getline line < srcinfof) > 0) {
          if (line == "") continue
          split(line, G, SEP)                    # G[1]=doc G[2]=type G[3]=resolved G[4]=src_rel
          d = G[1]; c = ++NSRC[d]
          STYPE[d, c] = G[2]; SRES[d, c] = G[3]; SREL[d, c] = G[4]
        }
        for (k = 1; k <= nd; k++) {
          doc = DOCS[k]
          if (!(doc in NSRC)) continue           # doc had no sources -> skip (was: empty SOURCES_LIST)
          b = doc; sub(/.*\//, "", b)
          for (mi = 1; mi <= nt; mi++) {
            term = TERMS[mi]
            for (s = 1; s <= NSRC[doc]; s++) {
              ty = STYPE[doc, s]
              if (ty == "url" || ty == "unresolved") { print "| " term " | " b " | N/A | N/A |"; continue }
              resolved = SRES[doc, s]
              if ((term SEP doc) in PRES || (term SEP resolved) in PRES)
                print "| " term " | " b " | " SREL[doc, s] " | present |"
              else
                print "| " term " | " b " | " SREL[doc, s] " | absent |"
            }
          }
        }
      }
    ' </dev/null
  fi
} > "$OUTPUT_B_TMP"

# ---------------------------------------------------------------------------
# Write outputs
# ---------------------------------------------------------------------------
write_output() {
  local content_file="$1"
  local out_path="$2"
  if [[ -n "$out_path" ]]; then
    cp "$content_file" "$out_path"
  fi
}

if [[ -n "$OUTPUT_ALL" ]]; then
  # Write both sections to a single file
  {
    echo "# Closure Check Results"
    echo ""
    cat "$OUTPUT_A_TMP"
    echo ""
    cat "$OUTPUT_B_TMP"
  } > "$OUTPUT_ALL"
  echo "[closure-check] Wrote all outputs to $OUTPUT_ALL" >&2
else
  # Write to stdout (default) or individual files
  if [[ -z "$OUTPUT_A" && -z "$OUTPUT_B" ]]; then
    # Both to stdout
    echo "# Closure Check Results"
    echo ""
    cat "$OUTPUT_A_TMP"
    echo ""
    cat "$OUTPUT_B_TMP"
  else
    # Individual files or stdout per-section
    if [[ -n "$OUTPUT_A" ]]; then
      write_output "$OUTPUT_A_TMP" "$OUTPUT_A"
      echo "[closure-check] Wrote output (a) to $OUTPUT_A" >&2
    else
      cat "$OUTPUT_A_TMP"
    fi
    if [[ -n "$OUTPUT_B" ]]; then
      write_output "$OUTPUT_B_TMP" "$OUTPUT_B"
      echo "[closure-check] Wrote output (b) to $OUTPUT_B" >&2
    else
      cat "$OUTPUT_B_TMP"
    fi
  fi
fi

echo "[closure-check] Done." >&2
