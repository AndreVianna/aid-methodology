#!/usr/bin/env bash
# kb-html-claims-check.sh — gate the project claims kb.html makes against the Knowledge Base.
#
# kb.html is a generated tour of the KB, read by people who will never open
# `.aid/knowledge/`. When the KB moves on and the tour does not, the tour keeps
# telling newcomers something the project stopped doing — and nothing catches it,
# because the tour is generated and therefore assumed correct.
#
# Scope: PROJECT CLAIMS ONLY — the artifact names and paths the tour cites, the
# counts it quotes, and the grades it reports. Not layout, not styling, not wording.
#
# Why this is not spot-check-facts.sh. That script extracts numeric and version
# claims (`N noun`, `vX.Y.Z`) and always exits 0 by design — its own header says it
# "does NOT affect grading". Measured against today's kb.html it finds 17 claims,
# none of them a file path, and reports 6 MISS while still exiting 0. It cannot see
# a renamed artifact and cannot fail a build. Both are this script's whole purpose,
# so it is a gate beside that report rather than a flag added to it.
#
# Deliberately OUTSIDE the review-criteria registry: no registry type, no criterion
# id, and the G-07 in-scope-markdown wording is untouched. kb.html is generated HTML,
# not authored markdown, so it is not the criteria cascade's business.
#
# Usage:
#   kb-html-claims-check.sh <html-file> [--kb-dir DIR] [--quiet]
#
# Exit codes:
#   0  every extracted claim is consistent with the KB
#   1  at least one claim contradicts the KB, OR zero claims were extracted
#   2  invocation error / unreadable input
#
# Extracting zero claims is a FAILURE, not a pass: a check that silently matches
# nothing is indistinguishable from a clean bill of health, and that is the exact
# failure mode this script exists to prevent.

set -euo pipefail

HTML=""
KB_DIR=".aid/knowledge"
QUIET=0

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0"; exit 0 ;;
        --kb-dir)  KB_DIR="${2:-}"; shift 2 ;;
        --quiet)   QUIET=1; shift ;;
        -*)        echo "kb-html-claims-check.sh: unknown flag: $1" >&2; exit 2 ;;
        *)         HTML="$1"; shift ;;
    esac
done

[ -n "$HTML" ]    || { echo "kb-html-claims-check.sh: <html-file> is required" >&2; exit 2; }
[ -r "$HTML" ]    || { echo "kb-html-claims-check.sh: cannot read HTML: $HTML" >&2; exit 2; }
[ -d "$KB_DIR" ]  || { echo "kb-html-claims-check.sh: not a directory: $KB_DIR" >&2; exit 2; }

say() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }

# --- KB corpus, read once -----------------------------------------------------
# Sorted for determinism: two runs over an unchanged tree must produce identical
# output, so nothing here may depend on filesystem order or on locale collation.
KB_TEXT="$(LC_ALL=C find "$KB_DIR" -maxdepth 1 -type f -name '*.md' -print0 \
    | LC_ALL=C sort -z | xargs -0 cat 2>/dev/null || true)"

# --- HTML text, tags stripped -------------------------------------------------
# Entities are decoded before extraction so `STATE&#46;yml` is not read as a
# different artifact from `STATE.yml`.
HTML_TEXT="$(sed -e 's/<[^>]*>/ /g' "$HTML" \
    | sed -e 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g; s/&#46;/./g')"

FINDINGS=0
CLAIMS=0

report() {
    FINDINGS=$((FINDINGS + 1))
    say "[FAIL] $1"
    say "       $2"
}

# ==============================================================================
# Claim class 1: artifact names — a rename the tour did not follow
#
# Direction comes from the canonical TEMPLATE, not from counting. Counting cannot
# tell which spelling is current: while a rename is in flight the KB legitimately
# says both, and old work folders on disk keep the old name forever, so a
# majority-share test flags the correct name as often as the stale one.
#
# The template is unambiguous. `work-state-template.yml` means the artifact it
# produces is `STATE.yml`; `delivery-blueprint-template.md` means `BLUEPRINT.md`.
# A stem with no matching template gets no oracle and is skipped rather than
# guessed at.
# ==============================================================================
say "== Claim class 1: artifact names =="

TEMPLATE_DIR="canonical/aid/templates"
ARTIFACT_EXTS="md yml yaml json"

# stem -> the template basename that defines it
ARTIFACT_MAP="STATE:state-template BLUEPRINT:blueprint-template DETAIL:detail-template"

count_in() {
    local n
    n="$(printf '%s' "$1" | grep -o "\\b${2}\\b" | wc -l | tr -d ' ')" || n=0
    printf '%s' "${n:-0}"
}

if [ -d "$TEMPLATE_DIR" ]; then
  for pair in $ARTIFACT_MAP; do
    stem="${pair%%:*}"
    tmpl_stem="${pair##*:}"

    # The extension the template itself carries is the current one.
    current_ext="$(LC_ALL=C find "$TEMPLATE_DIR" -type f -name "*${tmpl_stem}.*" 2>/dev/null \
        | LC_ALL=C sort | head -1 | sed -n 's/.*\.\([a-z]*\)$/\1/p')"
    if [ -z "$current_ext" ]; then continue; fi

    for ext in $ARTIFACT_EXTS; do
      if [ "$ext" = "$current_ext" ]; then continue; fi

      stale_n=$(count_in "$HTML_TEXT" "${stem}\\.${ext}")
      if [ "$stale_n" -eq 0 ]; then continue; fi
      CLAIMS=$((CLAIMS + 1))

      current_n=$(count_in "$HTML_TEXT" "${stem}\\.${current_ext}")
      if [ "$current_n" -gt 0 ]; then continue; fi

      report "kb.html names ${stem}.${ext} (${stale_n}x) and never ${stem}.${current_ext}" \
             "the current artifact is ${stem}.${current_ext}, per ${TEMPLATE_DIR}/*${tmpl_stem}.${current_ext} — the tour did not follow the rename"
    done
  done
fi

# Claim class 2: grades
#
# A grade printed in the tour must be one grade.sh can actually emit. The domain is
# closed and small, so an out-of-domain grade is a real error rather than a style
# choice — it means the tour invented, or preserved, a value no gate can produce.
# ==============================================================================
say "== Claim class 2: grades =="

VALID_GRADES=" A+ A A- B+ B B- C+ C C- D+ D D- E+ E E- F "
# Matched over the whole A-Z range, not just A-F: restricting the pattern to the
# letters that happen to be valid would make the check unable to see the error it
# exists to find — a grade of `Z` would simply not match, and the class could only
# ever catch `F+`/`F-`.
#
# The letter must be a STANDALONE token. Without the trailing delimiter, "Grade
# Summary" reads as a grade of `S`, and the live tour produced three such
# phantoms (S, T, W) — a check whose only output on real input is false positives
# is worse than no check.
GRADES_SEEN="$(printf '%s' "$HTML_TEXT" \
    | grep -oE '[Gg]rade:?[[:space:]]+[A-Z][+-]?([^A-Za-z0-9]|$)' \
    | sed -E 's/^[Gg]rade:?[[:space:]]+//; s/[^A-Za-z0-9+-]+$//' \
    | LC_ALL=C sort -u || true)"

if [ -n "$GRADES_SEEN" ]; then
    while IFS= read -r g; do
        if [ -z "$g" ]; then continue; fi
        CLAIMS=$((CLAIMS + 1))
        case "$VALID_GRADES" in
            *" $g "*) ;;
            *) report "kb.html reports grade '$g'" \
                      "not in the domain grade.sh emits: A+ A A- B+ B B- C+ C C- D+ D D- E+ E E- F" ;;
        esac
    done <<< "$GRADES_SEEN"
fi

# ==============================================================================
# Claim class 3: KB document paths
#
# The tour cites `.aid/knowledge/<doc>.md`. That file must exist. A tour that links
# a document the project deleted sends a reader to nothing.
# ==============================================================================
say "== Claim class 3: KB document paths =="

DOCS_CITED="$(printf '%s' "$HTML_TEXT" \
    | grep -oE '\.aid/knowledge/[A-Za-z0-9._-]+\.md' | LC_ALL=C sort -u || true)"

if [ -n "$DOCS_CITED" ]; then
    while IFS= read -r d; do
        if [ -z "$d" ]; then continue; fi
        CLAIMS=$((CLAIMS + 1))
        base="$(basename "$d")"
        if [ ! -f "${KB_DIR}/${base}" ]; then
            report "kb.html cites ${d}" "no such document under ${KB_DIR}/"
        fi
    done <<< "$DOCS_CITED"
fi

# ==============================================================================
# Verdict
# ==============================================================================
say ""
say "claims checked: ${CLAIMS}   findings: ${FINDINGS}"

if [ "$CLAIMS" -eq 0 ]; then
    echo "kb-html-claims-check: FAIL — zero claims extracted." >&2
    echo "  A check that matches nothing cannot distinguish a correct tour from an" >&2
    echo "  unparsed one, so this is a failure, not a pass. Either the HTML shape" >&2
    echo "  changed and the extractors need updating, or the wrong file was passed." >&2
    exit 1
fi

if [ "$FINDINGS" -gt 0 ]; then
    echo "kb-html-claims-check: FAIL — ${FINDINGS} claim(s) contradict the KB." >&2
    exit 1
fi

say "kb-html-claims-check: PASS — ${CLAIMS} claim(s), all consistent with the KB."
exit 0
