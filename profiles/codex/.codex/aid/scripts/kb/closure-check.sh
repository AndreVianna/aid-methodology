#!/usr/bin/env bash
# closure-check.sh -- deterministic single coverage oracle for AID essence capture.
#
# Consumes:
#   .aid/generated/candidate-concepts.md  -- term universe (harvest + synthesis rows)
#   domain-glossary.md                    -- concept spine (defined terms + relates-to)
#   KB docs + their resolved sources: frontmatter (f001 field)
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
  elif [[ -f "${ROOT}/.codex/aid/scripts/kb/coined-term-denylist.txt" ]]; then
    DENYLIST="${ROOT}/.codex/aid/scripts/kb/coined-term-denylist.txt"
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

# Subtract EXCLUDED terms from the universe (feature-014 Q10 fix), where EXCLUDED =
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
# Term normalization (feature-014 rules #1 and #2):
#   #1 slash-split  -- a compound joined by "/" is treated as its separate words; each part
#                      is its own term (e.g. "canonical / profile" -> "canonical", "profile").
#   #2 singular     -- terms are compared in singular form (e.g. "tasks" -> "task"). Applied
#                      symmetrically to BOTH the defined identifiers and the used terms, so the
#                      match is robust even if the singular rule is linguistically imperfect.
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

# Normalized defined-identifier set (each heading identifier slash-split + singularized).
DEFINED_NORM="${TMPDIR_CC}/defined_norm.txt"
norm_terms < "$DEFINED_FILE" 2>/dev/null | LC_ALL=C sort -u > "$DEFINED_NORM" || true

# ---------------------------------------------------------------------------
# Output (a) computation:
#   For each term in UNIVERSE_FILE, scan KB docs for occurrences.
#   A term is "defined" iff EVERY slash-split, singularized part is a defined identifier
#   (rules #1/#2). A term USED in a KB doc body that is not defined is an ungrounded term.
#   Output one row per (term, doc) pair where it is used.
#
#   Doc scanning: literal, case-insensitive (grep -i -F) on the original term.
# ---------------------------------------------------------------------------
OUTPUT_A_TMP="${TMPDIR_CC}/output_a.md"

{
  echo "## Output (a): Ungrounded / Un-closed Concept Set"
  echo ""
  echo "| term | used-in-doc | anchor |"
  echo "|------|-------------|--------|"

  if [[ -d "$KB_DIR" ]] && [[ -s "$UNIVERSE_FILE" ]]; then
    while IFS= read -r term; do
      [[ -z "$term" ]] && continue

      # Skip if already defined. Defined terms are clean IDENTIFIERS (heading text with any
      # "(explanation)" stripped). A used term resolves to the spine iff EVERY slash-split,
      # singularized part of it (rules #1/#2) is a defined identifier. So "canonical / profile"
      # resolves when both "canonical" and "profile" are defined, and "tasks" resolves to "task".
      term_defined=1
      while IFS= read -r _part; do
        [[ -z "$_part" ]] && continue
        grep -qixF -- "$_part" "$DEFINED_NORM" 2>/dev/null || { term_defined=0; break; }
      done < <(printf '%s\n' "$term" | norm_terms)
      [[ "$term_defined" == "1" ]] && continue

      # Scan KB docs for this term
      while IFS= read -r doc; do
        [[ -f "$doc" ]] || continue
        doc_base="$(basename "$doc")"

        # Check if term appears in doc (literal, case-insensitive; -F: no regex)
        if LC_ALL=C grep -qiF -- "$term" "$doc" 2>/dev/null; then
          # Find a representative anchor line (first match, limited context).
          # `head -1` closes the pipe after one line; under `set -euo pipefail` the upstream
          # `grep` then catches SIGPIPE (exit 141) on multi-match docs and would abort the
          # script. The anchor line is already captured, so swallow the SIGPIPE with `|| true`.
          anchor=$(LC_ALL=C grep -iF -- "$term" "$doc" 2>/dev/null \
            | head -1 \
            | sed 's/^[[:space:]]*//' \
            | cut -c1-80 || true)
          # Escape pipes in anchor
          anchor=$(echo "$anchor" | tr '|' '/')
          printf '| %s | %s | %s |\n' "$term" "$doc_base" "$anchor"
        fi
      done < <(find "$KB_DIR" -maxdepth 1 -type f -name '*.md' ! -name '.*' | sort)

    done < "$UNIVERSE_FILE"
  fi
} > "$OUTPUT_A_TMP"

# ---------------------------------------------------------------------------
# Output (b) computation:
#   For each KB doc, parse its sources: frontmatter.
#   For each sources: entry that is a local readable file, scan for each term.
#   URL entries -> anchoring-source = N/A, skip (no absent finding).
# ---------------------------------------------------------------------------
OUTPUT_B_TMP="${TMPDIR_CC}/output_b.md"

# Helper: extract sources: list items from a doc's frontmatter
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

# Helper: is an entry a URL?
is_url() {
  echo "$1" | grep -qE '^https?://'
}

# Helper: resolve a sources: entry to an absolute path under ROOT
resolve_source() {
  local entry="$1"
  # Try as-is under ROOT
  local candidate="${ROOT}/${entry}"
  if [[ -f "$candidate" && -r "$candidate" ]]; then
    echo "$candidate"
    return
  fi
  # Try entry as absolute path
  if [[ -f "$entry" && -r "$entry" ]]; then
    echo "$entry"
    return
  fi
  echo ""
}

{
  echo "## Output (b): Per-doc sources:-anchored Coverage"
  echo ""
  echo "| term | doc | anchoring-source | present|absent |"
  echo "|------|-----|------------------|--------|"

  if [[ -d "$KB_DIR" ]] && [[ -s "$TERMS_FILE" ]]; then
    while IFS= read -r doc; do
      [[ -f "$doc" ]] || continue
      doc_base="$(basename "$doc")"

      # Extract sources: list for this doc
      SOURCES_LIST="${TMPDIR_CC}/sources_${doc_base}.txt"
      extract_sources "$doc" > "$SOURCES_LIST" 2>/dev/null || true

      [[ -s "$SOURCES_LIST" ]] || continue

      # For each term, check against each source entry
      while IFS= read -r term; do
        [[ -z "$term" ]] && continue

        while IFS= read -r src_entry; do
          [[ -z "$src_entry" ]] && continue

          if is_url "$src_entry"; then
            # URL -> N/A, no finding
            printf '| %s | %s | N/A | N/A |\n' "$term" "$doc_base"
            continue
          fi

          resolved=$(resolve_source "$src_entry")
          if [[ -z "$resolved" ]]; then
            # Unresolvable -> N/A, no finding
            printf '| %s | %s | N/A | N/A |\n' "$term" "$doc_base"
            continue
          fi

          src_rel="${resolved#${ROOT}/}"

          # Check presence in doc body (literal, case-insensitive)
          in_doc=0
          if LC_ALL=C grep -qiF -- "$term" "$doc" 2>/dev/null; then
            in_doc=1
          fi

          # Check presence in resolved source file (literal, case-insensitive)
          in_src=0
          if LC_ALL=C grep -qiF -- "$term" "$resolved" 2>/dev/null; then
            in_src=1
          fi

          if [[ $in_doc -eq 1 || $in_src -eq 1 ]]; then
            printf '| %s | %s | %s | present |\n' "$term" "$doc_base" "$src_rel"
          else
            printf '| %s | %s | %s | absent |\n' "$term" "$doc_base" "$src_rel"
          fi

        done < "$SOURCES_LIST"
      done < "$TERMS_FILE"

    done < <(find "$KB_DIR" -maxdepth 1 -type f -name '*.md' ! -name '.*' | sort)
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
