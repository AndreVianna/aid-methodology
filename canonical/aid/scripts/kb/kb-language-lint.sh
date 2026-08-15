#!/usr/bin/env bash
# kb-language-lint.sh -- plain-language readability and glossary-coverage checks for KB docs.
#
# Purpose:
#   Two-check enforcement script for the plain-language authoring standard:
#
#   Glossary path (--check glossary):
#     Builds a merged coined-term candidate universe from two harvest runs --
#     one over the project root and one over the KB directory -- then calls
#     closure-check.sh to identify terms used in KB docs that have no
#     domain-glossary.md definition and no dismissal row. Emits one
#     [GLOSSARY-GAP] finding line per undefined term per doc.
#
#     Intermediate files written to <root>/.aid/.temp/kb-language/:
#       candidates.md    -- merged Ranked Candidates table (input to closure-check)
#       defined-extra.txt -- terms from Lexicon/Abbreviations/Domain-Meanings tables
#                           (input to closure-check --defined-extra)
#
#   Frontmatter path (--check frontmatter):
#     Checks the in-scope KB docs' frontmatter readability bounds:
#       objective:  at most 25 whitespace-delimited words (one physical line)
#       summary:    at most 2 sentences (split on . ? ! followed by whitespace or
#                   end-of-line), each sentence at most 30 words, with at most 1
#                   em-dash total in the summary value.
#     Emits one [LANG-FRONTMATTER] finding line per violation.
#
#   In-scope predicate for the frontmatter path (mirrors lint-frontmatter.sh):
#     kb-category: in {primary, extension} AND source: not "generated"
#     meta docs and generated docs are always skipped.
#
# Usage:
#   kb-language-lint.sh [--root <repo>] [--kb-dir <path>]
#                       [--check glossary|frontmatter|all]
#                       [--verbose] [-h|--help]
#
#   --root <repo>       repo root to scan (default: .)
#   --kb-dir <path>     KB directory (default: <root>/.aid/knowledge)
#   --check <mode>      which checks to run: glossary, frontmatter, or all (default: all)
#   --verbose           print progress messages to stderr
#   -h, --help          print this help and exit 0
#
# Exit codes:
#   0  no findings
#   1  one or more findings reported
#   2  usage / argument error
#
# Tools used: bash, coreutils, awk, git (optional via harvest), ripgrep (optional).
# No additional toolchain dependency is introduced: AID_HARVEST_NO_RG=1 produces
# identical findings by routing harvest-coined-terms.sh to its grep fallback.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARVEST_SH="${SCRIPT_DIR}/harvest-coined-terms.sh"
CLOSURE_SH="${SCRIPT_DIR}/closure-check.sh"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
ROOT="."
KB_DIR_ARG=""
CHECK_MODE="all"
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)    ROOT="$2";       shift 2 ;;
    --kb-dir)  KB_DIR_ARG="$2"; shift 2 ;;
    --check)
      case "${2:-}" in
        glossary|frontmatter|all) CHECK_MODE="$2"; shift 2 ;;
        *)
          echo "kb-language-lint.sh: --check must be glossary, frontmatter, or all" >&2
          exit 2
          ;;
      esac
      ;;
    --verbose) VERBOSE=1; shift ;;
    -h|--help)
      sed -n '2,48p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "kb-language-lint.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
resolve_abs() {
  local p="$1"
  case "$p" in
    /*|[A-Za-z]:[/\\]*) echo "$p" ;;
    *) echo "$PWD/$p" ;;
  esac
}

ROOT_ABS=$(resolve_abs "$ROOT")
if [[ ! -d "$ROOT_ABS" ]]; then
  echo "kb-language-lint.sh: root not found: $ROOT_ABS" >&2
  exit 2
fi

if [[ -n "$KB_DIR_ARG" ]]; then
  KB_DIR=$(resolve_abs "$KB_DIR_ARG")
else
  KB_DIR="${ROOT_ABS}/.aid/knowledge"
fi

if [[ ! -d "$KB_DIR" ]]; then
  echo "kb-language-lint.sh: kb-dir not found: $KB_DIR" >&2
  exit 2
fi

GLOSSARY="${KB_DIR}/domain-glossary.md"
DISMISSED="${KB_DIR}/.glossary-dismissed.txt"

# ---------------------------------------------------------------------------
# Verify sibling scripts exist
# ---------------------------------------------------------------------------
if [[ ! -f "$HARVEST_SH" ]]; then
  echo "kb-language-lint.sh: harvest-coined-terms.sh not found at $HARVEST_SH" >&2
  exit 1
fi
if [[ ! -f "$CLOSURE_SH" ]]; then
  echo "kb-language-lint.sh: closure-check.sh not found at $CLOSURE_SH" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Output and temp directories
# ---------------------------------------------------------------------------
OUTDIR="${ROOT_ABS}/.aid/.temp/kb-language"
mkdir -p "$OUTDIR"

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

# Accumulated finding count (modified by check functions)
FINDINGS=0

# ---------------------------------------------------------------------------
# Verbose helper
# ---------------------------------------------------------------------------
log() {
  [[ "$VERBOSE" -eq 1 ]] && printf '[kb-language-lint] %s\n' "$*" >&2 || true
}

# ===========================================================================
# Glossary path (Flow A)
# ===========================================================================
run_glossary_check() {
  log "Glossary check: running harvest over repo root..."

  # Harvest 1: project sources (repo root; .aid is pruned by harvest's SKIP_DIRS).
  # Use the default --top (60) which is supplemented by all spread>=3 terms, giving
  # the most salient coined terms from code, config, and git history without the
  # tens-of-thousands-of-low-rank-identifiers that --top 999999 would produce.
  local harvest_root="${TMPD}/harvest-root.md"
  bash "$HARVEST_SH" \
    --root "$ROOT_ABS" \
    --output "$harvest_root" \
    2>/dev/null || true

  log "Glossary check: running harvest over KB directory..."

  # Harvest 2: KB docs (kb-dir as root; .aid not a subdir under kb-dir, so not pruned).
  # Use --top 999999 to capture ALL terms coined in KB prose -- the KB has only ~20 docs
  # so this is fast and ensures no KB-coined term is missed regardless of its frequency.
  local harvest_kb="${TMPD}/harvest-kb.md"
  bash "$HARVEST_SH" \
    --root "$KB_DIR" \
    --top 999999 \
    --output "$harvest_kb" \
    2>/dev/null || true

  log "Glossary check: merging candidate tables..."

  # Merge: deduplicate Ranked Candidates tables by term (repo-root first, kb second)
  local candidates_file="${OUTDIR}/candidates.md"
  {
    printf '# Candidate Concepts\n\n'
    printf '## Ranked Candidates\n'
    printf '| # | Source | Term | Class | Freq | Spread | Channels | Salience | Example source |\n'
    printf '|---|--------|------|-------|------|--------|----------|----------|----------------|\n'
    awk '
      /^## Ranked Candidates/ { in_cands = 1; next }
      /^## /                  { in_cands = 0; next }
      in_cands && /^\|[[:space:]]*[0-9]/ {
        n = split($0, f, "|")
        if (n >= 4) {
          term = f[4]
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", term)
          gsub(/`/, "", term)
          if (term == "" || term == "Term") next
          if (!(term in seen)) {
            seen[term] = 1
            rows[++nrows] = $0
          }
        }
      }
      END {
        for (i = 1; i <= nrows; i++) {
          row = rows[i]
          sub(/^\|[[:space:]]*[0-9]+[[:space:]]*\|/, "| " i " |", row)
          print row
        }
      }
    ' "$harvest_root" "$harvest_kb" 2>/dev/null || true
  } > "$candidates_file"

  log "Glossary check: extracting table-defined terms from domain-glossary.md..."

  # Extract defined-extra: first-column terms from Lexicon/Abbreviations/Domain-Meanings tables
  # These table sections define terms that closure-check.sh's spine parse would miss
  # (it only parses ### headings and **Aliases:** under ## Concept Spine).
  local defined_extra="${OUTDIR}/defined-extra.txt"
  if [[ -f "$GLOSSARY" ]]; then
    awk '
      /^## Lexicon/            { in_section = 1; next }
      /^## Abbreviations/      { in_section = 1; next }
      /^## Terms with Specific/ { in_section = 1; next }
      /^## /                   { in_section = 0; next }
      in_section && /^\|/ {
        n = split($0, f, "|")
        if (n >= 2) {
          term = f[2]
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", term)
          if (term ~ /^[-]+$/) next          # separator row
          if (term == "Term" || term == "Abbreviation" || term == "Abbrev") next
          if (term != "") print term
        }
      }
    ' "$GLOSSARY" 2>/dev/null > "$defined_extra" || true
  else
    : > "$defined_extra"
  fi

  log "Glossary check: running closure-check..."

  # Build dismissed args array (flag absent when dismissal file does not exist)
  local dismissed_args=()
  [[ -f "$DISMISSED" ]] && dismissed_args=(--dismissed "$DISMISSED")

  local output_a="${TMPD}/closure-output-a.md"
  local output_b_discard="${TMPD}/closure-output-b.md"

  bash "$CLOSURE_SH" \
    --root "$ROOT_ABS" \
    --concepts "$candidates_file" \
    --spine "$GLOSSARY" \
    --kb-dir "$KB_DIR" \
    "${dismissed_args[@]}" \
    --defined-extra "$defined_extra" \
    --output-a "$output_a" \
    --output-b "$output_b_discard" \
    2>/dev/null || true

  log "Glossary check: converting output-a to [GLOSSARY-GAP] findings..."

  # Convert each output-(a) data row into a [GLOSSARY-GAP] finding line.
  # Map the normalized lowercase term back to original case using the candidates
  # table so the emitted finding matches the SPEC example form (e.g. "Thin Doorway"
  # not "thin doorway").  Falls back to the lowercase form when the candidates table
  # has no matching entry (e.g. a singularized derivative not directly in the table).
  if [[ -f "$output_a" ]]; then
    local gap_findings
    gap_findings=$(awk -F'|' -v candf="$candidates_file" '
      BEGIN {
        while ((getline line < candf) > 0) {
          n = split(line, f, "|")
          if (n >= 4 && line ~ /^\|[[:space:]]*[0-9]/) {
            t = f[4]
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
            gsub(/`/, "", t)
            if (t != "" && t != "Term") {
              tl = tolower(t)
              if (!(tl in case_map)) case_map[tl] = t
            }
          }
        }
      }
      /^\|/ {
        term = $2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", term)
        doc  = $3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", doc)
        if (term == "" || term == "term")    next
        if (term ~ /^[-]+$/)                next
        if (doc  == "" || doc == "used-in-doc") next
        display_term = (term in case_map) ? case_map[term] : term
        printf "  [GLOSSARY-GAP] %s: coined term \"%s\" has no domain-glossary.md definition\n", doc, display_term
      }
    ' "$output_a" 2>/dev/null) || true

    if [[ -n "$gap_findings" ]]; then
      printf '%s\n' "$gap_findings"
      local gap_count
      gap_count=$(printf '%s\n' "$gap_findings" \
        | awk '/\[GLOSSARY-GAP\]/{n++} END{print n+0}')
      FINDINGS=$((FINDINGS + gap_count))
    fi
  fi
}

# ===========================================================================
# Frontmatter path (Flow B)
# ===========================================================================
run_frontmatter_check() {
  log "Frontmatter check: scanning KB docs..."

  mapfile -t docs < <(find "$KB_DIR" -maxdepth 1 -type f -name '*.md' ! -name '.*' 2>/dev/null | sort)
  [[ ${#docs[@]} -eq 0 ]] && return 0

  # Em-dash: UTF-8 encoding E2 80 94 -- passed as a shell variable so the script
  # file itself stays ASCII-only (only the hex escape sequences are in the source).
  local emdash
  emdash=$(printf '\xe2\x80\x94')

  # Single awk pass over all in-scope docs.
  # Doc selection mirrors lint-frontmatter.sh: kb-category in {primary, extension},
  # source != generated; meta docs always skipped.
  local fm_findings
  fm_findings=$(LC_ALL=C awk \
    -v emdash="$emdash" \
    -v max_obj_words=25 \
    -v max_sum_sents=2 \
    -v max_sent_words=30 \
    -v max_emdash=1 \
    '
    # -------------------------------------------------------------------
    # count_words: count whitespace-delimited words in s
    function count_words(s,   a) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
      if (s == "") return 0
      return split(s, a, /[[:space:]]+/)
    }

    # split_sentences: split s on [.?!] followed by whitespace or end-of-line
    # into sents[1..n], return sentence count.
    function split_sentences(s, sents,   i, c, nc, slen, start, ns) {
      delete sents
      slen = length(s); ns = 0; start = 1
      for (i = 1; i <= slen; i++) {
        c = substr(s, i, 1)
        if (c == "." || c == "?" || c == "!") {
          nc = (i < slen) ? substr(s, i+1, 1) : " "
          if (nc ~ /[[:space:]]/ || i == slen) {
            ns++
            sents[ns] = substr(s, start, i - start + 1)
            # advance start past trailing whitespace
            i++
            while (i <= slen && substr(s, i, 1) ~ /[[:space:]]/) i++
            start = i
            i--  # for-loop will increment i again
          }
        }
      }
      # text after the last terminator (no sentence-ending punctuation)
      if (start <= slen) { ns++; sents[ns] = substr(s, start) }
      return ns
    }

    # count_occurrences: fixed-string count of needle in haystack
    function count_occurrences(haystack, needle,   n, pos, nlen, p) {
      n = 0; nlen = length(needle)
      if (nlen == 0) return 0
      pos = 1
      while (1) {
        p = index(substr(haystack, pos), needle)
        if (p == 0) break
        n++; pos += p + nlen - 1
      }
      return n
    }

    # check_doc: apply readability rules and print findings
    function check_doc(   sents, nsents, i, wc, ned) {
      # Scope filter (mirrors lint-frontmatter.sh predicate)
      if (fm_cat == "meta") return
      if (fm_cat != "" && fm_cat != "primary" && fm_cat != "extension") return
      if (fm_src == "generated") return

      # objective: at most max_obj_words whitespace-delimited words
      if (fm_obj_block) {
        printf "  [LANG-FRONTMATTER] %s: '\''objective:'\'' uses a block scalar (must be one physical line)\n", \
          fname
      } else if (fm_obj != "") {
        wc = count_words(fm_obj)
        if (wc > max_obj_words)
          printf "  [LANG-FRONTMATTER] %s: '\''objective:'\'' is %d words (max %d)\n", \
            fname, wc, max_obj_words
      }

      # summary: sentence count, per-sentence word count, em-dash count
      if (fm_sum_block) {
        printf "  [LANG-FRONTMATTER] %s: '\''summary:'\'' uses a block scalar (must be inline scalar)\n", \
          fname
      } else if (fm_sum != "") {
        nsents = split_sentences(fm_sum, sents)
        if (nsents > max_sum_sents)
          printf "  [LANG-FRONTMATTER] %s: '\''summary:'\'' has %d sentences (max %d)\n", \
            fname, nsents, max_sum_sents
        for (i = 1; i <= nsents; i++) {
          wc = count_words(sents[i])
          if (wc > max_sent_words)
            printf "  [LANG-FRONTMATTER] %s: '\''summary:'\'' sentence %d is %d words (max %d)\n", \
              fname, i, wc, max_sent_words
        }
        if (emdash != "") {
          ned = count_occurrences(fm_sum, emdash)
          if (ned > max_emdash)
            printf "  [LANG-FRONTMATTER] %s: '\''summary:'\'' has %d em-dashes (max %d)\n", \
              fname, ned, max_emdash
        }
      }
    }
    # -------------------------------------------------------------------

    FNR == 1 {
      in_fm = 0
      fname = FILENAME; sub(/.*\//, "", fname)
      fm_cat = ""; fm_src = ""; fm_obj = ""; fm_sum = ""
      fm_obj_block = 0; fm_sum_block = 0
    }
    /^---$/ {
      if (!in_fm && FNR == 1) { in_fm = 1; next }
      if (in_fm)               { in_fm = 0; check_doc(); next }
      next
    }
    in_fm && /^kb-category:/ {
      fm_cat = $0
      sub(/^kb-category:[[:space:]]*/, "", fm_cat)
      sub(/[[:space:]]+$/, "", fm_cat)
    }
    in_fm && /^source:/ {
      fm_src = $0
      sub(/^source:[[:space:]]*/, "", fm_src)
      sub(/[[:space:]]+$/, "", fm_src)
      # Strip block-scalar marker and surrounding quotes (keep only inline scalar)
      if (fm_src ~ /^[|>]/) fm_src = ""
      gsub(/^['"'"'"]|['"'"'"]$/, "", fm_src)
    }
    in_fm && /^objective:/ {
      fm_obj = $0
      sub(/^objective:[[:space:]]*/, "", fm_obj)
      sub(/[[:space:]]+$/, "", fm_obj)
      if (fm_obj ~ /^[|>]/) { fm_obj_block = 1; fm_obj = "" }
    }
    in_fm && /^summary:/ {
      fm_sum = $0
      sub(/^summary:[[:space:]]*/, "", fm_sum)
      sub(/[[:space:]]+$/, "", fm_sum)
      if (fm_sum ~ /^[|>]/) { fm_sum_block = 1; fm_sum = "" }
    }
    ' "${docs[@]}" 2>/dev/null) || true

  if [[ -n "$fm_findings" ]]; then
    printf '%s\n' "$fm_findings"
    local fm_count
    fm_count=$(printf '%s\n' "$fm_findings" \
      | awk '/\[LANG-FRONTMATTER\]/{n++} END{print n+0}')
    FINDINGS=$((FINDINGS + fm_count))
  fi
}

# ===========================================================================
# Main
# ===========================================================================
log "kb-language-lint running (check=$CHECK_MODE, root=$ROOT_ABS, kb-dir=$KB_DIR)"

if [[ "$CHECK_MODE" == "glossary" || "$CHECK_MODE" == "all" ]]; then
  run_glossary_check
fi

if [[ "$CHECK_MODE" == "frontmatter" || "$CHECK_MODE" == "all" ]]; then
  run_frontmatter_check
fi

if [[ "$FINDINGS" -gt 0 ]]; then
  exit 1
fi
exit 0
